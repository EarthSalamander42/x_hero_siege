function Torment( keys )
	local caster = keys.caster
	local target = keys.unit
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	-- Parameters
	local cooldown_reduction = ability:GetLevelSpecialValueFor("cooldown_reduction", ability_level)

	-- If a hero was damaged, reduce all ability cooldowns
	if target:IsRealHero() then
		for i = 0, 15 do
			local current_ability = caster:GetAbilityByIndex(i)
			if current_ability then
				local cooldown_remaining = current_ability:GetCooldownTimeRemaining()
				current_ability:EndCooldown()
				if cooldown_remaining > cooldown_reduction then
					current_ability:StartCooldown( cooldown_remaining - cooldown_reduction )
				end
			end
		end
	end
end
