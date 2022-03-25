function OnShowEvents() {
	$.GetContextPanel().FindChildTraverse("EventPanel").style.visibility = "visible";
}

function HeroImage() {
	GameEvents.SendCustomGameEventToServer("event_hero_image", {pID: Players.GetLocalPlayer()});
}

function AllHeroImages() {
	GameEvents.SendCustomGameEventToServer("event_all_hero_images", {pID: Players.GetLocalPlayer()});
}

function SpiritBeast() {
	GameEvents.SendCustomGameEventToServer("event_spirit_beast", {pID: Players.GetLocalPlayer()});
}

function FrostInfernal() {
	GameEvents.SendCustomGameEventToServer("event_frost_infernal", {pID: Players.GetLocalPlayer()});
}

function OnQuit() {
	$.GetContextPanel().FindChildTraverse("EventPanel").style.visibility = "collapse";
	GameEvents.SendCustomGameEventToServer("quit_event", {pID: Players.GetLocalPlayer()});
}

(function() {
	GameEvents.Subscribe("show_events", OnShowEvents);
	GameEvents.Subscribe("quit_events", OnQuit);
})();
