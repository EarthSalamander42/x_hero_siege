"use strict";

var BossBarState = {};
var BossBarIdentity = {};
var BossCastState = {};
var MAX_BOSS_BARS = 4;
var DEFAULT_BOSS_FILL_BACKGROUND = "gradient( linear, 0% 0%, 100% 0%, from( #2a0610 ), color-stop( 0.55, #c72542 ), to( #f5fff7 ) )";

function GetBossPanels(index) {
	return {
		container: $("#BossHP" + index),
		label: $("#BossLabel" + index),
		level: $("#BossLevel" + index),
		icon: $("#BossIcon" + index),
		iconImage: $("#BossIconImage" + index),
		health: $("#BossHealth" + index),
		bar: $("#BossProgressBar" + index),
		fill: $("#BossProgressFill" + index),
		damageLag: $("#BossDamageLag" + index),
		healPulse: $("#BossHealPulse" + index),
		markers: $("#BossMarkers" + index),
		counter: $("#BossCounter" + index),
		counterLabel: $("#BossCounterLabel" + index),
		counterValue: $("#BossCounterValue" + index),
		timer: $("#BossTimer" + index),
		timerLabel: $("#BossTimerLabel" + index),
		timerValue: $("#BossTimerValue" + index),
		timerFill: $("#BossTimerFill" + index),
		castBar: $("#BossCastBar" + index),
		castIcon: $("#BossCastIcon" + index),
		castIconImage: $("#BossCastIconImage" + index),
		castLabel: $("#BossCastLabel" + index),
		castTime: $("#BossCastTime" + index),
		castFill: $("#BossCastFill" + index),
		castGlow: $("#BossCastGlow" + index),
	};
}

function SetBossIcon(panels, bossIcon) {
	if (!panels || !panels.icon || !panels.iconImage) {
		return;
	}

	var imagePath = "";
	if (bossIcon) {
		imagePath = bossIcon.indexOf("/") >= 0
			? "file://{images}/" + bossIcon + ".png"
			: "file://{images}/heroes/" + bossIcon + ".png";
	}
	panels.icon.style.backgroundImage = "none";
	panels.iconImage.SetImage("");
	panels.iconImage.style.visibility = "collapse";

	if (!imagePath) {
		return;
	}

	panels.iconImage.SetImage(imagePath);
	panels.iconImage.style.visibility = "visible";
}

function SetBossCastIcon(panels, texture) {
	if (!panels || !panels.castIconImage) {
		return;
	}

	panels.castIconImage.SetImage("");
	panels.castIconImage.style.visibility = "collapse";

	if (!texture) {
		return;
	}

	panels.castIconImage.SetImage("file://{images}/spellicons/" + texture + ".png");
	panels.castIconImage.style.visibility = "visible";
}

function GetBossBarIndex(args) {
	var identity = GetBossBarIdentity(args);
	if (identity) {
		for (var i = 1; i <= MAX_BOSS_BARS; i++) {
			if (BossBarIdentity[i] === identity) {
				return i;
			}
		}
	}

	var index = Number(args && args.boss_count) || 1;
	if (index < 1 || index > MAX_BOSS_BARS) {
		return 1;
	}

	return index;
}

function GetBossBarIdentity(args) {
	if (!args || args.boss_bar_id === undefined || args.boss_bar_id === null || args.boss_bar_id === "") {
		return null;
	}

	return String(args.boss_bar_id);
}

function ShouldAcceptBossBarEvent(index, args) {
	var identity = GetBossBarIdentity(args);
	if (!identity) {
		return true;
	}

	if (!BossBarIdentity[index]) {
		return true;
	}

	return BossBarIdentity[index] === identity || index === (Number(args && args.boss_count) || 1);
}

function SetBossBarIdentity(index, args) {
	var identity = GetBossBarIdentity(args);
	if (identity) {
		BossBarIdentity[index] = identity;
	} else if (!BossBarIdentity[index]) {
		BossBarIdentity[index] = "slot_" + index;
	}
}

function UpdateBossBarLayout() {
	var visibleCount = 0;
	var root = $("#DiretidePanel");
	var visiblePanels = [];

	for (var i = 1; i <= MAX_BOSS_BARS; i++) {
		var panels = GetBossPanels(i);
		if (panels.container) {
			panels.container.SetHasClass("CenteredBossBar", false);
		}

		var visible = panels.container && panels.container.style.visibility === "visible";
		if (visible) {
			visibleCount++;
			visiblePanels.push(panels.container);
		}
	}

	if (root) {
		root.SetHasClass("SingleBossBar", visibleCount === 1);
		root.SetHasClass("MultiBossBars", visibleCount > 1);
		root.SetHasClass("OddBossBars", visibleCount > 1 && (visibleCount % 2) === 1);
	}

	if (visibleCount > 1 && (visibleCount % 2) === 1) {
		visiblePanels[visiblePanels.length - 1].SetHasClass("CenteredBossBar", true);
	}
}

function ResetBossPanels(index, panels) {
	if (!panels || !panels.container) {
		return;
	}

	panels.container.style.visibility = "collapse";
	panels.container.RemoveClass("HasBossCounter");
	panels.container.RemoveClass("HasBossTimer");
	panels.container.RemoveClass("HasBossCast");
	panels.container.RemoveClass("BossTimerStyleMagtheridon");
	panels.container.RemoveClass("BossTimerStyleSpiritMaster");
	panels.container.RemoveClass("BossCastStyleMagtheridon");
	panels.container.RemoveClass("BossCastStyleBanehallow");
	panels.container.RemoveClass("BossCastStyleGrom");
	panels.container.RemoveClass("BossCastStyleIllidan");
	panels.container.RemoveClass("BossCastStyleBalanar");
	panels.container.RemoveClass("BossCastStyleProudmoore");
	panels.container.RemoveClass("BossCastStyleLichKing");
	panels.container.RemoveClass("BossCastStyleSpiritMaster");
	panels.container.RemoveClass("BossCastStyleSpiritStorm");
	panels.container.RemoveClass("BossCastStyleSpiritEarth");
	panels.container.RemoveClass("BossCastStyleSpiritFire");
	panels.container.RemoveClass("BossDamaged");
	panels.container.RemoveClass("BossHealed");
	panels.container.RemoveClass("BossHeavyDamage");
	panels.label.text = "";
	panels.level.text = "";
	panels.level.style.visibility = "collapse";
	panels.level.SetHasClass("BossAnkhBadge", false);
	SetBossIcon(panels, null);
	panels.health.text = "";

	if (panels.fill) {
		panels.fill.style.width = "100%";
		panels.fill.style.backgroundColor = DEFAULT_BOSS_FILL_BACKGROUND;
	}
	if (panels.damageLag) {
		panels.damageLag.style.width = "100%";
	}
	if (panels.healPulse) {
		panels.healPulse.style.width = "100%";
	}
	if (panels.counterLabel) {
		panels.counterLabel.text = "";
	}
	if (panels.counterValue) {
		panels.counterValue.text = "";
	}
	if (panels.timerLabel) {
		panels.timerLabel.text = "";
	}
	if (panels.timerValue) {
		panels.timerValue.text = "";
	}
	if (panels.timerFill) {
		panels.timerFill.style.width = "0%";
	}
	if (panels.castLabel) {
		panels.castLabel.text = "";
	}
	if (panels.castTime) {
		panels.castTime.text = "";
	}
	if (panels.castFill) {
		panels.castFill.style.width = "0%";
		panels.castFill.style.transitionDuration = "0s";
	}
	SetBossCastIcon(panels, null);
	SetBossBarMarkers(panels, null);

	delete BossBarState[index];
	delete BossBarIdentity[index];
	delete BossCastState[index];
}

function FormatBossHealth(value) {
	var number = Number(value) || 0;

	if (number >= 1000000) {
		return (number / 1000000).toFixed(1).replace(".0", "") + "M";
	}

	if (number >= 10000) {
		return (number / 1000).toFixed(1).replace(".0", "") + "k";
	}

	return Math.floor(number).toString();
}

function FormatBossRatio(ratio) {
	return Math.round(Math.max(0, Math.min(1, ratio)) * 1000) / 10 + "%";
}

function FormatBossTimerSeconds(value) {
	var seconds = Math.max(0, Math.ceil(Number(value) || 0));
	var minutes = Math.floor(seconds / 60);
	var rest = seconds % 60;
	return minutes + ":" + (rest < 10 ? "0" : "") + rest;
}

function FormatBossCastSeconds(value) {
	return Math.max(0, Number(value) || 0).toFixed(1) + "s";
}

function GetBossCastTime() {
	if (typeof Game.GetGameTime === "function") {
		return Game.GetGameTime();
	}
	if (typeof Game.GetDOTATime === "function") {
		return Game.GetDOTATime(false, false);
	}
	return Date.now() / 1000;
}

function FormatBossAbilityName(args) {
	if (args && args.display_name) {
		return String(args.display_name);
	}

	if (args && args.ability_name) {
		var token = "#DOTA_Tooltip_ability_" + args.ability_name;
		var localized = $.Localize(token);
		if (localized && localized !== token) {
			return localized;
		}

		return String(args.ability_name)
			.replace(/^xhs_/, "")
			.replace(/^frostivus_boss_/, "")
			.replace(/_/g, " ");
	}

	return "Casting";
}

function FormatBossName(unitName) {
	var localized = $.Localize("#" + unitName);
	if (localized && localized !== "#" + unitName) {
		return localized;
	}

	return String(unitName || "Boss")
		.replace(/^npc_dota_(hero|boss)_/, "")
		.replace(/^npc_/, "")
		.replace(/_/g, " ");
}

function TriggerBossHealthReaction(index, panels, ratio) {
	var state = BossBarState[index] || {};
	var previous = typeof state.ratio === "number" ? state.ratio : ratio;
	var delta = ratio - previous;

	if (Math.abs(delta) < 0.001) {
		state.ratio = ratio;
		BossBarState[index] = state;
		return;
	}

	if (panels.container) {
		panels.container.RemoveClass("BossDamaged");
		panels.container.RemoveClass("BossHealed");
		panels.container.RemoveClass("BossHeavyDamage");
	}

	if (delta < 0) {
		if (panels.damageLag) {
			panels.damageLag.style.width = FormatBossRatio(previous);
			$.Schedule(0.05, function () {
				if (panels.damageLag) {
					panels.damageLag.style.width = FormatBossRatio(ratio);
				}
			});
		}

		if (panels.container) {
			panels.container.AddClass("BossDamaged");
			panels.container.SetHasClass("BossHeavyDamage", Math.abs(delta) >= 0.08);
			$.Schedule(0.36, function () {
				if (panels.container) {
					panels.container.RemoveClass("BossDamaged");
					panels.container.RemoveClass("BossHeavyDamage");
				}
			});
		}
	} else if (delta > 0) {
		if (panels.damageLag) {
			panels.damageLag.style.width = FormatBossRatio(ratio);
		}

		if (panels.healPulse) {
			panels.healPulse.style.width = FormatBossRatio(ratio);
		}

		if (panels.container) {
			panels.container.AddClass("BossHealed");
			$.Schedule(0.42, function () {
				if (panels.container) {
					panels.container.RemoveClass("BossHealed");
				}
			});
		}
	}

	state.ratio = ratio;
	BossBarState[index] = state;
}

function SetBossHealthFill(index, panels, health, maxHealth, args, isInitial) {
	var ratio = Math.max(0, Math.min(1, health / maxHealth));

	if (panels.fill) {
		panels.fill.style.width = FormatBossRatio(ratio);

		if (args && args.dark_color && args.light_color) {
			panels.fill.style.backgroundColor = "gradient( linear, 0% 0%, 100% 0%, from( " + args.dark_color + " ), color-stop( 0.55, " + args.light_color + " ), to( #f5fff7 ) )";
		} else {
			panels.fill.style.backgroundColor = DEFAULT_BOSS_FILL_BACKGROUND;
		}
	}

	if (panels.damageLag && (isInitial || BossBarState[index] == null)) {
		panels.damageLag.style.width = FormatBossRatio(ratio);
	}

	if (isInitial) {
		BossBarState[index] = { ratio: ratio };
	} else {
		TriggerBossHealthReaction(index, panels, ratio);
	}
}

function SetBossAnkhCount(panels, args) {
	if (!panels || !panels.level) {
		return;
	}

	if (args && args.ankh_count !== undefined && args.ankh_count !== null) {
		var count = Math.max(0, Number(args.ankh_count) || 0);
		panels.level.text = "ANKH " + count;
		panels.level.style.visibility = "visible";
		panels.level.SetHasClass("BossAnkhBadge", true);
		return;
	}

	panels.level.text = "";
	panels.level.style.visibility = "collapse";
	panels.level.SetHasClass("BossAnkhBadge", false);
}

function NormalizeBossBarMarkers(markers) {
	var result = [];
	if (!markers) {
		return result;
	}

	if (markers instanceof Array) {
		for (var i = 0; i < markers.length; i++) {
			if (markers[i]) {
				result.push(markers[i]);
			}
		}
		return result;
	}

	for (var key in markers) {
		if (markers.hasOwnProperty(key) && markers[key]) {
			result.push(markers[key]);
		}
	}

	result.sort(function (a, b) {
		return (Number(b.pct || b.percent || b.health_pct) || 0) - (Number(a.pct || a.percent || a.health_pct) || 0);
	});
	return result;
}

function SetBossBarMarkers(panels, markers) {
	if (!panels || !panels.markers) {
		return;
	}

	panels.markers.RemoveAndDeleteChildren();
	var normalized = NormalizeBossBarMarkers(markers);
	for (var i = 0; i < normalized.length; i++) {
		var marker = normalized[i];
		var pct = Math.max(0, Math.min(100, Number(marker.pct || marker.percent || marker.health_pct) || 0));
		if (pct <= 0 || pct >= 100) {
			continue;
		}

		var panel = $.CreatePanel("Panel", panels.markers, "BossThresholdMarker" + i);
		panel.AddClass("BossThresholdMarker");
		panel.SetHasClass("CompanionMarker", marker.kind === "companion");
		panel.SetHasClass("Triggered", marker.triggered === true || marker.triggered === 1);
		panel.style.position = pct + "% 0px 0px";
		panel.SetPanelEvent("onmouseover", (function (markerPanel, markerData, markerPct) {
			return function () {
				var label = markerData.label || "Boss mechanic";
				var details = markerData.description || markerData.details || markerData.tooltip || "";
				var text = label + " at " + Math.round(markerPct) + "%";
				if (details) {
					text = text + "\n" + details;
				}
				$.DispatchEvent("DOTAShowTextTooltip", markerPanel, text);
			};
		})(panel, marker, pct));
		panel.SetPanelEvent("onmouseout", function () {
			$.DispatchEvent("DOTAHideTextTooltip");
		});
	}
}

function ShowBossBar(args) {
	if (args.boss_count) {
		var index = GetBossBarIndex(args);
		var panels = GetBossPanels(index);
		var health = Number(args.boss_health) || 0;
		var maxHealth = Math.max(1, Number(args.boss_max_health) || 1);

		if (!panels.container || !panels.bar || !panels.fill) {
			return;
		}

		ResetBossPanels(index, panels);
		SetBossBarIdentity(index, args);
		SetBossIcon(panels, args.boss_icon);

		panels.container.style.visibility = "visible";
		panels.label.text = FormatBossName(args.boss_name);
		SetBossAnkhCount(panels, args);
		panels.health.text = FormatBossHealth(health) + " / " + FormatBossHealth(maxHealth);
		SetBossBarMarkers(panels, args.boss_bar_markers);
		SetBossHealthFill(index, panels, health, maxHealth, args, true);
		UpdateBossBarLayout();
	}
}

function UpdateBossBar(args) {
	if (args.boss_count) {
		var index = GetBossBarIndex(args);
		var panels = GetBossPanels(index);
		var health = Number(args.boss_health) || 0;
		var maxHealth = Math.max(1, Number(args.boss_max_health) || 1);

		if (!panels.health || !panels.fill) {
			return;
		}

		if (!ShouldAcceptBossBarEvent(index, args)) {
			return;
		}

		if (BossBarIdentity[index] !== (GetBossBarIdentity(args) || BossBarIdentity[index])) {
			ResetBossPanels(index, panels);
			panels.container.style.visibility = "visible";
		}
		SetBossBarIdentity(index, args);

		if (args.boss_name) {
			panels.label.text = FormatBossName(args.boss_name);
		}
		if (args.boss_icon) {
			SetBossIcon(panels, args.boss_icon);
		}
		SetBossAnkhCount(panels, args);
		panels.health.text = FormatBossHealth(health) + " / " + FormatBossHealth(maxHealth);
		SetBossBarMarkers(panels, args.boss_bar_markers);
		SetBossHealthFill(index, panels, health, maxHealth, args, false);
		UpdateBossBarLayout();
	}
}

function HideBossBar(args) {
	if (args.boss_count) {
		var index = GetBossBarIndex(args);
		var panels = GetBossPanels(index);

		if (!panels.container) {
			return;
		}

		if (!ShouldAcceptBossBarEvent(index, args)) {
			return;
		}

		ResetBossPanels(index, panels);
		UpdateBossBarLayout();
	}
}

function UpdateBossCounter(args) {
	var index = GetBossBarIndex(args);
	var panels = GetBossPanels(index);
	if (!panels.container || !panels.counter || !panels.counterLabel || !panels.counterValue) {
		return;
	}

	if (!ShouldAcceptBossBarEvent(index, args)) {
		return;
	}

	var remaining = Math.max(0, Number(args.remaining) || 0);
	var total = Math.max(1, Number(args.total) || 1);
	panels.counterLabel.text = args.label || "Ghost Revenants";
	panels.counterValue.text = remaining + " / " + total;
	panels.container.AddClass("HasBossCounter");

	panels.counter.RemoveClass("BossCounterTick");
	$.Schedule(0.03, function () {
		if (panels.counter) {
			panels.counter.AddClass("BossCounterTick");
		}
	});
	$.Schedule(0.32, function () {
		if (panels.counter) {
			panels.counter.RemoveClass("BossCounterTick");
		}
	});
}

function HideBossCounter(args) {
	var index = GetBossBarIndex(args);
	var panels = GetBossPanels(index);
	if (!ShouldAcceptBossBarEvent(index, args)) {
		return;
	}

	if (panels.container) {
		panels.container.RemoveClass("HasBossCounter");
	}
}

function UpdateBossTimer(args) {
	var index = GetBossBarIndex(args);
	var panels = GetBossPanels(index);
	if (!panels.container || !panels.timer || !panels.timerLabel || !panels.timerValue || !panels.timerFill) {
		return;
	}

	if (!ShouldAcceptBossBarEvent(index, args)) {
		return;
	}

	var remaining = Math.max(0, Number(args.remaining) || 0);
	var duration = Math.max(1, Number(args.duration) || 1);
	var ratio = Math.max(0, Math.min(1, remaining / duration));

	panels.timerLabel.text = args.label || "Timer";
	panels.timerValue.text = FormatBossTimerSeconds(remaining);
	panels.timerFill.style.width = FormatBossRatio(ratio);
	panels.container.AddClass("HasBossTimer");
	panels.container.SetHasClass("BossTimerStyleMagtheridon", args.style === "magtheridon");
	panels.container.SetHasClass("BossTimerStyleSpiritMaster", args.style === "spirit_master");
	UpdateBossBarLayout();
}

function HideBossTimer(args) {
	var index = GetBossBarIndex(args);
	var panels = GetBossPanels(index);
	if (!ShouldAcceptBossBarEvent(index, args)) {
		return;
	}

	if (panels.container) {
		panels.container.RemoveClass("HasBossTimer");
		panels.container.RemoveClass("BossTimerStyleMagtheridon");
		panels.container.RemoveClass("BossTimerStyleSpiritMaster");
	}
	if (panels.timerLabel) {
		panels.timerLabel.text = "";
	}
	if (panels.timerValue) {
		panels.timerValue.text = "";
	}
	if (panels.timerFill) {
		panels.timerFill.style.width = "0%";
	}
	UpdateBossBarLayout();
}

function GetBossCastElapsed(state) {
	var now = state.paused ? state.pausedAtTime : GetBossCastTime();
	return Math.max(0, now - state.startTime);
}

function UpdateBossCastVisual(index, panels, state) {
	var elapsed = GetBossCastElapsed(state);
	state.remaining = Math.max(0, state.duration - elapsed);
	var progress = Math.min(1, elapsed / Math.max(0.1, state.duration));

	if (panels.castTime) {
		panels.castTime.text = FormatBossCastSeconds(state.remaining);
	}
	if (panels.castFill) {
		panels.castFill.style.transitionDuration = "0s";
		panels.castFill.style.width = (progress * 100) + "%";
	}
}

function UpdateBossCastCountdown(index, serial) {
	var state = BossCastState[index];
	if (!state || state.serial !== serial) {
		return;
	}

	var panels = GetBossPanels(index);
	if (!panels.castTime) {
		return;
	}

	UpdateBossCastVisual(index, panels, state);

	if (state.remaining > 0) {
		$.Schedule(0.03, function () {
			UpdateBossCastCountdown(index, serial);
		});
	} else {
		HideBossCast(state.hideArgs || {});
	}
}

function StartBossCast(args) {
	var index = GetBossBarIndex(args);
	var panels = GetBossPanels(index);
	if (!panels.container || !panels.castBar || !panels.castLabel || !panels.castTime || !panels.castFill) {
		return;
	}

	if (!ShouldAcceptBossBarEvent(index, args)) {
		return;
	}

	var duration = Math.max(0.1, Number(args.duration) || 0.1);
	var previous = BossCastState[index] || {};
	var serial = (previous.serial || 0) + 1;
	BossCastState[index] = {
		serial: serial,
		duration: duration,
		remaining: duration,
		startTime: GetBossCastTime(),
		paused: false,
		pausedAtTime: 0,
		hideArgs: args,
	};

	panels.castLabel.text = FormatBossAbilityName(args);
	panels.castTime.text = FormatBossCastSeconds(duration);
	SetBossCastIcon(panels, args.texture);

	panels.container.AddClass("HasBossCast");
	panels.container.SetHasClass("BossCastStyleMagtheridon", args.style === "magtheridon");
	panels.container.SetHasClass("BossCastStyleBanehallow", args.style === "banehallow");
	panels.container.SetHasClass("BossCastStyleGrom", args.style === "grom");
	panels.container.SetHasClass("BossCastStyleIllidan", args.style === "illidan");
	panels.container.SetHasClass("BossCastStyleBalanar", args.style === "balanar");
	panels.container.SetHasClass("BossCastStyleProudmoore", args.style === "proudmoore");
	panels.container.SetHasClass("BossCastStyleLichKing", args.style === "lich_king");
	panels.container.SetHasClass("BossCastStyleSpiritMaster", args.style === "spirit_master");
	panels.container.SetHasClass("BossCastStyleSpiritStorm", args.style === "spirit_storm");
	panels.container.SetHasClass("BossCastStyleSpiritEarth", args.style === "spirit_earth");
	panels.container.SetHasClass("BossCastStyleSpiritFire", args.style === "spirit_fire");

	panels.castBar.RemoveClass("BossCastEntering");
	panels.castBar.AddClass("BossCastEntering");
	panels.castFill.style.transitionDuration = "0s";
	panels.castFill.style.width = "0%";

	$.Schedule(0.03, function () {
		var state = BossCastState[index];
		if (!state || state.serial !== serial || !panels.castFill) {
			return;
		}

		UpdateBossCastCountdown(index, serial);
	});

	UpdateBossBarLayout();
}

function HideBossCast(args) {
	var index = GetBossBarIndex(args);
	var panels = GetBossPanels(index);
	if (!ShouldAcceptBossBarEvent(index, args)) {
		return;
	}

	var previous = BossCastState[index] || {};
	BossCastState[index] = {
		serial: (previous.serial || 0) + 1,
		remaining: 0,
	};

	if (panels.container) {
		panels.container.RemoveClass("HasBossCast");
		panels.container.RemoveClass("BossCastStyleMagtheridon");
		panels.container.RemoveClass("BossCastStyleBanehallow");
		panels.container.RemoveClass("BossCastStyleGrom");
		panels.container.RemoveClass("BossCastStyleIllidan");
		panels.container.RemoveClass("BossCastStyleBalanar");
		panels.container.RemoveClass("BossCastStyleProudmoore");
		panels.container.RemoveClass("BossCastStyleLichKing");
		panels.container.RemoveClass("BossCastStyleSpiritMaster");
		panels.container.RemoveClass("BossCastStyleSpiritStorm");
		panels.container.RemoveClass("BossCastStyleSpiritEarth");
		panels.container.RemoveClass("BossCastStyleSpiritFire");
	}
	if (panels.castLabel) {
		panels.castLabel.text = "";
	}
	if (panels.castTime) {
		panels.castTime.text = "";
	}
	if (panels.castFill) {
		panels.castFill.style.transitionDuration = "0s";
		panels.castFill.style.width = "0%";
	}
	SetBossCastIcon(panels, null);
	UpdateBossBarLayout();
}

function OnGamePauseState(args) {
	var paused = args && (args.paused === true || Number(args.paused) === 1);
	var now = GetBossCastTime();

	for (var index = 1; index <= MAX_BOSS_BARS; index++) {
		var state = BossCastState[index];
		if (!state || !state.duration || state.remaining <= 0) {
			continue;
		}

		if (paused) {
			if (!state.paused) {
				state.paused = true;
				state.pausedAtTime = now;
			}
		} else if (state.paused) {
			state.startTime += Math.max(0, now - state.pausedAtTime);
			state.paused = false;
			state.pausedAtTime = 0;
		}

		UpdateBossCastVisual(index, GetBossPanels(index), state);
	}
}

(function () {
	GameEvents.Subscribe("show_boss_hp", ShowBossBar);
	GameEvents.Subscribe("update_boss_hp", UpdateBossBar);
	GameEvents.Subscribe("hide_boss_hp", HideBossBar);
	GameEvents.Subscribe("xhs_boss_counter_update", UpdateBossCounter);
	GameEvents.Subscribe("xhs_boss_counter_hide", HideBossCounter);
	GameEvents.Subscribe("xhs_boss_timer_update", UpdateBossTimer);
	GameEvents.Subscribe("xhs_boss_timer_hide", HideBossTimer);
	GameEvents.Subscribe("xhs_boss_cast_start", StartBossCast);
	GameEvents.Subscribe("xhs_boss_cast_hide", HideBossCast);
	GameEvents.Subscribe("xhs_game_pause_state", OnGamePauseState);
})();
