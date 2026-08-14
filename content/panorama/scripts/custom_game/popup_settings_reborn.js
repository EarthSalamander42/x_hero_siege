"use strict";

var XHSSettings = (function () {
	var ROOT = $.GetContextPanel();
	var QUEST_DEFAULT_STORAGE_KEY = "xhs_show_quest_ui_by_default";
	var ADS_HIDDEN_STORAGE_KEY = "xhs_ingame_advertize_hidden";
	var CONTROLLED_CREEPS_AUTO_ATTACK_STORAGE_KEY = "xhs_controlled_creeps_auto_attack_after_move";
	var SETTING_KEYS = [
		"show_advertize",
		"show_quest_ui",
		"controlled_creeps_auto_attack",
		"toggle_tag",
		"pass_rewards",
		"player_xp",
		"winrate_toggle"
	];
	var CONTROL_IDS = {
		show_advertize: "XHSSettingShowAdvertize",
		show_quest_ui: "XHSSettingShowQuestUI",
		controlled_creeps_auto_attack: "XHSSettingControlledCreepsAutoAttack",
		toggle_tag: "XHSSettingSupporterTag",
		pass_rewards: "XHSSettingSupporterCosmetics",
		player_xp: "XHSSettingSupporterXP",
		winrate_toggle: "XHSSettingSupporterWinrate"
	};
	var original = {};
	var draft = {};
	var activeTab = "game";
	var saving = false;
	var saveSerial = 0;

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
		return copy;
	}

	function SettingsEqual(left, right) {
		for (var i = 0; i < SETTING_KEYS.length; i++) {
			var key = SETTING_KEYS[i];
			if ((left && left[key] === true) !== (right && right[key] === true)) return false;
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

	function GetLocalPlayerData() {
		if (typeof CustomNetTables === "undefined" || !CustomNetTables.GetTableValue) return {};
		var playerID = Players.GetLocalPlayer ? Players.GetLocalPlayer() : -1;
		if (playerID < 0) return {};
		return CustomNetTables.GetTableValue("supporter_pass_player", String(playerID)) || {};
	}

	function BuildSettings() {
		var player = GetLocalPlayerData();
		var passRewards = player.pass_rewards !== undefined ? player.pass_rewards : player.bp_rewards;
		var adsHidden = player.xhs_ingame_advertize_hidden;
		if (adsHidden === undefined) adsHidden = ReadStoredBoolean(ADS_HIDDEN_STORAGE_KEY, false);
		return {
			show_advertize: !IsTruthy(adsHidden, false),
			show_quest_ui: ReadStoredBoolean(QUEST_DEFAULT_STORAGE_KEY, true),
			controlled_creeps_auto_attack: ReadStoredBoolean(CONTROLLED_CREEPS_AUTO_ATTACK_STORAGE_KEY, false),
			toggle_tag: IsTruthy(player.toggle_tag, true),
			pass_rewards: passRewards === 0 ? false : IsTruthy(passRewards, true),
			player_xp: IsTruthy(player.player_xp, true),
			winrate_toggle: IsTruthy(player.winrate_toggle, true)
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
		UpdateFooter();
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
		SendGameplaySettings(draft.controlled_creeps_auto_attack);
		var config = GameUI.CustomUIConfig ? GameUI.CustomUIConfig() : null;
		if (config && typeof config.SetXHSQuestLogDefaultVisibility === "function") {
			config.SetXHSQuestLogDefaultVisibility(draft.show_quest_ui);
		}
	}

	function SendGameplaySettings(controlledCreepsAutoAttack) {
		if (typeof GameEvents === "undefined" || !GameEvents.SendCustomGameEventToServer) return;
		GameEvents.SendCustomGameEventToServer("xhs_update_gameplay_settings", {
			controlled_creeps_auto_attack_after_move: controlledCreepsAutoAttack === true ? 1 : 0
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
			winrate_toggle: draft.winrate_toggle ? 1 : 0
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

	function DisableCompanion() {
		if (typeof GameEvents === "undefined" || !GameEvents.SendCustomGameEventToServer) {
			SetStatus($.Localize("#xhs_sp_settings_failed"), "error");
			return;
		}
		GameEvents.SendCustomGameEventToServer("supporter_pass_change_companion", { unit: "", js: true });
		SetStatus($.Localize("#xhs_sp_companion_disabled"), "success");
		Game.EmitSound("General.ButtonClick");
	}

	function Bind() {
		Panel("XHSSettingsBackdrop").SetPanelEvent("onactivate", function () { Toggle(false); });
		Panel("XHSSettingsCloseButton").SetPanelEvent("onactivate", function () { Toggle(false); });
		Panel("XHSSettingsTabGame").SetPanelEvent("onactivate", function () { SwitchTab("game"); });
		Panel("XHSSettingsTabSupporter").SetPanelEvent("onactivate", function () { SwitchTab("supporter"); });
		Panel("XHSSettingsSaveButton").SetPanelEvent("onactivate", Save);
		Panel("XHSSettingsCancelButton").SetPanelEvent("onactivate", Cancel);
		Panel("XHSSettingsDisableCompanion").SetPanelEvent("onactivate", DisableCompanion);
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
			SendGameplaySettings(ReadStoredBoolean(CONTROLLED_CREEPS_AUTO_ATTACK_STORAGE_KEY, false));
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
			RenderControls();
			SetStatus($.Localize((payload && payload.message) || "#xhs_sp_settings_failed"), "error");
		});
		if (CustomNetTables.SubscribeNetTableListener) {
			CustomNetTables.SubscribeNetTableListener("supporter_pass_player", function (tableName, key) {
				if (key !== String(Players.GetLocalPlayer()) || saving || !ROOT.BHasClass("IsVisible")) return;
				original = BuildSettings();
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
