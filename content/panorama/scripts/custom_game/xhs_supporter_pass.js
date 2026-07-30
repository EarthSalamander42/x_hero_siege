"use strict";

var XHSSupporterPass = (function () {
	var SUPPORTER_URL = "https://www.patreon.com/bePatron?u=2533325";
	var DISCORD_URL = "https://discord.frostrose-studio.com/";
	var DAILY_FRAGMENT_CAP = 100;
	var WEEKLY_FRAGMENT_CAP = DAILY_FRAGMENT_CAP;
	var SUPPORTER_PASS_LEVEL_COUNT = 50;
	var currentShopFilter = "All";
	var currentArmoryFilter = "All";
	var paginationState = {
		shop: { page: 0, page_size: 10 },
		armory: { page: 0, page_size: 10 },
		courier: { page: 0, page_size: 10 },
	};
	var courierRequestSerial = 0;
	var courierRequestState = {};
	var settingsOriginal = {};
	var settingsDraft = {};
	var settingsInitialized = false;
	var settingsSaving = false;
	var backToTopPollScheduled = false;
	var fragmentCounterInitialized = false;
	var lastLocalFragmentBalance = 0;
	var fragmentFlyoutIndex = 0;
	var actionToastSerial = 0;
	var pendingActions = {};
	var supporterLayerApplied = false;
	var supporterLayerRetryScheduled = false;
	var windowAnimationSerial = 0;
	var DEV_ASSET_FILTER = "Dev Assets";
	var devUnlockAllUI = false;
	var devSelectedAsset = "";
	var devAssetAssignments = {};
	var devTestRequestSerial = 0;
	var devTestState = {
		status: "idle",
		request_id: "",
		item_id: "",
		slot_id: "",
		message: "",
	};

	var PAGE_IDS = {
		overview: "XHSPassOverviewPage",
		rewards: "XHSPassRewardsPage",
		shop: "XHSPassShopPage",
		armory: "XHSPassArmoryPage",
		settings: "XHSPassSettingsPage",
	};

	var TAB_IDS = {
		overview: "XHSPassTabOverview",
		rewards: "XHSPassTabRewards",
		shop: "XHSPassTabShop",
		armory: "XHSPassTabArmory",
		settings: "XHSPassTabSettings",
	};

	var DISABLED_PAGES = {};

	var DEFAULT_TIERS = [
		{ id: 1, name: "Donator", price: "2\u20ac/month", color: "#70e39a", fragments: 150, xp_boost: 10, vote_power: 2 },
		{ id: 2, name: "Golden Donator", price: "4.50\u20ac/month", color: "#ffcf66", fragments: 400, xp_boost: 20, vote_power: 3 },
		{ id: 3, name: "Ember Donator", price: "9\u20ac/month", color: "#ff5a43", fragments: 900, xp_boost: 30, vote_power: 4 },
		{ id: 4, name: "Stoneguard Donator", price: "18\u20ac/month", color: "#5ad0ff", fragments: 1800, xp_boost: 40, vote_power: 5 },
		{ id: 5, name: "Earthwarden Donator", price: "27\u20ac/month", color: "#c99cff", fragments: 1800, xp_boost: 40, vote_power: 5, prestige: true },
	];

	var SITE_TIER_META = {
		1: {
			label: "#xhs_sp_tier_1_label",
			price: "2\u20ac/month",
			image: "patreon/donator_01_emerald.png",
			text: "#xhs_sp_tier_1_description",
			perks: ["#xhs_sp_perk_150_fragments", "#xhs_sp_perk_10_xp", "#xhs_sp_perk_2_votes", "#xhs_sp_perk_emerald", "#xhs_sp_perk_discord"],
		},
		2: {
			label: "#xhs_sp_tier_2_label",
			price: "4.50\u20ac/month",
			image: "patreon/donator_02_solar_gold.png",
			text: "#xhs_sp_tier_2_description",
			perks: ["#xhs_sp_perk_400_fragments", "#xhs_sp_perk_20_xp", "#xhs_sp_perk_3_votes", "#xhs_sp_perk_solar"],
			featured: true,
		},
		3: {
			label: "#xhs_sp_tier_3_label",
			price: "9\u20ac/month",
			image: "patreon/donator_03_ember_red.png",
			text: "#xhs_sp_tier_3_description",
			perks: ["#xhs_sp_perk_900_fragments", "#xhs_sp_perk_30_xp", "#xhs_sp_perk_4_votes", "#xhs_sp_perk_ember"],
		},
		4: {
			label: "#xhs_sp_tier_4_label",
			price: "18\u20ac/month",
			image: "patreon/donator_04_storm_blue.png",
			text: "#xhs_sp_tier_4_description",
			perks: ["#xhs_sp_perk_1800_fragments", "#xhs_sp_perk_40_xp", "#xhs_sp_perk_5_votes", "#xhs_sp_perk_storm"],
		},
		5: {
			label: "#xhs_sp_tier_5_label",
			price: "27\u20ac/month",
			image: "patreon/donator_05_amethyst_violet.png",
			text: "#xhs_sp_tier_5_description",
			perks: ["#xhs_sp_perk_1800_fragments", "#xhs_sp_perk_40_xp", "#xhs_sp_perk_5_votes", "#xhs_sp_perk_amethyst"],
		},
	};

	function Panel(id) {
		return $("#" + id);
	}

	function GetHudAncestor(panel) {
		var current = panel;
		while (current) {
			if (current.id === "Hud") {
				return current;
			}
			current = current.GetParent ? current.GetParent() : null;
		}
		return null;
	}

	function GetHudDirectChild(panel, hud) {
		var current = panel;
		var parent = current && current.GetParent ? current.GetParent() : null;
		while (current && parent && parent !== hud) {
			current = parent;
			parent = current.GetParent ? current.GetParent() : null;
		}
		return parent === hud ? current : null;
	}

	function ScheduleSupporterLayerRetry() {
		if (supporterLayerApplied || supporterLayerRetryScheduled) {
			return;
		}

		supporterLayerRetryScheduled = true;
		$.Schedule(0.5, function () {
			supporterLayerRetryScheduled = false;
			EnsureSupporterPassAboveVanillaHud();
		});
	}

	function EnsureSupporterPassAboveVanillaHud() {
		if (supporterLayerApplied) {
			return true;
		}

		var host = $.GetContextPanel();
		if (!host || typeof FindDotaHudElement !== "function") {
			ScheduleSupporterLayerRetry();
			return false;
		}

		var hudElements = FindDotaHudElement("HUDElements");
		var hud = GetHudAncestor(hudElements) || GetHudAncestor(host);
		var hudElementsChild = GetHudDirectChild(hudElements, hud);
		if (!hud || !hudElementsChild || typeof host.SetParent !== "function" || typeof hud.MoveChildAfter !== "function") {
			ScheduleSupporterLayerRetry();
			return false;
		}

		try {
			if (host.GetParent && host.GetParent() !== hud) {
				host.SetParent(hud);
			}

			if (!host.GetParent || host.GetParent() !== hud) {
				ScheduleSupporterLayerRetry();
				return false;
			}

			hud.MoveChildAfter(host, hudElementsChild);
			supporterLayerApplied = true;
			return true;
		} catch (error) {
			ScheduleSupporterLayerRetry();
			return false;
		}
	}

	function Safe(callback, fallbackValue) {
		try {
			var value = callback();
			return value === undefined || value === null ? fallbackValue : value;
		} catch (error) {
			return fallbackValue;
		}
	}

	function ToNumber(value, fallbackValue) {
		var numberValue = Number(value);
		if (isNaN(numberValue)) {
			return fallbackValue || 0;
		}
		return numberValue;
	}

	function Clamp(value, minValue, maxValue) {
		return Math.max(minValue, Math.min(maxValue, value));
	}

	function IsEarthwardenSupporterData(data) {
		if (!data) {
			return false;
		}

		var donatorLevel = Math.floor(ToNumber(data.donator_level || data.donator_status, 0));
		if (donatorLevel === 8 || donatorLevel === 9) {
			return true;
		}

		var tierName = (data.tier_name || data.supporter_tier_name || "").toString().toLowerCase();
		if (tierName.indexOf("earthwarden") >= 0) {
			return true;
		}

		var tierColor = (data.tier_color || "").toString().toLowerCase();
		return tierColor === "#c99cff";
	}

	function NormalizeSupporterTierID(tierID, data) {
		if (IsEarthwardenSupporterData(data)) {
			return 5;
		}

		var normalizedTier = Math.floor(ToNumber(tierID, 0));
		var statusToTier = {
			6: 1,
			7: 4,
			8: 5,
			9: 5
		};

		if (normalizedTier > 5 && statusToTier[normalizedTier] !== undefined) {
			normalizedTier = statusToTier[normalizedTier];
		}

		return Clamp(normalizedTier, 0, 5);
	}

	function NormalizeSupporterTierColor(data, tierID) {
		if (IsEarthwardenSupporterData(data)) {
			return "#c99cff";
		}

		return data.tier_color || GetTierColorByID(tierID);
	}

	function Localize(value) {
		if (!value) {
			return "";
		}

		var localized = $.Localize(value);
		return localized === value ? value.replace("#", "") : localized;
	}

	function Text(key, fallbackValue, replacements) {
		var token = key && key.charAt(0) === "#" ? key : "#" + key;
		var localized = $.Localize(token);
		var value = localized === token ? (fallbackValue || token.replace("#", "")) : localized;
		replacements = replacements || {};
		for (var replacement in replacements) {
			if (replacements.hasOwnProperty(replacement)) {
				value = value.replace("{" + replacement + "}", replacements[replacement]);
			}
		}
		return value;
	}

	function LocalizeMaybeKey(value) {
		if (!value) {
			return "";
		}

		if (typeof value === "string" && value.charAt(0) === "#") {
			return Localize(value);
		}

		return Localize("#" + value);
	}

	function NormalizeImagePath(imagePath) {
		if (!imagePath) {
			return "";
		}

		var path = imagePath.toString();
		path = path.replace(/\\/g, "/");
		path = path.replace(/^file:\/\/\{images\}\//, "");
		path = path.replace(/^s2r:\/\/panorama\/images\//, "");
		path = path.replace(/_png\.vtex$/, "");
		path = path.replace(/\.png$/, "");
		return path;
	}

	function ResolveImageURL(imagePath) {
		var rawImagePath = imagePath ? imagePath.toString().replace(/\\/g, "/") : "";
		if (rawImagePath.indexOf("s2r://panorama/images/") === 0 || rawImagePath.indexOf("file://{images}/") === 0) {
			return rawImagePath;
		}

		var normalized = NormalizeImagePath(imagePath);
		if (!normalized) {
			return "";
		}

		if (normalized.indexOf("custom_game/") === 0) {
			return "file://{images}/" + normalized + ".png";
		}

		var dotaRoots = ["badges/", "battlepass/", "compendium/", "econ/", "events/", "game_modes/", "heroes/", "items/", "spellicons/", "status_icons/"];
		for (var i = 0; i < dotaRoots.length; i++) {
			if (normalized.indexOf(dotaRoots[i]) === 0) {
				return "s2r://panorama/images/" + normalized + "_png.vtex";
			}
		}

		return "file://{images}/custom_game/" + normalized + ".png";
	}

	function SetCustomGameImage(panel, imagePath) {
		var imageURL = ResolveImageURL(imagePath);
		if (panel && imageURL) {
			panel.style.backgroundImage = 'url("' + imageURL + '")';
			panel.style.backgroundSize = "contain";
			panel.style.backgroundPosition = "50% 50%";
			panel.style.backgroundRepeat = "no-repeat";
		}
	}

	function ApplyItemVisualClasses(panel, item, track) {
		if (!panel) {
			return;
		}

		var type = NormalizeRewardType(item && (item.type || item.item_type));
		var typeClasses = {
			"Teleport FX": "ItemTypeTeleport",
			"Tome FX": "ItemTypeTome",
			"Kill FX": "ItemTypeKill",
			"Emblem": "ItemTypeEmblem",
			"Companion": "ItemTypeCompanion",
			"Effigy": "ItemTypeEffigy",
			"Potion FX": "ItemTypePotion",
			"Rebirth FX": "ItemTypeRebirth",
			"Attack Lifesteal": "ItemTypeAttackLifesteal",
			"Spell Lifesteal": "ItemTypeSpellLifesteal",
			"Regen Aura": "ItemTypeRegenAura",
			"Immolation": "ItemTypeImmolation",
			"High Five": "ItemTypeHighFive",
			"Title": "ItemTypeTitle",
			"Fragments": "ItemTypeFragments",
			"Bundle": "ItemTypeBundle",
			"Cosmetic": "ItemTypeCosmetic",
		};
		var rarity = ((item && (item.rarity || item.item_rarity)) || "common").toString().toLowerCase();
		var rarityClasses = {
			common: "RarityCommon",
			uncommon: "RarityUncommon",
			rare: "RarityRare",
			mythical: "RarityMythical",
			legendary: "RarityLegendary",
			immortal: "RarityImmortal",
			arcana: "RarityArcana",
			premium: "RarityPremium",
			supporter: "RaritySupporter",
			season: "RaritySeason",
		};

		panel.AddClass(typeClasses[type] || "ItemTypeCosmetic");
		panel.AddClass(rarityClasses[rarity] || "RarityCommon");
		panel.SetHasClass("IsPremiumTrack", track === "premium" || (item && item.track === "premium") || IsTruthy(item && item.premium, false));
	}

	function GetScenePreviewUnit(item) {
		if (!item) {
			return "";
		}

		var type = NormalizeRewardType(item.type || item.item_type);
		if (type !== "Companion" && type !== "Effigy") {
			return "";
		}
		var unit = item.unit || item.unit_name || item.file || item.npc_name || "";
		return unit && unit.toString().indexOf("npc_") === 0 ? unit.toString() : "";
	}

	function GetRewardComposition(item) {
		var type = NormalizeRewardType(item && (item.type || item.item_type || item.slot_id));
		if (type === "Potion FX") {
			return Text("xhs_sp_composition_potion", "Health + Mana + Light");
		}
		if (type === "Immolation") {
			return Text("xhs_sp_composition_immolation", "Owner + Targets");
		}
		if (type === "High Five") {
			return Text("xhs_sp_composition_high_five", "Overhead + Travel + Impact");
		}
		return "";
	}

	function CreateItemPreview(parent, item, previewClass, imageClass) {
		var preview = $.CreatePanel("Panel", parent, "");
		preview.AddClass("XHSPassItemPreview");
		preview.AddClass(previewClass);

		var image = $.CreatePanel("Panel", preview, "");
		image.AddClass("XHSPassPreviewImage");
		image.AddClass(imageClass);
		SetCustomGameImage(image, item && (item.image || item.image_inventory || item.icon || item.icon_path));

		var unit = GetScenePreviewUnit(item);
		if (unit) {
			preview.AddClass("HasAnimatedModel");
			parent.AddClass("HasAnimatedPreview");
			var scene = $.CreatePanel("DOTAScenePanel", preview, "", {
				"class": "XHSPassCompanionScene",
				environment: "default",
				hittest: "false",
				particleonly: "false",
				unit: unit,
			});
			scene.AddClass("XHSPassCompanionScene");
			scene.SetHasClass("IsEffigyScene", NormalizeRewardType(item.type || item.item_type) === "Effigy");
			scene.hittest = false;
		}

		var composition = GetRewardComposition(item);
		if (composition) {
			var compositionBadge = $.CreatePanel("Label", preview, "");
			compositionBadge.AddClass("XHSPassCompositionBadge");
			compositionBadge.text = composition;
		}
		return preview;
	}

	function GetCourierCatalog() {
		if (typeof XHSSupporterCourierCatalog === "undefined" || !XHSSupporterCourierCatalog) {
			return [];
		}
		return XHSSupporterCourierCatalog;
	}

	function ResetPagination(key) {
		if (paginationState[key]) {
			paginationState[key].page = 0;
		}
	}

	function GetPageSlice(items, key) {
		var state = paginationState[key];
		var totalPages = Math.max(1, Math.ceil(items.length / state.page_size));
		state.page = Clamp(state.page, 0, totalPages - 1);
		var start = state.page * state.page_size;
		return items.slice(start, start + state.page_size);
	}

	function RenderPaginationControls(parentID, key, totalItems, rerender) {
		var parent = Panel(parentID);
		ClearPanel(parent);
		if (!parent) {
			return;
		}

		var state = paginationState[key];
		var totalPages = Math.max(1, Math.ceil(totalItems / state.page_size));
		state.page = Clamp(state.page, 0, totalPages - 1);
		parent.SetHasClass("IsEmpty", totalItems === 0);

		var count = $.CreatePanel("Label", parent, "");
		count.AddClass("XHSPassPaginationCount");
		count.text = Text("xhs_sp_pagination_count", "{first}-{last} of {total}", {
			first: totalItems ? state.page * state.page_size + 1 : 0,
			last: Math.min(totalItems, (state.page + 1) * state.page_size),
			total: totalItems,
		});

		var controls = $.CreatePanel("Panel", parent, "");
		controls.AddClass("XHSPassPaginationControls");

		var previous = $.CreatePanel("Button", controls, "");
		previous.AddClass("XHSPassPaginationButton");
		previous.SetHasClass("IsDisabled", state.page <= 0);
		previous.SetPanelEvent("onactivate", function () {
			if (state.page <= 0) {
				Game.EmitSound("General.Cancel");
				return;
			}
			state.page--;
			rerender();
		});
		var previousLabel = $.CreatePanel("Label", previous, "");
		previousLabel.text = Text("xhs_sp_previous_page", "Previous");

		var pageLabel = $.CreatePanel("Label", controls, "");
		pageLabel.AddClass("XHSPassPaginationPage");
		pageLabel.text = Text("xhs_sp_page_value", "Page {page} / {pages}", {
			page: state.page + 1,
			pages: totalPages,
		});

		var next = $.CreatePanel("Button", controls, "");
		next.AddClass("XHSPassPaginationButton");
		next.SetHasClass("IsDisabled", state.page >= totalPages - 1);
		next.SetPanelEvent("onactivate", function () {
			if (state.page >= totalPages - 1) {
				Game.EmitSound("General.Cancel");
				return;
			}
			state.page++;
			rerender();
		});
		var nextLabel = $.CreatePanel("Label", next, "");
		nextLabel.text = Text("xhs_sp_next_page", "Next");

		var perPageLabel = $.CreatePanel("Label", controls, "");
		perPageLabel.AddClass("XHSPassPaginationPerPageLabel");
		perPageLabel.text = Text("xhs_sp_per_page", "Per page");

		var selector = $.CreatePanel("Panel", controls, "XHSPassPageSize_" + key);
		selector.AddClass("XHSPassPaginationSelect");
		var selectorButton = $.CreatePanel("Button", selector, "");
		selectorButton.AddClass("XHSPassPaginationSelectButton");
		var selectedLabel = $.CreatePanel("Label", selectorButton, "");
		selectedLabel.AddClass("XHSPassPaginationSelectedValue");
		selectedLabel.text = state.page_size.toString();
		var selectorArrow = $.CreatePanel("Label", selectorButton, "");
		selectorArrow.AddClass("XHSPassPaginationSelectArrow");
		selectorArrow.text = "▼";

		var selectorMenu = $.CreatePanel("Panel", selector, "");
		selectorMenu.AddClass("XHSPassPaginationSelectMenu");
		var sizes = [10, 25];
		for (var i = 0; i < sizes.length; i++) {
			(function (size) {
				var option = $.CreatePanel("Button", selectorMenu, "XHSPassPageSize_" + key + "_" + size);
				option.AddClass("XHSPassPaginationSelectOption");
				option.SetHasClass("IsSelected", size === state.page_size);
				var optionLabel = $.CreatePanel("Label", option, "");
				optionLabel.text = size.toString();
				option.SetPanelEvent("onactivate", function () {
					state.page_size = size;
					state.page = 0;
					selector.SetHasClass("IsOpen", false);
					rerender();
				});
			})(sizes[i]);
		}

		selectorButton.SetPanelEvent("onactivate", function () {
			selector.SetHasClass("IsOpen", !selector.BHasClass("IsOpen"));
		});
	}

	function ApplySupporterTierClasses(panel, tierID) {
		if (!panel) {
			return;
		}

		var normalizedTier = NormalizeSupporterTierID(tierID);
		panel.SetHasClass("HasSupporterTier", normalizedTier > 0);
		for (var tier = 0; tier <= 5; tier++) {
			panel.SetHasClass("SupporterTier" + tier, tier === normalizedTier);
		}
	}

	function FormatNumber(value) {
		var numberValue = ToNumber(value, 0);
		var absValue = Math.abs(numberValue);
		var sign = numberValue < 0 ? "-" : "";

		if (absValue >= 1000000) {
			return sign + (absValue / 1000000).toFixed(1) + "M";
		}

		if (absValue >= 10000) {
			return sign + (absValue / 1000).toFixed(1) + "k";
		}

		return sign + Math.floor(absValue).toString();
	}

	function FormatVotePower(value) {
		var votes = Math.max(1, Math.floor(ToNumber(value, 1)));
		return Text(votes > 1 ? "xhs_sp_votes" : "xhs_sp_vote", votes > 1 ? "{count} votes" : "{count} vote", { count: votes });
	}

	function AsArray(value) {
		if (!value) {
			return [];
		}

		if (Object.prototype.toString.call(value) === "[object Array]") {
			return value;
		}

		if (typeof value !== "object") {
			return [];
		}

		if (value.item_id !== undefined || value.id !== undefined || value.entitlement_id !== undefined || value.unit !== undefined) {
			return [value];
		}

		var keys = [];
		for (var rawKey in value) {
			if (value.hasOwnProperty(rawKey)) {
				keys.push(rawKey);
			}
		}

		if (keys.length === 1 && keys[0] === "1" && value["1"] && typeof value["1"] === "object") {
			return AsArray(value["1"]);
		}

		var result = [];
		var numericKeys = [];
		for (var i = 0; i < keys.length; i++) {
			if (/^\d+$/.test(keys[i])) {
				numericKeys.push(keys[i]);
			}
		}

		if (numericKeys.length > 0) {
			numericKeys.sort(function (a, b) { return Number(a) - Number(b); });
			for (var n = 0; n < numericKeys.length; n++) {
				if (value[numericKeys[n]] && typeof value[numericKeys[n]] === "object") {
					result.push(value[numericKeys[n]]);
				}
			}
			return result;
		}

		for (var key in value) {
			if (value.hasOwnProperty(key) && value[key] && typeof value[key] === "object") {
				result.push(value[key]);
			}
		}
		result.sort(function (a, b) {
			return ToNumber(a.level || a.rank || a.id, 0) - ToNumber(b.level || b.rank || b.id, 0);
		});

		return result;
	}

	function CopyObject(source) {
		var result = {};
		for (var key in source) {
			if (source.hasOwnProperty(key)) {
				result[key] = source[key];
			}
		}
		return result;
	}

	function SetActionPending(kind, id, pending) {
		var key = kind + ":" + (id || "");
		if (pending) {
			pendingActions[key] = true;
			$.Schedule(10.0, function () {
				if (pendingActions[key] !== true) {
					return;
				}
				delete pendingActions[key];
				ShowActionMessage(Text("xhs_sp_action_timeout", "The request timed out."), false);
				RenderAll();
			});
		} else {
			delete pendingActions[key];
		}
	}

	function IsActionPending(kind, id) {
		return pendingActions[kind + ":" + (id || "")] === true;
	}

	function ClearPanel(panel) {
		if (panel) {
			panel.RemoveAndDeleteChildren();
		}
	}

	function NormalizeSeasonProgress(level, xp, maxXp) {
		var normalizedLevel = Math.max(1, ToNumber(level, 1));
		var normalizedMax = Math.max(ToNumber(maxXp, 1000), 1);
		var normalizedXP = Math.max(0, ToNumber(xp, 0));

		if (normalizedXP >= normalizedMax) {
			var completedLevels = Math.floor(normalizedXP / normalizedMax);
			normalizedXP = normalizedXP - completedLevels * normalizedMax;
			normalizedLevel = Math.max(normalizedLevel, 1 + completedLevels);
		}

		return {
			level: normalizedLevel,
			xp: normalizedXP,
			maxXp: normalizedMax,
		};
	}

	function GetTable(tableName, keyName, fallbackValue) {
		return CustomNetTables.GetTableValue(tableName, keyName) || fallbackValue;
	}

	function GetTrackChunkKey(index, chunkIndex) {
		var keys = index && index.chunk_keys;
		if (Object.prototype.toString.call(keys) === "[object Array]") {
			return keys[chunkIndex - 1] || "";
		}
		if (keys && typeof keys === "object") {
			return keys[chunkIndex] || keys[chunkIndex.toString()] || "";
		}
		return "";
	}

	function GetPublishedRewardArray(tableName) {
		var index = GetTable(tableName, "rewards", {});
		var chunkCount = Math.max(0, Math.floor(ToNumber(index && index.chunk_count, 0)));
		if (chunkCount <= 0) {
			return AsArray(index);
		}

		var rewards = [];
		for (var chunkIndex = 1; chunkIndex <= chunkCount; chunkIndex++) {
			var key = GetTrackChunkKey(index, chunkIndex);
			if (!key) {
				key = "chunk_" + (chunkIndex < 10 ? "0" : "") + chunkIndex;
			}
			var chunk = AsArray(GetTable(tableName, key, []));
			for (var rewardIndex = 0; rewardIndex < chunk.length; rewardIndex++) {
				rewards.push(chunk[rewardIndex]);
			}
		}
		return rewards;
	}

	function CopyMissingFields(target, source) {
		if (!target || !source) {
			return target || {};
		}

		for (var key in source) {
			if (source.hasOwnProperty(key) && target[key] === undefined) {
				target[key] = source[key];
			}
		}

		return target;
	}

	function GetLocalPlayerData() {
		var playerID = Players.GetLocalPlayer();
		var data = GetTable("supporter_pass_player", playerID.toString(), {}) || {};
		var legacyData = GetTable("battlepass_player", playerID.toString(), null) || GetTable("battlepass_player", playerID, null);
		data = CopyMissingFields(data, legacyData);
		var info = Safe(function () { return Game.GetPlayerInfo(playerID); }, {});
		var tierID = NormalizeSupporterTierID(data.tier_id || data.supporter_tier || data.donator_level || 0, data);
		var season = NormalizeSeasonProgress(
			data.season_level !== undefined ? data.season_level : data.Lvl,
			data.season_xp !== undefined ? data.season_xp : data.XP,
			data.season_xp_max !== undefined ? data.season_xp_max : data.MaxXP
		);

		return {
			id: playerID,
			name: Safe(function () { return Players.GetPlayerName(playerID); }, info.player_name || Text("xhs_sp_player", "Player")),
			hero: Safe(function () { return Players.GetPlayerSelectedHero(playerID); }, info.player_selected_hero || ""),
			steamID: info.player_steamid || "",
			tier_id: tierID,
			tier_name: data.tier_name || Text("xhs_sp_free_player", "Free Player"),
			tier_color: NormalizeSupporterTierColor(data, tierID),
			fragments: ToNumber(data.fragments || data.fragment_balance, 0),
			has_fragment_balance: data.fragments !== undefined || data.fragment_balance !== undefined,
			daily_fragments: ToNumber(data.daily_fragments || data.daily_earned || data.weekly_fragments || data.weekly_earned, 0),
			daily_cap: ToNumber(data.daily_cap || data.weekly_cap, DAILY_FRAGMENT_CAP),
			weekly_fragments: ToNumber(data.daily_fragments || data.daily_earned || data.weekly_fragments || data.weekly_earned, 0),
			weekly_cap: ToNumber(data.daily_cap || data.weekly_cap, DAILY_FRAGMENT_CAP),
			xp_boost: ToNumber(data.xp_boost, 0),
			base_xp_change: ToNumber(data.base_xp_change, 0),
			xp_bonus: ToNumber(data.xp_bonus, 0),
			vote_power: Math.max(1, ToNumber(data.vote_power, tierID > 0 ? Math.min(tierID + 1, 5) : 1)),
			season_level: season.level,
			season_xp: season.xp,
			season_xp_max: season.maxXp,
			account_level: ToNumber(data.account_level !== undefined ? data.account_level : data.legacy_level, 0),
			xhs_account_level: ToNumber(data.xhs_account_level, 0),
			xhs_xp_current: ToNumber(data.xhs_xp_current, 0),
			xhs_xp_max: ToNumber(data.xhs_xp_max, 0),
			xhs_xp_total: ToNumber(data.xhs_xp, 0),
			supporter_url: data.supporter_url || SUPPORTER_URL,
			raw: data,
		};
	}

	function ResolveLocalPlayerIdentity(player) {
		player = player || {};
		if (typeof XHSNameDisplay !== "undefined" && XHSNameDisplay.Resolve) {
			return XHSNameDisplay.Resolve({
				playerID: player.id,
				playerName: player.name,
				heroName: player.hero,
			});
		}

		// Privacy-safe fallback: never expose the persona name.
		var heroName = player.hero || "";
		var localized = heroName ? $.Localize("#" + heroName) : "";
		return localized && localized !== ("#" + heroName) ? localized : "";
	}

	function IsLocalSupporterDeveloper(player) {
		if (!player) {
			return false;
		}

		var raw = player.raw || {};
		if (IsTruthy(raw.is_developer, false)) {
			return true;
		}
		if (Safe(function () { return Game.IsInToolsMode(); }, false)) {
			return true;
		}

		var rawStatus = ToNumber(
			raw.raw_donator_level !== undefined ? raw.raw_donator_level : raw.donator_level,
			0
		);
		if (rawStatus === 1 || rawStatus === 2) {
			return true;
		}

		var developers = GetTable("game_options", "donators", {}) || {};
		var steamID = (player.steamID || "").toString();
		for (var key in developers) {
			if (!developers.hasOwnProperty(key)) {
				continue;
			}
			var entry = developers[key];
			var entrySteamID = "";
			var entryStatus = 0;
			if (entry && typeof entry === "object") {
				entrySteamID = (entry.steamid || entry.steam_id || key || "").toString();
				entryStatus = ToNumber(entry.status || entry.donator_level, 0);
			} else {
				entrySteamID = key.toString();
				entryStatus = ToNumber(entry, 0);
			}
			if (entrySteamID === steamID && (entryStatus === 1 || entryStatus === 2)) {
				return true;
			}
		}
		return false;
	}

	function IsDevUnlockAllUIActive(player) {
		return devUnlockAllUI === true && IsLocalSupporterDeveloper(player);
	}

	function FormatXHSAccountXPSummary(player) {
		var level = Math.max(0, ToNumber(player.xhs_account_level, 0));
		var total = Math.max(0, ToNumber(player.xhs_xp_total, 0));
		var current = Math.max(0, ToNumber(player.xhs_xp_current, 0));
		var max = Math.max(0, ToNumber(player.xhs_xp_max, 0));

		if (level <= 0 && total <= 0 && current <= 0 && max <= 0) {
			return "-";
		}

		if (total > 0) {
			return "L" + Math.max(1, level) + " " + FormatNumber(total);
		}

		if (max > 0) {
			return "L" + Math.max(1, level) + " " + FormatNumber(current) + "/" + FormatNumber(max);
		}

		return "L" + Math.max(1, level);
	}

	function FormatSupporterXPSummary(player) {
		return "L" + player.season_level + " " + FormatNumber(player.season_xp) + "/" + FormatNumber(player.season_xp_max);
	}

	function GetTiers() {
		return AsArray(GetTable("supporter_pass_meta", "tiers", DEFAULT_TIERS));
	}

	function GetTierMeta(tier) {
		var tierID = ToNumber(tier.id || tier.tier_id, 0);
		var meta = SITE_TIER_META[tierID] || {};
		return {
			id: tierID,
			label: LocalizeMaybeKey(meta.label || Text("xhs_sp_tier_value", "Tier {tier}", { tier: tierID })),
			name: Text("xhs_sp_tier_" + tierID + "_name", tier.name || meta.name || "Supporter"),
			price: meta.price || tier.price || "",
			text: LocalizeMaybeKey(meta.text || ""),
			perks: (meta.perks || [
				FormatNumber(tier.fragments || 0) + " " + Text("xhs_sp_fragments_lower", "fragments"),
				"+" + FormatNumber(tier.xp_boost || 0) + "% " + Text("xhs_sp_xp", "XP"),
				FormatVotePower(tier.vote_power || (tierID > 0 ? Math.min(tierID + 1, 5) : 1)),
			]).map(function (perk) { return LocalizeMaybeKey(perk); }),
			image: meta.image || tier.image || "",
			color: tier.color || meta.color || "#5ad0ff",
			featured: meta.featured === true,
		};
	}

	function GetTierColorByID(tierID) {
		var normalizedTier = NormalizeSupporterTierID(tierID);
		if (normalizedTier <= 0) {
			return "#7db9d8";
		}

		var tiers = GetTiers();
		for (var i = 0; i < tiers.length; i++) {
			var tier = tiers[i] || {};
			var currentTierID = ToNumber(tier.id || tier.tier_id, 0);
			if (currentTierID === normalizedTier && tier.color) {
				return tier.color;
			}
		}

		for (var j = 0; j < DEFAULT_TIERS.length; j++) {
			if (DEFAULT_TIERS[j].id === normalizedTier) {
				return DEFAULT_TIERS[j].color;
			}
		}

		return "#5ad0ff";
	}

	function GetRewards(track) {
		var tableName = "supporter_pass_rewards_free";
		if (track === "premium") {
			tableName = "supporter_pass_rewards_premium";
		}

		var publishedRewards = GetPublishedRewardArray(tableName);
		var rewardsByLevel = {};
		function RewardPriority(reward) {
			var priority = 0;
			var seasonID = (reward.season_id || reward.season || "").toString();
			var rewardID = (reward.reward_id || reward.id || "").toString().toLowerCase();
			if (seasonID === "2026") {
				priority += 100;
			}
			if (rewardID.indexOf("sp26_") === 0) {
				priority += 50;
			}
			if (!IsTruthy(reward.legacy, false)) {
				priority += 20;
			}
			if (ToNumber(reward.item_id || reward.catalog_item_id, 0) >= 41) {
				priority += 10;
			}
			if (reward.slot_id && (reward.image || reward.image_inventory || reward.icon || reward.icon_path)) {
				priority += 5;
			}
			return priority;
		}

		for (var i = 0; i < publishedRewards.length; i++) {
			var reward = CopyObject(publishedRewards[i]);
			var level = Math.floor(ToNumber(reward.level_required || reward.level, 0));
			if (level < 1 || level > SUPPORTER_PASS_LEVEL_COUNT) {
				continue;
			}

			reward.level = level;
			reward.level_required = level;
			reward.track = track;
			reward.legacy = IsTruthy(reward.legacy, false);
			reward.claimable = reward.claimable === undefined
				? !reward.legacy
				: IsTruthy(reward.claimable, false);

			var previous = rewardsByLevel[level];
			if (!previous || RewardPriority(reward) >= RewardPriority(previous)) {
				rewardsByLevel[level] = reward;
			}
		}

		var rewards = [];
		for (var levelIndex = 1; levelIndex <= SUPPORTER_PASS_LEVEL_COUNT; levelIndex++) {
			if (rewardsByLevel[levelIndex]) {
				rewards.push(rewardsByLevel[levelIndex]);
			}
		}
		return rewards;
	}

	function GetRewardID(reward) {
		if (!reward) {
			return "";
		}

		return (reward.reward_id || reward.id || reward.item_id || "").toString();
	}

	function RewardValueMatches(value, reward, rewardID) {
		if (value === undefined || value === null) {
			return false;
		}

		if (typeof value === "object") {
			return RewardValueMatches(value.reward_id, reward, rewardID) ||
				RewardValueMatches(value.id, reward, rewardID) ||
				RewardValueMatches(value.item_id, reward, rewardID) ||
				RewardValueMatches(value.name, reward, rewardID);
		}

		var stringValue = value.toString();
		return stringValue === rewardID ||
			stringValue === (reward.item_id || "").toString() ||
			stringValue === (reward.id || "").toString() ||
			stringValue === (reward.name || "").toString();
	}

	function IsRewardClaimed(reward, player) {
		var rewardID = GetRewardID(reward);
		if (rewardID === "") {
			return false;
		}

		var claimed = player.raw && player.raw.claimed_rewards;
		if (!claimed) {
			return false;
		}

		if (Object.prototype.toString.call(claimed) === "[object Array]") {
			for (var i = 0; i < claimed.length; i++) {
				if (RewardValueMatches(claimed[i], reward, rewardID)) {
					return true;
				}
			}
			return false;
		}

		if (typeof claimed === "object") {
			if (IsTruthy(claimed[rewardID], false) || IsTruthy(claimed[reward.item_id], false) || IsTruthy(claimed[reward.id], false)) {
				return true;
			}

			for (var key in claimed) {
				if (claimed.hasOwnProperty(key) && (key === rewardID || RewardValueMatches(claimed[key], reward, rewardID))) {
					return true;
				}
			}
		}

		return false;
	}

	function IsLegacyRewardUnlocked(reward, player, track) {
		var requiredLevel = ToNumber(reward.level_required || reward.level, 1);
		var premium = track === "premium" || reward.track === "premium" || IsTruthy(reward.premium, false);
		return player.season_level >= requiredLevel && (!premium || player.tier_id > 0) && !IsTruthy(reward.item_unreleased, false);
	}

	function NormalizeRewardType(type) {
		var normalized = (type || "cosmetic").toString().toLowerCase();
		if (normalized === "teleport" || normalized === "teleport_fx" || normalized === "teleport fx") {
			return "Teleport FX";
		}
		if (normalized === "levelup" || normalized === "tome" || normalized === "tome_fx" || normalized === "tome fx") {
			return "Tome FX";
		}
		if (normalized === "kill_effect" || normalized === "kill_fx" || normalized === "kill fx") {
			return "Kill FX";
		}
		if (normalized === "emblem") {
			return "Emblem";
		}
		if (normalized === "courier" || normalized === "companion") {
			return "Companion";
		}
		if (normalized === "effigy" || normalized === "statue") {
			return "Effigy";
		}
		if (normalized === "potion" || normalized === "potion_fx" || normalized === "potion fx" ||
			normalized === "bottle" || normalized === "mekansm") {
			return "Potion FX";
		}
		if (normalized === "rebirth" || normalized === "rebirth_fx" || normalized === "rebirth fx" ||
			normalized === "ankh") {
			return "Rebirth FX";
		}
		if (normalized === "attack_lifesteal" || normalized === "attack lifesteal") {
			return "Attack Lifesteal";
		}
		if (normalized === "spell_lifesteal" || normalized === "spell lifesteal") {
			return "Spell Lifesteal";
		}
		if (normalized === "regen_aura" || normalized === "regen aura" || normalized === "fountain") {
			return "Regen Aura";
		}
		if (normalized === "immolation" || normalized === "radiance") {
			return "Immolation";
		}
		if (normalized === "high_five" || normalized === "high five" || normalized === "highfive") {
			return "High Five";
		}
		if (normalized === "title" || normalized === "account_title" || normalized === "account title") {
			return "Title";
		}
		if (normalized === "fragment" || normalized === "fragments" || normalized === "currency") {
			return "Fragments";
		}
		if (normalized === "bundle") {
			return "Bundle";
		}
		if (normalized === "pudge_hook" || normalized === "pudge hook") {
			return "Pudge Hook";
		}
		if (normalized === "pudge_arcana" || normalized === "pudge arcana") {
			return "Pudge Arcana";
		}
		if (normalized === "streak_counter" || normalized === "streak counter") {
			return "Streak Counter";
		}
		return "Cosmetic";
	}

	function NormalizeArmoryItemType(item) {
		var normalizedType = NormalizeRewardType(item && (item.type || item.item_type));
		if (normalizedType !== "Cosmetic") {
			return normalizedType;
		}

		var slot = ((item && item.slot_id) || "").toString().toLowerCase();
		if (slot === "companion" || slot === "companions" || slot === "courier") {
			return "Companion";
		}
		if (slot === "emblem" || slot === "emblems") {
			return "Emblem";
		}
		if (slot === "effigy" || slot === "statue") {
			return "Effigy";
		}
		if (slot === "teleport" || slot === "teleport_fx") {
			return "Teleport FX";
		}
		if (slot === "levelup" || slot === "tome" || slot === "tome_fx") {
			return "Tome FX";
		}
		if (slot === "kill_effect" || slot === "kill_fx") {
			return "Kill FX";
		}
		if (slot === "potion" || slot === "potion_fx" || slot === "bottle" || slot === "mekansm") {
			return "Potion FX";
		}
		if (slot === "rebirth" || slot === "rebirth_fx" || slot === "ankh") {
			return "Rebirth FX";
		}
		if (slot === "attack_lifesteal") {
			return "Attack Lifesteal";
		}
		if (slot === "spell_lifesteal") {
			return "Spell Lifesteal";
		}
		if (slot === "regen_aura" || slot === "fountain") {
			return "Regen Aura";
		}
		if (slot === "immolation" || slot === "radiance") {
			return "Immolation";
		}
		if (slot === "high_five" || slot === "highfive") {
			return "High Five";
		}
		if (slot === "title" || slot === "account_title") {
			return "Title";
		}
		if (slot === "fragment" || slot === "fragments") {
			return "Fragments";
		}
		return normalizedType;
	}

	function IsDisabledCompanionItem(item) {
		if (!item) {
			return false;
		}
		if (item.disabled === true || item.disabled === 1 || item.disabled === "1" ||
			item.enabled === false || item.enabled === 0 || item.enabled === "0") {
			return true;
		}

		var candidates = [
			item.unit,
			item.unit_name,
			item.file,
			item.npc_name,
			item.item_id,
			item.id,
			item.item_name,
			item.name,
		];
		for (var i = 0; i < candidates.length; i++) {
			if (candidates[i] === undefined || candidates[i] === null) {
				continue;
			}
			var value = candidates[i].toString().toLowerCase().replace(/[\s_-]/g, "");
			if (value === "" || value === "0" || value === "false" || value === "none" ||
				value === "off" || value === "disable" || value === "disabled" ||
				value === "nocompanion" || value.indexOf("companiondisabled") !== -1) {
				return true;
			}
		}
		return false;
	}

	function DisplayRewardType(type) {
		var normalized = NormalizeRewardType(type);
		var keys = {
			"Teleport FX": "xhs_sp_type_teleport",
			"Tome FX": "xhs_sp_type_tome",
			"Kill FX": "xhs_sp_type_kill",
			"Emblem": "xhs_sp_type_emblem",
			"Companion": "xhs_sp_type_companion",
			"Effigy": "xhs_sp_type_effigy",
			"Potion FX": "xhs_sp_type_potion",
			"Rebirth FX": "xhs_sp_type_rebirth",
			"Attack Lifesteal": "xhs_sp_type_attack_lifesteal",
			"Spell Lifesteal": "xhs_sp_type_spell_lifesteal",
			"Regen Aura": "xhs_sp_type_regen_aura",
			"Immolation": "xhs_sp_type_immolation",
			"High Five": "xhs_sp_type_high_five",
			"Title": "xhs_sp_type_title",
			"Fragments": "xhs_sp_type_fragments",
			"Bundle": "xhs_sp_type_bundle",
			"Cosmetic": "xhs_sp_type_cosmetic",
		};
		return Text(keys[normalized] || "xhs_sp_type_cosmetic", normalized);
	}

	function ReadLoadoutValue(loadout, slotNames) {
		if (!loadout) {
			return "";
		}

		for (var i = 0; i < slotNames.length; i++) {
			var value = loadout[slotNames[i]];
			if (value && typeof value === "object") {
				return value.item_id || value.id || value.entitlement_id || value.unit || "";
			}
			if (value) {
				return value;
			}
		}

		return "";
	}

	var SUPPORTER_SLOT_ALIASES = {
		teleport_fx: "teleport",
		"teleport fx": "teleport",
		tome: "levelup",
		tome_fx: "levelup",
		"tome fx": "levelup",
		kill_fx: "kill_effect",
		"kill fx": "kill_effect",
		courier: "companion",
		companions: "companion",
		statue: "effigy",
		effigies: "effigy",
		emblems: "emblem",
		bottle: "potion",
		bottles: "potion",
		mekansm: "potion",
		mekanism: "potion",
		potion_effect: "potion",
		potion_fx: "potion",
		potions: "potion",
		ankh: "rebirth",
		ankhs: "rebirth",
		reincarnation: "rebirth",
		revival: "rebirth",
		respawn: "rebirth",
		rebirth_fx: "rebirth",
		lifesteal: "attack_lifesteal",
		lifesteal_effect: "attack_lifesteal",
		attack_lifesteal_effect: "attack_lifesteal",
		spell_lifesteal_effect: "spell_lifesteal",
		fountain: "regen_aura",
		fountain_regen: "regen_aura",
		regen: "regen_aura",
		radiance: "immolation",
		cloak_of_flames: "immolation",
		immolation_effect: "immolation",
		highfive: "high_five",
		"high five": "high_five",
		account_title: "title",
		supporter_title: "title",
		fragments: "fragment",
	};

	function CanonicalSupporterSlot(value) {
		var normalized = (value || "").toString().toLowerCase();
		return SUPPORTER_SLOT_ALIASES[normalized] || normalized;
	}

	function GetCanonicalArmorySlot(item) {
		var rawSlot = CanonicalSupporterSlot(item && item.slot_id);
		if (rawSlot && rawSlot !== "default" && rawSlot !== "reward") {
			return rawSlot;
		}

		var type = NormalizeRewardType(item && (item.type || item.item_type));
		var slotsByType = {
			"Teleport FX": "teleport",
			"Tome FX": "levelup",
			"Kill FX": "kill_effect",
			"Emblem": "emblem",
			"Companion": "companion",
			"Effigy": "effigy",
			"Potion FX": "potion",
			"Rebirth FX": "rebirth",
			"Attack Lifesteal": "attack_lifesteal",
			"Spell Lifesteal": "spell_lifesteal",
			"Regen Aura": "regen_aura",
			"Immolation": "immolation",
			"High Five": "high_five",
			"Title": "title",
			"Fragments": "fragment",
		};
		return slotsByType[type] || "";
	}

	function ArmoryValueMatchesItem(value, item) {
		if (value === undefined || value === null || value === "") {
			return false;
		}
		var normalizedValue = value.toString();
		var identifiers = [
			item.item_id,
			item.catalog_item_id,
			item.catalog_item_key,
			item.item_key,
			item.reward_item_id,
			item.entitlement_id,
			item.id,
			item.item_name,
			item.name,
			item.unit,
			item.unit_name,
		];
		for (var i = 0; i < identifiers.length; i++) {
			if (identifiers[i] !== undefined && identifiers[i] !== null &&
				identifiers[i].toString() === normalizedValue) {
				return true;
			}
		}
		return false;
	}

	function IsArmoryItemEquipped(player, item) {
		var raw = player.raw || {};
		var loadout = raw.loadout || {};
		var slot = GetCanonicalArmorySlot(item);
		var equippedValue = "";
		var slotAliases = {
			teleport: ["teleport", "teleport_fx"],
			levelup: ["levelup", "tome", "tome_fx"],
			kill_effect: ["kill_effect", "kill_fx"],
			emblem: ["emblem", "emblems"],
			companion: ["companion", "companions", "courier"],
			effigy: ["effigy", "effigies", "statue"],
			potion: ["potion", "potion_fx", "bottle", "mekansm"],
			rebirth: ["rebirth", "rebirth_fx", "ankh"],
			attack_lifesteal: ["attack_lifesteal"],
			spell_lifesteal: ["spell_lifesteal"],
			regen_aura: ["regen_aura", "fountain"],
			immolation: ["immolation", "radiance"],
			high_five: ["high_five", "highfive"],
			title: ["title", "supporter_title", "account_title"],
		};

		if (slot === "fragment") {
			return false;
		}
		if (slotAliases[slot]) {
			equippedValue = ReadLoadoutValue(loadout, slotAliases[slot]);
		}
		if (!equippedValue) {
			for (var rawSlot in loadout) {
				if (loadout.hasOwnProperty(rawSlot) && CanonicalSupporterSlot(rawSlot) === slot) {
					equippedValue = ReadLoadoutValue(loadout, [rawSlot]);
					if (equippedValue) {
						break;
					}
				}
			}
		}
		if (!equippedValue && slot === "companion") {
			equippedValue = raw.companion || raw.companion_id;
		} else if (!equippedValue && slot === "emblem") {
			equippedValue = raw.emblem || raw.emblem_id;
		} else if (!equippedValue && slot === "effigy") {
			equippedValue = raw.effigy || raw.effigy_id || raw.statue || raw.statue_id;
		}

		return ArmoryValueMatchesItem(equippedValue, item) || item.equipped === true;
	}

	function BuildArmoryItemFromReward(reward, player, track) {
		var requiredLevel = ToNumber(reward.level_required || reward.level, 1);
		var isPremium = track === "premium" || reward.track === "premium" || reward.premium === 1 || reward.premium === "1";
		var premiumLocked = isPremium && player.tier_id < 1;
		var levelLocked = player.season_level < requiredLevel;
		var legacyReward = IsTruthy(reward.legacy, false);
		var actuallyOwned = legacyReward
			? IsLegacyRewardUnlocked(reward, player, track)
			: IsRewardClaimed(reward, player);
		var devPreviewUnlocked = IsDevUnlockAllUIActive(player);
		var actualItemID = reward.item_id || reward.catalog_item_id || reward.reward_id || reward.id;
		var item = {
			id: actualItemID,
			display_id: "battlepass_" + (actualItemID || reward.name),
			item_id: actualItemID,
			entitlement_id: reward.entitlement_id,
			name: reward.name || reward.item_name || reward.id,
			item_name: reward.item_name || reward.name,
			item_type: reward.item_type || reward.type,
			type: NormalizeRewardType(reward.type || reward.item_type),
			rarity: reward.rarity || reward.item_rarity || (isPremium ? "premium" : "season"),
			image: reward.image || reward.image_inventory || reward.icon || reward.icon_path,
			hero: reward.hero || reward.used_by_heroes || reward.type || reward.item_type || "global",
			slot_id: reward.slot_id || reward.type || reward.item_type || "default",
			unit: reward.unit || reward.unit_name || reward.npc_name,
			unit_name: reward.unit_name || reward.unit,
			runtime_assets: reward.runtime_assets || reward.runtimeAssets,
			start_pfx: reward.start_pfx,
			end_pfx: reward.end_pfx,
			target_pfx: reward.target_pfx,
			caster_pfx: reward.caster_pfx,
			health_pfx: reward.health_pfx,
			mana_pfx: reward.mana_pfx,
			light_pfx: reward.light_pfx,
			owner_pfx: reward.owner_pfx,
			pfx: reward.pfx,
			overhead_pfx: reward.overhead_pfx,
			travel_pfx: reward.travel_pfx,
			impact_pfx: reward.impact_pfx,
			title_text: reward.title_text,
			amount: reward.amount,
			level: requiredLevel,
			track: Text(isPremium ? "xhs_sp_supporter_track" : "xhs_sp_free_track", isPremium ? "Supporter Track" : "Free Track"),
		};

		item.locked = devPreviewUnlocked ? false : (premiumLocked || levelLocked);
		item.lock_reason = premiumLocked ? Text("xhs_sp_supporter_track", "Supporter Track") : Text("xhs_sp_level_value", "Level {level}", { level: requiredLevel });
		item.equipped = !item.locked && IsArmoryItemEquipped(player, item);
		item.dev_preview_only = devPreviewUnlocked && !actuallyOwned;
		if (item.dev_preview_only) {
			item.equipped = false;
		}
		return item;
	}

	function RequiredTierFromStatus(status) {
		var normalized = ToNumber(status, 0);
		var statusToTier = { 6: 1, 5: 2, 4: 3, 7: 4, 8: 5, 9: 5 };
		return statusToTier[normalized] || Clamp(normalized, 0, 5);
	}

	function BuildLegacyBattlepassArmory(player) {
		var items = [];
		var freeRewards = GetRewards("free");
		var premiumRewards = GetRewards("premium");
		var devPreviewUnlocked = IsDevUnlockAllUIActive(player);

		for (var i = 0; i < freeRewards.length; i++) {
			if (!devPreviewUnlocked && !IsTruthy(freeRewards[i].legacy, false)) {
				continue;
			}
			var freeItem = BuildArmoryItemFromReward(freeRewards[i], player, "free");
			if (!freeItem.locked && GetCanonicalArmorySlot(freeItem) !== "fragment") {
				items.push(freeItem);
			}
		}
		for (var j = 0; j < premiumRewards.length; j++) {
			if (!devPreviewUnlocked && !IsTruthy(premiumRewards[j].legacy, false)) {
				continue;
			}
			var premiumItem = BuildArmoryItemFromReward(premiumRewards[j], player, "premium");
			if (!premiumItem.locked && GetCanonicalArmorySlot(premiumItem) !== "fragment") {
				items.push(premiumItem);
			}
		}

		return items;
	}

	function GetArmoryCatalogEntries(item) {
		var type = NormalizeArmoryItemType(item);
		if (type === "Companion") {
			return AsArray(GetTable("supporter_pass_player", "companions", []));
		}
		if (type === "Emblem") {
			return AsArray(GetTable("supporter_pass_player", "emblems", []));
		}
		if (type === "Effigy") {
			return AsArray(GetTable("supporter_pass_player", "effigies", []));
		}
		return [];
	}

	function CatalogEntryMatchesArmoryItem(entry, item) {
		var itemIdentifiers = [
			item.item_id,
			item.catalog_item_id,
			item.catalog_item_key,
			item.item_key,
			item.reward_item_id,
			item.entitlement_id,
			item.id,
		];
		var entryIdentifiers = [
			entry.item_id,
			entry.catalog_item_id,
			entry.catalog_item_key,
			entry.item_key,
			entry.reward_item_id,
			entry.entitlement_id,
			entry.id,
		];

		for (var i = 0; i < itemIdentifiers.length; i++) {
			if (itemIdentifiers[i] === undefined || itemIdentifiers[i] === null || itemIdentifiers[i] === "") {
				continue;
			}
			for (var j = 0; j < entryIdentifiers.length; j++) {
				if (entryIdentifiers[j] !== undefined && entryIdentifiers[j] !== null &&
					itemIdentifiers[i].toString() === entryIdentifiers[j].toString()) {
					return true;
				}
			}
		}
		return false;
	}

	function EnrichOwnedArmoryItem(item) {
		var catalog = GetArmoryCatalogEntries(item);
		for (var i = 0; i < catalog.length; i++) {
			if (CatalogEntryMatchesArmoryItem(catalog[i], item)) {
				return CopyMissingFields(item, catalog[i]);
			}
		}
		return item;
	}

	function NormalizeBackendArmoryItems(items, player) {
		var normalizedItems = [];
		for (var i = 0; i < items.length; i++) {
			var item = EnrichOwnedArmoryItem(CopyObject(items[i]));
			item.type = NormalizeArmoryItemType(item);
			item.entitlement_id = item.entitlement_id || item.id;
			item.item_id = item.item_id || item.catalog_item_id || item.catalog_item_key ||
				item.item_key || item.reward_item_id || item.id;
			item.image = item.image || item.image_inventory || item.icon || item.icon_path;
			item.slot_id = GetCanonicalArmorySlot(item) || item.slot_id || "default";
			if (item.slot_id === "fragment") {
				continue;
			}
			if (item.type === "Companion") {
				item.unit = item.unit || item.unit_name || item.file || item.npc_name;
				if (IsDisabledCompanionItem(item)) {
					continue;
				}
			}
			var requiredTier = ToNumber(item.required_tier || item.tier_id, RequiredTierFromStatus(item.required_status));
			item.locked = requiredTier > 0 && player.tier_id < requiredTier;
			item.lock_reason = item.locked ? Text("xhs_sp_tier_value", "Tier {tier}", { tier: requiredTier }) : "";
			item.equipped = item.equipped === true || IsArmoryItemEquipped(player, item);
			normalizedItems.push(item);
		}
		return normalizedItems;
	}

	function GetShopItems() {
		var data = GetTable("supporter_pass_shop", "featured", null);
		var items = AsArray(data && data.items ? data.items : data);
		return items;
	}

	function GetArmoryItems(player) {
		var playerID = Players.GetLocalPlayer();
		var backendItems = NormalizeBackendArmoryItems(AsArray(GetTable("supporter_pass_armory", "rewards_" + playerID, [])), player);
		var legacyItems = BuildLegacyBattlepassArmory(player);
		var merged = [];
		var seen = {};

		function identityCandidates(item) {
			var candidates = [];
			var itemID = item.item_id || item.catalog_item_id || item.reward_item_id;
			if (itemID !== undefined && itemID !== null && itemID !== "") {
				candidates.push("item:" + itemID.toString().toLowerCase());
			}
			var runtimeAsset = item.unit || item.unit_name || item.file || item.particle;
			if (runtimeAsset) {
				candidates.push("runtime:" + runtimeAsset.toString().toLowerCase());
			}
			var name = item.name || item.item_name;
			if (name) {
				candidates.push("name:" + name.toString().toLowerCase().replace(/[^a-z0-9]/g, ""));
			}
			if (candidates.length === 0) {
				var fallback = item.entitlement_id || item.id || merged.length;
				candidates.push("fallback:" + fallback.toString().toLowerCase());
			}
			return candidates;
		}

		function mergeBackendItem(legacyItem, backendItem) {
			var result = CopyObject(legacyItem);
			var legacyType = NormalizeArmoryItemType(legacyItem);
			var backendType = NormalizeArmoryItemType(backendItem);
			var preserveLegacyType = backendType === "Cosmetic" && legacyType !== "Cosmetic";
			var preserveLegacySlot = (!backendItem.slot_id || backendItem.slot_id === "default") &&
				legacyItem.slot_id && legacyItem.slot_id !== "default";
			var visualFields = {
				image: true,
				image_inventory: true,
				icon: true,
				icon_path: true,
				unit: true,
				unit_name: true,
				file: true,
				particle: true,
			};

			for (var field in backendItem) {
				if (!backendItem.hasOwnProperty(field) || backendItem[field] === undefined || backendItem[field] === null || backendItem[field] === "") {
					continue;
				}
				if (visualFields[field] && result[field]) {
					continue;
				}
				if ((field === "type" || field === "item_type") && preserveLegacyType) {
					continue;
				}
				if (field === "slot_id" && preserveLegacySlot) {
					continue;
				}
				result[field] = backendItem[field];
			}
			result.type = preserveLegacyType ? legacyType : NormalizeArmoryItemType(result);
			if (preserveLegacySlot) {
				result.slot_id = legacyItem.slot_id;
			}
			return result;
		}

		function append(item, backendWins) {
			var identities = identityCandidates(item);
			var existingIndex;
			for (var i = 0; i < identities.length; i++) {
				if (seen[identities[i]] !== undefined) {
					existingIndex = seen[identities[i]];
					break;
				}
			}
			if (existingIndex !== undefined) {
				if (backendWins) {
					merged[existingIndex] = mergeBackendItem(merged[existingIndex], item);
					merged[existingIndex].dev_preview_only = false;
					var mergedIdentities = identityCandidates(merged[existingIndex]);
					for (var m = 0; m < mergedIdentities.length; m++) {
						seen[mergedIdentities[m]] = existingIndex;
					}
				}
				return;
			}
			var newIndex = merged.length;
			for (var j = 0; j < identities.length; j++) {
				seen[identities[j]] = newIndex;
			}
			merged.push(item);
		}

		for (var i = 0; i < legacyItems.length; i++) {
			append(legacyItems[i], false);
		}
		for (var j = 0; j < backendItems.length; j++) {
			append(backendItems[j], true);
		}
		return merged;
	}

	function IsTruthy(value, fallbackValue) {
		if (value === undefined || value === null) {
			return fallbackValue === true;
		}

		return value === true || value === 1 || value === "1" || value === "true";
	}

	function CopySettings(settings) {
		return {
			toggle_tag: settings.toggle_tag === true,
			pass_rewards: settings.pass_rewards === true,
			player_xp: settings.player_xp === true,
			winrate_toggle: settings.winrate_toggle === true,
		};
	}

	function SettingsEqual(a, b) {
		return a.toggle_tag === b.toggle_tag &&
			a.pass_rewards === b.pass_rewards &&
			a.player_xp === b.player_xp &&
			a.winrate_toggle === b.winrate_toggle;
	}

	function BuildSettingsFromPlayer(player) {
		var passRewards = player.raw.pass_rewards !== undefined ? player.raw.pass_rewards : player.raw.bp_rewards;
		return {
			toggle_tag: IsTruthy(player.raw.toggle_tag, true),
			pass_rewards: passRewards === 0 ? false : IsTruthy(passRewards, true),
			player_xp: IsTruthy(player.raw.player_xp, true),
			winrate_toggle: IsTruthy(player.raw.winrate_toggle, true),
		};
	}

	function SetPercent(panel, current, max) {
		if (!panel) {
			return;
		}
		panel.style.width = Clamp(Math.floor((ToNumber(current, 0) / Math.max(ToNumber(max, 1), 1)) * 100), 0, 100) + "%";
	}

	function SetText(id, value) {
		var panel = Panel(id);
		if (panel) {
			panel.text = value;
		}
	}

	function PulseFragmentsCounter() {
		var counter = Panel("XHSSupporterFragmentsCounter");
		if (!counter) {
			return;
		}

		counter.SetHasClass("IsPulsing", false);
		$.Schedule(0.01, function () {
			if (counter && (!counter.IsValid || counter.IsValid())) {
				counter.SetHasClass("IsPulsing", true);
			}
		});
		$.Schedule(0.38, function () {
			if (counter && (!counter.IsValid || counter.IsValid())) {
				counter.SetHasClass("IsPulsing", false);
			}
		});
	}

	function ShowFragmentGainFlyout(amount, tierID) {
		if (amount <= 0) {
			return;
		}

		var button = Panel("XHSSupporterPassButton");
		if (!button) {
			return;
		}

		var flyout = $.CreatePanel("Panel", button, "XHSSupporterFragmentFlyout" + fragmentFlyoutIndex++);
		flyout.AddClass("XHSSupporterFragmentFlyout");
		flyout.hittest = false;
		ApplySupporterTierClasses(flyout, tierID);

		var icon = $.CreatePanel("Label", flyout, "");
		icon.AddClass("XHSSupporterFragmentFlyoutIcon");
		icon.hittest = false;
		icon.text = "F";

		var value = $.CreatePanel("Label", flyout, "");
		value.AddClass("XHSSupporterFragmentFlyoutValue");
		value.hittest = false;
		value.text = "+" + FormatNumber(amount);

		$.Schedule(0.03, function () {
			if (flyout && (!flyout.IsValid || flyout.IsValid())) {
				flyout.AddClass("IsFlying");
			}
		});
		$.Schedule(0.46, PulseFragmentsCounter);
		$.Schedule(0.9, function () {
			if (flyout && (!flyout.IsValid || flyout.IsValid())) {
				flyout.DeleteAsync(0.0);
			}
		});
	}

	function UpdateFragmentsCounter(player) {
		var button = Panel("XHSSupporterPassButton");
		if (button) {
			ApplySupporterTierClasses(button, player.tier_id);
		}

		var fragments = Math.max(0, ToNumber(player.fragments, 0));
		SetText("XHSSupporterFragmentsCounterValue", FormatNumber(fragments));

		var counter = Panel("XHSSupporterFragmentsCounter");
		if (counter) {
			counter.SetHasClass("HasFragments", fragments > 0);
		}

		if (!player.has_fragment_balance && !fragmentCounterInitialized) {
			return;
		}

		if (!fragmentCounterInitialized) {
			lastLocalFragmentBalance = fragments;
			fragmentCounterInitialized = true;
			return;
		}

		if (fragments > lastLocalFragmentBalance) {
			ShowFragmentGainFlyout(fragments - lastLocalFragmentBalance, player.tier_id);
		}

		lastLocalFragmentBalance = fragments;
	}

	function OpenExternalURL(url) {
		if (!url) {
			return;
		}

		if (typeof ExternalBrowserGoToURL === "function") {
			ExternalBrowserGoToURL(url);
			return;
		}

		$.DispatchEvent("ExternalBrowserGoToURL", url);
	}

	function ShowActionMessage(message, success) {
		var toast = Panel("XHSPassActionToast");
		var label = Panel("XHSPassActionToastText");
		var text = message || Text(success ? "xhs_sp_done" : "xhs_sp_action_failed", success ? "Done." : "Action failed.");

		if (!toast || !label) {
			$.Msg("[XHS Supporter Pass] " + (success ? "OK: " : "ERROR: ") + text);
			return;
		}

		actionToastSerial++;
		var serial = actionToastSerial;
		label.text = text;
		toast.SetHasClass("IsSuccess", success === true);
		toast.SetHasClass("IsError", success !== true);
		toast.SetHasClass("IsVisible", true);
		$.Msg("[XHS Supporter Pass] " + (success ? "OK: " : "ERROR: ") + text);

		$.Schedule(3.0, function () {
			if (serial === actionToastSerial && toast && (!toast.IsValid || toast.IsValid())) {
				toast.SetHasClass("IsVisible", false);
			}
		});
	}

	function ToggleWindow(forceVisible) {
		EnsureSupporterPassAboveVanillaHud();
		var window = Panel("XHSSupporterPassWindow");
		if (!window) {
			return;
		}

		var visible = forceVisible;
		if (visible === undefined) {
			visible = !(window.BHasClass("IsVisible") || window.BHasClass("IsOpening"));
		}

		windowAnimationSerial += 1;
		var animationSerial = windowAnimationSerial;
		var config = GameUI.CustomUIConfig ? GameUI.CustomUIConfig() : null;
		if (config) {
			config.XHSSupporterPassVisible = visible === true;
			if (typeof config.UpdateXHSSupporterPassButtonState === "function") {
				config.UpdateXHSSupporterPassButtonState(visible);
			}
		}
		if (visible) {
			window.RemoveClass("IsClosing");
			window.AddClass("IsOpening");
			window.hittest = true;
			RenderAll();
			UpdateBackToTopButton();
			ScheduleBackToTopPoll();
			$.Schedule(0.01, function () {
				if (animationSerial !== windowAnimationSerial || !window || (window.IsValid && !window.IsValid())) {
					return;
				}
				window.RemoveClass("IsOpening");
				window.AddClass("IsVisible");
			});
		} else {
			SetCourierRequestViewerVisible(false);
			window.RemoveClass("IsOpening");
			window.RemoveClass("IsVisible");
			window.AddClass("IsClosing");
			window.hittest = false;
			backToTopPollScheduled = false;
			$.Schedule(0.32, function () {
				if (animationSerial === windowAnimationSerial && window && (!window.IsValid || window.IsValid())) {
					window.RemoveClass("IsClosing");
				}
			});
		}
	}

	function SwitchPage(pageName) {
		if (DISABLED_PAGES[pageName]) {
			Game.EmitSound("General.Cancel");
			return;
		}

		for (var page in PAGE_IDS) {
			if (PAGE_IDS.hasOwnProperty(page)) {
				var pagePanel = Panel(PAGE_IDS[page]);
				if (pagePanel) {
					pagePanel.SetHasClass("IsVisible", page === pageName);
				}
			}
		}

		for (var tab in TAB_IDS) {
			if (TAB_IDS.hasOwnProperty(tab)) {
				var tabPanel = Panel(TAB_IDS[tab]);
				if (tabPanel) {
					tabPanel.SetHasClass("IsActive", tab === pageName);
				}
			}
		}

		if (pageName !== "armory") {
			SetCourierRequestViewerVisible(false);
		}

		UpdateBackToTopButton();
		ScheduleBackToTopPoll();
	}

	function GetCurrentScrollPanel() {
		var activePage = null;
		for (var page in PAGE_IDS) {
			if (!PAGE_IDS.hasOwnProperty(page)) {
				continue;
			}
			var pagePanel = Panel(PAGE_IDS[page]);
			if (pagePanel && pagePanel.BHasClass("IsVisible")) {
				activePage = page;
				break;
			}
		}

		if (activePage === "overview") {
			return Panel("XHSPassOverviewGrid");
		}
		if (activePage === "rewards") {
			return Panel("XHSPassRewardTracks");
		}
		if (activePage === "shop") {
			return Panel("XHSPassShopGrid");
		}
		if (activePage === "armory") {
			var requestOverlay = Panel("XHSPassCourierRequestOverlay");
			if (requestOverlay && requestOverlay.BHasClass("IsVisible")) {
				return Panel("XHSPassCourierRequestGrid");
			}
			return Panel("XHSPassArmoryGrid");
		}
		if (activePage === "settings") {
			return Panel("XHSPassSettingsRows");
		}

		return null;
	}

	function UpdateBackToTopButton() {
		var button = Panel("XHSPassBackToTopButton");
		if (!button) {
			return;
		}

		var panel = GetCurrentScrollPanel();
		var scrollOffset = panel && typeof panel.scrolloffset_y === "number" ? panel.scrolloffset_y : 0;
		button.SetHasClass("IsVisible", scrollOffset > 40);
	}

	function ScheduleBackToTopPoll() {
		var window = Panel("XHSSupporterPassWindow");
		if (!window || !window.BHasClass("IsVisible") || backToTopPollScheduled) {
			return;
		}

		backToTopPollScheduled = true;
		$.Schedule(0.12, function () {
			backToTopPollScheduled = false;
			var currentWindow = Panel("XHSSupporterPassWindow");
			if (!currentWindow || !currentWindow.BHasClass("IsVisible")) {
				UpdateBackToTopButton();
				return;
			}

			UpdateBackToTopButton();
			ScheduleBackToTopPoll();
		});
	}

	function ScrollCurrentPageToTop() {
		var panel = GetCurrentScrollPanel();
		if (!panel) {
			return;
		}

		if (typeof panel.ScrollToTop === "function") {
			try {
				panel.ScrollToTop();
			} catch (e) {
			}
		}

		if (typeof panel.GetChildCount === "function" && panel.GetChildCount() > 0) {
			var firstChild = panel.GetChild(0);
			if (firstChild) {
				if (typeof firstChild.ScrollParentToMakePanelFit === "function") {
					try {
						firstChild.ScrollParentToMakePanelFit(0, false);
					} catch (e2) {
					}
				}
				$.DispatchEvent("ScrollPanelIntoView", firstChild);
			}
		}

		var button = Panel("XHSPassBackToTopButton");
		if (button) {
			button.SetHasClass("IsVisible", false);
		}

		$.Schedule(0.05, UpdateBackToTopButton);
	}

	function CreateEmpty(parent, title, body) {
		ClearPanel(parent);
		if (!parent) {
			return;
		}

		var empty = $.CreatePanel("Panel", parent, "");
		empty.AddClass("XHSPassEmpty");

		var titlePanel = $.CreatePanel("Label", empty, "");
		titlePanel.AddClass("XHSPassEmptyTitle");
		titlePanel.text = title;

		var bodyPanel = $.CreatePanel("Label", empty, "");
		bodyPanel.AddClass("XHSPassEmptyBody");
		bodyPanel.text = body;
	}

	function RenderHeader(player) {
		ApplySupporterTierClasses(Panel("XHSSupporterPassWindow"), player.tier_id);
		UpdateFragmentsCounter(player);
		var devUnlockButton = Panel("XHSPassDevUnlockUIButton");
		var canUseDevUnlock = IsLocalSupporterDeveloper(player);
		if (devUnlockButton) {
			devUnlockButton.SetHasClass("IsVisible", canUseDevUnlock);
			devUnlockButton.SetHasClass("IsActive", canUseDevUnlock && devUnlockAllUI);
			devUnlockButton.hittest = canUseDevUnlock;
		}
		SetText(
			"XHSPassDevUnlockUILabel",
			devUnlockAllUI ? "DEV: LOCK UI" : "DEV: UNLOCK UI"
		);

		var avatar = Panel("XHSPassAvatar");
		if (avatar && player.steamID) {
			avatar.steamid = player.steamID;
		}

		SetText("XHSPassTierValue", player.tier_name);
		SetText("XHSPassFragmentsValue", FormatNumber(player.fragments));
		SetText("XHSPassWeeklyCapValue", FormatNumber(player.daily_fragments || player.weekly_fragments) + " / " + FormatNumber(player.daily_cap || player.weekly_cap));
		SetText("XHSPassGlobalXPValue", FormatXHSAccountXPSummary(player));
		SetText("XHSPassSeasonXPValue", FormatSupporterXPSummary(player));
		var xpBoostText = "+" + FormatNumber(player.xp_boost) + "%";
		if (player.xp_bonus > 0) {
			xpBoostText += " (+" + FormatNumber(player.xp_bonus) + " XP)";
		}
		SetText("XHSPassXPBoostValue", xpBoostText);
		SetText("XHSPassVotePowerValue", FormatVotePower(player.vote_power));
		SetText("XHSPassPlayerName", ResolveLocalPlayerIdentity(player));
		SetText("XHSPassPlayerTier", player.tier_name);
		SetText("XHSPassLevelLabel", Text("xhs_sp_season_level_value", "Season Level {level}", { level: player.season_level }));
		SetText("XHSPassXpLabel", FormatNumber(player.season_xp) + " / " + FormatNumber(player.season_xp_max) + " " + Text("xhs_sp_xp", "XP"));
		SetPercent(Panel("XHSPassXpProgress"), player.season_xp, player.season_xp_max);
		SetPercent(Panel("XHSPassWeeklyProgress"), player.daily_fragments || player.weekly_fragments, player.daily_cap || player.weekly_cap);

		var tierLabel = Panel("XHSPassPlayerTier");
		if (tierLabel) {
			tierLabel.style.color = player.tier_color;
		}

		var tierValue = Panel("XHSPassTierValue");
		if (tierValue) {
			tierValue.style.color = player.tier_color;
		}

		var boostValue = Panel("XHSPassXPBoostValue");
		if (boostValue) {
			boostValue.style.color = player.tier_id > 0 ? player.tier_color : "#f3fbff";
		}

		var votePowerValue = Panel("XHSPassVotePowerValue");
		if (votePowerValue) {
			votePowerValue.style.color = player.tier_id > 0 ? player.tier_color : "#f3fbff";
		}
	}

	function RenderTiers() {
		var parent = Panel("XHSPassTierRows");
		ClearPanel(parent);

		var player = GetLocalPlayerData();
		var supporterURL = player.supporter_url || SUPPORTER_URL;
		var tiers = GetTiers();
		for (var i = 0; i < tiers.length; i++) {
			var tier = GetTierMeta(tiers[i]);
			var isOwnedTier = tier.id > 0 && tier.id === player.tier_id;
			var row = $.CreatePanel("Panel", parent, "");
			row.AddClass("XHSPassTierCard");
			row.AddClass("Tier" + tier.id);
			row.SetHasClass("Featured", tier.featured);
			row.SetHasClass("IsOwnedTier", isOwnedTier);
			row.SetHasClass("IsClickable", !isOwnedTier);
			row.hittest = true;
			if (!isOwnedTier) {
				(function (url) {
					row.SetPanelEvent("onactivate", function () {
						Game.EmitSound("General.ButtonClick");
						OpenExternalURL(url);
					});
				})(supporterURL);
			}

			var art = $.CreatePanel("Panel", row, "");
			art.AddClass("XHSPassTierArt");
			art.hittest = false;
			if (tier.image) {
				art.style.backgroundImage = 'url("file://{images}/custom_game/' + tier.image + '")';
			}

			var shade = $.CreatePanel("Panel", row, "");
			shade.AddClass("XHSPassTierShade");
			shade.hittest = false;

			var sweep = $.CreatePanel("Panel", row, "");
			sweep.AddClass("XHSPassTierSweep");
			sweep.hittest = false;

			if (isOwnedTier) {
				var owned = $.CreatePanel("Panel", row, "");
				owned.AddClass("XHSPassTierOwnedTooltip");
				owned.hittest = false;

				var ownedTitle = $.CreatePanel("Label", owned, "");
				ownedTitle.AddClass("XHSPassTierOwnedTitle");
				ownedTitle.text = Text("xhs_sp_current_tier", "Current Tier");

				var ownedText = $.CreatePanel("Label", owned, "");
				ownedText.AddClass("XHSPassTierOwnedText");
				ownedText.text = Text("xhs_sp_already_have_tier", "You already have this tier");
			}

			var top = $.CreatePanel("Panel", row, "");
			top.AddClass("XHSPassTierTopline");
			top.hittest = false;

			var mark = $.CreatePanel("Label", top, "");
			mark.AddClass("XHSPassTierMark");
			mark.text = tier.label;
			mark.hittest = false;

			var name = $.CreatePanel("Label", row, "");
			name.AddClass("XHSPassTierName");
			name.text = tier.name;
			name.hittest = false;

			var price = $.CreatePanel("Label", row, "");
			price.AddClass("XHSPassTierPrice");
			price.text = tier.price;
			price.hittest = false;

			var copy = $.CreatePanel("Label", row, "");
			copy.AddClass("XHSPassTierCopy");
			copy.text = tier.text;
			copy.hittest = false;

			var tagList = $.CreatePanel("Panel", row, "");
			tagList.AddClass("XHSPassTagList");
			tagList.hittest = false;
			for (var p = 0; p < tier.perks.length; p++) {
				var tag = $.CreatePanel("Label", tagList, "");
				tag.AddClass("XHSPassTag");
				tag.text = tier.perks[p];
				tag.hittest = false;
			}

			var cta = $.CreatePanel("Label", row, "");
			cta.AddClass("XHSPassTierCTA");
			cta.text = Text(isOwnedTier ? "xhs_sp_active_on_account" : "xhs_sp_support_on_patreon", isOwnedTier ? "Active on your account" : "Support on Patreon");
			cta.hittest = false;
		}
	}

	function CreateRewardCard(parent, reward, player, track) {
		var card = $.CreatePanel("Panel", parent, "");
		card.AddClass("XHSPassRewardCard");
		ApplyItemVisualClasses(card, reward, track);
		var devPreviewUnlocked = IsDevUnlockAllUIActive(player);
		var legacyReward = IsTruthy(reward.legacy, false);
		var rewardClaimable = reward.claimable === undefined ? !legacyReward : IsTruthy(reward.claimable, false);
		var legacyUnlocked = legacyReward && (devPreviewUnlocked || IsLegacyRewardUnlocked(reward, player, track));
		var rewardClaimed = devPreviewUnlocked || (legacyReward ? legacyUnlocked : IsRewardClaimed(reward, player));
		var requiredLevel = ToNumber(reward.level_required || reward.level, 1);
		var backendReady = devPreviewUnlocked || IsTruthy(player.raw && player.raw.backend_season_ready, true);
		var premiumLocked = (track === "premium" || reward.track === "premium" ||
			reward.premium === 1 || reward.premium === "1") && player.tier_id < 1 && !devPreviewUnlocked;
		var levelLocked = player.season_level < requiredLevel && !devPreviewUnlocked;
		card.SetHasClass("IsLegacyReward", legacyReward);
		card.SetHasClass("IsDevUIPreview", devPreviewUnlocked);
		card.SetHasClass("IsLocked", !rewardClaimed && (legacyReward ? !legacyUnlocked : (levelLocked || premiumLocked || !backendReady)));
		card.SetHasClass("IsPremiumLocked", premiumLocked);
		card.SetHasClass("IsClaimed", rewardClaimed);

		var preview = CreateItemPreview(card, reward, "XHSPassRewardPreview", "XHSPassRewardImage");
		var level = $.CreatePanel("Label", preview, "");
		level.AddClass("XHSPassRewardLevel");
		level.text = Text("xhs_sp_level_value", "Level {level}", { level: reward.level_required || reward.level || "-" });

		var details = $.CreatePanel("Panel", card, "");
		details.AddClass("XHSPassRewardDetails");

		var name = $.CreatePanel("Label", details, "");
		name.AddClass("XHSPassRewardName");
		name.text = LocalizeMaybeKey(reward.name || reward.item_name || Text("xhs_sp_reward", "Reward"));

		var type = $.CreatePanel("Label", details, "");
		type.AddClass("XHSPassRewardType");
		type.text = devPreviewUnlocked
			? "DEV UI PREVIEW"
			: rewardClaimed
			? Text(legacyReward ? "xhs_sp_unlocked" : "xhs_sp_claimed", legacyReward ? "Unlocked" : "Claimed")
			: (legacyReward ? Text("xhs_sp_legacy_reward", "Legacy Reward") : DisplayRewardType(reward.type || reward.item_type || "Cosmetic"));

		var rewardID = GetRewardID(reward);
		if (rewardID) {
			var button = $.CreatePanel("Button", card, "");
			button.AddClass("XHSPassShopButton");
			var pending = IsActionPending("claim", rewardID);
			var canClaim = !legacyReward && rewardClaimable && !rewardClaimed &&
				player.season_level >= requiredLevel && !premiumLocked && backendReady && !pending;
			button.SetHasClass("IsLocked", !canClaim);
			button.SetPanelEvent("onactivate", function () {
				if (!canClaim) {
					Game.EmitSound("General.Cancel");
					return;
				}
				GameEvents.SendCustomGameEventToServer("supporter_pass_claim_reward", {
					reward_id: rewardID,
					item_id: reward.item_id || rewardID,
				});
				SetActionPending("claim", rewardID, true);
				RenderRewards(GetLocalPlayerData());
			});

			var label = $.CreatePanel("Label", button, "");
			label.text = devPreviewUnlocked
				? "PREVIEW ONLY"
				: legacyReward
				? Text(legacyUnlocked ? "xhs_sp_unlocked" : "xhs_sp_locked", legacyUnlocked ? "Unlocked" : "Locked")
				: Text(pending ? "xhs_sp_pending" : (rewardClaimed ? "xhs_sp_claimed" : (canClaim ? "xhs_sp_claim" : "xhs_sp_locked")), pending ? "Pending..." : (rewardClaimed ? "Claimed" : (canClaim ? "Claim" : "Locked")));
		}
	}

	function RenderRewardTrack(parent, title, rewards, player, track) {
		var trackPanel = $.CreatePanel("Panel", parent, "");
		trackPanel.AddClass("XHSPassRewardTrack");
		trackPanel.SetHasClass("IsPremiumTrack", track === "premium");
		trackPanel.SetHasClass("IsIncompleteTrack", !rewards || rewards.length !== SUPPORTER_PASS_LEVEL_COUNT);

		var titlePanel = $.CreatePanel("Label", trackPanel, "");
		titlePanel.AddClass("XHSPassRewardTrackTitle");
		titlePanel.text = Text("xhs_sp_track_reward_count", "{track} · {count}/{total} rewards", {
			track: title,
			count: rewards ? rewards.length : 0,
			total: SUPPORTER_PASS_LEVEL_COUNT,
		});

		var row = $.CreatePanel("Panel", trackPanel, "");
		row.AddClass("XHSPassRewardRow");

		if (!rewards || rewards.length === 0) {
			var empty = $.CreatePanel("Label", row, "");
			empty.AddClass("XHSPassEmptyBody");
			empty.text = Text("xhs_sp_no_rewards_track", "No rewards configured for this track yet.");
			return;
		}

		for (var i = 0; i < rewards.length; i++) {
			CreateRewardCard(row, rewards[i], player, track);
		}

		$.Schedule(0.0, function () {
			if (row && row.IsValid() && typeof row.ScrollToLeftEdge === "function") {
				row.ScrollToLeftEdge();
			}
		});
	}

	function RenderRewards(player) {
		var parent = Panel("XHSPassRewardTracks");
		ClearPanel(parent);

		if (!parent) {
			return;
		}

		RenderRewardTrack(parent, Text("xhs_sp_free_track", "Free Track"), GetRewards("free"), player, "free");
		RenderRewardTrack(parent, Text("xhs_sp_supporter_track", "Supporter Track"), GetRewards("premium"), player, "premium");
	}

	function CreateShopCard(parent, item, player, mode) {
		var card = $.CreatePanel("Panel", parent, "");
		var devPreviewOnly = mode === "armory" && item.dev_preview_only === true;
		card.AddClass("XHSPassShopCard");
		card.SetHasClass("IsArmoryCard", mode === "armory");
		card.SetHasClass("IsDevUIPreview", devPreviewOnly);
		card.SetHasClass("IsEquipped", item.equipped === true);
		card.SetHasClass("IsLocked", item.locked === true);
		ApplyItemVisualClasses(card, item, item.track === "premium" ? "premium" : "");

		CreateItemPreview(card, item, "XHSPassShopPreview", "XHSPassShopImage");

		var name = $.CreatePanel("Label", card, "");
		name.AddClass("XHSPassShopName");
		name.text = LocalizeMaybeKey(item.name || item.item_name || item.id || Text("xhs_sp_shop_item", "Shop Item"));

		var meta = $.CreatePanel("Label", card, "");
		meta.AddClass("XHSPassShopMeta");
		meta.text = LocalizeMaybeKey(item.rarity || Text("xhs_sp_common", "Common")) + " " + DisplayRewardType(item.type || item.item_type || "Cosmetic");

		var price = $.CreatePanel("Label", card, "");
		price.AddClass("XHSPassShopPrice");
		if (mode === "armory") {
			price.text = devPreviewOnly
				? "DEV UI PREVIEW"
				: (item.locked ? (item.lock_reason || Text("xhs_sp_locked", "Locked")) : Text(item.equipped ? "xhs_sp_equipped" : "xhs_sp_unlocked", item.equipped ? "Equipped" : "Unlocked"));
		} else {
			price.text = FormatNumber(item.price || item.fragment_price || 0) + " " + Text("xhs_sp_fragments_lower", "fragments");
		}

		var button = $.CreatePanel("Button", card, "");
		button.AddClass("XHSPassShopButton");
		var requestID = mode === "armory"
			? (item.entitlement_id || item.item_id || item.id)
			: (item.id || item.item_id);
		var actionKind = mode === "armory" ? "equip" : "purchase";
		var pending = IsActionPending(actionKind, requestID);
		var canAfford = mode === "armory"
			? item.locked !== true && item.equipped !== true && !pending && !devPreviewOnly
			: player.fragments >= ToNumber(item.price || item.fragment_price, 0) && !pending;
		button.SetHasClass("IsLocked", !canAfford);
		button.SetPanelEvent("onactivate", function () {
			if (devPreviewOnly) {
				ShowActionMessage("UI preview only \u00b7 no server unlock or equip was sent.", true);
				Game.EmitSound("General.ButtonClick");
				return;
			}
			if (!canAfford) {
				Game.EmitSound("General.Cancel");
				return;
			}

			if (mode === "armory") {
				SetActionPending("equip", requestID, true);
				GameEvents.SendCustomGameEventToServer("supporter_pass_equip_item", {
					item_id: requestID,
					hero: item.hero || "global",
					slot_id: item.slot_id || "default",
				});
				Game.EmitSound("General.ButtonClick");
				RenderArmory(GetLocalPlayerData());
				return;
			}

			SetActionPending("purchase", requestID, true);
			GameEvents.SendCustomGameEventToServer("supporter_pass_buy_shop_item", {
				item_id: requestID,
			});
			RenderShop(GetLocalPlayerData());
		});

		var label = $.CreatePanel("Label", button, "");
		if (pending) {
			label.text = Text("xhs_sp_pending", "Pending...");
		} else if (devPreviewOnly) {
			label.text = "PREVIEW ONLY";
		} else if (mode === "armory") {
			label.text = Text(item.locked ? "xhs_sp_locked" : (item.equipped ? "xhs_sp_equipped" : "xhs_sp_equip"), item.locked ? "Locked" : (item.equipped ? "Equipped" : "Equip"));
		} else {
			label.text = Text(canAfford ? "xhs_sp_buy" : "xhs_sp_locked", canAfford ? "Buy" : "Locked");
		}
	}

	function HasShopData() {
		return GetShopItems().length > 0;
	}

	function UpdateShopAvailability() {
		var available = HasShopData();
		var tab = Panel("XHSPassTabShop");
		var page = Panel("XHSPassShopPage");
		if (tab) {
			tab.SetHasClass("IsHiddenByData", !available);
			tab.hittest = available;
		}
		if (page) {
			page.SetHasClass("IsHiddenByData", !available);
			if (!available && page.BHasClass("IsVisible")) {
				SwitchPage("overview");
			}
		}
	}

	function RenderShop(player) {
		var parent = Panel("XHSPassShopGrid");
		ClearPanel(parent);
		ClearPanel(Panel("XHSPassShopPager"));

		var data = GetTable("supporter_pass_shop", "featured", {}) || {};
		var refresh = data.refresh_label || data.refresh_at || Text("xhs_sp_featured_rotation", "Featured rotation");
		SetText("XHSPassShopRefresh", LocalizeMaybeKey(refresh.toString()));

		var items = GetShopItems();
		currentShopFilter = RenderCategoryTabs("XHSPassShopFilters", items, currentShopFilter, function (filterName) {
			currentShopFilter = filterName;
			ResetPagination("shop");
			RenderShop(player);
		});

		if (items.length === 0) {
			CreateEmpty(parent, Text("xhs_sp_shop_unavailable", "Shop unavailable"), Text("xhs_sp_shop_unavailable_body", "The Fragment Shop catalog has not been sent by the backend yet."));
			return;
		}

		var filteredItems = FilterItemsByCategory(items, currentShopFilter);
		RenderPaginationControls("XHSPassShopPager", "shop", filteredItems.length, function () {
			RenderShop(GetLocalPlayerData());
		});
		if (filteredItems.length === 0) {
			CreateEmpty(parent, Text("xhs_sp_no_shop_items", "No shop items"), Text("xhs_sp_no_shop_items_body", "No Fragment Shop items match this category."));
			return;
		}

		var pageItems = GetPageSlice(filteredItems, "shop");
		for (var i = 0; i < pageItems.length; i++) {
			CreateShopCard(parent, pageItems[i], player, "shop");
		}
	}

	function GetItemCategory(item) {
		return NormalizeArmoryItemType(item);
	}

	function GetCategoryKey(category) {
		if (category === DEV_ASSET_FILTER) {
			return "devassets";
		}
		if (category === "All") {
			return "all";
		}
		return (category || "Cosmetic")
			.toString()
			.toLowerCase()
			.replace(/[^a-z0-9]/g, "");
	}

	function GetItemCategories(items, player) {
		var available = {};
		for (var i = 0; i < items.length; i++) {
			var type = GetItemCategory(items[i]);
			var key = GetCategoryKey(type);
			if (!available[key]) {
				available[key] = type;
			}
		}

		var filters = ["All"];
		var categoryOrder = [
			"Cosmetic",
			"Teleport FX",
			"Tome FX",
			"Kill FX",
			"Companion",
			"Emblem",
			"Effigy",
			"Potion FX",
			"Rebirth FX",
			"Attack Lifesteal",
			"Spell Lifesteal",
			"Regen Aura",
			"Immolation",
			"High Five",
			"Title",
			"Bundle",
			"Pudge Hook",
			"Pudge Arcana",
			"Streak Counter",
		];
		var showDevAssets = IsLocalSupporterDeveloper(player);
		var devAssetsAdded = false;
		for (var j = 0; j < categoryOrder.length; j++) {
			var orderedKey = GetCategoryKey(categoryOrder[j]);
			if (available[orderedKey]) {
				filters.push(categoryOrder[j]);
				delete available[orderedKey];
			}
			if (categoryOrder[j] === "Effigy" && showDevAssets) {
				filters.push(DEV_ASSET_FILTER);
				devAssetsAdded = true;
			}
		}
		for (var remainingKey in available) {
			if (available.hasOwnProperty(remainingKey)) {
				filters.push(available[remainingKey]);
			}
		}
		if (showDevAssets && !devAssetsAdded) {
			filters.push(DEV_ASSET_FILTER);
		}
		return filters;
	}

	function FilterItemsByCategory(items, category) {
		if (category === "All") {
			return items;
		}

		var filtered = [];
		var categoryKey = GetCategoryKey(category);
		for (var i = 0; i < items.length; i++) {
			if (GetCategoryKey(GetItemCategory(items[i])) === categoryKey) {
				filtered.push(items[i]);
			}
		}
		return filtered;
	}

	function RenderCategoryTabs(parentID, items, activeFilter, onSelect, player) {
		var parent = Panel(parentID);
		ClearPanel(parent);
		if (!parent) {
			return activeFilter;
		}

		var filters = GetItemCategories(items, player);
		var activeExists = false;
		for (var f = 0; f < filters.length; f++) {
			if (GetCategoryKey(filters[f]) === GetCategoryKey(activeFilter)) {
				activeFilter = filters[f];
				activeExists = true;
				break;
			}
		}
		if (!activeExists) {
			activeFilter = "All";
		}

		for (var i = 0; i < filters.length; i++) {
			(function (filterName) {
				var button = $.CreatePanel("Button", parent, "");
				button.AddClass("XHSPassFilterTab");
				button.SetHasClass("IsActive", activeFilter === filterName);
				button.SetPanelEvent("onactivate", function () {
					onSelect(filterName);
				});

				var label = $.CreatePanel("Label", button, "");
				label.text = filterName === "All"
					? Text("xhs_sp_filter_all", "All")
					: (filterName === DEV_ASSET_FILTER
						? "DEV ASSETS"
						: DisplayRewardType(filterName));
			})(filters[i]);
		}

		return activeFilter;
	}

	function GetRewardVisualAsset(reward) {
		return reward && (reward.image || reward.image_inventory || reward.icon || reward.icon_path) || "";
	}

	function GetDevRewardTargets() {
		var targets = [];
		var tracks = ["free", "premium"];
		for (var t = 0; t < tracks.length; t++) {
			var track = tracks[t];
			var rewards = GetRewards(track);
			for (var i = 0; i < rewards.length; i++) {
				var reward = rewards[i];
				var identity = reward.reward_id || reward.item_id || reward.catalog_item_id || reward.id || reward.name || i;
				var key = track + ":" + identity.toString() + ":" + ToNumber(reward.level_required || reward.level, 0);
				var originalAsset = GetRewardVisualAsset(reward);
				if (devAssetAssignments[key] === undefined) {
					devAssetAssignments[key] = originalAsset;
				}
				targets.push({
					key: key,
					track: track,
					level: ToNumber(reward.level_required || reward.level, 0),
					reward: reward,
					original_asset: originalAsset,
				});
			}
		}
		return targets;
	}

	function GetDevRewardAssets(targets) {
		var assets = [];
		var seen = {};
		for (var i = 0; i < targets.length; i++) {
			var assetPath = targets[i].original_asset;
			if (!assetPath) {
				continue;
			}
			var key = NormalizeImagePath(assetPath).toLowerCase();
			if (seen[key]) {
				continue;
			}
			seen[key] = true;
			var visual = CopyObject(targets[i].reward);
			visual.image = assetPath;
			assets.push({
				key: key,
				path: assetPath,
				visual: visual,
			});
		}
		return assets;
	}

	function GetDevAssignedAsset(target) {
		if (devAssetAssignments.hasOwnProperty(target.key)) {
			return devAssetAssignments[target.key];
		}
		return target.original_asset;
	}

	function GetRewardRuntimeAssets(reward) {
		reward = reward || {};
		var assets = [];
		var seen = {};
		function AddRuntimeAsset(kind, hook, path) {
			path = (path || "").toString();
			if (!path || seen[path]) {
				return;
			}
			seen[path] = true;
			assets.push({
				kind: (kind || "asset").toString(),
				hook: (hook || "").toString(),
				path: path,
			});
		}

		var published = [];
		var rawPublished = reward.runtime_assets || reward.runtimeAssets || [];
		if (Object.prototype.toString.call(rawPublished) === "[object Array]") {
			published = rawPublished;
		} else if (rawPublished && typeof rawPublished === "object") {
			if (rawPublished.path !== undefined || rawPublished.modifier !== undefined) {
				published.push(rawPublished);
			} else {
				var runtimeKeys = [];
				for (var runtimeKey in rawPublished) {
					if (rawPublished.hasOwnProperty(runtimeKey) && /^\d+$/.test(runtimeKey)) {
						runtimeKeys.push(runtimeKey);
					}
				}
				runtimeKeys.sort(function (a, b) { return Number(a) - Number(b); });
				for (var runtimeIndex = 0; runtimeIndex < runtimeKeys.length; runtimeIndex++) {
					var runtimeValue = rawPublished[runtimeKeys[runtimeIndex]];
					if (runtimeValue && typeof runtimeValue === "object") {
						published.push(runtimeValue);
					}
				}
			}
		}
		for (var i = 0; i < published.length; i++) {
			var runtime = published[i] || {};
			AddRuntimeAsset(runtime.kind || runtime.type, runtime.hook || runtime.asset, runtime.path || runtime.modifier);
		}
		AddRuntimeAsset("particle", "teleport_start", reward.start_pfx);
		AddRuntimeAsset("particle", "teleport_end", reward.end_pfx);
		AddRuntimeAsset("particle", "target", reward.target_pfx);
		AddRuntimeAsset("particle", "caster", reward.caster_pfx);
		AddRuntimeAsset("particle", "health", reward.health_pfx);
		AddRuntimeAsset("particle", "mana", reward.mana_pfx);
		AddRuntimeAsset("particle", "light", reward.light_pfx);
		AddRuntimeAsset("particle", "owner", reward.owner_pfx);
		AddRuntimeAsset("particle", "high_five_overhead", reward.overhead_pfx);
		AddRuntimeAsset("particle", "high_five_travel", reward.travel_pfx);
		AddRuntimeAsset("particle", "high_five_impact", reward.impact_pfx);
		AddRuntimeAsset("particle", "", reward.particle || reward.pfx);
		AddRuntimeAsset("model", "", reward.model || reward.model_path);
		AddRuntimeAsset("unit", "", reward.unit || reward.unit_name);
		if (reward.file) {
			var fileKind = reward.file.toString().indexOf(".vpcf") !== -1 ? "particle" :
				(reward.file.toString().indexOf(".vmdl") !== -1 ? "model" : "file");
			AddRuntimeAsset(fileKind, "", reward.file);
		}
		return assets;
	}

	function FormatRewardRuntimeAssets(reward) {
		var assets = GetRewardRuntimeAssets(reward);
		if (assets.length === 0) {
			return "RUNTIME \u00b7 (unavailable)";
		}
		var lines = [];
		for (var i = 0; i < assets.length; i++) {
			var asset = assets[i];
			var prefix = asset.kind.toUpperCase();
			lines.push(prefix + " \u00b7 " + (asset.hook ? asset.hook + " \u2192 " : "") + asset.path);
		}
		return lines.join("\n");
	}

	function GetRuntimeAssetRole(asset) {
		var hook = (asset.hook || "").toLowerCase();
		if (hook.indexOf("teleport_start") !== -1) {
			return "TP START";
		}
		if (hook.indexOf("teleport_end") !== -1) {
			return "TP END";
		}
		if (hook.indexOf("target") !== -1) {
			return "TARGET";
		}
		if (hook.indexOf("caster") !== -1) {
			return "CASTER";
		}
		if (hook.indexOf("health") !== -1) {
			return "HEALTH";
		}
		if (hook.indexOf("mana") !== -1) {
			return "MANA";
		}
		if (hook.indexOf("owner") !== -1) {
			return "OWNER";
		}
		if (hook.indexOf("overhead") !== -1) {
			return "OVERHEAD";
		}
		if (hook.indexOf("travel") !== -1) {
			return "TRAVEL";
		}
		if (hook.indexOf("impact") !== -1) {
			return "IMPACT";
		}
		if (hook.indexOf("hero_emblem") !== -1) {
			return "EMBLEM";
		}

		var kind = (asset.kind || "asset").toUpperCase();
		return kind === "PARTICLE" ? "PFX" : kind;
	}

	function CreateRewardRuntimeAssetSummary(parent, reward) {
		var container = $.CreatePanel("Panel", parent, "");
		container.AddClass("XHSPassDevTargetRuntimeAssets");
		var assets = GetRewardRuntimeAssets(reward);
		if (assets.length === 0) {
			var unavailable = $.CreatePanel("Label", container, "");
			unavailable.AddClass("XHSPassDevRuntimeUnavailable");
			unavailable.text = "RUNTIME \u00b7 (unavailable)";
			return;
		}

		for (var i = 0; i < assets.length; i++) {
			(function (asset) {
				var item = $.CreatePanel("Panel", container, "");
				item.AddClass("XHSPassDevRuntimeAsset");
				var slashIndex = asset.path.lastIndexOf("/");
				var fileName = slashIndex >= 0 ? asset.path.substring(slashIndex + 1) : asset.path;
				var directory = slashIndex >= 0 ? asset.path.substring(0, slashIndex + 1) : "";

				var name = $.CreatePanel("Label", item, "");
				name.AddClass("XHSPassDevRuntimeAssetName");
				name.text = GetRuntimeAssetRole(asset) + " \u00b7 " + fileName;

				var path = $.CreatePanel("Label", item, "");
				path.AddClass("XHSPassDevRuntimeAssetDirectory");
				path.text = directory;

				var tooltip = (asset.hook ? asset.hook + " \u2192 " : "") + asset.path;
				item.SetPanelEvent("onmouseover", function () {
					$.DispatchEvent("UIShowTextTooltip", item, tooltip);
				});
				item.SetPanelEvent("onmouseout", function () {
					$.DispatchEvent("UIHideTextTooltip", item);
				});
			})(assets[i]);
		}
	}

	function GetDevTestSlot(reward) {
		var value = ((reward && (reward.slot_id || reward.item_type || reward.type)) || "").toString().toLowerCase();
		return CanonicalSupporterSlot(value);
	}

	function GetDevTestItemID(reward) {
		var value = reward && (reward.entitlement_id || reward.item_id || reward.catalog_item_id || reward.reward_item_id || reward.id);
		return value === undefined || value === null ? "" : value.toString();
	}

	function IsDevTestSlotSupported(slot) {
		return slot === "teleport" || slot === "levelup" || slot === "kill_effect" ||
			slot === "emblem" || slot === "companion" || slot === "effigy" ||
			slot === "potion" || slot === "rebirth" || slot === "attack_lifesteal" ||
			slot === "spell_lifesteal" || slot === "regen_aura" || slot === "immolation" ||
			slot === "high_five";
	}

	function IsDevTestPersistentSlot(slot) {
		return slot === "emblem" || slot === "companion" || slot === "effigy";
	}

	function IsDevTestBusy() {
		return devTestState.status === "pending" ||
			(devTestState.status === "active" && !IsDevTestPersistentSlot(devTestState.slot_id));
	}

	function GetDevTestButtonText(slot, active) {
		if (active) {
			return Text("xhs_sp_dev_test_active_button", "ACTIVE");
		}
		if (slot === "teleport") {
			return Text("xhs_sp_dev_test_teleport", "TEST TP");
		}
		if (slot === "levelup") {
			return Text("xhs_sp_dev_test_fx", "TEST FX");
		}
		if (slot === "kill_effect") {
			return Text("xhs_sp_dev_test_kill", "TEST KILL");
		}
		if (slot === "potion") {
			return Text("xhs_sp_dev_test_potion", "TEST POTION");
		}
		if (slot === "rebirth") {
			return Text("xhs_sp_dev_test_rebirth", "TEST REBIRTH");
		}
		if (slot === "attack_lifesteal") {
			return Text("xhs_sp_dev_test_attack_lifesteal", "TEST ATTACK STEAL");
		}
		if (slot === "spell_lifesteal") {
			return Text("xhs_sp_dev_test_spell_lifesteal", "TEST SPELL STEAL");
		}
		if (slot === "regen_aura" || slot === "immolation") {
			return Text("xhs_sp_dev_test_preview", "PREVIEW");
		}
		if (slot === "high_five") {
			return Text("xhs_sp_dev_test_high_five", "TEST HIGH FIVE");
		}
		if (IsDevTestPersistentSlot(slot)) {
			return Text("xhs_sp_dev_test_preview", "PREVIEW");
		}
		return Text("xhs_sp_dev_test_unsupported", "UNSUPPORTED");
	}

	function StartDevRewardTest(target, player) {
		var slot = GetDevTestSlot(target.reward);
		var itemID = GetDevTestItemID(target.reward);
		if (!IsDevTestSlotSupported(slot) || !itemID || IsDevTestBusy()) {
			Game.EmitSound("General.Cancel");
			return;
		}

		devTestRequestSerial += 1;
		var requestID = "sp-dev-" + devTestRequestSerial + "-" + Math.floor(Game.GetGameTime() * 1000);
		devTestState = {
			status: "pending",
			request_id: requestID,
			item_id: itemID,
			slot_id: slot,
			message: "#xhs_sp_dev_test_pending",
		};
		RenderArmory(player);
		GameEvents.SendCustomGameEventToServer("supporter_pass_dev_test_reward", {
			item_id: itemID,
			slot_id: slot,
			action: "test",
			request_id: requestID,
		});
		$.Msg("[XHS_SP_TEST_RUNTIME] item=" + itemID + " slot=" + slot + "\n" + FormatRewardRuntimeAssets(target.reward));
		ToggleWindow(false);

		$.Schedule(8.0, function () {
			if (devTestState.status === "pending" && devTestState.request_id === requestID) {
				devTestState.status = "error";
				devTestState.message = "#xhs_sp_dev_test_error_timeout";
				ShowActionMessage(Text("xhs_sp_dev_test_error_timeout", "The test request timed out."), false);
				RenderArmory(GetLocalPlayerData());
			}
		});
	}

	function StopDevRewardTest(player) {
		if (devTestState.status === "pending") {
			Game.EmitSound("General.Cancel");
			return;
		}
		devTestRequestSerial += 1;
		var requestID = "sp-stop-" + devTestRequestSerial + "-" + Math.floor(Game.GetGameTime() * 1000);
		devTestState.status = "pending";
		devTestState.request_id = requestID;
		devTestState.message = "#xhs_sp_dev_test_stopping";
		RenderArmory(player);
		GameEvents.SendCustomGameEventToServer("supporter_pass_dev_stop_test", {
			action: "stop",
			request_id: requestID,
		});
	}

	function CreateDevAssetButton(parent, asset, player) {
		var button = $.CreatePanel("Button", parent, "");
		button.AddClass("XHSPassDevAssetCard");
		button.SetHasClass("IsSelected", devSelectedAsset === asset.path);
		button.SetPanelEvent("onactivate", function () {
			devSelectedAsset = asset.path;
			Game.EmitSound("General.ButtonClick");
			RenderArmory(player);
		});

		CreateItemPreview(button, asset.visual, "XHSPassDevAssetPreview", "XHSPassDevAssetImage");
		var label = $.CreatePanel("Label", button, "");
		label.AddClass("XHSPassDevAssetPath");
		label.text = asset.path;
	}

	function CreateDevRewardTarget(parent, target, player) {
		var row = $.CreatePanel("Panel", parent, "");
		row.AddClass("XHSPassDevRewardTarget");
		var assignedAsset = GetDevAssignedAsset(target);
		row.SetHasClass("IsChanged", assignedAsset !== target.original_asset);
		row.SetHasClass("IsUnassigned", assignedAsset === "");
		var testSlot = GetDevTestSlot(target.reward);
		var testItemID = GetDevTestItemID(target.reward);
		var testSupported = IsDevTestSlotSupported(testSlot) && testItemID !== "";
		var isTestTarget = devTestState.item_id === testItemID && devTestState.slot_id === testSlot;
		row.SetHasClass("IsTestActive", isTestTarget && devTestState.status === "active");
		row.SetHasClass("IsTestPending", isTestTarget && devTestState.status === "pending");
		row.SetHasClass("IsTestError", isTestTarget && devTestState.status === "error");

		var previewData = CopyObject(target.reward);
		previewData.image = assignedAsset;
		CreateItemPreview(row, previewData, "XHSPassDevTargetPreview", "XHSPassDevTargetImage");

		var copy = $.CreatePanel("Panel", row, "");
		copy.AddClass("XHSPassDevTargetCopy");
		var title = $.CreatePanel("Label", copy, "");
		title.AddClass("XHSPassDevTargetTitle");
		title.text = target.track.toUpperCase() + " \u00b7 LVL " + target.level + " \u00b7 " +
			LocalizeMaybeKey(target.reward.name || target.reward.item_name || target.key);
		var metadata = $.CreatePanel("Label", copy, "");
		metadata.AddClass("XHSPassDevTargetMeta");
		metadata.text = "item=" + (target.reward.item_id || "-") +
			"  slot=" + (target.reward.slot_id || target.reward.type || "-");
		var path = $.CreatePanel("Label", copy, "");
		path.AddClass("XHSPassDevTargetPath");
		path.text = assignedAsset || "(unassigned)";
		CreateRewardRuntimeAssetSummary(copy, target.reward);
		var testStatus = $.CreatePanel("Label", copy, "");
		testStatus.AddClass("XHSPassDevTestState");
		testStatus.text = isTestTarget && devTestState.status !== "idle"
			? LocalizeMaybeKey(devTestState.message || ("#xhs_sp_dev_test_" + devTestState.status))
			: (testSupported ? Text("xhs_sp_dev_test_ready", "Ready to test") : Text("xhs_sp_dev_test_type_unsupported", "Unsupported reward type"));

		var actions = $.CreatePanel("Panel", row, "");
		actions.AddClass("XHSPassDevTargetActions");
		var testButton = $.CreatePanel("Button", actions, "");
		testButton.AddClass("XHSPassDevTestButton");
		testButton.SetHasClass("IsActive", isTestTarget && devTestState.status === "active");
		testButton.SetHasClass("IsPending", isTestTarget && devTestState.status === "pending");
		testButton.SetHasClass("IsLocked", !testSupported || IsDevTestBusy());
		testButton.SetPanelEvent("onactivate", function () {
			StartDevRewardTest(target, player);
		});
		var testLabel = $.CreatePanel("Label", testButton, "");
		testLabel.text = isTestTarget && devTestState.status === "pending"
			? Text("xhs_sp_dev_test_pending_button", "TESTING...")
			: GetDevTestButtonText(testSlot, isTestTarget && devTestState.status === "active");

		var assignButton = $.CreatePanel("Button", actions, "");
		assignButton.AddClass("XHSPassDevAssignButton");
		assignButton.SetHasClass("IsLocked", !devSelectedAsset);
		assignButton.SetPanelEvent("onactivate", function () {
			if (!devSelectedAsset) {
				Game.EmitSound("General.Cancel");
				return;
			}
			devAssetAssignments[target.key] = devSelectedAsset;
			Game.EmitSound("General.ButtonClick");
			RenderArmory(player);
		});
		var assignLabel = $.CreatePanel("Label", assignButton, "");
		assignLabel.text = devSelectedAsset ? "ASSIGN" : "SELECT ASSET";

		var unassignButton = $.CreatePanel("Button", actions, "");
		unassignButton.AddClass("XHSPassDevAssignButton");
		unassignButton.AddClass("IsUnassign");
		unassignButton.SetHasClass("IsLocked", assignedAsset === "");
		unassignButton.SetPanelEvent("onactivate", function () {
			if (GetDevAssignedAsset(target) === "") {
				Game.EmitSound("General.Cancel");
				return;
			}
			devAssetAssignments[target.key] = "";
			Game.EmitSound("General.ButtonClick");
			RenderArmory(player);
		});
		var unassignLabel = $.CreatePanel("Label", unassignButton, "");
		unassignLabel.text = "UNASSIGN";
	}

	function ResetDevAssetAssignments(player) {
		devSelectedAsset = "";
		devAssetAssignments = {};
		GetDevRewardTargets();
		RenderArmory(player);
	}

	function UnassignAllDevAssets(player) {
		var targets = GetDevRewardTargets();
		devSelectedAsset = "";
		for (var i = 0; i < targets.length; i++) {
			devAssetAssignments[targets[i].key] = "";
		}
		RenderArmory(player);
	}

	function BuildDevAssetMappingPayload() {
		var targets = GetDevRewardTargets();
		var assignments = [];
		var changes = [];
		for (var i = 0; i < targets.length; i++) {
			var target = targets[i];
			var reward = target.reward;
			var assignedAsset = GetDevAssignedAsset(target);
			var entry = {
				track: target.track,
				level: target.level,
				reward_id: reward.reward_id || reward.id || "",
				item_id: reward.item_id || reward.catalog_item_id || "",
				name: reward.name || reward.item_name || "",
				type: reward.type || reward.item_type || "",
				slot_id: reward.slot_id || "",
				runtime_assets: GetRewardRuntimeAssets(reward),
				original_asset: target.original_asset,
				image: assignedAsset,
			};
			assignments.push(entry);
			if (assignedAsset !== target.original_asset) {
				changes.push(entry);
			}
		}
		return {
			schema: "xhs_supporter_reward_asset_assignments_v1",
			assignments: assignments,
			changes: changes,
		};
	}

	function LogDevAssetMapping() {
		var payload = BuildDevAssetMappingPayload();
		$.Msg("[XHS_SP_ASSET_MAP_BEGIN]");
		$.Msg(JSON.stringify(payload));
		$.Msg("[XHS_SP_ASSET_MAP_END]");
		ShowActionMessage("Asset mapping logged: " + payload.changes.length + " change(s).", true);
		Game.EmitSound("General.ButtonClick");
		return payload;
	}

	function CreateDevTargetBucket(parent, title, targets, player, bucketClass) {
		var bucket = $.CreatePanel("Panel", parent, "");
		bucket.AddClass("XHSPassDevTargetBucket");
		bucket.AddClass(bucketClass);
		var header = $.CreatePanel("Label", bucket, "");
		header.AddClass("XHSPassDevColumnTitle");
		header.text = title + " (" + targets.length + ")";
		var list = $.CreatePanel("Panel", bucket, "");
		list.AddClass("XHSPassDevTargetList");

		if (targets.length === 0) {
			var empty = $.CreatePanel("Label", list, "");
			empty.AddClass("XHSPassDevBucketEmpty");
			empty.text = bucketClass === "IsUnassignedBucket"
				? "Everything has an asset."
				: "No asset assigned yet.";
			return;
		}

		for (var i = 0; i < targets.length; i++) {
			CreateDevRewardTarget(list, targets[i], player);
		}
	}

	function RenderDevAssetMapper(parent, player) {
		var targets = GetDevRewardTargets();
		var assets = GetDevRewardAssets(targets);
		var unassignedTargets = [];
		var assignedTargets = [];
		for (var t = 0; t < targets.length; t++) {
			if (GetDevAssignedAsset(targets[t]) === "") {
				unassignedTargets.push(targets[t]);
			} else {
				assignedTargets.push(targets[t]);
			}
		}
		var root = $.CreatePanel("Panel", parent, "");
		root.AddClass("XHSPassDevAssetMapper");

		var toolbar = $.CreatePanel("Panel", root, "");
		toolbar.AddClass("XHSPassDevAssetToolbar");
		var toolbarCopy = $.CreatePanel("Panel", toolbar, "");
		toolbarCopy.AddClass("XHSPassDevAssetToolbarCopy");
		var title = $.CreatePanel("Label", toolbarCopy, "");
		title.AddClass("XHSPassDevAssetTitle");
		title.text = "REWARD ASSET MAPPER";
		var status = $.CreatePanel("Label", toolbarCopy, "");
		status.AddClass("XHSPassDevAssetStatus");
		if (devTestState.status !== "idle" && devTestState.item_id) {
			status.text = LocalizeMaybeKey(devTestState.message || "#xhs_sp_dev_test_active") +
				" \u00b7 " + devTestState.slot_id.toUpperCase() + " \u00b7 item " + devTestState.item_id;
		} else {
			status.text = devSelectedAsset ? "Selected: " + devSelectedAsset : "1. Select an asset  \u00b7  2. Assign it to rewards  \u00b7  3. Log final mapping";
		}

		var stopTestButton = $.CreatePanel("Button", toolbar, "");
		stopTestButton.AddClass("XHSPassDevToolbarButton");
		stopTestButton.AddClass("IsStopTest");
		var canStopTest = devTestState.status === "active" && IsDevTestPersistentSlot(devTestState.slot_id);
		stopTestButton.SetHasClass("IsLocked", !canStopTest);
		stopTestButton.SetPanelEvent("onactivate", function () {
			if (!canStopTest) {
				Game.EmitSound("General.Cancel");
				return;
			}
			StopDevRewardTest(player);
		});
		var stopTestLabel = $.CreatePanel("Label", stopTestButton, "");
		stopTestLabel.text = Text("xhs_sp_dev_stop_test", "STOP TEST");

		var resetButton = $.CreatePanel("Button", toolbar, "");
		resetButton.AddClass("XHSPassDevToolbarButton");
		resetButton.SetPanelEvent("onactivate", function () { ResetDevAssetAssignments(player); });
		var resetLabel = $.CreatePanel("Label", resetButton, "");
		resetLabel.text = "RESET";

		var unassignAllButton = $.CreatePanel("Button", toolbar, "");
		unassignAllButton.AddClass("XHSPassDevToolbarButton");
		unassignAllButton.AddClass("IsDanger");
		unassignAllButton.SetPanelEvent("onactivate", function () { UnassignAllDevAssets(player); });
		var unassignAllLabel = $.CreatePanel("Label", unassignAllButton, "");
		unassignAllLabel.text = "UNASSIGN ALL";

		var logButton = $.CreatePanel("Button", toolbar, "");
		logButton.AddClass("XHSPassDevToolbarButton");
		logButton.AddClass("IsPrimary");
		logButton.SetPanelEvent("onactivate", LogDevAssetMapping);
		var logLabel = $.CreatePanel("Label", logButton, "");
		logLabel.text = "LOG FINAL MAPPING";

		var columns = $.CreatePanel("Panel", root, "");
		columns.AddClass("XHSPassDevAssetColumns");
		var assetColumn = $.CreatePanel("Panel", columns, "");
		assetColumn.AddClass("XHSPassDevAssetColumn");
		var assetHeader = $.CreatePanel("Label", assetColumn, "");
		assetHeader.AddClass("XHSPassDevColumnTitle");
		assetHeader.text = "ASSETS IN USE (" + assets.length + ")";
		var assetGrid = $.CreatePanel("Panel", assetColumn, "");
		assetGrid.AddClass("XHSPassDevAssetGrid");
		for (var a = 0; a < assets.length; a++) {
			CreateDevAssetButton(assetGrid, assets[a], player);
		}

		var targetColumn = $.CreatePanel("Panel", columns, "");
		targetColumn.AddClass("XHSPassDevTargetColumn");
		CreateDevTargetBucket(targetColumn, "UNASSIGNED", unassignedTargets, player, "IsUnassignedBucket");
		CreateDevTargetBucket(targetColumn, "ASSIGNED", assignedTargets, player, "IsAssignedBucket");
	}

	function GetCourierDisplayName(courier) {
		if (courier.item_name) {
			var localized = $.Localize(courier.item_name);
			if (localized && localized !== courier.item_name) {
				return localized;
			}
		}
		return courier.name || Text("xhs_sp_courier_fallback_name", "Courier");
	}

	function CreateCourierRequestCard(parent, courier, rerender) {
		var card = $.CreatePanel("Panel", parent, "");
		card.AddClass("XHSPassShopCard");
		card.AddClass("XHSPassCourierRequestCard");
		card.AddClass("HasAnimatedPreview");

		var preview = $.CreatePanel("Panel", card, "");
		preview.AddClass("XHSPassItemPreview");
		preview.AddClass("XHSPassShopPreview");
		preview.AddClass("HasAnimatedModel");

		var scene = $.CreatePanel("DOTAScenePanel", preview, "", {
			"class": "XHSPassCompanionScene XHSPassCourierScene",
			environment: "default",
			hittest: "false",
			particleonly: "false",
			unit: courier.unit,
			itemdef: courier.item_def,
			activity: "ACT_DOTA_IDLE",
		});
		scene.hittest = false;

		var name = $.CreatePanel("Label", card, "");
		name.AddClass("XHSPassShopName");
		name.text = GetCourierDisplayName(courier);

		var meta = $.CreatePanel("Label", card, "");
		meta.AddClass("XHSPassShopMeta");
		meta.text = Text("xhs_sp_courier_request_meta", "{rarity} courier · Item {item}", {
			rarity: LocalizeMaybeKey(courier.rarity || Text("xhs_sp_common", "Common")),
			item: courier.item_def,
		});

		var model = $.CreatePanel("Label", card, "");
		model.AddClass("XHSPassCourierModel");
		model.text = (courier.model || "").replace(/^.*\//, "");
		model.SetPanelEvent("onmouseover", function () {
			$.DispatchEvent("DOTAShowTextTooltip", model, courier.model || "");
		});
		model.SetPanelEvent("onmouseout", function () {
			$.DispatchEvent("DOTAHideTextTooltip", model);
		});

		var state = courierRequestState[courier.item_def] || "idle";
		var button = $.CreatePanel("Button", card, "");
		button.AddClass("XHSPassShopButton");
		button.AddClass("XHSPassCourierRequestButton");
		button.SetHasClass("IsPending", state === "pending");
		button.SetHasClass("IsSuccess", state === "success");
		button.SetPanelEvent("onactivate", function () {
			if (state === "pending" || state === "success") {
				Game.EmitSound(state === "pending" ? "General.Cancel" : "General.ButtonClick");
				return;
			}
			courierRequestSerial++;
			var requestID = "courier_" + courierRequestSerial + "_" + Date.now();
			courierRequestState[courier.item_def] = "pending";
			GameEvents.SendCustomGameEventToServer("supporter_pass_request_companion", {
				item_def: courier.item_def,
				request_id: requestID,
			});
			Game.EmitSound("General.ButtonClick");
			rerender();
		});

		var buttonLabel = $.CreatePanel("Label", button, "");
		buttonLabel.text = Text(
			state === "pending"
				? "xhs_sp_request_pending"
				: (state === "success" ? "xhs_sp_requested" : "xhs_sp_request_companion"),
			state === "pending" ? "Sending..." : (state === "success" ? "Requested" : "Request companion")
		);
	}

	function RenderCourierRequestViewer(parent, pagerID, rerender) {
		var catalog = GetCourierCatalog();
		RenderPaginationControls(pagerID, "courier", catalog.length, rerender);

		if (catalog.length === 0) {
			CreateEmpty(
				parent,
				Text("xhs_sp_courier_catalog_unavailable", "Courier catalog unavailable"),
				Text("xhs_sp_courier_catalog_unavailable_body", "Generate the catalogue before compiling Panorama.")
			);
			return;
		}

		var pageItems = GetPageSlice(catalog, "courier");
		for (var i = 0; i < pageItems.length; i++) {
			CreateCourierRequestCard(parent, pageItems[i], rerender);
		}
	}

	function RenderCourierRequestOverlay() {
		var grid = Panel("XHSPassCourierRequestGrid");
		ClearPanel(grid);
		ClearPanel(Panel("XHSPassCourierRequestPager"));
		if (!grid) {
			return;
		}

		RenderCourierRequestViewer(grid, "XHSPassCourierRequestPager", RenderCourierRequestOverlay);
	}

	function SetCourierRequestViewerVisible(visible) {
		var overlay = Panel("XHSPassCourierRequestOverlay");
		if (!overlay) {
			return;
		}

		overlay.SetHasClass("IsVisible", visible === true);
		overlay.hittest = visible === true;
		if (visible) {
			ResetPagination("courier");
			RenderCourierRequestOverlay();
			Game.EmitSound("General.ButtonClick");
		}
	}

	function RenderArmory(player) {
		var parent = Panel("XHSPassArmoryGrid");
		ClearPanel(parent);
		ClearPanel(Panel("XHSPassArmoryPager"));

		var items = GetArmoryItems(player);
		currentArmoryFilter = RenderCategoryTabs("XHSPassArmoryFilters", items, currentArmoryFilter, function (filterName) {
			currentArmoryFilter = filterName;
			ResetPagination("armory");
			RenderArmory(player);
		}, player);

		var devAssetMode = currentArmoryFilter === DEV_ASSET_FILTER && IsLocalSupporterDeveloper(player);
		parent.SetHasClass("IsDevAssetMode", devAssetMode);
		if (devAssetMode) {
			RenderDevAssetMapper(parent, player);
			return;
		}

		if (items.length === 0) {
			CreateEmpty(parent, Text("xhs_sp_no_cosmetics", "No unlocked cosmetics"), Text("xhs_sp_no_cosmetics_body", "Unlock cosmetics through the Supporter Pass or Fragment Shop, then equip them here."));
			return;
		}

		var filteredItems = FilterItemsByCategory(items, currentArmoryFilter);
		RenderPaginationControls("XHSPassArmoryPager", "armory", filteredItems.length, function () {
			RenderArmory(GetLocalPlayerData());
		});
		if (filteredItems.length === 0) {
			CreateEmpty(parent, Text("xhs_sp_no_armory_items", "No armory items"), Text("xhs_sp_no_armory_items_body", "No unlocked cosmetics match this category."));
			return;
		}

		var pageItems = GetPageSlice(filteredItems, "armory");
		for (var j = 0; j < pageItems.length; j++) {
			CreateShopCard(parent, pageItems[j], player, "armory");
		}
	}

	function CreateInfoRow(parent, title, description, value) {
		var row = $.CreatePanel("Panel", parent, "");
		row.AddClass("XHSPassSettingRow");

		var copy = $.CreatePanel("Panel", row, "");
		copy.AddClass("XHSPassRowMain");

		var titlePanel = $.CreatePanel("Label", copy, "");
		titlePanel.AddClass("XHSPassRowTitle");
		titlePanel.text = title;

		var descPanel = $.CreatePanel("Label", copy, "");
		descPanel.AddClass("XHSPassRowDescription");
		descPanel.text = description;

		var valuePanel = $.CreatePanel("Label", row, "");
		valuePanel.AddClass("XHSPassRowValue");
		valuePanel.text = value;
	}

	function UpdateSettingsSaveBar() {
		var bar = Panel("XHSPassSettingsSaveBar");
		if (!bar) {
			return;
		}

		bar.SetHasClass("IsDirty", !SettingsEqual(settingsOriginal, settingsDraft) || settingsSaving);
		bar.SetHasClass("IsSaving", settingsSaving);

		var label = bar.FindChildTraverse("XHSPassSettingsSaveText");
		if (label) {
			label.text = Text(settingsSaving ? "xhs_sp_saving_settings" : "xhs_sp_unsaved_changes", settingsSaving ? "Saving settings..." : "Unsaved changes");
		}
	}

	function CreateSettingRow(parent, key, title, description) {
		var row = $.CreatePanel("Panel", parent, "");
		row.AddClass("XHSPassSettingRow");
		row.SetHasClass("IsEnabled", settingsDraft[key] === true);
		row.hittest = true;

		var copy = $.CreatePanel("Panel", row, "");
		copy.AddClass("XHSPassRowMain");
		copy.hittest = false;

		var titlePanel = $.CreatePanel("Label", copy, "");
		titlePanel.AddClass("XHSPassRowTitle");
		titlePanel.text = title;
		titlePanel.hittest = false;

		var descPanel = $.CreatePanel("Label", copy, "");
		descPanel.AddClass("XHSPassRowDescription");
		descPanel.text = description;
		descPanel.hittest = false;

		var toggle = $.CreatePanel("Panel", row, "XHSPassSetting_" + key);
		toggle.AddClass("XHSPassSettingToggle");
		toggle.SetHasClass("IsEnabled", settingsDraft[key] === true);
		toggle.hittest = false;

		var knob = $.CreatePanel("Panel", toggle, "");
		knob.AddClass("XHSPassSettingToggleKnob");
		knob.hittest = false;

		row.SetPanelEvent("onactivate", function () {
			if (settingsSaving) {
				Game.EmitSound("General.Cancel");
				return;
			}

			settingsDraft[key] = settingsDraft[key] !== true;
			row.SetHasClass("IsEnabled", settingsDraft[key] === true);
			toggle.SetHasClass("IsEnabled", settingsDraft[key] === true);
			UpdateSettingsSaveBar();
			Game.EmitSound("General.ButtonClick");
		});
	}

	function CreateSettingActionRow(parent, title, description, buttonText, callback) {
		var row = $.CreatePanel("Panel", parent, "");
		row.AddClass("XHSPassSettingRow");
		row.AddClass("XHSPassSettingActionRow");
		row.hittest = true;

		var copy = $.CreatePanel("Panel", row, "");
		copy.AddClass("XHSPassRowMain");
		copy.hittest = false;

		var titlePanel = $.CreatePanel("Label", copy, "");
		titlePanel.AddClass("XHSPassRowTitle");
		titlePanel.text = title;
		titlePanel.hittest = false;

		var descPanel = $.CreatePanel("Label", copy, "");
		descPanel.AddClass("XHSPassRowDescription");
		descPanel.text = description;
		descPanel.hittest = false;

		var button = $.CreatePanel("Button", row, "");
		button.AddClass("XHSPassSettingActionButton");
		button.SetPanelEvent("onactivate", callback);

		var label = $.CreatePanel("Label", button, "");
		label.text = buttonText;
	}

	function RenderSettings(player) {
		var parent = Panel("XHSPassSettingsRows");
		ClearPanel(parent);

		if (!settingsInitialized) {
			settingsOriginal = BuildSettingsFromPlayer(player);
			settingsDraft = CopySettings(settingsOriginal);
			settingsInitialized = true;
		}

		CreateSettingRow(parent, "toggle_tag", Text("xhs_sp_setting_tag", "Supporter tag"), Text("xhs_sp_setting_tag_desc", "Display your supporter badge above your hero health bar."));
		CreateSettingRow(parent, "pass_rewards", Text("xhs_sp_setting_cosmetics", "Cosmetic rewards"), Text("xhs_sp_setting_cosmetics_desc", "Enable or disable equipped pass cosmetics in-game."));
		CreateSettingRow(parent, "player_xp", Text("xhs_sp_setting_xp", "XP visibility"), Text("xhs_sp_setting_xp_desc", "Show seasonal and account XP in social UI surfaces."));
		CreateSettingRow(parent, "winrate_toggle", Text("xhs_sp_setting_winrate", "Winrate visibility"), Text("xhs_sp_setting_winrate_desc", "Show your seasonal winrate in public profile surfaces."));
		CreateSettingActionRow(parent, Text("xhs_sp_type_companion", "Companion"), Text("xhs_sp_disable_companion_desc", "Remove your current supporter companion for this match."), Text("xhs_sp_disable", "Disable"), function () {
			if (GameEvents && GameEvents.SendCustomGameEventToServer) {
				GameEvents.SendCustomGameEventToServer("supporter_pass_change_companion", {
					unit: "",
					js: true,
				});
				ShowActionMessage(Text("xhs_sp_companion_disabled", "Companion disabled."), true);
				Game.EmitSound("General.ButtonClick");
			}
		});
		UpdateSettingsSaveBar();
	}

	function RenderAll() {
		var player = GetLocalPlayerData();
		UpdateShopAvailability();
		RenderHeader(player);
		RenderTiers();
		RenderRewards(player);
		if (HasShopData()) {
			RenderShop(player);
		}
		RenderArmory(player);
		RenderSettings(player);
	}

	function BindButtons() {
		var button = Panel("XHSSupporterPassButton");
		if (button) {
			button.SetPanelEvent("onactivate", function () {
				RenderAll();
				ToggleWindow();
			});
		}

		var close = Panel("XHSPassCloseButton");
		if (close) {
			close.SetPanelEvent("onactivate", function () {
				SetCourierRequestViewerVisible(false);
				ToggleWindow(false);
			});
		}

		var devUnlockUI = Panel("XHSPassDevUnlockUIButton");
		if (devUnlockUI) {
			devUnlockUI.SetPanelEvent("onactivate", function () {
				var player = GetLocalPlayerData();
				if (!IsLocalSupporterDeveloper(player)) {
					Game.EmitSound("General.Cancel");
					return;
				}

				devUnlockAllUI = !devUnlockAllUI;
				ResetPagination("armory");
				RenderAll();
				ShowActionMessage(
					devUnlockAllUI
						? "DEV UI preview enabled \u00b7 all 50 levels and both tracks are visible."
						: "DEV UI preview disabled \u00b7 account ownership restored.",
					true
				);
				Game.EmitSound("General.ButtonClick");
			});
		}

		var openCourierRequests = Panel("XHSPassCourierRequestOpenButton");
		if (openCourierRequests) {
			openCourierRequests.SetPanelEvent("onactivate", function () {
				SetCourierRequestViewerVisible(true);
			});
		}

		var closeCourierRequests = Panel("XHSPassCourierRequestCloseButton");
		if (closeCourierRequests) {
			closeCourierRequests.SetPanelEvent("onactivate", function () {
				SetCourierRequestViewerVisible(false);
				Game.EmitSound("General.Cancel");
			});
		}

		var courierRequestBackdrop = Panel("XHSPassCourierRequestBackdrop");
		if (courierRequestBackdrop) {
			courierRequestBackdrop.SetPanelEvent("onactivate", function () {
				SetCourierRequestViewerVisible(false);
				Game.EmitSound("General.Cancel");
			});
		}

		var support = Panel("XHSPassSupportButton");
		if (support) {
			support.SetPanelEvent("onactivate", function () {
				OpenExternalURL(GetLocalPlayerData().supporter_url || SUPPORTER_URL);
			});
		}

		var backToTop = Panel("XHSPassBackToTopButton");
		if (backToTop) {
			backToTop.SetPanelEvent("onactivate", ScrollCurrentPageToTop);
		}

		var saveSettings = Panel("XHSPassSettingsSaveButton");
		if (saveSettings) {
			saveSettings.SetPanelEvent("onactivate", function () {
				if (settingsSaving || SettingsEqual(settingsOriginal, settingsDraft)) {
					return;
				}

				settingsSaving = true;
				Game.EmitSound("General.ButtonClick");
				UpdateSettingsSaveBar();
				if (GameEvents && GameEvents.SendCustomGameEventToServer) {
					var payload = CopySettings(settingsDraft);
					payload.player_id = Players.GetLocalPlayer();
					GameEvents.SendCustomGameEventToServer("supporter_pass_update_settings", payload);
					$.Schedule(8.0, function () {
						if (!settingsSaving) {
							return;
						}

						settingsSaving = false;
						settingsDraft = CopySettings(settingsOriginal);
						RenderSettings(GetLocalPlayerData());
						ShowActionMessage(Text("xhs_sp_settings_timeout", "Settings save timed out."), false);
					});
				} else {
					settingsSaving = false;
					UpdateSettingsSaveBar();
				}
			});
		}

		var cancelSettings = Panel("XHSPassSettingsCancelButton");
		if (cancelSettings) {
			cancelSettings.SetPanelEvent("onactivate", function () {
				if (settingsSaving) {
					Game.EmitSound("General.Cancel");
					return;
				}

				settingsDraft = CopySettings(settingsOriginal);
				RenderSettings(GetLocalPlayerData());
				Game.EmitSound("General.Cancel");
			});
		}

		for (var page in TAB_IDS) {
			if (TAB_IDS.hasOwnProperty(page)) {
				(function (pageName) {
					var tab = Panel(TAB_IDS[pageName]);
					if (tab) {
						var isDisabled = DISABLED_PAGES[pageName] === true;
						tab.SetHasClass("IsDisabled", isDisabled);
						tab.SetPanelEvent("onactivate", function () { SwitchPage(pageName); });
					}
				})(page);
			}
		}

		if (GameEvents && GameEvents.Subscribe) {
			GameEvents.Subscribe("supporter_pass_purchase_pending", function () {
				ShowActionMessage(Text("xhs_sp_purchase_pending", "Supporter Pass purchase pending..."), true);
			});
			GameEvents.Subscribe("supporter_pass_purchase_success", function (payload) {
				SetActionPending("purchase", payload && payload.item_id, false);
				ShowActionMessage(Text(payload && payload.already_owned ? "xhs_sp_already_owned" : "xhs_sp_purchase_complete", payload && payload.already_owned ? "Already owned." : "Purchase complete."), true);
				RenderAll();
			});
			GameEvents.Subscribe("supporter_pass_purchase_failed", function (payload) {
				SetActionPending("purchase", payload && payload.item_id, false);
				ShowActionMessage(LocalizeMaybeKey((payload && payload.message) || "#xhs_sp_purchase_failed"), false);
				RenderAll();
			});
			GameEvents.Subscribe("supporter_pass_claim_success", function (payload) {
				SetActionPending("claim", payload && payload.reward_id, false);
				ShowActionMessage(Text(payload && payload.already_claimed ? "xhs_sp_reward_already_claimed" : "xhs_sp_reward_claimed", payload && payload.already_claimed ? "Reward already claimed." : "Reward claimed."), true);
				RenderAll();
			});
			GameEvents.Subscribe("supporter_pass_claim_failed", function (payload) {
				SetActionPending("claim", payload && payload.reward_id, false);
				ShowActionMessage(LocalizeMaybeKey((payload && payload.message) || "#xhs_sp_reward_claim_failed"), false);
				RenderAll();
			});
			GameEvents.Subscribe("supporter_pass_equip_success", function (payload) {
				SetActionPending("equip", payload && payload.item_id, false);
				ShowActionMessage(Text("xhs_sp_cosmetic_equipped", "Cosmetic equipped."), true);
				RenderAll();
			});
			GameEvents.Subscribe("supporter_pass_equip_failed", function (payload) {
				SetActionPending("equip", payload && payload.item_id, false);
				ShowActionMessage(LocalizeMaybeKey((payload && payload.message) || "#xhs_sp_equip_failed"), false);
				RenderAll();
			});
			GameEvents.Subscribe("supporter_pass_settings_failed", function (payload) {
				settingsSaving = false;
				settingsDraft = CopySettings(settingsOriginal);
				RenderSettings(GetLocalPlayerData());
				ShowActionMessage(LocalizeMaybeKey((payload && payload.message) || "#xhs_sp_settings_failed"), false);
			});
			GameEvents.Subscribe("supporter_pass_settings_success", function () {
				settingsSaving = false;
				settingsOriginal = CopySettings(settingsDraft);
				UpdateSettingsSaveBar();
				ShowActionMessage(Text("xhs_sp_settings_saved", "Settings saved."), true);
			});
			GameEvents.Subscribe("supporter_pass_dev_test_result", function (payload) {
				payload = payload || {};
				var requestID = (payload.request_id || "").toString();
				if (requestID && devTestState.request_id && requestID !== devTestState.request_id) {
					return;
				}
				var status = (payload.status || "error").toString();
				devTestState = {
					status: status,
					request_id: requestID,
					item_id: (payload.item_id || "").toString(),
					slot_id: (payload.slot_id || "").toString(),
					message: payload.message || ("#xhs_sp_dev_test_" + status),
				};
				if (status === "error") {
					ShowActionMessage(LocalizeMaybeKey(devTestState.message), false);
				} else if (status === "success" || status === "idle") {
					ShowActionMessage(LocalizeMaybeKey(devTestState.message), true);
				}
				RenderArmory(GetLocalPlayerData());
			});
			GameEvents.Subscribe("supporter_pass_companion_request_result", function (payload) {
				payload = payload || {};
				var itemDef = (payload.item_def || "").toString();
				if (!itemDef) {
					return;
				}
				var accepted = payload.accepted === true || payload.accepted === 1;
				courierRequestState[itemDef] = accepted ? "success" : "error";
				ShowActionMessage(
					LocalizeMaybeKey(payload.message || (accepted ? "#xhs_sp_request_recorded" : "#xhs_sp_request_failed")),
					accepted
				);
				var requestOverlay = Panel("XHSPassCourierRequestOverlay");
				if (requestOverlay && requestOverlay.BHasClass("IsVisible")) {
					RenderCourierRequestOverlay();
				}
			});
		}
	}

	function Init() {
		EnsureSupporterPassAboveVanillaHud();
		BindButtons();
		SwitchPage("overview");
		RenderAll();
		if (typeof XHSNameDisplay !== "undefined" && XHSNameDisplay.Subscribe) {
			XHSNameDisplay.Subscribe(function () {
				RenderHeader(GetLocalPlayerData());
			});
		}

		var config = GameUI.CustomUIConfig ? GameUI.CustomUIConfig() : null;
		if (config) {
			config.OpenXHSSupporterPass = function () {
				ToggleWindow(true);
			};
			config.ToggleXHSSupporterPass = function () {
				ToggleWindow();
			};
			if (config.XHSOpenSupporterPassRequested) {
				config.XHSOpenSupporterPassRequested = false;
				ToggleWindow(true);
			}
		}

		if (CustomNetTables.SubscribeNetTableListener) {
			CustomNetTables.SubscribeNetTableListener("supporter_pass_player", RenderAll);
			CustomNetTables.SubscribeNetTableListener("supporter_pass_shop", RenderAll);
			CustomNetTables.SubscribeNetTableListener("supporter_pass_meta", RenderAll);
			var renderPublishedTrack = function (tableName, key) {
				// The server publishes all five chunks before switching this
				// lightweight index, so render only on the atomic index update.
				if (key === "rewards") {
					RenderAll();
				}
			};
			CustomNetTables.SubscribeNetTableListener("supporter_pass_rewards_free", renderPublishedTrack);
			CustomNetTables.SubscribeNetTableListener("supporter_pass_rewards_premium", renderPublishedTrack);
		}
	}

	return {
		Init: Init,
		RenderAll: RenderAll,
		LogDevAssetMapping: LogDevAssetMapping,
		GetDevAssetMapping: BuildDevAssetMappingPayload,
		Open: function () { ToggleWindow(true); },
		Toggle: function () { ToggleWindow(); },
		OpenDiscord: function () { OpenExternalURL(DISCORD_URL); },
	};
})();

(function () {
	$.Schedule(0.0, XHSSupporterPass.Init);
})();
