require('libraries/timers')

function Spawn( entityKeyValues )
	Ability_shield = thisEntity:FindAbilityByName("abaddon_aphotic_shield")
	Ability_chronosphere = thisEntity:FindAbilityByName("creature_chronosphere")

	Timers:CreateTimer(0,AbaddonThink)
	DebugPrint("Starting AI for "..thisEntity:GetUnitName().." "..thisEntity:GetEntityIndex())

end

function AbaddonThink()
	-- body
	if not thisEntity:IsAlive() then
		return nil
	elseif Ability_shield:IsFullyCastable() then
		local units = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, 800, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		thisEntity:CastAbilityOnTarget(units[1],Ability_shield,-1)
	elseif Ability_light_roar:IsFullyCastable() then
		local units = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, 700, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		thisEntity:CastAbilityOnTarget(units[1],Ability_chronosphere,-1)
	end
	return 1
end
