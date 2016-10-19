function NightmareDamage( keys )
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	local target_health = target:GetHealth()
	local damage = ability:GetLevelSpecialValueFor("damage_per_second", ability:GetLevel() - 1)

	-- Check if the damage would be lethal.
	if target_health <= damage then
		
		-- If that's the case, deal pure damage.
		ApplyDamage({attacker = caster, victim = target, ability = ability, damage = damage, damage_type = DAMAGE_TYPE_PURE})
	else
		-- Otherwise, just set the health to be lower
		target:SetHealth(target_health - damage)
	end
end

function NightmareSpread( keys )
	local caster = keys.caster
	local target = keys.target
	local attacker = keys.attacker
	local ability = keys.ability
	local nightmare_modifier = keys.nightmare_modifier

	-- Check if it has the Nightmare debuff
	if target:HasModifier(nightmare_modifier) then

		-- If it does then apply it to the attacker
		ability:ApplyDataDrivenModifier(caster, attacker, nightmare_modifier, {})
	end
end

function NightmareEnd( keys )
	local target = keys.target
	local loop_sound = keys.loop_sound

	-- Stops playing sound
	StopSoundEvent(loop_sound, target)
end

function NightmareEndCast( keys )
	local ability = keys.ability
	local target = keys.target
	local modifier_nightmare = keys.modifier_nightmare
	local modifier_invul = keys.modifier_invul

	-- Remove Nightmare modifiers
	target:RemoveModifierByName(modifier_nightmare)
	target:RemoveModifierByName(modifier_invul)
end