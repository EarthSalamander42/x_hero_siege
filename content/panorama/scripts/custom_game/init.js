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

function ApplyXHSBuyTomeButtonStyle(button, options) {
	if (!button) {
		return;
	}

	options = options || {};
	var noTomes = options.noTomes !== undefined ? options.noTomes : button.BHasClass("NoTomes");
	var hovered = options.hovered !== undefined ? options.hovered === true : button.BHasClass("XHSBuyTomeHovered");

	button.style.width = "34px";
	button.style.height = "34px";
	button.style.horizontalAlign = "left";
	button.style.verticalAlign = "bottom";
	button.style.marginLeft = "6px";
	button.style.marginTop = "0px";
	button.style.marginBottom = "14px";
	button.style.backgroundColor = "#0614219a";
	button.style.border = hovered ? "1px solid #9fe8ff64" : "1px solid #7fd7ff2a";
	button.style.borderRadius = "4px";
	button.style.boxShadow = "fill #0000007a 0px 0px 5px 0px";
	button.style.opacity = noTomes ? "0.42" : (hovered ? "1" : "0.9");
	button.style.saturation = noTomes ? "0.35" : "1";
	button.style.brightness = noTomes ? "0.75" : (hovered ? "1.55" : "1");
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
}

GameUI.CustomUIConfig().ApplyXHSBuyTomeButtonStyle = ApplyXHSBuyTomeButtonStyle;

function OnXHSBuyTomeButtonPressed() {
	GameEvents.SendCustomGameEventToServer("xhs_buy_tomes", {});
}

function ShowXHSBuyTomeTooltip() {
	var button = GameUI.CustomUIConfig().XHSBuyTomeButton;
	if (button) {
		button.AddClass("XHSBuyTomeHovered");
		ApplyXHSBuyTomeButtonStyle(button, { hovered: true });
		$.DispatchEvent("DOTAShowAbilityTooltip", button, "item_tome_small");
	}
}

function HideXHSBuyTomeTooltip() {
	var button = GameUI.CustomUIConfig().XHSBuyTomeButton;
	if (button) {
		button.RemoveClass("XHSBuyTomeHovered");
		ApplyXHSBuyTomeButtonStyle(button, { hovered: false });
		$.DispatchEvent("DOTAHideAbilityTooltip", button);
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
		ApplyXHSBuyTomeButtonStyle(existing);
		return existing;
	}

	var button = $.CreatePanel("Button", targetParent, "XHSBuyTomeButton");
	button.AddClass("XHSBuyTomeButton");
	button.AddClass("NoTomes");
	button.AddClass("XHSInjectedIntoCenterBlock");
	button.hittest = true;
	button.SetPanelEvent("onactivate", OnXHSBuyTomeButtonPressed);
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
		if (!child || child.id === "XHSReportBugButton" || child.id === "XHSAdvertizeButton") {
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

CreateXHSAdvertizeButton();
CreateXHSReportBugButton();

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
	var inventory = center_block.FindChildTraverse("inventory");
	var tpCharges = inventory ? inventory.FindChildTraverse("tpCharges") : null;
	console.log(tpCharges);

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
