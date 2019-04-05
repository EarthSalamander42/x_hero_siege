"use strict";

(function () {

	GameEvents.Subscribe("end_game", EndScoreboard);
//	EndScoreboard();
})();

function RawTimetoGameTime(time) {
	var sec = Math.floor( time % 60 );
	var min = Math.floor( time / 60 );

	var timerText = "";
	timerText += min;
	timerText += ":";

	if ( sec < 10 )
	{
		timerText += "0";
	}
	timerText += sec;
	return timerText;
}

function EndScoreboard(args) {
//	$.Msg("Hey this is the end of the game!")
//	$.Msg(args)

	// Hide all other UI
	var MainPanel = $.GetContextPanel().GetParent().GetParent().GetParent().GetParent()
	MainPanel.FindChildTraverse("topbar").style.visibility = "collapse";
	MainPanel.FindChildTraverse("minimap_container").style.visibility = "collapse";
	MainPanel.FindChildTraverse("lower_hud").style.visibility = "collapse";
	// MainPanel.FindChildTraverse("HudChat").style.visibility = "collapse";
	MainPanel.FindChildTraverse("NetGraph").style.visibility = "collapse";
	MainPanel.FindChildTraverse("quickstats").style.visibility = "collapse";

	// Gather info
	if (args) {
		var serverInfo = args.info;
		var mapInfo = Game.GetMapInfo();
	}

	// player ids
	var radiantPlayerIds = Game.GetPlayerIDsOnTeam(DOTATeam_t.DOTA_TEAM_GOODGUYS);

	// Victory Info text
	var victoryMessage = "winning_team_name Victory!";
	var victoryMessageLabel = $("#es-victory-info-text");

	victoryMessage = victoryMessage.replace("winning_team_name", $.Localize(Game.GetTeamDetails(Game.GetGameWinner()).team_name));

	victoryMessageLabel.text = victoryMessage;

	// Load frequently used panels
	var teamsContainer = $("#es-teams");

	var panels = {
		radiant: $("#es-radiant"),
		radiantPlayers: $("#es-radiant-players"),
	};

	// the panorama xml file used for the player lines
	var playerXmlFile = "file://{resources}/layout/custom_game/xhs_end_screen_player.xml";

	// sort a player by merging results from server and using getplayerinfo  
	var loadPlayer = function (id) {
		var info = Game.GetPlayerInfo(id);
//		$.Msg(info)

		var result = null;
		for (var k in args.data.players) {
//			$.Msg(k)
			if (k == info.player_steamid) {
//				$.Msg(args.data.players[k])
				return {
					id: id,
					info: info,
					result: args.data.players[k]
				};
			}
		}

		return null;
	};

	// Load players = sort our data we got from above
	var radiantPlayers = [];

	$.Each(radiantPlayerIds, function (id) { radiantPlayers.push(loadPlayer(id)); });

	var createPanelForPlayer = function (player, parent) {
		// Create a new Panel for this player
//		$.Msg(player)
		var pp = $.CreatePanel("Panel", parent, "es-player-" + player.id);
		pp.AddClass("es-player");
		pp.BLoadLayout(playerXmlFile, false, false);
		var xp_bar = pp.FindChildrenWithClassTraverse("es-player-xp")

		var values = {
			name: pp.FindChildInLayoutFile("es-player-name"),
			avatar: pp.FindChildInLayoutFile("es-player-avatar"),
			hero: pp.FindChildInLayoutFile("es-player-hero"),
			desc: pp.FindChildInLayoutFile("es-player-desc"),
			kills: pp.FindChildInLayoutFile("es-player-k"),
			deaths: pp.FindChildInLayoutFile("es-player-d"),
			assists: pp.FindChildInLayoutFile("es-player-a"),
			imr: pp.FindChildInLayoutFile("es-player-imr"),
			gold: pp.FindChildInLayoutFile("es-player-gold"),
			level: pp.FindChildInLayoutFile("es-player-level"),
			xp: {
				bar: xp_bar,
				progress: pp.FindChildInLayoutFile("es-player-xp-progress"),
				level: pp.FindChildInLayoutFile("es-player-xp-level"),
				rank: pp.FindChildInLayoutFile("es-player-xp-rank"),
				rank_name: pp.FindChildInLayoutFile("es-player-xp-rank-name"),
				earned: pp.FindChildInLayoutFile("es-player-xp-earned"),
				booster: pp.FindChildInLayoutFile("es-player-xp-booster")
			}
		};

//		$.Msg(player.info.player_steamid);

		// Avatar + Hero Image
		values.avatar.steamid = player.info.player_steamid;
		values.hero.heroname = player.info.player_selected_hero;

		// Steam Name + Hero name
		values.name.text = player.info.player_name;
		values.desc.text = $.Localize(player.info.player_selected_hero);

		// Stats
		values.kills.text = player.info.player_kills;
		values.deaths.text = player.info.player_deaths;
		values.assists.text = player.info.player_assists;
		values.gold.text = player.info.player_gold;
		values.level.text = player.info.player_level;

		// XP
		var player_table = CustomNetTables.GetTableValue("player_table", player.id.toString());
		if (player_table) {
			values.xp.rank.text = Math.floor(player_table.XP) + "/" + Math.floor(player_table.MaxXP);
			values.xp.level.text = $.Localize("#battlepass_level") + player_table.Lvl;
			values.xp.rank_name.text = player_table.title;
			values.xp.rank_name.style.color = player_table.title_color;
			values.xp.booster.style.color = player_table.donator_color;
//			$.Msg(Math.floor(player_table.XP) / Math.floor(player_table.MaxXP))
//			if (Math.floor(player_table.XP) / Math.floor(player_table.MaxXP) >= 1) {
//				$.Msg("Level Up!")
//				values.xp.bar[0].AddClass("level-up");
//			}
			var progress = Math.round((100.0 * Math.floor(player_table.XP)) / Math.floor(player_table.MaxXP));
			values.xp.progress.style.width = progress + "%";
		}

//		$.Msg(player)
		if (player.result != null) {
			var xpDiff = Math.floor(player.result.xp_change);

//			$.Msg(xpDiff)

			if (xpDiff > 0) {
				values.xp.earned.text = "+" + xpDiff;
				values.xp.earned.AddClass("es-text-green");
			} else if (xpDiff == 0) {
				values.xp.earned.text = "0";
				values.xp.earned.AddClass("es-text-white");
			} else {
				values.xp.earned.text = new String(xpDiff);
				values.xp.earned.AddClass("es-text-red");
			}

			var multiplier = Math.round(player.result.xp_multiplier * 100.0);

			values.xp.booster.text = " (" + multiplier + "%)";
			values.xp.booster.style.color = "white";
		} else {
			values.xp.earned.text = "N/A";
		}
	};

	// Create the panels for the players
	$.Each(radiantPlayers, function (player) {
		createPanelForPlayer(player, panels.radiantPlayers);
	});

	// Set Team Score
	$("#es-team-score-radiant").text = new String(Game.GetTeamDetails(2).team_score);

	$("#es-game-time-text").text = RawTimetoGameTime(Game.GetDOTATime(false, false));
}
