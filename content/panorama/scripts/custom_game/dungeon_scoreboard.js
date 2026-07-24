"use strict"
CustomNetTables.SubscribeNetTableListener( "zone_scores", ZoneScoresReceived )
CustomNetTables.SubscribeNetTableListener( "player_zone_locations", UpdatePlayerZones )
CustomNetTables.SubscribeNetTableListener( "fragment_quests", FragmentQuestsReceived )
GameEvents.Subscribe( "zone_complete", OnZoneCompleted );

var KILL_EVENT_THRESHOLDS = [100, 200, 400, 500, 750];
var KILL_EVENT_VISIBLE_RATIO = 0.8;
var scoreboard_supporter_hover = null;
var scoreboard_supporter_hover_player_id = -1;
var scoreboard_hud_layer_applied = false;
var scoreboard_hud_layer_retry_scheduled = false;

function GetScoreboardHudAncestor(panel) {
	var current = panel;
	while (current) {
		if (current.id === "Hud") {
			return current;
		}
		current = current.GetParent ? current.GetParent() : null;
	}
	return null;
}

function GetScoreboardHudDirectChild(panel, hud) {
	var current = panel;
	var parent = current && current.GetParent ? current.GetParent() : null;
	while (current && parent && parent !== hud) {
		current = parent;
		parent = current.GetParent ? current.GetParent() : null;
	}
	return parent === hud ? current : null;
}

function ScheduleScoreboardHudLayerRetry() {
	if (scoreboard_hud_layer_applied || scoreboard_hud_layer_retry_scheduled) {
		return;
	}

	scoreboard_hud_layer_retry_scheduled = true;
	$.Schedule(0.5, function () {
		scoreboard_hud_layer_retry_scheduled = false;
		EnsureScoreboardAboveHudElements();
	});
}

function EnsureScoreboardAboveHudElements() {
	if (scoreboard_hud_layer_applied) {
		return true;
	}

	var host = $.GetContextPanel();
	var hud = GetScoreboardHudAncestor(host);
	var hudElements = hud && hud.FindChildTraverse ? hud.FindChildTraverse("HUDElements") : null;
	var hudElementsChild = GetScoreboardHudDirectChild(hudElements, hud);
	if (!host || !hud || !hudElementsChild || typeof host.SetParent !== "function" || typeof hud.MoveChildAfter !== "function") {
		ScheduleScoreboardHudLayerRetry();
		return false;
	}

	try {
		if (!host.GetParent || host.GetParent() !== hud) {
			host.SetParent(hud);
		}
		if (!host.GetParent || host.GetParent() !== hud) {
			ScheduleScoreboardHudLayerRetry();
			return false;
		}

		hud.MoveChildAfter(host, hudElementsChild);
		scoreboard_hud_layer_applied = true;
		return true;
	} catch (error) {
		ScheduleScoreboardHudLayerRetry();
		return false;
	}
}

function intToARGB(i) 
{ 
                return ('00' + ( i & 0xFF).toString( 16 ) ).substr( -2 ) +
                                               ('00' + ( ( i >> 8 ) & 0xFF ).toString( 16 ) ).substr( -2 ) +
                                               ('00' + ( ( i >> 16 ) & 0xFF ).toString( 16 ) ).substr( -2 ) + 
                                                ('00' + ( ( i >> 24 ) & 0xFF ).toString( 16 ) ).substr( -2 );
}

function ToggleMute( nRowID )
{
	var muteButton =  $("#ScoreboardTeamContainer").FindChildTraverse( "PlayerMuteButton" + nRowID );
	if ( muteButton !== null ) {
		var nPlayerID = muteButton.GetAttributeInt( "player_id", -1 );

		if ( nPlayerID !== -1 ) {
			var newIsMuted = !Game.IsPlayerMuted( nPlayerID );

			Game.SetPlayerMuted( nPlayerID, newIsMuted );
			muteButton.SetHasClass( "player_muted", Game.IsPlayerMuted( nPlayerID ) );
		} else {
			$.Msg( "No valid id" );
		}
	}
}

function GetLocalPlayerId() {
	var localPlayerId = 0;
	var localPlayerInfo = Game.GetLocalPlayerInfo();

	if(typeof(localPlayerInfo) !== "undefined") {
		localPlayerId = localPlayerInfo.player_id;
	}

	if (Players.IsLocalPlayerInPerspectiveCamera()) {
		//get local player info for selected portrait unit
		localPlayerId = Players.GetPerspectivePlayerId();
	}

	return localPlayerId;
}

function GetScoreboardSupporterTier(playerInfo) {
	if (!playerInfo) {
		return 0;
	}

	var tier = Number(playerInfo.tier_id || playerInfo.supporter_tier || 0) || 0;
	if (tier <= 0) {
		var status = Number(playerInfo.donator_level || playerInfo.donator_status || 0) || 0;
		var statusToTier = {
			6: 1,
			5: 2,
			4: 3,
			7: 4,
			8: 5,
			9: 5
		};
		tier = statusToTier[status] || 0;
	}

	return Math.max(0, Math.min(5, Math.floor(tier)));
}

function ClearScoreboardSupporterTierClasses(panel) {
	if (!panel) {
		return;
	}

	for (var tier = 0; tier <= 5; tier++) {
		panel.RemoveClass("ScoreboardSupporterTier" + tier);
	}
}

function GetScoreboardSupporterBadgeLetter(tier, tierName) {
	tier = Math.max(0, Math.min(5, Math.floor(Number(tier) || 0)));
	if (tier <= 0) {
		return "";
	}

	tierName = (tierName || "").toString();
	if (tierName.length > 0 && tierName !== "Supporter" && tierName !== "Supporter Pass") {
		return tierName.charAt(0).toUpperCase();
	}

	return ["", "D", "G", "E", "S", "E"][tier] || "";
}

function ScoreboardToNumber(value, fallbackValue) {
	var numberValue = Number(value);
	if (isNaN(numberValue)) {
		return fallbackValue || 0;
	}

	return numberValue;
}

function ScoreboardSafeCall(callback, fallbackValue) {
	try {
		var value = callback();
		return value === undefined || value === null ? fallbackValue : value;
	} catch (error) {
		return fallbackValue;
	}
}

function IsScoreboardPlayerValid(playerID) {
	playerID = Number(playerID);
	if (isNaN(playerID) || playerID < 0 || playerID > 7) {
		return false;
	}

	return !!ScoreboardSafeCall(function () {
		return Game.GetPlayerInfo(playerID);
	}, null);
}

function GetScoreboardNetTableValue(tableName, key) {
	if (key === undefined || key === null) {
		return null;
	}

	return ScoreboardSafeCall(function () {
		return CustomNetTables.GetTableValue(tableName, key.toString());
	}, null);
}

function EnsureScoreboardSupporterHover() {
	if (scoreboard_supporter_hover && scoreboard_supporter_hover.IsValid && scoreboard_supporter_hover.IsValid()) {
		return scoreboard_supporter_hover;
	}

	if (typeof XHSSupporterHover === "undefined" || !XHSSupporterHover.Create) {
		return null;
	}

	scoreboard_supporter_hover = XHSSupporterHover.Create($.GetContextPanel(), "Scoreboard", { className: "ScoreboardXHSSupporterHover" });
	return scoreboard_supporter_hover;
}

function ShowScoreboardSupporterHover(playerID, anchorPanel) {
	if (playerID === undefined || playerID === null || playerID < 0 || !anchorPanel) {
		return;
	}

	var playerInfo = GetScoreboardNetTableValue("supporter_pass_player", playerID) || {};
	var hover = EnsureScoreboardSupporterHover();
	if (!hover || typeof XHSSupporterHover === "undefined") {
		return;
	}

	scoreboard_supporter_hover_player_id = playerID;
	var data = XHSSupporterHover.GetPlayerData(playerID, {
		tableData: playerInfo,
		heroName: ScoreboardSafeCall(function () { return Players.GetPlayerSelectedHero(playerID); }, ""),
	});
	XHSSupporterHover.Update(hover, "Scoreboard", data);
	XHSSupporterHover.PositionNearAnchor(anchorPanel, hover, $.GetContextPanel(), { gap: 8, width: 336, height: 330 });
	XHSSupporterHover.Show(anchorPanel, hover);

	$.Schedule(0.01, function () {
		if (scoreboard_supporter_hover_player_id == playerID && hover && hover.IsValid && hover.IsValid()) {
			XHSSupporterHover.PositionNearAnchor(anchorPanel, hover, $.GetContextPanel(), { gap: 8, width: 336, height: 330 });
		}
	});
}

function HideScoreboardSupporterHover() {
	scoreboard_supporter_hover_player_id = -1;

	if (scoreboard_supporter_hover && scoreboard_supporter_hover.IsValid && scoreboard_supporter_hover.IsValid()) {
		XHSSupporterHover.Hide(null, scoreboard_supporter_hover);
	}
}

function EnsureScoreboardSupporterDecor(imagePanel, displaySlot) {
	if (!imagePanel) {
		return null;
	}

	var sweep = imagePanel.FindChildTraverse("ScoreboardSupporterSweep" + displaySlot);
	if (!sweep) {
		sweep = $.CreatePanel("Panel", imagePanel, "ScoreboardSupporterSweep" + displaySlot);
		sweep.AddClass("ScoreboardSupporterSweep");
		sweep.hittest = false;
	}

	var badge = imagePanel.FindChildTraverse("ScoreboardSupporterBadge" + displaySlot);
	if (!badge) {
		badge = $.CreatePanel("Panel", imagePanel, "ScoreboardSupporterBadge" + displaySlot);
		badge.AddClass("ScoreboardSupporterBadge");
		badge.hittest = false;

		var label = $.CreatePanel("Label", badge, "ScoreboardSupporterBadgeLabel" + displaySlot);
		label.AddClass("ScoreboardSupporterBadgeLabel");
		label.text = "";
		label.hittest = false;
	}

	return badge;
}

function ApplyScoreboardSupporterVisuals(playerID, displaySlot, playerInfo) {
	var teamContainer = $("#ScoreboardTeamContainer");
	if (!teamContainer) {
		return;
	}

	var tier = GetScoreboardSupporterTier(playerInfo);
	var heroImageName = displaySlot === 0 ? "PlayerImage" : "HeroImage" + displaySlot;
	var heroImage = teamContainer.FindChildTraverse(heroImageName);
	var imagePanel = heroImage ? heroImage.GetParent() : null;
	var row = imagePanel ? imagePanel.GetParent() : null;
	var xpPanel = $.GetContextPanel().FindChildTraverse("es-player-xp" + displaySlot);
	var badge = EnsureScoreboardSupporterDecor(imagePanel, displaySlot);
	var tierName = playerInfo && (playerInfo.tier_name || playerInfo.supporter_tier_name || playerInfo.title) || "Supporter";

	if (badge) {
		badge.hittest = false;
	}

	if (imagePanel) {
		imagePanel.hittest = true;
		imagePanel.hittestchildren = false;
		if (row) {
			row.hittest = true;
			row.hittestchildren = true;
			(function (rowPanel, anchorPanel, targetPlayerID) {
				rowPanel.SetPanelEvent("onmouseover", function () {
					ShowScoreboardSupporterHover(targetPlayerID, anchorPanel);
				});

				rowPanel.SetPanelEvent("onmouseout", function () {
					HideScoreboardSupporterHover();
				});
			})(row, imagePanel, playerID);
		}
		(function (anchorPanel, targetPlayerID) {
			anchorPanel.SetPanelEvent("onmouseover", function () {
				ShowScoreboardSupporterHover(targetPlayerID, anchorPanel);
			});

			anchorPanel.SetPanelEvent("onmouseout", function () {
				HideScoreboardSupporterHover();
			});
		})(imagePanel, playerID);
	}

	if (heroImage) {
		heroImage.hittest = false;
	}

	ClearScoreboardSupporterTierClasses(row);
	ClearScoreboardSupporterTierClasses(imagePanel);
	ClearScoreboardSupporterTierClasses(heroImage);
	ClearScoreboardSupporterTierClasses(xpPanel);
	ClearScoreboardSupporterTierClasses(badge);

	if (tier > 0) {
		if (row) { row.AddClass("ScoreboardSupporterTier" + tier); }
		if (imagePanel) { imagePanel.AddClass("ScoreboardSupporterTier" + tier); }
		if (heroImage) { heroImage.AddClass("ScoreboardSupporterTier" + tier); }
		if (xpPanel) { xpPanel.AddClass("ScoreboardSupporterTier" + tier); }
		if (badge) {
			badge.AddClass("ScoreboardSupporterTier" + tier);
			var label = badge.FindChildTraverse("ScoreboardSupporterBadgeLabel" + displaySlot);
			if (label) {
				label.text = GetScoreboardSupporterBadgeLetter(tier, tierName);
			}
		}
	}
}

function SetScoreboardDisplaySlotVisible(displaySlot, visible) {
	var teamContainer = $("#ScoreboardTeamContainer");
	if (!teamContainer || displaySlot <= 0) {
		return;
	}

	var heroImage = teamContainer.FindChildTraverse("HeroImage" + displaySlot);
	var imagePanel = heroImage ? heroImage.GetParent() : null;
	var row = imagePanel ? imagePanel.GetParent() : null;
	if (row) {
		row.style.visibility = visible ? "visible" : "collapse";
		row.hittest = visible;
		row.hittestchildren = visible;
	}
}

function UpdatePlayerImages() {
	var teamContainer = $("#ScoreboardTeamContainer");
	if (!teamContainer) {
		return;
	}

	var localPlayerId = GetLocalPlayerId();
	if (!IsScoreboardPlayerValid(localPlayerId)) {
		return;
	}

	var playerImage = teamContainer.FindChildTraverse( "PlayerImage" );
	var playerColorBar = teamContainer.FindChildTraverse( "PlayerColorBar");
	var colorInt = ScoreboardSafeCall(function () { return Players.GetPlayerColor(localPlayerId); }, 0);
	var colorString = "#" + intToARGB( colorInt );

	if (playerImage) {
		playerImage.heroname = ScoreboardSafeCall(function () { return Players.GetPlayerSelectedHero(localPlayerId); }, "");
	}
	if (playerColorBar) {
		playerColorBar.style.backgroundColor = colorString;
	}
//	friendlyBarImage.heroname = Players.GetPlayerSelectedHero( localPlayerId );

	var actualPlayerInfo = 1;
	var localSupporterInfo = GetScoreboardNetTableValue("supporter_pass_player", localPlayerId);
	ApplyScoreboardSupporterVisuals(localPlayerId, 0, localSupporterInfo);
	var localXPPanel = $.GetContextPanel().FindChildTraverse("es-player-xp0");
	if (localXPPanel != undefined && localSupporterInfo != undefined) {
		_ScoreboardUpdater_UpdatePlayerPanelXP(0, localXPPanel, localSupporterInfo);
	}
	for (var displaySlot = 1; displaySlot <= 7; displaySlot++) {
		SetScoreboardDisplaySlotVisible(displaySlot, false);
	}

	for(var i = 0; i < 8; i++) {
		var player_info = GetScoreboardNetTableValue("supporter_pass_player", i);

		if(i == localPlayerId)
		{
			continue;
		}

		if (!IsScoreboardPlayerValid(i) || actualPlayerInfo > 7) {
			continue;
		}
		SetScoreboardDisplaySlotVisible(actualPlayerInfo, true);

		var ImbaXP_Panel = $.GetContextPanel().FindChildTraverse("es-player-xp" + actualPlayerInfo);

		if (ImbaXP_Panel != undefined && player_info != undefined) {
			// set xp values for the display slot occupied by this player.
			_ScoreboardUpdater_UpdatePlayerPanelXP(actualPlayerInfo, ImbaXP_Panel, player_info);
		}

		var muteButton =  teamContainer.FindChildTraverse( "PlayerMuteButton" + actualPlayerInfo );
		if (muteButton) {
			muteButton.SetAttributeInt( "player_id", i );
			muteButton.SetHasClass( "player_muted", ScoreboardSafeCall(function () { return Game.IsPlayerMuted(i); }, false) )
		}

		var heroImage = teamContainer.FindChildTraverse( "HeroImage" + actualPlayerInfo );
		if (heroImage) {
			heroImage.heroname = ScoreboardSafeCall(function () { return Players.GetPlayerSelectedHero(i); }, "");
		}
		ApplyScoreboardSupporterVisuals(i, actualPlayerInfo, player_info);

		var heroColorBar = teamContainer.FindChildTraverse( "HeroColorBar" + actualPlayerInfo );
		var colorInt = ScoreboardSafeCall(function () { return Players.GetPlayerColor(i); }, 0);
		var colorString = "#" + intToARGB( colorInt );
		if (heroColorBar) {
			heroColorBar.style.backgroundColor = colorString;
		}

//		var friendlyBarImage = $("#PartyPortraits").FindChildTraverse( "PartyPortrait" + actualPlayerInfo ).FindChildTraverse( "HeroImage" );
//		friendlyBarImage.heroname = Players.GetPlayerSelectedHero( i );

		actualPlayerInfo++;
	}
}

function GetNextKillEvent(kills) {
	for (var i = 0; i < KILL_EVENT_THRESHOLDS.length; i++) {
		var target = KILL_EVENT_THRESHOLDS[i];
		if (kills < target) {
			return target;
		}
	}

	return null;
}

function GetDisplayedKillCount(playerId, zoneData) {
	var playerInfo = ScoreboardSafeCall(function () { return Game.GetPlayerInfo(playerId); }, null);
	if (playerInfo && typeof(playerInfo.player_kills) !== "undefined") {
		return playerInfo.player_kills;
	}

	if (zoneData && zoneData[playerId] && typeof(zoneData[playerId]["Kills"]) !== "undefined") {
		return zoneData[playerId]["Kills"];
	}

	return 0;
}

function EnsureKillEventHint(displaySlot) {
	var teamContainer = $("#ScoreboardTeamContainer");
	if (!teamContainer) {
		return null;
	}

	var row = teamContainer.GetChild(displaySlot + 1);
	if (!row) {
		return null;
	}

	var scoreContainer = row.FindChildTraverse("ScoreLabelsContainer");
	if (!scoreContainer) {
		return null;
	}

	var hint = scoreContainer.FindChildTraverse("KillEventHint" + displaySlot);
	if (hint) {
		return hint;
	}

	hint = $.CreatePanel("Panel", scoreContainer, "KillEventHint" + displaySlot);
	hint.AddClass("KillEventHint");
	hint.hittest = false;

	var glow = $.CreatePanel("Panel", hint, "");
	glow.AddClass("KillEventHintGlow");
	glow.hittest = false;

	var label = $.CreatePanel("Label", hint, "KillEventHintLabel" + displaySlot);
	label.AddClass("KillEventHintLabel");
	label.text = "";
	label.hittest = false;

	return hint;
}

function ApplyKillEventHintSupporterTier(hint, playerId) {
	if (!hint) {
		return;
	}

	ClearScoreboardSupporterTierClasses(hint);

	var playerInfo = null;
	if (playerId !== undefined && playerId !== null && playerId >= 0) {
		playerInfo = GetScoreboardNetTableValue("supporter_pass_player", playerId);
	}

	var tier = GetScoreboardSupporterTier(playerInfo);
	hint.AddClass("ScoreboardSupporterTier" + tier);
}

function UpdateKillEventHint(displaySlot, playerId, kills) {
	var hint = EnsureKillEventHint(displaySlot);
	if (!hint) {
		return;
	}

	ApplyKillEventHintSupporterTier(hint, playerId);

	var nextTarget = GetNextKillEvent(kills);
	var remaining = nextTarget === null ? 0 : nextTarget - kills;
	var visible = nextTarget !== null && remaining > 0 && kills >= Math.ceil(nextTarget * KILL_EVENT_VISIBLE_RATIO);

	hint.SetHasClass("KillEventHintVisible", visible);

	var label = hint.FindChildTraverse("KillEventHintLabel" + displaySlot);
	if (label) {
		label.text = remaining === 1 ? "1 kill remaining" : remaining + " kills remaining";
	}
}

function UpdateKillEventHints(zoneData, localPlayerId) {
	var localKills = GetDisplayedKillCount(localPlayerId, zoneData);
	UpdateKillEventHint(0, localPlayerId, localKills);

	var displaySlot = 1;
	for (var playerId = 0; playerId < 8; playerId++) {
		if (playerId === localPlayerId) {
			continue;
		}
		if (!IsScoreboardPlayerValid(playerId) || displaySlot > 7) {
			continue;
		}

		UpdateKillEventHint(displaySlot, playerId, GetDisplayedKillCount(playerId, zoneData));
		displaySlot++;
	}
}

function GetFragmentQuestList(state) {
	if (!state || !state.selected) {
		return [];
	}

	var selected = state.selected;
	var quests = [];
	for (var i = 1; i <= 3; i++) {
		if (selected[i.toString()]) {
			quests.push(selected[i.toString()]);
		}
	}

	if (quests.length === 0) {
		for (var key in selected) {
			if (selected.hasOwnProperty(key)) {
				quests.push(selected[key]);
			}
		}
	}

	return quests;
}

function GetFragmentQuestProgressPercent(quest) {
	if (!quest) {
		return 0;
	}

	var stars = Number(quest.stars || 0);
	if (stars > 0) {
		return Math.max(0, Math.min(100, (stars / 3) * 100));
	}

	var thresholds = quest.thresholds || {};
	var current = Number(quest.current_value || 0);
	var target = Number(thresholds["3"] || thresholds[3] || thresholds["2"] || thresholds[2] || thresholds["1"] || thresholds[1] || 0);

	if (target <= 0 || quest.score_mode === "lower_is_better" || quest.score_mode === "time_elapsed") {
		return 0;
	}

	return Math.max(0, Math.min(100, (current / target) * 100));
}

function AddFragmentQuestStars(parent, stars) {
	for (var i = 1; i <= 3; i++) {
		var star = $.CreatePanel("Panel", parent, "FragmentQuestStar" + parent.id + i);
		star.AddClass("FragmentQuestStar");
		star.SetHasClass("FragmentQuestStarActive", i <= stars);
	}
}

function BuildFragmentQuestCard(parent, quest, index, backendStatus) {
	var card = $.CreatePanel("Panel", parent, "FragmentQuestCard" + index);
	card.AddClass("FragmentQuestCard");
	card.SetHasClass("FragmentQuestCardComplete", Number(quest.stars || 0) >= 3);
	card.SetHasClass("FragmentQuestCardActive", quest.active === true || quest.active === 1);

	var header = $.CreatePanel("Panel", card, "FragmentQuestHeader" + index);
	header.AddClass("FragmentQuestHeader");

	var title = $.CreatePanel("Label", header, "FragmentQuestTitle" + index);
	title.AddClass("FragmentQuestTitle");
	title.text = quest.title || quest.template_id || "Fragment Quest";

	var stars = $.CreatePanel("Panel", header, "FragmentQuestStars" + index);
	stars.AddClass("FragmentQuestStars");
	AddFragmentQuestStars(stars, Number(quest.stars || 0));

	var description = $.CreatePanel("Label", card, "FragmentQuestDescription" + index);
	description.AddClass("FragmentQuestDescription");
	description.text = quest.description || "";

	var meta = $.CreatePanel("Panel", card, "FragmentQuestMeta" + index);
	meta.AddClass("FragmentQuestMeta");

	var progress = $.CreatePanel("Label", meta, "FragmentQuestProgress" + index);
	progress.AddClass("FragmentQuestProgress");
	progress.text = quest.progress_text || "0";

	var thresholds = $.CreatePanel("Label", meta, "FragmentQuestThresholds" + index);
	thresholds.AddClass("FragmentQuestThresholds");
	thresholds.text = quest.threshold_text || "";

	var progressBar = $.CreatePanel("Panel", card, "FragmentQuestProgressBar" + index);
	progressBar.AddClass("FragmentQuestProgressBar");

	var progressFill = $.CreatePanel("Panel", progressBar, "FragmentQuestProgressFill" + index);
	progressFill.AddClass("FragmentQuestProgressFill");
	progressFill.style.width = GetFragmentQuestProgressPercent(quest) + "%";

	var reward = $.CreatePanel("Label", card, "FragmentQuestReward" + index);
	reward.AddClass("FragmentQuestReward");
	var previewFragments = Number(quest.preview_fragments !== undefined ? quest.preview_fragments : quest.fragments_awarded || 0);
	var confirmedFragments = Number(quest.confirmed_fragments_awarded || 0);
	var maxFragments = Number(quest.reward_per_star || 0) * 3;
	if (backendStatus === "synced" && (quest.confirmed === true || quest.confirmed === 1)) {
		reward.text = "+" + confirmedFragments + " fragments confirmed";
	} else if (backendStatus === "error") {
		reward.text = "Earned: +" + previewFragments + " / " + maxFragments + " fragments";
	} else {
		reward.text = "Earned: +" + previewFragments + " / " + maxFragments + " fragments";
	}
}

function UpdateFragmentQuests(state) {
	var container = $("#ZoneStarRequirementsDesc");
	if (!container) {
		return;
	}

	container.RemoveAndDeleteChildren();

	var quests = GetFragmentQuestList(state);
	if (quests.length === 0) {
		var empty = $.CreatePanel("Label", container, "FragmentQuestEmpty");
		empty.AddClass("FragmentQuestEmpty");
		empty.text = "Loading fragment quests...";
		return;
	}

	for (var i = 0; i < quests.length; i++) {
		BuildFragmentQuestCard(container, quests[i], i + 1, state.backend_status || "pending");
	}
}

function FragmentQuestsReceived(tableName, key, data) {
	if (key !== "state") {
		return;
	}

	UpdateFragmentQuests(data);
}

function UpdateZoneScores( zoneName )
{
	if ($.GetContextPanel().BHasClass("ZoneComplete"))
		return;

	UpdatePlayerImages();

	var localPlayerId = GetLocalPlayerId();
	if (!IsScoreboardPlayerValid(localPlayerId)) {
		return;
	}

	var teamContainer = $("#ScoreboardTeamContainer");
	if (!teamContainer) {
		return;
	}

	var zonePlayerEntry = GetScoreboardNetTableValue("player_zone_locations", localPlayerId);
	var PlayerZoneName = zonePlayerEntry && zonePlayerEntry["ZoneName"] ? zonePlayerEntry["ZoneName"] : "";
	$.GetContextPanel().SetHasClass( "ActiveZone", zoneName === PlayerZoneName );

	var zoneData = GetScoreboardNetTableValue("zone_scores", zoneName);
	var zoneDataValid = !!zoneData;
	if ( zoneDataValid === true )
	{
		var secondsRaw = Math.floor( zoneData["CompletionTime"] );
		var minutes = secondsRaw / 60;
		var seconds = minutes < 1 ? secondsRaw : secondsRaw - ( Math.floor( minutes ) * 60 );
		$("#ScoreboardZone").text = $.Localize( "#" + zoneName );
		$("#ScoreboardDescription").text = $.Localize("#Dungeon_ZoneDesc_" + zoneName); //todo fillin
		$("#ScoreboardZoneTimeLabel").text = Math.floor( minutes ) + ":" + ( "0" + seconds ).slice(-2);
		$("#NewBestPanelStars").SetHasClass( "Hidden", true );
		$("#NewBestPanelTime").SetHasClass( "Hidden", true );

		var bZoneComplete = $.GetContextPanel().BHasClass( "Complete_" + zoneName );
		var nScore = GameUI.GetPlayerScoreboardScore( "Event_dungeon_ep_1_" + zoneName);
		var nPBStars = 3 - ( nScore >> 16 );
		var nPBTime = Math.floor( nScore & 0xFFFF );
		var nMinutes = nPBTime / 60;
		var nSeconds = nMinutes < 1 ? nPBTime : nPBTime - ( Math.floor( nMinutes ) * 60 );
		$("#ScoreboardZoneBestStars").SetHasClass( "Hidden", nScore == -1 );
		$("#OldBestTime").SetHasClass( "Hidden", nScore == -1 );
		$("#ScoreboardZoneBestStars").SetDialogVariableInt( "best_stars", nPBStars );
		$("#OldBestTime").SetDialogVariable( "best_time", Math.floor(nMinutes) + ":" + ("0" + nSeconds).slice(-2) );
		if ( bZoneComplete )
		{
			if ( zoneData["ZoneStars"] > nPBStars )
			{
				$("#NewBestPanelStars").SetHasClass( "Hidden", false );
			}
			if ( secondsRaw < nPBTime )
			{
				$("#NewBestPanelTime").SetHasClass( "Hidden", false );
			}
		}

		var exposedTableProperties = ["Kills", "Deaths", "Potions"]
//		var exposedTableProperties = ["Kills", "Deaths", "Items","GoldBags", "Potions", "ReviveTime", "Damage", "Healing"]

		$.GetContextPanel().SetHasClass( "Stars0", false );
		$.GetContextPanel().SetHasClass( "Stars1", false );
		$.GetContextPanel().SetHasClass( "Stars2", false );
		$.GetContextPanel().SetHasClass( "Stars3", false );
		$.GetContextPanel().SetHasClass( "Stars" + zoneData["ZoneStars"].toString(), true );

		//go through player count
		for (var key = 0; key < exposedTableProperties.length; key++) 
		{
			var tablePropertyName = exposedTableProperties[key]
			var keyTotal = 0;
			var playerValues = [0, 0, 0, 0, 0, 0, 0, 0];
//			var playerValues = [0, 0, 0, 0];
			//go through table values and sum them into totals
			for (var i = 0; i < 8; i++) 
			{
				if(typeof(zoneData[i]) != "undefined") 
				{
					var playerValue = zoneData[i][tablePropertyName];
					if (tablePropertyName === "Kills") {
						playerValue = GetDisplayedKillCount(i, zoneData);
					}

					if(typeof(playerValue) != "undefined")
					{
						playerValues[i] = playerValue;
						keyTotal += playerValue;
					}
				}
			}

			//prop the category variable to the container (e.g. "Deaths": 0)
			teamContainer.SetDialogVariableInt(tablePropertyName.toLowerCase(), keyTotal);

			var iNonPlayerCalculated = 1;
			for(var i = 0; i < 8; i++)
			{
				if (i !== localPlayerId && (!IsScoreboardPlayerValid(i) || iNonPlayerCalculated > 7)) {
					continue;
				}

				var ratioBarPanel;

				//handle special case where players have not done anything yet
				var percentage = 25.0;
				if(keyTotal != 0)
				{
					percentage = (playerValues[i] / keyTotal) * 100.0;
				}

				//get the correct panel based on adjusted player id
				if(i === localPlayerId)
				{
					var ratioBarPanelName = "#RatioBar" + tablePropertyName + "0";
					ratioBarPanel= $( ratioBarPanelName );
					teamContainer.SetDialogVariableInt("player_" + tablePropertyName.toLowerCase(), playerValues[i]);
				}
				else
				{
					var ratioBarPanelName = "#RatioBar" + tablePropertyName + iNonPlayerCalculated.toString();
					teamContainer.SetDialogVariableInt("ally_" + tablePropertyName.toLowerCase() + iNonPlayerCalculated.toString(), playerValues[i]);
					ratioBarPanel= $( ratioBarPanelName );
				}

				var badPanel = !ratioBarPanel;
				if( !badPanel )
				{
					if(typeof(ratioBarPanel.style) != "undefined")
					{
						ratioBarPanel.style.width = percentage.toString() + "%;";
					}

					var colorInt = ScoreboardSafeCall(function () { return Players.GetPlayerColor(i); }, 0);
					var colorString = "#" + intToARGB( colorInt );
					ratioBarPanel.style.backgroundColor = colorString;
					ratioBarPanel.style.borderColor = colorString;

					if(i != localPlayerId)
					{
						ratioBarPanel.AddClass("Hero" + iNonPlayerCalculated);
						iNonPlayerCalculated++;
					}
				}
				else
				{
					$.Msg("dungeon_scoreboard - could not find child " + ratioBarPanelName);
				}
			}
		}

		UpdateKillEventHints(zoneData, localPlayerId);
	}
}

function _ScoreboardUpdater_SetTextSafe(childName, textValue) {
	var childPanel = $.GetContextPanel().FindChildInLayoutFile(childName)
	if (childPanel === null)
		return;

	childPanel.text = textValue;
}

function _ScoreboardUpdater_SetValueSafe(childName, Value) {
	var childPanel = $.GetContextPanel().FindChildInLayoutFile(childName)

	if (childPanel === null)
		return;

	childPanel.value = Value;
}

function NormalizeSupporterPassProgress(playerInfo) {
	var xp = Math.max(0, Number(playerInfo.XP) || 0);
	var maxXp = Math.max(1, Number(playerInfo.MaxXP) || 1000);
	var level = Math.max(1, Number(playerInfo.Lvl) || 1);

	if (xp >= maxXp) {
		var completedLevels = Math.floor(xp / maxXp);
		xp = xp - completedLevels * maxXp;
		level = Math.max(level, 1 + completedLevels);
	}

	return {
		xp: xp,
		maxXp: maxXp,
		level: level
	};
}

function FormatXPInteger(value) {
	return Math.floor(Math.max(0, Number(value) || 0)).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

function BuildXPTooltip(playerInfo, supporterProgress) {
	var lines = [
		"Supporter Pass: Level " + supporterProgress.level + " - " + FormatXPInteger(supporterProgress.xp) + " / " + FormatXPInteger(supporterProgress.maxXp) + " XP"
	];
	var xhsLevel = Math.max(0, Number(playerInfo.xhs_account_level) || 0);
	var xhsCurrent = Math.max(0, Number(playerInfo.xhs_xp_current) || 0);
	var xhsMax = Math.max(0, Number(playerInfo.xhs_xp_max) || 0);
	var xhsTotal = Math.max(0, Number(playerInfo.xhs_xp) || 0);

	if (xhsLevel > 0 || xhsCurrent > 0 || xhsMax > 0 || xhsTotal > 0) {
		var xhsText = "XHS Account: Level " + Math.max(1, xhsLevel);
		if (xhsMax > 0) {
			xhsText += " - " + FormatXPInteger(xhsCurrent) + " / " + FormatXPInteger(xhsMax) + " XP";
		} else if (xhsTotal > 0) {
			xhsText += " - " + FormatXPInteger(xhsTotal) + " total XP";
		}

		lines.push(xhsText);
	}

	return lines.join("\n");
}

function _ScoreboardUpdater_UpdatePlayerPanelXP(playerId, ImbaXP_Panel, player_info) {
	if (!ImbaXP_Panel || !player_info) {
		return;
	}

	var ids = {
		xpRank:  "es-player-xp-rank-name" + playerId,
		xp: "es-player-xp-rank" + playerId,
		xpEarned: "es-player-xp-progress" + playerId,
		level: "es-player-xp-level" + playerId,
		progress_bar: "es-player-xp-progress" + playerId,
	};

	// setup panels
//	ImbaXP_Panel.BCreateChildren("<Panel id='XPProgressBarContainer" + playerId + "' value='0.0'/>");
//	var Imbar = ImbaXP_Panel.BCreateChildren("<ProgressBar id='XPProgressBar" + playerId + "'/>");
//	ImbaXP_Panel.BCreateChildren("<Label id='ImbaLvl" + playerId + "' text='999'/>");
//	ImbaXP_Panel.BCreateChildren("<Label id='ImbaXPRank" + playerId + "' text='999'/>");
//	ImbaXP_Panel.BCreateChildren("<Label id='ImbaXP" + playerId + "' text='999'/>");
//	ImbaXP_Panel.BCreateChildren("<Label id='ImbaXPEarned" + playerId + "' text='+0'/>");

//	var steamid = Game.GetPlayerInfo(playerId).player_steamid;

	// load player data from api
//	LoadPlayerInfo(function (data) {
//		var thisPlayerInfo = null;
//		playerInfo.forEach(function (i) {
//			if (i.steamid == steamid)
//				thisPlayerInfo = i;
//		});

//		if (thisPlayerInfo == null) // wtf
//			return;

//		_ScoreboardUpdater_SetTextSafe(playerPanel, ids.xpRank, thisPlayerInfo.xp_rank_title);
//		_ScoreboardUpdater_SetTextSafe(playerPanel, ids.xp, thisPlayerInfo.xp_in_current_level + "/" + thisPlayerInfo.total_xp_for_current_level);
//		_ScoreboardUpdater_SetTextSafe(playerPanel, ids.level, thisPlayerInfo.xp_level);
//		_ScoreboardUpdater_SetValueSafe(playerPanel, ids.progress_bar, thisPlayerInfo.xp_in_current_level / thisPlayerInfo.total_xp_for_current_level);
//		playerPanel.FindChildTraverse(ids.xpRank).style.color = "#" + thisPlayerInfo.xp_rank_color;

//	});

	// xp shown fix (temporary?)
	var progress = NormalizeSupporterPassProgress(player_info);
	_ScoreboardUpdater_SetTextSafe(ids.xpRank, player_info.title);
	_ScoreboardUpdater_SetTextSafe(ids.xp, progress.xp + "/" + progress.maxXp);
	_ScoreboardUpdater_SetTextSafe(ids.level, "Level: " + progress.level);
	var rankPanel = $.GetContextPanel().FindChildTraverse(ids.xpRank);
	if (rankPanel) {
		rankPanel.style.color = player_info.title_color || "#cde8ff";
	}

	var progress_bar_value = progress.xp / progress.maxXp * 100;
	var progressPanel = $("#" + ids.progress_bar);
	if (progressPanel) {
		progressPanel.style.width = progress_bar_value + "%";
	}
	var tooltip = BuildXPTooltip(player_info, progress);
	ImbaXP_Panel.SetPanelEvent("onmouseover", function () {
		$.DispatchEvent("UIShowTextTooltip", ImbaXP_Panel, tooltip);
	});
	ImbaXP_Panel.SetPanelEvent("onmouseout", function () {
		$.DispatchEvent("UIHideTextTooltip", ImbaXP_Panel);
	});
//	_ScoreboardUpdater_SetValueSafe(ids.progress_bar, progress.xp / progress.maxXp);
}

function UpdatePlayerZones()
{
//	$.Msg( "UpdatePlayerZones" );
}

var g_nCurZone = -1;

function ZoneScoresReceived()
{
	var localPlayerId = GetLocalPlayerId();
	if( IsScoreboardPlayerValid(localPlayerId) )
	{
		var zonePlayerEntry = GetScoreboardNetTableValue("player_zone_locations", localPlayerId);
		if (!zonePlayerEntry || !zonePlayerEntry["ZoneName"])
			return;
		var zoneName = zonePlayerEntry["ZoneName"];
		var zoneData = GetScoreboardNetTableValue("zone_scores", zoneName);
		if (!zoneData)
			return;

		if ( $.GetContextPanel().BHasClass( "flyout_scoreboard_visible" ) == false )
			return;

		var zoneNameList = CustomNetTables.GetAllTableValues("zone_names");
		if (!zoneNameList || !zoneNameList[g_nCurZone] || !zoneNameList[g_nCurZone]["value"]) {
			return;
		}
		UpdateZoneScores(zoneNameList[g_nCurZone]["value"]["ZoneName"]);
	}
}

var g_szZoneNameClass = null;

function OnZoneCompleted( data )
{
	if (!data || !data["ZoneName"])
		return;

	$.GetContextPanel().SetHasClass( "Complete_" + data["ZoneName"], true );
}

function HideZoneCompleted()
{
	if (g_szZoneNameClass)
		$.GetContextPanel().SetHasClass( g_szZoneNameClass, false );

	if ( $.GetContextPanel().BHasClass( "ZoneComplete" ) || $.GetContextPanel().BHasClass( "flyout_scoreboard_visible" ) )
	{
		$.DispatchEvent( "DOTAHUDToggleScoreboard" );
	}
	$.GetContextPanel().SetHasClass( "ZoneComplete", false );
}

function ScanForValidZoneName( nStart, nDir )
{
	var zoneNameList = CustomNetTables.GetAllTableValues("zone_names");
	if (!zoneNameList) {
		return "";
	}

	for (var i = nStart+nDir; i >= 0 && i < zoneNameList.length; i+=nDir )
	{
		if (!zoneNameList[i] || !zoneNameList[i]["value"] || !zoneNameList[i]["value"]["ZoneName"]) {
			continue;
		}

		var zoneData = GetScoreboardNetTableValue("zone_scores", zoneNameList[i]["value"]["ZoneName"]);
		if (!!zoneData === true)
			return zoneNameList[i]["value"]["ZoneName"];
	}

	return "";
}

function FindZoneByName( zoneName )
{
	var zoneNameList = CustomNetTables.GetAllTableValues("zone_names");
	if (!zoneNameList) {
		return -1;
	}

	for ( var i = 0; i < zoneNameList.length; i++ )
	{
		if (!zoneNameList[i] || !zoneNameList[i]["value"]) {
			continue;
		}

		if (zoneName == zoneNameList[i]["value"]["ZoneName"])
			return i;
	}

	return -1;
}

function SetScoreboardZoneButtonEnabled(buttonName, enabled) {
	var button = $.GetContextPanel().FindChildTraverse(buttonName);
	if (button) {
		button.enabled = enabled;
	}
}

function SetFlyoutScoreboardVisible( bVisible )
{
	EnsureScoreboardAboveHudElements();

	if(bVisible === true)
	{
		var localPlayerId = GetLocalPlayerId();
		if (!IsScoreboardPlayerValid(localPlayerId)) {
			return;
		}

		var zonePlayerEntry = GetScoreboardNetTableValue("player_zone_locations", localPlayerId);
		if (!zonePlayerEntry || !zonePlayerEntry["ZoneName"]) {
			return;
		}
		var zoneName = zonePlayerEntry["ZoneName"];
		var zoneData = GetScoreboardNetTableValue("zone_scores", zoneName);
		if ( typeof(zoneData) == "undefined" )
			return;

		var zoneNameList = CustomNetTables.GetAllTableValues("zone_names");
		if (!zoneNameList) {
			return;
		}
		for (var i = 0; i < zoneNameList.length; i++)
		{
			if (!zoneNameList[i] || !zoneNameList[i]["value"]) {
				continue;
			}

			if (zoneNameList[i]["value"]["ZoneName"] == zoneName)
			{
				g_nCurZone = i;
			}
		}

		var prevValidZoneName = ScanForValidZoneName(g_nCurZone, -1);
		var nextValidZoneName = ScanForValidZoneName(g_nCurZone, 1);

		SetScoreboardZoneButtonEnabled("PrevZoneButton", prevValidZoneName.length > 0);
		SetScoreboardZoneButtonEnabled("NextZoneButton", nextValidZoneName.length > 0);

		g_szZoneNameClass = zoneName;
		$.GetContextPanel().SetHasClass( g_szZoneNameClass, true );
		$.GetContextPanel().SetHasClass( "ZoneSelected_" + g_szZoneNameClass, true );
		UpdateZoneScores(zoneName);
	}
	else
	{
		if (g_szZoneNameClass) {
			$.GetContextPanel().SetHasClass( g_szZoneNameClass, false );
			$.GetContextPanel().SetHasClass( "ZoneSelected_" + g_szZoneNameClass, false );
		}
		$.GetContextPanel().SetHasClass( "ZoneComplete", bVisible );
	}
	$.GetContextPanel().SetHasClass( "flyout_scoreboard_visible", bVisible );
}

function SetFlyoutScoreboardChangeZone( nDir )
{
	var newZoneName = ScanForValidZoneName(g_nCurZone, nDir);
	if (newZoneName.length == 0)
		return;
	var zoneNameList = CustomNetTables.GetAllTableValues("zone_names");
	if (!zoneNameList || !zoneNameList[g_nCurZone] || !zoneNameList[g_nCurZone]["value"]) {
		return;
	}
	
	$.GetContextPanel().SetHasClass( "ZoneSelected_" + zoneNameList[g_nCurZone]["value"]["ZoneName"], false );
	g_nCurZone = FindZoneByName(newZoneName);
	if (g_nCurZone < 0 || !zoneNameList[g_nCurZone] || !zoneNameList[g_nCurZone]["value"]) {
		return;
	}

	var prevValidZoneName = ScanForValidZoneName(g_nCurZone, -1);
	var nextValidZoneName = ScanForValidZoneName(g_nCurZone, 1);

	SetScoreboardZoneButtonEnabled("PrevZoneButton", prevValidZoneName.length > 0);
	SetScoreboardZoneButtonEnabled("NextZoneButton", nextValidZoneName.length > 0);


	$.GetContextPanel().SetHasClass( "ZoneSelected_" + zoneNameList[g_nCurZone]["value"]["ZoneName"], true );
	UpdateZoneScores( zoneNameList[g_nCurZone]["value"]["ZoneName"] );
}

(function()
{	
	//InitializeScoreboard();
	EnsureScoreboardAboveHudElements();
	SetFlyoutScoreboardVisible(false);
	UpdateFragmentQuests(CustomNetTables.GetTableValue("fragment_quests", "state"));
	
	$.RegisterEventHandler( "DOTACustomUI_SetFlyoutScoreboardVisible", $.GetContextPanel(), SetFlyoutScoreboardVisible );
	$.RegisterEventHandler("DOTACustomUI_SetFlyoutScoreboardChangeZone", $.GetContextPanel(), SetFlyoutScoreboardChangeZone);
})();
