--[[Author: Pizzalol
Date: 26.09.2015.
Creates a dummy at the target location that acts as the Chronosphere]]
function MagneticField( keys )
	-- Variables
	local caster = keys.caster
	local ability = keys.ability
	local target_point = keys.target_points[1]

	-- Special Variables
	local duration = ability:GetLevelSpecialValueFor("duration", (ability:GetLevel() - 1))

	-- Dummy
	local dummy_modifier = keys.dummy_aura
	local dummy = CreateUnitByName("npc_dummy_unit", target_point, false, caster, caster, caster:GetTeam())
	dummy:AddNewModifier(caster, nil, "modifier_phased", {})
	ability:ApplyDataDrivenModifier(caster, dummy, dummy_modifier, {duration = duration})

	-- Timer to remove the dummy
	Timers:CreateTimer(duration, function() dummy:RemoveSelf() end)
end

--[[Author: Pizzalol
Date: 26.09.2015.
Checks if the target is a unit owned by the player that cast the Chronosphere
If it is then it applies the no collision and extra movementspeed modifier
otherwise it applies the stun modifier]]
function MagneticFieldAura( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	-- Ability variables
	local aura_modifier = keys.aura_modifier
	local duration = ability:GetLevelSpecialValueFor("aura_interval", ability_level)

	ability:ApplyDataDrivenModifier(caster, target, aura_modifier, {duration = duration}) 
end
