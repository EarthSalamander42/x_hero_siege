require("libraries/timers")

function PowerMountPhaseCast(keys)
local caster = keys.caster

	StartAnimation(caster, {duration = 1.1, activity = ACT_DOTA_VICTORY, rate = 1.45})
end

function PowerMountCast(keys)
local caster = keys.caster
local ability = keys.ability
local sub_ability_name = keys.sub_ability_name
local main_ability_name = ability:GetAbilityName()

--	sub_ability_name:StartCooldown(10.0) Fix this
	caster:SwapAbilities(main_ability_name, sub_ability_name, false, true)
end

function DarkCleave(keys)
local caster = keys.caster
local target = keys.target
local modifier_dark_cleave = keys.modifier_dark_cleave
local ability = keys.ability
local ability_level = ability:GetLevel() - 1
local cooldown = ability:GetCooldown(ability_level)
local stacks = caster:GetLevel()
local bonus_damage = ability:GetLevelSpecialValueFor("bonus_damage", ability_level)
local radius = ability:GetSpecialValueFor("radius")
local cleave = ability:GetSpecialValueFor("cleave_pct")
local full_damage = caster:GetAverageTrueAttackDamage(caster) + bonus_damage * stacks -- 100 * caster Level
local cleave_pct = cleave * full_damage / 100

	print("radius/cleave:", radius, cleave)

    ability:StartCooldown(cooldown)
    caster:RemoveModifierByName(modifier_dark_cleave)
    ApplyDamage({attacker = caster, victim = target, ability = ability, damage = full_damage, damage_type = DAMAGE_TYPE_PHYSICAL})
    SendOverheadEventMessage(nil, OVERHEAD_ALERT_CRITICAL, target, full_damage, nil)

    Splash(keys)

    Timers:CreateTimer(cooldown, function()
        ability:ApplyDataDrivenModifier(caster, caster, modifier_dark_cleave, {})
    end)
end

function Instakill( keys )
local caster = keys.caster
local target = keys.target
local ability = keys.ability
local damage = 7777777

	SendOverheadEventMessage(nil, OVERHEAD_ALERT_DENY, target, damage, nil)
	ApplyDamage({attacker = caster, victim = target, ability = ability, damage = damage, damage_type = DAMAGE_TYPE_PHYSICAL})
end

function RequiemPhaseCast(keys)
local caster = keys.caster
	StartAnimation(caster, {duration = 1.67, activity = ACT_DOTA_VICTORY, rate = 1.15})
end

function RequiemCast(keys)
local caster = keys.caster
local ability = keys.ability
local ability_level = ability:GetLevel() - 1
local modifier_souls_counter = keys.modifier_souls_counter
local particle_caster = keys.particle_caster_souls
local particle_ground = keys.particle_caster_ground
local particle_lines = keys.particle_lines
local soul_conversion = ability:GetLevelSpecialValueFor("soul_conversion", ability_level)
local line_width_start = ability:GetLevelSpecialValueFor("line_width_start", ability_level)
local line_width_end = ability:GetLevelSpecialValueFor("line_width_end", ability_level)
local line_speed = ability:GetLevelSpecialValueFor("line_speed", ability_level)
local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
local caster_loc = caster:GetAbsOrigin()
local scepter_release_time = radius / line_speed
-- Get number of souls. Uses Necromastery's maximum soul amount instead of current souls for nonstandard heroes, like Rubick, pugna ward, or in Random OMG. (yeah, hardcoded, blah blah sue me)
local souls = caster:GetLevel()
local lines = math.floor(souls / soul_conversion) -- original is multiplied

	-- Sound and particle effects
	caster:EmitSound(keys.requiem_cast_sound)
	local pfx_caster = ParticleManager:CreateParticle(particle_caster, PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(pfx_caster, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(pfx_caster, 1, Vector(lines, 0, 0))
	ParticleManager:SetParticleControl(pfx_caster, 2, caster:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(pfx_caster)
	local pfx_ground = ParticleManager:CreateParticle(particle_ground, PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(pfx_caster, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(pfx_ground, 1, Vector(lines, 0, 0))
	ParticleManager:ReleaseParticleIndex(pfx_ground)
	local pfx_line

	-- Create projectiles
	local forward_vector = caster:GetForwardVector()
	local line_targets = {}
	local next_line_target
	local next_line_velocity
	local projectile_info
	local pfx_projectile
	for i = 0, (lines - 1) do

		-- Find points to fire projectiles at
		next_line_target = RotatePosition(caster_loc, QAngle(0, i * 360 / lines, 0), caster_loc + forward_vector * radius)
		line_targets[i] = next_line_target

		-- Calculate velocity from point vectors and speed
		next_line_velocity = (next_line_target - caster_loc):Normalized() * line_speed
		projectile_info = {
			Ability = ability,
			EffectName = "",
			vSpawnOrigin = caster_loc,
			fDistance = radius,
			fStartRadius = line_width_start,
			fEndRadius = line_width_end,
			Source = caster,
			bHasFrontalCone = false,
			bReplaceExisting = false,
			iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
			iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
			iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			bDeleteOnHit = false,
			vVelocity = next_line_velocity,
			bProvidesVision = false
		}

		-- Create the projectile
		ProjectileManager:CreateLinearProjectile(projectile_info)

		-- Create the particle
		pfx_line = ParticleManager:CreateParticle(particle_lines, PATTACH_ABSORIGIN, caster)
		ParticleManager:SetParticleControl(pfx_line, 0, caster:GetAbsOrigin())
		ParticleManager:SetParticleControl(pfx_line, 1, next_line_velocity)
		ParticleManager:SetParticleControl(pfx_line, 2, Vector(0, scepter_release_time, 0))
		ParticleManager:ReleaseParticleIndex(pfx_line)
	end
end

function RequiemProjectileHitOutward(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	-- Parameters
	local damage = ability:GetLevelSpecialValueFor("line_damage", ability_level)

	-- Apply enemy modifier
	ability:ApplyDataDrivenModifier(caster, target, modifier_enemy, {})

	-- Apply damage
	ApplyDamage({victim = target, attacker = caster, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL})
end


--[[
	Author: Cookies
	Date: 25.11.2016.
	Skin Changer: Swap hero, keeping all stats and abilities leveled up
]]

function SkinChangerPhaseCast(keys)
local caster = keys.caster
CURRENT_XP = caster:GetCurrentXP()

	StartAnimation(caster, {duration = 1.933, activity = ACT_DOTA_VICTORY, rate = 1.0})
end

function SkinChanger(keys)
local caster = keys.caster
local PlayerID = caster:GetPlayerID()
local gold = caster:GetGold()
local loc = caster:GetAbsOrigin()
local Strength = caster:GetBaseStrength()
local Intellect = caster:GetBaseIntellect()
local Agility = caster:GetBaseAgility()
local HP = caster:GetHealth()
local Mana = caster:GetMana()

	local hero = PlayerResource:ReplaceHeroWith(PlayerID, keys.HeroSwap, gold, 0)
	hero:GetAbilityByIndex(4):StartCooldown(60)
	hero:AddExperience(CURRENT_XP, false, false)
	hero:SetAbsOrigin(loc)
	hero:SetBaseStrength(Strength)
	hero:SetBaseIntellect(Intellect)
	hero:SetBaseAgility(Agility)
	hero:SetHealth(HP)
	hero:SetMana(Mana)

	local items = {}
	for i = 0, 8 do
		if caster:GetItemInSlot(i) and caster:GetItemInSlot(i):GetName() ~= "item_classchange_reset" then
			itemCopy = CreateItem(caster:GetItemInSlot(i):GetName(), nil, nil)
			items[i] = itemCopy
		end
	end

	for i = 0, 8 do
		if items[i] then
			print(items[i])
			hero:AddItem(items[i])
--			items[i]:StartCooldown(items[i]:GetCooldownTimeRemaining())
--			if items[i]:GetCurrentCharges() ~= 0 then
--				print(items[i]:GetCurrentCharges())
--				items[i]:SetCurrentCharges(items[i]:GetCurrentCharges())
--			end
		end
	end

	if not caster:IsNull() then
		UTIL_Remove(caster)
	end
end
