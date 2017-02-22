require('libraries/timers')

function Spawn(entityKeyValues)
	Ability_mirror_image = thisEntity:FindAbilityByName("grom_hellscream_mirror_image")
	Ability_blade_fury = thisEntity:FindAbilityByName("grom_hellscream_bladefury")

	Timers:CreateTimer(0, GromThink)
	DebugPrint("Starting AI for "..thisEntity:GetUnitName().." "..thisEntity:GetEntityIndex())
end

function GromThink()
	if thisEntity:IsNull() or not thisEntity:IsAlive() then
		return nil
	end

	if thisEntity:IsIllusion() and GameRules:GetCustomGameDifficulty() ~= 4 then
		return nil
	elseif Ability_mirror_image:IsFullyCastable() then
		local units = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, 300, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		local number = 0 
		for _,v in pairs(units) do
			number = number +1
		end

		local units = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, 1000, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		local numberoffriends = 0 
		for _,v in pairs(units) do
			numberoffriends = numberoffriends +1
		end
--		print(numberoffriends)
		if number >= 1 and numberoffriends <= 9 then
			thisEntity:CastAbilityNoTarget(Ability_mirror_image, -1)
		end
	elseif Ability_blade_fury:IsFullyCastable() then
		local units = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil,  Ability_blade_fury:GetSpecialValueFor("radius")-5, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
		if units ~= nil then
			thisEntity:CastAbilityNoTarget(Ability_blade_fury, -1)
		end
	end
	return 2
end
