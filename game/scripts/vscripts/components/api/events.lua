local function PublishAllPlayersBattlepassLoaded()
	CustomGameEventManager:Send_ServerToAllClients("all_players_battlepass_loaded", {})
end

local function CompleteApiSetupWithoutBackend(reason)
	-- A Tools bot session is intentionally local-only. It must never create a
	-- game-register row or unlock persistent rewards, but humans still need
	-- their read-only donor identity for loading-screen and in-game visuals.
	api.game_id = nil
	api.players = {}
	api.companions = {}
	api.emblems = {}
	api.effigies = {}
	api.disabled_heroes = {}
	api.supporter_pass = {}
	api.custom_polls = {}
	api.xhs_bot_session_backend_disabled = true

	CustomNetTables:SetTableValue("supporter_pass_player", "companions", {})
	CustomNetTables:SetTableValue("supporter_pass_player", "emblems", {})
	CustomNetTables:SetTableValue("supporter_pass_player", "effigies", {})

	if CustomPolls and CustomPolls.SetBackendPayload then
		CustomPolls:SetBackendPayload({})
	end

	local human_steamids = {}
	for player_id = 0, 23 do
		if api:IsPersistentPlayerID(player_id) then
			local steamid = api:GetPersistentPlayerSteamID(player_id)
			if steamid ~= nil then
				human_steamids[tostring(steamid)] = true
			end
		end
	end

	local completed = false
	local function FinishLocalApiSetup(status_source)
		if completed then return end
		completed = true

		if SupporterPass and SupporterPass.PublishPlayers then
			SupporterPass:PublishPlayers()
		end

		print("game-register: skipped for local XHS bot session ("
			.. tostring(reason or "bot_configured")
			.. "); human donor metadata=" .. tostring(status_source or "unavailable") .. ".")
		PublishAllPlayersBattlepassLoaded()
	end

	local request_ok = pcall(function()
		api:Request("meta/donators", function(data)
			local rows = type(data) == "table" and data.players or nil
			if type(rows) == "table" then
				for key, row in pairs(rows) do
					if type(row) == "table" then
						local steamid = tostring(row.steamid or row.steam_id or key)
						local status = tonumber(row.status or row.donator_status)
						if human_steamids[steamid] == true and status ~= nil then
							api.players[steamid] = {
								status = math.max(0, math.min(10, math.floor(status))),
							}
						end
					end
				end
			end

			FinishLocalApiSetup("loaded")
		end, function()
			FinishLocalApiSetup("unavailable")
		end)
	end)

	if not request_ok then
		FinishLocalApiSetup("unavailable")
	end
end

local function RegisterGameAndLoadArmories()
	api:RegisterGame(function(data)
		print("Register game...")
		for k, _ in pairs(data and data.players or {}) do
			local payload = {
				steamid = tostring(k),
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

local function RegisterOrSkipAfterBotConfiguration()
	-- Production and Tools launches without the private package keep the
	-- original eager registration behavior.
	if not IsInToolsMode() or XHSBots == nil or XHSBots.enabled ~= true then
		RegisterGameAndLoadArmories()
		return
	end

	-- The loading-screen choice is still mutable when CUSTOM_GAME_SETUP first
	-- begins. Wait until XHSBots locks it in BeforeCustomSetupFinish; if an
	-- external launch bypasses that hook, leaving setup is also a terminal
	-- decision point.
	Timers:CreateTimer(0, function()
		local state = GameRules:State_Get()
		local configuration_locked = XHSBots ~= nil and XHSBots.locked == true
		if not configuration_locked and state == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
			return 0.1
		end

		local has_bot_session = api.HasXHSBotSession ~= nil and api:HasXHSBotSession()
		if not has_bot_session and XHSBots ~= nil and type(XHSBots.configuration) == "table" then
			has_bot_session = (tonumber(XHSBots.configuration.count) or 0) > 0
		end

		if has_bot_session then
			CompleteApiSetupWithoutBackend(configuration_locked and "configuration_locked" or "setup_left")
		else
			RegisterGameAndLoadArmories()
		end
		return nil
	end)
end

ListenToGameEvent('game_rules_state_change', function()
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		api:DetectParties()
		CustomNetTables:SetTableValue("game_options", "game_count", { value = 1 })

		RegisterOrSkipAfterBotConfiguration()

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
	-- The Panorama EndScreen must not depend on the backend response time.
	return original_SetGameWinner(self, iTeamNumber)
end
