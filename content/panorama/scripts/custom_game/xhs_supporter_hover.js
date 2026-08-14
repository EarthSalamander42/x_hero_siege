"use strict";

var XHSSupporterHover = (function () {
	var DAILY_FRAGMENT_CAP = 190;
	var DEFAULT_SUPPORTER_TIER_CATALOG = [
		{ id: 0, name: "Free Player", color: "#7db9d8", fragments: 0, xpBoost: 0, votePower: 1 },
		{ id: 1, name: "Donator", color: "#45C46B", fragments: 150, xpBoost: 10, votePower: 2 },
		{ id: 2, name: "Golden Donator", color: "#F2C94C", fragments: 400, xpBoost: 20, votePower: 3 },
		{ id: 3, name: "Ember Donator", color: "#E4572E", fragments: 900, xpBoost: 30, votePower: 4 },
		{ id: 4, name: "Stoneguard Donator", color: "#5AD0FF", fragments: 1800, xpBoost: 40, votePower: 5 },
		{ id: 5, name: "Earthwarden Donator", color: "#C99CFF", fragments: 1800, xpBoost: 40, votePower: 5 },
	];
	var SUPPORTER_SLOT_ORDER = [
		"teleport", "levelup", "kill_effect", "emblem", "potion", "rebirth",
		"attack_lifesteal", "spell_lifesteal", "regen_aura", "immolation",
		"high_five", "companion", "effigy", "title"
	];
	var SUPPORTER_SLOT_LABELS = {
		teleport: ["xhs_sp_type_teleport", "Teleport FX"],
		levelup: ["xhs_sp_type_tome", "Ascension FX"],
		kill_effect: ["xhs_sp_type_kill", "Kill FX"],
		emblem: ["xhs_sp_type_emblem", "Emblem"],
		potion: ["xhs_sp_type_potion", "Potion FX"],
		rebirth: ["xhs_sp_type_rebirth", "Rebirth FX"],
		attack_lifesteal: ["xhs_sp_type_attack_lifesteal", "Attack Lifesteal"],
		spell_lifesteal: ["xhs_sp_type_spell_lifesteal", "Spell Lifesteal"],
		regen_aura: ["xhs_sp_type_regen_aura", "Regen Aura"],
		immolation: ["xhs_sp_type_immolation", "Immolation"],
		high_five: ["xhs_sp_type_high_five", "High Five"],
		companion: ["xhs_sp_type_companion", "Companion"],
		effigy: ["xhs_sp_type_effigy", "Effigy"],
		title: ["xhs_sp_type_title", "Title"]
	};

	function ToNumber(value, fallback) {
		var numberValue = Number(value);
		return isNaN(numberValue) ? (fallback || 0) : numberValue;
	}

	function Clamp(value, minValue, maxValue) {
		value = ToNumber(value, minValue);
		return Math.max(minValue, Math.min(maxValue, value));
	}

	function FormatNumber(value) {
		var numberValue = Math.max(0, ToNumber(value, 0));
		if (numberValue >= 1000000) {
			return (numberValue / 1000000).toFixed(1) + "M";
		}
		if (numberValue >= 10000) {
			return (numberValue / 1000).toFixed(1) + "k";
		}

		return Math.floor(numberValue).toString();
	}

	function FormatVotePower(value) {
		var votes = Math.max(1, Math.floor(ToNumber(value, 1)));
		return votes + " setup " + (votes > 1 ? "votes" : "vote");
	}

	function LocalizeMaybeKey(value) {
		value = value === undefined || value === null ? "" : value.toString();
		if (!value) {
			return "";
		}
		var token = value.charAt(0) === "#" ? value : "#" + value;
		var localized = $.Localize(token);
		return localized && localized !== token ? localized : value;
	}

	function ResolveSupporterImageURL(imagePath) {
		var raw = imagePath ? imagePath.toString().replace(/\\/g, "/") : "";
		if (!raw || raw.indexOf("particles/") === 0) {
			return "";
		}
		if (raw.indexOf("s2r://panorama/images/") === 0 || raw.indexOf("file://{images}/") === 0) {
			return raw;
		}
		var normalized = raw
			.replace(/^file:\/\/\{images\}\//, "")
			.replace(/^s2r:\/\/panorama\/images\//, "")
			.replace(/_png\.vtex$/, "")
			.replace(/\.png$/, "");
		if (normalized.indexOf("custom_game/") === 0) {
			return "file://{images}/" + normalized + ".png";
		}
		var dotaRoots = ["badges/", "battlepass/", "compendium/", "econ/", "events/", "game_modes/", "heroes/", "items/", "spellicons/", "status_icons/"];
		for (var index = 0; index < dotaRoots.length; index++) {
			if (normalized.indexOf(dotaRoots[index]) === 0) {
				return "s2r://panorama/images/" + normalized + "_png.vtex";
			}
		}
		return "file://{images}/custom_game/" + normalized + ".png";
	}

	function SetSupporterItemImage(panel, imagePath) {
		var imageURL = ResolveSupporterImageURL(imagePath);
		panel.SetHasClass("HasImage", !!imageURL);
		if (imageURL) {
			panel.style.backgroundImage = 'url("' + imageURL + '")';
			panel.style.backgroundSize = "contain";
			panel.style.backgroundPosition = "50% 50%";
			panel.style.backgroundRepeat = "no-repeat";
		}
	}

	function NormalizeSupporterSlot(slot) {
		var normalized = (slot || "default").toString().toLowerCase();
		var aliases = {
			teleport_fx: "teleport",
			tome: "levelup",
			tome_fx: "levelup",
			kill_fx: "kill_effect",
			courier: "companion",
			statue: "effigy",
			bottle: "potion",
			ankh: "rebirth",
			lifesteal: "attack_lifesteal",
			fountain: "regen_aura",
			radiance: "immolation",
			highfive: "high_five"
		};
		return aliases[normalized] || normalized;
	}

	function GetEquippedItemIdentity(item) {
		return (item && (item.item_id || item.catalog_item_id || item.id || item.name || item.item_name) || "").toString();
	}

	function NormalizeEquippedItems(value) {
		var items = [];
		if (!value || typeof value !== "object") {
			return items;
		}
		if (value.slot_id || value.item_type || value.type) {
			value = { 1: value };
		}
		for (var key in value) {
			if (!value.hasOwnProperty(key)) {
				continue;
			}
			var source = value[key];
			var item = typeof source === "object" && source !== null ? source : {
				item_id: source,
				slot_id: key
			};
			var slot = NormalizeSupporterSlot(item.slot_id || item.item_type || item.type || key);
			if (!slot || slot === "default" || !GetEquippedItemIdentity(item)) {
				continue;
			}
			items.push({
				slot: slot,
				name: item.name || item.item_name || item.title_text || GetEquippedItemIdentity(item),
				image: item.image || item.image_inventory || item.icon || item.icon_path || ""
			});
		}
		items.sort(function (a, b) {
			var aIndex = SUPPORTER_SLOT_ORDER.indexOf(a.slot);
			var bIndex = SUPPORTER_SLOT_ORDER.indexOf(b.slot);
			if (aIndex < 0) aIndex = SUPPORTER_SLOT_ORDER.length;
			if (bIndex < 0) bIndex = SUPPORTER_SLOT_ORDER.length;
			return aIndex === bIndex ? a.slot.localeCompare(b.slot) : aIndex - bIndex;
		});
		return items;
	}

	function GetSupporterSlotLabel(slot) {
		var entry = SUPPORTER_SLOT_LABELS[slot];
		if (!entry) {
			return slot.replace(/_/g, " ").toUpperCase();
		}
		var localized = $.Localize("#" + entry[0]);
		return localized && localized !== "#" + entry[0] ? localized : entry[1];
	}

	function RenderEquippedItems(hover, id, equippedItems) {
		var section = hover.FindChildTraverse("XHSSupporterHoverEquipped_" + id);
		var grid = hover.FindChildTraverse("XHSSupporterHoverEquippedGrid_" + id);
		if (!section || !grid) {
			return;
		}
		grid.RemoveAndDeleteChildren();
		equippedItems = equippedItems || [];
		section.style.visibility = equippedItems.length > 0 ? "visible" : "collapse";
		for (var index = 0; index < equippedItems.length; index++) {
			var item = equippedItems[index];
			var cell = $.CreatePanel("Panel", grid, "");
			cell.AddClass("XHSSupporterHoverEquippedItem");
			var image = $.CreatePanel("Panel", cell, "");
			image.AddClass("XHSSupporterHoverEquippedImage");
			SetSupporterItemImage(image, item.image);
			var copy = $.CreatePanel("Panel", cell, "");
			copy.AddClass("XHSSupporterHoverEquippedCopy");
			var slot = $.CreatePanel("Label", copy, "");
			slot.AddClass("XHSSupporterHoverEquippedSlot");
			slot.text = GetSupporterSlotLabel(item.slot);
			var name = $.CreatePanel("Label", copy, "");
			name.AddClass("XHSSupporterHoverEquippedName");
			name.text = LocalizeMaybeKey(item.name);
		}
	}

	function FormatWinrate(value) {
		if (value === undefined || value === null || value === "") {
			return "-";
		}

		var numberValue = Number(value);
		if (isNaN(numberValue)) {
			return value.toString();
		}

		if (numberValue > 0 && numberValue <= 1) {
			numberValue = numberValue * 100;
		}

		return Math.round(numberValue) + "%";
	}

	function FormatAccountXPSummary(data) {
		var level = Math.max(0, ToNumber(data.accountLevel, 0));
		var total = Math.max(0, ToNumber(data.accountXPTotal, 0));
		var current = Math.max(0, ToNumber(data.accountXPCurrent, 0));
		var max = Math.max(0, ToNumber(data.accountXPMax, 0));

		if (level <= 0 && total <= 0 && current <= 0 && max <= 0) {
			return "-";
		}

		if (total > 0) {
			return "L" + Math.max(1, level) + " " + FormatNumber(total);
		}

		if (max > 0) {
			return "L" + Math.max(1, level) + " " + FormatNumber(current) + " / " + FormatNumber(max);
		}

		return "L" + Math.max(1, level);
	}

	function LocalizeHeroName(heroName) {
		if (!heroName) {
			return "";
		}

		var token = "#" + heroName;
		var localized = $.Localize(token);
		return localized && localized !== token ? localized : heroName.replace(/^npc_dota_hero_/, "").replace(/_/g, " ").toUpperCase();
	}

	function SetChildText(parent, childID, value) {
		if (!parent) {
			return;
		}

		var child = parent.FindChildTraverse(childID);
		if (child) {
			child.text = value === undefined || value === null ? "" : value.toString();
		}
	}

	function ResolveHoverIdentity(data) {
		data = data || {};
		if (typeof XHSNameDisplay !== "undefined" && XHSNameDisplay.Resolve) {
			return XHSNameDisplay.Resolve({
				playerID: data.playerID,
				entityIndex: data.entIndex,
				playerName: data.playerName,
				heroName: data.heroName,
				heroDisplayName: data.localHeroName,
			});
		}

		// Privacy-safe fallback for layouts that failed to load the shared helper.
		return data.localHeroName || LocalizeHeroName(data.heroName) || "";
	}

	function SetFillPercent(parent, childID, current, max) {
		if (!parent) {
			return;
		}

		var child = parent.FindChildTraverse(childID);
		if (!child) {
			return;
		}

		var maxValue = Math.max(1, ToNumber(max, 1));
		var percent = Clamp((ToNumber(current, 0) / maxValue) * 100, 0, 100);
		child.style.width = percent + "%";
	}

	function GetPanelWindowPosition(panel) {
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

	function NormalizeTierID(tierID, data) {
		if (IsEarthwardenSupporterData(data)) {
			return 5;
		}

		var normalizedTier = Math.floor(ToNumber(tierID, 0));
		var statusToTier = {
			6: 1,
			7: 4,
			8: 5,
			9: 5,
			4: 3,
			5: 2,
			1: 5,
			2: 5,
			3: 5,
		};

		if (normalizedTier > 5 && statusToTier[normalizedTier] !== undefined) {
			return statusToTier[normalizedTier];
		}

		if (statusToTier[normalizedTier] !== undefined && !(data && (data.tier_id || data.supporter_tier))) {
			return statusToTier[normalizedTier];
		}

		return Clamp(normalizedTier, 0, 5);
	}

	function GetTierCatalog() {
		var catalog = DEFAULT_SUPPORTER_TIER_CATALOG.slice(0);
		var tiers = CustomNetTables.GetTableValue("supporter_pass_meta", "tiers");

		if (!tiers) {
			return catalog;
		}

		for (var key in tiers) {
			if (!tiers.hasOwnProperty(key)) {
				continue;
			}

			var tier = tiers[key];
			if (!tier) {
				continue;
			}

			var tierID = Clamp(ToNumber(tier.id || key, 0), 0, 5);
			var fallback = catalog[tierID] || DEFAULT_SUPPORTER_TIER_CATALOG[0];

			catalog[tierID] = {
				id: tierID,
				name: tier.name || fallback.name,
				color: tier.color || fallback.color,
				fragments: ToNumber(tier.fragments || tier.monthly_fragments, fallback.fragments),
				xpBoost: ToNumber(tier.xp_boost || tier.xpBoost, fallback.xpBoost),
				votePower: ToNumber(tier.vote_power || tier.votePower, fallback.votePower),
			};
		}

		return catalog;
	}

	function GetTierInfo(tier, data) {
		tier = NormalizeTierID(tier, data);
		return GetTierCatalog()[tier] || DEFAULT_SUPPORTER_TIER_CATALOG[0];
	}

	function GetTierData(playerID, tableData) {
		var data = tableData || CustomNetTables.GetTableValue("supporter_pass_player", playerID.toString()) || {};
		var tier = NormalizeTierID(data.tier_id || data.supporter_tier || data.donator_level || 0, data);
		var tierInfo = GetTierInfo(tier, data);

		return {
			tier: tier,
			name: data.tier_name || data.supporter_tier_name || tierInfo.name,
			color: IsEarthwardenSupporterData(data) ? DEFAULT_SUPPORTER_TIER_CATALOG[5].color : (data.tier_color || tierInfo.color),
			fragmentsPerMonth: ToNumber(data.tier_fragments || tierInfo.fragments, tierInfo.fragments),
			xpBoost: ToNumber(data.tier_xp_boost || data.xp_boost || tierInfo.xpBoost, tierInfo.xpBoost),
			votePower: Math.max(1, ToNumber(data.vote_power, tierInfo.votePower)),
		};
	}

	function GetPlayerData(playerID, options) {
		options = options || {};
		var tableData = options.tableData || CustomNetTables.GetTableValue("supporter_pass_player", playerID.toString()) || {};
		var tierData = GetTierData(playerID, tableData);
		var model = options.model || {};
		var entIndex = options.entIndex === undefined ? -1 : options.entIndex;

		var playerInfo = options.playerInfo || (typeof Game !== "undefined" && Game.GetPlayerInfo ? Game.GetPlayerInfo(playerID) : {});
		var heroName = model.hero || options.heroName || tableData.hero || "";
		if (!heroName && entIndex >= 0 && typeof Entities !== "undefined") {
			heroName = Entities.GetUnitName(entIndex);
		}
		if (!heroName && playerInfo) {
			heroName = playerInfo.player_selected_hero || "";
		}

		var accountXPMax = ToNumber(tableData.xhs_xp_max || model.accountXPMax || 0, 0);
		return {
			playerID: playerID,
			entIndex: entIndex,
			playerName: model.name || options.playerName || (playerInfo && playerInfo.player_name) || ("Player " + (playerID + 1)),
			heroName: heroName,
			localHeroName: model.heroLabel || options.localHeroName || LocalizeHeroName(heroName),
			tier: tierData.tier,
			tierName: tierData.name,
			tierColor: tierData.color,
			fragments: ToNumber(tableData.fragments || tableData.fragment_balance || model.fragments, 0),
			weeklyFragments: ToNumber(tableData.daily_fragments || tableData.daily_earned || tableData.weekly_fragments || tableData.weekly_earned || model.weeklyFragments, 0),
			weeklyCap: Math.max(ToNumber(tableData.daily_cap || tableData.weekly_cap || model.weeklyCap, DAILY_FRAGMENT_CAP), 1),
			seasonLevel: Math.max(1, ToNumber(tableData.season_level || tableData.Lvl || model.seasonLevel, 1)),
			seasonXP: ToNumber(tableData.season_xp || tableData.XP || model.seasonXP, 0),
			seasonXPMax: Math.max(ToNumber(tableData.season_xp_max || tableData.MaxXP || model.seasonXPMax, 1000), 1),
			accountLevel: ToNumber(tableData.xhs_account_level || tableData.account_level || tableData.legacy_level || model.accountLevel, 0),
			accountXPCurrent: ToNumber(tableData.xhs_xp_current || model.accountXPCurrent, 0),
			accountXPMax: accountXPMax,
			accountXPTotal: ToNumber(tableData.xhs_xp || tableData.xhs_xp_total || model.accountXPTotal, 0),
			winrate: tableData.winrate !== undefined ? tableData.winrate : model.winrate,
			fragmentsPerMonth: tierData.fragmentsPerMonth,
			xpBoost: tierData.xpBoost,
			votePower: tierData.votePower,
			heroLevel: ToNumber(model.level || options.heroLevel || (entIndex >= 0 && typeof Entities !== "undefined" ? Entities.GetLevel(entIndex) : 0), 0),
			ankhCharges: ToNumber(options.ankhCharges || model.ankhCharges, 0),
			equippedItems: NormalizeEquippedItems(tableData.equipped_items || tableData.loadout),
		};
	}

	function CreateStat(parent, id, labelText) {
		var stat = $.CreatePanel("Panel", parent, "XHSSupporterHoverStat_" + id);
		stat.AddClass("XHSSupporterHoverStat");

		var label = $.CreatePanel("Label", stat, "XHSSupporterHoverStatLabel_" + id);
		label.AddClass("XHSSupporterHoverStatLabel");
		label.text = labelText;

		var value = $.CreatePanel("Label", stat, "XHSSupporterHoverStatValue_" + id);
		value.AddClass("XHSSupporterHoverStatValue");
		value.text = "-";
	}

	function CreateMeter(parent, id, labelText) {
		var meter = $.CreatePanel("Panel", parent, "XHSSupporterHoverMeter_" + id);
		meter.AddClass("XHSSupporterHoverMeter");

		var row = $.CreatePanel("Panel", meter, "XHSSupporterHoverMeterRow_" + id);
		row.AddClass("XHSSupporterHoverMeterRow");

		var label = $.CreatePanel("Label", row, "XHSSupporterHoverMeterLabel_" + id);
		label.AddClass("XHSSupporterHoverMeterLabel");
		label.text = labelText;

		var value = $.CreatePanel("Label", row, "XHSSupporterHoverMeterValue_" + id);
		value.AddClass("XHSSupporterHoverMeterValue");
		value.text = "-";

		var track = $.CreatePanel("Panel", meter, "XHSSupporterHoverMeterTrack_" + id);
		track.AddClass("XHSSupporterHoverMeterTrack");

		var fill = $.CreatePanel("Panel", track, "XHSSupporterHoverMeterFill_" + id);
		fill.AddClass("XHSSupporterHoverMeterFill");
	}

	function ClearTierClasses(panel) {
		if (!panel) {
			return;
		}

		for (var tier = 0; tier <= 5; tier++) {
			panel.RemoveClass("XHSSupporterTier" + tier);
		}
	}

	function Create(parent, id, options) {
		options = options || {};
		var hover = $.CreatePanel("Panel", parent, "XHSSupporterHoverCard_" + id);
		hover.AddClass("XHSSupporterHoverCard");
		if (options.className) {
			hover.AddClass(options.className);
		}
		hover.AddClass(options.isRightSide ? "XHSSupporterHoverRight" : "XHSSupporterHoverLeft");
		hover.hittest = false;
		hover.hittestchildren = false;
		hover.SetAttributeInt("xhs_extra_stats", options.extraStats === true ? 1 : 0);

		var header = $.CreatePanel("Panel", hover, "XHSSupporterHoverHeader_" + id);
		header.AddClass("XHSSupporterHoverHeader");

		var heroFrame = $.CreatePanel("Panel", header, "XHSSupporterHoverHeroFrame_" + id);
		heroFrame.AddClass("XHSSupporterHoverHeroFrame");

		var heroImage = $.CreatePanel("DOTAHeroImage", heroFrame, "XHSSupporterHoverHeroImage_" + id);
		heroImage.AddClass("XHSSupporterHoverHeroImage");
		heroImage.heroimagestyle = "landscape";
		heroImage.scaling = "stretch-to-cover-preserve-aspect";
		heroImage.hittest = false;

		var headerCopy = $.CreatePanel("Panel", header, "XHSSupporterHoverHeaderCopy_" + id);
		headerCopy.AddClass("XHSSupporterHoverHeaderCopy");

		var eyebrow = $.CreatePanel("Label", headerCopy, "XHSSupporterHoverEyebrow_" + id);
		eyebrow.AddClass("XHSSupporterHoverEyebrow");
		eyebrow.text = "SUPPORTER PROFILE";

		var playerName = $.CreatePanel("Label", headerCopy, "XHSSupporterHoverPlayerName_" + id);
		playerName.AddClass("XHSSupporterHoverPlayerName");

		var heroName = $.CreatePanel("Label", headerCopy, "XHSSupporterHoverHeroName_" + id);
		heroName.AddClass("XHSSupporterHoverHeroName");

		var tierValue = $.CreatePanel("Label", hover, "XHSSupporterHoverTierValue_" + id);
		tierValue.AddClass("XHSSupporterHoverTierValue");

		var stats = $.CreatePanel("Panel", hover, "XHSSupporterHoverStats_" + id);
		stats.AddClass("XHSSupporterHoverStats");
		CreateStat(stats, "AccountLevel_" + id, "XHS Level");
		CreateStat(stats, "SeasonLevel_" + id, "Season Level");
		CreateStat(stats, "Fragments_" + id, "Fragments");
		CreateStat(stats, "Winrate_" + id, "Winrate");
		if (options.extraStats === true) {
			CreateStat(stats, "HeroLevel_" + id, "Hero Level");
			CreateStat(stats, "Ankh_" + id, "Ankh");
		}

		CreateMeter(hover, "XP_" + id, "Season XP");
		CreateMeter(hover, "AccountXP_" + id, "Global XP");
		CreateMeter(hover, "Weekly_" + id, "Daily Fragment Cap");

		var equipped = $.CreatePanel("Panel", hover, "XHSSupporterHoverEquipped_" + id);
		equipped.AddClass("XHSSupporterHoverEquipped");
		var equippedTitle = $.CreatePanel("Label", equipped, "XHSSupporterHoverEquippedTitle_" + id);
		equippedTitle.AddClass("XHSSupporterHoverEquippedTitle");
		equippedTitle.text = "EQUIPPED EFFECTS";
		var equippedGrid = $.CreatePanel("Panel", equipped, "XHSSupporterHoverEquippedGrid_" + id);
		equippedGrid.AddClass("XHSSupporterHoverEquippedGrid");

		var footer = $.CreatePanel("Label", hover, "XHSSupporterHoverFooter_" + id);
		footer.AddClass("XHSSupporterHoverFooter");
		return hover;
	}

	function Update(hover, id, data) {
		if (!hover || !data) {
			return;
		}

		ClearTierClasses(hover);
		hover.AddClass("XHSSupporterTier" + Clamp(data.tier, 0, 5));

		var heroImage = hover.FindChildTraverse("XHSSupporterHoverHeroImage_" + id);
		if (heroImage && data.heroName) {
			heroImage.heroname = data.heroName;
		}

		var identity = ResolveHoverIdentity(data);
		var identityLabel = hover.FindChildTraverse("XHSSupporterHoverPlayerName_" + id);
		var secondaryIdentityLabel = hover.FindChildTraverse("XHSSupporterHoverHeroName_" + id);
		if (identityLabel) {
			identityLabel.text = identity;
			identityLabel.style.visibility = identity ? "visible" : "collapse";
		}
		if (secondaryIdentityLabel) {
			// Only one identity type may ever be visible at once.
			secondaryIdentityLabel.text = "";
			secondaryIdentityLabel.style.visibility = "collapse";
		}
		SetChildText(hover, "XHSSupporterHoverTierValue_" + id, data.tierName);
		SetChildText(hover, "XHSSupporterHoverStatValue_AccountLevel_" + id, data.accountLevel > 0 ? data.accountLevel : "-");
		SetChildText(hover, "XHSSupporterHoverStatValue_SeasonLevel_" + id, data.seasonLevel);
		SetChildText(hover, "XHSSupporterHoverStatValue_Fragments_" + id, FormatNumber(data.fragments));
		SetChildText(hover, "XHSSupporterHoverStatValue_Winrate_" + id, FormatWinrate(data.winrate));
		if (hover.GetAttributeInt("xhs_extra_stats", 0) === 1) {
			SetChildText(hover, "XHSSupporterHoverStatValue_HeroLevel_" + id, data.heroLevel);
			SetChildText(hover, "XHSSupporterHoverStatValue_Ankh_" + id, data.ankhCharges);
		}
		SetChildText(hover, "XHSSupporterHoverMeterValue_XP_" + id, FormatNumber(data.seasonXP) + " / " + FormatNumber(data.seasonXPMax));
		SetChildText(hover, "XHSSupporterHoverMeterValue_AccountXP_" + id, FormatAccountXPSummary(data));
		SetChildText(hover, "XHSSupporterHoverMeterValue_Weekly_" + id, FormatNumber(data.weeklyFragments) + " / " + FormatNumber(data.weeklyCap));
		SetFillPercent(hover, "XHSSupporterHoverMeterFill_XP_" + id, data.seasonXP, data.seasonXPMax);
		SetFillPercent(hover, "XHSSupporterHoverMeterFill_AccountXP_" + id, data.accountXPCurrent, data.accountXPMax > 0 ? data.accountXPMax : 1);
		SetFillPercent(hover, "XHSSupporterHoverMeterFill_Weekly_" + id, data.weeklyFragments, data.weeklyCap);
		RenderEquippedItems(hover, id, data.equippedItems);

		if (ToNumber(data.tier, 0) > 0) {
			SetChildText(hover, "XHSSupporterHoverFooter_" + id, "+" + FormatNumber(data.fragmentsPerMonth) + " monthly fragments / +" + FormatNumber(data.xpBoost) + "% season XP / " + FormatVotePower(data.votePower));
		} else {
			SetChildText(hover, "XHSSupporterHoverFooter_" + id, "No active supporter tier");
		}
	}

	function PositionNearAnchor(anchor, hover, root, options) {
		options = options || {};
		if (!anchor || !hover || !root) {
			return;
		}

		var anchorPosition = GetPanelWindowPosition(anchor);
		var rootPosition = GetPanelWindowPosition(root);
		var anchorWidth = Number(anchor.actuallayoutwidth || anchor.desiredlayoutwidth || 0);
		var anchorHeight = Number(anchor.actuallayoutheight || anchor.desiredlayoutheight || 0);
		var hoverWidth = Number(hover.actuallayoutwidth || hover.desiredlayoutwidth || options.width || 322);
		var hoverHeight = Number(hover.actuallayoutheight || hover.desiredlayoutheight || options.height || 330);
		var rootWidth = Number(root.actuallayoutwidth || root.desiredlayoutwidth || 1920);
		var rootHeight = Number(root.actuallayoutheight || root.desiredlayoutheight || 1080);
		var gap = Number(options.gap || 10);

		var x = anchorPosition.x - rootPosition.x + anchorWidth + gap;
		var y = anchorPosition.y - rootPosition.y - 8;

		if (options.side === "left") {
			x = anchorPosition.x - rootPosition.x - hoverWidth - gap;
		} else if (x + hoverWidth > rootWidth - 8) {
			x = anchorPosition.x - rootPosition.x - hoverWidth - gap;
		}

		if (y < 8) {
			y = 8;
		}
		if (y + hoverHeight > rootHeight - 8) {
			y = Math.max(8, rootHeight - hoverHeight - 8);
		}

		hover.style.position = Math.round(x) + "px " + Math.round(y) + "px 0px";
	}

	function Show(anchor, hover) {
		if (anchor) {
			anchor.AddClass("XHSHoverVisible");
		}
		if (hover) {
			hover.AddClass("XHSHoverVisible");
		}
	}

	function Hide(anchor, hover) {
		if (anchor) {
			anchor.RemoveClass("XHSHoverVisible");
		}
		if (hover) {
			hover.RemoveClass("XHSHoverVisible");
		}
	}

	return {
		Create: Create,
		Update: Update,
		Show: Show,
		Hide: Hide,
		PositionNearAnchor: PositionNearAnchor,
		GetPlayerData: GetPlayerData,
		GetTierData: GetTierData,
		GetTierInfo: GetTierInfo,
		NormalizeTierID: NormalizeTierID,
	};
})();
