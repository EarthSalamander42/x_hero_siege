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

// temporary
function DonatorStatusConverter(new_status) {
	if (new_status == 6)
		return 1;
	else if (new_status == 5)
		return 2;
	else if (new_status == 4)
		return 3;
	else if (new_status == 7)
		return 4;
	else if (new_status == 8)
		return 5;
	else if (new_status == 9)
		return 6;
	else if (new_status == 1)
		return 102;
	else if (new_status == 2)
		return 101;
	else if (new_status == 3)
		return 100;
}

function DonatorStatusConverterReverse(new_status) {
	if (new_status == 1)
		return 6;
	else if (new_status == 2)
		return 5;
	else if (new_status == 3)
		return 4;
	else if (new_status == 4)
		return 7;
	else if (new_status == 5)
		return 8;
	else if (new_status == 6)
		return 9;
	else if (new_status == 100)
		return 3;
	else if (new_status == 101)
		return 2;
	else if (new_status == 102)
		return 1;
}

function GetDonatorColor(status) {
	// lua donator status are still using old numbers
//	var donator_colors = CustomNetTables.GetTableValue("game_options", "donator_colors")

	// Placeholder
	var donator_colors = [];
	donator_colors[1] = "#00CC00";
	donator_colors[2] = "#DAA520";
	donator_colors[3] = "#DC2828";
	donator_colors[4] = "#993399";
	donator_colors[5] = "#2F5B97";
	donator_colors[6] = "#BB4B0A";
	donator_colors[100] = "#0066FF";
	donator_colors[101] = "#641414";
	donator_colors[102] = "#871414";

	return donator_colors[status];
}
