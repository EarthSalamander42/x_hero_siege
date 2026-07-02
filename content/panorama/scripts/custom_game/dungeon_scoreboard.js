"use strict"
CustomNetTables.SubscribeNetTableListener( "zone_scores", ZoneScoresReceived )
CustomNetTables.SubscribeNetTableListener( "player_zone_locations", UpdatePlayerZones )
CustomNetTables.SubscribeNetTableListener( "fragment_quests", FragmentQuestsReceived )
GameEvents.Subscribe( "zone_complete", OnZoneCompleted );

var KILL_EVENT_THRESHOLDS = [100, 200, 400, 500, 750];
var KILL_EVENT_VISIBLE_RATIO = 0.8;
var scoreboard_supporter_hover = null;
var scoreboard_supporter_hover_player_id = -1;

var SCOREBOARD_SUPPORTER_TIER_CATALOG = [
	{ name: "Free Player", color: "#7db9d8", fragments: 0, xpBoost: 0, votePower: 1 },
	{ name: "Donator", color: "#45C46B", fragments: 150, xpBoost: 10, votePower: 2 },
	{ name: "Golden Donator", color: "#F2C94C", fragments: 400, xpBoost: 20, votePower: 3 },
	{ name: "Ember Donator", color: "#E4572E", fragments: 900, xpBoost: 30, votePower: 4 },
	{ name: "Stoneguard Donator", color: "#5AD0FF", fragments: 1800, xpBoost: 40, votePower: 5 },
	{ name: "Earthwarden Donator", color: "#C99CFF", fragments: 1800, xpBoost: 40, votePower: 5 }
];

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

function ScoreboardFormatNumber(value) {
	var numberValue = Math.max(0, ScoreboardToNumber(value, 0));
	if (numberValue >= 1000000) {
		return (numberValue / 1000000).toFixed(1) + "M";
	}
	if (numberValue >= 10000) {
		return (numberValue / 1000).toFixed(1) + "k";
	}

	return Math.floor(numberValue).toString();
}

function ScoreboardFormatVotePower(value) {
	var votes = Math.max(1, Math.floor(ScoreboardToNumber(value, 1)));
	return votes + " setup " + (votes > 1 ? "votes" : "vote");
}

function ScoreboardFormatWinrate(value) {
	if (value === undefined || value === null || value === "") {
		return "-";
	}

	var numberValue = Number(value);
	if (isNaN(numberValue)) {
		return value.toString();
	}

	if (numberValue > 0 && numberValue <= 1) {
		numberValue = numberValue * 100;
	}

	return Math.round(numberValue) + "%";
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

function GetScoreboardSupporterTierInfo(tier) {
	tier = Math.max(0, Math.min(5, Math.floor(Number(tier) || 0)));
	return SCOREBOARD_SUPPORTER_TIER_CATALOG[tier] || SCOREBOARD_SUPPORTER_TIER_CATALOG[0];
}

function GetScoreboardWindowRect(panel) {
	if (!panel || typeof panel.GetPositionWithinWindow !== "function") {
		return { x: 0, y: 0, w: 0, h: 0 };
	}

	var position = panel.GetPositionWithinWindow();
	return {
		x: Number(position.x || position[0] || 0),
		y: Number(position.y || position[1] || 0),
		w: Number(panel.actuallayoutwidth || panel.desiredlayoutwidth || 0),
		h: Number(panel.actuallayoutheight || panel.desiredlayoutheight || 0)
	};
}

function GetScoreboardSupporterPlayerData(playerID, playerInfo) {
	playerInfo = playerInfo || {};
	var tier = GetScoreboardSupporterTier(playerInfo);
	var tierInfo = GetScoreboardSupporterTierInfo(tier);
	var gamePlayerInfo = ScoreboardSafeCall(function () { return Game.GetPlayerInfo(playerID); }, {}) || {};
	var heroName = ScoreboardSafeCall(function () { return Players.GetPlayerSelectedHero(playerID); }, "");
	var accountLevel = ScoreboardToNumber(playerInfo.xhs_account_level || playerInfo.account_level || playerInfo.legacy_level, 0);
	var accountCurrent = ScoreboardToNumber(playerInfo.xhs_xp_current, 0);
	var accountMax = ScoreboardToNumber(playerInfo.xhs_xp_max, 0);
	var accountTotal = ScoreboardToNumber(playerInfo.xhs_xp || playerInfo.xhs_xp_total, 0);

	return {
		playerID: playerID,
		playerName: ScoreboardSafeCall(function () { return Players.GetPlayerName(playerID); }, "") || gamePlayerInfo.player_name || ("Player " + (playerID + 1)),
		heroName: heroName,
		localHeroName: heroName ? $.Localize("#" + heroName) : "-",
		tier: tier,
		tierName: playerInfo.tier_name || playerInfo.supporter_tier_name || tierInfo.name,
		tierColor: playerInfo.tier_color || tierInfo.color,
		fragments: ScoreboardToNumber(playerInfo.fragments || playerInfo.fragment_balance, 0),
		weeklyFragments: ScoreboardToNumber(playerInfo.daily_fragments || playerInfo.daily_earned || playerInfo.weekly_fragments || playerInfo.weekly_earned, 0),
		weeklyCap: Math.max(ScoreboardToNumber(playerInfo.daily_cap || playerInfo.weekly_cap, 100), 1),
		seasonLevel: Math.max(1, ScoreboardToNumber(playerInfo.season_level || playerInfo.Lvl, 1)),
		seasonXP: ScoreboardToNumber(playerInfo.season_xp || playerInfo.XP, 0),
		seasonXPMax: Math.max(ScoreboardToNumber(playerInfo.season_xp_max || playerInfo.MaxXP, 1000), 1),
		accountLevel: accountLevel,
		accountXPCurrent: accountCurrent,
		accountXPMax: accountMax,
		accountXPTotal: accountTotal,
		winrate: playerInfo.winrate,
		fragmentsPerMonth: ScoreboardToNumber(playerInfo.tier_fragments || tierInfo.fragments, tierInfo.fragments),
		xpBoost: ScoreboardToNumber(playerInfo.tier_xp_boost || playerInfo.xp_boost || tierInfo.xpBoost, tierInfo.xpBoost),
		votePower: Math.max(1, ScoreboardToNumber(playerInfo.vote_power, tierInfo.votePower))
	};
}

function ScoreboardFormatAccountXP(data) {
	if (!data || (data.accountLevel <= 0 && data.accountXPCurrent <= 0 && data.accountXPMax <= 0 && data.accountXPTotal <= 0)) {
		return "-";
	}

	if (data.accountXPTotal > 0) {
		return "L" + Math.max(1, data.accountLevel) + " " + ScoreboardFormatNumber(data.accountXPTotal);
	}

	if (data.accountXPMax > 0) {
		return "L" + Math.max(1, data.accountLevel) + " " + ScoreboardFormatNumber(data.accountXPCurrent) + " / " + ScoreboardFormatNumber(data.accountXPMax);
	}

	return "L" + Math.max(1, data.accountLevel);
}

function ScoreboardSetChildText(parent, childID, value) {
	if (!parent) {
		return;
	}

	var child = parent.FindChildTraverse(childID);
	if (child) {
		child.text = value === undefined || value === null ? "" : value.toString();
	}
}

function ScoreboardSetFillPercent(parent, childID, current, max) {
	if (!parent) {
		return;
	}

	var child = parent.FindChildTraverse(childID);
	if (!child) {
		return;
	}

	var percent = Math.max(0, Math.min(100, Math.floor((ScoreboardToNumber(current, 0) / Math.max(ScoreboardToNumber(max, 1), 1)) * 100)));
	child.style.width = percent + "%";
}

function CreateScoreboardHoverStat(parent, id, labelText) {
	var stat = $.CreatePanel("Panel", parent, "ScoreboardXHSHoverStat_" + id);
	stat.AddClass("ScoreboardXHSHoverStat");

	var label = $.CreatePanel("Label", stat, "ScoreboardXHSHoverStatLabel_" + id);
	label.AddClass("ScoreboardXHSHoverStatLabel");
	label.text = labelText;

	var value = $.CreatePanel("Label", stat, "ScoreboardXHSHoverStatValue_" + id);
	value.AddClass("ScoreboardXHSHoverStatValue");
	value.text = "-";
}

function CreateScoreboardHoverMeter(parent, id, labelText) {
	var meter = $.CreatePanel("Panel", parent, "ScoreboardXHSHoverMeter_" + id);
	meter.AddClass("ScoreboardXHSHoverMeter");

	var row = $.CreatePanel("Panel", meter, "ScoreboardXHSHoverMeterRow_" + id);
	row.AddClass("ScoreboardXHSHoverMeterRow");

	var label = $.CreatePanel("Label", row, "ScoreboardXHSHoverMeterLabel_" + id);
	label.AddClass("ScoreboardXHSHoverMeterLabel");
	label.text = labelText;

	var value = $.CreatePanel("Label", row, "ScoreboardXHSHoverMeterValue_" + id);
	value.AddClass("ScoreboardXHSHoverMeterValue");
	value.text = "-";

	var track = $.CreatePanel("Panel", meter, "ScoreboardXHSHoverMeterTrack_" + id);
	track.AddClass("ScoreboardXHSHoverMeterTrack");

	var fill = $.CreatePanel("Panel", track, "ScoreboardXHSHoverMeterFill_" + id);
	fill.AddClass("ScoreboardXHSHoverMeterFill");
}

function EnsureScoreboardSupporterHover() {
	if (scoreboard_supporter_hover && scoreboard_supporter_hover.IsValid && scoreboard_supporter_hover.IsValid()) {
		return scoreboard_supporter_hover;
	}

	scoreboard_supporter_hover = $.CreatePanel("Panel", $.GetContextPanel(), "ScoreboardXHSSupporterHover");
	scoreboard_supporter_hover.AddClass("ScoreboardXHSSupporterHover");
	scoreboard_supporter_hover.hittest = false;
	scoreboard_supporter_hover.hittestchildren = false;

	var header = $.CreatePanel("Panel", scoreboard_supporter_hover, "ScoreboardXHSHoverHeader");
	header.AddClass("ScoreboardXHSHoverHeader");

	var heroFrame = $.CreatePanel("Panel", header, "ScoreboardXHSHoverHeroFrame");
	heroFrame.AddClass("ScoreboardXHSHoverHeroFrame");

	var heroImage = $.CreatePanel("DOTAHeroImage", heroFrame, "ScoreboardXHSHoverHeroImage");
	heroImage.AddClass("ScoreboardXHSHoverHeroImage");
	heroImage.heroimagestyle = "landscape";
	heroImage.scaling = "stretch-to-cover-preserve-aspect";
	heroImage.hittest = false;

	var copy = $.CreatePanel("Panel", header, "ScoreboardXHSHoverCopy");
	copy.AddClass("ScoreboardXHSHoverCopy");

	var eyebrow = $.CreatePanel("Label", copy, "ScoreboardXHSHoverEyebrow");
	eyebrow.AddClass("ScoreboardXHSHoverEyebrow");
	eyebrow.text = "SUPPORTER PROFILE";

	var name = $.CreatePanel("Label", copy, "ScoreboardXHSHoverPlayerName");
	name.AddClass("ScoreboardXHSHoverPlayerName");

	var hero = $.CreatePanel("Label", copy, "ScoreboardXHSHoverHeroName");
	hero.AddClass("ScoreboardXHSHoverHeroName");

	var tier = $.CreatePanel("Label", scoreboard_supporter_hover, "ScoreboardXHSHoverTier");
	tier.AddClass("ScoreboardXHSHoverTier");

	var stats = $.CreatePanel("Panel", scoreboard_supporter_hover, "ScoreboardXHSHoverStats");
	stats.AddClass("ScoreboardXHSHoverStats");
	CreateScoreboardHoverStat(stats, "AccountLevel", "XHS Level");
	CreateScoreboardHoverStat(stats, "SeasonLevel", "Season Level");
	CreateScoreboardHoverStat(stats, "Fragments", "Fragments");
	CreateScoreboardHoverStat(stats, "Winrate", "Winrate");

	CreateScoreboardHoverMeter(scoreboard_supporter_hover, "SeasonXP", "Season XP");
	CreateScoreboardHoverMeter(scoreboard_supporter_hover, "GlobalXP", "Global XP");
	CreateScoreboardHoverMeter(scoreboard_supporter_hover, "Weekly", "Daily Cap");

	var footer = $.CreatePanel("Label", scoreboard_supporter_hover, "ScoreboardXHSHoverFooter");
	footer.AddClass("ScoreboardXHSHoverFooter");

	return scoreboard_supporter_hover;
}

function PositionScoreboardSupporterHover(anchorPanel, hover) {
	var root = $.GetContextPanel();
	var rootRect = GetScoreboardWindowRect(root);
	var anchorRect = GetScoreboardWindowRect(anchorPanel);
	var hoverWidth = Number(hover.actuallayoutwidth || hover.desiredlayoutwidth || 300);
	var hoverHeight = Number(hover.actuallayoutheight || hover.desiredlayoutheight || 330);
	var rootWidth = Number(root.actuallayoutwidth || root.desiredlayoutwidth || 600);
	var rootHeight = Number(root.actuallayoutheight || root.desiredlayoutheight || 900);
	var margin = 8;
	var x = anchorRect.x - rootRect.x + anchorRect.w + margin;
	var y = anchorRect.y - rootRect.y - 10;

	if (x + hoverWidth > rootWidth - margin) {
		x = anchorRect.x - rootRect.x - hoverWidth - margin;
	}

	x = Math.max(margin, Math.min(rootWidth - hoverWidth - margin, x));
	y = Math.max(margin, Math.min(rootHeight - hoverHeight - margin, y));
	hover.style.position = Math.floor(x) + "px " + Math.floor(y) + "px 0px";
}

function ShowScoreboardSupporterHover(playerID, anchorPanel) {
	if (playerID === undefined || playerID === null || playerID < 0 || !anchorPanel) {
		return;
	}

	var playerInfo = GetScoreboardNetTableValue("supporter_pass_player", playerID) || {};
	var data = GetScoreboardSupporterPlayerData(playerID, playerInfo);
	var hover = EnsureScoreboardSupporterHover();

	scoreboard_supporter_hover_player_id = playerID;
	ClearScoreboardSupporterTierClasses(hover);
	hover.AddClass("ScoreboardSupporterTier" + data.tier);

	var heroImage = hover.FindChildTraverse("ScoreboardXHSHoverHeroImage");
	if (heroImage && data.heroName) {
		heroImage.heroname = data.heroName;
	}

	ScoreboardSetChildText(hover, "ScoreboardXHSHoverPlayerName", data.playerName);
	ScoreboardSetChildText(hover, "ScoreboardXHSHoverHeroName", data.localHeroName || data.heroName);
	ScoreboardSetChildText(hover, "ScoreboardXHSHoverTier", data.tierName);
	ScoreboardSetChildText(hover, "ScoreboardXHSHoverStatValue_AccountLevel", data.accountLevel > 0 ? data.accountLevel : "-");
	ScoreboardSetChildText(hover, "ScoreboardXHSHoverStatValue_SeasonLevel", data.seasonLevel);
	ScoreboardSetChildText(hover, "ScoreboardXHSHoverStatValue_Fragments", ScoreboardFormatNumber(data.fragments));
	ScoreboardSetChildText(hover, "ScoreboardXHSHoverStatValue_Winrate", ScoreboardFormatWinrate(data.winrate));
	ScoreboardSetChildText(hover, "ScoreboardXHSHoverMeterValue_SeasonXP", ScoreboardFormatNumber(data.seasonXP) + " / " + ScoreboardFormatNumber(data.seasonXPMax));
	ScoreboardSetChildText(hover, "ScoreboardXHSHoverMeterValue_GlobalXP", ScoreboardFormatAccountXP(data));
	ScoreboardSetChildText(hover, "ScoreboardXHSHoverMeterValue_Weekly", ScoreboardFormatNumber(data.weeklyFragments) + " / " + ScoreboardFormatNumber(data.weeklyCap));
	ScoreboardSetFillPercent(hover, "ScoreboardXHSHoverMeterFill_SeasonXP", data.seasonXP, data.seasonXPMax);
	ScoreboardSetFillPercent(hover, "ScoreboardXHSHoverMeterFill_GlobalXP", data.accountXPCurrent, data.accountXPMax > 0 ? data.accountXPMax : 1);
	ScoreboardSetFillPercent(hover, "ScoreboardXHSHoverMeterFill_Weekly", data.weeklyFragments, data.weeklyCap);

	if (data.tier > 0) {
		ScoreboardSetChildText(hover, "ScoreboardXHSHoverFooter", "+" + ScoreboardFormatNumber(data.fragmentsPerMonth) + " monthly fragments / +" + ScoreboardFormatNumber(data.xpBoost) + "% season XP / " + ScoreboardFormatVotePower(data.votePower));
	} else {
		ScoreboardSetChildText(hover, "ScoreboardXHSHoverFooter", "No active supporter tier");
	}

	PositionScoreboardSupporterHover(anchorPanel, hover);
	hover.AddClass("ScoreboardXHSHoverVisible");

	$.Schedule(0.01, function () {
		if (scoreboard_supporter_hover_player_id == playerID && hover && hover.IsValid && hover.IsValid()) {
			PositionScoreboardSupporterHover(anchorPanel, hover);
		}
	});
}

function HideScoreboardSupporterHover() {
	scoreboard_supporter_hover_player_id = -1;

	if (scoreboard_supporter_hover && scoreboard_supporter_hover.IsValid && scoreboard_supporter_hover.IsValid()) {
		scoreboard_supporter_hover.RemoveClass("ScoreboardXHSHoverVisible");
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
	var xpPanel = $.GetContextPanel().FindChildTraverse("es-player-xp" + playerID);
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

	for(var i = 0; i < 8; i++) {
		var player_info = GetScoreboardNetTableValue("supporter_pass_player", i);

		var ImbaXP_Panel = $.GetContextPanel().FindChildTraverse("es-player-xp" + i);

		if (ImbaXP_Panel != undefined && player_info != undefined) {
			// set xp values
			_ScoreboardUpdater_UpdatePlayerPanelXP(i, ImbaXP_Panel, player_info);
		}

		if(i == localPlayerId)
		{
			continue;
		}

		if (!IsScoreboardPlayerValid(i) || actualPlayerInfo > 7) {
			continue;
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
		reward.text = "Potential only: +" + previewFragments + " / " + maxFragments + " fragments";
	} else {
		reward.text = "Potential: +" + previewFragments + " / " + maxFragments + " fragments";
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
	SetFlyoutScoreboardVisible(false);
	UpdateFragmentQuests(CustomNetTables.GetTableValue("fragment_quests", "state"));
	
	$.RegisterEventHandler( "DOTACustomUI_SetFlyoutScoreboardVisible", $.GetContextPanel(), SetFlyoutScoreboardVisible );
	$.RegisterEventHandler("DOTACustomUI_SetFlyoutScoreboardChangeZone", $.GetContextPanel(), SetFlyoutScoreboardChangeZone);
})();
