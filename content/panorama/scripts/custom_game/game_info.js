"use strict";

(function() {
	function FindAncestorPanel(id) {
		var panel = $.GetContextPanel();

		for (var i = 0; i < 12 && panel; i++) {
			if (panel.id === id) {
				return panel;
			}

			var match = panel.FindChildTraverse(id);
			if (match) {
				return match;
			}

			panel = panel.GetParent();
		}

		return null;
	}

	function AddClass(panel, className) {
		if (panel && !panel.BHasClass(className)) {
			panel.AddClass(className);
		}
	}

	function FindHudAncestor(panel) {
		for (var current = panel; current; current = current.GetParent ? current.GetParent() : null) {
			if (current.id === "Hud") {
				return current;
			}
		}

		return null;
	}

	function GetHudDirectChild(panel, hud) {
		var current = panel;

		while (current && current.GetParent && current.GetParent() !== hud) {
			current = current.GetParent();
		}

		return current && current.GetParent && current.GetParent() === hud ? current : null;
	}

	function RaiseGameInfoShell(shell) {
		if (!shell) {
			return false;
		}

		// Preserve Valve's complete Game Info branch so its open/close controller
		// keeps working. Raise that branch above HUDElements instead of extracting
		// GameInfoPanel from its native hierarchy.
		shell.style.zIndex = "1000";

		var hud = FindHudAncestor(shell);
		if (!hud || !hud.FindChildTraverse || !hud.MoveChildAfter) {
			return false;
		}

		var hudElements = hud.FindChildTraverse("HUDElements");
		var hudElementsRoot = GetHudDirectChild(hudElements, hud);
		var gameInfoRoot = GetHudDirectChild(shell, hud);
		if (!hudElementsRoot || !gameInfoRoot || gameInfoRoot === hudElementsRoot) {
			return false;
		}

		gameInfoRoot.style.zIndex = "1000";
		hud.MoveChildAfter(gameInfoRoot, hudElementsRoot);
		return true;
	}

	function StyleGameInfoShell() {
		var shell = FindAncestorPanel("GameInfoPanel");

		if (!shell) {
			$.Schedule(0.1, StyleGameInfoShell);
			return;
		}

		var container = shell.GetParent ? shell.GetParent() : null;
		var button = container && container.FindChildTraverse ? container.FindChildTraverse("GameInfoButton") : null;
		var icon = button && button.FindChildTraverse ? button.FindChildTraverse("GameInfoIcon") : null;
		var openClose = button && button.FindChildTraverse ? button.FindChildTraverse("GameInfoOpenClose") : null;

		AddClass(shell, "XHSGameInfoPanel");
		AddClass(button, "XHSGameInfoButton");
		AddClass(icon, "XHSGameInfoIcon");
		AddClass(openClose, "XHSGameInfoOpenClose");
		RaiseGameInfoShell(shell);

		// Fallback styles for Valve's wrapper, which lives outside this custom layout.
		shell.style.width = "600px";
		shell.style.backgroundColor = "#061421ee";
		shell.style.boxShadow = "fill #000000aa 0px 0px 12px 0px";

		if (button) {
			button.style.zIndex = "1001";
			button.style.width = "38px";
			button.style.height = "70px";
			button.style.backgroundColor = "#071827f4";
			button.style.border = "1px solid #5ad0ffaa";
		}

		if (icon) {
			icon.style.washColor = "#77d8ff";
			icon.style.opacity = "0.96";
		}

		if (openClose) {
			openClose.style.zIndex = "1002";
			openClose.style.washColor = "#dff6ff";
			openClose.style.opacity = "0.9";
		}
	}

	StyleGameInfoShell();


	/*
	var AbilityPanel = $("#AbilitiesImage");

	var abilities = [
		"imba_abaddon_over_channel",
		"imba_bounty_hunter_headhunter",
		"imba_centaur_thick_hide",
		"imba_crystal_maiden_arcane_dynamo",
		"imba_faceless_void_timelord",
		"imba_kunkka_ebb_and_flow",
		"imba_queenofpain_delightful_torment",
		"imba_scaldris_antipode",
		"imba_tiny_rolling_stone",
		"imba_ursa_territorial_hunter",
	]

	if (AbilityPanel) {
		for (var i = 0; i < abilities.length; ++i) {
			var abilityPanelName = "tutorial_ability_" + i;
			var abilityPanel = AbilityPanel.FindChild(abilityPanelName);

			if (abilityPanel === null) {
				// Needs DOTAAbilityImage to be able to load from flash3 images
				// (similar to those used for dota shop, hence reusing
				// existing resources)
				abilityPanel = $.CreatePanel("DOTAAbilityImage", AbilityPanel, abilityPanelName);
				abilityPanel.AddClass("AbilityIcon")
			}

			if (abilities[i]) {
				abilityPanel.abilityname = abilities[i];

				(function (abilityPanel, ability) {
					abilityPanel.SetPanelEvent("onmouseover", function () {
						$.DispatchEvent("DOTAShowAbilityTooltip", abilityPanel, ability);
					})
					abilityPanel.SetPanelEvent("onmouseout", function () {
						$.DispatchEvent("DOTAHideAbilityTooltip", abilityPanel);
					})
				})(abilityPanel, abilities[i]);
			} else {
				abilityPanel.abilityname = "";
			}
		}
	}

	var ItemPanel = $("#ItemsImage");

	var items = [
		"item_imba_angelic_alliance",
		"item_imba_arcane_nexus",
		"item_imba_black_queen_cape",
		"item_imba_jarnbjorn",
		"item_imba_siege_cuirass",
		"item_imba_sogat_cuirass",
		"item_imba_starfury",
		"item_imba_ultimate_scepter_synth",
	]

	if (ItemPanel) {
		for (var i = 0; i < items.length; ++i) {
			var itemPanelName = "tutorial_item_" + i;
			var itemPanel = ItemPanel.FindChild(itemPanelName);

			if (itemPanel === null) {
				// Needs DOTAItemImage to be able to load from flash3 images
				// (similar to those used for dota shop, hence reusing
				// existing resources)
				itemPanel = $.CreatePanel("DOTAItemImage", ItemPanel, itemPanelName);
				itemPanel.AddClass("AbilityIcon")
			}

			if (items[i]) {
				itemPanel.itemname = items[i];
			} else {
				itemPanel.itemname = "";
			}
		}
	}
*/
})();
