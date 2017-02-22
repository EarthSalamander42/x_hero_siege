function EquipClaws(keys)
local caster = keys.caster
local ability = keys.ability
local BAT = caster:GetBaseAttackTime()
local BAT_Dec = ability:GetLevelSpecialValueFor("bat_reduction", ability:GetLevel()-1)

	caster:SetBaseAttackTime( BAT - BAT_Dec )
end

function UnequipClaws(keys)
local caster = keys.caster
local ability = keys.ability
local BAT = caster:GetBaseAttackTime()
local BAT_Dec = ability:GetLevelSpecialValueFor("bat_reduction", ability:GetLevel()-1)

	caster:SetBaseAttackTime( BAT + BAT_Dec )
end
