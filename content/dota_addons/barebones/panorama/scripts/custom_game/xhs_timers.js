"use strict";

function GameTimer(data)
{
	var timerText = "";
	timerText += data.timer_minute_10;
	timerText += data.timer_minute_01;
	timerText += ":";
	timerText += data.timer_second_10;
	timerText += data.timer_second_01;

	$("#GameTimer").text = timerText;
}

function TimerSpecialEvents(data)
{
	var timerText = "";
	timerText += data.timer_minute_10;
	timerText += data.timer_minute_01;
	timerText += ":";
	timerText += data.timer_second_10;
	timerText += data.timer_second_01;

	$("#SpecialEventsTimer").text = timerText;
}

function TimerIncomingWave(data)
{
	var timerText = "";
	timerText += data.timer_minute_10;
	timerText += data.timer_minute_01;
	timerText += ":";
	timerText += data.timer_second_10;
	timerText += data.timer_second_01;

	$("#IncomingWaveTimer").text = timerText;
}

function TimerHeroImage(data)
{
	var timerText = "";
	timerText += data.timer_minute_10;
	timerText += data.timer_minute_01;
	timerText += ":";
	timerText += data.timer_second_10;
	timerText += data.timer_second_01;

	$("#HeroImageTimer").text = timerText;
}

function TimerSpiritBeastHeroImage(data)
{
	var timerText = "";
	timerText += data.timer_minute_10;
	timerText += data.timer_minute_01;
	timerText += ":";
	timerText += data.timer_second_10;
	timerText += data.timer_second_01;

	$("#SpiritBeastTimer").text = timerText;
}

function TimerFrostInfernalHeroImage(data)
{
	var timerText = "";
	timerText += data.timer_minute_10;
	timerText += data.timer_minute_01;
	timerText += ":";
	timerText += data.timer_second_10;
	timerText += data.timer_second_01;

	$("#FrostInfernalTimer").text = timerText;
}

function TimerAllHeroImage(data)
{
	var timerText = "";
	timerText += data.timer_minute_10;
	timerText += data.timer_minute_01;
	timerText += ":";
	timerText += data.timer_second_10;
	timerText += data.timer_second_01;

	$("#AllHeroImageTimer").text = timerText;
}

function ShowTimer(data)
{
//	$("#ScoreboardLeft_Parent").style.visibility = "visible";
}

function OnGameStateChanged(table, key, data)
{
	$.Msg("Table '", table, "' changed: '", key, "' = ", data);
}

(function()
{
	// We use a nettable to communicate victory conditions to make sure we get the value regardless of timing.
	CustomNetTables.SubscribeNetTableListener("game_state", OnGameStateChanged);

	GameEvents.Subscribe("timer_game", GameTimer);
	GameEvents.Subscribe("timer_incoming_wave", TimerIncomingWave);
	GameEvents.Subscribe("timer_special_event", TimerSpecialEvents);
	GameEvents.Subscribe("timer_hero_image", TimerHeroImage);
	GameEvents.Subscribe("timer_spirit_beast", TimerSpiritBeastHeroImage);
	GameEvents.Subscribe("timer_frost_infernal", TimerFrostInfernalHeroImage);
	GameEvents.Subscribe("timer_all_hero_image", TimerAllHeroImage);
	GameEvents.Subscribe("show_timer", ShowTimer);

	$("#HeroImage").style.visibility = "collapse";
	$("#SpiritBeast").style.visibility = "collapse";
	$("#FrostInfernal").style.visibility = "collapse";
	$("#AllHeroImage").style.visibility = "collapse";
})();
