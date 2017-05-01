require('libraries/timers')

function SerpentWard(keys)
local caster = keys.caster
local caster_origin = caster:GetAbsOrigin()
local ability = keys.ability
local direction = (keys.target_points[1] - caster_origin):Normalized()
direction.z = 0

	caster:EmitSound("Ability.Ward")
	Timers:CreateTimer(1.6, function()
		caster:StopSound("Ability.Ward")
	end)

	local level = ability:GetLevel()
	if level >= 1 and level <= 4 then
		local unit = CreateUnitByName("serpent_ward_"..level, keys.target_points[1], false, caster, caster, caster:GetTeam())
		unit:SetForwardVector(direction)
		unit:SetControllableByPlayer(caster:GetPlayerID(), true)
		unit:SetOwner(caster)
		unit:AddNewModifier(caster, nil, "modifier_phased", {})

		local plague_ward_spawn_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_shadowshaman/shadow_shaman_dust_hit.vpcf", PATTACH_ABSORIGIN, unit)

		unit:AddNewModifier(unit, nil, "modifier_kill", {duration = keys.Duration})
		unit.venomancer_plague_ward_parent = caster
	end
end
