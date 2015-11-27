
require('libraries/timers')

function Spawn( entityKeyValues )

	Ability_holy_light = thisEntity:FindAbilityByName("arthas_holy_light")

	Timers:CreateTimer(0,BaristalThink)
	DebugPrint("Starting AI for "..thisEntity:GetUnitName().." "..thisEntity:GetEntityIndex())

end

function BaristalThink()
	-- body
	if thisEntity:IsNull() then
		return nil
	elseif not thisEntity:IsAlive() then
		return nil
	elseif Ability_holy_light:IsFullyCastable() then		
		if thisEntity:GetHealthPercent() <= 90 then
			thisEntity:CastAbilityOnTarget(thisEntity,Ability_holy_light,-1)
		end
	end
	return 1
end