"use strict";

var view = {
	title: $("#imba-loading-title-text"),
	text: $("#imba-loading-content-text"),
	map: $("#imba-loading-map-text"),
	link: $("#imba-loading-link"),
	link_text:  $("#imba-loading-link-text")
};

var link_targets = "";

function ucwords (str) {
	return (str + '').replace(/^(.)|\s+(.)/g, function ($1) {
		return $1.toUpperCase();
	});
}

function info_already_available() {
	return Game.GetMapInfo().map_name != "";
}

function fetch() {
	view.title.text = "X Hero Siege 3.48d: Ghost Revenant";
	view.text.text = "X Hero Siege will get a 100% free battlepass soon. The goal is to reward regular players on the long term by unlocking cosmetics and more! (Those rewards are unlocked in X Hero Siege only.)";
	view.link_text.text = "COMING SOON: X Hero Siege website.";

	// if data is not available yet, reschedule
	if (!info_already_available()) {
		$.Schedule(0.1, fetch);
		return;
	}

	$.Msg("Fetching and setting loading screen data");
	
	var mapInfo = Game.GetMapInfo();
	var map_name = ucwords(mapInfo.map_display_name.replace('_', " "));
 
//	api.resolve_map_name(mapInfo.map_display_name).then(function (data) {
//		view.map.text = data;
//	}).catch(function (err) {
//		$.Msg("Failed to resolve map name: " + err.message);
//		view.map.text = map_name;
//	});

	view.map.text = map_name;
/*
	api.loading_screen().then(function (data) {
		var lang = $.Language();
		var rdata = data.languages["en"];

		if (data.languages[lang] !== undefined)
			rdata = data.languages["en"];

		view.title.text = rdata.title;
		view.text.text = rdata.text;
		view.link_text.text = rdata.link_text;

		view.link.SetPanelEvent("onactivate", function() {
			$.DispatchEvent("DOTADisplayURL", rdata.link_value || "");
		});	
	}).catch(function (reason) {
		$.Msg("Loading Loading screen information failed");
		$.Msg(reason);

		view.text.text = "News currently unavailable.";
	});
*/
	/*
	var player_info = Game.GetPlayerInfo(Game.GetLocalPlayerID());
	
	api.player_info(player_info.player_steamid).then(function (data) {
		// TODO: do sth with the data
	}).catch(function (reason) {
		$.Msg("Loading player info for loading screen failed!")
		$.Msg(reason);
	});
	*/
};

function HoverableLoadingScreen() {
	if (Game.GameStateIs(2))
		$.GetContextPanel().style.zIndex = "1";
	else
		$.Schedule(1.0, HoverableLoadingScreen)
}

function OnVoteButtonPressed(category, vote)
{
//	$.Msg("Category: ", category);
//	$.Msg("Vote: ", vote);
	GameEvents.SendCustomGameEventToServer( "setting_vote", { "category":category, "vote":vote } );
}

function OnVotesReceived(data)
{
//	$.Msg(data)
//	$.Msg(data.vote.toString())
//	$.Msg(data.table)
	$.Msg(data.table2)

	var vote_count = []
	vote_count[1] = 0;
	vote_count[2] = 0;
	vote_count[3] = 0;
	vote_count[4] = 0;
	vote_count[5] = 0;

	// Reset tooltips
	for (var i = 1; i <= 5; i++) {
		$("#VoteDifficultyText" + i).text = $.Localize("#vote_difficulty_" + i);
	}

	// Check number of votes for each difficulties
	for (var id in data.table2){
		var difficulty = data.table2[id]
		vote_count[difficulty]++;
	}

	// Modify tooltips based on voted difficulty
	for (var i = 1; i <= 5; i++) {
		$("#VoteDifficultyText" + i).text = $.Localize("#vote_difficulty_" + i) + " (" + vote_count[i] + ")";
	}

//	if (data.category == "creep_lanes") {

//	}
}

(function(){
	HoverableLoadingScreen()
	fetch();

	GameEvents.Subscribe("send_votes", OnVotesReceived);
})();
