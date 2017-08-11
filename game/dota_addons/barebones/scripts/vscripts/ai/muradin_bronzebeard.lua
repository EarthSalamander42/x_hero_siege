
require('libraries/timers')

function Spawn( entityKeyValues )
	Ability_stormbolt = thisEntity:FindAbilityByName("roshan_stormbolt")
	Ability_clap = thisEntity:FindAbilityByName("creature_thunder_clap_low")
	waypoints = {
		{Entities:FindByName(nil, "roshan_wp_"..1),Entities:FindByName(nil, "roshan_wp_"..2),Entities:FindByName(nil, "roshan_wp_"..3),Entities:FindByName(nil, "roshan_wp_"..4)},
		{Entities:FindByName(nil, "roshan_wp_"..2),Entities:FindByName(nil, "roshan_wp_"..3),Entities:FindByName(nil, "roshan_wp_"..4)},
		{Entities:FindByName(nil, "roshan_wp_"..1),Entities:FindByName(nil, "roshan_wp_"..3),Entities:FindByName(nil, "roshan_wp_"..4)},
		{Entities:FindByName(nil, "roshan_wp_"..1),Entities:FindByName(nil, "roshan_wp_"..2),Entities:FindByName(nil, "roshan_wp_"..4)},
		{Entities:FindByName(nil, "roshan_wp_"..1),Entities:FindByName(nil, "roshan_wp_"..2),Entities:FindByName(nil, "roshan_wp_"..3)}
	}

	Timers:CreateTimer(0, RoshanThink)
	Timers:CreateTimer(0, RoshanWalk)

	DebugPrint("Starting AI for "..thisEntity:GetUnitName().." "..thisEntity:GetEntityIndex())
end

function RoshanThink()
if thisEntity:IsNull() or not thisEntity:IsAlive() then return end

	if Ability_stormbolt:IsFullyCastable() then
		--FindUnitsInRadius( iTeamNumber, vPosition, hCacheUnit, flRadius, iTeamFilter, iTypeFilter, iFlagFilter, iOrder, bCanGrowCache )
		local units = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, Ability_stormbolt:GetCastRange(nil, nil), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
		if units then
			for _, unit in pairs(units) do
				if unit:IsInvisible() then return end
				thisEntity:CastAbilityOnTarget(units[1],Ability_stormbolt,-1)
			end
		end
	elseif Ability_clap:IsFullyCastable() then
		local units = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, Ability_clap:GetLevelSpecialValueFor("radius", Ability_clap:GetLevel()-1), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
		local number = 0 
		for _, unit in pairs(units) do
			number = number +1
		end

		if number >= 1 then
			thisEntity:CastAbilityNoTarget(Ability_clap,-1)
		end
	end
	return 2.0
end

function RoshanWalk()
if thisEntity:IsNull() or not thisEntity:IsAlive() then return end
local wp = thisEntity:GetInitialGoalEntity()

	if wp then
	local i,j = string.find(wp:GetName(),"%d")
	local number = string.sub(wp:GetName(),i,j)
		thisEntity:MoveToPositionAggressive(waypoints[number+1][RandomInt(1, 3)]:GetAbsOrigin())
	else
		thisEntity:MoveToPositionAggressive(waypoints[1][RandomInt(1, 4)]:GetAbsOrigin())
	end
	return RandomInt(2,4)
end
