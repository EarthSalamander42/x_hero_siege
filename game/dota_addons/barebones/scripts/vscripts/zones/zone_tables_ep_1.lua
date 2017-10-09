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
				Type = ZONE_STAR_CRITERIA_TIME,
				Values =
				{
					3000, -- 50 Minutes
					2400, -- 40 Minutes
					1800, -- 30 Minutes
				},
			},
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
					szNPCName ="dota_badguys_barracks",
				},
				bOptional = true,
				nCompleteLimit = 1,
			},
			{
				szQuestName = "kill_ice_towers",
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
					szNPCName ="npc_tower_cold",
				},
				nCompleteLimit = ICE_TOWERS_REQUIRED,
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
					szTeamName = DOTA_TEAM_NEUTRALS,
				},
				nCompleteLimit = 52,
			},
			{
				szQuestName = "kill_mag",
				szQuestType = "Kill",
				Activators = 
				{
					{
						Type = QUEST_EVENT_ON_QUEST_COMPLETE,
						szQuestName = "defend_castle",
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
	},
}
