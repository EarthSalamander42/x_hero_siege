const FIX_CG_ROOT = $.GetContextPanel();

function OpenFixGame() {
	FIX_CG_ROOT.SetHasClass("show", true);
}
function CloseFixGame() {
	FIX_CG_ROOT.SetHasClass("show", false);
}

(function () {
	OpenFixGame();

	const descriptionPanel = FIX_CG_ROOT.FindChildTraverse("Ads_Description");

	if (descriptionPanel) {
		descriptionPanel.SetDialogVariable( "player_count_monthly", "3000" );
	}
})();
