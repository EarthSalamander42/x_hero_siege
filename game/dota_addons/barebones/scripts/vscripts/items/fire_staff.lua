function Ignite( keys )
	local caster = keys.caster
	if caster:IsIllusion() or caster:IsOwnedByAnyPlayer() == false then return end
	local target = keys.target
	local ability = keys.ability

	-- Calculates damage
	local damage = target:GetMaxHealth() * 0.005
	
	-- If the target is at low enough HP, kill it
	if target:GetHealth() <= (damage + 5) then
		ApplyDamage({attacker = caster, victim = target, ability = ability, damage = damage + 10, damage_type = DAMAGE_TYPE_PURE})
	-- Else, remove some HP from it
	else
		target:SetHealth(target:GetHealth() - damage)
	end
end
