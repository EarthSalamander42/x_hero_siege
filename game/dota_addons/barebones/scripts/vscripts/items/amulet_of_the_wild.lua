function Furbolg(keys)
local caster = keys.caster
local ability = keys.ability
local duration = ability:GetLevelSpecialValueFor("duration", ability:GetLevel() -1)

	--The Furbolg should initialize facing away, so find that direction.
	local caster_origin = caster:GetAbsOrigin()

	caster:EmitSound("Hero_Ursa.Earthshock")

	local unit = CreateUnitByName("npc_dota_furbolg", caster_origin, false, caster, caster, caster:GetTeam())
	unit:SetControllableByPlayer(caster:GetPlayerID(), false)
	unit:SetOwner(caster)
	unit:AddNewModifier(caster, nil, "modifier_phased", {duration = 0.1})

	--Display particle effects for Furbolg.
--	local cast_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_ursa/ursa_enrage_buff.vpcf", PATTACH_ABSORIGIN, caster)
	local spawn_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_ursa/ursa_earthshock.vpcf", PATTACH_ABSORIGIN, unit)

	--Add the green duration circle, and kill the Furbolg after the duration ends.
	unit:AddNewModifier(unit, nil, "modifier_kill", {duration = duration})

	--Store the unit that spawned this Furbolg.
--	unit.furbolg_parent = caster
end
