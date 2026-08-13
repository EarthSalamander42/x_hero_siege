(function () {
	var context = $.GetContextPanel();
	var closeButton = $("#XHSUIRecoveryClose");
	var hoveredTarget = null;
	var HOVER_INTERVAL = 0.05;
	var TOOLTIP_LAYER_INTERVAL = 0.25;
	var END_SCREEN_LAYER_Z_INDEX = "1350";
	var CONTEXT_MENU_LAYER_Z_INDEX = "13900";
	var TOOLTIP_LAYER_Z_INDEX = "14000";
	var CINEMATIC_LAYER_Z_INDEX = "15000";
	var TOOLTIP_BLOCKING_PANEL_IDS = [
		"XHSTopHudRoot",
		"XHSDevToolsRoot",
		"XHSDevToolsPerformance",
		"XHSDevToolsPanel",
		"XHSEndScreenMain"
	];
	var HUD_LAYER_INTERVAL = 0.25;
	var hudLayerLoopScheduled = false;
	var FLYOUT_SUPPORTER_HOVER_ID = "XHSSupporterHoverCard_Scoreboard";
	var FLYOUT_SUPPORTER_HOVER_Z_INDEX = "1400";
	var WORLD_HEALTH_FRAME_IDS = ["XHSOverheadRoot", "XHSCreepHealthBarsRoot"];
	var FLYOUT_OCCLUDED_PANEL_IDS = [
		"XHSWaveCountdown",
		"XHSWaveQueue",
		"XHSRuneIndicator",
		"QuestLog",
		"QuestLogCollapseButton"
	];
	var SHOP_PANEL_IDS = ["shop", "Shop", "DOTAShop", "ShopContainer"];
	var TOOLTIP_PANEL_IDS = [
		"Tooltips",
		"TooltipManager",
		"DOTATooltipManager",
		"TextTooltip",
		"DOTATextTooltip",
		"DOTAUIOverlayTooltip",
		"AbilityTooltips",
		"ItemTooltips",
		"DOTAAbilityTooltip",
		"DOTAItemTooltip",
		"DOTAEconItemTooltip",
		"NeutralItemTooltip",
		"HUDTeamItemTooltip",
		"AbilityTooltip",
		"ItemTooltip"
	];
	var CONTEXT_MENU_PANEL_IDS = [
		"ContextMenuManager",
		"ContextMenu",
		"DOTAContextMenu",
		"ItemContextMenu",
		"DOTAItemContextMenu",
		"ContextMenuBody"
	];
	var CONTEXT_MENU_PANEL_CLASSES = [
		"ContextMenuManager",
		"ContextMenu",
		"ItemContextMenu",
		"ContextMenuBody"
	];
	// Shared HUD layer contract. Values intentionally leave room for local
	// children; ordering direct Hud children is what makes these priorities work
	// across vanilla and custom Panorama branches.
	var HUD_LAYER_RULES = [
		{ key: "world_health_bars", z: 70, ids: ["XHSCreepHealthBarsRoot"], classes: ["XHSCreepHealthBars"] },
		{ key: "xhs_hud", z: 90, ids: ["DungeonHUDContents", "XHSTopHudRoot", "QuestLog", "QuestLogCollapseButton"] },
		{ key: "base", z: 100, ids: ["HUDElements"] },
		{ key: "leaderboards", z: 300, ids: ["XHSFarmLeaderboard"] },
		{ key: "scoreboard", z: 400, ids: ["XHSScoreboard", "TeamsContainer"] },
		{ key: "health", z: 600, ids: ["DiretidePanel", "CastleHP", "BossHP1"], classes: ["Diretide"] },
		{ key: "windows", z: 800, ids: ["GameInfoPanel"] },
		{ key: "modals", z: 1000, ids: ["EventPanel"] },
		{ key: "notifications", z: 1100, ids: ["XHSRewardFlyoutLayer", "XHSWaveCountdown", "XHSPauseRoot"], classes: ["XHSNotificationsRoot"] },
		{ key: "supporter_pass", z: 1150, ids: ["XHSSupporterPassWindow"], classes: ["XHSSupporterPassRoot"] },
		{ key: "devtools", z: 1200, ids: ["XHSDevToolsPanel", "XHSUIRecoveryClose"], classes: ["SupporterContentStudioRoot", "XHSUIRecoveryRoot"] },
		{ key: "flyout", z: 1300, ids: ["DungeonScoreboard"], classes: ["FlyoutScoreboardRoot"] },
		{ key: "end_screen", z: 1350, ids: ["XHSEndScreenMain"], classes: ["XHSEndScreenRoot"] },
		{ key: "cinematic", z: 15000, ids: ["XHSCinematicTopBar"], classes: ["XHSCinematicRoot"] }
	];
	// Some Panorama panels request their own composition layer. Register those
	// panels here as well so their compositor order cannot bypass the direct-Hud
	// host order above.
	var COMPOSITION_LAYER_RULES = [
		{ key: "world_health_bars", z: 70, ids: ["XHSCreepHealthBarsRoot", "XHSOverheadRoot"], classes: ["XHSCreepHealthBars"] },
		{ key: "quest_ui", z: 90, ids: ["QuestLog", "QuestLogCollapseButton"] },
		{ key: "supporter_pass", z: 1150, ids: ["XHSSupporterPassWindow"], classes: ["XHSSupporterPassRoot"] },
		{ key: "flyout", z: 1300, ids: ["DungeonScoreboard"], classes: ["FlyoutScoreboardRoot"] }
	];
	// These layouts previously reparented and reordered themselves from their
	// feature scripts. Keep every cross-Hud move here so there is one owner for
	// compositor order and one retry loop when Valve rebuilds a branch.
	var HUD_HOST_PROMOTIONS = [
		{ anchorID: "XHSCreepHealthBarsRoot", hostClass: "XHSCreepHealthBars" },
		{ anchorID: "ContentStudioWindow", hostClass: "SupporterContentStudioRoot" },
		{ anchorID: "DungeonScoreboard", hostClass: "FlyoutScoreboardRoot" }
	];

	var targets = [
		{ id: "CastleHP", visibleStyle: true, handler: "CastleHP" },
		{ id: "BossHP1", visibleStyle: true, handler: "BossHP1" },
		{ id: "BossHP2", visibleStyle: true, handler: "BossHP2" },
		{ id: "BossHP3", visibleStyle: true, handler: "BossHP3" },
		{ id: "BossHP4", visibleStyle: true, handler: "BossHP4" },
		{ id: "XHSWaveCountdown", hiddenClass: "XHSNotificationHidden", handler: "XHSWaveCountdown" },
		{ id: "XHSWaveQueue", hiddenClass: "XHSWaveQueueHidden", handler: "XHSWaveQueue" },
		{ id: "XHSRuneIndicator", hiddenClass: "XHSRuneHidden", handler: "XHSRuneIndicator" },
		{ id: "XHSChannelNotification", hiddenClass: "XHSChannelNotificationHidden", handler: "XHSChannelNotification" },
		{ id: "XHSArenaTimer", visibleStyle: true, collapseStyle: true },
		{ id: "XHSPersonalEventTimer", visibleStyle: true, collapseStyle: true },
		{ id: "XHSFragmentQuestIntro", visibleClass: "IsVisible", removeClasses: ["IsVisible"] },
		{ id: "XHSPauseRoot", hiddenClass: "XHSPauseHidden", addClass: "XHSPauseHidden" },
		{ id: "DialogPanel", visibleClass: "Visible", removeClasses: ["Visible"] },
		{ id: "FloatingDialogPanel", visibleClass: "Visible", removeClasses: ["Visible"] },
		{ id: "ZoneToastPanel", visibleClass: "Visible", removeClasses: ["Visible"] },
		{ id: "XHSDevToolsPanel", visibleClass: "Visible", removeClasses: ["Visible"] }
	];

	function isToolsMode() {
		return Game.IsInToolsMode && Game.IsInToolsMode();
	}

	function getHudRoot() {
		var root = context;
		while (root && root.GetParent && root.GetParent()) {
			root = root.GetParent();
		}
		return root;
	}

	function findPanel(id) {
		var root = getHudRoot();
		return root && root.FindChildTraverse ? root.FindChildTraverse(id) : null;
	}

	function directHudChild(panel, hud) {
		var current = panel;
		var parent = current && current.GetParent ? current.GetParent() : null;
		while (current && parent && parent !== hud) {
			current = parent;
			parent = current.GetParent ? current.GetParent() : null;
		}
		return parent === hud ? current : null;
	}

	function promoteTooltipHost(tooltip, hud) {
		var host = directHudChild(tooltip, hud);
		if (!isValid(host)) {
			// An end-screen tooltip may already have been promoted to the common
			// ancestor above Hud by a previous recovery pass.
			var root = getHudRoot();
			var rootHost = directHudChild(tooltip, root);
			return isValid(rootHost) && isTooltipPanel(rootHost) ? rootHost : null;
		}
		if (host.id !== "HUDElements" || !tooltip.SetParent) return host;

		// Native item/ability tooltips normally live below HUDElements, which
		// means a direct custom HUD sibling can cover them regardless of z-index.
		// Move only the dedicated tooltip branch to Hud; never move HUDElements.
		var branch = tooltip;
		var parent = branch.GetParent ? branch.GetParent() : null;
		while (parent && parent !== host) {
			branch = parent;
			parent = branch.GetParent ? branch.GetParent() : null;
		}
		if (parent === host && isTooltipPanel(branch) && branch.SetParent) {
			try {
				branch.SetParent(hud);
				return branch;
			} catch (error) {
				$.Msg("[XHS UI Layers] Could not promote native tooltip branch: " + error);
			}
		}
		return host;
	}

	function promoteTooltipAboveCustomHud(tooltipHost) {
		if (!isValid(tooltipHost) || !isTooltipPanel(tooltipHost)) return tooltipHost;
		var root = getHudRoot();
		if (!isValid(root) || !root.FindChildTraverse) return tooltipHost;

		// The top bar, devtools and end screen can each establish a separate
		// composition context. A tooltip left anywhere below Hud can therefore
		// still be covered even with a larger local z-index. Promote only the
		// dedicated native tooltip branch to the shared root.
		var blockingHosts = [];
		for (var blockerIndex = 0; blockerIndex < TOOLTIP_BLOCKING_PANEL_IDS.length; blockerIndex++) {
			var blocker = root.FindChildTraverse(TOOLTIP_BLOCKING_PANEL_IDS[blockerIndex]);
			var blockerHost = directHudChild(blocker, root);
			if (isValid(blockerHost)
				&& blockerHost !== tooltipHost
				&& blockingHosts.indexOf(blockerHost) === -1) {
				blockingHosts.push(blockerHost);
			}
		}
		if (!blockingHosts.length) return tooltipHost;

		if (tooltipHost.GetParent
			&& tooltipHost.GetParent() !== root
			&& tooltipHost.SetParent) {
			try {
				tooltipHost.SetParent(root);
			} catch (error) {
				$.Msg("[XHS UI Layers] Could not promote tooltip above custom HUD: " + error);
				return tooltipHost;
			}
		}
		tooltipHost.style.zIndex = TOOLTIP_LAYER_Z_INDEX;
		if (root.MoveChildAfter
			&& tooltipHost.GetParent
			&& tooltipHost.GetParent() === root) {
			for (var hostIndex = 0; hostIndex < blockingHosts.length; hostIndex++) {
				root.MoveChildAfter(tooltipHost, blockingHosts[hostIndex]);
			}
		}
		return tooltipHost;
	}

	function isContextMenuPanel(panel) {
		if (!isValid(panel)) return false;
		var signature = (String(panel.id || "") + String(panel.paneltype || ""))
			.toLowerCase().replace(/[^a-z0-9]/g, "");
		if (signature.indexOf("contextmenu") !== -1) return true;
		if (!panel.BHasClass) return false;
		for (var classIndex = 0; classIndex < CONTEXT_MENU_PANEL_CLASSES.length; classIndex++) {
			if (panel.BHasClass(CONTEXT_MENU_PANEL_CLASSES[classIndex])) return true;
		}
		return false;
	}

	function promoteContextMenuHost(contextMenu, hud) {
		if (!isValid(contextMenu) || !isValid(hud)) return null;
		var host = directHudChild(contextMenu, hud);
		if (!isValid(host)) return null;

		if (host.id === "HUDElements" && contextMenu.SetParent) {
			var branch = contextMenu;
			var parent = branch.GetParent ? branch.GetParent() : null;
			while (parent && parent !== host) {
				branch = parent;
				parent = branch.GetParent ? branch.GetParent() : null;
			}
			// Never promote a broad lower-HUD branch based only on a nested menu.
			// The immediate native branch must itself be dedicated to context menus.
			if (parent === host && isContextMenuPanel(branch) && branch.SetParent) {
				try {
					branch.SetParent(hud);
					host = branch;
				} catch (error) {
					$.Msg("[XHS UI Layers] Could not promote native context menu: " + error);
				}
			}
		}

		if (isValid(host) && host.id !== "HUDElements") {
			host.style.zIndex = CONTEXT_MENU_LAYER_Z_INDEX;
		}
		return host;
	}

	function collectDynamicContextMenus(panel, depth, result) {
		if (!isValid(panel) || depth > 5 || !panel.GetChildCount || !panel.GetChild) return;
		for (var childIndex = 0; childIndex < panel.GetChildCount(); childIndex++) {
			var child = panel.GetChild(childIndex);
			if (!isValid(child)) continue;
			if (isContextMenuPanel(child)) {
				result.push(child);
				continue;
			}
			collectDynamicContextMenus(child, depth + 1, result);
		}
	}

	function keepNativeContextMenusOnTop(hud) {
		if (!isValid(hud) || !hud.FindChildTraverse) return;
		var seen = [];
		for (var idIndex = 0; idIndex < CONTEXT_MENU_PANEL_IDS.length; idIndex++) {
			var panel = hud.FindChildTraverse(CONTEXT_MENU_PANEL_IDS[idIndex]);
			if (isValid(panel) && seen.indexOf(panel) === -1) {
				seen.push(panel);
				promoteContextMenuHost(panel, hud);
			}
		}
		if (hud.FindChildrenWithClassTraverse) {
			for (var classIndex = 0; classIndex < CONTEXT_MENU_PANEL_CLASSES.length; classIndex++) {
				var panels = hud.FindChildrenWithClassTraverse(CONTEXT_MENU_PANEL_CLASSES[classIndex]) || [];
				for (var panelIndex = 0; panelIndex < panels.length; panelIndex++) {
					if (isValid(panels[panelIndex]) && seen.indexOf(panels[panelIndex]) === -1) {
						seen.push(panels[panelIndex]);
						promoteContextMenuHost(panels[panelIndex], hud);
					}
				}
			}
		}

		var hudElements = hud.FindChildTraverse("HUDElements");
		var dynamicPanels = [];
		collectDynamicContextMenus(hudElements, 0, dynamicPanels);
		for (var dynamicIndex = 0; dynamicIndex < dynamicPanels.length; dynamicIndex++) {
			if (seen.indexOf(dynamicPanels[dynamicIndex]) === -1) {
				seen.push(dynamicPanels[dynamicIndex]);
				promoteContextMenuHost(dynamicPanels[dynamicIndex], hud);
			}
		}
	}

	function childMatchesRule(child, rule) {
		if (!isValid(child)) return false;
		// HUDElements contains most vanilla panels. Never classify the whole
		// vanilla tree from a nested signature such as TeamsContainer or shop.
		if (child.id === "HUDElements") return rule.key === "base";
		// The flyout contains a TeamsContainer too. Give its direct Hud host one
		// unambiguous priority instead of also classifying it as the base scoreboard.
		if (child.FindChildTraverse && child.FindChildTraverse("DungeonScoreboard")) {
			return rule.key === "flyout";
		}
		for (var i = 0; i < rule.ids.length; i++) {
			if (child.id === rule.ids[i] || (child.FindChildTraverse && child.FindChildTraverse(rule.ids[i]))) {
				return true;
			}
		}
		for (var classIndex = 0; rule.classes && classIndex < rule.classes.length; classIndex++) {
			if (child.BHasClass && child.BHasClass(rule.classes[classIndex])) return true;
		}
		return false;
	}

	function findClassAncestor(panel, className, stopPanel) {
		var current = panel;
		while (isValid(current) && current !== stopPanel) {
			if (current.BHasClass && current.BHasClass(className)) return current;
			current = current.GetParent ? current.GetParent() : null;
		}
		return null;
	}

	function promoteDedicatedHudHosts(hud) {
		if (!isValid(hud) || !hud.FindChildTraverse) return;
		// XHSOverheadRoot belongs to the xhs_top_hud layout context. Moving it to
		// Hud makes the feature script lose its scoped #ID lookup and all real-hero
		// frames disappear. Repair older/hot-reloaded moves, then control this
		// branch through its composition z-index only.
		var overheadRoot = hud.FindChildTraverse("XHSOverheadRoot");
		var topHudRoot = hud.FindChildTraverse("XHSTopHudRoot");
		var topHudHost = findClassAncestor(topHudRoot, "XHSTopHudHost", hud);
		if (isValid(overheadRoot)
			&& isValid(topHudHost)
			&& overheadRoot.GetParent
			&& overheadRoot.GetParent() !== topHudHost
			&& overheadRoot.SetParent) {
			try {
				overheadRoot.SetParent(topHudHost);
			} catch (error) {
				$.Msg("[XHS UI Layers] Could not restore XHSOverheadRoot: " + error);
			}
		}
		for (var promotionIndex = 0; promotionIndex < HUD_HOST_PROMOTIONS.length; promotionIndex++) {
			var promotion = HUD_HOST_PROMOTIONS[promotionIndex];
			var anchor = hud.FindChildTraverse(promotion.anchorID);
			var host = findClassAncestor(anchor, promotion.hostClass, hud);
			if (!isValid(host) || !host.SetParent || !host.GetParent || host.GetParent() === hud) continue;
			try {
				host.SetParent(hud);
			} catch (error) {
				$.Msg("[XHS UI Layers] Could not promote " + promotion.hostClass + ": " + error);
			}
		}
	}

	function applyCompositionLayerOrder(root) {
		if (!isValid(root) || !root.FindChildTraverse) return;
		for (var ruleIndex = 0; ruleIndex < COMPOSITION_LAYER_RULES.length; ruleIndex++) {
			var rule = COMPOSITION_LAYER_RULES[ruleIndex];
			for (var idIndex = 0; idIndex < rule.ids.length; idIndex++) {
				var panel = root.FindChildTraverse(rule.ids[idIndex]);
				if (isValid(panel)) panel.style.zIndex = String(rule.z);
			}
			if (!root.FindChildrenWithClassTraverse) continue;
			for (var classIndex = 0; rule.classes && classIndex < rule.classes.length; classIndex++) {
				var panels = root.FindChildrenWithClassTraverse(rule.classes[classIndex]) || [];
				for (var panelIndex = 0; panelIndex < panels.length; panelIndex++) {
					if (isValid(panels[panelIndex])) panels[panelIndex].style.zIndex = String(rule.z);
				}
			}
		}
	}

	function isVanillaShopOpen(hud) {
		try {
			if (typeof Game.IsShopOpen === "function") {
				return !!Game.IsShopOpen();
			}
		} catch (error) {}

		if (!isValid(hud) || !hud.FindChildTraverse) return false;
		// Generic Visible classes describe the permanently mounted shop host on
		// some HUD versions, not whether its drawer is open.
		var openClasses = ["ShopOpen", "shop_open", "ShopVisible", "shop_visible"];
		for (var panelIndex = 0; panelIndex < SHOP_PANEL_IDS.length; panelIndex++) {
			var shop = hud.FindChildTraverse(SHOP_PANEL_IDS[panelIndex]);
			if (!isValid(shop) || !shop.BHasClass) continue;
			for (var classIndex = 0; classIndex < openClasses.length; classIndex++) {
				if (shop.BHasClass(openClasses[classIndex])) return true;
			}
		}
		return false;
	}

	function isFlyoutScoreboardOpen(hud) {
		if (!isValid(hud) || !hud.FindChildTraverse) return false;
		var scoreboard = hud.FindChildTraverse("DungeonScoreboard");
		var flyoutRoot = findClassAncestor(scoreboard, "FlyoutScoreboardRoot", null);
		return isValid(flyoutRoot)
			&& flyoutRoot.BHasClass
			&& (flyoutRoot.BHasClass("flyout_scoreboard_visible") || flyoutRoot.BHasClass("ZoneComplete"));
	}

	function isSupporterPassOpen(hud) {
		try {
			if (GameUI.CustomUIConfig().XHSSupporterPassVisible === true) return true;
		} catch (error) {}
		if (!isValid(hud) || !hud.FindChildTraverse) return false;
		var window = hud.FindChildTraverse("XHSSupporterPassWindow");
		return isValid(window)
			&& window.BHasClass
			&& (window.BHasClass("IsOpening")
				|| window.BHasClass("IsVisible")
				|| window.BHasClass("IsClosing"));
	}

	function syncWorldHealthFrameOcclusion(hud) {
		// World-space Panorama branches can compose above vanilla panels even with
		// a lower local z-index. Hide only those frames while a blocking overlay is
		// open; the rest of the custom HUD keeps its normal layer ordering.
		var occluded = isVanillaShopOpen(hud) || isFlyoutScoreboardOpen(hud);
		for (var frameIndex = 0; frameIndex < WORLD_HEALTH_FRAME_IDS.length; frameIndex++) {
			var frameRoot = hud.FindChildTraverse(WORLD_HEALTH_FRAME_IDS[frameIndex]);
			if (!isValid(frameRoot)) continue;
			frameRoot.SetHasClass("XHSWorldHealthFramesOccluded", occluded);
		}
	}

	function syncFlyoutTargetedOcclusion(hud) {
		// These notification panels live in a compositor branch which can still
		// render above the flyout regardless of sibling order or z-index. Keep the
		// workaround deliberately narrow: only suppress the overlapping quest,
		// rune and special-wave panels, and use opacity so their feature state keeps
		// running.
		var occluded = isFlyoutScoreboardOpen(hud) || isSupporterPassOpen(hud);
		for (var panelIndex = 0; panelIndex < FLYOUT_OCCLUDED_PANEL_IDS.length; panelIndex++) {
			var panel = hud.FindChildTraverse(FLYOUT_OCCLUDED_PANEL_IDS[panelIndex]);
			if (!isValid(panel)) continue;

			if (occluded) {
				if (panel._xhsFlyoutOcclusionActive !== true) {
					panel._xhsFlyoutOcclusionPreviousOpacity = panel.style.opacity;
					panel._xhsFlyoutOcclusionActive = true;
				}
				panel.style.opacity = "0";
			} else if (panel._xhsFlyoutOcclusionActive === true) {
				panel.style.opacity = panel._xhsFlyoutOcclusionPreviousOpacity || null;
				panel._xhsFlyoutOcclusionPreviousOpacity = null;
				panel._xhsFlyoutOcclusionActive = false;
			}
		}
	}

	function syncFlyoutSupporterHoverLayer(hud) {
		// The dynamically created supporter card is a sibling of DungeonScoreboard,
		// but the scoreboard's composition layer may still paint after it. Enforce
		// both forms of local ordering without moving the hover out of its layout
		// context (its positioning is relative to the flyout root).
		var scoreboard = hud.FindChildTraverse("DungeonScoreboard");
		var hover = hud.FindChildTraverse(FLYOUT_SUPPORTER_HOVER_ID);
		if (!isValid(scoreboard) || !isValid(hover)) return;

		hover.style.zIndex = FLYOUT_SUPPORTER_HOVER_Z_INDEX;
		var parent = scoreboard.GetParent ? scoreboard.GetParent() : null;
		if (isValid(parent)
			&& hover.GetParent
			&& hover.GetParent() === parent
			&& parent.MoveChildAfter) {
			parent.MoveChildAfter(hover, scoreboard);
		}
	}

	function scheduleHudLayerOrder() {
		if (hudLayerLoopScheduled) return;
		hudLayerLoopScheduled = true;
		$.Schedule(HUD_LAYER_INTERVAL, function () {
			hudLayerLoopScheduled = false;
			applyHudLayerOrder();
		});
	}

	function applyHudLayerOrder() {
		var hud = findPanel("Hud") || getHudRoot();
		if (!isValid(hud) || !hud.GetChildCount || !hud.GetChild || !hud.MoveChildAfter) {
			scheduleHudLayerOrder();
			return;
		}
		promoteDedicatedHudHosts(hud);

		var ordered = [];
		for (var ruleIndex = 0; ruleIndex < HUD_LAYER_RULES.length; ruleIndex++) {
			var rule = HUD_LAYER_RULES[ruleIndex];
			for (var childIndex = 0; childIndex < hud.GetChildCount(); childIndex++) {
				var child = hud.GetChild(childIndex);
				if (childMatchesRule(child, rule)) {
					child.style.zIndex = String(rule.z);
					ordered.push({ panel: child, z: rule.z });
				}
			}
		}

		// Deduplicate hosts which contain more than one signature, then enforce
		// ascending siblings. Cross-Hud reparenting is owned above, never by the
		// individual feature scripts.
		var seen = [];
		var previous = null;
		for (var orderIndex = 0; orderIndex < ordered.length; orderIndex++) {
			var entry = ordered[orderIndex];
			if (seen.indexOf(entry.panel) !== -1) continue;
			seen.push(entry.panel);
			if (previous && previous !== entry.panel) hud.MoveChildAfter(entry.panel, previous);
			previous = entry.panel;
		}

		applyCompositionLayerOrder(hud);
		syncWorldHealthFrameOcclusion(hud);
		syncFlyoutTargetedOcclusion(hud);
		syncFlyoutSupporterHoverLayer(hud);

		// Tooltips remain owned by vanilla. Raise their nearest direct host only
		// when it is not HUDElements; raising HUDElements would cover all custom UI.
		for (var tooltipIndex = 0; tooltipIndex < TOOLTIP_PANEL_IDS.length; tooltipIndex++) {
			var tooltip = hud.FindChildTraverse(TOOLTIP_PANEL_IDS[tooltipIndex]);
			var tooltipHost = promoteTooltipHost(tooltip, hud);
			tooltipHost = promoteTooltipAboveCustomHud(tooltipHost);
			if (isValid(tooltipHost) && tooltipHost.id !== "HUDElements") {
				tooltipHost.style.zIndex = TOOLTIP_LAYER_Z_INDEX;
				var cinematic = hud.FindChildTraverse("XHSCinematicTopBar");
				var cinematicHost = directHudChild(cinematic, hud);
				var tooltipInHud = tooltipHost.GetParent && tooltipHost.GetParent() === hud;
				if (tooltipInHud && isValid(cinematicHost) && cinematicHost !== tooltipHost) {
					hud.MoveChildAfter(tooltipHost, previous || tooltipHost);
					hud.MoveChildAfter(cinematicHost, tooltipHost);
					cinematicHost.style.zIndex = CINEMATIC_LAYER_Z_INDEX;
				}
			}
		}

		scheduleHudLayerOrder();
	}

	function isTooltipPanel(panel) {
		if (!panel) {
			return false;
		}
		var id = String(panel.id || "").toLowerCase();
		var panelType = String(panel.paneltype || "").toLowerCase();
		return id.indexOf("tooltip") !== -1 || panelType.indexOf("tooltip") !== -1;
	}

	function promoteTooltipPanel(panel, root) {
		var current = panel;
		while (current && current !== root && isTooltipPanel(current)) {
			current.style.zIndex = TOOLTIP_LAYER_Z_INDEX;
			current = current.GetParent ? current.GetParent() : null;
		}
	}

	function keepNativeTooltipsOnTop() {
		var root = getHudRoot();
		var hud = findPanel("Hud") || root;
		if (root && root.FindChildTraverse) {
			for (var i = 0; i < TOOLTIP_PANEL_IDS.length; i++) {
				var panel = root.FindChildTraverse(TOOLTIP_PANEL_IDS[i]);
				if (isValid(panel)) {
					promoteTooltipPanel(panel, root);
					var host = promoteTooltipHost(panel, hud);
					host = promoteTooltipAboveCustomHud(host);
					if (isValid(host) && host.id !== "HUDElements") {
						host.style.zIndex = TOOLTIP_LAYER_Z_INDEX;
					}
				}
			}
		}
		keepNativeContextMenusOnTop(hud);
		$.Schedule(TOOLTIP_LAYER_INTERVAL, keepNativeTooltipsOnTop);
	}

	function isValid(panel) {
		return panel && (!panel.IsValid || panel.IsValid());
	}

	function hasAnyClass(panel, classNames) {
		for (var i = 0; i < classNames.length; i++) {
			if (panel.BHasClass(classNames[i])) {
				return true;
			}
		}
		return false;
	}

	function isTargetVisible(target, panel) {
		if (!isValid(panel) || panel.visible === false || panel.actuallayoutwidth < 4 || panel.actuallayoutheight < 4) {
			return false;
		}
		if (target.visibleStyle && panel.style.visibility !== "visible") {
			return false;
		}
		if (target.hiddenClass && panel.BHasClass(target.hiddenClass)) {
			return false;
		}
		if (target.visibleClass && !panel.BHasClass(target.visibleClass)) {
			return false;
		}
		if (target.anyVisibleClass && !hasAnyClass(panel, target.anyVisibleClass)) {
			return false;
		}
		return true;
	}

	function panelBounds(panel) {
		var position = panel.GetPositionWithinWindow();
		var scaleX = Number(panel.actualuiscale_x) || 1;
		var scaleY = Number(panel.actualuiscale_y) || 1;
		return {
			x: Number(position.x) || 0,
			y: Number(position.y) || 0,
			width: panel.actuallayoutwidth * scaleX,
			height: panel.actuallayoutheight * scaleY
		};
	}

	function contains(bounds, cursor) {
		return cursor[0] >= bounds.x && cursor[0] <= bounds.x + bounds.width &&
			cursor[1] >= bounds.y && cursor[1] <= bounds.y + bounds.height;
	}

	function dynamicToastTargets(root) {
		if (!root || !root.FindChildrenWithClassTraverse) {
			return [];
		}
		var panels = root.FindChildrenWithClassTraverse("XHSNotificationToast") || [];
		var result = [];
		for (var i = 0; i < panels.length; i++) {
			if (isValid(panels[i]) && panels[i].visible !== false &&
				panels[i].actuallayoutwidth >= 4 && panels[i].actuallayoutheight >= 4) {
				result.push({
					id: "",
					panel: panels[i],
					dynamicToast: true
				});
			}
		}
		return result;
	}

	function findHoveredTarget() {
		var cursor = GameUI.GetCursorPosition();
		var best = null;
		var bestArea = Number.MAX_VALUE;

		for (var i = 0; i < targets.length; i++) {
			var target = targets[i];
			var panel = findPanel(target.id);
			if (!isTargetVisible(target, panel)) {
				continue;
			}
			var bounds = panelBounds(panel);
			if (contains(bounds, cursor)) {
				var area = bounds.width * bounds.height;
				if (area < bestArea) {
					best = { target: target, panel: panel, bounds: bounds };
					bestArea = area;
				}
			}
		}

		var root = getHudRoot();
		var toasts = dynamicToastTargets(root);
		for (var toastIndex = 0; toastIndex < toasts.length; toastIndex++) {
			var toast = toasts[toastIndex];
			var toastBounds = panelBounds(toast.panel);
			if (contains(toastBounds, cursor)) {
				var toastArea = toastBounds.width * toastBounds.height;
				if (toastArea < bestArea) {
					best = { target: toast, panel: toast.panel, bounds: toastBounds };
					bestArea = toastArea;
				}
			}
		}

		return best;
	}

	function hideButton() {
		hoveredTarget = null;
		if (closeButton) {
			closeButton.RemoveClass("Visible");
		}
	}

	function updateHover() {
		if (!isToolsMode() || !closeButton) {
			hideButton();
			$.Schedule(HOVER_INTERVAL, updateHover);
			return;
		}

		var result = findHoveredTarget();
		if (!result) {
			hideButton();
			$.Schedule(HOVER_INTERVAL, updateHover);
			return;
		}

		hoveredTarget = result;
		var buttonSize = 30;
		var x = Math.max(0, result.bounds.x + result.bounds.width - buttonSize - 4);
		var y = Math.max(0, result.bounds.y + 4);
		closeButton.style.position = x.toFixed(0) + "px " + y.toFixed(0) + "px 0px";
		closeButton.AddClass("Visible");
		$.Schedule(HOVER_INTERVAL, updateHover);
	}

	function resetWithDescriptor(target, panel) {
		if (target.dynamicToast) {
			panel.visible = false;
			return;
		}
		if (target.removeClasses) {
			for (var i = 0; i < target.removeClasses.length; i++) {
				panel.RemoveClass(target.removeClasses[i]);
			}
		}
		if (target.addClass) {
			panel.AddClass(target.addClass);
		}
		if (target.collapseStyle) {
			panel.style.visibility = "collapse";
		}
	}

	function recoverHoveredTarget() {
		if (!isToolsMode() || !hoveredTarget || !isValid(hoveredTarget.panel)) {
			hideButton();
			return;
		}

		var target = hoveredTarget.target;
		var handlers = GameUI.CustomUIConfig().XHSUIRecoveryHandlers || {};
		var handler = target.handler ? handlers[target.handler] : null;
		if (typeof handler === "function") {
			handler();
		} else {
			resetWithDescriptor(target, hoveredTarget.panel);
		}
		hideButton();
	}

	if (closeButton) {
		closeButton.SetPanelEvent("onactivate", recoverHoveredTarget);
		closeButton.SetPanelEvent("onmouseover", function () {
			$.DispatchEvent("DOTAShowTextTooltip", closeButton, "Masquer cette UI (Tools Mode)");
		});
		closeButton.SetPanelEvent("onmouseout", function () {
			$.DispatchEvent("DOTAHideTextTooltip", closeButton);
		});
	}

	keepNativeTooltipsOnTop();
	applyHudLayerOrder();
	updateHover();
})();
