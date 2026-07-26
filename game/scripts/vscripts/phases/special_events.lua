if not SpecialEvents then
	SpecialEvents = class({})
	SpecialEvents.hero_farm_event = {}
	SpecialEvents.Ramero_trigger = 0
end

local SPECIAL_EVENT_CINEMATIC_PAUSE_RAMP = 2.75
local CINEMATIC_EVENT_PRE_TELEPORT_DELAY = 4.0
local CINEMATIC_EVENT_POST_TELEPORT_HOLD = 1.5
local MURADIN_ENTRY_POST_TELEPORT_HOLD = 3.0
local MURADIN_EXIT_STUN_DURATION = 5.0
local MURADIN_TELEPORT_IN_DELAY = CINEMATIC_EVENT_PRE_TELEPORT_DELAY + CINEMATIC_EVENT_POST_TELEPORT_HOLD
local MURADIN_TELEPORT_IN_CHANNEL_DURATION = 2.8
local MURADIN_TELEPORT_ARRIVAL_EFFECT_DURATION = 0.8
local MURADIN_TELEPORT_OUT_DURATION = 3.0
local FARM_LEADERBOARD_NET_TABLE = "xhs_farm_leaderboard"
local FARM_LEADERBOARD_NET_KEY = "state"
local FARM_LEADERBOARD_UPDATE_INTERVAL = 0.25
local FARM_EVENT_CREEPS_PER_WAVE = 10
local FARM_EVENT_ABILITY_THINK_INTERVAL = 0.25
local FARM_EVENT_ABILITY_BY_UNIT = {
	npc_dota_creature_murloc = "xhs_creep_blood_hunger",
	npc_dota_creature_wildkin = "xhs_creep_evasion",
	npc_dota_creature_golem = "neutral_spell_immunity",
	npc_dota_creature_polar_furbolg = "command_aura",
	npc_dota_creature_centaur = "xhs_creep_thorns",
	npc_dota_creature_razormane = "creature_war_stomp",
	npc_dota_creature_revenant = "creature_howling_blast",
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
local MURADIN_TELEPORT_START_PARTICLE = "particles/items2_fx/teleport_start.vpcf"
local MURADIN_TELEPORT_END_PARTICLE = "particles/items2_fx/teleport_end.vpcf"

local function IsValidAliveUnit(unit)
	return unit ~= nil and not unit:IsNull() and unit:IsAlive()
end

local function CanFarmEventUnitCast(unit, ability)
	if not IsValidAliveUnit(unit) or ability == nil or ability:IsNull() then return false end
	if not ability:IsFullyCastable() then return false end
	if unit:IsStunned() or unit:IsSilenced() or unit:IsChanneling() then return false end
	if unit.GetCurrentActiveAbility and unit:GetCurrentActiveAbility() ~= nil then return false end
	return true
end

local function GetFarmEventHero(playerID)
	if playerID == nil or playerID < 0 or not PlayerResource:HasSelectedHero(playerID) then return nil end
	local hero = PlayerResource:GetSelectedHeroEntity(playerID)
	if not IsValidAliveUnit(hero) then return nil end
	return hero
end

local function FindFarmEventBuffTarget(caster, playerID, config)
	local candidates = FindUnitsInRadius(
		caster:GetTeamNumber(),
		caster:GetAbsOrigin(),
		nil,
		config.trigger_range,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false
	)
	local bestTarget = nil
	local bestDamage = -1

	for _, candidate in ipairs(candidates) do
		if IsValidAliveUnit(candidate)
		and candidate.xhs_farm_event == true
		and tonumber(candidate.xhs_farm_event_player_id) == playerID
		and (config.modifier == nil or not candidate:HasModifier(config.modifier)) then
			local damage = candidate:GetAverageTrueAttackDamage(candidate)
			if damage > bestDamage then
				bestTarget = candidate
				bestDamage = damage
			end
		end
	end

	return bestTarget
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

local function StartSpecialArenaCinematicIntro(hero, point, creep_watch_name, on_complete)
	local intro_duration = CINEMATIC_EVENT_PRE_TELEPORT_DELAY + CINEMATIC_EVENT_POST_TELEPORT_HOLD

	CinematicPauseCreeps(SPECIAL_EVENT_CINEMATIC_PAUSE_RAMP)
	CinematicPauseHeroesForDuration(SPECIAL_EVENT_CINEMATIC_PAUSE_RAMP, intro_duration)
	StartCinematicPauseCreepsWatch(creep_watch_name, SPECIAL_EVENT_CINEMATIC_PAUSE_RAMP)

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
			{ text = "You can't kill him! Just survive the Countdown. Reward: 15 000 Gold." },
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

local function CountFarmEventCreeps(playerID)
	if playerID == nil then return 0 end

	local point = Entities:FindByName(nil, "farm_event_player_" .. playerID)
	if point == nil then return 0 end

	local units = FindUnitsInRadius(
		DOTA_TEAM_CUSTOM_2,
		point:GetAbsOrigin(),
		nil,
		1200,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_HERO,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false
	)

	local count = 0
	for _, unit in ipairs(units) do
		if unit.xhs_farm_event == true
		and tonumber(unit.xhs_farm_event_player_id) == playerID then
			count = count + 1
		end
	end

	return count
end

function SpecialEvents:PublishFarmLeaderboard(active)
	local wavesPerLevel = GetFarmEventWaveCount()
	local players = {}

	for playerID, progress in pairs(self.hero_farm_event or {}) do
		local numericPlayerID = tonumber(playerID)
		if type(progress) == "table" and numericPlayerID ~= nil then
			local level = math.max(1, tonumber(progress.level) or 1)
			local round = math.max(0, tonumber(progress.round) or 0) % wavesPerLevel
			local remaining = CountFarmEventCreeps(numericPlayerID)
			local completedWaves = ((level - 1) * wavesPerLevel) + round

			progress.remaining = remaining
			table.insert(players, {
				player_id = numericPlayerID,
				kills = math.max(0, tonumber(progress.kills) or 0),
				level = level,
				wave = round + 1,
				waves_per_level = wavesPerLevel,
				remaining = remaining,
				completed_waves = completedWaves,
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

	CustomNetTables:SetTableValue(FARM_LEADERBOARD_NET_TABLE, FARM_LEADERBOARD_NET_KEY, {
		active = active == true,
		waves_per_level = wavesPerLevel,
		creeps_per_wave = FARM_EVENT_CREEPS_PER_WAVE,
		players = players,
		updated_at = GameRules:GetGameTime(),
	})
end

function SpecialEvents:OnFarmEventCreepKilled(killedUnit)
	if GameMode.FarmEvent_occuring ~= true
		or killedUnit == nil
		or killedUnit:IsNull()
		or killedUnit.xhs_farm_event ~= true then
		return
	end

	local playerID = tonumber(killedUnit.xhs_farm_event_player_id)
	local progress = playerID ~= nil and self.hero_farm_event[playerID] or nil
	if progress == nil then return end

	progress.kills = math.max(0, tonumber(progress.kills) or 0) + 1
end

function SpecialEvents:StartFarmLeaderboardPublisher()
	local mode = GameRules:GetGameModeEntity()
	mode:SetContextThink("xhs_farm_leaderboard_publish", function()
		if GameMode.FarmEvent_occuring ~= true then
			self:PublishFarmLeaderboard(false)
			return nil
		end

		self:PublishFarmLeaderboard(true)
		return FARM_LEADERBOARD_UPDATE_INTERVAL
	end, 0.0)
end

function SpecialEvents:StartFarmEventAbilityAI(unit, playerID, abilityName)
	local config = FARM_EVENT_ACTIVE_ABILITIES[abilityName]
	if config == nil then return end

	local thinkName = DoUniqueString("xhs_farm_event_ability")
	GameRules:GetGameModeEntity():SetContextThink(thinkName, function()
		if GameMode.FarmEvent_occuring ~= true or not IsValidAliveUnit(unit) then return nil end

		local ability = unit:FindAbilityByName(abilityName)
		if not CanFarmEventUnitCast(unit, ability) then return FARM_EVENT_ABILITY_THINK_INTERVAL end

		local now = GameRules:GetGameTime()
		local lockKey = tostring(playerID) .. ":" .. abilityName
		local nextCastTime = self.farm_event_ability_locks and self.farm_event_ability_locks[lockKey] or 0
		if now < nextCastTime then return FARM_EVENT_ABILITY_THINK_INTERVAL end

		local castIssued = false
		if config.cast_type == "no_target" then
			local hero = GetFarmEventHero(playerID)
			if hero ~= nil and (hero:GetAbsOrigin() - unit:GetAbsOrigin()):Length2D() <= config.trigger_range then
				unit:CastAbilityNoTarget(ability, -1)
				castIssued = true
			end
		elseif config.cast_type == "friendly_target" then
			local target = FindFarmEventBuffTarget(unit, playerID, config)
			if target ~= nil then
				unit:CastAbilityOnTarget(target, ability, -1)
				castIssued = true
			end
		end

		if castIssued then
			self.farm_event_ability_locks = self.farm_event_ability_locks or {}
			self.farm_event_ability_locks[lockKey] = now + config.shared_lock
		end

		return FARM_EVENT_ABILITY_THINK_INTERVAL
	end, RandomFloat(0.05, 0.25))
end

function SpecialEvents:ConfigureFarmEventUnit(unit, playerID, difficulty)
	if not IsValidAliveUnit(unit) then return end

	unit.xhs_farm_event = true
	unit.xhs_farm_event_player_id = playerID

	local abilityName = FARM_EVENT_ABILITY_BY_UNIT[unit:GetUnitName()]
	if abilityName == nil then return end

	local ability = unit:FindAbilityByName(abilityName)
	if ability == nil then
		ability = unit:AddAbility(abilityName)
	end
	if ability == nil then
		print("[XHS][FarmEvent] Failed to add " .. abilityName .. " to " .. unit:GetUnitName())
		return
	end

	local maxLevel = math.max(1, ability:GetMaxLevel())
	ability:SetLevel(math.min(math.max(1, tonumber(difficulty) or 1), maxLevel))
	self:StartFarmEventAbilityAI(unit, playerID, abilityName)
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
	self:PublishFarmLeaderboard(true)
	self:StartFarmLeaderboardPublisher()
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
				CreateXHSReturnMarker(v, v.old_pos)
				if point ~= nil then
					StartCinematicDelayedTeleport(v, point:GetAbsOrigin(), tp_delay)
				end
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
				SpecialEvents.hero_farm_event[nPlayerID]["round"] = 0
				SpecialEvents.hero_farm_event[nPlayerID]["level"] = 1
				SpecialEvents.hero_farm_event[nPlayerID]["kills"] = 0

				for j = 1, FARM_EVENT_CREEPS_PER_WAVE do
					if FarmEvent_Creeps[1] and point then
						PlayStormEarthFireSound(point)

						local unit = CreateUnitByName(FarmEvent_Creeps[1], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
						unit:SetBaseDamageMin(unit:GetRealDamageDone(unit) + (FARM_EVENT_UPGRADE["damage"][difficulty] * SpecialEvents.hero_farm_event[nPlayerID]["level"]))
						unit:SetBaseDamageMax(unit:GetRealDamageDone(unit) + (FARM_EVENT_UPGRADE["damage"][difficulty] * SpecialEvents.hero_farm_event[nPlayerID]["level"]) * 1.1)
						unit:SetMaxHealth(unit:GetMaxHealth() + (FARM_EVENT_UPGRADE["health"][difficulty] * SpecialEvents.hero_farm_event[nPlayerID]["level"]))
						unit:SetBaseMaxHealth(unit:GetMaxHealth() + (FARM_EVENT_UPGRADE["health"][difficulty] * SpecialEvents.hero_farm_event[nPlayerID]["level"]))
						unit:SetHealth(unit:GetMaxHealth())
						unit:SetPhysicalArmorBaseValue(unit:GetPhysicalArmorValue(false) + (FARM_EVENT_UPGRADE["armor"][difficulty] * SpecialEvents.hero_farm_event[nPlayerID]["level"]))
						SpecialEvents:ConfigureFarmEventUnit(unit, nPlayerID, difficulty)
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

		-- The farm event pauses the shared special-wave timer. Use a local 30-second
		-- countdown because this warning fires at time - 20 and the wave spawns at time + 10.
		CustomTimers:ShowSpecialWaveCountdown(6, 30, false)
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
	local wavesPerLevel = GetFarmEventWaveCount()

	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("muradin_event"), function()
		local units = FindUnitsInRadius(DOTA_TEAM_CUSTOM_2, point:GetAbsOrigin(), nil, 1200, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

		if CustomTimers.timers_paused == 1 then
			if #units <= 1 then
				SpecialEvents.hero_farm_event[id]["round"] = (SpecialEvents.hero_farm_event[id]["round"] + 1) % wavesPerLevel

				if SpecialEvents.hero_farm_event[id]["round"] == 0 then
					SpecialEvents.hero_farm_event[id]["level"] = (SpecialEvents.hero_farm_event[id]["level"] + 1)
				end

				for j = 1, FARM_EVENT_CREEPS_PER_WAVE do
					local unit = CreateUnitByName(FarmEvent_Creeps[SpecialEvents.hero_farm_event[id]["round"] + 1], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
					unit:SetBaseDamageMin(unit:GetRealDamageDone(unit) + (FARM_EVENT_UPGRADE["damage"][difficulty] * SpecialEvents.hero_farm_event[id]["level"]) * 0.95)
					unit:SetBaseDamageMax(unit:GetRealDamageDone(unit) + (FARM_EVENT_UPGRADE["damage"][difficulty] * SpecialEvents.hero_farm_event[id]["level"]) * 1.05)
					unit:SetMaxHealth(unit:GetMaxHealth() + (FARM_EVENT_UPGRADE["health"][difficulty] * SpecialEvents.hero_farm_event[id]["level"]))
					unit:SetBaseMaxHealth(unit:GetMaxHealth() + (FARM_EVENT_UPGRADE["health"][difficulty] * SpecialEvents.hero_farm_event[id]["level"]))
					unit:SetHealth(unit:GetMaxHealth())
					unit:SetPhysicalArmorBaseValue(unit:GetPhysicalArmorValue(false) + (FARM_EVENT_UPGRADE["armor"][difficulty] * SpecialEvents.hero_farm_event[id]["level"]))

					SpecialEvents:ConfigureFarmEventUnit(unit, id, difficulty)
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

	if hero ~= nil and not hero:IsNull() then
		hero.old_pos = hero:GetAbsOrigin()
		CreateXHSReturnMarker(hero, hero.old_pos)
	end

	StartSpecialArenaCinematicIntro(hero, point, "xhs_ramero_baristol_creep_pause_watch", function()
		SpecialEvents:RameroAndBaristolEvent(XHS_RAMERO_BARISTOL_TIME, hero)
	end)
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
