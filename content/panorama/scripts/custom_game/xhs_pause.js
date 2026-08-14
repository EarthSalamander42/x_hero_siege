"use strict";

(function () {
	var GOOD_GUYS_TEAM = 2;
	var MAX_PLAYER_ID = 23;
	var POLL_INTERVAL = 0.10;
	var DATA_REFRESH_INTERVAL = 0.50;

	var DIFFICULTY_NAMES = {
		1: "EASY",
		2: "NORMAL",
		3: "HARD",
		4: "EXTREME",
		5: "DIVINE",
	};

	var PHASES = {
		1: {
			title: "Defend the Castle",
			focus: "Assign lanes and clear every wave before the next minute. Unchecked creeps compound quickly.",
		},
		2: {
			title: "Break the enemy siege",
			focus: "Destroy siege objectives without leaving the castle exposed to the next assault.",
		},
		3: {
			title: "Defeat the enemy leaders",
			focus: "Focus one enemy leader at a time and respect every telegraphed cast.",
		},
		4: {
			title: "Defeat the final enemies",
			focus: "Save mobility and revival windows for overlapping final-boss mechanics.",
		},
	};

	var OBJECTIVE_PRIORITY = [
		"final_wave",
		"phase2_creeps",
		"farm_event",
		"muradin_event",
	];

	var OBJECTIVE_NAMES = {
		final_wave: "Final Wave",
		phase2_creeps: "Phase 2 Assault",
		farm_event: "Farm Event",
		muradin_event: "Muradin Event",
	};

	var OBJECTIVE_FOCUS = {
		final_wave: "Clear every lane before committing to bosses. One leaked wave can overwhelm the castle.",
		phase2_creeps: "Hold the center, remove the densest creep packs first, then finish the siege targets.",
		farm_event: "Keep moving between dense packs: every unused second is lost gold and experience.",
		muradin_event: "Watch the event timer, respect Frenzy Rage, and regroup for the final damage window.",
	};

	var pauseRoot = $("#XHSPauseRoot");
	var pauseFrame = $("#XHSPauseFrame");
	var pauseShown = false;
	var lastDataRefresh = -999;
	var pauseEventState = false;

	function Safe(callback, fallbackValue) {
		try {
			var value = callback();
			return value === undefined || value === null ? fallbackValue : value;
		} catch (error) {
			return fallbackValue;
		}
	}

	function NumberOr(value, fallbackValue) {
		var numberValue = Number(value);
		return isNaN(numberValue) ? fallbackValue : numberValue;
	}

	function Clamp(value, minValue, maxValue) {
		return Math.max(minValue, Math.min(maxValue, value));
	}

	function SetText(panelID, text) {
		var panel = $("#" + panelID);
		if (panel) {
			panel.text = text;
		}
	}

	function GetHudRoot() {
		var panel = $.GetContextPanel();
		while (panel && panel.GetParent()) {
			panel = panel.GetParent();
		}
		return panel;
	}

	function FindHudPanel(panelID) {
		var hudRoot = GetHudRoot();
		return hudRoot && hudRoot.FindChildTraverse ? hudRoot.FindChildTraverse(panelID) : null;
	}

	function GetVanillaPausePanel() {
		var hudRoot = GetHudRoot();
		if (!hudRoot) {
			return null;
		}

		var pausedContainer = hudRoot.FindChildTraverse("PausedContainer");
		if (!pausedContainer) {
			return null;
		}

		return pausedContainer.GetParent();
	}

	function IsVanillaPauseActive() {
		var vanillaPause = GetVanillaPausePanel();
		return !!(vanillaPause && !vanillaPause.BHasClass("Hidden"));
	}

	function HideVanillaPause() {
		var vanillaPause = GetVanillaPausePanel();
		if (vanillaPause) {
			/*
			 * An earlier hot-reloaded instance may have set visible=false.
			 * Restore the engine-owned property, then hide only through style so
			 * Valve can keep toggling its authoritative Hidden class.
			 */
			vanillaPause.visible = true;
			vanillaPause.style.visibility = "collapse";
			vanillaPause.style.opacity = "0";
		}
	}

	function FormatTime(seconds) {
		var wholeSeconds = Math.max(0, Math.floor(NumberOr(seconds, 0)));
		var minutes = Math.floor(wholeSeconds / 60);
		var remainder = wholeSeconds % 60;
		return (minutes < 10 ? "0" : "") + minutes + ":" + (remainder < 10 ? "0" : "") + remainder;
	}

	function GetBattleTime() {
		var clockValue = FindHudPanel("XHSClockValue");
		if (clockValue && clockValue.text && clockValue.text !== "--:--") {
			return String(clockValue.text);
		}

		return Safe(function () {
			return FormatTime(Game.GetDOTATime(false, false));
		}, "00:00");
	}

	function GetQuestSnapshot() {
		return Safe(function () {
			return CustomNetTables.GetTableValue("xhs_quest_state", "state");
		}, null) || {};
	}

	function GetDifficulty() {
		var difficulty = Safe(function () {
			return CustomNetTables.GetTableValue("game_options", "difficulty");
		}, null);

		if (difficulty) {
			return NumberOr(difficulty["1"], 0);
		}

		var gameInfo = Safe(function () {
			return CustomNetTables.GetTableValue("game_options", "game_info");
		}, null);
		var difficultyName = gameInfo && gameInfo.difficulty ? String(gameInfo.difficulty).toUpperCase() : "";
		for (var id in DIFFICULTY_NAMES) {
			if (DIFFICULTY_NAMES.hasOwnProperty(id) && DIFFICULTY_NAMES[id] === difficultyName) {
				return Number(id);
			}
		}

		return 0;
	}

	function GetSquadState() {
		var total = 0;
		var alive = 0;

		for (var playerID = 0; playerID <= MAX_PLAYER_ID; playerID++) {
			var validPlayer = Safe(function () {
				return Players.IsValidPlayerID(playerID);
			}, false);
			if (!validPlayer) {
				continue;
			}

			var team = Safe(function () {
				return Players.GetTeam(playerID);
			}, -1);
			if (team !== GOOD_GUYS_TEAM) {
				continue;
			}

			total++;
			var hero = Safe(function () {
				return Players.GetPlayerHeroEntityIndex(playerID);
			}, -1);
			if (hero !== -1 && Safe(function () { return Entities.IsAlive(hero); }, false)) {
				alive++;
			}
		}

		return {
			alive: alive,
			total: total,
		};
	}

	function IsActiveObjective(objective) {
		if (!objective || !objective.state) {
			return false;
		}
		return String(objective.state).toLowerCase() === "active";
	}

	function GetActiveObjective(snapshot) {
		var objectives = snapshot.global_objectives || snapshot.globalObjectives || {};
		for (var i = 0; i < OBJECTIVE_PRIORITY.length; i++) {
			var id = OBJECTIVE_PRIORITY[i];
			if (IsActiveObjective(objectives[id])) {
				return {
					id: id,
					data: objectives[id],
				};
			}
		}
		return null;
	}

	function GuessObjectiveID(title) {
		var normalizedTitle = String(title || "").toLowerCase();
		if (normalizedTitle.indexOf("farm") !== -1) {
			return "farm_event";
		}
		if (normalizedTitle.indexOf("muradin") !== -1) {
			return "muradin_event";
		}
		if (normalizedTitle.indexOf("final") !== -1 && normalizedTitle.indexOf("wave") !== -1) {
			return "final_wave";
		}
		if (normalizedTitle.indexOf("phase 2") !== -1 || normalizedTitle.indexOf("assault") !== -1) {
			return "phase2_creeps";
		}
		return "";
	}

	function GetLiveEvent() {
		var eventPanel = FindHudPanel("XHSArenaTimer");
		if (!eventPanel || eventPanel.BHasClass("XHSOptionalTimer")) {
			return null;
		}

		var titlePanel = FindHudPanel("XHSCurrentEventTimerTitle");
		var valuePanel = FindHudPanel("XHSArenaTimerValue");
		var title = titlePanel && titlePanel.text ? String(titlePanel.text) : "ACTIVE EVENT";
		var value = valuePanel && valuePanel.text ? String(valuePanel.text) : "";
		return {
			id: GuessObjectiveID(title),
			title: title,
			value: value,
		};
	}

	function GetObjectiveTitle(activeObjective) {
		if (!activeObjective) {
			return "";
		}

		return OBJECTIVE_NAMES[activeObjective.id] || "Active Objective";
	}

	function RefreshBriefing() {
		var snapshot = GetQuestSnapshot();
		var phase = Clamp(Math.max(1, NumberOr(snapshot.game_phase, 1)), 1, 4);
		var creepLevel = Clamp(Math.max(1, NumberOr(snapshot.creep_level, 1)), 1, 4);
		var phaseInfo = PHASES[phase] || PHASES[1];
		var difficulty = GetDifficulty();
		var squad = GetSquadState();
		var activeObjective = GetActiveObjective(snapshot);
		var liveEvent = GetLiveEvent();
		var focusTitle = phaseInfo.title;
		var focusBody = phaseInfo.focus;
		var focusEyebrow = "TACTICAL FOCUS";

		SetText("XHSPauseSubtitle", "Tactical overview  \u2022  " + GetBattleTime());
		SetText("XHSPausePhaseValue", "PHASE " + phase);
		SetText("XHSPausePhaseDetail", phaseInfo.title);
		SetText("XHSPauseCreepValue", "LEVEL " + creepLevel + " / 4");
		SetText("XHSPauseCreepDetail", creepLevel >= 4 ? "Maximum wave strength" : "Wave strength");
		SetText("XHSPauseDifficultyValue", DIFFICULTY_NAMES[difficulty] || "CUSTOM");

		if (squad.total > 0) {
			SetText("XHSPauseSquadValue", squad.alive + " / " + squad.total + " ALIVE");
			SetText("XHSPauseSquadDetail", squad.alive === squad.total ? "All heroes ready" : "Revival required");
		} else {
			SetText("XHSPauseSquadValue", "ASSEMBLING");
			SetText("XHSPauseSquadDetail", "Waiting for heroes");
		}

		if (liveEvent) {
			focusEyebrow = "ACTIVE EVENT";
			focusTitle = liveEvent.title + (liveEvent.value && liveEvent.value !== "--:--" ? "  \u2022  " + liveEvent.value : "");
			focusBody = OBJECTIVE_FOCUS[liveEvent.id] || focusBody;
		} else if (activeObjective) {
			focusEyebrow = "ACTIVE OBJECTIVE";
			focusTitle = GetObjectiveTitle(activeObjective);
			focusBody = OBJECTIVE_FOCUS[activeObjective.id] || focusBody;
		}

		if (squad.total > 0 && squad.alive < squad.total) {
			focusBody = "Protect fallen heroes and coordinate revival channels before the next assault reaches the castle.";
		}

		SetText("XHSPauseFocusEyebrow", focusEyebrow);
		SetText("XHSPauseFocusTitle", focusTitle);
		SetText("XHSPauseFocusBody", focusBody);
	}

	function IsPaused() {
		var gamePaused = Safe(function () {
			return Game.IsGamePaused();
		}, false);
		return !!(gamePaused || pauseEventState || IsVanillaPauseActive());
	}

	function ShowPauseBriefing() {
		if (!pauseRoot) {
			return;
		}

		if (pauseShown) {
			return;
		}

		pauseShown = true;
		RefreshBriefing();
		pauseRoot.RemoveClass("XHSPauseHidden");
		pauseRoot.AddClass("XHSPauseIntro");
		$.Schedule(0.01, function () {
			if (pauseRoot && pauseShown) {
				pauseRoot.RemoveClass("XHSPauseIntro");
			}
		});
	}

	function HidePauseBriefing() {
		if (!pauseRoot || !pauseShown) {
			return;
		}

		pauseShown = false;
		pauseRoot.AddClass("XHSPauseHidden");
		pauseRoot.RemoveClass("XHSPauseIntro");
	}

	function OnPauseState(data) {
		pauseEventState = !!(data && NumberOr(data.paused, 0) === 1);
		if (pauseEventState) {
			ShowPauseBriefing();
		} else {
			HidePauseBriefing();
		}
	}

	function PollPauseState() {
		HideVanillaPause();

		var paused = IsPaused();
		if (paused) {
			ShowPauseBriefing();
			var now = Safe(function () { return Game.Time(); }, 0);
			if (now - lastDataRefresh >= DATA_REFRESH_INTERVAL) {
				lastDataRefresh = now;
				RefreshBriefing();
			}
		} else {
			HidePauseBriefing();
		}

		$.Schedule(POLL_INTERVAL, PollPauseState);
	}

	if (!pauseRoot || !pauseFrame) {
		$.Msg("[XHS Pause] Required panels are missing.");
		return;
	}

	GameEvents.Subscribe("xhs_game_pause_state", OnPauseState);
	CustomNetTables.SubscribeNetTableListener("xhs_quest_state", function () {
		if (pauseShown) {
			RefreshBriefing();
		}
	});

	HideVanillaPause();
	PollPauseState();
})();
