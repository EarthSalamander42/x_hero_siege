"use strict";

function OnMouseOut()
{
	$.GetContextPanel().SetHasClass("AdminMod", false);
	$.GetContextPanel().SetHasClass("CGSRadio", false);
	$.GetContextPanel().SetHasClass("PlayerCommandsBox", false);
	$("#CreditsBorder").visible = false
	$("#AdminMod").SetHasClass("HidePanel", !$("#AdminMod").BHasClass("HidePanel"));
}

function OnMouseOver()
{
	$.GetContextPanel().SetHasClass("AdminMod", true);
	$("#CreditsBorder").visible = true
	$("#AdminMod").SetHasClass("HidePanel", !$("#AdminMod").BHasClass("HidePanel"));
}

function OnBuyTomeCommand()
{
//	var hero = Players.GetLocalPlayer()
}

function ToggleDualHero()
{
	var ID = Players.GetLocalPlayer()
	GameEvents.SendCustomGameEventToServer("toggle_dual_hero", {pID: ID});
}

function ShowDualButton(data)
{
	$("#DualHeroText").visible = true;
	$("#DualHero").visible = true;
}

(function()
{
	GameEvents.Subscribe("show_dual", ShowDualButton);
})();