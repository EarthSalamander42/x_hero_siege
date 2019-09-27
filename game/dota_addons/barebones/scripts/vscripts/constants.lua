CUSTOM_GAME_TYPE = "XHS"

_G.GAME_VERSION = "3.49b"
CustomNetTables:SetTableValue("game_options", "game_count", {value = 1})

-- General
_G.nBASE_GOLD_BAG_DROP_RATE = 30
_G.nCHECKPOINT_REVIVES = 1
_G.nREVIVE_COST = 1
_G.nBUYBACK_COST = 1
_G.nREVIVE_HP_PCT = 25
_G.INIT_CHOOSE_HERO = false

-- Creature
_G.nROAMER_MAX_DIST_FROM_SPAWN = 2048
_G.nBOSS_MAX_DIST_FROM_SPAWN = 0

_G.nSQUADMEMBER_MAX_SPAWN_DIST = 250
_G.nSQUADMEMBER_MAX_WANDER_DIST = 300

_G.nCREATURE_RESPAWN_TIME = 60

_G.ZONE_TYPE_EXPLORE = 	0
_G.ZONE_TYPE_SURVIVAL = 1
_G.ZONE_TYPE_HOLDOUT = 	2
_G.ZONE_TYPE_ASSAULT = 	3

_G.QUEST_EVENT_ON_ZONE_ACTIVATE 			= 0
_G.QUEST_EVENT_ON_DIALOG 					= 1
_G.QUEST_EVENT_ON_ZONE_EVENT_FINISHED 		= 2
_G.QUEST_EVENT_ON_QUEST_ACTIVATE 			= 3
_G.QUEST_EVENT_ON_QUEST_COMPLETE 			= 4
_G.QUEST_EVENT_ON_ENEMY_KILLED 				= 5
_G.QUEST_EVENT_ON_KEY_ITEM_RECEIVED			= 6
_G.QUEST_EVENT_ON_DIALOG_ALL_CONFIRMED   	= 7
_G.QUEST_EVENT_ON_TREASURE_OPENED			= 8
_G.QUEST_EVENT_ON_TEAM_ENEMY_KILLED			= 9

_G.ZONE_STAT_KILLS 			= 0
_G.ZONE_STAT_DEATHS			= 1
_G.ZONE_STAT_ITEMS			= 2
_G.ZONE_STAT_GOLD_BAGS		= 3
_G.ZONE_STAT_POTIONS		= 4
_G.ZONE_STAT_REVIVE_TIME	= 5
_G.ZONE_STAT_DAMAGE 		= 6
_G.ZONE_STAT_HEALING		= 7

_G.ZONE_STAR_CRITERIA_TIME 				= 0
_G.ZONE_STAR_CRITERIA_DEATHS 			= 1
_G.ZONE_STAR_CRITERIA_KILLS				= 2
_G.ZONE_STAR_CRITERIA_QUEST_COMPLETE	= 3

-- X Hero Siege
_G.PREGAMETIME = 90.0
_G.nTimer_GameTime = 0
_G.nTimer_SpecialEvent = 0
_G.nTimer_IncomingWave = 0
_G.nTimer_CreepLevel = 0
_G.nTimer_SpecialArena = 0
_G.nTimer_HeroImage = 0
_G.nTimer_SpiritBeast = 0
_G.nTimer_FrostInfernal = 0
_G.nTimer_AllHeroImage = 0
_G.time_elapsed = 0
_G.RAMERO = 0
_G.MAGTHERIDON = 0
_G.FOUR_BOSSES = 0
_G.SPIRIT_MASTER = 0
_G.SPECIAL_EVENT = 0
_G.PlayerNumberRadiant = 0
_G.PlayerNumberDire = 0
_G.sword_first_time = true
_G.ring_first_time = true
_G.doom_first_time = false
_G.frost_first_time = false
_G.SECRET = 0
_G.PHASE = 1
_G.RESPAWN_TIME = 40.0
_G.CREEP_LANES_TYPE = 1
if GetMapName() == "x_hero_siege_4" then
	_G.CREEP_LANES_TYPE = 2
end
_G.BT_ENABLED = 1
_G.MURADIN_DEFEND = false
_G.STORM_SPIRIT = 0
_G.ALL_HERO_IMAGE_DEAD = 0

_G.FrostInfernal_killed = 0
_G.FrostInfernal_occuring = 0
_G.SpiritBeast_killed = 0
_G.SpiritBeast_occuring = 0
_G.HeroImage_occuring = 0
_G.AllHeroImages_occuring = 0
_G.AllHeroImagesDead = 0
_G.FrostTowers_killed = 0
_G.BossesTop_killed = 0

GameMode.FrostInfernal_killed = 0
GameMode.FrostInfernal_occuring = 0
GameMode.SpiritBeast_killed = 0
GameMode.SpiritBeast_occuring = 0
GameMode.SpecialArena_occuring = 0
GameMode.HeroImage_occuring = 0
GameMode.AllHeroImages_occuring = 0
GameMode.AllHeroImagesDead = 0
GameMode.FrostTowers_killed = 0
GameMode.BossesTop_killed = 0
GameMode.creep_roll = {}
GameMode.creep_roll["race"] = 0

CREEP_LANES = {} -- Stores individual creep lanes {enable/disable, creep level, rax alive}
CREEP_LANES[1] = {0, 1, 1}
CREEP_LANES[2] = {0, 1, 1}
CREEP_LANES[3] = {0, 1, 1}
CREEP_LANES[4] = {0, 1, 1}
CREEP_LANES[5] = {0, 1, 1}
CREEP_LANES[6] = {0, 1, 1}
CREEP_LANES[7] = {0, 1, 1}
CREEP_LANES[8] = {0, 1, 1}

PLAYER_COLORS = {}					-- Stores individual player colors
PLAYER_COLORS[0] = {200, 0, 0}		--Red
PLAYER_COLORS[1] = {0, 50, 200}		--Blue
PLAYER_COLORS[2] = {0, 255, 255}	--Cyan
PLAYER_COLORS[3] = {100, 0, 100}	--Purple
PLAYER_COLORS[4] = {255, 255, 0}	--Yellow
PLAYER_COLORS[5] = {255, 150, 0}	--Orange
PLAYER_COLORS[6] = {0, 125, 0}		--Green (Dark)
PLAYER_COLORS[7] = {255, 100, 255}	--Pink

HEROLIST = {}
HEROLIST[1] = "enchantress"			-- Dryad
HEROLIST[2] = "crystal_maiden"		-- Archmage
HEROLIST[3] = "luna"				-- Huntress
HEROLIST[4] = "lone_druid"			-- Beastmaster
HEROLIST[5] = "pugna"				-- Dread Lord
HEROLIST[6] = "lich"				-- Lich
HEROLIST[7] = "nyx_assassin"		-- Crypt Lord
HEROLIST[8] = "abyssal_underlord"	-- Pit Lord
HEROLIST[9] = "terrorblade"			-- Demon Hunter
HEROLIST[10] = "phantom_assassin"	-- Warden
HEROLIST[11] = "elder_titan"		-- Tauren Chieftain
HEROLIST[12] = "mirana"				-- Priestess of the Moon
HEROLIST[13] = "dragon_knight"		-- Arthas
HEROLIST[14] = "windrunner"			-- Sylvanas Windrunner
HEROLIST[15] = "invoker"			-- Blood Mage
HEROLIST[16] = "sniper"				-- Rifleman
HEROLIST[17] = "shadow_shaman"		-- Shadow Hunter
HEROLIST[18] = "juggernaut"			-- Blademaster
HEROLIST[19] = "omniknight"			-- Paladin
HEROLIST[20] = "rattletrap"			-- Space Marine
HEROLIST[21] = "chen"				-- Archimage
HEROLIST[22] = "lina"				-- Sorceress
HEROLIST[23] = "sven"				-- Mountain King
HEROLIST[24] = "ursa"				-- Malfurion
HEROLIST[25] = "nevermore"			-- Banehallow
HEROLIST[26] = "brewmaster"			-- Pandaren Brewmaster
HEROLIST[27] = "warlock"			-- Archimonde
HEROLIST[28] = "razor"				-- Ghost Revenant
-- DOTA 2
HEROLIST[29] = "axe"
HEROLIST[30] = "monkey_king"
HEROLIST[31] = "medusa"
HEROLIST[32] = "doom_bringer"
HEROLIST[33] = "bristleback"
HEROLIST[34] = "leshrac"
HEROLIST[35] = "naga_siren"
HEROLIST[36] = "magnataur"

HEROLIST_VIP = {}
HEROLIST_VIP[1] = "slardar"			-- Centurion
HEROLIST_VIP[2] = "skeleton_king"	-- Lich King
HEROLIST_VIP[3] = "meepo"			-- Kobold Knight
HEROLIST_VIP[4] = "chaos_knight"	-- Dark Fundamental
HEROLIST_VIP[5] = "tiny"			-- Stone Giant
HEROLIST_VIP[6] = "sand_king"		-- Desert Wyrm
HEROLIST_VIP[7] = "necrolyte"		-- Dark Summoner
HEROLIST_VIP[8] = "storm_spirit"	-- Spirit Master

HEROLIST_RANKED = {}
HEROLIST_RANKED[1] = "terrorblade"		-- Demon Hunter
HEROLIST_RANKED[2] = "phantom_assassin"	-- Warden
HEROLIST_RANKED[3] = "lich"				-- Lich
HEROLIST_RANKED[4] = "brewmaster"		-- Brewmaster
HEROLIST_RANKED[5] = "sven"				-- Mountain King

timers = {}

GameMode.creep_roll = {}
GameMode.creep_roll["race"] = 0

_G.FarmEvent_Creeps = {
	"npc_dota_creature_murloc",
	"npc_dota_creature_wildkin",
	"npc_dota_creature_golem",
	"npc_dota_creature_polar_furbolg",
	"npc_dota_creature_centaur",
	"npc_dota_creature_razormane",
	"npc_dota_creature_revenant",
	"npc_dota_creature_tuskarr",
	"npc_dota_creature_satyrr"
}

FARM_EVENT_UPGRADE = {}
FARM_EVENT_UPGRADE["damage"] =	{10, 20, 30, 40, 50}
FARM_EVENT_UPGRADE["health"] =	{200, 400, 600, 800, 1000}
FARM_EVENT_UPGRADE["armor"] =	{0, 0, 0, 0, 0}

PHASE_2_UPGRADE = {}
PHASE_2_UPGRADE["damage"] =	{25, 50, 75, 100, 125}
PHASE_2_UPGRADE["health"] =	{200, 400, 600, 800, 1000}
PHASE_2_UPGRADE["armor"] =	{0, 0, 0, 0, 0}

_G.banned_players = {
	151018319, -- Mohammad Mehdi Akhondi
}

XP_PER_LEVEL_TABLE = {
	0,		-- 1
	200,	-- 2 +200
	500,	-- 3 +300
	900,	-- 4 +400
	1400,	-- 5 +500
	2000,	-- 6 +600
	2800,	-- 7 +700
	3800,	-- 8 +1000
	5000,	-- 9 +1200
	6400,	-- 10 +1400
	8200,	-- 11 +1800
	10400,	-- 12 +2200
	13000,	-- 13 +2600
	16000,	-- 14 + 3000
	19500,	-- 15 + 3500
	23500,	-- 16 + 4000
	28000,	-- 17 + 4500
	33000,	-- 18 + 5000
	38500,	-- 19 + 5500
	44500,	-- 20 + 6000
	50500,	-- 21 + 6000
	56500,	-- 22 + 6000
	62500,	-- 23 + 6000
	68500,	-- 24 + 6000
	74500,	-- 25 + 6000
	80500,	-- 26 + 6000
	86500,	-- 27 + 6000
	92500,	-- 28 + 6000
	100500,	-- 29 + 6000
	106500	-- 30 + 6000
}

AbilitiesHeroes_XX = {
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
	npc_dota_hero_nevermore = {{"holdout_rain_of_chaos_20", 2}},
	npc_dota_hero_nyx_assassin = {{"holdout_burrow_impale", 2}},
	npc_dota_hero_omniknight = {{"holdout_light_frenzy", 2}},
	npc_dota_hero_phantom_assassin = {{"holdout_morph", 2}},
	npc_dota_hero_pugna = {{"holdout_rain_of_chaos_20", 2}},
	npc_dota_hero_rattletrap = {{"holdout_cluster_rockets", 2}},
	npc_dota_hero_shadow_shaman = {{"holdout_hex", 2}},
	npc_dota_hero_skeleton_king = {{"holdout_lordaeron_smash", 3}},
	npc_dota_hero_slardar = {{"holdout_dark_dimension", 2}},
	npc_dota_hero_sniper ={{"holdout_laser", 0}, {"holdout_plasma_rifle_20", 1}},
	npc_dota_hero_sven = {{"holdout_storm_bolt_20", 0}, {"holdout_thunder_clap_20", 1}},
	npc_dota_hero_terrorblade = {{"holdout_resistant_skin", 6}},
	npc_dota_hero_tiny = {{"holdout_war_club_20", 0}},
	npc_dota_hero_windrunner = {{"holdout_rocket_hail", 2}}
}

_G.innate_abilities = {
	"wisp_passives",
	"serpent_splash_arrows",
	"neutral_spell_immunity",
	"holdout_innate_lunar_glaive",
	"holdout_innate_great_cleave",
	"holdout_blink",
	"holdout_poison_attack",
	"forest_troll_high_priest_heal",
	"holdout_mana_shield",
	"holdout_berserkers_rage",
	"holdout_berserkers_rage_alt",
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
	"holdout_lich_king_effects",
	"wisp_pick_random_hero",
	"holdout_spellsteal",
	"bristleback_warpath",
	"iron_man_misc",
	"holdout_spirit_int",
	"holdout_spirit_str",
	"holdout_spirit_agi",
	"holdout_yellow_effect",	--Desert Wyrm Ultimate effect
	"holdout_blue_effect",		--Lich King boss + hero effect
	"holdout_green_effect",		--Banehallow boss + hero effect
	"holdout_red_effect",		--Abaddon boss
	"ghost_revenant_ghost_immolation",
}

_G.difficulty_abilities = {
	"huskar_berserkers_blood",
	"weaver_geminate_attack",
	"dragon_knight_dragon_blood",
	"undead_disease_cloud",
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
	"ursa_fury_swipes",
	"arthas_frostmourne",
	"baristol_holy_light",
	"chaos_knight_chaos_strike",
}

-- Abilities cast only if more than 1 player
_G.multiplayer_abilities_cast = {
	"balanar_sleep",
	"lion_voodoo",
}

_G.XHS_LIFESTEAL_MODIFIER_PRIORITY = {}
_G.XHS_LIFESTEAL_MODIFIER_PRIORITY["modifier_lightning_sword_lifesteal"] = 1
_G.XHS_LIFESTEAL_MODIFIER_PRIORITY["modifier_lifesteal"] = 2
_G.XHS_LIFESTEAL_MODIFIER_PRIORITY["modifier_xhs_vampiric_aura"] = 3

MODIFIER_ITEMS_WITH_LEVELS = {}
MODIFIER_ITEMS_WITH_LEVELS["modifier_lifesteal"] = {
	"item_doom_artifact",
	"item_lightning_sword",
	"item_lifesteal_mask",
}
MODIFIER_ITEMS_WITH_LEVELS["modifier_orb_of_darkness_active"] = {
	"item_bracer_of_the_void",
	"item_orb_of_darkness2",
	"item_orb_of_darkness",
}
MODIFIER_ITEMS_WITH_LEVELS["modifier_orb_of_lightning_active"] = {
	"item_celestial_claws",
	"item_orb_of_lightning2",
	"item_orb_of_lightning",
}

XHS_CREEPS_INTERVAL = 20.0
XHS_SPECIAL_EVENT_INTERVAL = 540.0 -- 9 min (has to be a multiple of 3)
XHS_SPECIAL_WAVE_INTERVAL = XHS_SPECIAL_EVENT_INTERVAL / 3 -- 3 min
XHS_SPECIAL_INITIAL_WAVE_DELAY = XHS_SPECIAL_WAVE_INTERVAL -- 3 min
XHS_CREEPS_UPGRADE_INTERVAL = XHS_SPECIAL_EVENT_INTERVAL / 2 -- 4:30
XHS_PHASE_2_DELAY = 420.0 -- 7 min

XHS_MURADIN_EVENT_GOLD = 20000
XHS_MURADIN_EVENT_DURATION = 120.0
