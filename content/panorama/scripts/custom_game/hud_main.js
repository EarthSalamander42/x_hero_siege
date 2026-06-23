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
	$( "#DialogTitle" ).text = $.Localize( "#" + Entities.GetUnitName( data["DialogEntIndex"] ) );
	$( "#DialogPortrait" ).SetUnit(Entities.GetUnitName( data["DialogEntIndex"] ), "", false);
	$( "#DialogPanel" ).SetHasClass( "ShowAdvanceButton", true );
	$( "#FloatingDialogPanel" ).SetHasClass( "ShowAdvanceButton", true );

	g_bShowAdvanceButton = data["ShowAdvanceButton"];
	g_nCurrentCharacter = 0;
	g_nCurrentDialogEnt = data["DialogEntIndex"];
	g_nCurrentDialogLine = data["DialogLine"];
	g_szPendingDialog = $.Localize( "#" + data["DialogText"] );
	g_szConfirmToken = data["ConfirmToken"]
	if ( !g_bSentToAll )
	{
		var szFullHeroName = Entities.GetUnitName( data["PlayerHeroEntIndex"] );
		var szHeroName = szFullHeroName.substring( 13, szFullHeroName.length );
		var szHeroLocalizedDialog = $.Localize( "#" + data["DialogText"] + szHeroName );
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
	GameEvents.SendCustomGameEventToServer( "dialog_confirm", { nPlayerID: (Players.GetLocalPlayer()), ConfirmToken: g_szConfirmToken, DialogEntIndex: g_nCurrentDialogEnt, DialogLine: g_nCurrentDialogLine } );
	$( "#ConfirmButton" ).AddClass( "Confirmed" );
}

function OnDialogPlayerConfirm( data )
{
	$( "#Player"+data["PlayerID"]+"Confirm" ).AddClass( "Confirmed" )
}

function OnDialogPlayerAllConfirmed()
{
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

function UpdateRoundUI() {
	var key = "bossHealth"
	var roundData = CustomNetTables.GetTableValue("round_data", key);

	if ( roundData !== null ) {
		$.Msg(roundData);
		if (roundData.boss) {
		// if (roundData.boss == "arthas") {
			var nBossHP = roundData.hp;
			// var bShowBossHP = roundData.hp == 0 ? false : true;
			$("#BossProgressBar").value = nBossHP / 100;
			$("#BossHP").visible = true;
		}
	}
}

function HideUI() {
	$.GetContextPanel().FindChildTraverse("BossHP").style.visibility = "collapse";
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

var XHS_TOME_COST = 10000;
var g_nXHSBuyTomeCount = 0;
var g_nXHSBuyTomeHeroEntIndex = -1;
var g_nXHSBuyTomePositionRetries = 0;

function GetXHSDotaHudRoot()
{
	var panel = $.GetContextPanel();
	while ( panel && panel.id !== "Hud" )
	{
		panel = panel.GetParent();
	}
	return panel;
}

function FindXHSDotaHudElement( id )
{
	var hud = GetXHSDotaHudRoot();
	return hud ? hud.FindChildTraverse( id ) : null;
}

function GetXHSBuyTomeButton()
{
	var config = GameUI.CustomUIConfig ? GameUI.CustomUIConfig() : null;
	return ( config && config.XHSBuyTomeButton ) || FindXHSDotaHudElement( "XHSBuyTomeButton" ) || $( "#XHSBuyTomeButton" ) || FindXHSDotaHudElement( "XHSBuyTomeButtonDefault" );
}

function CreateXHSBuyTomeButton( parent )
{
	var config = GameUI.CustomUIConfig ? GameUI.CustomUIConfig() : null;
	if ( config && config.CreateXHSBuyTomeButton )
	{
		return config.CreateXHSBuyTomeButton( parent );
	}

	return GetXHSBuyTomeButton();
}

function GetXHSActiveCenterBlock()
{
	var hud = GetXHSDotaHudRoot();
	if ( !hud )
	{
		return null;
	}

	var hudElements = hud.FindChildTraverse( "HUDElements" );
	var lowerHud = hudElements ? hudElements.FindChildTraverse( "lower_hud" ) : null;
	var centerWithStats = lowerHud ? lowerHud.FindChildTraverse( "center_with_stats" ) : null;
	return centerWithStats ? centerWithStats.FindChildTraverse( "center_block" ) : null;
}

function GetXHSLocalHeroInfo()
{
	var playerID = Players.GetLocalPlayer();
	var entIndex = playerID >= 0 ? Players.GetPlayerHeroEntityIndex( playerID ) : -1;
	var unitName = entIndex > 0 ? Entities.GetUnitName( entIndex ) : "";

	return {
		entIndex: entIndex,
		unitName: unitName || ""
	};
}

function IsXHSBuyTomeHeroReady()
{
	var hero = GetXHSLocalHeroInfo();

	if ( hero.entIndex <= 0 || hero.unitName === "" || hero.unitName === "npc_dota_hero_wisp" )
	{
		return false;
	}

	if ( hero.entIndex !== g_nXHSBuyTomeHeroEntIndex )
	{
		g_nXHSBuyTomeHeroEntIndex = hero.entIndex;
		g_nXHSBuyTomePositionRetries = 0;
	}

	return true;
}

function FindXHSBuyTomeInsertionAnchor( centerBlock )
{
	if ( !centerBlock )
	{
		return null;
	}

	var abilities = centerBlock.FindChildTraverse( "abilities" );
	if ( abilities )
	{
		if ( abilities.GetParent && abilities.GetParent() === centerBlock )
		{
			return abilities;
		}

		var abilityParent = abilities.GetParent ? abilities.GetParent() : null;
		if ( abilityParent && abilityParent.GetParent && abilityParent.GetParent() === centerBlock )
		{
			return abilityParent;
		}
	}

	var ability0 = centerBlock.FindChildTraverse( "Ability0" );
	var ability0Parent = ability0 && ability0.GetParent ? ability0.GetParent() : null;
	if ( ability0Parent && ability0Parent.GetParent && ability0Parent.GetParent() === centerBlock )
	{
		return ability0Parent;
	}

	return centerBlock.FindChildTraverse( "AbilitiesAndStatBranch" );
}

function GetXHSLocalGold()
{
	var playerID = Players.GetLocalPlayer();

	if ( typeof PlayerTables !== "undefined" && PlayerTables && PlayerTables.GetTableValue )
	{
		var goldTable = PlayerTables.GetTableValue( "gold", "gold" );
		if ( goldTable && goldTable[playerID] !== undefined )
		{
			return Number( goldTable[playerID] ) || 0;
		}
	}

	if ( Players.GetGold )
	{
		return Players.GetGold( playerID ) || 0;
	}

	return 0;
}

function InjectBuyTomeButtonIntoCenterBlock()
{
	var button = GetXHSBuyTomeButton();
	var centerBlock = GetXHSActiveCenterBlock();
	var anchor = FindXHSBuyTomeInsertionAnchor( centerBlock );
	if ( !centerBlock || !anchor )
	{
		if ( button )
		{
			button.style.visibility = "collapse";
		}
		return false;
	}

	if ( !button || ( button.GetParent && button.GetParent() !== centerBlock && !button.SetParent ) )
	{
		button = CreateXHSBuyTomeButton( centerBlock );
	}

	if ( !button )
	{
		return false;
	}

	if ( !IsXHSBuyTomeHeroReady() )
	{
		button.style.visibility = "collapse";
		return false;
	}

	var rootButton = $( "#XHSBuyTomeButton" );
	if ( rootButton && rootButton !== button && rootButton.GetParent && rootButton.GetParent() !== centerBlock )
	{
		rootButton.style.visibility = "collapse";
	}

	if ( button.SetParent )
	{
		button.SetParent( centerBlock );
	}

	if ( centerBlock.MoveChildAfter )
	{
		centerBlock.MoveChildAfter( button, anchor );
	}

	button.AddClass( "XHSInjectedIntoCenterBlock" );
	button.style.x = "0px";
	button.style.y = "0px";
	button.style.visibility = "visible";
	return true;
}

function UpdateBuyTomeButton()
{
	var button = GetXHSBuyTomeButton();
	if ( !button )
	{
		button = CreateXHSBuyTomeButton( GetXHSActiveCenterBlock() );
	}

	var countLabel = button ? ( button.FindChildTraverse( "XHSBuyTomeCount" ) || button.FindChildTraverse( "XHSBuyTomeCountDefault" ) ) : null;
	if ( !button || !countLabel )
	{
		$.Schedule( 0.25, UpdateBuyTomeButton );
		return;
	}

	var playerID = Players.GetLocalPlayer();
	if ( playerID < 0 || Players.IsSpectator( playerID ) )
	{
		button.style.visibility = "collapse";
		$.Schedule( 0.5, UpdateBuyTomeButton );
		return;
	}

	if ( !IsXHSBuyTomeHeroReady() )
	{
		button.style.visibility = "collapse";
		$.Schedule( 0.25, UpdateBuyTomeButton );
		return;
	}

	var gold = GetXHSLocalGold();
	g_nXHSBuyTomeCount = Math.max( 0, Math.floor( gold / XHS_TOME_COST ) );
	countLabel.text = "x" + g_nXHSBuyTomeCount;
	button.SetHasClass( "NoTomes", g_nXHSBuyTomeCount < 1 );

	if ( !InjectBuyTomeButtonIntoCenterBlock() )
	{
		g_nXHSBuyTomePositionRetries++;
		$.Schedule( g_nXHSBuyTomePositionRetries < 10 ? 0.1 : 0.25, UpdateBuyTomeButton );
		return;
	}

	g_nXHSBuyTomePositionRetries = 0;
	$.Schedule( 0.25, UpdateBuyTomeButton );
}

function OnBuyTomeButtonPressed()
{
	GameEvents.SendCustomGameEventToServer( "xhs_buy_tomes", {} );
}

function ShowBuyTomeTooltip()
{
	var button = GetXHSBuyTomeButton();
	if ( button )
	{
		$.DispatchEvent( "DOTAShowAbilityTooltip", button, "item_tome_small" );
	}
}

function HideBuyTomeTooltip()
{
	var button = GetXHSBuyTomeButton();
	if ( button )
	{
		$.DispatchEvent( "DOTAHideAbilityTooltip", button );
	}
}

// Ancient position: 0, -3500, 0

/*
SetPlayersCameraPosition({
	hPosition: "-6520.0 2048.0 128.0",
})
*/

function SetPlayersCameraPosition(keys) {
	if (!keys.iSpeed)
		keys.iSpeed = 2.0;

	if (!keys.hPosition) {
		$.Msg("ERROR: MISSING CAMERA POSITION!!")
		return;
	}

//	if (keys && keys.bStopLoop) {

//		return;
//	} else {
		if (keys && keys.hPosition) {
			keys.hPosition = keys.hPosition.split(" ");
			GameUI.SetCameraTargetPosition([keys.hPosition[0], keys.hPosition[1], keys.hPosition[2]], keys.iSpeed);
//			$.Schedule(0.03, function() {
//				SetPlayersCameraPosition(keys);
//			});
		}
//	}
}

(function(){
	GameEvents.Subscribe("hide_ui", HideUI);
	GameEvents.Subscribe("dotacraft_error_message", CreateErrorMessage)
	GameEvents.Subscribe("set_player_camera", SetPlayersCameraPosition)
	var tomeButton = GetXHSBuyTomeButton();
	if ( tomeButton )
	{
		tomeButton.SetPanelEvent( "onmouseover", ShowBuyTomeTooltip );
		tomeButton.SetPanelEvent( "onmouseout", HideBuyTomeTooltip );
	}
	UpdateBuyTomeButton();
})()
