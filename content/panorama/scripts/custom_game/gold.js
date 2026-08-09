/* global FindDotaHudElement, Game, PlayerTables, GameEvents, Players, Entities, CustomNetTables, DOTA_GameState */
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
	GameEvents.Subscribe('dota_player_update_query_unit', onQueryChange);
	GameEvents.Subscribe('dota_player_update_selected_unit', onQueryChange);
	CustomNetTables.SubscribeNetTableListener('xhs_bots', onXHSBotTableChanged);
	$.Schedule(0.1, StyleGoldHud);
	$.Schedule(0.15, PollBotQuickBuy);
})();
	

// settings
var useFormatting = 'half';
var xhsBotQuickBuy = null;
var xhsBotQuickBuySignature = '';
var hiddenVanillaQuickBuy = null;
var hiddenVanillaQuickBuyVisibility = '';

function onQueryChange() {
	onGoldChange('gold', PlayerTables.GetAllTableValues('gold'));
	$.Schedule(0.03, UpdateBotQuickBuy);
}

function onXHSBotTableChanged(tableName, key) {
	key = String(key || '');
	if (key === 'roster' || key.indexOf('debug_') === 0) {
		UpdateBotQuickBuy();
	}
}

function PollBotQuickBuy() {
	UpdateBotQuickBuy();
	$.Schedule(0.2, PollBotQuickBuy);
}

function GetSelectedXHSBotDebug() {
	var unit = Players.GetLocalPlayerPortraitUnit();
	if (Number(unit) < 0 || typeof CustomNetTables === 'undefined') {
		return null;
	}
	var ownerPlayerID = Number(Entities.GetPlayerOwnerID(unit));
	if (ownerPlayerID >= 0) {
		var ownerDebug = CustomNetTables.GetTableValue('xhs_bots', 'debug_' + ownerPlayerID);
		if (ownerDebug && Number(ownerDebug.hero_entindex) === Number(unit)) {
			return ownerDebug;
		}
	}
	var roster = CustomNetTables.GetTableValue('xhs_bots', 'roster') || {};
	var players = roster.players || {};
	for (var key in players) {
		var entry = players[key] || {};
		if (String(entry.participant_kind || '') !== 'xhs_bot' || Number(entry.preview || 0) === 1) {
			continue;
		}
		var playerID = Number(entry.player_id);
		if (playerID < 0) {
			playerID = Number(key);
		}
		var debug = CustomNetTables.GetTableValue('xhs_bots', 'debug_' + playerID);
		if (debug && Number(debug.hero_entindex) === Number(unit)) {
			return debug;
		}
	}
	return null;
}

function NumericArrayValues(value) {
	if (Array.isArray(value)) {
		return value;
	}
	var result = [];
	value = value || {};
	for (var key in value) {
		if (/^\d+$/.test(String(key))) {
			result.push({ index: Number(key), value: value[key] });
		}
	}
	result.sort(function (a, b) { return a.index - b.index; });
	return result.map(function (entry) { return entry.value; });
}

function GetBotPurchaseQueue(debug) {
	var queue = [];
	var seen = {};
	function add(itemName) {
		itemName = String(itemName || '');
		if (itemName === '' || seen[itemName] || queue.length >= 6) {
			return;
		}
		seen[itemName] = true;
		queue.push(itemName);
	}
	var committed = NumericArrayValues(debug.planned_purchase_queue);
	for (var committedIndex = 0; committedIndex < committed.length; committedIndex++) {
		add(committed[committedIndex]);
	}
	add(debug.planned_item);
	add(debug.planned_suggestion_item);
	var candidates = NumericArrayValues(debug.item_candidates);
	for (var index = 0; index < candidates.length; index++) {
		add(candidates[index] && candidates[index].item);
	}
	var loadout = NumericArrayValues(debug.planned_loadout);
	for (var loadoutIndex = 0; loadoutIndex < loadout.length; loadoutIndex++) {
		add(loadout[loadoutIndex]);
	}
	return queue;
}

function EnsureBotQuickBuy(quickBuy) {
	var parent = quickBuy && quickBuy.GetParent();
	if (!parent) {
		return null;
	}
	if (xhsBotQuickBuy && xhsBotQuickBuy.IsValid()) {
		if (xhsBotQuickBuy.GetParent() !== parent && xhsBotQuickBuy.SetParent) {
			xhsBotQuickBuy.SetParent(parent);
		}
		if (parent.MoveChildBefore) {
			parent.MoveChildBefore(xhsBotQuickBuy, quickBuy);
		}
		return xhsBotQuickBuy;
	}

	if (Game.IsInToolsMode()) {
		for (var index = 0; index < parent.GetChildCount(); index++) {
			var child = parent.GetChild(index);
			if (child && child.id === 'XHSBotQuickBuyMirror') {
				child.DeleteAsync(0);
			}
		}
	}

	xhsBotQuickBuy = $.CreatePanel('Panel', parent, 'XHSBotQuickBuyMirror');
	if (parent.MoveChildBefore) {
		parent.MoveChildBefore(xhsBotQuickBuy, quickBuy);
	}
	// #QuickBuyRows gets these metrics from Valve's ID selector. This mirror
	// has a different ID, so reproduce the native geometry explicitly instead
	// of relying on an unrelated fixed-size card.
	xhsBotQuickBuy.style.width = '100%';
	xhsBotQuickBuy.style.height = '44px';
	xhsBotQuickBuy.style.minHeight = '44px';
	xhsBotQuickBuy.style.maxHeight = '88px';
	xhsBotQuickBuy.style.horizontalAlign = 'right';
	xhsBotQuickBuy.style.verticalAlign = 'bottom';
	xhsBotQuickBuy.style.marginBottom = '60px';
	xhsBotQuickBuy.style.marginLeft = '1px';
	xhsBotQuickBuy.style.marginRight = '0px';
	xhsBotQuickBuy.style.padding = '0px';
	xhsBotQuickBuy.style.opacity = '1';
	// Keep Valve's QuickBuyRows visual language. The restrained cyan border and
	// wash are the only custom cue, so inspecting a bot remains seamless.
	xhsBotQuickBuy.style.backgroundColor = '#252627ac';
	xhsBotQuickBuy.style.backgroundImage = 'url("s2r://panorama/images/hud/reborn/quickbuy_bg_psd.vtex")';
	xhsBotQuickBuy.style.opacity = '0.5';
	xhsBotQuickBuy.style.border = '1px solid #77c8ff35';
	xhsBotQuickBuy.style.boxShadow = 'inset 0px -1px 4px -1px rgba(0, 0, 0, 0.5)';
	xhsBotQuickBuy.style.visibility = 'collapse';
	return xhsBotQuickBuy;
}

function StyleBotQuickBuyRow(row, rowIndex) {
	row.style.width = '176px';
	row.style.height = '44px';
	row.style.horizontalAlign = 'left';
	row.style.verticalAlign = 'top';
	row.style.flowChildren = 'right';
	row.style.padding = '7px 0px 7px 4px';
	row.style.marginTop = rowIndex === 0 ? '0px' : '44px';
	row.style.opacity = '1';
	row.style.visibility = 'visible';
}

function StyleBotQuickBuySlot(slot) {
	slot.style.width = '42px';
	slot.style.height = '30px';
	slot.style.marginRight = '1px';
	slot.style.backgroundColor = '#05090dcc';
	slot.style.border = '1px solid #77c8ff24';
	slot.style.boxShadow = 'inset #000000c0 0px 0px 3px 0px';
	slot.style.brightness = '1';
	slot.style.opacity = '1';
	slot.style.visibility = 'visible';
}

function StyleBotQuickBuyItem(item) {
	item.style.width = '40px';
	item.style.height = '28px';
	item.style.horizontalAlign = 'center';
	item.style.verticalAlign = 'center';
	item.style.opacity = '1';
	item.style.visibility = 'visible';
}

function SetBotQuickBuySlotHovered(slot, hovered) {
	slot.style.brightness = hovered ? '1.35' : '1';
	slot.style.border = hovered
		? '1px solid #77c8ff70'
		: '1px solid #77c8ff24';
}

function RenderBotQuickBuy(panel, debug) {
	panel.RemoveAndDeleteChildren();
	var queue = GetBotPurchaseQueue(debug);
	panel.style.height = queue.length > 4 ? '88px' : '44px';

	// Native hierarchy: QuickBuyRows > StickyItemSlotContainer. The bot label
	// occupies Valve's sticky-item column instead of consuming a quick-buy slot.
	var sticky = $.CreatePanel('Panel', panel, 'XHSBotPlanStickyItemSlotContainer');
	sticky.style.horizontalAlign = 'right';
	sticky.style.width = '53px';
	sticky.style.height = '100%';
	sticky.style.backgroundColor = '#0000006f';
	var title = $.CreatePanel('Label', sticky, 'XHSBotPlanLabel');
	title.text = Number(debug.planned_suggestion_only || 0) === 1
		? 'BOT\nPLAN ?'
		: 'BOT\nPLAN';
	title.style.width = '100%';
	title.style.height = '100%';
	title.style.color = '#77c8ff';
	title.style.fontSize = '11px';
	title.style.fontWeight = 'bold';
	title.style.textAlign = 'center';
	title.style.verticalAlign = 'center';
	title.style.horizontalAlign = 'center';
	title.style.opacity = '1';
	title.style.visibility = 'visible';

	if (queue.length === 0) {
		var empty = $.CreatePanel('Label', panel, 'XHSBotQuickBuyEmpty');
		empty.text = 'Calculating plan...';
		empty.style.width = '230px';
		empty.style.color = '#b9c9d6';
		empty.style.fontSize = '13px';
		empty.style.verticalAlign = 'center';
		empty.style.marginLeft = '8px';
		empty.style.opacity = '1';
		empty.style.visibility = 'visible';
		return;
	}

	for (var rowIndex = 0; rowIndex < Math.ceil(queue.length / 4); rowIndex++) {
		var row = $.CreatePanel('Panel', panel, 'XHSBotQuickBuyRow' + rowIndex);
		StyleBotQuickBuyRow(row, rowIndex);
		// Valve hides native rows while showing its ALT hint. Bot planning is
		// read-only telemetry and must remain visible in either input state.

		var rowEnd = Math.min(queue.length, (rowIndex + 1) * 4);
		for (var index = rowIndex * 4; index < rowEnd; index++) {
			var itemName = queue[index];
			var slot = $.CreatePanel('Panel', row, 'XHSBotQuickBuySlot' + index);
			StyleBotQuickBuySlot(slot);
			var shopItem = $.CreatePanel('DOTAShopItem', slot, 'XHSBotQuickBuyItem' + index);
			shopItem.itemname = itemName;
			shopItem.hittest = false;
			StyleBotQuickBuyItem(shopItem);
			slot.SetPanelEvent('onmouseover', (function (itemPanel, name) {
				return function () {
					SetBotQuickBuySlotHovered(itemPanel, true);
					$.DispatchEvent('DOTAShowAbilityTooltip', itemPanel, name);
				};
			})(slot, itemName));
			slot.SetPanelEvent('onmouseout', (function (itemPanel) {
				return function () {
					SetBotQuickBuySlotHovered(itemPanel, false);
					$.DispatchEvent('DOTAHideAbilityTooltip');
				};
			})(slot));
		}
	}
}

function RestoreVanillaQuickBuy() {
	if (hiddenVanillaQuickBuy && hiddenVanillaQuickBuy.IsValid()) {
		var restoreVisibility = hiddenVanillaQuickBuyVisibility;
		// A Panorama hot reload can inherit the "collapse" written by the
		// previous script instance. Never carry that bot-only state back to a
		// human selection.
		if (!restoreVisibility || restoreVisibility === 'collapse') {
			restoreVisibility = 'visible';
		}
		hiddenVanillaQuickBuy.style.visibility = restoreVisibility;
	}
	hiddenVanillaQuickBuy = null;
	hiddenVanillaQuickBuyVisibility = '';
	if (xhsBotQuickBuy && xhsBotQuickBuy.IsValid()) {
		xhsBotQuickBuy.style.visibility = 'collapse';
	}
	xhsBotQuickBuySignature = '';
}

function UpdateBotQuickBuy() {
	var quickBuy = FindDotaHudElement('QuickBuyRows');
	var debug = GetSelectedXHSBotDebug();
	if (!quickBuy || !debug) {
		RestoreVanillaQuickBuy();
		return;
	}
	var panel = EnsureBotQuickBuy(quickBuy);
	if (!panel) {
		return;
	}
	if (hiddenVanillaQuickBuy !== quickBuy) {
		RestoreVanillaQuickBuy();
		hiddenVanillaQuickBuy = quickBuy;
		hiddenVanillaQuickBuyVisibility = quickBuy.style.visibility || '';
	}
	quickBuy.style.visibility = 'collapse';
	var queue = GetBotPurchaseQueue(debug);
	var signature = String(debug.hero_entindex) + ':' + queue.join('|');
	if (signature !== xhsBotQuickBuySignature) {
		RenderBotQuickBuy(panel, debug);
		xhsBotQuickBuySignature = signature;
	}
	panel.style.visibility = 'visible';
}

function onGoldChange(table, data) {
	var unit = Players.GetLocalPlayerPortraitUnit();
	var localPlayerID = Game.GetLocalPlayerID();
	var playerID = Entities.GetPlayerOwnerID(unit);
	var localTeam = Players.GetTeam(localPlayerID);
	var inspectingSpectatorBot = IsSpectatorInspectingXHSBot(localTeam, playerID);

	if (playerID === -1 || (Entities.GetTeamNumber(unit) !== localTeam && !inspectingSpectatorBot)) {
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

function IsSpectatorInspectingXHSBot(localTeam, playerID) {
	if (Number(localTeam) !== 1 || Number(playerID) < 0 ||
		typeof CustomNetTables === 'undefined' || !CustomNetTables) {
		return false;
	}

	var roster = CustomNetTables.GetTableValue('xhs_bots', 'roster') || {};
	var players = roster.players || {};
	var entry = players[String(playerID)];
	if (!entry) {
		for (var key in players) {
			var candidate = players[key] || {};
			if (Number(candidate.player_id) === Number(playerID)) {
				entry = candidate;
				break;
			}
		}
	}

	return !!entry &&
		Number(entry.preview || 0) !== 1 &&
		String(entry.participant_kind || '') === 'xhs_bot';
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

	UpdateBotQuickBuy();
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
