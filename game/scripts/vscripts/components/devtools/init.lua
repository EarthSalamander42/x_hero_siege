if XHSDevTools == nil then
	_G.XHSDevTools = class({})
end

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

function XHSDevTools:Init()
	if self.initialized == true then
		self:PushState()
		return
	end

	self.initialized = true
	self.enabled = IsInToolsMode()
	self.sandbox_active = false
	self.spawned_units = {}
	self.invulnerable_players = false
	self.campaign_flow_active = false
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

function XHSDevTools:OnRunAction(_, event)
	event = event or {}

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
	elseif action == "cleanup" then
		return self:Cleanup()
	elseif action == "reset_sandbox" then
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

function XHSDevTools:Cleanup()
	self:RemoveDevSpawnedUnits()
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
		lanes = self.enabled and self:BuildLaneState() or {},
		quests = self.enabled and self:BuildQuestState() or {},
		bosses = self.enabled and self:BuildBossState() or {},
		last_result = self.last_result or {},
	})
end
