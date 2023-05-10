-- require("components/timers/events")

if CustomTimers == nil then
	CustomTimers = class({})

	CustomTimers.current_time = {}
	CustomTimers.current_time["game_time"] = PREGAMETIME * (-1)          -- Game Time
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
	CustomTimers.special_wave = 1
	CustomTimers.proc_final_wave = false
	CustomTimers.final_wave_delay = 60.0

	CustomTimers.timers_paused = 0 -- 1 = half-pause, 2 = full-pause (excluding special arenas)

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

ListenToGameEvent('game_rules_state_change', function()
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		print("Attempt to increment game phase...")
		CustomTimers:IncrementGamePhase()
		print("Game phase incremented!")
	end
end, nil)

ListenToGameEvent('entity_killed', function(keys)
	local killed_unit = EntIndexToHScript(keys.entindex_killed)
	if not killed_unit then return end

	if killed_unit:GetUnitName() == "npc_tower_cold" and CustomTimers.proc_final_wave == false then
		CustomTimers.proc_final_wave = true
		Notifications:TopToAll({ text = "WARNING! Final Wave incoming. Arriving in 60 seconds! Back to the Castle!", duration = 10.0 })
		CustomTimers:IncrementGamePhase() -- Phase 2 to Phase 3
		CustomTimers.current_time["special_event"] = CustomTimers.final_wave_delay + 1.0
		CustomTimers.current_time["special_wave"] = 1
		CustomTimers:Countdown("special_wave") -- will not trigger a special wave while in phase 3
		KillCreeps(DOTA_TEAM_CUSTOM_1)
	end

	-- The Killing entity
	--	local killer = nil
	--	if keys.entindex_attacker then killer = EntIndexToHScript(keys.entindex_attacker) end
end, nil)

function CustomTimers:Think()
	-- If no events is happening, keep running
	if CustomTimers.timers_paused == 0 then
		CustomTimers:Countdown("game_time")

		if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
			-- 9:00 minutes (Muradin Event)
			if CustomTimers.current_time["game_time"] == (XHS_SPECIAL_EVENT_INTERVAL - 1) then
				CustomTimers.timers_paused = 1

				PauseCreeps()
				PauseHeroes()

				Timers:CreateTimer(3, function()
					Timers:CreateTimer(3, RestartHeroes())
					Timers:CreateTimer(5, MuradinEvent(XHS_MURADIN_EVENT_DURATION))
				end)

				return
			end

			-- 18:00 minutes (Farm Event)
			if CustomTimers.current_time["game_time"] == (XHS_SPECIAL_EVENT_INTERVAL * 2) - 1 then
				CustomTimers.timers_paused = 1

				PauseCreeps()
				PauseHeroes()

				Timers:CreateTimer(3, function()
					Timers:CreateTimer(3, RestartHeroes())
					FarmEvent(180)
				end)

				return
			end

			-- 27:00 minutes (Farm Event)
			--			print("End of phase 2:", CustomTimers.current_time["game_time"], XHS_SPECIAL_EVENT_INTERVAL * 3 - 1)
			if CustomTimers.current_time["game_time"] == (XHS_SPECIAL_EVENT_INTERVAL * 3) then
				EndPhase2()
			end

			if CustomTimers.current_time["game_time"] == (XHS_SPECIAL_EVENT_INTERVAL * 3) + CustomTimers.final_wave_delay then
				FinalWave()
			end

			-- this 'game phase' fail-safe is unnecessary anymore, but yeah just in case
			if CustomTimers.game_phase == 1 then
				if CustomTimers.current_time["game_time"] % XHS_CREEPS_INTERVAL == 0 or math.floor(GameRules:GetDOTATime(false, false)) == 0 then
					SpawnCreeps()
				end

				-- every 4:30 minutes
				if CustomTimers.creep_level <= 4 then
					CustomTimers:Countdown("creep_level")

					if CustomTimers.current_time["creep_level"] == 1 then
						CustomTimers.creep_level = CustomTimers.creep_level + 1
						CustomTimers.current_time["creep_level"] = XHS_CREEPS_UPGRADE_INTERVAL + 1
						CreepLevels(CustomTimers.creep_level)
					end
				else
					if CustomTimers.current_time["creep_level"] ~= 0 then
						CustomTimers.current_time["creep_level"] = 0
					end
				end
			end

			if CustomTimers.game_phase < 3 then
				if CustomTimers.special_wave <= 8 then
					CustomTimers:Countdown("special_wave")

					local cardinal_point = CustomTimers.special_wave

					if CustomTimers.current_time["special_wave"] == 31 then
						Notifications:TopToAll({ text = "WARNING: " .. CustomTimers.special_wave_region[cardinal_point] .. "!", duration = 25.0, style = { color = "red" } })
						SpawnRunes()
					elseif CustomTimers.current_time["special_wave"] == 1 then
						SpecialWave(cardinal_point)
					end
				else
					if CustomTimers.current_time["special_wave"] ~= 1 then
						CustomTimers.current_time["special_wave"] = 1
						CustomTimers:Countdown("special_wave") -- run once to set to 00:00
					end
				end
			end
		end
	else
		--		print("Custom Timers are currently in pause.")
	end

	-- These timer should always run
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		if CustomTimers.timers_paused ~= 2 and CustomTimers.game_phase < 3 then
			CustomTimers:Countdown("special_event")
		end

		if GameMode.SpecialArena_occuring == 1 then CustomTimers:Countdown("special_arena") end
		if GameMode.HeroImage_occuring == 1 then CustomTimers:Countdown("hero_image") end
		if GameMode.SpiritBeast_occuring == 1 then CustomTimers:Countdown("spirit_beast") end
		if GameMode.FrostInfernal_occuring == 1 then CustomTimers:Countdown("frost_infernal") end
		if GameMode.AllHeroImages_occuring == 1 then CustomTimers:Countdown("all_hero_images") end
	end
end

function CustomTimers:Countdown(timer_name)
	--	print(timer_name, CustomTimers.current_time[timer_name])
	if timer_name == "game_time" then
		CustomTimers.current_time[timer_name] = CustomTimers.current_time[timer_name] + 1
	else
		CustomTimers.current_time[timer_name] = CustomTimers.current_time[timer_name] - 1
	end

	-- Let's not bother JS if we don't have to (if minimum visual timer == 2 then set math.max 2nd params to 0)
	--	if CustomTimers.current_time[timer_name] == 0 then return end

	local t = CustomTimers.current_time[timer_name]
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
	CustomGameEventManager:Send_ServerToAllClients("countdown_timer", broadcast_gametimer)
end

function CustomTimers:IncrementGamePhase()
	CustomTimers.game_phase = CustomTimers.game_phase + 1
	Notifications:TopToAll({ text = "GAME PHASE: Entering phase " .. CustomTimers.game_phase .. " !", duration = 5.0 })

	if CustomTimers.game_phase == 2 then
		Notifications:TopToAll({ text = "Destroyer Magnataurs killed!", style = { continue = true }, duration = 5.0 })
	elseif CustomTimers.game_phase == 3 then
		Notifications:TopToAll({ text = "Respawn disabled!", style = { continue = true } })
	end
end

function SpecialWave(iCardinalPoint)
	if CustomTimers.game_phase > 2 then return end

	CustomTimers.current_time["special_wave"] = XHS_SPECIAL_WAVE_INTERVAL + 1

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

	local real_point = "npc_dota_spawner_" .. point[iCardinalPoint] .. "_event"

	for j = 1, 10 do
		CreateUnitByName(unit[CustomTimers.special_wave], Entities:FindByName(nil, real_point):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
	end

	CustomTimers.special_wave = CustomTimers.special_wave + 1

	EmitSoundOnLocationForAllies(Entities:FindByName(nil, real_point):GetAbsOrigin(), "Ability.Roar", caster)

	Timers:CreateTimer(1.9, function()
		Entities:FindByName(nil, real_point):StopSound("Ability.Roar")
	end)
end
