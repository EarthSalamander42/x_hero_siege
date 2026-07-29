if not SpecialEvents then
	SpecialEvents = class({})
	SpecialEvents.hero_farm_event = {}
	SpecialEvents.Ramero_trigger = 0
end

require("boss_scripts/special_arena_ai")

local SPECIAL_EVENT_CINEMATIC_PAUSE_RAMP = 2.75
local CINEMATIC_EVENT_PRE_TELEPORT_DELAY = 4.0
local CINEMATIC_EVENT_POST_TELEPORT_HOLD = 1.5
local SPECIAL_EVENT_CAMERA_MOVE_DURATION = 1.25
local SPECIAL_EVENT_CAMERA_RETURN_DURATION = 0.85
local MURADIN_ENTRY_POST_TELEPORT_HOLD = 3.0
local MURADIN_EXIT_STUN_DURATION = 5.0
local MURADIN_TELEPORT_IN_DELAY = CINEMATIC_EVENT_PRE_TELEPORT_DELAY + CINEMATIC_EVENT_POST_TELEPORT_HOLD
local MURADIN_TELEPORT_IN_CHANNEL_DURATION = 2.8
local MURADIN_TELEPORT_ARRIVAL_EFFECT_DURATION = 0.8
local MURADIN_TELEPORT_OUT_DURATION = 3.0
local FARM_LEADERBOARD_NET_TABLE = "xhs_farm_leaderboard"
local FARM_LEADERBOARD_NET_KEY = "state"
local FARM_LEADERBOARD_UPDATE_INTERVAL = 0.5
local FARM_EVENT_CREEPS_PER_WAVE = 10
local FARM_EVENT_CELEBRATION_DURATION = 7.0
local FARM_EVENT_PRELOAD_INTERVAL = 0.1
local FARM_EVENT_SPAWN_RADIUS = 260
local FARM_EVENT_STAGING_ORIGIN = Vector(-15800, -15800, -2048)
local FARM_EVENT_WAVE_DAMAGE = { 125, 150, 175, 200, 225 }
local FARM_EVENT_ABILITY_BY_UNIT = {
	npc_dota_creature_murloc = "xhs_creep_blood_hunger",
	npc_dota_creature_wildkin = "xhs_creep_evasion",
	npc_dota_creature_golem = "neutral_spell_immunity",
	npc_dota_creature_centaur = "xhs_creep_thorns",
	npc_dota_creature_razormane = "creature_war_stomp",
	npc_dota_creature_revenant = "xhs_farm_howling_blast",
	npc_dota_creature_tuskarr = "xhs_creep_crippling_strike",
	npc_dota_creature_satyrr = "ogre_magi_bloodlust",
}
local FARM_EVENT_ACTIVE_ABILITIES = {
	creature_war_stomp = {
		cast_type = "no_target",
		trigger_range = 340,
		shared_lock = 4.0,
	},
	ogre_magi_bloodlust = {
		cast_type = "friendly_target",
		trigger_range = 650,
		shared_lock = 0.75,
		modifier = "modifier_ogre_magi_bloodlust",
	},
}
local FARM_EVENT_REWARDS = {
	npc_dota_creature_murloc = { gold_min = 550, gold_max = 650, xp = 45 },
	npc_dota_creature_wildkin = { gold_min = 250, gold_max = 300, xp = 45 },
	npc_dota_creature_golem = { gold_min = 250, gold_max = 300, xp = 45 },
	npc_dota_creature_polar_furbolg = { gold_min = 250, gold_max = 300, xp = 45 },
	npc_dota_creature_centaur = { gold_min = 250, gold_max = 300, xp = 45 },
	npc_dota_creature_razormane = { gold_min = 250, gold_max = 300, xp = 45 },
	npc_dota_creature_revenant = { gold_min = 250, gold_max = 300, xp = 45 },
	npc_dota_creature_tuskarr = { gold_min = 250, gold_max = 300, xp = 45 },
	npc_dota_creature_satyrr = { gold_min = 250, gold_max = 300, xp = 45 },
}

LinkLuaModifier(
	"modifier_xhs_farm_staged",
	"components/farm_event/modifiers.lua",
	LUA_MODIFIER_MOTION_NONE
)
LinkLuaModifier(
	"modifier_xhs_farm_suspended",
	"components/farm_event/modifiers.lua",
	LUA_MODIFIER_MOTION_NONE
)
LinkLuaModifier(
	"modifier_xhs_farm_wave_damage",
	"components/farm_event/modifiers.lua",
	LUA_MODIFIER_MOTION_NONE
)
local MURADIN_TELEPORT_START_PARTICLE = "particles/items2_fx/teleport_start.vpcf"
local MURADIN_TELEPORT_END_PARTICLE = "particles/items2_fx/teleport_end.vpcf"

local function IsValidAliveUnit(unit)
	return unit ~= nil and not unit:IsNull() and unit:IsAlive()
end

local function GetFarmEventHero(playerID)
	if playerID == nil or playerID < 0 or not PlayerResource:HasSelectedHero(playerID) then return nil end
	local hero = PlayerResource:GetSelectedHeroEntity(playerID)
	if not IsValidAliveUnit(hero) then return nil end
	return hero
end

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

local function GetHeroPlayerColor(hero)
	if hero == nil or hero:IsNull() or not hero.GetPlayerID then return "#ffffff" end

	local player_id = hero:GetPlayerID()
	local color = PLAYER_COLORS[player_id]
	if color == nil then return "#ffffff" end

	return string.format("#%02x%02x%02x", color[1] or 255, color[2] or 255, color[3] or 255)
end

local function NotifySpecialArenaStarted(hero, target_text)
	local hero_color = GetHeroPlayerColor(hero)
	local hero_unit_name = nil

	if hero ~= nil and not hero:IsNull() then
		hero_unit_name = hero:GetUnitName()
	end

	local segments = {}
	if hero_unit_name ~= nil and hero_unit_name ~= "" then
		table.insert(segments, { hero = hero_unit_name, imagestyle = "icon" })
		table.insert(segments, {
			text = "#" .. hero_unit_name,
			style = { color = hero_color },
			class = "XHSSpecialArenaText",
		})
	else
		table.insert(segments, {
			text = "A hero",
			style = { color = hero_color },
			class = "XHSSpecialArenaText",
		})
	end
	table.insert(segments, {
		text = " has reached the kill milestone and will fight " .. target_text .. "!",
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

local function StartCinematicDelayedTeleport(hero, point, delay)
	if hero == nil or hero:IsNull() or point == nil then return end

	Timers:CreateTimer(delay, function()
		if hero ~= nil and not hero:IsNull() then
			TeleportHero(hero, point, 0.0)
		end
		return nil
	end)
end

local function FocusAllPlayersOnSpecialArena(point, intro_duration, return_camera)
	if point == nil or XHSPlayDoorOpeningCinematic == nil then return end

	XHSPlayDoorOpeningCinematic({}, nil, {
		camera_position = point,
		move_duration = SPECIAL_EVENT_CAMERA_MOVE_DURATION,
		hold_duration = math.max(0, intro_duration - SPECIAL_EVENT_CAMERA_MOVE_DURATION),
		return_duration = SPECIAL_EVENT_CAMERA_RETURN_DURATION,
		return_camera = return_camera ~= false,
	})
end

local function DestroyMuradinTeleportParticle(particle)
	if particle == nil then return end
	ParticleManager:DestroyParticle(particle, false)
	ParticleManager:ReleaseParticleIndex(particle)
end

local function PlayMuradinTeleportIn(unit, spawn_position)
	if unit == nil or unit:IsNull() then return end

	local position = spawn_position or unit:GetAbsOrigin()
	unit:AddNoDraw()
	unit.xhs_teleport_in_revealed = false

	-- Wait until the hero teleport and the post-camera hold are both complete,
	-- then start the visible channel so the entire entrance is on screen.
	Timers:CreateTimer(MURADIN_TELEPORT_IN_DELAY, function()
		if unit == nil or unit:IsNull() then return nil end

		-- Match the final-wave boss entrance: teleport_end is the persistent
		-- channel while the boss remains hidden.
		local channel_particle = ParticleManager:CreateParticle(
			MURADIN_TELEPORT_END_PARTICLE,
			PATTACH_WORLDORIGIN,
			nil
		)
		ParticleManager:SetParticleControl(channel_particle, 0, position)
		ParticleManager:SetParticleControl(channel_particle, 1, position)
		unit.xhs_teleport_in_particle = channel_particle
		unit:EmitSound("Portal.Loop_Appear")

		Timers:CreateTimer(MURADIN_TELEPORT_IN_CHANNEL_DURATION, function()
			DestroyMuradinTeleportParticle(channel_particle)
			if unit ~= nil and not unit:IsNull() then
				unit.xhs_teleport_in_particle = nil
				unit:StopSound("Portal.Loop_Appear")
				unit:SetAbsOrigin(position)
				unit:RemoveNoDraw()
				unit.xhs_teleport_in_revealed = true

				-- The short teleport_start flash punctuates the exact frame on
				-- which Muradin becomes visible.
				local arrival_particle = ParticleManager:CreateParticle(
					MURADIN_TELEPORT_START_PARTICLE,
					PATTACH_ABSORIGIN_FOLLOW,
					unit
				)
				ParticleManager:SetParticleControl(arrival_particle, 0, position)
				ParticleManager:SetParticleControl(arrival_particle, 1, position)
				EmitSoundOnLocationWithCaster(position, "Portal.Hero_Appear", unit)

				Timers:CreateTimer(MURADIN_TELEPORT_ARRIVAL_EFFECT_DURATION, function()
					DestroyMuradinTeleportParticle(arrival_particle)
					return nil
				end)
			end
			return nil
		end)
		return nil
	end)
end

local function StartMuradinTeleportOut(unit)
	if unit == nil or unit:IsNull() or unit.xhs_teleport_out_started then return end

	unit.xhs_teleport_out_started = true
	unit:AddNewModifier(unit, nil, "modifier_cinematic_pause", {
		duration = MURADIN_TELEPORT_OUT_DURATION,
		ramp_duration = 0,
	})

	local particle = ParticleManager:CreateParticle(MURADIN_TELEPORT_START_PARTICLE, PATTACH_ABSORIGIN_FOLLOW, unit)
	unit:EmitSound("Portal.Loop_Appear")

	Timers:CreateTimer(MURADIN_TELEPORT_OUT_DURATION, function()
		if unit ~= nil and not unit:IsNull() then
			local position = unit:GetAbsOrigin()
			unit:StopSound("Portal.Loop_Appear")
			EmitSoundOnLocationWithCaster(position, "Portal.Hero_Disappear", unit)
			unit:AddNoDraw()
		end

		ParticleManager:DestroyParticle(particle, false)
		ParticleManager:ReleaseParticleIndex(particle)
		return nil
	end)
end

local function StartSpecialArenaCinematicIntro(hero, point, creep_watch_name, on_complete, return_camera)
	local intro_duration = CINEMATIC_EVENT_PRE_TELEPORT_DELAY + CINEMATIC_EVENT_POST_TELEPORT_HOLD

	CinematicPauseCreeps(SPECIAL_EVENT_CINEMATIC_PAUSE_RAMP)
	CinematicPauseHeroesForDuration(SPECIAL_EVENT_CINEMATIC_PAUSE_RAMP, intro_duration)
	StartCinematicPauseCreepsWatch(creep_watch_name, SPECIAL_EVENT_CINEMATIC_PAUSE_RAMP)

	FocusAllPlayersOnSpecialArena(point, intro_duration, return_camera)
	StartCinematicDelayedTeleport(hero, point, CINEMATIC_EVENT_PRE_TELEPORT_DELAY)

	Timers:CreateTimer(intro_duration, function()
		if on_complete ~= nil then
			on_complete()
		end
	end)

	return intro_duration
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
	SpecialEvents.stormEarthFireSoundGeneration = (SpecialEvents.stormEarthFireSoundGeneration or 0) + 1
	SpecialEvents.stormEarthFirePlaying = false

	-- Clean up a global instance left by the previous implementation.
	StopGlobalSound(STORM_EARTH_FIRE_SOUND)

	if SpecialEvents.stormEarthFireEmitters ~= nil then
		for _, info in pairs(SpecialEvents.stormEarthFireEmitters) do
			if info ~= nil then
				StopStormEarthFireSound(info.entity)

				if info.temporary == true
					and info.entity ~= nil
					and IsValidEntity(info.entity)
					and not info.entity:IsNull()
				then
					local emitter = info.entity
					GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("farm_music_emitter_cleanup"), function()
						if emitter ~= nil and IsValidEntity(emitter) and not emitter:IsNull() then
							UTIL_Remove(emitter)
						end
						return nil
					end, 5.0)
				end
			end
		end
	end

	SpecialEvents.stormEarthFireEmitters = {}
end

local function PlayStormEarthFireSound(entity, emitterKey, temporary)
	if entity == nil or not IsValidEntity(entity) or entity:IsNull() then return end

	emitterKey = emitterKey or "boss"
	SpecialEvents.stormEarthFireEmitters = SpecialEvents.stormEarthFireEmitters or {}

	local current = SpecialEvents.stormEarthFireEmitters[emitterKey]
	if current ~= nil
		and current.entity ~= nil
		and IsValidEntity(current.entity)
		and not current.entity:IsNull()
	then
		return
	end

	-- Never bind long event music to a boss: if it dies first, Source can keep
	-- the sound on an entindex that is later recycled by a creep. A dedicated
	-- invulnerable emitter remains valid until the event cleanup stops it.
	SpecialEvents.stormEarthFirePlaying = true

	local generation = SpecialEvents.stormEarthFireSoundGeneration
	local emitter = temporary ~= true and SpecialEvents.stormEarthFireEmitter or nil
	if emitter == nil or not IsValidEntity(emitter) or emitter:IsNull() then
		emitter = CreateUnitByName(
			"dummy_unit_invulnerable",
			entity:GetAbsOrigin(),
			false,
			nil,
			nil,
			DOTA_TEAM_GOODGUYS
		)
		if emitter == nil then
			return
		end

		emitter:AddNewModifier(emitter, nil, "modifier_invulnerable", {})
		emitter:AddNewModifier(emitter, nil, "modifier_phased", {})
		emitter:AddNoDraw()
		if temporary ~= true then
			SpecialEvents.stormEarthFireEmitter = emitter
		end
	else
		emitter:SetAbsOrigin(entity:GetAbsOrigin())
	end

	SpecialEvents.stormEarthFireEmitters[emitterKey] = {
		entity = emitter,
		temporary = temporary == true,
	}

	-- StopGlobalSound and replaying the same event in one frame can suppress the
	-- new instance. Start it on the next frame after the legacy cleanup.
	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("storm_earth_fire_play"), function()
		local registered = SpecialEvents.stormEarthFireEmitters
			and SpecialEvents.stormEarthFireEmitters[emitterKey]
		if SpecialEvents.stormEarthFireSoundGeneration ~= generation
			or registered == nil
			or registered.entity ~= emitter
			or emitter == nil
			or not IsValidEntity(emitter)
			or emitter:IsNull()
		then
			return nil
		end

		EmitSoundOn(STORM_EARTH_FIRE_SOUND, emitter)
		return nil
	end, 0.03)
end

function SpecialEvents:MuradinEvent(time)
	-- Keep Muradin anchored after the visible teleport completes so his arrival
	-- has time to land before the AI starts issuing movement orders.
	local stun_duration = MURADIN_TELEPORT_IN_DELAY
		+ MURADIN_TELEPORT_IN_CHANNEL_DURATION
		+ MURADIN_ENTRY_POST_TELEPORT_HOLD
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

	local muradin_spawn = Entities:FindByName(nil, "npc_dota_muradin_boss")
	local muradin_spawn_position = muradin_spawn:GetAbsOrigin()
	local Muradin = CreateUnitByName("npc_dota_creature_muradin_bronzebeard", muradin_spawn_position, true, nil, nil, DOTA_TEAM_CUSTOM_2)
	Muradin:AddNewModifier(Muradin, nil, "modifier_cinematic_pause", { duration = stun_duration, ramp_duration = SPECIAL_EVENT_CINEMATIC_PAUSE_RAMP })
	Muradin:SetAngles(0, 270, 0)
	PlayMuradinTeleportIn(Muradin, muradin_spawn_position)
	Notifications:TopToAll({
		duration = stun_duration,
		segments = {
			{ hero = "npc_dota_hero_zuus" },
			{ text = "You can't kill him! Just survive the Countdown. Reward: 20 000 Gold." },
		},
	})

	-- EmitSoundOn("SantaClaus.StartArena", Muradin) -- todo: add a variable in game-register endpoint to enable/disable this sound during december

	for nPlayerID = 0, PlayerResource:GetPlayerCount() - 1 do
		if PlayerResource:HasSelectedHero(nPlayerID) and PlayerResource:GetSelectedHeroEntity(nPlayerID) ~= "npc_dota_hero_wisp" then
			local hero = PlayerResource:GetSelectedHeroEntity(nPlayerID)

			if hero and not hero:IsNull() and hero:IsRealHero() and not hero:HasModifier("modifier_fountain_invulnerability") then
				hero.old_pos = hero:GetAbsOrigin()
				CreateXHSReturnMarker(hero, hero.old_pos)
				local id = hero:GetPlayerID()
				local point = Entities:FindByName(nil, "npc_dota_muradin_player_" .. id)

				DisableItems(hero, event_end_delay)
				if point ~= nil then
					StartCinematicDelayedTeleport(hero, point:GetAbsOrigin(), CINEMATIC_EVENT_PRE_TELEPORT_DELAY)
				end
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
		RestartCreeps(MURADIN_EXIT_STUN_DURATION)
		Notifications:TopToAll({ text = "Special Events are unlocked!", style = { color = "DodgerBlue" }, duration = 5.0 })
		Entities:FindByName(nil, "trigger_special_event_tp_off"):Disable()
		Entities:FindByName(nil, "trigger_special_event"):Enable()
		HideCurrentEventTimer()
		UpdateGlobalObjective("muradin_event", "Completed", "Muradin Event completed", nil, true)
		UpdateGlobalObjective("farm_event", "Active", "Farm Event in --:--", nil)
		CustomGameEventManager:Send_ServerToAllClients("update_special_event_label_farm", {})
		StopAllStormEarthFireSounds()
		StartMuradinTeleportOut(Muradin)
		SpecialEvents:EndMuradinEvent()
		if CustomTimers.special_waves_disabled ~= true then
			SpecialWave(3)
		end
		CinematicPauseGame(SPECIAL_EVENT_CINEMATIC_PAUSE_RAMP, MURADIN_EXIT_STUN_DURATION)

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

local function GetFarmEventWaveCount()
	return math.max(1, #(FarmEvent_Creeps or {}))
end

function SpecialEvents:PublishFarmLeaderboard(active)
	local wavesPerLevel = GetFarmEventWaveCount()
	local players = {}

	for playerID, progress in pairs(self.hero_farm_event or {}) do
		local numericPlayerID = tonumber(playerID)
		if type(progress) == "table" and numericPlayerID ~= nil then
			local level = math.max(1, tonumber(progress.level) or 1)
			local round = math.max(0, tonumber(progress.round) or 0) % wavesPerLevel
			local remaining = math.max(0, tonumber(progress.remaining) or 0)
			local completedWaves = math.max(0, tonumber(progress.completed_waves) or 0)

			table.insert(players, {
				player_id = numericPlayerID,
				kills = math.max(0, tonumber(progress.kills) or 0),
				level = level,
				wave = round + 1,
				waves_per_level = wavesPerLevel,
				remaining = remaining,
				completed_waves = completedWaves,
				last_wave_gold = math.max(0, tonumber(progress.last_wave_gold) or 0),
				last_wave_xp = math.max(0, tonumber(progress.last_wave_xp) or 0),
				reward_serial = math.max(0, tonumber(progress.reward_serial) or 0),
			})
		end
	end

	table.sort(players, function(a, b)
		if a.kills ~= b.kills then
			return a.kills > b.kills
		end
		if a.completed_waves ~= b.completed_waves then
			return a.completed_waves > b.completed_waves
		end
		if a.remaining ~= b.remaining then
			return a.remaining < b.remaining
		end
		return a.player_id < b.player_id
	end)

	for rank, player in ipairs(players) do
		player.rank = rank
	end

	local phase = self.farm_event_leaderboard_phase or (active == true and "active" or "archived")
	if phase == "active" then
		self.farm_event_final_players = players
	elseif self.farm_event_final_players ~= nil then
		players = self.farm_event_final_players
	end

	local winner = players[1]

	CustomNetTables:SetTableValue(FARM_LEADERBOARD_NET_TABLE, FARM_LEADERBOARD_NET_KEY, {
		active = active == true,
		available = #players > 0,
		phase = phase,
		winner_player_id = winner and winner.player_id or -1,
		winner_kills = winner and winner.kills or 0,
		celebration_duration = FARM_EVENT_CELEBRATION_DURATION,
		waves_per_level = wavesPerLevel,
		creeps_per_wave = FARM_EVENT_CREEPS_PER_WAVE,
		players = players,
		updated_at = GameRules:GetGameTime(),
	})
	self.farm_leaderboard_dirty = false
end

function SpecialEvents:GetFarmEventActiveUnits(playerID)
	local progress = self.hero_farm_event and self.hero_farm_event[tonumber(playerID)] or nil
	return progress and progress.active_units or {}
end

function SpecialEvents:GetFarmEventAbilityConfig(abilityName)
	return FARM_EVENT_ACTIVE_ABILITIES[abilityName]
end

function SpecialEvents:GetFarmEventAbilityLock(playerID, abilityName)
	local key = tostring(playerID) .. ":" .. tostring(abilityName)
	return self.farm_event_ability_locks and self.farm_event_ability_locks[key] or 0
end

function SpecialEvents:SetFarmEventAbilityLock(playerID, abilityName, nextCastTime)
	self.farm_event_ability_locks = self.farm_event_ability_locks or {}
	local key = tostring(playerID) .. ":" .. tostring(abilityName)
	self.farm_event_ability_locks[key] = tonumber(nextCastTime) or 0
end

function SpecialEvents:StartFarmLeaderboardPublisher()
	local mode = GameRules:GetGameModeEntity()
	mode:SetContextThink("xhs_farm_leaderboard_publish", function()
		if GameMode.FarmEvent_occuring ~= true then
			if self.farm_event_leaderboard_phase == "celebration" then
				return nil
			end
			self:PublishFarmLeaderboard(false)
			return nil
		end

		if self.farm_leaderboard_dirty == true then
			self:PublishFarmLeaderboard(true)
		end
		return FARM_LEADERBOARD_UPDATE_INTERVAL
	end, 0.0)
end

function SpecialEvents:RemoveFarmEventCreeps()
	for _, progress in pairs(self.hero_farm_event or {}) do
		progress.prep_token = (progress.prep_token or 0) + 1
		for _, collection in ipairs({ progress.active_units or {}, progress.prepared_units or {} }) do
			for _, unit in ipairs(collection) do
				if unit ~= nil and not unit:IsNull() then
					UTIL_Remove(unit)
				end
			end
		end
		progress.active_units = {}
		progress.prepared_units = {}
		progress.remaining = 0
	end
end

function SpecialEvents:SuspendNonFarmCreeps()
	self.farm_suspended_units = {}
	local units = FindUnitsInRadius(
		DOTA_TEAM_CUSTOM_1,
		Vector(0, 0, 0),
		nil,
		FIND_UNITS_EVERYWHERE,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
		FIND_ANY_ORDER,
		false
	)
	for _, unit in ipairs(units) do
		if IsValidAliveUnit(unit)
			and unit.xhs_farm_event ~= true
			and unit:HasModifier("modifier_ai") then
			unit:SetForceAttackTarget(nil)
			unit:Stop()
			unit:AddNewModifier(unit, nil, "modifier_xhs_farm_suspended", {})
			table.insert(self.farm_suspended_units, unit)
		end
	end
end

function SpecialEvents:ResumeNonFarmCreeps()
	for _, unit in ipairs(self.farm_suspended_units or {}) do
		if IsValidAliveUnit(unit) then
			unit:RemoveModifierByName("modifier_xhs_farm_suspended")
		end
	end
	self.farm_suspended_units = {}
end

local function GetNextFarmWave(round, level)
	local count = GetFarmEventWaveCount()
	local nextRound = (math.max(0, tonumber(round) or 0) + 1) % count
	local nextLevel = math.max(1, tonumber(level) or 1)
	if nextRound == 0 then nextLevel = nextLevel + 1 end
	return nextRound, nextLevel
end

local function GetFarmSpawnPosition(point, index)
	local angle = ((math.max(1, index) - 1) / FARM_EVENT_CREEPS_PER_WAVE) * math.pi * 2
	local radius = FARM_EVENT_SPAWN_RADIUS + ((index % 2) * 45)
	return point:GetAbsOrigin() + Vector(math.cos(angle) * radius, math.sin(angle) * radius, 0)
end

function SpecialEvents:ConfigureFarmEventUnit(unit, playerID, difficulty, staged)
	if not IsValidAliveUnit(unit) then return end

	unit.xhs_farm_event = true
	unit.xhs_farm_event_player_id = playerID
	unit.xhs_farm_staged = staged == true
	if unit.SetMinimumGoldBounty ~= nil then unit:SetMinimumGoldBounty(0) end
	if unit.SetMaximumGoldBounty ~= nil then unit:SetMaximumGoldBounty(0) end
	if unit.SetDeathXP ~= nil then unit:SetDeathXP(0) end
	if unit.SetIdleAcquire ~= nil then unit:SetIdleAcquire(false) end

	local reward = FARM_EVENT_REWARDS[unit:GetUnitName()] or {}
	unit.xhs_farm_reward_gold = RandomInt(
		tonumber(reward.gold_min) or 0,
		tonumber(reward.gold_max) or tonumber(reward.gold_min) or 0
	)
	unit.xhs_farm_reward_xp = tonumber(reward.xp) or 0

	local abilityName = FARM_EVENT_ABILITY_BY_UNIT[unit:GetUnitName()]
	if abilityName ~= nil then
		local ability = unit:FindAbilityByName(abilityName)
		if ability == nil then ability = unit:AddAbility(abilityName) end
		if ability ~= nil then
			local maxLevel = math.max(1, ability:GetMaxLevel())
			ability:SetLevel(math.min(math.max(1, tonumber(difficulty) or 1), maxLevel))
		else
			print("[XHS][FarmEvent] Failed to add " .. abilityName .. " to " .. unit:GetUnitName())
		end
	end

	if staged == true then
		unit:AddNoDraw()
		unit:AddNewModifier(unit, nil, "modifier_xhs_farm_staged", {})
	end
end

function SpecialEvents:CreateFarmEventUnit(playerID, round, level, staged, index)
	local progress = self.hero_farm_event[playerID]
	local point = progress and progress.point or nil
	local unitName = FarmEvent_Creeps[math.max(0, round) + 1]
	if point == nil or unitName == nil then return nil end

	local position = staged == true
		and (FARM_EVENT_STAGING_ORIGIN + Vector(playerID * 96, (index or 1) * 32, 0))
		or GetFarmSpawnPosition(point, index or 1)
	local unit = CreateUnitByName(unitName, position, true, nil, nil, DOTA_TEAM_CUSTOM_2)
	if not IsValidAliveUnit(unit) then return nil end

	local difficulty = GameRules:GetCustomGameDifficulty()
	local damageBonus = FARM_EVENT_UPGRADE.damage[difficulty] * level
	local healthBonus = FARM_EVENT_UPGRADE.health[difficulty] * level
	local armorBonus = FARM_EVENT_UPGRADE.armor[difficulty] * level
	local firstWave = round == 0 and level == 1 and (progress.completed_waves or 0) == 0
	local minimumFactor = firstWave and 1.0 or 0.95
	local maximumFactor = firstWave and 1.1 or 1.05
	unit:SetBaseDamageMin(unit:GetRealDamageDone(unit) + damageBonus * minimumFactor)
	unit:SetBaseDamageMax(unit:GetRealDamageDone(unit) + damageBonus * maximumFactor)
	local maxHealth = unit:GetMaxHealth() + healthBonus
	unit:SetBaseMaxHealth(maxHealth)
	unit:SetMaxHealth(maxHealth)
	unit:SetHealth(maxHealth)
	unit:SetPhysicalArmorBaseValue(unit:GetPhysicalArmorValue(false) + armorBonus)
	self:ConfigureFarmEventUnit(unit, playerID, difficulty, staged)
	return unit
end

function SpecialEvents:PrepareFarmEventWave(playerID, round, level)
	local progress = self.hero_farm_event[playerID]
	if progress == nil or progress.point == nil then return end

	progress.prep_token = (progress.prep_token or 0) + 1
	local token = progress.prep_token
	local generation = self.farm_event_generation
	progress.prepared_units = {}
	progress.prepared_round = round
	progress.prepared_level = level

	Timers:CreateTimer(0, function()
		if GameMode.FarmEvent_occuring ~= true
			or self.farm_event_generation ~= generation
			or progress.prep_token ~= token then
			return nil
		end

		local index = #progress.prepared_units + 1
		if index > FARM_EVENT_CREEPS_PER_WAVE then return nil end
		local unit = self:CreateFarmEventUnit(playerID, round, level, true, index)
		if unit ~= nil then table.insert(progress.prepared_units, unit) end
		return #progress.prepared_units < FARM_EVENT_CREEPS_PER_WAVE
			and FARM_EVENT_PRELOAD_INTERVAL or nil
	end)
end

function SpecialEvents:ActivateFarmEventWave(playerID, round, level)
	local progress = self.hero_farm_event[playerID]
	if progress == nil or progress.point == nil then return end
	progress.prep_token = (progress.prep_token or 0) + 1

	local prepared = {}
	if progress.prepared_round == round and progress.prepared_level == level then
		prepared = progress.prepared_units or {}
	else
		for _, unit in ipairs(progress.prepared_units or {}) do
			if unit ~= nil and not unit:IsNull() then UTIL_Remove(unit) end
		end
	end

	progress.round = round
	progress.level = level
	progress.active_units = {}
	progress.prepared_units = {}
	progress.prepared_round = nil
	progress.prepared_level = nil
	progress.transitioning = false

	for index = 1, FARM_EVENT_CREEPS_PER_WAVE do
		local unit = prepared[index]
		if not IsValidAliveUnit(unit) then
			unit = self:CreateFarmEventUnit(playerID, round, level, false, index)
		else
			unit.xhs_farm_staged = false
			unit:SetAbsOrigin(GetFarmSpawnPosition(progress.point, index))
			unit:RemoveModifierByName("modifier_xhs_farm_staged")
			unit:RemoveNoDraw()
			FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
		end

		if IsValidAliveUnit(unit) then
			if unit:GetUnitName() == "npc_dota_creature_polar_furbolg" then
				unit:AddNewModifier(unit, nil, "modifier_xhs_farm_wave_damage", {
					damage_pct = FARM_EVENT_WAVE_DAMAGE[
						math.min(#FARM_EVENT_WAVE_DAMAGE, math.max(1, GameRules:GetCustomGameDifficulty()))
					],
				})
			end
			if not unit:HasModifier("modifier_ai") then
				unit:AddNewModifier(unit, nil, "modifier_ai", { state = 5 })
			end
			local hero = GetFarmEventHero(playerID)
			if hero ~= nil then unit:SetForceAttackTarget(hero) end
			table.insert(progress.active_units, unit)
		end
	end

	progress.remaining = #progress.active_units
	self.farm_leaderboard_dirty = true
	self:PublishFarmLeaderboard(true)
	local nextRound, nextLevel = GetNextFarmWave(round, level)
	self:PrepareFarmEventWave(playerID, nextRound, nextLevel)
end

function SpecialEvents:PayFarmEventWaveRewards(playerID, progress)
	if progress == nil then return end
	playerID = tonumber(playerID)
	local gold = math.max(0, math.floor(tonumber(progress.pending_wave_gold) or 0))
	local xp = math.max(0, math.floor(tonumber(progress.pending_wave_xp) or 0))
	if gold <= 0 and xp <= 0 then return end

	local validPlayer = playerID ~= nil and PlayerResource:IsValidPlayerID(playerID)
	local player = validPlayer and PlayerResource:GetPlayer(playerID) or nil
	if gold > 0 and validPlayer then
		PlayerResource:ModifyGold(playerID, gold, false, DOTA_ModifyGold_CreepKill)
	end
	-- XP must still be paid if the wave ends while the owning hero is dead.
	local hero = validPlayer and PlayerResource:GetSelectedHeroEntity(playerID) or nil
	if xp > 0 and hero ~= nil then
		hero:AddExperience(xp, DOTA_ModifyXP_CreepKill, false, true)
	end
	-- One compact reward burst per completed wave replaces ten kill-time
	-- overhead messages and their associated client work.
	if hero ~= nil and player ~= nil then
		if gold > 0 then
			SendOverheadEventMessage(player, OVERHEAD_ALERT_GOLD, hero, gold, player)
		end
		if xp > 0 then
			SendOverheadEventMessage(player, OVERHEAD_ALERT_XP, hero, xp, player)
		end
	end
	progress.pending_wave_gold = 0
	progress.pending_wave_xp = 0
	progress.last_wave_gold = gold
	progress.last_wave_xp = xp
	progress.reward_serial = (progress.reward_serial or 0) + 1
end

function SpecialEvents:OnFarmEventCreepKilled(killedUnit)
	if GameMode.FarmEvent_occuring ~= true
		or killedUnit == nil
		or killedUnit:IsNull()
		or killedUnit.xhs_farm_event ~= true
		or killedUnit.xhs_farm_staged == true
		or killedUnit.xhs_farm_kill_counted == true then
		return
	end

	killedUnit.xhs_farm_kill_counted = true
	local playerID = tonumber(killedUnit.xhs_farm_event_player_id)
	local progress = playerID ~= nil and self.hero_farm_event[playerID] or nil
	if progress == nil then return end

	progress.kills = math.max(0, tonumber(progress.kills) or 0) + 1
	progress.remaining = math.max(0, (tonumber(progress.remaining) or 0) - 1)
	progress.pending_wave_gold = (progress.pending_wave_gold or 0)
		+ math.max(0, tonumber(killedUnit.xhs_farm_reward_gold) or 0)
	progress.pending_wave_xp = (progress.pending_wave_xp or 0)
		+ math.max(0, tonumber(killedUnit.xhs_farm_reward_xp) or 0)
	self.farm_leaderboard_dirty = true

	if progress.remaining > 0 or progress.transitioning == true then return end
	progress.transitioning = true
	self:PayFarmEventWaveRewards(playerID, progress)
	progress.completed_waves = (progress.completed_waves or 0) + 1
	local nextRound, nextLevel = GetNextFarmWave(progress.round, progress.level)
	local generation = self.farm_event_generation
	Timers:CreateTimer(0, function()
		if GameMode.FarmEvent_occuring == true and self.farm_event_generation == generation then
			self:ActivateFarmEventWave(playerID, nextRound, nextLevel)
		end
	end)
end

function SpecialEvents:BeginFarmEventCelebration(duration)
	duration = math.max(0, tonumber(duration) or FARM_EVENT_CELEBRATION_DURATION)

	for playerID, progress in pairs(self.hero_farm_event or {}) do
		self:PayFarmEventWaveRewards(tonumber(playerID), progress)
	end
	-- Capture the last combat frame before removing units so remaining-creep
	-- tie breakers cannot be changed by cleanup.
	self:PublishFarmLeaderboard(true)
	self.farm_event_leaderboard_phase = "celebration"
	GameMode.FarmEvent_occuring = false
	CustomTimers.timers_paused = 2
	StopAllStormEarthFireSounds()
	self:PublishFarmLeaderboard(true)
	self:RemoveFarmEventCreeps()

	for _, hero in pairs(HeroList:GetAllHeroes()) do
		if hero:IsRealHero() then
			hero:Stop()
			DisableItems(hero, duration)
		end
	end
end

function SpecialEvents:FarmEvent(time)
	local difficulty = GameRules:GetCustomGameDifficulty()
	local tp_delay = CINEMATIC_EVENT_PRE_TELEPORT_DELAY
	local start_delay = tp_delay + CINEMATIC_EVENT_POST_TELEPORT_HOLD

	StopAllStormEarthFireSounds()
	CustomTimers.current_time["special_event"] = time
	CustomTimers.timers_paused = 1
	CustomTimers.enable_special_wave = false
	CustomTimers:HideSpecialWaveCountdown()
	BT_ENABLED = 0
	GameMode.FarmEvent_occuring = true
	SpecialEvents.hero_farm_event = {}
	self.farm_event_ability_locks = {}
	self.farm_event_final_players = nil
	self.farm_event_leaderboard_phase = "active"
	self.farm_event_generation = (self.farm_event_generation or 0) + 1
	self.farm_exit_wave_scheduled = false
	self.farm_exit_wave_spawned = false
	self:SuspendNonFarmCreeps()
	self:StartFarmLeaderboardPublisher()
	ShowCurrentEventTimer("FARM EVENT", time)
	UpdateGlobalObjective("farm_event", "Active", "Farm Event active", time)
	if FragmentQuests ~= nil then
		FragmentQuests:OnFarmEventStart(time)
	end

	StunBuildings(time)
	CinematicPauseGame(SPECIAL_EVENT_CINEMATIC_PAUSE_RAMP)

	for _, v in pairs(HeroList:GetAllHeroes()) do
		if v:IsRealHero() then
			local nPlayerID = v:GetPlayerID()
			local point = Entities:FindByName(nil, "farm_event_player_" .. nPlayerID)

			if nPlayerID >= 0 then
				v.old_pos = v:GetAbsOrigin()
				CreateXHSReturnMarker(v, v.old_pos)
				if point ~= nil then
					StartCinematicDelayedTeleport(v, point:GetAbsOrigin(), tp_delay)
				end
				if point ~= nil and v:GetUnitName() ~= "npc_dota_hero_wisp" then
					self.hero_farm_event[nPlayerID] = {
						round = 0,
						level = 1,
						kills = 0,
						completed_waves = 0,
						remaining = 0,
						active_units = {},
						prepared_units = {},
						pending_wave_gold = 0,
						pending_wave_xp = 0,
						reward_serial = 0,
						point = point,
						prep_token = 0,
					}
					self:PrepareFarmEventWave(nPlayerID, 0, 1)
				end
			end
		end
	end
	self.farm_leaderboard_dirty = true
	self:PublishFarmLeaderboard(true)

	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("farm_event"), function()
		Notifications:TopToAll({
			duration = 5.0,
			segments = {
				{ hero = "npc_dota_hero_alchemist" },
				{ text = "It's farming time! Kill as many creeps as you can!" },
			},
		})

		RestartHeroes()

		for nPlayerID, progress in pairs(SpecialEvents.hero_farm_event or {}) do
			local hero = GetFarmEventHero(tonumber(nPlayerID))
			if hero ~= nil and progress.point ~= nil then
				PlayStormEarthFireSound(progress.point, "farm_" .. nPlayerID, true)
				DisableItems(hero, time)
				SpecialEvents:ActivateFarmEventWave(tonumber(nPlayerID), 0, 1)
			end
		end
	end, start_delay)

	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("muradin_event"), function()
		if CustomTimers.special_waves_disabled == true then return nil end

		-- The farm event pauses the shared special-wave timer. Use a local 30-second
		-- countdown because this warning fires at time - 20 and the wave spawns at time + 10.
		CustomTimers:ShowSpecialWaveCountdown(6, 30, false)
		if Runes and Runes.OnSpecialWaveWarning then
			Runes:OnSpecialWaveWarning(6, CustomTimers:GetSpecialWavePoint(6))
		end

		return nil
	end, time - 20)

	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("muradin_event"), function()
		SpecialEvents:BeginFarmEventCelebration(FARM_EVENT_CELEBRATION_DURATION)
		HideCurrentEventTimer()
		UpdateGlobalObjective("farm_event", "Completed", "Farm Event completed", nil)
		CustomGameEventManager:Send_ServerToAllClients("update_special_event_label_final", {})

		return nil
	end, time)

	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("farm_event_celebration_end"), function()
		BT_ENABLED = 1
		SpecialEvents:EndFarmEvent()
		return nil
	end, time + FARM_EVENT_CELEBRATION_DURATION)

end

function SpecialEvents:EndFarmEvent()
	CustomTimers.timers_paused = 2
	StopAllStormEarthFireSounds()
	self:ResumeNonFarmCreeps()
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

	-- The sixth special wave is coupled to the end of the 3-second return TP.
	-- Keep a single idempotent owner so duplicate Farm callbacks cannot advance
	-- the global index and spawn wave 7 from the same north lane.
	if self.farm_exit_wave_scheduled ~= true then
		self.farm_exit_wave_scheduled = true
		local farmEventGeneration = self.farm_event_generation
		Timers:CreateTimer(3.0, function()
			if self.farm_event_generation ~= farmEventGeneration then return nil end

			RestartCreeps(0.0)

			if CustomTimers.special_waves_disabled ~= true
				and self.farm_exit_wave_spawned ~= true
				and CustomTimers.special_wave == 6
			then
				self.farm_exit_wave_spawned = true
				SpecialWave(6)
			end

			return nil
		end)
	end

	local units = FindUnitsInRadius(DOTA_TEAM_CUSTOM_2, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for _, v in pairs(units) do
		if v:IsCreature() and v:HasMovementCapability() and v:GetUnitName() ~= "npc_dota_boss_lich_king" then
			UTIL_Remove(v)
		end
	end

	-- Start Phase 2
	local combatParticipants = GetXHSCombatParticipantCount ~= nil
		and GetXHSCombatParticipantCount()
		or PlayerResource:GetPlayerCount()
	for NumPlayers = 1, MAGNATAURS_TO_KILL * combatParticipants * CREEP_LANES_TYPE do
		local rax_spawner = Entities:FindByName(nil, "npc_dota_spawner_" .. NumPlayers)

		if rax_spawner then
			local magnataur = SpawnMagnataur(rax_spawner:GetAbsOrigin())
			CollapsePhaseOneLane(NumPlayers, magnataur)
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

	GameMode.FarmEvent_occuring = false
	self.farm_event_leaderboard_phase = "archived"
	self:PublishFarmLeaderboard(false)
end

function SpecialEvents:StartRameroAndBaristolEvent(hero)
	if IsInToolsMode() and hero == nil then
		hero = PlayerResource:GetSelectedHeroEntity(0)
	end

	local point = Entities:FindByName(nil, "npc_dota_muradin_player_1"):GetAbsOrigin()
	local intro_delay = CINEMATIC_EVENT_PRE_TELEPORT_DELAY + CINEMATIC_EVENT_POST_TELEPORT_HOLD
	StopAllStormEarthFireSounds()
	CustomTimers.timers_paused = 2
	CustomTimers:HideSpecialWaveCountdown()
	GameMode.SpecialArena_occuring = true
	CustomTimers.current_time["special_arena"] = XHS_RAMERO_BARISTOL_TIME + intro_delay
	BT_ENABLED = 0

	NotifySpecialArenaStarted(hero, "Ramero and Baristol")

	SpecialEvents.Ramero_trigger = 1
	SpecialEvents.active_arena_player_id = hero ~= nil
		and not hero:IsNull()
		and hero:GetPlayerID()
		or nil

	if hero ~= nil and not hero:IsNull() then
		hero.old_pos = hero:GetAbsOrigin()
		CreateXHSReturnMarker(hero, hero.old_pos)
	end

	StartSpecialArenaCinematicIntro(hero, point, "xhs_ramero_baristol_creep_pause_watch", function()
		SpecialEvents:RameroAndBaristolEvent(XHS_RAMERO_BARISTOL_TIME, hero)
	end, false)
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
	SpecialEvents.Ramero:AddNewModifier(SpecialEvents.Ramero, nil, "modifier_pause_creeps", { duration = stun_duration, IsHidden = true })
	SpecialEvents.Ramero:SetAngles(0, 45, 0)

	SpecialEvents.Baristol = CreateUnitByName("npc_baristol", Entities:FindByName(nil, "roshan_wp_2"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
	SpecialEvents.Baristol:AddNewModifier(SpecialEvents.Baristol, nil, "modifier_pause_creeps", { duration = stun_duration, IsHidden = true })
	SpecialEvents.Baristol:SetAngles(0, 325, 0)

	XHSSpecialArenaAI:Attach(SpecialEvents.Ramero, "ramero")
	XHSSpecialArenaAI:Attach(SpecialEvents.Baristol, "baristol")
	GameMode:ShowOptionalEventBossBar("ramero", SpecialEvents.Ramero, hero)
	GameMode:ShowOptionalEventBossBar("baristol", SpecialEvents.Baristol, hero)

	PlayStormEarthFireSound(SpecialEvents.Ramero)

	NotifySpecialArenaInstructions(hero, "npc_dota_hero_sven", "Kill Ramero and Baristol to get special items! Reward: Lightning Sword and Tome of Stats +250.")

	GameRules:GetGameModeEntity():SetContextThink("RameroAndBaristol", function()
		SpecialEvents:EndRameroAndBaristolEvent()

		return nil
	end, time)
end

function SpecialEvents:EndRameroAndBaristolEvent(bWin)
	-- Always clear both global slots before any idempotency return. Ramero may
	-- already have an invalid handle when Baristol dies, so the boss-bar helper
	-- also sends a handle-independent hide using the optional event identity.
	GameMode:HideOptionalEventBossBar("ramero", SpecialEvents.Ramero)
	GameMode:HideOptionalEventBossBar("baristol", SpecialEvents.Baristol)
	StopAllStormEarthFireSounds()

	if _G.RAMERO_ARTIFACT_PICKED == true then return end

	bWin = bWin == true or (SpecialEvents.RameroDead == true and SpecialEvents.BaristolDead == true)
	_G.RAMERO_ARTIFACT_PICKED = true
	SpecialEvents.active_arena_player_id = nil
	if FragmentQuests ~= nil then
		FragmentQuests:OnArenaEnd("ramero_baristol", bWin)
	end

	local teleport_time = 3.0
	local mode = GameRules:GetGameModeEntity()

	mode:SetContextThink("RameroAndBaristol", nil, 0)

	RestartCreeps(teleport_time + 3.0)
	UTIL_Remove(_G.RAMERO_DUMMY)
	UTIL_Remove(_G.BARISTOL_DUMMY)

	CustomGameEventManager:Send_ServerToAllClients("hide_timer_special_arena", {})

	if SpecialEvents.Ramero ~= nil and IsValidEntity(SpecialEvents.Ramero) and not SpecialEvents.Ramero:IsNull() then
		UTIL_Remove(SpecialEvents.Ramero)
	end
	if SpecialEvents.Baristol ~= nil and IsValidEntity(SpecialEvents.Baristol) and not SpecialEvents.Baristol:IsNull() then
		UTIL_Remove(SpecialEvents.Baristol)
	end
	SpecialEvents.Ramero = nil
	SpecialEvents.Baristol = nil

	if bWin then
		Notifications:TopToAll({ text = "Ramero and Baristol arena has been won!", duration = 5.0 })
		if SpecialEvents.RameroRewardPending == true and SpecialEvents.RameroRewardHero ~= nil then
			local rewardHero = SpecialEvents.RameroRewardHero
			Timers:CreateTimer(teleport_time + 0.3, function()
				if rewardHero ~= nil and IsValidEntity(rewardHero) and not rewardHero:IsNull() then
					if rewardHero:HasAnyAvailableInventorySpace() then
						local item = CreateItem("item_lightning_sword", rewardHero, rewardHero)
						if item ~= nil then
							item:SetPurchaseTime(GameRules:GetGameTime())
							item:SetPurchaser(rewardHero)
							rewardHero:AddItem(item)
						end
					else
						local dropTarget = rewardHero:GetAbsOrigin() + RandomVector(RandomFloat(50, 150))
						DropNeutralItemAtPositionForHero("item_lightning_sword", dropTarget, rewardHero, rewardHero:GetTeam(), true)
					end
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
	local intro_delay = CINEMATIC_EVENT_PRE_TELEPORT_DELAY + CINEMATIC_EVENT_POST_TELEPORT_HOLD
	StopAllStormEarthFireSounds()
	CustomTimers.timers_paused = 2
	CustomTimers:HideSpecialWaveCountdown()
	GameMode.SpecialArena_occuring = true
	CustomTimers.current_time["special_arena"] = 120.0 + intro_delay
	BT_ENABLED = 0

	NotifySpecialArenaStarted(hero, "Sogat")

	SpecialEvents.Ramero_trigger = 2
	SpecialEvents.active_arena_player_id = hero ~= nil
		and not hero:IsNull()
		and hero:GetPlayerID()
		or nil

	if hero ~= nil and not hero:IsNull() then
		hero.old_pos = hero:GetAbsOrigin()
		CreateXHSReturnMarker(hero, hero.old_pos)
	end

	StartSpecialArenaCinematicIntro(hero, point, "xhs_sogat_creep_pause_watch", function()
		SpecialEvents:SogatEvent(120.0, hero)
	end)
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
	SpecialEvents.SogatRewardHero = nil
	SpecialEvents.SogatRewardPending = false
	if FragmentQuests ~= nil then
		FragmentQuests:OnArenaStart("sogat", time)
	end

	SpecialEvents.Sogat = CreateUnitByName("npc_ramero_2", Entities:FindByName(nil, "roshan_wp_4"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
	SpecialEvents.Sogat:AddNewModifier(SpecialEvents.Sogat, nil, "modifier_pause_creeps", { duration = stun_duration, IsHidden = true })
	SpecialEvents.Sogat:SetAngles(0, 45, 0)
	XHSSpecialArenaAI:Attach(SpecialEvents.Sogat, "sogat")
	GameMode:ShowOptionalEventBossBar("sogat", SpecialEvents.Sogat, hero)
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
	SpecialEvents.active_arena_player_id = nil
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

	if SpecialEvents.Sogat ~= nil and IsValidEntity(SpecialEvents.Sogat) and not SpecialEvents.Sogat:IsNull() then
		GameMode:HideOptionalEventBossBar("sogat", SpecialEvents.Sogat)
		UTIL_Remove(SpecialEvents.Sogat)
	end

	if bWin then
		Notifications:TopToAll({ text = "Sogat arena has been won!", duration = 5.0 })
		if SpecialEvents.SogatRewardPending == true and SpecialEvents.SogatRewardHero ~= nil then
			local rewardHero = SpecialEvents.SogatRewardHero
			Timers:CreateTimer(teleport_time + 0.3, function()
				if rewardHero ~= nil and IsValidEntity(rewardHero) and not rewardHero:IsNull() then
					if rewardHero:HasAnyAvailableInventorySpace() then
						local item = CreateItem("item_ring_of_superiority", rewardHero, rewardHero)
						if item ~= nil then
							item:SetPurchaseTime(GameRules:GetGameTime())
							item:SetPurchaser(rewardHero)
							rewardHero:AddItem(item)
						end
					else
						local dropTarget = rewardHero:GetAbsOrigin() + RandomVector(RandomFloat(50, 150))
						DropNeutralItemAtPositionForHero("item_ring_of_superiority", dropTarget, rewardHero, rewardHero:GetTeam(), true)
					end
				end
			end)
		end
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
