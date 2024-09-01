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

var ProcessClick = function( entIndex ) {
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
	
	GameUI.SelectUnit( entIndex, false );

	return;  
}

var MoveCameraToHero = function() {
	var entIndex = $( '#HeroIconContainer').GetAttributeInt( "ent_index", -1 );
	var position = Entities.GetAbsOrigin(entIndex);
	GameUI.SetCameraTargetPosition([position[0], position[1], position[2]], 0.4);
}
