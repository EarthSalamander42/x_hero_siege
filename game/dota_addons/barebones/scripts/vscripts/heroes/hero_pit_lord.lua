require('libraries/timers')


function rain_of_chaos( event )
	-- body
	local caster = event.caster
	local ability = event.ability
	local time_to_damage = 2.0
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
		ability:ApplyDataDrivenModifier(caster, unit, "modifier_dummy_target", {duration = 1.1})
		local TimerDestroySound = Timers:CreateTimer(1.1, function()
			unit:EmitSound("Hero_Invoker.ChaosMeteor.Impact")
		end)
	end
end

function target_modifier_remove(keys)
	-- body
	local target = keys.target
	local caster = keys.caster
	local soil = ParticleManager:CreateParticle("particles/units/heroes/hero_invoker/invoker_chaos_meteor_land_soil.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(soil, 3, target:GetAbsOrigin()+Vector(0,0,40))
	local crumble = ParticleManager:CreateParticle("particles/units/heroes/hero_invoker/invoker_chaos_meteor_crumble.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(crumble, 3, target:GetAbsOrigin())
	target:StopSound("Hero_Invoker.ChaosMeteor.Loop")
	target:RemoveSelf()
end

function SpawnDoomBeast(keys)
	--The Plague Ward should initialize facing away from Venomancer, so find that direction.
	local caster_origin = keys.caster:GetAbsOrigin()

	keys.caster:EmitSound("Hero_Venomancer.Plague_Ward")

	local plague_ward_level = keys.ability:GetLevel()
	if plague_ward_level >= 1 and plague_ward_level <= 3 then
		local plague_ward_unit = CreateUnitByName("npc_dota_doom_golem_" .. plague_ward_level, caster_origin, false, keys.caster, keys.caster, keys.caster:GetTeam())
		plague_ward_unit:SetControllableByPlayer(keys.caster:GetPlayerID(), true)
		plague_ward_unit:SetOwner(keys.caster)
		plague_ward_unit:AddNewModifier(caster, nil, "modifier_phased", {})

		--Display particle effects for Venomancer as well as the plague ward.
--		local venomancer_plague_ward_cast_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_templar_assassin/templar_assassin_meld_attack_plasma.vpcf", PATTACH_ABSORIGIN, keys.caster)
		local plague_ward_spawn_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_shadowshaman/shadow_shaman_dust_hit.vpcf", PATTACH_ABSORIGIN, plague_ward_unit)

		--Add the green duration circle, and kill the plague ward after the duration ends.
		plague_ward_unit:AddNewModifier(plague_ward_unit, nil, "modifier_kill", {duration = keys.Duration})

		--Store the unit that spawned this plague ward (i.e. Venomancer).
		plague_ward_unit.venomancer_plague_ward_parent = keys.caster
	end
end
