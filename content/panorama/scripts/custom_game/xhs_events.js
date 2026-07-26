function GetEventPanel() {
	return $.GetContextPanel().FindChildTraverse("EventPanel");
}

function SetSharedEventsVisible(visible) {
	if (typeof GameUI === "undefined" || !GameUI.CustomUIConfig) {
		return;
	}

	GameUI.CustomUIConfig().xhsSpecialEventVisible = !!visible;
}

var EventUsageState = {
	hero_image_used: false,
	hero_image_busy: false,
	spirit_beast_used: false,
	spirit_beast_busy: false,
	frost_infernal_used: false,
	frost_infernal_busy: false,
	all_hero_images_used: false,
	all_hero_images_busy: false
};

function IsTruthy(value) {
	return value === true || value === 1 || value === "1" || value === "true";
}

function SetEventLocked(eventId, locked, labelText) {
	var card = $("#" + eventId);
	if (!card) {
		return;
	}

	card.SetHasClass("XHSEventCardLocked", locked);
	card.enabled = !locked;

	var label = $("#" + eventId + "LockLabel");
	if (label) {
		label.text = labelText || "";
	}
}

function RefreshEventLocks() {
	if (EventUsageState.hero_image_used) {
		SetEventLocked("Event1", true, "Already completed");
	} else if (EventUsageState.hero_image_busy) {
		SetEventLocked("Event1", true, "Another player is inside");
	} else {
		SetEventLocked("Event1", false, "");
	}

	if (EventUsageState.all_hero_images_used) {
		SetEventLocked("Event4", true, "Already completed");
	} else if (EventUsageState.all_hero_images_busy) {
		SetEventLocked("Event4", true, "Another player is inside");
	} else {
		SetEventLocked("Event4", false, "");
	}

	if (EventUsageState.spirit_beast_used) {
		SetEventLocked("Event2", true, "Already completed");
	} else if (EventUsageState.spirit_beast_busy) {
		SetEventLocked("Event2", true, "Another player is inside");
	} else {
		SetEventLocked("Event2", false, "");
	}

	if (EventUsageState.frost_infernal_used) {
		SetEventLocked("Event3", true, "Already completed");
	} else if (EventUsageState.frost_infernal_busy) {
		SetEventLocked("Event3", true, "Another player is inside");
	} else {
		SetEventLocked("Event3", false, "");
	}
}

function UpdateEventUsage(data) {
	data = data || {};

	if (data.hero_image_used !== undefined) {
		EventUsageState.hero_image_used = IsTruthy(data.hero_image_used);
	}

	if (data.hero_image_busy !== undefined) {
		EventUsageState.hero_image_busy = IsTruthy(data.hero_image_busy);
	}

	if (data.spirit_beast_used !== undefined) {
		EventUsageState.spirit_beast_used = IsTruthy(data.spirit_beast_used);
	}

	if (data.spirit_beast_busy !== undefined) {
		EventUsageState.spirit_beast_busy = IsTruthy(data.spirit_beast_busy);
	}

	if (data.frost_infernal_used !== undefined) {
		EventUsageState.frost_infernal_used = IsTruthy(data.frost_infernal_used);
	}

	if (data.frost_infernal_busy !== undefined) {
		EventUsageState.frost_infernal_busy = IsTruthy(data.frost_infernal_busy);
	}

	if (data.all_hero_images_used !== undefined) {
		EventUsageState.all_hero_images_used = IsTruthy(data.all_hero_images_used);
	}

	if (data.all_hero_images_busy !== undefined) {
		EventUsageState.all_hero_images_busy = IsTruthy(data.all_hero_images_busy);
	}

	RefreshEventLocks();
}

function SetEventsVisible(visible) {
	var panel = GetEventPanel();

	if (!panel) {
		return;
	}

	SetSharedEventsVisible(visible);
	panel.SetHasClass("XHSEventsPanelVisible", visible);
}

function OnShowEvents(data) {
	UpdateEventUsage(data);
	SetEventsVisible(true);
}

function SelectEvent(eventName) {
	if (eventName === "event_hero_image" && (EventUsageState.hero_image_used || EventUsageState.hero_image_busy)) {
		RefreshEventLocks();
		return;
	}

	if (eventName === "event_all_hero_images" && (EventUsageState.all_hero_images_used || EventUsageState.all_hero_images_busy)) {
		RefreshEventLocks();
		return;
	}

	if (eventName === "event_spirit_beast" && (EventUsageState.spirit_beast_used || EventUsageState.spirit_beast_busy)) {
		RefreshEventLocks();
		return;
	}

	if (eventName === "event_frost_infernal" && (EventUsageState.frost_infernal_used || EventUsageState.frost_infernal_busy)) {
		RefreshEventLocks();
		return;
	}

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
	SetSharedEventsVisible(false);
	GameEvents.Subscribe("show_events", OnShowEvents);
	GameEvents.Subscribe("xhs_event_usage_update", UpdateEventUsage);
	GameEvents.Subscribe("quit_events", function() {
		CloseEvents(false);
	});
})();
