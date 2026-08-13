"use strict";

var XHSSupporterPass = (function () {
	var SUPPORTER_URL = "https://mods.frostrose-studio.com/supporter-pass";
	var DISCORD_URL = "https://discord.frostrose-studio.com/";
	var SUPPORTER_SHOP_URL = "https://mods.frostrose-studio.com/supporter-pass?tab=shop";
	// Supporter Pass 4.0 purchases are available both in game and on the website.
	var IN_GAME_SHOP_PURCHASES_ENABLED = true;
	var DAILY_GAMEPLAY_FRAGMENT_CAP = 100;
	var DAILY_QUEST_FRAGMENT_CAP = 90;
	var DAILY_FRAGMENT_CAP = DAILY_GAMEPLAY_FRAGMENT_CAP + DAILY_QUEST_FRAGMENT_CAP;
	var WEEKLY_FRAGMENT_CAP = DAILY_FRAGMENT_CAP;
	var SUPPORTER_PASS_LEVEL_COUNT = 50;
	var currentShopFilter = "All";
	var currentShopEditionFilter = "All";
	var currentShopRarityFilter = "All";
	var currentShopSearch = "";
	var currentShopView = "highlights";
	var shopSearchTelemetrySerial = 0;
	var supporterUITelemetrySequence = 0;
	var shopDetailItem = null;
	var shopTransportCache = null;
	var shopTransportGeneration = -1;
	var activePageName = "overview";
	var currentAchievementFilter = "all";
	var achievementRevealQueue = [];
	var achievementRevealActive = null;
	var achievementRevealKnown = {};
	var currentArmoryFilter = "All";
	var armorySearchByCategory = {};
	var armorySearchRenderSerial = 0;
	var armoryRefreshPending = false;
	var paginationState = {
		shop: { page: 0, page_size: 12 },
		armory: { page: 0, page_size: 10 },
		asset_request: { page: 0, page_size: 10 },
	};
	var assetRequestSerial = 0;
	var shopPurchaseSerial = 0;
	var bundleOpenSerial = 0;
	var pendingPurchaseConfirmation = null;
	var purchaseRequestByItem = {};
	var bundleOpenRequestByInstance = {};
	var assetRequestResultState = {};
	var assetRequestView = {
		request_type: "companion",
		category: "courier",
		search: "",
	};
	var settingsOriginal = {};
	var settingsDraft = {};
	var settingsInitialized = false;
	var settingsSaving = false;
	var backToTopPollScheduled = false;
	var fragmentCounterInitialized = false;
	var lastLocalFragmentBalance = 0;
	var lastFragmentRewardEventID = "";
	var fragmentFlyoutIndex = 0;
	var displayedFragmentBalance = 0;
	var fragmentCounterAnimationSerial = 0;
	var fragmentCounterAnimating = false;
	var actionToastSerial = 0;
	var pendingActions = {};
	var windowAnimationSerial = 0;
	var DEV_ASSET_FILTER = "Dev Assets";
	var devUnlockAllUI = false;
	var devUnlockFreeUI = false;
	var devLocallyClaimedRewards = {};
	var devLocalEquippedBySlot = {};
	var DEV_LOCAL_LOADOUT_SLOTS = [
		"teleport", "levelup", "kill_effect", "companion", "emblem",
		"potion", "rebirth", "attack_lifesteal", "spell_lifesteal", "regen_aura",
		"immolation", "title",
	];
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
	var catalogPreviewRequestSerial = 0;
	var catalogPreviewState = {
		status: "idle",
		request_id: "",
		item_id: "",
		slot_id: "",
		category: "",
		message: "",
		expires_in: 0,
		started_at_ms: 0,
	};
	var CATALOG_PREVIEW_SLOTS = {
		teleport: true,
		levelup: true,
		kill_effect: true,
		emblem: true,
		companion: true,
		potion: true,
		rebirth: true,
		attack_lifesteal: true,
		spell_lifesteal: true,
		regen_aura: true,
		immolation: true,
		high_five: true,
	};

	var PAGE_IDS = {
		overview: "XHSPassOverviewPage",
		achievements: "XHSPassAchievementsPage",
		rewards: "XHSPassRewardsPage",
		shop: "XHSPassShopPage",
		armory: "XHSPassArmoryPage",
		settings: "XHSPassSettingsPage",
	};

	var TAB_IDS = {
		overview: "XHSPassTabOverview",
		achievements: "XHSPassTabAchievements",
		rewards: "XHSPassTabRewards",
		shop: "XHSPassTabShop",
		armory: "XHSPassTabArmory",
		settings: "XHSPassTabSettings",
	};

	var DISABLED_PAGES = {};

	var DEFAULT_TIERS = [
		{ id: 1, name: "Donator", price: "2\u20ac/month", color: "#70e39a", fragments: 150, daily_gameplay_fragments: 125, xp_boost: 10, vote_power: 2 },
		{ id: 2, name: "Golden Donator", price: "4.50\u20ac/month", color: "#ffcf66", fragments: 400, daily_gameplay_fragments: 150, xp_boost: 20, vote_power: 3 },
		{ id: 3, name: "Ember Donator", price: "9\u20ac/month", color: "#ff5a43", fragments: 900, daily_gameplay_fragments: 175, xp_boost: 30, vote_power: 4 },
		{ id: 4, name: "Stoneguard Donator", price: "18\u20ac/month", color: "#5ad0ff", fragments: 1800, daily_gameplay_fragments: 200, xp_boost: 40, vote_power: 5 },
		{ id: 5, name: "Earthwarden Donator", price: "27\u20ac/month", color: "#c99cff", fragments: 1800, daily_gameplay_fragments: 200, xp_boost: 40, vote_power: 5, prestige: true },
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

	function BoundedUIEventValue(value, maxLength) {
		var bounded = value === undefined || value === null ? "" : value.toString();
		bounded = bounded.replace(/[\r\n\t]/g, " ").replace(/^\s+|\s+$/g, "");
		return bounded.substring(0, Math.max(0, maxLength || 64));
	}

	function GetShopTelemetryContext() {
		var payload = GetRawShopPayload();
		return {
			release_id: BoundedUIEventValue(payload && (payload.release_id || payload.release), 64),
		};
	}

	function EmitSupporterUIEvent(eventName, fields) {
		if (!GameEvents || !GameEvents.SendCustomGameEventToServer) {
			return;
		}

		var allowedEvents = {
			pass_open: true,
			tab: true,
			search: true,
			filter: true,
			detail: true,
			preview_start: true,
			preview_verified: true,
			preview_fail: true,
			preview_stop: true,
			shop_purchase_intent: true,
			shop_purchase_success: true,
			shop_purchase_failed: true,
		};
		if (allowedEvents[eventName] !== true) {
			return;
		}

		fields = fields || {};
		var context = GetShopTelemetryContext();
		if (!fields.release_id && context.release_id) {
			fields.release_id = context.release_id;
		}
		var metadata = {};
		var stringLimits = {
			tab: 24,
			filter_key: 32,
			filter_value: 64,
			item_id: 96,
			category: 48,
			candidate_id: 96,
			result: 32,
			error_code: 64,
			release_id: 64,
		};
		for (var stringKey in stringLimits) {
			if (!stringLimits.hasOwnProperty(stringKey) || fields[stringKey] === undefined || fields[stringKey] === null) {
				continue;
			}
			var textValue = BoundedUIEventValue(fields[stringKey], stringLimits[stringKey]);
			var lowerValue = textValue.toLowerCase();
			if (!textValue || lowerValue.indexOf("vpcf") !== -1 || lowerValue.indexOf("particles/") !== -1 ||
				lowerValue.indexOf("http://") !== -1 || lowerValue.indexOf("https://") !== -1 ||
				lowerValue.indexOf("server_key") !== -1 || lowerValue.indexOf("api_key") !== -1 ||
				lowerValue.indexOf("password") !== -1 || lowerValue.indexOf("secret") !== -1 ||
				lowerValue.indexOf("token") !== -1) {
				continue;
			}
			metadata[stringKey] = textValue;
		}
		var integerLimits = {
			query_length: 500,
			duration_ms: 3600000,
			price: 10000000,
		};
		for (var integerKey in integerLimits) {
			if (!integerLimits.hasOwnProperty(integerKey) || fields[integerKey] === undefined || fields[integerKey] === null) {
				continue;
			}
			metadata[integerKey] = Clamp(Math.floor(ToNumber(fields[integerKey], 0)), 0, integerLimits[integerKey]);
		}
		supporterUITelemetrySequence = Math.min(2147483647, supporterUITelemetrySequence + 1);
		GameEvents.SendCustomGameEventToServer("supporter_pass_ui_event", {
			event_name: eventName,
			client_seq: supporterUITelemetrySequence,
			metadata: metadata,
		});
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
		var lowerImagePath = rawImagePath.toLowerCase();
		if (lowerImagePath.indexOf(".vpcf") !== -1 || lowerImagePath.indexOf("particles/") === 0) {
			return "";
		}
		var supporterCDNMatch = rawImagePath.match(/^https?:\/\/cdn\.frostrose-studio\.com\/static\/images\/battlepass\/xhs-4\.0\/([^?#]+)/i);
		if (supporterCDNMatch) {
			var supporterImageName = supporterCDNMatch[1].replace(/-v2(?=\.[^.]+$)/i, "").replace(/\.[^.]+$/, "").replace(/-/g, "_");
			return "file://{images}/custom_game/battlepass/" + supporterImageName + ".png";
		}
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
		if (normalized.indexOf("battlepass/") === 0) {
			return "file://{images}/custom_game/" + normalized + ".png";
		}

		var dotaRoots = ["badges/", "compendium/", "econ/", "events/", "game_modes/", "heroes/", "items/", "spellicons/", "status_icons/"];
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

	// Keep reward identity and art identity coupled even when an older backend
	// armory payload contains stale image metadata. These paths resolve directly
	// to Valve inventory textures shipped in Dota's VPK.
	var SUPPORTER_ITEM_IMAGE_OVERRIDES = {
		ti10_emblem: "battlepass/ti10_emblem",
		ti11_emblem: "battlepass/ti11_emblem",
		sp26_companion_carty: "econ/items/courier/carty/carty",
		sp26_companion_llama: "econ/items/courier/livery_llama_courier/livery_llama_courier",
		sp26_companion_jumo: "econ/items/courier/jumo/jumo",
		sp26_companion_boooofus: "econ/items/courier/boooofus_courier/boooofus_courier",
		sp26_companion_sappling: "econ/items/courier/little_sappling_style1/little_sappling_style1",
		sp26_companion_vaal: "econ/items/courier/vaal_the_animated_constructradiant/vaal_the_animated_constructradiant",
		sp26_companion_raiq: "econ/items/courier/raiq/raiq",
		sp26_companion_amphibian_kid: "econ/courier/frog/frog",
		sp26_companion_demi_doom: "econ/items/courier/jin_yin_white_fox/jin_yin_white_fox",
		sp26_companion_amaterasu: "econ/items/courier/amaterasu/amaterasu",
		sp26_companion_baekho: "econ/items/courier/baekho/baekho",
		sp26_companion_devourling: "econ/items/courier/chocobo/chocobo",
		sp26_companion_itsy: "econ/items/courier/itsy/itsy",
		sp26_companion_butch: "econ/items/courier/butch_pudge_dog/butch_pudge_dog",
		sp26_companion_golden_venoling: "econ/items/courier/snail/courier_snail",
		sp26_companion_mega_greevil: "econ/courier/mega_greevil_courier/mega_greevil_courier",
	};
	var SUPPORTER_TI_BUNDLE_IMAGES = {
		4: "battlepass/ti4_bundle",
		5: "battlepass/ti5_bundle",
		6: "battlepass/ti6_bundle",
		7: "battlepass/ti7_bundle",
		8: "battlepass/ti8_bundle",
		9: "battlepass/ti9_bundle",
		10: "battlepass/ti10_bundle",
		11: "battlepass/ti11_bundle",
	};
	var SUPPORTER_TI_EMBLEM_IMAGES = {
		10: "battlepass/ti10_emblem",
		11: "battlepass/ti11_emblem",
	};

	function GetSupporterTIBundleEdition(item) {
		if (!item) {
			return 0;
		}
		var candidates = [
			item.ti_edition,
			item.edition,
			item.metadata && item.metadata.ti_edition,
			item.payload && item.payload.ti_edition,
			item.id,
			item.item_id,
			item.item_name,
			item.name,
		];
		for (var i = 0; i < candidates.length; i++) {
			var value = (candidates[i] || "").toString().toLowerCase();
			var match = value.match(/(?:^|[^a-z0-9])ti[\s_-]?(10|11|[4-9])(?:[^0-9]|$)/i);
			if (!match && /^\d+$/.test(value)) {
				match = [value, value];
			}
			var edition = match ? Math.floor(ToNumber(match[1], 0)) : 0;
			if (SUPPORTER_TI_BUNDLE_IMAGES[edition]) {
				return edition;
			}
		}
		return 0;
	}

	function ApplySupporterItemImageOverride(item) {
		if (!item) {
			return item;
		}
		var imageOverrideKeys = [item.id, item.item_id, item.item_name, item.name];
		var override = "";
		for (var imageOverrideIndex = 0; imageOverrideIndex < imageOverrideKeys.length; imageOverrideIndex++) {
			var imageOverrideKey = (imageOverrideKeys[imageOverrideIndex] || "").toString().toLowerCase();
			if (SUPPORTER_ITEM_IMAGE_OVERRIDES[imageOverrideKey]) {
				override = SUPPORTER_ITEM_IMAGE_OVERRIDES[imageOverrideKey];
				break;
			}
		}
		var emblemIdentity = [
			item.item_type, item.type, item.category, item.slot_id,
			item.id, item.item_id, item.item_name, item.name,
		].join(" ").toLowerCase();
		if (emblemIdentity.indexOf("emblem") !== -1) {
			var emblemEdition = GetSupporterTIBundleEdition(item);
			if (SUPPORTER_TI_EMBLEM_IMAGES[emblemEdition]) {
				override = SUPPORTER_TI_EMBLEM_IMAGES[emblemEdition];
			}
		}
		if (override) {
			item.image = override;
			item.image_inventory = override;
			item.icon = override;
			item.image_url = override;
			item.preview_image = override;
		}
		var itemType = NormalizeRewardType(item.item_type || item.type || item.category);
		var bundleIdentity = [item.id, item.item_id, item.item_name, item.name]
			.join(" ")
			.toLowerCase();
		var isTICollection = bundleIdentity.indexOf("collection") !== -1;
		if ((item.is_bundle === true || itemType === "Bundle") && isTICollection) {
			var tiEdition = GetSupporterTIBundleEdition(item);
			if (tiEdition) {
				item.image = SUPPORTER_TI_BUNDLE_IMAGES[tiEdition];
				item.image_inventory = item.image;
				item.icon = item.image;
				item.image_url = item.image;
				item.preview_image = item.image;
			}
		}
		return item;
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
			ancient: "RarityAncient",
			immortal: "RarityImmortal",
			arcana: "RarityArcana",
			seasonal: "RaritySeason",
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
			return "";
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

	function CreatePageSizeOption(dropdown, key, pageSize) {
		var option = $.CreatePanel("Label", dropdown, "XHSPassPageSize_" + key + "_" + pageSize);
		option.AddClass("XHSPassPageSizeOption");
		option.xhs_page_size = pageSize.toString();
		option.SetAttributeString("xhs_page_size", option.xhs_page_size);
		option.text = option.xhs_page_size;
		dropdown.AddOption(option);
		return option;
	}

	function RenderPaginationControls(parentID, key, totalItems, rerender, options) {
		var parent = Panel(parentID);
		ClearPanel(parent);
		if (!parent) {
			return;
		}
		options = options || {};

		var state = paginationState[key];
		var totalPages = Math.max(1, Math.ceil(totalItems / state.page_size));
		state.page = Clamp(state.page, 0, totalPages - 1);
		parent.SetHasClass("IsEmpty", totalItems === 0 && options.keep_visible_when_empty !== true);

		var count = $.CreatePanel("Label", parent, "");
		count.AddClass("XHSPassPaginationCount");
		count.text = Text("xhs_sp_pagination_count", "{first}-{last} of {total}", {
			first: totalItems ? state.page * state.page_size + 1 : 0,
			last: Math.min(totalItems, (state.page + 1) * state.page_size),
			total: totalItems,
		});

		var controls = $.CreatePanel("Panel", parent, "");
		controls.AddClass("XHSPassPaginationControls");

		if (options.show_asset_request === true) {
			var requestCompanion = $.CreatePanel("Button", controls, "");
			requestCompanion.AddClass("XHSPassRequestCompanionButton");
			requestCompanion.AddClass("XHSPassPaginationRequestCompanion");
			requestCompanion.SetPanelEvent("onactivate", function () {
				if (!options.on_asset_request) {
					Game.EmitSound("General.Cancel");
					return;
				}
				options.on_asset_request();
			});
			var requestCompanionLabel = $.CreatePanel("Label", requestCompanion, "");
			requestCompanionLabel.text = options.asset_request_label
				|| Text("xhs_sp_request_companion", "Request companion");
		}

		if (options.equipped_label) {
			var equippedLabel = $.CreatePanel("Label", controls, "");
			equippedLabel.AddClass("XHSPassPaginationEquipped");
			equippedLabel.text = options.equipped_label;
			equippedLabel.hittest = true;
			if (options.equipped_tooltip) {
				equippedLabel.SetPanelEvent("onmouseover", function () {
					$.DispatchEvent("DOTAShowTextTooltip", equippedLabel, options.equipped_tooltip);
				});
				equippedLabel.SetPanelEvent("onmouseout", function () {
					$.DispatchEvent("DOTAHideTextTooltip", equippedLabel);
				});
			}
		}

		if (options.show_search === true) {
			var search = $.CreatePanel("TextEntry", controls, options.search_id || "");
			search.AddClass(options.search_class || "XHSPassArmorySearch");
			search.placeholder = options.search_placeholder || Text("xhs_sp_armory_search", "Search cosmetics...");
			search.text = (options.search_value || "").toString();
			search.SetPanelEvent("ontextentrychange", function () {
				if (options.on_search) {
					options.on_search((search.text || "").toString());
				}
			});
		}

		if (options.show_unequip === true) {
			var unequip = $.CreatePanel("Button", controls, "");
			unequip.AddClass("XHSPassPaginationButton");
			unequip.AddClass("XHSPassUnequipButton");
			unequip.SetHasClass("IsDisabled", options.can_unequip !== true || options.unequip_pending === true);
			unequip.SetPanelEvent("onactivate", function () {
				if (options.can_unequip !== true || options.unequip_pending === true || !options.on_unequip) {
					Game.EmitSound("General.Cancel");
					return;
				}
				options.on_unequip();
			});
			var unequipLabel = $.CreatePanel("Label", unequip, "");
			unequipLabel.text = options.unequip_pending === true
				? Text("xhs_sp_pending", "Pending...")
				: (options.unequip_label || Text("xhs_sp_unequip", "Unequip"));
		}

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

		var pageSizeDropdown = $.CreatePanel("DropDown", controls, "XHSPassPageSize_" + key);
		pageSizeDropdown.AddClass("XHSPassPageSizeDropDown");
		var pageSizes = key === "shop" ? [12, 24] : [10, 25];
		var selectedOptionID = "";
		for (var pageSizeIndex = 0; pageSizeIndex < pageSizes.length; pageSizeIndex++) {
			var pageSize = pageSizes[pageSizeIndex];
			var optionID = "XHSPassPageSize_" + key + "_" + pageSize;
			CreatePageSizeOption(pageSizeDropdown, key, pageSize);
			if (pageSize === state.page_size) {
				selectedOptionID = optionID;
			}
		}
		pageSizeDropdown.SetSelected(selectedOptionID || ("XHSPassPageSize_" + key + "_" + pageSizes[0]));
		pageSizeDropdown.SetPanelEvent("oninputsubmit", function () {
			var selected = pageSizeDropdown.GetSelected();
			var selectedSize = selected
				? ToNumber(selected.GetAttributeString("xhs_page_size", String(selected.xhs_page_size || state.page_size)), state.page_size)
				: state.page_size;
			if (pageSizes.indexOf(selectedSize) < 0 || selectedSize === state.page_size) {
				return;
			}
			state.page_size = selectedSize;
			state.page = 0;
			// Let the native DropDown finish and close before rebuilding its pager.
			// Deleting it synchronously from its own submit event can crash Panorama.
			$.Schedule(0.05, rerender);
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
			daily_gameplay_fragments: ToNumber(data.daily_gameplay_fragments, 0),
			daily_gameplay_cap: ToNumber(data.daily_gameplay_cap, [100, 125, 150, 175, 200, 200][tierID] || DAILY_GAMEPLAY_FRAGMENT_CAP),
			daily_quest_fragments: ToNumber(data.daily_quest_fragments, 0),
			daily_quest_cap: ToNumber(data.daily_quest_cap, DAILY_QUEST_FRAGMENT_CAP),
			weekly_fragments: ToNumber(data.daily_fragments || data.daily_earned || data.weekly_fragments || data.weekly_earned, 0),
			weekly_cap: ToNumber(data.daily_cap || data.weekly_cap, DAILY_FRAGMENT_CAP),
			xp_boost: ToNumber(data.xp_boost, 0),
			base_xp_change: ToNumber(data.base_xp_change, 0),
			xp_bonus: ToNumber(data.xp_bonus, 0),
			vote_power: Math.max(1, ToNumber(data.vote_power, tierID > 0 ? Math.min(tierID + 1, 5) : 1)),
			access_timeline: data.access_timeline || {},
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

	function IsDevUnlockFreeUIActive(player) {
		return devUnlockFreeUI === true && IsLocalSupporterDeveloper(player);
	}

	function GetDisplayPlayerData(player) {
		if (!player || !IsDevUnlockFreeUIActive(player)) {
			return player;
		}

		var displayPlayer = {};
		for (var key in player) {
			if (player.hasOwnProperty(key)) {
				displayPlayer[key] = player[key];
			}
		}
		displayPlayer.tier_id = 0;
		displayPlayer.supporter_tier = 0;
		displayPlayer.donator_level = 0;
		displayPlayer.tier_name = Text("xhs_sp_free_player", "Free Player");
		displayPlayer.tier_color = "#f3fbff";
		displayPlayer.xp_boost = 0;
		displayPlayer.xp_bonus = 0;
		displayPlayer.vote_power = 1;
		displayPlayer.season_level = SUPPORTER_PASS_LEVEL_COUNT;
		displayPlayer._dev_free_ui = true;
		return displayPlayer;
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
			perks: ([FormatNumber(tier.daily_gameplay_fragments || DAILY_GAMEPLAY_FRAGMENT_CAP) + " first match/day", "+" + DAILY_QUEST_FRAGMENT_CAP + " quest potential"]).concat(meta.perks || [
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
			if (IsDeferredSupporterItem(reward)) {
				continue;
			}
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

	function DisplayRewardRarity(item) {
		var rarity = ((item && (item.rarity || item.item_rarity)) || "common").toString().toLowerCase();
		var labels = {
			common: "Common",
			uncommon: "Uncommon",
			rare: "Rare",
			mythical: "Mythical",
			legendary: "Legendary",
			ancient: "Ancient",
			immortal: "Immortal",
			arcana: "Arcana",
			season: "Seasonal",
			seasonal: "Seasonal",
		};
		return Text("xhs_sp_" + rarity, labels[rarity] || rarity);
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
		if (IsDevUnlockAllUIActive(player) && devLocalEquippedBySlot.hasOwnProperty(slot)) {
			return ArmoryValueMatchesItem(devLocalEquippedBySlot[slot], item);
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

	function GetEquippedArmoryItems(items) {
		var equipped = [];
		for (var i = 0; i < items.length; i++) {
			if (items[i].equipped === true) {
				equipped.push(items[i]);
			}
		}
		return equipped;
	}

	function GetArmoryEquippedSummary(items) {
		var names = [];
		for (var i = 0; i < items.length; i++) {
			var name = LocalizeMaybeKey(items[i].name || items[i].item_name || items[i].id || "");
			if (name && names.indexOf(name) < 0) {
				names.push(name);
			}
		}
		if (names.length === 0) {
			return Text("xhs_sp_equipped_default", "Equipped: Default");
		}
		return Text("xhs_sp_equipped_item", "Equipped: {item}", { item: names.join(" · ") });
	}

	function BuildArmoryItemFromReward(reward, player, track) {
		ApplySupporterItemImageOverride(reward);
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
			catalog_item_id: reward.catalog_item_id || actualItemID,
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
		item.dev_preview_only = devPreviewUnlocked && !actuallyOwned;
		item.equipped = !item.locked && IsArmoryItemEquipped(player, item);
		return item;
	}

	function RequiredTierFromStatus(status) {
		var normalized = ToNumber(status, 0);
		var statusToTier = { 6: 1, 5: 2, 4: 3, 7: 4, 8: 5, 9: 5 };
		return statusToTier[normalized] || Clamp(normalized, 0, 5);
	}

	function BuildLegacyBattlepassArmory(player) {
		var items = [];
		var freeRewards = GetRewards("free") || [];
		var premiumRewards = GetRewards("premium") || [];
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
			var item = ApplySupporterItemImageOverride(EnrichOwnedArmoryItem(CopyObject(items[i])));
			var activatesIn41 = IsDeferredSupporterItem(item);
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
			if (activatesIn41) {
				// TI bundles may already grant these permanent entitlements in 4.0.
				// Keep them visible in the collection, but dormant until their runtime
				// systems ship in 4.1. These flags also prevent developer UI mode from
				// accidentally turning the Armory card into an equip action.
				item.deferred_until = item.deferred_until || "4.1";
				item.runtime_status = "dormant_4_1";
				item.activates_in_4_1 = true;
				item.dormant = true;
				item.previewable = false;
				item.preview_available = false;
				item.locked = true;
				item.lock_reason = Text("xhs_sp_activates_41", "Activates in 4.1");
				item.equipped = false;
			} else {
				item.locked = requiredTier > 0 && player.tier_id < requiredTier;
				item.lock_reason = item.locked ? Text("xhs_sp_tier_value", "Tier {tier}", { tier: requiredTier }) : "";
				item.equipped = IsTruthy(item.equipped, false) ||
					String(item.state || "").toLowerCase() === "equipped" ||
					IsArmoryItemEquipped(player, item);
			}
			normalizedItems.push(item);
		}
		return normalizedItems;
	}

	function ResolveTransportedShopPayload(catalog) {
		if (!catalog || ToNumber(catalog.transport_version, 0) < 2) {
			return catalog;
		}

		var generation = ToNumber(catalog.transport_generation, -1);
		if (shopTransportCache && shopTransportGeneration === generation) {
			return shopTransportCache;
		}

		var chunkCount = Math.max(0, ToNumber(catalog.item_chunk_count, 0));
		var items = [];
		for (var index = 1; index <= chunkCount; index++) {
			var chunk = GetTable("supporter_pass_shop", "items_" + index, null);
			if (!chunk || ToNumber(chunk.generation, -2) !== generation) {
				// Keep the last complete generation during the very short replication
				// window. The server publishes the manifest only after every chunk.
				return shopTransportCache;
			}
			items = items.concat(AsShopList(chunk.items));
		}

		var expectedCount = Math.max(0, ToNumber(catalog.item_count, items.length));
		if (items.length !== expectedCount) {
			return shopTransportCache;
		}

		var payload = CopyObject(catalog);
		payload.items = items;
		shopTransportCache = payload;
		shopTransportGeneration = generation;
		return payload;
	}

	function GetRawShopPayload() {
		var catalog = GetTable("supporter_pass_shop", "catalog", null);
		if (catalog) {
			return ResolveTransportedShopPayload(catalog) || {};
		}

		var permanent = GetTable("supporter_pass_shop", "permanent", null);
		if (permanent) {
			return permanent;
		}

		return GetTable("supporter_pass_shop", "featured", {}) || {};
	}

	function AsShopList(value) {
		if (value === undefined || value === null || value === "") {
			return [];
		}
		if (typeof value === "string" || typeof value === "number") {
			return [value];
		}
		if (Object.prototype.toString.call(value) === "[object Array]") {
			return value;
		}
		if (typeof value !== "object") {
			return [];
		}
		if (value.items !== undefined && value.id === undefined && value.item_id === undefined) {
			return AsShopList(value.items);
		}
		if (value.id !== undefined || value.item_id !== undefined || value.catalog_item_id !== undefined ||
			value.catalog_item_key !== undefined || value.item_key !== undefined ||
			value.reward_item_id !== undefined || value.entitlement_id !== undefined) {
			return [value];
		}

		var keys = [];
		for (var key in value) {
			if (value.hasOwnProperty(key) && /^\d+$/.test(key)) {
				keys.push(key);
			}
		}
		keys.sort(function (a, b) { return Number(a) - Number(b); });
		var list = [];
		for (var i = 0; i < keys.length; i++) {
			list.push(value[keys[i]]);
		}
		return list;
	}

	function ShopItemID(item) {
		if (item === undefined || item === null) {
			return "";
		}
		if (typeof item !== "object") {
			return item.toString();
		}
		var id = item.id || item.item_id || item.catalog_item_id || item.catalog_item_key ||
			item.item_key || item.reward_item_id || item.entitlement_id;
		return id === undefined || id === null ? "" : id.toString();
	}

	function ShopOwnershipKeys(item) {
		if (!item || typeof item !== "object") {
			return item === undefined || item === null || item === "" ? [] : [item.toString().toLowerCase()];
		}
		var fields = [
			item.item_id,
			item.catalog_item_id,
			item.catalog_item_key,
			item.item_key,
			item.reward_item_id,
			item.entitlement_id,
			item.id,
		];
		var keys = [];
		var seen = {};
		for (var i = 0; i < fields.length; i++) {
			if (fields[i] === undefined || fields[i] === null || fields[i] === "") {
				continue;
			}
			var key = fields[i].toString().toLowerCase();
			if (!seen[key]) {
				seen[key] = true;
				keys.push(key);
			}
		}
		return keys;
	}

	function CollectShopArmoryEntries(value, result, depth) {
		if (!value || depth > 6) {
			return;
		}
		if (Object.prototype.toString.call(value) === "[object Array]") {
			for (var arrayIndex = 0; arrayIndex < value.length; arrayIndex++) {
				CollectShopArmoryEntries(value[arrayIndex], result, depth + 1);
			}
			return;
		}
		if (typeof value !== "object") {
			return;
		}
		if (ShopOwnershipKeys(value).length > 0) {
			result.push(value);
			return;
		}
		for (var key in value) {
			if (value.hasOwnProperty(key) && value[key] && typeof value[key] === "object") {
				CollectShopArmoryEntries(value[key], result, depth + 1);
			}
		}
	}

	function ShopArmoryEntryQuantity(entry) {
		var fields = [entry && entry.owned_quantity, entry && entry.quantity, entry && entry.count, entry && entry.stack_count];
		var quantity = 0;
		for (var i = 0; i < fields.length; i++) {
			if (fields[i] !== undefined && fields[i] !== null && fields[i] !== "") {
				quantity = Math.max(quantity, Math.floor(ToNumber(fields[i], 0)));
			}
		}
		if (quantity <= 0 && !IsTruthy(entry && entry.owned, true)) {
			return 0;
		}
		return Math.max(1, quantity);
	}

	function BuildShopArmoryOwnershipIndex(player) {
		var playerID = Players.GetLocalPlayer();
		var sources = [
			GetTable("supporter_pass_armory", "rewards_" + playerID, []),
			player && player.raw && player.raw.armory,
			player && player.raw && player.raw.supporter_pass && player.raw.supporter_pass.armory,
		];
		var entries = [];
		for (var sourceIndex = 0; sourceIndex < sources.length; sourceIndex++) {
			CollectShopArmoryEntries(sources[sourceIndex], entries, 0);
		}
		var index = {
			__xhs_favorite: {},
			__xhs_giftable: {},
		};
		for (var entryIndex = 0; entryIndex < entries.length; entryIndex++) {
			var entry = entries[entryIndex];
			var quantity = ShopArmoryEntryQuantity(entry);
			var favorite = IsTruthy(entry.favorite, false) || IsTruthy(entry.is_favorite, false);
			var giftable = IsTruthy(entry.giftable, false)
				|| IsTruthy(entry.is_giftable, false)
				|| Math.floor(ToNumber(entry.giftable_quantity, 0)) > 0;
			var keys = ShopOwnershipKeys(entry);
			for (var keyIndex = 0; keyIndex < keys.length; keyIndex++) {
				index[keys[keyIndex]] = Math.max(ToNumber(index[keys[keyIndex]], 0), quantity);
				if (favorite) index.__xhs_favorite[keys[keyIndex]] = true;
				if (giftable) index.__xhs_giftable[keys[keyIndex]] = true;
			}
		}
		return index;
	}

	function GetShopArmoryOwnedQuantity(item, ownershipIndex) {
		var quantity = 0;
		var keys = ShopOwnershipKeys(item);
		for (var i = 0; i < keys.length; i++) {
			quantity = Math.max(quantity, ToNumber(ownershipIndex && ownershipIndex[keys[i]], 0));
		}
		return Math.max(0, Math.floor(quantity));
	}

	function GetShopArmoryFlag(item, ownershipIndex, flagName) {
		var flags = ownershipIndex && ownershipIndex["__xhs_" + flagName];
		if (!flags) return false;
		var keys = ShopOwnershipKeys(item);
		for (var i = 0; i < keys.length; i++) {
			if (flags[keys[i]] === true) return true;
		}
		return false;
	}

	function NormalizeShopComponent(component, ownershipIndex) {
		if (component === undefined || component === null) {
			return null;
		}
		if (typeof component !== "object") {
			component = { id: component.toString(), item_id: component.toString(), name: component.toString() };
		}

		var normalized = CopyObject(component);
		normalized.id = ShopItemID(component);
		normalized.item_id = normalized.item_id || normalized.id;
		normalized.name = normalized.name || normalized.item_name || normalized.id;
		normalized.item_type = normalized.item_type || normalized.type || normalized.category || "Cosmetic";
		normalized.owned_quantity = Math.max(
			Math.floor(ToNumber(normalized.owned_quantity || (normalized.ownership && normalized.ownership.quantity), 0)),
			GetShopArmoryOwnedQuantity(normalized, ownershipIndex)
		);
		normalized.owned = IsTruthy(normalized.owned, false) || IsTruthy(normalized.is_owned, false) || normalized.owned_quantity > 0;
		normalized.runtime_status = (normalized.runtime_status || normalized.status || "ready").toString().toLowerCase();
		return normalized;
	}

	function NormalizeShopItem(source, player, ownershipIndex) {
		if (!source || typeof source !== "object") {
			return null;
		}

		var item = CopyObject(source);
		item.id = ShopItemID(source);
		if (!item.id) {
			return null;
		}
		item.item_id = item.item_id || item.id;
		item.item_type = item.item_type || item.type || item.category || "Cosmetic";
		item.type = item.type || item.item_type;
		item.category = item.category || NormalizeArmoryItemType(item);
		item.edition = (item.edition || item.edition_id || item.ti_edition || item.event_edition || "Global").toString();
		item.rarity = (item.rarity || item.item_rarity || "common").toString().toLowerCase();
		var serverLocked = IsTruthy(item.locked, false) || IsTruthy(item.is_locked, false);
		var serverLockReason = item.lock_reason || item.locked_reason || "";
		var minimumTierValue = item.min_tier !== undefined && item.min_tier !== null
			? item.min_tier
			: (item.min_tier_id !== undefined && item.min_tier_id !== null
				? item.min_tier_id
				: (item.required_tier !== undefined && item.required_tier !== null ? item.required_tier : item.tier_id));
		item.min_tier = Math.max(0, Math.floor(ToNumber(minimumTierValue, 0)));
		item.giftable = IsTruthy(item.giftable, false) || IsTruthy(item.is_giftable, false)
			|| GetShopArmoryFlag(item, ownershipIndex, "giftable");
		item.favorite = IsTruthy(item.favorite, false) || IsTruthy(item.is_favorite, false)
			|| GetShopArmoryFlag(item, ownershipIndex, "favorite");
		item.is_new = IsTruthy(item.is_new, false)
			|| IsTruthy(item.metadata && item.metadata.is_new, false);
		item.runtime_status = (item.runtime_status || item.status || "ready").toString().toLowerCase();
		item.description = item.description || item.long_description || item.subtitle || "";

		var componentSource = item.components || item.grants || (item.bundle && (item.bundle.components || item.bundle.grants));
		if (!componentSource && item.payload && typeof item.payload === "object") {
			componentSource = item.payload.components || item.payload.grants;
		}
		var rawComponents = AsShopList(componentSource);
		item.components = [];
		for (var componentIndex = 0; componentIndex < rawComponents.length; componentIndex++) {
			var component = NormalizeShopComponent(rawComponents[componentIndex], ownershipIndex);
			if (component) {
				item.components.push(component);
			}
		}
		var ownedComponentIDs = {};
		var rawOwnedComponents = AsShopList(item.owned_component_ids || item.owned_components || (item.ownership && item.ownership.components));
		for (var ownedComponentIndex = 0; ownedComponentIndex < rawOwnedComponents.length; ownedComponentIndex++) {
			ownedComponentIDs[ShopItemID(rawOwnedComponents[ownedComponentIndex])] = true;
		}
		for (var normalizedComponentIndex = 0; normalizedComponentIndex < item.components.length; normalizedComponentIndex++) {
			if (ownedComponentIDs[item.components[normalizedComponentIndex].id]) {
				item.components[normalizedComponentIndex].owned = true;
				item.components[normalizedComponentIndex].owned_quantity = Math.max(1, ToNumber(item.components[normalizedComponentIndex].owned_quantity, 0));
			}
		}
		item.is_bundle = IsTruthy(item.is_bundle, false) || NormalizeRewardType(item.item_type) === "Bundle" || item.components.length > 1;
		if (item.is_bundle) {
			item.type = "Bundle";
			item.item_type = "Bundle";
			item.category = "Bundle";
		}

		var countedOwned = 0;
		var dormantComponents = 0;
		for (var ownedIndex = 0; ownedIndex < item.components.length; ownedIndex++) {
			if (item.components[ownedIndex].owned) {
				countedOwned++;
			}
			var componentStatus = item.components[ownedIndex].runtime_status;
			if (componentStatus.indexOf("dormant") !== -1 || componentStatus.indexOf("4.1") !== -1 || componentStatus.indexOf("deferred") !== -1) {
				dormantComponents++;
			}
		}
		item.component_count = Math.max(item.components.length, Math.floor(ToNumber(item.component_count, 0)));
		item.owned_count = Math.max(countedOwned, Math.floor(ToNumber(item.owned_count, 0)));
		item.owned_quantity = Math.max(
			Math.floor(ToNumber(item.owned_quantity || (item.ownership && item.ownership.quantity), 0)),
			GetShopArmoryOwnedQuantity(item, ownershipIndex)
		);
		item.owned = IsTruthy(item.owned, false) || IsTruthy(item.is_owned, false) || IsTruthy(item.ownership && item.ownership.owned, false) ||
			item.owned_quantity > 0 || (item.is_bundle && item.component_count > 0 && item.owned_count >= item.component_count);
		item.has_owned_components = item.is_bundle && item.owned_count > 0 && !item.owned;
		item.has_dormant_components = dormantComponents > 0;
		var tierLocked = item.min_tier > Math.max(0, Math.floor(ToNumber(player && player.tier_id, 0)));
		item.locked = serverLocked || tierLocked;
		item.lock_reason = serverLocked && serverLockReason
			? LocalizeMaybeKey(serverLockReason)
			: (tierLocked ? Text("xhs_sp_shop_tier_required", "Tier {tier} required", { tier: item.min_tier }) : "");
		return ApplySupporterItemImageOverride(item);
	}

	function BuildShopItemIndex(items) {
		var index = {};
		for (var i = 0; i < items.length; i++) {
			var id = ShopItemID(items[i]);
			if (id) {
				index[id] = items[i];
			}
		}
		return index;
	}

	function ResolveShopSection(section, itemIndex, player, ownershipIndex) {
		var references = AsShopList(section);
		if (references.length === 0 && section && typeof section === "object") {
			var sectionFields = ["item", "primary", "secondary", "secondary_items"];
			for (var sectionFieldIndex = 0; sectionFieldIndex < sectionFields.length; sectionFieldIndex++) {
				references = references.concat(AsShopList(section[sectionFields[sectionFieldIndex]]));
			}
		}
		var resolved = [];
		var seen = {};
		for (var i = 0; i < references.length; i++) {
			var reference = references[i];
			var id = ShopItemID(reference);
			var item = id && itemIndex[id] ? itemIndex[id] : null;
			if (item && reference && typeof reference === "object") {
				var merged = CopyObject(item);
				for (var field in reference) {
					if (reference.hasOwnProperty(field)) {
						merged[field] = reference[field];
					}
				}
				item = NormalizeShopItem(merged, player, ownershipIndex);
			} else if (!item && reference && typeof reference === "object") {
				item = NormalizeShopItem(reference, player, ownershipIndex);
			}
			if (!item || seen[item.id] || IsStandaloneDeferredShopItem(item)) {
				continue;
			}
			seen[item.id] = true;
			resolved.push(item);
		}
		return resolved;
	}

	function IsStandaloneDeferredShopItem(item) {
		if (!item || item.is_bundle === true) {
			return false;
		}
		return IsDeferredSupporterItem(item);
	}

	function GetShopViewModel(player) {
		player = player || GetDisplayPlayerData(GetLocalPlayerData());
		var ownershipIndex = BuildShopArmoryOwnershipIndex(player);
		var payload = GetRawShopPayload();
		var sections = payload && payload.sections && typeof payload.sections === "object" ? payload.sections : {};
		var structured = !!(payload && (payload.sections || payload.permanent || payload.hero || payload.catalog_items || payload.release_id || payload.version));
		var rawItems = AsShopList(payload && payload.items !== undefined ? payload.items : payload);
		if (rawItems.length === 0 && payload && payload.permanent) {
			rawItems = AsShopList(payload.permanent);
		}
		if (rawItems.length === 0 && sections.catalog) {
			rawItems = AsShopList(sections.catalog);
		}

		var items = [];
		var seen = {};
		for (var i = 0; i < rawItems.length; i++) {
			var normalized = NormalizeShopItem(rawItems[i], player, ownershipIndex);
			if (!normalized || seen[normalized.id] || IsStandaloneDeferredShopItem(normalized)) {
				continue;
			}
			var scope = (normalized.shop_scope || normalized.scope || "permanent").toString().toLowerCase();
			if (structured && (scope === "rotation" || scope === "rotating")) {
				continue;
			}
			seen[normalized.id] = true;
			items.push(normalized);
		}

		var index = BuildShopItemIndex(items);
		var hasCatalogSection = !!(sections.catalog || payload.catalog_items || payload.permanent_items || payload.permanent);
		var hero = ResolveShopSection(sections.hero || payload.hero, index, player, ownershipIndex).slice(0, 1);
		var featured = ResolveShopSection(sections.featured || payload.featured_items, index, player, ownershipIndex);
		var catalog = ResolveShopSection(sections.catalog || payload.catalog_items || payload.permanent_items, index, player, ownershipIndex);
		if (catalog.length === 0 && !hasCatalogSection) {
			catalog = items.slice(0);
		}
		if (hero.length === 0 && structured) {
			for (var heroIndex = 0; heroIndex < items.length; heroIndex++) {
				if ((items[heroIndex].placement || items[heroIndex].section || "").toString().toLowerCase() === "hero") {
					hero = [items[heroIndex]];
					break;
				}
			}
		}
		if (featured.length === 0 && structured) {
			featured = items.filter(function (item) {
				var placement = (item.placement || item.section || "").toString().toLowerCase();
				return placement === "featured" || ToNumber(item.featured_rank, 0) > 0;
			});
		}

		var heroID = hero.length ? hero[0].id : "";
		featured = featured.filter(function (item) { return item.id !== heroID; }).slice(0, 4);
		var allResolved = [];
		var resolvedSeen = {};
		var resolvedGroups = [items, hero, featured, catalog];
		for (var groupIndex = 0; groupIndex < resolvedGroups.length; groupIndex++) {
			for (var resolvedIndex = 0; resolvedIndex < resolvedGroups[groupIndex].length; resolvedIndex++) {
				var resolvedItem = resolvedGroups[groupIndex][resolvedIndex];
				if (!resolvedItem || resolvedSeen[resolvedItem.id]) { continue; }
				resolvedSeen[resolvedItem.id] = true;
				allResolved.push(resolvedItem);
			}
		}
		return {
			payload: payload || {},
			structured: structured,
			items: allResolved,
			hero: hero,
			featured: featured,
			catalog: catalog,
		};
	}

	function GetShopItems() {
		return GetShopViewModel(GetDisplayPlayerData(GetLocalPlayerData())).catalog;
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

	// Effigies and High Fives are retained in the catalog for their 4.1
	// implementations. Owned copies remain visible as dormant Armory entries, but
	// 4.0 never sells them standalone or lets players equip them.
	function IsDeferredSupporterItem(item) {
		if (!item) {
			return false;
		}

		var fields = [item.type, item.item_type, item.slot_id, item.category];
		for (var i = 0; i < fields.length; i++) {
			var value = (fields[i] || "").toString().toLowerCase().replace(/[^a-z0-9]/g, "");
			if (value === "effigy" || value === "effigies" || value === "statue" || value === "statues" ||
				value === "highfive" || value === "highfives") {
				return true;
			}
		}
		return false;
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

		var counter = Panel("XHSSupporterFragmentsCounter");
		if (counter) {
			counter.SetHasClass("HasFragments", fragments > 0);
		}

		if (!player.has_fragment_balance && !fragmentCounterInitialized) {
			return;
		}

		if (!fragmentCounterInitialized) {
			lastLocalFragmentBalance = fragments;
			displayedFragmentBalance = fragments;
			lastFragmentRewardEventID = (player.raw.fragment_reward_claim_event_id || "").toString();
			fragmentCounterInitialized = true;
			SetText("XHSSupporterFragmentsCounterValue", FormatNumber(fragments));
			return;
		}

		if (fragments > lastLocalFragmentBalance) {
			var balanceGain = Math.max(0, fragments - displayedFragmentBalance);
			var rewardEventID = (player.raw.fragment_reward_claim_event_id || "").toString();
			var rawGrants = player.raw.fragment_reward_grants || {};
			var rewardAmounts = [];
			var remainingGain = balanceGain;
			if (rewardEventID && rewardEventID !== lastFragmentRewardEventID) {
				for (var grantKey in rawGrants) {
					if (!rawGrants.hasOwnProperty(grantKey) || !rawGrants[grantKey]) {
						continue;
					}
					var rewardAmount = Math.min(
						remainingGain,
						Math.max(0, ToNumber(rawGrants[grantKey].amount, 0))
					);
					if (rewardAmount > 0) {
						rewardAmounts.push(rewardAmount);
						remainingGain -= rewardAmount;
					}
				}
				lastFragmentRewardEventID = rewardEventID;
			}

			var visualAmounts = rewardAmounts.slice(0);
			if (remainingGain > 0) {
				visualAmounts.push(remainingGain);
			}
			if (visualAmounts.length === 0 && balanceGain > 0) {
				visualAmounts.push(balanceGain);
			}

			var animationSerial = ++fragmentCounterAnimationSerial;
			fragmentCounterAnimating = visualAmounts.length > 0;
			SetText("XHSSupporterFragmentsCounterValue", FormatNumber(displayedFragmentBalance));
			var animationDelay = 0;
			for (var visualIndex = 0; visualIndex < visualAmounts.length; visualIndex++) {
				(function (amount, delay, serial) {
					$.Schedule(delay, function () {
						if (serial !== fragmentCounterAnimationSerial) {
							return;
						}
						ShowFragmentGainFlyout(amount, player.tier_id);
					});
					$.Schedule(delay + 0.46, function () {
						if (serial !== fragmentCounterAnimationSerial) {
							return;
						}
						displayedFragmentBalance = Math.min(fragments, displayedFragmentBalance + amount);
						SetText("XHSSupporterFragmentsCounterValue", FormatNumber(displayedFragmentBalance));
					});
				})(visualAmounts[visualIndex], animationDelay, animationSerial);
				animationDelay += 0.18;
			}
			$.Schedule(animationDelay + 0.5, function () {
				if (animationSerial !== fragmentCounterAnimationSerial) {
					return;
				}
				displayedFragmentBalance = fragments;
				fragmentCounterAnimating = false;
				SetText("XHSSupporterFragmentsCounterValue", FormatNumber(fragments));
			});
		} else if (fragments < lastLocalFragmentBalance) {
			fragmentCounterAnimationSerial++;
			fragmentCounterAnimating = false;
			displayedFragmentBalance = fragments;
			SetText("XHSSupporterFragmentsCounterValue", FormatNumber(fragments));
		} else if (!fragmentCounterAnimating) {
			displayedFragmentBalance = fragments;
			SetText("XHSSupporterFragmentsCounterValue", FormatNumber(fragments));
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
		var window = Panel("XHSSupporterPassWindow");
		if (!window) {
			return;
		}

		var wasVisible = window.BHasClass("IsVisible") || window.BHasClass("IsOpening");
		var visible = forceVisible;
		if (visible === undefined) {
			visible = !wasVisible;
		}

		windowAnimationSerial += 1;
		var animationSerial = windowAnimationSerial;
		var config = GameUI.CustomUIConfig ? GameUI.CustomUIConfig() : null;
		if (config) {
			config.XHSSupporterPassVisible = visible === true;
			if (visible) {
				config.XHSSupporterPassOccludesOverheads = true;
			}
			if (typeof config.UpdateXHSSupporterPassButtonState === "function") {
				config.UpdateXHSSupporterPassButtonState(visible);
			}
		}
		if (visible) {
			window.RemoveClass("IsClosing");
			window.AddClass("IsOpening");
			window.hittest = true;
			RenderAll();
			if (!wasVisible) {
				EmitSupporterUIEvent("pass_open", { tab: activePageName });
				EmitSupporterUIEvent("tab", { tab: activePageName });
			}
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
			SetShopDetailVisible(false);
			SetPurchaseConfirmationVisible(false);
			window.RemoveClass("IsOpening");
			window.RemoveClass("IsVisible");
			window.AddClass("IsClosing");
			window.hittest = false;
			backToTopPollScheduled = false;
			$.Schedule(0.32, function () {
				if (animationSerial === windowAnimationSerial && window && (!window.IsValid || window.IsValid())) {
					window.RemoveClass("IsClosing");
					if (config) {
						config.XHSSupporterPassOccludesOverheads = false;
					}
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
		if (pageName !== "shop") {
			SetShopDetailVisible(false);
			SetPurchaseConfirmationVisible(false);
		}

		activePageName = pageName;
		if (pageName === "shop") {
			RenderShop(GetLocalPlayerData());
		}
		if (IsSupporterPassVisible()) {
			EmitSupporterUIEvent("tab", { tab: pageName });
		}

		UpdatePremiumCTA(GetDisplayPlayerData(GetLocalPlayerData()));

		UpdateBackToTopButton();
		ScheduleBackToTopPoll();
	}

	function IsPageActive(pageName) {
		var pagePanel = Panel(PAGE_IDS[pageName]);
		return !!(pagePanel && pagePanel.BHasClass("IsVisible"));
	}

	function UpdatePremiumCTA(player) {
		var cta = Panel("XHSPassPremiumCTA");
		if (!cta) {
			return;
		}

		var visible = !!player && player.tier_id < 1 && !IsDevUnlockAllUIActive(player) && IsPageActive("rewards");
		cta.SetHasClass("IsVisible", visible);
		cta.hittest = visible;
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
		if (activePage === "achievements") {
			return Panel("XHSPassAchievementsScroll");
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
		var devFreeButton = Panel("XHSPassDevFreeUIButton");
		if (devFreeButton) {
			devFreeButton.SetHasClass("IsVisible", canUseDevUnlock);
			devFreeButton.SetHasClass("IsActive", canUseDevUnlock && devUnlockFreeUI);
			devFreeButton.hittest = canUseDevUnlock;
		}
		SetText(
			"XHSPassDevFreeUILabel",
			devUnlockFreeUI ? "DEV: EXIT FREE" : "DEV: FREE UI"
		);
		SetText("XHSPassHeaderLevelLabel", Text("xhs_sp_season_level_value", "Season Level {level}", { level: player.season_level }));
		SetText("XHSPassHeaderFragmentsValue", FormatNumber(player.fragments));
		SetText("XHSPassHeaderWalletValue", FormatNumber(player.fragments));
		SetText("XHSPassHeaderXPLabel", FormatNumber(player.season_xp) + " / " + FormatNumber(player.season_xp_max) + " " + Text("xhs_sp_xp", "XP"));
		SetPercent(Panel("XHSPassHeaderXpProgress"), player.season_xp, player.season_xp_max);

		var avatar = Panel("XHSPassAvatar");
		if (avatar && player.steamID) {
			avatar.steamid = player.steamID;
		}

		SetText("XHSPassTierValue", player.tier_name);
		SetText("XHSPassFragmentsValue", FormatNumber(player.fragments));
		SetText("XHSPassWeeklyCapValue", "Game " + FormatNumber(player.daily_gameplay_fragments) + "/" + FormatNumber(player.daily_gameplay_cap) + "  +  Quests " + FormatNumber(player.daily_quest_fragments) + "/" + FormatNumber(player.daily_quest_cap));
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
		var accessTimelineLabel = Panel("XHSPassAccessTimeline");
		if (accessTimelineLabel) {
			var accessPeriods = AsArray(player.access_timeline && player.access_timeline.periods || []);
			var accessNow = Date.now();
			var nextPeriod = null;
			var currentEnd = null;
			for (var accessIndex = 0; accessIndex < accessPeriods.length; accessIndex++) {
				var accessPeriod = accessPeriods[accessIndex] || {};
				var accessStart = new Date(accessPeriod.starts_at).getTime();
				var accessEnd = new Date(accessPeriod.ends_at).getTime();
				if (accessStart > accessNow && (!nextPeriod || accessStart < new Date(nextPeriod.starts_at).getTime())) nextPeriod = accessPeriod;
				if (accessStart <= accessNow && accessEnd > accessNow && ToNumber(accessPeriod.tier_id, 0) === player.tier_id && (!currentEnd || accessEnd > currentEnd)) currentEnd = accessEnd;
			}
			var accessText = "";
			if (nextPeriod) {
				accessText = "NEXT: TIER " + FormatNumber(nextPeriod.tier_id) + " · " + FormatSupporterAccessDate(nextPeriod.starts_at);
			} else if (currentEnd) {
				accessText = "ACCESS PROTECTED UNTIL " + FormatSupporterAccessDate(currentEnd);
			}
			accessTimelineLabel.text = accessText;
			accessTimelineLabel.SetHasClass("IsVisible", accessText.length > 0);
		}
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
		UpdatePremiumCTA(player);
	}

	function FormatSupporterAccessDate(value) {
		var date = new Date(value);
		if (!isFinite(date.getTime())) return "";
		var day = ("0" + date.getDate()).slice(-2);
		var month = ("0" + (date.getMonth() + 1)).slice(-2);
		return day + "/" + month + "/" + date.getFullYear();
	}

	function RenderTiers(player) {
		var parent = Panel("XHSPassTierRows");
		ClearPanel(parent);

		player = player || GetLocalPlayerData();
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
				(function (selectedTierID) {
					row.SetPanelEvent("onactivate", function () {
						OpenSupporterPortal("tier_card", selectedTierID);
					});
				})(tier.id);
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
		var requiredLevel = ToNumber(reward.level_required || reward.level, 1);
		var isCurrentLevel = requiredLevel === Math.max(1, ToNumber(player.season_level, 1));
		var card = $.CreatePanel(
			"Panel",
			parent,
			isCurrentLevel ? "XHSPassCurrentReward_" + track : ""
		);
		card.AddClass("XHSPassRewardCard");
		ApplyItemVisualClasses(card, reward, track);
		var devAllPreview = IsDevUnlockAllUIActive(player);
		var devFreePreview = IsDevUnlockFreeUIActive(player) && track === "free";
		var devPreviewUnlocked = devAllPreview || devFreePreview;
		var legacyReward = IsTruthy(reward.legacy, false);
		var rewardClaimable = reward.claimable === undefined ? !legacyReward : IsTruthy(reward.claimable, false);
		var rewardID = GetRewardID(reward);
		var devLocallyClaimed = devAllPreview && rewardID !== "" && devLocallyClaimedRewards[rewardID] === true;
		var legacyUnlocked = legacyReward && (devFreePreview || devLocallyClaimed || (!devAllPreview && IsLegacyRewardUnlocked(reward, player, track)));
		var rewardClaimed = devAllPreview
			? devLocallyClaimed
			: (devFreePreview || (legacyReward ? legacyUnlocked : IsRewardClaimed(reward, player)));
		var backendReady = devPreviewUnlocked || IsTruthy(player.raw && player.raw.backend_season_ready, true);
		var premiumLocked = (track === "premium" || reward.track === "premium" ||
			reward.premium === 1 || reward.premium === "1") && player.tier_id < 1 && !devPreviewUnlocked;
		var levelLocked = player.season_level < requiredLevel && !devPreviewUnlocked;
		var rewardLocked = devAllPreview ? false : (!rewardClaimed &&
			(legacyReward ? !legacyUnlocked : (levelLocked || premiumLocked || !backendReady)));
		card.SetHasClass("IsLegacyReward", legacyReward);
		card.SetHasClass("IsDevUIPreview", devAllPreview);
		card.SetHasClass("IsLocked", rewardLocked);
		card.SetHasClass("IsUnlocked", !rewardLocked && !rewardClaimed);
		card.SetHasClass("IsPremiumLocked", premiumLocked);
		card.SetHasClass("IsClaimed", rewardClaimed);
		card.SetHasClass("IsCurrentLevel", isCurrentLevel);

		var preview = CreateItemPreview(card, reward, "XHSPassRewardPreview", "XHSPassRewardImage");
		var level = $.CreatePanel("Label", preview, "");
		level.AddClass("XHSPassRewardLevel");
		level.text = isCurrentLevel
			? "CURRENT · " + Text("xhs_sp_level_value", "Level {level}", { level: requiredLevel })
			: Text("xhs_sp_level_value", "Level {level}", { level: requiredLevel });

		var details = $.CreatePanel("Panel", card, "");
		details.AddClass("XHSPassRewardDetails");

		var name = $.CreatePanel("Label", details, "");
		name.AddClass("XHSPassRewardName");
		name.text = LocalizeMaybeKey(reward.name || reward.item_name || Text("xhs_sp_reward", "Reward"));

		var rarity = $.CreatePanel("Label", details, "");
		rarity.AddClass("XHSPassRewardRarity");
		rarity.text = DisplayRewardRarity(reward);

		var type = $.CreatePanel("Label", details, "");
		type.AddClass("XHSPassRewardType");
		type.text = DisplayRewardType(reward.type || reward.item_type || "Cosmetic");

		if (rewardID) {
			var button = $.CreatePanel("Button", card, "");
			button.AddClass("XHSPassShopButton");
			var pending = IsActionPending("claim", rewardID);
			var canClaim = devAllPreview
				? !devLocallyClaimed
				: (!legacyReward && rewardClaimable && !rewardClaimed &&
					player.season_level >= requiredLevel && !premiumLocked && backendReady && !pending);
			button.SetHasClass("IsLocked", !canClaim);
			button.SetHasClass("IsClaimed", rewardClaimed || legacyUnlocked);
			button.hittest = canClaim;
			button.SetPanelEvent("onactivate", function () {
				if (!canClaim) {
					Game.EmitSound("General.Cancel");
					return;
				}
				if (devAllPreview) {
					devLocallyClaimedRewards[rewardID] = true;
					ShowActionMessage(Text("xhs_sp_dev_reward_claimed_local", "Reward claimed locally · backend unchanged."), true);
					Game.EmitSound("General.ButtonClick");
					RenderRewards(GetDisplayPlayerData(GetLocalPlayerData()));
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
			label.text = devAllPreview
				? Text(devLocallyClaimed ? "xhs_sp_dev_claimed_local" : "xhs_sp_dev_claim_local", devLocallyClaimed ? "Claimed locally" : "Claim locally")
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
	}

	function RenderRewards(player) {
		var parent = Panel("XHSPassRewardTracks");
		ClearPanel(parent);

		if (!parent) {
			return;
		}

		var freeRewards = GetRewards("free") || [];
		var premiumRewards = GetRewards("premium") || [];
		var rewardCount = Math.max(freeRewards.length, premiumRewards.length, 1);
		var canvas = $.CreatePanel("Panel", parent, "XHSPassRewardTracksCanvas");
		canvas.AddClass("XHSPassRewardTracksCanvas");
		canvas.style.width = Math.max(rewardCount * 222 + 24, 1348) + "px";

		RenderRewardTrack(canvas, Text("xhs_sp_free_track", "Free Track"), freeRewards, player, "free");
		RenderRewardTrack(canvas, Text("xhs_sp_supporter_track", "Supporter Track"), premiumRewards, player, "premium");

		$.Schedule(0.0, function () {
			if (!parent || !parent.IsValid()) {
				return;
			}
			var currentReward = parent.FindChildTraverse("XHSPassCurrentReward_free")
				|| parent.FindChildTraverse("XHSPassCurrentReward_premium");
			if (currentReward && typeof currentReward.ScrollParentToMakePanelFit === "function") {
				currentReward.ScrollParentToMakePanelFit(0, false);
				return;
			}
			if (typeof parent.ScrollToLeftEdge === "function") {
				parent.ScrollToLeftEdge();
			}
		});
	}

	function CreateShopCard(parent, item, player, mode) {
		if (mode === "shop") {
			return CreatePermanentShopCard(parent, item, player, "catalog", 0);
		}
		var card = $.CreatePanel("Panel", parent, "");
		var dormantUntil41 = mode === "armory" && item.activates_in_4_1 === true;
		var devPreviewOnly = mode === "armory" && item.dev_preview_only === true && !dormantUntil41;
		var devLocalEquipMode = mode === "armory" && IsDevUnlockAllUIActive(player) && !dormantUntil41;
		card.AddClass("XHSPassShopCard");
		card.SetHasClass("IsArmoryCard", mode === "armory");
		card.SetHasClass("IsDevUIPreview", devPreviewOnly);
		card.SetHasClass("IsDevLocalEquip", devLocalEquipMode);
		card.SetHasClass("IsEquipped", item.equipped === true);
		card.SetHasClass("IsLocked", item.locked === true);
		card.SetHasClass("IsDormant", dormantUntil41);
		ApplyItemVisualClasses(card, item, item.track === "premium" ? "premium" : "");

		CreateItemPreview(card, item, "XHSPassShopPreview", "XHSPassShopImage");

		var name = $.CreatePanel("Label", card, "");
		name.AddClass("XHSPassShopName");
		name.text = LocalizeMaybeKey(item.name || item.item_name || item.id || Text("xhs_sp_shop_item", "Shop Item"));

		var meta = $.CreatePanel("Label", card, "");
		meta.AddClass("XHSPassShopMeta");
		meta.text = DisplayRewardRarity(item) + " " + DisplayRewardType(item.type || item.item_type || "Cosmetic");

		var price = $.CreatePanel("Label", card, "");
		price.AddClass("XHSPassShopPrice");
		if (mode === "armory") {
			price.text = devLocalEquipMode
				? (item.equipped ? "DEV EQUIPPED LOCALLY" : "DEV LOCAL LOADOUT")
				: (item.locked ? (item.lock_reason || Text("xhs_sp_locked", "Locked")) : Text(item.equipped ? "xhs_sp_equipped" : "xhs_sp_unlocked", item.equipped ? "Equipped" : "Unlocked"));
		} else {
			price.text = FormatNumber(item.price || item.fragment_price || 0) + " " + Text("xhs_sp_fragments_lower", "fragments");
		}

		var button = $.CreatePanel("Button", card, "");
		button.AddClass("XHSPassShopButton");
		var backendRequestID = mode === "armory"
			? (item.entitlement_id || item.item_id || item.id)
			: (item.id || item.item_id);
		var devRequestID = item.catalog_item_id || item.item_id || item.id;
		var requestID = devLocalEquipMode ? devRequestID : backendRequestID;
		var unopenedBundle = mode === "armory" && item.type === "Bundle" && String(item.state || "").toLowerCase() === "unopened";
		button.SetHasClass("IsEquipped", mode === "armory" && item.equipped === true && !unopenedBundle);
		var actionKind = unopenedBundle ? "bundle_open" : (mode === "armory" ? (devLocalEquipMode ? "dev_equip" : "equip") : "purchase");
		var pending = IsActionPending(actionKind, requestID);
		var canAfford = mode === "armory"
			? (unopenedBundle || (item.locked !== true && item.equipped !== true)) && !pending
			: player.fragments >= ToNumber(item.price || item.fragment_price, 0) && !pending;
		button.SetHasClass("IsLocked", !canAfford);
		button.hittest = canAfford;
		button.SetPanelEvent("onactivate", function () {
			if (!canAfford) {
				Game.EmitSound("General.Cancel");
				return;
			}

			if (mode === "armory") {
				if (unopenedBundle) {
					var bundleRequestID = bundleOpenRequestByInstance[requestID];
					if (!bundleRequestID) {
						bundleOpenSerial++;
						bundleRequestID = "game_open_" + bundleOpenSerial + "_" + Math.floor(Safe(function () { return Game.GetGameTime(); }, 0) * 1000);
						bundleOpenRequestByInstance[requestID] = bundleRequestID;
					}
					SetActionPending("bundle_open", requestID, true);
					GameEvents.SendCustomGameEventToServer("supporter_pass_open_bundle", {
						instance_id: requestID,
						request_id: bundleRequestID,
					});
					Game.EmitSound("General.ButtonClick");
					RenderArmory(GetLocalPlayerData());
					return;
				}
				if (devLocalEquipMode) {
					SetActionPending("dev_equip", requestID, true);
					GameEvents.SendCustomGameEventToServer("supporter_pass_dev_equip_local", {
						item_id: requestID,
						slot_id: GetCanonicalArmorySlot(item),
						action: "equip",
					});
					Game.EmitSound("General.ButtonClick");
					RenderArmory(player);
					return;
				}
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

			BeginShopPurchase(item, player, "legacy_card");
		});

		var label = $.CreatePanel("Label", button, "");
		if (pending) {
			label.text = Text("xhs_sp_pending", "Pending...");
		} else if (devLocalEquipMode) {
			label.text = item.equipped ? "EQUIPPED LOCALLY" : "EQUIP LOCALLY";
		} else if (unopenedBundle) {
			label.text = Text("xhs_sp_open_bundle", "Open bundle");
		} else if (mode === "armory") {
			label.text = dormantUntil41
				? Text("xhs_sp_activates_41", "Activates in 4.1")
				: Text(item.locked ? "xhs_sp_locked" : (item.equipped ? "xhs_sp_equipped" : "xhs_sp_equip"), item.locked ? "Locked" : (item.equipped ? "Equipped" : "Equip"));
		} else {
			label.text = Text(canAfford ? "xhs_sp_buy" : "xhs_sp_locked", canAfford ? "Buy" : "Locked");
		}
	}

	function UpdateShopAvailability() {
		var tab = Panel("XHSPassTabShop");
		var page = Panel("XHSPassShopPage");
		if (tab) {
			// The permanent shop is a first-class 4.0 page. Keep its navigation
			// available while the catalog is empty so the explicit empty state can
			// explain that content has not been published yet.
			tab.SetHasClass("IsHiddenByData", false);
			tab.hittest = true;
		}
		if (page) {
			page.SetHasClass("IsHiddenByData", false);
		}
	}

	function RenderShop(player) {
		var parent = Panel("XHSPassShopGrid");
		var heroParent = Panel("XHSPassShopHero");
		var featuredParent = Panel("XHSPassShopFeatured");
		var highlights = Panel("XHSPassShopHighlights");
		var highlightsView = Panel("XHSPassShopHighlightsView");
		var browseView = Panel("XHSPassShopBrowseView");
		var highlightsTab = Panel("XHSPassShopHighlightsTab");
		var browseTab = Panel("XHSPassShopBrowseTab");
		var isBrowseView = currentShopView === "browse";
		if (highlightsView) { highlightsView.SetHasClass("IsVisible", !isBrowseView); }
		if (browseView) { browseView.SetHasClass("IsVisible", isBrowseView); }
		if (highlightsTab) { highlightsTab.SetHasClass("IsActive", !isBrowseView); }
		if (browseTab) { browseTab.SetHasClass("IsActive", isBrowseView); }
		ClearPanel(parent);
		ClearPanel(heroParent);
		ClearPanel(featuredParent);
		ClearPanel(Panel("XHSPassShopPager"));

		player = GetDisplayPlayerData(player || GetLocalPlayerData());
		var view = GetShopViewModel(player);
		var data = view.payload || {};
		var refresh = data.title || data.label || data.refresh_label || Text("xhs_sp_permanent_catalog", "Permanent catalog");
		SetText("XHSPassShopRefresh", LocalizeMaybeKey(refresh.toString()));
		var releaseMeta = [];
		if (data.release_id || data.release) {
			releaseMeta.push(BoundedUIEventValue(data.release_id || data.release, 64));
		}
		if (ToNumber(data.version, 0) > 0) {
			releaseMeta.push("v" + Math.floor(ToNumber(data.version, 0)));
		}
		SetText("XHSPassShopCatalogMeta", releaseMeta.join("  /  "));

		var items = view.catalog;
		if (isBrowseView) {
			currentShopFilter = RenderCategoryTabs("XHSPassShopFilters", items, currentShopFilter, function (filterName) {
				currentShopFilter = filterName;
				ResetPagination("shop");
				EmitSupporterUIEvent("filter", {
					tab: "shop",
					filter_key: "category",
					filter_value: filterName,
				});
				RenderShop(player);
			});
			currentShopEditionFilter = RenderShopFacetTabs(
				"XHSPassShopEditionFilters",
				GetShopFacetValues(items, "edition"),
				currentShopEditionFilter,
				"edition",
				function (value) {
					currentShopEditionFilter = value;
					ResetPagination("shop");
					RenderShop(player);
				}
			);
			currentShopRarityFilter = RenderShopFacetTabs(
				"XHSPassShopRarityFilters",
				GetShopFacetValues(items, "rarity"),
				currentShopRarityFilter,
				"rarity",
				function (value) {
					currentShopRarityFilter = value;
					ResetPagination("shop");
					RenderShop(player);
				}
			);
		}

		if (items.length === 0) {
			if (highlights) { highlights.SetHasClass("IsVisible", false); }
			SetText("XHSPassShopCatalogCount", Text("xhs_sp_zero_items", "0 items"));
			SetShopDetailVisible(false);
			CreateEmpty(isBrowseView ? parent : heroParent, Text("xhs_sp_shop_unavailable", "Permanent catalog unavailable"), Text("xhs_sp_shop_unavailable_body", "No permanent Supporter Pass items have been published yet."));
			return;
		}

		var highlightHero = view.hero.slice(0);
		var highlightFeatured = view.featured.slice(0);
		if (highlightHero.length === 0 && items.length > 0) {
			highlightHero = [items[0]];
		}
		var highlightedIDs = {};
		if (highlightHero.length > 0) { highlightedIDs[highlightHero[0].id] = true; }
		for (var highlightIndex = 0; highlightIndex < highlightFeatured.length; highlightIndex++) {
			highlightedIDs[highlightFeatured[highlightIndex].id] = true;
		}
		var highlightFallbackItems = view.items && view.items.length ? view.items : items;
		for (var fallbackIndex = 0; highlightFeatured.length < 4 && fallbackIndex < highlightFallbackItems.length; fallbackIndex++) {
			if (!highlightedIDs[highlightFallbackItems[fallbackIndex].id]) {
				highlightedIDs[highlightFallbackItems[fallbackIndex].id] = true;
				highlightFeatured.push(highlightFallbackItems[fallbackIndex]);
			}
		}
		var showHighlights = !isBrowseView && (highlightHero.length > 0 || highlightFeatured.length > 0);
		if (highlights) {
			highlights.SetHasClass("IsVisible", showHighlights);
			highlights.SetHasClass("HasHero", showHighlights && highlightHero.length > 0);
		}
		if (showHighlights) {
			if (highlightHero.length > 0) {
				CreateShopHighlight(heroParent, highlightHero[0], player, true, 0);
			}
			var featuredRows = [];
			for (var rowIndex = 0; rowIndex < Math.ceil(highlightFeatured.length / 2); rowIndex++) {
				var featuredRow = $.CreatePanel("Panel", featuredParent, "");
				featuredRow.AddClass("XHSPassShopFeaturedRow");
				featuredRow.SetHasClass("IsBottomRow", rowIndex === 1);
				featuredRows.push(featuredRow);
			}
			for (var featuredIndex = 0; featuredIndex < highlightFeatured.length; featuredIndex++) {
				CreateShopHighlight(featuredRows[Math.floor(featuredIndex / 2)], highlightFeatured[featuredIndex], player, false, featuredIndex);
			}
		}
		if (!isBrowseView) {
			RefreshShopDetail(player);
			return;
		}

		var filteredItems = FilterShopItems(items);
		var ownedCount = 0;
		for (var ownedIndex = 0; ownedIndex < filteredItems.length; ownedIndex++) {
			if (filteredItems[ownedIndex].owned) { ownedCount++; }
		}
		SetText("XHSPassShopCatalogCount", Text("xhs_sp_catalog_item_count", "{count} items  /  {owned} owned", {
			count: filteredItems.length,
			owned: ownedCount,
		}));
		RenderPaginationControls("XHSPassShopPager", "shop", filteredItems.length, function () {
			RenderShop(GetLocalPlayerData());
		});
		if (filteredItems.length === 0) {
			CreateEmpty(parent, Text("xhs_sp_no_shop_items", "No matching items"), Text("xhs_sp_no_shop_items_body", "Try another category, edition, rarity, or search."));
			return;
		}

		var pageItems = GetPageSlice(filteredItems, "shop");
		for (var i = 0; i < pageItems.length; i++) {
			CreatePermanentShopCard(parent, pageItems[i], player, "catalog", paginationState.shop.page * paginationState.shop.page_size + i);
		}
		RefreshShopDetail(player);
	}

	var supporterPortalRequestPending = false;
	function OpenSupporterPortal(source, tierID) {
		if (supporterPortalRequestPending) return;
		supporterPortalRequestPending = true;
		Game.EmitSound("General.ButtonClick");
		var payload = {
			source: source || "supporter_pass",
			locale: $.Language ? $.Language() : "en"
		};
		tierID = Math.floor(ToNumber(tierID, 0));
		if (tierID >= 1 && tierID <= 5) payload.tier_id = tierID;
		GameEvents.SendCustomGameEventToServer("supporter_pass_open_payment_portal", payload);
		$.Schedule(12, function () { supporterPortalRequestPending = false; });
	}

	var chinaPaymentState = {
		visible: false,
		loading: false,
		pending: false,
		providers: [],
		offers: [],
		tier_id: 1,
		billing_id: "30_days",
		provider: "",
		order_key: "",
		request_id: "",
	};

	function SetChinaPaymentStatus(message, statusClass) {
		var label = Panel("XHSPassChinaPaymentStatus");
		if (!label) return;
		label.text = message || "";
		label.SetHasClass("IsError", statusClass === "error");
		label.SetHasClass("IsSuccess", statusClass === "success");
	}

	function SetChinaPaymentVisible(visible) {
		var overlay = Panel("XHSPassChinaPaymentOverlay");
		if (!overlay) return;
		chinaPaymentState.visible = visible === true;
		overlay.SetHasClass("IsVisible", chinaPaymentState.visible);
		overlay.hittest = chinaPaymentState.visible;
		if (!chinaPaymentState.visible) return;

		var player = GetLocalPlayerData();
		chinaPaymentState.tier_id = Math.max(1, Math.min(5, ToNumber(player.tier_id, 1)));
		chinaPaymentState.loading = true;
		chinaPaymentState.pending = false;
		chinaPaymentState.order_key = "";
		chinaPaymentState.request_id = "";
		SetChinaPaymentStatus("Loading secure WeChat Pay and Alipay options...", "");
		RenderChinaPaymentFallback();
		GameEvents.SendCustomGameEventToServer("supporter_pass_payment_options", {});
		EmitSupporterUIEvent("china_payment_open", { source: "ingame_fallback" });
	}

	function FindChinaPaymentOffer(tierID) {
		for (var i = 0; i < chinaPaymentState.offers.length; i++) {
			var offer = chinaPaymentState.offers[i] || {};
			if (ToNumber(offer.tier_id, 0) === ToNumber(tierID, 0)) return offer;
		}
		return null;
	}

	function FindChinaPaymentAccessPass(offer, billingID) {
		var passes = AsArray(offer && offer.access_passes);
		for (var i = 0; i < passes.length; i++) {
			if ((passes[i].id || "").toString() === billingID) return passes[i];
		}
		return null;
	}

	function FindChinaPaymentProvider(providerID) {
		for (var i = 0; i < chinaPaymentState.providers.length; i++) {
			var provider = chinaPaymentState.providers[i] || {};
			if ((provider.id || "").toString() === providerID) return provider;
		}
		return null;
	}

	function FormatChinaPaymentAmount(amountMinor, currency) {
		var amount = Math.max(0, ToNumber(amountMinor, 0)) / 100;
		var formatted = amount.toFixed(2).replace(".", ",");
		return (currency || "EUR").toString().toUpperCase() === "EUR" ? formatted + " €" : formatted + " " + (currency || "EUR").toString().toUpperCase();
	}

	function CreateChinaPaymentChoice(parent, title, detail, selected, disabled, onActivate) {
		var button = $.CreatePanel("Button", parent, "");
		button.AddClass("XHSPassChinaPaymentChoice");
		button.SetHasClass("IsSelected", selected === true);
		button.SetHasClass("IsDisabled", disabled === true);
		button.enabled = disabled !== true;
		button.hittest = disabled !== true;
		var titleLabel = $.CreatePanel("Label", button, "");
		titleLabel.AddClass("XHSPassChinaPaymentChoiceTitle");
		titleLabel.text = title || "";
		var detailLabel = $.CreatePanel("Label", button, "");
		detailLabel.AddClass("XHSPassChinaPaymentChoiceDetail");
		detailLabel.text = detail || "";
		if (!disabled && onActivate) button.SetPanelEvent("onactivate", onActivate);
		return button;
	}

	function RenderChinaPaymentFallback() {
		var tiersPanel = Panel("XHSPassChinaPaymentTiers");
		var durationsPanel = Panel("XHSPassChinaPaymentDurations");
		var providersPanel = Panel("XHSPassChinaPaymentProviders");
		if (!tiersPanel || !durationsPanel || !providersPanel) return;
		tiersPanel.RemoveAndDeleteChildren();
		durationsPanel.RemoveAndDeleteChildren();
		providersPanel.RemoveAndDeleteChildren();

		var offers = chinaPaymentState.offers;
		for (var i = 0; i < offers.length; i++) {
			(function (offer) {
				var tierID = ToNumber(offer.tier_id, 0);
				if (tierID < 1 || tierID > 5) return;
				CreateChinaPaymentChoice(
					tiersPanel,
					offer.name || ("Tier " + tierID),
					"TIER " + tierID,
					chinaPaymentState.tier_id === tierID,
					chinaPaymentState.pending,
					function () {
						chinaPaymentState.tier_id = tierID;
						Game.EmitSound("General.ButtonClick");
						RenderChinaPaymentFallback();
					}
				);
			})(offers[i] || {});
		}

		var durationDefinitions = [
			{ id: "30_days", title: "1 MONTH", detail: "30 DAYS  /  1 个月" },
			{ id: "90_days", title: "3 MONTHS", detail: "90 DAYS  /  3 个月" },
			{ id: "365_days", title: "1 YEAR", detail: "2 MONTHS FREE  /  免费 2 个月" },
		];
		var selectedOffer = FindChinaPaymentOffer(chinaPaymentState.tier_id);
		for (var d = 0; d < durationDefinitions.length; d++) {
			(function (duration) {
				var pass = FindChinaPaymentAccessPass(selectedOffer, duration.id);
				CreateChinaPaymentChoice(
					durationsPanel,
					duration.title,
					duration.detail,
					chinaPaymentState.billing_id === duration.id,
					!pass || chinaPaymentState.pending,
					function () {
						chinaPaymentState.billing_id = duration.id;
						Game.EmitSound("General.ButtonClick");
						RenderChinaPaymentFallback();
					}
				);
			})(durationDefinitions[d]);
		}

		var providerDefinitions = [
			{ id: "wechat_pay", title: "WECHAT PAY · 微信支付", detail: "STRIPE SECURE CHECKOUT  /  安全支付" },
			{ id: "alipay", title: "ALIPAY · 支付宝", detail: "STRIPE SECURE CHECKOUT  /  安全支付" },
		];
		var firstConfiguredProvider = "";
		for (var providerScan = 0; providerScan < providerDefinitions.length; providerScan++) {
			var scannedProvider = FindChinaPaymentProvider(providerDefinitions[providerScan].id);
			if (scannedProvider && IsTruthy(scannedProvider.configured, false) && IsTruthy(scannedProvider.one_time, false)) {
				firstConfiguredProvider = providerDefinitions[providerScan].id;
				break;
			}
		}
		var currentProvider = FindChinaPaymentProvider(chinaPaymentState.provider);
		if (!currentProvider || !IsTruthy(currentProvider.configured, false) || !IsTruthy(currentProvider.one_time, false)) {
			chinaPaymentState.provider = firstConfiguredProvider;
		}
		for (var p = 0; p < providerDefinitions.length; p++) {
			(function (definition) {
				var provider = FindChinaPaymentProvider(definition.id);
				var configured = !!provider && IsTruthy(provider.configured, false) && IsTruthy(provider.one_time, false);
				CreateChinaPaymentChoice(
					providersPanel,
					definition.title,
					configured ? definition.detail : "UNAVAILABLE  /  暂不可用",
					chinaPaymentState.provider === definition.id,
					!configured || chinaPaymentState.pending,
					function () {
						chinaPaymentState.provider = definition.id;
						Game.EmitSound("General.ButtonClick");
						RenderChinaPaymentFallback();
					}
				);
			})(providerDefinitions[p]);
		}

		selectedOffer = FindChinaPaymentOffer(chinaPaymentState.tier_id);
		var selectedPass = FindChinaPaymentAccessPass(selectedOffer, chinaPaymentState.billing_id);
		var selectedProvider = FindChinaPaymentProvider(chinaPaymentState.provider);
		var ready = !!selectedOffer && !!selectedPass && !!selectedProvider && IsTruthy(selectedProvider.configured, false) && !chinaPaymentState.loading && !chinaPaymentState.pending;
		SetText("XHSPassChinaPaymentSelection", selectedOffer && selectedPass
			? (selectedOffer.name + "  ·  " + (chinaPaymentState.billing_id === "30_days" ? "1 month" : chinaPaymentState.billing_id === "90_days" ? "3 months" : "1 year"))
			: "Select a tier and fixed access period");
		SetText("XHSPassChinaPaymentPrice", selectedPass ? FormatChinaPaymentAmount(selectedPass.amount_minor, selectedOffer.currency) : "--");
		var continueButton = Panel("XHSPassChinaPaymentContinueButton");
		if (continueButton) {
			continueButton.enabled = ready;
			continueButton.hittest = ready;
			continueButton.SetHasClass("IsDisabled", !ready);
		}
	}

	function CreateChinaPaymentRequestID() {
		var now = Date.now ? Date.now() : Math.floor(Safe(function () { return Game.Time(); }, 0) * 1000);
		return ("xhs_ingame_" + Players.GetLocalPlayer() + "_" + now + "_" + Math.floor(Math.random() * 1000000)).slice(0, 128);
	}

	function BeginChinaPaymentCheckout() {
		if (chinaPaymentState.loading || chinaPaymentState.pending || !chinaPaymentState.provider) return;
		var offer = FindChinaPaymentOffer(chinaPaymentState.tier_id);
		var pass = FindChinaPaymentAccessPass(offer, chinaPaymentState.billing_id);
		var provider = FindChinaPaymentProvider(chinaPaymentState.provider);
		if (!offer || !pass || !provider || !IsTruthy(provider.configured, false)) {
			SetChinaPaymentStatus("Choose an available tier, duration, and payment method.", "error");
			return;
		}
		chinaPaymentState.pending = true;
		chinaPaymentState.request_id = CreateChinaPaymentRequestID();
		SetChinaPaymentStatus("Creating a secure Stripe Checkout session...  /  正在创建安全支付页面…", "");
		RenderChinaPaymentFallback();
		GameEvents.SendCustomGameEventToServer("supporter_pass_direct_checkout", {
			provider: chinaPaymentState.provider,
			tier_id: chinaPaymentState.tier_id,
			billing_id: chinaPaymentState.billing_id,
			request_id: chinaPaymentState.request_id,
			locale: $.Language ? $.Language() : "en",
		});
		EmitSupporterUIEvent("china_checkout_start", {
			provider: chinaPaymentState.provider,
			tier_id: chinaPaymentState.tier_id,
			billing_id: chinaPaymentState.billing_id,
		});
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
		if (category === "New") {
			return "new";
		}
		return (category || "Cosmetic")
			.toString()
			.toLowerCase()
			.replace(/[^a-z0-9]/g, "");
	}

	function GetItemCategories(items, player) {
		var available = {};
		var hasFavorites = false;
		var hasNewItems = false;
		for (var i = 0; i < items.length; i++) {
			var type = GetItemCategory(items[i]);
			var key = GetCategoryKey(type);
			if (!available[key]) {
				available[key] = type;
			}
			if (items[i].favorite === true) {
				hasFavorites = true;
			}
			if (items[i].is_new === true) {
				hasNewItems = true;
			}
		}

		var filters = ["All"];
		if (hasNewItems) {
			filters.push("New");
		}
		if (hasFavorites) {
			filters.push("Favorites");
		}
		var categoryOrder = [
			"Cosmetic",
			"Teleport FX",
			"Tome FX",
			"Kill FX",
			"Companion",
			"Emblem",
			"Potion FX",
			"Rebirth FX",
			"Attack Lifesteal",
			"Spell Lifesteal",
			"Regen Aura",
			"Immolation",
			"Title",
			"Bundle",
			"Pudge Hook",
			"Pudge Arcana",
			"Streak Counter",
		];
		for (var j = 0; j < categoryOrder.length; j++) {
			var orderedKey = GetCategoryKey(categoryOrder[j]);
			if (available[orderedKey]) {
				filters.push(categoryOrder[j]);
				delete available[orderedKey];
			}
		}
		for (var remainingKey in available) {
			if (available.hasOwnProperty(remainingKey)) {
				filters.push(available[remainingKey]);
			}
		}
		return filters;
	}

	function FilterItemsByCategory(items, category) {
		if (category === "All") {
			return items;
		}
		if (category === "Favorites") {
			return items.filter(function (item) { return item.favorite === true; });
		}
		if (category === "New") {
			return items.filter(function (item) { return item.is_new === true; });
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

	function FilterArmoryItemsBySearch(items, searchValue) {
		var query = (searchValue || "").toString().toLowerCase().replace(/^\s+|\s+$/g, "");
		if (!query) {
			return items;
		}

		var terms = query.split(/\s+/);
		return items.filter(function (item) {
			var fields = [
				LocalizeMaybeKey(item.name || item.item_name || item.id || ""),
				DisplayRewardType(item.type || item.item_type || "Cosmetic"),
				DisplayRewardRarity(item),
				item.item_id,
				item.catalog_item_id,
				item.entitlement_id,
				item.id,
				item.slot_id,
				item.unit,
				item.unit_name,
				item.file,
				item.particle,
			];
			var haystack = fields.filter(function (value) {
				return value !== undefined && value !== null;
			}).join(" ").toLowerCase();
			for (var termIndex = 0; termIndex < terms.length; termIndex++) {
				if (haystack.indexOf(terms[termIndex]) === -1) {
					return false;
				}
			}
			return true;
		});
	}

	function ShopFacetKey(value) {
		return (value || "").toString().toLowerCase().replace(/[^a-z0-9]/g, "");
	}

	function ShopEditionLabel(value) {
		var edition = (value || "Global").toString();
		var match = /^ti\s*0*([1-9]\d*)$/i.exec(edition);
		if (match) {
			return "TI" + match[1];
		}
		return edition.toUpperCase();
	}

	function GetShopFacetValues(items, facet) {
		var seen = {};
		var values = [];
		for (var i = 0; i < items.length; i++) {
			var value = facet === "edition" ? (items[i].edition || "Global") : (items[i].rarity || "common");
			var key = ShopFacetKey(value);
			if (!key || seen[key]) {
				continue;
			}
			seen[key] = true;
			values.push(value.toString());
		}
		if (facet === "rarity") {
			var rarityOrder = { common: 1, uncommon: 2, rare: 3, mythical: 4, legendary: 5, immortal: 6, arcana: 7, ancient: 8, season: 9, seasonal: 9 };
			values.sort(function (a, b) {
				return (rarityOrder[ShopFacetKey(a)] || 99) - (rarityOrder[ShopFacetKey(b)] || 99);
			});
		} else {
			values.sort(function (a, b) {
				var aMatch = /^ti\s*0*([1-9]\d*)$/i.exec(a);
				var bMatch = /^ti\s*0*([1-9]\d*)$/i.exec(b);
				if (aMatch && bMatch) {
					return Number(aMatch[1]) - Number(bMatch[1]);
				}
				if (aMatch) { return -1; }
				if (bMatch) { return 1; }
				return a.toLowerCase() < b.toLowerCase() ? -1 : 1;
			});
		}
		return values;
	}

	function RenderShopFacetTabs(parentID, values, activeValue, facet, onSelect) {
		var parent = Panel(parentID);
		ClearPanel(parent);
		if (!parent) {
			return activeValue;
		}

		var options = ["All"].concat(values);
		var activeKey = ShopFacetKey(activeValue || "All");
		var activeExists = activeKey === "all";
		for (var i = 1; i < options.length; i++) {
			if (ShopFacetKey(options[i]) === activeKey) {
				activeValue = options[i];
				activeExists = true;
				break;
			}
		}
		if (!activeExists) {
			activeValue = "All";
		}

		for (var optionIndex = 0; optionIndex < options.length; optionIndex++) {
			(function (option) {
				var button = $.CreatePanel("Button", parent, "");
				button.AddClass("XHSPassShopFacetButton");
				button.SetHasClass("IsActive", ShopFacetKey(option) === ShopFacetKey(activeValue));
				button.SetPanelEvent("onactivate", function () {
					onSelect(option);
					EmitSupporterUIEvent("filter", {
						tab: "shop",
						filter_key: facet,
						filter_value: option,
					});
				});
				var label = $.CreatePanel("Label", button, "");
				label.text = option === "All"
					? Text("xhs_sp_filter_all", "All")
					: (facet === "edition" ? ShopEditionLabel(option) : DisplayRewardRarity({ rarity: option }));
			})(options[optionIndex]);
		}
		return activeValue;
	}

	function FilterShopItems(items) {
		var categoryFiltered = FilterItemsByCategory(items, currentShopFilter);
		var query = (currentShopSearch || "").toString().toLowerCase().replace(/^\s+|\s+$/g, "");
		var terms = query ? query.split(/\s+/) : [];
		return categoryFiltered.filter(function (item) {
			if (currentShopEditionFilter !== "All" && ShopFacetKey(item.edition) !== ShopFacetKey(currentShopEditionFilter)) {
				return false;
			}
			if (currentShopRarityFilter !== "All" && ShopFacetKey(item.rarity) !== ShopFacetKey(currentShopRarityFilter)) {
				return false;
			}
			if (terms.length === 0) {
				return true;
			}
			var componentNames = [];
			for (var i = 0; i < item.components.length; i++) {
				componentNames.push(item.components[i].name || item.components[i].id || "");
			}
			var haystack = [
				item.name,
				item.item_name,
				item.id,
				item.description,
				item.category,
				item.edition,
				item.rarity,
				componentNames.join(" "),
			].join(" ").toLowerCase();
			for (var termIndex = 0; termIndex < terms.length; termIndex++) {
				if (haystack.indexOf(terms[termIndex]) === -1) {
					return false;
				}
			}
			return true;
		});
	}

	function IsDefaultShopDiscovery() {
		return currentShopFilter === "All" && currentShopEditionFilter === "All" &&
			currentShopRarityFilter === "All" && !currentShopSearch;
	}

	function IsSupporterPassVisible() {
		var window = Panel("XHSSupporterPassWindow");
		return !!(window && (window.BHasClass("IsVisible") || window.BHasClass("IsOpening")));
	}

	function CreateBundleGlyph(parent, withLabel) {
		var badge = $.CreatePanel("Panel", parent, "");
		badge.AddClass("XHSPassBundleBadge");
		var glyph = $.CreatePanel("Panel", badge, "");
		glyph.AddClass("XHSPassBundleGlyph");
		if (withLabel) {
			var label = $.CreatePanel("Label", badge, "");
			label.text = Text("xhs_sp_bundle", "Bundle");
		}
		return badge;
	}

	function CreateShopBadges(parent, item, compact) {
		var row = $.CreatePanel("Panel", parent, "");
		row.AddClass("XHSPassShopBadges");
		row.SetHasClass("IsCompact", compact === true);
		if (item.is_bundle) {
			CreateBundleGlyph(row, !compact);
		}

		function badge(text, className) {
			var label = $.CreatePanel("Label", row, "");
			label.AddClass("XHSPassShopBadge");
			if (className) { label.AddClass(className); }
			label.text = text;
		}
		if (item.is_new) {
			badge(Text("xhs_sp_new", "New"), "IsNew");
		}
		if (item.edition && ShopFacetKey(item.edition) !== "global") {
			badge(ShopEditionLabel(item.edition), "IsEdition");
		}
		if (item.giftable) {
			badge(Text("xhs_sp_giftable", "Giftable"), "IsGiftable");
		}
		if (item.favorite) {
			badge(Text("xhs_sp_favorite", "Favorite"), "IsFavorite");
		}
		if (item.min_tier > 0) {
			badge(Text("xhs_sp_tier_value", "Tier {tier}", { tier: item.min_tier }), "IsTier");
		}
		if (item.owned) {
			badge(Text("xhs_sp_owned", "Owned"), "IsOwned");
		}
		if (item.has_dormant_components) {
			badge("4.1 ITEM INCLUDED", "IsDormant");
		}
		return row;
	}

	function IsShopRuntimeUnavailable(item) {
		if (!item || item.is_bundle) {
			return false;
		}
		var status = (item.runtime_status || "ready").toString().toLowerCase();
		return status === "draft" || status === "unavailable" || status === "disabled" ||
			status.indexOf("deferred") !== -1 || status.indexOf("dormant") !== -1 || status.indexOf("4.1") !== -1;
	}

	function GetShopPurchaseState(item, player) {
		var requestID = ShopItemID(item);
		var pending = IsActionPending("purchase", requestID);
		var price = Math.max(0, ToNumber(item.price || item.fragment_price, 0));
		if (pending) {
			return { allowed: false, pending: true, label: Text("xhs_sp_pending", "Pending...") };
		}
		if (item.locked) {
			return { allowed: false, label: item.lock_reason || Text("xhs_sp_locked", "Locked") };
		}
		if (IsShopRuntimeUnavailable(item)) {
			return { allowed: false, label: Text("xhs_sp_unavailable", "Unavailable") };
		}
		if (!IN_GAME_SHOP_PURCHASES_ENABLED) {
			return {
				allowed: true,
				intent_only: true,
				reason: "website_only",
				label: Text("xhs_sp_available_on_website", "Available on website"),
			};
		}
		if (ToNumber(player && player.fragments, 0) < price) {
			return { allowed: false, label: Text("xhs_sp_need_fragments", "Need fragments") };
		}
		return { allowed: true, label: Text(item.owned ? "xhs_sp_buy_another" : "xhs_sp_buy", item.owned ? "Buy another" : "Buy") };
	}

	function SetPurchaseConfirmationVisible(visible) {
		var overlay = Panel("XHSPassPurchaseConfirmOverlay");
		if (!overlay) {
			return;
		}
		overlay.SetHasClass("IsVisible", visible === true);
		overlay.hittest = visible === true;
		if (!visible) {
			pendingPurchaseConfirmation = null;
		}
	}

	function OpenPurchaseConfirmation(item, player, placement) {
		var requestID = ShopItemID(item);
		if (!requestID) {
			return;
		}
		pendingPurchaseConfirmation = {
			item: item,
			placement: placement || "catalog",
		};
		SetText("XHSPassPurchaseConfirmTitle", LocalizeMaybeKey(item.name || item.item_name || item.id || requestID));
		SetText("XHSPassPurchaseConfirmPrice", FormatNumber(item.price || item.fragment_price || 0) + " " + Text("xhs_sp_fragments_lower", "fragments"));

		var preview = Panel("XHSPassPurchaseConfirmPreview");
		if (preview) {
			preview.RemoveAndDeleteChildren();
			CreateItemPreview(preview, item, "XHSPassPurchaseConfirmItemPreview", "XHSPassShopImage");
		}

		var ownership = Panel("XHSPassPurchaseConfirmOwnership");
		if (ownership) {
			var ownershipText = "";
			if (item.owned || item.has_owned_components) {
				ownershipText = item.is_bundle
					? Text("xhs_sp_bundle_duplicate_warning", "You already own part of this bundle. Its full price will be charged and every included item will be granted again.")
					: Text("xhs_sp_purchase_duplicate_warning", "You already own this item. Buying it again creates another giftable copy.");
			}
			ownership.text = ownershipText;
			ownership.SetHasClass("IsVisible", ownershipText.length > 0);
		}
		SetPurchaseConfirmationVisible(true);
		Game.EmitSound("General.ButtonClick");
	}

	function ConfirmShopPurchase() {
		var confirmation = pendingPurchaseConfirmation;
		if (!confirmation || !confirmation.item) {
			SetPurchaseConfirmationVisible(false);
			Game.EmitSound("General.Cancel");
			return;
		}
		var player = GetLocalPlayerData();
		var requestID = ShopItemID(confirmation.item);
		var item = FindCurrentShopItem(requestID, player) || confirmation.item;
		var placement = confirmation.placement;
		var state = GetShopPurchaseState(item, player);
		if (!state.allowed || state.intent_only || !requestID) {
			SetPurchaseConfirmationVisible(false);
			ShowActionMessage(state.label || Text("xhs_sp_purchase_failed", "Purchase failed."), false);
			Game.EmitSound("General.Cancel");
			RenderShop(player);
			return;
		}

		SetPurchaseConfirmationVisible(false);
		var confirmationKey = requestID.toString();
		var economicRequestID = purchaseRequestByItem[confirmationKey];
		if (!economicRequestID) {
			shopPurchaseSerial++;
			economicRequestID = "game_buy_" + shopPurchaseSerial + "_" + Math.floor(Safe(function () { return Game.GetGameTime(); }, 0) * 1000);
			purchaseRequestByItem[confirmationKey] = economicRequestID;
		}
		SetActionPending("purchase", requestID, true);
		EmitSupporterUIEvent("shop_purchase_intent", {
			item_id: requestID,
			category: ShopFacetKey(item.item_type || item.type),
			result: "attempted",
			price: Math.max(0, ToNumber(item.price || item.fragment_price, 0)),
			placement: placement,
		});
		GameEvents.SendCustomGameEventToServer("supporter_pass_buy_shop_item", {
			item_id: requestID,
			request_id: economicRequestID,
		});
		Game.EmitSound("General.ButtonClick");
		RenderShop(player);
	}

	function BeginShopPurchase(item, player, placement) {
		var state = GetShopPurchaseState(item, player);
		var requestID = ShopItemID(item);
		if (state.intent_only && requestID) {
			OpenExternalURL(SUPPORTER_SHOP_URL);
			ShowActionMessage(Text("xhs_sp_website_purchase_notice", "This item is purchased on the Supporter Pass website."), true);
			Game.EmitSound("General.ButtonClick");
			return;
		}
		if (!state.allowed || !requestID) {
			Game.EmitSound("General.Cancel");
			return;
		}
		OpenPurchaseConfirmation(item, player, placement);
	}

	function CreateShopPurchaseButton(parent, item, player, placement) {
		var state = GetShopPurchaseState(item, player);
		var button = $.CreatePanel("Button", parent, "");
		button.AddClass("XHSPassShopPurchaseButton");
		button.SetHasClass("IsLocked", !state.allowed);
		button.SetHasClass("IsOwned", false);
		button.SetHasClass("IsPending", state.pending === true);
		button.SetPanelEvent("onactivate", function () { BeginShopPurchase(item, player, placement); });
		var label = $.CreatePanel("Label", button, "");
		label.text = state.label;
		return button;
	}

	function CreateShopDetailsButton(parent, item, player, placement) {
		var button = $.CreatePanel("Button", parent, "");
		button.AddClass("XHSPassShopDetailsButton");
		button.SetPanelEvent("onactivate", function () {
			OpenShopDetail(item, player, placement);
		});
		var label = $.CreatePanel("Label", button, "");
		label.text = Text("xhs_sp_details", "Details");
		return button;
	}

	function CreatePermanentShopCard(parent, item, player, placement, position) {
		var card = $.CreatePanel("Panel", parent, "");
		card.AddClass("XHSPassShopCard");
		card.AddClass("XHSPassPermanentShopCard");
		card.SetHasClass("IsOwned", item.owned === true);
		card.SetHasClass("IsBundle", item.is_bundle === true);
		card.SetHasClass("IsLocked", item.locked === true);
		ApplyItemVisualClasses(card, item, "");

		var preview = CreateItemPreview(card, item, "XHSPassShopPreview", "XHSPassShopImage");
		if (item.is_bundle) {
			var previewGlyph = CreateBundleGlyph(preview, false);
			previewGlyph.AddClass("IsOnPreview");
		}
		CreateShopBadges(card, item, true);

		var name = $.CreatePanel("Label", card, "");
		name.AddClass("XHSPassShopName");
		name.text = LocalizeMaybeKey(item.name || item.item_name || item.id);

		var meta = $.CreatePanel("Label", card, "");
		meta.AddClass("XHSPassShopMeta");
		meta.AddClass("XHSPassShopQuality");
		meta.text = DisplayRewardRarity(item);

		var price = $.CreatePanel("Label", card, "");
		price.AddClass("XHSPassShopPrice");
		price.text = FormatNumber(item.price || item.fragment_price || 0) + " " + Text("xhs_sp_fragments_lower", "fragments");

		var actions = $.CreatePanel("Panel", card, "");
		actions.AddClass("XHSPassShopCardActions");
		CreateShopDetailsButton(actions, item, player, placement || "catalog");
		CreateShopPurchaseButton(actions, item, player, placement || "catalog");
		return card;
	}

	function CreateShopHighlight(parent, item, player, hero, position) {
		var card = $.CreatePanel("Panel", parent, "");
		card.AddClass(hero ? "XHSPassShopHeroCard" : "XHSPassShopFeaturedCard");
		card.SetHasClass("IsRightColumn", !hero && position % 2 === 1);
		card.SetHasClass("IsOwned", item.owned === true);
		card.SetHasClass("IsBundle", item.is_bundle === true);
		card.SetHasClass("IsLocked", item.locked === true);
		ApplyItemVisualClasses(card, item, "");

		var preview = CreateItemPreview(card, item, "XHSPassShopHighlightPreview", "XHSPassShopImage");
		if (item.is_bundle) {
			var glyph = CreateBundleGlyph(preview, false);
			glyph.AddClass("IsOnPreview");
		}
		var copy = $.CreatePanel("Panel", card, "");
		copy.AddClass("XHSPassShopHighlightCopy");
		CreateShopBadges(copy, item, !hero);
		var name = $.CreatePanel("Label", copy, "");
		name.AddClass("XHSPassShopHighlightName");
		name.text = LocalizeMaybeKey(item.name || item.item_name || item.id);
		var meta = $.CreatePanel("Label", copy, "");
		meta.AddClass("XHSPassShopHighlightMeta");
		meta.text = DisplayRewardRarity(item) + "  /  " + DisplayRewardType(item.item_type);
		if (hero && item.description) {
			var description = $.CreatePanel("Label", copy, "");
			description.AddClass("XHSPassShopHighlightDescription");
			description.text = LocalizeMaybeKey(item.description);
		}
		var price = $.CreatePanel("Label", copy, "");
		price.AddClass("XHSPassShopHighlightPrice");
		price.text = item.owned
			? Text("xhs_sp_in_collection", "In collection")
			: FormatNumber(item.price || item.fragment_price || 0) + " " + Text("xhs_sp_fragments_lower", "fragments");
		var actions = $.CreatePanel("Panel", copy, "");
		actions.AddClass("XHSPassShopHighlightActions");
		CreateShopDetailsButton(actions, item, player, hero ? "hero" : "featured");
		CreateShopPurchaseButton(actions, item, player, hero ? "hero" : "featured");
		return card;
	}

	function FindCurrentShopItem(itemID, player) {
		var view = GetShopViewModel(GetDisplayPlayerData(player || GetLocalPlayerData()));
		for (var i = 0; i < view.items.length; i++) {
			if (view.items[i].id === itemID) {
				return view.items[i];
			}
		}
		return null;
	}

	function SetShopDetailVisible(visible) {
		var overlay = Panel("XHSPassShopDetailOverlay");
		if (!overlay) {
			return;
		}
		overlay.SetHasClass("IsVisible", visible === true);
		overlay.hittest = visible === true;
		if (!visible) {
			shopDetailItem = null;
		}
	}

	function GetCatalogPreviewSlot(item) {
		var fields = [item && item.slot_id, item && item.item_type, item && item.type, item && item.category];
		for (var i = 0; i < fields.length; i++) {
			var value = (fields[i] || "").toString().toLowerCase().replace(/[\s-]+/g, "_");
			var slot = CanonicalSupporterSlot(value);
			if (CATALOG_PREVIEW_SLOTS[slot] === true) {
				return slot;
			}
		}
		var armorySlot = GetCanonicalArmorySlot(item || {});
		return CATALOG_PREVIEW_SLOTS[armorySlot] === true ? armorySlot : "";
	}

	function GetCatalogPreviewPlayerIDs() {
		var playerIDs = Safe(function () {
			return typeof Game.GetAllPlayerIDs === "function" ? Game.GetAllPlayerIDs() : [];
		}, []);
		playerIDs = AsArray(playerIDs);
		if (playerIDs.length > 0) {
			return playerIDs;
		}

		var teams = AsArray(Safe(function () {
			return typeof Game.GetAllTeamIDs === "function" ? Game.GetAllTeamIDs() : [];
		}, []));
		var seen = {};
		for (var teamIndex = 0; teamIndex < teams.length; teamIndex++) {
			var teamPlayers = AsArray(Safe(function () {
				return typeof Game.GetPlayerIDsOnTeam === "function" ? Game.GetPlayerIDsOnTeam(teams[teamIndex]) : [];
			}, []));
			for (var playerIndex = 0; playerIndex < teamPlayers.length; playerIndex++) {
				seen[teamPlayers[playerIndex].toString()] = teamPlayers[playerIndex];
			}
		}
		playerIDs = [];
		for (var key in seen) {
			if (seen.hasOwnProperty(key)) {
				playerIDs.push(seen[key]);
			}
		}
		return playerIDs;
	}

	function GetCatalogPreviewAccess() {
		var mapInfo = Safe(function () {
			return typeof Game.GetMapInfo === "function" ? Game.GetMapInfo() : {};
		}, {});
		var mapName = (mapInfo.map_display_name || mapInfo.map_name || "").toString().toLowerCase();
		if (mapName === "x_hero_siege_demo") {
			return { allowed: true, demo: true, human_count: 1 };
		}

		var playerIDs = GetCatalogPreviewPlayerIDs();
		var humanCount = 0;
		var localPlayerID = Safe(function () { return Players.GetLocalPlayer(); }, -1);
		for (var i = 0; i < playerIDs.length; i++) {
			var playerID = ToNumber(playerIDs[i], -1);
			if (playerID < 0) {
				continue;
			}
			var info = Safe(function () { return Game.GetPlayerInfo(playerID); }, {});
			var fakeClient = IsTruthy(info.player_is_fake_client, false) || IsTruthy(info.player_fake_client, false) || IsTruthy(info.player_is_bot, false);
			var steamID = (info.player_steamid || "").toString();
			if (!fakeClient && (playerID === localPlayerID || (steamID && steamID !== "0"))) {
				humanCount++;
			}
		}

		return {
			allowed: playerIDs.length > 0 && humanCount === 1,
			demo: false,
			human_count: humanCount,
		};
	}

	function SetCatalogPreviewTooltip(panel, tooltip) {
		if (!panel || !tooltip) {
			return;
		}
		panel.SetPanelEvent("onmouseover", function () {
			$.DispatchEvent("DOTAShowTextTooltip", panel, tooltip);
		});
		panel.SetPanelEvent("onmouseout", function () {
			$.DispatchEvent("DOTAHideTextTooltip", panel);
		});
	}

	function GetCatalogPreviewActionState(item) {
		var itemID = ShopItemID(item);
		var sameItem = itemID && catalogPreviewState.item_id === itemID;
		if (sameItem && catalogPreviewState.status === "active") {
			return {
				allowed: true,
				action: "stop",
				label: Text("xhs_sp_preview_stop", "Stop preview"),
				tooltip: Text("xhs_sp_preview_stop_tooltip", "Stop the temporary catalog preview."),
			};
		}
		if (sameItem && catalogPreviewState.status === "pending") {
			return {
				allowed: true,
				action: "stop",
				label: Text("xhs_sp_preview_cancel", "Cancel preview"),
				tooltip: Text("xhs_sp_preview_cancel_tooltip", "Cancel the pending catalog preview."),
			};
		}
		if (sameItem && catalogPreviewState.status === "stopping") {
			return { allowed: false, label: Text("xhs_sp_preview_stopping", "Stopping..."), tooltip: "" };
		}

		var slot = GetCatalogPreviewSlot(item);
		if (!itemID || item.is_bundle === true || !slot) {
			return {
				allowed: false,
				error_code: "unsupported_item",
				label: Text("xhs_sp_preview_not_available", "No live preview"),
				tooltip: Text("xhs_sp_preview_not_available_tooltip", "This item has no live effect preview."),
			};
		}
		var runtimeStatus = (item.runtime_status || "ready").toString().toLowerCase();
		if (runtimeStatus !== "ready" && runtimeStatus !== "available") {
			return {
				allowed: false,
				error_code: "runtime_unavailable",
				label: Text("xhs_sp_preview_not_available", "Preview unavailable"),
				tooltip: Text("xhs_sp_preview_runtime_unavailable", "This effect is not active in the current catalog release."),
			};
		}

		var access = GetCatalogPreviewAccess();
		if (!access.allowed) {
			return {
				allowed: false,
				map_locked: true,
				error_code: "map_locked",
				label: Text("xhs_sp_preview_demo_only", "Available on demo map"),
				tooltip: Text("xhs_sp_preview_demo_tooltip", "Preview is available on the demo map, or on a normal map with exactly one human player."),
			};
		}

		return {
			allowed: true,
			action: "preview",
			label: Text("xhs_sp_preview_test", "Test effect"),
			tooltip: Text("xhs_sp_preview_test_tooltip", "Temporarily test this effect. Ownership and tier locks do not apply to previews."),
		};
	}

	function CatalogPreviewNowMS() {
		return Math.max(0, Math.floor(Safe(function () { return Game.GetGameTime(); }, 0) * 1000));
	}

	function CatalogPreviewDurationMS(state) {
		var startedAt = Math.max(0, ToNumber(state && state.started_at_ms, 0));
		return startedAt > 0 ? Math.max(0, CatalogPreviewNowMS() - startedAt) : 0;
	}

	function EmitCatalogPreviewTelemetry(eventName, state, extra) {
		state = state || {};
		extra = extra || {};
		EmitSupporterUIEvent(eventName, {
			tab: "shop",
			item_id: state.item_id,
			category: state.category,
			candidate_id: extra.candidate_id,
			result: extra.result,
			error_code: extra.error_code,
			duration_ms: extra.duration_ms !== undefined ? extra.duration_ms : CatalogPreviewDurationMS(state),
		});
	}

	function StartCatalogPreview(item) {
		var state = GetCatalogPreviewActionState(item);
		if (state.action === "stop") {
			StopCatalogPreview();
			return;
		}
		if (!state.allowed || state.action !== "preview") {
			EmitCatalogPreviewTelemetry("preview_fail", {
				item_id: ShopItemID(item),
				category: item && item.category,
				started_at_ms: 0,
			}, {
				result: "blocked",
				error_code: state.error_code || "unavailable",
				duration_ms: 0,
			});
			Game.EmitSound("General.Cancel");
			ShowActionMessage(state.tooltip || Text("xhs_sp_preview_not_available", "Preview unavailable."), false);
			return;
		}

		catalogPreviewRequestSerial += 1;
		var requestID = "sp-preview-" + catalogPreviewRequestSerial + "-" + Math.floor(Safe(function () { return Game.GetGameTime(); }, 0) * 1000);
		catalogPreviewState = {
			status: "pending",
			request_id: requestID,
			item_id: ShopItemID(item),
			slot_id: GetCatalogPreviewSlot(item),
			category: item.category || "",
			message: Text("xhs_sp_preview_pending", "Checking live preview..."),
			expires_in: 0,
			started_at_ms: CatalogPreviewNowMS(),
		};
		EmitCatalogPreviewTelemetry("preview_start", catalogPreviewState, { result: "requested", duration_ms: 0 });
		GameEvents.SendCustomGameEventToServer("supporter_pass_catalog_preview", {
			action: "preview",
			request_id: requestID,
			item_id: catalogPreviewState.item_id,
		});
		RefreshShopDetail(GetLocalPlayerData());
		Game.EmitSound("General.ButtonClick");

		$.Schedule(8.0, function () {
			if (catalogPreviewState.request_id === requestID && catalogPreviewState.status === "pending") {
				catalogPreviewState.status = "error";
				catalogPreviewState.message = Text("xhs_sp_preview_timeout", "The preview request timed out.");
				EmitCatalogPreviewTelemetry("preview_fail", catalogPreviewState, { result: "timeout", error_code: "timeout" });
				ShowActionMessage(catalogPreviewState.message, false);
				RefreshShopDetail(GetLocalPlayerData());
			}
		});
	}

	function StopCatalogPreview() {
		if (catalogPreviewState.status !== "active" && catalogPreviewState.status !== "pending") {
			Game.EmitSound("General.Cancel");
			return;
		}
		catalogPreviewRequestSerial += 1;
		var previousState = catalogPreviewState;
		var requestID = "sp-preview-stop-" + catalogPreviewRequestSerial + "-" + Math.floor(Safe(function () { return Game.GetGameTime(); }, 0) * 1000);
		EmitCatalogPreviewTelemetry("preview_stop", previousState, {
			result: previousState.status === "pending" ? "cancel_requested" : "stop_requested",
		});
		catalogPreviewState.status = "stopping";
		catalogPreviewState.request_id = requestID;
		catalogPreviewState.message = Text("xhs_sp_preview_stopping", "Stopping preview...");
		GameEvents.SendCustomGameEventToServer("supporter_pass_catalog_preview_stop", {
			action: "stop",
			request_id: requestID,
		});
		RefreshShopDetail(GetLocalPlayerData());
		Game.EmitSound("General.ButtonClick");
	}

	function CreateCatalogPreviewButton(parent, item, compact) {
		var state = GetCatalogPreviewActionState(item);
		var button = $.CreatePanel("Button", parent, "");
		button.AddClass("XHSPassCatalogPreviewButton");
		button.SetHasClass("IsCompact", compact === true);
		button.SetHasClass("IsLocked", !state.allowed);
		button.SetHasClass("IsMapLocked", state.map_locked === true);
		button.SetHasClass("IsActive", state.action === "stop" && catalogPreviewState.status === "active");
		button.SetHasClass("IsPending", state.action === "stop" && catalogPreviewState.status === "pending");
		button.SetPanelEvent("onactivate", function () {
			StartCatalogPreview(item);
		});
		SetCatalogPreviewTooltip(button, state.tooltip);
		var label = $.CreatePanel("Label", button, "");
		label.text = state.label;
		return button;
	}

	function CreateShopDetailComponent(parent, component) {
		var row = $.CreatePanel("Panel", parent, "");
		row.AddClass("XHSPassShopDetailComponent");
		row.SetHasClass("IsOwned", component.owned === true);
		var status = (component.runtime_status || "ready").toString().toLowerCase();
		var dormant = status.indexOf("dormant") !== -1 || status.indexOf("deferred") !== -1 || status.indexOf("4.1") !== -1;
		row.SetHasClass("IsDormant", dormant);

		var image = $.CreatePanel("Panel", row, "");
		image.AddClass("XHSPassShopDetailComponentImage");
		SetCustomGameImage(image, component.image || component.image_inventory || component.icon || component.icon_path);
		var copy = $.CreatePanel("Panel", row, "");
		copy.AddClass("XHSPassShopDetailComponentCopy");
		var name = $.CreatePanel("Label", copy, "");
		name.AddClass("XHSPassShopDetailComponentName");
		name.text = LocalizeMaybeKey(component.name || component.item_name || component.id);
		var meta = $.CreatePanel("Label", copy, "");
		meta.AddClass("XHSPassShopDetailComponentMeta");
		meta.text = DisplayRewardType(component.item_type || component.type || component.category || "Cosmetic");
		var side = $.CreatePanel("Panel", row, "");
		side.AddClass("XHSPassShopDetailComponentSide");
		var state = $.CreatePanel("Label", side, "");
		state.AddClass("XHSPassShopDetailComponentState");
		state.text = component.owned
			? Text("xhs_sp_owned", "Owned")
			: (dormant ? Text("xhs_sp_activates_41", "Activates in 4.1") : Text("xhs_sp_included", "Included"));
		CreateCatalogPreviewButton(side, component, true);
		return row;
	}

	function RenderShopDetail(item, player, placement) {
		var body = Panel("XHSPassShopDetailBody");
		ClearPanel(body);
		if (!body || !item) {
			return;
		}
		SetText("XHSPassShopDetailTitle", LocalizeMaybeKey(item.name || item.item_name || item.id));

		var media = $.CreatePanel("Panel", body, "");
		media.AddClass("XHSPassShopDetailMedia");
		ApplyItemVisualClasses(media, item, "");
		var preview = CreateItemPreview(media, item, "XHSPassShopDetailPreview", "XHSPassShopImage");
		if (item.is_bundle) {
			var glyph = CreateBundleGlyph(preview, false);
			glyph.AddClass("IsOnPreview");
		}

		var content = $.CreatePanel("Panel", body, "");
		content.AddClass("XHSPassShopDetailContent");
		CreateShopBadges(content, item, false);
		var meta = $.CreatePanel("Label", content, "");
		meta.AddClass("XHSPassShopDetailMeta");
		meta.text = DisplayRewardRarity(item) + "  /  " + DisplayRewardType(item.item_type);
		var description = $.CreatePanel("Label", content, "");
		description.AddClass("XHSPassShopDetailDescription");
		description.text = LocalizeMaybeKey(item.description || Text("xhs_sp_permanent_item_description", "A permanent cosmetic for your Supporter Pass collection."));

		if (item.is_bundle) {
			var bundleHeader = $.CreatePanel("Panel", content, "");
			bundleHeader.AddClass("XHSPassShopDetailBundleHeader");
			CreateBundleGlyph(bundleHeader, true);
			var count = $.CreatePanel("Label", bundleHeader, "");
			count.AddClass("XHSPassShopDetailBundleCount");
			count.text = Text("xhs_sp_bundle_item_count", "{count} items", { count: item.component_count || item.components.length });
			var components = $.CreatePanel("Panel", content, "");
			components.AddClass("XHSPassShopDetailComponents");
			for (var componentIndex = 0; componentIndex < item.components.length; componentIndex++) {
				CreateShopDetailComponent(components, item.components[componentIndex]);
			}
			if (item.components.length === 0) {
				var unavailable = $.CreatePanel("Label", components, "");
				unavailable.AddClass("XHSPassShopDetailComponentsEmpty");
				unavailable.text = Text("xhs_sp_bundle_contents_unavailable", "Bundle contents are not available in this legacy catalog payload.");
			}
		}

		if (item.has_owned_components) {
			var duplicateWarning = $.CreatePanel("Label", content, "");
			duplicateWarning.AddClass("XHSPassShopDetailWarning");
			duplicateWarning.text = Text("xhs_sp_bundle_owned_warning", "You already own {owned}/{total} items. The bundle keeps its full price and grants every included item, including duplicate copies.", {
				owned: item.owned_count,
				total: item.component_count || item.components.length,
			});
		} else if (item.owned) {
			var ownedWarning = $.CreatePanel("Label", content, "");
			ownedWarning.AddClass("XHSPassShopDetailWarning");
			ownedWarning.AddClass("IsOwned");
			ownedWarning.text = Text("xhs_sp_item_already_owned_warning", "This permanent item is already in your collection.");
		}
		if (item.has_dormant_components) {
			var dormantNotice = $.CreatePanel("Label", content, "");
			dormantNotice.AddClass("XHSPassShopDetailNotice");
			dormantNotice.text = Text("xhs_sp_bundle_dormant_notice", "This bundle includes an item stored in your collection until its system activates in 4.1.");
		}
		if (!IN_GAME_SHOP_PURCHASES_ENABLED) {
			var websiteNotice = $.CreatePanel("Label", content, "");
			websiteNotice.AddClass("XHSPassShopDetailNotice");
			websiteNotice.AddClass("IsWebsiteOnly");
			websiteNotice.text = Text("xhs_sp_website_purchase_notice", "This item is purchased on the Supporter Pass website. No transaction is sent from the game.");
		}
		var purchaseNotice = $.CreatePanel("Label", content, "");
		purchaseNotice.AddClass("XHSPassShopDetailWarning");
		purchaseNotice.AddClass("IsPurchasePolicy");
		purchaseNotice.text = Text("xhs_sp_purchase_no_refund_notice", "Permanent purchase. No refunds. If you are unsure, try this item free in XHS Demo Mode before purchasing.");

		var footer = $.CreatePanel("Panel", content, "");
		footer.AddClass("XHSPassShopDetailFooter");
		var price = $.CreatePanel("Label", footer, "");
		price.AddClass("XHSPassShopDetailPrice");
		price.text = item.owned
			? Text("xhs_sp_in_collection", "In collection")
			: FormatNumber(item.price || item.fragment_price || 0) + " " + Text("xhs_sp_fragments_lower", "fragments");
		var actions = $.CreatePanel("Panel", footer, "");
		actions.AddClass("XHSPassShopDetailActions");
		if (!item.is_bundle) {
			CreateCatalogPreviewButton(actions, item, false);
		}
		var close = $.CreatePanel("Button", actions, "");
		close.AddClass("XHSPassShopDetailsButton");
		close.SetPanelEvent("onactivate", function () { SetShopDetailVisible(false); });
		var closeLabel = $.CreatePanel("Label", close, "");
		closeLabel.text = Text("xhs_sp_close", "Close");
		CreateShopPurchaseButton(actions, item, player, placement || "detail");
	}

	function OpenShopDetail(item, player, placement) {
		if (!item) {
			return;
		}
		shopDetailItem = { id: item.id, placement: placement || "catalog" };
		SetShopDetailVisible(true);
		RenderShopDetail(item, player, placement);
		EmitSupporterUIEvent("detail", {
			tab: "shop",
			item_id: item.id,
			category: item.category,
			result: placement || "catalog",
		});
		Game.EmitSound("General.ButtonClick");
	}

	function RefreshShopDetail(player) {
		if (!shopDetailItem) {
			return;
		}
		var displayPlayer = GetDisplayPlayerData(player || GetLocalPlayerData());
		var item = FindCurrentShopItem(shopDetailItem.id, displayPlayer);
		if (!item) {
			SetShopDetailVisible(false);
			return;
		}
		RenderShopDetail(item, displayPlayer, shopDetailItem.placement);
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
				button.SetHasClass("IsNewFilter", filterName === "New");
				button.SetPanelEvent("onactivate", function () {
					SetCourierRequestViewerVisible(false);
					onSelect(filterName);
				});

				var label = $.CreatePanel("Label", button, "");
				label.text = filterName === "All"
					? Text("xhs_sp_filter_all", "All")
					: (filterName === "New"
						? Text("xhs_sp_filter_new", "New")
						: (filterName === "Favorites"
							? Text("xhs_sp_filter_favorites", "Favorites")
							: (filterName === "Cosmetic"
								? Text("xhs_sp_filter_ascension", "Ascension")
								: DisplayRewardType(filterName))));
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

	function HumanizeAssetID(assetID) {
		return (assetID || "").toString()
			.replace(/^npc_dota_hero_/, "")
			.replace(/^npc_dota_(creature|boss)_/, "")
			.replace(/^npc_xhs_/, "")
			.replace(/^npc_/, "")
			.replace(/_/g, " ")
			.replace(/\b\w/g, function (letter) { return letter.toUpperCase(); });
	}

	function GetAssetRequestName(asset) {
		if (asset.item_def) {
			return GetCourierDisplayName(asset);
		}
		var token = "#" + (asset.unit || asset.asset_id || "");
		var localized = $.Localize(token);
		return asset.name || (localized && localized !== token ? localized : HumanizeAssetID(asset.asset_id));
	}

	function GetAssetRequestKey(asset) {
		return assetRequestView.request_type + ":" + assetRequestView.category + ":" + asset.asset_id;
	}

	function GetAssetRequestCatalog() {
		var list = [];
		if (assetRequestView.category === "courier") {
			var couriers = GetCourierCatalog();
			for (var c = 0; c < couriers.length; c++) {
				couriers[c].asset_id = couriers[c].item_def.toString();
				couriers[c].category = "courier";
				list.push(couriers[c]);
			}
		} else if (typeof XHSSupporterEffigyCatalog !== "undefined" && XHSSupporterEffigyCatalog) {
			var catalogKey = assetRequestView.category === "hero" ? "heroes" : assetRequestView.category + "s";
			list = XHSSupporterEffigyCatalog[catalogKey] || [];
		}
		var needle = (assetRequestView.search || "").toString().toLowerCase().replace(/^\s+|\s+$/g, "");
		if (!needle) return list;
		return list.filter(function (asset) {
			return (GetAssetRequestName(asset) + " " + (asset.asset_id || "") + " " + (asset.model || ""))
				.toLowerCase().indexOf(needle) !== -1;
		});
	}

	function RenderAssetRequestTabs(parentID, entries, selected, onSelect) {
		var parent = Panel(parentID);
		ClearPanel(parent);
		if (!parent) return;
		for (var i = 0; i < entries.length; i++) {
			(function (entry) {
				var button = $.CreatePanel("Button", parent, "");
				button.AddClass("XHSPassAssetRequestTab");
				button.SetHasClass("IsActive", entry.id === selected);
				button.SetPanelEvent("onactivate", function () { onSelect(entry.id); });
				var label = $.CreatePanel("Label", button, "");
				label.text = entry.label;
			})(entries[i]);
		}
	}

	function RenderAssetRequestNavigation() {
		RenderAssetRequestTabs("XHSPassAssetRequestTypeTabs", [
			{ id: "companion", label: Text("xhs_sp_companions", "Companions") },
			{ id: "effigy", label: Text("xhs_sp_effigies", "Statues / Effigies") },
		], assetRequestView.request_type, function (requestType) {
			assetRequestView.request_type = requestType;
			assetRequestView.category = requestType === "companion" ? "courier" : "hero";
			ResetPagination("asset_request");
			RenderCourierRequestOverlay();
		});
		var categories = assetRequestView.request_type === "companion"
			? [{ id: "courier", label: Text("xhs_sp_request_category_couriers", "Couriers") }]
			: [
				{ id: "hero", label: Text("xhs_sp_request_category_heroes", "Heroes") },
				{ id: "courier", label: Text("xhs_sp_request_category_couriers", "Couriers") },
				{ id: "creep", label: Text("xhs_sp_request_category_creeps", "Creeps") },
				{ id: "boss", label: Text("xhs_sp_request_category_bosses", "Bosses") },
			];
		RenderAssetRequestTabs("XHSPassAssetRequestCategoryTabs", categories, assetRequestView.category, function (category) {
			assetRequestView.category = category;
			ResetPagination("asset_request");
			RenderCourierRequestOverlay();
		});
		var title = Panel("XHSPassAssetRequestTitle");
		var body = Panel("XHSPassAssetRequestBody");
		if (title) title.text = assetRequestView.request_type === "companion"
			? Text("xhs_sp_courier_request_title", "Request a companion")
			: Text("xhs_sp_effigy_request_title", "Request a statue / effigy");
		if (body) body.text = assetRequestView.request_type === "companion"
			? Text("xhs_sp_courier_request_body", "Choose a courier you would like to see as a companion.")
			: Text("xhs_sp_effigy_request_body", "Browse heroes, couriers, creeps and bosses, then submit the model you would like as an effigy.");
	}

	function CreateCourierRequestCard(parent, asset, rerender) {
		var card = $.CreatePanel("Panel", parent, "");
		card.AddClass("XHSPassShopCard");
		card.AddClass("XHSPassCourierRequestCard");
		card.AddClass("HasAnimatedPreview");

		var preview = $.CreatePanel("Panel", card, "");
		preview.AddClass("XHSPassItemPreview");
		preview.AddClass("XHSPassShopPreview");
		preview.AddClass("HasAnimatedModel");

		var sceneSettings = {
			"class": "XHSPassCompanionScene XHSPassCourierScene",
			environment: "default",
			hittest: "false",
			particleonly: "false",
			unit: asset.unit,
			activity: "ACT_DOTA_IDLE",
		};
		if (asset.item_def) sceneSettings.itemdef = asset.item_def;
		var scene = $.CreatePanel("DOTAScenePanel", preview, "", sceneSettings);
		scene.hittest = false;

		var name = $.CreatePanel("Label", card, "");
		name.AddClass("XHSPassShopName");
		name.text = GetAssetRequestName(asset);

		var meta = $.CreatePanel("Label", card, "");
		meta.AddClass("XHSPassShopMeta");
		meta.text = Text("xhs_sp_courier_request_meta", "{rarity} courier · Item {item}", {
			rarity: DisplayRewardRarity(asset),
			item: asset.item_def || HumanizeAssetID(asset.category),
		});

		if (!asset.item_def) {
			meta.text = Text("xhs_sp_effigy_request_meta", "{category} effigy", {
				category: HumanizeAssetID(asset.category),
			});
		}

		var model = $.CreatePanel("Label", card, "");
		model.AddClass("XHSPassCourierModel");
		model.text = asset.model ? asset.model.replace(/^.*\//, "") : asset.asset_id;
		model.SetPanelEvent("onmouseover", function () {
			$.DispatchEvent("DOTAShowTextTooltip", model, asset.model || asset.asset_id || "");
		});
		model.SetPanelEvent("onmouseout", function () {
			$.DispatchEvent("DOTAHideTextTooltip", model);
		});

		var requestKey = GetAssetRequestKey(asset);
		var state = assetRequestResultState[requestKey] || "idle";
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
			assetRequestSerial++;
			var requestID = "asset_" + assetRequestSerial + "_" + Date.now();
			assetRequestResultState[requestKey] = "pending";
			GameEvents.SendCustomGameEventToServer("supporter_pass_request_asset", {
				request_type: assetRequestView.request_type,
				category: assetRequestView.category,
				asset_id: asset.asset_id,
				item_def: asset.item_def || "",
				unit_name: asset.unit || "",
				model: asset.model || "",
				display_name: GetAssetRequestName(asset),
				request_id: requestID,
			});
			Game.EmitSound("General.ButtonClick");
			rerender();
		});

		var buttonLabel = $.CreatePanel("Label", button, "");
		buttonLabel.text = Text(
			state === "pending"
				? "xhs_sp_request_pending"
				: (state === "success" ? "xhs_sp_requested" : "xhs_sp_request_asset"),
			state === "pending" ? "Sending..." : (state === "success" ? "Requested" : "Submit request")
		);
	}

	function RenderCourierRequestViewer(parent, pagerID, rerender) {
		var catalog = GetAssetRequestCatalog();
		RenderPaginationControls(pagerID, "asset_request", catalog.length, rerender);

		if (catalog.length === 0) {
			CreateEmpty(
				parent,
				Text("xhs_sp_asset_catalog_empty", "No matching assets"),
				Text("xhs_sp_asset_catalog_empty_body", "Try another category or search.")
			);
			return;
		}

		var pageItems = GetPageSlice(catalog, "asset_request");
		for (var i = 0; i < pageItems.length; i++) {
			CreateCourierRequestCard(parent, pageItems[i], rerender);
		}
	}

	function RenderCourierRequestResults() {
		var grid = Panel("XHSPassCourierRequestGrid");
		ClearPanel(grid);
		ClearPanel(Panel("XHSPassCourierRequestPager"));
		if (!grid) {
			return;
		}

		RenderCourierRequestViewer(grid, "XHSPassCourierRequestPager", RenderCourierRequestResults);
	}

	function RenderCourierRequestOverlay() {
		RenderAssetRequestNavigation();
		RenderCourierRequestResults();
	}

	function SetCourierRequestViewerVisible(visible, requestType) {
		var overlay = Panel("XHSPassCourierRequestOverlay");
		if (!overlay) {
			return;
		}

		overlay.SetHasClass("IsVisible", visible === true);
		overlay.hittest = visible === true;
		if (visible) {
			assetRequestView.request_type = requestType === "effigy" ? "effigy" : "companion";
			assetRequestView.category = assetRequestView.request_type === "effigy" ? "hero" : "courier";
			assetRequestView.search = "";
			var search = Panel("XHSPassAssetRequestSearch");
			if (search) {
				search.text = "";
				search.placeholder = Text("xhs_sp_request_search", "Search by name or unit...");
				search.SetHasClass("HasInput", false);
			}
			ResetPagination("asset_request");
			RenderCourierRequestOverlay();
			Game.EmitSound("General.ButtonClick");
		}
	}

	function RenderArmory(player) {
		var parent = Panel("XHSPassArmoryGrid");
		ClearPanel(parent);
		ClearPanel(Panel("XHSPassArmoryPager"));
		UpdateArmoryRefreshButton(player);

		var items = GetArmoryItems(player);
		currentArmoryFilter = RenderCategoryTabs("XHSPassArmoryFilters", items, currentArmoryFilter, function (filterName) {
			armorySearchRenderSerial++;
			currentArmoryFilter = filterName;
			ResetPagination("armory");
			RenderArmory(player);
		}, player);

		parent.SetHasClass("IsDevAssetMode", false);

		if (items.length === 0) {
			CreateEmpty(parent, Text("xhs_sp_no_cosmetics", "No unlocked cosmetics"), Text("xhs_sp_no_cosmetics_body", "Unlock cosmetics through the Supporter Pass or Fragment Shop, then equip them here."));
			return;
		}

		var categoryItems = FilterItemsByCategory(items, currentArmoryFilter);
		var armorySearchKey = GetCategoryKey(currentArmoryFilter);
		var armorySearchValue = armorySearchByCategory[armorySearchKey] || "";
		var filteredItems = FilterArmoryItemsBySearch(categoryItems, armorySearchValue);
		var equippedItems = GetEquippedArmoryItems(categoryItems);
		var unequipAll = currentArmoryFilter === "All";
		var unequipSlot = unequipAll
			? "all"
			: (equippedItems.length > 0 ? GetCanonicalArmorySlot(equippedItems[0]) : "");
		var devLocalEquipMode = IsDevUnlockAllUIActive(player);
		var unequipActionKind = devLocalEquipMode ? "dev_unequip" : "unequip";
		var unequipRequestID = unequipAll ? "all" : unequipSlot;
		var unequipPending = IsActionPending(unequipActionKind, unequipRequestID);
		var equippedSummary = GetArmoryEquippedSummary(equippedItems);
		RenderPaginationControls("XHSPassArmoryPager", "armory", filteredItems.length, function () {
			RenderArmory(GetLocalPlayerData());
		}, {
			show_asset_request: GetCategoryKey(currentArmoryFilter) === "companion" || GetCategoryKey(currentArmoryFilter) === "effigy",
			asset_request_label: GetCategoryKey(currentArmoryFilter) === "effigy"
				? Text("xhs_sp_request_effigy", "Request statue / effigy")
				: Text("xhs_sp_request_companion", "Request companion"),
			on_asset_request: function () {
				SetCourierRequestViewerVisible(true, GetCategoryKey(currentArmoryFilter) === "effigy" ? "effigy" : "companion");
			},
			show_unequip: true,
			show_search: true,
			keep_visible_when_empty: true,
			search_id: "XHSPassArmorySearch",
			search_value: armorySearchValue,
			search_placeholder: Text("xhs_sp_armory_search", "Search cosmetics..."),
			on_search: function (searchValue) {
				armorySearchByCategory[armorySearchKey] = searchValue;
				var renderSerial = ++armorySearchRenderSerial;
				$.Schedule(0.12, function () {
					if (renderSerial !== armorySearchRenderSerial ||
						GetCategoryKey(currentArmoryFilter) !== armorySearchKey) {
						return;
					}
					ResetPagination("armory");
					RenderArmory(GetLocalPlayerData());
					$.Schedule(0.0, function () {
						var refreshedSearch = Panel("XHSPassArmorySearch");
						if (refreshedSearch && refreshedSearch.IsValid()) {
							refreshedSearch.SetFocus();
						}
					});
				});
			},
			can_unequip: equippedItems.length > 0,
			unequip_pending: unequipPending,
			unequip_label: Text(unequipAll ? "xhs_sp_unequip_all" : "xhs_sp_unequip", unequipAll ? "Unequip all" : "Unequip"),
			equipped_label: equippedSummary,
			equipped_tooltip: equippedSummary,
			on_unequip: function () {
				if (!unequipRequestID || equippedItems.length === 0) {
					Game.EmitSound("General.Cancel");
					return;
				}
				SetActionPending(unequipActionKind, unequipRequestID, true);
				if (devLocalEquipMode) {
					GameEvents.SendCustomGameEventToServer("supporter_pass_dev_equip_local", {
						action: unequipAll ? "unequip_all" : "unequip",
						slot_id: unequipSlot,
					});
				} else {
					GameEvents.SendCustomGameEventToServer("supporter_pass_unequip_item", {
						hero: "global",
						slot_id: unequipSlot,
					});
				}
				Game.EmitSound("General.ButtonClick");
				RenderArmory(GetLocalPlayerData());
			},
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

	function AchievementList(value) {
		if (!value) {
			return [];
		}
		if (Object.prototype.toString.call(value) === "[object Array]") {
			return value;
		}
		if (typeof value !== "object") {
			return [value];
		}
		var keys = [];
		for (var key in value) {
			if (value.hasOwnProperty(key) && /^\d+$/.test(key)) {
				keys.push(key);
			}
		}
		keys.sort(function (a, b) { return Number(a) - Number(b); });
		var list = [];
		for (var i = 0; i < keys.length; i++) {
			list.push(value[keys[i]]);
		}
		return list;
	}

	function GetAchievementProfile() {
		var playerID = Players.GetLocalPlayer();
		var profile = GetTable("xhs_achievements_player", playerID.toString(), {}) || {};
		var meta = GetTable("xhs_achievements_catalog", "meta", {}) || {};
		var chunkCount = Math.max(0, Math.floor(ToNumber(meta.chunk_count, 0)));
		var catalog = [];
		for (var chunkIndex = 1; chunkIndex <= chunkCount; chunkIndex++) {
			var chunk = GetTable("xhs_achievements_catalog", "items_" + chunkIndex, {}) || {};
			catalog = catalog.concat(AchievementList(chunk.items));
		}
		profile.catalog = catalog;
		return profile;
	}

	function AchievementRankName(rank, isAbsolute) {
		if (isAbsolute) {
			return ToNumber(rank, 0) > 0
				? Text("xhs_sp_achievement_rank_absolute", "ACHIEVEMENT COMPLETE")
				: Text("xhs_sp_achievement_rank_locked", "LOCKED");
		}
		return [
			Text("xhs_sp_achievement_rank_locked", "LOCKED"),
			Text("xhs_sp_achievement_rank_bronze", "BRONZE"),
			Text("xhs_sp_achievement_rank_silver", "SILVER"),
			Text("xhs_sp_achievement_rank_gold", "GOLD"),
			Text("xhs_sp_achievement_rank_xhs", "XHS ABSOLUTE")
		][Clamp(Math.floor(ToNumber(rank, 0)), 0, 4)];
	}

	function AchievementMedalPath(rank, isAbsolute) {
		if (isAbsolute) {
			return "file://{images}/custom_game/achievements/achievement_rank_gold.png";
		}
		var names = ["bronze", "bronze", "silver", "gold", "xhs_absolute"];
		return "file://{images}/custom_game/achievements/achievement_rank_" + names[Clamp(Math.floor(ToNumber(rank, 1)), 1, 4)] + ".png";
	}

	function AchievementIconPath(entry) {
		var icon = String(entry && entry.icon || "wins_icon_png").replace(/[^a-z0-9_\-]/gi, "");
		return "file://{images}/custom_game/achievements/" + icon + ".png";
	}

	function AchievementValueLabel(value) {
		var amount = ToNumber(value, 0);
		if (Math.abs(amount) >= 1000000000) {
			return (amount / 1000000000).toFixed(amount >= 10000000000 ? 0 : 1) + "B";
		}
		if (Math.abs(amount) >= 1000000) {
			return (amount / 1000000).toFixed(amount >= 10000000 ? 0 : 1) + "M";
		}
		if (Math.abs(amount) >= 1000) {
			return (amount / 1000).toFixed(amount >= 10000 ? 0 : 1) + "K";
		}
		return Math.floor(amount).toString();
	}

	function AchievementLocalized(entry, field) {
		var fallback = entry && entry[field] || "";
		var id = entry && entry.id || "";
		if (!id) {
			return fallback;
		}
		var token = "#xhs_achievement_" + id + "_" + field;
		var localized = $.Localize(token);
		return localized && localized !== token ? localized : fallback;
	}

	var ACHIEVEMENT_REQUIREMENT_FALLBACKS = {
		veteran_defender: ["Finish an X Hero Siege run."],
		victory_march: ["Win an X Hero Siege run."],
		endless_horde: ["Defeat hostile units during X Hero Siege runs."],
		full_company: ["Win the run.", "Have at least four human defenders in the match."],
		event_veteran: ["Complete Muradin, Frost Infernal, Spirit Beast, Ramero & Baristol, or Sogat events."],
		all_hero_challenge: ["Win a run with each distinct playable XHS hero.", "A hero only counts after a victory with that hero."],
		siege_ascendant: [
			"Win the run; a higher difficulty also counts toward every lower difficulty.",
			"Bronze: 10 Normal wins / Silver: 25 Hard wins.",
			"Gold: 50 Extreme wins / XHS Absolute: 100 Divine wins."
		],
		the_ancient_stands: [
			"Win the run.",
			"Finish with at least 70% / 80% / 90% / 100% Ancient health for Bronze / Silver / Gold / XHS Absolute."
		],
		borrowed_time: ["Win on Hard or higher.", "Do not die during the run."],
		ahead_of_schedule: [
			"Win on Divine.",
			"Finish within 90 / 80 / 70 / 60 minutes for Bronze / Silver / Gold / XHS Absolute."
		],
		one_against_the_siege: [
			"Be the only human defender and win the run.",
			"Bronze: Normal / Silver: Hard / Gold: Extreme / XHS Absolute: Divine."
		],
		boss_breaker: ["Deal damage to XHS bosses."],
		lifebringer: ["Accumulate self-healing during X Hero Siege runs."],
		centaurs_retaliation: ["Accumulate damage taken during X Hero Siege runs."],
		harvest_of_war: ["Defeat enemies during the Farm Event."],
		tome_scholar: ["Gain permanent attributes from tomes."],
		first_victory: ["Win one eligible X Hero Siege run."],
		muradins_trial: ["Survive Muradin's challenge."],
		frost_infernal: ["Defeat the Frost Infernal."],
		spirit_beast: ["Defeat the Spirit Beast."],
		ramero_baristol: ["Win Ramero and Baristol's arena."],
		sogats_fall: ["Defeat Sogat."],
		hellscream_silenced: ["Defeat the true Hellscream."],
		pit_lord_falls: ["Defeat the Pit Lord."],
		four_stand_as_one: ["Win the run.", "Have at least four human defenders in the match."],
		perfect_campaign: ["Complete every required campaign objective.", "Win the run."],
		no_one_falls: ["Win the run.", "No human defender may die."],
		power_unspent: ["Win the run.", "Do not personally use any tome or potion."],
		see_through_the_lie: ["Defeat the true Hellscream and win the run.", "Do not damage a false clone."],
		sealed_supplies: ["Complete and win the full campaign.", "No human defender may use a reserve consumable."],
		old_school_defender: ["Complete the Classic campaign after it returns in 4.1."],
		classic_perfection: ["Master the Classic campaign after it returns in 4.1."],
		against_the_clock: ["Complete a Time Trial run after the mode arrives in 4.1."],
		clockbreaker: ["Master the Time Trial after the mode arrives in 4.1."],
		second_oath: ["Use the returning revive feature after it arrives in 4.3."],
		divine_pedestal: ["Prove yourself worthy beyond the frozen veil in 4.3."]
	};

	function CreateAchievementRequirement(parent, text, eligibilityRule) {
		var requirement = $.CreatePanel("Panel", parent, "");
		requirement.AddClass("XHSPassAchievementRequirement");
		if (eligibilityRule) {
			requirement.AddClass("IsEligibilityRule");
		}
		CreateAchievementLabel(requirement, "XHSPassAchievementRequirementBullet", "\u2022");
		CreateAchievementLabel(requirement, "XHSPassAchievementRequirementText", text);
	}

	function CreateAchievementRequirements(parent, entry) {
		var requirements = $.CreatePanel("Panel", parent, "");
		requirements.AddClass("XHSPassAchievementRequirements");
		CreateAchievementLabel(requirements, "XHSPassAchievementRequirementsTitle", Text("xhs_sp_achievement_requirements", "Requirements"));

		var fallbackRequirements = ACHIEVEMENT_REQUIREMENT_FALLBACKS[entry.id] || [AchievementLocalized(entry, "description")];
		for (var requirementIndex = 0; requirementIndex < fallbackRequirements.length; requirementIndex++) {
			var suffix = requirementIndex === 0 ? "requirement" : "requirement_" + (requirementIndex + 1);
			CreateAchievementRequirement(requirements, Text(
				"xhs_achievement_" + entry.id + "_" + suffix,
				fallbackRequirements[requirementIndex]
			), false);
		}

		if (entry.available !== false && entry.available !== 0) {
			CreateAchievementRequirement(requirements, Text(
				"xhs_sp_achievement_requirement_eligible",
				"Eligible matches only: no XHS bots, cheats, Tools Mode, abandons, or disconnects."
			), true);
		}
	}

	function AchievementProfileIndex(profile) {
		var index = { progress: {}, unlocks: {}, pins: {}, records: profile.records || {} };
		var progress = AchievementList(profile.progress);
		var unlocks = AchievementList(profile.unlocks);
		var pins = AchievementList(profile.pins);
		for (var i = 0; i < progress.length; i++) {
			index.progress[progress[i].achievement_id] = progress[i];
		}
		for (var u = 0; u < unlocks.length; u++) {
			var unlock = unlocks[u];
			index.unlocks[unlock.achievement_id] = Math.max(ToNumber(index.unlocks[unlock.achievement_id], 0), ToNumber(unlock.rank, 0));
		}
		for (var p = 0; p < pins.length; p++) {
			index.pins[pins[p].achievement_id] = true;
		}
		return index;
	}

	function CreateAchievementLabel(parent, className, value) {
		var label = $.CreatePanel("Label", parent, "");
		label.AddClass(className);
		label.text = value || "";
		label.hittest = false;
		return label;
	}

	function SetAchievementFilter(filterName) {
		currentAchievementFilter = filterName;
		var buttons = {
			all: "XHSPassAchievementFilterAll",
			progress: "XHSPassAchievementFilterProgress",
			complete: "XHSPassAchievementFilterComplete",
			coming: "XHSPassAchievementFilterComing",
		};
		for (var filter in buttons) {
			if (buttons.hasOwnProperty(filter) && Panel(buttons[filter])) {
				Panel(buttons[filter]).SetHasClass("IsActive", filter === filterName);
			}
		}
		RenderAchievements();
	}

	function AchievementTargetLabel(entry, rank) {
		var thresholds = AchievementList(entry && entry.thresholds);
		var labels = AchievementList(entry && entry.labels);
		var index = Clamp(Math.floor(ToNumber(rank, 1)) - 1, 0, Math.max(thresholds.length - 1, 0));
		return labels[index] || AchievementValueLabel(thresholds[index]);
	}

	function AchievementDefaultRank(entry, unlockedRank) {
		var count = Math.max(AchievementList(entry && entry.thresholds).length, 1);
		return unlockedRank >= count ? count : Clamp(unlockedRank + 1, 1, count);
	}

	function UpdateAchievementRankPreview(preview, entry, rank, unlockedRank, currentValue) {
		if (!preview) {
			return;
		}
		var fragments = AchievementList(entry.fragments);
		var points = AchievementList(entry.points);
		var index = Clamp(Math.floor(ToNumber(rank, 1)) - 1, 0, Math.max(fragments.length - 1, 0));
		var earned = unlockedRank >= rank;
		preview.SetHasClass("IsEarned", earned);
		preview.SetHasClass("IsNext", !earned && rank === unlockedRank + 1);
		preview.RemoveClass("Rank1");
		preview.RemoveClass("Rank2");
		preview.RemoveClass("Rank3");
		preview.RemoveClass("Rank4");
		preview.AddClass("Rank" + rank);
		preview._rank.text = AchievementRankName(rank, false);
		var hasCustomLabel = AchievementList(entry.labels).length > 0;
		preview._target.text = earned
			? AchievementTargetLabel(entry, rank) + "  " + Text("xhs_sp_achievement_complete", "COMPLETE")
			: (hasCustomLabel ? "TARGET  " + AchievementTargetLabel(entry, rank) : AchievementValueLabel(currentValue) + " / " + AchievementTargetLabel(entry, rank));
		preview._reward.text = "+" + FormatNumber(fragments[index] || 0) + " " + Text("xhs_sp_fragments", "fragments") + "   +" + FormatNumber(points[index] || 0) + " pts";
	}

	function CreateAchievementRankPips(parent, preview, entry, unlockedRank, currentValue) {
		var thresholds = AchievementList(entry.thresholds);
		var defaultRank = AchievementDefaultRank(entry, unlockedRank);
		for (var i = 0; i < thresholds.length; i++) {
			var rank = i + 1;
			var pip = $.CreatePanel("Panel", parent, "");
			pip.AddClass("XHSPassAchievementRankPip");
			pip.AddClass("Rank" + rank);
			pip.SetHasClass("IsEarned", unlockedRank >= rank);
			pip.SetHasClass("IsNext", defaultRank === rank && unlockedRank < rank);
			if (unlockedRank >= rank) {
				var medal = $.CreatePanel("Image", pip, "");
				medal.AddClass("XHSPassAchievementRankPipMedal");
				medal.SetImage(AchievementMedalPath(rank, false));
			} else {
				var dot = $.CreatePanel("Panel", pip, "");
				dot.AddClass("XHSPassAchievementRankPipDot");
			}
			CreateAchievementLabel(pip, "XHSPassAchievementRankPipTarget", AchievementTargetLabel(entry, rank));
			(function (stageRank, stagePanel) {
				stagePanel.hittest = true;
				stagePanel.SetPanelEvent("onmouseover", function () {
					UpdateAchievementRankPreview(preview, entry, stageRank, unlockedRank, currentValue);
					stagePanel.AddClass("IsHovered");
				});
				stagePanel.SetPanelEvent("onmouseout", function () {
					stagePanel.RemoveClass("IsHovered");
					UpdateAchievementRankPreview(preview, entry, defaultRank, unlockedRank, currentValue);
				});
				stagePanel.SetPanelEvent("onactivate", function () {
					UpdateAchievementRankPreview(preview, entry, stageRank, unlockedRank, currentValue);
				});
			})(rank, pip);
		}
		UpdateAchievementRankPreview(preview, entry, defaultRank, unlockedRank, currentValue);
	}

	function UpdateArmoryRefreshButton(player) {
		var button = Panel("XHSPassArmoryRefreshButton");
		var label = Panel("XHSPassArmoryRefreshLabel");
		if (!button) {
			return;
		}

		var raw = player && player.raw ? player.raw : {};
		var refreshState = (raw.armory_refresh_state || "").toString().toLowerCase();
		var used = IsTruthy(raw.armory_refresh_used, false) || refreshState === "pending" || refreshState === "used";
		var pending = armoryRefreshPending || refreshState === "pending";
		button.SetHasClass("IsPending", pending);
		button.SetHasClass("IsUsed", used && !pending);
		button.enabled = !used && !armoryRefreshPending;
		button.hittest = !used && !armoryRefreshPending;
		if (label) {
			label.text = pending
				? Text("xhs_sp_armory_refreshing", "Refreshing...")
				: (used
					? Text("xhs_sp_armory_refresh_used_short", "Refresh used")
					: Text("xhs_sp_armory_refresh", "Refresh"));
		}
	}

	function SetAchievementTooltip(panel, value) {
		if (!panel || !value) {
			return;
		}
		panel.hittest = true;
		panel.SetPanelEvent("onmouseover", function () {
			$.DispatchEvent("DOTAShowTextTooltip", panel, value);
		});
		panel.SetPanelEvent("onmouseout", function () {
			$.DispatchEvent("DOTAHideTextTooltip", panel);
		});
	}

	function AchievementRecordRank(entry, value) {
		var thresholds = AchievementList(entry && entry.thresholds);
		var rank = 0;
		for (var i = 0; i < thresholds.length; i++) {
			if (ToNumber(value, 0) >= ToNumber(thresholds[i], 0)) {
				rank = i + 1;
			}
		}
		return rank;
	}

	function PositionAchievementRecordHover(source) {
		var hover = Panel("XHSPassAchievementRecordHover");
		var root = hover && hover.GetParent ? hover.GetParent() : null;
		if (!hover || !root || !source || !source.IsValid()) {
			return;
		}
		var sourcePosition = source.GetPositionWithinWindow();
		var rootPosition = root.GetPositionWithinWindow();
		var sourceWidth = ToNumber(source.actuallayoutwidth, 0);
		var sourceHeight = ToNumber(source.actuallayoutheight, 0);
		var rootWidth = ToNumber(root.actuallayoutwidth, 1420);
		var rootHeight = ToNumber(root.actuallayoutheight, 820);
		var hoverWidth = Math.max(ToNumber(hover.actuallayoutwidth || hover.desiredlayoutwidth, 0), 390);
		var hoverHeight = Math.max(ToNumber(hover.actuallayoutheight || hover.desiredlayoutheight, 0), 166);
		var margin = 12;
		var sourceX = ToNumber(sourcePosition.x, 0) - ToNumber(rootPosition.x, 0);
		var sourceY = ToNumber(sourcePosition.y, 0) - ToNumber(rootPosition.y, 0);
		var x = sourceX + sourceWidth + margin;
		var y = sourceY + Math.floor((sourceHeight - hoverHeight) * 0.5);
		if (x + hoverWidth > rootWidth - margin) {
			x = sourceX - hoverWidth - margin;
		}
		x = Clamp(x, margin, Math.max(margin, rootWidth - hoverWidth - margin));
		y = Clamp(y, margin, Math.max(margin, rootHeight - hoverHeight - margin));
		hover.style.position = Math.floor(x) + "px " + Math.floor(y) + "px 0px";
	}

	function ShowAchievementRecordHover(source, entry, record) {
		var hover = Panel("XHSPassAchievementRecordHover");
		if (!hover || !source || !record) {
			return;
		}
		var steamID = String(record.steamid || "0");
		var value = ToNumber(record.value, 0);
		var rank = AchievementRecordRank(entry, value);
		var avatar = Panel("XHSPassAchievementRecordHoverAvatar");
		var playerName = Panel("XHSPassAchievementRecordHoverName");
		if (avatar) {
			avatar.steamid = steamID;
		}
		if (playerName) {
			playerName.steamid = steamID;
		}
		SetText("XHSPassAchievementRecordHoverSteamID", "SteamID64  " + steamID);
		SetText("XHSPassAchievementRecordHoverTitle", AchievementLocalized(entry, "title"));
		SetText("XHSPassAchievementRecordHoverTier", AchievementRankName(rank, false));
		SetText("XHSPassAchievementRecordHoverValue", FormatNumber(value));
		var medal = Panel("XHSPassAchievementRecordHoverMedal");
		if (medal) {
			medal.SetImage(AchievementMedalPath(Math.max(rank, 1), false));
		}
		hover.AddClass("IsVisible");
		PositionAchievementRecordHover(source);
		$.Schedule(0.01, function () {
			if (hover && (!hover.IsValid || hover.IsValid()) && hover.BHasClass("IsVisible")) {
				PositionAchievementRecordHover(source);
			}
		});
	}

	function HideAchievementRecordHover() {
		var hover = Panel("XHSPassAchievementRecordHover");
		if (hover) {
			hover.RemoveClass("IsVisible");
		}
	}

	function SetAchievementRecordHover(panel, entry, record) {
		if (!panel || !entry || !record) {
			return;
		}
		panel.hittest = true;
		panel.SetPanelEvent("onmouseover", function () {
			ShowAchievementRecordHover(panel, entry, record);
		});
		panel.SetPanelEvent("onmouseout", HideAchievementRecordHover);
	}

	function AchievementState(row) {
		var state = row && row.state || {};
		if (typeof state === "string") {
			try { state = JSON.parse(state); } catch (error) { state = {}; }
		}
		return state || {};
	}

	function CreateAllHeroAchievementRoster(parent, entry, progressRow) {
		var pool = AchievementList(entry.hero_pool);
		if (!parent || pool.length === 0) {
			return;
		}
		var localizedPool = [];
		for (var p = 0; p < pool.length; p++) {
			var poolHero = pool[p] || {};
			var localizedName = Localize("#" + poolHero.id);
			if (!localizedName || localizedName === poolHero.id) {
				localizedName = LocalizeMaybeKey(poolHero.name || poolHero.id || "");
			}
			localizedPool.push({
				hero: poolHero,
				name: localizedName || poolHero.id || ""
			});
		}
		localizedPool.sort(function (left, right) {
			var leftName = String(left.name || "").toLowerCase();
			var rightName = String(right.name || "").toLowerCase();
			if (leftName < rightName) { return -1; }
			if (leftName > rightName) { return 1; }
			return String(left.hero.id || "") < String(right.hero.id || "") ? -1 : 1;
		});
		var state = AchievementState(progressRow);
		var completedHeroes = AchievementList(state.heroes);
		var completed = {};
		for (var i = 0; i < completedHeroes.length; i++) {
			completed[String(completedHeroes[i])] = true;
		}
		var roster = $.CreatePanel("Panel", parent, "");
		roster.AddClass("XHSPassAchievementHeroRoster");
		var row = null;
		for (var h = 0; h < localizedPool.length; h++) {
			if (h % 10 === 0) {
				row = $.CreatePanel("Panel", roster, "");
				row.AddClass("XHSPassAchievementHeroRow");
			}
			var hero = localizedPool[h].hero;
			var icon = $.CreatePanel("DOTAHeroImage", row, "");
			icon.AddClass("XHSPassAchievementHeroIcon");
			icon.SetHasClass("IsComplete", completed[String(hero.id)] === true);
			icon.heroname = hero.id;
			icon.heroimagestyle = "landscape";
			SetAchievementTooltip(icon, localizedPool[h].name + (completed[String(hero.id)] ? "  [" + Text("xhs_sp_achievement_hero_complete", "COMPLETE") + "]" : ""));
		}
	}

	function RenderAchievements() {
		var profile = GetAchievementProfile();
		var catalog = AchievementList(profile.catalog);
		var index = AchievementProfileIndex(profile);
		var grid = Panel("XHSPassAchievementsGrid");
		if (!grid) {
			return;
		}
		ClearPanel(grid);
		SetText("XHSPassAchievementScore", FormatNumber(profile.score || 0));
		var completed = 0;
		var available = 0;
		for (var c = 0; c < catalog.length; c++) {
			if (catalog[c].available !== false && catalog[c].available !== 0) {
				available++;
				// Every earned rank is a completed achievement milestone. A progressive
				// achievement does not have to reach its final/XHS rank to count here.
				if (ToNumber(index.unlocks[catalog[c].id], 0) > 0) {
					completed++;
				}
			}
		}
		SetText("XHSPassAchievementCompletion", completed + " / " + available);

		for (var i = 0; i < catalog.length; i++) {
			var entry = catalog[i];
			var isAbsolute = entry.type === "absolute";
			var maxRank = isAbsolute ? 1 : AchievementList(entry.thresholds).length;
			var rank = ToNumber(index.unlocks[entry.id], 0);
			var isComplete = rank >= maxRank;
			var hasCompletedRank = rank > 0;
			var isComing = entry.available === false || entry.available === 0;
			if (currentAchievementFilter === "progress" && (isComplete || isComing)) { continue; }
			if (currentAchievementFilter === "complete" && (!hasCompletedRank || isComing)) { continue; }
			if (currentAchievementFilter === "coming" && !isComing) { continue; }

			var progressRow = index.progress[entry.id] || {};
			var value = ToNumber(progressRow.value, 0);
			var thresholds = AchievementList(entry.thresholds);
			var nextTarget = thresholds[Math.min(rank, thresholds.length - 1)] || (isAbsolute ? 1 : 0);
			var card = $.CreatePanel("Panel", grid, "");
			card.AddClass("XHSPassAchievementCard");
			card.SetHasClass("IsComplete", isComplete);
			card.SetHasClass("HasCompletedRank", hasCompletedRank);
			card.SetHasClass("IsLocked", rank <= 0 && !isComing);
			card.SetHasClass("IsComingSoon", isComing);
			card.SetHasClass("IsComing", isComing);
			card.SetHasClass("IsAbsolute", isAbsolute);
			card.SetHasClass("IsPinned", index.pins[entry.id] === true);
			card.SetHasClass("IsAllHeroChallenge", entry.id === "all_hero_challenge");
			card.AddClass("Rank" + Math.max(rank, 0));

			var artwork = $.CreatePanel("Image", card, "");
			artwork.AddClass("XHSPassAchievementCardArtwork");
			artwork.SetImage(AchievementIconPath(entry));
			var body = $.CreatePanel("Panel", card, "");
			body.AddClass("XHSPassAchievementCardBody");
			var top = $.CreatePanel("Panel", body, "");
			top.AddClass("XHSPassAchievementCardTop");
			var heading = $.CreatePanel("Panel", top, "");
			heading.AddClass("XHSPassAchievementCardHeading");
			CreateAchievementLabel(heading, "XHSPassAchievementCardRank", isComing
				? Text("xhs_sp_achievement_coming_in", "COMING IN {release}").replace("{release}", entry.release || Text("xhs_sp_achievement_future_update", "A FUTURE UPDATE"))
				: (isAbsolute ? Text("xhs_sp_achievement_rank_absolute", "ABSOLUTE ACHIEVEMENT") : Text("xhs_sp_achievement_progressive", "PROGRESSIVE ACHIEVEMENT")));
			CreateAchievementLabel(heading, "XHSPassAchievementCardTitle", AchievementLocalized(entry, "title"));
			if (index.pins[entry.id]) {
				CreateAchievementLabel(top, "XHSPassAchievementPinned", "★");
			}

			CreateAchievementLabel(body, "XHSPassAchievementCardDescription", AchievementLocalized(entry, "description"));
			CreateAchievementRequirements(body, entry);
			if (entry.id === "all_hero_challenge") {
				CreateAllHeroAchievementRoster(body, entry, progressRow);
			}
			var record = index.records && index.records[entry.id];
			if (!isAbsolute && record && ToNumber(record.value, 0) > 0) {
				var recordLabel = CreateAchievementLabel(
					body,
					"XHSPassAchievementRecord",
					"#1 " + Text("xhs_sp_achievement_record_worldwide", "WORLDWIDE") + "  •  " + AchievementValueLabel(record.value)
				);
				SetAchievementRecordHover(recordLabel, entry, record);
			}
			var progression = $.CreatePanel("Panel", card, "");
			progression.AddClass("XHSPassAchievementCardProgression");
			if (!isAbsolute) {
				var preview = $.CreatePanel("Panel", progression, "");
				preview.AddClass("XHSPassAchievementRankPreview");
				preview._rank = CreateAchievementLabel(preview, "XHSPassAchievementRankPreviewRank", "");
				preview._target = CreateAchievementLabel(preview, "XHSPassAchievementRankPreviewTarget", "");
				preview._reward = CreateAchievementLabel(preview, "XHSPassAchievementRankPreviewReward", "");
				var rankPips = $.CreatePanel("Panel", progression, "");
				rankPips.AddClass("XHSPassAchievementRankPips");
				CreateAchievementRankPips(rankPips, preview, entry, rank, value);
				var progressBar = $.CreatePanel("Panel", progression, "");
				progressBar.AddClass("XHSPassAchievementProgressBar");
				var progressFill = $.CreatePanel("Panel", progressBar, "");
				progressFill.AddClass("XHSPassAchievementProgressFill");
				progressFill.style.width = (isComplete ? 100 : Clamp(Math.floor(value / Math.max(nextTarget, 1) * 100), 0, 100)) + "%";
				CreateAchievementLabel(progression, "XHSPassAchievementProgressText", isComplete ? Text("xhs_sp_achievement_complete", "COMPLETE") : Text("xhs_sp_achievement_next_rank", "NEXT RANK"));
			} else {
				if (rank > 0) {
					var absoluteMedal = $.CreatePanel("Image", progression, "");
					absoluteMedal.AddClass("XHSPassAchievementAbsoluteMedal");
					absoluteMedal.SetImage(AchievementMedalPath(1, true));
				}
				var absoluteFragments = AchievementList(entry.fragments)[0] || 0;
				var absolutePoints = AchievementList(entry.points)[0] || 0;
				CreateAchievementLabel(progression, "XHSPassAchievementAbsoluteState", rank > 0 ? Text("xhs_sp_achievement_complete", "COMPLETE") : Text("xhs_sp_achievement_rank_locked", "LOCKED"));
				CreateAchievementLabel(progression, "XHSPassAchievementAbsoluteReward", "+" + FormatNumber(absoluteFragments) + " " + Text("xhs_sp_fragments", "fragments") + "   •   +" + FormatNumber(absolutePoints) + " pts");
			}
		}
	}

	function FindAchievementCatalogEntry(profile, achievementID) {
		var catalog = AchievementList(profile && profile.catalog);
		for (var i = 0; i < catalog.length; i++) {
			if (catalog[i].id === achievementID) {
				return catalog[i];
			}
		}
		return null;
	}

	function QueueAchievementReveals(profile) {
		profile = profile || GetAchievementProfile();
		var queue = AchievementList(profile.reveal_queue);
		for (var i = 0; i < queue.length; i++) {
			var reveal = queue[i];
			var revealID = ToNumber(reveal.id, 0);
			if (!revealID || achievementRevealKnown[revealID]) {
				continue;
			}
			reveal.catalog = FindAchievementCatalogEntry(profile, reveal.achievement_id);
			achievementRevealKnown[revealID] = true;
			achievementRevealQueue.push(reveal);
		}
		if (!achievementRevealActive && achievementRevealQueue.length > 0) {
			ShowNextAchievementReveal();
		}
	}

	function ShowNextAchievementReveal() {
		if (achievementRevealActive || achievementRevealQueue.length === 0) {
			return;
		}
		achievementRevealActive = achievementRevealQueue.shift();
		var reveal = achievementRevealActive;
		var entry = reveal.catalog || {};
		var rank = Math.max(1, ToNumber(reveal.rank, 1));
		var isAbsolute = entry.type === "absolute";
		var fragments = AchievementList(entry.fragments)[rank - 1] || reveal.fragments || 0;
		var points = AchievementList(entry.points)[rank - 1] || reveal.points || 0;
		SetText("XHSPassAchievementRevealRank", AchievementRankName(rank, isAbsolute));
		SetText("XHSPassAchievementRevealTitle", AchievementLocalized(entry, "title") || reveal.achievement_id || "Achievement");
		SetText("XHSPassAchievementRevealDescription", AchievementLocalized(entry, "description"));
		SetText("XHSPassAchievementRevealFragments", "+" + FormatNumber(fragments));
		SetText("XHSPassAchievementRevealPoints", "+" + FormatNumber(points));
		SetText("XHSPassAchievementRevealRemaining", achievementRevealQueue.length > 0 ? Text("xhs_sp_achievement_remaining", "{count} more achievements waiting", { count: achievementRevealQueue.length }) : "");
		var medal = Panel("XHSPassAchievementRevealMedal");
		if (medal) {
			medal.SetImage(AchievementMedalPath(rank, isAbsolute));
		}
		ToggleWindow(true);
		SwitchPage("achievements");
		var overlay = Panel("XHSPassAchievementRevealOverlay");
		if (overlay) {
			overlay.hittest = true;
			overlay.AddClass("IsVisible");
		}
		Game.EmitSound("ui.trophy_levelup");
	}

	function MarkAchievementReveals(reveals) {
		if (!GameEvents || !GameEvents.SendCustomGameEventToServer || !reveals || reveals.length === 0) {
			return;
		}
		var ids = {};
		for (var i = 0; i < reveals.length; i++) {
			ids[i + 1] = ToNumber(reveals[i].id, 0);
		}
		GameEvents.SendCustomGameEventToServer("xhs_achievements_mark_revealed", { ids: ids });
	}

	function ContinueAchievementReveal() {
		if (!achievementRevealActive) {
			return;
		}
		MarkAchievementReveals([achievementRevealActive]);
		achievementRevealActive = null;
		var overlay = Panel("XHSPassAchievementRevealOverlay");
		if (overlay) {
			overlay.RemoveClass("IsVisible");
			overlay.hittest = false;
		}
		Game.EmitSound("General.ButtonClick");
		$.Schedule(0.32, ShowNextAchievementReveal);
	}

	function RevealAllAchievements() {
		var all = [];
		if (achievementRevealActive) {
			all.push(achievementRevealActive);
		}
		for (var i = 0; i < achievementRevealQueue.length; i++) {
			all.push(achievementRevealQueue[i]);
		}
		MarkAchievementReveals(all);
		achievementRevealActive = null;
		achievementRevealQueue = [];
		var overlay = Panel("XHSPassAchievementRevealOverlay");
		if (overlay) {
			overlay.RemoveClass("IsVisible");
			overlay.hittest = false;
		}
		Game.EmitSound("General.ButtonClick");
	}

	function RenderAll() {
		var player = GetDisplayPlayerData(GetLocalPlayerData());
		UpdateShopAvailability();
		RenderHeader(player);
		RenderTiers(player);
		RenderRewards(player);
		RenderShop(player);
		RenderArmory(player);
		RenderSettings(player);
		RenderAchievements();
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

		var armoryRefresh = Panel("XHSPassArmoryRefreshButton");
		if (armoryRefresh) {
			armoryRefresh.SetPanelEvent("onactivate", function () {
				var player = GetLocalPlayerData();
				var raw = player && player.raw ? player.raw : {};
				if (armoryRefreshPending || IsTruthy(raw.armory_refresh_used, false)) {
					Game.EmitSound("General.Cancel");
					return;
				}

				armoryRefreshPending = true;
				UpdateArmoryRefreshButton(player);
				Game.EmitSound("General.ButtonClick");
				ShowActionMessage(Text("xhs_sp_armory_refreshing", "Refreshing Armory..."), true);
				GameEvents.SendCustomGameEventToServer("supporter_pass_refresh_armory", {});
			});
		}

		var achievementFilters = {
			XHSPassAchievementFilterAll: "all",
			XHSPassAchievementFilterProgress: "progress",
			XHSPassAchievementFilterComplete: "complete",
			XHSPassAchievementFilterComing: "coming",
		};
		for (var achievementFilterButton in achievementFilters) {
			if (achievementFilters.hasOwnProperty(achievementFilterButton)) {
				(function (buttonID, filterName) {
					var filterButton = Panel(buttonID);
					if (filterButton) {
						filterButton.SetPanelEvent("onactivate", function () {
							SetAchievementFilter(filterName);
							Game.EmitSound("General.ButtonClick");
						});
					}
				})(achievementFilterButton, achievementFilters[achievementFilterButton]);
			}
		}

		var achievementContinue = Panel("XHSPassAchievementRevealContinueButton");
		if (achievementContinue) {
			achievementContinue.SetPanelEvent("onactivate", ContinueAchievementReveal);
		}
		var achievementRevealAll = Panel("XHSPassAchievementRevealAllButton");
		if (achievementRevealAll) {
			achievementRevealAll.SetPanelEvent("onactivate", RevealAllAchievements);
		}

		var shopSearch = Panel("XHSPassShopSearch");
		if (shopSearch) {
			shopSearch.SetPanelEvent("ontextentrychange", function () {
				currentShopSearch = BoundedUIEventValue(shopSearch.text || "", 64);
				shopSearch.SetHasClass("HasInput", currentShopSearch.length > 0);
				ResetPagination("shop");
				RenderShop(GetLocalPlayerData());
				shopSearchTelemetrySerial++;
				var serial = shopSearchTelemetrySerial;
				$.Schedule(0.4, function () {
					if (serial !== shopSearchTelemetrySerial) {
						return;
					}
					EmitSupporterUIEvent("search", {
						tab: "shop",
						query_length: currentShopSearch.length,
						filter_key: "category",
						filter_value: currentShopFilter,
					});
				});
			});
		}

		var shopHighlightsTab = Panel("XHSPassShopHighlightsTab");
		if (shopHighlightsTab) {
			shopHighlightsTab.SetPanelEvent("onactivate", function () {
				if (currentShopView === "highlights") { return; }
				currentShopView = "highlights";
				SetShopDetailVisible(false);
				RenderShop(GetLocalPlayerData());
				Game.EmitSound("General.ButtonClick");
				EmitSupporterUIEvent("shop_view", { tab: "shop", view: "highlights" });
			});
		}

		var shopBrowseTab = Panel("XHSPassShopBrowseTab");
		if (shopBrowseTab) {
			shopBrowseTab.SetPanelEvent("onactivate", function () {
				if (currentShopView === "browse") { return; }
				currentShopView = "browse";
				SetShopDetailVisible(false);
				RenderShop(GetLocalPlayerData());
				Game.EmitSound("General.ButtonClick");
				EmitSupporterUIEvent("shop_view", { tab: "shop", view: "browse" });
			});
		}

		var closeShopDetail = Panel("XHSPassShopDetailClose");
		if (closeShopDetail) {
			closeShopDetail.SetPanelEvent("onactivate", function () {
				SetShopDetailVisible(false);
				Game.EmitSound("General.Cancel");
			});
		}

		var shopDetailBackdrop = Panel("XHSPassShopDetailBackdrop");
		if (shopDetailBackdrop) {
			shopDetailBackdrop.SetPanelEvent("onactivate", function () {
				SetShopDetailVisible(false);
				Game.EmitSound("General.Cancel");
			});
		}

		var purchaseConfirmCancel = Panel("XHSPassPurchaseConfirmCancel");
		var purchaseConfirmBackdrop = Panel("XHSPassPurchaseConfirmBackdrop");
		var purchaseConfirmSubmit = Panel("XHSPassPurchaseConfirmSubmit");
		var cancelPurchaseConfirmation = function () {
			SetPurchaseConfirmationVisible(false);
			Game.EmitSound("General.Cancel");
		};
		if (purchaseConfirmCancel) purchaseConfirmCancel.SetPanelEvent("onactivate", cancelPurchaseConfirmation);
		if (purchaseConfirmBackdrop) purchaseConfirmBackdrop.SetPanelEvent("onactivate", cancelPurchaseConfirmation);
		if (purchaseConfirmSubmit) purchaseConfirmSubmit.SetPanelEvent("onactivate", ConfirmShopPurchase);

		var devUnlockUI = Panel("XHSPassDevUnlockUIButton");
		if (devUnlockUI) {
			devUnlockUI.SetPanelEvent("onactivate", function () {
				var player = GetLocalPlayerData();
				if (!IsLocalSupporterDeveloper(player)) {
					Game.EmitSound("General.Cancel");
					return;
				}

				devUnlockAllUI = !devUnlockAllUI;
				if (devUnlockAllUI) {
					devUnlockFreeUI = false;
				}
				devLocallyClaimedRewards = {};
				devLocalEquippedBySlot = {};
				GameEvents.SendCustomGameEventToServer("supporter_pass_dev_equip_local", {
					action: "clear",
				});
				ResetPagination("armory");
				RenderAll();
				ShowActionMessage(
					devUnlockAllUI
						? "DEV UI enabled \u00b7 claim rewards locally without touching the backend."
						: "DEV UI preview disabled \u00b7 account ownership restored.",
					true
				);
				Game.EmitSound("General.ButtonClick");
			});
		}

		var devFreeUI = Panel("XHSPassDevFreeUIButton");
		if (devFreeUI) {
			devFreeUI.SetPanelEvent("onactivate", function () {
				var player = GetLocalPlayerData();
				if (!IsLocalSupporterDeveloper(player)) {
					Game.EmitSound("General.Cancel");
					return;
				}

				devUnlockFreeUI = !devUnlockFreeUI;
				if (devUnlockFreeUI) {
					devUnlockAllUI = false;
				}
				devLocalEquippedBySlot = {};
				GameEvents.SendCustomGameEventToServer("supporter_pass_dev_equip_local", {
					action: "clear",
				});
				ResetPagination("armory");
				RenderAll();
				ShowActionMessage(
					devUnlockFreeUI
						? "Free-player preview enabled · Free Track unlocked, Premium Track locked."
						: "Free-player preview disabled · account ownership restored.",
					true
				);
				Game.EmitSound("General.ButtonClick");
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

		var assetRequestSearch = Panel("XHSPassAssetRequestSearch");
		if (assetRequestSearch) {
			assetRequestSearch.SetPanelEvent("ontextentrychange", function () {
				assetRequestView.search = (assetRequestSearch.text || "").toString();
				assetRequestSearch.SetHasClass("HasInput", assetRequestView.search.length > 0);
				assetRequestSearch.placeholder = assetRequestView.search
					? ""
					: Text("xhs_sp_request_search", "Search by name or unit...");
				ResetPagination("asset_request");
				RenderCourierRequestResults();
			});
		}

		var support = Panel("XHSPassSupportButton");
		if (support) {
			support.SetPanelEvent("onactivate", function () {
				OpenSupporterPortal("supporter_pass");
			});
		}

		var premiumCTA = Panel("XHSPassPremiumCTAButton");
		if (premiumCTA) {
			premiumCTA.SetPanelEvent("onactivate", function () {
				OpenSupporterPortal("premium_cta");
			});
		}

		var chinaPaymentButton = Panel("XHSPassChinaPaymentButton");
		if (chinaPaymentButton) {
			chinaPaymentButton.SetPanelEvent("onactivate", function () {
				Game.EmitSound("General.ButtonClick");
				SetChinaPaymentVisible(true);
			});
		}

		var chinaPaymentClose = Panel("XHSPassChinaPaymentCloseButton");
		var chinaPaymentBackdrop = Panel("XHSPassChinaPaymentBackdrop");
		var chinaPaymentCancel = Panel("XHSPassChinaPaymentCancelButton");
		var closeChinaPayment = function () {
			SetChinaPaymentVisible(false);
			Game.EmitSound("General.Cancel");
		};
		if (chinaPaymentClose) chinaPaymentClose.SetPanelEvent("onactivate", closeChinaPayment);
		if (chinaPaymentBackdrop) chinaPaymentBackdrop.SetPanelEvent("onactivate", closeChinaPayment);
		if (chinaPaymentCancel) chinaPaymentCancel.SetPanelEvent("onactivate", closeChinaPayment);

		var chinaPaymentContinue = Panel("XHSPassChinaPaymentContinueButton");
		if (chinaPaymentContinue) {
			chinaPaymentContinue.SetPanelEvent("onactivate", BeginChinaPaymentCheckout);
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
					$.Schedule(16.0, function () {
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
			GameEvents.Subscribe("xhs_achievements_unlocked", function () {
				$.Schedule(0.15, function () {
					var profile = GetAchievementProfile();
					RenderAchievements();
					QueueAchievementReveals(profile);
				});
			});
			GameEvents.Subscribe("supporter_pass_purchase_pending", function () {
				ShowActionMessage(Text("xhs_sp_purchase_pending", "Supporter Pass purchase pending..."), true);
			});
			GameEvents.Subscribe("supporter_pass_purchase_success", function (payload) {
				SetActionPending("purchase", payload && payload.item_id, false);
				if (payload && payload.item_id) { delete purchaseRequestByItem[payload.item_id]; }
				EmitSupporterUIEvent("shop_purchase_success", { item_id: payload && payload.item_id, result: "succeeded" });
				ShowActionMessage(Text(payload && payload.already_owned ? "xhs_sp_duplicate_purchase_complete" : "xhs_sp_purchase_complete", payload && payload.already_owned ? "Purchase complete. Another giftable copy was added." : "Purchase complete."), true);
				RenderAll();
			});
			GameEvents.Subscribe("supporter_pass_purchase_failed", function (payload) {
				SetActionPending("purchase", payload && payload.item_id, false);
				EmitSupporterUIEvent("shop_purchase_failed", { item_id: payload && payload.item_id, result: "failed", error_code: payload && payload.code });
				ShowActionMessage(LocalizeMaybeKey((payload && payload.message) || "#xhs_sp_purchase_failed"), false);
				RenderAll();
			});
			GameEvents.Subscribe("supporter_pass_armory_refresh_success", function () {
				armoryRefreshPending = false;
				ResetPagination("armory");
				RenderAll();
				ShowActionMessage(Text("xhs_sp_armory_refreshed", "Armory refreshed. New website purchases are now available."), true);
			});
			GameEvents.Subscribe("supporter_pass_armory_refresh_failed", function (payload) {
				armoryRefreshPending = false;
				RenderAll();
				payload = payload || {};
				ShowActionMessage(LocalizeMaybeKey(payload.message || "#xhs_sp_armory_refresh_failed"), false);
			});
			GameEvents.Subscribe("supporter_pass_bundle_open_success", function (payload) {
				SetActionPending("bundle_open", payload && payload.instance_id, false);
				if (payload && payload.instance_id) { delete bundleOpenRequestByInstance[payload.instance_id]; }
				ShowActionMessage(Text("xhs_sp_bundle_opened", "Bundle opened. Its items are now in your Armory."), true);
				RenderAll();
			});
			GameEvents.Subscribe("supporter_pass_bundle_open_failed", function (payload) {
				SetActionPending("bundle_open", payload && payload.instance_id, false);
				ShowActionMessage(LocalizeMaybeKey((payload && payload.message) || "#xhs_sp_bundle_open_failed"), false);
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
			GameEvents.Subscribe("supporter_pass_unequip_success", function (payload) {
				SetActionPending("unequip", payload && payload.slot_id, false);
				ShowActionMessage(Text("xhs_sp_cosmetic_unequipped", "Cosmetic unequipped."), true);
				RenderAll();
			});
			GameEvents.Subscribe("supporter_pass_unequip_failed", function (payload) {
				SetActionPending("unequip", payload && payload.slot_id, false);
				ShowActionMessage(LocalizeMaybeKey((payload && payload.message) || "#xhs_sp_unequip_failed"), false);
				RenderAll();
			});
			GameEvents.Subscribe("supporter_pass_dev_equip_local_result", function (payload) {
				payload = payload || {};
				var action = (payload.action || "equip").toString();
				var itemID = (payload.item_id || "").toString();
				var slot = CanonicalSupporterSlot(payload.slot_id || "");
				var success = payload.success === true || payload.success === 1;
				if (itemID) {
					SetActionPending("dev_equip", itemID, false);
				}
				if (action === "unequip") {
					SetActionPending("dev_unequip", slot, false);
				} else if (action === "unequip_all") {
					SetActionPending("dev_unequip", "all", false);
				}
				if (!success) {
					ShowActionMessage(LocalizeMaybeKey(payload.message || "#xhs_sp_dev_test_error_item"), false);
					RenderAll();
					return;
				}
				if (action === "equip" && slot && itemID) {
					devLocalEquippedBySlot[slot] = itemID;
					ShowActionMessage("DEV cosmetic equipped locally \u00b7 backend unchanged.", true);
				} else if (action === "unequip" && slot) {
					devLocalEquippedBySlot[slot] = "";
					ShowActionMessage("DEV cosmetic unequipped locally \u00b7 backend unchanged.", true);
				} else if (action === "unequip_all") {
					for (var devSlotIndex = 0; devSlotIndex < DEV_LOCAL_LOADOUT_SLOTS.length; devSlotIndex++) {
						devLocalEquippedBySlot[DEV_LOCAL_LOADOUT_SLOTS[devSlotIndex]] = "";
					}
					ShowActionMessage("DEV supporter loadout unequipped locally \u00b7 backend unchanged.", true);
				} else if (action === "clear") {
					devLocalEquippedBySlot = {};
				}
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
			GameEvents.Subscribe("supporter_pass_payment_portal_ready", function (payload) {
				supporterPortalRequestPending = false;
				if (payload && payload.url) OpenExternalURL(payload.url);
			});
			GameEvents.Subscribe("supporter_pass_payment_portal_failed", function (payload) {
				supporterPortalRequestPending = false;
				ShowActionMessage(payload && payload.message ? payload.message : "Unable to open the supporter payment page.", false);
			});
			GameEvents.Subscribe("supporter_pass_payment_options_ready", function (payload) {
				payload = payload || {};
				chinaPaymentState.loading = false;
				chinaPaymentState.providers = AsArray(payload.providers);
				chinaPaymentState.offers = AsArray(payload.offers);
				var configuredCount = 0;
				for (var providerIndex = 0; providerIndex < chinaPaymentState.providers.length; providerIndex++) {
					if (IsTruthy((chinaPaymentState.providers[providerIndex] || {}).configured, false)) configuredCount++;
				}
				SetChinaPaymentStatus(configuredCount > 0
					? "Choose a fixed access pass. Checkout opens in the Steam overlay.  /  选择有效期，支付页面将在 Steam 界面中打开。"
					: "WeChat Pay and Alipay are not enabled on this server yet.", configuredCount > 0 ? "" : "error");
				RenderChinaPaymentFallback();
			});
			GameEvents.Subscribe("supporter_pass_payment_options_failed", function (payload) {
				chinaPaymentState.loading = false;
				SetChinaPaymentStatus(payload && payload.message ? payload.message : "Payment options are temporarily unavailable.", "error");
				RenderChinaPaymentFallback();
			});
			GameEvents.Subscribe("supporter_pass_direct_checkout_ready", function (payload) {
				payload = payload || {};
				chinaPaymentState.order_key = (payload.order_key || "").toString();
				var checkoutURL = (payload.checkout_url || "").toString();
				if (checkoutURL.indexOf("https://checkout.stripe.com/") !== 0) {
					chinaPaymentState.pending = false;
					SetChinaPaymentStatus("The payment provider returned an invalid checkout address.", "error");
					RenderChinaPaymentFallback();
					return;
				}
				SetChinaPaymentStatus("Secure checkout opened. Complete payment there; the game is verifying it automatically.  /  安全支付页面已打开，游戏将自动验证支付。", "");
				OpenExternalURL(checkoutURL);
				EmitSupporterUIEvent("china_checkout_opened", { provider: payload.provider || chinaPaymentState.provider });
			});
			GameEvents.Subscribe("supporter_pass_direct_checkout_failed", function (payload) {
				chinaPaymentState.pending = false;
				SetChinaPaymentStatus(payload && payload.message ? payload.message : "Unable to create the secure checkout.", "error");
				RenderChinaPaymentFallback();
				EmitSupporterUIEvent("china_checkout_failed", { provider: chinaPaymentState.provider, error_code: payload && payload.code });
			});
			GameEvents.Subscribe("supporter_pass_direct_checkout_status", function (payload) {
				payload = payload || {};
				var orderKey = (payload.order_key || "").toString();
				if (chinaPaymentState.order_key && orderKey && orderKey !== chinaPaymentState.order_key) return;
				if (IsTruthy(payload.confirmed, false) || (payload.status || "").toString() === "paid") {
					chinaPaymentState.pending = false;
					SetChinaPaymentStatus("Payment confirmed. Your supporter access is active.  /  支付已确认，支持者权益已生效。", "success");
					RenderChinaPaymentFallback();
					RenderAll();
					EmitSupporterUIEvent("china_checkout_confirmed", { provider: payload.provider || chinaPaymentState.provider, tier_id: payload.tier_id || chinaPaymentState.tier_id });
					return;
				}
				if (IsTruthy(payload.terminal, false) || IsTruthy(payload.failed, false)) {
					chinaPaymentState.pending = false;
					SetChinaPaymentStatus("Payment was not completed. You can safely try again.", "error");
					RenderChinaPaymentFallback();
					return;
				}
				if ((payload.status || "").toString() === "verification_unavailable") {
					SetChinaPaymentStatus(payload.message || "Payment received by the provider; verification will retry automatically.", "");
				} else if ((payload.status || "").toString() === "verification_timeout") {
					chinaPaymentState.pending = false;
					SetChinaPaymentStatus(payload.message || "Automatic verification paused. A completed payment will still activate securely; you may also try again.", "");
					RenderChinaPaymentFallback();
				} else {
					SetChinaPaymentStatus("Waiting for Stripe confirmation... Keep this game open.  /  正在等待 Stripe 确认…", "");
				}
			});
			GameEvents.Subscribe("supporter_pass_catalog_preview_result", function (payload) {
				payload = payload || {};
				var requestID = (payload.request_id || "").toString();
				if (requestID && catalogPreviewState.request_id && requestID !== catalogPreviewState.request_id) {
					return;
				}
				var previousPreviewState = catalogPreviewState;
				var allowedStatuses = { pending: true, active: true, success: true, idle: true, error: true };
				var status = (payload.status || "error").toString().toLowerCase();
				if (allowedStatuses[status] !== true) {
					status = "error";
				}
				catalogPreviewState = {
					status: status,
					request_id: requestID,
					item_id: (payload.item_id || previousPreviewState.item_id || "").toString(),
					slot_id: (payload.slot_id || previousPreviewState.slot_id || "").toString(),
					category: (previousPreviewState.category || "").toString(),
					message: payload.message || Text("xhs_sp_preview_" + status, status),
					expires_in: Math.max(0, ToNumber(payload.expires_in, 0)),
					started_at_ms: Math.max(0, ToNumber(previousPreviewState.started_at_ms, 0)),
				};
				if (status === "error") {
					EmitCatalogPreviewTelemetry("preview_fail", catalogPreviewState, {
						result: "server_error",
						error_code: payload.error_code || payload.code || "server_error",
					});
					ShowActionMessage(LocalizeMaybeKey(catalogPreviewState.message), false);
				} else if (status === "active") {
					if (previousPreviewState.status !== "active") {
						EmitCatalogPreviewTelemetry("preview_verified", catalogPreviewState, { result: "active" });
					}
					ShowActionMessage(Text("xhs_sp_preview_active", "Preview active. The effect will stop automatically."), true);
					ToggleWindow(false);
				} else if (status === "success" || status === "idle") {
					EmitCatalogPreviewTelemetry("preview_stop", catalogPreviewState, {
						result: previousPreviewState.status === "stopping" ? "stopped" : "expired",
					});
					ShowActionMessage(LocalizeMaybeKey(catalogPreviewState.message), true);
				}
				RefreshShopDetail(GetLocalPlayerData());
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
			var handleAssetRequestResult = function (payload) {
				payload = payload || {};
				var requestKey = (payload.request_key || "").toString();
				if (!requestKey && payload.item_def) {
					requestKey = "companion:courier:" + payload.item_def.toString();
				}
				if (!requestKey) {
					return;
				}
				var accepted = payload.accepted === true || payload.accepted === 1;
				assetRequestResultState[requestKey] = accepted ? "success" : "error";
				ShowActionMessage(
					LocalizeMaybeKey(payload.message || (accepted ? "#xhs_sp_request_recorded" : "#xhs_sp_request_failed")),
					accepted
				);
				var requestOverlay = Panel("XHSPassCourierRequestOverlay");
				if (requestOverlay && requestOverlay.BHasClass("IsVisible")) {
					RenderCourierRequestOverlay();
				}
			};
			GameEvents.Subscribe("supporter_pass_asset_request_result", handleAssetRequestResult);
			GameEvents.Subscribe("supporter_pass_companion_request_result", handleAssetRequestResult);
		}
	}

	function Init() {
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
			config.XHSSupporterPassVisible = false;
			config.XHSSupporterPassOccludesOverheads = false;
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
			CustomNetTables.SubscribeNetTableListener("xhs_achievements_catalog", function () {
				var profile = GetAchievementProfile();
				RenderAchievements();
				QueueAchievementReveals(profile);
			});
			CustomNetTables.SubscribeNetTableListener("xhs_achievements_player", function (tableName, key) {
				if (key !== Players.GetLocalPlayer().toString()) {
					return;
				}
				var profile = GetAchievementProfile();
				RenderAchievements();
				QueueAchievementReveals(profile);
			});
			CustomNetTables.SubscribeNetTableListener("supporter_pass_player", RenderAll);
			CustomNetTables.SubscribeNetTableListener("supporter_pass_armory", function (tableName, key) {
				if (key === "rewards_" + Players.GetLocalPlayer()) {
					RenderArmory(GetLocalPlayerData());
				}
			});
			CustomNetTables.SubscribeNetTableListener("supporter_pass_shop", function (tableName, key) {
				// Catalog is the normal atomic generation switch. Listening to chunk
				// keys too makes late/out-of-order client replication self-healing.
				if (key === "catalog" || /^items_\d+$/.test(key || "")) {
					RenderAll();
				}
			});
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
		QueueAchievementReveals(GetAchievementProfile());
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
