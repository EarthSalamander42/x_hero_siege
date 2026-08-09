local function PublishAllPlayersBattlepassLoaded()
	CustomGameEventManager:Send_ServerToAllClients("all_players_battlepass_loaded", {})
end

local function RegisterGameAndLoadArmories()
	-- A Tools match containing bots still needs the complete account-state
	-- snapshot for Supporter Pass XP, tiers and vote power. game-register marks
	-- the row as Tools Mode; both Lua completion and the backend independently
	-- reject every persistent reward for that session.
	api.xhs_bot_session_backend_disabled = false
	api.tools_telemetry_session = false
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

local function RegisterGameWithPlayerProfiles()
	-- Register immediately instead of waiting for the mutable bot choice. Only
	-- persistent human SteamIDs enter the request, and later enabling bots does
	-- not change the account snapshot or its read-only use during setup.
	RegisterGameAndLoadArmories()
end

ListenToGameEvent('game_rules_state_change', function()
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		api:DetectParties()
		CustomNetTables:SetTableValue("game_options", "game_count", { value = 1 })

		RegisterGameWithPlayerProfiles()

		CustomGameEventManager:Send_ServerToAllClients("all_players_loaded", {})
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
