"use strict";
var TutorialButtonPressed = false;

function OnToggleAdminModButton()
{
	if (TutorialButtonPressed) {
		TutorialButtonPressed = false;
		$.GetContextPanel().SetHasClass( "AdminModBorder", false );
		$.GetContextPanel().SetHasClass( "AdminModBorderInvisible", false );
		$.GetContextPanel().SetHasClass( "CGSRadio", false );
		$.GetContextPanel().SetHasClass( "PlayerCommandsBox", false );
		$.GetContextPanel().SetHasClass( "CloseButton", false );
		$.GetContextPanel().SetHasClass( "admin_tab", false );
		$( "#CloseButton" ).visible	 = false
		$( "#AdminCommandsBox" ).visible = false
		$( "#PlayerCommandsBox" ).visible = false
		$( "#HostCommandsBox" ).visible	 = false
		$( "#PlayerButton" ).visible = false
		$( "#AdminButton" ).visible = false
		$( "#AdminTabs" ).visible = false
		$( "#CreditsBorder" ).visible = false
		Game.EmitSound( "ui_team_select_lock_and_start" );
	} else {
		TutorialButtonPressed = true;
		$.GetContextPanel().SetHasClass( "AdminModBorder", true );
		$.GetContextPanel().SetHasClass( "AdminModBorderInvisible", true );
		$.GetContextPanel().SetHasClass( "admin_tab", true );
		$( "#PlayerCommandsBox" ).visible = true
		$( "#HostCommandsBox" ).visible = true
		$( "#PlayerButton" ).visible = true
		$( "#AdminButton" ).visible = true
		$( "#AdminTabs" ).visible = true
		$( "#CloseButton" ).visible = true
		$( "#CreditsBorder" ).visible = true
		Game.EmitSound( "Chat.LeaverMessage" );
	};
}

function OnFreezeCommand()
{
	var hero = Players.GetLocalPlayer()
}

function DisableAdminMod()
{
	var timerValue = Game.GetDOTATime( false, true );
	var timerText = "";

	if ( timerValue < 0 )
	{
		TutorialButtonPressed = false;
		$.GetContextPanel().SetHasClass( "AdminModBorder", false );
		$.GetContextPanel().SetHasClass( "AdminModBorderInvisible", false );
		$.GetContextPanel().SetHasClass( "CGSRadio", false );
		$.GetContextPanel().SetHasClass( "admin_tab", false );
		$( "#CloseButton" ).visible = false
		$( "#AdminCommandsBox" ).visible = false
		$( "#PlayerCommandsBox" ).visible = false
		$( "#HostCommandsBox" ).visible = false
		$( "#AdminTabs" ).visible = false
		$( "#CreditsBorder" ).visible = false
	}
}

function OnBuyTomeCommand()
{

}

function ToggleAdminTab(){
	$( "#AdminCommandsBox" ).visible = true
	$( "#PlayerCommandsBox" ).visible = false
	$( "#HostCommandsBox" ).visible = false
}

function ToggleNormalTab(){
	$( "#AdminCommandsBox" ).visible = false
	$( "#PlayerCommandsBox" ).visible = true
	$( "#HostCommandsBox" ).visible = true
}

(function()
{
	GameEvents.Subscribe( "disable_adminmod", DisableAdminMod );
	GameEvents.Subscribe( "buy_tome", OnBuyTomeCommand );
})();
