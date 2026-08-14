var toggle = false
function OnHeroSelectionPressed() {
	if (toggle == false) {
		$("#PickScreen").style.visibility = "visible";
		toggle = true;
		return;
	}

	$("#PickScreen").style.visibility = "collapse";
	toggle = false;
}

function OnHeroSelected(hero) {
	ToggleCheatMenu();

	GameEvents.SendCustomGameEventToServer('demo_select_hero', {
		hero: hero
	});
}

function ToggleCheatMenu() {
	if ($.GetContextPanel().BHasClass("Minimized")) {
		$.GetContextPanel().RemoveClass("Minimized");	
	} else {
		$.GetContextPanel().AddClass("Minimized");
		if (toggle == true) {
			toggle = false;
		}

		$("#PickScreen").style.visibility = "collapse";
	}

//	$.GetContextPanel().ToggleClass('Minimized')
}

(function () {
	if (Game.GetMapInfo().map_display_name != "x_hero_siege_demo") {
		$.GetContextPanel().DeleteAsync(0);
		return;
	}

	var heroListRendered = false;

	function RenderHeroList(data) {
		if (heroListRendered || !data || !data.herolist) {
			return;
		}

		var heroes = Object.keys(data.herolist).sort();
		if (heroes.length === 0) {
			return;
		}

		heroes.forEach(function (hero) {
			var attributePanel = $("#" + data.herolist[hero]);
			if (!attributePanel) {
				return;
			}

			var new_hero = $.CreatePanel('Panel', attributePanel, hero);
			new_hero.AddClass("HeroContainer");
			new_hero.group = 'HeroChoises';
			new_hero.SetPanelEvent('onactivate', function () { OnHeroSelected(hero); });

			var new_hero_image = $.CreatePanel('DOTAHeroImage', new_hero, '');
			new_hero_image.hittest = false;
			new_hero_image.heroname = hero;
		});

		heroListRendered = true;
	}

	CustomNetTables.SubscribeNetTableListener('hero_selection', function (tableName, key, data) {
		if (key === 'herolist') {
			RenderHeroList(data);
		}
	});

	RenderHeroList(CustomNetTables.GetTableValue('hero_selection', 'herolist'));
})();
