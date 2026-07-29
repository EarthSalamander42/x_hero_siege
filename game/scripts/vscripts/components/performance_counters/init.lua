if XHSPerformanceCounters == nil then
	_G.XHSPerformanceCounters = class({})
end

local WINDOW_SECONDS = 1.0
local SOURCE_SAMPLE_EVERY = 4
local MAX_SOURCE_ROWS = 8

local COUNTER_NAMES = {
	"zone_searches",
	"zone_results",
	"zone_search_cost_ms",
	"zone_searches_suppressed",
	"spatial_cache_hits",
	"spatial_cache_misses",
	"orders",
	"orders_suppressed",
	"repeated_orders",
	"ai_thinks",
	"ai_director_ticks",
	"ai_agents_registered",
	"ai_agents_processed",
	"ai_agents_sleeping",
	"ai_profile_builds",
	"ai_profile_cache_hits",
	"ai_no_active_profiles",
	"wave_thinks",
	"ability_loop_thinks",
	"damage_events",
	"ability_casts",
	"tracking_projectiles",
	"linear_projectiles",
	"unit_spawns",
	"unit_deaths",
	"target_changes",
}

local function RealNow()
	if RealTime ~= nil then return RealTime() end
	if Time ~= nil then return Time() end
	return GameRules:GetGameTime()
end

local function Round(value, precision)
	local multiplier = 10 ^ (precision or 0)
	return math.floor((tonumber(value) or 0) * multiplier + 0.5) / multiplier
end

local function NewCounterWindow()
	local counters = {}
	for _, name in ipairs(COUNTER_NAMES) do
		counters[name] = 0
	end
	return counters
end

local function CleanSource(source)
	source = tostring(source or "unknown")
	source = string.gsub(source, "^@", "")
	source = string.gsub(source, "\\", "/")
	local marker = "scripts/vscripts/"
	local markerStart = string.find(source, marker, 1, true)
	if markerStart ~= nil then
		source = string.sub(source, markerStart + #marker)
	end
	return source
end

local function GetCallerSource(stackLevel)
	if not IsInToolsMode() or debug == nil or debug.getinfo == nil then return "unknown:0" end
	local info = debug.getinfo(stackLevel or 3, "Sl")
	local source = CleanSource(info and (info.short_src or info.source) or "unknown")
	local line = info and tonumber(info.currentline) or 0
	return source .. ":" .. tostring(line)
end

function XHSPerformanceCounters:Increment(name, amount)
	if self.window == nil then return end
	self.window[name] = (tonumber(self.window[name]) or 0) + (tonumber(amount) or 1)
end

function XHSPerformanceCounters:TrackSource(bucketName, resultCount, elapsedMs, stackLevel)
	if not IsInToolsMode() or debug == nil or debug.getinfo == nil then return end

	self.source_sample_sequence = (self.source_sample_sequence or 0) + 1
	if self.source_sample_sequence % SOURCE_SAMPLE_EVERY ~= 0 then return end

	local key = GetCallerSource((stackLevel or 3) + 1)
	local bucket = self.source_windows[bucketName]
	bucket[key] = bucket[key] or {
		source = key,
		samples = 0,
		results = 0,
		cost_ms = 0,
	}
	bucket[key].samples = bucket[key].samples + 1
	bucket[key].results = bucket[key].results + (tonumber(resultCount) or 0)
	bucket[key].cost_ms = bucket[key].cost_ms + (tonumber(elapsedMs) or 0)
	self.observed_sources[bucketName] = self.observed_sources[bucketName] or {}
	self.observed_sources[bucketName][key] = RealNow()
end

function XHSPerformanceCounters:IsObservedSource(bucketName, source)
	return self.observed_sources ~= nil
		and self.observed_sources[bucketName] ~= nil
		and self.observed_sources[bucketName][tostring(source or "")] ~= nil
end

function XHSPerformanceCounters:BuildTopSources(bucketName, elapsed)
	local rows = {}
	for _, record in pairs(self.source_windows[bucketName] or {}) do
		table.insert(rows, {
			source = record.source,
			calls_per_second = Round(record.samples * SOURCE_SAMPLE_EVERY / elapsed, 1),
			results_per_second = Round(record.results * SOURCE_SAMPLE_EVERY / elapsed, 1),
			cost_ms_per_second = Round(record.cost_ms * SOURCE_SAMPLE_EVERY / elapsed, 2),
		})
	end
	table.sort(rows, function(left, right)
		if left.cost_ms_per_second == right.cost_ms_per_second then
			return left.calls_per_second > right.calls_per_second
		end
		return left.cost_ms_per_second > right.cost_ms_per_second
	end)

	local top = {}
	for index = 1, math.min(MAX_SOURCE_ROWS, #rows) do
		top[index] = rows[index]
	end
	return top
end

function XHSPerformanceCounters:RollWindow(now)
	local elapsed = math.max(0.001, now - self.window_started_at)
	local snapshot = {
		window_seconds = Round(elapsed, 2),
		host_timescale = Convars ~= nil
			and Round(math.max(0.01, Convars:GetFloat("host_timescale")), 2)
			or 1,
		real_clock = RealTime ~= nil and 1 or 0,
		zone_search_max_ms = Round(self.zone_search_max_ms or 0, 2),
		top_zone_sources = self:BuildTopSources("zone", elapsed),
		top_order_sources = self:BuildTopSources("order", elapsed),
	}

	for _, name in ipairs(COUNTER_NAMES) do
		snapshot[name .. "_per_second"] = Round((self.window[name] or 0) / elapsed, 1)
	end
	-- Historical "zone_*" keys actually describe every FindUnitsInRadius call
	-- in the addon. Keep them for compatibility while publishing accurate names.
	snapshot.spatial_queries_per_second = snapshot.zone_searches_per_second
	snapshot.spatial_results_per_second = snapshot.zone_results_per_second
	snapshot.spatial_query_cost_ms_per_second = snapshot.zone_search_cost_ms_per_second
	snapshot.spatial_query_max_ms = snapshot.zone_search_max_ms
	snapshot.top_spatial_sources = snapshot.top_zone_sources
	snapshot.projectiles_per_second = Round(
		((self.window.tracking_projectiles or 0) + (self.window.linear_projectiles or 0)) / elapsed,
		1
	)

	self.snapshot = snapshot
	table.insert(self.history, snapshot)
	if #self.history > 10 then table.remove(self.history, 1) end
	self.window = NewCounterWindow()
	self.source_windows = { zone = {}, order = {} }
	self.zone_search_max_ms = 0
	self.window_started_at = now
end

function XHSPerformanceCounters:GetSnapshot()
	return self.snapshot or {}
end

function XHSPerformanceCounters:GetAggregateSnapshot(windowCount)
	windowCount = math.max(1, math.floor(tonumber(windowCount) or 1))
	local firstIndex = math.max(1, #self.history - windowCount + 1)
	local aggregate = {
		window_seconds = 0,
		host_timescale = 1,
		real_clock = RealTime ~= nil and 1 or 0,
		zone_search_max_ms = 0,
		spatial_query_max_ms = 0,
	}
	local included = 0
	for index = firstIndex, #self.history do
		local snapshot = self.history[index]
		included = included + 1
		aggregate.window_seconds = aggregate.window_seconds + (snapshot.window_seconds or 0)
		aggregate.host_timescale = snapshot.host_timescale or aggregate.host_timescale
		aggregate.real_clock = snapshot.real_clock or aggregate.real_clock
		aggregate.zone_search_max_ms = math.max(
			aggregate.zone_search_max_ms,
			snapshot.zone_search_max_ms or 0
		)
		aggregate.spatial_query_max_ms = math.max(
			aggregate.spatial_query_max_ms,
			snapshot.spatial_query_max_ms or snapshot.zone_search_max_ms or 0
		)
		for key, value in pairs(snapshot) do
			if string.sub(key, -11) == "_per_second" and type(value) == "number" then
				aggregate[key] = (aggregate[key] or 0) + value
			end
		end
	end
	if included <= 0 then return self:GetSnapshot() end
	for key, value in pairs(aggregate) do
		if string.sub(key, -11) == "_per_second" then
			aggregate[key] = Round(value / included, 1)
		end
	end
	aggregate.window_seconds = Round(aggregate.window_seconds, 2)
	aggregate.zone_search_max_ms = Round(aggregate.zone_search_max_ms, 2)
	aggregate.spatial_query_max_ms = Round(aggregate.spatial_query_max_ms, 2)
	return aggregate
end

function XHSPerformanceCounters:RecordOrder(order)
	self:Increment("orders", 1)
	order = order or {}
	local now = RealNow()
	local unitIndex = tonumber(order.UnitIndex)
	local orderType = tonumber(order.OrderType) or -1

	if unitIndex ~= nil then
		local previous = self.last_orders[unitIndex]
		if previous ~= nil
			and previous.order_type == orderType
			and now - previous.at <= 0.5 then
			self:Increment("repeated_orders", 1)
		end
		self.last_orders[unitIndex] = {
			order_type = orderType,
			at = now,
		}
	end
	self:TrackSource("order", 0, 0, 4)
end

function XHSPerformanceCounters:InstallGlobalWrappers()
	if self.wrappers_installed then return end
	self.wrappers_installed = true

	self.original_find_units_in_radius = FindUnitsInRadius
	self.original_execute_order_from_table = ExecuteOrderFromTable

	FindUnitsInRadius = function(...)
		local source = nil
		if XHSLagLab ~= nil and XHSLagLab.IsHotspotExperimentActive ~= nil
			and XHSLagLab:IsHotspotExperimentActive() then
			source = GetCallerSource(3)
			if not XHSLagLab:ShouldRunHotspot(source) then
				XHSPerformanceCounters:Increment("zone_searches", 1)
				XHSPerformanceCounters:Increment("zone_searches_suppressed", 1)
				XHSPerformanceCounters:TrackSource("zone", 0, 0, 3)
				return {}
			end
		end
		local startedAt = RealNow()
		local result = XHSPerformanceCounters.original_find_units_in_radius(...)
		local elapsedMs = math.max(0, (RealNow() - startedAt) * 1000)
		local resultCount = type(result) == "table" and #result or 0
		XHSPerformanceCounters:Increment("zone_searches", 1)
		XHSPerformanceCounters:Increment("zone_results", resultCount)
		XHSPerformanceCounters:Increment("zone_search_cost_ms", elapsedMs)
		XHSPerformanceCounters.zone_search_max_ms = math.max(
			XHSPerformanceCounters.zone_search_max_ms or 0,
			elapsedMs
		)
		XHSPerformanceCounters:TrackSource("zone", resultCount, elapsedMs, 3)
		return result
	end

	ExecuteOrderFromTable = function(order)
		XHSPerformanceCounters:RecordOrder(order)
		if XHSLagLab ~= nil and XHSLagLab.ShouldSuppressOrder ~= nil
			and XHSLagLab:ShouldSuppressOrder(order) then
			XHSPerformanceCounters:Increment("orders_suppressed", 1)
			return nil
		end
		return XHSPerformanceCounters.original_execute_order_from_table(order)
	end
end

function XHSPerformanceCounters:FindUnitsInRadiusUntracked(...)
	return self.original_find_units_in_radius(...)
end

function XHSPerformanceCounters:RegisterEvents()
	if self.events_registered then return end
	self.events_registered = true

	ListenToGameEvent("entity_hurt", function()
		XHSPerformanceCounters:Increment("damage_events", 1)
	end, nil)
	ListenToGameEvent("dota_player_used_ability", function()
		XHSPerformanceCounters:Increment("ability_casts", 1)
	end, nil)
	ListenToGameEvent("dota_non_player_used_ability", function()
		XHSPerformanceCounters:Increment("ability_casts", 1)
	end, nil)
	ListenToGameEvent("npc_spawned", function()
		XHSPerformanceCounters:Increment("unit_spawns", 1)
	end, nil)
	ListenToGameEvent("entity_killed", function(event)
		XHSPerformanceCounters:Increment("unit_deaths", 1)
		local killedIndex = event and tonumber(event.entindex_killed) or nil
		if killedIndex ~= nil then
			XHSPerformanceCounters.last_orders[killedIndex] = nil
		end
	end, nil)
end

function XHSPerformanceCounters:Start()
	if self.started then return true end
	local gameModeEntity = GameRules ~= nil
		and GameRules.GetGameModeEntity ~= nil
		and GameRules:GetGameModeEntity() or nil
	if gameModeEntity == nil then
		return false
	end
	self.started = true
	gameModeEntity:SetContextThink("XHSPerformanceCounterWindow", function()
		local now = RealNow()
		if now - self.window_started_at >= WINDOW_SECONDS then
			self:RollWindow(now)
		end
		return 0.1
	end, 0.1)
	return true
end

function XHSPerformanceCounters:Init()
	if self.initialized then
		return self:Start()
	end
	self.initialized = true
	self.window = NewCounterWindow()
	self.snapshot = {}
	self.history = {}
	self.source_windows = { zone = {}, order = {} }
	self.observed_sources = { zone = {}, order = {} }
	self.last_orders = {}
	self.zone_search_max_ms = 0
	self.source_sample_sequence = 0
	self.window_started_at = RealNow()
	self:InstallGlobalWrappers()
	self:RegisterEvents()
	if self:Start() then
		print("[XHSPerformance] Runtime activity counters enabled.")
	else
		print("[XHSPerformance] Runtime activity counters initialized; thinker deferred.")
	end
	return self.started == true
end

return XHSPerformanceCounters
