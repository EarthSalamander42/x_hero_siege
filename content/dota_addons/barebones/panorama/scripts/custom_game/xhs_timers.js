"use strict";

function UpdateTimerMuradin(data)
{
	var timerText = "";
	timerText += data.timer_minute_10;
	timerText += data.timer_minute_01;
	timerText += ":";
	timerText += data.timer_second_10;
	timerText += data.timer_second_01;

	$("#Timer").text = timerText;
}

function UpdateTimerCreep(data)
{
	var timerText = "";
	timerText += data.timer_minute_10_2;
	timerText += data.timer_minute_01_2;
	timerText += ":";
	timerText += data.timer_second_10_2;
	timerText += data.timer_second_01_2;

	$("#CreepTimer").text = timerText;
}

function UpdateTimerIncomingWave(data)
{
	var timerText3 = "";
	timerText3 += data.timer_minute_10_3;
	timerText3 += data.timer_minute_01_3;
	timerText3 += ":";
	timerText3 += data.timer_second_10_3;
	timerText3 += data.timer_second_01_3;

	$("#IncomingWaveTimer").text = timerText3;
}

function UpdateTimerSpecialEvents(data)
{
	var timerText3 = "";
	timerText3 += data.timer_minute_10_3;
	timerText3 += data.timer_minute_01_3;
	timerText3 += ":";
	timerText3 += data.timer_second_10_3;
	timerText3 += data.timer_second_01_3;

	$("#SpecialEventsTimer").text = timerText3;
}

function ShowTimer(data)	// if Map is X Hero Siege then
{
	$("#Timer").AddClass("timer_visible");
	GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_BAR_SCORE, false);
	GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_BAR_DIRE_TEAM, false);
	$("#ScoreboardLeft_Parent").visible = true;
}

function OnGameStateChanged(table, key, data)
{
	$.Msg("Table '", table, "' changed: '", key, "' = ", data);
}

$.Schedule(0.025, visibleSwitch);
function visibleSwitch()
{
	$("#ScoreboardLeft_Parent").visible = false;
}

(function()
{
	// We use a nettable to communicate victory conditions to make sure we get the value regardless of timing.
	CustomNetTables.SubscribeNetTableListener("game_state", OnGameStateChanged);

	GameEvents.Subscribe("incomingwavecountdown", UpdateTimerSpecialEvents);
	GameEvents.Subscribe("specialeventscountdown", UpdateTimerIncomingWave);
	GameEvents.Subscribe("creepcountdown", UpdateTimerCreep);
	GameEvents.Subscribe("countdown", UpdateTimerMuradin);
	GameEvents.Subscribe("show_timer", ShowTimer);
})();
