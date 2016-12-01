function GameMode:setPlayerHealthLabel( player )
	-- Cycle through any innate VIP's found, then give them Health Label
	if PlayerResource:IsValidPlayerID(player:GetPlayerID()) then
		if not PlayerResource:IsBroadcaster(player:GetPlayerID()) then
			-- Cookies or X Hero Siege
			for i = 1, #vip_members do
				if PlayerResource:GetSteamAccountID(player:GetPlayerID()) == mod_creator[i] then
					if PlayerResource:GetPlayer(player:GetPlayerID()):GetAssignedHero() ~= nil then
						PlayerResource:GetPlayer(player:GetPlayerID()):GetAssignedHero():SetCustomHealthLabel("Mod Creator", 200, 45, 45)
						local vip_ability = PlayerResource:GetPlayer(player:GetPlayerID()):GetAssignedHero():AddAbility("holdout_vip")
						vip_ability:SetLevel(1)
					end
				end
			end
			-- Baumi
			for i = 1, #vip_members do
				if PlayerResource:GetSteamAccountID(player:GetPlayerID()) == captain_baumi[i] then
					if PlayerResource:GetPlayer(player:GetPlayerID()):GetAssignedHero() ~= nil then
						PlayerResource:GetPlayer(player:GetPlayerID()):GetAssignedHero():SetCustomHealthLabel("Captain Baumi", 200, 45, 45)
						local vip_ability = PlayerResource:GetPlayer(player:GetPlayerID()):GetAssignedHero():AddAbility("holdout_vip")
						vip_ability:SetLevel(1)
					end
				end
			end
			-- Mugiwara
			for i = 1, #vip_members do
				if PlayerResource:GetSteamAccountID(player:GetPlayerID()) == mod_graphist[i] then
					if PlayerResource:GetPlayer(player:GetPlayerID()):GetAssignedHero() ~= nil then
						PlayerResource:GetPlayer(player:GetPlayerID()):GetAssignedHero():SetCustomHealthLabel("Mod Graphist", 55, 55, 200)
						local vip_ability = PlayerResource:GetPlayer(player:GetPlayerID()):GetAssignedHero():AddAbility("holdout_vip")
						vip_ability:SetLevel(1)
					end
				end
			end
			-- See VIP List on Top
			for i = 1, #vip_members do
				if PlayerResource:GetSteamAccountID(player:GetPlayerID()) == vip_members[i] then
					if PlayerResource:GetPlayer(player:GetPlayerID()):GetAssignedHero() ~= nil then
						PlayerResource:GetPlayer(player:GetPlayerID()):GetAssignedHero():SetCustomHealthLabel("VIP Member", 45, 200, 45)
						local vip_ability = PlayerResource:GetPlayer(player:GetPlayerID()):GetAssignedHero():AddAbility("holdout_vip")
						vip_ability:SetLevel(1)
					end
				end
			end
		end
	end
end
