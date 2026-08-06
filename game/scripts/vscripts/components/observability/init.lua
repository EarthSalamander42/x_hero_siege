if XHSObservability == nil then _G.XHSObservability = class({}) end
local MAX_EVENTS, MAX_BATCH, SEND_INTERVAL, MAX_MESSAGE = 300, 50, 2.0, 1000
local function Now() return RealTime ~= nil and RealTime() or Time() end
local function Bounded(value, maximum)
	value = tostring(value == nil and "" or value):gsub("[\r\n\t]", " ")
	value = value:gsub("([Ss]erver[_%- ]?[Kk]ey%s*[=:]%s*)%S+", "%1[REDACTED]"):gsub("([Tt]oken%s*[=:]%s*)%S+", "%1[REDACTED]")
	return string.sub(value, 1, maximum)
end
local function Fingerprint(category, code, message)
	local normalized = string.lower(Bounded(message, 300)):gsub("0x[%da-f]+", "<hex>"):gsub("%d+%.?%d*", "<n>"):gsub("%s+", " ")
	return Bounded(tostring(category) .. ":" .. tostring(code) .. ":" .. normalized, 160)
end
function XHSObservability:Log(severity, category, code, message, context, source)
	if self.initialized ~= true then return end
	message = Bounded(message, MAX_MESSAGE)
	local fingerprint = Fingerprint(category, code, message)
	local existing = self.pending_by_fingerprint[fingerprint]
	if existing ~= nil then existing.count = existing.count + 1 return end
	self.sequence = self.sequence + 1
	local event = { sequence=self.sequence, game_time=GameRules:GetDOTATime(false,false), phase=CustomTimers ~= nil and tonumber(CustomTimers.game_phase) or 0, severity=severity or "info", category=category or "diagnostic", code=Bounded(code or "XHS_LOG",96), fingerprint=fingerprint, message=message, source=source or "server_lua", count=1, context=type(context)=="table" and context or {} }
	table.insert(self.pending,event) self.pending_by_fingerprint[fingerprint]=event
	if #self.pending > MAX_EVENTS then local dropped=table.remove(self.pending,1); self.pending_by_fingerprint[dropped.fingerprint]=nil; self.dropped=self.dropped+1 end
end
function XHSObservability:Error(code,message,context) self:Log("error","lua_error",code,message,context) end
function XHSObservability:SafeCall(code,callback,...)
	local args={...}
	return xpcall(function() return callback(unpack(args)) end,function(err)
		local trace=debug~=nil and debug.traceback~=nil and debug.traceback(tostring(err),2) or tostring(err)
		self:Error(code or "LUA_CALLBACK_ERROR",trace) return trace
	end)
end
function XHSObservability:TrySend()
	if self.in_flight or #self.pending==0 or api==nil or api.Request==nil or api.game_id==nil or Now()<self.next_send_at then return end
	local events={}; for index=1,math.min(MAX_BATCH,#self.pending) do events[index]=self.pending[index] end
	local payload={schema_version=1,game_id=tonumber(api.game_id),match_id=api:GetMatchID(),build=tostring(GAME_VERSION or ""),dropped=self.dropped,events=events}
	self.in_flight=true
	api:Request("observability/logs",function()
		for _=1,#events do local removed=table.remove(self.pending,1); if removed~=nil then self.pending_by_fingerprint[removed.fingerprint]=nil end end
		self.in_flight=false self.retry_count=0 self.next_send_at=0
	end,function()
		self.in_flight=false self.retry_count=math.min(self.retry_count+1,6) self.next_send_at=Now()+math.min(120,5*(2^(self.retry_count-1)))
	end,"POST",payload)
end
function XHSObservability:CapturePrint(...)
	local parts={}; for index=1,select("#",...) do parts[index]=tostring(select(index,...)) end
	local message=table.concat(parts," "); local lower=string.lower(message)
	if lower:find("observability/logs",1,true) then return end
	if lower:find("error",1,true) or lower:find("failed",1,true) or message:find("[XHS]",1,true) then
		local severity=(lower:find("error",1,true) or lower:find("failed",1,true)) and "error" or "info"
		local category=lower:find("particle",1,true) and "missing_particle" or lower:find("model",1,true) and "missing_model" or "diagnostic"
		self:Log(severity,category,"RUNTIME_PRINT",message,nil,"server_console")
	end
end
function XHSObservability:Init()
	if self.initialized then return end
	self.initialized=true self.pending={} self.pending_by_fingerprint={}
	-- Avoid collisions with rows emitted before a Lua hot reload in the same game.
	self.sequence=math.floor(Now()*1000)*1000
	self.dropped=0 self.in_flight=false self.retry_count=0 self.next_send_at=0
	self.original_print=print
	_G.print=function(...) XHSObservability.original_print(...); XHSObservability:CapturePrint(...) end
	GameRules:GetGameModeEntity():SetContextThink("XHSObservability",function() XHSObservability:TrySend(); return SEND_INTERVAL end,SEND_INTERVAL)
end
return XHSObservability
