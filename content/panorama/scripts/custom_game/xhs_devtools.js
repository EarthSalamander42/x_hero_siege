var XHSDevToolsState = {};
var XHSDevToolsActiveTab = "scenarios";
var XHSDevToolsHasServerState = false;
var XHSDevToolsCurrentTimescale = 1;
var XHSDevToolsCinematicPreviewId = "";
var XHSDevToolsBotConfig = {};
var XHSDevToolsBotRoster = { count: 0, players: {} };
var XHSDevToolsBotDebug = {};
var XHSDevToolsPerformance = {};
var XHSDevToolsPerformanceAccess = null;
var XHSDevToolsLagLab = {};
var XHSDevToolsLagLabPending = "";
var XHSDevToolsFPSFrames = 0;
var XHSDevToolsFPSWindowStartedAt = Date.now();
var XHSDevToolsFPSLastSentAt = 0;
var XHSDevToolsLocalFPS = -1;
var XHSDevToolsCompactHidden = false;
var XHSDevToolsOverheadFilter = "players";
var XHSDevToolsSpectatorLoopsStarted = false;
var XHSDevToolsSpectatorState = {
	currentPlayerID: -1,
	// Spectator mode is follow-first by default. Camera tracking is deliberately
	// client-only so team spectators never depend on a server camera target.
	following: true,
	lastFollowEntIndex: -1,
	lastInspectedEntIndex: -1,
	radiantFogApplied: false,
	radiantFogConfirmations: 0,
	cameraModeConfirmations: 0,
	wasVisible: false
};
var XHS_SPECTATOR_CAMERA_MODE_CHASE = 2;
var XHS_SPECTATOR_CAMERA_MODE_FREE = 1;
var XHSDevToolsPerformanceColumns = {
	client: true,
	server: true,
	activity: true,
	bots: true
};

var XHS_DEVTOOLS_PERFORMANCE_COLUMNS = {
	client: { panel: "#XHSPerfColumnClient", toggle: "#XHSPerfColumnToggleClient", label: "CLIENT", width: 208 },
	server: { panel: "#XHSPerfColumnServer", toggle: "#XHSPerfColumnToggleServer", label: "SERVER", width: 208 },
	activity: { panel: "#XHSPerfColumnActivity", toggle: "#XHSPerfColumnToggleActivity", label: "ACTIVITY", width: 235 },
	bots: { panel: "#XHSPerfColumnBots", toggle: "#XHSPerfColumnToggleBots", label: "BOTS", width: 205 }
};

var XHS_DEVTOOLS_TIMESCALES = [
	{ value: 0.1, label: "x0.1" },
	{ value: 0.3, label: "x0.3" },
	{ value: 1, label: "x1" },
	{ value: 3, label: "x3" },
	{ value: 5, label: "x5" }
];

var XHS_DEVTOOLS_TABS = [
	{ id: "scenarios", label: "Scenarios" },
	{ id: "bosses", label: "Bosses" },
	{ id: "lanes", label: "Lanes/Waves" },
	{ id: "timers", label: "Timers/Phase" },
	{ id: "bots", label: "Bots" },
	{ id: "lag_lab", label: "Lag Lab" },
	{ id: "players", label: "Player Tools" },
	{ id: "overhead", label: "Overhead PFX" },
	{ id: "ui", label: "UI Preview" },
	{ id: "battlepass", label: "Battle Pass" },
	{ id: "cleanup", label: "Cleanup" }
];

var XHS_DEVTOOLS_BOSSES = [
	{ id: "magtheridon", label: "Magtheridon", icon: "npc_dota_hero_abyssal_underlord" },
	{ id: "grom", label: "Grom", icon: "npc_dota_hero_juggernaut" },
	{ id: "illidan", label: "Illidan", icon: "npc_dota_hero_terrorblade" },
	{ id: "balanar", label: "Balanar", icon: "npc_dota_hero_pugna" },
	{ id: "proudmoore", label: "Proudmoore", icon: "npc_dota_hero_kunkka" },
	{ id: "arthas", label: "Arthas", icon: "npc_dota_hero_omniknight" },
	{ id: "banehallow", label: "Banehallow", icon: "npc_dota_hero_nevermore" },
	{ id: "lich_king", label: "Lich King", icon: "npc_dota_hero_abaddon" },
	{ id: "spirit_master", label: "Spirit Master", icon: "npc_dota_hero_brewmaster" }
];

var XHS_DEVTOOLS_BOSS_UNITS = {
	magtheridon: ["npc_dota_hero_magtheridon"],
	grom: ["npc_dota_hero_grom_hellscream"],
	illidan: ["npc_dota_hero_illidan"],
	balanar: ["npc_dota_hero_balanar"],
	proudmoore: ["npc_dota_hero_proudmoore"],
	arthas: ["npc_dota_hero_arthas"],
	banehallow: ["npc_dota_hero_banehallow"],
	lich_king: ["npc_dota_boss_lich_king"],
	spirit_master: [
		"npc_dota_boss_spirit_master",
		"npc_dota_boss_spirit_master_fire",
		"npc_dota_boss_spirit_master_storm",
		"npc_dota_boss_spirit_master_earth"
	]
};

var XHS_DEVTOOLS_DIFFICULTIES = [
	{ id: 1, label: "Easy" },
	{ id: 2, label: "Normal" },
	{ id: 3, label: "Hard" },
	{ id: 4, label: "Extreme" },
	{ id: 5, label: "Divine" }
];

var XHS_DEVTOOLS_DONATOR_STATUSES = [
	{ id: 0, label: "0 None" },
	{ id: 1, label: "1 Lead" },
	{ id: 2, label: "2 Dev" },
	{ id: 3, label: "3 Admin" },
	{ id: 4, label: "4 Ember" },
	{ id: 5, label: "5 Golden" },
	{ id: 6, label: "6 Donator" },
	{ id: 7, label: "7 Stone" },
	{ id: 8, label: "8 Earth" },
	{ id: 9, label: "9 Legacy" },
	{ id: 10, label: "10 Hidden" }
];

function XHSDevToolsPanel() {
	return $("#XHSDevToolsPanel");
}

function XHSDevToolsIsToolsMode() {
	return typeof Game.IsInToolsMode === "function" && Game.IsInToolsMode();
}

function XHSDevToolsGetLocalDonatorStatus() {
	if (typeof CustomNetTables === "undefined" || !CustomNetTables) {
		return 0;
	}

	var playerInfo = Game.GetPlayerInfo(Game.GetLocalPlayerID());
	var steamID = playerInfo && playerInfo.player_steamid !== undefined
		? String(playerInfo.player_steamid)
		: "";
	if (!steamID) {
		return 0;
	}

	var donators = CustomNetTables.GetTableValue("game_options", "donators") || {};
	for (var key in donators) {
		var entry = donators[key];
		var entrySteamID = String(key);
		var status = entry;
		if (entry && typeof entry === "object") {
			entrySteamID = entry.steamid !== undefined ? String(entry.steamid) : entrySteamID;
			status = entry.status !== undefined ? entry.status : entry.donator_status;
		}
		if (entrySteamID === steamID) {
			return Math.floor(XHSDevToolsPerformanceNumber(status));
		}
	}
	return 0;
}

function XHSDevToolsCanViewPerformanceLog() {
	if (XHSDevToolsIsToolsMode()) {
		return true;
	}
	if (XHSDevToolsPerformanceAccess &&
		XHSDevToolsPerformanceAccess.allowed !== undefined) {
		return XHSDevToolsPerformanceAccess.allowed === true ||
			Number(XHSDevToolsPerformanceAccess.allowed) === 1;
	}
	var status = XHSDevToolsGetLocalDonatorStatus();
	return status === 1;
}

function XHSDevToolsMatchHasPerformanceViewer() {
	if (XHSDevToolsIsToolsMode()) {
		return true;
	}
	if (typeof CustomNetTables === "undefined" || !CustomNetTables) {
		return false;
	}

	var donators = CustomNetTables.GetTableValue("game_options", "donators") || {};
	for (var key in donators) {
		var entry = donators[key];
		var status = entry;
		if (entry && typeof entry === "object") {
			status = entry.status !== undefined ? entry.status : entry.donator_status;
		}
		status = Math.floor(XHSDevToolsPerformanceNumber(status));
		if (status === 1) {
			return true;
		}
	}
	return false;
}

function XHSDevToolsApplyAccess() {
	var root = $("#XHSDevToolsRoot");
	if (!root) {
		return;
	}

	var toolsMode = XHSDevToolsIsToolsMode();
	var canViewLog = XHSDevToolsCanViewPerformanceLog();
	var localSpectator = XHSDevToolsIsLocalSpectator();
	root.style.visibility = (canViewLog || localSpectator) ? "visible" : "collapse";
	root.SetHasClass("LogOnly", canViewLog && !toolsMode);
	root.SetHasClass("SpectatorOnly", localSpectator && !canViewLog && !toolsMode);

	if (!toolsMode) {
		var panel = XHSDevToolsPanel();
		if (panel) {
			panel.RemoveClass("Visible");
		}
		var timescale = $("#XHSDevToolsTimescale");
		if (timescale) {
			timescale.RemoveClass("Visible");
		}
	}

	if (canViewLog) {
		XHSDevToolsRenderPerformance();
	}
}

function XHSDevToolsSend(action, payload) {
	if (!XHSDevToolsState.enabled) {
		XHSDevToolsRenderStatus();
		return;
	}

	payload = payload || {};
	payload.action = action;
	GameEvents.SendCustomGameEventToServer("xhs_devtools_run_action", payload);
}

function XHSDevToolsGetCinematicApi() {
	var config = GameUI.CustomUIConfig();
	return config && config.XHSCinematics;
}

function XHSDevToolsBeginClientCinematic(options) {
	var api = XHSDevToolsGetCinematicApi();
	if (!api || typeof api.begin !== "function") {
		$.Msg("[XHS][DevTools][Cinematic] Client API is unavailable. Check custom_ui_manifest.xml and xhs_cinematic.js.");
		return;
	}

	options = options || {};
	XHSDevToolsCinematicPreviewId = String(options.id || "xhs_dev_client");
	options.id = XHSDevToolsCinematicPreviewId;
	$.Msg("[XHS][DevTools][Cinematic] Client begin: ", options);
	api.begin(options);
}

function XHSDevToolsEndClientCinematic() {
	var api = XHSDevToolsGetCinematicApi();
	if (!api || typeof api.end !== "function") {
		$.Msg("[XHS][DevTools][Cinematic] Client API is unavailable; cannot end preview.");
		return;
	}

	var id = XHSDevToolsCinematicPreviewId || "xhs_dev_client";
	$.Msg("[XHS][DevTools][Cinematic] Client end: ", id);
	api.end({ id: id });
	XHSDevToolsCinematicPreviewId = "";
}

function XHSDevToolsRequestState() {
	GameEvents.SendCustomGameEventToServer("xhs_devtools_request_state", {});
}

function XHSDevToolsRequestStateLoop() {
	XHSDevToolsRequestState();

	if (!XHSDevToolsHasServerState) {
		$.Schedule(1.0, XHSDevToolsRequestStateLoop);
	}
}

function XHSDevToolsApplyCompactHUDState() {
	var root = $("#XHSDevToolsRoot");
	var controls = $("#XHSDevToolsButtons");
	var performance = $("#XHSDevToolsPerformance");
	var label = $("#XHSDevToolsCompactToggleLabel");
	if (!root) {
		return;
	}

	root.SetHasClass("CompactHidden", XHSDevToolsCompactHidden);
	if (controls) {
		controls.hittestchildren = !XHSDevToolsCompactHidden;
	}
	if (performance) {
		performance.hittestchildren = !XHSDevToolsCompactHidden;
	}
	if (label) {
		label.text = XHSDevToolsCompactHidden ? "\u2039" : "\u203a";
	}
}

function XHSDevToolsToggleCompactHUD() {
	XHSDevToolsCompactHidden = !XHSDevToolsCompactHidden;

	if (XHSDevToolsCompactHidden) {
		var panel = XHSDevToolsPanel();
		if (panel) {
			panel.RemoveClass("Visible");
		}

		var performance = $("#XHSDevToolsPerformance");
		if (performance) {
			performance.RemoveClass("Expanded");
		}
		XHSDevToolsApplyPerformanceColumns();
	}

	XHSDevToolsApplyCompactHUDState();
}

function XHSDevToolsTogglePanel() {
	var panel = XHSDevToolsPanel();
	if (!panel) {
		return;
	}

	panel.SetHasClass("Visible", !panel.BHasClass("Visible"));
	if (panel.BHasClass("Visible")) {
		XHSDevToolsRequestState();
		XHSDevToolsReadBotNetTables();
		XHSDevToolsRender();
	}
}

function XHSDevToolsTogglePerformance() {
	var panel = $("#XHSDevToolsPerformance");
	if (!panel) {
		$.Msg("[XHS][DevTools][Performance] Panel not found.");
		return;
	}

	panel.SetHasClass("Expanded", !panel.BHasClass("Expanded"));
	XHSDevToolsApplyPerformanceColumns();
}

function XHSDevToolsApplyPerformanceColumns() {
	var performancePanel = $("#XHSDevToolsPerformance");
	if (!performancePanel) {
		return;
	}

	var visibleWidth = 14;
	for (var columnName in XHS_DEVTOOLS_PERFORMANCE_COLUMNS) {
		var definition = XHS_DEVTOOLS_PERFORMANCE_COLUMNS[columnName];
		var visible = XHSDevToolsPerformanceColumns[columnName] !== false;
		var column = $(definition.panel);
		var toggle = $(definition.toggle);
		if (column) {
			column.SetHasClass("ColumnHidden", !visible);
		}
		if (toggle) {
			toggle.SetHasClass("Active", visible);
			var toggleLabel = toggle.GetChild(0);
			if (toggleLabel) {
				toggleLabel.text = visible ? definition.label : ("+ " + definition.label);
			}
		}
		if (visible) {
			visibleWidth += definition.width;
		}
	}

	performancePanel.style.width = performancePanel.BHasClass("Expanded")
		? (Math.max(420, visibleWidth) + "px")
		: "342px";
}

function XHSDevToolsTogglePerformanceColumn(columnName) {
	if (!XHS_DEVTOOLS_PERFORMANCE_COLUMNS[columnName]) {
		return;
	}
	XHSDevToolsPerformanceColumns[columnName] =
		XHSDevToolsPerformanceColumns[columnName] === false;
	XHSDevToolsApplyPerformanceColumns();
}

function XHSDevToolsBindPerformanceToggle() {
	var header = $("#XHSDevToolsPerformanceHeader");
	if (!header) {
		$.Msg("[XHS][DevTools][Performance] Header not found.");
	} else {
		header.SetPanelEvent("onactivate", XHSDevToolsTogglePerformance);
	}

	for (var columnName in XHS_DEVTOOLS_PERFORMANCE_COLUMNS) {
		(function(boundColumnName) {
			var definition = XHS_DEVTOOLS_PERFORMANCE_COLUMNS[boundColumnName];
			var toggle = definition && $(definition.toggle);
			if (!toggle) {
				$.Msg("[XHS][DevTools][Performance] Column toggle not found: " + boundColumnName);
				return;
			}

			toggle.SetPanelEvent("onactivate", function() {
				XHSDevToolsTogglePerformanceColumn(boundColumnName);
			});
		})(columnName);
	}
}

function XHSDevToolsSetPerformanceText(id, value) {
	var label = $(id);
	if (label) {
		label.text = value;
	}
}

function XHSDevToolsPerformanceNumber(value) {
	var number = Number(value);
	return isNaN(number) ? 0 : number;
}

function XHSDevToolsSetPerformanceStatus(id, warning, critical) {
	var label = $(id);
	if (!label) {
		return;
	}
	label.SetHasClass("Warning", !!warning && !critical);
	label.SetHasClass("Critical", !!critical);
}

function XHSDevToolsPerformanceMilliseconds(value) {
	var milliseconds = XHSDevToolsPerformanceNumber(value);
	return milliseconds < 10 ? milliseconds.toFixed(2) : milliseconds.toFixed(1);
}

function XHSDevToolsSetCompactMetric(id, value, low, critical) {
	var label = $(id);
	if (!label) {
		return;
	}
	label.text = value;
	label.SetHasClass("Low", !!low && !critical);
	label.SetHasClass("Critical", !!critical);
}

function XHSDevToolsRenderCompactPerformance(data) {
	data = data || {};
	var simHealth = XHSDevToolsPerformanceNumber(data.sim_health_pct);
	var hasSimHealth = data.sim_health_pct !== undefined && data.sim_health_pct !== null &&
		!isNaN(Number(data.sim_health_pct));
	var creeps = XHSDevToolsPerformanceNumber(data.creeps);
	var simHealthLow = data.sim_health_low_pct === undefined ? -1 : XHSDevToolsPerformanceNumber(data.sim_health_low_pct);
	var creepsHigh = data.creeps_high === undefined ? -1 : XHSDevToolsPerformanceNumber(data.creeps_high);
	var localFPS = XHSDevToolsLocalFPS >= 0 ? Math.round(XHSDevToolsLocalFPS) : -1;

	XHSDevToolsSetCompactMetric(
		"#XHSDevToolsLocalFPS",
		localFPS >= 0 ? String(localFPS) : "--",
		localFPS >= 0 && localFPS < 50,
		localFPS >= 0 && localFPS < 30
	);
	XHSDevToolsSetCompactMetric(
		"#XHSDevToolsServerHealth",
		hasSimHealth ? Math.round(simHealth) + "%" : "--",
		hasSimHealth && simHealth < 90,
		hasSimHealth && simHealth < 70
	);
	XHSDevToolsSetCompactMetric(
		"#XHSDevToolsCreepCount",
		String(creeps),
		creeps >= 100,
		creeps >= 125
	);
	XHSDevToolsSetCompactMetric(
		"#XHSDevToolsServerHealthLow",
		simHealthLow >= 0 ? "LOW " + Math.round(simHealthLow) + "%" : "LOW --",
		simHealthLow >= 0 && simHealthLow < 90,
		simHealthLow >= 0 && simHealthLow < 70
	);
	XHSDevToolsSetCompactMetric(
		"#XHSDevToolsCreepCountHigh",
		creepsHigh >= 0 ? "HIGH " + String(creepsHigh) : "HIGH --",
		creepsHigh >= 100,
		creepsHigh >= 125
	);
}

function XHSDevToolsRenderBotPerformance() {
	var configuredCount = XHSDevToolsPerformanceNumber(XHSDevToolsBotConfig.bot_count);
	var rosterCount = XHSDevToolsPerformanceNumber(XHSDevToolsBotRoster.count);
	var debugCount = 0;
	var engineVerified = 0;
	var activeCount = 0;
	var idleCount = 0;
	var ordersPerSecond = 0;
	var rateLimitedOrders = 0;
	var castsIssued = 0;
	var castsRejected = 0;
	var decisionAverageTotal = 0;
	var decisionAverageCount = 0;
	var decisionMaximum = 0;
	var thinkAverage = 0;
	var thinkMaximum = 0;
	var baseThreatScore = 0;
	var baseThreatCount = 0;
	var dangerHits = 0;
	var stuckRecoveries = 0;
	var safeErrors = 0;
	var safeErrorStreak = 0;

	for (var playerID in (XHSDevToolsBotDebug || {})) {
		var debug = XHSDevToolsBotDebug[playerID];
		if (!debug) {
			continue;
		}

		debugCount += 1;
		if (XHSDevToolsPerformanceNumber(debug.engine_fake_client) === 1 &&
			XHSDevToolsPerformanceNumber(debug.engine_team_verified) === 1) {
			engineVerified += 1;
		}

		var state = String(debug.state || "").toUpperCase();
		var inactive = state === "DEAD" ||
			state === "SELECTING_HERO" ||
			state === "ENGINE_IDENTITY_ERROR" ||
			state === "UNSUPPORTED_HERO" ||
			state === "ERROR";
		if (!inactive) {
			activeCount += 1;
		}
		if (!inactive && XHSDevToolsPerformanceNumber(debug.idle_seconds) >= 3) {
			idleCount += 1;
		}

		ordersPerSecond += XHSDevToolsPerformanceNumber(debug.orders_per_second);
		rateLimitedOrders += XHSDevToolsPerformanceNumber(debug.rate_limited_orders);
		castsIssued += XHSDevToolsPerformanceNumber(debug.casts_issued);
		castsRejected += XHSDevToolsPerformanceNumber(debug.casts_rejected);

		var decisionAverage = XHSDevToolsPerformanceNumber(debug.decision_cost_average_ms);
		if (decisionAverage > 0) {
			decisionAverageTotal += decisionAverage;
			decisionAverageCount += 1;
		}
		decisionMaximum = Math.max(
			decisionMaximum,
			XHSDevToolsPerformanceNumber(debug.decision_cost_max_ms)
		);
		thinkAverage = Math.max(
			thinkAverage,
			XHSDevToolsPerformanceNumber(debug.think_cost_average_ms)
		);
		thinkMaximum = Math.max(
			thinkMaximum,
			XHSDevToolsPerformanceNumber(debug.think_cost_max_ms)
		);
		baseThreatScore = Math.max(
			baseThreatScore,
			XHSDevToolsPerformanceNumber(debug.base_threat_score)
		);
		baseThreatCount = Math.max(
			baseThreatCount,
			XHSDevToolsPerformanceNumber(debug.base_threat_count)
		);
		dangerHits += XHSDevToolsPerformanceNumber(debug.danger_hits);
		stuckRecoveries += XHSDevToolsPerformanceNumber(debug.stuck_recoveries);
		safeErrors += XHSDevToolsPerformanceNumber(debug.safe_error_count);
		safeErrorStreak = Math.max(
			safeErrorStreak,
			XHSDevToolsPerformanceNumber(debug.safe_error_consecutive)
		);
	}

	if (rosterCount <= 0 && debugCount > 0) {
		rosterCount = debugCount;
	}
	var decisionAverageMs = decisionAverageCount > 0
		? decisionAverageTotal / decisionAverageCount
		: 0;

	XHSDevToolsSetPerformanceText("#XHSPerfBotCount", rosterCount + " / " + configuredCount);
	XHSDevToolsSetPerformanceText("#XHSPerfBotEngine", engineVerified + " / " + rosterCount);
	XHSDevToolsSetPerformanceText("#XHSPerfBotActivity", activeCount + " / " + idleCount);
	XHSDevToolsSetPerformanceText(
		"#XHSPerfBotOrders",
		ordersPerSecond.toFixed(1) + " / " + rateLimitedOrders
	);
	XHSDevToolsSetPerformanceText("#XHSPerfBotCasts", castsIssued + " / " + castsRejected);
	XHSDevToolsSetPerformanceText(
		"#XHSPerfBotDecision",
		XHSDevToolsPerformanceMilliseconds(decisionAverageMs) + " / " +
			XHSDevToolsPerformanceMilliseconds(decisionMaximum)
	);
	XHSDevToolsSetPerformanceText(
		"#XHSPerfBotThink",
		XHSDevToolsPerformanceMilliseconds(thinkAverage) + " / " +
			XHSDevToolsPerformanceMilliseconds(thinkMaximum)
	);
	XHSDevToolsSetPerformanceText(
		"#XHSPerfBotThreat",
		baseThreatScore.toFixed(1) + " / " + baseThreatCount
	);
	XHSDevToolsSetPerformanceText("#XHSPerfBotSafety", dangerHits + " / " + stuckRecoveries);
	XHSDevToolsSetPerformanceText("#XHSPerfBotErrors", safeErrors + " / " + safeErrorStreak);

	XHSDevToolsSetPerformanceStatus(
		"#XHSPerfBotEngine",
		rosterCount > 0 && engineVerified < rosterCount,
		rosterCount > 0 && engineVerified === 0
	);
	XHSDevToolsSetPerformanceStatus("#XHSPerfBotActivity", idleCount > 0, false);
	XHSDevToolsSetPerformanceStatus("#XHSPerfBotOrders", rateLimitedOrders > 0, false);
	XHSDevToolsSetPerformanceStatus("#XHSPerfBotCasts", castsRejected > castsIssued, false);
	XHSDevToolsSetPerformanceStatus("#XHSPerfBotThreat", baseThreatScore > 0, baseThreatScore >= 80);
	XHSDevToolsSetPerformanceStatus("#XHSPerfBotSafety", stuckRecoveries > 0, false);
	XHSDevToolsSetPerformanceStatus("#XHSPerfBotErrors", safeErrors > 0, safeErrorStreak > 0);
}

function XHSDevToolsRenderPlayerFPS(players) {
	var container = $("#XHSPerfPlayers");
	if (!container) {
		return;
	}

	container.RemoveAndDeleteChildren();
	var entries = [];
	for (var key in (players || {})) {
		var entry = players[key] || {};
		entries.push({
			playerID: Number(entry.player_id !== undefined ? entry.player_id : key),
			name: String(entry.name || ""),
			fps: Number(entry.fps)
		});
	}

	var localPlayerID = Players.GetLocalPlayer();
	var hasLocalPlayer = false;
	for (var entryIndex = 0; entryIndex < entries.length; entryIndex++) {
		if (entries[entryIndex].playerID === localPlayerID) {
			hasLocalPlayer = true;
			if ((isNaN(entries[entryIndex].fps) || entries[entryIndex].fps < 0) && XHSDevToolsLocalFPS >= 0) {
				entries[entryIndex].fps = XHSDevToolsLocalFPS;
			}
			if (!entries[entryIndex].name) {
				entries[entryIndex].name = Players.GetPlayerName(localPlayerID);
			}
			break;
		}
	}
	if (!hasLocalPlayer && localPlayerID >= 0) {
		entries.push({
			playerID: localPlayerID,
			name: Players.GetPlayerName(localPlayerID),
			fps: XHSDevToolsLocalFPS
		});
	}

	entries.sort(function(a, b) {
		return a.playerID - b.playerID;
	});

	if (entries.length === 0) {
		XHSDevToolsMakeLabel(container, "XHSDevToolsMuted", "Waiting for clients...");
		return;
	}

	for (var i = 0; i < entries.length; i++) {
		var entry = entries[i];
		var row = $.CreatePanel("Panel", container, "");
		row.AddClass("XHSDevToolsPerformancePlayerRow");

		var playerName = entry.name;
		if (!playerName && !isNaN(entry.playerID)) {
			playerName = Players.GetPlayerName(entry.playerID);
		}
		XHSDevToolsMakeLabel(
			row,
			"XHSDevToolsPerformancePlayerName",
			playerName || ("Player " + (entry.playerID + 1))
		);

		var hasFPS = !isNaN(entry.fps) && entry.fps >= 0;
		var fpsLabel = XHSDevToolsMakeLabel(
			row,
			"XHSDevToolsPerformancePlayerFPS",
			hasFPS ? (Math.round(entry.fps) + " FPS") : "--"
		);
		fpsLabel.SetHasClass("Critical", hasFPS && entry.fps < 30);
		fpsLabel.SetHasClass("Low", hasFPS && entry.fps >= 30 && entry.fps < 50);
		fpsLabel.SetHasClass("Unknown", !hasFPS);
	}
}

function XHSDevToolsActivitySource(activity, sourceList, index, includeCost) {
	var sources = activity[sourceList] || {};
	var source = sources[index] || sources[String(index)] || {};
	if (!source.source) {
		return index === 1 ? "--" : "";
	}
	var text = String(source.source) + "  " +
		XHSDevToolsPerformanceNumber(source.calls_per_second).toFixed(0) + "/s";
	if (includeCost) {
		text += "  " + XHSDevToolsPerformanceNumber(source.cost_ms_per_second).toFixed(1) + "ms";
	}
	return text;
}

function XHSDevToolsRenderActivityPerformance(activity) {
	activity = activity || {};
	var zoneSearches = XHSDevToolsPerformanceNumber(
		activity.spatial_queries_per_second !== undefined
			? activity.spatial_queries_per_second
			: activity.zone_searches_per_second
	);
	var zoneResults = XHSDevToolsPerformanceNumber(
		activity.spatial_results_per_second !== undefined
			? activity.spatial_results_per_second
			: activity.zone_results_per_second
	);
	var zoneCost = XHSDevToolsPerformanceNumber(
		activity.spatial_query_cost_ms_per_second !== undefined
			? activity.spatial_query_cost_ms_per_second
			: activity.zone_search_cost_ms_per_second
	);
	var zoneMaximum = XHSDevToolsPerformanceNumber(
		activity.spatial_query_max_ms !== undefined
			? activity.spatial_query_max_ms
			: activity.zone_search_max_ms
	);
	var orders = XHSDevToolsPerformanceNumber(activity.orders_per_second);
	var repeatedOrders = XHSDevToolsPerformanceNumber(activity.repeated_orders_per_second);
	var creepOrdersAI = XHSDevToolsPerformanceNumber(activity.creep_orders_modifier_ai_per_second);
	var creepOrdersWave = XHSDevToolsPerformanceNumber(activity.creep_orders_wave_per_second);
	var ownerConflicts = XHSDevToolsPerformanceNumber(activity.creep_order_owner_conflicts_per_second);
	var blockedWrongOwner = XHSDevToolsPerformanceNumber(activity.creep_orders_blocked_wrong_owner_per_second);
	var deduplicatedOrders = XHSDevToolsPerformanceNumber(activity.creep_orders_deduplicated_per_second);
	var ownerHandoffs = XHSDevToolsPerformanceNumber(activity.creep_order_owner_handoffs_per_second);
	var stageCreated = XHSDevToolsPerformanceNumber(activity.wave_stage_units_created_per_second);
	var stageFallback = XHSDevToolsPerformanceNumber(activity.wave_stage_units_fallback_created_per_second);
	var stageReleased = XHSDevToolsPerformanceNumber(activity.wave_stage_units_released_per_second);
	var stageCancelled = XHSDevToolsPerformanceNumber(activity.wave_stage_units_cancelled_per_second);
	var stageFailures = XHSDevToolsPerformanceNumber(activity.wave_stage_create_failures_per_second);
	var stageMissing = XHSDevToolsPerformanceNumber(activity.wave_stage_release_missing_per_second);
	var stageCost = XHSDevToolsPerformanceNumber(activity.wave_stage_create_cost_ms_per_second);
	var stageAIWakes = XHSDevToolsPerformanceNumber(activity.wave_stage_ai_wakes_per_second);
	var aiThinks = XHSDevToolsPerformanceNumber(activity.ai_thinks_per_second);
	var waveThinks = XHSDevToolsPerformanceNumber(activity.wave_thinks_per_second);
	var abilityThinks = XHSDevToolsPerformanceNumber(activity.ability_loop_thinks_per_second);
	var damage = XHSDevToolsPerformanceNumber(activity.damage_events_per_second);
	var casts = XHSDevToolsPerformanceNumber(activity.ability_casts_per_second);
	var linearProjectiles = XHSDevToolsPerformanceNumber(activity.linear_projectiles_per_second);
	var trackingProjectiles = XHSDevToolsPerformanceNumber(activity.tracking_projectiles_per_second);
	var spawns = XHSDevToolsPerformanceNumber(activity.unit_spawns_per_second);
	var deaths = XHSDevToolsPerformanceNumber(activity.unit_deaths_per_second);
	var targetChanges = XHSDevToolsPerformanceNumber(activity.target_changes_per_second);
	var spatialCacheHits = XHSDevToolsPerformanceNumber(activity.spatial_cache_hits_per_second);
	var spatialCacheMisses = XHSDevToolsPerformanceNumber(activity.spatial_cache_misses_per_second);

	XHSDevToolsSetPerformanceText("#XHSPerfZoneSearches", zoneSearches.toFixed(0) + " / " + zoneResults.toFixed(0));
	XHSDevToolsSetPerformanceText("#XHSPerfZoneCost", zoneCost.toFixed(1) + " / " + zoneMaximum.toFixed(1));
	XHSDevToolsSetPerformanceText("#XHSPerfOrders", orders.toFixed(0) + " / " + repeatedOrders.toFixed(0));
	XHSDevToolsSetPerformanceText("#XHSPerfCreepOrders", creepOrdersAI.toFixed(0) + " / " + creepOrdersWave.toFixed(0));
	XHSDevToolsSetPerformanceText("#XHSPerfOrderConflicts", ownerConflicts.toFixed(0) + " / " + blockedWrongOwner.toFixed(0));
	XHSDevToolsSetPerformanceText("#XHSPerfOrderDedup", deduplicatedOrders.toFixed(0) + " / " + ownerHandoffs.toFixed(0));
	XHSDevToolsSetPerformanceText("#XHSPerfStageCreated", stageCreated.toFixed(1) + " / " + stageFallback.toFixed(1));
	XHSDevToolsSetPerformanceText("#XHSPerfStageReleased", stageReleased.toFixed(1) + " / " + stageCancelled.toFixed(1));
	XHSDevToolsSetPerformanceText("#XHSPerfStageFailures", stageFailures.toFixed(1) + " / " + stageMissing.toFixed(1));
	XHSDevToolsSetPerformanceText("#XHSPerfStageCost", stageCost.toFixed(2) + " ms / " + stageAIWakes.toFixed(1));
	XHSDevToolsSetPerformanceText("#XHSPerfThinks", aiThinks.toFixed(0) + " / " + waveThinks.toFixed(0));
	XHSDevToolsSetPerformanceText("#XHSPerfAbilityThinks", abilityThinks.toFixed(0));
	XHSDevToolsSetPerformanceText("#XHSPerfCombat", damage.toFixed(0) + " / " + casts.toFixed(0));
	XHSDevToolsSetPerformanceText("#XHSPerfProjectiles", linearProjectiles.toFixed(0) + " / " + trackingProjectiles.toFixed(0));
	XHSDevToolsSetPerformanceText("#XHSPerfChurn", spawns.toFixed(0) + " / " + deaths.toFixed(0));
	XHSDevToolsSetPerformanceText("#XHSPerfTargetChanges", targetChanges.toFixed(0));
	XHSDevToolsSetPerformanceText(
		"#XHSPerfSpatialCache",
		spatialCacheHits.toFixed(0) + " / " + spatialCacheMisses.toFixed(0)
	);
	for (var sourceIndex = 1; sourceIndex <= 3; sourceIndex++) {
		var spatialSourceList = activity.top_spatial_sources ? "top_spatial_sources" : "top_zone_sources";
		XHSDevToolsSetPerformanceText(
			"#XHSPerfZoneSource" + sourceIndex,
			XHSDevToolsActivitySource(activity, spatialSourceList, sourceIndex, true)
		);
	}
	for (var orderSourceIndex = 1; orderSourceIndex <= 2; orderSourceIndex++) {
		XHSDevToolsSetPerformanceText(
			"#XHSPerfOrderSource" + orderSourceIndex,
			XHSDevToolsActivitySource(activity, "top_order_sources", orderSourceIndex, false)
		);
	}

	XHSDevToolsSetPerformanceStatus("#XHSPerfZoneSearches", zoneSearches >= 500, zoneSearches >= 1000);
	XHSDevToolsSetPerformanceStatus("#XHSPerfZoneCost", zoneCost >= 10, zoneCost >= 25);
	XHSDevToolsSetPerformanceStatus("#XHSPerfOrders", orders >= 200 || repeatedOrders >= 50, repeatedOrders >= 150);
	XHSDevToolsSetPerformanceStatus("#XHSPerfOrderConflicts", ownerConflicts > 0 || blockedWrongOwner > 0, ownerConflicts >= 5 || blockedWrongOwner >= 5);
	XHSDevToolsSetPerformanceStatus("#XHSPerfStageFailures", stageFailures > 0 || stageMissing > 0, stageFailures >= 1 || stageMissing >= 1);
	XHSDevToolsSetPerformanceStatus("#XHSPerfThinks", waveThinks >= 800 || aiThinks >= 300, waveThinks >= 1600);
	XHSDevToolsSetPerformanceStatus("#XHSPerfCombat", damage >= 500, damage >= 1000);
	XHSDevToolsSetPerformanceStatus("#XHSPerfProjectiles", linearProjectiles + trackingProjectiles >= 100, linearProjectiles + trackingProjectiles >= 250);
}

function XHSDevToolsRenderPerformance() {
	var panel = $("#XHSDevToolsPerformance");
	if (!panel) {
		return;
	}

	var data = XHSDevToolsPerformance || {};
	var creeps = XHSDevToolsPerformanceNumber(data.creeps);
	var simLagMs = XHSDevToolsPerformanceNumber(data.sim_lag_ms);
	var simHealth = XHSDevToolsPerformanceNumber(data.sim_health_pct);
	var hasSimHealth = data.sim_health_pct !== undefined && data.sim_health_pct !== null &&
		!isNaN(Number(data.sim_health_pct));
	panel.SetHasClass("Warning", (creeps >= 100 || simLagMs >= 15 || (hasSimHealth && simHealth < 90)) && creeps < 125 && simLagMs < 30 && (!hasSimHealth || simHealth >= 70));
	panel.SetHasClass("Critical", creeps >= 125 || simLagMs >= 30 || (hasSimHealth && simHealth < 70));

	XHSDevToolsRenderCompactPerformance(data);
	XHSDevToolsSetPerformanceText("#XHSPerfTotalUnits", String(XHSDevToolsPerformanceNumber(data.total_units)));
	var phaseOneBudget = data.phase_one_spawn_budget || {};
	var phaseOneActive = XHSDevToolsPerformanceNumber(phaseOneBudget.active_units);
	var phaseOneHardCap = XHSDevToolsPerformanceNumber(phaseOneBudget.hard_cap);
	var phaseOneSpawned = XHSDevToolsPerformanceNumber(phaseOneBudget.spawned);
	var phaseOneSkipped = XHSDevToolsPerformanceNumber(phaseOneBudget.skipped);
	XHSDevToolsSetPerformanceText("#XHSPerfPhaseOneBudget", phaseOneActive + " / " + phaseOneHardCap);
	XHSDevToolsSetPerformanceText("#XHSPerfPhaseOneWave", phaseOneSpawned + " / " + phaseOneSkipped);
	XHSDevToolsSetPerformanceStatus(
		"#XHSPerfPhaseOneBudget",
		phaseOneActive >= XHSDevToolsPerformanceNumber(phaseOneBudget.soft_cap),
		phaseOneHardCap > 0 && phaseOneActive >= phaseOneHardCap
	);
	XHSDevToolsSetPerformanceStatus("#XHSPerfPhaseOneWave", phaseOneSkipped > 0, phaseOneSkipped > 0 && phaseOneSpawned <= 0);
	XHSDevToolsSetPerformanceText("#XHSPerfWaveLoops", String(XHSDevToolsPerformanceNumber(data.wave_checks_per_second)));
	XHSDevToolsSetPerformanceText("#XHSPerfAITicks", String(XHSDevToolsPerformanceNumber(data.ai_ticks_per_second)));
	XHSDevToolsSetPerformanceText("#XHSPerfAbilityLoops", String(XHSDevToolsPerformanceNumber(data.ability_checks_per_second)));
	XHSDevToolsSetPerformanceText(
		"#XHSPerfMovementOwners",
		XHSDevToolsPerformanceNumber(data.movement_owner_ai) + " / " +
			XHSDevToolsPerformanceNumber(data.movement_owner_wave)
	);
	var waveStager = data.wave_stager || {};
	var stagedUnits = XHSDevToolsPerformanceNumber(waveStager.staged_units);
	var stageCap = XHSDevToolsPerformanceNumber(waveStager.global_cap);
	XHSDevToolsSetPerformanceText(
		"#XHSPerfStagedUnits",
		stagedUnits + " / " + stageCap + (waveStager.enabled === false ? " OFF" : "")
	);
	XHSDevToolsSetPerformanceText(
		"#XHSPerfStageQueue",
		XHSDevToolsPerformanceNumber(waveStager.active_jobs) + " / " +
			XHSDevToolsPerformanceNumber(waveStager.pending_units)
	);
	XHSDevToolsSetPerformanceText(
		"#XHSPerfStageCleanup",
		XHSDevToolsPerformanceNumber(waveStager.cleanup_units) + " / " +
			XHSDevToolsPerformanceNumber(waveStager.create_cost_max_ms).toFixed(2) + " ms"
	);
	XHSDevToolsSetPerformanceStatus(
		"#XHSPerfStagedUnits",
		stageCap > 0 && stagedUnits >= stageCap * 0.8,
		stageCap > 0 && stagedUnits >= stageCap
	);
	XHSDevToolsSetPerformanceText("#XHSPerfThinkers", String(XHSDevToolsPerformanceNumber(data.thinkers)));
	XHSDevToolsSetPerformanceText(
		"#XHSPerfHeroesBosses",
		XHSDevToolsPerformanceNumber(data.heroes) + " / " + XHSDevToolsPerformanceNumber(data.bosses)
	);
	XHSDevToolsSetPerformanceText("#XHSPerfSummons", String(XHSDevToolsPerformanceNumber(data.summons)));
	XHSDevToolsSetPerformanceText(
		"#XHSPerfOther",
		XHSDevToolsPerformanceNumber(data.breakables) + " / " + XHSDevToolsPerformanceNumber(data.other_units)
	);
	XHSDevToolsSetPerformanceText(
		"#XHSPerfSimulation",
		simLagMs.toFixed(1) + " ms / " + Math.round(simHealth) + "% / " +
			XHSDevToolsPerformanceNumber(data.server_observer_interval_ms).toFixed(0) + " ms tick"
	);
	XHSDevToolsSetPerformanceText(
		"#XHSPerfCost",
		XHSDevToolsPerformanceNumber(data.scan_ms).toFixed(2) + " ms"
	);
	XHSDevToolsRenderPlayerFPS(data.players || {});
	XHSDevToolsRenderActivityPerformance(data.activity || {});
	XHSDevToolsRenderBotPerformance();
}

function XHSDevToolsClientFPSTick() {
	XHSDevToolsFPSFrames += 1;
	var now = Date.now();
	var elapsed = now - XHSDevToolsFPSWindowStartedAt;
	if (elapsed >= 1000) {
		var fps = Math.max(0, Math.min(500, XHSDevToolsFPSFrames * 1000 / elapsed));
		XHSDevToolsLocalFPS = Math.round(fps * 10) / 10;
		XHSDevToolsRenderCompactPerformance(XHSDevToolsPerformance || {});
		XHSDevToolsRenderPlayerFPS((XHSDevToolsPerformance || {}).players || {});
		if (XHSDevToolsMatchHasPerformanceViewer() &&
			now - XHSDevToolsFPSLastSentAt >= 1900) {
			GameEvents.SendCustomGameEventToServer("xhs_devtools_client_fps", {
				fps: XHSDevToolsLocalFPS
			});
			XHSDevToolsFPSLastSentAt = now;
		}
		XHSDevToolsFPSFrames = 0;
		XHSDevToolsFPSWindowStartedAt = now;
	}

	$.Schedule(0.0, XHSDevToolsClientFPSTick);
}

function XHSDevToolsClear(panel) {
	if (!panel) {
		return;
	}
	panel.RemoveAndDeleteChildren();
}

function XHSDevToolsMakeLabel(parent, className, text) {
	var label = $.CreatePanel("Label", parent, "");
	if (className) {
		label.AddClass(className);
	}
	label.text = text || "";
	return label;
}

function XHSDevToolsMakeButton(parent, label, className, callback) {
	var button = $.CreatePanel("Button", parent, "");
	button.AddClass("XHSDevToolsButton");
	button.hittest = true;
	button.hittestchildren = true;
	if (className) {
		button.AddClass(className);
	}
	button.SetPanelEvent("onactivate", callback);
	XHSDevToolsMakeLabel(button, "", label);
	return button;
}

function XHSDevToolsMakeHeroIcon(parent, heroIcon, className) {
	var frame = $.CreatePanel("Panel", parent, "");
	frame.AddClass("XHSDevToolsHeroIconFrame");
	if (className) {
		frame.AddClass(className);
	}

	var image = $.CreatePanel("Image", frame, "");
	image.AddClass("XHSDevToolsHeroIcon");
	image.SetImage(heroIcon ? "file://{images}/heroes/" + heroIcon + ".png" : "");
	return frame;
}

function XHSDevToolsMakeSection(parent, title) {
	var section = $.CreatePanel("Panel", parent, "");
	section.AddClass("XHSDevToolsSection");
	XHSDevToolsMakeLabel(section, "XHSDevToolsSectionTitle", title);
	return section;
}

function XHSDevToolsRenderTimescale() {
	var bar = $("#XHSDevToolsTimescale");
	if (!bar) {
		return;
	}

	XHSDevToolsClear(bar);
	var available = XHSDevToolsIsToolsMode();
	bar.SetHasClass("Visible", available);
	if (!available) {
		return;
	}

	var serverTimescale = Number(XHSDevToolsState.host_timescale);
	if (serverTimescale > 0) {
		XHSDevToolsCurrentTimescale = serverTimescale;
	}

	for (var i = 0; i < XHS_DEVTOOLS_TIMESCALES.length; i++) {
		(function(option) {
			var button = $.CreatePanel("Button", bar, "");
			button.AddClass("XHSDevToolsTimescaleButton");
			button.SetHasClass("Active", Math.abs(XHSDevToolsCurrentTimescale - option.value) < 0.001);
			button.SetPanelEvent("onactivate", function() {
				XHSDevToolsCurrentTimescale = option.value;
				XHSDevToolsRenderTimescale();
				XHSDevToolsSend("set_timescale", { timescale: option.value });
			});
			XHSDevToolsMakeLabel(button, "", option.label);
		})(XHS_DEVTOOLS_TIMESCALES[i]);
	}
}

function XHSDevToolsIsLocalSpectator() {
	if (typeof Players === "undefined" || !Players.GetTeam) {
		return false;
	}
	var localPlayerID = Game.GetLocalPlayerID();
	if (localPlayerID < 0) {
		return false;
	}
	if (Number(Players.GetTeam(localPlayerID)) === 1) {
		return true;
	}

	// During custom setup/loading, Players.GetTeam can lag one frame behind the
	// server assignment. The authoritative bot configuration already identifies
	// the one client that is becoming XHS' spectator controller.
	return Number((XHSDevToolsBotConfig || {}).spectator_mode || 0) === 1
		&& Number((XHSDevToolsBotConfig || {}).controller_player_id) === localPlayerID;
}

function XHSDevToolsSetVanillaSpectatorPanelHidden(panelID, hidden) {
	if (typeof FindDotaHudElement !== "function") {
		return;
	}

	var panel = null;
	try {
		panel = FindDotaHudElement(panelID);
	} catch (error) {
		panel = null;
	}
	if (!panel) {
		return;
	}

	if (hidden) {
		if (panel._xhsToolsSpectatorHidden !== true) {
			panel._xhsToolsSpectatorPreviousOpacity = panel.style.opacity;
			panel._xhsToolsSpectatorPreviousHitTest = panel.hittest;
		}
		panel._xhsToolsSpectatorHidden = true;
		panel.visible = false;
		panel.hittest = false;
		panel.style.visibility = "collapse";
		// Valve rebuilds and re-opens DOTASpectatorOptions after a runtime team
		// assignment. Opacity guards the frame before our next 250 ms tick too.
		panel.style.opacity = "0";
	} else if (panel._xhsToolsSpectatorHidden === true) {
		panel.visible = true;
		panel.style.visibility = null;
		panel.style.opacity = panel._xhsToolsSpectatorPreviousOpacity || null;
		panel.hittest = panel._xhsToolsSpectatorPreviousHitTest !== undefined
			? panel._xhsToolsSpectatorPreviousHitTest
			: true;
		panel._xhsToolsSpectatorHidden = false;
	}
}

function XHSDevToolsAccessDropDownMenu(dropDown) {
	if (!dropDown || typeof dropDown.AccessDropDownMenu !== "function") {
		return null;
	}
	try {
		return dropDown.AccessDropDownMenu();
	} catch (error) {
		return null;
	}
}

function XHSDevToolsSelectDropDownOption(dropDown, option) {
	if (!dropDown || !option || !option.id) {
		return false;
	}
	try {
		dropDown.SetSelected(option.id);
		$.DispatchEvent("DropDownMenuItemSelected", dropDown, option);
		return true;
	} catch (error) {
		return false;
	}
}

function XHSDevToolsFindCameraModeOption(dropDown, mode) {
	var menu = XHSDevToolsAccessDropDownMenu(dropDown);
	if (!menu) {
		return null;
	}

	var knownIDs = mode === XHS_SPECTATOR_CAMERA_MODE_CHASE
		? ["CameraFollow", "CameraChase", "CameraHeroChase", "HeroChase", "SpectatorCameraChase"]
		: ["CameraFree", "CameraRoaming", "FreeCamera", "SpectatorCameraFree"];
	for (var knownIndex = 0; knownIndex < knownIDs.length; knownIndex++) {
		var knownOption = menu.FindChildTraverse(knownIDs[knownIndex]);
		if (knownOption) {
			return knownOption;
		}
	}

	var attributeNames = ["camera", "camera_mode", "mode", "value"];
	var pending = [menu];
	while (pending.length > 0) {
		var panel = pending.shift();
		if (!panel) {
			continue;
		}
		for (var attributeIndex = 0; attributeIndex < attributeNames.length; attributeIndex++) {
			try {
				if (panel.GetAttributeInt(attributeNames[attributeIndex], -999) === mode) {
					return panel;
				}
			} catch (error) {
				// Native entries vary slightly between Dota builds.
			}
		}
		for (var childIndex = 0; childIndex < panel.GetChildCount(); childIndex++) {
			pending.push(panel.GetChild(childIndex));
		}
	}
	return null;
}

function XHSDevToolsApplySpectatorCameraMode(following) {
	if (!XHSDevToolsIsLocalSpectator() || typeof FindDotaHudElement !== "function") {
		XHSDevToolsSpectatorState.cameraModeConfirmations = 0;
		return false;
	}

	var cameraDropDown = null;
	try {
		cameraDropDown = FindDotaHudElement("CameraDropDown");
	} catch (error) {
		cameraDropDown = null;
	}
	if (!cameraDropDown) {
		return false;
	}

	var desiredMode = following
		? XHS_SPECTATOR_CAMERA_MODE_CHASE
		: XHS_SPECTATOR_CAMERA_MODE_FREE;
	var option = XHSDevToolsFindCameraModeOption(cameraDropDown, desiredMode);
	if (!option) {
		return false;
	}

	var selected = null;
	try {
		selected = cameraDropDown.GetSelected();
	} catch (error) {
		selected = null;
	}
	if (!selected || selected.id !== option.id) {
		XHSDevToolsSpectatorState.cameraModeConfirmations = 0;
		return XHSDevToolsSelectDropDownOption(cameraDropDown, option);
	}

	XHSDevToolsSpectatorState.cameraModeConfirmations++;
	return true;
}

function XHSDevToolsSetVanillaScoreboardHidden(hidden) {
	if (typeof FindDotaHudElement !== "function") {
		return;
	}

	var radiantTeam = null;
	try {
		radiantTeam = FindDotaHudElement("RadiantTeamContainer");
	} catch (error) {
		radiantTeam = null;
	}
	if (!radiantTeam || !radiantTeam.GetParent) {
		return;
	}

	// Valve's dota_hud_scoreboard hierarchy is:
	// DOTAScoreboard > Background > RadiantTeamContainer.
	// Hide DOTAScoreboard itself so its own open/close classes can no longer
	// flash behind XHS' separate CustomUIElement FlyoutScoreboard.
	var background = radiantTeam.GetParent();
	var scoreboard = background && background.GetParent
		? background.GetParent()
		: null;
	if (!scoreboard || !scoreboard.FindChildTraverse ||
		!scoreboard.FindChildTraverse("TeamInventories")) {
		return;
	}

	if (hidden) {
		scoreboard._xhsToolsSpectatorHidden = true;
		scoreboard.style.visibility = "collapse";
	} else if (scoreboard._xhsToolsSpectatorHidden === true) {
		scoreboard.style.visibility = null;
		scoreboard._xhsToolsSpectatorHidden = false;
	}
}

function XHSDevToolsUpdateVanillaSpectatorUI() {
	var hidden = XHSDevToolsIsLocalSpectator();
	// Popup options are hosted in separate *DropDownMenu panels. Resolve and
	// apply them before collapsing the native spectator parent.
	XHSDevToolsApplyDefaultRadiantFog(hidden);
	if (hidden) {
		// Panorama owns follow mode. Keep Valve's camera in free mode so its
		// chase controller cannot fight SetCameraTargetPosition every frame.
		XHSDevToolsApplySpectatorCameraMode(false);
	}
	XHSDevToolsSetVanillaSpectatorPanelHidden("GameInfoButton", hidden);
	XHSDevToolsSetVanillaSpectatorPanelHidden("spectator_options", hidden);
	XHSDevToolsSetVanillaSpectatorPanelHidden("SpectatorOptionsContainer", hidden);
	XHSDevToolsSetVanillaSpectatorPanelHidden("SpectatorOptionsVisibilityButton", hidden);
	XHSDevToolsSetVanillaScoreboardHidden(hidden);
	if (
		GameUI.SetDefaultUIEnabled
		&& typeof DotaDefaultUIElement_t !== "undefined"
		&& DotaDefaultUIElement_t.DOTA_DEFAULT_UI_FLYOUT_SCOREBOARD !== undefined
	) {
		// The FlyoutScoreboard CustomUIElement receives its event independently.
		// Re-enabling this flag for spectators was what resurrected Valve's
		// scoreboard behind the XHS scoreboard.
		GameUI.SetDefaultUIEnabled(
			DotaDefaultUIElement_t.DOTA_DEFAULT_UI_FLYOUT_SCOREBOARD,
			false
		);
	}
}

function XHSDevToolsApplyDefaultRadiantFog(isSpectator) {
	if (!isSpectator) {
		XHSDevToolsSpectatorState.radiantFogApplied = false;
		XHSDevToolsSpectatorState.radiantFogConfirmations = 0;
		return;
	}
	if (XHSDevToolsSpectatorState.radiantFogApplied ||
		typeof FindDotaHudElement !== "function") {
		return;
	}

	var fogDropDown = null;
	try {
		fogDropDown = FindDotaHudElement("FogDropDown");
	} catch (error) {
		fogDropDown = null;
	}
	if (!fogDropDown || typeof fogDropDown.SetSelected !== "function") {
		return;
	}

	var selected = null;
	try {
		selected = typeof fogDropDown.GetSelected === "function"
			? fogDropDown.GetSelected()
			: null;
	} catch (error) {
		selected = null;
	}
	if (selected && selected.id === "FogRadiant") {
		XHSDevToolsSpectatorState.radiantFogConfirmations++;
		if (XHSDevToolsSpectatorState.radiantFogConfirmations >= 2) {
			// Apply only as the entry default. Once confirmed, never override a
			// spectator who deliberately selects another FoW perspective.
			XHSDevToolsSpectatorState.radiantFogApplied = true;
		}
		return;
	}

	XHSDevToolsSpectatorState.radiantFogConfirmations = 0;
	try {
		// Valve's native spectator panel maps FogRadiant to
		// dota_spectator_fog_of_war 2. Dispatch the dropdown selection event as
		// well as changing its visual selection: SetSelected alone can update
		// the label without submitting the client convar during HUD startup.
		var fogMenu = XHSDevToolsAccessDropDownMenu(fogDropDown);
		var radiantOption = fogMenu && fogMenu.FindChildTraverse
			? fogMenu.FindChildTraverse("FogRadiant")
			: null;
		if (radiantOption) {
			XHSDevToolsSelectDropDownOption(fogDropDown, radiantOption);
		}
	} catch (error) {
		// The native spectator options may still be initializing. The regular
		// spectator tick retries until two consecutive confirmations succeed.
	}
}

function XHSDevToolsSpectatorBots() {
	var bots = [];
	var rosterEntries = XHSDevToolsBotTableValues(XHSDevToolsBotRoster.players || {});
	for (var i = 0; i < rosterEntries.length; i++) {
		var entry = rosterEntries[i].value || {};
		var playerID = Number(entry.player_id);
		if (isNaN(playerID)) {
			playerID = Number(rosterEntries[i].key);
		}
		if (isNaN(playerID) || Number(entry.preview || 0) === 1 ||
			String(entry.participant_kind || "") !== "xhs_bot") {
			continue;
		}
		bots.push({
			playerID: playerID,
			slot: Number(entry.slot || 999),
			entry: entry,
			debug: XHSDevToolsBotDebug[String(playerID)] || {}
		});
	}
	bots.sort(function(a, b) {
		if (a.slot !== b.slot) {
			return a.slot - b.slot;
		}
		return a.playerID - b.playerID;
	});
	return bots;
}

function XHSDevToolsSpectatorHeroEntIndex(bot) {
	if (!bot) {
		return -1;
	}
	var entIndex = Number((bot.debug || {}).hero_entindex);
	if (isNaN(entIndex) || entIndex < 0) {
		entIndex = Players.GetPlayerHeroEntityIndex(bot.playerID);
	}
	return !isNaN(entIndex) ? entIndex : -1;
}

function XHSDevToolsSpectatorCurrentBot(bots) {
	bots = bots || XHSDevToolsSpectatorBots();
	for (var i = 0; i < bots.length; i++) {
		if (bots[i].playerID === XHSDevToolsSpectatorState.currentPlayerID) {
			return { bot: bots[i], index: i };
		}
	}
	if (bots.length > 0) {
		XHSDevToolsSpectatorState.currentPlayerID = bots[0].playerID;
		return { bot: bots[0], index: 0 };
	}
	XHSDevToolsSpectatorState.currentPlayerID = -1;
	return { bot: null, index: -1 };
}

function XHSDevToolsSpectatorFormatGold(value) {
	var gold = Math.max(0, Math.floor(Number(value) || 0));
	return String(gold).replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

function XHSDevToolsSpectatorUpdateClientCamera(transitionSeconds) {
	if (!XHSDevToolsSpectatorState.following ||
		!XHSDevToolsIsLocalSpectator() ||
		typeof GameUI.SetCameraTargetPosition !== "function") {
		return false;
	}

	var bot = XHSDevToolsSpectatorCurrentBot().bot;
	var entIndex = XHSDevToolsSpectatorHeroEntIndex(bot);
	if (entIndex < 0 ||
		(Entities.IsValidEntity && !Entities.IsValidEntity(entIndex))) {
		return false;
	}

	var origin = Entities.GetAbsOrigin(entIndex);
	if (!origin || origin.length < 3 ||
		!isFinite(Number(origin[0])) ||
		!isFinite(Number(origin[1])) ||
		!isFinite(Number(origin[2]))) {
		return false;
	}

	try {
		GameUI.SetCameraTargetPosition(origin, Math.max(0, Number(transitionSeconds) || 0));
		XHSDevToolsSpectatorState.lastFollowEntIndex = entIndex;
		return true;
	} catch (error) {
		return false;
	}
}

function XHSDevToolsSpectatorCameraTick() {
	// 20 Hz is smooth enough for hero movement while remaining negligible next
	// to Panorama's normal HUD work. The loop performs no work in free camera.
	if (XHSDevToolsSpectatorState.following && XHSDevToolsIsLocalSpectator()) {
		var current = XHSDevToolsSpectatorCurrentBot();
		var entIndex = XHSDevToolsSpectatorHeroEntIndex(current.bot);
		var changedTarget = entIndex !== XHSDevToolsSpectatorState.lastFollowEntIndex;
		XHSDevToolsSpectatorUpdateClientCamera(changedTarget ? 0.18 : 0.065);
	}
	$.Schedule(0.05, XHSDevToolsSpectatorCameraTick);
}

function XHSDevToolsSpectatorInspect() {
	var current = XHSDevToolsSpectatorCurrentBot();
	var bot = current.bot;
	if (!bot) {
		return;
	}

	var entIndex = XHSDevToolsSpectatorHeroEntIndex(bot);
	if (entIndex < 0 || (Entities.IsValidEntity && !Entities.IsValidEntity(entIndex))) {
		return;
	}

	if (XHSDevToolsSpectatorState.following) {
		XHSDevToolsApplySpectatorCameraMode(false);
	}
	GameUI.SelectUnit(entIndex, false);
	XHSDevToolsSpectatorState.lastInspectedEntIndex = entIndex;
	if (XHSDevToolsSpectatorState.following) {
		XHSDevToolsSpectatorState.lastFollowEntIndex = -1;
		XHSDevToolsSpectatorUpdateClientCamera(0.18);
	}
}

function XHSDevToolsSpectatorStep(direction) {
	var bots = XHSDevToolsSpectatorBots();
	if (bots.length === 0) {
		return;
	}

	var current = XHSDevToolsSpectatorCurrentBot(bots);
	var nextIndex = current.index + direction;
	if (nextIndex < 0) {
		nextIndex = bots.length - 1;
	} else if (nextIndex >= bots.length) {
		nextIndex = 0;
	}
	XHSDevToolsSpectatorState.currentPlayerID = bots[nextIndex].playerID;
	XHSDevToolsSpectatorState.lastFollowEntIndex = -1;
	XHSDevToolsSpectatorInspect();
	XHSDevToolsRenderSpectator();
}

function XHSDevToolsSpectatorToggleFollow() {
	var current = XHSDevToolsSpectatorCurrentBot();
	if (!current.bot) {
		return;
	}

	XHSDevToolsSpectatorState.following = !XHSDevToolsSpectatorState.following;
	XHSDevToolsSpectatorState.lastFollowEntIndex = -1;
	XHSDevToolsSpectatorState.cameraModeConfirmations = 0;
	XHSDevToolsApplySpectatorCameraMode(false);
	if (XHSDevToolsSpectatorState.following) {
		XHSDevToolsSpectatorUpdateClientCamera(0.18);
	}
	XHSDevToolsRenderSpectator();
}

function XHSDevToolsRenderSpectator() {
	var panel = $("#XHSDevToolsSpectator");
	if (!panel) {
		return;
	}

	var visible = XHSDevToolsIsLocalSpectator();
	panel.SetHasClass("Visible", visible);
	if (!visible) {
		XHSDevToolsSpectatorState.following = true;
		XHSDevToolsSpectatorState.lastFollowEntIndex = -1;
		XHSDevToolsSpectatorState.lastInspectedEntIndex = -1;
		XHSDevToolsSpectatorState.wasVisible = false;
		return;
	}
	XHSDevToolsSpectatorState.wasVisible = true;

	var bots = XHSDevToolsSpectatorBots();
	var current = XHSDevToolsSpectatorCurrentBot(bots);
	var bot = current.bot;
	var hasBot = !!bot;
	var previous = $("#XHSDevToolsSpectatorPrevious");
	var next = $("#XHSDevToolsSpectatorNext");
	var follow = $("#XHSDevToolsSpectatorFollow");
	var identity = $("#XHSDevToolsSpectatorIdentity");
	if (previous) {
		previous.enabled = hasBot;
	}
	if (next) {
		next.enabled = hasBot;
	}
	if (follow) {
		follow.enabled = hasBot;
		follow.SetHasClass("Active", hasBot && XHSDevToolsSpectatorState.following);
	}
	if (identity) {
		identity.enabled = hasBot;
	}

	var name = $("#XHSDevToolsSpectatorName");
	var counter = $("#XHSDevToolsSpectatorCounter");
	var gold = $("#XHSDevToolsSpectatorGold");
	var hero = $("#XHSDevToolsSpectatorHero");
	var followLabel = $("#XHSDevToolsSpectatorFollowLabel");
	if (!hasBot) {
		if (name) {
			name.text = "WAITING FOR AI ALLIES";
		}
		if (counter) {
			counter.text = "0 / 0";
		}
		if (gold) {
			gold.text = "0 GOLD";
		}
		if (hero) {
			hero.heroname = "npc_dota_hero_wisp";
		}
		if (followLabel) {
			followLabel.text = "FOLLOW";
		}
		return;
	}

	var debug = bot.debug || {};
	if (name) {
		name.text = XHSDevToolsBotText(bot.entry.name, XHSDevToolsBotHeroName(bot.entry.hero || debug.hero));
	}
	if (counter) {
		counter.text = (current.index + 1) + " / " + bots.length;
	}
	if (gold) {
		gold.text = XHSDevToolsSpectatorFormatGold(debug.gold) + " GOLD";
	}
	if (hero) {
		hero.heroname = bot.entry.hero || debug.hero || "npc_dota_hero_wisp";
	}
	if (followLabel) {
		followLabel.text = XHSDevToolsSpectatorState.following ? "FREE CAMERA" : "FOLLOW";
	}

	if (XHSDevToolsSpectatorState.following) {
		var entIndex = XHSDevToolsSpectatorHeroEntIndex(bot);
		if (entIndex >= 0 &&
			entIndex !== XHSDevToolsSpectatorState.lastInspectedEntIndex) {
			GameUI.SelectUnit(entIndex, false);
			XHSDevToolsSpectatorState.lastInspectedEntIndex = entIndex;
		}
	}
}

function XHSDevToolsBindSpectator() {
	var previous = $("#XHSDevToolsSpectatorPrevious");
	var next = $("#XHSDevToolsSpectatorNext");
	var follow = $("#XHSDevToolsSpectatorFollow");
	var identity = $("#XHSDevToolsSpectatorIdentity");
	if (previous) {
		previous.SetPanelEvent("onactivate", function() {
			XHSDevToolsSpectatorStep(-1);
		});
	}
	if (next) {
		next.SetPanelEvent("onactivate", function() {
			XHSDevToolsSpectatorStep(1);
		});
	}
	if (follow) {
		follow.SetPanelEvent("onactivate", XHSDevToolsSpectatorToggleFollow);
	}
	if (identity) {
		identity.SetPanelEvent("onactivate", function() {
			XHSDevToolsSpectatorInspect();
		});
	}
}

function XHSDevToolsSpectatorTick() {
	XHSDevToolsUpdateVanillaSpectatorUI();
	XHSDevToolsRenderSpectator();
	$.Schedule(0.25, XHSDevToolsSpectatorTick);
}

function XHSDevToolsStartSpectatorLoops() {
	if (XHSDevToolsSpectatorLoopsStarted || !XHSDevToolsIsLocalSpectator()) {
		return;
	}
	XHSDevToolsSpectatorLoopsStarted = true;
	XHSDevToolsSpectatorCameraTick();
	XHSDevToolsSpectatorTick();
}

function XHSDevToolsRenderTabs() {
	var tabs = $("#XHSDevToolsTabs");
	XHSDevToolsClear(tabs);

	for (var i = 0; i < XHS_DEVTOOLS_TABS.length; i++) {
		(function(tab) {
			var button = XHSDevToolsMakeButton(tabs, tab.label, "XHSDevToolsTab", function() {
				XHSDevToolsActiveTab = tab.id;
				XHSDevToolsRender();
			});
			button.SetHasClass("Active", XHSDevToolsActiveTab === tab.id);
		})(XHS_DEVTOOLS_TABS[i]);
	}
}

function XHSDevToolsRenderStatus() {
	var label = $("#XHSDevToolsStatusText");
	if (!label) {
		return;
	}

	if (!XHSDevToolsState.enabled) {
		var unavailable = XHSDevToolsHasServerState
			? "Disabled: launch from Workshop Tools mode"
			: "Waiting for devtools server state";
		label.text = unavailable;
		label.SetHasClass("Error", true);
		return;
	}

	var result = XHSDevToolsState.last_result || {};
	var sandbox = XHSDevToolsState.campaign_flow_active ? "Flow ON" : (XHSDevToolsState.sandbox_active ? "Sandbox ON" : "Sandbox off");
	var phase = XHSDevToolsState.game_phase || 0;
	var difficulty = XHSDevToolsState.difficulty || 1;
	var paused = XHSDevToolsState.timers_paused || 0;
	var message = result.message || "Ready";
	label.text = sandbox + " | Phase " + phase + " | Difficulty " + difficulty + " | Pause " + paused + " | " + message;
	label.SetHasClass("Error", result.ok === false);
}

function XHSDevToolsRenderSandboxBar() {
	var bar = $("#XHSDevToolsSandboxBar");
	XHSDevToolsClear(bar);
	if (!bar) {
		return;
	}

	if (!XHSDevToolsState.enabled) {
		bar.style.visibility = "collapse";
		return;
	}

	bar.style.visibility = "visible";
	var active = XHSDevToolsState.sandbox_active === true;
	var text = $.CreatePanel("Panel", bar, "");
	text.AddClass("XHSDevToolsSandboxText");
	XHSDevToolsMakeLabel(text, "XHSDevToolsSandboxTitle", "Sandbox");
	XHSDevToolsMakeLabel(text, "XHSDevToolsSandboxHint", active ? "Automatic creeps, events, timers and final wave are disabled." : "Normal automatic game flow is running.");

	var button = XHSDevToolsMakeButton(bar, active ? "Disable Sandbox" : "Enable Sandbox", active ? "Warn" : "Accent", function() {
		XHSDevToolsSend("set_sandbox", { enabled: active ? 0 : 1 });
	});
	button.AddClass("XHSDevToolsSandboxToggleButton");
	button.SetHasClass("Active", active);
}

function XHSDevToolsRenderUnavailable(parent) {
	var section = XHSDevToolsMakeSection(parent, "Dev tools unavailable");
	var reason = XHSDevToolsHasServerState
		? "The server loaded the panel, but actions are disabled because this session is not running in Workshop Tools mode."
		: "No devtools server state has been received yet. If you just compiled the HUD, restart the addon or reload the custom UI.";
	XHSDevToolsMakeLabel(section, "XHSDevToolsUnavailableLine", reason);
	XHSDevToolsMakeLabel(section, "XHSDevToolsMuted", "The DEV button is shown for diagnostics only; scenario, boss, lane, timer, and player actions remain blocked until tools mode is active.");
}

function XHSDevToolsGetBossActivity(boss) {
	var unitNames = XHS_DEVTOOLS_BOSS_UNITS[boss.id] || [];
	var bossesState = XHSDevToolsState.bosses || {};

	for (var bossKey in bossesState) {
		var active = bossesState[bossKey];
		for (var i = 0; i < unitNames.length; i++) {
			if (active.name === unitNames[i]) {
				var health = active.max_health > 0 ? Math.floor((active.health / active.max_health) * 100) : 0;
				return { active: true, health: health };
			}
		}
	}

	return { active: false, health: 0 };
}

function XHSDevToolsRenderScenarios(parent) {
	var quests = XHSDevToolsMakeSection(parent, "Quests");
	XHSDevToolsMakeLabel(quests, "XHSDevToolsSubsectionTitle", "Major Scenario");
	var scenarioGrid = $.CreatePanel("Panel", quests, "");
	scenarioGrid.AddClass("XHSDevToolsGrid");
	XHSDevToolsMakeButton(scenarioGrid, "Ramero & Baristol", "Accent", function() {
		XHSDevToolsSend("trigger_event", { event: "ramero_baristol" });
	});
	XHSDevToolsMakeButton(scenarioGrid, "Muradin", "Accent", function() {
		XHSDevToolsSend("trigger_event", { event: "muradin" });
	});
	XHSDevToolsMakeButton(scenarioGrid, "Farm", "Accent", function() {
		XHSDevToolsSend("trigger_event", { event: "farm" });
	});
	XHSDevToolsMakeButton(scenarioGrid, "Sogat", "Accent", function() {
		XHSDevToolsSend("trigger_event", { event: "sogat" });
	});
	XHSDevToolsMakeButton(scenarioGrid, "Final Wave", "Danger", function() {
		XHSDevToolsSend("start_final_wave", {});
	});

	var fragmentSection = XHSDevToolsMakeSection(parent, "Fragment Quests");
	var fragmentState = XHSDevToolsState.fragment_quests || {};
	XHSDevToolsMakeLabel(fragmentSection, "XHSDevToolsMuted", "Backend: " + (fragmentState.backend_status || "pending") + " / confirmed +" + (fragmentState.confirmed_total_fragments || 0) + " fragments");
	if (fragmentState.last_payload_dump && fragmentState.last_payload_dump.version) {
		var dump = fragmentState.last_payload_dump;
		XHSDevToolsMakeLabel(fragmentSection, "XHSDevToolsMuted", "Last payload: v" + dump.version + " / " + (dump.selected_count || 0) + " quests / " + (dump.event_count || 0) + " events / +" + (dump.total_fragments_preview || 0) + " preview");
	}

	var selected = fragmentState.selected || {};
	for (var slot = 1; slot <= 3; slot++) {
		var quest = selected[String(slot)];
		if (quest) {
			XHSDevToolsMakeLabel(fragmentSection, "XHSDevToolsMuted", slot + ". " + quest.title + " - " + (quest.stars || 0) + " stars - " + (quest.progress_text || "0"));
		}
	}

	var fragmentGrid = $.CreatePanel("Panel", fragmentSection, "");
	fragmentGrid.AddClass("XHSDevToolsGrid");
	XHSDevToolsMakeButton(fragmentGrid, "Reroll", "Accent", function() {
		XHSDevToolsSend("fragment_quests_reroll", {});
	});
	XHSDevToolsMakeButton(fragmentGrid, "Force Farm", "Small", function() {
		XHSDevToolsSend("fragment_quest_force", { slot: 2, template_id: "farm_event_kills", target_id: "team" });
	});
	XHSDevToolsMakeButton(fragmentGrid, "Force Muradin", "Small", function() {
		XHSDevToolsSend("fragment_quest_force", { slot: 2, template_id: "muradin_death_cap", target_id: "team" });
	});
	XHSDevToolsMakeButton(fragmentGrid, "Force Ramero", "Small", function() {
		XHSDevToolsSend("fragment_quest_force", { slot: 2, template_id: "arena_remaining_time", target_id: "ramero_baristol" });
	});
	XHSDevToolsMakeButton(fragmentGrid, "Force Sogat", "Small", function() {
		XHSDevToolsSend("fragment_quest_force", { slot: 2, template_id: "arena_remaining_time", target_id: "sogat" });
	});
	XHSDevToolsMakeButton(fragmentGrid, "Force Grom", "Small", function() {
		XHSDevToolsSend("fragment_quest_force", { slot: 3, template_id: "boss_death_cap", target_id: "grom" });
	});
	XHSDevToolsMakeButton(fragmentGrid, "Force Illidan", "Small", function() {
		XHSDevToolsSend("fragment_quest_force", { slot: 3, template_id: "boss_timer", target_id: "illidan" });
	});
	XHSDevToolsMakeButton(fragmentGrid, "Force LK", "Small", function() {
		XHSDevToolsSend("fragment_quest_force", { slot: 3, template_id: "boss_timer", target_id: "lich_king" });
	});

	var fragmentBackendGrid = $.CreatePanel("Panel", fragmentSection, "");
	fragmentBackendGrid.AddClass("XHSDevToolsGrid");
	XHSDevToolsMakeButton(fragmentBackendGrid, "Backend OK", "Small Accent", function() {
		XHSDevToolsSend("fragment_quest_backend_success", {});
	});
	XHSDevToolsMakeButton(fragmentBackendGrid, "Backend Error", "Small Danger", function() {
		XHSDevToolsSend("fragment_quest_backend_error", {});
	});
	XHSDevToolsMakeButton(fragmentBackendGrid, "Dump Payload", "Small", function() {
		XHSDevToolsSend("fragment_quest_dump_payload", {});
	});

	var fragmentProgressGrid = $.CreatePanel("Panel", fragmentSection, "");
	fragmentProgressGrid.AddClass("XHSDevToolsGrid");
	XHSDevToolsMakeButton(fragmentProgressGrid, "+5M Damage", "Small Accent", function() {
		XHSDevToolsSend("fragment_quest_progress", { metric: "damage", amount: 5000000 });
	});
	XHSDevToolsMakeButton(fragmentProgressGrid, "+500k Heal", "Small Accent", function() {
		XHSDevToolsSend("fragment_quest_progress", { metric: "healing", amount: 500000 });
	});
	XHSDevToolsMakeButton(fragmentProgressGrid, "+10 Potions", "Small", function() {
		XHSDevToolsSend("fragment_quest_progress", { metric: "potions", amount: 10 });
	});
	XHSDevToolsMakeButton(fragmentProgressGrid, "+1 Death", "Small Warn", function() {
		XHSDevToolsSend("fragment_quest_progress", { metric: "death", amount: 1 });
	});
	XHSDevToolsMakeButton(fragmentProgressGrid, "+60 Farm", "Small", function() {
		XHSDevToolsSend("fragment_quest_progress", { metric: "farm_kills", amount: 60 });
	});
	XHSDevToolsMakeButton(fragmentProgressGrid, "+500k Tanked", "Small", function() {
		XHSDevToolsSend("fragment_quest_progress", { metric: "frontline", amount: 500000 });
	});
	XHSDevToolsMakeButton(fragmentProgressGrid, "+1 Tower Kill", "Small Warn", function() {
		XHSDevToolsSend("fragment_quest_progress", { metric: "tower_kills", amount: 1 });
	});
	XHSDevToolsMakeButton(fragmentProgressGrid, "Base 100%", "Small Accent", function() {
		XHSDevToolsSend("fragment_quest_progress", { metric: "base_hp", amount: 100 });
	});

	var fragmentWindowGrid = $.CreatePanel("Panel", fragmentSection, "");
	fragmentWindowGrid.AddClass("XHSDevToolsGrid");
	XHSDevToolsMakeButton(fragmentWindowGrid, "Complete Farm", "Small Accent", function() {
		XHSDevToolsSend("fragment_quest_complete_window", { window: "farm", value: 240 });
	});
	XHSDevToolsMakeButton(fragmentWindowGrid, "Complete Muradin", "Small Accent", function() {
		XHSDevToolsSend("fragment_quest_complete_window", { window: "muradin", value: 0 });
	});
	XHSDevToolsMakeButton(fragmentWindowGrid, "Complete Ramero", "Small Accent", function() {
		XHSDevToolsSend("fragment_quest_complete_window", { window: "ramero", value: 60 });
	});
	XHSDevToolsMakeButton(fragmentWindowGrid, "Complete Sogat", "Small Accent", function() {
		XHSDevToolsSend("fragment_quest_complete_window", { window: "sogat", value: 45 });
	});
	XHSDevToolsMakeButton(fragmentWindowGrid, "Complete Phase2", "Small Accent", function() {
		XHSDevToolsSend("fragment_quest_complete_window", { window: "phase2", value: 180 });
	});
	XHSDevToolsMakeButton(fragmentWindowGrid, "Complete Grom", "Small Accent", function() {
		XHSDevToolsSend("fragment_quest_complete_window", { window: "grom", value: 0 });
	});
	XHSDevToolsMakeButton(fragmentWindowGrid, "Complete Illidan", "Small Accent", function() {
		XHSDevToolsSend("fragment_quest_complete_window", { window: "illidan", value: 120 });
	});
	XHSDevToolsMakeButton(fragmentWindowGrid, "Complete LK", "Small Accent", function() {
		XHSDevToolsSend("fragment_quest_complete_window", { window: "lich_king", value: 270 });
	});
	XHSDevToolsMakeButton(fragmentWindowGrid, "Complete Final", "Small Accent", function() {
		XHSDevToolsSend("fragment_quest_complete_window", { window: "final", value: 100 });
	});

	XHSDevToolsMakeLabel(quests, "XHSDevToolsSubsectionTitle", "Quest State");
	var questGrid = $.CreatePanel("Panel", quests, "");
	questGrid.AddClass("XHSDevToolsQuestGrid");

	var questState = XHSDevToolsState.quests || {};
	for (var key in questState) {
		var quest = questState[key];
		(function(questData) {
			var row = $.CreatePanel("Panel", questGrid, "");
			row.AddClass("XHSDevToolsQuestRow");

			var state = questData.completed ? "done" : (questData.active ? "active" : "idle");
			XHSDevToolsMakeLabel(row, "XHSDevToolsQuestName", questData.label + " (" + state + ")");

			XHSDevToolsMakeButton(row, "Activate", "Small", function() {
				XHSDevToolsSend("activate_quest", { quest: questData.name });
			});
			XHSDevToolsMakeButton(row, "Complete", "Small Warn", function() {
				XHSDevToolsSend("complete_quest", { quest: questData.name });
			});
		})(quest);
	}

}

function XHSDevToolsRenderBosses(parent) {
	var bosses = XHSDevToolsMakeSection(parent, "Bosses");
	XHSDevToolsMakeLabel(bosses, "XHSDevToolsMuted", "Start Test isolates the boss in sandbox. Start Flow launches a campaign checkpoint and lets normal progression continue.");
	var bossGrid = $.CreatePanel("Panel", bosses, "");
	bossGrid.AddClass("XHSDevToolsBossGrid");
	for (var i = 0; i < XHS_DEVTOOLS_BOSSES.length; i++) {
		(function(boss) {
			var activity = XHSDevToolsGetBossActivity(boss);
			var card = $.CreatePanel("Panel", bossGrid, "");
			card.AddClass("XHSDevToolsBossCard");
			card.SetHasClass("Active", activity.active);

			var header = $.CreatePanel("Panel", card, "");
			header.AddClass("XHSDevToolsBossCardHeader");
			XHSDevToolsMakeHeroIcon(header, boss.icon, "");

			var text = $.CreatePanel("Panel", header, "");
			text.AddClass("XHSDevToolsBossText");
			XHSDevToolsMakeLabel(text, "XHSDevToolsBossName", boss.label);
			XHSDevToolsMakeLabel(text, "XHSDevToolsBossStatus", activity.active ? ("Active - " + activity.health + "%") : "Ready");

			XHSDevToolsMakeButton(card, "Start Test", "Accent", function() {
				XHSDevToolsSend("start_boss", { boss: boss.id });
			});
			XHSDevToolsMakeButton(card, "Start Flow", "Flow", function() {
				XHSDevToolsSend("start_boss_flow", { boss: boss.id });
			});
		})(XHS_DEVTOOLS_BOSSES[i]);
	}

	var activeBosses = XHSDevToolsMakeSection(parent, "Active Bosses");
	var bossesState = XHSDevToolsState.bosses || {};
	var count = 0;
	for (var bossKey in bossesState) {
		count++;
		var active = bossesState[bossKey];
		var health = active.max_health > 0 ? Math.floor((active.health / active.max_health) * 100) : 0;
		XHSDevToolsMakeLabel(activeBosses, "XHSDevToolsBossLine", active.name + " - " + health + "%");
	}
	if (count === 0) {
		XHSDevToolsMakeLabel(activeBosses, "XHSDevToolsMuted", "No tracked boss alive.");
	}
}

function XHSDevToolsRenderLanes(parent) {
	var laneSection = XHSDevToolsMakeSection(parent, "Lane Control");
	var lanes = XHSDevToolsState.lanes || {};

	for (var i = 1; i <= 8; i++) {
		(function(laneNumber) {
			var lane = lanes[String(laneNumber)] || { enabled: false, level: 1, rax_alive: true };
			var row = $.CreatePanel("Panel", laneSection, "");
			row.AddClass("XHSDevToolsLaneRow");

			XHSDevToolsMakeLabel(row, "XHSDevToolsLaneName", "Lane " + laneNumber);
			XHSDevToolsMakeButton(row, lane.enabled ? "Disable" : "Enable", "Small", function() {
				XHSDevToolsSend("set_lane", { lane: laneNumber, enabled: lane.enabled ? 0 : 1 });
			});
			XHSDevToolsMakeButton(row, lane.rax_alive ? "Rax dead" : "Rax alive", "Small", function() {
				XHSDevToolsSend("set_lane", { lane: laneNumber, rax_alive: lane.rax_alive ? 0 : 1 });
			});

			for (var level = 1; level <= 4; level++) {
				(function(lvl) {
					var levelButton = XHSDevToolsMakeButton(row, "L" + lvl, "Tiny", function() {
						XHSDevToolsSend("set_lane", { lane: laneNumber, level: lvl });
					});
					levelButton.SetHasClass("Active", lane.level === lvl);
				})(level);
			}

			XHSDevToolsMakeButton(row, "Wave", "Small Accent", function() {
				XHSDevToolsSend("spawn_lane_wave", { lane: laneNumber });
			});
		})(i);
	}

	var waveSection = XHSDevToolsMakeSection(parent, "Wave Tools");
	XHSDevToolsMakeLabel(waveSection, "XHSDevToolsMuted", "Use the global Sandbox toggle above to stop automatic waves and timers. Manual triggers still work.");
	var grid = $.CreatePanel("Panel", waveSection, "");
	grid.AddClass("XHSDevToolsGrid");
	XHSDevToolsMakeButton(grid, "Activate Phase 2", "Warn", function() {
		XHSDevToolsSend("start_phase2", {});
	});
	XHSDevToolsMakeButton(grid, "Spawn Enabled Lanes", "", function() {
		XHSDevToolsSend("spawn_lane_wave", { lane: 0 });
	});
	XHSDevToolsMakeButton(grid, "Phase 2 Left", "Small Accent", function() {
		XHSDevToolsSend("spawn_phase2_wave", { side: "left" });
	});
	XHSDevToolsMakeButton(grid, "Phase 2 Right", "Small Accent", function() {
		XHSDevToolsSend("spawn_phase2_wave", { side: "right" });
	});
	XHSDevToolsMakeButton(grid, "Phase 2 Both", "Accent", function() {
		XHSDevToolsSend("spawn_phase2_wave", { side: "both" });
	});
	for (var wave = 1; wave <= 8; wave++) {
		(function(w) {
			XHSDevToolsMakeButton(grid, "Special " + w, "Small", function() {
				XHSDevToolsSend("special_wave", { wave: w });
			});
		})(wave);
	}
}

function XHSDevToolsRenderTimers(parent) {
	var difficulty = XHSDevToolsMakeSection(parent, "Difficulty");
	XHSDevToolsMakeLabel(difficulty, "XHSDevToolsMuted", "Changing difficulty respawns active dev boss tests so the fight reloads cleanly.");
	var difficultyGrid = $.CreatePanel("Panel", difficulty, "");
	difficultyGrid.AddClass("XHSDevToolsGrid");
	for (var d = 0; d < XHS_DEVTOOLS_DIFFICULTIES.length; d++) {
		(function(option) {
			var button = XHSDevToolsMakeButton(difficultyGrid, option.label, "", function() {
				XHSDevToolsSend("set_difficulty", { difficulty: option.id, respawn_bosses: 1 });
			});
			button.SetHasClass("Active", Number(XHSDevToolsState.difficulty || 1) === option.id);
		})(XHS_DEVTOOLS_DIFFICULTIES[d]);
	}

	var timers = XHSDevToolsMakeSection(parent, "Timers");
	var timerGrid = $.CreatePanel("Panel", timers, "");
	timerGrid.AddClass("XHSDevToolsGrid");
	XHSDevToolsMakeButton(timerGrid, "Pause Timers", "", function() {
		XHSDevToolsSend("pause_timers", {});
	});
	XHSDevToolsMakeButton(timerGrid, "Resume Timers", "", function() {
		XHSDevToolsSend("resume_timers", {});
	});
	XHSDevToolsMakeButton(timerGrid, "Final Countdown", "Warn", function() {
		XHSDevToolsSend("trigger_event", { event: "final_countdown" });
	});

	var phase = XHSDevToolsMakeSection(parent, "Phase");
	var phaseGrid = $.CreatePanel("Panel", phase, "");
	phaseGrid.AddClass("XHSDevToolsGrid");
	for (var i = 1; i <= 3; i++) {
		(function(phaseNumber) {
			var button = XHSDevToolsMakeButton(phaseGrid, "Phase " + phaseNumber, "", function() {
				XHSDevToolsSend("set_phase", { phase: phaseNumber });
			});
			button.SetHasClass("Active", XHSDevToolsState.game_phase === phaseNumber);
		})(i);
	}
}

function XHSDevToolsBotTableValues(table) {
	var values = [];
	for (var key in (table || {})) {
		if (table[key] !== undefined && table[key] !== null) {
			values.push({ key: key, value: table[key] });
		}
	}
	values.sort(function(a, b) {
		var aNumber = Number(a.key);
		var bNumber = Number(b.key);
		if (!isNaN(aNumber) && !isNaN(bNumber)) {
			return aNumber - bNumber;
		}
		return String(a.key) < String(b.key) ? -1 : 1;
	});
	return values;
}

function XHSDevToolsBotText(value, fallback) {
	if (value === undefined || value === null || String(value).length === 0) {
		return fallback || "-";
	}
	return String(value);
}

function XHSDevToolsBotHeroName(heroName) {
	heroName = XHSDevToolsBotText(heroName, "");
	if (!heroName) {
		return "No hero";
	}
	var localized = $.Localize("#" + heroName);
	if (localized && localized !== ("#" + heroName)) {
		return localized;
	}
	return heroName.replace(/^npc_dota_hero_/, "").replace(/_/g, " ").toUpperCase();
}

function XHSDevToolsBotVector(vector) {
	if (!vector) {
		return "-";
	}
	return Math.floor(Number(vector.x) || 0) + ", " +
		Math.floor(Number(vector.y) || 0) + ", " +
		Math.floor(Number(vector.z) || 0);
}

function XHSDevToolsBotItemName(itemName) {
	itemName = XHSDevToolsBotText(itemName, "");
	if (!itemName) {
		return "-";
	}
	return itemName
		.replace(/^item_recipe_/, "")
		.replace(/^item_xhs_/, "")
		.replace(/^item_/, "")
		.replace(/_/g, " ");
}

function XHSDevToolsBotNeedName(needName) {
	return XHSDevToolsBotText(needName, "")
		.replace(/_/g, " ")
		.toUpperCase();
}

function XHSDevToolsBotLoadout(loadout) {
	var entries = XHSDevToolsBotTableValues(loadout || {});
	var names = [];
	for (var i = 0; i < entries.length && i < 6; i++) {
		names.push(XHSDevToolsBotItemName(entries[i].value));
	}
	return names.length > 0 ? names.join(" | ") : "-";
}

function XHSDevToolsBotItemCandidates(candidates) {
	var entries = XHSDevToolsBotTableValues(candidates || {});
	var formatted = [];
	for (var i = 0; i < entries.length && i < 3; i++) {
		var candidate = entries[i].value || {};
		var score = Number(candidate.score);
		formatted.push(
			XHSDevToolsBotItemName(candidate.item) +
				" " + (isNaN(score) ? "-" : score.toFixed(1))
		);
	}
	return formatted.length > 0 ? formatted.join(" > ") : "-";
}

function XHSDevToolsMakeBotMetric(parent, key, value, wide) {
	var metric = $.CreatePanel("Panel", parent, "");
	metric.AddClass("XHSDevToolsBotMetric");
	metric.SetHasClass("Wide", wide === true);
	XHSDevToolsMakeLabel(metric, "XHSDevToolsBotMetricKey", key);
	XHSDevToolsMakeLabel(metric, "XHSDevToolsBotMetricValue", XHSDevToolsBotText(value, "-"));
	return metric;
}

function XHSDevToolsRenderBotTopActions(parent, debug) {
	var actions = XHSDevToolsBotTableValues(debug.top_actions || {});
	var actionList = $.CreatePanel("Panel", parent, "");
	actionList.AddClass("XHSDevToolsBotActionsList");
	if (actions.length === 0) {
		XHSDevToolsMakeLabel(actionList, "XHSDevToolsBotActionLine", "No scored action yet.");
		return;
	}

	for (var i = 0; i < actions.length && i < 3; i++) {
		var action = actions[i].value || {};
		var score = Number(action.score);
		var scoreText = isNaN(score) ? "-" : score.toFixed(2);
		XHSDevToolsMakeLabel(
			actionList,
			"XHSDevToolsBotActionLine",
			(i + 1) + ". " + XHSDevToolsBotText(action.id, "unknown") +
				" [" + scoreText + "] - " + XHSDevToolsBotText(action.reason, "no reason")
		);
	}
}

function XHSDevToolsRenderBotCard(parent, rosterEntry) {
	var bot = rosterEntry.value || {};
	var playerID = Number(bot.player_id);
	if (isNaN(playerID)) {
		playerID = Number(rosterEntry.key);
	}
	var debug = XHSDevToolsBotDebug[String(playerID)] || {};

	var card = $.CreatePanel("Panel", parent, "");
	card.AddClass("XHSDevToolsBotCard");
	card.SetHasClass("HasError", !!debug.error);

	var header = $.CreatePanel("Panel", card, "");
	header.AddClass("XHSDevToolsBotCardHeader");
	XHSDevToolsMakeHeroIcon(header, bot.hero || debug.hero, "XHSDevToolsBotHero");

	var headerText = $.CreatePanel("Panel", header, "");
	headerText.AddClass("XHSDevToolsBotHeaderText");
	XHSDevToolsMakeLabel(headerText, "XHSDevToolsBotName", XHSDevToolsBotText(bot.name, "XHS Bot " + (playerID + 1)));
	XHSDevToolsMakeLabel(
		headerText,
		"XHSDevToolsBotMeta",
		"#" + playerID + " / " +
			XHSDevToolsBotHeroName(bot.hero || debug.hero) + " / " +
			XHSDevToolsBotText(bot.difficulty || debug.difficulty, "normal") + " / " +
			XHSDevToolsBotText(bot.role || debug.role, "unassigned")
	);

	var stateRow = $.CreatePanel("Panel", card, "");
	stateRow.AddClass("XHSDevToolsBotStateRow");
	XHSDevToolsMakeLabel(stateRow, "XHSDevToolsBotState", XHSDevToolsBotText(debug.state, "INITIALIZING"));
	XHSDevToolsMakeLabel(stateRow, "XHSDevToolsBotGoal", "Goal: " + XHSDevToolsBotText(debug.goal, "-"));

	var metrics = $.CreatePanel("Panel", card, "");
	metrics.AddClass("XHSDevToolsBotMetrics");
	XHSDevToolsMakeBotMetric(
		metrics,
		"Encounter",
		XHSDevToolsBotText(debug.encounter_mode, "none") +
			" / " + XHSDevToolsBotText(debug.encounter_transitions, "0") + " transitions",
		true
	);
	XHSDevToolsMakeBotMetric(metrics, "Target", debug.target || debug.target_entindex, true);
	XHSDevToolsMakeBotMetric(metrics, "Anchor", XHSDevToolsBotVector(debug.anchor), true);
	XHSDevToolsMakeBotMetric(metrics, "Lane / side", XHSDevToolsBotText(debug.lane, "0") + " / " + XHSDevToolsBotText(debug.side, "-"), false);
	XHSDevToolsMakeBotMetric(metrics, "Idle", XHSDevToolsBotText(debug.idle_seconds, "0") + "s", false);
	XHSDevToolsMakeBotMetric(metrics, "Orders", debug.orders, false);
	XHSDevToolsMakeBotMetric(metrics, "Targets", debug.target_changes, false);
	XHSDevToolsMakeBotMetric(metrics, "Unstuck", debug.stuck_recoveries, false);
	XHSDevToolsMakeBotMetric(metrics, "Danger hits", debug.danger_hits, false);
	XHSDevToolsMakeBotMetric(
		metrics,
		"Tomes / allowance",
		XHSDevToolsBotText(debug.tomes_bought, "0") + " / " +
			XHSDevToolsBotText(debug.tome_allowance, "0"),
		false
	);
	XHSDevToolsMakeBotMetric(metrics, "Connection", debug.connection_state, false);
	XHSDevToolsMakeBotMetric(
		metrics,
		"Economy / reserve",
		XHSDevToolsBotText(debug.economy_phase, "-") + " / " +
			XHSDevToolsBotText(debug.opening_stage, "complete") + " / " +
			XHSDevToolsBotText(debug.economy_reserve_gold, "0") + "g / " +
			XHSDevToolsBotText(debug.attack_dps, "0") + " DPS",
		false
	);
	XHSDevToolsMakeBotMetric(
		metrics,
		"Slots / stash",
		XHSDevToolsBotText(debug.active_item_slots, "0") + "/6 active, " +
			XHSDevToolsBotText(debug.inventory_item_slots, "0") + "/9 carried, " +
			XHSDevToolsBotText(debug.stash_item_count, "0") + "/6 stash",
		false
	);
	var dominantItemNeed = XHSDevToolsBotNeedName(debug.item_dominant_need);
	var dominantItemNeedValue = Math.max(
		0,
		Number(debug.item_dominant_need_value) || 0
	);
	XHSDevToolsMakeBotMetric(
		metrics,
		"Next item",
		XHSDevToolsBotItemName(debug.planned_item) + " [" +
			XHSDevToolsBotText(debug.planned_item_family, "-") + " / " +
			XHSDevToolsBotText(debug.planned_item_score, "0") + "]" +
			(Number(debug.replacement_required || 0) === 1 ? " [replace]" : "") +
			(dominantItemNeed
				? " | Need " + dominantItemNeed + " " +
					dominantItemNeedValue.toFixed(2)
				: ""),
		true
	);
	var shopRoute = debug.shopping_item
		? XHSDevToolsBotItemName(debug.shopping_item) + " @ " +
			XHSDevToolsBotText(debug.shopping_shop, "home") +
			(Number(debug.shopping_urgent || 0) === 1 ? " [urgent]" : "")
		: "idle";
	var lastShopPurchase = debug.last_purchase_item
		? XHSDevToolsBotItemName(debug.last_purchase_item) + " @ " +
			XHSDevToolsBotText(
				debug.last_purchase_shop_kind,
				debug.last_purchase_shop || "unknown"
			) + " (" +
			XHSDevToolsBotText(debug.last_purchase_shop_distance, "?") + "u)"
		: "none";
	XHSDevToolsMakeBotMetric(
		metrics,
		"Shop route / last",
		shopRoute + " | " + lastShopPurchase +
			(Number(debug.shop_purchase_violation_count || 0) > 0
				? " | VIOLATIONS " + debug.shop_purchase_violation_count
				: ""),
		true
	);
	XHSDevToolsMakeBotMetric(
		metrics,
		"Stock / targets",
		"HP " + XHSDevToolsBotText(debug.health_potion_charges, "0") + "/" +
			XHSDevToolsBotText(debug.health_potion_target, "0") +
			" | MP " + XHSDevToolsBotText(debug.mana_potion_charges, "0") + "/" +
			XHSDevToolsBotText(debug.mana_potion_target, "0") +
			" | Ankh " + XHSDevToolsBotText(debug.ankh_charges, "0") + "/" +
			XHSDevToolsBotText(debug.ankh_target, "0") +
			" | Furbolg " + (debug.has_owned_furbolg ? "yes" : "no") +
			" | Orbs " + XHSDevToolsBotText(debug.orb_active_family_count, "0") + "/" +
			XHSDevToolsBotText(debug.orb_owned_family_count, "0") +
			(debug.orb_repair_pending_count > 0
				? " (repair " + XHSDevToolsBotText(debug.orb_repair_pending_count, "0") + ")"
				: ""),
		true
	);

	var decisions = $.CreatePanel("Panel", card, "");
	decisions.AddClass("XHSDevToolsBotDecisions");
	var replacementSummary = Number(debug.items_replaced || 0) > 0
		? " | replacements " + XHSDevToolsBotText(debug.items_replaced, "0") +
			" (last " + XHSDevToolsBotItemName(debug.last_replaced_item) +
			", +" + XHSDevToolsBotText(debug.replacement_gold_recovered, "0") + "g)"
		: "";
	XHSDevToolsMakeLabel(
		decisions,
		"XHSDevToolsBotDecisionLine",
		"Decision: " + XHSDevToolsBotText(debug.last_decision, "-") +
			" - " + XHSDevToolsBotText(debug.last_decision_reason, "no reason")
	);
	XHSDevToolsMakeLabel(
		decisions,
		"XHSDevToolsBotDecisionLine",
		"Order: " + XHSDevToolsBotText(debug.last_order, "-")
	);
	XHSDevToolsMakeLabel(
		decisions,
		"XHSDevToolsBotDecisionLine",
		"Ability: " + XHSDevToolsBotText(debug.last_ability, "-") +
			" - " + XHSDevToolsBotText(debug.last_ability_reason, "no reason")
	);
	XHSDevToolsMakeLabel(
		decisions,
		"XHSDevToolsBotDecisionLine",
		"Rejected: " + XHSDevToolsBotText(debug.last_rejected_action, "-")
	);
	XHSDevToolsMakeLabel(
		decisions,
		"XHSDevToolsBotDecisionLine",
		"Economy: " + XHSDevToolsBotText(debug.last_item_action, "-") +
			" / " + XHSDevToolsBotText(debug.last_item_rejection, "accepted") +
			replacementSummary
	);
	XHSDevToolsMakeLabel(
		decisions,
		"XHSDevToolsBotDecisionLine",
		"Why: " + XHSDevToolsBotText(debug.planned_item_reason, "-")
	);
	XHSDevToolsMakeLabel(
		decisions,
		"XHSDevToolsBotDecisionLine",
		"Loadout: " + XHSDevToolsBotLoadout(debug.planned_loadout)
	);
	XHSDevToolsMakeLabel(
		decisions,
		"XHSDevToolsBotDecisionLine",
		"Candidates: " + XHSDevToolsBotItemCandidates(debug.item_candidates)
	);

	XHSDevToolsMakeLabel(card, "XHSDevToolsBotSubheading", "TOP ACTIONS");
	XHSDevToolsRenderBotTopActions(card, debug);

	var engineKnown = debug.engine_fake_client !== undefined && debug.engine_fake_client !== null;
	var teamKnown = debug.engine_team_verified !== undefined && debug.engine_team_verified !== null;
	var engineOk = engineKnown && (Number(debug.engine_fake_client) === 1 || debug.engine_fake_client === true);
	var teamOk = teamKnown && (Number(debug.engine_team_verified) === 1 || debug.engine_team_verified === true);
	var engine = XHSDevToolsMakeLabel(
		card,
		"XHSDevToolsBotEngine",
		"Engine bot: " + (engineKnown ? (engineOk ? "YES" : "NO") : "...") +
			" / Radiant: " + (teamKnown ? (teamOk ? "YES" : "NO") : "...")
	);
	engine.SetHasClass("Error", (engineKnown && !engineOk) || (teamKnown && !teamOk));

	if (debug.error) {
		XHSDevToolsMakeLabel(card, "XHSDevToolsBotError", String(debug.error));
	}

	var goalGrid = $.CreatePanel("Panel", card, "");
	goalGrid.AddClass("XHSDevToolsBotGoalGrid");
	var goals = [
		{ id: "auto", label: "Auto" },
		{ id: "defend_base", label: "Base" },
		{ id: "regroup", label: "Regroup" },
		{ id: "fight_boss", label: "Boss" },
		{ id: "hold", label: "Hold" }
	];
	for (var i = 0; i < goals.length; i++) {
		(function(goal) {
			XHSDevToolsMakeButton(goalGrid, goal.label, "Tiny", function() {
				XHSDevToolsSend("bot_force_goal", { player_id: playerID, goal: goal.id });
			});
		})(goals[i]);
	}
}

function XHSDevToolsRenderBots(parent) {
	var controls = XHSDevToolsMakeSection(parent, "Allied Bot Control");
	var configuredCount = Number(XHSDevToolsBotConfig.bot_count || 0);
	var rosterCount = Number(XHSDevToolsBotRoster.count || 0);
	XHSDevToolsMakeLabel(
		controls,
		"XHSDevToolsMuted",
		"Config: " + configuredCount + " " +
			XHSDevToolsBotText(XHSDevToolsBotConfig.ai_difficulty, "normal") + " / " +
			XHSDevToolsBotText(XHSDevToolsBotConfig.composition, "balanced") +
			" | roster " + rosterCount +
			" | server " + XHSDevToolsBotText(XHSDevToolsBotConfig.status, "waiting")
	);
	if (XHSDevToolsBotConfig.error) {
		XHSDevToolsMakeLabel(controls, "XHSDevToolsBotError", String(XHSDevToolsBotConfig.error));
	}

	var controlGrid = $.CreatePanel("Panel", controls, "");
	controlGrid.AddClass("XHSDevToolsGrid");
	XHSDevToolsMakeButton(controlGrid, "Pause AI", "Warn", function() {
		XHSDevToolsSend("bot_pause", {});
	});
	XHSDevToolsMakeButton(controlGrid, "Resume AI", "Accent", function() {
		XHSDevToolsSend("bot_resume", {});
	});
	XHSDevToolsMakeButton(controlGrid, "Overlay ON", "", function() {
		XHSDevToolsSend("bot_overlay", { enabled: 1 });
	});
	XHSDevToolsMakeButton(controlGrid, "Overlay OFF", "", function() {
		XHSDevToolsSend("bot_overlay", { enabled: 0 });
	});
	XHSDevToolsMakeButton(controlGrid, "Reset AI", "Danger", function() {
		XHSDevToolsSend("bot_reset", {});
	});

	var scenarios = XHSDevToolsMakeSection(parent, "Bot Scenarios");
	XHSDevToolsMakeLabel(scenarios, "XHSDevToolsMuted", "Focused test hooks for danger response, assignment rebuild, stuck recovery, and respawn/rebind.");
	var scenarioGrid = $.CreatePanel("Panel", scenarios, "");
	scenarioGrid.AddClass("XHSDevToolsGrid");
	var scenarioOptions = [
		{ id: "danger", label: "Danger" },
		{ id: "reassign", label: "Reassign" },
		{ id: "stuck", label: "Stuck" },
		{ id: "respawn", label: "Respawn" }
	];
	for (var scenarioIndex = 0; scenarioIndex < scenarioOptions.length; scenarioIndex++) {
		(function(scenario) {
			XHSDevToolsMakeButton(scenarioGrid, scenario.label, "Small", function() {
				XHSDevToolsSend("bot_run_scenario", { scenario: scenario.id });
			});
		})(scenarioOptions[scenarioIndex]);
	}

	var telemetry = XHSDevToolsMakeSection(parent, "Live Bot Telemetry");
	var rosterEntries = XHSDevToolsBotTableValues(XHSDevToolsBotRoster.players || {});
	if (rosterEntries.length === 0) {
		XHSDevToolsMakeLabel(telemetry, "XHSDevToolsMuted", "No XHS bot is provisioned. Configure allies from the Tools loading screen, then launch.");
		return;
	}

	var cards = $.CreatePanel("Panel", telemetry, "");
	cards.AddClass("XHSDevToolsBotCardGrid");
	for (var botIndex = 0; botIndex < rosterEntries.length; botIndex++) {
		XHSDevToolsRenderBotCard(cards, rosterEntries[botIndex]);
	}
}

function XHSDevToolsRenderPlayers(parent) {
	var players = XHSDevToolsMakeSection(parent, "Player Tools");
	var grid = $.CreatePanel("Panel", players, "");
	grid.AddClass("XHSDevToolsGrid");
	XHSDevToolsMakeButton(grid, "Refresh Heroes", "", function() {
		XHSDevToolsSend("refresh_players", {});
	});
	XHSDevToolsMakeButton(grid, "Max Level", "", function() {
		XHSDevToolsSend("max_level", {});
	});
	XHSDevToolsMakeButton(grid, "+50k Gold", "", function() {
		XHSDevToolsSend("grant_gold", { amount: 50000 });
	});
	XHSDevToolsMakeButton(grid, "+250 Tome Stats", "", function() {
		XHSDevToolsSend("grant_tomes", { amount: 250 });
	});
	XHSDevToolsMakeButton(grid, XHSDevToolsState.invulnerable_players ? "Disable Invuln" : "Enable Invuln", "Warn", function() {
		XHSDevToolsSend("toggle_invulnerable", {});
	});

	var donator = XHSDevToolsMakeSection(parent, "Temporary Donator Status");
	var localPlayerID = Players.GetLocalPlayer();
	var donatorStatuses = XHSDevToolsState.donator_statuses || {};
	var current = donatorStatuses[String(localPlayerID)] || {};
	var hasOverride = current.has_override === true;
	var currentStatus = Number(current.status || 0);
	var temporaryStatus = hasOverride ? Number(current.temporary_status || 0) : null;
	XHSDevToolsMakeLabel(donator, "XHSDevToolsMuted", "Current: " + currentStatus + (hasOverride ? " temporary" : " API"));

	var donatorGrid = $.CreatePanel("Panel", donator, "");
	donatorGrid.AddClass("XHSDevToolsGrid");
	for (var i = 0; i < XHS_DEVTOOLS_DONATOR_STATUSES.length; i++) {
		(function(option) {
			var button = XHSDevToolsMakeButton(donatorGrid, option.label, "Small", function() {
				XHSDevToolsSend("set_temporary_donator_status", { status: option.id });
			});
			button.SetHasClass("Active", hasOverride && temporaryStatus === option.id);
		})(XHS_DEVTOOLS_DONATOR_STATUSES[i]);
	}

	XHSDevToolsMakeButton(donatorGrid, "Restore API", "Small Warn", function() {
		XHSDevToolsSend("set_temporary_donator_status", { clear: 1 });
	});
}

function XHSDevToolsReadClientHealthBarOffset(entIndex, fallback) {
	try {
		if (typeof Entities.GetHealthBarOffset === "function" && Entities.IsValidEntity(Number(entIndex))) {
			var value = Number(Entities.GetHealthBarOffset(Number(entIndex)));
			if (isFinite(value)) {
				return value;
			}
		}
	} catch (error) {}
	return Number(fallback) || 0;
}

function XHSDevToolsRenderOverheadOffsets(parent) {
	var section = XHSDevToolsMakeSection(parent, "Live unit overhead offsets");
	XHSDevToolsMakeLabel(section, "XHSDevToolsMuted", "Values are fetched from living entities. Apply updates every living instance of the same name and type for this Tools match; Reset restores the unit KV value.");

	var allRows = XHSDevToolsBotTableValues(XHSDevToolsState.overhead_offsets || {});
	var filters = [
		{ id: "players", label: "Players" },
		{ id: "considered_heroes", label: "Considered heroes" },
		{ id: "units", label: "Units" }
	];
	var filterBar = $.CreatePanel("Panel", section, "");
	filterBar.AddClass("XHSDevToolsOverheadFilters");
	for (var filterIndex = 0; filterIndex < filters.length; filterIndex++) {
		(function(filter) {
			var count = 0;
			for (var rowIndex = 0; rowIndex < allRows.length; rowIndex++) {
				var candidate = allRows[rowIndex].value || {};
				if (candidate.unit_type === filter.id) count += Number(candidate.instances || 0);
			}
			var button = XHSDevToolsMakeButton(filterBar, filter.label + " (" + count + ")", "Small", function() {
				XHSDevToolsOverheadFilter = filter.id;
				XHSDevToolsRender();
			});
			button.SetHasClass("Active", XHSDevToolsOverheadFilter === filter.id);
		})(filters[filterIndex]);
	}

	var refresh = XHSDevToolsMakeButton(section, "Fetch current", "Accent", function() {
		XHSDevToolsRequestState();
	});
	refresh.AddClass("XHSDevToolsOverheadRefresh");
	var selectionBars = XHSDevToolsMakeButton(section, "Add custom bars to selection", "Accent", function() {
		XHSDevToolsSend("apply_selection_health_bars", {});
	});
	selectionBars.AddClass("XHSDevToolsSelectionHealthBars");
	selectionBars.SetHasClass("Active", XHSDevToolsState.selection_health_bars_enabled === true);

	var rows = [];
	for (var i = 0; i < allRows.length; i++) {
		if ((allRows[i].value || {}).unit_type === XHSDevToolsOverheadFilter) {
			rows.push(allRows[i]);
		}
	}
	if (rows.length === 0) {
		XHSDevToolsMakeLabel(section, "XHSDevToolsMuted", "No living entity found for this type.");
		return;
	}

	var table = $.CreatePanel("Panel", section, "");
	table.AddClass("XHSDevToolsOverheadTable");
	for (var i = 0; i < rows.length; i++) {
		(function(row) {
			row = row.value || {};
			var line = $.CreatePanel("Panel", table, "");
			line.AddClass("XHSDevToolsOverheadRow");
			line.SetHasClass("HasOverride", row.has_override === true);

			var identity = $.CreatePanel("Panel", line, "");
			identity.AddClass("XHSDevToolsOverheadIdentity");
			XHSDevToolsMakeLabel(identity, "XHSDevToolsOverheadName", String(row.unit_name || "unknown"));
			var observed = XHSDevToolsReadClientHealthBarOffset(row.entindex, row.current_offset);
			var controlValue = row.has_override ? Number(row.current_offset) : observed;
			XHSDevToolsMakeLabel(identity, "XHSDevToolsOverheadMeta", row.instances + " alive  |  KV " + row.base_offset + "  |  live " + observed + (row.has_override ? "  |  target " + controlValue : ""));

			var minusTen = XHSDevToolsMakeButton(line, "-10", "Tiny", function() {
				XHSDevToolsSend("set_overhead_offset", { unit_type: row.unit_type, unit_name: row.unit_name, value: controlValue - 10 });
			});
			minusTen.AddClass("XHSDevToolsOverheadStep");

			var entry = $.CreatePanel("TextEntry", line, "");
			entry.AddClass("XHSDevToolsOverheadEntry");
			entry.text = String(controlValue);
			entry.textmode = "numeric";
			entry.maxchars = 4;

			var plusTen = XHSDevToolsMakeButton(line, "+10", "Tiny", function() {
				XHSDevToolsSend("set_overhead_offset", { unit_type: row.unit_type, unit_name: row.unit_name, value: controlValue + 10 });
			});
			plusTen.AddClass("XHSDevToolsOverheadStep");

			var apply = XHSDevToolsMakeButton(line, "Apply", "Small Accent", function() {
				XHSDevToolsSend("set_overhead_offset", { unit_type: row.unit_type, unit_name: row.unit_name, value: Number(entry.text) });
			});
			apply.AddClass("XHSDevToolsOverheadApply");
			entry.SetPanelEvent("ontextentrysubmit", function() {
				XHSDevToolsSend("set_overhead_offset", { unit_type: row.unit_type, unit_name: row.unit_name, value: Number(entry.text) });
			});

			var reset = XHSDevToolsMakeButton(line, "Reset KV", "Small", function() {
				XHSDevToolsSend("reset_overhead_offset", { unit_type: row.unit_type, unit_name: row.unit_name });
			});
			reset.AddClass("XHSDevToolsOverheadReset");
		})(rows[i]);
	}
}

function XHSDevToolsRenderUIPreview(parent) {
	var dialog = XHSDevToolsMakeSection(parent, "VIP Dialog Preview");
	XHSDevToolsMakeLabel(dialog, "XHSDevToolsMuted", "Client-only layout fixtures. They do not advance quests or alter campaign state.");

	var grid = $.CreatePanel("Panel", dialog, "");
	grid.AddClass("XHSDevToolsGrid");
	XHSDevToolsMakeButton(grid, "NEXT", "", function() {
		XHSDevToolsSend("preview_vip_dialog", { mode: "next", player_count: 1 });
	});
	XHSDevToolsMakeButton(grid, "READY · 1 HERO", "Accent", function() {
		XHSDevToolsSend("preview_vip_dialog", { mode: "ready", player_count: 1 });
	});
	XHSDevToolsMakeButton(grid, "READY · 4 HEROES", "Accent", function() {
		XHSDevToolsSend("preview_vip_dialog", { mode: "ready", player_count: 4 });
	});
	XHSDevToolsMakeButton(grid, "READY · 8 HEROES", "Accent", function() {
		XHSDevToolsSend("preview_vip_dialog", { mode: "ready", player_count: 8 });
	});
	XHSDevToolsMakeButton(grid, "CLOSE PREVIEW", "Warn", function() {
		XHSDevToolsSend("close_vip_dialog_preview", {});
	});

	var cinematic = XHSDevToolsMakeSection(parent, "XHS Cinematic Diagnostics");
	XHSDevToolsMakeLabel(cinematic, "XHSDevToolsMuted", "Client buttons bypass the server event path. Server buttons validate XHSCinematics and custom game event delivery.");

	var clientGrid = $.CreatePanel("Panel", cinematic, "");
	clientGrid.AddClass("XHSDevToolsGrid");
	XHSDevToolsMakeButton(clientGrid, "CLIENT BARS", "Accent", function() {
		XHSDevToolsBeginClientCinematic({
			id: "xhs_dev_client_bars",
			hide_hud: 0,
			letterbox_pct: 10,
			transition: 0.5
		});
	});
	XHSDevToolsMakeButton(clientGrid, "CLIENT TITLE", "Accent", function() {
		XHSDevToolsBeginClientCinematic({
			id: "xhs_dev_client_title",
			hide_hud: 0,
			letterbox_pct: 10,
			transition: 0.5,
			title: "X HERO SIEGE",
			subtitle: "Client-side cinematic diagnostic"
		});
	});
	XHSDevToolsMakeButton(clientGrid, "CLIENT FULL 5S", "Warn", function() {
		XHSDevToolsBeginClientCinematic({
			id: "xhs_dev_client_full",
			hide_hud: 1,
			letterbox_pct: 10,
			transition: 0.75,
			duration: 5,
			title: "FINAL WAVE",
			subtitle: "HUD restore should occur automatically"
		});
	});
	XHSDevToolsMakeButton(clientGrid, "CLIENT END", "Danger", XHSDevToolsEndClientCinematic);
	XHSDevToolsMakeButton(clientGrid, "SERVER BARS", "", function() {
		XHSDevToolsSend("preview_cinematic", { mode: "bars" });
	});
	XHSDevToolsMakeButton(clientGrid, "SERVER TITLE", "", function() {
		XHSDevToolsSend("preview_cinematic", { mode: "title" });
	});
	XHSDevToolsMakeButton(clientGrid, "SERVER FULL 5S", "Warn", function() {
		XHSDevToolsSend("preview_cinematic", { mode: "full" });
	});
	XHSDevToolsMakeButton(clientGrid, "FINAL PRESET 8S", "Warn", function() {
		XHSDevToolsSend("preview_cinematic", { mode: "final_wave" });
	});
	XHSDevToolsMakeButton(clientGrid, "SERVER END", "Danger", function() {
		XHSDevToolsSend("end_cinematic_preview", {});
	});
}

function XHSDevToolsBattlepassValues(table) {
	var entries = XHSDevToolsBotTableValues(table);
	var values = [];
	for (var i = 0; i < entries.length; i++) {
		values.push(entries[i].value);
	}
	return values;
}

function XHSDevToolsResolveBattlepassImage(imagePath) {
	if (!imagePath) {
		return "";
	}
	var raw = String(imagePath).replace(/\\/g, "/");
	var lower = raw.toLowerCase();
	if (lower.indexOf("particles/") === 0 || lower.indexOf(".vpcf") !== -1) {
		return "";
	}
	var cdnMatch = raw.match(/^https?:\/\/cdn\.frostrose-studio\.com\/static\/images\/battlepass\/xhs-4\.0\/([^?#]+)/i);
	if (cdnMatch) {
		var localName = cdnMatch[1]
			.replace(/-v2(?=\.[^.]+$)/i, "")
			.replace(/\.[^.]+$/, "")
			.replace(/-/g, "_");
		return "file://{images}/custom_game/battlepass/" + localName + ".png";
	}
	if (raw.indexOf("file://{images}/") === 0 || raw.indexOf("s2r://panorama/images/") === 0) {
		return raw;
	}
	var normalized = raw
		.replace(/^file:\/\/\{images\}\//, "")
		.replace(/^s2r:\/\/panorama\/images\//, "")
		.replace(/_png\.vtex$/, "")
		.replace(/\.png$/, "");
	if (normalized.indexOf("custom_game/") === 0) {
		return "file://{images}/" + normalized + ".png";
	}
	if (normalized.indexOf("battlepass/") === 0) {
		return "file://{images}/custom_game/" + normalized + ".png";
	}
	var dotaRoots = ["badges/", "compendium/", "econ/", "events/", "game_modes/", "heroes/", "items/", "spellicons/", "status_icons/"];
	for (var i = 0; i < dotaRoots.length; i++) {
		if (normalized.indexOf(dotaRoots[i]) === 0) {
			return "s2r://panorama/images/" + normalized + "_png.vtex";
		}
	}
	return "file://{images}/custom_game/" + normalized + ".png";
}

function XHSDevToolsBattlepassSourceText(reward) {
	var sources = [];
	if (Number(reward.from_shop || 0) === 1) {
		sources.push("SHOP");
	}
	if (Number(reward.from_free || 0) === 1) {
		sources.push("FREE REWARD");
	}
	if (Number(reward.from_premium || 0) === 1) {
		sources.push("PREMIUM REWARD");
	}
	return sources.length ? sources.join(" + ") : "CATALOG";
}

function XHSDevToolsRenderBattlepass(parent) {
	var battlepass = XHSDevToolsState.battlepass || {};
	var families = XHSDevToolsBattlepassValues(battlepass.families);
	var sequences = battlepass.sequences || {};
	var sequence = sequences[String(Players.GetLocalPlayer())] || {};
	var delay = Number(battlepass.delay || 5);

	var controls = XHSDevToolsMakeSection(parent, "Battle Pass Reward Tester");
	XHSDevToolsMakeLabel(
		controls,
		"XHSDevToolsMuted",
		"Merged live shop + free/premium rewards. Images use the shipped catalog art; family tests play each compatible item in order with a " +
			delay.toFixed(1) + "s interval and restore the equipped loadout when finished."
	);

	if (sequence.active) {
		XHSDevToolsMakeLabel(
			controls,
			"XHSDevToolsUnavailableLine",
			"Running: " + (sequence.label || sequence.family) + " " +
				Number(sequence.index || 0) + "/" + Number(sequence.count || 0)
		);
	}

	var familyGrid = $.CreatePanel("Panel", controls, "");
	familyGrid.AddClass("XHSDevToolsGrid");
	for (var familyIndex = 0; familyIndex < families.length; familyIndex++) {
		(function(family) {
			if (!(family.testable === true || Number(family.testable) === 1)) {
				return;
			}
			var button = XHSDevToolsMakeButton(
				familyGrid,
				"TEST " + String(family.label || family.id).toUpperCase() + " (" +
					Number(family.testable_count || family.count || 0) + ")",
				"Accent",
				function() {
					XHSDevToolsSend("battlepass_test_family", { family: family.id });
				}
			);
			button.SetHasClass("Active", !!sequence.active && sequence.family === family.id);
		})(families[familyIndex]);
	}
	XHSDevToolsMakeButton(familyGrid, "STOP / RESTORE", "Danger", function() {
		XHSDevToolsSend("battlepass_stop_test", {});
	});

	if (families.length === 0) {
		XHSDevToolsMakeLabel(
			controls,
			"XHSDevToolsUnavailableLine",
			"Battle Pass catalog is not available yet. Reopen this tab once the game setup has loaded."
		);
		return;
	}

	for (var i = 0; i < families.length; i++) {
		(function(family) {
			var publishedFamily = CustomNetTables.GetTableValue(
				"xhs_devtools",
				"battlepass_family_" + family.id
			) || family;
			var section = XHSDevToolsMakeSection(
				parent,
				String(publishedFamily.label || publishedFamily.id) + " Items (" +
					Number(publishedFamily.count || 0) + ")"
			);
			var grid = $.CreatePanel("Panel", section, "");
			grid.AddClass("XHSDevToolsBattlepassGrid");
			var rewards = XHSDevToolsBattlepassValues(publishedFamily.rewards);
			for (var rewardIndex = 0; rewardIndex < rewards.length; rewardIndex++) {
				(function(reward) {
					var displayName = String(reward.display_name || reward.name || reward.item_id);
					if (displayName.charAt(0) === "#") {
						var localizedName = $.Localize(displayName);
						if (localizedName && localizedName !== displayName) {
							displayName = localizedName;
						}
					}
					var testable = reward.testable === true || Number(reward.testable) === 1;
					var card = $.CreatePanel("Panel", grid, "");
					card.AddClass("XHSDevToolsBattlepassItem");
					card.SetHasClass("VisualOnly", !testable);

					var imageFrame = $.CreatePanel("Panel", card, "");
					imageFrame.AddClass("XHSDevToolsBattlepassImageFrame");
					var imageURL = XHSDevToolsResolveBattlepassImage(reward.image);
					if (imageURL) {
						var image = $.CreatePanel("Image", imageFrame, "");
						image.AddClass("XHSDevToolsBattlepassImage");
						image.SetImage(imageURL);
					} else {
						XHSDevToolsMakeLabel(imageFrame, "XHSDevToolsBattlepassMissingImage", "NO IMAGE");
					}

					XHSDevToolsMakeLabel(card, "XHSDevToolsBattlepassItemName", displayName);
					XHSDevToolsMakeLabel(
						card,
						"XHSDevToolsBattlepassItemMeta",
						"#" + reward.item_id +
							(reward.rarity ? "  ·  " + String(reward.rarity).toUpperCase() : "")
					);
					XHSDevToolsMakeLabel(
						card,
						"XHSDevToolsBattlepassItemSource",
						XHSDevToolsBattlepassSourceText(reward)
					);
					var button = XHSDevToolsMakeButton(
						card,
						testable ? "TEST ITEM" : "VISUAL ONLY",
						testable ? "Accent" : "",
						function() {
							if (!testable) {
								return;
							}
							XHSDevToolsSend("battlepass_test_reward", {
								family: publishedFamily.id,
								item_id: reward.item_id
							});
						}
					);
					button.AddClass("XHSDevToolsBattlepassTestButton");
					button.enabled = testable;
					var tooltip = displayName + "\n" +
						"ID: " + reward.item_id + " (" + String(reward.name || "") + ")\n" +
						XHSDevToolsBattlepassSourceText(reward) +
						(reward.track ? "\n" + String(reward.track).toUpperCase() + " track" : "") +
						(reward.level ? ", level " + Number(reward.level || 0) : "") +
						(reward.rarity ? "\nRarity: " + reward.rarity : "");
					card.SetPanelEvent("onmouseover", function() {
						$.DispatchEvent("UIShowTextTooltip", card, tooltip);
					});
					card.SetPanelEvent("onmouseout", function() {
						$.DispatchEvent("UIHideTextTooltip", card);
					});
				})(rewards[rewardIndex]);
			}
		})(families[i]);
	}
}

function XHSDevToolsRenderCleanup(parent) {
	var cleanup = XHSDevToolsMakeSection(parent, "Cleanup");
	XHSDevToolsMakeLabel(cleanup, "XHSDevToolsMuted", "Cleanup removes dev-spawned units, enemy lane creeps, boss counters, and boss health bars.");
	var grid = $.CreatePanel("Panel", cleanup, "");
	grid.AddClass("XHSDevToolsGrid");
	XHSDevToolsMakeButton(grid, "Cleanup Units/UI", "Warn", function() {
		XHSDevToolsSend("cleanup", {});
	});
	XHSDevToolsMakeButton(grid, "Reset Sandbox", "Danger", function() {
		XHSDevToolsSend("reset_sandbox", {});
	});
}

var XHS_DEVTOOLS_LAG_LAB_EXPERIMENTS = [
	{ id: "base_model", label: "Base models", hint: "Switches current/future waves and permanently removes their cosmetics for this match." },
	{ id: "hide_creeps", label: "Hide creeps", hint: "Tests rendering cost without deleting units." },
	{ id: "pause_ai", label: "Pause AI", hint: "Stops modifier_ai decisions." },
	{ id: "pause_bots", label: "Pause bots", hint: "Stops allied XHS bot decisions during the test window." },
	{ id: "pause_waves", label: "Pause waves", hint: "Stops lane controller ticks." },
	{ id: "pause_abilities", label: "Pause abilities", hint: "Stops periodic creep spell checks." },
	{ id: "disable_wave_staging", label: "No wave pre-spawn", hint: "Cancels dormant staged units and restores synchronous wave creation for a direct A/B comparison." },
	{ id: "suppress_orders", label: "Suppress orders", hint: "Drops new creep engine orders." },
	{ id: "root_creeps", label: "Root creeps", hint: "Keeps AI alive while removing movement." },
	{ id: "no_collision", label: "No collision", hint: "Tests pathing/crowd collision cost." },
	{ id: "disarm_creeps", label: "Disarm creeps", hint: "Tests attack/combat workload." },
	{ id: "silence_creeps", label: "Silence creeps", hint: "Tests ability workload via engine state." }
];

var XHS_DEVTOOLS_LAG_LAB_METRICS = [
	{ id: "client_fps", label: "Client FPS", higher: true },
	{ id: "server_sim_lag_ms", label: "Simulation lag ms", higher: false },
	{ id: "server_sim_health_pct", label: "Simulation health %", higher: true },
	{ id: "creeps", label: "Creeps", neutral: true },
	{ id: "total_units", label: "Total units", neutral: true },
	{ id: "staged_units", label: "Dormant staged units", neutral: true },
	{ id: "scan_ms", label: "Profiler scan ms", higher: false },
	{ id: "zone_searches_s", label: "Spatial queries/s", higher: false },
	{ id: "zone_cost_ms_s", label: "Spatial cost ms/s", higher: false },
	{ id: "orders_s", label: "Orders/s", higher: false },
	{ id: "repeated_orders_s", label: "Repeated orders/s", higher: false },
	{ id: "ai_thinks_s", label: "AI thinks/s", higher: false },
	{ id: "wave_thinks_s", label: "Wave thinks/s", higher: false },
	{ id: "ability_thinks_s", label: "Ability thinks/s", higher: false },
	{ id: "damage_s", label: "Damage events/s", higher: false },
	{ id: "projectiles_s", label: "Projectiles/s", higher: false },
	{ id: "target_changes_s", label: "Target changes/s", higher: false },
	{ id: "unit_spawns_s", label: "Unit spawns/s", higher: false },
	{ id: "stage_fallback_s", label: "Synchronous fallback/s", higher: false },
	{ id: "stage_create_cost_ms_s", label: "Staging create cost ms/s", neutral: true }
];

function XHSDevToolsLagLabStart(experiment, source) {
	source = source || "";
	if (XHSDevToolsLagLabIsActive(experiment, source)) {
		XHSDevToolsLagLabPending = "Disabling: " + String(experiment || "unknown");
		XHSDevToolsSend("lag_lab_restore", {});
	} else {
		XHSDevToolsLagLabPending = "Enabling immediately: " + String(experiment || "unknown");
		XHSDevToolsSend("lag_lab_start", {
			experiment: experiment,
			source: source,
			keep_active: 1
		});
	}
	XHSDevToolsRender();
}

function XHSDevToolsLagLabIsActive(experiment, source) {
	var stage = String(XHSDevToolsLagLab.stage || "");
	var active = XHSDevToolsLagLab.running === true ||
		XHSDevToolsLagLab.effect_active === true ||
		stage === "latched";
	if (!active || String(XHSDevToolsLagLab.experiment_id || "") !== String(experiment || "")) {
		return false;
	}
	if (source !== undefined && String(source || "") !== String(XHSDevToolsLagLab.source || "")) {
		return false;
	}
	return true;
}

function XHSDevToolsLagLabPing() {
	XHSDevToolsLagLabPending = "Ping sent to server";
	XHSDevToolsSend("lag_lab_ping", {});
	XHSDevToolsRender();
}

function XHSDevToolsLagLabFormat(value) {
	var number = Number(value);
	if (isNaN(number)) {
		return "-";
	}
	return Math.abs(number) >= 100 ? number.toFixed(0) : number.toFixed(2);
}

function XHSDevToolsRenderLagLabResult(parent, result) {
	if (!result || !result.experiment_id) {
		XHSDevToolsMakeLabel(parent, "XHSDevToolsMuted", "No completed comparison yet.");
		return;
	}
	XHSDevToolsMakeLabel(
		parent,
		"XHSDevToolsLagLabResultTitle",
		String(result.label || result.experiment_id) +
			(result.source ? " / " + String(result.source) : "") +
			" - " + Number(result.baseline_samples || 0) + " baseline samples, " +
			Number(result.test_samples || 0) + " test samples"
	);

	var table = $.CreatePanel("Panel", parent, "");
	table.AddClass("XHSDevToolsLagLabTable");
	var header = $.CreatePanel("Panel", table, "");
	header.AddClass("XHSDevToolsLagLabRow Header");
	XHSDevToolsMakeLabel(header, "XHSDevToolsLagLabMetric", "METRIC");
	XHSDevToolsMakeLabel(header, "XHSDevToolsLagLabValue", "BASE");
	XHSDevToolsMakeLabel(header, "XHSDevToolsLagLabValue", "TEST");
	XHSDevToolsMakeLabel(header, "XHSDevToolsLagLabValue", "DELTA");

	for (var i = 0; i < XHS_DEVTOOLS_LAG_LAB_METRICS.length; i++) {
		var metric = XHS_DEVTOOLS_LAG_LAB_METRICS[i];
		var baseline = Number((result.baseline || {})[metric.id] || 0);
		var test = Number((result.test || {})[metric.id] || 0);
		var delta = Number((result.delta || {})[metric.id] || 0);
		var row = $.CreatePanel("Panel", table, "");
		row.AddClass("XHSDevToolsLagLabRow");
		XHSDevToolsMakeLabel(row, "XHSDevToolsLagLabMetric", metric.label);
		XHSDevToolsMakeLabel(row, "XHSDevToolsLagLabValue", XHSDevToolsLagLabFormat(baseline));
		XHSDevToolsMakeLabel(row, "XHSDevToolsLagLabValue", XHSDevToolsLagLabFormat(test));
		var deltaLabel = XHSDevToolsMakeLabel(
			row,
			"XHSDevToolsLagLabValue Delta",
			(delta > 0 ? "+" : "") + XHSDevToolsLagLabFormat(delta)
		);
		if (!metric.neutral && Math.abs(delta) > 0.01) {
			var improved = metric.higher ? delta > 0 : delta < 0;
			deltaLabel.SetHasClass(improved ? "Improved" : "Regressed", true);
		}
	}
}

function XHSDevToolsRenderLagLab(parent) {
	var running = XHSDevToolsLagLab.running === true;
	var status = XHSDevToolsMakeSection(parent, "Controlled A/B Runner");
	XHSDevToolsMakeLabel(
		status,
		"XHSDevToolsMuted",
		"Toggle ON applies the isolation immediately and keeps it active. Toggle it OFF or use RESTORE ALL to remove it."
	);
	var statusRow = $.CreatePanel("Panel", status, "");
	statusRow.AddClass("XHSDevToolsLagLabStatus");
	var stage = String(XHSDevToolsLagLab.stage || "idle").toUpperCase();
	var current = XHSDevToolsLagLab.label ? " / " + String(XHSDevToolsLagLab.label) : "";
	var affected = Number(XHSDevToolsLagLab.affected_units || 0);
	var remaining = Number(XHSDevToolsLagLab.remaining || 0);
	XHSDevToolsMakeLabel(
		statusRow,
		"XHSDevToolsLagLabStage",
		stage + current + (running ? " / " + remaining.toFixed(1) + "s" : "") +
			(affected > 0 ? " / " + affected + " units" : "")
	);
	var restore = XHSDevToolsMakeButton(statusRow, "RESTORE ALL", "Danger", function() {
		XHSDevToolsLagLabPending = "Restore request sent";
		XHSDevToolsSend("lag_lab_restore", {});
		XHSDevToolsRender();
	});
	restore.enabled = running || XHSDevToolsLagLab.effect_active === true;
	XHSDevToolsMakeButton(statusRow, "PING SERVER", "Accent", XHSDevToolsLagLabPing);
	var actionResult = XHSDevToolsState.last_result || {};
	var actionName = String(actionResult.action || "");
	var feedbackText = XHSDevToolsLagLabPending || (actionName.indexOf("lag_lab_") === 0
		? String(actionResult.message || "Server response received")
		: "");
	if (feedbackText) {
		var feedback = XHSDevToolsMakeLabel(status, "XHSDevToolsLagLabFeedback", feedbackText);
		feedback.SetHasClass("Error", actionName.indexOf("lag_lab_") === 0 && actionResult.ok === false);
	}

	var experiments = XHSDevToolsMakeSection(parent, "Isolation Experiments");
	var experimentGrid = $.CreatePanel("Panel", experiments, "");
	experimentGrid.AddClass("XHSDevToolsLagLabGrid");
	for (var i = 0; i < XHS_DEVTOOLS_LAG_LAB_EXPERIMENTS.length; i++) {
		(function(experiment) {
			var isActive = XHSDevToolsLagLabIsActive(experiment.id, "");
			var isTesting = isActive && running;
			var card = $.CreatePanel("ToggleButton", experimentGrid, "");
			card.AddClass("XHSDevToolsLagLabCard");
			card.SetHasClass("IsOn", isActive && !isTesting);
			card.SetHasClass("IsTesting", isTesting);
			card.SetHasClass("IsOff", !isActive);
			card.hittest = true;
			card.hittestchildren = true;
			card.checked = isActive;
			card.SetPanelEvent("onactivate", function() {
				XHSDevToolsLagLabStart(experiment.id);
			});
			card.enabled = true;
			var header = $.CreatePanel("Panel", card, "");
			header.AddClass("XHSDevToolsLagLabCardHeader");
			XHSDevToolsMakeLabel(header, "XHSDevToolsLagLabCardTitle", experiment.label);
			var toggle = $.CreatePanel("Panel", header, "");
			toggle.AddClass("XHSDevToolsLagLabCheckbox");
			XHSDevToolsMakeLabel(
				toggle,
				"XHSDevToolsLagLabCheckboxLabel",
				isTesting ? "..." : (isActive ? "ON" : "OFF")
			);
			XHSDevToolsMakeLabel(card, "XHSDevToolsLagLabHint", experiment.hint);
		})(XHS_DEVTOOLS_LAG_LAB_EXPERIMENTS[i]);
	}

	var hotspots = XHSDevToolsMakeSection(parent, "Sampled Zone Hotspots");
	XHSDevToolsMakeLabel(
		hotspots,
		"XHSDevToolsMuted",
		"Only sources observed by the server profiler are accepted. Mute returns an empty search result; 50% and 25% throttle calls."
	);
	var sources = XHSDevToolsBotTableValues((XHSDevToolsPerformance.activity || {}).top_zone_sources || {});
	if (sources.length === 0) {
		XHSDevToolsMakeLabel(hotspots, "XHSDevToolsMuted", "Waiting for sampled FindUnitsInRadius hotspots...");
	}
	for (var sourceIndex = 0; sourceIndex < sources.length; sourceIndex++) {
		(function(sourceData) {
			var source = sourceData.value || {};
			var row = $.CreatePanel("Panel", hotspots, "");
			row.AddClass("XHSDevToolsLagLabHotspot");
			XHSDevToolsMakeLabel(
				row,
				"XHSDevToolsLagLabSource",
				String(source.source || "unknown") + " / " +
					XHSDevToolsLagLabFormat(source.calls_per_second) + " calls/s / " +
					XHSDevToolsLagLabFormat(source.cost_ms_per_second) + " ms/s"
			);
			var mute = XHSDevToolsMakeButton(row, "MUTE", "Small Danger", function() {
				XHSDevToolsLagLabStart("hotspot_mute", String(source.source || ""));
			});
			var half = XHSDevToolsMakeButton(row, "50%", "Small Warn", function() {
				XHSDevToolsLagLabStart("hotspot_half", String(source.source || ""));
			});
			var quarter = XHSDevToolsMakeButton(row, "25%", "Small Warn", function() {
				XHSDevToolsLagLabStart("hotspot_quarter", String(source.source || ""));
			});
			mute.SetHasClass("Active", XHSDevToolsLagLabIsActive("hotspot_mute", String(source.source || "")));
			half.SetHasClass("Active", XHSDevToolsLagLabIsActive("hotspot_half", String(source.source || "")));
			quarter.SetHasClass("Active", XHSDevToolsLagLabIsActive("hotspot_quarter", String(source.source || "")));
			mute.enabled = half.enabled = quarter.enabled = true;
		})(sources[sourceIndex]);
	}

	var results = XHSDevToolsMakeSection(parent, "Last Comparison");
	XHSDevToolsRenderLagLabResult(results, XHSDevToolsLagLab.last_result || {});
}

function XHSDevToolsRender() {
	var root = $("#XHSDevToolsRoot");
	var toolsMode = XHSDevToolsIsToolsMode();
	if (root) {
		root.style.visibility = toolsMode ? "visible" : "collapse";
	}
	XHSDevToolsApplyCompactHUDState();
	if (!toolsMode) {
		return;
	}

	var toggle = $("#XHSDevToolsToggle");
	if (toggle) {
		toggle.SetHasClass("Disabled", !XHSDevToolsState.enabled);
	}

	XHSDevToolsRenderStatus();
	XHSDevToolsRenderSandboxBar();
	XHSDevToolsRenderTimescale();
	XHSDevToolsRenderPerformance();

	var tabs = $("#XHSDevToolsTabs");
	var content = $("#XHSDevToolsContent");
	XHSDevToolsClear(tabs);
	XHSDevToolsClear(content);

	if (!XHSDevToolsState.enabled) {
		XHSDevToolsRenderUnavailable(content);
		return;
	}

	XHSDevToolsRenderTabs();

	if (XHSDevToolsActiveTab === "scenarios") {
		XHSDevToolsRenderScenarios(content);
	} else if (XHSDevToolsActiveTab === "bosses") {
		XHSDevToolsRenderBosses(content);
	} else if (XHSDevToolsActiveTab === "lanes") {
		XHSDevToolsRenderLanes(content);
	} else if (XHSDevToolsActiveTab === "timers") {
		XHSDevToolsRenderTimers(content);
	} else if (XHSDevToolsActiveTab === "bots") {
		XHSDevToolsRenderBots(content);
	} else if (XHSDevToolsActiveTab === "lag_lab") {
		XHSDevToolsRenderLagLab(content);
	} else if (XHSDevToolsActiveTab === "players") {
		XHSDevToolsRenderPlayers(content);
	} else if (XHSDevToolsActiveTab === "overhead") {
		XHSDevToolsRenderOverheadOffsets(content);
	} else if (XHSDevToolsActiveTab === "ui") {
		XHSDevToolsRenderUIPreview(content);
	} else if (XHSDevToolsActiveTab === "battlepass") {
		XHSDevToolsRenderBattlepass(content);
	} else if (XHSDevToolsActiveTab === "cleanup") {
		XHSDevToolsRenderCleanup(content);
	}
}

function XHSDevToolsOnState(tableName, key, data) {
	var localAccessKey = "performance_access_" + Game.GetLocalPlayerID();
	if (key === localAccessKey) {
		XHSDevToolsPerformanceAccess = data || { allowed: false };
		XHSDevToolsApplyAccess();
		return;
	}

	if (key === "performance") {
		XHSDevToolsPerformance = data || {};
		if (XHSDevToolsCanViewPerformanceLog()) {
			XHSDevToolsRenderPerformance();
		}
		return;
	}

	if (key === "lag_lab") {
		XHSDevToolsLagLab = data || {};
		if (XHSDevToolsIsToolsMode() && XHSDevToolsActiveTab === "lag_lab") {
			XHSDevToolsRender();
		}
		return;
	}

	if (key !== "state" || !XHSDevToolsIsToolsMode()) {
		return;
	}

	XHSDevToolsState = data || {};
	var lastAction = String((XHSDevToolsState.last_result || {}).action || "");
	if (lastAction.indexOf("lag_lab_") === 0) {
		XHSDevToolsLagLabPending = "";
	}
	XHSDevToolsHasServerState = true;
	XHSDevToolsRender();
}

function XHSDevToolsReadBotDebugFromRoster() {
	var active = {};
	var rosterEntries = XHSDevToolsBotTableValues(XHSDevToolsBotRoster.players || {});
	for (var i = 0; i < rosterEntries.length; i++) {
		var rosterBot = rosterEntries[i].value || {};
		var playerID = Number(rosterBot.player_id);
		if (isNaN(playerID)) {
			playerID = Number(rosterEntries[i].key);
		}
		if (isNaN(playerID)) {
			continue;
		}
		active[String(playerID)] = true;
		var debug = CustomNetTables.GetTableValue("xhs_bots", "debug_" + playerID);
		if (debug) {
			XHSDevToolsBotDebug[String(playerID)] = debug;
		}
	}

	for (var debugPlayerID in XHSDevToolsBotDebug) {
		if (!active[debugPlayerID]) {
			delete XHSDevToolsBotDebug[debugPlayerID];
		}
	}
}

function XHSDevToolsReadBotNetTables() {
	if (typeof CustomNetTables === "undefined" || !CustomNetTables) {
		return;
	}
	XHSDevToolsBotConfig = CustomNetTables.GetTableValue("xhs_bots", "config") || {};
	XHSDevToolsBotRoster = CustomNetTables.GetTableValue("xhs_bots", "roster") || { count: 0, players: {} };
	XHSDevToolsReadBotDebugFromRoster();
}

function XHSDevToolsShouldRenderBots() {
	var panel = XHSDevToolsPanel();
	return XHSDevToolsIsToolsMode() &&
		XHSDevToolsActiveTab === "bots" &&
		panel &&
		panel.BHasClass("Visible");
}

function XHSDevToolsOnBots(tableName, key, data) {
	if (key === "config") {
		XHSDevToolsBotConfig = data || {};
	} else if (key === "roster") {
		XHSDevToolsBotRoster = data || { count: 0, players: {} };
		XHSDevToolsReadBotDebugFromRoster();
	} else if (String(key).indexOf("debug_") === 0) {
		var playerID = String(key).substring("debug_".length);
		if (data) {
			XHSDevToolsBotDebug[playerID] = data;
		} else {
			delete XHSDevToolsBotDebug[playerID];
		}
	} else {
		return;
	}

	XHSDevToolsRenderBotPerformance();
	XHSDevToolsRenderSpectator();
	XHSDevToolsApplyAccess();
	XHSDevToolsStartSpectatorLoops();
	if (XHSDevToolsShouldRenderBots()) {
		XHSDevToolsRender();
	}
}

function XHSDevToolsOnGameOptions(tableName, key, data) {
	if (key !== "donators") {
		return;
	}
	XHSDevToolsApplyAccess();
}

(function() {
	CustomNetTables.SubscribeNetTableListener("xhs_devtools", XHSDevToolsOnState);
	CustomNetTables.SubscribeNetTableListener("game_options", XHSDevToolsOnGameOptions);
	CustomNetTables.SubscribeNetTableListener("xhs_bots", XHSDevToolsOnBots);
	CustomNetTables.SubscribeNetTableListener("supporter_pass_shop", function(tableName, key) {
		if (key === "catalog" && XHSDevToolsIsToolsMode()) {
			XHSDevToolsRequestState();
		}
	});
	CustomNetTables.SubscribeNetTableListener("supporter_pass_rewards_free", function(tableName, key) {
		if ((key === "rewards" || String(key).indexOf("chunk_") === 0) && XHSDevToolsIsToolsMode()) {
			XHSDevToolsRequestState();
		}
	});
	CustomNetTables.SubscribeNetTableListener("supporter_pass_rewards_premium", function(tableName, key) {
		if ((key === "rewards" || String(key).indexOf("chunk_") === 0) && XHSDevToolsIsToolsMode()) {
			XHSDevToolsRequestState();
		}
	});
	XHSDevToolsReadBotNetTables();
		XHSDevToolsPerformance = CustomNetTables.GetTableValue("xhs_devtools", "performance") || {};
		XHSDevToolsLagLab = CustomNetTables.GetTableValue("xhs_devtools", "lag_lab") || {};
	XHSDevToolsPerformanceAccess = CustomNetTables.GetTableValue(
		"xhs_devtools",
		"performance_access_" + Game.GetLocalPlayerID()
	);
	XHSDevToolsBindPerformanceToggle();
	XHSDevToolsBindSpectator();
	XHSDevToolsApplyPerformanceColumns();
	XHSDevToolsApplyAccess();
	XHSDevToolsClientFPSTick();
	XHSDevToolsStartSpectatorLoops();

	if (XHSDevToolsIsToolsMode()) {
		var state = CustomNetTables.GetTableValue("xhs_devtools", "state");
		if (state) {
			XHSDevToolsState = state;
			XHSDevToolsHasServerState = true;
		}
		XHSDevToolsRender();
		XHSDevToolsRequestStateLoop();
	}
})();
