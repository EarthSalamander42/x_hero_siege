
require('libraries/timers')

function Spawn( entityKeyValues )
	Ability_stampede = thisEntity:FindAbilityByName("banehallow_stampede")


	Timers:CreateTimer(0,ArthasThink)
	DebugPrint("Starting AI for "..thisEntity:GetUnitName().." "..thisEntity:GetEntityIndex())

end

function ArthasThink()
	-- body
	if thisEntity:IsNull() or not thisEntity:IsAlive() then
		return nil
	elseif Ability_stampede:IsFullyCastable() then
		--FindUnitsInRadius( iTeamNumber, vPosition, hCacheUnit, flRadius, iTeamFilter, iTypeFilter, iFlagFilter, iOrder, bCanGrowCache )
		local units = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, 1000, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
		if units ~= nil and #units >= 1 then
			thisEntity:CastAbilityNoTarget(Ability_stampede,-1)
		end
	end
	return 1
end