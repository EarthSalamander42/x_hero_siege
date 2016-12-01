function PowerMountPhaseCast(keys)
local caster = keys.caster

	StartAnimation(caster, {duration = 1.45, activity = ACT_DOTA_VICTORY, rate = 1.35})
end

function PowerMountCast(keys)
local caster = keys.caster
local ability = keys.ability
local sub_ability_name = keys.sub_ability_name
local main_ability_name = ability:GetAbilityName()

--	sub_ability_name:StartCooldown(10.0) Fix this
	caster:SwapAbilities(main_ability_name, sub_ability_name, false, true)
end
