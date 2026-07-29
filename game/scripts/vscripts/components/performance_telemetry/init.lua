if XHSPerformanceTelemetry == nil then
	_G.XHSPerformanceTelemetry = class({})
end

local SCHEMA_VERSION = 1
local SAMPLE_INTERVAL = 5
local SAMPLES_PER_BATCH = 6
local MAX_PENDING_BATCHES = 8
local MAX_CLIENT_FPS = 500
local CLIENT_REPORT_TIMEOUT = 12
local SERVER_FRAME_INCIDENT_MS = 40
local CLIENT_FPS_INCIDENT = 40
local INCIDENT_CONTEXT_SAMPLES = 4
local LOCAL_REPORT_SCHEMA_VERSION = 1
local LOCAL_REPORT_MAX_SAMPLES = math.ceil(3 * 60 * 60 / SAMPLE_INTERVAL)
local LOCAL_REPORT_TOP_SOURCES = 3
local LOCAL_REPORT_PREFIX = "[XHS_PERF_REPORT"
local ACTIVITY_INCIDENT_THRESHOLDS = {
	spatial_queries_per_second = { threshold = 500, reason = "spatial_query_pressure" },
	spatial_query_cost_ms_per_second = { threshold = 10, reason = "spatial_query_cost" },
	orders_per_second = { threshold = 200, reason = "order_pressure" },
	repeated_orders_per_second = { threshold = 50, reason = "repeated_order_pressure" },
	ai_thinks_per_second = { threshold = 300, reason = "ai_think_pressure" },
	wave_thinks_per_second = { threshold = 800, reason = "wave_think_pressure" },
	damage_events_per_second = { threshold = 500, reason = "damage_pressure" },
	projectiles_per_second = { threshold = 100, reason = "projectile_pressure" },
}

local BREAKABLES = {
	npc_dota_crate = true,
	npc_dota_chest = true,
	npc_dota_vase = true,
}

local BOSSES = {
	npc_dota_hero_magtheridon = true,
	npc_dota_hero_grom_hellscream = true,
	npc_dota_hero_illidan = true,
	npc_dota_hero_balanar = true,
	npc_dota_hero_proudmoore = true,
	npc_dota_hero_arthas = true,
	npc_dota_hero_banehallow = true,
	npc_dota_boss_lich_king = true,
	npc_dota_boss_spirit_master = true,
	npc_dota_boss_spirit_master_fire = true,
	npc_dota_boss_spirit_master_storm = true,
	npc_dota_boss_spirit_master_earth = true,
}

local function Now()
	if RealTime ~= nil then return RealTime() end
	return Time ~= nil and Time() or GameRules:GetGameTime()
end

local function Round(value, decimals)
	local scale = 10 ^ (decimals or 0)
	return math.floor((tonumber(value) or 0) * scale + 0.5) / scale
end

local function IsFinite(value)
	return value ~= nil and value == value and value ~= math.huge and value ~= -math.huge
end

local function CopyTable(source)
	local copy = {}
	for key, value in pairs(source or {}) do
		if type(value) == "table" then
			copy[key] = CopyTable(value)
		else
			copy[key] = value
		end
	end
	return copy
end

local function SafeField(value)
	value = tostring(value == nil and "" or value)
	value = string.gsub(value, "[\r\n\t|]", "_")
	return value
end

local function JoinFields(prefix, fields)
	local values = { prefix }
	for _, value in ipairs(fields) do
		table.insert(values, SafeField(value))
	end
	return table.concat(values, "|")
end

local function ActivityValue(activity, name)
	return Round(tonumber((activity or {})[name]) or 0, 2)
end

function XHSPerformanceTelemetry:ResolvePlayerID(sourceIndex)
	local playerID = nil
	if CustomGameEventManager.GetPlayerIDFromEventSourceIndex ~= nil then
		local ok, resolved = pcall(function()
			return CustomGameEventManager:GetPlayerIDFromEventSourceIndex(sourceIndex)
		end)
		if ok then playerID = tonumber(resolved) end
	end
	if playerID == nil or not PlayerResource:IsValidPlayerID(playerID) then
		local entityIndex = tonumber(sourceIndex)
		if entityIndex ~= nil and entityIndex > 0 then
			local ok, resolved = pcall(function()
				local sender = EntIndexToHScript(entityIndex)
				return sender ~= nil and sender.GetPlayerID ~= nil and sender:GetPlayerID() or nil
			end)
			if ok then playerID = tonumber(resolved) end
		end
	end
	if playerID == nil or not PlayerResource:IsValidPlayerID(playerID) then return nil end
	if PlayerResource.IsFakeClient ~= nil and PlayerResource:IsFakeClient(playerID) then return nil end
	return playerID
end

function XHSPerformanceTelemetry:OnClientSample(sourceIndex, event)
	local playerID = self:ResolvePlayerID(sourceIndex)
	if playerID == nil or type(event) ~= "table" then return end

	local fpsAverage = tonumber(event.fps_average)
	local fpsP5 = tonumber(event.fps_p5)
	local frameP95 = tonumber(event.frame_ms_p95)
	if not IsFinite(fpsAverage) or not IsFinite(fpsP5) or not IsFinite(frameP95) then return end

	self.client_reports[playerID] = {
		fps_average = math.max(0, math.min(MAX_CLIENT_FPS, fpsAverage)),
		fps_p5 = math.max(0, math.min(MAX_CLIENT_FPS, fpsP5)),
		frame_ms_p95 = math.max(0, math.min(1000, frameP95)),
		updated_at = Now(),
	}
end

function XHSPerformanceTelemetry:BuildPlayers()
	local players = {}
	local now = Now()
	local maximumPlayers = DOTA_MAX_TEAM_PLAYERS or 24
	for playerID = 0, maximumPlayers - 1 do
		local report = self.client_reports[playerID]
		if report ~= nil and now - report.updated_at <= CLIENT_REPORT_TIMEOUT then
			local hero = PlayerResource:GetSelectedHeroEntity(playerID)
			table.insert(players, {
				slot = playerID,
				hero = hero ~= nil and not hero:IsNull() and hero:GetUnitName() or nil,
				fps_average = Round(report.fps_average, 1),
				fps_p5 = Round(report.fps_p5, 1),
				frame_ms_p95 = Round(report.frame_ms_p95, 1),
			})
		end
	end
	return players
end

function XHSPerformanceTelemetry:BuildSessionPlayers()
	local players = {}
	local maximumPlayers = DOTA_MAX_TEAM_PLAYERS or 24
	for playerID = 0, maximumPlayers - 1 do
		local isValid = PlayerResource:IsValidPlayerID(playerID)
		local isHuman = isValid
			and (PlayerResource.IsFakeClient == nil or not PlayerResource:IsFakeClient(playerID))
		if isHuman then
			local steamID = tostring(PlayerResource:GetSteamID(playerID) or "")
			if steamID ~= "" and steamID ~= "0" then
				local hero = PlayerResource:GetSelectedHeroEntity(playerID)
				table.insert(players, {
					slot = playerID,
					steam_id = steamID,
					player_name = tostring(PlayerResource:GetPlayerName(playerID) or ""),
					hero = hero ~= nil and not hero:IsNull() and hero:GetUnitName() or nil,
				})
			end
		end
	end
	return players
end

function XHSPerformanceTelemetry:BuildLocalBotSnapshot()
	local now = Now()
	local totals = {
		orders = 0,
		rejected_orders = 0,
		casts_issued = 0,
		casts_rejected = 0,
		target_changes = 0,
		decision_ticks = 0,
		decision_cost_total_ms = 0,
	}
	local snapshot = {
		configured = XHSBots ~= nil
			and XHSBots.configuration ~= nil
			and tonumber(XHSBots.configuration.count) or 0,
		live = 0,
		active = 0,
		paused = XHSBots ~= nil and XHSBots.paused == true and 1 or 0,
		decision_average_ms = 0,
		decision_max_ms = 0,
		think_average_ms = XHSBots ~= nil
			and Round(XHSBots.think_cost_average_ms, 3) or 0,
		think_max_ms = XHSBots ~= nil
			and Round(XHSBots.think_cost_max_ms, 3) or 0,
	}

	if XHSBotPlayerRegistry ~= nil
		and XHSBotPlayerRegistry.GetXHSBotPlayerIDs ~= nil
		and XHSBotPlayerRegistry.GetBot ~= nil then
		for _, playerID in ipairs(XHSBotPlayerRegistry:GetXHSBotPlayerIDs()) do
			local record = XHSBotPlayerRegistry:GetBot(playerID) or {}
			snapshot.live = snapshot.live + 1
			if record.alive ~= false and record.state ~= "DEAD" then
				snapshot.active = snapshot.active + 1
			end
			totals.orders = totals.orders + (tonumber(record.orders) or 0)
			totals.rejected_orders = totals.rejected_orders
				+ (tonumber(record.rejected_orders) or 0)
				+ (tonumber(record.rate_limited_orders) or 0)
			totals.casts_issued = totals.casts_issued
				+ (tonumber(record.casts_issued) or 0)
			totals.casts_rejected = totals.casts_rejected
				+ (tonumber(record.casts_rejected) or 0)
			totals.target_changes = totals.target_changes
				+ (tonumber(record.target_changes) or 0)
			totals.decision_ticks = totals.decision_ticks
				+ (tonumber(record.decision_ticks) or 0)
			totals.decision_cost_total_ms = totals.decision_cost_total_ms
				+ (tonumber(record.decision_cost_total_ms) or 0)
			snapshot.decision_max_ms = math.max(
				snapshot.decision_max_ms,
				tonumber(record.decision_cost_max_ms) or 0
			)
		end
	end

	if totals.decision_ticks > 0 then
		snapshot.decision_average_ms = Round(
			totals.decision_cost_total_ms / totals.decision_ticks,
			3
		)
	end
	snapshot.decision_max_ms = Round(snapshot.decision_max_ms, 3)

	local previous = self.local_bot_previous
	local elapsed = previous ~= nil
		and math.max(0.001, now - (tonumber(previous.at) or now))
		or SAMPLE_INTERVAL
	local function Rate(name)
		if previous == nil then return 0 end
		return Round(math.max(
			0,
			(tonumber(totals[name]) or 0) - (tonumber(previous[name]) or 0)
		) / elapsed, 2)
	end
	snapshot.orders_per_second = Rate("orders")
	snapshot.rejected_orders_per_second = Rate("rejected_orders")
	snapshot.casts_per_second = Rate("casts_issued")
	snapshot.rejected_casts_per_second = Rate("casts_rejected")
	snapshot.target_changes_per_second = Rate("target_changes")
	totals.at = now
	self.local_bot_previous = totals
	return snapshot
end

function XHSPerformanceTelemetry:BuildLocalClientSnapshot(players)
	local snapshot = {
		count = 0,
		fps_average = -1,
		fps_p5 = -1,
		frame_ms_p95 = -1,
		detail = "",
	}
	local fpsSum = 0
	local details = {}
	for _, player in ipairs(players or {}) do
		snapshot.count = snapshot.count + 1
		fpsSum = fpsSum + (tonumber(player.fps_average) or 0)
		local fpsP5 = tonumber(player.fps_p5) or 0
		local frameP95 = tonumber(player.frame_ms_p95) or 0
		if snapshot.fps_p5 < 0 or fpsP5 < snapshot.fps_p5 then
			snapshot.fps_p5 = fpsP5
		end
		if snapshot.frame_ms_p95 < 0 or frameP95 > snapshot.frame_ms_p95 then
			snapshot.frame_ms_p95 = frameP95
		end
		table.insert(details, table.concat({
			tostring(tonumber(player.slot) or -1),
			tostring(tonumber(player.fps_average) or -1),
			tostring(fpsP5),
			tostring(frameP95),
			SafeField(player.hero or ""),
		}, ":"))
	end
	if snapshot.count > 0 then
		snapshot.fps_average = Round(fpsSum / snapshot.count, 1)
	end
	snapshot.detail = table.concat(details, ",")
	return snapshot
end

function XHSPerformanceTelemetry:GetLocalContext()
	local context = "game"
	if GameMode ~= nil and GameMode.FarmEvent_occuring == true then
		context = "farm_event"
	elseif CustomTimers ~= nil
		and CustomTimers.current_time ~= nil
		and (tonumber(CustomTimers.current_time.special_arena) or 0) > 0 then
		context = "special_arena"
	end
	if XHSLagLab ~= nil
		and XHSLagLab.state ~= nil
		and (XHSLagLab.state.running == true or XHSLagLab.state.effect_active == true) then
		context = "lag_lab:"
			.. SafeField(XHSLagLab.state.experiment_id or "unknown")
			.. ":" .. SafeField(XHSLagLab.state.stage or "active")
	end
	return context
end

function XHSPerformanceTelemetry:BuildLocalSourceLines(sequence, expanded)
	local lines = {}
	local counterSnapshot = XHSPerformanceCounters ~= nil
		and XHSPerformanceCounters.GetSnapshot ~= nil
		and XHSPerformanceCounters:GetSnapshot() or {}
	local buckets = {
		{ name = "spatial", rows = counterSnapshot.top_spatial_sources
			or counterSnapshot.top_zone_sources or {} },
		{ name = "order", rows = counterSnapshot.top_order_sources or {} },
	}
	local rowLimit = expanded == true and LOCAL_REPORT_TOP_SOURCES or 1
	for _, bucket in ipairs(buckets) do
		for index = 1, math.min(rowLimit, #bucket.rows) do
			local row = bucket.rows[index] or {}
			table.insert(lines, JoinFields(LOCAL_REPORT_PREFIX .. "_SOURCE]", {
				sequence,
				bucket.name,
				index,
				row.source or "",
				row.calls_per_second or 0,
				row.results_per_second or 0,
				row.cost_ms_per_second or 0,
			}))
		end
	end
	return lines
end

function XHSPerformanceTelemetry:CaptureLocalReportSample(sample)
	if not IsInToolsMode() then return end
	self.local_report_samples = self.local_report_samples or {}
	local activity = sample.activity or {}
	local director = sample.ai_director or {}
	local client = self:BuildLocalClientSnapshot(sample.players)
	local bots = self:BuildLocalBotSnapshot()
	local hostTimescale = tonumber(activity.host_timescale)
		or (Convars ~= nil and Convars:GetFloat("host_timescale")) or 1
	local paused = GameRules.IsGamePaused ~= nil
		and GameRules:IsGamePaused() and 1 or 0
	local expandedSources = sample.incident_id ~= nil
		or (tonumber(sample.server_frame_ms_p95) or 0) >= 25
		or (client.fps_p5 >= 0 and client.fps_p5 < 50)

	local record = {
		data = JoinFields(LOCAL_REPORT_PREFIX .. "_DATA]", {
			sample.sequence,
			sample.game_time,
			GameRules:State_Get(),
			paused,
			self:GetLocalContext(),
			sample.phase,
			sample.wave,
			sample.difficulty,
			Round(hostTimescale, 2),
			sample.server_frame_ms,
			sample.server_frame_ms_p95,
			sample.server_frame_ms_max,
			client.count,
			client.fps_average,
			client.fps_p5,
			client.frame_ms_p95,
			client.detail,
			sample.creeps,
			sample.total_units,
			sample.heroes,
			sample.bosses,
			sample.summons,
			sample.breakables,
			sample.other_units,
			sample.thinkers,
			sample.ai_controllers,
			sample.wave_controllers,
			sample.ability_controllers,
			director.active_agents or 0,
			director.queued_agents or 0,
			director.cached_profiles or 0,
			director.profiles_without_actives or 0,
			director.budget or 0,
			ActivityValue(activity, "ai_thinks_per_second"),
			ActivityValue(activity, "ai_agents_processed_per_second"),
			ActivityValue(activity, "ai_agents_sleeping_per_second"),
			ActivityValue(activity, "wave_thinks_per_second"),
			ActivityValue(activity, "ability_loop_thinks_per_second"),
			ActivityValue(activity, "spatial_queries_per_second"),
			ActivityValue(activity, "spatial_results_per_second"),
			ActivityValue(activity, "spatial_query_cost_ms_per_second"),
			ActivityValue(activity, "spatial_query_max_ms"),
			ActivityValue(activity, "spatial_cache_hits_per_second"),
			ActivityValue(activity, "spatial_cache_misses_per_second"),
			ActivityValue(activity, "orders_per_second"),
			ActivityValue(activity, "repeated_orders_per_second"),
			ActivityValue(activity, "damage_events_per_second"),
			ActivityValue(activity, "ability_casts_per_second"),
			ActivityValue(activity, "projectiles_per_second"),
			ActivityValue(activity, "unit_spawns_per_second"),
			ActivityValue(activity, "unit_deaths_per_second"),
			ActivityValue(activity, "target_changes_per_second"),
			bots.configured,
			bots.live,
			bots.active,
			bots.paused,
			bots.orders_per_second,
			bots.rejected_orders_per_second,
			bots.casts_per_second,
			bots.rejected_casts_per_second,
			bots.target_changes_per_second,
			bots.decision_average_ms,
			bots.decision_max_ms,
			bots.think_average_ms,
			bots.think_max_ms,
			sample.profiler_ms,
			sample.incident_id or 0,
		}),
		sources = self:BuildLocalSourceLines(sample.sequence, expandedSources),
	}
	table.insert(self.local_report_samples, record)
	if #self.local_report_samples > LOCAL_REPORT_MAX_SAMPLES then
		table.remove(self.local_report_samples, 1)
		self.local_report_dropped_samples =
			(self.local_report_dropped_samples or 0) + 1
	end
end

function XHSPerformanceTelemetry:PrintLocalReport(reason)
	if not IsInToolsMode() then
		print(LOCAL_REPORT_PREFIX .. "_ERROR]|tools_mode_required")
		return false
	end
	local summary = self:BuildSummary()
	local samples = self.local_report_samples or {}
	print(JoinFields(LOCAL_REPORT_PREFIX .. "_BEGIN]", {
		"schema=" .. tostring(LOCAL_REPORT_SCHEMA_VERSION),
		"reason=" .. SafeField(reason or "manual"),
		"map=" .. SafeField(GetMapName()),
		"mod=" .. SafeField(GAME_VERSION or ""),
		"interval_s=" .. tostring(SAMPLE_INTERVAL),
		"samples=" .. tostring(#samples),
		"dropped=" .. tostring(self.local_report_dropped_samples or 0),
	}))
	print(JoinFields(LOCAL_REPORT_PREFIX .. "_SUMMARY]", {
		"sample_count=" .. tostring(summary.sample_count or 0),
		"incidents=" .. tostring(summary.incident_count or 0),
		"server_avg_ms=" .. tostring(summary.server_frame_ms_average or 0),
		"server_max_ms=" .. tostring(summary.server_frame_ms_max or 0),
		"client_fps_p5_min=" .. tostring(summary.client_fps_p5_min or -1),
		"creeps_max=" .. tostring(summary.creeps_max or 0),
		"units_max=" .. tostring(summary.total_units_max or 0),
	}))
	print(JoinFields(LOCAL_REPORT_PREFIX .. "_COLUMNS]", {
		"seq", "game_s", "state", "paused", "context", "phase", "wave",
		"difficulty", "timescale", "server_avg_ms", "server_p95_ms",
		"server_max_ms", "clients", "client_fps_avg", "client_fps_p5",
		"client_frame_p95_ms", "client_detail",
		"creeps", "units", "heroes", "bosses", "summons", "breakables",
		"other", "thinkers", "ai_ctrl", "wave_ctrl", "ability_ctrl",
		"director_active", "director_queued", "profiles", "profiles_passive",
		"director_budget", "ai_s", "ai_processed_s", "ai_sleeping_s",
		"wave_s", "ability_s", "spatial_s", "spatial_hits_s",
		"spatial_cost_ms_s", "spatial_max_ms", "cache_hits_s",
		"cache_misses_s", "orders_s", "repeat_orders_s", "damage_s",
		"casts_s", "projectiles_s", "spawns_s", "deaths_s",
		"target_changes_s", "bots_configured", "bots_live", "bots_active",
		"bots_paused", "bot_orders_s", "bot_order_reject_s", "bot_casts_s",
		"bot_cast_reject_s", "bot_target_changes_s", "bot_decision_avg_ms",
		"bot_decision_max_ms", "bot_think_avg_ms", "bot_think_max_ms",
		"profiler_ms", "incident",
	}))
	for _, record in ipairs(samples) do
		print(record.data)
		for _, sourceLine in ipairs(record.sources or {}) do
			print(sourceLine)
		end
	end
	for _, incident in ipairs(self.incidents or {}) do
		print(JoinFields(LOCAL_REPORT_PREFIX .. "_INCIDENT]", {
			incident.incident_id or 0,
			incident.trigger_sequence or 0,
			incident.trigger_game_time or 0,
			incident.start_sequence or 0,
			incident.end_sequence or 0,
			table.concat(incident.reasons or {}, ","),
			incident.peak_server_frame_ms or 0,
			incident.min_client_fps_p5 or -1,
		}))
	end
	if self.active_incident ~= nil then
		local incident = self.active_incident
		print(JoinFields(LOCAL_REPORT_PREFIX .. "_INCIDENT]", {
			incident.incident_id or 0,
			incident.trigger_sequence or 0,
			incident.trigger_game_time or 0,
			incident.start_sequence or 0,
			incident.end_sequence or 0,
			table.concat(incident.reasons or {}, ","),
			incident.peak_server_frame_ms or 0,
			incident.min_client_fps_p5 or -1,
		}))
	end
	print(JoinFields(LOCAL_REPORT_PREFIX .. "_END]", {
		"samples=" .. tostring(#samples),
		"reason=" .. SafeField(reason or "manual"),
	}))
	return true
end

function XHSPerformanceTelemetry:BuildSample()
	local startedAt = Now()
	table.sort(self.server_frame_observations)
	local frameCount = #self.server_frame_observations
	local frameSum = 0
	for _, frameMs in ipairs(self.server_frame_observations) do frameSum = frameSum + frameMs end
	local frameP95Index = math.max(1, math.min(frameCount, math.ceil(frameCount * 0.95)))
	local frameAverage = frameCount > 0 and frameSum / frameCount or 0
	local frameP95 = frameCount > 0 and self.server_frame_observations[frameP95Index] or 0
	local frameMaximum = frameCount > 0 and self.server_frame_observations[frameCount] or 0
	self.server_frame_observations = {}
	local sample = {
		sequence = self.next_sequence,
		game_time = Round(GameRules:GetDOTATime(false, false), 1),
		server_frame_ms = Round(frameAverage, 2),
		server_frame_ms_p95 = Round(frameP95, 2),
		server_frame_ms_max = Round(frameMaximum, 2),
		total_units = 0,
		creeps = 0,
		ai_controllers = 0,
		wave_controllers = 0,
		ability_controllers = 0,
		heroes = 0,
		bosses = 0,
		summons = 0,
		breakables = 0,
		other_units = 0,
		thinkers = 0,
		phase = CustomTimers ~= nil and tonumber(CustomTimers.game_phase) or 0,
		wave = CustomTimers ~= nil and tonumber(CustomTimers.special_wave or CustomTimers.creep_level) or 0,
		difficulty = GameRules:GetCustomGameDifficulty() or 0,
		players = self:BuildPlayers(),
		activity = {},
	}

	local units = XHSPerformanceCounters:FindUnitsInRadiusUntracked(
		DOTA_TEAM_NEUTRALS,
		Vector(0, 0, 0),
		nil,
		FIND_UNITS_EVERYWHERE,
		DOTA_UNIT_TARGET_TEAM_BOTH,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
		FIND_ANY_ORDER,
		false
	)

	for _, unit in pairs(units) do
		if unit ~= nil and not unit:IsNull() and unit:IsAlive() then
			local unitName = unit:GetUnitName() or ""
			local isDummy = unit.is_fake_hero == true or string.find(unitName, "dummy", 1, true) ~= nil
			local isRune = IsXHSRuneUnit ~= nil and IsXHSRuneUnit(unit)
			sample.total_units = sample.total_units + 1
			if unit:HasModifier("modifier_ai") then sample.ai_controllers = sample.ai_controllers + 1 end
			if unit.xhs_wave_order_controller == true then sample.wave_controllers = sample.wave_controllers + 1 end
			if isDummy or isRune then
				sample.other_units = sample.other_units + 1
			elseif BOSSES[unitName] == true or unit.Boss == true then
				sample.bosses = sample.bosses + 1
			elseif unit:IsRealHero() and not unit:IsIllusion() then
				sample.heroes = sample.heroes + 1
			elseif BREAKABLES[unitName] == true then
				sample.breakables = sample.breakables + 1
			elseif unit.IsSummoned ~= nil and unit:IsSummoned() then
				sample.summons = sample.summons + 1
			elseif unit:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS
				and ((unit.IsCreep ~= nil and unit:IsCreep()) or (unit.IsCreature ~= nil and unit:IsCreature())) then
				sample.creeps = sample.creeps + 1
			else
				sample.other_units = sample.other_units + 1
			end
		end
	end

	local thinkers = Entities:FindAllByClassname("npc_dota_thinker")
	sample.thinkers = thinkers and #thinkers or 0
	local directorState = XHSCreepAIDirector ~= nil
		and XHSCreepAIDirector.GetState ~= nil
		and XHSCreepAIDirector:GetState()
		or {}
	sample.ai_director = directorState
	sample.ability_controllers = tonumber(directorState.active_ability_agents) or 0
	if XHSPerformanceCounters ~= nil
		and XHSPerformanceCounters.GetAggregateSnapshot ~= nil then
		sample.activity = CopyTable(XHSPerformanceCounters:GetAggregateSnapshot(
			math.max(1, math.floor(SAMPLE_INTERVAL))
		))
	end
	sample.ai_ticks_per_second = sample.activity.ai_thinks_per_second
		or sample.ai_controllers
	sample.wave_checks_per_second = sample.activity.wave_thinks_per_second
		or sample.wave_controllers
	sample.ability_checks_per_second = sample.activity.ability_loop_thinks_per_second
		or sample.ability_controllers
	sample.profiler_ms = Round(math.max(0, (Now() - startedAt) * 1000), 2)
	self.next_sequence = self.next_sequence + 1
	return sample
end

function XHSPerformanceTelemetry:DetectIncident(sample)
	local reasons = {}
	if sample.server_frame_ms_p95 >= SERVER_FRAME_INCIDENT_MS then
		table.insert(reasons, "server_frame")
	end
	for _, player in ipairs(sample.players or {}) do
		if player.fps_p5 < CLIENT_FPS_INCIDENT then
			table.insert(reasons, "client_fps")
			break
		end
	end
	for metricName, definition in pairs(ACTIVITY_INCIDENT_THRESHOLDS) do
		if (tonumber((sample.activity or {})[metricName]) or 0) >= definition.threshold then
			table.insert(reasons, definition.reason)
		end
	end

	if #reasons > 0 then
		if self.active_incident == nil then
			self.next_incident_id = self.next_incident_id + 1
			self.active_incident = {
				incident_id = self.next_incident_id,
				trigger_sequence = sample.sequence,
				trigger_game_time = sample.game_time,
				start_sequence = math.max(0, sample.sequence - INCIDENT_CONTEXT_SAMPLES),
				end_sequence = sample.sequence,
				reasons = reasons,
				peak_server_frame_ms = sample.server_frame_ms_max,
				min_client_fps_p5 = nil,
				dirty = true,
			}
			for _, previous in ipairs(self.current_samples) do
				if previous.sequence >= self.active_incident.start_sequence then
					previous.incident_id = self.active_incident.incident_id
				end
			end
			self.summary.incident_count = self.summary.incident_count + 1
		else
			for _, reason in ipairs(reasons) do
				local found = false
				for _, currentReason in ipairs(self.active_incident.reasons) do
					if currentReason == reason then found = true break end
				end
				if not found then table.insert(self.active_incident.reasons, reason) end
			end
		end
		self.incident_post_remaining = INCIDENT_CONTEXT_SAMPLES
	end

	if self.active_incident ~= nil then
		sample.incident_id = self.active_incident.incident_id
		self.active_incident.end_sequence = sample.sequence
		self.active_incident.peak_server_frame_ms = math.max(
			self.active_incident.peak_server_frame_ms or 0,
			sample.server_frame_ms_max
		)
		for _, player in ipairs(sample.players or {}) do
			if self.active_incident.min_client_fps_p5 == nil
				or player.fps_p5 < self.active_incident.min_client_fps_p5 then
				self.active_incident.min_client_fps_p5 = player.fps_p5
			end
		end
		self.active_incident.dirty = true
		if #reasons == 0 then
			self.incident_post_remaining = self.incident_post_remaining - 1
			if self.incident_post_remaining <= 0 then
				table.insert(self.incidents, self.active_incident)
				self.active_incident = nil
			end
		end
	end
end

function XHSPerformanceTelemetry:UpdateSummary(sample)
	local summary = self.summary
	summary.sample_count = summary.sample_count + 1
	summary.first_game_time = summary.first_game_time or sample.game_time
	summary.last_game_time = sample.game_time
	summary.server_frame_ms_sum = summary.server_frame_ms_sum + sample.server_frame_ms
	summary.server_frame_ms_max = math.max(summary.server_frame_ms_max, sample.server_frame_ms_max)
	summary.creeps_max = math.max(summary.creeps_max, sample.creeps)
	summary.total_units_max = math.max(summary.total_units_max, sample.total_units)
	for metricName, _ in pairs(ACTIVITY_INCIDENT_THRESHOLDS) do
		local summaryName = metricName .. "_max"
		summary[summaryName] = math.max(
			tonumber(summary[summaryName]) or 0,
			tonumber((sample.activity or {})[metricName]) or 0
		)
	end
	for _, player in ipairs(sample.players or {}) do
		if summary.client_fps_p5_min == nil or player.fps_p5 < summary.client_fps_p5_min then
			summary.client_fps_p5_min = player.fps_p5
		end
	end
end

function XHSPerformanceTelemetry:BuildSummary()
	local summary = CopyTable(self.summary)
	summary.server_frame_ms_average = summary.sample_count > 0
		and Round(summary.server_frame_ms_sum / summary.sample_count, 2)
		or 0
	summary.server_frame_ms_sum = nil
	summary.dropped_batches = self.dropped_batches
	summary.session_players = self:BuildSessionPlayers()
	return summary
end

function XHSPerformanceTelemetry:Collect()
	local sample = self:BuildSample()
	self:DetectIncident(sample)
	self:UpdateSummary(sample)
	self:CaptureLocalReportSample(sample)
	table.insert(self.current_samples, sample)
	if #self.current_samples >= SAMPLES_PER_BATCH then self:QueueBatch(false) end
end

function XHSPerformanceTelemetry:QueueBatch(final)
	if #self.current_samples == 0 and final ~= true then return end
	local incidentUpdates = {}
	for _, incident in ipairs(self.incidents) do
		if incident.dirty == true then
			local copy = CopyTable(incident)
			copy.dirty = nil
			table.insert(incidentUpdates, copy)
			incident.dirty = false
		end
	end
	if self.active_incident ~= nil and self.active_incident.dirty == true then
		local copy = CopyTable(self.active_incident)
		copy.dirty = nil
		table.insert(incidentUpdates, copy)
		self.active_incident.dirty = false
	end

	local batch = {
		schema_version = SCHEMA_VERSION,
		batch_id = self.next_batch_id,
		match_id = api ~= nil and api.GetMatchID ~= nil and api:GetMatchID() or 0,
		map = GetMapName(),
		mod_version = tostring(GAME_VERSION or ""),
		session_players = self:BuildSessionPlayers(),
		difficulty = GameRules:GetCustomGameDifficulty() or 0,
		sample_interval_ms = SAMPLE_INTERVAL * 1000,
		samples = self.current_samples,
		incidents = incidentUpdates,
		final = final == true,
	}
	if final == true then batch.summary = self:BuildSummary() end
	self.next_batch_id = self.next_batch_id + 1
	self.current_samples = {}
	table.insert(self.pending_batches, batch)
	if #self.pending_batches > MAX_PENDING_BATCHES then
		table.remove(self.pending_batches, 1)
		self.dropped_batches = self.dropped_batches + 1
	end
end

function XHSPerformanceTelemetry:TrySend()
	if self.in_flight == true or #self.pending_batches == 0 then return end
	if api == nil or api.Request == nil or api.game_id == nil then return end
	if api.xhs_bot_session_backend_disabled == true then
		self.pending_batches = {}
		return
	end
	if Now() < self.next_send_at then return end

	local batch = self.pending_batches[1]
	batch.game_id = tonumber(api.game_id)
	self.in_flight = true
	api:Request("performance", function()
		if self.pending_batches[1] == batch then table.remove(self.pending_batches, 1) end
		self.in_flight = false
		self.retry_count = 0
		self.next_send_at = 0
		self:TrySend()
	end, function()
		self.in_flight = false
		self.retry_count = math.min(self.retry_count + 1, 6)
		self.next_send_at = Now() + math.min(120, 5 * (2 ^ (self.retry_count - 1)))
	end, "POST", batch)
end

function XHSPerformanceTelemetry:Finalize()
	if self.finalized == true then return self:BuildSummary() end
	self.finalized = true
	if self.active_incident ~= nil then
		table.insert(self.incidents, self.active_incident)
		self.active_incident = nil
	end
	if api == nil or api.game_id == nil or api.xhs_bot_session_backend_disabled == true then
		self.current_samples = {}
		self.pending_batches = {}
		if IsInToolsMode() and self.local_report_auto_printed ~= true then
			self.local_report_auto_printed = true
			self:PrintLocalReport("finalize")
		end
		return self:BuildSummary()
	end
	self:QueueBatch(true)
	self:TrySend()
	if IsInToolsMode() and self.local_report_auto_printed ~= true then
		self.local_report_auto_printed = true
		self:PrintLocalReport("finalize")
	end
	return self:BuildSummary()
end

function XHSPerformanceTelemetry:Init()
	if self.initialized == true then return end
	self.initialized = true
	self.client_reports = {}
	self.current_samples = {}
	self.pending_batches = {}
	self.incidents = {}
	self.active_incident = nil
	self.next_sequence = 0
	self.next_batch_id = 0
	self.next_incident_id = 0
	self.incident_post_remaining = 0
	self.in_flight = false
	self.retry_count = 0
	self.next_send_at = 0
	self.next_sample_at = Now() + SAMPLE_INTERVAL
	self.server_frame_observations = {}
	self.dropped_batches = 0
	self.finalized = false
	self.local_report_samples = {}
	self.local_report_dropped_samples = 0
	self.local_report_auto_printed = false
	self.local_bot_previous = nil
	self.summary = {
		schema_version = SCHEMA_VERSION,
		sample_count = 0,
		incident_count = 0,
		server_frame_ms_sum = 0,
		server_frame_ms_max = 0,
		creeps_max = 0,
		total_units_max = 0,
	}
	for metricName, _ in pairs(ACTIVITY_INCIDENT_THRESHOLDS) do
		self.summary[metricName .. "_max"] = 0
	end

	CustomGameEventManager:RegisterListener("xhs_performance_client_sample", function(sourceIndex, event)
		return XHSPerformanceTelemetry:OnClientSample(sourceIndex, event)
	end)
	if IsInToolsMode() and Convars ~= nil and Convars.RegisterCommand ~= nil then
		Convars:RegisterCommand("xhs_perf_dump", function()
			XHSPerformanceTelemetry:PrintLocalReport("manual")
		end, "Print the local XHS performance timeline to VConsole.", FCVAR_CHEAT)
	end
	ListenToGameEvent("game_rules_state_change", function()
		if IsInToolsMode()
			and GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME
			and XHSPerformanceTelemetry.finalized ~= true then
			XHSPerformanceTelemetry:Finalize()
		end
	end, nil)

	GameRules:GetGameModeEntity():SetContextThink("XHSPerformanceTelemetry", function()
		if self.finalized == true then
			self:TrySend()
			return #self.pending_batches > 0 and 0.5 or nil
		end
		local now = Now()
		local hostTimescale = Convars ~= nil and math.max(Convars:GetFloat("host_timescale"), 0.01) or 1
		table.insert(self.server_frame_observations, math.max(0, FrameTime() * 1000 / hostTimescale))
		local state = GameRules:State_Get()
		if state >= DOTA_GAMERULES_STATE_PRE_GAME and now >= self.next_sample_at then
			self.next_sample_at = now + SAMPLE_INTERVAL
			self:Collect()
		end
		self:TrySend()
		return 0.1
	end, 0.1)
end
