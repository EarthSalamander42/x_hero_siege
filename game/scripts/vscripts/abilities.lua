function maintain_immolation_toggle( event )
	local manacost_per_second = 10
	-- if the caster has enough mana left to mantain the spell, spend it. Else, toggle the ability off
	if event.caster:GetMana() >= manacost_per_second then
		event.caster:SpendMana( manacost_per_second, event.ability)
	else
		event.ability:ToggleAbility()
	end
end
