require('libraries/timers')

function Spawn( entityKeyValues )
	Ability_black_hole = thisEntity:FindAbilityByName("enigma_black_hole")
	Ability_light_roar = thisEntity:FindAbilityByName("arthas_light_roar")
	Ability_holy_light = thisEntity:FindAbilityByName("arthas_holy_light")

	Timers:CreateTimer(0,ArthasThink)
	DebugPrint("Starting AI for "..thisEntity:GetUnitName().." "..thisEntity:GetEntityIndex())
end

function ArthasThink()
	-- body
	if thisEntity:IsNull() then
		return nil
	elseif Ability_holy_light:IsFullyCastable() then		
		if thisEntity:GetHealthPercent() <= 85 then
			thisEntity:CastAbilityOnTarget(thisEntity,Ability_holy_light,-1)
		end
	elseif Ability_black_hole:IsFullyCastable() then
		local units = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, thisEntity:GetAbsOrigin(), nil, 700, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		if #units ~= nil then
			if #units >= 1 then
				local index = RandomInt( 1, #units )
				local target = units[index]
				thisEntity:CastAbilityOnPosition(target:GetAbsOrigin(), Ability_black_hole, -1)
			end
		end
	end
	return 1
end
