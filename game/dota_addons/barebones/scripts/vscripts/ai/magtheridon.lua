require('libraries/timers')

function Spawn( entityKeyValues )
	Ability_Howl = thisEntity:FindAbilityByName("howl_of_terror")
	Ability_firestorm = thisEntity:FindAbilityByName("creature_firestorm")
	Ability_thunderclap = thisEntity:FindAbilityByName("creature_thunder_clap")

	Timers:CreateTimer(0,MagThink)
	DebugPrint("Starting AI for "..thisEntity:GetUnitName().." "..thisEntity:GetEntityIndex())

end

function MagThink()
	-- body
	if thisEntity:IsNull() or not thisEntity:IsAlive() then
		return nil
	elseif Ability_Howl:IsFullyCastable() then
		--FindUnitsInRadius( iTeamNumber, vPosition, hCacheUnit, flRadius, iTeamFilter, iTypeFilter, iFlagFilter, iOrder, bCanGrowCache )
		local units = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, Ability_Howl:GetSpecialValueFor("radius")-5, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
		if units ~= nil then
			thisEntity:CastAbilityNoTarget(Ability_Howl,-1)
		end
	elseif Ability_thunderclap:IsFullyCastable() then
		local units = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, Ability_thunderclap:GetSpecialValueFor("radius")-5, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
		if units ~= nil then
			thisEntity:CastAbilityNoTarget(Ability_thunderclap,-1)
		end

	elseif Ability_firestorm:IsFullyCastable() then
		local units = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, 800, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)	
		local target = nil
		local number_of_hits = 0

		if units ~= nil then

			for _,unit in pairs(units) do
				local hits = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, 800, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
				if hits ~=nil then
					if #hits > number_of_hits then
						target = unit
						number_of_hits = #hits
					end
				end	
			end
			if target ~= nil then
				thisEntity:CastAbilityOnPosition(target:GetAbsOrigin(),Ability_firestorm,-1)
				return Ability_firestorm:GetCooldown(Ability_firestorm:GetLevel()) +2
			end
		end
	end
	return 2
end