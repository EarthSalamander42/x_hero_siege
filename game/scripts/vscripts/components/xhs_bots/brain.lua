if XHSBotBrain == nil then
	XHSBotBrain = {}
end

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
	if delta:Length2D() <= 1 then return origin end
	return origin + delta:Normalized() * math.max(0, tonumber(distance) or 0)
end

local function Clamp(value, minimum, maximum)
	return math.max(minimum, math.min(maximum, tonumber(value) or minimum))
end

local function GetFortPosition()
	local fort = Entities:FindByName(nil, "dota_goodguys_fort")
		or Entities:FindByName(nil, "base_spawn")
	return IsValidEntityHandle(fort) and fort:GetAbsOrigin() or Vector(0, 0, 0)
end

local DEFENSIVE_STRUCTURE_NAMES = {
	npc_dota_defender_fort = true,
	npc_dota_holdout_tower = true,
	npc_tower_cold = true,
	npc_tower_death = true,
}

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

function XHSBotBrain:FindEnemies(hero, radius)
	return FindUnitsInRadius(
		hero:GetTeamNumber(),
		hero:GetAbsOrigin(),
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE
			+ DOTA_UNIT_TARGET_FLAG_NO_INVIS
			+ DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		FIND_CLOSEST,
		false
	)
end

function XHSBotBrain:IsCombatTarget(unit)
	if not IsValidEntityHandle(unit) or not unit:IsAlive() or unit:IsInvulnerable() then return false end
	local name = unit:GetUnitName()
	if name == "npc_dota_crate"
		or name == "npc_dota_chest"
		or name == "npc_dota_vase"
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
		or assignment.goal == "dead" or assignment.goal == "shop" then
		return false
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

function XHSBotBrain:RememberVisibleTarget(record, target, difficulty, now)
	if not self:IsCombatTarget(target) then return end
	now = tonumber(now) or GameRules:GetGameTime()
	record.last_seen_position = CopyPosition(target:GetAbsOrigin())
	record.last_seen_at = now
	record.last_seen_until = now + (tonumber(difficulty.target_memory_duration) or 1)
end

function XHSBotBrain:SelectTarget(playerID, hero, profile, record, assignment, difficulty, visibleEnemies)
	local now = GameRules:GetGameTime()
	local committed = EntityFromIndex(record.target_entindex)
	if self:IsCombatTarget(committed)
		and now < (record.target_committed_until or 0)
		and self:IsTeamVisible(hero, committed)
		and self:IsTargetAllowedByAssignment(playerID, hero, committed, assignment, difficulty) then
		self:RememberVisibleTarget(record, committed, difficulty, now)
		return committed, record.target_score or 0
	end

	if assignment ~= nil and assignment.target_entindex ~= nil then
		local assignedTarget = EntityFromIndex(assignment.target_entindex)
		if self:IsCombatTarget(assignedTarget)
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

function XHSBotBrain:GetAllies(hero, radius)
	return FindUnitsInRadius(
		hero:GetTeamNumber(),
		hero:GetAbsOrigin(),
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_HERO,
		DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS,
		FIND_ANY_ORDER,
		false
	)
end

function XHSBotBrain:GetNearbyFriendlyCover(hero, radius)
	return FindUnitsInRadius(
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

function XHSBotBrain:IsOwnedScreenUnit(hero, unit)
	if not IsValidEntityHandle(unit) or unit == hero or not unit:IsAlive()
		or unit.IsRealHero ~= nil and unit:IsRealHero() then
		return false
	end
	if unit.furbolg_parent == hero
		or unit.HasModifier ~= nil
			and unit:HasModifier("modifier_orb_of_darkness_controlled") then
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

function XHSBotBrain:ComputeCombatThreat(hero, enemies, record)
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
	local threat = Clamp(
		pressure
			+ math.min(0.55, recentDamageRate * 2.4)
			+ isolation
			- supportReduction,
		0,
		1.5
	)
	record.combat_threat = threat
	record.recent_damage_ratio = recentDamageRatio
	record.close_enemy_count = closeEnemies
	record.focused_by_count = focusedBy
	record.nearby_screen_count = ownedScreens
	record.boss_threat_nearby = bossNearby
	return {
		score = threat,
		recent_damage_ratio = recentDamageRatio,
		recent_damage_rate = recentDamageRate,
		close_enemies = closeEnemies,
		focused_by = focusedBy,
		allied_heroes = alliedHeroes,
		owned_screens = ownedScreens,
		boss_nearby = bossNearby,
	}
end

function XHSBotBrain:GetRetreatPosition(hero, target, assignment, threat)
	local heroOrigin = hero:GetAbsOrigin()
	if self:IsCombatTarget(target) then
		local bestUnit = nil
		local bestScore = -math.huge
		for _, ally in pairs(self:GetNearbyFriendlyCover(hero, 1050)) do
			if IsValidEntityHandle(ally) and ally ~= hero and ally:IsAlive() then
				local isScreen = self:IsOwnedScreenUnit(hero, ally)
				local isHero = ally.IsRealHero ~= nil and ally:IsRealHero()
				if isScreen or isHero then
					local score = (isScreen and 250 or 100)
						- Distance2D(heroOrigin, ally:GetAbsOrigin()) * 0.12
					if score > bestScore then
						bestScore = score
						bestUnit = ally
					end
				end
			end
		end
		if bestUnit ~= nil then
			local away = bestUnit:GetAbsOrigin() - target:GetAbsOrigin()
			away.z = 0
			if away:Length2D() > 1 then
				local behindCover = bestUnit:GetAbsOrigin() + away:Normalized() * 170
				if GridNav == nil or GridNav.CanFindPath == nil
					or GridNav:CanFindPath(heroOrigin, behindCover) then
					return behindCover, self:IsOwnedScreenUnit(hero, bestUnit)
						and "owned summon screen" or "ally screen"
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
		GetFortPosition(),
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
	if ability:GetLevel() <= 0 or ability:IsPassive() or not ability:IsActivated() then
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
	local emergencySelfHeal = (rule.mode == "ally_heal" or rule.healing == true)
		and (rule.include_self ~= false or rule.heals_caster == true)
		and HealthRatio(hero) <= (tonumber(rule.self_save_threshold) or 0.40)
	if not emergencySelfHeal
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
		if XHSBotConfig:IsBossTarget(target) and rule.prefer_boss then action.score = action.score + 12 end
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
		local nearby = self:CountEnemiesAround(enemies, hero:GetAbsOrigin(), rule.radius or 450)
		if nearby < (rule.minimum_targets or 1)
			and not XHSBotConfig:IsBossTarget(target) then return nil end
		action.score = action.score + math.min(15, nearby * 3)
		action.reason = tostring(nearby) .. " nearby enemies"
	elseif mode == "no_target_mixed" then
		local nearby = self:CountEnemiesAround(enemies, hero:GetAbsOrigin(), rule.radius or 550)
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
		if not self:IsCombatTarget(target) then return nil end
		local range = self:GetAbilityRange(hero, ability, target)
		if Distance2D(hero:GetAbsOrigin(), target:GetAbsOrigin()) > range then return nil end
		local nearby = self:CountEnemiesAround(enemies, target:GetAbsOrigin(), rule.radius or 325)
		if nearby < (rule.minimum_targets or 1)
			and not XHSBotConfig:IsBossTarget(target) then return nil end
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
		local nearby = self:CountEnemiesAround(enemies, targetOrigin, rule.radius or 425)
		if nearby < (rule.minimum_targets or 1)
			and not XHSBotConfig:IsBossTarget(target) then return nil end
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
		action.desired_state = target ~= nil and #enemies < 3 and manaReady
		action.score = ability:GetToggleState() == action.desired_state
			and 0 or math.max(action.score, tonumber(rule.state_change_floor) or 87)
	elseif mode == "toggle_aoe" then
		local manaReady = rule.mana_gate == false
			or ManaRatio(hero) > (tonumber(rule.mana_threshold) or 0.20)
		action.desired_state = target ~= nil and #enemies >= (rule.minimum_targets or 3) and manaReady
		action.score = ability:GetToggleState() == action.desired_state
			and 0 or math.max(action.score, tonumber(rule.state_change_floor) or 87)
	elseif mode == "defensive_toggle" then
		action.desired_state = target ~= nil or HealthRatio(hero) < 0.65
		action.score = ability:GetToggleState() == action.desired_state
			and 0 or math.max(action.score, tonumber(rule.state_change_floor) or 87)
	elseif mode == "autocast_attack" then
		local manaReady = ManaRatio(hero) >= (tonumber(rule.mana_threshold) or 0.20)
		action.desired_state = target ~= nil and manaReady
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
	local manaReady = ManaRatio(hero) >= (tonumber(rule.minimum_mana_ratio) or 0.18)
	local desiredMode = nil
	local nearbyTargetCount = 0
	if targetIsValid and manaReady then
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
	end

	local now = GameRules:GetGameTime()
	if desiredMode ~= nil
		and activeMode ~= nil
		and desiredMode ~= activeMode
		and not XHSBotConfig:IsBossTarget(target)
		and now < (record.rifle_attack_mode_hold_until or 0) then
		desiredMode = activeMode
	end

	local desiredAbility = desiredMode == "cleave" and cleaveAbility
		or desiredMode == "single" and singleAbility
		or nil
	if desiredAbility == nil and desiredMode ~= nil then
		desiredMode = nil
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
			+ (tonumber(rule.minimum_mode_duration) or 1.35)
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

function XHSBotBrain:GetRepositionPosition(hero, target, profile, anchor)
	if not self:IsCombatTarget(target) then return anchor end
	local away = hero:GetAbsOrigin() - target:GetAbsOrigin()
	away.z = 0
	if away:Length2D() <= 1 then away = RandomVector(1) end
	local position = hero:GetAbsOrigin() + away:Normalized() * math.max(220, profile.safety_distance)

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
	if record.stuck_sample_position == nil then
		record.stuck_sample_position = position
		record.stuck_sample_at = now
		return false
	end
	if now - (record.stuck_sample_at or 0) < 1.5 then return false end

	local moved = Distance2D(position, record.stuck_sample_position)
	local anchor = assignment and assignment.anchor
	local needsMovement = anchor ~= nil and Distance2D(position, anchor) > 450
	record.stuck_sample_position = position
	record.stuck_sample_at = now

	if moved >= 55 or not needsMovement or hero:IsAttacking() then
		record.stuck_since = nil
		return false
	end

	record.stuck_since = record.stuck_since or now
	if now - record.stuck_since < 3 then return false end

	record.stuck_since = now
	record.stuck_recoveries = (record.stuck_recoveries or 0) + 1
	local recovery = position + RandomVector(220 + math.min(300, record.stuck_recoveries * 40))
	XHSBotExecutor:Move(hero, recovery, record, "stuck recovery", 0)
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
	local target = encounter and encounter.forced_target or nil
	local targetScore = target ~= nil and 120 or nil
	if target == nil and (encounter == nil or encounter.no_combat ~= true) then
		target, targetScore = self:SelectTarget(
			playerID,
			hero,
			profile,
			record,
			assignment,
			difficulty,
			enemies
		)
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
	local danger, dangerEntries = XHSBotDangerRegistry:GetDangerAt(
		hero:GetAbsOrigin(),
		now,
		difficulty.danger_reaction_lead
	)
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
	local assignmentGoal = assignment and assignment.goal or "regroup"
	local threat = self:ComputeCombatThreat(hero, enemies, record)
	local defensiveCover, defensiveCoverDistance = self:GetDefensiveStructureCover(hero, 950)
	local lastStand = defensiveCover ~= nil and target ~= nil
	local retreatPosition, retreatCover = self:GetRetreatPosition(
		hero,
		target,
		assignment,
		threat
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
			+ (threat.focused_by >= 2 and 0.04 or 0),
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
	return {
		alive = hero:IsAlive(),
		disabled = hero:IsStunned()
			or hero:IsHexed()
			or (hero.IsCommandRestricted ~= nil and hero:IsCommandRestricted()),
		health_ratio = HealthRatio(hero),
		retreat_threshold = dynamicRetreatThreshold,
		retreat_position = retreatPosition,
		retreat_cover = retreatCover,
		last_stand = lastStand,
		defensive_cover = defensiveCover,
		defensive_cover_distance = defensiveCoverDistance,
		combat_threat = threat.score,
		recent_damage_ratio = threat.recent_damage_ratio,
		focused_by = threat.focused_by,
		close_enemies = threat.close_enemies,
		danger = danger,
		danger_entries = dangerEntries,
		safe_position = safePosition,
		channel_interrupt_danger = difficulty.channel_interrupt_danger,
		target = target,
		target_priority = math.min(20, math.max(0, targetScore or 0) * 0.2),
		too_close = (encounter == nil or encounter.no_reposition ~= true)
			and not lastStand and targetDistance ~= nil
			and profile.preferred_range >= 450
			and targetDistance < profile.safety_distance,
		reposition_position = self:GetRepositionPosition(hero, target, profile, anchor),
		ability_actions = abilityActions,
		anchor = anchor,
		anchor_distance = Distance2D(hero:GetAbsOrigin(), anchor),
		assignment_urgency = assignment and assignment.urgency or 0,
		shopping = assignmentGoal == "shop",
		shopping_urgent = assignmentGoal == "shop"
			and assignment.shopping_urgent == true,
		returning_to_lane = returningToLane,
		max_chase_distance = encounter and encounter.max_chase_distance
			or assignment and assignment.chase_radius
			or difficulty.max_chase_distance,
		last_seen_position = target == nil and record.last_seen_position or nil,
		attack_move = target == nil and mayAttackMove and record.use_attack_move == true,
		encounter_mode = encounter and encounter.id or nil,
		arena_combat = encounter and encounter.arena_combat == true,
		encounter_no_combat = encounter and encounter.no_combat == true,
		encounter_reached_distance = encounter and encounter.reached_distance or 180,
		no_retreat = encounter and encounter.no_retreat == true,
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
	record.state = self:ActionState(best, assignment, context.target, encounter)
	record.last_decision = best.id
	record.last_decision_reason = best.reason
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

	if XHSBotExecutor:Execute(hero, record.pending_decision, record, difficulty) then
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
