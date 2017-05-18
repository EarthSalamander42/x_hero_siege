require('libraries/timers')

function Spawn( entityKeyValues )
	Ability_Howl = thisEntity:FindAbilityByName("howl_of_terror")
	Ability_Sleep = thisEntity:FindAbilityByName("balanar_sleep")
	Ability_Chaosrain = thisEntity:FindAbilityByName("balanar_rain_of_chaos")

	Timers:CreateTimer(0, BalanarThink)
	DebugPrint("Starting AI for "..thisEntity:GetUnitName().." "..thisEntity:GetEntityIndex())
end

function BalanarThink()
	if thisEntity:IsNull() or not thisEntity:IsAlive() then
		return nil
	elseif Ability_Howl:IsFullyCastable() then
		local units = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, Ability_Howl:GetSpecialValueFor("radius")-5, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
		if units ~= nil and #units >=1 then
			thisEntity:CastAbilityNoTarget(Ability_Howl, -1)
		end
	elseif Ability_Chaosrain:IsFullyCastable() then
		local units = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, 400, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
--		if units ~= nil and #units >=1 then
		if units ~= nil then
			thisEntity:CastAbilityNoTarget(Ability_Chaosrain, -1)
		end
	elseif Ability_Sleep:IsFullyCastable() then
		local units = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, Ability_Sleep:GetSpecialValueFor("radius")-5, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
		if units ~= nil then
			--If there are more units without the buff than minimal targets then cast roar
			local numberOfTargets = 0
			for _,unit in pairs(units) do
				if not unit:HasModifier("modifier_sleep") then
					numberOfTargets = numberOfTargets +1
				end
			end
			
			if numberOfTargets >= 0 then
				thisEntity:CastAbilityOnTarget(units[1], Ability_Sleep, -1)
			end
		end
	end
	return 2.0
end
