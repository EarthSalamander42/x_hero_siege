"use strict";

var XHSEndScreen = (function () {
	var WEBSITE_URL = "https://mods.frostrose-studio.com";
	var DISCORD_URL = "https://discord.frostrose-studio.com/";

	var TEAM_NAMES = {
		2: "#DOTA_GoodGuys",
		3: "#DOTA_BadGuys",
		6: "#DOTA_Custom1",
		7: "#DOTA_Custom2",
		8: "#DOTA_Custom3",
		9: "#DOTA_Custom4",
		10: "#DOTA_Custom5",
		11: "#DOTA_Custom6",
		12: "#DOTA_Custom7",
		13: "#DOTA_Custom8",
	};

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

	function Clamp(value, minValue, maxValue) {
		return Math.max(minValue, Math.min(maxValue, value));
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

	function BuildPlayerModel(data, playerID) {
		var info = Safe(function () {
			return Game.GetPlayerInfo(playerID);
		}, null);

		var steamID = info && info.player_steamid ? info.player_steamid.toString() : playerID.toString();
		var server = FindServerPlayer(data, steamID, playerID) || {};
		var api = FindApiPlayer(data, steamID) || {};
		var battlepass = GetBattlepassTable(playerID);
		var heroName = server.hero || (info && info.player_selected_hero) || "";
		var team = ToNumber(server.team, info ? info.player_team_id : 0);

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
			healing: ToNumber(server.healing, 0),
			potionsUsed: ToNumber(server.potions_used, 0),
			tomeStatsBonus: ToNumber(server.tome_stats_bonus, 0),
			tomesSmall: ToNumber(server.tomes_bought_small, 0),
			tomesBig: ToNumber(server.tomes_bought_big, 0),
			tomesPower: ToNumber(server.tomes_bought_power, 0),
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

	function GetTeamName(teamID) {
		var detailsName = Safe(function () {
			return Game.GetTeamDetails(teamID).team_name;
		}, null);

		if (detailsName) {
			return Localize(detailsName);
		}

		return Localize(TEAM_NAMES[teamID] || ("Team " + teamID));
	}

	function GetDifficultyName(data) {
		var tableValue = CustomNetTables.GetTableValue("game_options", "difficulty");
		var value = data.difficulty || (tableValue && tableValue["1"]);
		var difficulty = ToNumber(value, 0);
		return DIFFICULTY_NAMES[difficulty] || (difficulty > 0 ? "Difficulty " + difficulty : "-");
	}

	function AddSummaryTile(parent, label, value) {
		var tile = $.CreatePanel("Panel", parent, "");
		tile.AddClass("XHSSummaryTile");

		var labelPanel = $.CreatePanel("Label", tile, "");
		labelPanel.AddClass("XHSSummaryLabel");
		labelPanel.text = label;

		var valuePanel = $.CreatePanel("Label", tile, "");
		valuePanel.AddClass("XHSSummaryValue");
		valuePanel.text = value;
	}

	function RenderHeader(data) {
		var winnerTeam = GetWinnerTeam(data);
		var result = Panel("XHSEndScreenResult");
		var winnerName = winnerTeam ? GetTeamName(winnerTeam) : "Unknown";
		var isXHeroesVictory = winnerTeam === 2 || winnerTeam === 6;

		if (result) {
			result.text = winnerName + " Victory";
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
			var mapName = data.map || "XHS";
			var gameMode = data.gamemode || data.game_type || "-";
			mode.text = mapName + " / " + gameMode;
		}

		var gameID = Panel("XHSEndScreenGameId");
		if (gameID) {
			gameID.text = ((data.info && data.info.id) || data.game_id || "-").toString();
		}
	}

	function RenderSummary(data, players) {
		var parent = Panel("XHSEndScreenRunSummary");
		ClearPanel(parent);

		if (!parent) {
			return;
		}

		var winnerTeam = GetWinnerTeam(data);
		AddSummaryTile(parent, "Winner", winnerTeam ? GetTeamName(winnerTeam) : "-");
		AddSummaryTile(parent, "Run Time", FormatTime(data.game_time || Safe(function () { return Game.GetDOTATime(false, false); }, 0)));
		AddSummaryTile(parent, "Players", players.length.toString());
		AddSummaryTile(parent, "Mode", (data.game_type || "XHS") + " / " + (data.gamemode || "-"));

		if (data.rosh_lvl !== undefined && data.rosh_lvl !== null) {
			AddSummaryTile(parent, "Roshan", "Lvl " + data.rosh_lvl + " - " + FormatNumber(data.rosh_hp) + "/" + FormatNumber(data.rosh_max_hp));
		}
	}

	function CreateMvpCard(parent, title, model, value, formatter, valueClassName) {
		var card = $.CreatePanel("Panel", parent, "");
		card.AddClass("XHSMvpCard");

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

		CreateMvpCard(parent, "Most Kills", kills.model, kills.value, FormatNumber, "MvpKills");
		CreateMvpCard(parent, "Richest Hero", networth.model, networth.value, FormatNumber, "MvpGold");
		CreateMvpCard(parent, "Most Tome Stats", tomes.model, tomes.value, function (value) { return "+" + FormatNumber(value); }, "MvpStats");
		CreateMvpCard(parent, "Most Potions Used", potions.model, potions.value, FormatNumber, "MvpPotions");
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

		var battlepass = model.battlepass || {};
		var xpEnabled = battlepass.player_xp === 1 || battlepass.player_xp === "1";
		var xpCurrent = ToNumber(battlepass.XP, 0);
		var xpMax = Math.max(ToNumber(battlepass.MaxXP, 500), 1);
		var xpChange = ToNumber(model.api && model.api.xp_change, 0);

		if (!xpEnabled) {
			level.text = "N/A";
			earned.text = "N/A";
			progressPanel.style.width = "0%";
			diffPanel.style.width = "0%";
			return;
		}

		var passLevel = Math.max(1, ToNumber(battlepass.Lvl, 1));
		var levelText = "Level " + passLevel;
		if (battlepass.title) {
			levelText += " - " + battlepass.title;
			level.style.color = battlepass.title_color || "#dceeff";
		}

		level.text = levelText;
		earned.text = xpChange > 0 ? "+" + FormatNumber(xpChange) : FormatNumber(xpChange);
		earned.SetHasClass("IsNegative", xpChange < 0);

		var progress = Clamp(Math.floor((xpCurrent / xpMax) * 100), 0, 100);
		var diff = Clamp(Math.floor((xpChange / xpMax) * 100), 0, 100);
		progressPanel.style.width = progress + "%";
		diffPanel.style.width = diff + "%";
		diffPanel.style.marginLeft = Math.max(0, progress - 1) + "%";

		var levelUps = Math.floor((xpCurrent + xpChange) / xpMax);
		bar.SetHasClass("LevelUp", xpChange > 0 && levelUps >= 1);

		if (model.id === Players.GetLocalPlayer() && xpChange > 0 && levelUps >= 1) {
			for (var i = 1; i <= levelUps; i++) {
				CreateBattlepassRewardPanel(passLevel + i, i);
			}
		}
	}

	function CreatePlayerRow(parent, model) {
		var row = $.CreatePanel("Panel", parent, "XHSEndScreenPlayerRow_" + model.id);
		row.AddClass("XHSEndScreenPlayerRow");
		row.SetHasClass("IsAbandoned", model.abandon);

		var identity = $.CreatePanel("Panel", row, "");
		identity.AddClass("XHSPlayerIdentity");

		var heroImage = $.CreatePanel("DOTAHeroImage", identity, "");
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
		RenderSummary(data, players);
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
