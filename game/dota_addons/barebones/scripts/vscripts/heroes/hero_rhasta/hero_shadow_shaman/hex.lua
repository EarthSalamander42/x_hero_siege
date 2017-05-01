function SetWardDamage( event )
local target = event.target
local ability = event.ability
local attack_damage_min = ability:GetLevelSpecialValueFor("damage_min", ability:GetLevel() - 1 )
local attack_damage_max = ability:GetLevelSpecialValueFor("damage_max", ability:GetLevel() - 1 )

	target:SetBaseDamageMax(attack_damage_max)
	target:SetBaseDamageMin(attack_damage_min)
end
