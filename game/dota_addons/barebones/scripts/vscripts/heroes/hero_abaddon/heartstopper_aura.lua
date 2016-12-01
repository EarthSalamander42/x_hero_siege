function HeartstopperEnemy( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	-- Ability parameters
	local aura_damage = ability:GetLevelSpecialValueFor("aura_damage", ability_level) * 0.01
	local max_stacks = ability:GetLevelSpecialValueFor("max_stacks", ability_level)

	-- Calculates damage
	local damage = target:GetMaxHealth() * aura_damage
	
	-- If the target is at low enough HP, kill it
	if target:GetHealth() <= (damage + 5) then
		ApplyDamage({attacker = caster, victim = target, ability = ability, damage = damage + 10, damage_type = DAMAGE_TYPE_PURE})

	-- Else, remove some HP from it
	else
		target:SetHealth(target:GetHealth() - damage)
	end
end
