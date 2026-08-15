(function() {
	"use strict";

	var MATCH_URL_BASE = "https://mods.frostrose-studio.com/match/";
	var currentRunGameID = "";
	var button = $("#XHSRunIdSecondRowButton");
	var label = $("#XHSRunIdSecondRowLabel");

	function normalizeGameID(value) {
		var text = value === undefined || value === null ? "" : String(value).trim();
		return text && text !== "0" && text !== "-" ? text : "";
	}

	function update() {
		var identity = CustomNetTables.GetTableValue("xhs_run_identity", "current") || {};
		currentRunGameID = normalizeGameID(identity.game_id);
		button.SetHasClass("HasGameID", !!currentRunGameID);
		label.text = currentRunGameID ? "ID " + currentRunGameID : "GAME ID \u2014";
	}

	function openMatchPage() {
		if (!currentRunGameID) return;

		var url = MATCH_URL_BASE + encodeURIComponent(currentRunGameID);
		try {
			if (typeof ExternalBrowserGoToURL === "function") {
				ExternalBrowserGoToURL(url);
				return;
			}
			$.DispatchEvent("ExternalBrowserGoToURL", url);
		} catch (error) {
			$.Msg("[XHS] Unable to open match page: " + String(error));
		}
	}

	function findHudRoot() {
		var root = $.GetContextPanel();
		while (root && root.GetParent && root.GetParent()) root = root.GetParent();
		return root;
	}

	function removeLegacyInjectedButtons() {
		var root = findHudRoot();
		if (!root) return;

		var legacyIds = ["XHSRunIdTopBarButton", "XHSRunIdButton"];
		for (var i = 0; i < legacyIds.length; i++) {
			var legacyButton = root.FindChildTraverse(legacyIds[i]);
			if (legacyButton) legacyButton.DeleteAsync(0);
		}

		var hudElements = root.FindChildTraverse("HUDElements");
		var injectedSecondRow = hudElements && hudElements.FindChildTraverse("XHSRunIdSecondRowButton");
		if (injectedSecondRow && injectedSecondRow !== button) injectedSecondRow.DeleteAsync(0);
	}

	button.SetPanelEvent("onactivate", openMatchPage);
	button.SetPanelEvent("onmouseover", function() {
		button.AddClass("XHSTopBarUtilityHovered");
		var tooltip = currentRunGameID
			? "Game ID " + currentRunGameID + " · View match details"
			: "Game ID pending";
		$.DispatchEvent("UIShowTextTooltip", button, tooltip);
	});
	button.SetPanelEvent("onmouseout", function() {
		button.RemoveClass("XHSTopBarUtilityHovered");
		$.DispatchEvent("UIHideTextTooltip", button);
	});

	CustomNetTables.SubscribeNetTableListener("xhs_run_identity", function(tableName, key) {
		if (key === "current") update();
	});

	removeLegacyInjectedButtons();
	update();
})();
