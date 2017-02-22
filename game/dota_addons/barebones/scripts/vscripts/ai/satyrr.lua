require('libraries/timers')

function Spawn( entityKeyValues )
	Ability_Bloodlust = thisEntity:FindAbilityByName("ogre_magi_bloodlust")

	Timers:CreateTimer(0, SatyrrThink)
end

function SatyrrThink()
	if thisEntity:IsNull() then
		return nil
	elseif Ability_Bloodlust and Ability_Bloodlust:IsFullyCastable() then
		local ally = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, 800, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		thisEntity:CastAbilityOnTarget(ally[1], Ability_Bloodlust, -1)
	end
	return 1
end
