local statInfo = LoadKeyValues('scripts/vscripts/internal/auth.kv')

local _AuthCode = statInfo._auth --The auth code for game and http server

local table_PlayerID = {}
local table_SteamID64 = {}
local table_player_key = {}
local table_able = {}
local table_XP_has = {}
local table_XP = {}

-- Diretide values
local table_XHS_lvl = {}
local table_XHS_pk = {} -- Player Kills (player_kills, difficulty, lane_type)
table_XHS_pk[0] = {0, 2, 1}
table_XHS_pk[1] = {0, 2, 1}
table_XHS_pk[2] = {0, 2, 1}
table_XHS_pk[3] = {0, 2, 1}
table_XHS_pk[4] = {0, 2, 1}
table_XHS_pk[5] = {0, 2, 1}
table_XHS_pk[6] = {0, 2, 1}
table_XHS_pk[7] = {0, 2, 1}

local table_XHS_gt = {} -- Game Time
local table_XHS_ph = {} -- Player Hero
local table_XHS_gd = {} -- Game Difficulty
local table_XHS_lt = {} -- Lane Type

local SteamID64
local player_key
local XP_has
local XHS_lvl_has
local XHS_pk_has
local XHS_gt_has
local XHS_ph_has
local XHS_gd_has
local XHS_lt_has

local EnnDisEnabled = 0

XP_WIN = 25
XP_LOSE = 0
XP_ABANDON = 0

--Level table for X Hero Siege XP
local table_rankXP = {100,200,300,400,500,700,900,1100,1300,1500,1800,2100,2400,2700,3000,3400,3800,4200,4600,5000}
--------------------  0  1   2   3   4   5   6   7    8    9   10   11   12   13   14   15   16   17   18   19   20

CustomNetTables:SetTableValue("game_options", "game_count", {value = 0})

local bonus = 0
for i = 21, 200 do
	bonus = bonus +125

	table_rankXP[i] = table_rankXP[i-1] + bonus
end

local XP_level_title = {}
local XP_level = {}
local XP_level_title_player = {}
local XP_need_to_next_level = {}
local XP_this_level = {}
local XP_has_this_level = {}

function Server_DecodeForPlayer( t, nPlayerID )   --To deep-decode the Json code...
	print("SERVER: Decode for Player..")
	local print_r_cache={}
	local function sub_print_r(t,indent)
		if (print_r_cache[tostring(t)]) then
			--print(indent.."*"..tostring(t))
		else
			print_r_cache[tostring(t)]=true
			if (type(t)=="table") then
				for pos,val in pairs(t) do
					if (type(val)=="table") then
						sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
					elseif (type(val)=="string") then
						if pos == "SteamID64" then
							SteamID64 = val
							--print("SteamID64="..SteamID64)
						end

						if pos == "player_key" then
							player_key = val
							table_player_key[nPlayerID] = tostring(player_key)
							--print("player_key="..table_player_key[nPlayerID])
						end

						if pos == "XP_has" then
							XP_has = val
							if tonumber(XP_has) < 0 then
								table_XP_has[nPlayerID] = 0
							else
								table_XP_has[nPlayerID] = tostring(XP_has)
							end
							table_XP_has[nPlayerID] = tostring(XP_has)
							--print("XP_has="..table_XP_has[nPlayerID])
						end

						if pos == "XHS_PlayerKills" then
							XHS_pk_has = val
							table_XHS_pk[nPlayerID] = tonumber(XHS_pk_has)
						end

						if pos == "XHS_GameTime" then
							XHS_gt_has = val
							table_XHS_gt[nPlayerID] = XHS_gt_has
						end

						if pos == "XHS_PlayerHero" then
							XHS_ph_has = val
							table_XHS_ph[nPlayerID] = XHS_ph_has
						end

						if pos == "XHS_GameDifficulty" then
							XHS_ph_has = val
							table_XHS_ph[nPlayerID] = XHS_ph_has
						end

						if pos == "XHS_LaneType" then
							XHS_ph_has = val
							table_XHS_ph[nPlayerID] = XHS_ph_has
						end

						for i = 1, 4 do
							if pos == "XHS_GameDifficulty"..i then

							end
						end

						table_able[nPlayerID] = tostring(0)
					end
				end
			end
		end
	end
	if (type(t)=="table") then
		sub_print_r(t,"  ")
	end
end

function Server_GetPlayerLevelAndTitle(nPlayerID)
	for i = #table_rankXP, 1 do
		if table_XP_has and table_XP_has[nPlayerID] and table_rankXP and table_rankXP[i] then
			if tonumber(table_XP_has[nPlayerID]) >= table_rankXP[i] then
				if tonumber(table_XP_has[nPlayerID]) < 0 then
					print("What did you do! Negative value!")
				end

				print("Level:", i)
				XP_level[nPlayerID] = i
				XP_level_title_player[nPlayerID] = Server_GetTitle(XP_level[nPlayerID])
				XP_this_level[nPlayerID] = table_rankXP[i]

				if i == #table_rankXP then
					XP_need_to_next_level[nPlayerID] = 0
				else
					XP_need_to_next_level[nPlayerID] = table_rankXP[i+1] - tonumber(table_XP_has[nPlayerID])
				end
				
				XP_has_this_level[nPlayerID] = tonumber(table_XP_has[nPlayerID]) - table_rankXP[i]

				--[[ Show up xp and record on HUD
				CustomNetTables:SetTableValue("player_table", tostring(nPlayerID), {
					XP = tonumber(XP_has_this_level[nPlayerID]),
					MaxXP = tonumber(XP_need_to_next_level[nPlayerID] + XP_has_this_level[nPlayerID]),
					Lvl = tonumber(XP_level[nPlayerID]),
					XHS_Lvl = tonumber(table_XHS_lvl[nPlayerID]),
					XHS_PK = tonumber(table_XHS_pk[nPlayerID]),
					XHS_GT = table_XHS_gt[nPlayerID],
					XHS_PH = table_XHS_ph[nPlayerID],
					ID = nPlayerID,
					title = XP_level_title_player[nPlayerID],
					title_color = Server_GetTitleColor(XP_level_title_player[nPlayerID], true)}
				)
				break --]]
			end
		end
	end
end

local _finished = 0
local is_AFK = {}

function Server_SendAndGetInfoForAll()
	if _finished == 0 then
		require('libraries/json')		

		for nPlayerID = 0, PlayerResource:GetPlayerCount() -1 do
			Server_SendAndGetInfoForAll_function(nPlayerID)
		end
		_finished = 1
	end
end

function Server_SendAndGetInfoForAll_function(nPlayerID)
	if PlayerResource:IsValidPlayer(nPlayerID) and not PlayerResource:IsFakeClient(nPlayerID) then
		table_SteamID64[nPlayerID] = tostring(PlayerResource:GetSteamID(nPlayerID))
		table_XP[nPlayerID] = tostring(XP_WIN) --How many XP will player get in this game
		local jsondata={}
		local jsontable={}
		jsontable.SteamID64 = table_SteamID64[nPlayerID]
		jsontable.XP = table_XP[nPlayerID]

		table.insert(jsondata,jsontable)
			local request = CreateHTTPRequestScriptVM( "GET", "http://www.dota2imba.cn/xhs/XP_game_to_tmp.php" )
			request:SetHTTPRequestGetOrPostParameter("data_json",JSON:encode(jsondata))
			request:SetHTTPRequestGetOrPostParameter("auth",_AuthCode)
			request:Send(function(result)

			if result.StatusCode == 200 then
				Adecode=JSON:decode(result.Body)
				Server_DecodeForPlayer(Adecode, nPlayerID)
				Server_GetPlayerLevelAndTitle(nPlayerID)
			end

			if result.StatusCode ~= 200 then
				Server_SendAndGetInfoForAll_function(nPlayerID)
				return
			end
		end)
		is_AFK[nPlayerID] = 0
	end
end

function Server_EnableToGainXPForPlyaer(nPlayerID)
	if EnnDisEnabled == 1 and is_AFK[nPlayerID] == 0 then
		table_able[nPlayerID] = 1
		Server_AbilityToGainXPForPlyaer_function(nPlayerID)
	end
end

function Server_DisableToGainXpForPlayer(nPlayerID)
	if EnnDisEnabled == 1 then
		table_able[nPlayerID] = 0
		Server_AbilityToGainXPForPlyaer_function(nPlayerID)
	end
end

function Server_AbilityToGainXPForPlyaer_function(nPlayerID)
	local jsondata={}
	local jsontable={}
	jsontable.player_key = table_player_key[nPlayerID]
	jsontable._able = table_able[nPlayerID]
	jsontable.SteamID64 = table_SteamID64[nPlayerID]
	table.insert(jsondata,jsontable)
	local request = CreateHTTPRequestScriptVM( "GET", "http://www.dota2imba.cn/xhs/XP_ability_to_gain.php" )
		request:SetHTTPRequestGetOrPostParameter("data_json",JSON:encode(jsondata))
		request:SetHTTPRequestGetOrPostParameter("auth",_AuthCode)
		request:Send(function(result)
		if result.StatusCode ~= 200 then
			Server_AbilityToGainXPForPlyaer_function(nPlayerID)
			return
		end
	end )
end

-- GetConnectionState values:
-- 0 - no connection
-- 1 - bot connected
-- 2 - player connected
-- 3 - bot/player disconnected.

function Server_WaitToEnableXpGain()
	Serer_CheckForAFKPlayer()
	EnnDisEnabled = 1

	if CHEAT_ENABLED == true then
		print("Game don't count.")
		return
	else
		CustomNetTables:SetTableValue("game_options", "game_count", {value = 1})
	end

	--print("Enable Xp gain system....")
	for nPlayerID = 0, PlayerResource:GetPlayerCount() -1 do
		if PlayerResource:IsValidPlayer(nPlayerID) and not PlayerResource:IsFakeClient(nPlayerID) then
			-- Determain if this guy could gain XP
			if PlayerResource:GetConnectionState(nPlayerID) == 2 then
				table_able[nPlayerID] = 1
				Server_EnableToGainXPForPlyaer(nPlayerID)
			end

			if PlayerResource:GetConnectionState(nPlayerID) == 3 then
				table_able[nPlayerID] = 0
				Server_DisableToGainXpForPlayer(nPlayerID)
			end
		end
	end
end

function Server_CalculateXPForWinnerAndAll(winning_team)
if CHEAT_ENABLED == true then return end
if EnnDisEnabled ~= 1 then return end
local Winner
local dis_player = 0

	for nPlayerID = 0, PlayerResource:GetPlayerCount() -1 do
		if  PlayerResource:IsValidPlayer(nPlayerID) and not PlayerResource:IsFakeClient(nPlayerID) and PlayerResource:GetConnectionState(nPlayerID) ~= 2 then
			dis_player = dis_player + 1
		end

		if PlayerResource:IsValidPlayer(nPlayerID) and not PlayerResource:IsFakeClient(nPlayerID) then
			if winning_team == "Radiant" then Winner = DOTA_TEAM_GOODGUYS end
			if winning_team == "Dire" then Winner = DOTA_TEAM_BADGUYS end

			local jsondata={}
			local jsontable={}
			jsontable.SteamID64 = table_SteamID64[nPlayerID]
			jsontable.XP = table_XP[nPlayerID]			

			print("SERVER XP: Testing XP earned...")
			local xp_modify
			if PlayerResource:GetTeam(nPlayerID) == Winner and PlayerResource:GetConnectionState(nPlayerID) == 2 then
				xp_modify = table_XP[nPlayerID]
			else
				if PlayerResource:GetConnectionState(nPlayerID) ~= 2 then -- ABANDON
					xp_modify = XP_ABANDON
				else -- LOSE
					xp_modify = XP_LOSE
				end
			end

			-- Modify XP (JSON)
			jsontable.XP = tostring(math.ceil(xp_modify)) -- WIN

			-- Modify XP (HUD End Game)
 --[[		CustomNetTables:SetTableValue("player_table", tostring(nPlayerID), {
				XP = tonumber(XP_has_this_level[nPlayerID]),
				MaxXP = tonumber(XP_need_to_next_level[nPlayerID] + XP_has_this_level[nPlayerID]),
				Lvl = tonumber(XP_level[nPlayerID]),
				ID = nPlayerID,
				title = XP_level_title_player[nPlayerID],
				XP_change = tonumber(math.ceil(xp_modify)),
				title_color = Server_GetTitleColor(XP_level_title_player[nPlayerID], true)
			}) --]]

			-- Score override conditions
--			if PlayerResource:GetKills(nPlayerID) > table_XHS_lvl[nPlayerID] then
--				table_XHS_pk[nPlayerID] = PlayerResource:GetKills(nPlayerID)
--				table_XHS_gt[nPlayerID] = GameRules:GetDOTATime(false, false)
--				table_XHS_ph[nPlayerID] = PlayerResource:GetPlayer(nPlayerID):GetAssignedHero():GetUnitName()
--				print("New record!")
--				print("Player Kills:", PlayerResource:GetKills(nPlayerID))
--				print("Game Time:", GameRules:GetDOTATime(false, false))
--				print("Player Hero:", PlayerResource:GetPlayer(nPlayerID):GetAssignedHero():GetUnitName())
--			end

--			jsontable.player_key = table_player_key[nPlayerID]
--			jsontable.XHS_PlayerKills = table_XHS_lvl[nPlayerID]
--			jsontable.XHS_GameTime = table_XHS_gt[nPlayerID]
--			jsontable.XHS_PlayerHero = table_XHS_ph[nPlayerID]
--			jsontable.XHS_GameDifficulty = table_XHS_gd[nPlayerID]
--			jsontable.XHS_LaneType = table_XHS_lt[nPlayerID]
			table.insert(jsondata,jsontable)
			Server_SendEndGameInfo(jsondata)
		end
	end
end

function Server_SendEndGameInfo(json)
	local request = CreateHTTPRequestScriptVM( "GET", "http://www.dota2imba.cn/xhs/XP_game_end_tmp_to_perm.php" )

	request:SetHTTPRequestGetOrPostParameter("data_json",JSON:encode(json))
	request:SetHTTPRequestGetOrPostParameter("auth",_AuthCode);
	request:Send(function(result)
		if result.StatusCode ~= 200 then
			Server_SendEndGameInfo(json)
			return
		end
	end)
end

local table_AFK_check_allHeroes = {}
local cycle_AFK_check_interval = 60
local AFK_check_times = 5
local _maxLv = 25

local table_AFK_exp_round =  {}
local cycle_AFK_exp_round = 1
local cycle_AFK_exp_max_round = AFK_check_times

function Serer_CheckForAFKPlayer()
	for i=1,cycle_AFK_exp_max_round do
		table_AFK_exp_round[i] = {}
	end

	Timers:CreateTimer(function()
			for nPlayerID = 0, PlayerResource:GetPlayerCount() -1 do
				if PlayerResource:IsValidPlayer(nPlayerID) and not PlayerResource:IsFakeClient(nPlayerID) then

					table_AFK_check_allHeroes[nPlayerID]=PlayerResource:GetSelectedHeroEntity(nPlayerID)   
					if PlayerResource:GetLevel(nPlayerID) ~= _maxLv then
						table_AFK_exp_round[cycle_AFK_exp_round][nPlayerID]=CDOTA_BaseNPC_Hero.GetCurrentXP(table_AFK_check_allHeroes[nPlayerID])
						if cycle_AFK_exp_round == cycle_AFK_exp_max_round then
							cycle_AFK_exp_round = 1
						else
							cycle_AFK_exp_round = cycle_AFK_exp_round + 1
						end
						local _AFK_check_pass = 0
						for i=1,cycle_AFK_exp_max_round-1 do
							if table_AFK_exp_round[i][nPlayerID] == table_AFK_exp_round[i+1][nPlayerID] then
								_AFK_check_pass = _AFK_check_pass +1
							end
						end
						if _AFK_check_pass == cycle_AFK_exp_max_round-1 then
							is_AFK[nPlayerID] = 1
							Server_DisableToGainXpForPlayer(nPlayerID)
						end
					end

					local idle_change_time = CDOTA_BaseNPC.GetLastIdleChangeTime(table_AFK_check_allHeroes[nPlayerID])
					local current_game_time = GameRules:GetGameTime()

					if current_game_time-idle_change_time > AFK_check_times * cycle_AFK_check_interval then --AFK_check_times * cycle_AFK_check_interval
						is_AFK[nPlayerID] = 1
						Server_DisableToGainXpForPlayer(nPlayerID)
					end

				end
			end
	return cycle_AFK_check_interval --cycle_AFK_check_interval
	end)
end

----------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------
----------------------------------------------Useful Functions-----------------------------------------------------
----------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------

function Server_GetPlayerLevel(playerID)
	if CustomNetTables:GetTableValue("player_table", tostring(playerID)) then
		return CustomNetTables:GetTableValue("player_table", tostring(playerID)).Lvl
	end
end

function Server_GetPlayerXP(playerID)
	if CustomNetTables:GetTableValue("player_table", tostring(playerID)) then
		return CustomNetTables:GetTableValue("player_table", tostring(playerID)).XP
	end
end

function Server_GetPlayerTitle(playerID)
	if CustomNetTables:GetTableValue("player_table", tostring(playerID)) then
		return CustomNetTables:GetTableValue("player_table", tostring(playerID)).title
	end
end

function Server_GetPlayerXHS_Lvl(playerID)
	if CustomNetTables:GetTableValue("player_table", tostring(playerID)) then
		return CustomNetTables:GetTableValue("player_table", tostring(playerID)).XHS_Lvl
	end
end

function print_r ( t )  
	local print_r_cache={}
	local function sub_print_r(t,indent)
		if (print_r_cache[tostring(t)]) then
			print(indent.."*"..tostring(t))
		else
			print_r_cache[tostring(t)]=true
			if (type(t)=="table") then
				for pos,val in pairs(t) do
					if (type(val)=="table") then
						print(indent.."["..pos.."] => "..tostring(t).." {")
						sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
						print(indent..string.rep(" ",string.len(pos)+6).."}")
					elseif (type(val)=="string") then
						print(indent.."["..pos..'] => "'..val..'"')
					else
						print(indent.."["..pos.."] => "..tostring(val))
					end
				end
			else
				print(indent..tostring(t))
			end
		end
	end
	if (type(t)=="table") then
		print(tostring(t).." {")
		sub_print_r(t,"  ")
		print("}")
	else
		sub_print_r(t,"  ")
	end
	print()
end

-------------------------
----UTILITY FUNCTIONS----
-------------------------

function Server_findHeroByPlayerID(nPlayerID)
	local _Hero = PlayerResource:GetSelectedHeroEntity(nPlayerID)
	return _Hero
end

local Table_Hero_Particle = {}

function Server_DestroyParticle(_particle)
	ParticleManager:DestroyParticle(_particle, true)
	ParticleManager:ReleaseParticleIndex(_particle)
	_particle = nil
end

function Server_Particle(nPlayerID)
	if Table_Hero_Particle[nPlayerID] then
		Server_DestroyParticle(Table_Hero_Particle[nPlayerID])
	end
	local hero = Server_findHeroByPlayerID(nPlayerID)
	local particle = ""

	if XP_level_title_player[nPlayerID] == "Rookie" then -- White
		particle = "particles/econ/courier/courier_platinum_roshan/platinum_roshan_ambient.vpcf"
	elseif XP_level_title_player[nPlayerID] == "Amateur" then -- Light Green
		particle = "particles/econ/courier/courier_greevil_green/courier_greevil_green_ambient_3.vpcf"
	elseif XP_level_title_player[nPlayerID] == "Captain" then -- DodgerBlue
		particle = "particles/econ/courier/courier_roshan_frost/courier_roshan_frost_ambient.vpcf"
	elseif XP_level_title_player[nPlayerID] == "Warrior" then -- Blue
		particle = "particles/econ/courier/courier_greevil_blue/courier_greevil_blue_ambient_3.vpcf"
	elseif XP_level_title_player[nPlayerID] == "Commander" then -- Purple
		particle = "particles/econ/courier/courier_greevil_purple/courier_greevil_purple_ambient_3.vpcf"
	elseif XP_level_title_player[nPlayerID] == "General" then -- DarkPurple
		particle = "particles/econ/courier/courier_roshan_darkmoon/courier_roshan_darkmoon.vpcf"
	elseif XP_level_title_player[nPlayerID] == "Master" then -- LightRed
		particle = "particles/econ/courier/courier_greevil_orange/courier_greevil_orange_ambient_3.vpcf"
	elseif XP_level_title_player[nPlayerID] == "Epic" then -- DarkRed
		particle = "particles/econ/courier/courier_roshan_lava/courier_roshan_lava.vpcf"
	elseif XP_level_title_player[nPlayerID] == "Legendary" then -- Gold
		particle = "particles/econ/courier/courier_roshan_desert_sands/baby_roshan_desert_sands_ambient.vpcf"
	elseif XP_level_title_player[nPlayerID] == "Icefrog" then -- DarkBlue
		particle = "particles/econ/courier/courier_crystal_rift/courier_ambient_crystal_rift.vpcf"
	elseif XP_level_title_player[nPlayerID] == "Firetoad" then -- DarkOrange
		particle = "particles/econ/courier/courier_greevil_red/courier_greevil_red_ambient_3.vpcf"
	end
	local _particle = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN_FOLLOW, hero)
	Table_Hero_Particle[nPlayerID] = _particle
	ParticleManager:SetParticleControlEnt(_particle, 0, hero, PATTACH_ABSORIGIN_FOLLOW, "follow_origin", hero:GetAbsOrigin(), true)
end

function Server_GetTopPlayer(ranking)  -- If you want to get the 2nd-top player, then use Server_GetTopPlayer(2)
	local jsondata = {}
	local jsontable = {}
	jsontable.Ranking = ranking
	table.insert(jsondata,jsontable)

	local request = CreateHTTPRequestScriptVM( "GET", "http://www.dota2imba.cn/xhs/XP_top.php" )

	request:SetHTTPRequestGetOrPostParameter("data_json",JSON:encode(jsondata))
	request:SetHTTPRequestGetOrPostParameter("auth",_AuthCode);
	request:Send(function(result)
		if result.StatusCode ~= 200 then
			Server_GetTopPlayer(ranking)
			return
		else
			local Adecode=JSON:decode(result.Body)
--			print("Result:", result.Body)
			Server_RankDecode(Adecode)
		end
	end)
end
--[[
leaderboard_SteamID = {}
leaderboard_RoshanLvl = {}
leaderboard_RoshanHP = {}
leaderboard_GameTime = {}
leaderboard_PlayerHero = {}

function Server_RankDecode( t )
	local print_r_cache={}
	local function sub_print_r(t,indent)
		if (print_r_cache[tostring(t)]) then
			--print(indent.."*"..tostring(t))
		else
			print_r_cache[tostring(t)]=true
			if (type(t)=="table") then
				for pos,val in pairs(t) do
					print(pos)
					print(val)
					if (type(val)=="table") then
						sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
--						for k, v in pairs(val) do
--							print(k)
--							print(v)
--						end
					elseif (type(val)=="string") then
						print(val)
						if pos == "SteamID64" then
--							print("Steam ID:", val)
							table.insert(leaderboard_SteamID, val)
						end
						if pos == "XHS_RoshanLvl" then
--							print("Roshan Level:", val)
							table.insert(leaderboard_RoshanLvl, val)
						end
						if pos == "XHS_RoshanHP" then
--							print("Roshan HP:", val)
							table.insert(leaderboard_RoshanHP, val)
						end
						if pos == "XHS_GameTime" then
--							print("Roshan HP:", val)
							table.insert(leaderboard_GameTime, val)
						end
						if pos == "XHS_PlayerHero" then
--							print("Roshan HP:", val)
							table.insert(leaderboard_PlayerHero, val)
						end
					end
				end
			end
		end
	end

	if (type(t)=="table") then
		sub_print_r(t,"  ")
	end

	a = {}
	for k, n in pairs(leaderboard_SteamID) do
		table.insert(a, n)
		leaderboard_SteamID = {}
	end
	table.sort(a)
	for i,n in ipairs(a) do
		table.insert(leaderboard_SteamID, n)
	end

	a = {}
	for k, n in pairs(leaderboard_RoshanLvl) do
		table.insert(a, n)
		leaderboard_RoshanLvl = {}
	end
	table.sort(a)
	for i,n in ipairs(a) do
		table.insert(leaderboard_RoshanLvl, n)
	end

	a = {}
	for k, n in pairs(leaderboard_RoshanHP) do
		table.insert(a, n)
		leaderboard_RoshanHP = {}
	end
	table.sort(a)
	for i,n in ipairs(a) do
		table.insert(leaderboard_RoshanHP, n)
	end

	a = {}
	for k, n in pairs(leaderboard_GameTime) do
		table.insert(a, n)
		leaderboard_GameTime = {}
	end
	table.sort(a)
	for i,n in ipairs(a) do
		table.insert(leaderboard_GameTime, n)
	end

	a = {}
	for k, n in pairs(leaderboard_PlayerHero) do
		table.insert(a, n)
		leaderboard_PlayerHero = {}
	end
	table.sort(a)
	for i,n in ipairs(a) do
		table.insert(leaderboard_PlayerHero, n)
	end

	CustomNetTables:SetTableValue("game_options", "leaderboard", {
		SteamID64 = leaderboard_SteamID,
		RoshanLvl = leaderboard_RoshanLvl,
		RoshanHP = leaderboard_RoshanHP,
		GameTime = leaderboard_GameTime,
		PlayerHero = leaderboard_PlayerHero,
	})
end
--]]
function Server_ClearScore(nPlayerID)
	print("Removed X Hero Siege records for "..PlayerResource:GetPlayer(nPlayerID):GetAssignedHero():GetUnitName())

	local jsondata={}
	local jsontable={}
	jsontable.SteamID64 = table_SteamID64[nPlayerID]
	jsontable.XHS_PlayerKills = "0"
	jsontable.XHS_GameTime = "0"
	jsontable.XHS_PlayerHero = "nil"
	table.insert(jsondata,jsontable)
	Server_SendEndGameInfo(jsondata)
	DiretideEnd()
end

function Server_PrintInfo()
	for nPlayerID = 0, PlayerResource:GetPlayerCount() -1 do
		if  PlayerResource:IsValidPlayer(nPlayerID) then
			if PlayerResource:IsFakeClient(nPlayerID) then
			else
				print("=============================")
				print("PlayerID:"..nPlayerID)
				print("SteamID64:"..table_SteamID64[nPlayerID])
--				print("Level:"..XP_level[nPlayerID]) -- ERROR
--				print("Rank_title:"..XP_level_title_player[nPlayerID]) -- ERROR
--				print("XP this level need:"..XP_this_level[nPlayerID]) -- ERROR
--				print("XP has in this level:"..XP_has_this_level[nPlayerID]) -- ERROR
--				print("XP need to level up:"..XP_need_to_next_level[nPlayerID]) -- ERROR
				print("player_key:"..table_player_key[nPlayerID])
				print("If able to get XP:"..table_able[nPlayerID])
				print("XP has:"..table_XP_has[nPlayerID])
				print("XP to get this game:"..table_XP[nPlayerID])
				print("Team(2 is Radiant, 3 is Dire):"..PlayerResource:GetTeam(nPlayerID))
				print("=============================")
			end
		end
	end
end

function Server_GetTitle(level)
	if level <= 9 then
		return "Rookie"
	elseif level <= 19 then
		return "Amateur"
	elseif level <= 29 then
		return "Captain"
	elseif level <= 39 then
		return "Warrior"
	elseif level <= 49 then
		return "Commander"
	elseif level <= 59 then
		return "General"
	elseif level <= 69 then
		return "Master"
	elseif level <= 79 then
		return "Epic"
	elseif level <= 89 then
		return "Legendary"
	elseif level <= 99 then
		return "Icefrog"
	else 
		return "EmberCookies "..level-100
	end
end

function Server_GetTitleColor(title, js)
	if js == true then
		if title == "Rookie" then
			return "#FFFFFF"
		elseif title == "Amateur" then
			return "#66CC00"
		elseif title == "Captain" then
			return "#4C8BCA"
		elseif title == "Warrior" then
			return "#004C99"
		elseif title == "Commander" then
			return "#985FD1"
		elseif title == "General" then
			return "#460587"
		elseif title == "Master" then
			return "#FA5353"
		elseif title == "Epic" then
			return "#8E0C0C"
		elseif title == "Legendary" then
			return "#EFBC14"
		elseif title == "Icefrog" then
			return "#001932"
		else -- it's Firetoaaaaaaaaaaad! 
			return "#C75102"
		end
	else
		if title == "Rookie" then
			return {255, 255, 255}
		elseif title == "Amateur" then
			return {102, 204, 0}
		elseif title == "Captain" then
			return {76, 139, 202}
		elseif title == "Warrior" then
			return {0, 76, 153}
		elseif title == "Commander" then
			return {152, 95, 209}
		elseif title == "General" then
			return {70, 5, 135}
		elseif title == "Master" then
			return {250, 83, 83}
		elseif title == "Epic" then
			return {142, 12, 12}
		elseif title == "Legendary" then
			return {239, 188, 20}
		elseif title == "Icefrog" then
			return {0, 25, 50}
		else -- it's Firetoaaaaaaaaaaad! 
			return {199, 81, 2}
		end
	end
end