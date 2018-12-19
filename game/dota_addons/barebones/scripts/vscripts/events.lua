require("libraries/playertables")

-- Cleanup a player when they leave
function GameMode:OnDisconnect(keys)
local name = keys.name
local networkid = keys.networkid
local reason = keys.reason
local userid = keys.userid

--	CloseLane(userid)
end

function GameMode:OnSettingVote(keys)
local pid = keys.PlayerID
local mode = GameMode

	-- VoteTable is initialised in InitGameMode()
	if not mode.VoteTable[keys.category] then
		mode.VoteTable[keys.category] = {}
	end
	mode.VoteTable[keys.category][pid] = keys.vote

	-- TODO: Finish votes show up
	CustomGameEventManager:Send_ServerToAllClients("send_votes", {category = keys.category, vote = keys.vote, table = mode.VoteTable, table2 = mode.VoteTable[keys.category]})
end

-- An NPC has spawned somewhere in game. This includes heroes
function GameMode:OnNPCSpawned(keys)
local difficulty = GameRules:GetCustomGameDifficulty()
local npc = EntIndexToHScript(keys.entindex)
local normal_bounty = npc:GetGoldBounty()
local normal_xp = npc:GetDeathXP()
if GetMapName() == "x_hero_siege_8" then
	local normal_bounty = npc:GetGoldBounty() * 2
	local normal_xp = npc:GetDeathXP() * 2
end
local normal_min_damage = npc:GetBaseDamageMin()
local normal_max_damage = npc:GetBaseDamageMax()
local hero_level = npc:GetLevel()

	-- This internal handling is used to set up main barebones functions
	GameMode:_OnNPCSpawned(keys)

	if npc then
		--ALL NPC
		for i = 1, #innate_abilities do
			local current_ability = npc:FindAbilityByName(innate_abilities[i])
			if current_ability then
				current_ability:SetLevel(1)
			end
		end

		if npc:GetTeamNumber() ~= 2 or npc:GetUnitName() == "npc_dota_creature_muradin_bronzebeard" then
			if npc:GetKeyValue("UseAI") == 1 or npc:GetKeyValue("UseAI") == 2 or npc:GetKeyValue("UseAI") == 3 then
				npc:AddNewModifier(npc, nil, "modifier_ai", {})
			end
		end

		if npc:GetUnitName() == "npc_dota_hero_magtheridon" then
			ShowBossBar(npc)
		end

		-- HERO NPC
		if npc:IsRealHero()  and npc:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
			if npc.bFirstSpawnComplete == nil then
				if npc:IsFakeHero() and AbilitiesHeroes_XX[npc:GetUnitName()] then
					npc:AddAbility("ability_level_20"):SetLevel(1)
					for _, ability in pairs(AbilitiesHeroes_XX[npc:GetUnitName()]) do
						if ability ~= nil then
							npc:AddAbility(ability[1])
							npc:UpgradeAbility(npc:FindAbilityByName(ability[1]))
						end
					end
				else
					local donator_level = IsDonator(npc)
					print("Donator?", donator_level)

					if donator_level then
						if not npc:HasAbility("holdout_vip") then
							if donator_level >= 1 and donator_level <= 9 then
								npc:SetCustomHealthLabel("#donator_tooltip_"..donator_level, DONATOR_COLOR[donator_level][1], DONATOR_COLOR[donator_level][2], DONATOR_COLOR[donator_level][3])

								local vip_ability = npc:AddAbility("holdout_vip")
								vip_ability:SetLevel(1)
								npc.tp_effect = "particles/econ/events/fall_major_2016/teleport_start_fm06_lvl3.vpcf"
								npc.tp_effect_end = "particles/econ/events/fall_major_2016/teleport_end_fm06_lvl3.vpcf"
							end
						end
					else
						npc.tp_effect = "particles/items2_fx/teleport_start.vpcf"
						npc.tp_effect_end = "particles/items2_fx/teleport_end.vpcf"
					end

					for i = 1, #vip_members do
						if PlayerResource:GetSteamAccountID(npc:GetPlayerID()) == vip_members[i] then
							if not npc:HasAbility("holdout_vip") then
								npc:SetCustomHealthLabel("VIP", 45, 200, 45)
								local vip_ability = npc:AddAbility("holdout_vip")
								vip_ability:SetLevel(1)
							end
						end
					end

					if npc:GetUnitName() == "npc_dota_hero_chaos_knight" or npc:GetUnitName() == "npc_dota_hero_keeper_of_the_light" then
						npc:SetAbilityPoints(0)
					elseif npc:GetUnitName() == "npc_dota_hero_lone_druid" then
						npc:AddNewModifier(npc, nil, "modifier_item_ultimate_scepter_consumed", {})
					end

					if npc:GetUnitName() ~= "npc_dota_hero_wisp" then
						npc:AddNewModifier(npc, nil, "modifier_armor_gain_fix", {})
--						npc:AddNewModifier(npc, nil, "modifier_magical_resistance_fix", {})
					end

					npc.bFirstSpawnComplete = true
					self.bPlayerHasSpawned = true
					npc.CurrentZoneName = nil
					self:OnPlayerHeroEnteredZone(npc, "xhs_holdout")
					npc.ankh_respawn = false
--					npc:AddNewModifier(npc, nil, "modifier_hero", {})
				end
			elseif npc.bFirstSpawnComplete == true then
				if npc:GetUnitName() == "npc_dota_hero_chaos_knight" or npc:GetUnitName() == "npc_dota_hero_keeper_of_the_light" then
					npc:SetAbilityPoints(0)
				elseif npc:GetUnitName() == "npc_dota_hero_tiny" then
					npc:AddAbility("tiny_grow")
					grow = npc:FindAbilityByName("tiny_grow")
					grow:SetLevel(1)
					npc:SetModelScale(1.1)
					Timers:CreateTimer(0.3, function()
						npc:RemoveAbility("tiny_grow")
					end)
					--debug
					if hero_level == 17 then
						npc:SetAbilityPoints(npc:GetAbilityPoints()-1)
					elseif hero_level >= 20 then
						local ability = npc:FindAbilityByName("holdout_war_club_20")
						npc:RemoveModifierByName("modifier_item_ultimate_scepter_consumed")
						npc:RemoveModifierByName("modifier_item_ultimate_scepter_consumed")
						npc:AddNewModifier(npc, ability, "modifier_item_ultimate_scepter_consumed", {})
						npc:AddNewModifier(npc, nil, "modifier_tiny_craggy_exterior", {})
					end
				end
			end
			return
		end

		-- CREATURES NPC
		if not npc:IsRealHero() and (npc:GetTeamNumber() == DOTA_TEAM_CUSTOM_1 or npc:GetTeamNumber() == DOTA_TEAM_CUSTOM_2 or npc:GetTeamNumber() == DOTA_TEAM_NEUTRALS) then
			if difficulty == 1 then
				npc:SetMinimumGoldBounty(normal_bounty*1.5)
				npc:SetMaximumGoldBounty(normal_bounty*1.5)
				npc:SetDeathXP(normal_xp*1.25)
				npc:SetBaseDamageMin(normal_min_damage*0.75)
				npc:SetBaseDamageMax(normal_max_damage*0.75)
			elseif difficulty == 2 then
				npc:SetMinimumGoldBounty(normal_bounty*1.1)
				npc:SetMaximumGoldBounty(normal_bounty*1.1)
				npc:SetDeathXP(normal_xp)
				npc:SetBaseDamageMin(normal_min_damage)
				npc:SetBaseDamageMax(normal_max_damage)
			elseif difficulty == 3 then
				npc:SetMinimumGoldBounty(normal_bounty)
				npc:SetMaximumGoldBounty(normal_bounty)
				npc:SetDeathXP(normal_xp*0.9)
				npc:SetBaseDamageMin(normal_min_damage*1.25)
				npc:SetBaseDamageMax(normal_max_damage*1.25)
			elseif difficulty == 4 then
				npc:SetMinimumGoldBounty(normal_bounty)
				npc:SetMaximumGoldBounty(normal_bounty)
				npc:SetDeathXP(normal_xp*0.75)
				npc:SetBaseDamageMin(normal_min_damage*1.5)
				npc:SetBaseDamageMax(normal_max_damage*1.5)
			elseif difficulty == 5 then
				npc:SetMinimumGoldBounty(normal_bounty*0.75)
				npc:SetMaximumGoldBounty(normal_bounty*0.75)
				npc:SetDeathXP(normal_xp*0.60)
				npc:SetBaseDamageMin(normal_min_damage*2.0)
				npc:SetBaseDamageMax(normal_max_damage*2.0)
			end

			-- Cycle through any innate abilities found, then upgrade them
			for i = 1, #difficulty_abilities do
				local current_ability = npc:FindAbilityByName(difficulty_abilities[i])
				local difficulty = GameRules:GetCustomGameDifficulty()
				if current_ability then
					current_ability:SetLevel(difficulty)
				end
			end

			if npc:GetUnitName() == "npc_dota_hero_banehallow" then
				npc:AddNewModifier(npc, nil, "boss_thinker_nevermore", {})
			end

			npc.zone = "xhs_holdout"

			return
		end
	end
end

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
--[[
function GameMode:OnPlayerLearnedAbility(keys)
local player = EntIndexToHScript(keys.player)
local hero = player:GetAssignedHero()
local abilityname = keys.abilityname
local ability = hero:FindAbilityByName(abilityname)

	if hero:GetUnitName() == "npc_dota_hero_doom_bringer" then
		if ability:GetAbilityIndex() == 3 or ability:GetAbilityIndex() == 4 then
			ability:SetLevel(ability:GetLevel() -1)
			hero:SetAbilityPoints(hero:GetAbilityPoints() +1)
			SendErrorMessage(hero:GetPlayerID(), "#error_cant_lvlup")
		end
	elseif hero:GetUnitName() == "npc_dota_hero_lone_druid" then
		if ability:GetAbilityIndex() == 0 then
			local Bears = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false)
			for _, Bear in pairs(Bears) do
				for number = 1, 7 do
					if Bear and Bear:GetUnitName() == "npc_dota_lone_druid_bear"..number then
						Bear.ankh_respawn = true
						Timers:CreateTimer(0.03, function()
							Bear.ankh_respawn = false
						end)
					end
				end
			end
		end
	end
end
--]]
function GameMode:OnAbilityChannelFinished(keys)
	local abilityname = keys.abilityname
	local interrupted = keys.interrupted == 1
end

function GameMode:OnPlayerLevelUp(keys)
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
			print("Whisper Level 20 Ability")
			hero.lvl_20 = true
			Notifications:Bottom(hero:GetPlayerOwnerID(), {text="You've reached level 20. Check out your new abilities! ",duration = 10})
			for _, ability in pairs(AbilitiesHeroes_XX[hero:GetUnitName()]) do
				if ability ~= nil then
					Notifications:Bottom(hero:GetPlayerOwnerID(), {ability=ability[1] ,continue=true})
					hero:AddAbility(ability[1])
					hero:UpgradeAbility(hero:FindAbilityByName(ability[1]))
					local oldab = hero:GetAbilityByIndex(ability[2])
					if oldab:GetAutoCastState() then 
						oldab:ToggleAutoCast()
					end
					hero:SwapAbilities(oldab:GetName(),ability[1],true,true)
				end
			end
		else
			print("No Level 20 Ability")			
		end
	end
end

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

function GameMode:OnRuneActivated(keys)
local player = PlayerResource:GetPlayer(keys.PlayerID)
local rune = keys.rune

	--[[ Rune Can be one of the following types
	DOTA_RUNE_DOUBLEDAMAGE
	DOTA_RUNE_HASTE
	DOTA_RUNE_HAUNTED
	DOTA_RUNE_ILLUSION
	DOTA_RUNE_INVISIBILITY
	DOTA_RUNE_BOUNTY
	DOTA_RUNE_MYSTERY
	DOTA_RUNE_RAPIER
	DOTA_RUNE_REGENERATION
	DOTA_RUNE_SPOOKY
	DOTA_RUNE_TURBO
	]]
end

function GameMode:OnPlayerTakeTowerDamage(keys)
local player = PlayerResource:GetPlayer(keys.PlayerID)
local damage = keys.damage

end

function GameMode:OnPlayerPickHero(keys)
local heroClass = keys.hero
local heroEntity = EntIndexToHScript(keys.heroindex)
local player = EntIndexToHScript(keys.player)

	-- modifies the name/label of a player
--	GameMode:setPlayerHealthLabel(player)
end

function GameMode:OnTeamKillCredit(keys)
local killerPlayer = PlayerResource:GetPlayer(keys.killer_userid)
local victimPlayer = PlayerResource:GetPlayer(keys.victim_userid)
local numKills = keys.herokills
local killerTeamNumber = keys.teamnumber

end

function GameMode:PlayerConnect(keys)
end

function GameMode:OnConnectFull(keys)
GameMode:_OnConnectFull(keys)
local entIndex = keys.index+1
local ply = EntIndexToHScript(entIndex)
local playerID = ply:GetPlayerID()

	-- If this is Mohammad Mehdi Akhondi, end the game. Dota Imba ban system.
	for i = 1, #banned_players do
		if PlayerResource:GetSteamAccountID(ply:GetPlayerID()) == banned_players[i] then
			Timers:CreateTimer(5.0, function()
				GameRules:SetGameWinner(DOTA_TEAM_CUSTOM_1)
			end)

			GameRules:SetHeroSelectionTime(1.0)
			GameRules:SetPreGameTime(1.0)
			GameRules:SetPostGameTime(5.0)
			GameRules:SetCustomGameSetupAutoLaunchDelay(0.0)
			Say(nil, "<font color='#FF0000'>Mohammad Mehdi Akhondi</font> detected, game will not start. Please disconnect.", false)
		end
	end
end

function GameMode:OnIllusionsCreated(keys)
	local originalEntity = EntIndexToHScript(keys.original_entindex)
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

function GameMode:OnPlayerChat(keys)
local teamonly = keys.teamonly
local userID = keys.playerid
local text = keys.text
local player = PlayerResource:GetPlayer(userID)
local hero = PlayerResource:GetPlayer(userID):GetAssignedHero()

	for str in string.gmatch(text, "%S+") do
		if IsDonator(hero) == 1 or IsDonator(hero) == 2 then
			for Frozen = 0, PlayerResource:GetPlayerCount() -1 do
				local PlayerNames = {"Red", "Blue", "Cyan", "Purple", "Yellow", "Orange", "Green", "Pink"}
				if PlayerResource:IsValidPlayer(Frozen) then
					if str == "-freeze_"..Frozen +1 then
						local hero = PlayerResource:GetPlayer(Frozen):GetAssignedHero()
						hero:AddNewModifier(nil, nil, "modifier_animation_freeze_stun", {})
						hero:AddNewModifier(nil, nil, "modifier_invulnerable", {})
						PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), hero)
						Notifications:TopToAll({text="[ADMIN MOD]: ", duration=6.0, style={color="red", ["font-size"]="30px"}})
						Notifications:TopToAll({text=PlayerNames[Frozen +1].." ", style={color=PlayerNames[Frozen +1], ["font-size"]="25px"}, continue=true})
						Notifications:TopToAll({text="player has been jailed!", style={color="white", ["font-size"]="25px"}, continue=true})
					end
					if str == "-unfreeze_"..Frozen +1 then
						local hero = PlayerResource:GetPlayer(Frozen):GetAssignedHero()
						hero:RemoveModifierByName("modifier_animation_freeze_stun")
						hero:RemoveModifierByName("modifier_boss_stun")
						hero:RemoveModifierByName("modifier_invulnerable")
						hero:RemoveModifierByName("modifier_command_restricted")
						PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), nil)
						Notifications:TopToAll({text="[ADMIN MOD]: ", duration=6.0, style={color="red", ["font-size"]="30px"}})
						Notifications:TopToAll({text=PlayerNames[Frozen +1].." ", style={color=PlayerNames[Frozen +1], ["font-size"]="25px"}, continue=true})
						Notifications:TopToAll({text="player has been released!", style={color="white", ["font-size"]="25px"}, continue=true})
					end
					if str == "-kill_"..Frozen +1 then
						local hero = PlayerResource:GetPlayer(Frozen):GetAssignedHero()
						if hero:IsAlive() then
							hero:ForceKill(true)
							Notifications:TopToAll({text="[ADMIN MOD]: ", duration=6.0, style={color="red", ["font-size"]="30px"}})
							Notifications:TopToAll({text=PlayerNames[Frozen +1].." ", style={color=PlayerNames[Frozen +1], ["font-size"]="25px"}, continue=true})
							Notifications:TopToAll({text="player has been slayed!", style={color="white", ["font-size"]="25px"}, continue=true})
						end
					end
					if str == "-revive_"..Frozen +1 then
						local hero = PlayerResource:GetPlayer(Frozen):GetAssignedHero()
						hero:RespawnHero(false, false)
						Notifications:TopToAll({text="[ADMIN MOD]: ", duration=6.0, style={color="red", ["font-size"]="30px"}})
						Notifications:TopToAll({text=PlayerNames[Frozen +1].." ", style={color=PlayerNames[Frozen +1], ["font-size"]="25px"}, continue=true})
						Notifications:TopToAll({text="player has been revived!", style={color="white", ["font-size"]="25px"}, continue=true})
					end
					if str == "-yolo_"..Frozen +1 then
						local hero = PlayerResource:GetPlayer(Frozen):GetAssignedHero()
						hero:SetMoveCapability(DOTA_UNIT_CAP_MOVE_FLY)
						StartAnimation(hero, {duration = 9999.0, activity = ACT_DOTA_FLAIL, rate = 0.9})
						yolo = ParticleManager:CreateParticle("particles/units/heroes/hero_batrider/batrider_firefly_ember.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
						ParticleManager:SetParticleControl(yolo, 0, hero:GetAbsOrigin() + Vector(0, 0, 100))
						yolo2 = ParticleManager:CreateParticle("particles/units/heroes/hero_ember_spirit/ember_spirit_flameguard.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
						hero:EmitSound("Hero_Batrider.Firefly.Cast")
						hero:EmitSound("Hero_Batrider.Firefly.Loop")
						Notifications:TopToAll({text="[ADMIN MOD]: ", duration=6.0, style={color="red", ["font-size"]="30px"}})
						Notifications:TopToAll({text=PlayerNames[Frozen +1].." ", style={color=PlayerNames[Frozen +1], ["font-size"]="25px"}, continue=true})
						Notifications:TopToAll({text="player is in YOLO state!", style={color="white", ["font-size"]="25px"}, continue=true})
					end
					if str == "-unyolo_"..Frozen +1 then
						local hero = PlayerResource:GetPlayer(Frozen):GetAssignedHero()
						hero:SetMoveCapability(DOTA_UNIT_CAP_MOVE_GROUND)
						EndAnimation(hero)
						hero:StopSound("Hero_Batrider.Firefly.Loop")
						ParticleManager:DestroyParticle(yolo, true)
						ParticleManager:DestroyParticle(yolo2, true)
						Notifications:TopToAll({text="[ADMIN MOD]: ", duration=6.0, style={color="red", ["font-size"]="30px"}})
						Notifications:TopToAll({text=PlayerNames[Frozen +1].." ", style={color=PlayerNames[Frozen +1], ["font-size"]="25px"}, continue=true})
						Notifications:TopToAll({text="player is not in YOLO state anymore.", style={color="white", ["font-size"]="25px"}, continue=true})
					end
				end
			end

			if str == "-replaceherowith" then
				text = string.gsub(text, str, "")
				text = string.gsub(text, " ", "")
				if PlayerResource:GetSelectedHeroName(hero:GetPlayerID()) ~= "npc_dota_hero_"..text then
					PrecacheUnitByNameAsync("npc_dota_hero_"..text, function()
						local wisp = PlayerResource:GetSelectedHeroEntity(playerId)
						local hero = PlayerResource:ReplaceHeroWith(playerId, "npc_dota_hero_"..text, 0, 0)

						Timers:CreateTimer(1.0, function()
							if wisp then
								UTIL_Remove(wisp)
							end
						end)
					end)
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

				Notifications:Bottom(player, {text="You've bought "..numberOfTomes.." Tomes!", duration=5.0, style={color="white"}})
				PlayerResource:SpendGold(player:GetPlayerID(), (numberOfTomes) * cost, DOTA_ModifyGold_PurchaseItem)

				Timers:CreateTimer(function()
					hero:ModifyAgility(1 * 50)
					hero:ModifyStrength(1 * 50)
					hero:ModifyIntellect(1 * 50)
					hero:EmitSound("ui.trophy_levelup")

					local particle1 = ParticleManager:CreateParticle("particles/econ/events/ti6/hero_levelup_ti6.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
					ParticleManager:SetParticleControl(particle1, 0, hero:GetAbsOrigin())

					i = i + 1

					if i >= numberOfTomes then
						return nil
					else
						return 0.1
					end
				end)
			elseif BT_ENABLED == 0 then
				SendErrorMessage(hero:GetPlayerID(), "#error_buy_tome_disabled")
			end
		end

		if str == "-info" then
			local diff = {"Easy", "Normal", "Hard", "Extreme", "Divine"}
			local lanes = {"Simple", "Double", "Full"}

			Notifications:Bottom(player, {text="DIFFICULTY: "..diff[GameRules:GetCustomGameDifficulty()], duration=10.0})
			Notifications:Bottom(player, {text="CREEP LANES: "..lanes[CREEP_LANES_TYPE], duration=10.0})
		end

		if GameRules:State_Get() >= DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
			if str == "-openlane_all" or str == "-ol_all" then
				for i = 1, 8 do
					OpenLane(i)
				end
			end

			if str == "-closelane_all" or str == "-cl_all" then
				for i = 1, 8 do
					CloseLane(hero:GetPlayerID(), i)
				end
			end
		end
	end

	if GameRules:State_Get() < DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then return end

	local openlane_command = {
		"openlane",
		"ol",
	}

	for _, openlane in pairs(openlane_command) do
		local i, j = string.find(text, openlane.."_%d")
		local lane = nil

		if i then
			lane = string.sub(text, i, j)
			local i,j = string.find(lane, "%d")
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
		local i, j = string.find(text, closelane.."_%d")
		local lane = nil

		if i then
			lane = string.sub(text, i, j)
			local i,j = string.find(lane, "%d")
			lane = tonumber(string.sub(lane, i, j))

			if lane <= 8 then
				print("Opening lane:", lane)
				CloseLane(hero:GetPlayerID(), lane)
			end
		end
	end
end

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
			for _,zone in pairs(self.Zones) do
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
	local playerHero = EntIndexToHScript(activator_entindex)
	if playerHero and playerHero:IsRealHero() and playerHero:GetPlayerOwnerID() ~= -1 then
		local i, j = string.find(triggerName, "_zone_")
		if i then
			local zone1Name = string.sub(triggerName, 1, i-1)
			local zone2Name = string.sub(triggerName, j+1, string.len(triggerName))

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
	self.Zones = {}
--	PrintTable(ZonesDefinition, "  ")
	for _, zone in pairs(ZonesDefinition) do
		if zone then
			print("GameMode:SetupZones() - Setting up zone " .. zone.szName .. " from definition.")
			local newZone = CDungeonZone()
			newZone:Init(zone)
			table.insert(self.Zones, newZone)
		end
	end
end

-- Cleanup a player when they leave
function GameMode:OnDisconnect(keys)
DebugPrint('[BAREBONES] Player Disconnected ' .. tostring(keys.userid))
DebugPrintTable(keys)
local name = keys.name
local networkid = keys.networkid
local reason = keys.reason
local userid = keys.userid

--	CloseLane(userid)
end

-- A non-player entity (necro-book, chen creep, etc) used an ability
function GameMode:OnNonPlayerUsedAbility(keys)
DebugPrint('[BAREBONES] OnNonPlayerUsedAbility')
DebugPrintTable(keys)

local abilityname = keys.abilityname
end

-- This function is called whenever illusions are created and tells you which was/is the original entity
function GameMode:OnIllusionsCreated(keys)
DebugPrint('[BAREBONES] OnIllusionsCreated')
DebugPrintTable(keys)

local originalEntity = EntIndexToHScript(keys.original_entindex)
end

-- This function is called whenever a tower is killed
function GameMode:OnTowerKill(keys)
DebugPrint('[BAREBONES] OnTowerKill')
DebugPrintTable(keys)

local gold = keys.gold
local killerPlayer = PlayerResource:GetPlayer(keys.killer_userid)
local team = keys.teamnumber
end

-- This function is called whenever a player changes there custom team selection during Game Setup 
function GameMode:OnPlayerSelectedCustomTeam(keys)
DebugPrint('[BAREBONES] OnPlayerSelectedCustomTeam')
DebugPrintTable(keys)

local player = PlayerResource:GetPlayer(keys.player_id)
local success = (keys.success == 1)
local team = keys.team_id
end

-- This function is called whenever an NPC reaches its goal position/target
function GameMode:OnNPCGoalReached(keys)
DebugPrint('[BAREBONES] OnNPCGoalReached')
DebugPrintTable(keys)

local goalEntity = EntIndexToHScript(keys.goal_entindex)
local nextGoalEntity = EntIndexToHScript(keys.next_goal_entindex)
local npc = EntIndexToHScript(keys.npc_entindex)
end

---------------------------------------------------------
-- entity_killed
-- * entindex_killed
-- * entindex_attacker
-- * entindex_inflictor
-- * damagebits
---------------------------------------------------------

local first_rax = false
function GameMode:OnEntityKilled(keys)
local killedUnit = EntIndexToHScript(keys.entindex_killed)
if killedUnit == nil then return end
if killedUnit:FindModifierByName( "modifier_breakable_container" ) then return end
local hero = nil
local killerAbility = nil
if keys.entindex_attacker ~= nil then hero = EntIndexToHScript(keys.entindex_attacker) end
if keys.entindex_inflictor ~= nil then killerAbility = EntIndexToHScript(keys.entindex_inflictor) end
local difficulty = GameRules:GetCustomGameDifficulty()
local damagebits = keys.damagebits -- This might always be 0 and therefore useless
local KillerID = hero:GetPlayerOwnerID()
local playerKills = PlayerResource:GetKills(KillerID)
local cn = string.gsub(killedUnit:GetName(), "dota_badguys_tower", "")
local lane = tonumber(cn)

	if IsValidEntity(hero:GetPlayerOwner()) then
		hero = hero:GetPlayerOwner():GetAssignedHero()
	end

	if hero:IsIllusion() and hero:GetTeamNumber() == 2 then
		hero = PlayerResource:GetPlayer(hero:GetPlayerID()):GetAssignedHero()
	end

	local Zone = killedUnit.zone
	if Zone then
		for _,zone in pairs(self.Zones) do
			zone:OnEnemyKilled(killedUnit, Zone)
		end
	end

	if killedUnit:IsRealHero() and (killedUnit:GetTeamNumber() == DOTA_TEAM_GOODGUYS) then
		local netTable = {}
--		CustomGameEventManager:Send_ServerToPlayer(killedUnit:GetPlayerOwner(), "life_lost", netTable)

		if killedUnit:GetUnitName() == "npc_dota_hero_tiny" then
			killedUnit:RemoveModifierByName("modifier_item_ultimate_scepter_consumed")
			killedUnit:RemoveModifierByName("modifier_animation_translate")  
		-- Lone Druid Bear death debug
		elseif killedUnit:GetUnitName() == "npc_dota_hero_lone_druid" then
			local Bears = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false)
			for _, Bear in pairs(Bears) do
				for number = 1, 7 do
					if Bear and Bear:GetUnitName() == "npc_dota_lone_druid_bear"..number then
						Timers:CreateTimer(0.03, function()
							Bear:RespawnUnit()
						end)
						Timers:CreateTimer(0.17, function()
							Bear:RespawnUnit()
							Bear:AddNewModifier(nil, nil, "modifier_animation_freeze_stun", {duration=4.8})
						end)
					end
				end
			end
		end

		--Drop Tombstone to be revived if dead after Castle Defense
		if PHASE == 3 then
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

		for _,Zone in pairs(self.Zones) do
			if Zone:ContainsUnit(killedUnit) then
				Zone:AddStat(killedUnit:GetPlayerID(), ZONE_STAT_DEATHS, 1)
				killedUnit.DeathZone = Zone
			end
		end 
	return
	elseif killedUnit:IsCreature() then
		local ramero_check = 0
		if killedUnit:GetUnitName() == "npc_ramero" then
			local item = CreateItem("item_lightning_sword", nil, nil)
			local pos = killedUnit:GetAbsOrigin()
			local drop = CreateItemOnPositionSync(pos, item)
			item:LaunchLoot(false, 300, 0.5, pos)
			ramero_check = ramero_check +1
		elseif killedUnit:GetUnitName() == "npc_baristol" then
			local item = CreateItem("item_tome_big", nil, nil)
			local pos = killedUnit:GetAbsOrigin()
			local drop = CreateItemOnPositionSync(pos, item)
			item:LaunchLoot(false, 300, 0.5, pos)
			ramero_check = ramero_check +1
		elseif killedUnit:GetUnitName() == "npc_ramero_2" then
			local item = CreateItem("item_ring_of_superiority", nil, nil)
			local pos = killedUnit:GetAbsOrigin()
			local drop = CreateItemOnPositionSync(pos, item)
			item:LaunchLoot(false, 300, 0.5, pos)
			doom_first_time = true
			Timers:RemoveTimer(timers.Ramero)
		elseif killedUnit:GetUnitName() == "npc_dota_hero_secret" then
			local item = CreateItem("item_orb_of_frost", nil, nil)
			local pos = killedUnit:GetAbsOrigin()
			local drop = CreateItemOnPositionSync(pos, item)
			item:LaunchLoot(false, 300, 0.5, pos)
			frost_first_time = true
		elseif killedUnit:GetUnitName() == "npc_dota_boss_lich_king" then
			GAME_WINNER_TEAM = "Radiant" 
			for _, hero in pairs(HeroList:GetAllHeroes()) do
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), hero)
				hero:AddNewModifier(hero, nil, "modifier_command_restricted", {})
				hero:Stop()
			end
		end

		if ramero_check == 2 then
			Timers:RemoveTimer(timers.RameroAndBaristol)
		end

		if killedUnit:GetUnitName() == "npc_dota_hero_magtheridon" then
			local teleporters2 = Entities:FindAllByName("trigger_teleport2")
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
		if hero:GetTeamNumber() == 2 then
			if not hero.gold_advertize then hero.gold_advertize = 0 end
			if hero:IsRealHero() then
				if PlayerResource:GetGold(hero:GetPlayerID()) > 990000 and hero.gold_advertize == 0 and SPECIAL_EVENT ~= 1 then
					SendErrorMessage(hero:GetPlayerID(), "#error_gold_full")
					hero.gold_advertize = 1
					Timers:CreateTimer(5.0, function()
						hero.gold_advertize = 0
					end)
				end
			end

			if killedUnit:GetTeamNumber() == 6 then
				if hero:IsIllusion() then
					hero = PlayerResource:GetPlayer(hero:GetPlayerID()):GetAssignedHero()
					hero:IncrementKills(1)
					for _, Zone in pairs(self.Zones) do
						if Zone:ContainsUnit(hero) then
							Zone:AddStat(hero:GetPlayerID(), ZONE_STAT_KILLS, 1)
						end
					end
				elseif IsValidEntity(hero:GetPlayerOwner()) then
					if not hero:IsRealHero() then
						if hero:GetPlayerOwner() then
							hero = hero:GetPlayerOwner():GetAssignedHero()
							hero:IncrementKills(1)
						end
						for _, Zone in pairs(self.Zones) do
							if Zone:ContainsUnit(hero) then
								Zone:AddStat(hero:GetPlayerID(), ZONE_STAT_KILLS, 1)
							end
						end
					--plays a particle and add a kill when a hero kills an enemy unit
					elseif hero:IsRealHero() then
						EmitSoundOnClient("Dungeon.LastHit", hero:GetPlayerOwner())
						ParticleManager:ReleaseParticleIndex(ParticleManager:CreateParticleForPlayer("particles/darkmoon_last_hit_effect.vpcf", PATTACH_ABSORIGIN_FOLLOW, killedUnit, hero:GetPlayerOwner()))
						if PlayerResource:HasSelectedHero(hero:GetPlayerOwnerID()) then
							hero:IncrementKills(1)
						end
						for _, Zone in pairs(self.Zones) do
							if Zone:ContainsUnit(hero) then
								Zone:AddStat(hero:GetPlayerID(), ZONE_STAT_KILLS, 1)
							end
						end

						-- reward system based on kills, including kill events
						if hero:GetKills() == 99 then
							Notifications:Bottom(hero:GetPlayerOwnerID(), {text="100 kills. You get 7500 gold.", duration=5.0, style={color="yellow"}})
							PlayerResource:ModifyGold(hero:GetPlayerOwnerID(), 7500, false,  DOTA_ModifyGold_Unspecified)
						elseif hero:GetKills() == 199 then
							Notifications:Bottom(hero:GetPlayerOwnerID(), {text="200 kills. You get 25000 gold.", duration=5.0, style={color="yellow"}})
							PlayerResource:ModifyGold(hero:GetPlayerOwnerID(), 25000, false,  DOTA_ModifyGold_Unspecified)
						elseif hero:GetKills() == 399 then
							Notifications:Bottom(hero:GetPlayerOwnerID(), {text="400 kills. You get 50000 gold.", duration=5.0, style={color="yellow"}})
							PlayerResource:ModifyGold(hero:GetPlayerOwnerID(), 50000, false,  DOTA_ModifyGold_Unspecified)
						elseif hero:GetKills() >= 499 and RAMERO == 0 then --500
						local point = Entities:FindByName(nil, "npc_dota_muradin_player_1"):GetAbsOrigin()
							hero:AddNewModifier(nil, nil, "modifier_animation_freeze_stun", nil)
							hero:AddNewModifier(nil, nil, "modifier_invulnerable", nil)
							Notifications:TopToAll({text="A hero has reached 500 kills and will fight Ramero and Baristol!", style={color="white"}, duration=5.0})
							PauseCreeps()
							Timers:CreateTimer(5.0, function()
								PauseCreeps()
								FindClearSpaceForUnit(hero, point, true)
								PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), hero)
								RameroAndBaristolEvent(120)
								hero:RemoveModifierByName("modifier_animation_freeze_stun")
								hero:RemoveModifierByName("modifier_invulnerable")
								Timers:CreateTimer(0.1, function()
									PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), nil)
								end)
							end)
							RAMERO = 1
							hero.old_pos = hero:GetAbsOrigin()
						elseif hero:GetKills() >= 749 and RAMERO == 1 then --750
						local point = Entities:FindByName(nil, "npc_dota_muradin_player_1"):GetAbsOrigin()
							hero:AddNewModifier(nil, nil, "modifier_animation_freeze_stun", nil)
							hero:AddNewModifier(nil, nil, "modifier_invulnerable", nil)
							Notifications:TopToAll({text="A hero has reached 750 kills and will fight Ramero!", style={color="white"}, duration=5.0})
							PauseCreeps()
							Timers:CreateTimer(5.0, function()
								FindClearSpaceForUnit(hero, point, true)
								PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), hero)
								RameroEvent(120)
								hero:RemoveModifierByName("modifier_animation_freeze_stun")
								hero:RemoveModifierByName("modifier_invulnerable")
								Timers:CreateTimer(0.1, function()
									PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), nil)
								end)
							end)
							RAMERO = 2
							local hero = hero
							hero.old_pos = hero:GetAbsOrigin()
						end
					end
				end
			end
		end
		if killedUnit.no_corpse ~= true then
			Corpses:CreateFromUnit(killedUnit)
		end
	return
	elseif killedUnit:IsBuilding() then
		if killedUnit:GetTeamNumber() == 3 then
			if hero:IsIllusion() then
				hero = PlayerResource:GetPlayer(hero:GetPlayerID()):GetAssignedHero()
				hero:IncrementKills(1)
				for _, Zone in pairs(self.Zones) do
					if Zone:ContainsUnit(hero) then
						Zone:AddStat(hero:GetPlayerID(), ZONE_STAT_KILLS, 1)
					end
				end
			elseif IsValidEntity(hero:GetPlayerOwner()) then
				if not hero:IsRealHero() then
					if hero:GetPlayerOwner() then
						hero = hero:GetPlayerOwner():GetAssignedHero()
						hero:IncrementKills(1)
					end
					for _, Zone in pairs(self.Zones) do
						if Zone:ContainsUnit(hero) then
							Zone:AddStat(hero:GetPlayerID(), ZONE_STAT_KILLS, 1)
						end
					end
				--plays a particle and add a kill when a hero kills an enemy unit
				elseif hero:IsRealHero() then
					EmitSoundOnClient("Dungeon.LastHit", hero:GetPlayerOwner())
					ParticleManager:ReleaseParticleIndex(ParticleManager:CreateParticleForPlayer("particles/darkmoon_last_hit_effect.vpcf", PATTACH_ABSORIGIN_FOLLOW, killedUnit, hero:GetPlayerOwner()))
					if PlayerResource:HasSelectedHero(hero:GetPlayerOwnerID()) then
						hero:IncrementKills(1)
					end
					for _, Zone in pairs(self.Zones) do
						if Zone:ContainsUnit(hero) then
							Zone:AddStat(hero:GetPlayerID(), ZONE_STAT_KILLS, 1)
						end
					end
				end
			end
		end
		
		if killedUnit:IsTower() then
			if killedUnit:GetUnitName() == "xhs_tower_lane_1" then
				for j = 1, difficulty do
					local unit = CreateUnitByName("xhs_death_revenant", killedUnit:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
				end
--				CREEP_LANES[lane][2] = CREEP_LANES[lane][2] + 1
--				Notifications:TopToAll({text="Creep lane "..lane.." is now level "..CREEP_LANES[lane][2].."!", duration=5.0, style={color="lightgreen"}})
			elseif killedUnit:GetUnitName() == "xhs_tower_lane_2" then
				for j = 1, difficulty do
					local unit = CreateUnitByName("xhs_death_revenant_2", killedUnit:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
				end
--				CREEP_LANES[lane][2] = CREEP_LANES[lane][2] + 1
--				Notifications:TopToAll({text="Creep lane "..lane.." is now level "..CREEP_LANES[lane][2].."!", duration=5.0, style={color="lightgreen"}})
			elseif killedUnit:GetUnitName() == "npc_tower_death" then

			elseif killedUnit:GetUnitName() == "npc_tower_cold" then
				FrostTowers_killed = FrostTowers_killed +1
				if FrostTowers_killed >= 2 then
					Notifications:TopToAll({text="WARNING! Final Wave incoming. Arriving in 60 seconds! Back to the Castle!" , duration=10.0})
					nTimer_SpecialEvent = 61
					nTimer_IncomingWave = 1
					PHASE = 3
					KillCreeps(DOTA_TEAM_CUSTOM_1)
					Timers:CreateTimer(59, RefreshPlayers)
					Timers:CreateTimer(60, FinalWave)
				end
			end
		return
		elseif killedUnit:IsBarracks() then
			if first_rax == false then
				first_rax = true

--				Entities:FindByName(nil, "trigger_phase2_left"):Enable()
--				Entities:FindByName(nil, "trigger_phase2_right"):Enable()

				local DoorObs = Entities:FindAllByName("obstruction_phase2")
				for _, obs in pairs(DoorObs) do 
					obs:SetEnabled(false, true)
				end

				DoEntFire("door_phase2_left", "SetAnimation", "gate_02_open", 0, nil, nil)
				DoEntFire("door_phase2_right", "SetAnimation", "gate_02_open", 0, nil, nil)
--				Notifications:TopToAll({text = "Phase 2 creeps can now be triggered!", duration = 11.0})

				PHASE = 2

				return
			end

			return
		end
	return
	end
	print("EntityKilled: Not Hero or Creature or Building.")
end

---------------------------------------------------------
-- dota_holdout_revive_complete
-- * caster (reviver hero entity index)
-- * target (revivee hero entity index)
---------------------------------------------------------

function GameMode:OnPlayerRevived(event)
local hRevivedHero = EntIndexToHScript(event.target)

	if hRevivedHero and hRevivedHero:IsRealHero() then
		hRevivedHero:AddNewModifier(hRevivedHero, nil, "modifier_invulnerable", { duration = 2.5 })
		hRevivedHero:AddNewModifier(hRevivedHero, nil, "modifier_omninight_guardian_angel", { duration = 2.5 })
		EmitSoundOn("Dungeon.HeroRevived", hRevivedHero)

		local hReviver = EntIndexToHScript(event.caster)
		local flChannelTime = event.channel_time
		if hReviver and flChannelTime > 0.0 then
			for _,Zone in pairs(self.Zones) do
				if Zone:ContainsUnit(hReviver) then
					Zone:AddStat(hReviver:GetPlayerID(), ZONE_STAT_REVIVE_TIME, flChannelTime)
				end
			end
		end
	end
end

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

function GameMode:OnRelicSpawned(item, itemKV)
	local PlayerIDs = {}
	local nRelicItemDef = tonumber(itemKV["DungeonItemDef"])
	print("GameMode:OnRelicSpawned - New Relic " .. item:GetAbilityName() .. " created of itemdef: " .. nRelicItemDef)
	for _, Hero in pairs (HeroList:GetAllHeroes()) do
		if Hero and Hero:IsRealHero() and Hero:HasOwnerAbandoned() == false then
			if GetItemDefOwnedCount(Hero:GetPlayerID(), nRelicItemDef) == 0 then
				print("GameMode:OnRelicSpawned - PlayerID " .. Hero:GetPlayerID() .. " does not own item, adding to grant list.")
				table.insert(PlayerIDs, Hero:GetPlayerID()) 
			end
		end
	end

	-- What do we do if it's empty?  Right now just give it to someone as a dupe?
	local bDupeForAllPlayers = #PlayerIDs == 0
	if bDupeForAllPlayers then
		for _,Hero in pairs (Heroes) do
			if Hero and Hero:IsRealHero() then
				table.insert(PlayerIDs, Hero:GetPlayerID()) 
			end
		end
	end

	local WinningPlayerID =  PlayerIDs[RandomInt(1, #PlayerIDs)]
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
-- dota_player_reconnected
-- * player_id
---------------------------------------------------------

function GameMode:OnPlayerReconnected(event)
--	OpenLane(event.player_id)
end

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
			for _,Zone in pairs(self.Zones) do
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
	for _,Hero in pairs (HeroList:GetAllHeroes()) do
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
		for _,Hero in pairs (Heroes) do
			if Hero ~= nil and Hero:IsRealHero() then
				table.insert(PlayerIDs, Hero:GetPlayerID()) 
			end
		end
	end

	local WinningPlayerID =  PlayerIDs[RandomInt(1, #PlayerIDs)]
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
--	print("GameMode:OnPlayerHeroEnteredZone - PlayerHero " .. playerHero:GetUnitName() .. " entered " .. zoneName)

	local netTable = {}
	netTable["ZoneName"] = zoneName
	CustomGameEventManager:Send_ServerToPlayer(playerHero:GetPlayerOwner(), "zone_enter", netTable)
end

---------------------------------------------------------

function GameMode:OnZoneActivated(Zone)

--	print("GameMode:OnZoneActivated")
	for _,zone in pairs(self.Zones) do
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
	for _,zone in pairs(self.Zones) do
		zone:OnZoneEventComplete(Zone)
	end
end

---------------------------------------------------------

function GameMode:OnQuestStarted(zone, quest)
--	print("GameMode:OnQuestStarted - Quest " .. quest.szQuestName .. " in Zone " .. zone.szName .. " started.")
	quest.bActivated = true

	for _,zone in pairs(self.Zones) do
		zone:OnQuestStarted(quest)
	end

	if quest.szQuestName == "kill_ice_towers" then
		SPECIAL_EVENT = 0
	end

	if quest.Completion.Type == QUEST_EVENT_ON_DIALOG or quest.Completion.Type == QUEST_EVENT_ON_DIALOG_ALL_CONFIRMED then
		local hDialogEntities = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false)
		for _,DialogEnt in pairs (hDialogEntities) do
			if DialogEnt ~= nil  and DialogEnt:GetUnitName() == quest.Completion.szNPCName and DialogEnt:FindModifierByName("modifier_npc_dialog_notify") == nil then
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
	print("GameMode:OnQuestCompleted - Quest " .. quest.szQuestName .. " in Zone " .. questZone.szName .. " completed.")
	quest.nCompleted = quest.nCompleted + 1
	if quest.nCompleted >= quest.nCompleteLimit then
		quest.bCompleted = true
	end

	local bZonePreviouslyCompleted = questZone.bZoneCompleted

	if quest.bOptional ~= true then
		questZone:CheckForZoneComplete()
	end

	if quest.bCompleted == true then
		for _,zone in pairs(self.Zones) do
			zone:OnQuestCompleted(quest)
		end

		if quest.Completion.Type == QUEST_EVENT_ON_DIALOG or quest.Completion.Type == QUEST_EVENT_ON_DIALOG_ALL_CONFIRMED then
			local hDialogEntities = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false)
			for _,DialogEnt in pairs (hDialogEntities) do
				if DialogEnt ~= nil and DialogEnt:GetUnitName() == quest.Completion.szNPCName and DialogEnt:FindModifierByName("modifier_npc_dialog_notify") then
					DialogEnt:RemoveModifierByName("modifier_npc_dialog_notify")
				end
			end
		end

		local hLogicRelay = Entities:FindByName(nil, quest.szCompletionLogicRelay)
		if hLogicRelay then
			hLogicRelay:Trigger()
		end

		for _,Hero in pairs (HeroList:GetAllHeroes()) do
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

	if self.bConfirmPending == true then
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

	for _,zone in pairs(self.Zones) do
		zone:OnDialogBegin(hDialogEnt)
	end

	if Dialog.bPlayersConfirm == true then
		self.bConfirmPending = true
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
				local drop = CreateItemOnPositionSync(hPlayerHero:GetAbsOrigin(), newItem)
				local dropTarget = hPlayerHero:GetAbsOrigin() + RandomVector(RandomFloat(50, 150))
				newItem:LaunchLoot(false, 150, 0.75, dropTarget)
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
		for _,unit in pairs (units) do
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
		for _,unit in pairs (units) do
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

		for _,Hero in pairs (HeroList:GetAllHeroes()) do
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
	metadataTable[ "event_name" ] = "siltbreaker"
	metadataTable[ "map_name" ] = "ep_1"

	metadataTable[ "zones" ] = {}

	local trophyLevel = 0

	local signoutTable = {}
	signoutTable["zone_stars"] = {}
	signoutTable["chef_notes"] = self.ChefNotesFound;
	signoutTable["invoker_found"] = self.InvokerFound;

	for _,zone in pairs(self.Zones) do
		if not zone.bNoLeaderboard and zone.flCompletionTime > 0 then
			local zoneTable = {}

			zoneTable[ "zone_id" ] = zone.nZoneID
			zoneTable[ "completed" ] = zone.bZoneCompleted
			zoneTable[ "stars" ] = zone.nStars
			zoneTable[ "kills" ] = zone.nKills
			zoneTable[ "deaths" ] = zone.nDeaths
			zoneTable[ "items" ] = zone.nItems
			zoneTable[ "gold_bags" ] = zone.nGoldBags
			zoneTable[ "potions" ] = zone.nPotions
			zoneTable[ "revive_time" ] = zone.nReviveTime
			zoneTable[ "damage" ] = zone.nDamage
			zoneTable[ "healing" ] = zone.nHealing
			zoneTable[ "completion_time" ] = zone.flCompletionTime
			
			metadataTable[ "zones" ][ zone.szName ] = zoneTable

			if (zone.nZoneID == 13) then
				trophyLevel = zone.nStars
				if (trophyLevel == 0) then
					trophyLevel = 1
				end
			end
		end

		if zone.nStars > 0 then
			signoutTable["zone_stars"][ zone.nZoneID ] = zone.nStars
		end
	end

--	if #self.RelicsFound > 0 then
--		signoutTable[ "relics_found" ] = self.RelicsFound
--	end

	if trophyLevel > 0 then
		signoutTable[ "trophy_id" ] = 63
		signoutTable[ "trophy_level" ] = trophyLevel
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

local ConfirmCount = {}

function GameMode:OnDialogConfirm(eventSourceIndex, data)
	if ConfirmCount[data.ConfirmToken] == nil then
		ConfirmCount[data.ConfirmToken] = 1
	else
		ConfirmCount[data.ConfirmToken] = ConfirmCount[data.ConfirmToken] + 1
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

	print("Check if everyone accepted dialog...")
	print(ConfirmCount[data.ConfirmToken], nValid)
	if ConfirmCount[data.ConfirmToken] >= nValid then
		local netTable = {}
		for _,zone in pairs(self.Zones) do
			zone:OnDialogAllConfirmed(EntIndexToHScript(data["DialogEntIndex"]), data["DialogLine"])
		end
		CustomGameEventManager:Send_ServerToAllClients("dialog_player_all_confirmed", netTable)
		self.bConfirmPending = false
	end
end

---------------------------------------------------------

function GameMode:OnDialogConfirmExpired(eventSourceIndex, data)
	ConfirmCount[data.ConfirmToken] = 4

	for _,zone in pairs(self.Zones) do
		zone:OnDialogAllConfirmed(EntIndexToHScript(data["DialogEntIndex"]), data["DialogLine"])
	end
	CustomGameEventManager:Send_ServerToAllClients("dialog_player_all_confirmed", netTable)
	self.bConfirmPending = false
end

---------------------------------------------------------

function GameMode:OnRelicClaimed(eventSourceIndex, data)
	local nPlayerID = data["PlayerID"]
	local szClaimedRelicName = data["ClaimedRelicName"]
	if nPlayerID ~= nil and szClaimedRelicName ~= nil then
		print("GameMode:OnRelicClaimed - Player " .. nPlayerID .. " is trying to claim relic " .. szClaimedRelicName)
		local relicTable = CustomNetTables:GetTableValue("relics", string.format("%d", nPlayerID))
		if relicTable ~= nil then
			for k,v in pairs(relicTable) do
				if v ~= nil and v == szClaimedRelicName then
					local Hero = PlayerResource:GetSelectedHeroEntity(nPlayerID)
					if Hero ~= nil then
						local newRelic = CreateItem(szClaimedRelicName, Hero, Hero)
						newRelic:SetPurchaseTime(GameRules:GetGameTime())
						newRelic:SetPurchaser(Hero)
						newRelic.bIsRelic = true
						newRelic.nBoundPlayerID = nPlayerID
						if Hero:HasAnyAvailableInventorySpace() then
							Hero:AddItem(newRelic) 
						else
							local drop = CreateItemOnPositionSync(Hero:GetAbsOrigin(), newRelic)
							local dropTarget = Hero:GetAbsOrigin() + RandomVector(RandomFloat(50, 150))
							newRelic:LaunchLoot(false, 150, 0.75, dropTarget)
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
