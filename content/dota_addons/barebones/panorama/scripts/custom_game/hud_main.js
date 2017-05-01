"use strict";

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

//Attempt of new pick type
//	function GetMouseCastTarget()
//	{
//		var mouseEntities = GameUI.FindScreenEntities( GameUI.GetCursorPosition() );
//		var localHeroIndex = Players.GetPlayerHeroEntityIndex( Players.GetLocalPlayer() );
//		mouseEntities = mouseEntities.filter( function(e) { return e.entityIndex !== localHeroIndex; } );
//		for ( var e of mouseEntities )
//		{
//			if ( !e.accurateCollision )
//				continue;
//			return e.entityIndex;
//		}
//	
//		for ( var e of mouseEntities )
//		{
//			return e.entityIndex;
//		}
//	
//		return -1;
//	}
//	
//	function OnLeftButtonPressed()
//	{
//		var castAbilityIndex = Entities.GetAbility( Players.GetPlayerHeroEntityIndex( Players.GetLocalPlayer() ), 0 );
//		var targetIndex = GetMouseCastTarget();
//		if ( targetIndex === -1 )
//		{
//			if ( GameUI.IsShiftDown() )
//			{
//	
//			}
//			else
//			{
//				$.Msg( "Left clicked nothing." );
//			}
//		}
//		else
//		{
//			BeginAttackState( 0, castAbilityIndex, targetIndex );
//		}
//	}
//	
//	function BeginAttackState( nMouseButton, abilityIndex, targetEntityIndex )
//	{
//		var order = {
//			AbilityIndex : abilityIndex,
//			QueueBehavior : OrderQueueBehavior_t.DOTA_ORDER_QUEUE_NEVER,
//			ShowEffects : false
//		};
//	
//		var abilityBehavior = Abilities.GetBehavior( abilityIndex );
//	
//		if ( order.OrderType === undefined )
//			$.Msg( "Clicked an unit." );
//		return;
//	}
//	
//	// Main mouse event callback
//	GameUI.SetMouseCallback( function( eventName, arg ) {
//		var nMouseButton = arg
//		var CONSUME_EVENT = true;
//		var CONTINUE_PROCESSING_EVENT = false;
//		if ( GameUI.GetClickBehaviors() !== CLICK_BEHAVIORS.DOTA_CLICK_BEHAVIOR_NONE )
//			return CONTINUE_PROCESSING_EVENT;
//	
//		if ( eventName === "pressed" )
//		{
//			// Left-click is move to position or attack
//			if ( arg === 0 )
//			{
//				OnLeftButtonPressed();
//				return CONSUME_EVENT;
//			}
//		}
//		return CONTINUE_PROCESSING_EVENT;
//	} );

(function()
{
	GameEvents.Subscribe("hide_ui", HideUI);
})();
