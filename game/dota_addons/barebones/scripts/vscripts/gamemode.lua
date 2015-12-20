BAREBONES_DEBUG_SPEW = false
_G.nCOUNTDOWNTIMER = 0


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
	GameMode.Muradin_Event = 0
end

function GameMode:OnHeroInGame(hero)
	DebugPrint("[BAREBONES] Hero spawned in game for first time -- " .. hero:GetUnitName())
end

function GameMode:OnGameInProgress()
	DebugPrint("[BAREBONES] The game has officially begun")

	--//=================================================================================================================
	--// Timer: Creeps Levels 2, 3, 4, 5 Whispering
	--//=================================================================================================================
	Timers:CreateTimer(360, function() -- 6 Min
	Notifications:TopToAll({hero="npc_dota_hero_undying", duration=6.0})
	Notifications:TopToAll({text="Creeps are now Level 2!", style={color="green"}, continue=true})
	end)
	Timers:CreateTimer(840, function() -- 12 Min + 2 Min with Muradin Event = 14 Min
	Notifications:TopToAll({hero="npc_dota_hero_nyx_assassin", duration=6.0})
	Notifications:TopToAll({text="Creeps are now Level 3!", style={color="green"}, continue=true})
	end)
	Timers:CreateTimer(1200, function() -- 18 Min + 2 Min with Muradin Event = 20 Min
	Notifications:TopToAll({hero="npc_dota_hero_doom", duration=6.0})
	Notifications:TopToAll({text="Creeps are now Level 4!", style={color="green"}, continue=true})
	end)
	Timers:CreateTimer(1560, function() -- 24 Min + 2 Min with Muradin Event = 26 Min
	Notifications:TopToAll({hero="npc_dota_hero_phantom_lancer", duration=6.0})
	Notifications:TopToAll({text="Creeps are now Level 5!", style={color="green"}, continue=true})
	end)
	--//=================================================================================================================
	--// Timer: West, North, East, South Event 1 Whispering
	--//=================================================================================================================
	Timers:CreateTimer(270, function() -- 4 Min 30 sec
	Notifications:TopToAll({text="Incoming wave of Darkness from the West! You have 30 seconds!", duration=29.0, color="red"})
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
	Timers:CreateTimer(660, function() -- 11 Min
	Notifications:TopToAll({text="Warning, Muradin Event in 1 Min! Creeps will stop spawning at 11:30.", style={color="red"}, duration=59.0})
	end)

	--//=================================================================================================================
	--// Timer: Creeps Level 1, 5 West 1
	--//=================================================================================================================
	if GetMapName() == "x_hero_siege_8_players" and GameMode.Muradin_Event == 0 then -- 8 Players Creep Lanes
	local time_elapsed = 0
	local EntBarrack = Entities:FindByName( nil, "dota_badguys_barracks_west_1" )
		Timers:CreateTimer(0, function()
		time_elapsed = time_elapsed + 30 -- with this system, the time_elapsed should be set to the Game Time + 30 sec, e.g: 5 Min = 300sec + 30 = 330
		print( time_elapsed )
--		Notifications:TopToAll({text="Creep Lane 1, West 1 spawning in Normal Mode", duration=6.0})
			if PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed < 390 then -- Level 1 lower than 6 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_1"):GetAbsOrigin()
				for j = 1, 3 do
				local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
				end
				local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			return 30 -- Rerun this timer every 30 game-time seconds

			elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 390 and time_elapsed < 750 then -- Level 2, higher or equal to 6 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_1"):GetAbsOrigin()
				for j = 1, 4 do
				local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
				end
				local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
				local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			return 30

			elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 750 and time_elapsed < 870 then -- Return 30 Muradin Event
			return 30

			elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 870 and time_elapsed < 1230 then -- Level 3, higher or equal to 12 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_1"):GetAbsOrigin()
				for j = 1, 5 do
				local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
				end
				for j = 1, 3 do
				local unit = CreateUnitByName("npc_dota_creature_mini_banes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
				end
			return 30

			elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 1230 and time_elapsed < 1590 then -- Level 4, higher or equal to 18 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_1"):GetAbsOrigin()
				for j = 1, 5 do
				local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
				end
				for j = 1, 3 do
				local unit = CreateUnitByName("npc_dota_creature_mini_phoenixes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
				end
			return 30

			elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 1590 then -- Level 4, higher or equal to 18 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_1"):GetAbsOrigin()
				for j = 1, 6 do
				local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
				end
				for j = 1, 4 do
				local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
				end
			return 30
			end
		end)

	--//=================================================================================================================
	--// Timer: Creeps Level 1, 4 West 2
	--//=================================================================================================================
	local time_elapsed = 0
	local EntBarrack = Entities:FindByName( nil, "dota_badguys_barracks_west_2" )
	local TimerWest2 = Timers:CreateTimer(0, function()
		time_elapsed = time_elapsed + 30 -- with this system, the time_elapsed should be set to the Game Time + 30 sec, e.g: 5 Min = 300sec + 30 = 330
		if PlayerResource:GetPlayerCount() >= 2 and EntBarrack:IsAlive() and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_2"):GetAbsOrigin()
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 2 and EntBarrack:IsAlive() and time_elapsed >= 390 and time_elapsed < 750 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_2"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 750 and time_elapsed < 870 then -- Return 30 Muradin Event
		return 30

		elseif PlayerResource:GetPlayerCount() >= 2 and EntBarrack:IsAlive() and time_elapsed >= 870 and time_elapsed < 1230 then -- Level 3, higher or equal to 12 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_2"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_banes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 2 and EntBarrack:IsAlive() and time_elapsed >= 1230 and time_elapsed < 1590 then -- Level 4, higher or equal to 18 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_2"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_phoenixes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 2 and EntBarrack:IsAlive() and time_elapsed >= 1590 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_2"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds
		end
	end)

	--//=================================================================================================================
	--// Timer: Creeps Level 1, 4 North 1
	--//=================================================================================================================
	local time_elapsed = 0
	local EntBarrack = Entities:FindByName( nil, "dota_badguys_barracks_north_1" )
	Timers:CreateTimer(0, function()
		time_elapsed = time_elapsed + 30 -- with this system, the time_elapsed should be set to the Game Time + 30 sec, e.g: 5 Min = 300sec + 30 = 330
		if PlayerResource:GetPlayerCount() >= 3 and EntBarrack:IsAlive() and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_3"):GetAbsOrigin()
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 3 and EntBarrack:IsAlive() and time_elapsed >= 390 and time_elapsed < 750 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_3"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 750 and time_elapsed < 870 then -- Return 30 Muradin Event
		return 30

		elseif PlayerResource:GetPlayerCount() >= 3 and EntBarrack:IsAlive() and time_elapsed >= 870 and time_elapsed < 1230 then -- Level 3, higher or equal to 12 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_3"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_banes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 3 and EntBarrack:IsAlive() and time_elapsed >= 1230 and time_elapsed < 1590 then -- Level 4, higher or equal to 18 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_3"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_phoenixes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 3 and EntBarrack:IsAlive() and time_elapsed >= 1590 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_3"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds
		end
	end)

	--//=================================================================================================================
	--// Timer: Creeps Level 1, 4 North 2
	--//=================================================================================================================
	local time_elapsed = 0
	local EntBarrack = Entities:FindByName( nil, "dota_badguys_barracks_north_2" )
	Timers:CreateTimer(0, function()
		time_elapsed = time_elapsed + 30 -- with this system, the time_elapsed should be set to the Game Time + 30 sec, e.g: 5 Min = 300sec + 30 = 330
		if PlayerResource:GetPlayerCount() >= 4 and EntBarrack:IsAlive() and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_4"):GetAbsOrigin()
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 4 and EntBarrack:IsAlive() and time_elapsed >= 390 and time_elapsed < 750 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_4"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 750 and time_elapsed < 870 then -- Return 30 Muradin Event
		return 30

		elseif PlayerResource:GetPlayerCount() >= 4 and EntBarrack:IsAlive() and time_elapsed >= 870 and time_elapsed < 1230 then -- Level 3, higher or equal to 12 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_4"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_banes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 4 and EntBarrack:IsAlive() and time_elapsed >= 1230 and time_elapsed < 1590 then -- Level 4, higher or equal to 18 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_4"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_phoenixes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 4 and EntBarrack:IsAlive() and time_elapsed >= 1590 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_4"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds
		end
	end)

	--//=================================================================================================================
	--// Timer: Creeps Level 1, 4 East 1
	--//=================================================================================================================
	local time_elapsed = 0
	local EntBarrack = Entities:FindByName( nil, "dota_badguys_barracks_east_2" )
	Timers:CreateTimer(0, function()
		time_elapsed = time_elapsed + 30 -- with this system, the time_elapsed should be set to the Game Time + 30 sec, e.g: 5 Min = 300sec + 30 = 330
		if PlayerResource:GetPlayerCount() >= 5 and EntBarrack:IsAlive() and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_5"):GetAbsOrigin()
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 5 and EntBarrack:IsAlive() and time_elapsed >= 390 and time_elapsed < 750 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_5"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 750 and time_elapsed < 870 then -- Return 30 Muradin Event
		return 30

		elseif PlayerResource:GetPlayerCount() >= 5 and EntBarrack:IsAlive() and time_elapsed >= 870 and time_elapsed < 1230 then -- Level 3, higher or equal to 12 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_5"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_banes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 5 and EntBarrack:IsAlive() and time_elapsed >= 1230 and time_elapsed < 1590 then -- Level 4, higher or equal to 18 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_5"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_phoenixes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 5 and EntBarrack:IsAlive() and time_elapsed >= 1590 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_5"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds
		end
	end)

	--//=================================================================================================================
	--// Timer: Creeps Level 1, 4 East 2
	--//=================================================================================================================
	local time_elapsed = 0
	local EntBarrack = Entities:FindByName( nil, "dota_badguys_barracks_east_1" )
	Timers:CreateTimer(0, function()
		time_elapsed = time_elapsed + 30 -- with this system, the time_elapsed should be set to the Game Time + 30 sec, e.g: 5 Min = 300sec + 30 = 330
		if PlayerResource:GetPlayerCount() >= 6 and EntBarrack:IsAlive() and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_6"):GetAbsOrigin()
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 6 and EntBarrack:IsAlive() and time_elapsed >= 390 and time_elapsed < 750 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_6"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 750 and time_elapsed < 870 then -- Return 30 Muradin Event
		return 30

		elseif PlayerResource:GetPlayerCount() >= 6 and EntBarrack:IsAlive() and time_elapsed >= 870 and time_elapsed < 1230 then -- Level 3, higher or equal to 12 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_6"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_banes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 6 and EntBarrack:IsAlive() and time_elapsed >= 1230 and time_elapsed < 1590 then -- Level 4, higher or equal to 18 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_6"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_phoenixes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 6 and EntBarrack:IsAlive() and time_elapsed >= 1590 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_6"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds
		end
	end)

	--//=================================================================================================================
	--// Timer: Creeps Level 1, 4 South 1
	--//=================================================================================================================
	local time_elapsed = 0
	local EntBarrack = Entities:FindByName( nil, "dota_badguys_barracks_south_1" )
	Timers:CreateTimer(0, function()
		time_elapsed = time_elapsed + 30 -- with this system, the time_elapsed should be set to the Game Time + 30 sec, e.g: 5 Min = 300sec + 30 = 330
		if PlayerResource:GetPlayerCount() >= 7 and EntBarrack:IsAlive() and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_7"):GetAbsOrigin()
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 7 and EntBarrack:IsAlive() and time_elapsed >= 390 and time_elapsed < 750 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_7"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 750 and time_elapsed < 870 then -- Return 30 Muradin Event
		return 30

		elseif PlayerResource:GetPlayerCount() >= 7 and EntBarrack:IsAlive() and time_elapsed >= 870 and time_elapsed < 1230 then -- Level 3, higher or equal to 12 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_7"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_banes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 7 and EntBarrack:IsAlive() and time_elapsed >= 1230 and time_elapsed < 1590 then -- Level 4, higher or equal to 18 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_7"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_phoenixes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 7 and EntBarrack:IsAlive() and time_elapsed >= 1590 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_7"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds
		end
	end)

	--//=================================================================================================================
	--// Timer: Creeps Level 1, 4 South 2
	--//=================================================================================================================
	local time_elapsed = 0
	local EntBarrack = Entities:FindByName( nil, "dota_badguys_barracks_south_2" )
	Timers:CreateTimer(0, function()
		time_elapsed = time_elapsed + 30 -- with this system, the time_elapsed should be set to the Game Time + 30 sec, e.g: 5 Min = 300sec + 30 = 330
		if PlayerResource:GetPlayerCount() >= 8 and EntBarrack:IsAlive() and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_8"):GetAbsOrigin()
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 8 and EntBarrack:IsAlive() and time_elapsed >= 390 and time_elapsed < 750 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_8"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 750 and time_elapsed < 870 then -- Return 30 Muradin Event
		return 30

		elseif PlayerResource:GetPlayerCount() >= 8 and EntBarrack:IsAlive() and time_elapsed >= 870 and time_elapsed < 1230 then -- Level 3, higher or equal to 12 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_8"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_banes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 8 and EntBarrack:IsAlive() and time_elapsed >= 1230 and time_elapsed < 1590 then -- Level 4, higher or equal to 18 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_8"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_phoenixes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 8 and EntBarrack:IsAlive() and time_elapsed >= 1590 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_8"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds
		end
	end)
	elseif GameMode.Muradin_Event == 1 then
		return 30 -- Return 30sec if Muradin Event is happening
	end -- end of if Map == Normal and not Event Muradin Running

	--//=================================================================================================================
	--// HARD MODE
	--//=================================================================================================================
	--//=================================================================================================================
	--// Timer: Creeps Level 1, 5 West 1
	--//=================================================================================================================
	if GetMapName() == "hardmode" and GameMode.Muradin_Event == 0 then -- 4 Players Creep Lanes, Hard Mode

	local time_elapsed = 0
	local EntBarrack = Entities:FindByName( nil, "dota_badguys_barracks_west_1" )
	Timers:CreateTimer(0, function()
	time_elapsed = time_elapsed + 30 -- with this system, the time_elapsed should be set to the Game Time + 30 sec, e.g: 5 Min = 300sec + 30 = 330
	print( time_elapsed )
--	Notifications:TopToAll({text="Creep Lane 1, West 1 spawning in Hard Mode", duration=6.0})
		if PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_1"):GetAbsOrigin()
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 390 and time_elapsed < 750 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_1"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 750 and time_elapsed < 870 then -- Return 30 Muradin Event
		return 30

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 870 and time_elapsed < 1230 then -- Level 3, higher or equal to 12 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_1"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_banes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 1230 and time_elapsed < 1590 then -- Level 4, higher or equal to 18 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_1"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_phoenixes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 1590 then -- Level 4, higher or equal to 18 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_1"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds
		end
	end)

	--//=================================================================================================================
	--// Timer: Creeps Level 1, 4 West 2
	--//=================================================================================================================
	local time_elapsed = 0
	local EntBarrack = Entities:FindByName( nil, "dota_badguys_barracks_west_2" )
	local TimerWest2 = Timers:CreateTimer(0, function()
		time_elapsed = time_elapsed + 30 -- with this system, the time_elapsed should be set to the Game Time + 30 sec, e.g: 5 Min = 300sec + 30 = 330
		if PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_2"):GetAbsOrigin()
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 390 and time_elapsed < 750 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_2"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 750 and time_elapsed < 870 then -- Return 30 Muradin Event
		return 30

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 870 and time_elapsed < 1230 then -- Level 3, higher or equal to 12 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_2"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_banes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 1230 and time_elapsed < 1590 then -- Level 4, higher or equal to 18 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_2"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_phoenixes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 1590 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_2"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds
		end
	end)

	--//=================================================================================================================
	--// Timer: Creeps Level 1, 4 North 1
	--//=================================================================================================================
	local time_elapsed = 0
	local EntBarrack = Entities:FindByName( nil, "dota_badguys_barracks_north_1" )
	Timers:CreateTimer(0, function()
		time_elapsed = time_elapsed + 30 -- with this system, the time_elapsed should be set to the Game Time + 30 sec, e.g: 5 Min = 300sec + 30 = 330
		if PlayerResource:GetPlayerCount() >= 2 and EntBarrack:IsAlive() and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_3"):GetAbsOrigin()
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 2 and EntBarrack:IsAlive() and time_elapsed >= 390 and time_elapsed < 750 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_3"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 750 and time_elapsed < 870 then -- Return 30 Muradin Event
		return 30

		elseif PlayerResource:GetPlayerCount() >= 2 and EntBarrack:IsAlive() and time_elapsed >= 870 and time_elapsed < 1230 then -- Level 3, higher or equal to 12 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_3"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_banes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 2 and EntBarrack:IsAlive() and time_elapsed >= 1230 and time_elapsed < 1590 then -- Level 4, higher or equal to 18 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_3"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_phoenixes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 2 and EntBarrack:IsAlive() and time_elapsed >= 1590 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_3"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds
		end
	end)

	--//=================================================================================================================
	--// Timer: Creeps Level 1, 4 North 2
	--//=================================================================================================================
	local time_elapsed = 0
	local EntBarrack = Entities:FindByName( nil, "dota_badguys_barracks_north_2" )
	Timers:CreateTimer(0, function()
		time_elapsed = time_elapsed + 30 -- with this system, the time_elapsed should be set to the Game Time + 30 sec, e.g: 5 Min = 300sec + 30 = 330
		if PlayerResource:GetPlayerCount() >= 2 and EntBarrack:IsAlive() and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_4"):GetAbsOrigin()
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 2 and EntBarrack:IsAlive() and time_elapsed >= 390 and time_elapsed < 750 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_4"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 750 and time_elapsed < 870 then -- Return 30 Muradin Event
		return 30

		elseif PlayerResource:GetPlayerCount() >= 2 and EntBarrack:IsAlive() and time_elapsed >= 870 and time_elapsed < 1230 then -- Level 3, higher or equal to 12 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_4"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_banes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 2 and EntBarrack:IsAlive() and time_elapsed >= 1230 and time_elapsed < 1590 then -- Level 4, higher or equal to 18 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_4"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_phoenixes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 2 and EntBarrack:IsAlive() and time_elapsed >= 1590 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_4"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds
		end
	end)

	--//=================================================================================================================
	--// Timer: Creeps Level 1, 4 East 1
	--//=================================================================================================================
	local time_elapsed = 0
	local EntBarrack = Entities:FindByName( nil, "dota_badguys_barracks_east_1" )
	Timers:CreateTimer(0, function()
		time_elapsed = time_elapsed + 30 -- with this system, the time_elapsed should be set to the Game Time + 30 sec, e.g: 5 Min = 300sec + 30 = 330
		if PlayerResource:GetPlayerCount() >= 3 and EntBarrack:IsAlive() and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_5"):GetAbsOrigin()
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 3 and EntBarrack:IsAlive() and time_elapsed >= 390 and time_elapsed < 750 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_5"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 750 and time_elapsed < 870 then -- Return 30 Muradin Event
		return 30

		elseif PlayerResource:GetPlayerCount() >= 3 and EntBarrack:IsAlive() and time_elapsed >= 870 and time_elapsed < 1230 then -- Level 3, higher or equal to 12 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_5"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_banes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 3 and EntBarrack:IsAlive() and time_elapsed >= 1230 and time_elapsed < 1590 then -- Level 4, higher or equal to 18 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_5"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_phoenixes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 3 and EntBarrack:IsAlive() and time_elapsed >= 1590 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_5"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds
		end
	end)

	--//=================================================================================================================
	--// Timer: Creeps Level 1, 4 East 2
	--//=================================================================================================================
	local time_elapsed = 0
	local EntBarrack = Entities:FindByName( nil, "dota_badguys_barracks_east_2" )
	Timers:CreateTimer(0, function()
		time_elapsed = time_elapsed + 30 -- with this system, the time_elapsed should be set to the Game Time + 30 sec, e.g: 5 Min = 300sec + 30 = 330
		if PlayerResource:GetPlayerCount() >= 3 and EntBarrack:IsAlive() and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_6"):GetAbsOrigin()
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 3 and EntBarrack:IsAlive() and time_elapsed >= 390 and time_elapsed < 750 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_6"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 750 and time_elapsed < 870 then -- Return 30 Muradin Event
		return 30

		elseif PlayerResource:GetPlayerCount() >= 3 and EntBarrack:IsAlive() and time_elapsed >= 870 and time_elapsed < 1230 then -- Level 3, higher or equal to 12 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_6"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_banes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 3 and EntBarrack:IsAlive() and time_elapsed >= 1230 and time_elapsed < 1590 then -- Level 4, higher or equal to 18 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_6"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_phoenixes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 3 and EntBarrack:IsAlive() and time_elapsed >= 1590 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_6"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds
		end
	end)

	--//=================================================================================================================
	--// Timer: Creeps Level 1, 4 South 1
	--//=================================================================================================================
	local time_elapsed = 0
	local EntBarrack = Entities:FindByName( nil, "dota_badguys_barracks_south_1" )
	Timers:CreateTimer(0, function()
		time_elapsed = time_elapsed + 30 -- with this system, the time_elapsed should be set to the Game Time + 30 sec, e.g: 5 Min = 300sec + 30 = 330
		if PlayerResource:GetPlayerCount() >= 4 and EntBarrack:IsAlive() and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_7"):GetAbsOrigin()
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 4 and EntBarrack:IsAlive() and time_elapsed >= 390 and time_elapsed < 750 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_7"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 750 and time_elapsed < 870 then -- Return 30 Muradin Event
		return 30

		elseif PlayerResource:GetPlayerCount() >= 4 and EntBarrack:IsAlive() and time_elapsed >= 870 and time_elapsed < 1230 then -- Level 3, higher or equal to 12 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_7"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_banes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 4 and EntBarrack:IsAlive() and time_elapsed >= 1230 and time_elapsed < 1590 then -- Level 4, higher or equal to 18 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_7"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_phoenixes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 4 and EntBarrack:IsAlive() and time_elapsed >= 1590 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_7"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds
		end
	end)

	--//=================================================================================================================
	--// Timer: Creeps Level 1, 4 South 2
	--//=================================================================================================================
	local time_elapsed = 0
	local EntBarrack = Entities:FindByName( nil, "dota_badguys_barracks_south_2" )
	Timers:CreateTimer(0, function()
		time_elapsed = time_elapsed + 30 -- with this system, the time_elapsed should be set to the Game Time + 30 sec, e.g: 5 Min = 300sec + 30 = 330
		if PlayerResource:GetPlayerCount() >= 4 and EntBarrack:IsAlive() and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_8"):GetAbsOrigin()
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 4 and EntBarrack:IsAlive() and time_elapsed >= 390 and time_elapsed < 750 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_8"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 750 and time_elapsed < 870 then -- Return 30 Muradin Event
		return 30

		elseif PlayerResource:GetPlayerCount() >= 4 and EntBarrack:IsAlive() and time_elapsed >= 870 and time_elapsed < 1230 then -- Level 3, higher or equal to 12 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_8"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_banes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 4 and EntBarrack:IsAlive() and time_elapsed >= 1230 and time_elapsed < 1590 then -- Level 4, higher or equal to 18 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_8"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_phoenixes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 4 and EntBarrack:IsAlive() and time_elapsed >= 1590 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_8"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds
		end
	end)
	elseif GameMode.Muradin_Event == 1 then
		return 30
	end -- end of if Map == Hard

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
	Timers:CreateTimer(1200, function() -- 20 Min: CAPTAIN SOUTH EVENT 4
	local point = Entities:FindByName( nil, "npc_dota_spawner_south_event"):GetAbsOrigin()

	for j = 1, 8 do
		local unit = CreateUnitByName("npc_dota_creature_captain_event_4", point, true, nil, nil, DOTA_TEAM_BADGUYS)
	end
	end)

	--//=================================================================================================================
	--// Timer: Muradin Bronzebeard Event 14 Min( End the Event )
	--//=================================================================================================================
	Timers:CreateTimer(845, function() -- 14:05 Min: MURADIN BRONZEBEARD EVENT 1, END
	GameMode.Muradin_Event = 0
	Notifications:TopToAll({text="All alive heroes have received 10 000 Gold!", duration=6.0})
	Notifications:TopToAll({ability="alchemist_goblins_greed", continue=true})
	end)

	--//=================================================================================================================
	--// Timer: Muradin Bronzebeard Event 12 Min
	--//=================================================================================================================
	Timers:CreateTimer(720, function() -- 12:00 Min: MURADIN BRONZEBEARD EVENT 1
	GameMode.Muradin_Event = 1
	local point = Entities:FindByName(nil,"npc_dota_muradin_boss"):GetAbsOrigin()
	local MuradinEvent = CreateUnitByName("npc_dota_creature_muradin_bronzebeard",Entities:FindByName(nil,"npc_dota_muradin_boss"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_BADGUYS)
	local heroes = HeroList:GetAllHeroes()

--	local creeps = Entities:FindAllByName("npc_dota_creature_mini_lifestealers")

--		for _,creep in pairs(creeps)do
--			creep:AddNewModifier(nil,nil,"modifier_invulnerable",nil)
--			creep:AddNewModifier(nil, nil, "modifier_stunned",nil)
--		end

--	local creeps2 = Entities:FindAllByName("npc_dota_creature_mini_weavers")

--		for _,creep2 in pairs(creeps2)do
--			creep2:AddNewModifier(nil,nil,"modifier_invulnerable",nil)
--			creep2:AddNewModifier(nil, nil, "modifier_stunned",nil)
--		end

	MuradinEvent:SetAngles(0, 270, 0)
	Notifications:TopToAll({hero="npc_dota_hero_zuus", duration=5.0})
	Notifications:TopToAll({text="Muradin Event Begins!", continue=true})
	Timers:CreateTimer( 5.0, StartMuradinEvent )
	Timers:CreateTimer( 120, EndMuradinEvent )
		Timers:CreateTimer(130, function() -- 2:10 Min
		MuradinEvent:ForceKill(true)
		end)
		for _,hero in pairs(heroes) do
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				FindClearSpaceForUnit(hero, point, true)
				hero:AddNewModifier(nil, nil, "modifier_stunned",nil)
				hero:AddNewModifier(nil, nil, "modifier_invulnerable",nil)
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
			end
		end
	end)
end

function StartMuradinEvent()
	local heroes = HeroList:GetAllHeroes()
		for _,hero in pairs(heroes) do
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
			PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil)
			hero:RemoveModifierByName("modifier_stunned")
			hero:RemoveModifierByName("modifier_invulnerable")
			end

			if hero:IsAlive() then
				Timers:CreateTimer(115, function()
					if hero:IsAlive() then
						PlayerResource:ModifyGold( hero:GetPlayerOwnerID(), 10000, false,  DOTA_ModifyGold_Unspecified )
					end
				end)
			end
		end
	return nil
end

function EndMuradinEvent()
	local heroes = HeroList:GetAllHeroes()
	local point = Entities:FindByName(nil,"base_spawn"):GetAbsOrigin()

	for _,hero in pairs(heroes) do
		if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
		hero:AddNewModifier(nil, nil, "modifier_stunned",nil)
		hero:AddNewModifier(nil, nil, "modifier_invulnerable",nil)
			Timers:CreateTimer(6, function()
			PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
			FindClearSpaceForUnit(hero, point, true)
			hero:RemoveModifierByName("modifier_stunned")
			hero:RemoveModifierByName("modifier_invulnerable")
			end)

			Timers:CreateTimer(6.5, function()
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil)
			end)
		end
	end
	return nil
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
	mode:SetFixedRespawnTime( 120 )
	mode:SetBuybackEnabled( false )

	if GetMapName() == "hardmode" then
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 4 )
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 0 )
	else
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 8 )
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 0 )
	end

	GameMode:_InitGameMode()

	GameRules:GetGameModeEntity():SetThink( "OnThink", self, 1 )

	self.countdownEnabled = false
--	ListenToGameEvent( "game_rules_state_change", Dynamic_Wrap( GameMode, 'OnGameRulesStateChange' ), self )

	Convars:RegisterCommand( "overthrow_set_timer", function(...) return SetTimerMuradin( ... ) end, "Set the timer.", FCVAR_CHEAT )

	DebugPrint('[BAREBONES] Done loading Barebones gamemode!\n\n')
end

function GameMode:OnGameRulesStateChange(keys)
	DebugPrint("[BAREBONES] GameRules State Changed")
	DebugPrintTable(keys)
	local heroes = HeroList:GetAllHeroes()

	-- This internal handling is used to set up main barebones functions
	GameMode:_OnGameRulesStateChange(keys)

	local newState = GameRules:State_Get()

	if newState == DOTA_GAMERULES_STATE_PRE_GAME then
		self._fPreGameStartTime = GameRules:GetGameTime()
		for _,hero in pairs(heroes) do
			if hero:IsRealHero() and not hero:IsIllusion() then
				local item1 = CreateItem("item_ankh_of_reincarnation", hero, hero)
				hero:AddItem(item1)

				local item2 = CreateItem("item_salve_1000", hero, hero)
				hero:AddItem(item2)
			else return nil
			end
		end
	end

	if newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		nCOUNTDOWNTIMER = 721
		print("Timer Set to 12 Min!")
		print( "OnGameRulesStateChange: Game In Progress" )
		self.countdownEnabled = true
		CustomGameEventManager:Send_ServerToAllClients( "show_timer", {} )
	end
end

function GameMode:OnThink()	
	-- Stop thinking if game is paused
	if GameRules:IsGamePaused() == true then
		return 1
	end
	CountdownTimerMuradin()
	if nCOUNTDOWNTIMER == 30 then
		CustomGameEventManager:Send_ServerToAllClients( "timer_alert", {} )
	elseif nCOUNTDOWNTIMER < -5 then
		nCOUNTDOWNTIMER = 714
	end
	return 1
end

function CountdownTimerMuradin()
	nCOUNTDOWNTIMER = nCOUNTDOWNTIMER - 1
	local t = nCOUNTDOWNTIMER
--	print( "Countdown Timer Activated" )
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
		}
	CustomGameEventManager:Send_ServerToAllClients( "countdown", broadcast_gametimer )
	if t <= 120 then
		CustomGameEventManager:Send_ServerToAllClients( "time_remaining", broadcast_gametimer )
	end
end

function SetTimerMuradin( cmdName, time )
	print( "Set the timer to: " .. time )
	nCOUNTDOWNTIMER = time
end
