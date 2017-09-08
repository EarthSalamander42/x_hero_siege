"use strict"


function InitUI()
{
	$.Msg("Init UI!")
	var map_info = Game.GetMapInfo();
	if (map_info.map_display_name == "ranked_2v2") {
		$.GetContextPanel().FindChildTraverse("VoteColumn").style.visibility = "collapse";
	} else if (map_info.map_display_name == "x_hero_siege") {
		var TeamContainer = $.GetContextPanel().GetParent().GetParent().FindChildTraverse("CustomUIContainer").FindChildTraverse("TeamSelectContainer")
		var GamePlayerPanel = TeamContainer.FindChildTraverse("GameAndPlayersRoot")
		var GameInfoPanel = TeamContainer.FindChildTraverse("GameInfoPanel")

		GamePlayerPanel.style.width = "20%";
		GamePlayerPanel.style.height = "20%";
		GamePlayerPanel.style.marginRight = "40%";
		GamePlayerPanel.style.backgroundColor = "#000000da";
		GamePlayerPanel.style.boxShadow = "black 0px 0px 0px 0px";

		GameInfoPanel.style.width = "100%";
		GameInfoPanel.FindChildTraverse("CustomGameModeName").style.align = "center center";
		GameInfoPanel.FindChildTraverse("MapInfo").style.align = "center center";
		GameInfoPanel.FindChildTraverse("StartGameCountdownTimer").style.width = "96px";
		GameInfoPanel.FindChildTraverse("StartGameCountdownTimer").style.height = "96px";
		GameInfoPanel.FindChildTraverse("StartGameCountdownTimer").style.marginTop = "16px";
		GameInfoPanel.FindChildTraverse("StartGameCountdownTimer").style.align = "center center";

		GameInfoPanel.FindChildTraverse("StartGameCountdownTimer").FindChildTraverse("TimerLabelBox").style.height = "40px";
		GameInfoPanel.FindChildTraverse("StartGameCountdownTimer").FindChildTraverse("TimerLabelBox").FindChildTraverse("TimerLabelAutoStart").style.height = "40px";

		TeamContainer.FindChildTraverse("TeamsList").style.visibility = "collapse";
		GamePlayerPanel.FindChildTraverse("UnassignedPlayerPanel").style.visibility = "collapse";
		GamePlayerPanel.FindChildTraverse("CancelAndUnlockButton").style.visibility = "collapse";
//		$.GetContextPanel().GetParent().GetParent().FindChildTraverse("HUDElements").FindChildTraverse("topbar").FindChildTraverse("TopBarDireTeam").style.visibility = "collapse";
	}
}

(function(){
	InitUI()
})();
