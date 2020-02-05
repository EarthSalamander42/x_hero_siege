"use strict";

GameUI.SetCameraTerrainAdjustmentEnabled( false );

var g_flDialogAdvanceTime = -1;
var g_nCurrentCharacter = 0;
var g_flCharacterAdvanceRate = 0.0075;
var g_szPendingDialog = null;
var g_nCurrentDialogEnt = -1;
var g_nCurrentDialogLine = -1;
var g_bSentToAll = false;
var g_szConfirmToken = null;
var g_bShowAdvanceButton = true;

function OnDialogReceived( data )
{
	if ( data["DialogText"] ===  "" )
		return;

	g_bSentToAll = data["SendToAll"];
	if ( !g_bSentToAll )
	{
		var vAbsOrigin = Entities.GetAbsOrigin( data["DialogEntIndex"] );
		var nX = Game.WorldToScreenX( vAbsOrigin[0], vAbsOrigin[1], vAbsOrigin[2] );
		var nY = Game.WorldToScreenY( vAbsOrigin[0], vAbsOrigin[1], vAbsOrigin[2] );
		$( "#FloatingDialogPanel" ).style.x = ( nX + 25 ) + "px"; 
		$( "#FloatingDialogPanel" ).style.y = ( nY - 100 ) + "px";
	}

	$( "#DialogPanel" ).SetHasClass( "Visible", g_bSentToAll || data["JournalEntry"] );
	$( "#FloatingDialogPanel" ).SetHasClass( "Visible", !g_bSentToAll && !data["JournalEntry"] );
	$( "#DialogPanel" ).SetHasClass( "JournalEntry", data["JournalEntry"] );
	$( "#DialogTitle" ).text = $.Localize( Entities.GetUnitName( data["DialogEntIndex"] ) );
	$( "#DialogPortrait" ).SetUnit(Entities.GetUnitName( data["DialogEntIndex"] ), "", false);
	$( "#DialogPanel" ).SetHasClass( "ShowAdvanceButton", true );
	$( "#FloatingDialogPanel" ).SetHasClass( "ShowAdvanceButton", true );

	g_bShowAdvanceButton = data["ShowAdvanceButton"];
	g_nCurrentCharacter = 0;
	g_nCurrentDialogEnt = data["DialogEntIndex"];
	g_nCurrentDialogLine = data["DialogLine"];
	g_szPendingDialog = $.Localize( data["DialogText"] );
	g_szConfirmToken = data["ConfirmToken"]
	if ( !g_bSentToAll )
	{
		var szFullHeroName = Entities.GetUnitName( data["PlayerHeroEntIndex"] );
		var szHeroName = szFullHeroName.substring( 13, szFullHeroName.length );
		var szHeroLocalizedDialog = $.Localize( data["DialogText"] + szHeroName );
		if ( szHeroLocalizedDialog !== ( data["DialogText"] + szHeroName ) )
		{
			g_szPendingDialog = szHeroLocalizedDialog;
		}
		if ( data["JournalEntry"] )
		{
			g_nCurrentCharacter = g_szPendingDialog.length;
		}
	}

	$( "#DialogLabelSizer" ).text = g_szPendingDialog;
	$( "#FloatingDialogLabelSizer" ).text = g_szPendingDialog;

	$( "#DialogPanel" ).SetHasClass( "ConfirmStyle", data["DialogPlayerConfirm"] == 1 );
	$( "#DialogPlayerConfirm" ).SetHasClass( "Visible", data["DialogPlayerConfirm"] == 1) ;
	$( "#ConfirmButton" ).SetHasClass( "Visible", data["DialogPlayerConfirm"] == 1 );

	for(var i = 0; i < 8; i++)
	{	
		$("#DialogPanel").SetDialogVariableInt("player_id_"+i, i);
		var heroImage = $( '#Player' + i + 'ConfirmIcon' );
		heroImage.heroname = Players.GetPlayerSelectedHero( i );
	}

	g_flDialogAdvanceTime = Game.GetGameTime() + data["DialogAdvanceTime"];

	$.Schedule( g_flCharacterAdvanceRate, AdvanceDialogThink );
}

function AdvanceDialogThink()
{
	if ( Game.GetGameTime() > g_flDialogAdvanceTime || g_szPendingDialog === null )
	{
		if ( $( "#DialogPlayerConfirm" ).BHasClass( "Visible" ) )
		{
			GameEvents.SendCustomGameEventToServer( "dialog_confirm_expire", { ConfirmToken: g_szConfirmToken, DialogEntIndex: g_nCurrentDialogEnt, DialogLine: g_nCurrentDialogLine } );	
			GameEvents.SendCustomGameEventToServer( "dialog_complete", { DialogEntIndex : g_nCurrentDialogEnt, DialogLine : g_nCurrentDialogLine, ShowNextLine : false, PlayerHeroEntIndex : Players.GetPlayerHeroEntityIndex( Players.GetLocalPlayer() ) } );
		}
		else
		{
			$( "#DialogPanel" ).SetHasClass( "Visible", false );
			$( "#FloatingDialogPanel" ).SetHasClass( "Visible", false );
			GameEvents.SendCustomGameEventToServer( "dialog_complete", { DialogEntIndex : g_nCurrentDialogEnt, DialogLine : g_nCurrentDialogLine, ShowNextLine : false, PlayerHeroEntIndex : Players.GetPlayerHeroEntityIndex( Players.GetLocalPlayer() ) } );
		}
		return;
	}

	g_nCurrentCharacter = Math.min( g_nCurrentCharacter + 1, g_szPendingDialog.length )
	if ( g_nCurrentCharacter === g_szPendingDialog.length )
	{
		$( "#DialogLabel" ).text = g_szPendingDialog;
		$( "#FloatingDialogLabel" ).text = g_szPendingDialog;
		$( "#DialogPanel" ).SetHasClass( "ShowAdvanceButton", g_bShowAdvanceButton ); 
		$( "#FloatingDialogPanel" ).SetHasClass( "ShowAdvanceButton", g_bShowAdvanceButton ); 
	}

	$( "#DialogLabel" ).text = g_szPendingDialog.substring(0, g_nCurrentCharacter) + "<span class='HiddenText'>" + g_szPendingDialog.substring(g_nCurrentCharacter, g_szPendingDialog.length) + "</span>";
	$( "#FloatingDialogLabel" ).text = g_szPendingDialog.substring( 0, g_nCurrentCharacter );

	$.Schedule( g_flCharacterAdvanceRate, AdvanceDialogThink );
}

function OnAdvanceDialogButtonPressed()
{
	$.Msg( "AdvanceDialogButtonPressed" );
	if ( g_nCurrentCharacter < g_szPendingDialog.length )
	{
		g_nCurrentCharacter = g_szPendingDialog.length;
		AdvanceDialogThink();
		return;
	}
	else
	{
		if ( !g_bShowAdvanceButton )
		{
			$( "#DialogPanel" ).SetHasClass( "Visible", false );
			$( "#FloatingDialogPanel" ).SetHasClass( "Visible", false );
		}	
		GameEvents.SendCustomGameEventToServer( "dialog_complete", { DialogEntIndex : g_nCurrentDialogEnt, DialogLine : g_nCurrentDialogLine, ShowNextLine : g_bShowAdvanceButton, PlayerHeroEntIndex : Players.GetPlayerHeroEntityIndex( Players.GetLocalPlayer() ) } );
	}
}

function OnConfirmButtonPressed()
{
	$.Msg("Pressed Confirm Button!")
	GameEvents.SendCustomGameEventToServer( "dialog_confirm", { nPlayerID: (Players.GetLocalPlayer()), ConfirmToken: g_szConfirmToken, DialogEntIndex: g_nCurrentDialogEnt, DialogLine: g_nCurrentDialogLine } );
	$( "#ConfirmButton" ).AddClass( "Confirmed" );
}

function OnDialogPlayerConfirm( data )
{
	$.Msg(data["PlayerID"] + " confirmed the dialog!")
	$( "#Player"+data["PlayerID"]+"Confirm" ).AddClass( "Confirmed" )
}

function OnDialogPlayerAllConfirmed()
{
	$.Msg("Everyone confirmed the dialog!")
	$( "#DialogPanel" ).SetHasClass( "Visible", false );
	GameEvents.SendCustomGameEventToServer( "dialog_complete", { DialogEntIndex: g_nCurrentDialogEnt, DialogLine: g_nCurrentDialogLine, ShowNextLine : false, PlayerHeroEntIndex : Players.GetPlayerHeroEntityIndex( Players.GetLocalPlayer() ) } );
	
	$( "#ConfirmButton" ).RemoveClass( "Confirmed" );
	$( "#Player"+0+"Confirm" ).RemoveClass( "Confirmed" )
	$( "#Player"+1+"Confirm" ).RemoveClass( "Confirmed" )
	$( "#Player"+2+"Confirm" ).RemoveClass( "Confirmed" )
	$( "#Player"+3+"Confirm" ).RemoveClass( "Confirmed" )
	$( "#Player"+4+"Confirm" ).RemoveClass( "Confirmed" )
	$( "#Player"+5+"Confirm" ).RemoveClass( "Confirmed" )
	$( "#Player"+6+"Confirm" ).RemoveClass( "Confirmed" )
	$( "#Player"+7+"Confirm" ).RemoveClass( "Confirmed" )
	g_szConfirmToken = null;
}

function OnCloseDialogButtonPressed()
{
	$( "#DialogPanel" ).SetHasClass( "Visible", false );
	$( "#FloatingDialogPanel" ).SetHasClass( "Visible", false );	
	GameEvents.SendCustomGameEventToServer( "dialog_complete", { DialogEntIndex : g_nCurrentDialogEnt, DialogLine : g_nCurrentDialogLine, ShowNextLine : false, PlayerHeroEntIndex : Players.GetPlayerHeroEntityIndex( Players.GetLocalPlayer() ) } );
}

GameEvents.Subscribe( "dialog", OnDialogReceived );
GameEvents.Subscribe( "dialog_player_confirm", OnDialogPlayerConfirm);
GameEvents.Subscribe( "dialog_player_all_confirmed", OnDialogPlayerAllConfirmed);

var g_nMovingCameraOffset = 600;
var g_nStillCameraOffset = 0;
var g_flTimeSpentMoving = 0.0;
var HUD_THINK = 0.005;
var g_bInBossIntro = false;
var g_nBossCameraEntIndex = -1;
var g_flCameraDesiredOffset = 128.0;
var g_flAdditionalCameraOffset = 0.0;
var g_flMaxLookDistance = 1200.0;
var g_bSentGuideDisable = false;
var g_szLastZoneLocation = null;
var g_ZoneList = ["xhs_holdout"];

//-----------------------------------------------------------------------------------------
function intToARGB(i) 
{ 
	return ('00' + ( i & 0xFF).toString( 16 ) ).substr( -2 ) +
	('00' + ( ( i >> 8 ) & 0xFF ).toString( 16 ) ).substr( -2 ) +
	('00' + ( ( i >> 16 ) & 0xFF ).toString( 16 ) ).substr( -2 ) + 
	('00' + ( ( i >> 24 ) & 0xFF ).toString( 16 ) ).substr( -2 );
}

function OnRoundDataUpdated( table_name, key, data )
{
	UpdateRoundUI();
}
CustomNetTables.SubscribeNetTableListener( "round_data", OnRoundDataUpdated )

function UpdateRoundUI()
{
	var key = "bossHealth"
	var roundData = CustomNetTables.GetTableValue("round_data", key);

	if ( roundData !== null )
	{
		if (roundData.boss == "mag")
		{
			var nBossHP = roundData.hp;
			var bShowBossHP = roundData.hp == 0 ? false : true;
			$("#MagtheridonProgressBar").value = nBossHP / 100;
			$("#MagtheridonHP").visible = true;
		}

		if (roundData.boss2 == "true")
		{
			var nBossHP = roundData.hp2;
			var bShowBossHP = roundData.hp2 == 0 ? false : true;
			$("#Magtheridon2ProgressBar").value = nBossHP / 100;
			$("#Magtheridon2HP").visible = true;
			$("#MagtheridonHP").style.position = "-300px 0px 0px";
		}

		if (roundData.boss == "arthas")
		{
			var nBossHP = roundData.hp;
			var bShowBossHP = roundData.hp == 0 ? false : true;
			$("#ArthasProgressBar").value = nBossHP / 100;
			$("#ArthasHP").visible = true;
		}

		if (roundData.boss == "banehallow")
		{
			var nBossHP = roundData.hp;
			var bShowBossHP = roundData.hp == 0 ? false : true;
			$("#BanehallowProgressBar").value = nBossHP / 100;
			$("#BanehallowHP").visible = true;
		}

		if (roundData.boss == "lich_king")
		{
			var nBossHP = roundData.hp;
			var bShowBossHP = roundData.hp == 0 ? false : true;
			$("#LichKingProgressBar").value = nBossHP / 100;
			$("#LichKingHP").visible = true;
		}

		if (roundData.boss == "spirit_master")
		{
			var nBossHP = roundData.hp;
			var bShowBossHP = roundData.hp == 0 ? false : true;
			$("#SpiritMasterProgressBar").value = nBossHP / 100;
			$("#SpiritMasterHP").visible = true;
		}

		if (roundData.boss == "storm_spirit")
		{
			var nBossHP = roundData.hp;
			var bShowBossHP = roundData.hp == 0 ? false : true;
			$("#SpiritMasterStormProgressBar").value = nBossHP / 100;
			$("#SpiritMasterStormHP").visible = true;
		}

		if (roundData.boss3 == "true")
		{
			var nBossHP = roundData.hp3;
			var bShowBossHP = roundData.hp3 == 0 ? false : true;
			$("#SpiritMasterEarthProgressBar").value = nBossHP / 100;
			$("#SpiritMasterEarthHP").visible = true;
		}

		if (roundData.boss4 == "true")
		{
			var nBossHP = roundData.hp4;
			var bShowBossHP = roundData.hp4 == 0 ? false : true;
			$("#SpiritMasterFireProgressBar").value = nBossHP / 100;
			$("#SpiritMasterFireHP").visible = true;
		}
	}
}

function HideUI()
{
	$.GetContextPanel().FindChildTraverse("MagtheridonHP").style.visibility = "collapse";
	$.GetContextPanel().FindChildTraverse("Magtheridon2HP").style.visibility = "collapse";
	$.GetContextPanel().FindChildTraverse("ArthasHP").style.visibility = "collapse";
	$.GetContextPanel().FindChildTraverse("BanehallowHP").style.visibility = "collapse";
	$.GetContextPanel().FindChildTraverse("LichKingHP").style.visibility = "collapse";
	$.GetContextPanel().FindChildTraverse("SpiritMasterHP").style.visibility = "collapse";
	$.GetContextPanel().FindChildTraverse("SpiritMasterStormHP").style.visibility = "collapse";
	$.GetContextPanel().FindChildTraverse("SpiritMasterEarthHP").style.visibility = "collapse";
	$.GetContextPanel().FindChildTraverse("SpiritMasterFireHP").style.visibility = "collapse";
}

function CreateErrorMessage(msg){
    var reason = msg.reason || 80;
    if (msg.message){
        GameEvents.SendEventClientSide("dota_hud_error_message", {"splitscreenplayer":0,"reason":reason ,"message":msg.message} );
    }
    else{
        GameEvents.SendEventClientSide("dota_hud_error_message", {"splitscreenplayer":0,"reason":reason} );
    }
}

GameUI.CreateErrorMessage = CreateErrorMessage;

(function(){
	GameEvents.Subscribe("hide_ui", HideUI);
	GameEvents.Subscribe("dotacraft_error_message", CreateErrorMessage)
})()