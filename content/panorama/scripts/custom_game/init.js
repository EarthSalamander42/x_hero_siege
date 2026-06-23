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

function OnXHSBuyTomeButtonPressed() {
	GameEvents.SendCustomGameEventToServer("xhs_buy_tomes", {});
}

function ShowXHSBuyTomeTooltip() {
	var button = GameUI.CustomUIConfig().XHSBuyTomeButton;
	if (button) {
		$.DispatchEvent("DOTAShowAbilityTooltip", button, "item_tome_small");
	}
}

function HideXHSBuyTomeTooltip() {
	var button = GameUI.CustomUIConfig().XHSBuyTomeButton;
	if (button) {
		$.DispatchEvent("DOTAHideAbilityTooltip", button);
	}
}

function FindXHSBuyTomeInitAnchor(parent) {
	var abilities = parent ? parent.FindChildTraverse("abilities") : null;
	if (abilities) {
		if (abilities.GetParent && abilities.GetParent() === parent) {
			return abilities;
		}

		var abilityParent = abilities.GetParent ? abilities.GetParent() : null;
		if (abilityParent && abilityParent.GetParent && abilityParent.GetParent() === parent) {
			return abilityParent;
		}
	}

	return null;
}

GameUI.CustomUIConfig().CreateXHSBuyTomeButton = function(parent) {
	parent = parent || center_block;
	if (!parent) {
		return null;
	}

	var existing = parent.FindChildTraverse("XHSBuyTomeButton");
	if (existing) {
		var existingAnchor = FindXHSBuyTomeInitAnchor(parent);
		if (existingAnchor && parent.MoveChildAfter) {
			if (existing.SetParent) {
				existing.SetParent(parent);
			}

			parent.MoveChildAfter(existing, existingAnchor);
		}

		GameUI.CustomUIConfig().XHSBuyTomeButton = existing;
		return existing;
	}

	var button = $.CreatePanel("Button", parent, "XHSBuyTomeButton");
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

	var anchor = FindXHSBuyTomeInitAnchor(parent);
	if (anchor && parent.MoveChildAfter) {
		if (button.SetParent) {
			button.SetParent(parent);
		}

		parent.MoveChildAfter(button, anchor);
	}

	GameUI.CustomUIConfig().XHSBuyTomeButton = button;
	return button;
};

GameUI.CustomUIConfig().CreateXHSBuyTomeButton(center_block);

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
