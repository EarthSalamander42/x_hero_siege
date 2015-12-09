
require('libraries/timers')

function Spawn( entityKeyValues )
	Ability_stormbolt = thisEntity:FindAbilityByName("roshan_stormbolt")
	Ability_clap = thisEntity:FindAbilityByName("roshan_clap")
	roshan_grow = thisEntity:FindAbilityByName("roshan_grow")
	waypoints = {
				{Entities:FindByName(nil, "roshan_wp_"..1),Entities:FindByName(nil, "roshan_wp_"..2),Entities:FindByName(nil, "roshan_wp_"..3),Entities:FindByName(nil, "roshan_wp_"..4)},
				{Entities:FindByName(nil, "roshan_wp_"..2),Entities:FindByName(nil, "roshan_wp_"..3),Entities:FindByName(nil, "roshan_wp_"..4)},
				{Entities:FindByName(nil, "roshan_wp_"..1),Entities:FindByName(nil, "roshan_wp_"..3),Entities:FindByName(nil, "roshan_wp_"..4)},
				{Entities:FindByName(nil, "roshan_wp_"..1),Entities:FindByName(nil, "roshan_wp_"..2),Entities:FindByName(nil, "roshan_wp_"..4)},
				{Entities:FindByName(nil, "roshan_wp_"..1),Entities:FindByName(nil, "roshan_wp_"..2),Entities:FindByName(nil, "roshan_wp_"..3)}
				}

	Timers:CreateTimer(0,RoshanThink)
	Timers:CreateTimer(0,RoshanWalk)

	DebugPrint("Starting AI for "..thisEntity:GetUnitName().." "..thisEntity:GetEntityIndex())
end

function RoshanThink()
	-- body
	if thisEntity:IsNull() then
		return nil
	elseif not thisEntity:IsAlive() then
		return nil
	elseif Ability_stormbolt:IsFullyCastable() then
		--FindUnitsInRadius( iTeamNumber, vPosition, hCacheUnit, flRadius, iTeamFilter, iTypeFilter, iFlagFilter, iOrder, bCanGrowCache )
		local units = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, Ability_stormbolt:GetCastRange(nil, nil), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
		if units ~= nil then
			thisEntity:CastAbilityOnTarget(units[1],Ability_stormbolt,-1)
		end
	elseif Ability_clap:IsFullyCastable() then
		--FindUnitsInRadius( iTeamNumber, vPosition, hCacheUnit, flRadius, iTeamFilter, iTypeFilter, iFlagFilter, iOrder, bCanGrowCache )
		local units = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, Ability_clap:GetLevelSpecialValueFor("radius", Ability_clap:GetLevel()-1), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
		local number = 0 
		for _,v in pairs(units) do
			number = number +1
		end

		if number >= 1 then
			thisEntity:CastAbilityNoTarget(Ability_clap,-1)
		end
	end
	return 1
end

function RoshanWalk()
	-- body

	if thisEntity:IsNull() then
		return nil
	elseif not thisEntity:IsAlive() then
		return nil
	else
		local wp = thisEntity:GetInitialGoalEntity()
		if wp ~= nil then
			local i,j = string.find(wp:GetName(),"%d")
    		local number = string.sub(wp:GetName(),i,j)
			thisEntity:MoveToPositionAggressive(waypoints[number+1][RandomInt(1, 3)]:GetAbsOrigin())
		else
			thisEntity:MoveToPositionAggressive(waypoints[1][RandomInt(1, 4)]:GetAbsOrigin())
		end
	end
	return RandomInt(2,4)
end

function RoshanGrow()
	-- body
	if thisEntity:IsNull() then
		return nil
	elseif not thisEntity:IsAlive() then
		return nil
	elseif roshan_grow:IsFullyCastable() then
		thisEntity:CastAbilityNoTarget(roshan_grow,-1)
		return nil
	end
	return 1
end