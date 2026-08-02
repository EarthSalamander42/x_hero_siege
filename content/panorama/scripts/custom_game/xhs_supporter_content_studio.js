(function () {
	"use strict";
	var root = $.GetContextPanel();
	var windowPanel = $("#ContentStudioWindow");
	var candidates = [];
	var categories = [];
	var filters = { category: "all", edition: "all", rarity: "all", state: "all" };
	var verified = {};
	var localVerified = {};
	var locallySent = {};
	var busy = {};
	var latestOperation = {};
	var syncSequence = 0;
	var syncFailures = 0;
	var pendingSyncID = 0;
	var syncChunks = {};
	var operationSequence = 0;
	var latestGlobalOperation = "";
	var activePreviewID = "";
	var layerRaiseGeneration = 0;

	function hudAncestor(panel) {
		var current = panel;
		while (current) {
			if (current.id === "Hud") return current;
			current = current.GetParent ? current.GetParent() : null;
		}
		return null;
	}
	function lastHudSibling(hud, host) {
		if (!hud || typeof hud.GetChildCount !== "function" || typeof hud.GetChild !== "function") return null;
		for (var index = hud.GetChildCount() - 1; index >= 0; index -= 1) {
			var child = hud.GetChild(index);
			if (child && child !== host) return child;
		}
		return null;
	}
	function ensureTopHudLayer() {
		if (!root || typeof root.GetParent !== "function" || (root.IsValid && !root.IsValid())) return false;
		var hud = null;
		try {
			hud = hudAncestor(root);
			if (!hud && typeof FindDotaHudElement === "function") hud = hudAncestor(FindDotaHudElement("HUDElements"));
		} catch (error) {
			return false;
		}
		if (!hud || typeof root.SetParent !== "function" || typeof hud.MoveChildAfter !== "function") return false;

		try {
			if (root.GetParent() !== hud) root.SetParent(hud);
			if (root.GetParent() !== hud) return false;

			// A CustomUIElement loaded later can otherwise paint above this one even
			// with a large local z-index. Make the Studio a direct, last HUD child.
			root.style.zIndex = "1000000";
			var sibling = lastHudSibling(hud, root);
			if (sibling) hud.MoveChildAfter(root, sibling);
			return true;
		} catch (error) {
			return false;
		}
	}
	function startLayerRaiseCycle() {
		if (!root || typeof root.GetParent !== "function") return;
		var generation = ++layerRaiseGeneration;
		function raise(attempt) {
			if (generation !== layerRaiseGeneration || !root || (root.IsValid && !root.IsValid())) return;
			ensureTopHudLayer();
			if (attempt < 8) $.Schedule(attempt < 3 ? 0.2 : 0.75, function () { raise(attempt + 1); });
		}
		raise(0);
	}

	function list(value) {
		if (!value) return [];
		if (Array.isArray(value)) return value;
		return Object.keys(value).sort(function (a, b) { return Number(a) - Number(b); }).map(function (key) { return value[key]; });
	}
	function text(value) { return String(value || ""); }
	function truthy(value) { return value === true || value === 1 || value === "1" || String(value).toLowerCase() === "true"; }
	function normalizeSignature(value) {
		var signature = text(value).toLowerCase();
		return /^[a-f0-9]{64}$/.test(signature) ? signature : "";
	}
	function candidateSignature(item) { return normalizeSignature(item && item.metadata && item.metadata.asset_signature); }
	function signedKey(candidateID, signature) { return text(candidateID) + "@" + signature; }
	function candidateByID(candidateID) {
		for (var index = 0; index < candidates.length; index += 1) {
			if (text(candidates[index].candidate_id) === text(candidateID)) return candidates[index];
		}
		return null;
	}
	function isVerified(item) {
		var signature = candidateSignature(item);
		return !!signature && verified[item.candidate_id] === signature;
	}
	function markSent(candidateID, signature) {
		signature = normalizeSignature(signature);
		if (!signature) return false;
		locallySent[signedKey(candidateID, signature)] = true;
		var marked = false;
		candidates.forEach(function (item) {
			if (text(item.candidate_id) === text(candidateID) && candidateSignature(item) === signature) {
				item.sent = true;
				verified[item.candidate_id] = signature;
				marked = true;
			}
		});
		return marked;
	}
	function label(value) { return text(value).replace(/_/g, " ").replace(/\b\w/g, function (letter) { return letter.toUpperCase(); }); }
	function unique(field) {
		var seen = {};
		candidates.forEach(function (item) { var value = text(item[field]); if (value) seen[value] = true; });
		return Object.keys(seen).sort(function (left, right) {
			var leftNumber = Number(left.replace(/\D/g, "")); var rightNumber = Number(right.replace(/\D/g, ""));
			if (leftNumber && rightNumber && leftNumber !== rightNumber) return leftNumber - rightNumber;
			return left < right ? -1 : (left > right ? 1 : 0);
		});
	}
	function status(message, error) {
		var panel = $("#ContentStudioStatus");
		panel.text = message;
		panel.SetHasClass("Error", !!error);
	}
	function openButtonState(caption, state) {
		var button = $("#ContentStudioOpen");
		var title = $("#ContentStudioOpenLabel");
		if (title) title.text = caption || "CONTENT STUDIO";
		if (!button) return;
		button.SetHasClass("OpenPending", state === "pending");
		button.SetHasClass("OpenVerified", state === "verified");
		button.SetHasClass("OpenError", state === "error");
	}
	function send(name, payload) { GameEvents.SendCustomGameEventToServer(name, payload || {}); }
	function filterButton(parent, caption, active, callback) {
		var button = $.CreatePanel("Button", parent, "");
		button.SetHasClass("Active", active);
		button.SetPanelEvent("onactivate", callback);
		var title = $.CreatePanel("Label", button, ""); title.text = caption;
	}
	function renderFacet(panelID, field, values, allCaption) {
		var parent = $(panelID); parent.RemoveAndDeleteChildren();
		filterButton(parent, allCaption, filters[field] === "all", function () { filters[field] = "all"; renderFacets(); render(); });
		values.forEach(function (value) {
			filterButton(parent, label(value).toUpperCase(), filters[field] === value, function () { filters[field] = value; renderFacets(); render(); });
		});
	}
	function renderFacets() {
		renderFacet("#ContentStudioCategories", "category", categories, "ALL CATEGORIES");
		renderFacet("#ContentStudioEditions", "edition", unique("ti_edition"), "ALL TI");
		renderFacet("#ContentStudioRarities", "rarity", unique("rarity"), "ALL RARITIES");
		renderFacet("#ContentStudioStates", "state", ["unsent", "sent"], "ALL STATES");
	}
	function action(parent, caption, className, callback, disabled) {
		var button = $.CreatePanel("Button", parent, "");
		button.AddClass(className || ""); button.enabled = !disabled; button.SetPanelEvent("onactivate", callback);
		var title = $.CreatePanel("Label", button, ""); title.text = caption;
	}
	function isBusy(candidateID, actionName) {
		return !!busy[candidateID] && (!actionName || busy[candidateID].action === actionName);
	}
	function setBusy(candidateID, actionName) {
		var operationID = String(++operationSequence);
		latestGlobalOperation = operationID;
		latestOperation[candidateID] = operationID;
		busy[candidateID] = { action: actionName, operation_id: operationID }; render();
		$.Schedule(10.0, function () {
			if (busy[candidateID] && busy[candidateID].operation_id === operationID) {
				var timedOutAction = busy[candidateID].action;
				delete busy[candidateID];
				if (activePreviewID === candidateID) activePreviewID = "";
				if (timedOutAction === "preview") openButtonState("PREVIEW TIMEOUT - OPEN STUDIO", "error");
				render(); status("No callback received. Retry the action after checking the game console.", true);
			}
		});
		return operationID;
	}
	function card(item) {
		var parent = $.CreatePanel("Panel", $("#ContentStudioCandidates"), "candidate_" + item.candidate_id); parent.AddClass("CandidateCard");
		var art = $.CreatePanel("Panel", parent, ""); art.AddClass("CandidateArt");
		var marker = $.CreatePanel("Label", art, ""); marker.AddClass("VPCFMarker"); marker.text = item.ti_edition ? text(item.ti_edition).toUpperCase() : "VPCF";
		if (item.metadata && item.metadata.experimental) { var warning = $.CreatePanel("Label", art, ""); warning.AddClass("Experimental"); warning.text = "EXPERIMENTAL"; }
		if (item.metadata && truthy(item.metadata.bundle_only)) { var bundleOnly = $.CreatePanel("Label", art, ""); bundleOnly.AddClass("BundleOnly"); bundleOnly.text = "TI BUNDLE ONLY - DORMANT UNTIL 4.1"; }
		var body = $.CreatePanel("Panel", parent, ""); body.AddClass("CandidateBody");
		var meta = $.CreatePanel("Label", body, ""); meta.AddClass("CandidateMeta"); meta.text = label(item.category) + "  -  " + label(item.rarity) + "  -  " + Number(item.fragment_price || 0) + " fragments";
		var name = $.CreatePanel("Label", body, ""); name.AddClass("CandidateName"); name.text = item.display_name;
		var path = $.CreatePanel("Label", body, ""); path.AddClass("CandidatePath");
		var fullPath = text(item.asset_path); path.text = fullPath;
		path.SetPanelEvent("onmouseover", function () { $.DispatchEvent("DOTAShowTextTooltip", path, fullPath); });
		path.SetPanelEvent("onmouseout", function () { $.DispatchEvent("DOTAHideTextTooltip", path); });
		var itemVerified = isVerified(item);
		var previewPending = isBusy(item.candidate_id, "preview");
		parent.SetHasClass("AwaitingPreview", previewPending);
		var state = $.CreatePanel("Label", body, ""); state.AddClass("CandidateState"); state.SetHasClass("Verified", itemVerified); state.SetHasClass("Pending", previewPending); state.text = item.sent ? "SENT - persisted on reload" : (previewPending ? "WAITING FOR THE VISIBLE EFFECT..." : (itemVerified ? "LIVE PREVIEW RUN - confirm it was visible" : "LIVE PREVIEW REQUIRED"));
		var actions = $.CreatePanel("Panel", body, ""); actions.AddClass("CandidateActions");
		action(actions, previewPending ? "TESTING..." : "TEST LIVE PLAYBACK", "Preview", function () {
			if (activePreviewID && activePreviewID !== item.candidate_id) delete busy[activePreviewID];
			activePreviewID = item.candidate_id;
			var operationID = setBusy(item.candidate_id, "preview");
			status("Starting live playback for " + item.display_name + "...", false);
			openButtonState("PREVIEW RUNNING - OPEN STUDIO", "pending");
			windowPanel.AddClass("Hidden");
			send("supporter_content_studio_preview", { candidate_id: item.candidate_id, operation_id: operationID });
		}, isBusy(item.candidate_id));
		action(actions, item.sent ? "SENT" : (isBusy(item.candidate_id, "submit") ? "SENDING..." : "VISIBLE - SEND TO REVIEW"), "Submit", function () {
			var operationID = setBusy(item.candidate_id, "submit");
			send("supporter_content_studio_submit", { candidate_id: item.candidate_id, operation_id: operationID });
		}, item.sent || !itemVerified || isBusy(item.candidate_id));
	}
	function render(preserveStatus) {
		var parent = $("#ContentStudioCandidates"); if (!parent) return; parent.RemoveAndDeleteChildren();
		var searchPanel = $("#ContentStudioSearch"); var query = text(searchPanel && searchPanel.text).toLowerCase();
		var shown = candidates.filter(function (item) {
			var state = item.sent ? "sent" : "unsent";
			return (filters.category === "all" || item.category === filters.category)
				&& (filters.edition === "all" || item.ti_edition === filters.edition)
				&& (filters.rarity === "all" || item.rarity === filters.rarity)
				&& (filters.state === "all" || state === filters.state)
				&& (!query || text(item.display_name).toLowerCase().indexOf(query) !== -1 || text(item.asset_path).toLowerCase().indexOf(query) !== -1);
		});
		shown.forEach(card);
		var waitingForPreview = activePreviewID && isBusy(activePreviewID, "preview");
		if (!preserveStatus && !waitingForPreview) status(shown.length + " / " + candidates.length + " candidates - " + candidates.filter(function (item) { return item.sent; }).length + " already sent", false);
	}
	function sync() {
		var requestID = ++syncSequence;
		pendingSyncID = requestID;
		syncChunks = {};
		status("Syncing persistent candidate state...", false);
		send("supporter_content_studio_sync", { request_id: String(requestID) });
		$.Schedule(4.0, function () {
			if (pendingSyncID === requestID && root && root.IsValid()) {
				syncFailures += 1;
				if (syncFailures < 8) sync();
				else {
					$("#ContentStudioOpen").RemoveClass("Hidden");
					openButtonState("SYNC ERROR - OPEN STUDIO", "error");
					status("Content Studio did not answer after several retries. A full demo map reload may be required after a Lua script reload; check the API and server console.", true);
				}
			}
		});
	}
	function stop() {
		activePreviewID = "";
		busy = {};
		latestGlobalOperation = String(++operationSequence);
		send("supporter_content_studio_stop", { operation_id: latestGlobalOperation });
		openButtonState("CONTENT STUDIO", "");
		render();
	}
	function toggle() {
		startLayerRaiseCycle();
		windowPanel.ToggleClass("Hidden");
		if (!windowPanel.BHasClass("Hidden")) sync();
	}

	function applySyncedState(event) {
		pendingSyncID = 0;
		syncFailures = 0;
		candidates = list(event.candidates); categories = list(event.categories);
		verified = {};
		candidates.forEach(function (item) {
			var signature = candidateSignature(item);
			var key = signature ? signedKey(item.candidate_id, signature) : "";
			item.sent = !!signature && (truthy(item.sent) || truthy(locallySent[key]));
			if (signature && (truthy(localVerified[key]) || item.sent)) verified[item.candidate_id] = signature;
		});
		var scene = event.scene_panel || {};
		$("#ContentStudioSceneNoticeText").text = truthy(scene.raw_vpcf_supported) ? "ScenePanel VPCF preview available." : "ScenePanel spike: raw VPCF needs an authored VMap. Category-matched live playback runs on the demo hero; teleport safely previews its exact start/end VPCFs without moving the hero.";
		if (!activePreviewID) openButtonState("CONTENT STUDIO", "");
		$("#ContentStudioOpen").RemoveClass("Hidden"); startLayerRaiseCycle(); renderFacets(); render();
	}
	GameEvents.Subscribe("supporter_content_studio_state", function (event) {
		var responseID = Number(event.request_id || 0);
		if (responseID && responseID < syncSequence) return;
		if (!truthy(event.ok)) {
			if (responseID === pendingSyncID) pendingSyncID = 0;
			if (truthy(event.unavailable)) return root.DeleteAsync(0);
			syncFailures += 1;
			$("#ContentStudioOpen").RemoveClass("Hidden");
			openButtonState("SYNC ERROR - OPEN STUDIO", "error");
			status(event.message || "Content Studio sync failed.", true);
			if (syncFailures < 8) {
				var failedRequestID = responseID;
				$.Schedule(Math.min(1.0 + syncFailures * 0.5, 4.0), function () {
					if (root && root.IsValid() && pendingSyncID === 0 && syncSequence === failedRequestID) sync();
				});
			}
			return;
		}
		var totalChunks = Math.max(1, Number(event.total_chunks || 1));
		var chunkIndex = Math.max(1, Number(event.chunk_index || 1));
		var chunkKey = String(responseID || event.request_id || "0");
		var accumulator = syncChunks[chunkKey];
		if (!accumulator) accumulator = syncChunks[chunkKey] = { chunks: {}, received: 0, categories: [], rarity_prices: {}, scene_panel: {} };
		if (!accumulator.chunks[chunkIndex]) {
			accumulator.chunks[chunkIndex] = list(event.candidates);
			accumulator.received += 1;
		}
		if (chunkIndex === 1) {
			accumulator.categories = list(event.categories);
			accumulator.rarity_prices = event.rarity_prices || {};
			accumulator.scene_panel = event.scene_panel || {};
		}
		if (accumulator.received < totalChunks) return;
		var merged = [];
		for (var index = 1; index <= totalChunks; index += 1) merged = merged.concat(accumulator.chunks[index] || []);
		delete syncChunks[chunkKey];
		applySyncedState({ candidates: merged, categories: accumulator.categories, rarity_prices: accumulator.rarity_prices, scene_panel: accumulator.scene_panel });
	});
	GameEvents.Subscribe("supporter_content_studio_preview_result", function (event) {
		if (truthy(event.stopped)) {
			var stopOperation = text(event.operation_id);
			if (stopOperation && stopOperation !== latestGlobalOperation) return;
			busy = {}; activePreviewID = "";
			openButtonState("CONTENT STUDIO", "");
		}
		if (event.candidate_id) {
			var current = busy[event.candidate_id];
			var responseOperation = text(event.operation_id);
			if (responseOperation && (!current || current.operation_id !== responseOperation)) return;
			if (!truthy(event.pending)) delete busy[event.candidate_id];
			if (truthy(event.ok) && truthy(event.verified)) {
				var item = candidateByID(event.candidate_id);
				var responseSignature = normalizeSignature(event.asset_signature);
				if (!item || !responseSignature || candidateSignature(item) !== responseSignature) {
					openButtonState("PREVIEW CHANGED - OPEN STUDIO", "error");
					render();
					return status("Candidate assets changed while the preview was running. Refresh and test it again.", true);
				}
				verified[event.candidate_id] = responseSignature;
				localVerified[signedKey(event.candidate_id, responseSignature)] = true;
			}
			if (truthy(event.pending)) openButtonState("PREVIEW RUNNING - OPEN STUDIO", "pending");
			else if (truthy(event.ok) && truthy(event.verified)) openButtonState("VERIFIED - OPEN STUDIO", "verified");
			else {
				activePreviewID = "";
				openButtonState("PREVIEW FAILED - OPEN STUDIO", "error");
			}
		}
		render(); status(event.message || (truthy(event.ok) ? "Preview started." : "Preview failed."), !truthy(event.ok));
	});
	GameEvents.Subscribe("supporter_content_studio_submit_result", function (event) {
		var candidateID = text(event.candidate_id);
		var responseOperation = text(event.operation_id);
		var newestOperation = latestOperation[candidateID];
		var stale = !!responseOperation && !!newestOperation && newestOperation !== responseOperation;
		if (stale) {
			if (truthy(event.ok) && markSent(candidateID, event.asset_signature)) render(true);
			return;
		}
		var current = busy[candidateID];
		if (!responseOperation || (current && current.operation_id === responseOperation)) delete busy[candidateID];
		if (truthy(event.ok)) markSent(candidateID, event.asset_signature);
		render(); status(event.message || (truthy(event.ok) ? "Candidate sent." : "Submission failed."), !truthy(event.ok));
	});

	var api = { Toggle: toggle, Sync: sync, Stop: stop, Render: render, RaiseLayer: ensureTopHudLayer };
	GameUI.CustomUIConfig().XHSContentStudio = api;
	startLayerRaiseCycle();
	$.Schedule(0.35, sync);
})();
