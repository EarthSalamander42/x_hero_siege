require("statcollection/init")
require('internal/util')
require('internal/vanilla_extension')
require('gamemode')

function Precache(context)
-- Custom Effects Precache
	PrecacheResource("particle_folder", "particles/econ/items/phantom_assassin/phantom_assassin_arcana_elder_smith", context)
	PrecacheResource("particle_folder", "particles/econ/items/luna/luna_crescent_moon", context)
	PrecacheResource("particle_folder", "particles/econ/items/gyrocopter/hero_gyrocopter_atomic_gold", context)
	PrecacheResource("particle_folder", "particles/econ/items/clockwerk/clockwerk_paraflare", context)
	PrecacheResource("particle_folder", "particles/econ/items/puck/puck_alliance_set", context)
	PrecacheResource("particle_folder", "particles/econ/items/shadow_fiend/sf_desolation", context)
	PrecacheResource("particle_folder", "particles/status_fx", context)
	PrecacheResource("particle_folder", "particles/econ/items/gyrocopter/hero_gyrocopter_gyrotechnics", context)
	PrecacheResource("particle_folder", "particles/econ/courier/courier_wyvern_hatchling", context)
	PrecacheResource("particle_folder", "particles/econ/items/wraith_king/wraith_king_ti6_bracer", context)
	PrecacheResource("particle_folder", "particles/econ/items/tinker/tinker_motm_rollermaw", context)
	PrecacheResource("particle_folder", "particles/econ/items/abaddon/abaddon_alliance", context)
	PrecacheResource("particle_folder", "particles/econ/items/razor/razor_ti6", context)
	PrecacheResource("particle_folder", "particles/items2_fx", context)
	PrecacheResource("particle_folder", "particles/custom", context)
	PrecacheResource("particle_folder", "particles/econ/events/ti6", context)
	PrecacheResource("particle_folder", "particles/units/heroes/hero_dragon_knight", context)
	PrecacheResource("particle_folder", "particles/custom/items/orb", context)
	PrecacheResource("particle_folder", "models/items/lone_druid/true_form/form_of_the_atniw", context)
	PrecacheResource("particle_folder", "models/items/lone_druid/bear/spirit_of_the_atniw", context)
	PrecacheResource("particle_folder", "particles/econ/events/ti6", context)
	PrecacheResource("particle_folder", "particles/econ/items/magnataur/shock_of_the_anvil", context)
	PrecacheResource("particle_folder", "particles/econ/items/rubick/rubick_staff_wandering", context)
	PrecacheResource("particle_folder", "particles/econ/courier/courier_roshan_frost", context)
	PrecacheResource("particle_folder", "models/items/ancient_apparition/shatterblast_crown", context)
	PrecacheResource("particle_folder", "particles/econ/items/nyx_assassin/nyx_assassin_ti6_witness", context)
	PrecacheResource("particle_folder", "particles/econ/courier/courier_axolotl_ambient", context)
	PrecacheResource("particle_folder", "particles/units/heroes/hero_earth_spirit", context)
	PrecacheResource("particle_folder", "particles/econ/items/effigies/status_fx_effigies", context)
	PrecacheResource("particle_folder", "particles/econ/items/shadow_fiend/sf_fire_arcana", context)
	PrecacheResource("particle_folder", "particles/econ/items/abaddon/abaddon_alliance", context)
	PrecacheResource("particle_folder", "particles/units/heroes/hero_abaddon", context)
	PrecacheResource("particle_folder", "particles/units/heroes/hero_desert_wyrm", context)
	PrecacheResource("particle_folder", "particles/econ/items/phoenix/phoenix_solar_forge/phoenix_sunray_solar_forge", context)
	PrecacheResource("particle_folder", "particles/units/heroes/heroes_underlord", context)
	PrecacheResource("particle_folder", "particles/frostivus_gameplay", context)
	PrecacheResource("particle_folder", "particles/econ/events/ti7/teleport_end_ti7_lvl3.vpcf", context)
	PrecacheResource("particle_folder", "particles/units/heroes/hero_shadow_shaman", context)

	PrecacheResource("particle", "particles/units/heroes/hero_dazzle/dazzle_armor_enemy_ring_sink.vpcf", context)
	PrecacheResource("particle", "particles/econ/items/dazzle/dazzle_dark_light_weapon/dazzle_dark_shallow_grave_ground.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_lone_druid/lone_druid_battle_cry_overhead_ember.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis_base_attack.vpcf", context) -- Illidan boss attack projectile

	PrecacheResource("model_folder", "models/heroes/skeleton_king", context) --Lich King Boss
	PrecacheResource("model_folder", "models/items/dragon_knight/ascension_weapon", context) --Arthas Boss Set
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

	-- PRECACHE HEROES (Particle effects for custom abilities)
	PrecacheUnitByNameAsync("npc_dota_hero_antimage", context)
	PrecacheUnitByNameAsync("npc_dota_hero_centaur", context)
	PrecacheUnitByNameAsync("npc_dota_hero_chaos_knight", context) -- Special Wave and creeps
	PrecacheUnitByNameAsync("npc_dota_hero_clinkz", context)
	PrecacheUnitByNameAsync("npc_dota_hero_clockwerk", context)
	PrecacheUnitByNameAsync("npc_dota_hero_dazzle", context)
	PrecacheUnitByNameAsync("npc_dota_hero_drow_ranger", context)
	PrecacheUnitByNameAsync("npc_dota_hero_earth_spirit", context)
	PrecacheUnitByNameAsync("npc_dota_hero_ember_spirit", context)
	PrecacheUnitByNameAsync("npc_dota_hero_faceless_void", context)
	PrecacheUnitByNameAsync("npc_dota_hero_huskar", context) -- For creeps
	PrecacheUnitByNameAsync("npc_dota_hero_keeper_of_the_light", context)
	PrecacheUnitByNameAsync("npc_dota_hero_kunkka", context)
	PrecacheUnitByNameAsync("npc_dota_hero_lifestealer", context)
	PrecacheUnitByNameAsync("npc_dota_hero_lion", context)
	PrecacheUnitByNameAsync("npc_dota_hero_lycan", context)
	PrecacheUnitByNameAsync("npc_dota_hero_magnataur", context)
	PrecacheUnitByNameAsync("npc_dota_hero_morphling", context)
	PrecacheUnitByNameAsync("npc_dota_hero_naga_siren", context) -- Special Wave 2
	PrecacheUnitByNameAsync("npc_dota_hero_necrolyte", context) -- Special Wave 1
	PrecacheUnitByNameAsync("npc_dota_hero_ogre_magi", context)
	PrecacheUnitByNameAsync("npc_dota_hero_phoenix", context) -- Dragons Level 1
	PrecacheUnitByNameAsync("npc_dota_hero_razor", context)
	PrecacheUnitByNameAsync("npc_dota_hero_silencer", context)
	PrecacheUnitByNameAsync("npc_dota_hero_slardar", context) -- Slardar (Centurion)
	PrecacheUnitByNameAsync("npc_dota_hero_storm_spirit", context) -- For Spirit Master.
	PrecacheUnitByNameAsync("npc_dota_hero_techies", context)
	PrecacheUnitByNameAsync("npc_dota_hero_templar_assassin", context)
	PrecacheUnitByNameAsync("npc_dota_hero_tinker", context) -- For Windrunner Lvl 20 Ability
	PrecacheUnitByNameAsync("npc_dota_hero_tiny", context) -- For Mountain Giant
	PrecacheUnitByNameAsync("npc_dota_hero_treant", context)
	PrecacheUnitByNameAsync("npc_dota_hero_vengefulspirit", context) -- For Incoming Wave 3.
	PrecacheUnitByNameAsync("npc_dota_hero_weaver", context)
	PrecacheUnitByNameAsync("npc_dota_hero_wisp", context) -- For Connecting bug
	PrecacheUnitByNameAsync("npc_dota_hero_zuus", context) -- Muradin Bronzebeard

	PrecacheUnitByNameSync( "npc_dota_hero_skeleton_king_bis", context)

	PrecacheUnitByNameSync( "npc_spirit_beast_bis", context)
	PrecacheUnitByNameSync( "npc_frost_infernal_bis", context)

--	-- PRECACHE SOUNDS
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_death_prophet.vsndevts", context) -- For Incoming Wave 4
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_lycan.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_magnataur.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_obsidian_destroyer.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_ogre_magi.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_queenofpain.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_sandking.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_skeletonking.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_skywrath_mage.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_spectre.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_techies.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_tinker.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_tiny.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_zuus.vsndevts", context)

	PrecacheResource("soundfile", "soundevents/game_sounds_custom.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_dungeon.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_dungeon_enemies.vsndevts", context)

--	-- Units Precache
	PrecacheUnitByNameAsync("npc_dota_lycan_wolf1", context)
	PrecacheUnitByNameAsync("npc_dota_shadowshaman_serpentward", context)
	PrecacheUnitByNameAsync("npc_dota_furbolg", context)
	PrecacheUnitByNameAsync("npc_dota_creature_muradin_bronzebeard", context)

	-- Final Wave
	PrecacheItemByNameSync("item_tombstone", context)

	for _, hero in pairs(HEROLIST) do
		PrecacheUnitByNameAsync("npc_dota_hero_"..hero, context)
	end

	for _, hero in pairs(HEROLIST_VIP) do
		PrecacheUnitByNameAsync("npc_dota_hero_"..hero, context)
	end
end

-- Create the game mode when we activate
function Activate()
	GameRules.GameMode = GameMode()
	GameRules.GameMode:InitGameMode()
end
