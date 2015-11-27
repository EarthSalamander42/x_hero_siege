function tome_use(event)
	local hero = event.caster
	local ability = event.ability
	local stats = ability:GetSpecialValueFor("stat_bonus")
	
	hero:ModifyAgility(stats)
	hero:ModifyStrength(stats)
	hero:ModifyIntellect(stats)
end