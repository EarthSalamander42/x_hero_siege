require('libraries/timers')

function Spawn( entityKeyValues )
	Ability_Muradin = thisEntity:FindAbilityByName("castle_muradin_defend")

	Timers:CreateTimer(0, CastleThink)
	DebugPrint("Starting AI for "..thisEntity:GetUnitName().." "..thisEntity:GetEntityIndex())
end

function CastleThink()
	if thisEntity:IsNull() then
		return nil
	elseif Ability_Muradin:IsFullyCastable() then		
		if thisEntity:GetHealthPercent() <= 40 then
			thisEntity:CastAbilityNoTarget(Ability_Muradin, -1)
		end
	end
	return 1
end