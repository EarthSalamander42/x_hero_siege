local XHS_BOOT_NATIVE_PRINT = _G.XHSBootstrapNativePrint or print
_G.XHSBootstrapNativePrint = XHS_BOOT_NATIVE_PRINT
_G.XHSBootstrapLogBuffer = _G.XHSBootstrapLogBuffer or {}
_G.XHSDiagnosticBuild = "farm-exit-diagnostics-20260811-1"
_G.XHSBootstrapSequence = _G.XHSBootstrapSequence or 0

local function XHSBootstrapTraceback(err)
	local message = tostring(err or "Unknown bootstrap error")
	if debug ~= nil and debug.traceback ~= nil then
		local ok, trace = pcall(debug.traceback, message, 2)
		if ok and trace ~= nil then return tostring(trace) end
	end
	return message
end

function XHSBootstrapLog(level, content)
	level = string.lower(tostring(level or "info"))
	if level ~= "error" and level ~= "critical" and level ~= "warn" then
		return
	end

	_G.XHSBootstrapSequence = (_G.XHSBootstrapSequence or 0) + 1
	local gameState = -1
	if GameRules ~= nil and GameRules.State_Get ~= nil then
		local stateOK, stateValue = pcall(function() return GameRules:State_Get() end)
		if stateOK then gameState = tonumber(stateValue) or -1 end
	end
	local mapName = "unknown"
	if GetMapName ~= nil then
		local mapOK, mapValue = pcall(GetMapName)
		if mapOK then mapName = tostring(mapValue or "unknown") end
	end
	local toolsMode = false
	if IsInToolsMode ~= nil then
		local toolsOK, toolsValue = pcall(IsInToolsMode)
		if toolsOK then toolsMode = toolsValue == true end
	end
	local prefix = "build=" .. tostring(_G.XHSDiagnosticBuild)
		.. " seq=" .. tostring(_G.XHSBootstrapSequence)
		.. " state=" .. tostring(gameState)
		.. " map=" .. mapName
		.. " tools=" .. tostring(toolsMode)
		.. " | "
	local entry = {
		level = level,
		content = prefix .. tostring(content or ""),
		trace = {},
	}
	local queued = false

	if api ~= nil and type(api.QueueRuntimeLog) == "function" then
		local ok = pcall(function()
			api:QueueRuntimeLog(entry)
		end)
		queued = ok
	end

	if not queued then
		table.insert(_G.XHSBootstrapLogBuffer, entry)
		while #_G.XHSBootstrapLogBuffer > 200 do
			table.remove(_G.XHSBootstrapLogBuffer, 1)
		end
	end

	if XHS_BOOT_NATIVE_PRINT ~= nil then
		pcall(XHS_BOOT_NATIVE_PRINT, "[" .. entry.level .. "][XHS_BOOT] " .. entry.content)
	end

end

function XHSFlushBootstrapLogs()
	if api == nil or type(api.QueueRuntimeLog) ~= "function" then return false end

	local pending = _G.XHSBootstrapLogBuffer or {}
	_G.XHSBootstrapLogBuffer = {}
	for _, entry in ipairs(pending) do
		local ok = pcall(function()
			api:QueueRuntimeLog(entry)
		end)
		if not ok then
			table.insert(_G.XHSBootstrapLogBuffer, entry)
		end
	end
	return #_G.XHSBootstrapLogBuffer == 0
end

-- adv_log protects Dynamic_Wrap callbacks, but anonymous game-event listeners
-- otherwise bypass it. Install this before any runtime module is required so
-- production-only listener failures are captured with a traceback as well.
_G.XHSNativeListenToGameEvent = _G.XHSNativeListenToGameEvent or ListenToGameEvent
if _G.XHSNativeListenToGameEvent ~= nil then
	ListenToGameEvent = function(eventName, callback, context)
		if type(callback) ~= "function" then
			return _G.XHSNativeListenToGameEvent(eventName, callback, context)
		end

		return _G.XHSNativeListenToGameEvent(eventName, function(...)
			local args = { ... }
			local result = nil
			local ok, err = xpcall(function()
				result = callback(unpack(args))
			end, XHSBootstrapTraceback)
			if not ok then
				XHSBootstrapLog("error", "event=" .. tostring(eventName) .. "\n" .. tostring(err))
			end
			return result
		end, context)
	end
end

local function XHSBootstrapRequire(moduleName)
	local result = nil
	local ok, err = xpcall(function()
		result = require(moduleName)
	end, XHSBootstrapTraceback)
	if not ok then
		XHSBootstrapLog("error", "require failed module=" .. tostring(moduleName)
			.. "\n" .. tostring(err))
	end
	return ok, result
end

XHSBootstrapRequire('libraries/camera_motion')
XHSBootstrapRequire('internal/util')
XHSBootstrapRequire('components/precache/init')
XHSBootstrapRequire('internal/vanilla_extension')
XHSBootstrapRequire('gamemode')

local function XHSPrecacheImpl(context)
	-- AddBotPlayerWithEntityScript bootstraps fake clients as Wisp. Keep the
	-- model resident before any player can trigger bot provisioning.
	PrecacheResource("model", "models/heroes/wisp/wisp.vmdl", context)

	-- Lua Modifiers
	LinkLuaModifier("modifier_provides_fow_position", "modifiers/modifier_provides_fow_position", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_npc_dialog", "modifiers/modifier_npc_dialog", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_npc_dialog_notify", "modifiers/modifier_npc_dialog_notify", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_stack_count_animation_controller", "modifiers/modifier_stack_count_animation_controller", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_tome_of_stats", "items/tomes.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_pause_creeps", "modifiers/modifier_pause_creeps.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_command_restricted", "modifiers/modifier_command_restricted.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_xhs_uther_prison_target", "modifiers/modifier_xhs_uther_prison_target.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_cinematic_pause", "modifiers/modifier_cinematic_pause.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_cinematic_pause_release", "modifiers/modifier_cinematic_pause.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_custom_mechanics", "modifiers/modifier_custom_mechanics", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_xhs_space_marine_attack_sound", "modifiers/modifier_xhs_space_marine_attack_sound.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_xhs_growth_overhead", "modifiers/modifier_xhs_growth_overhead.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_xhs_end_screen_stat_tracker", "modifiers/modifier_xhs_end_screen_stat_tracker.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_xhs_tombstone_interaction", "modifiers/modifier_xhs_tombstone_interaction.lua", LUA_MODIFIER_MOTION_NONE)

	XHSPrecache:Run(context)

	-- Legacy keepalive: new assets should go through XHSPrecache groups or KV precache blocks.
	-- Keep this block temporarily while missing Valve/econ assets are tested in-game.

	-- Not used currently
	--	PrecacheResource("particle", "particles/units/heroes/hero_dazzle/dazzle_armor_enemy_ring_sink.vpcf", context) -- Armor Rune Effect (not used)
	--	PrecacheResource("particle_folder", "particles/econ/items/phoenix/phoenix_solar_forge/phoenix_sunray_solar_forge", context) -- Iron Man ult
	--	PrecacheResource("particle_folder", "particles/econ/events/ti7/teleport_end_ti7_lvl3.vpcf", context) -- teleport effect for "TeleportHero" lua function

	-- Not sure those are needed to be precached
	--	PrecacheResource("particle_folder", "particles/status_fx", context) (not sure this is needed)
	--	PrecacheResource("particle_folder", "particles/items2_fx", context)
	--	PrecacheResource("particle", "particles/units/heroes/hero_earth_spirit/espirit_geomagentic_target_sphere.vpcf", context)
	--	PrecacheResource("particle", "particles/units/heroes/hero_ember_spirit/ember_spirit_flameguard.vpcf", context) -- Immolation
	PrecacheResource("particle", "particles/items2_fx/teleport_start.vpcf", context)                                          -- Immolation
	PrecacheResource("particle", "particles/items2_fx/teleport_end.vpcf", context)                                            -- Immolation
	PrecacheResource("particle", "particles/units/heroes/hero_templar_assassin/templar_assassin_trap_rings_inner.vpcf", context) -- Final Wave dark portals
	PrecacheResource("particle", "particles/units/heroes/hero_wisp/wisp_relocate_marker.vpcf", context)                       -- Return position marker
	PrecacheResource("particle", "particles/econ/events/fall_major_2016/teleport_start_fm06_lvl3.vpcf", context)              -- Immolation
	PrecacheResource("particle", "particles/econ/events/fall_major_2016/teleport_end_fm06_lvl3.vpcf", context)                -- Immolation
	PrecacheResource("particle_folder", "particles/custom", context)
	PrecacheResource("particle_folder", "particles/custom/items/orb", context)

	PrecacheResource("particle_folder", "particles/econ/items/puck/puck_alliance_set", context)     -- Dark Portal attack projectile
	PrecacheResource("particle_folder", "particles/econ/items/shadow_fiend/sf_desolation", context) -- Banehallow attack projectile
	PrecacheResource("particle_folder", "particles/econ/items/rubick/rubick_staff_wandering", context) -- Doom Golem attack projectile
	PrecacheResource("particle_folder", "particles/units/heroes/hero_nyx_assassin", context)
	PrecacheResource("particle_folder", "particles/econ/events/fall_major_2015", context)

	PrecacheResource("particle", "particles/econ/items/dazzle/dazzle_dark_light_weapon/dazzle_dark_shallow_grave_ground.vpcf", context) -- Armor Rune Overhead
	PrecacheResource("particle", "particles/units/heroes/hero_lone_druid/lone_druid_battle_cry_overhead_ember.vpcf", context)        -- Immolation Rune Overhead
	PrecacheResource("particle", "particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis_base_attack.vpcf", context)      -- Illidan boss attack projectile
	PrecacheResource("particle", "particles/act_2/campfire_flame.vpcf", context)
	PrecacheResource("particle", "particles/camp_fire_buff.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_pudge/pudge_rot.vpcf", context)
	PrecacheResource("particle", "particles/units/heroes/hero_pudge/pudge_rot_recipient.vpcf", context)
	PrecacheResource("particle", "particles/items_fx/abyssal_blade_crimson_impact_sparks.vpcf", context)                     -- Phase 1 Human ranged creep Headshot
	PrecacheResource("particle", "particles/darkmoon_last_hit_effect.vpcf", context)
	PrecacheResource("particle", "particles/custom/xhs_growth_overhead.vpcf", context)                                       -- Farm event/Phase 2 overhead
	PrecacheResource("particle", "particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_shadowraze.vpcf", context) -- Boss death
	PrecacheResource("particle", "particles/units/heroes/hero_morphling/morphling_ambient_new.vpcf", context)                -- Lightning Sword
	PrecacheResource("particle", "particles/units/heroes/hero_ogre_magi/ogre_magi_ignite_debuff.vpcf", context)              -- Shield of Invincibility
	PrecacheResource("particle", "particles/units/heroes/hero_morphling/morphling_morph_agi.vpcf", context)                  -- Ring of Superiority
	PrecacheResource("particle", "particles/econ/courier/courier_greevil_red/courier_greevil_red_ambient_3.vpcf", context)   -- Orb of Fire dropped
	PrecacheResource("particle", "particles/units/heroes/hero_doom_bringer/doom_bringer_doom_ring.vpcf", context)            -- Necklace of Spell Immunity dropped
	PrecacheResource("particle", "particles/units/heroes/hero_jakiro/jakiro_base_attack.vpcf", context)                      -- Jakiro Level 2 creeps
	PrecacheResource("particle", "particles/units/heroes/hero_ancient_apparition/ancient_apparition_base_attack.vpcf", context) -- Necro Level 2 creeps
	PrecacheResource("particle", "particles/units/heroes/hero_lion/lion_base_attack.vpcf", context)                          -- Special Wave 2
	PrecacheResource("particle", "particles/econ/items/razor/razor_ti6/razor_base_attack_ti6.vpcf", context)                 -- Rifleman level 20 Laser projectile

	PrecacheResource("model_folder", "models/heroes/skeleton_king", context)                                                 --Lich King Boss
	PrecacheResource("model_folder", "models/items/warlock/archivist_golem", context)                                        -- Spirit Beast event
	PrecacheResource("model_folder", "models/creeps/ice_biome/storegga", context)                                            -- Frost Infernal event

	PrecacheResource("model_folder", "models/items/chaos_knight/ck_esp_blade", context)                                      --Dark Fundamental Boss Set
	PrecacheResource("model_folder", "models/items/chaos_knight/ck_esp_helm", context)
	PrecacheResource("model_folder", "models/items/chaos_knight/ck_esp_mount", context)
	PrecacheResource("model_folder", "models/items/chaos_knight/ck_esp_shield", context)
	PrecacheResource("model_folder", "models/items/chaos_knight/ck_esp_shoulder", context)
	PrecacheResource("model_folder", "models/items/furion/treant/the_ancient_guardian_the_ancient_treants", context)
	PrecacheResource("model_folder", "models/items/dragon_knight/aurora_warrior_set_dragon_style2_aurora_warrior_set", context)
	PrecacheResource("model_folder", "models/heroes/dragon_knight", context)         -- For some reason precaching the hero doesn't fix missing model
	PrecacheResource("model_folder", "models/heroes/juggernaut", context)            -- Grom Hellscream
	PrecacheResource("model_folder", "models/heroes/troll_warlord", context)         -- Orc ranged wave 3
	PrecacheResource("model_folder", "models/items/undying/idol_of_ruination", context) -- Archimonde minions

	PrecacheResource("model", "models/creeps/neutral_creeps/n_creep_troll_skeleton/n_creep_troll_skeleton_fx.vmdl", context)
	PrecacheResource("model", "models/gameplay/breakingcrate_dest.vmdl", context)
	PrecacheResource("model", "models/creeps/lane_creeps/creep_bad_melee_diretide/creep_bad_melee_diretide.vmdl", context)           -- Phase 2 creeps
	PrecacheResource("model", "models/items/warlock/golem/mystery_of_the_lost_ores_golem/mystery_of_the_lost_ores_golem.vmdl", context) -- Dark Protectors
	PrecacheResource("model", "models/items/warlock/golem/obsidian_golem/obsidian_golem.vmdl", context)                              -- Balanar's Infernal Beast
	PrecacheResource("model", "models/props_items/blinkdagger.vmdl", context)                                                        -- Lightning Sword
	PrecacheResource("model", "models/props_items/poor_man_shield01.vmdl", context)                                                  -- Shield of Invincibility
	PrecacheResource("model", "models/props_items/ring_health.vmdl", context)                                                        -- Ring of Superiority
	PrecacheResource("model", "models/heroes/witchdoctor/witchdoctor_ward.vmdl", context)                                            -- Archimonde Dark Portal
	PrecacheResource("model", "models/props_items/staff_wizardry01.vmdl", context)                                                   -- Necklace of Spell Immunity

	-- TODO: remove all of those and precache them in abilities kv instead
	-- PRECACHE HEROES (Particle effects for custom abilities)
	XHSPrecache:PrecacheUnit("npc_dota_hero_antimage", nil, -1) -- Creeps level 3
	XHSPrecache:PrecacheUnit("npc_dota_hero_centaur", nil, -1) -- Final Wave
	-- XHSPrecache:PrecacheUnit("npc_dota_hero_chaos_knight", nil, -1)     -- Special Wave and creeps [what about dark fundamental?]
	-- --	XHSPrecache:PrecacheUnit("npc_dota_hero_clinkz", nil, -1)		-- Windrunner
	-- XHSPrecache:PrecacheUnit("npc_dota_hero_clockwerk", nil, -1)        -- Space Marine PC and NPC?
	XHSPrecache:PrecacheUnit("npc_dota_hero_dark_seer", nil, -1)        -- Final Wave - East
	XHSPrecache:PrecacheUnit("npc_dota_hero_dazzle", nil, -1)           -- Creep - orc ranged 2
	XHSPrecache:PrecacheUnit("npc_dota_hero_dragon_knight", nil, -1)    -- Lich & Dryad [Creeps level 1]
	XHSPrecache:PrecacheUnit("npc_dota_hero_drow_ranger", nil, -1)      -- Lich & Dryad [and apparently meepo wat]
	XHSPrecache:PrecacheUnit("npc_dota_hero_death_prophet", nil, -1)    -- Final Wave
	XHSPrecache:PrecacheUnit("npc_dota_hero_earthshaker", nil, -1)      -- Lich & Dryad [Creeps level 1]
	XHSPrecache:PrecacheUnit("npc_dota_hero_huskar", nil, -1)           -- For creeps
	XHSPrecache:PrecacheUnit("npc_dota_hero_jakiro", nil, -1)           -- For creeps
	XHSPrecache:PrecacheUnit("npc_dota_hero_keeper_of_the_light", nil, -1) -- Light Fundamental?
	-- XHSPrecache:PrecacheUnit("npc_dota_hero_kunkka", nil, -1)           -- last wave and 4 bosses kunkkas?
	-- XHSPrecache:PrecacheUnit("npc_dota_hero_lifestealer", nil, -1)      -- creep wave 4? Meepo?
	-- XHSPrecache:PrecacheUnit("npc_dota_hero_luna", nil, -1)             -- creep wave 1
	-- --	XHSPrecache:PrecacheUnit("npc_dota_hero_lion", nil, -1) 			-- Warden &  Pit Lord
	XHSPrecache:PrecacheUnit("npc_dota_hero_life_stealer", nil, -1) -- Creep wave 1 (undead)
	XHSPrecache:PrecacheUnit("npc_dota_hero_lycan", nil, -1)     -- Creep level 4 human melee
	XHSPrecache:PrecacheUnit("npc_dota_hero_magnataur", nil, -1) -- Magnataur & Tauren Chieftain
	XHSPrecache:PrecacheUnit("npc_dota_hero_morphling", nil, -1) -- Archmage & Archimage
	XHSPrecache:PrecacheUnit("npc_dota_hero_naga_siren", nil, -1) -- Special Wave 2
	-- XHSPrecache:PrecacheUnit("npc_dota_hero_necrolyte", nil, -1)     -- Special Wave 1 & Tauren Chieftain & Dark Summoner & LK & Paladin &
	-- XHSPrecache:PrecacheUnit("npc_dota_hero_ogre_magi", nil, -1)     -- Sniper
	-- XHSPrecache:PrecacheUnit("npc_dota_hero_phoenix", nil, -1)       -- Dragons Level 1 & Invo
	XHSPrecache:PrecacheUnit("npc_dota_hero_troll_warlord", nil, -1) -- Orc ranged wave 3
	-- XHSPrecache:PrecacheUnit("npc_dota_hero_razor", nil, -1)         -- Ghost Revenant? & Sniper [prolly the NPC revenants too]
	-- --	XHSPrecache:PrecacheUnit("npc_dota_hero_silencer", nil, -1) 		-- Warden (PA) & Kobold (Meepo)
	-- XHSPrecache:PrecacheUnit("npc_dota_hero_slardar", nil, -1)       -- Slardar (Centurion) & wind & LK
	XHSPrecache:PrecacheUnit("npc_dota_hero_slark", nil, -1) -- Farm Event
	-- XHSPrecache:PrecacheUnit("npc_dota_hero_storm_spirit", nil, -1)  -- For Spirit Master.
	-- XHSPrecache:PrecacheUnit("npc_dota_hero_techies", nil, -1)       -- Shaman most likely
	XHSPrecache:PrecacheUnit("npc_dota_hero_templar_assassin", nil, -1) -- Final Wave
	-- --	XHSPrecache:PrecacheUnit("npc_dota_hero_tiny", nil, -1) 			-- For Mountain Giant
	XHSPrecache:PrecacheUnit("npc_dota_hero_tusk", nil, -1)          -- Farm Event
	-- --	XHSPrecache:PrecacheUnit("npc_dota_hero_treant", nil, -1) 		-- for Malfurion?
	XHSPrecache:PrecacheUnit("npc_dota_hero_vengefulspirit", nil, -1) -- For Incoming Wave 3. & Paladin
	XHSPrecache:PrecacheUnit("npc_dota_hero_weaver", nil, -1)        -- for creeps?
	-- XHSPrecache:PrecacheUnit("npc_dota_hero_wisp", nil, -1)        -- For Connecting bug
	-- XHSPrecache:PrecacheUnit("npc_dota_hero_zuus", nil, -1)        -- Muradin Bronzebeard

	XHSPrecache:PrecacheUnitSync("npc_spirit_beast_bis", context)
	XHSPrecache:PrecacheUnitSync("npc_frost_infernal_bis", context)
	-- Wave 6 starts immediately after the farm event and intentionally skips the
	-- normal 30-second staging job, so its unit must already be resident.
	XHSPrecache:PrecacheUnitSync("npc_dota_creature_chaos_knight_event_6", context)
	XHSPrecache:PrecacheUnitSync("npc_dota_creature_clockwerk_event_8", context)
	-- This custom creature equips the full Seismic Berserker set through
	-- AttachWearables. Dedicated servers need its unit definition resident
	-- synchronously or individual econ pieces can spawn missing/as ERROR models.
	XHSPrecache:PrecacheUnitSync("npc_magnataur_destroyer_crypt", context)
	-- The final-wave Huntress likewise equips Luna's complete vanilla set via
	-- AttachWearables. Precache the custom unit synchronously so every econ model
	-- is resident before the cinematic spawns several copies at once.
	XHSPrecache:PrecacheUnitSync("npc_luna_final_wave", context)
	-- Shal Lightbinder and Uther Lightbringer are map/VIP units whose complete
	-- econ sets are declared through AttachWearables. Keep both definitions and
	-- their wearable models resident before either campaign phase reveals them.
	XHSPrecache:PrecacheUnitSync("npc_xhs_paladin", context)   -- The Desert Gale
	XHSPrecache:PrecacheUnitSync("npc_xhs_paladin_2", context) -- The Grey Gallant
	-- The split Spirit Master units attach separate vanilla econ sets. Keep the
	-- complete definitions resident before the encounter so dedicated servers do
	-- not substitute ERROR models for individual cosmetic pieces.
	XHSPrecache:PrecacheUnitSync("npc_dota_boss_spirit_master_fire", context)
	XHSPrecache:PrecacheUnitSync("npc_dota_boss_spirit_master_storm", context)
	XHSPrecache:PrecacheUnitSync("npc_dota_boss_spirit_master_earth", context)

	XHSPrecache:PrecacheUnit("npc_dota_hero_grom_hellscream", nil, -1)
	XHSPrecache:PrecacheUnit("npc_dota_hero_illidan", nil, -1)
	XHSPrecache:PrecacheUnit("npc_dota_hero_balanar", nil, -1)
	XHSPrecache:PrecacheUnit("npc_dota_hero_proudmoore", nil, -1)
	XHSPrecache:PrecacheUnit("npc_dota_lich_king_sindragosa", nil, -1)

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
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_tinker.vsndevts", context) -- Archmage Elemental Wave

	PrecacheResource("soundfile", "soundevents/game_sounds_custom.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_dungeon.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_dungeon_enemies.vsndevts", context)

	-- Units Precache
	XHSPrecache:PrecacheUnit("npc_dota_lycan_wolf1", nil, -1)
	XHSPrecache:PrecacheUnit("npc_dota_shadowshaman_serpentward", nil, -1)
	XHSPrecache:PrecacheUnit("npc_dota_furbolg", nil, -1)
	XHSPrecache:PrecacheUnit("npc_dota_creature_muradin_bronzebeard", nil, -1)

	-- Final Wave
	XHSPrecache:PrecacheUnit("npc_xhs_hero_tombstone", nil, -1)

	-- The demo force-picks Mountain King as soon as its zero-duration setup
	-- finishes. Make the hero definition and all of its ability assets resident
	-- before that replacement can run instead of relying on the async hero loop.
	if GetMapName() == "x_hero_siege_demo" then
		XHSPrecache:PrecacheUnitSync("npc_dota_hero_sven", context)
	end

	for _, hero in pairs(HEROLIST) do
		-- local hero_folder_name = "models/heroes/" .. string.gsub(hero, "npc_dota_hero_", "") .. ".vmdl"
		-- print("Precaching folder: " .. hero_folder_name)
		-- PrecacheResource("model_folder", hero_folder_name, context)
		XHSPrecache:PrecacheUnit("npc_dota_hero_" .. hero, nil, -1)
	end

	for _, hero in pairs(HEROLIST_VIP) do
		-- local hero_folder_name = "models/heroes/" .. string.gsub(hero, "npc_dota_hero_", "") .. ".vmdl"
		-- print("Precaching folder: " .. hero_folder_name)
		-- PrecacheResource("model_folder", hero_folder_name, context)
		XHSPrecache:PrecacheUnit("npc_dota_hero_" .. hero, nil, -1)

		if hero == "npc_dota_hero_storm_spirit" then
			print("Also precache brothers!")
		end
	end

	-- Three spirits vip hero
	XHSPrecache:PrecacheUnit("npc_dota_hero_ember_spirit", nil, -1)
	XHSPrecache:PrecacheUnit("npc_dota_hero_earth_spirit", nil, -1)

	XHSPrecache:PrecacheBattlepassCompanionAssets(context)
end

function Precache(context)
	local ok, err = xpcall(function()
		XHSPrecacheImpl(context)
	end, XHSBootstrapTraceback)
	if not ok then
		XHSBootstrapLog("error", "precache failed\n" .. tostring(err))
		return
	end
end

-- Create the game mode when we activate
function Activate()
	local ok, err = xpcall(function()
		if type(GameMode) ~= "table" then
			error("GameMode class unavailable after bootstrap requires")
		end
		GameRules.GameMode = GameMode()
		GameRules.GameMode:InitGameMode()
	end, XHSBootstrapTraceback)
	if not ok then
		XHSBootstrapLog("error", "activate/InitGameMode failed\n" .. tostring(err))
		return
	end
end
