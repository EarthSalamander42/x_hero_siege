(function () {
	var context = $.GetContextPanel();
	var closeButton = $("#XHSUIRecoveryClose");
	var hoveredTarget = null;
	var HOVER_INTERVAL = 0.05;
	var TOOLTIP_LAYER_INTERVAL = 0.25;
	var CONTEXT_MENU_LAYER_Z_INDEX = "13900";
	var TOOLTIP_LAYER_Z_INDEX = "14000";
	var CINEMATIC_LAYER_Z_INDEX = "15000";
	var HUD_LAYER_INTERVAL = 0.25;
	var TOOLTIP_PANEL_IDS = [
		"Tooltips",
		"TooltipManager",
		"DOTATooltipManager",
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
		{ key: "base", z: 100, ids: ["HUDElements"] },
		{ key: "xhs_hud", z: 200, ids: ["DungeonHUDContents", "XHSTopHudRoot"] },
		{ key: "leaderboards", z: 300, ids: ["XHSFarmLeaderboard"] },
		{ key: "scoreboard", z: 400, ids: ["XHSScoreboard", "TeamsContainer"] },
		{ key: "health", z: 600, ids: ["DiretidePanel", "CastleHP", "BossHP1"], classes: ["Diretide"] },
		{ key: "windows", z: 800, ids: ["GameInfoPanel"] },
		{ key: "modals", z: 1000, ids: ["EventPanel"] },
		{ key: "notifications", z: 1100, ids: ["XHSRewardFlyoutLayer", "XHSWaveCountdown", "XHSPauseRoot"], classes: ["XHSNotificationsRoot"] },
		{ key: "supporter_pass", z: 1150, ids: ["XHSSupporterPassWindow"], classes: ["XHSSupporterPassRoot"] },
		{ key: "devtools", z: 1200, ids: ["XHSDevToolsPanel", "XHSUIRecoveryClose"], classes: ["SupporterContentStudioRoot", "XHSUIRecoveryRoot"] },
		{ key: "flyout", z: 1300, ids: ["DungeonScoreboard"], classes: ["FlyoutScoreboardRoot"] },
		{ key: "cinematic", z: 15000, ids: ["XHSCinematicTopBar"], classes: ["XHSCinematicRoot"] }
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
		{ id: "EventPanel", visibleClass: "XHSEventsPanelVisible", removeClasses: ["XHSEventsPanelVisible"] },
		{ id: "XHSFarmLeaderboard", visibleClass: "IsVisible", removeClasses: ["IsVisible"] },
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
		if (!isValid(host) || host.id !== "HUDElements" || !tooltip.SetParent) return host;

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

	function applyHudLayerOrder() {
		var hud = findPanel("Hud") || getHudRoot();
		if (!isValid(hud) || !hud.GetChildCount || !hud.GetChild || !hud.MoveChildAfter) {
			$.Schedule(HUD_LAYER_INTERVAL, applyHudLayerOrder);
			return;
		}

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
		// ascending siblings. This coexists with intentional vanilla reparenting.
		var seen = [];
		var previous = null;
		for (var orderIndex = 0; orderIndex < ordered.length; orderIndex++) {
			var entry = ordered[orderIndex];
			if (seen.indexOf(entry.panel) !== -1) continue;
			seen.push(entry.panel);
			if (previous && previous !== entry.panel) hud.MoveChildAfter(entry.panel, previous);
			previous = entry.panel;
		}

		// Tooltips remain owned by vanilla. Raise their nearest direct host only
		// when it is not HUDElements; raising HUDElements would cover all custom UI.
		for (var tooltipIndex = 0; tooltipIndex < TOOLTIP_PANEL_IDS.length; tooltipIndex++) {
			var tooltip = hud.FindChildTraverse(TOOLTIP_PANEL_IDS[tooltipIndex]);
			var tooltipHost = promoteTooltipHost(tooltip, hud);
			if (isValid(tooltipHost) && tooltipHost.id !== "HUDElements") {
				tooltipHost.style.zIndex = TOOLTIP_LAYER_Z_INDEX;
				var cinematic = hud.FindChildTraverse("XHSCinematicTopBar");
				var cinematicHost = directHudChild(cinematic, hud);
				if (isValid(cinematicHost) && cinematicHost !== tooltipHost) {
					hud.MoveChildAfter(tooltipHost, previous || tooltipHost);
					hud.MoveChildAfter(cinematicHost, tooltipHost);
					cinematicHost.style.zIndex = CINEMATIC_LAYER_Z_INDEX;
				}
			}
		}

		$.Schedule(HUD_LAYER_INTERVAL, applyHudLayerOrder);
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
	GameUI.CustomUIConfig().XHSApplyHudLayerOrder = applyHudLayerOrder;
	applyHudLayerOrder();
	updateHover();
})();
