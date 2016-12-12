require('libraries/timers')

function SummonHealingWard(event)
local caster = event.caster
local ability = event.ability
local origin = event.caster:GetAbsOrigin()
local point = event.target_points[1]
local duration = ability:GetSpecialValueFor("duration")

	local ward = CreateUnitByName('healing_ward', point, false, caster, caster, caster:GetTeamNumber())
	ward:AddNewModifier(caster, nil, "modifier_kill", {duration = duration})
	ward:AddNewModifier(caster, nil, "modifier_invulnerable", {duration = duration})
	ward:AddNewModifier(caster, nil, "modifier_phased", {duration = duration})
	ward:EmitSound("Hero_Juggernaut.HealingWard.Cast")
	ward:EmitSound("Hero_Juggernaut.HealingWard.Loop")
	Timers:CreateTimer( duration, function()
		ward:EmitSound("Hero_Juggernaut.HealingWard.Stop")
		ward:StopSound("Hero_Juggernaut.HealingWard.Loop")
	end)
end
