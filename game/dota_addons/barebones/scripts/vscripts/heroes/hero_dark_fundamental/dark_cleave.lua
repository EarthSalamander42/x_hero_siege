require("libraries/timers")

function DarkCleave( keys )
local caster = keys.caster
local target = keys.target
local modifier_dark_cleave = keys.modifier_dark_cleave
local ability = keys.ability
local ability_level = ability:GetLevel() - 1
local cooldown = ability:GetCooldown(ability_level)
local stacks = caster:GetLevel()
local bonus_damage = ability:GetLevelSpecialValueFor("bonus_damage", ability_level)
local full_damage = bonus_damage * stacks -- 100 * caster Level

	ability:StartCooldown(cooldown)
	caster:RemoveModifierByName(modifier_dark_cleave)
	ApplyDamage({attacker = caster, victim = target, ability = ability, damage = full_damage, damage_type = DAMAGE_TYPE_PHYSICAL})
	SendOverheadEventMessage(nil, OVERHEAD_ALERT_CRITICAL, target, full_damage, nil)

	Timers:CreateTimer(cooldown, function()
		ability:ApplyDataDrivenModifier( caster, caster, modifier_dark_cleave, {})
	end)
end

function DarkCleaveStack( keys ) -- Called only On Spawn
local caster = keys.caster
local ability = keys.ability
local ability_level = ability:GetLevel() - 1
local modifier_stack = keys.modifier_stack
local stacks = caster:GetLevel()

	Timers:CreateTimer(0.2, function()
		ability:ApplyDataDrivenModifier(caster, caster, modifier_stack, {})
		caster:SetModifierStackCount(modifier_stack, ability, stacks)
	end)
end
