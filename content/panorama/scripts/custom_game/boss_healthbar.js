"use strict";

var BossBarState = {};
var BossBarIdentity = {};
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
	};
}

function SetBossIcon(panels, bossIcon) {
	if (!panels || !panels.icon || !panels.iconImage) {
		return;
	}

	var imagePath = bossIcon ? "file://{images}/heroes/" + bossIcon + ".png" : "";
	panels.icon.style.backgroundImage = "none";
	panels.iconImage.SetImage("");
	panels.iconImage.style.visibility = "collapse";

	if (!imagePath) {
		return;
	}

	panels.iconImage.SetImage(imagePath);
	panels.iconImage.style.visibility = "visible";
}

function GetBossBarIndex(args) {
	return Number(args && args.boss_count) || 1;
}

function GetBossBarIdentity(args) {
	if (!args || args.boss_bar_id === undefined || args.boss_bar_id === null || args.boss_bar_id === "") {
		return null;
	}

	return String(args.boss_bar_id);
}

function ShouldAcceptBossBarEvent(index, args) {
	var identity = GetBossBarIdentity(args);
	if (!identity || !BossBarIdentity[index]) {
		return true;
	}

	return BossBarIdentity[index] === identity;
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
		root.SetHasClass("MultiBossBars", visibleCount > 1);
		root.SetHasClass("ThreeBossBars", visibleCount === 3);
	}

	if (visibleCount === 3 && visiblePanels[2]) {
		visiblePanels[2].SetHasClass("CenteredBossBar", true);
	}
}

function ResetBossPanels(index, panels) {
	if (!panels || !panels.container) {
		return;
	}

	panels.container.style.visibility = "collapse";
	panels.container.RemoveClass("HasBossCounter");
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
	SetBossBarMarkers(panels, null);

	delete BossBarState[index];
	delete BossBarIdentity[index];
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
				$.DispatchEvent("DOTAShowTextTooltip", markerPanel, label + " at " + markerPct + "%");
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
		BossBarIdentity[index] = GetBossBarIdentity(args) || "slot_" + index;
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

(function () {
	GameEvents.Subscribe("show_boss_hp", ShowBossBar);
	GameEvents.Subscribe("update_boss_hp", UpdateBossBar);
	GameEvents.Subscribe("hide_boss_hp", HideBossBar);
	GameEvents.Subscribe("xhs_boss_counter_update", UpdateBossCounter);
	GameEvents.Subscribe("xhs_boss_counter_hide", HideBossCounter);
})();
