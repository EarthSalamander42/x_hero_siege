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
		if Gold then
			Gold:Init()
		end

		for i = 1, 8 do
			DoEntFire("door_lane" .. i, "SetAnimation", "gate_02_close", 0, nil, nil)
		end

		if GetMapName() ~= "x_hero_siege_demo" then
			-- debug
			--			if IsInToolsMode() then
			Entities:FindByName(nil, "trigger_special_event_tp_off"):Disable()
			Entities:FindByName(nil, "trigger_special_event"):Enable()
			--			end
		end

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

		for NumPlayers = 1, PlayerResource:GetPlayerCount() * CREEP_LANES_TYPE do
			CREEP_LANES[NumPlayers][1] = 1
			local DoorObs = Entities:FindAllByName("obstruction_lane" .. NumPlayers)
			for _, obs in pairs(DoorObs) do
				obs:SetEnabled(false, true)
			end
			DoEntFire("door_lane" .. NumPlayers, "SetAnimation", "gate_02_open", 0, nil, nil)
			local towers = Entities:FindAllByName("dota_badguys_tower" .. NumPlayers)
			for _, tower in pairs(towers) do
				tower:RemoveModifierByName("modifier_invulnerable")
			end
		end
	end
end, nil)

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
-- An NPC has spawned somewhere in game. This includes heroes
ListenToGameEvent('npc_spawned', function(keys)
	local difficulty = GameRules:GetCustomGameDifficulty()
	local npc = EntIndexToHScript(keys.entindex)
	local normal_bounty = npc:GetGoldBounty()
	local normal_xp = npc:GetDeathXP()
	local normal_min_damage = npc:GetBaseDamageMin()
	local normal_max_damage = npc:GetBaseDamageMax()
	local hero_level = npc:GetLevel()

	if GetMapName() == "x_hero_siege_8" then
		local normal_bounty = npc:GetGoldBounty() * 2
		local normal_xp = npc:GetDeathXP() * 2
	end

	if npc and IsValidEntity(npc) then
		--ALL NPC
		for i = 1, #innate_abilities do
			local current_ability = npc:FindAbilityByName(innate_abilities[i])
			if current_ability then
				current_ability:SetLevel(1)
			end
		end

		if npc:GetTeamNumber() ~= 2 or npc:GetUnitName() == "npc_dota_creature_muradin_bronzebeard" then
			local unit_kv = GetUnitKeyValuesByName(npc:GetUnitName())

			if unit_kv and unit_kv["UseAI"] then
				npc:AddNewModifier(npc, nil, "modifier_ai", { state = unit_kv["UseAI"] })
			end
		end

		if npc:GetUnitName() == "npc_dota_hero_magtheridon" then
			-- in case there are 2, wait for npc.boss_count

			GameRules:GetGameModeEntity():SetContextThink("PreGame", function()
				ShowBossBar(npc)
				return nil
			end, 0.1)
		end

		-- HERO NPC
		if npc:IsRealHero() and npc:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
			if npc.bFirstSpawnComplete == nil then
				npc:AddNewModifier(npc, nil, "modifier_custom_mechanics", {})

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

		for i = 0, 17 do
			local ability = hero:GetAbilityByIndex(i)

			if IsValidEntity(ability) then
				if ability:GetLevel() < ability:GetMaxLevel() then
					for j = 1, ability:GetMaxLevel() - ability:GetLevel() do
						hero:UpgradeAbility(ability)
					end
				end
			end
		end

		if AbilitiesHeroes_XX[hero:GetUnitName()] then
			hero.lvl_20 = true
			Notifications:Bottom(hero:GetPlayerOwnerID(), { text = "You've reached level 20. Check out your new abilities! ", duration = 10 })
			for _, ability in pairs(AbilitiesHeroes_XX[hero:GetUnitName()]) do
				if ability ~= nil then
					Notifications:Bottom(hero:GetPlayerOwnerID(), { ability = ability[1], continue = true })
					hero:AddAbility(ability[1])
					hero:UpgradeAbility(hero:FindAbilityByName(ability[1]))
					local oldab = hero:GetAbilityByIndex(ability[2])
					if oldab:GetAutoCastState() then
						oldab:ToggleAutoCast()
					end
					hero:SwapAbilities(oldab:GetName(), ability[1], true, true)
				end
			end
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
		if donator_level == 1 or donator_level == 2 or donator_level == 3 or IsInToolsMode() then
			for Frozen = 0, PlayerResource:GetPlayerCount() - 1 do
				local PlayerNames = { "Red", "Blue", "Cyan", "Purple", "Yellow", "Orange", "Green", "Pink" }
				if PlayerResource:IsValidPlayer(Frozen) then
					if str == "-freeze_" .. Frozen + 1 then
						local hero = PlayerResource:GetPlayer(Frozen):GetAssignedHero()
						hero:AddNewModifier(hero, nil, "modifier_pause_creeps", {})
						hero:AddNewModifier(hero, nil, "modifier_invulnerable", {})
						PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), hero)
						Notifications:TopToAll({ text = "[ADMIN MOD]: ", duration = 6.0, style = { color = "red", ["font-size"] = "30px" } })
						Notifications:TopToAll({ text = PlayerNames[Frozen + 1] .. " ", style = { color = PlayerNames[Frozen + 1], ["font-size"] = "25px" }, continue = true })
						Notifications:TopToAll({ text = "player has been jailed!", style = { color = "white", ["font-size"] = "25px" }, continue = true })
					end
					if str == "-unfreeze_" .. Frozen + 1 then
						local hero = PlayerResource:GetPlayer(Frozen):GetAssignedHero()
						hero:RemoveModifierByName("modifier_pause_creeps")
						hero:RemoveModifierByName("modifier_pause_creeps")
						hero:RemoveModifierByName("modifier_invulnerable")
						hero:RemoveModifierByName("modifier_command_restricted")
						PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), nil)
						Notifications:TopToAll({ text = "[ADMIN MOD]: ", duration = 6.0, style = { color = "red", ["font-size"] = "30px" } })
						Notifications:TopToAll({ text = PlayerNames[Frozen + 1] .. " ", style = { color = PlayerNames[Frozen + 1], ["font-size"] = "25px" }, continue = true })
						Notifications:TopToAll({ text = "player has been released!", style = { color = "white", ["font-size"] = "25px" }, continue = true })
					end
					if str == "-kill_" .. Frozen + 1 then
						local hero = PlayerResource:GetPlayer(Frozen):GetAssignedHero()
						if hero:IsAlive() then
							hero:Kill(nil, nil)
							Notifications:TopToAll({ text = "[ADMIN MOD]: ", duration = 6.0, style = { color = "red", ["font-size"] = "30px" } })
							Notifications:TopToAll({ text = PlayerNames[Frozen + 1] .. " ", style = { color = PlayerNames[Frozen + 1], ["font-size"] = "25px" }, continue = true })
							Notifications:TopToAll({ text = "player has been slayed!", style = { color = "white", ["font-size"] = "25px" }, continue = true })
						end
					end
					if str == "-revive_" .. Frozen + 1 then
						local hero = PlayerResource:GetPlayer(Frozen):GetAssignedHero()
						hero:RespawnHero(false, false)
						Notifications:TopToAll({ text = "[ADMIN MOD]: ", duration = 6.0, style = { color = "red", ["font-size"] = "30px" } })
						Notifications:TopToAll({ text = PlayerNames[Frozen + 1] .. " ", style = { color = PlayerNames[Frozen + 1], ["font-size"] = "25px" }, continue = true })
						Notifications:TopToAll({ text = "player has been revived!", style = { color = "white", ["font-size"] = "25px" }, continue = true })
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
						Notifications:TopToAll({ text = "[ADMIN MOD]: ", duration = 6.0, style = { color = "red", ["font-size"] = "30px" } })
						Notifications:TopToAll({ text = PlayerNames[Frozen + 1] .. " ", style = { color = PlayerNames[Frozen + 1], ["font-size"] = "25px" }, continue = true })
						Notifications:TopToAll({ text = "player is in YOLO state!", style = { color = "white", ["font-size"] = "25px" }, continue = true })
					end
					if str == "-unyolo_" .. Frozen + 1 then
						local hero = PlayerResource:GetPlayer(Frozen):GetAssignedHero()
						hero:SetMoveCapability(DOTA_UNIT_CAP_MOVE_GROUND)
						EndAnimation(hero)
						hero:StopSound("Hero_Batrider.Firefly.Loop")
						ParticleManager:DestroyParticle(yolo, true)
						ParticleManager:DestroyParticle(yolo2, true)
						Notifications:TopToAll({ text = "[ADMIN MOD]: ", duration = 6.0, style = { color = "red", ["font-size"] = "30px" } })
						Notifications:TopToAll({ text = PlayerNames[Frozen + 1] .. " ", style = { color = PlayerNames[Frozen + 1], ["font-size"] = "25px" }, continue = true })
						Notifications:TopToAll({ text = "player is not in YOLO state anymore.", style = { color = "white", ["font-size"] = "25px" }, continue = true })
					end
				end
			end

			if str == "-replaceherowith" then
				text = string.gsub(text, str, "")
				text = string.gsub(text, " ", "")

				if PlayerResource:GetSelectedHeroName(hero:GetPlayerID()) ~= "npc_dota_hero_" .. text then
					--					if KeyValues.HeroKV["npc_dota_hero_"..text] then
					PrecacheUnitByNameAsync("npc_dota_hero_" .. text, function()
						local wisp = PlayerResource:GetSelectedHeroEntity(hero:GetPlayerID())
						PlayerResource:ReplaceHeroWith(hero:GetPlayerID(), "npc_dota_hero_" .. text, 0, 0)

						GameRules:GetGameModeEntity():SetContextThink("PreGame", function()
							if wisp then
								UTIL_Remove(wisp)
							end

							return nil
						end, 1.0)
					end, userID)
					-- else
					-- 	Notifications:TopToAll({text="Hero don't exist!", duration=6.0, style={color="red", ["font-size"]="30px"}})
					-- end
				end
			end
		end

		if str == "-bt" then
			if GameRules:IsGamePaused() then
				SendErrorMessage(hero:GetPlayerID(), "#error_buy_tome_pause")
				return
			end

			local hero = player:GetAssignedHero()
			local gold = Gold:GetGold(userID)
			local cost = 10000
			local numberOfTomes = math.floor(gold / cost)

			if BT_ENABLED == 1 then
				if numberOfTomes < 1 then
					SendErrorMessage(hero:GetPlayerID(), "#error_cant_afford_tomes")
					return
				end

				local i = 0

				Notifications:Bottom(player, { text = "You've bought " .. numberOfTomes .. " Tomes!", duration = 5.0, style = { color = "white" } })
				PlayerResource:SpendGold(player:GetPlayerID(), (numberOfTomes) * cost, DOTA_ModifyGold_PurchaseItem)

				GameRules:GetGameModeEntity():SetContextThink("PreGame", function()
					hero:IncrementAttributes(50)
					hero:EmitSound("ui.trophy_levelup")

					local pfx = ParticleManager:CreateParticle("particles/generic_hero_status/hero_levelup.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero, hero)
					ParticleManager:SetParticleControl(pfx, 0, hero:GetAbsOrigin())

					i = i + 1

					if i >= numberOfTomes then
						return nil
					else
						return 0.1
					end
				end, FrameTime())
			elseif BT_ENABLED == 0 then
				SendErrorMessage(hero:GetPlayerID(), "#error_buy_tome_disabled")
			end
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
				print("Opening lane:", lane)
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

ListenToGameEvent('entity_killed', function(keys)
	local killedUnit = EntIndexToHScript(keys.entindex_killed)
	if killedUnit == nil then return end
	if killedUnit:FindModifierByName("modifier_breakable_container") then return end
	local killerAbility = nil
	local killer = nil
	if keys.entindex_attacker ~= nil then killer = EntIndexToHScript(keys.entindex_attacker) end
	if not killer then killer = GameRules:GetGameModeEntity() end
	if keys.entindex_inflictor ~= nil then killerAbility = EntIndexToHScript(keys.entindex_inflictor) end
	local difficulty = GameRules:GetCustomGameDifficulty()
	local Zone = killedUnit.zone

	if Zone then
		for _, zone in pairs(GameMode.Zones) do
			zone:OnEnemyKilled(killedUnit, Zone)
		end
	end

	if killedUnit:IsRealHero() and (killedUnit:GetTeamNumber() == DOTA_TEAM_GOODGUYS) then
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
			if killedUnit.ankh_respawn == true then
			else
				local newItem = CreateItem("item_tombstone", killedUnit, killedUnit)
				newItem:SetPurchaseTime(0)
				newItem:SetPurchaser(killedUnit)
				local tombstone = SpawnEntityFromTableSynchronous("dota_item_tombstone_drop", {})
				tombstone:SetContainedItem(newItem)
				tombstone:SetAngles(0, RandomFloat(0, 360), 0)
				FindClearSpaceForUnit(tombstone, killedUnit:GetAbsOrigin(), true)
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
		local ramero_check = 0
		if killedUnit:GetUnitName() == "npc_ramero" then
			DropNeutralItemAtPositionForHero("item_lightning_sword", killedUnit:GetAbsOrigin(), killer, killer:GetTeam(), true)
			ramero_check = ramero_check + 1
		elseif killedUnit:GetUnitName() == "npc_baristol" then
			local hero = killer

			if not killer:IsRealHero() then
				hero = killer:GetPlayerOwner():GetAssignedHero()
			end

			if hero then
				hero:IncrementAttributes(250)
			end

			ramero_check = ramero_check + 1
		elseif killedUnit:GetUnitName() == "npc_ramero_2" then
			DropNeutralItemAtPositionForHero("item_ring_of_superiority", killedUnit:GetAbsOrigin(), killer, killer:GetTeam(), true)
			DOOM_FIRST_TIME = true
			GameRules:GetGameModeEntity():SetContextThink("Sogat", nil, 0)
		elseif killedUnit:GetUnitName() == "npc_dota_hero_secret" then
			local pos = killedUnit:GetAbsOrigin()
			DropNeutralItemAtPositionForHero("item_orb_of_frost", pos, killer, killer:GetTeam(), true)
			FROST_FIRST_TIME = true
		end

		if ramero_check == 2 then
			GameRules:GetGameModeEntity():SetContextThink("RameroAndBaristol", nil, 0)
		end

		if killedUnit:GetUnitName() == "npc_dota_creature_muradin_bronzebeard" and killedUnit:GetTeamNumber() ~= 2 then
			Notifications:TopToAll({ text = "Muradin is dead! All heroes in the arena level increase to maximum, killer earned 50 000 gold bounty.", duration = 5.0, style = { color = "lightgreen" } })
		end

		if killedUnit:GetUnitName() == "npc_dota_hero_magtheridon" then
			local difficulty = GameRules:GetCustomGameDifficulty()

			MAGTHERIDON = MAGTHERIDON + 1

			if MAGTHERIDON > 0 and difficulty == 1 then
				EndMagtheridonArena()
			elseif MAGTHERIDON > 1 and difficulty == 2 then
				EndMagtheridonArena()
			elseif MAGTHERIDON > 3 and difficulty == 3 then
				EndMagtheridonArena()
			elseif MAGTHERIDON > 3 and difficulty == 4 then
				EndMagtheridonArena()
			elseif MAGTHERIDON > 5 and difficulty == 5 then
				EndMagtheridonArena()
			end
		end

		-- add kills to the hero who spawned a controlled unit, or an illusion
		if (killer and killer ~= GameRules:GetGameModeEntity()) and killer:IsRealHero() or (killer.IsIllusion and killer:IsIllusion()) or (killer.GetPlayerOwner and killer:GetPlayerOwner() and IsValidEntity(killer:GetPlayerOwner())) then
			if killer:GetTeamNumber() == 2 then
				if killedUnit:GetTeamNumber() == 6 then
					if killer:IsIllusion() then
						killer = PlayerResource:GetSelectedHeroEntity(killer:GetPlayerOwnerID())

						killer:IncrementKills(1)

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

						for _, Zone in pairs(GameMode.Zones) do
							if Zone:ContainsUnit(killer) then
								Zone:AddStat(killer:GetPlayerID(), ZONE_STAT_KILLS, 1)
							end
						end

						-- reward system based on kills, including kill events
						if killer:GetKills() == 99 then
							Notifications:Bottom(killer:GetPlayerOwnerID(), { text = "100 kills. You get 7500 gold.", duration = 5.0, style = { color = "yellow" } })
							PlayerResource:ModifyGold(killer:GetPlayerOwnerID(), 7500, false, DOTA_ModifyGold_Unspecified)
						elseif killer:GetKills() == 199 then
							Notifications:Bottom(killer:GetPlayerOwnerID(), { text = "200 kills. You get 25000 gold.", duration = 5.0, style = { color = "yellow" } })
							PlayerResource:ModifyGold(killer:GetPlayerOwnerID(), 25000, false, DOTA_ModifyGold_Unspecified)
						elseif killer:GetKills() == 399 then
							Notifications:Bottom(killer:GetPlayerOwnerID(), { text = "400 kills. You get 50000 gold.", duration = 5.0, style = { color = "yellow" } })
							PlayerResource:ModifyGold(killer:GetPlayerOwnerID(), 50000, false, DOTA_ModifyGold_Unspecified)
						elseif killer:GetKills() >= 499 and SpecialEvents.Ramero_trigger == 0 then --500
							SpecialEvents:StartRameroAndBaristolEvent(killer)
						elseif killer:GetKills() >= 749 and SpecialEvents.Ramero_trigger == 1 then --750
							SpecialEvents:StartSogatEvent(killer)
						end
					end
				end
			end
		end

		return
	elseif killedUnit:IsBuilding() then
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
					CreateUnitByName("xhs_death_revenant", killedUnit:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
				end
				-- CREEP_LANES[lane][2] = CREEP_LANES[lane][2] + 1
				-- Notifications:TopToAll({text="Creep lane "..lane.." is now level "..CREEP_LANES[lane][2].."!", duration=5.0, style={color="lightgreen"}})
			elseif killedUnit:GetUnitName() == "xhs_tower_lane_2" then
				for j = 1, difficulty do
					CreateUnitByName("xhs_death_revenant_2", killedUnit:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
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
	local hRevivedHero = EntIndexToHScript(event.target)

	print("GameMode:OnPlayerRevived")
	if hRevivedHero ~= nil and hRevivedHero:IsRealHero() then
		hRevivedHero:AddNewModifier(hRevivedHero, nil, "modifier_invulnerable", { duration = 2.5 })
		hRevivedHero:AddNewModifier(hRevivedHero, nil, "modifier_omninight_guardian_angel", { duration = 2.5 })
		EmitSoundOn("Dungeon.HeroRevived", hRevivedHero)

		local hReviver = EntIndexToHScript(event.caster)
		local flChannelTime = event.channel_time
		if hReviver ~= nil and flChannelTime > 0.0 then
			for _, Zone in pairs(GameMode.Zones) do
				if Zone:ContainsUnit(hReviver) then
					Zone:AddStat(hReviver:GetPlayerID(), ZONE_STAT_REVIVE_TIME, flChannelTime)
				end
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
	quest.bActivated = true

	for _, zone in pairs(GameMode.Zones) do
		zone:OnQuestStarted(quest)
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

function GameMode:OnQuestCompleted(questZone, quest)
	--	print("GameMode:OnQuestCompleted - Quest " .. quest.szQuestName .. " in Zone " .. questZone.szName .. " completed.")
	quest.nCompleted = quest.nCompleted + 1
	if quest.nCompleted >= quest.nCompleteLimit then
		quest.bCompleted = true
	end

	local bZonePreviouslyCompleted = questZone.bZoneCompleted

	if quest.bOptional ~= true then
		questZone:CheckForZoneComplete()
	end

	if quest.bCompleted == true then
		for _, zone in pairs(GameMode.Zones) do
			zone:OnQuestCompleted(quest)
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
		if hLogicRelay then
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

		if quest.szQuestName == "kill_dest_mag" then
			-- timers remains paused until magnataurs are killed
			StartPhase2()
		elseif quest.szQuestName == "teleport_top" then
			StartMagtheridonArena()
		elseif quest.szQuestName == "teleport_arthas" then
			StartArthasArena()
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
	if Dialog.bPlayersConfirm == true or NextDialog == nil or NextDialog.bPlayersConfirm == true or Dialog.bForceBreak == true then
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

function GameMode:OnDialogConfirm(eventSourceIndex, data)
	if GameMode.DialogConfirmCount[data.ConfirmToken] == nil then
		GameMode.DialogConfirmCount[data.ConfirmToken] = 1
	else
		GameMode.DialogConfirmCount[data.ConfirmToken] = GameMode.DialogConfirmCount[data.ConfirmToken] + 1
	end

	local netTable = {}
	netTable["PlayerID"] = data.nPlayerID
	CustomGameEventManager:Send_ServerToAllClients("dialog_player_confirm", netTable)

	local nValid = 0;
	for iPlayer = 0, PlayerResource:GetPlayerCount() - 1 do
		if PlayerResource:GetSteamAccountID(iPlayer) ~= 0 then
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
	local nPlayerID = data["PlayerID"]
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
