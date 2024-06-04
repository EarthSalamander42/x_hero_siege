require('internal/util')
require('internal/vanilla_extension')
require('gamemode')

function Precache(context)
	-- Lua Modifiers
	LinkLuaModifier("modifier_provides_fow_position", "modifiers/modifier_provides_fow_position", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_npc_dialog", "modifiers/modifier_npc_dialog", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_npc_dialog_notify", "modifiers/modifier_npc_dialog_notify", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_stack_count_animation_controller", "modifiers/modifier_stack_count_animation_controller", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_disable_aggro", "modifiers/modifier_disable_aggro", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_tome_of_stats", "items/tomes.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_pause_creeps", "modifiers/modifier_pause_creeps.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_custom_mechanics", "modifiers/modifier_custom_mechanics", LUA_MODIFIER_MOTION_NONE)

	-- Not used currently
	--	PrecacheResource("particle", "particles/units/heroes/hero_dazzle/dazzle_armor_enemy_ring_sink.vpcf", context) -- Armor Rune Effect (not used)
	--	PrecacheResource("particle_folder", "particles/econ/items/phoenix/phoenix_solar_forge/phoenix_sunray_solar_forge", context) -- Iron Man ult
	--	PrecacheResource("particle_folder", "particles/econ/events/ti7/teleport_end_ti7_lvl3.vpcf", context) -- teleport effect for "TeleportHero" lua function

	-- Not sure those are needed to be precached
	--	PrecacheResource("particle_folder", "particles/status_fx", context) (not sure this is needed)
	--	PrecacheResource("particle_folder", "particles/items2_fx", context)
	--	PrecacheResource("particle", "particles/units/heroes/hero_earth_spirit/espirit_geomagentic_target_sphere.vpcf", context)
	--	PrecacheResource("particle", "particles/units/heroes/hero_ember_spirit/ember_spirit_flameguard.vpcf", context) -- Immolation
	PrecacheResource("particle", "particles/items2_fx/teleport_start.vpcf", context)                          -- Immolation
	PrecacheResource("particle", "particles/items2_fx/teleport_end.vpcf", context)                            -- Immolation
	PrecacheResource("particle", "particles/econ/events/fall_major_2016/teleport_start_fm06_lvl3.vpcf", context) -- Immolation
	PrecacheResource("particle", "particles/econ/events/fall_major_2016/teleport_end_fm06_lvl3.vpcf", context) -- Immolation
	PrecacheResource("particle_folder", "particles/custom", context)
	PrecacheResource("particle_folder", "particles/custom/items/orb", context)
	PrecacheResource("particle_folder", "models/items/lone_druid/true_form/form_of_the_atniw", context)
	PrecacheResource("particle_folder", "models/items/lone_druid/bear/spirit_of_the_atniw", context)

	PrecacheResource("particle_folder", "particles/econ/items/puck/puck_alliance_set", context)                                      -- Dark Portal attack projectile
	PrecacheResource("particle_folder", "particles/econ/items/shadow_fiend/sf_desolation", context)                                  -- Banehallow attack projectile
	PrecacheResource("particle_folder", "particles/econ/items/rubick/rubick_staff_wandering", context)                               -- Doom Golem attack projectile

	PrecacheResource("particle", "particles/econ/items/dazzle/dazzle_dark_light_weapon/dazzle_dark_shallow_grave_ground.vpcf", context) -- Armor Rune Overhead
	PrecacheResource("particle", "particles/units/heroes/hero_lone_druid/lone_druid_battle_cry_overhead_ember.vpcf", context)        -- Immolation Rune Overhead
	PrecacheResource("particle", "particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis_base_attack.vpcf", context)      -- Illidan boss attack projectile

	PrecacheResource("model_folder", "models/heroes/skeleton_king", context)                                                         --Lich King Boss
	PrecacheResource("model_folder", "models/items/dragon_knight/ascension_weapon", context)                                         --Arthas Boss Set
	PrecacheResource("model_folder", "models/items/dragon_knight/ascension_back", context)
	PrecacheResource("model_folder", "models/items/dragon_knight/ascension_offhand", context)
	PrecacheResource("model_folder", "models/items/dragon_knight/ascension_arms", context)
	PrecacheResource("model_folder", "models/items/dragon_knight/ascension_shoulder", context)
	PrecacheResource("model_folder", "models/items/dragon_knight/ascension_head", context)
	PrecacheResource("model_folder", "models/items/juggernaut/arcana", context)

	PrecacheResource("model_folder", "models/items/chaos_knight/ck_esp_blade", context) --Dark Fundamental Boss Set
	PrecacheResource("model_folder", "models/items/chaos_knight/ck_esp_helm", context)
	PrecacheResource("model_folder", "models/items/chaos_knight/ck_esp_mount", context)
	PrecacheResource("model_folder", "models/items/chaos_knight/ck_esp_shield", context)
	PrecacheResource("model_folder", "models/items/chaos_knight/ck_esp_shoulder", context)
	PrecacheResource("model_folder", "particles/units/heroes/hero_nyx_assassin", context)
	PrecacheResource("model_folder", "models/items/furion/treant/the_ancient_guardian_the_ancient_treants", context)
	PrecacheResource("model_folder", "particles/econ/events/fall_major_2015", context)

	PrecacheResource("particle", "particles/act_2/campfire_flame.vpcf", context)
	PrecacheResource("particle", "particles/camp_fire_buff.vpcf", context)
	PrecacheResource("particle", "particles/custom/undead/disease_cloud.vpcf", context)

	-- TODO: remove all of those and precache them in abilities kv instead
	-- PRECACHE HEROES (Particle effects for custom abilities)
	--	PrecacheUnitByNameAsync("npc_dota_hero_antimage", context)		-- Shaman?
	--	PrecacheUnitByNameAsync("npc_dota_hero_centaur", context)		-- Beastmaster & Arthas & [creature?] & Tauren Chieftain & Pit Lord & Crypt Lord
	PrecacheUnitByNameAsync("npc_dota_hero_chaos_knight", context) -- Special Wave and creeps [what about dark fundamental?]
	--	PrecacheUnitByNameAsync("npc_dota_hero_clinkz", context)		-- Windrunner
	PrecacheUnitByNameAsync("npc_dota_hero_clockwerk", context) -- Space Marine PC and NPC?
	PrecacheUnitByNameAsync("npc_dota_hero_dazzle", context)    -- Creep - orc ranged 2
	--	PrecacheUnitByNameAsync("npc_dota_hero_drow_ranger", context)	-- Lich & Dryad [and apparently meepo wat]
	--	PrecacheUnitByNameAsync("npc_dota_hero_ember_spirit", context) 	-- Ember Spirit & Cloak of Flames & Immolation etc.
	PrecacheUnitByNameAsync("npc_dota_hero_huskar", context)           -- For creeps
	PrecacheUnitByNameAsync("npc_dota_hero_keeper_of_the_light", context) -- Light Fundamental?
	PrecacheUnitByNameAsync("npc_dota_hero_kunkka", context)           -- last wave and 4 bosses kunkkas?
	PrecacheUnitByNameAsync("npc_dota_hero_lifestealer", context)      -- creep wave 4? Meepo?
	--	PrecacheUnitByNameAsync("npc_dota_hero_lion", context) 			-- Warden &  Pit Lord
	PrecacheUnitByNameAsync("npc_dota_hero_lycan", context)            -- Archimonde??
	--	PrecacheUnitByNameAsync("npc_dota_hero_magnataur", context) 	-- Magnataur & Tauren Chieftain
	--	PrecacheUnitByNameAsync("npc_dota_hero_morphling", context)		-- Archmage & Archimage
	PrecacheUnitByNameAsync("npc_dota_hero_naga_siren", context)    -- Special Wave 2
	PrecacheUnitByNameAsync("npc_dota_hero_necrolyte", context)     -- Special Wave 1 & Tauren Chieftain & Dark Summoner & LK & Paladin &
	PrecacheUnitByNameAsync("npc_dota_hero_ogre_magi", context)     -- Sniper
	PrecacheUnitByNameAsync("npc_dota_hero_phoenix", context)       -- Dragons Level 1 & Invo
	PrecacheUnitByNameAsync("npc_dota_hero_razor", context)         -- Ghost Revenant? & Sniper [prolly the NPC revenants too]
	--	PrecacheUnitByNameAsync("npc_dota_hero_silencer", context) 		-- Warden (PA) & Kobold (Meepo)
	PrecacheUnitByNameAsync("npc_dota_hero_slardar", context)       -- Slardar (Centurion) & wind & LK
	PrecacheUnitByNameAsync("npc_dota_hero_storm_spirit", context)  -- For Spirit Master.
	PrecacheUnitByNameAsync("npc_dota_hero_techies", context)       -- Shaman most likely
	PrecacheUnitByNameAsync("npc_dota_hero_templar_assassin", context) --
	--	PrecacheUnitByNameAsync("npc_dota_hero_tiny", context) 			-- For Mountain Giant
	--	PrecacheUnitByNameAsync("npc_dota_hero_treant", context) 		-- for Malfurion?
	PrecacheUnitByNameAsync("npc_dota_hero_vengefulspirit", context) -- For Incoming Wave 3. & Paladin
	PrecacheUnitByNameAsync("npc_dota_hero_weaver", context)      -- for creeps?
	PrecacheUnitByNameAsync("npc_dota_hero_wisp", context)        -- For Connecting bug
	PrecacheUnitByNameAsync("npc_dota_hero_zuus", context)        -- Muradin Bronzebeard

	PrecacheUnitByNameSync("npc_spirit_beast_bis", context)
	PrecacheUnitByNameSync("npc_frost_infernal_bis", context)

	PrecacheUnitByNameAsync("npc_dota_hero_grom_hellscream", context)
	PrecacheUnitByNameAsync("npc_dota_hero_illidan", context)
	PrecacheUnitByNameAsync("npc_dota_hero_balanar", context)
	PrecacheUnitByNameAsync("npc_dota_hero_proudmoore", context)

	-- PRECACHE SOUNDS
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_abaddon.vsndevts", context)    -- For Lich King shield spell
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_death_prophet.vsndevts", context) -- For Incoming Wave 4
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_enigma.vsndevts", context)     -- For Incoming Wave 4
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_faceless_void.vsndevts", context) -- Lich King Chronosphere (boss)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_juggernaut.vsndevts", context) -- For Grom boss (crit sounds?)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_obsidian_destroyer.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_queenofpain.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_sandking.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_skeletonking.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_skywrath_mage.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_spectre.vsndevts", context)

	PrecacheResource("soundfile", "soundevents/game_sounds_custom.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_dungeon.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_dungeon_enemies.vsndevts", context)

	-- Units Precache
	PrecacheUnitByNameAsync("npc_dota_lycan_wolf1", context)
	PrecacheUnitByNameAsync("npc_dota_shadowshaman_serpentward", context)
	PrecacheUnitByNameAsync("npc_dota_furbolg", context)
	PrecacheUnitByNameAsync("npc_dota_creature_muradin_bronzebeard", context)

	-- Final Wave
	PrecacheItemByNameSync("item_tombstone", context)

	for _, hero in pairs(HEROLIST) do
		PrecacheUnitByNameAsync("npc_dota_hero_" .. hero, context)
	end

	for _, hero in pairs(HEROLIST_VIP) do
		PrecacheUnitByNameAsync("npc_dota_hero_" .. hero, context)
	end
end

-- Create the game mode when we activate
function Activate()
	GameRules.GameMode = GameMode()
	GameRules.GameMode:InitGameMode()
end
