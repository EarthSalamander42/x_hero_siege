require('libraries/timers')

function tome_use(event)
	local hero = event.caster
	local ability = event.ability
	local stats = ability:GetSpecialValueFor("stat_bonus")

	hero:ModifyAgility(stats)
	hero:ModifyStrength(stats)
	hero:ModifyIntellect(stats)
	local particle1 = ParticleManager:CreateParticle("particles/econ/events/ti6/hero_levelup_ti6.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
	ParticleManager:SetParticleControl(particle1, 0, hero:GetAbsOrigin())
	hero:EmitSound("ui.trophy_levelup")

--	hero:SetBaseAgility( hero:GetAgility() + stats )
end
