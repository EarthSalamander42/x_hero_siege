if XHSBotEconomy == nil then
	XHSBotEconomy = {}
end

-- libraries/gold.lua mirrors at most this amount into Dota's native wallet.
-- Any bot transaction must update both wallets or Gold:Think() will restore
-- a custom balance that was debited while the native wallet stayed capped.
XHSBotEconomy.ENGINE_GOLD_CAP = 50000
XHSBotEconomy.ACTIVE_LAST_SLOT = 5
XHSBotEconomy.INVENTORY_LAST_SLOT = 8
XHSBotEconomy.STASH_FIRST_SLOT = 9
XHSBotEconomy.STASH_LAST_SLOT = 14
XHSBotEconomy.STASH_CAPACITY = 6
XHSBotEconomy.STASH_COLLECTION_THRESHOLD = 4
XHSBotEconomy.SCAN_LAST_SLOT = XHSBotEconomy.STASH_LAST_SLOT
XHSBotEconomy.ANKH_ITEM_NAME = "item_ankh_of_reincarnation"
XHSBotEconomy.DARKNESS_MINIMUM_GAME_TIME = 8 * 60
XHSBotEconomy.DARKNESS_LOW_THREAT_HOLD = 24
XHSBotEconomy.DARKNESS_HIGH_THREAT_HOLD = 4
XHSBotEconomy.DARKNESS_TOGGLE_COOLDOWN = 12
XHSBotEconomy.DARKNESS_LOW_THREAT = 0.28
XHSBotEconomy.DARKNESS_HIGH_THREAT = 0.85
XHSBotEconomy.BASE_SHOP_RADIUS = 1200
XHSBotEconomy.LANE_SHOP_RADIUS = 900
XHSBotEconomy.SECRET_SHOP_RADIUS = 900
-- Some XHS shop triggers report DOTA_SHOP_HOME even at castle_shop. Keep a
-- wider exclusion buffer than the purchase radius so general items can never
-- be granted while a bot is entering or leaving the secret shop.
XHSBotEconomy.SECRET_SHOP_EXCLUSION_RADIUS = 1300

local DARKNESS_ITEMS = {
	item_orb_of_darkness = true,
	item_orb_of_darkness2 = true,
	item_bracer_of_the_void = true,
}
local DARKNESS_ACTIVE_MODIFIER = "modifier_orb_of_darkness_active"
local DARKNESS_COMBAT_ENCOUNTERS = {
	ramero_baristol = true,
	sogat = true,
	phase_2 = true,
	phase_3_vanguard = true,
	phase_3 = true,
}
local GENERAL_SHOP_CLASSNAMES = {
	"ent_dota_shop",
	"dota_item_shop",
	"trigger_shop",
}

local function IsValidEntityHandle(entity)
	return entity ~= nil and IsValidEntity(entity) and not entity:IsNull()
end

local function IsCastable(item)
	return IsValidEntityHandle(item)
		and item:IsFullyCastable()
		and item:IsCooldownReady()
end

local function ItemName(item)
	if not IsValidEntityHandle(item) then return nil end
	if item.GetAbilityName ~= nil then return item:GetAbilityName() end
	return item.GetName ~= nil and item:GetName() or nil
end

local function AbilitySpecialValue(ability, key)
	if not IsValidEntityHandle(ability) or type(key) ~= "string"
		or key == "" or ability.GetSpecialValueFor == nil then return 0 end
	local ok, value = pcall(function() return ability:GetSpecialValueFor(key) end)
	return ok and math.max(0, tonumber(value) or 0) or 0
end

local function AbilityCastPoint(ability)
	if not IsValidEntityHandle(ability) or ability.GetCastPoint == nil then return 0 end
	local ok, value = pcall(function() return ability:GetCastPoint() end)
	return ok and math.max(0, tonumber(value) or 0) or 0
end

local function GetFort()
	return Entities:FindByName(nil, "dota_goodguys_fort")
		or Entities:FindByName(nil, "base_spawn")
end

local function CopyPosition(position)
	if position == nil then return nil end
	return Vector(position.x, position.y, position.z or 0)
end

function XHSBotEconomy:CastNamedActiveItem(hero, name, action, record)
	if not IsValidEntityHandle(hero) or not hero:IsAlive() then return false end
	name = tostring(name or "")
	if name == "" then return false end
	for slot = 0, self.ACTIVE_LAST_SLOT do
		local item = hero:GetItemInSlot(slot)
		if ItemName(item) == name and IsCastable(item) then
			local request = {}
			for key, value in pairs(action or {}) do request[key] = value end
			request.ability = item
			if XHSBotExecutor:Cast(hero, request, record, 0) then
				record.last_item_action = "use:" .. name
				return true
			end
		end
	end
	return false
end

function XHSBotEconomy:TryUpgradeAbility(hero, ability)
	if not IsValidEntityHandle(ability)
		or ability:GetAbilityName() == "attribute_bonus"
		or ability:GetLevel() >= ability:GetMaxLevel()
		or ability:IsHidden() then
		return false
	end
	if ability.CanAbilityBeUpgraded == nil then return false end
	local canCheck, upgradeResult = pcall(function()
		return ability:CanAbilityBeUpgraded()
	end)
	if not canCheck or upgradeResult ~= (ABILITY_CAN_BE_UPGRADED or 0) then
		return false
	end
	local before = hero:GetAbilityPoints()
	local ok = pcall(function() hero:UpgradeAbility(ability) end)
	return ok and hero:GetAbilityPoints() < before
end

function XHSBotEconomy:SpendAbilityPoints(hero, profile)
	if not IsValidEntityHandle(hero) or hero:GetAbilityPoints() <= 0 then return 0 end

	local spent = 0
	local safety = 0
	while hero:GetAbilityPoints() > 0 and safety < 32 do
		safety = safety + 1
		local upgraded = false

		-- This is a measured priority list, not a blind forced level-up: an
		-- ultimate is attempted first at every level, then skipped until legal.
		for _, abilityName in ipairs(profile and profile.skill_build or {}) do
			local ability = hero:FindAbilityByName(abilityName)
			if self:TryUpgradeAbility(hero, ability) then
				spent = spent + 1
				upgraded = true
				break
			end
		end

		-- Unknown replacements and future hero changes retain a safe slot-order
		-- fallback instead of leaving points permanently unspent.
		for abilityIndex = 0, 23 do
			if upgraded then break end
			local ability = hero:GetAbilityByIndex(abilityIndex)
			if self:TryUpgradeAbility(hero, ability) then
				spent = spent + 1
				upgraded = true
				break
			end
		end

		if not upgraded then break end
	end
	return spent
end

function XHSBotEconomy:GetReadySelfHealCandidate(hero, profile)
	local best = nil
	local maximumHealth = math.max(1, hero:GetMaxHealth())
	local missingHealth = math.max(0, maximumHealth - hero:GetHealth())
	for abilityName, rule in pairs(profile and profile.abilities or {}) do
		local canHealSelf = rule.mode == "ally_heal" and rule.include_self ~= false
			or rule.healing == true and rule.heals_caster == true
		local ability = canHealSelf and hero:FindAbilityByName(abilityName) or nil
		if IsValidEntityHandle(ability)
			and ability:GetLevel() > 0
			and not ability:IsPassive()
			and ability:IsActivated()
			and ability:IsFullyCastable() then
			local estimated = AbilitySpecialValue(ability, rule.heal_flat_key)
				+ maximumHealth * AbilitySpecialValue(
					ability,
					rule.heal_percent_key
				) / 100
			local effective = math.min(missingHealth, estimated)
			local selfSaveThreshold = tonumber(rule.self_save_threshold) or 0.40
			if effective > 0
				and hero:GetHealth() / maximumHealth <= selfSaveThreshold
				and (best == nil or effective > best.effective_heal) then
				best = {
					ability = ability,
					name = abilityName,
					estimated_heal = estimated,
					effective_heal = effective,
					cast_point = AbilityCastPoint(ability),
					self_save_threshold = selfSaveThreshold,
				}
			end
		end
	end
	return best
end

function XHSBotEconomy:ShouldUseHealthPotionFirst(hero, potion, profile, record, difficulty)
	local maximumHealth = math.max(1, hero:GetMaxHealth())
	local missingHealth = math.max(0, maximumHealth - hero:GetHealth())
	local potionHeal = AbilitySpecialValue(potion, "hp_restore")
	local potionEffective = math.min(missingHealth, potionHeal)
	local spell = self:GetReadySelfHealCandidate(hero, profile)
	if spell == nil or potionEffective <= 0 then return true, nil end
	if record.was_in_active_danger == true then return true, spell end

	-- Instant recovery wins by default. A zero-cast spell may replace it when
	-- it is materially stronger; a cast-time spell needs a much larger payoff
	-- and enough projected health to actually finish the cast.
	if spell.cast_point <= 0.05 then
		return spell.effective_heal < potionEffective * 1.20, spell
	end

	local payoffRatio = spell.effective_heal / math.max(1, potionEffective)
	if payoffRatio < 2.50 then return true, spell end
	local recentDamagePerSecond = maximumHealth
		* (tonumber(record.recent_damage_ratio) or 0)
		/ math.max(0.10, tonumber(difficulty.think_interval) or 0.28)
	local projectedHealth = hero:GetHealth()
		- recentDamagePerSecond * (spell.cast_point + 0.15)
	local threat = tonumber(record.combat_threat) or 0
	local focusedBy = tonumber(record.focused_by_count) or 0
	local safeToFinish = projectedHealth > maximumHealth * 0.06
		and (threat < 1.25 or payoffRatio >= 4.0)
		and (focusedBy < 2 or spell.cast_point <= 0.50 or payoffRatio >= 4.0)
	return not safeToFinish, spell
end

function XHSBotEconomy:UseConsumables(hero, record, difficulty, profile, encounter)
	if not IsValidEntityHandle(hero) or not hero:IsAlive() then return false end

	local healthRatio = hero:GetHealth() / math.max(1, hero:GetMaxHealth())
	local manaRatio = hero:GetMana() / math.max(1, hero:GetMaxMana())
	local noCombatEncounter = encounter ~= nil and encounter.no_combat == true
	for slot = 0, self.ACTIVE_LAST_SLOT do
		local item = hero:GetItemInSlot(slot)
		if IsCastable(item) then
			local name = ItemName(item)
			local shouldUse = name == "item_health_potion"
				and healthRatio <= (difficulty.health_potion_threshold or 0.42)
				or not noCombatEncounter
				and name == "item_mana_potion"
				and manaRatio <= (difficulty.mana_potion_threshold or 0.30)
			if shouldUse and name == "item_health_potion" then
				local usePotionFirst, spell = self:ShouldUseHealthPotionFirst(
					hero,
					item,
					profile,
					record,
					difficulty
				)
				if not usePotionFirst then
					record.potions_deferred_for_heal = (record.potions_deferred_for_heal or 0) + 1
					record.preferred_heal_spell = spell and spell.name or ""
					record.defer_potion_for_spell_now = true
					record.last_item_action = "defer_potion_for:"
						.. tostring(record.preferred_heal_spell)
					return false
				end
			end
			if shouldUse and XHSBotExecutor:Cast(hero, {
				ability = item,
				mode = "no_target",
				reason = name == "item_health_potion"
					and "health potion threshold"
					or "mana potion threshold",
			}, record, 0) then
				record.consumables_used = (record.consumables_used or 0) + 1
				record.preferred_heal_spell = ""
				record.last_item_action = "use:" .. name
				if name == "item_health_potion" then
					local chargesBefore = item.GetCurrentCharges ~= nil
						and math.max(0, tonumber(item:GetCurrentCharges()) or 0)
						or 0
					if chargesBefore <= 1 then
						-- Do not wait for the next 1.5-2.75 second economy tick
						-- after consuming the final charge. The retreat route is
						-- armed on the same tick as the successful cast order.
						self:ScheduleEmergencyHealthResupply(
							hero,
							record,
							difficulty,
							"final health potion consumed"
						)
					end
				end
				return true
			end
		end
	end
	return false
end

function XHSBotEconomy:UseEmergencyTacticalItems(hero, record)
	if not IsValidEntityHandle(hero) or not hero:IsAlive() then return false end
	local maximumHealth = math.max(1, hero:GetMaxHealth())
	local healthRatio = hero:GetHealth() / maximumHealth
	local threat = math.max(0, tonumber(record.combat_threat) or 0)
	local focused = math.max(0, tonumber(record.focused_by_count) or 0)
	local recentDamage = math.max(0, tonumber(record.recent_damage_ratio) or 0)
	local magicalThreat = math.max(0, tonumber(record.magical_threat) or 0)
	local fatalPressure = healthRatio <= 0.24
		and (threat >= 0.88 or focused >= 2 or recentDamage >= 0.20)
	local severePressure = healthRatio <= 0.32
		and (threat >= 0.78 or focused >= 2 or recentDamage >= 0.16)
	local magicalCrisis = healthRatio <= 0.36
		and magicalThreat >= 0.72
		and (threat >= 0.70 or focused >= 1)

	local function Use(name, reason)
		if self:CastNamedActiveItem(hero, name, {
			mode = "no_target",
			reason = reason,
		}, record) then
			record.emergency_item_uses = (record.emergency_item_uses or 0) + 1
			return true
		end
		return false
	end

	if fatalPressure and Use(
		"item_potion_of_invulnerability",
		"fatal pressure immunity before maintenance"
	) then
		return true
	end
	if severePressure
		and maximumHealth >= 9000
		and Use(
			"item_potion_full",
			"fatal pressure instant restoration before maintenance"
		) then
		return true
	end
	if magicalCrisis and Use(
		"item_potion_of_antimagic",
		"fatal magical pressure before maintenance"
	) then
		return true
	end
	return false
end

function XHSBotEconomy:HasOwnedFurbolg(hero)
	local units = FindUnitsInRadius(
		hero:GetTeamNumber(),
		hero:GetAbsOrigin(),
		nil,
		FIND_UNITS_EVERYWHERE,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE or 0,
		FIND_ANY_ORDER,
		false
	)
	for _, unit in pairs(units) do
		if IsValidEntityHandle(unit) and unit:IsAlive() and unit.furbolg_parent == hero then
			return true
		end
	end
	return false
end

function XHSBotEconomy:FindDarknessOrb(hero)
	if not IsValidEntityHandle(hero) then return nil end
	for slot = 0, self.ACTIVE_LAST_SLOT do
		local item = hero:GetItemInSlot(slot)
		if DARKNESS_ITEMS[ItemName(item)] then return item end
	end
	return nil
end

function XHSBotEconomy:IsDarknessPowerReady(hero, record, now)
	if not IsValidEntityHandle(hero) then return false end
	now = tonumber(now) or GameRules:GetGameTime()
	local level = hero.GetLevel ~= nil and hero:GetLevel() or 0
	local maximumHealth = hero.GetMaxHealth ~= nil and hero:GetMaxHealth() or 0
	local attackDamage = 0
	if hero.GetAttackDamage ~= nil then
		local ok, value = pcall(function() return hero:GetAttackDamage() end)
		if ok then attackDamage = math.max(0, tonumber(value) or 0) end
	end
	local itemGold = math.max(0, tonumber(record.item_gold_spent) or 0)
	local tomes = math.max(0, tonumber(record.tomes_bought) or 0)
	local hasVoidBracer = false
	for slot = 0, self.ACTIVE_LAST_SLOT do
		hasVoidBracer = hasVoidBracer
			or ItemName(hero:GetItemInSlot(slot)) == "item_bracer_of_the_void"
	end
	local progressed = hasVoidBracer or itemGold >= 80000 or tomes >= 4
	local independentlyStrong = maximumHealth >= 11000 or attackDamage >= 650

	record.darkness_power_level = level
	record.darkness_power_health = maximumHealth
	record.darkness_power_damage = math.floor(attackDamage)
	return now >= self.DARKNESS_MINIMUM_GAME_TIME
		and level >= 12
		and progressed
		and independentlyStrong
end

function XHSBotEconomy:GetDarknessThreatState(hero, record)
	local healthRatio = hero:GetHealth() / math.max(1, hero:GetMaxHealth())
	local combatThreat = math.max(0, tonumber(record.combat_threat) or 0)
	local baseThreat = math.max(0, tonumber(record.base_threat_score) or 0)
	local assignmentUrgency = math.max(0, tonumber(record.assignment_urgency) or 0)
	local recentDamage = math.max(0, tonumber(record.recent_damage_ratio) or 0)
	local focusedBy = math.max(0, tonumber(record.focused_by_count) or 0)
	local encounter = tostring(record.encounter_mode or "")

	local high = record.base_threat_active == true
		or record.boss_threat_nearby == true
		or DARKNESS_COMBAT_ENCOUNTERS[encounter] == true
		or combatThreat >= self.DARKNESS_HIGH_THREAT
		or baseThreat >= 0.58
		or assignmentUrgency >= 0.85
		or recentDamage >= 0.10
		or focusedBy >= 2
		or healthRatio <= 0.45
	if high then return "high" end

	local low = combatThreat <= self.DARKNESS_LOW_THREAT
		and baseThreat <= 0.15
		and assignmentUrgency <= 0.55
		and recentDamage <= 0.025
		and focusedBy == 0
		and healthRatio >= 0.72
		and encounter ~= "muradin_survival"
	if low then return "low" end
	return "medium"
end

function XHSBotEconomy:UpdateDarknessOrb(hero, record)
	local orb = self:FindDarknessOrb(hero)
	if not IsValidEntityHandle(orb) then
		record.darkness_orb_active = false
		record.darkness_policy_state = "unavailable"
		record.darkness_low_threat_since = nil
		record.darkness_high_threat_since = nil
		return false
	end

	local now = GameRules:GetGameTime()
	local active = hero:HasModifier(DARKNESS_ACTIVE_MODIFIER)
	local powerReady = self:IsDarknessPowerReady(hero, record, now)
	local threatState = self:GetDarknessThreatState(hero, record)
	local playerID = math.max(0, tonumber(record.player_id)
		or tonumber(hero:GetPlayerID()) or 0)

	if threatState == "low" then
		record.darkness_low_threat_since = record.darkness_low_threat_since or now
		record.darkness_high_threat_since = nil
	elseif threatState == "high" then
		record.darkness_high_threat_since = record.darkness_high_threat_since or now
		record.darkness_low_threat_since = nil
	else
		record.darkness_low_threat_since = nil
		record.darkness_high_threat_since = nil
	end

	local lowSeconds = record.darkness_low_threat_since ~= nil
		and math.max(0, now - record.darkness_low_threat_since) or 0
	local highSeconds = record.darkness_high_threat_since ~= nil
		and math.max(0, now - record.darkness_high_threat_since) or 0
	local cooldownReady = now - (tonumber(record.darkness_last_toggle_at) or -math.huge)
		>= self.DARKNESS_TOGGLE_COOLDOWN
	local disableHold = self.DARKNESS_LOW_THREAT_HOLD + playerID % 5 * 1.5
	local enableHold = self.DARKNESS_HIGH_THREAT_HOLD + playerID % 3 * 0.4
	local desiredActive = active

	if active and powerReady and threatState == "low"
		and lowSeconds >= disableHold then
		desiredActive = false
	elseif not active and (
		not powerReady
		or threatState == "high" and highSeconds >= enableHold
	) then
		desiredActive = true
	end

	record.darkness_orb_active = active
	record.darkness_power_ready = powerReady
	record.darkness_threat_state = threatState
	record.darkness_low_threat_seconds = math.floor(lowSeconds * 10) / 10
	record.darkness_high_threat_seconds = math.floor(highSeconds * 10) / 10
	record.darkness_policy_state = active and "active" or "suppressed"

	if desiredActive == active or not cooldownReady or not IsCastable(orb) then
		return false
	end

	local reason = desiredActive
		and "reactivate darkness after sustained high threat"
		or "suppress darkness summons after sustained low threat"
	if not XHSBotExecutor:Cast(hero, {
		ability = orb,
		mode = "no_target",
		reason = reason,
	}, record, 0) then
		return false
	end

	local activeAfter = hero:HasModifier(DARKNESS_ACTIVE_MODIFIER)
	if activeAfter ~= desiredActive then
		record.last_item_rejection = "darkness toggle state did not change"
		return false
	end
	record.darkness_orb_active = activeAfter
	record.darkness_policy_state = activeAfter and "active" or "suppressed"
	record.darkness_last_toggle_at = now
	record.darkness_toggle_count = (record.darkness_toggle_count or 0) + 1
	record.last_item_action = (activeAfter and "activate:" or "deactivate:")
		.. tostring(ItemName(orb))
	return true
end

function XHSBotEconomy:EnsureCoreOrbStates(hero, record)
	if not IsValidEntityHandle(hero) or not hero:IsAlive() then return false end
	record.orb_toggle_retry_after = record.orb_toggle_retry_after or {}
	local now = GameRules:GetGameTime()
	local families = {}
	local seen = {}
	for slot = 0, self.ACTIVE_LAST_SLOT do
		local item = hero:GetItemInSlot(slot)
		local catalog = XHSBotItemCatalog:Get(ItemName(item))
		local familyName = catalog and tostring(catalog.family or "") or ""
		if familyName ~= "" and not seen[familyName] then
			seen[familyName] = true
			table.insert(families, {
				name = familyName,
				item = item,
				catalog = catalog,
			})
		end
	end

	local activeCount = 0
	local repairPending = {}
	for _, state in ipairs(families) do
		local modifierName = tostring(state.catalog.active_modifier or "")
		local active = modifierName ~= "" and hero:HasModifier(modifierName)
		if active then activeCount = activeCount + 1 end
		if state.catalog.default_active == true
			and state.catalog.toggle_policy == "always_on"
			and not active then
			table.insert(repairPending, state.name)
		end
	end
	record.orb_owned_family_count = #families
	record.orb_active_family_count = activeCount
	record.orb_repair_pending_count = #repairPending

	for _, state in ipairs(families) do
		local modifierName = tostring(state.catalog.active_modifier or "")
		local active = modifierName ~= "" and hero:HasModifier(modifierName)
		if state.catalog.default_active == true
			and state.catalog.toggle_policy == "always_on"
			and not active
			and now >= (tonumber(record.orb_toggle_retry_after[state.name]) or 0)
			and IsCastable(state.item) then
			record.orb_toggle_retry_after[state.name] = now + 3
			if XHSBotExecutor:Cast(hero, {
				ability = state.item,
				mode = "no_target",
				reason = "repair inactive " .. state.name .. " orb",
			}, record, 0) then
				record.orb_toggle_repair_count =
					(record.orb_toggle_repair_count or 0) + 1
				record.last_item_action = "repair_orb:" .. state.name
				return true
			end
		end
	end
	return false
end

function XHSBotEconomy:UseTacticalItems(hero, record, encounter)
	if not IsValidEntityHandle(hero) or not hero:IsAlive() then return false end
	if encounter ~= nil and encounter.no_combat == true then return false end

	local healthRatio = hero:GetHealth() / math.max(1, hero:GetMaxHealth())
	local manaRatio = hero:GetMana() / math.max(1, hero:GetMaxMana())
	local threat = math.max(0, tonumber(record.combat_threat) or 0)
	local baseThreat = math.max(0, tonumber(record.base_threat_score) or 0)
	local target = nil
	if record.target_entindex ~= nil and EntIndexToHScript ~= nil then
		pcall(function()
			target = EntIndexToHScript(record.target_entindex)
		end)
	end

	if healthRatio <= 0.55 or manaRatio <= 0.12 then
		if self:CastNamedActiveItem(hero, "item_potion_full", {
			mode = "no_target",
			reason = "high-value instant full restoration",
		}, record) then return true end
	end
	if (tonumber(record.magical_threat) or 0) >= 0.68
		and (threat >= 0.78 or healthRatio <= 0.48) then
		if self:CastNamedActiveItem(hero, "item_potion_of_antimagic", {
			mode = "no_target",
			reason = "measured magical pressure",
		}, record) then return true end
	end
	if (baseThreat >= 0.55 or threat >= 0.82) and healthRatio <= 0.82 then
		local hasNearbyWard = false
		for _, wardName in ipairs({ "healing_ward", "healing_ward2" }) do
			for _, ward in pairs(Entities:FindAllByName(wardName)) do
				if IsValidEntityHandle(ward)
					and ward:GetTeamNumber() == hero:GetTeamNumber()
					and (ward:GetAbsOrigin() - hero:GetAbsOrigin()):Length2D() <= 700 then
					hasNearbyWard = true
					break
				end
			end
			if hasNearbyWard then break end
		end
		if not hasNearbyWard then
			if self:CastNamedActiveItem(hero, "item_healing_wards2", {
				mode = "point_aoe",
				position = hero:GetAbsOrigin(),
				reason = "greater sustain pressured team position",
			}, record) then return true end
			if self:CastNamedActiveItem(hero, "item_healing_wards", {
				mode = "point_aoe",
				position = hero:GetAbsOrigin(),
				reason = "sustain pressured team position",
			}, record) then return true end
		end
	end
	if IsValidEntityHandle(target)
		and target:GetTeamNumber() ~= hero:GetTeamNumber()
		and (record.boss_threat_nearby == true or threat >= 0.82) then
		if self:CastNamedActiveItem(hero, "item_staff_of_mastery", {
			mode = "enemy_unit",
			target = target,
			reason = "disable dangerous physical target",
		}, record) then return true end
	end

	local hasCombatTarget = record.target_entindex ~= nil
	local shouldDeployFurbolg = hasCombatTarget
		and not self:HasOwnedFurbolg(hero)
		and GameRules:GetCustomGameDifficulty() >= 4
		and XHSBotItemPlanner:IsHighThreat(record)
	if shouldDeployFurbolg then
		if self:CastNamedActiveItem(hero, "item_amulet_of_the_wild", {
			mode = "no_target",
			reason = "deploy furbolg combat screen",
		}, record) then return true end
	end

	-- Toggle repair is maintenance. It must never delay a fatal potion, a
	-- team ward, a disable, or the deployment of an already bought screen.
	if self:UpdateDarknessOrb(hero, record) then return true end
	if self:EnsureCoreOrbStates(hero, record) then return true end
	return false
end

function XHSBotEconomy:GetGold(playerID)
	if Gold ~= nil and Gold.GetGold ~= nil then
		return math.max(0, tonumber(Gold:GetGold(playerID)) or 0)
	end
	if PlayerResource ~= nil and PlayerResource.GetGold ~= nil then
		return math.max(0, tonumber(PlayerResource:GetGold(playerID)) or 0)
	end
	return 0
end

function XHSBotEconomy:SetSynchronizedGold(playerID, amount)
	amount = math.max(0, math.floor(tonumber(amount) or 0))
	local hasCustomWallet = Gold ~= nil and Gold.GetGold ~= nil

	-- Once the custom wallet is active, updating it without the native wallet
	-- is unsafe at the 50k boundary. Fail closed if either setter is missing.
	if hasCustomWallet and Gold.SetGold == nil then return false end
	if PlayerResource == nil
		or PlayerResource.GetGold == nil
		or PlayerResource.SetGold == nil then
		return false
	end

	local nativeAmount = amount
	if hasCustomWallet then
		nativeAmount = math.min(amount, self.ENGINE_GOLD_CAP)
		local customOK = pcall(function()
			Gold:SetGold(playerID, amount)
		end)
		if not customOK then return false end
	end

	local nativeOK = pcall(function()
		PlayerResource:SetGold(playerID, nativeAmount, false)
		PlayerResource:SetGold(playerID, 0, true)
	end)
	if not nativeOK then return false end

	local logicalGold = self:GetGold(playerID)
	local nativeGold = math.max(0, tonumber(PlayerResource:GetGold(playerID)) or 0)
	return logicalGold == amount and nativeGold == nativeAmount
end

function XHSBotEconomy:WithdrawGold(playerID, amount)
	amount = math.max(0, math.ceil(tonumber(amount) or 0))
	if amount <= 0 then return true end
	local goldBefore = self:GetGold(playerID)
	if goldBefore < amount then return false end
	local targetGold = goldBefore - amount

	if Gold ~= nil and Gold.GetGold ~= nil then
		if self:SetSynchronizedGold(playerID, targetGold) then return true end
		-- A setter may have failed after changing one wallet. Restore the exact
		-- pre-transaction balance; never grant an item or stats on uncertainty.
		self:SetSynchronizedGold(playerID, goldBefore)
		return false
	end
	if PlayerResource ~= nil and PlayerResource.SpendGold ~= nil then
		local ok = pcall(function()
			PlayerResource:SpendGold(playerID, amount, DOTA_ModifyGold_PurchaseItem)
		end)
		if ok and self:GetGold(playerID) == targetGold then return true end
		self:SetSynchronizedGold(playerID, goldBefore)
		return false
	end
	return false
end

function XHSBotEconomy:RefundGold(playerID, amount)
	amount = math.max(0, math.ceil(tonumber(amount) or 0))
	if amount <= 0 then return true end
	local goldBefore = self:GetGold(playerID)
	return self:SetSynchronizedGold(playerID, goldBefore + amount)
end

function XHSBotEconomy:RemoveGrantedItem(hero, item)
	if not IsValidEntityHandle(item) then return end
	pcall(function() hero:RemoveItem(item) end)
	if IsValidEntityHandle(item) and UTIL_Remove ~= nil then
		pcall(function() UTIL_Remove(item) end)
	end
end

function XHSBotEconomy:GetAnkhPassiveCharges(hero)
	if not IsValidEntityHandle(hero) or hero.FindModifierByName == nil then return 0 end
	local modifier = hero:FindModifierByName("modifier_ankh_passives")
	if modifier == nil or modifier.GetStackCount == nil then return 0 end
	local ok, count = pcall(function() return modifier:GetStackCount() end)
	return ok and math.max(0, tonumber(count) or 0) or 0
end

function XHSBotEconomy:GetAnkhCharges(hero)
	local _, inventoryCharges = self:GetInventoryTotals(hero, self.ANKH_ITEM_NAME)
	return self:GetAnkhPassiveCharges(hero) + inventoryCharges
end

function XHSBotEconomy:GrantPurchasedItem(
	playerID,
	hero,
	entry,
	unitsBefore,
	chargesBefore,
	requiredShop
)
	requiredShop = tostring(requiredShop or self:GetRequiredShop(entry))
	local shopKind, shopDistance, shopRejection =
		self:GetCurrentShopKind(hero, requiredShop)
	if shopKind == nil then
		return false,
			"shop invariant rejected " .. tostring(entry.name)
				.. " for " .. requiredShop .. ": " .. tostring(shopRejection),
			nil,
			shopDistance
	end
	local purchaseName = tostring(entry.purchase_name or entry.name)
	local ok, item = pcall(function()
		return CreateItem(purchaseName, hero, hero)
	end)
	if not ok or not IsValidEntityHandle(item) then
		return false, "CreateItem failed for " .. purchaseName, shopKind, shopDistance
	end

	if item.SetPurchaser ~= nil then
		pcall(function() item:SetPurchaser(hero) end)
	end
	if item.SetPurchaseTime ~= nil then
		pcall(function() item:SetPurchaseTime(GameRules:GetGameTime()) end)
	end

	local cost = math.max(0, tonumber(entry.cost) or 0)
	if not self:WithdrawGold(playerID, cost) then
		self:RemoveGrantedItem(hero, item)
		return false,
			"gold withdrawal failed for " .. tostring(entry.name),
			shopKind,
			shopDistance
	end

	local added = pcall(function() hero:AddItem(item) end)
	if not added then
		self:RemoveGrantedItem(hero, item)
		self:RefundGold(playerID, cost)
		return false, "AddItem failed for " .. purchaseName, shopKind, shopDistance
	end

	local unitsAfter, chargesAfter = self:GetEntryInventoryTotals(hero, entry)
	local completed = unitsAfter > (unitsBefore or 0)
		or chargesAfter > (chargesBefore or 0)
	if not completed then
		self:RemoveGrantedItem(hero, item)
		self:RefundGold(playerID, cost)
		return false,
			"granted item did not complete " .. tostring(entry.name),
			shopKind,
			shopDistance
	end
	return true, purchaseName, shopKind, shopDistance
end

function XHSBotEconomy:GetInventoryTotals(hero, wantedName, lastSlot)
	local units = 0
	local charges = 0
	lastSlot = math.min(
		self.SCAN_LAST_SLOT,
		math.max(0, tonumber(lastSlot) or self.SCAN_LAST_SLOT)
	)
	for slot = 0, lastSlot do
		local item = hero:GetItemInSlot(slot)
		if ItemName(item) == wantedName then
			units = units + 1
			if item.GetCurrentCharges ~= nil then
				charges = charges + math.max(0, tonumber(item:GetCurrentCharges()) or 0)
			end
		end
	end
	return units, charges
end

function XHSBotEconomy:GetEntryInventoryTotals(hero, entry)
	local names = entry.completion_names or { entry.name }
	local totalUnits = 0
	local totalCharges = 0
	for _, name in ipairs(names) do
		local units, charges = self:GetInventoryTotals(hero, name)
		totalUnits = totalUnits + units
		totalCharges = totalCharges + charges
	end
	if entry.name == self.ANKH_ITEM_NAME then
		totalCharges = totalCharges + self:GetAnkhPassiveCharges(hero)
	end
	return totalUnits, totalCharges
end

function XHSBotEconomy:GetStashItemCount(hero)
	if not IsValidEntityHandle(hero) then return 0 end
	local count = 0
	for slot = self.STASH_FIRST_SLOT, self.STASH_LAST_SLOT do
		if IsValidEntityHandle(hero:GetItemInSlot(slot)) then count = count + 1 end
	end
	return count
end

function XHSBotEconomy:GetStashSignature(hero)
	if not IsValidEntityHandle(hero) then return "" end
	local parts = {}
	for slot = self.STASH_FIRST_SLOT, self.STASH_LAST_SLOT do
		local item = hero:GetItemInSlot(slot)
		if IsValidEntityHandle(item) then
			local charges = 0
			if item.GetCurrentCharges ~= nil then
				local ok, value = pcall(function() return item:GetCurrentCharges() end)
				if ok then charges = math.max(0, tonumber(value) or 0) end
			end
			table.insert(parts, table.concat({
				tostring(slot),
				tostring(ItemName(item) or "unknown"),
				tostring(charges),
			}, ":"))
		end
	end
	return table.concat(parts, "|")
end

function XHSBotEconomy:GetPriorityStashItem(hero)
	if not IsValidEntityHandle(hero) then return nil end
	for slot = self.STASH_FIRST_SLOT, self.STASH_LAST_SLOT do
		local item = hero:GetItemInSlot(slot)
		local name = ItemName(item)
		local catalog = name ~= nil and XHSBotItemCatalog:Get(name) or nil
		if name == self.ANKH_ITEM_NAME
			or catalog ~= nil and (
				catalog.requires_active_slot == true
				or catalog.active_slot == true
			) then
			return name
		end
	end
	return nil
end

function XHSBotEconomy:FindFreeSlot(hero, firstSlot, lastSlot)
	for slot = firstSlot, lastSlot do
		if not IsValidEntityHandle(hero:GetItemInSlot(slot)) then return slot end
	end
	return nil
end

function XHSBotEconomy:FindStashItemSlot(hero, wantedName)
	for slot = self.STASH_FIRST_SLOT, self.STASH_LAST_SLOT do
		local item = hero:GetItemInSlot(slot)
		if IsValidEntityHandle(item)
			and (wantedName == nil or ItemName(item) == wantedName) then
			return slot
		end
	end
	return nil
end

function XHSBotEconomy:CollectStashItems(hero, record)
	if not IsValidEntityHandle(hero) or not self:IsAtRequiredShop(hero, "base") then
		return 0
	end

	local moved = 0
	local safety = 0
	while safety < self.STASH_CAPACITY do
		safety = safety + 1
		-- Ankh cannot live in the backpack. Moving it to slots 0-5 activates
		-- its intrinsic modifier, consumes the item and banks a revive charge.
		local stashSlot = self:FindStashItemSlot(hero, self.ANKH_ITEM_NAME)
		local targetSlot = nil
		if stashSlot ~= nil then
			targetSlot = self:FindFreeSlot(hero, 0, self.ACTIVE_LAST_SLOT)
		else
			stashSlot = self:FindStashItemSlot(hero, nil)
			targetSlot = self:FindFreeSlot(hero, 0, self.INVENTORY_LAST_SLOT)
		end
		if stashSlot == nil or targetSlot == nil then break end

		local item = hero:GetItemInSlot(stashSlot)
		local name = ItemName(item) or "unknown"
		local ok = pcall(function() hero:SwapItems(targetSlot, stashSlot) end)
		local itemAfter = hero:GetItemInSlot(stashSlot)
		if not ok or itemAfter == item then break end
		moved = moved + 1
		record.stash_items_collected = (record.stash_items_collected or 0) + 1
		record.last_item_action = "collect_stash:" .. name
	end
	return moved
end

function XHSBotEconomy:HasFreeInventorySlot(hero)
	for slot = 0, self.INVENTORY_LAST_SLOT do
		if not IsValidEntityHandle(hero:GetItemInSlot(slot)) then return true end
	end
	return false
end

function XHSBotEconomy:GetTargetLoadoutCount(plan, wantedName)
	local count = 0
	for _, name in ipairs(plan and plan.target_loadout or {}) do
		if name == wantedName then count = count + 1 end
	end
	return count
end

function XHSBotEconomy:IsTargetFamilyItem(name, plan)
	local catalog = XHSBotItemCatalog:Get(name)
	if catalog == nil or catalog.family == nil then return false end
	local family = XHSBotItemCatalog:GetFamily(catalog.family)
	local terminal = family and family.levels[#family.levels] or nil
	return terminal ~= nil
		and self:GetTargetLoadoutCount(plan, terminal.name) > 0
end

function XHSBotEconomy:GetItemEquipPriority(item, snapshot, plan)
	local name = ItemName(item)
	if name == nil then return -1000 end
	if name == self.ANKH_ITEM_NAME then return 1200 end
	local catalog = XHSBotItemCatalog:Get(name) or {}
	if tonumber(catalog.equip_priority) ~= nil then
		return tonumber(catalog.equip_priority)
	end
	local healthRatio = tonumber(snapshot.health_ratio) or 1
	local manaRatio = tonumber(snapshot.mana_ratio) or 1
	local highThreat = XHSBotItemPlanner:IsHighThreat(snapshot)
	if name == "item_potion_of_invulnerability" then
		return highThreat and 1140 or 620
	elseif name == "item_potion_full" then
		return (healthRatio <= 0.65 or manaRatio <= 0.25) and 1120 or 600
	elseif name == "item_potion_of_antimagic" then
		return (tonumber(snapshot.magical_threat) or 0) >= 0.55 and 1100 or 590
	elseif name == "item_health_potion" then
		return healthRatio <= 0.68 and 1080 or 430
	elseif name == "item_mana_potion" then
		return manaRatio <= 0.42 and 1010 or 390
	elseif name == "item_healing_wards" or name == "item_healing_wards2" then
		return highThreat and 1000 or 520
	end
	for _, targetName in ipairs(plan and plan.target_loadout or {}) do
		if targetName == name then return 980 end
	end
	if catalog.no_backpack == true then
		return 760
	end
	if catalog.kind == "core" and self:IsTargetFamilyItem(name, plan) then
		return 820 + math.max(0, tonumber(catalog.tier) or 0) * 40
	end
	if catalog.kind == "core" then
		return 650 + math.max(0, tonumber(catalog.tier) or 0) * 70
	elseif name == "item_staff_of_mastery" then
		return 900
	elseif name == "item_amulet_of_the_wild" then
		return highThreat and 890 or 500
	elseif catalog.active_slot == true or catalog.kind == "tactical" then
		return highThreat and 840 or 480
	elseif name == "item_boots_of_speed" then
		return 180
	end
	return 250
end

function XHSBotEconomy:OptimizeActiveInventory(hero, record, snapshot, plan)
	if not IsValidEntityHandle(hero) then return false end
	local bestBackpackSlot = nil
	local bestBackpackPriority = -math.huge
	local lastStoredSlot = self.INVENTORY_LAST_SLOT
	if snapshot.at_home_shop == true then lastStoredSlot = self.STASH_LAST_SLOT end
	for slot = self.ACTIVE_LAST_SLOT + 1, lastStoredSlot do
		local item = hero:GetItemInSlot(slot)
		if IsValidEntityHandle(item) then
			local priority = self:GetItemEquipPriority(item, snapshot, plan)
			if priority > bestBackpackPriority then
				bestBackpackSlot = slot
				bestBackpackPriority = priority
			end
		end
	end
	if bestBackpackSlot == nil then return false end

	local targetSlot = self:FindFreeSlot(hero, 0, self.ACTIVE_LAST_SLOT)
	local targetPriority = -math.huge
	if targetSlot == nil then
		targetPriority = math.huge
		for slot = 0, self.ACTIVE_LAST_SLOT do
			local priority = self:GetItemEquipPriority(
				hero:GetItemInSlot(slot),
				snapshot,
				plan
			)
			if priority < targetPriority then
				targetSlot = slot
				targetPriority = priority
			end
		end
	end
	if targetSlot == nil or bestBackpackPriority <= targetPriority then return false end

	local backpackItem = hero:GetItemInSlot(bestBackpackSlot)
	local backpackName = ItemName(backpackItem) or "unknown"
	local activeName = ItemName(hero:GetItemInSlot(targetSlot)) or "empty"
	local swapped = pcall(function()
		hero:SwapItems(targetSlot, bestBackpackSlot)
	end)
	if not swapped or hero:GetItemInSlot(bestBackpackSlot) == backpackItem then
		record.last_item_rejection = "inventory optimizer swap rejected"
		return false
	end
	record.inventory_swaps = (record.inventory_swaps or 0) + 1
	record.last_item_action = (bestBackpackSlot >= self.STASH_FIRST_SLOT
		and "equip_stash:" or "equip:")
		.. backpackName .. "<-" .. activeName
	return true
end

function XHSBotEconomy:GetIncomingItemPriority(entry, snapshot, plan)
	if entry == nil then return -math.huge end
	local catalog = XHSBotItemCatalog:Get(entry.name) or entry
	if catalog.consumable ~= nil or catalog.kind == "revive" then
		return -math.huge
	end
	if catalog.kind == "core" then
		local priority = 720 + math.max(0, tonumber(catalog.tier) or 0) * 35
		if self:IsTargetFamilyItem(entry.name, plan) then
			priority = 900 + math.max(0, tonumber(catalog.tier) or 0) * 25
			if entry.name == (plan.next_entry and plan.next_entry.name) then
				priority = priority
					+ math.min(50, math.max(0, tonumber(plan.next_score) or 0) * 0.4)
			end
		end
		return priority
	end
	if catalog.kind == "tactical" then
		return XHSBotItemPlanner:IsHighThreat(snapshot) and 940 or 680
	end
	if catalog.kind == "utility" then return 850 end
	return -math.huge
end

function XHSBotEconomy:GetReplacementCredit(item, catalog)
	if not IsValidEntityHandle(item) or catalog == nil then return 0 end
	local base = math.max(
		0,
		tonumber(catalog.total_cost) or tonumber(catalog.cost) or 0
	)
	if tonumber(catalog.charges) ~= nil and item.GetCurrentCharges ~= nil then
		local charges = math.max(0, tonumber(item:GetCurrentCharges()) or 0)
		base = base * math.min(1, charges / math.max(1, tonumber(catalog.charges)))
	end
	return math.floor(base * 0.5)
end

function XHSBotEconomy:FindReplacementCandidate(hero, entry, snapshot, plan)
	local incomingPriority = self:GetIncomingItemPriority(entry, snapshot, plan)
	if incomingPriority == -math.huge then return nil end
	local lastSlot = snapshot.at_home_shop == true
		and self.STASH_LAST_SLOT or self.INVENTORY_LAST_SLOT
	local best = nil
	for slot = 0, lastSlot do
		local item = hero:GetItemInSlot(slot)
		local name = ItemName(item)
		local catalog = name ~= nil and XHSBotItemCatalog:Get(name) or nil
		local protected = catalog == nil
			or name == self.ANKH_ITEM_NAME
			or name == "item_health_potion"
			or name == "item_mana_potion"
			or name == entry.predecessor
			or self:IsTargetFamilyItem(name, plan)
		if not protected and catalog.no_backpack == true then
			local incomingCatalog = XHSBotItemCatalog:Get(entry.name) or {}
			local oldScore = tonumber(
				plan.family_loadout_scores
					and plan.family_loadout_scores[catalog.family]
			) or 0
			local newScore = tonumber(
				plan.family_loadout_scores
					and plan.family_loadout_scores[incomingCatalog.family]
			) or 0
			protected = plan.phase ~= "luxury"
				or incomingCatalog.family == nil
				or newScore < oldScore + 25
		end
		if not protected then
			local priority = self:GetItemEquipPriority(item, snapshot, plan)
			if incomingPriority >= priority + 60
				and (best == nil or priority < best.priority) then
				best = {
					slot = slot,
					item = item,
					name = name,
					catalog = catalog,
					priority = priority,
					incoming_priority = incomingPriority,
					credit = self:GetReplacementCredit(item, catalog),
				}
			end
		end
	end
	return best
end

function XHSBotEconomy:PrepareInventoryReplacement(hero, entry, snapshot, plan, record, now)
	local candidate = self:FindReplacementCandidate(hero, entry, snapshot, plan)
	if candidate == nil then return nil, "no lower-value replacement candidate" end
	if candidate.catalog.no_backpack == true then
		local watchKey = candidate.name .. "->" .. tostring(entry.name)
		if record.replacement_watch_key ~= watchKey then
			record.replacement_watch_key = watchKey
			record.replacement_watch_started_at = now
			return nil, "terminal replacement evaluation started"
		end
		local age = now - (tonumber(record.replacement_watch_started_at) or now)
		if age < 45 then
			return nil, "terminal replacement hysteresis "
				.. tostring(math.ceil(45 - age)) .. "s"
		end
	else
		record.replacement_watch_key = nil
		record.replacement_watch_started_at = nil
	end

	local charges = 0
	if candidate.item.GetCurrentCharges ~= nil then
		charges = math.max(0, tonumber(candidate.item:GetCurrentCharges()) or 0)
	end
	self:RemoveGrantedItem(hero, candidate.item)
	if hero:GetItemInSlot(candidate.slot) == candidate.item then
		return nil, "failed to retire replacement item"
	end
	candidate.charges = charges
	candidate.removed_at = now
	return candidate
end

function XHSBotEconomy:RestoreRetiredItem(hero, retired)
	if retired == nil or retired.name == nil then return true end
	local ok, restored = pcall(function()
		return CreateItem(retired.name, hero, hero)
	end)
	if not ok or not IsValidEntityHandle(restored) then return false end
	if restored.SetPurchaser ~= nil then
		pcall(function() restored:SetPurchaser(hero) end)
	end
	if retired.charges > 0 and restored.SetCurrentCharges ~= nil then
		pcall(function() restored:SetCurrentCharges(retired.charges) end)
	end
	local added = pcall(function() hero:AddItem(restored) end)
	if not added then
		self:RemoveGrantedItem(hero, restored)
		return false
	end
	return true
end

function XHSBotEconomy:CommitInventoryReplacement(playerID, retired, entry, record)
	if retired == nil then return end
	local credited = retired.credit <= 0
		or self:RefundGold(playerID, retired.credit)
	record.items_replaced = (record.items_replaced or 0) + 1
	record.replacement_gold_recovered =
		(record.replacement_gold_recovered or 0)
		+ (credited and retired.credit or 0)
	record.last_replaced_item = tostring(retired.name)
	record.last_item_action = "replace:" .. tostring(retired.name)
		.. "->" .. tostring(entry.name)
	if not credited then
		record.last_item_rejection = "replacement resale credit failed"
	end
	record.replacement_watch_key = nil
	record.replacement_watch_started_at = nil
end

function XHSBotEconomy:IsBuildEntryApplicable(entry)
	local gameDifficulty = GameRules:GetCustomGameDifficulty()
	if tonumber(entry.minimum_game_difficulty) ~= nil
		and gameDifficulty < tonumber(entry.minimum_game_difficulty) then
		return false
	end
	if tonumber(entry.maximum_game_difficulty) ~= nil
		and gameDifficulty > tonumber(entry.maximum_game_difficulty) then
		return false
	end
	return true
end

function XHSBotEconomy:GetDesiredConsumableCharges(entry, difficulty)
	if tonumber(entry.desired_charges) ~= nil then
		return math.max(0, math.floor(tonumber(entry.desired_charges)))
	end
	if entry.consumable == "health" then
		return math.max(0, tonumber(difficulty.min_health_potion_charges) or 0)
	elseif entry.consumable == "mana" then
		return math.max(0, tonumber(difficulty.min_mana_potion_charges) or 0)
	end
	return 0
end

function XHSBotEconomy:NeedsBuildEntry(hero, entry, difficulty)
	if not self:IsBuildEntryApplicable(entry) then return false, 0, 0 end
	local units, charges = self:GetEntryInventoryTotals(hero, entry)
	if entry.consumable ~= nil then
		local desiredCharges = self:GetDesiredConsumableCharges(entry, difficulty)
		return desiredCharges > 0 and charges < desiredCharges, units, charges
	end
	if entry.name == self.ANKH_ITEM_NAME then
		return charges < math.max(1, tonumber(entry.maximum) or 1), units, charges
	end
	return units < math.max(1, tonumber(entry.maximum) or 1), units, charges
end

function XHSBotEconomy:GetAlliedItemCoverage(hero)
	local itemCounts = {}
	local familyCounts = {}
	local allyCount = 0
	local lowHealthCount = 0
	local healthDeficit = 0
	if not IsValidEntityHandle(hero) or PlayerResource == nil then
		return itemCounts, familyCounts, allyCount, lowHealthCount, healthDeficit
	end
	local team = hero:GetTeamNumber()
	local playerIDs = {}
	if XHSBotPlayerRegistry ~= nil
		and XHSBotPlayerRegistry.GetCombatParticipantPlayerIDs ~= nil then
		local ok, registered = pcall(function()
			return XHSBotPlayerRegistry:GetCombatParticipantPlayerIDs()
		end)
		if ok and type(registered) == "table" then playerIDs = registered end
	end
	if #playerIDs <= 0 then
		for playerID = 0, 23 do table.insert(playerIDs, playerID) end
	end
	for _, playerID in ipairs(playerIDs) do
		local ally = nil
		if PlayerResource.IsValidPlayerID ~= nil
			and PlayerResource:IsValidPlayerID(playerID)
			and PlayerResource.GetSelectedHeroEntity ~= nil then
			local ok, selected = pcall(function()
				return PlayerResource:GetSelectedHeroEntity(playerID)
			end)
			if ok then ally = selected end
		end
		if IsValidEntityHandle(ally)
			and ally ~= hero
			and ally.GetTeamNumber ~= nil
			and ally:GetTeamNumber() == team
			and (ally.IsRealHero == nil or ally:IsRealHero()) then
			allyCount = allyCount + 1
			local healthRatio = ally:GetHealth() / math.max(1, ally:GetMaxHealth())
			if healthRatio <= 0.55 then lowHealthCount = lowHealthCount + 1 end
			healthDeficit = healthDeficit + (1 - healthRatio)
			for slot = 0, self.SCAN_LAST_SLOT do
				local name = ItemName(ally:GetItemInSlot(slot))
				if name ~= nil then
					itemCounts[name] = (itemCounts[name] or 0) + 1
					local catalog = XHSBotItemCatalog:Get(name)
					if catalog ~= nil and catalog.family ~= nil then
						familyCounts[catalog.family] =
							(familyCounts[catalog.family] or 0) + 1
					end
				end
			end
		end
	end
	return itemCounts, familyCounts, allyCount, lowHealthCount, healthDeficit
end

function XHSBotEconomy:BuildPlannerSnapshot(playerID, hero, record)
	local now = GameRules:GetGameTime()
	local damageTypeFresh = now - (tonumber(record.damage_type_last_hit_at) or -math.huge)
		<= 12
	local owned = {}
	local activeSlots = 0
	local inventorySlots = 0
	for slot = 0, self.SCAN_LAST_SLOT do
		local item = hero:GetItemInSlot(slot)
		local name = ItemName(item)
		if name ~= nil then
			owned[name] = (owned[name] or 0) + 1
			if slot <= self.ACTIVE_LAST_SLOT then activeSlots = activeSlots + 1 end
			if slot <= self.INVENTORY_LAST_SLOT then
				inventorySlots = inventorySlots + 1
			end
		end
	end
	local _, healthCharges = self:GetInventoryTotals(hero, "item_health_potion")
	local _, manaCharges = self:GetInventoryTotals(hero, "item_mana_potion")
	local inFarmEvent = GameMode ~= nil
		and GameMode.FarmEvent_occuring == true
		and SpecialEvents ~= nil
		and type(SpecialEvents.hero_farm_event) == "table"
		and type(
			SpecialEvents.hero_farm_event[tonumber(playerID)]
				or SpecialEvents.hero_farm_event[tostring(playerID)]
		) == "table"
	local alliedItemCounts, alliedFamilyCounts, allyCount,
		alliedLowHealthCount, alliedHealthDeficit =
		self:GetAlliedItemCoverage(hero)
	local origin = hero:GetAbsOrigin()
	local function ShopDistance(shop)
		local anchor = self:GetShopAnchor(shop, hero)
		return anchor ~= nil and (origin - anchor):Length2D() or -1
	end
	local movementSpeed = 300
	if hero.GetIdealSpeed ~= nil then
		local ok, value = pcall(function() return hero:GetIdealSpeed() end)
		if ok then movementSpeed = math.max(1, tonumber(value) or movementSpeed) end
	elseif hero.GetBaseMoveSpeed ~= nil then
		local ok, value = pcall(function() return hero:GetBaseMoveSpeed() end)
		if ok then movementSpeed = math.max(1, tonumber(value) or movementSpeed) end
	end
	return {
		owned = owned,
		allied_item_counts = alliedItemCounts,
		allied_family_counts = alliedFamilyCounts,
		ally_count = allyCount,
		allied_low_health_count = alliedLowHealthCount,
		allied_health_deficit = alliedHealthDeficit,
		active_slots = activeSlots,
		inventory_slots = inventorySlots,
		stash_slots = self:GetStashItemCount(hero),
		gold = self:GetGold(playerID),
		item_gold_spent = tonumber(record.item_gold_spent) or 0,
		tomes_bought = tonumber(record.tomes_bought) or 0,
		game_time = now,
		game_difficulty = GameRules:GetCustomGameDifficulty(),
		health_ratio = hero:GetHealth() / math.max(1, hero:GetMaxHealth()),
		mana_ratio = hero:GetMana() / math.max(1, hero:GetMaxMana()),
		max_health = hero:GetMaxHealth(),
		max_mana = hero:GetMaxMana(),
		combat_threat = tonumber(record.combat_threat) or 0,
		base_threat_score = tonumber(record.base_threat_score) or 0,
		base_threat_active = record.base_threat_active == true,
		assignment_urgency = tonumber(record.assignment_urgency) or 0,
		recent_damage_ratio = tonumber(record.recent_damage_ratio) or 0,
		focused_by_count = tonumber(record.focused_by_count) or 0,
		physical_threat = damageTypeFresh
			and (tonumber(record.physical_threat) or 0) or 0,
		magical_threat = damageTypeFresh
			and (tonumber(record.magical_threat) or 0) or 0,
		pure_threat = damageTypeFresh
			and (tonumber(record.pure_threat) or 0) or 0,
		nearby_screen_count = tonumber(record.nearby_screen_count) or 0,
		boss_nearby = record.boss_threat_nearby == true,
		goal = tostring(record.goal or ""),
		last_death_duration = tonumber(record.last_death_duration) or 0,
		expected_respawn_seconds = tonumber(record.expected_respawn_seconds) or 0,
		secret_shop_available = self:GetShopAnchor("secret") ~= nil,
		home_shop_distance = ShopDistance("home"),
		secret_shop_distance = ShopDistance("secret"),
		movement_speed = movementSpeed,
		lane_anchor_distance = tonumber(record.lane_anchor_distance) or 0,
		stuck_recoveries = tonumber(record.stuck_recoveries) or 0,
		at_home_shop = self:IsAtRequiredShop(hero, "base"),
		in_combat = record.target_entindex ~= nil
			or (tonumber(record.combat_threat) or 0) >= 0.45,
		has_owned_furbolg = self:HasOwnedFurbolg(hero),
		in_farm_event = inFarmEvent,
		health_potion_charges = healthCharges,
		mana_potion_charges = manaCharges,
	}
end

function XHSBotEconomy:FindPlanCandidate(plan, family)
	for _, candidate in ipairs(plan and plan.candidates or {}) do
		if candidate.family == family then return candidate end
	end
	return nil
end

function XHSBotEconomy:StabilizePlan(record, plan, now)
	local nextFamily = tostring(plan.next_family or "")
	if nextFamily == "" then
		record.economy_plan_lock_family = nil
		record.economy_plan_lock_started_at = nil
		return plan
	end
	local lockedFamily = tostring(record.economy_plan_lock_family or "")
	if lockedFamily == "" then
		record.economy_plan_lock_family = nextFamily
		record.economy_plan_lock_started_at = now
		return plan
	end
	if lockedFamily == nextFamily then return plan end

	local previous = self:FindPlanCandidate(plan, lockedFamily)
	local lockAge = now - (tonumber(record.economy_plan_lock_started_at) or now)
	local newScore = tonumber(plan.next_score) or 0
	local previousScore = previous and tonumber(previous.score) or -math.huge
	if previous ~= nil and lockAge < 20 and previousScore >= newScore - 12 then
		plan.next_entry = previous.entry
		plan.next_family = previous.family
		plan.next_score = previous.score
		plan.next_reason = tostring(previous.reason or "") .. "+plan_hysteresis"
		plan.reserve_gold = math.max(0, tonumber(previous.entry.cost) or 0)
		plan.replacement_required = previous.entry.tier == 1
			and (tonumber(plan.inventory_slots) or 0) >= 9
		record.economy_plan_hysteresis_holds =
			(record.economy_plan_hysteresis_holds or 0) + 1
		return plan
	end

	record.economy_plan_lock_family = nextFamily
	record.economy_plan_lock_started_at = now
	record.economy_plan_switches = (record.economy_plan_switches or 0) + 1
	return plan
end

function XHSBotEconomy:RecordPlan(record, snapshot, plan)
	record.economy_phase = plan.phase
	record.economy_reserve_gold = plan.reserve_gold
	record.planned_item = plan.next_entry and plan.next_entry.name or ""
	record.planned_item_family = plan.next_family or ""
	record.planned_item_score = plan.next_score or 0
	record.planned_item_reason = plan.next_reason or ""
	record.planned_loadout = plan.target_loadout or {}
	record.planned_loadout_scores = plan.target_loadout_scores or {}
	record.replacement_required = plan.replacement_required == true
	record.ankh_target = plan.ankh_target or 0
	record.health_potion_charges = snapshot.health_potion_charges or 0
	record.health_potion_target = plan.health_potion_target or 0
	record.mana_potion_charges = snapshot.mana_potion_charges or 0
	record.mana_potion_target = plan.mana_potion_target or 0
	record.tome_allowance = plan.tome_allowance or 0
	record.active_item_slots = snapshot.active_slots or 0
	record.inventory_item_slots = snapshot.inventory_slots or 0
	record.has_owned_furbolg = snapshot.has_owned_furbolg == true
	record.allied_family_counts = snapshot.allied_family_counts or {}
	record.allied_item_counts = snapshot.allied_item_counts or {}
	record.item_candidates = {}
	for index = 1, math.min(3, #(plan.candidates or {})) do
		local candidate = plan.candidates[index]
		table.insert(record.item_candidates, {
			item = candidate.entry.name,
			family = candidate.family,
			score = candidate.score,
			reason = candidate.reason,
		})
	end
end

function XHSBotEconomy:ShouldRestockPotion(kind, snapshot, plan)
	local charges = math.max(
		0,
		tonumber(snapshot[tostring(kind) .. "_potion_charges"]) or 0
	)
	local target = math.max(
		0,
		tonumber(plan[tostring(kind) .. "_potion_target"]) or 0
	)
	if target <= 0 or charges >= target then return false end
	if snapshot.at_home_shop == true or charges <= 0 then return true end

	-- Four charges should trigger a future restock, not abandon a dangerous
	-- lane. Stable downtime may start the grouped home-shop trip; current
	-- combat, castle pressure or a high-urgency assignment defers it.
	local unsafe = snapshot.in_combat == true
		or snapshot.base_threat_active == true
		or (tonumber(snapshot.base_threat_score) or 0) >= 0.35
		or (tonumber(snapshot.assignment_urgency) or 0) >= 0.70
		or (tonumber(snapshot.recent_damage_ratio) or 0) >= 0.05
	return not unsafe
end

function XHSBotEconomy:BuildPlannedPurchases(snapshot, plan)
	local purchases = {}
	local function Add(entry)
		if entry ~= nil then table.insert(purchases, entry) end
	end
	if self:ShouldRestockPotion("health", snapshot, plan) then
		local entry = XHSBotItemCatalog:CopyEntry("item_health_potion")
		entry.desired_charges = plan.health_potion_target
		Add(entry)
	end
	if self:ShouldRestockPotion("mana", snapshot, plan) then
		local entry = XHSBotItemCatalog:CopyEntry("item_mana_potion")
		entry.desired_charges = plan.mana_potion_target
		Add(entry)
	end
	if self:GetAnkhChargesFromSnapshot(snapshot) < (plan.ankh_target or 0) then
		local entry = XHSBotItemCatalog:CopyEntry(self.ANKH_ITEM_NAME)
		entry.maximum = plan.ankh_target
		Add(entry)
	end
	Add(plan.tactical_entry)
	Add(plan.next_entry)
	return purchases
end

function XHSBotEconomy:GetAnkhChargesFromSnapshot(snapshot)
	return math.max(0, tonumber(snapshot.ankh_charges) or 0)
end

function XHSBotEconomy:GetRequiredShop(entry)
	if type(entry) ~= "table" then return "home" end
	local catalog = XHSBotItemCatalog ~= nil
		and XHSBotItemCatalog:Get(entry.name) or nil
	local declared = tostring(
		type(catalog) == "table" and catalog.shop
			or entry.shop
			or "home"
	)
	if declared == "secret" then return "secret" end
	if declared == "base" then return "base" end
	-- The general XHS inventory is sold at both base and lane shops.
	return "home"
end

function XHSBotEconomy:PurchasePlan(playerID, hero, difficulty, record, snapshot, plan)
	snapshot.ankh_charges = self:GetAnkhCharges(hero)
	for _, entry in ipairs(self:BuildPlannedPurchases(snapshot, plan)) do
		local result = self:TryPurchaseBuildEntry(
			playerID,
			hero,
			entry,
			difficulty,
			record,
			snapshot,
			plan
		)
		if result == "purchased" or result == "travel" then return result end
	end
	return nil
end

function XHSBotEconomy:GetShopAnchors(shop)
	shop = tostring(shop or "home")
	local anchors = {}
	local castleShop = Entities:FindByName(nil, "castle_shop")
	local secretPosition = IsValidEntityHandle(castleShop)
		and castleShop:GetAbsOrigin() or nil

	local function Add(entity, kind, radius)
		if not IsValidEntityHandle(entity) then return end
		local position = entity:GetAbsOrigin()
		for _, existing in ipairs(anchors) do
			if (existing.position - position):Length2D() <= 64 then return end
		end
		table.insert(anchors, {
			position = CopyPosition(position),
			kind = kind,
			radius = radius,
		})
	end

	if shop == "secret" then
		Add(castleShop, "secret", self.SECRET_SHOP_RADIUS)
		return anchors
	end

	local fort = GetFort()
	Add(fort, "base", self.BASE_SHOP_RADIUS)
	if shop == "base" then return anchors end

	-- Discover the same map-owned lane shop classes used by the lane director.
	-- Exclude both castle_shop itself and any companion trigger colocated with
	-- it, since the custom secret shop may expose more than one entity.
	local seen = {}
	for _, className in ipairs(GENERAL_SHOP_CLASSNAMES) do
		for _, entity in pairs(Entities:FindAllByClassname(className) or {}) do
			local entityIndex = IsValidEntityHandle(entity) and entity:entindex() or -1
			if entityIndex >= 0
				and not seen[entityIndex]
				and entity ~= castleShop then
				local distanceFromSecret = secretPosition ~= nil
					and (entity:GetAbsOrigin() - secretPosition):Length2D()
					or math.huge
				if distanceFromSecret > self.SECRET_SHOP_EXCLUSION_RADIUS then
					seen[entityIndex] = true
					Add(entity, "lane", self.LANE_SHOP_RADIUS)
				end
			end
		end
	end
	return anchors
end

function XHSBotEconomy:GetCurrentShopKind(hero, shop)
	if not IsValidEntityHandle(hero) then
		return nil, math.huge, "hero unavailable"
	end
	shop = tostring(shop or "home")
	local origin = hero:GetAbsOrigin()
	local castleShop = Entities:FindByName(nil, "castle_shop")
	if shop ~= "secret" and IsValidEntityHandle(castleShop)
		and (origin - castleShop:GetAbsOrigin()):Length2D()
			<= self.SECRET_SHOP_EXCLUSION_RADIUS then
		return nil,
			(origin - castleShop:GetAbsOrigin()):Length2D(),
			"inside secret-shop exclusion"
	end
	local nearestDistance = math.huge
	for _, anchor in ipairs(self:GetShopAnchors(shop)) do
		local distance = (origin - anchor.position):Length2D()
		nearestDistance = math.min(nearestDistance, distance)
		if distance <= anchor.radius then
			return anchor.kind, distance, nil
		end
	end
	return nil, nearestDistance, "outside required-shop range"
end

function XHSBotEconomy:IsAtRequiredShop(hero, shop)
	local shopKind = self:GetCurrentShopKind(hero, shop)
	return shopKind ~= nil
end

function XHSBotEconomy:GetShopAnchor(shop, hero)
	local anchors = self:GetShopAnchors(shop)
	if #anchors <= 0 then return nil end
	if not IsValidEntityHandle(hero) then
		return CopyPosition(anchors[1].position)
	end
	local origin = hero:GetAbsOrigin()
	local best = anchors[1]
	local bestDistance = (origin - best.position):Length2D()
	for index = 2, #anchors do
		local distance = (origin - anchors[index].position):Length2D()
		if distance < bestDistance then
			best = anchors[index]
			bestDistance = distance
		end
	end
	return CopyPosition(best.position)
end

function XHSBotEconomy:ClearShoppingGoal(record, itemName)
	if type(record) ~= "table" or type(record.shopping_goal) ~= "table" then return end
	if itemName == nil or record.shopping_goal.item == itemName then
		local wasEmergency =
			record.shopping_goal.emergency_health_resupply == true
		record.shopping_goal = nil
		if wasEmergency then
			record.emergency_health_resupply_active = false
			record.emergency_health_resupply_cleared_at =
				GameRules ~= nil and GameRules:GetGameTime() or 0
			record.team_director_replan_requested = true
		end
	end
end

function XHSBotEconomy:SetShoppingGoal(record, entry, anchor, now, urgent, reason)
	local existing = type(record.shopping_goal) == "table"
		and record.shopping_goal or nil
	local emergencyHealth = entry.consumable == "health" and urgent == true
	local continuingEmergency = emergencyHealth
		and existing ~= nil
		and existing.item == entry.name
		and existing.emergency_health_resupply == true
	local goalAnchor = continuingEmergency and existing.anchor or anchor
	local startedAt = continuingEmergency
		and existing.emergency_started_at or now
	record.shopping_goal = {
		item = entry.name,
		shop = tostring(entry.shop or "home"),
		anchor = CopyPosition(goalAnchor),
		requested_at = existing ~= nil and existing.item == entry.name
			and existing.requested_at or now,
		urgent = urgent == true,
		force_home = continuingEmergency and existing.force_home == true or false,
		emergency_health_resupply = emergencyHealth,
		emergency_started_at = emergencyHealth and startedAt or nil,
		reason = tostring(reason or ""),
	}
	if emergencyHealth then
		if not continuingEmergency then
			record.emergency_health_resupply_count =
				(record.emergency_health_resupply_count or 0) + 1
			record.team_director_replan_requested = true
		end
		record.emergency_health_resupply_active = true
		record.emergency_health_resupply_started_at = startedAt
		record.emergency_health_resupply_reason = tostring(reason or "")
	end
end

function XHSBotEconomy:GetEmergencyHealthShopAnchor(hero, forceHome)
	if forceHome == true then return self:GetShopAnchor("base", hero) end
	if not IsValidEntityHandle(hero) then return self:GetShopAnchor("base", hero) end

	local origin = hero:GetAbsOrigin()
	local fort = GetFort()
	local fortPosition = IsValidEntityHandle(fort) and fort:GetAbsOrigin() or nil
	local heroFortDistance = fortPosition ~= nil
		and (origin - fortPosition):Length2D() or math.huge
	local best = nil
	local bestDistance = math.huge
	for _, shop in ipairs(self:GetShopAnchors("home")) do
		local shopFortDistance = fortPosition ~= nil
			and (shop.position - fortPosition):Length2D() or 0
		local distance = (origin - shop.position):Length2D()
		-- An emergency resupply may use a lane shop only when it is genuinely
		-- behind the bot. This prevents "nearest shop" from sending a dying hero
		-- farther down the threatened lane.
		if shopFortDistance <= heroFortDistance + 100 and distance < bestDistance then
			best = shop.position
			bestDistance = distance
		end
	end
	return CopyPosition(best or self:GetShopAnchor("base", hero))
end

function XHSBotEconomy:ScheduleEmergencyHealthResupply(
	hero,
	record,
	difficulty,
	reason,
	forceHomeOverride
)
	if not IsValidEntityHandle(hero) or not hero:IsAlive()
		or type(record) ~= "table" then
		return false
	end
	local now = GameRules:GetGameTime()
	local finalWave = CustomTimers ~= nil and CustomTimers.proc_final_wave == true
	local forceHome = forceHomeOverride == true
		or record.base_threat_active == true or finalWave
	local anchor = self:GetEmergencyHealthShopAnchor(hero, forceHome)
	if anchor == nil then return false end
	local entry = XHSBotItemCatalog:CopyEntry("item_health_potion")
	if type(entry) ~= "table" then return false end
	entry.shop = "home"
	self:SetShoppingGoal(
		record,
		entry,
		anchor,
		now,
		true,
		reason or "no health potions remaining"
	)
	record.shopping_goal.force_home = forceHome
	if forceHome then
		record.shopping_goal.anchor = CopyPosition(
			self:GetShopAnchor("base", hero) or anchor
		)
	end
	record.next_economy_think = 0
	return true
end

function XHSBotEconomy:RefreshEmergencyHealthResupply(hero, record, difficulty)
	if not IsValidEntityHandle(hero) or not hero:IsAlive()
		or type(record) ~= "table" then
		return false
	end
	local _, activeCharges = self:GetInventoryTotals(
		hero,
		"item_health_potion",
		self.ACTIVE_LAST_SLOT
	)
	local _, carriedCharges = self:GetInventoryTotals(
		hero,
		"item_health_potion",
		self.INVENTORY_LAST_SLOT
	)
	local _, totalCharges = self:GetInventoryTotals(hero, "item_health_potion")
	record.health_potion_active_charges = activeCharges
	record.health_potion_carried_charges = carriedCharges
	record.health_potion_total_charges = totalCharges
	record.health_potion_charges = carriedCharges
	if carriedCharges > 0 then
		if record.emergency_health_resupply_active == true
			or type(record.shopping_goal) == "table"
				and record.shopping_goal.emergency_health_resupply == true then
			self:ClearShoppingGoal(record, "item_health_potion")
		end
		if activeCharges <= 0 then
			-- A carried backpack potion is recoverable without travelling, but
			-- inventory optimization must run now rather than after the normal
			-- economy cadence.
			record.next_economy_think = 0
		end
		return false
	end
	if totalCharges > 0 then
		return self:ScheduleEmergencyHealthResupply(
			hero,
			record,
			difficulty,
			"health potions stranded in stash",
			true
		)
	end
	if type(record.shopping_goal) == "table"
		and record.shopping_goal.emergency_health_resupply == true then
		local finalWave =
			CustomTimers ~= nil and CustomTimers.proc_final_wave == true
		local mustForceHome = record.base_threat_active == true or finalWave
		if mustForceHome and record.shopping_goal.force_home ~= true then
			local baseAnchor = self:GetShopAnchor("base", hero)
			if baseAnchor ~= nil then
				record.shopping_goal.anchor = CopyPosition(baseAnchor)
				record.shopping_goal.force_home = true
				record.shopping_goal.reason =
					"emergency health resupply forced to base"
				record.emergency_health_resupply_reason =
					record.shopping_goal.reason
				record.team_director_replan_requested = true
			end
		end
		record.emergency_health_resupply_active = true
		return true
	end

	local healthRatio = hero:GetHealth() / math.max(1, hero:GetMaxHealth())
	local threshold = tonumber(
		difficulty and difficulty.emergency_health_resupply_threshold
	) or 0.70
	local threat = math.max(0, tonumber(record.combat_threat) or 0)
	local recentDamage = math.max(0, tonumber(record.recent_damage_ratio) or 0)
	local focused = math.max(0, tonumber(record.focused_by_count) or 0)
	local underPressure = threat >= 0.42
		or recentDamage >= 0.05
		or focused >= 1
		or record.was_in_active_danger == true
	if healthRatio <= threshold or underPressure then
		return self:ScheduleEmergencyHealthResupply(
			hero,
			record,
			difficulty,
			underPressure
				and "no health potions under combat pressure"
				or "no health potions below safe reserve"
		)
	end
	return false
end

function XHSBotEconomy:SetStashCollectionGoal(record, hero, now)
	if type(record.shopping_goal) == "table"
		and record.shopping_goal.emergency_health_resupply == true then
		return false
	end
	local stashCount = self:GetStashItemCount(hero)
	if stashCount <= 0 then
		if type(record.shopping_goal) == "table"
			and record.shopping_goal.inventory_logistics == true then
			record.shopping_goal = nil
		end
		record.stash_reviewed_signature = nil
		return false
	end
	local anchor = self:GetShopAnchor("base")
	if anchor == nil then return false end
	local signature = self:GetStashSignature(hero)
	local hasFreeCarriedSlot =
		self:FindFreeSlot(hero, 0, self.INVENTORY_LAST_SLOT) ~= nil
	local hasAnkh = self:FindStashItemSlot(hero, self.ANKH_ITEM_NAME) ~= nil
	local priorityItem = self:GetPriorityStashItem(hero)
	local reviewed = tostring(record.stash_reviewed_signature or "") == signature
	local needsReview = not reviewed and (
		priorityItem ~= nil
		or stashCount >= self.STASH_COLLECTION_THRESHOLD
	)

	-- With no carried slot, reaching home cannot reduce the stash count.
	-- The optimizer below may still swap a better stash item into an active
	-- slot, but the bot must not stay at or repeatedly return to the fountain
	-- for the unchanged lower-value remainder.
	if not hasFreeCarriedSlot and self:IsAtRequiredShop(hero, "base") then
		if type(record.shopping_goal) == "table"
			and record.shopping_goal.inventory_logistics == true then
			record.shopping_goal = nil
		end
		return false
	end
	if not hasFreeCarriedSlot and not hasAnkh and not needsReview then
		if type(record.shopping_goal) == "table"
			and record.shopping_goal.inventory_logistics == true then
			record.shopping_goal = nil
		end
		return false
	end

	local forceHome = hasAnkh or stashCount >= self.STASH_COLLECTION_THRESHOLD
	local existing = type(record.shopping_goal) == "table"
		and record.shopping_goal.inventory_logistics == true
		and record.shopping_goal or nil
	record.shopping_goal = {
		item = hasAnkh and self.ANKH_ITEM_NAME
			or priorityItem
			or "stash_pickup",
		shop = "home",
		anchor = CopyPosition(anchor),
		requested_at = existing ~= nil and existing.requested_at or now,
		urgent = forceHome,
		force_home = forceHome,
		inventory_logistics = true,
		reason = hasAnkh and "equip reincarnation charge"
			or stashCount >= self.STASH_CAPACITY and "stash full"
			or priorityItem ~= nil and "equip priority stash item"
			or "collect purchased items",
	}
	return forceHome
end

function XHSBotEconomy:CanPurchaseNow(playerID, hero)
	if not IsValidEntityHandle(hero) or not hero:IsAlive() then return false, "hero unavailable" end
	if GameRules:IsGamePaused() then return false, "game paused" end
	if CustomTimers ~= nil and CustomTimers.timers_paused == 1 then
		return false, "shop disabled by game flow"
	end
	if IsPlayerXHSReincarnating ~= nil and IsPlayerXHSReincarnating(playerID) then
		return false, "reincarnation inventory locked"
	end
	if IsHeroOptionalEventTomeLocked ~= nil and IsHeroOptionalEventTomeLocked(hero) then
		return false, "optional event inventory locked"
	end
	return PlayerResource ~= nil
		and PlayerResource:IsValidPlayerID(playerID), "invalid player"
end

function XHSBotEconomy:CanPurchaseTomesNow(playerID, hero)
	if not IsValidEntityHandle(hero) or not hero:IsAlive() then
		return false, "hero unavailable"
	end
	if GameRules:IsGamePaused() then return false, "game paused" end
	if IsPlayerXHSReincarnating ~= nil and IsPlayerXHSReincarnating(playerID) then
		return false, "reincarnation inventory locked"
	end
	if IsHeroOptionalEventTomeLocked ~= nil and IsHeroOptionalEventTomeLocked(hero) then
		return false, "optional event tome locked"
	end
	if IsTomePurchaseGloballyLocked ~= nil and IsTomePurchaseGloballyLocked() then
		return false, "tomes globally locked"
	end
	return PlayerResource ~= nil
		and PlayerResource:IsValidPlayerID(playerID), "invalid player"
end

function XHSBotEconomy:ResolvePendingPurchase(hero, record)
	local pending = record.pending_item_purchase
	if type(pending) ~= "table" then return nil end

	local unitsAfter, chargesAfter = self:GetEntryInventoryTotals(hero, {
		name = pending.name,
		completion_names = pending.completion_names,
	})
	if unitsAfter > (pending.units_before or 0)
		or chargesAfter > (pending.charges_before or 0) then
		record.items_purchased = (record.items_purchased or 0) + 1
		record.last_item_action = "buy:" .. pending.name
		record.last_item_rejection = nil
		record.pending_item_purchase = nil
		return "purchased"
	end

	local now = GameRules:GetGameTime()
	if now - (pending.issued_at or now) < 0.85 then return "pending" end
	record.last_item_rejection = "engine rejected " .. pending.name
	record.item_retry_after = record.item_retry_after or {}
	record.item_retry_after[pending.name] = now + (pending.retry_interval or 15)
	record.pending_item_purchase = nil
	self:ClearShoppingGoal(record, pending.name)
	return "rejected"
end

function XHSBotEconomy:TryPurchaseBuildEntry(
	playerID,
	hero,
	entry,
	difficulty,
	record,
	snapshot,
	plan
)
	local needsEntry, unitsBefore, chargesBefore = self:NeedsBuildEntry(hero, entry, difficulty)
	if not needsEntry then
		self:ClearShoppingGoal(record, entry.name)
		return "not_needed"
	end

	local now = GameRules:GetGameTime()
	record.item_retry_after = record.item_retry_after or {}
	if now < (record.item_retry_after[entry.name] or 0) then return "wait" end
	local declaredShop = tostring(entry.shop or "home")
	local requiredShop = self:GetRequiredShop(entry)
	if declaredShop ~= requiredShop then
		record.last_item_shop_correction = tostring(entry.name) .. ":"
			.. declaredShop .. "->" .. requiredShop
	end
	entry.shop = requiredShop

	local canPurchase, reason = self:CanPurchaseNow(playerID, hero)
	if not canPurchase then
		self:ClearShoppingGoal(record, entry.name)
		record.last_item_rejection = reason
		return "wait"
	end
	if self:GetGold(playerID) < math.max(0, tonumber(entry.cost) or 0) then
		self:ClearShoppingGoal(record, entry.name)
		record.last_item_rejection = "cannot afford " .. entry.name
		return "wait"
	end
	if not self:IsAtRequiredShop(hero, requiredShop) then
		local shop = requiredShop
		local anchor = self:GetShopAnchor(shop, hero)
		if anchor ~= nil then
			local urgentHealthRestock = entry.consumable == "health"
				and chargesBefore <= 0
			self:SetShoppingGoal(
				record,
				entry,
				anchor,
				now,
				urgentHealthRestock,
				urgentHealthRestock
					and "no health potions remaining"
					or "scheduled build restock"
			)
			record.last_item_rejection = "travelling to " .. shop .. " shop for " .. entry.name
			return "travel"
		end
		self:ClearShoppingGoal(record, entry.name)
		if shop == "secret" then
			-- castle_shop is removed by normal XHS game flow. Never reserve
			-- thousands of gold for an unreachable shop.
			record.last_item_rejection = "secret shop unavailable"
		else
			record.last_item_rejection = "not in home shop range"
		end
		record.item_retry_after[entry.name] = now + (difficulty.shop_retry_interval or 15)
		return "wait"
	end
	if entry.consumable ~= nil then
		local anchor = self:GetShopAnchor(requiredShop, hero)
		local urgentHealthRestock = entry.consumable == "health"
			and chargesBefore <= 0
		if anchor ~= nil then
			self:SetShoppingGoal(
				record,
				entry,
				anchor,
				now,
				urgentHealthRestock,
				urgentHealthRestock
					and "no health potions remaining"
					or "finish consumable restock"
			)
		end
	else
		self:ClearShoppingGoal(record, entry.name)
	end
	local retired = nil
	if not self:HasFreeInventorySlot(hero)
		and unitsBefore <= 0
		and entry.combines ~= true then
		local stashFull =
			self:GetStashItemCount(hero) >= self.STASH_CAPACITY
		if snapshot == nil or plan == nil then
			self:ClearShoppingGoal(record, entry.name)
			record.inventory_full_events = (record.inventory_full_events or 0) + 1
			record.last_item_rejection = stashFull
				and "stash full; collect purchases before buying"
				or "inventory full; planner replacement unavailable"
			record.item_retry_after[entry.name] =
				now + (difficulty.shop_retry_interval or 15)
			return "wait"
		end
		local replacementReason = nil
		retired, replacementReason = self:PrepareInventoryReplacement(
			hero,
			entry,
			snapshot,
			plan,
			record,
			now
		)
		if retired == nil then
			self:ClearShoppingGoal(record, entry.name)
			record.inventory_full_events = (record.inventory_full_events or 0) + 1
			record.last_item_rejection = stashFull
				and "stash full; " .. tostring(replacementReason)
				or "inventory full; " .. tostring(replacementReason)
			record.item_retry_after[entry.name] = now + math.min(
				5,
				difficulty.shop_retry_interval or 15
			)
			return "wait"
		end
	end
	local purchased, purchaseResult, purchaseShopKind, purchaseShopDistance =
		self:GrantPurchasedItem(
		playerID,
		hero,
		entry,
		unitsBefore,
		chargesBefore,
		requiredShop
	)
	record.last_purchase_item = tostring(entry.name)
	record.last_purchase_shop = requiredShop
	record.last_purchase_shop_kind = tostring(purchaseShopKind or "")
	record.last_purchase_shop_distance = purchaseShopDistance ~= nil
		and purchaseShopDistance < math.huge
		and math.floor(purchaseShopDistance) or -1
	record.last_purchase_at = now
	if not purchased then
		if string.find(
			tostring(purchaseResult),
			"shop invariant rejected",
			1,
			true
		) ~= nil then
			record.shop_purchase_violation_count =
				(record.shop_purchase_violation_count or 0) + 1
		end
		if retired ~= nil and not self:RestoreRetiredItem(hero, retired) then
			record.replacement_restore_failures =
				(record.replacement_restore_failures or 0) + 1
			purchaseResult = tostring(purchaseResult)
				.. "; retired item restore failed"
		end
		self:ClearShoppingGoal(record, entry.name)
		record.last_item_rejection = purchaseResult
		record.item_retry_after[entry.name] = now + (difficulty.shop_retry_interval or 15)
		return "wait"
	end

	record.items_purchased = (record.items_purchased or 0) + 1
	record.item_gold_spent = (record.item_gold_spent or 0)
		+ math.max(0, tonumber(entry.cost) or 0)
	record.shop_purchase_counts = record.shop_purchase_counts or {}
	record.shop_purchase_counts[purchaseShopKind] =
		(record.shop_purchase_counts[purchaseShopKind] or 0) + 1
	record.last_item_rejection = nil
	if retired ~= nil then
		self:CommitInventoryReplacement(playerID, retired, entry, record)
	else
		record.last_item_action = "buy:" .. entry.name
	end
	self:ClearShoppingGoal(record, entry.name)
	self:SetStashCollectionGoal(record, hero, now)
	return "purchased"
end

function XHSBotEconomy:BuyTomes(playerID, hero, reserveGold, difficulty, maximumCount)
	if not IsValidEntityHandle(hero) or not hero:IsAlive() then return 0 end
	local tomeEntry = XHSBotItemCatalog:GetTome("item_tome_small")
	local tomeCostEach = tomeEntry ~= nil and math.max(
		0,
		tonumber(tomeEntry.cost) or 0
	) or 0
	local tomeStatsEach = tomeEntry ~= nil
		and tomeEntry.stats ~= nil
		and math.max(0, tonumber(tomeEntry.stats.stat_bonus) or 0)
		or 0
	if tomeEntry == nil
		or tomeEntry.bot_transaction ~= "direct_stats"
		or tomeCostEach <= 0
		or tomeStatsEach <= 0 then
		return 0
	end
	-- Farm Event intentionally pauses normal shop/logistics flow while keeping
	-- -bt and the HUD tome button legal.  Tome validation must therefore use
	-- the authoritative tome locks, not CanPurchaseNow's shop-pause guard.
	local canPurchase = self:CanPurchaseTomesNow(playerID, hero)
	if not canPurchase then return 0 end

	local spendableGold = math.max(0, self:GetGold(playerID) - math.max(0, reserveGold or 0))
	local count = math.floor(spendableGold / tomeCostEach)
	count = math.min(count, math.max(0, tonumber(difficulty.max_tomes_per_think) or count))
	count = math.min(count, math.max(0, tonumber(maximumCount) or count))
	if count <= 0 then return 0 end
	if hero.IncrementAttributes == nil then
		return 0
	end

	-- Mirror the legal player transaction without routing the bot through
	-- player-facing notifications or persistent tome-stat recording.
	local tomeCost = count * tomeCostEach
	local goldBefore = self:GetGold(playerID)
	if not self:WithdrawGold(playerID, tomeCost) then return 0 end
	if self:GetGold(playerID) ~= goldBefore - tomeCost then
		self:SetSynchronizedGold(playerID, goldBefore)
		return 0
	end
	local granted = pcall(function()
		hero:IncrementAttributes(count * tomeStatsEach, {
			record_stats = tomeEntry.bot_record_stats == true,
			play_sound = false,
		})
	end)
	if not granted then
		self:RefundGold(playerID, tomeCost)
		return 0
	end
	return count
end

function XHSBotEconomy:Think(playerID, hero, record, profile, difficulty)
	if not IsValidEntityHandle(hero) then return nil end
	profile = profile or XHSBotHeroProfiles:Get(hero:GetUnitName())
	difficulty = difficulty or XHSBotConfig:GetDifficulty(record.difficulty)
	if profile == nil then return nil end

	local assignment = XHSBotTeamDirector ~= nil
		and XHSBotTeamDirector.GetAssignment ~= nil
		and XHSBotTeamDirector:GetAssignment(playerID)
		or nil
	local muradinSurvivalActive = XHSBotEncounterDirector ~= nil
		and XHSBotEncounterDirector.IsMuradinSurvivalActive ~= nil
		and XHSBotEncounterDirector:IsMuradinSurvivalActive(hero)
	local encounter = muradinSurvivalActive
		and XHSBotEncounterDirector.Build ~= nil
		and XHSBotEncounterDirector:Build(playerID, hero, record, assignment)
		or nil
	local noCombatEncounter = encounter ~= nil and encounter.no_combat == true
	record.economy_encounter_mode = encounter and encounter.id or ""
	record.economy_no_combat = noCombatEncounter
	if noCombatEncounter then
		-- Muradin survival owns movement immediately, even if a shop trip or
		-- recipe verification was active on the preceding tick. Only personal
		-- emergency defense and urgent health recovery may consume this tick.
		self:ClearShoppingGoal(record)
		record.defer_potion_for_spell_now = false
		if self:UseEmergencyTacticalItems(hero, record) then return "item" end
		if self:UseConsumables(
			hero,
			record,
			difficulty,
			profile,
			encounter
		) then
			return "healing"
		end
		return nil
	end

	local now = GameRules:GetGameTime()
	self:RefreshEmergencyHealthResupply(hero, record, difficulty)
	local pendingResult = self:ResolvePendingPurchase(hero, record)
	if pendingResult == "pending" or pendingResult == "purchased" then
		return "shopping"
	end

	record.next_economy_think = record.next_economy_think or 0
	if now < record.next_economy_think then return nil end
	record.next_economy_think = now + (difficulty.economy_think_interval or 1.5)
	record.minimum_order_interval = difficulty.min_order_interval
	record.max_orders_per_second = difficulty.max_orders_per_second

	local atHomeShop = self:IsAtRequiredShop(hero, "base")
	if atHomeShop and self:GetStashItemCount(hero) > 0 then
		self:CollectStashItems(hero, record)
	end
	record.stash_item_count = self:GetStashItemCount(hero)
	record.ankh_charges = self:GetAnkhCharges(hero)
	local stashTravelRequired = self:SetStashCollectionGoal(record, hero, now)
	if stashTravelRequired and not atHomeShop then
		return "shopping"
	end

	record.ability_points_spent = (record.ability_points_spent or 0)
		+ self:SpendAbilityPoints(hero, profile)
	local snapshot = self:BuildPlannerSnapshot(playerID, hero, record)
	snapshot.ankh_charges = record.ankh_charges
	local plan = XHSBotItemPlanner:Plan(snapshot, profile, difficulty)
	plan = self:StabilizePlan(record, plan, now)
	self:RecordPlan(record, snapshot, plan)
	record.defer_potion_for_spell_now = false
	if self:UseEmergencyTacticalItems(hero, record) then return "item" end
	local inventoryOptimized =
		self:OptimizeActiveInventory(hero, record, snapshot, plan)
	if atHomeShop then
		-- A swap may leave a lower-priority item in the stash. Remember the
		-- exact post-optimization contents so unchanged reserve items do not
		-- create an endless home-shop assignment.
		record.stash_reviewed_signature = self:GetStashSignature(hero)
	end
	if inventoryOptimized then
		return "inventory"
	end
	if self:UseConsumables(hero, record, difficulty, profile, encounter) then
		return "healing"
	end
	if record.defer_potion_for_spell_now == true then return nil end
	if self:UseTacticalItems(hero, record, encounter) then return "item" end
	if snapshot.in_farm_event and plan.tome_allowance > 0 then
		-- Farm Event intentionally converts its isolated combat income into
		-- stats, but the planner still caps each transaction.
		local farmTomes = self:BuyTomes(
			playerID,
			hero,
			0,
			difficulty,
			plan.tome_allowance
		)
		if farmTomes > 0 then
			record.tomes_bought = (record.tomes_bought or 0) + farmTomes
			record.last_item_action = "farm_event_tomes:" .. tostring(farmTomes)
			return "shopping"
		end
	end
	local buildResult = self:PurchasePlan(
		playerID,
		hero,
		difficulty,
		record,
		snapshot,
		plan
	)
	if buildResult == "purchased" then
		return "shopping"
	end
	if buildResult == "travel" then
		-- Travel must reach the Brain on this same tick so the newly forced
		-- emergency assignment can issue movement immediately. It also prevents
		-- a tome purchase from consuming the potion reserve while en route.
		return "travel"
	end

	local bought = self:BuyTomes(
		playerID,
		hero,
		plan.reserve_gold,
		difficulty,
		plan.tome_allowance
	)
	if bought > 0 then
		record.tomes_bought = (record.tomes_bought or 0) + bought
		record.last_item_action = "buy_tomes:" .. tostring(bought)
		return "shopping"
	end
	return nil
end

return XHSBotEconomy
