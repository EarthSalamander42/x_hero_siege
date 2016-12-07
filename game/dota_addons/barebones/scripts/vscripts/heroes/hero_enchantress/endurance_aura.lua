function EnduranceAuraCaster( keys )
local caster = keys.caster
local ability = keys.ability
local BAT = caster:GetBaseAttackTime()
local BAT_Dec = ability:GetLevelSpecialValueFor("bat_reduction_caster", ability:GetLevel() -1)

	caster:SetBaseAttackTime( BAT - BAT_Dec + 0.025 ) -- Just, don't ask..
end

function EnduranceAura( keys )
local target = keys.target
local ability = keys.ability
local BAT_alt = target:GetBaseAttackTime()
local BAT_Dec = ability:GetLevelSpecialValueFor("bat_reduction", ability:GetLevel() -1)

	target:SetBaseAttackTime( BAT_alt - BAT_Dec )
end

function EnduranceAuraRemove( keys )
local target = keys.target
local ability = keys.ability
local BAT_alt = target:GetBaseAttackTime()
local BAT_Dec = ability:GetLevelSpecialValueFor("bat_reduction", ability:GetLevel() -1)

	target:SetBaseAttackTime( BAT_alt + BAT_Dec )
end
