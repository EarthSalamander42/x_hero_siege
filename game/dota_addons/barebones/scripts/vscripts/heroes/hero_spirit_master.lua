require("libraries/timers")

function SpiritRemnants(keys)
local caster = keys.caster
local caster_origin = caster:GetAbsOrigin()
local direction = (keys.target_points[1] - caster_origin):Normalized()
local ability_level = keys.ability:GetLevel()
local duration = keys.Duration
direction.z = 0

local ward = {}
ward[1] = { 55, 110, 0 }	-- North-East
ward[2] = { -55, 110, 0 }	-- North-West
ward[3] = { -110, 0, 0 }	-- West
ward[4] = { 110, 0, 0 }		-- East
ward[5] = { -55, -110, 0 }	-- South-West
ward[6] = { 55, -110, 0 }	-- South-East

	for count = 1, 6 do
		local plague_ward_unit = CreateUnitByName("npc_dota_stormspirit_remnant", keys.target_points[1] + Vector( ward[count][1], ward[count][2], ward[count][3]), false, caster, caster, caster:GetTeam())
		plague_ward_unit:SetForwardVector(direction)
		plague_ward_unit:AddNewModifier(caster, nil, "modifier_phased", {})
	end
end

function static_remnant_init(keys)
local caster = keys.caster
local target = caster:GetAbsOrigin()
local ability = keys.ability
local model_name = caster:GetModelName()
local dummyModifierName = "modifier_static_remnant_dummy_datadriven"
local dummyFreezeModifierName = "modifier_static_remnant_dummy_freeze_datadriven"
local remnant_timer = 0.0
local remnant_interval_check = 0.1
local delay = ability:GetLevelSpecialValueFor( "static_remnant_delay", ability:GetLevel() - 1 )
local trigger_radius = ability:GetLevelSpecialValueFor( "static_remnant_radius", ability:GetLevel() - 1 )
local damage_radius = ability:GetLevelSpecialValueFor( "static_remnant_damage_radius", ability:GetLevel() - 1 )
local ability_damage = ability:GetLevelSpecialValueFor( "static_remnant_damage", ability:GetLevel() - 1 )
local ability_damage_type = ability:GetAbilityDamageType()
local ability_duration = ability:GetDuration()

local ward = {}
ward[1] = { 100, 200, 0 }	-- North-East
ward[2] = { -100, 200, 0 }	-- North-West
ward[3] = { -200, 0, 0 }	-- West
ward[4] = { 200, 0, 0 }		-- East
ward[5] = { -100, -200, 0 }	-- South-West
ward[6] = { 100, -200, 0 }	-- South-East

	-- Dummy creation
	for count = 1, 6 do
		local dummy = CreateUnitByName("npc_dota_storm_spirit_remnant", target + Vector( ward[count][1], ward[count][2], ward[count][3]), false, caster, nil, caster:GetTeamNumber())
		ability:ApplyDataDrivenModifier( caster, dummy, dummyModifierName, {} )
		dummy:SetModel(caster:GetModelName())
		dummy:SetOriginalModel(caster:GetModelName())

		Timers:CreateTimer(delay/1.5, function()
			if not dummy:HasModifier(dummyFreezeModifierName) then
				ability:ApplyDataDrivenModifier(caster, dummy, dummyFreezeModifierName, {})
			end
		end)

		Timers:CreateTimer(delay, function()
			-- Check in aoe
			local units = FindUnitsInRadius(caster:GetTeamNumber(), dummy:GetAbsOrigin(), caster, trigger_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false)

			-- If there is at least one unit, explode
			if #units > 0 then
				for k, v in pairs(units) do
					local damageTable = {
						victim = v,
						attacker = caster,
						damage = ability_damage,
						damage_type = ability_damage_type
					}
					ApplyDamage( damageTable )
				end

				if not dummy:IsNull() then
					EmitSoundOn("Hero_StormSpirit.StaticRemnantExplode", dummy)
					dummy:RemoveSelf()
				end	
				return nil
			end

			-- Update timer
			remnant_timer = remnant_timer + remnant_interval_check /6	-- 6 Remnants, so the timer goes 6 times faster, so we divide by 6

			-- Check if timer should be expired
			if remnant_timer >= ability_duration then
				if not dummy:IsNull() then
					EmitSoundOn("Hero_StormSpirit.StaticRemnantExplode", dummy)
					dummy:RemoveSelf()
				end			
				return nil
			else
				return remnant_interval_check
			end
		end)
	end
end

function overload_check_order(keys)
	local caster = keys.caster
	local ability = keys.ability
	if caster:GetUnitName() == "npc_dota_hero_storm_spirit" then
		ListenToGameEvent("dota_player_used_ability", function(event)
			local ply = caster:GetPlayerOwner()
			-- Check if player existed
			if ply then
				local hero = ply:GetAssignedHero()
				-- Check if it is corrent hero
				if hero == caster then
					-- Check if ability on cast bar is casted
					local ability_count = caster:GetAbilityCount()
					for i = 0, (ability_count - 1) do
						local ability_at_slot = caster:GetAbilityByIndex(i)
						if ability_at_slot and ability_at_slot:GetAbilityName() == event.abilityname then
							ability:ApplyDataDrivenModifier(caster, caster, "modifier_overload_damage_datadriven", {})
							break
						end
					end
				end
			end	
		end, nil)
	end
end

particle_names = {base = "particles/units/heroes/hero_stormspirit/stormspirit_base_attack.vpcf"}
projectile_speeds = {base = 500}

-- this finds the units particle infomation, if they're melee then it'll just use lunas default glaives
-- the results are stored in partile_names and projectile_speeds so it doesn't have to reload the KV file each time
function findProjectileInfo(class_name)
	if particle_names[class_name] ~= nil then
		return particle_names[class_name], projectile_speeds[class_name]
	end

	kv_heroes = LoadKeyValues("scripts/npc/npc_heroes.txt")
	kv_hero = kv_heroes[class_name]

	if kv_hero["ProjectileModel"] ~= nil and kv_hero["ProjectileModel"] ~= "" then
		particle_names[class_name] = kv_hero["ProjectileModel"]
		projectile_speeds[class_name] = kv_hero["ProjectileSpeed"]
	else
		particle_names[class_name] = particle_names["base"]
		projectile_speeds[class_name] = projectile_speeds["base"]
	end

	return particle_names[class_name], projectile_speeds[class_name]
end

function moon_glaive_start_create_dummy(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	-- Create the dummy unit which keeps track of bounces
	local dummy = CreateUnitByName( "npc_dummy_unit", target:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber() )
	dummy:AddAbility("holdout_overload_bounce")
	local dummy_ability =  dummy:FindAbilityByName("holdout_overload_bounce")
	local overload =  caster:FindAbilityByName("holdout_overload")
	dummy_ability:SetLevel(overload:GetLevel())
	dummy_ability:ApplyDataDrivenModifier( caster, dummy, "modifier_moon_glaive_dummy_unit", {} )

	-- Ability variables
	dummy_ability.damage = caster:GetAverageTrueAttackDamage(caster)
	dummy_ability.bounceTable = {}
	dummy_ability.bounceCount = 0
	dummy_ability.maxBounces = ability:GetLevelSpecialValueFor("bounces", ability_level)
	dummy_ability.bounceRange = ability:GetLevelSpecialValueFor("range", ability_level) 
	dummy_ability.dmgMultiplier = ability:GetLevelSpecialValueFor("damage_reduction_percent", ability_level) / 100
	dummy_ability.original_ability = ability

	dummy_ability.particle_name, dummy_ability.projectile_speed = findProjectileInfo(caster:GetClassname())
	dummy_ability.projectileFrom = target
	dummy_ability.projectileTo = nil

	-- Find the closest target that fits the search criteria
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local bounce_targets = FindUnitsInRadius(caster:GetTeamNumber(), dummy:GetAbsOrigin(), nil, dummy_ability.bounceRange, iTeam, iType, iFlag, FIND_CLOSEST, false)

	-- It has to be a target different from the current one
	for _,v in pairs(bounce_targets) do
		if v ~= target then
			dummy_ability.projectileTo = v
			break
		end
	end

	-- If we didnt find a new target then kill the dummy and end the function
	if dummy_ability.projectileTo == nil then
		killDummy(dummy, dummy)
	else
	-- Otherwise continue with creating a bounce projectile
		dummy_ability.bounceCount = dummy_ability.bounceCount + 1
		local info = {
        Target = dummy_ability.projectileTo,
        Source = dummy_ability.projectileFrom,
        EffectName = dummy_ability.particle_name,
        Ability = dummy_ability,
        bDodgeable = false,
        bProvidesVision = false,
        iMoveSpeed = dummy_ability.projectile_speed,
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION
    	}
    	ProjectileManager:CreateTrackingProjectile( info )
    end
end

--[[Author: Pizzalol
	Date: 29.09.2015.
	Creates bounce projectiles to the nearest target if there is any]]
function moon_glaive_bounce( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	-- Initialize the damage table
	local damage_table = {}
	damage_table.attacker = caster:GetOwner()
	damage_table.victim = target
	damage_table.ability = ability.original_ability
	damage_table.damage_type = DAMAGE_TYPE_PHYSICAL
	damage_table.damage = ability.damage * (1 - ability.dmgMultiplier)

	ApplyDamage(damage_table)
	-- Save the new damage for future bounces
	ability.damage = damage_table.damage

	-- If we exceeded the bounce limit then remove the dummy and stop the function
	if ability.bounceCount >= ability.maxBounces then
		killDummy(caster,caster)
		return
	end

	-- Reset target data and find new targets
	ability.projectileFrom = ability.projectileTo
	ability.projectileTo = nil

	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local bounce_targets = FindUnitsInRadius(caster:GetTeamNumber(), target:GetAbsOrigin(), nil, ability.bounceRange, iTeam, iType, iFlag, FIND_CLOSEST, false)

	-- Find a new target that is not the current one
	for _,v in pairs(bounce_targets) do
		if v ~= target then
			ability.projectileTo = v
			break
		end
	end

	-- If we didnt find a new target then kill the dummy
	if ability.projectileTo == nil then
		killDummy(caster, caster)
	else
	-- Otherwise increase the bounce count and create a new bounce projectile
		ability.bounceCount = ability.bounceCount + 1
		local info = {
        Target = ability.projectileTo,
        Source = ability.projectileFrom,
        EffectName = ability.particle_name,
        Ability = ability,
        bDodgeable = false,
        bProvidesVision = false,
        iMoveSpeed = ability.projectile_speed,
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION
    	}
    	ProjectileManager:CreateTrackingProjectile( info )
    end
end

function killDummy(caster, target)
	if caster:GetClassname() == "npc_dota_base_additive" then
		caster:RemoveSelf()
	elseif target:GetClassname() == "npc_dota_base_additive" then
		target:RemoveSelf()
	end
end

--[[
	Author: Cookies
	Date: 25.11.2016.
	Skin Changer: Swap hero, keeping all stats and abilities leveled up
]]
function SpiritSwapPhaseCast(keys)
local caster = keys.caster

	CURRENT_XP = caster:GetCurrentXP()
end

function SpiritSwap(keys)
local caster = keys.caster
local PlayerID = caster:GetPlayerID()
local gold = caster:GetGold()
local loc = caster:GetAbsOrigin()
local Strength = caster:GetBaseStrength()
local Intellect = caster:GetBaseIntellect()
local Agility = caster:GetBaseAgility()
local HP = caster:GetMaxHealth() * caster:GetHealthPercent() / 100
local Mana = caster:GetMaxMana() * caster:GetManaPercent() / 100
local AbPoints = caster:GetAbilityPoints()
local cooldowns_caster = {}

	if caster:GetUnitName() == "npc_dota_hero_storm_spirit" then
		hero = PlayerResource:ReplaceHeroWith( PlayerID, "npc_dota_hero_earth_spirit", gold, 0)
		local ability = hero:FindAbilityByName("holdout_spirit_str"):StartCooldown(20)
	elseif caster:GetUnitName() == "npc_dota_hero_earth_spirit" then
		hero = PlayerResource:ReplaceHeroWith( PlayerID, "npc_dota_hero_ember_spirit", gold, 0)
		local ability = hero:FindAbilityByName("holdout_spirit_agi"):StartCooldown(20)
	elseif caster:GetUnitName() == "npc_dota_hero_ember_spirit" then
		hero = PlayerResource:ReplaceHeroWith( PlayerID, "npc_dota_hero_storm_spirit", gold, 0)
		local ability = hero:FindAbilityByName("holdout_spirit_int"):StartCooldown(20)
	end

	for i = 0, 5 do 
	caster_ability = caster:GetAbilityByIndex(i)
	hero_ability = hero:GetAbilityByIndex(i)
		if IsValidEntity(caster_ability) then
			if i == 4 then -- Ignores Spirit Swap Ability
			else
				hero_ability:SetLevel(caster_ability:GetLevel())
			end
			cooldowns_caster[i] = caster_ability:GetCooldownTimeRemaining()
			hero_ability:StartCooldown(cooldowns_caster[i])
		end
	end

	local items = {}
	for i = 0, 8 do
		if caster:GetItemInSlot(i) ~= nil and caster:GetItemInSlot(i):GetName() ~= "item_classchange_reset" then
			itemCopy = CreateItem(caster:GetItemInSlot(i):GetName(), nil, nil)
			items[i] = itemCopy
		end
	end

	for i = 0, 8 do
		if items[i] ~= nil then
			hero:AddItem(items[i])
			items[i]:SetCurrentCharges(caster:GetItemInSlot(i):GetCurrentCharges())
		end
	end

	hero:AddExperience(CURRENT_XP, false, false)
	hero:SetAbsOrigin(loc)
	hero:SetBaseStrength(Strength)
	hero:SetBaseIntellect(Intellect)
	hero:SetBaseAgility(Agility)
	hero:SetHealth(HP)
	hero:SetMana(Mana)
	hero:SetAbilityPoints(AbPoints)

	Timers:CreateTimer(1.0, function()
		if not caster:IsNull() then
			UTIL_Remove(caster)
		end
	end)
end

function EnhancedSpirit(keys)
local caster = keys.caster
local ability = keys.ability

	if caster:GetUnitName() == "npc_dota_hero_storm_spirit" then
		caster:RemoveModifierByName("modifier_enhanced_spirit_earth")
		caster:RemoveModifierByName("modifier_enhanced_spirit_fire")
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_enhanced_spirit_storm", {})
	elseif caster:GetUnitName() == "npc_dota_hero_earth_spirit" then
		caster:RemoveModifierByName("modifier_enhanced_spirit_storm")
		caster:RemoveModifierByName("modifier_enhanced_spirit_fire")
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_enhanced_spirit_earth", {})
	elseif caster:GetUnitName() == "npc_dota_hero_ember_spirit" then
		caster:RemoveModifierByName("modifier_enhanced_spirit_storm")
		caster:RemoveModifierByName("modifier_enhanced_spirit_earth")
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_enhanced_spirit_fire", {})
	end
end
