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

function TimerCreepLevel(data)
{
	var timerText = "";
	timerText += data.timer_minute_10;
	timerText += data.timer_minute_01;
	timerText += ":";
	timerText += data.timer_second_10;
	timerText += data.timer_second_01;

	$("#CreepLevelTimer").text = timerText;
}

function TimerSpecialArena(data)
{
	var timerText = "";
	timerText += data.timer_minute_10;
	timerText += data.timer_minute_01;
	timerText += ":";
	timerText += data.timer_second_10;
	timerText += data.timer_second_01;

	$("#SpecialArenaTimer").text = timerText;
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

function ShowTimerBar() {
	$("#TimerPanels").style.visibility = "visible";
}

function ShowTimerSpecialArena() {
	$("#SpecialArena").style.visibility = "visible";
}

function ShowTimerHeroImage() {
	$("#HeroImage").style.visibility = "visible";
}

function ShowTimerSpiritBeast() {
	$("#SpiritBeast").style.visibility = "visible";
}

function ShowTimerFrostInfernal() {
	$("#FrostInfernal").style.visibility = "visible";
}

function ShowTimerAllHeroImage() {
	$("#AllHeroImage").style.visibility = "visible";
}

function HideTimerSpecialArena() {
	$("#SpecialArena").style.visibility = "collapse";
}

function HideTimerHeroImage() {
	$("#HeroImage").style.visibility = "collapse";
}

function HideTimerSpiritBeast() {
	$("#SpiritBeast").style.visibility = "collapse";
}

function HideTimerFrostInfernal() {
	$("#FrostInfernal").style.visibility = "collapse";
}

function HideTimerAllHeroImage() {
	$("#AllHeroImage").style.visibility = "collapse";
}

function SpecialEventLabelFarm() {
	$("#SpecialEventsLabel").text = "FARM EVENT:";
}

function SpecialEventLabelFinal() {
	$("#SpecialEventsLabel").text = "FINAL WAVE:";
}

(function()
{
	GameEvents.Subscribe("timer_game", GameTimer);
	GameEvents.Subscribe("timer_special_event", TimerSpecialEvents);
	GameEvents.Subscribe("timer_incoming_wave", TimerIncomingWave);
	GameEvents.Subscribe("timer_creep_level", TimerCreepLevel);
	GameEvents.Subscribe("timer_special_arena", TimerSpecialArena);
	GameEvents.Subscribe("timer_hero_image", TimerHeroImage);
	GameEvents.Subscribe("timer_spirit_beast", TimerSpiritBeastHeroImage);
	GameEvents.Subscribe("timer_frost_infernal", TimerFrostInfernalHeroImage);
	GameEvents.Subscribe("timer_all_hero_image", TimerAllHeroImage);
	GameEvents.Subscribe("show_timer_bar", ShowTimerBar);
	GameEvents.Subscribe("show_timer_special_arena", ShowTimerSpecialArena);
	GameEvents.Subscribe("show_timer_hero_image", ShowTimerHeroImage);
	GameEvents.Subscribe("show_timer_spirit_beast", ShowTimerSpiritBeast);
	GameEvents.Subscribe("show_timer_frost_infernal", ShowTimerFrostInfernal);
	GameEvents.Subscribe("show_timer_all_hero_image", ShowTimerAllHeroImage);
	GameEvents.Subscribe("hide_timer_special_arena", HideTimerSpecialArena);
	GameEvents.Subscribe("hide_timer_hero_image", HideTimerHeroImage);
	GameEvents.Subscribe("hide_timer_spirit_beast", HideTimerSpiritBeast);
	GameEvents.Subscribe("hide_timer_frost_infernal", HideTimerFrostInfernal);
	GameEvents.Subscribe("hide_timer_all_hero_image", HideTimerAllHeroImage);
	GameEvents.Subscribe("update_special_event_label_farm", SpecialEventLabelFarm);
	GameEvents.Subscribe("update_special_event_label_final", SpecialEventLabelFinal);
})();
