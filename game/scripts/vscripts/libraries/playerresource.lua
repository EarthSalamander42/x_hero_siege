CDOTA_PlayerResource.PlayerData = {}

--[[ Extension functions for PlayerResource
-PlayerResource:GetAllTeamPlayerIDs()
	Returns an iterator for all the player IDs assigned to a valid team (radiant, dire, or custom)
-PlayerResource:GetConnectedTeamPlayerIDs()
	Returns an iterator for all connected, non-spectator player IDs
-PlayerResource:GetPlayerIDsForTeam(int team)
	Returns an iterator for all player IDs in the given team
-PlayerResource:GetConnectedPlayerIDsForTeam(int team)
	Returns an iterator for all connected player IDs in the given team
-PlayerResource:RandomHeroForPlayersWithoutHero()
	Forcibly randoms a hero for any player that has not yet picked a hero
-PlayerResource:IsBotOrPlayerConnected(int id)
	Returns true if the given player ID is a connected bot or player
]]

local function IsSupportItem(bItemName)
	if bItemName == "item_smoke_of_deceit" or bItemName == "item_ward_observer" or bItemName == "item_ward_sentry" or bItemName == "item_imba_dust_of_appearance" or bItemName == "item_imba_gem" or bItemName == "item_imba_soul_of_truth" then
		return true
	end

	return false
end

function CDOTA_PlayerResource:GetAllTeamPlayerIDs()
	return filter(partial(self.IsValidPlayerID, self), range(0, self:GetPlayerCount()))
end

function CDOTA_PlayerResource:GetConnectedTeamPlayerIDs()
	return filter(partial(self.IsBotOrPlayerConnected, self), self:GetAllTeamPlayerIDs())
end

function CDOTA_PlayerResource:GetPlayerIDsForTeam(team)
	return filter(function(id) return self:GetTeam(id) == team end, range(0, self:GetPlayerCount()))
end

function CDOTA_PlayerResource:GetConnectedTeamPlayerIDsForTeam(team)
	return filter(partial(self.IsBotOrPlayerConnected, self), self:GetPlayerIDsForTeam(team))
end

function CDOTA_PlayerResource:RandomHeroForPlayersWithoutHero()
	function HasNotSelectedHero(playerID)
		return not self:HasSelectedHero(playerID)
	end
	function ForceRandomHero(playerID)
		self:GetPlayer(playerID):MakeRandomHeroSelection()
	end
	local playerIDsWithoutHero = filter(HasNotSelectedHero, self:GetConnectedTeamPlayerIDs())
	foreach(ForceRandomHero, playerIDsWithoutHero)
end

function CDOTA_PlayerResource:IsBotOrPlayerConnected(id)
	local connectionState = self:GetConnectionState(id)
	return connectionState == 2 or connectionState == 1
end

-- Initializes a player's data
ListenToGameEvent('npc_spawned', function(event)
	local npc = EntIndexToHScript(event.entindex)

	if npc.GetPlayerID and npc:GetPlayerID() >= 0 and not PlayerResource.PlayerData[npc:GetPlayerID()] then
		PlayerResource.PlayerData[npc:GetPlayerID()] = {}
		PlayerResource.PlayerData[npc:GetPlayerID()]["current_deathstreak"] = 0
		PlayerResource.PlayerData[npc:GetPlayerID()]["has_abandoned_due_to_long_disconnect"] = false
--		PlayerResource.PlayerData[npc:GetPlayerID()]["distribute_gold_to_allies"] = false -- not used atm
--		PlayerResource.PlayerData[npc:GetPlayerID()]["has_repicked"] = false -- not used atm
		PlayerResource.PlayerData[npc:GetPlayerID()]["items_bought"] = {}
		PlayerResource.PlayerData[npc:GetPlayerID()]["abilities_level_up_order"] = {}
--		print("player data set up for player with ID "..npc:GetPlayerID())
	end
end, nil)

function CDOTA_PlayerResource:StoreAbilitiesLevelUpOrder(player_id, ability_name)
	if self:IsImbaPlayer(player_id) then
		local i = #self.PlayerData[player_id]["abilities_level_up_order"] + 1

		-- shitty but doing the job
		if i == 17 or i == 19 then
			table.insert(self.PlayerData[player_id]["abilities_level_up_order"], "generic_hidden")
		elseif i == 21 then
			for i = 1, 4 do
				table.insert(self.PlayerData[player_id]["abilities_level_up_order"], "generic_hidden")
			end
		end

		table.insert(self.PlayerData[player_id]["abilities_level_up_order"], ability_name)
	end

--	print("Abilities stored:", self.PlayerData[player_id]["abilities_level_up_order"])
end

function CDOTA_PlayerResource:GetAbilitiesLevelUpOrder(player_id)
	if self:IsImbaPlayer(player_id) then
		return self.PlayerData[player_id]["abilities_level_up_order"]
	end

	return {}
end

-- todo: handle sell item shouldn't be stored
function CDOTA_PlayerResource:StoreItemBought(player_id, item_name)
	if self:IsImbaPlayer(player_id) then
		local item_info = {}
		item_info.game_time = GameRules:GetDOTATime(false, false)
		item_info.item_name = item_name

		table.insert(self.PlayerData[player_id]["items_bought"], item_info)
	end
end

function CDOTA_PlayerResource:GetItemsBought(player_id)
	if self:IsImbaPlayer(player_id) then
		return self.PlayerData[player_id]["items_bought"]
	end

	return {}
end

function CDOTA_PlayerResource:GetSupportItemsBought(player_id, items)
	local support_items_table = {}

	if self:IsImbaPlayer(player_id) then
		for i = 1, #items do
			local item_name = items[i].item_name

			if IsSupportItem(item_name) then
				local is_in_table = false

				for k, v in pairs(support_items_table) do
--					print(item_name, v.item_name, v.item_count)
					if item_name == v.item_name then
						v.item_count = v.item_count + 1
						is_in_table = true
						break
					end
				end

				if is_in_table == false then
					local item_info = {}
					item_info.item_count = 1
					item_info.item_name = item_name

					table.insert(support_items_table, item_info)
				end
			end
		end
	end

--	print(support_items_table)

	return support_items_table
end

function CDOTA_PlayerResource:IsImbaPlayer(player_id)
	if self.PlayerData[player_id] then
		return true
	else
		return false
	end
end

-- Set a player's abandonment due to long disconnect status
function CDOTA_PlayerResource:SetHasAbandonedDueToLongDisconnect(player_id, state)
	if self:IsImbaPlayer(player_id) then
		self.PlayerData[player_id]["has_abandoned_due_to_long_disconnect"] = state
--		print("Set player "..player_id.." 's abandon due to long disconnect state as "..tostring(state))
	end
end

-- Fetch a player's abandonment due to long disconnect status
function CDOTA_PlayerResource:GetHasAbandonedDueToLongDisconnect(player_id)
	if self:IsImbaPlayer(player_id) then
		return self.PlayerData[player_id]["has_abandoned_due_to_long_disconnect"]
	else
		return false
	end
end
