"use strict";

function intToARGB(i) 
{ 
                return ('00' + ( i & 0xFF).toString( 16 ) ).substr( -2 ) +
                                               ('00' + ( ( i >> 8 ) & 0xFF ).toString( 16 ) ).substr( -2 ) +
                                               ('00' + ( ( i >> 16 ) & 0xFF ).toString( 16 ) ).substr( -2 ) + 
                                                ('00' + ( ( i >> 24 ) & 0xFF ).toString( 16 ) ).substr( -2 );
}

(function UpdatePartyHealthBars()
{
	var partyContainer = $( "#PartyPortraits" );
	var localPlayerInfo = Game.GetLocalPlayerInfo();
	var i = 0;
	for ( i; i < 8; i++ )
	{
		var playerID = i;
		var playerPanelName = "PartyPortrait" + playerID;
		var entIndex = Players.GetPlayerHeroEntityIndex( playerID );
		var playerInfo = Game.GetPlayerInfo( playerID );
		var playerPanel = partyContainer.FindChild( playerPanelName );

		if ( playerPanel === null )
		{
//			if ( localPlayerInfo && ( playerID === localPlayerInfo.player_id ) )
//				continue;

			if ( entIndex === -1 )
				continue;
			
			playerPanel = $.CreatePanel( "Panel", partyContainer, playerPanelName );
			playerPanel.SetAttributeInt( "player_id", playerID );
			playerPanel.BLoadLayout( "file://{resources}/layout/custom_game/party_portrait.xml", false, false );

			var colorInt = Players.GetPlayerColor( playerID );
			var colorString = "#" + intToARGB( colorInt );

			var playerNameLabel = playerPanel.FindChildInLayoutFile( "PlayerName" );
			playerNameLabel.text = Players.GetPlayerName( playerID );
			playerNameLabel.style.color = colorString;

			var heroImage = playerPanel.FindChildInLayoutFile( "HeroImage" );
			heroImage.heroname = Players.GetPlayerSelectedHero( playerID );
		}

		if ( playerPanel.BHasClass( "VIP" ) )
		{
			entIndex = playerPanel.GetAttributeInt( "ent_index", -1 );
		}

		var heroIconContainer = playerPanel.FindChildInLayoutFile( "HeroIconContainer" );
		heroIconContainer.SetAttributeInt( "ent_index", entIndex );

		var healthBar = playerPanel.FindChildInLayoutFile( "HealthBar" );
		healthBar.value = Entities.GetHealthPercent( entIndex );
		var manaBar = playerPanel.FindChildInLayoutFile( "ManaBar" );
		manaBar.value = 100.0 * (Entities.GetMana( entIndex ) / Entities.GetMaxMana( entIndex ) );
		var heroImage = playerPanel.FindChildInLayoutFile( "HeroImage" );
		if ( healthBar.value === 0 )
		{
			heroImage.style.washColor = "#990000";	
		}
		else
		{
			heroImage.style.washColor = "#FFFFFF";
		}

		if ( !playerPanel.BHasClass( "VIP" ) )
		{
			var nRespawnsRemaining = 0;

			var respawnData = CustomNetTables.GetTableValue( "player_table", entIndex.toString() + "_respawns" );

			if ( respawnData && respawnData["1"] )
			{
				var nRespawnsRemaining = respawnData["1"];
				var LifeRemainingContainer = playerPanel.FindChild( "PartyLifeRemainingContainer" );
				if ( LifeRemainingContainer !== null )
				{
					var heroImage = playerPanel.FindChildInLayoutFile( "HeroImage" );
					var LifePanel = LifeRemainingContainer.FindChild( "PartyLife0" );
					var LifeAmount = LifeRemainingContainer.FindChild("LifeAmount");
					var NeutralItem = LifeRemainingContainer.FindChild("NeutralImage");

					if ( LifePanel !== null )
					{
						heroImage.heroname = Entities.GetUnitName( entIndex );
						LifePanel.heroname = Entities.GetUnitName( entIndex );
						LifePanel.SetHasClass( "LifeUsed", nRespawnsRemaining == 0 )
						LifeAmount.text = "x" + nRespawnsRemaining;

						var item_image = Abilities.GetAbilityTextureName(Entities.GetItemInSlot(entIndex, 16)).replace("custom/", "");

						if (item_image != "") {
							NeutralItem.SetImage( "file://{images}/items/" + item_image + ".png" );
						}
					}
				}
			}
	
			var bDisconnected = playerInfo.player_connection_state === DOTAConnectionState_t.DOTA_CONNECTION_STATE_DISCONNECTED || playerInfo.player_connection_state === DOTAConnectionState_t.DOTA_CONNECTION_STATE_DISCONNECTED;
			playerPanel.SetHasClass( "Disconnected", bDisconnected )
		}
	}

	$.Schedule( 1.0/30.0, UpdatePartyHealthBars );
})();

function UpdateVIPs()
{
	var partyContainer = $( "#PartyPortraits" );
	var key = 0;
	var vipData = CustomNetTables.GetTableValue( "vips", key.toString() );
	if ( typeof( vipData ) != "undefined" )
	{
		var i = 0;
		for ( i; i < 1; i++ )
		{
			var entIndex = vipData[i+1];
			var slot = (4 + i);
			var playerPanelName = "PartyPortrait" + slot;
			var playerPanel = partyContainer.FindChild( playerPanelName );
			if ( playerPanel === null )
			{
				if ( entIndex === -1 )
					continue;

				playerPanel = $.CreatePanel( "Panel", partyContainer, playerPanelName );
				playerPanel.SetAttributeInt( "player_id", -1 );
				playerPanel.SetAttributeInt( "ent_index", entIndex );
				playerPanel.BLoadLayout( "file://{resources}/layout/custom_game/party_portrait.xml", false, false );
				playerPanel.SetHasClass( "VIP", true );

				var playerNameLabel = playerPanel.FindChildInLayoutFile( "PlayerName" );
				playerNameLabel.text = $.Localize( "#" + Entities.GetUnitName( entIndex ) );

				var VIPImage = playerPanel.FindChildInLayoutFile( "VIPImage" );
				VIPImage.SetAttributeInt( "ent_index", entIndex );
				VIPImage.SetImage( "file://{images}/interface/" + Entities.GetUnitName( entIndex ) + ".png" );
			}
		}
	}
}

function RemoveVIPs()
{
	var partyContainer = $( "#PartyPortraits" );
	var i = 0;
	for ( i; i < 1; i++ )
	{
		var slot = (4 + i);
		var playerPanelName = "PartyPortrait" + slot;
		var playerPanel = partyContainer.FindChild( playerPanelName );
		if ( playerPanel !== null )
		{
			playerPanel.DeleteAsync( 1.0 );
		}
	}
}

if (Game.GetMapInfo().map_display_name == "x_hero_siege_8")
$.GetContextPanel().AddClass("8_players")

CustomNetTables.SubscribeNetTableListener( "vips", UpdateVIPs )
GameEvents.Subscribe( "remove_vips", RemoveVIPs );
