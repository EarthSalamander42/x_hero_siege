"use strict";

var XHSEndScreen = (function () {
	var WEBSITE_URL = "https://mods.frostrose-studio.com";
	var DISCORD_URL = "https://discord.frostrose-studio.com/";
	var SUPPORTER_URL = "https://mods.frostrose-studio.com/supporter-pass";
	var supporterPortalRequestPending = false;
	var PLAYER_COLOR_FALLBACKS = [
		"#0032c8ff",
		"#00ffffff",
		"#640064ff",
		"#ffff00ff",
		"#ff9600ff",
		"#ff64ffff",
		"#a3b000ff",
		"#65d9f7ff",
		"#007d00ff",
		"#a46900ff",
		"#78ff50ff",
		"#50a0ffff",
		"#b464ffff",
		"#ffd250ff",
		"#50ffbeff",
		"#ff6eaaff",
		"#a0d2ffff",
		"#8296aaff",
		"#d28250ff",
		"#785a3cff",
		"#d2ff78ff",
		"#ff96d2ff",
		"#64dcdcff",
		"#bebeffff",
		"#e6e6e6ff",
	];

	var DIFFICULTY_NAMES = {
		1: "Easy",
		2: "Normal",
		3: "Hard",
		4: "Extreme",
		5: "Divine",
	};
	var endGameSubscription = null;
	var hasRenderedEndGame = false;
	var fallbackTimerStarted = false;
	var shownRewardKeys = {};
	var rewardQueue = [];
	var activeReward = null;
	var rewardRevealScheduled = false;
	var rewardBatchTotal = 0;
	var rewardBatchAccepted = 0;
	var rewardPanelSequence = 0;
	var lastEndGameData = null;
	var farmLeaderboardVisible = false;
	var xpPresentationPhase = "idle";
	var xpPresentationKey = "";
	var xpPresentationGeneration = 0;
	var xpPresentationModel = null;
	var xpPresentationData = null;
	var xpStepPanels = [];
	var xpLastAnimatedLevel = 1;
	var xpLevelBurstQueue = [];
	var xpLevelBurstActive = false;

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

	function FirstDefined() {
		for (var i = 0; i < arguments.length; i++) {
			if (arguments[i] !== undefined && arguments[i] !== null) {
				return arguments[i];
			}
		}

		return undefined;
	}

	function MaxNumber() {
		var best = 0;
		for (var i = 0; i < arguments.length; i++) {
			best = Math.max(best, ToNumber(arguments[i], 0));
		}
		return best;
	}

	function Clamp(value, minValue, maxValue) {
		return Math.max(minValue, Math.min(maxValue, value));
	}

	function IntToColorString(value) {
		return "#" +
			("00" + (value & 0xFF).toString(16)).substr(-2) +
			("00" + ((value >> 8) & 0xFF).toString(16)).substr(-2) +
			("00" + ((value >> 16) & 0xFF).toString(16)).substr(-2) +
			"ff";
	}

	function NormalizeColorString(color) {
		if (color === undefined || color === null) {
			return "";
		}

		var colorString = color.toString();
		if (colorString.charAt(0) !== "#") {
			colorString = "#" + colorString;
		}

		if (colorString.length === 7) {
			colorString += "ff";
		}

		return colorString.toLowerCase();
	}

	function IsInvalidPlayerColorString(colorString) {
		return !colorString || colorString === "#ffffffff" || colorString === "#ffffff";
	}

	function GetFallbackPlayerColorString(playerID) {
		var fallbackIndex = ((playerID % PLAYER_COLOR_FALLBACKS.length) + PLAYER_COLOR_FALLBACKS.length) % PLAYER_COLOR_FALLBACKS.length;
		return PLAYER_COLOR_FALLBACKS[fallbackIndex];
	}

	function GetPlayerColorString(playerID, tableColor) {
		var normalizedTableColor = NormalizeColorString(tableColor);
		if (!IsInvalidPlayerColorString(normalizedTableColor)) {
			return normalizedTableColor;
		}

		var playerColors = CustomNetTables.GetTableValue("game_options", "player_colors");
		normalizedTableColor = NormalizeColorString(playerColors ? playerColors[playerID] : null);
		if (!IsInvalidPlayerColorString(normalizedTableColor)) {
			return normalizedTableColor;
		}

		var engineColor = Safe(function () {
			return Players.GetPlayerColor(playerID);
		}, null);
		var engineColorString = engineColor === null ? "" : IntToColorString(engineColor);
		if (!IsInvalidPlayerColorString(engineColorString)) {
			return engineColorString;
		}

		return GetFallbackPlayerColorString(playerID);
	}

	function ColorWithAlpha(colorString, alpha) {
		colorString = NormalizeColorString(colorString);
		if (!colorString || colorString.length < 7) {
			return colorString;
		}

		return colorString.substr(0, 7) + alpha;
	}

	function FormatTime(time) {
		var totalSeconds = Math.max(0, Math.floor(ToNumber(time, 0)));
		var minutes = Math.floor(totalSeconds / 60);
		var seconds = totalSeconds % 60;
		return minutes + ":" + (seconds < 10 ? "0" : "") + seconds;
	}

	function FormatNumber(value) {
		var numberValue = ToNumber(value, 0);
		var sign = numberValue < 0 ? "-" : "";
		var absValue = Math.abs(numberValue);

		if (absValue >= 1000000) {
			return sign + (absValue / 1000000).toFixed(1) + "M";
		}

		if (absValue >= 10000) {
			return sign + (absValue / 1000).toFixed(1) + "k";
		}

		return sign + Math.floor(absValue).toString();
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
		var token = value.toString();
		if (token.charAt(0) !== "#") {
			token = "#" + token;
		}
		return Localize(token);
	}

	function ResolveRewardImageURL(imagePath) {
		var path = (imagePath || "").toString().replace(/\\/g, "/");
		if (path.indexOf("s2r://") === 0) {
			return path;
		}
		path = path.replace(/^file:\/\/\{images\}\//, "");
		path = path.replace(/_png\.vtex$/, "");
		path = path.replace(/\.png$/, "");
		if (!path) {
			path = "battlepass/battlepass_new";
		}
		if (path.indexOf("custom_game/") === 0) {
			return "file://{images}/" + path + ".png";
		}
		if (path.indexOf("econ/") === 0 || path.indexOf("heroes/") === 0 ||
			path.indexOf("items/") === 0 || path.indexOf("spellicons/") === 0) {
			return "s2r://panorama/images/" + path + "_png.vtex";
		}
		return "file://{images}/custom_game/" + path + ".png";
	}

	function DisplaySupporterRewardType(reward) {
		var type = ((reward && (reward.type || reward.item_type || reward.slot_id)) || "reward").toString().toLowerCase();
		var aliases = {
			teleport: "xhs_sp_type_teleport",
			teleport_fx: "xhs_sp_type_teleport",
			levelup: "xhs_sp_type_tome",
			tome: "xhs_sp_type_tome",
			tome_fx: "xhs_sp_type_tome",
			kill_effect: "xhs_sp_type_kill",
			kill_fx: "xhs_sp_type_kill",
			emblem: "xhs_sp_type_emblem",
			companion: "xhs_sp_type_companion",
			courier: "xhs_sp_type_companion",
			effigy: "xhs_sp_type_effigy",
			statue: "xhs_sp_type_effigy",
			potion: "xhs_sp_type_potion",
			bottle: "xhs_sp_type_potion",
			mekansm: "xhs_sp_type_potion",
			rebirth: "xhs_sp_type_rebirth",
			ankh: "xhs_sp_type_rebirth",
			attack_lifesteal: "xhs_sp_type_attack_lifesteal",
			spell_lifesteal: "xhs_sp_type_spell_lifesteal",
			regen_aura: "xhs_sp_type_regen_aura",
			fountain: "xhs_sp_type_regen_aura",
			immolation: "xhs_sp_type_immolation",
			radiance: "xhs_sp_type_immolation",
			high_five: "xhs_sp_type_high_five",
			highfive: "xhs_sp_type_high_five",
			title: "xhs_sp_type_title",
			account_title: "xhs_sp_type_title",
			fragment: "xhs_sp_type_fragments",
			fragments: "xhs_sp_type_fragments",
		};
		if (aliases[type]) {
			return Localize("#" + aliases[type]);
		}
		return type.replace(/_/g, " ").replace(/\b\w/g, function (letter) {
			return letter.toUpperCase();
		});
	}

	function CollectSupporterRewards(value, result, depth) {
		if (!value || typeof value !== "object" || depth > 4) {
			return;
		}

		var hasLevel = value.level !== undefined || value.level_required !== undefined;
		var hasIdentity = value.reward_id !== undefined || value.item_id !== undefined ||
			value.catalog_item_id !== undefined || value.name !== undefined || value.item_name !== undefined;
		if (hasLevel && hasIdentity) {
			result.push(value);
			return;
		}

		for (var key in value) {
			if (value.hasOwnProperty(key) && value[key] && typeof value[key] === "object") {
				CollectSupporterRewards(value[key], result, depth + 1);
			}
		}
	}

	function GetTrackChunkKey(index, chunkIndex) {
		var keys = index && index.chunk_keys;
		if (Object.prototype.toString.call(keys) === "[object Array]") {
			return keys[chunkIndex - 1] || "";
		}
		if (keys && typeof keys === "object") {
			return keys[chunkIndex] || keys[chunkIndex.toString()] || "";
		}
		return "";
	}

	function CollectPublishedSupporterRewards(tableName, result) {
		var index = CustomNetTables.GetTableValue(tableName, "rewards") || {};
		var chunkCount = Math.max(0, Math.floor(ToNumber(index.chunk_count, 0)));
		if (chunkCount <= 0) {
			CollectSupporterRewards(index, result, 0);
			return;
		}

		for (var chunkIndex = 1; chunkIndex <= chunkCount; chunkIndex++) {
			var key = GetTrackChunkKey(index, chunkIndex);
			if (!key) {
				key = "chunk_" + (chunkIndex < 10 ? "0" : "") + chunkIndex;
			}
			var chunk = CustomNetTables.GetTableValue(tableName, key);
			CollectSupporterRewards(chunk, result, 0);
		}
	}

	function GetSupporterRewardAtLevel(track, level) {
		var tableName = track === "premium" ? "supporter_pass_rewards_premium" : "supporter_pass_rewards_free";
		var rewards = [];
		CollectPublishedSupporterRewards(tableName, rewards);
		var best = null;
		var bestPriority = -1;
		for (var i = 0; i < rewards.length; i++) {
			var reward = rewards[i] || {};
			if (Math.floor(ToNumber(reward.level_required || reward.level, 0)) !== level) {
				continue;
			}
			var priority = 0;
			if ((reward.season_id || reward.season || "").toString() === "2026") {
				priority += 100;
			}
			if ((reward.reward_id || reward.id || "").toString().toLowerCase().indexOf("sp26_") === 0) {
				priority += 50;
			}
			if (reward.legacy !== true && reward.legacy !== 1 && reward.legacy !== "1") {
				priority += 20;
			}
			if (ToNumber(reward.item_id || reward.catalog_item_id, 0) >= 41) {
				priority += 10;
			}
			if (priority >= bestPriority) {
				best = reward;
				bestPriority = priority;
			}
		}
		return best;
	}

	function ResolvePlayerIdentity(model) {
		model = model || {};
		if (typeof XHSNameDisplay !== "undefined" && XHSNameDisplay.Resolve) {
			return XHSNameDisplay.Resolve({
				playerID: model.id,
				playerName: model.name,
				heroName: model.hero,
				heroDisplayName: model.heroLabel,
			});
		}

		// Privacy-safe fallback: never substitute the persona name.
		return model.heroLabel || Localize("#" + (model.hero || ""));
	}

	function ResolveHallIdentity(entry) {
		entry = entry || {};
		var rawPlayerName = entry.name || entry.player_name || entry.steam_name || entry.steamid || entry.__key || "";
		if (typeof XHSNameDisplay !== "undefined" && XHSNameDisplay.Resolve) {
			return XHSNameDisplay.Resolve({
				playerID: entry.player_id,
				playerName: rawPlayerName,
				heroName: entry.hero || entry.hero_name || entry.unit_name || "",
			});
		}

		return entry.hero_label || Localize("#" + (entry.hero || entry.hero_name || entry.unit_name || ""));
	}

	function GetRootPanel() {
		var panel = $.GetContextPanel();
		var lastPanel = panel;

		for (var i = 0; i < 12 && panel; i++) {
			lastPanel = panel;
			panel = panel.GetParent();
		}

		return lastPanel;
	}

	function HideVanillaHud() {
		var root = GetRootPanel();
		var ids = [
			"topbar",
			"minimap_container",
			"lower_hud",
			"NetGraph",
			"quickstats",
			"buffs",
			"debuffs",
			"shop",
		];
		var localPlayerID = Safe(function () {
			return Players.GetLocalPlayer();
		}, -1);
		var isToolsSpectator = Safe(function () {
			return typeof Game.IsInToolsMode === "function"
				&& Game.IsInToolsMode()
				&& localPlayerID >= 0
				&& Number(Players.GetTeam(localPlayerID)) === 1;
		}, false);
		if (isToolsSpectator) {
			ids.push("GameInfoButton");
			ids.push("spectator_options");
		}

		for (var i = 0; i < ids.length; i++) {
			var panel = root && root.FindChildTraverse(ids[i]);
			if (panel) {
				panel.style.visibility = "collapse";
			}
		}
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

	function GetPublishedGameId() {
		var identity = CustomNetTables.GetTableValue("xhs_run_identity", "current") || {};
		var value = identity.game_id === undefined || identity.game_id === null ? "" : String(identity.game_id).trim();
		return value && value !== "0" && value !== "-" ? value : "";
	}

	function RefreshFallbackGameId() {
		var value = GetPublishedGameId();
		var button = Panel("XHSEndScreenFallbackGameIdButton");
		var label = Panel("XHSEndScreenFallbackGameId");
		if (!button || !label) return;
		label.text = value;
		button.SetHasClass("IsAvailable", !!value);
	}

	function OpenSupporterPortal() {
		if (supporterPortalRequestPending) return;
		supporterPortalRequestPending = true;
		GameEvents.SendCustomGameEventToServer("supporter_pass_open_payment_portal", {
			source: "end_screen",
			locale: $.Language ? $.Language() : "en"
		});
		$.Schedule(12, function () { supporterPortalRequestPending = false; });
	}

	function FinishGame() {
		if (Game && Game.FinishGame) {
			Game.FinishGame();
		}
	}

	function ShowEndScreenFallback() {
		if (hasRenderedEndGame) return;

		var root = $.GetContextPanel();
		if (!root) return;

		root.SetHasClass("IsLoading", false);
		root.SetHasClass("IsFallback", true);
		RefreshFallbackGameId();
	}

	function ScheduleEndScreenFallback() {
		if (fallbackTimerStarted) {
			return;
		}

		fallbackTimerStarted = true;
		$.Schedule(10.0, ShowEndScreenFallback);
	}

	function ClearPanel(panel) {
		if (panel) {
			panel.RemoveAndDeleteChildren();
		}
	}

	function GetEndGameData() {
		try {
			return CustomNetTables.GetTableValue("game_options", "end_game");
		} catch (error) {
			$.Msg("[XHSEndScreen] End-game data read failed: " + String(error && (error.stack || error.message) || error));
			return null;
		}
	}

	function FindServerPlayer(data, steamID, playerID) {
		var players = data.players || {};

		if (steamID && players[steamID]) {
			return players[steamID];
		}

		if (players[playerID]) {
			return players[playerID];
		}

		for (var key in players) {
			if (players.hasOwnProperty(key) && players[key] && Number(players[key].id) === Number(playerID)) {
				return players[key];
			}
		}

		return null;
	}

	function FindApiPlayer(data, steamID) {
		if (!data || !data.data || !data.data.players) {
			return null;
		}

		return data.data.players[steamID] || null;
	}

	function GetPlayerIDsFromData(data) {
		var ids = {};
		var ordered = [];
		var players = (data && data.players) || {};

		for (var steamID in players) {
			if (players.hasOwnProperty(steamID) && players[steamID] && players[steamID].id !== undefined) {
				ids[players[steamID].id] = true;
			}
		}

		for (var playerIDKey in ids) {
			if (ids.hasOwnProperty(playerIDKey)) {
				ordered.push(ToNumber(playerIDKey, 0));
			}
		}

		ordered.sort(function (a, b) { return a - b; });
		return ordered;
	}

	function GetBattlepassTable(playerID) {
		return CustomNetTables.GetTableValue("supporter_pass_player", playerID.toString()) || {};
	}

	function GetSupporterURL() {
		var playerID = Safe(function () {
			return Players.GetLocalPlayer();
		}, -1);
		var table = playerID >= 0 ? GetBattlepassTable(playerID) : {};
		return table.supporter_url || table.support_url || SUPPORTER_URL;
	}

	function GetSupporterTierData(playerID, battlepass) {
		battlepass = battlepass || {};

		if (typeof XHSSupporterHover !== "undefined" && XHSSupporterHover.GetTierData) {
			var hoverTier = XHSSupporterHover.GetTierData(playerID, battlepass);
			return {
				tier: Clamp(ToNumber(hoverTier.tier, 0), 0, 5),
				name: hoverTier.name || battlepass.title || "Supporter Pass",
				color: NormalizeColorString(hoverTier.color || battlepass.tier_color || battlepass.title_color || "#5ad0ff") || "#5ad0ffff"
			};
		}

		var tier = Clamp(ToNumber(FirstDefined(battlepass.tier_id, battlepass.supporter_tier, battlepass.donator_level, 0), 0), 0, 5);
		return {
			tier: tier,
			name: battlepass.tier_name || battlepass.supporter_tier_name || battlepass.title || "Supporter Pass",
			color: NormalizeColorString(battlepass.tier_color || battlepass.title_color || "#5ad0ff") || "#5ad0ffff"
		};
	}

	function MergeCompletedSupporterPass(battlepass, apiData) {
		var merged = {};
		battlepass = battlepass || {};
		apiData = apiData || {};

		for (var key in battlepass) {
			if (battlepass.hasOwnProperty(key)) {
				merged[key] = battlepass[key];
			}
		}

		var supporterPass = apiData.supporter_pass || apiData.supporterPass || {};
		var season = apiData.season || supporterPass.season || {};

		var seasonLevel = FirstDefined(season.level, supporterPass.season_level, supporterPass.level, apiData.supporter_pass_level);
		var seasonXP = FirstDefined(season.xp, supporterPass.season_xp, supporterPass.current_exp, apiData.supporter_pass_xp);
		var seasonMax = FirstDefined(season.xp_per_level, supporterPass.season_xp_max, supporterPass.xp_per_level, apiData.supporter_pass_xp_max);
		var seasonChange = FirstDefined(
			season.xp_change,
			season.gained_xp,
			supporterPass.season_xp_change,
			supporterPass.xp_change,
			supporterPass.gained_xp,
			apiData.supporter_pass_xp_change,
			apiData.supporter_xp_change,
			apiData.season_xp_change
		);
		var durationXP = FirstDefined(season.duration_xp, supporterPass.duration_xp, apiData.duration_xp);
		var victoryXPBonus = FirstDefined(season.victory_xp_bonus, supporterPass.victory_xp_bonus, apiData.victory_xp_bonus);
		var baseXPChange = FirstDefined(season.base_xp_change, supporterPass.base_xp_change, apiData.base_xp_change);
		var xpBoost = FirstDefined(season.xp_boost, supporterPass.xp_boost, apiData.xp_boost);
		var xpBonus = FirstDefined(season.xp_bonus, supporterPass.xp_bonus, apiData.xp_bonus);
		var xpEligible = FirstDefined(season.xp_eligible, supporterPass.xp_eligible, apiData.xp_eligible);
		var xpIneligibleReason = FirstDefined(season.xp_ineligible_reason, supporterPass.xp_ineligible_reason, apiData.xp_ineligible_reason);
		var seasonXPBefore = FirstDefined(season.xp_before, supporterPass.season_xp_before, apiData.season_xp_before);
		var seasonLevelBefore = FirstDefined(season.level_before, supporterPass.season_level_before, apiData.season_level_before);
		var xpBreakdown = FirstDefined(season.xp_breakdown, supporterPass.xp_breakdown, apiData.xp_breakdown);

		if (seasonLevel !== undefined) {
			merged.season_level = seasonLevel;
			merged.Lvl = seasonLevel;
		}
		if (seasonXP !== undefined) {
			merged.season_xp = seasonXP;
			merged.season_total_xp = seasonXP;
			merged.XP = seasonXP;
		}
		if (seasonXPBefore !== undefined) {
			merged.season_xp_before = seasonXPBefore;
		}
		if (seasonLevelBefore !== undefined) {
			merged.season_level_before = seasonLevelBefore;
		}
		if (seasonMax !== undefined) {
			merged.season_xp_max = seasonMax;
			merged.MaxXP = seasonMax;
		}
		if (seasonChange !== undefined) {
			merged.season_xp_change = seasonChange;
			merged.XP_change = seasonChange;
		}
		if (durationXP !== undefined) {
			merged.duration_xp = durationXP;
		}
		if (victoryXPBonus !== undefined) {
			merged.victory_xp_bonus = victoryXPBonus;
		}
		if (baseXPChange !== undefined) {
			merged.base_xp_change = baseXPChange;
		}
		if (xpBoost !== undefined) {
			merged.xp_boost = xpBoost;
		}
		if (xpBonus !== undefined) {
			merged.xp_bonus = xpBonus;
		}
		if (xpEligible !== undefined) {
			merged.xp_eligible = xpEligible;
		}
		if (xpIneligibleReason !== undefined && xpIneligibleReason !== null) {
			merged.xp_ineligible_reason = xpIneligibleReason;
		}
		if (xpBreakdown !== undefined) {
			merged.xp_breakdown = xpBreakdown;
		}

		merged.title = merged.title || "Supporter Pass";
		return merged;
	}

	function GetInventoryItemName(item) {
		if (!item) {
			return "";
		}
		if (typeof item === "string") {
			return item;
		}
		return (item.item_name || item.itemname || item.ability_name || item.name || "").toString();
	}

	function GetPlayerMainInventory(server, playerID) {
		var inventory = ["", "", "", "", "", ""];
		var liveItems = Safe(function () {
			return Game.GetPlayerItems(playerID);
		}, null);
		var hasLiveInventory = !!(liveItems && liveItems.inventory);

		if (hasLiveInventory) {
			for (var slot = 0; slot < inventory.length; slot++) {
				inventory[slot] = GetInventoryItemName(liveItems.inventory[slot]);
			}
		}

		if (!hasLiveInventory) {
			var snapshotItems = TableToArray(server && server.items);
			for (var inventorySlot = 0; inventorySlot < inventory.length && inventorySlot < snapshotItems.length; inventorySlot++) {
				inventory[inventorySlot] = GetInventoryItemName(snapshotItems[inventorySlot]);
			}
		}

		return inventory;
	}

	function BuildPlayerModel(data, playerID) {
		var info = Safe(function () {
			return Game.GetPlayerInfo(playerID);
		}, null);

		var steamID = info && info.player_steamid ? info.player_steamid.toString() : playerID.toString();
		var server = FindServerPlayer(data, steamID, playerID) || {};
		var api = FindApiPlayer(data, steamID) || {};
		var battlepass = MergeCompletedSupporterPass(GetBattlepassTable(playerID), api);
		var completion = data && data.data && data.data.completion ? data.data.completion : {};
		var supporterTier = GetSupporterTierData(playerID, battlepass);
		var heroName = server.hero || (info && info.player_selected_hero) || "";
		var team = ToNumber(server.team, info ? info.player_team_id : 0);
		var tomesSmall = MaxNumber(server.tomes_bought_small, server.tomes_small, server.tome_small, api.tomes_bought_small, api.tomes_small, api.tome_small);
		var tomesBig = MaxNumber(server.tomes_bought_big, server.tomes_big, server.tome_big, api.tomes_bought_big, api.tomes_big, api.tome_big);
		var tomesPower = MaxNumber(server.tomes_bought_power, server.tomes_power, server.tome_power, api.tomes_bought_power, api.tomes_power, api.tome_power);
		var tomeStatsBonus = MaxNumber(
			server.tome_stats_bonus,
			server.tome_stats,
			server.tomes_stats,
			server.stats_from_tomes,
			api.tome_stats_bonus,
			api.tome_stats,
			api.tomes_stats,
			api.stats_from_tomes,
			tomesSmall * 50 + tomesBig * 250
		);
		var potionsUsed = MaxNumber(
			server.potions_used,
			server.potion_uses,
			server.potions,
			server.potionsUsed,
			api.potions_used,
			api.potion_uses,
			api.potions,
			api.potionsUsed
		);

		return {
			id: playerID,
			steamID: steamID,
			name: Safe(function () { return Players.GetPlayerName(playerID); }, info ? info.player_name : "Player " + (playerID + 1)),
			hero: heroName,
			heroLabel: Localize("#" + heroName),
			inventory: GetPlayerMainInventory(server, playerID),
			team: team,
			kills: ToNumber(server.kills, info ? info.player_kills : 0),
			deaths: ToNumber(server.deaths, info ? info.player_deaths : 0),
			assists: ToNumber(server.assists, info ? info.player_assists : 0),
			level: ToNumber(server.level, info ? info.player_level : 0),
			networth: ToNumber(server.networth, info ? info.player_gold : 0),
			damageHeroes: ToNumber(server.damage_done_to_heroes, 0),
			damageBuildings: ToNumber(server.damage_done_to_buildings, 0),
			bossDamage: ToNumber(server.boss_damage, 0),
			damageTaken: ToNumber(server.damage_taken, 0),
			selfHealing: ToNumber(server.self_healing, 0),
			healing: ToNumber(server.healing, 0),
			potionsUsed: potionsUsed,
			tomeStatsBonus: tomeStatsBonus,
			tomesSmall: tomesSmall,
			tomesBig: tomesBig,
			tomesPower: tomesPower,
			playerColor: GetPlayerColorString(playerID, FirstDefined(battlepass.ply_color, server.ply_color, api.ply_color)),
			supporterTier: supporterTier.tier,
			supporterTierName: supporterTier.name,
			supporterTierColor: supporterTier.color,
			supportGold: ToNumber(server.gold_spent_on_support, 0),
			abandon: !!server.abandon,
			victory: IsPlayerVictory(data),
			gameTime: ToNumber(data.game_time, Safe(function () { return Game.GetDOTATime(false, false); }, 0)),
			api: api,
			server: server,
			battlepass: battlepass,
			completion: completion,
			matchCheatMode: BoolValue(FirstDefined(data && data.cheat_mode, completion.cheat_mode, false)),
			matchToolsMode: BoolValue(FirstDefined(data && data.tools_mode, completion.tools_mode, false)),
			persistentRewardsEligible: FirstDefined(data && data.persistent_rewards_eligible, true) !== false,
			completionError: BoolValue(data && data.completion_error),
		};
	}

	function BuildPlayerModels(data) {
		var playerIDs = GetPlayerIDsFromData(data);
		var models = [];

		for (var i = 0; i < playerIDs.length; i++) {
			var model = BuildPlayerModel(data, playerIDs[i]);
			if (Number(model.team) !== 1) {
				models.push(model);
			}
		}

		models.sort(function (a, b) {
			if (a.team !== b.team) {
				return a.team - b.team;
			}

			return a.id - b.id;
		});

		return models;
	}

	function GetWinnerTeam(data) {
		return ToNumber(
			data && data.info && data.info.winner !== undefined ? data.info.winner : data.winner,
			Safe(function () { return Game.GetGameWinner(); }, 0)
		);
	}

	function IsPlayerVictory(data) {
		var winnerTeam = GetWinnerTeam(data);
		return winnerTeam === 2;
	}

	function GetDifficultyName(data) {
		var tableValue = CustomNetTables.GetTableValue("game_options", "difficulty");
		var value = data.difficulty || (tableValue && tableValue["1"]);
		var difficulty = ToNumber(value, 0);
		return DIFFICULTY_NAMES[difficulty] || (difficulty > 0 ? "Difficulty " + difficulty : "-");
	}

	function GetGameId(data) {
		return (data.info && data.info.id)
			|| data.game_id
			|| (data.data && data.data.game_id)
			|| GetPublishedGameId()
			|| data.match_id
			|| (data.info && data.info.match_id)
			|| "-";
	}

	function GetPublicMatchURL(gameID) {
		var normalized = gameID === undefined || gameID === null ? "" : gameID.toString().trim();
		if (!normalized || normalized === "-" || normalized.toLowerCase() === "local") {
			return null;
		}

		return WEBSITE_URL + "/match/" + encodeURIComponent(normalized);
	}

	function RenderHeader(data) {
		var result = Panel("XHSEndScreenResult");
		var isXHeroesVictory = IsPlayerVictory(data);

		if (result) {
			result.text = isXHeroesVictory ? "Victory" : "Defeat";
			result.SetHasClass("IsVictory", isXHeroesVictory);
			result.SetHasClass("IsDefeat", !isXHeroesVictory);
		}

		var gameTime = data.game_time || Safe(function () { return Game.GetDOTATime(false, false); }, 0);
		var time = Panel("XHSEndScreenTime");
		if (time) {
			time.text = FormatTime(gameTime);
		}

		var difficulty = Panel("XHSEndScreenDifficulty");
		if (difficulty) {
			difficulty.text = GetDifficultyName(data);
		}

		var gameIDValue = GetGameId(data);
		var gameID = Panel("XHSEndScreenGameId");
		var gameIDButton = Panel("XHSEndScreenGameIdButton");
		var publicMatchURL = GetPublicMatchURL(gameIDValue);
		if (gameID) {
			gameID.text = gameIDValue.toString();
		}
		if (gameIDButton) {
			gameIDButton.enabled = !!publicMatchURL;
			gameIDButton.SetHasClass("IsAvailable", !!publicMatchURL);
			gameIDButton.SetHasClass("IsUnavailable", !publicMatchURL);
			gameIDButton.SetPanelEvent("onactivate", function () {
				if (publicMatchURL) {
					OpenExternalURL(publicMatchURL);
				}
			});
			gameIDButton.SetPanelEvent("onmouseover", function () {
				if (publicMatchURL) {
					$.DispatchEvent("UIShowTextTooltip", gameIDButton, "Open this match on the Frostrose website");
				}
			});
			gameIDButton.SetPanelEvent("onmouseout", function () {
				$.DispatchEvent("UIHideTextTooltip", gameIDButton);
			});
		}
	}

	function TableToArray(tableValue) {
		var result = [];
		if (!tableValue) {
			return result;
		}

		for (var key in tableValue) {
			if (tableValue.hasOwnProperty(key) && tableValue[key]) {
				result.push(tableValue[key]);
			}
		}

		result.sort(function (a, b) {
			return ToNumber(a.slot, 0) - ToNumber(b.slot, 0);
		});
		return result;
	}

	function IsSyncedFragmentQuestStatus(status) {
		status = (status || "").toString().toLowerCase();
		return status === "synced" || status === "confirmed" || status === "success" || status === "ok";
	}

	function FindSelectedFragmentQuest(selected, instanceID) {
		if (!selected || !instanceID) {
			return null;
		}

		var needle = instanceID.toString();
		for (var key in selected) {
			if (selected.hasOwnProperty(key) && selected[key] && selected[key].instance_id && selected[key].instance_id.toString() === needle) {
				return selected[key];
			}
		}

		return null;
	}

	function GetConfirmedFragmentQuestState(data) {
		var live = CustomNetTables.GetTableValue("fragment_quests", "state") || {};
		var liveConfirmed = TableToArray(live.confirmed_quests);
		if (live.backend_status === "synced" && liveConfirmed.length > 0) {
			return {
				quests: liveConfirmed,
				selected: live.selected || {},
				total: ToNumber(live.confirmed_total_fragments, 0),
			};
		}

		var response = data && data.data ? data.data : {};
		var block = response.fragment_quests || (data && data.fragment_quests);
		if (!block || !IsSyncedFragmentQuestStatus(block.status || block.backend_status)) {
			return null;
		}

		var quests = TableToArray(block.quests);
		if (quests.length === 0) {
			return null;
		}

		return {
			quests: quests,
			selected: live.selected || {},
			total: ToNumber(block.total_fragments_awarded || block.total_fragments, 0),
		};
	}

	function AddFragmentQuestStars(parent, stars) {
		stars = Clamp(ToNumber(stars, 0), 0, 3);
		for (var i = 1; i <= 3; i++) {
			var star = $.CreatePanel("Panel", parent, "");
			star.AddClass("XHSEndFragmentQuestStar");
			star.SetHasClass("IsActive", i <= stars);
		}
	}

	function RenderFragmentQuests(data) {
		var parent = Panel("XHSEndScreenFragmentQuests");
		ClearPanel(parent);

		if (!parent) {
			return;
		}

		parent.RemoveClass("IsVisible");
		var state = GetConfirmedFragmentQuestState(data);
		if (!state) {
			return;
		}

		parent.AddClass("IsVisible");

		var header = $.CreatePanel("Panel", parent, "");
		header.AddClass("XHSEndFragmentQuestHeader");

		var title = $.CreatePanel("Label", header, "");
		title.AddClass("XHSEndFragmentQuestTitle");
		title.text = "Fragment Quests";

		var total = $.CreatePanel("Label", header, "");
		total.AddClass("XHSEndFragmentQuestTotal");
		total.text = "+" + FormatNumber(state.total) + " fragments";

		for (var i = 0; i < state.quests.length; i++) {
			var quest = state.quests[i];
			var selected = FindSelectedFragmentQuest(state.selected, quest.instance_id) || {};
			var row = $.CreatePanel("Panel", parent, "");
			row.AddClass("XHSEndFragmentQuestRow");

			var copy = $.CreatePanel("Panel", row, "");
			copy.AddClass("XHSEndFragmentQuestCopy");

			var questTitle = $.CreatePanel("Label", copy, "");
			questTitle.AddClass("XHSEndFragmentQuestName");
			questTitle.text = selected.title || quest.title || quest.template_id || "Fragment Quest";

			var status = $.CreatePanel("Label", copy, "");
			status.AddClass("XHSEndFragmentQuestStatus");
			status.text = quest.grant_status || "confirmed";

			var stars = $.CreatePanel("Panel", row, "");
			stars.AddClass("XHSEndFragmentQuestStars");
			AddFragmentQuestStars(stars, quest.stars);

			var amount = $.CreatePanel("Label", row, "");
			amount.AddClass("XHSEndFragmentQuestAmount");
			amount.text = "+" + FormatNumber(quest.fragments_awarded || 0);
		}
	}

	function CreateMvpCard(parent, title, model, value, formatter, valueClassName, cardClassName) {
		var card = $.CreatePanel("Panel", parent, "");
		card.AddClass("XHSMvpCard");
		if (cardClassName) {
			card.AddClass(cardClassName);
		}

		var heroImage = $.CreatePanel("DOTAHeroImage", card, "");
		heroImage.AddClass("XHSMvpIcon");
		heroImage.heroimagestyle = "landscape";
		if (model && model.hero) {
			heroImage.heroname = model.hero;
		}

		var copy = $.CreatePanel("Panel", card, "");
		copy.AddClass("XHSMvpCopy");

		var label = $.CreatePanel("Label", copy, "");
		label.AddClass("XHSMvpLabel");
		label.text = title;

		var name = $.CreatePanel("Label", copy, "");
		name.AddClass("XHSMvpName");
		name.text = model ? ResolvePlayerIdentity(model) : "";

		var valuePanel = $.CreatePanel("Label", copy, "");
		valuePanel.AddClass("XHSMvpValue");
		if (valueClassName) {
			valuePanel.AddClass(valueClassName);
		}
		valuePanel.text = formatter ? formatter(value) : FormatNumber(value);
		return card;
	}

	function FindMvp(players, field) {
		var best = null;
		var bestValue = -1;

		for (var i = 0; i < players.length; i++) {
			var value = ToNumber(players[i][field], 0);
			if (value > bestValue) {
				best = players[i];
				bestValue = value;
			}
		}

		return {
			model: best,
			value: bestValue < 0 ? 0 : bestValue,
		};
	}

	function RenderMvpCards(players) {
		var parent = Panel("XHSEndScreenMvpCards");
		ClearPanel(parent);

		if (!parent) {
			return;
		}
		parent.RemoveClass("IsFarmLeaderboard");

		var kills = FindMvp(players, "kills");
		var tomes = FindMvp(players, "tomeStatsBonus");
		var networth = FindMvp(players, "networth");
		var potions = FindMvp(players, "potionsUsed");
		var bossDamage = FindMvp(players, "bossDamage");
		var damageTaken = FindMvp(players, "damageTaken");
		var selfHealing = FindMvp(players, "selfHealing");

		CreateMvpCard(parent, "Most Kills", kills.model, kills.value, FormatNumber, "MvpKills");
		CreateMvpCard(parent, "Richest Hero", networth.model, networth.value, FormatNumber, "MvpGold");
		CreateMvpCard(parent, "Most Tome Stats", tomes.model, tomes.value, function (value) { return "+" + FormatNumber(value); }, "MvpStats");
		CreateMvpCard(parent, "Most Potions Used", potions.model, potions.value, FormatNumber, "MvpPotions");
		CreateMvpCard(parent, "Most Boss Damage", bossDamage.model, bossDamage.value, FormatNumber, "MvpBossDamage");
		CreateMvpCard(parent, "Most Damage Taken", damageTaken.model, damageTaken.value, FormatNumber, "MvpDamageTaken");
		CreateMvpCard(parent, "Most Self Healing", selfHealing.model, selfHealing.value, FormatNumber, "MvpSustain", "XHSMvpCardLast");
	}

	function GetFarmLeaderboardState() {
		return CustomNetTables.GetTableValue("xhs_farm_leaderboard", "state") || {};
	}

	function GetFarmPlayerModel(playerID) {
		var hero = Safe(function () { return Players.GetPlayerSelectedHero(playerID); }, "");
		return {
			id: playerID,
			name: Safe(function () { return Players.GetPlayerName(playerID); }, ""),
			hero: hero,
			heroLabel: Localize("#" + hero),
		};
	}

	function GetFarmLeaderboardPlayers() {
		var players = TableToArray(GetFarmLeaderboardState().players);
		players.sort(function (a, b) {
			var rankA = ToNumber(a.rank, 999);
			var rankB = ToNumber(b.rank, 999);
			if (rankA !== rankB) {
				return rankA - rankB;
			}
			return ToNumber(b.kills, 0) - ToNumber(a.kills, 0);
		});
		return players;
	}

	function RenderFarmLeaderboard() {
		var parent = Panel("XHSEndScreenMvpCards");
		ClearPanel(parent);
		if (!parent) {
			return;
		}
		parent.AddClass("IsFarmLeaderboard");

		var heading = $.CreatePanel("Panel", parent, "");
		heading.AddClass("XHSEndFarmHeader");
		var headingTitle = $.CreatePanel("Label", heading, "");
		headingTitle.AddClass("XHSEndFarmTitle");
		headingTitle.text = "FARM EVENT";
		var headingNote = $.CreatePanel("Label", heading, "");
		headingNote.AddClass("XHSEndFarmNote");
		headingNote.text = "FINAL LEADERBOARD";

		var players = GetFarmLeaderboardPlayers();
		if (players.length === 0) {
			var empty = $.CreatePanel("Label", parent, "");
			empty.AddClass("XHSEndFarmEmpty");
			empty.text = "No Farm Event results available.";
			return;
		}

		for (var index = 0; index < players.length; index++) {
			var player = players[index];
			var playerID = ToNumber(player.player_id, -1);
			var rank = Math.max(1, ToNumber(player.rank, index + 1));
			var model = GetFarmPlayerModel(playerID);
			var row = $.CreatePanel("Panel", parent, "");
			row.AddClass("XHSEndFarmRow");
			row.SetHasClass("IsWinner", rank === 1);

			var rankLabel = $.CreatePanel("Label", row, "");
			rankLabel.AddClass("XHSEndFarmRank");
			rankLabel.text = rank === 1 ? "\u2605" : String(rank);

			var heroImage = $.CreatePanel("DOTAHeroImage", row, "");
			heroImage.AddClass("XHSEndFarmHero");
			heroImage.heroimagestyle = "landscape";
			heroImage.heroname = model.hero;

			var copy = $.CreatePanel("Panel", row, "");
			copy.AddClass("XHSEndFarmCopy");
			var name = $.CreatePanel("Label", copy, "");
			name.AddClass("XHSEndFarmName");
			name.text = ResolvePlayerIdentity(model);
			var stage = $.CreatePanel("Label", copy, "");
			stage.AddClass("XHSEndFarmStage");
			stage.text = "LEVEL " + Math.max(1, ToNumber(player.level, 1)) +
				"  \u00B7  WAVE " + Math.max(1, ToNumber(player.wave, 1)) +
				"/" + Math.max(1, ToNumber(player.waves_per_level, 1));

			var score = $.CreatePanel("Panel", row, "");
			score.AddClass("XHSEndFarmKills");
			var scoreValue = $.CreatePanel("Label", score, "");
			scoreValue.AddClass("XHSEndFarmKillsValue");
			scoreValue.text = FormatNumber(player.kills);
			var scoreSuffix = $.CreatePanel("Label", score, "");
			scoreSuffix.AddClass("XHSEndFarmKillsSuffix");
			scoreSuffix.text = "KILLS";
		}
	}

	function UpdateFarmLeaderboardButton() {
		var button = Panel("XHSEndScreenFarmButton");
		var label = Panel("XHSEndScreenFarmButtonLabel");
		var available = GetFarmLeaderboardPlayers().length > 0;
		if (button) {
			button.enabled = available;
			button.SetHasClass("XHSEndScreenButtonDisabled", !available);
			button.SetHasClass("IsSelected", farmLeaderboardVisible && available);
		}
		if (label) {
			label.text = farmLeaderboardVisible && available ? "Records" : "Farm Event";
		}
	}

	function RenderHighlightPanel(players) {
		if (farmLeaderboardVisible && GetFarmLeaderboardPlayers().length > 0) {
			RenderFarmLeaderboard();
		} else {
			farmLeaderboardVisible = false;
			RenderMvpCards(players);
		}
		UpdateFarmLeaderboardButton();
	}

	function CreateCell(parent, className, text, extraClassName) {
		var cell = $.CreatePanel("Label", parent, "");
		cell.AddClass("XHSPlayerCell");
		cell.AddClass(className);

		if (extraClassName) {
			cell.AddClass(extraClassName);
		}

		cell.text = text;
		return cell;
	}

	function NormalizeSupporterProgress(battlepass) {
		var xp = Math.max(0, ToNumber(battlepass.season_xp !== undefined ? battlepass.season_xp : battlepass.XP, 0));
		var max = Math.max(ToNumber(battlepass.season_xp_max !== undefined ? battlepass.season_xp_max : battlepass.MaxXP, 1000), 1);
		var level = Math.max(1, ToNumber(battlepass.season_level !== undefined ? battlepass.season_level : battlepass.Lvl, 1));

		if (xp >= max) {
			var completedLevels = Math.floor(xp / max);
			xp = xp - completedLevels * max;
			level = Math.max(level, 1 + completedLevels);
		}

		return {
			xp: xp,
			max: max,
			level: level,
		};
	}

	function GetXHSAccountProgress(apiData, battlepass) {
		apiData = apiData || {};
		battlepass = battlepass || {};

		var hasApiLevel = apiData.xp_level !== undefined && apiData.xp_level !== null;
		var level = hasApiLevel ? ToNumber(apiData.xp_level, 0) + 1 : ToNumber(battlepass.xhs_account_level, 0);
		var current = ToNumber(apiData.xp_in_level !== undefined ? apiData.xp_in_level : battlepass.xhs_xp_current, 0);
		var max = ToNumber(apiData.xp_next_level !== undefined ? apiData.xp_next_level : battlepass.xhs_xp_max, 0);
		var total = ToNumber(apiData.xp !== undefined ? apiData.xp : battlepass.xhs_xp, 0);
		var change = ToNumber(apiData.xp_change, 0);

		return {
			hasData: level > 0 || current > 0 || max > 0 || total > 0 || change !== 0,
			level: Math.max(1, level),
			current: Math.max(0, current),
			max: Math.max(0, max),
			total: Math.max(0, total),
			change: change,
		};
	}

	function FormatSignedNumber(value) {
		return value >= 0 ? "+" + FormatNumber(value) : FormatNumber(value);
	}

	function FormatXHSAccountProgress(progress) {
		if (!progress || !progress.hasData) {
			return "XHS N/A";
		}

		var text = "XHS L" + progress.level;
		if (progress.max > 0) {
			text += " " + FormatNumber(progress.current) + "/" + FormatNumber(progress.max);
		} else if (progress.total > 0) {
			text += " " + FormatNumber(progress.total) + " XP";
		}

		if (progress.change !== 0) {
			text += " (" + FormatSignedNumber(progress.change) + ")";
		}

		return text;
	}

	function IntXP(value) {
		return Math.max(0, Math.floor(ToNumber(value, 0)));
	}

	function BoolValue(value) {
		return value === true || value === 1 || value === "1" || value === "true";
	}

	function GetXPPresentationKey(data, model) {
		var completion = data && data.data && data.data.completion ? data.data.completion : {};
		var info = data && data.info ? data.info : {};
		var gameID = FirstDefined(completion.game_id, info.game_id, data && data.game_id, "local");
		return gameID.toString() + ":" + (model ? model.steamID : "spectator");
	}

	function GetLocalPlayerModel(players) {
		var localPlayerID = Safe(function () { return Players.GetLocalPlayer(); }, -1);
		for (var i = 0; i < players.length; i++) {
			if (Number(players[i].id) === Number(localPlayerID)) {
				return players[i];
			}
		}
		return null;
	}

	function GetXPPresentationData(model) {
		var apiData = model.api || {};
		var battlepass = model.battlepass || {};
		var season = apiData.season || {};
		var breakdown = apiData.xp_breakdown || season.xp_breakdown || battlepass.xp_breakdown || {};
		var serverFacts = model.server && model.server.supporter_xp ? model.server.supporter_xp : {};
		var completion = model.completion || {};
		var xpPerLevel = Math.max(IntXP(FirstDefined(
			season.xp_per_level,
			battlepass.season_xp_max,
			battlepass.MaxXP,
			1000
		)), 1);
		var supporterPercent = IntXP(FirstDefined(breakdown.supporter_percent, apiData.xp_boost, battlepass.xp_boost));
		var reason = (FirstDefined(
			apiData.xp_ineligible_reason,
			season.xp_ineligible_reason,
			completion.xp_ineligible_reason,
			battlepass.xp_ineligible_reason,
			model.matchToolsMode ? "tools_mode_telemetry_only" : undefined,
			model.matchCheatMode ? "cheat_mode_not_whitelisted" : undefined,
			model.persistentRewardsEligible === false ? "persistent_rewards_disabled" : undefined,
			model.completionError ? "backend_completion_failed" : undefined,
			""
		) || "").toString();
		var eligibleValue = FirstDefined(apiData.xp_eligible, season.xp_eligible, completion.xp_eligible);
		if (eligibleValue === undefined && (model.matchToolsMode || model.matchCheatMode || model.persistentRewardsEligible === false || model.completionError)) {
			eligibleValue = false;
		}
		if (eligibleValue === undefined) {
			eligibleValue = battlepass.xp_eligible;
		}
		var eligible = eligibleValue === undefined ? !reason : BoolValue(eligibleValue);
		if (eligible) {
			reason = "";
		} else if (!reason) {
			reason = "match_ineligible";
		}
		var simulation = !eligible;
		var farmDifficulty = Clamp(IntXP(FirstDefined(
			breakdown.farm_event_difficulty,
			serverFacts.farm_event_difficulty,
			1
		)), 1, 5);
		var theoreticalMatchXP = Math.floor(Math.min(Math.max(ToNumber(model.gameTime, 0), 0), 30 * 60) * 200 / (30 * 60));
		var theoreticalHeroImagesDone = IntXP(serverFacts.hero_images_done);
		var theoretical = {
			match: theoreticalMatchXP,
			muradin: BoolValue(serverFacts.muradin_event_won) ? 15 : 0,
			hero_images: theoreticalHeroImagesDone * 25,
			all_hero_images: BoolValue(serverFacts.all_hero_images_done) ? 50 : 0,
			frost_infernal: BoolValue(serverFacts.frost_infernal_done) ? 50 : 0,
			spirit_beast: BoolValue(serverFacts.spirit_beast_done) ? 50 : 0,
			ramero_baristol: BoolValue(serverFacts.ramero_baristol_won) ? 25 : 0,
			sogat: BoolValue(serverFacts.sogat_won) ? 25 : 0,
			farm_event: Math.floor(IntXP(serverFacts.farm_event_kills) * farmDifficulty / 100),
			victory: model.victory ? 300 : 0,
		};
		theoretical.heroic_objectives = theoretical.hero_images + theoretical.all_hero_images + theoretical.frost_infernal + theoretical.spirit_beast;
		theoretical.special_events = theoretical.ramero_baristol + theoretical.sogat;
		theoretical.subtotal = theoretical.match + theoretical.muradin + theoretical.heroic_objectives + theoretical.special_events + theoretical.farm_event + theoretical.victory;
		theoretical.supporter = Math.max(Math.round(theoretical.subtotal * supporterPercent / 100), 0);
		theoretical.total = theoretical.subtotal + theoretical.supporter;

		var matchXP = simulation ? theoretical.match : IntXP(FirstDefined(breakdown.match, apiData.duration_xp, battlepass.duration_xp));
		var muradinXP = IntXP(breakdown.muradin);
		var heroImagesXP = IntXP(breakdown.hero_images);
		var allHeroImagesXP = IntXP(breakdown.all_hero_images);
		var frostInfernalXP = IntXP(breakdown.frost_infernal);
		var spiritBeastXP = IntXP(breakdown.spirit_beast);
		var heroicObjectivesXP = IntXP(FirstDefined(
			breakdown.heroic_objectives,
			heroImagesXP + allHeroImagesXP + frostInfernalXP + spiritBeastXP
		));
		var rameroBaristolXP = IntXP(breakdown.ramero_baristol);
		var sogatXP = IntXP(breakdown.sogat);
		var specialEventsXP = IntXP(FirstDefined(
			breakdown.special_events,
			rameroBaristolXP + sogatXP
		));
		var farmXP = IntXP(breakdown.farm_event);
		var victoryXP = IntXP(FirstDefined(breakdown.victory, apiData.victory_xp_bonus, battlepass.victory_xp_bonus));
		var supporterXP = IntXP(FirstDefined(breakdown.supporter, apiData.xp_bonus, battlepass.xp_bonus));
		if (simulation) {
			muradinXP = theoretical.muradin;
			heroImagesXP = theoretical.hero_images;
			allHeroImagesXP = theoretical.all_hero_images;
			frostInfernalXP = theoretical.frost_infernal;
			spiritBeastXP = theoretical.spirit_beast;
			heroicObjectivesXP = theoretical.heroic_objectives;
			rameroBaristolXP = theoretical.ramero_baristol;
			sogatXP = theoretical.sogat;
			specialEventsXP = theoretical.special_events;
			farmXP = theoretical.farm_event;
			victoryXP = theoretical.victory;
			supporterXP = theoretical.supporter;
		}
		var calculatedTotal = matchXP + muradinXP + heroicObjectivesXP + specialEventsXP + farmXP + victoryXP + supporterXP;
		// A simulated match must always start from the account's current real XP.
		// Ignore any stale per-match delta still present in the player net table.
		var persistedTotalXP = simulation
			? 0
			: IntXP(FirstDefined(breakdown.total, apiData.xp_change, season.xp_change, battlepass.season_xp_change, calculatedTotal));
		var totalXP = simulation ? theoretical.total : persistedTotalXP;
		var persistedFinalXP = IntXP(FirstDefined(
			season.xp,
			battlepass.season_total_xp,
			battlepass.season_xp,
			persistedTotalXP
		));
		var beforeXP = IntXP(FirstDefined(season.xp_before, battlepass.season_xp_before, persistedFinalXP - persistedTotalXP));
		if (persistedFinalXP < beforeXP) {
			persistedFinalXP = beforeXP + persistedTotalXP;
		}
		var finalXP = simulation ? beforeXP + totalXP : persistedFinalXP;
		var heroImagesDone = IntXP(FirstDefined(breakdown.hero_images_done, serverFacts.hero_images_done));
		var farmKills = IntXP(FirstDefined(breakdown.farm_event_kills, serverFacts.farm_event_kills));
		// Prefer the authoritative receipt, then the server snapshot sent with the
		// completion request. If both are absent, do not falsely label it Divine.
		var farmPercent = Clamp(IntXP(FirstDefined(
			breakdown.farm_event_percent,
			serverFacts.farm_event_percent,
			farmDifficulty
		)), 1, 5);
		var farmDifficultyName = DIFFICULTY_NAMES[farmDifficulty] || ("Difficulty " + farmDifficulty);
		var startLevel = Math.floor(beforeXP / xpPerLevel) + 1;
		var endLevel = Math.floor(finalXP / xpPerLevel) + 1;
		var ineligibleMessages = {
			tools_mode_telemetry_only: "Tools Mode",
			cheat_mode: "Cheats enabled",
			cheat_mode_not_whitelisted: "Cheats enabled",
			persistent_rewards_disabled: "Persistence disabled",
			backend_completion_failed: "Reward service unavailable",
			match_too_short: "Match under 30 minutes",
			abandoned: "Match abandoned",
			disconnected: "Player disconnected",
		};
		var dailyFragments = apiData.daily_fragment_grant || season.daily_fragment_grant || null;
		var dailyTier = Clamp(IntXP(FirstDefined(
			dailyFragments && dailyFragments.tier_id,
			apiData.tier_id,
			season.tier_id,
			model.supporterTier,
			0
		)), 0, 5);
		var dailyCaps = [100, 125, 150, 175, 200, 200];
		var dailyCap = IntXP(FirstDefined(dailyFragments && dailyFragments.cap, dailyCaps[dailyTier]));
		var dailyAmount = IntXP(dailyFragments && dailyFragments.amount);
		var dailyDetails = [];
		if (!eligible) {
			dailyDetails.push({ label: "Eligible match required", value: ineligibleMessages[reason] || "Match ineligible", text: true });
			dailyDetails.push({ label: "First eligible match potential", value: "+" + FormatNumber(dailyCap) + " fragments", text: true });
		} else if (dailyFragments && BoolValue(dailyFragments.granted) && dailyAmount > 0) {
			dailyDetails.push({ label: "First eligible match today", value: "Granted", text: true });
			dailyDetails.push({ label: "Fragment balance", value: FormatNumber(IntXP(dailyFragments.balance_before)) + " -> " + FormatNumber(IntXP(dailyFragments.balance_after)), text: true });
		} else if (dailyFragments && BoolValue(dailyFragments.already_claimed)) {
			dailyDetails.push({ label: "Daily bonus", value: "Already collected today", text: true });
			dailyDetails.push({ label: "Tier " + dailyTier + " allowance", value: FormatNumber(dailyCap) + " fragments", text: true });
		} else {
			dailyDetails.push({ label: "Daily bonus", value: "No grant reported by server", text: true });
			dailyDetails.push({ label: "Tier " + dailyTier + " allowance", value: FormatNumber(dailyCap) + " fragments", text: true });
		}
		return {
			beforeXP: beforeXP,
			finalXP: finalXP,
			xpPerLevel: xpPerLevel,
			startLevel: startLevel,
			endLevel: endLevel,
			totalXP: totalXP,
			eligible: eligible,
			simulation: simulation,
			reason: reason,
			reasonLabel: reason ? (ineligibleMessages[reason] || "Match ineligible") : "",
			supporterPercent: supporterPercent,
			subtotal: simulation ? theoretical.subtotal : IntXP(FirstDefined(breakdown.subtotal, totalXP - supporterXP)),
			steps: [
				{ key: "match", title: "MATCH COMPLETE", amount: matchXP, details: eligible ? [] : [{ label: "Preview only", value: ineligibleMessages[reason] || "Match ineligible", text: true }] },
				{ key: "muradin", title: "MURADIN EVENT", amount: muradinXP, details: [{ label: "Challenge survived", value: muradinXP > 0 ? "+15" : "+0" }] },
				{ key: "objectives", title: "HEROIC OBJECTIVES", amount: heroicObjectivesXP, details: [
					{ label: "Hero Images " + heroImagesDone + " x 25", value: "+" + heroImagesXP },
					{ label: "All Hero Images", value: "+" + allHeroImagesXP },
					{ label: "Frost Infernal", value: "+" + frostInfernalXP },
					{ label: "Spirit Beast", value: "+" + spiritBeastXP },
				] },
				{ key: "arenas", title: "SPECIAL ARENAS", amount: specialEventsXP, details: [
					{ label: "Ramero & Baristol", value: "+" + rameroBaristolXP },
					{ label: "Sogat", value: "+" + sogatXP },
				] },
				{ key: "farm", title: "FARM EVENT", amount: farmXP, details: [{ label: FormatNumber(farmKills) + " kills x " + farmPercent + "% - " + farmDifficultyName + " - rounded down", value: "+" + farmXP }] },
				{ key: "victory", title: model.victory ? "VICTORY" : "DEFEAT", amount: victoryXP, details: [{ label: model.victory ? "Run completed" : "No victory bonus", value: "+" + victoryXP }] },
				{ key: "supporter", title: "SUPPORTER BOOST", amount: supporterXP, supporter: true, details: [{ label: supporterPercent + "% of " + FormatNumber(simulation ? theoretical.subtotal : IntXP(FirstDefined(breakdown.subtotal, totalXP - supporterXP))) + " XP", value: "+" + supporterXP }] },
				{ key: "daily_fragments", title: "DAILY FRAGMENTS", amount: dailyAmount, resource: "fragments", details: dailyDetails },
			],
		};
	}

	function ScheduleXP(generation, delay, callback) {
		$.Schedule(delay, function () {
			if (generation !== xpPresentationGeneration || xpPresentationPhase !== "xp") {
				return;
			}
			var container = Panel("XHSEndScreenXPContainer");
			if (!container || (container.IsValid && !container.IsValid())) {
				return;
			}
			callback();
		});
	}

	function SetXPOverlayVisible(visible) {
		var container = Panel("XHSEndScreenXPContainer");
		if (container) {
			container.SetHasClass("IsVisible", visible);
		}
		var root = $.GetContextPanel();
		if (root) {
			root.SetHasClass("HasPendingXP", visible);
		}
	}

	function SetXPRewardEndpoint(prefix, reward, level) {
		var image = Panel("XHSXP" + prefix + "RewardImage");
		var name = Panel("XHSXP" + prefix + "RewardName");
		var imageFrame = image ? image.GetParent() : null;
		var endpoint = imageFrame ? imageFrame.GetParent() : null;
		var rarityClasses = ["common", "uncommon", "rare", "mythical", "legendary", "immortal", "arcana", "ancient"];
		if (endpoint) {
			for (var rarityIndex = 0; rarityIndex < rarityClasses.length; rarityIndex++) {
				endpoint.RemoveClass("RewardRarity-" + rarityClasses[rarityIndex]);
			}
		}
		if (!reward) {
			if (image) image.style.backgroundImage = "none";
			if (name) name.text = level > 50 ? "TRACK COMPLETE" : "REWARD UNAVAILABLE";
			if (endpoint) {
				endpoint.SetHasClass("HasReward", false);
				endpoint.hittest = false;
			}
			return;
		}
		var rewardName = reward.name || reward.item_name || reward.reward_id || "Reward";
		var localizedRewardName = LocalizeMaybeKey(rewardName);
		var rarity = (reward.rarity || reward.item_rarity || "common").toString().toLowerCase();
		var rewardType = DisplaySupporterRewardType(reward);
		if (image) {
			image.style.backgroundImage = 'url("' + ResolveRewardImageURL(reward.image || reward.image_inventory || reward.icon || reward.icon_path) + '")';
			image.style.backgroundSize = "contain";
			image.style.backgroundPosition = "50% 50%";
			image.style.backgroundRepeat = "no-repeat";
		}
		if (name) name.text = "LVL " + level + " - " + localizedRewardName;
		if (endpoint) {
			endpoint.SetHasClass("HasReward", true);
			endpoint.AddClass("RewardRarity-" + rarity);
			endpoint.hittest = true;
			endpoint.hittestchildren = true;
			var tooltip = "LEVEL " + level + "\n" + localizedRewardName + "\n" + rarity.toUpperCase() + " - " + rewardType;
			endpoint.SetPanelEvent("onmouseover", function () {
				$.DispatchEvent("UIShowTextTooltip", endpoint, tooltip);
			});
			endpoint.SetPanelEvent("onmouseout", function () {
				$.DispatchEvent("UIHideTextTooltip", endpoint);
			});
		}
	}

	function UpdateXPRewardEndpoints(level) {
		var previousLevel = Math.min(Math.max(level, 1), 50);
		var nextLevel = level >= 50 ? 51 : level + 1;
		var preferredTrack = xpPresentationModel && ToNumber(xpPresentationModel.supporterTier, 0) > 0
			? "premium"
			: "free";
		var previousReward = GetSupporterRewardAtLevel(preferredTrack, previousLevel);
		var nextReward = GetSupporterRewardAtLevel(preferredTrack, nextLevel);
		if (preferredTrack === "premium") {
			previousReward = previousReward || GetSupporterRewardAtLevel("free", previousLevel);
			nextReward = nextReward || GetSupporterRewardAtLevel("free", nextLevel);
		}
		SetXPRewardEndpoint("Previous", previousReward, previousLevel);
		SetXPRewardEndpoint("Next", nextReward, nextLevel);
	}

	function PlayNextXPLevelUp(generation) {
		if (xpLevelBurstActive || xpLevelBurstQueue.length === 0 || generation !== xpPresentationGeneration) {
			return;
		}
		xpLevelBurstActive = true;
		var level = xpLevelBurstQueue.shift();
		var modal = Panel("XHSXPModal");
		var burst = Panel("XHSXPLevelUpBurst");
		var text = Panel("XHSXPLevelUpText");
		if (text) text.text = "+1 LEVEL";
		if (modal) modal.AddClass("IsLevelUp");
		if (burst) burst.AddClass("IsLevelUp");
		UpdateXPRewardEndpoints(level);
		ScheduleXP(generation, 1.06, function () {
			if (modal) modal.RemoveClass("IsLevelUp");
			if (burst) burst.RemoveClass("IsLevelUp");
			xpLevelBurstActive = false;
			ScheduleXP(generation, 0.08, function () { PlayNextXPLevelUp(generation); });
		});
	}

	function TriggerXPLevelUp(level, generation) {
		xpLevelBurstQueue.push(level);
		PlayNextXPLevelUp(generation);
	}

	function UpdateXPProgress(totalXP, presentation, generation, animateLevelUps) {
		totalXP = IntXP(totalXP);
		var level = Math.floor(totalXP / presentation.xpPerLevel) + 1;
		var inLevel = totalXP % presentation.xpPerLevel;
		var percent = Clamp(inLevel / presentation.xpPerLevel * 100, 0, 100);
		var fill = Panel("XHSXPProgressFill");
		var progressText = Panel("XHSXPProgressText");
		var currentLevel = Panel("XHSXPCurrentLevel");
		var nextLevel = Panel("XHSXPNextLevel");
		var totalGain = Panel("XHSXPTotalGain");
		if (fill) fill.style.width = percent + "%";
		if (progressText) progressText.text = FormatNumber(inLevel) + " / " + FormatNumber(presentation.xpPerLevel) + " XP";
		if (currentLevel) currentLevel.text = "LEVEL " + level;
		if (nextLevel) nextLevel.text = "LEVEL " + (level + 1);
		if (totalGain) totalGain.text = "+" + FormatNumber(Math.max(0, totalXP - presentation.beforeXP)) + " XP";

		if (animateLevelUps && level > xpLastAnimatedLevel) {
			for (var crossedLevel = xpLastAnimatedLevel + 1; crossedLevel <= level; crossedLevel++) {
				TriggerXPLevelUp(crossedLevel, generation);
			}
		}
		if (level !== xpLastAnimatedLevel) {
			xpLastAnimatedLevel = level;
			// During an animated gain, reward endpoints advance with each queued
			// +1 LEVEL burst instead of jumping to the final reward immediately.
			if (!animateLevelUps) {
				UpdateXPRewardEndpoints(level);
			}
		}
	}

	function AnimateXPInteger(fromValue, toValue, duration, generation, onUpdate, onComplete) {
		var frames = Math.max(1, Math.floor(duration / 0.03));
		var frame = 0;
		function Tick() {
			frame++;
			var progress = Clamp(frame / frames, 0, 1);
			var eased = 1 - Math.pow(1 - progress, 3);
			onUpdate(Math.round(fromValue + (toValue - fromValue) * eased));
			if (frame >= frames) {
				if (onComplete) onComplete();
				return;
			}
			ScheduleXP(generation, 0.03, Tick);
		}
		Tick();
	}

	function CreateXPTransfer(amount, generation) {
		var layer = Panel("XHSXPTransferLayer");
		if (!layer || amount <= 0) return;
		var transfer = $.CreatePanel("Label", layer, "");
		transfer.AddClass("XHSXPTransferGain");
		transfer.text = "+" + FormatNumber(amount) + " XP";
		ScheduleXP(generation, 0.0, function () { transfer.AddClass("IsFlying"); });
		ScheduleXP(generation, 0.72, function () {
			if (transfer && (!transfer.IsValid || transfer.IsValid())) transfer.DeleteAsync(0);
		});
	}

	function AddXPStepDetail(parent, detail) {
		var row = $.CreatePanel("Panel", parent, "");
		row.AddClass("XHSXPStepDetail");
		var bullet = $.CreatePanel("Label", row, "");
		bullet.AddClass("XHSXPStepDetailBullet");
		bullet.text = "\u2022";
		var label = $.CreatePanel("Label", row, "");
		label.AddClass("XHSXPStepDetailLabel");
		label.text = detail.label;
		var value = $.CreatePanel("Label", row, "");
		value.AddClass("XHSXPStepDetailValue");
		value.text = detail.text ? detail.value : detail.value + " XP";
	}

	function BuildXPSteps(presentation) {
		var container = Panel("XHSXPSteps");
		if (!container) return;
		ClearPanel(container);
		xpStepPanels = [];
		for (var i = 0; i < presentation.steps.length; i++) {
			var step = presentation.steps[i];
			var row = $.CreatePanel("Panel", container, "XHSXPStep_" + step.key);
			row.AddClass("XHSXPStep");
			row.SetHasClass("IsZero", step.amount === 0);
			row.SetHasClass("IsSupporter", step.supporter === true);
			row.SetHasClass("IsFragments", step.resource === "fragments");
			var marker = $.CreatePanel("Label", row, "");
			marker.AddClass("XHSXPStepMarker");
			marker.text = (i + 1).toString();
			var copy = $.CreatePanel("Panel", row, "");
			copy.AddClass("XHSXPStepCopy");
			var title = $.CreatePanel("Label", copy, "");
			title.AddClass("XHSXPStepTitle");
			title.text = step.title;
			var details = $.CreatePanel("Panel", copy, "");
			details.AddClass("XHSXPStepDetails");
			for (var detailIndex = 0; detailIndex < step.details.length; detailIndex++) {
				AddXPStepDetail(details, step.details[detailIndex]);
			}
			if (step.supporter && presentation.supporterPercent === 0) {
				var cta = $.CreatePanel("Button", copy, "");
				cta.AddClass("XHSXPSupporterCTA");
				cta.SetPanelEvent("onactivate", function () { OpenExternalURL(GetSupporterURL()); });
				var ctaLabel = $.CreatePanel("Label", cta, "");
				ctaLabel.text = "UNLOCK UP TO +40% XP";
			}
			var gain = $.CreatePanel("Label", row, "");
			gain.AddClass("XHSXPStepGain");
			gain.text = "+0 " + (step.resource === "fragments" ? "FRAGMENTS" : "XP");
			xpStepPanels.push({ panel: row, gain: gain, step: step });
		}
	}

	function CompleteXPStep(index, generation) {
		var item = xpStepPanels[index];
		if (item && item.panel) {
			item.panel.RemoveClass("IsActive");
			item.panel.AddClass("IsResolved");
		}
		ScheduleXP(generation, 0.16, function () { RunXPStep(index + 1, generation); });
	}

	function RunXPStep(index, generation) {
		if (!xpPresentationData || generation !== xpPresentationGeneration) return;
		if (index >= xpStepPanels.length) {
			UpdateXPProgress(xpPresentationData.finalXP, xpPresentationData, generation, true);
			if (xpLevelBurstActive || xpLevelBurstQueue.length > 0) {
				ScheduleXP(generation, 0.12, function () { RunXPStep(index, generation); });
				return;
			}
			xpPresentationData.finished = true;
			var modal = Panel("XHSXPModal");
			var button = Panel("XHSXPContinueButton");
			var summaryButton = Panel("XHSEndScreenXPButton");
			var label = Panel("XHSXPContinueButtonLabel");
			if (modal) modal.AddClass("IsReady");
			if (button) {
				button.enabled = true;
				button.AddClass("IsReady");
			}
			if (summaryButton) summaryButton.enabled = true;
			if (label) label.text = xpPresentationData.simulation
				? "CLOSE PREVIEW"
				: HasPendingLevelRewards(xpPresentationData)
					? "CONTINUE TO REWARDS"
					: "CONTINUE";
			return;
		}

		var item = xpStepPanels[index];
		var step = item.step;
		item.panel.AddClass("IsActive");
		if (typeof item.panel.ScrollParentToMakePanelFit === "function") {
			try {
				item.panel.ScrollParentToMakePanelFit(0.18, false);
			} catch (scrollError) {
			}
		}
		AnimateXPInteger(0, step.amount, 0.34, generation, function (value) {
			item.gain.text = "+" + FormatNumber(value) + " " + (step.resource === "fragments" ? "FRAGMENTS" : "XP");
		}, function () {
			if (step.amount <= 0) {
				ScheduleXP(generation, 0.34, function () { CompleteXPStep(index, generation); });
				return;
			}
			// Fragment grants are already persisted by the completion endpoint. They
			// get their own reveal without being folded into the XP progress bar.
			if (step.resource === "fragments") {
				ScheduleXP(generation, 0.58, function () { CompleteXPStep(index, generation); });
				return;
			}
			CreateXPTransfer(step.amount, generation);
			var fromTotal = xpPresentationData.animatedXP;
			var toTotal = fromTotal + step.amount;
			var modal = Panel("XHSXPModal");
			if (modal) modal.AddClass("IsAnimating");
			ScheduleXP(generation, 0.18, function () {
				AnimateXPInteger(fromTotal, toTotal, 0.68, generation, function (value) {
					xpPresentationData.animatedXP = value;
					UpdateXPProgress(value, xpPresentationData, generation, true);
				}, function () {
					xpPresentationData.animatedXP = toTotal;
					if (modal) modal.RemoveClass("IsAnimating");
					CompleteXPStep(index, generation);
				});
			});
		});
	}

	function HasPendingLevelRewards(presentation) {
		if (presentation.simulation) return false;
		var includePremium = xpPresentationModel && ToNumber(xpPresentationModel.supporterTier, 0) > 0;
		for (var level = presentation.startLevel + 1; level <= presentation.endLevel && level <= 50; level++) {
			if (GetSupporterRewardAtLevel("free", level)) return true;
			if (includePremium && GetSupporterRewardAtLevel("premium", level)) return true;
		}
		return false;
	}

	function ContinueXPPresentation() {
		if (CloseReopenedXPSummary()) return;
		if (xpPresentationPhase !== "xp" || !xpPresentationData || !xpPresentationData.finished) {
			return;
		}
		xpPresentationPhase = "rewards";
		SetXPOverlayVisible(false);
		var modal = Panel("XHSXPModal");
		if (modal) modal.RemoveClass("IsReady");
		Game.EmitSound("ui_generic_button_click");
		if (xpPresentationData.simulation) {
			xpPresentationPhase = "done";
			return;
		}
		var hasSupporterTier = xpPresentationModel && ToNumber(xpPresentationModel.supporterTier, 0) > 0;
		for (var level = xpPresentationData.startLevel + 1; level <= xpPresentationData.endLevel && level <= 50; level++) {
			var rewardKey = xpPresentationKey + ":" + level;
			if (!shownRewardKeys[rewardKey]) {
				shownRewardKeys[rewardKey] = true;
				CreateBattlepassRewardPanels(level, level - xpPresentationData.startLevel, hasSupporterTier);
			}
		}
		if (rewardQueue.length === 0 && !activeReward) {
			xpPresentationPhase = "done";
		}
	}

	function ReopenXPSummary() {
		if (!xpPresentationData || !xpPresentationData.finished) return;
		UpdateXPProgress(xpPresentationData.finalXP, xpPresentationData, xpPresentationGeneration, false);
		var modal = Panel("XHSXPModal");
		var button = Panel("XHSXPContinueButton");
		var label = Panel("XHSXPContinueButtonLabel");
		if (modal) modal.AddClass("IsReady");
		if (button) {
			button.enabled = true;
			button.AddClass("IsReady");
		}
		if (label) label.text = "CLOSE SUMMARY";
		xpPresentationPhase = "review";
		SetXPOverlayVisible(true);
		Game.EmitSound("ui_generic_button_click");
	}

	function CloseReopenedXPSummary() {
		if (xpPresentationPhase !== "review") return false;
		SetXPOverlayVisible(false);
		xpPresentationPhase = "done";
		Game.EmitSound("ui_generic_button_click");
		return true;
	}

	function StartXPPresentation(data, players) {
		// CompleteGame publishes a local snapshot before its HTTP request finishes
		// so the end-screen has match rows ready. That snapshot has no authoritative
		// XP yet and must not claim the presentation key before the backend receipt.
		if (data && data.completion_pending === true) {
			return;
		}
		var model = GetLocalPlayerModel(players);
		if (!model) {
			xpPresentationPhase = "done";
			return;
		}
		var presentationKey = GetXPPresentationKey(data, model);
		if (xpPresentationKey === presentationKey && xpPresentationPhase !== "idle") {
			return;
		}

		xpPresentationKey = presentationKey;
		xpPresentationPhase = "xp";
		xpPresentationGeneration++;
		xpPresentationModel = model;
		xpPresentationData = GetXPPresentationData(model);
		xpPresentationData.animatedXP = xpPresentationData.beforeXP;
		xpPresentationData.finished = false;
		xpLastAnimatedLevel = xpPresentationData.startLevel;
		xpLevelBurstQueue = [];
		xpLevelBurstActive = false;
		var generation = xpPresentationGeneration;
		var playerName = Panel("XHSXPPlayerName");
		var totalGain = Panel("XHSXPTotalGain");
		var totalCaption = Panel("XHSXPTotalCaption");
		var simulationTitle = Panel("XHSXPSimulationTitle");
		var simulationText = Panel("XHSXPSimulationText");
		var footerHint = Panel("XHSXPFooterHint");
		var continueButton = Panel("XHSXPContinueButton");
		var continueLabel = Panel("XHSXPContinueButtonLabel");
		var modal = Panel("XHSXPModal");
		if (playerName) playerName.text = ResolvePlayerIdentity(model) + (xpPresentationData.simulation ? " - XP PREVIEW" : " - PERSONAL PROGRESSION");
		if (totalGain) totalGain.text = "+0 XP";
		if (totalCaption) totalCaption.text = xpPresentationData.simulation ? "THEORETICAL TOTAL" : "TOTAL EARNED";
		if (simulationTitle) {
			simulationTitle.text = xpPresentationData.reason === "tools_mode_telemetry_only"
				? "TOOLS MODE - SIMULATION ONLY"
				: (xpPresentationData.reason === "cheat_mode" || xpPresentationData.reason === "cheat_mode_not_whitelisted")
					? "CHEATS ENABLED - SIMULATION ONLY"
					: "MATCH NOT ELIGIBLE - SIMULATION ONLY";
		}
		if (simulationText) {
			simulationText.text = xpPresentationData.reason === "tools_mode_telemetry_only"
				? "Theoretical XP is animated for UI testing. No XP or rewards are saved."
				: (xpPresentationData.reason === "cheat_mode" || xpPresentationData.reason === "cheat_mode_not_whitelisted")
					? "This match used cheats. Theoretical XP is shown, but nothing is saved."
					: "Theoretical XP is shown for preview. No XP or rewards are saved.";
		}
		if (footerHint) footerHint.text = xpPresentationData.simulation
			? "Preview only - your real Supporter Pass progression is unchanged"
			: "Your unlocked rewards will follow";
		if (continueButton) {
			continueButton.enabled = false;
			continueButton.RemoveClass("IsReady");
		}
		if (continueLabel) continueLabel.text = "CALCULATING XP";
		if (modal) {
			modal.RemoveClass("IsReady");
			modal.RemoveClass("IsLevelUp");
			modal.SetHasClass("IsSimulation", xpPresentationData.simulation);
		}
		BuildXPSteps(xpPresentationData);
		UpdateXPRewardEndpoints(xpPresentationData.startLevel);
		UpdateXPProgress(xpPresentationData.beforeXP, xpPresentationData, generation, false);
		SetXPOverlayVisible(true);
		ScheduleXP(generation, 0.42, function () { RunXPStep(0, generation); });
	}

	function CreateBattlepassCell(parent, model) {
		var cell = $.CreatePanel("Panel", parent, "");
		cell.AddClass("PlayerColBattlepass");
		cell.AddClass("XHSBattlepassCell");
		var hasSupporterTier = ToNumber(model.supporterTier, 0) > 0;
		cell.SetHasClass("XHSBattlepassSupporterCell", hasSupporterTier);
		if (hasSupporterTier) {
			cell.AddClass("XHSSupporterTier" + model.supporterTier);
		}

		var top = $.CreatePanel("Panel", cell, "");
		top.AddClass("XHSBattlepassTop");

		var level = $.CreatePanel("Label", top, "");
		level.AddClass("XHSBattlepassLevel");

		var earned = $.CreatePanel("Label", top, "");
		earned.AddClass("XHSBattlepassEarned");

		var bar = $.CreatePanel("Panel", cell, "");
		bar.AddClass("XHSBattlepassBar");

		var progressPanel = $.CreatePanel("Panel", bar, "");
		progressPanel.AddClass("XHSBattlepassProgress");

		var diffPanel = $.CreatePanel("Panel", bar, "");
		diffPanel.AddClass("XHSBattlepassDiff");

		var accountLine = $.CreatePanel("Label", cell, "");
		accountLine.AddClass("XHSAccountXpLine");

		var xpBreakdown = $.CreatePanel("Panel", cell, "");
		xpBreakdown.AddClass("XHSXPBreakdown");

		var durationLine = $.CreatePanel("Label", xpBreakdown, "");
		durationLine.AddClass("XHSXPBreakdownBase");

		var victoryLine = $.CreatePanel("Label", xpBreakdown, "");
		victoryLine.AddClass("XHSXPBreakdownVictory");

		var supporterLine = $.CreatePanel("Label", cell, "");
		supporterLine.AddClass("XHSXPBreakdownSupporter");
		supporterLine.AddClass("XHSXPBreakdownSupporterRow");

		var battlepass = model.battlepass || {};
		var xpPresentation = GetXPPresentationData(model);
		cell.SetHasClass("IsSimulation", xpPresentation.simulation);
		var xpEnabled = battlepass.player_xp !== 0 && battlepass.player_xp !== "0" && battlepass.player_xp !== false;
		var supporter = NormalizeSupporterProgress(battlepass);
		var persistedSupporterChange = ToNumber(
			battlepass.XP_change !== undefined ? battlepass.XP_change
				: (battlepass.season_xp_change !== undefined ? battlepass.season_xp_change : 0),
			0
		);
		var supporterChange = xpPresentation.simulation ? xpPresentation.totalXP : persistedSupporterChange;
		var xhsProgress = GetXHSAccountProgress(model.api, battlepass);
		var xpBonus = xpPresentation.simulation ? xpPresentation.steps[6].amount : Math.max(0, ToNumber(battlepass.xp_bonus, 0));
		var xpBoost = Math.max(0, ToNumber(battlepass.xp_boost, 0));
		var baseXPChange = xpPresentation.simulation ? xpPresentation.subtotal : Math.max(0, ToNumber(battlepass.base_xp_change, supporterChange - xpBonus));
		var durationXP = xpPresentation.simulation ? xpPresentation.steps[0].amount : Math.max(0, ToNumber(battlepass.duration_xp, baseXPChange));
		var victoryXPBonus = xpPresentation.simulation ? xpPresentation.steps[5].amount : Math.max(0, ToNumber(battlepass.victory_xp_bonus, 0));
		var xpIneligibleReason = xpPresentation.reason;

		if (!xpEnabled) {
			level.text = "N/A";
			earned.text = "N/A";
			progressPanel.style.width = "0%";
			diffPanel.style.width = "0%";
			accountLine.text = "XHS N/A";
			xpBreakdown.style.visibility = "collapse";
			return;
		}

		var levelText = "Level " + supporter.level;
		if (battlepass.title) {
			levelText += " - " + battlepass.title;
			level.style.color = battlepass.title_color || "#dceeff";
		}
		if (hasSupporterTier) {
			level.style.color = model.supporterTierColor;
			bar.style.border = "1px solid " + ColorWithAlpha(model.supporterTierColor, "78");
			bar.style.boxShadow = "fill " + ColorWithAlpha(model.supporterTierColor, "1f") + " 0px 0px 8px 0px";
			progressPanel.style.backgroundColor = "gradient( linear, 0% 0%, 100% 0%, from( " + ColorWithAlpha(model.supporterTierColor, "70") + " ), to( " + model.supporterTierColor + " ) )";
			diffPanel.style.backgroundColor = "gradient( linear, 0% 0%, 100% 0%, from( #ffe28a ), to( " + model.supporterTierColor + " ) )";
		}

		level.text = levelText;
		earned.text = FormatSignedNumber(supporterChange) + (xpPresentation.simulation ? " preview" : "");
		earned.SetHasClass("IsNegative", supporterChange < 0);
		earned.SetHasClass("IsPreview", xpPresentation.simulation);
		accountLine.text = FormatXHSAccountProgress(xhsProgress);
		var ineligibleMessages = {
			tools_mode_telemetry_only: "Preview only - Tools Mode",
			cheat_mode: "No XP - cheats enabled",
			cheat_mode_not_whitelisted: "No XP - cheats enabled",
			persistent_rewards_disabled: "Preview only - persistence disabled",
			match_too_short: "No XP - match under 30 minutes",
			abandoned: "No XP - abandoned match",
			disconnected: "No XP - disconnected"
		};
		durationLine.text = xpIneligibleReason
			? (ineligibleMessages[xpIneligibleReason] || "Preview only - ineligible match")
			: "+" + FormatNumber(durationXP) + " match";
		xpBreakdown.SetHasClass("IsIneligible", !!xpIneligibleReason);
		xpBreakdown.SetHasClass("IsSimulation", xpPresentation.simulation);
		victoryLine.text = "+" + FormatNumber(victoryXPBonus) + " victory";
		victoryLine.style.visibility = victoryXPBonus > 0 ? "visible" : "collapse";
		supporterLine.text = "SUPPORTER BOOST  +" + FormatNumber(xpBonus) + " XP (" + xpBoost + "%)";
		supporterLine.style.visibility = xpBonus > 0 && xpBoost > 0 ? "visible" : "collapse";
		if (hasSupporterTier) {
			supporterLine.style.color = model.supporterTierColor;
			supporterLine.style.textShadow = "0px 0px 5px " + ColorWithAlpha(model.supporterTierColor, "55");
		}

		var progress = Clamp(Math.floor((supporter.xp / supporter.max) * 100), 0, 100);
		var diff = Clamp(Math.floor((supporterChange / supporter.max) * 100), 0, 100);
		progressPanel.style.width = progress + "%";
		diffPanel.style.width = diff + "%";
		diffPanel.style.marginLeft = Math.max(0, progress - 1) + "%";

		var tooltip = "Supporter Pass: Level " + supporter.level + " - " + FormatNumber(supporter.xp) + "/" + FormatNumber(supporter.max) + " XP";
		if (xpIneligibleReason) {
			tooltip += "\n" + (ineligibleMessages[xpIneligibleReason] || "Preview only - ineligible match");
			tooltip += "\nTheoretical total: " + FormatSignedNumber(supporterChange) + " XP";
			tooltip += "\nNothing was added to your account.";
		}
		if (supporterChange > 0 && !xpPresentation.simulation) {
			tooltip += "\nMatch XP: +" + FormatNumber(durationXP);
			if (victoryXPBonus > 0) {
				tooltip += "\nVictory bonus: +" + FormatNumber(victoryXPBonus);
			}
			if (xpBonus > 0 && xpBoost > 0) {
				tooltip += "\nSupporter boost (" + xpBoost + "%): +" + FormatNumber(xpBonus);
			}
			tooltip += "\nTotal: " + FormatSignedNumber(supporterChange) + " XP";
		}
		if (xhsProgress.hasData) {
			tooltip += "\n" + FormatXHSAccountProgress(xhsProgress);
		}
		cell.SetPanelEvent("onmouseover", function () {
			$.DispatchEvent("UIShowTextTooltip", cell, tooltip);
		});
		cell.SetPanelEvent("onmouseout", function () {
			$.DispatchEvent("UIHideTextTooltip", cell);
		});

		var completionSeason = model.api && model.api.season ? model.api.season : {};
		var finalTotalXP = xpPresentation.simulation ? xpPresentation.finalXP : IntXP(FirstDefined(completionSeason.xp, battlepass.season_total_xp, battlepass.season_xp));
		var startingTotalXP = xpPresentation.simulation ? xpPresentation.beforeXP : IntXP(FirstDefined(completionSeason.xp_before, battlepass.season_xp_before, finalTotalXP - supporterChange));
		var startingLevel = Math.floor(startingTotalXP / supporter.max) + 1;
		var finalLevel = Math.floor(finalTotalXP / supporter.max) + 1;
		var levelUps = Math.max(0, finalLevel - startingLevel);
		bar.SetHasClass("LevelUp", supporterChange > 0 && levelUps >= 1);
	}

	function CreatePlayerRow(parent, model) {
		var row = $.CreatePanel("Panel", parent, "XHSEndScreenPlayerRow_" + model.id);
		row.AddClass("XHSEndScreenPlayerRow");
		row.SetHasClass("IsAbandoned", model.abandon);
		var hasSupporterTier = ToNumber(model.supporterTier, 0) > 0;
		row.SetHasClass("XHSEndScreenSupporterRow", hasSupporterTier);
		if (hasSupporterTier) {
			row.AddClass("XHSSupporterTier" + model.supporterTier);
			row.style.border = "1px solid " + ColorWithAlpha(model.supporterTierColor, "62");
			row.style.boxShadow = "inset " + ColorWithAlpha(model.supporterTierColor, "1a") + " 0px 0px 18px 0px";
		}
		row.hittest = true;
		row.hittestchildren = true;

		var identity = $.CreatePanel("Panel", row, "");
		identity.AddClass("XHSPlayerIdentity");
		identity.hittest = true;

		var identityTop = $.CreatePanel("Panel", identity, "");
		identityTop.AddClass("XHSPlayerIdentityTop");

		var heroFrame = $.CreatePanel("Panel", identityTop, "");
		heroFrame.AddClass("XHSPlayerHeroFrame");
		heroFrame.style.boxShadow = "fill " + ColorWithAlpha(model.playerColor, "66") + " 0px 0px 8px 0px" + (hasSupporterTier ? ", fill " + ColorWithAlpha(model.supporterTierColor, "70") + " 0px 0px 11px 0px" : "");
		if (hasSupporterTier) {
			heroFrame.style.border = "1px solid " + ColorWithAlpha(model.supporterTierColor, "c8");
		}

		var playerColor = $.CreatePanel("Panel", heroFrame, "");
		playerColor.AddClass("XHSPlayerColorStrip");
		playerColor.style.backgroundColor = model.playerColor;

		var heroImage = $.CreatePanel("DOTAHeroImage", heroFrame, "");
		heroImage.AddClass("XHSPlayerHeroImage");
		heroImage.heroimagestyle = "landscape";
		if (model.hero) {
			heroImage.heroname = model.hero;
		}

		var avatar = $.CreatePanel("DOTAAvatarImage", identityTop, "");
		avatar.AddClass("XHSPlayerAvatar");
		avatar.steamid = model.steamID;

		var text = $.CreatePanel("Panel", identityTop, "");
		text.AddClass("XHSPlayerText");

		var name = $.CreatePanel("Label", text, "");
		name.AddClass("XHSPlayerName");
		name.text = ResolvePlayerIdentity(model);
		name.style.visibility = name.text ? "visible" : "collapse";
		if (hasSupporterTier) {
			name.style.color = model.supporterTierColor;
			name.style.textShadow = "0px 1px 2px #000000, 0px 0px 7px " + ColorWithAlpha(model.supporterTierColor, "82");
		}

		var heroName = $.CreatePanel("Label", text, "");
		heroName.AddClass("XHSPlayerHeroName");
		heroName.text = model.abandon ? "Abandoned" : "";
		heroName.style.visibility = model.abandon ? "visible" : "collapse";

		var inventory = $.CreatePanel("Panel", identity, "");
		inventory.AddClass("XHSPlayerInventory");
		var inventoryItems = [];
		var inventoryItemNames = [];
		for (var slot = 0; slot < 6; slot++) {
			var itemName = model.inventory && model.inventory[slot] ? model.inventory[slot] : "";
			var item = $.CreatePanel("DOTAItemImage", inventory, "");
			item.AddClass("XHSPlayerInventoryItem");
			item.SetHasClass("IsEmpty", !itemName);
			item.itemname = itemName;
			item.hittest = !!itemName;
			item.hittestchildren = false;
			item.style.tooltipPosition = "top";
			inventoryItems.push(item);
			inventoryItemNames.push(itemName);
		}

		CreateCell(row, "PlayerColSmall", model.level.toString());
		CreateCell(row, "PlayerColKda", FormatNumber(model.kills), "XHSPlayerCellKills");
		CreateCell(row, "PlayerColNumber", FormatNumber(model.deaths));
		CreateCell(row, "PlayerColNumber", FormatNumber(model.networth), "XHSPlayerCellGold");
		CreateCell(row, "PlayerColNumber", "+" + FormatNumber(model.tomeStatsBonus), "XHSPlayerCellStats");
		CreateCell(row, "PlayerColNumber", FormatNumber(model.potionsUsed), "XHSPlayerCellPotions");
		CreateBattlepassCell(row, model);

		var inventoryHoverActive = false;
		var hideSupporterHover = null;
		if (typeof XHSSupporterHover !== "undefined" && XHSSupporterHover.Create) {
			var hoverID = "End_" + model.id;
			var hoverRoot = Panel("XHSEndScreenMain") || row;
			var hover = XHSSupporterHover.Create(hoverRoot, hoverID, { className: "XHSEndScreenSupporterHover" });
			var showHover = function () {
				if (inventoryHoverActive) {
					XHSSupporterHover.Hide(row, hover);
					return;
				}
				var data = XHSSupporterHover.GetPlayerData(model.id, {
					model: model,
					tableData: model.battlepass || {},
				});
				XHSSupporterHover.Update(hover, hoverID, data);
				XHSSupporterHover.PositionNearAnchor(identity, hover, hoverRoot, { gap: 12 });
				XHSSupporterHover.Show(row, hover);
			};
			var hideHover = function () {
				XHSSupporterHover.Hide(row, hover);
			};
			hideSupporterHover = hideHover;

			row.SetPanelEvent("onmouseover", showHover);
			row.SetPanelEvent("onmouseout", hideHover);
			identity.SetPanelEvent("onmouseover", showHover);
			identity.SetPanelEvent("onmouseout", hideHover);
		}

		for (var itemIndex = 0; itemIndex < inventoryItems.length; itemIndex++) {
			(function (inventoryItem, inventoryItemName) {
				if (!inventoryItemName) return;
				inventoryItem.SetPanelEvent("onmouseover", function () {
					inventoryHoverActive = true;
					if (hideSupporterHover) hideSupporterHover();
					$.DispatchEvent("DOTAShowAbilityTooltip", inventoryItem, inventoryItemName);
				});
				inventoryItem.SetPanelEvent("onmouseout", function () {
					inventoryHoverActive = false;
					$.DispatchEvent("DOTAHideAbilityTooltip", inventoryItem);
				});
			})(inventoryItems[itemIndex], inventoryItemNames[itemIndex]);
		}
	}

	function RenderPlayers(players) {
		var rows = Panel("XHSEndScreenPlayerRows");
		ClearPanel(rows);

		var count = Panel("XHSEndScreenPlayerCount");
		if (count) {
			count.text = players.length + (players.length === 1 ? " player" : " players");
		}

		var playersMeta = Panel("XHSEndScreenPlayersMeta");
		if (playersMeta) {
			playersMeta.text = players.length.toString();
		}

		if (!rows) {
			return;
		}

		for (var i = 0; i < players.length; i++) {
			CreatePlayerRow(rows, players[i]);
		}
	}

	function NormalizeHallEntries(rawData) {
		var entries = [];
		var source = rawData;

		if (source && source.data !== undefined) {
			source = source.data;
		}

		if (source && source.players !== undefined) {
			source = source.players;
		}

		if (!source) {
			return entries;
		}

		for (var key in source) {
			if (!source.hasOwnProperty(key)) {
				continue;
			}

			var entry = source[key];
			if (entry && typeof entry === "object") {
				entry.__key = key;
				entries.push(entry);
			}
		}

		entries.sort(function (a, b) {
			var rankA = ToNumber(a.rank || a.place, 0);
			var rankB = ToNumber(b.rank || b.place, 0);
			if (rankA > 0 && rankB > 0) {
				return rankA - rankB;
			}

			return ToNumber(b.score || b.points || b.imr || b.roshan, 0) - ToNumber(a.score || a.points || a.imr || a.roshan, 0);
		});

		return entries;
	}

	function RenderHallOfFame() {
		var rows = Panel("XHSEndScreenHallRows");
		var empty = Panel("XHSEndScreenHallEmpty");
		ClearPanel(rows);

		var hallData = CustomNetTables.GetTableValue("battlepass", "leaderboard_diretide");
		var entries = NormalizeHallEntries(hallData);

		if (empty) {
			empty.SetHasClass("IsVisible", entries.length === 0);
		}

		if (!rows) {
			return;
		}

		for (var i = 0; i < entries.length; i++) {
			var entry = entries[i];
			var row = $.CreatePanel("Panel", rows, "");
			row.AddClass("XHSEndScreenHallRow");

			var rank = $.CreatePanel("Label", row, "");
			rank.AddClass("HallColRank");
			rank.text = (entry.rank || entry.place || (i + 1)).toString();

			var name = $.CreatePanel("Label", row, "");
			name.AddClass("HallColPlayer");
			name.text = ResolveHallIdentity(entry);

			var score = $.CreatePanel("Label", row, "");
			score.AddClass("HallColScore");
			score.text = FormatNumber(entry.score || entry.points || entry.imr || entry.roshan || entry.value || 0);
		}
	}

	function OpenHallOfFame() {
		RenderHallOfFame();

		var panel = Panel("XHSEndScreenHallPanel");
		if (panel) {
			panel.AddClass("IsVisible");
		}
	}

	function CloseHallOfFame() {
		var panel = Panel("XHSEndScreenHallPanel");
		if (panel) {
			panel.RemoveClass("IsVisible");
		}
	}

	function SetRewardOverlayVisible(visible) {
		var container = Panel("XHSEndScreenRewardContainer");
		if (container) {
			container.SetHasClass("IsVisible", visible);
		}
		var root = $.GetContextPanel();
		if (root) {
			root.SetHasClass("HasPendingRewards", visible);
		}
	}

	function FindCompletedFragmentGrant(reward) {
		if (!reward || !xpPresentationModel) return null;
		var api = xpPresentationModel.api || {};
		var season = api.season || {};
		var supporterPass = api.supporter_pass || api.supporterPass || {};
		var grants = TableToArray(FirstDefined(
			api.fragment_reward_grants,
			season.fragment_reward_grants,
			supporterPass.fragment_reward_grants,
			{}
		));
		var rewardID = (reward.reward_id || reward.id || "").toString();
		for (var i = 0; i < grants.length; i++) {
			var grant = grants[i] || {};
			if ((grant.reward_id || "").toString() === rewardID && ToNumber(grant.amount, 0) > 0) {
				return grant;
			}
		}
		return null;
	}

	function AnimateFragmentRewardCounter(label, fromValue, toValue, onComplete) {
		var frames = 18;
		var frame = 0;
		function Tick() {
			if (!label || (label.IsValid && !label.IsValid())) return;
			frame++;
			var progress = Clamp(frame / frames, 0, 1);
			var eased = 1 - Math.pow(1 - progress, 3);
			label.text = FormatNumber(Math.round(fromValue + (toValue - fromValue) * eased));
			if (frame >= frames) {
				if (onComplete) onComplete();
				return;
			}
			$.Schedule(0.025, Tick);
		}
		Tick();
	}

	function QueueBattlepassReward(level, levelupCount, track, reward) {
		if (!reward) {
			return;
		}
		rewardQueue.push({
			level: level,
			levelupCount: levelupCount,
			track: track,
			reward: reward,
			fragmentGrant: FindCompletedFragmentGrant(reward),
		});
		rewardBatchTotal++;
		if (xpPresentationPhase === "xp") {
			return;
		}
		SetRewardOverlayVisible(true);

		if (!rewardRevealScheduled) {
			rewardRevealScheduled = true;
			$.Schedule(0.0, function () {
				rewardRevealScheduled = false;
				ShowNextQueuedReward();
			});
		}
	}

	function ShowNextQueuedReward() {
		if (activeReward) {
			return;
		}

		var container = Panel("XHSEndScreenRewardContainer");
		if (!container) {
			return;
		}

		ClearPanel(container);
		if (rewardQueue.length === 0) {
			SetRewardOverlayVisible(false);
			rewardBatchTotal = 0;
			rewardBatchAccepted = 0;
			if (xpPresentationPhase === "rewards") {
				xpPresentationPhase = "done";
			}
			return;
		}

		activeReward = rewardQueue.shift();
		var level = activeReward.level;
		var track = activeReward.track;
		var reward = activeReward.reward;
		var fragmentGrant = activeReward.fragmentGrant;
		var fragmentAmount = fragmentGrant ? Math.max(0, ToNumber(fragmentGrant.amount, 0)) : 0;

		var rewardName = reward.name || reward.item_name || reward.reward_id || "xhs_sp_reward";
		var rarity = (reward.rarity || reward.item_rarity || "common").toString().toLowerCase();
		var rewardType = DisplaySupporterRewardType(reward);
		var revealTier = rarity === "mythical" ? 1
			: (rarity === "legendary" ? 2
				: ((rarity === "immortal" || rarity === "arcana" || rarity === "ancient") ? 3 : 0));

		if (revealTier > 0) {
			var revealEffects = $.CreatePanel("Panel", container, "");
			revealEffects.AddClass("XHSRewardRevealEffects");
			revealEffects.AddClass("RevealTier" + revealTier);
			revealEffects.AddClass("level-" + rarity);

			var burst = $.CreatePanel("Panel", revealEffects, "");
			burst.AddClass("XHSRewardRevealBurst");

			if (revealTier >= 2) {
				var rays = $.CreatePanel("Panel", revealEffects, "");
				rays.AddClass("XHSRewardRevealRays");
				var raysCross = $.CreatePanel("Panel", revealEffects, "");
				raysCross.AddClass("XHSRewardRevealRays");
				raysCross.AddClass("Cross");
			}

			if (revealTier >= 3) {
				var flash = $.CreatePanel("Panel", revealEffects, "");
				flash.AddClass("XHSRewardRevealFlash");
			}
		}

		var panel = $.CreatePanel("Panel", container, "XHSEndScreenRewardPanel_" + (++rewardPanelSequence));
		panel.AddClass("XHSEndScreenRewardPanel");
		panel.AddClass("level-" + rarity);
		if (revealTier > 0) {
			panel.AddClass("RevealTier" + revealTier);
		}
		panel.SetHasClass("IsPremiumReward", track === "premium");
		panel.SetHasClass("IsFragmentReward", fragmentAmount > 0);

		var accent = $.CreatePanel("Panel", panel, "");
		accent.AddClass("XHSRewardAccent");

		var header = $.CreatePanel("Panel", panel, "");
		header.AddClass("XHSRewardHeader");

		var unlocked = $.CreatePanel("Label", header, "");
		unlocked.AddClass("XHSRewardUnlocked");
		unlocked.text = "REWARD UNLOCKED";

		var queueProgress = $.CreatePanel("Label", header, "");
		queueProgress.AddClass("XHSRewardQueueProgress");
		queueProgress.text = (rewardBatchAccepted + 1) + " / " + rewardBatchTotal;

		var description = $.CreatePanel("Label", panel, "");
		description.AddClass("XHSRewardDescription");
		description.text = Localize(track === "premium" ? "#xhs_sp_supporter_track" : "#xhs_sp_free_track") +
			" · " + Localize("#xhs_sp_level_value").replace("{level}", level);

		var imageFrame = $.CreatePanel("Panel", panel, "");
		imageFrame.AddClass("XHSRewardImageFrame");

		var imageGlow = $.CreatePanel("Panel", imageFrame, "");
		imageGlow.AddClass("XHSRewardImageGlow");
		imageGlow.AddClass(rarity);

		var image = $.CreatePanel("Panel", imageFrame, "");
		image.AddClass("XHSRewardImage");
		image.style.backgroundImage = 'url("' + ResolveRewardImageURL(reward.image || reward.image_inventory || reward.icon || reward.icon_path) + '")';
		image.style.backgroundSize = "contain";
		image.style.backgroundPosition = "50% 50%";
		image.style.backgroundRepeat = "no-repeat";

		var type = $.CreatePanel("Label", panel, "");
		type.AddClass("XHSRewardType");
		type.text = rewardType;

		var name = $.CreatePanel("Label", panel, "");
		name.AddClass("XHSRewardName");
		name.text = LocalizeMaybeKey(rewardName);

		var rarityPanel = $.CreatePanel("Label", panel, "");
		rarityPanel.AddClass("XHSRewardRarity");
		rarityPanel.AddClass(rarity);
		rarityPanel.text = rarity;

		var fragmentBalance = null;
		var fragmentGain = null;
		var fragmentBalanceBefore = 0;
		var fragmentBalanceAfter = 0;
		if (fragmentAmount > 0) {
			fragmentBalanceBefore = Math.max(0, ToNumber(
				fragmentGrant.balance_before,
				ToNumber(fragmentGrant.balance_after, fragmentAmount) - fragmentAmount
			));
			fragmentBalanceAfter = Math.max(
				fragmentBalanceBefore + fragmentAmount,
				ToNumber(fragmentGrant.balance_after, fragmentBalanceBefore + fragmentAmount)
			);
			var fragmentCounter = $.CreatePanel("Panel", panel, "");
			fragmentCounter.AddClass("XHSRewardFragmentCounter");
			var fragmentCaption = $.CreatePanel("Label", fragmentCounter, "");
			fragmentCaption.AddClass("XHSRewardFragmentCaption");
			fragmentCaption.text = "AUTO-CLAIMED · FRAGMENTS";
			fragmentBalance = $.CreatePanel("Label", fragmentCounter, "");
			fragmentBalance.AddClass("XHSRewardFragmentBalance");
			fragmentBalance.text = FormatNumber(fragmentBalanceBefore);
			fragmentGain = $.CreatePanel("Label", fragmentCounter, "");
			fragmentGain.AddClass("XHSRewardFragmentGain");
			fragmentGain.text = "+" + FormatNumber(fragmentAmount);
		}

		var button = $.CreatePanel("Button", panel, "");
		button.AddClass("XHSRewardButton");
		var accepting = false;
		button.SetPanelEvent("onactivate", function () {
			if (!activeReward || accepting) {
				return;
			}
			accepting = true;
			button.AddClass("IsAccepting");
			panel.AddClass("IsLeaving");
			Game.EmitSound("ui_generic_button_click");
			$.Schedule(0.18, function () {
				rewardBatchAccepted++;
				activeReward = null;
				ShowNextQueuedReward();
			});
		});

		var label = $.CreatePanel("Label", button, "");
		label.text = rewardQueue.length > 0 ? Localize("#xhs_sp_accept") + "  ›" : Localize("#xhs_sp_accept");
		if (fragmentAmount > 0) {
			button.enabled = false;
			label.text = "AUTO-CLAIMING...";
			$.Schedule(0.36, function () {
				if (fragmentGain && (!fragmentGain.IsValid || fragmentGain.IsValid())) {
					fragmentGain.AddClass("IsFlying");
				}
			});
			$.Schedule(0.72, function () {
				AnimateFragmentRewardCounter(fragmentBalance, fragmentBalanceBefore, fragmentBalanceAfter, function () {
					if (fragmentBalance && (!fragmentBalance.IsValid || fragmentBalance.IsValid())) {
						fragmentBalance.AddClass("HasIncreased");
					}
					if (button && (!button.IsValid || button.IsValid())) {
						button.enabled = true;
						label.text = rewardQueue.length > 0 ? "CONTINUE  ›" : "CONTINUE";
					}
				});
			});
			$.Schedule(1.28, function () {
				if (fragmentGain && (!fragmentGain.IsValid || fragmentGain.IsValid())) {
					fragmentGain.DeleteAsync(0);
				}
			});
		}

		var closeAllButton = $.CreatePanel("Button", panel, "");
		closeAllButton.AddClass("XHSRewardCloseAllButton");
		closeAllButton.SetPanelEvent("onactivate", function () {
			if (!activeReward) {
				return;
			}
			rewardQueue = [];
			rewardBatchAccepted = rewardBatchTotal;
			activeReward = null;
			Game.EmitSound("ui_generic_button_click");
			ClearPanel(container);
			SetRewardOverlayVisible(false);
			rewardBatchTotal = 0;
			rewardBatchAccepted = 0;
			xpPresentationPhase = "done";
		});

		var closeAllLabel = $.CreatePanel("Label", closeAllButton, "");
		closeAllLabel.text = "CLOSE ALL";

		var remaining = $.CreatePanel("Label", panel, "");
		remaining.AddClass("XHSRewardRemaining");
		remaining.text = rewardQueue.length > 0
			? rewardQueue.length + (rewardQueue.length === 1 ? " reward remaining" : " rewards remaining")
			: "Final reward";

		var sounds = {
			common: "Loot_Drop_Sfx",
			uncommon: "Loot_Drop_Stinger_Uncommon",
			rare: "Loot_Drop_Stinger_Rare",
			mythical: "Loot_Drop_Stinger_Mythical",
			legendary: "Loot_Drop_Stinger_Legendary",
			immortal: "Loot_Drop_Stinger_Immortal",
			arcana: "Loot_Drop_Stinger_Arcana",
			ancient: "Loot_Drop_Stinger_Ancient",
		};

		if (sounds[rarity]) {
			Game.EmitSound(sounds[rarity]);
		}
	}

	function CreateBattlepassRewardPanels(level, levelupCount, includePremium) {
		if (level < 1 || level > 50) {
			return;
		}
		QueueBattlepassReward(level, levelupCount, "free", GetSupporterRewardAtLevel("free", level));
		if (includePremium) {
			QueueBattlepassReward(level, levelupCount, "premium", GetSupporterRewardAtLevel("premium", level));
		}
	}

	function BindButtons() {
		var website = Panel("XHSEndScreenWebsiteButton");
		if (website) {
			website.SetPanelEvent("onactivate", function () {
				OpenExternalURL(WEBSITE_URL);
			});
		}

		var discord = Panel("XHSEndScreenDiscordButton");
		if (discord) {
			discord.SetPanelEvent("onactivate", function () {
				OpenExternalURL(DISCORD_URL);
			});
		}

		var support = Panel("XHSEndScreenSupportButton");
		if (support) {
			support.SetPanelEvent("onactivate", function () {
				OpenSupporterPortal();
			});
		}

		var close = Panel("XHSEndScreenCloseButton");
		if (close) {
			close.SetPanelEvent("onactivate", FinishGame);
		}

		var fallbackClose = Panel("XHSEndScreenFallbackClose");
		if (fallbackClose) {
			fallbackClose.SetPanelEvent("onactivate", FinishGame);
		}

		var fallbackGameId = Panel("XHSEndScreenFallbackGameIdButton");
		if (fallbackGameId) {
			fallbackGameId.SetPanelEvent("onactivate", function () {
				var url = GetPublicMatchURL(GetPublishedGameId());
				if (url) OpenExternalURL(url);
			});
			fallbackGameId.SetPanelEvent("onmouseover", function () {
				var value = GetPublishedGameId();
				if (value) $.DispatchEvent("UIShowTextTooltip", fallbackGameId, "Open this match on the Frostrose website");
			});
			fallbackGameId.SetPanelEvent("onmouseout", function () {
				$.DispatchEvent("UIHideTextTooltip", fallbackGameId);
			});
		}

		var hall = Panel("XHSEndScreenHallButton");
		if (hall) {
			hall.enabled = false;
		}

		var hallClose = Panel("XHSEndScreenHallCloseButton");
		if (hallClose) {
			hallClose.SetPanelEvent("onactivate", CloseHallOfFame);
		}

		var farm = Panel("XHSEndScreenFarmButton");
		if (farm) {
			farm.SetPanelEvent("onactivate", function () {
				if (GetFarmLeaderboardPlayers().length === 0 || !lastEndGameData) {
					return;
				}
				farmLeaderboardVisible = !farmLeaderboardVisible;
				RenderHighlightPanel(BuildPlayerModels(lastEndGameData));
				Game.EmitSound("ui_generic_button_click");
			});
		}

		var xpSummary = Panel("XHSEndScreenXPButton");
		if (xpSummary) {
			xpSummary.SetPanelEvent("onactivate", ReopenXPSummary);
		}

		var xpContinue = Panel("XHSXPContinueButton");
		if (xpContinue) {
			xpContinue.SetPanelEvent("onactivate", ContinueXPPresentation);
		}
	}

	function SetLoading(isLoading) {
		var root = $.GetContextPanel();

		if (root) {
			root.SetHasClass("IsLoading", isLoading);
		}
	}

	function RenderEndGameData(data) {
		if (!data) return;

		try {
			lastEndGameData = data;
			var players = BuildPlayerModels(data);

			RenderHeader(data);
			RenderFragmentQuests(data);
			RenderHighlightPanel(players);
			RenderPlayers(players);
			RenderHallOfFame();

			hasRenderedEndGame = true;
			SetLoading(false);
			var root = $.GetContextPanel();
			if (root) {
				root.SetHasClass("IsFallback", false);
			}
			StartXPPresentation(data, players);
		} catch (error) {
			$.Msg("[XHSEndScreen] Render failed: " + String(error && (error.stack || error.message) || error));
		}
	}

	function RefreshIdentitySurfaces() {
		if (!hasRenderedEndGame || !lastEndGameData) {
			return;
		}

		try {
			var players = BuildPlayerModels(lastEndGameData);
			RenderHighlightPanel(players);
			RenderPlayers(players);
			RenderHallOfFame();
		} catch (error) {
			$.Msg("[XHSEndScreen] Identity refresh failed: " + error);
		}
	}

	function SubscribeEndGameData() {
		if (endGameSubscription !== null) return;
		if (!CustomNetTables || !CustomNetTables.SubscribeNetTableListener) return;

		endGameSubscription = CustomNetTables.SubscribeNetTableListener("game_options", function (tableName, key, data) {
			if (key === "end_game") {
				RenderEndGameData(data);
			}
		});
	}

	function Init() {
		HideVanillaHud();
		BindButtons();
		SubscribeEndGameData();
		CustomNetTables.SubscribeNetTableListener("xhs_run_identity", function (tableName, key) {
			if (key === "current") RefreshFallbackGameId();
		});
		RefreshFallbackGameId();
		GameEvents.Subscribe("supporter_pass_payment_portal_ready", function (payload) {
			supporterPortalRequestPending = false;
			if (payload && payload.url) OpenExternalURL(payload.url);
		});
		GameEvents.Subscribe("supporter_pass_payment_portal_failed", function (payload) {
			supporterPortalRequestPending = false;
			$.Msg("[XHSEndScreen] Supporter portal unavailable: " + (payload && payload.message || "unknown error"));
		});
		if (typeof XHSNameDisplay !== "undefined" && XHSNameDisplay.Subscribe) {
			XHSNameDisplay.Subscribe(RefreshIdentitySurfaces);
		}
		SetLoading(true);
		ScheduleEndScreenFallback();
		var initialData = GetEndGameData();
		RenderEndGameData(initialData);
	}

	return {
		Init: Init,
		OpenHallOfFame: OpenHallOfFame,
		CloseHallOfFame: CloseHallOfFame,
	};
})();

(function () {
	$.Schedule(0.0, XHSEndScreen.Init);
})();
