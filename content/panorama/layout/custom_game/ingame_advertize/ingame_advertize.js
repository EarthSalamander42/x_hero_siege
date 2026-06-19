const FIX_CG_ROOT = $.GetContextPanel();
const ADS_URLS = {
	website: "https://mods.frostrose-studio.com/watch",
	discord: "https://discord.frostrose-studio.com",
};
let adsDoNotShowAgain = false;

function OpenFixGame() {
	FIX_CG_ROOT.SetHasClass("show", true);
}

function CloseFixGame() {
	FIX_CG_ROOT.SetHasClass("show", false);
	// Backend persistence will consume this state later.
	FIX_CG_ROOT.SetAttributeInt("do_not_show_again", adsDoNotShowAgain ? 1 : 0);
}

function OnAdsDoNotShowToggle() {
	const checkbox = FIX_CG_ROOT.FindChildTraverse("Ads_DoNotShowAgain");
	adsDoNotShowAgain = !!(checkbox && checkbox.checked);
	FIX_CG_ROOT.SetAttributeInt("do_not_show_again", adsDoNotShowAgain ? 1 : 0);
}

function OpenAdsUrl(url) {
	if (typeof DOTADisplayURL === "function") {
		DOTADisplayURL(url);
		return;
	}

	if (typeof ExternalBrowserGoToURL === "function") {
		ExternalBrowserGoToURL(url);
		return;
	}

	$.DispatchEvent("ExternalBrowserGoToURL", url);
}

function OpenAdsWebsite() {
	OpenAdsUrl(ADS_URLS.website);
}

function OpenAdsDiscord() {
	OpenAdsUrl(ADS_URLS.discord);
}

(function () {
	OpenFixGame();

	const descriptionPanel = FIX_CG_ROOT.FindChildTraverse("Ads_Description");

	if (descriptionPanel) {
		descriptionPanel.SetDialogVariable("player_count_monthly", "3000");
	}

	FIX_CG_ROOT.SetDialogVariable("player_count_monthly", "3000");
})();
