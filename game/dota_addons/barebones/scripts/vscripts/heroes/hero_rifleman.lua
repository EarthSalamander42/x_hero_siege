function ToggleAbilities(keys)
local caster = keys.caster
local ability = keys.ability
local ability_aux = keys.ability_aux
local ability_aux2 = keys.ability_aux2
local ability2 = caster:FindAbilityByName(ability_aux)
local ability3 = caster:FindAbilityByName(ability_aux2)
local projectile_model = keys.projectile_model

	if ability:GetToggleState() == true and ability:GetToggleState() == ability2:GetToggleState() then
		ability2:ToggleAbility()
		caster:SetRangedProjectileName(projectile_model)
	end
	if ability:GetToggleState() == true and ability:GetToggleState() == ability3:GetToggleState() then
		ability3:ToggleAbility()
	end
end

function SetOriginal(keys)
local caster = keys.caster
local projectile_model = "particles/units/heroes/hero_sniper/sniper_base_attack.vpcf"

	caster:SetRangedProjectileName(projectile_model)
end
