(function () {
	"use strict";

	var root = $.GetContextPanel();
	var topBar = $("#XHSCinematicTopBar");
	var bottomBar = $("#XHSCinematicBottomBar");
	var title = $("#XHSCinematicTitle");
	var subtitle = $("#XHSCinematicSubtitle");
	var activeId = "";
	var hiddenPanels = [];
	var musicHandles = [];
	var endSerial = 0;
	var maintainSerial = 0;

	$.Msg("[XHS][Cinematic] Loaded. root=", root ? root.id : "<missing>");

	function GetHudRoot() {
		var panel = root;
		while (panel && panel.id !== "Hud") {
			panel = panel.GetParent();
		}
		return panel;
	}

	function IsRecorded(panel) {
		for (var i = 0; i < hiddenPanels.length; i++) {
			if (hiddenPanels[i].panel === panel) {
				return true;
			}
		}
		return false;
	}

	function RecordAndHide(panel) {
		if (!panel || panel === root) {
			return;
		}
		if (IsRecorded(panel)) {
			panel.visible = false;
			return;
		}

		hiddenPanels.push({
			panel: panel,
			visible: panel.visible
		});
		panel.visible = false;
	}

	function HideHudBranches() {
		var hud = GetHudRoot();
		if (!hud) {
			return;
		}

		var protectedPath = [];
		var cursor = root;
		while (cursor && cursor !== hud) {
			protectedPath.unshift(cursor);
			cursor = cursor.GetParent();
		}
		if (cursor !== hud) {
			return;
		}

		var parent = hud;
		for (var pathIndex = 0; pathIndex < protectedPath.length; pathIndex++) {
			var protectedChild = protectedPath[pathIndex];
			var children = parent.GetChildren();
			for (var childIndex = 0; childIndex < children.length; childIndex++) {
				if (children[childIndex] !== protectedChild) {
					RecordAndHide(children[childIndex]);
				}
			}
			parent = protectedChild;
		}
	}

	function MaintainHudHidden(serial) {
		if (!activeId || serial !== maintainSerial) {
			return;
		}
		HideHudBranches();
		$.Schedule(0.1, function () {
			MaintainHudHidden(serial);
		});
	}

	function RestoreHud() {
		for (var i = hiddenPanels.length - 1; i >= 0; i--) {
			var state = hiddenPanels[i];
			if (state.panel && state.panel.IsValid && state.panel.IsValid()) {
				state.panel.visible = state.visible;
			}
		}
		hiddenPanels = [];
	}

	function StopMusic() {
		for (var i = 0; i < musicHandles.length; i++) {
			if (musicHandles[i] !== undefined && musicHandles[i] !== null) {
				Game.StopSound(musicHandles[i]);
			}
		}
		musicHandles = [];
	}

	function PlayMusic(soundName, layers) {
		StopMusic();
		if (!soundName) {
			return;
		}

		layers = Math.max(1, Number(layers) || 1);
		for (var i = 0; i < layers; i++) {
			musicHandles.push(Game.EmitSound(soundName));
		}
	}

	function ApplyLetterbox(percent, transition) {
		percent = Math.max(0, Math.min(25, Number(percent) || 10));
		transition = Math.max(0.05, Number(transition) || 0.7);
		var duration = transition.toFixed(2) + "s";
		topBar.style.transitionDuration = duration;
		bottomBar.style.transitionDuration = duration;
		topBar.style.height = percent.toFixed(2) + "%";
		bottomBar.style.height = percent.toFixed(2) + "%";
	}

	function Begin(data) {
		data = data || {};
		activeId = String(data.id || "default");
		endSerial++;
		maintainSerial++;
		$.Msg(
			"[XHS][Cinematic] Begin id=", activeId,
			" hide_hud=", data.hide_hud,
			" duration=", data.duration,
			" letterbox=", data.letterbox_pct,
			" hud=", GetHudRoot() ? "found" : "missing"
		);

		if (Number(data.hide_hud) !== 0) {
			HideHudBranches();
			$.Msg("[XHS][Cinematic] Hidden HUD branches: ", hiddenPanels.length);
			MaintainHudHidden(maintainSerial);
		}

		title.text = data.title || "";
		subtitle.text = data.subtitle || "";
		root.SetHasClass("XHSCinematicHasTitle", !!title.text || !!subtitle.text);
		ApplyLetterbox(data.letterbox_pct, data.transition);
		PlayMusic(data.music || "", data.music_layers);

		root.RemoveClass("XHSCinematicActive");
		$.Schedule(0.01, function () {
			if (activeId) {
				root.AddClass("XHSCinematicActive");
			}
		});

		var duration = Number(data.duration) || 0;
		if (duration > 0) {
			var serial = endSerial;
			$.Schedule(duration, function () {
				if (serial === endSerial && activeId === String(data.id || "default")) {
					End({ id: activeId });
				}
			});
		}
	}

	function End(data) {
		var requestedId = String((data && data.id) || "default");
		$.Msg("[XHS][Cinematic] End requested=", requestedId, " active=", activeId || "<none>");
		if (!activeId || requestedId !== activeId) {
			$.Msg("[XHS][Cinematic] End ignored because the id does not match the active cinematic.");
			return;
		}

		activeId = "";
		endSerial++;
		maintainSerial++;
		StopMusic();
		root.RemoveClass("XHSCinematicActive");
		root.RemoveClass("XHSCinematicHasTitle");
		topBar.style.height = "0%";
		bottomBar.style.height = "0%";

		var transition = parseFloat(topBar.style.transitionDuration) || 0.7;
		$.Schedule(transition, function () {
			if (!activeId) {
				RestoreHud();
				$.Msg("[XHS][Cinematic] HUD restored after transition ", transition);
			}
		});
	}

	GameEvents.Subscribe("xhs_cinematic_begin", Begin);
	GameEvents.Subscribe("xhs_cinematic_end", End);

	GameUI.CustomUIConfig().XHSCinematics = {
		begin: Begin,
		end: End,
		isActive: function () { return !!activeId; }
	};
})();
