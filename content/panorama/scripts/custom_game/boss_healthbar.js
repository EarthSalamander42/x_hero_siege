"use strict";

function GetBossPanels(index) {
	return {
		container: $("#BossHP" + index),
		label: $("#BossLabel" + index),
		level: $("#BossLevel" + index),
		icon: $("#BossIcon" + index),
		health: $("#BossHealth" + index),
		bar: $("#BossProgressBar" + index),
		barLeft: $("#BossProgressBar" + index + "_Left"),
	};
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

function ShowBossBar(args) {
	if (args.boss_count) {
		var panels = GetBossPanels(args.boss_count);

		if (!panels.container || !panels.bar) {
			return;
		}

		if (panels.icon && args.boss_icon) {
			panels.icon.style.backgroundImage = 'url("file://{images}/heroes/icons/' + args.boss_icon + '.png")';
		}

		panels.container.style.visibility = "visible";
		panels.label.text = $.Localize("#" + args.boss_name);
		panels.level.text = "Level " + args.difficulty;
		panels.health.text = FormatBossHealth(args.boss_health) + " / " + FormatBossHealth(args.boss_max_health);
		panels.bar.value = Math.max(0, Math.min(1, args.boss_health / args.boss_max_health));

		if (panels.barLeft && args.dark_color && args.light_color) {
			panels.barLeft.style.backgroundColor = "gradient( linear, 0% 0%, 100% 0%, from( " + args.dark_color + " ), color-stop( 0.55, " + args.light_color + " ), to( #ffffff ) )";
		}
	}
}

function UpdateBossBar(args) {
	if (args.boss_count) {
		var panels = GetBossPanels(args.boss_count);

		if (!panels.health || !panels.bar) {
			return;
		}

		panels.health.text = FormatBossHealth(args.boss_health) + " / " + FormatBossHealth(args.boss_max_health);
		panels.bar.value = Math.max(0, Math.min(1, args.boss_health / args.boss_max_health));
	}
}

function HideBossBar(args) {
	if (args.boss_count) {
		var panels = GetBossPanels(args.boss_count);

		if (!panels.container) {
			return;
		}

		panels.container.style.visibility = "collapse";
		panels.label.text = "";
		panels.level.text = "";
		panels.icon.style.backgroundImage = "none";
		panels.health.text = "";
		panels.bar.value = 1;
	}
}

(function () {
	GameEvents.Subscribe("show_boss_hp", ShowBossBar);
	GameEvents.Subscribe("update_boss_hp", UpdateBossBar);
	GameEvents.Subscribe("hide_boss_hp", HideBossBar);
})();
