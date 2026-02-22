"use strict";

var game_options;
var secret_key = {};
var local_votes = {};
var local_vote_confirmed = {};
var player_loading_rows = {};
var player_loading_section_rows = {};
var player_loading_order_signature = "";
var selected_profile_player_id = -1;
var profile_position_cache = {};
var profile_position_pending = {};
var profile_position_retry_at = {};
var profile_modal_transition_token = 0;
var profile_modal_fade_duration = 0.18;

var mmr_rank_to_medals = {
	Herald: 1,
	Guardian: 2,
	Crusader: 3,
	Archon: 4,
	Legend: 5,
	Ancient: 6,
	Divine: 7,
	Immortal: 8,
};

var api = {
	base: "https://api.frostrose-studio.com/",
	urls: {
		loadingScreenMessage: "imba/loading-screen-info",
		playerPosition: "imba/trackme",
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
	getPlayerPosition: function (data, success_callback, error_callback) {
		$.AsyncWebRequest(api.base + api.urls.playerPosition, {
			type: "GET",
			data: data,
			dataType: "json",
			timeout: 5000,
			headers: { 'X-Dota-Server-Key': secret_key },
			success: function (obj) {
				if (obj.error) {
					$.Msg("Error loading player position");
					error_callback();
				} else {
					success_callback(obj.data);
				}
			},
			error: function (err) {
				$.Msg("Error loading player position " + JSON.stringify(err));
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
		"difficulty": 5,
	},
	"PW": {
		"gamemode": 4,
	},
	"FB": {
		"gamemode": 3,
	},
};

var vote_fallbacks = {};

var link_targets = "";

var connection_state = {
	UNKNOWN: (typeof DOTAConnectionState_t !== "undefined" && DOTAConnectionState_t.DOTA_CONNECTION_STATE_UNKNOWN !== undefined) ? DOTAConnectionState_t.DOTA_CONNECTION_STATE_UNKNOWN : 0,
	NOT_YET_CONNECTED: (typeof DOTAConnectionState_t !== "undefined" && DOTAConnectionState_t.DOTA_CONNECTION_STATE_NOT_YET_CONNECTED !== undefined) ? DOTAConnectionState_t.DOTA_CONNECTION_STATE_NOT_YET_CONNECTED : 1,
	CONNECTED: (typeof DOTAConnectionState_t !== "undefined" && DOTAConnectionState_t.DOTA_CONNECTION_STATE_CONNECTED !== undefined) ? DOTAConnectionState_t.DOTA_CONNECTION_STATE_CONNECTED : 2,
	DISCONNECTED: (typeof DOTAConnectionState_t !== "undefined" && DOTAConnectionState_t.DOTA_CONNECTION_STATE_DISCONNECTED !== undefined) ? DOTAConnectionState_t.DOTA_CONNECTION_STATE_DISCONNECTED : 3,
	ABANDONED: (typeof DOTAConnectionState_t !== "undefined" && DOTAConnectionState_t.DOTA_CONNECTION_STATE_ABANDONED !== undefined) ? DOTAConnectionState_t.DOTA_CONNECTION_STATE_ABANDONED : 4,
	LOADING: (typeof DOTAConnectionState_t !== "undefined" && DOTAConnectionState_t.DOTA_CONNECTION_STATE_LOADING !== undefined) ? DOTAConnectionState_t.DOTA_CONNECTION_STATE_LOADING : 5,
	FAILED: (typeof DOTAConnectionState_t !== "undefined" && DOTAConnectionState_t.DOTA_CONNECTION_STATE_FAILED !== undefined) ? DOTAConnectionState_t.DOTA_CONNECTION_STATE_FAILED : 6,
};

function info_already_available() {
	return Game.GetMapInfo().map_name != "";
}

function isInt(n) {
	return n % 1 === 0;
}

function LocalizeWithFallback(token) {
	var localized = $.Localize(token);

	if (localized && localized !== token) {
		return localized;
	}

	var clean_token = token;
	if (token && token[0] == "#") {
		clean_token = token.substring(1);
	}

	if (vote_fallbacks[clean_token]) {
		return vote_fallbacks[clean_token];
	}

	return clean_token;
}

function L(token) {
	if (!token) {
		return "";
	}

	if (token[0] != "#") {
		token = "#" + token;
	}

	return LocalizeWithFallback(token);
}

function LocalizeTemplate(token, values) {
	var localized = L(token);

	if (!values) {
		return localized;
	}

	for (var key in values) {
		localized = localized.replace(new RegExp("\\{" + key + "\\}", "g"), values[key]);
	}

	return localized;
}

function LoadingScreenDebug(args) {
	$.Msg(args);
	view.text.text = view.text.text + ". \n\n" + args.text;
}

function GetCurrentTime() {
	if (Game.GetGameTime) {
		return Game.GetGameTime();
	}

	return 0;
}

function GetLocalPlayerIDSafe() {
	var local_player_id = Game.GetLocalPlayerID();

	if (local_player_id === undefined || local_player_id === null || local_player_id < 0) {
		return -1;
	}

	return local_player_id;
}

function GetSelectedProfilePlayerID() {
	if (selected_profile_player_id !== undefined && selected_profile_player_id !== null && selected_profile_player_id >= 0) {
		return selected_profile_player_id;
	}

	var local_player_id = GetLocalPlayerIDSafe();
	selected_profile_player_id = local_player_id;
	return selected_profile_player_id;
}

function SetSelectedProfilePlayer(player_id, open_modal) {
	if (player_id === undefined || player_id === null || player_id < 0) {
		player_id = GetLocalPlayerIDSafe();
	}

	selected_profile_player_id = player_id;
	UpdateProfilePanels();
	UpdatePlayerLoadingSidebar();
	RequestProfilePositionForSelected();

	if (open_modal) {
		ToggleProfileModal(true);
	}
}

function AddDecimalStrings(a, b) {
	var i = a.length - 1;
	var j = b.length - 1;
	var carry = 0;
	var out = "";

	while (i >= 0 || j >= 0 || carry > 0) {
		var da = i >= 0 ? (a.charCodeAt(i) - 48) : 0;
		var db = j >= 0 ? (b.charCodeAt(j) - 48) : 0;
		var sum = da + db + carry;

		out = (sum % 10).toString() + out;
		carry = Math.floor(sum / 10);
		i = i - 1;
		j = j - 1;
	}

	return out.replace(/^0+/, "") || "0";
}

function MultiplyDecimalStringBySmall(value, multiplier) {
	var i = value.length - 1;
	var carry = 0;
	var out = "";

	while (i >= 0 || carry > 0) {
		var dv = i >= 0 ? (value.charCodeAt(i) - 48) : 0;
		var prod = dv * multiplier + carry;

		out = (prod % 10).toString() + out;
		carry = Math.floor(prod / 10);
		i = i - 1;
	}

	return out.replace(/^0+/, "") || "0";
}

function AccountIDToSteamID64(account_id) {
	if (!account_id || !/^\d+$/.test(account_id)) {
		return "";
	}

	if (account_id == "0") {
		return "";
	}

	return AddDecimalStrings("76561197960265728", account_id);
}

function NormalizeSteamID64(raw_steam_id) {
	if (raw_steam_id === undefined || raw_steam_id === null) {
		return "";
	}

	var raw = raw_steam_id.toString().trim();
	if (raw.length <= 0 || raw == "0") {
		return "";
	}

	var bracket_match = raw.match(/\[U:1:(\d+)\]/i);
	if (bracket_match) {
		return AccountIDToSteamID64(bracket_match[1]);
	}

	var steam2_match = raw.match(/^STEAM_[0-5]:([0-1]):(\d+)$/i);
	if (steam2_match) {
		var y = steam2_match[2];
		var x = steam2_match[1];
		var account_id = AddDecimalStrings(MultiplyDecimalStringBySmall(y, 2), x);
		return AccountIDToSteamID64(account_id);
	}

	if (/^\d+$/.test(raw)) {
		if (raw.length >= 17 && raw.substring(0, 7) == "7656119") {
			return raw;
		}

		return AccountIDToSteamID64(raw);
	}

	return "";
}

function GetSteamIDFromPlayerInfo(player_info) {
	if (!player_info || player_info.player_steamid === undefined || player_info.player_steamid === null) {
		return "";
	}

	return NormalizeSteamID64(player_info.player_steamid);
}

function HasServerKey() {
	return typeof secret_key === "string" && secret_key.length > 0;
}

function GetCustomSetupStatus() {
	return CustomNetTables.GetTableValue("game_options", "custom_setup") || {};
}

function IsCustomSetupStatusActive(setup_status) {
	return setup_status && (setup_status.active === true || setup_status.active === 1 || setup_status.active === "1");
}

function IsPlayerMarkedReady(setup_status, player_id) {
	if (!setup_status || !setup_status.ready_players) {
		return false;
	}

	var ready_value = setup_status.ready_players[player_id];
	if (ready_value === undefined || ready_value === null) {
		ready_value = setup_status.ready_players[player_id.toString()];
	}

	return ready_value === true || ready_value === 1 || ready_value === "1";
}

function SafeSetText(panel_id, value) {
	var panel = $("#" + panel_id);

	if (panel) {
		panel.text = value;
	}
}

function IsTruthy(value) {
	return value === true || value === 1 || value === "1";
}

function ToNumber(value, fallback) {
	var parsed = parseFloat(value);

	if (isNaN(parsed)) {
		return fallback;
	}

	return parsed;
}

function Clamp01(value) {
	if (value < 0) {
		return 0;
	}

	if (value > 1) {
		return 1;
	}

	return value;
}

function FormatPercentValue(value) {
	if (value === undefined || value === null || value === false || value === "") {
		return L("loading_screen_na");
	}

	if (typeof value === "string" && value.indexOf("%") >= 0) {
		return value;
	}

	var numeric = ToNumber(value, NaN);
	if (isNaN(numeric)) {
		return value.toString();
	}

	if (numeric >= 0 && numeric <= 1) {
		numeric = numeric * 100;
	}

	return numeric.toFixed(1) + "%";
}

function FormatIntegerValue(value) {
	var numeric = ToNumber(value, NaN);

	if (isNaN(numeric)) {
		return L("loading_screen_na");
	}

	return Math.floor(numeric).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

function GetVisibilityStateText(value) {
	return IsTruthy(value) ? L("loading_screen_visible") : L("loading_screen_hidden");
}

function GetDonatorLevelText(level) {
	var normalized_level = Math.floor(ToNumber(level, 0));

	if (normalized_level <= 0) {
		return L("loading_screen_none");
	}

	var donator_token = "#donator_label_" + normalized_level;
	var localized_donator_label = $.Localize(donator_token);

	if (localized_donator_label && localized_donator_label != donator_token) {
		return localized_donator_label;
	}

	return LocalizeTemplate("loading_screen_donator_tier", { tier: normalized_level.toString() });
}

function ParseRankTitle(raw_title) {
	var result = {
		rank_name: "",
		stars: "_empty",
	};

	if (!raw_title) {
		return result;
	}

	var full_title = raw_title.toString().trim();
	if (full_title.length <= 0) {
		return result;
	}

	var tokens = full_title.split(" ");
	var last_token = tokens[tokens.length - 1];

	if (/^[1-5]$/.test(last_token)) {
		result.stars = last_token;
		tokens.pop();
	}

	result.rank_name = tokens.join(" ");
	return result;
}

function SetRankMedal(panel_tier_id, panel_pips_id, raw_title) {
	var tier_panel = $("#" + panel_tier_id);
	var pips_panel = $("#" + panel_pips_id);

	if (!tier_panel || !pips_panel) {
		return;
	}

	var parsed_rank = ParseRankTitle(raw_title);
	var medal_index = mmr_rank_to_medals[parsed_rank.rank_name];

	if (!medal_index) {
		tier_panel.style.backgroundImage = "none";
		pips_panel.style.backgroundImage = "none";
		return;
	}

	tier_panel.style.backgroundImage = 'url("s2r://panorama/images/rank_tier_icons/rank' + medal_index + '_psd.vtex")';
	pips_panel.style.backgroundImage = 'url("s2r://panorama/images/rank_tier_icons/pip' + parsed_rank.stars + '_psd.vtex")';
}

function ExtractProfilePosition(data, steam_id) {
	if (data === undefined || data === null) {
		return null;
	}

	if (typeof data !== "object") {
		return null;
	}

	if (data.position !== undefined) {
		return data.position;
	}

	if (data.rank !== undefined) {
		return data.rank;
	}

	if (data.leaderboard_position !== undefined) {
		return data.leaderboard_position;
	}

	if (data instanceof Array) {
		for (var i = 0; i < data.length; i++) {
			var child = data[i];

			if (!child || typeof child !== "object") {
				continue;
			}

			var child_steam_id = child.steamid || child.username || child.player_steamid || child.id;
			var child_rank = child.position || child.rank || child.leaderboard_position;

			if (steam_id && child_steam_id && child_steam_id.toString() == steam_id.toString() && child_rank !== undefined) {
				return child_rank;
			}

			var fallback_rank = ExtractProfilePosition(child, steam_id);
			if (fallback_rank !== null) {
				return fallback_rank;
			}
		}

		return null;
	}

	if (data.players !== undefined) {
		var players_rank = ExtractProfilePosition(data.players, steam_id);
		if (players_rank !== null) {
			return players_rank;
		}
	}

	if (data.data !== undefined) {
		var nested_rank = ExtractProfilePosition(data.data, steam_id);
		if (nested_rank !== null) {
			return nested_rank;
		}
	}

	for (var key in data) {
		if (key == "players" || key == "data") {
			continue;
		}

		var deeper_rank = ExtractProfilePosition(data[key], steam_id);
		if (deeper_rank !== null) {
			return deeper_rank;
		}
	}

	return null;
}

function RequestProfilePositionForSteam(steam_id) {
	steam_id = NormalizeSteamID64(steam_id);

	if (!steam_id || !HasServerKey()) {
		return;
	}

	if (profile_position_cache[steam_id] !== undefined) {
		return;
	}

	if (profile_position_pending[steam_id]) {
		return;
	}

	if (profile_position_retry_at[steam_id] !== undefined && GetCurrentTime() < profile_position_retry_at[steam_id]) {
		return;
	}

	profile_position_pending[steam_id] = true;

	api.getPlayerPosition({
		steamid: steam_id,
		language: $.Localize("#lang"),
	}, function (data) {
		profile_position_cache[steam_id] = ExtractProfilePosition(data, steam_id);
		profile_position_pending[steam_id] = false;
		profile_position_retry_at[steam_id] = 0;
		UpdateProfilePanels();
	}, function () {
		profile_position_pending[steam_id] = false;
		profile_position_retry_at[steam_id] = GetCurrentTime() + 5;
	});
}

function RequestProfilePositionForSelected() {
	var selected_player_data = GetProfileDataForPlayer(GetSelectedProfilePlayerID());

	if (!selected_player_data.steam_id) {
		return;
	}

	RequestProfilePositionForSteam(selected_player_data.steam_id);
}

function GetProfileDataForPlayer(player_id) {
	var local_player_id = GetLocalPlayerIDSafe();
	var player_info = null;
	var player_table = {};
	var xp_current = 0;
	var xp_max = 1000;
	var has_profile_data = false;
	var has_xp_data = false;

	if (player_id >= 0) {
		player_info = Game.GetPlayerInfo(player_id);
	}

	if (!player_info && player_id == local_player_id) {
		player_info = Game.GetLocalPlayerInfo();
	}

	if (player_id >= 0) {
		player_table = CustomNetTables.GetTableValue("battlepass_player", player_id.toString()) || {};
	}

	for (var key in player_table) {
		has_profile_data = true;
		break;
	}

	if (player_table.MaxXP !== undefined) {
		xp_max = Math.max(1, ToNumber(player_table.MaxXP, 1000));
	}

	if (player_table.XP !== undefined) {
		xp_current = Math.max(0, ToNumber(player_table.XP, 0));
		has_xp_data = true;
	} else if (player_table.whalepass_xp !== undefined) {
		xp_current = Math.max(0, ToNumber(player_table.whalepass_xp, 0));
		has_xp_data = true;

		while (xp_current >= xp_max) {
			xp_current = xp_current - xp_max;
		}
	}

	return {
		player_id: player_id,
		steam_id: GetSteamIDFromPlayerInfo(player_info),
		player_name: GetPlayerDisplayName(player_id, player_info),
		title: player_table.title || L("loading_screen_unavailable"),
		title_color: player_table.title_color || "#9eb0c9",
		level: player_table.Lvl !== undefined ? player_table.Lvl : "-",
		xp_current: xp_current,
		xp_max: xp_max,
		has_xp_data: has_xp_data,
		seasonal_winrate: has_profile_data ? FormatPercentValue(player_table.winrate) : L("loading_screen_na"),
		donator_level: player_table.donator_level,
		donator_color: player_table.donator_color || "#f1e3c3",
		mmr_title: player_table.mmr_title || L("loading_screen_na"),
		connection_state: (player_info && player_info.player_connection_state !== undefined) ? player_info.player_connection_state : connection_state.NOT_YET_CONNECTED,
		toggle_tag: player_table.toggle_tag,
		player_xp: player_table.player_xp,
		winrate_toggle: player_table.winrate_toggle,
		bp_rewards: player_table.bp_rewards,
		has_profile_data: has_profile_data,
	};
}

function GetLeaderboardTextForSteam(steam_id) {
	if (!steam_id) {
		return L("loading_screen_unavailable");
	}

	if (profile_position_pending[steam_id]) {
		return L("loading_screen_loading");
	}

	if (profile_position_cache[steam_id] === undefined) {
		return L("loading_screen_loading");
	}

	if (profile_position_cache[steam_id] === null || profile_position_cache[steam_id] === false || profile_position_cache[steam_id] === "") {
		return L("loading_screen_na");
	}

	return "#" + profile_position_cache[steam_id];
}

function UpdateProfilePanels() {
	var local_player_id = GetLocalPlayerIDSafe();
	var selected_player_id = GetSelectedProfilePlayerID();

	if (selected_player_id < 0 && local_player_id >= 0) {
		selected_player_id = local_player_id;
		selected_profile_player_id = selected_player_id;
	}

	var local_data = GetProfileDataForPlayer(local_player_id);
	var selected_data = GetProfileDataForPlayer(selected_player_id);

	var summary_avatar = $("#ProfileSummaryAvatar");
	var modal_avatar = $("#ProfileModalAvatar");
	var summary_name = $("#ProfileSummaryName");
	var summary_title = $("#ProfileSummaryTitle");
	var summary_level = $("#ProfileSummaryLevel");
	var summary_winrate = $("#ProfileSummaryWinrate");

	if (summary_avatar) {
		summary_avatar.steamid = local_data.steam_id ? local_data.steam_id : "0";
	}

	if (modal_avatar) {
		modal_avatar.steamid = selected_data.steam_id ? selected_data.steam_id : "0";
	}

	if (summary_name) {
		summary_name.text = local_data.player_name;
	}

	if (summary_title) {
		summary_title.text = local_data.title;
		summary_title.style.color = local_data.title_color;
	}

	if (summary_level) {
		summary_level.text = local_data.level.toString();
	}

	if (summary_winrate) {
		summary_winrate.text = local_data.seasonal_winrate;
	}

	var modal_name = selected_data.player_name;
	if (selected_data.player_id >= 0 && selected_data.player_id == local_player_id) {
		modal_name = modal_name + " " + L("loading_screen_you_suffix");
	}

	SafeSetText("ProfileModalName", modal_name);
	SafeSetText("ProfileModalSubtitle", selected_data.steam_id ? LocalizeTemplate("loading_screen_steam_id", { steam_id: selected_data.steam_id }) : L("loading_screen_steam_id_unavailable"));
	SafeSetText("ProfileModalLevelValue", selected_data.level.toString());
	SafeSetText("ProfileModalXPValue", selected_data.has_xp_data ? (FormatIntegerValue(selected_data.xp_current) + " / " + FormatIntegerValue(selected_data.xp_max)) : L("loading_screen_na"));
	SafeSetText("ProfileModalTitleValue", selected_data.title);
	SafeSetText("ProfileModalWinrateValue", selected_data.seasonal_winrate);
	SafeSetText("ProfileModalDonatorValue", GetDonatorLevelText(selected_data.donator_level));
	SafeSetText("ProfileModalMMRTitleValue", selected_data.mmr_title);
	SafeSetText("ProfileModalConnectionValue", GetConnectionStateText(selected_data.connection_state));
	SafeSetText("ProfileModalTagVisibleValue", GetVisibilityStateText(selected_data.toggle_tag));
	SafeSetText("ProfileModalXPVisibleValue", GetVisibilityStateText(selected_data.player_xp));
	SafeSetText("ProfileModalWinrateVisibleValue", GetVisibilityStateText(selected_data.winrate_toggle));
	SafeSetText("ProfileModalRewardsVisibleValue", GetVisibilityStateText(selected_data.bp_rewards));
	SafeSetText("ProfileModalLeaderboardValue", GetLeaderboardTextForSteam(selected_data.steam_id));

	var modal_title = $("#ProfileModalTitleValue");
	if (modal_title) {
		modal_title.style.color = selected_data.title_color;
	}

	var modal_donator = $("#ProfileModalDonatorValue");
	if (modal_donator) {
		modal_donator.style.color = selected_data.donator_color;
	}

	var xp_progress = $("#ProfileModalXPProgress");
	if (xp_progress) {
		if (selected_data.has_xp_data) {
			xp_progress.value = Clamp01(selected_data.xp_current / Math.max(1, selected_data.xp_max));
		} else {
			xp_progress.value = 0;
		}
	}

	SetRankMedal("ProfileModalRankTier", "ProfileModalRankPips", selected_data.mmr_title);

	var steam_button = $("#ProfileModalSteamButton");
	if (steam_button) {
		var can_open_steam = selected_data.steam_id.length > 0;
		steam_button.enabled = can_open_steam;
		steam_button.SetHasClass("IsDisabled", !can_open_steam);
	}
}

function RefreshProfileDataLoop() {
	UpdateProfilePanels();
	RequestProfilePositionForSelected();
	$.Schedule(0.25, RefreshProfileDataLoop);
}

function ToggleProfileModal(bBoolean) {
	var root_panel = $.GetContextPanel();
	profile_modal_transition_token = profile_modal_transition_token + 1;
	var transition_token = profile_modal_transition_token;

	if (bBoolean) {
		if (GetSelectedProfilePlayerID() < 0) {
			SetSelectedProfilePlayer(GetLocalPlayerIDSafe(), false);
		}

		RequestProfilePositionForSelected();
		root_panel.SetHasClass("ProfileModalClosing", false);
		root_panel.SetHasClass("ProfileModalVisible", true);
		return;
	}

	if (!root_panel.BHasClass("ProfileModalVisible") && !root_panel.BHasClass("ProfileModalClosing")) {
		return;
	}

	root_panel.SetHasClass("ProfileModalVisible", false);
	root_panel.SetHasClass("ProfileModalClosing", true);

	$.Schedule(profile_modal_fade_duration, function () {
		if (transition_token != profile_modal_transition_token) {
			return;
		}

		root_panel.SetHasClass("ProfileModalClosing", false);
	});
}

function OpenExternalURL(url) {
	if (!url || url.length <= 0) {
		return false;
	}

	if (typeof ExternalBrowserGoToURL === "function") {
		ExternalBrowserGoToURL(url);
		return true;
	}

	try {
		$.DispatchEvent("ExternalBrowserGoToURL", url);
		return true;
	} catch (err) {
		$.Msg("ExternalBrowserGoToURL unavailable: " + err);
	}

	try {
		$.DispatchEvent("DOTADisplayURL", url);
		return true;
	} catch (err2) {
		$.Msg("DOTADisplayURL unavailable: " + err2);
	}

	return false;
}

function OpenProfileSteamPage() {
	var selected_data = GetProfileDataForPlayer(GetSelectedProfilePlayerID());

	if (selected_data.steam_id) {
		OpenExternalURL("https://steamcommunity.com/profiles/" + selected_data.steam_id);
		return;
	}

	var local_info = Game.GetLocalPlayerInfo();
	var local_steam_id64 = GetSteamIDFromPlayerInfo(local_info);

	if (local_steam_id64) {
		OpenExternalURL("https://steamcommunity.com/profiles/" + local_steam_id64);
		return;
	}

	if (typeof DOTAShowProfilePage === "function") {
		DOTAShowProfilePage(0);
	}
}

function OnCustomSetupReadyPressed() {
	var local_player_id = GetLocalPlayerIDSafe();

	if (local_player_id < 0) {
		return;
	}

	GameEvents.SendCustomGameEventToServer("custom_setup_ready", { PlayerID: local_player_id });
}

function GetVoteInfoTooltipText() {
	if (game_options && game_options.game_type && vote_array[game_options.game_type]) {
		const categories = Object.keys(vote_array[game_options.game_type]);

		if (categories.length == 1) {
			return LocalizeWithFallback("#vote_" + categories[0] + "_description");
		}
	}

	return LocalizeWithFallback("#vote_settings_description");
}

function GetConnectionStateText(state) {
	if (state === connection_state.CONNECTED) {
		return L("loading_screen_connection_loaded");
	}

	if (state === connection_state.LOADING) {
		return L("loading_screen_connection_loading");
	}

	if (state === connection_state.DISCONNECTED) {
		return L("loading_screen_connection_disconnected");
	}

	if (state === connection_state.ABANDONED) {
		return L("loading_screen_connection_abandoned");
	}

	if (state === connection_state.FAILED) {
		return L("loading_screen_connection_failed");
	}

	if (state === connection_state.NOT_YET_CONNECTED) {
		return L("loading_screen_connection_pending");
	}

	return L("loading_screen_connection_pending");
}

function IsIssueConnectionState(state) {
	return state === connection_state.DISCONNECTED || state === connection_state.ABANDONED || state === connection_state.FAILED;
}

function IsLoadedConnectionState(state) {
	return state === connection_state.CONNECTED;
}

function GetConnectionGroup(state) {
	if (IsIssueConnectionState(state)) {
		return "failed";
	}

	if (IsLoadedConnectionState(state)) {
		return "ready";
	}

	return "waiting";
}

function GetConnectionGroupPriority(state) {
	var group = GetConnectionGroup(state);

	if (group == "failed") {
		return 0;
	}

	if (group == "waiting") {
		return 1;
	}

	return 2;
}

function GetConnectionStatePriority(state) {
	if (state === connection_state.FAILED) {
		return 0;
	}

	if (state === connection_state.DISCONNECTED) {
		return 1;
	}

	if (state === connection_state.ABANDONED) {
		return 2;
	}

	if (state === connection_state.LOADING) {
		return 3;
	}

	if (state === connection_state.NOT_YET_CONNECTED) {
		return 4;
	}

	if (state === connection_state.UNKNOWN) {
		return 5;
	}

	return 6;
}

function GetConnectionGroupTitle(group_key) {
	if (group_key == "failed") {
		return L("loading_screen_group_failed");
	}

	if (group_key == "waiting") {
		return L("loading_screen_group_waiting");
	}

	return L("loading_screen_group_ready");
}

function GetPlayerDisplayName(player_id, player_info) {
	if (player_info && player_info.player_name && player_info.player_name.length > 0) {
		return player_info.player_name;
	}

	if (player_id !== undefined && player_id >= 0) {
		const fallback_name = Players.GetPlayerName(player_id);
		if (fallback_name && fallback_name.length > 0) {
			return fallback_name;
		}
	}

	return L("loading_screen_player");
}

function BuildToolsModeLoadingEntries() {
	if (!Game.IsInToolsMode || !Game.IsInToolsMode()) {
		return [];
	}

	return [
		{ key: "tools_state_connected", state: connection_state.CONNECTED, name: L("loading_screen_tools_loaded") },
		{ key: "tools_state_loading", state: connection_state.LOADING, name: L("loading_screen_tools_loading") },
		{ key: "tools_state_pending", state: connection_state.NOT_YET_CONNECTED, name: L("loading_screen_tools_pending") },
		{ key: "tools_state_unknown", state: connection_state.UNKNOWN, name: L("loading_screen_tools_unknown") },
		{ key: "tools_state_disconnected", state: connection_state.DISCONNECTED, name: L("loading_screen_tools_disconnected") },
		{ key: "tools_state_failed", state: connection_state.FAILED, name: L("loading_screen_tools_failed") },
		{ key: "tools_state_abandoned", state: connection_state.ABANDONED, name: L("loading_screen_tools_abandoned") },
	];
}

function UpdatePlayerLoadingSidebar() {
	const list_parent = $("#PlayerLoadingList");
	const counter = $("#PlayerLoadingCounter");
	const progress_bar = $("#PlayerLoadingProgress");
	const waiting_label = $("#PlayerLoadingWaiting");
	const issues_label = $("#PlayerLoadingIssues");
	const force_launch_label = $("#PlayerForceLaunchLabel");
	const ready_button = $("#PlayerReadyButton");
	const ready_button_label = $("#PlayerReadyButtonLabel");
	const setup_status = GetCustomSetupStatus();
	const setup_active = IsCustomSetupStatusActive(setup_status);
	const setup_launching = setup_status && (setup_status.launching === true || setup_status.launching === 1 || setup_status.launching === "1");
	const setup_remaining = Math.max(0, Math.floor(ToNumber(setup_status.remaining_time, ToNumber(setup_status.duration, 20))));
	const local_player_id = GetLocalPlayerIDSafe();
	const local_player_ready = local_player_id >= 0 ? IsPlayerMarkedReady(setup_status, local_player_id) : false;
	const local_player_eligible = setup_status &&
		setup_status.ready_players &&
		(setup_status.ready_players[local_player_id] !== undefined || setup_status.ready_players[local_player_id.toString()] !== undefined);

	if (!list_parent || !counter) {
		return;
	}

	let player_ids = [];
	if (Game.GetAllPlayerIDs) {
		player_ids = Game.GetAllPlayerIDs() || [];
	}

	player_ids = player_ids.slice(0).sort(function (a, b) { return a - b; });

	const player_entries = [];

	for (var i = 0; i < player_ids.length; i++) {
		const player_id = player_ids[i];
		const player_info = Game.GetPlayerInfo(player_id);

		if (!player_info) {
			continue;
		}

		player_entries.push({
			row_key: player_id.toString(),
			player_id: player_id,
			player_info: player_info,
			display_name: GetPlayerDisplayName(player_id, player_info),
			can_open_profile: true,
			is_tools_debug: false,
		});
	}

	const tools_debug_entries = BuildToolsModeLoadingEntries();
	for (var t = 0; t < tools_debug_entries.length; t++) {
		const tools_entry = tools_debug_entries[t];

		player_entries.push({
			row_key: tools_entry.key,
			player_id: -1,
			player_info: {
				player_name: tools_entry.name,
				player_connection_state: tools_entry.state,
			},
			display_name: tools_entry.name,
			can_open_profile: false,
			is_tools_debug: true,
		});
	}

	const active_rows = {};
	const active_sections = {};
	const section_counts = {
		failed: 0,
		waiting: 0,
		ready: 0,
	};
	let total_players = 0;
	let loaded_players = 0;
	let waiting_players = 0;
	let issue_players = 0;

	for (var entry_seed = 0; entry_seed < player_entries.length; entry_seed++) {
		const seeded_entry = player_entries[entry_seed];
		const seeded_state = seeded_entry.player_info.player_connection_state;
		const seeded_group = GetConnectionGroup(seeded_state);

		seeded_entry.connection_state = seeded_state;
		seeded_entry.group = seeded_group;
		seeded_entry.group_priority = GetConnectionGroupPriority(seeded_state);
		seeded_entry.state_priority = GetConnectionStatePriority(seeded_state);

		section_counts[seeded_group] = (section_counts[seeded_group] || 0) + 1;
	}

	player_entries.sort(function (a, b) {
		if (a.group_priority != b.group_priority) {
			return a.group_priority - b.group_priority;
		}

		if (a.state_priority != b.state_priority) {
			return a.state_priority - b.state_priority;
		}

		if (a.can_open_profile != b.can_open_profile) {
			return a.can_open_profile ? -1 : 1;
		}

		return a.display_name.localeCompare(b.display_name);
	});

	var order_signature = "";
	for (var sig_i = 0; sig_i < player_entries.length; sig_i++) {
		order_signature = order_signature + "|" + player_entries[sig_i].row_key + ":" + player_entries[sig_i].group + ":" + player_entries[sig_i].state_priority;
	}
	order_signature = order_signature + "|f" + section_counts.failed + "|w" + section_counts.waiting + "|r" + section_counts.ready;

	if (player_loading_order_signature != order_signature) {
		for (var stale_row_key in player_loading_rows) {
			if (player_loading_rows[stale_row_key] && player_loading_rows[stale_row_key].panel) {
				player_loading_rows[stale_row_key].panel.DeleteAsync(0);
			}
		}

		for (var stale_section_key in player_loading_section_rows) {
			if (player_loading_section_rows[stale_section_key]) {
				player_loading_section_rows[stale_section_key].DeleteAsync(0);
			}
		}

		player_loading_rows = {};
		player_loading_section_rows = {};
		player_loading_order_signature = order_signature;
	}

	for (var entry_index = 0; entry_index < player_entries.length; entry_index++) {
		const entry = player_entries[entry_index];
		const row_key = entry.row_key;
		const player_id = entry.player_id;
		const player_info = entry.player_info;
		const state = entry.connection_state;
		const group = entry.group;
		const is_loaded = IsLoadedConnectionState(state);
		const is_issue = IsIssueConnectionState(state);
		const is_connecting = !is_loaded && !is_issue;

		if (!active_sections[group]) {
			active_sections[group] = true;

			if (!player_loading_section_rows[group]) {
				var section_row = $.CreatePanel("Label", list_parent, "PlayerLoadingSection_" + group);
				section_row.AddClass("player-loading-section");
				player_loading_section_rows[group] = section_row;
			}

			player_loading_section_rows[group].text = GetConnectionGroupTitle(group) + " (" + (section_counts[group] || 0) + ")";
		}

		total_players = total_players + 1;
		active_rows[row_key] = true;

		if (is_loaded) {
			loaded_players = loaded_players + 1;
		} else {
			waiting_players = waiting_players + 1;
		}

		if (is_issue) {
			issue_players = issue_players + 1;
		}

		if (!player_loading_rows[row_key]) {
			const safe_row_key = row_key.toString().replace(/[^a-zA-Z0-9_]/g, "_");
			const row = $.CreatePanel("Panel", list_parent, "PlayerLoadingRow_" + safe_row_key);
			row.AddClass("player-loading-row");

			const dot = $.CreatePanel("Panel", row, "");
			dot.AddClass("player-loading-dot");

			const spinner = $.CreatePanel("Panel", row, "");
			spinner.AddClass("player-loading-spinner");

			const avatar = $.CreatePanel("DOTAAvatarImage", row, "");
			avatar.AddClass("player-loading-avatar");

			const name = $.CreatePanel("Label", row, "");
			name.AddClass("player-loading-name");

			const status_label = $.CreatePanel("Label", row, "");
			status_label.AddClass("player-loading-state");

			player_loading_rows[row_key] = {
				panel: row,
				dot: dot,
				spinner: spinner,
				avatar: avatar,
				name: name,
				status: status_label,
				player_id: player_id,
			};
		}

		const player_row = player_loading_rows[row_key];
		player_row.player_id = player_id;
		const is_marked_ready = player_id >= 0 && IsPlayerMarkedReady(setup_status, player_id);

		if (!player_row.spinner) {
			player_row.spinner = $.CreatePanel("Panel", player_row.panel, "");
			player_row.spinner.AddClass("player-loading-spinner");
		}

		if (!player_row.avatar) {
			player_row.avatar = $.CreatePanel("DOTAAvatarImage", player_row.panel, "");
			player_row.avatar.AddClass("player-loading-avatar");
		}

		if (entry.can_open_profile) {
			player_row.panel.SetPanelEvent("onactivate", (function (target_player_id) {
				return function () {
					SetSelectedProfilePlayer(target_player_id, true);
				};
			})(player_id));
		} else {
			player_row.panel.SetPanelEvent("onactivate", function () { });
		}

		(function (row_panel, tooltip_name) {
			row_panel.SetPanelEvent("onmouseover", function () {
				$.DispatchEvent("UIShowTextTooltip", row_panel, tooltip_name);
			});

			row_panel.SetPanelEvent("onmouseout", function () {
				$.DispatchEvent("UIHideTextTooltip", row_panel);
			});
		})(player_row.panel, entry.display_name);

		player_row.panel.SetHasClass("PlayerLoadingReady", is_loaded);
		player_row.panel.SetHasClass("PlayerLoadingWaiting", !is_loaded);
		player_row.panel.SetHasClass("PlayerLoadingIssue", is_issue);
		player_row.panel.SetHasClass("PlayerLoadingConnecting", is_connecting);
		player_row.panel.SetHasClass("PlayerLoadingSelected", player_id >= 0 && player_id == GetSelectedProfilePlayerID());
		player_row.panel.SetHasClass("PlayerMarkedReady", is_marked_ready);
		player_row.panel.SetHasClass("PlayerLoadingInteractive", entry.can_open_profile);
		player_row.panel.SetHasClass("PlayerLoadingStatic", !entry.can_open_profile);
		player_row.panel.SetHasClass("PlayerLoadingToolsDebug", entry.is_tools_debug);

		player_row.dot.SetHasClass("PlayerLoadingReady", is_loaded);
		player_row.dot.SetHasClass("PlayerLoadingWaiting", !is_loaded);
		player_row.dot.SetHasClass("PlayerLoadingIssue", is_issue);
		player_row.dot.style.visibility = is_connecting ? "collapse" : "visible";

		player_row.spinner.style.visibility = is_connecting ? "visible" : "collapse";

		const steam_id64 = entry.can_open_profile ? GetSteamIDFromPlayerInfo(player_info) : "";
		if (steam_id64 && steam_id64.length > 0) {
			player_row.avatar.steamid = steam_id64;
			player_row.avatar.style.visibility = "visible";
		} else {
			player_row.avatar.steamid = "0";
			player_row.avatar.style.visibility = "collapse";
		}

		player_row.name.text = entry.display_name;
		player_row.status.text = is_marked_ready ? L("loading_screen_ready") : GetConnectionStateText(state);
	}

	for (var row_key in player_loading_rows) {
		if (!active_rows[row_key]) {
			if (player_loading_rows[row_key].player_id == GetSelectedProfilePlayerID()) {
				selected_profile_player_id = GetLocalPlayerIDSafe();
			}

			player_loading_rows[row_key].panel.DeleteAsync(0);
			delete player_loading_rows[row_key];
		}
	}

	for (var section_key in player_loading_section_rows) {
		if (!active_sections[section_key]) {
			player_loading_section_rows[section_key].DeleteAsync(0);
			delete player_loading_section_rows[section_key];
		}
	}

	counter.text = LocalizeTemplate("loading_screen_loaded_counter", {
		loaded: loaded_players.toString(),
		total: total_players.toString(),
	});

	if (progress_bar) {
		progress_bar.value = total_players > 0 ? Clamp01(loaded_players / total_players) : 0;
	}

	const all_players_loaded = total_players > 0 && loaded_players >= total_players;
	const has_connection_failures = issue_players > 0;

	if (waiting_label) {
		if (all_players_loaded || total_players <= 0) {
			waiting_label.style.visibility = "collapse";
		} else {
			waiting_label.style.visibility = "visible";
			waiting_label.text = LocalizeTemplate("loading_screen_failed_counter", { count: issue_players.toString() });
		}
	}

	if (issues_label) {
		if (all_players_loaded || total_players <= 0) {
			issues_label.style.visibility = "collapse";
		} else {
			issues_label.style.visibility = "collapse";
			issues_label.text = LocalizeTemplate("loading_screen_waiting_counter", { count: waiting_players.toString() });
		}
	}

	if (force_launch_label) {
		if (setup_active) {
			force_launch_label.style.visibility = "visible";
			force_launch_label.text = has_connection_failures ? L("loading_screen_failed_returning_lobby") : LocalizeTemplate("loading_screen_match_starts_in", { seconds: setup_remaining.toString() });
		} else if (setup_launching) {
			force_launch_label.style.visibility = "visible";
			force_launch_label.text = has_connection_failures ? L("loading_screen_failed_returning_lobby") : L("loading_screen_launching_match");
		} else {
			force_launch_label.style.visibility = "collapse";
		}
	}

	if (ready_button) {
		const can_show_ready = setup_active && local_player_id >= 0 && local_player_eligible;
		ready_button.style.visibility = can_show_ready ? "visible" : "collapse";
		ready_button.enabled = can_show_ready && !local_player_ready;
		ready_button.SetHasClass("IsReady", local_player_ready);
		ready_button.SetHasClass("IsDisabled", can_show_ready && local_player_ready);

		if (ready_button_label) {
			ready_button_label.text = local_player_ready ? L("loading_screen_ready") : L("loading_screen_mark_ready");
		}
	}

	$.Schedule(0.2, UpdatePlayerLoadingSidebar);
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
	UpdateProfilePanels();
}

function SetProfileName() {
	UpdateProfilePanels();
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

		if (secret_key !== undefined && secret_key !== null) {
			secret_key = secret_key.toString();
		}
	}

	RequestProfilePositionForSelected();

	if (Game.GetMapInfo().map_display_name == "imba_1v1")
		DisableVoting();
	else if (Game.GetMapInfo().map_display_name == "imbathrow_3v3v3v3")
		DisableRankingVoting();

	var game_version = game_options.value;

	if (isInt(game_version))
		game_version = game_version.toString() + ".0";

	view.title.text = $.Localize("#addon_game_name") + " " + game_version;
	view.subtitle.text = $.Localize("#game_version_name").toUpperCase();

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
			if (english_row && english_row.content) {
				view.text.text = english_row.content;
			}
			//			view.link_text.text = english_row.link_text;
		}
	}, function () {
		// error callback
		$.Msg("Unable to retrieve loading screen info.");
	});
};

function HideVoteCategory(vote_type) {
	const parent = $("#vote_" + vote_type);
	const vote_content = $("#VoteContent");

	if (parent) {
		parent.visible = false;
	}

	if (!vote_content) {
		ToggleVoteContainer(false);
		return;
	}

	const vote_children = vote_content.Children();
	for (var i = 0; i < vote_children.length; i++) {
		if (vote_children[i].visible == true) {
			return;
		}
	}

	ToggleVoteContainer(false);
}

function ShowAllVoteCategories() {
	const vote_content = $("#VoteContent");

	if (!vote_content) {
		return;
	}

	const vote_children = vote_content.Children();
	for (var i = 0; i < vote_children.length; i++) {
		vote_children[i].visible = true;
	}
}

function AllPlayersLoaded() {
	const vote_parent = $("#VoteContent");
	const vote_label_container = $("#vote-label-container");
	const main_vote_button = $("#MainVoteButton");

	if (!vote_parent) {
		return;
	}

	// Rebuild from scratch to avoid stale hidden panels / duplicate rows.
	vote_parent.RemoveAndDeleteChildren();
	if (vote_label_container) {
		vote_label_container.RemoveAndDeleteChildren();
	}

	if (main_vote_button) {
		main_vote_button.style.opacity = "1";
	}

	if (!game_options || !game_options.game_type) {
		$.Schedule(0.1, AllPlayersLoaded);
		return;
	}

	// $.Msg(vote_array["XHS"]);
	const vote_config = vote_array[game_options.game_type] || {};
	const vote_categories = Object.keys(vote_config);
	const vote_title = $.GetContextPanel().FindChildrenWithClassTraverse("vote-content-title");
	const vote_dialog = $.GetContextPanel().FindChildrenWithClassTraverse("vote-content");

	if (vote_title && vote_title[0]) {
		if (vote_categories.length == 1) {
			vote_title[0].text = LocalizeWithFallback("#vote_" + vote_categories[0]);
		} else {
			vote_title[0].text = LocalizeWithFallback("#vote_settings");
		}
	}

	if (vote_dialog && vote_dialog[0]) {
		vote_dialog[0].SetHasClass("SingleVoteCategory", vote_categories.length == 1);
	}

	for (var j in vote_config) {
		const vote_type = j;
		// $.Msg(vote_type)
		const vote_count = vote_config[j];
		const panel = $.CreatePanel("Panel", vote_parent, "vote_" + vote_type);
		panel.AddClass("vote-category-row");
		// panel.AddClass("VotePanel");
		var row_is_compact = true;

		// mid-left ui
		var gamemode_label = $.CreatePanel("Label", $("#vote-label-container"), "");
		gamemode_label.AddClass("vote-label");
		// gamemode_label.style.height = (100 / vote_count) + "%";
		gamemode_label.text = LocalizeWithFallback("#vote_" + vote_type);

		for (var i = 1; i <= vote_count; i++) {
			var vote_button = $.CreatePanel("Panel", panel, "VoteGameMode" + i);
			vote_button.AddClass("vote-choice-cell");
			vote_button.BLoadLayoutSnippet('VoteChoice');

			var card_width = 300;
			if (vote_count >= 5) {
				card_width = 228;
			} else if (vote_count == 4) {
				card_width = 248;
			} else if (vote_count == 3) {
				card_width = 280;
			}

			vote_button.style.width = card_width + "px";

			// mid-left ui
			var gamemode_label = $.CreatePanel("Label", $("#vote-label-container"), "leftui_vote_" + vote_type + "_" + i);
			gamemode_label.AddClass("vote-label");
			gamemode_label.AddClass("label_" + vote_type + "_reset");
			// gamemode_label.style.height = (100 / vote_count) + "%";
			gamemode_label.text = LocalizeWithFallback("#vote_" + vote_type + "_" + i);

			(function (panel, vote_type, i) {
				panel.SetPanelEvent("onmouseover", function () {
					$.DispatchEvent("UIShowTextTooltip", panel, LocalizeWithFallback("#vote_" + vote_type + "_" + i + "_description"));
				})

				panel.SetPanelEvent("onmouseout", function () {
					$.DispatchEvent("UIHideTextTooltip", panel);
				})
			})(gamemode_label, vote_type, i);

			var option_title = LocalizeWithFallback("#vote_" + vote_type + "_" + i);
			var option_description = LocalizeWithFallback("#vote_" + vote_type + "_" + i + "_description");
			var is_compact_description = option_description.length <= 120;

			vote_button.GetChild(0).text = option_title;
			vote_button.GetChild(1).text = option_description;

			vote_button.SetHasClass("VotePanelCompact", is_compact_description);

			if (!is_compact_description) {
				row_is_compact = false;
			}

			var choice_card = vote_button.GetChild(2);

			(function (button, vote_type, i) {
				if (!button) {
					return;
				}

				button.SetPanelEvent("onactivate", function () {
					OnVoteButtonPressed(vote_type, i);
					HideVoteCategory(vote_type);
				})
			})(choice_card, vote_type, i);
		}

		panel.SetHasClass("VoteRowCompact", row_is_compact);
	}

	const has_vote_options = vote_categories.length > 0;

	if (main_vote_button) {
		main_vote_button.enabled = has_vote_options;
		main_vote_button.style.opacity = has_vote_options ? "1" : "0.45";
	}

	ToggleVoteContainer(has_vote_options);

	//	$("#VoteGameMode1").checked = true;
	//	OnVoteButtonPressed("gamemode", 1);
}

function AllPlayersBattlepassLoaded() {
	UpdateProfilePanels();
	RequestProfilePositionForSelected();
}

function ToggleVoteContainer(bBoolean) {
	var vote_container = $.GetContextPanel().FindChildrenWithClassTraverse("vote-container-main");

	if (vote_container && vote_container[0]) {
		var panel = vote_container[0];
		panel.SetHasClass("Visible", bBoolean);
		panel.style.visibility = bBoolean ? "visible" : "collapse";
		panel.hittest = bBoolean;
		panel.hittestchildren = bBoolean;

		if (bBoolean) {
			ShowAllVoteCategories();
		}
	}
}

function HoverableLoadingScreen() {
	if (Game.GameStateIs(2))
		$.GetContextPanel().style.zIndex = "1";
	else
		$.Schedule(1.0, HoverableLoadingScreen)
}

function RefreshLocalVoteCategoryUI(category) {
	var labels = GetOrderedVoteLabels(category);
	var selected_vote = parseInt(local_votes[category]);
	var vote_confirmed = local_vote_confirmed[category] === true;

	for (var i = 0; i < labels.length; i++) {
		var index = i + 1;
		var is_selected = selected_vote == index;
		labels[i].SetHasClass("VoteSelectedOption", is_selected);
		labels[i].SetHasClass("VotePendingOption", is_selected && !vote_confirmed);
		labels[i].SetHasClass("VoteConfirmedOption", is_selected && vote_confirmed);
	}
}

function GetVoteChoiceFromEntry(vote_entry) {
	if (vote_entry === undefined || vote_entry === null) {
		return -1;
	}

	if (vote_entry[1] !== undefined) {
		return parseInt(vote_entry[1]);
	}

	if (vote_entry.vote !== undefined) {
		return parseInt(vote_entry.vote);
	}

	if (vote_entry.choice !== undefined) {
		return parseInt(vote_entry.choice);
	}

	var parsed = parseInt(vote_entry);
	return isNaN(parsed) ? -1 : parsed;
}

function FindPlayerVoteEntry(vote_table, player_id) {
	if (!vote_table || player_id < 0) {
		return null;
	}

	var direct = vote_table[player_id];
	if (direct !== undefined) {
		return direct;
	}

	var string_key = player_id.toString();
	if (vote_table[string_key] !== undefined) {
		return vote_table[string_key];
	}

	for (var key in vote_table) {
		if (parseInt(key) == player_id) {
			return vote_table[key];
		}
	}

	return null;
}

function UpdateLocalVoteConfirmation(category, vote_table) {
	var local_player_id = GetLocalPlayerIDSafe();
	var local_vote = parseInt(local_votes[category]);

	if (local_player_id < 0 || isNaN(local_vote)) {
		local_vote_confirmed[category] = false;
		return;
	}

	var local_entry = FindPlayerVoteEntry(vote_table, local_player_id);
	var server_vote = GetVoteChoiceFromEntry(local_entry);
	local_vote_confirmed[category] = server_vote == local_vote;
}

function GetOrderedVoteLabels(category) {
	var vote_container = $("#vote-label-container");

	if (!vote_container) {
		return [];
	}

	var labels = [];
	var vote_count = 12;

	if (game_options && game_options.game_type && vote_array[game_options.game_type] && vote_array[game_options.game_type][category]) {
		vote_count = vote_array[game_options.game_type][category];
	}

	for (var index = 1; index <= vote_count; index++) {
		var label = vote_container.FindChildTraverse("leftui_vote_" + category + "_" + index);
		if (label) {
			labels.push(label);
		}
	}

	if (labels.length > 0) {
		return labels;
	}

	return vote_container.FindChildrenWithClassTraverse("label_" + category + "_reset") || [];
}

function OnVoteButtonPressed(category, vote) {
	// var gamemode_name = $.Localize("#vote_" + category);

	// $("#VoteGameModeCheck").text = "You have voted for " + gamemode_name + ".";
	local_votes[category] = vote;
	local_vote_confirmed[category] = false;
	RefreshLocalVoteCategoryUI(category);
	GameEvents.SendCustomGameEventToServer("setting_vote", { "category": category, "vote": vote, "PlayerID": Game.GetLocalPlayerID() });
}

/* new system, double votes for donators */

function OnVotesReceived(data) {
	var vote_counter = [];
	var reset_labels = GetOrderedVoteLabels(data.category);

	// Reset tooltips
	for (var i = 0; i < reset_labels.length; i++) {
		var panel = reset_labels[i];
		const index = i + 1;
		panel.text = LocalizeWithFallback("#vote_" + data.category + "_" + index) + " (0 " + L("loading_screen_vote_word_single") + ")";
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

		var panel = reset_labels[i - 1];
		const index = parseInt(i);
		var vote_tooltip = vote_counter[i] > 1 ? L("loading_screen_vote_word_plural") : L("loading_screen_vote_word_single");

		if (panel) {
			// $.Msg(LocalizeWithFallback("#vote_" + data.category + "_" + index) + " (" + vote_counter[i] + " " + vote_tooltip + ")");
			panel.text = LocalizeWithFallback("#vote_" + data.category + "_" + index) + " (" + vote_counter[i] + " " + vote_tooltip + ")";
		}
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

	UpdateLocalVoteConfirmation(data.category, data.table);
	RefreshLocalVoteCategoryUI(data.category);
}

function DisableVoting() {
	var vote_container = $("#vote-container");

	if (vote_container) {
		vote_container.style.visibility = "collapse";
	}
}

function DisableRankingVoting() {
	DisableVoting();
}

(function () {
	// if (Game.IsInToolsMode()) {
	// 	AllPlayersLoaded();
	// }

	var vote_title = $.GetContextPanel().FindChildrenWithClassTraverse("vote-title");

	if (vote_title && vote_title[0]) {
		vote_title[0].text = LocalizeWithFallback("#votes");
	}

	var vote_info = $.GetContextPanel().FindChildrenWithClassTraverse("vote-info");

	if (vote_info && vote_info[0]) {
		vote_info[0].SetPanelEvent("onmouseover", function () {
			$.DispatchEvent("UIShowTextTooltip", vote_info[0], GetVoteInfoTooltipText());
		})

		vote_info[0].SetPanelEvent("onmouseout", function () {
			$.DispatchEvent("UIHideTextTooltip", vote_info[0]);
		})
	}

	var bottom_button_container = $.GetContextPanel().FindChildrenWithClassTraverse("bottom-button-container");

	if (bottom_button_container && bottom_button_container[0] && bottom_button_container[0].GetChild(0))
		bottom_button_container[0].GetChild(0).checked = true;

	var profile_button = $("#HomeProfileContainer");

	if (profile_button) {
		profile_button.SetPanelEvent("onactivate", function () {
			SetSelectedProfilePlayer(GetLocalPlayerIDSafe(), true);
		});

		profile_button.SetPanelEvent("onmouseover", function () {
			$.DispatchEvent("UIShowTextTooltip", profile_button, L("loading_screen_profile_tooltip_open"));
		});

		profile_button.SetPanelEvent("onmouseout", function () {
			$.DispatchEvent("UIHideTextTooltip", profile_button);
		});
	}
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
	RefreshProfileDataLoop();
	UpdatePlayerLoadingSidebar();
	$.GetContextPanel().SetHasClass("ProfileModalVisible", false);
	$.GetContextPanel().SetHasClass("ProfileModalClosing", false);

	CustomNetTables.SubscribeNetTableListener("battlepass_player", function (table_name, key, data) {
		UpdateProfilePanels();
	});

	GameEvents.Subscribe("loading_screen_debug", LoadingScreenDebug);
	GameEvents.Subscribe("send_votes", OnVotesReceived);
	GameEvents.Subscribe("all_players_loaded", AllPlayersLoaded);
	GameEvents.Subscribe("all_players_battlepass_loaded", AllPlayersBattlepassLoaded);
})();
