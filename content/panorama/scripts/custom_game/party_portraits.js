var OnHeroIconClicked = function() {
	var entIndex = $( '#HeroIconContainer').GetAttributeInt( "ent_index", -1 );

	if ( entIndex !== -1 ) {
		ProcessClick( entIndex );
	}
} 

var OnVIPIconClicked = function() {
	var entIndex = $( '#VIPImage').GetAttributeInt( "ent_index", -1 );
	if ( entIndex !== -1 ) {
		ProcessClick( entIndex );
	}
}

var recentUnitSelections = {};
var queuedUnitSelectionSerial = 0;
var queuedUnitSelectionToken = 0;
var suppressedUnitSelections = {};

var SelectUnitWithoutVanillaDoubleCenter = function( entIndex ) {
	var key = String(entIndex);
	if (recentUnitSelections[key]) {
		return false;
	}

	recentUnitSelections[key] = true;
	$.Schedule(0.35, function() {
		delete recentUnitSelections[key];
	});
	GameUI.SelectUnit(entIndex, false);
	return true;
}

var ProcessClick = function( entIndex ) {
	if ( entIndex === -1 )
		return;

	var key = String(entIndex);
	if (suppressedUnitSelections[key])
		return;

	var token = ++queuedUnitSelectionSerial;
	queuedUnitSelectionToken = token;
	$.Schedule(0.35, function() {
		if (queuedUnitSelectionToken !== token || suppressedUnitSelections[key])
			return;
		queuedUnitSelectionToken = 0;
		ProcessClickNow(entIndex);
	});
}

var ProcessClickNow = function( entIndex ) {
	if ( entIndex === -1 )
		return;

	var clickbehaviors = GameUI.GetClickBehaviors();

	if ( clickbehaviors === CLICK_BEHAVIORS.DOTA_CLICK_BEHAVIOR_CAST ) {
		var abilityIndex = Abilities.GetLocalPlayerActiveAbility();
		var abilityBehavior = Abilities.GetBehavior( abilityIndex );

		if ( abilityBehavior & DOTA_ABILITY_BEHAVIOR.DOTA_ABILITY_BEHAVIOR_UNIT_TARGET ) {
			var order = {
			  AbilityIndex : abilityIndex,
			  QueueBehavior : OrderQueueBehavior_t.DOTA_ORDER_QUEUE_NEVER,
			  ShowEffects : false,
			  OrderType : dotaunitorder_t.DOTA_UNIT_ORDER_CAST_TARGET,
			  TargetIndex : entIndex,
			};

			Game.PrepareUnitOrders( order );  
			return;  
		}
	}
	
	SelectUnitWithoutVanillaDoubleCenter( entIndex );

	return;  
}

var MoveCameraToHero = function() {
	var entIndex = $( '#HeroIconContainer').GetAttributeInt( "ent_index", -1 );
	if (entIndex !== -1) {
		queuedUnitSelectionToken = ++queuedUnitSelectionSerial;
		var key = String(entIndex);
		var suppressionToken = queuedUnitSelectionSerial;
		suppressedUnitSelections[key] = suppressionToken;
		$.Schedule(0.40, function() {
			if (suppressedUnitSelections[key] === suppressionToken)
				delete suppressedUnitSelections[key];
		});
		GameEvents.SendCustomGameEventToServer("xhs_camera_focus_entity", {
			entindex: entIndex,
		});
	}
}
