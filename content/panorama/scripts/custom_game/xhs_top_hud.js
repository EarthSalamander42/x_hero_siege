"use strict";

var XHSTopHud = (function () {
	var MAX_PLAYER_SLOTS = 8;
	var HERO_REFRESH_SECONDS = 0.75;
	var VITALS_REFRESH_SECONDS = 0.12;
	var SLOW_REFRESH_SECONDS = 1.0;
	var ANKH_ICON_PATH = "s2r://panorama/images/spellicons/custom/ankh_of_reincarnation_png.vtex";

	var allyCards = {};
	var vipCards = {};

	var timerCards = {
		special_arena: "XHSTimerCard_special_arena",
		hero_image: "XHSTimerCard_hero_image",
		spirit_beast: "XHSTimerCard_spirit_beast",
		frost_infernal: "XHSTimerCard_frost_infernal",
		all_hero_images: "XHSTimerCard_all_hero_images",
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

	function CreateAllyCard(playerID) {
		var roster = Panel("XHSAllyRoster");
		if (!roster) {
			return null;
		}

		var card = $.CreatePanel("Panel", roster, "XHSAllyCard_" + playerID);
		card.AddClass("XHSAllyCard");
		card.SetAttributeInt("player_id", playerID);
		card.SetAttributeInt("ent_index", -1);
		card.hittest = true;

		var colorStrip = $.CreatePanel("Panel", card, "XHSAllyColorStrip_" + playerID);
		colorStrip.AddClass("XHSAllyColorStrip");

		var imageWrap = $.CreatePanel("Panel", card, "XHSAllyImageWrap_" + playerID);
		imageWrap.AddClass("XHSAllyImageWrap");

		var heroImage = $.CreatePanel("DOTAHeroImage", imageWrap, "XHSAllyHeroImage_" + playerID);
		heroImage.AddClass("XHSAllyHeroImage");
		heroImage.heroimagestyle = "icon";
		heroImage.scaling = "stretch-to-cover-preserve-aspect";

		var overlay = $.CreatePanel("Panel", imageWrap, "XHSAllyStatusOverlay_" + playerID);
		overlay.AddClass("XHSAllyStatusOverlay");

		var disconnect = $.CreatePanel("Panel", imageWrap, "XHSDisconnectIcon_" + playerID);
		disconnect.AddClass("XHSDisconnectIcon");

		var name = $.CreatePanel("Label", card, "XHSAllyName_" + playerID);
		name.AddClass("XHSAllyName");

		var bars = $.CreatePanel("Panel", card, "XHSAllyBars_" + playerID);
		bars.AddClass("XHSAllyBars");
		CreateProgressBar(bars, "XHSAllyHealthBar_" + playerID, "XHSAllyHealthBar");
		CreateProgressBar(bars, "XHSAllyManaBar_" + playerID, "XHSAllyManaBar");

		var ankhBadge = $.CreatePanel("Panel", card, "XHSAnkhBadge_" + playerID);
		ankhBadge.AddClass("XHSAnkhBadge");

		var ankhIcon = $.CreatePanel("Image", ankhBadge, "XHSAnkhIcon_" + playerID);
		ankhIcon.AddClass("XHSAnkhIcon");
		ankhIcon.SetImage(ANKH_ICON_PATH);

		var ankhCount = $.CreatePanel("Label", ankhBadge, "XHSAnkhCount_" + playerID);
		ankhCount.AddClass("XHSAnkhCount");
		ankhCount.text = "0";

		card.SetPanelEvent("onactivate", function () {
			SelectUnitOrCast(card.GetAttributeInt("ent_index", -1));
		});

		card.SetPanelEvent("ondblclick", function () {
			MoveCameraToUnit(card.GetAttributeInt("ent_index", -1));
		});

		return card;
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

		card.SetHasClass("IsDisconnected", IsPlayerDisconnected(playerInfo));
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
	}

	function UpdateAllyAnkh(card, playerID, entIndex) {
		var charges = GetAnkhCharges(entIndex);
		var label = card.FindChildTraverse("XHSAnkhCount_" + playerID);

		if (label) {
			label.text = charges.toString();
		}

		card.SetHasClass("NoAnkh", charges <= 0);
	}

	function RefreshAllyRoster() {
		for (var playerID = 0; playerID < MAX_PLAYER_SLOTS; playerID++) {
			var entIndex = Players.GetPlayerHeroEntityIndex(playerID);
			var playerInfo = Game.GetPlayerInfo(playerID);

			if (!IsValidEntityIndex(entIndex)) {
				if (allyCards[playerID]) {
					allyCards[playerID].DeleteAsync(0);
					delete allyCards[playerID];
				}
				continue;
			}

			if (!allyCards[playerID]) {
				allyCards[playerID] = CreateAllyCard(playerID);
			}

			if (allyCards[playerID]) {
				UpdateAllyIdentity(allyCards[playerID], playerID, entIndex, playerInfo);
				UpdateAllyAnkh(allyCards[playerID], playerID, entIndex);
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

	function ShowTimer(timerName, isVisible) {
		var card = Panel(timerCards[timerName]);
		if (card) {
			card.SetHasClass("XHSOptionalTimer", !isVisible);
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

		SetText("XHSTimerValue_" + data.timer_name, text);
	}

	function SetDifficulty(data) {
		SetText("XHSTimerValue_difficulty", data && data.difficulty ? data.difficulty : "-----");
	}

	function SetSpecialEventLabel(text) {
		SetText("XHSTimerTitle_special_event", text);
	}

	function SubscribeTimerEvents() {
		GameEvents.Subscribe("countdown_timer", CountdownTimer);
		GameEvents.Subscribe("show_timer_bar", function () {});
		GameEvents.Subscribe("game_difficulty", SetDifficulty);
		GameEvents.Subscribe("update_special_event_label_farm", function () { SetSpecialEventLabel("FARM EVENT"); });
		GameEvents.Subscribe("update_special_event_label_final", function () { SetSpecialEventLabel("FINAL WAVE"); });

		GameEvents.Subscribe("show_timer_special_arena", function () { ShowTimer("special_arena", true); });
		GameEvents.Subscribe("show_timer_hero_image", function () { ShowTimer("hero_image", true); });
		GameEvents.Subscribe("show_timer_spirit_beast", function () { ShowTimer("spirit_beast", true); });
		GameEvents.Subscribe("show_timer_frost_infernal", function () { ShowTimer("frost_infernal", true); });
		GameEvents.Subscribe("show_timer_all_hero_image", function () { ShowTimer("all_hero_images", true); });

		GameEvents.Subscribe("hide_timer_special_arena", function () { ShowTimer("special_arena", false); });
		GameEvents.Subscribe("hide_timer_hero_image", function () { ShowTimer("hero_image", false); });
		GameEvents.Subscribe("hide_timer_spirit_beast", function () { ShowTimer("spirit_beast", false); });
		GameEvents.Subscribe("hide_timer_frost_infernal", function () { ShowTimer("frost_infernal", false); });
		GameEvents.Subscribe("hide_timer_all_hero_image", function () { ShowTimer("all_hero_images", false); });
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
		var mapInfo = Game.GetMapInfo();
		if (mapInfo && mapInfo.map_display_name === "x_hero_siege_8") {
			$.GetContextPanel().AddClass("XHSEightPlayers");
		}

		SubscribeTimerEvents();
		CustomNetTables.SubscribeNetTableListener("vips", RefreshVipRoster);

		StartHeroRefreshLoop();
		StartVitalsRefreshLoop();
		StartSlowRefreshLoop();
	}

	return {
		Initialize: Initialize,
	};
})();

XHSTopHud.Initialize();
