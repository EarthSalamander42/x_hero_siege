SupporterPass = SupporterPass or class({})

SupporterPass.DAILY_FRAGMENT_CAP = 100
SupporterPass.WEEKLY_FRAGMENT_CAP = SupporterPass.DAILY_FRAGMENT_CAP
SupporterPass.SEASON_XP_PER_LEVEL = 1000

local function FirstSupporterValue(...)
	for i = 1, select("#", ...) do
		local value = select(i, ...)
		if value ~= nil then
			return value
		end
	end

	return nil
end

local function CopySupporterTable(source)
	local copy = {}
	if type(source) ~= "table" then
		return copy
	end

	for key, value in pairs(source) do
		copy[key] = value
	end
	return copy
end

local function BuildPublishedSupporterLoadout(items)
	local published = {}
	for _, item in ipairs(type(items) == "table" and items or {}) do
		if type(item) == "table" then
			table.insert(published, {
				id = item.id or item.item_id or item.catalog_item_id,
				item_id = item.item_id or item.catalog_item_id or item.id,
				catalog_item_id = item.catalog_item_id or item.item_id or item.id,
				name = item.name or item.item_name,
				item_name = item.item_name or item.name,
				type = item.type or item.item_type or item.slot_id,
				item_type = item.item_type or item.type or item.slot_id,
				slot_id = item.slot_id or item.item_type or item.type,
				rarity = item.rarity or item.item_rarity,
				item_rarity = item.item_rarity or item.rarity,
				image = item.image or item.image_inventory,
				image_inventory = item.image_inventory or item.image,
			})
		end
	end
	return published
end

local function GetBackendSeasonRecord(supporterPass)
	local playerSeason = type(supporterPass) == "table"
		and supporterPass.season
		or nil
	if type(playerSeason) == "table" and next(playerSeason) ~= nil then
		return playerSeason
	end
	if playerSeason ~= nil and tostring(playerSeason) ~= "" then
		return playerSeason
	end

	local globalSeason = api
		and api.supporter_pass
		and api.supporter_pass.season
		or nil
	return globalSeason
end

local function IsBackendSeasonReady(supporterPass)
	local seasonRecord = GetBackendSeasonRecord(supporterPass)
	local identity = type(seasonRecord) == "table"
		and (
			seasonRecord.season_id
			or seasonRecord.season_key
			or seasonRecord.key
			or seasonRecord.id
		)
		or seasonRecord
	if SupporterPass2026 ~= nil
	and SupporterPass2026.IsBackendSeason2026 ~= nil then
		local seasonMatches =
			SupporterPass2026:IsBackendSeason2026(seasonRecord)
		local globalSeason = api
			and api.supporter_pass
			and api.supporter_pass.season
			or nil
		local globalSeasonMatches =
			SupporterPass2026:IsBackendSeason2026(globalSeason)
		local seasonPublished =
			SupporterPass2026.IsBackendSeasonPublished == nil
			or SupporterPass2026:IsBackendSeasonPublished(
				seasonRecord
			) ~= false
		local globalSeasonPublished =
			SupporterPass2026.IsBackendSeasonPublished == nil
			or SupporterPass2026:IsBackendSeasonPublished(
				globalSeason
			) ~= false
		local catalogReady = SupporterPass2026.IsBackendCatalog2026Ready ~= nil
			and SupporterPass2026:IsBackendCatalog2026Ready(
				api and api.supporter_pass and api.supporter_pass.rewards
			)
			or nil
		return seasonMatches ~= false
			and globalSeasonMatches ~= false
			and seasonPublished
			and globalSeasonPublished
			and catalogReady == true,
			identity
	end
	return false, identity
end

local function RewardIdentity(reward, index, sourceName)
	if type(reward) ~= "table" then
		return sourceName .. ":" .. tostring(index)
	end

	local itemID = reward.item_id or reward.catalog_item_id
	if itemID ~= nil and tostring(itemID) ~= "" then
		local itemType = string.lower(tostring(reward.type or reward.item_type or reward.slot_id or "default"))
		return "item:" .. itemType .. ":" .. tostring(itemID)
	end

	local rewardID = reward.reward_id or reward.id
	if rewardID ~= nil and tostring(rewardID) ~= "" then
		return "reward:" .. tostring(rewardID)
	end

	return sourceName .. ":" .. tostring(index)
end

local function IsSupporterRewardRecord(value)
	return type(value) == "table" and (
		value.reward_id ~= nil
		or value.item_id ~= nil
		or value.catalog_item_id ~= nil
		or value.item_type ~= nil
		or value.type ~= nil
		or (value.id ~= nil and (value.name ~= nil or value.track ~= nil or value.level ~= nil or value.level_required ~= nil))
	)
end

local function CollectSupporterRewards(value, forcedTrack, result)
	result = result or {}
	if type(value) ~= "table" then return result end

	if IsSupporterRewardRecord(value) then
		local reward = CopySupporterTable(value)
		reward.track = reward.track or forcedTrack
		table.insert(result, reward)
		return result
	end

	if value.rewards ~= nil then
		CollectSupporterRewards(value.rewards, forcedTrack, result)
	end
	if value.free ~= nil then
		CollectSupporterRewards(value.free, "free", result)
	end
	if value.premium ~= nil then
		CollectSupporterRewards(value.premium, "premium", result)
	end

	local numericKeys = {}
	for key, nested in pairs(value) do
		if tonumber(key) ~= nil and type(nested) == "table" then
			table.insert(numericKeys, tonumber(key))
		end
	end
	table.sort(numericKeys)
	for _, numericKey in ipairs(numericKeys) do
		local nested = value[numericKey] or value[tostring(numericKey)]
		CollectSupporterRewards(nested, forcedTrack, result)
	end

	if #numericKeys == 0 and value.rewards == nil and value.free == nil and value.premium == nil then
		for _, nested in pairs(value) do
			if type(nested) == "table" then
				CollectSupporterRewards(nested, forcedTrack, result)
			end
		end
	end

	return result
end

local function MergeRewardTracks(legacyRewards, backendRewards, track)
	if SupporterPass2026 ~= nil and SupporterPass2026.MergeBackendTrack ~= nil then
		return SupporterPass2026:MergeBackendTrack(
			legacyRewards,
			CollectSupporterRewards(backendRewards),
			track
		)
	end

	local merged = {}
	local order = {}

	for index, reward in ipairs(legacyRewards or {}) do
		local normalized = CopySupporterTable(reward)
		normalized.track = track
		normalized.legacy = true
		normalized.claimable = false
		local key = RewardIdentity(normalized, index, "legacy")
		merged[key] = normalized
		table.insert(order, key)
	end

	for index, reward in ipairs(CollectSupporterRewards(backendRewards)) do
		if type(reward) == "table" and (reward.track or "free") == track then
			local normalized = CopySupporterTable(reward)
			normalized.track = track
			normalized.legacy = false
			local key = RewardIdentity(normalized, index, "backend")
			if merged[key] == nil then
				table.insert(order, key)
			else
				for field, value in pairs(merged[key]) do
					if normalized[field] == nil then
						normalized[field] = value
					end
				end
			end
			merged[key] = normalized
		end
	end

	local rewards = {}
	for _, key in ipairs(order) do
		table.insert(rewards, merged[key])
	end
	table.sort(rewards, function(a, b)
		return (tonumber(a.level_required or a.level) or 0) < (tonumber(b.level_required or b.level) or 0)
	end)
	return rewards
end

local function IsEarthwardenSupporterValue(tierName, tierColor, donatorStatus)
	local status = tonumber(donatorStatus) or 0
	if status == 8 or status == 9 then
		return true
	end

	local normalizedName = string.lower(tostring(tierName or ""))
	if string.find(normalizedName, "earthwarden", 1, true) ~= nil then
		return true
	end

	return string.lower(tostring(tierColor or "")) == "#c99cff"
end

local function NormalizeSeasonProgress(level, xp, xpMax)
	level = math.max(tonumber(level) or 1, 1)
	xp = math.max(tonumber(xp) or 0, 0)
	xpMax = math.max(tonumber(xpMax) or SupporterPass.SEASON_XP_PER_LEVEL, 1)

	local totalXP = xp
	if xp >= xpMax then
		local completedLevels = math.floor(xp / xpMax)
		xp = xp - completedLevels * xpMax
		level = math.max(level, 1 + completedLevels)
	end

	return level, xp, xpMax, totalXP
end

local function SeasonProgressTotal(level, xp, xpMax)
	level = math.max(tonumber(level) or 1, 1)
	xp = math.max(tonumber(xp) or 0, 0)
	xpMax = math.max(tonumber(xpMax) or SupporterPass.SEASON_XP_PER_LEVEL, 1)
	return ((level - 1) * xpMax) + xp
end

SupporterPass.TIERS = {
	[1] = {
		id = 1,
		name = "Donator",
		price = "$2",
		color = "#45C46B",
		fragments = 150,
		xp_boost = 10,
		vote_power = 2,
		companion_unlocks = 3,
		emblem_unlocks = 1,
		effigy_unlocks = 1,
	},
	[2] = {
		id = 2,
		name = "Golden Donator",
		price = "$5",
		color = "#F2C94C",
		fragments = 400,
		xp_boost = 20,
		vote_power = 3,
		companion_unlocks = 3,
		emblem_unlocks = 1,
		effigy_unlocks = 1,
	},
	[3] = {
		id = 3,
		name = "Ember Donator",
		price = "$10",
		color = "#E4572E",
		fragments = 900,
		xp_boost = 30,
		vote_power = 4,
		companion_unlocks = 3,
		emblem_unlocks = 1,
		effigy_unlocks = 1,
	},
	[4] = {
		id = 4,
		name = "Stoneguard Donator",
		price = "$20",
		color = "#5AD0FF",
		fragments = 1800,
		xp_boost = 40,
		vote_power = 5,
		companion_unlocks = 3,
		emblem_unlocks = 1,
		effigy_unlocks = 1,
	},
	[5] = {
		id = 5,
		name = "Earthwarden Donator",
		price = "$50",
		color = "#C99CFF",
		fragments = 1800,
		xp_boost = 40,
		vote_power = 5,
		companion_unlocks = 3,
		emblem_unlocks = 1,
		effigy_unlocks = 1,
		prestige = true,
	},
}

SupporterPass.STATUS_TO_TIER = DONATOR_STATUS_TO_TIER or {}

function SupporterPass:Init()
	self:PublishMeta()
	self:PublishFeaturedShop()
end

function SupporterPass:GetTierByID(tierID)
	return self.TIERS[tonumber(tierID) or 0]
end

function SupporterPass:GetTierForStatus(status)
	if GetDonatorVisualTier ~= nil then
		return GetDonatorVisualTier(status)
	end

	return self.STATUS_TO_TIER[tonumber(status) or 0] or 0
end

function SupporterPass:GetTierForPlayer(playerID)
	if api and api.GetPlayerSupporterTier then
		return api:GetPlayerSupporterTier(playerID)
	end

	if api and api.GetDonatorStatus then
		return self:GetTierForStatus(api:GetDonatorStatus(playerID))
	end

	return 0
end

function SupporterPass:GetTierName(tierID)
	local tier = self:GetTierByID(tierID)
	return tier and tier.name or "Free Player"
end

function SupporterPass:GetTierColor(tierID)
	local tier = self:GetTierByID(tierID)
	return tier and tier.color or "#7DB9D8"
end

function SupporterPass:PublishMeta()
	CustomNetTables:SetTableValue("supporter_pass_meta", "tiers", self.TIERS)
	if BuildDonatorColorMeta ~= nil then
		CustomNetTables:SetTableValue("game_options", "donator_colors", BuildDonatorColorMeta(self.TIERS))
	end
	CustomNetTables:SetTableValue("supporter_pass_meta", "economy", {
		season_length_months = 3,
		daily_fragment_cap = self.DAILY_FRAGMENT_CAP,
		weekly_fragment_cap = self.DAILY_FRAGMENT_CAP,
	})
end

function SupporterPass:PublishFeaturedShop()
	if api and api.supporter_pass and api.supporter_pass.shop then
		local shop = api.supporter_pass.shop
		CustomNetTables:SetTableValue("supporter_pass_shop", "featured", shop.featured or shop)
		return
	end

	CustomNetTables:SetTableValue("supporter_pass_shop", "featured", {
		items = {},
	})
end

function SupporterPass:BuildPlayerTable(playerID)
	if not PlayerResource:IsValidPlayerID(playerID) then
		return nil
	end

	local steamID = tostring(PlayerResource:GetSteamID(playerID))
	local current = CustomNetTables:GetTableValue("supporter_pass_player", tostring(playerID)) or {}
	local player = api and api.players and api.players[steamID] or {}
	local supporterPass = player.supporter_pass or {}
	local backendSeasonReady, backendSeasonID = IsBackendSeasonReady(supporterPass)
	local seasonStateAllowed = backendSeasonReady ~= false
	local season = seasonStateAllowed and (supporterPass.season or {}) or {}
	local seasonSupporterPass = seasonStateAllowed and supporterPass or {}
	local seasonCurrent = seasonStateAllowed and current or {}
	local account = supporterPass.account or {}
	local settings = supporterPass.settings or player.settings or {}
	local passTierID = tonumber(FirstSupporterValue(supporterPass.tier_id, current.tier_id)) or 0
	local rawDonatorStatus = api and api.GetDonatorStatus and api:GetDonatorStatus(playerID) or 0
	local isDeveloper = IsInToolsMode()
		and api ~= nil
		and api.IsDeveloper ~= nil
		and api:IsDeveloper(playerID)
	local donatorStatus = GetDonatorVisualStatus ~= nil and GetDonatorVisualStatus(rawDonatorStatus) or rawDonatorStatus
	local rawTierName = FirstSupporterValue(supporterPass.tier_name, current.tier_name)
	local rawTierColor = FirstSupporterValue(supporterPass.tier_color, current.tier_color)
	local botTierID = api and api.GetBotSupporterTier and api:GetBotSupporterTier(playerID) or 0
	if botTierID > 0 then
		passTierID = botTierID
		rawTierName = nil
		rawTierColor = nil
	end
	local statusTierID = botTierID > 0 and botTierID or self:GetTierForStatus(donatorStatus)

	if IsEarthwardenSupporterValue(rawTierName, rawTierColor, donatorStatus) then
		passTierID = math.max(passTierID, 5)
	end

	local tierID = math.max(passTierID, statusTierID)
	local tier = self:GetTierByID(tierID)
	local tierName = FirstSupporterValue(rawTierName, self:GetTierName(tierID))
	local tierColor = FirstSupporterValue(rawTierColor, self:GetTierColor(tierID))
	if IsEarthwardenSupporterValue(tierName, tierColor, donatorStatus) then
		tierID = math.max(tierID, 5)
		tier = self:GetTierByID(tierID)
		tierName = self:GetTierName(tierID)
		tierColor = self:GetTierColor(tierID)
	end
	local accountLevel = tonumber(FirstSupporterValue(account.level, player.account_level, player.xp_level, supporterPass.account_level, current.account_level)) or 0
	local xhsAccountLevel = tonumber(current.xhs_account_level) or 0
	if player.xp_level ~= nil then
		xhsAccountLevel = math.max((tonumber(player.xp_level) or 0) + 1, 1)
	end
	local xhsXP = tonumber(FirstSupporterValue(player.xp, current.xhs_xp)) or 0
	local xhsXPCurrent = tonumber(FirstSupporterValue(player.xp_in_level, current.xhs_xp_current)) or 0
	local xhsXPMax = tonumber(FirstSupporterValue(player.xp_next_level, current.xhs_xp_max)) or 0
	local seasonLevel = math.max(tonumber(FirstSupporterValue(season.level, seasonSupporterPass.season_level, seasonSupporterPass.level, seasonCurrent.season_level, seasonCurrent.Lvl)) or 1, 1)
	local seasonXP = tonumber(FirstSupporterValue(season.xp, seasonSupporterPass.season_xp, seasonSupporterPass.current_exp, seasonCurrent.season_xp, seasonCurrent.XP)) or 0
	local seasonXPMax = tonumber(FirstSupporterValue(season.xp_per_level, seasonSupporterPass.season_xp_max, seasonSupporterPass.xp_per_level, seasonCurrent.season_xp_max, seasonCurrent.MaxXP)) or self.SEASON_XP_PER_LEVEL
	local seasonTotalXP = seasonXP
	seasonLevel, seasonXP, seasonXPMax, seasonTotalXP = NormalizeSeasonProgress(seasonLevel, seasonXP, seasonXPMax)
	local explicitSeasonXPChange = tonumber(FirstSupporterValue(
		season.xp_change,
		season.gained_xp,
		seasonSupporterPass.season_xp_change,
		seasonSupporterPass.xp_change,
		seasonSupporterPass.gained_xp,
		seasonStateAllowed and player.supporter_pass_xp_change or nil,
		seasonStateAllowed and player.supporter_xp_change or nil
	))
	local seasonXPChange = explicitSeasonXPChange or 0
	if explicitSeasonXPChange == nil and (seasonCurrent.steamid ~= nil or seasonCurrent.season_xp ~= nil or seasonCurrent.XP ~= nil) then
		local currentLevel = tonumber(FirstSupporterValue(seasonCurrent.season_level, seasonCurrent.Lvl)) or 1
		local currentXP = tonumber(FirstSupporterValue(seasonCurrent.season_xp, seasonCurrent.XP)) or 0
		local currentXPMax = tonumber(FirstSupporterValue(seasonCurrent.season_xp_max, seasonCurrent.MaxXP)) or seasonXPMax
		seasonXPChange = SeasonProgressTotal(seasonLevel, seasonXP, seasonXPMax) - SeasonProgressTotal(currentLevel, currentXP, currentXPMax)
	end
	local baseXPChange = tonumber(FirstSupporterValue(season.base_xp_change, seasonSupporterPass.base_xp_change, seasonStateAllowed and player.base_xp_change or nil, seasonCurrent.base_xp_change)) or 0
	local xpBonus = tonumber(FirstSupporterValue(season.xp_bonus, seasonSupporterPass.xp_bonus, seasonStateAllowed and player.xp_bonus or nil, seasonCurrent.xp_bonus)) or 0
	local passRewards = FirstSupporterValue(settings.pass_rewards, player.pass_rewards)
	if passRewards == nil then
		passRewards = player.bp_rewards
	end
	local loadout = supporterPass.loadout or current.loadout
	local isBot = Battlepass ~= nil
		and Battlepass.IsSupporterBotPlayerID ~= nil
		and Battlepass:IsSupporterBotPlayerID(playerID)
	local equippedItems = {}
	if Battlepass ~= nil and Battlepass.GetEquippedSupporterItems ~= nil then
		local success, items = pcall(
			Battlepass.GetEquippedSupporterItems,
			Battlepass,
			playerID
		)
		if success and type(items) == "table" then
			equippedItems = BuildPublishedSupporterLoadout(items)
		end
	end
	if isBot then
		loadout = equippedItems
		passRewards = true
	end
	local supporterTitle = FirstSupporterValue(
		supporterPass.supporter_title,
		current.supporter_title
	)
	if Battlepass ~= nil and Battlepass.GetEquippedSupporterItem ~= nil then
		local success, titleItem = pcall(
			Battlepass.GetEquippedSupporterItem,
			Battlepass,
			playerID,
			"title"
		)
		if success and type(titleItem) == "table" then
			supporterTitle = FirstSupporterValue(
				titleItem.title_text,
				titleItem.supporter_title,
				supporterTitle
			)
		end
	end

	return {
		steamid = steamID,
		is_bot = isBot,
		XP = seasonXP,
		MaxXP = seasonXPMax,
		Lvl = seasonLevel,
		title = "Supporter Pass",
		donator_level = donatorStatus,
		raw_donator_level = rawDonatorStatus,
		is_developer = isDeveloper,
		tier_id = tierID,
		tier_name = tierName,
		tier_color = tierColor,
		fragments = tonumber(FirstSupporterValue(supporterPass.fragments, supporterPass.fragment_balance, current.fragments, current.fragment_balance)) or 0,
		daily_fragments = tonumber(FirstSupporterValue(supporterPass.daily_fragments, supporterPass.daily_earned, supporterPass.weekly_fragments, supporterPass.weekly_earned, current.daily_fragments, current.daily_earned, current.weekly_fragments, current.weekly_earned)) or 0,
		daily_cap = tonumber(FirstSupporterValue(supporterPass.daily_cap, supporterPass.weekly_cap, current.daily_cap, current.weekly_cap)) or self.DAILY_FRAGMENT_CAP,
		weekly_fragments = tonumber(FirstSupporterValue(supporterPass.daily_fragments, supporterPass.daily_earned, supporterPass.weekly_fragments, supporterPass.weekly_earned, current.daily_fragments, current.daily_earned, current.weekly_fragments, current.weekly_earned)) or 0,
		weekly_cap = tonumber(FirstSupporterValue(supporterPass.daily_cap, supporterPass.weekly_cap, current.daily_cap, current.weekly_cap)) or self.DAILY_FRAGMENT_CAP,
		monthly_fragments = tonumber(FirstSupporterValue(supporterPass.monthly_fragments, current.monthly_fragments)) or (tier and tier.fragments or 0),
		xp_boost = tonumber(FirstSupporterValue(supporterPass.xp_boost, current.xp_boost)) or (tier and tier.xp_boost or 0),
		vote_power = tonumber(FirstSupporterValue(
			supporterPass.vote_power,
			tier and tier.vote_power or nil,
			current.vote_power
		)) or math.max(1, math.min(tierID + 1, 5)),
		season_level = seasonLevel,
		season_xp = seasonXP,
		season_xp_max = seasonXPMax,
		season_total_xp = seasonTotalXP,
		season_id = SupporterPass2026 ~= nil and SupporterPass2026.SEASON_ID or "2026",
		backend_season_id = backendSeasonID,
		backend_season_ready = backendSeasonReady ~= false,
		season_xp_change = seasonXPChange,
		XP_change = seasonXPChange,
		base_xp_change = baseXPChange,
		xp_bonus = xpBonus,
		account_level = accountLevel,
		xhs_account_level = xhsAccountLevel,
		xhs_xp = xhsXP,
		xhs_xp_current = xhsXPCurrent,
		xhs_xp_max = xhsXPMax,
		account_title = FirstSupporterValue(account.title, current.account_title, "Supporter Pass"),
		supporter_title = supporterTitle,
		toggle_tag = FirstSupporterValue(settings.toggle_tag, player.toggle_tag, current.toggle_tag),
		pass_rewards = passRewards,
		bp_rewards = passRewards,
		player_xp = FirstSupporterValue(settings.player_xp, player.player_xp, current.player_xp),
		winrate = FirstSupporterValue(player.winrate, player.winrate_x_hero_siege, current.winrate),
		winrate_toggle = FirstSupporterValue(settings.winrate_toggle, player.winrate_toggle, current.winrate_toggle),
		xhs_ingame_advertize_hidden = FirstSupporterValue(settings.xhs_ingame_advertize_hidden, settings.ingame_advertize_hidden, player.xhs_ingame_advertize_hidden, player.ingame_advertize_hidden, current.xhs_ingame_advertize_hidden, current.ingame_advertize_hidden),
		ingame_tag = FirstSupporterValue(player.ingame_tag, current.ingame_tag),
		supporter_url = FirstSupporterValue(supporterPass.url, supporterPass.supporter_url, player.supporter_url, current.supporter_url, "https://www.patreon.com/bePatron?u=2533325"),
		purchases = supporterPass.purchases or current.purchases,
		entitlements = supporterPass.entitlements or current.entitlements,
		armory = supporterPass.armory or current.armory,
		loadout = loadout,
		equipped_items = equippedItems,
		claimed_rewards = seasonStateAllowed
			and (supporterPass.claimed_rewards or current.claimed_rewards)
			or {},
	}
end

function SupporterPass:PublishPlayer(playerID)
	local playerTable = self:BuildPlayerTable(playerID)
	if playerTable then
		CustomNetTables:SetTableValue("supporter_pass_player", tostring(playerID), playerTable)
		if GameMode ~= nil and GameMode.RefreshSettingVotePower ~= nil then
			GameMode:RefreshSettingVotePower(playerID)
		end
		if api and api.PublishSupporterPassArmory then
			api:PublishSupporterPassArmory(playerID, playerTable.armory)
		end
	end
end

function SupporterPass:PublishPlayers()
	self:PublishMeta()
	self:PublishFeaturedShop()

	local backendRewards = api and api.supporter_pass and api.supporter_pass.rewards or {}
	local legacyFree = ItemsGame and ItemsGame.battlepass or {}
	local legacyPremium = ItemsGame and ItemsGame.battlepass2 or {}
	local freeRewards = MergeRewardTracks(legacyFree, backendRewards, "free")
	local premiumRewards = MergeRewardTracks(legacyPremium, backendRewards, "premium")
	if SupporterPass2026 ~= nil and SupporterPass2026.PublishRewardTrack ~= nil then
		SupporterPass2026:PublishRewardTrack("supporter_pass_rewards_free", freeRewards)
		SupporterPass2026:PublishRewardTrack("supporter_pass_rewards_premium", premiumRewards)
	else
		CustomNetTables:SetTableValue("supporter_pass_rewards_free", "rewards", freeRewards)
		CustomNetTables:SetTableValue("supporter_pass_rewards_premium", "rewards", premiumRewards)
	end

	for playerID = 0, PlayerResource:GetPlayerCount() - 1 do
		self:PublishPlayer(playerID)
	end
end
