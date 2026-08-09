if XHSObservability == nil then _G.XHSObservability = class({}) end
local MAX_EVENTS, MAX_BATCH, SEND_INTERVAL, MAX_MESSAGE = 300, 50, 2.0, 1000
local LOG_LEVEL_BY_NUMBER = {
	[1] = "debug",
	[2] = "info",
	[3] = "warn",
	[4] = "error",
	[5] = "critical",
}
local VALID_LOG_LEVELS = {
	debug = true,
	info = true,
	warn = true,
	error = true,
	critical = true,
}
local function Now() return RealTime ~= nil and RealTime() or Time() end
local function SafeGameTime()
	if GameRules == nil or GameRules.GetDOTATime == nil then return 0 end
	local ok, value = pcall(function() return GameRules:GetDOTATime(false, false) end)
	return ok and (tonumber(value) or 0) or 0
end
local function Bounded(value, maximum)
	value = tostring(value == nil and "" or value):gsub("[\r\n\t]", " ")
	value = value:gsub("([Ss]erver[_%- ]?[Kk]ey%s*[=:]%s*)%S+", "%1[REDACTED]"):gsub("([Tt]oken%s*[=:]%s*)%S+", "%1[REDACTED]")
	return string.sub(value, 1, maximum)
end
local function NormalizeLogLevel(value)
	local numeric = tonumber(value)
	if numeric ~= nil and LOG_LEVEL_BY_NUMBER[numeric] ~= nil then
		return LOG_LEVEL_BY_NUMBER[numeric]
	end
	local level = string.lower(tostring(value or "info"))
	if level == "warning" then level = "warn" end
	if level == "err" then level = "error" end
	if level == "fatal" then level = "critical" end
	return VALID_LOG_LEVELS[level] and level or "info"
end
local function HasStandaloneWord(value, word)
	return value:find("%f[%w]" .. word .. "%f[%W]") ~= nil
end
local function ClassifyPrintLevel(message)
	local lower = string.lower(tostring(message or ""))
	local explicit = lower:match("^%s*%[([%a]+)%]")
	if explicit ~= nil and (
		VALID_LOG_LEVELS[explicit]
		or explicit == "warning"
		or explicit == "err"
		or explicit == "fatal"
	) then
		return NormalizeLogLevel(explicit)
	end
	if lower:find("script runtime error", 1, true)
		or lower:find("stack traceback", 1, true)
		or lower:find("attempt to ", 1, true)
		or HasStandaloneWord(lower, "error")
		or HasStandaloneWord(lower, "failed")
		or HasStandaloneWord(lower, "failure") then
		return "error"
	end
	return "info"
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
	local event = { sequence=self.sequence, game_time=SafeGameTime(), phase=CustomTimers ~= nil and tonumber(CustomTimers.game_phase) or 0, severity=NormalizeLogLevel(severity), category=category or "diagnostic", code=Bounded(code or "XHS_LOG",96), fingerprint=fingerprint, message=message, source=source or "server_lua", count=1, context=type(context)=="table" and context or {} }
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
function XHSObservability:FallbackToRuntimeLogs(events, reason)
	if api == nil or type(api.QueueRuntimeLog) ~= "function" then return false end
	local queuedOK, queueError = pcall(function()
		for _, event in ipairs(events) do
			local contextText = ""
			if type(event.context) == "table" and json ~= nil and type(json.encode) == "function" then
				local encodedOK, encoded = pcall(json.encode, event.context)
				if encodedOK then contextText = " context=" .. Bounded(encoded, 700) end
			end
			api:QueueRuntimeLog({
				level = NormalizeLogLevel(event.severity),
				content = "[XHS_OBSERVABILITY][" .. tostring(event.category or "diagnostic")
					.. "][" .. tostring(event.code or "XHS_LOG") .. "] "
					.. tostring(event.message or "") .. contextText
					.. " fallback=" .. tostring(reason or "runtime_logs"),
				trace = {},
			})
		end
	end)
	if not queuedOK then
		self.in_flight=false
		self.next_send_at=Now()+5
		if XHSBootstrapNativePrint ~= nil then
			pcall(XHSBootstrapNativePrint, "[error][XHS_OBSERVABILITY] runtime-log fallback failed: "
				.. tostring(queueError))
		end
		return false
	end
	for _=1,#events do
		local removed=table.remove(self.pending,1)
		if removed~=nil then self.pending_by_fingerprint[removed.fingerprint]=nil end
	end
	self.in_flight=false self.retry_count=0 self.next_send_at=0
	return true
end
function XHSObservability:TrySend()
	if self.in_flight or #self.pending==0 or api==nil or api.Request==nil or api.game_id==nil or Now()<self.next_send_at then return end
	local events={}; for index=1,math.min(MAX_BATCH,#self.pending) do events[index]=self.pending[index] end
	if self.use_runtime_log_fallback == true then
		self:FallbackToRuntimeLogs(events, "primary_endpoint_unavailable")
		return
	end
	local payload={schema_version=1,game_id=tonumber(api.game_id),match_id=api:GetMatchID(),build=tostring(GAME_VERSION or ""),dropped=self.dropped,events=events}
	self.in_flight=true
	local requestOK, requestError = pcall(function() api:Request("observability/logs",function()
		for _=1,#events do local removed=table.remove(self.pending,1); if removed~=nil then self.pending_by_fingerprint[removed.fingerprint]=nil end end
		self.in_flight=false self.retry_count=0 self.next_send_at=0
	end,function()
		self.use_runtime_log_fallback=true
		self:FallbackToRuntimeLogs(events, "primary_endpoint_failed")
		if XHSBootstrapLog ~= nil then
			XHSBootstrapLog("warn", "observability/logs unavailable; switched to runtime-logs fallback")
		end
	end,"POST",payload) end)
	if not requestOK then
		self.use_runtime_log_fallback=true
		self:FallbackToRuntimeLogs(events, "primary_request_threw")
		if XHSBootstrapLog ~= nil then
			XHSBootstrapLog("error", "observability request threw before callback: " .. tostring(requestError))
		end
	end
end
function XHSObservability:CapturePrint(...)
	local parts={}; for index=1,select("#",...) do parts[index]=tostring(select(index,...)) end
	local message=table.concat(parts," "); local lower=string.lower(message)
	if lower:find("observability/logs",1,true) then return end
	local severity=ClassifyPrintLevel(message)
	if severity == "error" or severity == "critical"
		or (self.use_runtime_log_fallback ~= true and message:find("[XHS]",1,true)) then
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
	-- The dedicated endpoint currently returns 404; runtime-logs is the live,
	-- verified transport. Keep the primary implementation available for a
	-- future backend rollout without issuing a known-failing request per batch.
	self.use_runtime_log_fallback=true
	self.original_print=print
	_G.print=function(...)
		local args = { ... }
		pcall(XHSObservability.original_print, unpack(args))
		local captureOK, captureError = pcall(function() XHSObservability:CapturePrint(unpack(args)) end)
		if not captureOK and XHSBootstrapNativePrint ~= nil then
			pcall(XHSBootstrapNativePrint, "[error][XHS_OBSERVABILITY] CapturePrint failed: " .. tostring(captureError))
		end
	end
	local thinkOK, thinkError = pcall(function()
		GameRules:GetGameModeEntity():SetContextThink("XHSObservability",function()
			local ok, failure = pcall(function() XHSObservability:TrySend() end)
			if not ok and XHSBootstrapLog ~= nil then
				XHSBootstrapLog("error", "observability think failed: " .. tostring(failure))
			end
			return SEND_INTERVAL
		end,SEND_INTERVAL)
	end)
	self:Log("info", "diagnostic", "OBSERVABILITY_INITIALIZED", "Observability initialized", {
		build = tostring(_G.XHSDiagnosticBuild or ""), think_ok = thinkOK,
	})
	if not thinkOK and XHSBootstrapLog ~= nil then
		XHSBootstrapLog("error", "observability context think registration failed: " .. tostring(thinkError))
	end
end
return XHSObservability
