require("components/xhs_bots/config")
require("components/xhs_bots/player_registry")
require("components/xhs_bots/hero_profiles")
require("components/xhs_bots/item_catalog")
require("components/xhs_bots/item_planner")
require("components/xhs_bots/danger_registry")
require("components/xhs_bots/provisioner")
require("components/xhs_bots/team_director")
require("components/xhs_bots/utility")
require("components/xhs_bots/executor")
require("components/xhs_bots/economy")
require("components/xhs_bots/encounter_director")
require("components/xhs_bots/brain")

if XHSBots == nil then
	XHSBots = class({})
end

XHSBots.initialized = false
XHSBots.enabled = false
XHSBots.locked = false
XHSBots.paused = false
XHSBots.overlay_enabled = false
XHSBots.revision = 0
XHSBots.status = "disabled"
XHSBots.error = ""
XHSBots.configuration = XHSBotConfig:CopyDefaults()
XHSBots.next_roster_push = 0
XHSBots.next_debug_push = 0
XHSBots.launch_retry_count = 0
XHSBots.launch_retry_limit = 12
XHSBots.hero_selection_retry_count = 0
XHSBots.hero_selection_retry_limit = 12
XHSBots.hero_selection_retry_running = false
XHSBots.qa_human_pick_pending = false
XHSBots.qa_human_pick_timed_out = false
XHSBots.qa_human_pick_generation = 0
XHSBots.qa_human_pick_timeout = 15
XHSBots.controller_refresh_generation = 0
XHSBots.controller_refresh_retry_limit = 40
XHSBots.controller_refresh_retry_interval = 0.25
XHSBots.first_human_pick_seen = false
XHSBots.unique_hero_count_finalized = false
XHSBots.safe_error_state = XHSBots.safe_error_state or {}
XHSBots.safe_error_count = XHSBots.safe_error_count or 0
XHSBots.safe_error_report_interval = 5
XHSBots.qa_economy_audit = nil
XHSBots.qa_economy_audit_min_duration = 20
XHSBots.qa_economy_audit_timeout = 90
XHSBots.qa_economy_audit_max_purchases = 30
XHSBots.qa_economy_audit_wallet_grace = 0.75
XHSBots.qa_economy_audit_watch_generation = 0
XHSBots.qa_economy_audit_watch_running = false
XHSBots.qa_economy_audit_watch_interval = 1
XHSBots.qa_economy_audit_watch_context =
	"xhs_bots_economy_audit_watch"

local function IsTruthy(value)
	return value == true or value == 1 or value == "1" or value == "true"
end

local function SetupLogValue(value)
	local text = tostring(value == nil and "nil" or value)
	text = string.gsub(text, "[%c%s=]+", "_")
	if text == "" then return "empty" end
	return string.sub(text, 1, 160)
end

local function SetupLog(eventName, fields)
	-- Intentionally silent: XHSBots state is exposed through net tables/dev UI.
end

local function IsValidHero(hero)
	return hero ~= nil and IsValidEntity(hero) and not hero:IsNull() and hero:IsRealHero()
end

local function IsValidUnit(unit)
	return unit ~= nil and IsValidEntity(unit) and not unit:IsNull()
end

local function SafeEntityFromIndex(entindex)
	if entindex == nil or entindex < 0 then return nil end
	local ok, entity = pcall(EntIndexToHScript, entindex)
	if ok and IsValidUnit(entity) then return entity end
	return nil
end

local function GetDebugEntityName(entity)
	if not IsValidUnit(entity) then return "" end

	local nameGetter = entity.GetUnitName
	if type(nameGetter) ~= "function" then
		nameGetter = entity.GetClassname
	end
	if type(nameGetter) ~= "function" then return "" end

	local ok, name = pcall(nameGetter, entity)
	return ok and tostring(name or "") or ""
end

function XHSBots:GetSafeRuntimeTime()
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

function XHSBots:RunSafely(scope, callback, record, fallback)
	scope = tostring(scope or "unknown")
	local now = self:GetSafeRuntimeTime()
	local state = self.safe_error_state[scope] or {
		consecutive = 0,
		total = 0,
		next_report_at = 0,
	}
	self.safe_error_state[scope] = state
	local shouldReport = now >= (tonumber(state.next_report_at) or 0)
	local status = false
	local result = nil

	if Log ~= nil and Log.ExecuteInSafeContext ~= nil then
		status, result = Log:ExecuteInSafeContext(callback, {}, {
			notify = false,
			prefix = "[XHSBots][" .. scope .. "]",
			silent = true,
		})
	else
		status, result = xpcall(callback, function(err)
			local message = "[XHSBots][" .. scope .. "] " .. tostring(err or "Unknown Error")
			if debug ~= nil and debug.traceback ~= nil then
				message = message .. "\n" .. debug.traceback()
			end
			return message
		end)
	end

	if status then
		state.consecutive = 0
		state.last_success_at = now
		if type(record) == "table" and record.safe_last_error_scope == scope then
			record.safe_error_consecutive = 0
		end
		return true, result
	end

	state.consecutive = (tonumber(state.consecutive) or 0) + 1
	state.total = (tonumber(state.total) or 0) + 1
	state.last_error = tostring(result or "Unknown safe-context error")
	state.last_error_at = now
	if shouldReport then
		state.next_report_at = now + (tonumber(self.safe_error_report_interval) or 5)
	end
	self.safe_error_count = (tonumber(self.safe_error_count) or 0) + 1
	self.last_safe_error_scope = scope
	self.last_safe_error = state.last_error

	if type(record) == "table" then
		record.safe_error_count = (tonumber(record.safe_error_count) or 0) + 1
		record.safe_error_consecutive = state.consecutive
		record.safe_last_error_scope = scope
		record.safe_last_error = state.last_error
		record.safe_last_error_at = now
		local backoff = math.min(2, 0.15 * (2 ^ math.min(4, state.consecutive - 1)))
		record.next_think_at = math.max(tonumber(record.next_think_at) or 0, now + backoff)
	end
	return false, fallback, state.last_error
end

function XHSBots:RunSafeEvent(scope, callback)
	local _, result = self:RunSafely("event:" .. tostring(scope), callback, nil, nil)
	return result
end

function XHSBots:RecordDamageType(victim, damageType, amount)
	if self.enabled ~= true or not IsValidHero(victim)
		or victim.GetPlayerID == nil then return end
	local playerID = tonumber(victim:GetPlayerID())
	if playerID == nil
		or not XHSBotPlayerRegistry:IsXHSBotPlayerID(playerID) then return end
	local record = XHSBotPlayerRegistry:GetBot(playerID)
	amount = math.max(0, tonumber(amount) or 0)
	if record == nil or amount <= 0 then return end

	local now = GameRules:GetGameTime()
	local previousAt = tonumber(record.damage_type_sample_at) or now
	local elapsed = math.max(0, now - previousAt)
	local decay = math.exp(-elapsed / 8)
	if elapsed >= 20 then decay = 0 end
	record.recent_physical_damage =
		(tonumber(record.recent_physical_damage) or 0) * decay
	record.recent_magical_damage =
		(tonumber(record.recent_magical_damage) or 0) * decay
	record.recent_pure_damage =
		(tonumber(record.recent_pure_damage) or 0) * decay

	damageType = tonumber(damageType)
	if damageType == DAMAGE_TYPE_MAGICAL then
		record.recent_magical_damage = record.recent_magical_damage + amount
	elseif damageType == DAMAGE_TYPE_PURE then
		record.recent_pure_damage = record.recent_pure_damage + amount
	else
		record.recent_physical_damage = record.recent_physical_damage + amount
	end

	local total = record.recent_physical_damage
		+ record.recent_magical_damage
		+ record.recent_pure_damage
	record.physical_threat = record.recent_physical_damage / math.max(1, total)
	record.magical_threat = record.recent_magical_damage / math.max(1, total)
	record.pure_threat = record.recent_pure_damage / math.max(1, total)
	record.damage_type_sample_at = now
	record.damage_type_last_hit_at = now
end

function XHSBots:Init()
	SetupLog("init_called", {
		already_initialized = self.initialized,
		tools_mode = IsInToolsMode(),
	})
	if self.initialized then
		SetupLog("init_reused", {
			revision = self.revision,
			status = self.status,
		})
		self:PushConfiguration()
		return
	end
	self.initialized = true
	self.enabled = IsInToolsMode()

	-- Do not register client activation events or start thinkers in production.
	if not self.enabled then
		SetupLog("init_disabled", {
			reason = "outside_tools",
		})
	end
	if not self.enabled then return end

	self.configuration = XHSBotConfig:Normalize({}, XHSBotPlayerRegistry:GetHumanCount())
	self.status = "ready"
	self.controller_player_id = self:FindControllerPlayerID()

	self:RegisterQACommands()

	CustomGameEventManager:RegisterListener("xhs_bot_setup_configure", function(sourceIndex, event)
		return XHSBots:RunSafeEvent("configure", function()
			return XHSBots:OnConfigure(sourceIndex, event)
		end)
	end)

	ListenToGameEvent("game_rules_state_change", function()
		return XHSBots:RunSafeEvent("game_rules_state_change", function()
			return XHSBots:OnGameRulesStateChange()
		end)
	end, nil)
	ListenToGameEvent("player_connect_full", function(event)
		return XHSBots:RunSafeEvent("player_connect_full", function()
			SetupLog("player_connect_full", {
				event_player_id = event and event.PlayerID,
				event_user_id = event and event.userid,
			})
			XHSBots:StartControllerRefresh("player_connect_full")
		end)
	end, nil)
	ListenToGameEvent("npc_spawned", function(event)
		return XHSBots:RunSafeEvent("npc_spawned", function()
			return XHSBots:OnNPCSpawned(event)
		end)
	end, nil)

	self:PushConfiguration()
	self:PushRoster()
	self:StartControllerRefresh("init")
	SetupLog("init_completed", {
		controller_player_id = self.controller_player_id,
		human_count = XHSBotPlayerRegistry:GetHumanCount(),
		revision = self.revision,
		status = self.status,
	})
end

function XHSBots:FindControllerPlayerID()
	local humans = XHSBotPlayerRegistry:GetHumanPlayerIDs()
	return humans[1] or -1
end

function XHSBots:RefreshController(reason)
	if not self.enabled then return false end
	local previousPlayerID = tonumber(self.controller_player_id) or -1
	local nextPlayerID = self:FindControllerPlayerID()
	if nextPlayerID < 0 then return false end
	if nextPlayerID == previousPlayerID then return true end

	self.controller_player_id = nextPlayerID
	SetupLog("controller_updated", {
		previous_player_id = previousPlayerID,
		controller_player_id = nextPlayerID,
		reason = reason,
	})
	self:PushConfiguration()
	return true
end

function XHSBots:StartControllerRefresh(reason)
	if not self.enabled then return end
	if self:RefreshController(reason .. "_immediate") then return end
	if Timers == nil or Timers.CreateTimer == nil then
		SetupLog("controller_refresh_unavailable", {
			reason = reason,
		})
		return
	end

	self.controller_refresh_generation = self.controller_refresh_generation + 1
	local generation = self.controller_refresh_generation
	local attempt = 0
	SetupLog("controller_refresh_started", {
		generation = generation,
		reason = reason,
	})
	Timers:CreateTimer(0, function()
		if generation ~= XHSBots.controller_refresh_generation then return nil end
		attempt = attempt + 1
		if XHSBots:RefreshController(reason .. "_retry") then
			SetupLog("controller_refresh_completed", {
				attempt = attempt,
				controller_player_id = XHSBots.controller_player_id,
				generation = generation,
				reason = reason,
			})
			return nil
		end
		if attempt >= XHSBots.controller_refresh_retry_limit then
			SetupLog("controller_refresh_timed_out", {
				attempt = attempt,
				generation = generation,
				reason = reason,
			})
			return nil
		end
		return XHSBots.controller_refresh_retry_interval
	end)
end

function XHSBots:ResolveSenderPlayerID(sourceIndex)
	local numericSourceIndex = tonumber(sourceIndex)
	local playerID = -1

	if CustomGameEventManager ~= nil
		and CustomGameEventManager.GetPlayerIDFromEventSourceIndex ~= nil then
		local ok, resolvedPlayerID = pcall(function()
			return CustomGameEventManager:GetPlayerIDFromEventSourceIndex(sourceIndex)
		end)
		playerID = ok and tonumber(resolvedPlayerID) or -1
		local accepted = XHSBotPlayerRegistry:IsHumanPlayerID(playerID)
		SetupLog("sender_resolution", {
			accepted = accepted,
			candidate_player_id = playerID,
			method = "event_source_api",
			source_index = sourceIndex,
		})
		if accepted then return playerID end
	end

	-- Some Source 2 builds expose GetPlayerIDFromEventSourceIndex but return no
	-- usable player ID. The event source is still an engine-owned entity index,
	-- so resolve that entity directly without ever trusting payload.PlayerID.
	if numericSourceIndex ~= nil and numericSourceIndex > 0 then
		local ok, resolvedPlayerID = pcall(function()
			local sender = EntIndexToHScript(numericSourceIndex)
			if sender ~= nil and sender.GetPlayerID ~= nil then
				return sender:GetPlayerID()
			end
			return nil
		end)
		playerID = ok and tonumber(resolvedPlayerID) or -1
		local accepted = XHSBotPlayerRegistry:IsHumanPlayerID(playerID)
		SetupLog("sender_resolution", {
			accepted = accepted,
			candidate_player_id = playerID,
			method = "event_source_entity",
			source_index = sourceIndex,
		})
		if accepted then return playerID end
	end

	SetupLog("sender_resolution_failed", {
		source_index = sourceIndex,
	})
	return -1
end

function XHSBots:PrintQAResult(command, ok, message, fields)
	local line = "[XHSBots][QA] command="
		.. self:FormatQALogValue(command, 40)
		.. " status=" .. (ok == true and "ok" or "error")
		.. " message=" .. self:FormatQALogValue(message, 120)
	if fields ~= nil and tostring(fields) ~= "" then
		local safeFields = string.gsub(tostring(fields), "[%c]+", "_")
		line = line .. " " .. string.sub(safeFields, 1, 768)
	end
	line = string.sub(line, 1, 960)
	if NativePrint ~= nil then
		pcall(NativePrint, line)
	elseif print ~= nil then
		pcall(print, line)
	end
	return line
end

function XHSBots:FormatQALogValue(value, maximumLength)
	local text = tostring(value or "")
	text = string.gsub(text, "[%c%s=]+", "_")
	text = string.gsub(text, "[^%w%._:%-]", "_")
	if text == "" then text = "none" end
	return string.sub(text, 1, tonumber(maximumLength) or 96)
end

function XHSBots:RegisterQACommands()
	if not self.enabled or Convars == nil or Convars.RegisterCommand == nil then return end
	local commandFlags = FCVAR_CHEAT or 0

	Convars:RegisterCommand(
		"xhs_bots_test_config",
		function(_, count, difficulty, composition)
			local ok, message = XHSBots:ApplyConfiguration({
				count = count,
				difficulty = difficulty,
				composition = composition,
			})
			XHSBots:PrintQAResult(
				"xhs_bots_test_config",
				ok,
				message,
				"count=" .. tostring(count)
					.. " difficulty=" .. tostring(difficulty)
					.. " composition=" .. tostring(composition)
			)
			return ok
		end,
		"Tools-only: xhs_bots_test_config <count> <easy|normal> <composition>",
		commandFlags
	)

	Convars:RegisterCommand(
		"xhs_bots_test_launch",
		function()
			local ok, message = XHSBots:TestLaunchFromConsole()
			XHSBots:PrintQAResult("xhs_bots_test_launch", ok, message)
			return ok
		end,
		"Tools-only: finish custom setup through the normal XHS bot provisioning hook",
		commandFlags
	)

	Convars:RegisterCommand(
		"xhs_bots_test_pick_human",
		function(_, heroName)
			local ok, message, fields = XHSBots:TestPickHumanFromConsole(heroName)
			XHSBots:PrintQAResult("xhs_bots_test_pick_human", ok, message, fields)
			return ok
		end,
		"Tools-only: xhs_bots_test_pick_human <certified-or-standard hero>",
		commandFlags
	)

	Convars:RegisterCommand(
		"xhs_bots_test_scenario",
		function(_, scenarioName)
			local ok, message, fields = XHSBots:TestScenarioFromConsole(scenarioName)
			XHSBots:PrintQAResult("xhs_bots_test_scenario", ok, message, fields)
			return ok
		end,
		"Tools-only: xhs_bots_test_scenario <danger|reassign|stuck|respawn|economy>",
		commandFlags
	)

	Convars:RegisterCommand(
		"xhs_bots_test_encounter",
		function(_, encounterName)
			local ok, message, fields = XHSBots:TestEncounterFromConsole(encounterName)
			XHSBots:PrintQAResult("xhs_bots_test_encounter", ok, message, fields)
			return ok
		end,
		"Tools-only: xhs_bots_test_encounter <muradin|ramero_baristol|sogat|farm>",
		commandFlags
	)

	Convars:RegisterCommand(
		"xhs_bots_test_dump",
		function()
			local ok, message, fields = XHSBots:TestDumpFromConsole()
			XHSBots:PrintQAResult("xhs_bots_test_dump", ok, message, fields)
			return ok
		end,
		"Tools-only: print bounded structured state and telemetry for every XHS bot",
		commandFlags
	)

	Convars:RegisterCommand(
		"xhs_bots_test_economy_audit",
		function(_, action)
			local ok, message, fields =
				XHSBots:TestEconomyAuditFromConsole(action)
			XHSBots:PrintQAResult(
				"xhs_bots_test_economy_audit",
				ok,
				message,
				fields
			)
			return ok
		end,
		"Tools-only: xhs_bots_test_economy_audit <start|check|watch|stop|reset>",
		commandFlags
	)
end

function XHSBots:TestScenarioFromConsole(scenarioName)
	if not IsInToolsMode() or not self.enabled then
		return false, "unavailable_outside_tools"
	end

	scenarioName = string.lower(tostring(scenarioName or ""))
	local allowed = {
		danger = true,
		reassign = true,
		stuck = true,
		respawn = true,
		economy = true,
	}
	if not allowed[scenarioName] then
		return false, "unsupported_scenario",
			"scenario=" .. self:FormatQALogValue(scenarioName, 24)
	end

	local ok, message = self:RunScenario(scenarioName)
	return ok, message, "scenario=" .. self:FormatQALogValue(scenarioName, 24)
end

function XHSBots:TestEncounterFromConsole(encounterName)
	if not IsInToolsMode() or not self.enabled then
		return false, "unavailable_outside_tools"
	end
	if GameRules == nil
		or GameRules:State_Get() ~= DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		return false, "game_not_in_progress"
	end
	if SpecialEvents == nil then return false, "special_events_unavailable" end
	if GameMode ~= nil
		and (GameMode.Muradin_occuring == true
			or GameMode.SpecialArena_occuring == true
			or GameMode.FarmEvent_occuring == true) then
		return false, "encounter_already_active"
	end

	encounterName = string.lower(tostring(encounterName or ""))
	local allowed = {
		muradin = true,
		ramero_baristol = true,
		sogat = true,
		farm = true,
	}
	if not allowed[encounterName] then
		return false, "unsupported_encounter",
			"encounter=" .. self:FormatQALogValue(encounterName, 24)
	end

	local botPlayerID = nil
	local botHero = nil
	for _, playerID in ipairs(XHSBotPlayerRegistry:GetXHSBotPlayerIDs()) do
		local hero = PlayerResource:GetSelectedHeroEntity(playerID)
		if hero ~= nil and not hero:IsNull() and hero:IsAlive() then
			botPlayerID = playerID
			botHero = hero
			break
		end
	end
	if botHero == nil then return false, "no_alive_bot_hero" end

	if encounterName == "muradin" then
		SpecialEvents:MuradinEvent(45)
	elseif encounterName == "ramero_baristol" then
		SpecialEvents:StartRameroAndBaristolEvent(botHero)
	elseif encounterName == "sogat" then
		SpecialEvents:StartSogatEvent(botHero)
	else
		SpecialEvents:FarmEvent(60)
	end
	return true, "encounter_started",
		"encounter=" .. self:FormatQALogValue(encounterName, 24)
			.. " pid=" .. tostring(botPlayerID)
end

function XHSBots:TestDumpFromConsole()
	if not IsInToolsMode() or not self.enabled then
		return false, "unavailable_outside_tools"
	end

	-- Keep the nettable and console snapshots sourced from the same live records.
	self:PushDebugState()
	local playerIDs = XHSBotPlayerRegistry:GetXHSBotPlayerIDs()
	for _, playerID in ipairs(playerIDs) do
		local record = XHSBotPlayerRegistry:GetBot(playerID) or {}
		local now = GameRules ~= nil and GameRules.GetGameTime ~= nil
			and GameRules:GetGameTime() or 0
		local operationsPerSecond = XHSBotExecutor:GetOrdersPerSecond(record, now)
		local physicalLanes = {}
		for _, lane in ipairs(record.physical_lanes or {}) do
			table.insert(physicalLanes, tostring(tonumber(lane) or 0))
		end
		local shoppingGoal = type(record.shopping_goal) == "table"
			and record.shopping_goal or {}
		self:PrintQAResult(
			"xhs_bots_test_dump",
			true,
			"bot_state",
			"pid=" .. tostring(tonumber(playerID) or -1)
				.. " state=" .. self:FormatQALogValue(record.state, 32)
				.. " goal=" .. self:FormatQALogValue(
					record.goal or record.macro_state,
					48
				)
				.. " lane=" .. tostring(tonumber(record.lane) or 0)
				.. " physical_lanes=" .. self:FormatQALogValue(
					table.concat(physicalLanes, ","),
					24
				)
				.. " orders=" .. tostring(tonumber(record.orders) or 0)
				.. " ops=" .. string.format("%.3f", tonumber(operationsPerSecond) or 0)
				.. " decision_avg_ms=" .. string.format(
					"%.3f",
					tonumber(record.decision_cost_average_ms) or 0
				)
				.. " decision_max_ms=" .. string.format(
					"%.3f",
					tonumber(record.decision_cost_max_ms) or 0
				)
				.. " gold=" .. tostring(math.floor(
					tonumber(XHSBotEconomy:GetGold(playerID)) or 0
				))
				.. " phase=" .. self:FormatQALogValue(
					record.economy_phase,
					24
				)
				.. " reserve=" .. tostring(math.floor(
					tonumber(record.economy_reserve_gold) or 0
				))
				.. " next_item=" .. self:FormatQALogValue(
					record.planned_item,
					48
				)
				.. " route_shop=" .. self:FormatQALogValue(
					shoppingGoal.shop,
					16
				)
				.. " last_purchase=" .. self:FormatQALogValue(
					record.last_purchase_item,
					48
				)
				.. " required_shop=" .. self:FormatQALogValue(
					record.last_purchase_shop,
					16
				)
				.. " last_shop=" .. self:FormatQALogValue(
					record.last_purchase_shop_kind,
					16
				)
				.. " shop_distance=" .. tostring(math.floor(
					tonumber(record.last_purchase_shop_distance) or -1
				))
				.. " last_purchase_at=" .. string.format(
					"%.1f",
					tonumber(record.last_purchase_at) or 0
				)
				.. " purchases=" .. tostring(
					tonumber(record.items_purchased) or 0
				)
				.. " spent=" .. tostring(math.floor(
					tonumber(record.item_gold_spent) or 0
				))
				.. " shop_violations=" .. tostring(
					tonumber(record.shop_purchase_violation_count) or 0
				)
				.. " item_action=" .. self:FormatQALogValue(
					record.last_item_action,
					64
				)
				.. " hp_potions=" .. tostring(
					tonumber(record.health_potion_charges) or 0
				) .. "/" .. tostring(
					tonumber(record.health_potion_target) or 0
				)
				.. " mana_potions=" .. tostring(
					tonumber(record.mana_potion_charges) or 0
				) .. "/" .. tostring(
					tonumber(record.mana_potion_target) or 0
				)
				.. " ankhs=" .. tostring(
					tonumber(record.ankh_charges) or 0
				) .. "/" .. tostring(
					tonumber(record.ankh_target) or 0
				)
				.. " slots=" .. tostring(
					tonumber(record.active_item_slots) or 0
				) .. "/" .. tostring(
					tonumber(record.inventory_item_slots) or 0
				)
				.. " stash=" .. tostring(
					tonumber(record.stash_item_count) or 0
				)
				.. " item_error=" .. self:FormatQALogValue(
					record.last_item_rejection,
					96
				)
				.. " error=" .. self:FormatQALogValue(record.error, 96)
		)
	end
	return true, "dump_complete", "bots=" .. tostring(#playerIDs)
end

function XHSBots:GetQAEconomyFamilies(hero)
	local families = {}
	local coreItems = 0
	if not IsValidHero(hero) then return {}, 0, 0 end

	for slot = 0, XHSBotEconomy.INVENTORY_LAST_SLOT do
		local item = hero:GetItemInSlot(slot)
		local ok, itemName = pcall(function()
			if item == nil or item:IsNull() then return nil end
			return item:GetAbilityName()
		end)
		local entry = ok and itemName ~= nil
			and XHSBotItemCatalog:Get(itemName) or nil
		if entry ~= nil and entry.kind == "core" and entry.family ~= nil then
			families[tostring(entry.family)] = true
			coreItems = coreItems + 1
		end
	end

	local names = {}
	for familyName in pairs(families) do table.insert(names, familyName) end
	table.sort(names)
	return names, #names, coreItems
end

function XHSBots:StartEconomyAudit(playerIDs)
	if not IsInToolsMode() or not self.enabled then
		return false, "unavailable_outside_tools"
	end
	if GameRules == nil
		or GameRules:State_Get() ~= DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		return false, "game_not_in_progress"
	end
	self:StopEconomyAuditWatch(true)

	local requested = type(playerIDs) == "table"
		and playerIDs or XHSBotPlayerRegistry:GetXHSBotPlayerIDs()
	local now = GameRules:GetGameTime()
	local audit = {
		started_at = now,
		difficulty = tostring(self.configuration.difficulty or "normal"),
		min_duration = self.qa_economy_audit_min_duration,
		timeout = self.qa_economy_audit_timeout,
		global_safe_errors = tonumber(self.safe_error_count) or 0,
		bots = {},
		player_ids = {},
	}
	local seen = {}
	for _, rawPlayerID in ipairs(requested) do
		local playerID = tonumber(rawPlayerID)
		if playerID ~= nil and not seen[playerID] then
			seen[playerID] = true
			local record = XHSBotPlayerRegistry:GetBot(playerID) or {}
			audit.bots[playerID] = {
				items_purchased = tonumber(record.items_purchased) or 0,
				item_gold_spent = tonumber(record.item_gold_spent) or 0,
				tomes_bought = tonumber(record.tomes_bought) or 0,
				plan_switches = tonumber(record.economy_plan_switches) or 0,
				inventory_full_events =
					tonumber(record.inventory_full_events) or 0,
				replacement_restore_failures =
					tonumber(record.replacement_restore_failures) or 0,
				safe_errors = tonumber(record.safe_error_count) or 0,
				shop_violations =
					tonumber(record.shop_purchase_violation_count) or 0,
				wallet_desync_since = nil,
			}
			table.insert(audit.player_ids, playerID)
		end
	end
	table.sort(audit.player_ids)
	audit.bot_count = #audit.player_ids
	if audit.bot_count <= 0 then
		self.qa_economy_audit = nil
		return false, "no_registered_bots"
	end

	self.qa_economy_audit = audit
	return true,
		"audit_started",
		"verdict=wait bots=" .. tostring(audit.bot_count)
			.. " difficulty=" .. self:FormatQALogValue(audit.difficulty, 16)
			.. " min_seconds=" .. tostring(audit.min_duration)
			.. " timeout_seconds=" .. tostring(audit.timeout)
end

function XHSBots:GetQAPurchaseShopIssue(record, auditStartedAt)
	local lastPurchaseAt = tonumber(record.last_purchase_at) or 0
	if lastPurchaseAt < (tonumber(auditStartedAt) or 0) then
		return "purchase_timestamp_missing"
	end

	local requiredShop = tostring(record.last_purchase_shop or "")
	local actualShop = tostring(record.last_purchase_shop_kind or "")
	local validKind = requiredShop == "secret" and actualShop == "secret"
		or requiredShop == "base" and actualShop == "base"
		or requiredShop == "home"
			and (actualShop == "base" or actualShop == "lane")
	if not validKind then
		return "shop_mismatch:" .. requiredShop .. ":" .. actualShop
	end

	local maximumDistance = actualShop == "base"
		and XHSBotEconomy.BASE_SHOP_RADIUS
		or actualShop == "lane" and XHSBotEconomy.LANE_SHOP_RADIUS
		or actualShop == "secret" and XHSBotEconomy.SECRET_SHOP_RADIUS
		or -1
	local distance = tonumber(record.last_purchase_shop_distance) or -1
	if maximumDistance < 0 or distance < 0 or distance > maximumDistance + 1 then
		return "shop_distance:" .. tostring(math.floor(distance))
			.. ":" .. tostring(maximumDistance)
	end
	return nil
end

function XHSBots:EvaluateEconomyAudit(emitBotLines)
	local audit = self.qa_economy_audit
	if type(audit) ~= "table" then return false, "audit_not_started" end
	if GameRules == nil
		or GameRules:State_Get() ~= DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		return false, "game_not_in_progress"
	end

	local now = GameRules:GetGameTime()
	local elapsed = math.max(0, now - (tonumber(audit.started_at) or now))
	local timedOut = elapsed >= (tonumber(audit.timeout) or 90)
	local difficulty =
		XHSBotConfig:GetDifficulty(audit.difficulty) or {}
	local expectedHealthTarget =
		tonumber(difficulty.target_health_potion_charges) or 5
	local expectedManaTarget =
		tonumber(difficulty.target_mana_potion_charges) or 5
	local hardFailures = 0
	local pendingCount = 0
	local totalPurchases = 0
	local totalSpend = 0
	local distinctFamilies = {}
	local evaluatedBots = 0

	local function Add(list, value)
		if value == nil or value == "" then return end
		table.insert(list, tostring(value))
	end
	local function Delta(record, key, baseline)
		return (tonumber(record[key]) or 0)
			- (tonumber(baseline[key]) or 0)
	end

	for _, playerID in ipairs(audit.player_ids or {}) do
		local baseline = audit.bots[playerID] or {}
		local record = XHSBotPlayerRegistry:GetBot(playerID)
		local hero = XHSBotPlayerRegistry:GetBotHero(playerID)
		local issues = {}
		local pending = {}
		local alive = false
		local purchases = 0
		local spend = 0
		local familyNames = {}
		local familyCount = 0
		local logicalGold = 0
		local nativeGold = -1

		if record == nil then
			Add(issues, "record_missing")
		elseif not IsValidHero(hero) then
			Add(issues, "hero_missing")
		else
			evaluatedBots = evaluatedBots + 1
			local aliveOK, isAlive = pcall(function() return hero:IsAlive() end)
			alive = aliveOK and isAlive == true
			purchases = Delta(record, "items_purchased", baseline)
			spend = Delta(record, "item_gold_spent", baseline)
			totalPurchases = totalPurchases + math.max(0, purchases)
			totalSpend = totalSpend + math.max(0, spend)
			familyNames, familyCount =
				self:GetQAEconomyFamilies(hero)
			for _, familyName in ipairs(familyNames) do
				distinctFamilies[familyName] = true
			end

			if purchases < 0 then Add(issues, "purchase_counter_regressed") end
			if spend < 0 then Add(issues, "spend_counter_regressed") end
			if purchases > 0 and spend <= 0 then
				Add(issues, "purchase_without_spend")
			end
			if purchases > self.qa_economy_audit_max_purchases then
				Add(issues, "purchase_loop_suspected")
			end

			local safeErrors = Delta(record, "safe_error_count", {
				safe_error_count = baseline.safe_errors,
			})
			if safeErrors > 0 then Add(issues, "safe_error_delta:" .. safeErrors) end
			local shopViolations = Delta(
				record,
				"shop_purchase_violation_count",
				{ shop_purchase_violation_count = baseline.shop_violations }
			)
			if shopViolations > 0 then
				Add(issues, "shop_violation_delta:" .. shopViolations)
			end
			if tostring(record.error or "") ~= "" then
				Add(issues, "record_error")
			end
			if Delta(
				record,
				"replacement_restore_failures",
				baseline
			) > 0 then
				Add(issues, "replacement_restore_failure")
			end
			if Delta(record, "inventory_full_events", baseline) > 8 then
				Add(issues, "inventory_loop_suspected")
			end
			local planSwitches = Delta(record, "economy_plan_switches", {
				economy_plan_switches = baseline.plan_switches,
			})
			if planSwitches > math.max(3, purchases + 3) then
				Add(issues, "plan_oscillation:" .. tostring(planSwitches))
			end

			if (tonumber(record.stash_item_count) or 0)
				> XHSBotEconomy.STASH_CAPACITY then
				Add(issues, "stash_overflow")
			end
			local healthTarget = tonumber(record.health_potion_target) or 0
			local manaTarget = tonumber(record.mana_potion_target) or 0
			if healthTarget <= 0 or manaTarget <= 0 then
				Add(pending, "stock_targets_pending")
			else
				if healthTarget ~= expectedHealthTarget then
					Add(issues, "health_target:" .. tostring(healthTarget))
				end
				if manaTarget ~= expectedManaTarget then
					Add(issues, "mana_target:" .. tostring(manaTarget))
				end
			end
			local ankhTarget = tonumber(record.ankh_target) or 0
			if ankhTarget < 0 or ankhTarget > 2 then
				Add(issues, "ankh_target:" .. tostring(ankhTarget))
			end

			logicalGold = math.floor(
				tonumber(XHSBotEconomy:GetGold(playerID)) or 0
			)
			local nativeOK, currentNativeGold = pcall(function()
				return PlayerResource:GetGold(playerID)
			end)
			if not nativeOK then
				Add(issues, "native_wallet_unreadable")
			else
				nativeGold = math.floor(tonumber(currentNativeGold) or 0)
				local expectedNative = Gold ~= nil and Gold.GetGold ~= nil
					and math.min(
						logicalGold,
						XHSBotEconomy.ENGINE_GOLD_CAP
					) or logicalGold
				if nativeGold ~= expectedNative then
					baseline.wallet_desync_since =
						tonumber(baseline.wallet_desync_since) or now
					if now - baseline.wallet_desync_since
						>= self.qa_economy_audit_wallet_grace then
						Add(
							issues,
							"wallet_desync:" .. tostring(logicalGold)
								.. ":" .. tostring(nativeGold)
						)
					else
						Add(pending, "wallet_resync_pending")
					end
				else
					baseline.wallet_desync_since = nil
				end
			end

			if purchases > 0 then
				local shopIssue =
					self:GetQAPurchaseShopIssue(record, audit.started_at)
				Add(issues, shopIssue)
			else
				if not alive then
					Add(pending, "bot_dead")
				elseif type(record.shopping_goal) == "table" then
					Add(pending, "shopping")
				else
					Add(pending, "no_purchase_progress")
				end
			end
			if familyCount <= 0 then Add(pending, "core_pending") end
			local tomeDelta = Delta(record, "tomes_bought", baseline)
			if tomeDelta > 0
				and (record.economy_phase == "sustain"
					or record.economy_phase == "core_1") then
				Add(issues, "early_tome_spend:" .. tostring(tomeDelta))
			end
		end

		if timedOut and #pending > 0 then
			for _, reason in ipairs(pending) do
				Add(issues, "timeout_" .. reason)
			end
			pending = {}
		end
		local verdict = #issues > 0 and "fail"
			or #pending > 0 and "wait" or "pass"
		hardFailures = hardFailures + #issues
		pendingCount = pendingCount + #pending
		if emitBotLines ~= false then
			self:PrintQAResult(
				"xhs_bots_test_economy_audit",
				#issues == 0,
				"bot_audit",
				"verdict=" .. verdict
					.. " pid=" .. tostring(playerID)
					.. " alive=" .. (alive and "1" or "0")
					.. " purchases_delta=" .. tostring(purchases)
					.. " spend_delta=" .. tostring(math.floor(spend))
					.. " gold=" .. tostring(logicalGold)
					.. " native_gold=" .. tostring(nativeGold)
					.. " families=" .. self:FormatQALogValue(
						table.concat(familyNames, ","),
						80
					)
					.. " hp=" .. tostring(
						tonumber(record and record.health_potion_charges) or 0
					) .. "/" .. tostring(
						tonumber(record and record.health_potion_target) or 0
					)
					.. " mana=" .. tostring(
						tonumber(record and record.mana_potion_charges) or 0
					) .. "/" .. tostring(
						tonumber(record and record.mana_potion_target) or 0
					)
					.. " ankhs=" .. tostring(
						tonumber(record and record.ankh_charges) or 0
					) .. "/" .. tostring(
						tonumber(record and record.ankh_target) or 0
					)
					.. " stash=" .. tostring(
						tonumber(record and record.stash_item_count) or 0
					)
					.. " issues=" .. self:FormatQALogValue(
						table.concat(issues, ","),
						160
					)
					.. " pending=" .. self:FormatQALogValue(
						table.concat(pending, ","),
						120
					)
			)
		end
	end

	local globalSafeErrors = (tonumber(self.safe_error_count) or 0)
		- (tonumber(audit.global_safe_errors) or 0)
	if globalSafeErrors > 0 then
		hardFailures = hardFailures + 1
	end
	local distinctFamilyCount = 0
	for _ in pairs(distinctFamilies) do
		distinctFamilyCount = distinctFamilyCount + 1
	end
	local diversityPending = audit.bot_count >= 3
		and distinctFamilyCount < 2
	if diversityPending then
		if timedOut then
			hardFailures = hardFailures + 1
		else
			pendingCount = pendingCount + 1
		end
	end

	local verdict = hardFailures > 0 and "fail"
		or elapsed < (tonumber(audit.min_duration) or 20) and "wait"
		or pendingCount > 0 and "wait" or "pass"
	local fields = "verdict=" .. verdict
		.. " elapsed=" .. string.format("%.1f", elapsed)
		.. " bots=" .. tostring(evaluatedBots)
		.. "/" .. tostring(audit.bot_count)
		.. " purchases_delta=" .. tostring(totalPurchases)
		.. " spend_delta=" .. tostring(math.floor(totalSpend))
		.. " families=" .. tostring(distinctFamilyCount)
		.. " failures=" .. tostring(hardFailures)
		.. " pending=" .. tostring(pendingCount)
		.. " global_safe_errors=" .. tostring(globalSafeErrors)
	if verdict == "fail" then return false, "audit_failed", fields end
	if verdict == "wait" then return true, "audit_wait", fields end
	audit.completed_at = now
	return true, "audit_passed", fields
end

function XHSBots:StopEconomyAuditWatch(silent)
	self.qa_economy_audit_watch_generation =
		(tonumber(self.qa_economy_audit_watch_generation) or 0) + 1
	local wasRunning = self.qa_economy_audit_watch_running == true
	self.qa_economy_audit_watch_running = false
	local gameMode = GameRules ~= nil
		and GameRules.GetGameModeEntity ~= nil
		and GameRules:GetGameModeEntity() or nil
	if gameMode ~= nil and gameMode.SetContextThink ~= nil then
		pcall(function()
			gameMode:SetContextThink(
				self.qa_economy_audit_watch_context,
				nil,
				0
			)
		end)
	end
	if silent == true then return true end
	return true,
		wasRunning and "audit_watch_stopped" or "audit_watch_idle",
		"verdict=stopped"
end

function XHSBots:StartEconomyAuditWatch()
	if not IsInToolsMode() or not self.enabled then
		return false, "unavailable_outside_tools"
	end
	if type(self.qa_economy_audit) ~= "table" then
		return false, "audit_not_started"
	end
	local gameMode = GameRules ~= nil
		and GameRules.GetGameModeEntity ~= nil
		and GameRules:GetGameModeEntity() or nil
	if gameMode == nil or gameMode.SetContextThink == nil then
		return false, "context_think_unavailable"
	end

	self:StopEconomyAuditWatch(true)
	self.qa_economy_audit_watch_generation =
		(tonumber(self.qa_economy_audit_watch_generation) or 0) + 1
	local generation = self.qa_economy_audit_watch_generation
	self.qa_economy_audit_watch_running = true
	local installed = pcall(function()
		gameMode:SetContextThink(
			self.qa_economy_audit_watch_context,
			function()
				if XHSBots.qa_economy_audit_watch_running ~= true
					or XHSBots.qa_economy_audit_watch_generation
						~= generation then
					return nil
				end
				local executed, result = xpcall(function()
					local ok, message, fields =
						XHSBots:EvaluateEconomyAudit(false)
					return {
						ok = ok,
						message = message,
						fields = fields,
					}
				end, function(err)
					if debug ~= nil and debug.traceback ~= nil then
						return debug.traceback(tostring(err))
					end
					return tostring(err)
				end)
				if not executed then
					XHSBots.qa_economy_audit_watch_running = false
					XHSBots:PrintQAResult(
						"xhs_bots_test_economy_audit",
						false,
						"audit_watch_error",
						"verdict=fail error="
							.. XHSBots:FormatQALogValue(result, 240)
					)
					return nil
				end
				if result.message == "audit_wait" then
					return XHSBots.qa_economy_audit_watch_interval
				end

				XHSBots:EvaluateEconomyAudit(true)
				XHSBots.qa_economy_audit_watch_running = false
				XHSBots:PrintQAResult(
					"xhs_bots_test_economy_audit",
					result.ok,
					result.message,
					result.fields
				)
				return nil
			end,
			0.25
		)
	end)
	if not installed then
		self.qa_economy_audit_watch_running = false
		return false, "audit_watch_install_failed"
	end
	return true,
		"audit_watch_started",
		"verdict=wait interval="
			.. tostring(self.qa_economy_audit_watch_interval)
			.. " timeout="
			.. tostring(self.qa_economy_audit.timeout)
end

function XHSBots:TestEconomyAuditFromConsole(action)
	if not IsInToolsMode() or not self.enabled then
		return false, "unavailable_outside_tools"
	end
	action = string.lower(tostring(action or "check"))
	if action == "start" then return self:StartEconomyAudit() end
	if action == "watch" then return self:StartEconomyAuditWatch() end
	if action == "stop" then return self:StopEconomyAuditWatch(false) end
	if action == "reset" then
		self:StopEconomyAuditWatch(true)
		self.qa_economy_audit = nil
		return true, "audit_reset", "verdict=reset"
	end
	if action ~= "check" then
		return false,
			"unsupported_audit_action",
			"action=" .. self:FormatQALogValue(action, 24)
	end
	return self:EvaluateEconomyAudit()
end

function XHSBots:TestLaunchFromConsole()
	if not IsInToolsMode() or not self.enabled then
		return false, "unavailable_outside_tools"
	end
	if GameRules:State_Get() ~= DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		return false, "invalid_state_expected_custom_game_setup"
	end
	if self.locked then
		return false, "configuration_already_locked"
	end
	if GameMode == nil or GameMode.FinishCustomSetup == nil then
		return false, "normal_setup_finish_hook_unavailable"
	end
	if GameMode.CustomSetupState == nil or GameMode.CustomSetupState.active ~= true then
		return false, "custom_setup_not_active"
	end

	GameMode:FinishCustomSetup("bot_qa_console")
	return true, "launch_requested_through_normal_provisioning_hook"
end

function XHSBots:NormalizeQAHeroName(heroName)
	heroName = string.lower(tostring(heroName or ""))
	if string.find(heroName, "^npc_dota_hero_") ~= 1 then
		heroName = "npc_dota_hero_" .. heroName
	end
	return heroName
end

function XHSBots:IsQAHeroAllowed(heroName)
	for _, entry in ipairs(XHSBotHeroProfiles:GetCoverage()) do
		if entry.hero == heroName then return true end
	end
	return false
end

function XHSBots:FindFirstPersistentHumanPlayerID()
	for _, playerID in ipairs(XHSBotPlayerRegistry:GetHumanPlayerIDs()) do
		if IsXHSPersistentPlayerID == nil or IsXHSPersistentPlayerID(playerID) then
			return playerID
		end
	end
	return -1
end

function XHSBots:TestPickHumanFromConsole(heroName)
	if not IsInToolsMode() or not self.enabled then
		return false, "unavailable_outside_tools"
	end
	local currentState = GameRules:State_Get()
	if currentState < DOTA_GAMERULES_STATE_HERO_SELECTION
		or currentState > DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		return false, "invalid_state_expected_playable_selection_window"
	end
	if self.qa_human_pick_pending then
		return false, "human_pick_already_pending"
	end

	heroName = self:NormalizeQAHeroName(heroName)
	if not self:IsQAHeroAllowed(heroName) then
		return false, "hero_not_in_certified_or_standard_allowlist", "hero=" .. heroName
	end
	if XHSPrecache == nil or XHSPrecache.ReplaceHeroWith == nil then
		return false, "replace_hero_helper_unavailable"
	end

	local playerID = self:FindFirstPersistentHumanPlayerID()
	if playerID < 0 or not PlayerResource:IsValidPlayerID(playerID) then
		return false, "no_persistent_human"
	end
	local player = PlayerResource:GetPlayer(playerID)
	local oldHero = player ~= nil and player:GetAssignedHero() or nil
	if not IsValidHero(oldHero) then
		oldHero = PlayerResource:GetSelectedHeroEntity(playerID)
	end
	if not IsValidHero(oldHero) or oldHero:GetUnitName() ~= "npc_dota_hero_wisp" then
		return false, "first_persistent_human_is_not_wisp", "player_id=" .. tostring(playerID)
	end

	local difficulty = GameRules:GetCustomGameDifficulty()
	local startingGold = XHS_STARTING_GOLD and XHS_STARTING_GOLD[difficulty] or 0
	local origin = oldHero:GetAbsOrigin()
	self.qa_human_pick_generation = self.qa_human_pick_generation + 1
	local generation = self.qa_human_pick_generation
	self.qa_human_pick_pending = true
	self.qa_human_pick_timed_out = false
	self:OnHumanHeroSelected(playerID, heroName)

	local ok, replaceError = pcall(function()
		XHSPrecache:ReplaceHeroWith(playerID, heroName, startingGold, 0, oldHero, {
			startingItems = true,
		}, function(newHero)
			if XHSBots.qa_human_pick_generation ~= generation then return end
			XHSBots.qa_human_pick_pending = false
			XHSBots.qa_human_pick_timed_out = false

			if not IsValidHero(newHero) or newHero:GetPlayerID() ~= playerID then
				XHSBots:PrintQAResult(
					"xhs_bots_test_pick_human",
					false,
					"replace_callback_returned_no_matching_hero",
					"player_id=" .. tostring(playerID) .. " hero=" .. heroName
				)
				return
			end

			if FindClearSpaceForUnit ~= nil then
				FindClearSpaceForUnit(newHero, origin, true)
			end
			XHSBotProvisioner:RemoveSelectionTrigger(heroName)
			XHSBots:PrintQAResult(
				"xhs_bots_test_pick_human",
				true,
				"replace_callback_completed",
				"player_id=" .. tostring(playerID) .. " hero=" .. heroName
			)
		end)
	end)

	if not ok then
		self.qa_human_pick_pending = false
		return false, "replace_hero_call_failed", "error=" .. tostring(replaceError)
	end

	Timers:CreateTimer(self.qa_human_pick_timeout, function()
		if XHSBots.qa_human_pick_pending
			and XHSBots.qa_human_pick_generation == generation then
			XHSBots.qa_human_pick_timed_out = true
			XHSBots:PrintQAResult(
				"xhs_bots_test_pick_human",
				false,
				"replace_callback_timeout_no_retry",
				"player_id=" .. tostring(playerID) .. " hero=" .. heroName
			)
		end
		return nil
	end)

	return true, "replace_requested", "player_id=" .. tostring(playerID) .. " hero=" .. heroName
end

function XHSBots:ApplyConfiguration(configuration)
	configuration = configuration or {}
	SetupLog("apply_configuration_requested", {
		count = configuration.count,
		difficulty = configuration.difficulty,
		composition = configuration.composition,
		enabled = self.enabled,
		game_state = GameRules:State_Get(),
		human_count = XHSBotPlayerRegistry:GetHumanCount(),
		locked = self.locked,
		revision = self.revision,
		tools_mode = IsInToolsMode(),
	})
	if not IsInToolsMode() or not self.enabled then
		SetupLog("apply_configuration_rejected", {
			reason = "outside_tools_or_disabled",
		})
		return false, "AI allies are unavailable outside Tools mode"
	end
	if GameRules:State_Get() ~= DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		self.error = "AI settings can only change during custom setup"
		SetupLog("apply_configuration_rejected", {
			game_state = GameRules:State_Get(),
			reason = "outside_custom_setup",
		})
		self:PushConfiguration()
		return false, self.error
	end
	if self.locked then
		self.error = "AI settings are locked"
		SetupLog("apply_configuration_rejected", {
			reason = "setup_locked",
		})
		self:PushConfiguration()
		return false, self.error
	end

	self.controller_player_id = self:FindControllerPlayerID()
	self.unique_hero_count_finalized = false
	self.configuration = XHSBotConfig:Normalize(
		configuration,
		XHSBotPlayerRegistry:GetHumanCount()
	)
	self.revision = self.revision + 1
	self.status = "ready"
	self.error = ""
	SetupLog("apply_configuration_normalized", {
		controller_player_id = self.controller_player_id,
		count = self.configuration.count,
		difficulty = self.configuration.difficulty,
		composition = self.configuration.composition,
		maximum_bots = self.configuration.maximum_bots,
		revision = self.revision,
	})
	self:PushConfiguration()
	self:PushRoster()
	SetupLog("apply_configuration_completed", {
		count = self.configuration.count,
		difficulty = self.configuration.difficulty,
		composition = self.configuration.composition,
		revision = self.revision,
	})
	return true, "Configured " .. tostring(self.configuration.count)
		.. " " .. tostring(self.configuration.difficulty)
		.. " bot(s), composition " .. tostring(self.configuration.composition)
end

function XHSBots:OnConfigure(sourceIndex, event)
	local senderPlayerID = self:ResolveSenderPlayerID(sourceIndex)
	SetupLog("configure_event_received", {
		source_index = sourceIndex,
		sender_player_id = senderPlayerID,
		payload_bot_count = event and (event.count or event.bot_count),
		payload_difficulty = event and (event.difficulty or event.ai_difficulty),
		payload_composition = event and event.composition,
		payload_player_id = event and event.PlayerID,
		enabled = self.enabled,
		locked = self.locked,
		game_state = GameRules:State_Get(),
		tools_mode = IsInToolsMode(),
	})
	if not IsInToolsMode() or not self.enabled then
		SetupLog("configure_event_rejected", {
			reason = "outside_tools_or_disabled",
			sender_player_id = senderPlayerID,
		})
		return
	end
	if GameRules:State_Get() ~= DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		self.error = "AI settings can only change during custom setup"
		SetupLog("configure_event_rejected", {
			game_state = GameRules:State_Get(),
			reason = "outside_custom_setup",
			sender_player_id = senderPlayerID,
		})
		self:PushConfiguration()
		return
	end
	if self.locked then
		self.error = "AI settings are locked"
		SetupLog("configure_event_rejected", {
			reason = "setup_locked",
			sender_player_id = senderPlayerID,
		})
		self:PushConfiguration()
		return
	end

	self.controller_player_id = self:FindControllerPlayerID()
	if senderPlayerID < 0 or senderPlayerID ~= self.controller_player_id then
		self.error = "Only the setup controller can configure AI allies"
		SetupLog("configure_event_rejected", {
			controller_player_id = self.controller_player_id,
			reason = "sender_not_controller",
			sender_player_id = senderPlayerID,
		})
		self:PushConfiguration()
		return
	end

	local applied, message = self:ApplyConfiguration({
		count = event and (event.count or event.bot_count),
		difficulty = event and (event.difficulty or event.ai_difficulty),
		composition = event and event.composition,
	})
	SetupLog("configure_event_completed", {
		applied = applied,
		message = message,
		revision = self.revision,
		sender_player_id = senderPlayerID,
	})
end

function XHSBots:BuildConfigurationNetTable()
	local configuration = self.configuration or XHSBotConfig:CopyDefaults()
	return {
		available = self.enabled and 1 or 0,
		bot_count = tonumber(configuration.count) or 0,
		max_bots = tonumber(configuration.maximum_bots) or 0,
		ai_difficulty = configuration.difficulty or "normal",
		composition = configuration.composition or "balanced",
		controller_player_id = tonumber(self.controller_player_id) or -1,
		revision = self.revision,
		locked = self.locked and 1 or 0,
		status = self.status or "disabled",
		error = self.error or "",
		provision_pending = tonumber(XHSBotProvisioner.pending_count) or 0,
		provision_inflight = tonumber(XHSBotProvisioner.inflight_count) or 0,
		provision_failed = tonumber(XHSBotProvisioner.failed_count) or 0,
		provision_timed_out = tonumber(XHSBotProvisioner.timed_out_count) or 0,
		hero_assignment_pending = tonumber(XHSBotProvisioner.hero_assignment_pending_count) or 0,
		hero_assignment_timed_out = tonumber(XHSBotProvisioner.hero_assignment_timed_out_count) or 0,
		qa_human_pick_pending = self.qa_human_pick_pending and 1 or 0,
	}
end

function XHSBots:PushConfiguration()
	if not self.enabled or CustomNetTables == nil then
		SetupLog("config_push_skipped", {
			custom_nettables_available = CustomNetTables ~= nil,
			enabled = self.enabled,
		})
		return
	end
	local payload = self:BuildConfigurationNetTable()
	SetupLog("config_push", {
		available = payload.available,
		bot_count = payload.bot_count,
		max_bots = payload.max_bots,
		difficulty = payload.ai_difficulty,
		composition = payload.composition,
		controller_player_id = payload.controller_player_id,
		revision = payload.revision,
		locked = payload.locked,
		status = payload.status,
		error = payload.error,
	})
	CustomNetTables:SetTableValue("xhs_bots", "config", payload)
end

function XHSBots:BuildRosterNetTable()
	local roster = {}
	local recordsBySlot = {}
	local usedPlayerIDs = {}

	for _, playerID in ipairs(XHSBotPlayerRegistry:GetHumanPlayerIDs()) do
		usedPlayerIDs[playerID] = true
	end
	for _, playerID in ipairs(XHSBotPlayerRegistry:GetXHSBotPlayerIDs()) do
		local record = XHSBotPlayerRegistry:GetBot(playerID)
		if record ~= nil and tonumber(record.slot) ~= nil then
			recordsBySlot[tonumber(record.slot)] = {
				player_id = playerID,
				record = record,
			}
		end
		usedPlayerIDs[playerID] = true
	end

	local nextPreviewPlayerID = 0
	local requestedCount = math.max(0, math.floor(tonumber(self.configuration.count) or 0))
	for slot = 1, requestedCount do
		local slotEntry = recordsBySlot[slot]
		local playerID = slotEntry and slotEntry.player_id or nil
		local record = slotEntry and slotEntry.record or nil
		if playerID == nil then
			while nextPreviewPlayerID <= 7 and usedPlayerIDs[nextPreviewPlayerID] do
				nextPreviewPlayerID = nextPreviewPlayerID + 1
			end
			playerID = nextPreviewPlayerID <= 7 and nextPreviewPlayerID or (100 + slot)
			usedPlayerIDs[playerID] = true
			nextPreviewPlayerID = nextPreviewPlayerID + 1
		end

		local hero = XHSBotPlayerRegistry:GetBotHero(playerID)
		roster[tostring(playerID)] = {
			player_id = playerID,
			slot = slot,
			name = record and record.name
				or XHSBotProvisioner:GetDisplayName(slot),
			hero = IsValidHero(hero) and hero:GetUnitName()
				or (record and record.requested_hero or "npc_dota_hero_wisp"),
			difficulty = record and record.difficulty or self.configuration.difficulty,
			role = record and record.role or "",
			ready = 1,
			engine_ready = record and record.hero_assigned and 1 or 0,
			preview = record == nil and 1 or 0,
			participant_kind = "xhs_bot",
		}
	end
	return {
		count = requestedCount,
		players = roster,
	}
end

function XHSBots:PushRoster()
	if not self.enabled or CustomNetTables == nil then
		SetupLog("roster_push_skipped", {
			custom_nettables_available = CustomNetTables ~= nil,
			enabled = self.enabled,
		})
		return
	end
	local payload = self:BuildRosterNetTable()
	SetupLog("roster_push", {
		count = payload.count,
	})
	CustomNetTables:SetTableValue("xhs_bots", "roster", payload)
end

function XHSBots:BeforeCustomSetupFinish(launchReason, callback)
	if not self.enabled or self.locked then return true end

	self.controller_player_id = self:FindControllerPlayerID()
	self.configuration = XHSBotConfig:Normalize(
		self.configuration,
		XHSBotPlayerRegistry:GetHumanCount()
	)
	self.locked = true
	self.unique_hero_count_finalized = false
	self.status = self.configuration.count > 0 and "waiting_for_human_pick" or "locked"
	self.error = ""
	self.revision = self.revision + 1
	self:PushConfiguration()
	self:PushRoster()

	if self.configuration.count <= 0 then return true end
	SetupLog("provisioning_armed", {
		bot_count = self.configuration.count,
		launch_reason = launchReason,
		trigger = "first_human_hero_pick",
	})
	return true
end

function XHSBots:FinalizeUniqueHeroCount()
	if self.unique_hero_count_finalized then
		return self.configuration.count, self.configuration.count
	end
	local requested = math.max(0, math.floor(tonumber(self.configuration.count) or 0))
	local unavailable = XHSBotProvisioner:GetUnavailableHumanHeroes()
	local capacity = XHSBotHeroProfiles:GetAvailableHeroCount(
		self.configuration.composition,
		unavailable
	)
	local finalCount = math.min(requested, capacity)
	self.configuration.count = finalCount
	self.configuration.enabled = finalCount > 0
	self.configuration.maximum_bots = math.min(
		tonumber(self.configuration.maximum_bots) or capacity,
		capacity
	)
	self.unique_hero_count_finalized = true
	if finalCount ~= requested then
		self.revision = self.revision + 1
		SetupLog("unique_hero_count_adjusted", {
			available_unique_heroes = capacity,
			final_count = finalCount,
			requested_count = requested,
		})
		self:PushConfiguration()
		self:PushRoster()
	end
	return finalCount, requested
end

function XHSBots:StartHeroSelectionProvisioning(triggerPlayerID, triggerHeroName)
	if self.hero_selection_retry_running
		or self.configuration.count <= 0
		or XHSBotProvisioner.provisioned then
		SetupLog("hero_selection_provisioning_start_skipped", {
			already_provisioned = XHSBotProvisioner.provisioned,
			bot_count = self.configuration.count,
			retry_running = self.hero_selection_retry_running,
			trigger_hero = triggerHeroName,
			trigger_player_id = triggerPlayerID,
		})
		return
	end

	self.hero_selection_retry_count = 0
	self.hero_selection_retry_running = true
	self.status = "provisioning"
	self.error = ""
	SetupLog("hero_selection_provisioning_started", {
		bot_count = self.configuration.count,
		game_state = GameRules:State_Get(),
		trigger_hero = triggerHeroName,
		trigger_player_id = triggerPlayerID,
	})
	self:PushConfiguration()

	Timers:CreateTimer(0, function()
		if not XHSBots.hero_selection_retry_running then return nil end

		local currentState = GameRules:State_Get()
		if currentState < DOTA_GAMERULES_STATE_HERO_SELECTION
			or currentState > DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
			XHSBots.hero_selection_retry_running = false
			if not XHSBotProvisioner.provisioned then
				XHSBots.status = "error"
				XHSBots.error = "Bot provisioning left the playable state window"
				SetupLog("hero_selection_provisioning_aborted", {
					created = #XHSBotPlayerRegistry:GetXHSBotPlayerIDs(),
					game_state = currentState,
					requested = XHSBots.configuration.count,
				})
				XHSBots:PushConfiguration()
				XHSBots:PushRoster()
			end
			return nil
		end

		if not XHSBotProvisioner:AreHumanHeroesSelected() then
			if XHSBots.status ~= "waiting_for_all_human_picks" then
				XHSBots.status = "waiting_for_all_human_picks"
				XHSBots.error = ""
				SetupLog("provisioning_waiting_for_all_human_picks", {
					human_count = XHSBotPlayerRegistry:GetHumanCount(),
				})
				XHSBots:PushConfiguration()
			end
			return 0.25
		end

		local finalCount, requestedCount = XHSBots:FinalizeUniqueHeroCount()
		if finalCount <= 0 then
			XHSBots.hero_selection_retry_running = false
			XHSBots.status = "locked"
			XHSBots.error = ""
			SetupLog("provisioning_skipped_no_unique_hero", {
				requested_count = requestedCount,
			})
			XHSBots:PushConfiguration()
			XHSBots:PushRoster()
			return nil
		end

		local created, message = XHSBotProvisioner:Provision(XHSBots.configuration)
		SetupLog("hero_selection_provisioning_attempt", {
			attempt = XHSBots.hero_selection_retry_count + 1,
			created = created,
			message = message,
			requested = XHSBots.configuration.count,
		})
		if created == XHSBots.configuration.count then
			XHSBots.hero_selection_retry_running = false
			XHSBots.status = "provisioned"
			XHSBots.error = ""
			XHSBots:PushConfiguration()
			XHSBots:PushRoster()
			if RefreshXHSCombatLanes ~= nil then
				RefreshXHSCombatLanes()
			end
			return nil
		end

		XHSBots.hero_selection_retry_count = XHSBots.hero_selection_retry_count + 1
		if XHSBots.hero_selection_retry_count >= XHSBots.hero_selection_retry_limit then
			XHSBots.hero_selection_retry_running = false
			XHSBots.status = "error"
			XHSBots.error = "Created " .. tostring(created)
				.. "/" .. tostring(XHSBots.configuration.count)
				.. " bots during hero selection: " .. tostring(message)
			XHSBots:PushConfiguration()
			XHSBots:PushRoster()
			return nil
		end

		XHSBots.status = "deferred"
		XHSBots.error = "Created " .. tostring(created)
			.. "/" .. tostring(XHSBots.configuration.count)
			.. " bots; retrying during hero selection: " .. tostring(message)
		XHSBots:PushConfiguration()
		XHSBots:PushRoster()
		return 0.5
	end)
end

function XHSBots:OnHumanHeroSelected(playerID, heroName)
	SetupLog("human_hero_selected", {
		already_triggered = self.first_human_pick_seen,
		bot_count = self.configuration and self.configuration.count or 0,
		game_state = GameRules:State_Get(),
		hero = heroName,
		player_id = playerID,
	})
	if not self.enabled
		or self.configuration.count <= 0
		or self.first_human_pick_seen
		or not XHSBotPlayerRegistry:IsHumanPlayerID(playerID) then
		return
	end

	self.first_human_pick_seen = true
	self:StartHeroSelectionProvisioning(playerID, heroName)
end

function XHSBots:OnGameRulesStateChange()
	if not self.enabled then return end
	local state = GameRules:State_Get()
	SetupLog("game_state_changed", {
		bot_count = self.configuration and self.configuration.count or 0,
		locked = self.locked,
		state = state,
	})

	if state == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		self.controller_player_id = self:FindControllerPlayerID()
		self.configuration = XHSBotConfig:Normalize(
			self.configuration,
			XHSBotPlayerRegistry:GetHumanCount()
		)
		SetupLog("custom_setup_entered", {
			controller_player_id = self.controller_player_id,
			human_count = XHSBotPlayerRegistry:GetHumanCount(),
		})
		self:PushConfiguration()
		self:StartControllerRefresh("custom_setup_state")
	elseif state == DOTA_GAMERULES_STATE_HERO_SELECTION
		and self.configuration.count > 0
		and not XHSBotProvisioner.provisioned then
		self.status = "waiting_for_human_pick"
		self.error = ""
		SetupLog("waiting_for_first_human_hero_pick", {
			bot_count = self.configuration.count,
		})
		self:PushConfiguration()
		self:PushRoster()
	elseif state >= DOTA_GAMERULES_STATE_PRE_GAME
		and state <= DOTA_GAMERULES_STATE_GAME_IN_PROGRESS
		and self.configuration.count > 0 then
		self:StartThinker()
	elseif state >= DOTA_GAMERULES_STATE_POST_GAME then
		self:Stop()
	end
end

function XHSBots:OnNPCSpawned(event)
	if not self.enabled or event == nil or event.entindex == nil then return end
	local hero = SafeEntityFromIndex(tonumber(event.entindex))
	if not IsValidHero(hero) then return end

	local playerID = hero:GetPlayerID()
	if not XHSBotPlayerRegistry:IsXHSBotPlayerID(playerID) then return end
	if not XHSBotPlayerRegistry:IsEngineBotPlayerID(playerID)
		or PlayerResource:GetTeam(playerID) ~= DOTA_TEAM_GOODGUYS then
		local record = XHSBotPlayerRegistry:GetBot(playerID)
		if record ~= nil then record.error = "Rejected unverified bot hero spawn" end
		return
	end

	-- Provisioner owns registration. Spawn observation may only rebind an
	-- already-correlated fake-client slot; the entity marker is never identity.
	local previousRecord = XHSBotPlayerRegistry:GetBot(playerID)
	local wasDead = previousRecord ~= nil and previousRecord.alive == false
	local record = XHSBotPlayerRegistry:BindHero(playerID, hero)
	if record == nil then return end
	if wasDead then
		self:ResetBotAfterRespawn(playerID, hero, record, "npc_spawned")
	else
		record.next_think_at = GameRules:GetGameTime() + 0.2
	end
end

function XHSBots:ResetBotAfterRespawn(playerID, hero, record, reason)
	record = record or XHSBotPlayerRegistry:GetBot(playerID)
	if record == nil or not IsValidHero(hero) or not hero:IsAlive() then return false end

	local now = GameRules:GetGameTime()
	if tonumber(record.death_started_at) ~= nil then
		record.last_death_duration = math.max(0, now - record.death_started_at)
	end
	record.death_started_at = nil
	XHSBotPlayerRegistry:BindHero(playerID, hero)
	record.hero_assigned = true
	record.alive = true
	record.state = "INITIALIZING"
	record.macro_state = "INITIALIZING"
	record.respawns = (record.respawns or 0) + 1
	record.last_lifecycle_event = "respawn:" .. tostring(reason or "detected")
	record.pending_decision = nil
	record.pending_decision_signature = nil
	record.pending_decision_at = nil
	record.target_entindex = nil
	record.target_score = nil
	record.target_committed_until = nil
	record.last_seen_position = nil
	record.last_seen_at = nil
	record.last_seen_until = nil
	record.stuck_sample_position = hero:GetAbsOrigin()
	record.stuck_sample_at = now
	record.stuck_since = nil
	record.combo_target_entindex = nil
	record.combo_until = nil
	record.order_timestamps = {}
	record.last_order_signature = nil
	record.next_order_at = 0
	record.respond_to_current_danger = nil
	record.next_danger_response_choice = 0
	record.was_in_active_danger = false
	record.recent_physical_damage = 0
	record.recent_magical_damage = 0
	record.recent_pure_damage = 0
	record.physical_threat = 0
	record.magical_threat = 0
	record.pure_threat = 0
	record.damage_type_sample_at = nil
	record.damage_type_last_hit_at = nil
	record.telemetry_last_health = hero:GetHealth()
	record.threat_sample_health = hero:GetHealth()
	record.threat_sample_at = now
	record.next_think_at = now + 0.12
	-- Reincarnation and ordinary respawn can change the persistent Ankh
	-- modifier without touching carried slots. Refresh it immediately and wake
	-- the planner, while deliberately preserving any valid interrupted shop
	-- goal so normal lane/shop arbitration can resume it.
	record.next_economy_think = 0
	record.economy_encounter_mode = ""
	record.economy_no_combat = false
	record.defer_potion_for_spell_now = false
	if XHSBotEconomy ~= nil and XHSBotEconomy.GetAnkhCharges ~= nil then
		local ok, charges = pcall(function()
			return XHSBotEconomy:GetAnkhCharges(hero)
		end)
		if ok then record.ankh_charges = math.max(0, tonumber(charges) or 0) end
	end

	XHSBotTeamDirector.assignments[playerID] = nil
	return true
end

function XHSBots:OnBotHeroReady(playerID, hero)
	SetupLog("bot_hero_ready_callback", {
		hero = IsValidHero(hero) and hero:GetUnitName() or "invalid",
		player_id = playerID,
	})
	local record = XHSBotPlayerRegistry:BindHero(playerID, hero)
	if record == nil then return end
	record.hero_assigned = true
	record.error = nil
	record.next_think_at = GameRules:GetGameTime() + (record.slot or 1) * 0.07
	self:PushRoster()
end

function XHSBots:SafeThinkerTick()
	local status, nextThink = self:RunSafely("thinker", function()
		return self:Think()
	end, nil, 0.2)
	if not status then return 0.2 end
	return nextThink
end

function XHSBots:StartThinker()
	SetupLog("thinker_start_requested", {
		already_running = self.thinker_running,
		bot_count = self.configuration.count,
		enabled = self.enabled,
		game_state = GameRules:State_Get(),
		provisioned = XHSBotProvisioner.provisioned,
	})
	if self.thinker_running or not self.enabled or self.configuration.count <= 0 then return end
	self.thinker_running = true
	XHSBotDangerRegistry:SetEnabled(true)

	GameRules:GetGameModeEntity():SetContextThink("xhs_allied_bots_think", function()
		return XHSBots:SafeThinkerTick()
	end, 0.1)
end

function XHSBots:VerifyBotRecord(playerID, record)
	local now = GameRules:GetGameTime()
	if now < (record.next_engine_verification or 0) then return end
	record.next_engine_verification = now + 2
	record.engine_fake_client = XHSBotPlayerRegistry:IsEngineBotPlayerID(playerID)
	record.engine_team_verified = PlayerResource:IsValidPlayerID(playerID)
		and PlayerResource:GetTeam(playerID) == DOTA_TEAM_GOODGUYS
	record.engine_connection_state = PlayerResource:IsValidPlayerID(playerID)
		and PlayerResource:GetConnectionState(playerID) or -1
	if not record.engine_fake_client then
		record.error = "Registered XHS bot is not reported as a fake client"
	elseif not record.engine_team_verified then
		record.error = "Registered XHS bot is not on Radiant"
	elseif record.error == "Registered XHS bot is not reported as a fake client"
		or record.error == "Registered XHS bot is not on Radiant" then
		record.error = nil
	end
end

function XHSBots:TelemetryClock()
	if Time ~= nil then
		local ok, value = pcall(Time)
		if ok and tonumber(value) ~= nil then return tonumber(value) end
	end
	return GameRules ~= nil and GameRules:GetGameTime() or 0
end

function XHSBots:RecordThinkCost(startedAt)
	local elapsedMs = math.max(0, (self:TelemetryClock() - startedAt) * 1000)
	self.think_ticks = (self.think_ticks or 0) + 1
	self.think_cost_total_ms = (self.think_cost_total_ms or 0) + elapsedMs
	self.think_cost_average_ms = self.think_cost_total_ms / self.think_ticks
	self.think_cost_max_ms = math.max(self.think_cost_max_ms or 0, elapsedMs)
end

function XHSBots:ThinkBot(playerID, now, difficulty)
	local record = XHSBotPlayerRegistry:GetBot(playerID)
	if record == nil then return end
	local hero = XHSBotPlayerRegistry:GetBotHero(playerID)
	self:VerifyBotRecord(playerID, record)

	if IsValidHero(hero)
		and record.hero_assigned == true
		and record.engine_fake_client == true
		and record.engine_team_verified == true
		and not self.paused
		and now >= (record.next_think_at or 0) then
		record.next_think_at = now + difficulty.think_interval
		local profile = XHSBotHeroProfiles:Get(hero:GetUnitName())
		local economyOK, economyState = self:RunSafely(
			"economy:" .. tostring(playerID),
			function()
				return XHSBotEconomy:Think(
					playerID,
					hero,
					record,
					profile,
					difficulty
				)
			end,
			record,
			nil
		)
		if record.team_director_replan_requested == true then
			local replanOK = self:RunSafely(
				"team_director_replan:" .. tostring(playerID),
				function()
					XHSBotTeamDirector:Update(true)
				end,
				record,
				nil
			)
			if replanOK then
				record.team_director_replan_requested = false
			end
		end
		if economyOK and (economyState == "healing"
			or economyState == "shopping"
			or economyState == "item") then
			record.state = string.upper(economyState)
			record.macro_state = XHSBotBrain:MacroState(
				XHSBotTeamDirector:GetAssignment(playerID)
			)
		else
			self:RunSafely("brain:" .. tostring(playerID), function()
				XHSBotBrain:Think(
					playerID,
					hero,
					record,
					XHSBotTeamDirector:GetAssignment(playerID),
					difficulty
				)
			end, record, nil)
		end
	elseif IsValidHero(hero)
		and (record.engine_fake_client ~= true or record.engine_team_verified ~= true) then
		record.state = "ENGINE_IDENTITY_ERROR"
	elseif not IsValidHero(hero) and record.hero_assigned ~= true then
		record.state = "SELECTING_HERO"
		record.macro_state = "SELECTING_HERO"
	end
end

function XHSBots:Think()
	if not self.thinker_running or not self.enabled then return nil end
	if GameRules:IsGamePaused() then return 0.2 end
	local thinkStartedAt = self:TelemetryClock()

	local state = GameRules:State_Get()
	if state > DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		self:Stop()
		self:RecordThinkCost(thinkStartedAt)
		return nil
	end

	local now = GameRules:GetGameTime()
	self:RunSafely("provisioner", function()
		XHSBotProvisioner:TryAssignHeroes(self.configuration)
	end, nil, nil)
	-- npc_spawned is normally emitted on respawn, but XHS also revives heroes
	-- through scripted phase transitions. Detect the dead -> alive edge here so
	-- stale DEAD assignments and pre-death order deduplication can never strand
	-- a bot at the base.
	for _, playerID in ipairs(XHSBotPlayerRegistry:GetXHSBotPlayerIDs()) do
		local record = XHSBotPlayerRegistry:GetBot(playerID)
		self:RunSafely("respawn:" .. tostring(playerID), function()
			local wasAlive = record ~= nil and record.alive
			local hero = XHSBotPlayerRegistry:GetBotHero(playerID)
			if record ~= nil and IsValidHero(hero) and hero:IsAlive()
				and record.hero_assigned == true and wasAlive == false then
				self:ResetBotAfterRespawn(playerID, hero, record, "thinker_edge")
			end
		end, record, nil)
	end
	self:RunSafely("team_director", function()
		XHSBotTeamDirector:Update(false)
	end, nil, nil)
	local difficulty = XHSBotConfig:GetDifficulty(self.configuration.difficulty)

	for _, playerID in ipairs(XHSBotPlayerRegistry:GetXHSBotPlayerIDs()) do
		local record = XHSBotPlayerRegistry:GetBot(playerID)
		self:RunSafely("bot:" .. tostring(playerID), function()
			self:ThinkBot(playerID, now, difficulty)
		end, record, nil)
	end

	if now >= self.next_roster_push then
		self.next_roster_push = now + 1
		self:RunSafely("nettable:roster", function()
			self:PushRoster()
		end, nil, nil)
	end
	if now >= self.next_debug_push then
		self.next_debug_push = now + 0.5
		self:RunSafely("nettable:debug", function()
			self:PushDebugState()
		end, nil, nil)
	end
	self:RecordThinkCost(thinkStartedAt)
	return 0.08
end

function XHSBots:SerializeVector(position)
	if position == nil then return nil end
	return {
		x = math.floor(position.x),
		y = math.floor(position.y),
		z = math.floor(position.z or 0),
	}
end

function XHSBots:PushDebugState()
	if not self.enabled or CustomNetTables == nil then return end
	for _, playerID in ipairs(XHSBotPlayerRegistry:GetXHSBotPlayerIDs()) do
		local record = XHSBotPlayerRegistry:GetBot(playerID)
		local assignment = XHSBotTeamDirector:GetAssignment(playerID)
		local target = SafeEntityFromIndex(record.target_entindex)
		CustomNetTables:SetTableValue("xhs_bots", "debug_" .. tostring(playerID), {
			player_id = playerID,
			hero = record.hero_name or record.requested_hero or "",
			difficulty = record.difficulty or self.configuration.difficulty,
			role = record.role or "",
			state = record.state or "INITIALIZING",
			macro_state = record.macro_state or "",
			goal = record.goal or "",
			label = assignment and assignment.label or "",
			lane = record.lane or 0,
			physical_lanes = record.physical_lanes or {},
			participant_player_id = record.participant_player_id or -1,
			side = record.side or "",
			event = assignment and assignment.event or "",
			urgency = assignment and math.floor((assignment.urgency or 0) * 100) / 100 or 0,
			base_threat_score = math.floor((record.base_threat_score or 0) * 100) / 100,
			base_threat_active = record.base_threat_active and 1 or 0,
			base_threat_count = record.base_threat_count or 0,
			base_special_count = record.base_special_count or 0,
			base_dragon_count = record.base_dragon_count or 0,
			base_approaching_count = record.base_approaching_count or 0,
			follow_human_player_id = assignment and assignment.follow_human_player_id or -1,
			target = GetDebugEntityName(target),
			target_entindex = record.target_entindex or -1,
			anchor = assignment and self:SerializeVector(assignment.anchor) or nil,
			last_seen_position = self:SerializeVector(record.last_seen_position),
			top_actions = record.top_actions or {},
			last_decision = record.last_decision or "",
			last_decision_reason = record.last_decision_reason or "",
			last_order = record.last_order or "",
			last_ability = record.last_ability or "",
			last_ability_reason = record.last_ability_reason or "",
			last_rejected_action = record.last_rejected_action or "",
			idle_seconds = math.floor((record.idle_seconds or 0) * 10) / 10,
			orders = record.orders or 0,
			orders_per_second = XHSBotExecutor:GetOrdersPerSecond(record, GameRules:GetGameTime()),
			max_orders_per_second = record.max_orders_per_second_observed or 0,
			rejected_orders = record.rejected_orders or 0,
			rate_limited_orders = record.rate_limited_orders or 0,
			casts_considered = record.casts_considered or 0,
			casts_issued = record.casts_issued or 0,
			casts_rejected = record.casts_rejected or 0,
			humanized_cast_skips = record.humanized_cast_skips or 0,
			target_changes = record.target_changes or 0,
			assignment_changes = record.assignment_changes or 0,
			stuck_recoveries = record.stuck_recoveries or 0,
			danger_hits = record.danger_hits or 0,
			danger_damage = record.danger_damage or 0,
			danger_exposure_seconds = math.floor((record.danger_exposure_seconds or 0) * 10) / 10,
			combat_threat = math.floor((record.combat_threat or 0) * 100) / 100,
			recent_damage_ratio = math.floor((record.recent_damage_ratio or 0) * 1000) / 1000,
			physical_threat = math.floor((record.physical_threat or 0) * 100) / 100,
			magical_threat = math.floor((record.magical_threat or 0) * 100) / 100,
			pure_threat = math.floor((record.pure_threat or 0) * 100) / 100,
			close_enemy_count = record.close_enemy_count or 0,
			focused_by_count = record.focused_by_count or 0,
			nearby_screen_count = record.nearby_screen_count or 0,
			controlled_unit_count = record.controlled_unit_count or 0,
			controlled_unit_orders = record.controlled_unit_orders or 0,
			last_controlled_unit_order = record.last_controlled_unit_order or "",
			darkness_orb_active = record.darkness_orb_active and 1 or 0,
			darkness_policy_state = record.darkness_policy_state or "",
			darkness_threat_state = record.darkness_threat_state or "",
			darkness_power_ready = record.darkness_power_ready and 1 or 0,
			darkness_low_threat_seconds = record.darkness_low_threat_seconds or 0,
			darkness_high_threat_seconds = record.darkness_high_threat_seconds or 0,
			darkness_toggle_count = record.darkness_toggle_count or 0,
			orb_owned_family_count = record.orb_owned_family_count or 0,
			orb_active_family_count = record.orb_active_family_count or 0,
			orb_repair_pending_count = record.orb_repair_pending_count or 0,
			orb_toggle_repair_count = record.orb_toggle_repair_count or 0,
			respawns = record.respawns or 0,
			last_lifecycle_event = record.last_lifecycle_event or "",
			tomes_bought = record.tomes_bought or 0,
			items_purchased = record.items_purchased or 0,
			item_gold_spent = record.item_gold_spent or 0,
			items_replaced = record.items_replaced or 0,
			last_replaced_item = record.last_replaced_item or "",
			replacement_gold_recovered = record.replacement_gold_recovered or 0,
			replacement_restore_failures = record.replacement_restore_failures or 0,
			replacement_required = record.replacement_required == true and 1 or 0,
			economy_phase = record.economy_phase or "",
			economy_reserve_gold = record.economy_reserve_gold or 0,
			planned_item = record.planned_item or "",
			planned_item_family = record.planned_item_family or "",
			planned_item_score = record.planned_item_score or 0,
			planned_item_reason = record.planned_item_reason or "",
			planned_loadout = record.planned_loadout or {},
			planned_loadout_scores = record.planned_loadout_scores or {},
			item_candidates = record.item_candidates or {},
			allied_family_counts = record.allied_family_counts or {},
			economy_plan_switches = record.economy_plan_switches or 0,
			economy_plan_hysteresis_holds =
				record.economy_plan_hysteresis_holds or 0,
			stash_item_count = record.stash_item_count or 0,
			active_item_slots = record.active_item_slots or 0,
			inventory_item_slots = record.inventory_item_slots or 0,
			inventory_swaps = record.inventory_swaps or 0,
			stash_items_collected = record.stash_items_collected or 0,
			ankh_charges = record.ankh_charges or 0,
			ankh_target = record.ankh_target or 0,
			health_potion_charges = record.health_potion_charges or 0,
			health_potion_target = record.health_potion_target or 0,
			mana_potion_charges = record.mana_potion_charges or 0,
			mana_potion_target = record.mana_potion_target or 0,
			tome_allowance = record.tome_allowance or 0,
			last_death_duration = record.last_death_duration or 0,
			has_owned_furbolg = record.has_owned_furbolg == true,
			consumables_used = record.consumables_used or 0,
			potions_deferred_for_heal = record.potions_deferred_for_heal or 0,
			preferred_heal_spell = record.preferred_heal_spell or "",
			inventory_full_events = record.inventory_full_events or 0,
			last_item_action = record.last_item_action or "",
			last_item_rejection = record.last_item_rejection or "",
			last_item_shop_correction = record.last_item_shop_correction or "",
			last_purchase_item = record.last_purchase_item or "",
			last_purchase_shop = record.last_purchase_shop or "",
			last_purchase_shop_kind = record.last_purchase_shop_kind or "",
			last_purchase_shop_distance = record.last_purchase_shop_distance or -1,
			last_purchase_at = record.last_purchase_at or 0,
			shop_purchase_counts = record.shop_purchase_counts or {},
			shop_purchase_violation_count =
				record.shop_purchase_violation_count or 0,
			shopping_item = type(record.shopping_goal) == "table"
				and record.shopping_goal.item or "",
			shopping_shop = type(record.shopping_goal) == "table"
				and record.shopping_goal.shop or "",
			shopping_urgent = type(record.shopping_goal) == "table"
				and record.shopping_goal.urgent == true and 1 or 0,
			shopping_reason = type(record.shopping_goal) == "table"
				and record.shopping_goal.reason or "",
			emergency_health_resupply_active =
				record.emergency_health_resupply_active == true and 1 or 0,
			emergency_health_resupply_count =
				record.emergency_health_resupply_count or 0,
			emergency_health_resupply_reason =
				record.emergency_health_resupply_reason or "",
			health_potion_active_charges =
				record.health_potion_active_charges or 0,
			health_potion_carried_charges =
				record.health_potion_carried_charges or 0,
			health_potion_total_charges =
				record.health_potion_total_charges or 0,
			encounter_mode = record.encounter_mode or "",
			encounter_transitions = record.encounter_transitions or 0,
			decision_cost_average_ms = math.floor((record.decision_cost_average_ms or 0) * 1000) / 1000,
			decision_cost_max_ms = math.floor((record.decision_cost_max_ms or 0) * 1000) / 1000,
			think_cost_average_ms = math.floor((self.think_cost_average_ms or 0) * 1000) / 1000,
			think_cost_max_ms = math.floor((self.think_cost_max_ms or 0) * 1000) / 1000,
			safe_error_count = record.safe_error_count or 0,
			safe_error_consecutive = record.safe_error_consecutive or 0,
			safe_last_error_scope = record.safe_last_error_scope or "",
			safe_last_error = record.safe_last_error or "",
			engine_fake_client = record.engine_fake_client and 1 or 0,
			engine_team_verified = record.engine_team_verified and 1 or 0,
			connection_state = record.engine_connection_state or -1,
			error = record.error or "",
		})

		if self.overlay_enabled and IsValidHero(XHSBotPlayerRegistry:GetBotHero(playerID))
			and DebugDrawText ~= nil then
			local hero = XHSBotPlayerRegistry:GetBotHero(playerID)
			local top = record.top_actions and record.top_actions[1] or nil
			local overlay = string.format(
				"%s | %s | TARGET: %s%s",
				string.upper(record.difficulty or self.configuration.difficulty or "normal"),
				assignment and assignment.label or record.macro_state or "THINKING",
				IsValidUnit(target) and target:GetUnitName() or "none",
				top and (" | " .. tostring(top.id) .. "=" .. tostring(top.score)) or ""
			)
			DebugDrawText(hero:GetAbsOrigin() + Vector(0, 0, 180), overlay, false, 0.6)
		end
	end
end

function XHSBots:ForceGoal(playerID, goal)
	if not self.enabled then return false, "Bots are disabled" end
	playerID = tonumber(playerID)
	local record = XHSBotPlayerRegistry:GetBot(playerID)
	if record == nil then return false, "Unknown XHS bot player id" end

	goal = tostring(goal or "auto")
	local allowed = {
		auto = true,
		defend_base = true,
		regroup = true,
		fight_boss = true,
		hold = true,
	}
	if not allowed[goal] then return false, "Unsupported forced goal" end
	record.forced_goal = goal == "auto" and nil or goal
	XHSBotTeamDirector.assignments[playerID] = nil
	XHSBotTeamDirector:Update(true)
	return true, goal == "auto" and "Automatic goal restored" or ("Forced goal: " .. goal)
end

function XHSBots:RunScenario(name)
	if not self.enabled then return false, "Bots are disabled" end
	name = tostring(name or "danger")
	if name == "danger" then
		local count = 0
		for _, playerID in ipairs(XHSBotPlayerRegistry:GetXHSBotPlayerIDs()) do
			local hero = XHSBotPlayerRegistry:GetBotHero(playerID)
			if IsValidHero(hero) and hero:IsAlive() then
				XHSBotDangerRegistry:AddCircle(hero:GetAbsOrigin(), 325, 1.2, {
					severity = 1,
					label = "devtools_danger_scenario",
				})
				count = count + 1
			end
		end
		return true, "Danger scenario registered for " .. tostring(count) .. " bot(s)"
	elseif name == "reassign" then
		XHSBotTeamDirector:Reset()
		XHSBotTeamDirector:Update(true)
		return true, "Team assignments rebuilt"
	elseif name == "stuck" then
		for _, playerID in ipairs(XHSBotPlayerRegistry:GetXHSBotPlayerIDs()) do
			local record = XHSBotPlayerRegistry:GetBot(playerID)
			local hero = XHSBotPlayerRegistry:GetBotHero(playerID)
			if record ~= nil and IsValidHero(hero) then
				record.stuck_sample_position = hero:GetAbsOrigin()
				record.stuck_sample_at = GameRules:GetGameTime() - 2
			end
		end
		return true, "Stuck-recovery samples armed"
	elseif name == "respawn" then
		local ids = XHSBotPlayerRegistry:GetXHSBotPlayerIDs()
		local hero = ids[1] and XHSBotPlayerRegistry:GetBotHero(ids[1]) or nil
		if IsValidHero(hero) and hero:IsAlive() then
			hero:ForceKill(false)
			return true, "Killed first bot to exercise respawn/rebind"
		end
		return false, "No living bot available"
	elseif name == "economy" then
		if GameRules == nil
			or GameRules:State_Get() ~= DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
			return false, "Game is not in progress"
		end
		local funded = 0
		local fundedPlayerIDs = {}
		local targetGold = 120000
		for _, playerID in ipairs(XHSBotPlayerRegistry:GetXHSBotPlayerIDs()) do
			local record = XHSBotPlayerRegistry:GetBot(playerID)
			local hero = XHSBotPlayerRegistry:GetBotHero(playerID)
			if record ~= nil and IsValidHero(hero) and hero:IsAlive() then
				local currentGold = XHSBotEconomy:GetGold(playerID)
				local walletReady = currentGold >= targetGold
				if not walletReady then
					walletReady =
						XHSBotEconomy:SetSynchronizedGold(playerID, targetGold)
					if walletReady then
						record.qa_economy_gold_injected =
							(record.qa_economy_gold_injected or 0)
							+ (targetGold - currentGold)
					end
				end
				if walletReady then
					record.item_retry_after = {}
					record.next_economy_think = 0
					funded = funded + 1
					table.insert(fundedPlayerIDs, playerID)
				end
			end
		end
		local auditStarted = false
		local auditWatchStarted = false
		if funded > 0 then
			auditStarted = self:StartEconomyAudit(fundedPlayerIDs)
			if auditStarted then
				auditWatchStarted = self:StartEconomyAuditWatch()
			end
		end
		return funded > 0,
			"Economy planner funded for " .. tostring(funded) .. " bot(s)"
				.. (auditStarted and "; audit baseline started" or "")
				.. (auditWatchStarted and "; terminal watcher started" or "")
	end
	return false, "Unknown bot scenario"
end

function XHSBots:SetPaused(paused)
	if not self.enabled then return false end
	self.paused = paused == true
	return true
end

function XHSBots:SetOverlayEnabled(enabled)
	if not self.enabled then return false end
	self.overlay_enabled = enabled == true
	return true
end

function XHSBots:Stop()
	self.hero_selection_retry_running = false
	self.thinker_running = false
	self.paused = true
	self:StopEconomyAuditWatch(true)
	XHSBotDangerRegistry:SetEnabled(false)
	if GameRules ~= nil and GameRules.GetGameModeEntity ~= nil then
		GameRules:GetGameModeEntity():SetContextThink("xhs_allied_bots_think", nil, 0)
	end
end

function XHSBots:ResetForTools()
	if not self.enabled then return false end
	self:Stop()
	self.qa_economy_audit = nil
	XHSBotTeamDirector:Reset()
	XHSBotDangerRegistry:Clear()
	for _, playerID in ipairs(XHSBotPlayerRegistry:GetXHSBotPlayerIDs()) do
		local record = XHSBotPlayerRegistry:GetBot(playerID)
		local hero = XHSBotPlayerRegistry:GetBotHero(playerID)
		if IsValidHero(hero) then hero:Stop() end
		if record ~= nil then
			record.pending_decision = nil
			record.pending_decision_signature = nil
			record.pending_decision_at = nil
			record.target_entindex = nil
			record.target_score = nil
			record.target_committed_until = nil
			record.last_seen_position = nil
			record.last_seen_at = nil
			record.last_seen_until = nil
			record.stuck_sample_position = nil
			record.stuck_sample_at = nil
			record.stuck_since = nil
			record.combo_target_entindex = nil
			record.combo_until = nil
			record.order_timestamps = {}
			record.last_order_signature = nil
			record.next_order_at = 0
			record.ability_consider_after = {}
			record.ability_rejection_after = {}
			record.respond_to_current_danger = nil
			record.next_danger_response_choice = 0
			record.was_in_active_danger = false
			record.telemetry_last_health = IsValidHero(hero) and hero:GetHealth() or nil
			record.next_attack_move_choice = 0
			record.use_attack_move = nil
			record.state = IsValidHero(hero) and "INITIALIZING" or "SELECTING_HERO"
			record.macro_state = record.state
			-- An engine purchase order may still be resolving asynchronously;
			-- keep pending_item_purchase so the economy can verify it exactly once.
		end
	end
	self.paused = false
	return true
end

return XHSBots
