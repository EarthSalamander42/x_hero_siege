require('libraries/timers')

function Spawn( entityKeyValues )
	Ability_shield = thisEntity:FindAbilityByName("abaddon_aphotic_shield")
	Ability_immolation = thisEntity:FindAbilityByName("demonhunter_immolation")
	Ability_chronosphere = thisEntity:FindAbilityByName("creature_chronosphere")

	Timers:CreateTimer(0,AbaddonThink)
	DebugPrint("Starting AI for "..thisEntity:GetUnitName().." "..thisEntity:GetEntityIndex())
end

function AbaddonThink()
	if thisEntity:IsNull() then
		return nil
	elseif Ability_shield and Ability_shield:IsFullyCastable() then
		local ally = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, 800, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		thisEntity:CastAbilityOnTarget(ally[1], Ability_shield, -1)
	elseif Ability_immolation:IsFullyCastable() and not Ability_immolation:GetToggleState() then
		local units = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, Ability_immolation:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
		if units ~= nil then
			thisEntity:CastAbilityToggle(Ability_immolation,-1)
		end
	elseif Ability_chronosphere and Ability_chronosphere:IsFullyCastable() then
		local units = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, thisEntity:GetAbsOrigin(), nil, 700, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		if #units ~= nil then
			if #units >= 1 then
				local index = RandomInt( 1, #units )
				local target = units[index]
				thisEntity:CastAbilityOnPosition(target:GetAbsOrigin(), Ability_chronosphere, -1)
			end
		end
	end
	return 1
end
