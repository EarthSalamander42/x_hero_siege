customSchema = class({})

function customSchema:init()

	-- Check the schema_examples folder for different implementations

	-- Flag Example
	statCollection:setFlags({
		version = X_HERO_SIEGE_V
	})

	-- Listen for changes in the current state
	ListenToGameEvent('game_rules_state_change', function(keys)
		local state = GameRules:State_Get()

		-- Send custom stats when the game ends
		if state == DOTA_GAMERULES_STATE_POST_GAME then

			-- Build game array
			local game = BuildGameArray()

			-- Build players array
			local players = BuildPlayersArray()

			-- Print the schema data to the console
			if statCollection.TESTING then
				PrintSchema(game, players)
			end

			-- Send custom stats
			if statCollection.HAS_SCHEMA then
				statCollection:sendCustom({ game = game, players = players })
			end
		end
	end, nil)

	-- Write 'test_schema' on the console to test your current functions instead of having to end the game
	if Convars:GetBool('developer') then
		Convars:RegisterCommand("test_schema", function() PrintSchema(BuildGameArray(), BuildPlayersArray()) end, "Test the custom schema arrays", 0)
		Convars:RegisterCommand("test_end_game", function() GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS) end, "Test the end game", 0)
	end
end

-------------------------------------

-- In the statcollection/lib/utilities.lua, you'll find many useful functions to build your schema.
-- You are also encouraged to call your custom mod-specific functions

-- Returns a table with our custom game tracking.
function BuildGameArray()
	local game = {}
	local diff = {"Easy", "Normal", "Hard", "Extreme"}
	local lanes = {"Simple", "Double"}
	local dual = {"Normal", "Dual"}

	-- Add game values here as game.someValue = GetSomeGameValue()
	game.df = diff[GameRules:GetCustomGameDifficulty()]	-- Retrieve Difficulty of the mod
	game.la = lanes[CREEP_LANES_TYPE]
	game.dh = dual[DUAL_HERO]

	return game
end

-- Returns a table containing data for every player in the game
function BuildPlayersArray()
	local players = {}
	for playerID = 0, DOTA_MAX_PLAYERS do
		if PlayerResource:IsValidPlayerID(playerID) then
			if not PlayerResource:IsBroadcaster(playerID) then
				if hero:GetUnitName() == "npc_dota_hero_wisp" then return end
				local hero = PlayerResource:GetSelectedHeroEntity(playerID)

				table.insert(players, {
					-- steamID32 required in here
					steamID32 = PlayerResource:GetSteamAccountID(playerID),

					ph = "#"..hero:GetUnitName(), -- Hero by their Pseudos
					pk = hero:GetKills(),       -- Number of kills this hero have

					-- Item list
					i1 = GetItemSlot(hero, 0),
					i2 = GetItemSlot(hero, 1),
					i3 = GetItemSlot(hero, 2),
					i4 = GetItemSlot(hero, 3),
					i5 = GetItemSlot(hero, 4),
					i6 = GetItemSlot(hero, 5),

					s = SECRET

					-- Example functions for generic stats are defined in statcollection/lib/utilities.lua
					-- Add player values here as someValue = GetSomePlayerValue(),
				})
			end
		end
	end

	return players
end

-- Prints the custom schema, required to get an schemaID
function PrintSchema(gameArray, playerArray)
	print("-------- GAME DATA --------")
	DeepPrintTable(gameArray)
	print("\n-------- PLAYER DATA --------")
	DeepPrintTable(playerArray)
	print("-------------------------------------")
end

-------------------------------------

-- If your gamemode is round-based, you can use statCollection:submitRound(bLastRound) at any point of your main game logic code to send a round
-- If you intend to send rounds, make sure your settings.kv has the 'HAS_ROUNDS' set to true. Each round will send the game and player arrays defined earlier
-- The round number is incremented internally, lastRound can be marked to notify that the game ended properly
function customSchema:submitRound()

	local winners = BuildRoundWinnerArray()
	local game = BuildGameArray()
	local players = BuildPlayersArray()

	statCollection:sendCustom({ game = game, players = players })
end

-- A list of players marking who won this round
function BuildRoundWinnerArray()
	local winners = {}
	local current_winner_team = GameRules.Winner or 0 --You'll need to provide your own way of determining which team won the round
	for playerID = 0, DOTA_MAX_PLAYERS do
		if PlayerResource:IsValidPlayerID(playerID) then
			if not PlayerResource:IsBroadcaster(playerID) then
				winners[PlayerResource:GetSteamAccountID(playerID)] = (PlayerResource:GetTeam(playerID) == current_winner_team) and 1 or 0
			end
		end
	end
	return winners
end

-- Schema Created by Firetoad
-- String of item name
function GetItemSlot(hero, slot)
	local item = hero:GetItemInSlot(slot)
	local itemName = "empty"

	if item then
		if string.find(item:GetAbilityName(), "item") then
			itemName = string.gsub(item:GetAbilityName(), "item_", "")
		end
	end

	return itemName
end
