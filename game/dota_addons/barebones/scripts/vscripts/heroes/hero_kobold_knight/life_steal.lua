require("libraries/timers")

function LifeSteal( keys )
local caster = keys.caster
local modifier_lifesteal = keys.modifier_lifesteal
local ability = keys.ability
local ability_level = ability:GetLevel() - 1
local cooldown = ability:GetCooldown(ability_level)

	ability:StartCooldown(cooldown)
	caster:RemoveModifierByName(modifier_lifesteal)

	Timers:CreateTimer(cooldown, function()
		ability:ApplyDataDrivenModifier( caster, caster, modifier_lifesteal, {})
	end)
end
