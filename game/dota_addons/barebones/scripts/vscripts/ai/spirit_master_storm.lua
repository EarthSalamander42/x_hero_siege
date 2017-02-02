require('libraries/timers')

function Spawn(entityKeyValues)
	Ability_ElectricVortex = thisEntity:FindAbilityByName("holdout_electric_vortex")

	Timers:CreateTimer(0, SpiritStormThink)
	DebugPrint("Starting AI for "..thisEntity:GetUnitName().." "..thisEntity:GetEntityIndex())
end

function SpiritStormThink()
	if thisEntity:IsNull() or not thisEntity:IsAlive() then
		return nil
	elseif Ability_ElectricVortex:IsFullyCastable() then
		local units = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, 500, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
		if units ~= nil then
			thisEntity:CastAbilityNoTarget(Ability_ElectricVortex, -1)
		end
	end
	return 2
end
