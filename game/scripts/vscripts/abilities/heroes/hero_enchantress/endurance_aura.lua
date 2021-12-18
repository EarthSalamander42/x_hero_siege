function EnduranceAuraCaster( keys )
local caster = keys.caster
local ability = keys.ability
local BAT = caster:GetBaseAttackTime()
local BAT_Dec = ability:GetLevelSpecialValueFor("bat_reduction_caster", ability:GetLevel() -1)

	caster:SetBaseAttackTime( BAT - BAT_Dec + 0.025 ) -- Just, don't ask..
end
