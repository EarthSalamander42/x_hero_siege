"use strict";

var XHSTopHud = (function () {
	var MAX_PLAYER_DISPLAY_SLOTS = 8;
	var MAX_PLAYER_ID_SCAN = 23;
	var HERO_REFRESH_SECONDS = 0.75;
	var VITALS_REFRESH_SECONDS = 0.12;
	var SLOW_REFRESH_SECONDS = 1.0;
	var OVERHEAD_REFRESH_SECONDS = 0.01;
	var OVERHEAD_WORLD_Z_OFFSET = 238;
	var OVERHEAD_SCREEN_Y_OFFSET = 22;
	var OVERHEAD_PERSPECTIVE_BIAS = 38;
	var OVERHEAD_PLATE_WIDTH = 210;
	var OVERHEAD_PLATE_HEIGHT = 50;
	var OVERHEAD_LABEL_HEIGHT = 96;
	var OVERHEAD_FADE_MARGIN = 96;
	var OVERHEAD_BLOCKER_REFRESH_SECONDS = 0.12;
	var OVERHEAD_HEALTH_TICK_INTERVAL = 250;
	var OVERHEAD_HEALTH_MAX_TICKS = 32;
	var OVERHEAD_HEALTH_TICK_INTERVALS = [
		250,
		500,
		1000,
		2500,
		5000,
		10000,
		25000,
		50000,
		100000,
		250000,
		500000,
		1000000,
	];
	// Flip this back to true to show the static overhead health bar design sandbox.
	var OVERHEAD_MOCKUP_MODE = false;
	var OVERHEAD_TIER_DEV_VIEW = false;
	var DAILY_FRAGMENT_CAP = 100;
	var WEEKLY_FRAGMENT_CAP = DAILY_FRAGMENT_CAP;

	var allyCards = {};
	var vipCards = {};
	var overheadLabels = {};
	var cloneOverheadKeys = {};
	var botActivityStates = {};
	var overheadUiBlockerRects = [];
	var overheadUiBlockerRefreshAt = 0;
	var overheadUiBlockerRootWidth = 0;
	var overheadUiBlockerRootHeight = 0;
	var topHudLayerApplied = false;
	var isSpecialEventPanelVisible = false;
	var isGamePaused = false;
	var isSupporterPassOccluding = false;
	var areOverheadsModalOccluded = null;
	var isHeroSelectionTransitionActive = false;
	var nightfallVignetteToken = 0;
	var activeCurrentEventTimerName = null;
	var isMuradinFrenzyActive = false;
	var activePersonalTimerName = null;
	var currentEventTimerMaxRemaining = {};
	var currentEventTimerProgressRunning = {};
	var personalTimerMaxRemaining = {};
	var personalTimerProgressRunning = {};
	var XHS_PLAYER_COLOR_FALLBACKS = [
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
	];

	var OVERHEAD_STATUS_CLASSES = [
		"XHSStatusStunned",
		"XHSStatusHexed",
		"XHSStatusSleep",
		"XHSStatusFeared",
		"XHSStatusTaunted",
		"XHSStatusCycloned",
		"XHSStatusRooted",
		"XHSStatusLeashed",
		"XHSStatusSilenced",
		"XHSStatusMuted",
		"XHSStatusDisarmed",
		"XHSStatusBroken",
		"XHSStatusInvulnerable",
	];

	var BOT_ACTIVITY_TONE_CLASSES = [
		"XHSBotActivityToneCombat",
		"XHSBotActivityToneDefense",
		"XHSBotActivityToneDanger",
		"XHSBotActivityToneMove",
		"XHSBotActivityToneSupport",
		"XHSBotActivityToneEconomy",
		"XHSBotActivityToneSecret",
		"XHSBotActivityToneEvent",
		"XHSBotActivityToneIdle",
		"XHSBotActivityToneUnknown",
	];

	var DEFAULT_SUPPORTER_TIER_CATALOG = [
		{ id: 0, name: "Free Player", color: "#7db9d8", fragments: 0, xpBoost: 0, votePower: 1 },
		{ id: 1, name: "Donator", color: "#45C46B", fragments: 150, xpBoost: 10, votePower: 2 },
		{ id: 2, name: "Golden Donator", color: "#F2C94C", fragments: 400, xpBoost: 20, votePower: 3 },
		{ id: 3, name: "Ember Donator", color: "#E4572E", fragments: 900, xpBoost: 30, votePower: 4 },
		{ id: 4, name: "Stoneguard Donator", color: "#5AD0FF", fragments: 1800, xpBoost: 40, votePower: 5 },
		{ id: 5, name: "Earthwarden Donator", color: "#C99CFF", fragments: 1800, xpBoost: 40, votePower: 5 },
	];

	var currentEventTimerTitles = {
		special_arena: "SPECIAL ARENA",
		special_event: "EVENT",
	};

	var personalTimerTitles = {
		hero_image: "HERO IMAGE",
		spirit_beast: "SPIRIT BEAST",
		frost_infernal: "FROST INFERNAL",
		all_hero_images: "ALL HERO IMAGES",
	};

	function Panel(id) {
		return $("#" + id);
	}

	function GetPanelWindowPosition(panel) {
		if (!panel) {
			return { x: 0, y: 0 };
		}

		if (panel.GetPositionWithinWindow) {
			var position = panel.GetPositionWithinWindow();
			if (position) {
				return {
					x: Number(position.x || position[0] || 0),
					y: Number(position.y || position[1] || 0)
				};
			}
		}

		return {
			x: Number(panel.actualxoffset || 0),
			y: Number(panel.actualyoffset || 0)
		};
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


	function EnsureTopHudBelowShop() {
		if (topHudLayerApplied) {
			return;
		}

		if (typeof FindDotaHudElement !== "function") {
			$.Schedule(0.5, EnsureTopHudBelowShop);
			return;
		}

		var host = $.GetContextPanel();
		var shop = FindDotaHudElement("shop");
		if (!host || !shop) {
			$.Schedule(0.5, EnsureTopHudBelowShop);
			return;
		}

		var hostHud = GetHudAncestor(host);
		var shopHud = GetHudAncestor(shop);
		var hud = hostHud || shopHud;
		var hostChild = GetHudDirectChild(host, hud);
		var shopChild = GetHudDirectChild(shop, hud);

		if (!hud || !hostChild || !shopChild || hostChild === shopChild || typeof hud.MoveChildBefore !== "function") {
			$.Schedule(0.5, EnsureTopHudBelowShop);
			return;
		}

		try {
			hud.MoveChildBefore(hostChild, shopChild);
			topHudLayerApplied = true;
		} catch (error) {
			$.Schedule(0.5, EnsureTopHudBelowShop);
		}
	}
	function SetText(id, value) {
		var panel = Panel(id);
		if (panel) {
			panel.text = value;
		}
	}

	function SafeValue(callback, fallbackValue) {
		try {
			var value = callback();
			return value === undefined || value === null ? fallbackValue : value;
		} catch (error) {
			return fallbackValue;
		}
	}

	function IsValidEntityIndex(entIndex) {
		return entIndex !== undefined && entIndex !== null && entIndex !== -1;
	}

	function PanelHasHover(panel) {
		return SafeValue(function () {
			return panel && panel.BHasHoverStyle && panel.BHasHoverStyle();
		}, false);
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

	function NormalizeTextValue(value) {
		if (value === undefined || value === null) {
			return "";
		}

		return value.toString().replace(/^\s+|\s+$/g, "");
	}

	function FormatUnitNameFallback(unitName) {
		var text = NormalizeTextValue(unitName);
		if (!text) {
			return "";
		}

		text = text.replace(/^npc_dota_hero_/, "");
		text = text.replace(/^npc_/, "");
		text = text.replace(/_/g, " ");
		return text.toUpperCase();
	}

	function LocalizeUnitName(unitName) {
		var text = NormalizeTextValue(unitName);
		if (!text) {
			return "";
		}

		var localized = NormalizeTextValue(SafeValue(function () {
			return $.Localize("#" + text);
		}, ""));

		if (!localized || localized === "#" + text) {
			return FormatUnitNameFallback(text);
		}

		return localized;
	}

	function SetChildText(parent, childID, value) {
		if (!parent) {
			return;
		}

		var child = parent.FindChildTraverse(childID);
		if (child) {
			child.text = value === undefined || value === null ? "" : value.toString();
		}
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

	function ColorWithAlpha(color, alpha) {
		var normalizedColor = NormalizeColorString(color);
		if (!normalizedColor) {
			return "#ffffff" + alpha;
		}

		return normalizedColor.substr(0, 7) + alpha;
	}

	function IsInvalidPlayerColorString(colorString) {
		return !colorString || colorString === "#ffffffff" || colorString === "#ffffff";
	}

	function GetFallbackPlayerColorString(playerID) {
		var fallbackIndex = ((playerID % XHS_PLAYER_COLOR_FALLBACKS.length) + XHS_PLAYER_COLOR_FALLBACKS.length) % XHS_PLAYER_COLOR_FALLBACKS.length;
		return XHS_PLAYER_COLOR_FALLBACKS[fallbackIndex];
	}

	function GetPlayerColorString(playerID) {
		var tableColor = SafeValue(function () {
			var playerColors = CustomNetTables.GetTableValue("game_options", "player_colors");
			return playerColors ? playerColors[playerID] : null;
		}, null);
		var normalizedTableColor = NormalizeColorString(tableColor);

		if (!IsInvalidPlayerColorString(normalizedTableColor)) {
			return normalizedTableColor;
		}

		var engineColor = SafeValue(function () {
			return Players.GetPlayerColor(playerID);
		}, null);
		var engineColorString = engineColor === null ? "" : IntToColorString(engineColor);

		if (!IsInvalidPlayerColorString(engineColorString)) {
			return engineColorString;
		}

		return GetFallbackPlayerColorString(playerID);
	}

	function FormatTimer(data) {
		return "" +
			data.timer_minute_10 +
			data.timer_minute_01 +
			":" +
			data.timer_second_10 +
			data.timer_second_01;
	}

	function GetTimerSeconds(data) {
		if (!data) {
			return 0;
		}

		var minutes = (ToNumber(data.timer_minute_10, 0) * 10) + ToNumber(data.timer_minute_01, 0);
		var seconds = (ToNumber(data.timer_second_10, 0) * 10) + ToNumber(data.timer_second_01, 0);
		return Math.max(0, (minutes * 60) + seconds);
	}

	function ResetCurrentEventProgress(timerName) {
		if (timerName) {
			currentEventTimerMaxRemaining[timerName] = 0;
			currentEventTimerProgressRunning[timerName] = false;
		}

		var fill = Panel("XHSCurrentEventProgressFill");
		if (fill) {
			fill.style.transitionDuration = "0s";
			fill.style.width = "100%";
		}
	}

	function UpdateCurrentEventProgress(timerName, remaining) {
		var fill = Panel("XHSCurrentEventProgressFill");
		if (!fill || !timerName) {
			return;
		}

		var previousMax = currentEventTimerMaxRemaining[timerName] || 0;
		var timerWasReset = previousMax <= 0 || remaining > previousMax;
		var maxRemaining = timerWasReset ? Math.max(remaining, 1) : Math.max(previousMax, 1);
		currentEventTimerMaxRemaining[timerName] = maxRemaining;
		currentEventTimerProgressRunning[timerName] = true;

		if (remaining <= 0) {
			currentEventTimerProgressRunning[timerName] = false;
			fill.style.transitionDuration = "0.18s";
			fill.style.width = "0%";
			return;
		}

		var percent = Clamp((remaining / maxRemaining) * 100, 0, 100);

		if (timerWasReset) {
			fill.style.transitionDuration = "0s";
			fill.style.width = percent + "%";
			return;
		}

		fill.style.transitionDuration = "0.92s";
		fill.style.width = percent + "%";
	}

	function SetMuradinFrenzyActive(isActive) {
		isActive = !!isActive;
		if (isMuradinFrenzyActive === isActive) {
			return;
		}

		isMuradinFrenzyActive = isActive;
		var timer = Panel("XHSArenaTimer");
		if (timer) {
			timer.SetHasClass("XHSMuradinFrenzy", isActive);
		}
	}

	function ResetPersonalEventProgress(timerName) {
		if (timerName) {
			personalTimerMaxRemaining[timerName] = 0;
			personalTimerProgressRunning[timerName] = false;
		}

		var fill = Panel("XHSPersonalEventProgressFill");
		if (fill) {
			fill.style.transitionDuration = "0s";
			fill.style.width = "100%";
		}
	}

	function UpdatePersonalEventProgress(timerName, remaining) {
		var fill = Panel("XHSPersonalEventProgressFill");
		if (!fill || !timerName) {
			return;
		}

		var previousMax = personalTimerMaxRemaining[timerName] || 0;
		var timerWasReset = previousMax <= 0 || remaining > previousMax;
		var maxRemaining = timerWasReset ? Math.max(remaining, 1) : Math.max(previousMax, 1);
		personalTimerMaxRemaining[timerName] = maxRemaining;
		personalTimerProgressRunning[timerName] = true;

		if (remaining <= 0) {
			personalTimerProgressRunning[timerName] = false;
			fill.style.transitionDuration = "0.18s";
			fill.style.width = "0%";
			return;
		}

		var percent = Clamp((remaining / maxRemaining) * 100, 0, 100);

		if (timerWasReset) {
			fill.style.transitionDuration = "0s";
			fill.style.width = percent + "%";
			return;
		}

		fill.style.transitionDuration = "0.92s";
		fill.style.width = percent + "%";
	}

	function IsPlayerDisconnected(playerInfo) {
		if (!playerInfo) {
			return false;
		}

		if (typeof DOTAConnectionState_t === "undefined") {
			return false;
		}

		return playerInfo.player_connection_state === DOTAConnectionState_t.DOTA_CONNECTION_STATE_DISCONNECTED ||
			playerInfo.player_connection_state === DOTAConnectionState_t.DOTA_CONNECTION_STATE_ABANDONED;
	}

	var recentUnitSelections = {};

	function SelectUnitWithoutVanillaDoubleCenter(entIndex) {
		var key = String(entIndex);
		if (recentUnitSelections[key]) {
			return false;
		}

		recentUnitSelections[key] = true;
		$.Schedule(0.35, function () {
			delete recentUnitSelections[key];
		});
		GameUI.SelectUnit(entIndex, false);
		return true;
	}

	function SelectUnitOrCast(entIndex) {
		if (!IsValidEntityIndex(entIndex)) {
			return;
		}

		var clickBehavior = GameUI.GetClickBehaviors();
		if (clickBehavior === CLICK_BEHAVIORS.DOTA_CLICK_BEHAVIOR_CAST) {
			var abilityIndex = Abilities.GetLocalPlayerActiveAbility();
			if (!IsValidEntityIndex(abilityIndex)) {
				SelectUnitWithoutVanillaDoubleCenter(entIndex);
				return;
			}

			var abilityBehavior = Abilities.GetBehavior(abilityIndex);

			if (abilityBehavior & DOTA_ABILITY_BEHAVIOR.DOTA_ABILITY_BEHAVIOR_UNIT_TARGET) {
				Game.PrepareUnitOrders({
					AbilityIndex: abilityIndex,
					OrderType: dotaunitorder_t.DOTA_UNIT_ORDER_CAST_TARGET,
					QueueBehavior: OrderQueueBehavior_t.DOTA_ORDER_QUEUE_NEVER,
					ShowEffects: false,
					TargetIndex: entIndex,
				});
				return;
			}
		}

		SelectUnitWithoutVanillaDoubleCenter(entIndex);
	}

	function MoveCameraToUnit(entIndex) {
		if (!IsValidEntityIndex(entIndex)) {
			return;
		}
		GameEvents.SendCustomGameEventToServer("xhs_camera_focus_entity", {
			entindex: entIndex,
		});
	}

	function CreateProgressBar(parent, id, className, height) {
		var bar = $.CreatePanel("Panel", parent, id);
		bar.AddClass(className);
		bar.hittest = false;

		var fill = $.CreatePanel("Panel", bar, id + "_Fill");
		fill.AddClass("XHSAllyBarFill");
		fill.AddClass(className + "Fill");
		fill.hittest = false;
		fill.style.width = "100%";

		return bar;
	}

	function GetLocalPlayerID() {
		return SafeValue(function () {
			return Players.GetLocalPlayer();
		}, SafeValue(function () {
			return Game.GetLocalPlayerID();
		}, -1));
	}

	function ProjectWorldToScreen(origin) {
		if (!origin || typeof Game === "undefined" || typeof Game.WorldToScreenX !== "function" || typeof Game.WorldToScreenY !== "function") {
			return null;
		}

		var x = SafeValue(function () {
			return Game.WorldToScreenX(origin[0], origin[1], origin[2] + OVERHEAD_WORLD_Z_OFFSET);
		}, -1);
		var y = SafeValue(function () {
			return Game.WorldToScreenY(origin[0], origin[1], origin[2] + OVERHEAD_WORLD_Z_OFFSET);
		}, -1);

		if (x < 0 || y < 0 || isNaN(x) || isNaN(y)) {
			return null;
		}

		return { x: x, y: y };
	}

	function SetOverheadLabelVisible(label, isVisible) {
		if (!label) {
			return;
		}

		if (!isVisible) {
			label.style.opacity = "0";
		}
		label.SetHasClass("XHSOverheadHidden", !isVisible);
	}

	function GetOverheadEdgeFade(x, y, rootWidth, rootHeight) {
		var leftDistance = x + OVERHEAD_PLATE_WIDTH;
		var rightDistance = rootWidth - x;
		var topDistance = y + OVERHEAD_LABEL_HEIGHT;
		var bottomDistance = rootHeight - y;
		var edgeDistance = Math.min(leftDistance, rightDistance, topDistance, bottomDistance);

		return Clamp(edgeDistance / OVERHEAD_FADE_MARGIN, 0, 1);
	}

	function GetNowSeconds() {
		return SafeValue(function () {
			return Date.now() / 1000;
		}, SafeValue(function () {
			return Game.GetGameTime();
		}, 0));
	}

	function RectIntersects(a, b) {
		return a.left < b.right &&
			a.right > b.left &&
			a.top < b.bottom &&
			a.bottom > b.top;
	}

	function AddOverheadBlockerRect(blockers, left, top, right, bottom, padding) {
		padding = ToNumber(padding, 0);

		if (right <= left || bottom <= top) {
			return;
		}

		blockers.push({
			left: left - padding,
			top: top - padding,
			right: right + padding,
			bottom: bottom + padding
		});
	}

	function IsPanelUsableOverheadBlocker(panel) {
		if (!panel || panel.visible === false || (panel.style && panel.style.visibility === "collapse")) {
			return false;
		}

		// Vanilla shop toggles its open state through opacity rather than visibility.
		if (panel.style && panel.style.opacity !== undefined && panel.style.opacity !== "" && Number(panel.style.opacity) <= 0) {
			return false;
		}

		if (panel.BHasClass && panel.BHasClass("XHSOptionalTimer")) {
			return false;
		}

		var width = Number(panel.actuallayoutwidth || panel.desiredlayoutwidth || 0);
		var height = Number(panel.actuallayoutheight || panel.desiredlayoutheight || 0);
		return width > 0 && height > 0;
	}

	function AddPanelOverheadBlocker(blockers, panelID, rootPosition, padding) {
		var panel = Panel(panelID);
		if (!IsPanelUsableOverheadBlocker(panel)) {
			return;
		}

		var position = GetPanelWindowPosition(panel);
		var width = Number(panel.actuallayoutwidth || panel.desiredlayoutwidth || 0);
		var height = Number(panel.actuallayoutheight || panel.desiredlayoutheight || 0);

		AddOverheadBlockerRect(
			blockers,
			position.x - rootPosition.x,
			position.y - rootPosition.y,
			position.x - rootPosition.x + width,
			position.y - rootPosition.y + height,
			padding
		);
	}

	function BuildOverheadUiBlockers(root, rootWidth, rootHeight) {
		var blockers = [];
		var rootPosition = GetPanelWindowPosition(root);
		var minimapSize = Clamp(rootWidth * 0.16, 260, 330);
		var bottomHudTop = Math.max(rootHeight - 190, rootHeight * 0.80);

		AddOverheadBlockerRect(blockers, 0, 0, rootWidth, 126, 0);
		AddOverheadBlockerRect(blockers, rootWidth * 0.24, bottomHudTop, rootWidth * 0.76, rootHeight, 0);
		AddOverheadBlockerRect(blockers, 0, rootHeight - minimapSize - 14, minimapSize + 22, rootHeight, 0);
		AddOverheadBlockerRect(blockers, rootWidth - 335, rootHeight - 160, rootWidth, rootHeight, 0);
		var questLogBlocksWorld = SafeValue(function () {
			return GameUI.CustomUIConfig().xhsQuestLogBlocksWorld;
		}, true);
		if (questLogBlocksWorld !== false) {
			AddOverheadBlockerRect(blockers, 0, 120, Math.min(430, rootWidth * 0.26), rootHeight - minimapSize - 28, 0);
		}

		AddPanelOverheadBlocker(blockers, "XHSTopHudBar", rootPosition, 8);
		AddPanelOverheadBlocker(blockers, "XHSFocusTimers", rootPosition, 8);
		AddPanelOverheadBlocker(blockers, "XHSWavePressurePanel", rootPosition, 8);
		AddPanelOverheadBlocker(blockers, "XHSDifficultyAltPanel", rootPosition, 8);
		AddPanelOverheadBlocker(blockers, "XHSFragmentQuestIntro", rootPosition, 10);
		// The vanilla shop is outside the custom HUD tree, so register it explicitly.
		if (typeof FindDotaHudElement === "function") {
			var shop = FindDotaHudElement("shop");
			var shopUsable = IsPanelUsableOverheadBlocker(shop);
			if (shopUsable) {
				var shopPosition = GetPanelWindowPosition(shop);
				var shopWidth = Number(shop.actuallayoutwidth || shop.desiredlayoutwidth || 0);
				var shopHeight = Number(shop.actuallayoutheight || shop.desiredlayoutheight || 0);
				AddOverheadBlockerRect(
					blockers,
					shopPosition.x - rootPosition.x,
					shopPosition.y - rootPosition.y,
					shopPosition.x - rootPosition.x + shopWidth,
					shopPosition.y - rootPosition.y + shopHeight,
					8
				);
			}
		}
		if (IsSpecialEventPanelBlockingUi()) {
			var eventWidth = Math.min(1040, rootWidth * 0.64);
			var eventHeight = Math.min(620, rootHeight * 0.62);
			AddOverheadBlockerRect(
				blockers,
				(rootWidth - eventWidth) * 0.5,
				(rootHeight - eventHeight) * 0.5,
				(rootWidth + eventWidth) * 0.5,
				(rootHeight + eventHeight) * 0.5,
				16
			);
		}

		return blockers;
	}

	function GetOverheadUiBlockers(root, rootWidth, rootHeight) {
		var now = GetNowSeconds();
		if (now < overheadUiBlockerRefreshAt &&
			rootWidth === overheadUiBlockerRootWidth &&
			rootHeight === overheadUiBlockerRootHeight) {
			return overheadUiBlockerRects;
		}

		overheadUiBlockerRootWidth = rootWidth;
		overheadUiBlockerRootHeight = rootHeight;
		overheadUiBlockerRects = BuildOverheadUiBlockers(root, rootWidth, rootHeight);
		overheadUiBlockerRefreshAt = now + OVERHEAD_BLOCKER_REFRESH_SECONDS;
		return overheadUiBlockerRects;
	}

	function DoesOverheadOverlapUi(labelRect, root, rootWidth, rootHeight) {
		var blockers = GetOverheadUiBlockers(root, rootWidth, rootHeight);
		for (var i = 0; i < blockers.length; i++) {
			if (RectIntersects(labelRect, blockers[i])) {
				return true;
			}
		}

		return false;
	}

	function InvalidateOverheadBlockers() {
		overheadUiBlockerRefreshAt = 0;
	}

	function GetSupporterPassOcclusionState() {
		return SafeValue(function () {
			var config = GameUI.CustomUIConfig ? GameUI.CustomUIConfig() : null;
			if (!config) {
				return false;
			}
			if (typeof config.XHSSupporterPassOccludesOverheads === "boolean") {
				return config.XHSSupporterPassOccludesOverheads;
			}
			return config.XHSSupporterPassVisible === true;
		}, isSupporterPassOccluding);
	}

	function ApplyOverheadModalOcclusion(paused, supporterPassVisible) {
		isGamePaused = !!paused;
		isSupporterPassOccluding = !!supporterPassVisible;
		var occluded = isGamePaused || isSupporterPassOccluding;
		if (areOverheadsModalOccluded === occluded) {
			return;
		}

		areOverheadsModalOccluded = occluded;
		var overheadRoot = Panel("XHSOverheadRoot");
		if (overheadRoot) {
			overheadRoot.SetHasClass("XHSPauseOccluded", false);
			overheadRoot.SetHasClass("XHSModalOccluded", occluded);
		}
	}

	function SetOverheadPauseOcclusion(paused) {
		ApplyOverheadModalOcclusion(paused, GetSupporterPassOcclusionState());
	}

	function SyncOverheadPauseOcclusion() {
		var paused = SafeValue(function () {
			return Game.IsGamePaused();
		}, isGamePaused);
		ApplyOverheadModalOcclusion(paused, GetSupporterPassOcclusionState());
	}

	function SetSharedSpecialEventVisible(isVisible) {
		SafeValue(function () {
			if (GameUI.CustomUIConfig) {
				GameUI.CustomUIConfig().xhsSpecialEventVisible = !!isVisible;
			}
			return true;
		}, false);
	}

	function IsSpecialEventPanelBlockingUi() {
		return SafeValue(function () {
			if (GameUI.CustomUIConfig) {
				var sharedVisibility = GameUI.CustomUIConfig().xhsSpecialEventVisible;
				if (typeof sharedVisibility === "boolean") {
					return sharedVisibility;
				}
			}

			return isSpecialEventPanelVisible;
		}, isSpecialEventPanelVisible);
	}

	function CreateOverheadHeroImage(parent, id) {
		var portrait = SafeValue(function () {
			return $.CreatePanel("DOTAHeroImage", parent, id);
		}, null);

		if (portrait) {
			portrait.AddClass("XHSOverheadHeroPortrait");
			portrait.heroimagestyle = "icon";
			portrait.hittest = false;
			portrait.SetAttributeInt("xhs_hero_image_fallback", 0);
			return portrait;
		}

		portrait = $.CreatePanel("Panel", parent, id);
		portrait.AddClass("XHSOverheadHeroPortrait");
		portrait.AddClass("XHSOverheadHeroPortraitFallback");
		portrait.hittest = false;
		portrait.SetAttributeInt("xhs_hero_image_fallback", 1);
		return portrait;
	}

	function PrettyBotIdentifier(value) {
		var text = NormalizeTextValue(value);
		if (!text) {
			return "";
		}

		text = text
			.replace(/^npc_dota_hero_/, "")
			.replace(/^npc_dota_/, "")
			.replace(/^holdout_/, "")
			.replace(/^xhs_/, "")
			.replace(/^rifleman_/, "")
			.replace(/^item_/, "")
			.replace(/_/g, " ")
			.replace(/\s+/g, " ")
			.replace(/^\s+|\s+$/g, "");

		return text.toUpperCase();
	}

	function FormatBotAbilityName(abilityName) {
		abilityName = NormalizeTextValue(abilityName);
		if (!abilityName) {
			return "";
		}

		var token = "#DOTA_Tooltip_ability_" + abilityName;
		var localized = SafeValue(function () {
			return $.Localize(token);
		}, "");
		if (localized && localized !== token) {
			return localized.toUpperCase();
		}

		return PrettyBotIdentifier(abilityName);
	}

	function FormatBotItemName(itemName) {
		itemName = NormalizeTextValue(itemName);
		if (!itemName) {
			return "";
		}

		var token = "#DOTA_Tooltip_ability_" + itemName;
		var localized = SafeValue(function () {
			return $.Localize(token);
		}, "");
		if (localized && localized !== token) {
			return localized.toUpperCase();
		}

		return PrettyBotIdentifier(itemName);
	}

	function FormatBotTargetName(targetName) {
		targetName = NormalizeTextValue(targetName).toLowerCase();
		if (!targetName) {
			return "";
		}
		if (targetName.indexOf("baristol") >= 0) {
			return "BARISTOL";
		}
		if (targetName.indexOf("ramero") >= 0) {
			return "RAMERO";
		}
		if (targetName.indexOf("sogat") >= 0) {
			return "SOGAT";
		}
		if (targetName.indexOf("muradin") >= 0) {
			return "MURADIN";
		}
		if (targetName.indexOf("dragon") >= 0) {
			return "DRAGON";
		}
		if (targetName.indexOf("boss") >= 0) {
			return "BOSS";
		}
		if (targetName.indexOf("creep") >= 0 || targetName.indexOf("wave") >= 0) {
			return "WAVE";
		}
		return PrettyBotIdentifier(targetName);
	}

	function BotActivity(label, tone) {
		return {
			label: label,
			tone: tone || "Unknown",
		};
	}

	function ResolveBotShopActivity(data, travelling) {
		var shop = NormalizeTextValue(data.shopping_shop).toLowerCase();
		var itemName = FormatBotItemName(data.shopping_item || data.planned_item);
		var isSecret = shop === "secret" || shop.indexOf("secret") >= 0 || shop.indexOf("castle") >= 0;
		var forceBase = ToNumber(data.shopping_force_home, 0) > 0 || shop === "base";
		var label = "";
		var tone = isSecret ? "Secret" : "Economy";

		if (travelling) {
			label = isSecret ? "TO SECRET SHOP" : forceBase ? "TO BASE SHOP" : "TO NORMAL SHOP";
		} else {
			label = isSecret ? "BUYING @ SECRET" : forceBase ? "BUYING @ BASE" : "BUYING ITEM";
		}
		if (itemName) {
			label += ": " + itemName;
		}
		return BotActivity(label, tone);
	}

	function ResolveBotActivity(data) {
		data = data || {};
		var state = NormalizeTextValue(data.state).toUpperCase();
		var macroState = NormalizeTextValue(data.macro_state).toUpperCase();
		var decision = NormalizeTextValue(data.last_decision).toLowerCase();
		var goal = NormalizeTextValue(data.goal).toLowerCase();
		var eventName = NormalizeTextValue(data.event).toLowerCase();
		var encounter = NormalizeTextValue(data.encounter_mode).toLowerCase();
		var reason = NormalizeTextValue(data.last_decision_reason).toLowerCase();
		var lane = Math.max(0, Math.floor(ToNumber(data.lane, 0)));
		var laneSuffix = lane > 0 ? " " + lane : "";
		var targetName = FormatBotTargetName(data.decision_target || data.target);
		var abilityName = FormatBotAbilityName(data.decision_ability || data.last_ability);

		if (state === "SELECTING_HERO" || macroState === "SELECTING_HERO") {
			return BotActivity("SELECTING HERO", "Idle");
		}
		if (state === "DEAD" || macroState === "DEAD" || decision === "dead") {
			return BotActivity("DEAD", "Idle");
		}
		if (state === "UNSUPPORTED_HERO") {
			return BotActivity("AI PROFILE MISSING", "Danger");
		}
		if (state === "STUCK_RECOVERY") {
			return BotActivity("RECOVERING PATH", "Danger");
		}

		if (state === "MURADIN_SURVIVAL" || macroState === "MURADIN_SURVIVAL" || encounter === "muradin_survival") {
			if (decision === "cast_ability") {
				return BotActivity("EMERGENCY HEAL", "Support");
			}
			if (decision === "hold") {
				return BotActivity("HIDING FROM MURADIN", "Event");
			}
			return BotActivity("ESCAPING MURADIN", "Danger");
		}

		if (state === "COLLECTING_RUNE" || data.decision_objective === "rune") {
			return BotActivity("GOING TO RUNE", "Move");
		}
		if (state === "BREAKING_CRATE" || decision === "break_crate") {
			return BotActivity("BREAKING CRATE", "Economy");
		}
		if (state === "PICKING_UP_LOOT" || decision === "pickup_loot") {
			var lootItem = FormatBotAbilityName(data.loot_item || data.decision_target);
			return BotActivity(lootItem ? "PICKING UP: " + lootItem : "PICKING UP LOOT", "Economy");
		}
		if (state === "EVADING_DANGER" || decision === "evade_danger") {
			return BotActivity("DODGING DANGER", "Danger");
		}
		if (state === "RETREATING" || decision === "retreat") {
			return BotActivity("RETREATING TO SAFETY", "Danger");
		}
		if (state === "REPOSITIONING" || decision === "reposition") {
			return BotActivity("REPOSITIONING", "Move");
		}
		if (state === "SEARCHING_LAST_SEEN" || decision === "move_to_last_seen") {
			return BotActivity("CHECKING LAST SEEN", "Move");
		}
		if ((state === "PATROLLING_ANCIENT" || macroState === "PATROLLING_ANCIENT") &&
			(decision === "move_to_objective" || decision === "attack_move" || decision === "hold")) {
			return BotActivity("PATROLLING ANCIENT", "Defense");
		}

		switch (decision) {
			case "cast_ability":
				if (state === "HEALING" || data.decision_mode === "ally_heal") {
					return BotActivity(abilityName ? "HEALING: " + abilityName : "HEALING ALLY", "Support");
				}
				if (data.decision_mode === "rifle_attack_mode" ||
					data.decision_mode === "toggle_single" ||
					data.decision_mode === "toggle_aoe" ||
					data.decision_mode === "defensive_toggle" ||
					data.decision_mode === "autocast_attack") {
					var toggleVerb = ToNumber(data.decision_desired_state, 0) > 0 ? "ENABLING: " : "DISABLING: ";
					return BotActivity(abilityName ? toggleVerb + abilityName : "SWITCHING MODE", "Combat");
				}
				return BotActivity(abilityName ? "CASTING: " + abilityName : "CASTING ABILITY", "Combat");

			case "attack_target":
				if (state === "ARENA_COMBAT" || macroState === "RAMERO_BARISTOL_ARENA" ||
					macroState === "SOGAT_ARENA" || encounter === "ramero_baristol" || encounter === "sogat") {
					return BotActivity(targetName ? "FIGHTING " + targetName : "FIGHTING ARENA BOSS", "Event");
				}
				if (state === "FARM_EVENT" || macroState === "FARM_EVENT" || eventName === "farm_event") {
					return BotActivity("FARMING EVENT", "Event");
				}
				if (goal === "defend_base" || state === "DEFENDING_BASE" || macroState === "DEFENDING_BASE") {
					return BotActivity("DEFENDING ANCIENT", "Defense");
				}
				if (state === "FIGHTING_BOSS" || macroState === "FIGHTING_BOSS" || goal === "fight_boss") {
					return BotActivity(targetName ? "FIGHTING " + targetName : "FIGHTING BOSS", "Combat");
				}
				if (goal === "defend_phase2" || macroState === "DEFENDING_SIDE") {
					return BotActivity("DEFENDING PHASE 2", "Defense");
				}
				if (goal === "defend_lane" || macroState === "DEFENDING_LANE") {
					return BotActivity("DEFENDING LANE" + laneSuffix, "Defense");
				}
				return BotActivity(targetName && targetName !== "WAVE" ? "FIGHTING " + targetName : "FIGHTING WAVE", "Combat");

			case "attack_move":
				if (macroState === "RETURNING_TO_LANE") {
					return BotActivity("RETURNING TO LANE" + laneSuffix, "Move");
				}
				if (goal === "defend_base" || macroState === "DEFENDING_BASE") {
					return BotActivity("DEFENDING ANCIENT", "Defense");
				}
				if (state === "ARENA_COMBAT") {
					return BotActivity("REACQUIRING ARENA BOSS", "Event");
				}
				if (state === "FARM_EVENT" || eventName === "farm_event") {
					return BotActivity("FARMING EVENT", "Event");
				}
				if (goal === "defend_lane" || macroState === "DEFENDING_LANE") {
					return BotActivity("ADVANCING LANE" + laneSuffix, "Defense");
				}
				return BotActivity("ADVANCING TO OBJECTIVE", "Move");

			case "move_to_objective":
				if (goal === "shop" || macroState === "SHOPPING") {
					return ResolveBotShopActivity(data, true);
				}
				if (reason.indexOf("campfire") >= 0) {
					return BotActivity("GOING TO CAMPFIRE", "Support");
				}
				if (macroState === "RETURNING_TO_LANE") {
					return BotActivity("RETURNING TO LANE" + laneSuffix, "Move");
				}
				if (goal === "defend_base" || macroState === "DEFENDING_BASE") {
					return BotActivity("RESPONDING TO ANCIENT", "Defense");
				}
				if (goal === "defend_phase2" || macroState === "DEFENDING_SIDE") {
					return BotActivity("MOVING TO PHASE 2", "Move");
				}
				if (goal === "regroup" || macroState === "REGROUPING") {
					return BotActivity("REGROUPING", "Move");
				}
				if (goal === "defend_lane" || macroState === "DEFENDING_LANE") {
					return BotActivity("GOING TO LANE" + laneSuffix, "Move");
				}
				return BotActivity("GOING TO OBJECTIVE", "Move");

			case "hold":
				if (goal === "shop" || macroState === "SHOPPING") {
					return ResolveBotShopActivity(data, false);
				}
				if (goal === "defend_base" || macroState === "DEFENDING_BASE") {
					return BotActivity("GUARDING ANCIENT", "Defense");
				}
				if (goal === "defend_lane" || macroState === "DEFENDING_LANE") {
					return BotActivity("HOLDING LANE" + laneSuffix, "Defense");
				}
				if (state === "FARM_EVENT" || eventName === "farm_event") {
					return BotActivity("WAITING IN FARM EVENT", "Event");
				}
				return BotActivity("HOLDING POSITION", "Idle");

			case "wait":
				return BotActivity("WAITING — DISABLED", "Idle");

			case "dead":
				return BotActivity("DEAD", "Idle");
		}

		if (state === "HEALING") {
			return BotActivity("HEALING", "Support");
		}
		if (state === "ARENA_COMBAT") {
			return BotActivity("FIGHTING ARENA BOSS", "Event");
		}
		if (state === "FARM_EVENT" || macroState === "FARM_EVENT") {
			return BotActivity("FARMING EVENT", "Event");
		}
		if (state === "FIGHTING_BOSS" || macroState === "FIGHTING_BOSS") {
			return BotActivity("FIGHTING BOSS", "Combat");
		}
		if (state === "FIGHTING_WAVE") {
			return BotActivity("FIGHTING WAVE", "Combat");
		}
		if (macroState === "RETURNING_TO_LANE") {
			return BotActivity("RETURNING TO LANE" + laneSuffix, "Move");
		}
		if (macroState === "DEFENDING_BASE") {
			return BotActivity("DEFENDING ANCIENT", "Defense");
		}
		if (macroState === "PATROLLING_ANCIENT") {
			return BotActivity("PATROLLING ANCIENT", "Defense");
		}
		if (macroState === "DEFENDING_LANE") {
			return BotActivity("DEFENDING LANE" + laneSuffix, "Defense");
		}
		if (macroState === "DEFENDING_SIDE") {
			return BotActivity("DEFENDING PHASE 2", "Defense");
		}
		if (macroState === "SHOPPING") {
			return ResolveBotShopActivity(data, true);
		}
		if (macroState === "REGROUPING") {
			return BotActivity("REGROUPING", "Move");
		}

		var fallback = PrettyBotIdentifier(decision || state || macroState || "initializing");
		return BotActivity("AI: " + fallback, "Unknown");
	}

	function ApplyBotActivityToOverhead(playerID) {
		var label = overheadLabels[playerID];
		if (!label) {
			return;
		}

		var activityPanel = label.FindChildTraverse("XHSOverheadBotActivity_" + playerID);
		var activityLabel = label.FindChildTraverse("XHSOverheadBotActivityLabel_" + playerID);
		var nextPurchasePanel = label.FindChildTraverse("XHSOverheadBotNextPurchase_" + playerID);
		var nextPurchaseLabel = label.FindChildTraverse("XHSOverheadBotNextPurchaseLabel_" + playerID);
		var debugState = botActivityStates[playerID];
		var visible = !!debugState;
		var plannedItem = visible ? FormatBotItemName(debugState.planned_item) : "";
		var nextPurchaseVisible = plannedItem !== "";

		label.SetHasClass("XHSOverheadBotActivityVisible", visible);
		label.SetHasClass("XHSOverheadBotNextPurchaseVisible", nextPurchaseVisible);
		if (nextPurchasePanel && nextPurchaseLabel) {
			nextPurchaseLabel.text = nextPurchaseVisible ? "NEXT: " + plannedItem : "";
		}
		if (!activityPanel || !activityLabel) {
			return;
		}

		for (var i = 0; i < BOT_ACTIVITY_TONE_CLASSES.length; i++) {
			activityPanel.SetHasClass(BOT_ACTIVITY_TONE_CLASSES[i], false);
		}
		if (!visible) {
			activityLabel.text = "";
			return;
		}

		var activity = ResolveBotActivity(debugState);
		activityLabel.text = activity.label;
		activityPanel.AddClass("XHSBotActivityTone" + activity.tone);
	}

	function RefreshBotActivityStates() {
		var roster = CustomNetTables.GetTableValue("xhs_bots", "roster") || {};
		var players = roster.players || {};
		var activeBots = {};

		for (var key in players) {
			if (!players.hasOwnProperty(key)) {
				continue;
			}
			var rosterEntry = players[key] || {};
			var playerID = Math.floor(ToNumber(rosterEntry.player_id, ToNumber(key, -1)));
			if (playerID < 0) {
				continue;
			}
			activeBots[playerID] = true;
			var debugState = CustomNetTables.GetTableValue("xhs_bots", "debug_" + playerID);
			botActivityStates[playerID] = debugState || {
				state: "INITIALIZING",
				macro_state: "SELECTING_HERO",
				last_decision: "",
			};
			ApplyBotActivityToOverhead(playerID);
		}

		for (var storedPlayerID in botActivityStates) {
			if (!botActivityStates.hasOwnProperty(storedPlayerID)) {
				continue;
			}
			var numericPlayerID = Math.floor(ToNumber(storedPlayerID, -1));
			if (!activeBots[numericPlayerID]) {
				delete botActivityStates[storedPlayerID];
				ApplyBotActivityToOverhead(numericPlayerID);
			}
		}
	}

	function OnXHSBotsNetTableChanged(tableName, key, data) {
		key = NormalizeTextValue(key);
		if (key === "roster") {
			RefreshBotActivityStates();
			return;
		}
		if (key.indexOf("debug_") !== 0) {
			return;
		}

		var playerID = Math.floor(ToNumber(key.substr(6), -1));
		if (playerID < 0) {
			return;
		}
		if (data) {
			botActivityStates[playerID] = data;
		} else {
			delete botActivityStates[playerID];
		}
		ApplyBotActivityToOverhead(playerID);
	}

	function GetHeroIconName(heroName) {
		heroName = NormalizeTextValue(heroName);
		if (!heroName) {
			return "";
		}

		return heroName.replace(/^npc_dota_hero_/, "");
	}

	function SetOverheadHeroImage(portrait, heroName) {
		heroName = NormalizeTextValue(heroName);
		if (!portrait || !heroName) {
			if (portrait) {
				portrait.AddClass("XHSOverheadHeroPortraitMissing");
			}
			return;
		}

		portrait.RemoveClass("XHSOverheadHeroPortraitMissing");

		if (portrait.GetAttributeInt("xhs_hero_image_fallback", 0) > 0) {
			portrait.style.backgroundImage = "url(\"file://{images}/heroes/icons/" + GetHeroIconName(heroName) + ".png\")";
			return;
		}

		portrait.heroimagestyle = "icon";
		portrait.heroname = heroName;
	}

	function GetSelectedEntitySet() {
		var localPlayerID = GetLocalPlayerID();
		var selectedEntities = SafeValue(function () {
			return Players.GetSelectedEntities(localPlayerID);
		}, null);

		if (!selectedEntities) {
			selectedEntities = SafeValue(function () {
				return GameUI.GetSelectedEntities();
			}, []);
		}

		var selected = {};
		for (var index = 0; selectedEntities && index < selectedEntities.length; index++) {
			var entIndex = parseInt(selectedEntities[index], 10);
			if (IsValidEntityIndex(entIndex)) {
				selected[entIndex] = true;
			}
		}

		return selected;
	}

	function UpdateOverheadSelectionStates() {
		var selectedEntities = GetSelectedEntitySet();
		var isAltDown = SafeValue(function () {
			return GameUI.IsAltDown();
		}, false);

		for (var playerID in overheadLabels) {
			if (!overheadLabels.hasOwnProperty(playerID)) {
				continue;
			}

			var label = overheadLabels[playerID];
			var entIndex = label ? label.GetAttributeInt("ent_index", -1) : -1;
			var isSelected = !!selectedEntities[entIndex];
			var isReincarnating = label && label.BHasClass && label.BHasClass("IsReincarnating");

			if (label) {
				label.SetHasClass("IsSelectedHero", isSelected);
				label.SetHasClass("XHSOverheadSelectedHero", isSelected);
			}
		}
	}

	function CreateOverheadLabel(playerID) {
		var root = Panel("XHSOverheadRoot");
		if (!root) {
			return null;
		}

		var label = $.CreatePanel("Panel", root, "XHSOverheadLabel_" + playerID);
		label.AddClass("XHSOverheadLabel");
		label.SetAttributeInt("player_id", playerID);
		label.SetAttributeInt("ent_index", -1);
		label.SetAttributeInt("position_ent_index", -1);
		label.hittest = false;

		// Bot intent is a separate world-space caption.  It must never become
		// a child of XHSOverheadBars: doing so changes the health/mana layout.
		var botNextPurchase = $.CreatePanel("Panel", label, "XHSOverheadBotNextPurchase_" + playerID);
		botNextPurchase.AddClass("XHSOverheadBotNextPurchase");
		botNextPurchase.hittest = false;

		var botNextPurchaseNode = $.CreatePanel("Panel", botNextPurchase, "XHSOverheadBotNextPurchaseNode_" + playerID);
		botNextPurchaseNode.AddClass("XHSOverheadBotNextPurchaseNode");
		botNextPurchaseNode.hittest = false;

		var botNextPurchaseLabel = $.CreatePanel("Label", botNextPurchase, "XHSOverheadBotNextPurchaseLabel_" + playerID);
		botNextPurchaseLabel.AddClass("XHSOverheadBotNextPurchaseLabel");
		botNextPurchaseLabel.hittest = false;

		var botActivity = $.CreatePanel("Panel", label, "XHSOverheadBotActivity_" + playerID);
		botActivity.AddClass("XHSOverheadBotActivity");
		botActivity.hittest = false;

		var botActivityNode = $.CreatePanel("Panel", botActivity, "XHSOverheadBotActivityNode_" + playerID);
		botActivityNode.AddClass("XHSOverheadBotActivityNode");
		botActivityNode.hittest = false;

		var botActivityLabel = $.CreatePanel("Label", botActivity, "XHSOverheadBotActivityLabel_" + playerID);
		botActivityLabel.AddClass("XHSOverheadBotActivityLabel");
		botActivityLabel.hittest = false;

		var frameArt = $.CreatePanel("Panel", label, "XHSOverheadFrameArt_" + playerID);
		frameArt.AddClass("XHSOverheadFrameArt");
		frameArt.hittest = false;

		var tombstoneCard = $.CreatePanel("Panel", label, "XHSOverheadTombstoneCard_" + playerID);
		tombstoneCard.AddClass("XHSOverheadTombstoneCard");
		tombstoneCard.hittest = false;
		var tombstoneMark = $.CreatePanel("Panel", tombstoneCard, "XHSOverheadTombstoneMark_" + playerID);
		tombstoneMark.AddClass("XHSOverheadTombstoneMark");
		tombstoneMark.hittest = false;
		var tombstoneRuneVertical = $.CreatePanel("Panel", tombstoneMark, "");
		tombstoneRuneVertical.AddClass("XHSOverheadTombstoneRuneVertical");
		tombstoneRuneVertical.hittest = false;
		var tombstoneRuneHorizontal = $.CreatePanel("Panel", tombstoneMark, "");
		tombstoneRuneHorizontal.AddClass("XHSOverheadTombstoneRuneHorizontal");
		tombstoneRuneHorizontal.hittest = false;
		var tombstoneRuneCore = $.CreatePanel("Panel", tombstoneMark, "");
		tombstoneRuneCore.AddClass("XHSOverheadTombstoneRuneCore");
		tombstoneRuneCore.hittest = false;
		var tombstoneCopy = $.CreatePanel("Panel", tombstoneCard, "XHSOverheadTombstoneCopy_" + playerID);
		tombstoneCopy.AddClass("XHSOverheadTombstoneCopy");
		tombstoneCopy.hittest = false;
		var tombstoneTitle = $.CreatePanel("Label", tombstoneCopy, "XHSOverheadTombstoneTitle_" + playerID);
		tombstoneTitle.AddClass("XHSOverheadTombstoneTitle");
		tombstoneTitle.hittest = false;
		var tombstoneAction = $.CreatePanel("Label", tombstoneCopy, "XHSOverheadTombstoneAction_" + playerID);
		tombstoneAction.AddClass("XHSOverheadTombstoneAction");
		tombstoneAction.text = "RIGHT-CLICK TO REVIVE";
		tombstoneAction.hittest = false;

		var value = $.CreatePanel("Label", label, "XHSOverheadValue_" + playerID);
		value.AddClass("XHSOverheadValue");
		value.hittest = false;

		var content = $.CreatePanel("Panel", label, "XHSOverheadContent_" + playerID);
		content.AddClass("XHSOverheadContent");
		content.hittest = false;

		var leftContent = $.CreatePanel("Panel", content, "XHSOverheadLeftContent_" + playerID);
		leftContent.AddClass("XHSOverheadLeftContent");
		leftContent.hittest = false;

		var centerContent = $.CreatePanel("Panel", content, "XHSOverheadCenterContent_" + playerID);
		centerContent.AddClass("XHSOverheadCenterContent");
		centerContent.hittest = false;

		var rightContent = $.CreatePanel("Panel", content, "XHSOverheadRightContent_" + playerID);
		rightContent.AddClass("XHSOverheadRightContent");
		rightContent.hittest = false;

		var portraitFrame = $.CreatePanel("Panel", leftContent, "XHSOverheadHeroPortraitFrame_" + playerID);
		portraitFrame.AddClass("XHSOverheadHeroPortraitFrame");
		portraitFrame.hittest = false;

		CreateOverheadHeroImage(portraitFrame, "XHSOverheadHeroPortrait_" + playerID);

		var topRow = $.CreatePanel("Panel", centerContent, "XHSOverheadTopRow_" + playerID);
		topRow.AddClass("XHSOverheadTopRow");
		topRow.hittest = false;

		var tierOverline = $.CreatePanel("Label", topRow, "XHSOverheadTierOverline_" + playerID);
		tierOverline.AddClass("XHSOverheadTierOverline");
		tierOverline.hittest = false;

		var nameBg = $.CreatePanel("Panel", topRow, "XHSOverheadNameBg_" + playerID);
		nameBg.AddClass("XHSOverheadNameBg");
		nameBg.hittest = false;

		var nameShimmer = $.CreatePanel("Panel", topRow, "XHSOverheadNameShimmer_" + playerID);
		nameShimmer.AddClass("XHSOverheadNameShimmer");
		nameShimmer.hittest = false;

		var name = $.CreatePanel("Label", topRow, "XHSOverheadName_" + playerID);
		name.AddClass("XHSOverheadName");
		name.hittest = false;

		var statusRow = $.CreatePanel("Panel", centerContent, "XHSOverheadStatusRow_" + playerID);
		statusRow.AddClass("XHSOverheadStatusRow");
		statusRow.hittest = false;

		var node = $.CreatePanel("Panel", statusRow, "XHSOverheadStatusNode_" + playerID);
		node.AddClass("XHSOverheadStatusNode");
		node.hittest = false;

		var gameplayStatus = $.CreatePanel("Label", statusRow, "XHSOverheadGameplayStatus_" + playerID);
		gameplayStatus.AddClass("XHSOverheadGameplayStatus");
		gameplayStatus.hittest = false;

		var altStatus = $.CreatePanel("Label", statusRow, "XHSOverheadAltStatus_" + playerID);
		altStatus.AddClass("XHSOverheadAltStatus");
		altStatus.hittest = false;

		var bars = $.CreatePanel("Panel", centerContent, "XHSOverheadBars_" + playerID);
		bars.AddClass("XHSOverheadBars");
		bars.hittest = false;

		var vitalsFrame = $.CreatePanel("Panel", bars, "XHSOverheadVitalsFrame_" + playerID);
		vitalsFrame.AddClass("XHSOverheadVitalsFrame");
		vitalsFrame.hittest = false;

		var healthFrame = $.CreatePanel("Panel", bars, "XHSOverheadHealthFrame_" + playerID);
		healthFrame.AddClass("XHSOverheadHealthFrame");
		healthFrame.hittest = false;

		var healthLag = $.CreatePanel("Panel", healthFrame, "XHSOverheadHealthLag_" + playerID);
		healthLag.AddClass("XHSOverheadHealthLag");
		healthLag.hittest = false;

		var healthFill = $.CreatePanel("Panel", healthFrame, "XHSOverheadHealthFill_" + playerID);
		healthFill.AddClass("XHSOverheadHealthFill");
		healthFill.hittest = false;

		var healthTicks = $.CreatePanel("Panel", healthFrame, "XHSOverheadHealthTicks_" + playerID);
		healthTicks.AddClass("XHSOverheadHealthTicks");
		healthTicks.hittest = false;
		healthTicks.SetAttributeInt("xhs_tick_count", 0);

		var manaFrame = $.CreatePanel("Panel", bars, "XHSOverheadManaFrame_" + playerID);
		manaFrame.AddClass("XHSOverheadManaFrame");
		manaFrame.hittest = false;

		var manaFill = $.CreatePanel("Panel", manaFrame, "XHSOverheadManaFill_" + playerID);
		manaFill.AddClass("XHSOverheadManaFill");
		manaFill.hittest = false;

		var healthLevel = $.CreatePanel("Label", rightContent, "XHSOverheadHealthLevel_" + playerID);
		healthLevel.AddClass("XHSOverheadHealthLevel");
		healthLevel.hittest = false;

		var anchor = $.CreatePanel("Panel", label, "XHSOverheadAnchor_" + playerID);
		anchor.AddClass("XHSOverheadAnchor");
		anchor.hittest = false;

		var anchorDot = $.CreatePanel("Panel", label, "XHSOverheadAnchorDot_" + playerID);
		anchorDot.AddClass("XHSOverheadAnchorDot");
		anchorDot.hittest = false;

		ApplyBotActivityToOverhead(playerID);
		return label;
	}

	function GetOverheadHealthTickInterval(maxHealth) {
		var currentMaxHealth = Math.max(1, Math.floor(ToNumber(maxHealth, 1)));
		var minimumInterval = Math.max(OVERHEAD_HEALTH_TICK_INTERVAL, Math.ceil(currentMaxHealth / Math.max(1, OVERHEAD_HEALTH_MAX_TICKS)));

		for (var index = 0; index < OVERHEAD_HEALTH_TICK_INTERVALS.length; index++) {
			if (OVERHEAD_HEALTH_TICK_INTERVALS[index] >= minimumInterval) {
				return OVERHEAD_HEALTH_TICK_INTERVALS[index];
			}
		}

		return Math.ceil(minimumInterval / 1000000) * 1000000;
	}

	function GetOverheadHealthTickClass(interval) {
		if (interval >= 100000) {
			return "XHSOverheadHealthTickMassive";
		}

		if (interval >= 10000) {
			return "XHSOverheadHealthTickHuge";
		}

		if (interval > OVERHEAD_HEALTH_TICK_INTERVAL) {
			return "XHSOverheadHealthTickLarge";
		}

		return "";
	}

	function UpdateOverheadHealthTicks(label, playerID, maxHealth) {
		var ticks = label ? label.FindChildTraverse("XHSOverheadHealthTicks_" + playerID) : null;
		if (!ticks) {
			return;
		}

		var currentMaxHealth = Math.max(1, Math.floor(ToNumber(maxHealth, 1)));
		var tickInterval = GetOverheadHealthTickInterval(currentMaxHealth);
		var tickCount = Math.max(0, Math.floor((currentMaxHealth - 1) / tickInterval));
		var tickClass = GetOverheadHealthTickClass(tickInterval);
		var previousTickCount = ticks.GetAttributeInt("xhs_tick_count", -1);
		var previousTickInterval = ticks.GetAttributeInt("xhs_tick_interval", -1);

		if (previousTickCount !== tickCount || previousTickInterval !== tickInterval) {
			ticks.RemoveAndDeleteChildren();
			ticks.SetAttributeInt("xhs_tick_count", tickCount);
			ticks.SetAttributeInt("xhs_tick_interval", tickInterval);

			for (var tickIndex = 0; tickIndex < tickCount; tickIndex++) {
				var tick = $.CreatePanel("Panel", ticks, "XHSOverheadHealthTick_" + playerID + "_" + tickIndex);
				tick.AddClass("XHSOverheadHealthTick");
				if (tickClass !== "") {
					tick.AddClass(tickClass);
				}
				tick.hittest = false;
			}
		}

		for (var index = 0; index < tickCount; index++) {
			var tickPanel = ticks.FindChildTraverse("XHSOverheadHealthTick_" + playerID + "_" + index);
			if (!tickPanel) {
				continue;
			}

			var tickPercent = Clamp(((index + 1) / (tickCount + 1)) * 100, 0, 100);
			tickPanel.style.position = tickPercent.toFixed(3) + "% 0px 0px";
		}
	}

	function UpdateOverheadHealthLag(label, playerID, healthPercent) {
		var healthLag = label ? label.FindChildTraverse("XHSOverheadHealthLag_" + playerID) : null;
		if (!healthLag) {
			return;
		}

		var clampedPercent = Clamp(ToNumber(healthPercent, 0), 0, 100);
		var previousScaledPercent = label.GetAttributeInt("xhs_health_lag_percent", -1);
		var previousPercent = previousScaledPercent >= 0 ? previousScaledPercent / 1000 : -1;
		var scaledPercent = Math.floor(clampedPercent * 1000);
		var token = label.GetAttributeInt("xhs_health_lag_token", 0) + 1;

		label.SetAttributeInt("xhs_health_lag_token", token);
		label.SetAttributeInt("xhs_health_lag_percent", scaledPercent);

		if (previousPercent < 0 || clampedPercent >= previousPercent) {
			healthLag.style.transitionDuration = "0.08s";
			healthLag.style.width = clampedPercent + "%";
			return;
		}

		healthLag.style.transitionDuration = "0s";
		healthLag.style.width = previousPercent + "%";

		$.Schedule(0.05, function () {
			if (!label || !label.IsValid || !label.IsValid() || label.GetAttributeInt("xhs_health_lag_token", -1) !== token) {
				return;
			}

			var delayedLag = label.FindChildTraverse("XHSOverheadHealthLag_" + playerID);
			if (!delayedLag) {
				return;
			}

			delayedLag.style.transitionDuration = "0.55s";
			delayedLag.style.width = clampedPercent + "%";
		});
	}

	function SetOverheadMockupAccent(label, key, color) {
		var accent = NormalizeColorString(color || "#5ad0ff");
		var glow = ColorWithAlpha(accent, "88");
		var name = label.FindChildTraverse("XHSOverheadName_" + key);
		var node = label.FindChildTraverse("XHSOverheadStatusNode_" + key);
		var anchorDot = label.FindChildTraverse("XHSOverheadAnchorDot_" + key);

		if (name) {
			name.style.color = accent;
			name.style.textShadow = "0px 2px 3px #000000, 0px 0px 6px #000000, 0px 0px 5px " + glow;
		}
		if (node) {
			node.style.backgroundColor = accent;
			node.style.boxShadow = "fill " + glow + " 0px 0px 7px 0px";
		}
		if (anchorDot) {
			anchorDot.style.backgroundColor = accent;
			anchorDot.style.boxShadow = "fill " + glow + " 0px 0px 8px 0px";
		}
	}

	function AddMockupClassList(panel, classes) {
		if (!panel || !classes) {
			return;
		}

		for (var i = 0; i < classes.length; i++) {
			if (classes[i]) {
				panel.AddClass(classes[i]);
			}
		}
	}

	function CreateOverheadMockupPlate(parent, data, index) {
		var key = "Mock" + index;
		var cell = $.CreatePanel("Panel", parent, "XHSOverheadMockupCell_" + key);
		cell.AddClass("XHSOverheadTierDevCell");
		cell.hittest = false;

		var caption = $.CreatePanel("Label", cell, "XHSOverheadTierDevCaption_" + key);
		caption.AddClass("XHSOverheadTierDevCaption");
		caption.text = data.caption || "";
		caption.SetHasClass("XHSOverheadTierDevCaptionVisible", !!data.caption);
		caption.hittest = false;

		var label = $.CreatePanel("Panel", cell, "XHSOverheadMockup_" + key);
		label.AddClass("XHSOverheadLabel");
		label.AddClass("XHSOverheadMockupPlate");
		label.hittest = false;
		AddMockupClassList(label, data.classes);

		var frameArt = $.CreatePanel("Panel", label, "XHSOverheadFrameArt_" + key);
		frameArt.AddClass("XHSOverheadFrameArt");
		frameArt.hittest = false;

		var value = $.CreatePanel("Label", label, "XHSOverheadValue_" + key);
		value.AddClass("XHSOverheadValue");
		value.text = data.value || "";
		value.hittest = false;

		var content = $.CreatePanel("Panel", label, "XHSOverheadContent_" + key);
		content.AddClass("XHSOverheadContent");
		content.hittest = false;

		var leftContent = $.CreatePanel("Panel", content, "XHSOverheadLeftContent_" + key);
		leftContent.AddClass("XHSOverheadLeftContent");
		leftContent.hittest = false;

		var centerContent = $.CreatePanel("Panel", content, "XHSOverheadCenterContent_" + key);
		centerContent.AddClass("XHSOverheadCenterContent");
		centerContent.hittest = false;

		var rightContent = $.CreatePanel("Panel", content, "XHSOverheadRightContent_" + key);
		rightContent.AddClass("XHSOverheadRightContent");
		rightContent.hittest = false;

		var portraitFrame = $.CreatePanel("Panel", leftContent, "XHSOverheadHeroPortraitFrame_" + key);
		portraitFrame.AddClass("XHSOverheadHeroPortraitFrame");
		portraitFrame.hittest = false;
		var portrait = CreateOverheadHeroImage(portraitFrame, "XHSOverheadHeroPortrait_" + key);
		SetOverheadHeroImage(portrait, data.heroName);

		var topRow = $.CreatePanel("Panel", centerContent, "XHSOverheadTopRow_" + key);
		topRow.AddClass("XHSOverheadTopRow");
		topRow.hittest = false;

		var tierOverline = $.CreatePanel("Label", topRow, "XHSOverheadTierOverline_" + key);
		tierOverline.AddClass("XHSOverheadTierOverline");
		tierOverline.text = data.tierOverline || "";
		tierOverline.hittest = false;

		var nameBg = $.CreatePanel("Panel", topRow, "XHSOverheadNameBg_" + key);
		nameBg.AddClass("XHSOverheadNameBg");
		nameBg.hittest = false;

		var nameShimmer = $.CreatePanel("Panel", topRow, "XHSOverheadNameShimmer_" + key);
		nameShimmer.AddClass("XHSOverheadNameShimmer");
		nameShimmer.hittest = false;

		var name = $.CreatePanel("Label", topRow, "XHSOverheadName_" + key);
		name.AddClass("XHSOverheadName");
		name.text = data.name || "";
		name.hittest = false;

		var statusRow = $.CreatePanel("Panel", centerContent, "XHSOverheadStatusRow_" + key);
		statusRow.AddClass("XHSOverheadStatusRow");
		statusRow.hittest = false;

		var node = $.CreatePanel("Panel", statusRow, "XHSOverheadStatusNode_" + key);
		node.AddClass("XHSOverheadStatusNode");
		node.hittest = false;

		var gameplayStatus = $.CreatePanel("Label", statusRow, "XHSOverheadGameplayStatus_" + key);
		gameplayStatus.AddClass("XHSOverheadGameplayStatus");
		gameplayStatus.text = data.status || "";
		gameplayStatus.hittest = false;

		var altStatus = $.CreatePanel("Label", statusRow, "XHSOverheadAltStatus_" + key);
		altStatus.AddClass("XHSOverheadAltStatus");
		altStatus.text = data.altStatus || "";
		altStatus.hittest = false;

		var bars = $.CreatePanel("Panel", centerContent, "XHSOverheadBars_" + key);
		bars.AddClass("XHSOverheadBars");
		bars.hittest = false;

		var vitalsFrame = $.CreatePanel("Panel", bars, "XHSOverheadVitalsFrame_" + key);
		vitalsFrame.AddClass("XHSOverheadVitalsFrame");
		vitalsFrame.hittest = false;

		var healthFrame = $.CreatePanel("Panel", bars, "XHSOverheadHealthFrame_" + key);
		healthFrame.AddClass("XHSOverheadHealthFrame");
		healthFrame.hittest = false;

		var healthLag = $.CreatePanel("Panel", healthFrame, "XHSOverheadHealthLag_" + key);
		healthLag.AddClass("XHSOverheadHealthLag");
		healthLag.hittest = false;

		var healthFill = $.CreatePanel("Panel", healthFrame, "XHSOverheadHealthFill_" + key);
		healthFill.AddClass("XHSOverheadHealthFill");
		healthFill.hittest = false;

		var healthTicks = $.CreatePanel("Panel", healthFrame, "XHSOverheadHealthTicks_" + key);
		healthTicks.AddClass("XHSOverheadHealthTicks");
		healthTicks.hittest = false;
		healthTicks.SetAttributeInt("xhs_tick_count", 0);

		var manaFrame = $.CreatePanel("Panel", bars, "XHSOverheadManaFrame_" + key);
		manaFrame.AddClass("XHSOverheadManaFrame");
		manaFrame.hittest = false;

		var manaFill = $.CreatePanel("Panel", manaFrame, "XHSOverheadManaFill_" + key);
		manaFill.AddClass("XHSOverheadManaFill");
		manaFill.hittest = false;

		var healthLevel = $.CreatePanel("Label", rightContent, "XHSOverheadHealthLevel_" + key);
		healthLevel.AddClass("XHSOverheadHealthLevel");
		healthLevel.text = Math.max(1, ToNumber(data.level, 1)).toString();
		healthLevel.hittest = false;

		var anchor = $.CreatePanel("Panel", label, "XHSOverheadAnchor_" + key);
		anchor.AddClass("XHSOverheadAnchor");
		anchor.hittest = false;

		var anchorDot = $.CreatePanel("Panel", label, "XHSOverheadAnchorDot_" + key);
		anchorDot.AddClass("XHSOverheadAnchorDot");
		anchorDot.hittest = false;

		var healthPercent = Clamp(ToNumber(data.healthPercent, 100), 0, 100);
		var manaPercent = Clamp(ToNumber(data.manaPercent, 100), 0, 100);
		healthLag.style.width = healthPercent + "%";
		healthFill.style.width = healthPercent + "%";
		manaFill.style.width = manaPercent + "%";
		UpdateOverheadHealthTicks(label, key, data.maxHealth || 2500);

		label.SetHasClass("XHSOverheadLowHealth", healthPercent > 0 && healthPercent <= 30);
		label.SetHasClass("XHSNoMana", !!data.noMana);
		label.SetHasClass("IsDead", healthPercent <= 0 || !!data.dead);
		label.SetHasClass("IsReincarnating", !!data.reincarnating);
		label.SetHasClass("IsDisconnected", !!data.disconnected);
		label.SetHasClass("XHSOverheadMockupDualStatus", !!data.altStatus);
		label.SetHasClass("XHSOverheadHasTierOverline", !!data.tierOverline);

		SetOverheadMockupAccent(label, key, data.color);
		return label;
	}

	function CreateOverheadTopStatusMockup(parent, data, index) {
		var key = "TopMock" + index;
		var panel = $.CreatePanel("Panel", parent, "XHSOverheadTopStatusMockup_" + key);
		panel.AddClass("XHSOverheadTopStatusMockup");
		panel.hittest = false;
		AddMockupClassList(panel, data.classes);

		var portraitFrame = $.CreatePanel("Panel", panel, "XHSOverheadTopStatusPortraitFrame_" + key);
		portraitFrame.AddClass("XHSOverheadTopStatusPortraitFrame");
		portraitFrame.hittest = false;
		var portrait = CreateOverheadHeroImage(portraitFrame, "XHSOverheadTopStatusPortrait_" + key);
		SetOverheadHeroImage(portrait, data.heroName);

		var copy = $.CreatePanel("Panel", panel, "XHSOverheadTopStatusCopy_" + key);
		copy.AddClass("XHSOverheadTopStatusCopy");
		copy.hittest = false;

		var topLine = $.CreatePanel("Panel", copy, "XHSOverheadTopStatusTopLine_" + key);
		topLine.AddClass("XHSOverheadTopStatusTopLine");
		topLine.hittest = false;

		var name = $.CreatePanel("Label", topLine, "XHSOverheadTopStatusName_" + key);
		name.AddClass("XHSOverheadTopStatusName");
		name.text = data.name || "";
		name.hittest = false;

		var state = $.CreatePanel("Label", topLine, "XHSOverheadTopStatusState_" + key);
		state.AddClass("XHSOverheadTopStatusState");
		state.text = data.state || "";
		state.hittest = false;

		var detailLine = $.CreatePanel("Panel", copy, "XHSOverheadTopStatusDetailLine_" + key);
		detailLine.AddClass("XHSOverheadTopStatusDetailLine");
		detailLine.hittest = false;

		var detail = $.CreatePanel("Label", detailLine, "XHSOverheadTopStatusDetail_" + key);
		detail.AddClass("XHSOverheadTopStatusDetail");
		detail.text = data.detail || "";
		detail.hittest = false;

		var timer = $.CreatePanel("Label", detailLine, "XHSOverheadTopStatusTimer_" + key);
		timer.AddClass("XHSOverheadTopStatusTimer");
		timer.text = data.timer || "";
		timer.hittest = false;

		return panel;
	}

	function BuildOverheadTopStatusMockups() {
		var root = Panel("XHSOverheadTopStatusMockupRoot");
		if (!root) {
			return;
		}

		root.RemoveAndDeleteChildren();

		var statuses = [
			{ name: "LINA", heroName: "npc_dota_hero_lina", state: "RESPAWNING", detail: "DEAD / BUYBACK READY", timer: "42", classes: ["XHSOverheadTopStatusRespawn"] },
			{ name: "UNDYING", heroName: "npc_dota_hero_undying", state: "TOMBSTONE CHANNEL", detail: "PHASE 3 / NO ANKHS", timer: "HOLD", classes: ["XHSOverheadTopStatusTombstone"] },
		];

		for (var i = 0; i < statuses.length; i++) {
			CreateOverheadTopStatusMockup(root, statuses[i], i);
		}
	}

	function GetOverheadTierDevMockups() {
		var heroName = "npc_dota_hero_juggernaut";
		var common = {
			name: "BLADEMASTER",
			heroName: heroName,
			value: "5760 / 5760",
			status: "ANKH x2 / HERO LEVEL 16",
			level: 16,
			healthPercent: 86,
			manaPercent: 68,
			maxHealth: 5760,
		};

		function Entry(tier, caption, tierOverline, color, extraClasses) {
			var classes = ["XHSOverheadTierDevPlate", "XHSOverheadFrameTier" + tier, "XHSSupporterTier" + tier];
			if (tier > 0) {
				classes.push("XHSOverheadMockupDonator");
			}
			if (extraClasses) {
				for (var i = 0; i < extraClasses.length; i++) {
					classes.push(extraClasses[i]);
				}
			}

			return {
				name: common.name,
				heroName: common.heroName,
				value: common.value,
				status: common.status,
				level: common.level,
				healthPercent: common.healthPercent,
				manaPercent: common.manaPercent,
				maxHealth: common.maxHealth,
				caption: caption,
				tierOverline: tierOverline,
				color: color,
				classes: classes,
			};
		}

		return [
			Entry(0, "A / NON DONATOR", "", "#7db9d8"),
			Entry(1, "B / DONATOR", "DONATOR", "#70e39a"),
			Entry(2, "C / GOLDEN DONATOR", "GOLDEN DONATOR", "#ffcf66"),
			Entry(3, "D / EMBER DONATOR", "EMBER DONATOR", "#ff5a43"),
			Entry(4, "E / STONEGUARD DONATOR", "STONEGUARD DONATOR", "#5ad0ff", ["XHSOverheadSelectedHero"]),
			Entry(5, "F / EARTHWARDEN DONATOR", "EARTHWARDEN DONATOR", "#c99cff"),
		];
	}

	function BuildOverheadMockups() {
		var root = Panel("XHSOverheadMockupRoot");
		if (!root) {
			return;
		}

		root.RemoveAndDeleteChildren();
		root.SetHasClass("XHSOverheadTierDevView", OVERHEAD_TIER_DEV_VIEW);
		root.SetHasClass("XHSOverheadLegacyMockupView", OVERHEAD_MOCKUP_MODE && !OVERHEAD_TIER_DEV_VIEW);

		var topRoot = Panel("XHSOverheadTopStatusMockupRoot");
		if (topRoot && (!OVERHEAD_MOCKUP_MODE || OVERHEAD_TIER_DEV_VIEW)) {
			topRoot.RemoveAndDeleteChildren();
		}

		if (!OVERHEAD_MOCKUP_MODE && !OVERHEAD_TIER_DEV_VIEW) {
			return;
		}

		if (OVERHEAD_MOCKUP_MODE && !OVERHEAD_TIER_DEV_VIEW) {
			BuildOverheadTopStatusMockups();
		}

		var mockups = OVERHEAD_TIER_DEV_VIEW ? GetOverheadTierDevMockups() : [
			{ name: "MIRANA", heroName: "npc_dota_hero_mirana", value: "2140 / 2140", status: "ANKH x1 / HERO LEVEL 12", altStatus: "DEFAULT STATE", level: 12, healthPercent: 100, manaPercent: 68, maxHealth: 2140, color: "#7db9ff", classes: ["XHSOverheadMockupDefault"] },
			{ name: "JUGGERNAUT", heroName: "npc_dota_hero_juggernaut", value: "2840 / 2840", status: "SELECTING HERO", altStatus: "LOCK-IN PREVIEW", level: 18, healthPercent: 100, manaPercent: 82, maxHealth: 2840, color: "#5ad0ff", classes: ["XHSOverheadMockupSelecting", "XHSOverheadSelectedHero"] },
			{ name: "CRYSTAL MAIDEN", heroName: "npc_dota_hero_crystal_maiden", value: "1860 / 1860", status: "ANKH x2 / HERO LEVEL 16", altStatus: "GOLDEN DONATOR", level: 16, healthPercent: 88, manaPercent: 100, maxHealth: 1860, color: "#ffcf66", classes: ["XHSOverheadMockupDonator", "XHSSupporterTier2"] },
			{ name: "WRAITH KING", heroName: "npc_dota_hero_skeleton_king", value: "0 / 3920", status: "REINCARNATION IN 7s", altStatus: "EARTHWARDEN DONATOR", level: 22, healthPercent: 0, manaPercent: 18, maxHealth: 3920, color: "#c99cff", dead: true, reincarnating: true, classes: ["XHSOverheadMockupDonator", "XHSOverheadMockupReincarnating", "XHSSupporterTier5"] },
			{ name: "SNIPER", heroName: "npc_dota_hero_sniper", value: "1190 / 2140", status: "DISCONNECTED", altStatus: "LAST SEEN 00:41", level: 13, healthPercent: 56, manaPercent: 44, maxHealth: 2140, color: "#9fb2cc", disconnected: true, classes: ["XHSOverheadMockupDisconnected"] },
			{ name: "DROW RANGER", heroName: "npc_dota_hero_drow_ranger", value: "420 / 2360", status: "NO ANKH / HERO LEVEL 14", altStatus: "CRITICAL HEALTH", level: 14, healthPercent: 18, manaPercent: 23, maxHealth: 2360, color: "#ff735a", classes: ["XHSOverheadMockupCritical"] },
			{ name: "AXE", heroName: "npc_dota_hero_axe", value: "3060 / 4200", status: "NO MANA HERO", altStatus: "TANK FRONTLINE", level: 19, healthPercent: 73, manaPercent: 0, maxHealth: 4200, color: "#f05c45", noMana: true, classes: ["XHSOverheadMockupNoMana"] },
			{ name: "INVOKER", heroName: "npc_dota_hero_invoker", value: "740 / 3050", status: "SELECTED / ANKH x1", altStatus: "STONEGUARD DONATOR", level: 25, healthPercent: 24, manaPercent: 91, maxHealth: 3050, color: "#5ad0ff", classes: ["XHSOverheadMockupDonator", "XHSOverheadSelectedHero", "XHSSupporterTier4"] },
		];

		for (var i = 0; i < mockups.length; i++) {
			CreateOverheadMockupPlate(root, mockups[i], i);
		}
	}

	function ClearOverheadLabel(playerID) {
		if (overheadLabels[playerID]) {
			overheadLabels[playerID].DeleteAsync(0);
			delete overheadLabels[playerID];
		}
	}

	function EnsureOverheadLabel(playerID) {
		if (OVERHEAD_MOCKUP_MODE) {
			return null;
		}

		if (!overheadLabels[playerID]) {
			overheadLabels[playerID] = CreateOverheadLabel(playerID);
		}

		return overheadLabels[playerID];
	}

	function SetOverheadAccent(label, playerID, data, colorPlayerID) {
		if (!label) {
			return;
		}

		var supporterTier = data ? ToNumber(data.tier, 0) : 0;
		var supporterColor = data ? NormalizeColorString(data.tierColor) : "";
		var supporterAccent = supporterTier > 0 && supporterColor ? supporterColor : "#5ad0ff";
		var playerAccent = GetPlayerColorString(
			colorPlayerID === undefined || colorPlayerID === null ? playerID : colorPlayerID
		);
		var playerGlow = ColorWithAlpha(playerAccent, "88");
		var supporterGlow = ColorWithAlpha(supporterAccent, "88");
		var content = label.FindChildTraverse("XHSOverheadContent_" + playerID);
		var name = label.FindChildTraverse("XHSOverheadName_" + playerID);
		var node = label.FindChildTraverse("XHSOverheadStatusNode_" + playerID);
		var anchor = label.FindChildTraverse("XHSOverheadAnchor_" + playerID);
		var anchorDot = label.FindChildTraverse("XHSOverheadAnchorDot_" + playerID);

		if (content) {
			content.style.border = "0px solid transparent";
			content.style.borderLeft = "0px solid transparent";
		}
		if (name) {
			name.style.color = playerAccent;
			name.style.textShadow = "0px 2px 3px #000000, 0px 0px 6px #000000, 0px 0px 5px " + playerGlow;
		}
		if (node) {
			node.style.backgroundColor = supporterAccent;
			node.style.boxShadow = "fill " + supporterGlow + " 0px 0px 7px 0px";
		}
		if (anchor) {
			anchor.style.backgroundColor = "gradient( linear, 0% 0%, 0% 100%, from( " + ColorWithAlpha(supporterAccent, "b8") + " ), to( " + ColorWithAlpha(supporterAccent, "00") + " ) )";
			anchor.style.boxShadow = "fill " + supporterGlow + " 0px 0px 5px 0px";
		}
		if (anchorDot) {
			anchorDot.style.backgroundColor = supporterAccent;
			anchorDot.style.boxShadow = "fill " + supporterGlow + " 0px 0px 8px 0px";
		}
	}

	function GetOverheadStatusEffect(entIndex) {
		if (!IsValidEntityIndex(entIndex)) {
			return null;
		}

		var data = CustomNetTables.GetTableValue("player_table", entIndex.toString() + "_status_effect") || {};
		if (ToNumber(data.active, 0) <= 0 || !data.label || !data.class_name) {
			return null;
		}

		return data;
	}

	function ClearOverheadStatusClasses(label) {
		if (!label) {
			return;
		}

		for (var i = 0; i < OVERHEAD_STATUS_CLASSES.length; i++) {
			label.SetHasClass(OVERHEAD_STATUS_CLASSES[i], false);
		}
	}

	function FormatOverheadStatusLabel(statusEffect) {
		if (!statusEffect) {
			return "";
		}

		var label = NormalizeTextValue(statusEffect.label);
		var remaining = ToNumber(statusEffect.remaining, 0);
		var endTime = ToNumber(statusEffect.end_time, 0);

		if (endTime > 0) {
			remaining = Math.max(0, endTime - GetCurrentGameTime());
		}

		if (remaining > 0) {
			return label + " " + Math.ceil(remaining).toString() + "s";
		}

		return label;
	}

	function ApplyOverheadStatusEffect(label, playerID, statusEffect) {
		if (!label) {
			return;
		}

		ClearOverheadStatusClasses(label);

		var hasStatus = !!statusEffect;
		label.SetHasClass("XHSOverheadHasStatusEffect", hasStatus);
		if (hasStatus) {
			label.SetHasClass(statusEffect.class_name, true);
			var statusText = FormatOverheadStatusLabel(statusEffect);
			SetChildText(label, "XHSOverheadName_" + playerID, statusText);
			SetChildText(label, "XHSOverheadGameplayStatus_" + playerID, statusText);
			SetChildText(label, "XHSOverheadAltStatus_" + playerID, statusText);
		} else {
			var heroNameText = label.GetAttributeString("xhs_overhead_hero_label", "");
			if (heroNameText) {
				SetChildText(label, "XHSOverheadName_" + playerID, heroNameText);
			}
		}
	}

	function FormatOverheadGameplayStatus(data) {
		if (data.reincarnationState && data.reincarnationState.active) {
			return FormatReincarnationStatus(data.reincarnationState);
		}

		if (data.disconnected) {
			return "DISCONNECTED";
		}

		var ankh = Math.max(0, ToNumber(data.ankhCharges, 0));
		var ankhText = ankh > 0 ? "ANKH x" + ankh : "NO ANKH";
		return ankhText + " / HERO LEVEL " + Math.max(1, ToNumber(data.heroLevel, 1));
	}

	function FormatOverheadAltStatus(data) {
		return FormatOverheadGameplayStatus(data);
	}

	function FormatOverheadTierOverline(data) {
		if (!data || ToNumber(data.tier, 0) <= 0) {
			return "";
		}

		return data.tierName || "DONATOR";
	}

	function ResolvePlayerIdentity(playerID, entIndex, data) {
		data = data || {};
		if (typeof XHSNameDisplay !== "undefined" && XHSNameDisplay.Resolve) {
			return XHSNameDisplay.Resolve({
				playerID: playerID,
				entityIndex: entIndex,
				playerName: data.playerName,
				heroName: data.heroName,
				heroDisplayName: data.localHeroName || data.heroDisplayName,
			});
		}

		// Missing helper must remain privacy-safe: never fall back to persona name.
		return data.localHeroName || data.heroDisplayName || FormatUnitNameFallback(data.heroName) || "";
	}

	function UpdateOverheadLabelData(playerID, entIndex, labelKey) {
		var overheadKey = labelKey === undefined || labelKey === null ? playerID : labelKey;
		var label = EnsureOverheadLabel(overheadKey);
		if (!label || !IsValidEntityIndex(entIndex)) {
			return;
		}

		var data = GetSupporterPlayerData(playerID, entIndex);
		var displayName = ResolvePlayerIdentity(playerID, entIndex, data);

		label.SetAttributeInt("player_id", playerID);
		label.SetAttributeInt("ent_index", entIndex);
		label.SetHasClass("XHSOverheadLocalPlayer", playerID === GetLocalPlayerID());
		label.SetHasClass("IsDisconnected", !!data.disconnected);

		ClearSupporterTierClasses(label);
		label.AddClass("XHSSupporterTier" + data.tier);
		label.AddClass("XHSOverheadFrameTier" + data.tier);
		SetOverheadAccent(label, overheadKey, data, playerID);

		var tierOverline = FormatOverheadTierOverline(data);
		label.SetHasClass("XHSOverheadHasTierOverline", tierOverline !== "");
		label.SetAttributeString("xhs_overhead_hero_label", displayName);

		SetChildText(label, "XHSOverheadName_" + overheadKey, displayName);
		SetChildText(label, "XHSOverheadTierOverline_" + overheadKey, tierOverline);
		SetChildText(label, "XHSOverheadGameplayStatus_" + overheadKey, FormatOverheadGameplayStatus(data));
		SetChildText(label, "XHSOverheadAltStatus_" + overheadKey, FormatOverheadAltStatus(data));
		SetChildText(label, "XHSOverheadHealthLevel_" + overheadKey, Math.max(1, ToNumber(data.heroLevel, 1)).toString());
		SetChildText(label, "XHSOverheadTombstoneTitle_" + overheadKey, displayName || "FALLEN HERO");
		ApplyOverheadStatusEffect(label, overheadKey, GetOverheadStatusEffect(entIndex));
		if (overheadKey === playerID) {
			ApplyBotActivityToOverhead(playerID);
		}

		var portrait = label.FindChildTraverse("XHSOverheadHeroPortrait_" + overheadKey);
		SetOverheadHeroImage(portrait, data.heroName);
	}

	function UpdateOverheadLabelVitals(playerID, entIndex, healthPercent, manaPercent, health, maxHealth, hasMana, labelKey) {
		var overheadKey = labelKey === undefined || labelKey === null ? playerID : labelKey;
		var label = EnsureOverheadLabel(overheadKey);
		if (!label || !IsValidEntityIndex(entIndex)) {
			return;
		}

		var value = label.FindChildTraverse("XHSOverheadValue_" + overheadKey);
		var healthFill = label.FindChildTraverse("XHSOverheadHealthFill_" + overheadKey);
		var manaFill = label.FindChildTraverse("XHSOverheadManaFill_" + overheadKey);
		var clampedHealth = Clamp(ToNumber(healthPercent, 0), 0, 100);
		var currentHealth = Math.max(0, Math.floor(ToNumber(health, 0)));
		var currentMaxHealth = Math.max(1, Math.floor(ToNumber(maxHealth, 1)));
		var reincarnationState = GetReincarnationState(entIndex);
		var tombstoneState = GetTombstoneReviveState(entIndex);
		var tombstoneEntIndex = Math.floor(ToNumber(tombstoneState.tombstoneEntIndex, -1));
		var hasTombstone = clampedHealth <= 0 && IsValidEntityIndex(tombstoneEntIndex) && SafeValue(function () {
			return typeof Entities.IsValidEntity !== "function" || Entities.IsValidEntity(tombstoneEntIndex);
		}, true);
		var shouldHideDeadOverhead = clampedHealth <= 0 && !reincarnationState.active && GetAnkhCharges(entIndex) <= 0 && !hasTombstone;

		if (value) {
			value.text = FormatNumber(currentHealth) + " / " + FormatNumber(currentMaxHealth);
		}
		label.SetHasClass("XHSOverheadHasVitals", currentMaxHealth > 1 || currentHealth > 0);

		if (healthFill) {
			healthFill.style.width = clampedHealth + "%";
		}
		UpdateOverheadHealthLag(label, overheadKey, clampedHealth);
		UpdateOverheadHealthTicks(label, overheadKey, currentMaxHealth);
		if (manaFill) {
			manaFill.style.width = Clamp(ToNumber(manaPercent, 0), 0, 100) + "%";
		}

		label.SetHasClass("IsDead", clampedHealth <= 0);
		label.SetHasClass("IsReincarnating", reincarnationState.active);
		label.SetHasClass("XHSOverheadLowHealth", clampedHealth > 0 && clampedHealth <= 30);
		label.SetHasClass("XHSOverheadTombstone", hasTombstone);
		label.SetHasClass("XHSNoMana", !hasMana);
		label.SetAttributeInt("death_hidden", shouldHideDeadOverhead ? 1 : 0);
		label.SetAttributeInt("position_ent_index", hasTombstone ? tombstoneEntIndex : -1);
		ApplyOverheadStatusEffect(label, overheadKey, GetOverheadStatusEffect(entIndex));

		if (hasTombstone) {
			SetChildText(label, "XHSOverheadGameplayStatus_" + overheadKey, "TOMBSTONE");
			SetChildText(label, "XHSOverheadAltStatus_" + overheadKey, "CLICK TO REVIVE");
		}
		if (reincarnationState.active) {
			SetChildText(label, "XHSOverheadGameplayStatus_" + overheadKey, FormatReincarnationStatus(reincarnationState));
		}

		if (shouldHideDeadOverhead) {
			SetOverheadLabelVisible(label, false);
		}
	}

	function UpdateOverheadLabelPosition(label) {
		if (!label) {
			return;
		}

		var root = Panel("XHSOverheadRoot");
		var entIndex = label.GetAttributeInt("ent_index", -1);
		var positionEntIndex = label.GetAttributeInt("position_ent_index", -1);
		if (!IsValidEntityIndex(positionEntIndex)) {
			positionEntIndex = entIndex;
		}
		var playerID = label.GetAttributeInt("player_id", -1);
		if (isHeroSelectionTransitionActive && playerID === GetLocalPlayerID()) {
			SetOverheadLabelVisible(label, false);
			return;
		}
		if (!root || !IsValidEntityIndex(positionEntIndex) || label.GetAttributeInt("death_hidden", 0) > 0) {
			SetOverheadLabelVisible(label, false);
			return;
		}

		var origin = SafeValue(function () {
			return Entities.GetAbsOrigin(positionEntIndex);
		}, null);
		var screen = ProjectWorldToScreen(origin);
		var rootWidth = Number(root.actuallayoutwidth || root.desiredlayoutwidth || 0);
		var rootHeight = Number(root.actuallayoutheight || root.desiredlayoutheight || 0);

		if (!screen || rootWidth <= 0 || rootHeight <= 0) {
			SetOverheadLabelVisible(label, false);
			return;
		}

		var normalizedX = screen.x / rootWidth;
		var bias = Clamp((0.5 - normalizedX) * OVERHEAD_PERSPECTIVE_BIAS, -28, 28);
		var x = screen.x + bias - (OVERHEAD_PLATE_WIDTH * 0.5);
		var y = screen.y - OVERHEAD_SCREEN_Y_OFFSET - OVERHEAD_PLATE_HEIGHT;
		var edgeFade = GetOverheadEdgeFade(x, y, rootWidth, rootHeight);
		var labelRect = {
			left: x,
			top: y,
			right: x + OVERHEAD_PLATE_WIDTH,
			bottom: y + OVERHEAD_LABEL_HEIGHT
		};
		var isVisible = edgeFade > 0;

		label.style.position = Math.floor(x) + "px " + Math.floor(y) + "px 0px";
		if (isVisible && DoesOverheadOverlapUi(labelRect, root, rootWidth, rootHeight)) {
			SetOverheadLabelVisible(label, false);
			return;
		}

		label.style.opacity = edgeFade.toFixed(2);
		SetOverheadLabelVisible(label, isVisible);
	}

	function RefreshOverheadPositions() {
		UpdateOverheadSelectionStates();

		for (var playerID in overheadLabels) {
			if (!overheadLabels.hasOwnProperty(playerID)) {
				continue;
			}

			UpdateOverheadLabelPosition(overheadLabels[playerID]);
		}
	}

	function CreateAllyHoverCard(card, playerID, isRightSide) {
		var hoverParent = Panel("XHSTopHudRoot") || card;
		if (typeof XHSSupporterHover !== "undefined" && XHSSupporterHover.Create) {
			XHSSupporterHover.Create(hoverParent, playerID, { isRightSide: isRightSide, extraStats: true });
		}
	}

	function GetFixedRosterSlotIndex(playerID, playerInfo) {
		var playerSlot = playerInfo ? parseInt(playerInfo.player_slot, 10) : NaN;
		if (!isNaN(playerSlot)) {
			if (playerSlot >= 128) {
				playerSlot -= 128;
			}

			if (playerSlot >= 0 && playerSlot < MAX_PLAYER_DISPLAY_SLOTS) {
				return playerSlot;
			}
		}

		playerID = parseInt(playerID, 10);
		if (isNaN(playerID) || playerID < 0 || playerID >= MAX_PLAYER_DISPLAY_SLOTS) {
			return -1;
		}

		return playerID;
	}

	function EnsureAllyRosterSlot(rosterIndex) {
		var isRightSide = rosterIndex >= 4;
		var roster = Panel(isRightSide ? "XHSAllyRosterRight" : "XHSAllyRosterLeft");
		if (!roster) {
			return null;
		}

		var slot = roster.FindChild("XHSAllySlot_" + rosterIndex);
		if (!slot) {
			slot = $.CreatePanel("Panel", roster, "XHSAllySlot_" + rosterIndex);
			slot.AddClass("XHSAllySlot");
			slot.SetAttributeInt("roster_index", rosterIndex);
			slot.hittest = false;
			slot.hittestchildren = true;
		}

		return slot;
	}

	function EnsureAllyRosterSlots() {
		for (var rosterIndex = 0; rosterIndex < MAX_PLAYER_DISPLAY_SLOTS; rosterIndex++) {
			EnsureAllyRosterSlot(rosterIndex);
		}
	}

	function CreateAllyCard(playerID, rosterIndex) {
		var isRightSide = rosterIndex >= 4;
		var slot = EnsureAllyRosterSlot(rosterIndex);
		if (!slot) {
			return null;
		}

		var card = $.CreatePanel("Panel", slot, "XHSAllyCard_" + playerID);
		card.AddClass("XHSAllyCard");
		card.SetAttributeInt("player_id", playerID);
		card.SetAttributeInt("ent_index", -1);
		card.SetAttributeInt("roster_side", isRightSide ? 1 : 0);
		card.SetAttributeInt("roster_index", rosterIndex);
		card.hittest = true;

		var colorStrip = $.CreatePanel("Panel", card, "XHSAllyColorStrip_" + playerID);
		colorStrip.AddClass("XHSAllyColorStrip");
		colorStrip.hittest = false;

		var imageWrap = $.CreatePanel("Panel", card, "XHSAllyImageWrap_" + playerID);
		imageWrap.AddClass("XHSAllyImageWrap");
		imageWrap.hittest = false;

		var heroImage = $.CreatePanel("DOTAHeroImage", imageWrap, "XHSAllyHeroImage_" + playerID);
		heroImage.AddClass("XHSAllyHeroImage");
		heroImage.heroimagestyle = "landscape";
		heroImage.scaling = "stretch-to-cover-preserve-aspect";
		heroImage.hittest = false;

		var supporterTint = $.CreatePanel("Panel", imageWrap, "XHSSupporterPortraitTint_" + playerID);
		supporterTint.AddClass("XHSSupporterPortraitTint");
		supporterTint.hittest = false;

		var supporterSweep = $.CreatePanel("Panel", imageWrap, "XHSSupporterPortraitSweep_" + playerID);
		supporterSweep.AddClass("XHSSupporterPortraitSweep");
		supporterSweep.hittest = false;

		var supporterMark = $.CreatePanel("Panel", imageWrap, "XHSSupporterMark_" + playerID);
		supporterMark.AddClass("XHSSupporterMark");
		supporterMark.hittest = false;

		var overlay = $.CreatePanel("Panel", imageWrap, "XHSAllyStatusOverlay_" + playerID);
		overlay.AddClass("XHSAllyStatusOverlay");
		overlay.hittest = false;

		var respawnLabel = $.CreatePanel("Label", imageWrap, "XHSAllyRespawnLabel_" + playerID);
		respawnLabel.AddClass("XHSAllyRespawnLabel");
		respawnLabel.text = "";
		respawnLabel.hittest = false;

		var disconnect = $.CreatePanel("Panel", imageWrap, "XHSDisconnectIcon_" + playerID);
		disconnect.AddClass("XHSDisconnectIcon");
		disconnect.hittest = false;

		var bars = $.CreatePanel("Panel", card, "XHSAllyBars_" + playerID);
		bars.AddClass("XHSAllyBars");
		bars.hittest = false;
		CreateProgressBar(bars, "XHSAllyHealthBar_" + playerID, "XHSAllyHealthBar");
		CreateProgressBar(bars, "XHSAllyManaBar_" + playerID, "XHSAllyManaBar");

		var meta = $.CreatePanel("Panel", card, "XHSAllyMeta_" + playerID);
		meta.AddClass("XHSAllyMeta");
		meta.hittest = false;

		var name = $.CreatePanel("Label", meta, "XHSAllyName_" + playerID);
		name.AddClass("XHSAllyName");
		name.hittest = false;

		var ankhBadge = $.CreatePanel("Panel", card, "XHSAnkhBadge_" + playerID);
		ankhBadge.AddClass("XHSAnkhBadge");
		ankhBadge.hittest = false;

		var ankhPip = $.CreatePanel("Panel", ankhBadge, "XHSAnkhPip_" + playerID);
		ankhPip.AddClass("XHSAnkhPip");
		ankhPip.hittest = false;

		var ankhLabel = $.CreatePanel("Label", ankhBadge, "XHSAnkhLabel_" + playerID);
		ankhLabel.AddClass("XHSAnkhLabel");
		ankhLabel.text = "ANKH";
		ankhLabel.hittest = false;

		var ankhCount = $.CreatePanel("Label", ankhBadge, "XHSAnkhCount_" + playerID);
		ankhCount.AddClass("XHSAnkhCount");
		ankhCount.text = "x0";
		ankhCount.hittest = false;

		card.SetPanelEvent("onactivate", function () {
			// Select immediately. SelectUnitWithoutVanillaDoubleCenter already
			// deduplicates the second activation of a double-click, so delaying
			// this action only makes single-click selection unreliable.
			SelectUnitOrCast(card.GetAttributeInt("ent_index", -1));
		});

		card.SetPanelEvent("ondblclick", function () {
			MoveCameraToUnit(card.GetAttributeInt("ent_index", -1));
		});

		card.SetPanelEvent("onmouseover", function () {
			ShowAllyHover(card, playerID);
		});

		card.SetPanelEvent("onmouseout", function () {
			HideAllyHover(card);
		});

		CreateAllyHoverCard(card, playerID, isRightSide);
		return card;
	}

	function DeleteAllyCard(playerID) {
		if (allyCards[playerID]) {
			allyCards[playerID].DeleteAsync(0);
			delete allyCards[playerID];
		}

		var hover = Panel("XHSSupporterHoverCard_" + playerID);
		if (hover) {
			hover.DeleteAsync(0);
		}
	}

	function GetRosterPlayerIDs() {
		var ids = SafeValue(function () {
			return Game.GetAllPlayerIDs();
		}, null);

		if (!ids || !ids.length) {
			ids = [];
			for (var scanID = 0; scanID <= MAX_PLAYER_ID_SCAN; scanID++) {
				var playerInfo = SafeValue(function () { return Game.GetPlayerInfo(scanID); }, null);
				var entIndex = SafeValue(function () { return Players.GetPlayerHeroEntityIndex(scanID); }, -1);
				if (playerInfo || IsValidEntityIndex(entIndex)) {
					ids.push(scanID);
				}
			}
		}

		var unique = {};
		var normalized = [];
		var goodGuysTeam = typeof DOTATeam_t !== "undefined" &&
			DOTATeam_t.DOTA_TEAM_GOODGUYS !== undefined
			? Number(DOTATeam_t.DOTA_TEAM_GOODGUYS)
			: 2;
		for (var i = 0; i < ids.length; i++) {
			var playerID = parseInt(ids[i], 10);
			if (isNaN(playerID) || playerID < 0 || unique[playerID]) {
				continue;
			}

			var playerInfo = SafeValue(function () {
				return Game.GetPlayerInfo(playerID);
			}, null);
			var playerTeam = SafeValue(function () {
				return Players.GetTeam(playerID);
			}, playerInfo ? playerInfo.player_team_id : -1);
			if ((playerTeam === undefined || playerTeam === null) && playerInfo) {
				playerTeam = playerInfo.player_team_id;
			}
			if (Number(playerTeam) !== goodGuysTeam) {
				continue;
			}

			var entIndex = SafeValue(function () {
				return Players.GetPlayerHeroEntityIndex(playerID);
			}, -1);
			var heroName = NormalizeTextValue(SafeValue(function () {
				return IsValidEntityIndex(entIndex) ? Entities.GetUnitName(entIndex) : "";
			}, ""));
			if (!heroName) {
				heroName = NormalizeTextValue(SafeValue(function () {
					return Players.GetPlayerSelectedHero(playerID);
				}, ""));
			}
			// Radiant Wisps are real roster occupants during hero selection
			// (and in spectator bot setups), so they must retain their top-bar
			// slot until ReplaceHeroWith updates that same player.
			if (!IsValidEntityIndex(entIndex)) {
				continue;
			}

			unique[playerID] = true;
			normalized.push(playerID);
		}

		normalized.sort(function (a, b) { return a - b; });
		return normalized.slice(0, MAX_PLAYER_DISPLAY_SLOTS);
	}

	function ClearSupporterTierClasses(panel) {
		if (!panel) {
			return;
		}

		for (var tier = 0; tier <= 5; tier++) {
			panel.RemoveClass("XHSSupporterTier" + tier);
			panel.RemoveClass("XHSOverheadFrameTier" + tier);
		}
	}

	function GetSupporterTierInfo(tier) {
		tier = NormalizeSupporterTierID(tier);
		return GetSupporterTierCatalog()[tier] || DEFAULT_SUPPORTER_TIER_CATALOG[0];
	}

	function GetSupporterTierBadgeLetter(tierData) {
		if (!tierData || ToNumber(tierData.tier, 0) <= 0) {
			return "";
		}

		var tierName = (tierData.name || "").toString();
		if (tierName.length > 0) {
			return tierName.charAt(0).toUpperCase();
		}

		return ["", "D", "G", "E", "S", "E"][Clamp(ToNumber(tierData.tier, 0), 0, 5)] || "";
	}

	function GetSupporterTierCatalog() {
		var catalog = DEFAULT_SUPPORTER_TIER_CATALOG.slice(0);
		var tiers = CustomNetTables.GetTableValue("supporter_pass_meta", "tiers");

		if (!tiers) {
			return catalog;
		}

		for (var key in tiers) {
			if (!tiers.hasOwnProperty(key)) {
				continue;
			}

			var tier = tiers[key];
			if (!tier) {
				continue;
			}

			var tierID = Clamp(ToNumber(tier.id || key, 0), 0, 5);
			var fallback = catalog[tierID] || DEFAULT_SUPPORTER_TIER_CATALOG[0];

			catalog[tierID] = {
				id: tierID,
				name: tier.name || fallback.name,
				color: tier.color || fallback.color,
				fragments: ToNumber(tier.fragments || tier.monthly_fragments, fallback.fragments),
				xpBoost: ToNumber(tier.xp_boost || tier.xpBoost, fallback.xpBoost),
				votePower: ToNumber(tier.vote_power || tier.votePower, fallback.votePower),
			};
		}

		return catalog;
	}

	function GetSupporterTierData(playerID) {
		var data = CustomNetTables.GetTableValue("supporter_pass_player", playerID.toString()) || {};
		var tier = NormalizeSupporterTierID(data.tier_id || data.supporter_tier || data.donator_level || 0, data);
		var tierInfo = GetSupporterTierInfo(tier);

		return {
			tier: tier,
			name: data.tier_name || data.supporter_tier_name || tierInfo.name,
			color: IsEarthwardenSupporterData(data) ? DEFAULT_SUPPORTER_TIER_CATALOG[5].color : (data.tier_color || tierInfo.color),
			fragmentsPerMonth: ToNumber(data.tier_fragments || tierInfo.fragments, tierInfo.fragments),
			xpBoost: ToNumber(data.tier_xp_boost || data.xp_boost || tierInfo.xpBoost, tierInfo.xpBoost),
			votePower: Math.max(1, ToNumber(data.vote_power, tierInfo.votePower)),
		};
	}

	function GetSupporterPlayerData(playerID, entIndex) {
		var data = CustomNetTables.GetTableValue("supporter_pass_player", playerID.toString()) || {};
		var tierData = GetSupporterTierData(playerID);
		var playerInfo = SafeValue(function () {
			return Game.GetPlayerInfo(playerID);
		}, {});
		var heroName = NormalizeTextValue(SafeValue(function () {
			return Entities.GetUnitName(entIndex);
		}, SafeValue(function () {
			return Players.GetPlayerSelectedHero(playerID);
		}, "")));
		var localHeroName = LocalizeUnitName(heroName);
		var playerName = NormalizeTextValue(SafeValue(function () {
			return Players.GetPlayerName(playerID);
		}, ""));

		if (!playerName) {
			playerName = NormalizeTextValue(playerInfo.player_name);
		}

		if (!playerName) {
			playerName = localHeroName || FormatUnitNameFallback(heroName) || ("Player " + (playerID + 1));
		}

		return {
			playerName: playerName,
			heroName: heroName,
			localHeroName: localHeroName,
			heroDisplayName: localHeroName || FormatUnitNameFallback(heroName),
			tier: tierData.tier,
			tierName: tierData.name,
			tierColor: tierData.color,
			fragments: ToNumber(data.fragments || data.fragment_balance, 0),
			weeklyFragments: ToNumber(data.daily_fragments || data.daily_earned || data.weekly_fragments || data.weekly_earned, 0),
			weeklyCap: Math.max(ToNumber(data.daily_cap || data.weekly_cap, DAILY_FRAGMENT_CAP), 1),
			seasonLevel: Math.max(1, ToNumber(data.season_level || data.Lvl, 1)),
			seasonXP: ToNumber(data.season_xp || data.XP, 0),
			seasonXPMax: Math.max(ToNumber(data.season_xp_max || data.MaxXP, 1000), 1),
			accountLevel: ToNumber(data.xhs_account_level || data.account_level || data.legacy_level, 0),
			accountXPCurrent: ToNumber(data.xhs_xp_current || 0, 0),
			accountXPMax: ToNumber(data.xhs_xp_max || 0, 0),
			accountXPTotal: ToNumber(data.xhs_xp || data.xhs_xp_total || 0, 0),
			winrate: data.winrate,
			fragmentsPerMonth: tierData.fragmentsPerMonth,
			xpBoost: tierData.xpBoost,
			votePower: tierData.votePower,
			heroLevel: SafeValue(function () { return Entities.GetLevel(entIndex); }, 0),
			ankhCharges: GetAnkhCharges(entIndex),
			reincarnationState: GetReincarnationState(entIndex),
			disconnected: IsPlayerDisconnected(playerInfo),
		};
	}

	function ShowAllyHover(card, playerID) {
		if (!card) {
			return;
		}

		var hover = Panel("XHSSupporterHoverCard_" + playerID);
		if (typeof XHSSupporterHover !== "undefined" && XHSSupporterHover.Show) {
			XHSSupporterHover.Show(card, hover);
		}
		UpdateAllyHover(card, playerID);
	}

	function HideAllyHover(card) {
		if (card) {
			var hover = Panel("XHSSupporterHoverCard_" + card.GetAttributeInt("player_id", -1));
			if (typeof XHSSupporterHover !== "undefined" && XHSSupporterHover.Hide) {
				XHSSupporterHover.Hide(card, hover);
			}
		}
	}

	function UpdateAllyHover(card, playerID) {
		if (!card) {
			return;
		}

		var entIndex = card.GetAttributeInt("ent_index", -1);
		if (!IsValidEntityIndex(entIndex)) {
			return;
		}

		var hover = Panel("XHSSupporterHoverCard_" + playerID);
		if (!hover) {
			return;
		}

		var data = GetSupporterPlayerData(playerID, entIndex);
		if (typeof XHSSupporterHover !== "undefined" && XHSSupporterHover.Update) {
			XHSSupporterHover.Update(hover, playerID, data);
			XHSSupporterHover.PositionNearAnchor(card, hover, Panel("XHSTopHudRoot"), {
				side: card.GetAttributeInt("roster_side", 0) === 1 ? "left" : "right",
			});
		}
	}

	function UpdateAllySupporterTier(card, playerID) {
		var supporterMark = card.FindChildTraverse("XHSSupporterMark_" + playerID);
		var supporterCrestLabel = card.FindChildTraverse("XHSSupporterCrestLabel_" + playerID);
		var tierData = GetSupporterTierData(playerID);
		var tier = Clamp(ToNumber(tierData.tier, 0), 0, 5);

		ClearSupporterTierClasses(card);
		ClearSupporterTierClasses(supporterMark);
		card.SetHasClass("XHSAllySupporter", tier > 0);

		if (tier > 0) {
			card.AddClass("XHSSupporterTier" + tier);
		}

		if (supporterMark) {
			supporterMark.SetHasClass("XHSAllySupporter", tier > 0);
			if (tier > 0) {
				supporterMark.AddClass("XHSSupporterTier" + tier);
			}
		}

		if (supporterCrestLabel) {
			supporterCrestLabel.text = tier > 0 ? GetSupporterTierBadgeLetter(tierData) : "";
		}
	}

	function UpdateAllyIdentity(card, playerID, entIndex, playerInfo) {
		if (!card) {
			return;
		}

		var playerName = SafeValue(function () {
			return Players.GetPlayerName(playerID);
		}, "Player " + (playerID + 1));

		var heroName = SafeValue(function () {
			return Entities.GetUnitName(entIndex);
		}, Players.GetPlayerSelectedHero(playerID));

		var playerColor = GetPlayerColorString(playerID);

		card.SetAttributeInt("ent_index", entIndex);

		var colorStrip = card.FindChildTraverse("XHSAllyColorStrip_" + playerID);
		if (colorStrip) {
			colorStrip.style.backgroundColor = playerColor;
		}

		var name = card.FindChildTraverse("XHSAllyName_" + playerID);
		if (name) {
			name.text = ResolvePlayerIdentity(playerID, entIndex, {
				playerName: playerName,
				heroName: heroName,
				localHeroName: LocalizeUnitName(heroName),
			});
			name.style.color = playerColor;
		}

		var image = card.FindChildTraverse("XHSAllyHeroImage_" + playerID);
		if (image && heroName) {
			image.heroname = heroName;
		}

		var isDisconnected = IsPlayerDisconnected(playerInfo);
		card.SetHasClass("IsDisconnected", isDisconnected);

		var imageWrap = card.FindChildTraverse("XHSAllyImageWrap_" + playerID);
		if (imageWrap) {
			imageWrap.SetHasClass("IsDisconnected", isDisconnected);
		}

		UpdateAllySupporterTier(card, playerID);
	}

	function GetAnkhCharges(entIndex) {
		var data = CustomNetTables.GetTableValue("player_table", entIndex.toString() + "_respawns");
		if (!data || data["1"] === undefined || data["1"] === null) {
			return 0;
		}

		var value = parseInt(data["1"], 10);
		return isNaN(value) ? 0 : Math.max(value, 0);
	}

	function GetCurrentGameTime() {
		return SafeValue(function () {
			if (typeof Game.GetGameTime === "function") {
				return Game.GetGameTime();
			}

			return Game.GetDOTATime(false, false);
		}, 0);
	}

	function GetReincarnationState(entIndex) {
		var data = CustomNetTables.GetTableValue("player_table", entIndex.toString() + "_reincarnation") || {};
		var active = ToNumber(data.active, 0) > 0;
		var endTime = ToNumber(data.end_time, 0);
		var duration = ToNumber(data.duration, 0);
		var remaining = active ? Math.max(0, endTime - GetCurrentGameTime()) : 0;

		return {
			active: active,
			duration: duration,
			endTime: endTime,
			remaining: remaining,
		};
	}

	function GetTombstoneReviveState(entIndex) {
		var data = CustomNetTables.GetTableValue("player_table", entIndex.toString() + "_revive_channel") || {};
		var active = ToNumber(data.active, 0) > 0;
		var endTime = ToNumber(data.end_time, 0);
		var duration = ToNumber(data.duration, 0);
		var remaining = active ? Math.max(0, endTime - GetCurrentGameTime()) : 0;

		return {
			active: active && remaining > 0,
			duration: duration,
			endTime: endTime,
			remaining: remaining,
			channels: Math.max(0, ToNumber(data.channels, 0)),
			tombstoneEntIndex: Math.floor(ToNumber(data.tombstone_entindex, -1)),
		};
	}

	function GetPlayerRespawnSeconds(playerID) {
		return SafeValue(function () {
			if (typeof Players.GetRespawnSeconds === "function") {
				return Players.GetRespawnSeconds(playerID);
			}
			return -1;
		}, -1);
	}

	function UpdateAllyDeathStatus(card, playerID, entIndex, isDead) {
		var reincarnationState = GetReincarnationState(entIndex);
		var reviveState = GetTombstoneReviveState(entIndex);
		var isReviving = isDead && reviveState.active;
		var isReincarnating = isDead && !isReviving && reincarnationState.active;
		var label = card.FindChildTraverse("XHSAllyRespawnLabel_" + playerID);

		card.SetHasClass("XHSAllyReviving", isReviving);
		card.SetHasClass("XHSAllyReincarnating", isReincarnating);

		if (!label) {
			return;
		}

		if (isReviving) {
			label.text = Math.ceil(reviveState.remaining).toString() + "s";
		} else if (isReincarnating) {
			label.text = Math.ceil(reincarnationState.remaining).toString();
		} else if (isDead) {
			var respawnSeconds = GetPlayerRespawnSeconds(playerID);
			label.text = respawnSeconds > 0 ? Math.ceil(respawnSeconds).toString() : "∞";
		} else {
			label.text = "";
		}
	}

	function FormatReincarnationStatus(state) {
		var seconds = Math.ceil(Math.max(0, state.remaining || 0)).toString();
		var localized = $.Localize("#DOTA_XHS_Overhead_Reincarnation_In");
		if (!localized || localized === "#DOTA_XHS_Overhead_Reincarnation_In") {
			localized = "REINCARNATION IN {seconds}s";
		}
		return localized.replace("{seconds}", seconds);
	}

	function UpdateAllyVitals(card, playerID, entIndex) {
		var health = SafeValue(function () {
			return Entities.GetHealth(entIndex);
		}, 0);

		var maxHealth = SafeValue(function () {
			return Entities.GetMaxHealth(entIndex);
		}, 1);

		var healthPercent = SafeValue(function () {
			return Entities.GetHealthPercent(entIndex);
		}, 0);

		var maxMana = SafeValue(function () {
			return Entities.GetMaxMana(entIndex);
		}, 0);
		var hasMana = maxMana > 0;

		var manaPercent = SafeValue(function () {
			if (!hasMana) {
				return 0;
			}
			return 100.0 * (Entities.GetMana(entIndex) / maxMana);
		}, 0);

		var healthBar = card.FindChildTraverse("XHSAllyHealthBar_" + playerID);
		var manaBar = card.FindChildTraverse("XHSAllyManaBar_" + playerID);
		var healthFill = card.FindChildTraverse("XHSAllyHealthBar_" + playerID + "_Fill");
		var manaFill = card.FindChildTraverse("XHSAllyManaBar_" + playerID + "_Fill");
		var clampedHealth = Clamp(ToNumber(healthPercent, 0), 0, 100);
		var clampedMana = Clamp(ToNumber(manaPercent, 0), 0, 100);
		var isDead = SafeValue(function () {
			return !Entities.IsAlive(entIndex);
		}, clampedHealth <= 0);

		if (healthBar) {
			healthBar.SetAttributeInt("value", Math.floor(clampedHealth));
		}

		if (manaBar) {
			manaBar.SetAttributeInt("value", Math.floor(clampedMana));
		}

		if (healthFill) {
			healthFill.style.width = clampedHealth + "%";
		}

		if (manaFill) {
			manaFill.style.width = clampedMana + "%";
		}

		card.SetHasClass("IsDead", isDead);
		card.SetHasClass("XHSNoMana", !hasMana);
		UpdateAllyDeathStatus(card, playerID, entIndex, isDead);
		UpdateOverheadLabelVitals(playerID, entIndex, clampedHealth, clampedMana, health, maxHealth, hasMana);

		if (card.BHasClass("XHSHoverVisible") || PanelHasHover(card)) {
			UpdateAllyHover(card, playerID);
		}
	}

	function UpdateAllyAnkh(card, playerID, entIndex) {
		var charges = GetAnkhCharges(entIndex);
		var label = card.FindChildTraverse("XHSAnkhCount_" + playerID);

		if (label) {
			label.text = "x" + charges;
		}

		card.SetHasClass("NoAnkh", charges <= 0);
		UpdateOverheadLabelData(playerID, entIndex);

		if (card.BHasClass("XHSHoverVisible") || PanelHasHover(card)) {
			UpdateAllyHover(card, playerID);
		}
	}

	function RefreshAllyRoster() {
		EnsureAllyRosterSlots();

		var playerIDs = GetRosterPlayerIDs();
		var activePlayerIDs = {};

		for (var i = 0; i < playerIDs.length; i++) {
			var playerID = playerIDs[i];
			var playerInfo = Game.GetPlayerInfo(playerID);
			// The top bar is a compact roster of actual Radiant heroes, not a
			// mirror of global PlayerIDs. Spectators can own player 0 and receive
			// a short-lived Wisp placeholder, so pack valid Radiant players from
			// the first slot instead of preserving that empty global slot.
			var slotIndex = i;
			if (slotIndex < 0) {
				continue;
			}

			activePlayerIDs[playerID] = true;

			var entIndex = Players.GetPlayerHeroEntityIndex(playerID);

			if (!IsValidEntityIndex(entIndex)) {
				if (allyCards[playerID]) {
					DeleteAllyCard(playerID);
				}
				ClearOverheadLabel(playerID);
				continue;
			}

			var expectedSide = slotIndex >= 4 ? 1 : 0;
			if (allyCards[playerID] && (
				allyCards[playerID].GetAttributeInt("roster_side", -1) !== expectedSide ||
				allyCards[playerID].GetAttributeInt("roster_index", -1) !== slotIndex
			)) {
				DeleteAllyCard(playerID);
			}

			if (!allyCards[playerID]) {
				allyCards[playerID] = CreateAllyCard(playerID, slotIndex);
			}

			if (allyCards[playerID]) {
				UpdateAllyIdentity(allyCards[playerID], playerID, entIndex, playerInfo);
				UpdateAllyAnkh(allyCards[playerID], playerID, entIndex);
			}

			UpdateOverheadLabelData(playerID, entIndex);
		}

		for (var cardPlayerID in allyCards) {
			if (!allyCards.hasOwnProperty(cardPlayerID)) {
				continue;
			}

			if (!activePlayerIDs[parseInt(cardPlayerID, 10)]) {
				DeleteAllyCard(cardPlayerID);
				ClearOverheadLabel(cardPlayerID);
			}
		}
	}

	function RefreshAllyVitals() {
		for (var playerID in allyCards) {
			if (!allyCards.hasOwnProperty(playerID)) {
				continue;
			}

			var card = allyCards[playerID];
			var entIndex = card.GetAttributeInt("ent_index", -1);
			if (IsValidEntityIndex(entIndex)) {
				var numericPlayerID = parseInt(playerID, 10);
				UpdateAllyVitals(card, numericPlayerID, entIndex);
			}
		}
	}

	function ClearVipCards(activeKeys) {
		for (var key in vipCards) {
			if (!vipCards.hasOwnProperty(key)) {
				continue;
			}

			if (!activeKeys[key]) {
				vipCards[key].DeleteAsync(0);
				delete vipCards[key];
			}
		}
	}

	function CreateVipCard(key, entIndex) {
		var roster = Panel("XHSVipRoster");
		if (!roster) {
			return null;
		}

		var card = $.CreatePanel("Panel", roster, "XHSVipCard_" + key);
		card.AddClass("XHSVipCard");
		card.SetAttributeInt("ent_index", entIndex);
		card.hittest = true;

		var imageWrap = $.CreatePanel("Panel", card, "XHSVipImageWrap_" + key);
		imageWrap.AddClass("XHSVipImageWrap");

		var image = $.CreatePanel("Image", imageWrap, "XHSVipImage_" + key);
		image.AddClass("XHSVipImage");

		var name = $.CreatePanel("Label", card, "XHSVipName_" + key);
		name.AddClass("XHSVipName");

		card.SetPanelEvent("onactivate", function () {
			SelectUnitOrCast(card.GetAttributeInt("ent_index", -1));
		});

		card.SetPanelEvent("ondblclick", function () {
			MoveCameraToUnit(card.GetAttributeInt("ent_index", -1));
		});

		return card;
	}

	function RefreshVipRoster() {
		var data = CustomNetTables.GetTableValue("vips", "0");
		var activeKeys = {};

		if (data) {
			for (var i = 1; i <= 8; i++) {
				var entIndex = data[i] || data[i.toString()];
				if (!IsValidEntityIndex(entIndex)) {
					continue;
				}

				var key = i.toString();
				activeKeys[key] = true;

				if (!vipCards[key]) {
					vipCards[key] = CreateVipCard(key, entIndex);
				}

				var card = vipCards[key];
				if (!card) {
					continue;
				}

				var unitName = SafeValue(function () {
					return Entities.GetUnitName(entIndex);
				}, "");

				card.SetAttributeInt("ent_index", entIndex);

				var image = card.FindChildTraverse("XHSVipImage_" + key);
				if (image && unitName) {
					image.SetImage("file://{images}/interface/" + unitName + ".png");
				}

				var name = card.FindChildTraverse("XHSVipName_" + key);
				if (name && unitName) {
					name.text = $.Localize("#" + unitName);
				}
			}
		}

		ClearVipCards(activeKeys);
	}

	function SetOptionalPanelVisible(panelID, isVisible) {
		var panel = Panel(panelID);
		if (panel) {
			panel.SetHasClass("XHSOptionalTimer", !isVisible);
		}

		UpdateFocusTimersVisibility();
	}

	function UpdateFocusTimersVisibility() {
		var focusTimers = Panel("XHSFocusTimers");
		if (!focusTimers) {
			return;
		}

		var arenaTimer = Panel("XHSArenaTimer");
		var personalTimer = Panel("XHSPersonalEventTimer");
		var hasVisibleTimer =
			!!(arenaTimer && !arenaTimer.BHasClass("XHSOptionalTimer")) ||
			!!(personalTimer && !personalTimer.BHasClass("XHSOptionalTimer"));

		focusTimers.SetHasClass("XHSHasVisibleFocusTimer", hasVisibleTimer);

		var hud = GetHudAncestor($.GetContextPanel());
		var bossBars = hud && hud.FindChildTraverse ? hud.FindChildTraverse("DiretidePanel") : null;
		if (bossBars) {
			bossBars.SetHasClass("XHSFocusTimerActive", hasVisibleTimer);
		}
	}

	function ShowCurrentEventTimer(timerName, title, isVisible, duration) {
		if (isVisible) {
			SetMuradinFrenzyActive(false);
			if (activeCurrentEventTimerName !== timerName) {
				ResetCurrentEventProgress(timerName);
			}

			activeCurrentEventTimerName = timerName;
			if (duration !== undefined && duration !== null && ToNumber(duration, 0) > 0) {
				currentEventTimerMaxRemaining[timerName] = ToNumber(duration, 0);
				currentEventTimerProgressRunning[timerName] = true;
			}
			SetText("XHSCurrentEventTimerTitle", title || currentEventTimerTitles[timerName] || "EVENT");
			SetOptionalPanelVisible("XHSArenaTimer", true);

			return;
		}

		if (activeCurrentEventTimerName === timerName) {
			SetMuradinFrenzyActive(false);
			ResetCurrentEventProgress(timerName);
			activeCurrentEventTimerName = null;
			SetOptionalPanelVisible("XHSArenaTimer", false);
		}
	}

	function ShowArenaTimer(isVisible) {
		ShowCurrentEventTimer("special_arena", currentEventTimerTitles.special_arena, isVisible);
	}

	function ShowPersonalTimer(timerName, isVisible) {
		if (isVisible) {
			if (activePersonalTimerName !== timerName) {
				ResetPersonalEventProgress(timerName);
			}

			activePersonalTimerName = timerName;
			SetText("XHSPersonalEventTimerTitle", personalTimerTitles[timerName] || "EVENT");
			SetOptionalPanelVisible("XHSPersonalEventTimer", true);
			return;
		}

		if (activePersonalTimerName === timerName) {
			ResetPersonalEventProgress(timerName);
			activePersonalTimerName = null;
			SetOptionalPanelVisible("XHSPersonalEventTimer", false);
		}
	}

	function CountdownTimer(data) {
		if (!data || !data.timer_name) {
			return;
		}

		var text = FormatTimer(data);
		if (data.timer_name === "game_time") {
			SetText("XHSClockValue", text);
			return;
		}

		if (data.timer_name === "creep_level") {
			return;
		}

		if (data.timer_name === activeCurrentEventTimerName) {
			SetMuradinFrenzyActive(ToNumber(data.muradin_frenzy, 0) > 0);
			SetText("XHSArenaTimerValue", text);
			UpdateCurrentEventProgress(data.timer_name, GetTimerSeconds(data));
			return;
		}

		if (data.timer_name === activePersonalTimerName) {
			SetText("XHSPersonalEventTimerValue", text);
			UpdatePersonalEventProgress(data.timer_name, GetTimerSeconds(data));
			return;
		}

	}

	function SetDifficulty(data) {
		var difficulty = data && data.difficulty ? data.difficulty : "-----";
		SetText("XHSDifficultyAltValue", "DIFFICULTY: " + difficulty);
	}

	function RefreshAltState() {
		var isAltDown = SafeValue(function () {
			return GameUI.IsAltDown();
		}, false);

		$.GetContextPanel().SetHasClass("XHSAltDown", !!isAltDown);
		$.Schedule(0.03, RefreshAltState);
	}

	function ShowNightfallVignette(data) {
		var panel = $("#XHSNightfallVignette");
		if (!panel) {
			return;
		}

		var duration = Math.max(0.1, Number(data && data.duration) || 1.0);
		nightfallVignetteToken++;
		var token = nightfallVignetteToken;
		panel.SetHasClass("XHSNightfallActive", true);
		$.Schedule(duration, function () {
			if (token !== nightfallVignetteToken) {
				return;
			}
			var currentPanel = $("#XHSNightfallVignette");
			if (currentPanel) {
				currentPanel.SetHasClass("XHSNightfallActive", false);
			}
		});
	}

	function SubscribeTimerEvents() {
		GameEvents.Subscribe("countdown_timer", CountdownTimer);
		GameEvents.Subscribe("show_timer_bar", function () {});
		GameEvents.Subscribe("game_difficulty", SetDifficulty);
		GameEvents.Subscribe("xhs_nightfall_vignette", ShowNightfallVignette);
		GameEvents.Subscribe("xhs_game_pause_state", function (data) {
			SetOverheadPauseOcclusion(!!(data && Number(data.paused) === 1));
		});
		GameEvents.Subscribe("xhs_hero_selection_transition", function (data) {
			isHeroSelectionTransitionActive = !!(data && Number(data.active) === 1);
		});
		GameEvents.Subscribe("update_special_event_label_farm", function () {});
		GameEvents.Subscribe("update_special_event_label_final", function () {});
		GameEvents.Subscribe("show_current_event_timer", function (data) {
			ShowCurrentEventTimer(data && data.timer_name ? data.timer_name : "special_event", data && data.title ? data.title : "EVENT", true, data && data.duration);
		});
		GameEvents.Subscribe("hide_current_event_timer", function (data) {
			ShowCurrentEventTimer(data && data.timer_name ? data.timer_name : activeCurrentEventTimerName, "", false);
		});

		GameEvents.Subscribe("show_timer_special_arena", function () { ShowArenaTimer(true); });
		GameEvents.Subscribe("show_timer_hero_image", function () { ShowPersonalTimer("hero_image", true); });
		GameEvents.Subscribe("show_timer_spirit_beast", function () { ShowPersonalTimer("spirit_beast", true); });
		GameEvents.Subscribe("show_timer_frost_infernal", function () { ShowPersonalTimer("frost_infernal", true); });
		GameEvents.Subscribe("show_timer_all_hero_image", function () { ShowPersonalTimer("all_hero_images", true); });

		GameEvents.Subscribe("hide_timer_special_arena", function () { ShowArenaTimer(false); });
		GameEvents.Subscribe("hide_timer_hero_image", function () { ShowPersonalTimer("hero_image", false); });
		GameEvents.Subscribe("hide_timer_spirit_beast", function () { ShowPersonalTimer("spirit_beast", false); });
		GameEvents.Subscribe("hide_timer_frost_infernal", function () { ShowPersonalTimer("frost_infernal", false); });
		GameEvents.Subscribe("hide_timer_all_hero_image", function () { ShowPersonalTimer("all_hero_images", false); });

		GameEvents.Subscribe("show_events", function () {
			isSpecialEventPanelVisible = true;
			SetSharedSpecialEventVisible(true);
			InvalidateOverheadBlockers();
		});
		GameEvents.Subscribe("quit_events", function () {
			isSpecialEventPanelVisible = false;
			SetSharedSpecialEventVisible(false);
			InvalidateOverheadBlockers();
		});
	}

	function StartHeroRefreshLoop() {
		RefreshAllyRoster();
		$.Schedule(HERO_REFRESH_SECONDS, StartHeroRefreshLoop);
	}

	function RefreshCloneOverheads() {
		var state = CustomNetTables.GetTableValue("xhs_clone_units", "state") || {};
		var clones = state.clones || {};
		var activeKeys = {};

		for (var cloneID in clones) {
			if (!clones.hasOwnProperty(cloneID)) {
				continue;
			}

			var record = clones[cloneID] || {};
			var entIndex = parseInt(record.entindex !== undefined ? record.entindex : cloneID, 10);
			var ownerPlayerID = parseInt(record.owner_player_id, 10);
			if (!IsValidEntityIndex(entIndex) || isNaN(ownerPlayerID) || ownerPlayerID < 0) {
				continue;
			}

			var isAlive = SafeValue(function () {
				return Entities.IsAlive(entIndex);
			}, false);
			if (!isAlive) {
				continue;
			}

			// Player IDs are non-negative, so a negative entity-derived key gives
			// each clone a collision-free copy of the normal XHS overhead frame.
			var overheadKey = -(entIndex + 1);
			activeKeys[overheadKey] = true;
			cloneOverheadKeys[overheadKey] = true;

			UpdateOverheadLabelData(ownerPlayerID, entIndex, overheadKey);
			var label = overheadLabels[overheadKey];
			if (!label) {
				continue;
			}

			label.AddClass("XHSOverheadClone");
			var cloneName = LocalizeUnitName(SafeValue(function () {
				return Entities.GetUnitName(entIndex);
			}, ""));
			if (!cloneName) {
				cloneName = "CLONE";
			} else {
				cloneName += " CLONE";
			}
			label.SetAttributeString("xhs_overhead_hero_label", cloneName);
			SetChildText(label, "XHSOverheadName_" + overheadKey, cloneName);
			SetChildText(label, "XHSOverheadGameplayStatus_" + overheadKey, "CLONE");
			SetChildText(label, "XHSOverheadAltStatus_" + overheadKey, "CLONE");

			var health = SafeValue(function () { return Entities.GetHealth(entIndex); }, 0);
			var maxHealth = SafeValue(function () { return Entities.GetMaxHealth(entIndex); }, 1);
			var healthPercent = SafeValue(function () { return Entities.GetHealthPercent(entIndex); }, 0);
			var maxMana = SafeValue(function () { return Entities.GetMaxMana(entIndex); }, 0);
			var hasMana = maxMana > 0;
			var manaPercent = SafeValue(function () {
				return hasMana ? 100.0 * Entities.GetMana(entIndex) / maxMana : 0;
			}, 0);

			UpdateOverheadLabelVitals(
				ownerPlayerID,
				entIndex,
				healthPercent,
				manaPercent,
				health,
				maxHealth,
				hasMana,
				overheadKey
			);
		}

		for (var staleKey in cloneOverheadKeys) {
			if (!cloneOverheadKeys.hasOwnProperty(staleKey) || activeKeys[staleKey]) {
				continue;
			}
			ClearOverheadLabel(staleKey);
			delete cloneOverheadKeys[staleKey];
		}
	}

	function StartVitalsRefreshLoop() {
		RefreshAllyVitals();
		RefreshCloneOverheads();
		$.Schedule(VITALS_REFRESH_SECONDS, StartVitalsRefreshLoop);
	}

	function StartOverheadTrackingLoop() {
		// Poll as well as listening to the server event so a Panorama hot reload
		// during an existing pause cannot leave the custom world-space bars above
		// the pause briefing.
		SyncOverheadPauseOcclusion();
		RefreshOverheadPositions();
		$.Schedule(OVERHEAD_REFRESH_SECONDS, StartOverheadTrackingLoop);
	}

	function StartSlowRefreshLoop() {
		for (var playerID in allyCards) {
			if (!allyCards.hasOwnProperty(playerID)) {
				continue;
			}

			var card = allyCards[playerID];
			var entIndex = card.GetAttributeInt("ent_index", -1);
			if (IsValidEntityIndex(entIndex)) {
				var numericPlayerID = parseInt(playerID, 10);
				UpdateAllyAnkh(card, numericPlayerID, entIndex);
				UpdateOverheadLabelData(numericPlayerID, entIndex);
			}
		}

		RefreshVipRoster();
		$.Schedule(SLOW_REFRESH_SECONDS, StartSlowRefreshLoop);
	}

	function LocalizeWavePressure(token, replacements) {
		var localized = $.Localize(token);
		if (!localized || localized === token) {
			localized = token;
		}
		for (var key in replacements) {
			if (replacements.hasOwnProperty(key)) {
				localized = localized.replace("{" + key + "}", String(replacements[key]));
			}
		}
		return localized;
	}

	function UpdateWavePressurePanel() {
		var panel = Panel("XHSWavePressurePanel");
		if (!panel) {
			return;
		}

		var data = CustomNetTables.GetTableValue("xhs_phase_one_spawn_budget", "state") || {};
		var phaseActive = Number(data.phase_active) > 0;
		var pressureActive = phaseActive && Number(data.pressure_active) > 0;
		var activeUnits = Math.max(0, Math.floor(Number(data.active_units) || 0));
		var softCap = Math.max(1, Math.floor(Number(data.soft_cap) || 100));
		var hardCap = Math.max(softCap, Math.floor(Number(data.hard_cap) || 125));
		var spawned = Math.max(0, Math.floor(Number(data.spawned) || 0));
		var skipped = Math.max(0, Math.floor(Number(data.skipped) || 0));
		var limited = skipped > 0 || Number(data.limited) > 0;
		var blocked = limited && spawned <= 0;

		panel.SetHasClass("Active", pressureActive);
		panel.SetHasClass("Limited", limited);
		panel.SetHasClass("Critical", activeUnits >= hardCap || blocked);

		var count = Panel("XHSWavePressureCount");
		var title = Panel("XHSWavePressureTitle");
		var detail = Panel("XHSWavePressureDetail");
		var fill = Panel("XHSWavePressureFill");
		if (count) {
			count.text = activeUnits + " / " + hardCap;
		}
		if (title) {
			title.text = LocalizeWavePressure(
				blocked
					? "#xhs_phase_one_spawn_budget_blocked"
					: limited
						? "#xhs_phase_one_spawn_budget_reduced"
						: "#xhs_phase_one_spawn_budget_rising",
				{}
			);
		}
		if (detail) {
			detail.text = LocalizeWavePressure(
				limited
					? "#xhs_phase_one_spawn_budget_detail_limited"
					: "#xhs_phase_one_spawn_budget_detail_normal",
				{ count: skipped, soft: softCap }
			);
		}
		if (fill) {
			fill.style.width = Math.min(100, activeUnits / hardCap * 100) + "%";
		}
		InvalidateOverheadBlockers();
	}

	function Initialize() {
		SubscribeTimerEvents();
		EnsureTopHudBelowShop();
		CustomNetTables.SubscribeNetTableListener("vips", RefreshVipRoster);
		CustomNetTables.SubscribeNetTableListener("supporter_pass_meta", function () {
			RefreshAllyRoster();
		});
		CustomNetTables.SubscribeNetTableListener("supporter_pass_player", function () {
			RefreshAllyRoster();
		});
		CustomNetTables.SubscribeNetTableListener("xhs_bots", OnXHSBotsNetTableChanged);
		CustomNetTables.SubscribeNetTableListener("xhs_phase_one_spawn_budget", UpdateWavePressurePanel);
		CustomNetTables.SubscribeNetTableListener("xhs_clone_units", RefreshCloneOverheads);

		UpdateFocusTimersVisibility();
		UpdateWavePressurePanel();
		RefreshCloneOverheads();
		RefreshBotActivityStates();
		EnsureAllyRosterSlots();
		BuildOverheadMockups();
		StartHeroRefreshLoop();
		StartVitalsRefreshLoop();
		StartOverheadTrackingLoop();
		StartSlowRefreshLoop();
		RefreshAltState();
		if (typeof XHSNameDisplay !== "undefined" && XHSNameDisplay.Subscribe) {
			XHSNameDisplay.Subscribe(RefreshAllyRoster);
		}
	}

	return {
		Initialize: Initialize,
	};
})();

XHSTopHud.Initialize();

(function () {
	var frames = {};
	var vanillaChannelHidden = false;

	function LocalizeHeroName(heroName) {
		var localized = $.Localize("#" + String(heroName || ""));
		if (localized && localized !== ("#" + heroName)) {
			return localized.toUpperCase();
		}
		return String(heroName || "FALLEN HERO").replace(/^npc_dota_hero_/, "").replace(/_/g, " ").toUpperCase();
	}

	function UpdateReviveStackVisibility() {
		var root = $("#XHSReviveFrameStack");
		if (root) {
			var childCount = root.GetChildCount();
			root.SetHasClass("XHSHasReviveFrames", childCount > 0);
		}
	}

	function CreateFrame(key, data) {
		var root = $("#XHSReviveFrameStack");
		if (!root) {
			return null;
		}

		var frame = $.CreatePanel("Panel", root, "XHSReviveFrame_" + key);
		frame.AddClass("XHSReviveFrame");
		UpdateReviveStackVisibility();
		var accent = $.CreatePanel("Panel", frame, "");
		accent.AddClass("XHSReviveFrameAccent");

		var portraitWrap = $.CreatePanel("Panel", frame, "");
		portraitWrap.AddClass("XHSRevivePortraitWrap");
		var portrait = $.CreatePanel("DOTAHeroImage", portraitWrap, "");
		portrait.AddClass("XHSRevivePortrait");
		portrait.heroname = String(data.hero_name || "");
		var rune = $.CreatePanel("Label", portraitWrap, "");
		rune.AddClass("XHSReviveRune");
		rune.text = "✦";

		var copy = $.CreatePanel("Panel", frame, "");
		copy.AddClass("XHSReviveCopy");
		var header = $.CreatePanel("Panel", copy, "");
		header.AddClass("XHSReviveHeader");
		var eyebrow = $.CreatePanel("Label", header, "");
		eyebrow.AddClass("XHSReviveEyebrow");
		eyebrow.text = "SOUL RECALL";
		var channelers = $.CreatePanel("Label", header, "");
		channelers.AddClass("XHSReviveChannelers");

		var title = $.CreatePanel("Label", copy, "");
		title.AddClass("XHSReviveTitle");
		title.text = LocalizeHeroName(data.hero_name);

		var progressTrack = $.CreatePanel("Panel", copy, "");
		progressTrack.AddClass("XHSReviveProgressTrack");
		var progress = $.CreatePanel("Panel", progressTrack, "");
		progress.AddClass("XHSReviveProgress");
		var shine = $.CreatePanel("Panel", progressTrack, "");
		shine.AddClass("XHSReviveProgressShine");

		var timer = $.CreatePanel("Label", frame, "");
		timer.AddClass("XHSReviveTimer");

		frame._xhsPortrait = portrait;
		frame._xhsTitle = title;
		frame._xhsChannelers = channelers;
		frame._xhsProgress = progress;
		frame._xhsTimer = timer;
		return frame;
	}

	function UpdateFrame(frame, state) {
		var remaining = Math.max(0, state.endTime - Game.GetGameTime());
		var ratio = state.duration > 0 ? 1 - Math.min(1, remaining / state.duration) : 1;
		frame._xhsProgress.style.width = (ratio * 100).toFixed(2) + "%";
		frame._xhsTimer.text = remaining.toFixed(1) + "s";
		frame._xhsChannelers.text = state.channels + (state.channels === 1 ? " CHANNELER" : " CHANNELERS");
	}

	function RemoveFrame(key, result) {
		var state = frames[key];
		if (!state) {
			return;
		}
		delete frames[key];
		var frame = state.panel;
		frame.SetHasClass("XHSReviveCompleted", result === "completed");
		frame.SetHasClass("XHSReviveCancelled", result !== "completed");
		frame._xhsTimer.text = result === "completed" ? "ALIVE" : "CANCELLED";
		frame._xhsChannelers.text = result === "completed" ? "SOUL RESTORED" : "RITUAL INTERRUPTED";
		frame._xhsProgress.style.width = result === "completed" ? "100%" : "0%";
		$.Schedule(result === "completed" ? 0.9 : 0.55, function () {
			if (frame && frame.IsValid()) {
				frame.DeleteAsync(0);
				$.Schedule(0.03, UpdateReviveStackVisibility);
			}
		});
	}

	function OnReviveUpdate(data) {
		data = data || {};
		var key = String(Number(data.hero_entindex) || -1);
		if (Number(data.active) <= 0) {
			RemoveFrame(key, String(data.result || "cancelled"));
			return;
		}

		var state = frames[key];
		if (!state) {
			var panel = CreateFrame(key, data);
			if (!panel) {
				return;
			}
			state = { panel: panel };
			frames[key] = state;
		}

		state.duration = Math.max(0.1, Number(data.duration) || 0.1);
		state.endTime = Number(data.end_time) || (Game.GetGameTime() + state.duration);
		state.channels = Math.max(1, Number(data.channels) || 1);
		state.panel._xhsPortrait.heroname = String(data.hero_name || "");
		state.panel._xhsTitle.text = LocalizeHeroName(data.hero_name);
		state.panel.RemoveClass("XHSReviveCompleted");
		state.panel.RemoveClass("XHSReviveCancelled");
		UpdateFrame(state.panel, state);
	}

	function TickFrames() {
		for (var key in frames) {
			if (!frames.hasOwnProperty(key)) {
				continue;
			}
			var state = frames[key];
			if (state.panel && state.panel.IsValid()) {
				UpdateFrame(state.panel, state);
			}
		}
		$.Schedule(0.03, TickFrames);
	}

	function SetVanillaChannelHidden(hidden) {
		vanillaChannelHidden = !!hidden;
		var ids = ["ChannelBar", "channel_bar"];
		for (var i = 0; i < ids.length; i++) {
			var panel = typeof FindDotaHudElement === "function" ? FindDotaHudElement(ids[i]) : null;
			if (!panel || !panel.IsValid()) {
				continue;
			}
			if (hidden) {
				if (panel._xhsOriginalOpacity === undefined) {
					panel._xhsOriginalOpacity = panel.style.opacity;
				}
				panel.style.opacity = "0";
			} else {
				panel.style.opacity = panel._xhsOriginalOpacity || "1";
				panel._xhsOriginalOpacity = undefined;
			}
		}
	}

	function MaintainVanillaChannelVisibility() {
		if (vanillaChannelHidden) {
			SetVanillaChannelHidden(true);
		}
		$.Schedule(0.1, MaintainVanillaChannelVisibility);
	}

	function SyncReviveFramesFromNetTables() {
		var playerIds = typeof Game.GetAllPlayerIDs === "function" ? Game.GetAllPlayerIDs() : [];
		var scannedHeroIndexes = {};
		for (var i = 0; i < playerIds.length; i++) {
			var heroEntIndex = Players.GetPlayerHeroEntityIndex(playerIds[i]);
			if (!heroEntIndex || heroEntIndex < 0) {
				continue;
			}
			var key = String(heroEntIndex);
			scannedHeroIndexes[key] = true;
			var data = CustomNetTables.GetTableValue("player_table", key + "_revive_channel") || {};
			if (Number(data.active) > 0 && !frames[key]) {
				OnReviveUpdate({
					hero_entindex: heroEntIndex,
					player_id: playerIds[i],
					hero_name: Entities.GetUnitName(heroEntIndex),
					active: 1,
					duration: data.duration,
					end_time: data.end_time,
					channels: data.channels,
				});
			} else if (Number(data.active) <= 0 && frames[key]) {
				RemoveFrame(key, "cancelled");
			}
		}

		// Enemy/NPC heroes do not appear in Game.GetAllPlayerIDs(). The server
		// publishes their entity indexes explicitly so their revive state can use
		// the same reliable nettable fallback as player-owned heroes.
		var reviveIndex = CustomNetTables.GetTableValue("player_table", "xhs_tombstone_revive_index") || {};
		var indexedHeroes = reviveIndex.heroes || {};
		for (var indexKey in indexedHeroes) {
			if (!indexedHeroes.hasOwnProperty(indexKey)) {
				continue;
			}
			var indexEntry = indexedHeroes[indexKey] || {};
			var indexedEntIndex = Number(indexEntry.hero_entindex) || Number(indexKey) || -1;
			var indexedKey = String(indexedEntIndex);
			if (indexedEntIndex < 0 || scannedHeroIndexes[indexedKey]) {
				continue;
			}
			scannedHeroIndexes[indexedKey] = true;
			var indexedData = CustomNetTables.GetTableValue("player_table", indexedKey + "_revive_channel") || {};
			if (Number(indexedData.active) > 0 && !frames[indexedKey]) {
				OnReviveUpdate({
					hero_entindex: indexedEntIndex,
					player_id: Number(indexEntry.player_id),
					hero_name: String(indexEntry.hero_name || Entities.GetUnitName(indexedEntIndex) || ""),
					active: 1,
					duration: indexedData.duration,
					end_time: indexedData.end_time,
					channels: indexedData.channels,
				});
			} else if (Number(indexedData.active) <= 0 && frames[indexedKey]) {
				RemoveFrame(indexedKey, "cancelled");
			}
		}
		$.Schedule(0.5, SyncReviveFramesFromNetTables);
	}

	GameEvents.Subscribe("xhs_tombstone_revive_update", function (data) {
		OnReviveUpdate(data);
	});
	GameEvents.Subscribe("xhs_tombstone_channel_local", function (data) {
		SetVanillaChannelHidden(Number((data || {}).active) > 0);
	});
	UpdateReviveStackVisibility();
	TickFrames();
	MaintainVanillaChannelVisibility();
	SyncReviveFramesFromNetTables();
})();
