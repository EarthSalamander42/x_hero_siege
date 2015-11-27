function OnHitUnit( keys )
local target = keys.target
local ability = keys.ability
local ability_level = ability:GetLevel() - 1
local damage = ability:GetLevelSpecialValueFor("bonus_damage", ability_level)

SendOverheadEventMessage( nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, target, damage, nil ) 
end
