"use strict";

(function () {
	var SCHEMA_VERSION = 1;
	var MAX_BUILDS = 3;
	var MAX_ITEMS_PER_SECTION = 12;
	var SAVE_DEBOUNCE_SECONDS = 0.45;
	var MAX_RETRY_ATTEMPTS = 3;
	var SECTION_KEYS = ["starting", "early", "core", "situational", "late"];
	var SECTION_TOKENS = {
		starting: "#xhs_item_builds_section_starting",
		early: "#xhs_item_builds_section_early",
		core: "#xhs_item_builds_section_core",
		situational: "#xhs_item_builds_section_situational",
		late: "#xhs_item_builds_section_late"
	};
	var FALLBACK_ALLOWED_ITEMS = [
		"item_amulet_of_the_wild",
		"item_ankh_of_reincarnation",
		"item_astral_core",
		"item_boots_of_speed",
		"item_bracer_of_the_void",
		"item_celestial_claws",
		"item_healing_wards",
		"item_healing_wards2",
		"item_health_potion",
		"item_lifesteal_mask",
		"item_mana_potion",
		"item_mystic_gem",
		"item_orb_of_arcane",
		"item_orb_of_darkness",
		"item_orb_of_darkness2",
		"item_orb_of_earth",
		"item_orb_of_earth2",
		"item_orb_of_earth3",
		"item_orb_of_fire",
		"item_orb_of_fire2",
		"item_orb_of_lightning",
		"item_orb_of_lightning2",
		"item_orb_of_wind",
		"item_plagueheart",
		"item_potion_full",
		"item_potion_of_antimagic",
		"item_potion_of_invulnerability",
		"item_searing_blade",
		"item_staff_of_mastery",
		"item_tempest_aegis",
		"item_tome_big",
		"item_tome_of_power",
		"item_tome_small",
		"item_viridian_gem",
		"item_xhs_cloak_of_flames",
		"item_xhs_orb_of_venom",
		"item_zephyr_gem"
	];

	var root = $("#XHSItemBuildRoot");

	function findLocalElement(id) {
		return root && root.FindChildTraverse ? root.FindChildTraverse(id) : null;
	}
	var originalParent = root ? root.GetParent() : null;
	var state = {
		heroName: "",
		mapScope: "",
		revision: 0,
		payload: null,
		allowedItems: FALLBACK_ALLOWED_ITEMS.slice(0),
		activeBuildIndex: 0,
		editMode: false,
		catalogSection: "",
		loadSequence: 0,
		saveSequence: 0,
		loadAttempts: 0,
		saveDebounceGeneration: 0,
		saveInFlight: null,
		saveQueued: false,
		nameDialogMode: "",
		nativeAttached: false,
		nativeGuideInitialized: false,
		guideClosed: null,
		guideAlignmentGeneration: 0
	};

	function localize(token) {
		var value = $.Localize(token);
		return value && value !== token ? value : token.replace(/^#/, "");
	}

	function clone(value) {
		return JSON.parse(JSON.stringify(value));
	}

	function toArray(value) {
		if (!value) {
			return [];
		}
		if (Array.isArray(value)) {
			return value.slice(0);
		}
		var keys = Object.keys(value).filter(function (key) {
			return /^\d+$/.test(key);
		}).sort(function (left, right) {
			return Number(left) - Number(right);
		});
		return keys.map(function (key) {
			return value[key];
		});
	}

	function makeSections(source) {
		source = source || {};
		var sections = {};
		for (var i = 0; i < SECTION_KEYS.length; i++) {
			var key = SECTION_KEYS[i];
			sections[key] = toArray(source[key]).filter(function (itemName) {
				return typeof itemName === "string";
			}).slice(0, MAX_ITEMS_PER_SECTION);
		}
		return sections;
	}

	function makeBuild(id, name, sections) {
		return {
			id: String(id || ("build_" + Date.now())),
			name: String(name || localize("#xhs_item_builds_default_name")).substring(0, 32),
			sections: makeSections(sections)
		};
	}

	function makeDefaultPayload() {
		return {
			schema_version: SCHEMA_VERSION,
			active_build_id: "xhs_default",
			builds: [
				makeBuild("xhs_default", localize("#xhs_item_builds_default_name"), {
					starting: ["item_health_potion", "item_mana_potion"],
					early: ["item_boots_of_speed"],
					core: ["item_orb_of_lightning2", "item_orb_of_fire2", "item_orb_of_darkness2", "item_orb_of_earth2"],
					situational: ["item_potion_of_antimagic", "item_potion_of_invulnerability", "item_ankh_of_reincarnation"],
					late: ["item_astral_core", "item_tempest_aegis", "item_plagueheart"]
				})
			]
		};
	}

	function normalizePayload(payload) {
		payload = payload && typeof payload === "object" ? payload : {};
		var builds = toArray(payload.builds).slice(0, MAX_BUILDS).map(function (build, index) {
			build = build || {};
			return makeBuild(build.id || ("build_" + index), build.name, build.sections);
		});
		if (builds.length === 0) {
			return makeDefaultPayload();
		}
		var activeID = String(payload.active_build_id || builds[0].id);
		var activeFound = false;
		for (var i = 0; i < builds.length; i++) {
			if (builds[i].id === activeID) {
				activeFound = true;
				break;
			}
		}
		return {
			schema_version: SCHEMA_VERSION,
			active_build_id: activeFound ? activeID : builds[0].id,
			builds: builds
		};
	}

	function getHudRoot() {
		var panel = originalParent || root;
		while (panel && panel.GetParent()) {
			panel = panel.GetParent();
		}
		return panel;
	}

	function findHudElement(id) {
		var hud = getHudRoot();
		return hud && hud.FindChildTraverse ? hud.FindChildTraverse(id) : null;
	}

	function setVisible(panel, visible) {
		if (!panel) {
			return;
		}
		panel.style.visibility = visible ? "visible" : "collapse";
	}

	function guideButtonTravel(button) {
		var parent = button && button.GetParent ? button.GetParent() : null;
		var parentWidth = parent ? Number(parent.actuallayoutwidth || 0) : 0;
		var buttonWidth = button ? Number(button.actuallayoutwidth || 34) : 34;
		return Math.max(0, parentWidth - buttonWidth);
	}

	function updateGuideButtonAlignment(button, closed) {
		if (!button || state.guideClosed === closed) return;
		state.guideClosed = closed;
		state.guideAlignmentGeneration += 1;
		var generation = state.guideAlignmentGeneration;
		var travel = guideButtonTravel(button);

		if (closed) {
			button.style.transitionDuration = "0s";
			button.style.horizontalAlign = "right";
			button.style.transform = "translateX(-" + String(travel) + "px)";
			$.Schedule(0.0, function () {
				if (generation !== state.guideAlignmentGeneration || !button.IsValid()) return;
				button.style.transitionProperty = "transform";
				button.style.transitionDuration = "0.24s";
				button.style.transitionTimingFunction = "ease-in-out";
				button.style.transform = "translateX(0px)";
			});
			return;
		}

		button.style.transitionProperty = "transform";
		button.style.transitionDuration = "0.24s";
		button.style.transitionTimingFunction = "ease-in-out";
		button.style.horizontalAlign = "right";
		button.style.transform = "translateX(-" + String(travel) + "px)";
		$.Schedule(0.24, function () {
			if (generation !== state.guideAlignmentGeneration || !button.IsValid()) return;
			button.style.transitionDuration = "0s";
			button.style.horizontalAlign = "left";
			button.style.transform = "translateX(0px)";
			$.Schedule(0.0, function () {
				if (generation === state.guideAlignmentGeneration && button.IsValid()) button.style.transitionDuration = "0.24s";
			});
		});
	}

	function monitorGuideAlignment() {
		if (!root || !root.IsValid()) return;
		var guideFlyout = findHudElement("GuideFlyout");
		var guidesButtonV2 = findHudElement("GuidesButtonV2");
		if (guideFlyout && guidesButtonV2) {
			var closed = guideFlyout.BHasClass("HideGuide");
			if (state.guideClosed === null) {
				state.guideClosed = closed;
				guidesButtonV2.style.horizontalAlign = closed ? "right" : "left";
				guidesButtonV2.style.transform = "translateX(0px)";
			} else updateGuideButtonAlignment(guidesButtonV2, closed);
		}
		$.Schedule(0.03, monitorGuideAlignment);
	}

	function ensureNativeShopGuide() {
		if (!root || !root.IsValid()) {
			return;
		}

		GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_SHOP_SUGGESTEDITEMS, true);
		var itemBuildContainer = findHudElement("ItemBuildContainer");
		var guideFlyout = findHudElement("GuideFlyout");
		var guidesButton = findHudElement("GuidesButton");
		var guidesButtonV2 = findHudElement("GuidesButtonV2");
		var searchAndButtonsContainer = findHudElement("SearchAndButtonsContainer");
		var mainShopPanel = findHudElement("Main");
		var gridMainShopContentsV2 = findHudElement("GridMainShopContentsV2");
		var nativeItemBuild = findHudElement("ItemBuild");
		var nativePlusGuide = findHudElement("ItemPlusGuide");
		var shop = itemBuildContainer;

		while (shop && shop.paneltype !== "DOTAHUDShop") {
			shop = shop.GetParent();
		}

		if (shop) {
			shop.RemoveClass("GuidesDisabled");
			shop.RemoveClass("HideItemGuide");
			shop.RemoveClass("ForceDefaultGuide");
		}

		setVisible(itemBuildContainer, true);
		setVisible(guideFlyout, true);
		if (guideFlyout) {
			guideFlyout.style.width = "210px";
		}
		if (itemBuildContainer) {
			itemBuildContainer.style.width = "210px";
			itemBuildContainer.style.horizontalAlign = "left";
			itemBuildContainer.style.transform = "translateX(0px)";
		}
		setVisible(nativeItemBuild, false);
		setVisible(nativePlusGuide, false);

		var useV2Button = !!guidesButtonV2;
		if (guidesButtonV2) {
			guidesButtonV2.RemoveClass("XHSItemBuildGuideButtonSpacing");
			guidesButtonV2.style.width = "34px";
			guidesButtonV2.style.height = "34px";
			setVisible(guidesButtonV2, useV2Button);
		}
		if (guidesButton) {
			if (!useV2Button && mainShopPanel && mainShopPanel.actuallayoutwidth > 36) {
				guidesButton.style.marginRight = String(Math.round(mainShopPanel.actuallayoutwidth) - 36) + "px";
			}
			setVisible(guidesButton, !useV2Button);
		}
		if (searchAndButtonsContainer) {
			searchAndButtonsContainer.style.paddingLeft = "10px";
		}




		if (!state.nativeGuideInitialized && guideFlyout && (guidesButton || guidesButtonV2)) {
			guideFlyout.RemoveClass("HideGuide");
			state.nativeGuideInitialized = true;
		}

		if (itemBuildContainer && root.GetParent() !== itemBuildContainer) {
			root.SetParent(itemBuildContainer);
			state.nativeAttached = true;
		}

		if (state.nativeAttached) {
			setVisible(root, true);
		}


	}

	function currentHeroName() {
		var playerID = Players.GetLocalPlayer();
		var heroIndex = Players.GetPlayerHeroEntityIndex(playerID);
		var heroName = heroIndex !== -1 ? Entities.GetUnitName(heroIndex) : "";
		if (!heroName) {
			heroName = Players.GetPlayerSelectedHero(playerID) || "";
		}
		return String(heroName || "");
	}

	function heroDisplayName(heroName) {
		if (!heroName) {
			return localize("#xhs_item_builds_waiting_hero");
		}
		var localized = $.Localize("#" + heroName);
		if (localized && localized !== ("#" + heroName)) {
			return localized;
		}
		return heroName.replace("npc_dota_hero_", "").replace(/_/g, " ");
	}

	function setSaveState(kind, token) {
		var label = findLocalElement("XHSItemBuildSaveState");
		if (!label) {
			return;
		}
		label.RemoveClass("Saved");
		label.RemoveClass("Saving");
		label.RemoveClass("Loading");
		label.RemoveClass("Error");
		if (kind) {
			label.AddClass(kind);
		}
		label.text = localize(token);
	}

	function getActiveBuild() {
		var builds = state.payload ? state.payload.builds : [];
		if (!builds || builds.length === 0) {
			return null;
		}
		for (var i = 0; i < builds.length; i++) {
			if (builds[i].id === state.payload.active_build_id) {
				state.activeBuildIndex = i;
				return builds[i];
			}
		}
		state.activeBuildIndex = 0;
		state.payload.active_build_id = builds[0].id;
		return builds[0];
	}

	function clearPanel(panel) {
		if (panel) {
			panel.RemoveAndDeleteChildren();
		}
	}

	function attachItemTooltip(panel, itemName) {
		panel.SetPanelEvent("onmouseover", function () {
			$.DispatchEvent("DOTAShowAbilityTooltip", panel, itemName);
		});
		panel.SetPanelEvent("onmouseout", function () {
			$.DispatchEvent("DOTAHideAbilityTooltip", panel);
		});
	}

	function createViewItem(parent, itemName) {
		var item = $.CreatePanel("DOTAShopItem", parent, "");
		item.AddClass("XHSItemBuildShopItem");
		item.itemname = itemName;
		return item;
	}

	function moveItem(sectionKey, itemIndex, delta) {
		var build = getActiveBuild();
		if (!build) {
			return;
		}
		var items = build.sections[sectionKey];
		var destination = itemIndex + delta;
		if (destination < 0 || destination >= items.length) {
			return;
		}
		var value = items[itemIndex];
		items[itemIndex] = items[destination];
		items[destination] = value;
		render();
		queueSave();
	}

	function removeItem(sectionKey, itemIndex) {
		var build = getActiveBuild();
		if (!build) {
			return;
		}
		build.sections[sectionKey].splice(itemIndex, 1);
		render();
		queueSave();
	}

	function createItemControl(parent, labelText, className, callback) {
		var button = $.CreatePanel("Button", parent, "");
		button.AddClass("XHSItemBuildItemControl");
		if (className) {
			button.AddClass(className);
		}
		var label = $.CreatePanel("Label", button, "");
		label.text = labelText;
		button.SetPanelEvent("onactivate", callback);
		return button;
	}

	function createEditableItem(parent, sectionKey, itemName, itemIndex) {
		var wrapper = $.CreatePanel("Panel", parent, "");
		wrapper.AddClass("XHSItemBuildEditableItem");
		var image = $.CreatePanel("DOTAItemImage", wrapper, "");
		image.itemname = itemName;
		attachItemTooltip(image, itemName);
		var controls = $.CreatePanel("Panel", wrapper, "");
		controls.AddClass("XHSItemBuildItemControls");
		createItemControl(controls, "‹", "", function () {
			moveItem(sectionKey, itemIndex, -1);
		});
		createItemControl(controls, "›", "", function () {
			moveItem(sectionKey, itemIndex, 1);
		});
		createItemControl(controls, "×", "Delete", function () {
			removeItem(sectionKey, itemIndex);
		});
	}

	function openCatalog(sectionKey) {
		state.catalogSection = sectionKey;
		root.AddClass("CatalogOpen");
		var title = findLocalElement("XHSItemBuildCatalogTitle");
		title.text = localize("#xhs_item_builds_add_to") + " " + localize(SECTION_TOKENS[sectionKey]);
		findLocalElement("XHSItemBuildSearch").text = "";
		renderCatalog("");
	}

	function renderSections() {
		var container = findLocalElement("XHSItemBuildSections");
		clearPanel(container);
		var build = getActiveBuild();
		if (!build) {
			return;
		}

		for (var sectionIndex = 0; sectionIndex < SECTION_KEYS.length; sectionIndex++) {
			(function (sectionKey) {
				var section = $.CreatePanel("Panel", container, "");
				section.AddClass("XHSItemBuildSection");
				var header = $.CreatePanel("Panel", section, "");
				header.AddClass("XHSItemBuildSectionHeader");
				var title = $.CreatePanel("Label", header, "");
				title.AddClass("XHSItemBuildSectionTitle");
				title.text = localize(SECTION_TOKENS[sectionKey]);
				var add = $.CreatePanel("Button", header, "");
				add.AddClass("XHSItemBuildSectionAdd");
				var addLabel = $.CreatePanel("Label", add, "");
				addLabel.text = "+";
				add.SetPanelEvent("onactivate", function () {
					openCatalog(sectionKey);
				});
				var itemsPanel = $.CreatePanel("Panel", section, "");
				itemsPanel.AddClass("XHSItemBuildSectionItems");
				var items = build.sections[sectionKey] || [];
				if (items.length === 0) {
					var empty = $.CreatePanel("Label", itemsPanel, "");
					empty.AddClass("XHSItemBuildEmpty");
					empty.text = localize("#xhs_item_builds_empty");
				} else {
					for (var itemIndex = 0; itemIndex < items.length; itemIndex++) {
						if (state.editMode) {
							createEditableItem(itemsPanel, sectionKey, items[itemIndex], itemIndex);
						} else {
							createViewItem(itemsPanel, items[itemIndex]);
						}
					}
				}
			})(SECTION_KEYS[sectionIndex]);
		}
	}

	function render() {
		if (!root) {
			return;
		}
		root.SetHasClass("EditMode", state.editMode);
		root.SetHasClass("NoHero", !state.heroName);
		findLocalElement("XHSItemBuildHero").text = heroDisplayName(state.heroName);
		var build = getActiveBuild();
		findLocalElement("XHSItemBuildSelectorLabel").text = build ? build.name : localize("#xhs_item_builds_default_name");
		findLocalElement("XHSItemBuildEditLabel").text = localize(state.editMode ? "#xhs_item_builds_done" : "#xhs_item_builds_edit");
		renderSections();
	}

	function addCatalogItem(itemName) {
		var build = getActiveBuild();
		if (!build || !state.catalogSection) {
			return;
		}
		var items = build.sections[state.catalogSection];
		if (items.length >= MAX_ITEMS_PER_SECTION) {
			setSaveState("Error", "#xhs_item_builds_section_full");
			return;
		}
		items.push(itemName);
		root.RemoveClass("CatalogOpen");
		render();
		queueSave();
	}

	function itemDisplayName(itemName) {
		var localized = $.Localize("#DOTA_Tooltip_ability_" + itemName);
		if (localized && localized !== ("#DOTA_Tooltip_ability_" + itemName)) {
			return localized;
		}
		return itemName.replace(/^item_/, "").replace(/_/g, " ");
	}

	function renderCatalog(query) {
		var container = findLocalElement("XHSItemBuildCatalogItems");
		clearPanel(container);
		query = String(query || "").toLowerCase();
		var items = state.allowedItems.slice(0).sort(function (left, right) {
			var leftName = itemDisplayName(left);
			var rightName = itemDisplayName(right);
			return leftName < rightName ? -1 : (leftName > rightName ? 1 : 0);
		});
		for (var i = 0; i < items.length; i++) {
			(function (itemName) {
				if (query && itemName.toLowerCase().indexOf(query) === -1 && itemDisplayName(itemName).toLowerCase().indexOf(query) === -1) {
					return;
				}
				var button = $.CreatePanel("Button", container, "");
				button.AddClass("XHSItemBuildCatalogItem");
				var image = $.CreatePanel("DOTAItemImage", button, "");
				image.itemname = itemName;
				image.hittest = false;
				attachItemTooltip(button, itemName);
				button.SetPanelEvent("onactivate", function () {
					addCatalogItem(itemName);
				});
			})(items[i]);
		}
	}

	function setActiveBuild(index) {
		if (!state.payload || state.payload.builds.length === 0) {
			return;
		}
		var length = state.payload.builds.length;
		index = (index + length) % length;
		state.activeBuildIndex = index;
		state.payload.active_build_id = state.payload.builds[index].id;
		render();
		queueSave();
	}

	function showNameDialog(mode) {
		var build = getActiveBuild();
		state.nameDialogMode = mode;
		findLocalElement("XHSItemBuildNameDialogTitle").text = localize(mode === "new" ? "#xhs_item_builds_new" : "#xhs_item_builds_rename");
		findLocalElement("XHSItemBuildNameEntry").text = mode === "rename" && build ? build.name : "";
		root.AddClass("NameDialogOpen");
		findLocalElement("XHSItemBuildNameEntry").SetFocus();
	}

	function confirmNameDialog() {
		var name = String(findLocalElement("XHSItemBuildNameEntry").text || "").trim().substring(0, 32);
		if (!name) {
			return;
		}
		if (state.nameDialogMode === "new") {
			if (state.payload.builds.length >= MAX_BUILDS) {
				setSaveState("Error", "#xhs_item_builds_limit");
				root.RemoveClass("NameDialogOpen");
				return;
			}
			var id = "build_" + Date.now() + "_" + Math.floor(Math.random() * 100000);
			var build = makeBuild(id, name, {});
			state.payload.builds.push(build);
			state.payload.active_build_id = id;
			state.activeBuildIndex = state.payload.builds.length - 1;
		} else {
			var active = getActiveBuild();
			if (active) {
				active.name = name;
			}
		}
		root.RemoveClass("NameDialogOpen");
		render();
		queueSave();
	}

	function deleteActiveBuild() {
		if (!state.payload || state.payload.builds.length <= 1) {
			state.payload = makeDefaultPayload();
			state.activeBuildIndex = 0;
		} else {
			state.payload.builds.splice(state.activeBuildIndex, 1);
			state.activeBuildIndex = Math.max(0, state.activeBuildIndex - 1);
			state.payload.active_build_id = state.payload.builds[state.activeBuildIndex].id;
		}
		render();
		queueSave();
	}

	function makeRequestID(prefix, sequence) {
		return prefix + "_" + Date.now() + "_" + sequence;
	}

	function requestBuilds() {
		if (!state.heroName) {
			return;
		}
		state.loadSequence++;
		var requestID = makeRequestID("load", state.loadSequence);
		state.currentLoadRequestID = requestID;
		setSaveState("Loading", "#xhs_item_builds_loading");
		GameEvents.SendCustomGameEventToServer("xhs_item_builds_load", {
			request_id: requestID,
			hero_name: state.heroName,
			schema_version: SCHEMA_VERSION
		});
	}

	function onLoadResponse(data) {
		if (!data || data.request_id !== state.currentLoadRequestID || data.hero_name !== state.heroName) {
			return;
		}
		if (data.ok !== 1 && data.ok !== true) {
			state.loadAttempts++;
			state.payload = state.payload || makeDefaultPayload();
			render();
			setSaveState("Error", "#xhs_item_builds_load_error");
			if (state.loadAttempts < MAX_RETRY_ATTEMPTS) {
				var delay = Math.pow(2, state.loadAttempts - 1);
				$.Schedule(delay, function () {
					if (data.hero_name === state.heroName) {
						requestBuilds();
					}
				});
			}
			return;
		}
		state.loadAttempts = 0;
		state.mapScope = String(data.map_scope || "");
		state.revision = Number(data.revision || 0);
		state.allowedItems = toArray(data.allowed_items).filter(function (itemName) {
			return typeof itemName === "string";
		});
		if (state.allowedItems.length === 0) {
			state.allowedItems = FALLBACK_ALLOWED_ITEMS.slice(0);
		}
		state.payload = normalizePayload(data.payload);
		state.activeBuildIndex = 0;
		state.editMode = false;
		render();
		setSaveState("Saved", data.payload ? "#xhs_item_builds_saved" : "#xhs_item_builds_default");
	}

	function queueSave() {
		if (!state.heroName || !state.payload) {
			return;
		}
		state.saveDebounceGeneration++;
		var generation = state.saveDebounceGeneration;
		setSaveState("Saving", "#xhs_item_builds_unsaved");
		$.Schedule(SAVE_DEBOUNCE_SECONDS, function () {
			if (generation === state.saveDebounceGeneration) {
				startSave();
			}
		});
	}

	function startSave() {
		if (state.saveInFlight) {
			state.saveQueued = true;
			return;
		}
		state.saveSequence++;
		var requestID = makeRequestID("save", state.saveSequence);
		var idempotencyKey = state.heroName + ":" + Date.now() + ":" + state.saveSequence;
		state.saveInFlight = {
			request_id: requestID,
			idempotency_key: idempotencyKey,
			expected_revision: state.revision,
			hero_name: state.heroName,
			payload: clone(normalizePayload(state.payload)),
			attempts: 1
		};
		sendSaveInFlight();
	}

	function sendSaveInFlight() {
		var pending = state.saveInFlight;
		if (!pending) {
			return;
		}
		setSaveState("Saving", "#xhs_item_builds_saving");
		GameEvents.SendCustomGameEventToServer("xhs_item_builds_save", {
			request_id: pending.request_id,
			idempotency_key: pending.idempotency_key,
			expected_revision: pending.expected_revision,
			hero_name: pending.hero_name,
			schema_version: SCHEMA_VERSION,
			payload: pending.payload
		});
	}

	function onSaveResponse(data) {
		var pending = state.saveInFlight;
		if (!pending || !data || data.request_id !== pending.request_id) {
			return;
		}
		if (data.ok === 1 || data.ok === true) {
			state.revision = Number(data.revision || state.revision + 1);
			state.saveInFlight = null;
			setSaveState("Saved", "#xhs_item_builds_saved");
			if (state.saveQueued) {
				state.saveQueued = false;
				startSave();
			}
			return;
		}

		if (data.conflict === 1 || data.conflict === true) {
			state.revision = Number(data.revision || state.revision);
			pending.expected_revision = state.revision;
		}
		if (pending.attempts < MAX_RETRY_ATTEMPTS) {
			pending.attempts++;
			$.Schedule(Math.pow(2, pending.attempts - 2), function () {
				if (state.saveInFlight === pending && state.heroName === pending.hero_name) {
					sendSaveInFlight();
				}
			});
		} else {
			state.saveInFlight = null;
			state.saveQueued = true;
			setSaveState("Error", "#xhs_item_builds_save_error");
		}
	}

	function retryPendingSave() {
		if (state.saveQueued && !state.saveInFlight) {
			state.saveQueued = false;
			startSave();
		} else if (!state.payload) {
			requestBuilds();
		}
	}

	function bindEvents() {
		findLocalElement("XHSItemBuildPrevious").SetPanelEvent("onactivate", function () {
			setActiveBuild(state.activeBuildIndex - 1);
		});
		findLocalElement("XHSItemBuildNext").SetPanelEvent("onactivate", function () {
			setActiveBuild(state.activeBuildIndex + 1);
		});
		findLocalElement("XHSItemBuildSelector").SetPanelEvent("onactivate", function () {
			setActiveBuild(state.activeBuildIndex + 1);
		});
		findLocalElement("XHSItemBuildEdit").SetPanelEvent("onactivate", function () {
			state.editMode = !state.editMode;
			render();
		});
		findLocalElement("XHSItemBuildNew").SetPanelEvent("onactivate", function () {
			showNameDialog("new");
		});
		findLocalElement("XHSItemBuildRename").SetPanelEvent("onactivate", function () {
			showNameDialog("rename");
		});
		findLocalElement("XHSItemBuildDelete").SetPanelEvent("onactivate", deleteActiveBuild);
		findLocalElement("XHSItemBuildCatalogClose").SetPanelEvent("onactivate", function () {
			root.RemoveClass("CatalogOpen");
		});
		findLocalElement("XHSItemBuildSearch").SetPanelEvent("ontextentrychange", function () {
			renderCatalog(findLocalElement("XHSItemBuildSearch").text);
		});
		findLocalElement("XHSItemBuildNameCancel").SetPanelEvent("onactivate", function () {
			root.RemoveClass("NameDialogOpen");
		});
		findLocalElement("XHSItemBuildNameConfirm").SetPanelEvent("onactivate", confirmNameDialog);
		findLocalElement("XHSItemBuildNameEntry").SetPanelEvent("ontextentrysubmit", confirmNameDialog);
		findLocalElement("XHSItemBuildSaveState").SetPanelEvent("onactivate", retryPendingSave);
		GameEvents.Subscribe("xhs_item_builds_load_response", onLoadResponse);
		GameEvents.Subscribe("xhs_item_builds_save_response", onSaveResponse);
	}

	function poll() {
		ensureNativeShopGuide();
		var heroName = currentHeroName();
		if (heroName !== state.heroName) {
			state.heroName = heroName;
			state.mapScope = "";
			state.revision = 0;
			state.payload = heroName ? makeDefaultPayload() : null;
			state.activeBuildIndex = 0;
			state.editMode = false;
			state.saveInFlight = null;
			state.saveQueued = false;
			state.loadAttempts = 0;
			render();
			if (heroName) {
				requestBuilds();
			}
		}
		$.Schedule(0.5, poll);
	}

	if (!root) {
		return;
	}
	bindEvents();
	render();
	ensureNativeShopGuide();
	monitorGuideAlignment();
	poll();
})();
