-- Experience System
CustomNetTables:SetTableValue("game_options", "game_count", { value = 1 })

function Battlepass:GetTitleColorXP(title)
	if title == "Rookie" then
		return { 255, 255, 255 }
	elseif title == "Amateur" then
		return { 102, 204, 0 }
	elseif title == "Captain" then
		return { 76, 139, 202 }
	elseif title == "Warrior" then
		return { 0, 76, 153 }
	elseif title == "Commander" then
		return { 152, 95, 209 }
	elseif title == "General" then
		return { 70, 5, 135 }
	elseif title == "Master" then
		return { 250, 83, 83 }
	elseif title == "Epic" then
		return { 142, 12, 12 }
	elseif title == "Legendary" then
		return { 239, 188, 20 }
	elseif title == "Ancient" then
		return { 191, 149, 13 }
	elseif title == "Amphibian" then
		return { 0, 0, 102 }
	elseif title == "Icefrog" then
		return { 20, 86, 239 }
	else -- it's Firetoaaaaaaaaaaad!
		return { 199, 81, 2 }
	end
end

function Battlepass:GetPlayerInfoXP() -- yet it has too much useless loops, format later. Need to be loaded in game setup
	if not api.players then
		-- print("API not ready! Retry...")
		Timers:CreateTimer(1.0, function()
			Battlepass:GetPlayerInfoXP()
		end)

		return
	end

	print("API ready!")

	for player_id = 0, PlayerResource:GetPlayerCount() - 1 do
		local steamid = tostring(PlayerResource:GetSteamID(player_id))

		if api.players[steamid] then
			--			print("Player XP:", api.players[steamid].xp_in_level, api.players[steamid].xp_next_level, api.players[steamid].xp_level)

			local color = PLAYER_COLORS[player_id]

			local raw_donator_status = api:GetDonatorStatus(player_id)
			local donator_status = GetDonatorVisualStatus ~= nil and GetDonatorVisualStatus(raw_donator_status) or raw_donator_status
			local donator_color = DONATOR_COLOR[donator_status]

			if donator_color == nil then
				donator_color = DONATOR_COLOR[0]
			end

			local supporter_table = SupporterPass and SupporterPass:BuildPlayerTable(player_id) or nil
			if type(supporter_table) ~= "table" then
				supporter_table = CustomNetTables:GetTableValue("supporter_pass_player", tostring(player_id)) or {}
			end

			local season_xp = tonumber(supporter_table.season_xp or supporter_table.XP) or 0
			local season_xp_max = tonumber(supporter_table.season_xp_max or supporter_table.MaxXP) or 1000
			local season_level = tonumber(supporter_table.season_level or supporter_table.Lvl) or 1

			if season_xp_max <= 0 then
				season_xp_max = 1000
			end
			if season_level <= 0 then
				season_level = 1
			end

			supporter_table.XP = season_xp
			supporter_table.MaxXP = season_xp_max
			supporter_table.Lvl = season_level
			supporter_table.ply_color = rgbToHex(color)
			supporter_table.title = supporter_table.title or "Supporter Pass"
			supporter_table.title_color = supporter_table.title_color or "#9eb0c9"
			supporter_table.donator_level = donator_status
			supporter_table.raw_donator_level = raw_donator_status
			supporter_table.donator_color = rgbToHex(donator_color)
			supporter_table.tier_id = supporter_table.tier_id or 0
			supporter_table.tier_name = supporter_table.tier_name or "Free Player"
			supporter_table.tier_color = supporter_table.tier_color or "#7DB9D8"
			supporter_table.fragments = supporter_table.fragments or 0
			supporter_table.daily_fragments = supporter_table.daily_fragments or supporter_table.weekly_fragments or 0
			supporter_table.daily_cap = supporter_table.daily_cap or supporter_table.weekly_cap or 100
			supporter_table.weekly_fragments = supporter_table.daily_fragments
			supporter_table.weekly_cap = supporter_table.daily_cap
			supporter_table.monthly_fragments = supporter_table.monthly_fragments or 0
			supporter_table.xp_boost = supporter_table.xp_boost or 0
			supporter_table.season_level = season_level
			supporter_table.season_xp = season_xp
			supporter_table.season_xp_max = season_xp_max
			supporter_table.account_level = supporter_table.account_level or 0
			supporter_table.account_title = supporter_table.account_title or "Supporter Pass"
			if supporter_table.toggle_tag == nil then supporter_table.toggle_tag = api:GetPlayerTagEnabled(player_id) end
			if supporter_table.bp_rewards == nil then supporter_table.bp_rewards = api:GetPlayerBPRewardsEnabled(player_id) end
			if supporter_table.pass_rewards == nil then supporter_table.pass_rewards = api:GetPlayerBPRewardsEnabled(player_id) end
			if supporter_table.player_xp == nil then supporter_table.player_xp = api:GetPlayerXPEnabled(player_id) end
			supporter_table.winrate = supporter_table.winrate or api:GetPlayerSeasonalWinrate(player_id)
			if supporter_table.winrate_toggle == nil then supporter_table.winrate_toggle = api:GetPlayerWinrateShown(player_id) end
			if supporter_table.xhs_ingame_advertize_hidden == nil and api.GetPlayerIngameAdvertizeHidden ~= nil then supporter_table.xhs_ingame_advertize_hidden = api:GetPlayerIngameAdvertizeHidden(player_id) end
			supporter_table.XP_change = supporter_table.XP_change or 0
			supporter_table.ingame_tag = supporter_table.ingame_tag or api:GetPlayerIngameTag(player_id)
			supporter_table.achievements = supporter_table.achievements or api:GetPlayerAchievements(player_id)
			supporter_table.supporter_url = supporter_table.supporter_url or "https://www.patreon.com/bePatron?u=2533325"

			CustomNetTables:SetTableValue("supporter_pass_player", tostring(player_id), supporter_table)
		end
	end
end

function Battlepass:UpdatePlayerTable(player_id, key, value)
	local ply_table = CustomNetTables:GetTableValue("supporter_pass_player", tostring(player_id))
	if ply_table == nil then
		ply_table = {}
	end

	ply_table[key] = value

	CustomNetTables:SetTableValue("supporter_pass_player", tostring(player_id), ply_table)
end
