"use strict";

var game_options;
var secret_key = {};

var api = {
	base: "https://api.frostrose-studio.com/",
	urls: {
		loadingScreenMessage: "imba/loading-screen-info",
	},
	getLoadingScreenMessage: function (success_callback, error_callback) {
		$.AsyncWebRequest(api.base + api.urls.loadingScreenMessage, {
			type: "GET",
			dataType: "json",
			timeout: 5000,
			headers: { 'X-Dota-Server-Key': secret_key },
			success: function (obj) {
				if (obj.error) {
					$.Msg("Error loading screen info");
					error_callback();
				} else {
					$.Msg("Get loading screen info successful");
					success_callback(obj);
				}
			},
			error: function (err) {
				$.Msg("Error loading screen info" + JSON.stringify(err));
				error_callback();
			}
		});
	},
}

var view = {
	title: $("#loading-title-text"),
	subtitle: $("#loading-subtitle-text"),
	text: $("#loading-description-text"),
	map: $("#loading-map-text"),
	link: $("#loading-link"),
	link_text: $("#loading-link-text")
};

var vote_tooltips = {};
var vote_array = {
	"IMBA": {
		"gamemode": 5,
	},
	"XHS": {
		// "gamemode": 2, // Enable this when classic and reborn versions of the game are ready
		"difficulty": 5,
	},
	"PW": {
		"gamemode": 4,
	},
	"FB": {
		"gamemode": 3,
	},
};

var link_targets = "";

function info_already_available() {
	return Game.GetMapInfo().map_name != "";
}

function isInt(n) {
	return n % 1 === 0;
}

function LoadingScreenDebug(args) {
	$.Msg(args);
	view.text.text = view.text.text + ". \n\n" + args.text;
}

function SwitchTab(count) {
	var container = $.GetContextPanel().FindChildrenWithClassTraverse("bottom-footer-container");

	if (container && container[0]) {
		for (var i = 0; i < container[0].GetChildCount(); i++) {
			var panel = container[0].GetChild(i);
			var new_panel = container[0].GetChild(count - 1);

			if (panel == new_panel)
				panel.style.visibility = "visible";
			else
				panel.style.visibility = "collapse";
		}
	}

	var label = $("#BottomLabel");

	if (label) {
		label.text = $.Localize("#loading_screen_custom_games_" + count);
	}
}

function SetProfile() {
	var check = false;
	var check = false;

	if ($("#HomeProfileContainer")) {
		if ($("#HomeProfileContainer").FindChildTraverse("UserNickname") && $("#HomeProfileContainer").FindChildTraverse("UserNickname").GetChild(0)) {
			var player_table = CustomNetTables.GetTableValue("battlepass_player", Players.GetLocalPlayer().toString());

			if (player_table && player_table.Lvl) {
				$("#HomeProfileContainer").FindChildTraverse("UserNickname").GetChild(0).text = "Battle Pass Level: " + player_table.Lvl;

				check = true;
			}
		}
	}

	if (check == false) {
		$.Schedule(0.1, SetProfile);
		return;
	}
}

function SetProfileName() {
	var check = false;

	if ($("#HomeProfileContainer")) {
		if ($("#HomeProfileContainer").FindChildTraverse("AvatarImage") && Game.GetLocalPlayerInfo(Players.GetLocalPlayer())) {
			if ($("#HomeProfileContainer").FindChildTraverse("UserName") && $("#HomeProfileContainer").FindChildTraverse("UserName").GetChild(0)) {
				if ($("#HomeProfileContainer").FindChildTraverse("UserNickname") && $("#HomeProfileContainer").FindChildTraverse("UserNickname").GetChild(0)) {
					$("#HomeProfileContainer").FindChildTraverse("AvatarImage").steamid = Game.GetLocalPlayerInfo(Players.GetLocalPlayer()).player_steamid;

					$("#HomeProfileContainer").FindChildTraverse("UserName").GetChild(0).text = Players.GetPlayerName(Game.GetLocalPlayerID());
					$("#HomeProfileContainer").FindChildTraverse("UserName").GetChild(0).style.textOverflow = "shrink";

					$("#HomeProfileContainer").FindChildTraverse("RankTierContainer").style.width = "60px";
					$("#HomeProfileContainer").FindChildTraverse("RankTierContainer").style.height = "60px";

					$("#HomeProfileContainer").FindChildTraverse("UserNickname").GetChild(0).text = "";

					check = true;
				}
			}
		}
	}

	if (check == false) {
		$.Schedule(0.1, SetProfileName);
		return;
	} else {
		SetProfile();
	}
}

function fetch() {
	// if data is not available yet, reschedule
	if (!info_already_available()) {
		$.Schedule(0.1, fetch);
		return;
	}

	game_options = CustomNetTables.GetTableValue("game_options", "game_version");
	// $.Msg(game_options.game_type)
	if (game_options == undefined) {
		$.Schedule(0.1, fetch);
		return;
	}

	secret_key = CustomNetTables.GetTableValue("game_options", "server_key");
	if (secret_key == undefined) {
		$.Schedule(0.1, fetch);
		return;
	} else {
		secret_key = secret_key["1"];
	}

	if (Game.GetMapInfo().map_display_name == "imba_1v1")
		DisableVoting();
	else if (Game.GetMapInfo().map_display_name == "imbathrow_3v3v3v3")
		DisableRankingVoting();

	var game_version = game_options.value;

	if (isInt(game_version))
		game_version = game_version.toString() + ".0";

	view.title.text = $.Localize("#addon_game_name") + " " + game_version;
	view.subtitle.text = $.Localize("#game_version_name").toUpperCase();

	$.Msg($.Localize("lang"));

	api.getLoadingScreenMessage(function (data) {
		var found_lang = false;
		var result = data.data;
		var english_row;

		for (var i in result) {
			var info = result[i];

			if (info.lang == $.Localize("#lang")) {
				view.text.text = info.content;
				//				view.link_text.text = info.link_text;
				found_lang = true;
				break;
			} else if (info.lang == "en") {
				english_row = info;
			}
		}

		if (found_lang == false) {
			view.text.text = english_row.content;
			//			view.link_text.text = english_row.link_text;
		}
	}, function () {
		// error callback
		$.Msg("Unable to retrieve loading screen info.");
	});
};

function HideVoteCategory(vote_type) {
	$.Msg(vote_type);
	const parent = $("#vote_" + vote_type);

	if (parent) {
		parent.visible = false;
	}

	for (var i in $("#VoteContent").Children()) {
		if ($("#VoteContent").Children()[i].visible == true) {
			return;
		}
	}

	ToggleVoteContainer(false);
}

function AllPlayersLoaded() {
	$("#MainVoteButton").style.opacity = "1";
	const vote_parent = $("#VoteContent");

	if (Game.IsInToolsMode())
		vote_parent.RemoveAndDeleteChildren();

	if (!game_options || !game_options.game_type) {
		$.Schedule(0.1, AllPlayersLoaded);
		return;
	}

	// $.Msg(vote_array["XHS"]);
	for (var j in vote_array[game_options.game_type]) {
		const vote_type = j;
		// $.Msg(vote_type)
		const vote_count = vote_array[game_options.game_type][j];
		const panel = $.CreatePanel("Panel", vote_parent, "vote_" + vote_type);
		panel.AddClass("vote-select-panel-container");
		// panel.AddClass("VotePanel");

		// mid-left ui
		var gamemode_label = $.CreatePanel("Label", $("#vote-label-container"), "");
		gamemode_label.AddClass("vote-label");
		// gamemode_label.style.height = (100 / vote_count) + "%";
		gamemode_label.text = $.Localize("#vote_" + vote_type);

		for (var i = 1; i <= vote_count; i++) {
			var vote_button = $.CreatePanel("Panel", panel, "VoteGameMode" + i);
			vote_button.BLoadLayoutSnippet('VoteChoice');
			vote_button.style.width = (88 / vote_count) + "%";

			// mid-left ui
			var gamemode_label = $.CreatePanel("Label", $("#vote-label-container"), "leftui_vote_" + vote_type + "_" + i);
			gamemode_label.AddClass("vote-label");
			gamemode_label.AddClass("label_" + vote_type + "_reset");
			// gamemode_label.style.height = (100 / vote_count) + "%";
			gamemode_label.text = $.Localize("#vote_" + vote_type + "_" + i);

			(function (panel, vote_type, i) {
				panel.SetPanelEvent("onmouseover", function () {
					$.DispatchEvent("UIShowTextTooltip", panel, $.Localize("#vote_" + vote_type + "_" + i + "_description"));
				})

				panel.SetPanelEvent("onmouseout", function () {
					$.DispatchEvent("UIHideTextTooltip", panel);
				})
			})(gamemode_label, vote_type, i);

			vote_button.GetChild(0).text = $.Localize("#vote_" + vote_type + "_" + i);
			vote_button.GetChild(1).text = $.Localize("#vote_" + vote_type + "_" + i + "_description");

			(function (button, vote_type, i) {
				button.SetPanelEvent("onactivate", function () {
					OnVoteButtonPressed(vote_type, i);
					HideVoteCategory(vote_type);
				})
			})(vote_button.GetChild(2), vote_type, i);
		}
	}

	ToggleVoteContainer(true);

	//	$("#VoteGameMode1").checked = true;
	//	OnVoteButtonPressed("gamemode", 1);
}

function AllPlayersBattlepassLoaded() {
	var player_table = CustomNetTables.GetTableValue("battlepass_player", Players.GetLocalPlayer().toString());

	if (player_table && player_table.mmr_title) {
		var short_title = player_table.mmr_title;
		var title_stars = player_table.mmr_title.substring(player_table.mmr_title.length - 1, player_table.mmr_title.length)

		// if last character is a number (horrible hack, look away please)
		if (parseInt(title_stars)) {
			short_title = player_table.mmr_title.substring(0, player_table.mmr_title.length - 2);
			title_stars = player_table.mmr_title[player_table.mmr_title.length - 1];
		} else {
			short_title = player_table.mmr_title;
			title_stars = "_empty";
		}

		var mmr_rank_to_medals = {
			Herald: 1,
			Guardian: 2,
			Crusader: 3,
			Archon: 4,
			Legend: 5,
			Ancient: 6,
			Divine: 7,
			Immortal: 8,
		}

		$.GetContextPanel().FindChildTraverse("RankTier").style.backgroundImage = 'url("s2r://panorama/images/rank_tier_icons/rank' + mmr_rank_to_medals[short_title] + '_psd.vtex")';
		$.GetContextPanel().FindChildTraverse("RankPips").style.backgroundImage = 'url("s2r://panorama/images/rank_tier_icons/pip' + title_stars + '_psd.vtex")';
		/*
				rank_panel.SetPanelEvent("onmouseover", function () {
					$.DispatchEvent("DOTAShowTextTooltip", rank_panel, player_table.mmr_title);
				})
				rank_panel.SetPanelEvent("onmouseout", function () {
					$.DispatchEvent("DOTAHideTextTooltip", rank_panel);
				})
		*/
	}
}

function ToggleVoteContainer(bBoolean) {
	var vote_container = $.GetContextPanel().FindChildrenWithClassTraverse("vote-container-main");

	if (vote_container && vote_container[0]) {
		vote_container[0].SetHasClass("Visible", bBoolean);
	}
}

function HoverableLoadingScreen() {
	if (Game.GameStateIs(2))
		$.GetContextPanel().style.zIndex = "1";
	else
		$.Schedule(1.0, HoverableLoadingScreen)
}

function OnVoteButtonPressed(category, vote) {
	// var gamemode_name = $.Localize("#vote_" + category);

	// $("#VoteGameModeCheck").text = "You have voted for " + gamemode_name + ".";
	GameEvents.SendCustomGameEventToServer("setting_vote", { "category": category, "vote": vote, "PlayerID": Game.GetLocalPlayerID() });
}

/* new system, double votes for donators */

function OnVotesReceived(data) {
	var vote_counter = [];
	$.Msg(data);

	// Reset tooltips
	for (var i in $("#vote-label-container").FindChildrenWithClassTraverse("label_" + data.category + "_reset")) {
		var panel = $("#vote-label-container").FindChildrenWithClassTraverse("label_" + data.category + "_reset")[i];
		const index = parseInt(i) + 1;
		// $.Msg("Resetting tooltip for " + data.category + " " + i);
		panel.text = $.Localize("#vote_" + data.category + "_" + index) + " (0 vote)";
	}

	// Check number of votes for each gamemodes
	for (var player_id in data.table) {
		var gamemode = data.table[player_id][1];
		var amount_of_votes = data.table[player_id][2];
		// $.Msg("Player " + player_id + " voted for " + gamemode + " (" + amount_of_votes + " votes)");

		if (!vote_counter[gamemode]) {
			vote_counter[gamemode] = 0;
		}

		vote_counter[gamemode] = vote_counter[gamemode] + amount_of_votes;
	}

	for (var i in vote_counter) {
		// $.Msg("Gamemode " + i + " has " + vote_counter[i] + " votes");

		var panel = $("#vote-label-container").FindChildrenWithClassTraverse("label_" + data.category + "_reset")[i - 1];
		const index = parseInt(i);
		var vote_tooltip = "vote"
		if (vote_counter[i] > 1)
			vote_tooltip = "votes";

		// $.Msg($.Localize("#vote_" + data.category + "_" + index) + " (" + vote_counter[i] + " " + vote_tooltip + ")");
		panel.text = $.Localize("#vote_" + data.category + "_" + index) + " (" + vote_counter[i] + " " + vote_tooltip + ")";
	}

	// Modify tooltips based on voted gamemode
	// for (var i = 1; i <= vote_count[game_options.game_type]; i++) {
	// 	var vote_tooltip = "vote"

	// 	if (vote_counter[i] > 1)
	// 		vote_tooltip = "votes";

	// 	var gamemode_text = $.Localize("#" + vote_tooltips[i]) + " (" + vote_counter[i] + " " + vote_tooltip + ")";

	// 	if ($("#VoteGameModeText" + i)) {
	// 		$("#VoteGameModeText" + i).style.color = "white";
	// 		$("#VoteGameModeText" + i).text = $.Localize("#" + vote_tooltips[i]) + " (" + vote_counter[i] + " " + vote_tooltip + ")";
	// 	}
	// }

	// calculate number of people who voted
	var highest_vote = 0;
	for (var i in vote_counter) {
		if (vote_counter[i] > highest_vote)
			highest_vote = i;
	}

	if ($("#VoteGameModeText" + highest_vote)) {
		$("#VoteGameModeText" + highest_vote).style.color = "green";
	}
}

function DisableVoting() {
	$("#imba-loading-title-vote").style.visibility = "collapse";
}

function DisableRankingVoting() {
	$("#imba-loading-title-vote").FindChildTraverse("vote-content").GetChild(0).style.visibility = "collapse";
}

(function () {
	// if (Game.IsInToolsMode()) {
	// 	AllPlayersLoaded();
	// }

	var vote_info = $.GetContextPanel().FindChildrenWithClassTraverse("vote-info");

	if (vote_info && vote_info[0]) {
		vote_info[0].SetPanelEvent("onmouseover", function () {
			$.DispatchEvent("UIShowTextTooltip", vote_info[0], $.Localize("#vote_gamemode_description"));
		})

		vote_info[0].SetPanelEvent("onmouseout", function () {
			$.DispatchEvent("UIHideTextTooltip", vote_info[0]);
		})
	}

	var bottom_button_container = $.GetContextPanel().FindChildrenWithClassTraverse("bottom-button-container");

	if (bottom_button_container && bottom_button_container[0] && bottom_button_container[0].GetChild(0))
		bottom_button_container[0].GetChild(0).checked = true;
	/*/
		var bottom_patreon_container = $.GetContextPanel().FindChildrenWithClassTraverse("bottom-patreon-sub");
	
		if (bottom_patreon_container && bottom_patreon_container[0]) {
			var companion_list = [
				"npc_donator_companion_chocobo",
				"npc_donator_companion_mega_greevil",
				"npc_donator_companion_butch",
				"npc_donator_companion_hollow_jack",
				"npc_donator_companion_tory",
				"npc_donator_companion_frog",
			];
	
			for (var i in companion_list) {
				var companion = $.CreatePanel("Panel", bottom_patreon_container[0], "");
				companion.AddClass("DonatorReward");
				companion.style.width = 100 / companion_list.length + "%";
	
				var companionpreview = $.CreatePanel("Button", companion, "");
				companionpreview.style.width = "100%";
				companionpreview.style.height = "100%";
	
				companionpreview.BLoadLayoutFromString('<root><Panel><DOTAScenePanel style="width:100%; height:100%;" particleonly="false" unit="' + companion_list[i] + '"/></Panel></root>', false, false);
				companionpreview.style.opacityMask = 'url("s2r://panorama/images/masks/hero_model_opacity_mask_png.vtex");'
			}
		}
	*/
	HoverableLoadingScreen();
	fetch();
	SetProfileName();

	GameEvents.Subscribe("loading_screen_debug", LoadingScreenDebug);
	GameEvents.Subscribe("send_votes", OnVotesReceived);
	GameEvents.Subscribe("all_players_loaded", AllPlayersLoaded);
	GameEvents.Subscribe("all_players_battlepass_loaded", AllPlayersBattlepassLoaded);
})();
