local function PublishAllPlayersBattlepassLoaded()
	CustomGameEventManager:Send_ServerToAllClients("all_players_battlepass_loaded", {})
end

local game_register_load_watch_generation = 0

local function RegisterGameAndLoadArmories(trigger_reason)
	-- A Tools match containing bots still needs the complete account-state
	-- snapshot for Supporter Pass XP, tiers and vote power. game-register marks
	-- the row as Tools Mode; both Lua completion and the backend independently
	-- reject every persistent reward for that session.
	api.xhs_bot_session_backend_disabled = false
	api.tools_telemetry_session = false
	print("game-register: starting after " .. tostring(trigger_reason or "player_load_fallback"))
	api:RegisterGame(function(data)
		print("Register game...")
		for k, _ in pairs(data and data.players or {}) do
			local payload = {
				steamid = tostring(k),
				game_id = api:GetApiGameId(),
			}

			api:Request("armory", function(armoryData)
				if api.players[k] then
					api.players[k]["armory"] = armoryData
				end
			end, nil, "POST", payload)
		end

		if CUSTOM_GAME_TYPE == "PLS" then
			api:GenerateGameModeLeaderboard()
		end

		print("ALL PLAYERS LOADED IN!")
		PublishAllPlayersBattlepassLoaded()
	end)
end

local function RegisterGameWhenPlayersLoaded()
	game_register_load_watch_generation = game_register_load_watch_generation + 1
	local generation = game_register_load_watch_generation
	local started_at = Time()
	local fallback_after = 15

	local function TryRegisterAfterPlayerLoad()
		if generation ~= game_register_load_watch_generation then return nil end
		if api.game_register_state == "ready" or api.game_register_state == "pending" then return nil end

		local all_players_loaded = false
		if GameMode ~= nil and type(GameMode.AreAllCustomSetupPlayersLoaded) == "function" then
			local check_ok, loaded = pcall(function()
				return GameMode:AreAllCustomSetupPlayersLoaded()
			end)
			all_players_loaded = check_ok and loaded == true
		end

		local elapsed = math.max(Time() - started_at, 0)
		if all_players_loaded or elapsed >= fallback_after then
			local reason = all_players_loaded and "all human players loaded"
				or ("player-load fallback after " .. tostring(fallback_after) .. "s")
			CustomGameEventManager:Send_ServerToAllClients("all_players_loaded", {
				fallback = all_players_loaded and 0 or 1,
			})
			RegisterGameAndLoadArmories(reason)
			return nil
		end

		return 0.25
	end

	if Timers ~= nil and type(Timers.CreateTimer) == "function" then
		Timers:CreateTimer(0.1, TryRegisterAfterPlayerLoad)
		return
	end

	local game_mode = GameRules ~= nil and GameRules.GetGameModeEntity ~= nil
		and GameRules:GetGameModeEntity() or nil
	if game_mode ~= nil and type(game_mode.SetContextThink) == "function" then
		game_mode:SetContextThink("api_register_after_players_loaded", TryRegisterAfterPlayerLoad, 0.1)
		return
	end

	-- Last-resort bootstrap: RegisterGame has its own SteamID readiness poll.
	RegisterGameAndLoadArmories("scheduler unavailable fallback")
end

ListenToGameEvent('game_rules_state_change', function()
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		api:DetectParties()
		CustomNetTables:SetTableValue("game_options", "game_count", { value = 1 })

		RegisterGameWhenPlayersLoaded()
	elseif GameRules:State_Get() == DOTA_GAMERULES_STATE_PRE_GAME then
		api:InitDonatorTableJS()

		if api.parties then
			CustomNetTables:SetTableValue("game_options", "parties", api.parties)
		end

		Timers:CreateTimer(function()
			api:CheatDetector()

			if GAME_IS_OVER then
				return nil
			end

			return 1.0
		end)
		-- elseif GameRules:State_Get() == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		-- 	if IsInToolsMode() then
		-- 		GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("delay"), function()
		-- 			GameRules:SetGameWinner(2)
		-- 		end, 2.0)
		-- 	end
	end
end, nil)

ListenToGameEvent('dota_item_purchased', function(event)
	-- itemcost, itemname, PlayerID, splitscreenplayer
	local hero = PlayerResource:GetSelectedHeroEntity(event.PlayerID)

	--	if not PlayerResource.ItemTimer then PlayerResource.ItemTimer = {} end

	--	PlayerResource.ItemTimer = Timers:CreateTimer(10.0, CheckIfItemSold(event))
	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("check_item_sold"), function()
		if hero and not hero:IsNull() and IsValidEntity(hero) and hero:HasItemInInventory(event.itemname) then
			PlayerResource:StoreItemBought(event.PlayerID, event.itemname)
		end

		return nil
	end, 11.0)
end, nil)

-- creepy way to check if an item was sold and fully refund
function CheckIfItemSold(event)
	if PlayerResource:GetSelectedHeroEntity(event.PlayerID):HasItemInInventory(event.itemname) then
		PlayerResource:StoreItemBought(event.PlayerID, event.itemname)
	end
end

-- Call custom functions whenever SetGameWinner is being called anywhere
original_SetGameWinner = CDOTAGameRules.SetGameWinner
CDOTAGameRules.SetGameWinner = function(self, iTeamNumber, bSkipRecord)
	GAME_WINNER_TEAM = iTeamNumber

	if bSkipRecord then
		return original_SetGameWinner(self, iTeamNumber)
	end

	if api.end_game_started then
		return
	end
	api.end_game_started = true
	api:CompleteGame()
	-- CompleteGame publishes the final/fallback payload first, then calls this
	-- wrapper with bSkipRecord=true after the nettable had time to replicate.
	return
end
