function OnStartTouch(trigger)
	local triggerName = thisEntity:GetName()
	local activator_entindex = trigger.activator:GetEntityIndex()
	local caller_entindex = trigger.caller:GetEntityIndex()
	local gamemode = GameRules.GameMode

	if gamemode and gamemode.OnTriggerStartTouch then
		gamemode:OnTriggerStartTouch(triggerName, activator_entindex, caller_entindex)
	end
end

function OnEndTouch(trigger)
	local triggerName = thisEntity:GetName()
	local activator_entindex
	if trigger.activator then activator_entindex = trigger.activator:GetEntityIndex() end
	local caller_entindex
	if trigger.caller then caller_entindex = trigger.caller:GetEntityIndex() end
	local gamemode = GameRules.GameMode

	if gamemode and gamemode.OnTriggerEndTouch then
		gamemode:OnTriggerEndTouch(triggerName, activator_entindex, caller_entindex)
	end
end
