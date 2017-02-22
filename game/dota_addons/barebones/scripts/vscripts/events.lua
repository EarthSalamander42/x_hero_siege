require("libraries/playertables")
require("libraries/selection")

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
local hero_level = npc:GetLevel()

	if difficulty == 1 and not npc:IsHero() and npc:GetTeam() == DOTA_TEAM_BADGUYS then
		npc:SetMinimumGoldBounty( normal_bounty*1.5 )
		npc:SetMaximumGoldBounty( normal_bounty*1.5 )
		npc:SetDeathXP( normal_xp*1.25 )
		npc:SetBaseDamageMin( normal_min_damage*0.75 )
		npc:SetBaseDamageMax( normal_max_damage*0.75 )
	elseif difficulty == 2 and not npc:IsHero() and npc:GetTeam() == DOTA_TEAM_BADGUYS then
		npc:SetMinimumGoldBounty( normal_bounty*1.1 )
		npc:SetMaximumGoldBounty( normal_bounty*1.1 )
		npc:SetDeathXP( normal_xp )
		npc:SetBaseDamageMin( normal_min_damage )
		npc:SetBaseDamageMax( normal_max_damage )
	elseif difficulty == 3 and not npc:IsHero() and npc:GetTeam() == DOTA_TEAM_BADGUYS then
--		npc:SetMinimumGoldBounty( normal_bounty*0.9 )
--		npc:SetMaximumGoldBounty( normal_bounty*0.9 )
		npc:SetDeathXP( normal_xp*0.9 )
		npc:SetBaseDamageMin( normal_min_damage*1.25 )
		npc:SetBaseDamageMax( normal_max_damage*1.25 )
	elseif difficulty == 4 and not npc:IsHero() and npc:GetTeam() == DOTA_TEAM_BADGUYS then
--		npc:SetMinimumGoldBounty( normal_bounty*0.75 )
--		npc:SetMaximumGoldBounty( normal_bounty*0.75 )
		npc:SetDeathXP( normal_xp*0.75 )
		npc:SetBaseDamageMin( normal_min_damage*1.5 )
		npc:SetBaseDamageMax( normal_max_damage*1.5 )
	end

	if npc:GetUnitName() == "npc_dota_hero_tiny" then
		npc:AddAbility("tiny_grow")
		grow = npc:FindAbilityByName("tiny_grow")
		grow:SetLevel(1)
		npc:SetModelScale( 1.1 )
		Timers:CreateTimer(0.4, function()
			npc:RemoveAbility("tiny_grow")
		end)
	end

	--debug
	if npc:GetUnitName() == "npc_dota_hero_tiny" and hero_level >= 20 then
		local ability = npc:FindAbilityByName("holdout_war_club_20")
		npc:RemoveModifierByName("modifier_item_ultimate_scepter_consumed")
		npc:AddNewModifier(npc, ability, "modifier_item_ultimate_scepter_consumed", {})
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
		"holdout_taunt",
		"holdout_banish",
		"holdout_magic_shield",
		"holdout_anubarak_claw",
		"undead_burrow",
		"ogre_magi_bloodlust",
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
		"holdout_reincarnation",
		"holdout_power_mount_str",
		"holdout_power_mount_int",
		"holdout_power_mount_agi",
		"holdout_mechanism",
		"holdout_dark_cleave",
		"holdout_skin_changer_caster",
		"holdout_skin_changer_warrior",
		"holdout_health_buff",
		"pugna_decrepify",
		"holdout_giant_form",
		"holdout_monkey_king_bar",
		"holdout_stitch",
		"troll_warlord_berserkers_rage",
		"holdout_random_hero",
--		"troll_warlord_whirling_axes_ranged",
--		"troll_warlord_whirling_axes_melee",
		"holdout_yellow_effect", --Desert Wyrm Ultimate effect
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

	if npc:GetTeam() == DOTA_TEAM_GOODGUYS then
		for i = 1, #golden_vip_members do
			if npc:IsRealHero() then
				-- Cookies or X Hero Siege Official
				if PlayerResource:GetSteamAccountID(npc:GetPlayerID()) == mod_creator[i] then
					npc:SetCustomHealthLabel("Mod Creator", 200, 45, 45)
					if not npc:HasAbility("holdout_vip") then
						local vip_ability = npc:AddAbility("holdout_vip")
						vip_ability:SetLevel(1)
					end
				end
				-- Baumi
				if PlayerResource:GetSteamAccountID(npc:GetPlayerID()) == captain_baumi[i] then
					npc:SetCustomHealthLabel("Baumi Nation is real!", 55, 55, 200)
					if not npc:HasAbility("holdout_vip") then
						local vip_ability = npc:AddAbility("holdout_vip")
						vip_ability:SetLevel(1)
					end
				end
				-- Mugiwara or Flotos
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

	-- This internal handling is used to set up main barebones functions
	GameMode:_OnNPCSpawned(keys)
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
			damagingAbility = EntIndexToHScript( keys.entindex_inflictor )
		end
	end

--	if entVictim:GetUnitName() == "npc_dota_defender_fort" and entVictim:GetHealthPercent() <= 40 then
--	if entVictim:IsAncient() then
--		print("Ancient hurt!")
--		local Waypoint = Entities:FindByName(nil, "final_wave_player_1")
--		local InvTime = 30.0
--		local PauseTime = 10.0
--		if MURADIN_DEF == 0 then
--			print("Muradin check..")
--			local Muradin = CreateUnitByName("npc_dota_creature_muradin_bronzebeard", Waypoint:GetAbsOrigin(), false, nil, nil, DOTA_TEAM_GOODGUYS)
--			Muradin:SetInitialGoalEntity(Waypoint)
--			Muradin:MoveToPositionAggressive(Waypoint:GetAbsOrigin())
--			PauseCreepsCastle()
--			entVictim:AddNewModifier(entVictim, nil, "modifier_invulnerable", {duration = InvTime + PauseTime})
--			Notifications:BottomToAll({text = "Muradin is requested to defend your castle!", duration = PauseTime, continue = true})
--			Timers:CreateTimer(InvTime + PauseTime, function() 
--				UTIL_Remove(Muradin)
--			end)
--			print("Muradin working!")
--		end
--	end
end

-- An item was picked up off the ground
function GameMode:OnItemPickedUp(keys)
local heroEntity = EntIndexToHScript(keys.HeroEntityIndex)
local itemEntity = EntIndexToHScript(keys.ItemEntityIndex)
local player = PlayerResource:GetPlayer(keys.PlayerID)
local itemname = keys.itemname

end

-- A player has reconnected to the game. This function can be used to repaint Player-based particles or change
-- state as necessary
function GameMode:OnPlayerReconnect(keys)

end

-- An item was purchased by a player
function GameMode:OnItemPurchased( keys )
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
	local abilityname = keys.abilityname
end

function GameMode:OnNonPlayerUsedAbility(keys)
	local abilityname = keys.abilityname
end

function GameMode:OnPlayerChangedName(keys)
	local newName = keys.newname
	local oldName = keys.oldName
end

function GameMode:OnPlayerLearnedAbility(keys)
	local player = EntIndexToHScript(keys.player)
	local abilityname = keys.abilityname
end

function GameMode:OnAbilityChannelFinished(keys)
	local abilityname = keys.abilityname
	local interrupted = keys.interrupted == 1
end

function GameMode:OnPlayerLevelUp(keys)
local player = EntIndexToHScript(keys.player)
local level = keys.level
local hero = player:GetAssignedHero()
local hero_level = hero:GetLevel()

local AbilitiesHeroes_XX = {
		npc_dota_hero_abyssal_underlord = {{"lion_finger_of_death", 2}},
		npc_dota_hero_brewmaster = {{"enraged_wildkin_tornado", 4}},
		npc_dota_hero_chen = {{"holdout_frost_shield", 2}},
		npc_dota_hero_crystal_maiden = {{"holdout_rain_of_ice", 2}},
		npc_dota_hero_dragon_knight = {{"holdout_knights_armor", 6}},
		npc_dota_hero_elder_titan = {{"holdout_shockwave_20", 0}, {"holdout_war_stomp_20", 1}, {"holdout_roar_20", 4}, {"holdout_reincarnation", 6}},
		npc_dota_hero_enchantress = {{"neutral_spell_immunity", 6}},
		npc_dota_hero_invoker = {{"holdout_rain_of_fire", 2}},
		npc_dota_hero_juggernaut = {{"brewmaster_primal_split", 2}},
		npc_dota_hero_lich = {{"holdout_frost_chaos", 4}},
		npc_dota_hero_luna = {{"holdout_neutralization", 2}},
		npc_dota_hero_nevermore = {{"holdout_rain_of_chaos_20", 6}},
		npc_dota_hero_nyx_assassin = {{"holdout_burrow_impale", 2}},
		npc_dota_hero_omniknight = {{"holdout_light_frenzy", 2}},
		npc_dota_hero_phantom_assassin = {{"holdout_morph", 2}},
		npc_dota_hero_pugna = {{"holdout_rain_of_chaos_20", 2}},
		npc_dota_hero_rattletrap = {{"holdout_cluster_rockets", 2}},
		npc_dota_hero_shadow_shaman = {{"holdout_hex", 2}},
		npc_dota_hero_sniper ={{"holdout_rocket_launcher_20", 0}, {"holdout_plasma_rifle_20", 1}},
		npc_dota_hero_sven = {{"holdout_storm_bolt_20", 0}, {"holdout_thunder_clap_20", 1}},
		npc_dota_hero_terrorblade = {{"holdout_resistant_skin", 6}},
		npc_dota_hero_tiny = {{"holdout_war_club_20", 0}},
		npc_dota_hero_windrunner = {{"holdout_rocket_hail", 2}}
	}

	if hero_level == 17 then -- Debug because 7.0
		hero:SetAbilityPoints( hero:GetAbilityPoints() + 1 )
	elseif hero_level > 19 then
		hero:SetAbilityPoints( hero:GetAbilityPoints() - 1 )
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

function GameMode:OnRuneActivated (keys)
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
local heroes = HeroList:GetAllHeroes()

	-- modifies the name/label of a player
--	GameMode:setPlayerHealthLabel(player)
end

function GameMode:OnTeamKillCredit(keys)
local killerPlayer = PlayerResource:GetPlayer(keys.killer_userid)
local victimPlayer = PlayerResource:GetPlayer(keys.victim_userid)
local numKills = keys.herokills
local killerTeamNumber = keys.teamnumber

end

function GameMode:OnEntityKilled( keys )
GameMode:_OnEntityKilled( keys )

local killedUnit = EntIndexToHScript( keys.entindex_killed )
local killerEntity = nil

if keys.entindex_attacker ~= nil then
	killerEntity = EntIndexToHScript( keys.entindex_attacker )
end

local killerAbility = nil

if keys.entindex_inflictor ~= nil then
	killerAbility = EntIndexToHScript( keys.entindex_inflictor )
end

	-- Tiny Debug, but will work with all other new heroes using aghanim modifiers
	killedUnit:RemoveModifierByName("modifier_item_ultimate_scepter_consumed")
	killedUnit:RemoveModifierByName("modifier_animation_translate")

local damagebits = keys.damagebits -- This might always be 0 and therefore useless
local KillerID = killerEntity:GetPlayerOwnerID()
local playerKills = PlayerResource:GetKills(KillerID)

	if IsValidEntity(killerEntity:GetPlayerOwner()) then
		killerEntity = killerEntity:GetPlayerOwner():GetAssignedHero()
	end

	if killerEntity:IsIllusion() then
		killerEntity = PlayerResource:GetPlayer(killerEntity:GetPlayerID()):GetAssignedHero()
	end

	if killerEntity:IsRealHero() then
		if killerEntity:GetKills() == 99 then
			Notifications:Top(killerEntity:GetPlayerOwnerID(), {text="100 kills. You get 7500 gold.", duration=5.0, style={color="red"}})
			PlayerResource:ModifyGold( killerEntity:GetPlayerOwnerID(), 7500, false,  DOTA_ModifyGold_Unspecified )
		elseif killerEntity:GetKills() == 199 then
			Notifications:Top(killerEntity:GetPlayerOwnerID(), {text="200 kills. You get 25000 gold.", duration=5.0, style={color="red"}})
			PlayerResource:ModifyGold( killerEntity:GetPlayerOwnerID(), 25000, false,  DOTA_ModifyGold_Unspecified )
		elseif killerEntity:GetKills() == 399 then
			Notifications:Top(killerEntity:GetPlayerOwnerID(), {text="400 kills. You get 50000 gold.", duration=5.0, style={color="red"}})
			PlayerResource:ModifyGold( killerEntity:GetPlayerOwnerID(), 50000, false,  DOTA_ModifyGold_Unspecified )
		elseif killerEntity:GetKills() >= 499 and RAMERO == 0 and NEUTRAL_SPAWN == 0 then --500
		local point = Entities:FindByName(nil, "npc_dota_muradin_player_1"):GetAbsOrigin()
			killerEntity:AddNewModifier( nil, nil, "modifier_animation_freeze_stun", nil)
			killerEntity:AddNewModifier( nil, nil, "modifier_invulnerable", nil)
			Notifications:TopToAll({text="A hero has reached 500 kills and will fight Ramero and Baristol!", style={color="white"}, duration=5.0})
			Timers:CreateTimer(5.0, function()
				FindClearSpaceForUnit(killerEntity, point, true)
				PlayerResource:SetCameraTarget(killerEntity:GetPlayerOwnerID(), killerEntity)
				RameroAndBaristolEvent()
				killerEntity:RemoveModifierByName("modifier_animation_freeze_stun")
				killerEntity:RemoveModifierByName("modifier_invulnerable")
				Timers:CreateTimer(0.1, function()
					PlayerResource:SetCameraTarget(killerEntity:GetPlayerOwnerID(), nil)
				end)
			end)
			RAMERO = 1
		elseif killerEntity:GetKills() >= 749 and RAMERO == 1 and NEUTRAL_SPAWN == 0 then --750
		local point = Entities:FindByName(nil, "npc_dota_muradin_player_1"):GetAbsOrigin()
			killerEntity:AddNewModifier( nil, nil, "modifier_animation_freeze_stun", nil)
			killerEntity:AddNewModifier( nil, nil, "modifier_invulnerable", nil)
			Notifications:TopToAll({text="A hero has reached 750 kills and will fight Ramero!", style={color="white"}, duration=5.0})
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
			RAMERO = 2
		end
	end

	if killerEntity:IsRealHero() and killedUnit:IsRealHero() and killedUnit:GetTeam() == DOTA_TEAM_GOODGUYS then
		if PlayerResource:HasSelectedHero(KillerID) then
			PlayerNumberRadiant = PlayerNumberRadiant - 1
			print("Radiant Team: "..PlayerNumberRadiant)
		end
	elseif killerEntity:IsRealHero() and killedUnit:IsRealHero() and killedUnit:GetTeam() == DOTA_TEAM_BADGUYS then
		if PlayerResource:HasSelectedHero(KillerID) then
			PlayerNumberDire = PlayerNumberDire - 1
			print("Dire Team: "..PlayerNumberDire)
		end
	elseif killerEntity:IsRealHero() and killedUnit:GetTeam() == DOTA_TEAM_BADGUYS then
		if PlayerResource:HasSelectedHero(KillerID) then
			killerEntity:IncrementKills(1)
		end
	elseif killerEntity:IsBuilding() and killedUnit:GetTeam() == DOTA_TEAM_BADGUYS then
		return nil
	end

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
	elseif killedUnit:GetUnitName() == "npc_baristol" then
		local item = CreateItem("item_tome_big", nil, nil)
		local pos = killedUnit:GetAbsOrigin()
		local drop = CreateItemOnPositionSync( pos, item )
		item:LaunchLoot(false, 300, 0.5, pos)
	elseif killedUnit:GetUnitName() == "npc_ramero_2" then
		local item = CreateItem("item_ring_of_superiority", nil, nil)
		local pos = killedUnit:GetAbsOrigin()
		local drop = CreateItemOnPositionSync( pos, item )
		item:LaunchLoot(false, 300, 0.5, pos)
	elseif killedUnit:GetUnitName() == "npc_dota_hero_secret" then
		local item = CreateItem("item_orb_of_frost", nil, nil)
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

	Corpses:CreateFromUnit(killedUnit)
end

function GameMode:PlayerConnect(keys)
	DebugPrint('[BAREBONES] PlayerConnect')
	DebugPrintTable(keys)
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
local abilityName = keys.abilityname
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
local userID = keys.userid
local playerID = self.vUserIds[userID]:GetPlayerID()
local text = keys.text
local player = PlayerResource:GetPlayer(playerID)

	for str in string.gmatch(text, "%S+") do
		for i = 1, #mod_creator do
			if PlayerResource:GetSteamAccountID(player:GetPlayerID()) == mod_creator[i] then
				for Frozen = 0, DOTA_MAX_TEAM_PLAYERS -1 do
					local PlayerNames = {"Red", "Blue", "Cyan", "Purple", "Yellow", "Orange", "Green", "Pink"}
					if PlayerResource:IsValidPlayer(Frozen) then
						if str == "-freeze_"..Frozen +1 then
							local hero = PlayerResource:GetPlayer(Frozen):GetAssignedHero()
							hero:AddNewModifier( nil, nil, "modifier_animation_freeze_stun", {})
							hero:AddNewModifier( nil, nil, "modifier_invulnerable", {})
							Notifications:BottomToAll({text="[ADMIN MOD]: ", duration=6.0, style={color="red", ["font-size"]="30px"}})
							Notifications:BottomToAll({text=PlayerNames[Frozen +1].." ", style={color=PlayerNames[Frozen +1], ["font-size"]="25px"}, continue=true})
							Notifications:BottomToAll({text="player has been jailed!", style={color="white", ["font-size"]="25px"}, continue=true})
						end
						if str == "-unfreeze_"..Frozen +1 then
							local hero = PlayerResource:GetPlayer(Frozen):GetAssignedHero()
							hero:RemoveModifierByName("modifier_animation_freeze_stun")
							hero:RemoveModifierByName("modifier_invulnerable")
							Notifications:BottomToAll({text="[ADMIN MOD]: ", duration=6.0, style={color="red", ["font-size"]="30px"}})
							Notifications:BottomToAll({text=PlayerNames[Frozen +1].." ", style={color=PlayerNames[Frozen +1], ["font-size"]="25px"}, continue=true})
							Notifications:BottomToAll({text="player has been released!", style={color="white", ["font-size"]="25px"}, continue=true})
						end
						if str == "-poison_"..Frozen +1 then
							local hero = PlayerResource:GetPlayer(Frozen):GetAssignedHero()
							local ability = hero:FindAbilityByName("holdout_shadow_strike")
							hero:AddNewModifier( hero, ability, "modifier_shadow_strike", {})
							Notifications:BottomToAll({text="[ADMIN MOD]: ", duration=6.0, style={color="red", ["font-size"]="30px"}})
							Notifications:BottomToAll({text=PlayerNames[Frozen +1].." ", style={color=PlayerNames[Frozen +1], ["font-size"]="25px"}, continue=true})
							Notifications:BottomToAll({text="player has been poisoned!", style={color="white", ["font-size"]="25px"}, continue=true})
						end
						if str == "-purge_"..Frozen +1 then
							local hero = PlayerResource:GetPlayer(Frozen):GetAssignedHero()
							hero:RemoveModifierByName("modifier_shadow_strike")
							hero:Purge( false, true, false, true, true)
							Notifications:BottomToAll({text="[ADMIN MOD]: ", duration=6.0, style={color="red", ["font-size"]="30px"}})
							Notifications:BottomToAll({text=PlayerNames[Frozen +1].." ", style={color=PlayerNames[Frozen +1], ["font-size"]="25px"}, continue=true})
							Notifications:BottomToAll({text="player has been purged!", style={color="white", ["font-size"]="25px"}, continue=true})
						end
						if str == "-kill_"..Frozen +1 then
							local hero = PlayerResource:GetPlayer(Frozen):GetAssignedHero()
							hero:ForceKill(true)
							Notifications:BottomToAll({text="[ADMIN MOD]: ", duration=6.0, style={color="red", ["font-size"]="30px"}})
							Notifications:BottomToAll({text=PlayerNames[Frozen +1].." ", style={color=PlayerNames[Frozen +1], ["font-size"]="25px"}, continue=true})
							Notifications:BottomToAll({text="player has been slayed!", style={color="white", ["font-size"]="25px"}, continue=true})
						end
						if str == "-revive_"..Frozen +1 then
							local hero = PlayerResource:GetPlayer(Frozen):GetAssignedHero()
							hero:RespawnHero(false, false, false)
							Notifications:BottomToAll({text="[ADMIN MOD]: ", duration=6.0, style={color="red", ["font-size"]="30px"}})
							Notifications:BottomToAll({text=PlayerNames[Frozen +1].." ", style={color=PlayerNames[Frozen +1], ["font-size"]="25px"}, continue=true})
							Notifications:BottomToAll({text="player has been revived!", style={color="white", ["font-size"]="25px"}, continue=true})
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
							Notifications:BottomToAll({text="[ADMIN MOD]: ", duration=6.0, style={color="red", ["font-size"]="30px"}})
							Notifications:BottomToAll({text=PlayerNames[Frozen +1].." ", style={color=PlayerNames[Frozen +1], ["font-size"]="25px"}, continue=true})
							Notifications:BottomToAll({text="player is in YOLO state!", style={color="white", ["font-size"]="25px"}, continue=true})
						end
						if str == "-unyolo_"..Frozen +1 then
							local hero = PlayerResource:GetPlayer(Frozen):GetAssignedHero()
							hero:SetMoveCapability(DOTA_UNIT_CAP_MOVE_GROUND)
							EndAnimation(hero)
							hero:StopSound("Hero_Batrider.Firefly.Loop")
							ParticleManager:DestroyParticle(yolo, true)
							ParticleManager:DestroyParticle(yolo2, true)
							Notifications:BottomToAll({text="[ADMIN MOD]: ", duration=6.0, style={color="red", ["font-size"]="30px"}})
							Notifications:BottomToAll({text=PlayerNames[Frozen +1].." ", style={color=PlayerNames[Frozen +1], ["font-size"]="25px"}, continue=true})
							Notifications:BottomToAll({text="player is not in YOLO state anymore.", style={color="white", ["font-size"]="25px"}, continue=true})
						end
					end
				end
			elseif not PlayerResource:GetSteamAccountID(player:GetPlayerID()) == mod_creator[i] then
				Notifications:Top(player:GetPlayerID(), {text="You are not allowed to use this command!", duration=6.0, style={color="white"}})
			end
		end

		local newState = GameRules:State_Get()
		if newState == DOTA_GAMERULES_STATE_PRE_GAME then
			Notifications:Bottom({player, text="Game has not started yet!", style={color="white"}, duration=5.0})
		elseif newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
			if GameRules:PlayerHasCustomGameHostPrivileges(player) or PlayerResource:GetSteamAccountID(player:GetPlayerID()) == mod_creator[i] then
				for t = 1, 8 do
					if str == "-openway_"..t or str == "-ow"..t then
						if BARRACKMENTS[t] == 1 then
							Notifications:TopToAll({text="Red Player opened lane "..t.."!", style={color="white"}, duration=5.0})
							CREEP_LANES[t] = 1
							local DoorObs = Entities:FindAllByName("obstruction_lane"..t)
							for _, obs in pairs(DoorObs) do 
								obs:SetEnabled(false, true)
							end
							DoEntFire("door_lane"..t, "SetAnimation", "gate_entrance002_open", 0, nil, nil)
							local towers = Entities:FindAllByName("dota_badguys_tower"..t)
							for _, tower in pairs(towers) do
								tower:RemoveModifierByName("modifier_invulnerable")
							end
							local raxes = Entities:FindAllByName("dota_badguys_barracks_"..t)
							for _, rax in pairs(raxes) do
								rax:RemoveModifierByName("modifier_invulnerable")
							end
						elseif BARRACKMENTS[t] == 0 then
							Notifications:TopToAll({text="Can't open Lane "..t..", barrackment destroyed!", style={color="white"}, duration=5.0})
						end
					end
				end

				for t = 1, 4 do
					if str == "-closeway_"..t or str == "-cw"..t then
						Notifications:TopToAll({text="Lanes 1, 2, 3, 4 can't be closed!", style={color="white"}, duration=5.0})
					end
				end

				for t = 5, 8 do
					if str == "-closeway_"..t or str == "-cw"..t then
						Notifications:TopToAll({text="Red Player closed lane "..t.."!", style={color="white"}, duration=5.0})
						CREEP_LANES[t] = 1
						local DoorObs = Entities:FindAllByName("obstruction_lane"..t)
						for _, obs in pairs(DoorObs) do 
							obs:SetEnabled(true, true)
						end
						DoEntFire("door_lane"..t, "SetAnimation", "gate_entrance002_idle", 0, nil, nil)
						local towers = Entities:FindAllByName("dota_badguys_tower"..t)
						for _, tower in pairs(towers) do
							tower:AddNewModifier(nil, nil, "modifier_invulnerable", nil)
						end
						local raxes = Entities:FindAllByName("dota_badguys_barracks_"..t)
						for _, rax in pairs(raxes) do
							rax:AddNewModifier(nil, nil, "modifier_invulnerable", nil)
						end
					end
				end

				if str == "-openway_all" or str == "-ow_all" then
					Notifications:TopToAll({text="Red Player opened all lanes!", style={color="white"}, duration=5.0})
					for t = 1, 8 do
						CREEP_LANES[t] = 1
						local DoorObs = Entities:FindAllByName("obstruction_lane"..t)
						for _, obs in pairs(DoorObs) do
							obs:SetEnabled(false, true)
						end
						DoEntFire("door_lane"..t, "SetAnimation", "gate_entrance002_open", 0, nil, nil)
						local towers = Entities:FindAllByName("dota_badguys_tower"..t)
						for _, tower in pairs(towers) do
							tower:RemoveModifierByName("modifier_invulnerable")
						end
						local raxes = Entities:FindAllByName("dota_badguys_barracks_"..t)
						for _, rax in pairs(raxes) do
							rax:RemoveModifierByName("modifier_invulnerable")
						end
					end
				end

				if str == "-closeway_all" or str == "-cw_all" then
					Notifications:TopToAll({text="Red Player closed all lanes (excluding 1, 2, 3, 4)!", style={color="white"}, duration=5.0})
					for t = 5, 8 do
						CREEP_LANES[t] = 0
						local DoorObs = Entities:FindAllByName("obstruction_lane"..t)
						for _, obs in pairs(DoorObs) do 
							obs:SetEnabled(true, true)
						end
						DoEntFire("door_lane"..t, "SetAnimation", "gate_entrance002_idle", 0, nil, nil)
						local towers = Entities:FindAllByName("dota_badguys_tower"..t)
						for _, tower in pairs(towers) do
							tower:AddNewModifier(nil, nil, "modifier_invulnerable", nil)
						end
						local raxes = Entities:FindAllByName("dota_badguys_barracks_"..t)
						for _, rax in pairs(raxes) do
							rax:AddNewModifier(nil, nil, "modifier_invulnerable", nil)
						end
					end
				end
			end
		end

		if str == "-credits" then
			Notifications:Top(player, {text="Mod created by [BEAR] Cookies #42, thanks to Noya for WC3 database ported to dota!", style={color="white"}, duration=5.0})
		end

		if str == "-difficulty" then
			local diff = {"Easy", "Normal", "Hard", "Extreme"}
			Notifications:Top(player, {text="DIFFICULTY: "..diff[GameRules:GetCustomGameDifficulty()], duration=10.0})
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
