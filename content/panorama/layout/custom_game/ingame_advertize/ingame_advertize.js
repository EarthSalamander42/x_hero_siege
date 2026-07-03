const FIX_CG_ROOT = $.GetContextPanel();
const ADS_URLS = {
	website: "https://mods.frostrose-studio.com/watch",
	discord: "https://discord.frostrose-studio.com/",
};
const ADS_HIDE_STORAGE_KEY = "xhs_ingame_advertize_hidden";
let adsDoNotShowAgain = false;
let adsDismissedThisSession = false;
let adsForceOpened = false;
let adsLastSentHidden = null;

function GetAdsConfig() {
	if (typeof GameUI !== "undefined" && GameUI.CustomUIConfig) {
		return GameUI.CustomUIConfig();
	}

	return null;
}

function GetAdsLocalStorage() {
	if (typeof $ !== "undefined" && $.LocalStorage) {
		return $.LocalStorage;
	}

	if (typeof LocalStorage !== "undefined") {
		return LocalStorage;
	}

	return null;
}

function IsStoredAdsHidden() {
	const config = GetAdsConfig();
	if (config && config[ADS_HIDE_STORAGE_KEY] === true) {
		return true;
	}

	const localStorage = GetAdsLocalStorage();
	if (localStorage && localStorage.GetItem) {
		try {
			const storedValue = localStorage.GetItem(ADS_HIDE_STORAGE_KEY);
			return storedValue === "1" || storedValue === 1 || storedValue === true;
		} catch (error) {
		}
	}

	return false;
}

function IsAdsTruthy(value) {
	return value === true || value === 1 || value === "1" || value === "true";
}

function IsAdsFalsy(value) {
	return value === false || value === 0 || value === "0" || value === "false";
}

function ReadAdsHiddenField(data) {
	if (!data) {
		return undefined;
	}

	const settings = data.settings || {};
	const values = [
		data[ADS_HIDE_STORAGE_KEY],
		data.ingame_advertize_hidden,
		data.advertize_hidden,
		data.ads_hidden,
		data.do_not_show_advertize,
		data.do_not_show_ingame_advertize,
		settings[ADS_HIDE_STORAGE_KEY],
		settings.ingame_advertize_hidden,
		settings.advertize_hidden,
		settings.ads_hidden,
	];

	for (let i = 0; i < values.length; i++) {
		if (IsAdsTruthy(values[i])) {
			return true;
		}

		if (IsAdsFalsy(values[i])) {
			return false;
		}
	}

	return undefined;
}

function GetBackendAdsHiddenPreference() {
	if (typeof CustomNetTables === "undefined" || !CustomNetTables.GetTableValue || typeof Players === "undefined") {
		return undefined;
	}

	const playerID = Players.GetLocalPlayer ? Players.GetLocalPlayer() : -1;
	if (playerID < 0) {
		return undefined;
	}

	const values = [
		ReadAdsHiddenField(CustomNetTables.GetTableValue("supporter_pass_player", playerID.toString())),
		ReadAdsHiddenField(CustomNetTables.GetTableValue("battlepass_player", playerID.toString())),
		ReadAdsHiddenField(CustomNetTables.GetTableValue("battlepass_player", playerID)),
	];

	for (let i = 0; i < values.length; i++) {
		if (values[i] !== undefined) {
			return values[i];
		}
	}

	return undefined;
}

function GetResolvedAdsHiddenPreference() {
	const backendValue = GetBackendAdsHiddenPreference();
	if (backendValue !== undefined) {
		return backendValue;
	}

	return IsStoredAdsHidden();
}

function SendAdsHiddenPreferenceToServer(value) {
	if (typeof GameEvents === "undefined" || !GameEvents.SendCustomGameEventToServer || typeof Players === "undefined") {
		return;
	}

	const playerID = Players.GetLocalPlayer ? Players.GetLocalPlayer() : -1;
	if (playerID < 0) {
		return;
	}

	adsLastSentHidden = value === true;
	GameEvents.SendCustomGameEventToServer("supporter_pass_update_settings", {
		player_id: playerID,
		xhs_ingame_advertize_hidden: adsLastSentHidden,
	});
}

function StoreAdsHidden(value, sendToServer) {
	const normalizedValue = value === true;
	const config = GetAdsConfig();
	if (config) {
		config[ADS_HIDE_STORAGE_KEY] = normalizedValue;
	}

	const localStorage = GetAdsLocalStorage();
	if (localStorage && localStorage.SetItem) {
		try {
			localStorage.SetItem(ADS_HIDE_STORAGE_KEY, normalizedValue ? "1" : "0");
		} catch (error) {
		}
	}

	if (sendToServer === true) {
		SendAdsHiddenPreferenceToServer(normalizedValue);
	}
}

function IsAdsCheckboxChecked(checkbox) {
	if (!checkbox) {
		return false;
	}

	if (checkbox.checked === true) {
		return true;
	}

	if (checkbox.IsSelected && checkbox.IsSelected()) {
		return true;
	}

	return checkbox.BHasClass && (checkbox.BHasClass("Selected") || checkbox.BHasClass("Activated"));
}

function SetAdsCheckboxChecked(value) {
	const checkbox = FIX_CG_ROOT.FindChildTraverse("Ads_DoNotShowAgain");
	if (!checkbox) {
		return;
	}

	checkbox.checked = value === true;
	if (checkbox.SetSelected) {
		checkbox.SetSelected(value === true);
	}
}

function SetAdsPanelVisible(forceShow) {
	if (forceShow !== true && (adsDoNotShowAgain || GetResolvedAdsHiddenPreference() || adsDismissedThisSession)) {
		FIX_CG_ROOT.SetHasClass("show", false);
		return;
	}

	FIX_CG_ROOT.SetHasClass("show", true);
}

function OpenFixGame() {
	adsForceOpened = false;
	SetAdsPanelVisible(false);
}

function OpenXHSIngameAdvertize() {
	adsForceOpened = true;
	adsDoNotShowAgain = GetResolvedAdsHiddenPreference();
	SetAdsCheckboxChecked(adsDoNotShowAgain);
	SetAdsPanelVisible(true);
}

function IsXHSIngameAdvertizeOpen() {
	return FIX_CG_ROOT && FIX_CG_ROOT.BHasClass && FIX_CG_ROOT.BHasClass("show");
}

function HideXHSIngameAdvertizeToggle() {
	adsForceOpened = false;
	FIX_CG_ROOT.SetHasClass("show", false);
}

function ToggleXHSIngameAdvertize() {
	if (IsXHSIngameAdvertizeOpen()) {
		HideXHSIngameAdvertizeToggle();
		return;
	}

	OpenXHSIngameAdvertize();
}

function CloseFixGame() {
	adsDismissedThisSession = true;
	adsForceOpened = false;
	UpdateAdsHiddenPreferenceFromCheckbox(true);
	FIX_CG_ROOT.SetHasClass("show", false);
	StoreAdsHidden(adsDoNotShowAgain, false);
}

function UpdateAdsHiddenPreferenceFromCheckbox(sendToServer) {
	const checkbox = FIX_CG_ROOT.FindChildTraverse("Ads_DoNotShowAgain");
	adsDoNotShowAgain = IsAdsCheckboxChecked(checkbox);
	StoreAdsHidden(adsDoNotShowAgain, sendToServer === true);
}

function OnAdsDoNotShowToggle() {
	$.Schedule(0.0, function() {
		UpdateAdsHiddenPreferenceFromCheckbox(true);
	});
}

function ApplyAdsBackendPreference(data) {
	const backendValue = ReadAdsHiddenField(data);
	if (backendValue === undefined) {
		return;
	}

	adsDoNotShowAgain = backendValue;
	SetAdsCheckboxChecked(adsDoNotShowAgain);
	StoreAdsHidden(adsDoNotShowAgain, false);

	if (adsForceOpened) {
		FIX_CG_ROOT.SetHasClass("show", true);
		return;
	}

	SetAdsPanelVisible(false);
}

function OpenAdsUrl(url) {
	if (typeof DOTADisplayURL === "function") {
		DOTADisplayURL(url);
		return;
	}

	if (typeof ExternalBrowserGoToURL === "function") {
		ExternalBrowserGoToURL(url);
		return;
	}

	$.DispatchEvent("ExternalBrowserGoToURL", url);
}

function OpenAdsWebsite() {
	OpenAdsUrl(ADS_URLS.website);
}

function OpenAdsDiscord() {
	OpenAdsUrl(ADS_URLS.discord);
}

(function () {
	const config = GetAdsConfig();
	if (config) {
		config.OpenXHSIngameAdvertize = OpenXHSIngameAdvertize;
		config.ToggleXHSIngameAdvertize = ToggleXHSIngameAdvertize;
	}

	adsDoNotShowAgain = GetResolvedAdsHiddenPreference();
	SetAdsCheckboxChecked(adsDoNotShowAgain);
	OpenFixGame();

	if (config && config.XHSOpenAdvertizeRequested === true) {
		config.XHSOpenAdvertizeRequested = false;
		OpenXHSIngameAdvertize();
	}

	const descriptionPanel = FIX_CG_ROOT.FindChildTraverse("Ads_Description");

	if (descriptionPanel) {
		descriptionPanel.SetDialogVariable("player_count_monthly", "3000");
	}

	FIX_CG_ROOT.SetDialogVariable("player_count_monthly", "3000");

	if (typeof CustomNetTables !== "undefined" && CustomNetTables.SubscribeNetTableListener) {
		CustomNetTables.SubscribeNetTableListener("supporter_pass_player", function(tableName, key, data) {
			const playerID = typeof Players !== "undefined" && Players.GetLocalPlayer ? Players.GetLocalPlayer() : -1;
			if (playerID >= 0 && key === playerID.toString()) {
				ApplyAdsBackendPreference(data);
			}
		});
	}

	$.Schedule(1.0, function() {
		const backendValue = GetBackendAdsHiddenPreference();
		if (backendValue !== undefined) {
			ApplyAdsBackendPreference({
				xhs_ingame_advertize_hidden: backendValue,
			});
		}
	});
})();
