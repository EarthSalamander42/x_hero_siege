var playerPanels = {};
var top_xp = [];
var current_leaderboard_round = 0;

// Panel init
var MiniTabButtonContainer = $("#MiniTabButtonContainer");
var MiniTabButtonContainer2 = $("#MiniTabButtonContainer2");
var MiniTabButtonContainer3 = $("#MiniTabButtonContainer3");
var LeaderboardInfoContainer = $("#LeaderboardInfoContainer");

var toggle = false;
var first_time = false;

var secret_key = CustomNetTables.GetTableValue("game_options", "server_key")["1"];
var game_version = CustomNetTables.GetTableValue("game_options", "game_version");
var game_type = undefined;
if (game_version)
	game_type = game_version.game_type;

/*
var api = {
	base : "https://api.frostrose-studio.com/",
	urls : {
		modifyCompanion : "imba/modify-companion",
//		modifyStatue : "imba/modify-statue",
		modifyEmblem : "imba/modify-emblem",
		modifyArmory : "imba/modify-armory",
		toggleIngameTag : "imba/toggle-ingame-tag",
		toggleBPRewards : "imba/toggle-bp-rewards",
		togglePlayerXP : "imba/toggle-player-xp",
		toggleWinrate : "imba/toggle-winrate",
		PlayerPosition : "imba/trackme",
		modifyTag : "imba/modify-tag",
	},
	updateCompanion : function(data, success_callback, error_callback) {
		$.AsyncWebRequest(api.base + api.urls.modifyCompanion, {
			type : "POST",
			dataType : "json",
			data : data,
			timeout : 5000,
			headers : {'X-Dota-Server-Key' : secret_key},
			success : function(obj) {
				if (obj.error) {
//					$.Msg("Error updating companion");
					error_callback();
				} else {
//					$.Msg("Updated companion");
					success_callback();
				}
			},
			error : function(err) {
//				$.Msg("Error updating companion" + JSON.stringify(err));
				error_callback();
			}
		});
	},
	// updateStatue : function(data, success_callback, error_callback) {
		// $.AsyncWebRequest(api.base + api.urls.modifyStatue, {
			// type : "POST",
			// dataType : "json",
			// data : data,
			// timeout : 5000,
			// headers : {'X-Dota-Server-Key' : secret_key},
			// success : function(obj) {
				// if (obj.error) {
					// $.Msg("Error updating statue");
					// error_callback();
				// } else {
					// $.Msg("Updated statue");
					// success_callback();
				// }
			// },
			// error : function(err) {
				// $.Msg("Error updating statue " + JSON.stringify(err));
				// error_callback();
			// }
		// });
	// },
	updateEmblem : function(data, success_callback, error_callback) {
		$.AsyncWebRequest(api.base + api.urls.modifyEmblem, {
			type : "POST",
			dataType : "json",
			data : data,
			timeout : 5000,
			headers : {'X-Dota-Server-Key' : secret_key},
			success : function(obj) {
				if (obj.error) {
					$.Msg("Error updating emblem");
					error_callback();
				} else {
//					$.Msg("Updated emblem");
					success_callback();
				}
			},
			error : function(err) {
				$.Msg("Error updating emblem " + JSON.stringify(err));
				error_callback();
			}
		});
	},
	updateIngameTag : function(data, success_callback, error_callback) {
		$.AsyncWebRequest(api.base + api.urls.toggleIngameTag, {
			type : "POST",
			dataType : "json",
			data : data,
			timeout : 5000,
			headers : {'X-Dota-Server-Key' : secret_key},
			success : function(obj) {
//				$.Msg(obj)
				if (obj.error) {
					$.Msg("Error updating ingame tag");
					error_callback();
				} else {
					$.Msg("Updated ingame tag");
					success_callback();
				}
			},
			error : function(err) {
				$.Msg("Error ingame tag " + JSON.stringify(err));
				error_callback();
			}
		});
	},
	updateBPRewards : function(data, success_callback, error_callback) {
		$.AsyncWebRequest(api.base + api.urls.toggleBPRewards, {
			type : "POST",
			dataType : "json",
			data : data,
			timeout : 5000,
			headers : {'X-Dota-Server-Key' : secret_key},
			success : function(obj) {
//				$.Msg(obj)
				if (obj.error) {
					$.Msg("Error updating bp rewards");
					error_callback();
				} else {
//					$.Msg("Updated bp rewards");
					success_callback();
				}
			},
			error : function(err) {
				$.Msg("Error bp rewards " + JSON.stringify(err));
				error_callback();
			}
		});
	},
	updatePlayerXP : function(data, success_callback, error_callback) {
		$.AsyncWebRequest(api.base + api.urls.togglePlayerXP, {
			type : "POST",
			dataType : "json",
			data : data,
			timeout : 5000,
			headers : {'X-Dota-Server-Key' : secret_key},
			success : function(obj) {
//				$.Msg(obj)
				if (obj.error) {
					$.Msg("Error updating ply xp");
					error_callback();
				} else {
//					$.Msg("Updated ply xp");
					success_callback();
				}
			},
			error : function(err) {
				$.Msg("Error ply xp " + JSON.stringify(err));
				error_callback();
			}
		});
	},
	updateWinrate : function(data, success_callback, error_callback) {
		$.AsyncWebRequest(api.base + api.urls.toggleWinrate, {
			type : "POST",
			dataType : "json",
			data : data,
			timeout : 5000,
			headers : {'X-Dota-Server-Key' : secret_key},
			success : function(obj) {
//				$.Msg(obj)
				if (obj.error) {
					$.Msg("Error updating winrate");
					error_callback();
				} else {
//					$.Msg("Updated winrate");
					success_callback();
				}
			},
			error : function(err) {
				$.Msg("Error winrate " + JSON.stringify(err));
				error_callback();
			}
		});
	},
	getPlayerPosition : function(data, callback) {
		$.AsyncWebRequest(api.base + api.urls.PlayerPosition, {
			type : "GET",
			data : data,
			dataType : "json",
			timeout : 5000,
			headers : {'X-Dota-Server-Key' : secret_key},
			success : function(obj) {
				if (obj.error)
					$.Msg("Error finding player position");
				else {
					callback(obj.data);
				}
			},
			error : function(err) {
				$.Msg("Error finding player position " + JSON.stringify(err));
			}
		});
	},
	updateArmory : function(data, success_callback, error_callback) {
		$.AsyncWebRequest(api.base + api.urls.modifyArmory, {
			type : "POST",
			dataType : "json",
			data : data,
			timeout : 5000,
			headers : {'X-Dota-Server-Key' : secret_key},
			success : function(obj) {
				if (obj.error) {
//					$.Msg("Error updating armory");
					error_callback();
				} else {
//					$.Msg("Updated armory");
					success_callback();
				}
			},
			error : function(err) {
				$.Msg("Error updating armory " + JSON.stringify(err));
				error_callback();
			}
		});
	},
	updateTag : function(data, success_callback, error_callback) {
		$.AsyncWebRequest(api.base + api.urls.modifyTag, {
			type : "POST",
			dataType : "json",
			data : data,
			timeout : 5000,
			headers : {'X-Dota-Server-Key' : secret_key},
			success : function(obj) {
				if (obj.error) {
					$.Msg("Error updating tag");
					error_callback();
				} else {
					$.Msg("Updated tag");
					success_callback();
				}
			},
			error : function(err) {
				$.Msg("Error updating tag " + JSON.stringify(err));
				error_callback();
			}
		});
	},
};
*/

function ToggleBattlepass() {
	if (toggle === false) {
		toggle = true;
		if (first_time === false) {
			first_time = true;
			Battlepass();

			if ($("#BattlepassTabButton"))
				$("#BattlepassTabButton").AddClass('active');
		}


		if ($("#BattlepassWindow").BHasClass("sethidden")) {
			$("#BattlepassWindow").RemoveClass("sethidden");
		}
		$("#BattlepassWindow").AddClass("setvisible");
	} else {
		toggle = false;
		if ($("#BattlepassWindow").BHasClass("setvisible")) {
			$("#BattlepassWindow").RemoveClass("setvisible");
		}
		$("#BattlepassWindow").AddClass("sethidden");
	}
}

var toggle = false;

function ToggleGameOptions() {
	var bool = "";

	if (toggle === false) {
		toggle = true;
		$("#ImbaGameInfo").style.visibility = "visible";
	} else {
		toggle = false;
		$("#ImbaGameInfo").style.visibility = "collapse";
	}
}

var current_sub_tab = "";

function RefreshBattlepass(bRewardsDisabled) {
	var childrens = $("#BattlepassInfoContainer").FindChildrenWithClassTraverse("BattlepassRow");
	childrens.forEach(function (e) {
		e.DeleteAsync(0);
	});

	var companion_childrens = $("#CompanionTableWrapper").FindChildrenWithClassTraverse("DonatorRow");
	companion_childrens.forEach(function (e) {
		e.DeleteAsync(0);
	});
	/*
		var statue_childrens = $("#StatueTableWrapper").FindChildrenWithClassTraverse("DonatorRow");
		statue_childrens.forEach(function(e) {
			e.DeleteAsync(0);
		});
	*/
	var emblem_childrens = $("#EmblemTableWrapper").FindChildrenWithClassTraverse("DonatorRow");
	emblem_childrens.forEach(function (e) {
		e.DeleteAsync(0);
	});

	if (current_sub_tab != "") {
		Battlepass(true, bRewardsDisabled);
	} else {
		Battlepass(false, bRewardsDisabled);
	}
}

function SwitchTab(tab) {
	$("#BattlepassInfoContainer").style.visibility = "collapse";
	$("#DonatorInfoContainer").style.visibility = "collapse";
	$("#LeaderboardInfoContainer").style.visibility = "collapse";
	$("#SettingsInfoContainer").style.visibility = "collapse";

	$("#" + tab).style.visibility = "visible";

	MiniTabButtonContainer.style.visibility = "collapse";
	MiniTabButtonContainer2.style.visibility = "collapse";

	if (tab == 'BattlepassInfoContainer') {
		MiniTabButtonContainer.style.visibility = "visible";
		$("#OverviewTabButton").AddClass('active');
	} else if (tab == 'DonatorInfoContainer') {
		MiniTabButtonContainer2.style.visibility = "visible";
	}
}

function SwitchDonatorWrapper(type) {
	if (current_sub_tab == type) {
		//		$.Msg("Bro don't reload you're fine!");
		return;
	}

	current_sub_tab = type;

	var DonatorInfoContainer = $("#DonatorInfoContainer");

	for (var i = 1; i < DonatorInfoContainer.GetChildCount(); i++) {
		var child = DonatorInfoContainer.GetChild(i);
		child.style.visibility = "collapse";
	}

	var Buttons = $("#MiniTabButtonContainer2");

	for (var i = 0; i < Buttons.GetChildCount(); i++) {
		var child = Buttons.GetChild(i);
		child.RemoveClass('active');
	}

	$("#" + type + "TableWrapper").style.visibility = "visible";
	$("#" + type + "TabButton").AddClass('active');

	$('#DonatorTabTitle').text = $.Localize("#donator_" + type.toLowerCase() + "_wrapper_label").toUpperCase();
}

function BubbleSortByElement(t, element_name) {
	if (!t)
		return;

	var i = 1;

	while (t[i] != undefined) {
		for (var k in t) {
			var l = (parseInt(k) + 1).toString();

			if (t[l] && t[k][element_name] && t[l][element_name] && t[k][element_name] > t[l][element_name]) {
				var element_1 = t[k];
				var element_2 = t[l];

				t[k] = element_2;
				t[l] = element_1;
				i = 0;
			} else {
				i++;
			}
		}
	}

	return t;
}

function Battlepass(retainSubTab, bRewardsDisabled) {
	if (typeof retainSubTab == "undefined") { retainSubTab = false; };

	HallOfFame("Experience", null, 1); // init leaderboard on round 1 records
	MiniTabButtonContainer.style.visibility = "visible";

	var BP_REWARDS = CustomNetTables.GetTableValue("battlepass_js_builder", "rewards");
	if (BP_REWARDS && BP_REWARDS["1"])
		BP_REWARDS = BP_REWARDS["1"];

	var BP_REWARDS_2 = CustomNetTables.GetTableValue("battlepass_js_builder_2", "rewards");
	if (BP_REWARDS_2 && BP_REWARDS_2["1"])
		BP_REWARDS_2 = BP_REWARDS_2["1"];

	var limiter = 1;

	while (BP_REWARDS[limiter]) {
		limiter++;
	}

	for (var i in BP_REWARDS_2) {
		BP_REWARDS[(parseInt(i) + (limiter - 1)).toString()] = BP_REWARDS_2[i];
	}

	var BP_REWARDS_3 = BubbleSortByElement(BP_REWARDS, "level");

	GenerateBattlepassPanel(BP_REWARDS_3, Players.GetLocalPlayer(), bRewardsDisabled);

	var companions = CustomNetTables.GetTableValue("battlepass_player", "companions");
	if (companions != undefined)
		GenerateCompanionPanel(companions["1"], Players.GetLocalPlayer(), "Companion", retainSubTab);
	/*
		var statues = CustomNetTables.GetTableValue("battlepass_player", "statues");
		if (statues != undefined)
			GenerateCompanionPanel(statues["1"], Players.GetLocalPlayer(), "Statue", true);
	*/
	var emblems = CustomNetTables.GetTableValue("battlepass_player", "emblems");
	if (emblems != undefined)
		GenerateCompanionPanel(emblems["1"], Players.GetLocalPlayer(), "Emblem", true);

	SetupPanel();
}

var companion_changed = false;

function SetCompanion(companion, name, id, required_status) {
	if (companion_changed === true) {
		//		$.Msg("SLOW DOWN BUDDY!");
		return;
	}

	if ($("#CompanionNotification").BHasClass("not_donator")) {
		$("#CompanionNotification").RemoveClass("not_donator");
	}

	var donator_status = IsDonator(Game.GetLocalPlayerID());

	if (IsDonator(Game.GetLocalPlayerID()) === false) {
		$("#CompanionNotification").AddClass("not_donator");
		$("#CompanionNotificationLabel").text = $.Localize("companion_not_donator");
		return;
	}

	//	$.Msg(DonatorStatusConverter(donator_status))
	//	$.Msg(required_status)
	if (DonatorStatusConverter(donator_status) < required_status) {
		$("#CompanionNotification").AddClass("not_donator");
		$("#CompanionNotificationLabel").text = "Your donator status is too low. Required status: (" + $.Localize("donator_label_" + DonatorStatusConverterReverse(required_status)) + ")";
		return;
	}

	//	$.Msg("POST modify companion:")
	//	$.Msg(id)
	//	$.Msg(Game.GetLocalPlayerInfo().player_steamid)

	api.updateCompanion({
		companion_id: id,
		steamid: Game.GetLocalPlayerInfo().player_steamid,
	}, function () {
		$("#CompanionNotification").AddClass("success");
		$("#CompanionNotificationLabel").text = $.Localize("companion_success") + " " + $.Localize(name) + "!";
		GameEvents.SendCustomGameEventToServer("change_companion", {
			ID: Players.GetLocalPlayer(),
			unit: companion,
			js: true
		});
		$.Schedule(6.0, function () {
			$("#CompanionNotification").RemoveClass("success");
			$("#CompanionNotificationLabel").text = "";
			companion_changed = false;
		});
	}, function () {
		$("#CompanionNotification").AddClass("failure");
		$("#CompanionNotificationLabel").text = $.Localize("companion_error");
		$.Schedule(6.0, function () {
			$("#CompanionNotification").RemoveClass("failure");
			$("#CompanionNotificationLabel").text = "";
			companion_changed = false;
		});
	});

	companion_changed = true;
}

function SetStatue(statue, name, id) {
	if (companion_changed === true) {
		//		$.Msg("SLOW DOWN BUDDY!");
		return;
	}

	if ($("#CompanionNotification").BHasClass("not_donator")) {
		$("#CompanionNotification").RemoveClass("not_donator");
	}

	var donator_status = IsDonator(Game.GetLocalPlayerID());

	if (IsDonator(Game.GetLocalPlayerID()) === false) {
		$("#CompanionNotification").AddClass("not_donator");
		$("#CompanionNotificationLabel").text = $.Localize("companion_not_donator");
		return;
	}

	if (DonatorStatusConverter(donator_status) < required_status) {
		$("#CompanionNotification").AddClass("not_donator");
		$("#CompanionNotificationLabel").text = "Your donator status is too low. Required status: (" + $.Localize("donator_label_" + DonatorStatusConverterReverse(required_status)) + ")";
		return;
	}

	api.updateStatue({
		statue_id: id,
		steamid: Game.GetLocalPlayerInfo().player_steamid,
	}, function () {
		$("#CompanionNotification").AddClass("success");
		$("#CompanionNotificationLabel").text = $.Localize("statue_success") + " " + $.Localize(name) + "!";
		GameEvents.SendCustomGameEventToServer("change_statue", {
			ID: Players.GetLocalPlayer(),
			unit: statue
		});
		$.Schedule(6.0, function () {
			$("#CompanionNotification").RemoveClass("success");
			companion_changed = false;
			$("#CompanionNotificationLabel").text = "";
		});
	}, function () {
		$("#CompanionNotification").AddClass("failure");
		$("#CompanionNotificationLabel").text = $.Localize("companion_error");
		$.Schedule(6.0, function () {
			$("#CompanionNotification").RemoveClass("failure");
			companion_changed = false;
			$("#CompanionNotificationLabel").text = "";
		});
	});

	companion_changed = true;
}

function SetEmblem(emblem, name, id, required_status) {
	if (companion_changed === true) {
		//		$.Msg("SLOW DOWN BUDDY!");
		return;
	}

	if ($("#CompanionNotification").BHasClass("not_donator")) {
		$("#CompanionNotification").RemoveClass("not_donator");
	}

	var donator_status = IsDonator(Game.GetLocalPlayerID());

	if (IsDonator(Game.GetLocalPlayerID()) === false) {
		$("#CompanionNotification").AddClass("not_donator");
		$("#CompanionNotificationLabel").text = $.Localize("companion_not_donator");
		return;
	}

	//	$.Msg(DonatorStatusConverter(donator_status))
	//	$.Msg(required_status)
	if (DonatorStatusConverter(donator_status) < required_status) {
		$("#CompanionNotification").AddClass("not_donator");
		$("#CompanionNotificationLabel").text = "Your donator status is too low. Required status: (" + $.Localize("donator_label_" + DonatorStatusConverterReverse(required_status)) + ")";
		return;
	}

	api.updateEmblem({
		emblem_id: id,
		steamid: Game.GetLocalPlayerInfo().player_steamid,
	}, function () {
		$("#CompanionNotification").AddClass("success");
		$("#CompanionNotificationLabel").text = $.Localize("emblem_success") + " " + $.Localize(name) + "!";
		GameEvents.SendCustomGameEventToServer("change_emblem", {
			ID: Players.GetLocalPlayer(),
			unit: emblem
		});
		$.Schedule(6.0, function () {
			$("#CompanionNotification").RemoveClass("success");
			$("#CompanionNotificationLabel").text = "";
			companion_changed = false;
		});
	}, function () {
		$("#CompanionNotification").AddClass("failure");
		$("#CompanionNotificationLabel").text = $.Localize("companion_error");
		$.Schedule(6.0, function () {
			$("#CompanionNotification").RemoveClass("failure");
			$("#CompanionNotificationLabel").text = "";
			companion_changed = false;
		});
	});

	companion_changed = true;
}

function SetTag() {
	var chat = $("#GameChatEntry");

	chat.SetPanelEvent("oninputsubmit", function () {
		if (companion_changed === true) {
			//			$.Msg("SLOW DOWN BUDDY!");
			return;
		}

		companion_changed = true;

		if (chat.text === "-ping") {
			Game.ServerCmd("dota_ping");
		}
		/*
				GameEvents.SendCustomGameEventToServer("battlepass:update_tag", {
					steamid : Game.GetLocalPlayerInfo().player_steamid,
					tag_name : chat.text,
				})
		*/
		api.updateTag({
			steamid: Game.GetLocalPlayerInfo().player_steamid,
			tag_name: chat.text
		}, function () {
			GameEvents.SendCustomGameEventToServer("change_ingame_tag", {
				ingame_tag: chat.text
			});

			$("#CompanionNotification").AddClass("success");
			$("#CompanionNotificationLabel").text = $.Localize("tag_success") + " " + $.Localize(chat.text) + "!";

			$.Msg("Ingame tag update: success!")
			$.Schedule(6.0, function () {
				$("#CompanionNotification").RemoveClass("success");
				$("#CompanionNotificationLabel").text = "";
				companion_changed = false;
			});

			chat.text = "";
		}, function () {
			$.Msg("Ingame tag update: failure")
			$("#CompanionNotification").AddClass("failure");
			$("#CompanionNotificationLabel").text = $.Localize("companion_error");
			$.Schedule(6.0, function () {
				$("#CompanionNotification").RemoveClass("failure");
				$("#CompanionNotificationLabel").text = "";
				companion_changed = false;
			});
		});
	});
}

function SetArmory(hero, slot_id, item_id, bp_name, bForceUnequip) {
	if (companion_changed === true && bForceUnequip == undefined) {
		$.Msg("SLOW DOWN BUDDY!");
		return;
	}

	if (slot_id == undefined) slot_id = "weapon";

	api.updateArmory({
		steamid: Game.GetLocalPlayerInfo().player_steamid,
		hero: hero,
		slot_id: slot_id,
		item_id: item_id,
		custom_game: game_type,
	}, function () {
		$("#CompanionNotification").AddClass("success");

		var text = "";

		if ($("#reward_equipped_" + item_id)) {
			$("#reward_equipped_" + item_id).DeleteAsync(0);
			text = $.Localize("bp_reward_unequip_success") + " " + $.Localize(bp_name);
		} else {
			text = $.Localize("bp_reward_equip_success") + " " + $.Localize(bp_name);
			SetRewardEquipped(item_id, hero);
		}

		$("#CompanionNotificationLabel").text = text.toLowerCase();

		/*
				GameEvents.SendCustomGameEventToServer("change_emblem", {
					ID : Players.GetLocalPlayer(),
					unit : emblem
				});
		*/

		$.Schedule(6.0, function () {
			$("#CompanionNotification").RemoveClass("success");
			$("#CompanionNotificationLabel").text = "";
			companion_changed = false;
		});
	}, function () {

		$("#CompanionNotification").AddClass("failure");
		$("#CompanionNotificationLabel").text = $.Localize("companion_error");

		$.Schedule(6.0, function () {
			$("#CompanionNotification").RemoveClass("failure");
			$("#CompanionNotificationLabel").text = "";
			companion_changed = false;
		});
	});

	companion_changed = true;
}

function SpecialBubbleSortByElement(t, array_name, element_name) {
	if (!t)
		return;

	var i = 1;

	while (t[i] != undefined) {
		for (var k in t) {
			var l = (parseInt(k) + 1).toString();

			if (t[l] && t[k][array_name] && t[k][array_name][element_name] && t[l][array_name][element_name] && parseInt(t[k][array_name][element_name]) < parseInt(t[l][array_name][element_name])) {
				var element_1 = t[k];
				var element_2 = t[l];

				t[k] = element_2;
				t[l] = element_1;
				i = 0;
			} else {
				i++;
			}
		}
	}

	return t;
}

var current_type = "";
function HallOfFame(type, retainSubTab, iRoundCount) {
	if (!retainSubTab) {
		SwitchLeaderboardWrapper(type);
	}

	$("#ExperienceTops").RemoveAndDeleteChildren();

	var plyData = CustomNetTables.GetTableValue("battlepass_player", Players.GetLocalPlayer());
	var top_users = undefined;
	var iterations = 100;

	//	$.Msg(plyData);

	if (iRoundCount) {
		current_leaderboard_round = current_leaderboard_round + iRoundCount;

		var max_rounds = CustomNetTables.GetTableValue("game_options", "max_rounds");
		if (max_rounds && max_rounds["1"]) max_rounds == max_rounds["1"]

		if (current_leaderboard_round > max_rounds)
			current_leaderboard_round = 1;
		else if (current_leaderboard_round <= 0)
			current_leaderboard_round = max_rounds;
	}

	$("#RoundOrderLabel").text = "Round " + current_leaderboard_round;

	if (type == "Donator") {
		top_users = CustomNetTables.GetTableValue("game_options", "leaderboard_donator");
	} else if (type == "Winrate") {
		top_users = top_winrate;
	} else if (type == "Diretide") {
		top_users = CustomNetTables.GetTableValue("game_options", "leaderboard_diretide");
		iterations = 10;
	} else if (type == "Experience" && game_type == "PLS") {
		top_users = CustomNetTables.GetTableValue("game_options", "olympiade_leaderboard");

		if (top_users && top_users[current_leaderboard_round.toString()]) top_users = top_users[current_leaderboard_round.toString()];

		top_users = SpecialBubbleSortByElement(top_users, "round_score", current_leaderboard_round.toString());
	}

	//	$.Msg(top_users);

	if (top_users == undefined) {
		$.Schedule(3.0, function () {
			HallOfFame(type, retainSubTab, iRoundCount);
		})

		return;
	}

	for (var i in top_users) {
		if (top_users === undefined) {
			$.Msg("Top Players not defined...")
			return;
		}

		var user_info = top_users[(i).toString()];
		var top_id = parseInt(i) + 1;

		//		$.Msg(user_info);

		if (!user_info) {
			$.Msg("Invalid user info. End loop");
			return;
		}

		//		$.Msg(user_info)

		var next_level_progress = user_info.next_level_progress || 0;
		var xp_level = user_info.xp_level || 0;
		var rank_title = user_info.rank_title || "Rookie";
		var xp_in_level = user_info.xp_in_level || 0;
		var xp_next_level = user_info.xp_next_level || 0;
		var xp_total_for_level = user_info.xp_total_for_level || 500;

		var player = $.CreatePanel("Panel", $('#' + type + 'Tops'), "player_" + top_id);
		player.AddClass("LeaderboardGames");
		var rank = $.CreatePanel("Label", player, "rank_" + top_id);
		rank.AddClass("LeaderboardRank");
		rank.text = top_id;

		/*
				if (local_rank && Game.GetLocalPlayerInfo().player_steamid == user_info.steamid) {
					local_rank.text = top_id;
				}
		*/

		var steam_id = $.CreatePanel("DOTAAvatarImage", player, "player_steamid_" + top_id);
		steam_id.AddClass("LeaderboardAvatar");
		steam_id.steamid = user_info.steamid;
		steam_id.style.width = "38px";
		steam_id.style.height = "38px";
		steam_id.style.marginLeft = "40px";
		steam_id.style.marginRight = "40px";
		steam_id.style.align = "center center";

		var leaderboard_border = [];
		leaderboard_border[1] = "darkred"
		leaderboard_border[2] = "red"
		leaderboard_border[3] = "blue"
		leaderboard_border[4] = "darkred"
		leaderboard_border[5] = "gold"
		leaderboard_border[6] = "green"
		leaderboard_border[7] = "purple"
		leaderboard_border[8] = "dodgerblue"
		leaderboard_border[9] = "brown"

		if (user_info.donator_status)
			steam_id.style.border = "1px solid " + leaderboard_border[user_info.donator_status];
		else
			steam_id.style.border = "1px solid #3f464ecc";

		var imbar_container = $.CreatePanel("Panel", player, "imbar_container_" + top_id);
		imbar_container.AddClass("LeaderboardXP");
		var imbar = $.CreatePanel("ProgressBar", imbar_container, "imbar_" + top_id);
		imbar.AddClass("imbar-progress-bar");
		var imbar_value = (parseFloat(xp_in_level - xp_next_level) / xp_next_level) + 1;
		imbar.value = imbar_value;

		var imbar_lvl = $.CreatePanel("Label", imbar_container, "imbar_lvl" + top_id);
		imbar_lvl.AddClass("imbar-lvl");
		imbar_lvl.text = "Level: " + xp_level;

		var imbar_rank_wrapper = $.CreatePanel("Panel", imbar_container, "imbar_rank" + top_id);
		imbar_rank_wrapper.AddClass("imbar-rank-wrapper");

		var imbar_rank_circle = $.CreatePanel("Panel", imbar_rank_wrapper, "");
		imbar_rank_circle.AddClass("imbar-rank-cicle");
		imbar_rank_circle.style.backgroundColor = "white";
		//		imbar_rank_circle.style.backgroundColor = user_info.title_color;

		if (rank_title == "Icefrog")
			rank_title += " " + (xp_level - 300);
		else if (rank_title == "Firetoad")
			rank_title += " " + (xp_level - 400);

		var imbar_rank = $.CreatePanel("Label", imbar_rank_wrapper, "");
		imbar_rank.AddClass("imbar-rank");
		imbar_rank.text = rank_title;

		var xp_text = {}
		xp_text["Experience"] = xp_in_level + "/" + xp_total_for_level;
		xp_text["Winrate"] = "Matches: " + user_info.total_matches;
		xp_text["Donator"] = "";
		xp_text["Diretide"] = "";

		var imbar_xp = $.CreatePanel("Label", imbar_container, "imbar_xp" + top_id);
		imbar_xp.AddClass("imbar-xp");
		imbar_xp.text = xp_text[type];

		var imr = $.CreatePanel("Label", player, "rank_" + top_id);
		imr.AddClass("LeaderboardIMR");

		// temporary
		if (type == "Winrate") {
			imr.text = user_info.win_percentage;
		} else {
			if (user_info.round_score[current_leaderboard_round]) {
				var score = user_info.round_score[current_leaderboard_round];

				if (current_leaderboard_round == 4)
					imr.text = RawTimetoGameTime(score);
				else
					imr.text = score;
			}
		}
	}
}

function SafeToLeave() {
	$("#SafeToLeave").style.visibility = "visible";
}

function GenerateBattlepassPanel(reward_list, player, bRewardsDisabled) {
	var plyData = CustomNetTables.GetTableValue("battlepass_player", player);
	var reward_row = $("#BattlepassRewardRow");
	var player_avatar = $("#PlayerSteamAvatar");

	if (player_avatar)
		player_avatar.steamid = Game.GetLocalPlayerInfo(Players.GetLocalPlayer()).player_steamid;

	for (var i = 1; i <= 1000; i++) {
		if (reward_list[i] != undefined) {
			var bp_image = reward_list[i].image;
			var bp_level = reward_list[i].level;
			var bp_name = reward_list[i].name;
			var bp_rarity = reward_list[i].rarity;
			var bp_type = reward_list[i].type;
			var bp_item_id = reward_list[i].item_id;
			var bp_slot_id = reward_list[i].slot_id;
			var bp_hero = reward_list[i].hero;
			var bp_item_unreleased = reward_list[i].item_unreleased;

			// terrible fix
			if (bp_type == "taunt")
				bp_slot_id = "taunt";

			if (!$("#container_level_" + bp_level)) {
				var level_container = $.CreatePanel("Panel", reward_row, "container_level_" + bp_level);
				level_container.AddClass("ContainerLevel");

				var reward_level_container = $.CreatePanel("Panel", $("#container_level_" + bp_level), "reward_container_level_" + bp_level);
				reward_level_container.AddClass("RewardContainerLevel");

				var reward_label_container = $.CreatePanel("Panel", $("#container_level_" + bp_level), "");
				reward_label_container.AddClass("BattlepassRewardLabelContainer");

				var reward_label = $.CreatePanel("Label", reward_label_container, "");
				reward_label.AddClass("BattlepassRewardLabel");
				reward_label.text = $.Localize("#battlepass_level") + bp_level;
				//				reward_label.AddClass(bp_rarity + "_text");
			}

			var reward = $.CreatePanel("Button", $("#reward_container_level_" + bp_level), "reward_button_" + bp_item_id);
			reward.BLoadLayoutSnippet('BattlePassReward');
			reward.FindChildTraverse("BattlepassRewardImage").style.backgroundImage = 'url("s2r://panorama/images/' + bp_image + '.png")';
			reward.FindChildTraverse("BattlepassRewardImage").AddClass(bp_rarity + "_border");
			reward.hero_type = bp_hero;
			/*
						if (bp_hero != undefined && bp_hero.indexOf("npc_dota_hero_") !== -1) {
							var reward_hero_icon = $.CreatePanel("Panel", reward, "");
							reward_hero_icon.style.backgroundImage = 'url("file://{images}/heroes/icons/' + bp_hero + '.png")';
							reward_hero_icon.AddClass("BattlepassRewardHeroIcon");
						}
			*/
			if (plyData != null && bp_item_unreleased == undefined || bRewardsDisabled & bRewardsDisabled == true) {
				// Disable tinker immortal for now until fixed
				if (bp_item_id != "105" && bp_item_id != "113" && bp_item_id != "114" && bp_item_id != "115" && bp_item_id != "116" && bp_item_id != "118" && bp_item_id != "119" && bp_item_id != "120" && bp_item_id != "121") {
					if (bp_level <= plyData.Lvl) {
						reward.FindChildTraverse("BattlepassRewardTitle").AddClass("BattlepassRewardLabelUnlocked");

						var reward_panel_unlocked = $.CreatePanel("Panel", reward, "");
						reward_panel_unlocked.AddClass("BattlepassRewardPanelUnlocked");

						if (bp_type == "bundle" || bp_type == "wearable" || bp_type == "taunt") {
							var hero_tooltip = $.Localize(bp_hero);
							var new_hero_tooltip = undefined;

							if (hero_tooltip.indexOf(" (IMBA)") !== -1) {
								new_hero_tooltip = hero_tooltip.replace(" (IMBA)", "");
							}

							if (new_hero_tooltip)
								reward.FindChildTraverse("BattlepassRewardTitle").text = new_hero_tooltip + ": " + $.Localize(bp_name);
							else
								reward.FindChildTraverse("BattlepassRewardTitle").text = hero_tooltip + ": " + $.Localize(bp_name);
						} else
							reward.FindChildTraverse("BattlepassRewardTitle").text = $.Localize("battlepass_" + bp_type) + ": " + $.Localize(bp_name);

						var armory = CustomNetTables.GetTableValue("battlepass_rewards", "rewards_" + player);

						if (armory) {
							var j = 1;

							while (armory[j] != undefined) {
								var item = armory[j];

								if (item && item.item_id == bp_item_id) {
									//									$.Msg(item)
									SetRewardEquipped(bp_item_id, bp_hero);

									// rough fix to unequip rewards if somehow a player equip higher tiers rewards
									if (plyData.Lvl < bp_level) {
										SetArmory(bp_hero, slot_id, bp_item_id, bp_name, false)
									}

									break;
								}

								j++;
							}
						}

						var event = function (bp_hero, bp_slot_id, bp_item_id, bp_name) {
							return function () {
								SetArmory(bp_hero, bp_slot_id, bp_item_id, bp_name);
							}
						};

						reward.SetPanelEvent("onactivate", event(bp_hero, bp_slot_id, bp_item_id, bp_name));
					} else {
						reward.AddClass("BattlepassRewardIcon_locked")
						reward.FindChildTraverse("BattlepassRewardTitle").AddClass("BattlepassRewardLabelLocked");
						reward.FindChildTraverse("BattlepassRewardTitle").text = $.Localize("battlepass_reward_locked") + "\n" + $.Localize("battlepass_" + bp_type) + ": " + $.Localize(bp_name);
					}
				} else {
					reward.AddClass("BattlepassRewardIcon_unreleased")
					reward.FindChildTraverse("BattlepassRewardTitle").AddClass("BattlepassRewardLabelUnreleased");
					reward.FindChildTraverse("BattlepassRewardTitle").text = $.Localize("battlepass_reward_unreleased") + "\n" + $.Localize("battlepass_" + bp_type) + ": " + $.Localize(bp_name);
				}
			} else {
				reward.AddClass("BattlepassRewardIcon_locked")
				reward.FindChildTraverse("BattlepassRewardTitle").AddClass("BattlepassRewardLabelLocked");
				reward.FindChildTraverse("BattlepassRewardTitle").text = $.Localize("battlepass_reward_locked") + "\n" + $.Localize("battlepass_" + bp_type) + ": " + $.Localize(bp_name);
			}

			if (reward.FindChildTraverse("BattlepassRewardRarity")) {
				reward.FindChildTraverse("BattlepassRewardRarity").text = bp_rarity;
				reward.FindChildTraverse("BattlepassRewardRarity").AddClass(bp_rarity + "_text");
			}
		} else {
			break;
		}
	}
}

function SetRewardEquipped(item_id, item_hero) {
	var i = 1;

	while ($("#reward_button_" + i) != undefined) {
		if ($("#reward_button_" + i).hero_type == item_hero && $("#reward_button_" + i).GetChild(1)) {
			$("#reward_button_" + i).GetChild(1).DeleteAsync(0);
		}

		i++;
	}

	var reward_equipped = $.CreatePanel("Panel", $("#reward_button_" + item_id).FindChildTraverse("BattlepassRewardImage"), "reward_equipped_" + item_id);
	reward_equipped.AddClass("RewardEquipped");
}

function GenerateCompanionPanel(companions, player, panel, retainSubTab) {
	var i_count = 0;
	var class_option_count = 1;

	//	$.Msg("List of available companions:")
	//	$.Msg(companions)

	var donator_row = $.CreatePanel("Panel", $('#' + panel + 'TableWrapper'), "DonatorRow" + class_option_count + "_" + player);
	donator_row.AddClass("DonatorRow");

	// Companion Generator
	var plyData = CustomNetTables.GetTableValue("battlepass_player", Players.GetLocalPlayer());

	/*
	 * if (plyData.companion_enabled == 1) { if
	 * ($("#DonatorOptionsToggle").BHasClass("companion_disabled")) {
	 * $("#DonatorOptionsToggle").RemoveClass("companion_disabled") }
	 * $("#DonatorOptionsToggle").AddClass("companion_enabled")
	 * $("#DonatorOptionsToggleLabel").text = $.Localize("#companion_enabled") }
	 * else { if ($("#DonatorOptionsToggle").BHasClass("companion_enabled")) {
	 * $("#DonatorOptionsToggle").RemoveClass("companion_enabled") }
	 * $("#DonatorOptionsToggle").AddClass("companion_disabled")
	 * $("#DonatorOptionsToggleLabel").text = $.Localize("#companion_disabled") }
	 */

	var companion_unit = [];
	var companion_name = [];
	var companion_id = [];
	var companion_skin = [];

	// +1 for unique companion (e.g: cookies, baumi,
	// bulldog, icefrog)
	for (i in companions) {
		var vip = false;
		i_count = i_count + 1;
		if (companions[i] != undefined) {
			companion_unit[i] = companions[i]["file"];
			companion_id[i] = i;
			required_status = companions[i]["required_status"];

			if (i == 0) {
				companion_name[i] = "Disabled";
			}
			else
				companion_name[i] = companions[i]["name"];

			if (companion_unit[i] == "npc_donator_companion_sappling")
				companion_skin[i] = 3;
		}

		if (i_count > 5) {
			class_option_count = class_option_count + 1;
			var donator_row = $.CreatePanel("Panel", $('#' + panel + 'TableWrapper'), panel + "Row" + class_option_count + "_" + player);
			donator_row.AddClass("DonatorRow");
			i_count = 1;
		}

		var companion = $.CreatePanel("Panel", donator_row, companion_name[i]);
		companion.AddClass("DonatorReward");

		var companionpreview = $.CreatePanel("Button", companion, "CompanionPreview_" + i);
		companionpreview.style.width = "132px";
		companionpreview.style.height = "135px";

		var companion_scene = $.CreatePanelWithProperties('DOTAScenePanel', companionpreview, "", {
			class: `companion_scene`,
			particleonly: "false",
			unit: companion_name[i],
		});

		//		companionpreview.style.backgroundImage = 'url("file://{images}/custom_game/flyout/donator_emblem_' + i + '.png")';
		//		companionpreview.BLoadLayoutFromString('<root><Panel><DOTAScenePanel style="width:100%; height:153px; margin-top: -45px;" particleonly="false" unit="' + companion_unit[i.toString()] + '"/></Panel></root>', false, false);
		companionpreview.style.opacityMask = 'url("s2r://panorama/images/masks/hero_model_opacity_mask_png.vtex");'

		var companion_unit_name = companion_unit[i];

		/*
		 * This is weird. Seams like panorama v8 has a bug here.
		 * companion_unit_name should be copy-by-value but instead is
		 * copy-by-reference
		 */

		if (panel == "Companion") {
			var event = function (ev, name, id, required_status) {
				return function () {
					SetCompanion(ev, name, id, required_status);
				}
			};
		} else if (panel == "Statue") {
			var event = function (ev, name, id, required_status) {
				return function () {
					SetStatue(ev, name, id, required_status);
				}
			};
		} else if (panel == "Emblem") {
			var event = function (ev, name, id, required_status) {
				return function () {
					SetEmblem(ev, name, id, required_status);
				}
			};
		}

		companionpreview.SetPanelEvent("onactivate", event(companion_unit_name, companion_name[i], companion_id[i], required_status));

		var reward_label = $.CreatePanel("Label", companion, companion_name[i] + "_label");
		reward_label.AddClass("BattlepassRewardLabel");
		reward_label.text = companion_name[i];

		if (required_status != undefined && required_status != 0) {
			if (GetDonatorColor(required_status))
				reward_label.style.color = GetDonatorColor(required_status);
			else
				$.Msg("Failed to give color for status " + required_status);
		}

		if (!retainSubTab) {
			SwitchDonatorWrapper(panel);
		}
	}
}

function CompanionSkin(unit, j) {
	//	$.Msg(unit, j)
	GameEvents.SendCustomGameEventToServer("change_companion_skin", {
		ID: Players.GetLocalPlayer(),
		unit: unit,
		skin: j
	})
}

function SettingsIngameTag() {
	var tag = 0;

	if (CustomNetTables.GetTableValue("battlepass_player", Players.GetLocalPlayer()).toggle_tag != undefined) {
		tag = CustomNetTables.GetTableValue("battlepass_player", Players.GetLocalPlayer()).toggle_tag

		if (tag == 1)
			tag = 0
		else
			tag = 1
	}

	api.updateIngameTag({
		steamid: Game.GetLocalPlayerInfo().player_steamid,
		toggle_tag: tag
	}, function () {
		GameEvents.SendCustomGameEventToServer("toggle_ingame_tag", {
			tag: tag
		});
		//		$.Msg("Ingame tag update: success!")
		//		$.Schedule(6.0, function() {
		//			$("#CompanionNotification").RemoveClass("success");
		//			companion_changed = false;
		//		});
	}, function () {
		$("#IngameTagCheckBox").checked = tag;
		//		$.Msg("Ingame tag update: failure")
		//		$("#CompanionNotification").AddClass("failure");
		//		$("#CompanionNotificationLabel").text = $.Localize("companion_error");
		//		$.Schedule(6.0, function() {
		//			$("#CompanionNotification").RemoveClass("failure");
		//			companion_changed = false;
		//		});
	});
}

function SettingsBattlepassRewards() {
	var toggle_rewards = false;
	//	$.Msg("BP Rewards :" + CustomNetTables.GetTableValue("battlepass_player", Players.GetLocalPlayer()).bp_rewards)
	if (CustomNetTables.GetTableValue("battlepass_player", Players.GetLocalPlayer()).bp_rewards != undefined) {
		toggle_rewards = CustomNetTables.GetTableValue("battlepass_player", Players.GetLocalPlayer()).bp_rewards
		if (toggle_rewards == 1)
			toggle_rewards = 0
		else
			toggle_rewards = 1
	}

	//	$.Msg("BP Rewards :" + toggle_rewards)

	api.updateBPRewards({
		steamid: Game.GetLocalPlayerInfo().player_steamid,
		bp_rewards: toggle_rewards
	}, function () {
		GameEvents.SendCustomGameEventToServer("change_battlepass_rewards", {
			ID: Players.GetLocalPlayer(),
			bp_rewards: toggle_rewards
		});
		RefreshBattlepass(toggle_rewards);
		//		$.Msg("BP rewards update: success!")
		//		$.Schedule(6.0, function() {
		//			$("#CompanionNotification").RemoveClass("success");
		//			companion_changed = false;
		//		});
	}, function () {
		//		$.Msg("BP rewards update: failure")
		//		$("#CompanionNotification").AddClass("failure");
		//		$("#CompanionNotificationLabel").text = $.Localize("companion_error");
		//		$.Schedule(6.0, function() {
		//			$("#CompanionNotification").RemoveClass("failure");
		//			companion_changed = false;
		//		});
	});
}

function SettingsPlayerXP() {
	var toggle = false;
	//	$.Msg("BP Rewards :" + CustomNetTables.GetTableValue("battlepass_player", Players.GetLocalPlayer()).player_xp)
	if (CustomNetTables.GetTableValue("battlepass_player", Players.GetLocalPlayer()).player_xp != undefined) {
		toggle = CustomNetTables.GetTableValue("battlepass_player", Players.GetLocalPlayer()).player_xp
		if (toggle == 1)
			toggle = 0
		else
			toggle = 1
	}

	//	$.Msg("Player XP :" + toggle)

	api.updatePlayerXP({
		steamid: Game.GetLocalPlayerInfo().player_steamid,
		player_xp: toggle
	}, function () {
		GameEvents.SendCustomGameEventToServer("change_player_xp", {
			ID: Players.GetLocalPlayer(),
			player_xp: toggle
		});
		//		$.Msg("Player XP update: success!")
		//		$.Schedule(6.0, function() {
		//			$("#CompanionNotification").RemoveClass("success");
		//			companion_changed = false;
		//		});
	}, function () {
		//		$.Msg("Player XP update: failure")
		//		$("#CompanionNotification").AddClass("failure");
		//		$("#CompanionNotificationLabel").text = $.Localize("companion_error");
		//		$.Schedule(6.0, function() {
		//			$("#CompanionNotification").RemoveClass("failure");
		//			companion_changed = false;
		//		});
	});
}

function SettingsWinrate() {
	var toggle = 0;
	if (CustomNetTables.GetTableValue("battlepass_player", Players.GetLocalPlayer()).winrate_toggle != undefined) {
		toggle = CustomNetTables.GetTableValue("battlepass_player", Players.GetLocalPlayer()).winrate_toggle
		if (toggle == 1)
			toggle = 0
		else
			toggle = 1
	}

	//	$.Msg("Player XP :" + toggle)

	api.updateWinrate({
		steamid: Game.GetLocalPlayerInfo().player_steamid,
		winrate: toggle
	}, function () {
		GameEvents.SendCustomGameEventToServer("change_winrate", {
			ID: Players.GetLocalPlayer(),
			player_xp: toggle
		});
	}, function () {
		$.Msg("Winrate update fail!")
	});
}

function _ScoreboardUpdater_SetTextSafe(panel, childName, textValue) {
	if (panel === null)
		return;
	var childPanel = panel.FindChildInLayoutFile(childName)
	if (childPanel === null)
		return;

	childPanel.text = textValue;
}

function _ScoreboardUpdater_SetValueSafe(panel, childName, Value) {
	if (panel === null)
		return;
	var childPanel = panel.FindChildInLayoutFile(childName)

	if (childPanel === null)
		return;

	childPanel.value = Value;
}

function SwitchLeaderboardWrapper(type) {
	if (current_sub_tab == type) {
		//		$.Msg("Bro don't reload you're fine!");
		return;
	}

	current_sub_tab = type;
	//	$.Msg(type)

	//	$("#PatreonTableWrapper").style.visibility = "collapse";
	for (var i = 0; i < LeaderboardInfoContainer.GetChildCount(); i++) {
		if (LeaderboardInfoContainer.GetChild(i).id != "LocalPlayerInfoContainer")
			LeaderboardInfoContainer.GetChild(i).style.visibility = "collapse";
	}

	for (var i = 0; i < MiniTabButtonContainer.GetChildCount(); i++) {
		MiniTabButtonContainer.GetChild(i).RemoveClass("active");
	}

	for (var i = 0; i < MiniTabButtonContainer2.GetChildCount(); i++) {
		MiniTabButtonContainer2.GetChild(i).RemoveClass("active");
	}

	$("#Leaderboard" + type + "TableWrapper").style.visibility = "visible";
	$("#Leaderboard" + type + "TabButton").AddClass('active');
}

function _ScoreboardUpdater_UpdatePlayerPanelXP(playerId, playerPanel, ImbaXP_Panel) {
	//	$.Msg("Updating player xp panel");

	var ids = {
		xpRank: "ImbaXPRank" + playerId,
		xp: "ImbaXP" + playerId,
		xpEarned: "ImbaXPEarned" + playerId,
		level: "ImbaLvl" + playerId,
		progress_bar: "XPProgressBar" + playerId
	};

	// setup panels
	ImbaXP_Panel.BCreateChildren("<Panel id='XPProgressBarContainer" + playerId + "' value='0.0'/>");
	var Imbar = ImbaXP_Panel.BCreateChildren("<ProgressBar id='XPProgressBar" + playerId + "'/>");


	ImbaXP_Panel.BCreateChildren("<Panel id='LevelContainer'/>");

	var LevelContainer = ImbaXP_Panel.FindChildTraverse("LevelContainer");
	LevelContainer.BCreateChildren("<Panel id='LevelContainerChild'/>");

	var LevelContainerChild = ImbaXP_Panel.FindChildTraverse("LevelContainerChild");

	LevelContainerChild.BCreateChildren("<Label id='LevelLabel' text='Level: '/>");

	LevelContainerChild.BCreateChildren("<Label id='ImbaLvl" + playerId + "' text='undefined'/>");
	LevelContainerChild.BCreateChildren("<Label id='ImbaXPRank" + playerId + "' text='undefined'/>");


	LevelContainer.BCreateChildren("<Panel id='LevelContainerChild2'/>");

	var LevelContainerChild2 = ImbaXP_Panel.FindChildTraverse("LevelContainerChild2");


	LevelContainerChild2.BCreateChildren("<Label id='ImbaXP" + playerId + "' text='undefined'/>");
	LevelContainerChild2.BCreateChildren("<Label id='ImbaXPEarned" + playerId + "' text='+0'/>");

	var steamid = Game.GetPlayerInfo(playerId).player_steamid;
	/*
		// load player data from api
		LoadPlayerInfo(function (data) {
			var thisPlayerInfo = null;
			playerInfo.forEach(function (i) {
				if (i.steamid == steamid)
					thisPlayerInfo = i;
			});
	
			if (thisPlayerInfo == null) // wtf
				return;
	
			$.Msg(thisPlayerInfo)
	
			_ScoreboardUpdater_SetTextSafe(playerPanel, ids.xpRank, thisPlayerInfo.xp_rank_title);
			_ScoreboardUpdater_SetTextSafe(playerPanel, ids.xp, thisPlayerInfo.xp_in_current_level + "/" + thisPlayerInfo.total_xp_for_current_level);
			_ScoreboardUpdater_SetTextSafe(playerPanel, ids.level, thisPlayerInfo.xp_level);
			_ScoreboardUpdater_SetValueSafe(playerPanel, ids.progress_bar, thisPlayerInfo.xp_in_current_level / thisPlayerInfo.total_xp_for_current_level);
			playerPanel.FindChildTraverse(ids.xpRank).style.color = "#" + thisPlayerInfo.xp_rank_color;
		});
	*/

	// xp shown fix (temporary?)
	var player_info = CustomNetTables.GetTableValue("battlepass_player", playerId.toString())

	if (!player_info || player_info.player_xp == 0) {
		_ScoreboardUpdater_SetTextSafe(playerPanel, ids.xpRank, "N/A");
		_ScoreboardUpdater_SetTextSafe(playerPanel, ids.xp, "N/A");
		_ScoreboardUpdater_SetTextSafe(playerPanel, ids.level, "N/A");
		_ScoreboardUpdater_SetValueSafe(playerPanel, ids.progress_bar, 0);
		playerPanel.FindChildTraverse(ids.xpRank).style.color = "#FFFFFF";
	} else if (player_info.player_xp == 1) {
		_ScoreboardUpdater_SetTextSafe(playerPanel, ids.xpRank, player_info.title);
		_ScoreboardUpdater_SetTextSafe(playerPanel, ids.xp, player_info.XP + "/" + player_info.MaxXP);
		_ScoreboardUpdater_SetTextSafe(playerPanel, ids.level, player_info.Lvl + ' - ');
		_ScoreboardUpdater_SetValueSafe(playerPanel, ids.progress_bar, player_info.XP / player_info.MaxXP);
		//		_ScoreboardUpdater_SetValueSafe(playerPanel, "Rank", player_info.winrate);
		playerPanel.FindChildTraverse(ids.xpRank).style.color = player_info.title_color;
		// playerPanel.FindChildTraverse(ids.level).style.color = player_info.title_color;		
	}

	_ScoreboardUpdater_SetValueSafe(playerPanel, "Rank", player_info.mmr_title);
}

function SetupPanel() {
	var ply_table = CustomNetTables.GetTableValue("battlepass_player", Players.GetLocalPlayer());

	if (ply_table) {
		if (ply_table.ingame_tag)
			$("#IngameTagCheckBox").checked = ply_table.toggle_tag;
		if (ply_table.bp_rewards)
			$("#BPRewardsCheckBox").checked = ply_table.bp_rewards;
		if (ply_table.player_xp)
			$("#PlayerXPCheckBox").checked = ply_table.player_xp;
		if (ply_table.winrate_toggle)
			$("#WinrateCheckBox").checked = ply_table.winrate_toggle;
	}
}

function CreateBattlepassButton() {
	var Parent = $.GetContextPanel().GetParent().GetParent().GetParent().FindChildTraverse("ButtonBar");

	if (!Parent) {
		$.Schedule(1.0, CreateBattlepassButton);
		return;
	}

	if (Parent.FindChildTraverse("BattlepassButton")) {
		Parent.FindChildTraverse("BattlepassButton").DeleteAsync(0);
	}

	var BattlepassButton = $.CreatePanel("Button", $.GetContextPanel(), "BattlepassButton");
	BattlepassButton.SetPanelEvent("onactivate", function () {
		ToggleBattlepass();
	});

	BattlepassButton.SetPanelEvent("onmouseover", function () {
		$.DispatchEvent("UIShowTextTooltip", BattlepassButton, $.Localize("battlepass"));
	})

	BattlepassButton.SetPanelEvent("onmouseout", function () {
		$.DispatchEvent("UIHideTextTooltip", BattlepassButton);
	})
	BattlepassButton.SetParent(Parent);
}

(function () {
	$.Schedule(2.0, CreateBattlepassButton);

	// prevent running an api call everytime this file is edited
	// if (!Game.IsInToolsMode()) {
	// 	var args = {
	// 		steamid: Game.GetLocalPlayerInfo().player_steamid,
	// 		language: $.Localize("lang"),
	// 	}

	// 	api.getPlayerPosition(args, function(players) {});
	// }

	// Portraits recorder
	/*
		if (Game.IsInToolsMode()) {
			var main_panel = $.GetContextPanel().GetParent().GetParent().GetParent().GetParent().FindChildTraverse("HUDElements");
			var portrait = $.GetContextPanel().GetParent().GetParent().GetParent().FindChildTraverse("portraitHUD");
	
			portrait.SetParent(main_panel);
			portrait.style.align = "center center";
			portrait.style.width = "256px";
			portrait.style.height = "256px";
		}
	*/
	// setup XP and IMR
	var ImbaXP_Panel = $.GetContextPanel().FindChildInLayoutFile("PanelImbaXP");
	var playerId = Game.GetLocalPlayerID();

	if (ImbaXP_Panel != null) {
		// get player data
		var plyData = CustomNetTables.GetTableValue("battlepass_player", playerId.toString());

		if (plyData != null) {
			// set xp values
			_ScoreboardUpdater_UpdatePlayerPanelXP(playerId, ImbaXP_Panel, ImbaXP_Panel);
		}
	}

	if (game_type == "IMBA") {
		var values = [
			"bounty_multiplier", // todo: add % in text
			"exp_multiplier", // todo: add % in text
			"initial_gold",
			"initial_level",
			"max_level",
			"gold_tick",
		]

		// Update the game options display
		for (var i in values) {
			var value = CustomNetTables.GetTableValue("game_options", values[i]);

			if (value && value[1] && $("#" + value + "_value"))
				$("#" + value + "_value").text = value[1];
		}
	} else {
		var panels = {
			"bounty_multiplier": "BountyMultiplier",
			"exp_multiplier": "ExpMultiplier",
			"initial_gold": "InitialGold",
			"initial_level": "InitialLevel",
			"max_level": "MaxLevel",
			"gold_tick": "GoldTick",
		}

		for (var i in panels) {
			const panel = panels[i];

			if ($("#" + panel + "Desc")) {
				$("#" + panel + "Desc").style.visibility = "collapse";
			}

			if ($("#" + panel + "Value")) {
				$("#" + panel + "Value").style.visibility = "collapse";
			}
		}

		if (game_type == "PW") {
			var max_score = CustomNetTables.GetTableValue("game_score", "max_score");

			if (max_score)
				max_score = max_score.kills;
			else
				return;

			$("#BountyMultiplierValue").text = max_score;
			$("#BountyMultiplierDesc").style.visibility = "visible";
			$("#BountyMultiplierValue").style.visibility = "visible";
		}
	}

	GameEvents.Subscribe("safe_to_leave", SafeToLeave);
})();
