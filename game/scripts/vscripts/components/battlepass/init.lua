-- Copyright (C) 2018  Frostrose Studio
-- Battlepass System

-- Register developer candidate assets before the global Precache() pass.
require('components/battlepass/content_studio_assets')

local function LoadContentStudioRuntime()
	return require('components/battlepass/content_studio')
end

local function TryLateInitializeContentStudio()
	if IsInToolsMode == nil or not IsInToolsMode()
		or GetMapName == nil or string.lower(GetMapName() or "") ~= "x_hero_siege_demo"
		or GameRules == nil or GameRules.State_Get == nil then
		return false
	end
	local state = GameRules:State_Get()
	if state == nil or state < DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP
		or (DOTA_GAMERULES_STATE_POST_GAME ~= nil and state >= DOTA_GAMERULES_STATE_POST_GAME) then
		return false
	end
	if Battlepass == nil or Battlepass.ApplySupporterDevTestItem == nil
		or Battlepass.CleanupSupporterDevTest == nil then
		print("[Content Studio] Lua was reloaded after setup without live Battlepass adapters; reload the demo map fully.")
		return false
	end
	local ok, result = pcall(LoadContentStudioRuntime)
	if not ok then
		print("[Content Studio] Late runtime initialization failed; reload the demo map fully: " .. tostring(result))
		return false
	end
	print("[Content Studio] Late runtime initialization ready in Tools demo.")
	return true
end

local function IsPersistentBattlepassPlayer(playerID)
	playerID = tonumber(playerID)
	if playerID == nil or playerID < 0 or not PlayerResource:IsValidPlayerID(playerID) then
		return false
	end
	if IsXHSPersistentPlayerID ~= nil then
		return IsXHSPersistentPlayerID(playerID)
	end
	if PlayerResource.IsFakeClient ~= nil then
		return not PlayerResource:IsFakeClient(playerID)
	end
	return true
end

local function IsBattlepassCosmeticBot(playerID)
	playerID = tonumber(playerID)
	if playerID == nil or playerID < 0 then return false end
	if Battlepass ~= nil and Battlepass.IsSupporterBotPlayerID ~= nil then
		return Battlepass:IsSupporterBotPlayerID(playerID)
	end
	if IsXHSBotPlayerID ~= nil then
		local ok, isBot = pcall(IsXHSBotPlayerID, playerID)
		if ok and isBot == true then return true end
	end
	if PlayerResource.IsFakeClient ~= nil and PlayerResource:IsValidPlayerID(playerID) then
		local ok, isBot = pcall(function()
			return PlayerResource:IsFakeClient(playerID)
		end)
		return ok and isBot == true
	end
	return false
end

ListenToGameEvent('game_rules_state_change', function(keys)
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		_G.Battlepass = _G.Battlepass or class({})
		Battlepass.ENTITY_MODEL_OVERRIDE = {}

		require('components/battlepass/constants')
		require('components/battlepass/util')
		require('components/battlepass/supporter_pass')
		require('components/battlepass/supporter_pass_2026')
		require('components/battlepass/regen_aura')
		require('components/battlepass/recovery_effects')
		require('components/battlepass/immolation')
		LoadContentStudioRuntime()
		-- Supporter High Fives are deferred to 4.1. Keep their implementation in
		-- the repository, but do not load it or expose its ability in 4.0.
		require('components/battlepass/donator')
		require('components/battlepass/experience')
		require('libraries/wearables') -- this lib before items_game
		require('components/battlepass/keyvalues/items_game')

		if SupporterPass2026 and SupporterPass2026.Init then
			SupporterPass2026:Init()
		end

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

ListenToGameEvent("entity_killed", function(event)
	if Battlepass and Battlepass.OnSupporterPassEntityKilled then
		local attacker = event.entindex_attacker and EntIndexToHScript(event.entindex_attacker) or nil
		local playerID = nil
		if attacker ~= nil and XHSGetPlayerIDFromUnit ~= nil then
			playerID = XHSGetPlayerIDFromUnit(attacker)
		elseif attacker ~= nil and attacker.GetPlayerOwnerID ~= nil then
			playerID = attacker:GetPlayerOwnerID()
		end
		if playerID ~= nil and playerID >= 0
			and not IsPersistentBattlepassPlayer(playerID)
			and not IsBattlepassCosmeticBot(playerID) then
			return
		end
		Battlepass:OnSupporterPassEntityKilled(event)
	end
end, nil)

ListenToGameEvent("player_disconnect", function(event)
	local playerID = tonumber(event.PlayerID or event.playerid)
	if playerID == nil or not Battlepass then return end
	if not IsPersistentBattlepassPlayer(playerID) then return end
	if Battlepass.CleanupSupporterDevTest then Battlepass:CleanupSupporterDevTest(playerID, false) end
	if Battlepass.DonatorCompanion then Battlepass:DonatorCompanion(playerID, "", true) end
	if Battlepass.RemoveDonatorStatue then Battlepass:RemoveDonatorStatue(playerID) end
	if Battlepass.ClearSupporterOverrides then Battlepass:ClearSupporterOverrides(playerID) end
end, nil)

ListenToGameEvent('npc_spawned', function(event)
	local npc = EntIndexToHScript(event.entindex)

	--	print(npc:GetUnitName())

	if npc.bp_init == true then return end
	npc.bp_init = true

	local unit_name = npc:GetUnitName()

	local npc_player_id = XHSGetPlayerIDFromUnit ~= nil and XHSGetPlayerIDFromUnit(npc) or nil
	if npc_player_id == nil or npc_player_id < 0 then
		if npc.GetPlayerID ~= nil then npc_player_id = npc:GetPlayerID() end
		if (npc_player_id == nil or npc_player_id < 0) and npc.GetPlayerOwnerID ~= nil then
			npc_player_id = npc:GetPlayerOwnerID()
		end
	end
	local is_cosmetic_bot = npc_player_id ~= nil and npc_player_id >= 0
		and IsBattlepassCosmeticBot(npc_player_id)
	if npc_player_id ~= nil and npc_player_id >= 0
		and not IsPersistentBattlepassPlayer(npc_player_id)
		and not is_cosmetic_bot then
		return
	end

	local donator_level = nil

	if npc_player_id ~= nil and npc_player_id >= 0 then
		donator_level = api:GetDonatorStatus(npc_player_id)
	end

	local ply_table = CustomNetTables:GetTableValue("supporter_pass_player", tostring(npc:GetPlayerOwnerID()))
	if type(ply_table) ~= "table" then ply_table = nil end
	if is_cosmetic_bot and SupporterPass and SupporterPass.BuildPlayerTable then
		local bot_ply_table = SupporterPass:BuildPlayerTable(npc_player_id)
		if bot_ply_table ~= nil then
			CustomNetTables:SetTableValue("supporter_pass_player", tostring(npc_player_id), bot_ply_table)
		end
		if bot_ply_table ~= nil then
			ply_table = bot_ply_table
		end
	end

	if npc:IsRealHero() then
		if Battlepass.ENTITY_MODEL_OVERRIDE[unit_name] then
			npc:SetOriginalModel(Battlepass.ENTITY_MODEL_OVERRIDE[unit_name])
			npc:SetModel(Battlepass.ENTITY_MODEL_OVERRIDE[unit_name])
		end

		-- The commented out lines here are what I used to test in tools mode
		if api:IsDonator(npc:GetPlayerID()) or string.find(GetMapName(), "demo") then
			if unit_name ~= "npc_dota_hero_wisp" then
				npc:AddNewModifier(npc, nil, "modifier_patreon_donator", {})
			end
		end

		Timers:CreateTimer(0.1, function()
			if npc and not npc:IsNull() then
				Battlepass:ApplySupporterLoadout(npc:GetPlayerID(), npc)
				if Battlepass.ReapplySupporterDevTest then
					Battlepass:ReapplySupporterDevTest(npc:GetPlayerID(), npc)
				end
			end
		end)
	end
end, nil)

-- `require` is idempotent. This covers a Tools code reload that retained the
-- initialized Battlepass adapters after CUSTOM_GAME_SETUP; a fresh Lua VM must
-- reload the map, which Panorama exposes as an explicit timeout diagnostic.
TryLateInitializeContentStudio()
