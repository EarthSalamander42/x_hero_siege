"use strict";

// Client-only identity policy shared by every XHS Panorama surface.
//
// Dota stores the Health Bars > Names choice in this client convar:
//   0 = hero names, 1 = player names, 2 = no names.
// Values above 2 are intentionally treated as "none" so a future enum value
// can never accidentally expose a player's persona name.
var XHSNameDisplay = (function () {
	var CONVAR_NAME = "dota_hero_overhead_names";
	var MODE_HERO = "hero";
	var MODE_PLAYER = "player";
	var MODE_NONE = "none";
	var POLL_INTERVAL = 0.25;
	var config = null;

	try {
		config = GameUI.CustomUIConfig ? GameUI.CustomUIConfig() : null;
	} catch (error) {
		config = null;
	}

	if (config && config.XHSNameDisplay && config.XHSNameDisplay.version >= 1) {
		return config.XHSNameDisplay;
	}

	var listeners = [];
	var lastRawValue = null;
	var lastMode = MODE_HERO;
	var pollStarted = false;
	var notifying = false;

	function NormalizeText(value) {
		if (value === undefined || value === null) {
			return "";
		}

		var text = String(value);
		var lowered = text.toLowerCase();
		if (
			!text ||
			lowered === "undefined" ||
			lowered === "null" ||
			lowered === "n/a" ||
			lowered === "na"
		) {
			return "";
		}

		return text;
	}

	function SafeValue(callback, fallbackValue) {
		try {
			var value = callback();
			return value === undefined || value === null ? fallbackValue : value;
		} catch (error) {
			return fallbackValue;
		}
	}

	function ReadConvarValue() {
		if (
			typeof Game === "undefined" ||
			typeof Game.GetConvarInt !== "function"
		) {
			return null;
		}

		var value = SafeValue(function () {
			return Number(Game.GetConvarInt(CONVAR_NAME));
		}, NaN);

		if (isNaN(value) || value === Infinity || value === -Infinity) {
			return null;
		}

		return Math.floor(value);
	}

	function ModeFromConvarValue(value) {
		if (value === 1) {
			return MODE_PLAYER;
		}

		if (value === 0 || value === null) {
			return MODE_HERO;
		}

		return MODE_NONE;
	}

	function NotifyModeChanged() {
		if (notifying) {
			return;
		}

		notifying = true;
		var snapshot = listeners.slice(0);
		for (var i = 0; i < snapshot.length; i++) {
			try {
				snapshot[i](lastMode, lastRawValue);
			} catch (error) {
				$.Msg("[XHS Name Display] Listener failed: " + error);
			}
		}
		notifying = false;
	}

	function Refresh(notify) {
		var rawValue = ReadConvarValue();
		var nextMode = ModeFromConvarValue(rawValue);
		var changed = rawValue !== lastRawValue || nextMode !== lastMode;

		lastRawValue = rawValue;
		lastMode = nextMode;

		if (config) {
			config.XHSNameDisplayMode = lastMode;
			config.XHSNameDisplayConvarValue = lastRawValue;
		}

		if (changed && notify === true) {
			$.Msg("[XHS Name Display] " + CONVAR_NAME + "=" + lastRawValue + " -> " + lastMode);
			NotifyModeChanged();
		}

		return lastMode;
	}

	function GetMode() {
		return Refresh(true);
	}

	function GetRawValue() {
		Refresh(true);
		return lastRawValue;
	}

	function LocalizeHeroName(heroName) {
		heroName = NormalizeText(heroName);
		if (!heroName) {
			return "";
		}

		var token = heroName.charAt(0) === "#" ? heroName : ("#" + heroName);
		var localized = SafeValue(function () {
			return $.Localize(token);
		}, "");

		if (localized && localized !== token && localized !== heroName) {
			return localized;
		}

		return heroName
			.replace(/^#/, "")
			.replace(/^npc_dota_hero_/, "")
			.replace(/^npc_dota_/, "")
			.replace(/_/g, " ")
			.toUpperCase();
	}

	function ResolveHeroName(options) {
		options = options || {};

		var localized = NormalizeText(
			options.heroDisplayName ||
			options.localHeroName ||
			options.heroLabel
		);
		if (localized) {
			return localized;
		}

		var heroName = NormalizeText(
			options.heroName ||
			options.hero ||
			options.heroUnitName ||
			options.unitName
		);
		var entityIndex = Number(
			options.entityIndex !== undefined ? options.entityIndex : options.entIndex
		);
		var playerID = Number(options.playerID);

		if (!heroName && !isNaN(entityIndex) && entityIndex >= 0 && typeof Entities !== "undefined") {
			heroName = NormalizeText(SafeValue(function () {
				return Entities.GetUnitName(entityIndex);
			}, ""));
		}

		if (!heroName && !isNaN(playerID) && playerID >= 0 && typeof Players !== "undefined") {
			heroName = NormalizeText(SafeValue(function () {
				return Players.GetPlayerSelectedHero(playerID);
			}, ""));
		}

		if (!heroName && !isNaN(playerID) && playerID >= 0 && typeof Game !== "undefined") {
			var playerInfo = SafeValue(function () {
				return Game.GetPlayerInfo(playerID);
			}, null);
			heroName = NormalizeText(playerInfo && playerInfo.player_selected_hero);
		}

		return LocalizeHeroName(heroName);
	}

	function ResolvePlayerName(options) {
		options = options || {};
		var playerID = Number(options.playerID);
		var playerName = NormalizeText(
			options.playerName ||
			options.personaName ||
			options.steamName
		);

		if (!playerName && !isNaN(playerID) && playerID >= 0 && typeof Players !== "undefined") {
			playerName = NormalizeText(SafeValue(function () {
				return Players.GetPlayerName(playerID);
			}, ""));
		}

		if (!playerName && !isNaN(playerID) && playerID >= 0 && typeof Game !== "undefined") {
			var playerInfo = SafeValue(function () {
				return Game.GetPlayerInfo(playerID);
			}, null);
			playerName = NormalizeText(playerInfo && playerInfo.player_name);
		}

		if (!playerName) {
			playerName = NormalizeText(options.playerFallback);
		}

		if (!playerName && !isNaN(playerID) && playerID >= 0) {
			playerName = "Player " + (playerID + 1);
		}

		return playerName;
	}

	function ResolveForMode(mode, options) {
		if (mode === MODE_NONE) {
			return "";
		}

		if (mode === MODE_PLAYER) {
			return ResolvePlayerName(options);
		}

		// Privacy invariant: hero mode never falls back to a persona name.
		return ResolveHeroName(options);
	}

	function Resolve(options) {
		return ResolveForMode(GetMode(), options || {});
	}

	function ApplyToLabel(label, options) {
		var identity = Resolve(options);
		if (label) {
			label.text = identity;
			if (label.SetHasClass) {
				label.SetHasClass("XHSIdentityNameHidden", identity === "");
			}
		}
		return identity;
	}

	function Subscribe(callback) {
		if (typeof callback !== "function") {
			return null;
		}

		for (var i = 0; i < listeners.length; i++) {
			if (listeners[i] === callback) {
				return callback;
			}
		}

		listeners.push(callback);
		try {
			callback(GetMode(), lastRawValue);
		} catch (error) {
			$.Msg("[XHS Name Display] Initial listener failed: " + error);
		}
		return callback;
	}

	function Unsubscribe(callback) {
		for (var i = listeners.length - 1; i >= 0; i--) {
			if (listeners[i] === callback) {
				listeners.splice(i, 1);
			}
		}
	}

	function StartPolling() {
		if (pollStarted || typeof $ === "undefined" || typeof $.Schedule !== "function") {
			return;
		}

		pollStarted = true;
		var poll = function () {
			Refresh(true);
			$.Schedule(POLL_INTERVAL, poll);
		};
		$.Schedule(POLL_INTERVAL, poll);
	}

	var api = {
		version: 1,
		CONVAR_NAME: CONVAR_NAME,
		MODE_HERO: MODE_HERO,
		MODE_PLAYER: MODE_PLAYER,
		MODE_NONE: MODE_NONE,
		GetMode: GetMode,
		GetRawValue: GetRawValue,
		Refresh: function () { return Refresh(true); },
		Resolve: Resolve,
		ResolveForMode: ResolveForMode,
		ResolveHeroName: ResolveHeroName,
		ResolvePlayerName: ResolvePlayerName,
		LocalizeHeroName: LocalizeHeroName,
		ApplyToLabel: ApplyToLabel,
		Subscribe: Subscribe,
		Unsubscribe: Unsubscribe,
	};

	if (config) {
		config.XHSNameDisplay = api;
	}

	Refresh(false);
	$.Msg("[XHS Name Display] initialized: " + CONVAR_NAME + "=" + lastRawValue + " -> " + lastMode);
	StartPolling();
	return api;
})();
