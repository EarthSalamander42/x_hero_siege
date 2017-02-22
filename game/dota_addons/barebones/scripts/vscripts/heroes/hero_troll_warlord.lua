require("libraries/timers")

function EnchantedAxes(keys)
local attacker = keys.caster
local target = keys.target
local ability = keys.ability
local radius = ability:GetSpecialValueFor("full_damage_radius")
local cleave = ability:GetSpecialValueFor("cleave_pct_tooltip")
local full_damage = attacker:GetAverageTrueAttackDamage(attacker)
local cleave_pct = cleave * full_damage / 100
local splash_targets = FindUnitsInRadius(attacker:GetTeamNumber(), target:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
local ability_level = ability:GetLevel() - 1
local multiplier = ability:GetLevelSpecialValueFor("damage_multiplier", ability_level) -1
local dmg_mult = full_damage * multiplier

	if attacker:GetAttackCapability() == DOTA_UNIT_CAP_MELEE_ATTACK then
		for _,unit in pairs(splash_targets) do
			if unit ~= target and not unit:IsBuilding() then
				ApplyDamage({victim = unit, attacker = attacker, damage = cleave_pct, ability = ability, damage_type = DAMAGE_TYPE_PHYSICAL})
			end
		end
	elseif attacker:GetAttackCapability() == DOTA_UNIT_CAP_RANGED_ATTACK then
		if not target:IsBuilding() then
			ApplyDamage({victim = target, attacker = attacker, damage = dmg_mult, ability = ability, damage_type = DAMAGE_TYPE_PHYSICAL})
		end
	end
end

function BattleTrance(keys)
local caster = keys.caster
local target = keys.target
local ability = keys.ability
local BAT = caster:GetBaseAttackTime()
local BAT_alt = target:GetBaseAttackTime()
local BAT_Dec = ability:GetLevelSpecialValueFor("bat_reduction", ability:GetLevel() -1)
local duration = ability:GetLevelSpecialValueFor("duration", ability:GetLevel() -1)

	caster:SetBaseAttackTime(BAT - BAT_Dec) --Doesn't work, find a fix
	target:SetBaseAttackTime(BAT_alt - BAT_Dec)

	Timers:CreateTimer(duration, function()
		caster:SetBaseAttackTime(BAT)
		target:SetBaseAttackTime(BAT_alt)
	end)
end
