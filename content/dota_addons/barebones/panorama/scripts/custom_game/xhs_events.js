"use strict";

function OnShowEvents()
{
	$("#EventPanel").SetHasClass("HidePanel", !$("#EventPanel").BHasClass("HidePanel"));
}

function HeroImage()
{
	var ID = Players.GetLocalPlayer()
	GameEvents.SendCustomGameEventToServer("event_hero_image", {pID: ID});
}

function AllHeroImages()
{
	var ID = Players.GetLocalPlayer()
	GameEvents.SendCustomGameEventToServer("event_all_hero_images", {pID: ID});
}

function SpiritBeast()
{
	var ID = Players.GetLocalPlayer()
	GameEvents.SendCustomGameEventToServer("event_spirit_beast", {pID: ID});
}

function FrostInfernal()
{
	var ID = Players.GetLocalPlayer()
	GameEvents.SendCustomGameEventToServer("event_frost_infernal", {pID: ID});
}

function OnQuit()
{
	var ID = Players.GetLocalPlayer()
	$("#EventPanel").SetHasClass("HidePanel", !$("#EventPanel").BHasClass("HidePanel"));
	GameEvents.SendCustomGameEventToServer("quit_event", {pID: ID});
}

//	function ShowDuel()
//	{
//		$("#Duel_info").visible = true;
//	}

(function()
{
	GameEvents.Subscribe("show_events", OnShowEvents);
	GameEvents.Subscribe("quit_events", OnQuit);
})();
