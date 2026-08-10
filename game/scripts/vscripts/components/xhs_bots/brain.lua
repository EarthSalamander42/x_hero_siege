if XHSBotBrain == nil then
	XHSBotBrain = {}
end
XHSBotBrain.rune_claims = XHSBotBrain.rune_claims or {}
XHSBotBrain.enemy_query_cache = XHSBotBrain.enemy_query_cache or {}

local function IsValidEntityHandle(entity)
	return entity ~= nil and IsValidEntity(entity) and not entity:IsNull()
end

local function HealthRatio(unit)
	return unit:GetHealth() / math.max(1, unit:GetMaxHealth())
end

local function ManaRatio(unit)
	return unit:GetMana() / math.max(1, unit:GetMaxMana())
end

local function EntityFromIndex(entindex)
	if entindex == nil then return nil end
	local ok, entity = pcall(EntIndexToHScript, entindex)
	if ok and IsValidEntityHandle(entity) then return entity end
	return nil
end

local function Distance2D(left, right)
	return (left - right):Length2D()
end

local function ClockSeconds()
	if os ~= nil and os.clock ~= nil then
		local ok, value = pcall(os.clock)
		if ok and tonumber(value) ~= nil then return tonumber(value) end
	end
	if Time ~= nil then
		local ok, value = pcall(Time)
		if ok and tonumber(value) ~= nil then return tonumber(value) end
	end
	return GameRules ~= nil and GameRules:GetGameTime() or 0
end

local function CopyPosition(position)
	if position == nil then return nil end
	return Vector(position.x, position.y, position.z or 0)
end

local function PositionToward(origin, destination, distance)
	if origin == nil or destination == nil then return origin end
	local delta = destination - origin
	delta.z = 0
	local remaining = delta:Length2D()
	if remaining <= 1 then return CopyPosition(destination) end
	return origin + delta:Normalized() * math.min(
		remaining,
		math.max(0, tonumber(distance) or 0)
	)
end

local function Clamp(value, minimum, maximum)
	return math.max(minimum, math.min(maximum, tonumber(value) or minimum))
end

local function GetFortEntity()
	local fort = Entities:FindByName(nil, "dota_goodguys_fort")
		or Entities:FindByName(nil, "base_spawn")
	return IsValidEntityHandle(fort) and fort or nil
end

local function GetFortPosition()
	local fort = GetFortEntity()
	return fort ~= nil and fort:GetAbsOrigin() or Vector(0, 0, 0)
end

local CAMPFIRE_AURA_RADIUS = 700
local CAMPFIRE_INNER_BUFFER = 70
local ANCIENT_RETREAT_LIMIT_RADIUS = 950
local BASE_LAST_STAND_RADIUS = 1300
local RUNE_MAX_ROUTE_DISTANCE = 12000
local RUNE_CLAIM_TTL = 3.0
local STRATEGIC_SPECIAL_WAVE_RADIUS = 5200
local BOT_QUERY_BUCKET_SIZE = 700
local BOT_QUERY_BUCKET_PADDING = 500
local BOT_QUERY_RADIUS_STEP = 250
local BOT_ENEMY_QUERY_CACHE_TTL = 0.18
local BOT_QUERY_CACHE_PRUNE_INTERVAL = 2.0
local GROM_MIRROR_REAL_NAME = "npc_dota_hero_grom_hellscream"
local GROM_MIRROR_CLONE_NAME = "npc_dota_hero_grom_hellscream_clone"

local DEFENSIVE_STRUCTURE_NAMES = {
	npc_dota_defender_fort = true,
	npc_dota_holdout_tower = true,
	npc_tower_cold = true,
	npc_tower_death = true,
}

local NON_COMBAT_INTERACTION_UNIT_NAMES = {
	npc_xhs_paladin = true,
	npc_xhs_paladin_2 = true,
}

local function IsNonCombatInteractionUnit(unit)
	if not IsValidEntityHandle(unit) then return false end
	local name = tostring(unit.GetUnitName ~= nil and unit:GetUnitName() or "")
	if NON_COMBAT_INTERACTION_UNIT_NAMES[name] == true
		or unit.xhs_freed_shal_lightbinder == true then
		return true
	end
	return unit.HasModifier ~= nil
		and unit:HasModifier("modifier_npc_dialog")
end

function XHSBotBrain:IsTeamVisible(hero, unit)
	if not IsValidEntityHandle(hero) or not IsValidEntityHandle(unit) then return false end
	if unit.IsInvisible ~= nil and unit:IsInvisible() then return false end
	if hero.CanEntityBeSeenByMyTeam ~= nil then
		local ok, visible = pcall(function()
			return hero:CanEntityBeSeenByMyTeam(unit)
		end)
		if ok then return visible == true end
	end
	-- FindUnitsInRadius with FOW_VISIBLE is the primary perception path. If an
	-- engine build does not expose the direct query, fail closed for remembered
	-- entities and let the next visible radius scan reacquire them.
	return false
end

function XHSBotBrain:IncrementSpatialCacheCounter(name)
	if XHSPerformanceCounters ~= nil
		and XHSPerformanceCounters.Increment ~= nil then
		XHSPerformanceCounters:Increment(name, 1)
	end
end

function XHSBotBrain:PruneEnemyQueryCache(now)
	if now < (tonumber(self.next_enemy_query_cache_prune_at) or 0) then return end
	self.next_enemy_query_cache_prune_at = now + BOT_QUERY_CACHE_PRUNE_INTERVAL
	for key, entry in pairs(self.enemy_query_cache or {}) do
		if type(entry) ~= "table"
			or now >= (tonumber(entry.expires_at) or 0) then
			self.enemy_query_cache[key] = nil
		end
	end
end

function XHSBotBrain:BeginQueryContext(hero)
	self.query_context = {
		hero_entindex = IsValidEntityHandle(hero) and hero:entindex() or -1,
		friendly_radius = 0,
		friendly_units = nil,
	}
end

function XHSBotBrain:EndQueryContext(hero)
	local context = self.query_context
	if context == nil then return end
	if not IsValidEntityHandle(hero)
		or context.hero_entindex == hero:entindex() then
		self.query_context = nil
	end
end

function XHSBotBrain:GetFriendlyQueryUnits(hero, radius)
	radius = math.max(0, tonumber(radius) or 0)
	local context = self.query_context
	local canCache = context ~= nil
		and IsValidEntityHandle(hero)
		and context.hero_entindex == hero:entindex()
	if canCache
		and context.friendly_units ~= nil
		and radius <= (tonumber(context.friendly_radius) or 0) then
		self:IncrementSpatialCacheCounter("spatial_cache_hits")
		return context.friendly_units
	end

	self:IncrementSpatialCacheCounter("spatial_cache_misses")
	local units = FindUnitsInRadius(
		hero:GetTeamNumber(),
		hero:GetAbsOrigin(),
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE or 0,
		FIND_ANY_ORDER,
		false
	)
	if canCache then
		context.friendly_radius = radius
		context.friendly_units = units
	end
	return units
end

function XHSBotBrain:FilterFriendlyQueryUnits(hero, units, radius, heroesOnly)
	local filtered = {}
	local origin = hero:GetAbsOrigin()
	for _, unit in pairs(units or {}) do
		if IsValidEntityHandle(unit)
			and Distance2D(origin, unit:GetAbsOrigin()) <= radius
			and (not heroesOnly or unit:IsHero())
			and (not heroesOnly or unit.IsIllusion == nil or not unit:IsIllusion()) then
			table.insert(filtered, unit)
		end
	end
	return filtered
end

function XHSBotBrain:FindEnemies(hero, radius)
	if GameMode ~= nil
		and GameMode.FarmEvent_occuring == true
		and SpecialEvents ~= nil
		and SpecialEvents.GetFarmEventActiveUnits ~= nil then
		local playerID = hero:GetPlayerOwnerID()
		local enemies = {}
		for _, unit in ipairs(SpecialEvents:GetFarmEventActiveUnits(playerID)) do
			if IsValidEntityHandle(unit)
				and unit:IsAlive()
				and not unit:IsInvulnerable()
				and Distance2D(hero:GetAbsOrigin(), unit:GetAbsOrigin()) <= radius then
				table.insert(enemies, unit)
			end
		end
		return enemies
	end

	radius = math.max(0, tonumber(radius) or 0)
	local origin = hero:GetAbsOrigin()
	local now = GameRules:GetGameTime()
	self:PruneEnemyQueryCache(now)

	local bucketX = math.floor((origin.x + BOT_QUERY_BUCKET_SIZE * 0.5)
		/ BOT_QUERY_BUCKET_SIZE)
	local bucketY = math.floor((origin.y + BOT_QUERY_BUCKET_SIZE * 0.5)
		/ BOT_QUERY_BUCKET_SIZE)
	local queryRadius = math.ceil(radius / BOT_QUERY_RADIUS_STEP)
		* BOT_QUERY_RADIUS_STEP
	local key = table.concat({
		tostring(hero:GetTeamNumber()),
		tostring(bucketX),
		tostring(bucketY),
		tostring(queryRadius),
	}, ":")
	local entry = self.enemy_query_cache[key]
	local cacheHit = type(entry) == "table"
		and now < (tonumber(entry.expires_at) or 0)
		and type(entry.units) == "table"
	if not cacheHit then
		local queryOrigin = Vector(
			bucketX * BOT_QUERY_BUCKET_SIZE,
			bucketY * BOT_QUERY_BUCKET_SIZE,
			origin.z
		)
		entry = {
			expires_at = now + BOT_ENEMY_QUERY_CACHE_TTL,
			units = FindUnitsInRadius(
				hero:GetTeamNumber(),
				queryOrigin,
				nil,
				queryRadius + BOT_QUERY_BUCKET_PADDING,
				DOTA_UNIT_TARGET_TEAM_ENEMY,
				DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
				DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE
					+ DOTA_UNIT_TARGET_FLAG_NO_INVIS
					+ DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
				FIND_ANY_ORDER,
				false
			),
		}
		self.enemy_query_cache[key] = entry
		self:IncrementSpatialCacheCounter("spatial_cache_misses")
	else
		self:IncrementSpatialCacheCounter("spatial_cache_hits")
	end

	local enemies = {}
	local distances = {}
	for _, unit in pairs(entry.units or {}) do
		if IsValidEntityHandle(unit)
			and unit:IsAlive()
			and self:IsCombatTarget(unit)
			and Distance2D(origin, unit:GetAbsOrigin()) <= radius
			and (unit.IsInvisible == nil or not unit:IsInvisible()) then
			table.insert(enemies, unit)
			distances[unit:entindex()] = Distance2D(origin, unit:GetAbsOrigin())
		end
	end
	table.sort(enemies, function(left, right)
		return (distances[left:entindex()] or math.huge)
			< (distances[right:entindex()] or math.huge)
	end)
	return enemies
end

function XHSBotBrain:IsCombatTarget(unit)
	if not IsValidEntityHandle(unit) or not unit:IsAlive() or unit:IsInvulnerable() then return false end
	if IsNonCombatInteractionUnit(unit) then return false end
	local name = unit:GetUnitName()
	if name == "npc_dota_crate"
		or name == "npc_dota_chest"
		or name == "npc_dota_vase"
		or name == "item_lua"
		or name == ""
		or unit.GetClassname ~= nil
			and (
				unit:GetClassname() == "dota_item_drop"
				or unit:GetClassname() == "dota_item_physical"
			)
		or string.find(name, "dummy", 1, true) ~= nil then
		return false
	end
	return true
end

function XHSBotBrain:UpdateLaneReturnState(hero, assignment, record)
	if type(record) ~= "table" then return false end
	if not IsValidEntityHandle(hero)
		or assignment == nil
		or assignment.goal ~= "defend_lane"
		or assignment.anchor == nil then
		record.returning_to_lane = false
		if assignment ~= nil then assignment.returning_to_lane = false end
		return false
	end

	local distance = Distance2D(hero:GetAbsOrigin(), assignment.anchor)
	local anchorLeash = tonumber(assignment.anchor_leash) or 1700
	local enterDistance = math.max(850, math.min(1050, anchorLeash * 0.62))
	local exitDistance = math.min(475, enterDistance * 0.5)
	local returning = record.returning_to_lane == true
	if returning and distance <= exitDistance then
		returning = false
		record.returned_to_lane_count = (record.returned_to_lane_count or 0) + 1
	elseif not returning and distance >= enterDistance then
		returning = true
		record.return_to_lane_count = (record.return_to_lane_count or 0) + 1
		record.return_to_lane_started_at = GameRules:GetGameTime()
	end

	record.returning_to_lane = returning
	record.lane_anchor_distance = distance
	assignment.returning_to_lane = returning
	assignment.lane_return_enter_distance = enterDistance
	assignment.lane_return_exit_distance = exitDistance
	return returning
end

function XHSBotBrain:IsTargetAllowedByAssignment(playerID, hero, target, assignment, difficulty)
	if not self:IsCombatTarget(target) then return false end
	if assignment == nil or assignment.anchor == nil then return true end
	if assignment.goal == "hold" or assignment.goal == "selecting_hero"
		or assignment.goal == "dead" then
		return false
	end
	if assignment.goal == "shop" then
		local distance = Distance2D(hero:GetAbsOrigin(), target:GetAbsOrigin())
		local attacksHero = false
		if target.GetAttackTarget ~= nil then
			local ok, attackTarget = pcall(function()
				return target:GetAttackTarget()
			end)
			attacksHero = ok and attackTarget == hero
		end
		-- Shop logistics never make the bot pacifist. Threats already inside
		-- the base/self-defense envelope may be selected immediately.
		return attacksHero
			or distance <= math.max(
				900,
				tonumber(difficulty.self_defense_radius) or 650
			)
	end
	if assignment.non_combat == true then
		local distance = Distance2D(hero:GetAbsOrigin(), target:GetAbsOrigin())
		local attacksHero = false
		if target.GetAttackTarget ~= nil then
			local ok, attackTarget = pcall(function()
				return target:GetAttackTarget()
			end)
			attacksHero = ok and attackTarget == hero
		end
		return attacksHero
			and distance <= (tonumber(difficulty.self_defense_radius) or 650)
	end

	if target.xhs_farm_event == true then
		return assignment.goal == "participate_event"
			and tonumber(target.xhs_farm_event_player_id) == tonumber(playerID)
	end

	if assignment.returning_to_lane == true then
		local distance = Distance2D(hero:GetAbsOrigin(), target:GetAbsOrigin())
		local attacksHero = false
		if target.GetAttackTarget ~= nil then
			local ok, attackTarget = pcall(function() return target:GetAttackTarget() end)
			attacksHero = ok and attackTarget == hero
		end
		return attacksHero
			and distance <= math.min(400, tonumber(difficulty.self_defense_radius) or 650)
	end

	local targetFromAnchor = Distance2D(target:GetAbsOrigin(), assignment.anchor)
	local chaseRadius = tonumber(assignment.chase_radius)
		or tonumber(difficulty.max_chase_distance)
		or 1200
	if Distance2D(hero:GetAbsOrigin(), target:GetAbsOrigin()) > chaseRadius then
		return false
	end
	if targetFromAnchor > chaseRadius then
		local immediateDefense = Distance2D(hero:GetAbsOrigin(), target:GetAbsOrigin())
			<= (tonumber(difficulty.self_defense_radius) or 650)
		if not immediateDefense then return false end
	end

	local heroFromAnchor = Distance2D(hero:GetAbsOrigin(), assignment.anchor)
	if heroFromAnchor > (tonumber(assignment.anchor_leash) or difficulty.anchor_leash or 1800)
		and Distance2D(hero:GetAbsOrigin(), target:GetAbsOrigin())
			> (tonumber(difficulty.self_defense_radius) or 650) then
		return false
	end
	return true
end

function XHSBotBrain:ScoreTarget(hero, unit, profile)
	local distance = Distance2D(hero:GetAbsOrigin(), unit:GetAbsOrigin())
	local score = math.max(0, 35 - distance / 80)
	local isBoss = XHSBotConfig:IsBossTarget(unit)
	local attackTarget = unit:GetAttackTarget()

	if isBoss then
		score = score + 55
	elseif unit:IsHero() then
		score = score + 24
	end
	if unit:IsChanneling() then score = score + 25 end
	if unit:GetAttackTarget() == hero then score = score + 10 end
	if profile ~= nil and profile.role == "frontline" then score = score + math.max(0, 10 - distance / 100) end

	for index, priority in ipairs(profile and profile.target_priority or {}) do
		local matched = false
		if priority == "boss" then
			matched = isBoss
		elseif priority == "caster" then
			matched = unit:IsChanneling()
		elseif priority == "ranged" then
			local ok, attackRange = pcall(function() return unit:Script_GetAttackRange() end)
			matched = ok and (tonumber(attackRange) or 0) >= 450
		elseif priority == "threat_to_ally" then
			matched = IsValidEntityHandle(attackTarget)
				and attackTarget:GetTeamNumber() == hero:GetTeamNumber()
				and attackTarget ~= hero
		elseif priority == "nearest" then
			matched = true
		end
		if matched then
			score = score + math.max(2, 12 - (index - 1) * 3)
		end
	end
	return score
end

function XHSBotBrain:SelectGromMirrorTarget(
	playerID,
	hero,
	record,
	assignment,
	difficulty,
	visibleEnemies
)
	local candidates = {}
	local candidateByIndex = {}
	local cloneVisible = false
	for _, enemy in pairs(visibleEnemies or {}) do
		local name = IsValidEntityHandle(enemy) and enemy:GetUnitName() or ""
		if name == GROM_MIRROR_CLONE_NAME then cloneVisible = true end
		if (name == GROM_MIRROR_REAL_NAME or name == GROM_MIRROR_CLONE_NAME)
			and self:IsCombatTarget(enemy)
			and self:IsTeamVisible(hero, enemy)
			and self:IsTargetAllowedByAssignment(
				playerID,
				hero,
				enemy,
				assignment,
				difficulty
			) then
			table.insert(candidates, enemy)
			candidateByIndex[enemy:entindex()] = enemy
		end
	end

	if not cloneVisible then
		record.grom_mirror_signature = nil
		record.grom_mirror_target_entindex = nil
		return nil, false
	end
	local assignedBoss = assignment ~= nil
		and EntityFromIndex(assignment.target_entindex) or nil
	if IsValidEntityHandle(assignedBoss)
		and assignedBoss:GetUnitName() == GROM_MIRROR_REAL_NAME
		and assignedBoss:IsAlive()
		and assignedBoss:IsInvulnerable() then
		-- The clones appear a fraction before the real image loses its split
		-- invulnerability. Wait for the complete choice set instead of making the
		-- first selection from a list that can only contain fakes.
		return nil, true
	end
	if #candidates <= 0 then return nil, true end

	-- Entindexes identify the real unit on the server, so they may only provide
	-- stable ordering/state here. The actual choice is uniform across every
	-- visible image and never uses boss flags, unit names, damage or max health.
	table.sort(candidates, function(left, right)
		return left:entindex() < right:entindex()
	end)
	local indices = {}
	for _, candidate in ipairs(candidates) do
		table.insert(indices, candidate:entindex())
	end
	local signature = table.concat(indices, ",")
	local selected = candidateByIndex[
		tonumber(record.grom_mirror_target_entindex) or -1
	]
	if record.grom_mirror_signature ~= signature or selected == nil then
		selected = candidates[RandomInt(1, #candidates)]
		record.grom_mirror_signature = signature
		record.grom_mirror_target_entindex = selected:entindex()
		record.grom_mirror_choices = (record.grom_mirror_choices or 0) + 1
	end
	return selected, true
end

function XHSBotBrain:RememberVisibleTarget(record, target, difficulty, now)
	if not self:IsCombatTarget(target) then return end
	now = tonumber(now) or GameRules:GetGameTime()
	record.last_seen_position = CopyPosition(target:GetAbsOrigin())
	record.last_seen_at = now
	record.last_seen_until = now + (tonumber(difficulty.target_memory_duration) or 1)
end

function XHSBotBrain:SelectTarget(playerID, hero, profile, record, assignment, difficulty, visibleEnemies)
	local now = GameRules:GetGameTime()
	local mirrorTarget, mirrorHandled = self:SelectGromMirrorTarget(
		playerID,
		hero,
		record,
		assignment,
		difficulty,
		visibleEnemies
	)
	if mirrorHandled then
		-- Do this before commitment and assigned-target handling: both retain the
		-- real boss entindex from before the shuffle and would otherwise reveal it.
		record.target_committed_until = now
		if mirrorTarget ~= nil then
			self:RememberVisibleTarget(record, mirrorTarget, difficulty, now)
			return mirrorTarget, 75
		end
		return nil, -math.huge
	end
	local committed = EntityFromIndex(record.target_entindex)
	if self:IsCombatTarget(committed)
		and committed:GetTeamNumber() ~= hero:GetTeamNumber()
		and now < (record.target_committed_until or 0)
		and self:IsTeamVisible(hero, committed)
		and self:IsTargetAllowedByAssignment(playerID, hero, committed, assignment, difficulty) then
		self:RememberVisibleTarget(record, committed, difficulty, now)
		return committed, record.target_score or 0
	end

	if assignment ~= nil and assignment.target_entindex ~= nil then
		local assignedTarget = EntityFromIndex(assignment.target_entindex)
		if self:IsCombatTarget(assignedTarget)
			and assignedTarget:GetTeamNumber() ~= hero:GetTeamNumber()
			and self:IsTeamVisible(hero, assignedTarget)
			and self:IsTargetAllowedByAssignment(playerID, hero, assignedTarget, assignment, difficulty) then
			self:RememberVisibleTarget(record, assignedTarget, difficulty, now)
			return assignedTarget, 75
		end
	end

	local best = nil
	local bestScore = -math.huge
	for _, enemy in pairs(visibleEnemies or {}) do
		local claims = XHSBotTeamDirector:GetTargetClaimCount(enemy, playerID)
		local claimLimit = XHSBotTeamDirector:GetTargetChaseLimit(playerID, enemy)
		if self:IsCombatTarget(enemy)
			and self:IsTargetAllowedByAssignment(playerID, hero, enemy, assignment, difficulty)
			and (claimLimit == math.huge or claims < claimLimit) then
			local claimPenalty = claims * 11
			local score = self:ScoreTarget(hero, enemy, profile) - claimPenalty
			if score > bestScore then
				best = enemy
				bestScore = score
			end
		end
	end
	if best ~= nil then self:RememberVisibleTarget(record, best, difficulty, now) end
	return best, bestScore
end

function XHSBotBrain:IsSpecialThreat(unit)
	if not self:IsCombatTarget(unit) then return false end
	local active = CustomTimers and CustomTimers.active_special_wave_units or nil
	if type(active) ~= "table" then return false end
	local index = unit:entindex()
	if active[index] == true
		or active[index] == unit
		or active[tostring(index)] == true
		or active[tostring(index)] == unit then return true end
	for _, value in pairs(active) do
		if value == unit or tonumber(value) == index then return true end
	end
	return false
end

function XHSBotBrain:BuildThreatPacks(hero, enemies)
	local candidates = {}
	for _, enemy in pairs(enemies or {}) do
		if self:IsCombatTarget(enemy) and self:IsTeamVisible(hero, enemy) then
			table.insert(candidates, enemy)
			if #candidates >= 32 then break end
		end
	end

	local packs = {}
	local claimed = {}
	for seedIndex, seed in ipairs(candidates) do
		if not claimed[seedIndex] then
			local pack = { members = {}, indices = {} }
			local queue = { seedIndex }
			claimed[seedIndex] = true
			local cursor = 1
			while cursor <= #queue do
				local candidateIndex = queue[cursor]
				cursor = cursor + 1
				local candidate = candidates[candidateIndex]
				table.insert(pack.members, candidate)
				table.insert(pack.indices, candidate:entindex())
				for otherIndex, other in ipairs(candidates) do
					if not claimed[otherIndex]
						and Distance2D(candidate:GetAbsOrigin(), other:GetAbsOrigin()) <= 575 then
						claimed[otherIndex] = true
						table.insert(queue, otherIndex)
					end
				end
			end
			table.sort(pack.indices)
			pack.signature = table.concat(pack.indices, ",")
			table.insert(packs, pack)
		end
	end
	return packs
end

function XHSBotBrain:EvaluateThreatPacks(
	playerID,
	hero,
	profile,
	record,
	assignment,
	difficulty,
	enemies
)
	local allowedEnemies = {}
	for _, enemy in pairs(enemies or {}) do
		if self:IsTargetAllowedByAssignment(
			playerID,
			hero,
			enemy,
			assignment,
			difficulty
		) then
			table.insert(allowedEnemies, enemy)
		end
	end
	local packs = self:BuildThreatPacks(hero, allowedEnemies)
	local heroOrigin = hero:GetAbsOrigin()
	local preferredRange = tonumber(profile and profile.preferred_range) or 0
	local attackRange = 0
	if hero.Script_GetAttackRange ~= nil then
		local ok, value = pcall(function() return hero:Script_GetAttackRange() end)
		if ok then attackRange = tonumber(value) or 0 end
	end
	local ranged = preferredRange >= 450 or attackRange >= 450
	local allies = self:GetAllies(hero, 1800)
	local now = GameRules:GetGameTime()
	local best = nil
	local bestScore = -math.huge
	local previous = nil

	for _, pack in ipairs(packs) do
		local sum = Vector(0, 0, 0)
		local forecastEnemies = {}
		local structureEmergency = false
		local bossCount = 0
		local specialCount = 0
		for _, enemy in ipairs(pack.members) do
			sum = sum + enemy:GetAbsOrigin()
			local focused = false
			local attackTarget = nil
			if enemy.GetAttackTarget ~= nil then
				local ok, value = pcall(function() return enemy:GetAttackTarget() end)
				if ok then attackTarget = value end
				focused = attackTarget == hero
			end
			if IsValidEntityHandle(attackTarget)
				and attackTarget.IsBuilding ~= nil
				and attackTarget:IsBuilding() then
				structureEmergency = true
			end
			local enemyRange = 150
			if enemy.Script_GetAttackRange ~= nil then
				local ok, value = pcall(function() return enemy:Script_GetAttackRange() end)
				if ok then enemyRange = math.max(0, tonumber(value) or enemyRange) end
			end
			-- Forecast the fight at contact, not the harmless travel frame. Using
			-- current distance here made every distant lethal wave look farmable.
			local reach = focused and 1
				or enemyRange >= 450 and 0.88
				or ranged and 0.58
				or 0.78
			local boss = XHSBotConfig:IsBossTarget(enemy)
			local special = self:IsSpecialThreat(enemy)
			if boss then bossCount = bossCount + 1 end
			if special then specialCount = specialCount + 1 end
			table.insert(forecastEnemies, {
				effective_health = math.max(1, enemy:GetHealth()),
				projected_dps = self:GetAttackDamageAgainst(enemy, hero)
					* self:GetUnitAttacksPerSecond(enemy),
				reach_factor = reach,
				focused = focused,
				disable_risk = boss and 0.34 or special and 0.16 or 0.03,
				boss = boss,
				special = special,
			})
		end
		pack.position = sum * (1 / math.max(1, #pack.members))
		pack.distance = Distance2D(heroOrigin, pack.position)
		local representative = pack.members[1]
		local allyDPS = 0
		for _, ally in ipairs(allies or {}) do
			if IsValidEntityHandle(ally) and ally ~= hero and ally:IsAlive()
				and Distance2D(ally:GetAbsOrigin(), pack.position) <= 950 then
				allyDPS = allyDPS + self:GetHeroAttackDPSAgainst(ally, representative)
			end
		end
		local areaFactor = 1 + math.min(1.35, (#pack.members - 1)
			* (ranged and 0.08 or 0.18))
		local objectiveLoss = assignment ~= nil
			and tonumber(assignment.objective_loss_seconds) or nil
		local affordablePowerSpike = tostring(record.planned_item or "") ~= ""
			and XHSBotEconomy ~= nil
			and XHSBotEconomy:GetGold(playerID) >= math.max(
				5000,
				(tonumber(record.economy_reserve_gold) or 0) + 2500
			)
		local lifestealPercent, lifestealUptime =
			self:GetForecastAttackLifesteal(hero, profile)
		if lifestealPercent > 2 then lifestealPercent = lifestealPercent / 100 end
		local heroDPS = self:GetHeroAttackDPSAgainst(hero, representative)
		local availableBurst = 0
		for abilityName, rule in pairs(profile and profile.abilities or {}) do
			local offensive = rule.mode == "enemy_unit"
				or rule.mode == "point_aoe"
				or rule.mode == "directional_point"
				or rule.mode == "no_target_enemy"
				or rule.mode == "no_target_mixed"
			if offensive then
				local ability = hero:FindAbilityByName(abilityName)
				if IsValidEntityHandle(ability) and ability:GetLevel() > 0
					and ability:IsFullyCastable() then
					local cooldown = 0
					if ability.GetCooldown ~= nil then
						local ok, value = pcall(function()
							return ability:GetCooldown(math.max(0, ability:GetLevel() - 1))
						end)
						if ok then cooldown = tonumber(value) or 0 end
					end
					if cooldown < 45 then
						local eligibleTarget = nil
						local eligibleCount = 0
						for _, member in ipairs(pack.members) do
							if self:CanAbilityAffectEnemy(ability, member, rule) then
								eligibleTarget = eligibleTarget or member
								eligibleCount = eligibleCount + 1
							end
						end
						if eligibleTarget ~= nil then
							local _, damage = self:GetAbilityDamageAgainst(
								hero,
								ability,
								eligibleTarget,
								rule
							)
							damage = damage * math.max(
								0,
								tonumber(rule.forecast_damage_multiplier) or 1
							)
							local areaTargets = rule.mode == "enemy_unit"
								and (rule.aoe_unit_target == true
									and math.min(eligibleCount, 3) or 1)
								or math.min(eligibleCount, 3)
							availableBurst = availableBurst + damage * areaTargets
						end
					end
				end
			end
		end
		pack.forecast = XHSBotWorldModel:EstimateEngagement({
			maximum_health = hero:GetMaxHealth(),
			current_health = hero:GetHealth(),
			hero_dps = heroDPS,
			available_burst = availableBurst,
			ally_dps = allyDPS,
			enemies = forecastEnemies,
			area_factor = areaFactor,
			combat_uptime = ranged and 0.72 or 0.86,
			sustain_per_second = self:GetUnitHealthRegen(hero)
				+ heroDPS * lifestealPercent * lifestealUptime,
			cover_reduction = structureEmergency and 0.18 or 0,
			ranged = ranged,
			pullable = pack.distance >= 260,
			affordable_power_spike = affordablePowerSpike,
			structure_emergency = structureEmergency,
			objective_loss_time = objectiveLoss,
			travel_time = pack.distance / math.max(100, self:GetUnitMovementSpeed(hero)),
			unavoidable = structureEmergency and assignment ~= nil
				and assignment.goal == "defend_base",
		})
		pack.structure_emergency = structureEmergency
		pack.score = ({
			FARMABLE = 62,
			CONTESTABLE = 42,
			NEEDS_GEAR = 8,
			NEEDS_HELP = 18,
			SUICIDAL = -38,
		})[pack.forecast.classification] or 0
		pack.score = pack.score + pack.forecast.feasibility * 32
			+ (structureEmergency and 125 or 0)
			+ math.min(45, bossCount * 30 + specialCount * 18)
			- pack.distance / 85
		if pack.signature == record.engagement_pack_signature then previous = pack end
		if pack.score > bestScore then best, bestScore = pack, pack.score end
	end

	-- Short hysteresis prevents adjacent packs from making the bot oscillate.
	if previous ~= nil and now < (tonumber(record.engagement_locked_until) or 0)
		and previous.score >= bestScore - 16 then
		best = previous
		bestScore = previous.score
	end
	if best ~= nil and best.signature ~= record.engagement_pack_signature then
		record.engagement_pack_signature = best.signature
		record.engagement_locked_until = now + 1.35
	end
	return best, packs
end

function XHSBotBrain:GetAllies(hero, radius)
	radius = math.max(0, tonumber(radius) or 0)
	return self:FilterFriendlyQueryUnits(
		hero,
		self:GetFriendlyQueryUnits(hero, radius),
		radius,
		true
	)
end

function XHSBotBrain:GetNearbyFriendlyCover(hero, radius)
	radius = math.max(0, tonumber(radius) or 0)
	return self:FilterFriendlyQueryUnits(
		hero,
		self:GetFriendlyQueryUnits(hero, radius),
		radius,
		false
	)
end

function XHSBotBrain:GetDefensiveStructureCover(hero, radius)
	local buildings = FindUnitsInRadius(
		hero:GetTeamNumber(),
		hero:GetAbsOrigin(),
		nil,
		radius or 950,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_BUILDING,
		DOTA_UNIT_TARGET_FLAG_NONE or 0,
		FIND_CLOSEST,
		false
	)
	for _, building in pairs(buildings or {}) do
		if IsValidEntityHandle(building) and building:IsAlive()
			and DEFENSIVE_STRUCTURE_NAMES[building:GetUnitName()] == true then
			return building, Distance2D(hero:GetAbsOrigin(), building:GetAbsOrigin())
		end
	end

	-- The map's Ancient can be exposed by targetname even on engine builds that
	-- omit forts from a BUILDING radius query.
	local fort = Entities:FindByName(nil, "dota_goodguys_fort")
		or Entities:FindByName(nil, "base_spawn")
	if IsValidEntityHandle(fort) and (fort.IsAlive == nil or fort:IsAlive()) then
		local distance = Distance2D(hero:GetAbsOrigin(), fort:GetAbsOrigin())
		if distance <= (radius or 950) then return fort, distance end
	end
	return nil, nil
end

function XHSBotBrain:GetCampfireState(hero)
	local marker = Entities:FindByName(nil, "xhs_campfire")
	if not IsValidEntityHandle(marker) then
		return {
			position = nil,
			radius = CAMPFIRE_AURA_RADIUS,
			distance = math.huge,
			inside = false,
		}
	end

	local position = marker:GetAbsOrigin()
	local distance = IsValidEntityHandle(hero)
		and Distance2D(hero:GetAbsOrigin(), position)
		or math.huge
	return {
		position = CopyPosition(position),
		radius = CAMPFIRE_AURA_RADIUS,
		distance = distance,
		inside = distance <= math.max(
			100,
			CAMPFIRE_AURA_RADIUS - CAMPFIRE_INNER_BUFFER
		),
	}
end

function XHSBotBrain:ReleaseRuneClaim(playerID, record)
	local runeID = record and tonumber(record.rune_claim_id) or nil
	if runeID ~= nil then
		local claim = self.rune_claims[runeID]
		if claim ~= nil and tonumber(claim.player_id) == tonumber(playerID) then
			self.rune_claims[runeID] = nil
		end
	end
	if record ~= nil then
		record.rune_claim_id = nil
		record.rune_claim_expires_at = nil
		record.rune_committed = false
	end
end

function XHSBotBrain:PruneRuneClaims(now)
	now = tonumber(now) or GameRules:GetGameTime()
	local activeIDs = {}
	for id, active in pairs(Runes and Runes.activeRunes or {}) do
		if active ~= nil then activeIDs[tonumber(active.id) or tonumber(id)] = true end
	end
	for id, claim in pairs(self.rune_claims) do
		if activeIDs[tonumber(id)] ~= true
			or now >= (tonumber(claim.expires_at) or 0) then
			self.rune_claims[id] = nil
		end
	end
end

function XHSBotBrain:FindRuneObjective(hero, record, difficulty, now)
	if not IsValidEntityHandle(hero)
		or Runes == nil
		or type(Runes.activeRunes) ~= "table" then
		self:ReleaseRuneClaim(
			IsValidEntityHandle(hero) and hero:GetPlayerID() or nil,
			record
		)
		return nil
	end

	now = tonumber(now) or GameRules:GetGameTime()
	local playerID = hero:GetPlayerID()
	local maximumDistance = math.min(
		RUNE_MAX_ROUTE_DISTANCE,
		math.max(1000, tonumber(difficulty and difficulty.rune_search_radius)
			or RUNE_MAX_ROUTE_DISTANCE)
	)
	self:PruneRuneClaims(now)

	local function BuildCandidate(active)
		if active == nil then return nil end
		local alreadyPicked = false
		if Runes.HasHeroPickedRuneBatch ~= nil then
			local ok, result = pcall(function()
				return Runes:HasHeroPickedRuneBatch(active, hero)
			end)
			alreadyPicked = not ok or result == true
		end
		if alreadyPicked then return nil end

		local entity = EntityFromIndex(active.entityIndex)
		if not IsValidEntityHandle(entity) or entity.xhs_is_rune ~= true then
			return nil
		end
		local position = active.baseOrigin or entity:GetAbsOrigin()
		local distance = Distance2D(hero:GetAbsOrigin(), position)
		if distance > maximumDistance then return nil end
		return {
			id = active.id,
			batch_id = active.batchId,
			type = active.type or "unknown",
			position = CopyPosition(position),
			distance = distance,
		}
	end

	local best = nil
	local previousRuneID = record and tonumber(record.rune_claim_id) or nil
	if previousRuneID ~= nil then
		local previous = Runes.activeRunes[previousRuneID]
		local previousClaim = self.rune_claims[previousRuneID]
		if previousClaim == nil
			or tonumber(previousClaim.player_id) == tonumber(playerID) then
			best = BuildCandidate(previous)
		end
	end

	for _, active in pairs(Runes.activeRunes) do
		local runeID = tonumber(active and active.id)
		local claim = runeID ~= nil and self.rune_claims[runeID] or nil
		local claimedByOther = claim ~= nil
			and tonumber(claim.player_id) ~= tonumber(playerID)
		if not claimedByOther
			and (best == nil or tonumber(best.id) ~= runeID) then
			local candidate = BuildCandidate(active)
			if candidate ~= nil
				and (best == nil or candidate.distance < best.distance) then
				best = candidate
			end
		end
	end

	if best == nil then
		self:ReleaseRuneClaim(playerID, record)
		return nil
	end

	if previousRuneID ~= nil and previousRuneID ~= tonumber(best.id) then
		local previousClaim = self.rune_claims[previousRuneID]
		if previousClaim ~= nil
			and tonumber(previousClaim.player_id) == tonumber(playerID) then
			self.rune_claims[previousRuneID] = nil
		end
	end
	self.rune_claims[best.id] = {
		player_id = playerID,
		expires_at = now + RUNE_CLAIM_TTL,
	}
	if record ~= nil then
		record.rune_claim_id = best.id
		record.rune_claim_expires_at = now + RUNE_CLAIM_TTL
	end
	return best
end

function XHSBotBrain:IsOwnedScreenUnit(hero, unit)
	if not IsValidEntityHandle(unit) or unit == hero or not unit:IsAlive()
		or unit.IsRealHero ~= nil and unit:IsRealHero() then
		return false
	end
	if unit.furbolg_parent == hero then
		return true
	end
	if unit.GetPlayerOwnerID ~= nil then
		local ok, ownerID = pcall(function() return unit:GetPlayerOwnerID() end)
		if ok and tonumber(ownerID) == tonumber(hero:GetPlayerID()) then return true end
	end
	return false
end

function XHSBotBrain:GetAttackDamageAgainst(enemy, hero)
	if not IsValidEntityHandle(enemy) then return 0 end
	if enemy.GetAverageTrueAttackDamage ~= nil then
		local ok, damage = pcall(function()
			return enemy:GetAverageTrueAttackDamage(hero)
		end)
		if ok and tonumber(damage) ~= nil then return math.max(0, tonumber(damage)) end
	end
	if enemy.GetAttackDamage ~= nil then
		local ok, damage = pcall(function() return enemy:GetAttackDamage() end)
		if ok and tonumber(damage) ~= nil then return math.max(0, tonumber(damage)) end
	end
	return 0
end

function XHSBotBrain:GetSecondsPerAttack(hero)
	if not IsValidEntityHandle(hero) then return 1.7 end
	if hero.GetSecondsPerAttack ~= nil then
		local ok, value = pcall(function() return hero:GetSecondsPerAttack() end)
		if ok and tonumber(value) ~= nil then
			return math.max(0.10, tonumber(value))
		end
	end
	if hero.GetAttacksPerSecond ~= nil then
		local ok, value = pcall(function()
			return hero:GetAttacksPerSecond(false)
		end)
		if ok and tonumber(value) ~= nil and tonumber(value) > 0 then
			return 1 / tonumber(value)
		end
	end
	return 1.7
end

function XHSBotBrain:GetUnitAttacksPerSecond(unit)
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

function XHSBotBrain:GetUnitHealthRegen(unit)
	if not IsValidEntityHandle(unit) or unit.GetHealthRegen == nil then return 0 end
	local ok, value = pcall(function() return unit:GetHealthRegen() end)
	return ok and math.max(0, tonumber(value) or 0) or 0
end

function XHSBotBrain:GetUnitMovementSpeed(unit)
	if not IsValidEntityHandle(unit) then return 300 end
	if unit.GetIdealSpeed ~= nil then
		local ok, value = pcall(function() return unit:GetIdealSpeed() end)
		if ok and tonumber(value) ~= nil then
			return math.max(100, tonumber(value))
		end
	end
	return 300
end

function XHSBotBrain:GetForecastAttackLifesteal(hero, profile)
	if not IsValidEntityHandle(hero) then return 0, 0 end
	local bestPercent = 0
	local bestUptime = 0
	local sustain = profile and profile.intrinsic_sustain or nil
	if type(sustain) == "table" and sustain.attack_lifesteal == true then
		local learned = true
		if type(sustain.ability) == "string"
			and hero.FindAbilityByName ~= nil then
			local ok, ability = pcall(function()
				return hero:FindAbilityByName(sustain.ability)
			end)
			local level = 0
			if ok and IsValidEntityHandle(ability)
				and ability.GetLevel ~= nil then
				local levelOK, value = pcall(function()
					return ability:GetLevel()
				end)
				if levelOK then level = tonumber(value) or 0 end
			end
			learned = level > 0
		end
		if learned then
			bestPercent = math.max(
				bestPercent,
				tonumber(sustain.lifesteal_pct) or 0
			)
			bestUptime = sustain.kind == "active_buff" and 0.30 or 0.72
		end
	end
	if hero.HasItemInInventory ~= nil then
		local ok, hasMask = pcall(function()
			return hero:HasItemInInventory("item_lifesteal_mask")
		end)
		if ok and hasMask then
			bestPercent = math.max(bestPercent, 50)
			bestUptime = math.max(bestUptime, 0.72)
		end
	end
	return bestPercent, bestUptime
end

function XHSBotBrain:GetHeroAttackDPSAgainst(hero, target)
	if not IsValidEntityHandle(hero) then return 0 end
	local damage = 0
	if IsValidEntityHandle(target) then
		damage = self:GetAttackDamageAgainst(hero, target)
	elseif hero.GetAttackDamage ~= nil then
		local ok, value = pcall(function() return hero:GetAttackDamage() end)
		if ok then damage = math.max(0, tonumber(value) or 0) end
	end
	return damage * self:GetUnitAttacksPerSecond(hero)
end

function XHSBotBrain:GetAbilityDamageAgainst(hero, ability, target, rule)
	if not IsValidEntityHandle(hero)
		or not IsValidEntityHandle(ability)
		or not IsValidEntityHandle(target) then
		return 0, 0
	end
	local rawDamage = 0
	if ability.GetAbilityDamage ~= nil then
		local ok, value = pcall(function() return ability:GetAbilityDamage() end)
		if ok then rawDamage = math.max(0, tonumber(value) or 0) end
	end
	if rawDamage <= 0
		and type(rule) == "table"
		and type(rule.damage_key) == "string"
		and ability.GetSpecialValueFor ~= nil then
		local ok, value = pcall(function()
			return ability:GetSpecialValueFor(rule.damage_key)
		end)
		if ok then rawDamage = math.max(0, tonumber(value) or 0) end
	end
	if rawDamage <= 0 then return 0, 0 end

	local amplification = 0
	if hero.GetSpellAmplification ~= nil then
		local ok, value = pcall(function()
			return hero:GetSpellAmplification(false)
		end)
		if ok then amplification = tonumber(value) or 0 end
	end
	if math.abs(amplification) > 2 then amplification = amplification / 100 end
	rawDamage = rawDamage * math.max(0, 1 + amplification)

	local damageType = nil
	if ability.GetAbilityDamageType ~= nil then
		local ok, value = pcall(function() return ability:GetAbilityDamageType() end)
		if ok then damageType = value end
	end
	local multiplier = 1
	if DAMAGE_TYPE_MAGICAL ~= nil and damageType == DAMAGE_TYPE_MAGICAL then
		if target.IsMagicImmune ~= nil and target:IsMagicImmune() then
			return rawDamage, 0
		end
		if target.GetMagicalArmorValue ~= nil then
			local ok, resistance = pcall(function()
				return target:GetMagicalArmorValue()
			end)
			if ok then
				resistance = tonumber(resistance) or 0
				if math.abs(resistance) > 2 then resistance = resistance / 100 end
				multiplier = 1 - Clamp(resistance, -1, 0.95)
			end
		end
	elseif DAMAGE_TYPE_PHYSICAL ~= nil and damageType == DAMAGE_TYPE_PHYSICAL then
		if target.GetPhysicalArmorValue ~= nil then
			local ok, armor = pcall(function()
				return target:GetPhysicalArmorValue(false)
			end)
			if ok then
				armor = tonumber(armor) or 0
				local reduction = 0.06 * armor / (1 + 0.06 * math.abs(armor))
				multiplier = 1 - reduction
			end
		end
	end
	return rawDamage, math.max(0, rawDamage * multiplier)
end

function XHSBotBrain:IsEfficiencyCreepTarget(target)
	if not self:IsCombatTarget(target) or XHSBotConfig:IsBossTarget(target) then
		return false
	end
	if target.IsHero ~= nil then
		local ok, isHero = pcall(function() return target:IsHero() end)
		if ok and isHero then return false end
	end
	return true
end

function XHSBotBrain:EvaluateSingleTargetCreepSpell(
	hero,
	ability,
	target,
	rule
)
	if not self:IsEfficiencyCreepTarget(target) then return nil end
	local rawSpellDamage, spellDamage =
		self:GetAbilityDamageAgainst(hero, ability, target, rule)
	local attackDamage = self:GetAttackDamageAgainst(hero, target)
	if rawSpellDamage <= 0 or spellDamage <= 0 or attackDamage <= 0 then
		-- Many XHS abilities deliver damage through custom Lua and expose no
		-- standard damage value. A certified control/channel spell must not
		-- become unusable solely because that estimate is unavailable.
		local health = math.max(1, tonumber(target:GetHealth()) or 1)
		local modelFallback = rule ~= nil
			and (rule.control == true
				or rule.allow_creep_cast_without_damage_model == true)
			and attackDamage > 0
			and health > attackDamage * 1.10
		return {
			worthwhile = modelFallback,
			fallback_cast = modelFallback,
			reason = modelFallback and "certified spell on durable creep"
				or "damage model unavailable",
			spell_damage = 0,
			attack_damage = attackDamage,
			cast_lock = 0,
			time_saved = 0,
			efficiency = modelFallback and 1.15 or 0,
		}
	end

	local health = math.max(1, tonumber(target:GetHealth()) or 1)
	local attackInterval = self:GetSecondsPerAttack(hero)
	local castPoint = 0
	if ability.GetCastPoint ~= nil then
		local ok, value = pcall(function() return ability:GetCastPoint() end)
		if ok then castPoint = math.max(0, tonumber(value) or 0) end
	end
	local channelTime = 0
	if ability.GetChannelTime ~= nil then
		local ok, value = pcall(function() return ability:GetChannelTime() end)
		if ok then channelTime = math.max(0, tonumber(value) or 0) end
	end
	local castLock = math.max(0.15, castPoint + channelTime + 0.05)
	local attackDPS = attackDamage / attackInterval
	local effectiveSpellDamage = math.min(health, spellDamage)
	local spellDPS = effectiveSpellDamage / castLock
	local attacksWithout = math.ceil(health / attackDamage)
	local healthAfterSpell = math.max(0, health - spellDamage)
	local attacksAfter = math.ceil(healthAfterSpell / attackDamage)
	local timeWithoutSpell = attacksWithout * attackInterval
	local timeWithSpell = castLock + attacksAfter * attackInterval
	local timeSaved = timeWithoutSpell - timeWithSpell
	local efficiency = effectiveSpellDamage / math.max(
		1,
		math.min(health, attackDamage)
	)

	local manaCost = 0
	if ability.GetManaCost ~= nil then
		local ok, value = pcall(function()
			return ability:GetManaCost(math.max(0, ability:GetLevel() - 1))
		end)
		if ok then manaCost = math.max(0, tonumber(value) or 0) end
	end
	local maximumMana = math.max(1, tonumber(hero:GetMaxMana()) or 1)
	local manaFraction = manaCost / maximumMana
	local cooldown = 0
	if ability.GetCooldown ~= nil then
		local ok, value = pcall(function()
			return ability:GetCooldown(math.max(0, ability:GetLevel() - 1))
		end)
		if ok then cooldown = math.max(0, tonumber(value) or 0) end
	end
	local requiredEfficiency =
		tonumber(rule and rule.minimum_creep_spell_efficiency) or 1.12
	requiredEfficiency = requiredEfficiency
		+ math.min(0.45, manaFraction * 0.90)
		+ math.min(0.35, cooldown / 60)
	local minimumTimeSaved =
		tonumber(rule and rule.minimum_creep_spell_time_saved) or 0.15
	local worthwhile = health > attackDamage * 1.05
		and efficiency >= requiredEfficiency
		and spellDPS > attackDPS * 1.05
		and timeSaved >= minimumTimeSaved

	return {
		worthwhile = worthwhile,
		raw_spell_damage = rawSpellDamage,
		spell_damage = spellDamage,
		attack_damage = attackDamage,
		attack_dps = attackDPS,
		spell_dps = spellDPS,
		cast_lock = castLock,
		time_saved = timeSaved,
		efficiency = efficiency,
		required_efficiency = requiredEfficiency,
		mana_cost = manaCost,
	}
end

function XHSBotBrain:GetMobileSafeZoneScore(hero, ally, target)
	if not IsValidEntityHandle(hero)
		or not IsValidEntityHandle(ally)
		or ally == hero
		or not ally:IsAlive()
		or ally.IsRealHero == nil
		or not ally:IsRealHero() then
		return nil
	end

	local allyHealthRatio = HealthRatio(ally)
	if allyHealthRatio < 0.50 then return nil end

	local attackTarget = nil
	if ally.GetAttackTarget ~= nil then
		local ok, value = pcall(function() return ally:GetAttackTarget() end)
		if ok and IsValidEntityHandle(value) then attackTarget = value end
	end
	local attackRange = 150
	if ally.Script_GetAttackRange ~= nil then
		local ok, value = pcall(function() return ally:Script_GetAttackRange() end)
		if ok then attackRange = math.max(150, tonumber(value) or 150) end
	end
	local engaged = attackTarget ~= nil
		or self:IsCombatTarget(target)
			and Distance2D(ally:GetAbsOrigin(), target:GetAbsOrigin())
				<= attackRange + 325
	if not engaged then return nil end

	local heroDamage = math.max(1, self:GetAttackDamageAgainst(hero, target))
	local allyDamage = math.max(1, self:GetAttackDamageAgainst(ally, target))
	local healthPoolRatio = ally:GetMaxHealth() / math.max(1, hero:GetMaxHealth())
	local damageRatio = allyDamage / heroDamage
	local levelDelta = 0
	if ally.GetLevel ~= nil and hero.GetLevel ~= nil then
		levelDelta = (tonumber(ally:GetLevel()) or 1)
			- (tonumber(hero:GetLevel()) or 1)
	end
	local healthRegen = 0
	if ally.GetHealthRegen ~= nil then
		local ok, value = pcall(function() return ally:GetHealthRegen() end)
		if ok then healthRegen = math.max(0, tonumber(value) or 0) end
	end
	local sustain = allyHealthRatio
		+ math.min(0.35, healthRegen * 10 / math.max(1, ally:GetMaxHealth()))
	local strength = healthPoolRatio * 0.45
		+ damageRatio * 0.35
		+ Clamp(levelDelta / 10, -0.15, 0.35)
		+ sustain * 0.20
	if sustain < 0.62 or strength < 1.05 then return nil end
	return strength, sustain
end

function XHSBotBrain:GetMobileSafeZone(hero, target, radius)
	if not self:IsCombatTarget(target) then return nil, nil, nil end
	local best = nil
	for _, ally in pairs(self:GetAllies(hero, radius or 1150)) do
		local strength, sustain = self:GetMobileSafeZoneScore(hero, ally, target)
		if strength ~= nil then
			local distance = Distance2D(hero:GetAbsOrigin(), ally:GetAbsOrigin())
			local score = strength * 100 + sustain * 35 - distance * 0.08
			if best == nil or score > best.score then
				best = {
					ally = ally,
					strength = strength,
					sustain = sustain,
					distance = distance,
					score = score,
				}
			end
		end
	end
	if best == nil then return nil, nil, nil end
	return best.ally, best.strength, best.distance
end

function XHSBotBrain:GetStrategicThreatPosition(hero, target, assignment)
	local heroOrigin = IsValidEntityHandle(hero) and hero:GetAbsOrigin() or nil
	local groups = {}
	local activeSpecialUnits = CustomTimers ~= nil
		and CustomTimers.active_special_wave_units or {}
	for entindex, wave in pairs(activeSpecialUnits) do
		local unit = EntityFromIndex(tonumber(entindex))
		if IsValidEntityHandle(unit)
			and unit:IsAlive()
			and heroOrigin ~= nil
			and Distance2D(heroOrigin, unit:GetAbsOrigin())
				<= STRATEGIC_SPECIAL_WAVE_RADIUS then
			local key = wave ~= nil and tostring(wave) or tostring(entindex)
			local group = groups[key] or {
				position = Vector(0, 0, 0),
				count = 0,
			}
			group.position = group.position + unit:GetAbsOrigin()
			group.count = group.count + 1
			groups[key] = group
		end
	end

	local bestPosition = nil
	local bestDistance = math.huge
	for _, group in pairs(groups) do
		if group.count > 0 then
			local position = group.position / group.count
			local distance = Distance2D(heroOrigin, position)
			if distance < bestDistance then
				bestPosition = position
				bestDistance = distance
			end
		end
	end
	if bestPosition ~= nil then
		return CopyPosition(bestPosition), "active special wave"
	end
	if assignment ~= nil and assignment.threat_position ~= nil then
		return CopyPosition(assignment.threat_position), "team assignment"
	end
	if self:IsCombatTarget(target) then
		return CopyPosition(target:GetAbsOrigin()), "combat target"
	end
	return nil, nil
end

function XHSBotBrain:GetCoverFormationDistance(hero, profile)
	profile = profile or {}
	local primaryRole = tostring(profile.primary_role or profile.role or "")
	local secondaryRole = tostring(profile.secondary_role or "")
	local preferredRange = tonumber(profile.preferred_range) or 0
	local attackRange = 0
	if IsValidEntityHandle(hero) and hero.Script_GetAttackRange ~= nil then
		local ok, value = pcall(function() return hero:Script_GetAttackRange() end)
		if ok then attackRange = tonumber(value) or 0 end
	end
	local ranged = primaryRole == "ranged_dps"
		or secondaryRole == "ranged_dps"
		or preferredRange >= 450
		or attackRange >= 450
	return ranged and 650 or 250
end

function XHSBotBrain:ComputeCombatThreat(
	hero,
	enemies,
	record,
	profile,
	difficulty,
	target
)
	local now = GameRules:GetGameTime()
	local maximumHealth = math.max(1, hero:GetMaxHealth())
	local currentHealth = hero:GetHealth()
	local sampleHealth = tonumber(record.threat_sample_health) or currentHealth
	local sampleTime = tonumber(record.threat_sample_at) or now
	local elapsed = math.max(0.05, now - sampleTime)
	local recentDamageRatio = math.max(0, sampleHealth - currentHealth) / maximumHealth
	local recentDamageRate = recentDamageRatio / elapsed
	record.threat_sample_health = currentHealth
	record.threat_sample_at = now

	local pressure = 0
	local closeEnemies = 0
	local focusedBy = 0
	local bossNearby = false
	local forecastEnemies = {}
	for _, enemy in pairs(enemies or {}) do
		if self:IsCombatTarget(enemy) then
			local distance = Distance2D(hero:GetAbsOrigin(), enemy:GetAbsOrigin())
			local proximity = distance <= 325 and 1
				or distance <= 700 and 0.65
				or distance <= 1200 and 0.30
				or 0.10
			if distance <= 700 then closeEnemies = closeEnemies + 1 end
			local attackDamageRatio = self:GetAttackDamageAgainst(enemy, hero) / maximumHealth
			pressure = pressure + 0.055 * proximity
				+ math.min(0.22, attackDamageRatio * 1.65) * proximity
			if XHSBotConfig:IsBossTarget(enemy) then
				bossNearby = true
				pressure = pressure + 0.32 * proximity
			end
			if enemy.GetAttackTarget ~= nil then
				local ok, attackTarget = pcall(function() return enemy:GetAttackTarget() end)
				if ok and attackTarget == hero then
					focusedBy = focusedBy + 1
					pressure = pressure + 0.14
				end
			end
			local attackRange = 150
			if enemy.Script_GetAttackRange ~= nil then
				local ok, value = pcall(function()
					return enemy:Script_GetAttackRange()
				end)
				if ok then attackRange = math.max(0, tonumber(value) or attackRange) end
			end
			local focused = false
			if enemy.GetAttackTarget ~= nil then
				local ok, attackTarget = pcall(function()
					return enemy:GetAttackTarget()
				end)
				focused = ok and attackTarget == hero
			end
			local reachFactor = focused and 1
				or distance <= attackRange + 175 and 0.82
				or distance <= attackRange + 550 and 0.38
				or 0.08
			local isHero = false
			if enemy.IsHero ~= nil then
				local ok, value = pcall(function() return enemy:IsHero() end)
				isHero = ok and value == true
			end
			table.insert(forecastEnemies, {
				projected_dps = self:GetAttackDamageAgainst(enemy, hero)
					* self:GetUnitAttacksPerSecond(enemy),
				reach_factor = reachFactor,
				focused = focused,
				disable_risk = XHSBotConfig:IsBossTarget(enemy) and 0.34
					or isHero and 0.18 or 0.03,
			})
		end
	end

	local alliedHeroes = 0
	local ownedScreens = 0
	for _, ally in pairs(self:GetNearbyFriendlyCover(hero, 850)) do
		if IsValidEntityHandle(ally) and ally ~= hero and ally:IsAlive() then
			if ally.IsRealHero ~= nil and ally:IsRealHero() then
				alliedHeroes = alliedHeroes + 1
			elseif self:IsOwnedScreenUnit(hero, ally) then
				ownedScreens = ownedScreens + 1
			end
		end
	end
	local supportReduction = math.min(0.22, alliedHeroes * 0.055 + ownedScreens * 0.028)
	local isolation = closeEnemies >= 2 and alliedHeroes == 0 and ownedScreens == 0
		and 0.12 or 0
	local legacyThreat = Clamp(
		pressure
			+ math.min(0.55, recentDamageRate * 2.4)
			+ isolation
			- supportReduction,
		0,
		1.5
	)
	local lifestealPercent, lifestealUptime =
		self:GetForecastAttackLifesteal(hero, profile)
	local reactionTime = difficulty ~= nil and (
		(tonumber(difficulty.reaction_min) or 0)
			+ (tonumber(difficulty.reaction_max) or 0)
	) / 2 or 0.45
	local forecast = XHSBotWorldModel:EstimateSurvival({
		maximum_health = maximumHealth,
		current_health = currentHealth,
		recent_damage_rate = recentDamageRate,
		enemies = forecastEnemies,
		health_regen = self:GetUnitHealthRegen(hero),
		attack_dps = self:GetHeroAttackDPSAgainst(hero, target),
		attack_lifesteal_pct = lifestealPercent,
		combat_uptime = self:IsCombatTarget(target)
			and lifestealUptime or math.min(0.18, lifestealUptime),
		cover_reduction = supportReduction,
		reaction_time = reactionTime,
		movement_speed = self:GetUnitMovementSpeed(hero),
		escape_distance = focusedBy >= 2 and 800 or 600,
		safety_margin = 0.45,
	})
	-- Preserve the proven pressure heuristic as the floor. The forecast may
	-- raise it only by a bounded amount while runtime telemetry is accumulated.
	local threat = Clamp(
		math.max(
			legacyThreat,
			math.min(legacyThreat + 0.22, forecast.pressure_score)
		),
		0,
		1.5
	)
	record.combat_threat = threat
	record.recent_damage_ratio = recentDamageRatio
	record.close_enemy_count = closeEnemies
	record.focused_by_count = focusedBy
	record.nearby_screen_count = ownedScreens
	record.boss_threat_nearby = bossNearby
	record.survival_incoming_dps = math.floor(forecast.incoming_dps)
	record.survival_net_incoming_dps = math.floor(forecast.net_incoming_dps)
	record.survival_sustain_per_second =
		math.floor(forecast.sustain_per_second)
	record.survival_time_to_die =
		math.floor(forecast.time_to_die * 10) / 10
	record.survival_escape_time =
		math.floor(forecast.escape_time * 10) / 10
	record.survival_control_risk =
		math.floor(forecast.control_risk * 100) / 100
	record.survival_forecast_confidence =
		math.floor(forecast.confidence * 100) / 100
	record.survival_fatal_before_escape =
		forecast.fatal_before_escape == true
	return {
		score = threat,
		recent_damage_ratio = recentDamageRatio,
		recent_damage_rate = recentDamageRate,
		close_enemies = closeEnemies,
		focused_by = focusedBy,
		allied_heroes = alliedHeroes,
		owned_screens = ownedScreens,
		boss_nearby = bossNearby,
		incoming_dps = forecast.incoming_dps,
		net_incoming_dps = forecast.net_incoming_dps,
		sustain_per_second = forecast.sustain_per_second,
		time_to_die = forecast.time_to_die,
		escape_time = forecast.escape_time,
		health_at_escape_ratio = forecast.health_at_escape_ratio,
		fatal_before_escape = forecast.fatal_before_escape,
		control_risk = forecast.control_risk,
		forecast_confidence = forecast.confidence,
	}
end

function XHSBotBrain:GetRetreatPosition(
	hero,
	target,
	assignment,
	threat,
	mobileSafeZone,
	profile,
	strategicThreatPosition
)
	local heroOrigin = hero:GetAbsOrigin()
	local fortPosition = GetFortPosition()
	if Distance2D(heroOrigin, fortPosition) <= ANCIENT_RETREAT_LIMIT_RADIUS then
		return CopyPosition(fortPosition), "Ancient retreat limit"
	end
	if self:IsCombatTarget(target) then
		local bestUnit = nil
		local bestScore = -math.huge
		for _, ally in pairs(self:GetNearbyFriendlyCover(hero, 1050)) do
			if IsValidEntityHandle(ally) and ally ~= hero and ally:IsAlive() then
				local isScreen = self:IsOwnedScreenUnit(hero, ally)
				local isMobileSafeZone = ally == mobileSafeZone
				if isScreen or isMobileSafeZone then
					local score = (isScreen and 250 or 285)
						- Distance2D(heroOrigin, ally:GetAbsOrigin()) * 0.12
					if score > bestScore then
						bestScore = score
						bestUnit = ally
					end
				end
			end
		end
		if bestUnit ~= nil then
			local pressurePosition = strategicThreatPosition
				or select(1, self:GetStrategicThreatPosition(
					hero,
					target,
					assignment
				))
				or target:GetAbsOrigin()
			local away = bestUnit:GetAbsOrigin() - pressurePosition
			away.z = 0
			if away:Length2D() > 1 then
				local behindCover = bestUnit:GetAbsOrigin()
					+ away:Normalized()
						* self:GetCoverFormationDistance(hero, profile)
				if GridNav == nil or GridNav.CanFindPath == nil
					or GridNav:CanFindPath(heroOrigin, behindCover) then
					return behindCover, self:IsOwnedScreenUnit(hero, bestUnit)
						and "owned summon screen"
						or "threat-opposite strong ally safe zone"
				end
			end
		end
	end

	local assignmentGoal = assignment and assignment.goal or "regroup"
	if assignmentGoal == "participate_event"
		and assignment ~= nil and assignment.anchor ~= nil then
		return CopyPosition(assignment.anchor), "event anchor"
	end
	return PositionToward(
		heroOrigin,
		fortPosition,
		threat.score >= 0.85 and 800 or 575
	), "step toward base"
end

function XHSBotBrain:GetControlledUnits(hero, radius)
	local controlled = {}
	for _, unit in pairs(self:GetNearbyFriendlyCover(hero, radius)) do
		if self:IsOwnedScreenUnit(hero, unit) then table.insert(controlled, unit) end
	end
	table.sort(controlled, function(left, right) return left:entindex() < right:entindex() end)
	return controlled
end

function XHSBotBrain:ThinkControlledUnits(hero, record, assignment, encounter)
	local now = GameRules:GetGameTime()
	if now < (record.next_controlled_unit_order_at or 0) then return end
	local units = self:GetControlledUnits(hero, 2400)
	record.controlled_unit_count = #units
	if #units <= 0 then return end

	record.controlled_unit_cursor = (tonumber(record.controlled_unit_cursor) or 0) % #units + 1
	local unit = units[record.controlled_unit_cursor]
	local target = encounter and encounter.forced_target
		or EntityFromIndex(record.target_entindex)
	if target ~= nil and not self:IsCombatTarget(target) then
		target = nil
	end
	local order = {
		UnitIndex = unit:entindex(),
		Queue = false,
	}
	if encounter ~= nil and encounter.no_combat == true and encounter.anchor ~= nil then
		order.OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION
		order.Position = encounter.anchor
		record.last_controlled_unit_order = "muradin_escape"
	elseif self:IsCombatTarget(target) and self:IsTeamVisible(hero, target) then
		order.OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET
		order.TargetIndex = target:entindex()
		record.last_controlled_unit_order = "screen:" .. target:GetUnitName()
	elseif encounter ~= nil and encounter.anchor ~= nil then
		order.OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE
		order.Position = encounter.anchor
		record.last_controlled_unit_order = "advance_to_encounter"
	elseif assignment ~= nil and assignment.anchor ~= nil then
		order.OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE
		order.Position = assignment.anchor
		record.last_controlled_unit_order = "advance_to_assignment"
	else
		return
	end
	ExecuteOrderFromTable(order)
	record.controlled_unit_orders = (record.controlled_unit_orders or 0) + 1
	record.next_controlled_unit_order_at = now + 0.42
end

function XHSBotBrain:GetLowestHealthAlly(hero, radius)
	local lowest = hero
	local lowestRatio = HealthRatio(hero)
	for _, ally in pairs(self:GetAllies(hero, radius)) do
		if IsValidEntityHandle(ally) and ally:IsAlive() then
			local ratio = HealthRatio(ally)
			if ratio < lowestRatio then
				lowest = ally
				lowestRatio = ratio
			end
		end
	end
	return lowest, lowestRatio
end

function XHSBotBrain:GetAbilitySpecialValue(ability, key)
	if ability == nil or key == nil or key == "" or ability.GetSpecialValueFor == nil then
		return 0
	end
	local ok, value = pcall(function()
		return ability:GetSpecialValueFor(key)
	end)
	if not ok then return 0 end
	return math.max(0, tonumber(value) or 0)
end

function XHSBotBrain:EstimateAbilityHeal(ability, rule, recipient)
	if not IsValidEntityHandle(recipient) then return 0, 0, 0, 0 end
	local flat = self:GetAbilitySpecialValue(ability, rule.heal_flat_key)
	local percent = self:GetAbilitySpecialValue(ability, rule.heal_percent_key)
	local maximumHealth = math.max(1, recipient:GetMaxHealth())
	local missingHealth = math.max(0, maximumHealth - recipient:GetHealth())
	local estimated = flat + maximumHealth * percent / 100
	local effective = math.min(missingHealth, estimated)
	local effectiveRatio = effective / maximumHealth
	local usefulFraction = estimated > 0 and effective / estimated or 0
	return estimated, effective, effectiveRatio, usefulFraction
end

function XHSBotBrain:GetAllyRole(ally)
	if not IsValidEntityHandle(ally)
		or XHSBotHeroProfiles == nil
		or XHSBotHeroProfiles.Get == nil then
		return nil
	end
	local profile = XHSBotHeroProfiles:Get(ally:GetUnitName())
	return profile and profile.role or nil
end

function XHSBotBrain:IsPreferredAllyRole(rule, role)
	if role == nil then return false end
	for _, preferredRole in ipairs(rule.prefer_roles or {}) do
		if preferredRole == role then return true end
	end
	return false
end

function XHSBotBrain:GetAllyCombatContext(caster, ally, enemies, target)
	local context = {
		close_enemies = 0,
		focused_by = 0,
		boss_nearby = false,
		engaged = false,
	}
	if not IsValidEntityHandle(ally) then return context end
	local allyOrigin = ally:GetAbsOrigin()
	for _, enemy in pairs(enemies or {}) do
		if self:IsCombatTarget(enemy) then
			local distance = Distance2D(enemy:GetAbsOrigin(), allyOrigin)
			if distance <= 700 then
				context.close_enemies = context.close_enemies + 1
				context.engaged = true
			end
			if distance <= 950 and XHSBotConfig:IsBossTarget(enemy) then
				context.boss_nearby = true
				context.engaged = true
			end
			if enemy.GetAttackTarget ~= nil then
				local ok, attackTarget = pcall(function() return enemy:GetAttackTarget() end)
				if ok and attackTarget == ally then
					context.focused_by = context.focused_by + 1
					context.engaged = true
				end
			end
		end
	end
	if self:IsCombatTarget(target)
		and Distance2D(target:GetAbsOrigin(), allyOrigin) <= 850 then
		context.engaged = true
	end
	if ally.GetAttackTarget ~= nil then
		local ok, attackTarget = pcall(function() return ally:GetAttackTarget() end)
		if ok and self:IsCombatTarget(attackTarget) then context.engaged = true end
	end
	return context
end

function XHSBotBrain:ScoreAllyAbilityTarget(caster, ally, rule, enemies, target)
	if not IsValidEntityHandle(ally) or not ally:IsAlive() then return nil end
	if rule.include_self == false and ally == caster then return nil end
	if rule.active_modifier ~= nil
		and ally.HasModifier ~= nil
		and ally:HasModifier(rule.active_modifier) then
		return nil
	end

	local ratio = HealthRatio(ally)
	local missingHealth = 1 - ratio
	local context = self:GetAllyCombatContext(caster, ally, enemies, target)
	local intent = rule.intent or (rule.mode == "ally_heal" and "heal" or "defense")
	local score = 0
	if intent == "heal" then
		score = missingHealth * 100
			+ context.focused_by * 18
			+ context.close_enemies * 4
		local selfSaveThreshold = tonumber(rule.self_save_threshold) or 0.40
		-- A targeted heal may save another hero in ordinary play, but a caster
		-- in fatal danger must not ignore itself. AoE/bouncing heals marked as
		-- heals_caster do not need this bias because they save both units.
		if ally == caster
			and rule.heals_caster ~= true
			and ratio <= selfSaveThreshold then
			score = score + 55
				+ (selfSaveThreshold - ratio) * 120
				+ context.focused_by * 10
		end
	elseif intent == "offense" then
		score = context.close_enemies * 8
			+ context.focused_by * 5
			+ (context.boss_nearby and 20 or 0)
			+ (context.engaged and 18 or 0)
		if ratio < 0.25 then score = score - 22 end
	else
		score = missingHealth * 58
			+ context.focused_by * 20
			+ context.close_enemies * 7
			+ (context.boss_nearby and 18 or 0)
	end

	local role = self:GetAllyRole(ally)
	if self:IsPreferredAllyRole(rule, role) then score = score + 16 end
	if ally == caster and rule.prefer_self == true then score = score + 4 end
	return score, ratio, context, role
end

function XHSBotBrain:FindBestAllyAbilityTarget(caster, radius, rule, enemies, target)
	local best = nil
	local bestScore = -math.huge
	local bestRatio = 1
	local bestContext = nil
	local bestRole = nil
	for _, ally in pairs(self:GetAllies(caster, radius)) do
		local score, ratio, context, role =
			self:ScoreAllyAbilityTarget(caster, ally, rule, enemies, target)
		if score ~= nil and score > bestScore then
			best = ally
			bestScore = score
			bestRatio = tonumber(ratio) or 1
			bestContext = context
			bestRole = role
		end
	end
	return best, bestScore, bestRatio, bestContext, bestRole
end

function XHSBotBrain:GetAbilityRange(hero, ability, target)
	local ok, castRange = pcall(function()
		return ability:GetCastRange(hero:GetAbsOrigin(), target)
	end)
	if not ok or castRange == nil or castRange <= 0 then
		castRange = 650
	end
	return castRange + 75
end

function XHSBotBrain:CountEnemiesAround(enemies, position, radius)
	local count = 0
	for _, enemy in pairs(enemies) do
		if self:IsCombatTarget(enemy) and Distance2D(enemy:GetAbsOrigin(), position) <= radius then
			count = count + 1
		end
	end
	return count
end

function XHSBotBrain:CanAbilityAffectEnemy(ability, enemy, rule)
	if not IsValidEntityHandle(ability) or not self:IsCombatTarget(enemy) then
		return false
	end
	local magicImmune = false
	if enemy.IsMagicImmune ~= nil then
		local ok, value = pcall(function() return enemy:IsMagicImmune() end)
		magicImmune = ok and value == true
	end
	if not magicImmune then return true end
	if rule ~= nil and rule.affects_magic_immune == true then return true end

	-- Target flags are the engine/KV contract for spells which deliberately
	-- pierce immunity. Without that explicit contract, treating an immune unit
	-- as an AoE target only spends mana and cooldown for no useful effect.
	if ability.GetAbilityTargetFlags ~= nil
		and bit ~= nil
		and bit.band ~= nil
		and DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES ~= nil then
		local ok, flags = pcall(function() return ability:GetAbilityTargetFlags() end)
		if ok and bit.band(
				tonumber(flags) or 0,
				DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
			) ~= 0 then
			return true
		end
	end
	if ability.GetAbilityKeyValues ~= nil then
		local ok, keyValues = pcall(function() return ability:GetAbilityKeyValues() end)
		if ok and type(keyValues) == "table" then
			local immunityType = tostring(keyValues.SpellImmunityType or "")
			local targetFlags = tostring(keyValues.AbilityUnitTargetFlags or "")
			if string.find(immunityType, "SPELL_IMMUNITY_ENEMIES_YES", 1, true)
				or string.find(
					targetFlags,
					"DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES",
					1,
					true
				) then
				return true
			end
		end
	end
	return false
end

function XHSBotBrain:CountAbilityTargetsAround(
	ability,
	rule,
	enemies,
	position,
	radius
)
	local count = 0
	for _, enemy in pairs(enemies or {}) do
		if self:CanAbilityAffectEnemy(ability, enemy, rule)
			and Distance2D(enemy:GetAbsOrigin(), position) <= radius then
			count = count + 1
		end
	end
	return count
end

function XHSBotBrain:RecordAbilityRejection(record, abilityName, reason)
	if type(record) ~= "table" then return end
	local now = GameRules:GetGameTime()
	local signature = tostring(abilityName or "unknown") .. ":" .. tostring(reason or "rejected")
	record.ability_rejection_after = record.ability_rejection_after or {}
	if now < (record.ability_rejection_after[signature] or 0) then return end
	record.ability_rejection_after[signature] = now + 0.85
	record.casts_rejected = (record.casts_rejected or 0) + 1
	record.last_ability_reason = signature
end

function XHSBotBrain:CanConsiderAbility(record, abilityName, difficulty)
	local now = GameRules:GetGameTime()
	record.ability_consider_after = record.ability_consider_after or {}
	if now < (record.ability_consider_after[abilityName] or 0) then return false end

	local roll = RandomFloat(0, 1)
	if roll > difficulty.ability_use_chance then
		record.ability_consider_after[abilityName] = now + RandomFloat(0.6, 1.4)
		record.last_ability_reason = abilityName .. ": humanized skip"
		record.humanized_cast_skips = (record.humanized_cast_skips or 0) + 1
		return false
	end
	return true
end

function XHSBotBrain:IsEtherealSpellTarget(unit)
	if not self:IsCombatTarget(unit) then return false end
	if unit.HasModifier ~= nil then
		local modifiers = {
			"modifier_astral_core_ethereal",
			"modifier_item_ethereal_blade_ethereal",
			"modifier_ghost_state",
			"modifier_pugna_decrepify",
		}
		for _, modifierName in ipairs(modifiers) do
			local ok, hasModifier = pcall(function()
				return unit:HasModifier(modifierName)
			end)
			if ok and hasModifier then return true end
		end
	end
	if unit.IsAttackImmune ~= nil then
		local ok, attackImmune = pcall(function() return unit:IsAttackImmune() end)
		if ok and attackImmune then return true end
	end
	return false
end

function XHSBotBrain:CanAbilityAffectEthereal(ability)
	if not IsValidEntityHandle(ability) or ability.GetAbilityDamageType == nil then
		return true
	end
	local ok, damageType = pcall(function()
		return ability:GetAbilityDamageType()
	end)
	if not ok then return true end
	return DAMAGE_TYPE_PHYSICAL == nil or damageType ~= DAMAGE_TYPE_PHYSICAL
end

function XHSBotBrain:FindEtherealSpellTarget(
	hero,
	ability,
	enemies,
	maximumRange,
	useTargetFilter,
	rule
)
	if not self:CanAbilityAffectEthereal(ability) then return nil end
	local heroOrigin = hero:GetAbsOrigin()
	local best = nil
	local bestScore = -math.huge
	for _, enemy in pairs(enemies or {}) do
		if self:IsEtherealSpellTarget(enemy)
			and self:CanAbilityAffectEnemy(ability, enemy, rule) then
			local distance = Distance2D(heroOrigin, enemy:GetAbsOrigin())
			if maximumRange == nil or distance <= maximumRange then
				local accepted = true
				if useTargetFilter == true
					and ability.CastFilterResultTarget ~= nil then
					local ok, result = pcall(function()
						return ability:CastFilterResultTarget(enemy)
					end)
					accepted = ok and (result == nil or result == (UF_SUCCESS or 0))
				end
				if accepted then
					local score = 10000 - distance
						+ (XHSBotConfig:IsBossTarget(enemy) and 2500 or 0)
						+ math.min(1500, tonumber(enemy:GetHealth()) or 0) * 0.10
					if score > bestScore then
						best = enemy
						bestScore = score
					end
				end
			end
		end
	end
	return best
end

function XHSBotBrain:PassesCastFilter(ability, action)
	if ability == nil or type(action) ~= "table" then
		return false, "invalid cast filter input"
	end

	local mode = action.mode
	local filter = nil
	if mode == "enemy_unit" or mode == "ally_heal" or mode == "ally_buff" then
		if action.target == nil or ability.CastFilterResultTarget == nil then
			return action.target ~= nil, action.target ~= nil and nil or "missing cast target"
		end
		filter = function()
			return ability:CastFilterResultTarget(action.target)
		end
	elseif mode == "point_aoe" or mode == "directional_point" then
		if action.position == nil or ability.CastFilterResultLocation == nil then
			return action.position ~= nil, action.position ~= nil and nil or "missing cast position"
		end
		filter = function()
			return ability:CastFilterResultLocation(action.position)
		end
	elseif mode ~= "toggle_single"
		and mode ~= "toggle_aoe"
		and mode ~= "defensive_toggle"
		and mode ~= "rifle_attack_mode"
		and mode ~= "autocast_attack"
		and ability.CastFilterResult ~= nil then
		filter = function()
			return ability:CastFilterResult()
		end
	end

	if filter == nil then return true end
	local ok, result = pcall(filter)
	if not ok then return false, "cast filter error" end
	local successCode = UF_SUCCESS or 0
	if result ~= nil and result ~= successCode then
		return false, "cast filter rejected"
	end
	return true
end

function XHSBotBrain:BuildAbilityAction(hero, ability, rule, target, enemies, difficulty, record)
	if ability == nil or ability:IsNull() then
		if rule.optional ~= true then
			self:RecordAbilityRejection(record, rule.ability_name, "missing ability")
		end
		return nil
	end

	local name = ability:GetAbilityName()
	if ability:GetLevel() <= 0 then
		self:RecordAbilityRejection(record, name, "ability not learned")
		return nil
	end
	if ability:IsPassive() or not ability:IsActivated() then
		self:RecordAbilityRejection(record, name, "passive or deactivated")
		return nil
	end
	local isToggleMode = rule.mode == "toggle_single"
		or rule.mode == "toggle_aoe"
		or rule.mode == "defensive_toggle"
		or rule.mode == "autocast_attack"
	local currentToggleState = false
	if rule.mode == "autocast_attack" and ability.GetAutoCastState ~= nil then
		currentToggleState = ability:GetAutoCastState()
	elseif isToggleMode and ability.GetToggleState ~= nil then
		currentToggleState = ability:GetToggleState()
	end
	if not ability:IsFullyCastable()
		and not (isToggleMode and currentToggleState) then
		self:RecordAbilityRejection(record, name, "cooldown or mana")
		return nil
	end
	local etherealPriority = false
	if rule.mode == "enemy_unit"
		or rule.mode == "point_aoe"
		or rule.mode == "directional_point" then
		local range = rule.mode == "directional_point"
			and tonumber(rule.travel_range)
			or self:GetAbilityRange(hero, ability, target)
		local etherealTarget = self:FindEtherealSpellTarget(
			hero,
			ability,
			enemies,
			range,
			rule.mode == "enemy_unit",
			rule
		)
		if etherealTarget ~= nil then
			target = etherealTarget
			etherealPriority = true
		end
	elseif rule.mode == "no_target_enemy" or rule.mode == "no_target_mixed" then
		etherealPriority = self:FindEtherealSpellTarget(
			hero,
			ability,
			enemies,
			tonumber(rule.radius) or 550,
			false,
			rule
		) ~= nil
	end
	if rule.mode == "enemy_unit"
		and self:IsCombatTarget(target)
		and not self:CanAbilityAffectEnemy(ability, target, rule) then
		self:RecordAbilityRejection(record, name, "target is magic immune")
		return nil
	end
	local unitTargetAreaCount = 0
	local unitTargetAreaOpportunity = false
	if rule.mode == "enemy_unit"
		and rule.aoe_unit_target == true
		and self:IsCombatTarget(target) then
		unitTargetAreaCount = self:CountAbilityTargetsAround(
			ability,
			rule,
			enemies,
			target:GetAbsOrigin(),
			tonumber(rule.radius) or 500
		)
		unitTargetAreaOpportunity = unitTargetAreaCount
			>= (tonumber(rule.minimum_targets) or 2)
	end
	local creepSpellEfficiency = nil
	if not etherealPriority
		and rule.mode == "enemy_unit"
		and self:IsEfficiencyCreepTarget(target)
		and not unitTargetAreaOpportunity then
		creepSpellEfficiency = self:EvaluateSingleTargetCreepSpell(
			hero,
			ability,
			target,
			rule
		)
		record.single_spell_efficiency = creepSpellEfficiency ~= nil
			and tonumber(creepSpellEfficiency.efficiency) or 0
		record.single_spell_time_saved = creepSpellEfficiency ~= nil
			and tonumber(creepSpellEfficiency.time_saved) or 0
		record.single_spell_target = IsValidEntityHandle(target)
			and target:entindex() or nil
		if creepSpellEfficiency == nil
			or creepSpellEfficiency.worthwhile ~= true then
			local rejection = creepSpellEfficiency ~= nil
				and creepSpellEfficiency.reason
				or "single spell efficiency unavailable"
			self:RecordAbilityRejection(
				record,
				name,
				rejection or "single spell less efficient than attacks"
			)
			return nil
		end
	end
	local emergencySelfHeal = (rule.mode == "ally_heal" or rule.healing == true)
		and (rule.include_self ~= false or rule.heals_caster == true)
		and HealthRatio(hero) <= (tonumber(rule.self_save_threshold) or 0.40)
	local creepPackOpportunity = false
	if unitTargetAreaOpportunity then
		creepPackOpportunity = true
	elseif rule.mode == "no_target_enemy" then
		creepPackOpportunity = self:CountAbilityTargetsAround(
			ability,
			rule,
			enemies,
			hero:GetAbsOrigin(),
			tonumber(rule.radius) or 450
		) >= (tonumber(rule.minimum_targets) or 1)
	elseif (rule.mode == "point_aoe" or rule.mode == "directional_point")
		and self:IsCombatTarget(target) then
		creepPackOpportunity = self:CountAbilityTargetsAround(
			ability,
			rule,
			enemies,
			target:GetAbsOrigin(),
			tonumber(rule.radius) or 325
		) >= (tonumber(rule.minimum_targets) or 1)
	end
	if not emergencySelfHeal
		and not etherealPriority
		and not creepPackOpportunity
		and not (
			creepSpellEfficiency ~= nil
			and creepSpellEfficiency.worthwhile == true
		)
		and not self:CanConsiderAbility(record, name, difficulty) then return nil end
	record.casts_considered = (record.casts_considered or 0) + 1
	local mode = rule.mode
	local action = {
		ability = ability,
		mode = mode,
		score = rule.priority or 60,
		reason = mode,
		control = rule.control == true,
	}
	local bossSpellOpportunity = XHSBotConfig:IsBossTarget(target)
		and self:CanAbilityAffectEnemy(ability, target, rule)
	if etherealPriority then
		action.score = action.score + 55
		action.reason = "spell priority: ethereal target"
	end

	if mode == "enemy_unit" then
		if not self:IsCombatTarget(target) then
			self:RecordAbilityRejection(record, name, "no visible target")
			return nil
		end
		if Distance2D(hero:GetAbsOrigin(), target:GetAbsOrigin()) > self:GetAbilityRange(hero, ability, target) then
			self:RecordAbilityRejection(record, name, "target out of range")
			return nil
		end
		action.target = target
		if unitTargetAreaOpportunity then
			action.score = action.score + math.min(24, unitTargetAreaCount * 4)
			action.reason = "unit-target AoE on "
				.. tostring(unitTargetAreaCount) .. " enemies"
		end
		if XHSBotConfig:IsBossTarget(target) and rule.prefer_boss then action.score = action.score + 12 end
		if creepSpellEfficiency ~= nil
			and creepSpellEfficiency.fallback_cast == true then
			action.score = action.score + 18
			action.reason = creepSpellEfficiency.reason
		elseif creepSpellEfficiency ~= nil then
			action.score = action.score + math.min(
				28,
				math.max(0, creepSpellEfficiency.efficiency - 1) * 9
					+ math.max(0, creepSpellEfficiency.time_saved) * 3
			)
			action.reason = string.format(
				"creep spell efficient: %.0f post-reduction vs %.0f attack, "
					.. "%.2fs cast, %.2fs saved, x%.2f",
				creepSpellEfficiency.spell_damage,
				creepSpellEfficiency.attack_damage,
				creepSpellEfficiency.cast_lock,
				creepSpellEfficiency.time_saved,
				creepSpellEfficiency.efficiency
			)
		end
	elseif mode == "ally_heal" then
		local ally, allyScore, ratio, context = self:FindBestAllyAbilityTarget(
			hero,
			self:GetAbilityRange(hero, ability, hero),
			rule,
			enemies,
			target
		)
		local acceptableHealThreshold = tonumber(difficulty.ally_heal_threshold) or 0.50
		if ally == hero then
			acceptableHealThreshold = math.max(
				acceptableHealThreshold,
				tonumber(rule.self_save_threshold) or 0.40
			)
		end
		if ally == nil or ratio > acceptableHealThreshold then
			self:RecordAbilityRejection(record, name, "no ally below heal threshold")
			return nil
		end
		local estimated, effective, effectiveRatio, usefulFraction =
			self:EstimateAbilityHeal(ability, rule, ally)
		local knownHealAmount = estimated > 0
		local allyCritical = ratio <= (tonumber(rule.self_save_threshold) or 0.40)
			or context ~= nil and context.focused_by > 0
		if knownHealAmount
			and not allyCritical
			and (effectiveRatio < (tonumber(rule.minimum_effective_heal_ratio) or 0.06)
				or usefulFraction < (tonumber(rule.minimum_heal_use_fraction) or 0.25)) then
			self:RecordAbilityRejection(record, name, "heal would mostly overheal")
			return nil
		end
		local selfEstimated, selfEffective, selfEffectiveRatio =
			self:EstimateAbilityHeal(ability, rule, hero)
		action.target = ally
		action.score = action.score + math.min(45, allyScore * 0.45)
		action.is_heal = true
		action.heal_target_health_ratio = ratio
		action.estimated_heal = estimated
		action.effective_heal = effective
		action.effective_heal_ratio = effectiveRatio
		action.heals_self = ally == hero or rule.heals_caster == true
		action.self_effective_heal = ally == hero and effective
			or rule.heals_caster == true and selfEffective
			or 0
		action.self_effective_heal_ratio = ally == hero and effectiveRatio
			or rule.heals_caster == true and selfEffectiveRatio
			or 0
		action.reason = "heal ally at " .. tostring(math.floor(ratio * 100))
			.. "%, useful=" .. tostring(math.floor(effective))
			.. ", focused by " .. tostring(context and context.focused_by or 0)
	elseif mode == "ally_buff" then
		local ally, allyScore, _, context, role = self:FindBestAllyAbilityTarget(
			hero,
			self:GetAbilityRange(hero, ability, hero),
			rule,
			enemies,
			target
		)
		action.target = ally
		if action.target == nil
			or rule.require_combat and (context == nil or context.engaged ~= true) then
			self:RecordAbilityRejection(record, name, "no valid buff opportunity")
			return nil
		end
		action.score = math.max(
			action.score + math.min(24, math.max(0, allyScore) * 0.25),
			tonumber(rule.opportunity_floor) or 88
		)
		action.reason = "teamfight buff for " .. tostring(role or "ally")
			.. ", focused by " .. tostring(context and context.focused_by or 0)
	elseif mode == "no_target_enemy" then
		local nearby = self:CountAbilityTargetsAround(
			ability,
			rule,
			enemies,
			hero:GetAbsOrigin(),
			rule.radius or 450
		)
		if nearby < (rule.minimum_targets or 1)
			and not bossSpellOpportunity
			and not etherealPriority then
			self:RecordAbilityRejection(
				record,
				name,
				"nearby targets " .. tostring(nearby)
					.. "/" .. tostring(rule.minimum_targets or 1)
			)
			return nil
		end
		action.score = action.score + math.min(15, nearby * 3)
		action.reason = tostring(nearby) .. " nearby enemies"
	elseif mode == "no_target_mixed" then
		local nearby = self:CountAbilityTargetsAround(
			ability,
			rule,
			enemies,
			hero:GetAbsOrigin(),
			rule.radius or 550
		)
		local lowestAlly, allyRatio = self:GetLowestHealthAlly(hero, rule.radius or 550)
		local selfRatio = HealthRatio(hero)
		local emergencySelfOpportunity = rule.healing == true
			and rule.heals_caster == true
			and selfRatio <= (tonumber(rule.self_save_threshold) or 0.40)
		if nearby < (rule.minimum_targets or 1)
			and allyRatio > difficulty.ally_heal_threshold
			and not emergencySelfOpportunity then
			return nil
		end
		action.score = action.score + math.min(18, nearby * 3) + (1 - allyRatio) * 18
		if rule.healing == true then
			local estimated, effective, effectiveRatio, usefulFraction =
				self:EstimateAbilityHeal(ability, rule, lowestAlly)
			local selfEstimated, selfEffective, selfEffectiveRatio =
				self:EstimateAbilityHeal(ability, rule, hero)
			local knownHealAmount = estimated > 0
			local rescueOpportunity = allyRatio <= difficulty.ally_heal_threshold
				or emergencySelfOpportunity
			if nearby < (rule.minimum_targets or 1)
				and knownHealAmount
				and not rescueOpportunity
				and (effectiveRatio < (tonumber(rule.minimum_effective_heal_ratio) or 0.06)
					or usefulFraction < (tonumber(rule.minimum_heal_use_fraction) or 0.25)) then
				self:RecordAbilityRejection(record, name, "area heal would mostly overheal")
				return nil
			end
			action.is_heal = true
			action.heal_target = lowestAlly
			action.heal_target_health_ratio = allyRatio
			action.estimated_heal = estimated
			action.effective_heal = effective
			action.effective_heal_ratio = effectiveRatio
			action.heals_self = rule.heals_caster == true
			action.self_effective_heal = rule.heals_caster == true and selfEffective or 0
			action.self_effective_heal_ratio =
				rule.heals_caster == true and selfEffectiveRatio or 0
			action.reason = "mixed heal useful=" .. tostring(math.floor(effective))
				.. " at " .. tostring(math.floor(allyRatio * 100)) .. "%"
				.. ", enemies=" .. tostring(nearby)
		end
	elseif mode == "point_aoe" then
		if not self:IsCombatTarget(target) then
			self:RecordAbilityRejection(record, name, "no point target")
			return nil
		end
		local range = self:GetAbilityRange(hero, ability, target)
		if Distance2D(hero:GetAbsOrigin(), target:GetAbsOrigin()) > range then
			self:RecordAbilityRejection(record, name, "point target out of range")
			return nil
		end
		local nearby = self:CountAbilityTargetsAround(
			ability,
			rule,
			enemies,
			target:GetAbsOrigin(),
			rule.radius or 325
		)
		if nearby < (rule.minimum_targets or 1)
			and not bossSpellOpportunity
			and not etherealPriority then
			self:RecordAbilityRejection(
				record,
				name,
				"point targets " .. tostring(nearby)
					.. "/" .. tostring(rule.minimum_targets or 1)
			)
			return nil
		end
		action.position = target:GetAbsOrigin()
		action.target = target
		action.score = action.score + math.min(18, nearby * 4)
	elseif mode == "directional_point" then
		if not self:IsCombatTarget(target) then return nil end
		local heroOrigin = hero:GetAbsOrigin()
		local targetOrigin = target:GetAbsOrigin()
		local targetDistance = Distance2D(heroOrigin, targetOrigin)
		if tonumber(rule.travel_range) ~= nil
			and targetDistance > tonumber(rule.travel_range) then
			return nil
		end
		local nearby = self:CountAbilityTargetsAround(
			ability,
			rule,
			enemies,
			targetOrigin,
			rule.radius or 425
		)
		if nearby < (rule.minimum_targets or 1)
			and not bossSpellOpportunity
			and not etherealPriority then return nil end
		local direction = targetOrigin - heroOrigin
		direction.z = 0
		if direction:Length2D() <= 1 and hero.GetForwardVector ~= nil then
			direction = hero:GetForwardVector()
			direction.z = 0
		end
		if direction:Length2D() <= 1 then return nil end
		local legalRange = math.max(64, self:GetAbilityRange(hero, ability, nil) - 75)
		local jitterMargin = math.max(0, tonumber(difficulty.order_jitter) or 0) + 20
		local legalAimDistance = math.max(64, legalRange - jitterMargin)
		local aimDistance = math.min(tonumber(rule.aim_distance) or 240, legalAimDistance)
		action.position = heroOrigin + direction:Normalized() * aimDistance
		action.target = target
		action.score = action.score + math.min(18, nearby * 4)
		action.reason = "directional cast toward " .. tostring(nearby) .. " enemies"
	elseif mode == "self_buff" then
		if rule.require_combat and target == nil then return nil end
		local minimumHealthRatio = math.max(
			0,
			math.min(1, tonumber(rule.minimum_health_ratio) or 0)
		)
		if HealthRatio(hero) < minimumHealthRatio then
			self:RecordAbilityRejection(record, name, "health too low for risky self buff")
			return nil
		end
		local nearby = self:CountEnemiesAround(
			enemies,
			hero:GetAbsOrigin(),
			tonumber(rule.radius) or 700
		)
		local minimumTargets = math.max(0, tonumber(rule.minimum_targets) or 0)
		local bossOpportunity = rule.cast_on_boss == true
			and XHSBotConfig:IsBossTarget(target)
		if nearby < minimumTargets and not bossOpportunity then
			self:RecordAbilityRejection(record, name, "insufficient self-buff pressure")
			return nil
		end
		action.score = math.max(action.score, tonumber(rule.opportunity_floor) or 88)
		action.reason = bossOpportunity and "self buff for boss"
			or "self buff for " .. tostring(nearby) .. " enemies"
	elseif mode == "self_defensive" then
		if rule.active_modifier ~= nil
			and hero.HasModifier ~= nil
			and hero:HasModifier(rule.active_modifier) then
			return nil
		end
		local context = self:GetAllyCombatContext(hero, hero, enemies, target)
		local ratio = HealthRatio(hero)
		local healthOpportunity = ratio <= (tonumber(rule.health_threshold) or 0.45)
		local focusOpportunity = context.focused_by >= (tonumber(rule.focus_threshold) or 2)
		if not healthOpportunity and not focusOpportunity and not context.boss_nearby then
			self:RecordAbilityRejection(record, name, "insufficient defensive pressure")
			return nil
		end
		action.score = math.max(action.score, tonumber(rule.opportunity_floor) or 94)
			+ (1 - ratio) * 20 + context.focused_by * 5
		action.reason = "self defense at " .. tostring(math.floor(ratio * 100))
			.. "%, focused by " .. tostring(context.focused_by)
	elseif mode == "team_buff" then
		local radius = tonumber(rule.radius) or 900
		local allies = self:GetAllies(hero, radius)
		local eligibleAllies = 0
		local engagedAllies = 0
		local pressure = 0
		for _, ally in pairs(allies) do
			if IsValidEntityHandle(ally) and ally:IsAlive() then
				local alreadyBuffed = rule.active_modifier ~= nil
					and ally.HasModifier ~= nil
					and ally:HasModifier(rule.active_modifier)
				if not alreadyBuffed then
					eligibleAllies = eligibleAllies + 1
					local context = self:GetAllyCombatContext(hero, ally, enemies, target)
					if context.engaged then engagedAllies = engagedAllies + 1 end
					pressure = pressure + context.close_enemies
						+ context.focused_by * 2
						+ (context.boss_nearby and 3 or 0)
				end
			end
		end
		local bossOpportunity = rule.cast_on_boss == true
			and XHSBotConfig:IsBossTarget(target)
		if eligibleAllies < (tonumber(rule.minimum_allies) or 2)
			or engagedAllies <= 0
			or pressure < (tonumber(rule.minimum_enemies) or 2)
				and not bossOpportunity then
			self:RecordAbilityRejection(record, name, "insufficient team buff opportunity")
			return nil
		end
		action.score = math.max(action.score, tonumber(rule.opportunity_floor) or 90)
			+ math.min(18, pressure * 2)
		action.reason = "team buff for " .. tostring(eligibleAllies)
			.. " allies under " .. tostring(pressure) .. " pressure"
	elseif mode == "summon" then
		if rule.require_combat and target == nil then return nil end
		action.score = math.max(action.score, tonumber(rule.opportunity_floor) or 88)
	elseif mode == "toggle_single" then
		local manaReady = rule.mana_gate == false
			or ManaRatio(hero) > (tonumber(rule.mana_threshold) or 0.20)
		action.desired_state = target ~= nil
			and self:CanAbilityAffectEnemy(ability, target, rule)
			and #enemies < 3
			and manaReady
		action.score = ability:GetToggleState() == action.desired_state
			and 0 or math.max(action.score, tonumber(rule.state_change_floor) or 87)
	elseif mode == "toggle_aoe" then
		local manaReady = rule.mana_gate == false
			or ManaRatio(hero) > (tonumber(rule.mana_threshold) or 0.20)
		local nearby = self:CountAbilityTargetsAround(
			ability,
			rule,
			enemies,
			hero:GetAbsOrigin(),
			tonumber(rule.radius) or 450
		)
		action.desired_state = target ~= nil
			and nearby >= (rule.minimum_targets or 3)
			and manaReady
		action.score = ability:GetToggleState() == action.desired_state
			and 0 or math.max(action.score, tonumber(rule.state_change_floor) or 87)
	elseif mode == "defensive_toggle" then
		action.desired_state = target ~= nil or HealthRatio(hero) < 0.65
		action.score = ability:GetToggleState() == action.desired_state
			and 0 or math.max(action.score, tonumber(rule.state_change_floor) or 87)
	elseif mode == "autocast_attack" then
		local manaReady = ManaRatio(hero) >= (tonumber(rule.mana_threshold) or 0.20)
		action.desired_state = target ~= nil
			and self:CanAbilityAffectEnemy(ability, target, rule)
			and manaReady
		local enabled = ability.GetAutoCastState ~= nil and ability:GetAutoCastState() or false
		action.score = enabled == action.desired_state
			and 0 or math.max(action.score, tonumber(rule.state_change_floor) or 87)
	else
		return nil
	end

	local filterAccepted, filterReason = self:PassesCastFilter(ability, action)
	if not filterAccepted then
		self:RecordAbilityRejection(record, name, filterReason)
		return nil
	end

	if (record.combo_until or 0) > GameRules:GetGameTime()
		and action.control ~= true
		and not isToggleMode
		and mode ~= "ally_buff"
		and mode ~= "self_buff"
		and mode ~= "summon"
		and (record.combo_target_entindex == nil
			or target == nil
			or record.combo_target_entindex == target:entindex()) then
		action.score = action.score + (tonumber(difficulty.simple_combo_bonus) or 0)
		action.reason = action.reason .. " (simple control follow-up)"
	end
	local cooldown = 0
	if ability.GetCooldown ~= nil then
		local ok, value = pcall(function()
			return ability:GetCooldown(math.max(0, ability:GetLevel() - 1))
		end)
		if ok then cooldown = math.max(0, tonumber(value) or 0) end
	end
	action.cooldown_budget = cooldown
	action.long_cooldown = rule.reserve_ultimate == true or cooldown >= 45
	local offensive = mode == "enemy_unit"
		or mode == "point_aoe"
		or mode == "directional_point"
		or mode == "no_target_enemy"
		or mode == "no_target_mixed"
		or mode == "summon"
	if action.long_cooldown and offensive
		and record.engagement_classification == "FARMABLE"
		and not XHSBotConfig:IsBossTarget(target)
		and (tonumber(record.engagement_time_to_clear) or 999) <= 8
		and (tonumber(record.combat_threat) or 0) < 0.62 then
		record.ultimate_reservation_reason = "farmable pack; reserve " .. name
		record.ultimate_reservations = (record.ultimate_reservations or 0) + 1
		self:RecordAbilityRejection(record, name, record.ultimate_reservation_reason)
		return nil
	end
	if action.score <= 0 then return nil end
	return action
end

function XHSBotBrain:FindFirstLearnedAbility(hero, abilityNames)
	for _, abilityName in ipairs(abilityNames or {}) do
		local ability = hero:FindAbilityByName(abilityName)
		if ability ~= nil
			and not ability:IsNull()
			and ability:GetLevel() > 0
			and ability:IsActivated() then
			return ability
		end
	end
	return nil
end

function XHSBotBrain:CanSustainRifleMode(hero, ability, rule)
	if not IsValidEntityHandle(hero) or not IsValidEntityHandle(ability) then
		return false
	end
	local manaCost = 0
	if ability.GetManaCost ~= nil then
		local ok, value = pcall(function()
			return ability:GetManaCost(math.max(0, ability:GetLevel() - 1))
		end)
		if ok then manaCost = math.max(0, tonumber(value) or 0) end
	end
	if manaCost <= 0 then return true end
	local maximumMana = math.max(1, tonumber(hero:GetMaxMana()) or 1)
	local minimumMana = math.max(
		maximumMana * (tonumber(rule.minimum_mana_ratio) or 0.05),
		manaCost * math.max(1, tonumber(rule.minimum_mode_attacks) or 2)
	)
	return hero:GetMana() >= minimumMana
end

function XHSBotBrain:BuildRifleAttackModeAction(hero, rule, target, enemies, record)
	if type(rule) ~= "table" then return nil end

	local singleAbility = self:FindFirstLearnedAbility(hero, rule.single_target)
	local cleaveAbility = self:FindFirstLearnedAbility(hero, rule.cleave)
	if singleAbility == nil and cleaveAbility == nil then return nil end

	local activeAbility = nil
	local activeMode = nil
	if singleAbility ~= nil and singleAbility:GetToggleState() then
		activeAbility = singleAbility
		activeMode = "single"
	elseif cleaveAbility ~= nil and cleaveAbility:GetToggleState() then
		activeAbility = cleaveAbility
		activeMode = "cleave"
	end

	local targetIsValid = self:IsCombatTarget(target)
	local desiredMode = nil
	local nearbyTargetCount = 0
	local now = GameRules:GetGameTime()
	local targetIndex = targetIsValid and target:entindex() or nil
	local previousTargetIndex = record.rifle_attack_mode_target_entindex
	local targetChanged = targetIndex ~= nil
		and targetIndex ~= previousTargetIndex
	if targetIsValid then
		record.rifle_attack_mode_target_entindex = targetIndex
		record.rifle_attack_mode_target_seen_at = now
		nearbyTargetCount = self:CountEnemiesAround(
			enemies,
			target:GetAbsOrigin(),
			tonumber(rule.cleave_radius) or 325
		)
		if XHSBotConfig:IsBossTarget(target) then
			desiredMode = "single"
		else
			local enterTargets = math.max(2, tonumber(rule.cleave_enter_targets) or 3)
			local exitTargets = math.max(1, math.min(
				enterTargets,
				tonumber(rule.cleave_exit_targets) or (enterTargets - 1)
			))
			if activeMode == "cleave" then
				desiredMode = nearbyTargetCount >= exitTargets and "cleave" or "single"
			else
				desiredMode = nearbyTargetCount >= enterTargets and "cleave" or "single"
			end
		end
	elseif activeMode ~= nil
		and now - (record.rifle_attack_mode_target_seen_at or -math.huge)
			<= (tonumber(rule.target_loss_grace) or 0.45) then
		desiredMode = activeMode
	end

	local desiredAbility = desiredMode == "cleave" and cleaveAbility
		or desiredMode == "single" and singleAbility
		or nil
	if desiredAbility ~= nil
		and not self:CanSustainRifleMode(hero, desiredAbility, rule) then
		desiredAbility = nil
		desiredMode = nil
	elseif desiredAbility == nil and desiredMode ~= nil then
		desiredMode = nil
	end

	if desiredMode ~= nil
		and activeMode ~= nil
		and desiredMode ~= activeMode
		and not XHSBotConfig:IsBossTarget(target)
		and now < (record.rifle_attack_mode_hold_until or 0)
		and not (rule.target_change_override == true and targetChanged) then
		desiredMode = activeMode
		desiredAbility = activeAbility
	end

	if desiredMode == activeMode
		and activeAbility ~= nil then
		record.rifle_attack_mode = activeMode
		return nil
	end

	local actionAbility = desiredAbility or activeAbility
	local desiredState = desiredAbility ~= nil
	if actionAbility == nil then
		return nil
	end

	if desiredMode ~= nil and desiredMode ~= record.rifle_attack_mode then
		record.rifle_attack_mode = desiredMode
		record.rifle_attack_mode_hold_until = now
			+ (tonumber(rule.minimum_mode_duration) or 0.35)
	end

	local reason = "disable rifle attack mode"
	if desiredMode == "single" then
		reason = XHSBotConfig:IsBossTarget(target)
			and "single-target DPS mode for boss"
			or "single-target DPS mode for " .. tostring(nearbyTargetCount) .. " clustered target(s)"
	elseif desiredMode == "cleave" then
		reason = "cleave mode for " .. tostring(nearbyTargetCount) .. " clustered targets"
	end

	record.casts_considered = (record.casts_considered or 0) + 1
	return {
		ability = actionAbility,
		mode = "rifle_attack_mode",
		desired_state = desiredState,
		weapon_mode = desiredMode or "off",
		score = tonumber(rule.priority) or 90,
		reason = reason,
	}
end

function XHSBotBrain:BuildAbilityActions(hero, profile, target, enemies, difficulty, record)
	local actions = {}
	record.ultimate_reservation_reason = ""
	local attackModeAction = self:BuildRifleAttackModeAction(
		hero,
		profile.attack_mode,
		target,
		enemies,
		record
	)
	if attackModeAction ~= nil then
		table.insert(actions, attackModeAction)
	end
	for abilityName, rule in pairs(profile.abilities or {}) do
		rule.ability_name = abilityName
		local ability = hero:FindAbilityByName(abilityName)
		local action = self:BuildAbilityAction(hero, ability, rule, target, enemies, difficulty, record)
		if action ~= nil then table.insert(actions, action) end
	end
	return actions
end

function XHSBotBrain:FilterNoCombatAbilityActions(actions)
	local safe = {}
	for _, action in ipairs(actions or {}) do
		-- Muradin is a survival event: never let a mixed/offensive spell touch
		-- him. Pure targeted heals, personal shields and defensive toggles are
		-- safe, and the utility layer will still use them only under pressure.
		local mode = action.mode
		local pureHeal = action.is_heal == true and mode == "ally_heal"
		local personalDefense = mode == "self_defensive"
			or (mode == "defensive_toggle" and action.desired_state == true)
		if pureHeal or personalDefense then
			action.no_combat_safe = true
			table.insert(safe, action)
		end
	end
	return safe
end

function XHSBotBrain:GetRepositionPosition(
	hero,
	target,
	profile,
	anchor,
	mobileSafeZone,
	strategicThreatPosition
)
	if not self:IsCombatTarget(target) then return anchor end
	if IsValidEntityHandle(mobileSafeZone) then
		local threatPosition = strategicThreatPosition
			or select(1, self:GetStrategicThreatPosition(
				hero,
				target,
				nil
			))
			or target:GetAbsOrigin()
		local awayFromThreat =
			mobileSafeZone:GetAbsOrigin() - threatPosition
		awayFromThreat.z = 0
		if awayFromThreat:Length2D() > 1 then
			return mobileSafeZone:GetAbsOrigin()
				+ awayFromThreat:Normalized()
					* self:GetCoverFormationDistance(hero, profile)
		end
	end
	local away = hero:GetAbsOrigin() - target:GetAbsOrigin()
	away.z = 0
	if away:Length2D() <= 1 then away = RandomVector(1) end
	-- Reposition is a short combat step, not a replacement for attacking. The
	-- former full safety-distance stride let equal-speed creeps chase a ranged
	-- hero forever while every new think selected another retreating move.
	local repositionStep = math.max(
		220,
		math.min(420, tonumber(profile.safety_distance) or 300)
	)
	local position =
		hero:GetAbsOrigin() + away:Normalized() * repositionStep

	if anchor ~= nil and Distance2D(position, anchor) > 2200 then
		position = PositionToward(position, anchor, 300)
	end
	return position
end

function XHSBotBrain:UpdateStuck(hero, record, assignment)
	local now = GameRules:GetGameTime()
	local position = hero:GetAbsOrigin()
	if hero:IsChanneling()
		or hero:IsStunned()
		or hero:IsHexed()
		or (hero.IsCommandRestricted ~= nil and hero:IsCommandRestricted()) then
		record.stuck_sample_position = position
		record.stuck_sample_at = now
		record.stuck_since = nil
		return false
	end
	local movementDestination = record.last_movement_destination
	local movementOrderAt = tonumber(record.last_movement_order_at) or -math.huge
	local destinationDistance = movementDestination ~= nil
		and Distance2D(position, movementDestination) or 0
	local movementStillRelevant = movementDestination ~= nil
		and destinationDistance > 140
		and now - movementOrderAt <= 8
	if not movementStillRelevant or hero:IsAttacking() then
		record.stuck_sample_position = position
		record.stuck_sample_at = now
		record.stuck_since = nil
		return false
	end
	if record.stuck_sample_position == nil then
		record.stuck_sample_position = position
		record.stuck_sample_at = now
		return false
	end
	if now - (record.stuck_sample_at or 0) < 1.5 then return false end

	local moved = Distance2D(position, record.stuck_sample_position)
	record.stuck_sample_position = position
	record.stuck_sample_at = now

	if moved >= 55 then
		record.stuck_since = nil
		return false
	end

	record.stuck_since = record.stuck_since or now
	if now - record.stuck_since < 3 then return false end

	local recoveryGoal = movementDestination
	local defendingBase = assignment ~= nil and assignment.goal == "defend_base"
	if defendingBase then
		recoveryGoal = assignment.threat_position or assignment.anchor or recoveryGoal
	end
	local recoveryStep = 320 + math.min(240, (record.stuck_recoveries or 0) * 45)
	local recovery = PositionToward(position, recoveryGoal, recoveryStep)
	local issued = defendingBase
		and XHSBotExecutor:AttackMove(
			hero,
			recovery,
			record,
			"defense path recovery",
			0
		)
		or XHSBotExecutor:Move(hero, recovery, record, "stuck recovery", 0)
	if not issued then return false end

	record.stuck_since = nil
	record.stuck_recoveries = (record.stuck_recoveries or 0) + 1
	record.stuck_sample_position = position
	record.stuck_sample_at = now
	return true
end

function XHSBotBrain:UpdateDangerTelemetry(hero, record, dangerEntries, now, thinkInterval)
	local active = false
	for _, entry in pairs(dangerEntries or {}) do
		if now >= (entry.activates_at or now)
			and now <= (entry.expires_at or now) then
			active = true
			break
		end
	end

	local health = hero:GetHealth()
	local previousHealth = tonumber(record.telemetry_last_health)
	if previousHealth ~= nil and previousHealth > health
		and (active or record.was_in_active_danger == true) then
		local damage = previousHealth - health
		record.danger_hits = (record.danger_hits or 0) + 1
		record.danger_damage = (record.danger_damage or 0) + damage
		record.last_danger_damage = damage
	end
	if active then
		record.danger_exposure_seconds = (record.danger_exposure_seconds or 0)
			+ (tonumber(thinkInterval) or 0)
	end
	record.telemetry_last_health = health
	record.was_in_active_danger = active
end

function XHSBotBrain:BuildContext(playerID, hero, profile, difficulty, record, assignment, encounter)
	local now = GameRules:GetGameTime()
	local assignmentGoal = assignment and assignment.goal or "regroup"
	local nonCombatObjective = assignment ~= nil
		and assignment.non_combat == true
	local returningToLane = self:UpdateLaneReturnState(hero, assignment, record)
	if encounter ~= nil then
		returningToLane = false
		record.returning_to_lane = false
		if assignment ~= nil then assignment.returning_to_lane = false end
	end
	if returningToLane then
		-- Drop assistance-era commitments so nearby creeps cannot pull the bot
		-- from one lane to the next while it is travelling home.
		record.target_entindex = nil
		record.target_score = nil
		record.target_committed_until = now
		record.last_seen_position = nil
		record.last_seen_until = now
	end
	local perceivedEnemies = self:FindEnemies(hero, difficulty.perception_radius or 2100)
	local enemies = {}
	for _, enemy in pairs(perceivedEnemies or {}) do
		if encounter == nil
			or XHSBotEncounterDirector:IsTargetAllowed(encounter, playerID, enemy) then
			table.insert(enemies, enemy)
		end
	end
	local target = not nonCombatObjective
		and encounter
		and encounter.forced_target
		or nil
	local forcedTarget = target
	record.forced_target_entindex = IsValidEntityHandle(forcedTarget)
		and forcedTarget:entindex() or nil
	record.forced_target_block_reason = nil
	if target ~= nil and not self:IsCombatTarget(target) then
		record.forced_target_block_reason = "invalid forced target"
		target = nil
	elseif target ~= nil
		and not self:IsTeamVisible(hero, target) then
		-- A campaign boss may exist several rooms ahead. Do not let its large
		-- forced-target score starve the lower-scored movement action: advance to
		-- the encounter anchor until the team genuinely sees the boss.
		record.forced_target_block_reason = "forced target not team-visible"
		target = nil
	elseif target ~= nil then
		local forcedDistance = Distance2D(
			hero:GetAbsOrigin(),
			target:GetAbsOrigin()
		)
		local forcedChaseLimit = math.max(
			250,
			tonumber(encounter and encounter.max_chase_distance)
				or tonumber(difficulty.max_chase_distance)
				or 1800
		)
		if forcedDistance > forcedChaseLimit then
			record.forced_target_block_reason =
				"forced target beyond chase limit"
			target = nil
		end
	end
	record.forced_target_reachable = target ~= nil
	local targetScore = target ~= nil and 120 or nil
	local engagementPack = nil
	local threatPacks = {}
	if target == nil
		and encounter == nil
		and not nonCombatObjective then
		engagementPack, threatPacks = self:EvaluateThreatPacks(
			playerID,
			hero,
			profile,
			record,
			assignment,
			difficulty,
			enemies
		)
	end
	if target == nil
		and not nonCombatObjective
		and (encounter == nil or encounter.no_combat ~= true) then
		target, targetScore = self:SelectTarget(
			playerID,
			hero,
			profile,
			record,
			assignment,
			difficulty,
			engagementPack ~= nil and engagementPack.members or enemies
		)
	end
	local engagement = engagementPack and engagementPack.forecast or nil
	if engagement ~= nil then
		record.engagement_classification = engagement.classification
		record.engagement_mode = engagement.mode
		record.engagement_pack_count = #threatPacks
		record.engagement_enemy_count = engagement.enemy_count
		record.engagement_time_to_clear =
			math.floor(engagement.time_to_clear * 10) / 10
		record.engagement_time_to_die =
			math.floor(engagement.time_to_die * 10) / 10
		record.engagement_survival_ratio =
			math.floor(engagement.survival_ratio * 100) / 100
		record.engagement_feasibility =
			math.floor(engagement.feasibility * 100) / 100
		record.engagement_score = math.floor((engagementPack.score or 0) * 10) / 10
		record.engagement_position = CopyPosition(engagementPack.position)
		local wantsGear = engagement.classification == "NEEDS_GEAR"
			or engagement.classification == "SUICIDAL"
				and engagement.urgent_objective ~= true
		if wantsGear and tostring(record.planned_item or "") ~= "" then
			record.engagement_purchase_requested = true
			record.engagement_purchase_requested_at = now
			record.engagement_purchase_reason = engagement.classification
				.. " pack: TTD " .. string.format("%.1f", engagement.time_to_die)
				.. "s vs TTK " .. string.format("%.1f", engagement.time_to_clear) .. "s"
		elseif engagement.classification == "FARMABLE" then
			record.engagement_purchase_requested = false
		end
		record.engagement_help_requested = engagement.classification == "NEEDS_HELP"
		record.engagement_help_requested_at = record.engagement_help_requested
			and now or record.engagement_help_requested_at
	else
		record.engagement_classification = encounter ~= nil and "ENCOUNTER" or "NONE"
		record.engagement_mode = encounter ~= nil and "FULL_COMMIT" or "NONE"
		record.engagement_pack_count = #threatPacks
		record.engagement_enemy_count = 0
		record.engagement_help_requested = false
	end
	if target ~= nil and record.target_entindex ~= target:entindex() then
		record.target_changes = (record.target_changes or 0) + 1
		record.target_entindex = target:entindex()
		record.target_score = targetScore
		record.target_committed_until = now + difficulty.target_commitment
	elseif target == nil then
		record.target_entindex = nil
		record.target_score = nil
	end
	if now >= (record.last_seen_until or 0) then
		record.last_seen_position = nil
	end

	local anchor = encounter and encounter.anchor
		or assignment and assignment.anchor
		or GetFortPosition()
	if encounter == nil
		and assignmentGoal == "defend_base"
		and assignment ~= nil
		and assignment.threat_position ~= nil then
		-- The threatened structure is the fallback/retreat anchor; the pressure
		-- centre is the combat destination. Otherwise a bot can arrive beside a
		-- tower, see no target, and hold while the wave attacks from its far side.
		anchor = CopyPosition(assignment.threat_position)
	end
	local rawDanger, dangerEntries = XHSBotDangerRegistry:GetDangerAt(
		hero:GetAbsOrigin(),
		now,
		difficulty.danger_reaction_lead
	)
	local danger = rawDanger
	self:UpdateDangerTelemetry(hero, record, dangerEntries, now, difficulty.think_interval)
	if danger > 0 then
		if now >= (record.next_danger_response_choice or 0) then
			record.respond_to_current_danger = RandomFloat(0, 1)
				<= difficulty.danger_response_chance
			record.next_danger_response_choice = now + 0.8
			if not record.respond_to_current_danger then
				record.danger_evades_skipped = (record.danger_evades_skipped or 0) + 1
			end
		end
		if record.respond_to_current_danger ~= true then danger = 0 end
	else
		record.respond_to_current_danger = nil
		record.next_danger_response_choice = now
	end

	local safePosition = nil
	if danger > 0 then
		safePosition = XHSBotDangerRegistry:FindSafestPosition(
			hero:GetAbsOrigin(),
			anchor,
			profile.safety_distance + 220,
			difficulty.danger_reaction_lead
		)
	end

	local targetDistance = target ~= nil and Distance2D(hero:GetAbsOrigin(), target:GetAbsOrigin()) or nil
	if now >= (record.next_attack_move_choice or 0) then
		record.use_attack_move = RandomFloat(0, 1) <= (difficulty.attack_move_chance or 0)
		record.next_attack_move_choice = now + 2
	end
	local threat = self:ComputeCombatThreat(
		hero,
		enemies,
		record,
		profile,
		difficulty,
		target
	)
	local inFarmEvent = GameMode ~= nil and GameMode.FarmEvent_occuring == true
	local defensiveCover, defensiveCoverDistance = nil, nil
	local mobileSafeZone, mobileSafeZoneStrength, mobileSafeZoneDistance = nil, nil, nil
	if not inFarmEvent then
		defensiveCover, defensiveCoverDistance = self:GetDefensiveStructureCover(hero, 950)
		mobileSafeZone, mobileSafeZoneStrength, mobileSafeZoneDistance =
			self:GetMobileSafeZone(hero, target, 1150)
	end
	local strategicThreatPosition, strategicThreatSource =
		self:GetStrategicThreatPosition(hero, target, assignment)
	local fortPosition = GetFortPosition()
	local fortDistance = Distance2D(hero:GetAbsOrigin(), fortPosition)
	local campfire = self:GetCampfireState(hero)
	local recentlyRespawned = now - (tonumber(record.last_respawn_at) or -math.huge)
		<= 12
	local spawnCampfireHold = recentlyRespawned
		and fortDistance <= BASE_LAST_STAND_RADIUS
		and target ~= nil
		and (threat.close_enemies >= 3 or threat.focused_by >= 2)
		and (
			strategicThreatPosition == nil
			or Distance2D(strategicThreatPosition, fortPosition) <= 1800
		)
	local baseLastStand = target ~= nil
		and fortDistance <= BASE_LAST_STAND_RADIUS
		and (threat.close_enemies > 0
			or threat.focused_by > 0
			or threat.score >= 0.18)
	local mobileLastStand = mobileSafeZone ~= nil
		and mobileSafeZoneDistance <= 700
	local lastStand = target ~= nil
		and (defensiveCover ~= nil or baseLastStand or mobileLastStand)
	record.base_last_stand = baseLastStand
	record.campfire_distance = campfire.distance < math.huge
		and math.floor(campfire.distance) or -1
	record.campfire_inside = campfire.inside
	record.mobile_safe_zone_entindex = mobileSafeZone ~= nil
		and mobileSafeZone:entindex() or nil
	record.mobile_safe_zone_strength = mobileSafeZoneStrength ~= nil
		and math.floor(mobileSafeZoneStrength * 100) / 100 or 0
	record.strategic_threat_source = strategicThreatSource
	record.strategic_threat_position = strategicThreatPosition
	local retreatPosition, retreatCover = self:GetRetreatPosition(
		hero,
		target,
		assignment,
		threat,
		mobileSafeZone,
		profile,
		strategicThreatPosition
	)
	if encounter ~= nil
		and (encounter.id == "phase_3"
			or encounter.id == "phase_3_vanguard")
		and self:IsCombatTarget(target) then
		local away = hero:GetAbsOrigin() - target:GetAbsOrigin()
		away.z = 0
		if away:Length2D() > 1 then
			retreatPosition = hero:GetAbsOrigin() + away:Normalized() * 650
			retreatCover = "phase 3 arena spacing"
		end
	end
	local baseRetreatThreshold = profile.retreat_health * difficulty.self_retreat_multiplier
	local dynamicRetreatThreshold = Clamp(
		baseRetreatThreshold
			+ threat.score * math.min(0.07, difficulty.threat_retreat_weight or 0.07)
			+ threat.recent_damage_ratio * math.min(0.40, difficulty.damage_spike_retreat_weight or 0.40)
			+ (threat.focused_by >= 2 and 0.04 or 0)
			+ (threat.fatal_before_escape == true and 0.06 or 0),
		baseRetreatThreshold,
		math.min(difficulty.maximum_retreat_health or 0.68, baseRetreatThreshold + 0.14)
	)
	local mayAttackMove = assignmentGoal == "defend_lane"
		or assignmentGoal == "defend_phase2"
		or assignmentGoal == "defend_base"
		or assignmentGoal == "participate_event"
	local abilityActions = self:BuildAbilityActions(
		hero,
		profile,
		target,
		enemies,
		difficulty,
		record
	)
	if encounter ~= nil and encounter.no_combat == true then
		abilityActions = self:FilterNoCombatAbilityActions(abilityActions)
	end
	local creepLevel = math.max(
		1,
		tonumber(CustomTimers and CustomTimers.creep_level) or 1
	)
	local lootAllowed = encounter == nil
		and not nonCombatObjective
		and not returningToLane
		and assignmentGoal ~= "shop"
		and assignmentGoal ~= "defend_base"
		and threat.score <= 0.65
		and threat.recent_damage_ratio <= 0.12
		and HealthRatio(hero) > dynamicRetreatThreshold + 0.10
		and rawDanger <= 0
	local lootOpportunity = XHSBotLoot:FindOpportunity(
		playerID,
		hero,
		record,
		lootAllowed
	)
	record.loot_kind = lootOpportunity and lootOpportunity.kind or ""
	record.loot_item = lootOpportunity and lootOpportunity.item_name or ""
	record.loot_distance = lootOpportunity and math.floor(lootOpportunity.distance) or -1
	local urgentShopping = assignmentGoal == "shop"
		and assignment ~= nil
		and assignment.shopping_urgent == true
	local activeSpecialCount = CustomTimers ~= nil
		and tonumber(CustomTimers.active_special_wave_count) or 0
	local baseDefenseIdle = assignmentGoal == "defend_base"
		and assignment ~= nil
		and (tonumber(assignment.base_threat_count) or 0) <= 0
		and assignment.base_structure_emergency ~= true
		and activeSpecialCount <= 0
	local specialWaveETA = CustomTimers ~= nil
		and CustomTimers.enable_special_wave == true
		and tonumber(CustomTimers.current_time
			and CustomTimers.current_time["special_wave"]) or nil
	local runeStrategicallyAllowed = encounter == nil
		and not nonCombatObjective
		and not baseLastStand
		and (
			assignmentGoal ~= "shop"
			or creepLevel >= 2 and not urgentShopping
		)
		and (assignmentGoal ~= "defend_base" or baseDefenseIdle)
		and assignmentGoal ~= "hold"
		and assignmentGoal ~= "dead"
		and assignmentGoal ~= "selecting_hero"
	local runeObjective = runeStrategicallyAllowed
		and self:FindRuneObjective(hero, record, difficulty, now) or nil
	local preWaveRune = runeObjective ~= nil
		and baseDefenseIdle
		and specialWaveETA ~= nil
		and specialWaveETA > 0
	if preWaveRune then
		local travelSeconds = runeObjective.distance
			/ math.max(100, self:GetUnitMovementSpeed(hero))
		if travelSeconds > specialWaveETA + 2 then
			self:ReleaseRuneClaim(playerID, record)
			runeObjective = nil
			preWaveRune = false
		end
	end
	if not runeStrategicallyAllowed then
		self:ReleaseRuneClaim(playerID, record)
	end
	if runeObjective ~= nil then
		record.rune_target_id = runeObjective.id
		record.rune_target_type = runeObjective.type
		record.rune_target_distance = math.floor(runeObjective.distance)
	else
		record.rune_target_id = nil
		record.rune_target_type = nil
		record.rune_target_distance = nil
	end
	local repositionThreshold = math.max(
		180,
		math.min(
			420,
			(tonumber(profile.safety_distance) or 300) * 0.68
		)
	)
	local repositionDanger = targetDistance ~= nil
		and (
			targetDistance <= 190
			or threat.focused_by >= 1
			or threat.close_enemies >= 2
			or threat.score >= 0.45
		)
	local repositionReady =
		now >= (tonumber(record.next_reposition_at) or 0)
	record.reposition_threshold = math.floor(repositionThreshold)
	record.reposition_ready = repositionReady
	record.reposition_danger = repositionDanger == true
	return {
		alive = hero:IsAlive(),
		disabled = hero:IsStunned()
			or hero:IsHexed()
			or (hero.IsCommandRestricted ~= nil and hero:IsCommandRestricted()),
		health_ratio = HealthRatio(hero),
		retreat_threshold = dynamicRetreatThreshold,
		retreat_position = retreatPosition,
		retreat_distance = retreatPosition ~= nil
			and Distance2D(hero:GetAbsOrigin(), retreatPosition) or math.huge,
		retreat_cover = retreatCover,
		last_stand = lastStand,
		base_last_stand = baseLastStand,
		spawn_campfire_hold = spawnCampfireHold,
		at_ancient_retreat_limit =
			fortDistance <= ANCIENT_RETREAT_LIMIT_RADIUS,
		defensive_cover = defensiveCover,
		defensive_cover_distance = defensiveCoverDistance,
		mobile_safe_zone = mobileSafeZone,
		mobile_safe_zone_strength = mobileSafeZoneStrength,
		mobile_safe_zone_distance = mobileSafeZoneDistance,
		strategic_threat_position = strategicThreatPosition,
		strategic_threat_source = strategicThreatSource,
		campfire_position = campfire.position or fortPosition,
		campfire_distance = campfire.distance,
		campfire_radius = campfire.radius,
		inside_campfire = campfire.inside,
		combat_threat = threat.score,
		recent_damage_ratio = threat.recent_damage_ratio,
		focused_by = threat.focused_by,
		close_enemies = threat.close_enemies,
		incoming_dps = threat.incoming_dps,
		net_incoming_dps = threat.net_incoming_dps,
		sustain_per_second = threat.sustain_per_second,
		time_to_die = threat.time_to_die,
		escape_time = threat.escape_time,
		health_at_escape_ratio = threat.health_at_escape_ratio,
		fatal_before_escape = threat.fatal_before_escape,
		control_risk = threat.control_risk,
		forecast_confidence = threat.forecast_confidence,
		danger = danger,
		raw_danger = rawDanger,
		danger_entries = dangerEntries,
		safe_position = safePosition,
		channel_interrupt_danger = difficulty.channel_interrupt_danger,
		target = target,
		target_priority = math.min(20, math.max(0, targetScore or 0) * 0.2),
		too_close = (encounter == nil or encounter.no_reposition ~= true)
			and not lastStand and targetDistance ~= nil
			and profile.preferred_range >= 450
			and targetDistance < repositionThreshold
			and repositionDanger
			and repositionReady,
		reposition_position = self:GetRepositionPosition(
			hero,
			target,
			profile,
			anchor,
			mobileSafeZone,
			engagementPack ~= nil and engagementPack.position
				or strategicThreatPosition
		),
		engagement_classification = engagement and engagement.classification or "NONE",
		engagement_mode = engagement and engagement.mode or "FULL_COMMIT",
		engagement_position = engagementPack and engagementPack.position or nil,
		engagement_enemy_count = engagement and engagement.enemy_count or 0,
		engagement_time_to_clear = engagement and engagement.time_to_clear or 0,
		engagement_time_to_die = engagement and engagement.time_to_die or 0,
		engagement_survival_ratio = engagement and engagement.survival_ratio or 0,
		engagement_feasibility = engagement and engagement.feasibility or 1,
		engagement_urgent = engagement and engagement.urgent_objective == true or false,
		engagement_allow_attack = engagement == nil
			or engagement.classification == "FARMABLE"
			or engagement.classification == "CONTESTABLE"
			or engagement.urgent_objective == true
			or (engagement.mode == "PULL_SMALL_GROUP"
				or engagement.mode == "KITE_EDGE")
				and targetDistance ~= nil
				and targetDistance <= math.max(
					tonumber(profile.preferred_range) or 0,
					450
				) + 100
				and threat.focused_by <= 1,
		ability_actions = abilityActions,
		anchor = anchor,
		anchor_distance = Distance2D(hero:GetAbsOrigin(), anchor),
		assignment_urgency = assignment and assignment.urgency or 0,
		non_combat_objective = nonCombatObjective,
		objective_reached_distance = assignment
			and assignment.reached_distance or 180,
		shopping = assignmentGoal == "shop"
			and not (
				runeObjective ~= nil
				and creepLevel >= 2
				and not urgentShopping
			),
		shopping_urgent = assignmentGoal == "shop"
			and assignment.shopping_urgent == true,
		base_defense_active = assignmentGoal == "defend_base",
		base_defense_idle = baseDefenseIdle,
		returning_to_lane = returningToLane,
		max_chase_distance = encounter and encounter.max_chase_distance
			or assignment and assignment.chase_radius
			or difficulty.max_chase_distance,
		last_seen_position = target == nil and record.last_seen_position or nil,
		attack_move = target == nil and mayAttackMove
			and (assignmentGoal == "defend_base"
				or record.use_attack_move == true),
		encounter_mode = encounter and encounter.id or nil,
		arena_combat = encounter and encounter.arena_combat == true,
		encounter_no_combat = encounter and encounter.no_combat == true,
		encounter_reached_distance = encounter and encounter.reached_distance or 180,
		no_retreat = encounter and encounter.no_retreat == true,
		rune_position = runeObjective and runeObjective.position or nil,
		rune_distance = runeObjective and runeObjective.distance or nil,
		rune_type = runeObjective and runeObjective.type or nil,
		rune_id = runeObjective and runeObjective.id or nil,
		rune_priority = difficulty.rune_priority,
		rune_threat_ceiling = difficulty.rune_threat_ceiling,
		rune_health_margin = difficulty.rune_health_margin,
		rune_progression_critical = creepLevel >= 2,
		rune_pre_wave = preWaveRune,
		special_wave_eta = specialWaveETA,
		creep_level = creepLevel,
		loot_kind = lootOpportunity and lootOpportunity.kind or nil,
		loot_entity = lootOpportunity and lootOpportunity.entity or nil,
		loot_position = lootOpportunity and lootOpportunity.position or nil,
		loot_distance = lootOpportunity and lootOpportunity.distance or nil,
		loot_item = lootOpportunity and lootOpportunity.item_name or nil,
	}
end

function XHSBotBrain:MacroState(assignment, encounter)
	if encounter ~= nil then
		local encounterStates = {
			muradin_survival = "MURADIN_SURVIVAL",
			ramero_baristol = "RAMERO_BARISTOL_ARENA",
			sogat = "SOGAT_ARENA",
			farm_event = "FARM_EVENT",
			phase_2 = "PHASE_2",
			phase_3_vanguard = "PHASE_3_VANGUARD",
			phase_3 = "PHASE_3",
		}
		if encounterStates[encounter.id] ~= nil then
			return encounterStates[encounter.id]
		end
	end
	if assignment ~= nil and assignment.ancient_patrol == true then
		return "PATROLLING_ANCIENT"
	end
	local goal = assignment and assignment.goal or "regroup"
	if goal == "defend_lane" and assignment.returning_to_lane == true then
		return "RETURNING_TO_LANE"
	end
	local states = {
		selecting_hero = "SELECTING_HERO",
		regroup = "REGROUPING",
		defend_lane = "DEFENDING_LANE",
		defend_phase2 = "DEFENDING_SIDE",
		defend_base = "DEFENDING_BASE",
		fight_boss = "FIGHTING_BOSS",
		investigate_boss = "SEARCHING_LAST_SEEN",
		participate_event = "PARTICIPATING_EVENT",
		shop = "SHOPPING",
		dead = "DEAD",
		hold = "HOLDING",
	}
	return states[goal] or "REGROUPING"
end

function XHSBotBrain:ActionState(action, assignment, target, encounter)
	if encounter ~= nil and encounter.id == "muradin_survival" then
		return "MURADIN_SURVIVAL"
	end
	if encounter ~= nil and encounter.arena_combat == true then
		return "ARENA_COMBAT"
	end
	if encounter ~= nil and encounter.farm == true then
		return "FARM_EVENT"
	end
	if action.id == "move_to_objective"
		and action.data ~= nil and action.data.objective == "rune" then
		return "COLLECTING_RUNE"
	end
	if action.id == "break_crate" then return "BREAKING_CRATE" end
	if action.id == "pickup_loot" then return "PICKING_UP_LOOT" end
	if assignment ~= nil and assignment.ancient_patrol == true
		and (
			action.id == "move_to_objective"
			or action.id == "attack_move"
			or action.id == "hold"
		) then
		return "PATROLLING_ANCIENT"
	end
	local states = {
		dead = "DEAD",
		wait = "DISABLED",
		evade_danger = "EVADING_DANGER",
		retreat = "RETREATING",
		reposition = "REPOSITIONING",
		move_to_last_seen = "SEARCHING_LAST_SEEN",
		hold = "HOLDING",
	}
	if action.id == "cast_ability" and action.data ~= nil
		and (action.data.mode == "ally_heal" or action.data.is_heal == true) then
		return "HEALING"
	end
	if action.id == "cast_ability" or action.id == "attack_target" then
		if assignment ~= nil and assignment.goal == "participate_event" then
			return "PARTICIPATING_EVENT"
		end
		if assignment ~= nil and assignment.goal == "fight_boss"
			or XHSBotConfig:IsBossTarget(target) then
			return "FIGHTING_BOSS"
		end
		return "FIGHTING_WAVE"
	end
	if action.id == "move_to_objective" or action.id == "attack_move" then
		return self:MacroState(assignment)
	end
	return states[action.id] or "THINKING"
end

function XHSBotBrain:Think(playerID, hero, record, assignment, difficulty)
	local startedAt = ClockSeconds()
	local function FinishDecision()
		self:EndQueryContext(hero)
		local elapsedMs = math.max(0, (ClockSeconds() - startedAt) * 1000)
		record.decision_ticks = (record.decision_ticks or 0) + 1
		record.decision_cost_total_ms = (record.decision_cost_total_ms or 0) + elapsedMs
		record.decision_cost_average_ms = record.decision_cost_total_ms / record.decision_ticks
		record.decision_cost_max_ms = math.max(record.decision_cost_max_ms or 0, elapsedMs)
	end

	if not IsValidEntityHandle(hero) then
		record.alive = false
		record.state = "SELECTING_HERO"
		record.macro_state = "SELECTING_HERO"
		FinishDecision()
		return
	end
	if not hero:IsAlive() then
		self:ReleaseRuneClaim(playerID, record)
		if record.alive ~= false then
			record.deaths = (tonumber(record.deaths) or 0) + 1
			record.last_death_at = GameRules:GetGameTime()
		end
		record.death_started_at = record.death_started_at or GameRules:GetGameTime()
		record.alive = false
		record.state = "DEAD"
		record.macro_state = "DEAD"
		record.target_entindex = nil
		record.pending_decision = nil
		record.pending_decision_signature = nil
		record.telemetry_last_health = hero:GetHealth()
		FinishDecision()
		return
	end
	record.alive = true
	self:BeginQueryContext(hero)
	local encounter = XHSBotEncounterDirector:Build(
		playerID,
		hero,
		record,
		assignment
	)
	local encounterID = encounter and encounter.id or ""
	if record.encounter_mode ~= encounterID then
		record.target_entindex = nil
		record.target_score = nil
		record.pending_decision = nil
		record.pending_decision_signature = nil
		record.pending_decision_at = nil
		record.encounter_transitions = (record.encounter_transitions or 0) + 1
	end
	record.encounter_mode = encounterID
	self:ThinkControlledUnits(hero, record, assignment, encounter)

	if encounter == nil and self:UpdateStuck(hero, record, assignment) then
		record.state = "STUCK_RECOVERY"
		record.macro_state = self:MacroState(assignment, encounter)
		FinishDecision()
		return
	end

	local profile = XHSBotHeroProfiles:Get(hero:GetUnitName())
	if profile == nil or profile.certified ~= true then
		record.state = "UNSUPPORTED_HERO"
		record.error = "No certified AI profile for " .. hero:GetUnitName()
		FinishDecision()
		return
	end

	local context = self:BuildContext(
		playerID,
		hero,
		profile,
		difficulty,
		record,
		assignment,
		encounter
	)
	local actions = XHSBotUtility:Build(context)
	local best = actions[1]
	if best == nil then
		FinishDecision()
		return
	end

	record.macro_state = self:MacroState(assignment, encounter)
	record.planned_state = self:ActionState(best, assignment, context.target, encounter)
	record.planned_decision = best.id
	record.planned_decision_reason = best.reason
	record.top_actions = {}
	for index = 1, math.min(3, #actions) do
		table.insert(record.top_actions, {
			id = actions[index].id,
			score = math.floor(actions[index].score * 10) / 10,
			reason = actions[index].reason,
		})
	end

	local signature = best.id
	if best.data ~= nil and best.data.ability ~= nil then
		signature = signature .. ":" .. best.data.ability:GetAbilityName()
	end
	if best.data ~= nil and best.data.target ~= nil then
		signature = signature .. ":" .. tostring(best.data.target:entindex())
	end
	if best.data ~= nil and best.data.position ~= nil and best.data.target == nil then
		signature = signature
			.. ":" .. tostring(math.floor(best.data.position.x / 100))
			.. ":" .. tostring(math.floor(best.data.position.y / 100))
	end
	if best.data ~= nil and best.data.desired_state ~= nil then
		signature = signature .. ":" .. tostring(best.data.desired_state)
	end

	local now = GameRules:GetGameTime()
	if record.pending_decision_signature ~= signature then
		record.pending_decision_signature = signature
		record.pending_decision = best
		record.pending_decision_at = now + RandomFloat(difficulty.reaction_min, difficulty.reaction_max)
		if XHSBotDecisionAudit ~= nil then
			XHSBotDecisionAudit:RecordDecision(
				playerID,
				"planned",
				best,
				record,
				assignment
			)
		end
		FinishDecision()
		return
	end
	-- Refresh handles/positions from the newly rebuilt context while preserving
	-- the original humanized reaction deadline for the same semantic action.
	record.pending_decision = best
	if now < (record.pending_decision_at or 0) then
		FinishDecision()
		return
	end

	local executed = XHSBotExecutor:Execute(
		hero,
		record.pending_decision,
		record,
		difficulty
	)
	if XHSBotDecisionAudit ~= nil then
		XHSBotDecisionAudit:RecordDecision(
			playerID,
			executed and "executed" or "rejected",
			best,
			record,
			assignment
		)
	end
	if executed then
		record.state = record.planned_state
		record.last_decision = best.id
		record.last_decision_reason = best.reason
		if best.id == "reposition" then
			-- Guarantee an attack/cast opportunity after every kite step. This
			-- hysteresis prevents Archmage and other ranged bots from spending
			-- an entire engagement in REPOSITIONING.
			record.next_reposition_at = now + 1.10
		end
		record.rune_committed = best.data ~= nil
			and best.data.objective == "rune"
		if best.id == "hold" then
			record.idle_seconds = (record.idle_seconds or 0) + difficulty.think_interval
		end
	end
	record.pending_decision = nil
	record.pending_decision_signature = nil
	record.pending_decision_at = nil
	FinishDecision()
end

return XHSBotBrain
