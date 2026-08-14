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
var vote_progress_category = "difficulty";
var vote_modal_mode = "settings";
var custom_poll_state = { polls: [] };
var custom_poll_active_poll_id = "";
var custom_poll_review_mode = false;
var custom_poll_auto_attempted = false;
var custom_poll_status_text = "";
var player_loading_rows = {};
var player_loading_section_rows = {};
var player_loading_order_signature = "";
var player_loading_panel_serial = 0;
var loading_screen_context_panel = $.GetContextPanel();
var player_loading_profile_hover = null;
var player_loading_profile_hover_player_id = -1;
var selected_profile_player_id = -1;
var xhs_bot_setup_initialized = false;
var xhs_bot_setup_config = null;
var xhs_bot_setup_roster = { count: 0, players: {} };
var xhs_bot_setup_spectator_access = { allowed: 0 };
var xhs_bot_setup_draft = {
	bot_count: 0,
	ai_difficulty: "normal",
	spectator_mode: false,
	hero_selections: {},
};
var xhs_bot_setup_dirty = false;
var xhs_bot_setup_pending = false;
var xhs_bot_setup_synced = false;
var xhs_bot_setup_expected_revision = -1;
var xhs_bot_setup_request_token = 0;
var xhs_bot_setup_log_sequence = 0;
var xhs_bot_setup_identity_watch_running = false;
var xhs_bot_setup_last_local_player_id = -2;
var xhs_bot_setup_ui = {};
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
var loading_screen_logs_enabled = false;
var loading_screen_log_sequence = 0;
var loading_screen_last_setup_signature = "";
var loading_screen_last_sidebar_summary_signature = "";
var loading_screen_last_footer_mouse_state = false;
var loading_screen_last_bottom_tab_countdown_bucket = -1;
var loading_screen_last_fetch_stage = "";
var loading_screen_last_profile_signature = "";
var SUPPORTER_PASS_XP_PER_LEVEL = 1000;
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
		"difficulty": 5,
		"ai_allies": 2,
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

var vote_fallbacks = {
	loading_screen_bot_setup_title: "AI ALLIES",
	loading_screen_bot_setup_count: "Allies",
	loading_screen_bot_setup_performance_warning: "Performance warning: {total} total players (humans + AI). Above 4 players, bot resource usage may make the game less smooth.",
	loading_screen_bot_setup_difficulty: "Difficulty",
	loading_screen_bot_setup_easy: "Easy",
	loading_screen_bot_setup_normal: "Normal",
	loading_screen_bot_setup_random: "Random",
	loading_screen_bot_setup_observer: "Observer",
	loading_screen_bot_setup_spectator_off: "Play",
	loading_screen_bot_setup_spectator_on: "Spectate",
	loading_screen_bot_setup_spectator_note: "Spectator mode: AI allies own every active lane while you observe.",
	loading_screen_bot_setup_confirm: "Apply AI setup",
	loading_screen_bot_setup_waiting: "Waiting for the bot controller...",
	loading_screen_bot_setup_vote_waiting: "AI allies unlock after every human votes Yes ({yes}/{total}).",
	loading_screen_bot_setup_controller: "You control this setup.",
	loading_screen_bot_setup_controller_only: "Only the first human player can edit AI allies.",
	loading_screen_bot_setup_locked: "AI setup is locked for this launch.",
	loading_screen_bot_setup_pending: "Applying configuration...",
	loading_screen_bot_setup_summary: "{count} allied bot(s) / {difficulty} / {composition}",
	loading_screen_bot_setup_server_status: "Server: {status}",
	loading_screen_ai_allies_section: "AI Allies",
	loading_screen_ai_ally_status: "AI ALLY / {difficulty}",
	loading_screen_ai_ready_status: "AI READY / {difficulty}",
	loading_screen_ai_bot_name: "XHS Bot {number}",
	loading_screen_vote_tab_game_mode: "Game Mode",
	loading_screen_ai_vote_unanimity_rule: "Unanimous approval required. One No disables AI allies.",
	loading_screen_ai_vote_pending: "Waiting for unanimity: {yes}/{total} Yes.",
	loading_screen_ai_vote_rejected: "AI allies disabled: at least one player voted No.",
	loading_screen_ai_vote_approved: "Unanimous vote confirmed. The host can configure AI allies.",
	vote_ai_allies: "AI Allies",
	vote_ai_allies_1: "Yes, enable AI allies",
	vote_ai_allies_1_description: "Allow the host to add and configure allied bots for this match.",
	vote_ai_allies_2: "No AI allies",
	vote_ai_allies_2_description: "Keep this match human-only. AI allies require unanimous approval.",
};

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

function GetPlayerIDCandidateFromInfo(player_info) {
	if (!player_info) {
		return -1;
	}

	var fields = ["player_id", "playerid", "player_slot", "player_slot_id"];
	for (var field_index = 0; field_index < fields.length; field_index++) {
		var raw_candidate = player_info[fields[field_index]];
		if (raw_candidate === undefined || raw_candidate === null || raw_candidate === "") {
			continue;
		}
		var candidate = Number(raw_candidate);
		if (!isNaN(candidate) && candidate >= 0 && candidate < 24) {
			return Math.floor(candidate);
		}
	}

	return -1;
}

function HasLoadingScreenPlayerInfo(player_info) {
	if (!player_info) {
		return false;
	}

	if (GetPlayerIDCandidateFromInfo(player_info) >= 0) {
		return true;
	}

	var name = player_info.player_name;
	var steam_id = player_info.player_steamid || player_info.steamid || player_info.steam_id;
	var hero = player_info.player_selected_hero;
	var state = Number(player_info.player_connection_state);
	return !!(name && String(name).trim()) ||
		!!(steam_id && String(steam_id) !== "0") ||
		!!(hero && String(hero).trim()) ||
		(!isNaN(state) && state !== connection_state.UNKNOWN);
}

function GetLoadingScreenPlayerIDs() {
	var ids = [];
	function AddPlayerID(value) {
		if (value === undefined || value === null || value === "") {
			return;
		}
		var player_id = Number(value);
		if (!isNaN(player_id) && player_id >= 0 && player_id < 24 && ids.indexOf(player_id) < 0) {
			ids.push(player_id);
		}
	}

	if (Game.GetAllPlayerIDs) {
		var all_players = Game.GetAllPlayerIDs() || [];
		for (var all_index = 0; all_index < all_players.length; all_index++) AddPlayerID(all_players[all_index]);
	}

	if (Game.GetAllTeamIDs && Game.GetPlayerIDsOnTeam) {
		var teams = Game.GetAllTeamIDs() || [];
		for (var team_index = 0; team_index < teams.length; team_index++) {
			var team_players = Game.GetPlayerIDsOnTeam(teams[team_index]) || [];
			for (var team_player_index = 0; team_player_index < team_players.length; team_player_index++) {
				AddPlayerID(team_players[team_player_index]);
			}
		}
	}

	// During the native connection screen, the global player lists can remain
	// empty even though Panorama already exposes individual lobby slots. Probe
	// those client-side slots so our replacement roster does not depend on Lua
	// or the custom setup nettable being initialized first.
	if (typeof Game.GetPlayerInfo === "function") {
		for (var player_slot = 0; player_slot < 24; player_slot++) {
			var slot_info = null;
			try {
				slot_info = Game.GetPlayerInfo(player_slot);
			} catch (slot_error) {}
			if (HasLoadingScreenPlayerInfo(slot_info)) {
				var info_player_id = GetPlayerIDCandidateFromInfo(slot_info);
				AddPlayerID(info_player_id >= 0 ? info_player_id : player_slot);
			}
		}
	}

	var local_info = null;
	try {
		local_info = Game.GetLocalPlayerInfo ? Game.GetLocalPlayerInfo() : null;
	} catch (local_info_error) {}
	AddPlayerID(GetPlayerIDCandidateFromInfo(local_info));

	var local_player_id = GetLocalPlayerIDSafe();
	if (local_player_id >= 0) AddPlayerID(local_player_id);
	return ids.sort(function (a, b) { return a - b; });
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

function ApplyLoadingScreenStaticLocalization() {
	var labels = {
		VoteCategoryTabGameModeLabel: "loading_screen_vote_tab_game_mode",
		VoteCategoryTabAIAlliesLabel: "vote_ai_allies",
		VoteProgressAIAlliesTitle: "vote_ai_allies",
		VoteSelectionAIAlliesKey: "vote_ai_allies",
	};
	for (var panel_id in labels) {
		var panel = $("#" + panel_id);
		if (panel) {
			panel.text = L(labels[panel_id]);
		}
	}
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

function IsXHSBotSetupAllowed() {
	return game_options !== undefined &&
		game_options !== null &&
		String(game_options.game_type) === "XHS";
}

function XHSBotSetupHasUnanimousApproval() {
	return IsXHSBotSetupAllowed() &&
		!!xhs_bot_setup_config &&
		IsTruthy(xhs_bot_setup_config.vote_approved) &&
		IsTruthy(xhs_bot_setup_config.available);
}

function XHSBotSetupHasSpectatorAccess() {
	var tools_mode = typeof Game !== "undefined" &&
		typeof Game.IsInToolsMode === "function" &&
		Game.IsInToolsMode();
	var local_player_id = GetLocalPlayerIDSafe();
	if (!tools_mode && local_player_id >= 0 &&
		typeof CustomNetTables !== "undefined" && CustomNetTables) {
		var current_access = CustomNetTables.GetTableValue(
			"xhs_bots",
			"spectator_access_" + local_player_id
		);
		if (current_access) {
			xhs_bot_setup_spectator_access = current_access;
		}
	}
	return tools_mode || IsTruthy(xhs_bot_setup_spectator_access.allowed);
}

function XHSBotSetupSafeJSON(value) {
	try {
		var encoded = JSON.stringify(value);
		return encoded === undefined ? "null" : encoded;
	} catch (error) {
		return "{\"serialization_error\":\"" + String(error) + "\"}";
	}
}

function XHSBotSetupGetEditBlockReason() {
	if (!IsXHSBotSetupAllowed()) {
		return "setup_not_allowed";
	}
	if (!xhs_bot_setup_config) {
		return "config_missing";
	}
	if (!XHSBotSetupHasUnanimousApproval()) {
		return "unanimous_vote_required";
	}
	if (!XHSBotSetupIsController()) {
		return "not_controller";
	}
	if (IsTruthy(xhs_bot_setup_config.locked)) {
		return "setup_locked";
	}
	if (xhs_bot_setup_pending) {
		return "request_pending";
	}
	return "";
}

function XHSBotSetupSnapshot() {
	var config = xhs_bot_setup_config;
	var local_player_id = GetLocalPlayerIDSafe();
	var controller_player_id = config
		? Math.floor(ToNumber(config.controller_player_id, -1))
		: -1;
	var edit_block_reason = XHSBotSetupGetEditBlockReason();
	return {
		allowed: IsXHSBotSetupAllowed(),
		initialized: xhs_bot_setup_initialized,
		has_card: !!xhs_bot_setup_ui.card,
		has_config: !!config,
		local_player_id: local_player_id,
		controller_player_id: controller_player_id,
		is_controller: XHSBotSetupIsController(),
		available: !!(config && IsTruthy(config.available)),
		vote_approved: !!(config && IsTruthy(config.vote_approved)),
		unanimously_approved: XHSBotSetupHasUnanimousApproval(),
		locked: !!(config && IsTruthy(config.locked)),
		pending: xhs_bot_setup_pending,
		dirty: xhs_bot_setup_dirty,
		synced: xhs_bot_setup_synced,
		can_edit: edit_block_reason === "",
		edit_block_reason: edit_block_reason || "none",
		expected_revision: xhs_bot_setup_expected_revision,
		request_token: xhs_bot_setup_request_token,
		config: config ? {
			revision: Math.floor(ToNumber(config.revision, -1)),
			bot_count: Math.floor(ToNumber(config.bot_count, 0)),
			max_bots: Math.floor(ToNumber(config.max_bots, 0)),
			max_play_bots: Math.floor(ToNumber(config.max_play_bots, 0)),
			max_spectator_bots: Math.floor(ToNumber(config.max_spectator_bots, 0)),
			ai_difficulty: String(config.ai_difficulty || ""),
			spectator_mode: IsTruthy(config.spectator_mode),
			status: String(config.status || ""),
			error: String(config.error || ""),
		} : null,
		draft: {
			bot_count: Math.floor(ToNumber(xhs_bot_setup_draft.bot_count, 0)),
			ai_difficulty: String(xhs_bot_setup_draft.ai_difficulty || ""),
			spectator_mode: !!xhs_bot_setup_draft.spectator_mode,
		},
	};
}

function XHSBotSetupLog(event_name, details) {
	// Intentionally silent. Setup diagnostics live server-side now that the
	// Panorama controls and event wiring have been validated.
}

function GetXHSBotRosterPlayers() {
	if (!xhs_bot_setup_roster || !xhs_bot_setup_roster.players) {
		return {};
	}
	return xhs_bot_setup_roster.players;
}

function GetXHSBotRosterEntry(player_id) {
	var players = GetXHSBotRosterPlayers();
	return players[player_id] || players[String(player_id)] || null;
}

function GetXHSBotDisplayName(player_id, bot_data) {
	var bot_name = NormalizePlayerDisplayName(bot_data && bot_data.name);
	if (bot_name) {
		return bot_name;
	}
	return LocalizeTemplate("loading_screen_ai_bot_name", {
		number: (Math.max(0, Number(player_id) || 0) + 1).toString(),
	});
}

function XHSBotSetupMakeLabel(parent, class_name, text) {
	var label = $.CreatePanel("Label", parent, "");
	if (class_name) {
		label.AddClass(class_name);
	}
	label.text = text || "";
	return label;
}

function XHSBotSetupMakeButton(parent, id, text, class_name, callback) {
	var button_id = id || "XHSBotSetupUnnamedButton";
	var button = $.CreatePanel("Button", parent, button_id);
	button.AddClass("xhs-bot-setup-button");
	if (class_name) {
		button.AddClass(class_name);
	}
	button.SetPanelEvent("onactivate", function () {
		XHSBotSetupLog("button_activate", {
			button: button_id,
			button_enabled: !!button.enabled,
			text: String(text || ""),
			class_name: String(class_name || ""),
		});
		try {
			callback();
			XHSBotSetupLog("button_callback_complete", {
				button: button_id,
			});
		} catch (error) {
			XHSBotSetupLog("button_callback_exception", {
				button: button_id,
				error: String(error),
			});
			throw error;
		}
	});
	button.SetPanelEvent("onmouseover", function () {
		XHSBotSetupLog("button_pointer_enter", {
			button: button_id,
			button_enabled: !!button.enabled,
		});
	});
	button.SetPanelEvent("onmouseout", function () {
		XHSBotSetupLog("button_pointer_leave", {
			button: button_id,
			button_enabled: !!button.enabled,
		});
	});
	XHSBotSetupMakeLabel(button, "xhs-bot-setup-button-label", text);
	XHSBotSetupLog("button_created", {
		button: button_id,
		text: String(text || ""),
		class_name: String(class_name || ""),
	});
	return button;
}

function XHSBotSetupCopyHeroSelections(source, maximum_slot) {
	var copy = {};
	source = source || {};
	maximum_slot = Math.max(0, Math.floor(ToNumber(maximum_slot, 8)));
	for (var slot = 1; slot <= maximum_slot; slot++) {
		var hero_name = String(source[slot] || source[String(slot)] || "");
		if (hero_name) {
			copy[slot] = hero_name;
		}
	}
	return copy;
}

function XHSBotSetupGetSupportedHeroes() {
	var source = xhs_bot_setup_config && xhs_bot_setup_config.supported_heroes;
	var heroes = [];
	for (var key in (source || {})) {
		var entry = source[key];
		var hero_name = typeof entry === "string" ? entry : String((entry && entry.hero) || "");
		if (!hero_name) {
			continue;
		}
		heroes.push({
			hero: hero_name,
			display_name: String((entry && entry.display_name) || hero_name),
			order: Math.floor(ToNumber(key, heroes.length + 1)),
		});
	}
	heroes.sort(function (left, right) {
		var left_name = String(left.display_name || left.hero).toLowerCase();
		var right_name = String(right.display_name || right.hero).toLowerCase();
		if (left_name < right_name) {
			return -1;
		}
		if (left_name > right_name) {
			return 1;
		}
		return left.hero < right.hero ? -1 : (left.hero > right.hero ? 1 : 0);
	});
	return heroes;
}

function XHSBotSetupCreateHeroOption(dropdown, slot, suffix, hero_name, display_name) {
	// Native Label options keep Panorama's DropDown click handling intact.
	var option = $.CreatePanel("Label", dropdown, "XHSBotHeroOption_" + slot + "_" + suffix);
	option.AddClass("xhs-bot-hero-option");
	option.xhs_hero_name = hero_name;
	option.SetAttributeString("xhs_hero_name", hero_name);
	option.text = display_name;
	if (hero_name) {
		option.AddClass("HasHeroIcon");
		// Valve's square hero-icon resources keep the full KV unit name.
		option.style.backgroundImage = "url(\"file://{images}/heroes/icons/" + hero_name + ".png\")";
	}
	dropdown.AddOption(option);
	return option;
}

function XHSBotSetupIsSupportedHero(hero_name) {
	if (!hero_name) {
		return true;
	}
	var supported = XHSBotSetupGetSupportedHeroes();
	for (var index = 0; index < supported.length; index++) {
		if (supported[index].hero === hero_name) {
			return true;
		}
	}
	return false;
}

function XHSBotSetupSelectHero(slot, hero_name) {
	if (XHSBotSetupGetEditBlockReason()) {
		return;
	}
	slot = Math.max(1, Math.floor(ToNumber(slot, 1)));
	hero_name = String(hero_name || "");
	if (!XHSBotSetupIsSupportedHero(hero_name)) {
		return;
	}
	var selections = XHSBotSetupCopyHeroSelections(xhs_bot_setup_draft.hero_selections, XHSBotSetupMaxBots());
	if (hero_name) {
		selections[slot] = hero_name;
	} else {
		delete selections[slot];
	}
	xhs_bot_setup_draft.hero_selections = selections;
	xhs_bot_setup_dirty = true;
	XHSBotSetupRender("hero_select");
}

function XHSBotSetupEnsureHeroDropdown(player_row, bot_data) {
	if (!player_row || !bot_data) {
		return;
	}
	var slot = Math.max(1, Math.floor(ToNumber(bot_data.slot, 1)));
	var supported = XHSBotSetupGetSupportedHeroes();
	var options_signature = supported.map(function (entry) {
		return entry.hero + ":" + entry.display_name;
	}).join("|");
	if (!player_row.hero_dropdown || player_row.hero_dropdown_signature !== options_signature) {
		if (player_row.hero_dropdown) {
			player_row.hero_dropdown.DeleteAsync(0);
		}
		var dropdown = $.CreatePanel("DropDown", player_row.panel, "XHSBotHeroSelector_" + slot);
		dropdown.AddClass("xhs-bot-hero-dropdown");
		XHSBotSetupCreateHeroOption(
			dropdown,
			slot,
			"random",
			"",
			L("loading_screen_bot_setup_random")
		);
		for (var index = 0; index < supported.length; index++) {
			var hero = supported[index];
			XHSBotSetupCreateHeroOption(
				dropdown,
				slot,
				String(index),
				hero.hero,
				hero.display_name
			);
		}
		dropdown.SetPanelEvent("oninputsubmit", (function (target_slot, target_dropdown) {
			return function () {
				// oninputsubmit can run before GetSelected reflects the clicked
				// option. Defer one frame so Random cannot overwrite the choice.
				$.Schedule(0.03, function () {
					if (!target_dropdown) {
						return;
					}
					var selected = target_dropdown.GetSelected();
					var hero_name = selected
						? selected.GetAttributeString("xhs_hero_name", String(selected.xhs_hero_name || ""))
						: "";
					XHSBotSetupSelectHero(target_slot, hero_name);
				});
			};
		})(slot, dropdown));
		player_row.hero_dropdown = dropdown;
		player_row.hero_dropdown_signature = options_signature;
	}

	var selected_hero = String(
		(xhs_bot_setup_draft.hero_selections &&
			(xhs_bot_setup_draft.hero_selections[slot] || xhs_bot_setup_draft.hero_selections[String(slot)]))
		|| bot_data.hero_selection
		|| ""
	);
	var selected_id = "XHSBotHeroOption_" + slot + "_random";
	for (var option_index = 0; option_index < supported.length; option_index++) {
		if (supported[option_index].hero === selected_hero) {
			selected_id = "XHSBotHeroOption_" + slot + "_" + option_index;
			break;
		}
	}
	player_row.hero_dropdown.SetSelected(selected_id);
	player_row.hero_dropdown.SetHasClass("HasHeroIcon", !!selected_hero);
	player_row.hero_dropdown.style.backgroundImage = selected_hero
		? "url(\"file://{images}/heroes/icons/" + selected_hero + ".png\")"
		: "none";
	player_row.hero_dropdown.enabled = XHSBotSetupCanEdit();
	player_row.hero_dropdown.SetHasClass("Disabled", !XHSBotSetupCanEdit());
}

function XHSBotSetupMaxBots() {
	var spectator_mode = !!xhs_bot_setup_draft.spectator_mode;
	if (!xhs_bot_setup_config) {
		return spectator_mode ? 8 : 7;
	}
	var mode_maximum = spectator_mode
		? xhs_bot_setup_config.max_spectator_bots
		: xhs_bot_setup_config.max_play_bots;
	var fallback = Math.floor(ToNumber(xhs_bot_setup_config.max_bots, spectator_mode ? 8 : 7));
	var maximum = Math.floor(ToNumber(mode_maximum, fallback));
	return Math.max(0, Math.min(8, maximum));
}

function XHSBotSetupSyncDraftFromConfig() {
	if (!xhs_bot_setup_config) {
		XHSBotSetupLog("draft_sync_skipped", {
			reason: "config_missing",
		});
		return;
	}

	var previous_draft = {
		bot_count: xhs_bot_setup_draft.bot_count,
		ai_difficulty: xhs_bot_setup_draft.ai_difficulty,
		spectator_mode: xhs_bot_setup_draft.spectator_mode,
	};
	xhs_bot_setup_draft.spectator_mode = IsTruthy(xhs_bot_setup_config.spectator_mode);
	xhs_bot_setup_draft.bot_count = Math.max(
		0,
		Math.min(XHSBotSetupMaxBots(), Math.floor(ToNumber(xhs_bot_setup_config.bot_count, 0)))
	);
	xhs_bot_setup_draft.ai_difficulty = String(xhs_bot_setup_config.ai_difficulty || "normal").toLowerCase() === "easy"
		? "easy"
		: "normal";

	xhs_bot_setup_draft.hero_selections = XHSBotSetupCopyHeroSelections(
		xhs_bot_setup_config.hero_selections,
		xhs_bot_setup_draft.bot_count
	);
	xhs_bot_setup_synced = true;
	XHSBotSetupLog("draft_synced_from_config", {
		previous_draft: previous_draft,
	});
}

function XHSBotSetupIsController() {
	if (!xhs_bot_setup_config) {
		return false;
	}
	var local_player_id = GetLocalPlayerIDSafe();
	var controller_player_id = Math.floor(ToNumber(xhs_bot_setup_config.controller_player_id, -1));
	if (local_player_id < 0) {
		return false;
	}
	// The server remains authoritative. This temporary fallback only keeps the
	// first loaded human interactive until the server republishes its controller.
	return controller_player_id < 0 || local_player_id === controller_player_id;
}

function XHSBotSetupWatchIdentity() {
	if (!xhs_bot_setup_initialized ||
		!xhs_bot_setup_ui.card ||
		!XHSBotSetupHasUnanimousApproval()) {
		xhs_bot_setup_identity_watch_running = false;
		return;
	}

	var local_player_id = GetLocalPlayerIDSafe();
	var controller_player_id = xhs_bot_setup_config
		? Math.floor(ToNumber(xhs_bot_setup_config.controller_player_id, -1))
		: -1;
	if (local_player_id !== xhs_bot_setup_last_local_player_id) {
		var previous_local_player_id = xhs_bot_setup_last_local_player_id;
		xhs_bot_setup_last_local_player_id = local_player_id;
		XHSBotSetupLog("local_player_id_changed", {
			previous_local_player_id: previous_local_player_id,
			local_player_id: local_player_id,
			controller_player_id: controller_player_id,
		});
		XHSBotSetupRender("local_player_id_changed");
	}

	if (local_player_id >= 0 && xhs_bot_setup_config && controller_player_id >= 0) {
		xhs_bot_setup_identity_watch_running = false;
		XHSBotSetupLog("identity_watch_completed", {
			local_player_id: local_player_id,
			controller_player_id: controller_player_id,
		});
		return;
	}
	$.Schedule(0.1, XHSBotSetupWatchIdentity);
}

function XHSBotSetupStartIdentityWatch() {
	if (xhs_bot_setup_identity_watch_running) {
		return;
	}
	xhs_bot_setup_identity_watch_running = true;
	XHSBotSetupLog("identity_watch_started", {});
	$.Schedule(0.0, XHSBotSetupWatchIdentity);
}

function XHSBotSetupCanEdit() {
	return XHSBotSetupGetEditBlockReason() === "";
}

function XHSBotSetupSetButtonEnabled(button, enabled) {
	if (!button) {
		return;
	}
	enabled = !!enabled;
	button.enabled = enabled;
	button.SetHasClass("Disabled", !enabled);
}

function XHSBotSetupChangeCount(delta) {
	var edit_block_reason = XHSBotSetupGetEditBlockReason();
	var previous_count = Math.floor(ToNumber(xhs_bot_setup_draft.bot_count, 0));
	XHSBotSetupLog("count_change_requested", {
		delta: delta,
		previous_count: previous_count,
		edit_block_reason: edit_block_reason || "none",
	});
	if (edit_block_reason) {
		XHSBotSetupLog("count_change_rejected", {
			delta: delta,
			reason: edit_block_reason,
		});
		return;
	}
	var next_count = Math.max(0, Math.min(
		XHSBotSetupMaxBots(),
		previous_count + delta
	));
	if (next_count === previous_count) {
		XHSBotSetupLog("count_change_noop", {
			delta: delta,
			count: previous_count,
			reason: delta < 0 ? "minimum_reached" : "maximum_reached",
		});
		return;
	}
	xhs_bot_setup_draft.bot_count = next_count;
	if (next_count === 0) {
		xhs_bot_setup_draft.spectator_mode = false;
	}
	xhs_bot_setup_dirty = true;
	XHSBotSetupLog("count_change_applied", {
		delta: delta,
		previous_count: previous_count,
		next_count: next_count,
	});
	XHSBotSetupRender("count_change");
}

function XHSBotSetupSelectDifficulty(difficulty) {
	var edit_block_reason = XHSBotSetupGetEditBlockReason();
	XHSBotSetupLog("difficulty_select_requested", {
		requested: difficulty,
		previous: xhs_bot_setup_draft.ai_difficulty,
		edit_block_reason: edit_block_reason || "none",
	});
	if (edit_block_reason) {
		XHSBotSetupLog("difficulty_select_rejected", {
			requested: difficulty,
			reason: edit_block_reason,
		});
		return;
	}
	if (difficulty !== "easy" && difficulty !== "normal") {
		XHSBotSetupLog("difficulty_select_rejected", {
			requested: difficulty,
			reason: "invalid_difficulty",
		});
		return;
	}
	if (xhs_bot_setup_draft.ai_difficulty !== difficulty) {
		var previous_difficulty = xhs_bot_setup_draft.ai_difficulty;
		xhs_bot_setup_draft.ai_difficulty = difficulty;
		xhs_bot_setup_dirty = true;
		XHSBotSetupLog("difficulty_select_applied", {
			previous: previous_difficulty,
			next: difficulty,
		});
		XHSBotSetupRender("difficulty_select");
		return;
	}
	XHSBotSetupLog("difficulty_select_noop", {
		difficulty: difficulty,
		reason: "already_selected",
	});
}

function XHSBotSetupSelectSpectatorMode(enabled) {
	var edit_block_reason = XHSBotSetupGetEditBlockReason();
	if (edit_block_reason) {
		return;
	}
	enabled = !!enabled;
	if (enabled && !XHSBotSetupHasSpectatorAccess()) {
		return;
	}
	if (xhs_bot_setup_draft.spectator_mode === enabled) {
		return;
	}
	xhs_bot_setup_draft.spectator_mode = enabled;
	if (enabled && xhs_bot_setup_draft.bot_count < 1) {
		xhs_bot_setup_draft.bot_count = Math.min(1, XHSBotSetupMaxBots());
	}
	xhs_bot_setup_draft.bot_count = Math.min(
		XHSBotSetupMaxBots(),
		Math.max(0, Math.floor(ToNumber(xhs_bot_setup_draft.bot_count, 0)))
	);
	xhs_bot_setup_dirty = true;
	XHSBotSetupRender("spectator_mode_select");
}

function XHSBotSetupConfirm() {
	var edit_block_reason = XHSBotSetupGetEditBlockReason();
	XHSBotSetupLog("confirm_requested", {
		edit_block_reason: edit_block_reason || "none",
		dirty: xhs_bot_setup_dirty,
	});
	if (edit_block_reason) {
		XHSBotSetupLog("confirm_rejected", {
			reason: edit_block_reason,
		});
		return;
	}
	if (!xhs_bot_setup_dirty) {
		XHSBotSetupLog("confirm_rejected", {
			reason: "draft_not_dirty",
		});
		return;
	}

	xhs_bot_setup_pending = true;
	xhs_bot_setup_expected_revision = Math.floor(ToNumber(xhs_bot_setup_config.revision, 0)) + 1;
	xhs_bot_setup_request_token = xhs_bot_setup_request_token + 1;
	var request_token = xhs_bot_setup_request_token;
	var requested_count = Math.max(0, Math.min(
		XHSBotSetupMaxBots(),
		Math.floor(ToNumber(xhs_bot_setup_draft.bot_count, 0))
	));
	var request_payload = {
		bot_count: requested_count,
		ai_difficulty: xhs_bot_setup_draft.ai_difficulty,
		spectator_mode: xhs_bot_setup_draft.spectator_mode ? 1 : 0,
		hero_selections: XHSBotSetupCopyHeroSelections(xhs_bot_setup_draft.hero_selections, requested_count),
	};
	XHSBotSetupLog("confirm_sending", {
		request_token: request_token,
		expected_revision: xhs_bot_setup_expected_revision,
		payload: request_payload,
	});
	XHSBotSetupRender("confirm_pending");
	GameEvents.SendCustomGameEventToServer("xhs_bot_setup_configure", request_payload);
	XHSBotSetupLog("confirm_sent", {
		request_token: request_token,
		expected_revision: xhs_bot_setup_expected_revision,
	});

	$.Schedule(4.0, function () {
		XHSBotSetupLog("confirm_timeout_check", {
			request_token: request_token,
			is_current_token: xhs_bot_setup_request_token === request_token,
			still_pending: xhs_bot_setup_pending,
		});
		if (xhs_bot_setup_pending && xhs_bot_setup_request_token === request_token) {
			xhs_bot_setup_pending = false;
			XHSBotSetupLog("confirm_timed_out", {
				request_token: request_token,
				expected_revision: xhs_bot_setup_expected_revision,
			});
			XHSBotSetupRender("confirm_timeout");
		}
	});
}

function XHSBotSetupBuildCard() {
	if (!IsXHSBotSetupAllowed()) {
		XHSBotSetupLog("card_build_rejected", {
			reason: "setup_not_allowed",
		});
		return false;
	}
	if (!XHSBotSetupHasUnanimousApproval()) {
		XHSBotSetupLog("card_build_rejected", {
			reason: "unanimous_vote_required",
		});
		return false;
	}

	var sidebar = $("#PlayerLoadingSidebar");
	var player_list = $("#PlayerLoadingList");
	if (!sidebar || !player_list) {
		XHSBotSetupLog("card_build_rejected", {
			reason: "loading_sidebar_missing",
			has_sidebar: !!sidebar,
			has_player_list: !!player_list,
		});
		return false;
	}

	XHSBotSetupLog("card_build_started", {});
	var card = $.CreatePanel("Panel", sidebar, "XHSBotSetupCard");
	card.AddClass("xhs-bot-setup-card");
	card.style.visibility = "collapse";
	card.hittest = false;
	card.hittestchildren = false;

	var header = $.CreatePanel("Panel", card, "");
	header.AddClass("xhs-bot-setup-header");
	XHSBotSetupMakeLabel(header, "xhs-bot-setup-title", L("loading_screen_bot_setup_title"));

	var count_row = $.CreatePanel("Panel", card, "");
	count_row.AddClass("xhs-bot-setup-field-row");
	XHSBotSetupMakeLabel(count_row, "xhs-bot-setup-field-label", L("loading_screen_bot_setup_count"));
	var count_controls = $.CreatePanel("Panel", count_row, "");
	count_controls.AddClass("xhs-bot-setup-inline-controls");
	xhs_bot_setup_ui.count_minus = XHSBotSetupMakeButton(count_controls, "XHSBotSetupCountMinus", "-", "CountStep", function () {
		XHSBotSetupChangeCount(-1);
	});
	xhs_bot_setup_ui.count_value = XHSBotSetupMakeLabel(count_controls, "xhs-bot-setup-count-value", "0 / 7");
	xhs_bot_setup_ui.count_plus = XHSBotSetupMakeButton(count_controls, "XHSBotSetupCountPlus", "+", "CountStep", function () {
		XHSBotSetupChangeCount(1);
	});
	xhs_bot_setup_ui.performance_warning = XHSBotSetupMakeLabel(
		card,
		"xhs-bot-setup-performance-warning",
		""
	);
	xhs_bot_setup_ui.performance_warning.style.visibility = "collapse";

	var difficulty_row = $.CreatePanel("Panel", card, "");
	difficulty_row.AddClass("xhs-bot-setup-field-row");
	XHSBotSetupMakeLabel(difficulty_row, "xhs-bot-setup-field-label", L("loading_screen_bot_setup_difficulty"));
	var difficulty_controls = $.CreatePanel("Panel", difficulty_row, "");
	difficulty_controls.AddClass("xhs-bot-setup-inline-controls");
	xhs_bot_setup_ui.difficulty = {};
	xhs_bot_setup_ui.difficulty.easy = XHSBotSetupMakeButton(
		difficulty_controls,
		"XHSBotSetupDifficultyEasy",
		L("loading_screen_bot_setup_easy"),
		"Choice",
		function () { XHSBotSetupSelectDifficulty("easy"); }
	);
	xhs_bot_setup_ui.difficulty.normal = XHSBotSetupMakeButton(
		difficulty_controls,
		"XHSBotSetupDifficultyNormal",
		L("loading_screen_bot_setup_normal"),
		"Choice",
		function () { XHSBotSetupSelectDifficulty("normal"); }
	);

	var spectator_row = $.CreatePanel("Panel", card, "");
	spectator_row.AddClass("xhs-bot-setup-field-row");
	xhs_bot_setup_ui.spectator_row = spectator_row;
	XHSBotSetupMakeLabel(spectator_row, "xhs-bot-setup-field-label", L("loading_screen_bot_setup_observer"));
	var spectator_controls = $.CreatePanel("Panel", spectator_row, "");
	spectator_controls.AddClass("xhs-bot-setup-inline-controls");
	xhs_bot_setup_ui.spectator = {};
	xhs_bot_setup_ui.spectator.off = XHSBotSetupMakeButton(
		spectator_controls,
		"XHSBotSetupSpectatorOff",
		L("loading_screen_bot_setup_spectator_off"),
		"Choice",
		function () { XHSBotSetupSelectSpectatorMode(false); }
	);
	xhs_bot_setup_ui.spectator.on = XHSBotSetupMakeButton(
		spectator_controls,
		"XHSBotSetupSpectatorOn",
		L("loading_screen_bot_setup_spectator_on"),
		"Choice",
		function () { XHSBotSetupSelectSpectatorMode(true); }
	);
	xhs_bot_setup_ui.spectator_note = XHSBotSetupMakeLabel(
		card,
		"xhs-bot-setup-spectator-note",
		L("loading_screen_bot_setup_spectator_note")
	);

	xhs_bot_setup_ui.summary = XHSBotSetupMakeLabel(card, "xhs-bot-setup-summary", "");
	xhs_bot_setup_ui.controller = XHSBotSetupMakeLabel(card, "xhs-bot-setup-controller", "");
	xhs_bot_setup_ui.status = XHSBotSetupMakeLabel(card, "xhs-bot-setup-status", "");
	xhs_bot_setup_ui.error = XHSBotSetupMakeLabel(card, "xhs-bot-setup-error", "");
	xhs_bot_setup_ui.confirm = XHSBotSetupMakeButton(
		card,
		"XHSBotSetupConfirm",
		L("loading_screen_bot_setup_confirm"),
		"Confirm",
		XHSBotSetupConfirm
	);
	xhs_bot_setup_ui.card = card;

	if (typeof sidebar.MoveChildBefore === "function") {
		sidebar.MoveChildBefore(card, player_list);
	}
	XHSBotSetupLog("card_build_completed", {
		card_id: "XHSBotSetupCard",
	});
	return true;
}

function XHSBotSetupDestroyCard(reason) {
	var card = xhs_bot_setup_ui.card;
	if (!card) {
		return;
	}

	card.style.visibility = "collapse";
	card.hittest = false;
	card.hittestchildren = false;
	xhs_bot_setup_ui = {};
	if (typeof card.DeleteAsync === "function") {
		card.DeleteAsync(0.0);
	}
	XHSBotSetupLog("card_destroyed", {
		reason: String(reason || "unanimous_vote_missing"),
	});
}

function XHSBotSetupSyncCard(reason) {
	UpdateAIVoteUnanimityUI();
	if (!XHSBotSetupHasUnanimousApproval()) {
		XHSBotSetupDestroyCard(reason);
		return;
	}

	if (!xhs_bot_setup_ui.card && !XHSBotSetupBuildCard()) {
		return;
	}
	XHSBotSetupStartIdentityWatch();
	XHSBotSetupRender(reason);
}

function XHSBotSetupRender(reason) {
	if (!IsXHSBotSetupAllowed() || !xhs_bot_setup_ui.card) {
		XHSBotSetupLog("render_skipped", {
			reason: String(reason || "unspecified"),
			setup_allowed: IsXHSBotSetupAllowed(),
			has_card: !!xhs_bot_setup_ui.card,
		});
		return;
	}

	var available = XHSBotSetupHasUnanimousApproval();
	if (!available) {
		XHSBotSetupDestroyCard(reason);
		return;
	}
	xhs_bot_setup_ui.card.style.visibility = "visible";
	xhs_bot_setup_ui.card.hittest = true;
	xhs_bot_setup_ui.card.hittestchildren = true;
	UpdateAIVoteUnanimityUI();

	var controller = available && XHSBotSetupIsController();
	var locked = available && IsTruthy(xhs_bot_setup_config.locked);
	var can_edit = !!XHSBotSetupCanEdit();
	var maximum = XHSBotSetupMaxBots();
	var count = Math.max(0, Math.min(maximum, Math.floor(ToNumber(xhs_bot_setup_draft.bot_count, 0))));
	XHSBotSetupLog("render_started", {
		reason: String(reason || "unspecified"),
		available: available,
		controller: controller,
		locked: locked,
		can_edit: can_edit,
		count: count,
		maximum: maximum,
	});

	xhs_bot_setup_ui.card.SetHasClass("IsWaiting", !available);
	xhs_bot_setup_ui.card.SetHasClass("IsReadOnly", available && !controller);
	xhs_bot_setup_ui.card.SetHasClass("IsLocked", locked);
	xhs_bot_setup_ui.card.SetHasClass("IsPending", xhs_bot_setup_pending);
	var spectator_access = XHSBotSetupHasSpectatorAccess();
	xhs_bot_setup_ui.spectator_row.style.visibility = spectator_access ? "visible" : "collapse";

	xhs_bot_setup_ui.count_value.text = count + " / " + maximum;
	var human_count = Math.max(1, Math.floor(ToNumber(
		xhs_bot_setup_config && xhs_bot_setup_config.human_count,
		xhs_bot_setup_config && xhs_bot_setup_config.vote_total
	)));
	var total_players = human_count + count;
	var show_performance_warning = count > 0 && total_players > 4;
	xhs_bot_setup_ui.performance_warning.text = LocalizeTemplate(
		"loading_screen_bot_setup_performance_warning",
		{ total: total_players.toString() }
	);
	xhs_bot_setup_ui.performance_warning.style.visibility = show_performance_warning
		? "visible"
		: "collapse";
	XHSBotSetupSetButtonEnabled(xhs_bot_setup_ui.count_minus, can_edit && count > 0);
	XHSBotSetupSetButtonEnabled(xhs_bot_setup_ui.count_plus, can_edit && count < maximum);

	for (var difficulty in xhs_bot_setup_ui.difficulty) {
		var difficulty_button = xhs_bot_setup_ui.difficulty[difficulty];
		difficulty_button.SetHasClass("Selected", difficulty === xhs_bot_setup_draft.ai_difficulty);
		XHSBotSetupSetButtonEnabled(difficulty_button, can_edit);
	}
	xhs_bot_setup_ui.spectator.off.SetHasClass("Selected", !xhs_bot_setup_draft.spectator_mode);
	xhs_bot_setup_ui.spectator.on.SetHasClass("Selected", !!xhs_bot_setup_draft.spectator_mode);
	XHSBotSetupSetButtonEnabled(xhs_bot_setup_ui.spectator.off, can_edit && spectator_access);
	XHSBotSetupSetButtonEnabled(xhs_bot_setup_ui.spectator.on, can_edit && spectator_access);
	xhs_bot_setup_ui.spectator_note.style.visibility = xhs_bot_setup_draft.spectator_mode
		? "visible"
		: "collapse";

	var difficulty_text = L("loading_screen_bot_setup_" + xhs_bot_setup_draft.ai_difficulty);
	var composition = String(
		(xhs_bot_setup_config && xhs_bot_setup_config.composition) || "random"
	).toLowerCase();
	var composition_text = L("loading_screen_bot_setup_" + composition);
	xhs_bot_setup_ui.summary.text = LocalizeTemplate("loading_screen_bot_setup_summary", {
		count: count.toString(),
		difficulty: difficulty_text,
		composition: composition_text,
	});

	if (xhs_bot_setup_pending) {
		xhs_bot_setup_ui.controller.text = L("loading_screen_bot_setup_pending");
	} else if (locked) {
		xhs_bot_setup_ui.controller.text = L("loading_screen_bot_setup_locked");
	} else if (controller) {
		xhs_bot_setup_ui.controller.text = L("loading_screen_bot_setup_controller");
	} else {
		xhs_bot_setup_ui.controller.text = L("loading_screen_bot_setup_controller_only");
	}

	var server_status = xhs_bot_setup_config ? String(xhs_bot_setup_config.status || "waiting") : "waiting";
	xhs_bot_setup_ui.status.text = LocalizeTemplate("loading_screen_bot_setup_server_status", {
		status: server_status,
	});

	var error_text = xhs_bot_setup_config ? String(xhs_bot_setup_config.error || "") : "";
	xhs_bot_setup_ui.error.text = error_text;
	xhs_bot_setup_ui.error.style.visibility = error_text ? "visible" : "collapse";
	XHSBotSetupSetButtonEnabled(xhs_bot_setup_ui.confirm, can_edit && xhs_bot_setup_dirty);
	XHSBotSetupLog("render_completed", {
		reason: String(reason || "unspecified"),
		displayed_count: count + " / " + maximum,
		count_minus_enabled: can_edit && count > 0,
		count_plus_enabled: can_edit && count < maximum,
		difficulty_enabled: can_edit,
		spectator_enabled: can_edit,
		confirm_enabled: can_edit && xhs_bot_setup_dirty,
		server_status: server_status,
		error_text: error_text,
	});
}

function XHSBotSetupOnNetTableChanged(table_name, key, data) {
	XHSBotSetupLog("nettable_changed", {
		table_name: String(table_name || ""),
		key: String(key || ""),
		data: data || null,
	});
	if (!IsXHSBotSetupAllowed()) {
		XHSBotSetupLog("nettable_change_ignored", {
			key: String(key || ""),
			reason: "setup_not_allowed",
		});
		return;
	}

	if (key === "config") {
		var was_pending = xhs_bot_setup_pending;
		var received_revision = Math.floor(ToNumber(data && data.revision, -1));
		var acknowledged = was_pending && received_revision >= xhs_bot_setup_expected_revision;
		XHSBotSetupLog("config_received", {
			was_pending: was_pending,
			received_revision: received_revision,
			expected_revision: xhs_bot_setup_expected_revision,
			acknowledged: acknowledged,
			data: data || null,
		});
		xhs_bot_setup_config = data || null;

		if (!xhs_bot_setup_synced || acknowledged || (!xhs_bot_setup_dirty && !was_pending)) {
			XHSBotSetupSyncDraftFromConfig();
		}
		if (acknowledged) {
			xhs_bot_setup_pending = false;
			xhs_bot_setup_dirty = false;
			XHSBotSetupSyncDraftFromConfig();
		} else if (was_pending && data && data.error) {
			xhs_bot_setup_pending = false;
		}
		XHSBotSetupLog("config_processed", {
			acknowledged: acknowledged,
			was_pending: was_pending,
			received_revision: received_revision,
		});
		XHSBotSetupSyncCard("nettable_config");
		return;
	}

	if (key === "roster") {
		xhs_bot_setup_roster = data || { count: 0, players: {} };
		XHSBotSetupLog("roster_processed", {
			count: Math.floor(ToNumber(xhs_bot_setup_roster.count, 0)),
			data: data || null,
		});
		XHSBotSetupSyncCard("nettable_roster");
		return;
	}
	if (key === "spectator_access_" + GetLocalPlayerIDSafe()) {
		xhs_bot_setup_spectator_access = data || { allowed: 0 };
		XHSBotSetupSyncCard("nettable_spectator_access");
		return;
	}
	XHSBotSetupLog("nettable_change_ignored", {
		key: String(key || ""),
		reason: "unhandled_key",
	});
}

function MaybeInitializeXHSBotSetup() {
	XHSBotSetupLog("initialize_called", {});
	if (!IsXHSBotSetupAllowed() || xhs_bot_setup_initialized) {
		XHSBotSetupLog("initialize_skipped", {
			reason: !IsXHSBotSetupAllowed() ? "setup_not_allowed" : "already_initialized",
		});
		return;
	}
	XHSBotSetupLog("initialize_started", {});
	xhs_bot_setup_initialized = true;

	if (typeof CustomNetTables !== "undefined" && CustomNetTables) {
		XHSBotSetupLog("nettable_subscribe_started", {
			table_name: "xhs_bots",
		});
		CustomNetTables.SubscribeNetTableListener("xhs_bots", XHSBotSetupOnNetTableChanged);
		XHSBotSetupLog("nettable_subscribe_completed", {
			table_name: "xhs_bots",
		});

		var initial_config = CustomNetTables.GetTableValue("xhs_bots", "config");
		XHSBotSetupLog("initial_config_read", {
			data: initial_config || null,
			was_undefined: initial_config === undefined,
		});
		if (initial_config) {
			xhs_bot_setup_config = initial_config;
			XHSBotSetupSyncDraftFromConfig();
		}

		var initial_roster = CustomNetTables.GetTableValue("xhs_bots", "roster");
		XHSBotSetupLog("initial_roster_read", {
			data: initial_roster || null,
			was_undefined: initial_roster === undefined,
		});
		if (initial_roster) {
			xhs_bot_setup_roster = initial_roster;
		}

		var initial_spectator_access = CustomNetTables.GetTableValue(
			"xhs_bots",
			"spectator_access_" + GetLocalPlayerIDSafe()
		);
		if (initial_spectator_access) {
			xhs_bot_setup_spectator_access = initial_spectator_access;
		}
	} else {
		XHSBotSetupLog("nettable_unavailable", {});
	}
	XHSBotSetupSyncCard("initialize");
	XHSBotSetupLog("initialize_completed", {});
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

function IsGameModeVoteType(vote_type) {
	return vote_type == "gamemode" || vote_type == "mode";
}

function GetLocalizedItemName(item_name) {
	return LocalizeWithFallback("#DOTA_Tooltip_ability_" + item_name);
}

var XHS_DIFFICULTY_VOTE_ICONS = {
	gold: { image: "s2r://panorama/images/items/hand_of_midas_png.vtex" },
	ankh: { item: "item_ankh_of_reincarnation" },
	lifesteal: { item: "item_lifesteal_mask" },
};

function CreateDifficultyVoteIcon(parent, icon_config) {
	if (icon_config && icon_config.item) {
		var item_icon = $.CreatePanel("DOTAItemImage", parent, "");
		item_icon.AddClass("vote-difficulty-stat-icon");
		item_icon.itemname = icon_config.item;
		return item_icon;
	}

	var icon = $.CreatePanel("Panel", parent, "");
	icon.AddClass("vote-difficulty-stat-icon");
	if (icon_config && icon_config.image) {
		icon.style.backgroundImage = 'url("' + icon_config.image + '")';
	}

	return icon;
}

function CreateDifficultyVoteStat(parent, icon_config, label_text, value_text, class_name) {
	var row = $.CreatePanel("Panel", parent, "");
	row.AddClass("vote-difficulty-stat-row");
	if (class_name) {
		row.AddClass(class_name);
	}

	CreateDifficultyVoteIcon(row, icon_config);

	var copy = $.CreatePanel("Panel", row, "");
	copy.AddClass("vote-difficulty-stat-copy");

	var label = $.CreatePanel("Label", copy, "");
	label.AddClass("vote-difficulty-stat-label");
	label.text = label_text;

	var value = $.CreatePanel("Label", copy, "");
	value.AddClass("vote-difficulty-stat-value");
	value.text = value_text;
}

function CreateDifficultyVoteDescription(parent, description_text) {
	var description = $.CreatePanel("Panel", parent, "");
	description.AddClass("vote-difficulty-description");

	var lines = (description_text || "").split("\n");
	for (var i = 0; i < lines.length; i++) {
		var line_text = lines[i];
		if (!line_text) {
			continue;
		}

		var row = $.CreatePanel("Panel", description, "");
		row.AddClass("vote-difficulty-description-row");

		var dot = $.CreatePanel("Panel", row, "");
		dot.AddClass("vote-difficulty-description-dot");

		var separator_index = line_text.lastIndexOf(":");
		if (separator_index > 0) {
			var name = $.CreatePanel("Label", row, "");
			name.AddClass("vote-difficulty-description-name");
			name.text = line_text.substring(0, separator_index + 1);

			var value = $.CreatePanel("Label", row, "");
			value.AddClass("vote-difficulty-description-value");
			value.text = line_text.substring(separator_index + 1).trim();
		} else {
			var line = $.CreatePanel("Label", row, "");
			line.AddClass("vote-difficulty-description-line");
			line.text = line_text;
		}
	}
}

function CreateModeVoteDescription(vote_button, description_text) {
	if (!vote_button) {
		return false;
	}

	var native_descriptions = vote_button.FindChildrenWithClassTraverse("vote-select-description");
	var description = native_descriptions && native_descriptions[0] ? native_descriptions[0] : null;
	if (!description) {
		return false;
	}

	var lines = (description_text || "").split("\n");
	var formatted_lines = [];
	for (var i = 0; i < lines.length; i++) {
		var line_text = lines[i];
		if (!line_text) {
			continue;
		}

		line_text = line_text.replace(/^\s*-\s*/, "");
		formatted_lines.push("• " + line_text);
	}

	description.text = formatted_lines.join("\n");
	description.AddClass("vote-mode-description-native");

	return true;
}

function CreateDifficultyVoteStats(vote_button, difficulty_index, description_text) {
	var stats = XHS_DIFFICULTY_VOTE_STATS[difficulty_index];
	if (!stats || !vote_button) {
		return false;
	}

	var stats_panel = $.CreatePanel("Panel", vote_button, "");
	stats_panel.AddClass("vote-difficulty-stats");

	CreateDifficultyVoteDescription(stats_panel, description_text);

	CreateDifficultyVoteStat(
		stats_panel,
		XHS_DIFFICULTY_VOTE_ICONS.gold,
		L("loading_screen_vote_difficulty_starting_gold_short"),
		FormatLoadingScreenNumber(stats.starting_gold),
		"VoteDifficultyGold"
	);
	CreateDifficultyVoteStat(
		stats_panel,
		XHS_DIFFICULTY_VOTE_ICONS.ankh,
		L("loading_screen_vote_difficulty_ankhs_short"),
		stats.ankhs.toString(),
		"VoteDifficultyAnkhs"
	);

	if (stats.bonus_item == "item_lifesteal_mask") {
		CreateDifficultyVoteStat(
			stats_panel,
			XHS_DIFFICULTY_VOTE_ICONS.lifesteal,
			L("loading_screen_vote_difficulty_bonus_short"),
			GetLocalizedItemName(stats.bonus_item),
			"VoteDifficultyBonus"
		);
	}

	var buttons = vote_button.FindChildrenWithClassTraverse("vote-button");
	var choice_button = buttons && buttons[0] ? buttons[0] : null;
	if (choice_button && vote_button.MoveChildBefore) {
		vote_button.MoveChildBefore(stats_panel, choice_button);
	}

	return true;
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
	var local_player_id = -1;
	try {
		if (Game.GetLocalPlayerID) {
			var game_local_player_id = Game.GetLocalPlayerID();
			if (game_local_player_id !== undefined && game_local_player_id !== null && game_local_player_id !== "") {
				local_player_id = Number(game_local_player_id);
			}
		}
	} catch (game_local_player_error) {}

	if ((isNaN(local_player_id) || local_player_id < 0) && typeof Players !== "undefined" && Players.GetLocalPlayer) {
		try {
			var players_local_player_id = Players.GetLocalPlayer();
			if (players_local_player_id !== undefined && players_local_player_id !== null && players_local_player_id !== "") {
				local_player_id = Number(players_local_player_id);
			}
		} catch (players_local_player_error) {}
	}

	if (isNaN(local_player_id) || local_player_id < 0) {
		var local_info = null;
		try {
			local_info = Game.GetLocalPlayerInfo ? Game.GetLocalPlayerInfo() : null;
		} catch (local_info_error) {}
		local_player_id = GetPlayerIDCandidateFromInfo(local_info);
	}

	if (local_player_id === undefined || local_player_id === null || isNaN(local_player_id) || local_player_id < 0) {
		return -1;
	}

	return Math.floor(local_player_id);
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
		daily_gameplay_fragments: Math.max(0, ToNumber(player_table.daily_gameplay_fragments, 0)),
		daily_gameplay_cap: Math.max(1, ToNumber(player_table.daily_gameplay_cap, 100)),
		daily_quest_fragments: Math.max(0, ToNumber(player_table.daily_quest_fragments, 0)),
		daily_quest_cap: Math.max(1, ToNumber(player_table.daily_quest_cap, 90)),
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

	return "Game " + FormatIntegerValue(Math.max(0, ToNumber(profile_data.daily_gameplay_fragments, 0))) + "/" + FormatIntegerValue(Math.max(1, ToNumber(profile_data.daily_gameplay_cap, 100))) + " + Quests " + FormatIntegerValue(Math.max(0, ToNumber(profile_data.daily_quest_fragments, 0))) + "/" + FormatIntegerValue(Math.max(1, ToNumber(profile_data.daily_quest_cap, 90)));
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
		$.Msg("OnCustomSetupReadyPressed: failed state, ignoring click");
		PlayLoadingSound(LOADING_SCREEN_CONFIG.audio.failed_events);
		return;
	}

	var local_player_id = GetLocalPlayerIDSafe();

	if (local_player_id < 0) {
		$.Msg("OnCustomSetupReadyPressed: invalid local player id, ignoring click");
		PlayLoadingSound(LOADING_SCREEN_CONFIG.audio.failed_events);
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
				$.Msg("OnCustomSetupReadyPressed: pending token mismatch, ignoring lock");
				return;
			}

			if (!local_ready_click_pending) {
				$.Msg("OnCustomSetupReadyPressed: local_ready_click_pending is false, ignoring lock");
				return;
			}

			local_ready_click_pending = false;
			UpdatePlayerLoadingSidebar();
		});
	} else {
		$.Msg("OnCustomSetupReadyPressed: GameEvents.SendCustomGameEventToServer unavailable, ignoring click");
		PlayLoadingSound(LOADING_SCREEN_CONFIG.audio.failed_events);
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
	var resolved_name = NormalizePlayerDisplayName(player_info && player_info.player_name);
	var hero_name = NormalizePlayerDisplayName(player_info && player_info.player_selected_hero);
	var info_fallback = null;

	if (player_id !== undefined && player_id >= 0 && typeof Players !== "undefined") {
		if (!resolved_name && typeof Players.GetPlayerName === "function") {
			resolved_name = NormalizePlayerDisplayName(Players.GetPlayerName(player_id));
		}
		if (!hero_name && typeof Players.GetPlayerSelectedHero === "function") {
			hero_name = NormalizePlayerDisplayName(Players.GetPlayerSelectedHero(player_id));
		}
	}

	if (player_id !== undefined && player_id >= 0 && typeof Game.GetPlayerInfo === "function") {
		info_fallback = Game.GetPlayerInfo(player_id);
		if (!resolved_name) {
			resolved_name = NormalizePlayerDisplayName(info_fallback && info_fallback.player_name);
		}
		if (!hero_name) {
			hero_name = NormalizePlayerDisplayName(info_fallback && info_fallback.player_selected_hero);
		}
	}

	var local_player_id = GetLocalPlayerIDSafe();
	if (player_id == local_player_id || player_id < 0) {
		var local_info = Game.GetLocalPlayerInfo();
		if (!resolved_name) {
			resolved_name = NormalizePlayerDisplayName(local_info && local_info.player_name);
		}
		if (!hero_name) {
			hero_name = NormalizePlayerDisplayName(local_info && local_info.player_selected_hero);
		}
	}

	if (typeof XHSNameDisplay !== "undefined" && XHSNameDisplay.Resolve) {
		return XHSNameDisplay.Resolve({
			playerID: player_id,
			playerName: resolved_name,
			heroName: hero_name,
			playerFallback: L("loading_screen_player"),
		});
	}

	// Privacy-safe fallback: loading must never reveal a persona name merely
	// because the shared helper failed to initialize.
	if (!hero_name) {
		return "";
	}
	var localized_hero = $.Localize("#" + hero_name);
	return localized_hero && localized_hero !== ("#" + hero_name)
		? localized_hero
		: hero_name.replace(/^npc_dota_hero_/, "").replace(/_/g, " ").toUpperCase();
}

function IsLoadingScreenContextValid() {
	return !!loading_screen_context_panel &&
		(!loading_screen_context_panel.IsValid || loading_screen_context_panel.IsValid());
}

function SchedulePlayerLoadingSidebar(delay) {
	$.Schedule(delay, function () {
		if (IsLoadingScreenContextValid()) {
			UpdatePlayerLoadingSidebar();
		}
	});
}

function UpdatePlayerLoadingSidebar() {
	if (!IsLoadingScreenContextValid()) {
		return;
	}

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

	if (local_player_id < 0) {
		SchedulePlayerLoadingSidebar(0.2);
		return;
	}

	let player_ids = GetLoadingScreenPlayerIDs();

	var xhs_bot_roster_players = GetXHSBotRosterPlayers();
	for (var xhs_bot_player_key in xhs_bot_roster_players) {
		var xhs_bot_player_id = parseInt(xhs_bot_player_key);
		if (!isNaN(xhs_bot_player_id) && xhs_bot_player_id >= 0 && player_ids.indexOf(xhs_bot_player_id) < 0) {
			player_ids.push(xhs_bot_player_id);
		}
	}

	player_ids = player_ids.slice(0).sort(function (a, b) { return a - b; });

	var local_player_info = null;
	try {
		local_player_info = local_player_id >= 0 ? Game.GetPlayerInfo(local_player_id) : null;
	} catch (local_player_info_error) {}
	if (!local_player_info) {
		try {
			local_player_info = Game.GetLocalPlayerInfo();
		} catch (local_player_fallback_error) {}
	}
	var local_team_id = GetPlayerTeamIDFromInfo(local_player_info, GetDefaultFriendlyTeamID());

	const player_entries = [];

	for (var i = 0; i < player_ids.length; i++) {
		const player_id = player_ids[i];
		const roster_bot = GetXHSBotRosterEntry(player_id);
		var raw_player_info = null;
		var local_player_fallback = null;
		try {
			raw_player_info = Game.GetPlayerInfo(player_id);
		} catch (player_info_error) {}
		if (player_id == local_player_id) {
			try {
				local_player_fallback = Game.GetLocalPlayerInfo();
			} catch (local_player_entry_error) {}
		}
		const player_info = raw_player_info || local_player_fallback || (roster_bot ? {
			player_connection_state: IsTruthy(roster_bot.ready) ? connection_state.CONNECTED : connection_state.LOADING,
			player_selected_hero: roster_bot.hero || "",
			player_team_id: GetDefaultFriendlyTeamID(),
		} : null);

		if (!player_info) {
			continue;
		}

		var display_name = roster_bot ? GetXHSBotDisplayName(player_id, roster_bot) : GetPlayerDisplayName(player_id, player_info);
		if (!display_name) {
			display_name = L("loading_screen_player") + " " + (player_id + 1).toString();
		}

		player_entries.push({
			row_key: roster_bot ? ("bot_" + player_id) : player_id.toString(),
			player_id: player_id,
			player_info: player_info,
			display_name: display_name,
			team_id: GetPlayerTeamIDFromInfo(player_info, local_team_id),
			can_open_profile: !roster_bot,
			is_xhs_bot: !!roster_bot,
			bot_data: roster_bot,
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
		const seeded_state = seeded_entry.is_xhs_bot
			? (IsTruthy(seeded_entry.bot_data && seeded_entry.bot_data.ready) ? connection_state.CONNECTED : connection_state.LOADING)
			: (isNaN(Number(seeded_entry.player_info.player_connection_state))
				? connection_state.NOT_YET_CONNECTED
				: Number(seeded_entry.player_info.player_connection_state));
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
		const is_xhs_bot = entry.is_xhs_bot === true;
		const bot_data = entry.bot_data || null;
		const is_loaded = is_xhs_bot ? IsTruthy(bot_data && bot_data.ready) : IsLoadedConnectionState(state);
		const is_issue = is_xhs_bot ? false : IsIssueConnectionState(state);
		const is_connecting = !is_loaded && !is_issue;

		if (!active_sections[team_key]) {
			active_sections[team_key] = true;

			if (!player_loading_section_rows[team_key]) {
				player_loading_panel_serial = player_loading_panel_serial + 1;
				var section_row = $.CreatePanel("Label", list_parent, "PlayerLoadingSection_" + team_key + "_" + player_loading_panel_serial);
				section_row.AddClass("player-loading-section");
				player_loading_section_rows[team_key] = section_row;
			}

			var section_title = GetTeamDisplayName(team_id);
			player_loading_section_rows[team_key].text = section_title + " (" + (section_counts[team_key] || 0) + ")";
		}

		active_rows[row_key] = true;

		if (!is_xhs_bot) {
			total_players = total_players + 1;

			if (is_loaded) {
				loaded_players = loaded_players + 1;
			} else if (is_connecting) {
				waiting_players = waiting_players + 1;
			}

			if (is_issue) {
				issue_players = issue_players + 1;
			}
		}

		if (!player_loading_rows[row_key]) {
			const safe_row_key = row_key.toString().replace(/[^a-zA-Z0-9_]/g, "_");
			player_loading_panel_serial = player_loading_panel_serial + 1;
			const row = $.CreatePanel("Panel", list_parent, "PlayerLoadingRow_" + safe_row_key + "_" + player_loading_panel_serial);
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
			avatar_fallback_label.text = is_xhs_bot ? "AI" : "?";
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
				avatar_fallback_label: avatar_fallback_label,
				supporter_badge: supporter_badge,
				supporter_badge_label: supporter_badge_label,
				name: name,
				status: status_label,
				player_id: player_id,
			};

		}

		const player_row = player_loading_rows[row_key];
		player_row.player_id = player_id;
		player_row.can_open_profile = entry.can_open_profile;
		if (player_row.avatar_wrap) {
			player_row.avatar_wrap.AddClass("player-loading-avatar-wrap");
			player_row.avatar_wrap.hittest = entry.can_open_profile;
			player_row.avatar_wrap.hittestchildren = false;
		}
		if (player_row.avatar_fallback) {
			player_row.avatar_fallback.AddClass("player-loading-avatar-fallback");
			player_row.avatar_fallback.hittest = false;
		}
		if (player_row.avatar) {
			player_row.avatar.hittest = false;
		}
		const is_marked_ready = is_xhs_bot
			? IsTruthy(bot_data && bot_data.ready)
			: (player_id >= 0 && IsPlayerMarkedReady(setup_status, player_id));
		const is_selected = !is_xhs_bot && player_id >= 0 && player_id == GetSelectedProfilePlayerID();
		if (is_xhs_bot) {
			XHSBotSetupEnsureHeroDropdown(player_row, bot_data);
		}

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
			fallback_label.text = is_xhs_bot ? "AI" : "?";
			fallback_label.style.width = "100%";
			fallback_label.style.height = "100%";
			fallback_label.style.textAlign = "center center";
			fallback_label.style.verticalAlign = "center";
			fallback_label.style.fontSize = "16px";
			fallback_label.style.color = "#9eb0c9";
			fallback_label.style.fontFamily = "Reaver";
			fallback_label.hittest = false;
			player_row.avatar_fallback_label = fallback_label;
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

		if (entry.can_open_profile) {
			(function (avatar_anchor, target_player_id) {
				avatar_anchor.SetPanelEvent("onmouseover", function () {
					$.DispatchEvent("UIHideTextTooltip", avatar_anchor);
					ShowPlayerLoadingProfileHover(target_player_id, avatar_anchor);
				});

				avatar_anchor.SetPanelEvent("onmouseout", function () {
					HidePlayerLoadingProfileHover();
				});
			})(player_row.avatar_wrap, player_id);
		} else {
			player_row.avatar_wrap.SetPanelEvent("onmouseover", function () {});
			player_row.avatar_wrap.SetPanelEvent("onmouseout", function () {});
		}

		const profile_data = entry.can_open_profile ? GetProfileDataForPlayer(player_id) : {};
		const supporter_tier_id = GetLoadingSupporterTierID(profile_data);
		const supporter_tier_color = GetSupporterTierColor(profile_data);
		const supporter_badge_text = GetLoadingSupporterTierLetter(profile_data);

		const bot_difficulty = is_xhs_bot ? String((bot_data && bot_data.difficulty) || "normal").toLowerCase() : "";
		const bot_difficulty_text = is_xhs_bot ? L("loading_screen_bot_setup_" + bot_difficulty) : "";
		const status_text = is_xhs_bot
			? LocalizeTemplate(is_marked_ready ? "loading_screen_ai_ready_status" : "loading_screen_ai_ally_status", {
				difficulty: bot_difficulty_text,
			})
			: (is_marked_ready ? L("loading_screen_ready") : GetConnectionStateText(state));
		const row_visual_signature = [
			state,
			is_xhs_bot ? "bot" : "human",
			is_xhs_bot && bot_data ? String(bot_data.role || "") : "",
			is_loaded ? "1" : "0",
			is_issue ? "1" : "0",
			is_connecting ? "1" : "0",
			is_selected ? "1" : "0",
			is_marked_ready ? "1" : "0",
			entry.can_open_profile ? "1" : "0",
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
			player_row.panel.SetHasClass("PlayerLoadingBot", is_xhs_bot);
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
			is_xhs_bot && bot_data ? String(bot_data.hero || "") : "",
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

			if (player_row.avatar_fallback_label) {
				player_row.avatar_fallback_label.text = is_xhs_bot ? "AI" : "?";
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
		const can_show_ready = setup_active && local_player_id >= 0 && local_player_eligible;
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

	SchedulePlayerLoadingSidebar(0.2);
	} catch (err) {
		SchedulePlayerLoadingSidebar(0.5);
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
	if (game_options == undefined) {
		if (loading_screen_last_fetch_stage !== "waiting_game_options") {
			loading_screen_last_fetch_stage = "waiting_game_options";
		}
		$.Schedule(0.1, fetch);
		return;
	}

	// The authoritative game type is now available. Keep this call before any
	// API dependency so the Tools-only setup remains usable offline.
	XHSBotSetupLog("fetch_initialize_dispatch", {});
	MaybeInitializeXHSBotSetup();
	XHSBotSetupLog("fetch_initialize_returned", {});

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

function FormatCustomPollCount(value) {
	var count = Math.max(0, Math.floor(ToNumber(value, 0)));
	if (count >= 1000000) {
		return (count / 1000000).toFixed(count >= 10000000 ? 0 : 1).replace(".0", "") + "M";
	}
	if (count >= 1000) {
		return (count / 1000).toFixed(count >= 10000 ? 0 : 1).replace(".0", "") + "K";
	}
	return count.toString();
}

function CustomPollTableToArray(value) {
	if (!value) {
		return [];
	}

	if (Array.isArray && Array.isArray(value)) {
		return value.slice(0);
	}

	var out = [];
	for (var key in value) {
		if (value[key] !== undefined && value[key] !== null) {
			out.push(value[key]);
		}
	}

	out.sort(function (a, b) {
		var order_a = ToNumber(a.sort_order !== undefined ? a.sort_order : a.rank, 999999);
		var order_b = ToNumber(b.sort_order !== undefined ? b.sort_order : b.rank, 999999);
		if (order_a == order_b) {
			return String(a.option_id || a.poll_id || "").localeCompare(String(b.option_id || b.poll_id || ""));
		}
		return order_a - order_b;
	});

	return out;
}

function GetCustomPolls() {
	if (!custom_poll_state || !custom_poll_state.polls) {
		return [];
	}

	var polls = [];
	var source = CustomPollTableToArray(custom_poll_state.polls);
	for (var i = 0; i < source.length; i++) {
		if (source[i]) {
			polls.push(source[i]);
		}
	}

	polls.sort(function (a, b) {
		var priority_a = ToNumber(a.priority, 0);
		var priority_b = ToNumber(b.priority, 0);
		if (priority_a == priority_b) {
			return String(a.poll_id || "").localeCompare(String(b.poll_id || ""));
		}
		return priority_b - priority_a;
	});

	return polls;
}

function IsCustomPollVoted(poll) {
	return !!(poll && poll.player && poll.player.voted);
}

function GetCustomPollSelectedOptionID(poll) {
	if (!poll || !poll.player || poll.player.selected_option_id === undefined || poll.player.selected_option_id === null) {
		return "";
	}
	return String(poll.player.selected_option_id);
}

function GetNextUnvotedCustomPoll() {
	var polls = GetCustomPolls();
	for (var i = 0; i < polls.length; i++) {
		if (!IsCustomPollVoted(polls[i])) {
			return polls[i];
		}
	}
	return null;
}

function GetCustomPollByID(poll_id) {
	var polls = GetCustomPolls();
	for (var i = 0; i < polls.length; i++) {
		if (String(polls[i].poll_id) == String(poll_id)) {
			return polls[i];
		}
	}
	return null;
}

function GetCustomPollResults(poll) {
	if (!poll) {
		return null;
	}
	if (poll.player && poll.player.results) {
		return poll.player.results;
	}
	return poll.results || null;
}

function GetCustomPollResultForOption(results, option_id) {
	if (!results || !results.options) {
		return null;
	}

	var result_options = CustomPollTableToArray(results.options);
	for (var i = 0; i < result_options.length; i++) {
		var row = result_options[i];
		if (row && String(row.option_id) == String(option_id)) {
			return row;
		}
	}

	return null;
}

function UpdateCustomPollReviewButton() {
	var button = $("#CustomPollReviewButton");
	if (!button) {
		return;
	}

	var has_review = false;
	var polls = GetCustomPolls();
	for (var i = 0; i < polls.length; i++) {
		if (IsCustomPollVoted(polls[i])) {
			has_review = true;
			break;
		}
	}

	button.visible = has_review;
	button.SetHasClass("HasPolls", has_review);
}

function SetVoteModalTitleText(text) {
	const vote_title = $.GetContextPanel().FindChildrenWithClassTraverse("vote-content-title");
	if (vote_title && vote_title[0]) {
		vote_title[0].text = text;
	}
}

function ClearVoteModalContent() {
	const vote_content = $("#VoteContent");
	if (vote_content) {
		vote_content.RemoveAndDeleteChildren();
	}
}

function CreateCustomPollResults(parent, poll, selected_option_id) {
	var results = GetCustomPollResults(poll);
	if (!results || !results.options) {
		return;
	}

	var results_panel = $.CreatePanel("Panel", parent, "");
	results_panel.AddClass("custom-poll-results");

	var total = Math.max(0, Math.floor(ToNumber(results.total_votes, 0)));
	var header = $.CreatePanel("Label", results_panel, "");
	header.AddClass("custom-poll-results-title");
	header.text = "Results - " + FormatCustomPollCount(total) + " votes";

	var poll_options = CustomPollTableToArray(poll.options);
	for (var i = 0; i < poll_options.length; i++) {
		var option = poll_options[i];
		var result = GetCustomPollResultForOption(results, option.option_id) || {};
		var votes = Math.max(0, Math.floor(ToNumber(result.votes, 0)));
		var percent = Math.max(0, Math.min(100, ToNumber(result.percent, 0)));
		var rank = Math.max(0, Math.floor(ToNumber(result.rank, i + 1)));

		var row = $.CreatePanel("Panel", results_panel, "");
		row.AddClass("custom-poll-result-row");
		row.SetHasClass("IsSelected", String(option.option_id) == String(selected_option_id));

		var top = $.CreatePanel("Panel", row, "");
		top.AddClass("custom-poll-result-top");

		var name = $.CreatePanel("Label", top, "");
		name.AddClass("custom-poll-result-name");
		name.text = "#" + rank + "  " + option.label;

		var value = $.CreatePanel("Label", top, "");
		value.AddClass("custom-poll-result-value");
		value.text = percent.toFixed(percent >= 10 ? 0 : 1).replace(".0", "") + "% / " + FormatCustomPollCount(votes);

		var bar = $.CreatePanel("ProgressBar", row, "");
		bar.AddClass("custom-poll-result-bar");
		bar.value = percent / 100;
	}
}

function CreateCustomPollOption(parent, poll, option, review_mode, voted, selected_option_id) {
	var option_panel = $.CreatePanel("Panel", parent, "");
	option_panel.AddClass("custom-poll-option");
	var is_selected = String(option.option_id) == String(selected_option_id);
	option_panel.SetHasClass("IsSelected", is_selected);
	option_panel.SetHasClass("IsDisabled", review_mode || voted || poll.pending);

	var title = $.CreatePanel("Label", option_panel, "");
	title.AddClass("custom-poll-option-title");
	title.text = option.label || option.option_id;

	var description = $.CreatePanel("Label", option_panel, "");
	description.AddClass("custom-poll-option-description");
	description.text = option.description || "";

	if (!review_mode && !voted && !poll.pending) {
		option_panel.SetPanelEvent("onactivate", function () {
			SubmitCustomPollVote(poll.poll_id, option.option_id);
		});
	}
}

function BuildCustomPollPanel(poll, review_mode) {
	ClearVoteModalContent();
	vote_modal_mode = "custom_poll";
	custom_poll_active_poll_id = poll ? String(poll.poll_id) : "";
	custom_poll_review_mode = review_mode === true;

	const vote_content = $("#VoteContent");
	if (!vote_content || !poll) {
		return;
	}

	SetVoteModalTitleText(review_mode ? "Your Vote" : "Community Vote");

	var root = $.CreatePanel("Panel", vote_content, "vote_custom_poll");
	root.AddClass("custom-poll-panel");
	root.SetHasClass("ReviewMode", review_mode === true);
	root.SetHasClass("HasResults", !!GetCustomPollResults(poll));

	var header = $.CreatePanel("Panel", root, "");
	header.AddClass("custom-poll-header");

	var eyebrow = $.CreatePanel("Label", header, "");
	eyebrow.AddClass("custom-poll-eyebrow");
	eyebrow.text = review_mode ? "Vote recorded" : "One vote per Steam account";

	var title = $.CreatePanel("Label", header, "");
	title.AddClass("custom-poll-title");
	title.text = poll.title || "Community Vote";

	var description = $.CreatePanel("Label", header, "");
	description.AddClass("custom-poll-description");
	description.text = poll.description || "";

	var player = poll.player || {};
	var voted = player.voted === true;
	var selected_option_id = GetCustomPollSelectedOptionID(poll);

	var options = $.CreatePanel("Panel", root, "");
	options.AddClass("custom-poll-options");
	var poll_options = CustomPollTableToArray(poll.options);
	for (var i = 0; i < poll_options.length; i++) {
		CreateCustomPollOption(options, poll, poll_options[i], review_mode, voted, selected_option_id);
	}

	if (voted || review_mode) {
		CreateCustomPollResults(root, poll, selected_option_id);
	}

	var footer = $.CreatePanel("Panel", root, "");
	footer.AddClass("custom-poll-footer");

	var status = $.CreatePanel("Label", footer, "");
	status.AddClass("custom-poll-status");
	if (poll.pending) {
		status.text = "Saving vote...";
	} else if (custom_poll_status_text) {
		status.text = custom_poll_status_text;
	} else if (voted) {
		status.text = "Vote confirmed. Results are now visible.";
	} else {
		status.text = "Results unlock after your vote.";
	}

	var next_unvoted = GetNextUnvotedCustomPoll();
	var action = $.CreatePanel("Button", footer, "");
	action.AddClass("custom-poll-close-button");
	var action_label = $.CreatePanel("Label", action, "");
	action_label.text = (voted && next_unvoted && String(next_unvoted.poll_id) != String(poll.poll_id)) ? "Next Poll" : "Close";
	action.SetPanelEvent("onactivate", function () {
		custom_poll_status_text = "";
		if (voted) {
			var next = GetNextUnvotedCustomPoll();
			if (next && String(next.poll_id) != String(poll.poll_id)) {
				ShowCustomPoll(next, false);
				return;
			}
		}
		ToggleVoteContainer(false);
	});
}

function ShowCustomPoll(poll, review_mode) {
	if (!poll) {
		return false;
	}

	BuildCustomPollPanel(poll, review_mode === true);
	ToggleVoteContainer(true);
	return true;
}

function TryShowNextCustomPoll(force) {
	if (!force && custom_poll_auto_attempted) {
		return false;
	}

	custom_poll_auto_attempted = true;
	var poll = GetNextUnvotedCustomPoll();
	if (!poll) {
		return false;
	}

	custom_poll_status_text = "";
	return ShowCustomPoll(poll, false);
}

function OpenCustomPollReview() {
	var polls = GetCustomPolls();
	for (var i = 0; i < polls.length; i++) {
		if (IsCustomPollVoted(polls[i])) {
			custom_poll_status_text = "";
			ShowCustomPoll(polls[i], true);
			return;
		}
	}
}

function SubmitCustomPollVote(poll_id, option_id) {
	var poll = GetCustomPollByID(poll_id);
	if (!poll || IsCustomPollVoted(poll) || poll.pending) {
		return;
	}

	custom_poll_status_text = "Saving vote...";
	poll.pending = true;
	BuildCustomPollPanel(poll, false);

	if (typeof GameEvents !== "undefined" && GameEvents && typeof GameEvents.SendCustomGameEventToServer === "function") {
		GameEvents.SendCustomGameEventToServer("xhs_custom_poll_vote", {
			PlayerID: Game.GetLocalPlayerID(),
			poll_id: String(poll_id),
			option_id: String(option_id),
		});
	}
}

function OnCustomPollStateChanged(data) {
	custom_poll_state = data || { polls: [] };
	UpdateCustomPollReviewButton();

	if (vote_modal_mode == "custom_poll" && custom_poll_active_poll_id) {
		var poll = GetCustomPollByID(custom_poll_active_poll_id);
		if (poll) {
			BuildCustomPollPanel(poll, custom_poll_review_mode);
		}
	}

	if (!custom_poll_auto_attempted && (active_vote_sequence.length <= 0 || active_vote_index >= active_vote_sequence.length)) {
		$.Schedule(0.15, function () {
			TryShowNextCustomPoll(false);
		});
	}
}

function OnCustomPollVoteResult(payload) {
	payload = payload || {};
	custom_poll_status_text = payload.success ? "Vote confirmed. Results are now visible." : (payload.message || "Vote failed. Try again.");

	if (payload.state) {
		OnCustomPollStateChanged(payload.state);
		return;
	}

	var poll = GetCustomPollByID(payload.poll_id);
	if (poll) {
		poll.pending = false;
		BuildCustomPollPanel(poll, custom_poll_review_mode);
	}
}

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
	$.Schedule(0.15, function () {
		TryShowNextCustomPoll(false);
	});
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
	vote_modal_mode = "settings";
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
	if (vote_modal_mode == "custom_poll") {
		return;
	}

	if (active_vote_index < 0 || active_vote_index >= active_vote_sequence.length) {
		ToggleVoteContainer(false);
		return;
	}

	vote_progress_category = active_vote_sequence[active_vote_index];
	ShowOnlyVoteCategory(vote_progress_category);
	UpdateVoteProgressTabs();
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
	SetVoteSummaryValue("VoteSelectionDifficulty", "difficulty", local_votes["difficulty"]);
	SetVoteSummaryValue("VoteSelectionAIAllies", "ai_allies", local_votes["ai_allies"]);
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
	root.visible = vote_count > 0 && vote_progress_category == category;

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

	root.SetHasClass("IsActive", vote_progress_category == category);
}

function UpdateAIVoteUnanimityUI() {
	var rule = $("#VoteProgressAIAlliesRule");
	var status_panel = $("#VoteProgressAIAlliesStatus");
	if (rule) {
		rule.text = L("loading_screen_ai_vote_unanimity_rule");
	}
	if (!status_panel) {
		return;
	}

	var config = xhs_bot_setup_config || {};
	var approved = IsTruthy(config.vote_approved) && IsTruthy(config.available);
	var server_status = String(config.status || "awaiting_unanimous_vote");
	var rejected = !approved && server_status == "unanimity_required";
	var vote_yes = Math.max(0, Math.floor(ToNumber(config.vote_yes, 0)));
	var vote_total = Math.max(0, Math.floor(ToNumber(config.vote_total, 0)));
	var status_text = approved
		? L("loading_screen_ai_vote_approved")
		: rejected
			? L("loading_screen_ai_vote_rejected")
			: LocalizeTemplate("loading_screen_ai_vote_pending", {
				yes: vote_yes.toString(),
				total: vote_total.toString(),
			});

	status_panel.text = status_text;
	status_panel.SetHasClass("IsApproved", approved);
	status_panel.SetHasClass("IsRejected", rejected);
	status_panel.SetHasClass("IsPending", !approved && !rejected);
}

function UpdateVoteProgressTabs() {
	if (GetVoteCategoryCount(vote_progress_category) <= 0) {
		vote_progress_category = GetVoteCategoryCount("difficulty") > 0 ? "difficulty" : "ai_allies";
	}

	UpdateVoteProgressTab("difficulty", "VoteProgressDifficulty", "VoteProgressDifficultyRows");
	UpdateVoteProgressTab("ai_allies", "VoteProgressAIAllies", "VoteProgressAIAlliesRows");
	UpdateAIVoteUnanimityUI();

	var difficulty_tab = $("#VoteCategoryTabDifficulty");
	var ai_allies_tab = $("#VoteCategoryTabAIAllies");

	if (difficulty_tab) {
		difficulty_tab.visible = GetVoteCategoryCount("difficulty") > 0;
		difficulty_tab.SetHasClass("IsActive", vote_progress_category == "difficulty");
	}

	if (ai_allies_tab) {
		ai_allies_tab.visible = GetVoteCategoryCount("ai_allies") > 0;
		ai_allies_tab.SetHasClass("IsActive", vote_progress_category == "ai_allies");
	}
}

function ShowVoteProgressCategory(category) {
	if (GetVoteCategoryCount(category) <= 0) {
		return;
	}

	vote_progress_category = category;
	UpdateVoteProgressTabs();
}

function GetFirstUnsubmittedVoteCategory() {
	for (var i = 0; i < active_vote_sequence.length; i++) {
		var category = active_vote_sequence[i];
		if (local_votes[category] === undefined || local_votes[category] === null) {
			return category;
		}
	}
	return "";
}

function UpdateMainVoteButtonState() {
	var main_vote_button = $("#MainVoteButton");
	if (!main_vote_button) {
		return;
	}

	var next_category = GetFirstUnsubmittedVoteCategory();
	var can_vote = next_category !== "";
	main_vote_button.enabled = can_vote;
	main_vote_button.style.visibility = can_vote ? "visible" : "collapse";
	main_vote_button.style.opacity = can_vote ? "1" : "0";
}

function OpenSettingsVoteContainer() {
	var next_category = GetFirstUnsubmittedVoteCategory();
	if (!next_category) {
		UpdateMainVoteButtonState();
		return;
	}

	vote_modal_mode = "settings";
	var category_index = active_vote_sequence.indexOf(next_category);
	if (category_index >= 0) {
		active_vote_index = category_index;
	}
	ToggleVoteContainer(true);
}

function AllPlayersLoaded() {
	const vote_parent = $("#VoteContent");
	const vote_label_container = $("#vote-label-container");
	const main_vote_button = $("#MainVoteButton");

	if (!vote_parent) {
		return;
	}

	// Rebuild from scratch to avoid stale hidden panels / duplicate rows.
	vote_modal_mode = "settings";
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
	vote_progress_category = vote_categories.length > 0 ? vote_categories[0] : "difficulty";
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

			var is_gamemode_vote = IsGameModeVoteType(vote_type);
			vote_button.SetHasClass("VotePanelModeStyled", is_gamemode_vote);
			vote_button.SetHasClass("VotePanelDetailed", is_gamemode_vote && i == 2);

			if (vote_type == "difficulty") {
				var created_difficulty_stats = CreateDifficultyVoteStats(vote_button, i, option_description);
				if (!created_difficulty_stats && description_labels && description_labels[0]) {
					description_labels[0].text = GetVoteOptionDescription(vote_type, i, true);
				}
			} else if (is_gamemode_vote) {
				CreateModeVoteDescription(vote_button, option_description);
			}

			vote_button.SetHasClass("VotePanelCompact", is_compact_description);

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
					if (OnVoteButtonPressed(vote_type, i)) {
						HideVoteCategory(vote_type);
					}
				})
			})(choice_card, vote_type, i);
		}

		panel.SetHasClass("VoteRowCompact", row_is_compact);
		panel.SetHasClass("VoteRowDetailed", IsGameModeVoteType(vote_type));
		RefreshLocalVoteCategoryUI(vote_type);
	}

	UpdateVoteSelectionSummary();
	UpdateVoteProgressTabs();

	const has_vote_options = vote_categories.length > 0;
	UpdateMainVoteButtonState();

	ToggleVoteContainer(has_vote_options);
	if (has_vote_options) {
		ShowCurrentVoteCategory();
	} else {
		$.Schedule(0.15, function () {
			TryShowNextCustomPoll(false);
		});
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

		if (bBoolean && vote_modal_mode != "custom_poll") {
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
	if (local_votes[category] !== undefined && local_votes[category] !== null) {
		return false;
	}

	local_votes[category] = vote;
	local_vote_confirmed[category] = false;
	RefreshLocalVoteCategoryUI(category);
	UpdateVoteSelectionSummary();
	UpdateMainVoteButtonState();
	SendSettingVoteRequest(category, vote, 1);
	return true;
}

function SendSettingVoteRequest(category, vote, attempt) {
	var player_id = GetLocalPlayerIDSafe();
	if (typeof GameEvents === "undefined" || !GameEvents
		|| typeof GameEvents.SendCustomGameEventToServer !== "function") {
		return;
	}

	GameEvents.SendCustomGameEventToServer("setting_vote", {
		category: category,
		vote: vote,
		PlayerID: player_id,
	});

	if (attempt < 4) {
		$.Schedule(0.75, function () {
			if (local_vote_confirmed[category] === true
				|| parseInt(local_votes[category]) !== parseInt(vote)) return;
			SendSettingVoteRequest(category, vote, attempt + 1);
		});
	}
}

function GetVoteCounterFromTable(vote_table) {
	var vote_counter = [];

	if (!vote_table) {
		return vote_counter;
	}

	for (var player_id in vote_table) {
		var vote_row = vote_table[player_id];
		if (!vote_row) {
			continue;
		}

		var gamemode = GetVoteChoiceFromEntry(vote_row);
		var amount_of_votes = GetVoteWeightFromEntry(vote_row);

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
	var local_entry = FindPlayerVoteEntry(vote_table, GetLocalPlayerIDSafe());
	var server_vote = GetVoteChoiceFromEntry(local_entry);
	if (server_vote > 0) {
		local_votes[category] = server_vote;
		local_vote_confirmed[category] = true;
	}
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
	UpdateMainVoteButtonState();
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
	ApplyLoadingScreenStaticLocalization();
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
	}

	HoverableLoadingScreen();

	fetch();

	SetProfileName();

	RefreshProfileDataLoop();

	UpdatePlayerLoadingSidebar();

	$.GetContextPanel().SetHasClass("ProfileModalVisible", false);
	$.GetContextPanel().SetHasClass("ProfileModalClosing", false);

	if (typeof XHSNameDisplay !== "undefined" && XHSNameDisplay.Subscribe) {
		XHSNameDisplay.Subscribe(function () {
			SetProfileName();
			UpdateProfilePanels();
			UpdatePlayerLoadingSidebar();
		});
	}

	if (typeof CustomNetTables !== "undefined" && CustomNetTables && typeof CustomNetTables.SubscribeNetTableListener === "function") {
		CustomNetTables.SubscribeNetTableListener("supporter_pass_player", function (table_name, key, data) {
			UpdateProfilePanels();
			UpdatePlayerLoadingSidebar();
		});
		CustomNetTables.SubscribeNetTableListener("custom_polls", function (table_name, key, data) {
			if (String(key) == String(GetLocalPlayerIDSafe())) {
				OnCustomPollStateChanged(data);
			}
		});

		var initial_poll_state = CustomNetTables.GetTableValue("custom_polls", String(GetLocalPlayerIDSafe()));
		if (initial_poll_state) {
			OnCustomPollStateChanged(initial_poll_state);
		}
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
		GameEvents.Subscribe("xhs_custom_poll_vote_result", OnCustomPollVoteResult);
	}
})();
