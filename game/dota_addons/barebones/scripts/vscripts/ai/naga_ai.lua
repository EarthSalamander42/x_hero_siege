require('libraries/timers')

function Spawn( entityKeyValues )
	ABILITY_Starfall = thisEntity:FindAbilityByName( "creature_starfall" )
	Ability_FrostArmor = thisEntity:FindAbilityByName("lich_frost_armor")

	Timers:CreateTimer(0,AbaddonThink)
	DebugPrint("Starting AI for "..thisEntity:GetUnitName().." "..thisEntity:GetEntityIndex())
end

function AbaddonThink()
	if thisEntity:IsNull() then
		return nil
	elseif Ability_FrostArmor and Ability_FrostArmor:IsFullyCastable() then
		local ally = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, 800, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		thisEntity:CastAbilityOnTarget(ally[1], Ability_FrostArmor, -1)
	elseif ABILITY_Starfall:IsFullyCastable() then
		local units = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, ABILITY_Starfall:GetSpecialValueFor("starfall_radius") -75, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
		if units ~= nil then
			thisEntity:CastAbilityNoTarget(ABILITY_Starfall, -1)
		end
	end
	return 1
end
