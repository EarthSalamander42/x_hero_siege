require('libraries/timers')

function venomancer_plague_ward_datadriven_on_spell_start(keys)
local caster = keys.caster
local caster_origin = caster:GetAbsOrigin()
local direction = (keys.target_points[1] - caster_origin):Normalized()
direction.z = 0

	caster:EmitSound("Ability.Ward")
	Timers:CreateTimer(1.7, function()
		caster:StopSound("Ability.Ward")
	end)

	local plague_ward_level = keys.ability:GetLevel()
	if plague_ward_level >= 1 and plague_ward_level <= 4 then
		local plague_ward_unit = CreateUnitByName("serpent_ward_" .. plague_ward_level, keys.target_points[1], false, caster, caster, caster:GetTeam())
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
	end
end