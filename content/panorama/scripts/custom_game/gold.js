/* global FindDotaHudElement, Game, PlayerTables, GameEvents, Players, Entities, DOTA_GameState */
/*
	Author:
		Chronophylos
	Credits:
		Noya
		Angel Arena Blackstar
*/

'use strict';

(function () {
	PlayerTables.SubscribeNetTableListener('gold', onGoldChange);
	// GameEvents.Subscribe('dota_player_update_query_unit', onQueryChange); // This doesn't work but I'm leaving it in
	GameEvents.Subscribe('dota_player_update_selected_unit', onQueryChange);
	$.Schedule(0.1, StyleGoldHud);
})();
	

// settings
var useFormatting = 'half';

function onQueryChange() {
	onGoldChange('gold', PlayerTables.GetAllTableValues('gold'));
}

function onGoldChange(table, data) {
	var unit = Players.GetLocalPlayerPortraitUnit();
	var localPlayerID = Game.GetLocalPlayerID();
	var playerID = Entities.GetPlayerOwnerID(unit);

	if (playerID === -1 || Entities.GetTeamNumber(unit) !== Players.GetTeam(localPlayerID)) {
		playerID = localPlayerID;
	}

	if (data == undefined)
		data = PlayerTables.GetAllTableValues('gold');

	if (data == undefined || data.gold == undefined) {
		$.Msg("No gold table found");

		return;
	}

	var gold = data.gold[playerID];

	if (gold == undefined)
		gold = 0;

	UpdateGoldHud(gold);
	UpdateGoldTooltip(gold);
}

function UpdateGoldHud (gold) {
	var shopButton = FindDotaHudElement('ShopButton');

	if (!shopButton) {
		return;
	}

	StyleGoldHud();

	var GoldLabel = shopButton.FindChildTraverse('GoldLabel');

	if (!GoldLabel) {
		return;
	}

	if (useFormatting === 'full') {
		GoldLabel.text = FormatGold(gold);
	} else if (useFormatting === 'half') {
		GoldLabel.text = FormatComma(gold);
	} else {
		GoldLabel.text = gold;
	}
}

function StyleGoldHud() {
	var shopButton = FindDotaHudElement('ShopButton');

	if (!shopButton) {
		return;
	}

	var goldLabel = shopButton.FindChildTraverse('GoldLabel');
	var quickBuy = FindDotaHudElement('QuickBuyRows');

	if (!shopButton.BHasClass('XHSGoldButton')) {
		shopButton.AddClass('XHSGoldButton');
	}

	shopButton.style.backgroundColor = '#061421f2';
	shopButton.style.border = '1px solid #ffcf6640';
	shopButton.style.boxShadow = 'fill #00000090 0px 0px 8px 0px';

	if (goldLabel) {
		if (!goldLabel.BHasClass('XHSGoldLabel')) {
			goldLabel.AddClass('XHSGoldLabel');
		}

		goldLabel.style.color = '#ffcf66';
		goldLabel.style.fontSize = '22px';
		goldLabel.style.fontWeight = 'bold';
		goldLabel.style.textShadow = '0px 2px 4px #000000';
	}

	if (quickBuy && !quickBuy.BHasClass('XHSQuickBuyRows')) {
		quickBuy.AddClass('XHSQuickBuyRows');
		quickBuy.style.backgroundColor = '#061421d8';
		quickBuy.style.border = '1px solid #77c8ff20';
	}
}

function UpdateGoldTooltip (gold) {
	// HACK this spews error when attempting to change the tooltip if it is not visible
	try {
		var tooltipLabels = FindDotaHudElement('DOTAHUDGoldTooltip').FindChildTraverse('Contents');

		var label = tooltipLabels.GetChild(0);
		label.text = label.text.replace(/: [0-9]+/, ': ' + gold);

		label = tooltipLabels.GetChild(1);
		label.style.visibility = 'collapse';
	} catch (e) {}
}

/*
	Author:
		Noya
		Chronophylos
	Credits:
		Noya
	Description:
		Returns gold with commas and k
*/
function FormatGold (gold) {
	var formatted = FormatComma(gold);
	if (gold.toString().length > 6) {
		return FormatGold(gold.toString().substring(0, gold.toString().length - 5) / 10) + 'M';
	} else if (gold.toString().length > 4) {
		return FormatGold(gold.toString().substring(0, gold.toString().length - 3)) + 'k';
	} else {
		return formatted;
	}
}

/*
	Author:
		Noya
	Credits:
		Noya
	Description:
		Inserts Commas every 3 chars
		We use a whitespace because of some DIN
*/
function FormatComma (value) {
	try {
		return value.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',');
	} catch (e) {}
}
