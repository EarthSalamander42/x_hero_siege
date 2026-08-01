"use strict";

// Curated from XHS' playable heroes and units already shipped by the addon.
// Keeping this list explicit makes the Panorama previews deterministic and lets
// the server validate every request against the same unit families.
var XHSSupporterEffigyCatalog = {
	heroes: [
		"enchantress", "crystal_maiden", "luna", "lone_druid", "pugna", "lich",
		"nyx_assassin", "abyssal_underlord", "terrorblade", "phantom_assassin",
		"elder_titan", "mirana", "dragon_knight", "windrunner", "invoker", "sniper",
		"shadow_shaman", "juggernaut", "omniknight", "rattletrap", "chen", "lina",
		"sven", "ursa", "nevermore", "brewmaster", "warlock", "razor", "slardar",
		"skeleton_king", "meepo", "chaos_knight", "tiny", "sand_king", "necrolyte",
		"storm_spirit"
	].map(function (hero) {
		return { asset_id: "npc_dota_hero_" + hero, unit: "npc_dota_hero_" + hero, category: "hero" };
	}),
	creeps: [
		["npc_xhs_undead_creep_melee_1", "Undead Skeleton"],
		["npc_xhs_elf_creep_melee_1", "Elven Satyr"],
		["npc_xhs_orc_creep_melee_1", "Orc Ogre"],
		["npc_xhs_human_creep_melee_1", "Human Footman"],
		["npc_xhs_undead_creep_ranged_1", "Undead Ghost"],
		["npc_xhs_orc_creep_ranged_1", "Orc Berserker"],
		["npc_xhs_elf_creep_ranged_1", "Elven Harpy"],
		["npc_xhs_human_creep_ranged_1", "Human Rifleman"],
		["npc_dota_creature_red_dragon", "Red Dragon"],
		["npc_dota_creature_black_dragon", "Black Dragon"],
		["npc_dota_creature_green_dragon", "Green Dragon"],
		["npc_dota_creature_wildkin", "Wildkin"],
		["npc_dota_creature_golem", "Stone Golem"],
		["npc_dota_creature_polar_furbolg", "Polar Furbolg"],
		["npc_dota_creature_centaur", "Centaur"],
		["npc_dota_creature_revenant", "Revenant"]
	].map(function (entry) {
		return { asset_id: entry[0], unit: entry[0], name: entry[1], category: "creep" };
	}),
	bosses: [
		["npc_dota_hero_magtheridon", "Magtheridon"],
		["npc_dota_hero_grom_hellscream", "Grom Hellscream"],
		["npc_dota_hero_proudmoore", "Proudmoore"],
		["npc_dota_hero_illidan", "Illidan"],
		["npc_dota_hero_balanar", "Balanar"],
		["npc_dota_hero_arthas", "Arthas"],
		["npc_dota_boss_lich_king", "The Lich King"],
		["npc_dota_hero_banehallow", "Banehallow"],
		["npc_dota_boss_spirit_master", "Spirit Master"],
		["npc_dota_boss_spirit_master_fire", "Fire Spirit"],
		["npc_dota_boss_spirit_master_storm", "Storm Spirit"],
		["npc_dota_boss_spirit_master_earth", "Earth Spirit"],
		["npc_dota_lich_king_sindragosa", "Sindragosa"],
		["npc_infernal_beast", "Infernal Beast"]
	].map(function (entry) {
		return { asset_id: entry[0], unit: entry[0], name: entry[1], category: "boss" };
	})
};
