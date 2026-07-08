(function () {
	var TOP_CONTAINER_ID = "#XHSTopNotifications";
	var BOTTOM_CONTAINER_ID = "#XHSBottomNotifications";
	var WAVE_PANEL_ID = "#XHSWaveCountdown";
	var MAX_NOTIFICATIONS = 4;
	var activeWaveSchedule = null;
	var activeWaveTimerName = null;
	var activeWaveDuration = 30;
	var activeWaveMode = null;
	var WAVE_RING_COUNTDOWN_SECONDS = 30;
	var activeRuneRemaining = 0;
	var activeRuneBatchId = null;
	var activeRuneVersion = 0;
	var activeRuneCompactSchedule = null;
	var activeRuneHideSchedule = null;
	var fragmentQuestNotificationQueue = [];
	var fragmentQuestNotificationActive = false;
	var FRAGMENT_QUEST_QUEUE_GAP = 0.35;

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
			var shopButton = findHudElement("ShopButton");
			if (shopButton) {
				var goldLabel = shopButton.FindChildTraverse("GoldLabel");
				if (goldLabel) {
					return goldLabel;
				}

				return shopButton;
			}

			return findFirstHudElement(["GoldLabel", "ShopButton"]);
		}

		if (type === "stats") {
			return findFirstHudElement(["stats", "stats_container", "stats_tooltip_region", "stragiint"]);
		}

		return null;
	}

	function getRewardFlyoutLayer() {
		return $("#XHSRewardFlyoutLayer") || $("#XHSNotificationsRoot") || $.GetContextPanel();
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

	function getPanelTopLeft(panel) {
		if (!panel) {
			return { x: 0, y: 0 };
		}

		if (panel.GetPositionWithinWindow) {
			var position = panel.GetPositionWithinWindow();
			if (position) {
				return {
					x: Number(position.x || position[0] || 0),
					y: Number(position.y || position[1] || 0)
				};
			}
		}

		return {
			x: Number(panel.actualxoffset || 0),
			y: Number(panel.actualyoffset || 0)
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

	function cancelRuneSchedule(schedule) {
		if (schedule === null) {
			return null;
		}

		if (typeof $.CancelScheduled === "function") {
			$.CancelScheduled(schedule);
		} else if (schedule.Cancel) {
			schedule.Cancel();
		}

		return null;
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
		var root = getRewardFlyoutLayer();
		var flyout = $.CreatePanel("Panel", root, "");
		flyout.AddClass("XHSRewardFlyout");
		flyout.SetHasClass("XHSRewardFlyoutGold", type === "gold");
		flyout.SetHasClass("XHSRewardFlyoutStats", type === "stats");
		flyout.hittest = false;

		var label = $.CreatePanel("Label", flyout, "");
		label.text = flyoutText;
		label.hittest = false;

		function createRewardImpact(center) {
			var impact = $.CreatePanel("Panel", root, "");
			impact.AddClass("XHSRewardImpact");
			impact.SetHasClass("XHSRewardImpactGold", type === "gold");
			impact.SetHasClass("XHSRewardImpactStats", type === "stats");
			impact.hittest = false;
			var rootOrigin = getPanelTopLeft(root);
			impact.style.marginLeft = Math.round(center.x - rootOrigin.x - 26) + "px";
			impact.style.marginTop = Math.round(center.y - rootOrigin.y - 26) + "px";

			$.Schedule(0.03, function () {
				if (!impact || impact.deleted) {
					return;
				}
				impact.AddClass("XHSRewardImpactActive");
			});

			impact.DeleteAsync(0.58);
		}

		$.Schedule(0.03, function () {
			var start = getPanelCenter(toast);
			var end = getPanelCenter(target);
			if (!start || !end) {
				flyout.DeleteAsync(0);
				return;
			}

			var rootOrigin = getPanelTopLeft(root);
			var localStartX = start.x - rootOrigin.x;
			var localStartY = start.y - rootOrigin.y;
			var flyoutWidth = Number(flyout.actuallayoutwidth || 136);
			var flyoutHeight = Number(flyout.actuallayoutheight || 34);
			var finalScale = 0.42;
			var deltaX = Math.round(end.x - start.x);
			var deltaY = Math.round(end.y - start.y);

			flyout.style.marginLeft = Math.round(localStartX - flyoutWidth * 0.5) + "px";
			flyout.style.marginTop = Math.round(localStartY - flyoutHeight * 0.5) + "px";

			$.Schedule(0.03, function () {
				flyout.AddClass("XHSRewardFlyoutFlying");
				flyout.style.transform = "translateX(" + deltaX + "px) translateY(" + deltaY + "px)";
				flyout.style.preTransformScale2d = finalScale + ", " + finalScale;
			});

			$.Schedule(0.76, function () {
				flyout.AddClass("XHSRewardFlyoutArrived");
				target.AddClass("XHSRewardTargetPulse");
				createRewardImpact(end);
			});

			$.Schedule(0.84, function () {
				flyout.AddClass("XHSRewardFlyoutConsumed");
			});

			$.Schedule(1.08, function () {
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

	function updateWaveRingProgress(ratio) {
		var sweep = $("#XHSWaveRingSweep");
		if (!sweep) {
			return;
		}

		ratio = Math.max(0, Math.min(1, Number(ratio) || 0));
		sweep.style.clip = "radial(50% 50%, 0.0deg, " + (ratio * -360).toFixed(2) + "deg)";
		sweep.style.opacity = ratio > 0 ? String(Math.max(0.72, ratio)) : "0";
		sweep.SetHasClass("XHSWaveRingSweepWarning", ratio > 0 && ratio <= 0.25);
	}

	function updateWaveCountdown(remaining) {
		var panel = $(WAVE_PANEL_ID);
		var label = $("#XHSWaveCountdownValue");
		var fill = $("#XHSWaveRingFill");
		var ringRatio = Math.max(0, Math.min(1, Math.min(remaining, WAVE_RING_COUNTDOWN_SECONDS) / WAVE_RING_COUNTDOWN_SECONDS));

		if (label) {
			label.text = activeWaveMode === "compact" ? formatWaveTime(remaining) : String(Math.max(0, remaining));
		}

		if (fill) {
			fill.style.transform = "scaleX(1) scaleY(1)";
			fill.style.opacity = remaining > 0 ? ".68" : ".32";
		}

		updateWaveRingProgress(ringRatio);

		if (panel) {
			panel.SetHasClass("XHSWaveArrived", remaining <= 0);
		}
	}

	function hideWavePanel() {
		setWaveVisible(false);
		activeWaveTimerName = null;
		setWaveMode(null);
		updateWaveRingProgress(1);
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

		if (msg.timer_name === "special_wave" && (activeWaveMode === "active" || activeWaveMode === "cleared")) {
			if (msg.sound) {
				Game.EmitSound(msg.sound);
			}
			return;
		}

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

		if (msg.sound) {
			Game.EmitSound(msg.sound);
		}

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
			fill.style.transform = "scaleX(1) scaleY(1)";
			fill.style.opacity = remaining > 0 ? "1" : ".42";
		}
		updateWaveRingProgress(remaining > 0 ? remaining / total : 0);

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

	function setRuneCompact(compact) {
		var panel = $("#XHSRuneIndicator");
		if (panel) {
			panel.SetHasClass("XHSRuneCompact", compact);
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

	function clampRuneNumber(value, min, max) {
		value = Number(value);
		if (isNaN(value)) {
			value = min;
		}

		return Math.max(min, Math.min(max, Math.floor(value)));
	}

	function getRuneTotal(msg) {
		var total = Number(msg.rune_total);
		if (isNaN(total) || total <= 0) {
			total = Number(msg.rune_count);
		}
		if (isNaN(total) || total <= 0) {
			total = 1;
		}

		return clampRuneNumber(total, 1, 4);
	}

	function getRuneRemaining(msg, total) {
		var remaining = Number(msg.rune_remaining);
		if (isNaN(remaining)) {
			remaining = Number(msg.rune_count);
		}
		if (isNaN(remaining)) {
			remaining = total;
		}

		return clampRuneNumber(remaining, 0, total);
	}

	function formatRuneHeroName(heroName) {
		heroName = String(heroName || "");
		if (!heroName) {
			return "A hero";
		}

		var localized = $.Localize("#" + heroName);
		if (localized && localized !== "#" + heroName) {
			return localized;
		}

		return heroName;
	}

	function updateRunePips(remaining, total) {
		for (var i = 0; i < 4; i++) {
			var pip = $("#XHSRunePip" + i);
			if (!pip) {
				continue;
			}

			var visible = i < total;
			pip.SetHasClass("XHSRunePipVisible", visible);
			pip.SetHasClass("XHSRunePipClaimed", visible && i < total - remaining);
			pip.SetHasClass("XHSRunePipRemaining", visible && i >= total - remaining);
		}
	}

	function scheduleRuneCompact(version, delay) {
		activeRuneCompactSchedule = cancelRuneSchedule(activeRuneCompactSchedule);
		activeRuneCompactSchedule = $.Schedule(delay, function () {
			if (version === activeRuneVersion) {
				setRuneCompact(true);
			}
			activeRuneCompactSchedule = null;
		});
	}

	function scheduleRuneHide(version, delay) {
		activeRuneHideSchedule = cancelRuneSchedule(activeRuneHideSchedule);
		activeRuneHideSchedule = $.Schedule(delay, function () {
			if (version === activeRuneVersion) {
				setRuneVisible(false);
			}
			activeRuneHideSchedule = null;
		});
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
		var count = $("#XHSRuneCount");
		var state = String(msg.state || "spawned");
		var category = String(msg.category || "Misc");
		var total = getRuneTotal(msg);
		var remaining = getRuneRemaining(msg, total);
		var batchId = Number(msg.batch_id || msg.wave_index || 0);
		var isNewBatch = batchId !== activeRuneBatchId;

		activeRuneBatchId = batchId;
		activeRuneVersion += 1;
		activeRuneCompactSchedule = cancelRuneSchedule(activeRuneCompactSchedule);
		activeRuneHideSchedule = cancelRuneSchedule(activeRuneHideSchedule);

		clearRuneClasses(panel);
		panel.AddClass(getRuneCategoryClass(category));
		panel.SetHasClass("XHSRunePicked", state === "picked");
		panel.SetHasClass("XHSRuneExpired", state === "expired");
		setRuneCompact(false);

		if (eyebrow) {
			if (state === "picked") {
				eyebrow.text = remaining > 0 ? "RUNE CLAIMED" : "ALL RUNES CLAIMED";
			} else if (state === "expired" || state === "removed") {
				eyebrow.text = "RUNE LOST";
			} else {
				eyebrow.text = total > 1 ? category.toUpperCase() + " RUNES" : category.toUpperCase() + " RUNE";
			}
		}

		if (name) {
			name.text = msg.name || (total > 1 ? "Runes" : "Rune");
		}

		if (detail) {
			if (state === "picked") {
				if (remaining > 0) {
					detail.text = formatRuneHeroName(msg.picker_hero_name) + " claimed one - " + String(remaining) + " remaining";
				} else {
					detail.text = formatRuneHeroName(msg.picker_hero_name) + " claimed the last rune";
				}
			} else if (state === "expired" || state === "removed") {
				detail.text = remaining > 0 ? String(remaining) + " remaining when it faded" : "No runes remaining";
			} else {
				detail.text = formatRuneDirection(msg.direction) + " - " + String(remaining) + " remaining";
			}
		}

		activeRuneRemaining = remaining;
		if (count) {
			count.text = String(remaining) + "/" + String(total);
		}
		updateRunePips(remaining, total);

		setRuneVisible(true);

		var version = activeRuneVersion;
		if (state === "spawned") {
			scheduleRuneCompact(version, isNewBatch ? 4.5 : 1.8);
		} else if (remaining > 0) {
			scheduleRuneCompact(version, 3.0);
		} else {
			scheduleRuneHide(version, 4.0);
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

	function getFragmentQuestStars(msg) {
		return Math.max(0, Math.min(3, Math.floor(Number(msg && msg.stars) || 0)));
	}

	function getFragmentQuestPreviousStars(msg) {
		return Math.max(0, Math.min(3, Math.floor(Number(msg && msg.previous_stars) || 0)));
	}

	function addFragmentQuestToastStars(parent, stars, previousStars) {
		for (var i = 1; i <= 3; i++) {
			var star = $.CreatePanel("Panel", parent, "");
			star.AddClass("XHSFragmentQuestToastStar");
			star.SetHasClass("IsActive", i <= stars);
			star.SetHasClass("IsNew", i > previousStars && i <= stars);
			star.hittest = false;
		}
	}

	function renderFragmentQuestStarToast(msg, onDone) {
		var container = $(TOP_CONTAINER_ID);
		if (!container) {
			if (onDone) {
				$.Schedule(FRAGMENT_QUEST_QUEUE_GAP, onDone);
			}
			return;
		}

		msg = msg || {};
		var stars = getFragmentQuestStars(msg);
		var previousStars = getFragmentQuestPreviousStars(msg);
		var duration = getDuration({ duration: msg.duration || 5.4 });
		var toast = createToast(container, "top", {
			duration: duration,
			severity: "success"
		});
		toast.AddClass("XHSNotificationFragmentQuest");

		var content = toast.contentPanel || toast;
		content.RemoveAndDeleteChildren();

		var header = $.CreatePanel("Panel", content, "");
		header.AddClass("XHSFragmentQuestToastHeader");
		header.hittest = false;

		var copy = $.CreatePanel("Panel", header, "");
		copy.AddClass("XHSFragmentQuestToastCopy");
		copy.hittest = false;

		var eyebrow = $.CreatePanel("Label", copy, "");
		eyebrow.AddClass("XHSFragmentQuestToastEyebrow");
		eyebrow.text = "FRAGMENT QUEST";
		eyebrow.hittest = false;

		var title = $.CreatePanel("Label", copy, "");
		title.AddClass("XHSFragmentQuestToastTitle");
		title.text = msg.title || "Fragment Quest";
		title.hittest = false;

		var starsPanel = $.CreatePanel("Panel", header, "");
		starsPanel.AddClass("XHSFragmentQuestToastStars");
		starsPanel.hittest = false;
		addFragmentQuestToastStars(starsPanel, stars, previousStars);

		var subtitle = $.CreatePanel("Label", content, "");
		subtitle.AddClass("XHSFragmentQuestToastSubtitle");
		subtitle.text = stars + "/3 stars reached" + (msg.progress_text ? " - " + msg.progress_text : "");
		subtitle.hittest = false;

		var details = $.CreatePanel("Panel", content, "");
		details.AddClass("XHSFragmentQuestToastDetails");
		details.hittest = false;

		var threshold = $.CreatePanel("Label", details, "");
		threshold.AddClass("XHSFragmentQuestToastThreshold");
		threshold.text = msg.threshold_text || msg.description || "";
		threshold.hittest = false;

		var fragments = Number(msg.fragments_preview || msg.preview_fragments || 0);
		if (fragments <= 0 && msg.reward_per_star !== undefined) {
			fragments = Number(msg.reward_per_star || 0) * stars;
		}

		var reward = $.CreatePanel("Label", details, "");
		reward.AddClass("XHSFragmentQuestToastReward");
		reward.text = fragments > 0 ? "+" + formatRewardNumber(fragments) + " fragments earned" : "Fragments earned";
		reward.hittest = false;

		startProgress(toast, duration);
		$.Schedule(duration, function () {
			closeToast(toast);
			if (onDone) {
				$.Schedule(FRAGMENT_QUEST_QUEUE_GAP, onDone);
			}
		});

		trimStack(container);

		if (msg.sound && msg.sound !== "none") {
			Game.EmitSound(msg.sound);
		}
	}

	function processFragmentQuestNotificationQueue() {
		if (fragmentQuestNotificationActive) {
			return;
		}

		if (fragmentQuestNotificationQueue.length <= 0) {
			return;
		}

		fragmentQuestNotificationActive = true;
		var msg = fragmentQuestNotificationQueue.shift();
		renderFragmentQuestStarToast(msg, function () {
			fragmentQuestNotificationActive = false;
			processFragmentQuestNotificationQueue();
		});
	}

	function showFragmentQuestStar(msg) {
		fragmentQuestNotificationQueue.push(msg || {});
		processFragmentQuestNotificationQueue();
	}

	function enqueueFragmentQuestToolsPreview() {
		if (!Game.IsInToolsMode || !Game.IsInToolsMode()) {
			return;
		}

		$.Schedule(0.7, function () {
			showFragmentQuestStar({
				title: "War Healers",
				description: "Reach team healing milestones.",
				stars: 1,
				previous_stars: 0,
				progress_text: "250k healing",
				threshold_text: "250k / 500k / 1M",
				fragments_preview: 5,
				duration: 3.6,
				sound: "none"
			});
			showFragmentQuestStar({
				title: "Grom Executed",
				description: "Kill Grom with few deaths.",
				stars: 2,
				previous_stars: 1,
				progress_text: "2 deaths",
				threshold_text: "4 / 2 / 0 deaths",
				fragments_preview: 10,
				duration: 3.6,
				sound: "none"
			});
			showFragmentQuestStar({
				title: "Lich King's End",
				description: "Defeat the Lich King quickly.",
				stars: 3,
				previous_stars: 2,
				progress_text: "4:28",
				threshold_text: "7:00 / 5:30 / 4:30",
				fragments_preview: 15,
				duration: 3.6,
				sound: "none"
			});
		});
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
	GameEvents.Subscribe("xhs_fragment_quest_star", showFragmentQuestStar);
})();
