function ProjectileHit( keys )

	-- Variables
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local damage = ability:GetLevelSpecialValueFor( "target_damage" , ability_level  )
	local heal = ability:GetLevelSpecialValueFor( "heal_amount" , ability_level )

	-- If the target and caster are on a different team, do Damage. Heal otherwise
	if target:GetTeamNumber() ~= caster:GetTeamNumber() then
		ApplyDamage({ victim = target, attacker = caster, damage = damage,	damage_type = DAMAGE_TYPE_MAGICAL })
	else
		target:Heal(heal, caster)
		SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, target, heal, nil)
	end
end