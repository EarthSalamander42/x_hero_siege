(function () {
	"use strict";

	var NET_TABLE = "xhs_farm_leaderboard";
	var NET_KEY = "state";
	var ROW_HEIGHT = 50;
	var ROW_GAP = 4;
	var ROW_STRIDE = ROW_HEIGHT + ROW_GAP;
	var ROWS_VERTICAL_PADDING = 8;
	var cards = {};
	var layerApplied = false;
	var moveToken = 0;
	var lastPhase = "";
	var archiveExpanded = false;
	var leaderboardCollapsed = false;
	var leaderboardHidden = false;
	var leaderboardArchived = false;
	var leaderboardPlayerCount = 0;
	var leaderboardWasActive = false;

	function Panel(id) {
		return $("#" + id);
	}

	function ToNumber(value, fallbackValue) {
		var number = Number(value);
		return number === number && number !== Infinity && number !== -Infinity ? number : fallbackValue;
	}

	function IsTruthy(value) {
		return value === true || value === 1 || value === "1" || value === "true";
	}

	function TableToArray(table) {
		var values = [];
		if (!table) {
			return values;
		}

		for (var index = 1; table[index.toString()] !== undefined; index++) {
			values.push(table[index.toString()]);
		}

		return values;
	}

	function GetHudAncestor(panel) {
		var current = panel;
		while (current) {
			if (current.id === "Hud") {
				return current;
			}
			current = current.GetParent();
		}
		return null;
	}

	function GetHudDirectChild(panel, hud) {
		var current = panel;
		var parent = current && current.GetParent ? current.GetParent() : null;
		while (current && parent && parent !== hud) {
			current = parent;
			parent = current.GetParent ? current.GetParent() : null;
		}
		return parent === hud ? current : null;
	}

	function EnsureBelowShop() {
		if (layerApplied) {
			return;
		}

		var host = $.GetContextPanel();
		var shop = null;
		try {
			shop = typeof FindDotaHudElement === "function" ? FindDotaHudElement("shop") : null;
		} catch (error) {
			shop = null;
		}

		if (!host || !shop) {
			$.Schedule(0.5, EnsureBelowShop);
			return;
		}

		var hud = GetHudAncestor(host) || GetHudAncestor(shop);
		var hostChild = GetHudDirectChild(host, hud);
		var shopChild = GetHudDirectChild(shop, hud);
		if (!hud || !hostChild || !shopChild || hostChild === shopChild || typeof hud.MoveChildBefore !== "function") {
			$.Schedule(0.5, EnsureBelowShop);
			return;
		}

		try {
			hud.MoveChildBefore(hostChild, shopChild);
			layerApplied = true;
		} catch (error) {
			$.Schedule(0.5, EnsureBelowShop);
		}
	}

	function GetPlayerName(playerID) {
		var name = "";
		try {
			name = Players.GetPlayerName(playerID) || "";
		} catch (error) {
			name = "";
		}
		return name || ("Player " + (playerID + 1));
	}

	function GetPlayerHero(playerID) {
		try {
			return Players.GetPlayerSelectedHero(playerID) || "";
		} catch (error) {
			return "";
		}
	}

	function GetPlayerIdentity(playerID, heroName) {
		if (typeof XHSNameDisplay !== "undefined" && XHSNameDisplay.Resolve) {
			return XHSNameDisplay.Resolve({
				playerID: playerID,
				playerName: GetPlayerName(playerID),
				heroName: heroName,
			});
		}

		// Privacy-safe fallback: a missing helper must not expose a persona name.
		if (!heroName) {
			return "";
		}
		var localized = $.Localize("#" + heroName);
		return localized && localized !== ("#" + heroName) ? localized : heroName.replace(/^npc_dota_hero_/, "").replace(/_/g, " ").toUpperCase();
	}

	function IsPlayerDisconnected(playerID) {
		try {
			var info = Game.GetPlayerInfo(playerID);
			if (!info) {
				return false;
			}

			var state = info.player_connection_state;
			var disconnected = typeof DOTAConnectionState_t !== "undefined"
				? DOTAConnectionState_t.DOTA_CONNECTION_STATE_DISCONNECTED
				: 4;
			var abandoned = typeof DOTAConnectionState_t !== "undefined"
				? DOTAConnectionState_t.DOTA_CONNECTION_STATE_ABANDONED
				: 5;
			return state === disconnected || state === abandoned;
		} catch (error) {
			return false;
		}
	}

	function CreateCard(playerID) {
		var rows = Panel("XHSFarmLeaderboardRows");
		var card = $.CreatePanel("Panel", rows, "XHSFarmLeaderboardPlayer_" + playerID);
		card.AddClass("XHSFarmLeaderboardRow");
		card.SetAttributeInt("player_id", playerID);
		card.SetAttributeInt("rank", 0);
		card.SetAttributeInt("move_token", 0);

		var accent = $.CreatePanel("Panel", card, "");
		accent.AddClass("XHSFarmRowAccent");

		var rank = $.CreatePanel("Label", card, "XHSFarmRank_" + playerID);
		rank.AddClass("XHSFarmRank");
		rank.text = "-";

		var heroFrame = $.CreatePanel("Panel", card, "");
		heroFrame.AddClass("XHSFarmHeroFrame");

		var heroImage = $.CreatePanel("DOTAHeroImage", heroFrame, "XHSFarmHero_" + playerID);
		heroImage.AddClass("XHSFarmHeroImage");
		heroImage.heroimagestyle = "landscape";
		heroImage.scaling = "stretch-to-cover-preserve-aspect";
		heroImage.hittest = false;

		var identity = $.CreatePanel("Panel", card, "");
		identity.AddClass("XHSFarmIdentity");

		var playerName = $.CreatePanel("Label", identity, "XHSFarmPlayerName_" + playerID);
		playerName.AddClass("XHSFarmPlayerName");

		var stage = $.CreatePanel("Label", identity, "XHSFarmPlayerStage_" + playerID);
		stage.AddClass("XHSFarmPlayerStage");

		var progress = $.CreatePanel("Panel", card, "");
		progress.AddClass("XHSFarmProgress");

		var kills = $.CreatePanel("Label", progress, "XHSFarmKills_" + playerID);
		kills.AddClass("XHSFarmKills");
		kills.text = "0";

		var suffix = $.CreatePanel("Label", progress, "");
		suffix.AddClass("XHSFarmKillsSuffix");
		suffix.text = "KILLS";

		var delta = $.CreatePanel("Label", card, "XHSFarmRankDelta_" + playerID);
		delta.AddClass("XHSFarmRankDelta");

		$.Schedule(0.01, function () {
			if (card && card.IsValid && card.IsValid()) {
				card.AddClass("IsPresent");
			}
		});

		cards[playerID] = card;
		return card;
	}

	function EndMoveAnimation(card, token, rank) {
		$.Schedule(0.5, function () {
			if (!card || !card.IsValid || !card.IsValid() || card.GetAttributeInt("move_token", -1) !== token) {
				return;
			}

			card.RemoveClass("IsReordering");
			card.RemoveClass("IsMovingUp");
			card.style.zIndex = String(120 - rank);

			var playerID = card.GetAttributeInt("player_id", -1);
			var delta = Panel("XHSFarmRankDelta_" + playerID);
			if (delta) {
				delta.RemoveClass("IsVisible");
				delta.RemoveClass("IsDown");
			}
		});
	}

	function PositionCard(card, rank) {
		var previousRank = card.GetAttributeInt("rank", 0);
		var targetY = (rank - 1) * ROW_STRIDE;
		card.style.transform = "translateY( " + targetY + "px )";
		card.SetAttributeInt("rank", rank);

		if (previousRank > 0 && previousRank !== rank) {
			moveToken++;
			var token = moveToken;
			var movedUp = rank < previousRank;
			var delta = Panel("XHSFarmRankDelta_" + card.GetAttributeInt("player_id", -1));

			card.SetAttributeInt("move_token", token);
			card.AddClass("IsReordering");
			card.SetHasClass("IsMovingUp", movedUp);
			card.style.zIndex = movedUp ? "320" : "240";

			if (delta) {
				delta.text = (movedUp ? "\u25B2 " : "\u25BC ") + Math.abs(previousRank - rank);
				delta.SetHasClass("IsDown", !movedUp);
				delta.AddClass("IsVisible");
			}

			EndMoveAnimation(card, token, rank);
		} else {
			card.style.zIndex = String(120 - rank);
		}
	}

	function UpdateCard(card, player, rank, localPlayerID, mode, targetKills) {
		var playerID = ToNumber(player.player_id, -1);
		var level = Math.max(1, ToNumber(player.level, 1));
		var wave = Math.max(1, ToNumber(player.wave, 1));
		var wavesPerLevel = Math.max(1, ToNumber(player.waves_per_level, 1));
		var kills = Math.max(0, ToNumber(player.kills, 0));
		var supporterXP = Math.max(0, ToNumber(player.supporter_xp_earned, 0));
		var remaining = Math.max(0, ToNumber(player.remaining, targetKills - kills));

		var rankLabel = Panel("XHSFarmRank_" + playerID);
		var heroImage = Panel("XHSFarmHero_" + playerID);
		var nameLabel = Panel("XHSFarmPlayerName_" + playerID);
		var stageLabel = Panel("XHSFarmPlayerStage_" + playerID);
		var killsLabel = Panel("XHSFarmKills_" + playerID);

		if (rankLabel) {
			rankLabel.text = String(rank);
		}
		var heroName = GetPlayerHero(playerID);
		if (heroImage) {
			heroImage.heroname = heroName;
		}
		if (nameLabel) {
			nameLabel.text = GetPlayerIdentity(playerID, heroName);
		}
		if (stageLabel) {
			stageLabel.text = mode === "ramero_kill_race"
				? (remaining > 0 ? "+" + remaining + " KILLS REMAINING" : "ARENA READY")
				: "LEVEL " + level + "  \u00B7  WAVE " + wave + "/" + wavesPerLevel + "  \u00B7  +" + supporterXP + " XP";
		}
		if (killsLabel) {
			killsLabel.text = String(kills);
		}

		card.SetHasClass("IsLeader", rank === 1);
		card.SetHasClass("IsLocalPlayer", playerID === localPlayerID);
		card.SetHasClass("IsDisconnected", IsPlayerDisconnected(playerID));
		PositionCard(card, rank);
	}

	function RemoveMissingCards(activePlayerIDs) {
		for (var key in cards) {
			if (!cards.hasOwnProperty(key) || activePlayerIDs[key]) {
				continue;
			}

			var card = cards[key];
			delete cards[key];
			if (card && card.IsValid && card.IsValid()) {
				card.RemoveClass("IsPresent");
				card.DeleteAsync(0.2);
			}
		}
	}

	function SortPlayers(players) {
		players.sort(function (a, b) {
			var rankA = ToNumber(a.rank, 999);
			var rankB = ToNumber(b.rank, 999);
			if (rankA !== rankB) {
				return rankA - rankB;
			}

			var killsA = ToNumber(a.kills, 0);
			var killsB = ToNumber(b.kills, 0);
			if (killsA !== killsB) {
				return killsB - killsA;
			}

			return ToNumber(a.player_id, 0) - ToNumber(b.player_id, 0);
		});
	}

	function FindPlayer(players, playerID) {
		for (var index = 0; index < players.length; index++) {
			if (ToNumber(players[index].player_id, -1) === playerID) {
				return players[index];
			}
		}
		return players.length > 0 ? players[0] : null;
	}

	function SetArchiveExpanded(expanded) {
		archiveExpanded = expanded === true;
		var leaderboard = Panel("XHSFarmLeaderboard");
		var toggle = Panel("XHSFarmLeaderboardToggle");
		var toggleLabel = Panel("XHSFarmLeaderboardToggleLabel");
		if (leaderboard) {
			leaderboard.SetHasClass("IsVisible", archiveExpanded);
			leaderboard.SetHasClass("IsReopened", archiveExpanded);
		}
		if (toggle) {
			toggle.SetHasClass("IsExpanded", archiveExpanded && !leaderboardHidden);
		}
		if (toggleLabel) {
			toggleLabel.text = archiveExpanded && !leaderboardHidden ? "\u203A" : "\u2039";
		}
		RefreshExternalToggle();
	}

	function RefreshExternalToggle() {
		var toggle = Panel("XHSFarmLeaderboardToggle");
		if (toggle) {
			toggle.SetHasClass("IsVisible", leaderboardHidden || (leaderboardArchived && !archiveExpanded));
		}
	}

	function UpdateRowsHeight() {
		var rows = Panel("XHSFarmLeaderboardRows");
		if (rows) {
			rows.style.height = leaderboardCollapsed
				? "50px"
				: String(Math.max(64, leaderboardPlayerCount * ROW_STRIDE + ROWS_VERTICAL_PADDING)) + "px";
		}
	}

	function SetLeaderboardHidden(hidden) {
		leaderboardHidden = hidden === true;
		var leaderboard = Panel("XHSFarmLeaderboard");
		var toggle = Panel("XHSFarmLeaderboardToggle");
		var toggleLabel = Panel("XHSFarmLeaderboardToggleLabel");
		if (leaderboard) {
			leaderboard.SetHasClass("IsFullyHidden", leaderboardHidden);
		}
		if (toggle) {
			toggle.SetHasClass("IsExpanded", false);
		}
		if (toggleLabel && leaderboardHidden) {
			toggleLabel.text = "\u2039";
		}
		RefreshExternalToggle();
	}

	function SetLeaderboardCollapsed(collapsed) {
		leaderboardCollapsed = collapsed === true;
		var leaderboard = Panel("XHSFarmLeaderboard");
		var collapseButton = Panel("XHSFarmLeaderboardCollapse");
		var collapseLabel = Panel("XHSFarmLeaderboardCollapseLabel");
		if (leaderboard) {
			leaderboard.SetHasClass("IsCollapsed", leaderboardCollapsed);
		}
		if (collapseButton) {
			collapseButton.SetHasClass("IsCollapsed", leaderboardCollapsed);
		}
		if (collapseLabel) {
			collapseLabel.text = leaderboardCollapsed ? "\u25BC" : "\u25B2";
		}
		UpdateRowsHeight();
	}

	function UpdateCelebration(data, players, phase) {
		var leaderboard = Panel("XHSFarmLeaderboard");
		var eyebrow = Panel("XHSFarmLeaderboardEyebrow");
		var title = Panel("XHSFarmLeaderboardTitle");
		var status = Panel("XHSFarmLeaderboardStatus");
		var winnerName = Panel("XHSFarmWinnerName");
		var winnerScore = Panel("XHSFarmWinnerScore");
		var celebrating = phase === "celebration";
		var killRace = (data.mode || "").toString() === "ramero_kill_race";
		var targetKills = Math.max(1, ToNumber(data.target_kills, 300));

		if (leaderboard) {
			leaderboard.SetHasClass("IsCelebrating", celebrating);
			leaderboard.SetHasClass("IsKillRace", killRace);
		}
		if (eyebrow) {
			eyebrow.text = killRace ? "RAMERO & BARISTOL" : "FARM EVENT";
		}
		if (title) {
			title.text = killRace ? "KILL PROGRESS" : (celebrating ? "FINAL RESULTS" : "LIVE LEADERBOARD");
		}
		if (status) {
			status.text = killRace ? "TO " + targetKills : (celebrating ? "FINAL" : "LIVE");
		}

		if (celebrating) {
			var winner = FindPlayer(players, ToNumber(data.winner_player_id, -1));
			if (winnerName) {
				var winnerID = winner ? ToNumber(winner.player_id, -1) : -1;
				winnerName.text = winnerID >= 0
					? GetPlayerIdentity(winnerID, GetPlayerHero(winnerID))
					: "NO WINNER";
			}
			if (winnerScore) {
				winnerScore.text = FormatFarmWinnerScore(winner);
			}
			if (lastPhase !== "celebration") {
				Game.EmitSound("ui.trophy_levelup");
			}
		}
	}

	function FormatFarmWinnerScore(winner) {
		if (!winner) {
			return "0 KILLS";
		}
		return Math.max(0, ToNumber(winner.kills, 0)) + " KILLS  \u00B7  LEVEL " +
			Math.max(1, ToNumber(winner.level, 1));
	}

	function RenderState(data) {
		data = data || {};
		var leaderboard = Panel("XHSFarmLeaderboard");
		var rows = Panel("XHSFarmLeaderboardRows");
		if (!leaderboard || !rows) {
			return;
		}

		var active = IsTruthy(data.active);
		var available = IsTruthy(data.available);
		var phase = (data.phase || (active ? "active" : "archived")).toString();
		var archived = available && !active;
		leaderboardArchived = archived;

		leaderboard.SetHasClass("IsArchived", archived);
		RefreshExternalToggle();
		if (!active && !available) {
			leaderboard.SetHasClass("IsVisible", false);
			SetLeaderboardHidden(false);
			leaderboardWasActive = false;
			return;
		}
		if (active) {
			if (!leaderboardWasActive) {
				SetLeaderboardCollapsed(false);
				SetLeaderboardHidden(false);
			}
			archiveExpanded = false;
			leaderboard.SetHasClass("IsVisible", true);
			leaderboard.SetHasClass("IsReopened", false);
		} else {
			if (leaderboardWasActive) {
				SetLeaderboardCollapsed(false);
				SetLeaderboardHidden(false);
			}
			SetArchiveExpanded(archiveExpanded);
		}

		var players = TableToArray(data.players);
		SortPlayers(players);
		UpdateCelebration(data, players, phase);
		var mode = (data.mode || "farm_event").toString();
		var targetKills = Math.max(1, ToNumber(data.target_kills, 300));
		var activePlayerIDs = {};
		var localPlayerID = Players.GetLocalPlayer();

		for (var index = 0; index < players.length; index++) {
			var player = players[index] || {};
			var playerID = ToNumber(player.player_id, -1);
			if (playerID < 0) {
				continue;
			}

			var rank = index + 1;
			activePlayerIDs[playerID.toString()] = true;
			var card = cards[playerID] || CreateCard(playerID);
			UpdateCard(card, player, rank, localPlayerID, mode, targetKills);
		}

		RemoveMissingCards(activePlayerIDs);
		leaderboardPlayerCount = players.length;
		rows.SetHasClass("IsWaiting", players.length === 0);
		UpdateRowsHeight();
		lastPhase = phase;
		leaderboardWasActive = active;
	}

	function OnNetTableChanged(tableName, key, data) {
		if (tableName === NET_TABLE && key === NET_KEY) {
			RenderState(data);
		}
	}

	function Initialize() {
		EnsureBelowShop();
		var toggle = Panel("XHSFarmLeaderboardToggle");
		if (toggle) {
			toggle.SetPanelEvent("onactivate", function () {
				if (leaderboardHidden) {
					SetLeaderboardHidden(false);
				} else {
					SetArchiveExpanded(!archiveExpanded);
				}
				Game.EmitSound("ui_generic_button_click");
			});
		}
		var headerToggle = Panel("XHSFarmLeaderboardHeaderToggle");
		if (headerToggle) {
			headerToggle.SetPanelEvent("onactivate", function () {
				SetLeaderboardCollapsed(!leaderboardCollapsed);
				Game.EmitSound("ui_generic_button_click");
			});
		}
		var hideButton = Panel("XHSFarmLeaderboardHide");
		if (hideButton) {
			hideButton.SetPanelEvent("onactivate", function () {
				SetLeaderboardHidden(true);
				Game.EmitSound("ui_generic_button_click");
			});
		}
		SetLeaderboardCollapsed(false);
		CustomNetTables.SubscribeNetTableListener(NET_TABLE, OnNetTableChanged);
		RenderState(CustomNetTables.GetTableValue(NET_TABLE, NET_KEY));
		if (typeof XHSNameDisplay !== "undefined" && XHSNameDisplay.Subscribe) {
			XHSNameDisplay.Subscribe(function () {
				RenderState(CustomNetTables.GetTableValue(NET_TABLE, NET_KEY));
			});
		}
	}

	Initialize();
})();
