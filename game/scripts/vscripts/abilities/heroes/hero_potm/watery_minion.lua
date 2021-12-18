--[[ ============================================================================================================
	Author: Rook
	Date: June 6, 2015
	Called when Venomancer's Plague Ward is cast.  Spawns a Plague Ward of the appropriate level at the target location.
	Additional parameters: keys.Duration
================================================================================================================= ]]
function WateryMinion(keys)
	--The Plague Ward should initialize facing away from Venomancer, so find that direction.
	local caster_origin = keys.caster:GetAbsOrigin()
	local direction = (keys.target_points[1] - caster_origin):Normalized()
	direction.z = 0

	local watery_minion = keys.ability:GetLevel()
	if watery_minion >= 1 and watery_minion <= 4 then
		local watery_minion_unit = CreateUnitByName("npc_dota_creature_watery_minion_" .. watery_minion, keys.target_points[1], false, keys.caster, keys.caster, keys.caster:GetTeam())
		watery_minion_unit:SetForwardVector(direction)
		watery_minion_unit:SetControllableByPlayer(keys.caster:GetPlayerID(), true)
		watery_minion_unit:SetOwner(keys.caster)
		watery_minion_unit:AddNewModifier(caster, nil, "modifier_phased", {duration = 0.05})

		--Display particle effects for Venomancer as well as the plague ward.
--		local venomancer_plague_ward_cast_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_templar_assassin/templar_assassin_meld_attack_plasma.vpcf", PATTACH_ABSORIGIN, keys.caster)
		local plague_ward_spawn_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_lycan/lycan_loadout.vpcf", PATTACH_ABSORIGIN, watery_minion_unit)

		--Add the green duration circle, and kill the plague ward after the duration ends.
		watery_minion_unit:AddNewModifier(watery_minion_unit, nil, "modifier_kill", {duration = keys.Duration})

		--Store the unit that spawned this plague ward (i.e. Venomancer).
--		watery_minion_unit.venomancer_plague_ward_parent = keys.caster
	end
end
