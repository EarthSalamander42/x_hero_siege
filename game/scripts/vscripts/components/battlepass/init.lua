-- Copyright (C) 2018  Frostrose Studio
-- Battlepass System

ListenToGameEvent('game_rules_state_change', function(keys)
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		_G.Battlepass = _G.Battlepass or class({})
		Battlepass.ENTITY_MODEL_OVERRIDE = {}

		require('components/battlepass/constants')
		require('components/battlepass/util')
		require('components/battlepass/donator_settings')
		require('components/battlepass/supporter_pass')
		require('components/battlepass/donator')
		require('components/battlepass/experience')
		require('libraries/wearables') -- this lib before items_game
		require('components/battlepass/keyvalues/items_game')

		if CUSTOM_GAME_TYPE ~= "PLS" then
			require('components/battlepass/' .. CUSTOM_GAME_TYPE .. '_rewards')
		end

		if CUSTOM_GAME_TYPE == "PLS" then
			require('components/battlepass/PW_rewards')
		end

		if Battlepass.Init then
			Battlepass:Init()
		end

		if SupporterPass and SupporterPass.Init then
			SupporterPass:Init()
		end

		Battlepass:GetPlayerInfoXP()
	end
end, nil)

ListenToGameEvent('npc_spawned', function(event)
	local npc = EntIndexToHScript(event.entindex)

	--	print(npc:GetUnitName())

	if npc.bp_init == true then return end
	npc.bp_init = true

	local donator_level = nil

	if npc.GetPlayerID then
		donator_level = api:GetDonatorStatus(npc:GetPlayerID())
	end

	local ply_table = CustomNetTables:GetTableValue("supporter_pass_player", tostring(npc:GetPlayerOwnerID()))
	if type(ply_table) == nil then ply_table = nil end

	if npc:IsIllusion() or string.find(npc:GetUnitName(), "npc_dota_lone_druid_bear") then
		if ply_table then
			if ply_table.toggle_tag ~= nil and ply_table.toggle_tag == 1 or ply_table.toggle_tag ~= nil and ply_table.toggle_tag == true then
				npc:SetupHealthBarLabel()
			end
		end

		return
	elseif npc:IsRealHero() then
		if ply_table and ply_table.bp_rewards == 1 then
			Battlepass:AddItemEffects(npc, ply_table)
		end

		local unit_name = npc:GetUnitName()

		if Battlepass.ENTITY_MODEL_OVERRIDE[unit_name] then
			npc:SetOriginalModel(Battlepass.ENTITY_MODEL_OVERRIDE[unit_name])
			npc:SetModel(Battlepass.ENTITY_MODEL_OVERRIDE[unit_name])
		end

		-- The commented out lines here are what I used to test in tools mode
		if api:IsDonator(npc:GetPlayerID()) and PlayerResource:GetConnectionState(npc:GetPlayerID()) ~= 1 or string.find(GetMapName(), "demo") then
			-- if api:IsDonator(npc:GetPlayerID()) and PlayerResource:GetConnectionState(npc:GetPlayerID()) ~= 1 or (IsInToolsMode()) then
			if ply_table then
				if ply_table.toggle_tag ~= nil and ply_table.toggle_tag == 1 or ply_table.toggle_tag ~= nil and ply_table.toggle_tag == true then
					npc:SetupHealthBarLabel()
				end
			end

			if api:GetDonatorStatus(npc:GetPlayerID()) == 10 then
				npc:SetOriginalModel("models/items/courier/kanyu_shark/kanyu_shark.vmdl")
				npc:CenterCameraOnEntity(npc, -1)
			else
				npc:AddNewModifier(npc, nil, "modifier_patreon_donator", {})

				if string.find(GetMapName(), "demo") then return end

				if api:GetDonatorStatus(npc:GetPlayerID()) ~= 6 then
					Timers:CreateTimer(1.5, function()
						local companion = api:GetPlayerCompanion(npc:GetPlayerID())

						if companion then
							Battlepass:DonatorCompanion(npc:GetPlayerID(), companion)
						end
					end)
				end
			end
		end
	end
end, nil)
