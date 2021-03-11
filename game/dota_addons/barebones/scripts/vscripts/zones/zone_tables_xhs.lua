_G.ZonesDefinition =
{
	--------------------------------------------------
	-- X Hero Siege
	--------------------------------------------------
	{
		szName = "xhs_holdout",
		nZoneID = 1,
		Type = ZONE_TYPE_EXPLORE,
--		szTeleportEntityName = "forest_holdout_zone_darkforest_death_maze",
--		bNoLeaderboard = true,
		StarCriteria =
		{
			{
				Type = ZONE_STAR_CRITERIA_DEATHS,
				Values =
				{
					7,
					4,
					0,
				},
			},
		},
		Quests = 
		{
			{
				szQuestName = "defend_castle",
				szQuestType = "Explore",
				Activators = 
				{
					{
						Type = QUEST_EVENT_ON_ZONE_ACTIVATE,
						szZoneName = "xhs_holdout",
					},
				},
				Completion = 
				{
					Type = QUEST_EVENT_ON_QUEST_COMPLETE,
					szQuestName = "kill_final_wave",
				},
			},
			{
				szQuestName = "kill_rax",
				szQuestType = "Kill",
				Activators = 
				{
					{
						Type = QUEST_EVENT_ON_ZONE_ACTIVATE,
						szZoneName = "xhs_holdout",
					},			
				},
				Completion = 
				{	
					Type = QUEST_EVENT_ON_ENEMY_KILLED,
					szNPCName ="dummy_unit_phase_2_invulnerable",
				},
				nCompleteLimit = 1,
			},
			{
				szQuestName = "kill_dest_mag",
				szQuestType = "Kill",
				Activators = 
				{
					{
						Type = QUEST_EVENT_ON_QUEST_COMPLETE,
						szQuestName = "kill_rax",
					},			
				},
				Completion = 
				{	
					Type = QUEST_EVENT_ON_ENEMY_KILLED,
					szNPCName ="npc_magnataur_destroyer_crypt",
				},
--				nCompleteLimit = MAGNATAURS_TO_KILL * PlayerResource:GetPlayerCount() * CREEP_LANES_TYPE,
				nCompleteLimit = 1,
			},
			{
				szQuestName = "kill_ice_towers",
				szQuestType = "Kill",
				Activators = 
				{
					{
						Type = QUEST_EVENT_ON_QUEST_COMPLETE,
						szQuestName = "kill_dest_mag",
					},			
				},
				Completion = 
				{	
					Type = QUEST_EVENT_ON_ENEMY_KILLED,
					szNPCName ="npc_tower_cold",
				},
				nCompleteLimit = 1,
			},
			{
				szQuestName = "kill_final_wave",
				szQuestType = "Kill",
				Activators = 
				{
					{
						Type = QUEST_EVENT_ON_QUEST_COMPLETE,
						szQuestName = "kill_ice_towers",
					},			
				},
				Completion = 
				{	
					Type = QUEST_EVENT_ON_TEAM_ENEMY_KILLED,
					szTeamName = DOTA_TEAM_CUSTOM_1,
				},
				nCompleteLimit = 52,
			},
			{
				szQuestName = "teleport_top",
				szQuestType = "Speak",
				Activators = 
				{
					{
						Type = QUEST_EVENT_ON_QUEST_COMPLETE,
						szQuestName = "kill_final_wave",
					},			
				},
				Completion =
				{	
					Type = QUEST_EVENT_ON_DIALOG_ALL_CONFIRMED,
					szNPCName = "npc_xhs_paladin",
					nDialogLine = 1,
				},
			},
			{
				szQuestName = "kill_mag",
				szQuestType = "Kill",
				Activators = 
				{
					{
						Type = QUEST_EVENT_ON_QUEST_COMPLETE,
						szQuestName = "teleport_top",
					},			
				},
				Completion = 
				{	
					Type = QUEST_EVENT_ON_ENEMY_KILLED,
					szNPCName ="npc_dota_hero_magtheridon",
				},
				nCompleteLimit = GameRules:GetCustomGameDifficulty(),
			},
			{
				szQuestName = "kill_grom",
				szQuestType = "Kill",
				Activators = 
				{
					{
						Type = QUEST_EVENT_ON_QUEST_COMPLETE,
						szQuestName = "kill_mag",
					},			
				},
				Completion = 
				{	
					Type = QUEST_EVENT_ON_ENEMY_KILLED,
					szNPCName ="npc_dota_hero_grom_hellscream",
				},
				nCompleteLimit = 1,
			},
			{
				szQuestName = "kill_illidan",
				szQuestType = "Kill",
				Activators = 
				{
					{
						Type = QUEST_EVENT_ON_QUEST_COMPLETE,
						szQuestName = "kill_grom",
					},			
				},
				Completion = 
				{	
					Type = QUEST_EVENT_ON_ENEMY_KILLED,
					szNPCName ="npc_dota_hero_illidan",
				},
				nCompleteLimit = 1,
			},
			{
				szQuestName = "kill_balanar",
				szQuestType = "Kill",
				Activators = 
				{
					{
						Type = QUEST_EVENT_ON_QUEST_COMPLETE,
						szQuestName = "kill_illidan",
					},			
				},
				Completion = 
				{	
					Type = QUEST_EVENT_ON_ENEMY_KILLED,
					szNPCName ="npc_dota_hero_balanar",
				},
				nCompleteLimit = 1,
			},
			{
				szQuestName = "kill_proudmoore",
				szQuestType = "Kill",
				Activators = 
				{
					{
						Type = QUEST_EVENT_ON_QUEST_COMPLETE,
						szQuestName = "kill_balanar",
					},			
				},
				Completion = 
				{	
					Type = QUEST_EVENT_ON_ENEMY_KILLED,
					szNPCName ="npc_dota_hero_proudmoore",
				},
				nCompleteLimit = 1,
			},
			{
				szQuestName = "teleport_arthas",
				szQuestType = "Speak",
				Activators = 
				{
					{
						Type = QUEST_EVENT_ON_QUEST_COMPLETE,
						szQuestName = "kill_proudmoore",
					},			
				},
				Completion =
				{	
					Type = QUEST_EVENT_ON_DIALOG_ALL_CONFIRMED,
					szNPCName = "npc_xhs_paladin_2",
					nDialogLine = 1,
				},
			},
			{
				szQuestName = "kill_arthas",
				szQuestType = "Kill",
				Activators = 
				{
					{
						Type = QUEST_EVENT_ON_QUEST_COMPLETE,
						szQuestName = "kill_proudmoore",
					},			
				},
				Completion = 
				{	
					Type = QUEST_EVENT_ON_ENEMY_KILLED,
					szNPCName ="npc_dota_hero_arthas",
				},
				nCompleteLimit = 1,
			},
			{
				szQuestName = "kill_banehallow",
				szQuestType = "Kill",
				Activators = 
				{
					{
						Type = QUEST_EVENT_ON_QUEST_COMPLETE,
						szQuestName = "kill_arthas",
					},			
				},
				Completion = 
				{	
					Type = QUEST_EVENT_ON_ENEMY_KILLED,
					szNPCName ="npc_dota_hero_banehallow",
				},
				nCompleteLimit = 1,
			},
			{
				szQuestName = "kill_lich_king",
				szQuestType = "Kill",
				Activators = 
				{
					{
						Type = QUEST_EVENT_ON_QUEST_COMPLETE,
						szQuestName = "kill_banehallow",
					},			
				},
				Completion = 
				{	
					Type = QUEST_EVENT_ON_ENEMY_KILLED,
					szNPCName ="npc_dota_boss_lich_king",
				},
				nCompleteLimit = 1,
			},
			{
				szQuestName = "kill_spirit_master",
				szQuestType = "Kill",
				Activators = 
				{
					{
						Type = QUEST_EVENT_ON_QUEST_COMPLETE,
						szQuestName = "kill_lich_king",
					},			
				},
				Completion = 
				{	
					Type = QUEST_EVENT_ON_TEAM_ENEMY_KILLED,
					szTeamName = DOTA_TEAM_CUSTOM_1,
				},
				nCompleteLimit = 4,
				nCompleteLimit = 1,
			},
		},
		VIPs =
		{
			{
				szVIPName = "npc_xhs_paladin",
				szSpawnerName = "xhs_spawner_paladin_vip",
				nCount = 1,
				Activity = ACT_DOTA_IDLE,
			},
			{
				szVIPName = "npc_xhs_paladin_2",
				szSpawnerName = "xhs_spawner_paladin_2_vip",
				nCount = 1,
				Activity = ACT_DOTA_IDLE,
			},
		},
		AlliedStructures =
		{
			{
				fSpawnChance = 1.0,
				szSpawnerName = "xhs_campfire",
				szNPCName = "npc_dota_campfire",
				nMaxSpawnDistance = 0,
			},
		},
--		Chests =
--		{
--			--TreasureChest_A
--			{
--				fSpawnChance = 0.5,
--				szSpawnerName = "xhs_treasure_chest",
--				szNPCName = "npc_treasure_chest",
--				nMaxSpawnDistance = 0,
--				szTraps =
--				{
--					"creature_techies_land_mine",
--					"trap_sun_strike",
--				},
--				nTrapLevel = 1,
--				nMinGold = 250,
--				nMaxGold = 450,
--				Items =
--				{
--					"item_orb_of_lightning",
--					"item_orb_of_fire",
--					"item_orb_of_earth",
--					"item_orb_of_darkness",
--				},
--				Relics =
--				{
--					"item_orb_of_frost",
--				},
--				fRelicChance = 0.001,
--			},
--		},
		Breakables =
		{
			-- Crate
			{
				fSpawnChance = 1.0,
				szSpawnerName = "xhs_crate",
				szNPCName = "npc_dota_crate",
				nMaxSpawnDistance = 0,
				nMinGold = 100,
				nMaxGold = 200,
				fGoldChance = 0.11,
				CommonItems =
				{
					"item_health_potion",
					"item_health_potion",
					"item_mana_potion",
					"item_mana_potion",
					"item_potion_full",
					"item_potion_of_invulnerability",
					"item_potion_of_antimagic",
					"item_xhs_cloak_of_flames",
					"item_amulet_of_the_wild",
					"item_talisman_of_evasion_datadriven",
				},
				fCommonItemChance = 0.15,
				RareItems =
				{
					"item_tome_small",
					"item_tome_big",
					"item_tome_of_power",
				},
				fRareItemChance = 0.001,
			},
		},
	},
}
