"use strict";

function UpdateTimer()
{
	var timerValue = Game.GetDOTATime( false, true );
	var timerText = "";

	if ( timerValue < 0 )
	{
		timerValue = -timerValue;
	}

	var sec = Math.floor( timerValue % 60 );
	var min = Math.floor( timerValue / 60 );

//	if ( min > 0 )
	{
		timerText += min;
		timerText += ":";

		if ( sec < 10 )
		{
			timerText += "0";
		}
	}

	timerText += sec;

	var timePanel = $( "#ScoreboardCurrentTime" );
	if ( timePanel )
	{
		timePanel.text = timerText;
	}

}

function UpdateTimerMuradin( data )
{
	//$.Msg( "UpdateTimer: ", data );
	//var timerValue = Game.GetDOTATime( false, false );

	//var sec = Math.floor( timerValue % 60 );
	//var min = Math.floor( timerValue / 60 );

	//var timerText = "";
	//timerText += min;
	//timerText += ":";

	//if ( sec < 10 )
	//{
	//	timerText += "0";
	//}
	//timerText += sec;

	var timerText = "";
	timerText += data.timer_minute_10;
	timerText += data.timer_minute_01;
	timerText += ":";
	timerText += data.timer_second_10;
	timerText += data.timer_second_01;

	$( "#Timer" ).text = timerText;

	UpdateTimer();
}

function ShowTimer( data )
{
	$( "#Timer" ).AddClass( "timer_visible" );
}

function AlertTimer( data )
{
	$( "#Timer" ).AddClass( "timer_alert" );
}

function HideTimer( data )
{
	$( "#Timer" ).AddClass( "timer_hidden" );
}

function UpdateKillsToWin()
{
	var victory_condition = CustomNetTables.GetTableValue( "game_state", "victory_condition" );
	if ( victory_condition )
	{
		$("#VictoryPoints").text = victory_condition.kills_to_win;
	}
}

function OnGameStateChanged( table, key, data )
{
	$.Msg( "Table '", table, "' changed: '", key, "' = ", data );
	UpdateKillsToWin();
	UpdateTimer();
}

(function()
{
	// We use a nettable to communicate victory conditions to make sure we get the value regardless of timing.
	UpdateKillsToWin();
	CustomNetTables.SubscribeNetTableListener( "game_state", OnGameStateChanged );

    GameEvents.Subscribe( "countdown", UpdateTimerMuradin );
    GameEvents.Subscribe( "show_timer", ShowTimer );
    GameEvents.Subscribe( "timer_alert", AlertTimer );
    GameEvents.Subscribe( "overtime_alert", HideTimer );
	//UpdateTimer();
})();

