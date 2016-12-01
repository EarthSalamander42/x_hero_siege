function Instakill( keys )
local caster = keys.caster
local target = keys.target
local ability = keys.ability
local damage = 7777777

	SendOverheadEventMessage(nil, OVERHEAD_ALERT_DENY, target, damage, nil)
	ApplyDamage({attacker = caster, victim = target, ability = ability, damage = damage, damage_type = DAMAGE_TYPE_PHYSICAL})
end
