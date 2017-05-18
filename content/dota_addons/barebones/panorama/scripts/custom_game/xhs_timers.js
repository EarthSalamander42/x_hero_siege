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
	timerText += data.timer_minute_10;
	timerText += data.timer_minute_01;
	timerText += ":";
	timerText += data.timer_second_10;
	timerText += data.timer_second_01;

	$("#CreepTimer").text = timerText;
}

function UpdateTimerIncomingWave(data)
{
	var timerText = "";
	timerText += data.timer_minute_10;
	timerText += data.timer_minute_01;
	timerText += ":";
	timerText += data.timer_second_10;
	timerText += data.timer_second_01;

	$("#IncomingWaveTimer").text = timerText;
}

function UpdateTimerSpecialEvents(data)
{
	var timerText = "";
	timerText += data.timer_minute_10;
	timerText += data.timer_minute_01;
	timerText += ":";
	timerText += data.timer_second_10;
	timerText += data.timer_second_01;

	$("#SpecialEventsTimer").text = timerText;
}

function UpdateGameTimer(data)
{
	var timerText = "";
	timerText += data.timer_minute_10;
	timerText += data.timer_minute_01;
	timerText += ":";
	timerText += data.timer_second_10;
	timerText += data.timer_second_01;

	$("#GameTimer").text = timerText;
}

function ShowTimer(data)	// if Map is X Hero Siege then
{
	$("#Timer").AddClass("timer_visible");
	$("#ScoreboardLeft_Parent").visible = true;
}

function HideTimer(data)
{
//	$("#Timer").AddClass("timer_visible");
	$("#ScoreboardLeft_Parent").visible = false;
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
	GameEvents.Subscribe("gametimer", UpdateGameTimer);
	GameEvents.Subscribe("show_timer", ShowTimer);
	GameEvents.Subscribe("hide_timer", HideTimer);
})();
