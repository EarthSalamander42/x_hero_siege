local function GetXHSLaneParticipantCount()
	local participantCount = GetXHSCombatParticipantCount ~= nil
		and GetXHSCombatParticipantCount()
		or PlayerResource:GetPlayerCount()
	return math.max(1, math.min(8, tonumber(participantCount) or 1))
end

local function SetXHSLaneDoorState(lane, open)
	local wasOpen = CREEP_LANES ~= nil
		and CREEP_LANES[lane] ~= nil
		and CREEP_LANES[lane][1] == 1
	if CREEP_LANES ~= nil and CREEP_LANES[lane] ~= nil then
		CREEP_LANES[lane][1] = open and 1 or 0
	end

	for _, obstruction in pairs(Entities:FindAllByName("obstruction_lane" .. lane)) do
		obstruction:SetEnabled(not open, true)
	end
	DoEntFire(
		"door_lane" .. lane,
		"SetAnimation",
		open and "gate_02_open" or "gate_02_close",
		0,
		nil,
		nil
	)

	for _, tower in pairs(Entities:FindAllByName("dota_badguys_tower" .. lane)) do
		if open and tower:IsAlive() then
			tower:RemoveModifierByName("modifier_invulnerable")
		elseif tower:IsAlive() and not tower:HasModifier("modifier_invulnerable") then
			tower:AddNewModifier(tower, nil, "modifier_invulnerable", nil)
		end
	end

	for _, rax in pairs(Entities:FindAllByName("dota_badguys_barracks_" .. lane)) do
		if rax:IsAlive() and not rax:HasModifier("modifier_invulnerable") then
			rax:AddNewModifier(rax, nil, "modifier_invulnerable", nil)
		end
	end
	if XHSRefreshPhaseOneLaneStructureState ~= nil then
		XHSRefreshPhaseOneLaneStructureState(lane)
	end

	if open and not wasOpen and XHSKnockbackHeroesAtOpeningDoors ~= nil then
		XHSKnockbackHeroesAtOpeningDoors({ "door_lane" .. lane })
	end
end

function RefreshXHSCombatLanes(forceDefaults)
	if GameRules:State_Get() < DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		return 0
	end
	if forceDefaults ~= true and GameMode.xhs_manual_lane_configuration == true then
		local activeLaneCount = 0
		for lane = 1, 8 do
			local open = CREEP_LANES ~= nil
				and CREEP_LANES[lane] ~= nil
				and CREEP_LANES[lane][1] == 1
			SetXHSLaneDoorState(lane, open)
			if open then activeLaneCount = activeLaneCount + 1 end
		end
		return activeLaneCount
	end

	local participantCount = GetXHSLaneParticipantCount()
	_G.CREEP_LANES_TYPE = participantCount <= 4 and 2 or 1
	local laneCount = math.min(8, participantCount * CREEP_LANES_TYPE)
	for lane = 1, 8 do
		SetXHSLaneDoorState(lane, lane <= laneCount)
	end
	return laneCount
end

ListenToGameEvent('game_rules_state_change', function()
	local newState = GameRules:State_Get()

	if newState == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		for playerID = 0, PlayerResource:GetPlayerCount() - 1 do
			if PlayerResource:IsValidPlayer(playerID) then
				PlayerResource:SetCustomPlayerColor(playerID, PLAYER_COLORS[playerID][1], PLAYER_COLORS[playerID][2], PLAYER_COLORS[playerID][3])
			end
		end

		GameRules:GetGameModeEntity():SetContextThink("PreGame", function()
			EmitSoundOn("Global.InGame", BASE_GOOD)

			--			if BOTS_ENABLED == true then
			--			if IsInToolsMode() then
			--				SendToServerConsole('sm_gmode 1')
			--				SendToServerConsole('dota_bot_populate')
			--			end

			--			if base_bad then
			--				EmitSoundOn("Global.InGame", base_bad)
			--			end
			return nil
		end, 3.0)
	elseif newState == DOTA_GAMERULES_STATE_HERO_SELECTION then
		-- crash game (since 7.23)
		--		GameRules:GetGameModeEntity():SetItemAddedToInventoryFilter(Dynamic_Wrap(GameMode, "ItemAddedFilter"), GameMode)

		require('zones/dialog_xhs')
		require('zones/zone_tables_xhs')
	elseif newState == DOTA_GAMERULES_STATE_PRE_GAME then
		local player_count = GetXHSLaneParticipantCount()
		if player_count <= 4 then
			_G.CREEP_LANES_TYPE = 2
		else
			_G.CREEP_LANES_TYPE = 1
		end

		if Gold then
			Gold:Init()
		end

		for i = 1, 8 do
			DoEntFire("door_lane" .. i, "SetAnimation", "gate_02_close", 0, nil, nil)
		end

		-- QA needs direct access to the post-Muradin optional events from the
		-- beginning of a Tools match. Public games keep the normal Muradin gate.
		SetXHSOptionalEventsUnlocked(IsInToolsMode())

		local diff = { "Easy", "Normal", "Hard", "Extreme", "Divine" }
		local Color = { "green", "Yellow", "orange", "red", "darkred" }

		CustomNetTables:SetTableValue("game_options", "game_info", {
			difficulty = diff[GameRules:GetCustomGameDifficulty()],
		})

		GameRules:GetGameModeEntity():SetContextThink("PreGame", function()
			CustomGameEventManager:Send_ServerToAllClients("show_timer_bar", {})
			CustomGameEventManager:Send_ServerToAllClients("game_difficulty", { difficulty = diff[GameRules:GetCustomGameDifficulty()] })
			Notifications:TopToAll({ text = "DIFFICULTY: " .. diff[GameRules:GetCustomGameDifficulty()], color = Color[GameRules:GetCustomGameDifficulty()], duration = 10.0 })
			return nil
		end, 3.0)

		AddFOWViewer(DOTA_TEAM_GOODGUYS, Vector(6528, 1152, 192), 900, 99999, false)
		AddFOWViewer(DOTA_TEAM_CUSTOM_2, Vector(6528, 1152, 192), 900, 99999, false)

		GameMode:SetupZones()

		PHASE_2_QUEST_UNIT = CreateUnitByName("dummy_unit_phase_2_invulnerable", Vector(10000, 0, 0), false, nil, nil, 3)
		PHASE_2_QUEST_UNIT.zone = "xhs_holdout"
	end

	if newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		print("OnGameRulesStateChange: Game In Progress")

		--		ModifyLanes()

		local ice_towers = Entities:FindAllByName("npc_tower_death")
		for _, tower in pairs(ice_towers) do
			tower:AddNewModifier(tower, nil, "modifier_invulnerable", nil)
		end

		for TW = 1, 2 do
			local ice_towers_main = Entities:FindByName(nil, "npc_tower_cold_" .. TW)

			if ice_towers_main then
				ice_towers_main:AddNewModifier(ice_towers_main, nil, "modifier_invulnerable", nil)
				ice_towers_main.zone = "xhs_holdout"
			end
		end

		-- Make towers invulnerable again
		for Players = 1, 8 do
			local towers = Entities:FindAllByName("dota_badguys_tower" .. Players)
			for _, tower in pairs(towers) do
				tower:AddNewModifier(tower, nil, "modifier_invulnerable", nil)
			end

			local raxes = Entities:FindAllByName("dota_badguys_barracks_" .. Players)
			for _, rax in pairs(raxes) do
				rax.zone = "xhs_holdout"
				rax:AddNewModifier(rax, nil, "modifier_invulnerable", nil)
			end
		end

		RefreshXHSCombatLanes()
		SetXHSOptionalEventsUnlocked(IsInToolsMode())
	end
end, nil)

local function SendXHSRewardNotification(playerID, rewardType, amount, title, text)
	local player = PlayerResource:GetPlayer(playerID)
	if player == nil then return end

	CustomGameEventManager:Send_ServerToPlayer(player, "xhs_reward_notification", {
		type = rewardType,
		amount = amount,
		title = title,
		text = text,
		duration = 2.6,
	})
end

-- Cleanup a player when they leave
--[[
ListenToGameEvent('player_disconnect', function(keys)
	local name = keys.name
	local networkid = keys.networkid
	local reason = keys.reason
	local userid = keys.userid

--	CloseLane(userid)
end, nil)
--]]
local hidden_innate_abilities = {
	"necronomicon_warrior_sight",
	"holdout_blue_effect",
}
local DUNGEON_CHECKPOINT_MODEL = "models/props_structures/outpost.vmdl"

local XHS_CREEP_ARMOR_DIFFICULTY_MULTIPLIERS = {
	[1] = 0.70, -- Easy
	[2] = 0.85, -- Normal
	[3] = 1.00, -- Hard: current KV armor is the reference
	[4] = 1.20, -- Extreme
	[5] = 1.40, -- Divine
}

local XHS_PHASE_TWO_ARMOR_CREEPS = {
	npc_ghul_II = true,
	npc_orc_II = true,
	npc_magnataur_destroyer_crypt = true,
}

local XHS_DRAGON_ARMOR_CREEPS = {
	npc_dota_creature_green_dragon = true,
	npc_dota_creature_red_dragon = true,
	npc_dota_creature_blue_dragon = true,
}

local function IsXHSPhaseOneArmorCreep(unitName)
	local race, attackType = string.match(unitName or "", "^npc_xhs_([%a]+)_creep_([%a]+)_[1-4]$")
	local validRace = race == "undead" or race == "orc" or race == "elf" or race == "human"
	local validAttackType = attackType == "melee" or attackType == "ranged"
	return validRace and validAttackType
end

local function ShouldScaleXHSCreepArmor(unitName)
	return IsXHSPhaseOneArmorCreep(unitName)
		or XHS_PHASE_TWO_ARMOR_CREEPS[unitName] == true
		or XHS_DRAGON_ARMOR_CREEPS[unitName] == true
end

local function ApplyXHSCreepDifficultyArmor(npc, unitName, difficulty, referenceArmor)
	if not ShouldScaleXHSCreepArmor(unitName) then return end

	local multiplier = XHS_CREEP_ARMOR_DIFFICULTY_MULTIPLIERS[difficulty] or 1.0
	local scaledArmor = math.floor((referenceArmor * multiplier) * 10 + 0.5) / 10
	npc:SetPhysicalArmorBaseValue(scaledArmor)
	npc.xhs_hard_reference_armor = referenceArmor
	npc.xhs_difficulty_armor_multiplier = multiplier
end

-- An NPC has spawned somewhere in game. This includes heroes
ListenToGameEvent('npc_spawned', function(keys)
	local difficulty = GameRules:GetCustomGameDifficulty()
	local npc = EntIndexToHScript(keys.entindex)
	local normal_bounty = npc:GetGoldBounty()
	local normal_xp = npc:GetDeathXP()
	local normal_min_damage = npc:GetBaseDamageMin()
	local normal_max_damage = npc:GetBaseDamageMax()
	local normal_armor = npc:GetPhysicalArmorValue(false)
	local hero_level = npc:GetLevel()

	if npc and IsValidEntity(npc) then
		if npc:IsRealHero() and npc:IsAlive() and npc.xhs_dead_inventory_lock_active == true
			and StopXHSDeadInventoryLock ~= nil then
			StopXHSDeadInventoryLock(npc)
		end

		if npc:IsRealHero() and _G.XHSUnitTombstone ~= nil then
			_G.XHSUnitTombstone:RegisterHero(npc)
		end

		--ALL NPC
		for i = 1, #innate_abilities do
			local current_ability = npc:FindAbilityByName(innate_abilities[i])
			if current_ability then
				current_ability:SetLevel(1)
			end
		end

		-- Technical innates must keep functioning without occupying HUD slots.
		for i = 1, #hidden_innate_abilities do
			local hidden_ability = npc:FindAbilityByName(hidden_innate_abilities[i])
			if hidden_ability then
				hidden_ability:SetHidden(true)
			end
		end

		if npc:GetUnitName() == "npc_dota_dungeon_checkpoint" then
			-- The map-placed checkpoint keeps the model serialized in the VMAP.
			-- Override both model references before attaching model-dependent PFX.
			npc:SetOriginalModel(DUNGEON_CHECKPOINT_MODEL)
			npc:SetModel(DUNGEON_CHECKPOINT_MODEL)
			npc:SetMaterialGroup("1")

			if npc.xhs_outpost_ambient_particle == nil then
				npc.xhs_outpost_ambient_particle = ParticleManager:CreateParticle(
					"particles/world_outpost/world_outpost_radiant_ambient.vpcf",
					PATTACH_ABSORIGIN_FOLLOW,
					npc
				)
				ParticleManager:SetParticleControlEnt(
					npc.xhs_outpost_ambient_particle,
					0,
					npc,
					PATTACH_ABSORIGIN_FOLLOW,
					nil,
					npc:GetAbsOrigin(),
					true
				)
			end
		end

		if npc:GetTeamNumber() ~= 2 or npc:GetUnitName() == "npc_dota_creature_muradin_bronzebeard" then
			local unit_kv = GetUnitKeyValuesByName(npc:GetUnitName())

			local aiState = unit_kv and tonumber(unit_kv["UseAI"]) or 0
			if aiState > 0 then
				npc:AddNewModifier(npc, nil, "modifier_ai", { state = aiState })
			end
		end

		if npc:GetUnitName() == "npc_dota_hero_magtheridon" then
			-- in case there are 2, wait for npc.boss_count

			GameRules:GetGameModeEntity():SetContextThink("PreGame", function()
				ShowBossBar(npc)
				return nil
			end, 0.1)
		end

		if npc:GetUnitName() == "npc_dota_hero_grom_hellscream" and XHSGrom_AttachPhase3AI ~= nil then
			GameRules:GetGameModeEntity():SetContextThink("AttachGromPhase3AI" .. tostring(npc:entindex()), function()
				if npc ~= nil and IsValidEntity(npc) and not npc:IsNull() and npc.xhs_phase3_staged ~= true then
					XHSGrom_AttachPhase3AI(npc)
				end
				return nil
			end, 0.1)
		end

		if npc:GetUnitName() == "npc_dota_hero_illidan" and XHSIllidan_AttachPhase3AI ~= nil then
			GameRules:GetGameModeEntity():SetContextThink("AttachIllidanPhase3AI" .. tostring(npc:entindex()), function()
				if npc ~= nil and IsValidEntity(npc) and not npc:IsNull() and npc.xhs_phase3_staged ~= true then
					XHSIllidan_AttachPhase3AI(npc)
				end
				return nil
			end, 0.1)
		end

		if npc:GetUnitName() == "npc_dota_hero_balanar" and XHSBalanar_AttachPhase3AI ~= nil then
			GameRules:GetGameModeEntity():SetContextThink("AttachBalanarPhase3AI" .. tostring(npc:entindex()), function()
				if npc ~= nil and IsValidEntity(npc) and not npc:IsNull() and npc.xhs_phase3_staged ~= true then
					XHSBalanar_AttachPhase3AI(npc)
				end
				return nil
			end, 0.1)
		end

		if npc:GetUnitName() == "npc_dota_hero_proudmoore" and XHSProudmoore_AttachPhase3AI ~= nil then
			GameRules:GetGameModeEntity():SetContextThink("AttachProudmoorePhase3AI" .. tostring(npc:entindex()), function()
				if npc ~= nil and IsValidEntity(npc) and not npc:IsNull() and npc.xhs_phase3_staged ~= true then
					XHSProudmoore_AttachPhase3AI(npc)
				end
				return nil
			end, 0.1)
		end

		if npc:GetUnitName() == "npc_dota_hero_arthas" and XHSArthas_AttachPhase3AI ~= nil then
			GameRules:GetGameModeEntity():SetContextThink("AttachArthasPhase3AI" .. tostring(npc:entindex()), function()
				if npc ~= nil and IsValidEntity(npc) and not npc:IsNull() then
					XHSArthas_AttachPhase3AI(npc)
				end
				return nil
			end, 0.1)
		end

		if npc:GetUnitName() == "npc_dota_boss_lich_king" and XHSLichKing_AttachPhase3AI ~= nil then
			GameRules:GetGameModeEntity():SetContextThink("AttachLichKingPhase3AI" .. tostring(npc:entindex()), function()
				if npc ~= nil and IsValidEntity(npc) and not npc:IsNull() and not npc:IsInvulnerable() then
					XHSLichKing_AttachPhase3AI(npc)
				end
				return nil
			end, 0.1)
		end

		if npc:GetUnitName() == "npc_dota_boss_spirit_master" and XHSSpiritMaster_AttachPhase3AI ~= nil then
			GameRules:GetGameModeEntity():SetContextThink("AttachSpiritMasterPhase3AI" .. tostring(npc:entindex()), function()
				if npc ~= nil and IsValidEntity(npc) and not npc:IsNull() then
					XHSSpiritMaster_AttachPhase3AI(npc)
				end
				return nil
			end, 0.1)
		end

		-- HERO NPC
		if npc:IsRealHero() and npc:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
			if npc.bFirstSpawnComplete == nil then
				npc:AddNewModifier(npc, nil, "modifier_custom_mechanics", {})
				if npc:GetUnitName() == "npc_dota_hero_rattletrap" then
					npc:AddNewModifier(npc, nil, "modifier_xhs_space_marine_attack_sound", {})
				end

				if npc:IsFakeHero() and AbilitiesHeroes_XX[npc:GetUnitName()] then
					npc:AddAbility("ability_level_20"):SetLevel(1)
					for _, ability in pairs(AbilitiesHeroes_XX[npc:GetUnitName()]) do
						if ability ~= nil then
							npc:AddAbility(ability[1])
							npc:UpgradeAbility(npc:FindAbilityByName(ability[1]))
						end
					end
				else
					-- This internal handling is used to set up main barebones functions
					if npc:IsRealHero() and npc.bFirstSpawned == nil then
						npc.bFirstSpawned = true
						GameMode:OnHeroInGame(npc)
					end

					if npc:GetUnitName() == "npc_dota_hero_chaos_knight" or npc:GetUnitName() == "npc_dota_hero_keeper_of_the_light" then
						npc:SetAbilityPoints(0)
					elseif npc:GetUnitName() == "npc_dota_hero_lone_druid" then
						npc:AddNewModifier(npc, nil, "modifier_item_ultimate_scepter_consumed", {})
					end

					npc.bFirstSpawnComplete = true
					GameMode.bPlayerHasSpawned = true
					npc.CurrentZoneName = nil
					GameMode:OnPlayerHeroEnteredZone(npc, "xhs_holdout")
					npc.ankh_respawn = false
					--					npc:AddNewModifier(npc, nil, "modifier_hero", {})
				end
			elseif npc.bFirstSpawnComplete == true then
				if npc:GetUnitName() == "npc_dota_hero_chaos_knight" or npc:GetUnitName() == "npc_dota_hero_keeper_of_the_light" then
					npc:SetAbilityPoints(0)
				elseif npc:GetUnitName() == "npc_dota_hero_tiny" then
					npc:AddAbility("tiny_grow"):SetLevel(1)
					npc:SetModelScale(1.1)

					GameRules:GetGameModeEntity():SetContextThink("PreGame", function()
						npc:RemoveAbility("tiny_grow")
						return nil
					end, 0.3)

					--debug
					if hero_level == 17 then
						npc:SetAbilityPoints(npc:GetAbilityPoints() - 1)
					elseif hero_level >= 20 then
						local ability = npc:FindAbilityByName("holdout_war_club_20")
						npc:RemoveModifierByName("modifier_item_ultimate_scepter_consumed")
						npc:RemoveModifierByName("modifier_item_ultimate_scepter_consumed")
						npc:AddNewModifier(npc, ability, "modifier_item_ultimate_scepter_consumed", {})
						-- npc:AddNewModifier(npc, nil, "modifier_tiny_craggy_exterior", {})
					end
				end
			end
			return
		end

		-- CREATURES NPC
		if not npc:IsRealHero() and (npc:GetTeamNumber() == DOTA_TEAM_CUSTOM_1 or npc:GetTeamNumber() == DOTA_TEAM_CUSTOM_2 or npc:GetTeamNumber() == DOTA_TEAM_NEUTRALS) then
			if XHSCreepPassives ~= nil then
				XHSCreepPassives:Apply(npc, difficulty)
			end
			ApplyXHSCreepDifficultyArmor(npc, npc:GetUnitName(), difficulty, normal_armor)

			if difficulty == 1 then
				npc:SetMinimumGoldBounty(normal_bounty * 1.5)
				npc:SetMaximumGoldBounty(normal_bounty * 1.5)
				npc:SetDeathXP(normal_xp * 1.25)
				npc:SetBaseDamageMin(normal_min_damage * 0.75)
				npc:SetBaseDamageMax(normal_max_damage * 0.75)
			elseif difficulty == 2 then
				npc:SetMinimumGoldBounty(normal_bounty * 1.1)
				npc:SetMaximumGoldBounty(normal_bounty * 1.1)
				npc:SetDeathXP(normal_xp)
				npc:SetBaseDamageMin(normal_min_damage)
				npc:SetBaseDamageMax(normal_max_damage)
			elseif difficulty == 3 then
				npc:SetMinimumGoldBounty(normal_bounty)
				npc:SetMaximumGoldBounty(normal_bounty)
				npc:SetDeathXP(normal_xp * 0.9)
				npc:SetBaseDamageMin(normal_min_damage * 1.25)
				npc:SetBaseDamageMax(normal_max_damage * 1.25)
			elseif difficulty == 4 then
				npc:SetMinimumGoldBounty(normal_bounty)
				npc:SetMaximumGoldBounty(normal_bounty)
				npc:SetDeathXP(normal_xp * 0.75)
				npc:SetBaseDamageMin(normal_min_damage * 1.5)
				npc:SetBaseDamageMax(normal_max_damage * 1.5)
			elseif difficulty == 5 then
				npc:SetMinimumGoldBounty(normal_bounty * 0.75)
				npc:SetMaximumGoldBounty(normal_bounty * 0.75)
				npc:SetDeathXP(normal_xp * 0.60)
				npc:SetBaseDamageMin(normal_min_damage * 2.0)
				npc:SetBaseDamageMax(normal_max_damage * 2.0)
			end

			-- Cycle through any innate abilities found, then upgrade them
			for i = 1, #difficulty_abilities do
				local current_ability = npc:FindAbilityByName(difficulty_abilities[i])
				local difficulty = GameRules:GetCustomGameDifficulty()

				if current_ability then
					current_ability:SetLevel(difficulty)
				end
			end

			npc.zone = "xhs_holdout"

			return
		end

		if npc:IsIllusion() then
			if npc:GetPlayerOwner() then
				local main_hero = PlayerResource:GetSelectedHeroEntity(npc:GetPlayerOwnerID())

				npc:SetBaseStrength(main_hero:GetStrength())
				npc:SetBaseAgility(main_hero:GetAgility())
				npc:SetBaseIntellect(main_hero:GetIntellect(true))
			end
		end
	end
end, nil)

--[[

-- An entity somewhere has been hurt.  This event fires very often with many units so don't do too many expensive
-- operations here
function GameMode:OnEntityHurt(keys)
	local damagebits = keys.damagebits -- This might always be 0 and therefore useless
	if keys.entindex_attacker ~= nil and keys.entindex_killed ~= nil then
		local entCause = EntIndexToHScript(keys.entindex_attacker)
		local entVictim = EntIndexToHScript(keys.entindex_killed)

		-- The ability/item used to damage, or nil if not damaged by an item/ability
		local damagingAbility = nil

		if keys.entindex_inflictor ~= nil then
			damagingAbility = EntIndexToHScript(keys.entindex_inflictor)
		end
	end
end

-- An item was purchased by a player
function GameMode:OnItemPurchased(keys)
	-- The playerID of the hero who is buying something
	local plyID = keys.PlayerID
	if not plyID then return end

	-- The name of the item purchased
	local itemName = keys.itemname
	
	-- The cost of the item purchased
	local itemcost = keys.itemcost
end

function GameMode:OnAbilityUsed(keys)
local player = PlayerResource:GetPlayer(keys.PlayerID)
local hero = player:GetAssignedHero()
local abilityname = keys.abilityname
local ability = hero:FindAbilityByName(abilityname)
local k, v = string.find(abilityname, "item_")

--	if a then
--		print("Item:", abilityname)
--	end
end

function GameMode:OnNonPlayerUsedAbility(keys)
	local abilityname = keys.abilityname
end

function GameMode:OnPlayerChangedName(keys)
	local newName = keys.newname
	local oldName = keys.oldName
end

--]]

local function RemoveNewestPurchasedItem(hero, itemName, itemEntIndex, minPurchaseTime)
	if hero == nil or hero:IsNull() or itemName == nil or itemName == "" then return false end

	local itemToRemove = nil
	local newestPurchaseTime = -1
	local fallbackItem = nil
	local fallbackPurchaseTime = -1
	if itemEntIndex ~= nil and itemEntIndex > 0 then
		local eventItem = EntIndexToHScript(itemEntIndex)
		if eventItem ~= nil and not eventItem:IsNull() then
			local eventItemName = eventItem.GetAbilityName and eventItem:GetAbilityName() or eventItem:GetName()
			if eventItemName == itemName then
				itemToRemove = eventItem
			end
		end
	end

	if itemToRemove == nil then
		for slot = 0, 14 do
			local item = hero:GetItemInSlot(slot)
			if item ~= nil and not item:IsNull() then
				local slotItemName = item.GetAbilityName and item:GetAbilityName() or item:GetName()
				if slotItemName == itemName then
					local purchaseTime = item.GetPurchaseTime and item:GetPurchaseTime() or 0
					if itemToRemove == nil or purchaseTime >= newestPurchaseTime then
						itemToRemove = item
						newestPurchaseTime = purchaseTime
					end
				end

				local purchaseTime = item.GetPurchaseTime and item:GetPurchaseTime() or 0
				if minPurchaseTime ~= nil and purchaseTime >= minPurchaseTime and purchaseTime >= fallbackPurchaseTime then
					fallbackItem = item
					fallbackPurchaseTime = purchaseTime
				end
			end
		end
	end

	if fallbackItem ~= nil and (itemToRemove == nil or (minPurchaseTime ~= nil and newestPurchaseTime < minPurchaseTime)) then
		itemToRemove = fallbackItem
	end

	if itemToRemove ~= nil and not itemToRemove:IsNull() then
		hero:RemoveItem(itemToRemove)
		return true
	end

	return false
end

ListenToGameEvent('dota_item_purchased', function(keys)
	local playerID = tonumber(keys.PlayerID)
	if playerID == nil or playerID < 0 then return end
	if IsPlayerXHSInventoryLocked == nil or not IsPlayerXHSInventoryLocked(playerID) then return end

	local itemName = keys.itemname or ""
	local itemCost = tonumber(keys.itemcost) or 0
	local itemEntIndex = tonumber(keys.item_entindex or keys.ItemEntityIndex or keys.item_ent_index) or -1
	local purchaseGameTime = GameRules:GetGameTime()

	local lockedHero = PlayerResource:GetSelectedHeroEntity(playerID)
	if lockedHero == nil or lockedHero:IsNull() then
		local player = PlayerResource:GetPlayer(playerID)
		lockedHero = player and player:GetAssignedHero() or nil
	end
	if lockedHero ~= nil and not lockedHero:IsNull() and SendXHSInventoryLockedError ~= nil then
		SendXHSInventoryLockedError(lockedHero)
	else
		SendErrorMessage(playerID, "#error_dead_inventory_locked")
	end

	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("xhs_locked_inventory_purchase_rollback"), function()
		local hero = PlayerResource:GetSelectedHeroEntity(playerID)
		if hero == nil or hero:IsNull() then
			local player = PlayerResource:GetPlayer(playerID)
			hero = player and player:GetAssignedHero() or nil
		end

		RemoveNewestPurchasedItem(hero, itemName, itemEntIndex, purchaseGameTime - 0.5)

		if itemCost > 0 then
			PlayerResource:ModifyGold(playerID, itemCost, false, DOTA_ModifyGold_Unspecified)
		end

		return nil
	end, 0)
end, nil)

local function GetXHSTrackedPlayerHero(playerID)
	if playerID == nil or playerID < 0 or not PlayerResource:IsValidPlayerID(playerID) then return nil end

	local hero = PlayerResource:GetSelectedHeroEntity(playerID)
	if hero ~= nil and not hero:IsNull() then return hero end

	local player = PlayerResource:GetPlayer(playerID)
	return player ~= nil and player:GetAssignedHero() or nil
end

ListenToGameEvent('dota_player_used_ability', function(keys)
	local playerID = tonumber(keys.PlayerID or keys.player_id or keys.playerid)
	if playerID == nil or playerID < 0 then return end

	local abilityName = keys.abilityname or keys.itemname or keys.ability_name
	if XHSIsPotionItemName == nil or XHSIsPotionItemName(abilityName) ~= true then return end
	if XHSRecordPotionUseForPlayer == nil then return end

	XHSRecordPotionUseForPlayer(playerID, GetXHSTrackedPlayerHero(playerID), abilityName)
end, nil)

local function GetHeroFromInventoryEvent(keys)
	local unitEntIndex = tonumber(keys.unit_entindex or keys.inventory_parent_entindex or keys.entindex or keys.entityIndex)
	if unitEntIndex ~= nil and unitEntIndex > 0 then
		local unit = EntIndexToHScript(unitEntIndex)
		if unit ~= nil and not unit:IsNull() and unit.IsRealHero and unit:IsRealHero() then
			return unit
		end
	end

	local playerID = tonumber(keys.PlayerID or keys.player_id or keys.playerid)
	if playerID ~= nil and playerID >= 0 then
		local hero = nil
		if PlayerResource:IsValidPlayerID(playerID) and PlayerResource:HasSelectedHero(playerID) then
			hero = PlayerResource:GetSelectedHeroEntity(playerID)
		end

		if hero == nil or hero:IsNull() then
			local player = PlayerResource:GetPlayer(playerID)
			hero = player and player:GetAssignedHero() or nil
		end

		if hero ~= nil and not hero:IsNull() then
			return hero
		end
	end

	return nil
end

local function RestoreReincarnationInventoryForHero(hero)
	if hero == nil or hero:IsNull() then return end
	if IsPlayerXHSReincarnating == nil or RestoreXHSReincarnationInventory == nil then return end
	if not hero.GetPlayerID or not IsPlayerXHSReincarnating(hero:GetPlayerID()) then return end

	if RestoreXHSReincarnationInventory(hero) and SendXHSReincarnationInventoryLockedError ~= nil then
		SendXHSReincarnationInventoryLockedError(hero)
	end
end

local function OnReincarnationInventoryChanged(keys)
	local hero = GetHeroFromInventoryEvent(keys or {})
	if hero ~= nil then
		RestoreReincarnationInventoryForHero(hero)
		return
	end

	for playerID = 0, PlayerResource:GetPlayerCount() - 1 do
		if IsPlayerXHSReincarnating ~= nil and IsPlayerXHSReincarnating(playerID) then
			RestoreReincarnationInventoryForHero(PlayerResource:GetSelectedHeroEntity(playerID))
		end
	end
end

ListenToGameEvent('dota_inventory_changed', OnReincarnationInventoryChanged, nil)
ListenToGameEvent('dota_inventory_item_changed', OnReincarnationInventoryChanged, nil)
ListenToGameEvent('dota_inventory_item_added', OnReincarnationInventoryChanged, nil)
ListenToGameEvent('dota_inventory_player_got_item', OnReincarnationInventoryChanged, nil)
ListenToGameEvent('inventory_updated', OnReincarnationInventoryChanged, nil)

ListenToGameEvent('dota_player_learned_ability', function(keys)
	local player = EntIndexToHScript(keys.player)
	local hero = player:GetAssignedHero()
	local abilityname = keys.abilityname
	local ability = hero:FindAbilityByName(abilityname)

	if hero:GetUnitName() == "npc_dota_hero_doom_bringer" then
		if ability:GetAbilityIndex() == 3 or ability:GetAbilityIndex() == 4 then
			ability:SetLevel(ability:GetLevel() - 1)
			hero:SetAbilityPoints(hero:GetAbilityPoints() + 1)
			SendErrorMessage(hero:GetPlayerID(), "#error_cant_lvlup")
		end
	elseif hero:GetUnitName() == "npc_dota_hero_lone_druid" then
		if ability:GetAbilityIndex() == 0 then
			local Bears = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false)
			for _, Bear in pairs(Bears) do
				for number = 1, 7 do
					if Bear and Bear:GetUnitName() == "npc_dota_lone_druid_bear" .. number then
						Bear.ankh_respawn = true

						GameRules:GetGameModeEntity():SetContextThink("PreGame", function()
							Bear.ankh_respawn = false
							return nil
						end, FrameTime())
					end
				end
			end
		end
	end
end, nil)

--[[

function GameMode:OnAbilityChannelFinished(keys)
	local abilityname = keys.abilityname
	local interrupted = keys.interrupted == 1
end
--]]
ListenToGameEvent('dota_player_gained_level', function(keys)
	local player = EntIndexToHScript(keys.player)
	local level = keys.level
	local hero = player:GetAssignedHero()
	local hero_level = hero:GetLevel()

	if hero_level == 17 then -- Debug because 7.0
		hero:SetAbilityPoints(hero:GetAbilityPoints() + 1)
	elseif hero_level > 19 then
		hero:SetAbilityPoints(hero:GetAbilityPoints() - 1)
	end

	if hero:GetUnitName() == "npc_dota_hero_lich" then
		if hero_level == 20 then
			hero:RemoveAbility("holdout_frost_frenzy")
		end
	end

	if hero:GetUnitName() == "npc_dota_hero_tiny" then
		if hero_level == 20 then
			local ability = hero:FindAbilityByName("holdout_war_club_20")
			hero:RemoveAbility("holdout_war_club")
			hero:AddNewModifier(hero, ability, "modifier_item_ultimate_scepter_consumed", {})
		end
	end

	if hero:GetUnitName() == "npc_dota_hero_elder_titan" then
		if hero_level == 20 then
			hero:RemoveAbility("holdout_shockwave")
			hero:RemoveAbility("holdout_war_stomp")
			hero:RemoveAbility("holdout_roar")
		end
	end

	if hero:GetUnitName() == "npc_dota_hero_sven" then
		if hero_level == 20 then
			hero:RemoveAbility("holdout_storm_bolt")
			hero:RemoveAbility("holdout_thunder_clap")
		end
	end

	if hero:GetUnitName() == "npc_dota_hero_sniper" then
		if hero_level == 20 then
			local rocket_launcher = hero:FindAbilityByName("holdout_rocket_launcher")
			local plasma_rifle = hero:FindAbilityByName("holdout_plasma_rifle")

			if rocket_launcher ~= nil and not rocket_launcher:IsNull() and rocket_launcher:GetToggleState() then
				rocket_launcher:ToggleAbility()
			end
			if plasma_rifle ~= nil and not plasma_rifle:IsNull() and plasma_rifle:GetToggleState() then
				plasma_rifle:ToggleAbility()
			end

			hero:RemoveModifierByName("modifier_rocket_launcher")
			hero:RemoveModifierByName("modifier_plasma_rifle")
			hero:RemoveAbility("holdout_rocket_launcher")
			hero:RemoveAbility("holdout_plasma_rifle")
		end
	end

	if hero:GetUnitName() == "npc_dota_hero_brewmaster" then
		if hero_level == 20 then
			hero:RemoveAbility("shadow_shaman_shackles")
		end
	end

	if hero:GetUnitName() == "npc_dota_hero_omniknight" then
		if hero_level == 20 then
			hero:RemoveAbility("holdout_taunt")
		end
	end

	if hero:GetUnitName() == "npc_dota_hero_chaos_knight" then
		local stacks = hero:GetLevel()
		hero:SetModifierStackCount("modifier_power_mount_str", caster, stacks) -- Power Mount(STR) Level Up
		hero:SetModifierStackCount("modifier_power_mount_agi", caster, stacks) -- Power Mount(AGI) Level Up
		hero:SetModifierStackCount("modifier_power_mount_int", caster, stacks) -- Power Mount(INT) Level Up
		hero:SetModifierStackCount("modifier_dark_cleave_dummy", caster, stacks) -- Dark Cleave Level Up
		hero:SetAbilityPoints(hero:GetAbilityPoints() - 1)

		if hero_level == 5 then
			hero:UpgradeAbility(hero:FindAbilityByName("holdout_instakill"))
		end
		if hero_level >= 8 then
			hero:UpgradeAbility(hero:FindAbilityByName("holdout_requiem"))
			hero:SetModifierStackCount("modifier_requiem_dummy", caster, stacks * 2)
		end
		if hero_level == 10 then
			hero:UpgradeAbility(hero:FindAbilityByName("holdout_odin"))
		end
		if hero_level == 15 then
			hero:UpgradeAbility(hero:FindAbilityByName("holdout_odin"))
		end
	end

	if hero:GetUnitName() == "npc_dota_hero_keeper_of_the_light" then
		local stacks = hero:GetLevel()
		hero:SetModifierStackCount("modifier_power_mount_str", caster, stacks) -- Power Mount(STR) Level Up
		hero:SetModifierStackCount("modifier_power_mount_agi", caster, stacks) -- Power Mount(AGI) Level Up
		hero:SetModifierStackCount("modifier_power_mount_int", caster, stacks) -- Power Mount(INT) Level Up
		hero:SetAbilityPoints(hero:GetAbilityPoints() - 1)

		if hero_level >= 5 then
			hero:UpgradeAbility(hero:FindAbilityByName("holdout_light_stand"))
			hero:SetModifierStackCount("modifier_light_stand_dummy", caster, stacks)
		end
		if hero_level == 8 then
			hero:UpgradeAbility(hero:FindAbilityByName("holdout_sacred_pool"))
		end
		if hero_level == 10 then
			hero:UpgradeAbility(hero:FindAbilityByName("holdout_guardian_angel"))
		end
		if hero_level == 15 then
			hero:UpgradeAbility(hero:FindAbilityByName("holdout_guardian_angel"))
		end
	end

	if hero_level == 20 then
		-- 7.23 outpost capture ability fix
		if hero:HasAbility("ability_capture") then
			hero:RemoveAbility("ability_capture")
		end

		ForEachUnitAbility(hero, function(ability)
			if ability:GetLevel() < ability:GetMaxLevel() then
				for j = 1, ability:GetMaxLevel() - ability:GetLevel() do
					hero:UpgradeAbility(ability)
				end
			end
		end)

		if AbilitiesHeroes_XX[hero:GetUnitName()] then
			hero.lvl_20 = true
			local notification_segments = {
				{ text = "You've reached level 20. Check out your new abilities! " },
			}

			for _, ability in pairs(AbilitiesHeroes_XX[hero:GetUnitName()]) do
				if ability ~= nil then
					table.insert(notification_segments, { ability = ability[1] })
					local new_ability = hero:AddAbility(ability[1])
					if new_ability ~= nil then
						new_ability:SetLevel(new_ability:GetMaxLevel())
					end
					local oldab = GetUnitAbilityBySafeIndex(hero, ability[2])
					if oldab ~= nil and oldab:GetAutoCastState() then
						oldab:ToggleAutoCast()
					end
					if oldab ~= nil then
						hero:SwapAbilities(oldab:GetName(), ability[1], true, true)
					end
				end
			end

			Notifications:Bottom(hero:GetPlayerOwnerID(), {
				duration = 10,
				segments = notification_segments,
			})
		else
			print("No Level 20 Ability for " .. hero:GetUnitName() .. " found!")
		end
	end
end, nil)

--[[

function GameMode:OnLastHit(keys)
local isFirstBlood = keys.FirstBlood == 1
local isHeroKill = keys.HeroKill == 1
local isTowerKill = keys.TowerKill == 1
local player = PlayerResource:GetPlayer(keys.PlayerID)
local killedEnt = EntIndexToHScript(keys.EntKilled)

end

function GameMode:OnTreeCut(keys)
local treeX = keys.tree_x
local treeY = keys.tree_y

end

function GameMode:OnPlayerTakeTowerDamage(keys)
local player = PlayerResource:GetPlayer(keys.PlayerID)
local damage = keys.damage

end

function GameMode:OnTeamKillCredit(keys)
local killerPlayer = PlayerResource:GetPlayer(keys.killer_userid)
local victimPlayer = PlayerResource:GetPlayer(keys.victim_userid)
local numKills = keys.herokills
local killerTeamNumber = keys.teamnumber

end

function GameMode:PlayerConnect(keys)
end

function GameMode:OnItemCombined(keys)
local plyID = keys.PlayerID
if not plyID then return end
local player = PlayerResource:GetPlayer(plyID)
local itemName = keys.itemname
local itemcost = keys.itemcost
end

function GameMode:OnAbilityCastBegins(keys)
local player = PlayerResource:GetPlayer(keys.PlayerID)
local hero = player:GetAssignedHero()
local abilityName = keys.abilityname
local ability = hero:FindAbilityByName(abilityname)

	if hero:GetUnitName() == "npc_dota_hero_earth_spirit" then
		StartAnimation(hero, {duration = 1.0, activity = ACT_DOTA_CAST_ABILITY_6, rate = 1.0})
	end
end

function GameMode:OnTowerKill(keys)
local gold = keys.gold
local killerPlayer = PlayerResource:GetPlayer(keys.killer_userid)
local team = keys.teamnumber
end

function GameMode:OnPlayerSelectedCustomTeam(keys)
local player = PlayerResource:GetPlayer(keys.player_id)
local success = (keys.success == 1)
local team = keys.team_id
end

-- This function is called whenever an NPC reaches its goal position/target
function GameMode:OnNPCGoalReached(keys)
local goalEntity = EntIndexToHScript(keys.goal_entindex)
local nextGoalEntity = EntIndexToHScript(keys.next_goal_entindex)
local npc = EntIndexToHScript(keys.npc_entindex)
end

--]]
ListenToGameEvent("player_chat", function(keys)
	local teamonly = keys.teamonly
	local userID = keys.playerid
	local text = keys.text
	local player = PlayerResource:GetPlayer(userID)
	local hero = PlayerResource:GetPlayer(userID):GetAssignedHero()
	local donator_level = 0

	if api then
		donator_level = api:GetDonatorStatus(userID)
	end

	for str in string.gmatch(text, "%S+") do
		if str == "-xhs_precache_report" and IsInToolsMode() and XHSPrecache then
			XHSPrecache:PrintReport()
		end

		if donator_level == 1 or donator_level == 2 or donator_level == 3 or IsInToolsMode() then
			for Frozen = 0, PlayerResource:GetPlayerCount() - 1 do
				local PlayerNames = { "Red", "Blue", "Cyan", "Purple", "Yellow", "Orange", "Green", "Pink" }
				if PlayerResource:IsValidPlayer(Frozen) then
					if str == "-freeze_" .. Frozen + 1 then
						local hero = PlayerResource:GetPlayer(Frozen):GetAssignedHero()
						hero:AddNewModifier(hero, nil, "modifier_pause_creeps", {})
						hero:AddNewModifier(hero, nil, "modifier_invulnerable", {})
						CameraMotion:Follow(hero:GetPlayerOwnerID(), hero, {
							from = hero,
							duration = 0,
							owner = "admin_freeze",
							priority = 200,
							policy = "replace",
						})
						Notifications:TopToAll({
							duration = 6.0,
							segments = {
								{ text = "[ADMIN MOD]: ",                style = { color = "red", ["font-size"] = "30px" } },
								{ text = PlayerNames[Frozen + 1] .. " ", style = { color = PlayerNames[Frozen + 1], ["font-size"] = "25px" } },
								{ text = "player has been jailed!",      style = { color = "white", ["font-size"] = "25px" } },
							},
						})
					end
					if str == "-unfreeze_" .. Frozen + 1 then
						local hero = PlayerResource:GetPlayer(Frozen):GetAssignedHero()
						hero:RemoveModifierByName("modifier_pause_creeps")
						hero:RemoveModifierByName("modifier_pause_creeps")
						hero:RemoveModifierByName("modifier_invulnerable")
						hero:RemoveModifierByName("modifier_command_restricted")
						CameraMotion:Release(hero:GetPlayerOwnerID(), {
							owner = "admin_freeze",
							mode = "free",
							reason = "admin freeze ended",
						})
						Notifications:TopToAll({
							duration = 6.0,
							segments = {
								{ text = "[ADMIN MOD]: ",                style = { color = "red", ["font-size"] = "30px" } },
								{ text = PlayerNames[Frozen + 1] .. " ", style = { color = PlayerNames[Frozen + 1], ["font-size"] = "25px" } },
								{ text = "player has been released!",    style = { color = "white", ["font-size"] = "25px" } },
							},
						})
					end
					if str == "-kill_" .. Frozen + 1 then
						local hero = PlayerResource:GetPlayer(Frozen):GetAssignedHero()
						if hero:IsAlive() then
							hero:Kill(nil, nil)
							Notifications:TopToAll({
								duration = 6.0,
								segments = {
									{ text = "[ADMIN MOD]: ",                style = { color = "red", ["font-size"] = "30px" } },
									{ text = PlayerNames[Frozen + 1] .. " ", style = { color = PlayerNames[Frozen + 1], ["font-size"] = "25px" } },
									{ text = "player has been slayed!",      style = { color = "white", ["font-size"] = "25px" } },
								},
							})
						end
					end
					if str == "-revive_" .. Frozen + 1 then
						local hero = PlayerResource:GetPlayer(Frozen):GetAssignedHero()
						hero:RespawnHero(false, false)
						Notifications:TopToAll({
							duration = 6.0,
							segments = {
								{ text = "[ADMIN MOD]: ",                style = { color = "red", ["font-size"] = "30px" } },
								{ text = PlayerNames[Frozen + 1] .. " ", style = { color = PlayerNames[Frozen + 1], ["font-size"] = "25px" } },
								{ text = "player has been revived!",     style = { color = "white", ["font-size"] = "25px" } },
							},
						})
					end
					if str == "-yolo_" .. Frozen + 1 then
						local hero = PlayerResource:GetPlayer(Frozen):GetAssignedHero()
						hero:SetMoveCapability(DOTA_UNIT_CAP_MOVE_FLY)
						StartAnimation(hero, { duration = 9999.0, activity = ACT_DOTA_FLAIL, rate = 0.9 })
						yolo = ParticleManager:CreateParticle("particles/units/heroes/hero_batrider/batrider_firefly_ember.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
						ParticleManager:SetParticleControl(yolo, 0, hero:GetAbsOrigin() + Vector(0, 0, 100))
						yolo2 = ParticleManager:CreateParticle("particles/units/heroes/hero_ember_spirit/ember_spirit_flameguard.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
						hero:EmitSound("Hero_Batrider.Firefly.Cast")
						hero:EmitSound("Hero_Batrider.Firefly.Loop")
						Notifications:TopToAll({
							duration = 6.0,
							segments = {
								{ text = "[ADMIN MOD]: ",                style = { color = "red", ["font-size"] = "30px" } },
								{ text = PlayerNames[Frozen + 1] .. " ", style = { color = PlayerNames[Frozen + 1], ["font-size"] = "25px" } },
								{ text = "player is in YOLO state!",     style = { color = "white", ["font-size"] = "25px" } },
							},
						})
					end
					if str == "-unyolo_" .. Frozen + 1 then
						local hero = PlayerResource:GetPlayer(Frozen):GetAssignedHero()
						hero:SetMoveCapability(DOTA_UNIT_CAP_MOVE_GROUND)
						EndAnimation(hero)
						hero:StopSound("Hero_Batrider.Firefly.Loop")
						ParticleManager:DestroyParticle(yolo, true)
						ParticleManager:DestroyParticle(yolo2, true)
						Notifications:TopToAll({
							duration = 6.0,
							segments = {
								{ text = "[ADMIN MOD]: ",                        style = { color = "red", ["font-size"] = "30px" } },
								{ text = PlayerNames[Frozen + 1] .. " ",         style = { color = PlayerNames[Frozen + 1], ["font-size"] = "25px" } },
								{ text = "player is not in YOLO state anymore.", style = { color = "white", ["font-size"] = "25px" } },
							},
						})
					end
				end
			end

			if str == "-replaceherowith" then
				text = string.gsub(text, str, "")
				text = string.gsub(text, " ", "")

				if PlayerResource:GetSelectedHeroName(hero:GetPlayerID()) ~= "npc_dota_hero_" .. text then
					--					if KeyValues.HeroKV["npc_dota_hero_"..text] then
					local wisp = PlayerResource:GetSelectedHeroEntity(hero:GetPlayerID())
					XHSPrecache:ReplaceHeroWith(hero:GetPlayerID(), "npc_dota_hero_" .. text, 0, 0, wisp, {
						cleanupDelay = 1.0,
					})
					-- else
					-- 	Notifications:TopToAll({text="Hero don't exist!", duration=6.0, style={color="red", ["font-size"]="30px"}})
					-- end
				end
			end
		end

		if str == "-bt" then
			BuyMaxSmallTomesForPlayer(userID)
		end

		if str == "-info" then
			local diff = { "Easy", "Normal", "Hard", "Extreme", "Divine" }
			local lanes = { "Simple", "Double", "Full" }

			Notifications:Bottom(player, { text = "DIFFICULTY: " .. diff[GameRules:GetCustomGameDifficulty()], duration = 10.0 })
			Notifications:Bottom(player, { text = "CREEP LANES: " .. lanes[CREEP_LANES_TYPE], duration = 10.0 })
		end

		if str == "-openlane_all" or str == "-ol_all" then
			--			Notifications:TopToAll({text="Host opened every lanes!", style={color="lightgreen"}, duration=5.0})

			for i = 1, 8 do
				OpenCreepLane(i)
			end
		end

		if str == "-closelane_all" or str == "-cl_all" then
			--			Notifications:TopToAll({text="Host closed every lanes!", style={color="lightgreen"}, duration=5.0})

			for i = 1, 8 do
				CloseCreepLane(i)
			end
		end
	end

	local openlane_command = {
		"openlane",
		"ol",
	}

	for _, openlane in pairs(openlane_command) do
		local i, j = string.find(text, openlane .. "_%d")
		local lane = nil

		if i then
			lane = string.sub(text, i, j)
			local i, j = string.find(lane, "%d")
			lane = tonumber(string.sub(lane, i, j))

			if lane <= 8 then
				print("Opening lane:", lane)
				OpenLane(lane)
			end
		end
	end

	local closelane_command = {
		"closelane",
		"cl",
	}

	for _, closelane in pairs(closelane_command) do
		local i, j = string.find(text, closelane .. "_%d")
		local lane = nil

		if i then
			lane = string.sub(text, i, j)
			local i, j = string.find(lane, "%d")
			lane = tonumber(string.sub(lane, i, j))

			if lane <= 8 then
				print("Closing lane:", lane)
				CloseLane(hero:GetPlayerID(), lane)
			end
		end
	end
end, nil)

--DUNGEON
function GameMode:OnTriggerStartTouch(triggerName, activator_entindex, caller_entindex)
	--print("GameMode:OnTriggerStartTouch - " .. triggerName)
	local playerHero = EntIndexToHScript(activator_entindex)
	if playerHero and playerHero:IsRealHero() and playerHero:GetPlayerOwnerID() ~= -1 then
		--    local i, j = string.find(triggerName, "_zone_")
		--This is a zone transition trigger
		--    if i then
		--      local zone1Name = string.sub(triggerName, 1, i-1)
		--      local zone2Name = string.sub(triggerName, j+1, string.len(triggerName))
		--      print("Zone Transition: " .. zone1Name .. zone2Name)
		for _, zone in pairs(GameMode.Zones) do
			--        if zone and (zone.szName == zone1Name or zone.szName == zone2Name) then
			if zone and (zone.szName == "xhs_holdout") then
				zone:Precache()
			end
		end
		--    end

		local m, o = string.find(triggerName, "reveal_radius")
		if m then
			--print("triggerName == " .. triggerName)
			local TriggerEntity = EntIndexToHScript(caller_entindex)
			if TriggerEntity then
				local nRevealRadius = TriggerEntity:Attribute_GetIntValue("reveal_radius", 512)
				--  print("GameMode - Setting FOW Reveal Radius to " .. nRevealRadius)
				playerHero:SetRevealRadius(nRevealRadius)
			end
		end
	end
end

---------------------------------------------------------

function GameMode:OnTriggerEndTouch(triggerName, activator_entindex, caller_entindex)
	--print("GameMode:OnTriggerEndTouch - " .. triggerName)
	--This is a zone transition trigger
	-- print(activator_entindex, caller_entindex)

	if activator_entindex == nil then
		return
	end

	local playerHero = EntIndexToHScript(activator_entindex)

	if playerHero and playerHero:IsRealHero() and playerHero:GetPlayerOwnerID() ~= -1 then
		local i, j = string.find(triggerName, "_zone_")
		if i then
			local zone1Name = string.sub(triggerName, 1, i - 1)
			local zone2Name = string.sub(triggerName, j + 1, string.len(triggerName))

			local zone1 = self:GetZoneByName(zone1Name)
			local zone2 = self:GetZoneByName(zone2Name)
			if zone1 and zone1:ContainsUnit(playerHero) then
				self:OnPlayerHeroEnteredZone(playerHero, zone1.szName)
				return
			end
			if zone2 and zone2:ContainsUnit(playerHero) then
				self:OnPlayerHeroEnteredZone(playerHero, zone2.szName)
				return
			end
		end
	end
end

function GameMode:SetupZones()
	GameMode.Zones = {}
	--	PrintTable(ZonesDefinition, "  ")
	for _, zone in pairs(ZonesDefinition) do
		if zone then
			-- print("GameMode:SetupZones() - Setting up zone " .. zone.szName .. " from definition.")
			local newZone = CDungeonZone()
			newZone:Init(zone)
			table.insert(GameMode.Zones, newZone)
		end
	end
end

-- Cleanup a player when they leave
function GameMode:OnDisconnect(keys)
	local name = keys.name
	local networkid = keys.networkid
	local reason = keys.reason
	local userid = keys.userid

	--	CloseLane(userid)
end

-- A non-player entity (necro-book, chen creep, etc) used an ability
function GameMode:OnNonPlayerUsedAbility(keys)
	local abilityname = keys.abilityname
end

-- This function is called whenever a tower is killed
function GameMode:OnTowerKill(keys)
	local gold = keys.gold
	local killerPlayer = PlayerResource:GetPlayer(keys.killer_userid)
	local team = keys.teamnumber
end

-- This function is called whenever a player changes there custom team selection during Game Setup
function GameMode:OnPlayerSelectedCustomTeam(keys)
	local player = PlayerResource:GetPlayer(keys.player_id)
	local success = (keys.success == 1)
	local team = keys.team_id
end

---------------------------------------------------------
-- entity_killed
-- * entindex_killed
-- * entindex_attacker
-- * entindex_inflictor
-- * damagebits
---------------------------------------------------------

local function IsValidXHSTombstoneEntity(entity)
	return entity ~= nil and IsValidEntity(entity) and not entity:IsNull()
end

local XHS_TOMBSTONE_SPAWN_PARTICLE = "particles/units/heroes/hero_undying/undying_tombstone.vpcf"
local XHS_TOMBSTONE_AMBIENT_PARTICLE = "particles/econ/items/undying/fall20_undying_head/fall20_undying_tombstone_ambient.vpcf"

function XHSDestroyTombstoneDropEffects(drop)
	if not IsValidXHSTombstoneEntity(drop) then return end

	if drop.xhs_tombstone_ambient_particle ~= nil then
		ParticleManager:DestroyParticle(drop.xhs_tombstone_ambient_particle, false)
		ParticleManager:ReleaseParticleIndex(drop.xhs_tombstone_ambient_particle)
		drop.xhs_tombstone_ambient_particle = nil
	end
end

function XHSCleanupClaimedTombstoneDrops(hero, delay)
	if hero == nil or hero.xhs_tombstone_claimed_drops == nil then return end

	local claimedDrops = hero.xhs_tombstone_claimed_drops
	hero.xhs_tombstone_claimed_drops = nil
	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("xhs_tombstone_claimed_drop_cleanup"), function()
		for dropEntindex, _ in pairs(claimedDrops) do
			local numericEntindex = tonumber(dropEntindex)
			if numericEntindex ~= nil and numericEntindex > 0 then
				local drop = EntIndexToHScript(numericEntindex)
				if IsValidXHSTombstoneEntity(drop) then
					XHSDestroyTombstoneDropEffects(drop)
					UTIL_Remove(drop)
				end
			end
		end
		return nil
	end, math.max(0, tonumber(delay) or 0.2))
end

function XHSRemoveTombstoneGroundForHero(hero, cleanupClaimed)
	if hero == nil then return end

	local drop = hero.xhs_tombstone_drop
	local item = hero.xhs_tombstone_item
	hero.xhs_tombstone_drop = nil
	hero.xhs_tombstone_item = nil

	if IsValidXHSTombstoneEntity(drop) then
		XHSDestroyTombstoneDropEffects(drop)
		UTIL_Remove(drop)
	end
	if IsValidXHSTombstoneEntity(item) then
		UTIL_Remove(item)
	end
	if cleanupClaimed == true then
		XHSCleanupClaimedTombstoneDrops(hero, 0.2)
	end
end

function EnsureXHSTombstoneGroundDrop(hero, position)
	if not IsValidXHSTombstoneEntity(hero) or hero:IsAlive() then return nil, nil end
	if IsValidXHSTombstoneEntity(hero.xhs_tombstone_drop)
		and IsValidXHSTombstoneEntity(hero.xhs_tombstone_item) then
		return hero.xhs_tombstone_item, hero.xhs_tombstone_drop
	end

	XHSRemoveTombstoneGroundForHero(hero)

	local tombstonePosition = position or hero:GetAbsOrigin()
	tombstonePosition = Vector(tombstonePosition.x, tombstonePosition.y, tombstonePosition.z)
	local item = CreateItem("item_tombstone", hero, hero)
	if not IsValidXHSTombstoneEntity(item) then return nil, nil end

	item:SetPurchaseTime(0)
	item:SetPurchaser(hero)
	item.xhs_revive_hero_entindex = hero:entindex()
	item.xhs_tombstone_position = tombstonePosition

	local drop = SpawnEntityFromTableSynchronous("dota_item_tombstone_drop", {})
	if not IsValidXHSTombstoneEntity(drop) then
		UTIL_Remove(item)
		return nil, nil
	end

	drop:SetContainedItem(item)
	drop:SetAngles(0, RandomFloat(0, 360), 0)
	FindClearSpaceForUnit(drop, tombstonePosition, true)
	local dropPosition = drop:GetAbsOrigin()

	local spawnParticle = ParticleManager:CreateParticle(XHS_TOMBSTONE_SPAWN_PARTICLE, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(spawnParticle, 0, dropPosition)
	ParticleManager:ReleaseParticleIndex(spawnParticle)

	drop.xhs_tombstone_ambient_particle = ParticleManager:CreateParticle(
		XHS_TOMBSTONE_AMBIENT_PARTICLE,
		PATTACH_ABSORIGIN_FOLLOW,
		drop
	)

	item.xhs_tombstone_drop_entindex = drop:entindex()
	hero.xhs_tombstone_item = item
	hero.xhs_tombstone_drop = drop

	Timers:CreateTimer(0.5, function()
		if not IsValidXHSTombstoneEntity(hero) then
			if IsValidXHSTombstoneEntity(drop) then
				XHSDestroyTombstoneDropEffects(drop)
				UTIL_Remove(drop)
			end
			if IsValidXHSTombstoneEntity(item) then UTIL_Remove(item) end
			return nil
		end
		if hero.xhs_tombstone_item ~= item then return nil end
		if hero:IsAlive() then
			XHSRemoveTombstoneGroundForHero(hero)
			return nil
		end
		if not IsValidXHSTombstoneEntity(drop) and not IsValidXHSTombstoneEntity(item) then
			if hero.xhs_tombstone_item == item then
				hero.xhs_tombstone_drop = nil
				hero.xhs_tombstone_item = nil
			end
			return nil
		end
		return 0.5
	end)

	return item, drop
end

function SpawnXHSTombstoneForHero(hero, position)
	if not IsValidXHSTombstoneEntity(hero) or hero:IsAlive() then return nil, nil end

	XHSRemoveTombstoneGroundForHero(hero, true)
	if XHSClearTombstoneReviveState ~= nil then
		XHSClearTombstoneReviveState(hero)
	end
	local oldState = hero.xhs_tombstone_state
	if oldState ~= nil then
		for _, channelItem in pairs(oldState.channels or {}) do
			if IsValidXHSTombstoneEntity(channelItem) then
				channelItem.xhs_finish_handled = true
				local caster = channelItem:GetCaster()
				if IsValidXHSTombstoneEntity(caster) and channelItem:IsChanneling() then
					caster:InterruptChannel()
				end
				caster = channelItem:GetCaster()
				if IsValidXHSTombstoneEntity(caster) then
					for slot = 0, 14 do
						if caster:GetItemInSlot(slot) == channelItem then
							caster:RemoveItem(channelItem)
							break
						end
					end
				end
				if IsValidXHSTombstoneEntity(channelItem) then
					UTIL_Remove(channelItem)
				end
			end
		end
	end

	hero.xhs_tombstone_state = {
		channels = {},
		end_time = nil,
		completed = false,
	}
	return EnsureXHSTombstoneGroundDrop(hero, position)
end

-- Replace the legacy item-drop implementation above with a real allied unit.
-- Keeping the old functions in this file makes hot reloads with an already
-- claimed legacy item safe; the installed unit system owns every new death.
local XHSUnitTombstone = require("abilities/xhs_tombstone_revive")
XHSUnitTombstone:Install()

ListenToGameEvent('entity_killed', function(keys)
	local killedUnit = EntIndexToHScript(keys.entindex_killed)
	if killedUnit == nil then return end
	if killedUnit.xhs_silent_phase_one_lane_cleanup == true then
		-- Closed-lane structures are removed only to release entity/render cost.
		-- They grant no kill credit, quest progress, Revenants or Magnataurs.
		return
	end
	local killedUnitName = killedUnit.GetUnitName ~= nil and killedUnit:GetUnitName() or ""
	if killedUnit:FindModifierByName("modifier_breakable_container")
		or killedUnitName == "npc_dota_crate"
		or killedUnitName == "npc_dota_vase" then
		-- Breakables award their own loot, but never progress hero kill rewards,
		-- zone kill quests, Fragment Quests or event-unlock thresholds.
		return
	end
	-- local killerAbility = nil
	local killer = nil
	if keys.entindex_attacker ~= nil then killer = EntIndexToHScript(keys.entindex_attacker) end
	if not killer then killer = GameRules:GetGameModeEntity() end
	-- if keys.entindex_inflictor ~= nil then killerAbility = EntIndexToHScript(keys.entindex_inflictor) end
	local difficulty = GameRules:GetCustomGameDifficulty()
	local Zone = killedUnit.zone
	if FragmentQuests ~= nil then
		FragmentQuests:OnEntityKilled(killedUnit, killer)
	end
	if SpecialEvents ~= nil and SpecialEvents.OnFarmEventCreepKilled ~= nil then
		SpecialEvents:OnFarmEventCreepKilled(killedUnit)
	end

	if Zone then
		for _, zone in pairs(GameMode.Zones) do
			zone:OnEnemyKilled(killedUnit, Zone)
		end
	end

	if killedUnit:GetUnitName() == "npc_dota_hero_grom_hellscream" and not killedUnit:IsIllusion() then
		GameMode.XHSGromRealDefeated = true
		if killedUnit.phantasm_illusions ~= nil then
			for _, illusion in pairs(killedUnit.phantasm_illusions) do
				if illusion ~= nil and IsValidEntity(illusion) and not illusion:IsNull() and illusion:IsAlive() then
					illusion:Kill(nil, nil)
				end
			end

			killedUnit.phantasm_illusions = {}
		end
	end

	if killedUnit:IsRealHero() and (killedUnit:GetTeamNumber() == DOTA_TEAM_GOODGUYS) then
		if StartXHSDeadInventoryLock ~= nil then
			StartXHSDeadInventoryLock(killedUnit)
		end

		if FragmentQuests ~= nil then
			FragmentQuests:OnHeroDeath(killedUnit)
		end
		if DestroyXHSReturnMarker ~= nil then
			DestroyXHSReturnMarker(killedUnit)
		end
		if ReissueWaveCreepOrders ~= nil then
			ReissueWaveCreepOrders(0.5)
		end

		-- local netTable = {}
		--		CustomGameEventManager:Send_ServerToPlayer(killedUnit:GetPlayerOwner(), "life_lost", netTable)

		if killedUnit:GetUnitName() == "npc_dota_hero_tiny" then
			killedUnit:RemoveModifierByName("modifier_item_ultimate_scepter_consumed")
			killedUnit:RemoveModifierByName("modifier_animation_translate")
			-- Lone Druid Bear death debug
		elseif killedUnit:GetUnitName() == "npc_dota_hero_lone_druid" then
			local Bears = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false)
			for _, Bear in pairs(Bears) do
				for number = 1, 7 do
					if Bear and Bear:GetUnitName() == "npc_dota_lone_druid_bear" .. number then
						GameRules:GetGameModeEntity():SetContextThink("PreGame", function()
							Bear:RespawnUnit()
							return nil
						end, 0.03)

						GameRules:GetGameModeEntity():SetContextThink("PreGame", function()
							Bear:RespawnUnit()
							Bear:AddNewModifier(Bear, nil, "modifier_pause_creeps", { duration = 4.8 })
							return nil
						end, 0.17)
					end
				end
			end
		end

		--Drop Tombstone to be revived if dead after Castle Defense
		if CustomTimers.game_phase == 3 then
			if killedUnit.ankh_respawn ~= true then
				SpawnXHSTombstoneForHero(killedUnit, killedUnit:GetAbsOrigin())
			end
		end

		for _, Zone in pairs(GameMode.Zones) do
			if Zone:ContainsUnit(killedUnit) then
				Zone:AddStat(killedUnit:GetPlayerID(), ZONE_STAT_DEATHS, 1)
				killedUnit.DeathZone = Zone
			end
		end
		return
	elseif killedUnit:IsCreature() then
		if killedUnit:GetUnitName() == "npc_death_revenant_banehallow" and GameMode.BanehallowRevenantsRemaining ~= nil then
			GameMode.BanehallowRevenantsRemaining = math.max(0, GameMode.BanehallowRevenantsRemaining - 1)
			CustomGameEventManager:Send_ServerToAllClients("xhs_boss_counter_update", {
				boss_count = 1,
				label = "Ghost Revenants",
				remaining = GameMode.BanehallowRevenantsRemaining,
				total = GameMode.BanehallowRevenantsTotal or 12,
			})
		end

		if killedUnit:GetUnitName() == "npc_ramero" then
			SpecialEvents.RameroDead = true
			local rewardHero = GetPlayerHeroFromUnit(killer)
			if rewardHero ~= nil then
				SpecialEvents.RameroRewardHero = rewardHero
				SpecialEvents.RameroRewardPending = true
			end
		elseif killedUnit:GetUnitName() == "npc_baristol" then
			SpecialEvents.BaristolDead = true
			GameMode:HideOptionalEventBossBar("baristol", killedUnit)
			GrantTomeStatsToHero(killer, 250, "Tome Granted", "+250 all stats")
		elseif killedUnit:GetUnitName() == "npc_ramero_2" then
			local rewardHero = GetPlayerHeroFromUnit(killer)
			if rewardHero ~= nil then
				SpecialEvents.SogatRewardHero = rewardHero
				SpecialEvents.SogatRewardPending = true
			end
			DOOM_FIRST_TIME = true
			GameRules:GetGameModeEntity():SetContextThink("Sogat", nil, 0)
			SpecialEvents:EndSogatEvent(true)
		elseif killedUnit:GetUnitName() == "npc_dota_hero_secret" then
			local pos = killedUnit:GetAbsOrigin()
			DropNeutralItemAtPositionForHero("item_orb_of_frost", pos, killer, killer:GetTeam(), true)
			FROST_FIRST_TIME = true
		end

		if SpecialEvents.RameroDead == true and SpecialEvents.BaristolDead == true then
			SpecialEvents:EndRameroAndBaristolEvent(true)
		end

		if killedUnit:GetUnitName() == "npc_dota_creature_muradin_bronzebeard" and killedUnit:GetTeamNumber() ~= 2 then
			Notifications:TopToAll({ text = "Muradin is dead! All heroes in the arena level increase to maximum, killer earned 50 000 gold bounty.", duration = 5.0, style = { color = "lightgreen" } })
		end

		if killedUnit:GetUnitName() == "npc_dota_hero_magtheridon" then
			local difficulty = GameRules:GetCustomGameDifficulty()

			MAGTHERIDON = MAGTHERIDON + 1

			if MAGTHERIDON >= GetXHSMagtheridonKillLimit(difficulty) then
				GameMode.XHSPitLordDefeated = true
				if PlayMagtheridonFinalDeathSequence ~= nil then
					PlayMagtheridonFinalDeathSequence(killedUnit)
				end

				if XHSDevTools ~= nil and XHSDevTools:IsSandboxActive() then
					CustomGameEventManager:Send_ServerToAllClients("hide_boss_hp", { boss_count = 1 })
					CustomGameEventManager:Send_ServerToAllClients("hide_boss_hp", { boss_count = 2 })
					if XHSMagtheridon_HideBossTimer ~= nil then
						XHSMagtheridon_HideBossTimer(1)
						XHSMagtheridon_HideBossTimer(2)
					end
					if XHSMagtheridon_HideFragmentCounter ~= nil then
						XHSMagtheridon_HideFragmentCounter(1)
						XHSMagtheridon_HideFragmentCounter(2)
					end
					Notifications:TopToAll({ text = "Dev sandbox: Magtheridon cleared. Campaign progression blocked.", duration = 6.0 })
					XHSDevTools:PushState()
				else
					EndMagtheridonArena()
				end
			end
		end

		-- add kills to the hero who spawned a controlled unit, or an illusion
		if (killer and killer ~= GameRules:GetGameModeEntity()) and killer:IsRealHero() or (killer.IsIllusion and killer:IsIllusion()) or (killer.GetPlayerOwner and killer:GetPlayerOwner() and IsValidEntity(killer:GetPlayerOwner())) then
			if killer:GetTeamNumber() == 2 then
				if killedUnit:GetTeamNumber() == 6 then
					if killer:IsIllusion() then
						killer = PlayerResource:GetSelectedHeroEntity(killer:GetPlayerOwnerID())

						killer:IncrementKills(1)
						SpecialEvents:RefreshKillEventLeaderboard()
						if killer:GetKills() >= XHS_RAMERO_BARISTOL_KILLS_REQUIRED
							and SpecialEvents.Ramero_trigger == 0
							and not (XHSDevTools ~= nil and XHSDevTools:IsSandboxActive()) then
							SpecialEvents:StartRameroAndBaristolEvent(killer)
						end

						for _, Zone in pairs(GameMode.Zones) do
							if Zone:ContainsUnit(killer) then
								Zone:AddStat(killer:GetPlayerID(), ZONE_STAT_KILLS, 1)
							end
						end
					elseif IsValidEntity(killer:GetPlayerOwner()) then
						if PlayerResource:HasSelectedHero(killer:GetPlayerOwnerID()) then
							killer = PlayerResource:GetSelectedHeroEntity(killer:GetPlayerOwnerID())
						else
							return
						end

						--plays a particle and add a kill when a hero kills an enemy unit
						EmitSoundOnClient("Dungeon.LastHit", killer:GetPlayerOwner())
						ParticleManager:ReleaseParticleIndex(ParticleManager:CreateParticleForPlayer("particles/darkmoon_last_hit_effect.vpcf", PATTACH_ABSORIGIN_FOLLOW, killedUnit, killer:GetPlayerOwner()))

						killer:IncrementKills(1)
						SpecialEvents:RefreshKillEventLeaderboard()

						for _, Zone in pairs(GameMode.Zones) do
							if Zone:ContainsUnit(killer) then
								Zone:AddStat(killer:GetPlayerID(), ZONE_STAT_KILLS, 1)
							end
						end

						-- reward system based on kills, including kill events
						if killer:GetKills() == 50 then
							SendXHSRewardNotification(killer:GetPlayerOwnerID(), "gold", 7500, "Kill Reward", "+7,500 gold")
							PlayerResource:ModifyGold(killer:GetPlayerOwnerID(), 7500, false, DOTA_ModifyGold_Unspecified)
						elseif killer:GetKills() == 100 then
							SendXHSRewardNotification(killer:GetPlayerOwnerID(), "gold", 25000, "Kill Reward", "+25,000 gold")
							PlayerResource:ModifyGold(killer:GetPlayerOwnerID(), 25000, false, DOTA_ModifyGold_Unspecified)
						elseif killer:GetKills() == 200 then
							SendXHSRewardNotification(killer:GetPlayerOwnerID(), "gold", 50000, "Kill Reward", "+50,000 gold")
							PlayerResource:ModifyGold(killer:GetPlayerOwnerID(), 50000, false, DOTA_ModifyGold_Unspecified)
						elseif killer:GetKills() >= XHS_RAMERO_BARISTOL_KILLS_REQUIRED and SpecialEvents.Ramero_trigger == 0 and not (XHSDevTools ~= nil and XHSDevTools:IsSandboxActive()) then
							SpecialEvents:StartRameroAndBaristolEvent(killer)
						elseif killer:GetKills() >= XHS_SOGAT_KILLS_REQUIRED and SpecialEvents.Ramero_trigger == 1 and not (XHSDevTools ~= nil and XHSDevTools:IsSandboxActive()) then
							SpecialEvents:StartSogatEvent(killer)
						end
					end
				end
			end
		end

		return
	elseif killedUnit:IsBuilding() then
		local targetName = killedUnit.GetName ~= nil and killedUnit:GetName() or ""
		local destroyedLane = tonumber(string.match(targetName, "^dota_badguys_barracks_(%d+)$"))
		if destroyedLane ~= nil and XHSRefreshPhaseOneLaneStructureState ~= nil then
			XHSRefreshPhaseOneLaneStructureState(destroyedLane)
		end

		if killedUnit:GetTeamNumber() == 2 then
			if killedUnit:GetClassname() == "npc_dota_fort" then
				GameRules:SetGameWinner(3)
			end
		elseif killedUnit:GetTeamNumber() == 3 then
			if killer and killer:IsIllusion() then
				killer = PlayerResource:GetPlayer(killer:GetPlayerID()):GetAssignedHero()
				killer:IncrementKills(1)

				for _, Zone in pairs(GameMode.Zones) do
					if Zone:ContainsUnit(killer) then
						Zone:AddStat(killer:GetPlayerID(), ZONE_STAT_KILLS, 1)
					end
				end
			elseif IsValidEntity(killer:GetPlayerOwner()) then
				if killer and killer:IsRealHero() then
					EmitSoundOnClient("Dungeon.LastHit", killer:GetPlayerOwner())
					ParticleManager:ReleaseParticleIndex(ParticleManager:CreateParticleForPlayer("particles/darkmoon_last_hit_effect.vpcf", PATTACH_ABSORIGIN_FOLLOW, killedUnit, killer:GetPlayerOwner()))
					if PlayerResource:HasSelectedHero(killer:GetPlayerOwnerID()) then
						killer:IncrementKills(1)
					end
					for _, Zone in pairs(GameMode.Zones) do
						if Zone:ContainsUnit(killer) then
							Zone:AddStat(killer:GetPlayerID(), ZONE_STAT_KILLS, 1)
						end
					end
				end
			end
		end

		if killedUnit:IsTower() then
			if killedUnit:GetUnitName() == "xhs_tower_lane_1" then
				for j = 1, difficulty do
					if SpawnReleasedPhaseOneCreep ~= nil then
						SpawnReleasedPhaseOneCreep("xhs_death_revenant", killedUnit:GetAbsOrigin())
					else
						CreateUnitByName("xhs_death_revenant", killedUnit:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
					end
				end
				-- CREEP_LANES[lane][2] = CREEP_LANES[lane][2] + 1
				-- Notifications:TopToAll({text="Creep lane "..lane.." is now level "..CREEP_LANES[lane][2].."!", duration=5.0, style={color="lightgreen"}})
			elseif killedUnit:GetUnitName() == "xhs_tower_lane_2" then
				for j = 1, difficulty do
					if SpawnReleasedPhaseOneCreep ~= nil then
						SpawnReleasedPhaseOneCreep("xhs_death_revenant_2", killedUnit:GetAbsOrigin())
					else
						CreateUnitByName("xhs_death_revenant_2", killedUnit:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
					end
				end
				-- CREEP_LANES[lane][2] = CREEP_LANES[lane][2] + 1
				-- Notifications:TopToAll({text="Creep lane "..lane.." is now level "..CREEP_LANES[lane][2].."!", duration=5.0, style={color="lightgreen"}})
			end
		elseif killedUnit:IsAncient() then
			local castle_shop = Entities:FindByName(nil, "castle_shop")

			if castle_shop then
				print("Ancient destroyed, removed secret shop")
				castle_shop:RemoveSelf()
			end
		end
	end
	--	print("EntityKilled: Not Hero or Creature or Building.")
end, nil)

---------------------------------------------------------
-- dota_player_gained_level
-- * player (player entity index)
-- * level (new level)
---------------------------------------------------------

function GameMode:OnPlayerGainedLevel(event)

end

---------------------------------------------------------
-- dota_item-spawned
-- * player_id
-- * item_ent_index
---------------------------------------------------------

function GameMode:OnItemSpawned(event)
	local item = EntIndexToHScript(event.item_ent_index)
	if item then
		local bIsRelic = false
		local itemKV = item:GetAbilityKeyValues()
		if itemKV and itemKV["DungeonItemDef"] then
			item.bIsRelic = true
		end

		if item.bIsRelic and item.nBoundPlayerID == nil and item:GetPurchaser() == nil and event.player_id == -1 then
			print("GameMode:OnItemSpawned - Relic Found")
			self:OnRelicSpawned(item, itemKV)
		end
	end
end

---------------------------------------------------------
-- dota_player_reconnected
-- * player_id
---------------------------------------------------------

--[[
ListenToGameEvent("player_reconnected", function(event)
--	OpenLane(event.player_id)
end, nil)
--]]
---------------------------------------------------------
-- entity_killed
-- * entindex_killed
-- * entindex_attacker
-- * entindex_inflictor
-- * damagebits
---------------------------------------------------------

---------------------------------------------------------
-- dota_holdout_revive_complete
-- * caster (reviver hero entity index)
-- * target (revivee hero entity index)
---------------------------------------------------------

function GameMode:OnPlayerRevived(event)
	if type(event) ~= "table" then return end
	local revivedIndex = tonumber(event.target or event.entindex_target or event.revived_entindex)
	if revivedIndex == nil or revivedIndex <= 0 then return end

	local hRevivedHero = EntIndexToHScript(revivedIndex)
	if hRevivedHero == nil or hRevivedHero:IsNull() or not hRevivedHero:IsRealHero() then return end
	if StopXHSDeadInventoryLock ~= nil then
		StopXHSDeadInventoryLock(hRevivedHero)
	end

	hRevivedHero:AddNewModifier(hRevivedHero, nil, "modifier_invulnerable", { duration = 2.5 })
	hRevivedHero:AddNewModifier(hRevivedHero, nil, "modifier_omninight_guardian_angel", { duration = 2.5 })
	EmitSoundOn("Dungeon.HeroRevived", hRevivedHero)

	local reviverIndex = tonumber(event.caster or event.entindex_caster or event.reviver_entindex)
	local hReviver = reviverIndex ~= nil and reviverIndex > 0 and EntIndexToHScript(reviverIndex) or nil
	local flChannelTime = tonumber(event.channel_time) or 0
	if hReviver ~= nil and not hReviver:IsNull() and flChannelTime > 0.0 then
		for _, Zone in pairs(GameMode.Zones) do
			if Zone:ContainsUnit(hReviver) then
				Zone:AddStat(hReviver:GetPlayerID(), ZONE_STAT_REVIVE_TIME, flChannelTime)
			end
		end
	end
end

function GameMode:OnRelicSpawned(item, itemKV)
	local PlayerIDs = {}
	local nRelicItemDef = tonumber(itemKV["DungeonItemDef"])
	print("GameMode:OnRelicSpawned - New Relic " .. item:GetAbilityName() .. " created of itemdef: " .. nRelicItemDef)
	for _, Hero in pairs(HeroList:GetAllHeroes()) do
		if Hero ~= nil and Hero:IsRealHero() and Hero:HasOwnerAbandoned() == false then
			if GetItemDefOwnedCount(Hero:GetPlayerID(), nRelicItemDef) == 0 then
				print("GameMode:OnRelicSpawned - PlayerID " .. Hero:GetPlayerID() .. " does not own item, adding to grant list.")
				table.insert(PlayerIDs, Hero:GetPlayerID())
			end
		end
	end

	-- What do we do if it's empty?  Right now just give it to someone as a dupe?
	local bDupeForAllPlayers = #PlayerIDs == 0
	if bDupeForAllPlayers then
		for _, Hero in pairs(Heroes) do
			if Hero ~= nil and Hero:IsRealHero() then
				table.insert(PlayerIDs, Hero:GetPlayerID())
			end
		end
	end

	local WinningPlayerID = PlayerIDs[RandomInt(1, #PlayerIDs)]
	local WinningHero = PlayerResource:GetSelectedHeroEntity(WinningPlayerID)
	local WinningSteamID = PlayerResource:GetSteamID(WinningPlayerID)

	print("GameMode:OnRelicSpawned - Relic " .. item:GetAbilityName() .. " has been bound to " .. WinningPlayerID)
	item.nBoundPlayerID = WinningPlayerID
	item:SetPurchaser(WinningHero)

	EmitSoundOn("Dungeon.Stinger06", WinningHero)
	local Relic = {}
	Relic["DungeonItemDef"] = itemKV["DungeonItemDef"]
	Relic["DungeonAction"] = itemKV["DungeonAction"]
	Relic["SteamID"] = WinningSteamID
	table.insert(self.RelicsFound, Relic)

	local gameEvent = {}
	gameEvent["player_id"] = WinningHero:GetPlayerID()
	gameEvent["team_number"] = DOTA_TEAM_GOODGUYS
	gameEvent["locstring_value"] = "#DOTA_Tooltip_Ability_" .. item:GetAbilityName()
	gameEvent["message"] = "#Dungeon_FoundNewRelic"
	FireGameEvent("dota_combat_event_message", gameEvent)
end

---------------------------------------------------------

function GameMode:OnPlayerHeroEnteredZone(playerHero, zoneName)
	if not playerHero:GetPlayerOwner() then return end

	-- print("GameMode:OnPlayerHeroEnteredZone - PlayerHero " .. playerHero:GetUnitName() .. " entered " .. zoneName)

	local netTable = {}
	netTable["ZoneName"] = zoneName
	CustomGameEventManager:Send_ServerToPlayer(playerHero:GetPlayerOwner(), "zone_enter", netTable)
end

---------------------------------------------------------

function GameMode:OnZoneActivated(Zone)
	--	print("GameMode:OnZoneActivated")
	for _, zone in pairs(GameMode.Zones) do
		zone:OnZoneActivated(Zone)
	end

	--	if Zone.szName == "forest_holdout" then
	--		local hTowers = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BUILDING, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false)
	--		for _,Tower in pairs(hTowers) do
	--			if Tower ~= nil and Tower:GetUnitName() == "npc_dota_holdout_tower" then
	--				Tower:RemoveAbility("building_no_vision")
	--				Tower:RemoveModifierByName("modifier_no_vision")
	--			end
	--		end
	--	end
end

---------------------------------------------------------

function GameMode:OnZoneEventComplete(Zone)
	print("GameMode:OnZoneEventComplete")
	for _, zone in pairs(GameMode.Zones) do
		zone:OnZoneEventComplete(Zone)
	end
end

---------------------------------------------------------

function GameMode:OnQuestStarted(zone, quest)
	--	print("GameMode:OnQuestStarted - Quest " .. quest.szQuestName .. " in Zone " .. zone.szName .. " started.")
	local bDevSandbox = XHSDevTools ~= nil and XHSDevTools:IsSandboxActive()
	if quest.szQuestName == "kill_mag" then
		quest.nCompleteLimit = GetXHSMagtheridonKillLimit()
	elseif quest.szQuestName == "clear_grom_vanguard" then
		quest.nCompleteLimit = GetXHSGromVanguardKillLimit()
	elseif quest.szQuestName == "kill_dest_mag" then
		quest.nCompleteLimit = GetXHSDestroyerMagnataurKillLimit()
	end

	quest.bActivated = true
	if XHSActivatePhase3BossEncounter ~= nil then
		XHSActivatePhase3BossEncounter(quest.szQuestName)
	end
	self:StartQuestBossVision(quest.szQuestName)

	if bDevSandbox ~= true then
		for _, zone in pairs(GameMode.Zones) do
			zone:OnQuestStarted(quest)
		end
	end

	if quest.Completion.Type == QUEST_EVENT_ON_DIALOG or quest.Completion.Type == QUEST_EVENT_ON_DIALOG_ALL_CONFIRMED then
		local hDialogEntities = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false)
		for _, DialogEnt in pairs(hDialogEntities) do
			if DialogEnt ~= nil and DialogEnt:GetUnitName() == quest.Completion.szNPCName and DialogEnt:FindModifierByName("modifier_npc_dialog_notify") == nil then
				if DialogEnt:FindModifierByName("modifier_invulnerable") then
					DialogEnt:RemoveModifierByName("modifier_invulnerable")
				end

				print("DIALOG: Adding modifier: modifier_npc_dialog_notify")
				DialogEnt:AddNewModifier(DialogEnt, nil, "modifier_npc_dialog_notify", {})
			end
		end
	end

	local netTable = {}
	netTable["ZoneName"] = zone.szName
	netTable["QuestName"] = quest.szQuestName
	netTable["QuestType"] = quest.szQuestType
	netTable["Completed"] = quest.nCompleted
	netTable["CompleteLimit"] = quest.nCompleteLimit
	netTable["Optional"] = quest.bOptional

	CustomGameEventManager:Send_ServerToAllClients("quest_activated", netTable)
end

---------------------------------------------------------

local XHS_QUEST_FOCUS_TARGETS = {
	teleport_top = "npc_xhs_paladin",
	teleport_arthas = "npc_xhs_paladin_2",
	kill_grom = "npc_dota_hero_grom_hellscream",
	kill_illidan = "npc_dota_hero_illidan",
	kill_balanar = "npc_dota_hero_balanar",
	kill_proudmoore = "npc_dota_hero_proudmoore",
	free_uther = "npc_xhs_uther_ice_prison",
}

local XHS_BOSS_QUEST_VISION_TARGETS = {
	kill_mag = "npc_dota_hero_magtheridon",
	kill_grom = "npc_dota_hero_grom_hellscream",
	kill_illidan = "npc_dota_hero_illidan",
	kill_balanar = "npc_dota_hero_balanar",
	kill_proudmoore = "npc_dota_hero_proudmoore",
	kill_arthas = "npc_dota_hero_arthas",
	kill_banehallow = "npc_dota_hero_banehallow",
	kill_lich_king = "npc_dota_boss_lich_king",
	kill_spirit_master = "npc_dota_boss_spirit_master",
}

local XHS_BOSS_QUEST_FOW_RADIUS = 500
local XHS_BOSS_QUEST_FOW_DURATION = 0.75
local XHS_BOSS_QUEST_FOW_INTERVAL = 0.5

local function FindXHSQuestTargetUnits(targetName)
	local targets = {}
	if targetName == nil then return targets end

	local units = FindUnitsInRadius(
		DOTA_TEAM_GOODGUYS,
		Vector(0, 0, 0),
		nil,
		FIND_UNITS_EVERYWHERE,
		DOTA_UNIT_TARGET_TEAM_BOTH,
		DOTA_UNIT_TARGET_ALL,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
		FIND_ANY_ORDER,
		false
	)

	for _, unit in pairs(units) do
		if unit ~= nil and IsValidEntity(unit) and not unit:IsNull() and unit:IsAlive() and unit:GetUnitName() == targetName then
			table.insert(targets, unit)
		end
	end

	return targets
end

function GameMode:StartQuestBossVision(questName)
	local targetName = questName and XHS_BOSS_QUEST_VISION_TARGETS[questName]
	if targetName == nil or Timers == nil then return end

	self.XHSQuestBossVisionWatchers = self.XHSQuestBossVisionWatchers or {}
	if self.XHSQuestBossVisionWatchers[questName] == true then return end
	local watchers = self.XHSQuestBossVisionWatchers
	watchers[questName] = true

	Timers:CreateTimer(0.0, function()
		if GameMode:IsQuestActive(questName) ~= true then
			watchers[questName] = nil
			return nil
		end

		for _, unit in pairs(FindXHSQuestTargetUnits(targetName)) do
			AddFOWViewer(DOTA_TEAM_GOODGUYS, unit:GetAbsOrigin(), XHS_BOSS_QUEST_FOW_RADIUS, XHS_BOSS_QUEST_FOW_DURATION, false)
		end

		return XHS_BOSS_QUEST_FOW_INTERVAL
	end)
end

function GameMode:OnQuestFocusRequested(_, event)
	local playerID = event and event.PlayerID
	local questName = event and event.quest_id
	local targetName = questName and XHS_QUEST_FOCUS_TARGETS[questName]
	if playerID == nil or targetName == nil then return end

	local player = PlayerResource:GetPlayer(playerID)
	if player == nil then return end
	if GameMode:IsQuestActive(questName) ~= true then return end

	local playerHero = PlayerResource:GetSelectedHeroEntity(playerID)
	local targetUnit = nil
	local targetDistance = nil
	for _, unit in pairs(FindXHSQuestTargetUnits(targetName)) do
		if unit ~= nil and IsValidEntity(unit) and not unit:IsNull() then
			local distance = 0
			if playerHero ~= nil and IsValidEntity(playerHero) and not playerHero:IsNull() then
				distance = (unit:GetAbsOrigin() - playerHero:GetAbsOrigin()):Length2D()
			end
			if targetUnit == nil or distance < targetDistance then
				targetUnit = unit
				targetDistance = distance
			end
		end
	end

	if targetUnit ~= nil then
		CameraMotion:Sequence(playerID, {
			{
				type = "move",
				to = targetUnit,
				from = playerHero,
				duration = 0.55,
				easing = "smootherstep",
			},
			{ type = "hold",    duration = 1.70 },
			{
				type = "return",
				to = function()
					return PlayerResource:GetSelectedHeroEntity(playerID)
				end,
				duration = 0.65,
				easing = "smootherstep",
			},
			{ type = "release", mode = "free" },
		}, {
			owner = "quest_focus:" .. tostring(questName),
			priority = 10,
			policy = "replace",
		})
	end
end

function GameMode:OnCameraFocusEntityRequested(_, event)
	local playerID = event and tonumber(event.PlayerID) or -1
	local entIndex = event and math.floor(tonumber(event.entindex) or -1) or -1
	if playerID < 0 or entIndex <= 0 or CameraMotion == nil then return end
	if not PlayerResource:IsValidPlayerID(playerID) or PlayerResource:GetPlayer(playerID) == nil then return end

	local target = EntIndexToHScript(entIndex)
	if target == nil or not IsValidEntity(target) or target:IsNull() or target.GetAbsOrigin == nil then return end

	CameraMotion:Move(playerID, target, {
		from = PlayerResource:GetSelectedHeroEntity(playerID),
		duration = 0.4,
		easing = "smootherstep",
		owner = "manual_entity_focus",
		priority = 10,
		policy = "replace",
		-- This is a user-initiated move from a freely panned client camera.
		-- Always wait for the fresh client look-at handshake, even if another
		-- camera request still considers its dummy captured.
		origin_mode = "provider",
		release = "free",
	})
end

---------------------------------------------------------

local XHS_MAIN_QUEST_NOTIFICATIONS = {
	kill_rax = {
		phase = "Phase 1",
		title = "Castle Defense Complete",
		subtitle = "The siege has been held. Prepare for the Destroyer Magnataurs.",
		sound = "Dungeon.Stinger01",
	},
	kill_ice_towers = {
		phase = "Final Wave",
		title = "Castle Breach Sealed",
		subtitle = "Return to the castle and survive the last assault.",
		sound = "Dungeon.Stinger01",
	},
	kill_final_wave = {
		phase = "Phase 2 Finished",
		title = "Final Wave Cleared",
		subtitle = "The castle is safe. Advance to the enemy leaders.",
		sound = "Dungeon.Stinger01",
	},
	clear_grom_vanguard = {
		phase = "Phase 3",
		title = "Grom's Vanguard Broken",
		subtitle = "The way to Grom Hellscream is open.",
		sound = "Dungeon.Stinger01",
	},
}

function GameMode:OnQuestCompleted(questZone, quest)
	--	print("GameMode:OnQuestCompleted - Quest " .. quest.szQuestName .. " in Zone " .. questZone.szName .. " completed.")
	local bDevSandbox = XHSDevTools ~= nil and XHSDevTools:IsSandboxActive()
	local bQuestPreviouslyCompleted = quest.bCompleted == true
	quest.nCompleted = quest.nCompleted + 1
	if quest.nCompleted >= quest.nCompleteLimit then
		quest.bCompleted = true
	end

	local bZonePreviouslyCompleted = questZone.bZoneCompleted

	if quest.bOptional ~= true and bDevSandbox ~= true then
		questZone:CheckForZoneComplete()
	end

	if quest.bCompleted == true then
		if bDevSandbox ~= true then
			for _, zone in pairs(GameMode.Zones) do
				zone:OnQuestCompleted(quest)
			end
		end

		if quest.Completion.Type == QUEST_EVENT_ON_DIALOG or quest.Completion.Type == QUEST_EVENT_ON_DIALOG_ALL_CONFIRMED then
			local hDialogEntities = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false)
			for _, DialogEnt in pairs(hDialogEntities) do
				if DialogEnt ~= nil and DialogEnt:GetUnitName() == quest.Completion.szNPCName and DialogEnt:FindModifierByName("modifier_npc_dialog_notify") then
					DialogEnt:RemoveModifierByName("modifier_npc_dialog_notify")
				end
			end
		end

		local hLogicRelay = Entities:FindByName(nil, quest.szCompletionLogicRelay)
		if hLogicRelay and bDevSandbox ~= true then
			hLogicRelay:Trigger()
		end

		for _, Hero in pairs(HeroList:GetAllHeroes()) do
			if Hero ~= nil and Hero:IsRealHero() and Hero:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
				if quest.RewardXP ~= nil and quest.RewardXP > 0 then
					Hero:AddExperience(quest.RewardXP, DOTA_ModifyXP_Unspecified, false, true)
				end
				if quest.RewardGold ~= nil and quest.RewardGold > 0 then
					Hero:ModifyGold(quest.RewardGold, true, DOTA_ModifyGold_Unspecified)
				end
			end
		end

		if bDevSandbox == true then
			Notifications:TopToAll({ text = "Dev sandbox: quest completed without campaign follow-up.", duration = 4.0 })
			if XHSDevTools ~= nil then
				XHSDevTools:PushState()
			end
		elseif quest.szQuestName == "kill_dest_mag" then
			if FragmentQuests ~= nil then
				FragmentQuests:OnPhase2End()
			end

			if bQuestPreviouslyCompleted == false then
				Notifications:TopToAll({ text = "Phase 2 Creeps enabled!", style = { color = "lightgreen" }, duration = 5.0 })
			end

			-- Timers remain paused until magnataurs are killed. The farm-exit
			-- recovery path may already have advanced to phase two; keep this quest
			-- callback idempotent so late destroyer deaths cannot skip to phase 3.
			local currentPhase = CustomTimers ~= nil
				and (tonumber(CustomTimers.game_phase) or 0) or 0
			if currentPhase < 2 then
				StartPhase2()
			elseif CustomTimers ~= nil and currentPhase == 2 then
				CustomTimers.timers_paused = 0
			end
		elseif quest.szQuestName == "kill_final_wave" then
			if FragmentQuests ~= nil then
				FragmentQuests:OnFinalWaveEnd()
			end

			StopGlobalSound("XHS.FinalWaveMusic")

			if XHSSetGlobalObjectiveState ~= nil then
				XHSSetGlobalObjectiveState("final_wave", "Completed", "Final Wave completed")
			else
				CustomGameEventManager:Send_ServerToAllClients("xhs_global_objective_update", {
					id = "final_wave",
					state = "Completed",
					text = "Final Wave completed",
				})
			end

			if CustomTimers ~= nil and CustomTimers.game_phase < 3 then
				CustomTimers:IncrementGamePhase()
			end

			if bQuestPreviouslyCompleted == false and Timers ~= nil then
				Timers:CreateTimer(1.5, function()
					if XHSFocusPlayersOnShalLightbinder ~= nil then
						XHSFocusPlayersOnShalLightbinder()
					end
					return nil
				end)
			end
		elseif quest.szQuestName == "clear_grom_vanguard" then
			if OpenGromGate ~= nil then
				OpenGromGate()
			end
		elseif quest.szQuestName == "kill_proudmoore" then
			if XHSActivateUtherIcePrison ~= nil then
				XHSActivateUtherIcePrison()
			end
		elseif quest.szQuestName == "free_uther" then
			if XHSReleaseUtherFromIce ~= nil then
				XHSReleaseUtherFromIce()
			end
		elseif quest.szQuestName == "teleport_top" then
			StartMagtheridonArena()
		elseif quest.szQuestName == "teleport_arthas" then
			FourBossesKillCount()
			-- Uther's prison now opens the last Proudmoore gate. His dialog only
			-- authorizes the next encounter, so it cannot leave him trapped behind it.
			if XHSOpenProudmooreFinalDoor ~= nil then XHSOpenProudmooreFinalDoor() end
			Timers:CreateTimer(2.5, StartArthasArena)
		end
	end

	local netTable = {}
	netTable["ZoneName"] = questZone.szName
	netTable["QuestName"] = quest.szQuestName
	netTable["QuestType"] = quest.szQuestType
	netTable["Completed"] = quest.nCompleted
	netTable["CompleteLimit"] = quest.nCompleteLimit
	netTable["XPReward"] = quest.RewardXP or 0
	netTable["GoldReward"] = quest.RewardGold or 0
	netTable["ZoneCompleted"] = bZonePreviouslyCompleted == false and questZone.bZoneCompleted == true
	netTable["Optional"] = quest.bOptional
	netTable["ZoneStars"] = questZone.nStars

	CustomGameEventManager:Send_ServerToAllClients("quest_completed", netTable)

	if bQuestPreviouslyCompleted == false and quest.bCompleted == true and XHS_MAIN_QUEST_NOTIFICATIONS[quest.szQuestName] ~= nil then
		local notification = XHS_MAIN_QUEST_NOTIFICATIONS[quest.szQuestName]
		CustomGameEventManager:Send_ServerToAllClients("xhs_main_quest_completed", {
			phase = notification.phase,
			title = notification.title,
			subtitle = notification.subtitle,
			sound = notification.sound,
			duration = 6.5,
		})
	end
end

---------------------------------------------------------

function GameMode:OnDialogBegin(hPlayerHero, hDialogEnt)
	local Dialog = self:GetDialog(hDialogEnt)

	if Dialog == nil then
		print("GameMode:OnDialogBegin - ERROR: No Dialog found for " .. hDialogEnt:GetUnitName())
		return
	end

	if GameMode.bConfirmPending == true then
		print("GameMode:OnDialogBegin - Cannot dialog, a confirm dialog is pending.")
		return
	end

	if Dialog.szRequireQuestActive ~= nil then
		if self:IsQuestActive(Dialog.szRequireQuestActive) == false then
			print("GameMode:OnDialogBegin - Required Active Quest for dialog line not active.")
			return
		end
	end

	local bShowAdvanceDialogButton = true
	local NextDialog = self:GetDialogLine(hDialogEnt, hDialogEnt.nCurrentLine + 1)
	if Dialog.bPlayersConfirm == true or NextDialog == nil or Dialog.bForceBreak == true then
		bShowAdvanceDialogButton = false
	end

	local netTable = {}
	netTable["DialogEntIndex"] = hDialogEnt:entindex()
	netTable["PlayerHeroEntIndex"] = hPlayerHero:entindex()
	netTable["DialogText"] = Dialog.szText
	netTable["DialogAdvanceTime"] = Dialog.flAdvanceTime
	netTable["DialogLine"] = hDialogEnt.nCurrentLine
	netTable["ShowAdvanceButton"] = bShowAdvanceDialogButton
	netTable["SendToAll"] = Dialog.bSendToAll
	netTable["DialogPlayerConfirm"] = Dialog.bPlayersConfirm
	netTable["ConfirmToken"] = Dialog.szConfirmToken
	netTable["JournalEntry"] = hDialogEnt:FindAbilityByName("ability_journal_note") ~= nil

	hDialogEnt:RemoveModifierByName("modifier_npc_dialog_notify")

	for _, zone in pairs(GameMode.Zones) do
		zone:OnDialogBegin(hDialogEnt)
	end

	if Dialog.bPlayersConfirm == true then
		GameMode.bConfirmPending = true
	end

	local cinematicId = "xhs_dialog_" .. tostring(hDialogEnt:entindex())
	local cinematicOptions = {
		hide_hud = true,
		allow_dialog_ui = true,
		lock_orders = true,
		camera_entindex = hDialogEnt:entindex(),
		camera_speed = 0.5,
		transition = 0.35,
	}
	if Dialog.bSendToAll == true then
		XHSCinematics:BeginForAll(cinematicId, cinematicOptions)
	else
		XHSCinematics:BeginForPlayer(hPlayerHero:GetPlayerID(), cinematicId, cinematicOptions)
	end

	if Dialog.bSkipFacePlayer ~= true then
		hDialogEnt.vOriginalFaceDir = hDialogEnt:GetOrigin() + hDialogEnt:GetForwardVector() * 50
		hDialogEnt:FaceTowards(hPlayerHero:GetOrigin())
	end

	if Dialog.Gesture ~= nil then
		hDialogEnt:StartGesture(Dialog.Gesture)
	end

	if Dialog.Sound ~= nil then
		EmitSoundOn(Dialog.Sound, hDialogEnt)
	end

	if Dialog.bAdvance == true then
		hDialogEnt.nCurrentLine = hDialogEnt.nCurrentLine + 1
	end

	if Dialog.szGiveItemName ~= nil then
		local newItem = CreateItem(Dialog.szGiveItemName, nil, nil)
		if hPlayerHero:HasAnyAvailableInventorySpace() then
			hPlayerHero:AddItem(newItem)
		else
			if newItem ~= nil then
				local dropTarget = hPlayerHero:GetAbsOrigin() + RandomVector(RandomFloat(50, 150))
				DropNeutralItemAtPositionForHero(Dialog.szGiveItemName, dropTarget, hPlayerHero, hPlayerHero:GetTeam(), true)
			end
		end
	end

	if Dialog.bDialogStopsMovement == true then
		hDialogEnt:SetMoveCapability(DOTA_UNIT_CAP_MOVE_NONE)
	end

	if hDialogEnt:FindAbilityByName("ability_journal_note") ~= nil then
		local szJournalNumber = string.match(Dialog.szText, "chef_journal_(%d+)");
		if szJournalNumber ~= nil then
			local nJournalNumber = tonumber(szJournalNumber);
			local nPlayerID = hPlayerHero:GetPlayerID()
			--			self:OnPlayerFoundChefNote(nPlayerID, nJournalNumber)
		end
	end

	if Dialog.bSendToAll == true then
		CustomGameEventManager:Send_ServerToAllClients("dialog", netTable)
	else
		CustomGameEventManager:Send_ServerToPlayer(hPlayerHero:GetPlayerOwner(), "dialog", netTable)
	end
end

---------------------------------------------------------

function GameMode:OnDialogEnded(eventSourceIndex, data)
	local hDialogEnt = EntIndexToHScript(data.DialogEntIndex)
	local hPlayerHero = EntIndexToHScript(data.PlayerHeroEntIndex)
	local nDialogLine = data.DialogLine
	local bShowNextLine = data.ShowNextLine

	if hDialogEnt ~= nil and nDialogLine ~= nil then
		local Dialog = self:GetDialogLine(hDialogEnt, nDialogLine)
		if Dialog ~= nil then
			if Dialog.bSkipFacePlayer ~= true then
				hDialogEnt:StopFacing()
				hDialogEnt:FaceTowards(hDialogEnt.vOriginalFaceDir)
			end

			if Dialog.Gesture ~= nil then
				hDialogEnt:FadeGesture(Dialog.Gesture)
			end

			if Dialog.bDialogStopsMovement then
				hDialogEnt:SetMoveCapability(DOTA_UNIT_CAP_MOVE_GROUND)
			end

			if Dialog.OrderOnDialogEnd ~= nil then
				Dialog.OrderOnDialogEnd.UnitIndex = hDialogEnt:entindex()
				ExecuteOrderFromTable(Dialog.OrderOnDialogEnd)
			end
			if Dialog.InitialGoalEntity ~= nil then
				local hWaypoint = Entities:FindByName(nil, Dialog.InitialGoalEntity)
				if hWaypoint ~= nil then
					hDialogEnt:SetInitialGoalEntity(hWaypoint)
				end
			end
			if Dialog.szLogicRelay ~= nil then
				local hLogicRelay = Entities:FindByName(nil, Dialog.szLogicRelay)
				if hLogicRelay then
					hLogicRelay:Trigger()
				end
			end
		end

		if bShowNextLine == 1 and hPlayerHero then
			self:OnDialogBegin(hPlayerHero, hDialogEnt)
		else
			local cinematicId = "xhs_dialog_" .. tostring(hDialogEnt:entindex())
			if Dialog ~= nil and Dialog.bSendToAll == true then
				XHSCinematics:EndForAll(cinematicId)
			elseif hPlayerHero ~= nil then
				XHSCinematics:EndForPlayer(hPlayerHero:GetPlayerID(), cinematicId)
			end
		end
	end
end

---------------------------------------------------------

function GameMode:OnBossFightIntro(hBoss)
	local Dialog = self:GetDialog(hBoss)
	if Dialog == nil then
		print("GameMode:OnBossFightIntro - ERROR: No Dialog found for boss " .. hBoss:GetUnitName())
		return
	end

	if Dialog.bAdvance == true then
		hBoss.nCurrentLine = hBoss.nCurrentLine + 1
	end

	if Dialog.Gesture ~= nil then
		hBoss:StartGesture(Dialog.Gesture)
		hBoss.CurrentGesture = Dialog.Gesture
	end

	if Dialog.Sound ~= nil then
		EmitSoundOn(Dialog.Sound, hBoss)
	end

	if hBoss:FindModifierByName("modifier_temple_guardian_statue") ~= nil then
		hBoss:AddNewModifier(hBoss, nil, "modifier_invulnerable", { duration = Dialog.flAdvanceTime })
		hBoss:RemoveModifierByName("modifier_temple_guardian_statue")
	end


	local netTable = {}
	netTable["DialogText"] = Dialog.szText
	netTable["BossName"] = hBoss:GetUnitName()
	netTable["BossEntIndex"] = hBoss:entindex()
	netTable["BossIntroTime"] = Dialog.flAdvanceTime
	netTable["CameraPitch"] = Dialog.flCameraPitch
	netTable["CameraDistance"] = Dialog.flCameraDistance
	netTable["CameraLookAtHeight"] = Dialog.flCameraLookAtHeight
	netTable["SkipIntro"] = Dialog.bSkipBossIntro

	hBoss.bStarted = true
	hBoss.flIntroEndTime = GameRules:GetGameTime() + Dialog.flAdvanceTime
	hBoss.bIntroComplete = false

	local hFriendlyHero = nil
	if Dialog.bSkipBossIntro == false then
		local units = FindUnitsInRadius(hBoss:GetTeamNumber(), hBoss:GetOrigin(), hBoss, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, 0, false)
		for _, unit in pairs(units) do
			if unit ~= nil and unit ~= hBoss then
				unit:AddNewModifier(hBoss, nil, "modifier_boss_intro", { duration = netTable["BossIntroTime"] })
				if unit:IsRealHero() and unit:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
					hFriendlyHero = unit
				end
			end
		end
	end

	CustomGameEventManager:Send_ServerToAllClients("boss_intro_begin", netTable)

	hBoss:AddNewModifier(hFriendlyHero, nil, "modifier_provide_vision", {})
	hBoss:AddNewModifier(hBoss, nil, "modifier_boss_intro", { duration = netTable["BossIntroTime"] })
	hBoss:AddNewModifier(hBoss, nil, "modifier_followthrough", { duration = netTable["BossIntroTime"] + 1.0 })
end

---------------------------------------------------------

function GameMode:OnBossFightIntroEnd(hBoss)
	CustomGameEventManager:Send_ServerToAllClients("boss_intro_end", netTable)

	if hBoss ~= nil then
		local units = FindUnitsInRadius(hBoss:GetTeamNumber(), hBoss:GetOrigin(), hBoss, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, 0, false)
		for _, unit in pairs(units) do
			if unit ~= nil and unit ~= hBoss then
				unit:RemoveModifierByName("modifier_boss_intro")
			end
		end

		--hBoss:RemoveModifierByName("modifier_provide_vision")
		hBoss:RemoveModifierByName("modifier_boss_intro")
		hBoss:RemoveGesture(hBoss.CurrentGesture)
		if hBoss:GetUnitName() == "npc_dota_creature_temple_guardian" then
			hBoss:RemoveGesture(ACT_DOTA_CAST_ABILITY_7)
		end

		for _, Hero in pairs(HeroList:GetAllHeroes()) do
			if Hero ~= nil and Hero:IsRealHero() and Hero:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
				local hPlayer = Hero:GetPlayerOwner()
				if hPlayer ~= nil then
					hPlayer:SetMusicStatus(2, 1.0) -- turn on battle music
				end
			end
		end
	end
end

---------------------------------------------------------

function GameMode:OnTreasureOpen(hPlayerHero, hTreasureEnt)
	print("OnTreasureOpen()")

	self:ChooseTreasureSurprise(hPlayerHero, hTreasureEnt)


	--hTreasureEnt:Destroy()
end

---------------------------------------------------------

function GameMode:UpdateGameEndTables()
	local metadataTable = {}
	metadataTable["event_name"] = "siltbreaker"
	metadataTable["map_name"] = "ep_1"

	metadataTable["zones"] = {}

	local trophyLevel = 0

	local signoutTable = {}
	signoutTable["zone_stars"] = {}
	signoutTable["chef_notes"] = self.ChefNotesFound;
	signoutTable["invoker_found"] = self.InvokerFound;

	for _, zone in pairs(GameMode.Zones) do
		if not zone.bNoLeaderboard and zone.flCompletionTime > 0 then
			local zoneTable = {}

			zoneTable["zone_id"] = zone.nZoneID
			zoneTable["completed"] = zone.bZoneCompleted
			zoneTable["stars"] = zone.nStars
			zoneTable["kills"] = zone.nKills
			zoneTable["deaths"] = zone.nDeaths
			zoneTable["items"] = zone.nItems
			zoneTable["gold_bags"] = zone.nGoldBags
			zoneTable["potions"] = zone.nPotions
			zoneTable["revive_time"] = zone.nReviveTime
			zoneTable["damage"] = zone.nDamage
			zoneTable["healing"] = zone.nHealing
			zoneTable["completion_time"] = zone.flCompletionTime

			metadataTable["zones"][zone.szName] = zoneTable

			if (zone.nZoneID == 13) then
				trophyLevel = zone.nStars
				if (trophyLevel == 0) then
					trophyLevel = 1
				end
			end
		end

		if zone.nStars > 0 then
			signoutTable["zone_stars"][zone.nZoneID] = zone.nStars
		end
	end

	--	if #self.RelicsFound > 0 then
	--		signoutTable[ "relics_found" ] = self.RelicsFound
	--	end

	if trophyLevel > 0 then
		signoutTable["trophy_id"] = 63
		signoutTable["trophy_level"] = trophyLevel
	end

	local hasXHSBotSession = false
	if api ~= nil and api.HasXHSBotSession ~= nil then
		hasXHSBotSession = api:HasXHSBotSession()
	elseif api ~= nil and api.HasXHSBotParticipants ~= nil then
		hasXHSBotSession = api:HasXHSBotParticipants()
	end
	if hasXHSBotSession then
		return
	end

	GameRules:SetEventMetadataCustomTable(metadataTable)
	GameRules:SetEventSignoutCustomTable(signoutTable)
end

---------------------------------------------------------

function GameMode:OnZoneCompleted(zone)
	print("GameMode:OnZoneCompleted - Zone " .. zone.szName .. " has been completed with " .. zone.nStars .. " stars ")

	self:UpdateGameEndTables();
end

---------------------------------------------------------

function GameMode:OnGameFinished()
	print("GameMode:OnGameFinished")

	self:UpdateGameEndTables()
end

---------------------------------------------------------

function GameMode:OnScrollClicked(eventSourceIndex, data)
	local hPlayerHero = EntIndexToHScript(data.ent_index)

	if hPlayerHero then
		hPlayerHero.bHasClickedScroll = true
	end
end

---------------------------------------------------------

local function ResolveAuthenticatedPersistentPlayerID(eventSourceIndex)
	local playerID = XHSResolveEventPlayerID ~= nil and XHSResolveEventPlayerID(eventSourceIndex) or nil

	if playerID == nil and api ~= nil and api.GetEventPlayerID ~= nil then
		local ok, resolvedPlayerID = pcall(function()
			return api:GetEventPlayerID(eventSourceIndex, nil)
		end)
		if ok then
			playerID = tonumber(resolvedPlayerID)
		end
	elseif playerID == nil and CustomGameEventManager ~= nil
		and CustomGameEventManager.GetPlayerIDFromEventSourceIndex ~= nil then
		local ok, resolvedPlayerID = pcall(function()
			return CustomGameEventManager:GetPlayerIDFromEventSourceIndex(eventSourceIndex)
		end)
		if ok then
			playerID = tonumber(resolvedPlayerID)
		end
	elseif playerID == nil and tonumber(eventSourceIndex) ~= nil and tonumber(eventSourceIndex) > 0 then
		-- Compatibility fallback for engine builds without
		-- GetPlayerIDFromEventSourceIndex. The event source is authoritative;
		-- payload PlayerID/nPlayerID is deliberately never consulted.
		local ok, resolvedPlayerID = pcall(function()
			local sender = EntIndexToHScript(tonumber(eventSourceIndex))
			return sender ~= nil and sender.GetPlayerID ~= nil and sender:GetPlayerID() or nil
		end)
		if ok then
			playerID = tonumber(resolvedPlayerID)
		end
	end

	if playerID == nil or playerID < 0 or not PlayerResource:IsValidPlayerID(playerID) then
		return nil
	end

	if api ~= nil and api.IsPersistentPlayerID ~= nil then
		return api:IsPersistentPlayerID(playerID) and playerID or nil
	end
	if IsXHSPersistentPlayerID ~= nil then
		return IsXHSPersistentPlayerID(playerID) and playerID or nil
	end
	if PlayerResource.IsFakeClient ~= nil and PlayerResource:IsFakeClient(playerID) then
		return nil
	end

	return playerID
end

function GameMode:OnDialogConfirm(eventSourceIndex, data)
	data = data or {}
	local playerID = ResolveAuthenticatedPersistentPlayerID(eventSourceIndex)
	if playerID == nil or data.ConfirmToken == nil then return end

	GameMode.DialogConfirmPlayers = GameMode.DialogConfirmPlayers or {}
	GameMode.DialogConfirmPlayers[data.ConfirmToken] = GameMode.DialogConfirmPlayers[data.ConfirmToken] or {}
	if GameMode.DialogConfirmPlayers[data.ConfirmToken][playerID] then return end
	GameMode.DialogConfirmPlayers[data.ConfirmToken][playerID] = true

	if GameMode.DialogConfirmCount[data.ConfirmToken] == nil then
		GameMode.DialogConfirmCount[data.ConfirmToken] = 1
	else
		GameMode.DialogConfirmCount[data.ConfirmToken] = GameMode.DialogConfirmCount[data.ConfirmToken] + 1
	end

	local netTable = {}
	netTable["PlayerID"] = playerID
	CustomGameEventManager:Send_ServerToAllClients("dialog_player_confirm", netTable)

	local nValid = 0;
	for iPlayer = 0, 23 do
		local eligible = api ~= nil and api.IsPersistentPlayerID ~= nil
			and api:IsPersistentPlayerID(iPlayer)
			or api == nil and IsXHSPersistentPlayerID ~= nil
			and IsXHSPersistentPlayerID(iPlayer)
		if eligible then
			nValid = nValid + 1
		end
	end

	--	print("Check if everyone accepted dialog...")
	--	print(GameMode.DialogConfirmCount[data.ConfirmToken], nValid)

	if GameMode.DialogConfirmCount[data.ConfirmToken] >= nValid then
		local netTable = {}
		for _, zone in pairs(GameMode.Zones) do
			zone:OnDialogAllConfirmed(EntIndexToHScript(data["DialogEntIndex"]), data["DialogLine"])
		end
		CustomGameEventManager:Send_ServerToAllClients("dialog_player_all_confirmed", netTable)
		GameMode.bConfirmPending = false
	end
end

---------------------------------------------------------

function GameMode:OnDialogConfirmExpired(eventSourceIndex, data)
	data = data or {}
	if ResolveAuthenticatedPersistentPlayerID(eventSourceIndex) == nil then return end

	if data.ConfirmToken then
		GameMode.DialogConfirmCount[data.ConfirmToken] = 4
	end

	for _, zone in pairs(GameMode.Zones) do
		zone:OnDialogAllConfirmed(EntIndexToHScript(data["DialogEntIndex"]), data["DialogLine"])
	end

	CustomGameEventManager:Send_ServerToAllClients("dialog_player_all_confirmed", netTable)
	GameMode.bConfirmPending = false
end

---------------------------------------------------------

function GameMode:OnRelicClaimed(eventSourceIndex, data)
	data = data or {}
	local nPlayerID = ResolveAuthenticatedPersistentPlayerID(eventSourceIndex)
	local szClaimedRelicName = data["ClaimedRelicName"]
	if nPlayerID ~= nil and szClaimedRelicName ~= nil then
		print("GameMode:OnRelicClaimed - Player " .. nPlayerID .. " is trying to claim relic " .. szClaimedRelicName)
		local relicTable = CustomNetTables:GetTableValue("relics", string.format("%d", nPlayerID))
		if relicTable ~= nil then
			for k, v in pairs(relicTable) do
				if v ~= nil and v == szClaimedRelicName then
					local Hero = PlayerResource:GetSelectedHeroEntity(nPlayerID)
					if Hero ~= nil then
						if Hero:HasAnyAvailableInventorySpace() then
							local newRelic = CreateItem(szClaimedRelicName, Hero, Hero)
							newRelic:SetPurchaseTime(GameRules:GetGameTime())
							newRelic:SetPurchaser(Hero)
							newRelic.bIsRelic = true
							newRelic.nBoundPlayerID = nPlayerID
							Hero:AddItem(newRelic)
						else
							local dropTarget = Hero:GetAbsOrigin() + RandomVector(RandomFloat(50, 150))
							DropNeutralItemAtPositionForHero(szClaimedRelicName, dropTarget, Hero, Hero:GetTeam(), true)
						end

						relicTable[k] = nil
						CustomNetTables:SetTableValue("relics", string.format("%d", nPlayerID), relicTable)
					end
				end
			end
		end
	end
end

---------------------------------------------------------

function GameMode:OnPlayerFoundChefNote(nPlayerID, nChefNoteIndex)
	--	self:TrackPlayerAchievementEvent(self.ChefNotesFound, nPlayerID, nChefNoteIndex)
end
