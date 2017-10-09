"use strict"

var VotingOptionPanels = {};

function OnVoteButtonPressed(category, vote)
{
//	$.Msg("Category: ", category);
//	$.Msg("Vote: ", vote);
	GameEvents.SendCustomGameEventToServer( "setting_vote", { "category":category, "vote":vote } );
}

function InitUI()
{
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

function OnVotesReceived(data)
{
//	$.Msg(data.category)
//	$.Msg(data.vote)
	$.Msg(data.table) // Regroup all votes from a specific player ID.

	var Players = Game.GetPlayerIDsOnTeam( DOTATeam_t.DOTA_TEAM_GOODGUYS );

	$.Each( Players, function( player ) {
		$.Msg("Player: " + player)
		if (data.category == "difficulty") {
			$.Msg(data.vote)
			$("#VoteDifficulty" + data.vote).text = $.Localize("vote_difficulty_" + data.vote) + " (+1)"
			$.Msg($("#VoteDifficulty" + data.vote).text)
		}

		if (data.category == "creep_lanes") {

		}
	});
}

GameEvents.Subscribe( "send_votes", OnVotesReceived );

(function(){
	InitUI()
})();
