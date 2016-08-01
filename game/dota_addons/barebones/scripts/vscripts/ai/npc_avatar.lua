
require('libraries/timers')

function Spawn( entityKeyValues )
	ability_summon = thisEntity:FindAbilityByName("warden_avatar_summon_spirit")
	Timers:CreateTimer(0,AvatarThink)
	DebugPrint("Starting AI for "..thisEntity:GetUnitName().." "..thisEntity:GetEntityIndex())

end

function AvatarThink()
	-- body
	if not IsValidAlive(thisEntity) then
		return nil
	elseif ability_summon:IsFullyCastable() and ability_summon:GetAutoCastState() then
		DebugPrint("can cast spirit")
		thisEntity:CastAbilityNoTarget(ability_summon,-1)
	end
	return 2
end