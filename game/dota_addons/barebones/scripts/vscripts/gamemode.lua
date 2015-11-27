BAREBONES_DEBUG_SPEW = false 

if GameMode == nil then
	DebugPrint( '[BAREBONES] creating barebones game mode' )
	_G.GameMode = class({})
end

require('libraries/timers')
require('libraries/physics')
require('libraries/projectiles')
require('libraries/notifications')
require('libraries/animations')
require('libraries/attachments')

require('internal/gamemode')
require('internal/events')

require('settings')
require('events')

function GameMode:OnFirstPlayerLoaded()
DebugPrint("[BAREBONES] First Player has loaded")
end

function GameMode:OnAllPlayersLoaded()
DebugPrint("[BAREBONES] All Players have loaded into the game")
GameMode.FrostTowers_killed = 0
GameMode.Magtheridon_killed = 0
GameMode.BossesTop_killed = 0
GameMode.Arthas_killed = 0
end

function GameMode:OnHeroInGame(hero)
DebugPrint("[BAREBONES] Hero spawned in game for first time -- " .. hero:GetUnitName())

local item = CreateItem("item_tpscroll_new", hero, hero)
hero:AddItem(item)

local item2 = CreateItem("item_salve_1000", hero, hero)
hero:AddItem(item2)

local item3 = CreateItem("item_ankh_of_reincarnation", hero, hero)
hero:AddItem(item3)
end

function CheckWestBarracks1()
	EntBarrackWest1 = Entities:FindByName( nil, "dota_badguys_barracks_west_1" )
	if EntBarrackWest1:IsAlive() then
	print( "West Barracks 1 is Alive!" )
	return 30

	elseif not EntBarrackWest1:IsAlive() then
	print( "West Barracks 1 is Dead." )
	return nil
	end
end

function CheckWestBarracks2()
	EntBarrackWest2 = Entities:FindByName( nil, "dota_badguys_barracks_west_2" )
	if EntBarrackWest2:IsAlive() then
	print( "West Barracks 2 is Alive!" )
	return 30

	elseif not EntBarrackWest2:IsAlive() then
	print( "West Barracks 2 is Dead." )
	return nil
	end
end

function CheckNorthBarracks1()
	EntBarrackNorth1 = Entities:FindByName( nil, "dota_badguys_barracks_north_1" )
	if EntBarrackNorth1:IsAlive() then
	print( "North Barracks 1 is Alive!" )
	return 30

	elseif not EntBarrackNorth1:IsAlive() then
	print( "North Barracks 1 is Dead." )
	return nil
	end
end

function CheckNorthBarracks2()
	EntBarrackNorth2 = Entities:FindByName( nil, "dota_badguys_barracks_north_2" )
	if EntBarrackNorth2:IsAlive() then
	print( "North Barracks 2 is Alive!" )
	return 30

	elseif not EntBarrackNorth2:IsAlive() then
	print( "North Barracks 2 is Dead." )
	return nil
	end
end

function CheckEastBarracks1()
	EntBarrackEast1 = Entities:FindByName( nil, "dota_badguys_barracks_east_1" )
	if EntBarrackEast1:IsAlive() then
	print( "East Barracks 1 is Alive!" )
	return 30

	elseif not EntBarrackEast1:IsAlive() then
	print( "East Barracks 1 is Dead." )
	return nil
	end
end

function CheckEastBarracks2()
	EntBarrackEast2 = Entities:FindByName( nil, "dota_badguys_barracks_east_2" )
	if EntBarrackEast2:IsAlive() then
	print( "East Barracks 2 is Alive!" )
	return 30

	elseif not EntBarrackEast2:IsAlive() then
	print( "East Barracks 2 is Dead." )
	return nil
	end
end

function CheckSouthBarracks1()
	EntBarrackSouth1 = Entities:FindByName( nil, "dota_badguys_barracks_south_1" )
	if EntBarrackSouth1:IsAlive() then
	print( "South Barracks 1 is Alive!" )
	return 30

	elseif not EntBarrackSouth1:IsAlive() then
	print( "South Barracks 1 is Dead." )
	return nil
	end
end

function CheckSouthBarracks2()
	EntBarrackSouth2 = Entities:FindByName( nil, "dota_badguys_barracks_south_2" )
	if EntBarrackSouth2:IsAlive() then
	print( "South Barracks 2 is Alive!" )
	return 30

	elseif not EntBarrackSouth2:IsAlive() then
	print( "South Barracks 2 is Dead." )
	return nil
	end
end

function GameMode:OnGameInProgress()
DebugPrint("[BAREBONES] The game has officially begun")
local difficulty = GameRules:GetCustomGameDifficulty()

	--TEST COMMAND
--	Timers:CreateTimer(30, function() -- 30 Sec
--	local point = Entities:FindByName( nil, "npc_dota_spawner_west_event"):GetAbsOrigin()
--	local unit = CreateUnitByName("npc_dota_creature_abaddon", point, true, nil, nil, DOTA_TEAM_BADGUYS)
--	end)

	--//=================================================================================================================
	--// Timer: Creeps Levels 2, 3, 4, 5 Whispering
	--//=================================================================================================================
	Timers:CreateTimer(360, function() -- 6 Min
	Notifications:TopToAll({text="Creeps are now Level 2!", duration=6.0})
	end)
	Timers:CreateTimer(720, function() -- 12 Min
	Notifications:TopToAll({text="Creeps are now Level 3!", duration=6.0})
	end)
	Timers:CreateTimer(1080, function() -- 18 Min
	Notifications:TopToAll({text="Creeps are now Level 4!", duration=6.0})
	end)
	Timers:CreateTimer(1440, function() -- 24 Min
	Notifications:TopToAll({text="Creeps are now Level 5!", duration=6.0})
	end)

	--//=================================================================================================================
	--// Timer: West, North, East, South Event 1 Whispering
	--//=================================================================================================================
	Timers:CreateTimer(270, function() -- 4 Min 30 sec
	Notifications:TopToAll({text="Incoming wave of Darkness from the West! You have 30 seconds!", duration=29.0})
	end)
	Timers:CreateTimer(570, function() -- 9 Min 30 sec
	Notifications:TopToAll({text="Incoming wave of Darkness from the North! You have 30 seconds!", duration=29.0})
	end)
	Timers:CreateTimer(870, function() -- 14 Min 30 sec
	Notifications:TopToAll({text="Incoming wave of Darkness from the East! You have 30 seconds!", duration=29.0})
	end)
	Timers:CreateTimer(1170, function() -- 19 Min 30 sec
	Notifications:TopToAll({text="Incoming wave of Darkness from the South! You have 30 seconds!", duration=29.0})
	end)

	--//=================================================================================================================
	--// Timer: Creeps Level 1, 5 West 1
	--//=================================================================================================================
	local time_elapsed = 0
	Timers:CreateTimer(0, function()
	time_elapsed = time_elapsed + 30 -- with this system, the time_elapsed should be set to the Game Time + 30 sec, e.g: 5 Min = 300sec + 30 = 330
	print( time_elapsed )
		if GetMapName() == "x_hero_siege_8_players" and PlayerResource:GetPlayerCount() >= 1 and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_1"):GetAbsOrigin()
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return CheckWestBarracks1() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "x_hero_siege_8_players" and PlayerResource:GetPlayerCount() >= 1 and time_elapsed >= 390 and time_elapsed < 750 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_1"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return CheckWestBarracks1() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "x_hero_siege_8_players" and PlayerResource:GetPlayerCount() >= 1 and time_elapsed >= 750 and time_elapsed < 1110 then -- Level 3, higher or equal to 12 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_1"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_banes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckWestBarracks1() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "x_hero_siege_8_players" and PlayerResource:GetPlayerCount() >= 1 and time_elapsed >= 1110 and time_elapsed < 1470 then -- Level 4, higher or equal to 18 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_1"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_phoenixes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckWestBarracks1() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "x_hero_siege_8_players" and PlayerResource:GetPlayerCount() >= 1 and time_elapsed >= 1470 then -- Level 4, higher or equal to 18 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_1"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckWestBarracks1() -- Rerun this timer every 30 game-time seconds
		end
	end)

	--//=================================================================================================================
	--// Timer: Creeps Level 1, 4 West 2
	--//=================================================================================================================
	local time_elapsed = 0
	local TimerWest2 = Timers:CreateTimer(0, function()
		time_elapsed = time_elapsed + 30 -- with this system, the time_elapsed should be set to the Game Time + 30 sec, e.g: 5 Min = 300sec + 30 = 330
		if GetMapName() == "x_hero_siege_8_players" and PlayerResource:GetPlayerCount() >= 2 and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_2"):GetAbsOrigin()
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return CheckWestBarracks2() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "x_hero_siege_8_players" and PlayerResource:GetPlayerCount() >= 2 and time_elapsed >= 390 and time_elapsed < 750 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_2"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return CheckWestBarracks2() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "x_hero_siege_8_players" and PlayerResource:GetPlayerCount() >= 2 and time_elapsed >= 750 and time_elapsed < 1110 then -- Level 3, higher or equal to 12 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_2"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_banes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckWestBarracks2() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "x_hero_siege_8_players" and PlayerResource:GetPlayerCount() >= 2 and time_elapsed >= 1110 and time_elapsed < 1470 then -- Level 4, higher or equal to 18 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_2"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_phoenixes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckWestBarracks2() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "x_hero_siege_8_players" and PlayerResource:GetPlayerCount() >= 2 and time_elapsed >= 1470 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_2"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckWestBarracks2() -- Rerun this timer every 30 game-time seconds
		end
	end)

	--//=================================================================================================================
	--// Timer: Creeps Level 1, 4 North 1
	--//=================================================================================================================
	local time_elapsed = 0
	Timers:CreateTimer(0, function()
		time_elapsed = time_elapsed + 30 -- with this system, the time_elapsed should be set to the Game Time + 30 sec, e.g: 5 Min = 300sec + 30 = 330
		if GetMapName() == "x_hero_siege_8_players" and PlayerResource:GetPlayerCount() >= 3 and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_3"):GetAbsOrigin()
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return CheckNorthBarracks1() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "x_hero_siege_8_players" and PlayerResource:GetPlayerCount() >= 3 and time_elapsed >= 390 and time_elapsed < 750 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_3"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return CheckNorthBarracks1() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "x_hero_siege_8_players" and PlayerResource:GetPlayerCount() >= 3 and time_elapsed >= 750 and time_elapsed < 1110 then -- Level 3, higher or equal to 12 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_3"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_banes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckNorthBarracks1() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "x_hero_siege_8_players" and PlayerResource:GetPlayerCount() >= 3 and time_elapsed >= 1110 and time_elapsed < 1470 then -- Level 4, higher or equal to 18 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_3"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_phoenixes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckNorthBarracks1() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "x_hero_siege_8_players" and PlayerResource:GetPlayerCount() >= 3 and time_elapsed >= 1470 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_3"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckNorthBarracks1() -- Rerun this timer every 30 game-time seconds
		end
	end)

	--//=================================================================================================================
	--// Timer: Creeps Level 1, 4 North 2
	--//=================================================================================================================
	local time_elapsed = 0
	Timers:CreateTimer(0, function()
		time_elapsed = time_elapsed + 30 -- with this system, the time_elapsed should be set to the Game Time + 30 sec, e.g: 5 Min = 300sec + 30 = 330
		if GetMapName() == "x_hero_siege_8_players" and PlayerResource:GetPlayerCount() >= 4 and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_4"):GetAbsOrigin()
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return CheckNorthBarracks2() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "x_hero_siege_8_players" and PlayerResource:GetPlayerCount() >= 4 and time_elapsed >= 390 and time_elapsed < 750 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_4"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return CheckNorthBarracks2() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "x_hero_siege_8_players" and PlayerResource:GetPlayerCount() >= 4 and time_elapsed >= 750 and time_elapsed < 1110 then -- Level 3, higher or equal to 12 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_4"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_banes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckNorthBarracks2() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "x_hero_siege_8_players" and PlayerResource:GetPlayerCount() >= 4 and time_elapsed >= 1110 and time_elapsed < 1470 then -- Level 4, higher or equal to 18 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_4"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_phoenixes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckNorthBarracks2() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "x_hero_siege_8_players" and PlayerResource:GetPlayerCount() >= 4 and time_elapsed >= 1470 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_4"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckNorthBarracks2() -- Rerun this timer every 30 game-time seconds
		end
	end)

	--//=================================================================================================================
	--// Timer: Creeps Level 1, 4 East 1
	--//=================================================================================================================
	local time_elapsed = 0
	Timers:CreateTimer(0, function()
		time_elapsed = time_elapsed + 30 -- with this system, the time_elapsed should be set to the Game Time + 30 sec, e.g: 5 Min = 300sec + 30 = 330
		if GetMapName() == "x_hero_siege_8_players" and PlayerResource:GetPlayerCount() >= 5 and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_5"):GetAbsOrigin()
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return CheckEastBarracks1() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "x_hero_siege_8_players" and PlayerResource:GetPlayerCount() >= 5 and time_elapsed >= 390 and time_elapsed < 750 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_5"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return CheckEastBarracks1() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "x_hero_siege_8_players" and PlayerResource:GetPlayerCount() >= 5 and time_elapsed >= 750 and time_elapsed < 1110 then -- Level 3, higher or equal to 12 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_5"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_banes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckEastBarracks1() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "x_hero_siege_8_players" and PlayerResource:GetPlayerCount() >= 5 and time_elapsed >= 1110 and time_elapsed < 1470 then -- Level 4, higher or equal to 18 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_5"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_phoenixes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckEastBarracks1() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "x_hero_siege_8_players" and PlayerResource:GetPlayerCount() >= 5 and time_elapsed >= 1470 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_5"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckEastBarracks1() -- Rerun this timer every 30 game-time seconds
		end
	end)

	--//=================================================================================================================
	--// Timer: Creeps Level 1, 4 East 2
	--//=================================================================================================================
	local time_elapsed = 0
	Timers:CreateTimer(0, function()
		time_elapsed = time_elapsed + 30 -- with this system, the time_elapsed should be set to the Game Time + 30 sec, e.g: 5 Min = 300sec + 30 = 330
		if GetMapName() == "x_hero_siege_8_players" and PlayerResource:GetPlayerCount() >= 6 and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_6"):GetAbsOrigin()
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return CheckEastBarracks2() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "x_hero_siege_8_players" and PlayerResource:GetPlayerCount() >= 6 and time_elapsed >= 390 and time_elapsed < 750 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_6"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return CheckEastBarracks2() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "x_hero_siege_8_players" and PlayerResource:GetPlayerCount() >= 6 and time_elapsed >= 750 and time_elapsed < 1110 then -- Level 3, higher or equal to 12 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_6"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_banes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckEastBarracks2() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "x_hero_siege_8_players" and PlayerResource:GetPlayerCount() >= 6 and time_elapsed >= 1110 and time_elapsed < 1470 then -- Level 4, higher or equal to 18 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_6"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_phoenixes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckEastBarracks2() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "x_hero_siege_8_players" and PlayerResource:GetPlayerCount() >= 6 and time_elapsed >= 1470 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_6"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckEastBarracks2() -- Rerun this timer every 30 game-time seconds
		end
	end)

	--//=================================================================================================================
	--// Timer: Creeps Level 1, 4 South 1
	--//=================================================================================================================
	local time_elapsed = 0
	Timers:CreateTimer(0, function()
		time_elapsed = time_elapsed + 30 -- with this system, the time_elapsed should be set to the Game Time + 30 sec, e.g: 5 Min = 300sec + 30 = 330
		if GetMapName() == "x_hero_siege_8_players" and PlayerResource:GetPlayerCount() >= 7 and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_7"):GetAbsOrigin()
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return CheckSouthBarracks1() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "x_hero_siege_8_players" and PlayerResource:GetPlayerCount() >= 7 and time_elapsed >= 390 and time_elapsed < 750 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_7"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return CheckSouthBarracks1() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "x_hero_siege_8_players" and PlayerResource:GetPlayerCount() >= 7 and time_elapsed >= 750 and time_elapsed < 1110 then -- Level 3, higher or equal to 12 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_7"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_banes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckSouthBarracks1() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "x_hero_siege_8_players" and PlayerResource:GetPlayerCount() >= 7 and time_elapsed >= 1110 and time_elapsed < 1470 then -- Level 4, higher or equal to 18 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_7"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_phoenixes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckSouthBarracks1() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "x_hero_siege_8_players" and PlayerResource:GetPlayerCount() >= 7 and time_elapsed >= 1470 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_7"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckSouthBarracks1() -- Rerun this timer every 30 game-time seconds
		end
	end)

	--//=================================================================================================================
	--// Timer: Creeps Level 1, 4 South 2
	--//=================================================================================================================
	local time_elapsed = 0
	Timers:CreateTimer(0, function()
		time_elapsed = time_elapsed + 30 -- with this system, the time_elapsed should be set to the Game Time + 30 sec, e.g: 5 Min = 300sec + 30 = 330
		if GetMapName() == "x_hero_siege_8_players" and PlayerResource:GetPlayerCount() >= 8 and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_8"):GetAbsOrigin()
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return CheckSouthBarracks2() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "x_hero_siege_8_players" and PlayerResource:GetPlayerCount() >= 8 and time_elapsed >= 390 and time_elapsed < 750 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_8"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return CheckSouthBarracks2() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "x_hero_siege_8_players" and PlayerResource:GetPlayerCount() >= 8 and time_elapsed >= 750 and time_elapsed < 1110 then -- Level 3, higher or equal to 12 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_8"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_banes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckSouthBarracks2() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "x_hero_siege_8_players" and PlayerResource:GetPlayerCount() >= 8 and time_elapsed >= 1110 and time_elapsed < 1470 then -- Level 4, higher or equal to 18 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_8"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_phoenixes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckSouthBarracks2() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "x_hero_siege_8_players" and PlayerResource:GetPlayerCount() >= 8 and time_elapsed >= 1470 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_8"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckSouthBarracks2() -- Rerun this timer every 30 game-time seconds
		end
	end)

	--//=================================================================================================================
	--// HARD MODE
	--//=================================================================================================================
	--//=================================================================================================================
	--// Timer: Creeps Level 1, 5 West 1
	--//=================================================================================================================
	local time_elapsed = 0
	Timers:CreateTimer(0, function()
	time_elapsed = time_elapsed + 30 -- with this system, the time_elapsed should be set to the Game Time + 30 sec, e.g: 5 Min = 300sec + 30 = 330
	print( time_elapsed )
		if GetMapName() == "xherosiege_hardmode" and PlayerResource:GetPlayerCount() >= 1 and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_1"):GetAbsOrigin()
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return CheckWestBarracks1() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "xherosiege_hardmode" and PlayerResource:GetPlayerCount() >= 1 and time_elapsed >= 390 and time_elapsed < 750 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_1"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return CheckWestBarracks1() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "xherosiege_hardmode" and PlayerResource:GetPlayerCount() >= 1 and time_elapsed >= 750 and time_elapsed < 1110 then -- Level 3, higher or equal to 12 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_1"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_banes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckWestBarracks1() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "xherosiege_hardmode" and PlayerResource:GetPlayerCount() >= 1 and time_elapsed >= 1110 and time_elapsed < 1470 then -- Level 4, higher or equal to 18 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_1"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_phoenixes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckWestBarracks1() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "xherosiege_hardmode" and PlayerResource:GetPlayerCount() >= 1 and time_elapsed >= 1470 then -- Level 4, higher or equal to 18 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_1"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckWestBarracks1() -- Rerun this timer every 30 game-time seconds
		end
	end)

	--//=================================================================================================================
	--// Timer: Creeps Level 1, 4 West 2
	--//=================================================================================================================
	local time_elapsed = 0
	local TimerWest2 = Timers:CreateTimer(0, function()
		time_elapsed = time_elapsed + 30 -- with this system, the time_elapsed should be set to the Game Time + 30 sec, e.g: 5 Min = 300sec + 30 = 330
		if GetMapName() == "xherosiege_hardmode" and PlayerResource:GetPlayerCount() >= 1 and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_2"):GetAbsOrigin()
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return CheckWestBarracks2() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "xherosiege_hardmode" and PlayerResource:GetPlayerCount() >= 1 and time_elapsed >= 390 and time_elapsed < 750 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_2"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return CheckWestBarracks2() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "xherosiege_hardmode" and PlayerResource:GetPlayerCount() >= 1 and time_elapsed >= 750 and time_elapsed < 1110 then -- Level 3, higher or equal to 12 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_2"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_banes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckWestBarracks2() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "xherosiege_hardmode" and PlayerResource:GetPlayerCount() >= 1 and time_elapsed >= 1110 and time_elapsed < 1470 then -- Level 4, higher or equal to 18 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_2"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_phoenixes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckWestBarracks2() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "xherosiege_hardmode" and PlayerResource:GetPlayerCount() >= 1 and time_elapsed >= 1470 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_2"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckWestBarracks2() -- Rerun this timer every 30 game-time seconds
		end
	end)

	--//=================================================================================================================
	--// Timer: Creeps Level 1, 4 North 1
	--//=================================================================================================================
	local time_elapsed = 0
	Timers:CreateTimer(0, function()
		time_elapsed = time_elapsed + 30 -- with this system, the time_elapsed should be set to the Game Time + 30 sec, e.g: 5 Min = 300sec + 30 = 330
		if GetMapName() == "xherosiege_hardmode" and PlayerResource:GetPlayerCount() >= 2 and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_3"):GetAbsOrigin()
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return CheckNorthBarracks1() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "xherosiege_hardmode" and PlayerResource:GetPlayerCount() >= 2 and time_elapsed >= 390 and time_elapsed < 750 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_3"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return CheckNorthBarracks1() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "xherosiege_hardmode" and PlayerResource:GetPlayerCount() >= 2 and time_elapsed >= 750 and time_elapsed < 1110 then -- Level 3, higher or equal to 12 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_3"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_banes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckNorthBarracks1() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "xherosiege_hardmode" and PlayerResource:GetPlayerCount() >= 2 and time_elapsed >= 1110 and time_elapsed < 1470 then -- Level 4, higher or equal to 18 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_3"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_phoenixes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckNorthBarracks1() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "xherosiege_hardmode" and PlayerResource:GetPlayerCount() >= 2 and time_elapsed >= 1470 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_3"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckNorthBarracks1() -- Rerun this timer every 30 game-time seconds
		end
	end)

	--//=================================================================================================================
	--// Timer: Creeps Level 1, 4 North 2
	--//=================================================================================================================
	local time_elapsed = 0
	Timers:CreateTimer(0, function()
		time_elapsed = time_elapsed + 30 -- with this system, the time_elapsed should be set to the Game Time + 30 sec, e.g: 5 Min = 300sec + 30 = 330
		if GetMapName() == "xherosiege_hardmode" and PlayerResource:GetPlayerCount() >= 2 and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_4"):GetAbsOrigin()
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return CheckNorthBarracks2() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "xherosiege_hardmode" and PlayerResource:GetPlayerCount() >= 2 and time_elapsed >= 390 and time_elapsed < 750 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_4"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return CheckNorthBarracks2() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "xherosiege_hardmode" and PlayerResource:GetPlayerCount() >= 2 and time_elapsed >= 750 and time_elapsed < 1110 then -- Level 3, higher or equal to 12 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_4"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_banes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckNorthBarracks2() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "xherosiege_hardmode" and PlayerResource:GetPlayerCount() >= 2 and time_elapsed >= 1110 and time_elapsed < 1470 then -- Level 4, higher or equal to 18 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_4"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_phoenixes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckNorthBarracks2() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "xherosiege_hardmode" and PlayerResource:GetPlayerCount() >= 2 and time_elapsed >= 1470 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_4"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckNorthBarracks2() -- Rerun this timer every 30 game-time seconds
		end
	end)

	--//=================================================================================================================
	--// Timer: Creeps Level 1, 4 East 1
	--//=================================================================================================================
	local time_elapsed = 0
	Timers:CreateTimer(0, function()
		time_elapsed = time_elapsed + 30 -- with this system, the time_elapsed should be set to the Game Time + 30 sec, e.g: 5 Min = 300sec + 30 = 330
		if GetMapName() == "xherosiege_hardmode" and PlayerResource:GetPlayerCount() >= 3 and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_5"):GetAbsOrigin()
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return CheckEastBarracks1() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "xherosiege_hardmode" and PlayerResource:GetPlayerCount() >= 3 and time_elapsed >= 390 and time_elapsed < 750 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_5"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return CheckEastBarracks1() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "xherosiege_hardmode" and PlayerResource:GetPlayerCount() >= 3 and time_elapsed >= 750 and time_elapsed < 1110 then -- Level 3, higher or equal to 12 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_5"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_banes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckEastBarracks1() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "xherosiege_hardmode" and PlayerResource:GetPlayerCount() >= 3 and time_elapsed >= 1110 and time_elapsed < 1470 then -- Level 4, higher or equal to 18 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_5"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_phoenixes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckEastBarracks1() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "xherosiege_hardmode" and PlayerResource:GetPlayerCount() >= 3 and time_elapsed >= 1470 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_5"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckEastBarracks1() -- Rerun this timer every 30 game-time seconds
		end
	end)

	--//=================================================================================================================
	--// Timer: Creeps Level 1, 4 East 2
	--//=================================================================================================================
	local time_elapsed = 0
	Timers:CreateTimer(0, function()
		time_elapsed = time_elapsed + 30 -- with this system, the time_elapsed should be set to the Game Time + 30 sec, e.g: 5 Min = 300sec + 30 = 330
		if GetMapName() == "xherosiege_hardmode" and PlayerResource:GetPlayerCount() >= 3 and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_6"):GetAbsOrigin()
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return CheckEastBarracks2() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "xherosiege_hardmode" and PlayerResource:GetPlayerCount() >= 3 and time_elapsed >= 390 and time_elapsed < 750 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_6"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return CheckEastBarracks2() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "xherosiege_hardmode" and PlayerResource:GetPlayerCount() >= 3 and time_elapsed >= 750 and time_elapsed < 1110 then -- Level 3, higher or equal to 12 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_6"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_banes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckEastBarracks2() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "xherosiege_hardmode" and PlayerResource:GetPlayerCount() >= 3 and time_elapsed >= 1110 and time_elapsed < 1470 then -- Level 4, higher or equal to 18 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_6"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_phoenixes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckEastBarracks2() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "xherosiege_hardmode" and PlayerResource:GetPlayerCount() >= 3 and time_elapsed >= 1470 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_6"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckEastBarracks2() -- Rerun this timer every 30 game-time seconds
		end
	end)

	--//=================================================================================================================
	--// Timer: Creeps Level 1, 4 South 1
	--//=================================================================================================================
	local time_elapsed = 0
	Timers:CreateTimer(0, function()
		time_elapsed = time_elapsed + 30 -- with this system, the time_elapsed should be set to the Game Time + 30 sec, e.g: 5 Min = 300sec + 30 = 330
		if GetMapName() == "xherosiege_hardmode" and PlayerResource:GetPlayerCount() >= 4 and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_7"):GetAbsOrigin()
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return CheckSouthBarracks1() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "xherosiege_hardmode" and PlayerResource:GetPlayerCount() >= 4 and time_elapsed >= 390 and time_elapsed < 750 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_7"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return CheckSouthBarracks1() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "xherosiege_hardmode" and PlayerResource:GetPlayerCount() >= 4 and time_elapsed >= 750 and time_elapsed < 1110 then -- Level 3, higher or equal to 12 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_7"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_banes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckSouthBarracks1() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "xherosiege_hardmode" and PlayerResource:GetPlayerCount() >= 4 and time_elapsed >= 1110 and time_elapsed < 1470 then -- Level 4, higher or equal to 18 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_7"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_phoenixes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckSouthBarracks1() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "xherosiege_hardmode" and PlayerResource:GetPlayerCount() >= 4 and time_elapsed >= 1470 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_7"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckSouthBarracks1() -- Rerun this timer every 30 game-time seconds
		end
	end)

	--//=================================================================================================================
	--// Timer: Creeps Level 1, 4 South 2
	--//=================================================================================================================
	local time_elapsed = 0
	Timers:CreateTimer(0, function()
		time_elapsed = time_elapsed + 30 -- with this system, the time_elapsed should be set to the Game Time + 30 sec, e.g: 5 Min = 300sec + 30 = 330
		if GetMapName() == "xherosiege_hardmode" and PlayerResource:GetPlayerCount() >= 4 and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_8"):GetAbsOrigin()
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return CheckSouthBarracks2() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "xherosiege_hardmode" and PlayerResource:GetPlayerCount() >= 4 and time_elapsed >= 390 and time_elapsed < 750 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_8"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return CheckSouthBarracks2() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "xherosiege_hardmode" and PlayerResource:GetPlayerCount() >= 4 and time_elapsed >= 750 and time_elapsed < 1110 then -- Level 3, higher or equal to 12 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_8"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_banes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckSouthBarracks2() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "xherosiege_hardmode" and PlayerResource:GetPlayerCount() >= 4 and time_elapsed >= 1110 and time_elapsed < 1470 then -- Level 4, higher or equal to 18 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_8"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_phoenixes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckSouthBarracks2() -- Rerun this timer every 30 game-time seconds

		elseif GetMapName() == "xherosiege_hardmode" and PlayerResource:GetPlayerCount() >= 4 and time_elapsed >= 1470 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_8"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return CheckSouthBarracks2() -- Rerun this timer every 30 game-time seconds
		end
	end)

	--//=================================================================================================================
	--// Timer: West Event 1 Spawn
	--//=================================================================================================================
	Timers:CreateTimer(300, function() -- 5 Min: DEATH PROPHET WEST EVENT 1
	local point = Entities:FindByName( nil, "npc_dota_spawner_west_event"):GetAbsOrigin()

	for j = 1, 8 do
		local unit = CreateUnitByName("npc_dota_creature_death_prophet_event_1", point, true, nil, nil, DOTA_TEAM_BADGUYS)
	end
	end)

	--//=================================================================================================================
	--// Timer: North Event 2 Spawn
	--//=================================================================================================================
	Timers:CreateTimer(600, function() -- 10 Min: NAGA SIREN NORTH EVENT 2
	local point = Entities:FindByName( nil, "npc_dota_spawner_north_event"):GetAbsOrigin()

	for j = 1, 8 do
		local unit = CreateUnitByName("npc_dota_creature_naga_siren_event_2", point, true, nil, nil, DOTA_TEAM_BADGUYS)
	end
	end)

	--//=================================================================================================================
	--// Timer: East Event 3 Spawn
	--//=================================================================================================================
	Timers:CreateTimer(900, function() -- 15 Min: VENGEFUL SPIRIT SOUTH EVENT 3
	local point = Entities:FindByName( nil, "npc_dota_spawner_east_event"):GetAbsOrigin()

	for j = 1, 8 do
		local unit = CreateUnitByName("npc_dota_creature_vengeful_spirit_event_3", point, true, nil, nil, DOTA_TEAM_BADGUYS)
	end
	end)

	--//=================================================================================================================
	--// Timer: South Event 4 Spawn
	--//=================================================================================================================
	Timers:CreateTimer(1200, function() -- 20 Min: ENIGMA SOUTH EVENT 4
	local point = Entities:FindByName( nil, "npc_dota_spawner_south_event"):GetAbsOrigin()

	for j = 1, 8 do
		local unit = CreateUnitByName("npc_dota_creature_enigma_event_4", point, true, nil, nil, DOTA_TEAM_BADGUYS)
	end
	end)
end

XP_PER_LEVEL_TABLE = {
	0,-- 1
	200,-- 2
	400,-- 3
	700,-- 4
	1100,-- 5
	1600,-- 6
	2200,-- 7
	2900,-- 8
	3700,-- 9
	4600,-- 10
	5600,-- 11
	6700,-- 12
	7900,-- 13
	9200,-- 14
	10600,-- 15
	12100,-- 16
	13700,-- 17
	15400,-- 18
	17200,-- 19
	19100,-- 20
	21100,-- 21
	23200,-- 22
	25400,-- 23
	27700,-- 24
	30100, -- 25
	32600, -- 26
	35200, -- 27
	37900, -- 28
	40700, -- 29
	43600, -- 30
	46600, -- 31
	49700, -- 32
	52900, -- 33
	56200, -- 34
	59600, -- 35
	63100, -- 36
	66700, -- 37
	70400, -- 38
	74200, -- 39
	78100, -- 40
	82100, -- 41
	86200, -- 42
	90400, -- 43
	94700, -- 44
	99100, -- 45
	103600, -- 46
	108200, -- 47
	112900, -- 48
	117700, -- 49
	122600 -- 50
}

function GameMode:InitGameMode()
	GameMode = self
	DebugPrint('[BAREBONES] Starting to load Barebones gamemode...')

	mode = GameRules:GetGameModeEntity()
	mode:SetCustomHeroMaxLevel( 50 )
	mode:SetCustomXPRequiredToReachNextLevel( XP_PER_LEVEL_TABLE )
	mode:SetUseCustomHeroLevels( true )

	GameMode:_InitGameMode()

	Convars:RegisterCommand( "command_example", Dynamic_Wrap(GameMode, 'ExampleConsoleCommand'), "A console command example", FCVAR_CHEAT )

	DebugPrint('[BAREBONES] Done loading Barebones gamemode!\n\n')
end

-- This is an example console command
function GameMode:ExampleConsoleCommand()
  print( '******* Example Console Command ***************' )
  local cmdPlayer = Convars:GetCommandClient()
  if cmdPlayer then
	local playerID = cmdPlayer:GetPlayerID()
	if playerID ~= nil and playerID ~= -1 then
	  -- Do something here for the player who called this command
	  PlayerResource:ReplaceHeroWith(playerID, "npc_dota_hero_viper", 1000, 1000)
	end
  end

  print( '*********************************************' )
end
