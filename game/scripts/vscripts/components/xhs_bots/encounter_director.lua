if XHSBotEncounterDirector == nil then
	XHSBotEncounterDirector = {}
end

local SPECIAL_ARENA_RADIUS = 2300
local ARENA_COMBAT_CHASE_DISTANCE = 6000
local MURADIN_ESCAPE_REACHED_DISTANCE = 180
local FARM_TARGET_RADIUS = 1900

local function IsValidEntityHandle(entity)
	return entity ~= nil
		and IsValidEntity(entity)
		and not entity:IsNull()
end

local function IsValidCombatUnit(unit)
	return IsValidEntityHandle(unit)
		and unit:IsAlive()
		and not unit:IsInvulnerable()
end

local function Distance2D(left, right)
	return (left - right):Length2D()
end

local function CopyPosition(position)
	if position == nil then return nil end
	return Vector(position.x, position.y, position.z or 0)
end

local function GetArenaCenter()
	local center = Entities:FindByName(nil, "npc_dota_muradin_boss")
	if IsValidEntityHandle(center) then return center:GetAbsOrigin() end
	return Vector(0, 0, 0)
end

local function GetEntityByIndex(entindex)
	entindex = tonumber(entindex)
	if entindex == nil or entindex < 0 or EntIndexToHScript == nil then return nil end
	local ok, entity = pcall(EntIndexToHScript, entindex)
	return ok and IsValidEntityHandle(entity) and entity or nil
end

function XHSBotEncounterDirector:IsArenaParticipant(playerID, hero)
	if SpecialEvents ~= nil
		and tonumber(SpecialEvents.active_arena_player_id) == tonumber(playerID) then
		return true
	end
	return IsValidEntityHandle(hero)
		and Distance2D(hero:GetAbsOrigin(), GetArenaCenter()) <= SPECIAL_ARENA_RADIUS
end

function XHSBotEncounterDirector:FindMuradin()
	local center = GetArenaCenter()
	local units = FindUnitsInRadius(
		DOTA_TEAM_GOODGUYS,
		center,
		nil,
		SPECIAL_ARENA_RADIUS,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_INVULNERABLE
			+ DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		FIND_CLOSEST,
		false
	)
	for _, unit in pairs(units or {}) do
		if IsValidEntityHandle(unit)
			and unit:GetUnitName() == "npc_dota_creature_muradin_bronzebeard" then
			return unit
		end
	end
	return nil
end

function XHSBotEncounterDirector:GetMuradinEscapePosition(playerID, hero, muradin)
	local candidates = {}
	local seen = {}
	local function AddEntity(entity)
		if not IsValidEntityHandle(entity) then return end
		local entindex = entity:entindex()
		if seen[entindex] then return end
		seen[entindex] = true
		table.insert(candidates, entity:GetAbsOrigin())
	end

	for index = 0, 23 do
		AddEntity(Entities:FindByName(nil, "npc_dota_muradin_player_" .. tostring(index)))
	end
	for index = 1, 4 do
		AddEntity(Entities:FindByName(nil, "roshan_wp_" .. tostring(index)))
	end

	if #candidates == 0 then
		local center = GetArenaCenter()
		for index = 0, 7 do
			local angle = math.rad(index * 45)
			table.insert(candidates, center + Vector(math.cos(angle), math.sin(angle), 0) * 1050)
		end
	end

	local threatPosition = IsValidEntityHandle(muradin)
		and muradin:GetAbsOrigin()
		or GetArenaCenter()
	local best = nil
	local bestScore = -math.huge
	for index, position in ipairs(candidates) do
		local score = Distance2D(position, threatPosition)
		-- Stable tie-breaking spreads several bots instead of stacking all of
		-- them on the exact same corner when Muradin is centered.
		local preferred = (tonumber(playerID) or 0) % #candidates + 1
		local circularDistance = math.min(
			math.abs(index - preferred),
			#candidates - math.abs(index - preferred)
		)
		score = score - circularDistance * 8
		if score > bestScore then
			best = position
			bestScore = score
		end
	end
	return CopyPosition(best or hero:GetAbsOrigin())
end

function XHSBotEncounterDirector:GetFarmTarget(playerID, hero)
	local enemies = FindUnitsInRadius(
		hero:GetTeamNumber(),
		hero:GetAbsOrigin(),
		nil,
		FARM_TARGET_RADIUS,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE
			+ DOTA_UNIT_TARGET_FLAG_NO_INVIS
			+ DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		FIND_ANY_ORDER,
		false
	)
	local best = nil
	local bestScore = math.huge
	for _, enemy in pairs(enemies or {}) do
		if IsValidCombatUnit(enemy)
			and enemy.xhs_farm_event == true
			and tonumber(enemy.xhs_farm_event_player_id) == tonumber(playerID) then
			local healthRatio = enemy:GetHealth() / math.max(1, enemy:GetMaxHealth())
			local score = healthRatio * 1000
				+ Distance2D(hero:GetAbsOrigin(), enemy:GetAbsOrigin()) * 0.08
				+ enemy:entindex() * 0.00001
			if score < bestScore then
				best = enemy
				bestScore = score
			end
		end
	end
	return best
end

function XHSBotEncounterDirector:GetArenaBoss(mode)
	if SpecialEvents == nil then return nil end
	if mode == "ramero_baristol" then
		-- Baristol can heal and protect the duo, so coordinated bots focus him
		-- before finishing Ramero.
		if IsValidCombatUnit(SpecialEvents.Baristol) then return SpecialEvents.Baristol end
		if IsValidCombatUnit(SpecialEvents.Ramero) then return SpecialEvents.Ramero end
	elseif mode == "sogat" and IsValidCombatUnit(SpecialEvents.Sogat) then
		return SpecialEvents.Sogat
	end
	return nil
end

function XHSBotEncounterDirector:GetPhase2Target(hero, assignment)
	local anchor = assignment and assignment.anchor or hero:GetAbsOrigin()
	local fort = Entities:FindByName(nil, "dota_goodguys_fort")
		or Entities:FindByName(nil, "base_spawn")
	local defensePosition = IsValidEntityHandle(fort)
		and fort:GetAbsOrigin()
		or anchor
	local enemies = FindUnitsInRadius(
		hero:GetTeamNumber(),
		anchor,
		nil,
		2400,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE
			+ DOTA_UNIT_TARGET_FLAG_NO_INVIS
			+ DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		FIND_ANY_ORDER,
		false
	)
	local best = nil
	local bestScore = math.huge
	for _, enemy in pairs(enemies or {}) do
		local name = IsValidEntityHandle(enemy) and enemy:GetUnitName() or ""
		if IsValidCombatUnit(enemy)
			and (name == "npc_ghul_II" or name == "npc_orc_II") then
			-- The deepest creep is the one most likely to reach the ice towers
			-- or castle. Missing health then breaks ties to secure the kill.
			local score = Distance2D(enemy:GetAbsOrigin(), defensePosition)
				+ enemy:GetHealth() / math.max(1, enemy:GetMaxHealth()) * 180
			if score < bestScore then
				best = enemy
				bestScore = score
			end
		end
	end
	return best
end

function XHSBotEncounterDirector:GetPhase3VanguardTarget(hero)
	local enemies = FindUnitsInRadius(
		hero:GetTeamNumber(),
		hero:GetAbsOrigin(),
		nil,
		2800,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE
			+ DOTA_UNIT_TARGET_FLAG_NO_INVIS
			+ DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		FIND_ANY_ORDER,
		false
	)
	local best = nil
	local bestScore = math.huge
	for _, enemy in pairs(enemies or {}) do
		if IsValidCombatUnit(enemy) and enemy.xhs_grom_vanguard_unit == true then
			local healthRatio = enemy:GetHealth() / math.max(1, enemy:GetMaxHealth())
			local score = Distance2D(hero:GetAbsOrigin(), enemy:GetAbsOrigin())
				+ healthRatio * 260
			if enemy.GetAttackTarget ~= nil then
				local ok, attackTarget = pcall(function()
					return enemy:GetAttackTarget()
				end)
				if ok and attackTarget == hero then score = score - 450 end
			end
			if score < bestScore then
				best = enemy
				bestScore = score
			end
		end
	end
	return best
end

function XHSBotEncounterDirector:GetPhase3VanguardAnchor(playerID, hero)
	local point = Entities:FindByName(
		nil,
		"point_teleport_phase3_creeps_" .. tostring(playerID)
	)
	if not IsValidEntityHandle(point) then
		point = Entities:FindByName(nil, "point_teleport_phase3_creeps_1")
	end
	return IsValidEntityHandle(point)
		and point:GetAbsOrigin()
		or hero:GetAbsOrigin()
end

function XHSBotEncounterDirector:IsMuradinSurvivalActive(hero)
	return IsValidEntityHandle(hero)
		and GameMode ~= nil
		and GameMode.Muradin_occuring == true
		and Distance2D(hero:GetAbsOrigin(), GetArenaCenter()) <= SPECIAL_ARENA_RADIUS
end

function XHSBotEncounterDirector:Build(playerID, hero, record, assignment)
	if not IsValidEntityHandle(hero) then return nil end

	if self:IsMuradinSurvivalActive(hero) then
		local muradin = self:FindMuradin()
		return {
			id = "muradin_survival",
			no_combat = true,
			no_retreat = true,
			anchor = self:GetMuradinEscapePosition(playerID, hero, muradin),
			threat = muradin,
			reached_distance = MURADIN_ESCAPE_REACHED_DISTANCE,
			max_chase_distance = 0,
		}
	end

	if GameMode ~= nil
		and GameMode.SpecialArena_occuring == true
		and self:IsArenaParticipant(playerID, hero) then
		local mode = SpecialEvents ~= nil and tonumber(SpecialEvents.Ramero_trigger) or 0
		if mode == 1 or mode == 2 then
			local id = mode == 1 and "ramero_baristol" or "sogat"
			return {
				id = id,
				arena_combat = true,
				no_retreat = true,
				no_reposition = true,
				anchor = GetArenaCenter(),
				forced_target = self:GetArenaBoss(id),
				-- The arena radius is measured from its center, while chase
				-- distance is measured hero-to-boss. Opposite edges can be
				-- almost twice as far apart, so the generic 2300 leash could
				-- reject every attack order after a knockback or boss chase.
				max_chase_distance = ARENA_COMBAT_CHASE_DISTANCE,
			}
		end
	end

	if GameMode ~= nil
		and GameMode.FarmEvent_occuring == true
		and SpecialEvents ~= nil
		and type(SpecialEvents.hero_farm_event) == "table"
		and type(
			SpecialEvents.hero_farm_event[tonumber(playerID)]
				or SpecialEvents.hero_farm_event[tostring(playerID)]
		) == "table" then
		local point = Entities:FindByName(nil, "farm_event_player_" .. tostring(playerID))
		return {
			id = "farm_event",
			farm = true,
			no_retreat = true,
			anchor = IsValidEntityHandle(point) and point:GetAbsOrigin() or hero:GetAbsOrigin(),
			forced_target = self:GetFarmTarget(playerID, hero),
			max_chase_distance = 1500,
		}
	end

	local phase = CustomTimers ~= nil and tonumber(CustomTimers.game_phase) or 1
	local assignmentGoal = assignment and assignment.goal or nil
	-- Shopping is an explicit team-director commitment. Phase policies must not
	-- drag a bot out of either shop while its purchase trip is in progress.
	if assignmentGoal == "shop" then return nil end
	local vanguardTarget = nil
	if phase >= 3
		and GameMode ~= nil
		and type(GameMode.GromVanguard) == "table"
		and GameMode.GromVanguard.started == true
		and GameMode.GromVanguard.gate_opened ~= true then
		vanguardTarget = self:GetPhase3VanguardTarget(hero)
	end
	if phase == 2 then
		return {
			id = "phase_2",
			anchor = assignment and CopyPosition(assignment.anchor) or hero:GetAbsOrigin(),
			forced_target = self:GetPhase2Target(hero, assignment),
			max_chase_distance = assignment and assignment.chase_radius or 1800,
		}
	elseif IsValidCombatUnit(vanguardTarget) then
		return {
			id = "phase_3_vanguard",
			anchor = self:GetPhase3VanguardAnchor(playerID, hero),
			forced_target = vanguardTarget,
			max_chase_distance = 2800,
		}
	elseif phase >= 3 then
		local assignedTarget = assignment
			and GetEntityByIndex(assignment.target_entindex)
			or nil
		return {
			id = "phase_3",
			anchor = assignment and CopyPosition(assignment.anchor) or hero:GetAbsOrigin(),
			forced_target = IsValidCombatUnit(assignedTarget) and assignedTarget or nil,
			max_chase_distance = assignment and assignment.chase_radius or 3200,
		}
	end
	return nil
end

function XHSBotEncounterDirector:IsTargetAllowed(policy, playerID, target)
	if policy == nil then return true end
	if policy.no_combat == true then return false end
	if not IsValidCombatUnit(target) then return false end

	if policy.id == "ramero_baristol" then
		-- This is a strict kill order, not merely a preference. Allowing both
		-- names here let generic target selection drift onto Ramero whenever a
		-- committed target was refreshed.
		local priority = self:GetArenaBoss("ramero_baristol")
		return IsValidCombatUnit(priority)
			and target:entindex() == priority:entindex()
	elseif policy.id == "sogat" then
		return target:GetUnitName() == "npc_ramero_2"
	elseif policy.id == "farm_event" then
		return target.xhs_farm_event == true
			and tonumber(target.xhs_farm_event_player_id) == tonumber(playerID)
	elseif policy.id == "phase_2" then
		return target.xhs_farm_event ~= true
			and target:GetUnitName() ~= "npc_dota_creature_muradin_bronzebeard"
			and (policy.anchor == nil
				or Distance2D(target:GetAbsOrigin(), policy.anchor) <= 2300)
	elseif policy.id == "phase_3_vanguard" then
		return target.xhs_grom_vanguard_unit == true
	end
	return true
end

return XHSBotEncounterDirector
