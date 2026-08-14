"use strict";

var XHSQuestState = {
	initialized: false,
	gamePhase: 1,
	creepLevel: 1,
	nextCreepSeconds: null,
	specialEventSeconds: null,
	muradinEventStarted: false,
	globalObjectives: {
		muradin_event: {
			state: "Active",
			text: "Muradin Event in --:--",
			defaultText: "Muradin Event in --:--"
		},
		farm_event: {
			state: "Inactive",
			text: "Farm Event locked",
			defaultText: "Farm Event locked"
		},
		phase2_creeps: {
			state: "Inactive",
			text: "Phase 2 creeps locked",
			defaultText: "Phase 2 creeps locked"
		},
		final_wave: {
			state: "Inactive",
			text: "Final Wave locked",
			defaultText: "Final Wave locked"
		}
	}
};

var XHSQuestLogPinnedBackground = false;
var XHSQuestLogCollapsed = false;
var XHSQuestLogTemporaryRevealToken = 0;
var XHSQuestLogSuppressActivationEffects = false;
var XHSCollapsedMainQuestPhases = {};

var XHSMainQuestPhases = {
	xhs_phase_1: 1,
	xhs_phase_2: 2,
	xhs_phase_3: 3
};

function RefreshXHSQuestLogBackgroundToggle() {
	var questLog = $("#QuestLog");
	var button = $("#QuestLogPinButton");

	if (questLog) {
		questLog.SetHasClass("QuestLogPinnedBackground", XHSQuestLogPinnedBackground);
	}

	if (button) {
		button.SetHasClass("Checked", XHSQuestLogPinnedBackground);
	}
}

function RefreshXHSQuestLogCollapsedState() {
	var questLog = $("#QuestLog");
	var button = $("#QuestLogCollapseButton");

	if (questLog) {
		questLog.SetHasClass("QuestLogCollapsed", XHSQuestLogCollapsed);
	}

	if (button) {
		button.SetHasClass("QuestLogCollapsed", XHSQuestLogCollapsed);
	}
}

function SaveXHSQuestLogCollapsedState() {
	if (typeof GameUI !== "undefined" && GameUI.CustomUIConfig) {
		GameUI.CustomUIConfig().xhsQuestLogCollapsed = XHSQuestLogCollapsed;
	}
}

function ToggleXHSQuestLogCollapsed() {
	XHSQuestLogCollapsed = !XHSQuestLogCollapsed;
	XHSQuestLogTemporaryRevealToken++;

	var questLog = $("#QuestLog");
	if (questLog) {
		questLog.SetHasClass("QuestLogTemporaryReveal", false);
	}

	SaveXHSQuestLogCollapsedState();
	RefreshXHSQuestLogCollapsedState();
}

function TemporarilyRevealXHSQuestLog(seconds) {
	if (!XHSQuestLogCollapsed) {
		return;
	}

	var questLog = $("#QuestLog");
	if (!questLog) {
		return;
	}

	seconds = Math.max(1.0, Number(seconds) || 4.0);
	XHSQuestLogTemporaryRevealToken++;
	var token = XHSQuestLogTemporaryRevealToken;

	questLog.SetHasClass("QuestLogTemporaryReveal", true);
	RefreshXHSQuestLogCollapsedState();

	$.Schedule(seconds, function () {
		if (token !== XHSQuestLogTemporaryRevealToken) {
			return;
		}

		var currentQuestLog = $("#QuestLog");
		if (currentQuestLog) {
			currentQuestLog.SetHasClass("QuestLogTemporaryReveal", false);
		}
	});
}

function PulseXHSQuestPanel(panel) {
	if (!panel || XHSQuestLogSuppressActivationEffects) {
		return;
	}

	panel.SetHasClass("QuestJustActivated", false);
	$.Schedule(0.01, function () {
		if (panel && panel.IsValid && panel.IsValid()) {
			panel.SetHasClass("QuestJustActivated", true);
		}
	});

	$.Schedule(2.2, function () {
		if (panel && panel.IsValid && panel.IsValid()) {
			panel.SetHasClass("QuestJustActivated", false);
		}
	});
}

function NotifyXHSQuestBecameActive(panel) {
	if (!panel || XHSQuestLogSuppressActivationEffects) {
		return;
	}

	TemporarilyRevealXHSQuestLog(5.0);
	PulseXHSQuestPanel(panel);
}

function ToggleXHSQuestLogBackground() {
	XHSQuestLogPinnedBackground = !XHSQuestLogPinnedBackground;

	if (typeof GameUI !== "undefined" && GameUI.CustomUIConfig) {
		GameUI.CustomUIConfig().xhsQuestLogPinnedBackground = XHSQuestLogPinnedBackground;
	}

	RefreshXHSQuestLogBackgroundToggle();
}

function BindXHSQuestLogBackgroundToggle() {
	var button = $("#QuestLogPinButton");
	if (!button) {
		return;
	}

	button.SetPanelEvent("onmouseover", function () {
		$.DispatchEvent("DOTAShowTextTooltip", button, "Keep quest panel background dark");
	});

	button.SetPanelEvent("onmouseout", function () {
		$.DispatchEvent("DOTAHideTextTooltip");
	});
}

function BindXHSQuestLogCollapseToggle() {
	var button = $("#QuestLogCollapseButton");
	if (!button) {
		return;
	}

	button.SetPanelEvent("onmouseover", function () {
		$.DispatchEvent("DOTAShowTextTooltip", button, XHSQuestLogCollapsed ? "Show quest panel" : "Hide quest panel");
	});

	button.SetPanelEvent("onmouseout", function () {
		$.DispatchEvent("DOTAHideTextTooltip");
	});
}

function GetXHSQuestPhase(questID) {
	if (XHSMainQuestPhases[questID]) {
		return XHSMainQuestPhases[questID];
	}

	var meta = XHSQuestUiMeta[questID] || null;
	return meta && meta.phase ? meta.phase : 0;
}

function LoadXHSCollapsedMainQuestPhases() {
	if (typeof GameUI === "undefined" || !GameUI.CustomUIConfig) {
		return;
	}

	var saved = GameUI.CustomUIConfig().xhsCollapsedMainQuestPhases || {};
	XHSCollapsedMainQuestPhases = {};

	for (var phase in saved) {
		if (!saved.hasOwnProperty(phase)) {
			continue;
		}

		if (saved[phase] === true) {
			XHSCollapsedMainQuestPhases[phase] = true;
		}
	}
}

function SaveXHSCollapsedMainQuestPhases() {
	if (typeof GameUI !== "undefined" && GameUI.CustomUIConfig) {
		GameUI.CustomUIConfig().xhsCollapsedMainQuestPhases = XHSCollapsedMainQuestPhases;
	}
}

function ApplyXHSQuestPanelVisibility(panel) {
	if (!panel) {
		return;
	}

	var questID = panel.GetAttributeString("quest_id", panel.id || "");
	var phase = Number(panel.GetAttributeString("xhs_phase", "0")) || 0;
	var hidden = IsXHSHiddenQuest(questID);
	var collapsedByMainQuest = panel.BHasClass("SubQuest")
		&& phase > 0
		&& XHSCollapsedMainQuestPhases[phase] === true
		&& !panel.BHasClass("Active");

	panel.SetHasClass("XHSCollapsedByMainQuest", collapsedByMainQuest);
	panel.style.visibility = hidden || collapsedByMainQuest ? "collapse" : "visible";
}

function RefreshXHSQuestCollapseState() {
	var questsContainer = $("#QuestsContainer");
	if (!questsContainer) {
		return;
	}

	var questPanels = questsContainer.FindChildrenWithClassTraverse("Quest");
	for (var i = 0; i < questPanels.length; i++) {
		var panel = questPanels[i];
		if (!panel) {
			continue;
		}

		var questID = panel.GetAttributeString("quest_id", panel.id || "");
		var mainQuestPhase = XHSMainQuestPhases[questID] || 0;
		panel.SetHasClass("XHSMainQuestCollapsed", mainQuestPhase > 0 && XHSCollapsedMainQuestPhases[mainQuestPhase] === true);
		ApplyXHSQuestPanelVisibility(panel);
	}
}

function ToggleXHSMainQuestPhase(phase) {
	phase = Number(phase) || 0;
	if (phase <= 0) {
		return;
	}

	XHSCollapsedMainQuestPhases[phase] = XHSCollapsedMainQuestPhases[phase] !== true;
	SaveXHSCollapsedMainQuestPhases();
	RefreshXHSQuestCollapseState();
}

function ApplyXHSMainQuestToggle(panel, questID) {
	if (!panel) {
		return;
	}

	var phase = XHSMainQuestPhases[questID] || 0;
	panel.SetHasClass("CollapsibleMainQuest", phase > 0);
	panel.SetHasClass("XHSMainQuestCollapsed", phase > 0 && XHSCollapsedMainQuestPhases[phase] === true);

	if (phase <= 0) {
		return;
	}

	panel.hittest = true;
	panel.hittestchildren = true;
	panel.SetPanelEvent("onactivate", function () {
		ToggleXHSMainQuestPhase(phase);
	});
}

var XHSStaticQuests = [
	{
		id: "xhs_phase_1",
		text: "Phase 1: Defend the Castle",
		type: "Holdout",
		state: "Active"
	},
	{
		id: "xhs_creep_level_2",
		text: "Creep level 2 in --:--",
		type: "Explore",
		state: "Active",
		subquest: true
	},
	{
		id: "xhs_creep_level_3",
		text: "Creep level 3 locked",
		type: "Explore",
		state: "Inactive",
		subquest: true
	},
	{
		id: "xhs_creep_level_4",
		text: "Creep level 4 locked",
		type: "Explore",
		state: "Inactive",
		subquest: true
	},
	{
		id: "muradin_event",
		text: "Muradin Event in --:--",
		type: "Explore",
		state: "Active",
		subquest: true
	},
	{
		id: "xhs_phase_2",
		text: "Phase 2: Break the enemy siege",
		type: "Holdout",
		state: "Inactive"
	},
	{
		id: "farm_event",
		text: "Farm Event locked",
		type: "Explore",
		state: "Inactive",
		subquest: true
	},
	{
		id: "phase2_creeps",
		text: "Phase 2 creeps locked",
		type: "Explore",
		state: "Inactive",
		subquest: true
	},
	{
		id: "final_wave",
		text: "Final Wave locked",
		type: "Explore",
		state: "Inactive",
		subquest: true
	},
	{
		id: "xhs_phase_3",
		text: "Phase 3: Defeat the enemy leaders",
		type: "Holdout",
		state: "Inactive"
	}
];

var XHSQuestUiOrder = [
	"xhs_phase_1",
	"defend_castle",
	"kill_rax",
	"xhs_creep_level_2",
	"muradin_event",
	"xhs_creep_level_3",
	"xhs_creep_level_4",
	"xhs_phase_2",
	"farm_event",
	"kill_dest_mag",
	"phase2_creeps",
	"final_wave",
	"kill_ice_towers",
	"kill_final_wave",
	"xhs_phase_3",
	"teleport_top",
	"kill_mag",
	"clear_grom_vanguard",
	"kill_grom",
	"kill_illidan",
	"kill_balanar",
	"kill_proudmoore",
	"teleport_arthas",
	"kill_arthas",
	"kill_banehallow",
	"kill_lich_king",
	"kill_spirit_master"
];

var XHSQuestUiMeta = {
	xhs_creep_level_2: { phase: 1, subquest: true },
	xhs_creep_level_3: { phase: 1, subquest: true },
	xhs_creep_level_4: { phase: 1, subquest: true },
	defend_castle: { phase: 1, subquest: true },
	kill_rax: { phase: 1, subquest: true },
	muradin_event: { phase: 1, subquest: true },
	farm_event: { phase: 2, subquest: true },
	phase2_creeps: { phase: 2, subquest: true },
	final_wave: { phase: 2, subquest: true },
	kill_dest_mag: { phase: 2, subquest: true },
	kill_ice_towers: { phase: 2, subquest: true },
	kill_final_wave: { phase: 2, subquest: true },
	teleport_top: { phase: 3, subquest: true, infoTarget: "npc_xhs_paladin" },
	kill_mag: { phase: 3, subquest: true },
	clear_grom_vanguard: { phase: 3, subquest: true },
	kill_grom: { phase: 3, subquest: true, infoTarget: "npc_dota_hero_grom_hellscream" },
	kill_illidan: { phase: 3, subquest: true, infoTarget: "npc_dota_hero_illidan" },
	kill_balanar: { phase: 3, subquest: true, infoTarget: "npc_dota_hero_balanar" },
	kill_proudmoore: { phase: 3, subquest: true, infoTarget: "npc_dota_hero_proudmoore" },
	teleport_arthas: { phase: 3, subquest: true, infoTarget: "npc_xhs_paladin_2" },
	kill_arthas: { phase: 3, subquest: true },
	kill_banehallow: { phase: 3, subquest: true },
	kill_lich_king: { phase: 3, subquest: true },
	kill_spirit_master: { phase: 3, subquest: true }
};

var XHSHiddenQuestIds = {
	defend_castle: true,
	kill_rax: true,
	kill_ice_towers: true
};

function IsXHSHiddenQuest(questID) {
	return !!(questID && XHSHiddenQuestIds[questID]);
}

function FormatQuestSeconds(seconds) {
	seconds = Math.max(0, Number(seconds) || 0);
	var minutes = Math.floor(seconds / 60);
	var rest = seconds - minutes * 60;
	return minutes + ":" + (rest < 10 ? "0" : "") + rest;
}

function ApplyXHSQuestMetadata(panel, questID, isSubquest) {
	if (!panel) {
		return;
	}

	var meta = XHSQuestUiMeta[questID] || null;
	var phase = GetXHSQuestPhase(questID);
	var subquest = !!isSubquest || !!(meta && meta.subquest);
	var hidden = IsXHSHiddenQuest(questID);

	panel.SetHasClass("SubQuest", subquest);
	panel.SetHasClass("XHSPhase1Quest", phase === 1);
	panel.SetHasClass("XHSPhase2Quest", phase === 2);
	panel.SetHasClass("XHSPhase3Quest", phase === 3);
	panel.SetHasClass("XHSHiddenQuest", hidden);
	panel.SetHasClass("HasQuestInfo", !!(meta && meta.infoTarget));
	panel.SetAttributeString("quest_id", questID || "");
	panel.SetAttributeString("xhs_phase", phase.toString());
	ApplyXHSMainQuestToggle(panel, questID);
	ApplyXHSQuestPanelVisibility(panel);

	var infoButton = panel.FindChildInLayoutFile("QuestInfoButton");
	if (infoButton) {
		infoButton.SetPanelEvent("onactivate", function () {
			OnQuestInfoPressed(questID);
		});
	}
}

function OnQuestInfoPressed(questID) {
	var meta = XHSQuestUiMeta[questID] || null;
	if (!meta || !meta.infoTarget) {
		return;
	}

	GameEvents.SendCustomGameEventToServer("xhs_quest_focus", {
		quest_id: questID,
		target: meta.infoTarget
	});
}

function ReorderXHSQuestPanels(zonePanel) {
	if (!zonePanel) {
		return;
	}

	var container = zonePanel.FindChildInLayoutFile("ZoneQuestsContainer");
	if (!container || !container.MoveChildAfter) {
		return;
	}

	var previous = null;
	for (var i = 0; i < XHSQuestUiOrder.length; i++) {
		var child = container.FindChild(XHSQuestUiOrder[i]);
		if (!child) {
			continue;
		}

		if (previous) {
			container.MoveChildAfter(child, previous);
		}
		previous = child;
	}

	RefreshXHSQuestCollapseState();
}

function EnsureQuestZone(zoneName, zoneLabel) {
	var QuestsContainerPanel = $("#QuestsContainer");
	if (QuestsContainerPanel === null) {
		return null;
	}

	var ZonePanel = QuestsContainerPanel.FindChild(zoneName);
	if (ZonePanel === null) {
		ZonePanel = $.CreatePanel("Panel", QuestsContainerPanel, zoneName);
		ZonePanel.BLoadLayout("file://{resources}/layout/custom_game/quest_zone.xml", false, false);
	}

	var label = ZonePanel.FindChildInLayoutFile("ZoneName");
	if (label) {
		label.text = zoneLabel || $.Localize("#" + zoneName);
	}

	return ZonePanel;
}

function EnsureQuestPanel(zonePanel, quest) {
	if (!zonePanel || !quest) {
		return null;
	}

	var ZoneQuestsContainer = zonePanel.FindChildInLayoutFile("ZoneQuestsContainer");
	if (ZoneQuestsContainer === null) {
		return null;
	}

	var QuestPanel = ZoneQuestsContainer.FindChild(quest.id);
	if (QuestPanel === null) {
		QuestPanel = $.CreatePanel("Panel", ZoneQuestsContainer, quest.id);
		QuestPanel.BLoadLayout("file://{resources}/layout/custom_game/quest.xml", false, false);
		QuestPanel.AddClass("XHSStaticQuest");
		ApplyXHSQuestMetadata(QuestPanel, quest.id, !!quest.subquest);

		var icon = QuestPanel.FindChildInLayoutFile("QuestIcon");
		if (icon) {
			icon.SetHasClass(quest.type || "Explore", true);
		}

		QuestPanel.SetDialogVariableInt("completed", 0);
		QuestPanel.SetDialogVariableInt("complete_limit", 1);
		QuestPanel.SetHasClass("ShowNumbers", false);
		QuestPanel.SetHasClass("Optional", false);
	}

	ApplyXHSQuestMetadata(QuestPanel, quest.id, !!quest.subquest);

	return QuestPanel;
}

function AutoCollapseXHSCompletedMainQuestPhase(panel, state, previousState) {
	if (!panel || state !== "Completed" || previousState === "Completed") {
		return;
	}

	var questID = panel.GetAttributeString("quest_id", panel.id || "");
	var phase = XHSMainQuestPhases[questID] || 0;
	if (phase <= 0 || XHSCollapsedMainQuestPhases[phase] === true) {
		return;
	}

	XHSCollapsedMainQuestPhases[phase] = true;
	SaveXHSCollapsedMainQuestPhases();
	RefreshXHSQuestCollapseState();
}

function SetQuestVisualState(panel, state) {
	if (!panel) {
		return;
	}

	var previousState = panel.GetAttributeString("xhs_state", "");
	panel.SetHasClass("Active", state === "Active");
	panel.SetHasClass("Inactive", state === "Inactive");
	panel.SetHasClass("Completed", state === "Completed");
	panel.SetAttributeString("xhs_state", state || "");
	ApplyXHSQuestPanelVisibility(panel);
	AutoCollapseXHSCompletedMainQuestPhase(panel, state, previousState);

	if (state === "Active" && previousState !== "" && previousState !== "Active") {
		NotifyXHSQuestBecameActive(panel);
	}
}

function SetStaticQuest(id, text, state) {
	var zonePanel = EnsureQuestZone("xhs_holdout", $.Localize("#xhs_holdout"));
	if (!zonePanel) {
		return;
	}

	var quest = null;
	for (var i = 0; i < XHSStaticQuests.length; i++) {
		if (XHSStaticQuests[i].id === id) {
			quest = XHSStaticQuests[i];
			break;
		}
	}

	if (!quest) {
		return;
	}

	var panel = EnsureQuestPanel(zonePanel, quest);
	if (!panel) {
		return;
	}

	var label = panel.FindChildInLayoutFile("QuestText");
	if (label) {
		label.text = text || quest.text;
	}

	SetQuestVisualState(panel, state || quest.state);
	ReorderXHSQuestPanels(zonePanel);
	RefreshXHSQuestCollapseState();
}

function GetEffectiveQuestPhase() {
	var phase = Math.max(1, Number(XHSQuestState.gamePhase) || 1);
	for (var id in XHSQuestState.globalObjectives) {
		if (!XHSQuestState.globalObjectives.hasOwnProperty(id)) {
			continue;
		}

		var meta = XHSQuestUiMeta[id] || null;
		if (!meta || !meta.phase) {
			continue;
		}

		var objective = XHSQuestState.globalObjectives[id];
		var state = objective ? objective.state : "";
		if (state === "Active" || state === "Completed") {
			phase = Math.max(phase, meta.phase);
		}
	}

	var questsContainer = $("#QuestsContainer");
	if (questsContainer) {
		var questPanels = questsContainer.FindChildrenWithClassTraverse("Quest");
		for (var i = 0; i < questPanels.length; i++) {
			var panel = questPanels[i];
			if (!panel || (!panel.BHasClass("Active") && !panel.BHasClass("Completed"))) {
				continue;
			}

			var questID = panel.GetAttributeString("quest_id", panel.id || "");
			var panelMeta = XHSQuestUiMeta[questID] || null;
			if (panelMeta && panelMeta.phase) {
				phase = Math.max(phase, panelMeta.phase);
			}
		}
	}

	if (phase > (Number(XHSQuestState.gamePhase) || 1)) {
		XHSQuestState.gamePhase = phase;
	}

	return phase;
}

function IsXHSQuestCompleted(questID) {
	var questsContainer = $("#QuestsContainer");
	if (!questsContainer || !questID) {
		return false;
	}

	var zones = questsContainer.FindChildrenWithClassTraverse("Zone");
	for (var i = 0; i < zones.length; i++) {
		var zoneQuestsContainer = zones[i].FindChildInLayoutFile("ZoneQuestsContainer");
		if (!zoneQuestsContainer) {
			continue;
		}

		var panel = zoneQuestsContainer.FindChild(questID);
		if (panel) {
			return panel.BHasClass("Completed");
		}
	}

	return false;
}

function RefreshPhaseQuestHeaders(phase) {
	phase = phase || GetEffectiveQuestPhase();
	var phase3Completed = IsXHSQuestCompleted("kill_spirit_master");
	SetStaticQuest("xhs_phase_1", "Phase 1: Defend the Castle", phase > 1 ? "Completed" : "Active");
	SetStaticQuest("xhs_phase_2", "Phase 2: Break the enemy siege", phase === 2 ? "Active" : (phase > 2 ? "Completed" : "Inactive"));
	SetStaticQuest("xhs_phase_3", "Phase 3: Defeat the enemy leaders", phase3Completed ? "Completed" : (phase >= 3 ? "Active" : "Inactive"));
}

function RefreshStaticQuests() {
	var phase = GetEffectiveQuestPhase();
	var level = XHSQuestState.creepLevel || 1;
	var nextSeconds = XHSQuestState.nextCreepSeconds;

	RefreshPhaseQuestHeaders(phase);

	for (var i = 2; i <= 4; i++) {
		var state = "Inactive";
		var text = "Creep level " + i + " locked";

		if (phase > 1 || i <= level) {
			state = "Completed";
			text = "Creep level " + i + " completed";
		} else if (i === level + 1 && phase === 1) {
			state = "Active";
			text = "Creep level " + i + " in " + (nextSeconds === null ? "--:--" : FormatQuestSeconds(nextSeconds));
		}

		SetStaticQuest("xhs_creep_level_" + i, text, state);
	}

	RefreshGlobalObjectiveQuests();
}

function RefreshGlobalObjectiveQuests() {
	for (var id in XHSQuestState.globalObjectives) {
		if (!XHSQuestState.globalObjectives.hasOwnProperty(id)) {
			continue;
		}

		var objective = XHSQuestState.globalObjectives[id];
		SetStaticQuest(id, objective.text || objective.defaultText, objective.state || "Inactive");
	}
}

function GetActiveGlobalObjectiveId() {
	var order = ["muradin_event", "farm_event", "phase2_creeps", "final_wave"];
	for (var i = 0; i < order.length; i++) {
		var id = order[i];
		var objective = XHSQuestState.globalObjectives[id];
		if (objective && objective.state === "Active") {
			return id;
		}
	}

	return null;
}

function SetGlobalObjective(id, text, state, seconds) {
	var objective = XHSQuestState.globalObjectives[id];
	if (!objective) {
		return;
	}

	if (state) {
		objective.state = state;
	}

	if (text) {
		objective.text = text;
	} else if (seconds !== undefined && seconds !== null) {
		objective.text = GetGlobalObjectiveTimerText(id, seconds);
	} else if (!objective.text) {
		objective.text = objective.defaultText;
	}

	RefreshGlobalObjectiveQuests();
}

function RemoveQuestPanelById(questID) {
	var questsContainer = $("#QuestsContainer");
	if (!questsContainer || !questID) {
		return;
	}

	var zones = questsContainer.FindChildrenWithClassTraverse("Zone");
	for (var i = 0; i < zones.length; i++) {
		var zoneQuestsContainer = zones[i].FindChildInLayoutFile("ZoneQuestsContainer");
		if (!zoneQuestsContainer) {
			continue;
		}

		var questPanel = zoneQuestsContainer.FindChild(questID);
		if (questPanel) {
			questPanel.DeleteAsync(0.0);
		}
	}
}

function ActivateFinalWaveWaitObjective() {
	var objective = XHSQuestState.globalObjectives.final_wave;
	if (!objective || objective.state === "Completed") {
		return;
	}

	var phase2Creeps = XHSQuestState.globalObjectives.phase2_creeps;
	if (phase2Creeps && phase2Creeps.state === "Active") {
		return;
	}

	var seconds = XHSQuestState.specialEventSeconds;
	var text = seconds !== null && seconds !== undefined
		? GetGlobalObjectiveTimerText("final_wave", seconds)
		: "Final Wave in --:--";

	SetGlobalObjective("final_wave", text, "Active");
}

function ApplyHiddenQuestSideEffects(data) {
	if (!data) {
		return;
	}

	if (data["QuestName"] === "kill_ice_towers") {
		RemoveQuestPanelById("kill_ice_towers");
		ActivateFinalWaveWaitObjective();
		RefreshStaticQuests();
	}
}

function GetGlobalObjectiveTimerText(id, seconds) {
	if (id === "muradin_event") {
		return "Muradin Event: " + FormatQuestSeconds(seconds);
	}

	if (id === "farm_event") {
		return "Farm Event: " + FormatQuestSeconds(seconds);
	}

	if (id === "phase2_creeps") {
		return "Phase 2 creeps: " + FormatQuestSeconds(seconds);
	}

	if (id === "final_wave") {
		return "Final Wave in " + FormatQuestSeconds(seconds);
	}

	return FormatQuestSeconds(seconds);
}

function IsQuestSnapshotTruthy(value) {
	return value === true || value === 1 || value === "1" || value === "true";
}

function GetQuestSnapshotNumber(value, fallback) {
	var number = Number(value);
	if (isNaN(number)) {
		return fallback;
	}

	return number;
}

function ApplyGlobalObjectiveSnapshot(id, source, snapshot) {
	var objective = XHSQuestState.globalObjectives[id];
	if (!objective || !source) {
		return;
	}

	if (source.state) {
		objective.state = source.state;
	}

	if (source.defaultText || source.default_text) {
		objective.defaultText = source.defaultText || source.default_text;
	}

	var sourceSeconds = source.seconds;
	var specialEventSeconds = snapshot ? snapshot.special_event_seconds : null;
	var seconds = sourceSeconds !== undefined && sourceSeconds !== null
		? GetQuestSnapshotNumber(sourceSeconds, null)
		: GetQuestSnapshotNumber(specialEventSeconds, null);

	if (objective.state === "Active" && seconds !== null && seconds > 0) {
		objective.text = GetGlobalObjectiveTimerText(id, seconds);
	} else if (source.text) {
		objective.text = source.text;
	} else if (!objective.text) {
		objective.text = objective.defaultText;
	}

	if (id === "muradin_event" && (IsQuestSnapshotTruthy(source.started) || objective.state === "Completed")) {
		XHSQuestState.muradinEventStarted = true;
	}
}

function ApplyQuestStateSnapshot(data) {
	if (!data) {
		return;
	}

	XHSQuestState.gamePhase = Math.max(1, GetQuestSnapshotNumber(data.game_phase, XHSQuestState.gamePhase || 1));
	XHSQuestState.creepLevel = Math.max(1, GetQuestSnapshotNumber(data.creep_level, XHSQuestState.creepLevel || 1));

	if (data.creep_seconds !== undefined && data.creep_seconds !== null) {
		XHSQuestState.nextCreepSeconds = Math.max(0, GetQuestSnapshotNumber(data.creep_seconds, 0));
	}

	if (data.special_event_seconds !== undefined && data.special_event_seconds !== null) {
		XHSQuestState.specialEventSeconds = Math.max(0, GetQuestSnapshotNumber(data.special_event_seconds, 0));
	}

	if (IsQuestSnapshotTruthy(data.muradin_event_started)) {
		XHSQuestState.muradinEventStarted = true;
	}

	var objectives = data.global_objectives || data.globalObjectives || {};
	for (var id in XHSQuestState.globalObjectives) {
		if (!XHSQuestState.globalObjectives.hasOwnProperty(id)) {
			continue;
		}

		ApplyGlobalObjectiveSnapshot(id, objectives[id], data);
	}

	RefreshStaticQuests();
}

function InitStaticQuestLog() {
	if (XHSQuestState.initialized) {
		return;
	}

	if ($("#QuestsContainer") === null) {
		$.Schedule(0.2, InitStaticQuestLog);
		return;
	}

	XHSQuestState.initialized = true;
	if (typeof GameUI !== "undefined" && GameUI.CustomUIConfig) {
		XHSQuestLogPinnedBackground = GameUI.CustomUIConfig().xhsQuestLogPinnedBackground === true;
		XHSQuestLogCollapsed = GameUI.CustomUIConfig().xhsQuestLogCollapsed === true;
	}
	LoadXHSCollapsedMainQuestPhases();
	BindXHSQuestLogBackgroundToggle();
	BindXHSQuestLogCollapseToggle();
	RefreshXHSQuestLogBackgroundToggle();
	RefreshXHSQuestLogCollapsedState();

	XHSQuestLogSuppressActivationEffects = true;
	for (var i = 0; i < XHSStaticQuests.length; i++) {
		SetStaticQuest(XHSStaticQuests[i].id, XHSStaticQuests[i].text, XHSStaticQuests[i].state);
	}
	ApplyQuestStateSnapshot(CustomNetTables.GetTableValue("xhs_quest_state", "state"));
	RefreshStaticQuests();
	RefreshXHSQuestCollapseState();
	XHSQuestLogSuppressActivationEffects = false;
}

function OnQuestActivated( data ) {
	var QuestsContainerPanel = $( "#QuestsContainer" );
	if ( QuestsContainerPanel === null ) 
		return;

	var szZoneName = data["ZoneName"];
	var szQuestName = data["QuestName"];
	var szQuestType = data["QuestType"];
	if ( szZoneName === null || szQuestName === null )
		return;
	if ( IsXHSHiddenQuest( szQuestName ) )
	{
		ApplyHiddenQuestSideEffects(data);
		return;
	}

	var ZonePanel = QuestsContainerPanel.FindChild( szZoneName );
	if ( ZonePanel === null )
	{
		ZonePanel = $.CreatePanel( "Panel", QuestsContainerPanel, szZoneName );
		ZonePanel.BLoadLayout( "file://{resources}/layout/custom_game/quest_zone.xml", false, false );
		ZonePanel.FindChildInLayoutFile( "ZoneName" ).text = $.Localize( "#" + szZoneName );
	}

	var ZoneQuestsContainer = ZonePanel.FindChildInLayoutFile( "ZoneQuestsContainer" );
	if ( ZoneQuestsContainer === null )
		return;

	var QuestPanel = ZoneQuestsContainer.FindChild( szQuestName );
	if ( QuestPanel === null )
	{
		QuestPanel = $.CreatePanel( "Panel", ZoneQuestsContainer, szQuestName );
		QuestPanel.BLoadLayout( "file://{resources}/layout/custom_game/quest.xml", false, false );
		QuestPanel.FindChildInLayoutFile( "QuestIcon" ).SetHasClass( szQuestType, true );
		QuestPanel.FindChildInLayoutFile( "QuestText" ).text =  $.Localize( "#" + szQuestName );
		ApplyXHSQuestMetadata(QuestPanel, szQuestName, false);

		QuestPanel.SetDialogVariableInt( "completed", data["Completed"] );
		QuestPanel.SetDialogVariableInt( "complete_limit", data["CompleteLimit"] );
		QuestPanel.SetHasClass( "ShowNumbers", data["CompleteLimit"] !== 1 );
		QuestPanel.SetHasClass( "Optional", data["Optional"] );
	}

	ApplyXHSQuestMetadata(QuestPanel, szQuestName, false);
	QuestPanel.SetHasClass( "Completed", data["Completed"] >= data["CompleteLimit"] );
	QuestPanel.SetHasClass( "Active", data["Completed"] < data["CompleteLimit"] );
	QuestPanel.SetHasClass( "Inactive", false );
	QuestPanel.SetAttributeString("xhs_state", data["Completed"] < data["CompleteLimit"] ? "Active" : "Completed");
	ApplyXHSQuestPanelVisibility(QuestPanel);
	if (data["Completed"] < data["CompleteLimit"]) {
		NotifyXHSQuestBecameActive(QuestPanel);
	}
	ReorderXHSQuestPanels(ZonePanel);
	RefreshXHSQuestCollapseState();
	RefreshPhaseQuestHeaders();
	ZonePanel.SetHasClass( "Completed", false );
}
GameEvents.Subscribe( "quest_activated", OnQuestActivated );


function HideQuestCompletePopup( )
{
	var DungeonQuestCompleteRoot = $( "#DungeonQuestCompleteRoot" );
	if (DungeonQuestCompleteRoot == null) {
		return;
	}

	DungeonQuestCompleteRoot.SetHasClass( $("#DungeonQuestCompleteZoneName").text, false );
	DungeonQuestCompleteRoot.SetHasClass( "Stars1", false );
	DungeonQuestCompleteRoot.SetHasClass( "Stars2", false );
	DungeonQuestCompleteRoot.SetHasClass( "Stars3", false );

	DungeonQuestCompleteRoot.SetHasClass("PopupDisplayed", false);
	DungeonQuestCompleteRoot.SetHasClass("PopupDismissed", true);
}

function ShowQuestCompletePopup( data )
{
	if ( data && IsXHSHiddenQuest( data["QuestName"] ) )
	{
		return;
	}

	var DungeonQuestCompleteRoot = $( "#DungeonQuestCompleteRoot" );
	if(DungeonQuestCompleteRoot == null)
	{
		return;
	}

	if ( data["ZoneCompleted"] )
	{
		DungeonQuestCompleteRoot.SetHasClass( data["ZoneName"], true );
		DungeonQuestCompleteRoot.SetHasClass( "Stars" + data["ZoneStars"].toString(), true );
	}

	DungeonQuestCompleteRoot.SetDialogVariableInt( "completed", data["Completed"] );
	DungeonQuestCompleteRoot.SetDialogVariableInt( "complete_limit", data["CompleteLimit"] );
	DungeonQuestCompleteRoot.SetHasClass( "ShowNumbers", data["CompleteLimit"] !== 1 );
	DungeonQuestCompleteRoot.SetHasClass( "Completed", data["Completed"] >= data["CompleteLimit"] );

	DungeonQuestCompleteRoot.SetDialogVariableInt( "xp_reward", data["XPReward"] );
	DungeonQuestCompleteRoot.SetHasClass( "XPReward", data["XPReward"] > 0 );
	DungeonQuestCompleteRoot.SetDialogVariableInt( "gold_reward", data["GoldReward"] );
	DungeonQuestCompleteRoot.SetHasClass( "GoldReward", data["GoldReward"] > 0 );

	if( !(data["ZoneName"] === null) )
	{
		DungeonQuestCompleteRoot.SetDialogVariable( "zone_name", $.Localize( "#" + data["ZoneName"] ) );
	}
	else
	{
		DungeonQuestCompleteRoot.SetDialogVariable( "zone_name", "" );
	}

	if( !(data["QuestName"] === null) )
	{
		DungeonQuestCompleteRoot.SetDialogVariable( "quest_name", $.Localize( "#" + data["QuestName"] ) );
	}
	else
	{
		DungeonQuestCompleteRoot.SetDialogVariable( "quest_name", "" );
	}
	DungeonQuestCompleteRoot.SetHasClass("PopupDisplayed", true);
	DungeonQuestCompleteRoot.SetHasClass("PopupDismissed", false);

	$.Schedule( 10.0, HideQuestCompletePopup );
}

function OnQuestCompleted( data )
{
	if ( data && IsXHSHiddenQuest( data["QuestName"] ) )
	{
		ApplyHiddenQuestSideEffects(data);
		return;
	}

	if ( data["Completed"] === data["CompleteLimit"] && ( data["Optional"] || data["ZoneCompleted"] ) )
	{
		if ( data["ZoneCompleted"] )
		{
			Game.EmitSound( "Dungeon.Stinger01" );
		}
		else
		{
			Game.EmitSound( "Dungeon.Stinger03" );
		}
		ShowQuestCompletePopup( data );
	}

	var QuestsContainerPanel = $( "#QuestsContainer" );
	if ( QuestsContainerPanel === null ) 
		return;

	var szZoneName = data["ZoneName"];
	var szQuestName = data["QuestName"];
	if ( szZoneName === null || szQuestName === null )
		return;
	var ZonePanel = QuestsContainerPanel.FindChild( szZoneName );
	if ( ZonePanel === null )
		return;

	var ZoneQuestsContainer = ZonePanel.FindChildInLayoutFile( "ZoneQuestsContainer" );
	if ( ZoneQuestsContainer === null )
		return;

	var QuestPanel = ZoneQuestsContainer.FindChild( szQuestName );
	if ( QuestPanel === null )
		return;

	QuestPanel.SetDialogVariableInt( "completed", data["Completed"] );
	QuestPanel.SetDialogVariableInt( "complete_limit", data["CompleteLimit"] );
	QuestPanel.SetHasClass( "ShowNumbers", data["CompleteLimit"] !== 1 );
	QuestPanel.SetHasClass( "Completed", data["Completed"] >= data["CompleteLimit"] );
	QuestPanel.SetHasClass( "Active", data["Completed"] < data["CompleteLimit"] );
	QuestPanel.SetHasClass( "Inactive", false );
	QuestPanel.SetAttributeString("xhs_state", data["Completed"] >= data["CompleteLimit"] ? "Completed" : "Active");
	ApplyXHSQuestPanelVisibility(QuestPanel);

	QuestPanel.SetDialogVariableInt( "xp_reward", data["XPReward"] );
	QuestPanel.SetHasClass( "XPReward", data["XPReward"] > 0 );
	QuestPanel.SetDialogVariableInt( "gold_reward", data["GoldReward"] );
	QuestPanel.SetHasClass( "GoldReward", data["GoldReward"] > 0 );

	var QuestsInZone = ZoneQuestsContainer.FindChildrenWithClassTraverse( "Quest" );
	var bAllComplete = true;
	var i = 0;
	for ( i = 0; i < QuestsInZone.length; i++ ) {
		var Quest = QuestsInZone[i];
		if ( Quest !== null && Quest.BHasClass( "Completed" ) === false )
		{
			bAllComplete = false;
			break;
		}
	}

	ZonePanel.SetHasClass( "Completed", bAllComplete || data["ZoneCompleted"] );
	RefreshPhaseQuestHeaders();
	RefreshXHSQuestCollapseState();
}

GameEvents.Subscribe( "quest_completed", OnQuestCompleted );

function OnPlayerEnteredZone( data )
{
	var QuestsContainerPanel = $( "#QuestsContainer" );
	if ( QuestsContainerPanel === null ) 
		return;

	var Zones = QuestsContainerPanel.FindChildrenWithClassTraverse( "Zone" );
	for( var i in Zones )
	{
		var Zone = Zones[i];
		if ( Zone === null )
			continue;

		var bAllHidden = true;
		var ZoneQuestsContainer = Zone.FindChildInLayoutFile( "ZoneQuestsContainer" );
		if ( ZoneQuestsContainer === null )
			continue; 

		var Quests = ZoneQuestsContainer.FindChildrenWithClassTraverse( "Quest" );
		for ( var j in Quests )
		{
			var Quest = Quests[j];
			if ( Quest === null )
				return;

			var bIsCurrentZone = Zone.id === data["ZoneName"];
			var bIsOptional = Quest.BHasClass( "Optional" );
			var bHideOutOfZone = !bIsCurrentZone && bIsOptional;
			Quest.SetHasClass( "HideOutOfZone", bHideOutOfZone );

			var bQuestCompleted = Quest.BHasClass( "Completed" );
			if ( !bHideOutOfZone || ( !bQuestCompleted && !bIsOptional ) )
			{
				bAllHidden = false;
			}
		}

		Zone.SetHasClass( "NotInZone", bAllHidden );
	}
}

GameEvents.Subscribe( "zone_enter", OnPlayerEnteredZone );

function OnQuestCountdownTimer(data) {
	if (!data || (data.timer_name !== "creep_level" && data.timer_name !== "special_event")) {
		return;
	}

	var minute10 = Number(data.timer_minute_10 || 0);
	var minute01 = Number(data.timer_minute_01 || 0);
	var second10 = Number(data.timer_second_10 || 0);
	var second01 = Number(data.timer_second_01 || 0);
	var seconds = ((minute10 * 10 + minute01) * 60) + (second10 * 10 + second01);

	if (data.timer_name === "creep_level") {
		XHSQuestState.nextCreepSeconds = seconds;
		RefreshStaticQuests();
		return;
	}

	XHSQuestState.specialEventSeconds = seconds;
	var activeObjectiveId = GetActiveGlobalObjectiveId();
	if (activeObjectiveId) {
		SetGlobalObjective(activeObjectiveId, GetGlobalObjectiveTimerText(activeObjectiveId, seconds), "Active");
	}
}

function OnGlobalObjectiveUpdate(data) {
	if (!data || !data.id) {
		return;
	}

	if (data.id === "muradin_event") {
		if (data.started === 1 || data.started === true || data.state === "Completed") {
			XHSQuestState.muradinEventStarted = true;
		}
	}

	SetGlobalObjective(data.id, data.text || null, data.state || null, data.seconds);
	RefreshStaticQuests();
}

function OnCreepLevelUpdate(data) {
	XHSQuestState.creepLevel = Math.max(1, Number(data && data.level) || 1);
	XHSQuestState.nextCreepSeconds = null;
	RefreshStaticQuests();
}

function OnGamePhaseUpdate(data) {
	XHSQuestState.gamePhase = Math.max(1, Number(data && data.phase) || 1);
	RefreshStaticQuests();
}

GameEvents.Subscribe("countdown_timer", OnQuestCountdownTimer);
GameEvents.Subscribe("xhs_global_objective_update", OnGlobalObjectiveUpdate);
GameEvents.Subscribe("xhs_creep_level_update", OnCreepLevelUpdate);
GameEvents.Subscribe("xhs_game_phase_update", OnGamePhaseUpdate);

CustomNetTables.SubscribeNetTableListener("xhs_quest_state", function (tableName, key, data) {
	if (key === "state") {
		ApplyQuestStateSnapshot(data);
	}
});

$.Schedule(0.1, InitStaticQuestLog);
