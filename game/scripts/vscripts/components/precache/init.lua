if XHSPrecache == nil then
	_G.XHSPrecache = {}
end

XHSPrecache.groups = XHSPrecache.groups or {}
XHSPrecache.precachedAssets = XHSPrecache.precachedAssets or {}
XHSPrecache.precachedUnits = XHSPrecache.precachedUnits or {}
XHSPrecache.pendingUnits = XHSPrecache.pendingUnits or {}
XHSPrecache.runtimeAssets = XHSPrecache.runtimeAssets or {}
XHSPrecache.runtimeAssetSet = XHSPrecache.runtimeAssetSet or {}
XHSPrecache.replaceInProgress = XHSPrecache.replaceInProgress or false

local function normalizeAssetList(assets)
	assets = assets or {}
	return {
		particle = assets.particle or assets.particles or {},
		particle_folder = assets.particle_folder or assets.particle_folders or {},
		model = assets.model or assets.models or {},
		model_folder = assets.model_folder or assets.model_folders or {},
		soundfile = assets.soundfile or assets.soundfiles or {},
		unit = assets.unit or assets.units or {},
		item = assets.item or assets.items or {},
	}
end

local function unitCacheKey(unitName, playerID)
	return tostring(unitName) .. "::" .. tostring(playerID or -1)
end

local function addUnique(list, set, value)
	if value == nil or value == "" then return end
	if set[value] then return end
	set[value] = true
	table.insert(list, value)
end

function XHSPrecache:RegisterGroup(groupName, assets)
	if groupName == nil then return end
	self.groups[groupName] = normalizeAssetList(assets)
end

function XHSPrecache:IsAssetDeclared(kind, path)
	local key = tostring(kind) .. ":" .. tostring(path)
	return self.precachedAssets[key] == true
end

function XHSPrecache:PrecacheResource(kind, path, context)
	if kind == nil or path == nil or path == "" then return end

	local key = tostring(kind) .. ":" .. tostring(path)
	if self.precachedAssets[key] then return end
	self.precachedAssets[key] = true

	if context ~= nil and PrecacheResource ~= nil then
		PrecacheResource(kind, path, context)
	end
end

function XHSPrecache:PrecacheItem(itemName, context)
	if itemName == nil or itemName == "" then return end
	local key = "item:" .. tostring(itemName)
	if self.precachedAssets[key] then return end
	self.precachedAssets[key] = true

	if context ~= nil and PrecacheItemByNameSync ~= nil then
		PrecacheItemByNameSync(itemName, context)
	end
end

function XHSPrecache:PrecacheUnit(unitName, callback, playerID)
	if unitName == nil or unitName == "" then
		if callback then callback(nil) end
		return
	end

	local cacheKey = unitCacheKey(unitName, playerID)

	if self.precachedUnits[cacheKey] then
		if callback then callback(self.precachedUnits[cacheKey]) end
		return
	end

	if self.pendingUnits[cacheKey] then
		if callback then
			table.insert(self.pendingUnits[cacheKey], callback)
		end
		return
	end

	self.pendingUnits[cacheKey] = {}
	if callback then
		table.insert(self.pendingUnits[cacheKey], callback)
	end

	PrecacheUnitByNameAsync(unitName, function(spawnGroup)
		self.precachedUnits[cacheKey] = spawnGroup or true
		local callbacks = self.pendingUnits[cacheKey] or {}
		self.pendingUnits[cacheKey] = nil

		for _, queuedCallback in pairs(callbacks) do
			if queuedCallback then
				queuedCallback(spawnGroup)
			end
		end
	end, playerID or -1)
end

function XHSPrecache:PrecacheUnitSync(unitName, context)
	if unitName == nil or unitName == "" then return end
	local cacheKey = unitCacheKey(unitName, -1)
	if self.precachedUnits[cacheKey] then return end

	if context ~= nil and PrecacheUnitByNameSync ~= nil then
		self.precachedUnits[cacheKey] = PrecacheUnitByNameSync(unitName, context) or true
	end
end

function XHSPrecache:Run(context)
	for _, assets in pairs(self.groups) do
		for kind, list in pairs(assets) do
			if kind == "unit" then
				for _, unitName in pairs(list) do
					self:PrecacheUnit(unitName, nil, -1)
				end
			elseif kind == "item" then
				for _, itemName in pairs(list) do
					self:PrecacheItem(itemName, context)
				end
			else
				for _, path in pairs(list) do
					self:PrecacheResource(kind, path, context)
				end
			end
		end
	end
end

function XHSPrecache:ReplaceHeroWith(playerID, heroName, gold, xp, oldHero, options, callback)
	options = options or {}

	self:PrecacheUnit(heroName, function()
		self.replaceInProgress = true
		local newHero = PlayerResource:ReplaceHeroWith(playerID, heroName, gold or 0, xp or 0)
		self.replaceInProgress = false

		if options.startingItems == true and oldHero ~= nil and newHero ~= nil then
			StartingItems(oldHero, newHero)
		end

		if options.cleanupOld ~= false and oldHero ~= nil then
			Timers:CreateTimer(options.cleanupDelay or 0.1, function()
				if oldHero ~= nil and IsValidEntity(oldHero) and not oldHero:IsNull() then
					UTIL_Remove(oldHero)
				end
			end)
		end

		if callback then
			callback(newHero)
		end
	end, playerID)
end

function XHSPrecache:CreateUnitByName(unitName, origin, findClearSpace, owner, unitOwner, team, callback, playerID)
	self:PrecacheUnit(unitName, function()
		local unit = CreateUnitByName(unitName, origin, findClearSpace, owner, unitOwner, team)
		if callback then
			callback(unit)
		end
	end, playerID or -1)
end

function XHSPrecache:PrecacheCompanion(unitName, callback, playerID)
	if unitName == nil or unitName == "" or unitName == false then
		unitName = "npc_donator_companion_demi_doom"
	end

	self:PrecacheUnit(unitName, callback, playerID)
end

function XHSPrecache:PrecacheBattlepassCompanionAssets(context)
	local ok, err = pcall(require, "components/battlepass/constants")
	if not ok and IsInToolsMode() then
		print("[XHSPrecache] Failed to load battlepass constants: " .. tostring(err))
	end

	local models = {}
	local modelSet = {}
	local particles = {}
	local particleSet = {}

	local roshanModels = {
		"models/courier/baby_rosh/babyroshan_elemental.vmdl",
		"models/courier/baby_rosh/babyroshan_winter18.vmdl",
		"models/courier/baby_rosh/babyroshan_ti9.vmdl",
	}

	local roshanParticles = {
		"particles/econ/courier/courier_donkey_ti7/courier_donkey_ti7_ambient.vpcf",
		"particles/econ/courier/courier_golden_roshan/golden_roshan_ambient.vpcf",
		"particles/econ/courier/courier_platinum_roshan/platinum_roshan_ambient.vpcf",
		"particles/econ/courier/courier_roshan_darkmoon/courier_roshan_darkmoon.vpcf",
		"particles/econ/courier/courier_roshan_desert_sands/baby_roshan_desert_sands_ambient.vpcf",
		"particles/econ/courier/courier_roshan_ti8/courier_roshan_ti8.vpcf",
		"particles/econ/courier/courier_roshan_lava/courier_roshan_lava.vpcf",
		"particles/econ/courier/courier_roshan_frost/courier_roshan_frost_ambient.vpcf",
		"particles/econ/courier/courier_babyroshan_winter18/courier_babyroshan_winter18_ambient.vpcf",
		"particles/econ/courier/courier_babyroshan_ti9/courier_babyroshan_ti9_ambient.vpcf",
	}

	for _, model in pairs(roshanModels) do
		addUnique(models, modelSet, model)
	end

	for _, particle in pairs(roshanParticles) do
		addUnique(particles, particleSet, particle)
	end

	for _, info in pairs(DONATOR_COMPANION_ADDITIONAL_INFO or {}) do
		addUnique(particles, particleSet, info[1])
	end

	for _, equipment in pairs(UNIT_EQUIPMENT or {}) do
		for _, wearable in pairs(equipment) do
			if type(wearable) == "string" then
				addUnique(models, modelSet, wearable)
			end
		end
	end

	local cosmeticParticles = {
		"particles/econ/items/pudge/pudge_scorching_talon/pudge_scorching_talon_ambient.vpcf",
		"particles/econ/items/pudge/pudge_arcana/pudge_arcana_back_ambient.vpcf",
		"particles/econ/items/pudge/pudge_arcana/pudge_arcana_back_ambient_beam.vpcf",
		"particles/econ/items/pudge/pudge_arcana/pudge_arcana_ambient_flies.vpcf",
		"particles/econ/items/rubick/rubick_arcana/rubick_arc_ambient_default.vpcf",
		"particles/econ/items/juggernaut/jugg_ti8_sword/jugg_ti8_crimson_sword_ambient.vpcf",
		"particles/econ/items/phantom_assassin/phantom_assassin_arcana_elder_smith/pa_arcana_blade_ambient_a.vpcf",
		"particles/econ/items/phantom_assassin/phantom_assassin_arcana_elder_smith/pa_arcana_blade_ambient_b.vpcf",
		"particles/econ/items/phantom_assassin/phantom_assassin_arcana_elder_smith/pa_arcana_elder_ambient.vpcf",
		"particles/econ/items/phantom_assassin/phantom_assassin_arcana_elder_smith/pa_arcana_elder_eyes_l.vpcf",
		"particles/econ/items/phantom_assassin/phantom_assassin_arcana_elder_smith/pa_arcana_elder_eyes_r.vpcf",
	}

	for _, particle in pairs(cosmeticParticles) do
		addUnique(particles, particleSet, particle)
	end

	for _, model in pairs(models) do
		self:PrecacheResource("model", model, context)
	end

	for _, particle in pairs(particles) do
		self:PrecacheResource("particle", particle, context)
	end
end

function XHSPrecache:NoteRuntimeAsset(kind, path, source)
	if not IsInToolsMode() then return end
	if kind == nil or path == nil or path == "" then return end
	if self:IsAssetDeclared(kind, path) then return end

	local key = tostring(kind) .. ":" .. tostring(path)
	if self.runtimeAssetSet[key] then return end

	self.runtimeAssetSet[key] = true
	table.insert(self.runtimeAssets, {
		kind = kind,
		path = path,
		source = source or "runtime",
	})
end

function XHSPrecache:PrintReport()
	print("[XHSPrecache] ===== Precache Report =====")
	print("[XHSPrecache] Groups:")
	for groupName, assets in pairs(self.groups) do
		local count = 0
		for _, list in pairs(assets) do
			count = count + #list
		end
		print("[XHSPrecache]  - " .. tostring(groupName) .. ": " .. tostring(count) .. " entries")
	end

	print("[XHSPrecache] Units precached:")
	for key in pairs(self.precachedUnits) do
		print("[XHSPrecache]  - " .. tostring(key))
	end

	if #self.runtimeAssets > 0 then
		print("[XHSPrecache] Runtime assets not declared:")
		for _, asset in pairs(self.runtimeAssets) do
			print("[XHSPrecache]  - " .. tostring(asset.kind) .. " " .. tostring(asset.path) .. " (" .. tostring(asset.source) .. ")")
		end
	else
		print("[XHSPrecache] No undeclared runtime assets recorded.")
	end
end

XHSPrecache:RegisterGroup("core", {
	particles = {
		"particles/items2_fx/teleport_start.vpcf",
		"particles/items2_fx/teleport_end.vpcf",
		"particles/econ/events/fall_major_2016/teleport_start_fm06_lvl3.vpcf",
		"particles/econ/events/fall_major_2016/teleport_end_fm06_lvl3.vpcf",
		"particles/generic_hero_status/hero_levelup.vpcf",
		"particles/generic_gameplay/generic_lifesteal.vpcf",
		"particles/items_fx/blink_dagger_start.vpcf",
		"particles/items_fx/blink_dagger_end.vpcf",
	},
	soundfiles = {
		"soundevents/game_sounds_custom.vsndevts",
		"soundevents/game_sounds_dungeon.vsndevts",
		"soundevents/game_sounds_dungeon_enemies.vsndevts",
	},
})

XHSPrecache:RegisterGroup("runes", {
	particles = {
		"particles/generic_gameplay/rune_bounty_owner.vpcf",
		"particles/generic_hero_status/hero_levelup.vpcf",
		"particles/units/heroes/hero_zuus/zuus_arc_lightning.vpcf",
		"particles/units/heroes/hero_stormspirit/stormspirit_overload_ambient.vpcf",
	},
	models = {
		"models/custom_game/runes/xhs_rune_recovery.vmdl",
		"models/custom_game/runes/xhs_rune_defense.vmdl",
		"models/custom_game/runes/xhs_rune_offense.vmdl",
		"models/custom_game/runes/xhs_rune_misc.vmdl",
	},
	units = {
		"dummy_unit_invulnerable",
	},
})

XHSPrecache:RegisterGroup("hero_abilities", {
	particles = {
		"particles/units/heroes/hero_razor_reduced_flash/razor_rain_storm_reduced_flash.vpcf",
		"particles/econ/items/mirana/mirana_starstorm_bow/mirana_starstorm_starfall_attack.vpcf",
	},
})

XHSPrecache:RegisterGroup("events", {
	particles = {
		"particles/custom/xhs_special_wave_timer_segment.vpcf",
		"particles/custom/xhs_growth_overhead.vpcf",
		"particles/units/heroes/hero_morphling/morphling_ambient_new.vpcf",
		"particles/units/heroes/hero_ogre_magi/ogre_magi_ignite_debuff.vpcf",
		"particles/units/heroes/hero_morphling/morphling_morph_agi.vpcf",
		"particles/econ/courier/courier_greevil_red/courier_greevil_red_ambient_3.vpcf",
		"particles/units/heroes/hero_doom_bringer/doom_bringer_doom_ring.vpcf",
	},
	models = {
		"models/props_items/blinkdagger.vmdl",
		"models/props_items/poor_man_shield01.vmdl",
		"models/props_items/ring_health.vmdl",
		"models/props_items/staff_wizardry01.vmdl",
	},
	units = {
		"npc_spirit_beast",
		"npc_spirit_beast_bis",
		"npc_frost_infernal",
		"npc_frost_infernal_bis",
		"npc_dota_creature_muradin_bronzebeard",
		"npc_ramero",
		"npc_ramero_2",
		"npc_baristol",
	},
})

XHSPrecache:RegisterGroup("bosses", {
	particles = {
		"particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_shadowraze.vpcf",
		"particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_ambient.vpcf",
		"particles/boss_nevermore/nevermore_shoulder_ambient.vpcf",
		"particles/units/heroes/hero_nevermore/nevermore_trail.vpcf",
		"particles/boss_nevermore/pre_raze.vpcf",
		"particles/boss_nevermore/raze_blast.vpcf",
		"particles/boss_nevermore/meteorain_pre.vpcf",
		"particles/boss_nevermore/meteorain.vpcf",
		"particles/boss_nevermore/immolation_warning.vpcf",
		"particles/boss_nevermore/ragna_blade_pre_warning.vpcf",
		"particles/boss_nevermore/ragna_blade.vpcf",
		"particles/units/heroes/hero_nevermore/nevermore_requiemofsouls_line.vpcf",
		"particles/custom/xhs_boss_warning_circle.vpcf",
		"particles/events/darkmoon_generic_aoe_green.vpcf",
		"particles/econ/events/darkmoon_2017/darkmoon_generic_aoe.vpcf",
		"particles/units/heroes/hero_invoker/invoker_chaos_meteor_land_soil.vpcf",
		"particles/units/heroes/hero_invoker/invoker_chaos_meteor_crumble.vpcf",
		"particles/units/heroes/hero_templar_assassin/templar_assassin_trap_rings_inner.vpcf",
		"particles/units/heroes/hero_shadowshaman/shadow_shaman_dust_hit.vpcf",
		"particles/units/heroes/hero_brewmaster/brewmaster_thunder_clap.vpcf",
		"particles/units/heroes/hero_brewmaster/brewmaster_thunder_clap_debuff.vpcf",
		"particles/units/heroes/hero_lycan/lycan_howl_cast.vpcf",
		"particles/items_fx/aura_shivas.vpcf",
	},
	model_folders = {
		"models/heroes/skeleton_king",
		"models/items/warlock/archivist_golem",
		"models/creeps/ice_biome/storegga",
		"models/items/chaos_knight/ck_esp_blade",
		"models/items/chaos_knight/ck_esp_helm",
		"models/items/chaos_knight/ck_esp_mount",
		"models/items/chaos_knight/ck_esp_shield",
		"models/items/chaos_knight/ck_esp_shoulder",
		"models/items/furion/treant/the_ancient_guardian_the_ancient_treants",
		"models/items/dragon_knight/aurora_warrior_set_dragon_style2_aurora_warrior_set",
		"models/heroes/dragon_knight",
		"models/heroes/juggernaut",
		"models/items/undying/idol_of_ruination",
	},
	units = {
		"npc_dota_hero_grom_hellscream",
		"npc_dota_hero_illidan",
		"npc_dota_hero_balanar",
		"npc_dota_hero_proudmoore",
		"npc_dota_hero_magtheridon",
		"npc_dota_hero_arthas",
		"npc_dota_hero_banehallow",
		"npc_dota_boss_spirit_master",
		"npc_dota_hero_secret",
	},
})

XHSPrecache:RegisterGroup("waves", {
	particles = {
		"particles/custom/undead/disease_cloud.vpcf",
		"particles/darkmoon_last_hit_effect.vpcf",
		"particles/units/heroes/hero_jakiro/jakiro_base_attack.vpcf",
		"particles/units/heroes/hero_ancient_apparition/ancient_apparition_base_attack.vpcf",
		"particles/units/heroes/hero_lion/lion_base_attack.vpcf",
		"particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis_base_attack.vpcf",
	},
	models = {
		"models/creeps/neutral_creeps/n_creep_troll_skeleton/n_creep_troll_skeleton_fx.vmdl",
		"models/gameplay/breakingcrate_dest.vmdl",
		"models/creeps/lane_creeps/creep_bad_melee_diretide/creep_bad_melee_diretide.vmdl",
		"models/items/warlock/golem/mystery_of_the_lost_ores_golem/mystery_of_the_lost_ores_golem.vmdl",
		"models/items/warlock/golem/obsidian_golem/obsidian_golem.vmdl",
		"models/heroes/lycan/lycan.vmdl",
		"models/heroes/witchdoctor/witchdoctor_ward.vmdl",
	},
	units = {
		"npc_dota_lycan_wolf1",
		"npc_dota_shadowshaman_serpentward",
		"npc_dota_furbolg",
	},
})

XHSPrecache:RegisterGroup("items_lua", {
	particles = {
		"particles/items3_fx/fish_bones_active.vpcf",
		"particles/items3_fx/mango_active.vpcf",
		"particles/items_fx/aegis_respawn.vpcf",
		"particles/items_fx/aegis_respawn_timer.vpcf",
		"particles/units/heroes/hero_ember_spirit/ember_spirit_flameguard.vpcf",
		"particles/units/heroes/hero_ursa/ursa_earthshock.vpcf",
		"particles/units/heroes/hero_invoker/invoker_sun_strike_team.vpcf",
	},
	soundfiles = {
		"soundevents/game_sounds_items.vsndevts",
		"soundevents/game_sounds_heroes/game_sounds_ursa.vsndevts",
		"soundevents/game_sounds_heroes/game_sounds_juggernaut.vsndevts",
		"soundevents/game_sounds_heroes/game_sounds_invoker.vsndevts",
	},
	items = {
		"item_tombstone",
	},
})

XHSPrecache:RegisterGroup("supporter_pass", {
	particles = {
		"particles/custom/xhs_supporter_wisp_ambient.vpcf",
	},
})

return XHSPrecache
