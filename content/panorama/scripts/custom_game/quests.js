"use strict";

var XHSQuestState = {
	initialized: false,
	gamePhase: 1,
	creepLevel: 1,
	nextCreepSeconds: null,
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
		final_wave: {
			state: "Inactive",
			text: "Final Wave locked",
			defaultText: "Final Wave locked"
		}
	}
};

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
	"final_wave",
	"kill_ice_towers",
	"kill_final_wave",
	"xhs_phase_3",
	"teleport_top"
];

var XHSQuestUiMeta = {
	defend_castle: { phase: 1, subquest: true },
	kill_rax: { phase: 1, subquest: true },
	muradin_event: { phase: 1, subquest: true },
	farm_event: { phase: 2, subquest: true },
	final_wave: { phase: 2, subquest: true },
	kill_dest_mag: { phase: 2, subquest: true },
	kill_ice_towers: { phase: 2, subquest: true },
	kill_final_wave: { phase: 2, subquest: true },
	teleport_top: { phase: 3, subquest: true, infoTarget: "npc_xhs_paladin" }
};

var XHSHiddenQuestIds = {
	defend_castle: true,
	kill_rax: true
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
	var phase = meta ? meta.phase : 0;
	var subquest = !!isSubquest || !!(meta && meta.subquest);
	var hidden = IsXHSHiddenQuest(questID);

	panel.SetHasClass("SubQuest", subquest);
	panel.SetHasClass("XHSPhase1Quest", phase === 1);
	panel.SetHasClass("XHSPhase2Quest", phase === 2);
	panel.SetHasClass("XHSPhase3Quest", phase === 3);
	panel.SetHasClass("XHSHiddenQuest", hidden);
	panel.style.visibility = hidden ? "collapse" : "visible";
	panel.SetHasClass("HasQuestInfo", !!(meta && meta.infoTarget));
	panel.SetAttributeString("quest_id", questID || "");

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

function SetQuestVisualState(panel, state) {
	if (!panel) {
		return;
	}

	panel.SetHasClass("Active", state === "Active");
	panel.SetHasClass("Inactive", state === "Inactive");
	panel.SetHasClass("Completed", state === "Completed");
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
}

function RefreshStaticQuests() {
	var phase = XHSQuestState.gamePhase || 1;
	var level = XHSQuestState.creepLevel || 1;
	var nextSeconds = XHSQuestState.nextCreepSeconds;

	SetStaticQuest("xhs_phase_1", "Phase 1: Defend the Castle", phase > 1 ? "Completed" : "Active");
	SetStaticQuest("xhs_phase_2", "Phase 2: Break the enemy siege", phase === 2 ? "Active" : (phase > 2 ? "Completed" : "Inactive"));
	SetStaticQuest("xhs_phase_3", "Phase 3: Defeat the enemy leaders", phase >= 3 ? "Active" : "Inactive");

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
	var order = ["muradin_event", "farm_event", "final_wave"];
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

function GetGlobalObjectiveTimerText(id, seconds) {
	if (id === "muradin_event") {
		return "Muradin Event: " + FormatQuestSeconds(seconds);
	}

	if (id === "farm_event") {
		return "Farm Event: " + FormatQuestSeconds(seconds);
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
	for (var i = 0; i < XHSStaticQuests.length; i++) {
		SetStaticQuest(XHSStaticQuests[i].id, XHSStaticQuests[i].text, XHSStaticQuests[i].state);
	}
	ApplyQuestStateSnapshot(CustomNetTables.GetTableValue("xhs_quest_state", "state"));
	RefreshStaticQuests();
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
		return;

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
	ReorderXHSQuestPanels(ZonePanel);
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
