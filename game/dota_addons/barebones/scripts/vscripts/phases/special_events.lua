require('libraries/timers')

function MuradinEvent() -- 12 Min, lasts 2 Min.
local teleporters = Entities:FindAllByName("trigger_teleport_muradin_end")
nTimer_SpecialEvent = 120
BT_ENABLED = 0

mode = GameRules:GetGameModeEntity()
mode:SetFixedRespawnTime(1)

	local Muradin = CreateUnitByName("npc_dota_creature_muradin_bronzebeard", Entities:FindByName(nil, "npc_dota_muradin_boss"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
	Muradin:AddNewModifier( nil, nil, "modifier_boss_stun", {duration = 5})
	Muradin:AddNewModifier( nil, nil, "modifier_invulnerable", {duration = 5})
	Muradin:SetAngles(0, 270, 0)
	Muradin:EmitSound("Muradin.StormEarthFire")
--	Muradin:EmitSound("SantaClaus.StartArena")
	Notifications:TopToAll({hero="npc_dota_hero_zuus", duration=5.0})
	Notifications:TopToAll({text=" You can't kill him! Just survive the Countdown. ", continue=true})
	Notifications:TopToAll({text="Reward: 15 000 Gold.", continue=true})
	for _, hero in pairs(HeroList:GetAllHeroes()) do
		hero.old_pos = hero:GetAbsOrigin()
		local id = hero:GetPlayerID()
		if PlayerResource:IsValidPlayerID(id) then
			local point = Entities:FindByName(nil,"npc_dota_muradin_player_"..id)
			DisableItems(hero, 120)
			if point then
				FindClearSpaceForUnit(hero, point:GetAbsOrigin(), true)
			else
				print("Wrong point?")
			end
			PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), hero)
			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), nil)
			end)
		else
			print("Wrong Player?")
--			Notifications:TopToAll({text="Invalid Steam ID detected!! #ERROR 002 ", duration = 10.0})
--			Notifications:TopToAll({text="Please report this bug on Discord Chat!! #ERROR 002 ", continue = true})
		end
	end

	Timers:CreateTimer(90, function()
		Notifications:TopToAll({text="WARNING: Incoming Wave of Darkness from the East!", duration=25.0, style={color="red"}})
		SpawnRunes()
	end)

	Timers:CreateTimer(120, function() -- 14:00 Min, teleport back to the spawn
		SpecialWave()
		UTIL_Remove(Muradin)
		mode:SetFixedRespawnTime(40)
		nTimer_SpecialEvent = 720
		BT_ENABLED = 1
		SPECIAL_EVENT = 0
		RestartCreeps()
	end)

	Timers:CreateTimer(126, function() -- 14:05 Min: MURADIN BRONZEBEARD EVENT 1, END
		Notifications:TopToAll({text="All heroes who survived Muradin received 15 000 Gold!", duration=6.0})
		Notifications:TopToAll({ability="alchemist_goblins_greed", continue = true})
		RestartCreeps()
	end)
end

function EndMuradinEvent()
local Check = 0
local MuradinCheck = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, Entities:FindByName(nil, "npc_dota_muradin_boss"):GetAbsOrigin(), nil, 2000, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE , FIND_ANY_ORDER, false)

	Notifications:TopToAll({text="Special Events are unlocked!", style={color="DodgerBlue"}, duration=5.0})
	Entities:FindByName(nil, "trigger_special_event_tp_off"):Disable()
	Entities:FindByName(nil, "trigger_special_event"):Enable()

	for _, hero in pairs(MuradinCheck) do
		Timers:CreateTimer(0.0, function()
			if Check < 5 then
				if hero:IsIllusion() then
					print("Illusion found, ignoring it")
				elseif hero:IsRealHero() and not hero.paid then
					hero.paid = true
					if hero.old_pos then
						TeleportHero(hero, 0.0, hero.old_pos)
					else
						if hero:GetTeamNumber() == 2 then
							TeleportHero(hero, 0.0, base_good:GetAbsOrigin())
						elseif hero:GetTeamNumber() == 3 then
							TeleportHero(hero, 0.0, base_bad:GetAbsOrigin())
						end
					end
					PlayerResource:ModifyGold(hero:GetPlayerOwnerID(), 15000, false,  DOTA_ModifyGold_Unspecified)
				end
				Check = Check +1
				return 1
			end
		end)
	end
end

function FarmEvent() -- 24 Min, lasts 3 Min.
nTimer_SpecialEvent = 180
BT_ENABLED = 0
GameMode.hero_farm_event = {}
local hero_count = 0

	Notifications:TopToAll({hero="npc_dota_hero_alchemist", duration=5.0})
	Notifications:TopToAll({text=" It's farming time! Kill as much creeps as you can!", continue = true})

	for _, hero in pairs(HeroList:GetAllHeroes()) do
		hero.old_pos = hero:GetAbsOrigin()
		if hero:IsIllusion() then
		elseif hero:IsRealHero() then
			local id = hero:GetPlayerID()
			local point = Entities:FindByName(nil, "farm_event_player_"..id)

			if point then
				FindClearSpaceForUnit(hero, point:GetAbsOrigin(), true)
				PlayerResource:SetCameraTarget(hero:GetPlayerID(), hero)
			else
				NotificationsTopToAll({text="Invalid Steam ID detected!! #ERROR 003 ", duration = 10.0})
				Notifications:TopToAll({text="Please report this bug on Discord Chat!! #ERROR 003 ", continue = true})
			end

			for j = 1, 10 do
				local unit = CreateUnitByName(FarmEvent_Creeps[1], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
			end

			hero_count = hero_count +1
			print("Hero Count:", hero_count)
			for PlayerID = 0, hero_count -1 do
				GameMode.hero_farm_event[PlayerID] = {}
				GameMode.hero_farm_event[PlayerID]["round"] = 1
	--			Farm0 = Timers:CreateTimer(0.1, FarmEventCreeps(id))
			end

			if hero_count == 1 then
				Timers:CreateTimer(0.1, FarmEventCreeps0)
			elseif hero_count == 2 then
				Timers:CreateTimer(0.1, FarmEventCreeps1)
			elseif hero_count == 3 then
				Timers:CreateTimer(0.1, FarmEventCreeps2)
			elseif hero_count == 4 then
				Timers:CreateTimer(0.1, FarmEventCreeps3)
			elseif hero_count == 5 then
				Timers:CreateTimer(0.1, FarmEventCreeps4)
			elseif hero_count == 6 then
				Timers:CreateTimer(0.1, FarmEventCreeps5)
			elseif hero_count == 7 then
				Timers:CreateTimer(0.1, FarmEventCreeps6)
			elseif hero_count == 8 then
				Timers:CreateTimer(0.1, FarmEventCreeps7)
			end

			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(hero:GetPlayerID(), nil)
			end)

			DisableItems(hero, 120)
		else
			Notifications:TopToAll({text="Invalid Steam ID detected!! #ERROR 001 ", duration = 10.0})
			Notifications:TopToAll({text="Please report this bug on Discord Chat!! #ERROR 001 ", continue = true})
		end
	end

	Timers:CreateTimer(160, function() -- 150
		Notifications:TopToAll({text="WARNING: Incoming Wave of Darkness from the North!", duration=25.0, style={color="red"}})
		SpawnRunes()
	end)

	Timers:CreateTimer(175, function()
		EndFarmEvent()
	end)

	Timers:CreateTimer(180, function() -- 27:00 Min, teleport back to the spawn
		BT_ENABLED = 1
		SPECIAL_EVENT = 0
		RestartCreeps()

		Timers:CreateTimer(0.1, function()
			local units = FindUnitsInRadius(DOTA_TEAM_CUSTOM_2, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE , FIND_ANY_ORDER, false)
			for _,v in pairs(units) do
				UTIL_Remove(v)
			end
		end)

		Timers:CreateTimer(10.0, function()
			RestartCreeps()
			SpecialWave()
		end)
	end)
end

--	function FarmEventCreeps(id)
--		local point = Entities:FindByName(nil, "farm_event_player_"..id)
--		local units = FindUnitsInRadius(DOTA_TEAM_CUSTOM_2, point:GetAbsOrigin(), nil, 1200, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
--		local number = 0
--		for _,v in pairs(units) do
--			number = number +1
--		end
--	
--		if number <= 1 and SPECIAL_EVENT == 1 then
--			GameMode.hero_farm_event[id]["round"] = (GameMode.hero_farm_event[id]["round"] + 1) % 9
--			for j = 1, 10 do
--				local unit = CreateUnitByName(FarmEvent_Creeps[GameMode.hero_farm_event[id]["round"] + 1], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
--			end
--		end
--		return 1
--	end

function FarmEventCreeps0()
	local point = Entities:FindByName(nil, "farm_event_player_0")
	local units = FindUnitsInRadius(DOTA_TEAM_CUSTOM_2, point:GetAbsOrigin(), nil, 1200, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
	local number = 0
	for _,v in pairs(units) do
		number = number +1
	end

	if number <= 1 and SPECIAL_EVENT == 1 then
		GameMode.hero_farm_event[0]["round"] = (GameMode.hero_farm_event[0]["round"] + 1) % 9
		for j = 1, 10 do
			local unit = CreateUnitByName(FarmEvent_Creeps[GameMode.hero_farm_event[0]["round"] + 1], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
		end
	end
	return 1
end

function FarmEventCreeps1()
	local point = Entities:FindByName(nil, "farm_event_player_1")
	local units = FindUnitsInRadius(DOTA_TEAM_CUSTOM_2, point:GetAbsOrigin(), nil, 1200, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
	local number = 0
	for _,v in pairs(units) do
		number = number +1
	end

	if number <= 1 and SPECIAL_EVENT == 1 then
		GameMode.hero_farm_event[1]["round"] = (GameMode.hero_farm_event[1]["round"] + 1) % 9
		for j = 1, 10 do
			local unit = CreateUnitByName(FarmEvent_Creeps[GameMode.hero_farm_event[1]["round"] + 1], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
		end
	end
	return 1
end

function FarmEventCreeps2()
	local point = Entities:FindByName(nil, "farm_event_player_2")
	local units = FindUnitsInRadius(DOTA_TEAM_CUSTOM_2, point:GetAbsOrigin(), nil, 1200, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
	local number = 0
	for _,v in pairs(units) do
		number = number +1
	end

	if number <= 1 and SPECIAL_EVENT == 1 then
		GameMode.hero_farm_event[2]["round"] = (GameMode.hero_farm_event[2]["round"] + 1) % 9
		for j = 1, 10 do
			local unit = CreateUnitByName(FarmEvent_Creeps[GameMode.hero_farm_event[2]["round"] + 1], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
		end
	end
	return 1
end

function FarmEventCreeps3()
	local point = Entities:FindByName(nil, "farm_event_player_3")
	local units = FindUnitsInRadius(DOTA_TEAM_CUSTOM_2, point:GetAbsOrigin(), nil, 1200, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
	local number = 0
	for _,v in pairs(units) do
		number = number +1
	end

	if number <= 1 and SPECIAL_EVENT == 1 then
		GameMode.hero_farm_event[3]["round"] = (GameMode.hero_farm_event[3]["round"] + 1) % 9
		for j = 1, 10 do
			local unit = CreateUnitByName(FarmEvent_Creeps[GameMode.hero_farm_event[3]["round"] + 1], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
		end
	end
	return 1
end

function FarmEventCreeps4()
	local point = Entities:FindByName(nil, "farm_event_player_4")
	local units = FindUnitsInRadius(DOTA_TEAM_CUSTOM_2, point:GetAbsOrigin(), nil, 1200, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
	local number = 0
	for _,v in pairs(units) do
		number = number +1
	end

	if number <= 1 and SPECIAL_EVENT == 1 then
		GameMode.hero_farm_event[4]["round"] = (GameMode.hero_farm_event[4]["round"] + 1) % 9
		for j = 1, 10 do
			local unit = CreateUnitByName(FarmEvent_Creeps[GameMode.hero_farm_event[4]["round"] + 1], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
		end
	end
	return 1
end

function FarmEventCreeps5()
	local point = Entities:FindByName(nil, "farm_event_player_5")
	local units = FindUnitsInRadius(DOTA_TEAM_CUSTOM_2, point:GetAbsOrigin(), nil, 1200, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
	local number = 0
	for _,v in pairs(units) do
		number = number +1
	end

	if number <= 1 and SPECIAL_EVENT == 1 then
		GameMode.hero_farm_event[5]["round"] = (GameMode.hero_farm_event[5]["round"] + 1) % 9
		for j = 1, 10 do
			local unit = CreateUnitByName(FarmEvent_Creeps[GameMode.hero_farm_event[5]["round"] + 1], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
		end
	end
	return 1
end

function FarmEventCreeps6()
	local point = Entities:FindByName(nil, "farm_event_player_6")
	local units = FindUnitsInRadius(DOTA_TEAM_CUSTOM_2, point:GetAbsOrigin(), nil, 1200, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
	local number = 0
	for _,v in pairs(units) do
		number = number +1
	end

	if number <= 1 and SPECIAL_EVENT == 1 then
		GameMode.hero_farm_event[6]["round"] = (GameMode.hero_farm_event[6]["round"] + 1) % 9
		for j = 1, 10 do
			local unit = CreateUnitByName(FarmEvent_Creeps[GameMode.hero_farm_event[6]["round"] + 1], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
		end
	end
	return 1
end

function FarmEventCreeps7()
	local point = Entities:FindByName(nil, "farm_event_player_7")
	local units = FindUnitsInRadius(DOTA_TEAM_CUSTOM_2, point:GetAbsOrigin(), nil, 1200, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
	local number = 0
	for _,v in pairs(units) do
		number = number +1
	end

	if number <= 1 and SPECIAL_EVENT == 1 then
		GameMode.hero_farm_event[7]["round"] = (GameMode.hero_farm_event[7]["round"] + 1) % 9
		for j = 1, 10 do
			local unit = CreateUnitByName(FarmEvent_Creeps[GameMode.hero_farm_event[7]["round"] + 1], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
		end
	end
	return 1
end

function EndFarmEvent()
	for _, hero in pairs(HeroList:GetAllHeroes()) do
		RefreshPlayers()
		local id = hero:GetPlayerID()
		local FarmCheck = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, Entities:FindByName(nil, "farm_event_player_"..id):GetAbsOrigin(), nil, 2000, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE , FIND_ANY_ORDER, false)

		if hero:IsRealHero() then
			if hero.old_pos then
				TeleportHero(hero, 0.0, hero.old_pos)
			else
				if hero:GetTeamNumber() == 2 then
					TeleportHero(hero, 5.0, base_good:GetAbsOrigin())
				elseif hero:GetTeamNumber() == 3 then
					TeleportHero(hero, 5.0, base_bad:GetAbsOrigin())
				end
			end

			PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), hero)
			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), nil)
			end)
			hero:Stop()
		else
			Notifications:TopToAll({hero="npc_dota_hero_techies", duration = 5.0})
			Notifications:TopToAll({text="Oops! a bug occured, please report it on Discord! ERROR CODE: #003", continue = true})
			EndFarmEvent()
		end
	end

	local units = FindUnitsInRadius(DOTA_TEAM_CUSTOM_2, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE , FIND_ANY_ORDER, false)
	for _,v in pairs(units) do
		if v:IsCreature() and v:HasMovementCapability() then
			UTIL_Remove(v)
		end
	end
end

function RameroAndBaristolEvent() -- 500 kills
local teleporters = Entities:FindAllByName("trigger_teleport_ramero_end")
nTimer_SpecialEvent = 120
SPECIAL_EVENT = 1

	local Ramero = CreateUnitByName("npc_ramero", Entities:FindByName(nil, "roshan_wp_4"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
	Ramero:AddNewModifier( nil, nil, "modifier_boss_stun", {duration = 5})
	Ramero:AddNewModifier( nil, nil, "modifier_invulnerable", {duration = 5})
	Ramero:SetAngles(0, 45, 0)
	local Baristol = CreateUnitByName("npc_baristol", Entities:FindByName(nil, "roshan_wp_2"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
	Baristol:AddNewModifier( nil, nil, "modifier_boss_stun", {duration = 5})
	Baristol:AddNewModifier( nil, nil, "modifier_invulnerable", {duration = 5})
	Baristol:SetAngles(0, 325, 0)
--	Ramero:EmitSound("Muradin.StormEarthFire")
	Notifications:TopToAll({hero="npc_dota_hero_sven", duration=5.0})
	Notifications:TopToAll({text="Kill Ramero and Baristol to get special items! ", continue=true})
	Notifications:TopToAll({text="Reward: Lightning Sword and Tome of Stats +250.", continue=true})

	timers.RameroAndBaristol = Timers:CreateTimer(120, function() -- Teleport back to the spawn
		SPECIAL_EVENT = 0
		RestartCreeps()
		UTIL_Remove(RAMERO_DUMMY)
		UTIL_Remove(BARISTOL_DUMMY)

		if Ramero:IsNull() and Baristol:IsNull() then
			return
		else
			UTIL_Remove(Ramero)
			UTIL_Remove(Baristol)

			local Check = 0
			Notifications:TopToAll({text="Ramero and Baristol arena has been loss!", duration=5.0})
			Timers:CreateTimer(0.0, function()
				if Check < 5 then
					local RameroAndBaristolCheck = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, Entities:FindByName(nil, "npc_dota_muradin_boss"):GetAbsOrigin(), nil, 2000, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE , FIND_ANY_ORDER, false)
					for _, hero in pairs(RameroAndBaristolCheck) do
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

function RameroEvent() -- 750 kills
SPECIAL_EVENT = 1
local teleporters = Entities:FindAllByName("trigger_teleport_ramero_end")
nTimer_SpecialEvent = 120
PauseCreeps()

	local Ramero = CreateUnitByName("npc_ramero_2", Entities:FindByName(nil, "roshan_wp_4"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
	Ramero:AddNewModifier( nil, nil, "modifier_boss_stun", {duration = 5})
	Ramero:AddNewModifier( nil, nil, "modifier_invulnerable", {duration = 5})
	Ramero:SetAngles(0, 45, 0)
--	Ramero:EmitSound("Muradin.StormEarthFire")
	Notifications:TopToAll({hero="npc_dota_hero_sven", duration = 5.0})
	Notifications:TopToAll({text="Kill Ramero to get special items! ", continue = true})
	Notifications:TopToAll({text="Reward: Ring of Superiority.", continue = true})

	timers.Ramero = Timers:CreateTimer(120, function() -- Teleport back to the spawn
		SPECIAL_EVENT = 0
		RestartCreeps()
		UTIL_Remove(RAMERO_BIS_DUMMY)

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

dire_hero_list = {}
radiant_hero_list = {}

function DuelEvent()
local duel = 1
PlayerNumberRadiant = 0
PlayerNumberDire = 0
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
					table.insert(dire_hero_list, hero)
					PlayerNumberDire = PlayerNumberDire + 1
				elseif ID == 1 or ID == 3 or ID == 5 or ID == 7 then
					hero:SetTeam(DOTA_TEAM_BADGUYS)
					if hero:GetPlayerOwner() then
						hero:GetPlayerOwner():SetTeam(DOTA_TEAM_BADGUYS)
					end
					table.insert(radiant_hero_list, hero)
					PlayerNumberRadiant = PlayerNumberRadiant + 1
				end
				hero:SetGold(Gold, false)

				local point = Entities:FindByName(nil, "duel_event_"..ID)
				TeleportHero(hero, 0.0, point:GetAbsOrigin())

				-- Duel Settings
				hero:SetPhysicalArmorBaseValue(0 - hero:GetPhysicalArmorValue()*0.80) -- Remove 80% of the heroes armor

				for itemSlot = 0, 14 do
					local item = hero:GetItemInSlot(itemSlot)
					if item then
						if item:GetName() == "item_healing_potion" or item:GetName() == "item_mana_potion" or item:GetName() == "item_ankh_of_reincarnation" then
							hero:RemoveItem(item)
						end
					end
				end
			end
		else
			if hero:GetTeamNumber() == 2 then
				TeleportHero(hero, 0.0, base_good:GetAbsOrigin())
			elseif hero:GetTeamNumber() == 3 then
				TeleportHero(hero, 0.0, base_bad:GetAbsOrigin())
			end
			Notifications:TopToAll({text="Disconnected hero detected, teleporting out of arena!", duration=5.0, style={color="white"}})
		end
	end

	-- WIN Conditions
	local RadiantCheck = 0
	local DireCheck = 0
	timers.Duel = Timers:CreateTimer(1.0, function()
		local RadiantPlayers = FindUnitsInRadius( DOTA_TEAM_GOODGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE , FIND_ANY_ORDER, false )
		local DirePlayers = FindUnitsInRadius( DOTA_TEAM_BADGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE , FIND_ANY_ORDER, false )
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
