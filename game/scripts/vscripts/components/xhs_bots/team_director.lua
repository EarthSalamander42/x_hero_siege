if XHSBotTeamDirector == nil then
	XHSBotTeamDirector = {}
end

XHSBotTeamDirector.assignments = XHSBotTeamDirector.assignments or {}
XHSBotTeamDirector.assignment_duration = 6
XHSBotTeamDirector.next_update = 0
XHSBotTeamDirector.last_strategy = nil
XHSBotTeamDirector.visible_boss = nil
XHSBotTeamDirector.last_seen_boss_entindex = nil
XHSBotTeamDirector.last_seen_boss_position = nil
XHSBotTeamDirector.last_seen_boss_at = nil
XHSBotTeamDirector.shopping_allowed = XHSBotTeamDirector.shopping_allowed or {}
XHSBotTeamDirector.base_threat_score = XHSBotTeamDirector.base_threat_score or 0
XHSBotTeamDirector.base_threat_active = XHSBotTeamDirector.base_threat_active or false
XHSBotTeamDirector.base_threat_hold_until = XHSBotTeamDirector.base_threat_hold_until or 0
XHSBotTeamDirector.base_response_hold_until =
	XHSBotTeamDirector.base_response_hold_until or 0
XHSBotTeamDirector.base_threat_last_sample_at = XHSBotTeamDirector.base_threat_last_sample_at or 0
XHSBotTeamDirector.base_threat_unit_samples = XHSBotTeamDirector.base_threat_unit_samples or {}
XHSBotTeamDirector.last_structure_emergency_anchor =
	XHSBotTeamDirector.last_structure_emergency_anchor or nil
XHSBotTeamDirector.last_structure_emergency_threat_position =
	XHSBotTeamDirector.last_structure_emergency_threat_position or nil
XHSBotTeamDirector.structure_emergency_hold_until =
	XHSBotTeamDirector.structure_emergency_hold_until or 0

local BASE_THREAT_SCAN_RADIUS = 5200
local BASE_THREAT_ENTER_SCORE = 0.58
local BASE_THREAT_EXIT_SCORE = 0.28
local BASE_THREAT_MINIMUM_HOLD = 7
local BASE_RESPONSE_MINIMUM_HOLD = 5
local BASE_THREAT_DECAY_PER_SECOND = 0.09
local STRUCTURE_EMERGENCY_HOLD = 3
local LANE_DOOR_HOLD_DISTANCE = 260
local PHASE_FOLLOW_RADIUS = 600
local PHASE_FOLLOW_SECOND_RING_RADIUS = 750
local PHASE_FOLLOW_GOLDEN_ANGLE = 137.5
local LANE_SHOP_CLASSNAMES = {
	"ent_dota_shop",
	"dota_item_shop",
	"trigger_shop",
}

local function IsValidEntityHandle(entity)
	return entity ~= nil and IsValidEntity(entity) and not entity:IsNull()
end

local function GetFort()
	return Entities:FindByName(nil, "dota_goodguys_fort")
		or Entities:FindByName(nil, "base_spawn")
end

local function IsProtectedStructure(unit)
	if not IsValidEntityHandle(unit) then return false end
	if unit == GetFort() then return true end
	local name = tostring(unit.GetUnitName ~= nil and unit:GetUnitName() or "")
	return name == "npc_dota_defender_fort"
		or name == "npc_dota_holdout_tower"
		or name == "npc_tower_cold"
		or name == "npc_tower_death"
end

local function PositionToward(origin, destination, distance)
	if origin == nil or destination == nil then return origin end
	local delta = destination - origin
	delta.z = 0
	if delta:Length2D() <= 1 then return origin end
	return origin + delta:Normalized() * distance
end

local function CopyPosition(position)
	if position == nil then return nil end
	return Vector(position.x, position.y, position.z or 0)
end

local function Clamp(value, minimum, maximum)
	return math.max(minimum, math.min(maximum, tonumber(value) or 0))
end

local function Distance2D(left, right)
	return (left - right):Length2D()
end

local function GetUnitAttacksPerSecond(unit)
	if not IsValidEntityHandle(unit) then return 0 end
	if unit.GetAttacksPerSecond ~= nil then
		local ok, value = pcall(function()
			return unit:GetAttacksPerSecond(false)
		end)
		if ok and tonumber(value) ~= nil then
			return math.max(0, tonumber(value))
		end
	end
	if unit.GetSecondsPerAttack ~= nil then
		local ok, value = pcall(function() return unit:GetSecondsPerAttack() end)
		if ok and tonumber(value) ~= nil and tonumber(value) > 0 then
			return 1 / tonumber(value)
		end
	end
	return 0
end

local function GetUnitMovementSpeed(unit)
	if not IsValidEntityHandle(unit) or unit.GetIdealSpeed == nil then return 300 end
	local ok, value = pcall(function() return unit:GetIdealSpeed() end)
	return ok and math.max(100, tonumber(value) or 300) or 300
end

local function GetPlayerHero(playerID)
	if PlayerResource == nil or playerID == nil then return nil end
	if PlayerResource.GetSelectedHeroEntity ~= nil then
		local ok, hero = pcall(function()
			return PlayerResource:GetSelectedHeroEntity(playerID)
		end)
		if ok and IsValidEntityHandle(hero) then return hero end
	end
	local player = PlayerResource.GetPlayer ~= nil
		and PlayerResource:GetPlayer(playerID) or nil
	if player ~= nil and player.GetAssignedHero ~= nil then
		local ok, hero = pcall(function() return player:GetAssignedHero() end)
		if ok and IsValidEntityHandle(hero) then return hero end
	end
	return nil
end

local function IsTraversable(position)
	if position == nil or GridNav == nil or GridNav.IsTraversable == nil then
		return position ~= nil
	end
	local ok, traversable = pcall(function()
		return GridNav:IsTraversable(position)
	end)
	return not ok or traversable ~= false
end

local function AssignmentKey(assignment)
	if assignment == nil then return nil end
	if assignment.goal == "defend_lane" then return "lane:" .. tostring(assignment.lane) end
	if assignment.goal == "defend_phase2" then return "side:" .. tostring(assignment.side) end
	return assignment.goal
end

function XHSBotTeamDirector:GetPhase()
	if CustomTimers ~= nil and tonumber(CustomTimers.game_phase) ~= nil then
		return math.max(1, math.min(3, tonumber(CustomTimers.game_phase)))
	end
	return 1
end

function XHSBotTeamDirector:GetActivePhaseOneLanes()
	local lanes = {}
	local participants = XHSBotPlayerRegistry:GetCombatParticipantPlayerIDs()
	for participantLane = 1, math.min(8, #participants) do
		for _, physicalLane in ipairs(
			self:GetPhysicalLanesForParticipantLane(participantLane)
		) do
			local laneState = CREEP_LANES ~= nil and CREEP_LANES[physicalLane] or nil
			if laneState ~= nil and laneState[1] == 1 and laneState[3] == 1 then
				table.insert(lanes, participantLane)
				break
			end
		end
	end
	return lanes
end

function XHSBotTeamDirector:GetOwnedPhaseOneLanes()
	local lanes = {}
	local participants = XHSBotPlayerRegistry:GetCombatParticipantPlayerIDs()
	for participantLane = 1, math.min(8, #participants) do
		if #self:GetPhysicalLanesForParticipantLane(participantLane) > 0 then
			table.insert(lanes, participantLane)
		end
	end
	return lanes
end

function XHSBotTeamDirector:GetPhysicalLanesForParticipantLane(participantLane)
	participantLane = math.floor(tonumber(participantLane) or 0)
	if participantLane < 1 or participantLane > 8 then return {} end

	-- With up to four combat participants, XHS opens two visual creep lanes
	-- per participant (melee then ranged). Above four, each participant owns
	-- exactly one physical lane.
	local lanesPerParticipant = tonumber(CREEP_LANES_TYPE) == 2 and 2 or 1
	local firstPhysicalLane = (participantLane - 1) * lanesPerParticipant + 1
	local lanes = {}
	for offset = 0, lanesPerParticipant - 1 do
		local physicalLane = firstPhysicalLane + offset
		if physicalLane <= 8 then table.insert(lanes, physicalLane) end
	end
	return lanes
end

function XHSBotTeamDirector:GetLaneDoorAnchor(physicalLane, fort)
	local door = Entities:FindByName(nil, "door_lane" .. tostring(physicalLane))
	if not IsValidEntityHandle(door) then return nil end

	-- Stay on the castle side of the gate. Standing directly on the prop can
	-- make pathing oscillate when its animation or obstruction state changes.
	return PositionToward(
		door:GetAbsOrigin(),
		fort:GetAbsOrigin(),
		LANE_DOOR_HOLD_DISTANCE
	)
end

function XHSBotTeamDirector:GetLaneShopAnchor(physicalLane, fort, spawner)
	if not IsValidEntityHandle(spawner) then return nil end

	local castleShop = Entities:FindByName(nil, "castle_shop")
	local closestShop = nil
	local closestDistance = math.huge
	local seen = {}
	for _, className in ipairs(LANE_SHOP_CLASSNAMES) do
		for _, shop in pairs(Entities:FindAllByClassname(className) or {}) do
			local entityIndex = IsValidEntityHandle(shop) and shop:entindex() or -1
			if entityIndex >= 0
				and not seen[entityIndex]
				and shop ~= castleShop then
				seen[entityIndex] = true
				local distance = Distance2D(
					shop:GetAbsOrigin(),
					spawner:GetAbsOrigin()
				)
				if distance < closestDistance then
					closestShop = shop
					closestDistance = distance
				end
			end
		end
	end

	if not IsValidEntityHandle(closestShop) then return nil end
	return (fort:GetAbsOrigin() + closestShop:GetAbsOrigin()) / 2
end

function XHSBotTeamDirector:GetPhaseOnePhysicalAnchor(physicalLane)
	local fort = GetFort()
	if not IsValidEntityHandle(fort) then return Vector(0, 0, 0) end

	local spawner = Entities:FindByName(
		nil,
		"npc_dota_spawner_" .. tostring(physicalLane)
	)

	local participantCount = #XHSBotPlayerRegistry:GetCombatParticipantPlayerIDs()
	if participantCount >= 5 then
		local doorAnchor = self:GetLaneDoorAnchor(physicalLane, fort)
		if doorAnchor ~= nil then return doorAnchor end
	else
		local shopAnchor = self:GetLaneShopAnchor(physicalLane, fort, spawner)
		if shopAnchor ~= nil then return shopAnchor end
	end

	if IsValidEntityHandle(spawner) then
		return PositionToward(fort:GetAbsOrigin(), spawner:GetAbsOrigin(), 1450)
	end

	local towers = Entities:FindAllByName(
		"dota_badguys_tower" .. tostring(physicalLane)
	)
	local closest = nil
	local closestDistance = math.huge
	for _, tower in pairs(towers) do
		if IsValidEntityHandle(tower) then
			local distance = (tower:GetAbsOrigin() - fort:GetAbsOrigin()):Length2D()
			if distance < closestDistance then
				closest = tower
				closestDistance = distance
			end
		end
	end
	return closest ~= nil and closest:GetAbsOrigin() or fort:GetAbsOrigin()
end

function XHSBotTeamDirector:GetPhaseOneAnchor(participantLane)
	local physicalLanes = self:GetPhysicalLanesForParticipantLane(participantLane)
	local anchor = nil
	for _, physicalLane in ipairs(physicalLanes) do
		local physicalAnchor = self:GetPhaseOnePhysicalAnchor(physicalLane)
		anchor = anchor == nil and physicalAnchor or anchor + physicalAnchor
	end
	if anchor ~= nil and #physicalLanes > 1 then
		anchor = anchor / #physicalLanes
	end
	if anchor ~= nil then return anchor end

	local fort = GetFort()
	return IsValidEntityHandle(fort) and fort:GetAbsOrigin() or Vector(0, 0, 0)
end

function XHSBotTeamDirector:GetPhaseTwoAnchor(side)
	local fort = GetFort()
	local spawnerName = side == "right"
		and "npc_dota_spawner_top_right_1"
		or "npc_dota_spawner_top_left_1"
	local spawner = Entities:FindByName(nil, spawnerName)

	if IsValidEntityHandle(fort) and IsValidEntityHandle(spawner) then
		return PositionToward(fort:GetAbsOrigin(), spawner:GetAbsOrigin(), 1900)
	end
	if IsValidEntityHandle(spawner) then return spawner:GetAbsOrigin() end
	return IsValidEntityHandle(fort) and fort:GetAbsOrigin() or Vector(0, 0, 0)
end

function XHSBotTeamDirector:GetPhaseThreeStagingAnchor(playerID, hero)
	if GameMode ~= nil
		and type(GameMode.GromVanguard) == "table"
		and GameMode.GromVanguard.started == true
		and GameMode.GromVanguard.gate_opened ~= true then
		local point = Entities:FindByName(
			nil,
			"point_teleport_phase3_creeps_" .. tostring(playerID)
		)
		if not IsValidEntityHandle(point) then
			point = Entities:FindByName(nil, "point_teleport_phase3_creeps_1")
		end
		if IsValidEntityHandle(point) then return point:GetAbsOrigin() end
	end
	-- This is only a no-human fallback. Normal phase-three/four downtime uses
	-- GetPhaseHumanFollowAnchor so bots leave an obsolete boss staging point.
	return IsValidEntityHandle(hero) and hero:GetAbsOrigin() or Vector(0, 0, 0)
end

function XHSBotTeamDirector:GetPhaseHumanFollowAnchor(
	playerID,
	slot,
	hero,
	preferredHumanPlayerID
)
	if not IsValidEntityHandle(hero) then return nil end
	local humans = {}
	for _, humanPlayerID in ipairs(XHSBotPlayerRegistry:GetHumanPlayerIDs()) do
		local humanHero = GetPlayerHero(humanPlayerID)
		if IsValidEntityHandle(humanHero) and humanHero:IsAlive() then
			table.insert(humans, {
				player_id = humanPlayerID,
				hero = humanHero,
				distance = Distance2D(hero:GetAbsOrigin(), humanHero:GetAbsOrigin()),
			})
		end
	end
	if #humans <= 0 then return nil end
	table.sort(humans, function(left, right)
		local leftPreferred = left.player_id == tonumber(preferredHumanPlayerID)
		local rightPreferred = right.player_id == tonumber(preferredHumanPlayerID)
		if leftPreferred ~= rightPreferred then return leftPreferred end
		if left.distance == right.distance then return left.player_id < right.player_id end
		return left.distance < right.distance
	end)

	local leader = humans[1]
	local formationSlot = math.max(1, math.floor(tonumber(slot) or 1))
	local radius = formationSlot <= 5
		and PHASE_FOLLOW_RADIUS or PHASE_FOLLOW_SECOND_RING_RADIUS
	local baseAngle = (
		(formationSlot - 1) * PHASE_FOLLOW_GOLDEN_ANGLE
			+ (tonumber(playerID) or 0) * 11
	) % 360
	for _, offset in ipairs({ 0, 45, -45, 90, -90, 180 }) do
		local radians = math.rad(baseAngle + offset)
		local origin = leader.hero:GetAbsOrigin()
		local candidate = origin + Vector(
			math.cos(radians) * radius,
			math.sin(radians) * radius,
			0
		)
		candidate.z = origin.z
		if IsTraversable(candidate) then
			return candidate, leader.player_id, radius
		end
	end

	-- The human's current position is known reachable. The generic 260-unit
	-- anchor tolerance still prevents the bot from trying to overlap them.
	return CopyPosition(leader.hero:GetAbsOrigin()), leader.player_id, radius
end

function XHSBotTeamDirector:GetVisibleThreatPressure(position, radius)
	if position == nil then return 0, 0 end
	if GameMode ~= nil and GameMode.FarmEvent_occuring == true then return 0, 0 end
	local units = FindUnitsInRadius(
		DOTA_TEAM_GOODGUYS,
		position,
		nil,
		tonumber(radius) or 1200,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE
			+ DOTA_UNIT_TARGET_FLAG_NO_INVIS
			+ DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		FIND_ANY_ORDER,
		false
	)

	local pressure = 0
	local count = 0
	for _, unit in pairs(units or {}) do
		if IsValidEntityHandle(unit) and unit:IsAlive() and not unit:IsInvulnerable() then
			count = count + 1
			local weight = 1
			if XHSBotConfig:IsBossTarget(unit) then
				weight = 6
			elseif unit:IsHero() then
				weight = 3
			end
			pressure = pressure + weight
		end
	end
	return pressure, count
end

function XHSBotTeamDirector:CalculateBaseThreat(now)
	now = tonumber(now) or GameRules:GetGameTime()
	if GameMode ~= nil and GameMode.FarmEvent_occuring == true then
		self.base_threat_score = 0
		self.base_threat_active = false
		self.base_response_hold_until = 0
		return {
			active = false,
			response_required = false,
			score = 0,
			anchor = Vector(0, 0, 0),
			threat_count = 0,
			special_count = 0,
			dragon_count = 0,
			boss_count = 0,
			approaching_count = 0,
			immediate_count = 0,
			fort_target_count = 0,
			structure_target_count = 0,
			structure_emergency = false,
			objective_loss_seconds = -1,
			objective_incoming_dps = 0,
			objective_forecast_confidence = 0,
			fort_damage_ratio = 0,
		}
	end
	local fort = GetFort()
	if not IsValidEntityHandle(fort) then
		self.base_threat_score = 0
		self.base_threat_active = false
		self.base_response_hold_until = 0
		return {
			active = false,
			response_required = false,
			score = 0,
			anchor = Vector(0, 0, 0),
			threat_count = 0,
			special_count = 0,
			dragon_count = 0,
			boss_count = 0,
			approaching_count = 0,
			immediate_count = 0,
			fort_target_count = 0,
			structure_target_count = 0,
			structure_emergency = false,
			objective_loss_seconds = -1,
			objective_incoming_dps = 0,
			objective_forecast_confidence = 0,
			fort_damage_ratio = 0,
		}
	end

	local fortOrigin = fort:GetAbsOrigin()
	local fortMaximumHealth = fort.GetMaxHealth ~= nil
		and math.max(1, fort:GetMaxHealth()) or 1
	local units = FindUnitsInRadius(
		DOTA_TEAM_GOODGUYS,
		fortOrigin,
		nil,
		BASE_THREAT_SCAN_RADIUS,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		FIND_ANY_ORDER,
		false
	)
	local globalUnits = FindUnitsInRadius(
		DOTA_TEAM_GOODGUYS,
		fortOrigin,
		nil,
		FIND_UNITS_EVERYWHERE,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		FIND_ANY_ORDER,
		false
	)
	local structureAttackers = {}
	local seenUnits = {}
	for _, unit in pairs(units or {}) do
		if IsValidEntityHandle(unit) then seenUnits[unit:entindex()] = true end
	end
	for _, unit in pairs(globalUnits or {}) do
		if IsValidEntityHandle(unit) and unit:IsAlive()
			and unit.GetAttackTarget ~= nil then
			local ok, attackTarget = pcall(function()
				return unit:GetAttackTarget()
			end)
			if ok and IsProtectedStructure(attackTarget) then
				structureAttackers[unit:entindex()] = {
					target = attackTarget,
					position = CopyPosition(unit:GetAbsOrigin()),
				}
				if not seenUnits[unit:entindex()] then
					table.insert(units, unit)
					seenUnits[unit:entindex()] = true
				end
			end
		end
	end
	local activeSpecialUnits = CustomTimers ~= nil
		and CustomTimers.active_special_wave_units or {}
	local previousSamples = self.base_threat_unit_samples or {}
	local nextSamples = {}
	local rawScore = 0
	local threatCount = 0
	local specialCount = 0
	local dragonCount = 0
	local bossCount = 0
	local approachingCount = 0
	local immediateCount = 0
	local fortTargetCount = 0
	local structureTargetCount = 0
	local structureThreatPosition = Vector(0, 0, 0)
	local structureForecastGroups = {}
	local closestDistance = math.huge
	local weightedPosition = Vector(0, 0, 0)
	local positionWeight = 0

	for _, unit in pairs(units or {}) do
		if IsValidEntityHandle(unit) and unit:IsAlive() and not unit:IsInvulnerable() then
			local entindex = unit:entindex()
			local position = unit:GetAbsOrigin()
			local distance = Distance2D(position, fortOrigin)
			local contribution = distance <= 650 and 0.18
				or distance <= 1100 and 0.10
				or distance <= 1800 and 0.045
				or distance <= 2600 and 0.018
				or distance <= 3800 and 0.007
				or 0.002
			local name = tostring(unit:GetUnitName() or "")
			local isSpecial = activeSpecialUnits[entindex] ~= nil
			local isDragon = string.find(name, "dragon", 1, true) ~= nil
			local isBoss = XHSBotConfig:IsBossTarget(unit)
			local multiplier = isBoss and 6
				or isSpecial and 4
				or isDragon and 4
				or unit:IsHero() and 3
				or 1
			local attackDamage = 0
			if unit.GetAverageTrueAttackDamage ~= nil then
				local ok, value = pcall(function()
					return unit:GetAverageTrueAttackDamage(fort)
				end)
				if ok then attackDamage = math.max(0, tonumber(value) or 0) end
			elseif unit.GetAttackDamage ~= nil then
				local ok, value = pcall(function() return unit:GetAttackDamage() end)
				if ok then attackDamage = math.max(0, tonumber(value) or 0) end
			end
			multiplier = multiplier + math.min(3, attackDamage / fortMaximumHealth * 10)

			local previous = previousSamples[entindex]
			local approaching = previous ~= nil
				and now > (previous.sampled_at or 0)
				and (previous.distance or distance) - distance
					>= math.max(60, (now - (previous.sampled_at or now)) * 40)
			if approaching then
				multiplier = multiplier + 0.5
				approachingCount = approachingCount + 1
			end

			local targetsFort = false
			if unit.GetAttackTarget ~= nil then
				local ok, attackTarget = pcall(function() return unit:GetAttackTarget() end)
				targetsFort = ok and attackTarget == fort
			end
			local structureAttack = structureAttackers[entindex]
			local targetsStructure = structureAttack ~= nil
			if targetsFort or targetsStructure then
				contribution = contribution + 0.30
			end
			if targetsStructure
				and IsValidEntityHandle(structureAttack.target) then
				local structure = structureAttack.target
				local structureIndex = structure:entindex()
				local group = structureForecastGroups[structureIndex] or {
					target = structure,
					attackers = {},
					threat_position = Vector(0, 0, 0),
					attacker_count = 0,
				}
				local structureDamage = attackDamage
				if unit.GetAverageTrueAttackDamage ~= nil then
					local ok, value = pcall(function()
						return unit:GetAverageTrueAttackDamage(structure)
					end)
					if ok then
						structureDamage = math.max(
							0,
							tonumber(value) or structureDamage
						)
					end
				end
				table.insert(group.attackers, {
					projected_dps = structureDamage
						* GetUnitAttacksPerSecond(unit),
					uptime = 1,
				})
				group.threat_position =
					group.threat_position + unit:GetAbsOrigin()
				group.attacker_count = group.attacker_count + 1
				structureForecastGroups[structureIndex] = group
			end

			-- Ordinary waves spread across eight doors must not add up to a
			-- permanent castle emergency while they are still safely outside.
			-- They become actionable once close, clearly approaching, or
			-- already attacking the fort. Specials, dragons and bosses remain
			-- strategic threats at the full scan radius.
			local immediate = distance <= 1800 or targetsFort or targetsStructure
			local actionable = immediate
				or approaching
				or isSpecial
				or isDragon
				or isBoss
			if isBoss then
				contribution = math.max(contribution, 0.60)
			elseif isSpecial or isDragon then
				contribution = math.max(
					contribution,
					distance <= 2600 and 0.24 or 0.10
				)
			end
			contribution = contribution * multiplier
			if actionable then
				rawScore = rawScore + contribution
				threatCount = threatCount + 1
				specialCount = specialCount + (isSpecial and 1 or 0)
				dragonCount = dragonCount + (isDragon and 1 or 0)
				bossCount = bossCount + (isBoss and 1 or 0)
				immediateCount = immediateCount + (immediate and 1 or 0)
				fortTargetCount = fortTargetCount + (targetsFort and 1 or 0)
				if targetsStructure then
					structureTargetCount = structureTargetCount + 1
					structureThreatPosition =
						structureThreatPosition + unit:GetAbsOrigin()
					self.last_structure_emergency_anchor =
						CopyPosition(structureAttack.target:GetAbsOrigin())
				end
				closestDistance = math.min(closestDistance, distance)
				weightedPosition = weightedPosition + position * contribution
				positionWeight = positionWeight + contribution
			end
			nextSamples[entindex] = {
				distance = distance,
				sampled_at = now,
			}
		end
	end
	self.base_threat_unit_samples = nextSamples

	local structureEmergency = structureTargetCount > 0
	local objectiveForecast = nil
	local objectiveForecastTarget = nil
	local objectiveThreatPosition = nil
	for _, group in pairs(structureForecastGroups) do
		if IsValidEntityHandle(group.target) and group.attacker_count > 0 then
			local maximumHealth = group.target.GetMaxHealth ~= nil
				and math.max(1, group.target:GetMaxHealth()) or 1
			local currentHealth = group.target.GetHealth ~= nil
				and math.max(0, group.target:GetHealth()) or maximumHealth
			local healthRegen = 0
			if group.target.GetHealthRegen ~= nil then
				local ok, value = pcall(function()
					return group.target:GetHealthRegen()
				end)
				if ok then healthRegen = math.max(0, tonumber(value) or 0) end
			end
			local forecast = XHSBotWorldModel:EstimateObjectiveLoss({
				maximum_health = maximumHealth,
				current_health = currentHealth,
				health_regen = healthRegen,
				attackers = group.attackers,
			})
			if objectiveForecast == nil
				or forecast.loss_time < objectiveForecast.loss_time then
				objectiveForecast = forecast
				objectiveForecastTarget = group.target
				objectiveThreatPosition =
					group.threat_position / group.attacker_count
			end
		end
	end
	if structureEmergency then
		self.structure_emergency_hold_until = now + STRUCTURE_EMERGENCY_HOLD
		self.last_structure_emergency_threat_position = CopyPosition(
			objectiveThreatPosition
				or structureThreatPosition / structureTargetCount
		)
		if IsValidEntityHandle(objectiveForecastTarget) then
			self.last_structure_emergency_anchor =
				CopyPosition(objectiveForecastTarget:GetAbsOrigin())
		end
	elseif now < (tonumber(self.structure_emergency_hold_until) or 0)
		and self.last_structure_emergency_anchor ~= nil then
		structureEmergency = true
	end
	if structureEmergency then
		rawScore = math.max(rawScore, 1.05)
	end

	local fortHealth = fort.GetHealth ~= nil and fort:GetHealth() or 0
	local previousFortHealth = tonumber(self.base_threat_fort_health) or fortHealth
	local fortDamageRatio = math.max(0, previousFortHealth - fortHealth) / fortMaximumHealth
	self.base_threat_fort_health = fortHealth
	rawScore = rawScore + math.min(0.90, fortDamageRatio * 12)

	local elapsed = math.max(0, now - (tonumber(self.base_threat_last_sample_at) or now))
	local rememberedScore = math.max(
		0,
		(tonumber(self.base_threat_score) or 0) - elapsed * BASE_THREAT_DECAY_PER_SECOND
	)
	local score = Clamp(math.max(rawScore, rememberedScore), 0, 1.5)
	-- A far special wave is strategic lane pressure, not permission to pull
	-- every bot off its own door. Global regrouping starts only when meaningful
	-- pressure reaches the castle envelope or a protected structure is attacked.
	local responseRequired = structureEmergency
		or fortTargetCount > 0
		or immediateCount > 0
			and closestDistance <= 1800
			and rawScore >= BASE_THREAT_ENTER_SCORE
	if responseRequired then
		self.base_response_hold_until = now + BASE_RESPONSE_MINIMUM_HOLD
	elseif now < (tonumber(self.base_response_hold_until) or 0) then
		-- Do not bounce base -> lane -> base while the last castle contact is
		-- only briefly outside a scan/visibility boundary.
		responseRequired = true
	end
	local active = self.base_threat_active == true
	if rawScore >= BASE_THREAT_ENTER_SCORE then
		active = true
		self.base_threat_hold_until = now + BASE_THREAT_MINIMUM_HOLD
	elseif active and score <= BASE_THREAT_EXIT_SCORE
		and now >= (tonumber(self.base_threat_hold_until) or 0) then
		active = false
	end

	local anchor = fortOrigin
	if structureEmergency and self.last_structure_emergency_anchor ~= nil then
		anchor = CopyPosition(self.last_structure_emergency_anchor)
	elseif positionWeight > 0 then
		local pressureCenter = weightedPosition / positionWeight
		anchor = PositionToward(
			fortOrigin,
			pressureCenter,
			math.min(850, Distance2D(fortOrigin, pressureCenter))
		)
	end
	self.base_threat_score = score
	self.base_threat_active = active
	self.base_threat_last_sample_at = now
	return {
		active = active,
		response_required = responseRequired,
		score = score,
		raw_score = rawScore,
		anchor = CopyPosition(anchor),
		threat_count = threatCount,
		special_count = specialCount,
		dragon_count = dragonCount,
		boss_count = bossCount,
		approaching_count = approachingCount,
		immediate_count = immediateCount,
		fort_target_count = fortTargetCount,
		structure_target_count = structureTargetCount,
		structure_emergency = structureEmergency,
		objective_loss_seconds = objectiveForecast ~= nil
			and objectiveForecast.loss_time or -1,
		objective_incoming_dps = objectiveForecast ~= nil
			and objectiveForecast.incoming_dps or 0,
		objective_forecast_confidence = objectiveForecast ~= nil
			and objectiveForecast.confidence or 0,
		threat_position = structureEmergency
			and CopyPosition(self.last_structure_emergency_threat_position)
			or positionWeight > 0 and CopyPosition(weightedPosition / positionWeight)
			or nil,
		closest_distance = closestDistance < math.huge and closestDistance or 0,
		fort_damage_ratio = fortDamageRatio,
	}
end

function XHSBotTeamDirector:GetHumanPresence(position, radius)
	local humans = {}
	if position == nil then return humans end
	for _, playerID in ipairs(XHSBotPlayerRegistry:GetHumanPlayerIDs()) do
		local player = PlayerResource:GetPlayer(playerID)
		local hero = player ~= nil and player:GetAssignedHero() or nil
		if IsValidEntityHandle(hero)
			and hero:IsAlive()
			and Distance2D(hero:GetAbsOrigin(), position) <= (tonumber(radius) or 1600) then
			table.insert(humans, {
				player_id = playerID,
				hero = hero,
				distance = Distance2D(hero:GetAbsOrigin(), position),
			})
		end
	end
	table.sort(humans, function(left, right)
		if left.distance == right.distance then return left.player_id < right.player_id end
		return left.distance < right.distance
	end)
	return humans
end

function XHSBotTeamDirector:BuildStrategicSnapshot(phase)
	local snapshot = {
		phase = phase,
		objectives = {},
		by_key = {},
		by_player_id = {},
		built_at = GameRules:GetGameTime(),
	}
	snapshot.base_threat = self:CalculateBaseThreat(snapshot.built_at)
	if phase >= 3 and snapshot.base_threat.structure_emergency ~= true then
		snapshot.base_threat.active = false
		snapshot.base_threat.response_required = false
		snapshot.base_threat.score = 0
	end
	if phase == 1 then
		local participants = XHSBotPlayerRegistry:GetCombatParticipantPlayerIDs()
		-- Lane ownership is a roster invariant, not a transient creep-spawner
		-- state. Even between waves or after a lane objective changes state,
		-- its participant keeps the door anchor instead of regrouping at base.
		for _, lane in ipairs(self:GetOwnedPhaseOneLanes()) do
			local participantPlayerID = participants[lane]
			local anchor = self:GetPhaseOneAnchor(lane)
			local pressure, threatCount = self:GetVisibleThreatPressure(anchor, 1450)
			local humans = self:GetHumanPresence(anchor, 1650)
			local laneActive = false
			for _, physicalLane in ipairs(self:GetPhysicalLanesForParticipantLane(lane)) do
				local laneState = CREEP_LANES ~= nil and CREEP_LANES[physicalLane] or nil
				if laneState ~= nil and laneState[1] == 1 and laneState[3] == 1 then
					laneActive = true
					break
				end
			end
			local objective = {
				key = "lane:" .. tostring(lane),
				goal = "defend_lane",
				lane = lane,
				physical_lanes = self:GetPhysicalLanesForParticipantLane(lane),
				participant_player_id = participantPlayerID,
				anchor = anchor,
				pressure = pressure,
				threat_count = threatCount,
				humans = humans,
				human_count = #humans,
				lane_active = laneActive,
				urgency = Clamp(0.18 + pressure / 12, 0.18, 1),
			}
			table.insert(snapshot.objectives, objective)
			snapshot.by_key[objective.key] = objective
			if participantPlayerID ~= nil then
				snapshot.by_player_id[participantPlayerID] = objective
			end
		end
	elseif phase == 2 then
		for _, side in ipairs({ "left", "right" }) do
			local anchor = self:GetPhaseTwoAnchor(side)
			local pressure, threatCount = self:GetVisibleThreatPressure(anchor, 1750)
			local humans = self:GetHumanPresence(anchor, 1900)
			local objective = {
				key = "side:" .. side,
				goal = "defend_phase2",
				side = side,
				anchor = anchor,
				pressure = pressure,
				threat_count = threatCount,
				humans = humans,
				human_count = #humans,
				urgency = Clamp(0.24 + pressure / 14, 0.24, 1),
			}
			table.insert(snapshot.objectives, objective)
			snapshot.by_key[objective.key] = objective
		end

		-- Phase-two ownership follows the whole combat roster, ordered by
		-- PlayerID. The first half (rounded up) owns left, the rest owns right.
		-- This keeps bots aligned with the players beside them instead of
		-- changing lanes whenever the live pressure score fluctuates.
		local participants = XHSBotPlayerRegistry:GetCombatParticipantPlayerIDs()
		local leftCount = math.ceil(#participants / 2)
		for index, playerID in ipairs(participants) do
			local side = index <= leftCount and "left" or "right"
			snapshot.by_player_id[playerID] = snapshot.by_key["side:" .. side]
		end
	end
	table.sort(snapshot.objectives, function(left, right)
		if left.urgency == right.urgency then return left.key < right.key end
		return left.urgency > right.urgency
	end)
	self.last_strategy = snapshot
	return snapshot
end

function XHSBotTeamDirector:SelectObjective(snapshot, loads, profile, difficulty, slot)
	local best = nil
	local bestScore = -math.huge
	for index, objective in ipairs(snapshot.objectives or {}) do
		local load = tonumber(loads[objective.key]) or 0
		local urgencyScore = objective.urgency * (difficulty.lane_urgency_weight or 0.5)
		local humanScore = objective.human_count * (difficulty.human_follow_weight or 0)
		local roleScore = 0
		if profile ~= nil and profile.role == "support" and objective.human_count > 0 then
			roleScore = 0.35
		elseif profile ~= nil and profile.role == "frontline" then
			roleScore = objective.urgency * 0.22
		end
		-- The tiny slot/index term makes no-pressure ties deterministic while
		-- rotating first choice across slots.
		local tieRotation = ((slot + index - 2) % math.max(1, #snapshot.objectives)) * 0.001
		local score = urgencyScore + humanScore + roleScore - load * 0.58 - tieRotation
		if score > bestScore then
			best = objective
			bestScore = score
		end
	end
	if best ~= nil then loads[best.key] = (loads[best.key] or 0) + 1 end
	return best
end

function XHSBotTeamDirector:IsFarmEventActiveFor(playerID)
	if GameMode == nil or GameMode.FarmEvent_occuring ~= true
		or SpecialEvents == nil
		or type(SpecialEvents.hero_farm_event) ~= "table" then
		return false
	end
	return type(SpecialEvents.hero_farm_event[tonumber(playerID)]) == "table"
		or type(SpecialEvents.hero_farm_event[tostring(playerID)]) == "table"
end

function XHSBotTeamDirector:GetFarmEventAnchor(playerID)
	if not self:IsFarmEventActiveFor(playerID) then return nil end
	local point = Entities:FindByName(nil, "farm_event_player_" .. tostring(playerID))
	return IsValidEntityHandle(point) and point:GetAbsOrigin() or nil
end

function XHSBotTeamDirector:IsShoppingGoalEligible(record, hero)
	if type(record) ~= "table"
		or type(record.shopping_goal) ~= "table"
		or record.shopping_goal.anchor == nil
		or not IsValidEntityHandle(hero)
		or not hero:IsAlive() then
		return false
	end
	local healthRatio = hero:GetHealth() / math.max(1, hero:GetMaxHealth())
	-- An empty health reserve is a survival assignment, not a downtime purchase.
	-- It bypasses both the normal health band and the combat target gate.
	if record.shopping_goal.emergency_health_resupply == true then return true end
	if record.shopping_goal.urgent == true then
		if record.shopping_goal.force_home == true then return true end
		local shopDistance = Distance2D(hero:GetAbsOrigin(), record.shopping_goal.anchor)
		if healthRatio <= 0.60 or shopDistance <= 1200 then
			return true
		end
	end

	-- Ordinary shopping remains a downtime action. Combat, current telegraphs
	-- and marginal health keep the bot on assignment until it is safe to leave.
	if record.target_entindex ~= nil or record.was_in_active_danger == true then return false end
	if (tonumber(record.assignment_urgency) or 0) >= 0.80 then return false end
	return healthRatio >= 0.72
end

function XHSBotTeamDirector:RefreshShoppingAllowlist(playerIDs)
	local candidates = {}
	local maximumShoppers = 1

	for _, playerID in ipairs(playerIDs or {}) do
		local record = XHSBotPlayerRegistry:GetBot(playerID)
		local hero = XHSBotPlayerRegistry:GetBotHero(playerID)
		local difficulty = XHSBotConfig:GetDifficulty(record and record.difficulty or "normal")
		maximumShoppers = math.max(
			maximumShoppers,
			math.floor(tonumber(difficulty.max_concurrent_shoppers) or 1)
		)
		if self:IsShoppingGoalEligible(record, hero) then
			local existing = self.assignments[playerID]
			table.insert(candidates, {
				player_id = playerID,
				already_shopping = existing ~= nil and existing.goal == "shop",
				urgent = record.shopping_goal.urgent == true,
				emergency_health =
					record.shopping_goal.emergency_health_resupply == true,
				requested_at = tonumber(record.shopping_goal.requested_at) or math.huge,
			})
		end
	end

	table.sort(candidates, function(left, right)
		if left.emergency_health ~= right.emergency_health then
			return left.emergency_health
		end
		if left.urgent ~= right.urgent then
			return left.urgent
		end
		if left.requested_at ~= right.requested_at then
			return left.requested_at < right.requested_at
		end
		-- Preserve a current route only after older requests had their turn.
		-- Otherwise one bot can buy an item, immediately request the next one,
		-- remain "already shopping", and starve Enchantress forever.
		if left.already_shopping ~= right.already_shopping then
			return left.already_shopping
		end
		return left.player_id < right.player_id
	end)

	self.shopping_allowed = {}
	local ordinaryShoppers = 0
	for _, candidate in ipairs(candidates) do
		-- A concurrency cap is useful for planned gear trips, but limiting an
		-- empty-potion emergency to one or two bots simply chooses which other
		-- bots are allowed to die and consume Ankhs.
		if candidate.emergency_health == true then
			self.shopping_allowed[candidate.player_id] = true
		elseif ordinaryShoppers < maximumShoppers then
			self.shopping_allowed[candidate.player_id] = true
			ordinaryShoppers = ordinaryShoppers + 1
		end
	end
end

function XHSBotTeamDirector:IsShoppingAssignmentAllowed(playerID, record, hero)
	return self.shopping_allowed[tonumber(playerID)] == true
		and self:IsShoppingGoalEligible(record, hero)
end

function XHSBotTeamDirector:ClearBossMemory()
	self.last_seen_boss_entindex = nil
	self.last_seen_boss_position = nil
	self.last_seen_boss_at = nil
end

function XHSBotTeamDirector:GetRememberedBossPosition(now)
	now = tonumber(now) or GameRules:GetGameTime()
	if self.last_seen_boss_position == nil
		or now - (self.last_seen_boss_at or 0) > 4 then
		self:ClearBossMemory()
		return nil
	end
	if self.last_seen_boss_entindex ~= nil then
		local ok, boss = pcall(EntIndexToHScript, self.last_seen_boss_entindex)
		if not ok or not IsValidEntityHandle(boss) or not boss:IsAlive() then
			self:ClearBossMemory()
			return nil
		end
	end
	return CopyPosition(self.last_seen_boss_position)
end

function XHSBotTeamDirector:FindActiveBoss()
	if GameMode ~= nil and GameMode.FarmEvent_occuring == true then return nil end
	local fort = GetFort()
	local origin = IsValidEntityHandle(fort) and fort:GetAbsOrigin() or Vector(0, 0, 0)
	local units = FindUnitsInRadius(
		DOTA_TEAM_GOODGUYS,
		origin,
		nil,
		FIND_UNITS_EVERYWHERE,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE
			+ DOTA_UNIT_TARGET_FLAG_NO_INVIS
			+ DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
			+ DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
		FIND_CLOSEST,
		false
	)

	for _, unit in pairs(units) do
		if IsValidEntityHandle(unit) and unit:IsAlive() then
			if XHSBotConfig:IsBossTarget(unit) then
				self.last_seen_boss_entindex = unit:entindex()
				self.last_seen_boss_position = CopyPosition(unit:GetAbsOrigin())
				self.last_seen_boss_at = GameRules:GetGameTime()
				return unit
			end
		end
	end
	return nil
end

function XHSBotTeamDirector:CanRespondToStructureEmergency(
	hero,
	profile,
	baseThreat
)
	if not IsValidEntityHandle(hero) or not hero:IsAlive()
		or baseThreat == nil or baseThreat.structure_emergency ~= true then
		return false
	end
	local healthRatio = hero:GetHealth() / math.max(1, hero:GetMaxHealth())
	local responseThreshold = math.max(
		0.34,
		(tonumber(profile and profile.retreat_health) or 0.24) + 0.10
	)
	if healthRatio >= responseThreshold then return true end
	if baseThreat.anchor == nil then return false end
	local distance = Distance2D(hero:GetAbsOrigin(), baseThreat.anchor)
	if distance <= 1300 then return true end

	-- A critically weak bot normally finishes its emergency resupply. The only
	-- forecast exception is a genuine last-chance structure save that it can
	-- physically reach before the projected loss.
	local lossTime = tonumber(baseThreat.objective_loss_seconds) or -1
	local travelTime = distance / GetUnitMovementSpeed(hero)
	return healthRatio >= 0.18
		and lossTime > 0 and lossTime <= 8
		and travelTime <= lossTime + 1.5
end

function XHSBotTeamDirector:BuildAssignment(playerID, slot, phase, now, snapshot, loads)
	local record = XHSBotPlayerRegistry:GetBot(playerID)
	local hero = XHSBotPlayerRegistry:GetBotHero(playerID)
	local profile = hero ~= nil and XHSBotHeroProfiles:Get(hero:GetUnitName()) or nil
	local difficulty = XHSBotConfig:GetDifficulty(record and record.difficulty or "normal")
	loads = loads or {}
	local assignment = {
		player_id = playerID,
		role = profile and profile.role or "unknown",
		phase = phase,
		assigned_at = now,
		locked_until = now + (difficulty.assignment_duration or self.assignment_duration),
		urgency = 0.5,
		chase_radius = difficulty.max_chase_distance or 1200,
		anchor_leash = difficulty.anchor_leash or 1700,
	}

	if not IsValidEntityHandle(hero) then
		assignment.goal = "selecting_hero"
		assignment.anchor = Vector(0, 0, 0)
		assignment.urgency = 0
		assignment.locked_until = now + 1
		assignment.label = "SELECTING HERO"
	elseif not hero:IsAlive() then
		assignment.goal = "dead"
		assignment.anchor = hero:GetAbsOrigin()
		assignment.urgency = 0
		assignment.locked_until = now + 1
		assignment.label = "DEAD"
	end

	local shoppingGoal = record and record.shopping_goal or nil
	local farmAnchor = assignment.goal == nil and self:GetFarmEventAnchor(playerID) or nil
	if farmAnchor ~= nil then
		-- FarmEvent is initiated by the game/human flow and creates a per-player
		-- progress entry before this assignment is possible. The director only
		-- reacts to that authoritative state; it never touches event triggers.
		assignment.goal = "participate_event"
		assignment.event = "farm_event"
		assignment.anchor = farmAnchor
		assignment.urgency = 0.95
		assignment.chase_radius = 1250
		assignment.anchor_leash = 1400
		assignment.label = "FARM EVENT (PASSIVE JOIN)"
	elseif assignment.goal == nil
		and self:IsShoppingAssignmentAllowed(playerID, record, hero) then
		assignment.goal = "shop"
		assignment.shopping_item = shoppingGoal.item
		assignment.shopping_urgent = shoppingGoal.urgent == true
		assignment.shopping_emergency_health_resupply =
			shoppingGoal.emergency_health_resupply == true
		assignment.shopping_inventory_logistics = shoppingGoal.inventory_logistics == true
		assignment.anchor = CopyPosition(shoppingGoal.anchor)
		assignment.urgency =
			shoppingGoal.emergency_health_resupply == true and 1
			or shoppingGoal.urgent == true and 0.88 or 0.35
		assignment.chase_radius = 650
		assignment.anchor_leash = 850
		assignment.label = shoppingGoal.inventory_logistics == true
			and "COLLECTING STASH"
			or (shoppingGoal.urgent == true and "EMERGENCY RESTOCK: " or "SHOPPING: ")
				.. string.upper(tostring(shoppingGoal.item))
	elseif assignment.goal ~= nil then
		-- Selecting/dead assignments intentionally do not consume a lane load.
	elseif phase == 1 or phase == 2 then
		local strategicSnapshot = snapshot or self:BuildStrategicSnapshot(phase)
		local objective = nil
		if phase == 1 then
			-- Phase-one ownership follows the complete combat roster ordered by
			-- PlayerID: roster position 1 owns lane 1, position 2 owns lane 2,
			-- and so on. A bot never steals a human's participant lane because
			-- urgency/load balancing only applies to phase two.
			objective = strategicSnapshot.by_player_id[playerID]
		else
			objective = strategicSnapshot.by_player_id[playerID]
		end
		if objective ~= nil then
			assignment.goal = objective.goal
			assignment.lane = objective.lane
			assignment.physical_lanes = objective.physical_lanes
			assignment.participant_player_id = objective.participant_player_id
			assignment.side = objective.side
			assignment.anchor = objective.anchor
			assignment.strategy_key = objective.key
			assignment.urgency = objective.urgency
			assignment.threat_count = objective.threat_count
			assignment.human_count = objective.human_count

			local nearestHuman = objective.humans and objective.humans[1] or nil
			if nearestHuman ~= nil
				and phase ~= 1
				and nearestHuman.distance <= (difficulty.human_follow_radius or 0)
				and (difficulty.human_follow_weight or 0) > 0 then
				local followDistance = math.min(
					450,
					nearestHuman.distance * (difficulty.human_follow_weight or 0)
				)
				assignment.anchor = PositionToward(
					assignment.anchor,
					nearestHuman.hero:GetAbsOrigin(),
					followDistance
				)
				assignment.follow_human_player_id = nearestHuman.player_id
			end

			if phase == 1 then
				assignment.label = "DEFENDING L" .. tostring(assignment.lane)
			else
				assignment.label = "PHASE 2 " .. string.upper(tostring(assignment.side))
			end
		else
			local fort = GetFort()
			assignment.goal = "regroup"
			assignment.anchor = IsValidEntityHandle(fort) and fort:GetAbsOrigin() or Vector(0, 0, 0)
			assignment.label = "REGROUPING"
		end
	else
		local boss = self.visible_boss
		if IsValidEntityHandle(boss) then
			assignment.goal = "fight_boss"
			assignment.target_entindex = boss:entindex()
			assignment.anchor = CopyPosition(boss:GetAbsOrigin())
			assignment.urgency = 0.9
			assignment.chase_radius = 3200
			assignment.anchor_leash = 3600
			assignment.label = "FIGHTING BOSS"
		elseif self:GetRememberedBossPosition(now) ~= nil then
			assignment.goal = "investigate_boss"
			assignment.target_entindex = nil
			assignment.anchor = self:GetRememberedBossPosition(now)
			assignment.urgency = 0.74
			assignment.chase_radius = 1800
			assignment.anchor_leash = 2100
			assignment.label = "SEARCHING LAST SEEN BOSS"
		else
			local followAnchor, followHumanPlayerID, followRadius =
				self:GetPhaseHumanFollowAnchor(playerID, slot, hero, nil)
			assignment.goal = "regroup"
			assignment.anchor = followAnchor
				or self:GetPhaseThreeStagingAnchor(playerID, hero)
			assignment.follow_human_player_id = followHumanPlayerID
			assignment.follow_radius = followRadius
			assignment.urgency = followAnchor ~= nil and 0.30 or 0.12
			assignment.chase_radius = 2800
			assignment.anchor_leash = 3200
			assignment.label = followAnchor ~= nil
				and "PHASE 3/4 FOLLOWING PLAYER"
				or "PHASE 3/4 STAGING"
		end
	end

	local baseThreat = snapshot and snapshot.base_threat or nil
	local emergencyHealthShopping = assignment.goal == "shop"
		and assignment.shopping_emergency_health_resupply == true
	local structureEmergency = baseThreat ~= nil
		and baseThreat.structure_emergency == true
	local canRespondToStructure = self:CanRespondToStructureEmergency(
		hero,
		profile,
		baseThreat
	)
	local structureEmergencyOrCapable =
		structureEmergency or canRespondToStructure
	local preserveEmergencyShopping = emergencyHealthShopping
		and not canRespondToStructure
	if IsValidEntityHandle(hero) and hero:IsAlive()
		and baseThreat ~= nil and baseThreat.active == true
		and baseThreat.response_required == true
		and not preserveEmergencyShopping
		and (not structureEmergency or canRespondToStructure) then
		assignment.goal = "defend_base"
		assignment.anchor = CopyPosition(baseThreat.anchor)
		assignment.threat_position =
			CopyPosition(baseThreat.threat_position)
		assignment.target_entindex = nil
		assignment.urgency = 1
		assignment.chase_radius = 2200
		assignment.anchor_leash = 2450
		assignment.base_threat_score = baseThreat.score
		assignment.base_threat_count = baseThreat.threat_count
		assignment.base_special_count = baseThreat.special_count
		assignment.base_dragon_count = baseThreat.dragon_count
		assignment.base_immediate_count = baseThreat.immediate_count
		assignment.base_structure_emergency =
			baseThreat.structure_emergency == true
		assignment.objective_loss_seconds =
			baseThreat.objective_loss_seconds
		assignment.objective_incoming_dps =
			baseThreat.objective_incoming_dps
		assignment.label = structureEmergencyOrCapable and structureEmergency
			and "STRUCTURE UNDER ATTACK"
			or string.format("BASE THREAT %.2f", baseThreat.score or 0)
	end

	if IsValidEntityHandle(hero) and hero:IsAlive()
		and CustomTimers ~= nil and CustomTimers.proc_final_wave == true
		and not emergencyHealthShopping then
		local fort = GetFort()
		assignment.goal = "defend_base"
		assignment.anchor = IsValidEntityHandle(fort) and fort:GetAbsOrigin() or assignment.anchor
		assignment.urgency = 1
		assignment.label = "DEFENDING BASE"
	end

	local forcedGoal = IsValidEntityHandle(hero) and hero:IsAlive()
		and record and record.forced_goal or nil
	if forcedGoal == "defend_base" or forcedGoal == "regroup" then
		local fort = GetFort()
		assignment.goal = forcedGoal
		assignment.anchor = IsValidEntityHandle(fort) and fort:GetAbsOrigin() or assignment.anchor
		assignment.target_entindex = nil
		assignment.urgency = 1
		assignment.label = forcedGoal == "defend_base" and "FORCED: DEFEND BASE" or "FORCED: REGROUP"
	elseif forcedGoal == "fight_boss" then
		local boss = IsValidEntityHandle(self.visible_boss) and self.visible_boss or self:FindActiveBoss()
		local rememberedBossPosition = self:GetRememberedBossPosition(now)
		if IsValidEntityHandle(boss) then
			assignment.goal = "fight_boss"
			assignment.target_entindex = boss:entindex()
			assignment.anchor = CopyPosition(boss:GetAbsOrigin())
			assignment.label = "FORCED: FIGHT BOSS"
		elseif rememberedBossPosition ~= nil then
			assignment.goal = "investigate_boss"
			assignment.target_entindex = nil
			assignment.anchor = rememberedBossPosition
			assignment.label = "FORCED: SEARCH LAST SEEN BOSS"
		else
			local fort = GetFort()
			assignment.goal = "regroup"
			assignment.target_entindex = nil
			assignment.anchor = IsValidEntityHandle(fort) and fort:GetAbsOrigin() or assignment.anchor
			assignment.label = "FORCED: BOSS NOT VISIBLE"
		end
		assignment.urgency = 1
	elseif forcedGoal == "hold" and IsValidEntityHandle(hero) then
		assignment.goal = "hold"
		assignment.anchor = hero:GetAbsOrigin()
		assignment.target_entindex = nil
		assignment.urgency = 1
		assignment.label = "FORCED: HOLD"
	end

	if record ~= nil then
		record.role = assignment.role
		record.goal = assignment.goal
		record.lane = assignment.lane
		record.physical_lanes = assignment.physical_lanes
		record.participant_player_id = assignment.participant_player_id
		record.side = assignment.side
		record.assignment_urgency = assignment.urgency
		record.follow_human_player_id = assignment.follow_human_player_id
		record.base_threat_score = baseThreat and baseThreat.score or 0
		record.base_threat_active = baseThreat and baseThreat.active == true or false
		record.base_response_required = baseThreat
			and baseThreat.response_required == true or false
		record.base_threat_count = baseThreat and baseThreat.threat_count or 0
		record.base_special_count = baseThreat and baseThreat.special_count or 0
		record.base_dragon_count = baseThreat and baseThreat.dragon_count or 0
		record.base_approaching_count = baseThreat and baseThreat.approaching_count or 0
		record.base_structure_emergency = baseThreat
			and baseThreat.structure_emergency == true or false
		record.base_structure_target_count = baseThreat
			and baseThreat.structure_target_count or 0
		record.base_objective_loss_seconds = baseThreat
			and baseThreat.objective_loss_seconds or -1
		record.base_objective_incoming_dps = baseThreat
			and math.floor(baseThreat.objective_incoming_dps or 0) or 0
		record.base_objective_forecast_confidence = baseThreat
			and math.floor(
				(baseThreat.objective_forecast_confidence or 0) * 100
			) / 100 or 0
	end
	return assignment
end

function XHSBotTeamDirector:ShouldReplaceAssignment(existing, phase, now, snapshot, record, hero)
	if existing == nil then return true end
	if existing.phase ~= phase then return true end
	if phase == 1 and snapshot ~= nil and record ~= nil then
		local expectedLane = snapshot.by_player_id[record.player_id]
		if expectedLane == nil and existing.goal == "defend_lane" then
			return true
		end
		if expectedLane ~= nil and (
			existing.goal == "regroup"
			or existing.goal == "defend_lane"
				and existing.strategy_key ~= expectedLane.key
		) then
			return true
		end
	end
	local baseThreatActive = snapshot ~= nil and snapshot.base_threat ~= nil
		and snapshot.base_threat.active == true
	local baseResponseRequired = baseThreatActive
		and snapshot.base_threat.response_required == true
	local structureEmergency = baseResponseRequired
		and snapshot.base_threat.structure_emergency == true
	local finalWaveActive = CustomTimers ~= nil and CustomTimers.proc_final_wave == true
	local forcedGoal = record and record.forced_goal or nil
	local emergencyShoppingActive = record ~= nil
		and type(record.shopping_goal) == "table"
		and record.shopping_goal.emergency_health_resupply == true
		and self:IsShoppingAssignmentAllowed(record.player_id, record, hero)
	local profile = IsValidEntityHandle(hero)
		and XHSBotHeroProfiles:Get(hero:GetUnitName()) or nil
	local canRespondToStructure = structureEmergency
		and self:CanRespondToStructureEmergency(
			hero,
			profile,
			snapshot.base_threat
		)
	local preserveEmergencyShopping = emergencyShoppingActive
		and not canRespondToStructure
	local baseThreatControls = baseResponseRequired
		and not preserveEmergencyShopping
		and (not structureEmergency or canRespondToStructure)
		and forcedGoal == nil
		and IsValidEntityHandle(hero)
		and hero:IsAlive()
	if baseThreatControls and existing.goal ~= "defend_base" then return true end
	if not baseThreatControls and not finalWaveActive and forcedGoal ~= "defend_base"
		and existing.goal == "defend_base" then
		return true
	end
	local farmEventActive = record ~= nil and self:IsFarmEventActiveFor(record.player_id)
	if not baseThreatControls
		and farmEventActive ~= (existing.goal == "participate_event") then
		return true
	end
	if finalWaveActive and not emergencyShoppingActive
		and existing.goal ~= "defend_base" then
		return true
	end
	if not IsValidEntityHandle(hero) or not hero:IsAlive() then
		return existing.goal ~= "dead"
	elseif existing.goal == "dead" then
		return true
	end

	local shoppingAllowed =
		self:IsShoppingAssignmentAllowed(record and record.player_id, record, hero)
	local shoppingActive = not farmEventActive
		and forcedGoal == nil
		and not baseThreatControls
		and shoppingAllowed
		and (emergencyShoppingActive
			or not finalWaveActive and not baseResponseRequired)
	if shoppingActive ~= (existing.goal == "shop") then return true end
	if shoppingActive and existing.shopping_item ~= record.shopping_goal.item then return true end

	if phase == 3 and not farmEventActive and not finalWaveActive
		and not baseResponseRequired and forcedGoal == nil
		and not shoppingActive then
		local bossVisible = IsValidEntityHandle(self.visible_boss)
		local expectedBossGoal = bossVisible and "fight_boss"
			or self:GetRememberedBossPosition(now) ~= nil and "investigate_boss"
			or "regroup"
		if existing.goal ~= expectedBossGoal then return true end
		if bossVisible
			and existing.target_entindex ~= self.visible_boss:entindex() then
			return true
		end
	end

	if now >= (existing.locked_until or 0) then return true end
	if existing.target_entindex ~= nil then
		local ok, target = pcall(EntIndexToHScript, existing.target_entindex)
		if not ok or not IsValidEntityHandle(target) or not target:IsAlive() then
			return true
		end
	end
	if phase ~= 1 and snapshot ~= nil and existing.strategy_key ~= nil then
		local current = snapshot.by_key[existing.strategy_key]
		local mostUrgent = snapshot.objectives[1]
		local difficulty = XHSBotConfig:GetDifficulty(record and record.difficulty or "normal")
		if current ~= nil and mostUrgent ~= nil
			and mostUrgent.key ~= current.key
			and now - (existing.assigned_at or now) >= 2
			and mostUrgent.urgency - current.urgency >= (difficulty.urgency_break_threshold or 0.5) then
			return true
		end
	end
	return false
end

function XHSBotTeamDirector:Update(force)
	local now = GameRules:GetGameTime()
	if not force and now < self.next_update then return end
	local phase = self:GetPhase()
	if phase == 3 then
		self.visible_boss = self:FindActiveBoss()
	else
		self.visible_boss = nil
	end
	local ids = XHSBotPlayerRegistry:GetXHSBotPlayerIDs()
	self:RefreshShoppingAllowlist(ids)
	local replanInterval = 1.35
	for _, playerID in ipairs(ids) do
		local record = XHSBotPlayerRegistry:GetBot(playerID)
		local difficulty = XHSBotConfig:GetDifficulty(record and record.difficulty or "normal")
		replanInterval = math.min(
			replanInterval,
			tonumber(difficulty.director_replan_interval) or replanInterval
		)
	end
	self.next_update = now + replanInterval

	local snapshot = self:BuildStrategicSnapshot(phase)
	for _, playerID in ipairs(ids) do
		local record = XHSBotPlayerRegistry:GetBot(playerID)
		if record ~= nil then
			record.base_threat_score = snapshot.base_threat.score or 0
			record.base_threat_active = snapshot.base_threat.active == true
			record.base_response_required =
				snapshot.base_threat.response_required == true
			record.base_threat_count = snapshot.base_threat.threat_count or 0
			record.base_special_count = snapshot.base_threat.special_count or 0
			record.base_dragon_count = snapshot.base_threat.dragon_count or 0
			record.base_approaching_count = snapshot.base_threat.approaching_count or 0
			record.base_structure_emergency =
				snapshot.base_threat.structure_emergency == true
			record.base_structure_target_count =
				snapshot.base_threat.structure_target_count or 0
			record.base_objective_loss_seconds =
				snapshot.base_threat.objective_loss_seconds or -1
			record.base_objective_incoming_dps = math.floor(
				snapshot.base_threat.objective_incoming_dps or 0
			)
			record.base_objective_forecast_confidence = math.floor(
				(snapshot.base_threat.objective_forecast_confidence or 0) * 100
			) / 100
		end
	end
	local loads = {}
	local replace = {}

	for _, playerID in ipairs(ids) do
		local existing = self.assignments[playerID]
		local record = XHSBotPlayerRegistry:GetBot(playerID)
		local hero = XHSBotPlayerRegistry:GetBotHero(playerID)
		replace[playerID] = force or self:ShouldReplaceAssignment(
			existing,
			phase,
			now,
			snapshot,
			record,
			hero
		)
		if not replace[playerID] then
			local key = AssignmentKey(existing)
			if key ~= nil then loads[key] = (loads[key] or 0) + 1 end
		end
	end

	for slot, playerID in ipairs(ids) do
		local existing = self.assignments[playerID]
		if replace[playerID] then
			self.assignments[playerID] = self:BuildAssignment(
				playerID,
				slot,
				phase,
				now,
				snapshot,
				loads
			)
			local record = XHSBotPlayerRegistry:GetBot(playerID)
			if record ~= nil and existing ~= nil
				and AssignmentKey(existing) ~= AssignmentKey(self.assignments[playerID]) then
				record.assignment_changes = (record.assignment_changes or 0) + 1
			end
		elseif phase == 3 and existing.goal == "fight_boss" then
			local target = self.visible_boss
			if IsValidEntityHandle(target)
				and existing.target_entindex == target:entindex() then
				existing.anchor = CopyPosition(target:GetAbsOrigin())
			end
		elseif phase == 3 and existing.goal == "regroup" then
			local hero = XHSBotPlayerRegistry:GetBotHero(playerID)
			local followAnchor, followHumanPlayerID, followRadius =
				self:GetPhaseHumanFollowAnchor(
					playerID,
					slot,
					hero,
					existing.follow_human_player_id
				)
			existing.anchor = followAnchor
				or self:GetPhaseThreeStagingAnchor(playerID, hero)
			existing.follow_human_player_id = followHumanPlayerID
			existing.follow_radius = followRadius
			existing.label = followAnchor ~= nil
				and "PHASE 3/4 FOLLOWING PLAYER"
				or "PHASE 3/4 STAGING"
			local record = XHSBotPlayerRegistry:GetBot(playerID)
			if record ~= nil then
				record.follow_human_player_id = followHumanPlayerID
			end
		elseif existing.goal == "defend_base"
			and snapshot.base_threat.active == true
			and snapshot.base_threat.response_required == true then
			existing.anchor = CopyPosition(snapshot.base_threat.anchor)
			existing.threat_position =
				CopyPosition(snapshot.base_threat.threat_position)
			existing.base_threat_score = snapshot.base_threat.score
			existing.base_threat_count = snapshot.base_threat.threat_count
			existing.base_special_count = snapshot.base_threat.special_count
			existing.base_dragon_count = snapshot.base_threat.dragon_count
			existing.base_immediate_count = snapshot.base_threat.immediate_count
			existing.base_structure_emergency =
				snapshot.base_threat.structure_emergency == true
			existing.objective_loss_seconds =
				snapshot.base_threat.objective_loss_seconds
			existing.objective_incoming_dps =
				snapshot.base_threat.objective_incoming_dps
		elseif existing.goal == "participate_event" then
			local eventAnchor = self:GetFarmEventAnchor(playerID)
			if eventAnchor ~= nil then existing.anchor = eventAnchor end
		elseif existing.goal == "hold" then
			local hero = XHSBotPlayerRegistry:GetBotHero(playerID)
			if IsValidEntityHandle(hero) then existing.anchor = hero:GetAbsOrigin() end
		end
	end

	for playerID in pairs(self.assignments) do
		if XHSBotPlayerRegistry:GetBot(playerID) == nil then
			self.assignments[playerID] = nil
		end
	end
end

function XHSBotTeamDirector:GetTargetClaimCount(target, exceptPlayerID)
	if not IsValidEntityHandle(target) then return 0 end
	local entindex = target:entindex()
	local count = 0
	for _, playerID in ipairs(XHSBotPlayerRegistry:GetXHSBotPlayerIDs()) do
		if playerID ~= tonumber(exceptPlayerID) then
			local record = XHSBotPlayerRegistry:GetBot(playerID)
			if record ~= nil
				and record.target_entindex == entindex
				and record.alive ~= false then
				count = count + 1
			end
		end
	end
	return count
end

function XHSBotTeamDirector:GetTargetChaseLimit(playerID, target)
	if not IsValidEntityHandle(target) then return 0 end
	if XHSBotConfig:IsBossTarget(target) or target:IsHero() then
		return math.huge
	end
	local record = XHSBotPlayerRegistry:GetBot(playerID)
	local difficulty = XHSBotConfig:GetDifficulty(record and record.difficulty or "normal")
	return math.max(1, tonumber(difficulty.max_basic_chasers) or 1)
end

function XHSBotTeamDirector:CanPursueTarget(playerID, target)
	local limit = self:GetTargetChaseLimit(playerID, target)
	return limit == math.huge
		or self:GetTargetClaimCount(target, playerID) < limit
end

function XHSBotTeamDirector:GetAssignment(playerID)
	return self.assignments[tonumber(playerID)]
end

function XHSBotTeamDirector:Reset()
	self.assignments = {}
	self.next_update = 0
	self.last_strategy = nil
	self.visible_boss = nil
	self.last_seen_boss_entindex = nil
	self.last_seen_boss_position = nil
	self.last_seen_boss_at = nil
	self.shopping_allowed = {}
	self.base_threat_score = 0
	self.base_threat_active = false
	self.base_threat_hold_until = 0
	self.base_response_hold_until = 0
	self.base_threat_last_sample_at = 0
	self.base_threat_unit_samples = {}
	self.base_threat_fort_health = nil
end

return XHSBotTeamDirector
