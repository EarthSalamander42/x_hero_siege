ListenToGameEvent('game_rules_state_change', function(keys)
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		GetPlayerInfoXP()
		Battlepass:Init()
	elseif GameRules:State_Get() == DOTA_GAMERULES_STATE_HERO_SELECTION then
		InitDonatorTableJS()
	end
end, nil)

ListenToGameEvent('npc_spawned', function(event)
	local npc = EntIndexToHScript( event.entindex )

	local npc = EntIndexToHScript( event.entindex )
	local donator_level

	if npc.GetPlayerID then
		donator_level = api:GetDonatorStatus(npc:GetPlayerID())
	end

	if donator_level then
		if npc:IsRealHero() then
			if npc:GetUnitName() ~= "npc_dota_hero_wisp" then
				Battlepass:AddItemEffects(npc)
			end

			if not npc:HasAbility("holdout_vip") then
				if donator_level >= 1 and donator_level <= 9 then
					npc:SetCustomHealthLabel("#donator_tooltip_"..donator_level, DONATOR_COLOR[donator_level][1], DONATOR_COLOR[donator_level][2], DONATOR_COLOR[donator_level][3])

					local vip_ability = npc:AddAbility("holdout_vip")
					vip_ability:SetLevel(1)

					if donator_level ~= 6 then
						DonatorCompanion(npc:GetPlayerID())
					end
				end
			end
		else
			if string.find(npc:GetUnitName(), "npc_dota_lone_druid_bear") then
				npc:SetCustomHealthLabel("#donator_tooltip_"..donator_level, DONATOR_COLOR[donator_level][1], DONATOR_COLOR[donator_level][2], DONATOR_COLOR[donator_level][3])
			end
		end
	end
end, nil)
