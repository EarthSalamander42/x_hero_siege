function Furbolg(keys)
local caster = keys.caster
local ability = keys.ability
local duration = ability:GetSpecialValueFor("duration")
local caster_origin = caster:GetAbsOrigin()

	caster:EmitSound("Hero_Ursa.Earthshock")

	local unit = CreateUnitByName("npc_dota_furbolg", caster_origin, false, caster, caster, caster:GetTeam())
	unit:SetControllableByPlayer(caster:GetPlayerID(), true)
	unit:SetOwner(caster)
	unit:AddNewModifier(caster, nil, "modifier_phased", {duration = 0.1})

	local spawn_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_ursa/ursa_earthshock.vpcf", PATTACH_ABSORIGIN, unit)
	unit:AddNewModifier(unit, nil, "modifier_kill", {duration = duration})
	unit.furbolg_parent = caster
end
