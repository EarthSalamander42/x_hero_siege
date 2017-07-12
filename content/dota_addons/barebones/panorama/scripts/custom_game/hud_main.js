"use strict";

GameUI.SetCameraTerrainAdjustmentEnabled( false );

//	function OnPlayerEnteredZone( data )
//	{
//		$.Msg( "OnPlayerEnteredZone" );
//		Game.EmitSound("Dungeon.Stinger07");
//		$( "#ZoneToastPanel" ).SetHasClass( "Visible", true );
//		$( "#ZoneNameLabel" ).text = $.Localize( data["ZoneName"] );

//		$.Schedule( 10.0, HideZoneNotification );
//	}

//	function HideZoneNotification()
//	{
//		$( "#ZoneToastPanel" ).SetHasClass( "Visible", false );
//	}

//	GameEvents.Subscribe( "zone_enter", OnPlayerEnteredZone );

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
	$( "#DialogPortrait" ).SetUnit(Entities.GetUnitName( data["DialogEntIndex"] ), ""); 
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

	$("#DialogPanel").SetDialogVariableInt("player_id_0", 0);
	$("#DialogPanel").SetDialogVariableInt("player_id_1", 1);
	$("#DialogPanel").SetDialogVariableInt("player_id_2", 2);
	$("#DialogPanel").SetDialogVariableInt("player_id_3", 3);
	
	
	for(var i = 0; i < 8; i++)
	{	
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
	GameEvents.SendCustomGameEventToServer( "dialog_confirm", { nPlayerID: (Players.GetLocalPlayer()), ConfirmToken: g_szConfirmToken, DialogEntIndex: g_nCurrentDialogEnt, DialogLine: g_nCurrentDialogLine } );
	$( "#ConfirmButton" ).AddClass( "Confirmed" );
}

function OnDialogPlayerConfirm( data )
{
	$( "#Player"+data["PlayerID"]+"Confirm" ).AddClass( "Confirmed" )
}

function OnDialogPlayerAllConfirmed( data )
{
	$( "#DialogPanel" ).SetHasClass( "Visible", false );
	GameEvents.SendCustomGameEventToServer( "dialog_complete", { DialogEntIndex: g_nCurrentDialogEnt, DialogLine: g_nCurrentDialogLine, ShowNextLine : false, PlayerHeroEntIndex : Players.GetPlayerHeroEntityIndex( Players.GetLocalPlayer() ) } );
	
	$( "#ConfirmButton" ).RemoveClass( "Confirmed" );
	$( "#Player"+0+"Confirm" ).RemoveClass( "Confirmed" )
	$( "#Player"+1+"Confirm" ).RemoveClass( "Confirmed" )
	$( "#Player"+2+"Confirm" ).RemoveClass( "Confirmed" )
	$( "#Player"+3+"Confirm" ).RemoveClass( "Confirmed" )
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
var g_ZoneList = [	"xhs_holdout",
					"xhs_bosses" ];

//	(function HUDThink()
//	{	
//		var flThink = HUD_THINK;
//		if ( g_bInBossIntro === false )
//		{
//			UpdateBossHP()
//		}
//		else
//		{
//			BossHPTickUp();
//			flThink = 0.05;
//		}
//	
//	//	if ( !g_bSentToAll && $( "#FloatingDialogPanel" ).BHasClass( "Visible") )
//	//	{
//	//		var vAbsOrigin = Entities.GetAbsOrigin( g_nCurrentDialogEnt );
//	//		var nX = Game.WorldToScreenX( vAbsOrigin[0], vAbsOrigin[1], vAbsOrigin[2] );
//	//		var nY = Game.WorldToScreenY( vAbsOrigin[0], vAbsOrigin[1], vAbsOrigin[2] );
//	//		$( "#FloatingDialogPanel" ).style.x = ( nX / $( "#FloatingDialogPanel" ).actualuiscale_x ) + 25 + "px"; 
//	//		$( "#FloatingDialogPanel" ).style.y = ( nY / $( "#FloatingDialogPanel" ).actualuiscale_y  ) - 100 + "px";
//	//	}
//	
//		var playerZoneData = CustomNetTables.GetTableValue( "player_zone_locations", Players.GetLocalPlayer().toString() );
//		if (  typeof(playerZoneData) !== "undefined" )
//		{
//			var zoneName = playerZoneData["ZoneName"];
//		 	if ( g_szLastZoneLocation !== zoneName )
//		 	{
//		 		if ( g_szLastZoneLocation !== null )
//		 		{
//		 			$( "#DungeonHUDContents" ).RemoveClass( g_szLastZoneLocation );
//		 		}
//		 		$.Msg("ZONE NAME: ", zoneName)
//		 		$( "#DungeonHUDContents" ).SetHasClass( zoneName, true );
//		 		g_szLastZoneLocation = zoneName;
//		 	}
//		}
//	
//	//	$( "#DungeonHUDContents" ).SetHasClass( "HasAbilityToSpend", Entities.GetAbilityPoints( Players.GetLocalPlayerPortraitUnit() ) > 0 );
//	
//		if( !g_bSentGuideDisable )
//		{
//			$.DispatchEvent( 'DOTAShopSetGuideVisibility', false);
//			g_bSentGuideDisable = true;
//		}
//	
//		if ( Entities.GetUnitName( Players.GetLocalPlayerPortraitUnit() ) === "npc_dota_creature_invoker" && Game.IsShopOpen() === false )
//		{
//			Game.SetCustomShopEntityString( "invoker_shop" );
//			$.DispatchEvent( "DOTAHUDShopOpened", DOTA_SHOP_TYPE.DOTA_SHOP_CUSTOM, true );
//		}
//		
//		$.Schedule( flThink, HUDThink );
//	})();
//	
//	(function CameraThink() {
//	    if (g_bInBossIntro === false)
//	    {
//	    	if ( Game.GetState() < DOTA_GameState.DOTA_GAMERULES_STATE_POST_GAME )
//	    	{
//	        	UpdateCameraOffset();
//	        }
//	    }
//	    $.Schedule(0, CameraThink);
//	})();

//	CustomNetTables.SubscribeNetTableListener( "boss", UpdateBossHP )

//	function UpdateBossHP()
//	{
//		var key = 0;
//		var bossData = CustomNetTables.GetTableValue( "boss", key.toString() );
//		if ( typeof( bossData ) != "undefined" )
//		{
//			var nBossHP = bossData["boss_hp"];
//			var bShowBossHP = bossData["boss_hp"] == 0 ? false : true;
//			$( "#BossProgressBar" ).value = nBossHP / 100;
//			$( "#BossHP").SetHasClass( "Visible", bShowBossHP );
//		}
//	}

function BossHPTickUp()
{
	if ( $( "#BossProgressBar" ).value < 1.0 )
	{
		$( "#BossProgressBar" ).value = $( "#BossProgressBar" ).value + 0.025;
	}
}

function OnBossIntroBegin( data )
{
	$( "#BossProgressBar" ).value = 0;
	$( "#BossHP").SetHasClass( data["BossName"], true );
	$( "#BossIcon" ).SetHasClass( data["BossName"], true );
	$( "#BossLabel" ).text = $.Localize( data["BossName"] );
	
	if ( g_bInBossIntro === true )
		return;

	if ( data["SkipIntro"] )
		return;

	Game.EmitSound( "Dungeon.Stinger02" );
	Game.EmitSound( "Dungeon.BossBar" );

	$( "#BossHP").SetHasClass( "Visible", true );

	$( "#DialogPanel" ).SetHasClass( "Visible", data["DialogText"] != "" );
	$( "#DialogTitle" ).text = $.Localize( Entities.GetUnitName( data["DialogEntIndex"] ) );
	g_nCurrentDialogEnt = data["DialogEntIndex"];
	g_nCurrentDialogLine = data["DialogLine"];
	$( "#DialogLabel" ).text = $.Localize( data["DialogText"] );
	$( "#DialogLabelSizer" ).text = $.Localize( data["DialogText"] );
	
	g_bInBossIntro = true;
	g_nBossCameraEntIndex = data["BossEntIndex"];

	if ( typeof( data["CameraPitch"] ) != "undefined" )
	{
		GameUI.SetCameraPitchMin( data["CameraPitch"] );
		GameUI.SetCameraPitchMax( data["CameraPitch"] );
	}
	if ( typeof( data["CameraDistance"] ) != "undefined" )
	{
		GameUI.SetCameraDistance( data["CameraDistance"] );
	}
	if ( typeof( data["CameraDistance"] ) != "undefined" )
	{
		GameUI.SetCameraLookAtPositionHeightOffset( data["CameraDistance"] );
	}
	
	
	UpdateCameraOffset();
}

GameEvents.Subscribe( "boss_intro_begin", OnBossIntroBegin );

function OnBossIntroEnd( data )
{
	g_bInBossIntro = false;
	g_nBossCameraEntIndex = -1;
	GameUI.SetCameraPitchMin( 38 );
	GameUI.SetCameraPitchMax( 60 );
	GameUI.SetCameraDistance( 1134.0 );
	GameUI.SetCameraLookAtPositionHeightOffset( 0 );
	$( "#DialogPanel" ).SetHasClass( "Visible", false );
	UpdateCameraOffset();
}

GameEvents.Subscribe( "boss_intro_end", OnBossIntroEnd );

function OnBossFightFinished( data )
{
	$( "#BossProgressBar" ).value = 0;
	$( "#BossHP").SetHasClass( data["BossName"], false );
	$( "#BossIcon" ).SetHasClass( data["BossName"], false );
	Game.EmitSound( "Dungeon.Stinger01" );
}

GameEvents.Subscribe( "boss_fight_finished", OnBossFightFinished );

var g_nCachedCameraEntIndex = -1;

function UpdateCameraOffset()
{
	var localCamFollowIndex = Players.GetPlayerHeroEntityIndex( Players.GetLocalPlayer() );
	//handle spectators
	if ( Players.IsLocalPlayerInPerspectiveCamera() )
	{
		localCamFollowIndex = Players.GetPerspectivePlayerEntityIndex();
	}

	if ( g_nBossCameraEntIndex !== -1 )
	{
		localCamFollowIndex = g_nBossCameraEntIndex;
	}
	if ( localCamFollowIndex !== -1 )
	{
		if ( Entities.IsAlive( localCamFollowIndex ) === false )
			return;

		var vDesiredLookAtPosition = Entities.GetAbsOrigin( localCamFollowIndex );
		var vLookAtPos = GameUI.GetCameraLookAtPosition();
		var flCurOffset = GameUI.GetCameraLookAtPositionHeightOffset();
		var flCameraRawHeight = vLookAtPos[2] - flCurOffset;
		var flEntityHeight = vDesiredLookAtPosition[2];
		vDesiredLookAtPosition[1] = vDesiredLookAtPosition[1] - 180.0;
		
		var bMouseWheelDown = GameUI.IsMouseDown( 2 );
		if ( bMouseWheelDown )
		{
			var vScreenWorldPos = GameUI.GetScreenWorldPosition( GameUI.GetCursorPosition() );
			if ( vScreenWorldPos !== null )
			{
				var vToCursor = [];
				vToCursor[0] = vScreenWorldPos[0] - vDesiredLookAtPosition[0];
				vToCursor[1] = vScreenWorldPos[1] - vDesiredLookAtPosition[1];
				vToCursor[2] = vScreenWorldPos[2] - vDesiredLookAtPosition[2];
				vToCursor = Game.Normalized( vToCursor );
				var flDistance = Math.min( Game.Length2D( vScreenWorldPos, vDesiredLookAtPosition ), g_flMaxLookDistance );
				vDesiredLookAtPosition[0] = vDesiredLookAtPosition[0] + vToCursor[0] * flDistance;
				vDesiredLookAtPosition[1] = vDesiredLookAtPosition[1] + vToCursor[1] * flDistance;
				vDesiredLookAtPosition[2] = vDesiredLookAtPosition[2] + vToCursor[2] * flDistance;
			}
		}

		var flHeightDiff = flCameraRawHeight - flEntityHeight;
		var flNewOffset = g_flCameraDesiredOffset - flHeightDiff + 50;
		var key = 0;
		var bossData = CustomNetTables.GetTableValue("boss", key.toString());
		var flAdditionalOffset = 0.0;
		if ( typeof( bossData ) != "undefined" )
		{
			var bShowBossHP = bossData["boss_hp"] == 0 ? false : true;
			if ( bShowBossHP )
			{
			    flAdditionalOffset = 100.0;
			}
		}

		var t = Game.GetGameFrameTime() / 1.5;
		if ( t > 1.0 ) { t = 1.0; }

		g_flAdditionalCameraOffset = g_flAdditionalCameraOffset * t + flAdditionalOffset * ( 1.0 - t ); 
		flNewOffset = flNewOffset + g_flAdditionalCameraOffset;

		var flLerp = 0.05;
		if ( bMouseWheelDown )
		{
			flLerp = 0.1;
		}
		if ( g_nCachedCameraEntIndex !== localCamFollowIndex )
		{
			flLerp = 1.5;
		}

		GameUI.SetCameraTargetPosition(vDesiredLookAtPosition, flLerp);
		GameUI.SetCameraLookAtPositionHeightOffset( flNewOffset );

		g_nCachedCameraEntIndex = localCamFollowIndex;
	}
	else
	{
		GameUI.SetCameraLookAtPositionHeightOffset( 0.0 );
	}
}

GameEvents.Subscribe( "boss_intro_end", OnBossIntroEnd );

//	function HideScroll( data )
//	{
//		$.Msg( "HideScroll" );
//		var hitBoxPanel = $( '#TPScrollHitbox' );
//		hitBoxPanel.RemoveClass( "MakeVisible" );			
//		var clickHint = $( '#ClickHint' );
//		clickHint.AddClass( "QuickHide" );
//	
//		var scenePanelContainer = $( '#TPScrollContainer' );
//		scenePanelContainer.AddClass( "CollapsePanel" );
//	}

//	GameEvents.Subscribe( "hide_scroll", HideScroll );

function OnCheckpointActivated( data )
{
	$.Schedule( 3.0, HideCheckpointActivation );
}

GameEvents.Subscribe( "checkpoint_activated", OnCheckpointActivated );

function HideCheckpointActivation()
{
}

function OnGainedLife( data )
{
	var panel = $( '#1UpPopup' );
	panel.SetHasClass( "Play1Up", true );
	var heroImage = $( '#1UpHeroIcon' );
	var heroImageShadow = $( '#1UpHeroIconOutline' );
	var localPlayerInfo = Game.GetLocalPlayerInfo();
	var heroName = Players.GetPlayerSelectedHero( localPlayerInfo.player_id );
	heroImage.heroname = heroName;
	heroImageShadow.heroname = heroName;
	Game.EmitSound( "Dungeon.Plus1" );
	$.Schedule( 3.0, HideGainedLife );
}

GameEvents.Subscribe( "gained_life", OnGainedLife );

function HideGainedLife()
{
	var panel = $( '#1UpPopup' );
	panel.SetHasClass( "Play1Up", false );
}

//	function OnLostLife( data )
//	{
//		var panel = $( '#1UpPopup' );
//	//	panel.SetHasClass( "Play1Up", true );
//	//	panel.SetHasClass( "LifeLost", true );
//		var heroImage = $( '#1UpHeroIcon' );
//		var heroImageShadow = $( '#1UpHeroIconOutline' );
//		var localPlayerInfo = Game.GetLocalPlayerInfo();
//		var heroName = Players.GetPlayerSelectedHero( localPlayerInfo.player_id );
//		heroImage.heroname = heroName;
//		heroImageShadow.heroname = heroName;
//		//Game.EmitSound( "Dungeon.Plus1" );
//		$.Schedule( 3.0, HideLostLife );
//	}

//	GameEvents.Subscribe( "life_lost", OnLostLife );

function HideLostLife()
{
	var panel = $( '#1UpPopup' );
//	panel.SetHasClass( "Play1Up", false );
//	panel.SetHasClass( "LifeLost", false );
}
