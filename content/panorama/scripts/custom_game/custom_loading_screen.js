"use strict";

var game_options;
var local_votes = {};
var local_vote_confirmed = {};
var vote_payload_cache = {};
var api_request_sequence = 0;
var api_pending_requests = {};
var api_local_player_retry_seconds = 0.25;
var api_local_player_max_attempts = 40;
var active_vote_sequence = [];
var active_vote_index = 0;
var player_loading_rows = {};
var player_loading_section_rows = {};
var player_loading_order_signature = "";
var player_loading_profile_hover = null;
var player_loading_profile_hover_player_id = -1;
var selected_profile_player_id = -1;
var profile_modal_transition_token = 0;
var profile_modal_fade_duration = 0.18;
var LOADING_SCREEN_CONFIG = {
	links: {
		website: "https://mods.frostrose-studio.com",
		patreon: "https://www.patreon.com/bePatron?u=2533325",
		discord: "https://discord.frostrose-studio.com/",
		artwork_instagram: "https://www.instagram.com/duongcua_art",
	},
	footer: {
		auto_interval_seconds: 10.0,
		rotation_order: [3, 2, 1],
		auto_tick_interval_seconds: 0.1,
	},
	tools: {
		lobby_simulation_enabled: true,
		player_count: 7,
		ready_stagger_seconds: 0.55,
	},
	ready: {
		immediate_lock_fallback_seconds: 5.0,
		toast_duration_seconds: 1.8,
	},
	audio: {
		enabled: true,
		ready_click_events: ["General.ButtonClick", "ui_rollover_micro"],
		all_ready_events: ["ui_team_select_pick_01", "General.Buy"],
		failed_events: ["General.Cancel", "ui_custom_lobby_player_kick"],
	},
	qa: {
		enabled: true,
	},
	taglines: {
		1: "loading_screen_tab_tagline_custom_games",
		2: "loading_screen_tab_tagline_patreon",
		3: "loading_screen_tab_tagline_discord",
	},
};
var bottom_tab_current_panel_index = -1;
var bottom_tab_transition_token = 0;
var bottom_tab_transition_duration = 0.34;
var bottom_tab_auto_interval = LOADING_SCREEN_CONFIG.footer.auto_interval_seconds;
var bottom_tab_rotation_order = LOADING_SCREEN_CONFIG.footer.rotation_order.slice(0);
var bottom_tab_auto_tick_interval = LOADING_SCREEN_CONFIG.footer.auto_tick_interval_seconds;
var bottom_tab_countdown_remaining = bottom_tab_auto_interval;
var bottom_tab_last_tick_time = -1;
var bottom_tab_mouse_over_footer = false;
var bottom_tab_last_mouse_move_time = -1;
var bottom_mods_current_page = 0;
var bottom_mods_auto_elapsed = 0;
var bottom_mods_transition_token = 0;
var bottom_mods_transition_duration = 0.18;
var custom_setup_failed_state = false;
var local_ready_click_pending = false;
var local_ready_click_token = 0;
var ready_toast_token = 0;
var loading_screen_last_global_status_key = "";
var loading_screen_qa_panel_visible = false;
var loading_screen_logs_enabled = false;
var loading_screen_log_sequence = 0;
var loading_screen_last_setup_signature = "";
var loading_screen_last_sidebar_summary_signature = "";
var loading_screen_last_footer_mouse_state = false;
var loading_screen_last_bottom_tab_countdown_bucket = -1;
var tools_mode_last_lobby_signature = "";
var loading_screen_last_fetch_stage = "";
var loading_screen_last_profile_signature = "";
var SUPPORTER_PASS_XP_PER_LEVEL = 1000;
// Debug toggle: set to true to enable fake tools-mode player state simulation.
var tools_mode_lobby_simulation_enabled = LOADING_SCREEN_CONFIG.tools.lobby_simulation_enabled;
var tools_mode_lobby_sim_started_at = -1;
var tools_mode_lobby_player_count = LOADING_SCREEN_CONFIG.tools.player_count;
var tools_mode_lobby_player_stagger = 1.8;
var tools_mode_lobby_ready_stagger = LOADING_SCREEN_CONFIG.tools.ready_stagger_seconds;
var tools_mode_qa_mode = "normal";
var tools_mode_lobby_stage_durations = {
	unknown: 1.3,
	pending: 1.3,
	loading_primary: 2.5,
	disconnected: 1.4,
	abandoned: 1.2,
	loading_reconnect: 2.1,
};

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
	urls: {
		loadingScreenMessage: "loading-screen-info",
	},
	getGameType: function () {
		if (game_options && game_options.game_type) {
			return String(game_options.game_type);
		}
		return "XHS";
	},
	getModPrefix: function () {
		return api.getGameType().toLowerCase() + "/";
	},
	request: function (request_type, data, success_callback, error_callback, attempt) {
		if (!IsServerApiAvailable()) {
			if (error_callback) {
				error_callback();
			}
			return;
		}

		var local_player_id = GetLocalPlayerIDSafe();
		if (local_player_id < 0) {
			var next_attempt = (attempt || 0) + 1;
			if (next_attempt <= api_local_player_max_attempts) {
				$.Schedule(api_local_player_retry_seconds, function () {
					api.request(request_type, data, success_callback, error_callback, next_attempt);
				});
			} else if (error_callback) {
				error_callback("local-player-not-ready");
			}
			return;
		}

		api_request_sequence = api_request_sequence + 1;
		var request_id = api.getGameType() + "_" + local_player_id + "_" + api_request_sequence;
		api_pending_requests[request_id] = {
			success: success_callback || function () {},
			error: error_callback || function () {},
		};

		GameEvents.SendCustomGameEventToServer("loading_screen_api_request", {
			request_id: request_id,
			request_type: request_type,
			data: data || {},
			PlayerID: local_player_id,
		});

		$.Schedule(5.0, function () {
			var pending = api_pending_requests[request_id];
			if (!pending) {
				return;
			}

			delete api_pending_requests[request_id];
			pending.error();
		});
	},
	getLoadingScreenMessage: function (success_callback, error_callback) {
		api.request(api.urls.loadingScreenMessage, {}, success_callback, error_callback);
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
	"XHS": {
		"gamemode": 2,
		"difficulty": 5,
	},
	"PW": {
		"gamemode": 4,
	},
	"FB": {
		"gamemode": 3,
	},
};

var XHS_DIFFICULTY_VOTE_STATS = {
	1: { starting_gold: 10000, ankhs: 4, bonus_item: "item_lifesteal_mask" },
	2: { starting_gold: 5000, ankhs: 3 },
	3: { starting_gold: 4000, ankhs: 2 },
	4: { starting_gold: 3000, ankhs: 1 },
	5: { starting_gold: 2000, ankhs: 0 },
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

function FormatLoadingScreenNumber(value) {
	var text = Math.floor(value || 0).toString();
	var separator = L("loading_screen_number_group_separator");
	if (separator == "loading_screen_number_group_separator") {
		separator = ",";
	}
	return text.replace(/\B(?=(\d{3})+(?!\d))/g, separator);
}

function GetDifficultyVoteExtraDescription(difficulty_index) {
	var stats = XHS_DIFFICULTY_VOTE_STATS[difficulty_index];
	if (!stats) {
		return "";
	}

	var lines = [
		LocalizeTemplate("loading_screen_vote_difficulty_starting_gold", {
			amount: FormatLoadingScreenNumber(stats.starting_gold)
		}),
		LocalizeTemplate("loading_screen_vote_difficulty_ankhs", {
			count: stats.ankhs.toString()
		})
	];

	if (stats.bonus_item) {
		lines.push(LocalizeTemplate("loading_screen_vote_difficulty_bonus_item", {
			item: GetLocalizedItemName(stats.bonus_item)
		}));
	}

	return lines.join("\n");
}

function AppendVoteDescriptionExtra(description, extra) {
	if (!extra || extra.length <= 0) {
		return description;
	}

	if (!description || description.length <= 0) {
		return extra;
	}

	return description + "\n" + extra;
}

function GetVoteOptionDescription(vote_type, vote_index, include_extra) {
	if (include_extra === undefined) {
		include_extra = true;
	}

	var option_description = LocalizeWithFallback("#vote_" + vote_type + "_" + vote_index + "_description");

	if (include_extra && vote_type == "difficulty") {
		option_description = AppendVoteDescriptionExtra(option_description, GetDifficultyVoteExtraDescription(vote_index));
	}

	return option_description;
}

function GetLocalizedItemName(item_name) {
	return LocalizeWithFallback("#DOTA_Tooltip_ability_" + item_name);
}

function CreateDifficultyVoteStat(parent, item_name, label_text, value_text, class_name) {
	var row = $.CreatePanel("Panel", parent, "");
	row.AddClass("vote-difficulty-stat-row");
	if (class_name) {
		row.AddClass(class_name);
	}

	var icon = $.CreatePanel("DOTAItemImage", row, "");
	icon.AddClass("vote-difficulty-stat-icon");
	icon.itemname = item_name;

	var copy = $.CreatePanel("Panel", row, "");
	copy.AddClass("vote-difficulty-stat-copy");

	var label = $.CreatePanel("Label", copy, "");
	label.AddClass("vote-difficulty-stat-label");
	label.text = label_text;

	var value = $.CreatePanel("Label", copy, "");
	value.AddClass("vote-difficulty-stat-value");
	value.text = value_text;
}

function CreateDifficultyVoteStats(vote_button, difficulty_index) {
	var stats = XHS_DIFFICULTY_VOTE_STATS[difficulty_index];
	if (!stats || !vote_button) {
		return;
	}

	var panels = vote_button.FindChildrenWithClassTraverse("vote-select-panel");
	var parent = panels && panels[0] ? panels[0] : null;
	if (!parent) {
		return;
	}

	var stats_panel = $.CreatePanel("Panel", parent, "");
	stats_panel.AddClass("vote-difficulty-stats");

	CreateDifficultyVoteStat(
		stats_panel,
		"item_bag_of_gold",
		L("loading_screen_vote_difficulty_starting_gold_short"),
		FormatLoadingScreenNumber(stats.starting_gold),
		"VoteDifficultyGold"
	);
	CreateDifficultyVoteStat(
		stats_panel,
		"item_ankh_of_reincarnation",
		L("loading_screen_vote_difficulty_ankhs_short"),
		stats.ankhs.toString(),
		"VoteDifficultyAnkhs"
	);

	if (stats.bonus_item == "item_lifesteal_mask") {
		CreateDifficultyVoteStat(
			stats_panel,
			stats.bonus_item,
			L("loading_screen_vote_difficulty_bonus_short"),
			GetLocalizedItemName(stats.bonus_item),
			"VoteDifficultyBonus"
		);
	}

	var buttons = parent.FindChildrenWithClassTraverse("vote-button");
	var choice_button = buttons && buttons[0] ? buttons[0] : null;
	if (choice_button && parent.MoveChildBefore) {
		parent.MoveChildBefore(stats_panel, choice_button);
	}
}

function SafeSerializeForLog(data) {
	if (data === undefined) {
		return "";
	}

	if (data === null) {
		return "null";
	}

	if (typeof data === "string") {
		return data;
	}

	try {
		return JSON.stringify(data);
	} catch (err) {
		return "<unserializable>";
	}
}

function LoadingScreenLog(scope, message, data) {
	if (!loading_screen_logs_enabled) {
		return;
	}

	var prefix = "[XHS_LOADING_HIDE][" + scope + "] " + message;
	if (data !== undefined) {
		$.Msg(prefix + " | " + SafeSerializeForLog(data));
	} else {
		$.Msg(prefix);
	}
}

function BuildSetupStatusSignature(setup_status) {
	if (!setup_status) {
		return "none";
	}

	var active_value = setup_status.active === true || setup_status.active === 1 || setup_status.active === "1" ? "1" : "0";
	var launching_value = setup_status.launching === true || setup_status.launching === 1 || setup_status.launching === "1" ? "1" : "0";
	var remaining_value = Math.max(0, Math.floor(ToNumber(setup_status.remaining_time, ToNumber(setup_status.duration, 20))));
	var ready_parts = [];

	if (setup_status.ready_players) {
		for (var key in setup_status.ready_players) {
			if (setup_status.ready_players[key] === true || setup_status.ready_players[key] === 1 || setup_status.ready_players[key] === "1") {
				ready_parts.push(key.toString());
			}
		}
	}

	ready_parts.sort();
	return "a" + active_value + "|l" + launching_value + "|t" + remaining_value + "|r" + ready_parts.join(",");
}



function GetConnectionStateDebugName(state) {
	if (state === connection_state.CONNECTED) {
		return "CONNECTED";
	}

	if (state === connection_state.LOADING) {
		return "LOADING";
	}

	if (state === connection_state.DISCONNECTED) {
		return "DISCONNECTED";
	}

	if (state === connection_state.ABANDONED) {
		return "ABANDONED";
	}

	if (state === connection_state.FAILED) {
		return "FAILED";
	}

	if (state === connection_state.NOT_YET_CONNECTED) {
		return "PENDING";
	}

	if (state === connection_state.UNKNOWN) {
		return "UNKNOWN";
	}

	return "STATE_" + state;
}

function LoadingScreenDebug(args) {
	view.text.text = view.text.text + ". \n\n" + args.text;
}

function GetCurrentTime() {
	if (typeof Game.GetGameTime === "function") {
		var game_time = Game.GetGameTime();
		if (game_time !== undefined && game_time !== null && !isNaN(game_time)) {
			return game_time;
		}
	}

	if (typeof $.Now === "function") {
		return $.Now() / 1000.0;
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

function IsToolsModeEnabled() {
	if (typeof Game.IsInToolsMode === "function") {
		return Game.IsInToolsMode();
	}

	return false;
}

function IsToolsModeLoadingSimulationEnabled() {
	return tools_mode_lobby_simulation_enabled === true;
}

function GetToolsModeLobbyElapsedSeconds() {
	if (tools_mode_lobby_sim_started_at < 0) {
		tools_mode_lobby_sim_started_at = GetCurrentTime();
	}

	return Math.max(0, GetCurrentTime() - tools_mode_lobby_sim_started_at);
}

function GetToolsModeLobbyPlayerName(index) {
	var token = "#loading_screen_tools_player_" + (index + 1);
	var localized = $.Localize(token);

	if (localized && localized != token) {
		return localized;
	}

	return "Player " + (index + 1);
}

function GetToolsModeLobbyPlayerState(player_index, elapsed_seconds) {
	var qa_mode = tools_mode_qa_mode || "normal";
	var loading_phase_base = 1.8;
	var ready_step = Math.max(0.25, tools_mode_lobby_ready_stagger);
	var last_fake_index = Math.max(0, tools_mode_lobby_player_count - 1);

	if (qa_mode === "all_loading") {
		return connection_state.LOADING;
	}

	if (qa_mode === "all_ready") {
		return connection_state.CONNECTED;
	}

	if (qa_mode === "all_loaded") {
		return connection_state.CONNECTED;
	}

	if (qa_mode === "one_failed") {
		if (player_index == last_fake_index) {
			return connection_state.FAILED;
		}
		return connection_state.CONNECTED;
	}

	if (player_index == last_fake_index) {
		var failed_time = loading_phase_base + ((last_fake_index - 1) * ready_step) + 1.4;
		if (elapsed_seconds >= failed_time) {
			return connection_state.FAILED;
		}

		return connection_state.LOADING;
	}

	var ready_time = loading_phase_base + (player_index * ready_step);
	if (elapsed_seconds >= ready_time) {
		return connection_state.CONNECTED;
	}

	return connection_state.LOADING;
}

function GetToolsModeLobbyPlayerReady(player_index, elapsed_seconds, state) {
	var qa_mode = tools_mode_qa_mode || "normal";
	var last_fake_index = Math.max(0, tools_mode_lobby_player_count - 1);

	if (qa_mode === "all_loading") {
		return false;
	}

	if (qa_mode === "all_ready") {
		return true;
	}

	if (qa_mode === "all_loaded") {
		return false;
	}

	if (qa_mode === "one_failed") {
		return player_index != last_fake_index;
	}

	return state === connection_state.CONNECTED;
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
	var requested_player_id = player_id;

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

function GetSteamIDCandidateFromPlayerInfo(player_info) {
	if (!player_info) {
		return "";
	}

	var fields = [
		"player_steamid",
		"player_steam_id",
		"steamid",
		"steam_id",
		"accountid",
		"account_id",
	];

	for (var i = 0; i < fields.length; i++) {
		var field_name = fields[i];
		var value = player_info[field_name];
		if (value !== undefined && value !== null && value.toString().trim().length > 0 && value.toString().trim() != "0") {
			return value.toString().trim();
		}
	}

	return "";
}

function GetSteamIDFromPlayerInfo(player_info, player_id) {
	var candidate = GetSteamIDCandidateFromPlayerInfo(player_info);
	var normalized = NormalizeSteamID64(candidate);
	if (normalized.length > 0) {
		return normalized;
	}

	if (player_id !== undefined && player_id >= 0 && typeof Game.GetPlayerInfo === "function") {
		var fallback_info = Game.GetPlayerInfo(player_id);
		candidate = GetSteamIDCandidateFromPlayerInfo(fallback_info);
		normalized = NormalizeSteamID64(candidate);
		if (normalized.length > 0) {
			return normalized;
		}
	}

	var local_player_id = GetLocalPlayerIDSafe();
	if (player_id !== undefined && player_id == local_player_id) {
		var local_info = Game.GetLocalPlayerInfo();
		candidate = GetSteamIDCandidateFromPlayerInfo(local_info);
		normalized = NormalizeSteamID64(candidate);
		if (normalized.length > 0) {
			return normalized;
		}
	}

	return "";
}

function GetAvatarSteamIDFromPlayerInfo(player_info, player_id) {
	var normalized = GetSteamIDFromPlayerInfo(player_info, player_id);
	if (normalized.length > 0) {
		return normalized;
	}

	var candidate = GetSteamIDCandidateFromPlayerInfo(player_info);
	if (candidate.length > 0) {
		return candidate;
	}

	if (player_id !== undefined && player_id >= 0 && typeof Game.GetPlayerInfo === "function") {
		var fallback_info = Game.GetPlayerInfo(player_id);
		candidate = GetSteamIDCandidateFromPlayerInfo(fallback_info);
		if (candidate.length > 0) {
			return candidate;
		}
	}

	return "";
}

function IsServerApiAvailable() {
	return typeof GameEvents !== "undefined" &&
		GameEvents &&
		typeof GameEvents.SendCustomGameEventToServer === "function";
}

function OnLoadingScreenApiResponse(payload) {
	if (!payload || !payload.request_id) {
		return;
	}

	var pending = api_pending_requests[payload.request_id];
	if (!pending) {
		return;
	}

	delete api_pending_requests[payload.request_id];

	if (payload.ok === true || payload.ok === 1 || payload.ok === "1") {
		pending.success(payload.data || {});
		return;
	}

	pending.error(payload.message || "");
}

function GetCustomSetupStatus() {
	var status = {};

	if (typeof CustomNetTables !== "undefined" && CustomNetTables && typeof CustomNetTables.GetTableValue === "function") {
		status = CustomNetTables.GetTableValue("game_options", "custom_setup") || {};
	}

	var signature = BuildSetupStatusSignature(status);
	if (loading_screen_last_setup_signature !== signature) {
		loading_screen_last_setup_signature = signature;
	}

	return status;
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

var SUPPORTER_TIER_COLOR_FALLBACK = {
	0: "#7db9d8",
	1: "#70e39a",
	2: "#ffcf66",
	3: "#ff5a43",
	4: "#5ad0ff",
	5: "#c99cff"
};

function IsEarthwardenSupporterData(profile_data) {
	if (!profile_data) {
		return false;
	}

	var donator_level = Math.floor(ToNumber(profile_data.donator_level, 0));
	if (donator_level == 8 || donator_level == 9) {
		return true;
	}

	var tier_name = (profile_data.tier_name || profile_data.supporter_tier_name || "").toString().toLowerCase();
	if (tier_name.indexOf("earthwarden") >= 0) {
		return true;
	}

	var tier_color = (profile_data.tier_color || profile_data.donator_color || "").toString().toLowerCase();
	return tier_color == "#c99cff";
}

function NormalizeSupporterTierID(profile_data) {
	if (!profile_data) {
		return 0;
	}

	if (IsEarthwardenSupporterData(profile_data)) {
		return 5;
	}

	var tier = Math.floor(ToNumber(profile_data.tier_id || profile_data.supporter_tier, 0));
	if (tier <= 0 && typeof DonatorStatusConverter === "function") {
		tier = Math.floor(ToNumber(DonatorStatusConverter(profile_data.donator_level), 0));
	}

	return Math.max(0, Math.min(5, tier));
}

function GetSupporterTierColor(profile_data) {
	if (!profile_data) {
		return SUPPORTER_TIER_COLOR_FALLBACK[0];
	}

	if (IsEarthwardenSupporterData(profile_data)) {
		return SUPPORTER_TIER_COLOR_FALLBACK[5];
	}

	if (profile_data.tier_color) {
		return profile_data.tier_color;
	}

	var tier = NormalizeSupporterTierID(profile_data);

	if (typeof GetDonatorColor === "function" && tier > 0) {
		return GetDonatorColor(tier);
	}

	return SUPPORTER_TIER_COLOR_FALLBACK[tier] || profile_data.donator_color || SUPPORTER_TIER_COLOR_FALLBACK[0];
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

function GetSupporterTierText(profile_data) {
	if (!profile_data) {
		return L("loading_screen_none");
	}

	if (profile_data.supporter_tier_name) {
		return profile_data.supporter_tier_name;
	}

	return GetDonatorLevelText(profile_data.donator_level);
}

function FormatXHSAccountXP(profile_data) {
	if (!profile_data || !profile_data.has_xhs_xp_data) {
		return L("loading_screen_na");
	}

	var level = Math.max(1, ToNumber(profile_data.xhs_account_level, 1));
	var text = "Level " + level;

	if (profile_data.xhs_xp_max > 0) {
		text += " - " + FormatIntegerValue(profile_data.xhs_xp_current) + " / " + FormatIntegerValue(profile_data.xhs_xp_max) + " XP";
	} else if (profile_data.xhs_xp_total > 0) {
		text += " - " + FormatIntegerValue(profile_data.xhs_xp_total) + " total XP";
	}

	return text;
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

function RequestProfilePositionForSteam(steam_id) {
}

function RequestProfilePositionForSelected() {
}

function GetProfileDataForPlayer(player_id) {
	var local_player_id = GetLocalPlayerIDSafe();
	var player_info = null;
	var player_table = {};
	var xp_current = 0;
	var xp_max = SUPPORTER_PASS_XP_PER_LEVEL;
	var has_profile_data = false;
	var has_xp_data = false;

	if (player_id >= 0) {
		player_info = Game.GetPlayerInfo(player_id);
	}

	if (!player_info && player_id == local_player_id) {
		player_info = Game.GetLocalPlayerInfo();
	}

	if (player_id >= 0) {
		player_table = CustomNetTables.GetTableValue("supporter_pass_player", player_id.toString()) || {};
	}

	for (var key in player_table) {
		has_profile_data = true;
		break;
	}

	xp_max = SUPPORTER_PASS_XP_PER_LEVEL;

	if (player_table.season_xp !== undefined) {
		xp_current = Math.max(0, ToNumber(player_table.season_xp, 0));
		has_xp_data = true;
	} else if (player_table.XP !== undefined) {
		xp_current = Math.max(0, ToNumber(player_table.XP, 0));
		has_xp_data = true;
	}

	while (xp_current >= xp_max) {
		xp_current = xp_current - xp_max;
	}

	var supporter_level = Math.max(1, ToNumber(player_table.season_level !== undefined ? player_table.season_level : player_table.Lvl, 1));
	var xhs_account_level = Math.max(0, ToNumber(player_table.xhs_account_level, 0));
	var xhs_xp_current = Math.max(0, ToNumber(player_table.xhs_xp_current, 0));
	var xhs_xp_max = Math.max(0, ToNumber(player_table.xhs_xp_max, 0));
	var xhs_xp_total = Math.max(0, ToNumber(player_table.xhs_xp, 0));
	var has_xhs_xp_data = xhs_account_level > 0 || xhs_xp_current > 0 || xhs_xp_max > 0 || xhs_xp_total > 0;

	return {
		player_id: player_id,
		steam_id: GetSteamIDFromPlayerInfo(player_info, player_id),
		player_name: GetPlayerDisplayName(player_id, player_info),
		title: "Supporter Pass",
		title_color: "#9eb0c9",
		level: supporter_level,
		xp_current: xp_current,
		xp_max: xp_max,
		has_xp_data: has_xp_data,
		xhs_account_level: xhs_account_level,
		xhs_xp_current: xhs_xp_current,
		xhs_xp_max: xhs_xp_max,
		xhs_xp_total: xhs_xp_total,
		has_xhs_xp_data: has_xhs_xp_data,
		seasonal_winrate: has_profile_data ? FormatPercentValue(player_table.winrate) : L("loading_screen_na"),
		donator_level: player_table.donator_level,
		donator_color: GetSupporterTierColor(player_table),
		supporter_tier: player_table.tier_id || player_table.supporter_tier || 0,
		supporter_tier_name: player_table.tier_name || player_table.supporter_tier_name,
		fragments: player_table.fragments || player_table.fragment_balance || 0,
		daily_fragments: player_table.daily_fragments || player_table.daily_earned || player_table.weekly_fragments || player_table.weekly_earned || 0,
		daily_cap: Math.max(1, ToNumber(player_table.daily_cap || player_table.weekly_cap, 100)),
		weekly_fragments: player_table.daily_fragments || player_table.daily_earned || player_table.weekly_fragments || player_table.weekly_earned || 0,
		weekly_cap: Math.max(1, ToNumber(player_table.daily_cap || player_table.weekly_cap, 100)),
		mmr_title: player_table.mmr_title || L("loading_screen_na"),
		connection_state: (player_info && player_info.player_connection_state !== undefined) ? player_info.player_connection_state : connection_state.NOT_YET_CONNECTED,
		toggle_tag: player_table.toggle_tag,
		player_xp: player_table.player_xp,
		winrate_toggle: player_table.winrate_toggle,
		bp_rewards: player_table.pass_rewards !== undefined ? player_table.pass_rewards : player_table.bp_rewards,
		has_profile_data: has_profile_data,
	};
}

function GetLoadingSupporterTierID(profile_data) {
	return NormalizeSupporterTierID(profile_data);
}

function GetLoadingSupporterTierLetter(profile_data) {
	var tier_text = GetSupporterTierText(profile_data);

	if (!tier_text || tier_text == L("loading_screen_none") || tier_text == L("loading_screen_na")) {
		return "";
	}

	return tier_text.toString().charAt(0).toUpperCase();
}

function FormatLoadingSeasonXP(profile_data) {
	if (!profile_data || !profile_data.has_xp_data) {
		return L("loading_screen_na");
	}

	return FormatIntegerValue(profile_data.xp_current) + " / " + FormatIntegerValue(profile_data.xp_max);
}

function FormatLoadingGlobalXP(profile_data) {
	if (!profile_data || !profile_data.has_xhs_xp_data) {
		return L("loading_screen_na");
	}

	if (profile_data.xhs_xp_max > 0) {
		return FormatIntegerValue(profile_data.xhs_xp_current) + " / " + FormatIntegerValue(profile_data.xhs_xp_max);
	}

	return FormatIntegerValue(profile_data.xhs_xp_total);
}

function FormatLoadingFragments(profile_data) {
	if (!profile_data) {
		return L("loading_screen_na");
	}

	return FormatIntegerValue(Math.max(0, ToNumber(profile_data.fragments, 0)));
}

function FormatLoadingDailyFragments(profile_data) {
	if (!profile_data) {
		return L("loading_screen_na");
	}

	return FormatIntegerValue(Math.max(0, ToNumber(profile_data.daily_fragments || profile_data.weekly_fragments, 0))) + " / " + FormatIntegerValue(Math.max(1, ToNumber(profile_data.daily_cap || profile_data.weekly_cap, 100)));
}

function GetWindowRect(panel) {
	if (!panel || typeof panel.GetPositionWithinWindow !== "function") {
		return {
			x: 0,
			y: 0,
			w: 0,
			h: 0,
		};
	}

	return {
		x: panel.GetPositionWithinWindow().x,
		y: panel.GetPositionWithinWindow().y,
		w: panel.actuallayoutwidth || panel.desiredlayoutwidth || 0,
		h: panel.actuallayoutheight || panel.desiredlayoutheight || 0,
	};
}

function CreateLoadingProfileHoverStat(parent, label_text, value_text) {
	var stat = $.CreatePanel("Panel", parent, "");
	stat.AddClass("loading-profile-hover-stat");

	var label = $.CreatePanel("Label", stat, "");
	label.AddClass("loading-profile-hover-stat-label");
	label.text = label_text;

	var value = $.CreatePanel("Label", stat, "");
	value.AddClass("loading-profile-hover-stat-value");
	value.text = value_text;

	return stat;
}

function CreateLoadingProfileHoverSeasonPass(parent, profile_data) {
	var level = Math.max(1, ToNumber(profile_data.level, 1));
	var xp_current = Math.max(0, ToNumber(profile_data.xp_current, 0));
	var xp_max = Math.max(1, ToNumber(profile_data.xp_max, SUPPORTER_PASS_XP_PER_LEVEL));
	var percent = profile_data.has_xp_data ? Math.max(0, Math.min(100, Math.floor((xp_current / xp_max) * 100))) : 0;
	var xp_text = profile_data.has_xp_data ? FormatIntegerValue(xp_current) + " / " + FormatIntegerValue(xp_max) + " XP" : L("loading_screen_na");

	var panel = $.CreatePanel("Panel", parent, "");
	panel.AddClass("loading-profile-hover-season-pass");

	var header = $.CreatePanel("Panel", panel, "");
	header.AddClass("loading-profile-hover-season-header");

	var title = $.CreatePanel("Label", header, "");
	title.AddClass("loading-profile-hover-season-title");
	title.text = "SEASON PASS";

	var level_label = $.CreatePanel("Label", header, "");
	level_label.AddClass("loading-profile-hover-season-level");
	level_label.text = "LVL " + level;

	var progress_row = $.CreatePanel("Panel", panel, "");
	progress_row.AddClass("loading-profile-hover-season-progress-row");

	var xp_label = $.CreatePanel("Label", progress_row, "");
	xp_label.AddClass("loading-profile-hover-season-xp");
	xp_label.text = xp_text;

	var percent_label = $.CreatePanel("Label", progress_row, "");
	percent_label.AddClass("loading-profile-hover-season-percent");
	percent_label.text = profile_data.has_xp_data ? percent + "%" : "--";

	var track = $.CreatePanel("Panel", panel, "");
	track.AddClass("loading-profile-hover-season-track");

	var fill = $.CreatePanel("Panel", track, "");
	fill.AddClass("loading-profile-hover-season-fill");
	fill.style.width = percent + "%";

	var meta = $.CreatePanel("Panel", panel, "");
	meta.AddClass("loading-profile-hover-season-meta");

	var fragments = $.CreatePanel("Label", meta, "");
	fragments.AddClass("loading-profile-hover-season-chip");
	fragments.text = "Fragments " + FormatLoadingFragments(profile_data);

	var daily = $.CreatePanel("Label", meta, "");
	daily.AddClass("loading-profile-hover-season-chip");
	daily.AddClass("Right");
	daily.text = "Daily " + FormatLoadingDailyFragments(profile_data);

	return panel;
}

function EnsurePlayerLoadingProfileHover() {
	if (player_loading_profile_hover && player_loading_profile_hover.IsValid && player_loading_profile_hover.IsValid()) {
		return player_loading_profile_hover;
	}

	var root = $.GetContextPanel();
	player_loading_profile_hover = $.CreatePanel("Panel", root, "PlayerLoadingProfileHover");
	player_loading_profile_hover.AddClass("loading-profile-hover");
	player_loading_profile_hover.hittest = false;
	player_loading_profile_hover.hittestchildren = false;

	return player_loading_profile_hover;
}

function FillPlayerLoadingProfileHover(player_id) {
	var hover = EnsurePlayerLoadingProfileHover();
	var profile_data = GetProfileDataForPlayer(player_id);
	var tier_id = GetLoadingSupporterTierID(profile_data);
	var tier_text = GetSupporterTierText(profile_data);
	var tier_color = GetSupporterTierColor(profile_data);

	hover.RemoveAndDeleteChildren();
	hover.SetHasClass("PlayerLoadingDonatorTier1", tier_id == 1);
	hover.SetHasClass("PlayerLoadingDonatorTier2", tier_id == 2);
	hover.SetHasClass("PlayerLoadingDonatorTier3", tier_id == 3);
	hover.SetHasClass("PlayerLoadingDonatorTier4", tier_id == 4);
	hover.SetHasClass("PlayerLoadingDonatorTier5", tier_id == 5);

	var header = $.CreatePanel("Panel", hover, "");
	header.AddClass("loading-profile-hover-header");

	var avatar = $.CreatePanel("DOTAAvatarImage", header, "");
	avatar.AddClass("loading-profile-hover-avatar");
	avatar.hittest = false;
	var steam_id = profile_data.steam_id ? profile_data.steam_id.toString() : "";
	if (steam_id.length > 0) {
		avatar.steamid = steam_id;
	}

	var identity = $.CreatePanel("Panel", header, "");
	identity.AddClass("loading-profile-hover-identity");

	var eyebrow = $.CreatePanel("Label", identity, "");
	eyebrow.AddClass("loading-profile-hover-eyebrow");
	eyebrow.text = "SUPPORTER PROFILE";

	var name = $.CreatePanel("Label", identity, "");
	name.AddClass("loading-profile-hover-name");
	name.text = profile_data.player_name || L("loading_screen_na");

	var tier = $.CreatePanel("Label", identity, "");
	tier.AddClass("loading-profile-hover-tier");
	tier.text = tier_text;
	tier.style.color = tier_color;

	CreateLoadingProfileHoverSeasonPass(hover, profile_data);

	var grid = $.CreatePanel("Panel", hover, "");
	grid.AddClass("loading-profile-hover-grid");

	CreateLoadingProfileHoverStat(grid, "XHS Level", Math.max(0, ToNumber(profile_data.xhs_account_level, 0)).toString());
	CreateLoadingProfileHoverStat(grid, "Global XP", FormatLoadingGlobalXP(profile_data));
	CreateLoadingProfileHoverStat(grid, "Fragments", FormatLoadingFragments(profile_data));
	CreateLoadingProfileHoverStat(grid, "Winrate", profile_data.seasonal_winrate || L("loading_screen_na"));
	CreateLoadingProfileHoverStat(grid, "Daily Cap", FormatLoadingDailyFragments(profile_data));
	CreateLoadingProfileHoverStat(grid, "Rank", profile_data.mmr_title || L("loading_screen_na"));

	var status = $.CreatePanel("Label", hover, "");
	status.AddClass("loading-profile-hover-status");
	status.text = tier_id > 0 ? "Active supporter benefits enabled" : "No active supporter tier";

	hover.style.border = "1px solid " + tier_color + "88";
}

function PositionPlayerLoadingProfileHover(anchor_panel) {
	var hover = EnsurePlayerLoadingProfileHover();
	var root = $.GetContextPanel();
	var root_rect = GetWindowRect(root);
	var anchor_rect = GetWindowRect(anchor_panel);
	var hover_width = Math.max(hover.actuallayoutwidth || hover.desiredlayoutwidth || 0, 352);
	var hover_height = Math.max(hover.actuallayoutheight || hover.desiredlayoutheight || 0, 300);
	var margin = 10;
	var x = anchor_rect.x - root_rect.x - hover_width - margin;
	var y = anchor_rect.y - root_rect.y - 18;
	var max_y = Math.max(0, root_rect.h - hover_height - margin);

	if (x < margin) {
		x = anchor_rect.x - root_rect.x + anchor_rect.w + margin;
	}

	y = Math.max(margin, Math.min(max_y, y));
	hover.style.position = x + "px " + y + "px 0px";
}

function ShowPlayerLoadingProfileHover(player_id, anchor_panel) {
	if (player_id === undefined || player_id === null || player_id < 0) {
		return;
	}

	player_loading_profile_hover_player_id = player_id;
	FillPlayerLoadingProfileHover(player_id);
	PositionPlayerLoadingProfileHover(anchor_panel);

	var hover = EnsurePlayerLoadingProfileHover();
	hover.SetHasClass("PlayerLoadingProfileHoverVisible", true);
	$.Schedule(0.01, function () {
		if (player_loading_profile_hover_player_id == player_id && hover && hover.IsValid && hover.IsValid()) {
			PositionPlayerLoadingProfileHover(anchor_panel);
		}
	});
}

function HidePlayerLoadingProfileHover() {
	player_loading_profile_hover_player_id = -1;

	if (player_loading_profile_hover && player_loading_profile_hover.IsValid && player_loading_profile_hover.IsValid()) {
		player_loading_profile_hover.SetHasClass("PlayerLoadingProfileHoverVisible", false);
	}
}

function GetLeaderboardTextForSteam(steam_id) {
	if (!steam_id) {
		return L("loading_screen_unavailable");
	}

	return L("loading_screen_na");
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
	var summary_card = $("#ProfileSummaryCard");
	var modal_avatar = $("#ProfileModalAvatar");
	var summary_name = $("#ProfileSummaryName");
	var summary_title = $("#ProfileSummaryTitle");
	var summary_level = $("#ProfileSummaryLevel");
	var summary_donator = $("#ProfileSummaryWinrate");
	var summary_xp_wrap = $("#ProfileSummaryXPWrap");
	var summary_xp_progress = $("#ProfileSummaryXPProgress");
	var summary_xp_text = $("#ProfileSummaryXPText");
	var profile_modal = $("#ProfileModal");

	if (summary_avatar) {
		summary_avatar.steamid = local_data.steam_id ? local_data.steam_id : "0";
	}

	var local_tier_id = GetLoadingSupporterTierID(local_data);
	if (summary_card) {
		summary_card.SetHasClass("ProfileSummaryDonator", local_tier_id > 0);
		summary_card.SetHasClass("PlayerLoadingDonatorTier1", local_tier_id == 1);
		summary_card.SetHasClass("PlayerLoadingDonatorTier2", local_tier_id == 2);
		summary_card.SetHasClass("PlayerLoadingDonatorTier3", local_tier_id == 3);
		summary_card.SetHasClass("PlayerLoadingDonatorTier4", local_tier_id == 4);
		summary_card.SetHasClass("PlayerLoadingDonatorTier5", local_tier_id == 5);
	}

	if (summary_avatar) {
		summary_avatar.SetHasClass("ProfileSummaryDonatorAvatar", local_tier_id > 0);
		summary_avatar.style.border = local_tier_id > 0 ? ("1px solid " + local_data.donator_color + "cc") : "1px solid #d5b87866";
	}

	if (modal_avatar) {
		modal_avatar.steamid = selected_data.steam_id ? selected_data.steam_id : "0";
	}

	var selected_tier_id = GetLoadingSupporterTierID(selected_data);
	if (profile_modal) {
		profile_modal.SetHasClass("PlayerLoadingDonatorTier1", selected_tier_id == 1);
		profile_modal.SetHasClass("PlayerLoadingDonatorTier2", selected_tier_id == 2);
		profile_modal.SetHasClass("PlayerLoadingDonatorTier3", selected_tier_id == 3);
		profile_modal.SetHasClass("PlayerLoadingDonatorTier4", selected_tier_id == 4);
		profile_modal.SetHasClass("PlayerLoadingDonatorTier5", selected_tier_id == 5);
	}

	if (modal_avatar) {
		modal_avatar.style.border = selected_tier_id > 0 ? ("1px solid " + selected_data.donator_color + "cc") : "1px solid #62ceff66";
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

	if (summary_donator) {
		summary_donator.text = GetSupporterTierText(local_data);
		summary_donator.style.color = local_data.donator_color ? local_data.donator_color : "#f1e3c3";
	}

	if (summary_xp_progress) {
		summary_xp_progress.value = local_data.has_xp_data ? Clamp01(local_data.xp_current / Math.max(1, local_data.xp_max)) : 0;
	}

	if (summary_xp_text) {
		summary_xp_text.text = local_data.has_xp_data ? ("Season XP " + FormatIntegerValue(local_data.xp_current) + " / " + FormatIntegerValue(local_data.xp_max)) : "";
	}

	if (summary_xp_wrap) {
		summary_xp_wrap.SetHasClass("HasXPData", local_data.has_xp_data === true);
		(function (panel, data) {
			panel.SetPanelEvent("onmouseover", function () {
				if (data.has_xp_data) {
					var tooltip = "Supporter Pass: Level " + data.level + " - " + FormatIntegerValue(data.xp_current) + " / " + FormatIntegerValue(data.xp_max) + " XP";
					if (data.has_xhs_xp_data) {
						tooltip += "\nXHS Account: " + FormatXHSAccountXP(data);
					}
					$.DispatchEvent("UIShowTextTooltip", panel, tooltip);
				}
			});

			panel.SetPanelEvent("onmouseout", function () {
				$.DispatchEvent("UIHideTextTooltip", panel);
			});
		})(summary_xp_wrap, local_data);
	}

	var modal_name = selected_data.player_name;
	if (selected_data.player_id >= 0 && selected_data.player_id == local_player_id) {
		modal_name = modal_name + " " + L("loading_screen_you_suffix");
	}

	SafeSetText("ProfileModalName", modal_name);
	SafeSetText("ProfileModalSubtitle", selected_data.steam_id ? LocalizeTemplate("loading_screen_steam_id", { steam_id: selected_data.steam_id }) : L("loading_screen_steam_id_unavailable"));
	SafeSetText("ProfileModalLevelValue", selected_data.level.toString());
	SafeSetText("ProfileModalXPValue", selected_data.has_xp_data ? (FormatIntegerValue(selected_data.xp_current) + " / " + FormatIntegerValue(selected_data.xp_max)) : L("loading_screen_na"));
	SafeSetText("ProfileModalXHSXPValue", FormatXHSAccountXP(selected_data));
	SafeSetText("ProfileModalTitleValue", selected_data.title);
	SafeSetText("ProfileModalWinrateValue", selected_data.seasonal_winrate);
	SafeSetText("ProfileModalDonatorValue", GetSupporterTierText(selected_data));
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

	var profile_signature =
		"local:" + local_data.player_id +
		"|selected:" + selected_data.player_id +
		"|steam:" + selected_data.steam_id +
		"|title:" + selected_data.title +
		"|level:" + selected_data.level +
		"|conn:" + GetConnectionStateDebugName(selected_data.connection_state) +
		"|can_open_steam:" + (selected_data.steam_id.length > 0 ? "1" : "0");

	if (loading_screen_last_profile_signature !== profile_signature) {
		loading_screen_last_profile_signature = profile_signature;
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

function PlayLoadingSound(event_names) {
	if (!LOADING_SCREEN_CONFIG.audio.enabled) {
		return;
	}

	if (!event_names) {
		return;
	}

	var events = event_names;
	if (!(events instanceof Array)) {
		events = [events];
	}

	for (var i = 0; i < events.length; i++) {
		var event_name = events[i];
		if (!event_name || event_name.length <= 0) {
			continue;
		}

		try {
			if (typeof Game.EmitSound === "function") {
				Game.EmitSound(event_name);
				return;
			}
		} catch (err_emit) {
		}

		try {
			$.DispatchEvent("PlaySoundEffect", event_name);
			return;
		} catch (err_dispatch) {
		}
	}
}

function ShowReadyToast(message_token) {
	var toast = $("#ReadyToast");
	var toast_label = $("#ReadyToastLabel");
	if (!toast) {
		return;
	}

	if (toast_label && message_token) {
		toast_label.text = L(message_token);
	}

	ready_toast_token = ready_toast_token + 1;
	var token = ready_toast_token;

	toast.SetHasClass("ReadyToastVisible", true);
	$.Schedule(LOADING_SCREEN_CONFIG.ready.toast_duration_seconds, function () {
		if (token !== ready_toast_token || !toast) {
			return;
		}

		toast.SetHasClass("ReadyToastVisible", false);
	});
}

function OnWebsiteButtonPressed() {
	OpenExternalURL(LOADING_SCREEN_CONFIG.links.website);
}

function OnPatreonButtonPressed() {
	OpenExternalURL(LOADING_SCREEN_CONFIG.links.patreon);
}

function OnDiscordButtonPressed() {
	OpenExternalURL(LOADING_SCREEN_CONFIG.links.discord);
}

function OnArtworkCreditPressed() {
	OpenExternalURL(LOADING_SCREEN_CONFIG.links.artwork_instagram);
}

function ToggleLoadingQaPanel() {
	loading_screen_qa_panel_visible = !loading_screen_qa_panel_visible;
	UpdateLoadingQaPanelState();
}

function SetToolsQaMode(mode) {
	if (!mode || mode.length <= 0) {
		mode = "normal";
	}

	tools_mode_qa_mode = mode;
	if (mode === "normal") {
		tools_mode_lobby_sim_started_at = -1;
	}

	custom_setup_failed_state = false;
	loading_screen_last_global_status_key = "";
	for (var row_key in player_loading_rows) {
		if (player_loading_rows[row_key]) {
			player_loading_rows[row_key].row_visual_signature = "";
		}
	}

	UpdateLoadingQaPanelState();
	UpdatePlayerLoadingSidebar();
}

function UpdateLoadingQaPanelState() {
	var qa_toggle = $("#LoadingQaToggleButton");
	var qa_panel = $("#LoadingQaPanel");
	var qa_allowed = LOADING_SCREEN_CONFIG.qa.enabled && IsToolsModeEnabled() && IsToolsModeLoadingSimulationEnabled();

	if (qa_toggle) {
		qa_toggle.style.visibility = qa_allowed ? "visible" : "collapse";
		qa_toggle.SetHasClass("IsActive", qa_allowed && loading_screen_qa_panel_visible);
	}

	if (qa_panel) {
		qa_panel.style.visibility = qa_allowed && loading_screen_qa_panel_visible ? "visible" : "collapse";
	}
}

function UpdateBottomTabTagline(panel_index) {
	var tagline_label = $("#BottomTabTagline");
	var tagline_wrap = $("#BottomTabTaglineWrap");
	if (!tagline_label) {
		return;
	}

	var token = LOADING_SCREEN_CONFIG.taglines[panel_index] || "";
	if (!token || token.length <= 0) {
		if (tagline_wrap) {
			tagline_wrap.style.visibility = "collapse";
		}
		return;
	}

	if (tagline_wrap) {
		tagline_wrap.style.visibility = "visible";
	}

	tagline_label.text = L(token);
}

function OpenProfileSteamPage() {
	var selected_data = GetProfileDataForPlayer(GetSelectedProfilePlayerID());

	if (selected_data.steam_id) {
		OpenExternalURL("https://steamcommunity.com/profiles/" + selected_data.steam_id);
		return;
	}

	var local_info = Game.GetLocalPlayerInfo();
	var local_steam_id64 = GetSteamIDFromPlayerInfo(local_info, GetLocalPlayerIDSafe());

	if (local_steam_id64) {
		OpenExternalURL("https://steamcommunity.com/profiles/" + local_steam_id64);
		return;
	}

	if (typeof DOTAShowProfilePage === "function") {
		DOTAShowProfilePage(0);
	}
}

function OnCustomSetupReadyPressed() {

	if (custom_setup_failed_state) {
		PlayLoadingSound(LOADING_SCREEN_CONFIG.audio.failed_events);
		return;
	}

	var local_player_id = GetLocalPlayerIDSafe();

	if (local_player_id < 0) {
		return;
	}

	if (typeof GameEvents !== "undefined" && GameEvents && typeof GameEvents.SendCustomGameEventToServer === "function") {
		GameEvents.SendCustomGameEventToServer("custom_setup_ready", { PlayerID: local_player_id });
		local_ready_click_pending = true;
		local_ready_click_token = local_ready_click_token + 1;
		var pending_token = local_ready_click_token;
		ShowReadyToast("loading_screen_ready_toast");
		PlayLoadingSound(LOADING_SCREEN_CONFIG.audio.ready_click_events);
		UpdatePlayerLoadingSidebar();
		$.Schedule(LOADING_SCREEN_CONFIG.ready.immediate_lock_fallback_seconds, function () {
			if (pending_token !== local_ready_click_token) {
				return;
			}

			if (!local_ready_click_pending) {
				return;
			}

			local_ready_click_pending = false;
			UpdatePlayerLoadingSidebar();
		});
	} else {
	}
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

function GetTeamConstant(name, fallback_value) {
	if (typeof DOTATeam_t !== "undefined" && DOTATeam_t && DOTATeam_t[name] !== undefined) {
		return DOTATeam_t[name];
	}

	return fallback_value;
}

function GetDefaultFriendlyTeamID() {
	return GetTeamConstant("DOTA_TEAM_GOODGUYS", 2);
}

function GetDefaultEnemyTeamID() {
	return GetTeamConstant("DOTA_TEAM_BADGUYS", 3);
}

function GetOppositeCoreTeamID(team_id) {
	var goodguys = GetDefaultFriendlyTeamID();
	var badguys = GetDefaultEnemyTeamID();

	if (team_id == goodguys) {
		return badguys;
	}

	if (team_id == badguys) {
		return goodguys;
	}

	return badguys;
}

function GetPlayerTeamIDFromInfo(player_info, fallback_team_id) {
	var fallback = fallback_team_id;
	if (fallback === undefined || fallback === null) {
		fallback = GetDefaultFriendlyTeamID();
	}

	if (!player_info) {
		return fallback;
	}

	var raw_team_id = player_info.player_team_id;
	if (raw_team_id === undefined || raw_team_id === null) {
		raw_team_id = player_info.team_id;
	}

	var parsed_team_id = parseInt(raw_team_id);
	if (isNaN(parsed_team_id)) {
		return fallback;
	}

	return parsed_team_id;
}

function GetToolsModeLobbyTeamID(player_index, local_team_id) {
	var friendly_team_id = local_team_id;
	// Tools-mode QA: keep every simulated player in the same team as local player.
	return friendly_team_id;
}

function GetTeamSectionKey(team_id) {
	return "team_" + team_id;
}

function GetTeamSortPriority(team_id, local_team_id) {
	if (team_id == local_team_id) {
		return 0;
	}

	return 1 + team_id;
}

function GetTeamDisplayName(team_id) {
	var goodguys = GetDefaultFriendlyTeamID();
	var badguys = GetDefaultEnemyTeamID();

	if (team_id == goodguys) {
		var radiant = LocalizeWithFallback("#DOTA_GoodGuys");
		return radiant == "DOTA_GoodGuys" ? "Radiant" : radiant;
	}

	if (team_id == badguys) {
		var dire = LocalizeWithFallback("#DOTA_BadGuys");
		return dire == "DOTA_BadGuys" ? "Dire" : dire;
	}

	var details = null;
	if (typeof Game.GetTeamDetails === "function") {
		details = Game.GetTeamDetails(team_id);
	}

	if (details && details.team_name && details.team_name.length > 0) {
		return details.team_name;
	}

	return "Team " + team_id;
}

function NormalizePlayerDisplayName(raw_name) {
	if (raw_name === undefined || raw_name === null) {
		return "";
	}

	var text = "";
	try {
		text = raw_name.toString();
	} catch (err) {
		return "";
	}

	text = text.replace(/\s+/g, " ").trim();
	if (text.length <= 0) {
		return "";
	}

	var lowered = text.toLowerCase();
	if (
		lowered == "unnamed" ||
		lowered == "unnamed player" ||
		lowered == "unknown" ||
		lowered == "null" ||
		lowered == "undefined" ||
		lowered == "n/a" ||
		lowered == "na"
	) {
		return "";
	}

	return text;
}

function GetPlayerDisplayName(player_id, player_info) {
	// $.Msg(player_info);
	var resolved_name = NormalizePlayerDisplayName(player_info && player_info.player_name);
	if (resolved_name.length > 0) {
		return resolved_name;
	}

	if (player_id !== undefined && player_id >= 0 && typeof Players !== "undefined" && typeof Players.GetPlayerName === "function") {
		resolved_name = NormalizePlayerDisplayName(Players.GetPlayerName(player_id));
		if (resolved_name.length > 0) {
			return resolved_name;
		}
	}

	if (player_id !== undefined && player_id >= 0 && typeof Game.GetPlayerInfo === "function") {
		var info_fallback = Game.GetPlayerInfo(player_id);
		resolved_name = NormalizePlayerDisplayName(info_fallback && info_fallback.player_name);
		if (resolved_name.length > 0) {
			return resolved_name;
		}
	}

	var local_player_id = GetLocalPlayerIDSafe();
	if (player_id == local_player_id || player_id < 0) {
		var local_info = Game.GetLocalPlayerInfo();
		resolved_name = NormalizePlayerDisplayName(local_info && local_info.player_name);
		if (resolved_name.length > 0) {
			return resolved_name;
		}
	}

	return L("loading_screen_player");
}

function BuildToolsModeLoadingEntries() {
	if (!IsToolsModeLoadingSimulationEnabled()) {
		if (tools_mode_last_lobby_signature !== "disabled") {
			tools_mode_last_lobby_signature = "disabled";
		}
		return [];
	}

	if (!IsToolsModeEnabled() && tools_mode_last_lobby_signature !== "no_tools_flag") {
		tools_mode_last_lobby_signature = "no_tools_flag";
	}

	var elapsed_seconds = GetToolsModeLobbyElapsedSeconds();
	var entries = [];
	var local_player_id = GetLocalPlayerIDSafe();
	var local_info = local_player_id >= 0 ? Game.GetPlayerInfo(local_player_id) : null;

	if (!local_info) {
		local_info = Game.GetLocalPlayerInfo();
	}

	var local_team_id = GetPlayerTeamIDFromInfo(local_info, GetDefaultFriendlyTeamID());

	for (var i = 0; i < tools_mode_lobby_player_count; i++) {
		var player_state = GetToolsModeLobbyPlayerState(i, elapsed_seconds);

		entries.push({
			key: "tools_sim_player_" + i,
			state: player_state,
			name: GetToolsModeLobbyPlayerName(i),
			is_marked_ready: GetToolsModeLobbyPlayerReady(i, elapsed_seconds, player_state),
			team_id: GetToolsModeLobbyTeamID(i, local_team_id),
		});
	}

	var tools_signature = "";
	for (var e = 0; e < entries.length; e++) {
		tools_signature = tools_signature + "|" + entries[e].key + ":" + entries[e].team_id + ":" + GetConnectionStateDebugName(entries[e].state) + ":" + (entries[e].is_marked_ready ? "1" : "0");
	}
	tools_signature = "mode:" + (tools_mode_qa_mode || "normal") + tools_signature;

	if (tools_mode_last_lobby_signature !== tools_signature) {
		tools_mode_last_lobby_signature = tools_signature;
	}

	return entries;
}

function UpdatePlayerLoadingSidebar() {
	try {
	const list_parent = $("#PlayerLoadingList");
	const title_label = $("#PlayerLoadingTitle");
	const counter = $("#PlayerLoadingCounter");
	const progress_bar = $("#PlayerLoadingProgress");
	const waiting_label = $("#PlayerLoadingWaiting");
	const global_status_label = $("#PlayerLoadingGlobalStatus");
	const force_launch_label = $("#PlayerForceLaunchLabel");
	const ready_button = $("#PlayerReadyButton");
	const ready_button_label = $("#PlayerReadyButtonLabel");
	const setup_status = GetCustomSetupStatus();
	const is_tools_mode = IsToolsModeEnabled();
	const tools_simulation_enabled = IsToolsModeLoadingSimulationEnabled();
	const setup_active = IsCustomSetupStatusActive(setup_status);
	const setup_launching = setup_status && (setup_status.launching === true || setup_status.launching === 1 || setup_status.launching === "1");
	const setup_remaining = Math.max(0, Math.floor(ToNumber(setup_status.remaining_time, ToNumber(setup_status.duration, 20))));
	const local_player_id = GetLocalPlayerIDSafe();
	let local_player_ready = local_player_id >= 0 ? IsPlayerMarkedReady(setup_status, local_player_id) : false;
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

	if (tools_simulation_enabled) {
		player_ids = local_player_id >= 0 ? [local_player_id] : [];
	} else if (local_player_id >= 0 && player_ids.indexOf(local_player_id) < 0) {
		player_ids.push(local_player_id);
	}

	player_ids = player_ids.slice(0).sort(function (a, b) { return a - b; });

	var local_player_info = local_player_id >= 0 ? Game.GetPlayerInfo(local_player_id) : null;
	if (!local_player_info) {
		local_player_info = Game.GetLocalPlayerInfo();
	}
	var local_team_id = GetPlayerTeamIDFromInfo(local_player_info, GetDefaultFriendlyTeamID());

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
			team_id: GetPlayerTeamIDFromInfo(player_info, local_team_id),
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
				player_team_id: tools_entry.team_id,
			},
			display_name: tools_entry.name,
			team_id: tools_entry.team_id,
			is_marked_ready: tools_entry.is_marked_ready === true,
			can_open_profile: false,
			is_tools_debug: true,
		});
	}

	const active_rows = {};
	const active_sections = {};
	const section_counts = {};
	let total_players = 0;
	let loaded_players = 0;
	let waiting_players = 0;
	let issue_players = 0;

	for (var entry_seed = 0; entry_seed < player_entries.length; entry_seed++) {
		const seeded_entry = player_entries[entry_seed];
		const seeded_state = seeded_entry.player_info.player_connection_state;
		const seeded_team_id = seeded_entry.team_id !== undefined ? seeded_entry.team_id : GetPlayerTeamIDFromInfo(seeded_entry.player_info, local_team_id);
		const seeded_team_key = GetTeamSectionKey(seeded_team_id);

		seeded_entry.connection_state = seeded_state;
		seeded_entry.team_id = seeded_team_id;
		seeded_entry.team_key = seeded_team_key;
		seeded_entry.team_priority = GetTeamSortPriority(seeded_team_id, local_team_id);

		section_counts[seeded_team_key] = (section_counts[seeded_team_key] || 0) + 1;
	}

	player_entries.sort(function (a, b) {
		if (a.team_priority != b.team_priority) {
			return a.team_priority - b.team_priority;
		}

		if (a.can_open_profile != b.can_open_profile) {
			return a.can_open_profile ? -1 : 1;
		}

		var name_a = (a.display_name !== undefined && a.display_name !== null) ? a.display_name.toString() : "";
		var name_b = (b.display_name !== undefined && b.display_name !== null) ? b.display_name.toString() : "";

		if (name_a < name_b) {
			return -1;
		}

		if (name_a > name_b) {
			return 1;
		}

		return 0;
	});

	var order_signature = "";
	for (var sig_i = 0; sig_i < player_entries.length; sig_i++) {
		order_signature = order_signature + "|" + player_entries[sig_i].row_key + ":" + player_entries[sig_i].team_key;
	}
	for (var section_count_key in section_counts) {
		order_signature = order_signature + "|" + section_count_key + ":" + section_counts[section_count_key];
	}

	if (player_loading_order_signature != order_signature) {
		var old_order_signature = player_loading_order_signature;
		var display_rows = [];
		for (var display_i = 0; display_i < player_entries.length; display_i++) {
			var display_entry = player_entries[display_i];
			display_rows.push(display_entry.display_name + ":" + GetConnectionStateDebugName(display_entry.connection_state) + ":" + GetTeamDisplayName(display_entry.team_id));
		}

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
		const team_id = entry.team_id;
		const team_key = entry.team_key;
		const is_loaded = IsLoadedConnectionState(state);
		const is_issue = IsIssueConnectionState(state);
		const is_connecting = !is_loaded && !is_issue;

		if (!active_sections[team_key]) {
			active_sections[team_key] = true;

			if (!player_loading_section_rows[team_key]) {
				var section_row = $.CreatePanel("Label", list_parent, "PlayerLoadingSection_" + team_key);
				section_row.AddClass("player-loading-section");
				player_loading_section_rows[team_key] = section_row;
			}

			player_loading_section_rows[team_key].text = GetTeamDisplayName(team_id) + " (" + (section_counts[team_key] || 0) + ")";
		}

		total_players = total_players + 1;
		active_rows[row_key] = true;

		if (is_loaded) {
			loaded_players = loaded_players + 1;
		} else if (is_connecting) {
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

			const avatar_wrap = $.CreatePanel("Panel", row, "");
			avatar_wrap.AddClass("player-loading-avatar-wrap");
			avatar_wrap.style.width = "24px";
			avatar_wrap.style.height = "24px";
			avatar_wrap.style.marginRight = "8px";
			avatar_wrap.style.border = "1px solid #d5b87855";
			avatar_wrap.style.backgroundColor = "#04060b";
			avatar_wrap.style.verticalAlign = "center";
			avatar_wrap.style.flowChildren = "none";
			avatar_wrap.style.overflow = "clip clip";
			avatar_wrap.hittest = true;
			avatar_wrap.hittestchildren = false;

			const avatar = $.CreatePanel("DOTAAvatarImage", avatar_wrap, "");
			avatar.style.width = "100%";
			avatar.style.height = "100%";
			avatar.style.verticalAlign = "center";
			avatar.hittest = false;

			const avatar_fallback = $.CreatePanel("Panel", avatar_wrap, "");
			avatar_fallback.AddClass("player-loading-avatar-fallback");
			avatar_fallback.style.width = "100%";
			avatar_fallback.style.height = "100%";
			avatar_fallback.style.backgroundColor = "#0d1420";
			avatar_fallback.style.border = "1px solid #ffffff10";
			avatar_fallback.style.flowChildren = "none";
			avatar_fallback.style.visibility = "collapse";
			avatar_fallback.hittest = false;
			var avatar_fallback_label = $.CreatePanel("Label", avatar_fallback, "");
			avatar_fallback_label.text = "?";
			avatar_fallback_label.style.width = "100%";
			avatar_fallback_label.style.height = "100%";
			avatar_fallback_label.style.textAlign = "center center";
			avatar_fallback_label.style.verticalAlign = "center";
			avatar_fallback_label.style.fontSize = "16px";
			avatar_fallback_label.style.color = "#9eb0c9";
			avatar_fallback_label.style.fontFamily = "Reaver";
			avatar_fallback_label.hittest = false;

			const initial_avatar_steam_id = entry.can_open_profile ? GetAvatarSteamIDFromPlayerInfo(player_info, player_id) : "";
			if (initial_avatar_steam_id && initial_avatar_steam_id.length > 0) {
				avatar.steamid = initial_avatar_steam_id;
				avatar.style.visibility = "visible";
				avatar_fallback.style.visibility = "collapse";
			} else {
				avatar.steamid = "0";
				avatar.style.visibility = "collapse";
				avatar_fallback.style.visibility = "visible";
			}

			const supporter_badge = $.CreatePanel("Panel", row, "");
			supporter_badge.AddClass("player-loading-supporter-badge");
			supporter_badge.hittest = false;
			const supporter_badge_label = $.CreatePanel("Label", supporter_badge, "");
			supporter_badge_label.AddClass("player-loading-supporter-badge-label");
			supporter_badge_label.hittest = false;

			const name = $.CreatePanel("Label", row, "");
			name.AddClass("player-loading-name");

			const status_label = $.CreatePanel("Label", row, "");
			status_label.AddClass("player-loading-state");

			player_loading_rows[row_key] = {
				panel: row,
				dot: dot,
				spinner: spinner,
				avatar_wrap: avatar_wrap,
				avatar: avatar,
				avatar_fallback: avatar_fallback,
				supporter_badge: supporter_badge,
				supporter_badge_label: supporter_badge_label,
				name: name,
				status: status_label,
				player_id: player_id,
			};

		}

		const player_row = player_loading_rows[row_key];
		player_row.player_id = player_id;
		if (player_row.avatar_wrap) {
			player_row.avatar_wrap.AddClass("player-loading-avatar-wrap");
			player_row.avatar_wrap.hittest = true;
			player_row.avatar_wrap.hittestchildren = false;
		}
		if (player_row.avatar_fallback) {
			player_row.avatar_fallback.AddClass("player-loading-avatar-fallback");
			player_row.avatar_fallback.hittest = false;
		}
		if (player_row.avatar) {
			player_row.avatar.hittest = false;
		}
		const is_marked_ready = (player_id >= 0 && IsPlayerMarkedReady(setup_status, player_id))
			|| (tools_simulation_enabled && entry.is_tools_debug === true && entry.is_marked_ready === true);
		const is_selected = player_id >= 0 && player_id == GetSelectedProfilePlayerID();

		if (!player_row.spinner) {
			player_row.spinner = $.CreatePanel("Panel", player_row.panel, "");
			player_row.spinner.AddClass("player-loading-spinner");
		}

		if (!player_row.avatar) {
			player_row.avatar_wrap = $.CreatePanel("Panel", player_row.panel, "");
			player_row.avatar_wrap.AddClass("player-loading-avatar-wrap");
			player_row.avatar_wrap.style.width = "24px";
			player_row.avatar_wrap.style.height = "24px";
			player_row.avatar_wrap.style.marginRight = "8px";
			player_row.avatar_wrap.style.border = "1px solid #d5b87855";
			player_row.avatar_wrap.style.backgroundColor = "#04060b";
			player_row.avatar_wrap.style.verticalAlign = "center";
			player_row.avatar_wrap.style.flowChildren = "none";
			player_row.avatar_wrap.style.overflow = "clip clip";
			player_row.avatar_wrap.hittest = true;
			player_row.avatar_wrap.hittestchildren = false;

			player_row.avatar = $.CreatePanel("DOTAAvatarImage", player_row.avatar_wrap, "");
			player_row.avatar.style.width = "100%";
			player_row.avatar.style.height = "100%";
			player_row.avatar.style.verticalAlign = "center";
			player_row.avatar.hittest = false;

			player_row.avatar_fallback = $.CreatePanel("Panel", player_row.avatar_wrap, "");
			player_row.avatar_fallback.AddClass("player-loading-avatar-fallback");
			player_row.avatar_fallback.style.width = "100%";
			player_row.avatar_fallback.style.height = "100%";
			player_row.avatar_fallback.style.backgroundColor = "#0d1420";
			player_row.avatar_fallback.style.border = "1px solid #ffffff10";
			player_row.avatar_fallback.style.flowChildren = "none";
			player_row.avatar_fallback.style.visibility = "collapse";
			player_row.avatar_fallback.hittest = false;

			var fallback_label = $.CreatePanel("Label", player_row.avatar_fallback, "");
			fallback_label.text = "?";
			fallback_label.style.width = "100%";
			fallback_label.style.height = "100%";
			fallback_label.style.textAlign = "center center";
			fallback_label.style.verticalAlign = "center";
			fallback_label.style.fontSize = "16px";
			fallback_label.style.color = "#9eb0c9";
			fallback_label.style.fontFamily = "Reaver";
			fallback_label.hittest = false;
		}

		if (!player_row.supporter_badge) {
			player_row.supporter_badge = $.CreatePanel("Panel", player_row.panel, "");
			player_row.supporter_badge.AddClass("player-loading-supporter-badge");
			player_row.supporter_badge.hittest = false;
			if (player_row.panel.MoveChildBefore) {
				player_row.panel.MoveChildBefore(player_row.supporter_badge, player_row.name);
			}
			player_row.supporter_badge_label = $.CreatePanel("Label", player_row.supporter_badge, "");
			player_row.supporter_badge_label.AddClass("player-loading-supporter-badge-label");
			player_row.supporter_badge_label.hittest = false;
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

		(function (avatar_anchor, target_player_id) {
			avatar_anchor.SetPanelEvent("onmouseover", function () {
				$.DispatchEvent("UIHideTextTooltip", avatar_anchor);
				ShowPlayerLoadingProfileHover(target_player_id, avatar_anchor);
			});

			avatar_anchor.SetPanelEvent("onmouseout", function () {
				HidePlayerLoadingProfileHover();
			});
		})(player_row.avatar_wrap, player_id);

		const profile_data = GetProfileDataForPlayer(player_id);
		const supporter_tier_id = GetLoadingSupporterTierID(profile_data);
		const supporter_tier_color = GetSupporterTierColor(profile_data);
		const supporter_badge_text = GetLoadingSupporterTierLetter(profile_data);

		const status_text = is_marked_ready ? L("loading_screen_ready") : GetConnectionStateText(state);
		const row_visual_signature = [
			state,
			is_loaded ? "1" : "0",
			is_issue ? "1" : "0",
			is_connecting ? "1" : "0",
			is_selected ? "1" : "0",
			is_marked_ready ? "1" : "0",
			entry.can_open_profile ? "1" : "0",
			entry.is_tools_debug ? "1" : "0",
			supporter_tier_id.toString(),
			supporter_tier_color,
			supporter_badge_text,
			status_text,
		].join("|");

		if (player_row.row_visual_signature !== row_visual_signature) {
			player_row.row_visual_signature = row_visual_signature;
			player_row.panel.SetHasClass("PlayerLoadingReady", is_loaded);
			player_row.panel.SetHasClass("PlayerLoadingWaiting", !is_loaded);
			player_row.panel.SetHasClass("PlayerLoadingIssue", is_issue);
			player_row.panel.SetHasClass("PlayerLoadingConnecting", is_connecting);
			player_row.panel.SetHasClass("PlayerLoadingSelected", is_selected);
			player_row.panel.SetHasClass("PlayerMarkedReady", is_marked_ready);
			player_row.panel.SetHasClass("PlayerLoadingInteractive", entry.can_open_profile);
			player_row.panel.SetHasClass("PlayerLoadingStatic", !entry.can_open_profile);
			player_row.panel.SetHasClass("PlayerLoadingToolsDebug", entry.is_tools_debug);
			player_row.panel.SetHasClass("PlayerLoadingDonator", supporter_tier_id > 0);
			player_row.panel.SetHasClass("PlayerLoadingDonatorTier1", supporter_tier_id == 1);
			player_row.panel.SetHasClass("PlayerLoadingDonatorTier2", supporter_tier_id == 2);
			player_row.panel.SetHasClass("PlayerLoadingDonatorTier3", supporter_tier_id == 3);
			player_row.panel.SetHasClass("PlayerLoadingDonatorTier4", supporter_tier_id == 4);
			player_row.panel.SetHasClass("PlayerLoadingDonatorTier5", supporter_tier_id == 5);

			player_row.dot.SetHasClass("PlayerLoadingReady", is_loaded);
			player_row.dot.SetHasClass("PlayerLoadingWaiting", !is_loaded);
			player_row.dot.SetHasClass("PlayerLoadingIssue", is_issue);
			player_row.dot.style.visibility = is_connecting ? "collapse" : "visible";

			player_row.spinner.style.visibility = is_connecting ? "visible" : "collapse";
			player_row.status.text = status_text;

			if (player_row.supporter_badge) {
				player_row.supporter_badge.SetHasClass("PlayerLoadingSupporterBadgeVisible", supporter_tier_id > 0);
				player_row.supporter_badge.SetHasClass("PlayerLoadingDonatorTier1", supporter_tier_id == 1);
				player_row.supporter_badge.SetHasClass("PlayerLoadingDonatorTier2", supporter_tier_id == 2);
				player_row.supporter_badge.SetHasClass("PlayerLoadingDonatorTier3", supporter_tier_id == 3);
				player_row.supporter_badge.SetHasClass("PlayerLoadingDonatorTier4", supporter_tier_id == 4);
				player_row.supporter_badge.SetHasClass("PlayerLoadingDonatorTier5", supporter_tier_id == 5);
				player_row.supporter_badge.style.border = "1px solid " + supporter_tier_color + "cc";
			}

			if (player_row.supporter_badge_label) {
				player_row.supporter_badge_label.text = supporter_badge_text;
				player_row.supporter_badge_label.style.color = supporter_tier_color;
			}
		}

		const avatar_steam_id = entry.can_open_profile ? GetAvatarSteamIDFromPlayerInfo(player_info, player_id) : "";
		const row_identity_signature = [
			entry.display_name || "",
			avatar_steam_id || "0",
		].join("|");

		if (player_row.row_identity_signature !== row_identity_signature) {
			player_row.row_identity_signature = row_identity_signature;

			if (avatar_steam_id && avatar_steam_id.length > 0) {
				player_row.avatar.steamid = avatar_steam_id;
				player_row.avatar.style.visibility = "visible";
				if (player_row.avatar_fallback) {
					player_row.avatar_fallback.style.visibility = "collapse";
				}
			} else {
				player_row.avatar.steamid = "0";
				player_row.avatar.style.visibility = "collapse";
				if (player_row.avatar_fallback) {
					player_row.avatar_fallback.style.visibility = "visible";
				}
			}

			player_row.name.text = entry.display_name;
		}
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

	const loaded_counter_text = LocalizeTemplate("loading_screen_loaded_counter", {
		loaded: loaded_players.toString(),
		total: total_players.toString(),
	});

	if (counter) {
		counter.text = loaded_counter_text;
		counter.style.visibility = "collapse";
	}

	if (progress_bar) {
		progress_bar.value = total_players > 0 ? Clamp01(loaded_players / total_players) : 0;
	}

	const all_players_loaded = total_players > 0 && loaded_players >= total_players;
	const has_connection_failures = issue_players > 0;
	custom_setup_failed_state = has_connection_failures;
	const has_any_failure = custom_setup_failed_state;

	if (local_player_ready && local_ready_click_pending) {
		local_ready_click_pending = false;
	}

	const local_player_ready_effective = local_player_ready || local_ready_click_pending;

	if (title_label) {
		var players_title_text = L("loading_screen_players");
		if (!players_title_text || players_title_text == "loading_screen_players" || players_title_text == "#loading_screen_players") {
			players_title_text = "PLAYERS";
		}
		title_label.text = players_title_text.toUpperCase() + " " + loaded_counter_text.toUpperCase();
	}

	if (title_label) {
		title_label.SetHasClass("PlayerLoadingTitleFailed", has_any_failure);
	}

	var global_status_key = "loading";
	var global_status_token = "loading_screen_status_loading";

	if (has_any_failure) {
		global_status_key = "failed";
		global_status_token = "loading_screen_status_failed";
	} else if (all_players_loaded) {
		global_status_key = "all_ready";
		global_status_token = "loading_screen_status_all_ready";
	}

	if (global_status_label) {
		if (global_status_key === "failed") {
			global_status_label.style.visibility = "collapse";
		} else {
			global_status_label.style.visibility = "visible";
			global_status_label.text = L(global_status_token);
		}

		global_status_label.SetHasClass("StatusLoading", global_status_key === "loading");
		global_status_label.SetHasClass("StatusAllReady", global_status_key === "all_ready");
		global_status_label.SetHasClass("StatusFailed", global_status_key === "failed");
	}

	if (loading_screen_last_global_status_key !== global_status_key) {
		if (loading_screen_last_global_status_key !== "") {
			if (global_status_key === "all_ready") {
				PlayLoadingSound(LOADING_SCREEN_CONFIG.audio.all_ready_events);
			} else if (global_status_key === "failed") {
				PlayLoadingSound(LOADING_SCREEN_CONFIG.audio.failed_events);
			}
		}
		loading_screen_last_global_status_key = global_status_key;
	}

	if (waiting_label) {
		if (all_players_loaded || total_players <= 0 || has_any_failure || waiting_players <= 0) {
			waiting_label.style.visibility = "collapse";
		} else {
			waiting_label.style.visibility = "visible";
			waiting_label.text = LocalizeTemplate("loading_screen_waiting_counter", { count: waiting_players.toString() });
		}
	}

	if (force_launch_label) {
		if (setup_active) {
			force_launch_label.style.visibility = "visible";
			force_launch_label.text = has_any_failure ? L("loading_screen_failed_returning_lobby") : LocalizeTemplate("loading_screen_match_starts_in", { seconds: setup_remaining.toString() });
		} else if (setup_launching) {
			force_launch_label.style.visibility = "visible";
			force_launch_label.text = has_any_failure ? L("loading_screen_failed_returning_lobby") : L("loading_screen_launching_match");
		} else {
			force_launch_label.style.visibility = "collapse";
		}
	}

	if (ready_button) {
		const can_show_ready = setup_active && local_player_id >= 0 && (local_player_eligible || tools_simulation_enabled);
		const ready_locked_by_failure = has_any_failure;
		ready_button.style.visibility = can_show_ready ? "visible" : "collapse";
		ready_button.enabled = can_show_ready && !local_player_ready_effective && !ready_locked_by_failure;
		ready_button.SetHasClass("IsReady", local_player_ready_effective);
		ready_button.SetHasClass("IsDisabled", can_show_ready && (local_player_ready_effective || ready_locked_by_failure));
		ready_button.SetHasClass("IsFailedLock", can_show_ready && ready_locked_by_failure);

		if (ready_button_label) {
			ready_button_label.text = local_player_ready_effective ? L("loading_screen_ready") : L("loading_screen_mark_ready");
		}
	}

	var sidebar_summary_signature =
		"p" + total_players +
		"|l" + loaded_players +
		"|w" + waiting_players +
		"|i" + issue_players +
		"|active:" + (setup_active ? "1" : "0") +
		"|launching:" + (setup_launching ? "1" : "0") +
		"|remaining:" + setup_remaining +
		"|local_ready:" + (local_player_ready_effective ? "1" : "0") +
		"|failed_lock:" + (custom_setup_failed_state ? "1" : "0");

	if (loading_screen_last_sidebar_summary_signature !== sidebar_summary_signature) {
		loading_screen_last_sidebar_summary_signature = sidebar_summary_signature;
	}

	$.Schedule(0.2, UpdatePlayerLoadingSidebar);
	} catch (err) {
		$.Schedule(0.5, UpdatePlayerLoadingSidebar);
	}
}

function GetBottomModCells() {
	var track = $("#BottomModsTrack");
	if (!track || typeof track.GetChildCount !== "function") {
		return [];
	}

	var cells = [];
	var child_count = track.GetChildCount();

	for (var i = 0; i < child_count; i++) {
		var child = track.GetChild(i);
		if (child && child.BHasClass && child.BHasClass("mod-cell")) {
			cells.push(child);
		}
	}

	return cells;
}

function GetBottomModsVisibleCount() {
	var root = $.GetContextPanel();

	if (root && root.BHasClass && root.BHasClass("AspectRatio4x3")) {
		return 2;
	}

	if (root && root.BHasClass && root.BHasClass("AspectRatio21x9")) {
		return 4;
	}

	return 3;
}

function GetBottomModsPageCount(item_count, visible_count) {
	if (visible_count <= 0) {
		return 1;
	}

	return Math.max(1, Math.ceil(item_count / visible_count));
}

function GetBottomModsTrack() {
	return $("#BottomModsTrack");
}

function IsBottomModsTabActive() {
	return bottom_tab_current_panel_index == 1;
}

function ResetBottomModsAutoScroll(reset_page) {
	bottom_mods_auto_elapsed = 0;

	if (reset_page === true && bottom_mods_current_page != 0) {
		SetBottomModsPage(0, 0);
	}
}

function AutoAdvanceBottomModsCarousel(delta, is_paused) {
	if (!IsBottomModsTabActive()) {
		bottom_mods_auto_elapsed = 0;
		return;
	}

	var cells = GetBottomModCells();
	var visible_count = GetBottomModsVisibleCount();
	var page_count = GetBottomModsPageCount(cells.length, visible_count);

	if (page_count <= 1) {
		bottom_mods_auto_elapsed = 0;
		return;
	}

	if (is_paused) {
		return;
	}

	var page_interval = bottom_tab_auto_interval / page_count;
	if (page_interval <= 0) {
		page_interval = bottom_tab_auto_interval;
	}

	bottom_mods_auto_elapsed = bottom_mods_auto_elapsed + Math.max(0, delta);

	while (bottom_mods_auto_elapsed >= page_interval) {
		bottom_mods_auto_elapsed = bottom_mods_auto_elapsed - page_interval;
		SetBottomModsPage((bottom_mods_current_page + 1) % page_count, 1);
	}
}

function ClearBottomModsTransitionClasses(track) {
	if (!track) {
		return;
	}

	track.SetHasClass("IsCarouselOutLeft", false);
	track.SetHasClass("IsCarouselOutRight", false);
	track.SetHasClass("IsCarouselInFromLeft", false);
	track.SetHasClass("IsCarouselInFromRight", false);
}

function SetBottomModsPage(target_page, direction) {
	var cells = GetBottomModCells();
	var visible_count = GetBottomModsVisibleCount();
	var page_count = GetBottomModsPageCount(cells.length, visible_count);
	var clamped_page = Math.max(0, Math.min(page_count - 1, target_page));
	var animate_direction = direction || 0;

	if (clamped_page == bottom_mods_current_page) {
		return false;
	}

	var track = GetBottomModsTrack();
	if (!track || animate_direction == 0) {
		bottom_mods_current_page = clamped_page;
		UpdateBottomModsCarousel();
		return true;
	}

	bottom_mods_transition_token = bottom_mods_transition_token + 1;
	var transition_token = bottom_mods_transition_token;
	ClearBottomModsTransitionClasses(track);
	track.SetHasClass(animate_direction > 0 ? "IsCarouselOutLeft" : "IsCarouselOutRight", true);

	$.Schedule(bottom_mods_transition_duration * 0.5, function () {
		if (transition_token != bottom_mods_transition_token) {
			return;
		}

		bottom_mods_current_page = clamped_page;
		UpdateBottomModsCarousel();
		ClearBottomModsTransitionClasses(track);
		track.SetHasClass(animate_direction > 0 ? "IsCarouselInFromRight" : "IsCarouselInFromLeft", true);

		$.Schedule(0.01, function () {
			if (transition_token != bottom_mods_transition_token) {
				return;
			}

			ClearBottomModsTransitionClasses(track);
		});
	});

	return true;
}

function UpdateBottomModsCarousel() {
	var cells = GetBottomModCells();
	var visible_count = GetBottomModsVisibleCount();
	var page_count = GetBottomModsPageCount(cells.length, visible_count);

	if (bottom_mods_current_page < 0) {
		bottom_mods_current_page = 0;
	}

	if (bottom_mods_current_page >= page_count) {
		bottom_mods_current_page = page_count - 1;
	}

	var start_index = bottom_mods_current_page * visible_count;
	var end_index = start_index + visible_count;
	for (var i = 0; i < cells.length; i++) {
		var is_visible = i >= start_index && i < end_index;
		cells[i].SetHasClass("IsHiddenByCarousel", !is_visible);
		cells[i].style.visibility = is_visible ? "visible" : "collapse";
	}

	var prev_button = $("#BottomModsPrev");
	var next_button = $("#BottomModsNext");
	var can_go_prev = bottom_mods_current_page > 0;
	var can_go_next = bottom_mods_current_page < page_count - 1;
	var should_show_arrows = cells.length > visible_count;

	if (prev_button) {
		prev_button.enabled = should_show_arrows && can_go_prev;
		prev_button.SetHasClass("IsDisabled", !should_show_arrows || !can_go_prev);
		prev_button.style.visibility = should_show_arrows ? "visible" : "collapse";
	}

	if (next_button) {
		next_button.enabled = should_show_arrows && can_go_next;
		next_button.SetHasClass("IsDisabled", !should_show_arrows || !can_go_next);
		next_button.style.visibility = should_show_arrows ? "visible" : "collapse";
	}
}

function ShiftBottomMods(direction) {
	var cells = GetBottomModCells();
	var visible_count = GetBottomModsVisibleCount();
	var page_count = GetBottomModsPageCount(cells.length, visible_count);
	var target_page = bottom_mods_current_page + (direction < 0 ? -1 : 1);

	if (target_page < 0) {
		target_page = 0;
	}

	if (target_page >= page_count) {
		target_page = page_count - 1;
	}

	if (target_page == bottom_mods_current_page) {
		return;
	}

	bottom_mods_auto_elapsed = 0;
	SetBottomModsPage(target_page, direction < 0 ? -1 : 1);
	ResetBottomTabAutoTimer();
}

function InitializeBottomModsCarousel() {
	bottom_mods_current_page = 0;
	bottom_mods_auto_elapsed = 0;
	bottom_mods_transition_token = bottom_mods_transition_token + 1;
	ClearBottomModsTransitionClasses(GetBottomModsTrack());
	UpdateBottomModsCarousel();
	$.Schedule(0.1, UpdateBottomModsCarousel);
}

function GetBottomTabPanels() {
	var container = $.GetContextPanel().FindChildrenWithClassTraverse("bottom-footer-container");

	if (!container || !container[0]) {
		return [];
	}

	var root = container[0];
	var panels = [];
	var panel_count = 0;

	if (typeof root.GetChildCount === "function") {
		panel_count = root.GetChildCount();
	}

	for (var i = 0; i < panel_count; i++) {
		var child = root.GetChild(i);
		if (!child) {
			continue;
		}

		child.AddClass("bottom-tab-panel");
		panels.push(child);
	}

	return panels;
}

function GetBottomTabRotationPosition(panel_index) {
	for (var i = 0; i < bottom_tab_rotation_order.length; i++) {
		if (bottom_tab_rotation_order[i] == panel_index) {
			return i;
		}
	}

	return -1;
}

function GetBottomTabTargetRadio(panel_index) {
	if (panel_index == 3) {
		return $("#BottomRadioDiscord");
	}

	if (panel_index == 2) {
		return $("#BottomRadioPatreon");
	}

	if (panel_index == 1) {
		return $("#BottomRadioCustomGames");
	}

	return null;
}

function UpdateBottomTabHeader(panel_index) {
	var radios = [
		$("#BottomRadioDiscord"),
		$("#BottomRadioPatreon"),
		$("#BottomRadioCustomGames"),
	];
	var target_radio = GetBottomTabTargetRadio(panel_index);

	for (var i = 0; i < radios.length; i++) {
		var radio = radios[i];
		if (!radio) {
			continue;
		}

		var is_target = radio == target_radio;
		radio.checked = is_target;
		radio.SetHasClass("BottomRadioManualSelected", is_target);

		if (typeof radio.SetSelected === "function") {
			radio.SetSelected(is_target);
		}
	}

	UpdateBottomTabTagline(panel_index);

}

function GetNextBottomTabPanelIndex() {
	var current_position = GetBottomTabRotationPosition(bottom_tab_current_panel_index);
	if (current_position < 0) {
		return bottom_tab_rotation_order[0];
	}

	return bottom_tab_rotation_order[(current_position + 1) % bottom_tab_rotation_order.length];
}

function UpdateBottomTabCountdownLabel(seconds_remaining, is_paused, hide_label) {
	var timer_label = $("#BottomTabCountdown");
	var timer_wrap = $("#BottomTabCountdownWrap");

	if (!timer_label) {
		return;
	}

	if (hide_label) {
		timer_label.style.visibility = "collapse";
		if (timer_wrap) {
			timer_wrap.style.visibility = "collapse";
		}
		return;
	}

	if (timer_wrap) {
		timer_wrap.style.visibility = "visible";
		timer_wrap.SetHasClass("IsPausedByMouse", is_paused);
	}

	timer_label.style.visibility = "visible";
	var timer_text = LocalizeTemplate("loading_screen_tab_timer", {
		seconds: Math.max(0, Math.ceil(seconds_remaining)).toString(),
	});

	if (!timer_text || timer_text == "loading_screen_tab_timer" || timer_text == "#loading_screen_tab_timer") {
		timer_text = Math.max(0, Math.ceil(seconds_remaining)).toString() + "s";
	}

	timer_label.text = timer_text;
	timer_label.SetHasClass("IsPausedByMouse", is_paused);
}

function ResetBottomTabAutoTimer() {
	bottom_tab_countdown_remaining = bottom_tab_auto_interval;
	bottom_tab_last_tick_time = GetCurrentTime();
	UpdateBottomTabCountdownLabel(bottom_tab_countdown_remaining, false, false);
}

function ResetBottomTabAutoTimerForFooterHover() {
	bottom_tab_countdown_remaining = bottom_tab_auto_interval;
	bottom_tab_last_tick_time = GetCurrentTime();
	UpdateBottomTabCountdownLabel(bottom_tab_countdown_remaining, true, false);
}

function InitializeBottomFooterMouseTracking() {
	var footer_panel = $("#BottomFooterRoot");
	if (!footer_panel) {
		return;
	}

	footer_panel.SetPanelEvent("onmouseover", function () {
		bottom_tab_mouse_over_footer = true;
		bottom_tab_last_mouse_move_time = GetCurrentTime();
		ResetBottomTabAutoTimerForFooterHover();
	});

	footer_panel.SetPanelEvent("onmouseout", function () {
		bottom_tab_mouse_over_footer = false;
		bottom_tab_last_mouse_move_time = -1;
		ResetBottomTabAutoTimer();
	});

	footer_panel.SetPanelEvent("onmousemove", function () {
		var now = GetCurrentTime();
		bottom_tab_mouse_over_footer = true;
		bottom_tab_last_mouse_move_time = now;
		ResetBottomTabAutoTimerForFooterHover();
	});
}

function AutoRotateBottomTabs() {
	var panels = GetBottomTabPanels();
	var has_rotation = panels && panels.length > 1;
	var now = GetCurrentTime();

	if (bottom_tab_last_tick_time < 0 || now < bottom_tab_last_tick_time) {
		bottom_tab_last_tick_time = now;
	}

	var delta = Math.max(0, now - bottom_tab_last_tick_time);
	bottom_tab_last_tick_time = now;

	if (!has_rotation) {
		UpdateBottomTabCountdownLabel(bottom_tab_countdown_remaining, false, true);
		if (loading_screen_last_bottom_tab_countdown_bucket !== -999) {
			loading_screen_last_bottom_tab_countdown_bucket = -999;
		}
		$.Schedule(bottom_tab_auto_tick_interval, AutoRotateBottomTabs);
		return;
	}

	var mouse_moving_now = bottom_tab_mouse_over_footer;

	if (mouse_moving_now) {
		bottom_tab_countdown_remaining = bottom_tab_auto_interval;
	} else {
		bottom_tab_countdown_remaining = Math.max(0, bottom_tab_countdown_remaining - delta);
	}

	if (loading_screen_last_footer_mouse_state !== mouse_moving_now) {
		loading_screen_last_footer_mouse_state = mouse_moving_now;
	}

	UpdateBottomTabCountdownLabel(bottom_tab_countdown_remaining, mouse_moving_now, false);
	AutoAdvanceBottomModsCarousel(delta, mouse_moving_now);

	if (bottom_tab_countdown_remaining <= 0) {
		SwitchTab(GetNextBottomTabPanelIndex(), true);
		bottom_tab_countdown_remaining = bottom_tab_auto_interval;
		UpdateBottomTabCountdownLabel(bottom_tab_countdown_remaining, false, false);
	}

	$.Schedule(bottom_tab_auto_tick_interval, AutoRotateBottomTabs);
}

function InitializeBottomTabs() {
	var panels = GetBottomTabPanels();

	if (!panels || panels.length <= 0) {
		return;
	}

	bottom_tab_current_panel_index = -1;
	SwitchTab(bottom_tab_rotation_order[0], true);
	ResetBottomTabAutoTimer();
}

function SwitchTab(count, is_auto) {
	var panels = GetBottomTabPanels();
	var switched_by_auto = is_auto === true;

	if (!panels || panels.length <= 0) {
		return;
	}

	var target_panel_index = parseInt(count);
	if (isNaN(target_panel_index) || target_panel_index < 1 || target_panel_index > panels.length) {
		target_panel_index = bottom_tab_rotation_order[0];
	}


	var previous_panel_index = bottom_tab_current_panel_index;
	var has_previous = previous_panel_index >= 1 && previous_panel_index <= panels.length;

	if (!has_previous || previous_panel_index == target_panel_index) {
		for (var i = 0; i < panels.length; i++) {
			var panel = panels[i];
			var is_target = i == (target_panel_index - 1);

			panel.SetHasClass("IsActive", is_target);
			panel.SetHasClass("IsLeavingLeft", false);
			panel.SetHasClass("IsLeavingRight", false);
			panel.SetHasClass("IsEnteringFromLeft", false);
			panel.SetHasClass("IsEnteringFromRight", false);
			panel.style.visibility = is_target ? "visible" : "collapse";
		}

		bottom_tab_current_panel_index = target_panel_index;
		UpdateBottomTabHeader(target_panel_index);

		if (target_panel_index == 1) {
			ResetBottomModsAutoScroll(true);
		}

		if (!switched_by_auto) {
			ResetBottomTabAutoTimer();
		}

		return;
	}

	bottom_tab_transition_token = bottom_tab_transition_token + 1;
	var transition_token = bottom_tab_transition_token;
	var previous_panel = panels[previous_panel_index - 1];
	var target_panel = panels[target_panel_index - 1];

	for (var j = 0; j < panels.length; j++) {
		if (j == (previous_panel_index - 1) || j == (target_panel_index - 1)) {
			continue;
		}

		panels[j].SetHasClass("IsActive", false);
		panels[j].SetHasClass("IsLeavingLeft", false);
		panels[j].SetHasClass("IsLeavingRight", false);
		panels[j].SetHasClass("IsEnteringFromLeft", false);
		panels[j].SetHasClass("IsEnteringFromRight", false);
		panels[j].style.visibility = "collapse";
	}

	var previous_order = GetBottomTabRotationPosition(previous_panel_index);
	var target_order = GetBottomTabRotationPosition(target_panel_index);
	var move_forward = true;

	if (previous_order >= 0 && target_order >= 0) {
		var diff = target_order - previous_order;
		var last_step = bottom_tab_rotation_order.length - 1;

		if (diff == 1 || diff == -last_step) {
			move_forward = true;
		} else if (diff == -1 || diff == last_step) {
			move_forward = false;
		} else {
			move_forward = diff > 0;
		}
	} else {
		move_forward = target_panel_index > previous_panel_index;
	}

	previous_panel.style.visibility = "visible";
	previous_panel.SetHasClass("IsActive", false);
	previous_panel.SetHasClass("IsLeavingLeft", move_forward);
	previous_panel.SetHasClass("IsLeavingRight", !move_forward);
	previous_panel.SetHasClass("IsEnteringFromLeft", false);
	previous_panel.SetHasClass("IsEnteringFromRight", false);

	target_panel.style.visibility = "visible";
	target_panel.SetHasClass("IsActive", false);
	target_panel.SetHasClass("IsLeavingLeft", false);
	target_panel.SetHasClass("IsLeavingRight", false);
	target_panel.SetHasClass("IsEnteringFromRight", move_forward);
	target_panel.SetHasClass("IsEnteringFromLeft", !move_forward);

	$.Schedule(0.01, function () {
		if (transition_token != bottom_tab_transition_token) {
			return;
		}

		target_panel.SetHasClass("IsActive", true);
		target_panel.SetHasClass("IsEnteringFromRight", false);
		target_panel.SetHasClass("IsEnteringFromLeft", false);
	});

	$.Schedule(bottom_tab_transition_duration, function () {
		if (transition_token != bottom_tab_transition_token) {
			return;
		}

		previous_panel.style.visibility = "collapse";
		previous_panel.SetHasClass("IsLeavingLeft", false);
		previous_panel.SetHasClass("IsLeavingRight", false);
	});

	bottom_tab_current_panel_index = target_panel_index;
	UpdateBottomTabHeader(target_panel_index);

	if (target_panel_index == 1) {
		ResetBottomModsAutoScroll(true);
	}

	if (!switched_by_auto) {
		ResetBottomTabAutoTimer();
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
		if (loading_screen_last_fetch_stage !== "waiting_map_info") {
			loading_screen_last_fetch_stage = "waiting_map_info";
		}
		$.Schedule(0.1, fetch);
		return;
	}

	game_options = CustomNetTables.GetTableValue("game_options", "game_version");
	// $.Msg(game_options.game_type)
	if (game_options == undefined) {
		if (loading_screen_last_fetch_stage !== "waiting_game_options") {
			loading_screen_last_fetch_stage = "waiting_game_options";
		}
		$.Schedule(0.1, fetch);
		return;
	}

	if (!IsServerApiAvailable()) {
		if (loading_screen_last_fetch_stage !== "waiting_server_api") {
			loading_screen_last_fetch_stage = "waiting_server_api";
		}
		$.Schedule(0.1, fetch);
		return;
	}

	if (loading_screen_last_fetch_stage !== "ready") {
		loading_screen_last_fetch_stage = "ready";
	}

	RequestProfilePositionForSelected();

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
	if (active_vote_sequence.length <= 0) {
		ToggleVoteContainer(false);
		return;
	}

	var current_category = active_vote_sequence[active_vote_index];
	if (vote_type == current_category) {
		active_vote_index = active_vote_index + 1;
	}

	if (active_vote_index < active_vote_sequence.length) {
		ShowCurrentVoteCategory();
		return;
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

function SetVoteContentTitle(vote_type) {
	const vote_title = $.GetContextPanel().FindChildrenWithClassTraverse("vote-content-title");

	if (vote_title && vote_title[0]) {
		vote_title[0].text = LocalizeWithFallback("#vote_" + vote_type);
	}
}

function SetVoteCategoryVisible(vote_type, visible) {
	const parent = $("#vote_" + vote_type);

	if (parent) {
		parent.visible = visible;
	}

	const vote_label_container = $("#vote-label-container");
	if (!vote_label_container) {
		return;
	}

	const labels = vote_label_container.FindChildrenWithClassTraverse("label_" + vote_type + "_reset") || [];
	for (var i = 0; i < labels.length; i++) {
		labels[i].visible = visible;
	}
}

function ShowOnlyVoteCategory(vote_type) {
	const vote_content = $("#VoteContent");

	if (!vote_content) {
		return;
	}

	const vote_children = vote_content.Children();
	for (var i = 0; i < vote_children.length; i++) {
		var child = vote_children[i];
		child.visible = child.id == ("vote_" + vote_type);
	}

	for (var j = 0; j < active_vote_sequence.length; j++) {
		SetVoteCategoryVisible(active_vote_sequence[j], active_vote_sequence[j] == vote_type);
	}

	SetVoteContentTitle(vote_type);
}

function ShowCurrentVoteCategory() {
	if (active_vote_index < 0 || active_vote_index >= active_vote_sequence.length) {
		ToggleVoteContainer(false);
		return;
	}

	ShowOnlyVoteCategory(active_vote_sequence[active_vote_index]);
}

function SetVoteSummaryValue(panel_id, category, vote_index) {
	var panel = $("#" + panel_id);

	if (!panel) {
		return;
	}

	var has_selection = vote_index !== undefined && vote_index !== null && !isNaN(parseInt(vote_index));
	if (!has_selection) {
		panel.text = L("loading_screen_not_selected");
		panel.SetHasClass("HasSelection", false);
		panel.SetHasClass("IsConfirmed", false);
		return;
	}

	var parsed_vote = parseInt(vote_index);
	var vote_weight = GetLocalVoteWeight(category, parsed_vote);
	var vote_weight_text = vote_weight > 0 ? " +" + vote_weight : "";
	panel.text = LocalizeWithFallback("#vote_" + category + "_" + parsed_vote) + vote_weight_text;
	panel.SetHasClass("HasSelection", true);
	panel.SetHasClass("IsConfirmed", local_vote_confirmed[category] === true);
}

function UpdateVoteSelectionSummary() {
	SetVoteSummaryValue("VoteSelectionGamemode", "gamemode", local_votes["gamemode"]);
	SetVoteSummaryValue("VoteSelectionDifficulty", "difficulty", local_votes["difficulty"]);
}

function GetVoteCategoryCount(category) {
	if (game_options && game_options.game_type && vote_array[game_options.game_type] && vote_array[game_options.game_type][category]) {
		return vote_array[game_options.game_type][category];
	}

	return 0;
}

function FormatVoteCountText(count) {
	var vote_word = count > 1 ? L("loading_screen_vote_word_plural") : L("loading_screen_vote_word_single");
	return count + " " + vote_word;
}

function GetVoteProgressModel(category) {
	var vote_count = GetVoteCategoryCount(category);
	var vote_counter = GetVoteCounterFromTable(vote_payload_cache[category] || {});
	var leader_index = 0;
	var leader_count = 0;
	var total_votes = 0;
	var details = [];
	var options = [];

	for (var i = 1; i <= vote_count; i++) {
		var count = vote_counter[i] ? vote_counter[i] : 0;
		var option_name = LocalizeWithFallback("#vote_" + category + "_" + i);
		total_votes += count;
		details.push(option_name + ": " + count);

		if (count > leader_count) {
			leader_count = count;
			leader_index = i;
		}
	}

	var leader_text = L("loading_screen_no_votes");
	if (total_votes > 0 && leader_index > 0) {
		leader_text = LocalizeWithFallback("#vote_" + category + "_" + leader_index) + " (" + FormatVoteCountText(leader_count) + ")";
	}

	for (var j = 1; j <= vote_count; j++) {
		var option_count = vote_counter[j] ? vote_counter[j] : 0;
		options.push({
			index: j,
			name: LocalizeWithFallback("#vote_" + category + "_" + j),
			count: option_count,
			percent: total_votes > 0 ? (option_count / total_votes) * 100 : 0,
			is_leader: total_votes > 0 && j == leader_index
		});
	}

	return {
		leader: leader_text,
		detail: details.join(" / "),
		total: total_votes,
		options: options
	};
}

function UpdateVoteProgressTab(category, root_id, rows_id) {
	var root = $("#" + root_id);
	if (!root) {
		return;
	}

	var vote_count = GetVoteCategoryCount(category);
	root.visible = vote_count > 0;

	if (vote_count <= 0) {
		return;
	}

	var model = GetVoteProgressModel(category);
	var rows = $("#" + rows_id);

	if (rows) {
		rows.RemoveAndDeleteChildren();
		for (var i = 0; i < model.options.length; i++) {
			var option = model.options[i];
			var row = $.CreatePanel("Panel", rows, rows_id + "_" + option.index);
			row.AddClass("vote-progress-option-row");
			row.SetHasClass("IsWinning", option.is_leader);
			row.SetHasClass("IsSelected", parseInt(local_votes[category]) == option.index);
			row.SetHasClass("IsConfirmed", parseInt(local_votes[category]) == option.index && local_vote_confirmed[category] === true);

			var top_line = $.CreatePanel("Panel", row, "");
			top_line.AddClass("vote-progress-option-topline");

			var name = $.CreatePanel("Label", top_line, "");
			name.AddClass("vote-progress-option-name");
			name.text = option.name;

			var count = $.CreatePanel("Label", top_line, "");
			count.AddClass("vote-progress-option-count");
			count.text = FormatVoteCountText(option.count);

			var bar = $.CreatePanel("ProgressBar", row, rows_id + "_" + option.index + "_Progress");
			bar.AddClass("vote-progress-option-bar");
			bar.value = Math.max(0, Math.min(1, option.percent / 100));

			(function (panel, vote_type, index) {
				panel.SetPanelEvent("onmouseover", function () {
					$.DispatchEvent("UIShowTextTooltip", panel, GetVoteOptionDescription(vote_type, index));
				});

				panel.SetPanelEvent("onmouseout", function () {
					$.DispatchEvent("UIHideTextTooltip", panel);
				});
			})(row, category, option.index);
		}
	}

	root.SetHasClass("IsActive", active_vote_sequence[active_vote_index] == category);
}

function UpdateVoteProgressTabs() {
	UpdateVoteProgressTab("gamemode", "VoteProgressGamemode", "VoteProgressGamemodeRows");
	UpdateVoteProgressTab("difficulty", "VoteProgressDifficulty", "VoteProgressDifficultyRows");
}

function ShowVoteProgressCategory(category) {
	if (GetVoteCategoryCount(category) <= 0) {
		return;
	}

	for (var i = 0; i < active_vote_sequence.length; i++) {
		SetVoteCategoryVisible(active_vote_sequence[i], active_vote_sequence[i] == category);
	}

	var category_index = active_vote_sequence.indexOf(category);
	if (category_index >= 0) {
		active_vote_index = category_index;
	}

	UpdateVoteProgressTabs();
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
	active_vote_sequence = vote_categories.slice(0);
	active_vote_index = 0;
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
			} else if (vote_count == 2) {
				card_width = 340;
			}

			vote_button.style.width = card_width + "px";

			var option_title = LocalizeWithFallback("#vote_" + vote_type + "_" + i);
			var option_description = GetVoteOptionDescription(vote_type, i, vote_type != "difficulty");
			var is_compact_description = option_description.length <= 120;

			var title_labels = vote_button.FindChildrenWithClassTraverse("vote-select-title");
			var description_labels = vote_button.FindChildrenWithClassTraverse("vote-select-description");

			if (title_labels && title_labels[0]) {
				title_labels[0].text = option_title;
			}

			if (description_labels && description_labels[0]) {
				description_labels[0].text = option_description;
			}

			if (vote_type == "difficulty") {
				CreateDifficultyVoteStats(vote_button, i);
			}

			vote_button.SetHasClass("VotePanelCompact", is_compact_description);
			vote_button.SetHasClass("VotePanelDetailed", vote_type == "gamemode" && i == 2);

			if (!is_compact_description) {
				row_is_compact = false;
			}

			var choice_cards = vote_button.FindChildrenWithClassTraverse("vote-button");
			var choice_card = choice_cards && choice_cards[0] ? choice_cards[0] : null;

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
		panel.SetHasClass("VoteRowDetailed", vote_type == "gamemode");
		RefreshLocalVoteCategoryUI(vote_type);
	}

	UpdateVoteSelectionSummary();
	UpdateVoteProgressTabs();

	const has_vote_options = vote_categories.length > 0;

	if (main_vote_button) {
		main_vote_button.enabled = has_vote_options;
		main_vote_button.style.opacity = has_vote_options ? "1" : "0.45";
	}

	ToggleVoteContainer(has_vote_options);
	if (has_vote_options) {
		ShowCurrentVoteCategory();
	}

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
		if (bBoolean && active_vote_sequence.length > 0 && active_vote_index >= active_vote_sequence.length) {
			active_vote_index = 0;
		}

		panel.SetHasClass("Visible", bBoolean);
		panel.style.visibility = bBoolean ? "visible" : "collapse";
		panel.hittest = bBoolean;
		panel.hittestchildren = bBoolean;

		if (bBoolean) {
			ShowCurrentVoteCategory();
		}

	} else {
	}
}

function HoverableLoadingScreen() {
	if (Game.GameStateIs(2)) {
		$.GetContextPanel().style.zIndex = "1";
	} else {
		$.Schedule(1.0, HoverableLoadingScreen)
	}
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

	UpdateVoteSelectionSummary();
	UpdateVoteProgressTabs();
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

function GetVoteWeightFromEntry(vote_entry) {
	if (vote_entry === undefined || vote_entry === null) {
		return 0;
	}

	if (vote_entry[2] !== undefined) {
		var table_weight = parseInt(vote_entry[2]);
		return isNaN(table_weight) || table_weight <= 0 ? 1 : table_weight;
	}

	if (vote_entry.weight !== undefined) {
		var named_weight = parseInt(vote_entry.weight);
		return isNaN(named_weight) || named_weight <= 0 ? 1 : named_weight;
	}

	if (vote_entry.votes !== undefined) {
		var named_votes = parseInt(vote_entry.votes);
		return isNaN(named_votes) || named_votes <= 0 ? 1 : named_votes;
	}

	return 0;
}

function GetVoteWeightForDonatorStatus(status) {
	var parsed_status = parseInt(status);

	if (parsed_status == 1 || parsed_status == 2 || parsed_status == 3) {
		return 5;
	}

	if (parsed_status == 4) {
		return 4;
	}

	if (parsed_status == 5) {
		return 3;
	}

	if (parsed_status == 8 || parsed_status == 9) {
		return 5;
	}

	if (parsed_status == 7) {
		return 5;
	}

	if (parsed_status == 6) {
		return 2;
	}

	return 1;
}

function GetLocalVoteWeightFallback() {
	var local_player_id = GetLocalPlayerIDSafe();
	if (local_player_id < 0 || typeof CustomNetTables === "undefined" || !CustomNetTables) {
		return 1;
	}

	var player_info = Game.GetPlayerInfo(local_player_id);
	if (!player_info || !player_info.player_steamid) {
		return 1;
	}

	var vote_power = 1;
	var supporter_table = CustomNetTables.GetTableValue("supporter_pass_player", local_player_id.toString()) || {};
	if (supporter_table.vote_power !== undefined) {
		vote_power = Math.max(vote_power, Math.floor(ToNumber(supporter_table.vote_power, 1)));
	} else {
		var supporter_tier = Math.floor(ToNumber(supporter_table.tier_id || supporter_table.supporter_tier, 0));
		if (supporter_tier > 0) {
			vote_power = Math.max(vote_power, Math.min(supporter_tier + 1, 5));
		}
	}

	var donators = CustomNetTables.GetTableValue("game_options", "donators");
	if (!donators) {
		return vote_power;
	}

	var local_steamid = player_info.player_steamid.toString();
	for (var key in donators) {
		var row = donators[key];
		var steamid = key;
		var status = row;

		if (row && typeof row === "object") {
			steamid = row.steamid !== undefined ? row.steamid : key;
			status = row.status !== undefined ? row.status : row.donator_status;
		}

		if (steamid !== undefined && steamid !== null && steamid.toString() == local_steamid) {
			return Math.max(vote_power, GetVoteWeightForDonatorStatus(status));
		}
	}

	return vote_power;
}

function GetLocalVoteWeight(category, vote_index) {
	var local_player_id = GetLocalPlayerIDSafe();
	var local_entry = FindPlayerVoteEntry(vote_payload_cache[category] || {}, local_player_id);
	var server_vote = GetVoteChoiceFromEntry(local_entry);

	if (server_vote == vote_index) {
		var server_weight = GetVoteWeightFromEntry(local_entry);
		return server_weight > 0 ? server_weight : 1;
	}

	if (parseInt(local_votes[category]) == vote_index) {
		return GetLocalVoteWeightFallback();
	}

	return 0;
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
	UpdateVoteSelectionSummary();
	if (typeof GameEvents !== "undefined" && GameEvents && typeof GameEvents.SendCustomGameEventToServer === "function") {
		GameEvents.SendCustomGameEventToServer("setting_vote", { "category": category, "vote": vote, "PlayerID": Game.GetLocalPlayerID() });
	} else {
	}
}

function GetVoteCounterFromTable(vote_table) {
	var vote_counter = [];

	if (!vote_table) {
		return vote_counter;
	}

	for (var player_id in vote_table) {
		var vote_row = vote_table[player_id];
		if (!vote_row || vote_row[1] === undefined) {
			continue;
		}

		var gamemode = parseInt(vote_row[1]);
		var amount_of_votes = parseInt(vote_row[2]);

		if (isNaN(gamemode) || gamemode <= 0) {
			continue;
		}

		if (isNaN(amount_of_votes) || amount_of_votes <= 0) {
			amount_of_votes = 1;
		}

		if (!vote_counter[gamemode]) {
			vote_counter[gamemode] = 0;
		}

		vote_counter[gamemode] = vote_counter[gamemode] + amount_of_votes;
	}

	return vote_counter;
}

function ApplyVoteCountsToLabels(category, vote_table) {
	var labels = GetOrderedVoteLabels(category);
	if (!labels || labels.length <= 0) {
		return false;
	}

	var vote_counter = GetVoteCounterFromTable(vote_table);

	for (var i = 0; i < labels.length; i++) {
		var panel = labels[i];
		var index = i + 1;
		var count = vote_counter[index] ? vote_counter[index] : 0;
		var vote_word = count > 1 ? L("loading_screen_vote_word_plural") : L("loading_screen_vote_word_single");
		panel.text = LocalizeWithFallback("#vote_" + category + "_" + index) + " (" + count + " " + vote_word + ")";
	}

	return true;
}

/* Supporter vote power starts at 2 votes for tier 1 and caps at 5 votes. */

function OnVotesReceived(data) {
	if (!data || !data.category) {
		return;
	}

	var category = data.category;
	var vote_table = data.table || {};
	vote_payload_cache[category] = vote_table;
	ApplyVoteCountsToLabels(category, vote_table);

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
	UpdateLocalVoteConfirmation(category, vote_table);
	RefreshLocalVoteCategoryUI(category);
	UpdateVoteSelectionSummary();
	UpdateVoteProgressTabs();
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

	InitializeBottomModsCarousel();
	InitializeBottomTabs();
	InitializeBottomFooterMouseTracking();
	UpdateLoadingQaPanelState();
	$.Schedule(bottom_tab_auto_tick_interval, AutoRotateBottomTabs);

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
	} else {
	}
	HoverableLoadingScreen();
	fetch();
	SetProfileName();
	RefreshProfileDataLoop();
	UpdatePlayerLoadingSidebar();
	$.GetContextPanel().SetHasClass("ProfileModalVisible", false);
	$.GetContextPanel().SetHasClass("ProfileModalClosing", false);

	if (typeof CustomNetTables !== "undefined" && CustomNetTables && typeof CustomNetTables.SubscribeNetTableListener === "function") {
		CustomNetTables.SubscribeNetTableListener("supporter_pass_player", function (table_name, key, data) {
			UpdateProfilePanels();
			UpdatePlayerLoadingSidebar();
		});
	} else {
	}

	if (typeof GameEvents !== "undefined" && GameEvents && typeof GameEvents.Subscribe === "function") {
		GameEvents.Subscribe("loading_screen_api_response", OnLoadingScreenApiResponse);
		GameEvents.Subscribe("loading_screen_debug", LoadingScreenDebug);
		GameEvents.Subscribe("send_votes", function (payload) {
			OnVotesReceived(payload);
		});
		GameEvents.Subscribe("all_players_loaded", function (payload) {
			AllPlayersLoaded();
		});
		GameEvents.Subscribe("all_players_battlepass_loaded", function (payload) {
			AllPlayersBattlepassLoaded();
		});
	} else {
	}
})();
