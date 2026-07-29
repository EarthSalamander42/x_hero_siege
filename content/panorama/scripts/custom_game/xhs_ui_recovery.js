(function () {
	var context = $.GetContextPanel();
	var closeButton = $("#XHSUIRecoveryClose");
	var hoveredTarget = null;
	var HOVER_INTERVAL = 0.05;

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
		{ id: "XHSSupporterPassWindow", anyVisibleClass: ["IsVisible", "IsOpening"], removeClasses: ["IsVisible", "IsOpening", "IsClosing"] },
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

	updateHover();
})();
