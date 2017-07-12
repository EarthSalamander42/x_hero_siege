"use strict";

function ShowScreen()
{
		//this function will only get called when
	$.Msg("Game end has been triggered:" + Game.GetGameWinner());
	if(Game.GetGameWinner() === 3)
	{
		$.GetContextPanel().SetHasClass("GameOverLoss", true)
	}
	else
	{
		$.GetContextPanel().SetHasClass("GameOverWin", true)
	}
}

(function()
{	
	$.Schedule( 1.00, ShowScreen );
})();

