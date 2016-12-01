//"use strict";

// Notifications for Overthrow
//function AlertTimer( data )
//{
//	$.Msg( "AlertTimer: ", data );
//	var remainingText = "";
	
//	if ( ( data.timer_minute_01 == 2 ) && ( data.timer_second_10 == 0 ) && ( data.timer_second_01 == 0 ) )
//	{
//		remainingText = "2 MINUTES REMAINING";
//		$.GetContextPanel().SetHasClass( "time_notification", true );
//		$( "#AlertTimer_Text" ).text = remainingText;
//		Game.EmitSound("Tutorial.TaskProgress");
//	}
//	if ( ( data.timer_minute_01 == 1 ) && ( data.timer_second_10 == 0 ) && ( data.timer_second_01 == 0 ) )
//	{
//		remainingText = "60 SECONDS REMAINING";
//		$.GetContextPanel().SetHasClass( "time_notification", true );
//		$( "#AlertTimer_Text" ).text = remainingText;
//		Game.EmitSound("Tutorial.TaskProgress");
//	}
//	if ( ( data.timer_second_10 == 5 ) && ( data.timer_second_01 == 5 ) )
//	{
//		$.GetContextPanel().SetHasClass( "time_notification", false );
//	}
//	if ( ( data.timer_minute_01 == 0 ) && ( data.timer_second_10 == 3 ) && ( data.timer_second_01 == 0 ) )
//	{
//		remainingText = "30 SECONDS";
//		$.GetContextPanel().SetHasClass( "time_notification", true );
//		$( "#AlertTimer_Text" ).text = remainingText;
//		Game.EmitSound("Tutorial.TaskProgress");
//	}
//	if ( ( data.timer_minute_01 == 0 ) && ( data.timer_second_10 == 2 ) && ( data.timer_second_01 == 5 ) )
//	{
//		$.GetContextPanel().SetHasClass( "time_notification", false );
//	}
//	if ( ( data.timer_minute_01 == 0 ) && ( data.timer_second_10 == 1 ) && ( data.timer_second_01 == 0 ) )
//	{
//		remainingText = "10";
//		$.GetContextPanel().SetHasClass( "time_notification", true );
//		$.GetContextPanel().SetHasClass( "time_countdown", true );
//		$( "#AlertTimer_Text" ).text = remainingText;
//		Game.EmitSound("Tutorial.TaskProgress");
//	}
//	if ( ( data.timer_minute_01 == 0 ) && ( data.timer_second_10 == 0 ) && ( data.timer_second_01 <= 9 ) )
//	{
//		remainingText += data.timer_second_01;
//		$( "#AlertTimer_Text" ).text = remainingText;
//		Game.EmitSound("Tutorial.TaskProgress");
//	}
//	if ( ( data.timer_minute_01 == 0 ) && ( data.timer_second_10 == 0 ) && ( data.timer_second_01 <= 0 ) )
//	{
//		$( "#AlertTimer_Text" ).text = $.Localize( "#Overtime" );
//		Game.EmitSound("General.PingAttack");
//	}
//}

//(function () {
//    GameEvents.Subscribe( "time_remaining", AlertTimer );
//})();

