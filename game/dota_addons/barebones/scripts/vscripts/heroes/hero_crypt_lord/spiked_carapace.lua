function Return( event )
	-- Variables
	local caster = event.caster
	local attacker = event.attacker
	local ability = event.ability
	local damageType = ability:GetAbilityDamageType()
	local hero_damage = ability:GetLevelSpecialValueFor( "hero_return_percent" , ability:GetLevel() - 1  )
	local creep_damage = ability:GetLevelSpecialValueFor( "creep_return_percent" , ability:GetLevel() - 1  )
	local attacker_damage = attacker:GetBaseDamageMin()
	local divided_damage = attacker_damage / 100

	-- Damage
	if attacker:GetTeamNumber() ~= caster:GetTeamNumber() and attacker:IsConsideredHero() then
		ApplyDamage({ victim = attacker, attacker = caster, damage = divided_damage * hero_damage, damage_type = damageType })
	elseif attacker:GetTeamNumber() ~= caster:GetTeamNumber() and attacker:IsCreep() then
		ApplyDamage({ victim = attacker, attacker = caster, damage = divided_damage * creep_damage, damage_type = damageType })
	end
end
