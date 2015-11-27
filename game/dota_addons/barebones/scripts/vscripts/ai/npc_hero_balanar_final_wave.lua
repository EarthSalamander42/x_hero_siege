
require('libraries/timers')

function Spawn( entityKeyValues )

	Ability_Sleep = thisEntity:FindAbilityByName("balanar_sleep")

	Timers:CreateTimer(0,BalanarThink)
	DebugPrint("Starting AI for "..thisEntity:GetUnitName().." "..thisEntity:GetEntityIndex())

end

function BalanarThink()
	-- body
	if thisEntity:IsNull() or not thisEntity:IsAlive() then
		return nil
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
			if numberOfTargets >=2 then
				thisEntity:CastAbilityOnTarget(units[1],Ability_Sleep,-1)
			end
		end
	end
	return 2
end