require('libraries/timers')

function Spawn( entityKeyValues )
	Ability_shield = thisEntity:FindAbilityByName("proudmoore_divine_shield")
	Ability_light_roar = thisEntity:FindAbilityByName("arthas_light_roar")
	Ability_holy_light = thisEntity:FindAbilityByName("arthas_holy_light")

	Timers:CreateTimer(0,ArthasThink)
	DebugPrint("Starting AI for "..thisEntity:GetUnitName().." "..thisEntity:GetEntityIndex())

end

function ArthasThink()
	-- body
	if not thisEntity:IsAlive() then
		return nil
	elseif Ability_shield:IsFullyCastable() then
		--FindUnitsInRadius( iTeamNumber, vPosition, hCacheUnit, flRadius, iTeamFilter, iTypeFilter, iFlagFilter, iOrder, bCanGrowCache )
		local units = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, 800, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
		local number = 0 
		for _,v in pairs(units) do
			number = number +1
		end
		
		if number >= 1 then
			thisEntity:CastAbilityNoTarget(Ability_shield,-1)
		end

	elseif Ability_holy_light:IsFullyCastable() then		
		if thisEntity:GetHealthPercent() <= 85 then
			thisEntity:CastAbilityOnTarget(thisEntity,Ability_holy_light,-1)
		end
	elseif Ability_light_roar:IsFullyCastable() then
		local units = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, 700, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
		local number = 0 
		for _,v in pairs(units) do
			number = number +1
		end
		
		if number >= 1 then
			thisEntity:CastAbilityNoTarget(Ability_light_roar,-1)
		end
	end
	return 1
end