"use strict";

var XHSTopHud = (function () {
	var MAX_PLAYER_DISPLAY_SLOTS = 8;
	var MAX_PLAYER_ID_SCAN = 23;
	var HERO_REFRESH_SECONDS = 0.75;
	var VITALS_REFRESH_SECONDS = 0.12;
	var SLOW_REFRESH_SECONDS = 1.0;
	var OVERHEAD_REFRESH_SECONDS = 0.03;
	var OVERHEAD_WORLD_Z_OFFSET = 238;
	var OVERHEAD_SCREEN_Y_OFFSET = 22;
	var OVERHEAD_PERSPECTIVE_BIAS = 38;
	var OVERHEAD_PLATE_WIDTH = 238;
	var OVERHEAD_PLATE_HEIGHT = 58;
	var OVERHEAD_LABEL_HEIGHT = 92;
	var OVERHEAD_FADE_MARGIN = 96;
	var DAILY_FRAGMENT_CAP = 100;
	var WEEKLY_FRAGMENT_CAP = DAILY_FRAGMENT_CAP;

	var allyCards = {};
	var vipCards = {};
	var overheadLabels = {};
	var activeCurrentEventTimerName = null;
	var activePersonalTimerName = null;
	var currentEventTimerMaxRemaining = {};
	var currentEventTimerProgressRunning = {};
	var personalTimerMaxRemaining = {};
	var personalTimerProgressRunning = {};
	var XHS_PLAYER_COLOR_FALLBACKS = [
		"#c80000ff",
		"#0032c8ff",
		"#00ffffff",
		"#640064ff",
		"#ffff00ff",
		"#ff9600ff",
		"#007d00ff",
		"#ff64ffff",
	];

	var DEFAULT_SUPPORTER_TIER_CATALOG = [
		{ id: 0, name: "Free Player", color: "#7db9d8", fragments: 0, xpBoost: 0, votePower: 1 },
		{ id: 1, name: "Donator", color: "#45C46B", fragments: 150, xpBoost: 10, votePower: 1 },
		{ id: 2, name: "Golden Donator", color: "#F2C94C", fragments: 400, xpBoost: 20, votePower: 2 },
		{ id: 3, name: "Ember Donator", color: "#E4572E", fragments: 900, xpBoost: 30, votePower: 3 },
		{ id: 4, name: "Stoneguard Donator", color: "#5AD0FF", fragments: 1800, xpBoost: 40, votePower: 4 },
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

	function PositionAllyHover(card, hover) {
		var root = Panel("XHSTopHudRoot");
		if (!card || !hover || !root) {
			return;
		}

		var cardPosition = GetPanelWindowPosition(card);
		var rootPosition = GetPanelWindowPosition(root);
		var cardWidth = Number(card.actuallayoutwidth || card.desiredlayoutwidth || 0);
		var cardHeight = Number(card.actuallayoutheight || card.desiredlayoutheight || 0);
		var hoverWidth = Number(hover.actuallayoutwidth || hover.desiredlayoutwidth || 322);
		var rootWidth = Number(root.actuallayoutwidth || root.desiredlayoutwidth || 1920);

		var x = cardPosition.x - rootPosition.x;
		var y = cardPosition.y - rootPosition.y + cardHeight + 8;

		if (x + hoverWidth > rootWidth - 12) {
			x = cardPosition.x - rootPosition.x + cardWidth - hoverWidth;
		}

		x = Math.max(12, Math.floor(x));
		y = Math.max(0, Math.floor(y));
		hover.style.position = x + "px " + y + "px 0px";
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

	function FormatVotePower(value) {
		var votes = Math.max(1, Math.floor(ToNumber(value, 1)));
		return votes + " setup " + (votes > 1 ? "votes" : "vote");
	}

	function FormatWinrate(value) {
		if (value === undefined || value === null || value === "") {
			return "-";
		}

		var numberValue = Number(value);
		if (isNaN(numberValue)) {
			return value.toString();
		}

		if (numberValue > 0 && numberValue <= 1) {
			numberValue = numberValue * 100;
		}

		return Math.round(numberValue) + "%";
	}

	function FormatAccountXPSummary(data) {
		var level = Math.max(0, ToNumber(data.accountLevel, 0));
		var total = Math.max(0, ToNumber(data.accountXPTotal, 0));
		var current = Math.max(0, ToNumber(data.accountXPCurrent, 0));
		var max = Math.max(0, ToNumber(data.accountXPMax, 0));

		if (level <= 0 && total <= 0 && current <= 0 && max <= 0) {
			return "-";
		}

		if (total > 0) {
			return "L" + Math.max(1, level) + " " + FormatNumber(total);
		}

		if (max > 0) {
			return "L" + Math.max(1, level) + " " + FormatNumber(current) + " / " + FormatNumber(max);
		}

		return "L" + Math.max(1, level);
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

	function SetFillPercent(parent, childID, current, max) {
		if (!parent) {
			return;
		}

		var child = parent.FindChildTraverse(childID);
		if (!child) {
			return;
		}

		var percent = Clamp(Math.floor((ToNumber(current, 0) / Math.max(ToNumber(max, 1), 1)) * 100), 0, 100);
		child.style.width = percent + "%";
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

	function SelectUnitOrCast(entIndex) {
		if (!IsValidEntityIndex(entIndex)) {
			return;
		}

		var clickBehavior = GameUI.GetClickBehaviors();
		if (clickBehavior === CLICK_BEHAVIORS.DOTA_CLICK_BEHAVIOR_CAST) {
			var abilityIndex = Abilities.GetLocalPlayerActiveAbility();
			if (!IsValidEntityIndex(abilityIndex)) {
				GameUI.SelectUnit(entIndex, false);
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

		GameUI.SelectUnit(entIndex, false);
	}

	function MoveCameraToUnit(entIndex) {
		if (!IsValidEntityIndex(entIndex)) {
			return;
		}

		var position = SafeValue(function () {
			return Entities.GetAbsOrigin(entIndex);
		}, null);

		if (position) {
			GameUI.SetCameraTargetPosition([position[0], position[1], position[2]], 0.4);
		}
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

	function SetOverheadHeroImage(portrait, heroName) {
		if (!portrait || !heroName) {
			return;
		}

		if (portrait.GetAttributeInt("xhs_hero_image_fallback", 0) > 0) {
			portrait.style.backgroundImage = "url(\"file://{images}/heroes/" + heroName + ".png\")";
			return;
		}

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
				label.SetHasClass("XHSOverheadSelectedCompact", isSelected && !isAltDown && !isReincarnating);
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
		label.hittest = false;

		var value = $.CreatePanel("Label", label, "XHSOverheadValue_" + playerID);
		value.AddClass("XHSOverheadValue");
		value.hittest = false;

		var content = $.CreatePanel("Panel", label, "XHSOverheadContent_" + playerID);
		content.AddClass("XHSOverheadContent");
		content.hittest = false;

		var topRow = $.CreatePanel("Panel", content, "XHSOverheadTopRow_" + playerID);
		topRow.AddClass("XHSOverheadTopRow");
		topRow.hittest = false;

		var badge = $.CreatePanel("Panel", topRow, "XHSOverheadBadge_" + playerID);
		badge.AddClass("XHSOverheadBadge");
		badge.hittest = false;

		var badgeLabel = $.CreatePanel("Label", badge, "XHSOverheadBadgeLabel_" + playerID);
		badgeLabel.AddClass("XHSOverheadBadgeLabel");
		badgeLabel.hittest = false;

		var name = $.CreatePanel("Label", topRow, "XHSOverheadName_" + playerID);
		name.AddClass("XHSOverheadName");
		name.hittest = false;

		var tagWrap = $.CreatePanel("Panel", topRow, "XHSOverheadTagWrap_" + playerID);
		tagWrap.AddClass("XHSOverheadTagWrap");
		tagWrap.hittest = false;

		var gameTag = $.CreatePanel("Label", tagWrap, "XHSOverheadGameTag_" + playerID);
		gameTag.AddClass("XHSOverheadGameTag");
		gameTag.hittest = false;

		var tierTag = $.CreatePanel("Label", tagWrap, "XHSOverheadTierTag_" + playerID);
		tierTag.AddClass("XHSOverheadTierTag");
		tierTag.hittest = false;

		var statusRow = $.CreatePanel("Panel", content, "XHSOverheadStatusRow_" + playerID);
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

		var bars = $.CreatePanel("Panel", label, "XHSOverheadBars_" + playerID);
		bars.AddClass("XHSOverheadBars");
		bars.hittest = false;

		var portraitFrame = $.CreatePanel("Panel", bars, "XHSOverheadHeroPortraitFrame_" + playerID);
		portraitFrame.AddClass("XHSOverheadHeroPortraitFrame");
		portraitFrame.hittest = false;

		CreateOverheadHeroImage(portraitFrame, "XHSOverheadHeroPortrait_" + playerID);

		var healthFrame = $.CreatePanel("Panel", bars, "XHSOverheadHealthFrame_" + playerID);
		healthFrame.AddClass("XHSOverheadHealthFrame");
		healthFrame.hittest = false;

		var healthFill = $.CreatePanel("Panel", healthFrame, "XHSOverheadHealthFill_" + playerID);
		healthFill.AddClass("XHSOverheadHealthFill");
		healthFill.hittest = false;

		var healthTicks = $.CreatePanel("Panel", healthFrame, "XHSOverheadHealthTicks_" + playerID);
		healthTicks.AddClass("XHSOverheadHealthTicks");
		healthTicks.hittest = false;

		for (var tickIndex = 0; tickIndex < 10; tickIndex++) {
			var tick = $.CreatePanel("Panel", healthTicks, "XHSOverheadHealthTick_" + playerID + "_" + tickIndex);
			tick.AddClass("XHSOverheadHealthTick");
			tick.hittest = false;
		}

		var manaFrame = $.CreatePanel("Panel", bars, "XHSOverheadManaFrame_" + playerID);
		manaFrame.AddClass("XHSOverheadManaFrame");
		manaFrame.hittest = false;

		var manaFill = $.CreatePanel("Panel", manaFrame, "XHSOverheadManaFill_" + playerID);
		manaFill.AddClass("XHSOverheadManaFill");
		manaFill.hittest = false;

		var healthLevel = $.CreatePanel("Label", bars, "XHSOverheadHealthLevel_" + playerID);
		healthLevel.AddClass("XHSOverheadHealthLevel");
		healthLevel.hittest = false;

		var anchor = $.CreatePanel("Panel", label, "XHSOverheadAnchor_" + playerID);
		anchor.AddClass("XHSOverheadAnchor");
		anchor.hittest = false;

		var anchorDot = $.CreatePanel("Panel", label, "XHSOverheadAnchorDot_" + playerID);
		anchorDot.AddClass("XHSOverheadAnchorDot");
		anchorDot.hittest = false;

		return label;
	}

	function ClearOverheadLabel(playerID) {
		if (overheadLabels[playerID]) {
			overheadLabels[playerID].DeleteAsync(0);
			delete overheadLabels[playerID];
		}
	}

	function EnsureOverheadLabel(playerID) {
		if (!overheadLabels[playerID]) {
			overheadLabels[playerID] = CreateOverheadLabel(playerID);
		}

		return overheadLabels[playerID];
	}

	function SetOverheadAccent(label, playerID, tierData) {
		if (!label) {
			return;
		}

		var accent = tierData && tierData.tier > 0 ? tierData.color : GetPlayerColorString(playerID);
		var content = label.FindChildTraverse("XHSOverheadContent_" + playerID);
		var badge = label.FindChildTraverse("XHSOverheadBadge_" + playerID);
		var node = label.FindChildTraverse("XHSOverheadStatusNode_" + playerID);
		var anchorDot = label.FindChildTraverse("XHSOverheadAnchorDot_" + playerID);

		if (content) {
			content.style.border = "1px solid " + accent;
			content.style.borderLeft = "3px solid " + accent;
		}
		if (badge) {
			badge.style.border = "1px solid " + accent;
			badge.style.boxShadow = "fill " + accent + "66 0px 0px 8px 0px";
		}
		if (node) {
			node.style.backgroundColor = accent;
			node.style.boxShadow = "fill " + accent + "88 0px 0px 7px 0px";
		}
		if (anchorDot) {
			anchorDot.style.backgroundColor = accent;
			anchorDot.style.boxShadow = "fill " + accent + "88 0px 0px 8px 0px";
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
		if (data.tier > 0) {
			return "SEASON " + data.seasonLevel + " / BP XP " + FormatNumber(data.seasonXP);
		}

		return "SEASON " + data.seasonLevel + " / SUPPORTER PASS";
	}

	function UpdateOverheadLabelData(playerID, entIndex) {
		var label = EnsureOverheadLabel(playerID);
		if (!label || !IsValidEntityIndex(entIndex)) {
			return;
		}

		var data = GetSupporterPlayerData(playerID, entIndex);
		var tierData = GetSupporterTierData(playerID);
		var playerName = data.playerName || ("Player " + (playerID + 1));
		var badgeText = GetSupporterTierBadgeLetter(tierData) || playerName.charAt(0).toUpperCase();
		var tierTag = data.tier > 0 ? "T" + data.tier : "PASS";

		label.SetAttributeInt("ent_index", entIndex);
		label.SetHasClass("XHSOverheadLocalPlayer", playerID === GetLocalPlayerID());
		label.SetHasClass("IsDisconnected", !!data.disconnected);

		ClearSupporterTierClasses(label);
		label.AddClass("XHSSupporterTier" + data.tier);
		SetOverheadAccent(label, playerID, tierData);

		SetChildText(label, "XHSOverheadBadgeLabel_" + playerID, badgeText);
		SetChildText(label, "XHSOverheadName_" + playerID, playerName);
		SetChildText(label, "XHSOverheadGameTag_" + playerID, "LV " + Math.max(1, ToNumber(data.heroLevel, 1)));
		SetChildText(label, "XHSOverheadTierTag_" + playerID, tierTag);
		SetChildText(label, "XHSOverheadGameplayStatus_" + playerID, FormatOverheadGameplayStatus(data));
		SetChildText(label, "XHSOverheadAltStatus_" + playerID, data.tierName + " / " + FormatOverheadAltStatus(data));
		SetChildText(label, "XHSOverheadHealthLevel_" + playerID, Math.max(1, ToNumber(data.heroLevel, 1)).toString());

		var portrait = label.FindChildTraverse("XHSOverheadHeroPortrait_" + playerID);
		SetOverheadHeroImage(portrait, data.heroName);
	}

	function UpdateOverheadLabelVitals(playerID, entIndex, healthPercent, manaPercent, health, maxHealth, hasMana) {
		var label = EnsureOverheadLabel(playerID);
		if (!label || !IsValidEntityIndex(entIndex)) {
			return;
		}

		var value = label.FindChildTraverse("XHSOverheadValue_" + playerID);
		var healthFill = label.FindChildTraverse("XHSOverheadHealthFill_" + playerID);
		var manaFill = label.FindChildTraverse("XHSOverheadManaFill_" + playerID);
		var clampedHealth = Clamp(ToNumber(healthPercent, 0), 0, 100);
		var currentHealth = Math.max(0, Math.floor(ToNumber(health, 0)));
		var currentMaxHealth = Math.max(1, Math.floor(ToNumber(maxHealth, 1)));
		var reincarnationState = GetReincarnationState(entIndex);
		var shouldHideDeadOverhead = clampedHealth <= 0 && !reincarnationState.active && GetAnkhCharges(entIndex) <= 0;

		if (value) {
			value.text = FormatNumber(currentHealth) + " / " + FormatNumber(currentMaxHealth);
		}

		if (healthFill) {
			healthFill.style.width = clampedHealth + "%";
		}
		if (manaFill) {
			manaFill.style.width = Clamp(ToNumber(manaPercent, 0), 0, 100) + "%";
		}

		label.SetHasClass("IsDead", clampedHealth <= 0);
		label.SetHasClass("IsReincarnating", reincarnationState.active);
		label.SetHasClass("XHSOverheadLowHealth", clampedHealth > 0 && clampedHealth <= 30);
		label.SetHasClass("XHSNoMana", !hasMana);
		label.SetAttributeInt("death_hidden", shouldHideDeadOverhead ? 1 : 0);

		if (reincarnationState.active) {
			SetChildText(label, "XHSOverheadGameplayStatus_" + playerID, FormatReincarnationStatus(reincarnationState));
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
		if (!root || !IsValidEntityIndex(entIndex) || label.GetAttributeInt("death_hidden", 0) > 0) {
			SetOverheadLabelVisible(label, false);
			return;
		}

		var origin = SafeValue(function () {
			return Entities.GetAbsOrigin(entIndex);
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
		var isVisible = edgeFade > 0;

		label.style.position = Math.floor(x) + "px " + Math.floor(y) + "px 0px";
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

	function CreateHoverStat(parent, id, labelText) {
		var stat = $.CreatePanel("Panel", parent, "XHSSupporterHoverStat_" + id);
		stat.AddClass("XHSSupporterHoverStat");

		var label = $.CreatePanel("Label", stat, "XHSSupporterHoverStatLabel_" + id);
		label.AddClass("XHSSupporterHoverStatLabel");
		label.text = labelText;

		var value = $.CreatePanel("Label", stat, "XHSSupporterHoverStatValue_" + id);
		value.AddClass("XHSSupporterHoverStatValue");
		value.text = "-";
	}

	function CreateHoverMeter(parent, id, labelText) {
		var meter = $.CreatePanel("Panel", parent, "XHSSupporterHoverMeter_" + id);
		meter.AddClass("XHSSupporterHoverMeter");

		var row = $.CreatePanel("Panel", meter, "XHSSupporterHoverMeterRow_" + id);
		row.AddClass("XHSSupporterHoverMeterRow");

		var label = $.CreatePanel("Label", row, "XHSSupporterHoverMeterLabel_" + id);
		label.AddClass("XHSSupporterHoverMeterLabel");
		label.text = labelText;

		var value = $.CreatePanel("Label", row, "XHSSupporterHoverMeterValue_" + id);
		value.AddClass("XHSSupporterHoverMeterValue");
		value.text = "-";

		var track = $.CreatePanel("Panel", meter, "XHSSupporterHoverMeterTrack_" + id);
		track.AddClass("XHSSupporterHoverMeterTrack");

		var fill = $.CreatePanel("Panel", track, "XHSSupporterHoverMeterFill_" + id);
		fill.AddClass("XHSSupporterHoverMeterFill");
	}

	function CreateAllyHoverCard(card, playerID, isRightSide) {
		var hoverParent = Panel("XHSTopHudRoot") || card;
		var hover = $.CreatePanel("Panel", hoverParent, "XHSSupporterHoverCard_" + playerID);
		hover.AddClass("XHSSupporterHoverCard");
		hover.AddClass(isRightSide ? "XHSSupporterHoverRight" : "XHSSupporterHoverLeft");
		hover.hittest = false;

		var header = $.CreatePanel("Panel", hover, "XHSSupporterHoverHeader_" + playerID);
		header.AddClass("XHSSupporterHoverHeader");

		var heroFrame = $.CreatePanel("Panel", header, "XHSSupporterHoverHeroFrame_" + playerID);
		heroFrame.AddClass("XHSSupporterHoverHeroFrame");

		var heroImage = $.CreatePanel("DOTAHeroImage", heroFrame, "XHSSupporterHoverHeroImage_" + playerID);
		heroImage.AddClass("XHSSupporterHoverHeroImage");
		heroImage.heroimagestyle = "landscape";
		heroImage.scaling = "stretch-to-cover-preserve-aspect";

		var headerCopy = $.CreatePanel("Panel", header, "XHSSupporterHoverHeaderCopy_" + playerID);
		headerCopy.AddClass("XHSSupporterHoverHeaderCopy");

		var eyebrow = $.CreatePanel("Label", headerCopy, "XHSSupporterHoverEyebrow_" + playerID);
		eyebrow.AddClass("XHSSupporterHoverEyebrow");
		eyebrow.text = "SUPPORTER PROFILE";

		var playerName = $.CreatePanel("Label", headerCopy, "XHSSupporterHoverPlayerName_" + playerID);
		playerName.AddClass("XHSSupporterHoverPlayerName");

		var heroName = $.CreatePanel("Label", headerCopy, "XHSSupporterHoverHeroName_" + playerID);
		heroName.AddClass("XHSSupporterHoverHeroName");

		var tierBadge = $.CreatePanel("Panel", hover, "XHSSupporterHoverTierBadge_" + playerID);
		tierBadge.AddClass("XHSSupporterHoverTierBadge");

		var tierLabel = $.CreatePanel("Label", tierBadge, "XHSSupporterHoverTierLabel_" + playerID);
		tierLabel.AddClass("XHSSupporterHoverTierLabel");
		tierLabel.text = "TIER";

		var tierValue = $.CreatePanel("Label", tierBadge, "XHSSupporterHoverTierValue_" + playerID);
		tierValue.AddClass("XHSSupporterHoverTierValue");

		var stats = $.CreatePanel("Panel", hover, "XHSSupporterHoverStats_" + playerID);
		stats.AddClass("XHSSupporterHoverStats");
		CreateHoverStat(stats, "AccountLevel_" + playerID, "XHS Level");
		CreateHoverStat(stats, "SeasonLevel_" + playerID, "Season Level");
		CreateHoverStat(stats, "Fragments_" + playerID, "Fragments");
		CreateHoverStat(stats, "Winrate_" + playerID, "Winrate");
		CreateHoverStat(stats, "HeroLevel_" + playerID, "Hero Level");
		CreateHoverStat(stats, "Ankh_" + playerID, "Ankh");

		CreateHoverMeter(hover, "XP_" + playerID, "Season XP");
		CreateHoverMeter(hover, "AccountXP_" + playerID, "Global XP");
		CreateHoverMeter(hover, "Weekly_" + playerID, "Daily Cap");

		var perks = $.CreatePanel("Panel", hover, "XHSSupporterHoverPerks_" + playerID);
		perks.AddClass("XHSSupporterHoverPerks");

		var perksTitle = $.CreatePanel("Label", perks, "XHSSupporterHoverPerksTitle_" + playerID);
		perksTitle.AddClass("XHSSupporterHoverPerksTitle");

		for (var i = 1; i <= 3; i++) {
			var perk = $.CreatePanel("Label", perks, "XHSSupporterHoverPerk" + i + "_" + playerID);
			perk.AddClass("XHSSupporterHoverPerk");
		}

		var footer = $.CreatePanel("Label", hover, "XHSSupporterHoverFooter_" + playerID);
		footer.AddClass("XHSSupporterHoverFooter");
	}

	function CreateAllyCard(playerID, rosterIndex) {
		var isRightSide = rosterIndex >= 4;
		var roster = Panel(isRightSide ? "XHSAllyRosterRight" : "XHSAllyRosterLeft");
		if (!roster) {
			return null;
		}

		var card = $.CreatePanel("Panel", roster, "XHSAllyCard_" + playerID);
		card.AddClass("XHSAllyCard");
		card.SetAttributeInt("player_id", playerID);
		card.SetAttributeInt("ent_index", -1);
		card.SetAttributeInt("roster_side", isRightSide ? 1 : 0);
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

		var overlay = $.CreatePanel("Panel", imageWrap, "XHSAllyStatusOverlay_" + playerID);
		overlay.AddClass("XHSAllyStatusOverlay");
		overlay.hittest = false;

		var supporterCrest = $.CreatePanel("Panel", card, "XHSSupporterCrest_" + playerID);
		supporterCrest.AddClass("XHSSupporterCrest");
		supporterCrest.hittest = true;
		supporterCrest.SetPanelEvent("onmouseover", function () {
			$.DispatchEvent("UIShowTextTooltip", supporterCrest, GetSupporterTierData(playerID).name);
		});
		supporterCrest.SetPanelEvent("onmouseout", function () {
			$.DispatchEvent("UIHideTextTooltip", supporterCrest);
		});

		var supporterCrestLabel = $.CreatePanel("Label", supporterCrest, "XHSSupporterCrestLabel_" + playerID);
		supporterCrestLabel.AddClass("XHSSupporterCrestLabel");
		supporterCrestLabel.text = "";
		supporterCrestLabel.hittest = false;

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

		CreateAllyHoverCard(card, playerID, isRightSide);

		card.SetPanelEvent("onmouseover", function () {
			ShowAllyHover(card, playerID);
		});

		card.SetPanelEvent("onmouseout", function () {
			HideAllyHover(card);
		});

		card.SetPanelEvent("onactivate", function () {
			SelectUnitOrCast(card.GetAttributeInt("ent_index", -1));
		});

		card.SetPanelEvent("ondblclick", function () {
			MoveCameraToUnit(card.GetAttributeInt("ent_index", -1));
		});

		return card;
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
		for (var i = 0; i < ids.length; i++) {
			var playerID = parseInt(ids[i], 10);
			if (isNaN(playerID) || playerID < 0 || unique[playerID]) {
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

		return {
			playerName: SafeValue(function () { return Players.GetPlayerName(playerID); }, playerInfo.player_name || "Player " + (playerID + 1)),
			heroName: SafeValue(function () { return Entities.GetUnitName(entIndex); }, Players.GetPlayerSelectedHero(playerID)),
			localHeroName: SafeValue(function () { return $.Localize("#" + Entities.GetUnitName(entIndex)); }, ""),
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

		card.AddClass("XHSHoverVisible");
		var hover = Panel("XHSSupporterHoverCard_" + playerID);
		if (hover) {
			hover.AddClass("XHSHoverVisible");
		}
		UpdateAllyHover(card, playerID);
	}

	function HideAllyHover(card) {
		if (card) {
			var hover = Panel("XHSSupporterHoverCard_" + card.GetAttributeInt("player_id", -1));
			if (hover) {
				hover.RemoveClass("XHSHoverVisible");
			}
			card.RemoveClass("XHSHoverVisible");
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
		ClearSupporterTierClasses(hover);
		hover.AddClass("XHSSupporterTier" + data.tier);

		var heroImage = hover.FindChildTraverse("XHSSupporterHoverHeroImage_" + playerID);
		if (heroImage && data.heroName) {
			heroImage.heroname = data.heroName;
		}

		SetChildText(hover, "XHSSupporterHoverPlayerName_" + playerID, data.playerName);
		SetChildText(hover, "XHSSupporterHoverHeroName_" + playerID, data.localHeroName || data.heroName);
		SetChildText(hover, "XHSSupporterHoverTierValue_" + playerID, data.tierName);
		SetChildText(hover, "XHSSupporterHoverStatValue_AccountLevel_" + playerID, data.accountLevel > 0 ? data.accountLevel : "-");
		SetChildText(hover, "XHSSupporterHoverStatValue_SeasonLevel_" + playerID, data.seasonLevel);
		SetChildText(hover, "XHSSupporterHoverStatValue_Fragments_" + playerID, FormatNumber(data.fragments));
		SetChildText(hover, "XHSSupporterHoverStatValue_Winrate_" + playerID, FormatWinrate(data.winrate));
		SetChildText(hover, "XHSSupporterHoverStatValue_HeroLevel_" + playerID, data.heroLevel);
		SetChildText(hover, "XHSSupporterHoverStatValue_Ankh_" + playerID, data.ankhCharges);
		SetChildText(hover, "XHSSupporterHoverMeterValue_XP_" + playerID, FormatNumber(data.seasonXP) + " / " + FormatNumber(data.seasonXPMax));
		SetChildText(hover, "XHSSupporterHoverMeterValue_AccountXP_" + playerID, FormatAccountXPSummary(data));
		SetChildText(hover, "XHSSupporterHoverMeterValue_Weekly_" + playerID, FormatNumber(data.weeklyFragments) + " / " + FormatNumber(data.weeklyCap));
		SetFillPercent(hover, "XHSSupporterHoverMeterFill_XP_" + playerID, data.seasonXP, data.seasonXPMax);
		SetFillPercent(hover, "XHSSupporterHoverMeterFill_AccountXP_" + playerID, data.accountXPCurrent, data.accountXPMax > 0 ? data.accountXPMax : 1);
		SetFillPercent(hover, "XHSSupporterHoverMeterFill_Weekly_" + playerID, data.weeklyFragments, data.weeklyCap);
		PositionAllyHover(card, hover);

		if (data.tier > 0) {
			SetChildText(hover, "XHSSupporterHoverPerksTitle_" + playerID, "Active status");
			SetChildText(hover, "XHSSupporterHoverPerk1_" + playerID, "+" + FormatNumber(data.fragmentsPerMonth) + " monthly fragments");
			SetChildText(hover, "XHSSupporterHoverPerk2_" + playerID, "+" + FormatNumber(data.xpBoost) + "% season XP");
			SetChildText(hover, "XHSSupporterHoverPerk3_" + playerID, FormatVotePower(data.votePower));
			SetChildText(hover, "XHSSupporterHoverFooter_" + playerID, "Cosmetic prestige only. No combat power is sold.");
		} else {
			var entryTier = GetSupporterTierInfo(1);
			SetChildText(hover, "XHSSupporterHoverPerksTitle_" + playerID, "Supporter upgrade");
			SetChildText(hover, "XHSSupporterHoverPerk1_" + playerID, "+" + FormatNumber(entryTier.fragments) + " monthly fragments");
			SetChildText(hover, "XHSSupporterHoverPerk2_" + playerID, "+" + FormatNumber(entryTier.xpBoost) + "% season XP");
			SetChildText(hover, "XHSSupporterHoverPerk3_" + playerID, FormatVotePower(entryTier.votePower));
			SetChildText(hover, "XHSSupporterHoverFooter_" + playerID, "Match this status from the Supporter Pass panel.");
		}
	}

	function UpdateAllySupporterTier(card, playerID) {
		var tierData = GetSupporterTierData(playerID);
		var supporterMark = card.FindChildTraverse("XHSSupporterMark_" + playerID);
		var supporterCrestLabel = card.FindChildTraverse("XHSSupporterCrestLabel_" + playerID);

		ClearSupporterTierClasses(card);
		ClearSupporterTierClasses(supporterMark);

		card.AddClass("XHSSupporterTier" + tierData.tier);
		if (supporterMark) {
			supporterMark.AddClass("XHSSupporterTier" + tierData.tier);
		}
		if (supporterCrestLabel) {
			supporterCrestLabel.text = GetSupporterTierBadgeLetter(tierData);
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
			name.text = SafeValue(function () { return $.Localize("#" + heroName); }, heroName || playerName);
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

	function FormatReincarnationStatus(state) {
		return "REINCARNATING IN " + Math.ceil(Math.max(0, state.remaining || 0)).toString();
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

		card.SetHasClass("IsDead", clampedHealth <= 0);
		card.SetHasClass("XHSNoMana", !hasMana);
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
		var playerIDs = GetRosterPlayerIDs();
		var activePlayerIDs = {};

		for (var slotIndex = 0; slotIndex < playerIDs.length; slotIndex++) {
			var playerID = playerIDs[slotIndex];
			activePlayerIDs[playerID] = true;

			var entIndex = Players.GetPlayerHeroEntityIndex(playerID);
			var playerInfo = Game.GetPlayerInfo(playerID);

			if (!IsValidEntityIndex(entIndex)) {
				if (allyCards[playerID]) {
					allyCards[playerID].DeleteAsync(0);
					delete allyCards[playerID];
				}
				ClearOverheadLabel(playerID);
				continue;
			}

			var expectedSide = slotIndex >= 4 ? 1 : 0;
			if (allyCards[playerID] && allyCards[playerID].GetAttributeInt("roster_side", -1) !== expectedSide) {
				allyCards[playerID].DeleteAsync(0);
				delete allyCards[playerID];
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
				allyCards[cardPlayerID].DeleteAsync(0);
				delete allyCards[cardPlayerID];
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
	}

	function ShowCurrentEventTimer(timerName, title, isVisible, duration) {
		if (isVisible) {
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

	function SubscribeTimerEvents() {
		GameEvents.Subscribe("countdown_timer", CountdownTimer);
		GameEvents.Subscribe("show_timer_bar", function () {});
		GameEvents.Subscribe("game_difficulty", SetDifficulty);
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
	}

	function StartHeroRefreshLoop() {
		RefreshAllyRoster();
		$.Schedule(HERO_REFRESH_SECONDS, StartHeroRefreshLoop);
	}

	function StartVitalsRefreshLoop() {
		RefreshAllyVitals();
		$.Schedule(VITALS_REFRESH_SECONDS, StartVitalsRefreshLoop);
	}

	function StartOverheadTrackingLoop() {
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

	function Initialize() {
		SubscribeTimerEvents();
		CustomNetTables.SubscribeNetTableListener("vips", RefreshVipRoster);
		CustomNetTables.SubscribeNetTableListener("supporter_pass_meta", function () {
			RefreshAllyRoster();
		});
		CustomNetTables.SubscribeNetTableListener("supporter_pass_player", function () {
			RefreshAllyRoster();
		});

		UpdateFocusTimersVisibility();
		StartHeroRefreshLoop();
		StartVitalsRefreshLoop();
		StartOverheadTrackingLoop();
		StartSlowRefreshLoop();
		RefreshAltState();
	}

	return {
		Initialize: Initialize,
	};
})();

XHSTopHud.Initialize();
