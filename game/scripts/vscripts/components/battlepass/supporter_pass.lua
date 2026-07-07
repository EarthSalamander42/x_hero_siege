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
		CustomNetTables:SetTableValue("supporter_pass_shop", "featured", api.supporter_pass.shop)
		return
	end

	CustomNetTables:SetTableValue("supporter_pass_shop", "featured", {
		refresh_label = "Weekly featured rotation",
		items = {
			{
				id = "legacy_bp_emblem_sunken",
				item_id = "21",
				name = "battlepass_emblem_sunken",
				type = "Emblem",
				rarity = "immortal",
				price = 500,
				image = "battlepass/emblem_sunken",
			},
			{
				id = "legacy_bp_emblem_aghanim",
				item_id = "24",
				name = "battlepass_emblem_aghanim",
				type = "Emblem",
				rarity = "immortal",
				price = 900,
				image = "battlepass/emblem_aghanim",
			},
			{
				id = "legacy_bp_kill_rubick",
				item_id = "36",
				name = "battlepass_kill_effect_rubick",
				type = "Kill FX",
				rarity = "uncommon",
				price = 750,
				image = "battlepass/kill_effect_rubick",
			},
			{
				id = "legacy_bp_tome_fall2022",
				item_id = "40",
				name = "battlepass_levelup8",
				type = "Tome FX",
				rarity = "legendary",
				price = 1200,
				image = "battlepass/levelup8",
			},
		},
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
	local season = supporterPass.season or {}
	local account = supporterPass.account or {}
	local settings = supporterPass.settings or player.settings or {}
	local passTierID = tonumber(FirstSupporterValue(supporterPass.tier_id, current.tier_id)) or 0
	local rawDonatorStatus = api and api.GetDonatorStatus and api:GetDonatorStatus(playerID) or 0
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
	local seasonLevel = math.max(tonumber(FirstSupporterValue(season.level, supporterPass.season_level, supporterPass.level, current.season_level, current.Lvl)) or 1, 1)
	local seasonXP = tonumber(FirstSupporterValue(season.xp, supporterPass.season_xp, supporterPass.current_exp, current.season_xp, current.XP)) or 0
	local seasonXPMax = tonumber(FirstSupporterValue(season.xp_per_level, supporterPass.season_xp_max, supporterPass.xp_per_level, current.season_xp_max, current.MaxXP)) or self.SEASON_XP_PER_LEVEL
	local seasonTotalXP = seasonXP
	seasonLevel, seasonXP, seasonXPMax, seasonTotalXP = NormalizeSeasonProgress(seasonLevel, seasonXP, seasonXPMax)
	local explicitSeasonXPChange = tonumber(FirstSupporterValue(
		season.xp_change,
		season.gained_xp,
		supporterPass.season_xp_change,
		supporterPass.xp_change,
		supporterPass.gained_xp,
		player.supporter_pass_xp_change,
		player.supporter_xp_change
	))
	local seasonXPChange = explicitSeasonXPChange or 0
	if explicitSeasonXPChange == nil and (current.steamid ~= nil or current.season_xp ~= nil or current.XP ~= nil) then
		local currentLevel = tonumber(FirstSupporterValue(current.season_level, current.Lvl)) or 1
		local currentXP = tonumber(FirstSupporterValue(current.season_xp, current.XP)) or 0
		local currentXPMax = tonumber(FirstSupporterValue(current.season_xp_max, current.MaxXP)) or seasonXPMax
		seasonXPChange = SeasonProgressTotal(seasonLevel, seasonXP, seasonXPMax) - SeasonProgressTotal(currentLevel, currentXP, currentXPMax)
	end
	local baseXPChange = tonumber(FirstSupporterValue(season.base_xp_change, supporterPass.base_xp_change, player.base_xp_change, current.base_xp_change)) or 0
	local xpBonus = tonumber(FirstSupporterValue(season.xp_bonus, supporterPass.xp_bonus, player.xp_bonus, current.xp_bonus)) or 0
	local passRewards = FirstSupporterValue(settings.pass_rewards, player.pass_rewards)
	if passRewards == nil then
		passRewards = player.bp_rewards
	end

	return {
		steamid = steamID,
		XP = seasonXP,
		MaxXP = seasonXPMax,
		Lvl = seasonLevel,
		title = "Supporter Pass",
		donator_level = donatorStatus,
		raw_donator_level = rawDonatorStatus,
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
		vote_power = tonumber(FirstSupporterValue(supporterPass.vote_power, current.vote_power)) or (tier and tier.vote_power or math.max(1, math.min(tierID + 1, 5))),
		season_level = seasonLevel,
		season_xp = seasonXP,
		season_xp_max = seasonXPMax,
		season_total_xp = seasonTotalXP,
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
		loadout = supporterPass.loadout or current.loadout,
		claimed_rewards = supporterPass.claimed_rewards or current.claimed_rewards,
	}
end

function SupporterPass:PublishPlayer(playerID)
	local playerTable = self:BuildPlayerTable(playerID)
	if playerTable then
		CustomNetTables:SetTableValue("supporter_pass_player", tostring(playerID), playerTable)
	end
end

function SupporterPass:PublishPlayers()
	self:PublishMeta()
	self:PublishFeaturedShop()

	if api and api.supporter_pass and api.supporter_pass.rewards then
		local freeRewards = {}
		local premiumRewards = {}
		for _, reward in pairs(api.supporter_pass.rewards) do
			if reward.track == "premium" then
				table.insert(premiumRewards, reward)
			else
				table.insert(freeRewards, reward)
			end
		end
		CustomNetTables:SetTableValue("supporter_pass_rewards_free", "rewards", freeRewards)
		CustomNetTables:SetTableValue("supporter_pass_rewards_premium", "rewards", premiumRewards)
	end

	for playerID = 0, PlayerResource:GetPlayerCount() - 1 do
		self:PublishPlayer(playerID)
	end
end
