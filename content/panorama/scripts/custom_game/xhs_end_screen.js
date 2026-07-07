"use strict";

var XHSEndScreen = (function () {
	var WEBSITE_URL = "https://mods.frostrose-studio.com";
	var DISCORD_URL = "https://discord.frostrose-studio.com/";
	var SUPPORTER_URL = "https://www.patreon.com/bePatron?u=2533325";
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

	function FinishGame() {
		if (Game && Game.FinishGame) {
			Game.FinishGame();
		}
	}

	function ClearPanel(panel) {
		if (panel) {
			panel.RemoveAndDeleteChildren();
		}
	}

	function GetEndGameData() {
		var data = CustomNetTables.GetTableValue("game_options", "end_game");

		if (data) {
			return data;
		}

		var fallbackPlayers = {};
		for (var playerID = 0; playerID < 24; playerID++) {
			var info = Safe(function () {
				return Game.GetPlayerInfo(playerID);
			}, null);

			if (info) {
				fallbackPlayers[info.player_steamid || playerID.toString()] = {
					id: playerID,
					kills: info.player_kills,
					deaths: info.player_deaths,
					assists: info.player_assists,
					level: info.player_level,
					team: info.player_team_id,
					hero: info.player_selected_hero,
					networth: info.player_gold,
				};
			}
		}

		return {
			players: fallbackPlayers,
			data: { players: {} },
			info: {},
			game_time: Safe(function () { return Game.GetDOTATime(false, false); }, 0),
		};
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
		var players = data.players || {};

		for (var steamID in players) {
			if (players.hasOwnProperty(steamID) && players[steamID] && players[steamID].id !== undefined) {
				ids[players[steamID].id] = true;
			}
		}

		for (var playerID = 0; playerID < 24; playerID++) {
			var info = Safe(function () {
				return Game.GetPlayerInfo(playerID);
			}, null);

			if (info || ids[playerID]) {
				ordered.push(playerID);
			}
		}

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
		var season = supporterPass.season || {};

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

		if (seasonLevel !== undefined) {
			merged.season_level = seasonLevel;
			merged.Lvl = seasonLevel;
		}
		if (seasonXP !== undefined) {
			merged.season_xp = seasonXP;
			merged.XP = seasonXP;
		}
		if (seasonMax !== undefined) {
			merged.season_xp_max = seasonMax;
			merged.MaxXP = seasonMax;
		}
		if (seasonChange !== undefined) {
			merged.season_xp_change = seasonChange;
			merged.XP_change = seasonChange;
		}

		merged.title = merged.title || "Supporter Pass";
		return merged;
	}

	function BuildPlayerModel(data, playerID) {
		var info = Safe(function () {
			return Game.GetPlayerInfo(playerID);
		}, null);

		var steamID = info && info.player_steamid ? info.player_steamid.toString() : playerID.toString();
		var server = FindServerPlayer(data, steamID, playerID) || {};
		var api = FindApiPlayer(data, steamID) || {};
		var battlepass = MergeCompletedSupporterPass(GetBattlepassTable(playerID), api);
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
			supportGold: ToNumber(server.gold_spent_on_support, 0),
			abandon: !!server.abandon,
			api: api,
			battlepass: battlepass,
		};
	}

	function BuildPlayerModels(data) {
		var playerIDs = GetPlayerIDsFromData(data);
		var models = [];

		for (var i = 0; i < playerIDs.length; i++) {
			models.push(BuildPlayerModel(data, playerIDs[i]));
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

	function GetGameModeValue(data) {
		var tableValue = CustomNetTables.GetTableValue("game_options", "gamemode");
		return data.gamemode
			|| (data.info && data.info.gamemode)
			|| (data.data && data.data.gamemode)
			|| (tableValue && tableValue["1"])
			|| null;
	}

	function GetGameModeName(data) {
		var gameMode = ToNumber(GetGameModeValue(data), 0);
		if (gameMode > 0) {
			var token = "#vote_gamemode_" + gameMode;
			var localized = $.Localize(token);
			if (localized && localized !== token) {
				return localized;
			}
		}

		return gameMode > 0 ? "Mode " + gameMode : "-";
	}

	function GetGameId(data) {
		return (data.info && data.info.id)
			|| data.game_id
			|| (data.data && data.data.game_id)
			|| data.match_id
			|| (data.info && data.info.match_id)
			|| "-";
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

		var mode = Panel("XHSEndScreenMode");
		if (mode) {
			var gameType = data.game_type || (data.info && data.info.game_type) || "XHS";
			mode.text = gameType + " / " + GetGameModeName(data);
		}

		var gameID = Panel("XHSEndScreenGameId");
		if (gameID) {
			gameID.text = GetGameId(data).toString();
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
		name.text = model ? model.name : "N/A";

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
		var max = Math.max(ToNumber(battlepass.season_xp_max !== undefined ? battlepass.season_xp_max : battlepass.MaxXP, 500), 1);
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

	function CreateBattlepassCell(parent, model) {
		var cell = $.CreatePanel("Panel", parent, "");
		cell.AddClass("PlayerColBattlepass");
		cell.AddClass("XHSBattlepassCell");

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

		var battlepass = model.battlepass || {};
		var xpEnabled = battlepass.player_xp !== 0 && battlepass.player_xp !== "0" && battlepass.player_xp !== false;
		var supporter = NormalizeSupporterProgress(battlepass);
		var supporterChange = ToNumber(
			battlepass.XP_change !== undefined ? battlepass.XP_change
				: (battlepass.season_xp_change !== undefined ? battlepass.season_xp_change : 0),
			0
		);
		var xhsProgress = GetXHSAccountProgress(model.api, battlepass);

		if (!xpEnabled) {
			level.text = "N/A";
			earned.text = "N/A";
			progressPanel.style.width = "0%";
			diffPanel.style.width = "0%";
			accountLine.text = "XHS N/A";
			return;
		}

		var levelText = "Level " + supporter.level;
		if (battlepass.title) {
			levelText += " - " + battlepass.title;
			level.style.color = battlepass.title_color || "#dceeff";
		}

		level.text = levelText;
		earned.text = FormatSignedNumber(supporterChange);
		earned.SetHasClass("IsNegative", supporterChange < 0);
		accountLine.text = FormatXHSAccountProgress(xhsProgress);

		var progress = Clamp(Math.floor((supporter.xp / supporter.max) * 100), 0, 100);
		var diff = Clamp(Math.floor((supporterChange / supporter.max) * 100), 0, 100);
		progressPanel.style.width = progress + "%";
		diffPanel.style.width = diff + "%";
		diffPanel.style.marginLeft = Math.max(0, progress - 1) + "%";

		var tooltip = "Supporter Pass: Level " + supporter.level + " - " + FormatNumber(supporter.xp) + "/" + FormatNumber(supporter.max) + " XP";
		if (xhsProgress.hasData) {
			tooltip += "\n" + FormatXHSAccountProgress(xhsProgress);
		}
		cell.SetPanelEvent("onmouseover", function () {
			$.DispatchEvent("UIShowTextTooltip", cell, tooltip);
		});
		cell.SetPanelEvent("onmouseout", function () {
			$.DispatchEvent("UIHideTextTooltip", cell);
		});

		var levelUps = Math.floor((supporter.xp + supporterChange) / supporter.max);
		bar.SetHasClass("LevelUp", supporterChange > 0 && levelUps >= 1);

		if (model.id === Players.GetLocalPlayer() && supporterChange > 0 && levelUps >= 1) {
			for (var i = 1; i <= levelUps; i++) {
				CreateBattlepassRewardPanel(supporter.level + i, i);
			}
		}
	}

	function CreatePlayerRow(parent, model) {
		var row = $.CreatePanel("Panel", parent, "XHSEndScreenPlayerRow_" + model.id);
		row.AddClass("XHSEndScreenPlayerRow");
		row.SetHasClass("IsAbandoned", model.abandon);
		row.hittest = true;
		row.hittestchildren = true;

		var identity = $.CreatePanel("Panel", row, "");
		identity.AddClass("XHSPlayerIdentity");
		identity.hittest = true;

		var heroFrame = $.CreatePanel("Panel", identity, "");
		heroFrame.AddClass("XHSPlayerHeroFrame");
		heroFrame.style.boxShadow = "fill " + ColorWithAlpha(model.playerColor, "66") + " 0px 0px 8px 0px";

		var playerColor = $.CreatePanel("Panel", heroFrame, "");
		playerColor.AddClass("XHSPlayerColorStrip");
		playerColor.style.backgroundColor = model.playerColor;

		var heroImage = $.CreatePanel("DOTAHeroImage", heroFrame, "");
		heroImage.AddClass("XHSPlayerHeroImage");
		heroImage.heroimagestyle = "landscape";
		if (model.hero) {
			heroImage.heroname = model.hero;
		}

		var avatar = $.CreatePanel("DOTAAvatarImage", identity, "");
		avatar.AddClass("XHSPlayerAvatar");
		avatar.steamid = model.steamID;

		var text = $.CreatePanel("Panel", identity, "");
		text.AddClass("XHSPlayerText");

		var name = $.CreatePanel("Label", text, "");
		name.AddClass("XHSPlayerName");
		name.text = model.name;

		var heroName = $.CreatePanel("Label", text, "");
		heroName.AddClass("XHSPlayerHeroName");
		heroName.text = model.abandon ? model.heroLabel + " - Abandoned" : model.heroLabel;

		CreateCell(row, "PlayerColSmall", model.level.toString());
		CreateCell(row, "PlayerColKda", FormatNumber(model.kills), "XHSPlayerCellKills");
		CreateCell(row, "PlayerColNumber", FormatNumber(model.deaths));
		CreateCell(row, "PlayerColNumber", FormatNumber(model.networth), "XHSPlayerCellGold");
		CreateCell(row, "PlayerColNumber", "+" + FormatNumber(model.tomeStatsBonus), "XHSPlayerCellStats");
		CreateCell(row, "PlayerColNumber", FormatNumber(model.potionsUsed), "XHSPlayerCellPotions");
		CreateBattlepassCell(row, model);

		if (typeof XHSSupporterHover !== "undefined" && XHSSupporterHover.Create) {
			var hoverID = "End_" + model.id;
			var hoverRoot = Panel("XHSEndScreenMain") || row;
			var hover = XHSSupporterHover.Create(hoverRoot, hoverID, { className: "XHSEndScreenSupporterHover" });
			var showHover = function () {
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

			row.SetPanelEvent("onmouseover", showHover);
			row.SetPanelEvent("onmouseout", hideHover);
			identity.SetPanelEvent("onmouseover", showHover);
			identity.SetPanelEvent("onmouseout", hideHover);
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
			name.text = entry.name || entry.player_name || entry.steam_name || entry.steamid || entry.__key || "Unknown";

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

	function CreateBattlepassRewardPanel(level, levelupCount) {
		var battlepass = CustomNetTables.GetTableValue("supporter_pass_rewards_free", "rewards");
		if (battlepass && battlepass["1"]) {
			battlepass = battlepass["1"];
		}

		if (!battlepass || !battlepass[level]) {
			return;
		}

		var reward = battlepass[level];
		var rewardName = reward.name;
		var rarity = reward.rarity || "common";
		var rewardType = reward.type || "Reward";
		var container = Panel("XHSEndScreenRewardContainer");

		if (!container) {
			return;
		}

		var panel = $.CreatePanel("Panel", container, "XHSEndScreenRewardPanel_" + levelupCount);
		panel.AddClass("XHSEndScreenRewardPanel");
		panel.AddClass("level-" + rarity);

		var description = $.CreatePanel("Label", panel, "");
		description.AddClass("XHSRewardDescription");
		description.text = Localize("#battlepass_reward_description") + " " + level;

		var name = $.CreatePanel("Label", panel, "");
		name.AddClass("XHSRewardName");
		name.text = rewardType + ": " + Localize("#" + rewardName);

		var rarityPanel = $.CreatePanel("Label", panel, "");
		rarityPanel.AddClass("XHSRewardRarity");
		rarityPanel.AddClass(rarity);
		rarityPanel.text = rarity;

		var image = $.CreatePanel("Panel", panel, "");
		image.AddClass("XHSRewardImage");
		image.style.backgroundImage = 'url("file://{resources}/images/custom_game/battlepass/' + rewardName + '.png")';

		var button = $.CreatePanel("Button", panel, "");
		button.AddClass("XHSRewardButton");
		button.SetPanelEvent("onactivate", function () {
			panel.DeleteAsync(0);
		});

		var label = $.CreatePanel("Label", button, "");
		label.text = "Accept";

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
				OpenExternalURL(GetSupporterURL());
			});
		}

		var close = Panel("XHSEndScreenCloseButton");
		if (close) {
			close.SetPanelEvent("onactivate", FinishGame);
		}

		var hall = Panel("XHSEndScreenHallButton");
		if (hall) {
			hall.enabled = false;
		}

		var hallClose = Panel("XHSEndScreenHallCloseButton");
		if (hallClose) {
			hallClose.SetPanelEvent("onactivate", CloseHallOfFame);
		}
	}

	function Init() {
		HideVanillaHud();
		BindButtons();

		var data = GetEndGameData();
		var players = BuildPlayerModels(data);

		RenderHeader(data);
		RenderFragmentQuests(data);
		RenderMvpCards(players);
		RenderPlayers(players);
		RenderHallOfFame();
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
