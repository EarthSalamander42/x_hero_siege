"use strict";

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
}

function UpdateTimerCreep( data )
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
	timerText += data.timer_minute_10_2;
	timerText += data.timer_minute_01_2;
	timerText += ":";
	timerText += data.timer_second_10_2;
	timerText += data.timer_second_01_2;

	$( "#CreepTimer" ).text = timerText;
}

function UpdateTimerIncomingWave( data )
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

	var timerText3 = "";
	timerText3 += data.timer_minute_10_3;
	timerText3 += data.timer_minute_01_3;
	timerText3 += ":";
	timerText3 += data.timer_second_10_3;
	timerText3 += data.timer_second_01_3;

	$( "#IncomingWaveTimer" ).text = timerText3;
}

function UpdateTimerSpecialEvents( data )
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

	var timerText3 = "";
	timerText3 += data.timer_minute_10_3;
	timerText3 += data.timer_minute_01_3;
	timerText3 += ":";
	timerText3 += data.timer_second_10_3;
	timerText3 += data.timer_second_01_3;

	$( "#SpecialEventsTimer" ).text = timerText3;
}

function ShowTimer( data )
{
	$( "#Timer" ).AddClass( "timer_visible" );
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
}

(function()
{
	// We use a nettable to communicate victory conditions to make sure we get the value regardless of timing.
	UpdateKillsToWin();
	CustomNetTables.SubscribeNetTableListener( "game_state", OnGameStateChanged );

	GameEvents.Subscribe( "incomingwavecountdown", UpdateTimerSpecialEvents );
	GameEvents.Subscribe( "specialeventscountdown", UpdateTimerIncomingWave );
	GameEvents.Subscribe( "creepcountdown", UpdateTimerCreep );
	GameEvents.Subscribe( "countdown", UpdateTimerMuradin );
	GameEvents.Subscribe( "show_timer", ShowTimer );
})();

