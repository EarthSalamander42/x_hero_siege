"use strict"
CustomNetTables.SubscribeNetTableListener( "zone_scores", ZoneScoresReceived )
CustomNetTables.SubscribeNetTableListener( "player_zone_locations", UpdatePlayerZones )
GameEvents.Subscribe( "zone_complete", OnZoneCompleted );

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
	if ( muteButton !== null )
	{
		$.Msg( "clicked" );
		var nPlayerID = muteButton.GetAttributeInt( "player_id", -1 )
		if ( nPlayerID !== -1 )
		{
			$.Msg( "Toggling mute on player: " + nPlayerID );
			var newIsMuted = !Game.IsPlayerMuted( nPlayerID );
			Game.SetPlayerMuted( nPlayerID, newIsMuted );
			muteButton.SetHasClass( "player_muted", Game.IsPlayerMuted( nPlayerID ) );
		}
		else
		{
			$.Msg( "No valid id" );
		}
	}
}

function GetLocalPlayerId()
{
	var localPlayerId = 0;
	var localPlayerInfo = Game.GetLocalPlayerInfo();
	if(typeof(localPlayerInfo) !== "undefined")
	{
		localPlayerId = localPlayerInfo.player_id;
	}

	if(Players.IsLocalPlayerInPerspectiveCamera())
	{
		//get local player info for selected portrait unit
		localPlayerId = Players.GetPerspectivePlayerId();
	}
	return localPlayerId;
}

function UpdatePlayerImages()
{
	var localPlayerId = GetLocalPlayerId();

	var playerImage = $("#ScoreboardTeamContainer").FindChildTraverse( "PlayerImage" );
	playerImage.heroname = Players.GetPlayerSelectedHero( localPlayerId );
	var playerColorBar = $("#ScoreboardTeamContainer").FindChildTraverse( "PlayerColorBar");
	var colorInt = Players.GetPlayerColor( localPlayerId );
	var colorString = "#" + intToARGB( colorInt );
	playerColorBar.style.backgroundColor = colorString;
	var FriendlyBarImage = $("#ScoreboardTeamContainer").FindChildTraverse( "HeroImage" );
	var friendlyBarImage2 = $("#PartyPortraits").FindChildTraverse( "PartyPortrait" + localPlayerId ).FindChildTraverse( "HeroImage" );
	friendlyBarImage.heroname = Players.GetPlayerSelectedHero( localPlayerId );

	var actualPlayerInfo = 1;
	for(var i = 0; i < 8; i++)
	{
		var player_info = CustomNetTables.GetTableValue("battlepass", i);
		if (player_info) {
			playerImage.style.border = "2px solid " + player_info.donator_color;
		}

		var ImbaXP_Panel = $.GetContextPanel().FindChildTraverse("es-player-xp" + i);

		if (ImbaXP_Panel != undefined && player_info != undefined) {
			// set xp values
			_ScoreboardUpdater_UpdatePlayerPanelXP(i, ImbaXP_Panel, player_info);
		}

		if(i == localPlayerId)
		{
			continue;
		}

		var muteButton =  $("#ScoreboardTeamContainer").FindChildTraverse( "PlayerMuteButton" + actualPlayerInfo );
		muteButton.SetAttributeInt( "player_id", i );
		muteButton.SetHasClass( "player_muted", Game.IsPlayerMuted( i ) )
		//$.Msg( "assigning button to player id: " + i );

		var heroImage = $("#ScoreboardTeamContainer").FindChildTraverse( "HeroImage" + actualPlayerInfo );
		heroImage.heroname = Players.GetPlayerSelectedHero( i );

		var heroColorBar = $("#ScoreboardTeamContainer").FindChildTraverse( "HeroColorBar" + actualPlayerInfo );
		var colorInt = Players.GetPlayerColor( i );
		var colorString = "#" + intToARGB( colorInt );
		heroColorBar.style.backgroundColor = colorString;

		var friendlyBarImage = $("#PartyPortraits").FindChildTraverse( "PartyPortrait" + actualPlayerInfo ).FindChildTraverse( "HeroImage" );
		friendlyBarImage.heroname = Players.GetPlayerSelectedHero( i );

		actualPlayerInfo++;
	}
}

function UpdateZoneScores( zoneName )
{
	if ($.GetContextPanel().BHasClass("ZoneComplete"))
		return;

	UpdatePlayerImages();

	var localPlayerId = GetLocalPlayerId();

	//$.Msg( "Updating zone: " + zoneName );

	var zonePlayerEntry = CustomNetTables.GetTableValue( "player_zone_locations", localPlayerId.toString());
	var PlayerZoneName = zonePlayerEntry["ZoneName"];
	$.GetContextPanel().SetHasClass( "ActiveZone", zoneName === PlayerZoneName );

	var zoneData = CustomNetTables.GetTableValue( "zone_scores", zoneName );
	var zoneDataValid = !!zoneData;
	if ( zoneDataValid === true )
	{
		var secondsRaw = Math.floor( zoneData["CompletionTime"] );
		var minutes = secondsRaw / 60;
		var seconds = minutes < 1 ? secondsRaw : secondsRaw - ( Math.floor( minutes ) * 60 );
		$("#ScoreboardZone").text = $.Localize( zoneName );
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
					if(typeof(playerValue) != "undefined")
					{
						playerValues[i] = playerValue;
						keyTotal += playerValue;
					}
				}
			}

			//prop the category variable to the container (e.g. "Deaths": 0)
			$("#ScoreboardTeamContainer").SetDialogVariableInt(tablePropertyName.toLowerCase(), keyTotal);

			var iNonPlayerCalculated = 1;
			for(var i = 0; i < 8; i++)
			{
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
					$("#ScoreboardTeamContainer").SetDialogVariableInt("player_" + tablePropertyName.toLowerCase(), playerValues[i]);
				}
				else
				{
					var ratioBarPanelName = "#RatioBar" + tablePropertyName + iNonPlayerCalculated.toString();
					$("#ScoreboardTeamContainer").SetDialogVariableInt("ally_" + tablePropertyName.toLowerCase() + iNonPlayerCalculated.toString(), playerValues[i]);
					ratioBarPanel= $( ratioBarPanelName );
				}

				var badPanel = !ratioBarPanel;
				if( !badPanel )
				{
					//$.Msg("dungeon_scoreboard - found child " + ratioBarPanelName + " for player " + i + " with width " + percentage.toFixed(2));
					//$.Msg("dungeon_scoreboard - player: " + i + " values:" + playerValues[i] + "/" + keyTotal + " = " + percentage);

					if(typeof(ratioBarPanel.style) != "undefined")
					{
						ratioBarPanel.style.width = percentage.toString() + "%;";
					}

					var colorInt = Players.GetPlayerColor( i );
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

function _ScoreboardUpdater_UpdatePlayerPanelXP(playerId, ImbaXP_Panel, player_info) {

//	$.Msg("Updating player xp panel");

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
	_ScoreboardUpdater_SetTextSafe(ids.xpRank, player_info.title);
	_ScoreboardUpdater_SetTextSafe(ids.xp, player_info.XP + "/" + player_info.MaxXP);
	_ScoreboardUpdater_SetTextSafe(ids.level, "Level: " + player_info.Lvl);
	$.GetContextPanel().FindChildTraverse(ids.xpRank).style.color = player_info.title_color;

	var progress_bar_value = player_info.XP / player_info.MaxXP * 100;
	$("#" + ids.progress_bar).style.width = progress_bar_value + "%";
//	_ScoreboardUpdater_SetValueSafe(ids.progress_bar, player_info.XP / player_info.MaxXP);
}

function UpdatePlayerZones()
{
	$.Msg( "UpdatePlayerZones" );
}

var g_nCurZone = -1;

function ZoneScoresReceived()
{
	//$.Msg( "ZoneScoresReceived" );
	var localPlayerId = GetLocalPlayerId();
	if( localPlayerId !== -1)
	{
		var zonePlayerEntry = CustomNetTables.GetTableValue( "player_zone_locations", localPlayerId.toString());
		if ( typeof(zonePlayerEntry) == "undefined" )
			return;
		var zoneName = zonePlayerEntry["ZoneName"];
		var zoneData = CustomNetTables.GetTableValue( "zone_scores", zoneName );
		if ( typeof(zoneData) == "undefined" )
			return;

		if ( $.GetContextPanel().BHasClass( "flyout_scoreboard_visible" ) == false )
			return;

		var zoneNameList = CustomNetTables.GetAllTableValues("zone_names");
		UpdateZoneScores(zoneNameList[g_nCurZone]["value"]["ZoneName"]);
	}
}

var g_szZoneNameClass = null;

function OnZoneCompleted( data )
{
	$.GetContextPanel().SetHasClass( "Complete_" + data["ZoneName"], true );
}

function HideZoneCompleted()
{
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

	for (var i = nStart+nDir; i >= 0 && i < zoneNameList.length; i+=nDir )
	{
		var zoneData = CustomNetTables.GetTableValue("zone_scores", zoneNameList[i]["value"]["ZoneName"]);
		if (!!zoneData === true)
			return zoneNameList[i]["value"]["ZoneName"];
	}

	return "";
}

function FindZoneByName( zoneName )
{
	var zoneNameList = CustomNetTables.GetAllTableValues("zone_names");

	for ( var i = 0; i < zoneNameList.length; i++ )
	{
		if (zoneName == zoneNameList[i]["value"]["ZoneName"])
			return i;
	}

	return -1;
}

function SetFlyoutScoreboardVisible( bVisible )
{
	if(bVisible === true)
	{
		var localPlayerId = GetLocalPlayerId();

		var zonePlayerEntry = CustomNetTables.GetTableValue( "player_zone_locations", localPlayerId.toString());
		$.Msg(zonePlayerEntry)
		var zoneName = zonePlayerEntry["ZoneName"];
		var zoneData = CustomNetTables.GetTableValue( "zone_scores", zoneName );
		if ( typeof(zoneData) == "undefined" )
			return;

		var zoneNameList = CustomNetTables.GetAllTableValues("zone_names");
		for (var i = 0; i < zoneNameList.length; i++)
		{
			if (zoneNameList[i]["value"]["ZoneName"] == zoneName)
			{
				g_nCurZone = i;
			}
		}

		var prevValidZoneName = ScanForValidZoneName(g_nCurZone, -1);
		var nextValidZoneName = ScanForValidZoneName(g_nCurZone, 1);

		//$.Msg("next:" + nextValidZoneName)

		$.GetContextPanel().FindChildTraverse("PrevZoneButton").enabled = (prevValidZoneName.length > 0);
		$.GetContextPanel().FindChildTraverse("NextZoneButton").enabled = (nextValidZoneName.length > 0);

		g_szZoneNameClass = zoneName;
		$.GetContextPanel().SetHasClass( g_szZoneNameClass, true );
		$.GetContextPanel().SetHasClass( "ZoneSelected_" + g_szZoneNameClass, true );
		UpdateZoneScores(zoneName);
	}
	else
	{
		$.GetContextPanel().SetHasClass( g_szZoneNameClass, false );
		$.GetContextPanel().SetHasClass( "ZoneSelected_" + g_szZoneNameClass, false );
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
	
	//$.Msg("new:" + newZoneName)
	$.GetContextPanel().SetHasClass( "ZoneSelected_" + zoneNameList[g_nCurZone]["value"]["ZoneName"], false );
	g_nCurZone = FindZoneByName(newZoneName);

	//$.Msg("zone:" + g_nCurZone)

	var prevValidZoneName = ScanForValidZoneName(g_nCurZone, -1);
	var nextValidZoneName = ScanForValidZoneName(g_nCurZone, 1);

	$.GetContextPanel().FindChildTraverse("PrevZoneButton").enabled = (prevValidZoneName.length > 0);
	$.GetContextPanel().FindChildTraverse("NextZoneButton").enabled = (nextValidZoneName.length > 0);


	$.GetContextPanel().SetHasClass( "ZoneSelected_" + zoneNameList[g_nCurZone]["value"]["ZoneName"], true );
	UpdateZoneScores( zoneNameList[g_nCurZone]["value"]["ZoneName"] );
}

(function()
{	
	//InitializeScoreboard();
	SetFlyoutScoreboardVisible(false);

	$("#ZoneRequirementContainer").SwitchClass("TabSlot", "Tab1Selected");
	
	$.RegisterEventHandler( "DOTACustomUI_SetFlyoutScoreboardVisible", $.GetContextPanel(), SetFlyoutScoreboardVisible );
	$.RegisterEventHandler("DOTACustomUI_SetFlyoutScoreboardChangeZone", $.GetContextPanel(), SetFlyoutScoreboardChangeZone);
})();
