_G.nCOUNTDOWNTIMER = 720
_G.nCOUNTDOWNCREEP = 720
_G.nCOUNTDOWNINCWAVE = 720

if GameMode == nil then
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
end

function GameMode:OnAllPlayersLoaded()
	GameMode.FrostTowers_killed = 0
	GameMode.Magtheridon_killed = 0
	GameMode.BossesTop_killed = 0
	GameMode.Arthas_killed = 0
	GameMode.MuradinTimeLapse = 0
end

function GameMode:OnHeroInGame(hero)
end

function GameMode:OnGameInProgress()

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
	nCOUNTDOWNCREEP = 361
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
	--// Timer: West, North, East, South Event Whispering
	--//=================================================================================================================
	Timers:CreateTimer(270, function() -- 4 Min 30 sec
	Notifications:TopToAll({text="WARNING: Incoming wave of Darkness from the West!", duration=29.0, color="red"})
	end)
	Timers:CreateTimer(570, function() -- 9 Min 30 sec
	Notifications:TopToAll({text="WARNING: Incoming wave of Darkness from the North!", duration=29.0, color="red"})
	end)
	Timers:CreateTimer(870, function() -- 14 Min 30 sec
	Notifications:TopToAll({text="WARNING: Incoming wave of Darkness from the East!", duration=29.0, color="red"})
	end)
	Timers:CreateTimer(1170, function() -- 19 Min 30 sec
	Notifications:TopToAll({text="WARNING: Incoming wave of Darkness from the South!", duration=29.0, color="red"})
	end)
	Timers:CreateTimer(1470, function() -- 24 Min 30 sec
	Notifications:TopToAll({text="WARNING: Incoming wave of Darkness from the West!", duration=29.0, color="red"})
	end)
	Timers:CreateTimer(1770, function() -- 24 Min 30 sec
	Notifications:TopToAll({text="WARNING: Incoming wave of Darkness from the North!", duration=29.0, color="red"})
	end)
	--//=================================================================================================================
	--// Timer: Muradin Event Whispering
	--//=================================================================================================================
	Timers:CreateTimer(600, function() -- 10 Min
	Notifications:TopToAll({text="Warning, Muradin Event in 2 Min!", style={color="red"}, duration=10.0})
	end)
	Timers:CreateTimer(660, function() -- 11:00 Min
	Notifications:TopToAll({text="Warning, Muradin Event in 1 Min! Creeps will stop spawning now.", style={color="red"}, duration=10.0})
	end)

	--//=================================================================================================================
	--// Timer: Creeps Level 1, 5 West 1
	--//=================================================================================================================
	if GetMapName() == "x_hero_siege_8_players" then -- 8 Players Creep Lanes
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

			elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 390 and time_elapsed < 720 then -- Level 2, higher or equal to 6 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_1"):GetAbsOrigin()
				for j = 1, 4 do
				local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
				end
				local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
				local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			return 30

			elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 720 and time_elapsed < 870 then -- Return 30 Muradin Event
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

		elseif PlayerResource:GetPlayerCount() >= 2 and EntBarrack:IsAlive() and time_elapsed >= 390 and time_elapsed < 720 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_2"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 720 and time_elapsed < 870 then -- Return 30 Muradin Event
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

		elseif PlayerResource:GetPlayerCount() >= 3 and EntBarrack:IsAlive() and time_elapsed >= 390 and time_elapsed < 720 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_3"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 720 and time_elapsed < 870 then -- Return 30 Muradin Event
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

		elseif PlayerResource:GetPlayerCount() >= 4 and EntBarrack:IsAlive() and time_elapsed >= 390 and time_elapsed < 720 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_4"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 720 and time_elapsed < 870 then -- Return 30 Muradin Event
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

		elseif PlayerResource:GetPlayerCount() >= 5 and EntBarrack:IsAlive() and time_elapsed >= 390 and time_elapsed < 720 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_5"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 720 and time_elapsed < 870 then -- Return 30 Muradin Event
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

		elseif PlayerResource:GetPlayerCount() >= 6 and EntBarrack:IsAlive() and time_elapsed >= 390 and time_elapsed < 720 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_6"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 720 and time_elapsed < 870 then -- Return 30 Muradin Event
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
	local EntBarrack = Entities:FindByName( nil, "dota_badguys_barracks_south_2" )
	Timers:CreateTimer(0, function()
		time_elapsed = time_elapsed + 30 -- with this system, the time_elapsed should be set to the Game Time + 30 sec, e.g: 5 Min = 300sec + 30 = 330
		if PlayerResource:GetPlayerCount() >= 7 and EntBarrack:IsAlive() and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_7"):GetAbsOrigin()
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 7 and EntBarrack:IsAlive() and time_elapsed >= 390 and time_elapsed < 720 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_7"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 720 and time_elapsed < 870 then -- Return 30 Muradin Event
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
	local EntBarrack = Entities:FindByName( nil, "dota_badguys_barracks_south_1" )
	Timers:CreateTimer(0, function()
		time_elapsed = time_elapsed + 30 -- with this system, the time_elapsed should be set to the Game Time + 30 sec, e.g: 5 Min = 300sec + 30 = 330
		if PlayerResource:GetPlayerCount() >= 8 and EntBarrack:IsAlive() and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_8"):GetAbsOrigin()
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 8 and EntBarrack:IsAlive() and time_elapsed >= 390 and time_elapsed < 720 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_8"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 720 and time_elapsed < 870 then -- Return 30 Muradin Event
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
	end -- end of if Map == Normal and not Event Muradin Running

	--//=================================================================================================================
	--// HARD MODE
	--//=================================================================================================================
	--//=================================================================================================================
	--// Timer: Creeps Level 1, 5 West 1
	--//=================================================================================================================
	if GetMapName() == "hardmode" then -- 4 Players Creep Lanes, Hard Mode

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

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 390 and time_elapsed < 720 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_1"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 720 and time_elapsed < 870 then -- Return 30 Muradin Event
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

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 390 and time_elapsed < 720 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_2"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 720 and time_elapsed < 870 then -- Return 30 Muradin Event
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

		elseif PlayerResource:GetPlayerCount() >= 2 and EntBarrack:IsAlive() and time_elapsed >= 390 and time_elapsed < 720 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_3"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 720 and time_elapsed < 870 then -- Return 30 Muradin Event
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

		elseif PlayerResource:GetPlayerCount() >= 2 and EntBarrack:IsAlive() and time_elapsed >= 390 and time_elapsed < 720 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_4"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 720 and time_elapsed < 870 then -- Return 30 Muradin Event
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

		elseif PlayerResource:GetPlayerCount() >= 3 and EntBarrack:IsAlive() and time_elapsed >= 390 and time_elapsed < 720 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_5"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 720 and time_elapsed < 870 then -- Return 30 Muradin Event
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

		elseif PlayerResource:GetPlayerCount() >= 3 and EntBarrack:IsAlive() and time_elapsed >= 390 and time_elapsed < 720 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_6"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 720 and time_elapsed < 870 then -- Return 30 Muradin Event
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

		elseif PlayerResource:GetPlayerCount() >= 4 and EntBarrack:IsAlive() and time_elapsed >= 390 and time_elapsed < 720 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_7"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 720 and time_elapsed < 870 then -- Return 30 Muradin Event
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

		elseif PlayerResource:GetPlayerCount() >= 4 and EntBarrack:IsAlive() and time_elapsed >= 390 and time_elapsed < 720 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_8"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 720 and time_elapsed < 870 then -- Return 30 Muradin Event
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
	end -- end of if Map == Hard

	if GetMapName() == "solomode" then -- 1 Players Creep Lane, Solo Mode

	local time_elapsed = 0
	local EntBarrack = Entities:FindByName( nil, "dota_badguys_barracks_west_1" )
	Timers:CreateTimer(0, function()
	time_elapsed = time_elapsed + 30 -- with this system, the time_elapsed should be set to the Game Time + 30 sec, e.g: 5 Min = 300sec + 30 = 330
	print( time_elapsed )
--	Notifications:TopToAll({text="Creep Lane 1, West 1 spawning in Hard Mode", duration=6.0})
		if PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_1"):GetAbsOrigin()
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 390 and time_elapsed < 720 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_1"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 720 and time_elapsed < 870 then -- Return 30 Muradin Event
		return 30

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 870 and time_elapsed < 1230 then -- Level 3, higher or equal to 12 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_1"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_banes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 1230 and time_elapsed < 1590 then -- Level 4, higher or equal to 18 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_1"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_phoenixes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and EntBarrack:IsAlive() and time_elapsed >= 1590 then -- Level 4, higher or equal to 18 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_1"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds
		end
	end)
	end -- end of if Map == Solo

	--//=================================================================================================================
	--// Timer: West Event 1 Spawn
	--//=================================================================================================================
	Timers:CreateTimer(301, function() -- 5 Min: DEATH PROPHET WEST EVENT 1
	local point = Entities:FindByName( nil, "npc_dota_spawner_west_event"):GetAbsOrigin()

	if GetMapName() == "x_hero_siege_8_players" then
		for j = 1, 10 do
			local unit = CreateUnitByName("npc_dota_creature_necrolyte_event_1", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		end
		elseif GetMapName() == "hardmode" then
		for j = 1, 8 do
			local unit = CreateUnitByName("npc_dota_creature_necrolyte_event_1", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		end
		elseif GetMapName() == "solomode" then
		for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_necrolyte_event_1", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		end
	end
	end)

	--//=================================================================================================================
	--// Timer: North Event 2 Spawn
	--//=================================================================================================================
	Timers:CreateTimer(601, function() -- 10 Min: NAGA SIREN NORTH EVENT 2
	local point = Entities:FindByName( nil, "npc_dota_spawner_north_event"):GetAbsOrigin()
	if GetMapName() == "x_hero_siege_8_players" then
		for j = 1, 10 do
			local unit = CreateUnitByName("npc_dota_creature_naga_siren_event_2", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		end
		elseif GetMapName() == "hardmode" then
		for j = 1, 8 do
			local unit = CreateUnitByName("npc_dota_creature_naga_siren_event_2", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		end
		elseif GetMapName() == "solomode" then
		for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_naga_siren_event_2", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		end
	end
	end)

	--//=================================================================================================================
	--// Timer: East Event 3 Spawn
	--//=================================================================================================================
	Timers:CreateTimer(901, function() -- 15 Min: VENGEFUL SPIRIT SOUTH EVENT 3
	local point = Entities:FindByName( nil, "npc_dota_spawner_east_event"):GetAbsOrigin()
	if GetMapName() == "x_hero_siege_8_players" then
		for j = 1, 10 do
			local unit = CreateUnitByName("npc_dota_creature_vengeful_spirit_event_3", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		end
		elseif GetMapName() == "hardmode" then
		for j = 1, 8 do
			local unit = CreateUnitByName("npc_dota_creature_vengeful_spirit_event_3", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		end
		elseif GetMapName() == "solomode" then
		for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_vengeful_spirit_event_3", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		end
	end
	end)

	--//=================================================================================================================
	--// Timer: South Event 4 Spawn
	--//=================================================================================================================
	Timers:CreateTimer(1201, function() -- 20 Min: CAPTAIN SOUTH EVENT 4
	local point = Entities:FindByName( nil, "npc_dota_spawner_south_event"):GetAbsOrigin()
	if GetMapName() == "x_hero_siege_8_players" then
		for j = 1, 10 do
			local unit = CreateUnitByName("npc_dota_creature_captain_event_4", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		end
		elseif GetMapName() == "hardmode" then
		for j = 1, 8 do
			local unit = CreateUnitByName("npc_dota_creature_captain_event_4", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		end
		elseif GetMapName() == "solomode" then
		for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_captain_event_4", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		end
	end
	end)

	--//=================================================================================================================
	--// Timer: West Event 5 Spawn
	--//=================================================================================================================
	Timers:CreateTimer(1501, function() -- 25 Min: SLARDARS EVENT 5
	local point = Entities:FindByName( nil, "npc_dota_spawner_west_event"):GetAbsOrigin()
	if GetMapName() == "x_hero_siege_8_players" then
		for j = 1, 10 do
			local unit = CreateUnitByName("npc_dota_creature_slardar_event_5", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		end
		elseif GetMapName() == "hardmode" then
		for j = 1, 8 do
			local unit = CreateUnitByName("npc_dota_creature_slardar_event_5", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		end
		elseif GetMapName() == "solomode" then
		for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_slardar_event_5", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		end
	end
	end)

	--//=================================================================================================================
	--// Timer: North Event 6 Spawn
	--//=================================================================================================================
	Timers:CreateTimer(1801, function() -- 30 Min: CHAOS KNIGHTS EVENT 6
	local point = Entities:FindByName( nil, "npc_dota_spawner_north_event"):GetAbsOrigin()
	if GetMapName() == "x_hero_siege_8_players" then
		for j = 1, 10 do
			local unit = CreateUnitByName("npc_dota_creature_chaos_knight_event_6", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		end
		elseif GetMapName() == "hardmode" then
		for j = 1, 8 do
			local unit = CreateUnitByName("npc_dota_creature_chaos_knight_event_6", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		end
		elseif GetMapName() == "solomode" then
		for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_chaos_knight_event_6", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		end
	end
	end)

	--//=================================================================================================================
	--// Timer: Muradin Bronzebeard Event 14 Min( End the Event )
	--//=================================================================================================================
	Timers:CreateTimer(845, function() -- 14:05 Min: MURADIN BRONZEBEARD EVENT 1, END
	Notifications:TopToAll({text="All heroes who survived Muradin received 10 000 Gold!", duration=6.0})
	Notifications:TopToAll({ability="alchemist_goblins_greed", continue=true})
	end)

	--//=================================================================================================================
	--// Timer: Muradin Bronzebeard Event 12 Min
	--//=================================================================================================================
	Timers:CreateTimer(720, function() -- 12:00 Min: MURADIN BRONZEBEARD EVENT 1
	GameMode.MuradinTimeLapse = 1
	nCOUNTDOWNTIMER = 121
	local point = Entities:FindByName(nil,"npc_dota_muradin_player"):GetAbsOrigin()
	local MuradinEvent = CreateUnitByName("npc_dota_creature_muradin_bronzebeard",Entities:FindByName(nil,"npc_dota_muradin_boss"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_BADGUYS)
	local heroes = HeroList:GetAllHeroes()
	local teleporters = Entities:FindAllByName("trigger_teleport_muradin_end")

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
	Notifications:TopToAll({text="You can't kill him! Just survive the Countdown", continue=true})
	Notifications:TopToAll({text="Reward: 10 000 Gold.", continue=true})
	Timers:CreateTimer( 3.0, StartMuradinEvent )
	Timers:CreateTimer( 120, EndMuradinEvent )
		Timers:CreateTimer(120, function() -- 14:00 Min
			for _,v in pairs(teleporters) do
			v:Enable()
			end
		end)
		for _,hero in pairs(heroes) do
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				FindClearSpaceForUnit(hero, point, true)
				hero:AddNewModifier(nil, nil, "modifier_stunned",nil)
				hero:AddNewModifier(nil, nil, "modifier_invulnerable",nil)
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
			end
		end
		Timers:CreateTimer(121, function() -- 14:01 Min
			MuradinEvent:ForceKill(true)
		end)
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
		end
	return nil
end

	XP_PER_LEVEL_TABLE = {
	0,-- 1
	300,-- 2
	600,-- 3
	1000,-- 4
	1500,-- 5
	2100,-- 6
	2900,-- 7
	3900,-- 8
	5100,-- 9
	6500,-- 10
	8100,-- 11
	9900,-- 12
	11900,-- 13
	14100,-- 14
	16500,-- 15
	19100,-- 16
	21900,-- 17
	24900,-- 18
	28100,-- 19
	31500-- 20
}

function GameMode:InitGameMode()
	GameMode = self

	mode = GameRules:GetGameModeEntity()
	mode:SetCustomHeroMaxLevel( 20 )
	mode:SetCustomXPRequiredToReachNextLevel( XP_PER_LEVEL_TABLE )
	mode:SetUseCustomHeroLevels( true )
	mode:SetBuybackEnabled( false )

	if GetMapName() == "x_hero_siege_8_players" then
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 8 )
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 0 )
		mode:SetFixedRespawnTime( 45 )
	elseif GetMapName() == "hardmode" then
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 4 )
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 0 )
		mode:SetFixedRespawnTime( 60 )
	else
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 1 )
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 0 )
		mode:SetFixedRespawnTime( 20 )
	end

	GameMode:_InitGameMode()

	GameRules:GetGameModeEntity():SetThink( "OnThink", self, 1 )

	self.countdownEnabled = false
--	ListenToGameEvent( "game_rules_state_change", Dynamic_Wrap( GameMode, 'OnGameRulesStateChange' ), self )

	Convars:RegisterCommand( "muradin_set_timer", function(...) return SetTimerMuradin( ... ) end, "Set the timer.", FCVAR_CHEAT )
	Convars:RegisterCommand( "creep_set_timer", function(...) return SetTimerCreep( ... ) end, "Set the timer.", FCVAR_CHEAT )
	Convars:RegisterCommand( "wave_set_timer", function(...) return SetTimerIncomingWave( ... ) end, "Set the timer.", FCVAR_CHEAT )
end

function GameMode:OnGameRulesStateChange(keys)
	local heroes = HeroList:GetAllHeroes()

	-- This internal handling is used to set up main barebones functions
	GameMode:_OnGameRulesStateChange(keys)

	local newState = GameRules:State_Get()

	if newState == DOTA_GAMERULES_STATE_PRE_GAME then
		self._fPreGameStartTime = GameRules:GetGameTime()
		for _,hero in pairs(heroes) do
			if hero:IsRealHero() then
--				local item1 = CreateItem("item_ankh_of_reincarnation", hero, hero)
--				hero:AddItem(item1)

--				local item2 = CreateItem("item_salve_1000", hero, hero)
--				hero:AddItem(item2)
			end
		end
	end

	if newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		nCOUNTDOWNTIMER = 721
		nCOUNTDOWNCREEP = 361
		nCOUNTDOWNINCWAVE = 301
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
	CountdownTimerCreep()
	CountdownTimerIncomingWave()

	if nCOUNTDOWNTIMER == 30 then
		CustomGameEventManager:Send_ServerToAllClients( "timer_alert", {} )
	elseif nCOUNTDOWNTIMER < -5 --[[and GameMode.MuradinTimeLapse > 0--]] then
		nCOUNTDOWNTIMER = 14394 -- Debug = 7200
	end

	if nCOUNTDOWNCREEP < 1 then
		nCOUNTDOWNCREEP = 360
	end

	if nCOUNTDOWNINCWAVE < 1 then
		nCOUNTDOWNINCWAVE = 300
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

function CountdownTimerCreep()
	nCOUNTDOWNCREEP = nCOUNTDOWNCREEP - 1
	local t = nCOUNTDOWNCREEP
--	print( "Countdown Timer Activated" )
	local minutes = math.floor(t / 60)
	local seconds = t - (minutes * 60)
	local m10 = math.floor(minutes / 10)
	local m01 = minutes - (m10 * 10)
	local s10 = math.floor(seconds / 10)
	local s01 = seconds - (s10 * 10)
	local broadcast_gametimer = 
		{
			timer_minute_10_2 = m10,
			timer_minute_01_2 = m01,
			timer_second_10_2 = s10,
			timer_second_01_2 = s01,
		}
	CustomGameEventManager:Send_ServerToAllClients( "creepcountdown", broadcast_gametimer )
end

function SetTimerCreep( cmdName, time )
	print( "Set the timer to: " .. time )
	nCOUNTDOWNCREEP = time
end

function CountdownTimerIncomingWave()
	nCOUNTDOWNINCWAVE = nCOUNTDOWNINCWAVE - 1
	local t = nCOUNTDOWNINCWAVE
--	print( "Countdown Timer Activated" )
	local minutes = math.floor(t / 60)
	local seconds = t - (minutes * 60)
	local m10 = math.floor(minutes / 10)
	local m01 = minutes - (m10 * 10)
	local s10 = math.floor(seconds / 10)
	local s01 = seconds - (s10 * 10)
	local broadcast_gametimer = 
		{
			timer_minute_10_3 = m10,
			timer_minute_01_3 = m01,
			timer_second_10_3 = s10,
			timer_second_01_3 = s01,
		}
	CustomGameEventManager:Send_ServerToAllClients( "incomingwavecountdown", broadcast_gametimer )
end

function SetTimerIncomingWave( cmdName, time )
	print( "Set the timer to: " .. time )
	nCOUNTDOWNINCWAVE = time
end
