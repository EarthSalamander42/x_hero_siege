function SpawnDoomBeast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local Duration = keys.Duration
	local caster_origin = caster:GetAbsOrigin()

	caster:EmitSound("Hero_Venomancer.Plague_Ward")

	local plague_ward_level = ability:GetLevel()
	if plague_ward_level >= 1 and plague_ward_level <= 3 then
		local plague_ward_unit = CreateUnitByName("npc_dota_doom_golem_" .. plague_ward_level, caster_origin, false, caster, caster, caster:GetTeam())
		plague_ward_unit:SetControllableByPlayer(caster:GetPlayerID(), true)
		plague_ward_unit:SetOwner(caster)
		plague_ward_unit:AddNewModifier(caster, nil, "modifier_phased", {})

		--Display particle effects for Venomancer as well as the plague ward.
		--		local venomancer_plague_ward_cast_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_templar_assassin/templar_assassin_meld_attack_plasma.vpcf", PATTACH_ABSORIGIN, caster)
		local plague_ward_spawn_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_shadowshaman/shadow_shaman_dust_hit.vpcf", PATTACH_ABSORIGIN, plague_ward_unit)

		--Add the green duration circle, and kill the plague ward after the duration ends.
		plague_ward_unit:AddNewModifier(plague_ward_unit, nil, "modifier_kill", { duration = Duration })

		--Store the unit that spawned this plague ward (i.e. Venomancer).
		plague_ward_unit.venomancer_plague_ward_parent = caster
	end
end
