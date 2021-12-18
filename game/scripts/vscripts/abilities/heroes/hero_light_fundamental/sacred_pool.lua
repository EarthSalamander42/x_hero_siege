function ApplyHeal(keys)
local caster = keys.caster
local target = keys.target
local ability = keys.ability
local health = target:GetMaxHealth()	
local health_percent = ability:GetLevelSpecialValueFor("heal_percent", ability:GetLevel() -1)/100
local heal = health_percent * health

	target:Heal(heal, target)
--	SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, ally, heal, nil)
end
