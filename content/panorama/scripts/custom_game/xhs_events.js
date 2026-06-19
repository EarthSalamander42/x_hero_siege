function GetEventPanel() {
	return $.GetContextPanel().FindChildTraverse("EventPanel");
}

function SetEventsVisible(visible) {
	var panel = GetEventPanel();

	if (!panel) {
		return;
	}

	panel.SetHasClass("XHSEventsPanelVisible", visible);
}

function OnShowEvents() {
	SetEventsVisible(true);
}

function SelectEvent(eventName) {
	GameEvents.SendCustomGameEventToServer(eventName, {
		pID: Players.GetLocalPlayer()
	});

	SetEventsVisible(false);
}

function HeroImage() {
	SelectEvent("event_hero_image");
}

function AllHeroImages() {
	SelectEvent("event_all_hero_images");
}

function SpiritBeast() {
	SelectEvent("event_spirit_beast");
}

function FrostInfernal() {
	SelectEvent("event_frost_infernal");
}

function CloseEvents(sendServerEvent) {
	SetEventsVisible(false);

	if (sendServerEvent) {
		GameEvents.SendCustomGameEventToServer("quit_event", {
			pID: Players.GetLocalPlayer()
		});
	}
}

function OnQuit() {
	CloseEvents(true);
}

(function() {
	GameEvents.Subscribe("show_events", OnShowEvents);
	GameEvents.Subscribe("quit_events", function() {
		CloseEvents(false);
	});
})();
