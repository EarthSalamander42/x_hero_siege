-- This function initializes the game mode and is called before anyone loads into the game
-- It can be used to pre-initialize any values/tables that will be needed later
function GameMode:_InitGameMode()

	GameRules:SetHeroRespawnEnabled( true )
	GameRules:SetUseUniversalShopMode( true )
	GameRules:SetSameHeroSelectionEnabled( false )
	GameRules:SetHeroSelectionTime( 30 )
	GameRules:SetPreGameTime( 30 )
	GameRules:SetPostGameTime( 60 )
	GameRules:SetTreeRegrowTime( 60 )
	GameRules:SetUseCustomHeroXPValues ( true )
	GameRules:SetGoldPerTick( 0 )
	GameRules:SetGoldTickTime( 0 )
	GameRules:SetRuneSpawnTime( 120 )
	GameRules:SetUseBaseGoldBountyOnHeroes( true )
	GameRules:SetHeroMinimapIconScale( 1 )
	GameRules:SetCreepMinimapIconScale( 1 )
	GameRules:SetRuneMinimapIconScale( 1 )

	GameRules:SetFirstBloodActive( false )
	GameRules:SetHideKillMessageHeaders( true )

	CUSTOM_TEAM_PLAYER_COUNT = {}
	CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_GOODGUYS] = 8
	CUSTOM_TEAM_PLAYER_COUNT[DOTA_TEAM_BADGUYS]  = 0

	local count = 0
	for team,number in pairs(CUSTOM_TEAM_PLAYER_COUNT) do
		if count >= MAX_NUMBER_OF_TEAMS then
		GameRules:SetCustomGameTeamMaxPlayers(team, 0)
		else
		GameRules:SetCustomGameTeamMaxPlayers(team, number)
		end
		count = count + 1
	end
end

	TEAM_COLORS = {}
	TEAM_COLORS[DOTA_TEAM_GOODGUYS] = { 61, 210, 150 }  --    Teal
	TEAM_COLORS[DOTA_TEAM_BADGUYS]  = { 243, 201, 9 }   --    Yellow

	if USE_CUSTOM_TEAM_COLORS then
		for team,color in pairs(TEAM_COLORS) do
		SetTeamCustomHealthbarColor(team, color[1], color[2], color[3])
		end
	end
  DebugPrint('[BAREBONES] GameRules set')

  -- Event Hooks
  -- All of these events can potentially be fired by the game, though only the uncommented ones have had
  -- Functions supplied for them.  If you are interested in the other events, you can uncomment the
  -- ListenToGameEvent line and add a function to handle the event
  ListenToGameEvent('dota_player_gained_level', Dynamic_Wrap(GameMode, 'OnPlayerLevelUp'), self)
  ListenToGameEvent('dota_ability_channel_finished', Dynamic_Wrap(GameMode, 'OnAbilityChannelFinished'), self)
  ListenToGameEvent('dota_player_learned_ability', Dynamic_Wrap(GameMode, 'OnPlayerLearnedAbility'), self)
  ListenToGameEvent('entity_killed', Dynamic_Wrap(GameMode, 'OnEntityKilled'), self)
  ListenToGameEvent('player_connect_full', Dynamic_Wrap(GameMode, 'OnConnectFull'), self)
  ListenToGameEvent('player_disconnect', Dynamic_Wrap(GameMode, 'OnDisconnect'), self)
  ListenToGameEvent('dota_item_purchased', Dynamic_Wrap(GameMode, 'OnItemPurchased'), self)
  ListenToGameEvent('dota_item_picked_up', Dynamic_Wrap(GameMode, 'OnItemPickedUp'), self)
  ListenToGameEvent('last_hit', Dynamic_Wrap(GameMode, 'OnLastHit'), self)
  ListenToGameEvent('dota_non_player_used_ability', Dynamic_Wrap(GameMode, 'OnNonPlayerUsedAbility'), self)
  ListenToGameEvent('player_changename', Dynamic_Wrap(GameMode, 'OnPlayerChangedName'), self)
  ListenToGameEvent('dota_rune_activated_server', Dynamic_Wrap(GameMode, 'OnRuneActivated'), self)
  ListenToGameEvent('dota_player_take_tower_damage', Dynamic_Wrap(GameMode, 'OnPlayerTakeTowerDamage'), self)
  ListenToGameEvent('tree_cut', Dynamic_Wrap(GameMode, 'OnTreeCut'), self)
  ListenToGameEvent('entity_hurt', Dynamic_Wrap(GameMode, 'OnEntityHurt'), self)
  ListenToGameEvent('player_connect', Dynamic_Wrap(GameMode, 'PlayerConnect'), self)
  ListenToGameEvent('dota_player_used_ability', Dynamic_Wrap(GameMode, 'OnAbilityUsed'), self)
  ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(GameMode, 'OnGameRulesStateChange'), self)
  ListenToGameEvent('npc_spawned', Dynamic_Wrap(GameMode, 'OnNPCSpawned'), self)
  ListenToGameEvent('dota_player_pick_hero', Dynamic_Wrap(GameMode, 'OnPlayerPickHero'), self)
  ListenToGameEvent('dota_team_kill_credit', Dynamic_Wrap(GameMode, 'OnTeamKillCredit'), self)
  ListenToGameEvent("player_reconnected", Dynamic_Wrap(GameMode, 'OnPlayerReconnect'), self)

  ListenToGameEvent("dota_illusions_created", Dynamic_Wrap(GameMode, 'OnIllusionsCreated'), self)
  ListenToGameEvent("dota_item_combined", Dynamic_Wrap(GameMode, 'OnItemCombined'), self)
  ListenToGameEvent("dota_player_begin_cast", Dynamic_Wrap(GameMode, 'OnAbilityCastBegins'), self)
  ListenToGameEvent("dota_tower_kill", Dynamic_Wrap(GameMode, 'OnTowerKill'), self)
  ListenToGameEvent("dota_player_selected_custom_team", Dynamic_Wrap(GameMode, 'OnPlayerSelectedCustomTeam'), self)
  ListenToGameEvent("dota_npc_goal_reached", Dynamic_Wrap(GameMode, 'OnNPCGoalReached'), self)

  ListenToGameEvent("player_chat", Dynamic_Wrap(GameMode, 'OnPlayerChat'), self)
  
  --ListenToGameEvent("dota_tutorial_shop_toggled", Dynamic_Wrap(GameMode, 'OnShopToggled'), self)

  --ListenToGameEvent('player_spawn', Dynamic_Wrap(GameMode, 'OnPlayerSpawn'), self)
  --ListenToGameEvent('dota_unit_event', Dynamic_Wrap(GameMode, 'OnDotaUnitEvent'), self)
  --ListenToGameEvent('nommed_tree', Dynamic_Wrap(GameMode, 'OnPlayerAteTree'), self)
  --ListenToGameEvent('player_completed_game', Dynamic_Wrap(GameMode, 'OnPlayerCompletedGame'), self)
  --ListenToGameEvent('dota_match_done', Dynamic_Wrap(GameMode, 'OnDotaMatchDone'), self)
  --ListenToGameEvent('dota_combatlog', Dynamic_Wrap(GameMode, 'OnCombatLogEvent'), self)
  --ListenToGameEvent('dota_player_killed', Dynamic_Wrap(GameMode, 'OnPlayerKilled'), self)
  --ListenToGameEvent('player_team', Dynamic_Wrap(GameMode, 'OnPlayerTeam'), self)

  --[[This block is only used for testing events handling in the event that Valve adds more in the future
  Convars:RegisterCommand('events_test', function()
	  GameMode:StartEventTest()
	end, "events test", 0)]]

  local spew = 0
  if BAREBONES_DEBUG_SPEW then
	spew = 1
  end
  Convars:RegisterConvar('barebones_spew', tostring(spew), 'Set to 1 to start spewing barebones debug info.  Set to 0 to disable.', 0)

  -- Change random seed
  local timeTxt = string.gsub(string.gsub(GetSystemTime(), ':', ''), '0','')
  math.randomseed(tonumber(timeTxt))

  -- Initialized tables for tracking state
  self.bSeenWaitForPlayers = false
  self.vUserIds = {}

  DebugPrint('[BAREBONES] Done loading Barebones gamemode!\n\n')

mode = nil

XP_PER_LEVEL_TABLE = {}

XP_PER_LEVEL_TABLE[1] = 0 -- 1
XP_PER_LEVEL_TABLE[2] = 200 -- 2
XP_PER_LEVEL_TABLE[3] = 400 -- 3
XP_PER_LEVEL_TABLE[4] = 700 -- 4
XP_PER_LEVEL_TABLE[5] = 1100 -- 5
XP_PER_LEVEL_TABLE[6] = 1600 -- 6
XP_PER_LEVEL_TABLE[7] = 2200 -- 7
XP_PER_LEVEL_TABLE[8] = 2900 -- 8
XP_PER_LEVEL_TABLE[9] = 3700 -- 9
XP_PER_LEVEL_TABLE[10] = 4600 -- 10
XP_PER_LEVEL_TABLE[11] = 5600 -- 11
XP_PER_LEVEL_TABLE[12] = 6700 -- 12
XP_PER_LEVEL_TABLE[13] = 7900 -- 13
XP_PER_LEVEL_TABLE[14] = 9200 -- 14
XP_PER_LEVEL_TABLE[15] = 10600 -- 15
XP_PER_LEVEL_TABLE[16] = 12100 -- 16
XP_PER_LEVEL_TABLE[17] = 13700 -- 17
XP_PER_LEVEL_TABLE[18] = 15400 -- 18
XP_PER_LEVEL_TABLE[19] = 17200 -- 19
XP_PER_LEVEL_TABLE[20] = 19100 -- 20
XP_PER_LEVEL_TABLE[21] = 21100 -- 21
XP_PER_LEVEL_TABLE[22] = 23200 -- 22
XP_PER_LEVEL_TABLE[23] = 25400 -- 23
XP_PER_LEVEL_TABLE[24] = 27700 -- 24
XP_PER_LEVEL_TABLE[25] = 30100 -- 25
XP_PER_LEVEL_TABLE[26] = 32600 -- 26
XP_PER_LEVEL_TABLE[27] = 35200 -- 27
XP_PER_LEVEL_TABLE[28] = 37900 -- 28
XP_PER_LEVEL_TABLE[29] = 40700 -- 29
XP_PER_LEVEL_TABLE[30] = 43600 -- 30
XP_PER_LEVEL_TABLE[31] = 46600 -- 31
XP_PER_LEVEL_TABLE[32] = 49700 -- 32
XP_PER_LEVEL_TABLE[33] = 52900 -- 33
XP_PER_LEVEL_TABLE[34] = 56200 -- 34
XP_PER_LEVEL_TABLE[35] = 59600 -- 35
XP_PER_LEVEL_TABLE[36] = 63100 -- 36
XP_PER_LEVEL_TABLE[37] = 66700 -- 37
XP_PER_LEVEL_TABLE[38] = 70400 -- 38
XP_PER_LEVEL_TABLE[39] = 74200 -- 39
XP_PER_LEVEL_TABLE[41] = 78100 -- 40
XP_PER_LEVEL_TABLE[41] = 82100 -- 41
XP_PER_LEVEL_TABLE[42] = 86200 -- 42
XP_PER_LEVEL_TABLE[43] = 90400 -- 43
XP_PER_LEVEL_TABLE[44] = 94700 -- 44
XP_PER_LEVEL_TABLE[45] = 99100 -- 45
XP_PER_LEVEL_TABLE[46] = 103600 -- 46
XP_PER_LEVEL_TABLE[47] = 108200 -- 47
XP_PER_LEVEL_TABLE[48] = 112900 -- 48
XP_PER_LEVEL_TABLE[49] = 117700 -- 49
XP_PER_LEVEL_TABLE[50] = 122600 -- 50

-- This function is called as the first player loads and sets up the GameMode parameters
function GameMode:_CaptureGameMode()
  if mode == nil then
	-- Set GameMode parameters
	mode = GameRules:GetGameModeEntity()        
	mode:SetRecommendedItemsDisabled( false )
	mode:SetCameraDistanceOverride( 1134 )
	mode:SetCustomBuybackCostEnabled( false )
	mode:SetCustomBuybackCooldownEnabled( false )
	mode:SetBuybackEnabled( false )
	mode:SetTopBarTeamValuesOverride ( false )
	mode:SetTopBarTeamValuesVisible( false )

	mode:SetUseCustomHeroLevels ( true )
	mode:SetCustomHeroMaxLevel ( 50 )
	mode:SetCustomXPRequiredToReachNextLevel( XP_PER_LEVEL_TABLE )

	mode:SetBotThinkingEnabled( false )
	mode:SetTowerBackdoorProtectionEnabled( false )

	mode:SetFogOfWarDisabled( false )
	mode:SetGoldSoundDisabled( false )
	mode:SetRemoveIllusionsOnDeath( false )

	mode:SetAlwaysShowPlayerInventory( false )
	mode:SetAnnouncerDisabled( false )
	if FORCE_PICKED_HERO ~= nil then
	  mode:SetCustomGameForceHero( false )
	end
	mode:SetFixedRespawnTime( 120 ) 
	mode:SetLoseGoldOnDeath( false )
	mode:SetMaximumAttackSpeed( 20 )
	mode:SetMinimumAttackSpeed( 600 )
	mode:SetStashPurchasingDisabled ( false )

	for rune, spawn in pairs(ENABLED_RUNES) do
	  mode:SetRuneEnabled(rune, spawn)
	end

	mode:SetUnseenFogOfWarEnabled( false )

	self:OnFirstPlayerLoaded()
  end 
end
