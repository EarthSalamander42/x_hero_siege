"use strict";

function ShowBossBar(args) {
//	$.Msg(args)

	$("#BossHP").style.visibility = "visible";
	$("#BossLabel").text = $.Localize(args.boss_name);
	$("#BossLevel").text = "Level: " + args.difficulty;
	$("#BossIcon").heroname = args.boss_icon;
	$("#BossHealth").text = args.boss_health + " / " + args.boss_max_health;
	$("#BossProgressBar").value = args.boss_health / args.boss_max_health;
	$("#BossProgressBar_Left").style.backgroundColor = "gradient( linear, 0% 0%, 0% 100%, from( " + args.light_color + " ), color-stop( 0.3, " + args.dark_color + " ), color-stop( .5, " + args.dark_color + " ), to( " + args.light_color + " ) )";
}

function HideBossBar(args) {
	$("#BossHP").style.visibility = "collapse";
	$("#BossLabel").text = "";
	$("#BossIcon").heroname = "";
	$("#BossHealth").text = "";
	$("#BossProgressBar").value = 100;
	$("#BossProgressBar_Left").style.backgroundColor = "gradient( linear, 0% 0%, 0% 100%, from( #320000 ), color-stop( 0.3, #a30f0f ), color-stop( .5, #a30f0f ), to( #320000 ) )";
}

(function () {
	GameEvents.Subscribe("show_boss_hp", ShowBossBar);
	GameEvents.Subscribe("hide_boss_hp", HideBossBar);
})();
