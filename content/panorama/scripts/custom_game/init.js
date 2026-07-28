// Turn off some default UI
		GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_BAR, false );
		GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_TIMEOFDAY, false );
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_HEROES, false );
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_FLYOUT_SCOREBOARD, false );
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_QUICKBUY, true );
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_COURIER, false );
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_PROTECT, false );
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_SHOP_SUGGESTEDITEMS, false );
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_QUICK_STATS, false );
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_ENDGAME, false );
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_PREGAME_STRATEGYUI, false );
GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_KILLCAM, false );

GameUI.CustomUIConfig().team_colors = {}
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_GOODGUYS] = "#004080;";
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_BADGUYS ] = "#802020;";
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_3 ] = "#00b4c8;";
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_CUSTOM_4 ] = "#00963c;";

var hudElements = $.GetContextPanel().GetParent().GetParent().FindChildTraverse("HUDElements");
var center_block = hudElements.FindChildTraverse("lower_hud").FindChildTraverse("center_with_stats").FindChildTraverse("center_block");

function NormalizeXHSLocalizedText(text) {
	var value = text === undefined || text === null ? "" : String(text);
	var hasUtf8MojibakeMarker = value.indexOf("\u00C3") !== -1
		|| value.indexOf("\u00C2") !== -1
		|| value.indexOf("\u00E2") !== -1;

	if (!hasUtf8MojibakeMarker) {
		return value;
	}

	try {
		var decoded = decodeURIComponent(escape(value));
		return decoded.indexOf("\uFFFD") === -1 ? decoded : value;
	} catch (error) {
		return value;
	}
}

GameUI.CustomUIConfig().NormalizeXHSLocalizedText = NormalizeXHSLocalizedText;

function EnsureXHSBuyTomeDisabledOverlay(button) {
	if (!button) {
		return null;
	}

	var overlay = button.FindChildTraverse("XHSBuyTomeDisabledOverlay");
	if (!overlay) {
		overlay = $.CreatePanel("Panel", button, "XHSBuyTomeDisabledOverlay");
		overlay.AddClass("XHSBuyTomeDisabledOverlay");
		overlay.hittest = false;

		var mark = $.CreatePanel("Label", overlay, "XHSBuyTomeDisabledMark");
		mark.AddClass("XHSBuyTomeDisabledMark");
		mark.text = "!";
		mark.hittest = false;
	}

	return overlay;
}

function EnsureXHSBuyTomeAutoBuyHint(button) {
	if (!button) {
		return null;
	}

	var hint = button.FindChildTraverse("XHSBuyTomeAutoBuyHint");
	if (!hint) {
		hint = $.CreatePanel("Label", button, "XHSBuyTomeAutoBuyHint");
		hint.AddClass("XHSBuyTomeAutoBuyHint");
		hint.hittest = false;
	}

	var enabled = button.BHasClass("TomeAutoBuyEnabled");
	hint.text = enabled ? "AUTO" : "RMB";
	hint.SetHasClass("Enabled", enabled);
	return hint;
}

function ApplyXHSBuyTomeButtonStyle(button, options) {
	if (!button) {
		return;
	}

	options = options || {};
	var noTomes = options.noTomes !== undefined ? options.noTomes : button.BHasClass("NoTomes");
	var locked = options.locked !== undefined ? options.locked === true : button.BHasClass("TomePurchaseLocked");
	var hovered = options.hovered !== undefined ? options.hovered === true : button.BHasClass("XHSBuyTomeHovered");
	var autoBuy = options.autoBuy !== undefined ? options.autoBuy === true : button.BHasClass("TomeAutoBuyEnabled");
	button.SetHasClass("TomeAutoBuyEnabled", autoBuy);

	button.style.width = "34px";
	button.style.height = "34px";
	button.style.horizontalAlign = "left";
	button.style.verticalAlign = "bottom";
	button.style.marginLeft = "6px";
	button.style.marginTop = "0px";
	button.style.marginBottom = "14px";
	button.style.backgroundColor = "#0614219a";
	button.style.border = autoBuy ? "2px solid #ffd75e" : (locked ? "1px solid #e06a6aaa" : (hovered ? "1px solid #9fe8ff64" : "1px solid #7fd7ff2a"));
	button.style.borderRadius = "4px";
	button.style.boxShadow = autoBuy ? "fill #ffbf3870 0px 0px 9px 1px" : "fill #0000007a 0px 0px 5px 0px";
	button.style.opacity = autoBuy ? "1" : (locked ? "0.78" : (noTomes ? "0.42" : (hovered ? "1" : "0.9")));
	button.style.saturation = autoBuy ? "1" : (locked ? "0.25" : (noTomes ? "0.35" : "1"));
	button.style.brightness = autoBuy ? "1" : (locked ? (hovered ? "0.92" : "0.72") : (noTomes ? "0.75" : (hovered ? "1.55" : "1")));
	button.style.preTransformScale2d = "1";
	button.style.tooltipPosition = "top";
	button.style.zIndex = "1200";

	var icon = button.FindChildTraverse("XHSBuyTomeIcon");
	if (icon) {
		icon.style.width = "28px";
		icon.style.height = "28px";
		icon.style.horizontalAlign = "center";
		icon.style.verticalAlign = "center";
		icon.style.borderRadius = "3px";
		icon.style.opacity = "0.88";
	}

	var count = button.FindChildTraverse("XHSBuyTomeCount");
	if (count) {
		count.style.minWidth = "22px";
		count.style.height = "15px";
		count.style.horizontalAlign = "right";
		count.style.verticalAlign = "bottom";
		count.style.marginRight = "-5px";
		count.style.marginBottom = "-4px";
		count.style.padding = "0px 3px";
		count.style.backgroundColor = "#07131ee8";
		count.style.border = "1px solid #7fd7ff3c";
		count.style.borderRadius = "3px";
		count.style.color = "#d8f7ff";
		count.style.fontSize = "12px";
		count.style.fontWeight = "bold";
		count.style.textAlign = "center";
		count.style.textShadow = "0px 1px 2px 2 #000000";
		count.style.textOverflow = "shrink";
	}

	var autoBuyHint = EnsureXHSBuyTomeAutoBuyHint(button);
	if (autoBuyHint) {
		autoBuyHint.text = autoBuy ? "AUTO" : "RMB";
		autoBuyHint.SetHasClass("Enabled", autoBuy);
	}

	var overlay = EnsureXHSBuyTomeDisabledOverlay(button);
	if (overlay) {
		overlay.style.visibility = locked ? "visible" : "collapse";
		overlay.style.width = "100%";
		overlay.style.height = "100%";
		overlay.style.backgroundColor = "#3b0505b8";
		overlay.style.borderRadius = "3px";
		overlay.style.zIndex = "5";
	}

	var mark = overlay ? overlay.FindChildTraverse("XHSBuyTomeDisabledMark") : null;
	if (mark) {
		mark.style.horizontalAlign = "center";
		mark.style.verticalAlign = "center";
		mark.style.color = "#ffd6d6";
		mark.style.fontSize = "24px";
		mark.style.fontWeight = "bold";
		mark.style.textShadow = "0px 1px 3px 3 #000000";
	}
}

GameUI.CustomUIConfig().ApplyXHSBuyTomeButtonStyle = ApplyXHSBuyTomeButtonStyle;
GameUI.CustomUIConfig().EnsureXHSBuyTomeDisabledOverlay = EnsureXHSBuyTomeDisabledOverlay;
GameUI.CustomUIConfig().EnsureXHSBuyTomeAutoBuyHint = EnsureXHSBuyTomeAutoBuyHint;

function OnXHSBuyTomeButtonPressed() {
	var button = GameUI.CustomUIConfig().XHSBuyTomeButton;
	if (button && button.BHasClass("TomePurchaseLocked")) {
		return;
	}

	GameEvents.SendCustomGameEventToServer("xhs_buy_tomes", {});
}

function OnXHSBuyTomeAutoBuyToggle() {
	var button = GameUI.CustomUIConfig().XHSBuyTomeButton;
	if (button && button.BHasClass("XHSBuyTomeOtherPlayer")) {
		return;
	}

	GameEvents.SendCustomGameEventToServer("xhs_toggle_auto_buy_tomes", {});
}

function ShowXHSBuyTomeTooltip() {
	var button = GameUI.CustomUIConfig().XHSBuyTomeButton;
	if (button) {
		button.AddClass("XHSBuyTomeHovered");
		ApplyXHSBuyTomeButtonStyle(button, { hovered: true });
		var autoBuyEnabled = button.BHasClass("TomeAutoBuyEnabled");
		var controlHelp = autoBuyEnabled
			? "AUTO-BUY: ON\nRight-click to disable."
			: "AUTO-BUY: OFF\nRight-click to enable.";
		if (button.BHasClass("TomePurchaseLocked")) {
			var reasonToken = GameUI.CustomUIConfig().XHSBuyTomeLockReason || "#xhs_tome_lock_temporarily_disabled";
			var reason = NormalizeXHSLocalizedText($.Localize(reasonToken));
			$.DispatchEvent("DOTAShowTextTooltip", button, reason + "\n\n" + controlHelp);
		} else {
			$.DispatchEvent(
				"DOTAShowTextTooltip",
				button,
				"Tome of Stats (+50 all attributes)\nLeft-click to buy the maximum affordable.\n\n" + controlHelp
			);
		}
	}
}

function HideXHSBuyTomeTooltip() {
	var button = GameUI.CustomUIConfig().XHSBuyTomeButton;
	if (button) {
		button.RemoveClass("XHSBuyTomeHovered");
		ApplyXHSBuyTomeButtonStyle(button, { hovered: false });
		$.DispatchEvent("DOTAHideAbilityTooltip", button);
		$.DispatchEvent("DOTAHideTextTooltip", button);
	}
}

function FindXHSBuyTomeInitTarget(parent) {
	var abilities = parent ? parent.FindChildTraverse("abilities") : null;
	if (abilities) {
		var abilitiesParent = abilities.GetParent ? abilities.GetParent() : null;

		if (abilities.GetParent && abilities.GetParent() === parent) {
			return {
				parent: parent,
				anchor: abilities
			};
		}

		var abilityParent = abilitiesParent;
		if (abilityParent) {
			return {
				parent: abilityParent,
				anchor: abilities
			};
		}
	}

	return null;
}

GameUI.CustomUIConfig().CreateXHSBuyTomeButton = function(parent) {
	parent = parent || center_block;
	if (!parent) {
		return null;
	}

	var insertionTarget = FindXHSBuyTomeInitTarget(parent);
	var targetParent = insertionTarget ? insertionTarget.parent : parent;
	var anchor = insertionTarget ? insertionTarget.anchor : null;
	var existing = parent.FindChildTraverse("XHSBuyTomeButton");
	if (existing) {
		if (anchor && targetParent.MoveChildAfter) {
			if (existing.SetParent) {
				existing.SetParent(targetParent);
			}

			targetParent.MoveChildAfter(existing, anchor);
		}

		GameUI.CustomUIConfig().XHSBuyTomeButton = existing;
		existing.SetPanelEvent("onactivate", OnXHSBuyTomeButtonPressed);
		existing.SetPanelEvent("oncontextmenu", OnXHSBuyTomeAutoBuyToggle);
		existing.SetPanelEvent("onmouseover", ShowXHSBuyTomeTooltip);
		existing.SetPanelEvent("onmouseout", HideXHSBuyTomeTooltip);
		EnsureXHSBuyTomeAutoBuyHint(existing);
		EnsureXHSBuyTomeDisabledOverlay(existing);
		ApplyXHSBuyTomeButtonStyle(existing);
		return existing;
	}

	var button = $.CreatePanel("Button", targetParent, "XHSBuyTomeButton");
	button.AddClass("XHSBuyTomeButton");
	button.AddClass("NoTomes");
	button.AddClass("XHSInjectedIntoCenterBlock");
	button.hittest = true;
	button.SetPanelEvent("onactivate", OnXHSBuyTomeButtonPressed);
	button.SetPanelEvent("oncontextmenu", OnXHSBuyTomeAutoBuyToggle);
	button.SetPanelEvent("onmouseover", ShowXHSBuyTomeTooltip);
	button.SetPanelEvent("onmouseout", HideXHSBuyTomeTooltip);
	button.style.visibility = "collapse";

	var icon = $.CreatePanel("DOTAItemImage", button, "XHSBuyTomeIcon");
	icon.AddClass("XHSBuyTomeIcon");
	icon.itemname = "item_tome_small";
	icon.hittest = false;

	var count = $.CreatePanel("Label", button, "XHSBuyTomeCount");
	count.AddClass("XHSBuyTomeCount");
	count.text = "x0";
	count.hittest = false;
	EnsureXHSBuyTomeAutoBuyHint(button);
	EnsureXHSBuyTomeDisabledOverlay(button);
	ApplyXHSBuyTomeButtonStyle(button, { noTomes: true });

	if (anchor && targetParent.MoveChildAfter) {
		if (button.SetParent) {
			button.SetParent(targetParent);
		}

		targetParent.MoveChildAfter(button, anchor);
	}

	GameUI.CustomUIConfig().XHSBuyTomeButton = button;
	return button;
};

GameUI.CustomUIConfig().CreateXHSBuyTomeButton(center_block);

function OpenXHSExternalURL(url) {
	if (!url) {
		return;
	}

	if (typeof ExternalBrowserGoToURL === "function") {
		ExternalBrowserGoToURL(url);
		return;
	}

	try {
		$.DispatchEvent("ExternalBrowserGoToURL", url);
	} catch (err) {
		try {
			$.DispatchEvent("DOTADisplayURL", url);
		} catch (err2) {
			$.Msg("Unable to open external URL: " + url);
		}
	}
}

function ApplyXHSTopBarUtilityButtonStyle(button, options) {
	if (!button) {
		return;
	}

	options = options || {};
	var icon = options.icon || "";
	var iconId = options.iconId || "";
	var hovered = options.hovered === true || button.BHasClass("XHSTopBarUtilityHovered");

	button.style.width = "30px";
	button.style.height = "30px";
	button.style.minWidth = "30px";
	button.style.minHeight = "30px";
	button.style.horizontalAlign = "center";
	button.style.verticalAlign = "middle";
	button.style.marginLeft = "8px";
	button.style.marginRight = "8px";
	button.style.marginTop = "0px";
	button.style.marginBottom = "0px";
	button.style.backgroundColor = "#00000000";
	button.style.border = "0px solid #00000000";
	button.style.boxShadow = "none";
	button.style.backgroundImage = "none";
	button.style.backgroundRepeat = "no-repeat";
	button.style.backgroundSize = "100% 100%";
	button.style.backgroundPosition = "center";
	button.style.opacity = hovered ? "1.0" : "0.5";
	button.style.washColor = "#ccddffff";
	button.style.imgShadow = "0px 0px 3px 3 black";
	button.style.transitionProperty = "opacity";
	button.style.transitionDuration = "0.2s";
	button.style.zIndex = "5000";
	button.style.tooltipPosition = "bottom";

	var iconPanel = iconId ? button.FindChildTraverse(iconId) : null;
	if (!iconPanel && iconId) {
		iconPanel = $.CreatePanel("Image", button, iconId);
		iconPanel.hittest = false;
	}

	if (iconPanel) {
		if (iconPanel.SetImage) {
			iconPanel.SetImage(icon);
		} else {
			iconPanel.src = icon;
		}
		iconPanel.style.width = "26px";
		iconPanel.style.height = "26px";
		iconPanel.style.horizontalAlign = "center";
		iconPanel.style.verticalAlign = "middle";
		iconPanel.style.washColor = "#ffffffff";
		iconPanel.style.imgShadow = "0px 0px 3px 3 black";
		iconPanel.style.opacity = "1.0";
	}
}

function ApplyXHSReportBugButtonStyle(button) {
	ApplyXHSTopBarUtilityButtonStyle(button, {
		icon: "file://{images}/custom_game/hud/xhs_bug_report_icon.png",
		iconId: "XHSReportBugButtonIcon"
	});
}

function ApplyXHSSupporterPassButtonStyle(button) {
	ApplyXHSTopBarUtilityButtonStyle(button, {
		icon: "file://{images}/items/shield_of_invincibility.png",
		iconId: "XHSSupporterPassTopBarIcon"
	});

	var config = GameUI.CustomUIConfig ? GameUI.CustomUIConfig() : null;
	if (button && config && config.XHSSupporterPassVisible === true) {
		button.AddClass("XHSSupporterPassActive");
		button.style.opacity = "1.0";
		button.style.brightness = "1.32";
		button.style.preTransformScale2d = "1.04";
		button.style.backgroundColor = "#14364cf2";
		button.style.border = "1px solid #70d4ff";
		button.style.boxShadow = "fill #5ad0ff55 0px 0px 9px 0px";
	} else if (button) {
		button.RemoveClass("XHSSupporterPassActive");
		button.style.brightness = "1.0";
		button.style.preTransformScale2d = "1.0";
	}

	if (button && button.BHasClass("XHSSupporterPassAttention")) {
		button.style.opacity = "1.0";
		button.style.brightness = "1.45";
		button.style.preTransformScale2d = "1.08";
		button.style.imgShadow = "0px 0px 7px 3 #ffb34d";
	}
}

function ApplyXHSAdvertizeButtonStyle(button) {
	ApplyXHSTopBarUtilityButtonStyle(button, {
		icon: "file://{images}/custom_game/hud/xhs_advertize_icon.png",
		iconId: "XHSAdvertizeButtonIcon"
	});
}

function SetXHSTopBarUtilityButtonHover(button, styleFn, hovered) {
	if (!button || !styleFn) {
		return;
	}

	if (hovered) {
		button.AddClass("XHSTopBarUtilityHovered");
	} else {
		button.RemoveClass("XHSTopBarUtilityHovered");
	}

	styleFn(button);
}

function GetXHSButtonBar() {
	var panel = $.GetContextPanel();
	var safety = 0;
	while (panel && safety < 12) {
		var buttonBar = panel.FindChildTraverse ? panel.FindChildTraverse("ButtonBar") : null;
		if (buttonBar) {
			return buttonBar;
		}

		panel = panel.GetParent ? panel.GetParent() : null;
		safety++;
	}

	return null;
}

function GetXHSHudRoot() {
	var buttonBar = GetXHSButtonBar();
	if (buttonBar) {
		var panel = buttonBar;
		var safety = 0;
		while (panel && safety < 12) {
			if (panel.id === "Hud") {
				return panel;
			}

			panel = panel.GetParent ? panel.GetParent() : null;
			safety++;
		}
	}

	return $.GetContextPanel().GetParent ? $.GetContextPanel().GetParent() : $.GetContextPanel();
}

function FindXHSFlyoutScoreboardButton(buttonBar) {
	if (!buttonBar || !buttonBar.GetChildCount) {
		return null;
	}

	var firstOtherChild = null;
	for (var i = 0; i < buttonBar.GetChildCount(); i++) {
		var child = buttonBar.GetChild(i);
		if (!child || child.id === "XHSReportBugButton" || child.id === "XHSAdvertizeButton" || child.id === "XHSSupporterPassTopBarButton") {
			continue;
		}

		if (!firstOtherChild) {
			firstOtherChild = child;
		}

		var id = child && child.id ? child.id.toLowerCase() : "";

		if (id.indexOf("scoreboard") !== -1 || id.indexOf("flyout") !== -1) {
			return child;
		}
	}

	return firstOtherChild;
}

function FindXHSAdvertizeButton(buttonBar) {
	if (!buttonBar) {
		return null;
	}

	return buttonBar.FindChildTraverse("XHSAdvertizeButton");
}

function FindXHSReportBugButton(buttonBar) {
	if (!buttonBar) {
		return null;
	}

	return buttonBar.FindChildTraverse("XHSReportBugButton");
}

function PlaceXHSAdvertizeButton(button) {
	var buttonBar = GetXHSButtonBar();
	if (!buttonBar || !button) {
		return false;
	}

	if (button.SetParent && button.GetParent && button.GetParent() !== buttonBar) {
		button.SetParent(buttonBar);
	}

	var scoreboardButton = FindXHSFlyoutScoreboardButton(buttonBar);
	if (scoreboardButton && buttonBar.MoveChildAfter) {
		buttonBar.MoveChildAfter(button, scoreboardButton);
	}

	return true;
}

function PlaceXHSReportBugButton(button) {
	var buttonBar = GetXHSButtonBar();
	if (!buttonBar || !button) {
		return false;
	}

	if (button.SetParent && button.GetParent && button.GetParent() !== buttonBar) {
		button.SetParent(buttonBar);
	}

	var advertizeButton = FindXHSAdvertizeButton(buttonBar);
	if (advertizeButton && buttonBar.MoveChildAfter) {
		buttonBar.MoveChildAfter(button, advertizeButton);
	} else {
		var scoreboardButton = FindXHSFlyoutScoreboardButton(buttonBar);
		if (scoreboardButton && buttonBar.MoveChildAfter) {
			buttonBar.MoveChildAfter(button, scoreboardButton);
		}
	}

	return true;
}

function PlaceXHSSupporterPassButton(button) {
	var buttonBar = GetXHSButtonBar();
	if (!buttonBar || !button) {
		return false;
	}

	if (button.SetParent && button.GetParent && button.GetParent() !== buttonBar) {
		button.SetParent(buttonBar);
	}

	var reportButton = FindXHSReportBugButton(buttonBar);
	if (reportButton && buttonBar.MoveChildAfter) {
		buttonBar.MoveChildAfter(button, reportButton);
	} else {
		var advertizeButton = FindXHSAdvertizeButton(buttonBar);
		if (advertizeButton && buttonBar.MoveChildAfter) {
			buttonBar.MoveChildAfter(button, advertizeButton);
		}
	}

	return true;
}

function OpenXHSIngameAdvertizeFromButton(retriesLeft) {
	var config = GameUI.CustomUIConfig ? GameUI.CustomUIConfig() : null;
	if (config && typeof config.ToggleXHSIngameAdvertize === "function") {
		config.ToggleXHSIngameAdvertize();
		return;
	}

	if (config && typeof config.OpenXHSIngameAdvertize === "function") {
		config.OpenXHSIngameAdvertize();
		return;
	}

	if (config) {
		config.XHSOpenAdvertizeRequested = true;
	}

	if (retriesLeft > 0) {
		$.Schedule(0.25, function() {
			OpenXHSIngameAdvertizeFromButton(retriesLeft - 1);
		});
	}
}

function OpenXHSSupporterPassFromButton(retriesLeft) {
	var config = GameUI.CustomUIConfig ? GameUI.CustomUIConfig() : null;
	if (config && typeof config.ToggleXHSSupporterPass === "function") {
		config.ToggleXHSSupporterPass();
		return;
	}

	if (config && typeof config.OpenXHSSupporterPass === "function") {
		config.OpenXHSSupporterPass();
		return;
	}

	if (config) {
		config.XHSOpenSupporterPassRequested = true;
	}

	if (retriesLeft > 0) {
		$.Schedule(0.25, function() {
			OpenXHSSupporterPassFromButton(retriesLeft - 1);
		});
	}
}

function HideXHSSupporterPassCTA(button, popup) {
	if (button && (!button.IsValid || button.IsValid())) {
		button.RemoveClass("XHSSupporterPassAttention");
		ApplyXHSSupporterPassButtonStyle(button);
	}

	if (!popup || (popup.IsValid && !popup.IsValid())) {
		return;
	}

	popup.style.opacity = "0";
	popup.style.transform = "translateY( -7px )";
	$.Schedule(0.22, function() {
		if (popup && (!popup.IsValid || popup.IsValid())) {
			popup.style.visibility = "collapse";
		}
	});
}

function ShowXHSSupporterPassCTA(button, popup) {
	if (!button || !popup || (popup.IsValid && !popup.IsValid())) {
		return;
	}

	button.AddClass("XHSSupporterPassAttention");
	ApplyXHSSupporterPassButtonStyle(button);
	popup.style.visibility = "visible";
	$.Schedule(0.01, function() {
		if (popup && (!popup.IsValid || popup.IsValid())) {
			popup.style.opacity = "1";
			popup.style.transform = "translateY( 0px )";
		}
	});

	$.Schedule(10.0, function() {
		HideXHSSupporterPassCTA(button, popup);
	});
}

function CreateXHSSupporterPassCTA(button) {
	var existing = button.FindChildTraverse("XHSSupporterPassTopBarCTA");
	if (existing) {
		return existing;
	}

	button.style.overflow = "noclip";
	var buttonBar = GetXHSButtonBar();
	if (buttonBar) {
		buttonBar.style.overflow = "noclip";
	}

	var popup = $.CreatePanel("Panel", button, "XHSSupporterPassTopBarCTA");
	popup.hittest = true;
	popup.style.width = "286px";
	popup.style.height = "88px";
	popup.style.position = "-92px 38px 0px";
	popup.style.padding = "10px 12px 9px 12px";
	popup.style.flowChildren = "down";
	popup.style.backgroundColor = "gradient( linear, 0% 0%, 100% 100%, from( #251407fa ), color-stop( 0.58, #0d1b2dfa ), to( #05090ffa ) )";
	popup.style.border = "1px solid #ffbd62cc";
	popup.style.borderRadius = "5px";
	popup.style.boxShadow = "fill #000000cc 0px 0px 14px 0px, fill #ff9f302c 0px 0px 10px 0px";
	popup.style.opacity = "0";
	popup.style.transform = "translateY( -7px )";
	popup.style.transitionProperty = "opacity, transform, brightness";
	popup.style.transitionDuration = "0.2s";
	popup.style.visibility = "collapse";
	popup.style.zIndex = "9000";
	popup.SetPanelEvent("onactivate", function() {
		HideXHSSupporterPassCTA(button, popup);
		OpenXHSSupporterPassFromButton(8);
	});
	popup.SetPanelEvent("onmouseover", function() {
		popup.style.brightness = "1.16";
	});
	popup.SetPanelEvent("onmouseout", function() {
		popup.style.brightness = "1";
	});

	var title = $.CreatePanel("Label", popup, "XHSSupporterPassTopBarCTATitle");
	title.hittest = false;
	title.text = $.Localize("#xhs_sp_topbar_cta_title");
	title.style.width = "100%";
	title.style.color = "#ffe2a8";
	title.style.fontSize = "18px";
	title.style.fontWeight = "bold";
	title.style.textTransform = "uppercase";
	title.style.textShadow = "0px 1px 3px 2 #000000";

	var body = $.CreatePanel("Label", popup, "XHSSupporterPassTopBarCTABody");
	body.hittest = false;
	body.text = $.Localize("#xhs_sp_topbar_cta_body");
	body.style.width = "100%";
	body.style.marginTop = "3px";
	body.style.color = "#d8e8f7";
	body.style.fontSize = "14px";
	body.style.textShadow = "0px 1px 2px 2 #000000";

	var action = $.CreatePanel("Label", popup, "XHSSupporterPassTopBarCTAAction");
	action.hittest = false;
	action.text = $.Localize("#xhs_sp_topbar_cta_action");
	action.style.horizontalAlign = "right";
	action.style.marginTop = "4px";
	action.style.color = "#ffbd62";
	action.style.fontSize = "13px";
	action.style.fontWeight = "bold";
	action.style.textTransform = "uppercase";

	return popup;
}

function CreateXHSAdvertizeButton() {
	var root = GetXHSHudRoot();
	if (!root) {
		$.Schedule(0.5, CreateXHSAdvertizeButton);
		return;
	}

	var buttonBar = GetXHSButtonBar();
	if (!buttonBar) {
		$.Schedule(0.5, CreateXHSAdvertizeButton);
		return;
	}

	var existing = root.FindChildTraverse("XHSAdvertizeButton");
	if (existing) {
		PlaceXHSAdvertizeButton(existing);
		ApplyXHSAdvertizeButtonStyle(existing);
		return;
	}

	var button = $.CreatePanel("Button", buttonBar, "XHSAdvertizeButton");
	button.hittest = true;
	button.SetPanelEvent("onactivate", function() {
		OpenXHSIngameAdvertizeFromButton(8);
	});
	button.SetPanelEvent("onmouseover", function() {
		SetXHSTopBarUtilityButtonHover(button, ApplyXHSAdvertizeButtonStyle, true);
		$.DispatchEvent("UIShowTextTooltip", button, "Toggle advertize");
	});
	button.SetPanelEvent("onmouseout", function() {
		SetXHSTopBarUtilityButtonHover(button, ApplyXHSAdvertizeButtonStyle, false);
		$.DispatchEvent("UIHideTextTooltip", button);
	});

	var icon = $.CreatePanel("Image", button, "XHSAdvertizeButtonIcon");
	icon.hittest = false;

	PlaceXHSAdvertizeButton(button);
	ApplyXHSAdvertizeButtonStyle(button);
}

function CreateXHSReportBugButton() {
	var root = GetXHSHudRoot();
	if (!root) {
		$.Schedule(0.5, CreateXHSReportBugButton);
		return;
	}

	var buttonBar = GetXHSButtonBar();
	if (!buttonBar) {
		$.Schedule(0.5, CreateXHSReportBugButton);
		return;
	}

	var existing = root.FindChildTraverse("XHSReportBugButton");
	if (existing) {
		PlaceXHSReportBugButton(existing);
		ApplyXHSReportBugButtonStyle(existing);
		return;
	}

	var button = $.CreatePanel("Button", buttonBar, "XHSReportBugButton");
	button.hittest = true;
	button.SetPanelEvent("onactivate", function() {
		OpenXHSExternalURL("https://discord.frostrose-studio.com/");
	});
	button.SetPanelEvent("onmouseover", function() {
		SetXHSTopBarUtilityButtonHover(button, ApplyXHSReportBugButtonStyle, true);
		$.DispatchEvent("UIShowTextTooltip", button, "Report a bug");
	});
	button.SetPanelEvent("onmouseout", function() {
		SetXHSTopBarUtilityButtonHover(button, ApplyXHSReportBugButtonStyle, false);
		$.DispatchEvent("UIHideTextTooltip", button);
	});

	var icon = $.CreatePanel("Image", button, "XHSReportBugButtonIcon");
	icon.hittest = false;

	PlaceXHSReportBugButton(button);
	ApplyXHSReportBugButtonStyle(button);
}

function RegisterXHSSupporterPassButtonStateBridge() {
	var config = GameUI.CustomUIConfig ? GameUI.CustomUIConfig() : null;
	if (!config) {
		return;
	}
	config.UpdateXHSSupporterPassButtonState = function(visible) {
		config.XHSSupporterPassVisible = visible === true;
		var currentRoot = GetXHSHudRoot();
		var currentButton = currentRoot && currentRoot.FindChildTraverse("XHSSupporterPassTopBarButton");
		if (currentButton) {
			ApplyXHSSupporterPassButtonStyle(currentButton);
		}
	};
}

function CreateXHSSupporterPassButton() {
	var root = GetXHSHudRoot();
	if (!root) {
		$.Schedule(0.5, CreateXHSSupporterPassButton);
		return;
	}

	var buttonBar = GetXHSButtonBar();
	if (!buttonBar) {
		$.Schedule(0.5, CreateXHSSupporterPassButton);
		return;
	}
	RegisterXHSSupporterPassButtonStateBridge();

	var existing = root.FindChildTraverse("XHSSupporterPassTopBarButton");
	if (existing) {
		PlaceXHSSupporterPassButton(existing);
		ApplyXHSSupporterPassButtonStyle(existing);
		return;
	}

	var button = $.CreatePanel("Button", buttonBar, "XHSSupporterPassTopBarButton");
	button.hittest = true;
	button.SetPanelEvent("onactivate", function() {
		var popup = button.FindChildTraverse("XHSSupporterPassTopBarCTA");
		HideXHSSupporterPassCTA(button, popup);
		OpenXHSSupporterPassFromButton(8);
	});
	button.SetPanelEvent("onmouseover", function() {
		SetXHSTopBarUtilityButtonHover(button, ApplyXHSSupporterPassButtonStyle, true);
		$.DispatchEvent("UIShowTextTooltip", button, $.Localize("#xhs_sp_topbar_tooltip"));
	});
	button.SetPanelEvent("onmouseout", function() {
		SetXHSTopBarUtilityButtonHover(button, ApplyXHSSupporterPassButtonStyle, false);
		$.DispatchEvent("UIHideTextTooltip", button);
	});

	var icon = $.CreatePanel("Image", button, "XHSSupporterPassTopBarIcon");
	icon.hittest = false;

	PlaceXHSSupporterPassButton(button);
	ApplyXHSSupporterPassButtonStyle(button);
	var popup = CreateXHSSupporterPassCTA(button);
	$.Schedule(3.0, function() {
		ShowXHSSupporterPassCTA(button, popup);
	});
}

CreateXHSAdvertizeButton();
CreateXHSReportBugButton();
CreateXHSSupporterPassButton();

//Use this line if you want to keep 4 ability minimum size, and only use 160 if you want ~2 ability min size
center_block.FindChildTraverse("AbilitiesAndStatBranch").style.minWidth = "386px";
//center_block.FindChildTraverse("AbilitiesAndStatBranch").style.minWidth = "160px";
center_block.FindChildTraverse("inventory_neutral_craft_holder").style.visibility = "collapse";

var minimap_container = hudElements.FindChildTraverse("minimap_container");
minimap_container.FindChildTraverse("GlyphScanContainer").style.visibility = "collapse";

minimap_container.FindChildTraverse("RoshanTimerContainer").style.visibility = "collapse";
minimap_container.FindChildTraverse("TormentorTimerContainer").style.visibility = "collapse";

center_block.FindChildTraverse("StatBranch").style.visibility = "collapse";

//you are not spawning the talent UI, fuck off (Disabling mouseover and onactivate)
//We also don't want to crash, valve plz
center_block.FindChildTraverse("StatBranch").SetPanelEvent("onmouseover", function(){});
center_block.FindChildTraverse("StatBranch").SetPanelEvent("onactivate", function(){});

center_block.FindChildrenWithClassTraverse("RootInnateDisplay")[0].style.visibility = "collapse";

//Fuck that levelup button
center_block.FindChildTraverse("level_stats_frame").style.visibility = "collapse";

center_block.FindChildTraverse("AghsStatusContainer").style.visibility = "collapse";

//Skin Killer - Portrait
center_block.FindChildTraverse("HUDSkinPortrait").style.visibility = "collapse";
center_block.FindChildTraverse("HUDSkinXPBackground").style.visibility = "collapse";
center_block.FindChildTraverse("HUDSkinStatBranchBG").style.visibility = "collapse";
center_block.FindChildTraverse("HUDSkinStatBranchGlow").style.visibility = "collapse";
center_block.FindChildTraverse("unitname").style.transform = "translateY(0px)";
center_block.FindChildTraverse("unitname").style.width = "159px";
//Skin Killer - AbilityPanel
center_block.FindChildTraverse("HUDSkinAbilityContainerBG").style.visibility = "collapse";
center_block.FindChildTraverse("center_bg").style.backgroundImage = "url('s2r://panorama/images/hud/reborn/ability_bg_psd.vtex')";
//Skin Killer - inventory
center_block.FindChildTraverse("inventory").FindChildTraverse("HUDSkinInventoryBG").style.visibility = "collapse";
center_block.FindChildTraverse("inventory").FindChildTraverse("inventory_list_container").style.backgroundColor = "#ffffff00"; //0% opacity on colour

function HideXHSTpCharges(retryCount) {
	var tpCharges = center_block.FindChildTraverse("tpCharges");

	if (tpCharges) {
		tpCharges.style.opacity = "0";
	}

	if (retryCount > 0) {
		$.Schedule(0.5, function() {
			HideXHSTpCharges(retryCount - 1);
		});
	}
}

HideXHSTpCharges(20);

var g_XHSEnemyAbilityUpdateScheduled = false;
var g_XHSEnemyAbilityWasActive = false;
var g_XHSEnemyAbilitySelectionRefreshSerial = 0;

function ScheduleXHSEnemyAbilityTooltipRetry(image) {
	if (!image || !image._xhsTooltipHovered || image._xhsTooltipRetryScheduled) {
		return;
	}

	var retryCount = Number(image._xhsTooltipRetryCount) || 0;
	if (retryCount >= 10) {
		return;
	}

	image._xhsTooltipRetryScheduled = true;
	image._xhsTooltipRetryCount = retryCount + 1;
	$.Schedule(0.03, function() {
		image._xhsTooltipRetryScheduled = false;
		if (image._xhsTooltipHovered) {
			ShowXHSEnemyAbilityTooltip(image);
		}
	});
}

function ShowXHSEnemyAbilityTooltip(image) {
	if (!image) {
		return;
	}

	image._xhsTooltipHovered = true;
	var abilityName = image._xhsAbilityName || image.abilityname;
	var abilityLevel = Number(image._xhsAbilityLevel) || 0;
	var abilityEntityIndex = Number(image._xhsAbilityEntityIndex);

	// Read the entity again at hover time. The selection event can arrive one
	// frame before Valve updates the portrait HUD and its ability bindings.
	if (abilityEntityIndex >= 0) {
		var liveAbilityName = Abilities.GetAbilityName(abilityEntityIndex);
		var liveAbilityLevel = Abilities.GetLevel ?
			Math.max(0, Number(Abilities.GetLevel(abilityEntityIndex)) || 0) :
			abilityLevel;
		if (liveAbilityName) {
			abilityName = liveAbilityName;
			image._xhsAbilityName = liveAbilityName;
		}
		if (liveAbilityLevel > 0) {
			abilityLevel = liveAbilityLevel;
			image._xhsAbilityLevel = liveAbilityLevel;
		}
	}

	if (abilityName && abilityLevel > 0) {
		// Enemy ability levels are already networked through the ability entity.
		// Passing the level explicitly avoids Valve resolving the same slot on
		// the local hero, which produced "Level ?" and selected no KV value.
		image._xhsTooltipRetryCount = 0;
		image._xhsTooltipShownAbilityName = abilityName;
		image._xhsTooltipShownAbilityLevel = abilityLevel;
		image._xhsTooltipShownAbilityEntityIndex = abilityEntityIndex;
		$.DispatchEvent("DOTAShowAbilityTooltipForLevel", image, abilityName, abilityLevel);
		return;
	}

	// Do not let Valve build a partial tooltip with "Level ?". Keep the hover
	// alive and retry for a few frames while the newly selected unit networks.
	if (abilityName) {
		$.DispatchEvent("DOTAHideAbilityTooltip", image);
		ScheduleXHSEnemyAbilityTooltipRetry(image);
	}
}

function HideXHSEnemyAbilityTooltip(image) {
	if (image) {
		image._xhsTooltipHovered = false;
		image._xhsTooltipRetryCount = 0;
		image._xhsTooltipShownAbilityName = null;
		image._xhsTooltipShownAbilityLevel = null;
		image._xhsTooltipShownAbilityEntityIndex = null;
		$.DispatchEvent("DOTAHideAbilityTooltip", image);
	}
}

function GetXHSPortraitUnit() {
	if (Players.GetLocalPlayerPortraitUnit) {
		return Players.GetLocalPlayerPortraitUnit();
	}

	var selected = Players.GetSelectedEntities(Players.GetLocalPlayer());
	return selected && selected.length > 0 ? selected[0] : -1;
}

function IsXHSEnemyPortraitUnit(unit) {
	if (unit === undefined || unit === null || unit < 0) {
		return false;
	}

	var localPlayer = Players.GetLocalPlayer();
	var localTeam = Players.GetTeam(localPlayer);
	var unitTeam = Entities.GetTeamNumber(unit);
	return localTeam >= 0 && unitTeam >= 0 && localTeam !== unitTeam;
}

function GetXHSAbilityPanels() {
	var parent = center_block && center_block.FindChildTraverse("abilities");
	var panels = [];
	if (!parent) {
		return panels;
	}

	for (var i = 0; i < parent.GetChildCount(); i++) {
		var child = parent.GetChild(i);
		if (!child) {
			continue;
		}

		if (child.FindChildTraverse("Cooldown") ||
			child.FindChildTraverse("CooldownOverlay") ||
			child.FindChildTraverse("AbilityImage")) {
			panels.push(child);
		}
	}

	return panels;
}

function GetXHSDisplayedAbilities(unit) {
	var displayed = [];
	for (var slot = 0; slot < 24; slot++) {
		var ability = Entities.GetAbility(unit, slot);
		if (ability === undefined || ability === null || ability < 0) {
			continue;
		}
		if (Abilities.IsHidden && Abilities.IsHidden(ability)) {
			continue;
		}
		if (Abilities.IsAttributeBonus && Abilities.IsAttributeBonus(ability)) {
			continue;
		}
		displayed.push(ability);
	}
	return displayed;
}

function GetXHSPanelAbility(panel, panelIndex, unit, displayedAbilities) {
	var abilityImage = panel.FindChildTraverse("AbilityImage");
	var panelAbilityName = abilityImage && abilityImage.abilityname;

	if (panelAbilityName && Abilities.GetAbilityName) {
		for (var slot = 0; slot < 24; slot++) {
			var namedAbility = Entities.GetAbility(unit, slot);
			if (namedAbility >= 0 && Abilities.GetAbilityName(namedAbility) === panelAbilityName) {
				return namedAbility;
			}
		}
	}

	var idMatch = panel.id && panel.id.match(/(?:Ability|ability)(\d+)$/);
	if (idMatch) {
		var slottedAbility = Entities.GetAbility(unit, Number(idMatch[1]));
		if (slottedAbility >= 0) {
			return slottedAbility;
		}
	}

	return panelIndex < displayedAbilities.length ? displayedAbilities[panelIndex] : -1;
}

function GetXHSAbilityIconHost(panel) {
	// Use Valve's exact icon geometry. The custom Image itself is neutral and
	// the owner/level context is supplied separately for its tooltip.
	return panel.FindChildTraverse("AbilityImage") || panel;
}

function GetXHSCooldownLabelHost(panel) {
	// The stock radial cooldown mask is drawn by this panel. A label parented
	// to AbilityImage cannot render above it, regardless of its z-index.
	return panel.FindChildTraverse("Cooldown") || GetXHSAbilityIconHost(panel);
}

function PlaceXHSCooldownLabelAboveMask(panel, label) {
	if (!label) {
		return;
	}

	var host = label.GetParent();
	var stockOverlay = panel.FindChildTraverse("CooldownOverlay");
	if (host && stockOverlay && stockOverlay.GetParent() === host && host.MoveChildAfter) {
		host.MoveChildAfter(label, stockOverlay);
	}
}

function GetOrCreateXHSEnemyManaLabel(panel) {
	var iconContainer = GetXHSAbilityIconHost(panel);
	var container = panel.FindChildTraverse("XHSEnemyManaCostContainer");
	if (!container) {
		container = $.CreatePanel("Panel", iconContainer, "XHSEnemyManaCostContainer");
	} else if (container.GetParent() !== iconContainer) {
		container.SetParent(iconContainer);
	}

	var label = panel.FindChildTraverse("XHSEnemyManaCost");
	if (label && label.GetParent() === container) {
		return label;
	}
	if (label) {
		label.SetParent(container);
		return label;
	}

	container.hittest = false;
	container.style.horizontalAlign = "right";
	container.style.verticalAlign = "bottom";
	container.style.marginRight = "2px";
	container.style.marginBottom = "2px";
	container.style.padding = "0px 3px";
	container.style.minWidth = "18px";
	container.style.height = "18px";
	container.style.backgroundColor = "#071522ed";
	container.style.border = "1px solid #367aa5cc";
	container.style.borderRadius = "3px";
	container.style.boxShadow = "fill #000000aa 0px 0px 2px 1px";
	container.style.zIndex = "62";

	label = $.CreatePanel("Label", container, "XHSEnemyManaCost");
	label.hittest = false;
	label.AddClass("ManaCostLabel");
	label.style.horizontalAlign = "center";
	label.style.verticalAlign = "center";
	label.style.color = "#78c8ff";
	label.style.fontSize = "13px";
	label.style.fontWeight = "semi-bold";
	label.style.textShadow = "1px 1px 2px 2 #000000";
	return label;
}

function GetOrCreateXHSEnemyCooldownLabel(panel) {
	var cooldownContainer = GetXHSCooldownLabelHost(panel);
	var label = panel.FindChildTraverse("XHSEnemyCooldownTimer");
	if (label && label.GetParent() !== cooldownContainer) {
		label.SetParent(cooldownContainer);
	}

	if (!label) {
		label = $.CreatePanel("Label", cooldownContainer, "XHSEnemyCooldownTimer");
		label.hittest = false;
		label.AddClass("CooldownTimer");
		label.style.horizontalAlign = "center";
		label.style.verticalAlign = "center";
		label.style.color = "white";
		label.style.fontSize = "20px";
		label.style.fontWeight = "bold";
		label.style.textShadow = "1px 1px 3px 3 #000000";
	}

	label.style.zIndex = "80";
	PlaceXHSCooldownLabelAboveMask(panel, label);
	return label;
}

function GetOrCreateXHSEnemyCooldownOverlay(panel) {
	var overlay = panel.FindChildTraverse("XHSEnemyCooldownOverlay");
	var iconContainer = GetXHSAbilityIconHost(panel);
	if (overlay && overlay.GetParent() === iconContainer) {
		return overlay;
	}
	if (overlay) {
		overlay.SetParent(iconContainer);
		return overlay;
	}

	overlay = $.CreatePanel("Panel", iconContainer, "XHSEnemyCooldownOverlay");
	overlay.hittest = false;
	overlay.style.width = "100%";
	overlay.style.height = "100%";
	overlay.style.horizontalAlign = "center";
	overlay.style.verticalAlign = "center";
	overlay.style.backgroundColor = "#000000c8";
	overlay.style.zIndex = "60";
	return overlay;
}

function GetOrCreateXHSEnemyAbilityImage(panel) {
	var obsoleteVisualHost = panel.FindChildTraverse("XHSEnemyAbilityVisualHost");
	if (obsoleteVisualHost) {
		obsoleteVisualHost.visible = false;
	}
	var legacyAbilityImage = panel.FindChildTraverse("XHSEnemyAbilityImage");
	if (legacyAbilityImage) {
		// DOTAAbilityImage resolves learned/unlearned state against the local
		// hero's matching slot, so an enemy spell can become incorrectly gray.
		legacyAbilityImage.visible = false;
		legacyAbilityImage.hittest = false;
	}

	var enemyImage = panel.FindChildTraverse("XHSEnemyAbilityIcon");
	var iconContainer = GetXHSAbilityIconHost(panel);
	if (enemyImage && enemyImage.GetParent() === iconContainer) {
		enemyImage.hittest = true;
		enemyImage.SetPanelEvent("onmouseover", function() {
			ShowXHSEnemyAbilityTooltip(enemyImage);
		});
		enemyImage.SetPanelEvent("onmouseout", function() {
			HideXHSEnemyAbilityTooltip(enemyImage);
		});
		return enemyImage;
	}
	if (enemyImage) {
		enemyImage.SetParent(iconContainer);
		enemyImage.hittest = true;
		enemyImage.SetPanelEvent("onmouseover", function() {
			ShowXHSEnemyAbilityTooltip(enemyImage);
		});
		enemyImage.SetPanelEvent("onmouseout", function() {
			HideXHSEnemyAbilityTooltip(enemyImage);
		});
		return enemyImage;
	}

	// A plain Image renders the spell texture verbatim and has no implicit
	// dependency on the selected local hero or the local ability-bar slot.
	enemyImage = $.CreatePanel("Image", iconContainer, "XHSEnemyAbilityIcon");
	enemyImage.hittest = true;
	enemyImage.SetPanelEvent("onmouseover", function() {
		ShowXHSEnemyAbilityTooltip(enemyImage);
	});
	enemyImage.SetPanelEvent("onmouseout", function() {
		HideXHSEnemyAbilityTooltip(enemyImage);
	});
	enemyImage.style.width = "100%";
	enemyImage.style.height = "100%";
	enemyImage.style.horizontalAlign = "center";
	enemyImage.style.verticalAlign = "center";
	enemyImage.style.saturation = "1";
	enemyImage.style.brightness = "1";
	enemyImage.style.washColor = "#ffffffff";
	enemyImage.style.zIndex = "50";
	return enemyImage;
}

function SetXHSEnemyAbilityImageReveal(panel, reveal) {
	var abilityImage = panel.FindChildTraverse("AbilityImage");
	if (!abilityImage) {
		return;
	}

	if (reveal) {
		if (!abilityImage._xhsEnemyStyleCaptured) {
			abilityImage._xhsEnemyStyleCaptured = true;
			abilityImage._xhsOldSaturation = abilityImage.style.saturation;
			abilityImage._xhsOldBrightness = abilityImage.style.brightness;
			abilityImage._xhsOldWashColor = abilityImage.style.washColor;
			abilityImage._xhsOldOpacity = abilityImage.style.opacity;
		}
		abilityImage.style.saturation = "1";
		abilityImage.style.brightness = "1";
		abilityImage.style.washColor = "#ffffffff";
		abilityImage.style.opacity = "1";
	} else if (abilityImage._xhsEnemyStyleCaptured) {
		abilityImage.style.saturation = abilityImage._xhsOldSaturation || null;
		abilityImage.style.brightness = abilityImage._xhsOldBrightness || null;
		abilityImage.style.washColor = abilityImage._xhsOldWashColor || null;
		abilityImage.style.opacity = abilityImage._xhsOldOpacity || null;
		abilityImage._xhsEnemyStyleCaptured = false;
	}
}

function HideXHSEnemyAbilityPanel(panel) {
	SetXHSEnemyAbilityImageReveal(panel, false);
	var enemyImage = panel.FindChildTraverse("XHSEnemyAbilityIcon");
	var legacyAbilityImage = panel.FindChildTraverse("XHSEnemyAbilityImage");
	var manaContainer = panel.FindChildTraverse("XHSEnemyManaCostContainer");
	var manaLabel = panel.FindChildTraverse("XHSEnemyManaCost");
	var cooldownLabel = panel.FindChildTraverse("XHSEnemyCooldownTimer");
	var cooldownOverlay = panel.FindChildTraverse("XHSEnemyCooldownOverlay");
	if (manaContainer) {
		manaContainer.visible = false;
	}
	if (enemyImage) {
		enemyImage.visible = false;
	}
	if (legacyAbilityImage) {
		legacyAbilityImage.visible = false;
		legacyAbilityImage.hittest = false;
	}
	if (manaLabel && (!manaContainer || manaLabel.GetParent() !== manaContainer)) {
		manaLabel.visible = false;
		manaLabel.DeleteAsync(0);
	}
	if (cooldownLabel) {
		cooldownLabel.visible = false;
	}
	if (cooldownOverlay) {
		cooldownOverlay.visible = false;
	}
}

function HideXHSEnemyAbilityLabels() {
	var panels = GetXHSAbilityPanels();
	for (var i = 0; i < panels.length; i++) {
		HideXHSEnemyAbilityPanel(panels[i]);
	}
}

function RestoreXHSStockAbilityPanels(unit) {
	var panels = GetXHSAbilityPanels();
	var displayedAbilities = unit >= 0 ? GetXHSDisplayedAbilities(unit) : [];

	for (var i = 0; i < panels.length; i++) {
		var panel = panels[i];
		var ability = unit >= 0 ? GetXHSPanelAbility(panel, i, unit, displayedAbilities) : -1;
		var remaining = ability >= 0 ? Math.max(0, Abilities.GetCooldownTimeRemaining(ability) || 0) : 0;
		var inCooldown = remaining > 0.01;
		var cooldown = ability >= 0 ?
			(Abilities.GetCooldownLength ? Abilities.GetCooldownLength(ability) : Abilities.GetCooldown(ability)) :
			0;
		var cooldownPanel = panel.FindChildTraverse("Cooldown");
		var stockTimer = panel.FindChildTraverse("CooldownTimer");
		var stockOverlay = panel.FindChildTraverse("CooldownOverlay");

		panel.SetHasClass("in_cooldown", inCooldown);
		panel.SetHasClass("cooldown_ready", !inCooldown);
		panel.SetHasClass("can_cast_again", false);
		if (cooldownPanel) {
			// The previous enemy HUD implementation wrote directly to .visible.
			// Restore the native panels permanently; Valve's cooldown classes own
			// their actual visibility from this point onward.
			cooldownPanel.visible = true;
			cooldownPanel.style.visibility = null;
			cooldownPanel.style.opacity = null;
		}
		if (stockTimer) {
			// Its text binding was broken by the legacy enemy cooldown hack.
			// Keep it hidden: XHSEnemyCooldownTimer now owns the numeric label
			// for both friendly and enemy portrait units.
			stockTimer.visible = false;
			stockTimer.style.visibility = null;
			stockTimer.style.opacity = null;
		}
		if (stockOverlay) {
			stockOverlay.visible = true;
			stockOverlay.style.visibility = null;
			stockOverlay.style.opacity = null;
			stockOverlay.style.clip = null;
		}
	}
}

function UpdateXHSFriendlyCooldownLabels(unit) {
	if (unit === undefined || unit === null || unit < 0) {
		return;
	}

	var panels = GetXHSAbilityPanels();
	var displayedAbilities = GetXHSDisplayedAbilities(unit);
	for (var i = 0; i < panels.length; i++) {
		var panel = panels[i];
		var ability = GetXHSPanelAbility(panel, i, unit, displayedAbilities);
		var timer = GetOrCreateXHSEnemyCooldownLabel(panel);
		var stockTimer = panel.FindChildTraverse("CooldownTimer");

		if (stockTimer) {
			stockTimer.visible = false;
		}
		if (ability < 0) {
			timer.visible = false;
			continue;
		}

		var remaining = Math.max(0, Abilities.GetCooldownTimeRemaining(ability) || 0);
		var inCooldown = remaining > 0.01;
		timer.visible = inCooldown;
		timer.text = inCooldown ? String(Math.max(1, Math.ceil(remaining))) : "";
	}
}

function UpdateXHSEnemyAbilityPanel(panel, ability, ownerUnit) {
	if (ability === undefined || ability === null || ability < 0) {
		HideXHSEnemyAbilityPanel(panel);
		return;
	}

	var abilityName = Abilities.GetAbilityName(ability);
	var abilityLevel = Abilities.GetLevel ? Math.max(0, Number(Abilities.GetLevel(ability)) || 0) : 0;

	// Keep the replacement in Valve's original geometry without mutating the
	// native DOTAAbilityPanel. Changing its entity/level properties rebuilds
	// the stock panel and makes it steal hover events from this image.
	SetXHSEnemyAbilityImageReveal(panel, true);
	var enemyImage = GetOrCreateXHSEnemyAbilityImage(panel);
	var textureName = Abilities.GetAbilityTextureName ?
		Abilities.GetAbilityTextureName(ability) :
		abilityName;
	enemyImage.SetImage("s2r://panorama/images/spellicons/" + (textureName || abilityName) + "_png.vtex");
	enemyImage._xhsAbilityName = abilityName;
	enemyImage._xhsAbilityLevel = abilityLevel;
	enemyImage._xhsAbilityOwner = ownerUnit;
	enemyImage._xhsAbilityEntityIndex = ability;
	enemyImage.visible = true;

	if (enemyImage._xhsTooltipHovered &&
		abilityLevel > 0 &&
		(enemyImage._xhsTooltipShownAbilityName !== abilityName ||
			enemyImage._xhsTooltipShownAbilityLevel !== abilityLevel ||
			enemyImage._xhsTooltipShownAbilityEntityIndex !== ability)) {
		ShowXHSEnemyAbilityTooltip(enemyImage);
	}

	var cooldown = Abilities.GetCooldownLength ?
		Abilities.GetCooldownLength(ability) :
		Abilities.GetCooldown(ability);
	var remaining = Math.max(0, Abilities.GetCooldownTimeRemaining(ability) || 0);
	var inCooldown = remaining > 0.01;
	var overlay = GetOrCreateXHSEnemyCooldownOverlay(panel);
	var timer = GetOrCreateXHSEnemyCooldownLabel(panel);
	var cooldownPanel = panel.FindChildTraverse("Cooldown");
	var stockTimer = panel.FindChildTraverse("CooldownTimer");

	if (cooldownPanel) {
		// Enemy portrait panels can leave Valve's cooldown host collapsed. The
		// custom numeric timer lives inside it so it must remain renderable.
		cooldownPanel.visible = true;
		cooldownPanel.style.visibility = "visible";
		cooldownPanel.style.opacity = "1";
	}
	if (stockTimer) {
		stockTimer.visible = false;
	}
	if (timer) {
		timer.visible = inCooldown;
		timer.text = inCooldown ? String(Math.max(1, Math.ceil(remaining))) : "";
	}
	if (overlay) {
		overlay.visible = inCooldown;
		if (inCooldown) {
			var duration = Math.max(remaining, cooldown || 0.01);
			var remainingDegrees = Math.max(0, Math.min(360, 360 * remaining / duration));
			overlay.style.clip = "radial(50% 50%, 0deg, -" + remainingDegrees.toFixed(1) + "deg)";
		}
	}

	var manaCost = Abilities.GetEffectiveManaCost ?
		Abilities.GetEffectiveManaCost(ability) :
		Abilities.GetManaCost(ability);
	manaCost = Math.max(0, Number(manaCost) || 0);

	var manaLabel = GetOrCreateXHSEnemyManaLabel(panel);
	var manaContainer = panel.FindChildTraverse("XHSEnemyManaCostContainer");
	if (manaContainer) {
		manaContainer.visible = manaCost > 0;
	}
	manaLabel.text = manaCost > 0 ? String(Math.floor(manaCost + 0.5)) : "";
}

function UpdateXHSEnemyAbilityCooldowns() {
	var unit = GetXHSPortraitUnit();
	if (!IsXHSEnemyPortraitUnit(unit)) {
		if (g_XHSEnemyAbilityWasActive) {
			HideXHSEnemyAbilityLabels();
			RestoreXHSStockAbilityPanels(unit);
			g_XHSEnemyAbilityWasActive = false;
		}
		UpdateXHSFriendlyCooldownLabels(unit);
		return;
	}

	g_XHSEnemyAbilityWasActive = true;
	var panels = GetXHSAbilityPanels();
	var displayedAbilities = GetXHSDisplayedAbilities(unit);
	for (var i = 0; i < panels.length; i++) {
		var ability = GetXHSPanelAbility(panels[i], i, unit, displayedAbilities);
		UpdateXHSEnemyAbilityPanel(panels[i], ability, unit);
	}
}

function ShowEnemyAbilityCooldown() {
	UpdateXHSEnemyAbilityCooldowns();

	if (!g_XHSEnemyAbilityUpdateScheduled) {
		g_XHSEnemyAbilityUpdateScheduled = true;
		$.Schedule(0.1, function() {
			g_XHSEnemyAbilityUpdateScheduled = false;
			ShowEnemyAbilityCooldown();
		});
	}
}

function RefreshXHSEnemyAbilitiesAfterSelection() {
	var refreshSerial = ++g_XHSEnemyAbilitySelectionRefreshSerial;
	UpdateXHSEnemyAbilityCooldowns();

	// The event is sent before GetLocalPlayerPortraitUnit and the stock ability
	// panels are guaranteed to point at the new unit. Refresh on the next frame
	// and once more shortly after so the very first hover has complete data.
	$.Schedule(0.0, function() {
		if (refreshSerial === g_XHSEnemyAbilitySelectionRefreshSerial) {
			UpdateXHSEnemyAbilityCooldowns();
		}
	});
	$.Schedule(0.03, function() {
		if (refreshSerial === g_XHSEnemyAbilitySelectionRefreshSerial) {
			UpdateXHSEnemyAbilityCooldowns();
		}
	});
}

GameEvents.Subscribe("dota_player_update_selected_unit", RefreshXHSEnemyAbilitiesAfterSelection);
GameEvents.Subscribe("dota_player_update_query_unit", RefreshXHSEnemyAbilitiesAfterSelection);
HideXHSEnemyAbilityLabels();
RestoreXHSStockAbilityPanels(GetXHSPortraitUnit());
ShowEnemyAbilityCooldown();


//Skin Killer - minimap
hudElements.FindChildTraverse("HUDSkinMinimap").style.visibility = "collapse";

//Buff Bar
var BuffBar = hudElements.FindChildTraverse("lower_hud").FindChildTraverse("buffs")
BuffBar.style.width = "30%";
BuffBar.style.marginLeft = "38.5%";

//DeBuff Bar
var DeBuffBar = hudElements.FindChildTraverse("lower_hud").FindChildTraverse("debuffs")
DeBuffBar.style.width = "30%";
DeBuffBar.style.marginBottom = "45.5%";
DeBuffBar.style.marginRight = "31.5%";
DeBuffBar.style.flowChildren = "right";

var HeroDisplay = $.GetContextPanel().GetParent().GetParent().FindChildTraverse("HeroDisplay")
var HeroDisplayContainer = $.GetContextPanel().GetParent().GetParent().FindChildTraverse("HeroDisplay").FindChildTraverse("HeroDisplayRowContainer")
HeroDisplay.style.marginTop = "17.5%"
HeroDisplay.style.marginLeft = "1%"
HeroDisplay.style.width = "500px"
HeroDisplay.style.height = "76px"
HeroDisplayContainer.style.width = "500px"
HeroDisplayContainer.style.flowChildren = "right"

hudElements.FindChildTraverse("topbar").FindChildTraverse("GameTime").style.visibility = "collapse";

//Top Bar Dire
var TopBarDireTeam = hudElements.FindChildTraverse("TopBarDireTeam");
TopBarDireTeam.style.visibility = "collapse";

var Parent = $.GetContextPanel().GetParent().GetParent();

// Loading screen custom UI runs in an isolated DotaLoadingScreen context and
// cannot reliably reach these vanilla pregame panels. This override must stay
// in a HUD-context script such as init.js.
SetupLoadingScreen();

function SetupLoadingScreen() {
	var required_panels = [
		"GameAndPlayersRoot",
		"TeamsList",
		"TeamsListGroup",
		"CancelAndUnlockButton",
		"UnassignedPlayerPanel",
		"ShuffleTeamAssignmentButton",
	];

	for (var i = 0; i < required_panels.length; i++) {
		if (Parent.FindChildTraverse(required_panels[i]) == undefined) {
			$.Schedule(0.1, SetupLoadingScreen);
			return;
		}
	}

	Parent.FindChildTraverse("GameAndPlayersRoot").style.visibility = "collapse";
	Parent.FindChildTraverse("TeamsList").style.visibility = "collapse";
}
