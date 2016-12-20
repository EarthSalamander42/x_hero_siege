--[[ ============================================================================================================
	Author: Rook
	Date: June 6, 2015
	Called when Venomancer's Plague Ward is cast.  Spawns a Plague Ward of the appropriate level at the target location.
	Additional parameters: keys.Duration
================================================================================================================= ]]
function venomancer_plague_ward_datadriven_on_spell_start(keys)
local caster = keys.caster
local caster_origin = caster:GetAbsOrigin()
local direction = (keys.target_points[1] - caster_origin):Normalized()
direction.z = 0

	caster:EmitSound("Hero_Venomancer.Plague_Ward")

	local ability_level = keys.ability:GetLevel()
	if ability_level >= 1 and ability_level <= 2 then
		local plague_ward_unit = CreateUnitByName("laser_trap_" .. ability_level, keys.target_points[1], false, caster, caster, caster:GetTeam())
		plague_ward_unit:SetForwardVector(direction)
		plague_ward_unit:SetControllableByPlayer(caster:GetPlayerID(), true)
		plague_ward_unit:SetOwner(caster)
		plague_ward_unit:AddNewModifier(caster, nil, "modifier_phased", {})

		--Display particle effects for Venomancer as well as the plague ward.
--		local venomancer_plague_ward_cast_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_templar_assassin/templar_assassin_meld_attack_plasma.vpcf", PATTACH_ABSORIGIN, caster)
		local plague_ward_spawn_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_shadowshaman/shadow_shaman_dust_hit.vpcf", PATTACH_ABSORIGIN, plague_ward_unit)

		--Add the green duration circle, and kill the plague ward after the duration ends.
		plague_ward_unit:AddNewModifier(plague_ward_unit, nil, "modifier_kill", {duration = keys.Duration})

		--Store the unit that spawned this plague ward (i.e. Venomancer).
		plague_ward_unit.venomancer_plague_ward_parent = caster
	elseif ability_level >= 3 then
		local plague_ward_unit = CreateUnitByName("laser_trap_2", keys.target_points[1], false, caster, caster, caster:GetTeam())
		plague_ward_unit:SetForwardVector(direction)
		plague_ward_unit:SetControllableByPlayer(caster:GetPlayerID(), true)
		plague_ward_unit:SetOwner(caster)
		plague_ward_unit:AddNewModifier(caster, nil, "modifier_phased", {})

		local plague_ward_spawn_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_shadowshaman/shadow_shaman_dust_hit.vpcf", PATTACH_ABSORIGIN, plague_ward_unit)
		plague_ward_unit:AddNewModifier(plague_ward_unit, nil, "modifier_kill", {duration = keys.Duration})
		plague_ward_unit.venomancer_plague_ward_parent = caster

		local plague_ward_unit2 = CreateUnitByName("laser_trap_2", keys.target_points[1] + RandomVector(150), false, caster, caster, caster:GetTeam())
		plague_ward_unit2:SetForwardVector(direction)
		plague_ward_unit2:SetControllableByPlayer(caster:GetPlayerID(), true)
		plague_ward_unit2:SetOwner(caster)
		plague_ward_unit2:AddNewModifier(caster, nil, "modifier_phased", {})

		local plague_ward_spawn_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_shadowshaman/shadow_shaman_dust_hit.vpcf", PATTACH_ABSORIGIN, plague_ward_unit2)
		plague_ward_unit2:AddNewModifier(plague_ward_unit2, nil, "modifier_kill", {duration = keys.Duration})
		plague_ward_unit2.venomancer_plague_ward_parent = caster
	end
end
