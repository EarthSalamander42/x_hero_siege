"use strict";

var XHSSettings = (function () {
	var ROOT = $.GetContextPanel();
	var QUEST_DEFAULT_STORAGE_KEY = "xhs_show_quest_ui_by_default";
	var ADS_HIDDEN_STORAGE_KEY = "xhs_ingame_advertize_hidden";
	var CONTROLLED_CREEPS_AUTO_ATTACK_STORAGE_KEY = "xhs_controlled_creeps_auto_attack_after_move";
	var STARTING_ITEM_SLOTS_STORAGE_KEY = "xhs_starting_item_slots";
	var STARTING_ITEMS = ["item_health_potion", "item_mana_potion", "item_lifesteal_mask"];
	var DEFAULT_STARTING_ITEM_SLOTS = {
		item_health_potion: 0,
		item_mana_potion: 1,
		item_lifesteal_mask: 2
	};
	var SETTING_KEYS = [
		"show_advertize",
		"show_quest_ui",
		"controlled_creeps_auto_attack",
		"toggle_tag",
		"pass_rewards",
		"player_xp",
		"winrate_toggle",
		"show_companion"
	];
	var CONTROL_IDS = {
		show_advertize: "XHSSettingShowAdvertize",
		show_quest_ui: "XHSSettingShowQuestUI",
		controlled_creeps_auto_attack: "XHSSettingControlledCreepsAutoAttack",
		toggle_tag: "XHSSettingSupporterTag",
		pass_rewards: "XHSSettingSupporterCosmetics",
		player_xp: "XHSSettingSupporterXP",
		winrate_toggle: "XHSSettingSupporterWinrate",
		show_companion: "XHSSettingShowCompanion"
	};
	var original = {};
	var draft = {};
	var activeTab = "game";
	var saving = false;
	var saveSerial = 0;

	function StartingItemTrace(message) {
		$.Msg("[XHS Settings][StartingItems] " + message);
	}

	function Panel(id) {
		return ROOT && ROOT.FindChildTraverse ? ROOT.FindChildTraverse(id) : null;
	}

	function IsTruthy(value, fallback) {
		if (value === true || value === 1 || value === "1" || value === "true") return true;
		if (value === false || value === 0 || value === "0" || value === "false") return false;
		return fallback === true;
	}

	function CopySettings(source) {
		var copy = {};
		for (var i = 0; i < SETTING_KEYS.length; i++) {
			var key = SETTING_KEYS[i];
			copy[key] = source && source[key] === true;
		}
		copy.starting_item_slots = NormalizeStartingItemSlots(source && source.starting_item_slots);
		return copy;
	}

	function NormalizeStartingItemSlots(value) {
		var normalized = {};
		var occupied = {};
		for (var i = 0; i < STARTING_ITEMS.length; i++) {
			var itemName = STARTING_ITEMS[i];
			var slot = value ? Number(value[itemName]) : NaN;
			if (slot % 1 !== 0 || slot < 0 || slot > 5 || occupied[slot]) {
				return {
					item_health_potion: DEFAULT_STARTING_ITEM_SLOTS.item_health_potion,
					item_mana_potion: DEFAULT_STARTING_ITEM_SLOTS.item_mana_potion,
					item_lifesteal_mask: DEFAULT_STARTING_ITEM_SLOTS.item_lifesteal_mask
				};
			}
			normalized[itemName] = slot;
			occupied[slot] = true;
		}
		return normalized;
	}

	function SettingsEqual(left, right) {
		for (var i = 0; i < SETTING_KEYS.length; i++) {
			var key = SETTING_KEYS[i];
			if ((left && left[key] === true) !== (right && right[key] === true)) return false;
		}
		var leftSlots = NormalizeStartingItemSlots(left && left.starting_item_slots);
		var rightSlots = NormalizeStartingItemSlots(right && right.starting_item_slots);
		for (var j = 0; j < STARTING_ITEMS.length; j++) {
			var itemName = STARTING_ITEMS[j];
			if (leftSlots[itemName] !== rightSlots[itemName]) return false;
		}
		return true;
	}

	function GetLocalStorage() {
		if (typeof $ !== "undefined" && $.LocalStorage) return $.LocalStorage;
		if (typeof LocalStorage !== "undefined") return LocalStorage;
		return null;
	}

	function ReadStoredBoolean(key, fallback) {
		var config = GameUI.CustomUIConfig ? GameUI.CustomUIConfig() : null;
		if (config && typeof config[key] === "boolean") return config[key];
		var storage = GetLocalStorage();
		if (storage && storage.GetItem) {
			try {
				var value = storage.GetItem(key);
				if (value !== undefined && value !== null && value !== "") return IsTruthy(value, fallback);
			} catch (error) {}
		}
		return fallback === true;
	}

	function StoreBoolean(key, value) {
		var normalized = value === true;
		var config = GameUI.CustomUIConfig ? GameUI.CustomUIConfig() : null;
		if (config) config[key] = normalized;
		var storage = GetLocalStorage();
		if (storage && storage.SetItem) {
			try { storage.SetItem(key, normalized ? "1" : "0"); } catch (error) {}
		}
	}

	function ReadStoredStartingItemSlots(fallback) {
		var config = GameUI.CustomUIConfig ? GameUI.CustomUIConfig() : null;
		if (config && config.xhs_starting_item_slots) return NormalizeStartingItemSlots(config.xhs_starting_item_slots);
		var storage = GetLocalStorage();
		if (storage && storage.GetItem) {
			try {
				var raw = storage.GetItem(STARTING_ITEM_SLOTS_STORAGE_KEY);
				if (raw) return NormalizeStartingItemSlots(JSON.parse(raw));
			} catch (error) {}
		}
		return NormalizeStartingItemSlots(fallback);
	}

	function StoreStartingItemSlots(value) {
		var normalized = NormalizeStartingItemSlots(value);
		var config = GameUI.CustomUIConfig ? GameUI.CustomUIConfig() : null;
		if (config) config.xhs_starting_item_slots = normalized;
		var storage = GetLocalStorage();
		if (storage && storage.SetItem) {
			try { storage.SetItem(STARTING_ITEM_SLOTS_STORAGE_KEY, JSON.stringify(normalized)); } catch (error) {}
		}
	}

	function GetLocalPlayerData() {
		if (typeof CustomNetTables === "undefined" || !CustomNetTables.GetTableValue) return {};
		var playerID = Players.GetLocalPlayer ? Players.GetLocalPlayer() : -1;
		if (playerID < 0) return {};
		return CustomNetTables.GetTableValue("supporter_pass_player", String(playerID)) || {};
	}

	function BuildSettings() {
		var player = GetLocalPlayerData();
		var backendSlots = player.starting_item_slots || (player.settings && player.settings.starting_item_slots);
		var backendSettings = player.settings || {};
		var passRewards = player.pass_rewards !== undefined ? player.pass_rewards : player.bp_rewards;
		var adsHidden = player.xhs_ingame_advertize_hidden;
		if (adsHidden === undefined) adsHidden = ReadStoredBoolean(ADS_HIDDEN_STORAGE_KEY, false);
		return {
			show_advertize: !IsTruthy(adsHidden, false),
			show_quest_ui: ReadStoredBoolean(QUEST_DEFAULT_STORAGE_KEY, true),
			controlled_creeps_auto_attack: ReadStoredBoolean(CONTROLLED_CREEPS_AUTO_ATTACK_STORAGE_KEY, false),
			starting_item_slots: backendSlots ? NormalizeStartingItemSlots(backendSlots) : ReadStoredStartingItemSlots(DEFAULT_STARTING_ITEM_SLOTS),
			toggle_tag: IsTruthy(player.toggle_tag, true),
			pass_rewards: passRewards === 0 ? false : IsTruthy(passRewards, true),
			player_xp: IsTruthy(player.player_xp, true),
			winrate_toggle: IsTruthy(player.winrate_toggle, true),
			show_companion: IsTruthy(player.show_companion !== undefined ? player.show_companion : backendSettings.show_companion, true)
		};
	}

	function IsCheckboxChecked(panel) {
		if (!panel) return false;
		if (panel.checked === true) return true;
		if (panel.IsSelected) return panel.IsSelected() === true;
		return panel.BHasClass && (panel.BHasClass("Selected") || panel.BHasClass("Activated"));
	}

	function SetCheckboxChecked(panel, checked) {
		if (!panel) return;
		panel.checked = checked === true;
		if (panel.SetSelected) panel.SetSelected(checked === true);
	}

	function RenderControls() {
		for (var key in CONTROL_IDS) {
			if (CONTROL_IDS.hasOwnProperty(key)) SetCheckboxChecked(Panel(CONTROL_IDS[key]), draft[key] === true);
		}
		RenderStartingItemSlots();
		UpdateFooter();
	}

	function FindStartingItemInSlot(slot) {
		for (var i = 0; i < STARTING_ITEMS.length; i++) {
			var itemName = STARTING_ITEMS[i];
			if (draft.starting_item_slots[itemName] === slot) return itemName;
		}
		return "";
	}

	function MoveStartingItem(itemName, targetSlot) {
		StartingItemTrace("Move requested item=" + itemName + " targetSlot=" + targetSlot);
		if (STARTING_ITEMS.indexOf(itemName) < 0 || targetSlot < 0 || targetSlot > 5) {
			StartingItemTrace("Move rejected: invalid item or slot");
			return;
		}
		var sourceSlot = draft.starting_item_slots[itemName];
		if (sourceSlot === targetSlot) {
			StartingItemTrace("Move ignored: item already in slot " + targetSlot);
			return;
		}
		var displaced = FindStartingItemInSlot(targetSlot);
		draft.starting_item_slots[itemName] = targetSlot;
		if (displaced) draft.starting_item_slots[displaced] = sourceSlot;
		StartingItemTrace("Move applied sourceSlot=" + sourceSlot + " targetSlot=" + targetSlot + " displaced=" + (displaced || "none"));
		RenderStartingItemSlots();
		UpdateFooter();
		Game.EmitSound("General.ButtonClick");
	}

	function BindStartingItemDrag(dragSource, itemName) {
		StartingItemTrace("Binding source item=" + itemName + " panel=" + dragSource.id);
		dragSource.SetAttributeString("xhs_item_name", itemName);
		dragSource.hittest = true;
		dragSource.hittestchildren = false;
		if (dragSource.SetDraggable) {
			dragSource.SetDraggable(true);
			StartingItemTrace("SetDraggable(true) item=" + itemName);
		} else {
			dragSource.draggable = true;
			StartingItemTrace("SetDraggable unavailable; property fallback item=" + itemName);
		}
		dragSource.SetPanelEvent("onmouseover", function () {
			StartingItemTrace("onmouseover item=" + itemName);
			$.DispatchEvent("DOTAShowAbilityTooltip", dragSource, itemName);
		});
		dragSource.SetPanelEvent("onmouseout", function () {
			StartingItemTrace("onmouseout item=" + itemName);
			$.DispatchEvent("DOTAHideAbilityTooltip", dragSource);
		});
	}

	function OnStartingItemDragStart(panelId, dragCallbacks) {
		$.DispatchEvent("DOTAHideAbilityTooltip", panelId);
		var itemName = panelId && panelId.GetAttributeString ? panelId.GetAttributeString("xhs_item_name", "") : "";
		StartingItemTrace("native DragStart item=" + itemName + " panel=" + (panelId ? panelId.id : "missing"));
		if (STARTING_ITEMS.indexOf(itemName) < 0) return false;
		var display = $.CreatePanel("Panel", ROOT, "");
		display.SetAttributeString("xhs_item_name", itemName);
		display.hittest = false;
		display.hittestchildren = false;
		display.AddClass("XHSStartingDragImage");
		var displayImage = $.CreatePanel("DOTAItemImage", display, "");
		displayImage.itemname = itemName;
		displayImage.hittest = false;
		displayImage.AddClass("XHSStartingDragItemImage");
		dragCallbacks.displayPanel = display;
		dragCallbacks.offsetX = 32;
		dragCallbacks.offsetY = 22;
		return true;
	}

	function OnStartingItemDragEnd(panelId, draggedPanel) {
		var itemName = panelId && panelId.GetAttributeString ? panelId.GetAttributeString("xhs_item_name", "") : "";
		StartingItemTrace("native DragEnd item=" + itemName + " panel=" + (panelId ? panelId.id : "missing") + " draggedPanel=" + !!draggedPanel);
		if (draggedPanel && draggedPanel.DeleteAsync) draggedPanel.DeleteAsync(0.0);
		return true;
	}

	function PanelContainsCursor(panel, cursor) {
		if (!panel || !panel.GetPositionWithinWindow) return false;
		var position = panel.GetPositionWithinWindow();
		var scaleX = Number(panel.actualuiscale_x) || 1;
		var scaleY = Number(panel.actualuiscale_y) || 1;
		var width = (Number(panel.actuallayoutwidth) || 0) * scaleX;
		var height = (Number(panel.actuallayoutheight) || 0) * scaleY;
		return cursor[0] >= position.x && cursor[0] <= position.x + width &&
			cursor[1] >= position.y && cursor[1] <= position.y + height;
	}

	function RenderStartingItemSlots() {
		draft.starting_item_slots = NormalizeStartingItemSlots(draft.starting_item_slots);
		for (var slot = 0; slot < 6; slot++) {
			var holder = Panel("XHSStartingItemHolder" + slot);
			if (!holder) continue;
			holder.RemoveAndDeleteChildren();
			var itemName = FindStartingItemInSlot(slot);
			if (!itemName) continue;
			var dragSource = $.CreatePanel("Panel", holder, "XHSStartingItem_" + itemName);
			dragSource.AddClass("XHSStartingItemDragSource");
			var image = $.CreatePanel("DOTAItemImage", dragSource, "");
			image.itemname = itemName;
			image.hittest = false;
			image.AddClass("XHSStartingItemImage");
			image.SetHasClass("IsEasyOnly", itemName === "item_lifesteal_mask");
			BindStartingItemDrag(dragSource, itemName);
		}
	}

	function IsCursorInsidePanel(panel) {
		if (typeof GameUI.GetCursorPosition !== "function") return false;
		return PanelContainsCursor(panel, GameUI.GetCursorPosition());
	}

	function ReadControls() {
		for (var key in CONTROL_IDS) {
			if (CONTROL_IDS.hasOwnProperty(key)) draft[key] = IsCheckboxChecked(Panel(CONTROL_IDS[key]));
		}
		UpdateFooter();
	}

	function SetStatus(text, state) {
		var label = Panel("XHSSettingsStatus");
		if (!label) return;
		label.text = text || "";
		label.SetHasClass("IsSuccess", state === "success");
		label.SetHasClass("IsError", state === "error");
	}

	function UpdateFooter() {
		var dirty = !SettingsEqual(original, draft);
		var save = Panel("XHSSettingsSaveButton");
		var cancel = Panel("XHSSettingsCancelButton");
		if (save) save.enabled = dirty && !saving;
		if (cancel) cancel.enabled = dirty && !saving;
		if (saving) SetStatus($.Localize("#xhs_sp_saving_settings"), "");
		else if (dirty) SetStatus($.Localize("#xhs_sp_unsaved_changes"), "");
		else if (!Panel("XHSSettingsStatus") || !Panel("XHSSettingsStatus").BHasClass("IsSuccess")) SetStatus("", "");
	}

	function SwitchTab(tab) {
		activeTab = tab === "supporter" ? "supporter" : "game";
		Panel("XHSSettingsTabGame").SetHasClass("IsActive", activeTab === "game");
		Panel("XHSSettingsTabSupporter").SetHasClass("IsActive", activeTab === "supporter");
		Panel("XHSSettingsGamePage").SetHasClass("IsVisible", activeTab === "game");
		Panel("XHSSettingsSupporterPage").SetHasClass("IsVisible", activeTab === "supporter");
		var supporter = activeTab === "supporter";
		Panel("XHSSettingsPageEyebrow").text = $.Localize(supporter ? "#xhs_settings_supporter_eyebrow" : "#xhs_settings_game_eyebrow");
		Panel("XHSSettingsPageTitle").text = $.Localize(supporter ? "#xhs_settings_supporter_title" : "#xhs_settings_game_title");
		Panel("XHSSettingsPageDescription").text = $.Localize(supporter ? "#xhs_settings_supporter_description" : "#xhs_settings_game_description");
		Game.EmitSound("General.ButtonClick");
	}

	function SetVisible(visible) {
		if (!ROOT) return;
		ROOT.SetHasClass("IsVisible", visible === true);
		ROOT.hittest = visible === true;
		ROOT.hittestchildren = visible === true;
		var config = GameUI.CustomUIConfig ? GameUI.CustomUIConfig() : null;
		if (config) {
			config.XHSSettingsVisible = visible === true;
			if (typeof config.UpdateXHSSettingsButtonState === "function") config.UpdateXHSSettingsButtonState(visible === true);
		}
		if (visible) {
			original = BuildSettings();
			draft = CopySettings(original);
			SetStatus("", "");
			RenderControls();
		}
	}

	function Toggle(forceVisible) {
		var isVisible = ROOT && ROOT.BHasClass("IsVisible");
		SetVisible(forceVisible === undefined ? !isVisible : forceVisible === true);
	}

	function StoreGameSettings() {
		StoreBoolean(QUEST_DEFAULT_STORAGE_KEY, draft.show_quest_ui);
		StoreBoolean(ADS_HIDDEN_STORAGE_KEY, !draft.show_advertize);
		StoreBoolean(CONTROLLED_CREEPS_AUTO_ATTACK_STORAGE_KEY, draft.controlled_creeps_auto_attack);
		StoreStartingItemSlots(draft.starting_item_slots);
		SendGameplaySettings(draft.controlled_creeps_auto_attack, draft.starting_item_slots);
		var config = GameUI.CustomUIConfig ? GameUI.CustomUIConfig() : null;
		if (config && typeof config.SetXHSQuestLogDefaultVisibility === "function") {
			config.SetXHSQuestLogDefaultVisibility(draft.show_quest_ui);
		}
	}

	function SendGameplaySettings(controlledCreepsAutoAttack, startingItemSlots) {
		if (typeof GameEvents === "undefined" || !GameEvents.SendCustomGameEventToServer) return;
		GameEvents.SendCustomGameEventToServer("xhs_update_gameplay_settings", {
			controlled_creeps_auto_attack_after_move: controlledCreepsAutoAttack === true ? 1 : 0,
			starting_item_slots: NormalizeStartingItemSlots(startingItemSlots)
		});
	}

	function Save() {
		if (saving) return;
		ReadControls();
		if (SettingsEqual(original, draft)) return;
		if (typeof GameEvents === "undefined" || !GameEvents.SendCustomGameEventToServer) {
			SetStatus($.Localize("#xhs_sp_settings_failed"), "error");
			return;
		}
		StoreGameSettings();
		saving = true;
		saveSerial++;
		var serial = saveSerial;
		UpdateFooter();
		Game.EmitSound("General.ButtonClick");
		GameEvents.SendCustomGameEventToServer("supporter_pass_update_settings", {
			player_id: Players.GetLocalPlayer(),
			xhs_ingame_advertize_hidden: draft.show_advertize ? 0 : 1,
			toggle_tag: draft.toggle_tag ? 1 : 0,
			pass_rewards: draft.pass_rewards ? 1 : 0,
			player_xp: draft.player_xp ? 1 : 0,
			winrate_toggle: draft.winrate_toggle ? 1 : 0,
			show_companion: draft.show_companion ? 1 : 0,
			starting_item_slots: NormalizeStartingItemSlots(draft.starting_item_slots)
		});
		$.Schedule(16.0, function () {
			if (!saving || serial !== saveSerial) return;
			saving = false;
			original = BuildSettings();
			draft = CopySettings(original);
			RenderControls();
			SetStatus($.Localize("#xhs_sp_settings_timeout"), "error");
		});
	}

	function Cancel() {
		if (saving) return;
		draft = CopySettings(original);
		RenderControls();
		SetStatus("", "");
		Game.EmitSound("General.Cancel");
	}

	function ResetStartingItemSlots() {
		if (saving) return;
		draft.starting_item_slots = NormalizeStartingItemSlots(DEFAULT_STARTING_ITEM_SLOTS);
		RenderStartingItemSlots();
		UpdateFooter();
		Game.EmitSound("General.ButtonClick");
	}

	function Bind() {
		StartingItemTrace("Bind begin");
		$.RegisterEventHandler("DragStart", ROOT, OnStartingItemDragStart);
		$.RegisterEventHandler("DragEnd", ROOT, OnStartingItemDragEnd);
		Panel("XHSSettingsBackdrop").SetPanelEvent("onactivate", function () {
			if (!IsCursorInsidePanel(Panel("XHSSettingsContainer"))) Toggle(false);
		});
		Panel("XHSSettingsCloseButton").SetPanelEvent("onactivate", function () { Toggle(false); });
		Panel("XHSSettingsTabGame").SetPanelEvent("onactivate", function () { SwitchTab("game"); });
		Panel("XHSSettingsTabSupporter").SetPanelEvent("onactivate", function () { SwitchTab("supporter"); });
		Panel("XHSSettingsSaveButton").SetPanelEvent("onactivate", Save);
		Panel("XHSSettingsCancelButton").SetPanelEvent("onactivate", Cancel);
		Panel("XHSStartingItemsReset").SetPanelEvent("onactivate", ResetStartingItemSlots);
		for (var slot = 0; slot < 6; slot++) {
			(function (targetSlot) {
				var slotPanel = Panel("XHSStartingItemSlot" + targetSlot);
				var dropPanel = Panel("XHSStartingItemHolder" + targetSlot);
				StartingItemTrace("Binding drop slot=" + targetSlot + " slotPanel=" + !!slotPanel + " dropPanel=" + !!dropPanel);
				$.RegisterEventHandler("DragEnter", dropPanel, function () {
					StartingItemTrace("native DragEnter slot=" + targetSlot);
					slotPanel.AddClass("IsDragTarget");
					return true;
				});
				$.RegisterEventHandler("DragLeave", dropPanel, function () {
					StartingItemTrace("native DragLeave slot=" + targetSlot);
					slotPanel.RemoveClass("IsDragTarget");
					return true;
				});
				$.RegisterEventHandler("DragDrop", dropPanel, function (panelId, draggedPanel) {
					slotPanel.RemoveClass("IsDragTarget");
					var itemName = draggedPanel && draggedPanel.GetAttributeString
						? draggedPanel.GetAttributeString("xhs_item_name", "") : "";
					StartingItemTrace("native DragDrop slot=" + targetSlot + " panelId=" + panelId + " item=" + itemName + " draggedPanel=" + !!draggedPanel);
					if (itemName !== "") {
						$.Schedule(0.0, function () { MoveStartingItem(itemName, targetSlot); });
					}
					return itemName !== "";
				});
			})(slot);
		}
		for (var key in CONTROL_IDS) {
			if (CONTROL_IDS.hasOwnProperty(key)) Panel(CONTROL_IDS[key]).SetPanelEvent("onactivate", function () { $.Schedule(0.0, ReadControls); });
		}
	}

	function Init() {
		Bind();
		original = BuildSettings();
		draft = CopySettings(original);
		RenderControls();
		SwitchTab("game");
		var config = GameUI.CustomUIConfig ? GameUI.CustomUIConfig() : null;
		if (config) {
			config.XHSSettingsVisible = false;
			config.OpenXHSSettings = function () { Toggle(true); };
			config.ToggleXHSSettings = function () { Toggle(); };
			if (config.XHSOpenSettingsRequested === true) {
				config.XHSOpenSettingsRequested = false;
				Toggle(true);
			}
		}
		$.Schedule(1.0, function () {
			var initialSettings = BuildSettings();
			StoreStartingItemSlots(initialSettings.starting_item_slots);
			SendGameplaySettings(
				initialSettings.controlled_creeps_auto_attack,
				initialSettings.starting_item_slots
			);
		});
		GameEvents.Subscribe("supporter_pass_settings_success", function () {
			if (!saving) return;
			saving = false;
			original = CopySettings(draft);
			UpdateFooter();
			SetStatus($.Localize("#xhs_sp_settings_saved"), "success");
		});
		GameEvents.Subscribe("supporter_pass_settings_failed", function (payload) {
			if (!saving) return;
			saving = false;
			original = BuildSettings();
			draft = CopySettings(original);
			StoreGameSettings();
			RenderControls();
			SetStatus($.Localize((payload && payload.message) || "#xhs_sp_settings_failed"), "error");
		});
		if (CustomNetTables.SubscribeNetTableListener) {
			CustomNetTables.SubscribeNetTableListener("supporter_pass_player", function (tableName, key) {
				if (key !== String(Players.GetLocalPlayer()) || saving) return;
				var latest = BuildSettings();
				StoreStartingItemSlots(latest.starting_item_slots);
				SendGameplaySettings(latest.controlled_creeps_auto_attack, latest.starting_item_slots);
				if (!ROOT.BHasClass("IsVisible")) return;
				original = latest;
				draft = CopySettings(original);
				RenderControls();
			});
		}
	}

	return {
		Init: Init,
		Open: function () { Toggle(true); },
		Close: function () { Toggle(false); },
		Toggle: Toggle,
		OnToggle: function () { $.Schedule(0.0, ReadControls); }
	};
})();

$.Schedule(0.0, XHSSettings.Init);
