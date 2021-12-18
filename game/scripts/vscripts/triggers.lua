function OnStartTouch( trigger )
local triggerName = thisEntity:GetName()
local activator_entindex = trigger.activator:GetEntityIndex()
local caller_entindex = trigger.caller:GetEntityIndex()
local gamemode = GameRules.GameMode

	gamemode:OnTriggerStartTouch( triggerName, activator_entindex, caller_entindex )
end

function OnEndTouch( trigger )
local triggerName = thisEntity:GetName()
local activator_entindex = trigger.activator:GetEntityIndex()
local caller_entindex = trigger.caller:GetEntityIndex()
local gamemode = GameRules.GameMode

	gamemode:OnTriggerEndTouch( triggerName, activator_entindex, caller_entindex )
end
