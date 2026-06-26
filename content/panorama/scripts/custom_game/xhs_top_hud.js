"use strict";

var XHSTopHud = (function () {
	var MAX_PLAYER_DISPLAY_SLOTS = 8;
	var MAX_PLAYER_ID_SCAN = 23;
	var HERO_REFRESH_SECONDS = 0.75;
	var VITALS_REFRESH_SECONDS = 0.12;
	var SLOW_REFRESH_SECONDS = 1.0;
	var WEEKLY_FRAGMENT_CAP = 100;

	var allyCards = {};
	var vipCards = {};
	var activeCurrentEventTimerName = null;
	var activePersonalTimerName = null;
	var currentEventTimerMaxRemaining = {};
	var currentEventTimerProgressRunning = {};
	var personalTimerMaxRemaining = {};
	var personalTimerProgressRunning = {};

	var DEFAULT_SUPPORTER_TIER_CATALOG = [
		{ id: 0, name: "Free Player", color: "#7db9d8", fragments: 0, xpBoost: 0 },
		{ id: 1, name: "Donator", color: "#45C46B", fragments: 150, xpBoost: 10 },
		{ id: 2, name: "Golden Donator", color: "#F2C94C", fragments: 400, xpBoost: 20 },
		{ id: 3, name: "Ember Donator", color: "#E4572E", fragments: 900, xpBoost: 30 },
		{ id: 4, name: "Stoneguard Donator", color: "#7B8794", fragments: 1800, xpBoost: 40 },
		{ id: 5, name: "Earthwarden Donator", color: "#2EC4B6", fragments: 1800, xpBoost: 40 },
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
		var bar = $.CreatePanel("ProgressBar", parent, id);
		bar.AddClass(className);
		bar.min = 0;
		bar.max = 100;
		bar.value = 100;
		return bar;
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
		var hover = $.CreatePanel("Panel", card, "XHSSupporterHoverCard_" + playerID);
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
		CreateHoverStat(stats, "Level_" + playerID, "Season Level");
		CreateHoverStat(stats, "Fragments_" + playerID, "Fragments");
		CreateHoverStat(stats, "HeroLevel_" + playerID, "Hero Level");
		CreateHoverStat(stats, "Ankh_" + playerID, "Ankh");
		CreateHoverStat(stats, "Health_" + playerID, "Health");
		CreateHoverStat(stats, "Mana_" + playerID, "Mana");

		CreateHoverMeter(hover, "XP_" + playerID, "Season XP");
		CreateHoverMeter(hover, "Weekly_" + playerID, "Weekly Cap");

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

		var overlay = $.CreatePanel("Panel", imageWrap, "XHSAllyStatusOverlay_" + playerID);
		overlay.AddClass("XHSAllyStatusOverlay");
		overlay.hittest = false;

		var disconnect = $.CreatePanel("Panel", imageWrap, "XHSDisconnectIcon_" + playerID);
		disconnect.AddClass("XHSDisconnectIcon");
		disconnect.hittest = false;

		var name = $.CreatePanel("Label", card, "XHSAllyName_" + playerID);
		name.AddClass("XHSAllyName");
		name.hittest = false;

		var bars = $.CreatePanel("Panel", card, "XHSAllyBars_" + playerID);
		bars.AddClass("XHSAllyBars");
		bars.hittest = false;
		CreateProgressBar(bars, "XHSAllyHealthBar_" + playerID, "XHSAllyHealthBar");
		CreateProgressBar(bars, "XHSAllyManaBar_" + playerID, "XHSAllyManaBar");

		var ankhBadge = $.CreatePanel("Panel", card, "XHSAnkhBadge_" + playerID);
		ankhBadge.AddClass("XHSAnkhBadge");
		ankhBadge.hittest = false;

		var ankhIcon = $.CreatePanel("DOTAItemImage", ankhBadge, "XHSAnkhIcon_" + playerID);
		ankhIcon.AddClass("XHSAnkhIcon");
		ankhIcon.itemname = "item_ankh_of_reincarnation";
		ankhIcon.hittest = false;

		var ankhCount = $.CreatePanel("Label", ankhBadge, "XHSAnkhCount_" + playerID);
		ankhCount.AddClass("XHSAnkhCount");
		ankhCount.text = "0";
		ankhCount.hittest = false;

		var supporterMark = $.CreatePanel("Panel", ankhBadge, "XHSSupporterMark_" + playerID);
		supporterMark.AddClass("XHSSupporterMark");
		supporterMark.hittest = true;
		supporterMark.SetPanelEvent("onmouseover", function () {
			$.DispatchEvent("UIShowTextTooltip", supporterMark, GetSupporterTierData(playerID).name);
		});
		supporterMark.SetPanelEvent("onmouseout", function () {
			$.DispatchEvent("UIHideTextTooltip", supporterMark);
		});

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

	function IsEightPlayerMap() {
		var mapInfo = SafeValue(function () {
			return Game.GetMapInfo();
		}, null);

		if (!mapInfo) {
			return false;
		}

		return mapInfo.map_display_name === "x_hero_siege_8" || mapInfo.map_name === "x_hero_siege_8";
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
		tier = Clamp(ToNumber(tier, 0), 0, 5);
		return GetSupporterTierCatalog()[tier] || DEFAULT_SUPPORTER_TIER_CATALOG[0];
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
			};
		}

		return catalog;
	}

	function GetSupporterTierData(playerID) {
		var data = CustomNetTables.GetTableValue("supporter_pass_player", playerID.toString()) || {};
		var tier = ToNumber(data.tier_id || data.supporter_tier || data.donator_level || 0, 0);

		if (isNaN(tier)) {
			tier = 0;
		}

		tier = Clamp(tier, 0, 5);
		var tierInfo = GetSupporterTierInfo(tier);

		return {
			tier: tier,
			name: data.tier_name || data.supporter_tier_name || tierInfo.name,
			color: data.tier_color || tierInfo.color,
			fragmentsPerMonth: ToNumber(data.tier_fragments || tierInfo.fragments, tierInfo.fragments),
			xpBoost: ToNumber(data.tier_xp_boost || data.xp_boost || tierInfo.xpBoost, tierInfo.xpBoost),
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
			weeklyFragments: ToNumber(data.weekly_fragments || data.weekly_earned, 0),
			weeklyCap: Math.max(ToNumber(data.weekly_cap, WEEKLY_FRAGMENT_CAP), 1),
			seasonLevel: Math.max(1, ToNumber(data.season_level || data.Lvl, 1)),
			seasonXP: ToNumber(data.season_xp || data.XP, 0),
			seasonXPMax: Math.max(ToNumber(data.season_xp_max || data.MaxXP, 1000), 1),
			accountLevel: ToNumber(data.account_level || data.legacy_level, 0),
			fragmentsPerMonth: tierData.fragmentsPerMonth,
			xpBoost: tierData.xpBoost,
			heroLevel: SafeValue(function () { return Entities.GetLevel(entIndex); }, 0),
			ankhCharges: GetAnkhCharges(entIndex),
			healthPercent: SafeValue(function () { return Entities.GetHealthPercent(entIndex); }, 0),
			manaPercent: SafeValue(function () {
				var maxMana = Entities.GetMaxMana(entIndex);
				return maxMana <= 0 ? 0 : Math.floor(100.0 * (Entities.GetMana(entIndex) / maxMana));
			}, 0),
			disconnected: IsPlayerDisconnected(playerInfo),
		};
	}

	function ShowAllyHover(card, playerID) {
		if (!card) {
			return;
		}

		UpdateAllyHover(card, playerID);
		card.AddClass("XHSHoverVisible");
	}

	function HideAllyHover(card) {
		if (card) {
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

		var hover = card.FindChildTraverse("XHSSupporterHoverCard_" + playerID);
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
		SetChildText(hover, "XHSSupporterHoverStatValue_Level_" + playerID, data.seasonLevel);
		SetChildText(hover, "XHSSupporterHoverStatValue_Fragments_" + playerID, FormatNumber(data.fragments));
		SetChildText(hover, "XHSSupporterHoverStatValue_HeroLevel_" + playerID, data.heroLevel);
		SetChildText(hover, "XHSSupporterHoverStatValue_Ankh_" + playerID, data.ankhCharges);
		SetChildText(hover, "XHSSupporterHoverStatValue_Health_" + playerID, Math.floor(data.healthPercent) + "%");
		SetChildText(hover, "XHSSupporterHoverStatValue_Mana_" + playerID, Math.floor(data.manaPercent) + "%");
		SetChildText(hover, "XHSSupporterHoverMeterValue_XP_" + playerID, FormatNumber(data.seasonXP) + " / " + FormatNumber(data.seasonXPMax));
		SetChildText(hover, "XHSSupporterHoverMeterValue_Weekly_" + playerID, FormatNumber(data.weeklyFragments) + " / " + FormatNumber(data.weeklyCap));
		SetFillPercent(hover, "XHSSupporterHoverMeterFill_XP_" + playerID, data.seasonXP, data.seasonXPMax);
		SetFillPercent(hover, "XHSSupporterHoverMeterFill_Weekly_" + playerID, data.weeklyFragments, data.weeklyCap);

		if (data.tier > 0) {
			SetChildText(hover, "XHSSupporterHoverPerksTitle_" + playerID, "Active status");
			SetChildText(hover, "XHSSupporterHoverPerk1_" + playerID, "+" + FormatNumber(data.fragmentsPerMonth) + " monthly fragments");
			SetChildText(hover, "XHSSupporterHoverPerk2_" + playerID, "+" + FormatNumber(data.xpBoost) + "% season XP");
			SetChildText(hover, "XHSSupporterHoverPerk3_" + playerID, "Companions, emblems, effigies");
			SetChildText(hover, "XHSSupporterHoverFooter_" + playerID, "Cosmetic prestige only. No combat power is sold.");
		} else {
			var entryTier = GetSupporterTierInfo(1);
			SetChildText(hover, "XHSSupporterHoverPerksTitle_" + playerID, "Supporter upgrade");
			SetChildText(hover, "XHSSupporterHoverPerk1_" + playerID, "+" + FormatNumber(entryTier.fragments) + " monthly fragments");
			SetChildText(hover, "XHSSupporterHoverPerk2_" + playerID, "+" + FormatNumber(entryTier.xpBoost) + "% season XP");
			SetChildText(hover, "XHSSupporterHoverPerk3_" + playerID, "Premium profile and cosmetics");
			SetChildText(hover, "XHSSupporterHoverFooter_" + playerID, "Match this status from the Supporter Pass panel.");
		}
	}

	function UpdateAllySupporterTier(card, playerID) {
		var tierData = GetSupporterTierData(playerID);
		var supporterMark = card.FindChildTraverse("XHSSupporterMark_" + playerID);

		ClearSupporterTierClasses(card);
		ClearSupporterTierClasses(supporterMark);

		card.AddClass("XHSSupporterTier" + tierData.tier);
		if (supporterMark) {
			supporterMark.AddClass("XHSSupporterTier" + tierData.tier);
		}
	}

	function UpdateAllyIdentity(card, playerID, entIndex, playerInfo) {
		var playerName = SafeValue(function () {
			return Players.GetPlayerName(playerID);
		}, "Player " + (playerID + 1));

		var heroName = SafeValue(function () {
			return Entities.GetUnitName(entIndex);
		}, Players.GetPlayerSelectedHero(playerID));

		var playerColor = SafeValue(function () {
			return Players.GetPlayerColor(playerID);
		}, 0xFFFFFFFF);

		card.SetAttributeInt("ent_index", entIndex);

		var colorStrip = card.FindChildTraverse("XHSAllyColorStrip_" + playerID);
		if (colorStrip) {
			colorStrip.style.backgroundColor = IntToColorString(playerColor);
		}

		var name = card.FindChildTraverse("XHSAllyName_" + playerID);
		if (name) {
			name.text = playerName;
			name.style.color = IntToColorString(playerColor);
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

	function UpdateAllyVitals(card, playerID, entIndex) {
		var healthPercent = SafeValue(function () {
			return Entities.GetHealthPercent(entIndex);
		}, 0);

		var manaPercent = SafeValue(function () {
			var maxMana = Entities.GetMaxMana(entIndex);
			if (maxMana <= 0) {
				return 0;
			}
			return 100.0 * (Entities.GetMana(entIndex) / maxMana);
		}, 0);

		var healthBar = card.FindChildTraverse("XHSAllyHealthBar_" + playerID);
		var manaBar = card.FindChildTraverse("XHSAllyManaBar_" + playerID);

		if (healthBar) {
			healthBar.value = healthPercent;
		}

		if (manaBar) {
			manaBar.value = manaPercent;
		}

		card.SetHasClass("IsDead", healthPercent <= 0);

		if (card.BHasClass("XHSHoverVisible")) {
			UpdateAllyHover(card, playerID);
		}
	}

	function UpdateAllyAnkh(card, playerID, entIndex) {
		var charges = GetAnkhCharges(entIndex);
		var label = card.FindChildTraverse("XHSAnkhCount_" + playerID);

		if (label) {
			label.text = charges.toString();
		}

		card.SetHasClass("NoAnkh", charges <= 0);

		if (card.BHasClass("XHSHoverVisible")) {
			UpdateAllyHover(card, playerID);
		}
	}

	function RefreshAllyRoster() {
		var playerIDs = GetRosterPlayerIDs();
		var activePlayerIDs = {};
		$.GetContextPanel().SetHasClass("XHSEightPlayers", IsEightPlayerMap() || playerIDs.length > 4);

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
		}

		for (var cardPlayerID in allyCards) {
			if (!allyCards.hasOwnProperty(cardPlayerID)) {
				continue;
			}

			if (!activePlayerIDs[parseInt(cardPlayerID, 10)]) {
				allyCards[cardPlayerID].DeleteAsync(0);
				delete allyCards[cardPlayerID];
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
				UpdateAllyVitals(card, parseInt(playerID, 10), entIndex);
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

	function StartSlowRefreshLoop() {
		for (var playerID in allyCards) {
			if (!allyCards.hasOwnProperty(playerID)) {
				continue;
			}

			var card = allyCards[playerID];
			var entIndex = card.GetAttributeInt("ent_index", -1);
			if (IsValidEntityIndex(entIndex)) {
				UpdateAllyAnkh(card, parseInt(playerID, 10), entIndex);
			}
		}

		RefreshVipRoster();
		$.Schedule(SLOW_REFRESH_SECONDS, StartSlowRefreshLoop);
	}

	function Initialize() {
		$.GetContextPanel().SetHasClass("XHSEightPlayers", IsEightPlayerMap());

		SubscribeTimerEvents();
		CustomNetTables.SubscribeNetTableListener("vips", RefreshVipRoster);
		CustomNetTables.SubscribeNetTableListener("supporter_pass_meta", function () {
			RefreshAllyRoster();
		});
		CustomNetTables.SubscribeNetTableListener("supporter_pass_player", function () {
			RefreshAllyRoster();
		});

		StartHeroRefreshLoop();
		StartVitalsRefreshLoop();
		StartSlowRefreshLoop();
		RefreshAltState();
	}

	return {
		Initialize: Initialize,
	};
})();

XHSTopHud.Initialize();
