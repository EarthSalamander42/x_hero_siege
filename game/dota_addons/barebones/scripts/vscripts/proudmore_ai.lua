
require('libraries/timers')

function Spawn( entityKeyValues )
	Ability_hex = thisEntity:FindAbilityByName("proudmoore_hex")
	Ability_shield = thisEntity:FindAbilityByName("proudmoore_divine_shield")

	Timers:CreateTimer(0,ProudmooreThink)
	DebugPrint("Starting AI for "..thisEntity:GetUnitName().." "..thisEntity:GetEntityIndex())

end

function ProudmooreThink()
	-- body
	if thisEntity:IsNull() or not thisEntity:IsAlive() then
		return nil
	elseif Ability_shield:IsFullyCastable() then
		local units = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, 800, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
		if units ~= nil and #units>0 then
			thisEntity:CastAbilityNoTarget(Ability_shield,-1)		
		end
	elseif Ability_hex:IsFullyCastable() then
		--FindUnitsInRadius( iTeamNumber, vPosition, hCacheUnit, flRadius, iTeamFilter, iTypeFilter, iFlagFilter, iOrder, bCanGrowCache )
		local units = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, 800, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		if units ~= nil and #units>0 then
			thisEntity:CastAbilityOnTarget(units[1],Ability_hex,-1)
		end
	end
	return 2
end