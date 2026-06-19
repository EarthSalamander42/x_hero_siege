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

			local donator_color = DONATOR_COLOR[api:GetDonatorStatus(player_id)]

			if donator_color == nil then
				donator_color = DONATOR_COLOR[0]
			end

			local supporter_table = SupporterPass and SupporterPass:BuildPlayerTable(player_id) or nil
			local current_xp = supporter_table and supporter_table.season_xp or 0
			local xp_in_level = current_xp
			local level = supporter_table and supporter_table.season_level or 0

			while xp_in_level > 2000 do
				xp_in_level = xp_in_level - 2000
			end

			CustomNetTables:SetTableValue("supporter_pass_player", tostring(player_id), {
				XP = xp_in_level,
				MaxXP = supporter_table and supporter_table.season_xp_max or 2000,
				Lvl = level,
				ply_color = rgbToHex(color),
				title = api.players[steamid].rank_title,
				title_color = rgbToHex(Battlepass:GetTitleColorXP(api.players[steamid].rank_title)),
				donator_level = api:GetDonatorStatus(player_id),
				donator_color = rgbToHex(donator_color),
				tier_id = supporter_table and supporter_table.tier_id or 0,
				tier_name = supporter_table and supporter_table.tier_name or "Free Player",
				tier_color = supporter_table and supporter_table.tier_color or "#7DB9D8",
				fragments = supporter_table and supporter_table.fragments or 0,
				weekly_fragments = supporter_table and supporter_table.weekly_fragments or 0,
				weekly_cap = supporter_table and supporter_table.weekly_cap or 100,
				monthly_fragments = supporter_table and supporter_table.monthly_fragments or 0,
				xp_boost = supporter_table and supporter_table.xp_boost or 0,
				season_level = level,
				season_xp = current_xp,
				season_xp_max = supporter_table and supporter_table.season_xp_max or 2000,
				account_level = supporter_table and supporter_table.account_level or 0,
				account_title = supporter_table and supporter_table.account_title or api.players[steamid].rank_title,
				legacy_fragments = supporter_table and supporter_table.legacy_fragments or 0,
				toggle_tag = api:GetPlayerTagEnabled(player_id),
				bp_rewards = api:GetPlayerBPRewardsEnabled(player_id),
				pass_rewards = api:GetPlayerBPRewardsEnabled(player_id),
				player_xp = api:GetPlayerXPEnabled(player_id),
				winrate = api:GetPlayerSeasonalWinrate(player_id),
				winrate_toggle = api:GetPlayerWinrateShown(player_id),
				XP_change = 0,
				ingame_tag = api:GetPlayerIngameTag(player_id),
				achievements = api:GetPlayerAchievements(player_id),
				supporter_url = supporter_table and supporter_table.supporter_url or "https://www.patreon.com/frostrose",
				-- mmr = api:GetPlayerMMR(player_id),
				-- mmr_title = api:GetPlayerRankMMR(player_id),
			})
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
