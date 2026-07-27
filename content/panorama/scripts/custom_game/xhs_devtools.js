var XHSDevToolsState = {};
var XHSDevToolsActiveTab = "scenarios";
var XHSDevToolsHasServerState = false;
var XHSDevToolsCurrentTimescale = 1;
var XHSDevToolsCinematicPreviewId = "";
var XHSDevToolsBotConfig = {};
var XHSDevToolsBotRoster = { count: 0, players: {} };
var XHSDevToolsBotDebug = {};

var XHS_DEVTOOLS_TIMESCALES = [
	{ value: 0.1, label: "x0.1" },
	{ value: 1, label: "x1" },
	{ value: 3, label: "x3" },
	{ value: 5, label: "x5" }
];

var XHS_DEVTOOLS_TABS = [
	{ id: "scenarios", label: "Scenarios" },
	{ id: "bosses", label: "Bosses" },
	{ id: "lanes", label: "Lanes/Waves" },
	{ id: "timers", label: "Timers/Phase" },
	{ id: "bots", label: "Bots" },
	{ id: "players", label: "Player Tools" },
	{ id: "ui", label: "UI Preview" },
	{ id: "cleanup", label: "Cleanup" }
];

var XHS_DEVTOOLS_BOSSES = [
	{ id: "magtheridon", label: "Magtheridon", icon: "npc_dota_hero_abyssal_underlord" },
	{ id: "grom", label: "Grom", icon: "npc_dota_hero_juggernaut" },
	{ id: "illidan", label: "Illidan", icon: "npc_dota_hero_terrorblade" },
	{ id: "balanar", label: "Balanar", icon: "npc_dota_hero_pugna" },
	{ id: "proudmoore", label: "Proudmoore", icon: "npc_dota_hero_kunkka" },
	{ id: "arthas", label: "Arthas", icon: "npc_dota_hero_omniknight" },
	{ id: "banehallow", label: "Banehallow", icon: "npc_dota_hero_nevermore" },
	{ id: "lich_king", label: "Lich King", icon: "npc_dota_hero_abaddon" },
	{ id: "spirit_master", label: "Spirit Master", icon: "npc_dota_hero_brewmaster" }
];

var XHS_DEVTOOLS_BOSS_UNITS = {
	magtheridon: ["npc_dota_hero_magtheridon"],
	grom: ["npc_dota_hero_grom_hellscream"],
	illidan: ["npc_dota_hero_illidan"],
	balanar: ["npc_dota_hero_balanar"],
	proudmoore: ["npc_dota_hero_proudmoore"],
	arthas: ["npc_dota_hero_arthas"],
	banehallow: ["npc_dota_hero_banehallow"],
	lich_king: ["npc_dota_boss_lich_king"],
	spirit_master: [
		"npc_dota_boss_spirit_master",
		"npc_dota_boss_spirit_master_fire",
		"npc_dota_boss_spirit_master_storm",
		"npc_dota_boss_spirit_master_earth"
	]
};

var XHS_DEVTOOLS_DIFFICULTIES = [
	{ id: 1, label: "Easy" },
	{ id: 2, label: "Normal" },
	{ id: 3, label: "Hard" },
	{ id: 4, label: "Extreme" },
	{ id: 5, label: "Divine" }
];

var XHS_DEVTOOLS_DONATOR_STATUSES = [
	{ id: 0, label: "0 None" },
	{ id: 1, label: "1 Lead" },
	{ id: 2, label: "2 Dev" },
	{ id: 3, label: "3 Admin" },
	{ id: 4, label: "4 Ember" },
	{ id: 5, label: "5 Golden" },
	{ id: 6, label: "6 Donator" },
	{ id: 7, label: "7 Stone" },
	{ id: 8, label: "8 Earth" },
	{ id: 9, label: "9 Legacy" },
	{ id: 10, label: "10 Hidden" }
];

function XHSDevToolsPanel() {
	return $("#XHSDevToolsPanel");
}

function XHSDevToolsIsToolsMode() {
	return typeof Game.IsInToolsMode === "function" && Game.IsInToolsMode();
}

function XHSDevToolsSend(action, payload) {
	if (!XHSDevToolsState.enabled) {
		XHSDevToolsRenderStatus();
		return;
	}

	payload = payload || {};
	payload.action = action;
	GameEvents.SendCustomGameEventToServer("xhs_devtools_run_action", payload);
}

function XHSDevToolsGetCinematicApi() {
	var config = GameUI.CustomUIConfig();
	return config && config.XHSCinematics;
}

function XHSDevToolsBeginClientCinematic(options) {
	var api = XHSDevToolsGetCinematicApi();
	if (!api || typeof api.begin !== "function") {
		$.Msg("[XHS][DevTools][Cinematic] Client API is unavailable. Check custom_ui_manifest.xml and xhs_cinematic.js.");
		return;
	}

	options = options || {};
	XHSDevToolsCinematicPreviewId = String(options.id || "xhs_dev_client");
	options.id = XHSDevToolsCinematicPreviewId;
	$.Msg("[XHS][DevTools][Cinematic] Client begin: ", options);
	api.begin(options);
}

function XHSDevToolsEndClientCinematic() {
	var api = XHSDevToolsGetCinematicApi();
	if (!api || typeof api.end !== "function") {
		$.Msg("[XHS][DevTools][Cinematic] Client API is unavailable; cannot end preview.");
		return;
	}

	var id = XHSDevToolsCinematicPreviewId || "xhs_dev_client";
	$.Msg("[XHS][DevTools][Cinematic] Client end: ", id);
	api.end({ id: id });
	XHSDevToolsCinematicPreviewId = "";
}

function XHSDevToolsRequestState() {
	GameEvents.SendCustomGameEventToServer("xhs_devtools_request_state", {});
}

function XHSDevToolsRequestStateLoop() {
	XHSDevToolsRequestState();

	if (!XHSDevToolsHasServerState) {
		$.Schedule(1.0, XHSDevToolsRequestStateLoop);
	}
}

function XHSDevToolsTogglePanel() {
	var panel = XHSDevToolsPanel();
	if (!panel) {
		return;
	}

	panel.SetHasClass("Visible", !panel.BHasClass("Visible"));
	if (panel.BHasClass("Visible")) {
		XHSDevToolsRequestState();
		XHSDevToolsReadBotNetTables();
		XHSDevToolsRender();
	}
}

function XHSDevToolsClear(panel) {
	if (!panel) {
		return;
	}
	panel.RemoveAndDeleteChildren();
}

function XHSDevToolsMakeLabel(parent, className, text) {
	var label = $.CreatePanel("Label", parent, "");
	if (className) {
		label.AddClass(className);
	}
	label.text = text || "";
	return label;
}

function XHSDevToolsMakeButton(parent, label, className, callback) {
	var button = $.CreatePanel("Button", parent, "");
	button.AddClass("XHSDevToolsButton");
	if (className) {
		button.AddClass(className);
	}
	button.SetPanelEvent("onactivate", callback);
	XHSDevToolsMakeLabel(button, "", label);
	return button;
}

function XHSDevToolsMakeHeroIcon(parent, heroIcon, className) {
	var frame = $.CreatePanel("Panel", parent, "");
	frame.AddClass("XHSDevToolsHeroIconFrame");
	if (className) {
		frame.AddClass(className);
	}

	var image = $.CreatePanel("Image", frame, "");
	image.AddClass("XHSDevToolsHeroIcon");
	image.SetImage(heroIcon ? "file://{images}/heroes/" + heroIcon + ".png" : "");
	return frame;
}

function XHSDevToolsMakeSection(parent, title) {
	var section = $.CreatePanel("Panel", parent, "");
	section.AddClass("XHSDevToolsSection");
	XHSDevToolsMakeLabel(section, "XHSDevToolsSectionTitle", title);
	return section;
}

function XHSDevToolsRenderTimescale() {
	var bar = $("#XHSDevToolsTimescale");
	if (!bar) {
		return;
	}

	XHSDevToolsClear(bar);
	var available = XHSDevToolsIsToolsMode();
	bar.SetHasClass("Visible", available);
	if (!available) {
		return;
	}

	var serverTimescale = Number(XHSDevToolsState.host_timescale);
	if (serverTimescale > 0) {
		XHSDevToolsCurrentTimescale = serverTimescale;
	}

	for (var i = 0; i < XHS_DEVTOOLS_TIMESCALES.length; i++) {
		(function(option) {
			var button = $.CreatePanel("Button", bar, "");
			button.AddClass("XHSDevToolsTimescaleButton");
			button.SetHasClass("Active", Math.abs(XHSDevToolsCurrentTimescale - option.value) < 0.001);
			button.SetPanelEvent("onactivate", function() {
				XHSDevToolsCurrentTimescale = option.value;
				XHSDevToolsRenderTimescale();
				XHSDevToolsSend("set_timescale", { timescale: option.value });
			});
			XHSDevToolsMakeLabel(button, "", option.label);
		})(XHS_DEVTOOLS_TIMESCALES[i]);
	}
}

function XHSDevToolsRenderTabs() {
	var tabs = $("#XHSDevToolsTabs");
	XHSDevToolsClear(tabs);

	for (var i = 0; i < XHS_DEVTOOLS_TABS.length; i++) {
		(function(tab) {
			var button = XHSDevToolsMakeButton(tabs, tab.label, "XHSDevToolsTab", function() {
				XHSDevToolsActiveTab = tab.id;
				XHSDevToolsRender();
			});
			button.SetHasClass("Active", XHSDevToolsActiveTab === tab.id);
		})(XHS_DEVTOOLS_TABS[i]);
	}
}

function XHSDevToolsRenderStatus() {
	var label = $("#XHSDevToolsStatusText");
	if (!label) {
		return;
	}

	if (!XHSDevToolsState.enabled) {
		var unavailable = XHSDevToolsHasServerState
			? "Disabled: launch from Workshop Tools mode"
			: "Waiting for devtools server state";
		label.text = unavailable;
		label.SetHasClass("Error", true);
		return;
	}

	var result = XHSDevToolsState.last_result || {};
	var sandbox = XHSDevToolsState.campaign_flow_active ? "Flow ON" : (XHSDevToolsState.sandbox_active ? "Sandbox ON" : "Sandbox off");
	var phase = XHSDevToolsState.game_phase || 0;
	var difficulty = XHSDevToolsState.difficulty || 1;
	var paused = XHSDevToolsState.timers_paused || 0;
	var message = result.message || "Ready";
	label.text = sandbox + " | Phase " + phase + " | Difficulty " + difficulty + " | Pause " + paused + " | " + message;
	label.SetHasClass("Error", result.ok === false);
}

function XHSDevToolsRenderSandboxBar() {
	var bar = $("#XHSDevToolsSandboxBar");
	XHSDevToolsClear(bar);
	if (!bar) {
		return;
	}

	if (!XHSDevToolsState.enabled) {
		bar.style.visibility = "collapse";
		return;
	}

	bar.style.visibility = "visible";
	var active = XHSDevToolsState.sandbox_active === true;
	var text = $.CreatePanel("Panel", bar, "");
	text.AddClass("XHSDevToolsSandboxText");
	XHSDevToolsMakeLabel(text, "XHSDevToolsSandboxTitle", "Sandbox");
	XHSDevToolsMakeLabel(text, "XHSDevToolsSandboxHint", active ? "Automatic creeps, events, timers and final wave are disabled." : "Normal automatic game flow is running.");

	var button = XHSDevToolsMakeButton(bar, active ? "Disable Sandbox" : "Enable Sandbox", active ? "Warn" : "Accent", function() {
		XHSDevToolsSend("set_sandbox", { enabled: active ? 0 : 1 });
	});
	button.AddClass("XHSDevToolsSandboxToggleButton");
	button.SetHasClass("Active", active);
}

function XHSDevToolsRenderUnavailable(parent) {
	var section = XHSDevToolsMakeSection(parent, "Dev tools unavailable");
	var reason = XHSDevToolsHasServerState
		? "The server loaded the panel, but actions are disabled because this session is not running in Workshop Tools mode."
		: "No devtools server state has been received yet. If you just compiled the HUD, restart the addon or reload the custom UI.";
	XHSDevToolsMakeLabel(section, "XHSDevToolsUnavailableLine", reason);
	XHSDevToolsMakeLabel(section, "XHSDevToolsMuted", "The DEV button is shown for diagnostics only; scenario, boss, lane, timer, and player actions remain blocked until tools mode is active.");
}

function XHSDevToolsGetBossActivity(boss) {
	var unitNames = XHS_DEVTOOLS_BOSS_UNITS[boss.id] || [];
	var bossesState = XHSDevToolsState.bosses || {};

	for (var bossKey in bossesState) {
		var active = bossesState[bossKey];
		for (var i = 0; i < unitNames.length; i++) {
			if (active.name === unitNames[i]) {
				var health = active.max_health > 0 ? Math.floor((active.health / active.max_health) * 100) : 0;
				return { active: true, health: health };
			}
		}
	}

	return { active: false, health: 0 };
}

function XHSDevToolsRenderScenarios(parent) {
	var quests = XHSDevToolsMakeSection(parent, "Quests");
	XHSDevToolsMakeLabel(quests, "XHSDevToolsSubsectionTitle", "Major Scenario");
	var scenarioGrid = $.CreatePanel("Panel", quests, "");
	scenarioGrid.AddClass("XHSDevToolsGrid");
	XHSDevToolsMakeButton(scenarioGrid, "Ramero & Baristol", "Accent", function() {
		XHSDevToolsSend("trigger_event", { event: "ramero_baristol" });
	});
	XHSDevToolsMakeButton(scenarioGrid, "Muradin", "Accent", function() {
		XHSDevToolsSend("trigger_event", { event: "muradin" });
	});
	XHSDevToolsMakeButton(scenarioGrid, "Farm", "Accent", function() {
		XHSDevToolsSend("trigger_event", { event: "farm" });
	});
	XHSDevToolsMakeButton(scenarioGrid, "Sogat", "Accent", function() {
		XHSDevToolsSend("trigger_event", { event: "sogat" });
	});
	XHSDevToolsMakeButton(scenarioGrid, "Final Wave", "Danger", function() {
		XHSDevToolsSend("start_final_wave", {});
	});

	var fragmentSection = XHSDevToolsMakeSection(parent, "Fragment Quests");
	var fragmentState = XHSDevToolsState.fragment_quests || {};
	XHSDevToolsMakeLabel(fragmentSection, "XHSDevToolsMuted", "Backend: " + (fragmentState.backend_status || "pending") + " / confirmed +" + (fragmentState.confirmed_total_fragments || 0) + " fragments");
	if (fragmentState.last_payload_dump && fragmentState.last_payload_dump.version) {
		var dump = fragmentState.last_payload_dump;
		XHSDevToolsMakeLabel(fragmentSection, "XHSDevToolsMuted", "Last payload: v" + dump.version + " / " + (dump.selected_count || 0) + " quests / " + (dump.event_count || 0) + " events / +" + (dump.total_fragments_preview || 0) + " preview");
	}

	var selected = fragmentState.selected || {};
	for (var slot = 1; slot <= 3; slot++) {
		var quest = selected[String(slot)];
		if (quest) {
			XHSDevToolsMakeLabel(fragmentSection, "XHSDevToolsMuted", slot + ". " + quest.title + " - " + (quest.stars || 0) + " stars - " + (quest.progress_text || "0"));
		}
	}

	var fragmentGrid = $.CreatePanel("Panel", fragmentSection, "");
	fragmentGrid.AddClass("XHSDevToolsGrid");
	XHSDevToolsMakeButton(fragmentGrid, "Reroll", "Accent", function() {
		XHSDevToolsSend("fragment_quests_reroll", {});
	});
	XHSDevToolsMakeButton(fragmentGrid, "Force Farm", "Small", function() {
		XHSDevToolsSend("fragment_quest_force", { slot: 2, template_id: "farm_event_kills", target_id: "team" });
	});
	XHSDevToolsMakeButton(fragmentGrid, "Force Muradin", "Small", function() {
		XHSDevToolsSend("fragment_quest_force", { slot: 2, template_id: "muradin_death_cap", target_id: "team" });
	});
	XHSDevToolsMakeButton(fragmentGrid, "Force Ramero", "Small", function() {
		XHSDevToolsSend("fragment_quest_force", { slot: 2, template_id: "arena_remaining_time", target_id: "ramero_baristol" });
	});
	XHSDevToolsMakeButton(fragmentGrid, "Force Sogat", "Small", function() {
		XHSDevToolsSend("fragment_quest_force", { slot: 2, template_id: "arena_remaining_time", target_id: "sogat" });
	});
	XHSDevToolsMakeButton(fragmentGrid, "Force Grom", "Small", function() {
		XHSDevToolsSend("fragment_quest_force", { slot: 3, template_id: "boss_death_cap", target_id: "grom" });
	});
	XHSDevToolsMakeButton(fragmentGrid, "Force Illidan", "Small", function() {
		XHSDevToolsSend("fragment_quest_force", { slot: 3, template_id: "boss_timer", target_id: "illidan" });
	});
	XHSDevToolsMakeButton(fragmentGrid, "Force LK", "Small", function() {
		XHSDevToolsSend("fragment_quest_force", { slot: 3, template_id: "boss_timer", target_id: "lich_king" });
	});

	var fragmentBackendGrid = $.CreatePanel("Panel", fragmentSection, "");
	fragmentBackendGrid.AddClass("XHSDevToolsGrid");
	XHSDevToolsMakeButton(fragmentBackendGrid, "Backend OK", "Small Accent", function() {
		XHSDevToolsSend("fragment_quest_backend_success", {});
	});
	XHSDevToolsMakeButton(fragmentBackendGrid, "Backend Error", "Small Danger", function() {
		XHSDevToolsSend("fragment_quest_backend_error", {});
	});
	XHSDevToolsMakeButton(fragmentBackendGrid, "Dump Payload", "Small", function() {
		XHSDevToolsSend("fragment_quest_dump_payload", {});
	});

	var fragmentProgressGrid = $.CreatePanel("Panel", fragmentSection, "");
	fragmentProgressGrid.AddClass("XHSDevToolsGrid");
	XHSDevToolsMakeButton(fragmentProgressGrid, "+5M Damage", "Small Accent", function() {
		XHSDevToolsSend("fragment_quest_progress", { metric: "damage", amount: 5000000 });
	});
	XHSDevToolsMakeButton(fragmentProgressGrid, "+500k Heal", "Small Accent", function() {
		XHSDevToolsSend("fragment_quest_progress", { metric: "healing", amount: 500000 });
	});
	XHSDevToolsMakeButton(fragmentProgressGrid, "+10 Potions", "Small", function() {
		XHSDevToolsSend("fragment_quest_progress", { metric: "potions", amount: 10 });
	});
	XHSDevToolsMakeButton(fragmentProgressGrid, "+1 Death", "Small Warn", function() {
		XHSDevToolsSend("fragment_quest_progress", { metric: "death", amount: 1 });
	});
	XHSDevToolsMakeButton(fragmentProgressGrid, "+60 Farm", "Small", function() {
		XHSDevToolsSend("fragment_quest_progress", { metric: "farm_kills", amount: 60 });
	});
	XHSDevToolsMakeButton(fragmentProgressGrid, "+500k Tanked", "Small", function() {
		XHSDevToolsSend("fragment_quest_progress", { metric: "frontline", amount: 500000 });
	});
	XHSDevToolsMakeButton(fragmentProgressGrid, "+1 Tower Kill", "Small Warn", function() {
		XHSDevToolsSend("fragment_quest_progress", { metric: "tower_kills", amount: 1 });
	});
	XHSDevToolsMakeButton(fragmentProgressGrid, "Base 100%", "Small Accent", function() {
		XHSDevToolsSend("fragment_quest_progress", { metric: "base_hp", amount: 100 });
	});

	var fragmentWindowGrid = $.CreatePanel("Panel", fragmentSection, "");
	fragmentWindowGrid.AddClass("XHSDevToolsGrid");
	XHSDevToolsMakeButton(fragmentWindowGrid, "Complete Farm", "Small Accent", function() {
		XHSDevToolsSend("fragment_quest_complete_window", { window: "farm", value: 240 });
	});
	XHSDevToolsMakeButton(fragmentWindowGrid, "Complete Muradin", "Small Accent", function() {
		XHSDevToolsSend("fragment_quest_complete_window", { window: "muradin", value: 0 });
	});
	XHSDevToolsMakeButton(fragmentWindowGrid, "Complete Ramero", "Small Accent", function() {
		XHSDevToolsSend("fragment_quest_complete_window", { window: "ramero", value: 60 });
	});
	XHSDevToolsMakeButton(fragmentWindowGrid, "Complete Sogat", "Small Accent", function() {
		XHSDevToolsSend("fragment_quest_complete_window", { window: "sogat", value: 45 });
	});
	XHSDevToolsMakeButton(fragmentWindowGrid, "Complete Phase2", "Small Accent", function() {
		XHSDevToolsSend("fragment_quest_complete_window", { window: "phase2", value: 180 });
	});
	XHSDevToolsMakeButton(fragmentWindowGrid, "Complete Grom", "Small Accent", function() {
		XHSDevToolsSend("fragment_quest_complete_window", { window: "grom", value: 0 });
	});
	XHSDevToolsMakeButton(fragmentWindowGrid, "Complete Illidan", "Small Accent", function() {
		XHSDevToolsSend("fragment_quest_complete_window", { window: "illidan", value: 120 });
	});
	XHSDevToolsMakeButton(fragmentWindowGrid, "Complete LK", "Small Accent", function() {
		XHSDevToolsSend("fragment_quest_complete_window", { window: "lich_king", value: 270 });
	});
	XHSDevToolsMakeButton(fragmentWindowGrid, "Complete Final", "Small Accent", function() {
		XHSDevToolsSend("fragment_quest_complete_window", { window: "final", value: 100 });
	});

	XHSDevToolsMakeLabel(quests, "XHSDevToolsSubsectionTitle", "Quest State");
	var questGrid = $.CreatePanel("Panel", quests, "");
	questGrid.AddClass("XHSDevToolsQuestGrid");

	var questState = XHSDevToolsState.quests || {};
	for (var key in questState) {
		var quest = questState[key];
		(function(questData) {
			var row = $.CreatePanel("Panel", questGrid, "");
			row.AddClass("XHSDevToolsQuestRow");

			var state = questData.completed ? "done" : (questData.active ? "active" : "idle");
			XHSDevToolsMakeLabel(row, "XHSDevToolsQuestName", questData.label + " (" + state + ")");

			XHSDevToolsMakeButton(row, "Activate", "Small", function() {
				XHSDevToolsSend("activate_quest", { quest: questData.name });
			});
			XHSDevToolsMakeButton(row, "Complete", "Small Warn", function() {
				XHSDevToolsSend("complete_quest", { quest: questData.name });
			});
		})(quest);
	}

}

function XHSDevToolsRenderBosses(parent) {
	var bosses = XHSDevToolsMakeSection(parent, "Bosses");
	XHSDevToolsMakeLabel(bosses, "XHSDevToolsMuted", "Start Test isolates the boss in sandbox. Start Flow launches a campaign checkpoint and lets normal progression continue.");
	var bossGrid = $.CreatePanel("Panel", bosses, "");
	bossGrid.AddClass("XHSDevToolsBossGrid");
	for (var i = 0; i < XHS_DEVTOOLS_BOSSES.length; i++) {
		(function(boss) {
			var activity = XHSDevToolsGetBossActivity(boss);
			var card = $.CreatePanel("Panel", bossGrid, "");
			card.AddClass("XHSDevToolsBossCard");
			card.SetHasClass("Active", activity.active);

			var header = $.CreatePanel("Panel", card, "");
			header.AddClass("XHSDevToolsBossCardHeader");
			XHSDevToolsMakeHeroIcon(header, boss.icon, "");

			var text = $.CreatePanel("Panel", header, "");
			text.AddClass("XHSDevToolsBossText");
			XHSDevToolsMakeLabel(text, "XHSDevToolsBossName", boss.label);
			XHSDevToolsMakeLabel(text, "XHSDevToolsBossStatus", activity.active ? ("Active - " + activity.health + "%") : "Ready");

			XHSDevToolsMakeButton(card, "Start Test", "Accent", function() {
				XHSDevToolsSend("start_boss", { boss: boss.id });
			});
			XHSDevToolsMakeButton(card, "Start Flow", "Flow", function() {
				XHSDevToolsSend("start_boss_flow", { boss: boss.id });
			});
		})(XHS_DEVTOOLS_BOSSES[i]);
	}

	var activeBosses = XHSDevToolsMakeSection(parent, "Active Bosses");
	var bossesState = XHSDevToolsState.bosses || {};
	var count = 0;
	for (var bossKey in bossesState) {
		count++;
		var active = bossesState[bossKey];
		var health = active.max_health > 0 ? Math.floor((active.health / active.max_health) * 100) : 0;
		XHSDevToolsMakeLabel(activeBosses, "XHSDevToolsBossLine", active.name + " - " + health + "%");
	}
	if (count === 0) {
		XHSDevToolsMakeLabel(activeBosses, "XHSDevToolsMuted", "No tracked boss alive.");
	}
}

function XHSDevToolsRenderLanes(parent) {
	var laneSection = XHSDevToolsMakeSection(parent, "Lane Control");
	var lanes = XHSDevToolsState.lanes || {};

	for (var i = 1; i <= 8; i++) {
		(function(laneNumber) {
			var lane = lanes[String(laneNumber)] || { enabled: false, level: 1, rax_alive: true };
			var row = $.CreatePanel("Panel", laneSection, "");
			row.AddClass("XHSDevToolsLaneRow");

			XHSDevToolsMakeLabel(row, "XHSDevToolsLaneName", "Lane " + laneNumber);
			XHSDevToolsMakeButton(row, lane.enabled ? "Disable" : "Enable", "Small", function() {
				XHSDevToolsSend("set_lane", { lane: laneNumber, enabled: lane.enabled ? 0 : 1 });
			});
			XHSDevToolsMakeButton(row, lane.rax_alive ? "Rax dead" : "Rax alive", "Small", function() {
				XHSDevToolsSend("set_lane", { lane: laneNumber, rax_alive: lane.rax_alive ? 0 : 1 });
			});

			for (var level = 1; level <= 4; level++) {
				(function(lvl) {
					var levelButton = XHSDevToolsMakeButton(row, "L" + lvl, "Tiny", function() {
						XHSDevToolsSend("set_lane", { lane: laneNumber, level: lvl });
					});
					levelButton.SetHasClass("Active", lane.level === lvl);
				})(level);
			}

			XHSDevToolsMakeButton(row, "Wave", "Small Accent", function() {
				XHSDevToolsSend("spawn_lane_wave", { lane: laneNumber });
			});
		})(i);
	}

	var waveSection = XHSDevToolsMakeSection(parent, "Wave Tools");
	XHSDevToolsMakeLabel(waveSection, "XHSDevToolsMuted", "Use the global Sandbox toggle above to stop automatic waves and timers. Manual triggers still work.");
	var grid = $.CreatePanel("Panel", waveSection, "");
	grid.AddClass("XHSDevToolsGrid");
	XHSDevToolsMakeButton(grid, "Activate Phase 2", "Warn", function() {
		XHSDevToolsSend("start_phase2", {});
	});
	XHSDevToolsMakeButton(grid, "Spawn Enabled Lanes", "", function() {
		XHSDevToolsSend("spawn_lane_wave", { lane: 0 });
	});
	XHSDevToolsMakeButton(grid, "Phase 2 Left", "Small Accent", function() {
		XHSDevToolsSend("spawn_phase2_wave", { side: "left" });
	});
	XHSDevToolsMakeButton(grid, "Phase 2 Right", "Small Accent", function() {
		XHSDevToolsSend("spawn_phase2_wave", { side: "right" });
	});
	XHSDevToolsMakeButton(grid, "Phase 2 Both", "Accent", function() {
		XHSDevToolsSend("spawn_phase2_wave", { side: "both" });
	});
	for (var wave = 1; wave <= 8; wave++) {
		(function(w) {
			XHSDevToolsMakeButton(grid, "Special " + w, "Small", function() {
				XHSDevToolsSend("special_wave", { wave: w });
			});
		})(wave);
	}
}

function XHSDevToolsRenderTimers(parent) {
	var difficulty = XHSDevToolsMakeSection(parent, "Difficulty");
	XHSDevToolsMakeLabel(difficulty, "XHSDevToolsMuted", "Changing difficulty respawns active dev boss tests so the fight reloads cleanly.");
	var difficultyGrid = $.CreatePanel("Panel", difficulty, "");
	difficultyGrid.AddClass("XHSDevToolsGrid");
	for (var d = 0; d < XHS_DEVTOOLS_DIFFICULTIES.length; d++) {
		(function(option) {
			var button = XHSDevToolsMakeButton(difficultyGrid, option.label, "", function() {
				XHSDevToolsSend("set_difficulty", { difficulty: option.id, respawn_bosses: 1 });
			});
			button.SetHasClass("Active", Number(XHSDevToolsState.difficulty || 1) === option.id);
		})(XHS_DEVTOOLS_DIFFICULTIES[d]);
	}

	var timers = XHSDevToolsMakeSection(parent, "Timers");
	var timerGrid = $.CreatePanel("Panel", timers, "");
	timerGrid.AddClass("XHSDevToolsGrid");
	XHSDevToolsMakeButton(timerGrid, "Pause Timers", "", function() {
		XHSDevToolsSend("pause_timers", {});
	});
	XHSDevToolsMakeButton(timerGrid, "Resume Timers", "", function() {
		XHSDevToolsSend("resume_timers", {});
	});
	XHSDevToolsMakeButton(timerGrid, "Final Countdown", "Warn", function() {
		XHSDevToolsSend("trigger_event", { event: "final_countdown" });
	});

	var phase = XHSDevToolsMakeSection(parent, "Phase");
	var phaseGrid = $.CreatePanel("Panel", phase, "");
	phaseGrid.AddClass("XHSDevToolsGrid");
	for (var i = 1; i <= 3; i++) {
		(function(phaseNumber) {
			var button = XHSDevToolsMakeButton(phaseGrid, "Phase " + phaseNumber, "", function() {
				XHSDevToolsSend("set_phase", { phase: phaseNumber });
			});
			button.SetHasClass("Active", XHSDevToolsState.game_phase === phaseNumber);
		})(i);
	}
}

function XHSDevToolsBotTableValues(table) {
	var values = [];
	for (var key in (table || {})) {
		if (table[key] !== undefined && table[key] !== null) {
			values.push({ key: key, value: table[key] });
		}
	}
	values.sort(function(a, b) {
		var aNumber = Number(a.key);
		var bNumber = Number(b.key);
		if (!isNaN(aNumber) && !isNaN(bNumber)) {
			return aNumber - bNumber;
		}
		return String(a.key) < String(b.key) ? -1 : 1;
	});
	return values;
}

function XHSDevToolsBotText(value, fallback) {
	if (value === undefined || value === null || String(value).length === 0) {
		return fallback || "-";
	}
	return String(value);
}

function XHSDevToolsBotHeroName(heroName) {
	heroName = XHSDevToolsBotText(heroName, "");
	if (!heroName) {
		return "No hero";
	}
	var localized = $.Localize("#" + heroName);
	if (localized && localized !== ("#" + heroName)) {
		return localized;
	}
	return heroName.replace(/^npc_dota_hero_/, "").replace(/_/g, " ").toUpperCase();
}

function XHSDevToolsBotVector(vector) {
	if (!vector) {
		return "-";
	}
	return Math.floor(Number(vector.x) || 0) + ", " +
		Math.floor(Number(vector.y) || 0) + ", " +
		Math.floor(Number(vector.z) || 0);
}

function XHSDevToolsMakeBotMetric(parent, key, value, wide) {
	var metric = $.CreatePanel("Panel", parent, "");
	metric.AddClass("XHSDevToolsBotMetric");
	metric.SetHasClass("Wide", wide === true);
	XHSDevToolsMakeLabel(metric, "XHSDevToolsBotMetricKey", key);
	XHSDevToolsMakeLabel(metric, "XHSDevToolsBotMetricValue", XHSDevToolsBotText(value, "-"));
	return metric;
}

function XHSDevToolsRenderBotTopActions(parent, debug) {
	var actions = XHSDevToolsBotTableValues(debug.top_actions || {});
	var actionList = $.CreatePanel("Panel", parent, "");
	actionList.AddClass("XHSDevToolsBotActionsList");
	if (actions.length === 0) {
		XHSDevToolsMakeLabel(actionList, "XHSDevToolsBotActionLine", "No scored action yet.");
		return;
	}

	for (var i = 0; i < actions.length && i < 3; i++) {
		var action = actions[i].value || {};
		var score = Number(action.score);
		var scoreText = isNaN(score) ? "-" : score.toFixed(2);
		XHSDevToolsMakeLabel(
			actionList,
			"XHSDevToolsBotActionLine",
			(i + 1) + ". " + XHSDevToolsBotText(action.id, "unknown") +
				" [" + scoreText + "] - " + XHSDevToolsBotText(action.reason, "no reason")
		);
	}
}

function XHSDevToolsRenderBotCard(parent, rosterEntry) {
	var bot = rosterEntry.value || {};
	var playerID = Number(bot.player_id);
	if (isNaN(playerID)) {
		playerID = Number(rosterEntry.key);
	}
	var debug = XHSDevToolsBotDebug[String(playerID)] || {};

	var card = $.CreatePanel("Panel", parent, "");
	card.AddClass("XHSDevToolsBotCard");
	card.SetHasClass("HasError", !!debug.error);

	var header = $.CreatePanel("Panel", card, "");
	header.AddClass("XHSDevToolsBotCardHeader");
	XHSDevToolsMakeHeroIcon(header, bot.hero || debug.hero, "XHSDevToolsBotHero");

	var headerText = $.CreatePanel("Panel", header, "");
	headerText.AddClass("XHSDevToolsBotHeaderText");
	XHSDevToolsMakeLabel(headerText, "XHSDevToolsBotName", XHSDevToolsBotText(bot.name, "XHS Bot " + (playerID + 1)));
	XHSDevToolsMakeLabel(
		headerText,
		"XHSDevToolsBotMeta",
		"#" + playerID + " / " +
			XHSDevToolsBotHeroName(bot.hero || debug.hero) + " / " +
			XHSDevToolsBotText(bot.difficulty || debug.difficulty, "normal") + " / " +
			XHSDevToolsBotText(bot.role || debug.role, "unassigned")
	);

	var stateRow = $.CreatePanel("Panel", card, "");
	stateRow.AddClass("XHSDevToolsBotStateRow");
	XHSDevToolsMakeLabel(stateRow, "XHSDevToolsBotState", XHSDevToolsBotText(debug.state, "INITIALIZING"));
	XHSDevToolsMakeLabel(stateRow, "XHSDevToolsBotGoal", "Goal: " + XHSDevToolsBotText(debug.goal, "-"));

	var metrics = $.CreatePanel("Panel", card, "");
	metrics.AddClass("XHSDevToolsBotMetrics");
	XHSDevToolsMakeBotMetric(metrics, "Target", debug.target || debug.target_entindex, true);
	XHSDevToolsMakeBotMetric(metrics, "Anchor", XHSDevToolsBotVector(debug.anchor), true);
	XHSDevToolsMakeBotMetric(metrics, "Lane / side", XHSDevToolsBotText(debug.lane, "0") + " / " + XHSDevToolsBotText(debug.side, "-"), false);
	XHSDevToolsMakeBotMetric(metrics, "Idle", XHSDevToolsBotText(debug.idle_seconds, "0") + "s", false);
	XHSDevToolsMakeBotMetric(metrics, "Orders", debug.orders, false);
	XHSDevToolsMakeBotMetric(metrics, "Targets", debug.target_changes, false);
	XHSDevToolsMakeBotMetric(metrics, "Unstuck", debug.stuck_recoveries, false);
	XHSDevToolsMakeBotMetric(metrics, "Danger hits", debug.danger_hits, false);
	XHSDevToolsMakeBotMetric(metrics, "Tomes", debug.tomes_bought, false);
	XHSDevToolsMakeBotMetric(metrics, "Connection", debug.connection_state, false);

	var decisions = $.CreatePanel("Panel", card, "");
	decisions.AddClass("XHSDevToolsBotDecisions");
	XHSDevToolsMakeLabel(
		decisions,
		"XHSDevToolsBotDecisionLine",
		"Decision: " + XHSDevToolsBotText(debug.last_decision, "-") +
			" - " + XHSDevToolsBotText(debug.last_decision_reason, "no reason")
	);
	XHSDevToolsMakeLabel(
		decisions,
		"XHSDevToolsBotDecisionLine",
		"Order: " + XHSDevToolsBotText(debug.last_order, "-")
	);
	XHSDevToolsMakeLabel(
		decisions,
		"XHSDevToolsBotDecisionLine",
		"Ability: " + XHSDevToolsBotText(debug.last_ability, "-") +
			" - " + XHSDevToolsBotText(debug.last_ability_reason, "no reason")
	);
	XHSDevToolsMakeLabel(
		decisions,
		"XHSDevToolsBotDecisionLine",
		"Rejected: " + XHSDevToolsBotText(debug.last_rejected_action, "-")
	);

	XHSDevToolsMakeLabel(card, "XHSDevToolsBotSubheading", "TOP ACTIONS");
	XHSDevToolsRenderBotTopActions(card, debug);

	var engineKnown = debug.engine_fake_client !== undefined && debug.engine_fake_client !== null;
	var teamKnown = debug.engine_team_verified !== undefined && debug.engine_team_verified !== null;
	var engineOk = engineKnown && (Number(debug.engine_fake_client) === 1 || debug.engine_fake_client === true);
	var teamOk = teamKnown && (Number(debug.engine_team_verified) === 1 || debug.engine_team_verified === true);
	var engine = XHSDevToolsMakeLabel(
		card,
		"XHSDevToolsBotEngine",
		"Engine bot: " + (engineKnown ? (engineOk ? "YES" : "NO") : "...") +
			" / Radiant: " + (teamKnown ? (teamOk ? "YES" : "NO") : "...")
	);
	engine.SetHasClass("Error", (engineKnown && !engineOk) || (teamKnown && !teamOk));

	if (debug.error) {
		XHSDevToolsMakeLabel(card, "XHSDevToolsBotError", String(debug.error));
	}

	var goalGrid = $.CreatePanel("Panel", card, "");
	goalGrid.AddClass("XHSDevToolsBotGoalGrid");
	var goals = [
		{ id: "auto", label: "Auto" },
		{ id: "defend_base", label: "Base" },
		{ id: "regroup", label: "Regroup" },
		{ id: "fight_boss", label: "Boss" },
		{ id: "hold", label: "Hold" }
	];
	for (var i = 0; i < goals.length; i++) {
		(function(goal) {
			XHSDevToolsMakeButton(goalGrid, goal.label, "Tiny", function() {
				XHSDevToolsSend("bot_force_goal", { player_id: playerID, goal: goal.id });
			});
		})(goals[i]);
	}
}

function XHSDevToolsRenderBots(parent) {
	var controls = XHSDevToolsMakeSection(parent, "Allied Bot Control");
	var configuredCount = Number(XHSDevToolsBotConfig.bot_count || 0);
	var rosterCount = Number(XHSDevToolsBotRoster.count || 0);
	XHSDevToolsMakeLabel(
		controls,
		"XHSDevToolsMuted",
		"Config: " + configuredCount + " " +
			XHSDevToolsBotText(XHSDevToolsBotConfig.ai_difficulty, "normal") + " / " +
			XHSDevToolsBotText(XHSDevToolsBotConfig.composition, "balanced") +
			" | roster " + rosterCount +
			" | server " + XHSDevToolsBotText(XHSDevToolsBotConfig.status, "waiting")
	);
	if (XHSDevToolsBotConfig.error) {
		XHSDevToolsMakeLabel(controls, "XHSDevToolsBotError", String(XHSDevToolsBotConfig.error));
	}

	var controlGrid = $.CreatePanel("Panel", controls, "");
	controlGrid.AddClass("XHSDevToolsGrid");
	XHSDevToolsMakeButton(controlGrid, "Pause AI", "Warn", function() {
		XHSDevToolsSend("bot_pause", {});
	});
	XHSDevToolsMakeButton(controlGrid, "Resume AI", "Accent", function() {
		XHSDevToolsSend("bot_resume", {});
	});
	XHSDevToolsMakeButton(controlGrid, "Overlay ON", "", function() {
		XHSDevToolsSend("bot_overlay", { enabled: 1 });
	});
	XHSDevToolsMakeButton(controlGrid, "Overlay OFF", "", function() {
		XHSDevToolsSend("bot_overlay", { enabled: 0 });
	});
	XHSDevToolsMakeButton(controlGrid, "Reset AI", "Danger", function() {
		XHSDevToolsSend("bot_reset", {});
	});

	var scenarios = XHSDevToolsMakeSection(parent, "Bot Scenarios");
	XHSDevToolsMakeLabel(scenarios, "XHSDevToolsMuted", "Focused test hooks for danger response, assignment rebuild, stuck recovery, and respawn/rebind.");
	var scenarioGrid = $.CreatePanel("Panel", scenarios, "");
	scenarioGrid.AddClass("XHSDevToolsGrid");
	var scenarioOptions = [
		{ id: "danger", label: "Danger" },
		{ id: "reassign", label: "Reassign" },
		{ id: "stuck", label: "Stuck" },
		{ id: "respawn", label: "Respawn" }
	];
	for (var scenarioIndex = 0; scenarioIndex < scenarioOptions.length; scenarioIndex++) {
		(function(scenario) {
			XHSDevToolsMakeButton(scenarioGrid, scenario.label, "Small", function() {
				XHSDevToolsSend("bot_run_scenario", { scenario: scenario.id });
			});
		})(scenarioOptions[scenarioIndex]);
	}

	var telemetry = XHSDevToolsMakeSection(parent, "Live Bot Telemetry");
	var rosterEntries = XHSDevToolsBotTableValues(XHSDevToolsBotRoster.players || {});
	if (rosterEntries.length === 0) {
		XHSDevToolsMakeLabel(telemetry, "XHSDevToolsMuted", "No XHS bot is provisioned. Configure allies from the Tools loading screen, then launch.");
		return;
	}

	var cards = $.CreatePanel("Panel", telemetry, "");
	cards.AddClass("XHSDevToolsBotCardGrid");
	for (var botIndex = 0; botIndex < rosterEntries.length; botIndex++) {
		XHSDevToolsRenderBotCard(cards, rosterEntries[botIndex]);
	}
}

function XHSDevToolsRenderPlayers(parent) {
	var players = XHSDevToolsMakeSection(parent, "Player Tools");
	var grid = $.CreatePanel("Panel", players, "");
	grid.AddClass("XHSDevToolsGrid");
	XHSDevToolsMakeButton(grid, "Refresh Heroes", "", function() {
		XHSDevToolsSend("refresh_players", {});
	});
	XHSDevToolsMakeButton(grid, "Max Level", "", function() {
		XHSDevToolsSend("max_level", {});
	});
	XHSDevToolsMakeButton(grid, "+50k Gold", "", function() {
		XHSDevToolsSend("grant_gold", { amount: 50000 });
	});
	XHSDevToolsMakeButton(grid, "+250 Tome Stats", "", function() {
		XHSDevToolsSend("grant_tomes", { amount: 250 });
	});
	XHSDevToolsMakeButton(grid, XHSDevToolsState.invulnerable_players ? "Disable Invuln" : "Enable Invuln", "Warn", function() {
		XHSDevToolsSend("toggle_invulnerable", {});
	});

	var donator = XHSDevToolsMakeSection(parent, "Temporary Donator Status");
	var localPlayerID = Players.GetLocalPlayer();
	var donatorStatuses = XHSDevToolsState.donator_statuses || {};
	var current = donatorStatuses[String(localPlayerID)] || {};
	var hasOverride = current.has_override === true;
	var currentStatus = Number(current.status || 0);
	var temporaryStatus = hasOverride ? Number(current.temporary_status || 0) : null;
	XHSDevToolsMakeLabel(donator, "XHSDevToolsMuted", "Current: " + currentStatus + (hasOverride ? " temporary" : " API"));

	var donatorGrid = $.CreatePanel("Panel", donator, "");
	donatorGrid.AddClass("XHSDevToolsGrid");
	for (var i = 0; i < XHS_DEVTOOLS_DONATOR_STATUSES.length; i++) {
		(function(option) {
			var button = XHSDevToolsMakeButton(donatorGrid, option.label, "Small", function() {
				XHSDevToolsSend("set_temporary_donator_status", { status: option.id });
			});
			button.SetHasClass("Active", hasOverride && temporaryStatus === option.id);
		})(XHS_DEVTOOLS_DONATOR_STATUSES[i]);
	}

	XHSDevToolsMakeButton(donatorGrid, "Restore API", "Small Warn", function() {
		XHSDevToolsSend("set_temporary_donator_status", { clear: 1 });
	});
}

function XHSDevToolsRenderUIPreview(parent) {
	var dialog = XHSDevToolsMakeSection(parent, "VIP Dialog Preview");
	XHSDevToolsMakeLabel(dialog, "XHSDevToolsMuted", "Client-only layout fixtures. They do not advance quests or alter campaign state.");

	var grid = $.CreatePanel("Panel", dialog, "");
	grid.AddClass("XHSDevToolsGrid");
	XHSDevToolsMakeButton(grid, "NEXT", "", function() {
		XHSDevToolsSend("preview_vip_dialog", { mode: "next", player_count: 1 });
	});
	XHSDevToolsMakeButton(grid, "READY · 1 HERO", "Accent", function() {
		XHSDevToolsSend("preview_vip_dialog", { mode: "ready", player_count: 1 });
	});
	XHSDevToolsMakeButton(grid, "READY · 4 HEROES", "Accent", function() {
		XHSDevToolsSend("preview_vip_dialog", { mode: "ready", player_count: 4 });
	});
	XHSDevToolsMakeButton(grid, "READY · 8 HEROES", "Accent", function() {
		XHSDevToolsSend("preview_vip_dialog", { mode: "ready", player_count: 8 });
	});
	XHSDevToolsMakeButton(grid, "CLOSE PREVIEW", "Warn", function() {
		XHSDevToolsSend("close_vip_dialog_preview", {});
	});

	var cinematic = XHSDevToolsMakeSection(parent, "XHS Cinematic Diagnostics");
	XHSDevToolsMakeLabel(cinematic, "XHSDevToolsMuted", "Client buttons bypass the server event path. Server buttons validate XHSCinematics and custom game event delivery.");

	var clientGrid = $.CreatePanel("Panel", cinematic, "");
	clientGrid.AddClass("XHSDevToolsGrid");
	XHSDevToolsMakeButton(clientGrid, "CLIENT BARS", "Accent", function() {
		XHSDevToolsBeginClientCinematic({
			id: "xhs_dev_client_bars",
			hide_hud: 0,
			letterbox_pct: 10,
			transition: 0.5
		});
	});
	XHSDevToolsMakeButton(clientGrid, "CLIENT TITLE", "Accent", function() {
		XHSDevToolsBeginClientCinematic({
			id: "xhs_dev_client_title",
			hide_hud: 0,
			letterbox_pct: 10,
			transition: 0.5,
			title: "X HERO SIEGE",
			subtitle: "Client-side cinematic diagnostic"
		});
	});
	XHSDevToolsMakeButton(clientGrid, "CLIENT FULL 5S", "Warn", function() {
		XHSDevToolsBeginClientCinematic({
			id: "xhs_dev_client_full",
			hide_hud: 1,
			letterbox_pct: 10,
			transition: 0.75,
			duration: 5,
			title: "FINAL WAVE",
			subtitle: "HUD restore should occur automatically"
		});
	});
	XHSDevToolsMakeButton(clientGrid, "CLIENT END", "Danger", XHSDevToolsEndClientCinematic);
	XHSDevToolsMakeButton(clientGrid, "SERVER BARS", "", function() {
		XHSDevToolsSend("preview_cinematic", { mode: "bars" });
	});
	XHSDevToolsMakeButton(clientGrid, "SERVER TITLE", "", function() {
		XHSDevToolsSend("preview_cinematic", { mode: "title" });
	});
	XHSDevToolsMakeButton(clientGrid, "SERVER FULL 5S", "Warn", function() {
		XHSDevToolsSend("preview_cinematic", { mode: "full" });
	});
	XHSDevToolsMakeButton(clientGrid, "FINAL PRESET 8S", "Warn", function() {
		XHSDevToolsSend("preview_cinematic", { mode: "final_wave" });
	});
	XHSDevToolsMakeButton(clientGrid, "SERVER END", "Danger", function() {
		XHSDevToolsSend("end_cinematic_preview", {});
	});
}

function XHSDevToolsRenderCleanup(parent) {
	var cleanup = XHSDevToolsMakeSection(parent, "Cleanup");
	XHSDevToolsMakeLabel(cleanup, "XHSDevToolsMuted", "Cleanup removes dev-spawned units, enemy lane creeps, boss counters, and boss health bars.");
	var grid = $.CreatePanel("Panel", cleanup, "");
	grid.AddClass("XHSDevToolsGrid");
	XHSDevToolsMakeButton(grid, "Cleanup Units/UI", "Warn", function() {
		XHSDevToolsSend("cleanup", {});
	});
	XHSDevToolsMakeButton(grid, "Reset Sandbox", "Danger", function() {
		XHSDevToolsSend("reset_sandbox", {});
	});
}

function XHSDevToolsRender() {
	var root = $("#XHSDevToolsRoot");
	var toolsMode = XHSDevToolsIsToolsMode();
	if (root) {
		root.style.visibility = toolsMode ? "visible" : "collapse";
	}
	if (!toolsMode) {
		return;
	}

	var toggle = $("#XHSDevToolsToggle");
	if (toggle) {
		toggle.SetHasClass("Disabled", !XHSDevToolsState.enabled);
	}

	XHSDevToolsRenderStatus();
	XHSDevToolsRenderSandboxBar();
	XHSDevToolsRenderTimescale();

	var tabs = $("#XHSDevToolsTabs");
	var content = $("#XHSDevToolsContent");
	XHSDevToolsClear(tabs);
	XHSDevToolsClear(content);

	if (!XHSDevToolsState.enabled) {
		XHSDevToolsRenderUnavailable(content);
		return;
	}

	XHSDevToolsRenderTabs();

	if (XHSDevToolsActiveTab === "scenarios") {
		XHSDevToolsRenderScenarios(content);
	} else if (XHSDevToolsActiveTab === "bosses") {
		XHSDevToolsRenderBosses(content);
	} else if (XHSDevToolsActiveTab === "lanes") {
		XHSDevToolsRenderLanes(content);
	} else if (XHSDevToolsActiveTab === "timers") {
		XHSDevToolsRenderTimers(content);
	} else if (XHSDevToolsActiveTab === "bots") {
		XHSDevToolsRenderBots(content);
	} else if (XHSDevToolsActiveTab === "players") {
		XHSDevToolsRenderPlayers(content);
	} else if (XHSDevToolsActiveTab === "ui") {
		XHSDevToolsRenderUIPreview(content);
	} else if (XHSDevToolsActiveTab === "cleanup") {
		XHSDevToolsRenderCleanup(content);
	}
}

function XHSDevToolsOnState(tableName, key, data) {
	if (key !== "state") {
		return;
	}

	XHSDevToolsState = data || {};
	XHSDevToolsHasServerState = true;
	XHSDevToolsRender();
}

function XHSDevToolsReadBotDebugFromRoster() {
	var active = {};
	var rosterEntries = XHSDevToolsBotTableValues(XHSDevToolsBotRoster.players || {});
	for (var i = 0; i < rosterEntries.length; i++) {
		var rosterBot = rosterEntries[i].value || {};
		var playerID = Number(rosterBot.player_id);
		if (isNaN(playerID)) {
			playerID = Number(rosterEntries[i].key);
		}
		if (isNaN(playerID)) {
			continue;
		}
		active[String(playerID)] = true;
		var debug = CustomNetTables.GetTableValue("xhs_bots", "debug_" + playerID);
		if (debug) {
			XHSDevToolsBotDebug[String(playerID)] = debug;
		}
	}

	for (var debugPlayerID in XHSDevToolsBotDebug) {
		if (!active[debugPlayerID]) {
			delete XHSDevToolsBotDebug[debugPlayerID];
		}
	}
}

function XHSDevToolsReadBotNetTables() {
	if (!XHSDevToolsIsToolsMode() || typeof CustomNetTables === "undefined" || !CustomNetTables) {
		return;
	}
	XHSDevToolsBotConfig = CustomNetTables.GetTableValue("xhs_bots", "config") || {};
	XHSDevToolsBotRoster = CustomNetTables.GetTableValue("xhs_bots", "roster") || { count: 0, players: {} };
	XHSDevToolsReadBotDebugFromRoster();
}

function XHSDevToolsShouldRenderBots() {
	var panel = XHSDevToolsPanel();
	return XHSDevToolsIsToolsMode() &&
		XHSDevToolsActiveTab === "bots" &&
		panel &&
		panel.BHasClass("Visible");
}

function XHSDevToolsOnBots(tableName, key, data) {
	if (!XHSDevToolsIsToolsMode()) {
		return;
	}

	if (key === "config") {
		XHSDevToolsBotConfig = data || {};
	} else if (key === "roster") {
		XHSDevToolsBotRoster = data || { count: 0, players: {} };
		XHSDevToolsReadBotDebugFromRoster();
	} else if (String(key).indexOf("debug_") === 0) {
		var playerID = String(key).substring("debug_".length);
		if (data) {
			XHSDevToolsBotDebug[playerID] = data;
		} else {
			delete XHSDevToolsBotDebug[playerID];
		}
	} else {
		return;
	}

	if (XHSDevToolsShouldRenderBots()) {
		XHSDevToolsRender();
	}
}

(function() {
	if (!XHSDevToolsIsToolsMode()) {
		var root = $("#XHSDevToolsRoot");
		if (root) {
			root.style.visibility = "collapse";
		}
		return;
	}

	CustomNetTables.SubscribeNetTableListener("xhs_devtools", XHSDevToolsOnState);
	CustomNetTables.SubscribeNetTableListener("xhs_bots", XHSDevToolsOnBots);
	var state = CustomNetTables.GetTableValue("xhs_devtools", "state");
	if (state) {
		XHSDevToolsState = state;
		XHSDevToolsHasServerState = true;
	}
	XHSDevToolsReadBotNetTables();
	XHSDevToolsRender();
	XHSDevToolsRequestStateLoop();
})();
