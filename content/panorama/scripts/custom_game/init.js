// Turn off some default UI
//		GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_BAR, true );
//		GameUI.SetDefaultUIEnabled( DotaDefaultUIElement_t.DOTA_DEFAULT_UI_TOP_TIMEOFDAY, false );
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
//Use this line if you want to keep 4 ability minimum size, and only use 160 if you want ~2 ability min size
center_block.FindChildTraverse("AbilitiesAndStatBranch").style.minWidth = "386px";
//center_block.FindChildTraverse("AbilitiesAndStatBranch").style.minWidth = "160px";
center_block.FindChildTraverse("inventory_neutral_craft_holder").style.visibility = "collapse";

//Fuck Scanner UI
var minimap_container = hudElements.FindChildTraverse("minimap_container");
minimap_container.FindChildTraverse("GlyphScanContainer").style.visibility = "collapse";

//Fuck Roshan UI
minimap_container.FindChildTraverse("RoshanTimerContainer").style.visibility = "collapse";

center_block.FindChildTraverse("StatBranch").style.visibility = "collapse";

//you are not spawning the talent UI, fuck off (Disabling mouseover and onactivate)
//We also don't want to crash, valve plz
center_block.FindChildTraverse("StatBranch").SetPanelEvent("onmouseover", function(){});
center_block.FindChildTraverse("StatBranch").SetPanelEvent("onactivate", function(){});

center_block.FindChildrenWithClassTraverse("RootInnateDisplay")[0].style.visibility = "collapse";

//Fuck that levelup button
center_block.FindChildTraverse("level_stats_frame").style.visibility = "collapse";

center_block.FindChildTraverse("AghsStatusContainer").style.visibility = "collapse";

//Skin Killer - TopBar
var topbar = hudElements.FindChildTraverse("topbar");
topbar.FindChildTraverse("HUDSkinTopBarBG").style.visibility = "collapse";
for (var bg of topbar.FindChildrenWithClassTraverse("TopBarBackground")) {
	bg.style.opacity = "1";
	bg.style.backgroundImage = "none";
	bg.style.backgroundColor = "#000000da";
}

topbar.style.width = "685px";

var TopBarRadiantTeam = hudElements.FindChildTraverse("TopBarRadiantTeam");
TopBarRadiantTeam.style.width = "320px";
TopBarRadiantTeam.style.marginRight = "189px";

var topbarRadiantPlayers = hudElements.FindChildTraverse("TopBarRadiantPlayers");
topbarRadiantPlayers.style.width = "275px";

var topbarRadiantPlayersContainer = hudElements.FindChildTraverse("TopBarRadiantPlayersContainer");
topbarRadiantPlayersContainer.style.width = "275px";

var map_info = Game.GetMapInfo();
if (map_info.map_display_name == "x_hero_siege_8") {
	topbar.style.width = "1112px";

	//Top Bar Radiant
	var TopBarRadiantTeam = hudElements.FindChildTraverse("TopBarRadiantTeam");
	TopBarRadiantTeam.style.width = "1000px";
	TopBarRadiantTeam.style.marginLeft = "100px";
	TopBarRadiantTeam.style.marginRight = "0px";

	var topbarRadiantPlayers = hudElements.FindChildTraverse("TopBarRadiantPlayers");
	topbarRadiantPlayers.style.width = "504px";

	var topbarRadiantPlayersContainer = hudElements.FindChildTraverse("TopBarRadiantPlayersContainer");
	topbarRadiantPlayersContainer.style.width = "504px";

	var RadiantTeamContainer = hudElements.FindChildTraverse("RadiantTeamContainer");
	RadiantTeamContainer.style.height = "1000px";

	var RadiantBackground = TopBarRadiantTeam.GetChild(0);
	RadiantBackground.style.width = "1000px";
	RadiantBackground.style.marginRight = "50px";
}

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
var PreGame = Parent.FindChildTraverse("PreGame")

// setup modified vanilla HUD
SetupLoadingScreen();

function SetupLoadingScreen() {
	if (Parent.FindChildTraverse("GameAndPlayersRoot") == undefined || Parent.FindChildTraverse("TeamsList") == undefined || Parent.FindChildTraverse("TeamsListGroup") == undefined || Parent.FindChildTraverse("CancelAndUnlockButton") == undefined || Parent.FindChildTraverse("UnassignedPlayerPanel") == undefined || Parent.FindChildTraverse("ShuffleTeamAssignmentButton") == undefined)
		$.Schedule(0.25, SetupLoadingScreen);
	else {
		Parent.FindChildTraverse("GameAndPlayersRoot").style.backgroundColor = "rgba(50, 50, 50, 0.5)";
		Parent.FindChildTraverse("GameAndPlayersRoot").style.borderRadius = "3px";
		Parent.FindChildTraverse("GameAndPlayersRoot").style.boxShadow = "black 0px 0px 2px 2px";
		Parent.FindChildTraverse("TeamsList").style.visibility = "collapse";
		Parent.FindChildTraverse("TeamsListGroup").SetParent(Parent.FindChildTraverse("GameAndPlayersRoot"))
		Parent.FindChildTraverse("TeamsListGroup").style.verticalAlign = "top";
		Parent.FindChildTraverse("TeamsListGroup").style.width = "99%";
		if (Game.IsInToolsMode() == false) {
			Parent.FindChildTraverse("UnassignedPlayerPanel").style.visibility = "collapse";
			Parent.FindChildTraverse("CancelAndUnlockButton").style.visibility = "collapse";
			Parent.FindChildTraverse("ShuffleTeamAssignmentButton").style.visibility = "collapse";
		}
	}
}
