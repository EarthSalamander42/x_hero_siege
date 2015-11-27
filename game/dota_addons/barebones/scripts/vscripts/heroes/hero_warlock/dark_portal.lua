--[[ ============================================================================================================
	Author: Rook
	Date: June 6, 2015
	Called when Venomancer's Plague Ward is cast.  Spawns a Plague Ward of the appropriate level at the target location.
	Additional parameters: keys.Duration
================================================================================================================= ]]
function venomancer_plague_ward_datadriven_on_spell_start(keys)
	--The Plague Ward should initialize facing away from Venomancer, so find that direction.
	local caster_origin = keys.caster:GetAbsOrigin()
	local direction = (keys.target_points[1] - caster_origin):Normalized()
	direction.z = 0
	
	keys.caster:EmitSound("Hero_Venomancer.Plague_Ward")
	
	local plague_ward_level = keys.ability:GetLevel()
	if plague_ward_level >= 1 and plague_ward_level <= 7 then
		local plague_ward_unit = CreateUnitByName("dark_portal_" .. plague_ward_level, keys.target_points[1], false, keys.caster, keys.caster, keys.caster:GetTeam())
		plague_ward_unit:SetForwardVector(direction)
		plague_ward_unit:SetControllableByPlayer(keys.caster:GetPlayerID(), true)
		plague_ward_unit:SetOwner(keys.caster)
		plague_ward_unit:AddNewModifier(caster, nil, "modifier_phased", {})

		--Display particle effects for Venomancer as well as the plague ward.
--		local venomancer_plague_ward_cast_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_templar_assassin/templar_assassin_meld_attack_plasma.vpcf", PATTACH_ABSORIGIN, keys.caster)
		local plague_ward_spawn_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_templar_assassin/templar_assassin_trap_rings_inner.vpcf", PATTACH_ABSORIGIN, plague_ward_unit)

		--Add the green duration circle, and kill the plague ward after the duration ends.
		plague_ward_unit:AddNewModifier(plague_ward_unit, nil, "modifier_kill", {duration = keys.Duration})

		--Store the unit that spawned this plague ward (i.e. Venomancer).
		plague_ward_unit.venomancer_plague_ward_parent = keys.caster
	end
end