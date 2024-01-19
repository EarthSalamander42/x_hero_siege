function api:GenerateGameModeLeaderboard()
	local round_count = Rounds:GetRoundCount()
	--	print("Amount of rounds:", round_count)

	self:GetGameModeLeaderboard(1, round_count)
end

function api:GetGameModeLeaderboard(iRound, iMaxRound)
	if not self.pls_ranking then
		self.pls_ranking = {}
	end

	print("Iterate round " .. iRound .. "...")

	self:Request("pls_ranking", function(data)
		self.pls_ranking[iRound] = data.players

		-- if IsInToolsMode() then
		-- print("GameMode Leaderboard for round "..iRound..":", data.players)
		-- end

		print("Leaderboard round " .. iRound .. ": success!")
		iRound = iRound + 1

		if iRound < iMaxRound + 1 then
			self:GetGameModeLeaderboard(iRound, iMaxRound)
		else
			CustomNetTables:SetTableValue("game_options", "GameMode_leaderboard", self.pls_ranking)
		end
	end, function()
		print("Leaderboard round " .. iRound .. ": failure!!!")
		iRound = iRound + 1

		if iRound < iMaxRound + 1 then
			self:GetGameModeLeaderboard(iRound, iMaxRound)
		else
			CustomNetTables:SetTableValue("game_options", "GameMode_leaderboard", self.pls_ranking)
		end
	end, "POST", {
		round_range = iRound,
	})
end
