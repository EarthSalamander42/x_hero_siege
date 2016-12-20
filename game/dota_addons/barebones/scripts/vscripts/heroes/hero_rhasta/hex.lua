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
local ability_level = keys.ability:GetLevel()
local duration = keys.Duration
direction.z = 0

local ward = {}
ward[1] = { 55, 110, 0 }	-- North-East
ward[2] = { -55, 110, 0 }	-- North-West
ward[3] = { -110, 0, 0 }	-- West
ward[4] = { 110, 0, 0 }		-- East
ward[5] = { -55, -110, 0 }	-- South-West
ward[6] = { 55, -110, 0 }	-- South-East

	caster:EmitSound("Hero_Venomancer.Plague_Ward")

	for count = 1, 6 do
		local plague_ward_unit = CreateUnitByName("laser_trap_2", keys.target_points[1] + Vector( ward[count][1], ward[count][2], ward[count][3]), false, caster, caster, caster:GetTeam())
		plague_ward_unit:SetForwardVector(direction)
		plague_ward_unit:SetControllableByPlayer(caster:GetPlayerID(), true)
		plague_ward_unit:SetOwner(caster)
		plague_ward_unit:AddNewModifier(caster, nil, "modifier_phased", {})

		local plague_ward_spawn_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_shadowshaman/shadow_shaman_dust_hit.vpcf", PATTACH_ABSORIGIN, plague_ward_unit)
		plague_ward_unit:AddNewModifier(plague_ward_unit, nil, "modifier_kill", {duration = duration})
		plague_ward_unit.venomancer_plague_ward_parent = caster
	end
end
