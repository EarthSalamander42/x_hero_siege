"use strict";

function intToARGB(i) 
{ 
	return ('00' + ( i & 0xFF).toString( 16 ) ).substr( -2 ) +
	('00' + ( ( i >> 8 ) & 0xFF ).toString( 16 ) ).substr( -2 ) +
	('00' + ( ( i >> 16 ) & 0xFF ).toString( 16 ) ).substr( -2 ) + 
	('00' + ( ( i >> 24 ) & 0xFF ).toString( 16 ) ).substr( -2 );
}

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
				$.Msg( "Creating player portrait for VIP" );
				playerPanel = $.CreatePanel( "Panel", partyContainer, playerPanelName );
				playerPanel.SetAttributeInt( "player_id", -1 );
				playerPanel.SetAttributeInt( "ent_index", entIndex );
				playerPanel.BLoadLayout( "file://{resources}/layout/custom_game/party_portrait.xml", false, false );
				playerPanel.SetHasClass( "VIP", true );

				var playerNameLabel = playerPanel.FindChildInLayoutFile( "PlayerName" );
				playerNameLabel.text = $.Localize( Entities.GetUnitName( entIndex ) );

				var VIPImage = playerPanel.FindChildInLayoutFile( "VIPImage" );
				VIPImage.SetAttributeInt( "ent_index", entIndex );
				VIPImage.SetImage( "file://{images}/interface/" + Entities.GetUnitName( entIndex ) + ".png" );
			}
		}
	}
}

function RemoveVIPs()
{
	$.Msg( "RemoveVIPs" );
	var partyContainer = $( "#PartyPortraits" );
	var i = 0;
	for ( i; i < 1; i++ )
	{
		var slot = (4 + i);
		var playerPanelName = "PartyPortrait" + slot;
		var playerPanel = partyContainer.FindChild( playerPanelName );
		if ( playerPanel !== null )
		{
			$.Msg( "DeleteVIP" );
			playerPanel.DeleteAsync( 1.0 );
		}
	}
}

CustomNetTables.SubscribeNetTableListener( "vips", UpdateVIPs )
GameEvents.Subscribe( "remove_vips", RemoveVIPs );