"use strict";

var XHSSupporterPass = (function () {
	var SUPPORTER_URL = "https://www.patreon.com/bePatron?u=2533325";
	var DISCORD_URL = "https://discord.frostrose-studio.com/";
	var WEEKLY_FRAGMENT_CAP = 100;
	var LEGACY_FRAGMENT_CAP = 5000;
	var currentArmoryFilter = "All";
	var settingsOriginal = {};
	var settingsDraft = {};
	var settingsInitialized = false;
	var backToTopPollScheduled = false;

	var PAGE_IDS = {
		overview: "XHSPassOverviewPage",
		rewards: "XHSPassRewardsPage",
		shop: "XHSPassShopPage",
		armory: "XHSPassArmoryPage",
		leaderboards: "XHSPassLeaderboardsPage",
		settings: "XHSPassSettingsPage",
	};

	var TAB_IDS = {
		overview: "XHSPassTabOverview",
		rewards: "XHSPassTabRewards",
		shop: "XHSPassTabShop",
		armory: "XHSPassTabArmory",
		leaderboards: "XHSPassTabLeaderboards",
		settings: "XHSPassTabSettings",
	};

	var DEFAULT_TIERS = [
		{ id: 1, name: "Donator", price: "$2", color: "#45C46B", fragments: 150, xp_boost: 10 },
		{ id: 2, name: "Golden Donator", price: "$5", color: "#F2C94C", fragments: 400, xp_boost: 20 },
		{ id: 3, name: "Ember Donator", price: "$10", color: "#E4572E", fragments: 900, xp_boost: 30 },
		{ id: 4, name: "Stoneguard Donator", price: "$20", color: "#7B8794", fragments: 1800, xp_boost: 40 },
		{ id: 5, name: "Earthwarden Donator", price: "$50", color: "#2EC4B6", fragments: 1800, xp_boost: 40, prestige: true },
	];

	var DEFAULT_SHOP_ITEMS = [
		{ id: "companion_azure_wisp", name: "Azure Wisp Companion", type: "Companion", rarity: "Rare", price: 650, image: "battlepass/assets/btn_donator.png" },
		{ id: "companion_frostling", name: "Frostling Companion", type: "Companion", rarity: "Epic", price: 950, image: "battlepass/assets/btn_donator_icon.png" },
		{ id: "emblem_siege_blue", name: "Azure Siege Emblem", type: "Emblem", rarity: "Rare", price: 500, image: "battlepass/assets/btn_battlepass.png" },
		{ id: "emblem_warden", name: "Stoneguard Emblem", type: "Emblem", rarity: "Epic", price: 850, image: "battlepass/assets/btn_leaderboard_icon.png" },
		{ id: "effigy_castle_guard", name: "Castle Guard Effigy", type: "Effigy", rarity: "Epic", price: 900, image: "battlepass/assets/btn_leaderboard.png" },
		{ id: "effigy_muradin", name: "Muradin Event Effigy", type: "Effigy", rarity: "Mythical", price: 1400, image: "battlepass/levelup.png" },
		{ id: "bundle_blue_siege", name: "Blue Siege Bundle", type: "Bundle", rarity: "Mythical", price: 1600, image: "battlepass/battlepass_new.png" },
		{ id: "bundle_founder_cache", name: "Founder Cache", type: "Bundle", rarity: "Legendary", price: 2400, image: "battlepass/levelup2.png" },
	];

	var DEFAULT_REWARDS_FREE = [
		{ level: 1, name: "100 Fragments", type: "Fragments", rarity: "Common", image: "battlepass/levelup.png" },
		{ level: 3, name: "Azure Spray", type: "Emblem", rarity: "Common", image: "battlepass/assets/btn_battlepass_icon.png" },
		{ level: 5, name: "50 Fragments", type: "Fragments", rarity: "Common", image: "battlepass/levelup2.png" },
		{ level: 8, name: "Siege Banner", type: "Emblem", rarity: "Rare", image: "battlepass/assets/btn_battlepass.png" },
		{ level: 12, name: "Frost Trail", type: "Effect", rarity: "Rare", image: "battlepass/levelup3.png" },
		{ level: 16, name: "100 Fragments", type: "Fragments", rarity: "Common", image: "battlepass/levelup4.png" },
		{ level: 20, name: "Castle Guard Effigy", type: "Effigy", rarity: "Epic", image: "battlepass/assets/btn_leaderboard.png" },
	];

	var DEFAULT_REWARDS_PREMIUM = [
		{ level: 1, name: "Supporter Cache", type: "Bundle", rarity: "Rare", image: "battlepass/battlepass_new.png" },
		{ level: 2, name: "Azure Wisp", type: "Companion", rarity: "Rare", image: "battlepass/assets/btn_donator.png" },
		{ level: 4, name: "Hero Glow Blue", type: "Effect", rarity: "Epic", image: "battlepass/levelup5.png" },
		{ level: 7, name: "Stoneguard Emblem", type: "Emblem", rarity: "Epic", image: "battlepass/assets/btn_leaderboard_icon.png" },
		{ level: 10, name: "500 Fragments", type: "Fragments", rarity: "Rare", image: "battlepass/levelup6.png" },
		{ level: 14, name: "Frostling", type: "Companion", rarity: "Epic", image: "battlepass/assets/btn_donator_icon.png" },
		{ level: 18, name: "Muradin Event Effigy", type: "Effigy", rarity: "Mythical", image: "battlepass/levelup7.png" },
		{ level: 25, name: "Earthwarden Prestige", type: "Bundle", rarity: "Legendary", image: "battlepass/levelup8.png" },
	];

	var DEFAULT_ARMORY_ITEMS = [
		{ id: "armory_companion_azure_wisp", name: "Azure Wisp", type: "Companion", rarity: "Rare", price: 0, image: "battlepass/assets/btn_donator.png", equipped: true },
		{ id: "armory_companion_frostling", name: "Frostling", type: "Companion", rarity: "Epic", price: 0, image: "battlepass/assets/btn_donator_icon.png", equipped: false },
		{ id: "armory_emblem_siege", name: "Azure Siege", type: "Emblem", rarity: "Rare", price: 0, image: "battlepass/assets/btn_battlepass.png", equipped: true },
		{ id: "armory_emblem_stoneguard", name: "Stoneguard", type: "Emblem", rarity: "Epic", price: 0, image: "battlepass/assets/btn_leaderboard_icon.png", equipped: false },
		{ id: "armory_effigy_castle_guard", name: "Castle Guard", type: "Effigy", rarity: "Epic", price: 0, image: "battlepass/assets/btn_leaderboard.png", equipped: true },
		{ id: "armory_effect_frost_trail", name: "Frost Trail", type: "Effect", rarity: "Rare", price: 0, image: "battlepass/levelup3.png", equipped: false },
		{ id: "armory_bundle_founder", name: "Founder Cache", type: "Bundle", rarity: "Legendary", price: 0, image: "battlepass/battlepass_new.png", equipped: false },
	];

	var DEFAULT_LEADERBOARD_ENTRIES = [
		{ rank: 1, name: "Cookies", type: "Season XP", score: 182400 },
		{ rank: 2, name: "Ethan", type: "Season XP", score: 151900 },
		{ rank: 3, name: "Mason", type: "Season XP", score: 138250 },
		{ rank: 4, name: "Noah", type: "Winrate", score: 74 },
		{ rank: 5, name: "Lucas", type: "Hall of Fame", score: 12 },
		{ rank: 6, name: "Liam", type: "Fragments earned", score: 9200 },
		{ rank: 7, name: "Owen", type: "Boss clears", score: 48 },
	];

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

	function Localize(value) {
		if (!value) {
			return "";
		}

		var localized = $.Localize(value);
		return localized === value ? value.replace("#", "") : localized;
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

	function AsArray(value) {
		if (!value) {
			return [];
		}

		if (Object.prototype.toString.call(value) === "[object Array]") {
			return value;
		}

		if (value["1"] && Object.prototype.toString.call(value["1"]) === "[object Array]") {
			return value["1"];
		}

		var result = [];
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

	function ClearPanel(panel) {
		if (panel) {
			panel.RemoveAndDeleteChildren();
		}
	}

	function GetTable(tableName, keyName, fallbackValue) {
		return CustomNetTables.GetTableValue(tableName, keyName) || fallbackValue;
	}

	function GetLocalPlayerData() {
		var playerID = Players.GetLocalPlayer();
		var data = GetTable("supporter_pass_player", playerID.toString(), {}) || {};
		var info = Safe(function () { return Game.GetPlayerInfo(playerID); }, {});

		return {
			id: playerID,
			name: Safe(function () { return Players.GetPlayerName(playerID); }, info.player_name || "Player"),
			steamID: info.player_steamid || "",
			tier_id: ToNumber(data.tier_id || data.supporter_tier || 0, 0),
			tier_name: data.tier_name || "Free Player",
			tier_color: data.tier_color || "#7db9d8",
			fragments: ToNumber(data.fragments || data.fragment_balance, 0),
			weekly_fragments: ToNumber(data.weekly_fragments || data.weekly_earned, 0),
			weekly_cap: ToNumber(data.weekly_cap, WEEKLY_FRAGMENT_CAP),
			season_level: Math.max(1, ToNumber(data.season_level || data.Lvl, 1)),
			season_xp: ToNumber(data.season_xp || data.XP, 0),
			season_xp_max: Math.max(ToNumber(data.season_xp_max || data.MaxXP, 2000), 1),
			account_level: ToNumber(data.account_level || data.legacy_level, 0),
			legacy_fragments: Clamp(ToNumber(data.legacy_fragments, ToNumber(data.account_level || data.legacy_level, 0) * 50), 0, LEGACY_FRAGMENT_CAP),
			supporter_url: data.supporter_url || SUPPORTER_URL,
			raw: data,
		};
	}

	function GetTiers() {
		return AsArray(GetTable("supporter_pass_meta", "tiers", DEFAULT_TIERS));
	}

	function GetRewards(track) {
		var tableName = track === "premium" ? "supporter_pass_rewards_premium" : "supporter_pass_rewards_free";
		var rewards = AsArray(GetTable(tableName, "rewards", []));
		if (rewards.length > 0) {
			return rewards;
		}

		return track === "premium" ? DEFAULT_REWARDS_PREMIUM : DEFAULT_REWARDS_FREE;
	}

	function GetShopItems() {
		var data = GetTable("supporter_pass_shop", "featured", null);
		var items = AsArray(data && data.items ? data.items : data);
		return items.length > 0 ? items : DEFAULT_SHOP_ITEMS;
	}

	function GetArmoryItems() {
		var playerID = Players.GetLocalPlayer();
		var items = AsArray(GetTable("supporter_pass_armory", "rewards_" + playerID, []));
		return items.length > 0 ? items : DEFAULT_ARMORY_ITEMS;
	}

	function GetLeaderboardEntries() {
		var tables = CustomNetTables.GetAllTableValues ? CustomNetTables.GetAllTableValues("supporter_pass_leaderboards") : [];
		var entries = [];

		for (var i = 0; i < tables.length; i++) {
			if (tables[i] && tables[i].value) {
				entries.push(tables[i].value);
			}
		}

		return entries.length > 0 ? entries : DEFAULT_LEADERBOARD_ENTRIES;
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
		return {
			toggle_tag: IsTruthy(player.raw.toggle_tag, true),
			pass_rewards: player.raw.pass_rewards === 0 ? false : IsTruthy(player.raw.pass_rewards, true),
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

	function ToggleWindow(forceVisible) {
		var window = Panel("XHSSupporterPassWindow");
		if (!window) {
			return;
		}

		var visible = forceVisible;
		if (visible === undefined) {
			visible = !window.BHasClass("IsVisible");
		}

		window.SetHasClass("IsVisible", visible);
		if (visible) {
			RenderAll();
			UpdateBackToTopButton();
			ScheduleBackToTopPoll();
		} else {
			backToTopPollScheduled = false;
		}
	}

	function SwitchPage(pageName) {
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
			return Panel("XHSPassArmoryGrid");
		}
		if (activePage === "leaderboards") {
			return Panel("XHSPassLeaderboardRows");
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
		var avatar = Panel("XHSPassAvatar");
		if (avatar && player.steamID) {
			avatar.steamid = player.steamID;
		}

		SetText("XHSPassTierValue", player.tier_name);
		SetText("XHSPassFragmentsValue", FormatNumber(player.fragments));
		SetText("XHSPassWeeklyCapValue", FormatNumber(player.weekly_fragments) + " / " + FormatNumber(player.weekly_cap));
		SetText("XHSPassPlayerName", player.name);
		SetText("XHSPassPlayerTier", player.tier_name);
		SetText("XHSPassLevelLabel", "Season Level " + player.season_level);
		SetText("XHSPassXpLabel", FormatNumber(player.season_xp) + " / " + FormatNumber(player.season_xp_max) + " XP");
		SetText("XHSPassLegacyValue", FormatNumber(player.legacy_fragments) + " fragments");
		SetPercent(Panel("XHSPassXpProgress"), player.season_xp, player.season_xp_max);
		SetPercent(Panel("XHSPassWeeklyProgress"), player.weekly_fragments, player.weekly_cap);

		var tierLabel = Panel("XHSPassPlayerTier");
		if (tierLabel) {
			tierLabel.style.color = player.tier_color;
		}
	}

	function RenderTiers() {
		var parent = Panel("XHSPassTierRows");
		ClearPanel(parent);

		var tiers = GetTiers();
		for (var i = 0; i < tiers.length; i++) {
			var tier = tiers[i];
			var row = $.CreatePanel("Panel", parent, "");
			row.AddClass("XHSPassTierRow");

			var color = $.CreatePanel("Panel", row, "");
			color.AddClass("XHSPassTierColor");
			color.style.backgroundColor = tier.color || "#5ad0ff";

			var copy = $.CreatePanel("Panel", row, "");
			copy.AddClass("XHSPassTierCopy");

			var name = $.CreatePanel("Label", copy, "");
			name.AddClass("XHSPassTierName");
			name.text = tier.name || "Supporter";
			name.style.color = tier.color || "#f3fbff";

			var details = $.CreatePanel("Label", copy, "");
			details.AddClass("XHSPassTierDetails");
			details.text = FormatNumber(tier.fragments || 0) + " fragments/month - +" + FormatNumber(tier.xp_boost || 0) + "% XP - 3 companions, 1 emblem, 1 effigy";

			var price = $.CreatePanel("Label", row, "");
			price.AddClass("XHSPassTierPrice");
			price.text = tier.price || "";
		}
	}

	function CreateRewardCard(parent, reward) {
		var card = $.CreatePanel("Panel", parent, "");
		card.AddClass("XHSPassRewardCard");

		var image = $.CreatePanel("Panel", card, "");
		image.AddClass("XHSPassRewardImage");
		if (reward.image) {
			image.style.backgroundImage = 'url("file://{images}/custom_game/' + reward.image + '")';
		}

		var level = $.CreatePanel("Label", card, "");
		level.AddClass("XHSPassRewardLevel");
		level.text = "Level " + (reward.level || "-");

		var name = $.CreatePanel("Label", card, "");
		name.AddClass("XHSPassRewardName");
		name.text = Localize("#" + (reward.name || reward.item_name || "Reward"));

		var type = $.CreatePanel("Label", card, "");
		type.AddClass("XHSPassRewardType");
		type.text = reward.type || reward.item_type || "Reward";
	}

	function RenderRewardTrack(parent, title, rewards) {
		var track = $.CreatePanel("Panel", parent, "");
		track.AddClass("XHSPassRewardTrack");

		var titlePanel = $.CreatePanel("Label", track, "");
		titlePanel.AddClass("XHSPassRewardTrackTitle");
		titlePanel.text = title;

		var row = $.CreatePanel("Panel", track, "");
		row.AddClass("XHSPassRewardRow");

		if (!rewards || rewards.length === 0) {
			var empty = $.CreatePanel("Label", row, "");
			empty.AddClass("XHSPassEmptyBody");
			empty.text = "No rewards configured for this track yet.";
			return;
		}

		for (var i = 0; i < rewards.length; i++) {
			CreateRewardCard(row, rewards[i]);
		}
	}

	function RenderRewards() {
		var parent = Panel("XHSPassRewardTracks");
		ClearPanel(parent);

		if (!parent) {
			return;
		}

		RenderRewardTrack(parent, "Free Track", GetRewards("free"));
		RenderRewardTrack(parent, "Supporter Track", GetRewards("premium"));
	}

	function CreateShopCard(parent, item, player, mode) {
		var card = $.CreatePanel("Panel", parent, "");
		card.AddClass("XHSPassShopCard");

		var image = $.CreatePanel("Panel", card, "");
		image.AddClass("XHSPassShopImage");
		if (item.image) {
			image.style.backgroundImage = 'url("file://{images}/custom_game/' + item.image + '")';
		}

		var name = $.CreatePanel("Label", card, "");
		name.AddClass("XHSPassShopName");
		name.text = Localize("#" + (item.name || item.item_name || item.id || "Shop Item"));

		var meta = $.CreatePanel("Label", card, "");
		meta.AddClass("XHSPassShopMeta");
		meta.text = (item.rarity || "Common") + " " + (item.type || item.item_type || "Cosmetic");

		var price = $.CreatePanel("Label", card, "");
		price.AddClass("XHSPassShopPrice");
		if (mode === "armory") {
			price.text = item.equipped ? "Equipped" : "Unlocked";
		} else {
			price.text = FormatNumber(item.price || item.fragment_price || 0) + " fragments";
		}

		var button = $.CreatePanel("Button", card, "");
		button.AddClass("XHSPassShopButton");
		var canAfford = mode === "armory" || player.fragments >= ToNumber(item.price || item.fragment_price, 0);
		button.SetHasClass("IsLocked", !canAfford);
		button.SetPanelEvent("onactivate", function () {
			if (!canAfford) {
				Game.EmitSound("General.Cancel");
				return;
			}

			if (mode === "armory") {
				Game.EmitSound("General.ButtonClick");
				return;
			}

			GameEvents.SendCustomGameEventToServer("supporter_pass_buy_shop_item", {
				item_id: item.id || item.item_id,
			});
		});

		var label = $.CreatePanel("Label", button, "");
		label.text = mode === "armory" ? (item.equipped ? "Equipped" : "Equip") : (canAfford ? "Buy" : "Locked");
	}

	function RenderShop(player) {
		var parent = Panel("XHSPassShopGrid");
		ClearPanel(parent);

		var data = GetTable("supporter_pass_shop", "featured", {}) || {};
		var refresh = data.refresh_label || data.refresh_at || "Featured rotation";
		SetText("XHSPassShopRefresh", refresh.toString());

		var items = GetShopItems();
		if (items.length === 0) {
			CreateEmpty(parent, "Shop unavailable", "The Fragment Shop catalog has not been sent by the backend yet.");
			return;
		}

		for (var i = 0; i < items.length; i++) {
			CreateShopCard(parent, items[i], player, "shop");
		}
	}

	function GetArmoryFilters(items) {
		var filters = ["All"];
		for (var i = 0; i < items.length; i++) {
			var type = items[i].type || items[i].item_type || "Cosmetic";
			var exists = false;
			for (var j = 0; j < filters.length; j++) {
				if (filters[j] === type) {
					exists = true;
					break;
				}
			}
			if (!exists) {
				filters.push(type);
			}
		}
		return filters;
	}

	function RenderArmoryFilters(items, player) {
		var parent = Panel("XHSPassArmoryFilters");
		ClearPanel(parent);
		if (!parent) {
			return;
		}

		var filters = GetArmoryFilters(items);
		for (var i = 0; i < filters.length; i++) {
			(function (filterName) {
				var button = $.CreatePanel("Button", parent, "");
				button.AddClass("XHSPassArmoryFilterButton");
				button.SetHasClass("IsActive", currentArmoryFilter === filterName);
				button.SetPanelEvent("onactivate", function () {
					currentArmoryFilter = filterName;
					RenderArmory(player);
				});

				var label = $.CreatePanel("Label", button, "");
				label.text = filterName;
			})(filters[i]);
		}
	}

	function RenderArmory(player) {
		var parent = Panel("XHSPassArmoryGrid");
		ClearPanel(parent);

		var items = GetArmoryItems();
		RenderArmoryFilters(items, player);

		var filteredItems = [];
		for (var i = 0; i < items.length; i++) {
			var type = items[i].type || items[i].item_type || "Cosmetic";
			if (currentArmoryFilter === "All" || currentArmoryFilter === type) {
				filteredItems.push(items[i]);
			}
		}

		if (items.length === 0) {
			CreateEmpty(parent, "No equipped cosmetics", "Unlock cosmetics through the Supporter Pass or Fragment Shop, then equip them here.");
			return;
		}

		for (var j = 0; j < filteredItems.length; j++) {
			CreateShopCard(parent, filteredItems[j], player, "armory");
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

		bar.SetHasClass("IsDirty", !SettingsEqual(settingsOriginal, settingsDraft));
	}

	function CreateSettingRow(parent, key, title, description) {
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

		var checkbox = $.CreatePanel("DOTASettingsCheckbox", row, "XHSPassSetting_" + key);
		checkbox.AddClass("XHSPassSettingCheckbox");
		checkbox.checked = settingsDraft[key] === true;
		checkbox.SetPanelEvent("onactivate", function () {
			settingsDraft[key] = checkbox.checked === true;
			UpdateSettingsSaveBar();
		});
	}

	function RenderSettings(player) {
		var parent = Panel("XHSPassSettingsRows");
		ClearPanel(parent);

		if (!settingsInitialized) {
			settingsOriginal = BuildSettingsFromPlayer(player);
			settingsDraft = CopySettings(settingsOriginal);
			settingsInitialized = true;
		}

		CreateSettingRow(parent, "toggle_tag", "Supporter tag", "Display your supporter badge above your hero health bar.");
		CreateSettingRow(parent, "pass_rewards", "Cosmetic rewards", "Enable or disable equipped pass cosmetics in-game.");
		CreateSettingRow(parent, "player_xp", "XP visibility", "Show seasonal and account XP in social UI surfaces.");
		CreateSettingRow(parent, "winrate_toggle", "Winrate visibility", "Show your seasonal winrate in public profile surfaces.");
		UpdateSettingsSaveBar();
	}

	function RenderLeaderboards() {
		var parent = Panel("XHSPassLeaderboardRows");
		ClearPanel(parent);

		var entries = GetLeaderboardEntries();
		if (entries.length === 0) {
			CreateEmpty(parent, "No leaderboard data", "Leaderboard data is unavailable for this match or season.");
			return;
		}

		for (var i = 0; i < entries.length; i++) {
			var entry = entries[i];
			var row = $.CreatePanel("Panel", parent, "");
			row.AddClass("XHSPassLeaderboardRow");

			var copy = $.CreatePanel("Panel", row, "");
			copy.AddClass("XHSPassRowMain");

			var title = $.CreatePanel("Label", copy, "");
			title.AddClass("XHSPassRowTitle");
			title.text = entry.name || entry.player_name || "Player";

			var desc = $.CreatePanel("Label", copy, "");
			desc.AddClass("XHSPassRowDescription");
			desc.text = entry.type || "Season leaderboard";

			var value = $.CreatePanel("Label", row, "");
			value.AddClass("XHSPassRowValue");
			value.text = FormatNumber(entry.score || entry.xp || entry.value || 0);
		}
	}

	function RenderAll() {
		var player = GetLocalPlayerData();
		RenderHeader(player);
		RenderTiers();
		RenderRewards();
		RenderShop(player);
		RenderArmory(player);
		RenderLeaderboards();
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
			close.SetPanelEvent("onactivate", function () { ToggleWindow(false); });
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
				settingsOriginal = CopySettings(settingsDraft);
				UpdateSettingsSaveBar();
				Game.EmitSound("General.ButtonClick");
				if (GameEvents && GameEvents.SendCustomGameEventToServer) {
					GameEvents.SendCustomGameEventToServer("supporter_pass_update_settings", CopySettings(settingsDraft));
				}
			});
		}

		var cancelSettings = Panel("XHSPassSettingsCancelButton");
		if (cancelSettings) {
			cancelSettings.SetPanelEvent("onactivate", function () {
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
						tab.SetPanelEvent("onactivate", function () { SwitchPage(pageName); });
					}
				})(page);
			}
		}
	}

	function Init() {
		BindButtons();
		SwitchPage("overview");
		RenderAll();

		if (CustomNetTables.SubscribeNetTableListener) {
			CustomNetTables.SubscribeNetTableListener("supporter_pass_player", RenderAll);
			CustomNetTables.SubscribeNetTableListener("supporter_pass_shop", RenderAll);
			CustomNetTables.SubscribeNetTableListener("supporter_pass_meta", RenderAll);
		}
	}

	return {
		Init: Init,
		RenderAll: RenderAll,
		OpenDiscord: function () { OpenExternalURL(DISCORD_URL); },
	};
})();

(function () {
	$.Schedule(0.0, XHSSupporterPass.Init);
})();
