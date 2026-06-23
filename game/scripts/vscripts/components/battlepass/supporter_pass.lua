SupporterPass = SupporterPass or class({})

SupporterPass.WEEKLY_FRAGMENT_CAP = 100
SupporterPass.LEGACY_FRAGMENT_PER_LEVEL = 50
SupporterPass.LEGACY_FRAGMENT_CAP = 5000
SupporterPass.SEASON_XP_PER_LEVEL = 1000

SupporterPass.TIERS = {
	[1] = {
		id = 1,
		name = "Donator",
		price = "$2",
		color = "#45C46B",
		fragments = 150,
		xp_boost = 10,
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
		companion_unlocks = 3,
		emblem_unlocks = 1,
		effigy_unlocks = 1,
	},
	[4] = {
		id = 4,
		name = "Stoneguard Donator",
		price = "$20",
		color = "#7B8794",
		fragments = 1800,
		xp_boost = 40,
		companion_unlocks = 3,
		emblem_unlocks = 1,
		effigy_unlocks = 1,
	},
	[5] = {
		id = 5,
		name = "Earthwarden Donator",
		price = "$50",
		color = "#2EC4B6",
		fragments = 1800,
		xp_boost = 40,
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

function SupporterPass:LegacyFragments(accountLevel)
	local level = tonumber(accountLevel) or 0
	return math.min(level * self.LEGACY_FRAGMENT_PER_LEVEL, self.LEGACY_FRAGMENT_CAP)
end

function SupporterPass:PublishMeta()
	CustomNetTables:SetTableValue("supporter_pass_meta", "tiers", self.TIERS)
	if BuildDonatorColorMeta ~= nil then
		CustomNetTables:SetTableValue("game_options", "donator_colors", BuildDonatorColorMeta(self.TIERS))
	end
	CustomNetTables:SetTableValue("supporter_pass_meta", "economy", {
		season_length_months = 3,
		weekly_fragment_cap = self.WEEKLY_FRAGMENT_CAP,
		legacy_fragment_per_level = self.LEGACY_FRAGMENT_PER_LEVEL,
		legacy_fragment_cap = self.LEGACY_FRAGMENT_CAP,
	})
end

function SupporterPass:PublishFeaturedShop()
	CustomNetTables:SetTableValue("supporter_pass_shop", "featured", {
		refresh_label = "Weekly featured rotation",
		items = {
			{
				id = "companion_featured_001",
				name = "Featured Companion",
				type = "Companion",
				rarity = "Rare",
				price = 650,
				image = "battlepass/assets/btn_donator.png",
			},
			{
				id = "emblem_featured_001",
				name = "Azure Emblem",
				type = "Emblem",
				rarity = "Rare",
				price = 500,
				image = "battlepass/assets/btn_battlepass.png",
			},
			{
				id = "effigy_featured_001",
				name = "Base Effigy",
				type = "Effigy",
				rarity = "Epic",
				price = 900,
				image = "battlepass/assets/btn_leaderboard.png",
			},
			{
				id = "bundle_featured_001",
				name = "Blue Siege Bundle",
				type = "Bundle",
				rarity = "Mythical",
				price = 1600,
				image = "battlepass/battlepass_new.png",
			},
		},
	})
end

function SupporterPass:BuildPlayerTable(playerID)
	if not PlayerResource:IsValidPlayerID(playerID) then
		return nil
	end

	local steamID = tostring(PlayerResource:GetSteamID(playerID))
	local player = api and api.players and api.players[steamID] or {}
	local supporterPass = player.supporter_pass or {}
	local passTierID = tonumber(supporterPass.tier_id) or 0
	local statusTierID = api and api.GetDonatorStatus and self:GetTierForStatus(api:GetDonatorStatus(playerID)) or 0
	local tierID = math.max(passTierID, statusTierID)
	local tier = self:GetTierByID(tierID)
	local accountLevel = tonumber(player.account_level or player.xp_level or supporterPass.account_level) or 0
	local seasonLevel = math.max(tonumber(supporterPass.season_level or supporterPass.level) or 1, 1)
	local seasonXP = tonumber(supporterPass.season_xp or supporterPass.current_exp) or 0
	local seasonXPMax = self.SEASON_XP_PER_LEVEL

	return {
		steamid = steamID,
		tier_id = tierID,
		tier_name = supporterPass.tier_name or self:GetTierName(tierID),
		tier_color = supporterPass.tier_color or self:GetTierColor(tierID),
		fragments = tonumber(supporterPass.fragments or supporterPass.fragment_balance) or 0,
		weekly_fragments = tonumber(supporterPass.weekly_fragments or supporterPass.weekly_earned) or 0,
		weekly_cap = tonumber(supporterPass.weekly_cap) or self.WEEKLY_FRAGMENT_CAP,
		monthly_fragments = tier and tier.fragments or 0,
		xp_boost = tier and tier.xp_boost or 0,
		season_level = seasonLevel,
		season_xp = seasonXP,
		season_xp_max = seasonXPMax,
		account_level = accountLevel,
		account_title = "Supporter Pass",
		legacy_fragments = tonumber(supporterPass.legacy_fragments) or self:LegacyFragments(accountLevel),
		toggle_tag = player.toggle_tag,
		pass_rewards = player.pass_rewards or player.bp_rewards,
		player_xp = player.player_xp,
		winrate = player.winrate or player.winrate_x_hero_siege,
		winrate_toggle = player.winrate_toggle,
		ingame_tag = player.ingame_tag,
		supporter_url = supporterPass.url or player.supporter_url or "https://www.patreon.com/frostrose",
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

	for playerID = 0, PlayerResource:GetPlayerCount() - 1 do
		self:PublishPlayer(playerID)
	end
end
