-- require("components/timers/events")

local SPECIAL_WAVE_WARNING_SOUND = "Dungeon.Stinger03"

if CustomTimers == nil then
	CustomTimers = class({})

	CustomTimers.current_time = {}
	CustomTimers.current_time["game_time"] = PREGAMETIME * (-1)          -- Game Time
	-- if IsInToolsMode() then CustomTimers.current_time["game_time"] = 600 end
	CustomTimers.current_time["creep_level"] = XHS_CREEPS_UPGRADE_INTERVAL -- Upgrade phase 1 creeps level
	CustomTimers.current_time["special_wave"] = XHS_SPECIAL_WAVE_INTERVAL -- Special Wave spawning west, north, east, south
	CustomTimers.current_time["special_event"] = XHS_SPECIAL_EVENT_INTERVAL -- Muradin Event, Farm Event, Final Wave
	CustomTimers.current_time["special_arena"] = 0                       -- Ramero & Baristol, Sogat
	CustomTimers.current_time["hero_image"] = 0                          -- Hero Image event
	CustomTimers.current_time["spirit_beast"] = 0                        -- Hero Image event
	CustomTimers.current_time["frost_infernal"] = 0                      -- Hero Image event
	CustomTimers.current_time["all_hero_images"] = 0                     -- Hero Image event

	CustomTimers.game_phase = 0
	CustomTimers.creep_level = 1
	CustomTimers.muradin_creep_level_delay_applied = false
	CustomTimers.special_wave = 1
	CustomTimers.enable_special_wave = false -- todo: use this to enable/disable special waves when notification happens 30s before and disable it when it has spawned. This will allow waves to spawn exactly when supposed to, rather than a few seconds before/after
	CustomTimers.special_waves_disabled = false
	CustomTimers.active_special_waves = {}
	CustomTimers.active_special_wave_units = {}
	CustomTimers.active_special_wave_count = 0
	CustomTimers.active_special_wave_total = 0
	CustomTimers.active_special_wave_direction = ""
	CustomTimers.pending_special_wave_display_id = nil
	CustomTimers.active_special_wave_timer_particles = {}
	CustomTimers.proc_final_wave = false
	CustomTimers.final_wave_delay = 60.0

	CustomTimers.timers_paused = 0 -- 1 = half-pause, 2 = full-pause (excluding special arenas)
	CustomTimers.current_event_timer_paused = false

	CustomTimers.special_wave_region = {
		"Incoming wave of Darkness from the West",
		"Incoming wave of Darkness from the North",
		"Muradin Event in 30 sec",
		"Incoming wave of Darkness from the South",
		"Incoming wave of Darkness from the West",
		"Farming Event in 30 sec",
		"Incoming wave of Darkness from the East",
		"Incoming wave of Darkness from the South"
	}
end

if XHSQuestState == nil then
	XHSQuestState = {
		muradin_event_started = false,
		global_objectives = {
			muradin_event = {
				state = "Active",
				text = "Muradin Event in --:--",
				default_text = "Muradin Event in --:--",
			},
			farm_event = {
				state = "Inactive",
				text = "Farm Event locked",
				default_text = "Farm Event locked",
			},
			phase2_creeps = {
				state = "Inactive",
				text = "Phase 2 creeps locked",
				default_text = "Phase 2 creeps locked",
			},
			final_wave = {
				state = "Inactive",
				text = "Final Wave locked",
				default_text = "Final Wave locked",
			},
		},
	}
end

function XHSUpdateQuestStateNetTable()
	if CustomNetTables == nil or CustomTimers == nil then return end

	CustomNetTables:SetTableValue("xhs_quest_state", "state", {
		game_phase = CustomTimers.game_phase or 1,
		creep_level = CustomTimers.creep_level or 1,
		creep_seconds = CustomTimers.current_time and CustomTimers.current_time["creep_level"] or 0,
		special_event_seconds = CustomTimers.current_time and CustomTimers.current_time["special_event"] or 0,
		muradin_event_started = XHSQuestState.muradin_event_started == true,
		global_objectives = XHSQuestState.global_objectives or {},
	})
end

function XHSPersistQuestTimingState()
	XHSUpdateQuestStateNetTable()
end

function XHSSetGlobalObjectiveState(id, state, text, seconds, started)
	if id == nil or XHSQuestState == nil then return end

	local objectives = XHSQuestState.global_objectives or {}
	XHSQuestState.global_objectives = objectives

	local current = objectives[id] or {}
	local objective = {
		state = state or current.state or "Inactive",
		text = text or current.text or current.default_text or "",
		default_text = current.default_text or current.defaultText or text or "",
		started = started == true or current.started == true,
	}

	if seconds ~= nil then
		objective.seconds = seconds
	end

	if id == "muradin_event" and (started == true or state == "Completed") then
		XHSQuestState.muradin_event_started = true
		objective.started = true
	end

	objectives[id] = objective
	XHSUpdateQuestStateNetTable()

	CustomGameEventManager:Send_ServerToAllClients("xhs_global_objective_update", {
		id = id,
		state = objective.state,
		text = objective.text,
		seconds = seconds,
		started = objective.started,
	})
end

function CustomTimers:GetVisibleSpecialWave()
	local waves = CustomTimers.active_special_waves or {}
	return waves[1]
end

function CustomTimers:SyncVisibleSpecialWaveFields()
	local wave = CustomTimers:GetVisibleSpecialWave()
	if wave ~= nil then
		CustomTimers.active_special_wave_count = wave.remaining or 0
		CustomTimers.active_special_wave_total = wave.total or 0
		CustomTimers.active_special_wave_direction = wave.direction or ""
	else
		CustomTimers.active_special_wave_count = 0
		CustomTimers.active_special_wave_total = 0
		CustomTimers.active_special_wave_direction = ""
	end

	return wave
end

function CustomTimers:IsSpecialWaveDisplayPending(wave)
	return wave ~= nil and CustomTimers.pending_special_wave_display_id ~= nil and CustomTimers.pending_special_wave_display_id == wave.id
end

function CustomTimers:BroadcastSpecialWaveActive(wave)
	if wave == nil then return end

	CustomGameEventManager:Send_ServerToAllClients("xhs_wave_active", {
		remaining = wave.remaining or 0,
		total = wave.total or 0,
		direction = wave.direction or "",
		wave_index = wave.wave_index or 0,
	})
end

function CustomTimers:BroadcastVisibleSpecialWave()
	local wave = CustomTimers:SyncVisibleSpecialWaveFields()
	if wave == nil or CustomTimers:IsSpecialWaveDisplayPending(wave) then return end

	CustomTimers:BroadcastSpecialWaveActive(wave)
end

function CustomTimers:RemoveSpecialWave(wave)
	if wave == nil then return false end

	local waves = CustomTimers.active_special_waves or {}
	for index, activeWave in ipairs(waves) do
		if activeWave == wave then
			table.remove(waves, index)
			break
		end
	end

	if CustomTimers.pending_special_wave_display_id == wave.id then
		CustomTimers.pending_special_wave_display_id = nil
	end

	CustomTimers:SyncVisibleSpecialWaveFields()
	return true
end

function CustomTimers:ScheduleVisibleSpecialWaveAfterClear()
	local wave = CustomTimers:GetVisibleSpecialWave()
	if wave == nil then return end

	CustomTimers.pending_special_wave_display_id = wave.id
	Timers:CreateTimer(2.4, function()
		local visibleWave = CustomTimers:GetVisibleSpecialWave()
		if visibleWave == nil or visibleWave.id ~= wave.id then return nil end

		CustomTimers.pending_special_wave_display_id = nil
		CustomTimers:BroadcastVisibleSpecialWave()
		return nil
	end)
end

ListenToGameEvent('game_rules_state_change', function()
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		CustomTimers:IncrementGamePhase()
	end
end, nil)

ListenToGameEvent('entity_killed', function(keys)
	local killed_unit = EntIndexToHScript(keys.entindex_killed)
	if not killed_unit then return end

	if killed_unit:GetUnitName() == "npc_tower_cold" and CustomTimers.proc_final_wave == false then
		CustomTimers:PrepareFinalWaveCountdown()
	end

	CustomTimers.active_special_wave_units = CustomTimers.active_special_wave_units or {}
	local specialWave = CustomTimers.active_special_wave_units[keys.entindex_killed]
	if specialWave ~= nil then
		CustomTimers.active_special_wave_units[keys.entindex_killed] = nil
		if specialWave.units ~= nil then
			specialWave.units[keys.entindex_killed] = nil
		end

		specialWave.remaining = math.max(0, (specialWave.remaining or 0) - 1)

		local visibleWave = CustomTimers:GetVisibleSpecialWave()
		local wasVisible = specialWave == visibleWave

		if wasVisible and specialWave.remaining > 0 then
			CustomTimers:SyncVisibleSpecialWaveFields()
			CustomTimers:BroadcastVisibleSpecialWave()
		elseif specialWave.remaining <= 0 then
			CustomTimers:RemoveSpecialWave(specialWave)

			if wasVisible then
				CustomGameEventManager:Send_ServerToAllClients("xhs_wave_cleared", {
					total = specialWave.total or 0,
					direction = specialWave.direction or "",
					wave_index = specialWave.wave_index or 0,
				})

				if CustomTimers:GetVisibleSpecialWave() ~= nil then
					CustomTimers:ScheduleVisibleSpecialWaveAfterClear()
				elseif FragmentQuests ~= nil then
					FragmentQuests:OnSpecialWaveEnd(true)
				end
			elseif CustomTimers:IsSpecialWaveDisplayPending(specialWave) and CustomTimers:GetVisibleSpecialWave() ~= nil then
				CustomTimers:ScheduleVisibleSpecialWaveAfterClear()
			end
		end
	end

	-- The Killing entity
	--	local killer = nil
	--	if keys.entindex_attacker then killer = EntIndexToHScript(keys.entindex_attacker) end
end, nil)

function CustomTimers:PrepareFinalWaveCountdown(force)
	if CustomTimers.proc_final_wave == true then return end
	if force ~= true and XHSDevTools ~= nil and XHSDevTools:IsSandboxActive() then return end

	CustomTimers.proc_final_wave = true
	CustomTimers.final_wave_kill_counting = false
	CustomTimers.final_wave_spawned_kill_limit = 0
	KillCreeps(DOTA_TEAM_CUSTOM_1)

	for c = 1, 8 do
		if CREEP_LANES[c] ~= nil then
			CREEP_LANES[c][1] = 0
			CREEP_LANES[c][3] = 0
		end
	end

	Notifications:TopToAll({ text = "WARNING! Final Wave incoming. Arriving in 60 seconds! Back to the Castle!", duration = 10.0 })

	CustomGameEventManager:Send_ServerToAllClients("update_special_event_label_final", {})
	XHSSetGlobalObjectiveState("phase2_creeps", "Completed", "Phase 2 creep assault survived", nil)
	XHSSetGlobalObjectiveState("final_wave", "Active", "Final Wave in " .. math.floor(CustomTimers.final_wave_delay) .. "s", CustomTimers.final_wave_delay)
	CustomTimers.current_time["special_event"] = CustomTimers.final_wave_delay + 1
	CustomTimers.current_time["special_wave"] = 1
	CustomTimers:Countdown("special_wave")
	CustomTimers:ShowFinalWaveCountdown(CustomTimers.final_wave_delay)
end

function CustomTimers:Think()
	if XHSDevTools ~= nil and XHSDevTools:IsSandboxActive() then
		return
	end

	-- If no events is happening, keep running
	if CustomTimers.timers_paused == 0 and GameMode.SpecialArena_occuring ~= true then
		CustomTimers:Countdown("game_time")

		if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
			-- local minutes = math.floor(CustomTimers.current_time["game_time"] / 60)
			-- local seconds = math.floor(CustomTimers.current_time["game_time"] - (minutes * 60))
			-- print("Game Time: " .. minutes .. ":" .. seconds)

			-- 9:00 minutes (Muradin Event)
			if CustomTimers.current_time["game_time"] == XHS_SPECIAL_EVENT_INTERVAL and XHS_TIMERS_MURADIN == false then
				XHS_TIMERS_MURADIN = true
				SpecialEvents:MuradinEvent(XHS_MURADIN_EVENT_DURATION)

				return
			end

			-- 18:00 minutes (Farm Event)
			if CustomTimers.current_time["game_time"] == (XHS_SPECIAL_EVENT_INTERVAL * 2) and XHS_TIMERS_FARM == false then
				XHS_TIMERS_FARM = true
				SpecialEvents:FarmEvent(XHS_FARM_EVENT_DURATION)

				return
			end

			-- 27:00 minutes (End of phase 2)
			if CustomTimers.current_time["game_time"] == (XHS_SPECIAL_EVENT_INTERVAL * 3) and XHS_TIMERS_PHASE_2 == false then
				XHS_TIMERS_PHASE_2 = true
				EndPhase2()
			end

			-- 28:00 minutes (Final Wave)
			if CustomTimers.current_time["game_time"] == (XHS_SPECIAL_EVENT_INTERVAL * 3) + CustomTimers.final_wave_delay and XHS_TIMERS_FINAL_WAVE == false then
				XHS_TIMERS_FINAL_WAVE = true
				FinalWave()
			end

			-- this 'game phase' fail-safe is unnecessary anymore, but yeah just in case
			if CustomTimers.game_phase == 1 then
				if CustomTimers.current_time["game_time"] % XHS_CREEPS_INTERVAL == 0 or math.floor(GameRules:GetDOTATime(false, false)) == 0 then
					SpawnCreeps()
				end

				CustomTimers:TickCreepLevel()
			end

			if CustomTimers.game_phase < 3 and CustomTimers.proc_final_wave ~= true and GameMode.SpecialArena_occuring ~= true and CustomTimers.special_waves_disabled ~= true then
				if CustomTimers.special_wave <= 8 then
					CustomTimers:Countdown("special_wave")

					local cardinal_point = CustomTimers.special_wave

					if CustomTimers.current_time["special_wave"] == 30 then
						-- print("Special Wave in 30 seconds:", CustomTimers.special_wave_region[cardinal_point], CustomTimers.special_wave)
						if cardinal_point ~= 3 then
							CustomTimers:ShowSpecialWaveCountdown(cardinal_point, 30)
							if Runes and Runes.OnSpecialWaveWarning then
								Runes:OnSpecialWaveWarning(cardinal_point, CustomTimers:GetSpecialWavePoint(cardinal_point))
							end
							CustomTimers.enable_special_wave = true
						end
					elseif CustomTimers.current_time["special_wave"] == 0 then
						-- print("Special Wave:", CustomTimers.special_wave_region[cardinal_point], CustomTimers.special_wave)
						SpecialWave(cardinal_point)
					end
				else
					if CustomTimers.current_time["special_wave"] ~= 0 then
						CustomTimers.current_time["special_wave"] = 0
						CustomTimers:Countdown("special_wave") -- run once to set to 00:00 on UI
					end
				end
			end
		end
	else
		-- print("Custom Timers are currently in pause.")
	end

	-- These timer should always run
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		local final_wave_countdown = CustomTimers.proc_final_wave == true and XHS_TIMERS_FINAL_WAVE == false
		local final_wave_active = CustomTimers.proc_final_wave == true and XHS_TIMERS_FINAL_WAVE == true and CustomTimers.game_phase < 3
		if CustomTimers.timers_paused ~= 2 and CustomTimers.current_event_timer_paused ~= true and GameMode.SpecialArena_occuring ~= true and (final_wave_countdown or (CustomTimers.game_phase < 3 and final_wave_active ~= true)) then
			CustomTimers:Countdown("special_event")
		end

		if CustomTimers.timers_paused ~= 0 and CustomTimers.current_event_timer_paused ~= true and GameMode.Muradin_occuring == true and CustomTimers.game_phase == 1 then
			CustomTimers:TickCreepLevel()
			CustomTimers:TickMuradinSpecialWaveCountdown()
		end

		if GameMode.SpecialArena_occuring == true then CustomTimers:Countdown("special_arena") end
		if GameMode.HeroImage_occuring == true then CustomTimers:Countdown("hero_image") end
		if GameMode.SpiritBeast_occuring == true then CustomTimers:Countdown("spirit_beast") end
		if GameMode.FrostInfernal_occuring == true then CustomTimers:Countdown("frost_infernal") end
		if GameMode.AllHeroImages_occuring == true then CustomTimers:Countdown("all_hero_images") end
	end
end

function CustomTimers:GetSpecialWaveTimerMetadata(t)
	local wave_index = CustomTimers.special_wave or 0
	local direction = ""
	local show_compact = false

	if wave_index >= 1 and wave_index <= 8 and CustomTimers.game_phase < 3 and CustomTimers.proc_final_wave ~= true then
		direction = CustomTimers:GetSpecialWavePoint(wave_index) or ""
		show_compact = t > 30

		if wave_index == 3 and CustomTimers.enable_special_wave ~= true then
			show_compact = false
		end
	end

	return {
		wave_index = wave_index,
		direction = direction,
		show_compact = show_compact,
		wave_interval = XHS_SPECIAL_WAVE_INTERVAL,
	}
end

function CustomTimers:BroadcastTimer(timer_name)
	local t = CustomTimers.current_time[timer_name] or 0
	if t < 0 then t = t * (-1) end
	local minutes = math.floor(t / 60)
	local seconds = t - (minutes * 60)
	local m10 = math.floor(minutes / 10)
	local m01 = minutes - (m10 * 10)
	local s10 = math.floor(seconds / 10)
	local s01 = seconds - (s10 * 10)
	local broadcast_gametimer =
	{
		timer_minute_10 = m10,
		timer_minute_01 = m01,
		timer_second_10 = s10,
		timer_second_01 = s01,
		timer_name = timer_name,
	}

	if timer_name == "special_wave" then
		local metadata = CustomTimers:GetSpecialWaveTimerMetadata(t)
		for key, value in pairs(metadata) do
			broadcast_gametimer[key] = value
		end
	end

	CustomGameEventManager:Send_ServerToAllClients("countdown_timer", broadcast_gametimer)

	if timer_name == "creep_level" or timer_name == "special_event" then
		XHSPersistQuestTimingState()
	end
end

function CustomTimers:Countdown(timer_name)
	--	print(timer_name, CustomTimers.current_time[timer_name])
	if timer_name == "game_time" then
		CustomTimers.current_time[timer_name] = CustomTimers.current_time[timer_name] + 1
	else
		CustomTimers.current_time[timer_name] = CustomTimers.current_time[timer_name] - 1
	end

	CustomTimers:BroadcastTimer(timer_name)
end

function CustomTimers:TickMuradinSpecialWaveCountdown()
	if CustomTimers.enable_special_wave ~= true then return end
	if CustomTimers.current_time["special_wave"] <= 0 then return end

	CustomTimers:Countdown("special_wave")
end

function CustomTimers:TickCreepLevel()
	if CustomTimers.game_phase ~= 1 then return end

	if CustomTimers.creep_level <= 4 then
		CustomTimers:Countdown("creep_level")

		if CustomTimers.current_time["creep_level"] <= 0 then
			CustomTimers.creep_level = CustomTimers.creep_level + 1
			CustomTimers.current_time["creep_level"] = XHS_CREEPS_UPGRADE_INTERVAL
			if CustomTimers.creep_level == 2 and CustomTimers.muradin_creep_level_delay_applied ~= true then
				CustomTimers.current_time["creep_level"] = CustomTimers.current_time["creep_level"] + XHS_MURADIN_EVENT_DURATION
				CustomTimers.muradin_creep_level_delay_applied = true
			end
			CreepLevels(CustomTimers.creep_level)
			CustomTimers:BroadcastTimer("creep_level")
		end
	else
		if CustomTimers.current_time["creep_level"] ~= 0 then
			CustomTimers.current_time["creep_level"] = 0
			CustomTimers:BroadcastTimer("creep_level")
		end
	end
end

function CustomTimers:IncrementGamePhase()
	CustomTimers.game_phase = CustomTimers.game_phase + 1

	if CustomTimers.game_phase == 3 and RespawnDeadHeroesForPhase3Start ~= nil then
		RespawnDeadHeroesForPhase3Start()
	end

	CustomGameEventManager:Send_ServerToAllClients("xhs_game_phase_update", {
		phase = CustomTimers.game_phase,
	})
	CustomGameEventManager:Send_ServerToAllClients("xhs_creep_level_update", {
		level = CustomTimers.creep_level,
	})
	XHSPersistQuestTimingState()

	if CustomTimers.game_phase == 2 then
		return
	elseif CustomTimers.game_phase == 3 then
		Notifications:TopToAll({ text = "Phase 3 begins. Respawn disabled!", duration = 5.0, severity = "warning" })
	else
		Notifications:TopToAll({ text = "GAME PHASE: Entering phase " .. CustomTimers.game_phase .. " !", duration = 5.0 })
	end
end

function CustomTimers:GetSpecialWavePoint(iCardinalPoint)
	if iCardinalPoint > 4 then iCardinalPoint = iCardinalPoint - 4 end

	local point = {
		"west",
		"north",
		"east",
		"south"
	}

	return point[iCardinalPoint]
end

function CustomTimers:ShowSpecialWaveCountdown(iCardinalPoint, duration)
	if GameMode.SpecialArena_occuring == true then return end

	local direction = CustomTimers:GetSpecialWavePoint(iCardinalPoint)
	if direction == nil then return end

	CustomGameEventManager:Send_ServerToAllClients("xhs_wave_timer", {
		duration = duration,
		timer_name = "special_wave",
		eyebrow = "WAVE INCOMING",
		title = "Wave of Darkness",
		subtitle = string.upper(direction) .. " lane",
		sound = duration == 30 and SPECIAL_WAVE_WARNING_SOUND or nil
	})

	CustomTimers:CreateSpecialWaveTimerParticle(direction, duration)
end

function CustomTimers:HideSpecialWaveCountdown()
	CustomGameEventManager:Send_ServerToAllClients("xhs_wave_hide", {})
	CustomTimers:ClearSpecialWaveTimerParticles()
end

function CustomTimers:ClearSpecialWaveTimerParticles()
	local particles = CustomTimers.active_special_wave_timer_particles or {}
	for index, particle in pairs(particles) do
		if particle ~= nil then
			ParticleManager:DestroyParticle(particle, false)
			ParticleManager:ReleaseParticleIndex(particle)
			particles[index] = nil
		end
	end
end

function CustomTimers:ResumeSpecialWaveCountdown()
	if CustomTimers.game_phase >= 3 or CustomTimers.special_wave > 8 then return end
	if CustomTimers.proc_final_wave == true then return end
	if GameMode.SpecialArena_occuring == true then return end

	local remaining = CustomTimers.current_time["special_wave"] or 0
	if remaining <= 0 or remaining > 30 then return end
	if CustomTimers.special_wave == 3 then return end

	CustomTimers:ShowSpecialWaveCountdown(CustomTimers.special_wave, remaining)
end

function CustomTimers:ShowFinalWaveCountdown(duration)
	CustomGameEventManager:Send_ServerToAllClients("xhs_wave_timer", {
		duration = duration,
		timer_name = "special_event",
		eyebrow = "FINAL WAVE",
		title = "Back to the Castle",
		subtitle = "Final wave incoming"
	})
end

function CustomTimers:CreateSpecialWaveTimerParticle(direction, duration)
	local spawner = Entities:FindByName(nil, "npc_dota_spawner_" .. direction .. "_event")
	if spawner == nil then return end

	CustomTimers:ClearSpecialWaveTimerParticles()

	local origin = spawner:GetAbsOrigin()

	AddFOWViewer(DOTA_TEAM_GOODGUYS, origin, radius, duration, false)
end

function SpecialWave(iCardinalPoint, force)
	if CustomTimers.game_phase > 2 then return end
	if CustomTimers.proc_final_wave == true then return end
	if force ~= true and XHSDevTools ~= nil and XHSDevTools:IsSandboxActive() then return end
	if CustomTimers.special_waves_disabled == true and force ~= true then return end

	CustomTimers.enable_special_wave = false
	CustomTimers.current_time["special_wave"] = XHS_SPECIAL_WAVE_INTERVAL + 1
	local waveIndex = CustomTimers.special_wave

	if iCardinalPoint > 4 then iCardinalPoint = iCardinalPoint - 4 end

	local point = {
		"west",
		"north",
		"east",
		"south"
	}

	local unit = {
		"npc_dota_creature_necrolyte_event_1",
		"npc_dota_creature_naga_siren_event_2",
		"npc_dota_creature_vengeful_spirit_event_3",
		"npc_dota_creature_captain_event_4",
		"npc_dota_creature_slardar_event_5",
		"npc_dota_creature_chaos_knight_event_6",
		"npc_dota_creature_luna_event_7",
		"npc_dota_creature_clockwerk_event_8"
	}

	local real_point = Entities:FindByName(nil, "npc_dota_spawner_" .. point[iCardinalPoint] .. "_event")

	if real_point == nil then
		print("Special Wave: Failed to find spawner for " .. point[iCardinalPoint])
		return
	end

	local wave = {
		id = DoUniqueString("xhs_special_wave"),
		wave_index = waveIndex,
		direction = point[iCardinalPoint],
		total = 10,
		remaining = 10,
		units = {},
	}
	CustomTimers.active_special_waves = CustomTimers.active_special_waves or {}
	CustomTimers.active_special_wave_units = CustomTimers.active_special_wave_units or {}
	table.insert(CustomTimers.active_special_waves, wave)
	CustomTimers:SyncVisibleSpecialWaveFields()

	if FragmentQuests ~= nil then
		FragmentQuests:OnSpecialWaveStart(waveIndex, wave.direction, wave.total)
	end

	for j = 1, 10 do
		local spawned_unit = CreateUnitByName(unit[waveIndex], real_point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
		if spawned_unit ~= nil then
			wave.units[spawned_unit:entindex()] = true
			CustomTimers.active_special_wave_units[spawned_unit:entindex()] = wave
		end
	end

	if CustomTimers:GetVisibleSpecialWave() == wave then
		CustomTimers:BroadcastVisibleSpecialWave()
	end

	CustomTimers.special_wave = CustomTimers.special_wave + 1

	EmitSoundOnLocationForAllies(real_point:GetAbsOrigin(), "Ability.Roar", caster)

	Timers:CreateTimer(1.9, function()
		real_point:StopSound("Ability.Roar")
	end)
end
