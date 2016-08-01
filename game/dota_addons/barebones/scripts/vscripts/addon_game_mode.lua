require('internal/util')
require('gamemode')
require("statcollection/init")

-- Precache resources
function Precache( context )
	PrecacheItemByNameSync( "item_ankh_of_reincarnation", context )
	PrecacheItemByNameSync( "item_assassins_blade", context )
	PrecacheItemByNameSync( "item_claws_of_attack", context )
	PrecacheItemByNameSync( "item_desolator2", context )
	PrecacheItemByNameSync( "item_desolator3", context )

	-- Desolator Custom Effect Precache
	PrecacheResource( "particle_folder", "particles/econ/items/antimage/antimage_weapon_basher_ti5_gold", context )

	-- PRECACHE HEROES EFFECTS
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_lifestealer", context )
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_weaver", context )
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_pudge", context )
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_death_prophet", context )
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_undying", context )
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_necrolyte", context )
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_nyx_assassin", context )
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_bane", context )
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_phoenix", context )
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_doom", context )
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_razor", context )
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_magnataur", context )
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_lina", context )
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_antimage", context )
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_luna", context )
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_sniper", context )
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_juggernaut", context )
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_warlock", context )
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_centaur", context )
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_death_prophet", context )
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_brewmaster", context )
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_skeletonking", context )
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_terrorblade", context )
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_legion_commander", context )
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_omniknight", context )
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_tiny", context )
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_naga_siren", context )
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_nevermore", context )
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_vengeful", context )
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_abaddon", context )
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_skeletonking", context )
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_drow", context )
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_clinkz", context )
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_sven", context )
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_stormspirit", context )
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_ursa", context )
	PrecacheResource( "particle_folder", "particles/units/heroes/hero_venomancer", context )
	PrecacheResource( "particle_folder", "particles/items_fx", context )

	-- PRECACHE SOUNDS
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_lina.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_magnataur.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_brewmaster.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_invoker.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_skeletonking.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_juggernaut.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_terrorblade.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_legion_commander.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_tiny.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_razor.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_warlock.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_naga_siren.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_omniknight.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_nevermore.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_vengefulspirit.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_ogre_magi.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_abaddon.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_drowranger.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_clinkz.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_sven.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_stormspirit.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_leshrac.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_techies.vsndevts", context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_ursa.vsndevts", context )

	-- PHASE 1
	PrecacheUnitByNameSync( "npc_dota_creature_mini_lifestealers", context)
	PrecacheUnitByNameSync( "npc_dota_creature_mini_weavers", context)
	PrecacheUnitByNameSync( "npc_dota_creature_mini_undyings", context)
	PrecacheUnitByNameSync( "npc_dota_creature_mini_necrolytes", context)
	PrecacheUnitByNameSync( "npc_dota_creature_mini_nyxes", context)
	PrecacheUnitByNameSync( "npc_dota_creature_mini_banes", context)
	PrecacheUnitByNameSync( "npc_dota_creature_mini_dooms", context)
	PrecacheUnitByNameSync( "npc_dota_creature_mini_phoenixes", context)
	PrecacheUnitByNameSync( "npc_dota_creature_mini_lancers", context)
	PrecacheUnitByNameSync( "npc_dota_creature_mini_miranas", context)

	PrecacheUnitByNameSync( "npc_death_ghost_tower", context)
	PrecacheUnitByNameSync( "npc_magnataur_destroyer_crypt", context)
	-- Incoming Waves
	PrecacheUnitByNameSync( "npc_dota_creature_death_prophet_event_1", context)
	PrecacheUnitByNameSync( "npc_dota_creature_naga_siren_event_2", context)
	PrecacheUnitByNameSync( "npc_dota_creature_vengeful_spirit_event_3", context)
	PrecacheUnitByNameSync( "npc_dota_creature_captain_event_4", context)

	-- Special Events
	PrecacheUnitByNameSync( "npc_dota_creature_muradin_bronzebeard", context)

	-- PHASE 2
	PrecacheUnitByNameSync( "npc_ghul_II", context)
	PrecacheUnitByNameSync( "npc_orc_II", context)
	-- Final Wave
	PrecacheUnitByNameSync( "npc_dota_hero_balanar_final_wave", context)
	PrecacheUnitByNameSync( "npc_guard_final_wave", context)
	PrecacheUnitByNameSync( "npc_keeper_final_wave", context)
	PrecacheUnitByNameSync( "npc_luna_final_wave", context)
	PrecacheUnitByNameSync( "npc_chaos_orc_final_wave", context)
	PrecacheUnitByNameSync( "npc_warlock_final_wave", context)
	PrecacheUnitByNameSync( "npc_orc_raider_final_wave", context)
--	PrecacheUnitByNameSync( "npc_dota_hero_grom_hellscream_final_wave", context)
	PrecacheUnitByNameSync( "npc_dota_hero_illidan_final_wave", context)
	PrecacheUnitByNameSync( "npc_dota_hero_proudmoore_final_wave", context)
	PrecacheUnitByNameSync( "npc_knight_final_wave", context)

	-- PHASE 3
	PrecacheUnitByNameSync( "npc_dota_creep_radiant_hulk", context)
	PrecacheUnitByNameSync( "npc_dota_creep_dire_hulk", context)
	PrecacheUnitByNameSync( "npc_dota_warlock_golem_3", context)

	-- 4 Bosses Arena
	PrecacheUnitByNameSync( "npc_dota_hero_grom_hellscream", context)

	-- Last Arena
	PrecacheUnitByNameSync( "npc_dota_hero_arthas", context)
	PrecacheUnitByNameSync( "npc_dota_hero_banehallow", context)
	PrecacheUnitByNameSync( "npc_death_revenant_banehallow", context)
	PrecacheUnitByNameSync( "npc_dota_creature_abaddon", context)

	-- X HEROES PRECACHING
	PrecacheUnitByNameSync( "dark_portal_1", context)
	PrecacheUnitByNameSync( "serpent_ward_1", context)
	PrecacheUnitByNameSync( "laser_trap_1", context)
	PrecacheUnitByNameSync( "npc_dota_lich_frost_beast", context)
	PrecacheUnitByNameSync( "npc_infernal_beast", context) -- Balanar Beasts
end

-- Create the game mode when we activate
function Activate()
	GameRules.GameMode = GameMode()
	GameRules.GameMode:InitGameMode()
end

