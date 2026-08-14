-- Supporter Pass UI telemetry bridge.
--
-- Panorama reports a deliberately small, non-economic event vocabulary. This
-- server layer owns player identity, sanitizes metadata, keeps the local debug
-- ring, and forwards bounded/idempotent batches through the authenticated game
-- API. Failed requests retain the same event IDs for safe retries.

local SUPPORTER_UI_EVENT_NAMES = {
	pass_open = true,
	tab = true,
	search = true,
	filter = true,
	detail = true,
	preview_start = true,
	preview_verified = true,
	preview_fail = true,
	preview_stop = true,
}

local SUPPORTER_UI_METADATA = {
	tab = { kind = "text", max = 24 },
	query_length = { kind = "integer", min = 0, max = 500 },
	filter_key = { kind = "text", max = 32 },
	filter_value = { kind = "text", max = 64 },
	item_id = { kind = "text", max = 96 },
	category = { kind = "text", max = 48 },
	candidate_id = { kind = "text", max = 96 },
	result = { kind = "text", max = 32 },
	error_code = { kind = "text", max = 64 },
	duration_ms = { kind = "integer", min = 0, max = 3600000 },
	release_id = { kind = "text", max = 64 },
	client_seq = { kind = "integer", min = 0, max = 2147483647 },
}

local SUPPORTER_UI_LOCAL_BUFFER_SIZE = 128
local SUPPORTER_UI_REMOTE_QUEUE_SIZE = 256
local SUPPORTER_UI_REMOTE_BATCH_SIZE = 64
local SUPPORTER_UI_REMOTE_FLUSH_THRESHOLD = 8
local SUPPORTER_UI_REMOTE_FLUSH_INTERVAL = 5.0
local SUPPORTER_UI_REMOTE_TIMER_INTERVAL = 1.0
local SUPPORTER_UI_REMOTE_RETRY_BASE = 5.0
local SUPPORTER_UI_REMOTE_RETRY_MAX = 120.0
local SUPPORTER_UI_EVENT_RATE_WINDOW = 10.0
local SUPPORTER_UI_EVENT_RATE_LIMIT = 120

local function SupporterTelemetryNow()
	if GameRules ~= nil and GameRules.GetGameTime ~= nil then
		local ok, value = pcall(function() return GameRules:GetGameTime() end)
		if ok and tonumber(value) ~= nil then return tonumber(value) end
	end
	if Time ~= nil then
		local ok, value = pcall(Time)
		if ok and tonumber(value) ~= nil then return tonumber(value) end
	end
	return 0
end

local function CopySupporterTelemetryTable(source)
	local copy = {}
	for key, value in pairs(type(source) == "table" and source or {}) do
		copy[key] = value
	end
	return copy
end

local function NormalizeSupporterTelemetryText(value, maxLength)
	if value == nil then return nil end
	local normalized = tostring(value)
		:gsub("[%z\1-\31\127]", " ")
		:gsub("^%s+", "")
		:gsub("%s+$", "")
	if normalized == "" then return nil end
	normalized = string.sub(normalized, 1, tonumber(maxLength) or 96)

	-- Values, not only keys, are screened as defense in depth. None of the
	-- product analytics dimensions need a path, URL, token, or VPCF name.
	local lower = string.lower(normalized)
	if string.find(lower, "vpcf", 1, true)
		or string.find(lower, "particles/", 1, true)
		or string.find(lower, "http://", 1, true)
		or string.find(lower, "https://", 1, true)
		or string.find(lower, "server_key", 1, true)
		or string.find(lower, "api_key", 1, true)
		or string.find(lower, "password", 1, true)
		or string.find(lower, "secret", 1, true)
		or string.find(lower, "token", 1, true) then
		return nil
	end
	return normalized
end

local function SanitizeSupporterTelemetryMetadata(value)
	local source = type(value) == "table" and value or {}
	local metadata = {}
	for key, spec in pairs(SUPPORTER_UI_METADATA) do
		local fieldValue = source[key]
		if fieldValue ~= nil then
			if spec.kind == "integer" then
				local numberValue = tonumber(fieldValue)
				if numberValue ~= nil then
					numberValue = math.floor(numberValue)
					metadata[key] = math.max(spec.min, math.min(spec.max, numberValue))
				end
			elseif type(fieldValue) == "string"
				or type(fieldValue) == "number"
				or type(fieldValue) == "boolean" then
				metadata[key] = NormalizeSupporterTelemetryText(fieldValue, spec.max)
			end
		end
	end
	return metadata
end

local function NormalizeSupporterTelemetryID(value, fallback)
	local normalized = tostring(value or "")
		:gsub("[^%w_.:%-]", "-")
		:gsub("^[-_.:]+", "")
		:sub(1, 160)
	if normalized == "" then return fallback or "supporter-pass" end
	return normalized
end

function Battlepass:GetSupporterPassTelemetrySessionID()
	if type(self.SupporterPassTelemetrySessionID) == "string"
		and self.SupporterPassTelemetrySessionID ~= "" then
		return self.SupporterPassTelemetrySessionID
	end

	local matchID = "0"
	if api ~= nil and api.GetMatchID ~= nil then
		local ok, value = pcall(function() return api:GetMatchID() end)
		if ok and value ~= nil and tostring(value) ~= "" then matchID = tostring(value) end
	end
	local unique = nil
	if DoUniqueString ~= nil then
		local ok, value = pcall(DoUniqueString, "sp-ui")
		if ok then unique = value end
	end
	unique = unique or tostring(math.floor(SupporterTelemetryNow() * 1000))
	self.SupporterPassTelemetrySessionID = NormalizeSupporterTelemetryID(
		"sp." .. matchID .. "." .. tostring(unique),
		"sp.0.0"
	)
	return self.SupporterPassTelemetrySessionID
end

function Battlepass:GetSupporterPassTelemetryPlayerState(playerID, steamID)
	self.SupporterPassTelemetryRemote = self.SupporterPassTelemetryRemote or {
		session_id = self:GetSupporterPassTelemetrySessionID(),
		players = {},
	}
	local key = tostring(steamID)
	local state = self.SupporterPassTelemetryRemote.players[key]
	if type(state) ~= "table" then
		state = {
			player_id = playerID,
			steamid = key,
			queue = {},
			in_flight = nil,
			retry_count = 0,
			next_retry_at = 0,
			first_queued_at = 0,
			dropped = 0,
		}
		self.SupporterPassTelemetryRemote.players[key] = state
	end
	state.player_id = playerID
	return state
end

function Battlepass:IsSupporterPassUIEventRateAllowed(playerID)
	self.SupporterPassUIEventRate = self.SupporterPassUIEventRate or {}
	local now = SupporterTelemetryNow()
	local rate = self.SupporterPassUIEventRate[playerID]
	if type(rate) ~= "table"
		or now - (tonumber(rate.started_at) or 0) >= SUPPORTER_UI_EVENT_RATE_WINDOW then
		rate = { started_at = now, count = 0 }
		self.SupporterPassUIEventRate[playerID] = rate
	end
	rate.count = (tonumber(rate.count) or 0) + 1
	return rate.count <= SUPPORTER_UI_EVENT_RATE_LIMIT
end

function Battlepass:RecordSupporterPassUILocalEvent(playerID, steamID, payload)
	if playerID == nil or type(payload) ~= "table" then return nil end
	self.SupporterPassUILocalEvents = self.SupporterPassUILocalEvents or {}
	self.SupporterPassUIEventSequence = (tonumber(self.SupporterPassUIEventSequence) or 0) + 1
	local records = self.SupporterPassUILocalEvents[playerID]
	if type(records) ~= "table" then
		records = {}
		self.SupporterPassUILocalEvents[playerID] = records
	end
	local record = {
		sequence = self.SupporterPassUIEventSequence,
		player_id = playerID,
		steamid = tostring(steamID),
		game_time = SupporterTelemetryNow(),
		source = "panorama",
		client_reported = true,
		event_name = payload.event_name,
		client_seq = payload.client_seq,
		metadata = CopySupporterTelemetryTable(payload.metadata),
	}
	table.insert(records, record)
	if #records > SUPPORTER_UI_LOCAL_BUFFER_SIZE then table.remove(records, 1) end
	return record
end

function Battlepass:QueueSupporterPassUIRemoteEvent(playerID, steamID, payload)
	local state = self:GetSupporterPassTelemetryPlayerState(playerID, steamID)
	self.SupporterPassTelemetryEventSequence =
		(tonumber(self.SupporterPassTelemetryEventSequence) or 0) + 1
	local event = {
		event_id = NormalizeSupporterTelemetryID(
			self:GetSupporterPassTelemetrySessionID()
				.. "." .. tostring(steamID)
				.. "." .. tostring(self.SupporterPassTelemetryEventSequence),
			"sp.0." .. tostring(self.SupporterPassTelemetryEventSequence)
		),
		event_name = payload.event_name,
		steamid = tostring(steamID),
		client_seq = payload.client_seq,
		metadata = CopySupporterTelemetryTable(payload.metadata),
	}

	local protected = type(state.in_flight) == "table" and #state.in_flight or 0
	if #state.queue >= SUPPORTER_UI_REMOTE_QUEUE_SIZE then
		if protected < #state.queue then
			table.remove(state.queue, protected + 1)
			state.dropped = state.dropped + 1
		else
			state.dropped = state.dropped + 1
			return false
		end
	end
	if #state.queue == 0 then state.first_queued_at = SupporterTelemetryNow() end
	table.insert(state.queue, event)
	self:EnsureSupporterPassTelemetryTimer()
	if #state.queue >= SUPPORTER_UI_REMOTE_FLUSH_THRESHOLD then
		self:TryFlushSupporterPassTelemetryState(state, false)
	end
	return true
end

local function RemoveSupporterTelemetrySnapshot(state, snapshot)
	local sent = {}
	for _, event in ipairs(type(snapshot) == "table" and snapshot or {}) do
		sent[event.event_id] = true
	end
	local kept = {}
	for _, event in ipairs(state.queue) do
		if sent[event.event_id] ~= true then table.insert(kept, event) end
	end
	state.queue = kept
end

function Battlepass:TryFlushSupporterPassTelemetryState(state, force)
	if type(state) ~= "table" or state.in_flight ~= nil or #state.queue == 0 then return false end
	if api == nil or api.Request == nil or api.xhs_bot_session_backend_disabled == true then return false end
	local gameID = tonumber(api.GetApiGameId ~= nil and api:GetApiGameId() or api.game_id)
	if gameID == nil or gameID <= 0 then return false end

	local now = SupporterTelemetryNow()
	if now < (tonumber(state.next_retry_at) or 0) then return false end
	if force ~= true
		and #state.queue < SUPPORTER_UI_REMOTE_FLUSH_THRESHOLD
		and now - (tonumber(state.first_queued_at) or now) < SUPPORTER_UI_REMOTE_FLUSH_INTERVAL then
		return false
	end

	local snapshot = {}
	for index = 1, math.min(#state.queue, SUPPORTER_UI_REMOTE_BATCH_SIZE) do
		table.insert(snapshot, state.queue[index])
	end
	if #snapshot == 0 then return false end
	state.in_flight = snapshot

	local requestOK = pcall(function()
		api:Request("supporter-pass/telemetry", function()
			RemoveSupporterTelemetrySnapshot(state, snapshot)
			state.in_flight = nil
			state.retry_count = 0
			state.next_retry_at = 0
			state.first_queued_at = #state.queue > 0 and SupporterTelemetryNow() or 0
			if #state.queue >= SUPPORTER_UI_REMOTE_FLUSH_THRESHOLD then
				self:TryFlushSupporterPassTelemetryState(state, false)
			end
		end, function()
			state.in_flight = nil
			state.retry_count = math.min((tonumber(state.retry_count) or 0) + 1, 6)
			state.next_retry_at = SupporterTelemetryNow() + math.min(
				SUPPORTER_UI_REMOTE_RETRY_MAX,
				SUPPORTER_UI_REMOTE_RETRY_BASE * (2 ^ (state.retry_count - 1))
			)
		end, "POST", {
			game_id = gameID,
			session_id = self:GetSupporterPassTelemetrySessionID(),
			events = snapshot,
		})
	end)
	if not requestOK then
		state.in_flight = nil
		state.retry_count = math.min((tonumber(state.retry_count) or 0) + 1, 6)
		state.next_retry_at = SupporterTelemetryNow() + math.min(
			SUPPORTER_UI_REMOTE_RETRY_MAX,
			SUPPORTER_UI_REMOTE_RETRY_BASE * (2 ^ (state.retry_count - 1))
		)
		return false
	end
	return true
end

function Battlepass:FlushSupporterPassTelemetry(force)
	local remote = self.SupporterPassTelemetryRemote
	local pending = false
	for _, state in pairs(type(remote) == "table" and remote.players or {}) do
		if #state.queue > 0 then
			pending = true
			self:TryFlushSupporterPassTelemetryState(state, force == true)
		end
	end
	return pending
end

function Battlepass:EnsureSupporterPassTelemetryTimer()
	if self.SupporterPassTelemetryTimerStarted == true then return end
	if Timers == nil or Timers.CreateTimer == nil then return end
	self.SupporterPassTelemetryTimerStarted = true
	Timers:CreateTimer(SUPPORTER_UI_REMOTE_TIMER_INTERVAL, function()
		if Battlepass == nil or Battlepass.FlushSupporterPassTelemetry == nil then return nil end
		local pending = Battlepass:FlushSupporterPassTelemetry(false)
		if pending then return SUPPORTER_UI_REMOTE_TIMER_INTERVAL end
		Battlepass.SupporterPassTelemetryTimerStarted = false
		return nil
	end)
end

local function ResolveSupporterTelemetrySender(eventSourceIndex, event)
	if api == nil
		or api.GetEventPlayerID == nil
		or api.IsPersistentPlayerID == nil
		or api.GetPersistentPlayerSteamID == nil then
		return nil, nil
	end
	local ok, playerID = pcall(function()
		return api:GetEventPlayerID(eventSourceIndex, event)
	end)
	playerID = ok and tonumber(playerID) or nil
	if playerID == nil or not api:IsPersistentPlayerID(playerID) then return nil, nil end
	local steamID = api:GetPersistentPlayerSteamID(playerID)
	if steamID == nil then return nil, nil end
	return playerID, tostring(steamID)
end

function Battlepass:SupporterPassUIEvent(eventSourceIndex, event)
	if type(event) ~= "table" then return end
	local playerID, steamID = ResolveSupporterTelemetrySender(eventSourceIndex, event)
	if playerID == nil or steamID == nil then return end
	if not self:IsSupporterPassUIEventRateAllowed(playerID) then return end

	local eventName = NormalizeSupporterTelemetryText(event.event_name, 32)
	eventName = eventName ~= nil and string.lower(eventName) or nil
	if eventName == nil or SUPPORTER_UI_EVENT_NAMES[eventName] ~= true then return end

	local metadata = SanitizeSupporterTelemetryMetadata(event.metadata)
	local clientSeq = tonumber(event.client_seq)
		or tonumber(metadata.client_seq)
	if clientSeq ~= nil then
		clientSeq = math.max(0, math.min(2147483647, math.floor(clientSeq)))
		metadata.client_seq = clientSeq
	end
	local payload = {
		event_name = eventName,
		client_seq = clientSeq,
		metadata = metadata,
	}
	self:RecordSupporterPassUILocalEvent(playerID, steamID, payload)
	self:QueueSupporterPassUIRemoteEvent(playerID, steamID, payload)
end

CustomGameEventManager:RegisterListener(
	"supporter_pass_ui_event",
	Dynamic_Wrap(Battlepass, "SupporterPassUIEvent")
)

return {
	EVENT_NAMES = SUPPORTER_UI_EVENT_NAMES,
	METADATA = SUPPORTER_UI_METADATA,
	MAX_BATCH = SUPPORTER_UI_REMOTE_BATCH_SIZE,
}
