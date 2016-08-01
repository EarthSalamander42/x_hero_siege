function sec2Min(secs)
	
	secs = math.floor(secs)

	if secs >= 60 then

		myMinutes = math.floor(secs/60);
		mySeconds = string.format("%02d", secs%60)


		myTime = myMinutes..":"..mySeconds;

	else
		myTime = "0:"..string.format("%02d",secs);

	end

	return myTime;

end


function printEvents()
	local msg = ""
    if Timers.timers[timer_wave_spawn] ~= nil then
      local time = Timers.timers[timer_wave_spawn].endTime-GameRules:GetGameTime()
      if time > 0 then
      	msg = "Next wave incoming in "..sec2Min(time).."."
      	GameRules:SendCustomMessage(msg, DOTA_TEAM_GOODGUYS, 1) 
      end
    end
    if Timers.timers[timer_event_roshan] ~= nil then
      local time = Timers.timers[timer_event_roshan].endTime-GameRules:GetGameTime()
      if time > 0 then
      	msg = "Special Event Roshan starting in "..sec2Min(time).."."
      	GameRules:SendCustomMessage(msg, DOTA_TEAM_GOODGUYS, 1) 
      end
    end
    if Timers.timers[timer_special_arena] ~= nil then
      local time = Timers.timers[timer_special_arena].endTime-GameRules:GetGameTime()
      if time > 0 then
      	msg = "Special Arena starting in "..sec2Min(time).."."
      	GameRules:SendCustomMessage(msg, DOTA_TEAM_GOODGUYS, 1) 
      end
    end
    return (30)
end

function IsValidAlive(ent)
  return IsValidEntity(ent) and ent:IsAlive()
end

