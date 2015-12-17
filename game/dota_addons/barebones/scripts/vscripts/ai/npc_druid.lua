--[[
npc_priest ai
]]
-- "vscripts"			"ai/npc_priest.lua"
require('libraries/timers')

function Spawn( entityKeyValues )
	Ability_roar = thisEntity:FindAbilityByName("druid_roar")
	Ability_trueform = thisEntity:FindAbilityByName("druid_true_form")
	Timers:CreateTimer(0,DruidThink)
	DebugPrint("Starting AI for "..thisEntity:GetUnitName().." "..thisEntity:GetEntityIndex())

end

function DruidThink()
	-- body
	local minimalTargets = 7
	if thisEntity:IsNull() or not thisEntity:IsAlive() then
		return nil
	elseif Ability_roar:IsFullyCastable() then
		DebugPrint("can cast roar")
		--FindUnitsInRadius( iTeamNumber, vPosition, hCacheUnit, flRadius, iTeamFilter, iTypeFilter, iFlagFilter, iOrder, bCanGrowCache )
		local units = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, Ability_roar:GetSpecialValueFor("radius")-5, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
		if units ~= nil then
			--If there are more units without the buff than minimal targets then cast roar
			local numberOfTargets = 0
			for _,unit in pairs(units) do
				if not unit:HasModifier("modifier_roar") then
					numberOfTargets = numberOfTargets +1
				end
			end
			if numberOfTargets >=minimalTargets then
				DebugPrint("castingAbility roar")
				thisEntity:CastAbilityNoTarget(Ability_roar,-1)
			end
		end
	elseif Ability_trueform:IsFullyCastable() and not thisEntity:HasModifier("modifier_true_form") then
		local units = FindUnitsInRadius(thisEntity:GetTeamNumber(), thisEntity:GetAbsOrigin(), nil, Ability_roar:GetSpecialValueFor("radius")-5, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		if #units >=1 then
			DebugPrint("toggle Ability trueform")
			Ability_trueform:ToggleAbility()
		end
	end
	return 2
end