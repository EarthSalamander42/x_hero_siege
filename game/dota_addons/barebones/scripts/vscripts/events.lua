-- Cleanup a player when they leave
function GameMode:OnDisconnect(keys)
	DebugPrint('[BAREBONES] Player Disconnected ' .. tostring(keys.userid))
	DebugPrintTable(keys)

	local name = keys.name
	local networkid = keys.networkid
	local reason = keys.reason
	local userid = keys.userid
end

function GameMode:OnSettingVote(keys)
  --print("Custom Game Settings Vote.")
  --PrintTable(keys)
  local pid   = keys.PlayerID
  local mode  = GameMode

  -- VoteTable is initialised in InitGameMode()
  if not mode.VoteTable[keys.category] then mode.VoteTable[keys.category] = {} end
  mode.VoteTable[keys.category][pid] = keys.vote

  --PrintTable(mode.VoteTable)
end

-- An NPC has spawned somewhere in game. This includes heroes
function GameMode:OnNPCSpawned(keys)
	DebugPrint("[BAREBONES] NPC Spawned")
	DebugPrintTable(keys)

	local difficulty = GameRules:GetCustomGameDifficulty()
	local npc = EntIndexToHScript(keys.entindex)
	local normal_bounty = npc:GetGoldBounty()
	local normal_xp = npc:GetDeathXP()
	local normal_min_damage = npc:GetBaseDamageMin()
	local normal_max_damage = npc:GetBaseDamageMax()

	if difficulty == 1 and npc:GetTeam() == DOTA_TEAM_BADGUYS then
		npc:SetMinimumGoldBounty( normal_bounty*1.5 )
		npc:SetMaximumGoldBounty( normal_bounty*1.5 )
		npc:SetDeathXP( normal_xp*1.25 )
		npc:SetBaseDamageMin( normal_min_damage*0.75 )
		npc:SetBaseDamageMax( normal_max_damage*0.75 )
	elseif difficulty == 2 and npc:GetTeam() == DOTA_TEAM_BADGUYS then
		npc:SetMinimumGoldBounty( normal_bounty*1.1 )
		npc:SetMaximumGoldBounty( normal_bounty*1.1 )
		npc:SetDeathXP( normal_xp )
		npc:SetBaseDamageMin( normal_min_damage )
		npc:SetBaseDamageMax( normal_max_damage )
	elseif difficulty == 3 and npc:GetTeam() == DOTA_TEAM_BADGUYS then
--		npc:SetMinimumGoldBounty( normal_bounty*0.9 )
--		npc:SetMaximumGoldBounty( normal_bounty*0.9 )
		npc:SetDeathXP( normal_xp*0.9 )
		npc:SetBaseDamageMin( normal_min_damage*1.25 )
		npc:SetBaseDamageMax( normal_max_damage*1.25 )
	elseif difficulty == 4 and npc:GetTeam() == DOTA_TEAM_BADGUYS then
--		npc:SetMinimumGoldBounty( normal_bounty*0.75 )
--		npc:SetMaximumGoldBounty( normal_bounty*0.75 )
		npc:SetDeathXP( normal_xp*0.75 )
		npc:SetBaseDamageMin( normal_min_damage*1.5 )
		npc:SetBaseDamageMax( normal_max_damage*1.5 )
	end

	if npc:GetUnitName() == "npc_dota_hero_chaos_knight" then
		npc:SetAbilityPoints(0)
	end
	if npc:GetUnitName() == "npc_dota_hero_keeper_of_the_light" then
		npc:SetAbilityPoints(0)
	end

	-- List of innate abilities
	local innate_abilities = {
		"dummy_passive_vulnerable_wisp",
		"serpent_splash_arrows",
		"neutral_spell_immunity",
		"holdout_innate_lunar_glaive",
		"holdout_innate_great_cleave",
		"holdout_blink",
		"holdout_poison_attack",
		"forest_troll_high_priest_heal",
		"holdout_mana_shield",
		"holdout_berserkers_rage",
		"holdout_rejuvenation",
		"holdout_resistant_skin",
		"holdout_roar",
		"shadow_shaman_shackles",
		"holdout_command_aura_innate",
		"holdout_frost_frenzy",
		"holdout_sleep",
		"juggernaut_healing_ward",
		"holdout_thunder_spirit",
		"holdout_cripple",
		"blood_mage_orbs",
		"axe_berserkers_call",
		"holdout_banish",
		"holdout_magic_shield",
		"holdout_anubarak_claw",
		"undead_burrow",
		"ogre_magi_bloodlust",
		"axe_berserkers_call",
		"black_dragon_fireball",
		"holdout_beastmaster_misc",
		"holdout_frostmourne_hungers",
		"holdout_battlecry_alt2",
		"holdout_rabid_alt2",
		"lone_druid_spirit_bear_demolish",
		"lone_druid_spirit_bear_entangle",
		"holdout_divided_we_stand_hidden",
		"holdout_frostmourne_innate",
		"holdout_strength_of_the_wild",
		"holdout_last_stand",
		"holdout_power_mount_str",
		"holdout_power_mount_int",
		"holdout_power_mount_agi",
		"holdout_mechanism",
		"holdout_dark_cleave",
		"holdout_skin_changer_caster",
		"holdout_skin_changer_warrior",
		"holdout_health_buff",
		"holdout_blue_effect", --Lich King boss + hero effect
		"holdout_green_effect", --Banehallow boss + hero effect
		"holdout_red_effect" --Abaddon boss
	}

	-- Cycle through any innate abilities found, then upgrade them
	for i = 1, #innate_abilities do
		local current_ability = npc:FindAbilityByName(innate_abilities[i])
		if current_ability then
			current_ability:SetLevel(1)
		end
	end

	-- List of innate abilities
	local difficulty_abilities = {
		"life_stealer_feast",
		"weaver_geminate_attack",
		"creature_aura_of_blight",
		"antimage_mana_break",
		"nevermore_dark_lord",
		"juggernaut_blade_dance",
		"viper_corrosive_skin",
		"creature_thunder_clap_low",
		"creature_death_pulse",
		"endurance_aura",
		"unholy_aura",
		"creature_thunder_clap",
		"command_aura",
		"grom_hellscream_mirror_image",
		"grom_hellscream_bladefury",
		"devotion_aura",
		"divine_aura",
		"proudmoore_divine_shield",
		"arthas_holy_light",
		"arthas_knights_armor",
		"arthas_light_roar",
		"roshan_stormbolt",
		"creature_starfall",
		"creature_firestorm",
		"demonhunter_evasion",
		"demonhunter_immolation",
		"demonhunter_immolation_small",
		"demonhunter_negative_energy",
		"demonhunter_negative_energy_small",
		"demonhunter_roar",
		"demonhunter_vampiric_aura",
		"howl_of_terror",
		"balanar_rain_of_chaos",
		"balanar_sleep",
		"banehallow_stampede",
		"creature_chronosphere",
		"venomancer_poison_sting",
		"lich_frost_armor",
		"monkey_king_boundless_strike"
	}

	-- Cycle through any innate abilities found, then upgrade them
	for i = 1, #difficulty_abilities do
		local current_ability = npc:FindAbilityByName(difficulty_abilities[i])
		local difficulty = GameRules:GetCustomGameDifficulty()
		if current_ability and npc:GetTeam() == DOTA_TEAM_BADGUYS then
			current_ability:SetLevel(difficulty)
		elseif current_ability and npc:GetTeam() == DOTA_TEAM_NEUTRALS then
		end
	end

--	if npc:GetUnitName() == "npc_dota_hero_furion" then -- This functions says it's working, print works no errors but Wearables still there..
--		local model = npc:FirstMoveChild()
--		while model ~= nil do
--			if model:GetClassname() == "dota_item_wearable" then
--				model:AddEffects(EF_NODRAW) -- Set model hidden
--				print("Wearables for Furion hidden!")
--			end
--			model = model:NextMovePeer()
--		end
--	end

	if npc:GetTeam() == DOTA_TEAM_GOODGUYS then
		for i = 1, #vip_members do
			-- Cookies or X Hero Siege
			if npc:IsHero() then
				if PlayerResource:GetSteamAccountID(npc:GetPlayerID()) == mod_creator[i] then
					npc:SetCustomHealthLabel("Mod Creator", 200, 45, 45)
					if not npc:HasAbility("holdout_vip") then
						local vip_ability = npc:AddAbility("holdout_vip")
						vip_ability:SetLevel(1)
					end
				end
				-- Baumi
				if PlayerResource:GetSteamAccountID(npc:GetPlayerID()) == captain_baumi[i] then
					npc:SetCustomHealthLabel("Captain Baumi", 55, 55, 200)
					if not npc:HasAbility("holdout_vip") then
						local vip_ability = npc:AddAbility("holdout_vip")
						vip_ability:SetLevel(1)
					end
				end
				-- Mugiwara
				if PlayerResource:GetSteamAccountID(npc:GetPlayerID()) == mod_graphist[i] then
					npc:SetCustomHealthLabel("Mod Graphist", 55, 55, 200)
					if not npc:HasAbility("holdout_vip") then
						local vip_ability = npc:AddAbility("holdout_vip")
						vip_ability:SetLevel(1)
					end
				end
				-- See VIP List on Top
				if PlayerResource:GetSteamAccountID(npc:GetPlayerID()) == vip_members[i] then
					npc:SetCustomHealthLabel("VIP Member", 45, 200, 45)
					if not npc:HasAbility("holdout_vip") then
						local vip_ability = npc:AddAbility("holdout_vip")
						vip_ability:SetLevel(1)
					end
				end
				if PlayerResource:GetSteamAccountID(npc:GetPlayerID()) == golden_vip_members[i] then
					npc:SetCustomHealthLabel("Golden VIP Member", 218, 165, 32)
					if not npc:HasAbility("holdout_vip") then
						local vip_ability = npc:AddAbility("holdout_vip")
						vip_ability:SetLevel(1)
					end
				end
			end
		end
	end

	if npc:GetTeam() == DOTA_TEAM_BADGUYS then
		if not npc:HasAbility("holdout_frost_effect") then
			local frost_effect = npc:AddAbility("holdout_frost_effect")
			frost_effect:SetLevel(1)
		end
	end

--	if npc:GetTeam() == DOTA_TEAM_NEUTRALS then
--		if not npc:HasAbility("holdout_frost_effect") then
--			local frost_effect = npc:AddAbility("holdout_frost_effect")
--			frost_effect:SetLevel(1)
--		end
--	end

	-- This internal handling is used to set up main barebones functions
	GameMode:_OnNPCSpawned(keys)
end

-- An entity somewhere has been hurt.  This event fires very often with many units so don't do too many expensive
-- operations here
function GameMode:OnEntityHurt(keys)
	--DebugPrint("[BAREBONES] Entity Hurt")
	--DebugPrintTable(keys)

	local damagebits = keys.damagebits -- This might always be 0 and therefore useless
	if keys.entindex_attacker ~= nil and keys.entindex_killed ~= nil then
	local entCause = EntIndexToHScript(keys.entindex_attacker)
	local entVictim = EntIndexToHScript(keys.entindex_killed)

	-- The ability/item used to damage, or nil if not damaged by an item/ability
	local damagingAbility = nil

	if keys.entindex_inflictor ~= nil then
		damagingAbility = EntIndexToHScript( keys.entindex_inflictor )
	end
	end
end

-- An item was picked up off the ground
function GameMode:OnItemPickedUp(keys)
	DebugPrint( '[BAREBONES] OnItemPickedUp' )
	DebugPrintTable(keys)

	local heroEntity = EntIndexToHScript(keys.HeroEntityIndex)
	local itemEntity = EntIndexToHScript(keys.ItemEntityIndex)
	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local itemname = keys.itemname
end

-- A player has reconnected to the game. This function can be used to repaint Player-based particles or change
-- state as necessary
function GameMode:OnPlayerReconnect(keys)
	DebugPrint( '[BAREBONES] OnPlayerReconnect' )
	DebugPrintTable(keys) 
end

-- An item was purchased by a player
function GameMode:OnItemPurchased( keys )
	DebugPrint( '[BAREBONES] OnItemPurchased' )
	DebugPrintTable(keys)

	-- The playerID of the hero who is buying something
	local plyID = keys.PlayerID
	if not plyID then return end

	-- The name of the item purchased
	local itemName = keys.itemname 
	
	-- The cost of the item purchased
	local itemcost = keys.itemcost
	
end

-- An ability was used by a player
function GameMode:OnAbilityUsed(keys)
	DebugPrint('[BAREBONES] AbilityUsed')
	DebugPrintTable(keys)

	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local abilityname = keys.abilityname
end

-- A non-player entity (necro-book, chen creep, etc) used an ability
function GameMode:OnNonPlayerUsedAbility(keys)
	DebugPrint('[BAREBONES] OnNonPlayerUsedAbility')
	DebugPrintTable(keys)

	local abilityname=  keys.abilityname
end

-- A player changed their name
function GameMode:OnPlayerChangedName(keys)
	DebugPrint('[BAREBONES] OnPlayerChangedName')
	DebugPrintTable(keys)

	local newName = keys.newname
	local oldName = keys.oldName
end

-- A player leveled up an ability
function GameMode:OnPlayerLearnedAbility( keys)
	DebugPrint('[BAREBONES] OnPlayerLearnedAbility')
	DebugPrintTable(keys)

	local player = EntIndexToHScript(keys.player)
	local abilityname = keys.abilityname
end

-- A channelled ability finished by either completing or being interrupted
function GameMode:OnAbilityChannelFinished(keys)
	DebugPrint('[BAREBONES] OnAbilityChannelFinished')
	DebugPrintTable(keys)

	local abilityname = keys.abilityname
	local interrupted = keys.interrupted == 1
end

-- A player leveled up
function GameMode:OnPlayerLevelUp(keys)
DebugPrint('[BAREBONES] OnPlayerLevelUp')
DebugPrintTable(keys)
local player = EntIndexToHScript(keys.player)
local level = keys.level
local hero = player:GetAssignedHero()
local hero_level = hero:GetLevel()

local AbilitiesHeroes_XX = {
	npc_dota_hero_elder_titan = {{"holdout_shockwave_20", 0}, {"holdout_war_stomp_20", 1}, {"holdout_roar_20", 4}, {"holdout_reincarnation", 6}},
	npc_dota_hero_enchantress = {{"neutral_spell_immunity", 6}},
	npc_dota_hero_omniknight = {{"holdout_light_frenzy", 4}},
	npc_dota_hero_sniper ={{"holdout_rocket_launcher_20", 0}, {"holdout_plasma_rifle_20", 1}},
	npc_dota_hero_sven = {{"holdout_storm_bolt_20", 0}, {"holdout_thunder_clap_20", 1}},
	npc_dota_hero_brewmaster = {{"enraged_wildkin_tornado", 4}},
	npc_dota_hero_nevermore = {{"holdout_rain_of_chaos_20", 6}},
	}

	if hero_level == 17 then -- Debug because 7.0
		hero:SetAbilityPoints( hero:GetAbilityPoints() + 1 )
	elseif hero_level > 19 then
		hero:SetAbilityPoints( hero:GetAbilityPoints() - 1 )
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
			hero:RemoveAbility("axe_berserkers_call")
		end
	end

	if hero:GetUnitName() == "npc_dota_hero_chaos_knight" then
		local stacks = hero:GetLevel()
		hero:SetModifierStackCount("modifier_power_mount_str", caster, stacks) -- Power Mount(STR) Level Up
		hero:SetModifierStackCount("modifier_power_mount_agi", caster, stacks) -- Power Mount(AGI) Level Up
		hero:SetModifierStackCount("modifier_power_mount_int", caster, stacks) -- Power Mount(INT) Level Up
		hero:SetModifierStackCount("modifier_dark_cleave_dummy", caster, stacks) -- Dark Cleave Level Up
		hero:SetAbilityPoints( hero:GetAbilityPoints() - 1 )

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
		hero:SetAbilityPoints( hero:GetAbilityPoints() - 1 )

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
		-- level up all abilities, that are not leveled up
		for i = 0,15 do 
		local ability = hero:GetAbilityByIndex(i)
			if IsValidEntity(ability) then
				if ability:GetLevel() < ability:GetMaxLevel() then
					for j = 1, ability:GetMaxLevel() - ability:GetLevel() do
					hero:UpgradeAbility(ability)
					end
				end
			end
		end

		Notifications:Top(hero:GetPlayerOwnerID(), {text="You've reached level 20. Check out your new abilities! ",duration = 10})

		for _,ability in pairs(AbilitiesHeroes_XX[hero:GetUnitName()]) do
			if ability ~= nil then
				Notifications:Top(hero:GetPlayerOwnerID(), {ability=ability[1] ,continue=true})
				hero:AddAbility(ability[1])
				hero:UpgradeAbility(hero:FindAbilityByName(ability[1]))
				local oldab = hero:GetAbilityByIndex(ability[2])
				if oldab:GetAutoCastState() then 
					oldab:ToggleAutoCast()
				end
				hero:SwapAbilities(oldab:GetName(),ability[1],true,true)
			end
		end
	end
end

-- A player last hit a creep, a tower, or a hero
function GameMode:OnLastHit(keys)
	DebugPrint('[BAREBONES] OnLastHit')
	DebugPrintTable(keys)

	local isFirstBlood = keys.FirstBlood == 1
	local isHeroKill = keys.HeroKill == 1
	local isTowerKill = keys.TowerKill == 1
	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local killedEnt = EntIndexToHScript(keys.EntKilled)
end

-- A tree was cut down by tango, quelling blade, etc
function GameMode:OnTreeCut(keys)
	DebugPrint('[BAREBONES] OnTreeCut')
	DebugPrintTable(keys)

	local treeX = keys.tree_x
	local treeY = keys.tree_y
end

-- A rune was activated by a player
function GameMode:OnRuneActivated (keys)
	DebugPrint('[BAREBONES] OnRuneActivated')
	DebugPrintTable(keys)

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

-- A player took damage from a tower
function GameMode:OnPlayerTakeTowerDamage(keys)
	DebugPrint('[BAREBONES] OnPlayerTakeTowerDamage')
	DebugPrintTable(keys)

	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local damage = keys.damage
end

-- A player picked a hero
function GameMode:OnPlayerPickHero(keys)
	DebugPrint('[BAREBONES] OnPlayerPickHero')
	DebugPrintTable(keys)

	local heroClass = keys.hero
	local heroEntity = EntIndexToHScript(keys.heroindex)
	local player = EntIndexToHScript(keys.player)
	local heroes = HeroList:GetAllHeroes()

	-- modifies the name/label of a player
--	GameMode:setPlayerHealthLabel(player)
end

-- A player killed another player in a multi-team context
function GameMode:OnTeamKillCredit(keys)
	DebugPrint('[BAREBONES] OnTeamKillCredit')
	DebugPrintTable(keys)

	local killerPlayer = PlayerResource:GetPlayer(keys.killer_userid)
	local victimPlayer = PlayerResource:GetPlayer(keys.victim_userid)
	local numKills = keys.herokills
	local killerTeamNumber = keys.teamnumber
end

-- An entity died
function GameMode:OnEntityKilled( keys )
DebugPrint( '[BAREBONES] OnEntityKilled Called' )
DebugPrintTable( keys )

GameMode:_OnEntityKilled( keys )

-- The Unit that was Killed
local killedUnit = EntIndexToHScript( keys.entindex_killed )
-- The Killing entity
local killerEntity = nil

if keys.entindex_attacker ~= nil then
	killerEntity = EntIndexToHScript( keys.entindex_attacker )
end

-- The ability/item used to kill, or nil if not killed by an item/ability
local killerAbility = nil

if keys.entindex_inflictor ~= nil then
	killerAbility = EntIndexToHScript( keys.entindex_inflictor )
end

local damagebits = keys.damagebits -- This might always be 0 and therefore useless
local KillerID = killerEntity:GetPlayerOwnerID()
local playerKills = PlayerResource:GetKills(KillerID)

	-- Should grants kills to the hero assigned to the unit
	if IsValidEntity(killerEntity:GetPlayerOwner()) then
		killerEntity = killerEntity:GetPlayerOwner():GetAssignedHero()
	end

	-- if killed by illusion, change the killer to the owner of illusion instead
	if killerEntity:IsIllusion() then
		killerEntity = PlayerResource:GetPlayer(killerEntity:GetPlayerID()):GetAssignedHero()
	end

	-- Set Kill Count to the Player's Last Hit Count
	if killerEntity:IsRealHero() and killedUnit:GetTeam() == DOTA_TEAM_BADGUYS then
		if PlayerResource:HasSelectedHero(KillerID) then
			killerEntity:IncrementKills(1)
		end
		elseif killerEntity:IsRealHero() and killedUnit:GetTeam() == DOTA_TEAM_NEUTRALS then
		if PlayerResource:HasSelectedHero(KillerID) then
			killerEntity:IncrementKills(1)
		end
	else
		return nil
	end

	if killerEntity:GetKills() == 100 then
		Notifications:Top(killerEntity:GetPlayerOwnerID(), {text="100 kills. You get 5000 gold.", duration=5.0, style={color="red"}})
		PlayerResource:ModifyGold( killerEntity:GetPlayerOwnerID(), 5000, false,  DOTA_ModifyGold_Unspecified )
	elseif killerEntity:GetKills() == 500 then
		Notifications:Top(killerEntity:GetPlayerOwnerID(), {text="500 kills. You get 25000 gold.", duration=5.0, style={color="red"}})
		PlayerResource:ModifyGold( killerEntity:GetPlayerOwnerID(), 25000, false,  DOTA_ModifyGold_Unspecified )
	elseif killerEntity:GetKills() == 1000 then
		Notifications:Top(killerEntity:GetPlayerOwnerID(), {text="1000 kills. You get 50000 gold.", duration=5.0, style={color="red"}})
		PlayerResource:ModifyGold( killerEntity:GetPlayerOwnerID(), 50000, false,  DOTA_ModifyGold_Unspecified )
	elseif killerEntity:GetKills() >= 940 and RAMERO == 0 and NEUTRAL_SPAWN == 0 then -- 940
	local point = Entities:FindByName(nil, "npc_dota_muradin_player_1"):GetAbsOrigin()
		killerEntity:AddNewModifier( nil, nil, "modifier_animation_freeze_stun", nil)
		killerEntity:AddNewModifier( nil, nil, "modifier_invulnerable", nil)
		Notifications:TopToAll({text="A hero has reached 80 Wave kills and will fight Ramero and Baristal!", style={color="white"}, duration=5.0})
		Timers:CreateTimer(5.0, function()
			FindClearSpaceForUnit(killerEntity, point, true)
			PlayerResource:SetCameraTarget(killerEntity:GetPlayerOwnerID(), killerEntity)
			RameroEvent()
			killerEntity:RemoveModifierByName("modifier_animation_freeze_stun")
			killerEntity:RemoveModifierByName("modifier_invulnerable")
			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(killerEntity:GetPlayerOwnerID(), nil)
			end)
		end)
		RAMERO = 1
	end

	-- Ends lanes spawning when the linked barrackment is destroyed
	for c = 1, 8 do
		if killedUnit:GetUnitName() == "dota_badguys_barracks_"..c then
			BARRACKMENTS[c] = 0
			CREEP_LANES[c] = 0
			print(BARRACKMENTS[c])
		elseif killerEntity:IsIllusion() and killedUnit:GetUnitName() == "dota_badguys_barracks_"..c then
			BARRACKMENTS[c] = 0
			CREEP_LANES[c] = 0
		end
	end

	if killedUnit:GetUnitName() == "npc_ramero" then
		local item = CreateItem("item_lightning_sword", nil, nil)
		local pos = killedUnit:GetAbsOrigin()
		local drop = CreateItemOnPositionSync( pos, item )
		item:LaunchLoot(false, 300, 0.5, pos)
	end

	if killedUnit:GetUnitName() == "npc_baristal" then
		local item = CreateItem("item_tome_big", nil, nil)
		local pos = killedUnit:GetAbsOrigin()
		local drop = CreateItemOnPositionSync( pos, item )
		item:LaunchLoot(false, 300, 0.5, pos)
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
		end
	end

	if killedUnit:GetUnitName() == "npc_dota_boss_spirit_master_fire" then
		SPIRIT_MASTER = SPIRIT_MASTER + 1
	end
	if killedUnit:GetUnitName() == "npc_dota_boss_spirit_master_storm" then
		SPIRIT_MASTER = SPIRIT_MASTER + 1
	end
	if killedUnit:GetUnitName() == "npc_dota_boss_spirit_master_earth" then
		SPIRIT_MASTER = SPIRIT_MASTER + 1
	end
	if SPIRIT_MASTER >= 3 then
		GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
	end
end

-- This function is called 1 to 2 times as the player connects initially but before they have completely connected
function GameMode:PlayerConnect(keys)
	DebugPrint('[BAREBONES] PlayerConnect')
	DebugPrintTable(keys)
end

-- This function is called once when the player fully connects and becomes "Ready" during Loading
function GameMode:OnConnectFull(keys)
	DebugPrint('[BAREBONES] OnConnectFull')
	DebugPrintTable(keys)

	GameMode:_OnConnectFull(keys)
	
	local entIndex = keys.index+1
	-- The Player entity of the joining user
	local ply = EntIndexToHScript(entIndex)
	
	-- The Player ID of the joining player
	local playerID = ply:GetPlayerID()

	-- If this is Mohammad Mehdi Akhondi, end the game. Dota Imba ban system.
	for i = 1, #banned_players do
		if PlayerResource:GetSteamAccountID(ply:GetPlayerID()) == banned_players[i] then
			Timers:CreateTimer(5.0, function()
				GameRules:SetGameWinner(DOTA_TEAM_BADGUYS)
			end)
			GameRules:SetHeroSelectionTime(1.0)
			GameRules:SetPreGameTime(1.0)
			GameRules:SetPostGameTime(5.0)
			GameRules:SetCustomGameSetupAutoLaunchDelay(0.0)
			Say(nil, "<font color='#FF0000'>Mohammad Mehdi Akhondi</font> detected, game will not start. Please disconnect.", false)
		end
	end
end

-- This function is called whenever illusions are created and tells you which was/is the original entity
function GameMode:OnIllusionsCreated(keys)
	DebugPrint('[BAREBONES] OnIllusionsCreated')
	DebugPrintTable(keys)

	local originalEntity = EntIndexToHScript(keys.original_entindex)
end

-- This function is called whenever an item is combined to create a new item
function GameMode:OnItemCombined(keys)
	DebugPrint('[BAREBONES] OnItemCombined')
	DebugPrintTable(keys)

	-- The playerID of the hero who is buying something
	local plyID = keys.PlayerID
	if not plyID then return end
	local player = PlayerResource:GetPlayer(plyID)

	-- The name of the item purchased
	local itemName = keys.itemname 
	
	-- The cost of the item purchased
	local itemcost = keys.itemcost
end

-- This function is called whenever an ability begins its PhaseStart phase (but before it is actually cast)
function GameMode:OnAbilityCastBegins(keys)
	DebugPrint('[BAREBONES] OnAbilityCastBegins')
	DebugPrintTable(keys)

	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local abilityName = keys.abilityname
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
local goalEntity = EntIndexToHScript(keys.goal_entindex)
local nextGoalEntity = EntIndexToHScript(keys.next_goal_entindex)
local npc = EntIndexToHScript(keys.npc_entindex)

end

function GameMode:OnPlayerChat(keys)
local teamonly = keys.teamonly
local userID = keys.userid
local playerID = self.vUserIds[userID]:GetPlayerID()
local text = keys.text
local player = PlayerResource:GetPlayer(playerID)
	for str in string.gmatch(text, "%S+") do
		if GameRules:PlayerHasCustomGameHostPrivileges(player) then
			if str == "-openway_1" or str == "-ow1" then
				if BARRACKMENTS[1] == 1 then
					Notifications:TopToAll({text="Red Player opened lane 1!", style={color="white"}, duration=5.0})
					CREEP_LANES[1] = 1
				elseif BARRACKMENTS[1] == 0 then
					Notifications:TopToAll({text="Can't open Lane 1, barrackment destroyed!", style={color="white"}, duration=5.0})
				end
			end
			if str == "-openway_2" or str == "-ow2" then
				if BARRACKMENTS[2] == 1 then
					Notifications:TopToAll({text="Red Player opened lane 2!", style={color="white"}, duration=5.0})
					CREEP_LANES[2] = 1
				elseif BARRACKMENTS[2] == 0 then
					Notifications:TopToAll({text="Can't open Lane 2, barrackment destroyed!", style={color="white"}, duration=5.0})
				end
			end
			if str == "-openway_3" or str == "-ow3" then
				if BARRACKMENTS[3] == 1 then
					Notifications:TopToAll({text="Red Player opened lane 3!", style={color="white"}, duration=5.0})
					CREEP_LANES[3] = 1
				elseif BARRACKMENTS[3] == 0 then
					Notifications:TopToAll({text="Can't open Lane 3, barrackment destroyed!", style={color="white"}, duration=5.0})
				end
			end
			if str == "-openway_4" or str == "-ow4" then
				if BARRACKMENTS[4] == 1 then
					Notifications:TopToAll({text="Red Player opened lane 4!", style={color="white"}, duration=5.0})
					CREEP_LANES[4] = 1
				elseif BARRACKMENTS[4] == 0 then
					Notifications:TopToAll({text="Can't open Lane 4, barrackment destroyed!", style={color="white"}, duration=5.0})
				end
			end
			if str == "-openway_5" or str == "-ow5" then
				if BARRACKMENTS[5] == 1 then
					Notifications:TopToAll({text="Red Player opened lane 5!", style={color="white"}, duration=5.0})
					CREEP_LANES[5] = 1
				elseif BARRACKMENTS[5] == 0 then
					Notifications:TopToAll({text="Can't open Lane 5, barrackment destroyed!", style={color="white"}, duration=5.0})
				end
			end
			if str == "-openway_6" or str == "-ow6" then
				if BARRACKMENTS[6] == 1 then
					Notifications:TopToAll({text="Red Player opened lane 6!", style={color="white"}, duration=5.0})
					CREEP_LANES[6] = 1
				elseif BARRACKMENTS[6] == 0 then
					Notifications:TopToAll({text="Can't open Lane 6, barrackment destroyed!", style={color="white"}, duration=5.0})
				end
			end
			if str == "-openway_7" or str == "-ow7" then
				if BARRACKMENTS[7] == 1 then
					Notifications:TopToAll({text="Red Player opened lane 7!", style={color="white"}, duration=5.0})
					CREEP_LANES[7] = 1
				elseif BARRACKMENTS[7] == 0 then
					Notifications:TopToAll({text="Can't open Lane 7, barrackment destroyed!", style={color="white"}, duration=5.0})
				end
			end
			if str == "-openway_8" or str == "-ow8" then
				if BARRACKMENTS[8] == 1 then
					Notifications:TopToAll({text="Red Player opened lane 8!", style={color="white"}, duration=5.0})
					CREEP_LANES[8] = 1
				elseif BARRACKMENTS[8] == 0 then
					Notifications:TopToAll({text="Can't open Lane 8, barrackment destroyed!", style={color="white"}, duration=5.0})
				end
			end

			if str == "-closeway_1" or str == "-cw1" then
				Notifications:TopToAll({text="Red Player closed lane 1!", style={color="white"}, duration=5.0})
--				Notifications:TopToAll({text="Lanes 1, 2, 3, 4 can't be closed!", style={color="white"}, duration=5.0})
				CREEP_LANES[1] = 0
			end
			if str == "-closeway_2" or str == "-cw2" then
				Notifications:TopToAll({text="Red Player closed lane 2!", style={color="white"}, duration=5.0})
--				Notifications:TopToAll({text="Lanes 1, 2, 3, 4 can't be closed", style={color="white"}, duration=5.0})
				CREEP_LANES[2] = 0
			end
			if str == "-closeway_3" or str == "-cw3" then
				Notifications:TopToAll({text="Red Player closed lane 3!", style={color="white"}, duration=5.0})
--				Notifications:TopToAll({text="Lanes 1, 2, 3, 4 can't be closed", style={color="white"}, duration=5.0})
				CREEP_LANES[3] = 0
			end
			if str == "-closeway_4" or str == "-cw4" then
				Notifications:TopToAll({text="Red Player closed lane 4!", style={color="white"}, duration=5.0})
--				Notifications:TopToAll({text="Lanes 1, 2, 3, 4 can't be closed", style={color="white"}, duration=5.0})
				CREEP_LANES[4] = 0
			end
			if str == "-closeway_5" or str == "-cw5" then
				Notifications:TopToAll({text="Red Player closed lane 5!", style={color="white"}, duration=5.0})
				CREEP_LANES[5] = 0
			end
			if str == "-closeway_6" or str == "-cw6" then
				Notifications:TopToAll({text="Red Player closed lane 6!", style={color="white"}, duration=5.0})
				CREEP_LANES[6] = 0
			end
			if str == "-closeway_7" or str == "-cw7" then
				Notifications:TopToAll({text="Red Player closed lane 7!", style={color="white"}, duration=5.0})
				CREEP_LANES[7] = 0
			end
			if str == "-closeway_8" or str == "-cw8" then
				Notifications:TopToAll({text="Red Player closed lane 8!", style={color="white"}, duration=5.0})
				CREEP_LANES[8] = 0
			end

			if str == "-openway_all" or str == "-ow_all" then
				Notifications:TopToAll({text="Red Player opened all lanes!", style={color="white"}, duration=5.0})
				CREEP_LANES[1] = 1
				CREEP_LANES[2] = 1
				CREEP_LANES[3] = 1
				CREEP_LANES[4] = 1
				CREEP_LANES[5] = 1
				CREEP_LANES[6] = 1
				CREEP_LANES[7] = 1
				CREEP_LANES[8] = 1
			end

			if str == "-closeway_all" or str == "-cw_all" then
				Notifications:TopToAll({text="Red Player closed all lanes!", style={color="white"}, duration=5.0})
--				Notifications:TopToAll({text="Red Player closed all lanes (excluding 1, 2, 3, 4)!", style={color="white"}, duration=5.0})
				CREEP_LANES[1] = 0
				CREEP_LANES[2] = 0
				CREEP_LANES[3] = 0
				CREEP_LANES[4] = 0
				CREEP_LANES[5] = 0
				CREEP_LANES[6] = 0
				CREEP_LANES[7] = 0
				CREEP_LANES[8] = 0
			end
		end

		if str == "-credits" then
			Notifications:TopToAll({text="Mod created by [BEAR] Cookies #42, thanks to Noya for WC3 database ported to dota!", style={color="white"}, duration=5.0})
		end

		if str == "-difficulty" then
			local diff = {"Easy","Normal","Hard","Extreme"}
			Notifications:TopToAll({text="DIFFICULTY: "..diff[GameRules:GetCustomGameDifficulty()], duration=10.0})
		end

		if str == "-bt" then
		local hero = PlayerResource:GetPlayer(playerID):GetAssignedHero()
		local gold = hero:GetGold()
		local cost = 10000
		local numberOfTomes = math.floor(gold / cost)
			if numberOfTomes >= 1 and BT_ENABLED == 1 then
				PlayerResource:SpendGold(playerID, (numberOfTomes) * cost, DOTA_ModifyGold_PurchaseItem)
				hero:ModifyAgility(numberOfTomes * 50)
				hero:ModifyStrength(numberOfTomes * 50)
				hero:ModifyIntellect(numberOfTomes * 50)
				hero:EmitSound("ui.trophy_levelup")
				local particle1 = ParticleManager:CreateParticle("particles/econ/events/ti6/hero_levelup_ti6.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
				ParticleManager:SetParticleControl(particle1, 0, hero:GetAbsOrigin())
				Notifications:Top(player, {text="You've bought "..numberOfTomes.." Tomes!", duration=5.0, style={color="white"}})
			elseif numberOfTomes < 1 then
				Notifications:Top(player, {text="You don't have enough gold to afford tomes!", duration=5.0, style={color="white"}})
			elseif BT_ENABLED == 0 then
				Notifications:Top(player, {text="You are not allowed to buy tomes in this arena!", duration=5.0, style={color="white"}})
			end
		end
	end
end
