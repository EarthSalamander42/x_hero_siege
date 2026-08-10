(function () {
	"use strict";

	var root = $.GetContextPanel();
	var topBar = $("#XHSCinematicTopBar");
	var bottomBar = $("#XHSCinematicBottomBar");
	var title = $("#XHSCinematicTitle");
	var subtitle = $("#XHSCinematicSubtitle");
	var states = {};
	var stateOrder = [];
	var hiddenPanels = [];
	var musicHandles = [];
	var eventMusicHandle = null;
	var eventMusicSerial = -1;
	var renderSerial = 0;
	var stateSerial = 0;

	$.Msg("[XHS][Cinematic] Loaded. root=", root ? root.id : "<missing>");

	function GetHudRoot() {
		var panel = root;
		while (panel && panel.id !== "Hud") panel = panel.GetParent();
		return panel;
	}

	function GetPanelChildren(panel) {
		var children = [];
		if (!panel) return children;
		if (typeof panel.GetChildCount === "function" && typeof panel.GetChild === "function") {
			for (var i = 0; i < panel.GetChildCount(); i++) {
				var child = panel.GetChild(i);
				if (child) children.push(child);
			}
		} else if (typeof panel.Children === "function") {
			children = panel.Children() || children;
		}
		return children;
	}

	function IsRecorded(panel) {
		for (var i = 0; i < hiddenPanels.length; i++) {
			if (hiddenPanels[i].panel === panel) return true;
		}
		return false;
	}

	function RecordAndHide(panel) {
		if (!panel || panel === root) return;
		if (!IsRecorded(panel)) hiddenPanels.push({ panel: panel, visible: panel.visible });
		panel.visible = false;
	}

	function IsProtectedOrAncestor(panel, protectedPanels) {
		for (var i = 0; i < protectedPanels.length; i++) {
			var cursor = protectedPanels[i];
			while (cursor) {
				if (cursor === panel) return true;
				cursor = cursor.GetParent();
			}
		}
		return false;
	}

	function HideUnprotectedChildren(panel, protectedPanels) {
		var children = GetPanelChildren(panel);
		for (var i = 0; i < children.length; i++) {
			var child = children[i];
			if (!IsProtectedOrAncestor(child, protectedPanels)) {
				RecordAndHide(child);
			} else {
				var protectedPanel = false;
				for (var j = 0; j < protectedPanels.length; j++) {
					if (protectedPanels[j] === child) protectedPanel = true;
				}
				if (!protectedPanel) HideUnprotectedChildren(child, protectedPanels);
			}
		}
	}

	function HideHud(state) {
		var hud = GetHudRoot();
		if (!hud || !state || Number(state.hide_hud) === 0) return;
		var protectedPanels = [root];
		if (hud.FindChildTraverse) {
			// Pause must remain usable during every cinematic. Dialog panels are
			// additionally preserved only for cinematics started by a dialog.
			var pauseRoot = hud.FindChildTraverse("XHSPauseRoot");
			if (pauseRoot) protectedPanels.push(pauseRoot);

			// Preserve only the two central toast stacks. The notification root
			// also owns rune, wave and channel widgets, so protecting the whole
			// root would bring unrelated gameplay UI back into the cutscene.
			var topNotifications = hud.FindChildTraverse("XHSTopNotifications");
			var bottomNotifications = hud.FindChildTraverse("XHSBottomNotifications");
			if (topNotifications) protectedPanels.push(topNotifications);
			if (bottomNotifications) protectedPanels.push(bottomNotifications);
		}
		if (Number(state.allow_dialog_ui) !== 0 && hud.FindChildTraverse) {
			var dialog = hud.FindChildTraverse("DialogPanel");
			var floatingDialog = hud.FindChildTraverse("FloatingDialogPanel");
			if (dialog) protectedPanels.push(dialog);
			if (floatingDialog) protectedPanels.push(floatingDialog);
		}
		HideUnprotectedChildren(hud, protectedPanels);
	}

	function RestoreHud() {
		for (var i = hiddenPanels.length - 1; i >= 0; i--) {
			var state = hiddenPanels[i];
			if (state.panel && state.panel.IsValid && state.panel.IsValid()) state.panel.visible = state.visible;
		}
		hiddenPanels = [];
	}

	function StopMusic() {
		for (var i = 0; i < musicHandles.length; i++) {
			if (musicHandles[i] !== undefined && musicHandles[i] !== null) Game.StopSound(musicHandles[i]);
		}
		musicHandles = [];
	}

	function PlayMusic(soundName, layers) {
		StopMusic();
		if (!soundName) return;
		for (var i = 0; i < Math.max(1, Number(layers) || 1); i++) musicHandles.push(Game.EmitSound(soundName));
	}

	function StopEventMusic() {
		if (eventMusicHandle !== undefined && eventMusicHandle !== null) Game.StopSound(eventMusicHandle);
		eventMusicHandle = null;
	}

	function PlayEventMusic(data) {
		data = data || {};
		var serial = Number(data.serial) || 0;
		if (serial < eventMusicSerial) return;
		eventMusicSerial = serial;
		StopEventMusic();
		if (data.sound) eventMusicHandle = Game.EmitSound(String(data.sound));
	}

	function EndEventMusic(data) {
		data = data || {};
		var serial = Number(data.serial) || 0;
		if (serial < eventMusicSerial) return;
		eventMusicSerial = serial;
		StopEventMusic();
	}

	function ApplyLetterbox(percent, transition) {
		var numericPercent = Number(percent);
		percent = Math.max(0, Math.min(25, isNaN(numericPercent) ? 10 : numericPercent));
		transition = Math.max(0.05, Number(transition) || 0.7);
		var duration = transition.toFixed(2) + "s";
		topBar.style.transitionDuration = duration;
		bottomBar.style.transitionDuration = duration;
		topBar.style.height = percent.toFixed(2) + "%";
		bottomBar.style.height = percent.toFixed(2) + "%";
	}

	function GetTopState() {
		for (var i = stateOrder.length - 1; i >= 0; i--) {
			if (states[stateOrder[i]]) return states[stateOrder[i]];
		}
		return null;
	}

	function Render() {
		renderSerial++;
		var state = GetTopState();
		RestoreHud();
		if (!state) {
			StopMusic();
			root.RemoveClass("XHSCinematicActive");
			root.RemoveClass("XHSCinematicHasTitle");
			topBar.style.height = "0%";
			bottomBar.style.height = "0%";
			return;
		}

		HideHud(state);
		var serial = renderSerial;
		(function MaintainHudHidden() {
			if (serial !== renderSerial || state !== GetTopState()) return;
			HideHud(state);
			$.Schedule(0.1, MaintainHudHidden);
		})();
		title.text = state.title || "";
		subtitle.text = state.subtitle || "";
		root.SetHasClass("XHSCinematicHasTitle", !!title.text || !!subtitle.text);
		ApplyLetterbox(state.letterbox_pct, state.transition);
		PlayMusic(state.music || "", state.music_layers);
		root.AddClass("XHSCinematicActive");
	}

	function Begin(data) {
		data = data || {};
		var id = String(data.id || "default");
		if (!states[id]) stateOrder.push(id);
		data._serial = ++stateSerial;
		states[id] = data;
		Render();
		$.Msg("[XHS][Cinematic] Begin id=", id, " stack=", stateOrder.length);

		var duration = Number(data.duration) || 0;
		if (duration > 0) {
			var serial = data._serial;
			var endGameTime = Game.GetGameTime() + duration;
			(function WaitForDuration() {
				if (!states[id] || states[id]._serial !== serial) return;
				if (Game.GetGameTime() >= endGameTime) {
					End({ id: id });
					return;
				}
				$.Schedule(0.03, WaitForDuration);
			})();
		}
	}

	function End(data) {
		var id = String((data && data.id) || "default");
		if (!states[id]) return;
		var endedState = states[id];
		delete states[id];
		for (var i = stateOrder.length - 1; i >= 0; i--) {
			if (stateOrder[i] === id) stateOrder.splice(i, 1);
		}
		Render();
		$.Msg("[XHS][Cinematic] End id=", id, " stack=", stateOrder.length);
	}

	GameEvents.Subscribe("xhs_cinematic_begin", Begin);
	GameEvents.Subscribe("xhs_cinematic_end", End);
	GameEvents.Subscribe("xhs_event_music_play", PlayEventMusic);
	GameEvents.Subscribe("xhs_event_music_stop", EndEventMusic);
	GameUI.CustomUIConfig().XHSCinematics = {
		begin: Begin,
		end: End,
		isActive: function () { return !!GetTopState(); }
	};
})();
