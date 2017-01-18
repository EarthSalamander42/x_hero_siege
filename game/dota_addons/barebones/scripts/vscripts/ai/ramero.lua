require('libraries/timers')

function Spawn( entityKeyValues )
	Ability_shield = thisEntity:FindAbilityByName("proudmoore_divine_shield")

	Timers:CreateTimer(0, RameroThink)
	DebugPrint("Starting AI for "..thisEntity:GetUnitName().." "..thisEntity:GetEntityIndex())

end

function RameroThink()
	if thisEntity:IsNull() then
		return nil
	elseif Ability_shield:IsFullyCastable() then
		--FindUnitsInRadius( iTeamNumber, vPosition, hCacheUnit, flRadius, iTeamFilter, iTypeFilter, iFlagFilter, iOrder, bCanGrowCache )
		local units = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, 800, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
		local number = 0 
		for _,v in pairs(units) do
			number = number +1
		end
		
		if number >= 1 then
			thisEntity:CastAbilityNoTarget(Ability_shield, -1)
		end
	end
	return 1
end