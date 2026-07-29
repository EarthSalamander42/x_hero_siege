if XHSDevTools == nil then
	_G.XHSDevTools = class({})
end

require("components/devtools/lag_lab")

local QUEST_ORDER = {
	"defend_castle",
	"kill_rax",
	"kill_dest_mag",
	"kill_ice_towers",
	"kill_final_wave",
	"teleport_top",
	"kill_mag",
	"kill_grom",
	"kill_illidan",
	"kill_balanar",
	"kill_proudmoore",
	"teleport_arthas",
	"kill_arthas",
	"kill_banehallow",
	"kill_lich_king",
	"kill_spirit_master",
}

local QUEST_LABELS = {
	defend_castle = "Defend Castle",
	kill_rax = "Kill Barracks",
	kill_dest_mag = "Destroyer Magnataurs",
	kill_ice_towers = "Ice Towers",
	kill_final_wave = "Final Wave",
	teleport_top = "Teleport Top",
	kill_mag = "Magtheridon",
	kill_grom = "Grom",
	kill_illidan = "Illidan",
	kill_balanar = "Balanar",
	kill_proudmoore = "Proudmoore",
	teleport_arthas = "Teleport Arthas",
	kill_arthas = "Arthas",
	kill_banehallow = "Banehallow",
	kill_lich_king = "Lich King",
	kill_spirit_master = "Spirit Master",
}

local DIRECT_BOSSES = {
	grom = { quest = "kill_grom", unit = "npc_dota_hero_grom_hellscream", spawner = "spawn_grom_hellscream", yaw = 270 },
	illidan = { quest = "kill_illidan", unit = "npc_dota_hero_illidan", spawner = "spawn_illidan", yaw = 0 },
	balanar = { quest = "kill_balanar", unit = "npc_dota_hero_balanar", spawner = "spawn_balanar", yaw = 90 },
	proudmoore = { quest = "kill_proudmoore", unit = "npc_dota_hero_proudmoore", spawner = "spawn_admiral_proudmore", yaw = 180 },
}

local BOSS_UNIT_TO_DEV_ID = {
	npc_dota_hero_magtheridon = "magtheridon",
	npc_dota_hero_grom_hellscream = "grom",
	npc_dota_hero_illidan = "illidan",
	npc_dota_hero_balanar = "balanar",
	npc_dota_hero_proudmoore = "proudmoore",
	npc_dota_hero_arthas = "arthas",
	npc_dota_hero_banehallow = "banehallow",
	npc_dota_boss_lich_king = "lich_king",
	npc_dota_boss_spirit_master = "spirit_master",
	npc_dota_boss_spirit_master_fire = "spirit_master",
	npc_dota_boss_spirit_master_storm = "spirit_master",
	npc_dota_boss_spirit_master_earth = "spirit_master",
}

local DIFFICULTY_LABELS = { "Easy", "Normal", "Hard", "Extreme", "Divine" }

local BATTLEPASS_DEV_FAMILY_ORDER = {
	"teleport",
	"levelup",
	"kill_effect",
	"emblem",
	"companion",
	"effigy",
	"potion",
	"rebirth",
	"attack_lifesteal",
	"spell_lifesteal",
	"regen_aura",
	"immolation",
	"high_five",
}

local BATTLEPASS_DEV_FAMILY_LABELS = {
	teleport = "Teleport",
	levelup = "Level Up",
	kill_effect = "Kill Effect",
	emblem = "Emblem",
	companion = "Companion",
	effigy = "Effigy",
	potion = "Potion",
	rebirth = "Rebirth",
	attack_lifesteal = "Attack Lifesteal",
	spell_lifesteal = "Spell Lifesteal",
	regen_aura = "Regen Aura",
	immolation = "Immolation",
	high_five = "High Five",
}

local BATTLEPASS_DEV_FAMILY_SET = {}
for _, family in ipairs(BATTLEPASS_DEV_FAMILY_ORDER) do
	BATTLEPASS_DEV_FAMILY_SET[family] = true
end

local BATTLEPASS_DEV_SEQUENCE_DELAY = 5.0

local function FormatBattlepassDevRewardName(name, family)
	local value = tostring(name or "")
	value = string.gsub(value, "^#", "")
	value = string.gsub(value, "^sp26_", "")
	value = string.gsub(value, "^" .. tostring(family or "") .. "_", "")
	value = string.gsub(value, "_", " ")
	return value ~= "" and value or tostring(name or "Unknown")
end

local BOSS_UNIT_NAMES = {
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

local function IsTruthy(value)
	return value == true or value == 1 or value == "1" or value == "true"
end

local function ToNumber(value, fallback)
	local number = tonumber(value)
	if number == nil then
		return fallback
	end
	return number
end

local PERFORMANCE_UPDATE_INTERVAL = 1.0
local CLIENT_FPS_TIMEOUT = 5.0
local PERFORMANCE_BREAKABLES = {
	npc_dota_crate = true,
	npc_dota_chest = true,
	npc_dota_vase = true,
}

local function IsPerformanceDummy(unit, unitName)
	return unit.is_fake_hero == true
		or string.find(unitName or "", "dummy", 1, true) ~= nil
end

function XHSDevTools:ResolveEventPlayerID(sourceIndex)
	local playerID = nil
	if CustomGameEventManager ~= nil
		and CustomGameEventManager.GetPlayerIDFromEventSourceIndex ~= nil then
		local ok, resolvedPlayerID = pcall(function()
			return CustomGameEventManager:GetPlayerIDFromEventSourceIndex(sourceIndex)
		end)
		if ok then
			playerID = tonumber(resolvedPlayerID)
		end
	end

	if playerID == nil or not PlayerResource:IsValidPlayerID(playerID) then
		local numericSourceIndex = tonumber(sourceIndex)
		if numericSourceIndex ~= nil and numericSourceIndex > 0 then
			local ok, resolvedPlayerID = pcall(function()
				local sender = EntIndexToHScript(numericSourceIndex)
				return sender ~= nil and sender.GetPlayerID ~= nil and sender:GetPlayerID() or nil
			end)
			if ok then
				playerID = tonumber(resolvedPlayerID)
			end
		end
	end

	if playerID == nil or not PlayerResource:IsValidPlayerID(playerID) then return nil end
	if PlayerResource.IsFakeClient ~= nil and PlayerResource:IsFakeClient(playerID) then return nil end
	return playerID
end

function XHSDevTools:IsPerformanceViewer(playerID)
	if IsInToolsMode() then return true end
	if playerID == nil
		or PlayerResource == nil
		or not PlayerResource:IsValidPlayerID(playerID)
		or PlayerResource.IsFakeClient ~= nil and PlayerResource:IsFakeClient(playerID)
		or api == nil
		or api.GetDonatorStatus == nil then
		return false
	end

	local status = tonumber(api:GetDonatorStatus(playerID)) or 0
	return status == 1 or status == 2
end

function XHSDevTools:HasPerformanceViewer()
	if IsInToolsMode() then return true end
	local maxPlayers = DOTA_MAX_TEAM_PLAYERS or 24
	for playerID = 0, maxPlayers - 1 do
		if self:IsPerformanceViewer(playerID) then
			return true
		end
	end
	return false
end

function XHSDevTools:OnClientFPS(sourceIndex, event)
	if not self:HasPerformanceViewer() then return end

	local playerID = self:ResolveEventPlayerID(sourceIndex)
	local fps = event and tonumber(event.fps) or nil
	if playerID == nil
		or fps == nil
		or fps ~= fps then
		return
	end

	self.client_fps = self.client_fps or {}
	self.client_fps[playerID] = {
		fps = math.max(0, math.min(500, fps)),
		updated_at = Time ~= nil and Time() or GameRules:GetGameTime(),
	}
end

function XHSDevTools:RegisterPerformanceListeners()
	if self.client_fps_listener_registered == true then return end
	if CustomGameEventManager == nil then return end

	self.client_fps_listener_registered = true
	CustomGameEventManager:RegisterListener("xhs_devtools_client_fps", function(sourceIndex, event)
		return XHSDevTools:OnClientFPS(sourceIndex, event)
	end)
end

function XHSDevTools:BuildClientFPSState()
	local players = {}
	local now = Time ~= nil and Time() or GameRules:GetGameTime()
	local maxPlayers = DOTA_MAX_TEAM_PLAYERS or 24

	for playerID = 0, maxPlayers - 1 do
		local isValid = PlayerResource:IsValidPlayerID(playerID)
		local isHuman = isValid
			and (PlayerResource.IsFakeClient == nil or not PlayerResource:IsFakeClient(playerID))
		local player = isHuman and PlayerResource:GetPlayer(playerID) or nil
		local hasPlayerHandle = player ~= nil
			and (player.IsNull == nil or not player:IsNull())
		local isPresent = isHuman and (
			hasPlayerHandle
			or PlayerResource:GetConnectionState(playerID) == DOTA_CONNECTION_STATE_CONNECTED
		)

		if isPresent then
			local record = self.client_fps and self.client_fps[playerID] or nil
			local isFresh = record ~= nil
				and now - (tonumber(record.updated_at) or -999) <= CLIENT_FPS_TIMEOUT
			players[tostring(playerID)] = {
				player_id = playerID,
				name = PlayerResource:GetPlayerName(playerID) or ("Player " .. tostring(playerID + 1)),
				fps = isFresh and math.floor((tonumber(record.fps) or 0) + 0.5) or -1,
			}
		end
	end

	return players
end

function XHSDevTools:BuildPerformanceState()
	local startedAt = Time ~= nil and Time() or 0
	local snapshot = {
		creeps = 0,
		total_units = 0,
		ai_controllers = 0,
		wave_controllers = 0,
		ability_controllers = 0,
		heroes = 0,
		bosses = 0,
		summons = 0,
		breakables = 0,
		other_units = 0,
		thinkers = 0,
		frame_ms = math.max(0, FrameTime() * 1000 / math.max(0.01, self.host_timescale or 1)),
		scan_ms = 0,
		players = self:BuildClientFPSState(),
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
			local isDummy = IsPerformanceDummy(unit, unitName)
			local isRune = IsXHSRuneUnit ~= nil and IsXHSRuneUnit(unit)

			snapshot.total_units = snapshot.total_units + 1
			if unit:HasModifier("modifier_ai") then
				snapshot.ai_controllers = snapshot.ai_controllers + 1
			end
			if unit.xhs_wave_order_controller == true then
				snapshot.wave_controllers = snapshot.wave_controllers + 1
			end
			if isDummy or isRune then
				snapshot.other_units = snapshot.other_units + 1
			elseif BOSS_UNIT_NAMES[unitName] == true or unit.Boss == true then
				snapshot.bosses = snapshot.bosses + 1
			elseif unit:IsRealHero() and not unit:IsIllusion() then
				snapshot.heroes = snapshot.heroes + 1
			elseif PERFORMANCE_BREAKABLES[unitName] == true then
				snapshot.breakables = snapshot.breakables + 1
			elseif unit.IsSummoned ~= nil and unit:IsSummoned() then
				snapshot.summons = snapshot.summons + 1
			elseif unit:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS
				and ((unit.IsCreep ~= nil and unit:IsCreep()) or (unit.IsCreature ~= nil and unit:IsCreature())) then
				snapshot.creeps = snapshot.creeps + 1
			else
				snapshot.other_units = snapshot.other_units + 1
			end
		end
	end

	local thinkers = Entities:FindAllByClassname("npc_dota_thinker")
	snapshot.thinkers = thinkers and #thinkers or 0
	local directorState = XHSCreepAIDirector ~= nil
		and XHSCreepAIDirector.GetState ~= nil
		and XHSCreepAIDirector:GetState()
		or {}
	snapshot.ai_director = directorState
	snapshot.ability_controllers = tonumber(directorState.active_ability_agents) or 0
	snapshot.activity = XHSPerformanceCounters ~= nil
		and XHSPerformanceCounters.GetSnapshot ~= nil
		and XHSPerformanceCounters:GetSnapshot()
		or {}
	snapshot.ai_ticks_per_second =
		tonumber(snapshot.activity.ai_thinks_per_second) or 0
	snapshot.wave_checks_per_second =
		tonumber(snapshot.activity.wave_thinks_per_second) or 0
	snapshot.ability_checks_per_second =
		tonumber(snapshot.activity.ability_loop_thinks_per_second) or 0

	if Time ~= nil then
		snapshot.scan_ms = math.max(0, (Time() - startedAt) * 1000)
	end

	return snapshot
end

function XHSDevTools:PublishPerformanceState()
	if CustomNetTables == nil or not self:HasPerformanceViewer() then return end
	CustomNetTables:SetTableValue("xhs_devtools", "performance", self:BuildPerformanceState())
end

function XHSDevTools:StartPerformanceMonitor()
	if self.performance_monitor_started == true then return end

	self.performance_monitor_started = true
	self.next_performance_update_at = 0
	GameRules:GetGameModeEntity():SetContextThink("XHSDevToolsPerformanceMonitor", function()
		if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
			self.performance_monitor_started = false
			return nil
		end

		local now = Time ~= nil and Time() or GameRules:GetGameTime()
		if now >= (self.next_performance_update_at or 0) then
			self.next_performance_update_at = now + PERFORMANCE_UPDATE_INTERVAL
			self:PublishPerformanceState()
		end
		return 0.1
	end, 0.1)
end

function XHSDevTools:Init()
	self.enabled = IsInToolsMode()
	self.client_fps = self.client_fps or {}
	self:RegisterPerformanceListeners()
	XHSLagLab:Init()

	if self.initialized == true then
		self:StartPerformanceMonitor()
		self:PushState()
		return
	end

	self.initialized = true
	self.sandbox_active = false
	self.spawned_units = {}
	self.invulnerable_players = false
	self.campaign_flow_active = false
	self.host_timescale = Convars ~= nil and Convars:GetFloat("host_timescale") or 1
	self.last_result = {
		action = "",
		ok = true,
		message = self.enabled and "Dev tools ready" or "Dev tools disabled: launch from Workshop Tools mode",
	}
	print("[XHSDevTools] Init enabled=" .. tostring(self.enabled))

	CustomGameEventManager:RegisterListener("xhs_devtools_request_state", function(...)
		return XHSDevTools:OnRequestState(...)
	end)

	CustomGameEventManager:RegisterListener("xhs_devtools_run_action", function(...)
		return XHSDevTools:OnRunAction(...)
	end)

	self:StartPerformanceMonitor()
	self:PushState()
end

function XHSDevTools:IsSandboxActive()
	return self.enabled == true and self.sandbox_active == true
end

function XHSDevTools:ActivateSandbox(reason)
	self:SetSandboxActive(true, reason or "dev action")
end

function XHSDevTools:SetSandboxActive(enabled, reason)
	self.sandbox_active = enabled == true
	self.sandbox_reason = self.sandbox_active and (reason or "manual toggle") or nil
	self.campaign_flow_active = false

	if CustomTimers ~= nil then
		CustomTimers.special_waves_disabled = self.sandbox_active
		CustomTimers.enable_special_wave = false
		CustomTimers.timers_paused = self.sandbox_active and 2 or 0
		if self.sandbox_active and CustomTimers.HideSpecialWaveCountdown ~= nil then
			CustomTimers:HideSpecialWaveCountdown()
		end
		if CustomTimers.BroadcastTimer ~= nil then
			CustomTimers:BroadcastTimer("special_wave")
			CustomTimers:BroadcastTimer("special_event")
		end
	end

	if self.sandbox_active and KillCreeps ~= nil then
		KillCreeps(DOTA_TEAM_CUSTOM_1)
	end
end

function XHSDevTools:SetResult(action, ok, message)
	self.last_result = {
		action = action or "",
		ok = ok == true,
		message = message or "",
	}
	self:PushState()
end

function XHSDevTools:OnRequestState()
	self:PushState()
end

function XHSDevTools:OnRunAction(sourceIndex, event)
	event = event or {}
	event.xhs_devtools_source_index = sourceIndex

	local action = event.action or ""
	if not IsInToolsMode() then
		self:SetResult(action, false, "Dev tools actions require Workshop Tools mode")
		return
	end

	local ok, message = pcall(function()
		return self:RunAction(action, event)
	end)

	if ok then
		self:SetResult(action, true, message or "Done")
	else
		self:SetResult(action, false, tostring(message))
	end
end

function XHSDevTools:RunAction(action, event)
	if action == "activate_quest" then
		local quest_name = event.quest
		self:ActivateSandbox("quest")
		return self:ActivateQuestByName(quest_name)
	elseif action == "complete_quest" then
		local quest_name = event.quest
		self:ActivateSandbox("quest")
		return self:CompleteQuestByName(quest_name)
	elseif action == "start_boss" then
		self:ActivateSandbox("boss")
		return self:StartBoss(event.boss)
	elseif action == "start_boss_flow" then
		return self:StartCampaignFlow(event.boss)
	elseif action == "set_sandbox" then
		local enabled = IsTruthy(event.enabled)
		self:SetSandboxActive(enabled, "manual toggle")
		return enabled and "Sandbox enabled" or "Sandbox disabled"
	elseif action == "set_timescale" then
		local requested = ToNumber(event.timescale, 1)
		local canonicalTimescales = { 0.1, 0.3, 1, 3, 5 }
		local canonicalRequested = nil
		for _, value in ipairs(canonicalTimescales) do
			if math.abs(requested - value) < 0.001 then
				canonicalRequested = value
				break
			end
		end
		if canonicalRequested == nil then
			error("Unsupported host_timescale value")
		end
		requested = canonicalRequested

		self.host_timescale = requested
		SendToServerConsole("host_timescale " .. tostring(requested))
		return "host_timescale " .. tostring(requested)
	elseif action == "start_final_wave" then
		self:ActivateSandbox("final_wave")
		if FinalWave then
			FinalWave(true)
			return "Final Wave started in sandbox"
		end
		return "FinalWave() is unavailable"
	elseif action == "set_lane" then
		return self:SetLane(event)
	elseif action == "spawn_lane_wave" then
		return self:SpawnLaneWave(ToNumber(event.lane, 0))
	elseif action == "spawn_phase2_wave" then
		return self:SpawnPhase2Wave(event.side)
	elseif action == "start_phase2" then
		return self:StartPhase2()
	elseif action == "special_wave" then
		self:ActivateSandbox("special_wave")
		local wave = ToNumber(event.wave, CustomTimers and CustomTimers.special_wave or 1)
		if CustomTimers then
			CustomTimers.special_wave = math.max(1, math.min(8, wave))
		end
		SpecialWave(math.max(1, math.min(8, wave)), true)
		return "Special wave " .. tostring(wave) .. " triggered"
	elseif action == "pause_timers" then
		if CustomTimers then CustomTimers.timers_paused = 2 end
		return "Timers paused"
	elseif action == "resume_timers" then
		if CustomTimers then CustomTimers.timers_paused = 0 end
		return "Timers resumed"
	elseif action == "set_phase" then
		return self:SetPhase(ToNumber(event.phase, 1))
	elseif action == "set_difficulty" then
		return self:SetDifficulty(ToNumber(event.difficulty, GameRules:GetCustomGameDifficulty() or 1), IsTruthy(event.respawn_bosses))
	elseif action == "trigger_event" then
		self:ActivateSandbox("event")
		return self:TriggerEvent(event.event)
	elseif action == "refresh_players" then
		if RefreshPlayers then RefreshPlayers() end
		return "Players refreshed"
	elseif action == "max_level" then
		return self:MaxLevelHeroes()
	elseif action == "grant_gold" then
		return self:GrantGold(ToNumber(event.amount, 50000))
	elseif action == "grant_tomes" then
		if GiveTomeToAllHeroes then
			GiveTomeToAllHeroes(ToNumber(event.amount, 250))
		end
		return "Tomes granted"
	elseif action == "toggle_invulnerable" then
		return self:ToggleInvulnerable()
	elseif action == "set_temporary_donator_status" then
		return self:SetTemporaryDonatorStatus(event)
	elseif action == "preview_vip_dialog" then
		return self:PreviewVipDialog(event)
	elseif action == "close_vip_dialog_preview" then
		return self:CloseVipDialogPreview(event)
	elseif action == "preview_cinematic" then
		return self:PreviewCinematic(event)
	elseif action == "end_cinematic_preview" then
		return self:EndCinematicPreview(event)
	elseif action == "battlepass_test_reward" then
		return self:TestBattlepassReward(event)
	elseif action == "battlepass_test_family" then
		return self:TestBattlepassFamily(event)
	elseif action == "battlepass_stop_test" then
		return self:StopBattlepassTest(event)
	elseif action == "fragment_quests_reroll" then
		if FragmentQuests == nil then return "FragmentQuests is unavailable" end
		FragmentQuests:DevReroll()
		return "Fragment quests rerolled"
	elseif action == "fragment_quest_force" then
		if FragmentQuests == nil then return "FragmentQuests is unavailable" end
		local ok, message = FragmentQuests:ForceQuest(event.template_id, event.target_id, ToNumber(event.slot, 1))
		if ok ~= true then error(message or "Failed to force fragment quest") end
		return message or "Fragment quest forced"
	elseif action == "fragment_quest_progress" then
		if FragmentQuests == nil then return "FragmentQuests is unavailable" end
		FragmentQuests:DevAddProgress(event.metric, ToNumber(event.amount, 1))
		return "Fragment quest progress added"
	elseif action == "fragment_quest_backend_success" then
		if FragmentQuests == nil then return "FragmentQuests is unavailable" end
		FragmentQuests:DevSimulateBackend(true)
		return "Fragment quest backend success simulated"
	elseif action == "fragment_quest_backend_error" then
		if FragmentQuests == nil then return "FragmentQuests is unavailable" end
		FragmentQuests:DevSimulateBackend(false)
		return "Fragment quest backend error simulated"
	elseif action == "fragment_quest_dump_payload" then
		if FragmentQuests == nil then return "FragmentQuests is unavailable" end
		FragmentQuests:DevDumpPayload()
		return "Fragment quest analytics payload dumped to console"
	elseif action == "fragment_quest_complete_window" then
		if FragmentQuests == nil then return "FragmentQuests is unavailable" end
		if FragmentQuests:DevCompleteWindow(event.window, event.value) ~= true then
			error("Unknown fragment quest window")
		end
		return "Fragment quest window completed"
	elseif action == "bot_pause" then
		if XHSBots == nil then return "XHSBots is unavailable" end
		XHSBots:SetPaused(true)
		return "Bot AI paused"
	elseif action == "bot_resume" then
		if XHSBots == nil then return "XHSBots is unavailable" end
		XHSBots:SetPaused(false)
		XHSBots:StartThinker()
		return "Bot AI resumed"
	elseif action == "bot_overlay" then
		if XHSBots == nil then return "XHSBots is unavailable" end
		XHSBots:SetOverlayEnabled(IsTruthy(event.enabled))
		return IsTruthy(event.enabled) and "Bot overlay enabled" or "Bot overlay disabled"
	elseif action == "bot_force_goal" then
		if XHSBots == nil then return "XHSBots is unavailable" end
		local ok, result = XHSBots:ForceGoal(ToNumber(event.player_id, -1), event.goal)
		if not ok then error(result) end
		return result
	elseif action == "bot_reset" then
		if XHSBots == nil then return "XHSBots is unavailable" end
		XHSBots:ResetForTools()
		XHSBots:StartThinker()
		return "Bot AI state reset"
	elseif action == "bot_run_scenario" then
		if XHSBots == nil then return "XHSBots is unavailable" end
		local ok, result = XHSBots:RunScenario(event.scenario)
		if not ok then error(result) end
		return result
	elseif action == "lag_lab_ping" then
		if XHSLagLab == nil or XHSLagLab.Init == nil then
			error("Lag Lab server module is unavailable; reload scripts or start a new Tools match")
		end
		XHSLagLab:Init()
		return "Lag Lab server OK (" .. tostring(XHSLagLab.state and XHSLagLab.state.stage or "idle") .. ")"
	elseif action == "lag_lab_start" then
		if XHSLagLab == nil or XHSLagLab.Init == nil then
			error("Lag Lab server module is unavailable; reload scripts or start a new Tools match")
		end
		XHSLagLab:Init()
		return XHSLagLab:Start(
			tostring(event.experiment or ""),
			event.source,
			IsTruthy(event.keep_active)
		)
	elseif action == "lag_lab_restore" then
		if XHSLagLab == nil or XHSLagLab.Restore == nil then
			error("Lag Lab server module is unavailable; reload scripts or start a new Tools match")
		end
		return XHSLagLab:Restore("manual")
	elseif action == "cleanup" then
		XHSLagLab:Restore("cleanup")
		return self:Cleanup()
	elseif action == "reset_sandbox" then
		XHSLagLab:Restore("reset")
		self:Cleanup()
		self:SetSandboxActive(false)
		return "Sandbox reset"
	end

	return "Unknown dev action: " .. tostring(action)
end

function XHSDevTools:GetXHSZone()
	if GameMode == nil or GameMode.Zones == nil then return nil end

	for _, zone in pairs(GameMode.Zones) do
		if zone ~= nil and zone.szName == "xhs_holdout" then
			return zone
		end
	end

	return nil
end

function XHSDevTools:FindQuest(quest_name)
	local zone = self:GetXHSZone()
	if zone == nil or zone.Quests == nil then return nil, nil end

	for _, quest in pairs(zone.Quests) do
		if quest ~= nil and quest.szQuestName == quest_name then
			return zone, quest
		end
	end

	return nil, nil
end

function XHSDevTools:MarkPrerequisitesComplete(zone, target_quest)
	if zone == nil or target_quest == nil or zone.Quests == nil then return end

	local blockers = {}
	for _, activator in pairs(target_quest.Activators or {}) do
		if activator ~= nil and activator.szQuestName ~= nil then
			blockers[activator.szQuestName] = true
		end
	end

	local changed = true
	while changed do
		changed = false
		for _, quest in pairs(zone.Quests) do
			if quest ~= nil and blockers[quest.szQuestName] == true and quest.bCompleted ~= true then
				quest.bActivated = true
				quest.bCompleted = true
				quest.nCompleted = quest.nCompleteLimit or 1
				changed = true

				for _, activator in pairs(quest.Activators or {}) do
					if activator ~= nil and activator.szQuestName ~= nil then
						blockers[activator.szQuestName] = true
					end
				end
			end
		end
	end
end

function XHSDevTools:ActivateQuestByName(quest_name)
	local zone, quest = self:FindQuest(quest_name)
	if zone == nil or quest == nil then
		return "Quest not found: " .. tostring(quest_name)
	end

	self:MarkPrerequisitesComplete(zone, quest)

	if quest.bCompleted == true then
		quest.bCompleted = false
		quest.nCompleted = 0
	end

	if quest.bActivated ~= true then
		GameRules.GameMode:OnQuestStarted(zone, quest)
	else
		self:BroadcastQuestActivated(zone, quest)
	end

	return "Quest activated: " .. tostring(quest_name)
end

function XHSDevTools:CompleteQuestByName(quest_name)
	local zone, quest = self:FindQuest(quest_name)
	if zone == nil or quest == nil then
		return "Quest not found: " .. tostring(quest_name)
	end

	self:MarkPrerequisitesComplete(zone, quest)
	quest.bActivated = true
	quest.bCompleted = true
	quest.nCompleted = quest.nCompleteLimit or 1
	self:BroadcastQuestCompleted(zone, quest)

	return "Quest completed without follow-up: " .. tostring(quest_name)
end

function XHSDevTools:BroadcastQuestActivated(zone, quest)
	CustomGameEventManager:Send_ServerToAllClients("quest_activated", {
		ZoneName = zone.szName,
		QuestName = quest.szQuestName,
		QuestType = quest.szQuestType,
		Completed = quest.nCompleted or 0,
		CompleteLimit = quest.nCompleteLimit or 1,
		Optional = quest.bOptional,
	})
end

function XHSDevTools:BroadcastQuestCompleted(zone, quest)
	CustomGameEventManager:Send_ServerToAllClients("quest_completed", {
		ZoneName = zone.szName,
		QuestName = quest.szQuestName,
		QuestType = quest.szQuestType,
		Completed = quest.nCompleted or 0,
		CompleteLimit = quest.nCompleteLimit or 1,
		XPReward = quest.RewardXP or 0,
		GoldReward = quest.RewardGold or 0,
		ZoneCompleted = false,
		Optional = quest.bOptional,
		ZoneStars = zone.nStars,
	})
end

function XHSDevTools:StartBoss(boss)
	boss = boss or ""
	if boss == "magtheridon" then
		MAGTHERIDON = 0
		self:ActivateQuestByName("kill_mag")
		StartMagtheridonArena(false)
		return "Magtheridon started"
	elseif boss == "arthas" then
		self:ActivateQuestByName("kill_arthas")
		StartArthasArena(false)
		return "Arthas started"
	elseif boss == "banehallow" then
		self:ActivateQuestByName("kill_banehallow")
		StartBanehallowArena()
		return "Banehallow started"
	elseif boss == "lich_king" then
		self:ActivateQuestByName("kill_lich_king")
		self:EnsureLichKing()
		StartLichKingArena()
		return "Lich King started"
	elseif boss == "spirit_master" then
		SPIRIT_MASTER_KILLED_BOSS_COUNT = 0
		if XHSSpiritMasterEncounter ~= nil then
			XHSSpiritMasterEncounter:Reset()
		end
		self:ActivateQuestByName("kill_spirit_master")
		StartSpiritMasterArena()
		return "Spirit Master started"
	elseif DIRECT_BOSSES[boss] ~= nil then
		return self:SpawnDirectBoss(DIRECT_BOSSES[boss])
	end

	return "Unknown boss: " .. tostring(boss)
end

function XHSDevTools:PrepareCampaignFlow()
	self:Cleanup()
	self:SetSandboxActive(false)
	self.campaign_flow_active = true

	if CustomTimers ~= nil then
		CustomTimers.game_phase = 3
		CustomGameEventManager:Send_ServerToAllClients("xhs_game_phase_update", { phase = 3 })
		if XHSPersistQuestTimingState then
			XHSPersistQuestTimingState()
		end
	end

	if RefreshPlayers then
		RefreshPlayers()
	end
end

function XHSDevTools:StartCampaignFlow(boss)
	boss = boss or ""
	if DIRECT_BOSSES[boss] ~= nil then
		boss = "four_bosses"
	end

	self:PrepareCampaignFlow()

	if boss == "magtheridon" then
		MAGTHERIDON = 0
		FOUR_BOSSES = 0
		self:ActivateQuestByName("kill_mag")
		StartMagtheridonArena(false)
		return "Campaign flow started at Magtheridon"
	elseif boss == "four_bosses" then
		FOUR_BOSSES = 0
		self:ActivateQuestByName("kill_grom")
		self:ActivateQuestByName("kill_illidan")
		self:ActivateQuestByName("kill_balanar")
		self:ActivateQuestByName("kill_proudmoore")
		EndMagtheridonArena()
		return "Campaign flow started at the four bosses"
	elseif boss == "arthas" then
		self:ActivateQuestByName("kill_arthas")
		StartArthasArena(false)
		return "Campaign flow started at Arthas"
	elseif boss == "banehallow" then
		self:ActivateQuestByName("kill_banehallow")
		StartBanehallowArena()
		return "Campaign flow started at Banehallow"
	elseif boss == "lich_king" then
		self:ActivateQuestByName("kill_lich_king")
		self:EnsureLichKing()
		StartLichKingArena()
		return "Campaign flow started at Lich King"
	elseif boss == "spirit_master" then
		SPIRIT_MASTER_KILLED_BOSS_COUNT = 0
		if XHSSpiritMasterEncounter ~= nil then
			XHSSpiritMasterEncounter:Reset()
		end
		self:ActivateQuestByName("kill_spirit_master")
		StartSpiritMasterArena()
		return "Campaign flow started at Spirit Master"
	end

	self.campaign_flow_active = false
	return "Unknown campaign flow checkpoint: " .. tostring(boss)
end

function XHSDevTools:SpawnDirectBoss(def)
	self:ActivateQuestByName(def.quest)

	local spawner = Entities:FindByName(nil, def.spawner)
	if spawner == nil then
		return "Missing spawner: " .. tostring(def.spawner)
	end

	RefreshPlayers()
	local unit = CreateUnitByName(def.unit, spawner:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
	unit.zone = "xhs_holdout"
	unit:SetAngles(0, def.yaw or 0, 0)
	unit:AddNewModifier(unit, nil, "modifier_pause_creeps", { Duration = 3, IsHidden = true }):SetStackCount(1)
	unit:AddNewModifier(unit, nil, "modifier_invulnerable", { Duration = 3, IsHidden = true })
	if unit:GetUnitName() == "npc_dota_hero_grom_hellscream" and XHSGrom_AttachPhase3AI ~= nil then
		XHSGrom_AttachPhase3AI(unit)
	end
	if unit:GetUnitName() == "npc_dota_hero_illidan" and XHSIllidan_AttachPhase3AI ~= nil then
		XHSIllidan_AttachPhase3AI(unit)
	end
	if unit:GetUnitName() == "npc_dota_hero_balanar" and XHSBalanar_AttachPhase3AI ~= nil then
		XHSBalanar_AttachPhase3AI(unit)
	end
	if unit:GetUnitName() == "npc_dota_hero_proudmoore" and XHSProudmoore_AttachPhase3AI ~= nil then
		XHSProudmoore_AttachPhase3AI(unit)
	end
	if unit:GetUnitName() == "npc_dota_hero_arthas" and XHSArthas_AttachPhase3AI ~= nil then
		XHSArthas_AttachPhase3AI(unit)
	end
	self:RegisterSpawnedUnit(unit)
	self:FocusAllPlayers(unit)

	return QUEST_LABELS[def.quest] .. " spawned"
end

function XHSDevTools:EnsureLichKing()
	for _, unit in pairs(self:FindUnitsEverywhere(DOTA_TEAM_CUSTOM_2)) do
		if unit:GetUnitName() == "npc_dota_boss_lich_king" then
			self:RegisterSpawnedUnit(unit)
			return unit
		end
	end

	local spawner = Entities:FindByName(nil, "npc_dota_spawner_lich_king_bis")
	if spawner == nil then return nil end

	local unit = CreateUnitByName("npc_dota_boss_lich_king", spawner:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
	unit:AddNewModifier(unit, nil, "modifier_invulnerable", {})
	unit:AddNewModifier(unit, nil, "modifier_stunned", {})
	unit:SetAttackCapability(DOTA_UNIT_CAP_NO_ATTACK)
	unit:SetMoveCapability(DOTA_UNIT_CAP_MOVE_NONE)
	unit.zone = "xhs_holdout"
	if XHSLichKing_AttachPhase3AI ~= nil then
		XHSLichKing_AttachPhase3AI(unit)
	end
	self:RegisterSpawnedUnit(unit)
	return unit
end

function XHSDevTools:RegisterSpawnedUnit(unit)
	if unit == nil or not IsValidEntity(unit) or unit:IsNull() then return end

	unit.xhs_devtools_spawned = true
	self.spawned_units = self.spawned_units or {}
	self.spawned_units[unit:entindex()] = true
	self:PushState()
end

function XHSDevTools:SetLane(event)
	local lane = math.max(1, math.min(8, ToNumber(event.lane, 1)))
	local data = CREEP_LANES[lane] or { 0, 1, 1 }
	CREEP_LANES[lane] = data

	if event.enabled ~= nil then data[1] = IsTruthy(event.enabled) and 1 or 0 end
	if event.level ~= nil then data[2] = math.max(1, math.min(4, ToNumber(event.level, data[2] or 1))) end
	if event.rax_alive ~= nil then data[3] = IsTruthy(event.rax_alive) and 1 or 0 end

	self:SetLaneDoor(lane, data[1] == 1)
	return "Lane " .. lane .. " updated"
end

function XHSDevTools:SetLaneDoor(lane, open)
	local obs = Entities:FindAllByName("obstruction_lane" .. lane)
	for _, obstruction in pairs(obs) do
		obstruction:SetEnabled(not open, true)
	end

	if open then
		DoEntFire("door_lane" .. lane, "SetAnimation", "gate_02_open", 0, nil, nil)
	else
		DoEntFire("door_lane" .. lane, "SetAnimation", "gate_02_close", 0, nil, nil)
	end
end

function XHSDevTools:SpawnLaneWave(lane)
	if lane == nil or lane <= 0 then
		SpawnCreeps(true)
		return "Spawned enabled lane waves"
	end

	lane = math.max(1, math.min(8, lane))
	local previous = {}
	for i = 1, 8 do
		previous[i] = CREEP_LANES[i] and CREEP_LANES[i][1] or 0
		if CREEP_LANES[i] then
			CREEP_LANES[i][1] = i == lane and 1 or 0
		end
	end

	SpawnCreeps(true)

	for i = 1, 8 do
		if CREEP_LANES[i] then
			CREEP_LANES[i][1] = previous[i]
		end
	end

	return "Spawned wave on lane " .. lane
end

function XHSDevTools:SpawnPhase2Wave(side)
	side = string.lower(tostring(side or "both"))
	if side ~= "left" and side ~= "right" and side ~= "both" then
		return "Unknown Phase 2 side: " .. tostring(side)
	end

	if OpenPhase2Doors == nil or SpawnPhase2CreepWave == nil then
		return "Phase 2 wave helpers are unavailable"
	end

	OpenPhase2Doors(side, false)
	local spawned = SpawnPhase2CreepWave(side, true)
	return "Spawned " .. tostring(spawned) .. " Phase 2 creeps (" .. side .. ")"
end

function XHSDevTools:StartPhase2()
	if _G.StartPhase2 == nil or CustomTimers == nil then
		return "StartPhase2() is unavailable"
	end

	self:SetSandboxActive(false)
	CustomTimers.game_phase = 1
	_G.StartPhase2()
	return "Phase 2 activated with recurring waves"
end

function XHSDevTools:SetPhase(phase)
	phase = math.max(1, math.min(3, phase))
	if CustomTimers then
		CustomTimers.game_phase = phase
		CustomGameEventManager:Send_ServerToAllClients("xhs_game_phase_update", { phase = phase })
		CustomGameEventManager:Send_ServerToAllClients("xhs_creep_level_update", { level = CustomTimers.creep_level or 1 })
		if XHSPersistQuestTimingState then
			XHSPersistQuestTimingState()
		end
	end
	return "Phase set to " .. phase
end

function XHSDevTools:SetDifficulty(difficulty, respawn_bosses)
	difficulty = math.max(1, math.min(5, difficulty or 1))

	local active_boss_ids = {}
	local active_boss_lookup = {}
	if respawn_bosses == true then
		for _, boss_id in pairs(self:GetActiveBossDevIds()) do
			if active_boss_lookup[boss_id] ~= true then
				active_boss_lookup[boss_id] = true
				table.insert(active_boss_ids, boss_id)
			end
		end
	end

	GameRules:SetCustomGameDifficulty(difficulty)
	if api ~= nil and api.SetCustomDifficulty ~= nil then
		api:SetCustomDifficulty(difficulty)
	end
	if CustomNetTables ~= nil then
		CustomNetTables:SetTableValue("game_options", "difficulty", { tostring(difficulty) })
	end

	if respawn_bosses == true and #active_boss_ids > 0 then
		self:ActivateSandbox("difficulty")
		self:RemoveActiveBossUnits()
		CustomGameEventManager:Send_ServerToAllClients("hide_boss_hp", { boss_count = 1 })
		CustomGameEventManager:Send_ServerToAllClients("hide_boss_hp", { boss_count = 2 })
		CustomGameEventManager:Send_ServerToAllClients("xhs_boss_counter_hide", { boss_count = 1 })
		CustomGameEventManager:Send_ServerToAllClients("hide_ui", {})

		GameRules:GetGameModeEntity():SetContextThink("XHSDevToolsRespawnBosses", function()
			for _, boss_id in pairs(active_boss_ids) do
				self:StartBoss(boss_id)
			end
			self:PushState()
			return nil
		end, 0.2)

		return "Difficulty set to " .. tostring(difficulty) .. " (" .. (DIFFICULTY_LABELS[difficulty] or "Custom") .. "); respawning active boss test"
	end

	return "Difficulty set to " .. tostring(difficulty) .. " (" .. (DIFFICULTY_LABELS[difficulty] or "Custom") .. ")"
end

function XHSDevTools:GetPrimaryGoodHero()
	for _, hero in pairs(HeroList:GetAllHeroes()) do
		if hero ~= nil and hero:IsRealHero() and hero:GetTeamNumber() == DOTA_TEAM_GOODGUYS and hero:GetPlayerOwner() ~= nil then
			return hero
		end
	end

	return nil
end

function XHSDevTools:GetActionPlayer(event)
	local playerID = ToNumber(event and event.PlayerID, -1)
	if PlayerResource:IsValidPlayerID(playerID) then
		return PlayerResource:GetPlayer(playerID)
	end

	local hero = self:GetPrimaryGoodHero()
	return hero ~= nil and hero:GetPlayerOwner() or nil
end

function XHSDevTools:PreviewVipDialog(event)
	local player = self:GetActionPlayer(event)
	if player == nil then
		return "No player available for VIP dialog preview"
	end

	local mode = string.lower(tostring(event.mode or "ready"))
	local ready = mode ~= "next"
	local playerCount = math.max(1, math.min(8, ToNumber(event.player_count, 1)))
	local isUther = event.speaker == "uther"
	local speakerUnit = isUther and "npc_xhs_paladin_2" or "npc_xhs_paladin"
	local speakerName = isUther and "UTHER LIGHTBRINGER" or "SHAL LIGHTBINDER"
	local text
	if isUther then
		text = ready
			and "Stand together. When every hero is ready, we face Arthas - and end this."
			or "The road to the Frozen Throne lies open. Beyond this passage, Arthas awaits - and the reckoning I have dreaded since Lordaeron fell."
	else
		text = ready
			and "The way is open. Give the word, and the Light will carry us into their realm - straight to the source of this invasion."
			or "While I was bound, I felt the enemy gathering beyond the gates. The siege was only their first test."
	end

	CustomGameEventManager:Send_ServerToPlayer(player, "dialog", {
		DevPreview = 1,
		PreviewPlayerCount = playerCount,
		DialogEntIndex = -1,
		PlayerHeroEntIndex = -1,
		DialogText = text,
		RawDialogText = 1,
		DialogAdvanceTime = 120,
		DialogLine = 1,
		ShowAdvanceButton = not ready,
		SendToAll = true,
		DialogPlayerConfirm = ready and 1 or 0,
		ConfirmToken = "XHSDevPreview",
		JournalEntry = false,
		SpeakerUnitName = speakerUnit,
		SpeakerName = speakerName,
	})

	return "VIP dialog preview: " .. mode .. " / " .. tostring(playerCount) .. " players"
end

function XHSDevTools:CloseVipDialogPreview(event)
	local player = self:GetActionPlayer(event)
	if player ~= nil then
		CustomGameEventManager:Send_ServerToPlayer(player, "xhs_dialog_dev_preview_close", {})
	end
	return "VIP dialog preview closed"
end

function XHSDevTools:PreviewCinematic(event)
	local player = self:GetActionPlayer(event)
	if player == nil then
		return "No player available for cinematic preview"
	end
	if XHSCinematics == nil then
		error("XHSCinematics is unavailable")
	end

	local mode = string.lower(tostring(event.mode or "bars"))
	local options = {
		duration = 0,
		letterbox_pct = 10,
		transition = 0.5,
		hide_hud = false,
	}

	if mode == "title" then
		options.title = "X HERO SIEGE"
		options.subtitle = "Server event cinematic diagnostic"
	elseif mode == "full" then
		options.duration = 5
		options.transition = 0.75
		options.hide_hud = true
		options.title = "FINAL WAVE"
		options.subtitle = "HUD restore should occur automatically"
	elseif mode == "final_wave" then
		options.duration = 8
		options.transition = 0.75
		options.hide_hud = true
	else
		mode = "bars"
	end

	self.dev_cinematic_id = "xhs_dev_server_" .. mode
	XHSCinematics:BeginForPlayer(player, self.dev_cinematic_id, options)
	return "Cinematic preview started: " .. mode
end

function XHSDevTools:EndCinematicPreview(event)
	local player = self:GetActionPlayer(event)
	if player == nil then
		return "No player available for cinematic preview"
	end
	if XHSCinematics == nil then
		error("XHSCinematics is unavailable")
	end

	local cinematicId = self.dev_cinematic_id or "xhs_dev_server_bars"
	XHSCinematics:EndForPlayer(player, cinematicId)
	self.dev_cinematic_id = nil
	return "Cinematic preview ended"
end

function XHSDevTools:TriggerEvent(event_name)
	if event_name == "muradin" then
		SpecialEvents:MuradinEvent(10)
		return "Muradin event triggered"
	elseif event_name == "farm" then
		SpecialEvents:FarmEvent(10)
		return "Farm event triggered"
	elseif event_name == "ramero_baristol" then
		SpecialEvents:StartRameroAndBaristolEvent(self:GetPrimaryGoodHero())
		return "Ramero & Baristol event triggered"
	elseif event_name == "sogat" then
		SpecialEvents:StartSogatEvent(self:GetPrimaryGoodHero())
		return "Sogat event triggered"
	elseif event_name == "final_countdown" then
		if CustomTimers and CustomTimers.PrepareFinalWaveCountdown then
			CustomTimers:PrepareFinalWaveCountdown(true)
			return "Final wave countdown triggered"
		end
	end
	return "Unknown event: " .. tostring(event_name)
end

function XHSDevTools:MaxLevelHeroes()
	for _, hero in pairs(HeroList:GetAllHeroes()) do
		if hero ~= nil and hero:IsRealHero() and hero:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
			hero:AddExperience(9999999, DOTA_ModifyXP_Unspecified, false, true)
		end
	end
	return "Heroes max leveled"
end

function XHSDevTools:GrantGold(amount)
	for player_id = 0, PlayerResource:GetPlayerCount() - 1 do
		if PlayerResource:IsValidPlayerID(player_id) and PlayerResource:GetTeam(player_id) == DOTA_TEAM_GOODGUYS then
			PlayerResource:ModifyGold(player_id, amount, true, DOTA_ModifyGold_Unspecified)
		end
	end
	return "Granted " .. tostring(amount) .. " gold"
end

function XHSDevTools:ToggleInvulnerable()
	self.invulnerable_players = self.invulnerable_players ~= true

	for _, hero in pairs(HeroList:GetAllHeroes()) do
		if hero ~= nil and hero:IsRealHero() and hero:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
			if self.invulnerable_players then
				hero:AddNewModifier(hero, nil, "modifier_invulnerable", {})
			else
				hero:RemoveModifierByName("modifier_invulnerable")
			end
		end
	end

	return self.invulnerable_players and "Hero invulnerability enabled" or "Hero invulnerability disabled"
end

function XHSDevTools:SetTemporaryDonatorStatus(event)
	if api == nil or api.SetTemporaryDonatorStatus == nil then
		return "Donator API is unavailable"
	end

	local playerID = ToNumber(event.target_player_id, ToNumber(event.PlayerID, -1))
	if not PlayerResource:IsValidPlayerID(playerID) then
		return "Invalid player ID for temporary donator status"
	end

	if IsTruthy(event.clear) then
		api:SetTemporaryDonatorStatus(playerID, nil)
		self:RefreshTemporaryDonatorStatus(playerID)
		return "Temporary donator status cleared"
	end

	local status = math.max(0, math.min(10, math.floor(ToNumber(event.status, 0))))
	api:SetTemporaryDonatorStatus(playerID, status)
	self:RefreshTemporaryDonatorStatus(playerID)
	return "Temporary donator status set to " .. tostring(status)
end

function XHSDevTools:RefreshTemporaryDonatorStatus(playerID)
	if api ~= nil and api.InitDonatorTableJS ~= nil then
		api:InitDonatorTableJS()
	end

	if SupporterPass ~= nil and SupporterPass.PublishPlayer ~= nil then
		SupporterPass:PublishPlayer(playerID)
	elseif CustomNetTables ~= nil and api ~= nil and api.GetDonatorStatus ~= nil then
		local playerTable = CustomNetTables:GetTableValue("supporter_pass_player", tostring(playerID)) or {}
		playerTable.donator_level = api:GetDonatorStatus(playerID)
		CustomNetTables:SetTableValue("supporter_pass_player", tostring(playerID), playerTable)
	end

	local hero = PlayerResource:GetSelectedHeroEntity(playerID)
	if hero ~= nil and not hero:IsNull() then
		local status = api:GetDonatorStatus(playerID)
		local modifier = hero:FindModifierByName("modifier_patreon_donator")

		if status == 10 then
			if modifier ~= nil then
				hero:RemoveModifierByName("modifier_patreon_donator")
			end
		else
			if modifier == nil then
				modifier = hero:AddNewModifier(hero, nil, "modifier_patreon_donator", {})
			end

			if modifier ~= nil then
				modifier:SetStackCount(status)
				modifier.current_effect_name = nil

				if modifier.SetDonatorEffect ~= nil and api.GetPlayerEmblem ~= nil then
					modifier:SetDonatorEffect(api:GetPlayerEmblem(playerID))
				elseif modifier.RefreshEffect ~= nil then
					modifier:RefreshEffect()
				end
			end
		end

		-- if hero.SetupHealthBarLabel ~= nil then
		-- hero:SetupHealthBarLabel()
		-- end
	end
end

function XHSDevTools:Cleanup()
	local battlepassPlayers = {}
	for playerID, _ in pairs(self.battlepass_dev_sequences or {}) do
		table.insert(battlepassPlayers, playerID)
	end
	for _, playerID in ipairs(battlepassPlayers) do
		self:CancelBattlepassDevSequence(playerID, true)
	end
	self:RemoveDevSpawnedUnits()
	if ResetPhase2CreepWaveCounts ~= nil then
		ResetPhase2CreepWaveCounts()
	end
	if KillCreeps then
		KillCreeps(DOTA_TEAM_CUSTOM_1)
	end
	CustomGameEventManager:Send_ServerToAllClients("hide_boss_hp", { boss_count = 1 })
	CustomGameEventManager:Send_ServerToAllClients("hide_boss_hp", { boss_count = 2 })
	CustomGameEventManager:Send_ServerToAllClients("xhs_boss_counter_hide", { boss_count = 1 })
	CustomGameEventManager:Send_ServerToAllClients("hide_ui", {})
	return "Dev cleanup complete"
end

function XHSDevTools:RemoveDevSpawnedUnits()
	self.spawned_units = self.spawned_units or {}

	for entindex in pairs(self.spawned_units) do
		local unit = EntIndexToHScript(entindex)
		if unit ~= nil and IsValidEntity(unit) and not unit:IsNull() then
			UTIL_Remove(unit)
		end
	end

	for _, unit in pairs(self:FindUnitsEverywhere(DOTA_TEAM_CUSTOM_2)) do
		if unit.xhs_devtools_spawned == true then
			UTIL_Remove(unit)
		end
	end

	self.spawned_units = {}
end

function XHSDevTools:GetActiveBossUnits()
	local units = {}
	local seen = {}
	local teams = { DOTA_TEAM_CUSTOM_2, DOTA_TEAM_CUSTOM_1 }

	for _, team in pairs(teams) do
		for _, unit in pairs(self:FindUnitsEverywhere(team)) do
			if unit ~= nil and not unit:IsNull() and unit:IsAlive() and BOSS_UNIT_NAMES[unit:GetUnitName()] then
				local entindex = unit:entindex()
				if seen[entindex] ~= true then
					seen[entindex] = true
					table.insert(units, unit)
				end
			end
		end
	end

	return units
end

function XHSDevTools:GetActiveBossDevIds()
	local ids = {}

	for _, unit in pairs(self:GetActiveBossUnits()) do
		local boss_id = BOSS_UNIT_TO_DEV_ID[unit:GetUnitName()]
		if boss_id ~= nil then
			table.insert(ids, boss_id)
		end
	end

	return ids
end

function XHSDevTools:RemoveActiveBossUnits()
	self.spawned_units = self.spawned_units or {}
	for _, unit in pairs(self:GetActiveBossUnits()) do
		if unit ~= nil and IsValidEntity(unit) and not unit:IsNull() then
			self.spawned_units[unit:entindex()] = nil
			UTIL_Remove(unit)
		end
	end
end

function XHSDevTools:FindUnitsEverywhere(team)
	return FindUnitsInRadius(
		team,
		Vector(0, 0, 0),
		nil,
		FIND_UNITS_EVERYWHERE,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_ALL,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
		FIND_ANY_ORDER,
		false
	)
end

function XHSDevTools:FocusAllPlayers(unit)
	if unit == nil or unit:IsNull() then return end

	for _, hero in pairs(HeroList:GetAllHeroes()) do
		if hero ~= nil and hero:IsRealHero() and hero:GetTeamNumber() == DOTA_TEAM_GOODGUYS and hero:GetPlayerOwner() ~= nil then
			CustomGameEventManager:Send_ServerToPlayer(hero:GetPlayerOwner(), "set_player_camera", {
				hPosition = unit:GetAbsOrigin(),
				iSpeed = 0.55,
			})
		end
	end
end

function XHSDevTools:BuildBattlepassDevCatalog()
	local grouped = {}
	local seen = {}
	for _, family in ipairs(BATTLEPASS_DEV_FAMILY_ORDER) do
		grouped[family] = {}
	end

	if ItemsGame == nil then return {} end
	for _, trackData in ipairs({
		{ id = "free", rewards = ItemsGame.battlepass or {} },
		{ id = "premium", rewards = ItemsGame.battlepass2 or {} },
	}) do
		for _, reward in pairs(trackData.rewards) do
			if type(reward) == "table" then
				local family = tostring(reward.slot_id or reward.item_type or reward.type or "")
					:lower()
				if Battlepass ~= nil and Battlepass.NormalizeSupporterSlot ~= nil then
					family = Battlepass:NormalizeSupporterSlot(family)
				end

				local itemID = reward.entitlement_id
					or reward.item_id
					or reward.catalog_item_id
					or reward.reward_item_id
					or reward.id
				itemID = itemID ~= nil and tostring(itemID) or ""
				local identity = family .. ":" .. itemID
				if BATTLEPASS_DEV_FAMILY_SET[family] == true
					and itemID ~= ""
					and not seen[identity] then
					seen[identity] = true
					local name = tostring(reward.name or reward.item_name or itemID)
					table.insert(grouped[family], {
						item_id = itemID,
						family = family,
						name = name,
						display_name = FormatBattlepassDevRewardName(name, family),
						rarity = tostring(reward.rarity or reward.item_rarity or ""),
						track = tostring(reward.track or trackData.id),
						level = tonumber(reward.level) or 0,
					})
				end
			end
		end
	end

	local families = {}
	for _, family in ipairs(BATTLEPASS_DEV_FAMILY_ORDER) do
		local rewards = grouped[family]
		table.sort(rewards, function(a, b)
			local aID = tonumber(a.item_id)
			local bID = tonumber(b.item_id)
			if aID ~= nil and bID ~= nil and aID ~= bID then return aID < bID end
			if a.level ~= b.level then return a.level < b.level end
			return a.item_id < b.item_id
		end)
		if #rewards > 0 then
			table.insert(families, {
				id = family,
				label = BATTLEPASS_DEV_FAMILY_LABELS[family] or family,
				count = #rewards,
				rewards = rewards,
			})
		end
	end
	return families
end

function XHSDevTools:PublishBattlepassDevCatalog()
	if self.battlepass_dev_catalog_index ~= nil then
		return self.battlepass_dev_catalog_index
	end
	if CustomNetTables == nil then return {} end

	local families = self:BuildBattlepassDevCatalog()
	if #families == 0 then return {} end
	local index = {}
	for _, family in ipairs(families) do
		CustomNetTables:SetTableValue(
			"xhs_devtools",
			"battlepass_family_" .. family.id,
			family
		)
		table.insert(index, {
			id = family.id,
			label = family.label,
			count = family.count,
		})
	end
	self.battlepass_dev_catalog_index = index
	return index
end

function XHSDevTools:FindBattlepassDevFamily(familyID)
	familyID = tostring(familyID or ""):lower()
	for _, family in ipairs(self:BuildBattlepassDevCatalog()) do
		if family.id == familyID then return family end
	end
	return nil
end

function XHSDevTools:FindBattlepassDevReward(familyID, itemID)
	local family = self:FindBattlepassDevFamily(familyID)
	itemID = tostring(itemID or "")
	if family == nil or itemID == "" then return nil end
	for _, reward in ipairs(family.rewards) do
		if reward.item_id == itemID then return reward, family end
	end
	return nil
end

function XHSDevTools:NotifyBattlepassDevTest(playerID, text, duration)
	local payload = {
		text = tostring(text or ""),
		duration = tonumber(duration) or BATTLEPASS_DEV_SEQUENCE_DELAY,
		severity = "system",
	}
	if Notifications ~= nil and Notifications.Bottom ~= nil then
		Notifications:Bottom(playerID, payload)
		return
	end
	local player = PlayerResource:GetPlayer(playerID)
	if player ~= nil then
		CustomGameEventManager:Send_ServerToPlayer(player, "bottom_notification", payload)
	end
end

function XHSDevTools:CancelBattlepassDevSequence(playerID, cleanupPreview)
	self.battlepass_dev_sequences = self.battlepass_dev_sequences or {}
	local sequence = self.battlepass_dev_sequences[playerID]
	if sequence ~= nil then
		sequence.cancelled = true
		if sequence.timer ~= nil and Timers ~= nil then
			Timers:RemoveTimer(sequence.timer)
		end
		self.battlepass_dev_sequences[playerID] = nil
	end
	if cleanupPreview == true and Battlepass ~= nil and Battlepass.CleanupSupporterDevTest ~= nil then
		Battlepass:CleanupSupporterDevTest(playerID, true)
	end
end

function XHSDevTools:RunBattlepassDevReward(sourceIndex, playerID, reward, requestID)
	if Battlepass == nil or Battlepass.SupporterPassDevTestReward == nil then
		error("Battle Pass dev reward tester is unavailable")
	end
	local player = PlayerResource:GetPlayer(playerID)
	if player ~= nil and player.entindex ~= nil then
		sourceIndex = player:entindex()
	end
	self:NotifyBattlepassDevTest(
		playerID,
		string.format(
			"[Battle Pass] %s - %s (#%s)",
			BATTLEPASS_DEV_FAMILY_LABELS[reward.family] or reward.family,
			reward.display_name,
			reward.item_id
		)
	)
	Battlepass:SupporterPassDevTestReward(sourceIndex, {
		item_id = reward.item_id,
		slot_id = reward.family,
		action = "test",
		request_id = requestID,
		xhs_devtools_trusted = true,
	})
end

function XHSDevTools:TestBattlepassReward(event)
	local sourceIndex = event.xhs_devtools_source_index
	local playerID = self:ResolveEventPlayerID(sourceIndex)
	if playerID == nil then error("Unable to resolve the requesting player") end
	local reward = self:FindBattlepassDevReward(event.family, event.item_id)
	if reward == nil then error("Unknown Battle Pass reward") end

	self:CancelBattlepassDevSequence(playerID, true)
	self:RunBattlepassDevReward(
		sourceIndex,
		playerID,
		reward,
		"xhs-dev-single-" .. tostring(GameRules:GetGameTime())
	)
	return string.format("Testing %s (#%s)", reward.name, reward.item_id)
end

function XHSDevTools:TestBattlepassFamily(event)
	local sourceIndex = event.xhs_devtools_source_index
	local playerID = self:ResolveEventPlayerID(sourceIndex)
	if playerID == nil then error("Unable to resolve the requesting player") end
	local family = self:FindBattlepassDevFamily(event.family)
	if family == nil or #family.rewards == 0 then error("Unknown or empty Battle Pass family") end
	if Timers == nil then error("Timers is unavailable") end
	local player = PlayerResource:GetPlayer(playerID)
	if player ~= nil and player.entindex ~= nil then
		sourceIndex = player:entindex()
	end

	self:CancelBattlepassDevSequence(playerID, true)
	self.battlepass_dev_sequences = self.battlepass_dev_sequences or {}
	local sequence = {
		family = family.id,
		label = family.label,
		rewards = family.rewards,
		index = 0,
		count = #family.rewards,
		source_index = sourceIndex,
		player_id = playerID,
		cancelled = false,
	}
	self.battlepass_dev_sequences[playerID] = sequence

	local function PlayNext()
		if sequence.cancelled == true
			or self.battlepass_dev_sequences[playerID] ~= sequence then
			return nil
		end
		sequence.index = sequence.index + 1
		if sequence.index > sequence.count then
			self:CancelBattlepassDevSequence(playerID, true)
			self:NotifyBattlepassDevTest(
				playerID,
				string.format("[Battle Pass] %s complete (%d rewards)", sequence.label, sequence.count),
				4
			)
			self:PushState()
			return nil
		end

		if Battlepass ~= nil and Battlepass.CleanupSupporterDevTest ~= nil then
			Battlepass:CleanupSupporterDevTest(playerID, true)
		end
		local reward = sequence.rewards[sequence.index]
		self:NotifyBattlepassDevTest(
			playerID,
			string.format(
				"[Battle Pass] %s %d/%d - %s (#%s)",
				sequence.label,
				sequence.index,
				sequence.count,
				reward.display_name,
				reward.item_id
			),
			BATTLEPASS_DEV_SEQUENCE_DELAY
		)
		Battlepass:SupporterPassDevTestReward(sequence.source_index, {
			item_id = reward.item_id,
			slot_id = reward.family,
			action = "test",
			xhs_devtools_trusted = true,
			request_id = string.format(
				"xhs-dev-family-%s-%d-%s",
				sequence.family,
				sequence.index,
				tostring(GameRules:GetGameTime())
			),
		})
		self:PushState()
		sequence.timer = Timers:CreateTimer(BATTLEPASS_DEV_SEQUENCE_DELAY, PlayNext)
		return nil
	end

	PlayNext()
	return string.format("Testing %d %s rewards", sequence.count, sequence.label)
end

function XHSDevTools:StopBattlepassTest(event)
	local playerID = self:ResolveEventPlayerID(event.xhs_devtools_source_index)
	if playerID == nil then error("Unable to resolve the requesting player") end
	self:CancelBattlepassDevSequence(playerID, true)
	self:NotifyBattlepassDevTest(playerID, "[Battle Pass] Reward preview stopped", 3)
	return "Battle Pass reward preview stopped"
end

function XHSDevTools:BuildBattlepassDevSequenceState()
	local result = {}
	for playerID, sequence in pairs(self.battlepass_dev_sequences or {}) do
		if sequence.cancelled ~= true then
			result[tostring(playerID)] = {
				active = true,
				family = sequence.family,
				label = sequence.label,
				index = sequence.index,
				count = sequence.count,
				delay = BATTLEPASS_DEV_SEQUENCE_DELAY,
			}
		end
	end
	return result
end

function XHSDevTools:BuildQuestState()
	local quests = {}
	local zone = self:GetXHSZone()

	for index, quest_name in ipairs(QUEST_ORDER) do
		local quest = nil
		if zone ~= nil and zone.Quests ~= nil then
			for _, candidate in pairs(zone.Quests) do
				if candidate ~= nil and candidate.szQuestName == quest_name then
					quest = candidate
					break
				end
			end
		end

		quests[tostring(index)] = {
			name = quest_name,
			label = QUEST_LABELS[quest_name] or quest_name,
			active = quest ~= nil and quest.bActivated == true or false,
			completed = quest ~= nil and quest.bCompleted == true or false,
			progress = quest ~= nil and quest.nCompleted or 0,
			limit = quest ~= nil and quest.nCompleteLimit or 1,
		}
	end

	return quests
end

function XHSDevTools:BuildLaneState()
	local lanes = {}
	for lane = 1, 8 do
		local data = CREEP_LANES[lane] or { 0, 1, 1 }
		lanes[tostring(lane)] = {
			lane = lane,
			enabled = data[1] == 1,
			level = data[2] or 1,
			rax_alive = data[3] == 1,
		}
	end
	return lanes
end

function XHSDevTools:BuildBossState()
	local bosses = {}
	local index = 1

	for _, unit in pairs(self:GetActiveBossUnits()) do
		bosses[tostring(index)] = {
			entindex = unit:entindex(),
			name = unit:GetUnitName(),
			health = unit:GetHealth(),
			max_health = unit:GetMaxHealth(),
			dev_spawned = unit.xhs_devtools_spawned == true,
		}
		index = index + 1
	end

	return bosses
end

function XHSDevTools:BuildDonatorState()
	local statuses = {}
	if api == nil or api.GetDonatorStatus == nil then
		return statuses
	end

	for playerID = 0, PlayerResource:GetPlayerCount() - 1 do
		if PlayerResource:IsValidPlayerID(playerID) then
			local temporaryStatus = nil
			if api.GetTemporaryDonatorStatus ~= nil then
				temporaryStatus = api:GetTemporaryDonatorStatus(playerID)
			end

			statuses[tostring(playerID)] = {
				status = api:GetDonatorStatus(playerID),
				temporary_status = temporaryStatus,
				has_override = temporaryStatus ~= nil,
			}
		end
	end

	return statuses
end

function XHSDevTools:PushState()
	if CustomNetTables == nil then return end

	self.enabled = IsInToolsMode()

	CustomNetTables:SetTableValue("xhs_devtools", "state", {
		enabled = self.enabled == true,
		sandbox_active = self.sandbox_active == true,
		campaign_flow_active = self.campaign_flow_active == true,
		sandbox_reason = self.sandbox_reason or "",
		game_phase = CustomTimers and CustomTimers.game_phase or 0,
		difficulty = GameRules:GetCustomGameDifficulty() or 1,
		timers_paused = CustomTimers and CustomTimers.timers_paused or 0,
		creep_level = CustomTimers and CustomTimers.creep_level or 1,
		special_wave = CustomTimers and CustomTimers.special_wave or 1,
		invulnerable_players = self.invulnerable_players == true,
		host_timescale = self.host_timescale or 1,
		lanes = self.enabled and self:BuildLaneState() or {},
		quests = self.enabled and self:BuildQuestState() or {},
		bosses = self.enabled and self:BuildBossState() or {},
		donator_statuses = self.enabled and self:BuildDonatorState() or {},
		battlepass = self.enabled and {
			families = self:PublishBattlepassDevCatalog(),
			sequences = self:BuildBattlepassDevSequenceState(),
			delay = BATTLEPASS_DEV_SEQUENCE_DELAY,
		} or {},
		fragment_quests = self.enabled and FragmentQuests ~= nil and FragmentQuests:BuildDevtoolsState() or {},
		last_result = self.last_result or {},
	})
end
