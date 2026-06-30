"use strict";

var XHSSupporterPass = (function () {
	var SUPPORTER_URL = "https://www.patreon.com/bePatron?u=2533325";
	var DISCORD_URL = "https://discord.frostrose-studio.com/";
	var DAILY_FRAGMENT_CAP = 100;
	var WEEKLY_FRAGMENT_CAP = DAILY_FRAGMENT_CAP;
	var currentShopFilter = "All";
	var currentArmoryFilter = "All";
	var settingsOriginal = {};
	var settingsDraft = {};
	var settingsInitialized = false;
	var settingsSaving = false;
	var backToTopPollScheduled = false;
	var fragmentCounterInitialized = false;
	var lastLocalFragmentBalance = 0;
	var fragmentFlyoutIndex = 0;
	var actionToastSerial = 0;

	var PAGE_IDS = {
		overview: "XHSPassOverviewPage",
		rewards: "XHSPassRewardsPage",
		shop: "XHSPassShopPage",
		armory: "XHSPassArmoryPage",
		leaderboards: "XHSPassLeaderboardsPage",
		settings: "XHSPassSettingsPage",
	};

	var TAB_IDS = {
		overview: "XHSPassTabOverview",
		rewards: "XHSPassTabRewards",
		shop: "XHSPassTabShop",
		armory: "XHSPassTabArmory",
		leaderboards: "XHSPassTabLeaderboards",
		settings: "XHSPassTabSettings",
	};

	var DISABLED_PAGES = {
		leaderboards: true,
	};

	var DEFAULT_TIERS = [
		{ id: 1, name: "Donator", price: "2\u20ac/month", color: "#70e39a", fragments: 150, xp_boost: 10, vote_power: 1 },
		{ id: 2, name: "Golden Donator", price: "4.50\u20ac/month", color: "#ffcf66", fragments: 400, xp_boost: 20, vote_power: 2 },
		{ id: 3, name: "Ember Donator", price: "9\u20ac/month", color: "#ff5a43", fragments: 900, xp_boost: 30, vote_power: 3 },
		{ id: 4, name: "Stoneguard Donator", price: "18\u20ac/month", color: "#5ad0ff", fragments: 1800, xp_boost: 40, vote_power: 4 },
		{ id: 5, name: "Earthwarden Donator", price: "27\u20ac/month", color: "#c99cff", fragments: 1800, xp_boost: 40, vote_power: 5, prestige: true },
	];

	var SITE_TIER_META = {
		1: {
			label: "Tier 1",
			price: "2\u20ac/month",
			image: "patreon/donator_01_emerald.png",
			text: "Start supporting XHS with monthly fragments, Emerald identity, a Discord role, visible profile prestige, and 1 vote in game setup.",
			perks: ["150 fragments", "+10% XP", "1 vote", "Emerald Green", "Discord role"],
		},
		2: {
			label: "Tier 2",
			price: "4.50\u20ac/month",
			image: "patreon/donator_02_solar_gold.png",
			text: "Upgrade to Solar Gold for a stronger monthly fragment pack, faster progression, 2 setup votes, and all Tier 1 benefits.",
			perks: ["400 fragments", "+20% XP", "2 votes", "Solar Gold"],
			featured: true,
		},
		3: {
			label: "Tier 3",
			price: "9\u20ac/month",
			image: "patreon/donator_03_ember_red.png",
			text: "Stand out with Ember Red styling, 900 monthly fragments, 3 setup votes, and a sharper supporter presence in every XHS space.",
			perks: ["900 fragments", "+30% XP", "3 votes", "Ember Red"],
		},
		4: {
			label: "Tier 4",
			price: "18\u20ac/month",
			image: "patreon/donator_04_storm_blue.png",
			text: "Lock in Storm Blue status with the top XP boost, 1800 monthly fragments, 4 setup votes, and a premium supporter look.",
			perks: ["1800 fragments", "+40% XP", "4 votes", "Storm Blue"],
		},
		5: {
			label: "Tier 5",
			price: "27\u20ac/month",
			image: "patreon/donator_05_amethyst_violet.png",
			text: "The prestige tier for core supporters: Amethyst identity, top XP boost, 5 setup votes, and the full supporter stack.",
			perks: ["1800 fragments", "+40% XP", "5 votes", "Amethyst Violet"],
		},
	};

	var DEFAULT_SHOP_ITEMS = [
		{ id: "legacy_bp_emblem_sunken", item_id: "21", name: "battlepass_emblem_sunken", type: "Emblem", rarity: "immortal", price: 500, image: "battlepass/emblem_sunken" },
		{ id: "legacy_bp_emblem_aghanim", item_id: "24", name: "battlepass_emblem_aghanim", type: "Emblem", rarity: "immortal", price: 900, image: "battlepass/emblem_aghanim" },
		{ id: "legacy_bp_teleport_ti2018", item_id: "15", name: "battlepass_teleport22", type: "Teleport FX", rarity: "uncommon", price: 450, image: "battlepass/teleport22" },
		{ id: "legacy_bp_teleport_ti2018_premium", item_id: "16", name: "battlepass_teleport24", type: "Teleport FX", rarity: "uncommon", price: 650, image: "battlepass/teleport24" },
		{ id: "legacy_bp_kill_rubick", item_id: "36", name: "battlepass_kill_effect_rubick", type: "Kill FX", rarity: "uncommon", price: 750, image: "battlepass/kill_effect_rubick" },
		{ id: "legacy_bp_kill_spectre", item_id: "32", name: "battlepass_kill_effect_spectre", type: "Kill FX", rarity: "uncommon", price: 750, image: "battlepass/kill_effect_spectre" },
		{ id: "legacy_bp_tome_fall2022", item_id: "40", name: "battlepass_levelup8", type: "Tome FX", rarity: "legendary", price: 1200, image: "battlepass/levelup8" },
		{ id: "legacy_bp_emblem_diretide", item_id: "26", name: "battlepass_emblem_diretide_red", type: "Emblem", rarity: "immortal", price: 1600, image: "battlepass/emblem_diretide_red" },
	];

	var DEFAULT_REWARDS_FREE = [
		{ level: 1, name: "battlepass_teleport2", type: "teleport", rarity: "uncommon", image: "battlepass/teleport2", item_id: "1", slot_id: "teleport", hero: "teleport" },
		{ level: 2, name: "battlepass_teleport6", type: "teleport", rarity: "uncommon", image: "battlepass/teleport6", item_id: "3", slot_id: "teleport", hero: "teleport" },
		{ level: 3, name: "battlepass_teleport8", type: "teleport", rarity: "uncommon", image: "battlepass/teleport8", item_id: "5", slot_id: "teleport", hero: "teleport" },
		{ level: 4, name: "battlepass_teleport10", type: "teleport", rarity: "uncommon", image: "battlepass/teleport10", item_id: "7", slot_id: "teleport", hero: "teleport" },
		{ level: 5, name: "battlepass_emblem_sunken", type: "emblem", rarity: "immortal", image: "battlepass/emblem_sunken", item_id: "21", slot_id: "emblem", hero: "emblem" },
		{ level: 6, name: "battlepass_teleport13", type: "teleport", rarity: "uncommon", image: "battlepass/teleport13", item_id: "9", slot_id: "teleport", hero: "teleport" },
		{ level: 7, name: "battlepass_teleport16", type: "teleport", rarity: "uncommon", image: "battlepass/teleport16", item_id: "11", slot_id: "teleport", hero: "teleport" },
		{ level: 8, name: "battlepass_teleport19", type: "teleport", rarity: "uncommon", image: "battlepass/teleport19", item_id: "13", slot_id: "teleport", hero: "teleport" },
		{ level: 9, name: "battlepass_teleport22", type: "teleport", rarity: "uncommon", image: "battlepass/teleport22", item_id: "15", slot_id: "teleport", hero: "teleport" },
		{ level: 10, name: "battlepass_emblem_overgrown", type: "emblem", rarity: "immortal", image: "battlepass/emblem_overgrown", item_id: "22", slot_id: "emblem", hero: "emblem" },
		{ level: 11, name: "battlepass_kill_effect_culling_blade", type: "kill_effect", rarity: "uncommon", image: "battlepass/kill_effect_culling_blade", item_id: "27", slot_id: "kill_effect", hero: "kill_effect" },
		{ level: 12, name: "battlepass_levelup1", type: "levelup", rarity: "legendary", image: "battlepass/levelup", item_id: "17", slot_id: "levelup", hero: "levelup" },
		{ level: 13, name: "battlepass_kill_effect_radiant_tower", type: "kill_effect", rarity: "uncommon", image: "battlepass/kill_effect_radiant_tower", item_id: "29", slot_id: "kill_effect", hero: "kill_effect" },
		{ level: 14, name: "battlepass_levelup3", type: "levelup", rarity: "legendary", image: "battlepass/levelup3", item_id: "19", slot_id: "levelup", hero: "levelup" },
		{ level: 15, name: "battlepass_kill_effect_spectre_free", type: "kill_effect", rarity: "uncommon", image: "battlepass/kill_effect_spectre_free", item_id: "31", slot_id: "kill_effect", hero: "kill_effect" },
		{ level: 16, name: "battlepass_levelup5", type: "levelup", rarity: "legendary", image: "battlepass/levelup5", item_id: "37", slot_id: "levelup", hero: "levelup" },
		{ level: 17, name: "battlepass_kill_effect_gyro_free", type: "kill_effect", rarity: "uncommon", image: "battlepass/kill_effect_purple_smoke_free", item_id: "33", slot_id: "kill_effect", hero: "kill_effect" },
		{ level: 18, name: "battlepass_levelup7", type: "levelup", rarity: "legendary", image: "battlepass/levelup7", item_id: "39", slot_id: "levelup", hero: "levelup" },
		{ level: 19, name: "battlepass_kill_effect_rubick_free", type: "kill_effect", rarity: "uncommon", image: "battlepass/kill_effect_rubick_free", item_id: "35", slot_id: "kill_effect", hero: "kill_effect" },
		{ level: 20, name: "battlepass_emblem_divinity", type: "emblem", rarity: "immortal", image: "battlepass/emblem_divinity", item_id: "23", slot_id: "emblem", hero: "emblem" },
	];

	var DEFAULT_REWARDS_PREMIUM = [
		{ level: 1, name: "battlepass_teleport5", type: "teleport", rarity: "uncommon", image: "battlepass/teleport5", item_id: "2", slot_id: "teleport", hero: "teleport", track: "premium" },
		{ level: 2, name: "battlepass_teleport7", type: "teleport", rarity: "uncommon", image: "battlepass/teleport7", item_id: "4", slot_id: "teleport", hero: "teleport", track: "premium" },
		{ level: 3, name: "battlepass_teleport9", type: "teleport", rarity: "uncommon", image: "battlepass/teleport9", item_id: "6", slot_id: "teleport", hero: "teleport", track: "premium" },
		{ level: 4, name: "battlepass_teleport12", type: "teleport", rarity: "uncommon", image: "battlepass/teleport12", item_id: "8", slot_id: "teleport", hero: "teleport", track: "premium" },
		{ level: 5, name: "battlepass_emblem_aghanim", type: "emblem", rarity: "immortal", image: "battlepass/emblem_aghanim", item_id: "24", slot_id: "emblem", hero: "emblem", track: "premium" },
		{ level: 6, name: "battlepass_teleport15", type: "teleport", rarity: "uncommon", image: "battlepass/teleport15", item_id: "10", slot_id: "teleport", hero: "teleport", track: "premium" },
		{ level: 7, name: "battlepass_teleport18", type: "teleport", rarity: "uncommon", image: "battlepass/teleport18", item_id: "12", slot_id: "teleport", hero: "teleport", track: "premium" },
		{ level: 8, name: "battlepass_teleport21", type: "teleport", rarity: "uncommon", image: "battlepass/teleport21", item_id: "14", slot_id: "teleport", hero: "teleport", track: "premium" },
		{ level: 9, name: "battlepass_teleport24", type: "teleport", rarity: "uncommon", image: "battlepass/teleport24", item_id: "16", slot_id: "teleport", hero: "teleport", track: "premium" },
		{ level: 10, name: "battlepass_emblem_nemestice", type: "emblem", rarity: "immortal", image: "battlepass/emblem_nemestice", item_id: "25", slot_id: "emblem", hero: "emblem", track: "premium" },
		{ level: 11, name: "battlepass_kill_effect_faceless_void", type: "kill_effect", rarity: "uncommon", image: "battlepass/kill_effect_faceless_void", item_id: "28", slot_id: "kill_effect", hero: "kill_effect", track: "premium" },
		{ level: 12, name: "battlepass_levelup2", type: "levelup", rarity: "legendary", image: "battlepass/levelup2", item_id: "18", slot_id: "levelup", hero: "levelup", track: "premium" },
		{ level: 13, name: "battlepass_kill_effect_razor", type: "kill_effect", rarity: "uncommon", image: "battlepass/kill_effect_razor", item_id: "30", slot_id: "kill_effect", hero: "kill_effect", track: "premium" },
		{ level: 14, name: "battlepass_levelup4", type: "levelup", rarity: "legendary", image: "battlepass/levelup4", item_id: "20", slot_id: "levelup", hero: "levelup", track: "premium" },
		{ level: 15, name: "battlepass_kill_effect_spectre", type: "kill_effect", rarity: "uncommon", image: "battlepass/kill_effect_spectre", item_id: "32", slot_id: "kill_effect", hero: "kill_effect", track: "premium" },
		{ level: 16, name: "battlepass_levelup6", type: "levelup", rarity: "legendary", image: "battlepass/levelup6", item_id: "38", slot_id: "levelup", hero: "levelup", track: "premium" },
		{ level: 17, name: "battlepass_kill_effect_gyro", type: "kill_effect", rarity: "uncommon", image: "battlepass/kill_effect_purple_smoke", item_id: "34", slot_id: "kill_effect", hero: "kill_effect", track: "premium" },
		{ level: 18, name: "battlepass_levelup8", type: "levelup", rarity: "legendary", image: "battlepass/levelup8", item_id: "40", slot_id: "levelup", hero: "levelup", track: "premium" },
		{ level: 19, name: "battlepass_kill_effect_rubick", type: "kill_effect", rarity: "uncommon", image: "battlepass/kill_effect_rubick", item_id: "36", slot_id: "kill_effect", hero: "kill_effect", track: "premium" },
		{ level: 20, name: "battlepass_emblem_diretide_red", type: "emblem", rarity: "immortal", image: "battlepass/emblem_diretide_red", item_id: "26", slot_id: "emblem", hero: "emblem", track: "premium" },
	];

	var DEFAULT_COMPANION_ITEMS = [
		"npc_donator_companion_cookies",
		"npc_donator_companion_admiral_bulldog",
		"npc_donator_companion_baumi",
		"npc_donator_companion_icefrog",
		"npc_donator_companion_amaterasu",
		"npc_donator_companion_demi_doom",
		"npc_donator_companion_carty",
		"npc_donator_companion_llama",
		"npc_donator_companion_jumo",
		"npc_donator_companion_baekho",
		"npc_donator_companion_devourling",
		"npc_donator_companion_sappling",
		"npc_donator_companion_golem",
		"npc_donator_companion_duskie",
		"npc_donator_companion_rubick_arcana",
		"npc_donator_companion_juggernaut_arcana",
		"npc_donator_companion_terrorblade_arcana",
		"npc_donator_companion_tinkbot",
		"npc_donator_companion_hollow_jack",
		"npc_donator_companion_chocobo",
	];

	var DEFAULT_LEADERBOARD_ENTRIES = [
		{ rank: 1, name: "Cookies", type: "Season XP", score: 182400 },
		{ rank: 2, name: "Ethan", type: "Season XP", score: 151900 },
		{ rank: 3, name: "Mason", type: "Season XP", score: 138250 },
		{ rank: 4, name: "Noah", type: "Winrate", score: 74 },
		{ rank: 5, name: "Lucas", type: "Hall of Fame", score: 12 },
		{ rank: 6, name: "Liam", type: "Fragments earned", score: 9200 },
		{ rank: 7, name: "Owen", type: "Boss clears", score: 48 },
	];

	function Panel(id) {
		return $("#" + id);
	}

	function Safe(callback, fallbackValue) {
		try {
			var value = callback();
			return value === undefined || value === null ? fallbackValue : value;
		} catch (error) {
			return fallbackValue;
		}
	}

	function ToNumber(value, fallbackValue) {
		var numberValue = Number(value);
		if (isNaN(numberValue)) {
			return fallbackValue || 0;
		}
		return numberValue;
	}

	function Clamp(value, minValue, maxValue) {
		return Math.max(minValue, Math.min(maxValue, value));
	}

	function IsEarthwardenSupporterData(data) {
		if (!data) {
			return false;
		}

		var donatorLevel = Math.floor(ToNumber(data.donator_level || data.donator_status, 0));
		if (donatorLevel === 8 || donatorLevel === 9) {
			return true;
		}

		var tierName = (data.tier_name || data.supporter_tier_name || "").toString().toLowerCase();
		if (tierName.indexOf("earthwarden") >= 0) {
			return true;
		}

		var tierColor = (data.tier_color || "").toString().toLowerCase();
		return tierColor === "#c99cff";
	}

	function NormalizeSupporterTierID(tierID, data) {
		if (IsEarthwardenSupporterData(data)) {
			return 5;
		}

		var normalizedTier = Math.floor(ToNumber(tierID, 0));
		var statusToTier = {
			6: 1,
			7: 4,
			8: 5,
			9: 5
		};

		if (normalizedTier > 5 && statusToTier[normalizedTier] !== undefined) {
			normalizedTier = statusToTier[normalizedTier];
		}

		return Clamp(normalizedTier, 0, 5);
	}

	function NormalizeSupporterTierColor(data, tierID) {
		if (IsEarthwardenSupporterData(data)) {
			return "#c99cff";
		}

		return data.tier_color || GetTierColorByID(tierID);
	}

	function Localize(value) {
		if (!value) {
			return "";
		}

		var localized = $.Localize(value);
		return localized === value ? value.replace("#", "") : localized;
	}

	function LocalizeMaybeKey(value) {
		if (!value) {
			return "";
		}

		if (typeof value === "string" && value.charAt(0) === "#") {
			return Localize(value);
		}

		return Localize("#" + value);
	}

	function NormalizeImagePath(imagePath) {
		if (!imagePath) {
			return "";
		}

		var path = imagePath.toString();
		path = path.replace(/^custom_game\//, "");
		path = path.replace(/\.png$/, "");
		return path + ".png";
	}

	function SetCustomGameImage(panel, imagePath) {
		var normalized = NormalizeImagePath(imagePath);
		if (panel && normalized) {
			panel.style.backgroundImage = 'url("file://{images}/custom_game/' + normalized + '")';
			panel.style.backgroundSize = "contain";
			panel.style.backgroundPosition = "50% 50%";
			panel.style.backgroundRepeat = "no-repeat";
		}
	}

	function ApplySupporterTierClasses(panel, tierID) {
		if (!panel) {
			return;
		}

		var normalizedTier = NormalizeSupporterTierID(tierID);
		panel.SetHasClass("HasSupporterTier", normalizedTier > 0);
		for (var tier = 0; tier <= 5; tier++) {
			panel.SetHasClass("SupporterTier" + tier, tier === normalizedTier);
		}
	}

	function FormatNumber(value) {
		var numberValue = ToNumber(value, 0);
		var absValue = Math.abs(numberValue);
		var sign = numberValue < 0 ? "-" : "";

		if (absValue >= 1000000) {
			return sign + (absValue / 1000000).toFixed(1) + "M";
		}

		if (absValue >= 10000) {
			return sign + (absValue / 1000).toFixed(1) + "k";
		}

		return sign + Math.floor(absValue).toString();
	}

	function FormatVotePower(value) {
		var votes = Math.max(1, Math.floor(ToNumber(value, 1)));
		return votes + " " + (votes > 1 ? "votes" : "vote");
	}

	function AsArray(value) {
		if (!value) {
			return [];
		}

		if (Object.prototype.toString.call(value) === "[object Array]") {
			return value;
		}

		if (value["1"] && Object.prototype.toString.call(value["1"]) === "[object Array]") {
			return value["1"];
		}

		var result = [];
		for (var key in value) {
			if (value.hasOwnProperty(key) && value[key] && typeof value[key] === "object") {
				result.push(value[key]);
			}
		}

		result.sort(function (a, b) {
			return ToNumber(a.level || a.rank || a.id, 0) - ToNumber(b.level || b.rank || b.id, 0);
		});

		return result;
	}

	function ClearPanel(panel) {
		if (panel) {
			panel.RemoveAndDeleteChildren();
		}
	}

	function NormalizeSeasonProgress(level, xp, maxXp) {
		var normalizedLevel = Math.max(1, ToNumber(level, 1));
		var normalizedMax = Math.max(ToNumber(maxXp, 2000), 1);
		var normalizedXP = Math.max(0, ToNumber(xp, 0));

		if (normalizedXP >= normalizedMax) {
			var completedLevels = Math.floor(normalizedXP / normalizedMax);
			normalizedXP = normalizedXP - completedLevels * normalizedMax;
			normalizedLevel = Math.max(normalizedLevel, 1 + completedLevels);
		}

		return {
			level: normalizedLevel,
			xp: normalizedXP,
			maxXp: normalizedMax,
		};
	}

	function GetTable(tableName, keyName, fallbackValue) {
		return CustomNetTables.GetTableValue(tableName, keyName) || fallbackValue;
	}

	function CopyMissingFields(target, source) {
		if (!target || !source) {
			return target || {};
		}

		for (var key in source) {
			if (source.hasOwnProperty(key) && target[key] === undefined) {
				target[key] = source[key];
			}
		}

		return target;
	}

	function GetLocalPlayerData() {
		var playerID = Players.GetLocalPlayer();
		var data = GetTable("supporter_pass_player", playerID.toString(), {}) || {};
		var legacyData = GetTable("battlepass_player", playerID.toString(), null) || GetTable("battlepass_player", playerID, null);
		data = CopyMissingFields(data, legacyData);
		var info = Safe(function () { return Game.GetPlayerInfo(playerID); }, {});
		var tierID = NormalizeSupporterTierID(data.tier_id || data.supporter_tier || data.donator_level || 0, data);
		var season = NormalizeSeasonProgress(
			data.season_level !== undefined ? data.season_level : data.Lvl,
			data.season_xp !== undefined ? data.season_xp : data.XP,
			data.season_xp_max !== undefined ? data.season_xp_max : data.MaxXP
		);

		return {
			id: playerID,
			name: Safe(function () { return Players.GetPlayerName(playerID); }, info.player_name || "Player"),
			steamID: info.player_steamid || "",
			tier_id: tierID,
			tier_name: data.tier_name || "Free Player",
			tier_color: NormalizeSupporterTierColor(data, tierID),
			fragments: ToNumber(data.fragments || data.fragment_balance, 0),
			has_fragment_balance: data.fragments !== undefined || data.fragment_balance !== undefined,
			daily_fragments: ToNumber(data.daily_fragments || data.daily_earned || data.weekly_fragments || data.weekly_earned, 0),
			daily_cap: ToNumber(data.daily_cap || data.weekly_cap, DAILY_FRAGMENT_CAP),
			weekly_fragments: ToNumber(data.daily_fragments || data.daily_earned || data.weekly_fragments || data.weekly_earned, 0),
			weekly_cap: ToNumber(data.daily_cap || data.weekly_cap, DAILY_FRAGMENT_CAP),
			xp_boost: ToNumber(data.xp_boost, 0),
			vote_power: Math.max(1, ToNumber(data.vote_power, tierID > 0 ? tierID : 1)),
			season_level: season.level,
			season_xp: season.xp,
			season_xp_max: season.maxXp,
			account_level: ToNumber(data.account_level !== undefined ? data.account_level : data.legacy_level, 0),
			xhs_account_level: ToNumber(data.xhs_account_level, 0),
			xhs_xp_current: ToNumber(data.xhs_xp_current, 0),
			xhs_xp_max: ToNumber(data.xhs_xp_max, 0),
			xhs_xp_total: ToNumber(data.xhs_xp, 0),
			supporter_url: data.supporter_url || SUPPORTER_URL,
			raw: data,
		};
	}

	function FormatXHSAccountXPSummary(player) {
		var level = Math.max(0, ToNumber(player.xhs_account_level, 0));
		var total = Math.max(0, ToNumber(player.xhs_xp_total, 0));
		var current = Math.max(0, ToNumber(player.xhs_xp_current, 0));
		var max = Math.max(0, ToNumber(player.xhs_xp_max, 0));

		if (level <= 0 && total <= 0 && current <= 0 && max <= 0) {
			return "-";
		}

		if (total > 0) {
			return "L" + Math.max(1, level) + " " + FormatNumber(total);
		}

		if (max > 0) {
			return "L" + Math.max(1, level) + " " + FormatNumber(current) + "/" + FormatNumber(max);
		}

		return "L" + Math.max(1, level);
	}

	function FormatSupporterXPSummary(player) {
		return "L" + player.season_level + " " + FormatNumber(player.season_xp) + "/" + FormatNumber(player.season_xp_max);
	}

	function GetTiers() {
		return AsArray(GetTable("supporter_pass_meta", "tiers", DEFAULT_TIERS));
	}

	function GetTierMeta(tier) {
		var tierID = ToNumber(tier.id || tier.tier_id, 0);
		var meta = SITE_TIER_META[tierID] || {};
		return {
			id: tierID,
			label: meta.label || ("Tier " + tierID),
			name: tier.name || meta.name || "Supporter",
			price: meta.price || tier.price || "",
			text: meta.text || "",
			perks: meta.perks || [
				FormatNumber(tier.fragments || 0) + " fragments",
				"+" + FormatNumber(tier.xp_boost || 0) + "% XP",
				FormatVotePower(tier.vote_power || tierID),
			],
			image: meta.image || tier.image || "",
			color: tier.color || meta.color || "#5ad0ff",
			featured: meta.featured === true,
		};
	}

	function GetTierColorByID(tierID) {
		var normalizedTier = NormalizeSupporterTierID(tierID);
		if (normalizedTier <= 0) {
			return "#7db9d8";
		}

		var tiers = GetTiers();
		for (var i = 0; i < tiers.length; i++) {
			var tier = tiers[i] || {};
			var currentTierID = ToNumber(tier.id || tier.tier_id, 0);
			if (currentTierID === normalizedTier && tier.color) {
				return tier.color;
			}
		}

		for (var j = 0; j < DEFAULT_TIERS.length; j++) {
			if (DEFAULT_TIERS[j].id === normalizedTier) {
				return DEFAULT_TIERS[j].color;
			}
		}

		return "#5ad0ff";
	}

	function GetRewards(track) {
		var tableName = "supporter_pass_rewards_free";
		if (track === "premium") {
			tableName = "supporter_pass_rewards_premium";
		}

		var rewards = AsArray(GetTable(tableName, "rewards", []));
		if (rewards.length > 0) {
			return rewards;
		}

		return track === "premium" ? DEFAULT_REWARDS_PREMIUM : DEFAULT_REWARDS_FREE;
	}

	function GetRewardID(reward) {
		if (!reward) {
			return "";
		}

		return (reward.reward_id || reward.id || reward.item_id || "").toString();
	}

	function RewardValueMatches(value, reward, rewardID) {
		if (value === undefined || value === null) {
			return false;
		}

		if (typeof value === "object") {
			return RewardValueMatches(value.reward_id, reward, rewardID) ||
				RewardValueMatches(value.id, reward, rewardID) ||
				RewardValueMatches(value.item_id, reward, rewardID) ||
				RewardValueMatches(value.name, reward, rewardID);
		}

		var stringValue = value.toString();
		return stringValue === rewardID ||
			stringValue === (reward.item_id || "").toString() ||
			stringValue === (reward.id || "").toString() ||
			stringValue === (reward.name || "").toString();
	}

	function IsRewardClaimed(reward, player) {
		if (reward.claimed === true || reward.claimed === 1 || reward.claimed === "1") {
			return true;
		}

		var rewardID = GetRewardID(reward);
		if (rewardID === "") {
			return false;
		}

		var claimed = player.raw && player.raw.claimed_rewards;
		if (!claimed) {
			return false;
		}

		if (Object.prototype.toString.call(claimed) === "[object Array]") {
			for (var i = 0; i < claimed.length; i++) {
				if (RewardValueMatches(claimed[i], reward, rewardID)) {
					return true;
				}
			}
			return false;
		}

		if (typeof claimed === "object") {
			if (IsTruthy(claimed[rewardID], false) || IsTruthy(claimed[reward.item_id], false) || IsTruthy(claimed[reward.id], false)) {
				return true;
			}

			for (var key in claimed) {
				if (claimed.hasOwnProperty(key) && (key === rewardID || RewardValueMatches(claimed[key], reward, rewardID))) {
					return true;
				}
			}
		}

		return false;
	}

	function NormalizeRewardType(type) {
		var normalized = (type || "cosmetic").toString().toLowerCase();
		if (normalized === "teleport") {
			return "Teleport FX";
		}
		if (normalized === "levelup") {
			return "Tome FX";
		}
		if (normalized === "kill_effect") {
			return "Kill FX";
		}
		if (normalized === "emblem") {
			return "Emblem";
		}
		if (normalized === "courier" || normalized === "companion") {
			return "Companion";
		}
		if (normalized === "effigy" || normalized === "statue") {
			return "Effigy";
		}
		if (normalized === "bundle") {
			return "Bundle";
		}
		if (normalized === "pudge_hook") {
			return "Pudge Hook";
		}
		if (normalized === "pudge_arcana") {
			return "Pudge Arcana";
		}
		if (normalized === "streak_counter") {
			return "Streak Counter";
		}
		return normalized.charAt(0).toUpperCase() + normalized.slice(1);
	}

	function ReadLoadoutValue(loadout, slotNames) {
		if (!loadout) {
			return "";
		}

		for (var i = 0; i < slotNames.length; i++) {
			var value = loadout[slotNames[i]];
			if (value && typeof value === "object") {
				return value.item_id || value.id || value.entitlement_id || value.unit || "";
			}
			if (value) {
				return value;
			}
		}

		return "";
	}

	function IsArmoryItemEquipped(player, item) {
		var raw = player.raw || {};
		var loadout = raw.loadout || {};
		var itemID = item.item_id || item.id || item.entitlement_id || "";
		var unit = item.unit || "";
		var type = NormalizeRewardType(item.type || item.item_type);
		var equippedValue = "";

		if (type === "Companion") {
			equippedValue = ReadLoadoutValue(loadout, ["companion", "companions"]) || raw.companion || raw.companion_id;
			return equippedValue && (equippedValue === itemID || equippedValue === unit);
		}
		if (type === "Emblem") {
			equippedValue = ReadLoadoutValue(loadout, ["emblem", "emblems"]) || raw.emblem || raw.emblem_id;
			return equippedValue && equippedValue === itemID;
		}
		if (type === "Teleport FX") {
			equippedValue = ReadLoadoutValue(loadout, ["teleport", "teleport_fx"]);
			return equippedValue && equippedValue === itemID;
		}
		if (type === "Tome FX") {
			equippedValue = ReadLoadoutValue(loadout, ["levelup", "tome", "tome_fx"]);
			return equippedValue && equippedValue === itemID;
		}
		if (type === "Kill FX") {
			equippedValue = ReadLoadoutValue(loadout, ["kill_effect", "kill_fx"]);
			return equippedValue && equippedValue === itemID;
		}

		return item.equipped === true;
	}

	function BuildArmoryItemFromReward(reward, player, track) {
		var requiredLevel = ToNumber(reward.level_required || reward.level, 1);
		var isPremium = track === "premium" || reward.track === "premium" || reward.premium === 1 || reward.premium === "1";
		var premiumLocked = isPremium && player.tier_id < 1;
		var levelLocked = player.season_level < requiredLevel;
		var item = {
			id: "battlepass_" + (reward.item_id || reward.id || reward.name),
			item_id: reward.item_id || reward.id || reward.reward_id,
			name: reward.name || reward.item_name || reward.id,
			type: NormalizeRewardType(reward.type || reward.item_type),
			rarity: reward.rarity || reward.item_rarity || (isPremium ? "premium" : "season"),
			image: reward.image,
			hero: reward.hero || reward.used_by_heroes || reward.type || reward.item_type || "global",
			slot_id: reward.slot_id || reward.type || reward.item_type || "default",
			level: requiredLevel,
			track: isPremium ? "Supporter Track" : "Free Track",
		};

		item.locked = premiumLocked || levelLocked;
		item.lock_reason = premiumLocked ? "Supporter Track" : ("Level " + requiredLevel);
		item.equipped = !item.locked && IsArmoryItemEquipped(player, item);
		return item;
	}

	function BuildCompanionArmoryItems(player) {
		var companions = AsArray(GetTable("supporter_pass_player", "companions", []));
		var items = [];

		if (companions.length === 0) {
			for (var i = 0; i < DEFAULT_COMPANION_ITEMS.length; i++) {
				companions.push({ unit: DEFAULT_COMPANION_ITEMS[i], item_name: DEFAULT_COMPANION_ITEMS[i] });
			}
		}

		for (var j = 0; j < companions.length; j++) {
			var companion = companions[j];
			var unit = companion.unit || companion.unit_name || companion.item_name || companion.name || DEFAULT_COMPANION_ITEMS[j];
			if (!unit) {
				continue;
			}

			var item = {
				id: "companion_" + unit,
				item_id: companion.item_id || unit,
				unit: unit,
				name: companion.name || companion.item_name || unit,
				type: "Companion",
				rarity: companion.rarity || companion.item_rarity || "supporter",
				image: companion.image || companion.image_inventory || "battlepass/assets/btn_donator_icon",
				hero: "global",
				slot_id: "companion",
				locked: player.tier_id < 1,
				lock_reason: "Supporter Tier",
			};
			item.equipped = !item.locked && IsArmoryItemEquipped(player, item);
			items.push(item);
		}

		return items;
	}

	function BuildLegacyBattlepassArmory(player) {
		var items = [];
		var freeRewards = GetRewards("free");
		var premiumRewards = GetRewards("premium");

		for (var i = 0; i < freeRewards.length; i++) {
			items.push(BuildArmoryItemFromReward(freeRewards[i], player, "free"));
		}
		for (var j = 0; j < premiumRewards.length; j++) {
			items.push(BuildArmoryItemFromReward(premiumRewards[j], player, "premium"));
		}

		var companions = BuildCompanionArmoryItems(player);
		for (var c = 0; c < companions.length; c++) {
			items.push(companions[c]);
		}

		return items;
	}

	function NormalizeBackendArmoryItems(items, player) {
		var normalizedItems = [];
		for (var i = 0; i < items.length; i++) {
			var item = items[i];
			item.type = NormalizeRewardType(item.type || item.item_type);
			item.equipped = item.equipped === true || IsArmoryItemEquipped(player, item);
			normalizedItems.push(item);
		}
		return normalizedItems;
	}

	function GetShopItems() {
		var data = GetTable("supporter_pass_shop", "featured", null);
		var items = AsArray(data && data.items ? data.items : data);
		return items.length > 0 ? items : DEFAULT_SHOP_ITEMS;
	}

	function GetArmoryItems(player) {
		var playerID = Players.GetLocalPlayer();
		var items = AsArray(GetTable("supporter_pass_armory", "rewards_" + playerID, []));
		return items.length > 0 ? NormalizeBackendArmoryItems(items, player) : BuildLegacyBattlepassArmory(player);
	}

	function GetLeaderboardEntries() {
		var tables = CustomNetTables.GetAllTableValues ? CustomNetTables.GetAllTableValues("supporter_pass_leaderboards") : [];
		var entries = [];

		for (var i = 0; i < tables.length; i++) {
			if (tables[i] && tables[i].value) {
				entries.push(tables[i].value);
			}
		}

		return entries.length > 0 ? entries : DEFAULT_LEADERBOARD_ENTRIES;
	}

	function IsTruthy(value, fallbackValue) {
		if (value === undefined || value === null) {
			return fallbackValue === true;
		}

		return value === true || value === 1 || value === "1" || value === "true";
	}

	function CopySettings(settings) {
		return {
			toggle_tag: settings.toggle_tag === true,
			pass_rewards: settings.pass_rewards === true,
			player_xp: settings.player_xp === true,
			winrate_toggle: settings.winrate_toggle === true,
		};
	}

	function SettingsEqual(a, b) {
		return a.toggle_tag === b.toggle_tag &&
			a.pass_rewards === b.pass_rewards &&
			a.player_xp === b.player_xp &&
			a.winrate_toggle === b.winrate_toggle;
	}

	function BuildSettingsFromPlayer(player) {
		var passRewards = player.raw.pass_rewards !== undefined ? player.raw.pass_rewards : player.raw.bp_rewards;
		return {
			toggle_tag: IsTruthy(player.raw.toggle_tag, true),
			pass_rewards: passRewards === 0 ? false : IsTruthy(passRewards, true),
			player_xp: IsTruthy(player.raw.player_xp, true),
			winrate_toggle: IsTruthy(player.raw.winrate_toggle, true),
		};
	}

	function SetPercent(panel, current, max) {
		if (!panel) {
			return;
		}
		panel.style.width = Clamp(Math.floor((ToNumber(current, 0) / Math.max(ToNumber(max, 1), 1)) * 100), 0, 100) + "%";
	}

	function SetText(id, value) {
		var panel = Panel(id);
		if (panel) {
			panel.text = value;
		}
	}

	function PulseFragmentsCounter() {
		var counter = Panel("XHSSupporterFragmentsCounter");
		if (!counter) {
			return;
		}

		counter.SetHasClass("IsPulsing", false);
		$.Schedule(0.01, function () {
			if (counter && (!counter.IsValid || counter.IsValid())) {
				counter.SetHasClass("IsPulsing", true);
			}
		});
		$.Schedule(0.38, function () {
			if (counter && (!counter.IsValid || counter.IsValid())) {
				counter.SetHasClass("IsPulsing", false);
			}
		});
	}

	function ShowFragmentGainFlyout(amount, tierID) {
		if (amount <= 0) {
			return;
		}

		var button = Panel("XHSSupporterPassButton");
		if (!button) {
			return;
		}

		var flyout = $.CreatePanel("Panel", button, "XHSSupporterFragmentFlyout" + fragmentFlyoutIndex++);
		flyout.AddClass("XHSSupporterFragmentFlyout");
		flyout.hittest = false;
		ApplySupporterTierClasses(flyout, tierID);

		var icon = $.CreatePanel("Label", flyout, "");
		icon.AddClass("XHSSupporterFragmentFlyoutIcon");
		icon.hittest = false;
		icon.text = "F";

		var value = $.CreatePanel("Label", flyout, "");
		value.AddClass("XHSSupporterFragmentFlyoutValue");
		value.hittest = false;
		value.text = "+" + FormatNumber(amount);

		$.Schedule(0.03, function () {
			if (flyout && (!flyout.IsValid || flyout.IsValid())) {
				flyout.AddClass("IsFlying");
			}
		});
		$.Schedule(0.46, PulseFragmentsCounter);
		$.Schedule(0.9, function () {
			if (flyout && (!flyout.IsValid || flyout.IsValid())) {
				flyout.DeleteAsync(0.0);
			}
		});
	}

	function UpdateFragmentsCounter(player) {
		var button = Panel("XHSSupporterPassButton");
		if (button) {
			ApplySupporterTierClasses(button, player.tier_id);
		}

		var fragments = Math.max(0, ToNumber(player.fragments, 0));
		SetText("XHSSupporterFragmentsCounterValue", FormatNumber(fragments));

		var counter = Panel("XHSSupporterFragmentsCounter");
		if (counter) {
			counter.SetHasClass("HasFragments", fragments > 0);
		}

		if (!player.has_fragment_balance && !fragmentCounterInitialized) {
			return;
		}

		if (!fragmentCounterInitialized) {
			lastLocalFragmentBalance = fragments;
			fragmentCounterInitialized = true;
			return;
		}

		if (fragments > lastLocalFragmentBalance) {
			ShowFragmentGainFlyout(fragments - lastLocalFragmentBalance, player.tier_id);
		}

		lastLocalFragmentBalance = fragments;
	}

	function OpenExternalURL(url) {
		if (!url) {
			return;
		}

		if (typeof ExternalBrowserGoToURL === "function") {
			ExternalBrowserGoToURL(url);
			return;
		}

		$.DispatchEvent("ExternalBrowserGoToURL", url);
	}

	function ShowActionMessage(message, success) {
		var toast = Panel("XHSPassActionToast");
		var label = Panel("XHSPassActionToastText");
		var text = message || (success ? "Done." : "Action failed.");

		if (!toast || !label) {
			$.Msg("[XHS Supporter Pass] " + (success ? "OK: " : "ERROR: ") + text);
			return;
		}

		actionToastSerial++;
		var serial = actionToastSerial;
		label.text = text;
		toast.SetHasClass("IsSuccess", success === true);
		toast.SetHasClass("IsError", success !== true);
		toast.SetHasClass("IsVisible", true);
		$.Msg("[XHS Supporter Pass] " + (success ? "OK: " : "ERROR: ") + text);

		$.Schedule(3.0, function () {
			if (serial === actionToastSerial && toast && (!toast.IsValid || toast.IsValid())) {
				toast.SetHasClass("IsVisible", false);
			}
		});
	}

	function ToggleWindow(forceVisible) {
		var window = Panel("XHSSupporterPassWindow");
		if (!window) {
			return;
		}

		var visible = forceVisible;
		if (visible === undefined) {
			visible = !window.BHasClass("IsVisible");
		}

		window.SetHasClass("IsVisible", visible);
		if (visible) {
			RenderAll();
			UpdateBackToTopButton();
			ScheduleBackToTopPoll();
		} else {
			backToTopPollScheduled = false;
		}
	}

	function SwitchPage(pageName) {
		if (DISABLED_PAGES[pageName]) {
			Game.EmitSound("General.Cancel");
			return;
		}

		for (var page in PAGE_IDS) {
			if (PAGE_IDS.hasOwnProperty(page)) {
				var pagePanel = Panel(PAGE_IDS[page]);
				if (pagePanel) {
					pagePanel.SetHasClass("IsVisible", page === pageName);
				}
			}
		}

		for (var tab in TAB_IDS) {
			if (TAB_IDS.hasOwnProperty(tab)) {
				var tabPanel = Panel(TAB_IDS[tab]);
				if (tabPanel) {
					tabPanel.SetHasClass("IsActive", tab === pageName);
				}
			}
		}

		UpdateBackToTopButton();
		ScheduleBackToTopPoll();
	}

	function GetCurrentScrollPanel() {
		var activePage = null;
		for (var page in PAGE_IDS) {
			if (!PAGE_IDS.hasOwnProperty(page)) {
				continue;
			}
			var pagePanel = Panel(PAGE_IDS[page]);
			if (pagePanel && pagePanel.BHasClass("IsVisible")) {
				activePage = page;
				break;
			}
		}

		if (activePage === "overview") {
			return Panel("XHSPassOverviewGrid");
		}
		if (activePage === "rewards") {
			return Panel("XHSPassRewardTracks");
		}
		if (activePage === "shop") {
			return Panel("XHSPassShopGrid");
		}
		if (activePage === "armory") {
			return Panel("XHSPassArmoryGrid");
		}
		if (activePage === "leaderboards") {
			return Panel("XHSPassLeaderboardRows");
		}
		if (activePage === "settings") {
			return Panel("XHSPassSettingsRows");
		}

		return null;
	}

	function UpdateBackToTopButton() {
		var button = Panel("XHSPassBackToTopButton");
		if (!button) {
			return;
		}

		var panel = GetCurrentScrollPanel();
		var scrollOffset = panel && typeof panel.scrolloffset_y === "number" ? panel.scrolloffset_y : 0;
		button.SetHasClass("IsVisible", scrollOffset > 40);
	}

	function ScheduleBackToTopPoll() {
		var window = Panel("XHSSupporterPassWindow");
		if (!window || !window.BHasClass("IsVisible") || backToTopPollScheduled) {
			return;
		}

		backToTopPollScheduled = true;
		$.Schedule(0.12, function () {
			backToTopPollScheduled = false;
			var currentWindow = Panel("XHSSupporterPassWindow");
			if (!currentWindow || !currentWindow.BHasClass("IsVisible")) {
				UpdateBackToTopButton();
				return;
			}

			UpdateBackToTopButton();
			ScheduleBackToTopPoll();
		});
	}

	function ScrollCurrentPageToTop() {
		var panel = GetCurrentScrollPanel();
		if (!panel) {
			return;
		}

		if (typeof panel.ScrollToTop === "function") {
			try {
				panel.ScrollToTop();
			} catch (e) {
			}
		}

		if (typeof panel.GetChildCount === "function" && panel.GetChildCount() > 0) {
			var firstChild = panel.GetChild(0);
			if (firstChild) {
				if (typeof firstChild.ScrollParentToMakePanelFit === "function") {
					try {
						firstChild.ScrollParentToMakePanelFit(0, false);
					} catch (e2) {
					}
				}
				$.DispatchEvent("ScrollPanelIntoView", firstChild);
			}
		}

		var button = Panel("XHSPassBackToTopButton");
		if (button) {
			button.SetHasClass("IsVisible", false);
		}

		$.Schedule(0.05, UpdateBackToTopButton);
	}

	function CreateEmpty(parent, title, body) {
		ClearPanel(parent);
		if (!parent) {
			return;
		}

		var empty = $.CreatePanel("Panel", parent, "");
		empty.AddClass("XHSPassEmpty");

		var titlePanel = $.CreatePanel("Label", empty, "");
		titlePanel.AddClass("XHSPassEmptyTitle");
		titlePanel.text = title;

		var bodyPanel = $.CreatePanel("Label", empty, "");
		bodyPanel.AddClass("XHSPassEmptyBody");
		bodyPanel.text = body;
	}

	function RenderHeader(player) {
		ApplySupporterTierClasses(Panel("XHSSupporterPassWindow"), player.tier_id);
		UpdateFragmentsCounter(player);

		var avatar = Panel("XHSPassAvatar");
		if (avatar && player.steamID) {
			avatar.steamid = player.steamID;
		}

		SetText("XHSPassTierValue", player.tier_name);
		SetText("XHSPassFragmentsValue", FormatNumber(player.fragments));
		SetText("XHSPassWeeklyCapValue", FormatNumber(player.daily_fragments || player.weekly_fragments) + " / " + FormatNumber(player.daily_cap || player.weekly_cap));
		SetText("XHSPassGlobalXPValue", FormatXHSAccountXPSummary(player));
		SetText("XHSPassSeasonXPValue", FormatSupporterXPSummary(player));
		SetText("XHSPassXPBoostValue", "+" + FormatNumber(player.xp_boost) + "%");
		SetText("XHSPassVotePowerValue", FormatVotePower(player.vote_power));
		SetText("XHSPassPlayerName", player.name);
		SetText("XHSPassPlayerTier", player.tier_name);
		SetText("XHSPassLevelLabel", "Season Level " + player.season_level);
		SetText("XHSPassXpLabel", FormatNumber(player.season_xp) + " / " + FormatNumber(player.season_xp_max) + " XP");
		SetPercent(Panel("XHSPassXpProgress"), player.season_xp, player.season_xp_max);
		SetPercent(Panel("XHSPassWeeklyProgress"), player.daily_fragments || player.weekly_fragments, player.daily_cap || player.weekly_cap);

		var tierLabel = Panel("XHSPassPlayerTier");
		if (tierLabel) {
			tierLabel.style.color = player.tier_color;
		}

		var tierValue = Panel("XHSPassTierValue");
		if (tierValue) {
			tierValue.style.color = player.tier_color;
		}

		var boostValue = Panel("XHSPassXPBoostValue");
		if (boostValue) {
			boostValue.style.color = player.tier_id > 0 ? player.tier_color : "#f3fbff";
		}

		var votePowerValue = Panel("XHSPassVotePowerValue");
		if (votePowerValue) {
			votePowerValue.style.color = player.tier_id > 0 ? player.tier_color : "#f3fbff";
		}
	}

	function RenderTiers() {
		var parent = Panel("XHSPassTierRows");
		ClearPanel(parent);

		var player = GetLocalPlayerData();
		var supporterURL = player.supporter_url || SUPPORTER_URL;
		var tiers = GetTiers();
		for (var i = 0; i < tiers.length; i++) {
			var tier = GetTierMeta(tiers[i]);
			var isOwnedTier = tier.id > 0 && tier.id === player.tier_id;
			var row = $.CreatePanel("Panel", parent, "");
			row.AddClass("XHSPassTierCard");
			row.AddClass("Tier" + tier.id);
			row.SetHasClass("Featured", tier.featured);
			row.SetHasClass("IsOwnedTier", isOwnedTier);
			row.SetHasClass("IsClickable", !isOwnedTier);
			row.hittest = true;
			if (!isOwnedTier) {
				(function (url) {
					row.SetPanelEvent("onactivate", function () {
						Game.EmitSound("General.ButtonClick");
						OpenExternalURL(url);
					});
				})(supporterURL);
			}

			var art = $.CreatePanel("Panel", row, "");
			art.AddClass("XHSPassTierArt");
			art.hittest = false;
			if (tier.image) {
				art.style.backgroundImage = 'url("file://{images}/custom_game/' + tier.image + '")';
			}

			var shade = $.CreatePanel("Panel", row, "");
			shade.AddClass("XHSPassTierShade");
			shade.hittest = false;

			var sweep = $.CreatePanel("Panel", row, "");
			sweep.AddClass("XHSPassTierSweep");
			sweep.hittest = false;

			if (isOwnedTier) {
				var owned = $.CreatePanel("Panel", row, "");
				owned.AddClass("XHSPassTierOwnedTooltip");
				owned.hittest = false;

				var ownedTitle = $.CreatePanel("Label", owned, "");
				ownedTitle.AddClass("XHSPassTierOwnedTitle");
				ownedTitle.text = "Current Tier";

				var ownedText = $.CreatePanel("Label", owned, "");
				ownedText.AddClass("XHSPassTierOwnedText");
				ownedText.text = "You already have this tier";
			}

			var top = $.CreatePanel("Panel", row, "");
			top.AddClass("XHSPassTierTopline");
			top.hittest = false;

			var mark = $.CreatePanel("Label", top, "");
			mark.AddClass("XHSPassTierMark");
			mark.text = tier.label;
			mark.hittest = false;

			var name = $.CreatePanel("Label", row, "");
			name.AddClass("XHSPassTierName");
			name.text = tier.name;
			name.hittest = false;

			var price = $.CreatePanel("Label", row, "");
			price.AddClass("XHSPassTierPrice");
			price.text = tier.price;
			price.hittest = false;

			var copy = $.CreatePanel("Label", row, "");
			copy.AddClass("XHSPassTierCopy");
			copy.text = tier.text;
			copy.hittest = false;

			var tagList = $.CreatePanel("Panel", row, "");
			tagList.AddClass("XHSPassTagList");
			tagList.hittest = false;
			for (var p = 0; p < tier.perks.length; p++) {
				var tag = $.CreatePanel("Label", tagList, "");
				tag.AddClass("XHSPassTag");
				tag.text = tier.perks[p];
				tag.hittest = false;
			}

			var cta = $.CreatePanel("Label", row, "");
			cta.AddClass("XHSPassTierCTA");
			cta.text = isOwnedTier ? "Active on your account" : "Support on Patreon";
			cta.hittest = false;
		}
	}

	function CreateRewardCard(parent, reward, player, track) {
		var card = $.CreatePanel("Panel", parent, "");
		card.AddClass("XHSPassRewardCard");
		var legacyReward = IsTruthy(reward.legacy, false) || reward.claimable === false;
		var rewardClaimed = IsRewardClaimed(reward, player);
		card.SetHasClass("IsLegacyReward", legacyReward);

		var image = $.CreatePanel("Panel", card, "");
		image.AddClass("XHSPassRewardImage");
		SetCustomGameImage(image, reward.image);

		var level = $.CreatePanel("Label", card, "");
		level.AddClass("XHSPassRewardLevel");
		level.text = "Level " + (reward.level || "-");

		var name = $.CreatePanel("Label", card, "");
		name.AddClass("XHSPassRewardName");
		name.text = LocalizeMaybeKey(reward.name || reward.item_name || "Reward");

		var type = $.CreatePanel("Label", card, "");
		type.AddClass("XHSPassRewardType");
		type.text = rewardClaimed ? "Claimed" : (legacyReward ? "Legacy Reward" : NormalizeRewardType(reward.type || reward.item_type || "Reward"));

		var rewardID = GetRewardID(reward);
		if (rewardID) {
			var button = $.CreatePanel("Button", card, "");
			button.AddClass("XHSPassShopButton");
			var requiredLevel = ToNumber(reward.level_required || reward.level, 1);
			var premiumLocked = (track === "premium" || reward.track === "premium" || reward.premium === 1 || reward.premium === "1") && player.tier_id < 1;
			var canClaim = !legacyReward && !rewardClaimed && player.season_level >= requiredLevel && !premiumLocked;
			button.SetHasClass("IsLocked", !canClaim);
			button.SetPanelEvent("onactivate", function () {
				if (!canClaim) {
					Game.EmitSound("General.Cancel");
					return;
				}
				GameEvents.SendCustomGameEventToServer("supporter_pass_claim_reward", {
					reward_id: rewardID,
					item_id: reward.item_id || rewardID,
				});
			});

			var label = $.CreatePanel("Label", button, "");
			label.text = legacyReward ? "Legacy" : (rewardClaimed ? "Claimed" : (canClaim ? "Claim" : "Locked"));
		}
	}

	function RenderRewardTrack(parent, title, rewards, player, track) {
		var trackPanel = $.CreatePanel("Panel", parent, "");
		trackPanel.AddClass("XHSPassRewardTrack");

		var titlePanel = $.CreatePanel("Label", trackPanel, "");
		titlePanel.AddClass("XHSPassRewardTrackTitle");
		titlePanel.text = title;

		var row = $.CreatePanel("Panel", trackPanel, "");
		row.AddClass("XHSPassRewardRow");

		if (!rewards || rewards.length === 0) {
			var empty = $.CreatePanel("Label", row, "");
			empty.AddClass("XHSPassEmptyBody");
			empty.text = "No rewards configured for this track yet.";
			return;
		}

		for (var i = 0; i < rewards.length; i++) {
			CreateRewardCard(row, rewards[i], player, track);
		}
	}

	function RenderRewards(player) {
		var parent = Panel("XHSPassRewardTracks");
		ClearPanel(parent);

		if (!parent) {
			return;
		}

		RenderRewardTrack(parent, "Free Track", GetRewards("free"), player, "free");
		RenderRewardTrack(parent, "Supporter Track", GetRewards("premium"), player, "premium");
	}

	function CreateShopCard(parent, item, player, mode) {
		var card = $.CreatePanel("Panel", parent, "");
		card.AddClass("XHSPassShopCard");

		var image = $.CreatePanel("Panel", card, "");
		image.AddClass("XHSPassShopImage");
		SetCustomGameImage(image, item.image);

		var name = $.CreatePanel("Label", card, "");
		name.AddClass("XHSPassShopName");
		name.text = LocalizeMaybeKey(item.name || item.item_name || item.id || "Shop Item");

		var meta = $.CreatePanel("Label", card, "");
		meta.AddClass("XHSPassShopMeta");
		meta.text = (item.rarity || "Common") + " " + (item.type || item.item_type || "Cosmetic");

		var price = $.CreatePanel("Label", card, "");
		price.AddClass("XHSPassShopPrice");
		if (mode === "armory") {
			price.text = item.locked ? (item.lock_reason || "Locked") : (item.equipped ? "Equipped" : "Unlocked");
		} else {
			price.text = FormatNumber(item.price || item.fragment_price || 0) + " fragments";
		}

		var button = $.CreatePanel("Button", card, "");
		button.AddClass("XHSPassShopButton");
		var canAfford = mode === "armory" ? item.locked !== true : player.fragments >= ToNumber(item.price || item.fragment_price, 0);
		button.SetHasClass("IsLocked", !canAfford);
		button.SetPanelEvent("onactivate", function () {
			if (!canAfford) {
				Game.EmitSound("General.Cancel");
				return;
			}

			if (mode === "armory") {
				GameEvents.SendCustomGameEventToServer("supporter_pass_equip_item", {
					item_id: item.entitlement_id || item.id || item.item_id,
					hero: item.hero || "global",
					slot_id: item.slot_id || "default",
				});
				Game.EmitSound("General.ButtonClick");
				return;
			}

			GameEvents.SendCustomGameEventToServer("supporter_pass_buy_shop_item", {
				item_id: item.id || item.item_id,
			});
		});

		var label = $.CreatePanel("Label", button, "");
		label.text = mode === "armory" ? (item.locked ? "Locked" : (item.equipped ? "Equipped" : "Equip")) : (canAfford ? "Buy" : "Locked");
	}

	function RenderShop(player) {
		var parent = Panel("XHSPassShopGrid");
		ClearPanel(parent);

		var data = GetTable("supporter_pass_shop", "featured", {}) || {};
		var refresh = data.refresh_label || data.refresh_at || "Featured rotation";
		SetText("XHSPassShopRefresh", refresh.toString());

		var items = GetShopItems();
		currentShopFilter = RenderCategoryTabs("XHSPassShopFilters", items, currentShopFilter, function (filterName) {
			currentShopFilter = filterName;
			RenderShop(player);
		});

		if (items.length === 0) {
			CreateEmpty(parent, "Shop unavailable", "The Fragment Shop catalog has not been sent by the backend yet.");
			return;
		}

		var filteredItems = FilterItemsByCategory(items, currentShopFilter);
		if (filteredItems.length === 0) {
			CreateEmpty(parent, "No shop items", "No Fragment Shop items match this category.");
			return;
		}

		for (var i = 0; i < filteredItems.length; i++) {
			CreateShopCard(parent, filteredItems[i], player, "shop");
		}
	}

	function GetItemCategory(item) {
		return NormalizeRewardType(item.type || item.item_type || "Cosmetic");
	}

	function GetItemCategories(items) {
		var filters = ["All"];
		for (var i = 0; i < items.length; i++) {
			var type = GetItemCategory(items[i]);
			var exists = false;
			for (var j = 0; j < filters.length; j++) {
				if (filters[j] === type) {
					exists = true;
					break;
				}
			}
			if (!exists) {
				filters.push(type);
			}
		}
		return filters;
	}

	function FilterItemsByCategory(items, category) {
		if (category === "All") {
			return items;
		}

		var filtered = [];
		for (var i = 0; i < items.length; i++) {
			if (GetItemCategory(items[i]) === category) {
				filtered.push(items[i]);
			}
		}
		return filtered;
	}

	function RenderCategoryTabs(parentID, items, activeFilter, onSelect) {
		var parent = Panel(parentID);
		ClearPanel(parent);
		if (!parent) {
			return activeFilter;
		}

		var filters = GetItemCategories(items);
		var activeExists = false;
		for (var f = 0; f < filters.length; f++) {
			if (filters[f] === activeFilter) {
				activeExists = true;
				break;
			}
		}
		if (!activeExists) {
			activeFilter = "All";
		}

		for (var i = 0; i < filters.length; i++) {
			(function (filterName) {
				var button = $.CreatePanel("Button", parent, "");
				button.AddClass("XHSPassFilterTab");
				button.SetHasClass("IsActive", activeFilter === filterName);
				button.SetPanelEvent("onactivate", function () {
					onSelect(filterName);
				});

				var label = $.CreatePanel("Label", button, "");
				label.text = filterName;
			})(filters[i]);
		}

		return activeFilter;
	}

	function RenderArmory(player) {
		var parent = Panel("XHSPassArmoryGrid");
		ClearPanel(parent);

		var items = GetArmoryItems(player);
		currentArmoryFilter = RenderCategoryTabs("XHSPassArmoryFilters", items, currentArmoryFilter, function (filterName) {
			currentArmoryFilter = filterName;
			RenderArmory(player);
		});

		if (items.length === 0) {
			CreateEmpty(parent, "No equipped cosmetics", "Unlock cosmetics through the Supporter Pass or Fragment Shop, then equip them here.");
			return;
		}

		var filteredItems = FilterItemsByCategory(items, currentArmoryFilter);
		if (filteredItems.length === 0) {
			CreateEmpty(parent, "No armory items", "No unlocked cosmetics match this category.");
			return;
		}

		for (var j = 0; j < filteredItems.length; j++) {
			CreateShopCard(parent, filteredItems[j], player, "armory");
		}
	}

	function CreateInfoRow(parent, title, description, value) {
		var row = $.CreatePanel("Panel", parent, "");
		row.AddClass("XHSPassSettingRow");

		var copy = $.CreatePanel("Panel", row, "");
		copy.AddClass("XHSPassRowMain");

		var titlePanel = $.CreatePanel("Label", copy, "");
		titlePanel.AddClass("XHSPassRowTitle");
		titlePanel.text = title;

		var descPanel = $.CreatePanel("Label", copy, "");
		descPanel.AddClass("XHSPassRowDescription");
		descPanel.text = description;

		var valuePanel = $.CreatePanel("Label", row, "");
		valuePanel.AddClass("XHSPassRowValue");
		valuePanel.text = value;
	}

	function UpdateSettingsSaveBar() {
		var bar = Panel("XHSPassSettingsSaveBar");
		if (!bar) {
			return;
		}

		bar.SetHasClass("IsDirty", !SettingsEqual(settingsOriginal, settingsDraft) || settingsSaving);
		bar.SetHasClass("IsSaving", settingsSaving);

		var label = bar.FindChildTraverse("XHSPassSettingsSaveText");
		if (label) {
			label.text = settingsSaving ? "Saving settings..." : "Unsaved changes";
		}
	}

	function CreateSettingRow(parent, key, title, description) {
		var row = $.CreatePanel("Panel", parent, "");
		row.AddClass("XHSPassSettingRow");
		row.SetHasClass("IsEnabled", settingsDraft[key] === true);
		row.hittest = true;

		var copy = $.CreatePanel("Panel", row, "");
		copy.AddClass("XHSPassRowMain");
		copy.hittest = false;

		var titlePanel = $.CreatePanel("Label", copy, "");
		titlePanel.AddClass("XHSPassRowTitle");
		titlePanel.text = title;
		titlePanel.hittest = false;

		var descPanel = $.CreatePanel("Label", copy, "");
		descPanel.AddClass("XHSPassRowDescription");
		descPanel.text = description;
		descPanel.hittest = false;

		var toggle = $.CreatePanel("Panel", row, "XHSPassSetting_" + key);
		toggle.AddClass("XHSPassSettingToggle");
		toggle.SetHasClass("IsEnabled", settingsDraft[key] === true);
		toggle.hittest = false;

		var knob = $.CreatePanel("Panel", toggle, "");
		knob.AddClass("XHSPassSettingToggleKnob");
		knob.hittest = false;

		row.SetPanelEvent("onactivate", function () {
			if (settingsSaving) {
				Game.EmitSound("General.Cancel");
				return;
			}

			settingsDraft[key] = settingsDraft[key] !== true;
			row.SetHasClass("IsEnabled", settingsDraft[key] === true);
			toggle.SetHasClass("IsEnabled", settingsDraft[key] === true);
			UpdateSettingsSaveBar();
			Game.EmitSound("General.ButtonClick");
		});
	}

	function CreateSettingActionRow(parent, title, description, buttonText, callback) {
		var row = $.CreatePanel("Panel", parent, "");
		row.AddClass("XHSPassSettingRow");
		row.AddClass("XHSPassSettingActionRow");
		row.hittest = true;

		var copy = $.CreatePanel("Panel", row, "");
		copy.AddClass("XHSPassRowMain");
		copy.hittest = false;

		var titlePanel = $.CreatePanel("Label", copy, "");
		titlePanel.AddClass("XHSPassRowTitle");
		titlePanel.text = title;
		titlePanel.hittest = false;

		var descPanel = $.CreatePanel("Label", copy, "");
		descPanel.AddClass("XHSPassRowDescription");
		descPanel.text = description;
		descPanel.hittest = false;

		var button = $.CreatePanel("Button", row, "");
		button.AddClass("XHSPassSettingActionButton");
		button.SetPanelEvent("onactivate", callback);

		var label = $.CreatePanel("Label", button, "");
		label.text = buttonText;
	}

	function RenderSettings(player) {
		var parent = Panel("XHSPassSettingsRows");
		ClearPanel(parent);

		if (!settingsInitialized) {
			settingsOriginal = BuildSettingsFromPlayer(player);
			settingsDraft = CopySettings(settingsOriginal);
			settingsInitialized = true;
		}

		CreateSettingRow(parent, "toggle_tag", "Supporter tag", "Display your supporter badge above your hero health bar.");
		CreateSettingRow(parent, "pass_rewards", "Cosmetic rewards", "Enable or disable equipped pass cosmetics in-game.");
		CreateSettingRow(parent, "player_xp", "XP visibility", "Show seasonal and account XP in social UI surfaces.");
		CreateSettingRow(parent, "winrate_toggle", "Winrate visibility", "Show your seasonal winrate in public profile surfaces.");
		CreateSettingActionRow(parent, "Companion", "Remove your current supporter companion for this match.", "Disable", function () {
			if (GameEvents && GameEvents.SendCustomGameEventToServer) {
				GameEvents.SendCustomGameEventToServer("supporter_pass_change_companion", {
					ID: Players.GetLocalPlayer(),
					unit: "",
					js: true,
				});
				ShowActionMessage("Companion disabled.", true);
				Game.EmitSound("General.ButtonClick");
			}
		});
		UpdateSettingsSaveBar();
	}

	function RenderLeaderboards() {
		var parent = Panel("XHSPassLeaderboardRows");
		ClearPanel(parent);

		var entries = GetLeaderboardEntries();
		if (entries.length === 0) {
			CreateEmpty(parent, "No leaderboard data", "Leaderboard data is unavailable for this match or season.");
			return;
		}

		for (var i = 0; i < entries.length; i++) {
			var entry = entries[i];
			var row = $.CreatePanel("Panel", parent, "");
			row.AddClass("XHSPassLeaderboardRow");

			var copy = $.CreatePanel("Panel", row, "");
			copy.AddClass("XHSPassRowMain");

			var title = $.CreatePanel("Label", copy, "");
			title.AddClass("XHSPassRowTitle");
			title.text = entry.name || entry.player_name || "Player";

			var desc = $.CreatePanel("Label", copy, "");
			desc.AddClass("XHSPassRowDescription");
			desc.text = entry.type || "Season leaderboard";

			var value = $.CreatePanel("Label", row, "");
			value.AddClass("XHSPassRowValue");
			value.text = FormatNumber(entry.score || entry.xp || entry.value || 0);
		}
	}

	function RenderAll() {
		var player = GetLocalPlayerData();
		RenderHeader(player);
		RenderTiers();
		RenderRewards(player);
		RenderShop(player);
		RenderArmory(player);
		RenderLeaderboards();
		RenderSettings(player);
	}

	function BindButtons() {
		var button = Panel("XHSSupporterPassButton");
		if (button) {
			button.SetPanelEvent("onactivate", function () {
				RenderAll();
				ToggleWindow();
			});
		}

		var close = Panel("XHSPassCloseButton");
		if (close) {
			close.SetPanelEvent("onactivate", function () { ToggleWindow(false); });
		}

		var support = Panel("XHSPassSupportButton");
		if (support) {
			support.SetPanelEvent("onactivate", function () {
				OpenExternalURL(GetLocalPlayerData().supporter_url || SUPPORTER_URL);
			});
		}

		var backToTop = Panel("XHSPassBackToTopButton");
		if (backToTop) {
			backToTop.SetPanelEvent("onactivate", ScrollCurrentPageToTop);
		}

		var saveSettings = Panel("XHSPassSettingsSaveButton");
		if (saveSettings) {
			saveSettings.SetPanelEvent("onactivate", function () {
				if (settingsSaving || SettingsEqual(settingsOriginal, settingsDraft)) {
					return;
				}

				settingsSaving = true;
				Game.EmitSound("General.ButtonClick");
				UpdateSettingsSaveBar();
				if (GameEvents && GameEvents.SendCustomGameEventToServer) {
					var payload = CopySettings(settingsDraft);
					payload.player_id = Players.GetLocalPlayer();
					GameEvents.SendCustomGameEventToServer("supporter_pass_update_settings", payload);
					$.Schedule(8.0, function () {
						if (!settingsSaving) {
							return;
						}

						settingsSaving = false;
						settingsDraft = CopySettings(settingsOriginal);
						RenderSettings(GetLocalPlayerData());
						ShowActionMessage("Settings save timed out.", false);
					});
				} else {
					settingsSaving = false;
					UpdateSettingsSaveBar();
				}
			});
		}

		var cancelSettings = Panel("XHSPassSettingsCancelButton");
		if (cancelSettings) {
			cancelSettings.SetPanelEvent("onactivate", function () {
				if (settingsSaving) {
					Game.EmitSound("General.Cancel");
					return;
				}

				settingsDraft = CopySettings(settingsOriginal);
				RenderSettings(GetLocalPlayerData());
				Game.EmitSound("General.Cancel");
			});
		}

		for (var page in TAB_IDS) {
			if (TAB_IDS.hasOwnProperty(page)) {
				(function (pageName) {
					var tab = Panel(TAB_IDS[pageName]);
					if (tab) {
						var isDisabled = DISABLED_PAGES[pageName] === true;
						tab.SetHasClass("IsDisabled", isDisabled);
						tab.SetPanelEvent("onactivate", function () { SwitchPage(pageName); });
					}
				})(page);
			}
		}

		if (GameEvents && GameEvents.Subscribe) {
			GameEvents.Subscribe("supporter_pass_purchase_pending", function () {
				ShowActionMessage("Supporter Pass purchase pending...", true);
			});
			GameEvents.Subscribe("supporter_pass_purchase_success", function (payload) {
				ShowActionMessage(payload && payload.already_owned ? "Already owned." : "Purchase complete.", true);
				RenderAll();
			});
			GameEvents.Subscribe("supporter_pass_purchase_failed", function (payload) {
				ShowActionMessage((payload && payload.message) || "Purchase failed.", false);
			});
			GameEvents.Subscribe("supporter_pass_claim_success", function (payload) {
				ShowActionMessage(payload && payload.already_claimed ? "Reward already claimed." : "Reward claimed.", true);
				RenderAll();
			});
			GameEvents.Subscribe("supporter_pass_claim_failed", function (payload) {
				ShowActionMessage((payload && payload.message) || "Reward claim failed.", false);
			});
			GameEvents.Subscribe("supporter_pass_equip_success", function () {
				ShowActionMessage("Cosmetic equipped.", true);
				RenderAll();
			});
			GameEvents.Subscribe("supporter_pass_equip_failed", function (payload) {
				ShowActionMessage((payload && payload.message) || "Equip failed.", false);
			});
			GameEvents.Subscribe("supporter_pass_settings_failed", function (payload) {
				settingsSaving = false;
				settingsDraft = CopySettings(settingsOriginal);
				RenderSettings(GetLocalPlayerData());
				ShowActionMessage((payload && payload.message) || "Settings save failed.", false);
			});
			GameEvents.Subscribe("supporter_pass_settings_success", function () {
				settingsSaving = false;
				settingsOriginal = CopySettings(settingsDraft);
				UpdateSettingsSaveBar();
				ShowActionMessage("Settings saved.", true);
			});
		}
	}

	function Init() {
		BindButtons();
		SwitchPage("overview");
		RenderAll();

		if (CustomNetTables.SubscribeNetTableListener) {
			CustomNetTables.SubscribeNetTableListener("supporter_pass_player", RenderAll);
			CustomNetTables.SubscribeNetTableListener("supporter_pass_shop", RenderAll);
			CustomNetTables.SubscribeNetTableListener("supporter_pass_meta", RenderAll);
			CustomNetTables.SubscribeNetTableListener("supporter_pass_rewards_free", RenderAll);
			CustomNetTables.SubscribeNetTableListener("supporter_pass_rewards_premium", RenderAll);
		}
	}

	return {
		Init: Init,
		RenderAll: RenderAll,
		OpenDiscord: function () { OpenExternalURL(DISCORD_URL); },
	};
})();

(function () {
	$.Schedule(0.0, XHSSupporterPass.Init);
})();
