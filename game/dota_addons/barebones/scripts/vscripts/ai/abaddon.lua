require('libraries/timers')

function Spawn( entityKeyValues )
	Ability_chronosphere = thisEntity:FindAbilityByName("creature_chronosphere")


	Timers:CreateTimer(0,AbaddonThink)
	DebugPrint("Starting AI for "..thisEntity:GetUnitName().." "..thisEntity:GetEntityIndex())
end

function AbaddonThink()
	-- body
	if thisEntity:IsNull() or not thisEntity:IsAlive() then
		return nil
	elseif Ability_chronosphere:IsFullyCastable() then
		--FindUnitsInRadius( iTeamNumber, vPosition, hCacheUnit, flRadius, iTeamFilter, iTypeFilter, iFlagFilter, iOrder, bCanGrowCache )
		local units = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, 800, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

		if units ~= nil then
			thisEntity:CastAbilityOnTarget(units[1],Ability_chronosphere,-1)
		end
	end
	return 1
end
