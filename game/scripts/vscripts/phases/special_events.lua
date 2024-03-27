if not SpecialEvents then
	SpecialEvents = class({})
	SpecialEvents.hero_farm_event = {}
	SpecialEvents.Ramero_trigger = 0
end

function SpecialEvents:MuradinEvent(time)
	local stun_duration = 5.0

	CustomTimers.current_time["special_event"] = time + stun_duration
	CustomTimers.timers_paused = 1
	GameMode.Muradin_occuring = true
	BT_ENABLED = 0

	StunBuildings(time)
	PauseCreeps()
	PauseHeroes()

	local mode = GameRules:GetGameModeEntity()
	mode:SetFixedRespawnTime(1)

	local Muradin = CreateUnitByName("npc_dota_creature_muradin_bronzebeard", Entities:FindByName(nil, "npc_dota_muradin_boss"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
	Muradin:AddNewModifier(Muradin, nil, "modifier_pause_creeps", { duration = stun_duration }):SetStackCount(1)
	Muradin:AddNewModifier(Muradin, nil, "modifier_invulnerable", { duration = stun_duration })
	Muradin:SetAngles(0, 270, 0)
	Notifications:TopToAll({ hero = "npc_dota_hero_zuus", duration = stun_duration })
	Notifications:TopToAll({ text = " You can't kill him! Just survive the Countdown. ", continue = true })
	Notifications:TopToAll({ text = "Reward: 15 000 Gold.", continue = true })

	-- EmitSoundOn("SantaClaus.StartArena", Muradin) -- todo: add a variable in game-register endpoint to enable/disable this sound during december
	EmitSoundOn("Muradin.StormEarthFire", Muradin)

	for nPlayerID = 0, PlayerResource:GetPlayerCount() - 1 do
		if PlayerResource:HasSelectedHero(nPlayerID) and PlayerResource:GetSelectedHeroEntity(nPlayerID) ~= "npc_dota_hero_wisp" then
			local hero = PlayerResource:GetSelectedHeroEntity(nPlayerID)

			if hero and not hero:IsNull() and hero:IsRealHero() and not hero:HasModifier("modifier_fountain_invulnerability") then
				hero.old_pos = hero:GetAbsOrigin()
				local id = hero:GetPlayerID()
				local point = Entities:FindByName(nil, "npc_dota_muradin_player_" .. id)

				DisableItems(hero, time)
				TeleportHero(hero, point:GetAbsOrigin(), stun_duration - 2.0)
			end
		end
	end

	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("muradin_event"), function()
		RestartHeroes()

		return nil
	end, stun_duration)

	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("muradin_event"), function()
		Notifications:TopToAll({ text = "WARNING: Incoming Wave of Darkness from the East!", duration = 25.0, style = { color = "red" } })
		-- SpawnRunes()

		return nil
	end, time - 30)

	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("muradin_event"), function()
		mode:SetFixedRespawnTime(RESPAWN_TIME)
		CustomTimers.current_time["special_event"] = XHS_SPECIAL_EVENT_INTERVAL + 1
		CustomTimers.current_time["creep_level"] = XHS_CREEPS_UPGRADE_INTERVAL + 1
		BT_ENABLED = 1
		CustomTimers.timers_paused = 0
		RestartCreeps(3.0)
		Notifications:TopToAll({ text = "Special Events are unlocked!", style = { color = "DodgerBlue" }, duration = 5.0 })
		Entities:FindByName(nil, "trigger_special_event_tp_off"):Disable()
		Entities:FindByName(nil, "trigger_special_event"):Enable()
		CustomGameEventManager:Send_ServerToAllClients("update_special_event_label_farm", {})
		SpecialEvents:EndMuradinEvent()

		return nil
	end, time)

	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("muradin_event"), function()
		-- fail-safe, just in case a hero died and had an ankh of reincarnation
		SpecialEvents:EndMuradinEvent()

		Notifications:TopToAll({ text = "All heroes who survived Muradin received " .. XHS_MURADIN_EVENT_GOLD .. " Gold!", duration = 6.0 })
		Notifications:TopToAll({ ability = "alchemist_goblins_greed", continue = true })

		RestartCreeps(0.0)
		UTIL_Remove(Muradin)

		-- SpecialWave(3)

		return nil
	end, time + 6.0)

	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("muradin_event"), function()
		GameMode.Muradin_occuring = false

		return nil
	end, time + 10.0)
end

function SpecialEvents:EndMuradinEvent()
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
		end
		-- end)
	end
end

function SpecialEvents:FarmEvent(time)
	local difficulty = GameRules:GetCustomGameDifficulty()
	local tp_delay = 3.0
	local start_delay = tp_delay + 3.0

	CustomTimers.current_time["special_event"] = time
	CustomTimers.timers_paused = 1
	BT_ENABLED = 0
	GameMode.FarmEvent_occuring = true

	StunBuildings(time)
	PauseCreeps()
	PauseHeroes()

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
		Notifications:TopToAll({ hero = "npc_dota_hero_alchemist", duration = 5.0 })
		Notifications:TopToAll({ text = " It's farming time! Kill as much creeps as you can!", continue = true })

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
						EmitSoundOn("Muradin.StormEarthFire", point)

						local unit = CreateUnitByName(FarmEvent_Creeps[1], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
						unit:SetBaseDamageMin(unit:GetRealDamageDone(unit) + (FARM_EVENT_UPGRADE["damage"][difficulty] * SpecialEvents.hero_farm_event[nPlayerID]["level"]))
						unit:SetBaseDamageMax(unit:GetRealDamageDone(unit) + (FARM_EVENT_UPGRADE["damage"][difficulty] * SpecialEvents.hero_farm_event[nPlayerID]["level"]) * 1.1)
						unit:SetMaxHealth(unit:GetMaxHealth() + (FARM_EVENT_UPGRADE["health"][difficulty] * SpecialEvents.hero_farm_event[nPlayerID]["level"]))
						unit:SetBaseMaxHealth(unit:GetMaxHealth() + (FARM_EVENT_UPGRADE["health"][difficulty] * SpecialEvents.hero_farm_event[nPlayerID]["level"]))
						unit:SetHealth(unit:GetMaxHealth())
						unit:SetPhysicalArmorBaseValue(unit:GetPhysicalArmorValue(false) + (FARM_EVENT_UPGRADE["armor"][difficulty] * SpecialEvents.hero_farm_event[nPlayerID]["level"]))
						if not unit.GrowthOverheadPfx then
							unit.GrowthOverheadPfx = ParticleManager:CreateParticle("particles/units/heroes/hero_abaddon/abaddon_curse_counter_stack.vpcf", PATTACH_OVERHEAD_FOLLOW, unit)
						end

						ParticleManager:SetParticleControl(unit.GrowthOverheadPfx, 1, Vector(0, SpecialEvents.hero_farm_event[nPlayerID]["level"], 0))
						-- local stack_10 = math.floor(SpecialEvents.hero_farm_event[nPlayerID]["level"] / 10)
						-- ParticleManager:SetParticleControl(unit.GrowthOverheadPfx, 2, Vector(stack_10, SpecialEvents.hero_farm_event[nPlayerID]["level"] - stack_10*10, 0))
					end
				end

				DisableItems(hero, time)

				SpecialEvents:FarmEventCreeps(nPlayerID)
			end
		end
	end, start_delay)

	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("muradin_event"), function()
		Notifications:TopToAll({ text = "WARNING: Incoming Wave of Darkness from the North!", duration = 25.0, style = { color = "red" } })
		-- SpawnRunes()

		return nil
	end, time - 20)

	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("muradin_event"), function()
		BT_ENABLED = 1
		SpecialEvents:EndFarmEvent()
		CustomGameEventManager:Send_ServerToAllClients("update_special_event_label_final", {})

		return nil
	end, time)

	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("muradin_event"), function()
		RestartCreeps(0.0)
		SpecialWave(6)

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

					if not unit.GrowthOverheadPfx then
						unit.GrowthOverheadPfx = ParticleManager:CreateParticle("particles/units/heroes/hero_abaddon/abaddon_curse_counter_stack.vpcf", PATTACH_OVERHEAD_FOLLOW, unit)
					end

					ParticleManager:SetParticleControl(unit.GrowthOverheadPfx, 1, Vector(0, SpecialEvents.hero_farm_event[id]["level"], 0))

					-- local stack_10 = math.floor(SpecialEvents.hero_farm_event[id]["level"] / 10)
					-- ParticleManager:SetParticleControl(unit.GrowthOverheadPfx, 2, Vector(stack_10, SpecialEvents.hero_farm_event[id]["level"] - stack_10*10, 0))
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
	CustomTimers.timers_paused = 2

	Notifications:TopToAll({ text = "A hero has reached 500 kills and will fight Ramero and Baristol!", style = { color = "white" }, duration = 5.0 })
	TeleportHero(hero, point, delay)
	PauseCreeps()

	SpecialEvents:RameroAndBaristolEvent(XHS_RAMERO_BARISTOL_TIME + delay)

	SpecialEvents.Ramero_trigger = 1

	hero.old_pos = hero:GetAbsOrigin()
end

function SpecialEvents:RameroAndBaristolEvent(time) -- 500 kills
	local stun_duration = 5.0
	CustomTimers.current_time["special_arena"] = time + stun_duration
	StunBuildings(time)
	CustomGameEventManager:Send_ServerToAllClients("show_timer_special_arena", {})
	GameMode.SpecialArena_occuring = true

	SpecialEvents.Ramero = CreateUnitByName("npc_ramero", Entities:FindByName(nil, "roshan_wp_4"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
	SpecialEvents.Ramero:AddNewModifier(SpecialEvents.Ramero, nil, "modifier_pause_creeps", { duration = stun_duration })
	SpecialEvents.Ramero:AddNewModifier(SpecialEvents.Ramero, nil, "modifier_invulnerable", { duration = stun_duration })
	SpecialEvents.Ramero:SetAngles(0, 45, 0)

	SpecialEvents.Baristol = CreateUnitByName("npc_baristol", Entities:FindByName(nil, "roshan_wp_2"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
	SpecialEvents.Baristol:AddNewModifier(SpecialEvents.Baristol, nil, "modifier_pause_creeps", { duration = stun_duration })
	SpecialEvents.Baristol:AddNewModifier(SpecialEvents.Baristol, nil, "modifier_invulnerable", { duration = stun_duration })
	SpecialEvents.Baristol:SetAngles(0, 325, 0)

	EmitSoundOn("Muradin.StormEarthFire", SpecialEvents.Ramero)

	Notifications:TopToAll({ hero = "npc_dota_hero_sven", duration = stun_duration })
	Notifications:TopToAll({ text = "Kill Ramero and Baristol to get special items! ", continue = true })
	Notifications:TopToAll({ text = "Reward: Lightning Sword and Tome of Stats +250.", continue = true })

	GameRules:GetGameModeEntity():SetContextThink("RameroAndBaristol", function()
		SpecialEvents:EndRameroAndBaristolEvent()

		return nil
	end, time)
end

function SpecialEvents:EndRameroAndBaristolEvent(bWin)
	-- if _G.RAMERO_ARTIFACT_PICKED == true then return end -- if timer is not removed, uncomment this

	_G.RAMERO_ARTIFACT_PICKED = true

	local teleport_time = 3.0
	local mode = GameRules:GetGameModeEntity()

	mode:SetContextThink("RameroAndBaristol", nil, 0)

	RestartCreeps(teleport_time + 3.0)
	UTIL_Remove(_G.RAMERO_DUMMY)
	UTIL_Remove(_G.BARISTOL_DUMMY)

	CustomGameEventManager:Send_ServerToAllClients("hide_timer_special_arena", {})

	if not SpecialEvents.Ramero:IsNull() or not SpecialEvents.Baristol:IsNull() then
		if not SpecialEvents.Ramero:IsNull() then UTIL_Remove(SpecialEvents.Ramero) end
		if not SpecialEvents.Baristol:IsNull() then UTIL_Remove(SpecialEvents.Baristol) end
	end

	if bWin then
		Notifications:TopToAll({ text = "Ramero and Baristol arena has been won!", duration = 5.0 })
	else
		Notifications:TopToAll({ text = "Ramero and Baristol arena has been loss!", duration = 5.0 })
	end

	mode:SetContextThink(DoUniqueString("delay"), function()
		CustomTimers.timers_paused = 0
	end, teleport_time)

	SpecialEvents:ReturnFromSpecialArena()
end

function SpecialEvents:StartSogatEvent(hero)
	local point = Entities:FindByName(nil, "npc_dota_muradin_player_1"):GetAbsOrigin()
	local delay = 5.0

	Notifications:TopToAll({ text = "A hero has reached 750 kills and will fight Ramero!", style = { color = "white" }, duration = 5.0 })
	PauseCreeps()
	TeleportHero(hero, point, delay)

	SpecialEvents:SogatEvent(120.0 + delay)

	SpecialEvents.Ramero_trigger = 2

	hero.old_pos = hero:GetAbsOrigin()
end

function SpecialEvents:SogatEvent(time) -- 750 kills
	local stun_duration = 5.0
	CustomTimers.timers_paused = 2
	CustomTimers.current_time["special_arena"] = time + stun_duration
	StunBuildings(time)
	CustomGameEventManager:Send_ServerToAllClients("show_timer_special_arena", {})
	GameMode.SpecialArena_occuring = true

	SpecialEvents.Sogat = CreateUnitByName("npc_ramero_2", Entities:FindByName(nil, "roshan_wp_4"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
	SpecialEvents.Sogat:AddNewModifier(SpecialEvents.Sogat, nil, "modifier_pause_creeps", { duration = stun_duration })
	SpecialEvents.Sogat:AddNewModifier(SpecialEvents.Sogat, nil, "modifier_invulnerable", { duration = stun_duration })
	SpecialEvents.Sogat:SetAngles(0, 45, 0)
	EmitSoundOn("Muradin.StormEarthFire", SpecialEvents.Sogat)
	Notifications:TopToAll({ hero = "npc_dota_hero_sven", duration = stun_duration })
	Notifications:TopToAll({ text = "Kill Sogat to get a special item! ", continue = true })
	Notifications:TopToAll({ text = "Reward: Ring of Superiority.", continue = true })

	GameRules:GetGameModeEntity():SetContextThink("Sogat", function()
		SpecialEvents:EndSogatEvent()

		return nil
	end, time)
end

function SpecialEvents:EndSogatEvent(bWin)
	-- if _G.SOGAT_ARTIFACT_PICKED == true then return end -- if timer is not removed, uncomment this

	_G.SOGAT_ARTIFACT_PICKED = true

	local teleport_time = 3.0
	local mode = GameRules:GetGameModeEntity()

	mode:SetContextThink("Sogat", nil, 0)

	RestartCreeps(teleport_time + 3.0)
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
	end, teleport_time)

	SpecialEvents:ReturnFromSpecialArena()
end

function SpecialEvents:DuelEvent()
	PauseCreeps()
	-- SpawnRunes()
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
	PauseCreeps()
	-- SpawnRunes()
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

	for _, hero in pairs(SpecialArenaCheck) do
		if hero:IsRealHero() then
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
			end, teleport_time + 1.0)
		end
	end
end
