require('libraries/timers')

function Spawn( entityKeyValues )
	Ability_strike = thisEntity:FindAbilityByName("monkey_king_boundless_strike")
	Ability_immolation = thisEntity:FindAbilityByName("demonhunter_immolation")

	Timers:CreateTimer(0, SpiritMasterThink)
end

function SpiritMasterThink()
	if thisEntity:IsNull() then
		return nil
	elseif Ability_strike:IsFullyCastable() then
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
				thisEntity:CastAbilityOnPosition(target:GetAbsOrigin(),Ability_strike, -1)
				return Ability_strike:GetCooldown(Ability_strike:GetLevel()) + 2
			end
		end
	end
	return 1
end
