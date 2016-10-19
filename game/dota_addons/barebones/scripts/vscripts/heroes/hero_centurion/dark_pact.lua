function Purge(keys)
local caster = keys.caster
local index = ParticleManager:CreateParticle("particles/units/heroes/hero_slark/slark_dark_pact_start.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)

	ParticleManager:SetParticleControlEnt(index, 1, caster, PATTACH_ABSORIGIN_FOLLOW, nil, caster:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(index)

	Timers:CreateTimer(1.5, function()
	local index = ParticleManager:CreateParticle("particles/units/heroes/hero_slark/slark_dark_pact_pulses.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControlEnt(index, 1, caster, PATTACH_ABSORIGIN_FOLLOW, nil, caster:GetAbsOrigin(), true)
		ParticleManager:SetParticleControl(index, 2, Vector(300, 0, 0))
		caster:Purge( true, true, false, true, false)
	end)
end
