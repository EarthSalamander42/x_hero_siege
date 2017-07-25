function rain_of_chaos(event)
local caster = event.caster
local time_to_damage = 2.0
local ability = event.ability
local radius = ability:GetLevelSpecialValueFor("radius", ability:GetLevel()-1)

	local meteors_per_tick = ability:GetLevelSpecialValueFor("meteors_per_tick", ability:GetLevel()-1)

	for i = 1, meteors_per_tick do
		local point = caster:GetAbsOrigin()+ RandomInt(1,radius)*RandomVector(1)
		local meteor = ParticleManager:CreateParticle("particles/units/heroes/hero_invoker/invoker_chaos_meteor_fly.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControl(meteor, 0, point + Vector(0,0,500))
		ParticleManager:SetParticleControl(meteor, 1, point)
		ParticleManager:SetParticleControl(meteor, 2, Vector(1.2,0,0))
		local unit = CreateUnitByName("dummy_unit_invulnerable", point, true, nil, nil, caster:GetTeamNumber())
		unit:EmitSound("Hero_Invoker.ChaosMeteor.Loop")
		local TimerDestroySound = Timers:CreateTimer(1.09, function()
			unit:EmitSound("Hero_Invoker.ChaosMeteor.Impact")
		end)
		ability:ApplyDataDrivenModifier(caster, unit, "modifier_dummy_target", {duration = 1.1})
	end
end

function target_modifier_remove(event)
local target = event.target
local caster = event.caster
local ability = event.ability
local duration = ability:GetSpecialValueFor("golem_duration")

	target:StopSound("Hero_Invoker.ChaosMeteor.Loop")
	local unit = CreateUnitByName("npc_infernal_beast", target:GetAbsOrigin(), true, caster,caster, target:GetTeamNumber())
	local soil = ParticleManager:CreateParticle("particles/units/heroes/hero_invoker/invoker_chaos_meteor_land_soil.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(soil, 3, target:GetAbsOrigin()+Vector(0,0,40))
	local crumble = ParticleManager:CreateParticle("particles/units/heroes/hero_invoker/invoker_chaos_meteor_crumble.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(crumble, 3, target:GetAbsOrigin())
	target:RemoveSelf()
	unit:AddNewModifier(unit, nil, "modifier_kill", {duration = duration})
end
