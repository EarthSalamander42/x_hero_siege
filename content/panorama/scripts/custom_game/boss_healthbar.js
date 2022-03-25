"use strict";

function ShowBossBar(args) {
	if (args.boss_count) {
		var boss_icon = $("#BossIcon" + args.boss_count);
		boss_icon.style.backgroundImage = 'url("file://{images}/heroes/icons/' + args.boss_icon + '.png")';
		boss_icon.style.backgroundRepeat = "no-repeat";
		boss_icon.style.backgroundPosition = "50% 0%";
		boss_icon.style.backgroundSize = "90% 90%";
		boss_icon.style.zIndex = "10";

		$("#BossHP" + args.boss_count).style.visibility = "visible";
		$("#BossLabel" + args.boss_count).text = $.Localize("#" + args.boss_name);
		$("#BossLevel" + args.boss_count).text = "Level: " + args.difficulty;
		$("#BossHealth" + args.boss_count).text = args.boss_health + " / " + args.boss_max_health;
		$("#BossProgressBar" + args.boss_count).value = args.boss_health / args.boss_max_health;
		$("#BossProgressBar" + args.boss_count + "_Left").style.backgroundColor = "gradient( linear, 0% 0%, 0% 100%, from( " + args.dark_color + " ), color-stop( 0.3, " + args.light_color + " ), color-stop( .5, " + args.light_color + " ), to( " + args.dark_color + " ) )";
	}
}

function UpdateBossBar(args) {
	if (args.boss_count) {
		$("#BossHealth" + args.boss_count).text = args.boss_health + " / " + args.boss_max_health;
		$("#BossProgressBar" + args.boss_count).value = args.boss_health / args.boss_max_health;
		$("#BossProgressBar" + args.boss_count + "_Left").style.backgroundColor = "gradient( linear, 0% 0%, 0% 100%, from( " + args.dark_color + " ), color-stop( 0.3, " + args.light_color + " ), color-stop( .5, " + args.light_color + " ), to( " + args.dark_color + " ) )";
	}
}

function HideBossBar(args) {
	if (args.boss_count) {
		$("#BossHP" + args.boss_count).style.visibility = "collapse";
		$("#BossLabel" + args.boss_count).text = "";
		$("#BossIcon" + args.boss_count).style.backgroundImage = '';
		$("#BossHealth" + args.boss_count).text = "";
		$("#BossProgressBar" + args.boss_count).value = 100;
		$("#BossProgressBar" + args.boss_count + "_Left").style.backgroundColor = "gradient( linear, 0% 0%, 0% 100%, from( #320000 ), color-stop( 0.3, #a30f0f ), color-stop( .5, #a30f0f ), to( #320000 ) )";
	}
}

(function () {
	GameEvents.Subscribe("show_boss_hp", ShowBossBar);
	GameEvents.Subscribe("update_boss_hp", UpdateBossBar);
	GameEvents.Subscribe("hide_boss_hp", HideBossBar);
})();
