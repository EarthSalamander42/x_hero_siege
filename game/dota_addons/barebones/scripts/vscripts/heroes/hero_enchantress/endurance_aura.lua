function EnduranceAura( keys )
local caster = keys.caster
local target = keys.target
local ability = keys.ability
local BAT = caster:GetBaseAttackTime()
local BAT_alt = target:GetBaseAttackTime()
local BAT_Dec = ability:GetLevelSpecialValueFor("bat_reduction", ability:GetLevel()-1)

	caster:SetBaseAttackTime( BAT - BAT_Dec )
	target:SetBaseAttackTime( BAT_alt - BAT_Dec )
end

function EnduranceAuraRemove( keys )
local caster = keys.caster
local target = keys.target
local ability = keys.ability
local BAT = caster:GetBaseAttackTime()
local BAT_alt = target:GetBaseAttackTime()
local BAT_Dec = ability:GetLevelSpecialValueFor("bat_reduction", ability:GetLevel()-1)

	caster:SetBaseAttackTime( BAT + BAT_Dec )
	target:SetBaseAttackTime( BAT_alt + BAT_Dec )
end
