require('libraries/timers')

function Spawn( entityKeyValues )
	Ability_sleep = thisEntity:FindAbilityByName("balanar_sleep")

	Timers:CreateTimer(0, BalanarThink)
	DebugPrint("Starting AI for "..thisEntity:GetUnitName().." "..thisEntity:GetEntityIndex())

end

function BalanarThink()
	-- body
	if thisEntity:IsNull() or not thisEntity:IsAlive() then
		return nil		
	elseif Ability_sleep:IsFullyCastable() then
		--FindUnitsInRadius( iTeamNumber, vPosition, hCacheUnit, flRadius, iTeamFilter, iTypeFilter, iFlagFilter, iOrder, bCanGrowCache )
		local units = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, 500, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

		if units ~= nil and units > 1 then
			thisEntity:CastAbilityOnTarget(units[1],Ability_sleep,-1)
		end
	end
	return 2
end
