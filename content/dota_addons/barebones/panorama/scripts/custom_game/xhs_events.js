"use strict";

function OnShowEvents()
{
	$.GetContextPanel().FindChildTraverse("EventPanel").style.visibility = "visible";
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
	$.GetContextPanel().FindChildTraverse("EventPanel").style.visibility = "collapse";
	GameEvents.SendCustomGameEventToServer("quit_event", {pID: ID});
}

(function()
{
	GameEvents.Subscribe("show_events", OnShowEvents);
	GameEvents.Subscribe("quit_events", OnQuit);
})();
