if not SpecialEvents then
	SpecialEvents = class({})
	SpecialEvents.hero_farm_event = {}
	SpecialEvents.Ramero_trigger = 0
end

local SPECIAL_EVENT_CINEMATIC_PAUSE_RAMP = 2.75

local function ShowCurrentEventTimer(title, duration)
	CustomGameEventManager:Send_ServerToAllClients("show_current_event_timer", {
		timer_name = "special_event",
		title = title,
		duration = duration,
	})
end

local function HideCurrentEventTimer()
	CustomGameEventManager:Send_ServerToAllClients("hide_current_event_timer", {
		timer_name = "special_event",
	})
end

local function UpdateGlobalObjective(id, state, text, seconds, started)
	if XHSSetGlobalObjectiveState ~= nil then
		XHSSetGlobalObjectiveState(id, state, text, seconds, started)
		return
	end

	CustomGameEventManager:Send_ServerToAllClients("xhs_global_objective_update", {
		id = id,
		state = state,
		text = text,
		seconds = seconds,
		started = started,
	})
end

local function GetHeroDisplayName(hero)
	if hero == nil or hero:IsNull() then return "A hero" end

	local unit_name = hero:GetUnitName() or ""
	local name = string.gsub(unit_name, "^npc_dota_hero_", "")
	name = string.gsub(name, "^npc_dota_", "")
	name = string.gsub(name, "_", " ")

	return string.gsub(" " .. name, "%W%l", string.upper):sub(2)
end

local function GetHeroPlayerColor(hero)
	if hero == nil or hero:IsNull() or not hero.GetPlayerID then return "#ffffff" end

	local player_id = hero:GetPlayerID()
	local color = PLAYER_COLORS[player_id]
	if color == nil then return "#ffffff" end

	return string.format("#%02x%02x%02x", color[1] or 255, color[2] or 255, color[3] or 255)
end

local function NotifySpecialArenaStarted(hero, target_text)
	local hero_name = GetHeroDisplayName(hero)
	local hero_color = GetHeroPlayerColor(hero)
	local hero_unit_name = nil

	if hero ~= nil and not hero:IsNull() then
		hero_unit_name = hero:GetUnitName()
	end

	local segments = {}
	if hero_unit_name ~= nil and hero_unit_name ~= "" then
		table.insert(segments, { hero = hero_unit_name, imagestyle = "icon" })
	end
	table.insert(segments, {
		text = "<font color='" .. hero_color .. "'>" .. hero_name .. "</font> has reached the kill milestone and will fight " .. target_text .. "!",
		class = "XHSSpecialArenaText",
	})

	Notifications:TopToAll({
		duration = 5.0,
		segments = segments,
	})
end

local function NotifySpecialArenaInstructions(hero, boss_hero, text)
	if hero == nil or hero:IsNull() or not hero.GetPlayerOwner then return end

	local player = hero:GetPlayerOwner()
	if player == nil then return end

	Notifications:Bottom(player, {
		duration = 6.5,
		segments = {
			{ hero = boss_hero },
			{ text = text },
		},
	})
end

local STORM_EARTH_FIRE_SOUND = "Muradin.StormEarthFire"

local function StopStormEarthFireSound(entity)
	if entity == nil or not IsValidEntity(entity) or entity:IsNull() then return end

	StopSoundOn(STORM_EARTH_FIRE_SOUND, entity)
	if entity.StopSound ~= nil then
		entity:StopSound(STORM_EARTH_FIRE_SOUND)
	end
end

local function StopAllStormEarthFireSounds()
	if SpecialEvents.stormEarthFireEmitters == nil then return end

	for _, info in pairs(SpecialEvents.stormEarthFireEmitters) do
		if info ~= nil then
			StopStormEarthFireSound(info.entity)
		end
	end

	SpecialEvents.stormEarthFireEmitters = {}
end

local function PlayStormEarthFireSound(entity)
	if entity == nil or not IsValidEntity(entity) or entity:IsNull() then return end

	SpecialEvents.stormEarthFireEmitters = SpecialEvents.stormEarthFireEmitters or {}

	local key = tostring(entity:entindex())
	local now = GameRules:GetGameTime()
	local previous = SpecialEvents.stormEarthFireEmitters[key]
	if previous ~= nil and previous.lastPlayed ~= nil and now - previous.lastPlayed < 1.0 then
		return
	end

	StopStormEarthFireSound(entity)
	EmitSoundOn(STORM_EARTH_FIRE_SOUND, entity)
	SpecialEvents.stormEarthFireEmitters[key] = {
		entity = entity,
		lastPlayed = now,
	}
end

function SpecialEvents:MuradinEvent(time)
	local stun_duration = 5.0
	local event_end_delay = time + stun_duration

	StopAllStormEarthFireSounds()
	CustomTimers.current_time["special_event"] = time
	CustomTimers.current_time["creep_level"] = time
	CustomTimers.current_event_timer_paused = true
	CustomTimers.timers_paused = 1
	GameMode.Muradin_occuring = true
	BT_ENABLED = 0
	ShowCurrentEventTimer("MURADIN EVENT", time)
	CustomTimers:BroadcastTimer("special_event")
	CustomTimers:BroadcastTimer("creep_level")
	UpdateGlobalObjective("muradin_event", "Active", "Muradin Event: " .. tostring(math.floor(time / 60)) .. ":" .. string.format("%02d", time % 60), time, true)
	if FragmentQuests ~= nil then
		FragmentQuests:OnMuradinStart(time)
	end

	StunBuildings(event_end_delay)
	CinematicPauseGame(SPECIAL_EVENT_CINEMATIC_PAUSE_RAMP)

	local mode = GameRules:GetGameModeEntity()
	mode:SetFixedRespawnTime(1)

	local Muradin = CreateUnitByName("npc_dota_creature_muradin_bronzebeard", Entities:FindByName(nil, "npc_dota_muradin_boss"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
	Muradin:AddNewModifier(Muradin, nil, "modifier_cinematic_pause", { duration = stun_duration, ramp_duration = SPECIAL_EVENT_CINEMATIC_PAUSE_RAMP })
	Muradin:SetAngles(0, 270, 0)
	Notifications:TopToAll({
		duration = stun_duration,
		segments = {
			{ hero = "npc_dota_hero_zuus" },
			{ text = "You can't kill him! Just survive the Countdown. Reward: 15 000 Gold." },
		},
	})

	-- EmitSoundOn("SantaClaus.StartArena", Muradin) -- todo: add a variable in game-register endpoint to enable/disable this sound during december

	for nPlayerID = 0, PlayerResource:GetPlayerCount() - 1 do
		if PlayerResource:HasSelectedHero(nPlayerID) and PlayerResource:GetSelectedHeroEntity(nPlayerID) ~= "npc_dota_hero_wisp" then
			local hero = PlayerResource:GetSelectedHeroEntity(nPlayerID)

			if hero and not hero:IsNull() and hero:IsRealHero() and not hero:HasModifier("modifier_fountain_invulnerability") then
				hero.old_pos = hero:GetAbsOrigin()
				local id = hero:GetPlayerID()
				local point = Entities:FindByName(nil, "npc_dota_muradin_player_" .. id)

				DisableItems(hero, event_end_delay)
				TeleportHero(hero, point:GetAbsOrigin(), stun_duration - 2.0)
			end
		end
	end

	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("muradin_event"), function()
		RestartHeroes()
		if Muradin and not Muradin:IsNull() then
			PlayStormEarthFireSound(Muradin)
		end
		CustomTimers.current_event_timer_paused = false

		return nil
	end, stun_duration)

	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("muradin_event"), function()
		if CustomTimers.special_waves_disabled == true then return nil end

		CustomTimers.current_time["special_wave"] = 30
		CustomTimers:ShowSpecialWaveCountdown(3, 30)
		if Runes and Runes.OnSpecialWaveWarning then
			Runes:OnSpecialWaveWarning(3, CustomTimers:GetSpecialWavePoint(3))
		end
		CustomTimers.enable_special_wave = true
		CustomTimers:BroadcastTimer("special_wave")

		return nil
	end, event_end_delay - 30)

	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("muradin_event"), function()
		mode:SetFixedRespawnTime(RESPAWN_TIME)
		CustomTimers.current_time["special_event"] = XHS_SPECIAL_EVENT_INTERVAL + 1
		CustomTimers.current_event_timer_paused = false
		if CustomTimers.creep_level < 3 then
			CustomTimers.creep_level = 3
			CustomTimers.current_time["creep_level"] = XHS_CREEPS_UPGRADE_INTERVAL
			CreepLevels(CustomTimers.creep_level)
		end
		BT_ENABLED = 1
		CustomTimers.timers_paused = 0
		RestartCreeps(3.0)
		Notifications:TopToAll({ text = "Special Events are unlocked!", style = { color = "DodgerBlue" }, duration = 5.0 })
		Entities:FindByName(nil, "trigger_special_event_tp_off"):Disable()
		Entities:FindByName(nil, "trigger_special_event"):Enable()
		HideCurrentEventTimer()
		UpdateGlobalObjective("muradin_event", "Completed", "Muradin Event completed", nil, true)
		UpdateGlobalObjective("farm_event", "Active", "Farm Event in --:--", nil)
		CustomGameEventManager:Send_ServerToAllClients("update_special_event_label_farm", {})
		StopAllStormEarthFireSounds()
		SpecialEvents:EndMuradinEvent()
		if CustomTimers.special_waves_disabled ~= true then
			SpecialWave(3)
		end

		return nil
	end, event_end_delay)

	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("muradin_event"), function()
		-- fail-safe, just in case a hero died and had an ankh of reincarnation
		SpecialEvents:EndMuradinEvent()

		RestartCreeps(0.0)
		StopAllStormEarthFireSounds()
		UTIL_Remove(Muradin)

		return nil
	end, event_end_delay + 6.0)

	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("muradin_event"), function()
		GameMode.Muradin_occuring = false

		return nil
	end, event_end_delay + 10.0)
end

function SpecialEvents:EndMuradinEvent()
	if FragmentQuests ~= nil then
		FragmentQuests:OnMuradinEnd()
	end

	local MuradinCheck = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, Entities:FindByName(nil, "npc_dota_muradin_boss"):GetAbsOrigin(), nil, 2000, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)

	for _, hero in pairs(MuradinCheck) do
		-- Timers:CreateTimer(function()
		if hero and not hero:IsNull() and hero:IsRealHero() and not hero:IsIllusion() and hero:IsRealHero() and not hero.paid then
			hero.paid = true
			if hero.old_pos then
				TeleportHero(hero, hero.old_pos, 3.0, 1.0)
			else
				if hero:GetTeamNumber() == 2 then
					TeleportHero(hero, BASE_GOOD:GetAbsOrigin(), 3.0, 1.0)
					-- elseif hero:GetTeamNumber() == 3 then
					-- TeleportHero(hero, base_bad:GetAbsOrigin(), 3.0, 1.0)
				end
			end

			PlayerResource:ModifyGold(hero:GetPlayerOwnerID(), XHS_MURADIN_EVENT_GOLD, false, DOTA_ModifyGold_Unspecified)
			local player = PlayerResource:GetPlayer(hero:GetPlayerOwnerID())
			if player ~= nil then
				CustomGameEventManager:Send_ServerToPlayer(player, "xhs_reward_notification", {
					type = "gold",
					amount = XHS_MURADIN_EVENT_GOLD,
					title = "Muradin Reward",
					text = "+" .. XHS_MURADIN_EVENT_GOLD .. " gold",
					duration = 2.6,
				})
			end
		end
		-- end)
	end
end

function SpecialEvents:FarmEvent(time)
	local difficulty = GameRules:GetCustomGameDifficulty()
	local tp_delay = 3.0
	local start_delay = tp_delay + 3.0

	StopAllStormEarthFireSounds()
	CustomTimers.current_time["special_event"] = time
	CustomTimers.timers_paused = 1
	BT_ENABLED = 0
	GameMode.FarmEvent_occuring = true
	ShowCurrentEventTimer("FARM EVENT", time)
	UpdateGlobalObjective("farm_event", "Active", "Farm Event active", time)
	if FragmentQuests ~= nil then
		FragmentQuests:OnFarmEventStart(time)
	end

	StunBuildings(time)
	CinematicPauseGame(SPECIAL_EVENT_CINEMATIC_PAUSE_RAMP)

	for k, v in pairs(HeroList:GetAllHeroes()) do
		if v:IsRealHero() then
			local nPlayerID = v:GetPlayerID()
			local point = Entities:FindByName(nil, "farm_event_player_" .. nPlayerID)

			if nPlayerID >= 0 then
				v.old_pos = v:GetAbsOrigin()
				TeleportHero(v, point:GetAbsOrigin(), tp_delay)
			end
		end
	end

	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("farm_event"), function()
		Notifications:TopToAll({
			duration = 5.0,
			segments = {
				{ hero = "npc_dota_hero_alchemist" },
				{ text = "It's farming time! Kill as many creeps as you can!" },
			},
		})

		RestartHeroes()

		for nPlayerID = 0, PlayerResource:GetPlayerCount() - 1 do
			if PlayerResource:HasSelectedHero(nPlayerID) and PlayerResource:GetSelectedHeroEntity(nPlayerID) ~= "npc_dota_hero_wisp" then
				local hero = PlayerResource:GetSelectedHeroEntity(nPlayerID)
				local point = Entities:FindByName(nil, "farm_event_player_" .. nPlayerID)

				SpecialEvents.hero_farm_event[nPlayerID] = {}
				SpecialEvents.hero_farm_event[nPlayerID]["round"] = 1
				SpecialEvents.hero_farm_event[nPlayerID]["level"] = 1

				for j = 1, 10 do
					if FarmEvent_Creeps[1] and point then
						PlayStormEarthFireSound(point)

						local unit = CreateUnitByName(FarmEvent_Creeps[1], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
						unit:SetBaseDamageMin(unit:GetRealDamageDone(unit) + (FARM_EVENT_UPGRADE["damage"][difficulty] * SpecialEvents.hero_farm_event[nPlayerID]["level"]))
						unit:SetBaseDamageMax(unit:GetRealDamageDone(unit) + (FARM_EVENT_UPGRADE["damage"][difficulty] * SpecialEvents.hero_farm_event[nPlayerID]["level"]) * 1.1)
						unit:SetMaxHealth(unit:GetMaxHealth() + (FARM_EVENT_UPGRADE["health"][difficulty] * SpecialEvents.hero_farm_event[nPlayerID]["level"]))
						unit:SetBaseMaxHealth(unit:GetMaxHealth() + (FARM_EVENT_UPGRADE["health"][difficulty] * SpecialEvents.hero_farm_event[nPlayerID]["level"]))
						unit:SetHealth(unit:GetMaxHealth())
						unit:SetPhysicalArmorBaseValue(unit:GetPhysicalArmorValue(false) + (FARM_EVENT_UPGRADE["armor"][difficulty] * SpecialEvents.hero_farm_event[nPlayerID]["level"]))
						ApplyGrowthOverheadMarker(unit, SpecialEvents.hero_farm_event[nPlayerID]["level"])
					end
				end

				DisableItems(hero, time)

				SpecialEvents:FarmEventCreeps(nPlayerID)
			end
		end
	end, start_delay)

	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("muradin_event"), function()
		if CustomTimers.special_waves_disabled == true then return nil end

		Notifications:TopToAll({ text = "WARNING: Incoming Wave of Darkness from the North!", duration = 25.0, style = { color = "red" } })
		if Runes and Runes.OnSpecialWaveWarning then
			Runes:OnSpecialWaveWarning(6, CustomTimers:GetSpecialWavePoint(6))
		end

		return nil
	end, time - 20)

	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("muradin_event"), function()
		BT_ENABLED = 1
		SpecialEvents:EndFarmEvent()
		HideCurrentEventTimer()
		UpdateGlobalObjective("farm_event", "Completed", "Farm Event completed", nil)
		CustomGameEventManager:Send_ServerToAllClients("update_special_event_label_final", {})

		return nil
	end, time)

	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("muradin_event"), function()
		RestartCreeps(0.0)
		if CustomTimers.special_waves_disabled ~= true then
			SpecialWave(6)
		end

		return nil
	end, time + 10)
end

function SpecialEvents:FarmEventCreeps(id)
	local point = Entities:FindByName(nil, "farm_event_player_" .. id)
	local difficulty = GameRules:GetCustomGameDifficulty()

	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("muradin_event"), function()
		local units = FindUnitsInRadius(DOTA_TEAM_CUSTOM_2, point:GetAbsOrigin(), nil, 1200, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

		if CustomTimers.timers_paused == 1 then
			if #units <= 1 then
				SpecialEvents.hero_farm_event[id]["round"] = (SpecialEvents.hero_farm_event[id]["round"] + 1) % 9

				if SpecialEvents.hero_farm_event[id]["round"] == 0 then
					SpecialEvents.hero_farm_event[id]["level"] = (SpecialEvents.hero_farm_event[id]["level"] + 1)
				end

				for j = 1, 10 do
					local unit = CreateUnitByName(FarmEvent_Creeps[SpecialEvents.hero_farm_event[id]["round"] + 1], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
					unit:SetBaseDamageMin(unit:GetRealDamageDone(unit) + (FARM_EVENT_UPGRADE["damage"][difficulty] * SpecialEvents.hero_farm_event[id]["level"]) * 0.95)
					unit:SetBaseDamageMax(unit:GetRealDamageDone(unit) + (FARM_EVENT_UPGRADE["damage"][difficulty] * SpecialEvents.hero_farm_event[id]["level"]) * 1.05)
					unit:SetMaxHealth(unit:GetMaxHealth() + (FARM_EVENT_UPGRADE["health"][difficulty] * SpecialEvents.hero_farm_event[id]["level"]))
					unit:SetBaseMaxHealth(unit:GetMaxHealth() + (FARM_EVENT_UPGRADE["health"][difficulty] * SpecialEvents.hero_farm_event[id]["level"]))
					unit:SetHealth(unit:GetMaxHealth())
					unit:SetPhysicalArmorBaseValue(unit:GetPhysicalArmorValue(false) + (FARM_EVENT_UPGRADE["armor"][difficulty] * SpecialEvents.hero_farm_event[id]["level"]))

					ApplyGrowthOverheadMarker(unit, SpecialEvents.hero_farm_event[id]["level"])
				end
			end

			return 1
		else
			return nil
		end
	end, 0.0)
end

function SpecialEvents:EndFarmEvent()
	CustomTimers.timers_paused = 2
	StopAllStormEarthFireSounds()
	if FragmentQuests ~= nil then
		FragmentQuests:OnFarmEventEnd()
		FragmentQuests:OnPhase2Start()
	end

	for _, hero in pairs(HeroList:GetAllHeroes()) do
		RefreshPlayers()

		if hero:IsRealHero() then
			if hero.old_pos then
				TeleportHero(hero, hero.old_pos, 3.0)
			else
				if hero:GetTeamNumber() == 2 then
					TeleportHero(hero, BASE_GOOD:GetAbsOrigin(), 3.0)
					-- elseif hero:GetTeamNumber() == 3 then
					-- TeleportHero(hero, base_bad:GetAbsOrigin(), 3.0)
				end
			end

			hero:Stop()
		end
	end

	local units = FindUnitsInRadius(DOTA_TEAM_CUSTOM_2, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for _, v in pairs(units) do
		if v:IsCreature() and v:HasMovementCapability() and v:GetUnitName() ~= "npc_dota_boss_lich_king" then
			UTIL_Remove(v)
		end
	end

	-- Start Phase 2
	for NumPlayers = 1, MAGNATAURS_TO_KILL * PlayerResource:GetPlayerCount() * CREEP_LANES_TYPE do
		local rax_spawner = Entities:FindByName(nil, "npc_dota_spawner_" .. NumPlayers)

		if rax_spawner then
			SpawnMagnataur(rax_spawner:GetAbsOrigin())
			print("npc_dota_spawner_" .. NumPlayers .. " removed.")
			rax_spawner.disabled = true
		end
	end

	if PHASE_2_QUEST_UNIT and IsValidEntity(PHASE_2_QUEST_UNIT) and PHASE_2_QUEST_UNIT:IsAlive() then
		PHASE_2_QUEST_UNIT:Kill(nil, nil)
		print("Dummy unit phase 2 killed, phase 2 begins.")
	else
		print("ERROR: DUMMY UNIT PHASE 2 INVALID!!!")
	end

	-- only set timers and update panorama, restart count down happens when magnataurs are killed
	CustomTimers.current_time["game_time"] = (XHS_SPECIAL_EVENT_INTERVAL * 2) - 1
	CustomTimers.current_time["special_event"] = XHS_SPECIAL_EVENT_INTERVAL + 1
	CustomTimers.current_time["special_wave"] = XHS_SPECIAL_WAVE_INTERVAL + 1

	CustomTimers:Countdown("game_time")
	CustomTimers:Countdown("special_event")
	CustomTimers:Countdown("special_wave")

	Notifications:TopToAll({ text = "Phase 2 begins! (Destroyer Magnataur launched)", duration = 10.0, style = { color = "red" } })

	GameMode.FarmEvent_occuring = false
end

function SpecialEvents:StartRameroAndBaristolEvent(hero)
	if IsInToolsMode() and hero == nil then
		hero = PlayerResource:GetSelectedHeroEntity(0)
	end

	local point = Entities:FindByName(nil, "npc_dota_muradin_player_1"):GetAbsOrigin()
	local delay = 5.0
	StopAllStormEarthFireSounds()
	CustomTimers.timers_paused = 2
	CustomTimers:HideSpecialWaveCountdown()
	GameMode.SpecialArena_occuring = true
	CustomTimers.current_time["special_arena"] = XHS_RAMERO_BARISTOL_TIME + delay
	BT_ENABLED = 0

	NotifySpecialArenaStarted(hero, "Ramero and Baristol")
	CinematicPauseCreeps(SPECIAL_EVENT_CINEMATIC_PAUSE_RAMP)
	CinematicPauseHeroesForDuration(SPECIAL_EVENT_CINEMATIC_PAUSE_RAMP, delay)
	TeleportHero(hero, point, delay)
	StartCinematicPauseCreepsWatch("xhs_ramero_baristol_creep_pause_watch", SPECIAL_EVENT_CINEMATIC_PAUSE_RAMP)

	Timers:CreateTimer(delay, function()
		SpecialEvents:RameroAndBaristolEvent(XHS_RAMERO_BARISTOL_TIME, hero)
	end)

	SpecialEvents.Ramero_trigger = 1

	hero.old_pos = hero:GetAbsOrigin()
end

function SpecialEvents:RameroAndBaristolEvent(time, hero) -- 500 kills
	local stun_duration = 5.0
	CustomTimers.current_time["special_arena"] = time
	BT_ENABLED = 0
	SpecialEvents.RameroDead = false
	SpecialEvents.BaristolDead = false
	SpecialEvents.RameroRewardHero = nil
	SpecialEvents.RameroRewardPending = false
	StunBuildings(time)
	CustomGameEventManager:Send_ServerToAllClients("show_timer_special_arena", {})
	CustomTimers:BroadcastTimer("special_arena")
	GameMode.SpecialArena_occuring = true
	if FragmentQuests ~= nil then
		FragmentQuests:OnArenaStart("ramero_baristol", time)
	end

	SpecialEvents.Ramero = CreateUnitByName("npc_ramero", Entities:FindByName(nil, "roshan_wp_4"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
	SpecialEvents.Ramero:AddNewModifier(SpecialEvents.Ramero, nil, "modifier_cinematic_pause", { duration = stun_duration, ramp_duration = SPECIAL_EVENT_CINEMATIC_PAUSE_RAMP })
	SpecialEvents.Ramero:SetAngles(0, 45, 0)

	SpecialEvents.Baristol = CreateUnitByName("npc_baristol", Entities:FindByName(nil, "roshan_wp_2"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
	SpecialEvents.Baristol:AddNewModifier(SpecialEvents.Baristol, nil, "modifier_cinematic_pause", { duration = stun_duration, ramp_duration = SPECIAL_EVENT_CINEMATIC_PAUSE_RAMP })
	SpecialEvents.Baristol:SetAngles(0, 325, 0)

	PlayStormEarthFireSound(SpecialEvents.Ramero)

	NotifySpecialArenaInstructions(hero, "npc_dota_hero_sven", "Kill Ramero and Baristol to get special items! Reward: Lightning Sword and Tome of Stats +250.")

	GameRules:GetGameModeEntity():SetContextThink("RameroAndBaristol", function()
		SpecialEvents:EndRameroAndBaristolEvent()

		return nil
	end, time)
end

function SpecialEvents:EndRameroAndBaristolEvent(bWin)
	if _G.RAMERO_ARTIFACT_PICKED == true then return end

	bWin = bWin == true or (SpecialEvents.RameroDead == true and SpecialEvents.BaristolDead == true)
	_G.RAMERO_ARTIFACT_PICKED = true
	if FragmentQuests ~= nil then
		FragmentQuests:OnArenaEnd("ramero_baristol", bWin)
	end

	local teleport_time = 3.0
	local mode = GameRules:GetGameModeEntity()

	mode:SetContextThink("RameroAndBaristol", nil, 0)

	RestartCreeps(teleport_time + 3.0)
	StopAllStormEarthFireSounds()
	UTIL_Remove(_G.RAMERO_DUMMY)
	UTIL_Remove(_G.BARISTOL_DUMMY)

	CustomGameEventManager:Send_ServerToAllClients("hide_timer_special_arena", {})

	if not SpecialEvents.Ramero:IsNull() or not SpecialEvents.Baristol:IsNull() then
		if not SpecialEvents.Ramero:IsNull() then UTIL_Remove(SpecialEvents.Ramero) end
		if not SpecialEvents.Baristol:IsNull() then UTIL_Remove(SpecialEvents.Baristol) end
	end

	if bWin then
		Notifications:TopToAll({ text = "Ramero and Baristol arena has been won!", duration = 5.0 })
		if SpecialEvents.RameroRewardPending == true and SpecialEvents.RameroRewardHero ~= nil then
			local rewardHero = SpecialEvents.RameroRewardHero
			Timers:CreateTimer(teleport_time + 0.3, function()
				if rewardHero ~= nil and IsValidEntity(rewardHero) and not rewardHero:IsNull() then
					DropNeutralItemAtPositionForHero("item_lightning_sword", rewardHero:GetAbsOrigin(), rewardHero, rewardHero:GetTeam(), true)
				end
			end)
		end
	else
		Notifications:TopToAll({ text = "Ramero and Baristol arena has been loss!", duration = 5.0 })
	end

	mode:SetContextThink(DoUniqueString("delay"), function()
		CustomTimers.timers_paused = 0
		BT_ENABLED = 1
	end, teleport_time)

	SpecialEvents:ReturnFromSpecialArena()
end

function SpecialEvents:StartSogatEvent(hero)
	local point = Entities:FindByName(nil, "npc_dota_muradin_player_1"):GetAbsOrigin()
	local delay = 5.0
	StopAllStormEarthFireSounds()
	CustomTimers.timers_paused = 2
	CustomTimers:HideSpecialWaveCountdown()
	GameMode.SpecialArena_occuring = true
	CustomTimers.current_time["special_arena"] = 120.0 + delay
	BT_ENABLED = 0

	NotifySpecialArenaStarted(hero, "Sogat")
	CinematicPauseCreeps(SPECIAL_EVENT_CINEMATIC_PAUSE_RAMP)
	CinematicPauseHeroesForDuration(SPECIAL_EVENT_CINEMATIC_PAUSE_RAMP, delay)
	StartCinematicPauseCreepsWatch("xhs_sogat_creep_pause_watch", SPECIAL_EVENT_CINEMATIC_PAUSE_RAMP)
	TeleportHero(hero, point, delay)

	Timers:CreateTimer(delay, function()
		SpecialEvents:SogatEvent(120.0, hero)
	end)

	SpecialEvents.Ramero_trigger = 2

	hero.old_pos = hero:GetAbsOrigin()
end

function SpecialEvents:SogatEvent(time, hero) -- 750 kills
	local stun_duration = 5.0
	CustomTimers.timers_paused = 2
	CustomTimers.current_time["special_arena"] = time
	BT_ENABLED = 0
	StunBuildings(time)
	CustomGameEventManager:Send_ServerToAllClients("show_timer_special_arena", {})
	CustomTimers:BroadcastTimer("special_arena")
	GameMode.SpecialArena_occuring = true
	if FragmentQuests ~= nil then
		FragmentQuests:OnArenaStart("sogat", time)
	end

	SpecialEvents.Sogat = CreateUnitByName("npc_ramero_2", Entities:FindByName(nil, "roshan_wp_4"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
	SpecialEvents.Sogat:AddNewModifier(SpecialEvents.Sogat, nil, "modifier_cinematic_pause", { duration = stun_duration, ramp_duration = SPECIAL_EVENT_CINEMATIC_PAUSE_RAMP })
	SpecialEvents.Sogat:SetAngles(0, 45, 0)
	PlayStormEarthFireSound(SpecialEvents.Sogat)
	NotifySpecialArenaInstructions(hero, "npc_dota_hero_sven", "Kill Sogat to get a special item! Reward: Ring of Superiority.")

	GameRules:GetGameModeEntity():SetContextThink("Sogat", function()
		SpecialEvents:EndSogatEvent()

		return nil
	end, time)
end

function SpecialEvents:EndSogatEvent(bWin)
	-- if _G.SOGAT_ARTIFACT_PICKED == true then return end -- if timer is not removed, uncomment this

	_G.SOGAT_ARTIFACT_PICKED = true
	if FragmentQuests ~= nil then
		FragmentQuests:OnArenaEnd("sogat", bWin == true)
	end

	local teleport_time = 3.0
	local mode = GameRules:GetGameModeEntity()

	mode:SetContextThink("Sogat", nil, 0)

	RestartCreeps(teleport_time + 3.0)
	StopAllStormEarthFireSounds()
	UTIL_Remove(_G.RAMERO_BIS_DUMMY)

	CustomGameEventManager:Send_ServerToAllClients("hide_timer_special_arena", {})

	if not SpecialEvents.Sogat:IsNull() then
		UTIL_Remove(SpecialEvents.Sogat)
	end

	if bWin then
		Notifications:TopToAll({ text = "Sogat arena has been won!", duration = 5.0 })
	else
		Notifications:TopToAll({ text = "Sogat arena has been loss!", duration = 5.0 })
	end

	mode:SetContextThink(DoUniqueString("delay"), function()
		CustomTimers.timers_paused = 0
		BT_ENABLED = 1
	end, teleport_time)

	SpecialEvents:ReturnFromSpecialArena()
end

function SpecialEvents:DuelEvent()
	CinematicPauseCreeps(SPECIAL_EVENT_CINEMATIC_PAUSE_RAMP)
	CinematicPauseHeroesForDuration(SPECIAL_EVENT_CINEMATIC_PAUSE_RAMP, 3.0)
	CustomGameEventManager:Send_ServerToAllClients("show_duel", {})

	Notifications:TopToAll({ text = "Fight your team mates until 1 team survives!", duration = 10.0, style = { color = "white" } })

	-- Initialize duel
	for _, hero in pairs(HeroList:GetAllHeroes()) do
		local ID = hero:GetPlayerID()
		local Gold = hero:GetGold()
		hero:SetRespawnsDisabled(true)
		if not hero:HasOwnerAbandoned() then
			if PlayerResource:IsValidPlayerID(hero:GetPlayerOwnerID()) and hero:IsRealHero() then
				if ID == 0 or ID == 2 or ID == 4 or ID == 6 then
					--					hero:SetTeam(DOTA_TEAM_CUSTOM_3)
					--					if hero:GetPlayerOwner() then
					--						hero:GetPlayerOwner():SetTeam(DOTA_TEAM_CUSTOM_3)
					--					end
				elseif ID == 1 or ID == 3 or ID == 5 or ID == 7 then
					hero:SetTeam(DOTA_TEAM_BADGUYS)
					if hero:GetPlayerOwner() then
						hero:GetPlayerOwner():SetTeam(DOTA_TEAM_BADGUYS)
					end
				end
				hero:SetGold(Gold, false)

				local point = Entities:FindByName(nil, "duel_event_" .. ID)
				TeleportHero(hero, point:GetAbsOrigin(), 3.0)

				-- Duel Settings
				hero:SetPhysicalArmorBaseValue(0 - hero:GetPhysicalArmorValue(false) * 0.80) -- Remove 80% of the heroes armor

				for itemSlot = 0, 14 do
					local item = hero:GetItemInSlot(itemSlot)
					if item then
						if item:GetName() == "item_health_potion" or item:GetName() == "item_mana_potion" or item:GetName() == "item_ankh_of_reincarnation" then
							hero:RemoveItem(item)
						end
					end
				end
			end
		else
			if hero:GetTeamNumber() == 2 then
				TeleportHero(hero, BASE_GOOD:GetAbsOrigin(), 3.0)
				-- elseif hero:GetTeamNumber() == 3 then
				-- TeleportHero(hero, base_bad:GetAbsOrigin(), 3.0)
			end
			Notifications:TopToAll({ text = "Disconnected hero detected, teleporting out of arena!", duration = 5.0, style = { color = "white" } })
		end
	end

	-- WIN Conditions
	local RadiantCheck = 0
	local DireCheck = 0
	timers.Duel = Timers:CreateTimer(1.0, function()
		local RadiantPlayers = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
		local DirePlayers = FindUnitsInRadius(DOTA_TEAM_BADGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
		local RadiantNumber = 0
		local DireNumber = 0

		--Count the number of players alive in each teams
		for _, unit in pairs(RadiantPlayers) do
			if unit:IsAlive() then
				RadiantNumber = RadiantNumber + 1
			end
		end
		for _, unit in pairs(DirePlayers) do
			if unit:IsAlive() then
				DireNumber = DireNumber + 1
			end
		end

		if RadiantNumber == 0 then --if a whole team is dead then
			RadiantCheck = RadiantCheck + 1
		elseif RadiantNumber > 0 then --elseif a player revives
			RadiantCheck = 0
		end
		if RadiantCheck >= 7 then --if a whole team is dead during 7 seconds then
			GameRules:SetGameWinner(DOTA_TEAM_BADGUYS)
			print("Dire Win!")
		end

		if DireNumber == 0 then
			DireCheck = DireCheck + 1
		elseif DireNumber > 0 then
			DireCheck = 0
		end
		if DireCheck >= 7 then
			GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
			print("Radiant Win!")
		end

		print("Radiant Check: " .. RadiantCheck)
		print("Dire Check: " .. DireCheck)
		print("Duel Score: " .. RadiantNumber .. "/" .. DireNumber)
		return 1.0
	end)
end

function SpecialEvents:DuelRanked()
	CinematicPauseCreeps(SPECIAL_EVENT_CINEMATIC_PAUSE_RAMP)
	CinematicPauseHeroesForDuration(SPECIAL_EVENT_CINEMATIC_PAUSE_RAMP, 3.0)
	--	CustomGameEventManager:Send_ServerToAllClients("show_duel", {})

	Notifications:TopToAll({ text = "It's Duel Time!", duration = 5.0, style = { color = "white" } })

	-- Initialize duel
	for _, hero in pairs(HeroList:GetAllHeroes()) do
		local ID = hero:GetPlayerID()
		hero:SetRespawnsDisabled(true)
		if PlayerResource:GetConnectionState() == 2 then
			if PlayerResource:IsValidPlayerID(hero:GetPlayerOwnerID()) and hero:IsRealHero() then
				local point = Entities:FindByName(nil, "duel_event_" .. ID)
				TeleportHero(hero, point:GetAbsOrigin(), 3.0)

				-- Duel Settings
				--				hero:SetPhysicalArmorBaseValue(0 - hero:GetPhysicalArmorValue(false)*0.80) -- Remove 80% of the heroes armor

				for itemSlot = 0, 14 do
					local item = hero:GetItemInSlot(itemSlot)
					if item then
						if item:GetName() == "item_health_potion" or item:GetName() == "item_mana_potion" or item:GetName() == "item_ankh_of_reincarnation" then
							hero:RemoveItem(item)
						end
					end
				end
			end
		else
			if hero:GetTeamNumber() == 2 then
				TeleportHero(hero, BASE_GOOD:GetAbsOrigin(), 3.0)
				-- elseif hero:GetTeamNumber() == 3 then
				-- TeleportHero(hero, base_bad:GetAbsOrigin(), 3.0)
			end
			Notifications:TopToAll({ text = "Disconnected hero detected, teleporting out of arena!", duration = 5.0, style = { color = "white" } })
		end
	end

	-- WIN Conditions
	local RadiantCheck = 0
	local DireCheck = 0
	timers.Duel = Timers:CreateTimer(1.0, function()
		local RadiantPlayers = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
		local DirePlayers = FindUnitsInRadius(DOTA_TEAM_BADGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
		local RadiantNumber = 0
		local DireNumber = 0

		--Count the number of players alive in each teams
		for _, unit in pairs(RadiantPlayers) do
			if unit:IsAlive() then
				RadiantNumber = RadiantNumber + 1
			end
		end
		for _, unit in pairs(DirePlayers) do
			if unit:IsAlive() then
				DireNumber = DireNumber + 1
			end
		end

		if RadiantNumber == 0 then --if a whole team is dead then
			RadiantCheck = RadiantCheck + 1
		elseif RadiantNumber > 0 then --elseif a player revives
			RadiantCheck = 0
		end
		if RadiantCheck >= 7 then --if a whole team is dead during 7 seconds then
			GameRules:SetGameWinner(DOTA_TEAM_BADGUYS)
			print("Dire Win!")
		end

		if DireNumber == 0 then
			DireCheck = DireCheck + 1
		elseif DireNumber > 0 then
			DireCheck = 0
		end
		if DireCheck >= 7 then
			GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
			print("Radiant Win!")
		end

		print("Radiant Check: " .. RadiantCheck)
		print("Dire Check: " .. DireCheck)
		print("Duel Score: " .. RadiantNumber .. "/" .. DireNumber)
		return 1.0
	end)
end

function SpecialEvents:ReturnFromSpecialArena()
	CustomTimers.timers_paused = 0
	CustomGameEventManager:Send_ServerToAllClients("hide_timer_special_arena", {})

	local SpecialArenaCheck = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, Entities:FindByName(nil, "npc_dota_muradin_boss"):GetAbsOrigin(), nil, 2000, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
	local returnedHero = false

	for _, hero in pairs(SpecialArenaCheck) do
		if hero:IsRealHero() then
			returnedHero = true
			print(hero:GetUnitName() .. " was in an arena when it ended, teleporting to base")

			local teleport_time = 3.0

			RestartCreeps(teleport_time + 3.0)

			if hero.old_pos then
				TeleportHero(hero, hero.old_pos, teleport_time)
			else
				if hero:GetTeamNumber() == 2 then
					TeleportHero(hero, BASE_GOOD:GetAbsOrigin(), 3.0)
					--		elseif hero:GetTeamNumber() == 3 then
					--			TeleportHero(hero, base_bad:GetAbsOrigin(), 3.0)
				end
			end

			hero:EmitSound("Hero_TemplarAssassin.Trap")

			GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("delay"), function()
				GameMode.SpecialArena_occuring = false
				CustomTimers:ResumeSpecialWaveCountdown()
			end, teleport_time + 1.0)
		end
	end

	if returnedHero ~= true then
		GameMode.SpecialArena_occuring = false
		CustomTimers:ResumeSpecialWaveCountdown()
	end
end
