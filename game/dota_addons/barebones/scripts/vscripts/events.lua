require('label')

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
--	local normal_health = npc:GetMaxHealth()
	local normal_xp = npc:GetDeathXP()
	local normal_min_damage = npc:GetBaseDamageMin()
	local normal_max_damage = npc:GetBaseDamageMax()

	if difficulty == 1 and npc:GetTeam() == DOTA_TEAM_BADGUYS then
		npc:SetMinimumGoldBounty( normal_bounty*1.5 )
		npc:SetMaximumGoldBounty( normal_bounty*1.5 )
		npc:SetDeathXP( normal_xp )
		npc:SetBaseDamageMin( normal_min_damage*0.75 )
		npc:SetBaseDamageMax( normal_max_damage*0.75 )
--		npc:SetMaxHealth( normal_health )
	elseif difficulty == 2 and npc:GetTeam() == DOTA_TEAM_BADGUYS then
		npc:SetMinimumGoldBounty( normal_bounty )
		npc:SetMaximumGoldBounty( normal_bounty )
		npc:SetDeathXP( normal_xp )
		npc:SetBaseDamageMin( normal_min_damage )
		npc:SetBaseDamageMax( normal_max_damage )
--		npc:SetMaxHealth( normal_health*1.1 )
	elseif difficulty == 3 and npc:GetTeam() == DOTA_TEAM_BADGUYS then
		npc:SetMinimumGoldBounty( normal_bounty*0.8 )
		npc:SetMaximumGoldBounty( normal_bounty*0.8 )
		npc:SetDeathXP( normal_xp*0.9 )
		npc:SetBaseDamageMin( normal_min_damage*1.2 )
		npc:SetBaseDamageMax( normal_max_damage*1.2 )
--		npc:SetMaxHealth( normal_health/1.5 )
	elseif difficulty == 4 and npc:GetTeam() == DOTA_TEAM_BADGUYS then
		npc:SetMinimumGoldBounty( normal_bounty*0.6 )
		npc:SetMaximumGoldBounty( normal_bounty*0.6 )
		npc:SetDeathXP( normal_xp*0.7 )
		npc:SetBaseDamageMin( normal_min_damage*1.5 )
		npc:SetBaseDamageMax( normal_max_damage*1.5 )
--		npc:SetMaxHealth( normal_health/1.5 )
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

-- A player has reconnected to the game.  This function can be used to repaint Player-based particles or change
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

	if hero_level > 18 then
		hero:SetAbilityPoints( hero:GetAbilityPoints() - 1 )
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
	GameMode:setPlayerHealthLabel(player)
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

end

-- This function is called 1 to 2 times as the player connects initially but before they 
-- have completely connected
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
	DebugPrint('[BAREBONES] OnNPCGoalReached')
	DebugPrintTable(keys)

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
end

--function GameMode:DestroyDoor( keys )
--	local door = Entities:FindByName(nil, "door_west_1")
--	for _,hero in pairs(HeroList:GetAllHeroes()) do
--		if IsValidEntity(hero:GetPlayerOwner()) then
--		PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),door)
--			Timers:CreateTimer(1,function ()
--				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil)
--			end)
--		end
--	end
--		if IsValidEntity(door) then
--		AddFOWViewer(DOTA_TEAM_GOODGUYS, door:GetAbsOrigin(), 500, 5, true)
--		end
--	DoEntFire(keys.door_name,"SetAnimation","gate_entrance002_open",0,nil,nil)
--
--	local gridobs = Entities:FindAllByName(keys.obstruction_name)
--
--	for _,obs in pairs(gridobs) do
--		obs:SetEnabled(false, true)
--	end
--end
