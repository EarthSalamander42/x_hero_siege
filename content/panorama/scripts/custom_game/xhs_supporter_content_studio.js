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
	var stopping = false;
	var pendingPreviewInstruction = "";
	var cardPreviewModes = {};
	function updateLayoutClass() {
		if (!root) return;
		var width = Number(root.actuallayoutwidth || 0);
		var height = Number(root.actuallayoutheight || 0);
		root.SetHasClass("Compact", width > 0 && width < 1250);
		root.SetHasClass("Narrow", width > 0 && width < 850);
		root.SetHasClass("LowHeight", height > 0 && height < 780);
		root.SetHasClass("Tiny", (width > 0 && width < 680) || (height > 0 && height < 620));
	}

	function list(value) {
		if (!value) return [];
		if (Array.isArray(value)) return value;
		return Object.keys(value).sort(function (a, b) { return Number(a) - Number(b); }).map(function (key) { return value[key]; });
	}
	function text(value) { return String(value || ""); }
	function truthy(value) { return value === true || value === 1 || value === "1" || String(value).toLowerCase() === "true"; }
	var LOCAL_PREVIEW_IMAGE_ALIASES = {
		diretide_2020_emblem_gold: "diretide_2020_emblem_gold",
		diretide_2020_emblem_green: "diretide_2020_emblem_green",
		diretide_2020_emblem_violet: "diretide_2020_emblem_violet",
		ti4_regen: "ti4_regen_aura",
		ti5_regen: "ti5_regen_aura",
		ti6_regen: "ti6_regen_aura",
		ti7_regen: "ti7_regen_aura",
		ti8_regen: "ti8_regen_aura",
		ti9_regen: "ti9_regen_aura",
		ti10_regen: "ti10_regen_aura",
		ti11_regen: "ti11_regen_aura",
		ti10_high_five_lvl2: "ti10_high_five",
		kill_fx_terrorblade: "kill_effect_terrorblade_arcana",
		kill_fx_windranger: "kill_effect_windranger_arcana",
		kill_fx_windranger_style2: "kill_effect_windranger_arcana_style2",
		rebirth_faceless_void: "rebirth_faceless_void_arcana",
		rebirth_muerta_revenant: "rebirth_muerta_revenant_portal",
		rebirth_seismic_apotheosis: "rebirth_seismic_apotheosis_style2"
	};
	var VANILLA_PREVIEW_IMAGE_ALIASES = {
		attack_lifesteal_blood: "s2r://panorama/images/items/lifesteal_png.vtex",
		attack_lifesteal_feast: "s2r://panorama/images/spellicons/life_stealer_feast_png.vtex",
		spell_lifesteal_bloodstone: "s2r://panorama/images/items/bloodstone_png.vtex",
		rebirth_ogre: "s2r://panorama/images/econ/items/ogre_magi/ogre_magi_arcana/ogre_magi_arcana_head_png.vtex"
	};
	function previewImagePath(value) {
		var raw = text(value).replace(/\\/g, "/").replace(/^\/+/, "");
		if (!raw) return "";
		if (raw.indexOf("file://{images}/") === 0 || raw.indexOf("s2r://panorama/images/") === 0) return raw;
		var cdnMatch = raw.match(/^https?:\/\/cdn\.frostrose-studio\.com\/static\/images\/battlepass\/xhs-4\.0\/([^?#]+)/i);
		if (cdnMatch) {
			var localName = cdnMatch[1]
				.replace(/-v2(?=\.[^.]+$)/i, "")
				.replace(/\.[^.]+$/, "")
				.replace(/-/g, "_");
			return "file://{images}/custom_game/battlepass/" + localName + ".png";
		}
		if (/^https?:\/\//i.test(raw)) return "";
		if (raw.indexOf("battlepass/") === 0) raw = "custom_game/" + raw;
		if (raw.indexOf("custom_game/") === 0) {
			if (!/\.[a-z0-9]+$/i.test(raw)) raw += ".png";
			return "file://{images}/" + raw;
		}
		if (/\.(?:png|jpg|jpeg|gif)$/i.test(raw)) return "file://{images}/" + raw;
		if (/\.vtex$/i.test(raw)) return "s2r://panorama/images/" + raw;
		return "s2r://panorama/images/" + raw + "_png.vtex";
	}
	function candidateTIEmblemPreviewImagePath(item) {
		if (!item) return "";
		var identity = [
			item.candidate_id,
			item.id,
			item.item_id,
			item.display_name,
			item.item_name,
			item.name,
			item.edition,
			item.ti_edition,
			item.metadata && item.metadata.ti_edition
		].join(" ").toLowerCase();
		var category = [item.category, item.item_type, item.type, item.slot_id]
			.join(" ").toLowerCase();
		if (category.indexOf("emblem") === -1 && identity.indexOf("emblem") === -1) return "";
		var edition = identity.match(/(?:^|[^a-z0-9])ti[\s_-]?(10|11)(?:[^0-9]|$)/i);
		if (!edition) return "";
		return "file://{images}/custom_game/battlepass/ti" + edition[1] + "_emblem.png";
	}
	function candidatePreviewImagePath(item) {
		// Candidate identity is authoritative for shipped TI emblem art. Backend
		// image metadata can legitimately lag behind the in-game catalogue.
		var emblemImage = candidateTIEmblemPreviewImagePath(item);
		if (emblemImage) return emblemImage;
		var fields = ["preview_image", "image_url", "image", "image_inventory", "icon", "icon_path"];
		for (var index = 0; index < fields.length; index += 1) {
			var resolved = previewImagePath(item && item[fields[index]]);
			if (resolved) return resolved;
		}
		var candidateID = text(item && item.candidate_id);
		var aliasedName = LOCAL_PREVIEW_IMAGE_ALIASES[candidateID];
		if (aliasedName) return "file://{images}/custom_game/battlepass/" + aliasedName + ".png";
		var vanillaImage = VANILLA_PREVIEW_IMAGE_ALIASES[candidateID];
		if (vanillaImage) return vanillaImage;
		var localName = candidateID;
		if (/^(ti(?:4|5|6|7|8|9|10|11)_(?:teleport|ascension|immolation|emblem|high_five)|ti7_shadow_kill(?:_gold)?|spell_lifesteal_octarine|rebirth_(?:icewrack|phantom_legacy|haunting_rift_style2|watchers_arrival|stonefall|divine_descent|mistborne|exorcists_return|chronal_aperture|young_magus_debut|phantom_arrival|winterwake))$/.test(localName)) {
			return "file://{images}/custom_game/battlepass/" + localName + ".png";
		}
		return "";
	}
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
		panel.SetHasClass("Pending", !error && (!!pendingPreviewInstruction || stopping));
	}
	function pendingCardText(item) {
		if (text(item && item.category) === "attack_lifesteal") return "PENDING - WAITING FOR THE IN-GAME ATTACK";
		if (text(item && item.category) === "kill_effect") return "PENDING - WAITING FOR THE IN-GAME KILL TRIGGER";
		return "PENDING - WAITING FOR THE IN-GAME EFFECT";
	}
	function pendingStatusText() {
		if (stopping) return "Stopping the active preview and cleaning its temporary gameplay assets...";
		if (activePreviewID && isBusy(activePreviewID, "preview")) {
			return pendingPreviewInstruction || "Preview pending: watch the in-game trigger before returning to the candidate card.";
		}
		return "";
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
	function setStopControls(isStopping) {
		var stopButton = $("#ContentStudioStop");
		var refreshButton = $("#ContentStudioRefresh");
		var stopLabel = $("#ContentStudioStopLabel");
		if (stopButton) stopButton.enabled = !isStopping;
		if (refreshButton) refreshButton.enabled = !isStopping;
		if (stopLabel) stopLabel.text = isStopping ? "STOPPING..." : "STOP PREVIEW";
		if (root) root.SetHasClass("IsStopping", !!isStopping);
	}
	function setBusy(candidateID, actionName) {
		// A new explicit preview supersedes a pending STOP. Its higher operation
		// ID makes a late stop acknowledgement stale while keeping the Studio
		// usable if that acknowledgement is delayed or lost.
		if (stopping) {
			stopping = false;
			setStopControls(false);
			if (root) root.RemoveClass("StopTimedOut");
		}
		var operationID = String(++operationSequence);
		latestGlobalOperation = operationID;
		latestOperation[candidateID] = operationID;
		busy[candidateID] = { action: actionName, operation_id: operationID }; render();
		$.Schedule(10.0, function () {
			if (busy[candidateID] && busy[candidateID].operation_id === operationID) {
				var timedOutAction = busy[candidateID].action;
				delete busy[candidateID];
				if (activePreviewID === candidateID) {
					activePreviewID = "";
					pendingPreviewInstruction = "";
				}
				if (timedOutAction === "preview") openButtonState("PREVIEW TIMEOUT - OPEN STUDIO", "error");
				render(); status("No callback received. Retry the action after checking the game console.", true);
			}
		});
		return operationID;
	}
	function card(item) {
		var parent = $.CreatePanel("Panel", $("#ContentStudioCandidates"), "candidate_" + item.candidate_id); parent.AddClass("CandidateCard");
		parent.AddClass("Rarity" + label(item.rarity || "common").replace(/[^A-Za-z0-9]/g, ""));
		var visual = $.CreatePanel("Panel", parent, ""); visual.AddClass("CandidateVisual");
		var art = $.CreatePanel("Panel", visual, ""); art.AddClass("CandidateArt");
		var previewMode = cardPreviewModes[item.candidate_id] || "image";
		var previewSwitch = $.CreatePanel("Panel", art, ""); previewSwitch.AddClass("CandidatePreviewSwitch");
		var imageButton = $.CreatePanel("Button", previewSwitch, ""); imageButton.AddClass("CandidatePreviewModeButton");
		imageButton.SetHasClass("Active", previewMode === "image");
		var imageButtonLabel = $.CreatePanel("Label", imageButton, ""); imageButtonLabel.text = "REWARD IMAGE";
		var vpcfButton = $.CreatePanel("Button", previewSwitch, ""); vpcfButton.AddClass("CandidatePreviewModeButton");
		vpcfButton.SetHasClass("Active", previewMode === "vpcf");
		var vpcfButtonLabel = $.CreatePanel("Label", vpcfButton, ""); vpcfButtonLabel.text = "VPCF PREVIEW";

		var imageStage = $.CreatePanel("Panel", art, ""); imageStage.AddClass("CandidatePreviewStage"); imageStage.AddClass("RewardImageStage");
		imageStage.SetHasClass("Hidden", previewMode !== "image");
		var imagePath = candidatePreviewImagePath(item);
		if (imagePath) {
			var previewImage = $.CreatePanel("Image", imageStage, "");
			previewImage.AddClass("CandidatePreviewImage");
			previewImage.scaling = "stretch-to-fill";
			previewImage.SetImage(imagePath);
			previewImage.hittest = false;
		} else {
			var marker = $.CreatePanel("Label", imageStage, ""); marker.AddClass("VPCFMarker"); marker.text = "NO REWARD IMAGE";
		}
		var vpcfStage = $.CreatePanel("Panel", art, ""); vpcfStage.AddClass("CandidatePreviewStage"); vpcfStage.AddClass("VPCFPreviewStage");
		vpcfStage.SetHasClass("Hidden", previewMode !== "vpcf");
		var vpcfStatus = $.CreatePanel("Label", vpcfStage, ""); vpcfStatus.AddClass("VPCFPreviewStatus"); vpcfStatus.text = "VPCF RENDERER COMING LATER";
		var vpcfPath = $.CreatePanel("Label", vpcfStage, ""); vpcfPath.AddClass("VPCFPreviewPath"); vpcfPath.text = text(item.asset_path);
		imageButton.SetPanelEvent("onactivate", function () {
			cardPreviewModes[item.candidate_id] = "image";
			imageButton.SetHasClass("Active", true);
			vpcfButton.SetHasClass("Active", false);
			imageStage.SetHasClass("Hidden", false);
			vpcfStage.SetHasClass("Hidden", true);
		});
		vpcfButton.SetPanelEvent("onactivate", function () {
			cardPreviewModes[item.candidate_id] = "vpcf";
			imageButton.SetHasClass("Active", false);
			vpcfButton.SetHasClass("Active", true);
			imageStage.SetHasClass("Hidden", true);
			vpcfStage.SetHasClass("Hidden", false);
		});
		var descriptionText = text(item.metadata && item.metadata.description);
		if (descriptionText) {
			art.SetPanelEvent("onmouseover", function () { $.DispatchEvent("DOTAShowTextTooltip", art, descriptionText); });
			art.SetPanelEvent("onmouseout", function () { $.DispatchEvent("DOTAHideTextTooltip", art); });
		}
		if (item.metadata && item.metadata.experimental) { var warning = $.CreatePanel("Label", art, ""); warning.AddClass("Experimental"); warning.text = "EXPERIMENTAL"; }
		if (item.metadata && truthy(item.metadata.bundle_only)) { var bundleOnly = $.CreatePanel("Label", art, ""); bundleOnly.AddClass("BundleOnly"); bundleOnly.text = "TI BUNDLE ONLY - DORMANT UNTIL 4.1"; }
		if (item.metadata && item.metadata.pricing_rule === "v2_above_v1") { var styleTwo = $.CreatePanel("Label", art, ""); styleTwo.AddClass("VariantBadge"); styleTwo.text = "STYLE II - PREMIUM"; }
		if (item.metadata && (item.metadata.technical_risk || truthy(item.metadata.requires_distinctness_review))) { var review = $.CreatePanel("Label", art, ""); review.AddClass("ReviewBadge"); review.text = item.metadata.technical_risk ? "TECH REVIEW" : "COMPARE VARIANT"; }
		var body = $.CreatePanel("Panel", visual, ""); body.AddClass("CandidateBody");
		var meta = $.CreatePanel("Label", body, ""); meta.AddClass("CandidateMeta"); meta.text = label(item.category) + "  -  " + label(item.rarity) + "  -  " + Number(item.fragment_price || 0) + " fragments";
		var name = $.CreatePanel("Label", body, ""); name.AddClass("CandidateName"); name.text = item.display_name;
		var path = $.CreatePanel("Label", body, ""); path.AddClass("CandidatePath");
		var fullPath = text(item.asset_path); path.text = fullPath;
		path.SetPanelEvent("onmouseover", function () { $.DispatchEvent("DOTAShowTextTooltip", path, fullPath); });
		path.SetPanelEvent("onmouseout", function () { $.DispatchEvent("DOTAHideTextTooltip", path); });
		var itemVerified = isVerified(item);
		var previewPending = isBusy(item.candidate_id, "preview");
		parent.SetHasClass("AwaitingPreview", previewPending);
		if (previewPending) {
			var pendingBadge = $.CreatePanel("Label", art, "");
			pendingBadge.AddClass("PendingBadge");
			pendingBadge.text = "PENDING";
		}
		var state = $.CreatePanel("Label", body, ""); state.AddClass("CandidateState"); state.SetHasClass("Verified", itemVerified); state.SetHasClass("Pending", previewPending); state.text = item.sent ? "SENT - persisted on reload" : (previewPending ? pendingCardText(item) : (itemVerified ? "LIVE PREVIEW RUN - confirm it was visible" : "LIVE PREVIEW REQUIRED"));
		var actions = $.CreatePanel("Panel", parent, ""); actions.AddClass("CandidateActions");
		action(actions, previewPending ? "TESTING..." : "TEST LIVE PLAYBACK", "Preview", function () {
			if (activePreviewID && activePreviewID !== item.candidate_id) delete busy[activePreviewID];
			activePreviewID = item.candidate_id;
			pendingPreviewInstruction = "Preview pending for " + item.display_name + ": watch the in-game trigger while keeping the Studio open.";
			var operationID = setBusy(item.candidate_id, "preview");
			status(pendingPreviewInstruction, false);
			openButtonState("PREVIEW RUNNING - OPEN STUDIO", "pending");
			send("supporter_content_studio_preview", { candidate_id: item.candidate_id, operation_id: operationID });
		}, isBusy(item.candidate_id));
		action(actions, item.sent ? "SENT" : (isBusy(item.candidate_id, "submit") ? "SENDING..." : "VISIBLE - SEND TO REVIEW"), "Submit", function () {
			var operationID = setBusy(item.candidate_id, "submit");
			send("supporter_content_studio_submit", { candidate_id: item.candidate_id, operation_id: operationID });
		}, item.sent || !itemVerified || isBusy(item.candidate_id));
	}
	function render(preserveStatus) {
		updateLayoutClass();
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
		var pendingInstruction = pendingStatusText();
		if (pendingInstruction) status(pendingInstruction, false);
		else if (!preserveStatus) status(shown.length + " / " + candidates.length + " candidates - " + candidates.filter(function (item) { return item.sent; }).length + " already sent", false);
	}
	function sync() {
		var requestID = ++syncSequence;
		pendingSyncID = requestID;
		syncChunks = {};
		var pendingInstruction = pendingStatusText();
		if (pendingInstruction) status(pendingInstruction, false);
		else status("Syncing persistent candidate state...", false);
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
		if (stopping) return;
		stopping = true;
		activePreviewID = "";
		pendingPreviewInstruction = "";
		busy = {};
		latestGlobalOperation = String(++operationSequence);
		var stopOperation = latestGlobalOperation;
		setStopControls(true);
		if (root) root.RemoveClass("StopTimedOut");
		status("Stopping the active preview and cleaning its temporary gameplay assets...", false);
		send("supporter_content_studio_stop", { operation_id: latestGlobalOperation });
		openButtonState("STOPPING PREVIEW - OPEN STUDIO", "pending");
		render(true);
		$.Schedule(5.0, function () {
			if (!stopping || latestGlobalOperation !== stopOperation) return;
			finishStop("STOP TIMEOUT: the server did not acknowledge cleanup. Local Studio state was reset; retry STOP before testing another effect.", true);
		});
	}
	function finishStop(message, timedOut) {
		stopping = false;
		busy = {};
		activePreviewID = "";
		pendingPreviewInstruction = "";
		setStopControls(false);
		if (root) root.SetHasClass("StopTimedOut", !!timedOut);
		openButtonState(timedOut ? "STOP TIMEOUT - OPEN STUDIO" : "CONTENT STUDIO", timedOut ? "error" : "");
		render(true);
		status(message || "Preview stopped.", !!timedOut);
	}
	function toggle() {
		updateLayoutClass();
		windowPanel.ToggleClass("Hidden");
		if (!windowPanel.BHasClass("Hidden")) sync();
	}
	function closeStudio() {
		if (!windowPanel.BHasClass("Hidden")) windowPanel.AddClass("Hidden");
		var hasPendingPreview = Object.keys(busy).some(function (candidateID) { return busy[candidateID] && busy[candidateID].action === "preview"; });
		// A verified preview can remain active after its callback. Keep the X a
		// cleanup action, not just a visual close, so no temporary asset leaks.
		if (activePreviewID || hasPendingPreview) stop();
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
		$("#ContentStudioOpen").RemoveClass("Hidden"); renderFacets(); render();
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
			return finishStop(event.message || "Preview stopped.", false);
		}
		if (event.candidate_id) {
			var current = busy[event.candidate_id];
			var responseOperation = text(event.operation_id);
			if (responseOperation && (!current || current.operation_id !== responseOperation)) return;
			if (!truthy(event.pending)) {
				delete busy[event.candidate_id];
				pendingPreviewInstruction = "";
			} else {
				pendingPreviewInstruction = event.message || "Preview pending: watch the in-game trigger before returning to the candidate card.";
			}
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

	var api = { Toggle: toggle, Close: closeStudio, Sync: sync, Stop: stop, Render: render };
	GameUI.CustomUIConfig().XHSContentStudio = api;
	updateLayoutClass();
	$.Schedule(0.35, sync);
})();
