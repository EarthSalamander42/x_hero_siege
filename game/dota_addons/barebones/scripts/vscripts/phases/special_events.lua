require('libraries/timers')

function MuradinEvent() -- 12 Min, lasts 2 Min.
local teleporters = Entities:FindAllByName("trigger_teleport_muradin_end")
local heroes = HeroList:GetAllHeroes()
nCOUNTDOWNTIMER = 121
BT_ENABLED = 0
mode = GameRules:GetGameModeEntity()
mode:SetFixedRespawnTime(1)
	local Muradin = CreateUnitByName("npc_dota_creature_muradin_bronzebeard", Entities:FindByName(nil, "npc_dota_muradin_boss"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
	Muradin:AddNewModifier( nil, nil, "modifier_boss_stun", {duration = 5})
	Muradin:AddNewModifier( nil, nil, "modifier_invulnerable", {duration = 5})
	Muradin:SetAngles(0, 270, 0)
	Muradin:EmitSound("Muradin.StormEarthFire")
--	Muradin:EmitSound("SantaClaus.StartArena")
	Notifications:TopToAll({hero="npc_dota_hero_zuus", duration=5.0})
	Notifications:TopToAll({text=" You can't kill him! Just survive the Countdown. ", continue=true})
	Notifications:TopToAll({text="Reward: 15 000 Gold.", continue=true})
	for _, hero in pairs(heroes) do
	local id = hero:GetPlayerID()
		if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
		local point = Entities:FindByName(nil,"npc_dota_muradin_player_"..id)
			FindClearSpaceForUnit(hero, point:GetAbsOrigin(), true)
			PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), hero)
			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), nil)
			end)

			timers.disabled_items = Timers:CreateTimer(0.0, function()
				for itemSlot = 0, 5 do
				local item = hero:GetItemInSlot(itemSlot)
					if item ~= nil and item:GetName() == "item_tome_small" then
						item:StartCooldown(120.0)
					end
					if item ~= nil and item:GetName() == "item_tome_big" then
						item:StartCooldown(120.0)
					end
					if item ~= nil and item:GetName() == "item_tpscroll" then
						item:StartCooldown(120.0)
					end
				end
			end)
		elseif hero:GetTeam() == DOTA_TEAM_GOODGUYS and not PlayerResource:IsValidPlayerID(id) and hero:GetUnitName() == "npc_dota_hero_meepo" then
			-- Do not send message error 002
		else
--			Notifications:TopToAll({text="Invalid Steam ID detected!! #ERROR 002 ", duration = 10.0})
--			Notifications:TopToAll({text="Please report this bug on Discord Chat!! #ERROR 002 ", continue = true})
		end
	end

	Timers:CreateTimer(120, function() -- 14:00 Min, teleport back to the spawn
		for _,v in pairs(teleporters) do
			v:Enable()
		end

		UTIL_Remove(Muradin)
		mode:SetFixedRespawnTime(40)
		nCOUNTDOWNCREEP = 360
		nCOUNTDOWNINCWAVE = 240
		nCOUNTDOWNTIMER = 600
		BT_ENABLED = 1
		SPECIAL_EVENT = 0
		RestartCreeps()
	end)
	Timers:CreateTimer(126, function() -- 14:05 Min: MURADIN BRONZEBEARD EVENT 1, END
		Notifications:TopToAll({text="All heroes who survived Muradin received 15 000 Gold!", duration=6.0})
		Notifications:TopToAll({ability="alchemist_goblins_greed", continue = true})
		RestartCreeps()
		for _,v in pairs(teleporters) do
			v:Disable()
		end
	end)
end

function EndMuradinEvent(keys)
local activator = keys.activator
local point = Entities:FindByName(nil, "base_spawn"):GetAbsOrigin()
	if activator:GetTeam() == DOTA_TEAM_GOODGUYS then
	FindClearSpaceForUnit(activator, point, true)
	PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(), activator)
	Timers:CreateTimer(0.5, function()
		PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(), nil)
	end)
	activator:Stop()
	PlayerResource:ModifyGold( activator:GetPlayerOwnerID(), 15000, false,  DOTA_ModifyGold_Unspecified )
	end
end

function FarmEvent() -- 24 Min, lasts 3 Min.
nCOUNTDOWNTIMER = 180
nCOUNTDOWNCREEP = 1
nCOUNTDOWNINCWAVE = 1
BT_ENABLED = 0
GameMode.hero_farm_event = {}
local heroes = HeroList:GetAllHeroes()

	Notifications:TopToAll({hero="npc_dota_hero_alchemist", duration=5.0})
	Notifications:TopToAll({text=" It's farming time! Kill as much creeps as you can!", continue = true})

	Timers:CreateTimer(180, function() -- 27:00 Min, teleport back to the spawn
		local units = FindUnitsInRadius(DOTA_TEAM_CUSTOM_1, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE , FIND_ANY_ORDER, false)
		local teleporters = Entities:FindAllByName("trigger_farm_event")

		nCOUNTDOWNINCWAVE = 240
		BT_ENABLED = 1
		SPECIAL_EVENT = 0
		RestartCreeps()

		for _,v in pairs(teleporters) do
			v:Enable()
		end

		Timers:CreateTimer(0.1, function()
			for _,v in pairs(units) do
				UTIL_Remove(v)
			end
		end)

		Timers:CreateTimer(10.0, function()
			RestartCreeps()
		end)
	end)

	for _, hero in pairs(heroes) do
		if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
			local id = hero:GetPlayerID()
			local point = Entities:FindByName(nil, "farm_event_player_"..id)

			for j = 1, 10 do
				FindClearSpaceForUnit(hero, point:GetAbsOrigin(), true)
				PlayerResource:SetCameraTarget(hero:GetPlayerID(), hero)
				local unit = CreateUnitByName(FarmEvent_Creeps[1], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
			end

			for PlayerID = 0, 7 do
				GameMode.hero_farm_event[PlayerID] = {}
				GameMode.hero_farm_event[PlayerID]["round"] = 1
			end

			Farm1 = Timers:CreateTimer(0.1, FarmEventCreeps0)
			Farm2 = Timers:CreateTimer(0.1, FarmEventCreeps1)
			Farm3 = Timers:CreateTimer(0.1, FarmEventCreeps2)
			Farm4 = Timers:CreateTimer(0.1, FarmEventCreeps3)
			Farm5 = Timers:CreateTimer(0.1, FarmEventCreeps4)
			Farm6 = Timers:CreateTimer(0.1, FarmEventCreeps5)
			Farm7 = Timers:CreateTimer(0.1, FarmEventCreeps6)
			Farm8 = Timers:CreateTimer(0.1, FarmEventCreeps7)

			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(hero:GetPlayerID(), nil)
			end)

			timers.disabled_items = Timers:CreateTimer(0.0, function()
			local ability = hero:FindAbilityByName("holdout_blink")
				for itemSlot = 0, 5 do
				local item = hero:GetItemInSlot(itemSlot)
					if item ~= nil and item:GetName() == "item_tome_small" then
						item:StartCooldown(180.0)
					end
					if item ~= nil and item:GetName() == "item_tome_big" then
						item:StartCooldown(180.0)
					end
					if item ~= nil and item:GetName() == "item_boots_of_speed" then
						item:StartCooldown(180.0)
					end
					if item ~= nil and item:GetName() == "item_tpscroll" then
					item:StartCooldown(180.0)
					end
				end
				if ability then
					ability:StartCooldown(180.0)
				end
			end)
		else
			Notifications:TopToAll({text="Invalid Steam ID detected!! #ERROR 001 ", duration = 10.0})
			Notifications:TopToAll({text="Please report this bug on Discord Chat!! #ERROR 001 ", continue = true})
		end
	end
end

function FarmEventCreeps0()
	local point = Entities:FindByName(nil, "farm_event_player_0")
	local units = FindUnitsInRadius(DOTA_TEAM_CUSTOM_1, point:GetAbsOrigin(), nil, 1200, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
	local number = 0
	for _,v in pairs(units) do
		number = number +1
	end

	if number <= 1 and SPECIAL_EVENT == 1 then
		GameMode.hero_farm_event[0]["round"] = (GameMode.hero_farm_event[0]["round"] + 1) % 9
		for j = 1, 10 do
			local unit = CreateUnitByName(FarmEvent_Creeps[GameMode.hero_farm_event[0]["round"] + 1], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
		end
	end
	return 1
end

function FarmEventCreeps1()
	local point = Entities:FindByName(nil, "farm_event_player_1")
	local units = FindUnitsInRadius(DOTA_TEAM_CUSTOM_1, point:GetAbsOrigin(), nil, 1200, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
	local number = 0
	for _,v in pairs(units) do
		number = number +1
	end

	if number <= 1 and SPECIAL_EVENT == 1 then
		GameMode.hero_farm_event[1]["round"] = (GameMode.hero_farm_event[1]["round"] + 1) % 9
		for j = 1, 10 do
			local unit = CreateUnitByName(FarmEvent_Creeps[GameMode.hero_farm_event[1]["round"] + 1], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
		end
	end
	return 1
end

function FarmEventCreeps2()
	local point = Entities:FindByName(nil, "farm_event_player_2")
	local units = FindUnitsInRadius(DOTA_TEAM_CUSTOM_1, point:GetAbsOrigin(), nil, 1200, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
	local number = 0
	for _,v in pairs(units) do
		number = number +1
	end

	if number <= 1 and SPECIAL_EVENT == 1 then
		GameMode.hero_farm_event[2]["round"] = (GameMode.hero_farm_event[2]["round"] + 1) % 9
		for j = 1, 10 do
			local unit = CreateUnitByName(FarmEvent_Creeps[GameMode.hero_farm_event[2]["round"] + 1], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
		end
	end
	return 1
end

function FarmEventCreeps3()
	local point = Entities:FindByName(nil, "farm_event_player_3")
	local units = FindUnitsInRadius(DOTA_TEAM_CUSTOM_1, point:GetAbsOrigin(), nil, 1200, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
	local number = 0
	for _,v in pairs(units) do
		number = number +1
	end

	if number <= 1 and SPECIAL_EVENT == 1 then
		GameMode.hero_farm_event[3]["round"] = (GameMode.hero_farm_event[3]["round"] + 1) % 9
		for j = 1, 10 do
			local unit = CreateUnitByName(FarmEvent_Creeps[GameMode.hero_farm_event[3]["round"] + 1], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
		end
	end
	return 1
end

function FarmEventCreeps4()
	local point = Entities:FindByName(nil, "farm_event_player_4")
	local units = FindUnitsInRadius(DOTA_TEAM_CUSTOM_1, point:GetAbsOrigin(), nil, 1200, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
	local number = 0
	for _,v in pairs(units) do
		number = number +1
	end

	if number <= 1 and SPECIAL_EVENT == 1 then
		GameMode.hero_farm_event[4]["round"] = (GameMode.hero_farm_event[4]["round"] + 1) % 9
		for j = 1, 10 do
			local unit = CreateUnitByName(FarmEvent_Creeps[GameMode.hero_farm_event[4]["round"] + 1], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
		end
	end
	return 1
end

function FarmEventCreeps5()
	local point = Entities:FindByName(nil, "farm_event_player_5")
	local units = FindUnitsInRadius(DOTA_TEAM_CUSTOM_1, point:GetAbsOrigin(), nil, 1200, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
	local number = 0
	for _,v in pairs(units) do
		number = number +1
	end

	if number <= 1 and SPECIAL_EVENT == 1 then
		GameMode.hero_farm_event[5]["round"] = (GameMode.hero_farm_event[5]["round"] + 1) % 9
		for j = 1, 10 do
			local unit = CreateUnitByName(FarmEvent_Creeps[GameMode.hero_farm_event[5]["round"] + 1], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
		end
	end
	return 1
end

function FarmEventCreeps6()
	local point = Entities:FindByName(nil, "farm_event_player_6")
	local units = FindUnitsInRadius(DOTA_TEAM_CUSTOM_1, point:GetAbsOrigin(), nil, 1200, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
	local number = 0
	for _,v in pairs(units) do
		number = number +1
	end

	if number <= 1 and SPECIAL_EVENT == 1 then
		GameMode.hero_farm_event[6]["round"] = (GameMode.hero_farm_event[6]["round"] + 1) % 9
		for j = 1, 10 do
			local unit = CreateUnitByName(FarmEvent_Creeps[GameMode.hero_farm_event[6]["round"] + 1], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
		end
	end
	return 1
end

function FarmEventCreeps7()
	local point = Entities:FindByName(nil, "farm_event_player_7")
	local units = FindUnitsInRadius(DOTA_TEAM_CUSTOM_1, point:GetAbsOrigin(), nil, 1200, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
	local number = 0
	for _,v in pairs(units) do
		number = number +1
	end

	if number <= 1 and SPECIAL_EVENT == 1 then
		GameMode.hero_farm_event[7]["round"] = (GameMode.hero_farm_event[7]["round"] + 1) % 9
		for j = 1, 10 do
			local unit = CreateUnitByName(FarmEvent_Creeps[GameMode.hero_farm_event[7]["round"] + 1], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
		end
	end
	return 1
end

function EndFarmEvent(keys)
local activator = keys.activator
local point = Entities:FindByName(nil,"base_spawn"):GetAbsOrigin()
	if activator:GetTeam() == DOTA_TEAM_GOODGUYS then
	FindClearSpaceForUnit(activator, point, true)
	PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(), activator)
	Timers:CreateTimer(0.1, function()
		PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(), nil)
	end)
	activator:Stop()
	end

	local units = FindUnitsInRadius(DOTA_TEAM_CUSTOM_1, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE , FIND_ANY_ORDER, false)
	for _,v in pairs(units) do
		if v:IsCreature() and v:HasMovementCapability() then
			UTIL_Remove(v)
		end
	end
end

function RameroEvent() -- 750 kills
SPECIAL_EVENT = 1
local teleporters = Entities:FindAllByName("trigger_teleport_ramero_end")
nCOUNTDOWNTIMER = 121
PauseCreeps()

	local Ramero = CreateUnitByName("npc_ramero_2", Entities:FindByName(nil, "roshan_wp_4"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
	Ramero:AddNewModifier( nil, nil, "modifier_boss_stun", {duration = 5})
	Ramero:AddNewModifier( nil, nil, "modifier_invulnerable", {duration = 5})
	Ramero:SetAngles(0, 45, 0)
--	Ramero:EmitSound("Muradin.StormEarthFire")
	Notifications:TopToAll({hero="npc_dota_hero_sven", duration = 5.0})
	Notifications:TopToAll({text="Kill Ramero to get special items! ", continue = true})
	Notifications:TopToAll({text="Reward: Ring of Superiority.", continue = true})

	timers.Ramero = Timers:CreateTimer(120, function() -- Teleport back to the spawn
		for _,v in pairs(teleporters) do
			v:Enable()
		end
		SPECIAL_EVENT = 0
		UTIL_Remove(Ramero)
		RestartCreeps()
	end)

	Timers:CreateTimer(126, function() -- 14:05 Min: MURADIN BRONZEBEARD EVENT 1, END
--		Notifications:TopToAll({text="Ramero and Baristol won the duel!", duration = 6.0})
		for _,v in pairs(teleporters) do
			v:Disable()
		end
	end)

	UTIL_Remove(RAMERO_BIS_DUMMY)
end

function RameroAndBaristolEvent() -- 500 kills
local teleporters = Entities:FindAllByName("trigger_teleport_ramero_end")
nCOUNTDOWNTIMER = 121
SPECIAL_EVENT = 1

	local Ramero = CreateUnitByName("npc_ramero", Entities:FindByName(nil, "roshan_wp_4"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
	Ramero:AddNewModifier( nil, nil, "modifier_boss_stun", {duration = 5})
	Ramero:AddNewModifier( nil, nil, "modifier_invulnerable", {duration = 5})
	Ramero:SetAngles(0, 45, 0)
	local Baristol = CreateUnitByName("npc_baristol", Entities:FindByName(nil, "roshan_wp_2"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
	Baristol:AddNewModifier( nil, nil, "modifier_boss_stun", {duration = 5})
	Baristol:AddNewModifier( nil, nil, "modifier_invulnerable", {duration = 5})
	Baristol:SetAngles(0, 325, 0)
--	Ramero:EmitSound("Muradin.StormEarthFire")
	Notifications:TopToAll({hero="npc_dota_hero_sven", duration=5.0})
	Notifications:TopToAll({text="Kill Ramero and Baristol to get special items! ", continue=true})
	Notifications:TopToAll({text="Reward: Lightning Sword and Tome of Stats +250.", continue=true})

	timers.RameroAndBaristol = Timers:CreateTimer(120, function() -- Teleport back to the spawn
		for _,v in pairs(teleporters) do
			v:Enable()
		end
		SPECIAL_EVENT = 0
		UTIL_Remove(Ramero)
		UTIL_Remove(Baristol)
		RestartCreeps()
	end)

	Timers:CreateTimer(126, function() -- 14:05 Min: MURADIN BRONZEBEARD EVENT 1, END
--		Notifications:TopToAll({text = "Ramero and Baristol won the duel!", duration = 6.0})
		for _,v in pairs(teleporters) do
			v:Disable()
		end
	end)

	UTIL_Remove(RAMERO_DUMMY)
	UTIL_Remove(BARISTOL_DUMMY)
end

function EndRameroEvent(keys)
local activator = keys.activator
local point = Entities:FindByName(nil, "base_spawn"):GetAbsOrigin()

	if activator:GetTeam() == DOTA_TEAM_GOODGUYS then
	FindClearSpaceForUnit(activator, point, true)
	PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(), activator)
	Timers:CreateTimer(0.1, function()
		PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(), nil)
	end)
	activator:Stop()
	end
end

dire_hero_list = {}
radiant_hero_list = {}

function DuelEvent()
local heroes = HeroList:GetAllHeroes()
local duel = 1
PlayerNumberRadiant = 0
PlayerNumberDire = 0
PauseCreeps()
SpawnRunes()
CustomGameEventManager:Send_ServerToAllClients("show_duel", {})

	Notifications:TopToAll({text="Fight your team mates until 1 team survives!", duration=10.0, style={color="white"}})

	-- Initialize duel
	for _, hero in pairs(heroes) do
		local ID = hero:GetPlayerID()
		local Gold = hero:GetGold()
		hero:SetRespawnsDisabled(true)
		if not hero:HasOwnerAbandoned() then
--		if PlayerResource:GetConnectionState(ID) == 3 then -- Connected
			if PlayerResource:IsValidPlayerID(hero:GetPlayerOwnerID()) and hero:IsRealHero() then
				if ID == 0 or ID == 2 or ID == 4 or ID == 6 then
					hero:SetTeam(DOTA_TEAM_CUSTOM_3)
					if hero:GetPlayerOwner() then
						hero:GetPlayerOwner():SetTeam(DOTA_TEAM_CUSTOM_3)
					end
					table.insert(dire_hero_list, hero)
					PlayerNumberDire = PlayerNumberDire + 1
				elseif ID == 1 or ID == 3 or ID == 5 or ID == 7 then
					hero:SetTeam(DOTA_TEAM_CUSTOM_4)
					if hero:GetPlayerOwner() then
						hero:GetPlayerOwner():SetTeam(DOTA_TEAM_CUSTOM_4)
					end
					table.insert(radiant_hero_list, hero)
					PlayerNumberRadiant = PlayerNumberRadiant + 1
				end
				hero:SetGold(Gold, false)

				local point = Entities:FindByName(nil, "duel_event_"..ID)
				FindClearSpaceForUnit(hero, point:GetAbsOrigin(), true)

				-- Duel Settings
				hero:SetPhysicalArmorBaseValue(0 - hero:GetPhysicalArmorValue()*0.80) -- Remove 80% of the heroes armor
			end
		else
		--		elseif PlayerResource:GetConnectionState(ID) == 4 then -- Disconnected
			FindClearSpaceForUnit(hero, Entities:FindByName(nil, "choose_vip_point"):GetAbsOrigin(), true)
			Notifications:TopToAll({text="Disconnected hero detected, teleporting them out of arena!", duration=5.0, style={color="white"}})
		end
	end

	-- WIN Conditions
	timers.Duel = Timers:CreateTimer(1.0, function()
		print("Check Death")
		if duel == 1 then
			if PlayerNumberRadiant <= 0 then
				GameRules:SetGameWinner(DOTA_TEAM_CUSTOM_3)
			end
			if PlayerNumberDire <= 0 then
				print("Radiant Win!")
			end
		else
			return nil
		end
		return 1.0
	end)
end

--	function DuelEnd(winner)
--		local point = Entities:FindByName(nil, "base_spawn"):GetAbsOrigin()
--		print(winner.." has won!")
--		for _, hero in pairs(radiant_hero_list) do
--			if PlayerResource:IsValidPlayerID(hero:GetPlayerOwnerID()) then
--				if winner == RADIANT then
--					hero:AddItemByName("item_orb_of_frost")
--				end
--				FindClearSpaceForUnit(hero, point, true)
--			end
--		end
--		for _, hero in pairs(dire_hero_list) do
--			if PlayerResource:IsValidPlayerID(hero:GetPlayerOwnerID()) then
--				if winner == DIRE then
--					hero:AddItemByName("item_orb_of_frost")
--				end
--				hero:SetTeam(DOTA_TEAM_GOODGUYS)
--				if hero:GetPlayerOwner() then
--					hero:GetPlayerOwner():SetTeam(DOTA_TEAM_GOODGUYS)
--				end
--				FindClearSpaceForUnit(hero, point, true)
--			end
--		end
--		radiant_hero_list = {}
--		dire_hero_list = {}
--		Timers:RemoveTimer(timers.Duel)
--		duel = 0
--		SPECIAL_EVENT = 0
--		ANKHS = 1
--	end
