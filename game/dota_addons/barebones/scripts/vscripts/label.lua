function GameMode:setPlayerHealthLabel( player )
	if PlayerResource:IsValidPlayerID(player:GetPlayerID()) then
		if not PlayerResource:IsBroadcaster(player:GetPlayerID()) then
			-- Cookies or X Hero Siege
			if PlayerResource:GetSteamAccountID(player:GetPlayerID()) == 54896080 or PlayerResource:GetSteamAccountID(player:GetPlayerID()) == 295458357 then
				if PlayerResource:GetPlayer(player:GetPlayerID()):GetAssignedHero() ~= nil then
					PlayerResource:GetPlayer(player:GetPlayerID()):GetAssignedHero():SetCustomHealthLabel("Mod Creator", 200, 45, 45)
				end
			end
			-- Mugiwara
			if PlayerResource:GetSteamAccountID(player:GetPlayerID()) == 61711140 then
				if PlayerResource:GetPlayer(player:GetPlayerID()):GetAssignedHero() ~= nil then
					PlayerResource:GetPlayer(player:GetPlayerID()):GetAssignedHero():SetCustomHealthLabel("Mod Graphist", 55, 55, 200)
				end
			end
			-- Beast
			if PlayerResource:GetSteamAccountID(player:GetPlayerID()) == 206464009 or PlayerResource:GetSteamAccountID(player:GetPlayerID()) == 146805680 then -- beast + VIP Donator Uktail
				if PlayerResource:GetPlayer(player:GetPlayerID()):GetAssignedHero() ~= nil then
					PlayerResource:GetPlayer(player:GetPlayerID()):GetAssignedHero():SetCustomHealthLabel("VIP Member", 45, 200, 45)
				end
			end
		end
	end
end
