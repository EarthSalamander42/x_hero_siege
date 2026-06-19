(function () {
	var TOP_CONTAINER_ID = "#XHSTopNotifications";
	var BOTTOM_CONTAINER_ID = "#XHSBottomNotifications";
	var WAVE_PANEL_ID = "#XHSWaveCountdown";
	var MAX_NOTIFICATIONS = 4;
	var lastTopNotification = null;
	var lastBottomNotification = null;
	var activeWaveSchedule = null;

	function getDuration(msg) {
		if (typeof msg.duration === "number" && msg.duration > 0) {
			return msg.duration;
		}

		return 3;
	}

	function isContinuation(msg) {
		return msg.continue === true || (msg.style && msg.style.continue === true);
	}

	function getSeverity(msg) {
		if (msg.severity) {
			return msg.severity;
		}

		var style = msg.style || {};
		var color = String(style.color || "").toLowerCase();
		var text = String(msg.text || "").toLowerCase();

		if (color === "red" || color === "#ff0000" || text.indexOf("warning") !== -1 || text.indexOf("respawn disabled") !== -1) {
			return "warning";
		}

		if (color === "green" || color === "lightgreen" || text.indexOf("enabled") !== -1 || text.indexOf("reward") !== -1) {
			return "success";
		}

		return "default";
	}

	function localizeText(text) {
		if (!text) {
			return "No Text provided";
		}

		return $.Localize(text);
	}

	function formatRewardNumber(value) {
		var number = Number(value) || 0;
		return String(Math.floor(number)).replace(/\B(?=(\d{3})+(?!\d))/g, ",");
	}

	function getHudRoot() {
		var panel = $.GetContextPanel();
		while (panel !== null && panel.id !== "Hud") {
			panel = panel.GetParent();
		}

		return panel;
	}

	function findHudElement(id) {
		var hud = getHudRoot();
		if (!hud) {
			return null;
		}

		return hud.FindChildTraverse(id);
	}

	function findFirstHudElement(ids) {
		for (var i = 0; i < ids.length; i++) {
			var panel = findHudElement(ids[i]);
			if (panel) {
				return panel;
			}
		}

		return null;
	}

	function getRewardTarget(type) {
		if (type === "gold") {
			return findFirstHudElement(["ShopButton", "GoldLabel"]);
		}

		if (type === "stats") {
			return findFirstHudElement(["stats_container", "stragiint", "stats"]);
		}

		return null;
	}

	function getPanelCenter(panel) {
		if (!panel) {
			return null;
		}

		var x = 0;
		var y = 0;

		if (panel.GetPositionWithinWindow) {
			var position = panel.GetPositionWithinWindow();
			if (position) {
				x = Number(position.x || position[0] || 0);
				y = Number(position.y || position[1] || 0);
			}
		} else {
			x = Number(panel.actualxoffset || 0);
			y = Number(panel.actualyoffset || 0);
		}

		return {
			x: x + Number(panel.actuallayoutwidth || 0) * 0.5,
			y: y + Number(panel.actuallayoutheight || 0) * 0.5
		};
	}

	function getWaveWarningInfo(msg) {
		var text = String((msg && msg.text) || "");
		var match = text.match(/incoming wave of darkness from the (west|north|east|south)/i);

		if (!match) {
			return null;
		}

		return {
			direction: match[1].toUpperCase()
		};
	}

	function isCoveredTimerWarning(msg) {
		var text = String((msg && msg.text) || "").toLowerCase();
		return text.indexOf("muradin event in 30 sec") !== -1 ||
			text.indexOf("farming event in 30 sec") !== -1;
	}

	function cancelWaveSchedule() {
		if (activeWaveSchedule === null) {
			return;
		}

		if (typeof $.CancelScheduled === "function") {
			$.CancelScheduled(activeWaveSchedule);
		} else if (activeWaveSchedule.Cancel) {
			activeWaveSchedule.Cancel();
		}

		activeWaveSchedule = null;
	}

	function applyStyle(panel, style) {
		if (!style) {
			return;
		}

		for (var key in style) {
			if (key === "continue") {
				continue;
			}

			panel.style[key] = style[key];
		}
	}

	function createToast(container, lane, msg) {
		var toast = $.CreatePanel("Panel", container, "");
		toast.AddClass("XHSNotificationToast");
		toast.hittest = false;

		if (lane === "bottom") {
			toast.AddClass("XHSNotificationBottom");
		}

		var severity = getSeverity(msg);
		if (severity === "warning") {
			toast.AddClass("XHSNotificationWarning");
		} else if (severity === "success") {
			toast.AddClass("XHSNotificationSuccess");
		}

		if (msg.rewardType) {
			toast.AddClass("XHSNotificationReward");
			if (msg.rewardType === "gold") {
				toast.AddClass("XHSNotificationGoldReward");
			} else if (msg.rewardType === "stats") {
				toast.AddClass("XHSNotificationStatsReward");
			}
		}

		var body = $.CreatePanel("Panel", toast, "");
		body.AddClass("XHSNotificationBody");
		body.hittest = false;

		var accent = $.CreatePanel("Panel", body, "");
		accent.AddClass("XHSNotificationAccent");
		accent.hittest = false;

		var content = $.CreatePanel("Panel", body, "");
		content.AddClass("XHSNotificationContent");
		content.hittest = false;
		toast.contentPanel = content;

		var track = $.CreatePanel("Panel", toast, "");
		track.AddClass("XHSNotificationProgressTrack");
		track.hittest = false;

		var progress = $.CreatePanel("Panel", track, "");
		progress.AddClass("XHSNotificationProgress");
		progress.hittest = false;
		toast.progressPanel = progress;

		return toast;
	}

	function addSegment(toast, msg) {
		var content = toast.contentPanel || toast;
		var segment = null;

		if (msg.hero != null) {
			segment = $.CreatePanel("DOTAHeroImage", content, "");
			segment.heroimagestyle = msg.imagestyle || "icon";
			segment.heroname = msg.hero;
			segment.AddClass("XHSNotificationImage");
		} else if (msg.image != null) {
			segment = $.CreatePanel("Image", content, "");
			segment.SetImage(msg.image);
			segment.AddClass("XHSNotificationImage");
		} else if (msg.ability != null) {
			segment = $.CreatePanel("DOTAAbilityImage", content, "");
			segment.abilityname = msg.ability;
			segment.AddClass("XHSNotificationImage");
		} else if (msg.item != null) {
			segment = $.CreatePanel("DOTAItemImage", content, "");
			segment.itemname = msg.item;
			segment.AddClass("XHSNotificationImage");
		} else {
			segment = $.CreatePanel("Label", content, "");
			segment.html = true;
			segment.text = localizeText(msg.text);
			segment.AddClass("XHSNotificationMessage");
			segment.AddClass("TitleText");
		}

		segment.hittest = false;

		if (msg.class) {
			segment.AddClass(msg.class);
		}

		applyStyle(segment, msg.style);
	}

	function startProgress(toast, duration) {
		if (!toast.progressPanel) {
			return;
		}

		toast.progressPanel.style.width = "100%";
		toast.progressPanel.style.transitionDuration = duration + "s";

		$.Schedule(0.03, function () {
			if (!toast || toast.deleted) {
				return;
			}

			toast.progressPanel.style.width = "0%";
		});
	}

	function closeToast(toast) {
		if (!toast || toast.deleted) {
			return;
		}

		toast.deleted = true;
		toast.AddClass("XHSNotificationClosing");
		toast.DeleteAsync(0.28);
	}

	function trimStack(container) {
		var removeCount = container.GetChildCount() - MAX_NOTIFICATIONS;
		for (var i = 0; i < removeCount; i++) {
			closeToast(container.GetChild(i));
		}
	}

	function addNotification(msg, container, lane) {
		if (!container) {
			return null;
		}

		msg = msg || {};
		var lastNotification = lane === "top" ? lastTopNotification : lastBottomNotification;
		var usePrevious = isContinuation(msg) && lastNotification && !lastNotification.deleted;

		if (!usePrevious) {
			lastNotification = createToast(container, lane, msg);
			var duration = getDuration(msg);
			startProgress(lastNotification, duration);
			$.Schedule(duration, function () {
				closeToast(lastNotification);
			});

			if (lane === "top") {
				lastTopNotification = lastNotification;
			} else {
				lastBottomNotification = lastNotification;
			}

			trimStack(container);
		}

		addSegment(lastNotification, msg);
		return lastNotification;
	}

	function playRewardFlyout(toast, msg) {
		if (!toast || toast.deleted) {
			return;
		}

		var type = msg.rewardType || "gold";
		var target = getRewardTarget(type);
		if (!target) {
			return;
		}

		var flyoutText = msg.flyoutText || msg.text || "";
		var root = $.GetContextPanel();
		var flyout = $.CreatePanel("Panel", root, "");
		flyout.AddClass("XHSRewardFlyout");
		flyout.SetHasClass("XHSRewardFlyoutGold", type === "gold");
		flyout.SetHasClass("XHSRewardFlyoutStats", type === "stats");
		flyout.hittest = false;

		var label = $.CreatePanel("Label", flyout, "");
		label.text = flyoutText;
		label.hittest = false;

		$.Schedule(0.03, function () {
			var start = getPanelCenter(toast);
			var end = getPanelCenter(target);
			if (!start || !end) {
				flyout.DeleteAsync(0);
				return;
			}

			var flyoutWidth = Number(flyout.actuallayoutwidth || 136);
			var flyoutHeight = Number(flyout.actuallayoutheight || 34);
			var deltaX = Math.round(end.x - start.x);
			var deltaY = Math.round(end.y - start.y);

			flyout.style.marginLeft = Math.round(start.x - flyoutWidth * 0.5) + "px";
			flyout.style.marginTop = Math.round(start.y - flyoutHeight * 0.5) + "px";

			$.Schedule(0.03, function () {
				flyout.AddClass("XHSRewardFlyoutFlying");
				flyout.style.transform = "translateX(" + deltaX + "px) translateY(" + deltaY + "px) scaleX(0.35) scaleY(0.35)";
			});

			$.Schedule(0.54, function () {
				target.AddClass("XHSRewardTargetPulse");
			});

			$.Schedule(0.9, function () {
				target.RemoveClass("XHSRewardTargetPulse");
				flyout.DeleteAsync(0);
			});
		});
	}

	function showRewardNotification(msg) {
		msg = msg || {};

		var type = String(msg.type || msg.rewardType || "gold").toLowerCase();
		var amount = Number(msg.amount || 0);
		var title = msg.title || (type === "stats" ? "Stats Granted" : "Gold Gained");
		var rewardText = msg.text;

		if (!rewardText) {
			rewardText = type === "stats"
				? "+" + formatRewardNumber(amount) + " all stats"
				: "+" + formatRewardNumber(amount) + " gold";
		}

		var duration = getDuration(msg);
		var toast = addNotification({
			text: title + ": " + rewardText,
			duration: duration,
			severity: "success",
			rewardType: type,
			class: "XHSRewardMessage"
		}, $(BOTTOM_CONTAINER_ID), "bottom");

		if (!toast) {
			return;
		}

		var flyoutDelay = Math.max(0.45, duration - 0.78);
		$.Schedule(flyoutDelay, function () {
			playRewardFlyout(toast, {
				rewardType: type,
				text: rewardText,
				flyoutText: rewardText
			});
		});
	}

	function removeNotification(msg, container) {
		var count = msg && msg.count ? msg.count : 0;
		if (count <= 0 || !container || container.GetChildCount() <= 0) {
			return;
		}

		var start = container.GetChildCount() - count;
		if (start < 0) {
			start = 0;
		}

		for (var i = start; i < container.GetChildCount(); i++) {
			closeToast(container.GetChild(i));
		}
	}

	function topNotification(msg) {
		var waveWarning = getWaveWarningInfo(msg);
		if (waveWarning) {
			showWaveTimer({
				duration: Math.max(1, Math.round(getDuration(msg))),
				eyebrow: "WAVE INCOMING",
				title: "Wave of Darkness",
				subtitle: waveWarning.direction + " lane"
			});
			return;
		}

		if (isCoveredTimerWarning(msg)) {
			return;
		}

		addNotification(msg, $(TOP_CONTAINER_ID), "top");
	}

	function bottomNotification(msg) {
		addNotification(msg, $(BOTTOM_CONTAINER_ID), "bottom");
	}

	function topRemoveNotification(msg) {
		removeNotification(msg, $(TOP_CONTAINER_ID));
	}

	function bottomRemoveNotification(msg) {
		removeNotification(msg, $(BOTTOM_CONTAINER_ID));
	}

	function setWaveVisible(visible) {
		var panel = $(WAVE_PANEL_ID);
		if (!panel) {
			return;
		}

		panel.SetHasClass("XHSNotificationHidden", !visible);
	}

	function updateWaveCountdown(remaining) {
		var label = $("#XHSWaveCountdownValue");
		if (label) {
			label.text = String(Math.max(0, remaining));
		}
	}

	function tickWaveCountdown(remaining) {
		updateWaveCountdown(remaining);

		if (remaining <= 0) {
			activeWaveSchedule = $.Schedule(0.35, function () {
				setWaveVisible(false);
			});
			return;
		}

		activeWaveSchedule = $.Schedule(1.0, function () {
			tickWaveCountdown(remaining - 1);
		});
	}

	function showWaveTimer(msg) {
		msg = msg || {};

		var title = $("#XHSWaveTitle");
		var subtitle = $("#XHSWaveSubtitle");
		var eyebrow = $("#XHSWaveEyebrow");
		var duration = typeof msg.duration === "number" ? msg.duration : 30;

		if (eyebrow) {
			eyebrow.text = msg.eyebrow || "WAVE INCOMING";
		}

		if (title) {
			title.text = msg.title || "Wave of Darkness";
		}

		if (subtitle) {
			subtitle.text = msg.subtitle || "Prepare your lane";
		}

		cancelWaveSchedule();

		setWaveVisible(true);
		tickWaveCountdown(duration);
	}

	GameEvents.Subscribe("top_notification", topNotification);
	GameEvents.Subscribe("bottom_notification", bottomNotification);
	GameEvents.Subscribe("top_remove_notification", topRemoveNotification);
	GameEvents.Subscribe("bottom_remove_notification", bottomRemoveNotification);
	GameEvents.Subscribe("xhs_wave_timer", showWaveTimer);
	GameEvents.Subscribe("xhs_reward_notification", showRewardNotification);
})();
