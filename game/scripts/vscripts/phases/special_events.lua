require('libraries/timers')

function MuradinEvent(time)
	local stun_duration = 5.0
	CustomTimers.current_time["special_event"] = time + stun_duration
	BT_ENABLED = 0
	StunBuildings(time)
	mode = GameRules:GetGameModeEntity()
	mode:SetFixedRespawnTime(1)

	local Muradin = CreateUnitByName("npc_dota_creature_muradin_bronzebeard", Entities:FindByName(nil, "npc_dota_muradin_boss"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
	Muradin:AddNewModifier( nil, nil, "modifier_pause_creeps", {duration = stun_duration}):SetStackCount(1)
	Muradin:AddNewModifier( nil, nil, "modifier_invulnerable", {duration = stun_duration})
	Muradin:SetAngles(0, 270, 0)
--	Muradin:EmitSound("SantaClaus.StartArena")
	EmitSoundOn("Muradin.StormEarthFire", Muradin)
	Notifications:TopToAll({hero="npc_dota_hero_zuus", duration = stun_duration})
	Notifications:TopToAll({text=" You can't kill him! Just survive the Countdown. ", continue=true})
	Notifications:TopToAll({text="Reward: 15 000 Gold.", continue=true})

	for nPlayerID = 0, PlayerResource:GetPlayerCount() -1 do
		if PlayerResource:HasSelectedHero(nPlayerID) and PlayerResource:GetSelectedHeroEntity(nPlayerID) ~= "npc_dota_hero_wisp" then
			local hero = PlayerResource:GetSelectedHeroEntity(nPlayerID)
			hero.old_pos = hero:GetAbsOrigin()
			local id = hero:GetPlayerID()
			local point = Entities:FindByName(nil,"npc_dota_muradin_player_"..id)

			DisableItems(hero, time)
			TeleportHero(hero, point:GetAbsOrigin(), nil, 1.0)
		end
	end

	Timers:CreateTimer(time - 30, function()
		Notifications:TopToAll({text="WARNING: Incoming Wave of Darkness from the East!", duration=25.0, style={color="red"}})
		SpawnRunes()
	end)

	Timers:CreateTimer(time, function()
		SpecialWave(3)
		mode:SetFixedRespawnTime(RESPAWN_TIME)
		CustomTimers.current_time["special_event"] = XHS_SPECIAL_EVENT_INTERVAL + 1
		CustomTimers.current_time["creep_level"] = XHS_CREEPS_UPGRADE_INTERVAL + 1
		BT_ENABLED = 1
		CustomTimers.timers_paused = 0
		RestartCreeps(3.0)
		Notifications:TopToAll({text="Special Events are unlocked!", style={color="DodgerBlue"}, duration=5.0})
		Entities:FindByName(nil, "trigger_special_event_tp_off"):Disable()
		Entities:FindByName(nil, "trigger_special_event"):Enable()
		CustomGameEventManager:Send_ServerToAllClients("update_special_event_label_farm", {})
		EndMuradinEvent()

		Timers:CreateTimer(6, function() -- 14:05 Min: MURADIN BRONZEBEARD EVENT 1, END
			-- fail-safe, just in case a hero died and had an ankh of reincarnation
			EndMuradinEvent()

			Notifications:TopToAll({text="All heroes who survived Muradin received "..XHS_MURADIN_EVENT_GOLD.." Gold!", duration=6.0})
			Notifications:TopToAll({ability="alchemist_goblins_greed", continue = true})

			RestartCreeps(0.0)
			UTIL_Remove(Muradin)
		end)
	end)
end

function EndMuradinEvent()
	local MuradinCheck = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, Entities:FindByName(nil, "npc_dota_muradin_boss"):GetAbsOrigin(), nil, 2000, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE , FIND_ANY_ORDER, false)

	for _, hero in pairs(MuradinCheck) do
		Timers:CreateTimer(function()
			if hero and not hero:IsNull() and hero:IsRealHero() and not hero:IsIllusion() and hero:IsRealHero() and not hero.paid then
				hero.paid = true
				if hero.old_pos then
					TeleportHero(hero, hero.old_pos, 3.0, 1.0)
				else
					if hero:GetTeamNumber() == 2 then
						TeleportHero(hero, base_good:GetAbsOrigin(), 3.0, 1.0)
					elseif hero:GetTeamNumber() == 3 then
						TeleportHero(hero, base_bad:GetAbsOrigin(), 3.0, 1.0)
					end
				end

				PlayerResource:ModifyGold(hero:GetPlayerOwnerID(), XHS_MURADIN_EVENT_GOLD, false, DOTA_ModifyGold_Unspecified)
			end
		end)
	end
end

function FarmEvent(time)
	local difficulty = GameRules:GetCustomGameDifficulty()
	CustomTimers.current_time["special_event"] = time
	BT_ENABLED = 0
	GameMode.hero_farm_event = {}
	StunBuildings(time)

	Notifications:TopToAll({hero="npc_dota_hero_alchemist", duration = 5.0})
	Notifications:TopToAll({text=" It's farming time! Kill as much creeps as you can!", continue = true})

	for nPlayerID = 0, PlayerResource:GetPlayerCount() - 1 do
		if PlayerResource:HasSelectedHero(nPlayerID) and PlayerResource:GetSelectedHeroEntity(nPlayerID) ~= "npc_dota_hero_wisp" then
			local hero = PlayerResource:GetSelectedHeroEntity(nPlayerID)
			hero.old_pos = hero:GetAbsOrigin()
			local point = Entities:FindByName(nil, "farm_event_player_"..nPlayerID)
			EmitSoundOn("Muradin.StormEarthFire", point)

			if nPlayerID == nil then
				Notifications:TopToAll({text="Invalid Steam ID detected!! #ERROR 003 ", duration = 10.0})
				Notifications:TopToAll({text="Please report this bug on Discord!! #ERROR 003 ", continue = true})
			elseif point == nil then
				Notifications:TopToAll({text="Invalid teleport point detected!! #ERROR 004 ", duration = 10.0})
				Notifications:TopToAll({text="Please report this bug on Discord!! #ERROR 004 ", continue = true})
			else
				TeleportHero(hero, point:GetAbsOrigin(), nil, 1.0)
			end

			GameMode.hero_farm_event[nPlayerID] = {}
			GameMode.hero_farm_event[nPlayerID]["round"] = 1
			GameMode.hero_farm_event[nPlayerID]["level"] = 1

			for j = 1, 10 do
				local unit = CreateUnitByName(FarmEvent_Creeps[1], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
				unit:SetBaseDamageMin(unit:GetRealDamageDone(unit) + (FARM_EVENT_UPGRADE["damage"][difficulty] * GameMode.hero_farm_event[nPlayerID]["level"]))
				unit:SetBaseDamageMax(unit:GetRealDamageDone(unit) + (FARM_EVENT_UPGRADE["damage"][difficulty] * GameMode.hero_farm_event[nPlayerID]["level"]) * 1.1)
				unit:SetMaxHealth(unit:GetMaxHealth() + (FARM_EVENT_UPGRADE["health"][difficulty] * GameMode.hero_farm_event[nPlayerID]["level"]))
				unit:SetBaseMaxHealth(unit:GetMaxHealth() + (FARM_EVENT_UPGRADE["health"][difficulty] * GameMode.hero_farm_event[nPlayerID]["level"]))
				unit:SetHealth(unit:GetMaxHealth())
				unit:SetPhysicalArmorBaseValue(unit:GetPhysicalArmorValue(false) + (FARM_EVENT_UPGRADE["armor"][difficulty] * GameMode.hero_farm_event[nPlayerID]["level"]))
				if not unit.GrowthOverheadPfx then 
					unit.GrowthOverheadPfx = ParticleManager:CreateParticle("particles/hw_fx/candy_carrying_stack.vpcf", PATTACH_OVERHEAD_FOLLOW, unit)
					ParticleManager:SetParticleControl(unit.GrowthOverheadPfx, 0, unit:GetAbsOrigin())
				end
				local stack_10 = math.floor(GameMode.hero_farm_event[nPlayerID]["level"] / 10)
				ParticleManager:SetParticleControl(unit.GrowthOverheadPfx, 2, Vector(stack_10, GameMode.hero_farm_event[nPlayerID]["level"] - stack_10*10, 0))
			end

			DisableItems(hero, time)

			FarmEventCreeps(nPlayerID)
		end
	end

	Timers:CreateTimer(time-20, function() -- 150
		Notifications:TopToAll({text="WARNING: Incoming Wave of Darkness from the North!", duration=25.0, style={color="red"}})
		SpawnRunes()
	end)

	local additional_delay = 10.0

	Timers:CreateTimer(time, function()
		BT_ENABLED = 1
		EndFarmEvent()
		CustomGameEventManager:Send_ServerToAllClients("update_special_event_label_final", {})

		Timers:CreateTimer(additional_delay, function()
			RestartCreeps(0.0)
			SpecialWave(6)
		end)
	end)
end

function FarmEventCreeps(id)
	local point = Entities:FindByName(nil, "farm_event_player_"..id)
	local difficulty = GameRules:GetCustomGameDifficulty()

	Timers:CreateTimer(function()
		local units = FindUnitsInRadius(DOTA_TEAM_CUSTOM_2, point:GetAbsOrigin(), nil, 1200, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

		if CustomTimers.timers_paused == 1 then
			if #units <= 1 then
				GameMode.hero_farm_event[id]["round"] = (GameMode.hero_farm_event[id]["round"] + 1) % 9

				if GameMode.hero_farm_event[id]["round"] == 0 then
					GameMode.hero_farm_event[id]["level"] = (GameMode.hero_farm_event[id]["level"] + 1)
				end

				for j = 1, 10 do
					local unit = CreateUnitByName(FarmEvent_Creeps[GameMode.hero_farm_event[id]["round"] + 1], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
					unit:SetBaseDamageMin(unit:GetRealDamageDone(unit) + (FARM_EVENT_UPGRADE["damage"][difficulty] * GameMode.hero_farm_event[id]["level"]) * 0.95)
					unit:SetBaseDamageMax(unit:GetRealDamageDone(unit) + (FARM_EVENT_UPGRADE["damage"][difficulty] * GameMode.hero_farm_event[id]["level"]) * 1.05)
					unit:SetMaxHealth(unit:GetMaxHealth() + (FARM_EVENT_UPGRADE["health"][difficulty] * GameMode.hero_farm_event[id]["level"]))
					unit:SetBaseMaxHealth(unit:GetMaxHealth() + (FARM_EVENT_UPGRADE["health"][difficulty] * GameMode.hero_farm_event[id]["level"]))
					unit:SetHealth(unit:GetMaxHealth())
					unit:SetPhysicalArmorBaseValue(unit:GetPhysicalArmorValue(false) + (FARM_EVENT_UPGRADE["armor"][difficulty] * GameMode.hero_farm_event[id]["level"]))

					if not unit.GrowthOverheadPfx then 
						unit.GrowthOverheadPfx = ParticleManager:CreateParticle("particles/hw_fx/candy_carrying_stack.vpcf", PATTACH_OVERHEAD_FOLLOW, unit)
						ParticleManager:SetParticleControl(unit.GrowthOverheadPfx, 0, unit:GetAbsOrigin())
					end

					local stack_10 = math.floor(GameMode.hero_farm_event[id]["level"] / 10)
					ParticleManager:SetParticleControl(unit.GrowthOverheadPfx, 2, Vector(stack_10, GameMode.hero_farm_event[id]["level"] - stack_10*10, 0))
				end
			end

			return 1
		end
	end)
end

function EndFarmEvent()
	CustomTimers.timers_paused = 2

	for _, hero in pairs(HeroList:GetAllHeroes()) do
		RefreshPlayers()

		if hero:IsRealHero() then
			if hero.old_pos then
				TeleportHero(hero, hero.old_pos, 3.0)
			else
				if hero:GetTeamNumber() == 2 then
					TeleportHero(hero, base_good:GetAbsOrigin(), 3.0)
				elseif hero:GetTeamNumber() == 3 then
					TeleportHero(hero, base_bad:GetAbsOrigin(), 3.0)
				end
			end
			hero:Stop()
		end
	end

	local units = FindUnitsInRadius(DOTA_TEAM_CUSTOM_2, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE , FIND_ANY_ORDER, false)
	for _,v in pairs(units) do
		if v:IsCreature() and v:HasMovementCapability() and v:GetUnitName() ~= "npc_dota_boss_lich_king" then
			UTIL_Remove(v)
		end
	end

	-- Start Phase 2
	for NumPlayers = 1, PlayerResource:GetPlayerCount() * CREEP_LANES_TYPE do
		local rax_spawner = Entities:FindByName(nil, "npc_dota_spawner_"..NumPlayers)

		if rax_spawner then
			SpawnMagnataur(rax_spawner:GetAbsOrigin())
			print("npc_dota_spawner_"..NumPlayers.." removed.")
			rax_spawner.disabled = true
		end
	end

	if PHASE_2_QUEST_UNIT and IsValidEntity(PHASE_2_QUEST_UNIT) and PHASE_2_QUEST_UNIT:IsAlive() then
		print("Kill phase 2 unit and move on!")
		PHASE_2_QUEST_UNIT:ForceKill(false)
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

	Notifications:TopToAll({text="Phase 2 begins! (Destroyer Magnataur launched)", duration=10.0, style={color="red"}})
end

function StartRameroAndBaristolEvent(hero)
	local point = Entities:FindByName(nil, "npc_dota_muradin_player_1"):GetAbsOrigin()
	local delay = 5.0
	CustomTimers.timers_paused = 2

	Notifications:TopToAll({text="A hero has reached 500 kills and will fight Ramero and Baristol!", style={color="white"}, duration=5.0})
	TeleportHero(hero, point, delay)
	PauseCreeps()

	RameroAndBaristolEvent(120 + delay)

	RAMERO = 1
	hero.old_pos = hero:GetAbsOrigin()
end

function RameroAndBaristolEvent(time) -- 500 kills
	local stun_duration = 5.0
	CustomTimers.current_time["special_arena"] = time + stun_duration
	StunBuildings(time)
	CustomGameEventManager:Send_ServerToAllClients("show_timer_special_arena", {})
	GameMode.SpecialArena_occuring = 1

	local Ramero = CreateUnitByName("npc_ramero", Entities:FindByName(nil, "roshan_wp_4"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
	Ramero:AddNewModifier( nil, nil, "modifier_pause_creeps", {duration = stun_duration})
	Ramero:AddNewModifier( nil, nil, "modifier_invulnerable", {duration = stun_duration})
	Ramero:SetAngles(0, 45, 0)
	local Baristol = CreateUnitByName("npc_baristol", Entities:FindByName(nil, "roshan_wp_2"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
	Baristol:AddNewModifier( nil, nil, "modifier_pause_creeps", {duration = stun_duration})
	Baristol:AddNewModifier( nil, nil, "modifier_invulnerable", {duration = stun_duration})
	Baristol:SetAngles(0, 325, 0)
	EmitSoundOn("Muradin.StormEarthFire", Ramero)
	Notifications:TopToAll({hero="npc_dota_hero_sven", duration = stun_duration})
	Notifications:TopToAll({text="Kill Ramero and Baristol to get special items! ", continue=true})
	Notifications:TopToAll({text="Reward: Lightning Sword and Tome of Stats +250.", continue=true})

	timers.RameroAndBaristol = Timers:CreateTimer(time, function() -- Teleport back to the spawn
		CustomTimers.timers_paused = 0
		local teleport_time = 3.0
		RestartCreeps(teleport_time + 3.0)
		UTIL_Remove(_G.RAMERO_DUMMY)
		UTIL_Remove(_G.BARISTOL_DUMMY)
		CustomGameEventManager:Send_ServerToAllClients("hide_timer_special_arena", {})
		GameMode.SpecialArena_occuring = 0

		if Ramero:IsNull() and Baristol:IsNull() then
			return
		else
			UTIL_Remove(Ramero)
			UTIL_Remove(Baristol)

			local Check = 0
			Notifications:TopToAll({text="Ramero and Baristol arena has been loss!", duration=5.0})
			Timers:CreateTimer(function()
				if Check < 2 then
					local RameroAndBaristolCheck = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, Entities:FindByName(nil, "npc_dota_muradin_boss"):GetAbsOrigin(), nil, 2000, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE , FIND_ANY_ORDER, false)
					for _, hero in pairs(RameroAndBaristolCheck) do
						if hero:IsRealHero() then
							TeleportHero(hero, base_good:GetAbsOrigin(), teleport_time)
							RestartCreeps(teleport_time + 3.0)
						end
					end
					Check = Check +1
					return 5
				end
			end)
		end
	end)
end

function StartSogatEvent(hero)
	local point = Entities:FindByName(nil, "npc_dota_muradin_player_1"):GetAbsOrigin()
	local delay = 5.0

	Notifications:TopToAll({text="A hero has reached 750 kills and will fight Ramero!", style={color="white"}, duration=5.0})
	PauseCreeps()
	TeleportHero(hero, point, delay)

	SogatEvent(120.0 + delay)

	RAMERO = 2
	hero.old_pos = hero:GetAbsOrigin()
end

function SogatEvent(time) -- 750 kills
	local stun_duration = 5.0
	CustomTimers.timers_paused = 2
	CustomTimers.current_time["special_arena"] = time + stun_duration
	StunBuildings(time)
	CustomGameEventManager:Send_ServerToAllClients("show_timer_special_arena", {})
	GameMode.SpecialArena_occuring = 1

	local Ramero = CreateUnitByName("npc_ramero_2", Entities:FindByName(nil, "roshan_wp_4"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
	Ramero:AddNewModifier( nil, nil, "modifier_pause_creeps", {duration = stun_duration})
	Ramero:AddNewModifier( nil, nil, "modifier_invulnerable", {duration = stun_duration})
	Ramero:SetAngles(0, 45, 0)
	EmitSoundOn("Muradin.StormEarthFire", Ramero)
	Notifications:TopToAll({hero="npc_dota_hero_sven", duration = stun_duration})
	Notifications:TopToAll({text="Kill Sogat to get a special item! ", continue = true})
	Notifications:TopToAll({text="Reward: Ring of Superiority.", continue = true})

	timers.Ramero = Timers:CreateTimer(time, function() -- Teleport back to the spawn
		CustomTimers.timers_paused = 0
		local teleport_time = 3.0
		RestartCreeps(teleport_time + 3.0)
		UTIL_Remove(_G.RAMERO_BIS_DUMMY)
		CustomGameEventManager:Send_ServerToAllClients("hide_timer_special_arena", {})
		GameMode.SpecialArena_occuring = 0

		if Ramero:IsNull() then
			return
		else
			UTIL_Remove(Ramero)

			local Check = 0
			Notifications:TopToAll({text="Ramero arena has been loss!", duration=5.0})
			Timers:CreateTimer(0.0, function()
				if Check < 5 then
					local RameroCheck = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, Entities:FindByName(nil, "npc_dota_muradin_boss"):GetAbsOrigin(), nil, 2000, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE , FIND_ANY_ORDER, false)
					for _, hero in pairs(RameroCheck) do
						if hero:IsRealHero() then
							FindClearSpaceForUnit(hero, base_good:GetAbsOrigin(), true)
						end
					end
					Check = Check +1
					return 1
				end
			end)
		end
	end)
end

function DuelEvent()
PauseCreeps()
SpawnRunes()
CustomGameEventManager:Send_ServerToAllClients("show_duel", {})

	Notifications:TopToAll({text="Fight your team mates until 1 team survives!", duration=10.0, style={color="white"}})

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

				local point = Entities:FindByName(nil, "duel_event_"..ID)
				TeleportHero(hero, point:GetAbsOrigin(), 3.0)

				-- Duel Settings
				hero:SetPhysicalArmorBaseValue(0 - hero:GetPhysicalArmorValue(false)*0.80) -- Remove 80% of the heroes armor

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
				TeleportHero(hero, base_good:GetAbsOrigin(), 3.0)
			elseif hero:GetTeamNumber() == 3 then
				TeleportHero(hero, base_bad:GetAbsOrigin(), 3.0)
			end
			Notifications:TopToAll({text="Disconnected hero detected, teleporting out of arena!", duration=5.0, style={color="white"}})
		end
	end

	-- WIN Conditions
	local RadiantCheck = 0
	local DireCheck = 0
	timers.Duel = Timers:CreateTimer(1.0, function()
		local RadiantPlayers = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE , FIND_ANY_ORDER, false)
		local DirePlayers = FindUnitsInRadius(DOTA_TEAM_BADGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE , FIND_ANY_ORDER, false)
		local RadiantNumber = 0
		local DireNumber = 0

		--Count the number of players alive in each teams
		for _, unit in pairs(RadiantPlayers) do
			if unit:IsAlive() then
				RadiantNumber = RadiantNumber +1
			end
		end
		for _, unit in pairs(DirePlayers) do
			if unit:IsAlive() then
				DireNumber = DireNumber +1
			end
		end

		if RadiantNumber == 0 then --if a whole team is dead then
			RadiantCheck = RadiantCheck +1
		elseif RadiantNumber > 0 then --elseif a player revives
			RadiantCheck = 0
		end
		if RadiantCheck >= 7 then --if a whole team is dead during 7 seconds then
			GameRules:SetGameWinner(DOTA_TEAM_BADGUYS)
			print("Dire Win!")
		end

		if DireNumber == 0 then
			DireCheck = DireCheck +1
		elseif DireNumber > 0 then
			DireCheck = 0
		end
		if DireCheck >= 7 then
			GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
			print("Radiant Win!")
		end

		print("Radiant Check: "..RadiantCheck)
		print("Dire Check: "..DireCheck)
		print("Duel Score: "..RadiantNumber.."/"..DireNumber)
		return 1.0
	end)
end

function DuelRanked()
PauseCreeps()
SpawnRunes()
--	CustomGameEventManager:Send_ServerToAllClients("show_duel", {})

	Notifications:TopToAll({text="It's Duel Time!", duration=5.0, style={color="white"}})

	-- Initialize duel
	for _, hero in pairs(HeroList:GetAllHeroes()) do
		local ID = hero:GetPlayerID()
		hero:SetRespawnsDisabled(true)
		if PlayerResource:GetConnectionState() == 2 then
			if PlayerResource:IsValidPlayerID(hero:GetPlayerOwnerID()) and hero:IsRealHero() then
				local point = Entities:FindByName(nil, "duel_event_"..ID)
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
				TeleportHero(hero, base_good:GetAbsOrigin(), 3.0)
			elseif hero:GetTeamNumber() == 3 then
				TeleportHero(hero, base_bad:GetAbsOrigin(), 3.0)
			end
			Notifications:TopToAll({text="Disconnected hero detected, teleporting out of arena!", duration=5.0, style={color="white"}})
		end
	end

	-- WIN Conditions
	local RadiantCheck = 0
	local DireCheck = 0
	timers.Duel = Timers:CreateTimer(1.0, function()
		local RadiantPlayers = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE , FIND_ANY_ORDER, false)
		local DirePlayers = FindUnitsInRadius(DOTA_TEAM_BADGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE , FIND_ANY_ORDER, false)
		local RadiantNumber = 0
		local DireNumber = 0

		--Count the number of players alive in each teams
		for _, unit in pairs(RadiantPlayers) do
			if unit:IsAlive() then
				RadiantNumber = RadiantNumber +1
			end
		end
		for _, unit in pairs(DirePlayers) do
			if unit:IsAlive() then
				DireNumber = DireNumber +1
			end
		end

		if RadiantNumber == 0 then --if a whole team is dead then
			RadiantCheck = RadiantCheck +1
		elseif RadiantNumber > 0 then --elseif a player revives
			RadiantCheck = 0
		end
		if RadiantCheck >= 7 then --if a whole team is dead during 7 seconds then
			GameRules:SetGameWinner(DOTA_TEAM_BADGUYS)
			print("Dire Win!")
		end

		if DireNumber == 0 then
			DireCheck = DireCheck +1
		elseif DireNumber > 0 then
			DireCheck = 0
		end
		if DireCheck >= 7 then
			GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
			print("Radiant Win!")
		end

		print("Radiant Check: "..RadiantCheck)
		print("Dire Check: "..DireCheck)
		print("Duel Score: "..RadiantNumber.."/"..DireNumber)
		return 1.0
	end)
end
