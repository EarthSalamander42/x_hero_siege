"use strict";

var QuestButtonPressed = false;
var Quest1ButtonPressed = false;

function OnShowQuests()
{
	if (QuestButtonPressed) {
		QuestButtonPressed = false;
		$.GetContextPanel().FindChildTraverse("Quest1").style.visibility = "collapse";
		$.GetContextPanel().FindChildTraverse("Quest2").style.visibility = "collapse";
		$.GetContextPanel().FindChildTraverse("Quest3").style.visibility = "collapse";
		$.GetContextPanel().FindChildTraverse("Quest4").style.visibility = "collapse";
		$.GetContextPanel().FindChildTraverse("Quest5").style.visibility = "collapse";
	} else {
		QuestButtonPressed = true;
		$.GetContextPanel().FindChildTraverse("Quest1").style.visibility = "visible";
		$.GetContextPanel().FindChildTraverse("Quest2").style.visibility = "visible";
		$.GetContextPanel().FindChildTraverse("Quest3").style.visibility = "visible";
		$.GetContextPanel().FindChildTraverse("Quest4").style.visibility = "visible";
		$.GetContextPanel().FindChildTraverse("Quest5").style.visibility = "visible";
	};
}

function OnShowQuest1()
{
	if (Quest1ButtonPressed) {
		Quest1ButtonPressed = false;
		$.GetContextPanel().FindChildTraverse("ShowQuests").style.visibility = "visible";
		$.GetContextPanel().FindChildTraverse("Quest2").style.visibility = "visible";
		$.GetContextPanel().FindChildTraverse("Quest3").style.visibility = "visible";
		$.GetContextPanel().FindChildTraverse("Quest4").style.visibility = "visible";
		$.GetContextPanel().FindChildTraverse("Quest5").style.visibility = "visible";
		$.GetContextPanel().FindChildTraverse("Quest1_Info").style.visibility = "collapse";
	} else {
		Quest1ButtonPressed = true;
		$.GetContextPanel().FindChildTraverse("ShowQuests").style.visibility = "collapse";
		$.GetContextPanel().FindChildTraverse("Quest2").style.visibility = "collapse";
		$.GetContextPanel().FindChildTraverse("Quest3").style.visibility = "collapse";
		$.GetContextPanel().FindChildTraverse("Quest4").style.visibility = "collapse";
		$.GetContextPanel().FindChildTraverse("Quest5").style.visibility = "collapse";
		$.GetContextPanel().FindChildTraverse("Quest1_Info").style.visibility = "visible";
	};
}

function OnShowQuest2()
{
	if (Quest1ButtonPressed) {
		Quest1ButtonPressed = false;
		$.GetContextPanel().FindChildTraverse("ShowQuests").style.visibility = "visible";
		$.GetContextPanel().FindChildTraverse("Quest1").style.visibility = "visible";
		$.GetContextPanel().FindChildTraverse("Quest3").style.visibility = "visible";
		$.GetContextPanel().FindChildTraverse("Quest4").style.visibility = "visible";
		$.GetContextPanel().FindChildTraverse("Quest5").style.visibility = "visible";
		$.GetContextPanel().FindChildTraverse("Quest2_Info").style.visibility = "collapse";
	} else {
		Quest1ButtonPressed = true;
		$.GetContextPanel().FindChildTraverse("ShowQuests").style.visibility = "collapse";
		$.GetContextPanel().FindChildTraverse("Quest1").style.visibility = "collapse";
		$.GetContextPanel().FindChildTraverse("Quest3").style.visibility = "collapse";
		$.GetContextPanel().FindChildTraverse("Quest4").style.visibility = "collapse";
		$.GetContextPanel().FindChildTraverse("Quest5").style.visibility = "collapse";
		$.GetContextPanel().FindChildTraverse("Quest2_Info").style.visibility = "visible";
	};
}

function OnShowQuest3()
{
	if (Quest1ButtonPressed) {
		Quest1ButtonPressed = false;
		$.GetContextPanel().FindChildTraverse("ShowQuests").style.visibility = "visible";
		$.GetContextPanel().FindChildTraverse("Quest1").style.visibility = "visible";
		$.GetContextPanel().FindChildTraverse("Quest2").style.visibility = "visible";
		$.GetContextPanel().FindChildTraverse("Quest4").style.visibility = "visible";
		$.GetContextPanel().FindChildTraverse("Quest5").style.visibility = "visible";
		$.GetContextPanel().FindChildTraverse("Quest3_Info").style.visibility = "collapse";
	} else {
		Quest1ButtonPressed = true;
		$.GetContextPanel().FindChildTraverse("ShowQuests").style.visibility = "collapse";
		$.GetContextPanel().FindChildTraverse("Quest1").style.visibility = "collapse";
		$.GetContextPanel().FindChildTraverse("Quest2").style.visibility = "collapse";
		$.GetContextPanel().FindChildTraverse("Quest4").style.visibility = "collapse";
		$.GetContextPanel().FindChildTraverse("Quest5").style.visibility = "collapse";
		$.GetContextPanel().FindChildTraverse("Quest3_Info").style.visibility = "visible";
	};
}

function OnShowQuest4()
{
	if (Quest1ButtonPressed) {
		Quest1ButtonPressed = false;
		$.GetContextPanel().FindChildTraverse("ShowQuests").style.visibility = "visible";
		$.GetContextPanel().FindChildTraverse("Quest1").style.visibility = "visible";
		$.GetContextPanel().FindChildTraverse("Quest2").style.visibility = "visible";
		$.GetContextPanel().FindChildTraverse("Quest3").style.visibility = "visible";
		$.GetContextPanel().FindChildTraverse("Quest5").style.visibility = "visible";
		$.GetContextPanel().FindChildTraverse("Quest4_Info").style.visibility = "collapse";
	} else {
		Quest1ButtonPressed = true;
		$.GetContextPanel().FindChildTraverse("ShowQuests").style.visibility = "collapse";
		$.GetContextPanel().FindChildTraverse("Quest1").style.visibility = "collapse";
		$.GetContextPanel().FindChildTraverse("Quest2").style.visibility = "collapse";
		$.GetContextPanel().FindChildTraverse("Quest3").style.visibility = "collapse";
		$.GetContextPanel().FindChildTraverse("Quest5").style.visibility = "collapse";
		$.GetContextPanel().FindChildTraverse("Quest4_Info").style.visibility = "visible";
	};
}

function OnShowQuest5()
{
	if (Quest1ButtonPressed) {
		Quest1ButtonPressed = false;
		$.GetContextPanel().FindChildTraverse("ShowQuests").style.visibility = "visible";
		$.GetContextPanel().FindChildTraverse("Quest1").style.visibility = "visible";
		$.GetContextPanel().FindChildTraverse("Quest2").style.visibility = "visible";
		$.GetContextPanel().FindChildTraverse("Quest3").style.visibility = "visible";
		$.GetContextPanel().FindChildTraverse("Quest4").style.visibility = "visible";
		$.GetContextPanel().FindChildTraverse("Quest5_info").style.visibility = "collapse";
	} else {
		Quest1ButtonPressed = true;
		$.GetContextPanel().FindChildTraverse("ShowQuests").style.visibility = "collapse";
		$.GetContextPanel().FindChildTraverse("Quest1").style.visibility = "collapse";
		$.GetContextPanel().FindChildTraverse("Quest2").style.visibility = "collapse";
		$.GetContextPanel().FindChildTraverse("Quest3").style.visibility = "collapse";
		$.GetContextPanel().FindChildTraverse("Quest4").style.visibility = "collapse";
		$.GetContextPanel().FindChildTraverse("Quest5_info").style.visibility = "visible";
	};
}

function ShowDuel()
{
	$("#Duel_info").visible = true;
}

(function()
{
	GameEvents.Subscribe("show_duel", ShowDuel);
})();
