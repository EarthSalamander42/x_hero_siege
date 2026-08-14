/* global $ */
'use strict';

/* Author: Angel Arena Blackstar Credits: Angel Arena Blackstar */
if (typeof module !== 'undefined' && module.exports) {
	module.exports.FindDotaHudElement = FindDotaHudElement;
	module.exports.ColorToHexCode = ColorToHexCode;
	module.exports.ColoredText = ColoredText;
	module.exports.LuaTableToArray = LuaTableToArray;
}

var HudNotFoundException = /** @class */
(function() {
	function HudNotFoundException(message) {
		this.message = message;
	}
	return HudNotFoundException;
}());

function FindDotaHudElement(id) {
	return GetDotaHud().FindChildTraverse(id);
}

function GetDotaHud() {
	var p = $.GetContextPanel();
	while (p !== null && p.id !== 'Hud') {
		p = p.GetParent();
	}
	if (p === null) {
		throw new HudNotFoundException('Could not find Hud root as parent of panel with id: ' + $.GetContextPanel().id);
	} else {
		return p;
	}
}

/**
 * Takes an array-like table passed from Lua that has stringified indices
 * starting from 1 and returns an array of type T containing the elements of the
 * table. Order of elements is preserved.
 */
function LuaTableToArray(table) {
	var array = [];

	for (var i = 1; table[i.toString()] !== undefined; i++) {
		array.push(table[i.toString()]);
	}

	return array;
}

/**
 * Takes an integer and returns a hex code string of the color represented by
 * the integer
 */
function ColorToHexCode(color) {
	var red = (color & 0xff).toString(16);
	var green = ((color & 0xff00) >> 8).toString(16);
	var blue = ((color & 0xff0000) >> 16).toString(16);

	return '#' + red + green + blue;
}

function ColoredText(colorCode, text) {
	return '<font color="' + colorCode + '">' + text + '</font>';
}

/* Credits: EarthSalamander #42 */
function IsDonator(ID) {
	var i = 0
	if (CustomNetTables.GetTableValue("game_options", "donators") == undefined) {
		return false;
	}

	var local_steamid = Game.GetPlayerInfo(ID).player_steamid;
	var donators = CustomNetTables.GetTableValue("game_options", "donators");

	for (var key in donators) {
		var steamid = key;
		var status = donators[key];
		if (local_steamid === steamid && status != 1 || status != 2)
			return status;
	}

	return false;
}

function IsDeveloper(ID) {
	var i = 0
	if (CustomNetTables.GetTableValue("game_options", "donators") == undefined) {
		return false;
	}

	var local_steamid = Game.GetPlayerInfo(ID).player_steamid;
	var developers = CustomNetTables.GetTableValue("game_options", "donators");
		
	for (var key in developers) {
		var steamid = developers[key].steamid;
		var status = developers[key].status;
		if (local_steamid === steamid && status == 1 || status == 2)
			return true;
	}

	return false;
}

var DONATOR_STATUS_TO_TIER_FALLBACK = {
	"1": 5,
	"2": 5,
	"3": 5,
	"4": 3,
	"5": 2,
	"6": 1,
	"7": 4,
	"8": 5,
	"9": 5
};

var DONATOR_TIER_TO_STATUS_FALLBACK = {
	"1": 6,
	"2": 5,
	"3": 4,
	"4": 7,
	"5": 8,
	"6": 9
};

var DONATOR_TIER_COLOR_FALLBACK = {
	"0": "#7DB9D8",
	"1": "#45C46B",
	"2": "#F2C94C",
	"3": "#E4572E",
	"4": "#7B8794",
	"5": "#C99CFF",
	"6": "#C99CFF"
};

function GetDonatorColorMeta() {
	return CustomNetTables.GetTableValue("game_options", "donator_colors") || {};
}

function DonatorStatusConverter(new_status) {
	var status = (Number(new_status) || 0).toString();
	var meta = GetDonatorColorMeta();
	var statusToTier = meta.status_to_tier || DONATOR_STATUS_TO_TIER_FALLBACK;

	return statusToTier[status] || 0;
}

function DonatorStatusConverterReverse(new_status) {
	var tier = (Number(new_status) || 0).toString();
	var meta = GetDonatorColorMeta();
	var tierToStatus = meta.tier_to_status || DONATOR_TIER_TO_STATUS_FALLBACK;

	return tierToStatus[tier] || 0;
}

function GetDonatorColor(status) {
	var tier = (Number(status) || 0).toString();
	var meta = GetDonatorColorMeta();
	var tierColors = meta.tier || DONATOR_TIER_COLOR_FALLBACK;

	return tierColors[tier] || DONATOR_TIER_COLOR_FALLBACK[tier];
}
