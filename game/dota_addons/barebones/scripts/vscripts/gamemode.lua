_G.nCOUNTDOWNTIMER = 0
_G.nCOUNTDOWNCREEP = 0
_G.nCOUNTDOWNINCWAVE = 0
_G.time_elapsed = 0

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

require('events')

require('phases/phase2')

function GameMode:OnFirstPlayerLoaded()
end

function FrostTowersToFinalWave()
	if GameMode.FrostTowers_killed >= 2 then
		nCOUNTDOWNTIMER = 60
	end
end

function FrostInfernalTimer()
	nCOUNTDOWNTIMER = 120
end

function FrostInfernalTimerEnd()
	nCOUNTDOWNTIMER = -4
end

function GameMode:OnAllPlayersLoaded()
	GameMode.FrostTowers_killed = 0
	GameMode.Magtheridon_killed = 0
	GameMode.BossesTop_killed = 0
	GameMode.Arthas_killed = 0
	-- Debug
	local triggers_choice = Entities:FindAllByName("trigger_special_event_choice")
	for _,v in pairs(triggers_choice) do
			v:Enable()
	end
end

function GameMode:OnHeroInGame(hero)
hero:SetGold(0, false)
	if hero:GetUnitName() == "npc_dota_hero_wisp" then
		hero:SetAbilityPoints(0)
		hero:AddNewModifier(nil, nil, "modifier_animation_freeze_stun", {Duration = 4, IsHidden = true})
		hero:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 4, IsHidden = true})
	end
end

function GameMode:OnGameInProgress()
local difficulty = GameRules:GetCustomGameDifficulty()
local triggers_choice = Entities:FindAllByName("trigger_special_event_choice")

	--//=================================================================================================================
	--// Timer: Creeps Levels 2, 3, 4, 5, 6 Whispering
	--//=================================================================================================================
	Timers:CreateTimer(360, function() -- 6 Min
	Notifications:TopToAll({hero="npc_dota_hero_undying", duration=6.0})
	Notifications:TopToAll({text="Creeps are now Level 2!", style={color="green"}, continue=true})
	end)

	Timers:CreateTimer(840, function() -- 12 Min 30 + 2 Min with Muradin Event = 14 Min 30
	Notifications:TopToAll({hero="npc_dota_hero_nyx_assassin", duration=6.0})
	Notifications:TopToAll({text="Creeps are now Level 3!", style={color="grey"}, continue=true})
	Notifications:TopToAll({text="Frost Infernal is unlocked!", style={color="grey"}, continue=true})
	nCOUNTDOWNCREEP = 361
	nCOUNTDOWNINCWAVE = 241
		for _,v in pairs(triggers_choice) do
			v:Enable()
		end
	end)

	Timers:CreateTimer(1200, function() -- 18 Min 30 + 2 Min with Muradin Event = 20 Min 30
	Notifications:TopToAll({hero="npc_dota_hero_doom_bringer", duration=6.0})
	Notifications:TopToAll({text="Creeps are now Level 4!", style={color="red"}, continue=true})
	end)

	Timers:CreateTimer(1560, function() -- 24 Min 30 + 2 Min with Muradin Event = 26 Min 30
	Notifications:TopToAll({hero="npc_dota_hero_phantom_lancer", duration=6.0})
	Notifications:TopToAll({text="Creeps are now Level 5!", style={color="blue"}, continue=true})
	end)

	Timers:CreateTimer(1920, function() -- 30 Min 30 + 2 Min with Muradin Event = 26 Min 30
	Notifications:TopToAll({hero="npc_dota_hero_tiny", duration=6.0})
	Notifications:TopToAll({text="Creeps are now Level 6!", style={color="white"}, continue=true})
	end)

	--//=================================================================================================================
	--// Timer: West, North, East, South Event Whispering
	--//=================================================================================================================
	Timers:CreateTimer(211, function() -- 3 Min 30 sec
	Notifications:TopToAll({text="WARNING: Incoming wave of Darkness from the West!", duration=25.0, style={color="red"}})
	end)
	Timers:CreateTimer(451, function() -- 7 Min 30 sec
	Notifications:TopToAll({text="WARNING: Incoming wave of Darkness from the North!", duration=25.0, style={color="red"}})
	end)
	Timers:CreateTimer(811, function() -- 11 Min 30 sec
	Notifications:TopToAll({text="WARNING: Incoming wave of Darkness from the East!", duration=25.0, style={color="red"}})
	end)
	Timers:CreateTimer(1051, function() -- 15 Min 30 sec
	Notifications:TopToAll({text="WARNING: Incoming wave of Darkness from the South!", duration=25.0, style={color="red"}})
	end)
	Timers:CreateTimer(1291, function() -- 19 Min 30 sec
	Notifications:TopToAll({text="WARNING: Incoming wave of Darkness from the West!", duration=25.0, style={color="red"}})
	end)
	Timers:CreateTimer(1531, function() -- 23 Min 30 sec
	Notifications:TopToAll({text="WARNING: Incoming wave of Darkness from the North!", duration=25.0, style={color="red"}})
	end)
	Timers:CreateTimer(1771, function() -- 27 Min 30 sec
	Notifications:TopToAll({text="WARNING: Incoming wave of Darkness from the East!", duration=25.0, style={color="red"}})
	end)
	Timers:CreateTimer(2011, function() -- 31 Min 30 sec
	Notifications:TopToAll({text="WARNING: Incoming wave of Darkness from the South!", duration=25.0, style={color="red"}})
	end)

	--//=================================================================================================================
	--// Timer: Creeps Level 1, 5 West 1
	--//=================================================================================================================
	local EntBarrack = Entities:FindByName( nil, "dota_badguys_barracks_west_1" )
		Timers:CreateTimer(0, function()
		time_elapsed = time_elapsed + 30 -- with this system, the time_elapsed should be set to the Game Time + 30 sec, e.g: 5 Min = 300sec + 30 = 330
		print( time_elapsed )
--		Notifications:TopToAll({text="Creep Lane 1, West 1 spawning in Normal Mode", duration=6.0})
			if PlayerResource:GetPlayerCount() >= 1 and not EntBarrack:IsNull() and time_elapsed < 390 then -- Level 1 lower than 6 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_1"):GetAbsOrigin()
				for j = 1, 3 do
				local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
				end
				local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			return 30 -- Rerun this timer every 30 game-time seconds

			elseif PlayerResource:GetPlayerCount() >= 1 and not EntBarrack:IsNull() and time_elapsed >= 390 and time_elapsed < 750 then -- Level 2, higher or equal to 6 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_1"):GetAbsOrigin()
				for j = 1, 4 do
				local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
				end
				local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
				local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			return 30

			elseif PlayerResource:GetPlayerCount() >= 1 and not EntBarrack:IsNull() and time_elapsed >= 750 and time_elapsed < 870 then -- Return 30 Muradin Event
			return 30

			elseif PlayerResource:GetPlayerCount() >= 1 and not EntBarrack:IsNull() and time_elapsed >= 870 and time_elapsed < 1230 then -- Level 3, higher or equal to 12 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_1"):GetAbsOrigin()
				for j = 1, 5 do
				local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
				end
				for j = 1, 3 do
				local unit = CreateUnitByName("npc_dota_creature_mini_fiends", point, true, nil, nil, DOTA_TEAM_BADGUYS)
				end
			return 30

			elseif PlayerResource:GetPlayerCount() >= 1 and not EntBarrack:IsNull() and time_elapsed >= 1230 and time_elapsed < 1590 then -- Level 4, higher or equal to 18 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_1"):GetAbsOrigin()
				for j = 1, 5 do
				local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
				end
				for j = 1, 3 do
				local unit = CreateUnitByName("npc_dota_creature_mini_jakiros", point, true, nil, nil, DOTA_TEAM_BADGUYS)
				end
			return 30

			elseif PlayerResource:GetPlayerCount() >= 1 and not EntBarrack:IsNull() and time_elapsed >= 1590 and time_elapsed < 1950 then -- Level 5, higher or equal to 26:30 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_1"):GetAbsOrigin()
				for j = 1, 6 do
				local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
				end
				for j = 1, 4 do
				local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
				end
			return 30

			elseif PlayerResource:GetPlayerCount() >= 1 and not EntBarrack:IsNull() and time_elapsed >= 1950 then -- Level 5, higher or equal to 32:30 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_1"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_tinys", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_wyverns", point, true, nil, nil, DOTA_TEAM_BADGUYS)
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
		if PlayerResource:GetPlayerCount() >= 2 and not EntBarrack:IsNull() and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_2"):GetAbsOrigin()
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 2 and not EntBarrack:IsNull() and time_elapsed >= 390 and time_elapsed < 750 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_2"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and not EntBarrack:IsNull() and time_elapsed >= 750 and time_elapsed < 870 then -- Return 30 Muradin Event
		return 30

		elseif PlayerResource:GetPlayerCount() >= 2 and not EntBarrack:IsNull() and time_elapsed >= 870 and time_elapsed < 1230 then -- Level 3, higher or equal to 12 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_2"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_fiends", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 2 and not EntBarrack:IsNull() and time_elapsed >= 1230 and time_elapsed < 1590 then -- Level 4, higher or equal to 18 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_2"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_jakiros", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 2 and not EntBarrack:IsNull() and time_elapsed >= 1590 and time_elapsed < 1950 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_2"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 2 and not EntBarrack:IsNull() and time_elapsed >= 1950 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_2"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_tinys", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_wyverns", point, true, nil, nil, DOTA_TEAM_BADGUYS)
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
		if PlayerResource:GetPlayerCount() >= 3 and not EntBarrack:IsNull() and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_3"):GetAbsOrigin()
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 3 and not EntBarrack:IsNull() and time_elapsed >= 390 and time_elapsed < 750 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_3"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and not EntBarrack:IsNull() and time_elapsed >= 750 and time_elapsed < 870 then -- Return 30 Muradin Event
		return 30

		elseif PlayerResource:GetPlayerCount() >= 3 and not EntBarrack:IsNull() and time_elapsed >= 870 and time_elapsed < 1230 then -- Level 3, higher or equal to 12 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_3"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_fiends", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 3 and not EntBarrack:IsNull() and time_elapsed >= 1230 and time_elapsed < 1590 then -- Level 4, higher or equal to 18 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_3"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_jakiros", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 3 and not EntBarrack:IsNull() and time_elapsed >= 1590 and time_elapsed < 1950 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_3"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 3 and not EntBarrack:IsNull() and time_elapsed >= 1950 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_3"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_tinys", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_wyverns", point, true, nil, nil, DOTA_TEAM_BADGUYS)
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
		if PlayerResource:GetPlayerCount() >= 4 and not EntBarrack:IsNull() and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_4"):GetAbsOrigin()
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 4 and not EntBarrack:IsNull() and time_elapsed >= 390 and time_elapsed < 750 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_4"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and not EntBarrack:IsNull() and time_elapsed >= 750 and time_elapsed < 870 then -- Return 30 Muradin Event
		return 30

		elseif PlayerResource:GetPlayerCount() >= 4 and not EntBarrack:IsNull() and time_elapsed >= 870 and time_elapsed < 1230 then -- Level 3, higher or equal to 12 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_4"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_fiends", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 4 and not EntBarrack:IsNull() and time_elapsed >= 1230 and time_elapsed < 1590 then -- Level 4, higher or equal to 18 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_4"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_jakiros", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 4 and not EntBarrack:IsNull() and time_elapsed >= 1590 and time_elapsed < 1950 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_4"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 4 and not EntBarrack:IsNull() and time_elapsed >= 1950 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_4"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_tinys", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_wyverns", point, true, nil, nil, DOTA_TEAM_BADGUYS)
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
		if PlayerResource:GetPlayerCount() >= 5 and not EntBarrack:IsNull() and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_5"):GetAbsOrigin()
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 5 and not EntBarrack:IsNull() and time_elapsed >= 390 and time_elapsed < 750 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_5"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and not EntBarrack:IsNull() and time_elapsed >= 750 and time_elapsed < 870 then -- Return 30 Muradin Event
		return 30

		elseif PlayerResource:GetPlayerCount() >= 5 and not EntBarrack:IsNull() and time_elapsed >= 870 and time_elapsed < 1230 then -- Level 3, higher or equal to 12 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_5"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_fiends", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 5 and not EntBarrack:IsNull() and time_elapsed >= 1230 and time_elapsed < 1590 then -- Level 4, higher or equal to 18 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_5"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_jakiros", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 5 and not EntBarrack:IsNull() and time_elapsed >= 1590 and time_elapsed < 1950 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_5"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 5 and not EntBarrack:IsNull() and time_elapsed >= 1950 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_5"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_tinys", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_wyverns", point, true, nil, nil, DOTA_TEAM_BADGUYS)
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
		if PlayerResource:GetPlayerCount() >= 6 and not EntBarrack:IsNull() and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_6"):GetAbsOrigin()
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 6 and not EntBarrack:IsNull() and time_elapsed >= 390 and time_elapsed < 750 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_6"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and not EntBarrack:IsNull() and time_elapsed >= 750 and time_elapsed < 870 then -- Return 30 Muradin Event
		return 30

		elseif PlayerResource:GetPlayerCount() >= 6 and not EntBarrack:IsNull() and time_elapsed >= 870 and time_elapsed < 1230 then -- Level 3, higher or equal to 12 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_6"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_fiends", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 6 and not EntBarrack:IsNull() and time_elapsed >= 1230 and time_elapsed < 1590 then -- Level 4, higher or equal to 18 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_6"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_jakiros", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 6 and not EntBarrack:IsNull() and time_elapsed >= 1590 and time_elapsed < 1950 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_6"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 6 and not EntBarrack:IsNull() and time_elapsed >= 1950 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_6"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_tinys", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_wyverns", point, true, nil, nil, DOTA_TEAM_BADGUYS)
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
		if PlayerResource:GetPlayerCount() >= 7 and not EntBarrack:IsNull() and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_7"):GetAbsOrigin()
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 7 and not EntBarrack:IsNull() and time_elapsed >= 390 and time_elapsed < 750 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_7"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and not EntBarrack:IsNull() and time_elapsed >= 750 and time_elapsed < 870 then -- Return 30 Muradin Event
		return 30

		elseif PlayerResource:GetPlayerCount() >= 7 and not EntBarrack:IsNull() and time_elapsed >= 870 and time_elapsed < 1230 then -- Level 3, higher or equal to 12 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_7"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_fiends", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 7 and not EntBarrack:IsNull() and time_elapsed >= 1230 and time_elapsed < 1590 then -- Level 4, higher or equal to 18 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_7"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_jakiros", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 7 and not EntBarrack:IsNull() and time_elapsed >= 1590 and time_elapsed < 1950 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_7"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 7 and not EntBarrack:IsNull() and time_elapsed >= 1950 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_7"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_tinys", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_wyverns", point, true, nil, nil, DOTA_TEAM_BADGUYS)
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
		if PlayerResource:GetPlayerCount() >= 8 and not EntBarrack:IsNull() and time_elapsed < 390 then -- Level 1 lower than 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_8"):GetAbsOrigin()
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lifestealers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_weavers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 8 and not EntBarrack:IsNull() and time_elapsed >= 390 and time_elapsed < 750 then -- Level 2, higher or equal to 6 min
		local point = Entities:FindByName( nil, "npc_dota_spawner_8"):GetAbsOrigin()
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_undyings", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			local unit = CreateUnitByName("npc_dota_creature_mini_necrolytes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 1 and not EntBarrack:IsNull() and time_elapsed >= 750 and time_elapsed < 870 then -- Return 30 Muradin Event
		return 30

		elseif PlayerResource:GetPlayerCount() >= 8 and not EntBarrack:IsNull() and time_elapsed >= 870 and time_elapsed < 1230 then -- Level 3, higher or equal to 12 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_8"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_nyxes", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_fiends", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 8 and not EntBarrack:IsNull() and time_elapsed >= 1230 and time_elapsed < 1590 then -- Level 4, higher or equal to 18 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_8"):GetAbsOrigin()
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_dota_creature_mini_dooms", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 3 do
			local unit = CreateUnitByName("npc_dota_creature_mini_jakiros", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 8 and not EntBarrack:IsNull() and time_elapsed >= 1590 and time_elapsed < 1950 then -- Level 5, higher or equal to 24 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_8"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_lancers", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_miranas", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds

		elseif PlayerResource:GetPlayerCount() >= 8 and not EntBarrack:IsNull() and time_elapsed >= 1950 then -- Level 6, higher or equal to 30 min
			local point = Entities:FindByName( nil, "npc_dota_spawner_8"):GetAbsOrigin()
			for j = 1, 6 do
			local unit = CreateUnitByName("npc_dota_creature_mini_tinys", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			for j = 1, 4 do
			local unit = CreateUnitByName("npc_dota_creature_mini_wyverns", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds
		end
	end)

	--//=================================================================================================================
	--// Timer: West Event 1 Spawn
	--//=================================================================================================================
	Timers:CreateTimer(241, function() -- 4 Min: NECROLYTE WEST EVENT 1
	local point = Entities:FindByName( nil, "npc_dota_spawner_west_event"):GetAbsOrigin()
		if difficulty == 1 then
			for j = 1, 6 do
				local unit = CreateUnitByName("npc_dota_creature_necrolyte_event_1", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		elseif difficulty == 2 then
			for j = 1, 8 do
				local unit = CreateUnitByName("npc_dota_creature_necrolyte_event_1", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		elseif difficulty == 3 then
			for j = 1, 10 do
				local unit = CreateUnitByName("npc_dota_creature_necrolyte_event_1", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		elseif difficulty == 4 then
			for j = 1, 14 do
				local unit = CreateUnitByName("npc_dota_creature_necrolyte_event_1", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		end
	end)

	--//=================================================================================================================
	--// Timer: North Event 2 Spawn
	--//=================================================================================================================
	Timers:CreateTimer(481, function() -- 8 Min: NAGA SIREN NORTH EVENT 2
	local point = Entities:FindByName( nil, "npc_dota_spawner_north_event"):GetAbsOrigin()
		if difficulty == 1 then
			for j = 1, 6 do
				local unit = CreateUnitByName("npc_dota_creature_naga_siren_event_2", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		elseif difficulty == 2 then
			for j = 1, 8 do
				local unit = CreateUnitByName("npc_dota_creature_naga_siren_event_2", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		elseif difficulty == 3 then
			for j = 1, 10 do
				local unit = CreateUnitByName("npc_dota_creature_naga_siren_event_2", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		elseif difficulty == 4 then
			for j = 1, 14 do
				local unit = CreateUnitByName("npc_dota_creature_naga_siren_event_2", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		end
	end)

	--//=================================================================================================================
	--// Timer: East Event 3 Spawn
	--//=================================================================================================================
	Timers:CreateTimer(841, function() -- 12 Min: VENGEFUL SPIRIT SOUTH EVENT 3
	local point = Entities:FindByName( nil, "npc_dota_spawner_east_event"):GetAbsOrigin()
		if difficulty == 1 then
			for j = 1, 6 do
				local unit = CreateUnitByName("npc_dota_creature_vengeful_spirit_event_3", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		elseif difficulty == 2 then
			for j = 1, 8 do
				local unit = CreateUnitByName("npc_dota_creature_vengeful_spirit_event_3", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		elseif difficulty == 3 then
			for j = 1, 10 do
				local unit = CreateUnitByName("npc_dota_creature_vengeful_spirit_event_3", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		elseif difficulty == 4 then
			for j = 1, 14 do
				local unit = CreateUnitByName("npc_dota_creature_vengeful_spirit_event_3", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		end
	end)

	--//=================================================================================================================
	--// Timer: South Event 4 Spawn
	--//=================================================================================================================
	Timers:CreateTimer(1081, function() -- 16 Min: CAPTAIN SOUTH EVENT 4
	local point = Entities:FindByName( nil, "npc_dota_spawner_south_event"):GetAbsOrigin()
		if difficulty == 1 then
			for j = 1, 6 do
				local unit = CreateUnitByName("npc_dota_creature_captain_event_4", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			elseif difficulty == 2 then
			for j = 1, 8 do
				local unit = CreateUnitByName("npc_dota_creature_captain_event_4", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			elseif difficulty == 3 then
			for j = 1, 10 do
				local unit = CreateUnitByName("npc_dota_creature_captain_event_4", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			elseif difficulty == 4 then
			for j = 1, 14 do
				local unit = CreateUnitByName("npc_dota_creature_captain_event_4", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		end
	end)

	--//=================================================================================================================
	--// Timer: West Event 5 Spawn
	--//=================================================================================================================
	Timers:CreateTimer(1321, function() -- 20 Min: SLARDARS EVENT 5
	local point = Entities:FindByName( nil, "npc_dota_spawner_west_event"):GetAbsOrigin()
		if difficulty == 1 then
			for j = 1, 6 do
				local unit = CreateUnitByName("npc_dota_creature_slardar_event_5", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			elseif difficulty == 2 then
			for j = 1, 8 do
				local unit = CreateUnitByName("npc_dota_creature_slardar_event_5", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			elseif difficulty == 3 then
			for j = 1, 10 do
				local unit = CreateUnitByName("npc_dota_creature_slardar_event_5", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			elseif difficulty == 4 then
			for j = 1, 14 do
				local unit = CreateUnitByName("npc_dota_creature_slardar_event_5", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		end
	end)

	--//=================================================================================================================
	--// Timer: North Event 6 Spawn
	--//=================================================================================================================
	Timers:CreateTimer(1561, function() -- 24 Min: CHAOS KNIGHTS EVENT 6
	local point = Entities:FindByName( nil, "npc_dota_spawner_north_event"):GetAbsOrigin()
		if difficulty == 1 then
			for j = 1, 6 do
				local unit = CreateUnitByName("npc_dota_creature_chaos_knight_event_6", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			elseif difficulty == 2 then
			for j = 1, 8 do
				local unit = CreateUnitByName("npc_dota_creature_chaos_knight_event_6", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			elseif difficulty == 3 then
			for j = 1, 10 do
				local unit = CreateUnitByName("npc_dota_creature_chaos_knight_event_6", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			elseif difficulty == 4 then
			for j = 1, 14 do
				local unit = CreateUnitByName("npc_dota_creature_chaos_knight_event_6", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		end
	end)

	--//=================================================================================================================
	--// Timer: East Event 7 Spawn
	--//=================================================================================================================
	Timers:CreateTimer(1801, function() -- 28 Min: LUNA EVENT 7
	local point = Entities:FindByName( nil, "npc_dota_spawner_east_event"):GetAbsOrigin()
		if difficulty == 1 then
			for j = 1, 6 do
				local unit = CreateUnitByName("npc_dota_creature_luna_event_7", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			elseif difficulty == 2 then
			for j = 1, 8 do
				local unit = CreateUnitByName("npc_dota_creature_luna_event_7", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			elseif difficulty == 3 then
			for j = 1, 10 do
				local unit = CreateUnitByName("npc_dota_creature_luna_event_7", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			elseif difficulty == 4 then
			for j = 1, 14 do
				local unit = CreateUnitByName("npc_dota_creature_luna_event_7", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		end
	end)

	--//=================================================================================================================
	--// Timer: South Event 8 Spawn
	--//=================================================================================================================
	Timers:CreateTimer(2041, function() -- 32 Min: LUNA EVENT 8
	local point = Entities:FindByName( nil, "npc_dota_spawner_south_event"):GetAbsOrigin()
		if difficulty == 1 then
			for j = 1, 6 do
				local unit = CreateUnitByName("npc_dota_creature_clockwerk_event_8", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			elseif difficulty == 2 then
			for j = 1, 8 do
				local unit = CreateUnitByName("npc_dota_creature_clockwerk_event_8", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			elseif difficulty == 3 then
			for j = 1, 10 do
				local unit = CreateUnitByName("npc_dota_creature_clockwerk_event_8", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			elseif difficulty == 4 then
			for j = 1, 14 do
				local unit = CreateUnitByName("npc_dota_creature_clockwerk_event_8", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		end
	end)

	--//=================================================================================================================
	--// Timer: Muradin Bronzebeard Event 14 Min 05( End the Event )
	--//=================================================================================================================
	Timers:CreateTimer(845, function() -- 14:05 Min: MURADIN BRONZEBEARD EVENT 1, END
	Notifications:TopToAll({text="All heroes who survived Muradin received 10 000 Gold!", duration=6.0})
	Notifications:TopToAll({ability="alchemist_goblins_greed", continue=true})
	end)

	--//=================================================================================================================
	--// Timer: Muradin Bronzebeard Event 12 Min 30
	--//=================================================================================================================
	Timers:CreateTimer(720, function() -- 12:30 Min: MURADIN BRONZEBEARD EVENT 1
	nCOUNTDOWNTIMER = 121
	local point = Entities:FindByName(nil,"npc_dota_muradin_player"):GetAbsOrigin()
	local MuradinEvent = CreateUnitByName("npc_dota_creature_muradin_bronzebeard", Entities:FindByName(nil, "npc_dota_muradin_boss"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
	local heroes = HeroList:GetAllHeroes()
	local teleporters = Entities:FindAllByName("trigger_teleport_muradin_end")
	local units = FindUnitsInRadius( DOTA_TEAM_BADGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE , FIND_ANY_ORDER, false )
	local units2 = FindUnitsInRadius( DOTA_TEAM_GOODGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE , FIND_ANY_ORDER, false )

	for _,v in pairs(units) do
		
		if v:IsCreature() and v:HasMovementCapability() then
			v:AddNewModifier(nil, nil, "modifier_animation_freeze_stun", {Duration = 135, IsHidden = true})
			v:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 135, IsHidden = true})
		end
	end

	for _,v in pairs(units2) do
		
		if v:IsCreature() and v:HasMovementCapability() then
			v:AddNewModifier(nil, nil, "modifier_animation_freeze_stun", {Duration = 125, IsHidden = true})
			v:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 125, IsHidden = true})
		end
	end

	MuradinEvent:SetAngles(0, 270, 0)
	Notifications:TopToAll({hero="npc_dota_hero_zuus", duration=5.0})
	Notifications:TopToAll({text="You can't kill him! Just survive the Countdown", continue=true})
	Notifications:TopToAll({text="Reward: 10 000 Gold.", continue=true})
	Timers:CreateTimer( 3.0, StartMuradinEvent )
	Timers:CreateTimer( 120, EndMuradinEvent )
		Timers:CreateTimer(120, function() -- 14:30 Min
			MuradinEvent:ForceKill(true)
			for _,v in pairs(teleporters) do
				v:Enable()
			end
		end)

		for _,hero in pairs(heroes) do
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				FindClearSpaceForUnit(hero, point, true)
				hero:EmitSound("Muradin.StormEarthFire")
				Timers:CreateTimer(120, function()
					hero:StopSound("Muradin.StormEarthFire")
				end)
				hero:AddNewModifier(nil, nil, "modifier_animation_freeze_stun",nil)
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
			hero:RemoveModifierByName("modifier_animation_freeze_stun")
			hero:RemoveModifierByName("modifier_invulnerable")
			end
		end
	return nil
end

	XP_PER_LEVEL_TABLE = {
	0,-- 1
	300,-- 2 +300
	600,-- 3 +300
	1000,-- 4 +400
	1500,-- 5 +500
	2100,-- 6 +600
	2900,-- 7 +700
	3900,-- 8 +1000
	5100,-- 9 +1200
	6500,-- 10 +1400
	8300,-- 11 +1800
	10500,-- 12 +2200
	13100,-- 13 +2600
	16100,-- 14 + 3000
	19600,-- 15 + 3500
	23600,-- 16 + 4000
	28100,-- 17 + 4500
	33100,-- 18 + 5000
	38600,-- 19 + 5500
	44600, -- 20 + 6000
	50600, -- 21 + 6000
	56600, -- 22 + 6000
	62600, -- 23 + 6000
	68600, -- 24 + 6000
	74600, -- 25 + 6000
	80600, -- 26 + 6000
	86600, -- 27 + 6000
	92600, -- 28 + 6000
	100600, -- 29 + 6000
	106600 -- 30 + 6000
}

function GameMode:InitGameMode()
	GameMode = self
	mode = GameRules:GetGameModeEntity()
	local difficulty = GameRules:GetCustomGameDifficulty()

	-- Timer Rules
	GameRules:SetPreGameTime( 90.0 )
	GameRules:SetPostGameTime( 60.0 )
	GameRules:SetTreeRegrowTime( 120.0 )
	GameRules:SetRuneSpawnTime( 120.0 )
	GameRules:SetHeroSelectionTime( 0.0 )
	GameRules:SetGoldTickTime( 0.0 )
	GameRules:SetGoldPerTick( 0.0 )

	-- Boolean Rules
	GameRules:SetUseCustomHeroXPValues ( true )
	GameRules:SetUseBaseGoldBountyOnHeroes( true )
	GameRules:SetHeroRespawnEnabled( true )
	mode:SetUseCustomHeroLevels( true )
	mode:SetRecommendedItemsDisabled( true )
	mode:SetTopBarTeamValuesOverride ( true )
	mode:SetTopBarTeamValuesVisible( true )
	mode:SetUnseenFogOfWarEnabled( false )
	mode:SetStashPurchasingDisabled ( true )

	mode:SetBuybackEnabled( false )
	mode:SetBotThinkingEnabled( false )
	mode:SetTowerBackdoorProtectionEnabled( false )
	mode:SetFogOfWarDisabled( true )
	mode:SetGoldSoundDisabled( false )
	mode:SetRemoveIllusionsOnDeath( false )
	mode:SetAlwaysShowPlayerInventory( false )
	mode:SetAnnouncerDisabled( false )
	mode:SetLoseGoldOnDeath( false )

	-- Value Rules
	mode:SetCameraDistanceOverride( 1250 )
	mode:SetMaximumAttackSpeed( 700 )
	mode:SetMinimumAttackSpeed( 20 )
	mode:SetCustomHeroMaxLevel( 30 )
	GameRules:SetHeroMinimapIconScale( 1.25 )
	GameRules:SetCreepMinimapIconScale( 1 )
	GameRules:SetRuneMinimapIconScale( 1 )

	-- Team Rules
	SetTeamCustomHealthbarColor(DOTA_TEAM_GOODGUYS, 52, 52, 190) --Blue
	SetTeamCustomHealthbarColor(DOTA_TEAM_BADGUYS, 190, 52, 52) --Red
	SetTeamCustomHealthbarColor(DOTA_TEAM_CUSTOM_1, 230, 42, 42) --Dark Red

	-- Table Rules
	mode:SetCustomXPRequiredToReachNextLevel( XP_PER_LEVEL_TABLE )

	GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 8 )
	GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 0 )
	GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_1, 0 )
	mode:SetCustomGameForceHero( "npc_dota_hero_wisp" )
	mode:SetFixedRespawnTime( 40 )

--	if difficulty == 1 then
--		mode:SetFixedRespawnTime( 30 )
--	elseif difficulty == 2 then
--		mode:SetFixedRespawnTime( 60 )
--	elseif difficulty == 3 then
--		mode:SetFixedRespawnTime( 90 )
--	elseif difficulty == 4 then
--		mode:SetFixedRespawnTime( 120 )
--	end

	GameMode:_InitGameMode()
	self:OnFirstPlayerLoaded()

	GameRules:GetGameModeEntity():SetThink( "OnThink", self, 1 )

	self.countdownEnabled = false

	Convars:RegisterCommand( "muradin_set_timer", function(...) return SetTimerMuradin( ... ) end, "Set the timer.", FCVAR_CHEAT )
	Convars:RegisterCommand( "creep_set_timer", function(...) return SetTimerCreep( ... ) end, "Set the timer.", FCVAR_CHEAT )
	Convars:RegisterCommand( "wave_set_timer", function(...) return SetTimerIncomingWave( ... ) end, "Set the timer.", FCVAR_CHEAT )
end

function GameMode:OnGameRulesStateChange(keys)
	local heroes = HeroList:GetAllHeroes()

	-- This internal handling is used to set up main barebones functions
	GameMode:_OnGameRulesStateChange(keys)

	local newState = GameRules:State_Get()

	if newState == DOTA_GAMERULES_STATE_HERO_SELECTION then
		GameRules:SetCustomGameDifficulty(2)
		local mode  = GameMode
		local votes = mode.VoteTable

		--[[
		-- Random tables for test purposes
		local testTable = {game_length = {}, combat_system = {}}
		local votes_a = {15, 20, 25, 30}
		local votes_b = {1, 2}
		for i = 0,9 do
		  testTable.game_length[i]  = votes_a[math.random(table.getn(votes_a))]
		  testTable.combat_system[i]  = votes_b[math.random(table.getn(votes_b))]
		end
		votes = testTable   
		]]

		for category, pidVoteTable in pairs(votes) do
	  
		  -- Tally the votes into a new table
			local voteCounts = {}
			for pid, vote in pairs(pidVoteTable) do
				if not voteCounts[vote] then voteCounts[vote] = 0 end
				voteCounts[vote] = voteCounts[vote] + 1
			end

		  --print(" ----- " .. category .. " ----- ")
		  --PrintTable(voteCounts)

		  -- Find the key that has the highest value (key=vote value, value=number of votes)
			local highest_vote = 0
			local highest_key = ""
			for k, v in pairs(voteCounts) do
				if v > highest_vote then
					highest_key = k
					highest_vote = v
				end
			end

			-- Check for a tie by counting how many values have the highest number of votes
			local tieTable = {}
			for k, v in pairs(voteCounts) do
				if v == highest_vote then
					table.insert(tieTable, k)
				end
			end

			-- Resolve a tie by selecting a random value from those with the highest votes
			if table.getn(tieTable) > 1 then
				--print("TIE!")
				highest_key = tieTable[math.random(table.getn(tieTable))]
			end
			-- Act on the winning vote
			if category == "difficulty" then
				GameRules:SetCustomGameDifficulty(highest_key)
			end

			print(category .. ": " .. highest_key)
		end
	end

	if newState == DOTA_GAMERULES_STATE_PRE_GAME then
		self._fPreGameStartTime = GameRules:GetGameTime()
		for _,hero in pairs(heroes) do
			if hero:IsRealHero() then
--				local item1 = CreateItem("item_ankh_of_reincarnation", hero, hero)
--				hero:AddItem(item1)

--				local item2 = CreateItem("item_faerie_fire", hero, hero)
--				hero:AddItem(item2)
			end
		end
		SpawnHeroesBis()

		local diff = {"Easy","Normal","Hard","Extreme"}
		Notifications:TopToAll({text="DIFFICULTY: "..diff[GameRules:GetCustomGameDifficulty()], duration=15.0})
	end

	if newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		nCOUNTDOWNTIMER = 721
		nCOUNTDOWNCREEP = 361
		nCOUNTDOWNINCWAVE = 241
		print( "OnGameRulesStateChange: Game In Progress" )
		self.countdownEnabled = true
		CustomGameEventManager:Send_ServerToAllClients( "show_timer", {} )
	end
end

function GameMode:OnThink()	
	local newState = GameRules:State_Get()

	-- Stop thinking if game is paused
	if GameRules:IsGamePaused() == true then
		return 1
	end

	CountdownTimerMuradin()
	CountdownTimerCreep()
	CountdownTimerIncomingWave()

	if nCOUNTDOWNTIMER == 30 then -- Enable Red Timer before Muradin event
		CustomGameEventManager:Send_ServerToAllClients( "timer_alert", {} )
	elseif nCOUNTDOWNTIMER < 721 and newState == DOTA_GAMERULES_STATE_PRE_GAME then
		nCOUNTDOWNTIMER = 721
	elseif nCOUNTDOWNTIMER < -4 then
		nCOUNTDOWNTIMER = -4
	end

	if nCOUNTDOWNCREEP < 1 then -- Keep timers to 0 before game starts
		nCOUNTDOWNCREEP = 1
	elseif nCOUNTDOWNCREEP < 2 then
		nCOUNTDOWNCREEP = 361
	elseif time_elapsed > 720 and time_elapsed < 870 then
		nCOUNTDOWNCREEP = 1
	elseif time_elapsed > 1950 then
		nCOUNTDOWNCREEP = 1
	end

	if nCOUNTDOWNINCWAVE < 1 then -- Keep timers to 0 before game starts
		nCOUNTDOWNINCWAVE = 1
	elseif nCOUNTDOWNINCWAVE < 2 then
		nCOUNTDOWNINCWAVE = 241
	elseif time_elapsed > 720 and time_elapsed < 870 then
		nCOUNTDOWNINCWAVE = 1
	elseif time_elapsed > 2040 then
		nCOUNTDOWNINCWAVE = 1
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
