-- Copyright (C) 2020 - Frostrose Studio Development Team
-- Api Interface for every custom games managed/created by Frostrose Studio

api = api or class({})

local baseUrl = "https://api.frostrose-studio.com/"
local endUrlWebsite = "website/"
local endUrlFrostrose = string.lower(CUSTOM_GAME_TYPE or "xhs") .. "/"
local timeout = 5000
local native_print = print

local function IsValidApiPlayerID(player_id)
	player_id = tonumber(player_id)
	return player_id ~= nil
		and player_id >= 0
		and PlayerResource ~= nil
		and PlayerResource.IsValidPlayerID ~= nil
		and PlayerResource:IsValidPlayerID(player_id)
end

local function GetApiSteamID(player_id)
	if not IsValidApiPlayerID(player_id) then return nil end

	local ok, steam_id = pcall(function()
		return PlayerResource:GetSteamID(tonumber(player_id))
	end)
	if not ok or steam_id == nil then return nil end

	steam_id = tostring(steam_id)
	if steam_id == "" or steam_id == "0" then return nil end
	return steam_id
end

local function IsApiBotPlayerID(player_id)
	if not IsValidApiPlayerID(player_id) then return false end

	if IsXHSBotPlayerID ~= nil then
		local ok, is_xhs_bot = pcall(IsXHSBotPlayerID, tonumber(player_id))
		if ok and is_xhs_bot == true then return true end
	end

	-- The explicit XHS registry is authoritative. IsFakeClient is a defensive
	-- fallback for the short provisioning window before a bot is registered.
	if PlayerResource.IsFakeClient ~= nil then
		local ok, is_fake_client = pcall(function()
			return PlayerResource:IsFakeClient(tonumber(player_id))
		end)
		if ok and is_fake_client == true then return true end
	end

	return false
end

local function IsApiSpectatorPlayerID(player_id)
	if not IsValidApiPlayerID(player_id)
		or PlayerResource.GetTeam == nil then
		return false
	end

	local ok, team = pcall(function()
		return PlayerResource:GetTeam(tonumber(player_id))
	end)
	return ok and tonumber(team) == 1
end

local function IsApiPersistentPlayerID(player_id)
	if not IsValidApiPlayerID(player_id) then return false end
	if IsApiSpectatorPlayerID(player_id) then return false end

	if IsXHSPersistentPlayerID ~= nil then
		local ok, is_persistent = pcall(IsXHSPersistentPlayerID, tonumber(player_id))
		if ok then
			return is_persistent == true and GetApiSteamID(player_id) ~= nil
		end
	end

	if IsApiBotPlayerID(player_id) then return false end
	return GetApiSteamID(player_id) ~= nil
end

function api:IsPersistentPlayerID(player_id)
	return IsApiPersistentPlayerID(player_id)
end

function api:GetPersistentPlayerSteamID(player_id)
	if not self:IsPersistentPlayerID(player_id) then return nil end
	return GetApiSteamID(player_id)
end

function api:IsXHSBotParticipant(player_id)
	return IsApiBotPlayerID(player_id)
end

function api:HasXHSBotParticipants()
	if GetXHSBotPlayerIDs ~= nil then
		local ok, bot_ids = pcall(GetXHSBotPlayerIDs)
		if ok and type(bot_ids) == "table" and next(bot_ids) ~= nil then
			return true
		end
	end

	for player_id = 0, 23 do
		if IsApiBotPlayerID(player_id) then return true end
	end

	return false
end

function api:HasXHSBotSession()
	-- Configuration is checked in addition to the live registry so persistence
	-- is disabled immediately after the controller requests bots, including
	-- the asynchronous provisioning window and explicit provisioning failures.
	if XHSBots ~= nil and type(XHSBots.configuration) == "table"
		and (tonumber(XHSBots.configuration.count) or 0) > 0 then
		return true
	end

	return self:HasXHSBotParticipants()
end

function api:GetXHSBotParticipantCount()
	local count = 0
	for player_id = 0, 23 do
		if IsApiBotPlayerID(player_id) then count = count + 1 end
	end
	return count
end

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

	local full_url = url .. endpoint
	local uses_combined_log = endpoint == "game-register"
		or endpoint == "game-complete"
		or endpoint == "performance"
	if not uses_combined_log then
		print("URL: " .. full_url)
	end

	return full_url
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

function api:GetBotDonatorStatus(player_id)
	local bot_supporter_tier = self:GetBotSupporterTier(player_id)
	if bot_supporter_tier <= 0 then
		return 0
	end

	if DONATOR_TIER_TO_STATUS ~= nil and DONATOR_TIER_TO_STATUS[bot_supporter_tier] ~= nil then
		return DONATOR_TIER_TO_STATUS[bot_supporter_tier]
	end

	local tier_to_status = {
		[1] = 6,
		[2] = 5,
		[3] = 4,
		[4] = 7,
		[5] = 8,
	}

	return tier_to_status[bot_supporter_tier] or 0
end

function api:GetDevPreviewSupporterTier(player_id)
	-- Legacy PID-based tiers are a local supporter UI preview, not bot
	-- detection. Keep the preview available to real Tools users only.
	if not IsInToolsMode() or not self:IsPersistentPlayerID(player_id) then
		return 0
	end

	local connection_state = PlayerResource:GetConnectionState(player_id)
	if player_id >= 1 and player_id <= 5 and (connection_state == 1 or connection_state == 2) then
		return player_id
	end

	return 0
end

-- Backwards-compatible name for existing visual code. This deliberately
-- returns zero for XHS/engine bots and outside Tools mode.
function api:GetBotSupporterTier(player_id)
	return self:GetDevPreviewSupporterTier(player_id)
end

function api:GetDonatorStatus(player_id)
	if not self:IsPersistentPlayerID(player_id) then
		--		native_print("api:GetDonatorStatus: Player ID not valid!")
		return 0
	end

	if self.temporary_donator_status ~= nil and self.temporary_donator_status[player_id] ~= nil then
		return self.temporary_donator_status[player_id]
	end

	local bot_donator_status = self:GetBotDonatorStatus(player_id)
	if bot_donator_status ~= 0 then
		return bot_donator_status
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

function api:GetTemporaryDonatorStatus(player_id)
	if not self:IsPersistentPlayerID(player_id) then
		return nil
	end

	if self.temporary_donator_status == nil then
		return nil
	end

	return self.temporary_donator_status[player_id]
end

function api:SetTemporaryDonatorStatus(player_id, status)
	if not self:IsPersistentPlayerID(player_id) then
		return false
	end

	self.temporary_donator_status = self.temporary_donator_status or {}

	if status == nil then
		self.temporary_donator_status[player_id] = nil
		return true
	end

	status = tonumber(status) or 0
	status = math.max(0, math.min(10, math.floor(status)))
	self.temporary_donator_status[player_id] = status
	return true
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

function api:GetPlayerIngameAdvertizeHidden(player_id)
	if not PlayerResource:IsValidPlayerID(player_id) then
		return nil
	end

	local steamid = tostring(PlayerResource:GetSteamID(player_id))
	if self.players == nil or self.players[steamid] == nil then
		return nil
	end

	local player = self.players[steamid]
	local supporter_pass = player.supporter_pass or {}
	local settings = supporter_pass.settings or player.settings or {}
	local values = {
		settings.xhs_ingame_advertize_hidden,
		settings.ingame_advertize_hidden,
		player.xhs_ingame_advertize_hidden,
		player.ingame_advertize_hidden,
	}

	for _, value in pairs(values) do
		if value ~= nil then
			return value
		end
	end

	return nil
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
	if not self:IsPersistentPlayerID(player_id) then
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

local function IsSupporterClaimedValue(value)
	if value == true or value == 1 or value == "1" then return true end
	return string.lower(tostring(value or "")) == "true"
end

local function CollectSupporterClaimIDs(value, result, depth)
	result = result or {}
	depth = depth or 0
	if type(value) ~= "table" or depth > 5 then return result end

	local rewardID = value.reward_id or value.reward_key
	if rewardID == nil and value.claimed ~= nil then
		rewardID = value.id
	end
	local isRewardRecord = rewardID ~= nil or value.claimed ~= nil
	if rewardID ~= nil and IsSupporterClaimedValue(value.claimed) then
		result[tostring(rewardID)] = true
	end

	for key, nested in pairs(value) do
		if type(nested) == "table" then
			CollectSupporterClaimIDs(nested, result, depth + 1)
		elseif not isRewardRecord
		and IsSupporterClaimedValue(nested)
		and type(key) == "string"
		then
			result[tostring(key)] = true
		elseif tonumber(key) ~= nil and type(nested) == "string" and nested ~= "" then
			result[nested] = true
		end
	end
	return result
end

local function MergeSupporterClaimIDs(target, source)
	target = target or {}
	for rewardID in pairs(CollectSupporterClaimIDs(source or {})) do
		target[tostring(rewardID)] = true
	end
	return target
end

local function NormalizeSupporterClaimSeasonKey(value)
	if type(value) == "table" then
		value = value.season_id
			or value.season_key
			or value.key
			or value.id
			or value.name
			or value.title
	end
	if value == nil then return nil end

	local key = string.lower(tostring(value))
	key = string.gsub(key, "^%s+", "")
	key = string.gsub(key, "%s+$", "")
	if key == "" then return nil end

	-- The live backend and the local manifest use different identifiers for
	-- the same 2026 season. Claims may only be merged after canonicalization.
	if string.find(key, "2026", 1, true) ~= nil then
		return "supporter_pass_2026"
	end
	return key
end

local function InferSupporterClaimSeasonKey(claimed)
	local inferred = nil
	local found = false

	for rewardID in pairs(CollectSupporterClaimIDs(claimed or {})) do
		found = true
		local id = string.lower(tostring(rewardID))
		local rewardSeason = nil
		if string.match(id, "^sp26_") ~= nil
			or string.find(id, "supporter_pass_2026:", 1, true) == 1
		then
			rewardSeason = "supporter_pass_2026"
		end

		-- Unknown or mixed identifiers are deliberately not treated as being
		-- in the current season. This prevents cross-season monotone unions.
		if rewardSeason == nil then return nil end
		if inferred ~= nil and inferred ~= rewardSeason then return nil end
		inferred = rewardSeason
	end

	return found and inferred or nil
end

local function GetSupporterClaimSeasonFromPass(supporter_pass)
	if type(supporter_pass) ~= "table" then return nil end
	return NormalizeSupporterClaimSeasonKey(supporter_pass.season)
		or NormalizeSupporterClaimSeasonKey(supporter_pass.season_id)
		or NormalizeSupporterClaimSeasonKey(supporter_pass.season_key)
end

local function GetSupporterClaimSeasonFromResponse(data)
	if type(data) ~= "table" then return nil end
	local profile = type(data.profile) == "table" and data.profile
		or (type(data.supporter_pass) == "table" and data.supporter_pass or {})
	return NormalizeSupporterClaimSeasonKey(data.season)
		or NormalizeSupporterClaimSeasonKey(data.season_id)
		or NormalizeSupporterClaimSeasonKey(data.season_key)
		or NormalizeSupporterClaimSeasonKey(profile.season)
		or NormalizeSupporterClaimSeasonKey(profile.season_id)
		or NormalizeSupporterClaimSeasonKey(profile.season_key)
end

local function GetSupporterClaimPayload(data, fallback)
	if type(data) ~= "table" then return fallback or {} end
	local profile = type(data.profile) == "table" and data.profile
		or (type(data.supporter_pass) == "table" and data.supporter_pass or {})
	return data.claimed_rewards
		or profile.claimed_rewards
		or fallback
		or {}
end

local function GetSupporterClaimSyncState(steamid)
	api.supporter_claim_sync_state = api.supporter_claim_sync_state or {}
	local key = tostring(steamid)
	local state = api.supporter_claim_sync_state[key]
	if type(state) ~= "table" then
		state = {
			mutation_revision = 0,
			refresh_sequence = 0,
		}
		api.supporter_claim_sync_state[key] = state
	end
	return state
end

local function GetSupporterClaimPlayerState(steamid)
	local player = api.players and api.players[tostring(steamid)] or nil
	local supporter_pass = player and player.supporter_pass or nil
	local claimed = CollectSupporterClaimIDs(
		supporter_pass and supporter_pass.claimed_rewards or {}
	)
	return player, supporter_pass, claimed
end

local function IsSupporterClaimPlayerStillBound(player_id, steamid)
	return api:GetPersistentPlayerSteamID(player_id) == tostring(steamid)
end

function api:MergeSupporterPassResponse(steamid, data)
	if not steamid or not data or not api.players or not api.players[steamid] then
		return
	end

	local player = api.players[steamid]
	player.supporter_pass = player.supporter_pass or {}
	local supporter_pass = player.supporter_pass
	local profile = data.profile or data.supporter_pass or {}
	local season = data.season or profile.season or supporter_pass.season or {}
	local function FirstNonNil(...)
		for index = 1, select("#", ...) do
			local value = select(index, ...)
			if value ~= nil then
				return value
			end
		end
		return nil
	end
	local season_id = season.season_id or season.id or season.key
	if season_id ~= nil and tostring(season_id) ~= "" then
		supporter_pass.season = supporter_pass.season or {}
		supporter_pass.season.id = season_id
		supporter_pass.season.season_id = season_id
	end

	if profile.fragments ~= nil then
		supporter_pass.fragments = profile.fragments
		supporter_pass.fragment_balance = profile.fragments
	end
	local daily_fragments = profile.daily_fragments or profile.daily_earned or profile.weekly_fragments
	if daily_fragments ~= nil then
		supporter_pass.daily_fragments = daily_fragments
		supporter_pass.daily_earned = daily_fragments
		supporter_pass.weekly_fragments = daily_fragments
		supporter_pass.weekly_earned = daily_fragments
	end
	local daily_cap = profile.daily_cap or profile.weekly_cap
	if daily_cap ~= nil then
		supporter_pass.daily_cap = daily_cap
		supporter_pass.weekly_cap = daily_cap
	end

	if season.xp ~= nil or season.level ~= nil or season.xp_per_level ~= nil then
		supporter_pass.season = supporter_pass.season or {}
		supporter_pass.season.xp = season.xp or supporter_pass.season.xp
		supporter_pass.season.level = season.level or supporter_pass.season.level
		supporter_pass.season.xp_per_level = season.xp_per_level or supporter_pass.season.xp_per_level
	end

	local season_xp = season.xp or profile.season_xp
	local season_level = season.level or profile.season_level
	local season_xp_change = season.xp_change or season.gained_xp or profile.season_xp_change or profile.xp_change or data.season_xp_change or data.supporter_pass_xp_change or data.xp_change
	local base_xp_change = season.base_xp_change or profile.base_xp_change or data.base_xp_change
	local xp_boost = season.xp_boost or profile.xp_boost or data.xp_boost
	local xp_bonus = season.xp_bonus or profile.xp_bonus or data.xp_bonus
	local duration_xp = FirstNonNil(season.duration_xp, profile.duration_xp, data.duration_xp)
	local victory_xp_bonus = FirstNonNil(season.victory_xp_bonus, profile.victory_xp_bonus, data.victory_xp_bonus)
	local xp_eligible = FirstNonNil(season.xp_eligible, profile.xp_eligible, data.xp_eligible)
	local xp_ineligible_reason = FirstNonNil(season.xp_ineligible_reason, profile.xp_ineligible_reason, data.xp_ineligible_reason)
	local xp_eligibility_reason = FirstNonNil(season.xp_eligibility_reason, profile.xp_eligibility_reason, data.xp_eligibility_reason)
	if season_xp ~= nil then
		supporter_pass.season_xp = season_xp
		supporter_pass.current_exp = season_xp
	end
	if season_level ~= nil then
		supporter_pass.season_level = season_level
		supporter_pass.level = season_level
	end
	if season_xp_change ~= nil then
		supporter_pass.season_xp_change = season_xp_change
		supporter_pass.xp_change = season_xp_change
		supporter_pass.season = supporter_pass.season or {}
		supporter_pass.season.xp_change = season_xp_change
	end
	if base_xp_change ~= nil then
		supporter_pass.base_xp_change = base_xp_change
		supporter_pass.season = supporter_pass.season or {}
		supporter_pass.season.base_xp_change = base_xp_change
	end
	if xp_boost ~= nil then
		supporter_pass.xp_boost = xp_boost
		supporter_pass.season = supporter_pass.season or {}
		supporter_pass.season.xp_boost = xp_boost
	end
	if xp_bonus ~= nil then
		supporter_pass.xp_bonus = xp_bonus
		supporter_pass.season = supporter_pass.season or {}
		supporter_pass.season.xp_bonus = xp_bonus
	end
	if duration_xp ~= nil then
		supporter_pass.duration_xp = duration_xp
		supporter_pass.season = supporter_pass.season or {}
		supporter_pass.season.duration_xp = duration_xp
	end
	if victory_xp_bonus ~= nil then
		supporter_pass.victory_xp_bonus = victory_xp_bonus
		supporter_pass.season = supporter_pass.season or {}
		supporter_pass.season.victory_xp_bonus = victory_xp_bonus
	end
	if xp_eligible ~= nil then
		supporter_pass.xp_eligible = xp_eligible
		supporter_pass.season = supporter_pass.season or {}
		supporter_pass.season.xp_eligible = xp_eligible
	end
	if xp_ineligible_reason ~= nil then
		supporter_pass.xp_ineligible_reason = xp_ineligible_reason
		supporter_pass.season = supporter_pass.season or {}
		supporter_pass.season.xp_ineligible_reason = xp_ineligible_reason
	end
	if xp_eligibility_reason ~= nil then
		supporter_pass.xp_eligibility_reason = xp_eligibility_reason
		supporter_pass.season = supporter_pass.season or {}
		supporter_pass.season.xp_eligibility_reason = xp_eligibility_reason
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
	end
	if data.claimed_rewards ~= nil then
		supporter_pass.claimed_rewards = data.claimed_rewards
	end
end

function api:RefreshSupporterPassClaims(player_id, callback)
	callback = callback or function() end
	if self:HasXHSBotSession() then
		return callback(false, { code = "xhs_bot_session" })
	end

	local steamid = self:GetPersistentPlayerSteamID(player_id)
	if steamid == nil then
		return callback(false, { code = "non_persistent_player" })
	end

	local syncState = GetSupporterClaimSyncState(steamid)
	syncState.refresh_sequence = syncState.refresh_sequence + 1
	local refreshSequence = syncState.refresh_sequence
	local mutationRevision = syncState.mutation_revision
	local _, requestPass, requestClaims = GetSupporterClaimPlayerState(steamid)
	local requestSeason = GetSupporterClaimSeasonFromPass(requestPass)
		or syncState.season_key
		or InferSupporterClaimSeasonKey(requestClaims)

	self:Request("supporter-pass/catalog", function(data)
		data = data or {}
		local currentState = GetSupporterClaimSyncState(steamid)
		local _, currentPass, currentClaims = GetSupporterClaimPlayerState(steamid)

		-- A refresh is a replace-like snapshot. Ignore it if a newer refresh
		-- exists or if any claim POST was confirmed after this GET started.
		if currentState.refresh_sequence ~= refreshSequence
			or currentState.mutation_revision ~= mutationRevision
		then
			if IsSupporterClaimPlayerStillBound(player_id, steamid)
			and SupporterPass and SupporterPass.PublishPlayer
			then
				SupporterPass:PublishPlayer(player_id)
			end
			callback(true, {
				claimed_rewards = currentClaims,
				season = currentPass and currentPass.season or nil,
				stale_ignored = true,
			})
			return
		end

		local remoteClaims = CollectSupporterClaimIDs(data.rewards or {})
		local currentSeason = GetSupporterClaimSeasonFromPass(currentPass)
			or currentState.season_key
			or InferSupporterClaimSeasonKey(currentClaims)
		local remoteSeason = GetSupporterClaimSeasonFromResponse(data)
			or InferSupporterClaimSeasonKey(remoteClaims)
			or requestSeason
		local claimed = {}

		-- Claims are monotone only inside one positively identified season.
		-- A real season transition intentionally starts from the remote set.
		if currentSeason ~= nil
			and remoteSeason ~= nil
			and currentSeason == remoteSeason
		then
			MergeSupporterClaimIDs(claimed, currentClaims)
		end
		MergeSupporterClaimIDs(claimed, remoteClaims)

		api:MergeSupporterPassResponse(steamid, {
			season = data.season,
			claimed_rewards = claimed,
		})
		currentState.season_key = remoteSeason
		if IsSupporterClaimPlayerStillBound(player_id, steamid)
		and SupporterPass and SupporterPass.PublishPlayer
		then
			SupporterPass:PublishPlayer(player_id)
		end
		callback(true, {
			claimed_rewards = claimed,
			season = data.season,
		})
	end, function(error)
		callback(false, error)
	end, "GET", {
		steamid = steamid,
	})
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

	CustomNetTables:SetTableValue("supporter_pass_armory", "rewards_" .. player_id, armory or {})

	if Battlepass and Battlepass.ApplySupporterLoadout then
		Battlepass:ApplySupporterLoadout(player_id)
	end
end

function api:GetSupporterPassArmory(player_id)
	if not PlayerResource:IsValidPlayerID(player_id) then
		return {}
	end

	local steamid = tostring(PlayerResource:GetSteamID(player_id))
	local player = self.players and self.players[steamid] or nil
	local supporter_pass = player and player.supporter_pass or nil
	return supporter_pass and supporter_pass.armory or {}
end

function api:GetSupporterPassLoadout(player_id)
	if not PlayerResource:IsValidPlayerID(player_id) then
		return {}
	end

	local steamid = tostring(PlayerResource:GetSteamID(player_id))
	local player = self.players and self.players[steamid] or nil
	local supporter_pass = player and player.supporter_pass or nil
	if supporter_pass and supporter_pass.loadout then
		return supporter_pass.loadout
	end

	return player and player.armory or {}
end

function api:GrantSupporterFragments(player_id, amount, reason, idempotency_key, callback)
	if callback == nil then
		callback = function() end
	end

	if self:HasXHSBotSession() then
		return callback(false, {
			code = "xhs_bot_session",
			message = "Persistent rewards are disabled for XHS bot sessions.",
		})
	end

	local steamid = self:GetPersistentPlayerSteamID(player_id)
	if steamid == nil then
		return callback(false, { code = "non_persistent_player", message = "Persistent human player required." })
	end

	local payload = {
		game_id = api:GetApiGameId(),
		match_id = api:GetMatchID(),
		steam_id = steamid,
		player_id = player_id,
		amount = amount,
		reason = reason,
		idempotency_key = idempotency_key,
		gamemode = api:GetCustomGamemode(),
	}

	api:Request("supporter-fragments/grant", function(data)
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

	local steamid = self:GetPersistentPlayerSteamID(player_id)
	if steamid == nil then
		return callback(false, { code = "non_persistent_player", message = "Persistent human player required." })
	end

	local payload = {
		steamid = steamid,
	}

	if settings.toggle_tag ~= nil then payload.toggle_tag = settings.toggle_tag == true or settings.toggle_tag == 1 end
	if settings.pass_rewards ~= nil then payload.pass_rewards = settings.pass_rewards == true or settings.pass_rewards == 1 end
	if settings.player_xp ~= nil then payload.player_xp = settings.player_xp == true or settings.player_xp == 1 end
	if settings.winrate_toggle ~= nil then payload.winrate_toggle = settings.winrate_toggle == true or settings.winrate_toggle == 1 end
	if settings.xhs_ingame_advertize_hidden ~= nil then payload.xhs_ingame_advertize_hidden = settings.xhs_ingame_advertize_hidden == true or settings.xhs_ingame_advertize_hidden == 1 end

	api:Request("supporter-pass/settings", function(data)
		if api.players and api.players[steamid] then
			if data.toggle_tag ~= nil then api.players[steamid].toggle_tag = data.toggle_tag elseif settings.toggle_tag ~= nil then api.players[steamid].toggle_tag = settings.toggle_tag end
			if data.bp_rewards ~= nil then api.players[steamid].bp_rewards = data.bp_rewards end
			if data.pass_rewards ~= nil then
				api.players[steamid].pass_rewards = data.pass_rewards
				api.players[steamid].bp_rewards = data.pass_rewards
			elseif settings.pass_rewards ~= nil then
				api.players[steamid].pass_rewards = settings.pass_rewards
				api.players[steamid].bp_rewards = settings.pass_rewards
			end
			if data.player_xp ~= nil then api.players[steamid].player_xp = data.player_xp elseif settings.player_xp ~= nil then api.players[steamid].player_xp = settings.player_xp end
			if data.winrate_toggle ~= nil then
				api.players[steamid].winrate = data.winrate_toggle and 1 or 0
				api.players[steamid].winrate_toggle = data.winrate_toggle
			elseif settings.winrate_toggle ~= nil then
				api.players[steamid].winrate = settings.winrate_toggle and 1 or 0
				api.players[steamid].winrate_toggle = settings.winrate_toggle
			end
			if data.xhs_ingame_advertize_hidden ~= nil then
				api.players[steamid].xhs_ingame_advertize_hidden = data.xhs_ingame_advertize_hidden
			elseif settings.xhs_ingame_advertize_hidden ~= nil then
				api.players[steamid].xhs_ingame_advertize_hidden = settings.xhs_ingame_advertize_hidden
			end
			if api.players[steamid].xhs_ingame_advertize_hidden ~= nil then
				api.players[steamid].supporter_pass = api.players[steamid].supporter_pass or {}
				api.players[steamid].supporter_pass.settings = api.players[steamid].supporter_pass.settings or {}
				api.players[steamid].supporter_pass.settings.xhs_ingame_advertize_hidden = api.players[steamid].xhs_ingame_advertize_hidden
			end
		end

		callback(true, data)
	end, function(error)
		callback(false, error)
	end, "POST", payload)
end

function api:RequestSupporterPassAsset(player_id, asset, callback)
	callback = callback or function() end
	local steamid = self:GetPersistentPlayerSteamID(player_id)
	if steamid == nil then
		return callback(false, { code = "non_persistent_player", message = "Persistent human player required." })
	end

	asset = type(asset) == "table" and asset or {}
	self:Request("supporter-pass/asset-request", function(data)
		callback(true, data or {})
	end, function(error)
		callback(false, error or { message = "Feature request failed." })
	end, "POST", {
		steamid = steamid,
		game_id = self:GetApiGameId(),
		match_id = self:GetMatchID(),
		request_id = tostring(asset.request_id or ""),
		request_type = tostring(asset.request_type or ""),
		category = tostring(asset.category or ""),
		asset_id = tostring(asset.asset_id or ""),
		item_def = asset.item_def,
		unit_name = asset.unit_name,
		model = asset.model,
		display_name = asset.display_name,
	})
end

function api:BuySupporterPassShopItem(player_id, item_id, callback)
	if callback == nil then
		callback = function() end
	end

	local steamid = self:GetPersistentPlayerSteamID(player_id)
	if steamid == nil then
		return callback(false, { code = "non_persistent_player", message = "Persistent human player required." })
	end

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

	if self:HasXHSBotSession() then
		return callback(false, {
			code = "xhs_bot_session",
			message = "Persistent rewards are disabled for XHS bot sessions.",
		})
	end

	local steamid = self:GetPersistentPlayerSteamID(player_id)
	if steamid == nil then
		return callback(false, { code = "non_persistent_player", message = "Persistent human player required." })
	end

	local payload = {
		steamid = steamid,
		reward_id = reward_id,
	}

	local syncState = GetSupporterClaimSyncState(steamid)
	local _, requestPass, requestClaims = GetSupporterClaimPlayerState(steamid)
	local requestSeason = GetSupporterClaimSeasonFromPass(requestPass)
		or syncState.season_key
		or InferSupporterClaimSeasonKey(requestClaims)
		or InferSupporterClaimSeasonKey({ [tostring(reward_id)] = true })

	api:Request("supporter-pass/claim-reward", function(data)
		data = data or {}
		local currentState = GetSupporterClaimSyncState(steamid)
		currentState.mutation_revision = currentState.mutation_revision + 1

		local player, currentPass, currentClaims = GetSupporterClaimPlayerState(steamid)
		local currentSeason = GetSupporterClaimSeasonFromPass(currentPass)
			or currentState.season_key
			or InferSupporterClaimSeasonKey(currentClaims)
		local responseClaims = CollectSupporterClaimIDs(
			GetSupporterClaimPayload(data, {})
		)
		local responseSeason = GetSupporterClaimSeasonFromResponse(data)
			or InferSupporterClaimSeasonKey(responseClaims)
			or requestSeason
			or InferSupporterClaimSeasonKey({ [tostring(reward_id)] = true })

		api:MergeSupporterPassResponse(steamid, data)
		player = api.players and api.players[steamid] or player
		if player ~= nil then
			player.supporter_pass = player.supporter_pass or {}
			local claimed = {}
			if currentSeason ~= nil
			and responseSeason ~= nil
			and currentSeason == responseSeason
			then
				MergeSupporterClaimIDs(claimed, currentClaims)
			end
			MergeSupporterClaimIDs(claimed, responseClaims)
			claimed[tostring(reward_id)] = true
			player.supporter_pass.claimed_rewards = claimed
		end
		currentState.season_key = responseSeason

		local playerStillBound = IsSupporterClaimPlayerStillBound(player_id, steamid)
		if playerStillBound and data.armory then
			api:PublishSupporterPassArmory(player_id, data.armory)
		end

		if playerStillBound and SupporterPass and SupporterPass.PublishPlayer then
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

	local steamid = self:GetPersistentPlayerSteamID(player_id)
	if steamid == nil then
		return callback(false, { code = "non_persistent_player", message = "Persistent human player required." })
	end

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

		callback(true, data)
	end, function(error)
		callback(false, error)
	end, "POST", payload)
end

function api:UnequipSupporterPassItem(player_id, hero, slot_id, callback)
	if callback == nil then
		callback = function() end
	end

	local steamid = self:GetPersistentPlayerSteamID(player_id)
	if steamid == nil then
		return callback(false, { code = "non_persistent_player", message = "Persistent human player required." })
	end

	local payload = {
		steamid = steamid,
		hero = hero,
		slot_id = slot_id,
	}

	api:Request("supporter-pass/unequip", function(data)
		api:MergeSupporterPassResponse(steamid, data)

		if data.armory then
			api:PublishSupporterPassArmory(player_id, data.armory)
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

function api:HasLocalBackendKey()
	if not IsInToolsMode() or IsDedicatedServer() then
		return false
	end

	local key_values = LoadKeyValues("scripts/vscripts/components/api/backend_key.kv")
	local server_key = type(key_values) == "table" and key_values.server_key or nil
	return type(server_key) == "string" and string.len(server_key) > 0
end

function api:SetBackendTestGameTime(value)
	if not self:HasLocalBackendKey() then
		self.backend_test_game_time = nil
		return false, "local backend key missing; simulation disabled"
	end

	local seconds = tonumber(value)
	if seconds == nil then
		return false, "usage: xhs_backend_test_game_time <seconds>; use 0 to disable"
	end

	seconds = math.floor(seconds)
	if seconds <= 0 then
		self.backend_test_game_time = nil
		return true, "production XP simulation disabled"
	end

	self.backend_test_game_time = math.min(seconds, 28800)
	return true, "production XP simulation enabled with game_time="
		.. tostring(self.backend_test_game_time)
end

function api:GetBackendTestGameTime()
	if not self:HasLocalBackendKey() then
		return nil
	end

	local seconds = tonumber(self.backend_test_game_time)
	if seconds == nil or seconds <= 0 then
		return nil
	end
	return math.floor(seconds)
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
		local steamid = self:GetPersistentPlayerSteamID(id)
		if steamid ~= nil then
			table.insert(players, steamid)
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
	local player_id = nil
	local source_index = nil

	if type(event_source_index) == "number" or type(event_source_index) == "string" then
		source_index = tonumber(event_source_index)
	end

	if source_index ~= nil and source_index >= 0
		and CustomGameEventManager ~= nil
		and CustomGameEventManager.GetPlayerIDFromEventSourceIndex ~= nil then
		local ok, sender_player_id = pcall(function()
			return CustomGameEventManager:GetPlayerIDFromEventSourceIndex(source_index)
		end)

		if ok then
			local resolved_player_id = tonumber(sender_player_id)
			if resolved_player_id ~= nil and resolved_player_id >= 0 then
				player_id = resolved_player_id
			end
		end
	elseif source_index ~= nil and source_index > 0 then
		-- Compatibility fallback for engine builds without
		-- GetPlayerIDFromEventSourceIndex. Never trust payload.PlayerID.
		local ok, sender_player_id = pcall(function()
			local sender = EntIndexToHScript(source_index)
			if sender ~= nil and sender.GetPlayerID then
				return sender:GetPlayerID()
			end
			return nil
		end)

		if ok then
			local resolved_player_id = tonumber(sender_player_id)
			if resolved_player_id ~= nil and resolved_player_id >= 0 then
				player_id = resolved_player_id
			end
		end
	end

	if player_id == nil then
		return nil
	end

	local valid_ok, valid_player_id = pcall(function()
		return PlayerResource:IsValidPlayerID(player_id)
	end)

	if not valid_ok or not valid_player_id then
		return nil
	end

	return player_id
end

function api:SendLoadingScreenApiResponse(player_id, request_id, ok, data, message)
	local player_ok, player = pcall(function()
		return PlayerResource:GetPlayer(player_id)
	end)
	if not player_ok or player == nil then
		return
	end

	local send_ok, send_err = pcall(function()
		CustomGameEventManager:Send_ServerToPlayer(player, "loading_screen_api_response", {
			request_id = request_id or "",
			ok = ok and 1 or 0,
			data = data or {},
			message = message or "",
		})
	end)
end

function api:IsLoadingScreenApiRateLimited(player_id, request_type)
	self.loading_screen_api_last_request = self.loading_screen_api_last_request or {}

	local key = tostring(player_id) .. ":" .. tostring(request_type)
	local now = 0
	local ok, game_time = pcall(function()
		return GameRules:GetGameTime()
	end)
	if ok and tonumber(game_time) ~= nil then
		now = tonumber(game_time)
	elseif Time ~= nil then
		now = Time()
	end
	local last_request = self.loading_screen_api_last_request[key]

	if last_request ~= nil and now - last_request < 0.5 then
		return true
	end

	self.loading_screen_api_last_request[key] = now
	return false
end

function api:OnLoadingScreenApiRequest(event_source_index, keys)
	local ok = xpcall(function()
		api.OnLoadingScreenApiRequestSafe(api, event_source_index, keys)
	end, function(error_message)
		return tostring(error_message)
	end)
end

function api:OnLoadingScreenApiRequestSafe(event_source_index, keys)
	local payload = keys

	if type(event_source_index) == "table" and type(payload) ~= "table" then
		payload = event_source_index
		event_source_index = nil
	end

	if type(payload) ~= "table" then
		return
	end

	local player_id = nil
	local ok, resolved_player_id = pcall(function()
		return self:GetEventPlayerID(event_source_index, payload)
	end)

	if ok then
		player_id = resolved_player_id
	end

	if player_id == nil then
		return
	end

	local valid_ok, valid_player_id = pcall(function()
		return PlayerResource:IsValidPlayerID(player_id)
	end)
	if not valid_ok or not valid_player_id then
		return
	end

	local request_id = tostring(payload.request_id or "")
	if request_id == "" then
		return
	end

	local request_type = tostring(payload.request_type or "")
	local rate_limit_ok, is_rate_limited = pcall(function()
		return self:IsLoadingScreenApiRateLimited(player_id, request_type)
	end)
	if rate_limit_ok and is_rate_limited then
		self:SendLoadingScreenApiResponse(player_id, request_id, false, {}, "rate limited")
		return
	end

	if request_type == "loading-screen-info" then
		if self.loading_screen_info_cache ~= nil then
			self:SendLoadingScreenApiResponse(player_id, request_id, true, { data = self.loading_screen_info_cache })
			return
		end

		local request_ok = pcall(function()
			self:Request("loading-screen-info", function(data)
				self.loading_screen_info_cache = data
				self:SendLoadingScreenApiResponse(player_id, request_id, true, { data = data })
			end, function()
				self:SendLoadingScreenApiResponse(player_id, request_id, false, {}, "loading-screen-info failed")
			end)
		end)

		if not request_ok then
			self:SendLoadingScreenApiResponse(player_id, request_id, false, {}, "loading-screen-info failed")
		end
		return
	end

	self:SendLoadingScreenApiResponse(player_id, request_id, false, {}, "unknown request")
end

-- Core
function api:Request(endpoint, okCallback, failCallback, method, payload)
	local request_started_at = Time()
	local encoded_payload_size = 0
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

	local request_url = self:GetUrl(endpoint)
	local request = CreateHTTPRequestScriptVM(method, request_url)

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
			encoded_payload_size = string.len(encoded or "")
			request:SetHTTPRequestRawPostBody("application/json", encoded)
		end
	end

	request:Send(function(result)
		-- print(result)
		local code = result.StatusCode;
		local response_body = tostring(result.Body or "")
		if endpoint == "game-register" or endpoint == "game-complete" or endpoint == "performance" then
			local elapsed_ms = math.floor(math.max(Time() - request_started_at, 0) * 1000)
			print("[XHS HTTP] destination=" .. tostring(request_url)
				.. " | method=" .. tostring(method)
				.. " | status=" .. tostring(code or 0)
				.. " | elapsed=" .. tostring(elapsed_ms) .. "ms"
				.. " | request=" .. tostring(encoded_payload_size) .. "B"
				.. " | response=" .. tostring(string.len(response_body)) .. "B")
		end

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
			-- Express' default 403/404 responses can be empty or HTML when a
			-- deployment is missing a route. Do not report those transport errors
			-- as malformed JSON: that hides the actionable HTTP status from Tools.
			if response_body == "" then
				return fail("HTTP " .. tostring(code) .. " returned an empty response")
			end

			local obj, pos, err = json.decode(response_body)

			if err then
				if code >= 400 then
					return fail("HTTP " .. tostring(code) .. " returned a non-JSON response")
				end
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
	local locked_bot_session = IsInToolsMode()
		and XHSBots ~= nil
		and XHSBots.enabled == true
		and XHSBots.locked == true
		and self:HasXHSBotSession()

	-- Defense in depth for future/direct callers. The normal deferred flow
	-- handles local API readiness itself and never reaches this branch.
	if self.xhs_bot_session_backend_disabled == true or locked_bot_session then
		print("game-register: rejected for a locked local XHS bot session.")
		return false, "xhs_bot_session"
	end

	self.game_register_state = "pending"
	self:Request("game-register", function(data)
		api.game_id = tonumber(data.game_id)
		if api.game_id == nil or api.game_id <= 0 then
			api.game_id = nil
			api.game_register_state = "failed"
			print("game-register: backend returned an invalid game_id")
			return
		end
		api.game_register_state = "ready"
		print("game-register: ready with game_id=" .. tostring(api.game_id))
		api.players = data.players
		api.companions = data.companions or nil
		api.emblems = data.emblems or nil
		api.effigies = data.effigies or data.statues or nil
		api.disabled_heroes = data.disabled_heroes or nil
		api.supporter_pass = data.supporter_pass or nil
		api.custom_polls = data.custom_polls or nil

		CustomNetTables:SetTableValue("supporter_pass_player", "companions", api.companions)
		CustomNetTables:SetTableValue("supporter_pass_player", "emblems", api.emblems)
		CustomNetTables:SetTableValue("supporter_pass_player", "effigies", api.effigies)

		if data.supporter_pass and data.supporter_pass.shop then
			CustomNetTables:SetTableValue("supporter_pass_shop", "featured", data.supporter_pass.shop)
		end

		if SupporterPass and SupporterPass.PublishPlayers then
			SupporterPass:PublishPlayers()
		end

		if CustomPolls and CustomPolls.SetBackendPayload then
			CustomPolls:SetBackendPayload(api.custom_polls)
		end

		for player_id = 0, PlayerResource:GetPlayerCount() - 1 do
			if api:IsPersistentPlayerID(player_id) then
				api:PublishSupporterPassArmory(player_id)
				api:RefreshSupporterPassClaims(player_id)
			end
		end

		if IsInToolsMode() then
			for player_id = 0, PlayerResource:GetPlayerCount() - 1 do
				local steamid = api:GetPersistentPlayerSteamID(player_id)
				if steamid ~= nil then
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
	end, function(error_data)
		api.game_id = nil
		api.game_register_state = "failed"
		print("game-register: failed; persistent completion disabled for this match ("
			.. tostring(error_data and error_data.message or "unknown error") .. ")")
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

function api:SubmitCustomPollVote(player_id, poll_id, option_id, callback)
	if callback == nil then
		callback = function() end
	end

	local steamid = self:GetPersistentPlayerSteamID(player_id)
	if steamid == nil then
		callback(false, { code = "non_persistent_player", message = "Persistent human player required." })
		return
	end

	self:Request("custom-polls/vote", function(data)
		callback(true, data or {})
	end, function(err)
		callback(false, err or { message = "Vote backend unavailable." })
	end, "POST", {
		game_id = api:GetApiGameId(),
		match_id = api:GetMatchID(),
		steamid = steamid,
		poll_id = tostring(poll_id or ""),
		option_id = tostring(option_id or ""),
	})
end

function api:ProcessCompletedGame(data, payload, skipWinner)
	local game_id = payload.game_id or api:GetApiGameId() or api:GetMatchID()
	local match_id = payload.match_id or api:GetMatchID()
	local gamemode = payload.gamemode or api:GetCustomGamemode()
	local game_type = payload.game_type or CUSTOM_GAME_TYPE

	local function MergeCompletedPlayers(response)
		if type(response) ~= "table" then
			return
		end

		local response_players = response.players
		if response_players == nil and type(response.data) == "table" then
			response_players = response.data.players
		end
		if type(response_players) ~= "table" then
			return
		end

		api.players = api.players or {}

		for key, player_data in pairs(response_players) do
			if type(player_data) == "table" then
				local steamid = tostring(player_data.steamid or player_data.steam_id or player_data.steamID or key)
				api.players[steamid] = api.players[steamid] or {}

				for field, value in pairs(player_data) do
					api.players[steamid][field] = value
				end

				if api.MergeSupporterPassResponse then
					api:MergeSupporterPassResponse(steamid, player_data)
				end
			end
		end
	end

	MergeCompletedPlayers(data)
	if SupporterPass and SupporterPass.PublishPlayers then
		SupporterPass:PublishPlayers()
	end

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

	if not skipWinner then
		local winner_team = GAME_WINNER_TEAM
		Timers:CreateTimer(0.5, function()
			GameRules:SetGameWinner(winner_team, true)
		end)
	end
end

function api:CompleteGame()
	print("CompleteGame")
	local players = {}
	local backend_players = {}
	local has_xhs_bot_session = self:HasXHSBotSession()
	if has_xhs_bot_session
		and XHSBotDecisionAudit ~= nil
		and type(XHSBotDecisionAudit.Finalize) == "function" then
		local auditCallOK, auditOK, auditMessage = pcall(function()
			return XHSBotDecisionAudit:Finalize("complete_game")
		end)
		if not auditCallOK then
			print("[XHSBots][AUDIT] type=finalize_error reason=complete_game error="
				.. tostring(auditOK))
		elseif auditOK == false and auditMessage ~= "audit_already_finalized" then
			print("[XHSBots][AUDIT] type=finalize_error reason=complete_game error="
				.. tostring(auditMessage))
		end
	end

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

	local function GetEndScreenHeroPlayerID(hero)
		if hero == nil or hero:IsNull() or not hero:IsRealHero() then
			return nil
		end

		if XHSGetPlayerIDFromUnit ~= nil then
			local playerID = XHSGetPlayerIDFromUnit(hero)
			if playerID ~= nil then
				return playerID
			end
		end

		if hero.GetPlayerID ~= nil then
			local playerID = hero:GetPlayerID()
			if playerID ~= nil and playerID >= 0 and PlayerResource:IsValidPlayerID(playerID) then
				return playerID
			end
		end

		return nil
	end

	local function IsEndScreenHero(hero, playerID)
		return GetEndScreenHeroPlayerID(hero) == playerID
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
		if PlayerResource:IsValidPlayerID(id)
			and not IsApiSpectatorPlayerID(id) then
			local items = {}
			local heroEntity = ResolveEndScreenHero(id)
			local hero = json.null
			local networth = 0
			local gold_earned = XHSGetEndScreenStat ~= nil and XHSGetEndScreenStat(id, "gold_earned") or 0
			local healing = PlayerResource:GetHealing(id)
			local boss_damage = XHSGetEndScreenStat ~= nil and XHSGetEndScreenStat(id, "boss_damage") or 0
			local damage_taken = XHSGetEndScreenStat ~= nil and XHSGetEndScreenStat(id, "damage_taken") or 0
			local self_healing = XHSGetEndScreenStat ~= nil and XHSGetEndScreenStat(id, "self_healing") or 0
			local tracked_potions_used = XHSGetPotionUses ~= nil and XHSGetPotionUses(id) or 0
			local end_screen_potions_used = XHSGetEndScreenStat ~= nil and XHSGetEndScreenStat(id, "potions_used") or 0
			local potions_used = math.max(tracked_potions_used, end_screen_potions_used, CountPlayerZoneStat(id, "Potions"))
			local damage_done_to_heroes = 0
			local damage_done_to_buildings = 0
			local kills_done_to_hero = {}
			local items_bought = {}
			local abandon = false
			local connection_state = tonumber(PlayerResource:GetConnectionState(id)) or 0
			local disconnected = connection_state ~= 2
			local leaderboard = {}
			local support_items = {}
			local abilities_level_up_order = {}
			local tracked_tome_stats_bonus = XHSGetTomeStats ~= nil and XHSGetTomeStats(id) or 0
			local end_screen_tome_stats_bonus = XHSGetEndScreenStat ~= nil and XHSGetEndScreenStat(id, "tome_stats_bonus") or 0
			local tome_stats_bonus = math.max(tracked_tome_stats_bonus, end_screen_tome_stats_bonus)

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

			local is_persistent_player = self:IsPersistentPlayerID(id)
			local is_xhs_bot = self:IsXHSBotParticipant(id)
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
				gold_earned = gold_earned,
				healing = healing,
				boss_damage = boss_damage,
				damage_taken = damage_taken,
				self_healing = self_healing,
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
				connection_state = connection_state,
				disconnected = disconnected,
				leaderboard = leaderboard,
				participant_kind = is_xhs_bot and "xhs_bot" or (is_persistent_player and "human" or "non_persistent"),
				is_xhs_bot = is_xhs_bot and 1 or 0,
			}

			local steamid = tostring(PlayerResource:GetSteamID(id))
			local local_player_key = steamid

			if local_player_key == "0" then
				local_player_key = tostring(id)
			end

			players[local_player_key] = player
			if is_persistent_player then
				local persistent_steamid = self:GetPersistentPlayerSteamID(id)
				if persistent_steamid ~= nil then
					backend_players[persistent_steamid] = player
				end
			end
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

	local api_game_id = tonumber(self:GetApiGameId())
	if api_game_id ~= nil and api_game_id <= 0 then
		api_game_id = nil
	end

	local fragment_quests = FragmentQuests ~= nil and FragmentQuests:BuildAnalyticsPayload() or nil
	local performance_summary = XHSPerformanceTelemetry ~= nil
		and XHSPerformanceTelemetry:Finalize()
		or nil
	local backend_fragment_quests = fragment_quests
	if type(fragment_quests) == "table" then
		backend_fragment_quests = {}
		for key, value in pairs(fragment_quests) do
			backend_fragment_quests[key] = value
		end

		backend_fragment_quests.players = {}
		for _, contribution in pairs(fragment_quests.players or {}) do
			if type(contribution) == "table" and self:IsPersistentPlayerID(contribution.player_id) then
				table.insert(backend_fragment_quests.players, contribution)
			end
		end

		backend_fragment_quests.events = {}
		for _, event in ipairs(fragment_quests.events or {}) do
			local event_player_id = type(event) == "table"
				and type(event.data) == "table"
				and event.data.player_id
				or nil
			if event_player_id == nil or self:IsPersistentPlayerID(event_player_id) then
				table.insert(backend_fragment_quests.events, event)
			end
		end
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
		difficulty = api:GetCustomDifficulty(),
		mod_version = tostring(GAME_VERSION or ""),
		rosh_lvl = rosh_lvl,
		rosh_hp = rosh_hp,
		rosh_max_hp = rosh_max_hp,
		cheat_mode = self:IsCheatGame(),
		map = GetMapName(),
		fragment_quests = fragment_quests,
		performance_summary = performance_summary,
		contains_xhs_bots = self:HasXHSBotParticipants(),
		xhs_bot_count = self:GetXHSBotParticipantCount(),
		persistent_rewards_eligible = not has_xhs_bot_session,
	}
	local backend_payload = {}
	for key, value in pairs(payload) do
		backend_payload[key] = value
	end
	backend_payload.players = backend_players
	backend_payload.fragment_quests = backend_fragment_quests
	local backend_test_game_time = self:GetBackendTestGameTime()
	if backend_test_game_time ~= nil then
		backend_payload.game_time = backend_test_game_time
		print("game-complete: authenticated game time override enabled with game_time="
			.. tostring(backend_test_game_time))
	end
	local completed_display_payload = {}
	for key, value in pairs(payload) do
		completed_display_payload[key] = value
	end
	completed_display_payload.game_time = backend_payload.game_time

	-- A private Tools bot run must not alter account XP, win rate, quests, or
	-- any other persistent human result. Keep the complete marked local
	-- snapshot, but do not submit the match-complete payload at all.
	if has_xhs_bot_session then
		print("game-complete: skipped backend request for an XHS bot session.")
		if FragmentQuests ~= nil then
			FragmentQuests:OnBackendComplete(false, { code = "xhs_bot_session" })
		end
		self:ProcessCompletedGame({}, payload)
		return
	end

	if next(backend_players) == nil then
		print("game-complete: skipped backend request because no persistent human player is present.")
		if FragmentQuests ~= nil then
			FragmentQuests:OnBackendComplete(false, { code = "no_persistent_players" })
		end
		self:ProcessCompletedGame({}, payload)
		return
	end

	if api_game_id == nil then
		print("game-complete: skipped backend request because game-register has no valid game_id (state="
			.. tostring(self.game_register_state or "unknown") .. ").")
		if FragmentQuests ~= nil then
			FragmentQuests:OnBackendComplete(false, { code = "game_not_registered" })
		end
		self:ProcessCompletedGame({}, payload)
		return
	end

	local outbound_players = {}
	for steamid, player_data in pairs(backend_players) do
		outbound_players[tostring(steamid)] = {
			team = player_data.team,
			abandon = player_data.abandon,
			disconnected = player_data.disconnected,
			connection_state = player_data.connection_state,
		}
	end
	print("[XHS game-complete] outbound " .. json.encode({
		game_id = backend_payload.game_id,
		game_time = backend_payload.game_time,
		winner = backend_payload.winner,
		cheat_mode = backend_payload.cheat_mode,
		players = outbound_players,
	}))

	self:Request("game-complete", function(data)
			print("game-complete: Game complete successful!")
			local inbound_players = {}
			for steamid, player_data in pairs(data.players or {}) do
				inbound_players[tostring(steamid)] = {
					xp = player_data.xp,
					xp_change = player_data.xp_change,
					duration_xp = player_data.duration_xp,
					victory_xp_bonus = player_data.victory_xp_bonus,
					xp_boost = player_data.xp_boost,
					xp_bonus = player_data.xp_bonus,
					xp_eligible = player_data.xp_eligible,
					xp_ineligible_reason = player_data.xp_ineligible_reason,
				}
			end
			print("[XHS game-complete] inbound " .. json.encode({
				completion = data.completion,
				players = inbound_players,
			}))
			if FragmentQuests ~= nil then
				FragmentQuests:OnBackendComplete(true, data)
			end
			api:ProcessCompletedGame(data, completed_display_payload)
		end,

		function(data)
			print("game-complete: Error on game complete!")
			print(data)
			if FragmentQuests ~= nil then
				FragmentQuests:OnBackendComplete(false, data)
			end
			api:ProcessCompletedGame(data, payload)
		end,
		"POST", backend_payload
	)
end

function api:DiretideHallOfFame(successCallback, failCallback)
	if self:HasXHSBotSession() then
		if failCallback ~= nil then
			failCallback({
				code = "xhs_bot_session",
				message = "Leaderboard persistence is disabled for XHS bot sessions.",
			})
		end
		return false
	end

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

function api:SetCompanion(event_source_index, data)
	if type(event_source_index) == "table" and type(data) ~= "table" then
		data = event_source_index
		event_source_index = nil
	end
	data = data or {}

	local player_id = self:GetEventPlayerID(event_source_index, data)
	local player = player_id ~= nil and PlayerResource:GetPlayer(player_id) or nil
	local steamid = self:GetPersistentPlayerSteamID(player_id)
	if steamid == nil then
		if player ~= nil then
			CustomGameEventManager:Send_ServerToPlayer(player, "change_companion_failure", {
				code = "non_persistent_player",
			})
		end
		return false
	end

	local unit_name = data.sUnitName

	local payload = {
		companion_id = data.companion_id,
		steamid = steamid,
	}

	api:Request("modify-companion", function(data)
			Battlepass:DonatorCompanion(player_id, unit_name, true)
		end,
		function(data)
			if player ~= nil then
				CustomGameEventManager:Send_ServerToPlayer(player, "change_companion_failure", {})
			end
		end, "POST", payload)
	return true
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
