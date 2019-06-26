function TomeOfStats(event)
local hero = event.caster
local ability = event.ability
local stats = ability:GetSpecialValueFor("stat_bonus")

	hero:IncrementAttributes(stats)
	local particle1 = ParticleManager:CreateParticle("particles/econ/events/ti6/hero_levelup_ti6.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
	ParticleManager:SetParticleControl(particle1, 0, hero:GetAbsOrigin())
	hero:EmitSound("ui.trophy_levelup")
end

function TomeOfPower(event)
	local hero = event.caster
	local level = hero:GetLevel()

	if IsValidEntity(hero) and level < 30 then 
		hero:AddExperience(XP_PER_LEVEL_TABLE[level+1]-XP_PER_LEVEL_TABLE[level] , DOTA_ModifyXP_Unspecified , false, true)
	end
end