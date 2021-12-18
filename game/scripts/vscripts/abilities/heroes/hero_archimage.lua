--[[
	Author: Noya
	Creates a dummy unit to apply the Blizzard thinker modifier which does the waves
]]
function BlizzardStartPoint( event )

	local caster = event.caster
	local point = event.target_points[1]

	caster.blizzard_dummy_point = CreateUnitByName("dummy_unit_invulnerable", point, false, caster, caster, caster:GetTeam())
	event.ability:ApplyDataDrivenModifier(caster, caster.blizzard_dummy_point, "modifier_blizzard_wave", nil)
	event.ability:ApplyDataDrivenModifier(caster, caster.blizzard_dummy_point, "modifier_dummy_target", nil)
	caster.blizzard_dummy_point:EmitSound("hero_Crystal.freezingField.wind")
end


--[[function BlizzardWaveStart( event )
	local caster = event.caster
	event.ability:ApplyDataDrivenModifier(caster, caster.blizzard_dummy_point, "modifier_blizzard_thinker", nil)
end]]

-- Create the particles with small delays between each other
function BlizzardWave(event)
local caster = event.caster
local ability = event.ability
local target_position = event.target:GetAbsOrigin() --event.target_points[1]
local particleName = "particles/units/heroes/hero_crystalmaiden/maiden_freezing_field_explosion.vpcf"
local distance = 100

	-- Center explosion
	local particle1 = ParticleManager:CreateParticle( particleName, PATTACH_CUSTOMORIGIN, caster )
	ParticleManager:SetParticleControl( particle1, 0, target_position )

	local fv = caster:GetForwardVector()

	Timers:CreateTimer(0.05,function()
	local particle2 = ParticleManager:CreateParticle( particleName, PATTACH_CUSTOMORIGIN, caster )
	ParticleManager:SetParticleControl( particle2, 0, target_position+RandomVector(100) ) end)

	Timers:CreateTimer(0.1,function()
	local particle3 = ParticleManager:CreateParticle( particleName, PATTACH_CUSTOMORIGIN, caster )
	ParticleManager:SetParticleControl( particle3, 0, target_position-RandomVector(100) ) end)

	Timers:CreateTimer(0.15,function()
	local particle4 = ParticleManager:CreateParticle( particleName, PATTACH_CUSTOMORIGIN, caster )
	ParticleManager:SetParticleControl( particle4, 0, target_position+RandomVector(RandomInt(50,100)) ) end)

	Timers:CreateTimer(0.2,function()
	local particle5 = ParticleManager:CreateParticle( particleName, PATTACH_CUSTOMORIGIN, caster )
	ParticleManager:SetParticleControl( particle5, 0, target_position-RandomVector(RandomInt(50,100)) ) end)

	Timers:CreateTimer(0.25,function()
	local particle6 = ParticleManager:CreateParticle( particleName, PATTACH_CUSTOMORIGIN, caster )
	ParticleManager:SetParticleControl( particle6, 0, target_position-RandomVector(RandomInt(150,200)) ) end)

	Timers:CreateTimer(0.3,function()
	local particle7 = ParticleManager:CreateParticle( particleName, PATTACH_CUSTOMORIGIN, caster )
	ParticleManager:SetParticleControl( particle7, 0, target_position-RandomVector(RandomInt(150,200)) ) end)

	Timers:CreateTimer(0.35,function()
	local particle8 = ParticleManager:CreateParticle( particleName, PATTACH_CUSTOMORIGIN, caster )
	ParticleManager:SetParticleControl( particle8, 0, target_position-RandomVector(RandomInt(150,200)) ) end)
end

function ApplyAnimation( event )
	local ability = event.ability
	local caster = event.caster
	local start_time = ability:GetChannelStartTime()
	local time_channeled = GameRules:GetGameTime() - start_time
	local max_channel_time = ability:GetLevelSpecialValueFor("wave_duration", ability:GetLevel() - 1)
	local wps_thinker = ability:GetLevelSpecialValueFor("wps_thinker", ability:GetLevel()-1)

	if ability:IsChanneling() and (time_channeled < max_channel_time - 0.5) then
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_channeling", { duration = wps_thinker-0.05 })
	end
end

function BlizzardEnd(event)
	local caster = event.caster
	caster.blizzard_dummy_point:RemoveModifierByName("modifier_blizzard_wave")
	caster:RemoveModifierByName("modifier_blizzard_channelling")
	caster.blizzard_dummy_point:StopSound("hero_Crystal.freezingField.wind")

	local blizzard_dummy_point_pointer = caster.blizzard_dummy_point
	Timers:CreateTimer(0.4,function() blizzard_dummy_point_pointer:RemoveSelf() end)
end

function WaterElemental(keys)
local caster_origin = keys.caster:GetAbsOrigin()
local caster_fv = keys.caster:GetForwardVector()
caster_origin.z = 0
local level = keys.ability:GetLevel()

	if level >= 1 and level <= 4 then
		local unit = CreateUnitByName("npc_water_elemental_"..level, caster_origin, false, keys.caster, keys.caster, keys.caster:GetTeam())
		unit:SetForwardVector(caster_fv)
		unit:SetControllableByPlayer(keys.caster:GetPlayerID(), true)
		unit:SetOwner(keys.caster)
		unit:AddNewModifier(caster, nil, "modifier_phased", {duration = 0.05})
		local plague_ward_spawn_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_morphling/morphling_replicate_finish.vpcf", PATTACH_ABSORIGIN, unit)
		unit:AddNewModifier(unit, nil, "modifier_kill", {duration = keys.Duration})
	end
end

function MagicShield(keys)
local caster = keys.caster
local target = keys.target
local ability = keys.ability
local particle_cast = "particles/units/heroes/hero_omniknight/omniknight_repel_cast.vpcf"
local Duration = ability:GetSpecialValueFor("duration")

	local particle_cast_fx = ParticleManager:CreateParticle(particle_cast, PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle_cast_fx, 0, target:GetAbsOrigin())
	target:Purge(false, true, false, true, true)
end
