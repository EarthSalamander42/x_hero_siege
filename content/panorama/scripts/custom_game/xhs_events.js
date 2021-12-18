"use strict";

function OnShowEvents()
{
	$.GetContextPanel().FindChildTraverse("EventPanel").style.visibility = "visible";
	$.Msg("Menu: Show")
}

function HeroImage()
{
	var ID = Players.GetLocalPlayer()
	GameEvents.SendCustomGameEventToServer("event_hero_image", {pID: ID});
	$.Msg("Menu: Hero Image")
}

function AllHeroImages()
{
	var ID = Players.GetLocalPlayer()
	GameEvents.SendCustomGameEventToServer("event_all_hero_images", {pID: ID});
	$.Msg("Menu: All Hero Images")
}

function SpiritBeast()
{
	var ID = Players.GetLocalPlayer()
	GameEvents.SendCustomGameEventToServer("event_spirit_beast", {pID: ID});
	$.Msg("Menu: Spirit Beast")
}

function FrostInfernal()
{
	var ID = Players.GetLocalPlayer()
	GameEvents.SendCustomGameEventToServer("event_frost_infernal", {pID: ID});
	$.Msg("Menu: Frost Infernal")
}

function OnQuit()
{
	var ID = Players.GetLocalPlayer()
	$.GetContextPanel().FindChildTraverse("EventPanel").style.visibility = "collapse";
	GameEvents.SendCustomGameEventToServer("quit_event", {pID: ID});
	$.Msg("Menu: Hide")
}

(function()
{
	GameEvents.Subscribe("show_events", OnShowEvents);
	GameEvents.Subscribe("quit_events", OnQuit);
})();
