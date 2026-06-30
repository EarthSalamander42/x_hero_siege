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

var game_version = CustomNetTables.GetTableValue("game_options", "game_version");
var game_type = undefined;
if (game_version)
	game_type = game_version.game_type;


function ToggleBattlepass() {
	if (toggle === false) {
		toggle = true;

		if (first_time === false) {
			first_time = true;
			Battlepass();

			if ($("#BattlepassTabButton"))
				$("#BattlepassTabButton").AddClass('active');
		}
	} else {
		toggle = false;
	}

	$.GetContextPanel().visible = toggle;
	$("#BattlepassWindow").SetHasClass("setvisible", toggle);
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

function SwitchBattlepassWrapper(type) {
	if (current_sub_tab == type) {
		//		$.Msg("Bro don't reload you're fine!");
		return;
	}

	current_sub_tab = type;

	var BattlepassInfoContainer = $("#BattlepassInfoContainer");

	for (var i = 1; i < BattlepassInfoContainer.GetChildCount(); i++) {
		var child = BattlepassInfoContainer.GetChild(i);
		child.style.visibility = "collapse";
	}

	var Buttons = $("#MiniTabButtonContainer");

	for (var i = 0; i < Buttons.GetChildCount(); i++) {
		var child = Buttons.GetChild(i);
		child.RemoveClass('active');
	}

	$("#" + type + "TableWrapper").style.visibility = "visible";
	$("#" + type + "TabButton").AddClass('active');

	// $('#BattlepassTabTitle').text = $.Localize("#donator_" + type.toLowerCase() + "_wrapper_label").toUpperCase();
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

	PlayerQuests();
	MiniTabButtonContainer.style.visibility = "visible";

	var BP_REWARDS = CustomNetTables.GetTableValue("battlepass_js_free", "rewards");
	if (BP_REWARDS && BP_REWARDS["1"])
		BP_REWARDS = BP_REWARDS["1"];

	var BP_REWARDS_2 = CustomNetTables.GetTableValue("battlepass_js_premium", "rewards");
	if (BP_REWARDS_2 && BP_REWARDS_2["1"])
		BP_REWARDS_2 = BP_REWARDS_2["1"];

	if (BP_REWARDS == undefined) {
		$.Msg("BP_REWARDS is undefined");
		return;
	}

	BP_REWARDS = BubbleSortByElement(BP_REWARDS, "level");
	BP_REWARDS_2 = BubbleSortByElement(BP_REWARDS_2, "level");

	GenerateBattlepassPanel(BP_REWARDS, $("#BattlepassRewardRowFree"), bRewardsDisabled);
	GenerateBattlepassPanel(BP_REWARDS_2, $("#BattlepassRewardRowPremiumContainer"), bRewardsDisabled);
	GenerateArmoryPanel(BP_REWARDS, BP_REWARDS_2, bRewardsDisabled);

	var companions = CustomNetTables.GetTableValue("battlepass_player", "companions");
	if (companions != undefined)
		GenerateCompanionPanel(companions, Players.GetLocalPlayer(), "Companion", retainSubTab);

	var emblems = CustomNetTables.GetTableValue("battlepass_player", "emblems");
	if (emblems != undefined)
		GenerateCompanionPanel(emblems, Players.GetLocalPlayer(), "Emblem", true);

	SetupPanel();
}

var companion_changed = false;

function SetCompanion(companion, name, id, required_status) {
	if (companion_changed === true) {
		// $.Msg("SLOW DOWN BUDDY!");
		return;
	}

	if ($("#CompanionNotification").BHasClass("not_donator")) {
		$("#CompanionNotification").RemoveClass("not_donator");
	}

	var donator_status = IsDonator(Game.GetLocalPlayerID());

	if (IsDonator(Game.GetLocalPlayerID()) === false) {
		$("#CompanionNotification").AddClass("not_donator");
		$("#CompanionNotificationLabel").text = $.Localize("#companion_not_donator");
		return;
	}

	//	$.Msg(DonatorStatusConverter(donator_status))
	//	$.Msg(required_status)
	if (DonatorStatusConverter(donator_status) < required_status) {
		$("#CompanionNotification").AddClass("not_donator");
		$("#CompanionNotificationLabel").text = "Your donator status is too low. Required status: (" + $.Localize("#donator_label_" + DonatorStatusConverterReverse(required_status)) + ")";
		return;
	}

	//	$.Msg("POST modify companion:")
	//	$.Msg(id)
	//	$.Msg(Game.GetLocalPlayerInfo().player_steamid)

	// api.updateCompanion({
	// 	companion_id: id,
	// 	steamid: Game.GetLocalPlayerInfo().player_steamid,
	// }, function () {
	// 	$("#CompanionNotification").AddClass("success");
	// 	$("#CompanionNotificationLabel").text = $.Localize("#companion_success") + " " + $.Localize("#" + name) + "!";
	// 	GameEvents.SendCustomGameEventToServer("change_companion", {
	// 		ID: Players.GetLocalPlayer(),
	// 		unit: companion,
	// 		js: true
	// 	});
	// 	$.Schedule(6.0, function () {
	// 		$("#CompanionNotification").RemoveClass("success");
	// 		$("#CompanionNotificationLabel").text = "";
	// 		companion_changed = false;
	// 	});
	// }, function () {
	// 	$("#CompanionNotification").AddClass("failure");
	// 	$("#CompanionNotificationLabel").text = $.Localize("#companion_error");
	// 	$.Schedule(6.0, function () {
	// 		$("#CompanionNotification").RemoveClass("failure");
	// 		$("#CompanionNotificationLabel").text = "";
	// 		companion_changed = false;
	// 	});
	// });

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
		$("#CompanionNotificationLabel").text = $.Localize("#companion_not_donator");
		return;
	}

	if (DonatorStatusConverter(donator_status) < required_status) {
		$("#CompanionNotification").AddClass("not_donator");
		$("#CompanionNotificationLabel").text = "Your donator status is too low. Required status: (" + $.Localize("#donator_label_" + DonatorStatusConverterReverse(required_status)) + ")";
		return;
	}

	// api.updateStatue({
	// 	statue_id: id,
	// 	steamid: Game.GetLocalPlayerInfo().player_steamid,
	// }, function () {
	// 	$("#CompanionNotification").AddClass("success");
	// 	$("#CompanionNotificationLabel").text = $.Localize("#statue_success") + " " + $.Localize("#" + name) + "!";
	// 	GameEvents.SendCustomGameEventToServer("change_statue", {
	// 		ID: Players.GetLocalPlayer(),
	// 		unit: statue
	// 	});
	// 	$.Schedule(6.0, function () {
	// 		$("#CompanionNotification").RemoveClass("success");
	// 		companion_changed = false;
	// 		$("#CompanionNotificationLabel").text = "";
	// 	});
	// }, function () {
	// 	$("#CompanionNotification").AddClass("failure");
	// 	$("#CompanionNotificationLabel").text = $.Localize("#companion_error");
	// 	$.Schedule(6.0, function () {
	// 		$("#CompanionNotification").RemoveClass("failure");
	// 		companion_changed = false;
	// 		$("#CompanionNotificationLabel").text = "";
	// 	});
	// });

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
		$("#CompanionNotificationLabel").text = $.Localize("#companion_not_donator");
		return;
	}

	//	$.Msg(DonatorStatusConverter(donator_status))
	//	$.Msg(required_status)
	if (DonatorStatusConverter(donator_status) < required_status) {
		$("#CompanionNotification").AddClass("not_donator");
		$("#CompanionNotificationLabel").text = "Your donator status is too low. Required status: (" + $.Localize("#donator_label_" + DonatorStatusConverterReverse(required_status)) + ")";
		return;
	}

	// api.updateEmblem({
	// 	emblem_id: id,
	// 	steamid: Game.GetLocalPlayerInfo().player_steamid,
	// }, function () {
	// 	$("#CompanionNotification").AddClass("success");
	// 	$("#CompanionNotificationLabel").text = $.Localize("#emblem_success") + " " + $.Localize("#" + name) + "!";
	// 	GameEvents.SendCustomGameEventToServer("change_emblem", {
	// 		ID: Players.GetLocalPlayer(),
	// 		unit: emblem
	// 	});
	// 	$.Schedule(6.0, function () {
	// 		$("#CompanionNotification").RemoveClass("success");
	// 		$("#CompanionNotificationLabel").text = "";
	// 		companion_changed = false;
	// 	});
	// }, function () {
	// 	$("#CompanionNotification").AddClass("failure");
	// 	$("#CompanionNotificationLabel").text = $.Localize("#companion_error");
	// 	$.Schedule(6.0, function () {
	// 		$("#CompanionNotification").RemoveClass("failure");
	// 		$("#CompanionNotificationLabel").text = "";
	// 		companion_changed = false;
	// 	});
	// });

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
		// api.updateTag({
		// 	steamid: Game.GetLocalPlayerInfo().player_steamid,
		// 	tag_name: chat.text
		// }, function () {
		// 	GameEvents.SendCustomGameEventToServer("change_ingame_tag", {
		// 		ingame_tag: chat.text
		// 	});

		// 	$("#CompanionNotification").AddClass("success");
		// 	$("#CompanionNotificationLabel").text = $.Localize("#tag_success") + " " + chat.text + "!";

		// 	$.Msg("Ingame tag update: success!")
		// 	$.Schedule(6.0, function () {
		// 		$("#CompanionNotification").RemoveClass("success");
		// 		$("#CompanionNotificationLabel").text = "";
		// 		companion_changed = false;
		// 	});

		// 	chat.text = "";
		// }, function () {
		// 	$.Msg("Ingame tag update: failure")
		// 	$("#CompanionNotification").AddClass("failure");
		// 	$("#CompanionNotificationLabel").text = $.Localize("#companion_error");
		// 	$.Schedule(6.0, function () {
		// 		$("#CompanionNotification").RemoveClass("failure");
		// 		$("#CompanionNotificationLabel").text = "";
		// 		companion_changed = false;
		// 	});
		// });
	});
}

function SetArmory(hero, slot_id, item_id, bp_name, bForceUnequip) {
	if (companion_changed === true && bForceUnequip == undefined) {
		$.Msg("SLOW DOWN BUDDY!");
		return;
	}

	if (slot_id == undefined) slot_id = "weapon";

	GameEvents.SendCustomGameEventToServer("battlepass:update_armory", {
		steamid: Game.GetLocalPlayerInfo().player_steamid,
		hero: hero,
		slot_id: slot_id,
		item_id: item_id,
		custom_game: game_type,
	});

	// function () {
	// 	$("#CompanionNotification").AddClass("success");

	// 	var text = "";

	// 	if ($("#reward_equipped_" + item_id)) {
	// 		$("#reward_equipped_" + item_id).DeleteAsync(0);
	// 		text = $.Localize("#bp_reward_unequip_success") + " " + $.Localize("#" + bp_name);
	// 	} else {
	// 		text = $.Localize("#bp_reward_equip_success") + " " + $.Localize("#" + bp_name);
	// 		SetRewardEquipped(item_id, hero);
	// 	}

	// 	$("#CompanionNotificationLabel").text = text.toLowerCase();

	// 	/*
	// 			GameEvents.SendCustomGameEventToServer("change_emblem", {
	// 				ID : Players.GetLocalPlayer(),
	// 				unit : emblem
	// 			});
	// 	*/

	// 	$.Schedule(6.0, function () {
	// 		$("#CompanionNotification").RemoveClass("success");
	// 		$("#CompanionNotificationLabel").text = "";
	// 		companion_changed = false;
	// 	});
	// }, function () {

	// 	$("#CompanionNotification").AddClass("failure");
	// 	$("#CompanionNotificationLabel").text = $.Localize("#companion_error");

	// 	$.Schedule(6.0, function () {
	// 		$("#CompanionNotification").RemoveClass("failure");
	// 		$("#CompanionNotificationLabel").text = "";
	// 		companion_changed = false;
	// 	});
	// });
}

function SetArmory_callback(item_id, hero, bp_name, bSuccess) {
	if (bSuccess == undefined) bSuccess = true;

	companion_changed = true;

	if (bSuccess == true) {
		$("#CompanionNotification").AddClass("success");
		$("#CompanionNotificationLabel").text = $.Localize("#bp_reward_equip_success") + " " + $.Localize("#" + bp_name);

		SetRewardEquipped(item_id, hero);
	} else {
		$("#CompanionNotification").AddClass("failure");
		$("#CompanionNotificationLabel").text = $.Localize("#companion_error");
	}

	$.Schedule(6.0, function () {
		$("#CompanionNotification").RemoveClass("success");
		$("#CompanionNotification").RemoveClass("failure");
		$("#CompanionNotificationLabel").text = "";
		companion_changed = false;
	});
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

function SafeToLeave() {
	$("#SafeToLeave").style.visibility = "visible";
}

function GenerateBattlepassPanel(reward_list, reward_row, bRewardsDisabled) {
	// $.Msg("GenerateBattlepassPanel: " + reward_row.id);
	const player = Players.GetLocalPlayer();
	var plyData = CustomNetTables.GetTableValue("battlepass_player", player);
	var player_avatar = $("#PlayerSteamAvatar");

	if (player_avatar)
		player_avatar.steamid = Game.GetLocalPlayerInfo(player).player_steamid;

	for (var i = 1; i <= 1000; i++) {
		// $.Msg("GenerateBattlepassPanel: " + reward_row.id + " - " + i);
		if (reward_list[i] != undefined) {
			// $.Msg("GenerateBattlepassPanel: " + reward_row.id + " - " + i + " - " + reward_list[i].name);
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

			var container_level = reward_row.FindChildTraverse("#container_level_" + bp_level);
			var reward_level_container;

			if (!container_level) {
				// $.Msg("Create reward container for level " + bp_level + " in " + reward_row.id + "")
				container_level = $.CreatePanel("Panel", reward_row, "container_level_" + bp_level);
				container_level.AddClass("ContainerLevel");

				reward_level_container = $.CreatePanel("Panel", container_level, "reward_container_level_" + bp_level);
				reward_level_container.AddClass("RewardContainerLevel");

				var reward_label_container = $.CreatePanel("Panel", container_level, "");
				reward_label_container.AddClass("BattlepassRewardLabelContainer");

				var reward_label = $.CreatePanel("Label", reward_label_container, "");
				reward_label.AddClass("BattlepassRewardLabel");
				reward_label.text = $.Localize("#battlepass_level") + bp_level;
				//				reward_label.AddClass(bp_rarity + "_text");
			} else {
				reward_level_container = container_level.FindChildTraverse("#reward_container_level_" + bp_level);
			}

			var reward = $.CreatePanel("Button", reward_level_container, "reward_button_" + bp_item_id, {
				class: "RewardButton HideStatusLabel SingleItem Static ActivateBehavior_Detail Owned StyleUnlocked ShuffleDisabled ItemSlot_" + bp_type + " Season_PlusSubscription Unavailable ItemRarity_" + bp_rarity + "",
			});
			reward.BLoadLayout("file://{resources}/layout/custom_game/frostrose_battlepass/dota_files/ui_econ_item_animated.xml", false, false)
			reward.FindChildTraverse("EconItemName").SetDialogVariable("ItemName", $.Localize("#" + bp_name));
			reward.FindChildTraverse("EconItemSlotName").SetDialogVariable("SlotName", $.Localize("#battlepass_" + bp_type));
			reward.FindChildTraverse("EconItemIcon").style.backgroundImage = 'url("s2r://panorama/images/' + bp_image + '.png")';
			reward.FindChildTraverse("EconItemIcon").style.backgroundSize = "100% 100%";

			if (reward_row.id == "BattlepassRewardRowPremiumContainer") {
				reward.AddClass("Seasonal");
			}

			// reward.BLoadLayoutSnippet('BattlePassReward');
			// reward.FindChildTraverse("BattlepassRewardImage").style.backgroundImage = 'url("s2r://panorama/images/' + bp_image + '.png")';
			// reward.FindChildTraverse("BattlepassRewardImage").AddClass(bp_rarity + "_border");
			// reward.hero_type = bp_hero;


			/*
						if (bp_hero != undefined && bp_hero.indexOf("npc_dota_hero_") !== -1) {
							var reward_hero_icon = $.CreatePanel("Panel", reward, "");
							reward_hero_icon.style.backgroundImage = 'url("file://{images}/heroes/icons/' + bp_hero + '.png")';
							reward_hero_icon.AddClass("BattlepassRewardHeroIcon");
						}
			*/

			// if (plyData != null && bp_item_unreleased == undefined || bRewardsDisabled & bRewardsDisabled == true) {
			// 	// Disable tinker immortal for now until fixed
			// 	if (bp_item_id != "105" && bp_item_id != "113" && bp_item_id != "114" && bp_item_id != "115" && bp_item_id != "116" && bp_item_id != "118" && bp_item_id != "119" && bp_item_id != "120" && bp_item_id != "121") {
			// 		if (bp_level <= plyData.Lvl) {
			// 			reward.FindChildTraverse("BattlepassRewardTitle").AddClass("BattlepassRewardLabelUnlocked");

			// 			var reward_panel_unlocked = $.CreatePanel("Panel", reward, "");
			// 			reward_panel_unlocked.AddClass("BattlepassRewardPanelUnlocked");

			// 			if (bp_type == "bundle" || bp_type == "wearable" || bp_type == "taunt") {
			// 				var hero_tooltip = $.Localize("#" + bp_hero);
			// 				reward.FindChildTraverse("BattlepassRewardTitle").text = hero_tooltip + ": " + $.Localize("#" + bp_name);
			// 			} else
			// 				reward.FindChildTraverse("BattlepassRewardTitle").text = $.Localize("#battlepass_" + bp_type) + ": " + $.Localize("#" + bp_name);

			// 			var armory = CustomNetTables.GetTableValue("battlepass_rewards", "rewards_" + player);

			// 			if (armory) {
			// 				var j = 1;

			// 				while (armory[j] != undefined) {
			// 					var item = armory[j];

			// 					if (item && item.item_id == bp_item_id) {
			// 						// $.Msg(item)
			// 						SetRewardEquipped(bp_item_id, bp_hero);

			// 						// rough fix to unequip rewards if somehow a player equip higher tiers rewards
			// 						if (plyData.Lvl < bp_level) {
			// 							SetArmory(bp_hero, slot_id, bp_item_id, bp_name, false)
			// 						}

			// 						break;
			// 					}

			// 					j++;
			// 				}
			// 			}

			// 			var event = function (bp_hero, bp_slot_id, bp_item_id, bp_name) {
			// 				return function () {
			// 					SetArmory(bp_hero, bp_slot_id, bp_item_id, bp_name);
			// 				}
			// 			};

			// 			reward.SetPanelEvent("onactivate", event(bp_hero, bp_slot_id, bp_item_id, bp_name));
			// 		} else {
			// 			reward.AddClass("BattlepassRewardIcon_locked")
			// 			reward.FindChildTraverse("BattlepassRewardTitle").AddClass("BattlepassRewardLabelLocked");
			// 			reward.FindChildTraverse("BattlepassRewardTitle").text = $.Localize("#battlepass_" + bp_type) + ": " + $.Localize("#" + bp_name);
			// 			reward.FindChildTraverse("BattlepassRewardImageLabel").text = $.Localize("#battlepass_reward_locked");
			// 		}
			// 	} else {
			// 		reward.AddClass("BattlepassRewardIcon_unreleased")
			// 		reward.FindChildTraverse("BattlepassRewardTitle").AddClass("BattlepassRewardLabelUnreleased");
			// 		reward.FindChildTraverse("BattlepassRewardTitle").text = $.Localize("#battlepass_" + bp_type) + ": " + $.Localize("#" + bp_name);
			// 		reward.FindChildTraverse("BattlepassRewardImageLabel").text = $.Localize("#battlepass_reward_unreleased");

			// 	}
			// } else {
			// 	reward.AddClass("BattlepassRewardIcon_locked")
			// 	reward.FindChildTraverse("BattlepassRewardTitle").AddClass("BattlepassRewardLabelLocked");
			// 	reward.FindChildTraverse("BattlepassRewardTitle").text = $.Localize("#battlepass_" + bp_type) + ": " + $.Localize("#" + bp_name);
			// 	reward.FindChildTraverse("BattlepassRewardImageLabel").text = $.Localize("#battlepass_reward_locked");
			// }

			// if (reward.FindChildTraverse("BattlepassRewardRarity")) {
			// 	reward.FindChildTraverse("BattlepassRewardRarity").text = bp_rarity;
			// 	reward.FindChildTraverse("BattlepassRewardRarity").AddClass(bp_rarity + "_text");
			// }
		} else {
			break;
		}
	}
}

function GenerateArmoryPanel(reward_list, premium_reward_list, bRewardsDisabled) {
	const parent = $("#BattlepassArmoryRow");
	let reward_row = $("#BattlepassArmoryRowContainer0");
	// $.Msg("GenerateArmoryPanel: " + reward_row.id);
	const player = Players.GetLocalPlayer();
	var plyData = CustomNetTables.GetTableValue("battlepass_player", player);
	if (plyData == undefined) return;
	var player_avatar = $("#PlayerSteamAvatar");

	// for (var i in plyData) {
	// 	$.Msg(i + " - " + plyData[i]);
	// }

	if (player_avatar)
		player_avatar.steamid = Game.GetLocalPlayerInfo(player).player_steamid;

	let reward_line_count = 0;
	let reward_line_counter = 0;
	let reward_line_max = 4;

	for (var i = 1; i <= plyData.Lvl; i++) {
		if (reward_line_counter == reward_line_max) {
			reward_line_counter = 0;
			reward_line_count++;
			reward_row = $.CreatePanel("Panel", parent, "BattlepassArmoryRowContainer" + reward_line_count, {
				class: "BattlepassArmoryRowContainer BattlepassRow"
			});
		}

		reward_line_counter++;

		if (reward_list[i] != undefined) {
			$.Msg("GenerateArmoryPanel: " + reward_row.id + " - " + i + " - " + reward_list[i].name);
			var bp_image = reward_list[i].image;
			var bp_level = reward_list[i].level;
			var bp_name = reward_list[i].name;
			var bp_rarity = reward_list[i].rarity;
			var bp_type = reward_list[i].type;
			var bp_item_id = reward_list[i].item_id;
			var bp_slot_id = reward_list[i].slot_id;
			var bp_hero = reward_list[i].hero;
			var bp_item_unreleased = reward_list[i].item_unreleased;

			var container_level = reward_row.FindChildTraverse("#container_level_" + bp_level);
			var reward_level_container;

			if (!container_level) {
				// $.Msg("Create reward container for level " + bp_level + " in " + reward_row.id + "")
				container_level = $.CreatePanel("Panel", reward_row, "container_level_" + bp_level);
				container_level.AddClass("ContainerLevel");

				reward_level_container = $.CreatePanel("Panel", container_level, "reward_container_level_" + bp_level);
				reward_level_container.AddClass("RewardContainerLevel");

				var reward_label_container = $.CreatePanel("Panel", container_level, "");
				reward_label_container.AddClass("BattlepassRewardLabelContainer");

				var reward_label = $.CreatePanel("Label", reward_label_container, "");
				reward_label.AddClass("BattlepassRewardLabel");
				reward_label.text = $.Localize("#battlepass_level") + bp_level;
				//				reward_label.AddClass(bp_rarity + "_text");
			} else {
				reward_level_container = container_level.FindChildTraverse("#reward_container_level_" + bp_level);
			}

			var reward = $.CreatePanel("Button", reward_level_container, "reward_button_" + bp_item_id);
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
							var hero_tooltip = $.Localize("#" + bp_hero);
							reward.FindChildTraverse("BattlepassRewardTitle").text = hero_tooltip + ": " + $.Localize("#" + bp_name);
						} else
							reward.FindChildTraverse("BattlepassRewardTitle").text = $.Localize("#battlepass_" + bp_type) + ": " + $.Localize("#" + bp_name);

						var armory = CustomNetTables.GetTableValue("battlepass_rewards", "rewards_" + player);

						if (armory) {
							var j = 1;

							while (armory[j] != undefined) {
								var item = armory[j];

								if (item && item.item_id == bp_item_id) {
									// $.Msg(item)
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
						reward.FindChildTraverse("BattlepassRewardTitle").text = $.Localize("#battlepass_" + bp_type) + ": " + $.Localize("#" + bp_name);
						reward.FindChildTraverse("BattlepassRewardImageLabel").text = $.Localize("#battlepass_reward_locked");
					}
				} else {
					reward.AddClass("BattlepassRewardIcon_unreleased")
					reward.FindChildTraverse("BattlepassRewardTitle").AddClass("BattlepassRewardLabelUnreleased");
					reward.FindChildTraverse("BattlepassRewardTitle").text = $.Localize("#battlepass_" + bp_type) + ": " + $.Localize("#" + bp_name);
					reward.FindChildTraverse("BattlepassRewardImageLabel").text = $.Localize("#battlepass_reward_unreleased");

				}
			} else {
				reward.AddClass("BattlepassRewardIcon_locked")
				reward.FindChildTraverse("BattlepassRewardTitle").AddClass("BattlepassRewardLabelLocked");
				reward.FindChildTraverse("BattlepassRewardTitle").text = $.Localize("#battlepass_" + bp_type) + ": " + $.Localize("#" + bp_name);
				reward.FindChildTraverse("BattlepassRewardImageLabel").text = $.Localize("#battlepass_reward_locked");
			}

			if (reward.FindChildTraverse("BattlepassRewardRarity")) {
				reward.FindChildTraverse("BattlepassRewardRarity").text = bp_rarity;
				reward.FindChildTraverse("BattlepassRewardRarity").AddClass(bp_rarity + "_text");
			}
		} else {
			break;
		}

		if (reward_line_counter == reward_line_max) {
			reward_line_counter = 0;
			reward_line_count++;
			reward_row = $.CreatePanel("Panel", parent, "BattlepassArmoryRowContainer" + reward_line_count);
			reward_row.AddClass("BattlepassRow");
		}

		reward_line_counter++;

		// Premium rewards
		if (premium_reward_list[i] != undefined) {
			$.Msg("GenerateArmoryPanel: " + reward_row.id + " - " + i + " - " + premium_reward_list[i].name);
			var bp_image = premium_reward_list[i].image;
			var bp_level = premium_reward_list[i].level;
			var bp_name = premium_reward_list[i].name;
			var bp_rarity = premium_reward_list[i].rarity;
			var bp_type = premium_reward_list[i].type;
			var bp_item_id = premium_reward_list[i].item_id;
			var bp_slot_id = premium_reward_list[i].slot_id;
			var bp_hero = premium_reward_list[i].hero;
			var bp_item_unreleased = premium_reward_list[i].item_unreleased;

			var container_level = reward_row.FindChildTraverse("#container_level_" + bp_level);
			var reward_level_container;

			if (!container_level) {
				// $.Msg("Create reward container for level " + bp_level + " in " + reward_row.id + "")
				container_level = $.CreatePanel("Panel", reward_row, "container_level_" + bp_level);
				container_level.AddClass("ContainerLevel");

				reward_level_container = $.CreatePanel("Panel", container_level, "reward_container_level_" + bp_level);
				reward_level_container.AddClass("RewardContainerLevel");

				var reward_label_container = $.CreatePanel("Panel", container_level, "");
				reward_label_container.AddClass("BattlepassRewardLabelContainer");

				var reward_label = $.CreatePanel("Label", reward_label_container, "");
				reward_label.AddClass("BattlepassRewardLabel");
				reward_label.text = $.Localize("#battlepass_level") + bp_level;
				//				reward_label.AddClass(bp_rarity + "_text");
			} else {
				reward_level_container = container_level.FindChildTraverse("#reward_container_level_" + bp_level);
			}

			var reward = $.CreatePanel("Button", reward_level_container, "reward_button_" + bp_item_id);
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
							var hero_tooltip = $.Localize("#" + bp_hero);
							reward.FindChildTraverse("BattlepassRewardTitle").text = hero_tooltip + ": " + $.Localize("#" + bp_name);
						} else
							reward.FindChildTraverse("BattlepassRewardTitle").text = $.Localize("#battlepass_" + bp_type) + ": " + $.Localize("#" + bp_name);

						var armory = CustomNetTables.GetTableValue("battlepass_rewards", "rewards_" + player);

						if (armory) {
							var j = 1;

							while (armory[j] != undefined) {
								var item = armory[j];

								if (item && item.item_id == bp_item_id) {
									// $.Msg(item)
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
						reward.FindChildTraverse("BattlepassRewardTitle").text = $.Localize("#battlepass_" + bp_type) + ": " + $.Localize("#" + bp_name);
						reward.FindChildTraverse("BattlepassRewardImageLabel").text = $.Localize("#battlepass_reward_locked");
					}
				} else {
					reward.AddClass("BattlepassRewardIcon_unreleased")
					reward.FindChildTraverse("BattlepassRewardTitle").AddClass("BattlepassRewardLabelUnreleased");
					reward.FindChildTraverse("BattlepassRewardTitle").text = $.Localize("#battlepass_" + bp_type) + ": " + $.Localize("#" + bp_name);
					reward.FindChildTraverse("BattlepassRewardImageLabel").text = $.Localize("#battlepass_reward_unreleased");

				}
			} else {
				reward.AddClass("BattlepassRewardIcon_locked")
				reward.FindChildTraverse("BattlepassRewardTitle").AddClass("BattlepassRewardLabelLocked");
				reward.FindChildTraverse("BattlepassRewardTitle").text = $.Localize("#battlepass_" + bp_type) + ": " + $.Localize("#" + bp_name);
				reward.FindChildTraverse("BattlepassRewardImageLabel").text = $.Localize("#battlepass_reward_locked");
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

	var donator_row = $.CreatePanel("Panel", $('#' + panel + 'TableWrapper'), "CompanionRow" + class_option_count + "_" + player);
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

		// todo: finish point shop
		companion.AddClass("CompanionLocked");

		var companionpreview = $.CreatePanel("Button", companion, "CompanionPreview_" + i);
		companionpreview.style.width = "132px";
		companionpreview.style.height = "135px";

		// $.Msg("Create scene panel for unit: " + companion_unit[i]);
		$.CreatePanel('DOTAScenePanel', companionpreview, "", {
			class: `companion_scene`,
			particleonly: "false",
			unit: companion_unit[i],
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

	// api.updateIngameTag({
	// 	steamid: Game.GetLocalPlayerInfo().player_steamid,
	// 	toggle_tag: tag
	// }, function () {
	// 	GameEvents.SendCustomGameEventToServer("toggle_ingame_tag", {
	// 		tag: tag
	// 	});
	// 	//		$.Msg("Ingame tag update: success!")
	// 	//		$.Schedule(6.0, function() {
	// 	//			$("#CompanionNotification").RemoveClass("success");
	// 	//			companion_changed = false;
	// 	//		});
	// }, function () {
	// 	$("#IngameTagCheckBox").checked = tag;
	// 	//		$.Msg("Ingame tag update: failure")
	// 	//		$("#CompanionNotification").AddClass("failure");
	// 	//		$("#CompanionNotificationLabel").text = $.Localize("#companion_error");
	// 	//		$.Schedule(6.0, function() {
	// 	//			$("#CompanionNotification").RemoveClass("failure");
	// 	//			companion_changed = false;
	// 	//		});
	// });
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

	// api.updateBPRewards({
	// 	steamid: Game.GetLocalPlayerInfo().player_steamid,
	// 	bp_rewards: toggle_rewards
	// }, function () {
	// 	GameEvents.SendCustomGameEventToServer("change_battlepass_rewards", {
	// 		ID: Players.GetLocalPlayer(),
	// 		bp_rewards: toggle_rewards
	// 	});
	// 	RefreshBattlepass(toggle_rewards);
	// 	//		$.Msg("BP rewards update: success!")
	// 	//		$.Schedule(6.0, function() {
	// 	//			$("#CompanionNotification").RemoveClass("success");
	// 	//			companion_changed = false;
	// 	//		});
	// }, function () {
	// 	//		$.Msg("BP rewards update: failure")
	// 	//		$("#CompanionNotification").AddClass("failure");
	// 	//		$("#CompanionNotificationLabel").text = $.Localize("#companion_error");
	// 	//		$.Schedule(6.0, function() {
	// 	//			$("#CompanionNotification").RemoveClass("failure");
	// 	//			companion_changed = false;
	// 	//		});
	// });
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

	// api.updatePlayerXP({
	// 	steamid: Game.GetLocalPlayerInfo().player_steamid,
	// 	player_xp: toggle
	// }, function () {
	// 	GameEvents.SendCustomGameEventToServer("change_player_xp", {
	// 		ID: Players.GetLocalPlayer(),
	// 		player_xp: toggle
	// 	});
	// 	//		$.Msg("Player XP update: success!")
	// 	//		$.Schedule(6.0, function() {
	// 	//			$("#CompanionNotification").RemoveClass("success");
	// 	//			companion_changed = false;
	// 	//		});
	// }, function () {
	// 	//		$.Msg("Player XP update: failure")
	// 	//		$("#CompanionNotification").AddClass("failure");
	// 	//		$("#CompanionNotificationLabel").text = $.Localize("#companion_error");
	// 	//		$.Schedule(6.0, function() {
	// 	//			$("#CompanionNotification").RemoveClass("failure");
	// 	//			companion_changed = false;
	// 	//		});
	// });
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

	// api.updateWinrate({
	// 	steamid: Game.GetLocalPlayerInfo().player_steamid,
	// 	winrate: toggle
	// }, function () {
	// 	GameEvents.SendCustomGameEventToServer("change_winrate", {
	// 		ID: Players.GetLocalPlayer(),
	// 		player_xp: toggle
	// 	});
	// }, function () {
	// 	$.Msg("Winrate update fail!")
	// });
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
	var ids = {
		xpRank: "ImbaXPRank",
		xp: "ImbaXP",
		xpEarned: "ImbaXPEarned",
		level: "ImbaLvl",
		progress_bar: "XPProgressBar"
	};

	if (Game.IsInToolsMode()) {
		ImbaXP_Panel.RemoveAndDeleteChildren();
	}

	ImbaXP_Panel.BLoadLayoutSnippet("LocalPlayerProfile");

	// xp shown fix (temporary?)
	var player_info = CustomNetTables.GetTableValue("battlepass_player", playerId.toString())

	// const current_xp = player_info.XP;
	// const current_max_xp = player_info.MaxXP;
	// const level = player_info.Lvl;

	let current_xp = player_info.supporter_pass_xp || player_info.XP || 0;
	const current_max_xp = 1000;
	let level = 1;

	while (current_xp >= current_max_xp) {
		current_xp -= 1000;
		level++;
	}

	if (!player_info || player_info.player_xp == 0) {
		_ScoreboardUpdater_SetTextSafe(playerPanel, ids.xpRank, "N/A");
		_ScoreboardUpdater_SetTextSafe(playerPanel, ids.xp, "N/A");
		_ScoreboardUpdater_SetTextSafe(playerPanel, ids.level, "N/A");
		_ScoreboardUpdater_SetValueSafe(playerPanel, ids.progress_bar, 0);
		playerPanel.FindChildTraverse(ids.xpRank).style.color = "#FFFFFF";
	} else if (player_info.player_xp == 1) {
		_ScoreboardUpdater_SetTextSafe(playerPanel, ids.xpRank, player_info.title);
		_ScoreboardUpdater_SetTextSafe(playerPanel, ids.xp, current_xp + "/" + current_max_xp);
		_ScoreboardUpdater_SetTextSafe(playerPanel, ids.level, level + ' - ');
		_ScoreboardUpdater_SetValueSafe(playerPanel, ids.progress_bar, current_xp / current_max_xp);
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

	MiniTabButtonContainer.GetChild(0).AddClass('active');
	MiniTabButtonContainer2.GetChild(0).AddClass('active');
	MiniTabButtonContainer3.GetChild(0).AddClass('active');
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
		$.DispatchEvent("UIShowTextTooltip", BattlepassButton, $.Localize("#battlepass"));
	})

	BattlepassButton.SetPanelEvent("onmouseout", function () {
		$.DispatchEvent("UIHideTextTooltip", BattlepassButton);
	})
	BattlepassButton.SetParent(Parent);
}

function OpenSupporterPass() {
	const bp_player = CustomNetTables.GetTableValue("battlepass_player", Players.GetLocalPlayer());

	if (bp_player) {
		const supporter_url = bp_player.supporter_url;

		if (supporter_url) {
			$.DispatchEvent('ExternalBrowserGoToURL', supporter_url);
		} else {
			$.Msg("Supporter Pass URL not available");
		}
	} else {
		$.Msg("Battlepass player info not available");
	}
}

function PlayerQuests() {
	const parent = $("#CurrentSeasonQuestsList");
	const bp_player = CustomNetTables.GetTableValue("battlepass_player", Players.GetLocalPlayer());
	
	if (Game.IsInToolsMode()) {
		parent.RemoveAndDeleteChildren();
	}

	// $.Msg(bp_player.achievements);
	if (bp_player && bp_player.achievements) {

		let remaining_points = 0;
		let remaining_quests = 0;
		let quest_counter = 1;

		while (bp_player.achievements[quest_counter.toString()]) {
			const achievement = bp_player.achievements[quest_counter.toString()];
			remaining_points += achievement.rewards["1"].amount;

			const quest = $.CreatePanel("Panel", parent, "");
			quest.BLoadLayoutSnippet("PlusQuest");
			quest.FindChildTraverse("AchievementName").text = achievement.name;
			quest.FindChildTraverse("RewardAmount").GetChild(1).text = achievement.rewards["1"].amount;

			if (achievement.completed) {
				quest.AddClass("AlreadyClaimed");
				remaining_quests++;
			}

			quest_counter++;
		}

		if (quest_counter > 1) {
			$.GetContextPanel().FindChildrenWithClassTraverse("AchievementTabContentsHeaderRight")[0].AddClass("Visible");
			// $.GetContextPanel().FindChildrenWithClassTraverse("SeasonAchievementsTitle")[0].text = "Win up to " + remaining_points + " experience during " + bp_name + ".";
			$.GetContextPanel().FindChildrenWithClassTraverse("SeasonAchievementsRewards")[0].SetDialogVariableInt("shards_available", remaining_points);
			$.GetContextPanel().FindChildrenWithClassTraverse("SeasonAchievementsProgress")[0].SetDialogVariableInt("quests_completed", remaining_quests);	
			$.GetContextPanel().FindChildrenWithClassTraverse("SeasonAchievementsProgress")[0].SetDialogVariableInt("quests_count", quest_counter - 1);
			// if (Game.IsInToolsMode()) {
			// 	$("#LeaderboardExperienceTableWrapper").RemoveAndDeleteChildren();
			// }
		}
	}
}

(function () {
	$.Schedule(2.0, CreateBattlepassButton);

	// prevent running an api call everytime this file is edited
	// if (!Game.IsInToolsMode()) {
	// 	var args = {
	// 		steamid: Game.GetLocalPlayerInfo().player_steamid,
	// 		language: $.Localize("#lang"),
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

	GameEvents.Subscribe("safe_to_leave", SafeToLeave);
})();
