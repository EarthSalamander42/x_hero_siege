"use strict";

CustomNetTables.SubscribeNetTableListener( "relics", UpdateRelicInventory )

function UpdateRelicInventory()
{
	var RelicsContainer = $("#RelicsContainer" );
	var RelicsViolater = $("#RelicCountViolator" );
	var RelicsCourier = $( "#RelicCourier" );
	
	var RelicData = CustomNetTables.GetTableValue( "relics", Players.GetLocalPlayer().toString() );
	
	if ( typeof( RelicData != "undefined" ) )
	{
		for ( var i in RelicData )	
		{	
			var RelicName = RelicData[i];
			if ( RelicName === null )
				continue;

			if ( RelicsContainer.FindChild( RelicName ) )
				continue;

		//	$.Msg( "Creating new relic panel: " + RelicName );
			var newRelic = $.CreatePanel( "Panel", RelicsContainer, RelicName );
			newRelic.BLoadLayout( "file://{resources}/layout/custom_game/relic_item.xml", false, false );
			newRelic.FindChildInLayoutFile( "ItemImage" ).itemname = RelicName;
			newRelic.SetHasClass( "RelicIcon", true );
			newRelic.SetDraggable( true );
		}
		var nRelicCount = RelicsContainer.GetChildCount();
		RelicsViolater.text = nRelicCount;
		
		$.Msg( "count: " + nRelicCount );
		if ( nRelicCount < 1 )
		{
			RelicsCourier.SetHasClass( "NoItems" , true );
			RelicsCourier.RemoveClass( "Expanded" ); 
		}			
	}
	
	
}

function OnRelicButtonClicked()
{
	var RelicsContainer = $( "#RelicsContainer" );
	var RelicsCourier = $( "#RelicCourier" );
	var nRelicCount = RelicsContainer.GetChildCount();

	UpdateRelicInventory();
	
	if ( nRelicCount > 0 )
	{
		RelicsCourier.ToggleClass( "Expanded" );
	}
}

