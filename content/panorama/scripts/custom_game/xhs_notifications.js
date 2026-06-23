(function () {
	var TOP_CONTAINER_ID = "#XHSTopNotifications";
	var BOTTOM_CONTAINER_ID = "#XHSBottomNotifications";
	var WAVE_PANEL_ID = "#XHSWaveCountdown";
	var MAX_NOTIFICATIONS = 4;
	var activeWaveSchedule = null;
	var activeWaveTimerName = null;
	var activeWaveDuration = 30;
	var activeWaveMode = null;
	var activeRuneRemaining = 0;

	function getDuration(msg) {
		if (typeof msg.duration === "number" && msg.duration > 0) {
			return msg.duration;
		}

		return 3;
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

	function formatGoldRewardText(amount, text) {
		if (text) {
			return String(text).replace(/^\s*\+\s*/, "");
		}

		return formatRewardNumber(amount) + " gold";
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

	function getTimerSeconds(msg) {
		var minute10 = Number(msg.timer_minute_10 || 0);
		var minute01 = Number(msg.timer_minute_01 || 0);
		var second10 = Number(msg.timer_second_10 || 0);
		var second01 = Number(msg.timer_second_01 || 0);

		return ((minute10 * 10 + minute01) * 60) + (second10 * 10 + second01);
	}

	function isTruthy(value) {
		return value === true || value === 1 || value === "1";
	}

	function formatWaveTime(seconds) {
		seconds = Math.max(0, Math.floor(Number(seconds) || 0));
		if (seconds >= 60) {
			var minutes = Math.floor(seconds / 60);
			var remainder = seconds - (minutes * 60);
			return minutes + ":" + ("0" + remainder).slice(-2);
		}

		return String(seconds);
	}

	function getWaveDirectionLabel(direction) {
		direction = String(direction || "").toUpperCase();
		return direction ? direction + " lane" : "Preparing";
	}

	function applyStyle(panel, style) {
		if (!style) {
			return;
		}

		for (var key in style) {
			panel.style[key] = style[key];
		}
	}

	function getSegmentCount(msg) {
		var segments = msg && msg.segments;
		if (!segments) {
			return 0;
		}

		if (typeof segments.length === "number") {
			return segments.length;
		}

		var count = 0;
		for (var key in segments) {
			var index = Number(key);
			if (index > 0 && Math.floor(index) === index) {
				count++;
			}
		}

		return count;
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

		if (getSegmentCount(msg) > 1) {
			toast.AddClass("XHSNotificationCompound");
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

	function addSegments(toast, msg) {
		var segments = msg && msg.segments;
		if (!segments) {
			toast.AddClass("XHSNotificationSingleMessage");
			addSegment(toast, msg);
			return;
		}

		var added = false;

		if (typeof segments.length === "number") {
			for (var i = 0; i < segments.length; i++) {
				if (segments[i]) {
					addSegment(toast, segments[i]);
					added = true;
				}
			}
		}

		if (added) {
			return;
		}

		var orderedSegments = [];
		for (var key in segments) {
			var index = Number(key);
			if (index > 0 && Math.floor(index) === index) {
				orderedSegments[index] = segments[key];
			}
		}

		for (var j = 1; j < orderedSegments.length; j++) {
			if (orderedSegments[j]) {
				addSegment(toast, orderedSegments[j]);
				added = true;
			}
		}

		if (!added) {
			addSegment(toast, msg);
		}
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
		var notification = createToast(container, lane, msg);
		var duration = getDuration(msg);
		startProgress(notification, duration);
		$.Schedule(duration, function () {
			closeToast(notification);
		});

		trimStack(container);
		addSegments(notification, msg);
		return notification;
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
				: formatGoldRewardText(amount);
		} else if (type === "gold") {
			rewardText = formatGoldRewardText(amount, rewardText);
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
				flyoutText: type === "gold" ? formatRewardNumber(amount) : rewardText
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

	function setWaveMode(mode) {
		var panel = $(WAVE_PANEL_ID);
		if (!panel) {
			return;
		}

		activeWaveMode = mode || null;
		panel.SetHasClass("XHSWaveCompact", mode === "compact");
		panel.SetHasClass("XHSWaveWarning", mode === "warning");
		panel.SetHasClass("XHSWaveActive", mode === "active");
		panel.SetHasClass("XHSWaveCleared", mode === "cleared");
	}

	function updateWaveCountdown(remaining) {
		var panel = $(WAVE_PANEL_ID);
		var label = $("#XHSWaveCountdownValue");
		var fill = $("#XHSWaveRingFill");
		var duration = Math.max(1, activeWaveDuration || 30);
		var ratio = Math.max(0, Math.min(1, remaining / duration));

		if (label) {
			label.text = activeWaveMode === "compact" ? formatWaveTime(remaining) : String(Math.max(0, remaining));
		}

		if (fill) {
			fill.style.transform = "scaleX(" + ratio + ") scaleY(" + ratio + ")";
			fill.style.opacity = String(Math.max(0.18, ratio));
		}

		if (panel) {
			panel.SetHasClass("XHSWaveArrived", remaining <= 0);
		}
	}

	function hideWavePanel() {
		setWaveVisible(false);
		activeWaveTimerName = null;
		setWaveMode(null);
	}

	function showWaveCompact(msg, remaining) {
		msg = msg || {};

		var title = $("#XHSWaveTitle");
		var subtitle = $("#XHSWaveSubtitle");
		var eyebrow = $("#XHSWaveEyebrow");
		var interval = Math.max(remaining, Number(msg.wave_interval || activeWaveDuration || remaining || 1));

		cancelWaveSchedule();
		activeWaveTimerName = "special_wave";
		activeWaveDuration = interval;
		setWaveMode("compact");

		var panel = $(WAVE_PANEL_ID);
		if (panel) {
			panel.SetHasClass("XHSWaveArrived", false);
		}

		if (eyebrow) {
			eyebrow.text = "NEXT WAVE";
		}

		if (title) {
			title.text = "Wave of Darkness";
		}

		if (subtitle) {
			subtitle.text = getWaveDirectionLabel(msg.direction);
		}

		setWaveVisible(true);
		updateWaveCountdown(remaining);
	}

	function countdownTimer(msg) {
		if (msg && msg.timer_name === "special_wave" && activeWaveMode !== "warning" && activeWaveMode !== "active" && activeWaveMode !== "cleared") {
			var compactRemaining = getTimerSeconds(msg);
			if (isTruthy(msg.show_compact) && compactRemaining > 30) {
				showWaveCompact(msg, compactRemaining);
				return;
			}

			if (activeWaveMode === "compact") {
				hideWavePanel();
			}
		}

		if (!activeWaveTimerName || !msg || msg.timer_name !== activeWaveTimerName) {
			return;
		}

		var remaining = getTimerSeconds(msg);
		updateWaveCountdown(remaining);

		cancelWaveSchedule();
		if (remaining <= 0) {
			if (activeWaveTimerName === "special_wave") {
				var eyebrow = $("#XHSWaveEyebrow");
				var subtitle = $("#XHSWaveSubtitle");

				if (eyebrow) {
					eyebrow.text = "WAVE SPAWNED";
				}

				if (subtitle) {
					subtitle.text = "Clear the attackers";
				}
			} else {
				activeWaveSchedule = $.Schedule(0.35, function () {
					hideWavePanel();
					activeWaveSchedule = null;
				});
			}
		}
	}

	function showWaveTimer(msg) {
		msg = msg || {};

		var title = $("#XHSWaveTitle");
		var subtitle = $("#XHSWaveSubtitle");
		var eyebrow = $("#XHSWaveEyebrow");
		var duration = typeof msg.duration === "number" ? msg.duration : 30;
		activeWaveTimerName = msg.timer_name || null;
		activeWaveDuration = duration;

		var panel = $(WAVE_PANEL_ID);
		if (panel) {
			panel.SetHasClass("XHSWaveArrived", false);
		}
		setWaveMode("warning");

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
		updateWaveCountdown(duration);

		if (!activeWaveTimerName) {
			activeWaveSchedule = $.Schedule(duration, function () {
				hideWavePanel();
				activeWaveSchedule = null;
			});
		}
	}

	function showWaveActive(msg) {
		msg = msg || {};
		var panel = $(WAVE_PANEL_ID);
		var title = $("#XHSWaveTitle");
		var subtitle = $("#XHSWaveSubtitle");
		var eyebrow = $("#XHSWaveEyebrow");
		var label = $("#XHSWaveCountdownValue");
		var fill = $("#XHSWaveRingFill");
		var total = Math.max(1, Number(msg.total || 10));
		var remaining = Math.max(0, Number(msg.remaining || 0));
		var killed = Math.max(0, total - remaining);
		var direction = String(msg.direction || "").toUpperCase();

		cancelWaveSchedule();
		activeWaveTimerName = null;

		if (panel) {
			panel.SetHasClass("XHSWaveArrived", false);
		}
		setWaveMode(remaining > 0 ? "active" : "cleared");

		if (eyebrow) {
			eyebrow.text = remaining > 0 ? "WAVE ACTIVE" : "WAVE CLEARED";
		}

		if (title) {
			title.text = "Wave of Darkness";
		}

		if (subtitle) {
			subtitle.text = remaining > 0
				? (direction ? direction + " lane - " : "") + killed + "/" + total + " killed"
				: "All attackers defeated";
		}

		if (label) {
			label.text = String(remaining);
		}

		if (fill) {
			var ratio = remaining / total;
			fill.style.transform = "scaleX(" + ratio + ") scaleY(" + ratio + ")";
			fill.style.opacity = remaining > 0 ? "1" : ".42";
		}

		setWaveVisible(true);

		if (remaining <= 0) {
			activeWaveSchedule = $.Schedule(2.4, function () {
				hideWavePanel();
				activeWaveSchedule = null;
			});
		}
	}

	function showWaveCleared(msg) {
		msg = msg || {};
		msg.remaining = 0;
		showWaveActive(msg);
	}

	function hideWaveTimer() {
		hideWavePanel();
	}

	function clearRuneClasses(panel) {
		if (!panel) {
			return;
		}

		var classes = [
			"XHSRuneRecovery",
			"XHSRuneDefense",
			"XHSRuneOffense",
			"XHSRuneMisc",
			"XHSRunePicked",
			"XHSRuneExpired"
		];

		for (var i = 0; i < classes.length; i++) {
			panel.SetHasClass(classes[i], false);
		}
	}

	function setRuneVisible(visible) {
		var panel = $("#XHSRuneIndicator");
		if (panel) {
			panel.SetHasClass("XHSRuneHidden", !visible);
		}
	}

	function getRuneCategoryClass(category) {
		category = String(category || "").toLowerCase();
		if (category === "recovery") {
			return "XHSRuneRecovery";
		}
		if (category === "defense") {
			return "XHSRuneDefense";
		}
		if (category === "offense") {
			return "XHSRuneOffense";
		}
		return "XHSRuneMisc";
	}

	function formatRuneDirection(direction) {
		direction = String(direction || "");
		if (!direction) {
			return "rune point";
		}

		return direction.toUpperCase() + " lane";
	}

	function updateRuneState(msg) {
		msg = msg || {};

		var panel = $("#XHSRuneIndicator");
		if (!panel) {
			return;
		}

		var eyebrow = $("#XHSRuneEyebrow");
		var name = $("#XHSRuneName");
		var detail = $("#XHSRuneDetail");
		var time = $("#XHSRuneTime");
		var state = String(msg.state || "spawned");
		var category = String(msg.category || "Misc");

		clearRuneClasses(panel);
		panel.AddClass(getRuneCategoryClass(category));
		panel.SetHasClass("XHSRunePicked", state === "picked");
		panel.SetHasClass("XHSRuneExpired", state === "expired");

		if (eyebrow) {
			eyebrow.text = state === "picked" ? "RUNE CLAIMED" : (state === "expired" ? "RUNE EXPIRED" : category.toUpperCase() + " RUNE");
		}

		if (name) {
			name.text = msg.name || "Rune";
		}

		if (detail) {
			if (state === "picked") {
				detail.text = msg.picker_hero_name ? msg.picker_hero_name + " picked it up" : "Picked up";
			} else if (state === "expired") {
				detail.text = "No hero reached it in time";
			} else {
				detail.text = formatRuneDirection(msg.direction);
			}
		}

		activeRuneRemaining = Number(msg.remaining);
		if (time) {
			time.text = state === "spawned" && activeRuneRemaining >= 0 ? String(Math.max(0, activeRuneRemaining)) : "";
		}

		setRuneVisible(true);

		if (state !== "spawned") {
			$.Schedule(4.0, function () {
				setRuneVisible(false);
			});
		}
	}

	function showMainQuestCompleted(msg) {
		var container = $(TOP_CONTAINER_ID);
		if (!container) {
			return;
		}

		msg = msg || {};
		var toast = createToast(container, "top", {
			duration: msg.duration || 6.5,
			severity: "success"
		});
		toast.AddClass("XHSNotificationMainQuest");

		var content = toast.contentPanel || toast;
		content.RemoveAndDeleteChildren();

		var eyebrow = $.CreatePanel("Label", content, "");
		eyebrow.AddClass("XHSMainQuestEyebrow");
		eyebrow.text = msg.phase || "MAIN QUEST";
		eyebrow.hittest = false;

		var title = $.CreatePanel("Label", content, "");
		title.AddClass("XHSMainQuestTitle");
		title.text = msg.title || "Objective Complete";
		title.hittest = false;

		var subtitle = $.CreatePanel("Label", content, "");
		subtitle.AddClass("XHSMainQuestSubtitle");
		subtitle.text = msg.subtitle || "";
		subtitle.hittest = false;

		var duration = getDuration({ duration: msg.duration || 6.5 });
		startProgress(toast, duration);
		$.Schedule(duration, function () {
			closeToast(toast);
		});

		trimStack(container);

		if (msg.sound) {
			Game.EmitSound(msg.sound);
		}
	}

	GameEvents.Subscribe("top_notification", topNotification);
	GameEvents.Subscribe("bottom_notification", bottomNotification);
	GameEvents.Subscribe("top_remove_notification", topRemoveNotification);
	GameEvents.Subscribe("bottom_remove_notification", bottomRemoveNotification);
	GameEvents.Subscribe("countdown_timer", countdownTimer);
	GameEvents.Subscribe("xhs_wave_timer", showWaveTimer);
	GameEvents.Subscribe("xhs_wave_active", showWaveActive);
	GameEvents.Subscribe("xhs_wave_cleared", showWaveCleared);
	GameEvents.Subscribe("xhs_wave_hide", hideWaveTimer);
	GameEvents.Subscribe("xhs_rune_state_update", updateRuneState);
	GameEvents.Subscribe("xhs_main_quest_completed", showMainQuestCompleted);
	GameEvents.Subscribe("xhs_reward_notification", showRewardNotification);
})();
