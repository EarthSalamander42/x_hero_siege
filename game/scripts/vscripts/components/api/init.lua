-- Copyright (C) 2020 - Frostrose Studio Development Team
-- Api Interface for every custom games managed/created by Frostrose Studio

api = api or class({})

local baseUrl = "https://api.frostrose-studio.com/"
local endUrlWebsite = "website/"
local endUrlFrostrose = string.lower(CUSTOM_GAME_TYPE or "xhs") .. "/"
local timeout = 5000
local native_print = print

function api:Init()
	CustomGameEventManager:RegisterListener("api_change_companion", Dynamic_Wrap(self, "SetCompanion"))
	CustomGameEventManager:RegisterListener("loading_screen_api_request", Dynamic_Wrap(self, "OnLoadingScreenApiRequest"))
end

-- Utils
function api:GetUrl(endpoint)
	local url = baseUrl

	if endpoint == "statistics/ranking/xp" or endpoint == "statistics/ranking/winrate" then
		url = url .. endUrlWebsite
	else
		url = url .. endUrlFrostrose
	end

	print("URL: " .. url .. endpoint)

	return url .. endpoint
end

function api:IsDonator(player_id)
	if self:GetDonatorStatus(player_id) ~= 0 and self:GetDonatorStatus(player_id) ~= 10 then
		return true
	else
		return false
	end
end

function api:IsDeveloper(player_id)
	local status = self:GetDonatorStatus(player_id);
	if status == 1 or status == 2 then
		return true
	else
		return false
	end
end

function api:GetDonatorStatus(player_id)
	if not PlayerResource:IsValidPlayerID(player_id) then
		--		native_print("api:GetDonatorStatus: Player ID not valid!")
		return 0
	end

	local steamid = tostring(PlayerResource:GetSteamID(player_id))

	-- if the game isnt registered yet, we have no way to know if the player is a donator
	if self.players == nil then
		return 0
	end

	if self.players[steamid] ~= nil then
		return self.players[steamid].status
	else
		--		native_print("api:GetDonatorStatus: api players steamid not valid!")
		return 0
	end
end

function api:GetPlayerIngameTag(player_id)
	if not PlayerResource:IsValidPlayerID(player_id) then
		--		native_print("api:GetPlayerIngameTag: Player ID not valid!")
		return nil
	end

	local steamid = tostring(PlayerResource:GetSteamID(player_id));

	-- if the game isnt registered yet, we have no way to know if the player is a donator
	if self.players == nil then
		return nil
	end

	if self.players[steamid] ~= nil then
		return self.players[steamid].ingame_tag
	else
		--		native_print("api:GetPlayerIngameTag: api players steamid not valid!")
		return nil
	end
end

function api:SetPlayerIngameTag(player_id, tag)
	if not PlayerResource:IsValidPlayerID(player_id) then
		--		native_print("api:GetPlayerIngameTag: Player ID not valid!")
		return nil
	end

	local steamid = tostring(PlayerResource:GetSteamID(player_id));

	-- if the game isnt registered yet, we have no way to know if the player is a donator
	if self.players == nil then
		return nil
	end

	if self.players[steamid] ~= nil and self.players[steamid]["toggle_tag"] then
		self.players[steamid].changed_tag_this_game = true
		self.players[steamid].ingame_tag = tag
	else
		--		native_print("api:GetPlayerIngameTag: api players steamid not valid!")
		return nil
	end
end

function api:InitDonatorTableJS()
	local donators = {}

	for i = 0, PlayerResource:GetPlayerCount() - 1 do
		local donator_status = self:GetDonatorStatus(i)
		if donator_status ~= 0 and donator_status ~= 10 then
			donators[PlayerResource:GetSteamID(i)] = donator_status
		end
	end

	-- print(donators)
	CustomNetTables:SetTableValue("game_options", "donators", donators)
end

function api:GetPlayerXP(player_id)
	if not PlayerResource:IsValidPlayerID(player_id) then
		native_print("api:GetPlayerXP: Player ID not valid!")
		return 0
	end

	local steamid = tostring(PlayerResource:GetSteamID(player_id))

	-- if the game isnt registered yet, we have no way to know player xp
	if self.players == nil then
		native_print("api:GetPlayerXP() self.players == nil")
		return 0
	end

	if self.players[steamid] ~= nil then
		return self.players[steamid].xp
	else
		native_print("api:GetPlayerXP: api players steamid not valid!")
		return 0
	end
end

function api:GetPlayerXPLevel(player_id)
	if not PlayerResource:IsValidPlayerID(player_id) then
		native_print("api:GetPlayerXP: Player ID not valid!")
		return 0
	end

	local steamid = tostring(PlayerResource:GetSteamID(player_id));

	-- if the game isnt registered yet, we have no way to know player xp
	if self.players == nil then
		native_print("api:GetPlayerXP() self.players == nil")
		return 0
	end

	if self.players[steamid] ~= nil then
		return self.players[steamid].xp_level + 1
	else
		native_print("api:GetPlayerXP: api players steamid not valid!")
		return 0
	end
end

-- companion, statue, emblem only, wearable cosmetics handled in api:GetArmory()
function api:GetPlayerCosmetics(player_id, cosmetic_type)
	if not PlayerResource:IsValidPlayerID(player_id) then
		native_print("api:GetPlayerCosmetics: Player ID not valid!")
		return false
	end

	if not cosmetic_type then
		native_print("api:GetPlayerCosmetics: cosmetic_type not valid!")
		return false
	end

	-- if the game isnt registered yet, we have no way to know player xp
	if self.players == nil then
		native_print("api:GetPlayerCosmetics() self.players == nil")
		return false
	end

	local steamid = tostring(PlayerResource:GetSteamID(player_id))

	if self.players[steamid] == nil then
		native_print("api:GetPlayerCosmetics: api players steamid not valid!")
		return false
	end

	local cosmetics = api[cosmetic_type]

	if cosmetics and type(cosmetics) == "table" and next(cosmetics) then
	else
		print("api:GetPlayerCosmetics: cosmetics table value is empty for cosmetic_type:", cosmetic_type)
		return false
	end

	local cosmetic_variable = nil

	if cosmetic_type == "companions" then
		cosmetic_variable = "companion_id"
	elseif cosmetic_type == "statues" then
		cosmetic_variable = "statue_id"
	elseif cosmetic_type == "emblems" then
		cosmetic_variable = "emblem_id"
	end

	if cosmetic_variable == nil then
		print("api:GetPlayerCosmetics: invalid cosmetics variable for cosmetics type:", cosmetic_type)
		return false
	end

	local cosmetic_id = self.players[steamid][cosmetic_variable]

	if cosmetic_id == nil then
		native_print("api:GetPlayerCosmetics: Unable to get " .. cosmetic_variable .. " player table!")
		return false
	end

	return self:GetCosmeticByID(cosmetics, cosmetic_id)
end

function api:GetCosmeticByID(hCosmetics, nIndex)
	for k, v in pairs(hCosmetics) do
		if v.id == tostring(nIndex) then
			-- print("Cosmetic found:", v)
			return v.file
		end
	end
end

function api:GetPlayerCompanion(player_id)
	return self:GetPlayerCosmetics(player_id, "companions")
end

function api:GetPlayerStatue(player_id)
	return self:GetPlayerCosmetics(player_id, "statues")
end

function api:GetPlayerEmblem(player_id)
	return self:GetPlayerCosmetics(player_id, "emblems")
end

function api:GetPlayerTagEnabled(player_id)
	if not PlayerResource:IsValidPlayerID(player_id) then
		native_print("api:GetPlayerTagEnabled: Player ID not valid!")
		return false
	end

	local steamid = tostring(PlayerResource:GetSteamID(player_id));

	-- if the game isnt registered yet, we have no way to know player xp
	if self.players == nil then
		native_print("api:GetPlayerTagEnabled() self.players == nil")
		return false
	end

	if self.players[steamid] ~= nil then
		return self.players[steamid]["toggle_tag"]
	else
		native_print("api:GetPlayerTagEnabled: api players steamid not valid!")
		return false
	end
end

function api:GetPlayerBPRewardsEnabled(player_id)
	if not PlayerResource:IsValidPlayerID(player_id) then
		native_print("api:GetPlayerBPRewardsEnabled: Player ID not valid!")
		return false
	end

	local steamid = tostring(PlayerResource:GetSteamID(player_id))

	-- if the game isnt registered yet, we have no way to know player xp
	if self.players == nil then
		native_print("api:GetPlayerBPRewardsEnabled() self.players == nil")
		return false
	end

	if self.players[steamid] ~= nil then
		return self.players[steamid]["bp_rewards"]
	else
		native_print("api:GetPlayerBPRewardsEnabled: api players steamid not valid!")
		return false
	end
end

function api:GetPlayerXPEnabled(player_id)
	if not PlayerResource:IsValidPlayerID(player_id) then
		native_print("api:GetPlayerXPEnabled: Player ID not valid!")
		return false
	end

	local steamid = tostring(PlayerResource:GetSteamID(player_id));

	-- if the game isnt registered yet, we have no way to know player xp
	if self.players == nil then
		native_print("api:GetPlayerXPEnabled() self.players == nil")
		return false
	end

	if self.players[steamid] ~= nil then
		return self.players[steamid]["player_xp"]
	else
		native_print("api:GetPlayerXPEnabled: api players steamid not valid!")
		return false
	end
end

function api:GetPlayerWinrateShown(player_id)
	if not PlayerResource:IsValidPlayerID(player_id) then
		native_print("api:GetPlayerWinrateShown: Player ID not valid!")
		return false
	end

	local steamid = tostring(PlayerResource:GetSteamID(player_id));

	-- if the game isnt registered yet, we have no way to know player xp
	if self.players == nil then
		native_print("api:GetPlayerWinrateShown() self.players == nil")
		return false
	end

	if self.players[steamid] ~= nil then
		return self.players[steamid]["winrate_toggle"]
	else
		native_print("api:GetPlayerWinrateShown: api players steamid not valid!")
		return false
	end
end

function api:GetPlayerWinrate(player_id)
	if not PlayerResource:IsValidPlayerID(player_id) then
		native_print("api:GetPlayerWinrate: Player ID not valid!")
		return false
	end

	local steamid = tostring(PlayerResource:GetSteamID(player_id));

	-- if the game isnt registered yet, we have no way to know player xp
	if self.players == nil then
		native_print("api:GetPlayerWinrate() self.players == nil")
		return false
	end

	if self.players[steamid] ~= nil then
		return self.players[steamid]["winrate_" .. string.gsub(GetMapName(), "imba_", "")]
	else
		native_print("api:GetPlayerWinrate: api players steamid not valid!")
		return false
	end
end

function api:GetPlayerSeasonalWinrate(player_id)
	if not PlayerResource:IsValidPlayerID(player_id) then
		native_print("api:GetPlayerWinrate: Player ID not valid!")
		return false
	end

	local steamid = tostring(PlayerResource:GetSteamID(player_id));

	-- if the game isnt registered yet, we have no way to know player xp
	if self.players == nil then
		native_print("api:GetPlayerWinrate() self.players == nil")
		return false
	end

	if self.players[steamid] ~= nil then
		return self.players[steamid]["seasonal_winrate"]
	else
		native_print("api:GetPlayerWinrate: api players steamid not valid!")
		return false
	end
end

function api:GetPlayerSupporterPass(player_id)
	if not PlayerResource:IsValidPlayerID(player_id) then
		return {}
	end

	local steamid = tostring(PlayerResource:GetSteamID(player_id))
	if self.players == nil or self.players[steamid] == nil then
		return {}
	end

	return self.players[steamid].supporter_pass or {}
end

function api:GetPlayerSupporterTier(player_id)
	local supporter_pass = self:GetPlayerSupporterPass(player_id)
	local tier_id = tonumber(supporter_pass.tier_id)
	local status_tier = 0

	if SupporterPass and SupporterPass.GetTierForStatus then
		status_tier = SupporterPass:GetTierForStatus(self:GetDonatorStatus(player_id))
	end

	if tier_id ~= nil then
		return math.max(tier_id, status_tier)
	end

	return status_tier
end

function api:GetPlayerSupporterFragments(player_id)
	local supporter_pass = self:GetPlayerSupporterPass(player_id)
	return tonumber(supporter_pass.fragments or supporter_pass.fragment_balance) or 0
end

function api:MergeSupporterPassResponse(steamid, data)
	if not steamid or not data or not api.players or not api.players[steamid] then
		return
	end

	local player = api.players[steamid]
	player.supporter_pass = player.supporter_pass or {}
	local supporter_pass = player.supporter_pass
	local profile = data.profile or {}
	local season = data.season or profile.season or supporter_pass.season or {}

	if profile.fragments ~= nil then
		supporter_pass.fragments = profile.fragments
		supporter_pass.fragment_balance = profile.fragments
	end
	if profile.weekly_fragments ~= nil then
		supporter_pass.weekly_fragments = profile.weekly_fragments
		supporter_pass.weekly_earned = profile.weekly_fragments
	end
	if profile.weekly_cap ~= nil then
		supporter_pass.weekly_cap = profile.weekly_cap
	end
	if profile.legacy_fragments ~= nil then
		supporter_pass.legacy_fragments = profile.legacy_fragments
	end

	if season.xp ~= nil or season.level ~= nil or season.xp_per_level ~= nil then
		supporter_pass.season = supporter_pass.season or {}
		supporter_pass.season.xp = season.xp or supporter_pass.season.xp
		supporter_pass.season.level = season.level or supporter_pass.season.level
		supporter_pass.season.xp_per_level = season.xp_per_level or supporter_pass.season.xp_per_level
	end

	local season_xp = season.xp or profile.season_xp
	local season_level = season.level or profile.season_level
	if season_xp ~= nil then
		supporter_pass.season_xp = season_xp
		supporter_pass.current_exp = season_xp
	end
	if season_level ~= nil then
		supporter_pass.season_level = season_level
		supporter_pass.level = season_level
	end

	if data.entitlements ~= nil then
		supporter_pass.entitlements = data.entitlements
	end
	if data.purchases ~= nil then
		supporter_pass.purchases = data.purchases
	end
	if data.loadout ~= nil then
		supporter_pass.loadout = data.loadout
	end
	if data.armory ~= nil then
		supporter_pass.armory = data.armory
	end
	if data.equipped ~= nil then
		supporter_pass.loadout = data.equipped
		player.armory = data.equipped
	end
	if data.claimed_rewards ~= nil then
		supporter_pass.claimed_rewards = data.claimed_rewards
	end
end

function api:PublishSupporterPassArmory(player_id, armory)
	if not PlayerResource:IsValidPlayerID(player_id) then
		return
	end

	if armory == nil then
		local steamid = tostring(PlayerResource:GetSteamID(player_id))
		local player = api.players and api.players[steamid] or nil
		local supporter_pass = player and player.supporter_pass or nil
		armory = supporter_pass and supporter_pass.armory or nil
	end

	if armory ~= nil then
		CustomNetTables:SetTableValue("supporter_pass_armory", "rewards_" .. player_id, armory)
	end
end

function api:GrantSupporterFragments(player_id, amount, reason, idempotency_key, callback)
	if callback == nil then
		callback = function() end
	end

	if not PlayerResource:IsValidPlayerID(player_id) then
		return callback(false)
	end

	local payload = {
		game_id = api:GetApiGameId(),
		match_id = api:GetMatchID(),
		steam_id = tostring(PlayerResource:GetSteamID(player_id)),
		player_id = player_id,
		amount = amount,
		reason = reason,
		idempotency_key = idempotency_key,
		gamemode = api:GetCustomGamemode(),
	}

	api:Request("supporter-fragments/grant", function(data)
		local steamid = tostring(PlayerResource:GetSteamID(player_id))
		api:MergeSupporterPassResponse(steamid, data)

		if SupporterPass and SupporterPass.PublishPlayer then
			SupporterPass:PublishPlayer(player_id)
		end

		callback(true, data)
	end, function(error)
		callback(false, error)
	end, "POST", payload)
end

function api:UpdateSupporterPassSettings(player_id, settings, callback)
	if callback == nil then
		callback = function() end
	end

	if not PlayerResource:IsValidPlayerID(player_id) then
		return callback(false)
	end

	local steamid = tostring(PlayerResource:GetSteamID(player_id))
	local payload = {
		steamid = steamid,
		toggle_tag = settings.toggle_tag == true or settings.toggle_tag == 1,
		pass_rewards = settings.pass_rewards == true or settings.pass_rewards == 1,
		player_xp = settings.player_xp == true or settings.player_xp == 1,
		winrate_toggle = settings.winrate_toggle == true or settings.winrate_toggle == 1,
	}

	api:Request("supporter-pass/settings", function(data)
		if api.players and api.players[steamid] then
			api.players[steamid].toggle_tag = data.toggle_tag
			api.players[steamid].bp_rewards = data.bp_rewards
			api.players[steamid].pass_rewards = data.pass_rewards
			api.players[steamid].player_xp = data.player_xp
			api.players[steamid].winrate = data.winrate_toggle and 1 or 0
			api.players[steamid].winrate_toggle = data.winrate_toggle
		end

		callback(true, data)
	end, function(error)
		callback(false, error)
	end, "POST", payload)
end

function api:BuySupporterPassShopItem(player_id, item_id, callback)
	if callback == nil then
		callback = function() end
	end

	if not PlayerResource:IsValidPlayerID(player_id) then
		return callback(false)
	end

	local steamid = tostring(PlayerResource:GetSteamID(player_id))
	local payload = {
		steamid = steamid,
		item_id = item_id,
	}

	api:Request("supporter-pass/buy-shop-item", function(data)
		api:MergeSupporterPassResponse(steamid, data)
		api:PublishSupporterPassArmory(player_id, data.armory)

		if SupporterPass and SupporterPass.PublishPlayer then
			SupporterPass:PublishPlayer(player_id)
		end

		callback(true, data)
	end, function(error)
		callback(false, error)
	end, "POST", payload)
end

function api:ClaimSupporterPassReward(player_id, reward_id, callback)
	if callback == nil then
		callback = function() end
	end

	if not PlayerResource:IsValidPlayerID(player_id) then
		return callback(false)
	end

	local steamid = tostring(PlayerResource:GetSteamID(player_id))
	local payload = {
		steamid = steamid,
		reward_id = reward_id,
	}

	api:Request("supporter-pass/claim-reward", function(data)
		api:MergeSupporterPassResponse(steamid, data)

		if data.armory then
			api:PublishSupporterPassArmory(player_id, data.armory)
		end

		if SupporterPass and SupporterPass.PublishPlayer then
			SupporterPass:PublishPlayer(player_id)
		end

		callback(true, data)
	end, function(error)
		callback(false, error)
	end, "POST", payload)
end

function api:EquipSupporterPassItem(player_id, item_id, hero, slot_id, callback)
	if callback == nil then
		callback = function() end
	end

	if not PlayerResource:IsValidPlayerID(player_id) then
		return callback(false)
	end

	local steamid = tostring(PlayerResource:GetSteamID(player_id))
	local payload = {
		steamid = steamid,
		item_id = item_id,
		hero = hero,
		slot_id = slot_id,
	}

	api:Request("supporter-pass/equip", function(data)
		api:MergeSupporterPassResponse(steamid, data)

		if data.armory then
			api:PublishSupporterPassArmory(player_id, data.armory)
		end

		if api.players and api.players[steamid] and data.equipped then
			api.players[steamid].armory = data.equipped
		end

		callback(true, data)
	end, function(error)
		callback(false, error)
	end, "POST", payload)
end

function api:GetPlayerMMR(player_id)
	if not PlayerResource:IsValidPlayerID(player_id) then
		native_print("api:GetPlayerMMR: Player ID not valid!")
		return false
	end

	local steamid = tostring(PlayerResource:GetSteamID(player_id));

	-- if the game isnt registered yet, we have no way to know player xp
	if self.players == nil then
		native_print("api:GetPlayerMMR() self.players == nil")
		return false
	end

	if self.players[steamid] ~= nil then
		return self.players[steamid]["mmr_value"]
	else
		native_print("api:GetPlayerMMR: api players steamid not valid!")
		return false
	end
end

function api:GetPlayerRankMMR(player_id)
	if not PlayerResource:IsValidPlayerID(player_id) then
		native_print("api:GetPlayerMMR: Player ID not valid!")
		return false
	end

	local steamid = tostring(PlayerResource:GetSteamID(player_id));

	-- if the game isnt registered yet, we have no way to know player xp
	if self.players == nil then
		native_print("api:GetPlayerMMR() self.players == nil")
		return false
	end

	if self.players[steamid] ~= nil then
		return self.players[steamid]["mmr_title"]
	else
		native_print("api:GetPlayerMMR: api players steamid not valid!")
		return false
	end
end

function api:GetPhantomAssassinArcanaKills(player_id)
	if not PlayerResource:IsValidPlayerID(player_id) then
		--		native_print("api:GetPhantomAssassinArcanaKills: Player ID not valid!")
		return false
	end

	local steamid = tostring(PlayerResource:GetSteamID(player_id));

	-- if the game isnt registered yet, we have no way to know player xp
	if self.players == nil then
		--		native_print("api:GetPhantomAssassinArcanaKills() self.players == nil")
		return false
	end

	if self.players[steamid] ~= nil then
		return self.players[steamid]["pa_arcana_kills"]
	else
		--		native_print("api:GetPhantomAssassinArcanaKills: api players steamid not valid!")
		return false
	end
end

function api:GetPlayerSeasonalWinrate(player_id)
	if not PlayerResource:IsValidPlayerID(player_id) then
		native_print("api:GetPlayerSeasonalWinrate: Player ID not valid!")
		return false
	end

	local steamid = tostring(PlayerResource:GetSteamID(player_id));

	-- if the game isnt registered yet, we have no way to know player xp
	if self.players == nil then
		native_print("api:GetPlayerSeasonalWinrate() self.players == nil")
		return false
	end

	if self.players[steamid] ~= nil then
		return self.players[steamid]["seasonal_winrate"]
	else
		native_print("api:GetPlayerSeasonalWinrate: api players steamid not valid!")
		return false
	end
end

function api:GetArmory(player_id)
	if not PlayerResource:IsValidPlayerID(player_id) then
		--		native_print("api:GetArmory: Player ID not valid!")
		return {}
	end

	local steamid = tostring(PlayerResource:GetSteamID(player_id));

	-- if the game isnt registered yet, we have no way to know if the player is a donator
	if self.players == nil then
		return {}
	end

	if self.players[steamid] ~= nil then
		return self.players[steamid].armory
	else
		--		native_print("api:GetArmory: api players steamid not valid!")
		return {}
	end
end

function api:GetDisabledHeroes()
	if not api.disabled_heroes then return end
	if not api.disabled_heroes["npc_dota_hero_target_dummy"] then api.disabled_heroes["npc_dota_hero_target_dummy"] = true end
	print(api.disabled_heroes)
	return api.disabled_heroes
end

function api:GetApiGameId()
	return self.game_id
end

function api:CheatDetector()
	if CustomNetTables:GetTableValue("game_options", "game_count").value == 1 then
		if Convars:GetBool("sv_cheats") == true or GameRules:IsCheatMode() then
			if not IsInToolsMode() and log then
				log.info("Cheats have been enabled, game don't count.")
				CustomNetTables:SetTableValue("game_options", "game_count", { value = 0 })
				CustomGameEventManager:Send_ServerToAllClients("safe_to_leave", {})
				return true
			end
		end
	end

	return false
end

function api:IsCheatGame()
	if IsInToolsMode() then
		return true
	end

	if CustomNetTables:GetTableValue("game_options", "game_count").value == 0 then
		return true
	end

	return false
end

function api:GetWinnerTeam()
	return GAME_WINNER_TEAM
end

function api:GetKillsForTeam(team)
	return GetTeamHeroKills(team)
end

function api:GetAllPlayerSteamIds()
	local players = {}
	for id = 0, PlayerResource:GetPlayerCount() - 1 do
		if PlayerResource:IsValidPlayerID(id) then
			table.insert(players, tostring(PlayerResource:GetSteamID(id)))
		end
	end

	return players
end

function api:GetMatchID()
	return tostring(GameRules:Script_GetMatchID())
end

function api:GetLoggingConfiguration(callback)
	-- TODO: implement this; do nothing for now
end

function api:Message(message, _type)
	if not message or message == '' then return end

	_type = _type or 1
	local data = json.null
	local messageType = type(message)

	if messageType == "string" or messageType == "boolean" or messageType == "number" or messageType == "table" then
		data = message
	elseif messageType == "function" or messageType == "userdata" then
		data = tostring(message)
	end

	local status, err = xpcall(function()
		--[[
		api:Request("game-event", nil, nil, "POST", {
			type = _type,
			game_id = api.game_id or 0,
			message = data
		})
--]]
	end, function(err)
		if err == nil then
			err = "Unknown Error"
		end

		native_print(err)
	end)
end

function api:GetEventPlayerID(event_source_index, payload)
	local player_id = tonumber(payload and payload.PlayerID or -1) or -1

	if type(event_source_index) == "number" and event_source_index > 0 then
		local ok, sender = pcall(EntIndexToHScript, event_source_index)
		if ok and sender ~= nil and sender.GetPlayerID then
			local sender_player_id = sender:GetPlayerID()
			if sender_player_id ~= nil and sender_player_id >= 0 then
				player_id = sender_player_id
			end
		end
	end

	if not PlayerResource:IsValidPlayerID(player_id) then
		return nil
	end

	return player_id
end

function api:SendLoadingScreenApiResponse(player_id, request_id, ok, data, message)
	local player = PlayerResource:GetPlayer(player_id)
	if player == nil then
		return
	end

	CustomGameEventManager:Send_ServerToPlayer(player, "loading_screen_api_response", {
		request_id = request_id or "",
		ok = ok and 1 or 0,
		data = data or {},
		message = message or "",
	})
end

function api:IsLoadingScreenApiRateLimited(player_id, request_type)
	self.loading_screen_api_last_request = self.loading_screen_api_last_request or {}

	local key = tostring(player_id) .. ":" .. tostring(request_type)
	local now = GameRules:GetGameTime()
	local last_request = self.loading_screen_api_last_request[key]

	if last_request ~= nil and now - last_request < 0.5 then
		return true
	end

	self.loading_screen_api_last_request[key] = now
	return false
end

function api:OnLoadingScreenApiRequest(event_source_index, keys)
	local payload = keys

	if type(event_source_index) == "table" and payload == nil then
		payload = event_source_index
	end

	if payload == nil then
		return
	end

	local player_id = self:GetEventPlayerID(event_source_index, payload)
	if player_id == nil then
		return
	end

	local request_id = tostring(payload.request_id or "")
	if request_id == "" then
		return
	end

	local request_type = tostring(payload.request_type or "")
	if self:IsLoadingScreenApiRateLimited(player_id, request_type) then
		self:SendLoadingScreenApiResponse(player_id, request_id, false, {}, "rate limited")
		return
	end

	if request_type == "loading-screen-info" then
		if self.loading_screen_info_cache ~= nil then
			self:SendLoadingScreenApiResponse(player_id, request_id, true, { data = self.loading_screen_info_cache })
			return
		end

		self:Request("loading-screen-info", function(data)
			self.loading_screen_info_cache = data
			self:SendLoadingScreenApiResponse(player_id, request_id, true, { data = data })
		end, function()
			self:SendLoadingScreenApiResponse(player_id, request_id, false, {}, "loading-screen-info failed")
		end)
		return
	end

	self:SendLoadingScreenApiResponse(player_id, request_id, false, {}, "unknown request")
end

-- Core
function api:Request(endpoint, okCallback, failCallback, method, payload)
	if okCallback == nil then
		okCallback = function()
		end
	end

	if failCallback == nil then
		failCallback = function()
		end
	end

	if method == nil then
		method = "GET"
	end
	method = string.upper(method)

	local request = CreateHTTPRequestScriptVM(method, self:GetUrl(endpoint))

	if request == nil then
		print("Failed to create http request. skipping")
		return failCallback()
	end

	request:SetHTTPRequestAbsoluteTimeoutMS(timeout)

	local header_key = nil

	if IsDedicatedServer() then
		header_key = GetDedicatedServerKeyV2("2")
	else
		local key = LoadKeyValues("scripts/vscripts/components/api/backend_key.kv")

		if key then
			header_key = key.server_key
		end
	end

	request:SetHTTPRequestHeaderValue("X-Dota-Server-Key", header_key)
	request:SetHTTPRequestHeaderValue("X-Dota-Game-Type", CUSTOM_GAME_TYPE)

	-- encode payload
	if payload ~= nil then
		if method == "GET" then
			for key, value in pairs(payload) do
				if value ~= nil and value ~= json.null then
					request:SetHTTPRequestGetOrPostParameter(tostring(key), tostring(value))
				end
			end
		else
			local encoded = json.encode(payload)
			request:SetHTTPRequestRawPostBody("application/json", encoded)
		end
	end

	request:Send(function(result)
		-- print(result)
		local code = result.StatusCode;

		local fail = function(message)
			if (code == nil) then
				code = 0
			end

			print("Request to " .. endpoint .. " failed with message " .. message .. " (" .. tostring(code) .. ")")
			failCallback({
				message = message,
				status_code = code,
				endpoint = endpoint,
			})
		end

		if code == 0 then
			return fail("Request timeout")
		elseif code >= 500 then
			return fail("Server Error")
		elseif code == 204 then
			print("Request to " .. endpoint .. " succeeded with no content")
			return okCallback({})
		else
			local obj, pos, err = json.decode(result.Body)

			if err then
				return fail("Json error: " .. tostring(err))
			end

			if obj == nil then
				return fail("Unknown Server error")
			end

			-- print(obj)
			if obj.error == nil then
				return fail("Invalid response from server")
			elseif obj.error == true and obj.message ~= nil then
				return fail(obj.message)
			elseif obj.error == true and obj.message == nil then
				return fail("Unknown server error. (message is nil)")
			elseif code >= 200 and code < 400 then
				return okCallback(obj.data or {})
			else
				return fail("Wtf")
			end
		end
	end)
end

function api:RegisterGame(callback)
	self:Request("game-register", function(data)
		api.game_id = tonumber(data.game_id)
		api.players = data.players
		api.companions = data.companions or nil
		api.emblems = data.emblems or nil
		api.effigies = data.effigies or data.statues or nil
		api.disabled_heroes = data.disabled_heroes or nil
		api.supporter_pass = data.supporter_pass or nil

		CustomNetTables:SetTableValue("supporter_pass_player", "companions", api.companions)
		CustomNetTables:SetTableValue("supporter_pass_player", "emblems", api.emblems)
		CustomNetTables:SetTableValue("supporter_pass_player", "effigies", api.effigies)

		if data.supporter_pass and data.supporter_pass.shop then
			CustomNetTables:SetTableValue("supporter_pass_shop", "featured", data.supporter_pass.shop)
		end

		if SupporterPass and SupporterPass.PublishPlayers then
			SupporterPass:PublishPlayers()
		end

		for player_id = 0, PlayerResource:GetPlayerCount() - 1 do
			if PlayerResource:IsValidPlayerID(player_id) then
				api:PublishSupporterPassArmory(player_id)
			end
		end

		if IsInToolsMode() then
			for player_id = 0, PlayerResource:GetPlayerCount() - 1 do
				if PlayerResource:IsValidPlayerID(player_id) then
					local steamid = tostring(PlayerResource:GetSteamID(player_id))
					local player = api.players and api.players[steamid] or nil
					local supporter_pass = player and player.supporter_pass or {}
					local season = supporter_pass.season or {}
					print("XHS Supporter Pass register: player=" .. tostring(player_id)
						.. " steamid=" .. steamid
						.. " tier=" .. tostring(supporter_pass.tier_id)
						.. " fragments=" .. tostring(supporter_pass.fragments or supporter_pass.fragment_balance)
						.. " season_xp=" .. tostring(season.xp or supporter_pass.season_xp or supporter_pass.current_exp)
						.. " season_level=" .. tostring(season.level or supporter_pass.season_level or supporter_pass.level))
					if not player then
						print("XHS Supporter Pass register: missing backend player row for steamid=" .. steamid)
					end
				end
			end
		end

		if callback ~= nil then
			callback(data)
		end
	end, function()
		-- fail-safe if http request can't reach backend
		--		GameRules:SetCustomGameSetupRemainingTime(20.0)
	end, "POST", {
		map = GetMapName(),
		match_id = self:GetMatchID(),
		players = self:GetAllPlayerSteamIds(),
		cheat_mode = self:IsCheatGame(),
	})

	-- call in supporter pass scripts after supporter_pass_player is set to show mmr medal in loading screen
	--	print("ALL PLAYERS LOADED IN!")
	--	CustomGameEventManager:Send_ServerToAllClients("all_players_loaded", {})
end

function api:ProcessCompletedGame(data, payload)
	local game_id = payload.game_id or api:GetApiGameId() or api:GetMatchID()
	local match_id = payload.match_id or api:GetMatchID()
	local gamemode = payload.gamemode or api:GetCustomGamemode()
	local game_type = payload.game_type or CUSTOM_GAME_TYPE

	local full_data = {
		players = payload.players,
		data = data,
		game_id = game_id,
		match_id = match_id,
		game_type = game_type,
		gamemode = gamemode,
		game_time = payload.game_time,
		map = payload.map or GetMapName(),
		info = {
			winner = GAME_WINNER_TEAM,
			id = game_id,
			match_id = match_id,
			game_type = game_type,
			gamemode = gamemode,
		}
	}
	CustomNetTables:SetTableValue("game_options", "end_game", full_data)
	-- CustomGameEventManager:Send_ServerToAllClients("end_game", full_data)

	GameRules:SetGameWinner(GAME_WINNER_TEAM, true)
end

function api:CompleteGame()
	print("CompleteGame")
	local players = {}

	local function CountItemsBought(itemsBought, itemName)
		local count = 0

		if itemsBought == nil then
			return count
		end

		for _, itemInfo in pairs(itemsBought) do
			if itemInfo and itemInfo.item_name == itemName then
				count = count + 1
			end
		end

		return count
	end

	local function CountPlayerZoneStat(playerID, statName)
		local total = 0
		local zones = nil

		if GameRules.GameMode ~= nil and GameRules.GameMode.Zones ~= nil then
			zones = GameRules.GameMode.Zones
		elseif GameMode ~= nil and GameMode.Zones ~= nil then
			zones = GameMode.Zones
		end

		if zones == nil then
			return total
		end

		for _, zone in pairs(zones) do
			if zone.PlayerStats ~= nil and zone.PlayerStats[playerID] ~= nil then
				total = total + (tonumber(zone.PlayerStats[playerID][statName]) or 0)
			end
		end

		return total
	end

	local function IsEndScreenHero(hero, playerID)
		return hero ~= nil and not hero:IsNull() and hero:IsRealHero() and hero:GetPlayerID() == playerID
	end

	local function ResolveEndScreenHero(playerID)
		local candidates = {}
		local selectedHero = PlayerResource:GetSelectedHeroEntity(playerID)
		local player = PlayerResource:GetPlayer(playerID)
		local assignedHero = nil

		if player ~= nil then
			assignedHero = player:GetAssignedHero()
		end

		if IsEndScreenHero(selectedHero, playerID) then
			table.insert(candidates, selectedHero)
		end

		if IsEndScreenHero(assignedHero, playerID) and assignedHero ~= selectedHero then
			table.insert(candidates, assignedHero)
		end

		for _, hero in pairs(HeroList:GetAllHeroes()) do
			if IsEndScreenHero(hero, playerID) and hero ~= selectedHero and hero ~= assignedHero then
				table.insert(candidates, hero)
			end
		end

		local fallbackHero = nil
		for _, hero in pairs(candidates) do
			fallbackHero = fallbackHero or hero

			if hero:FindModifierByName("modifier_tome_of_stats") ~= nil then
				return hero
			end
		end

		return fallbackHero
	end

	for id = 0, PlayerResource:GetPlayerCount() - 1 do
		if PlayerResource:IsValidPlayerID(id) then
			local items = {}
			local heroEntity = ResolveEndScreenHero(id)
			local hero = json.null
			local networth = 0
			local healing = PlayerResource:GetHealing(id)
			local tracked_potions_used = XHSGetPotionUses ~= nil and XHSGetPotionUses(id) or 0
			local potions_used = tracked_potions_used > 0 and tracked_potions_used or CountPlayerZoneStat(id, "Potions")
			local damage_done_to_heroes = 0
			local damage_done_to_buildings = 0
			local kills_done_to_hero = {}
			local items_bought = {}
			local abandon = false
			local leaderboard = {}
			local support_items = {}
			local abilities_level_up_order = {}
			local tracked_tome_stats_bonus = XHSGetTomeStats ~= nil and XHSGetTomeStats(id) or 0
			local tome_stats_bonus = tracked_tome_stats_bonus

			if PlayerResource.GetHasAbandonedDueToLongDisconnect then
				abandon = PlayerResource:GetHasAbandonedDueToLongDisconnect(id)
			end

			if PlayerResource.GetItemsBought then
				items_bought = PlayerResource:GetItemsBought(id)
			end

			if PlayerResource.GetSupportItemsBought then
				support_items = PlayerResource:GetSupportItemsBought(id, items_bought)
			end

			if PlayerResource.GetAbilitiesLevelUpOrder then
				abilities_level_up_order = PlayerResource:GetAbilitiesLevelUpOrder(id)
			end

			if heroEntity ~= nil then
				hero = tostring(heroEntity:GetUnitName())

				for slot = 0, 15 do
					local item = heroEntity:GetItemInSlot(slot)
					if item ~= nil then
						table.insert(items, tostring(item:GetAbilityName()))
					end
				end

				networth = PlayerResource:GetNetWorth(id)

				local tomeModifier = heroEntity:FindModifierByName("modifier_tome_of_stats")
				if tomeModifier ~= nil then
					tome_stats_bonus = math.max(tome_stats_bonus, tomeModifier:GetStackCount())
				end
			end

			if CUSTOM_GAME_TYPE == "PLS" then
				for index, score in pairs(Rounds.player_score[id]) do
					table.insert(leaderboard, index, score)
					--					table.insert(leaderboard, tonumber(index), score)
				end
			end

			for i = 0, PlayerResource:GetPlayerCount() - 1 do
				damage_done_to_heroes = damage_done_to_heroes + PlayerResource:GetDamageDoneToHero(id, i)
				kills_done_to_hero[i] = PlayerResource:GetKillsDoneToHero(id, i)
			end

			--			if IsInToolsMode() and id == 0 then
			--				print("CompleteGame: Items:", items)
			--				print("CompleteGame: Items Bought:", items_bought)
			--				print("CompleteGame: Support Items Bought:", PlayerResource:GetSupportItemsBought(id, items_bought))
			--				print("CompleteGame: Abilities Level Up Order:", PlayerResource:GetAbilitiesLevelUpOrder(id))
			--			end

			local increment_pa_arcana_kills = false

			if hero and hero == "npc_dota_hero_phantom_assassin" and Battlepass and Battlepass:HasArcana(id, "phantom_assassin") then
				increment_pa_arcana_kills = true
			end

			--			print("Player Leaderboard:", leaderboard)

			local player = {
				id = id,
				kills = tonumber(PlayerResource:GetKills(id)),
				deaths = tonumber(PlayerResource:GetDeaths(id)),
				assists = tonumber(PlayerResource:GetAssists(id)),
				level = tonumber(PlayerResource:GetLevel(id)),
				hero = hero,
				team = tonumber(PlayerResource:GetTeam(id)),
				items = items,
				networth = networth,
				healing = healing,
				potions_used = potions_used,
				damage_done_to_heroes = damage_done_to_heroes,
				damage_done_to_buildings = damage_done_to_buildings,
				kills_done_to_hero = kills_done_to_hero,
				items_bought = items_bought,
				tome_stats_bonus = tome_stats_bonus,
				tomes_bought_small = CountItemsBought(items_bought, "item_tome_small"),
				tomes_bought_big = CountItemsBought(items_bought, "item_tome_big"),
				tomes_bought_power = CountItemsBought(items_bought, "item_tome_of_power"),
				support_items = support_items,
				gold_spent_on_support = PlayerResource:GetGoldSpentOnSupport(id),
				abilities_level_up_order = abilities_level_up_order,
				increment_pa_arcana_kills = increment_pa_arcana_kills,
				pa_arcana_kills = api:GetPhantomAssassinArcanaKills(id),
				abandon = abandon,
				leaderboard = leaderboard,
			}

			local steamid = tostring(PlayerResource:GetSteamID(id))

			if steamid == "0" then
				steamid = tostring(id)
			end

			players[steamid] = player
		end
	end

	local winnerTeam = api:GetWinnerTeam()
	if winnerTeam == nil or winnerTeam == 0 then
		winnerTeam = json.null
	end

	local rosh_lvl
	local rosh_hp
	local rosh_max_hp

	--	print(rosh_lvl, rosh_hp, rosh_max_hp)

	local api_game_id = self:GetApiGameId()
	if api_game_id == nil or api_game_id == 0 then
		api_game_id = self:GetMatchID()
	end

	local payload = {
		winner = winnerTeam,
		game_id = api_game_id,
		match_id = self:GetMatchID(),
		players = players,
		-- radiant_score = self:GetKillsForTeam(2),
		-- dire_score = self:GetKillsForTeam(3),
		game_time = GameRules:GetDOTATime(false, false),
		game_type = CUSTOM_GAME_TYPE,
		gamemode = api:GetCustomGamemode(),
		rosh_lvl = rosh_lvl,
		rosh_hp = rosh_hp,
		rosh_max_hp = rosh_max_hp,
		cheat_mode = self:IsCheatGame(),
		map = GetMapName(),
	}

	self:Request("game-complete", function(data)
			print("game-complete: Game complete successful!")
			api:ProcessCompletedGame(data, payload)
		end,

		function(data)
			print("game-complete: Error on game complete!")
			print(data)
			api:ProcessCompletedGame(data, payload)
		end,
		"POST", payload
	)
end

function api:DiretideHallOfFame(successCallback, failCallback)
	self:Request("diretide-score", function(data)
		if successCallback ~= nil then
			successCallback(data)
		end
	end, failCallback, "POST", {
		map = GetMapName(),
	})
end

-- todo: do different stuff based on the game mode
function api:SetCustomGamemode(iValue)
	if iValue and type(iValue) == "number" then
		-- GameRules:SetCustomGameDifficulty(iValue)
		CustomNetTables:SetTableValue("game_options", "gamemode", { tostring(iValue) })
	else
		print("ERROR: Value should be a number, not string.")
		api:SetCustomGamemode(tonumber(iValue))
	end

	return nil
end

function api:GetCustomGamemode()
	local value = CustomNetTables:GetTableValue("game_options", "gamemode")

	if value then
		value = value["1"]
	end

	return tonumber(value)
end

function api:SetCustomDifficulty(iValue)
	if iValue and type(iValue) == "number" then
		GameRules:SetCustomGameDifficulty(iValue)
		CustomNetTables:SetTableValue("game_options", "difficulty", { tostring(iValue) })
	else
		print("ERROR: Value should be a number, not string.")
		api:SetCustomDifficulty(tonumber(iValue))
	end

	return nil
end

function api:GetCustomDifficulty()
	local value = CustomNetTables:GetTableValue("game_options", "difficulty")

	if value then
		value = value["1"]
	end

	return tonumber(value)
end

-- Credits: darklord (Dota 12v12)
function api:DetectParties()
	self.parties = {}
	local party_indicies = {}
	local party_members_count = {}
	local party_index = 1
	-- Set up player colors
	for id = 0, 23 do
		if PlayerResource:IsValidPlayer(id) then
			local party_id = tonumber(tostring(PlayerResource:GetPartyID(id)))
			if party_id and party_id > 0 then
				if not party_indicies[party_id] then
					party_indicies[party_id] = party_index
					party_index = party_index + 1
				end
				local party_index = party_indicies[party_id]
				self.parties[id] = party_index
				if not party_members_count[party_index] then
					party_members_count[party_index] = 0
				end
				party_members_count[party_index] = party_members_count[party_index] + 1
			end
		end
	end
	for id, party in pairs(self.parties) do
		-- at least 2 ppl in party!
		if party_members_count[party] and party_members_count[party] < 2 then
			self.parties[id] = nil
		end
	end

	-- print("Parties:", api.parties)
end

function api:FindPlayerParty(iPlayerID)
	if not self.parties then
		print("No party detected.")
		return
	end

	for id, party in pairs(self.parties) do
		if iPlayerID == id then
			return party
		end
	end
end

function api:SetCompanion(data)
	local player_id = data.PlayerID
	local unit_name = data.sUnitName

	local payload = {
		companion_id = data.companion_id,
		steamid = tostring(PlayerResource:GetSteamID(player_id))
	}

	api:Request("modify-companion", function(data)
			Battlepass:DonatorCompanion(player_id, unit_name, true)
		end,
		function(data)
			CustomGameEventManager:Send_ServerToPlayer(player, "change_companion_failure", {})
		end, "POST", payload)
end

function api:GetParties(iPlayerID)
	if not self.parties then
		print("No party detected.")
		return
	end

	return self.parties
end

function api:GetPlayerSupporterURL(player_id)
	if not PlayerResource:IsValidPlayerID(player_id) then
		native_print("api:GetPlayerSupporterURL: Player ID not valid!")
		return false
	end

	local steamid = tostring(PlayerResource:GetSteamID(player_id))

	-- if the game isnt registered yet, we have no way to know if the player is a donator
	if self.players == nil then
		return false
	end

	if self.players[steamid] ~= nil then
		local supporter_pass = self.players[steamid].supporter_pass or {}
		return supporter_pass.url or self.players[steamid].supporter_url
	else
		native_print("api:GetPlayerSupporterURL: api players steamid not valid!")
		return false
	end
end

function api:GetPlayerAchievements(player_id)
	if not PlayerResource:IsValidPlayerID(player_id) then
		native_print("api:GetPlayerAchievements: Player ID not valid!")
		return false
	end

	local steamid = tostring(PlayerResource:GetSteamID(player_id))

	-- if the game isnt registered yet, we have no way to know if the player is a donator
	if self.players == nil then
		return false
	end

	if self.players[steamid] ~= nil then
		local supporter_pass = self.players[steamid].supporter_pass or {}
		return supporter_pass.challenges or supporter_pass.achievements or {}
	else
		native_print("api:GetPlayerAchievements: api players steamid not valid!")
		return false
	end
end

function api:GetPlayerSupporterPassXP(player_id)
	if not PlayerResource:IsValidPlayerID(player_id) then
		native_print("api:GetPlayerSupporterPassXP: Player ID not valid!")
		return 0
	end

	local steamid = tostring(PlayerResource:GetSteamID(player_id))

	if self.players == nil then
		return 0
	end

	if self.players[steamid] ~= nil then
		local supporter_pass = self.players[steamid].supporter_pass or {}
		return tonumber(supporter_pass.season_xp or supporter_pass.current_exp) or 0
	else
		native_print("api:GetPlayerSupporterPassXP: api players steamid not valid!")
		return 0
	end
end

function api:GetPlayerSupporterPassLevel(player_id)
	if not PlayerResource:IsValidPlayerID(player_id) then
		native_print("api:GetPlayerSupporterPassLevel: Player ID not valid!")
		return false
	end

	local steamid = tostring(PlayerResource:GetSteamID(player_id))

	if self.players == nil then
		return false
	end

	if self.players[steamid] ~= nil then
		local supporter_pass = self.players[steamid].supporter_pass or {}
		return math.max(tonumber(supporter_pass.season_level or supporter_pass.level) or 1, 1)
	else
		native_print("api:GetPlayerSupporterPassLevel: api players steamid not valid!")
		return 1
	end
end

api:Init()

require("components/api/events")
require("components/api/mods/" .. CUSTOM_GAME_TYPE .. "")
