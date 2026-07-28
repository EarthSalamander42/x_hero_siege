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
var XHS_DIALOG_MAX_PLAYERS = 8;
var g_bXHSDialogDevPreview = false;
var g_nXHSDialogDevPreviewPlayers = 0;
var XHS_DIALOG_DEV_HEROES = [
	{ unit: "npc_dota_hero_ancient_apparition", name: "ARCHMAGE" },
	{ unit: "npc_dota_hero_windrunner", name: "DRYAD" },
	{ unit: "npc_dota_hero_terrorblade", name: "DEMON HUNTER" },
	{ unit: "npc_dota_hero_elder_titan", name: "TAUREN CHIEFTAIN" },
	{ unit: "npc_dota_hero_lich", name: "LICH" },
	{ unit: "npc_dota_hero_juggernaut", name: "BLADEMASTER" },
	{ unit: "npc_dota_hero_night_stalker", name: "DREAD LORD" },
	{ unit: "npc_dota_hero_lina", name: "SORCERESS" }
];

function IsXHSDialogPlayerPresent( playerID )
{
	if ( g_bXHSDialogDevPreview )
	{
		return playerID >= 0 && playerID < g_nXHSDialogDevPreviewPlayers;
	}

	return Players.IsValidPlayerID( playerID ) &&
		Players.GetTeam( playerID ) === DOTATeam_t.DOTA_TEAM_GOODGUYS;
}

function ResetXHSDialogPlayerConfirms()
{
	for ( var i = 0; i < XHS_DIALOG_MAX_PLAYERS; i++ )
	{
		var playerPanel = $( "#Player" + i + "Confirm" );
		if ( playerPanel )
		{
			playerPanel.RemoveClass( "Confirmed" );
		}
	}
}

function RefreshXHSDialogPlayers()
{
	var activePlayerCount = 0;
	for ( var i = 0; i < XHS_DIALOG_MAX_PLAYERS; i++ )
	{
		var playerPanel = $( "#Player" + i + "Confirm" );
		var heroImage = $( "#Player" + i + "ConfirmIcon" );
		var heroNameLabel = $( "#Player" + i + "ConfirmName" );
		var isPresent = IsXHSDialogPlayerPresent( i );

		if ( playerPanel )
		{
			playerPanel.SetHasClass( "ActivePlayer", isPresent );
		}

		if ( isPresent )
		{
			activePlayerCount++;
			var heroUnitName = "";
			var localizedHeroName = "";
			if ( g_bXHSDialogDevPreview )
			{
				var previewHero = XHS_DIALOG_DEV_HEROES[i] || XHS_DIALOG_DEV_HEROES[0];
				heroUnitName = previewHero.unit;
				localizedHeroName = previewHero.name;
			}
			else
			{
				var heroEntityIndex = Players.GetPlayerHeroEntityIndex( i );
				if ( heroEntityIndex !== -1 )
				{
					heroUnitName = Entities.GetUnitName( heroEntityIndex );
				}
				heroUnitName = heroUnitName || Players.GetPlayerSelectedHero( i );
			}

			if ( heroImage )
			{
				heroImage.heroname = heroUnitName;
			}

			if ( heroNameLabel )
			{
				localizedHeroName = localizedHeroName || ( heroUnitName ? $.Localize( "#" + heroUnitName ) : "" );
				if ( !localizedHeroName || localizedHeroName === heroUnitName || localizedHeroName === ( "#" + heroUnitName ) )
				{
					localizedHeroName = String( heroUnitName || "Hero" ).replace( "npc_dota_hero_", "" ).replace( /_/g, " " );
				}
				if ( typeof XHSNameDisplay !== "undefined" && XHSNameDisplay.Resolve )
				{
					heroNameLabel.text = XHSNameDisplay.Resolve( {
						playerID: i,
						playerName: g_bXHSDialogDevPreview ? ( "Player " + ( i + 1 ) ) : "",
						heroName: heroUnitName,
						heroDisplayName: localizedHeroName
					} );
				}
				else
				{
					// Privacy-safe fallback: never expose a persona name.
					heroNameLabel.text = localizedHeroName;
				}
			}
		}
		else if ( heroNameLabel )
		{
			heroNameLabel.text = "";
		}
	}

	var confirmPanel = $( "#DialogPlayerConfirm" );
	if ( confirmPanel )
	{
		confirmPanel.SetHasClass( "PartySolo", activePlayerCount <= 1 );
		confirmPanel.SetHasClass( "PartyMedium", activePlayerCount > 1 && activePlayerCount <= 4 );
		confirmPanel.SetHasClass( "PartyFull", activePlayerCount > 4 );
	}
}

function OnDialogReceived( data )
{
	if ( data["DialogText"] ===  "" )
		return;

	g_bXHSDialogDevPreview = data["DevPreview"] == 1;
	g_nXHSDialogDevPreviewPlayers = g_bXHSDialogDevPreview ? Math.max( 0, Math.min( XHS_DIALOG_MAX_PLAYERS, Number( data["PreviewPlayerCount"] || 1 ) ) ) : 0;
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
	var dialogUnitName = data["SpeakerUnitName"] || Entities.GetUnitName( data["DialogEntIndex"] );
	$( "#DialogTitle" ).text = data["SpeakerName"] || $.Localize( "#" + dialogUnitName );
	$( "#DialogPortrait" ).SetUnit( dialogUnitName, "", false );
	$( "#DialogPanel" ).SetHasClass( "ShowAdvanceButton", true );
	$( "#FloatingDialogPanel" ).SetHasClass( "ShowAdvanceButton", true );

	g_bShowAdvanceButton = data["ShowAdvanceButton"];
	g_nCurrentCharacter = 0;
	g_nCurrentDialogEnt = data["DialogEntIndex"];
	g_nCurrentDialogLine = data["DialogLine"];
	g_szPendingDialog = data["RawDialogText"] == 1 ? data["DialogText"] : $.Localize( "#" + data["DialogText"] );
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
	ResetXHSDialogPlayerConfirms();
	RefreshXHSDialogPlayers();

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
		if ( g_bXHSDialogDevPreview )
		{
			$( "#DialogPanel" ).SetHasClass( "Visible", false );
			return;
		}

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
	if ( g_bXHSDialogDevPreview )
	{
		for ( var i = 0; i < g_nXHSDialogDevPreviewPlayers; i++ )
		{
			var previewPanel = $( "#Player" + i + "Confirm" );
			if ( previewPanel )
			{
				previewPanel.AddClass( "Confirmed" );
			}
		}
		$( "#ConfirmButton" ).AddClass( "Confirmed" );
		return;
	}

	GameEvents.SendCustomGameEventToServer( "dialog_confirm", { nPlayerID: (Players.GetLocalPlayer()), ConfirmToken: g_szConfirmToken, DialogEntIndex: g_nCurrentDialogEnt, DialogLine: g_nCurrentDialogLine } );
	$( "#ConfirmButton" ).AddClass( "Confirmed" );
}

function OnXHSDialogDevPreviewClose()
{
	g_bXHSDialogDevPreview = false;
	g_nXHSDialogDevPreviewPlayers = 0;
	g_szPendingDialog = null;
	$( "#DialogPanel" ).SetHasClass( "Visible", false );
	$( "#FloatingDialogPanel" ).SetHasClass( "Visible", false );
	$( "#ConfirmButton" ).RemoveClass( "Confirmed" );
	ResetXHSDialogPlayerConfirms();
}

function OnDialogPlayerConfirm( data )
{
	var playerPanel = $( "#Player" + data["PlayerID"] + "Confirm" );
	if ( playerPanel && playerPanel.BHasClass( "ActivePlayer" ) )
	{
		playerPanel.AddClass( "Confirmed" );
	}
}

function OnDialogPlayerAllConfirmed()
{
	$( "#DialogPanel" ).SetHasClass( "Visible", false );
	GameEvents.SendCustomGameEventToServer( "dialog_complete", { DialogEntIndex: g_nCurrentDialogEnt, DialogLine: g_nCurrentDialogLine, ShowNextLine : false, PlayerHeroEntIndex : Players.GetPlayerHeroEntityIndex( Players.GetLocalPlayer() ) } );
	
	$( "#ConfirmButton" ).RemoveClass( "Confirmed" );
	ResetXHSDialogPlayerConfirms();
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
GameEvents.Subscribe( "xhs_dialog_dev_preview_close", OnXHSDialogDevPreviewClose );

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
var XHS_REINCARNATION_PORTRAIT_REFRESH_SECONDS = 0.1;
var g_pXHSReincarnationPortraitOverlay = null;

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
var g_nXHSBuyTomeSelectedPlayerID = -1;
var g_bXHSBuyTomeLocked = false;
var g_sXHSBuyTomeLockReason = "";
var g_bXHSTomeAutoBuyEnabled = false;

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

function GetXHSReincarnationGameTime()
{
	if ( typeof Game.GetGameTime === "function" )
	{
		return Game.GetGameTime();
	}

	return Game.GetDOTATime( false, false );
}

function GetXHSLocalReincarnationState( entIndex )
{
	if ( entIndex <= 0 )
	{
		return { active: false, remaining: 0 };
	}

	var data = CustomNetTables.GetTableValue( "player_table", entIndex.toString() + "_reincarnation" ) || {};
	var active = Number( data.active ) > 0;
	var endTime = Number( data.end_time ) || 0;

	return {
		active: active,
		remaining: active ? Math.max( 0, endTime - GetXHSReincarnationGameTime() ) : 0
	};
}

function EnsureXHSReincarnationPortraitOverlay()
{
	if ( g_pXHSReincarnationPortraitOverlay && ( !g_pXHSReincarnationPortraitOverlay.IsValid || g_pXHSReincarnationPortraitOverlay.IsValid() ) )
	{
		return g_pXHSReincarnationPortraitOverlay;
	}

	var portraitContainer = FindXHSDotaHudElement( "PortraitContainer" );
	if ( !portraitContainer )
	{
		g_pXHSReincarnationPortraitOverlay = null;
		return null;
	}

	var overlay = portraitContainer.FindChildTraverse( "XHSReincarnationPortraitOverlay" );
	if ( !overlay )
	{
		overlay = $.CreatePanel( "Panel", portraitContainer, "XHSReincarnationPortraitOverlay" );
		overlay.hittest = false;

		var glow = $.CreatePanel( "Panel", overlay, "XHSReincarnationPortraitGlow" );
		glow.hittest = false;

		var timeLabel = $.CreatePanel( "Label", overlay, "XHSReincarnationPortraitTime" );
		timeLabel.hittest = false;

		var caption = $.CreatePanel( "Label", overlay, "XHSReincarnationPortraitCaption" );
		caption.hittest = false;
		caption.text = $.Localize( "#DOTA_Tooltip_modifier_reincarnation" );
	}

	g_pXHSReincarnationPortraitOverlay = overlay;
	return overlay;
}

function UpdateXHSReincarnationPortrait()
{
	var overlay = EnsureXHSReincarnationPortraitOverlay();
	if ( !overlay )
	{
		$.Schedule( XHS_REINCARNATION_PORTRAIT_REFRESH_SECONDS, UpdateXHSReincarnationPortrait );
		return;
	}

	var playerID = Players.GetLocalPlayer();
	var entIndex = playerID >= 0 ? Players.GetPlayerHeroEntityIndex( playerID ) : -1;
	var portraitEntIndex = Players.GetLocalPlayerPortraitUnit ? Players.GetLocalPlayerPortraitUnit() : entIndex;
	var state = GetXHSLocalReincarnationState( entIndex );
	var isAlive = entIndex > 0 && Entities.IsAlive ? Entities.IsAlive( entIndex ) : true;
	var visible = entIndex > 0 && portraitEntIndex === entIndex && !isAlive && state.active && state.remaining > 0;

	overlay.SetHasClass( "Visible", visible );

	var timeLabel = overlay.FindChildTraverse( "XHSReincarnationPortraitTime" );
	if ( timeLabel )
	{
		timeLabel.text = visible ? Math.ceil( state.remaining ).toString() : "";
	}

	$.Schedule( XHS_REINCARNATION_PORTRAIT_REFRESH_SECONDS, UpdateXHSReincarnationPortrait );
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

function ApplyXHSBuyTomeButtonStyle( button, options )
{
	var config = GameUI.CustomUIConfig ? GameUI.CustomUIConfig() : null;
	if ( config && config.ApplyXHSBuyTomeButtonStyle )
	{
		config.ApplyXHSBuyTomeButtonStyle( button, options || {} );
	}
}

function EnsureXHSBuyTomeDisabledOverlay( button )
{
	var config = GameUI.CustomUIConfig ? GameUI.CustomUIConfig() : null;
	if ( config && config.EnsureXHSBuyTomeDisabledOverlay )
	{
		config.EnsureXHSBuyTomeDisabledOverlay( button );
	}
}

function EnsureXHSBuyTomeAutoBuyHint( button )
{
	var config = GameUI.CustomUIConfig ? GameUI.CustomUIConfig() : null;
	if ( config && config.EnsureXHSBuyTomeAutoBuyHint )
	{
		return config.EnsureXHSBuyTomeAutoBuyHint( button );
	}

	return null;
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

function IsXHSPlayerHeroEntity( entIndex )
{
	if ( entIndex <= 0 || !Entities.IsValidEntity || !Entities.IsValidEntity( entIndex ) )
	{
		return false;
	}

	var playerID = Entities.GetPlayerOwnerID ? Entities.GetPlayerOwnerID( entIndex ) : -1;
	if ( playerID < 0 )
	{
		return false;
	}

	if ( typeof PlayerResource !== "undefined" && PlayerResource.IsValidPlayerID && !PlayerResource.IsValidPlayerID( playerID ) )
	{
		return false;
	}

	if ( Entities.IsRealHero )
	{
		return Entities.IsRealHero( entIndex );
	}

	if ( Entities.IsHero )
	{
		return Entities.IsHero( entIndex ) && ( !Entities.IsIllusion || !Entities.IsIllusion( entIndex ) );
	}

	return entIndex === Players.GetPlayerHeroEntityIndex( playerID );
}

function GetXHSBuyTomeSelectedHeroInfo()
{
	var localPlayerID = Players.GetLocalPlayer();
	var entIndex = Players.GetLocalPlayerPortraitUnit ? Players.GetLocalPlayerPortraitUnit() : -1;
	var unitName = entIndex > 0 ? Entities.GetUnitName( entIndex ) : "";
	var playerID = entIndex > 0 && Entities.GetPlayerOwnerID ? Entities.GetPlayerOwnerID( entIndex ) : -1;
	var localTeam = localPlayerID >= 0 && Players.GetTeam ? Players.GetTeam( localPlayerID ) : -1;
	var selectedTeam = entIndex > 0 && Entities.GetTeamNumber ? Entities.GetTeamNumber( entIndex ) : -1;
	var isPlayerHero = IsXHSPlayerHeroEntity( entIndex );

	if ( localTeam >= 0 && selectedTeam >= 0 && selectedTeam !== localTeam )
	{
		isPlayerHero = false;
	}

	return {
		entIndex: entIndex,
		playerID: playerID,
		unitName: unitName || "",
		isPlayerHero: isPlayerHero
	};
}

function IsXHSBuyTomeHeroReady( hero )
{
	hero = hero || GetXHSBuyTomeSelectedHeroInfo();

	if ( !hero.isPlayerHero || hero.entIndex <= 0 || hero.unitName === "" || hero.unitName === "npc_dota_hero_wisp" )
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

function FindXHSBuyTomeInsertionTarget( centerBlock )
{
	if ( !centerBlock )
	{
		return null;
	}

	var abilities = centerBlock.FindChildTraverse( "abilities" );
	if ( abilities )
	{
		var abilitiesParent = abilities.GetParent ? abilities.GetParent() : null;

		if ( abilities.GetParent && abilities.GetParent() === centerBlock )
		{
			return {
				parent: centerBlock,
				anchor: abilities
			};
		}

		var abilityParent = abilitiesParent;
		if ( abilityParent )
		{
			return {
				parent: abilityParent,
				anchor: abilities
			};
		}
	}

	var ability0 = centerBlock.FindChildTraverse( "Ability0" );
	var ability0Parent = ability0 && ability0.GetParent ? ability0.GetParent() : null;
	if ( ability0Parent )
	{
		return {
			parent: ability0Parent,
			anchor: ability0
		};
	}

	var fallback = centerBlock.FindChildTraverse( "AbilitiesAndStatBranch" );
	return {
		parent: centerBlock,
		anchor: fallback
	};
}

function GetXHSGoldForPlayer( playerID )
{
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

function GetXHSLocalGold()
{
	return GetXHSGoldForPlayer( Players.GetLocalPlayer() );
}

function GetXHSBuyTomeLockState( playerID )
{
	if ( playerID < 0 || typeof CustomNetTables === "undefined" )
	{
		return { locked: false, reason: "" };
	}

	var state = CustomNetTables.GetTableValue( "xhs_tome_purchase", String( playerID ) );
	return {
		locked: !!state && Number( state.locked ) === 1,
		reason: state && state.reason ? String( state.reason ) : "",
		autoBuy: !!state && Number( state.auto_buy ) === 1
	};
}

function NormalizeXHSBuyTomeLocalizedText( text )
{
	var config = GameUI.CustomUIConfig ? GameUI.CustomUIConfig() : null;
	if ( config && typeof config.NormalizeXHSLocalizedText === "function" )
	{
		return config.NormalizeXHSLocalizedText( text );
	}

	var value = text === undefined || text === null ? "" : String( text );
	var hasUtf8MojibakeMarker = value.indexOf( "\u00C3" ) !== -1
		|| value.indexOf( "\u00C2" ) !== -1
		|| value.indexOf( "\u00E2" ) !== -1;
	if ( !hasUtf8MojibakeMarker )
	{
		return value;
	}

	try
	{
		var decoded = decodeURIComponent( escape( value ) );
		return decoded.indexOf( "\uFFFD" ) === -1 ? decoded : value;
	}
	catch ( error )
	{
		return value;
	}
}

function InjectBuyTomeButtonIntoCenterBlock()
{
	var button = GetXHSBuyTomeButton();
	var centerBlock = GetXHSActiveCenterBlock();
	var insertionTarget = FindXHSBuyTomeInsertionTarget( centerBlock );
	var targetParent = insertionTarget ? insertionTarget.parent : null;
	var anchor = insertionTarget ? insertionTarget.anchor : null;
	if ( !centerBlock || !targetParent || !anchor )
	{
		if ( button )
		{
			button.style.visibility = "collapse";
		}
		return false;
	}

	if ( !button || ( button.GetParent && button.GetParent() !== targetParent && !button.SetParent ) )
	{
		button = CreateXHSBuyTomeButton( targetParent );
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
	if ( rootButton && rootButton !== button && rootButton.GetParent && rootButton.GetParent() !== targetParent )
	{
		rootButton.style.visibility = "collapse";
	}

	if ( button.SetParent )
	{
		button.SetParent( targetParent );
	}

	if ( targetParent.MoveChildAfter )
	{
		targetParent.MoveChildAfter( button, anchor );
	}

	button.AddClass( "XHSInjectedIntoCenterBlock" );
	button.style.visibility = "visible";
	ApplyXHSBuyTomeButtonStyle( button );
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

	var selectedHero = GetXHSBuyTomeSelectedHeroInfo();
	if ( !IsXHSBuyTomeHeroReady( selectedHero ) )
	{
		button.style.visibility = "collapse";
		$.Schedule( 0.25, UpdateBuyTomeButton );
		return;
	}

	g_nXHSBuyTomeSelectedPlayerID = selectedHero.playerID;

	var gold = GetXHSGoldForPlayer( selectedHero.playerID );
	g_nXHSBuyTomeCount = Math.max( 0, Math.floor( gold / XHS_TOME_COST ) );
	var lockState = GetXHSBuyTomeLockState( selectedHero.playerID );
	g_bXHSBuyTomeLocked = lockState.locked;
	g_sXHSBuyTomeLockReason = lockState.reason;
	g_bXHSTomeAutoBuyEnabled = lockState.autoBuy;
	var config = GameUI.CustomUIConfig ? GameUI.CustomUIConfig() : null;
	if ( config )
	{
		// Keep the ASCII localization token in shared state. Localize only at
		// the final display boundary so Unicode text is never passed around as
		// an already-decoded intermediary value.
		config.XHSBuyTomeLockReason = g_sXHSBuyTomeLockReason;
	}

	countLabel.text = "x" + g_nXHSBuyTomeCount;
	button.SetHasClass( "NoTomes", g_nXHSBuyTomeCount < 1 );
	button.SetHasClass( "TomePurchaseLocked", g_bXHSBuyTomeLocked );
	button.SetHasClass( "TomeAutoBuyEnabled", g_bXHSTomeAutoBuyEnabled );
	button.SetHasClass( "XHSBuyTomeOtherPlayer", selectedHero.playerID !== playerID );
	EnsureXHSBuyTomeAutoBuyHint( button );
	EnsureXHSBuyTomeDisabledOverlay( button );
	ApplyXHSBuyTomeButtonStyle( button, {
		noTomes: g_nXHSBuyTomeCount < 1,
		locked: g_bXHSBuyTomeLocked,
		autoBuy: g_bXHSTomeAutoBuyEnabled,
		hovered: button.BHasClass( "XHSBuyTomeHovered" )
	} );

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
	if ( g_nXHSBuyTomeSelectedPlayerID !== Players.GetLocalPlayer() || g_bXHSBuyTomeLocked )
	{
		return;
	}

	GameEvents.SendCustomGameEventToServer( "xhs_buy_tomes", {} );
}

function OnBuyTomeAutoBuyToggle()
{
	if ( g_nXHSBuyTomeSelectedPlayerID !== Players.GetLocalPlayer() )
	{
		return;
	}

	GameEvents.SendCustomGameEventToServer( "xhs_toggle_auto_buy_tomes", {} );
}

function ShowBuyTomeTooltip()
{
	var button = GetXHSBuyTomeButton();
	if ( button )
	{
		button.AddClass( "XHSBuyTomeHovered" );
		ApplyXHSBuyTomeButtonStyle( button, {
			locked: g_bXHSBuyTomeLocked,
			autoBuy: g_bXHSTomeAutoBuyEnabled,
			hovered: true
		} );
		var controlHelp = g_bXHSTomeAutoBuyEnabled
			? "AUTO-BUY: ON\nRight-click to disable."
			: "AUTO-BUY: OFF\nRight-click to enable.";
		if ( g_bXHSBuyTomeLocked )
		{
			var reason = g_sXHSBuyTomeLockReason
				? $.Localize( g_sXHSBuyTomeLockReason )
				: $.Localize( "#xhs_tome_lock_temporarily_disabled" );
			reason = NormalizeXHSBuyTomeLocalizedText( reason );
			$.DispatchEvent( "DOTAShowTextTooltip", button, reason + "\n\n" + controlHelp );
		}
		else
		{
			$.DispatchEvent(
				"DOTAShowTextTooltip",
				button,
				"Tome of Stats (+50 all attributes)\nLeft-click to buy the maximum affordable.\n\n" + controlHelp
			);
		}
	}
}

function HideBuyTomeTooltip()
{
	var button = GetXHSBuyTomeButton();
	if ( button )
	{
		button.RemoveClass( "XHSBuyTomeHovered" );
		ApplyXHSBuyTomeButtonStyle( button, {
			locked: g_bXHSBuyTomeLocked,
			autoBuy: g_bXHSTomeAutoBuyEnabled,
			hovered: false
		} );
		$.DispatchEvent( "DOTAHideAbilityTooltip", button );
		$.DispatchEvent( "DOTAHideTextTooltip", button );
	}
}

// Ancient position: 0, -3500, 0

/*
SetPlayersCameraPosition({
	hPosition: "-6520.0 2048.0 128.0",
})
*/

var XHSCameraMoveSequence = 0;
var XHSHeroSelectionHealthFrameHidden = false;
var XHSHeroSelectionHealthPanels = [];

function GetXHSHeroSelectionHealthPanel()
{
	var hud = GetXHSDotaHudRoot();
	var hudElements = hud && hud.FindChildTraverse ? hud.FindChildTraverse( "HUDElements" ) : null;
	var lowerHud = hudElements ? hudElements.FindChildTraverse( "lower_hud" ) : null;
	var centerWithStats = lowerHud ? lowerHud.FindChildTraverse( "center_with_stats" ) : null;
	var centerBlock = centerWithStats ? centerWithStats.FindChildTraverse( "center_block" ) : null;
	return centerBlock ? centerBlock.FindChildTraverse( "HealthContainer" ) : null;
}

function HideXHSHeroSelectionHealthPanel( panel )
{
	if ( !panel || !panel.IsValid || !panel.IsValid() )
	{
		return;
	}

	if ( panel._xhsHeroSelectionHealthRecorded !== true )
	{
		panel._xhsHeroSelectionHealthRecorded = true;
		panel._xhsHeroSelectionHealthOpacity = panel.style.opacity;
		panel._xhsHeroSelectionHealthHitTest = panel.hittest;
		XHSHeroSelectionHealthPanels.push( panel );
	}

	panel.style.opacity = "0";
	panel.hittest = false;
}

function RestoreXHSHeroSelectionHealthPanels()
{
	for ( var i = 0; i < XHSHeroSelectionHealthPanels.length; i++ )
	{
		var panel = XHSHeroSelectionHealthPanels[i];
		if ( !panel || !panel.IsValid || !panel.IsValid() )
		{
			continue;
		}

		panel.style.opacity = panel._xhsHeroSelectionHealthOpacity || "1";
		panel.hittest = panel._xhsHeroSelectionHealthHitTest;
		panel._xhsHeroSelectionHealthRecorded = false;
	}
	XHSHeroSelectionHealthPanels = [];
}

function MaintainXHSHeroSelectionHealthFrame()
{
	if ( !XHSHeroSelectionHealthFrameHidden )
	{
		return;
	}

	HideXHSHeroSelectionHealthPanel( GetXHSHeroSelectionHealthPanel() );
	$.Schedule( 0.03, MaintainXHSHeroSelectionHealthFrame );
}

function SetXHSHeroSelectionTransition( data )
{
	var hidden = !!( data && Number( data.active ) === 1 );
	if ( XHSHeroSelectionHealthFrameHidden === hidden )
	{
		if ( hidden )
		{
			HideXHSHeroSelectionHealthPanel( GetXHSHeroSelectionHealthPanel() );
		}
		return;
	}

	XHSHeroSelectionHealthFrameHidden = hidden;
	if ( hidden )
	{
		HideXHSHeroSelectionHealthPanel( GetXHSHeroSelectionHealthPanel() );
		MaintainXHSHeroSelectionHealthFrame();
	}
	else
	{
		RestoreXHSHeroSelectionHealthPanels();
	}
}

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
			var targetPosition = [keys.hPosition[0], keys.hPosition[1], keys.hPosition[2]];
			var cinematicConfig = GameUI.CustomUIConfig ? GameUI.CustomUIConfig() : null;
			var cinematicApi = cinematicConfig && cinematicConfig.XHSCinematics;
			var cameraHandledByCinematic = cinematicApi
				&& cinematicApi.isActive
				&& cinematicApi.isActive()
				&& cinematicApi.setCameraTarget
				&& cinematicApi.setCameraTarget(targetPosition, keys.iSpeed);
			if (!cameraHandledByCinematic) {
				GameUI.SetCameraTargetPosition(targetPosition, keys.iSpeed);
			}
			var sequence = ++XHSCameraMoveSequence;
			var returnDelay = Number(keys.return_to_hero_after) || 0;
			if (returnDelay > 0) {
				$.Schedule(returnDelay, function () {
					if (sequence !== XHSCameraMoveSequence) {
						return;
					}

					var hero = Players.GetPlayerHeroEntityIndex(Players.GetLocalPlayer());
					if (hero === -1) {
						return;
					}

					var heroPosition = Entities.GetAbsOrigin(hero);
					if (heroPosition) {
						var returnHandledByCinematic = cinematicApi
							&& cinematicApi.isActive
							&& cinematicApi.isActive()
							&& cinematicApi.setCameraTarget
							&& cinematicApi.setCameraTarget(heroPosition, Number(keys.return_speed) || 0.65);
						if (!returnHandledByCinematic) {
							GameUI.SetCameraTargetPosition(heroPosition, Number(keys.return_speed) || 0.65);
						}
					}
				});
			}
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
	GameEvents.Subscribe("xhs_hero_selection_transition", SetXHSHeroSelectionTransition)
	var tomeButton = GetXHSBuyTomeButton();
	if ( tomeButton )
	{
		tomeButton.SetPanelEvent( "onmouseover", ShowBuyTomeTooltip );
		tomeButton.SetPanelEvent( "onmouseout", HideBuyTomeTooltip );
		tomeButton.SetPanelEvent( "oncontextmenu", OnBuyTomeAutoBuyToggle );
	}
	UpdateBuyTomeButton();
	UpdateXHSReincarnationPortrait();
	if ( typeof XHSNameDisplay !== "undefined" && XHSNameDisplay.Subscribe )
	{
		XHSNameDisplay.Subscribe( RefreshXHSDialogPlayers );
	}
})()
