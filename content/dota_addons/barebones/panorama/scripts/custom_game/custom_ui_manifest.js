"use strict"


function InitUI()
{
	$.Msg("Init UI!")
	var map_info = Game.GetMapInfo();
	if (map_info.map_display_name == "ranked_2v2") {
		$.GetContextPanel().FindChildTraverse("VoteColumn").style.visibility = "collapse";
	} else if (map_info.map_display_name == "x_hero_siege") {
		$.GetContextPanel().GetParent().GetParent().FindChildTraverse("CustomUIContainer").FindChildTraverse("TeamSelectContainer").style.visibility = "collapse";
//		$.GetContextPanel().GetParent().GetParent().FindChildTraverse("HUDElements").FindChildTraverse("topbar").FindChildTraverse("TopBarDireTeam").style.visibility = "collapse";
	}
}

(function(){
	InitUI()
})();
