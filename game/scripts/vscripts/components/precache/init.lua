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

		if newHero ~= nil and not newHero:IsNull() then
			newHero.xhs_player_id = playerID
			-- Selection-display heroes use this flag and are deleted once every
			-- player has picked. A replacement must never inherit that identity.
			newHero.is_fake_hero = nil
		end

		if options.startingItems == true and oldHero ~= nil and newHero ~= nil then
			-- XHSPrecache owns old-hero cleanup. StartingItems used to schedule a
			-- second UTIL_Remove for the same handle, creating a race where a
			-- recycled Source 2 handle could delete the replacement at random.
			local previousDeferCleanup = options.deferOldHeroCleanup
			options.deferOldHeroCleanup = true
			StartingItems(oldHero, newHero, options)
			options.deferOldHeroCleanup = previousDeferCleanup
		end

		if options.cleanupOld ~= false and oldHero ~= nil and oldHero ~= newHero then
			local oldEntIndex = oldHero.entindex ~= nil and oldHero:entindex() or -1
			local newEntIndex = newHero ~= nil and not newHero:IsNull()
				and newHero.entindex ~= nil and newHero:entindex() or -1
			Timers:CreateTimer(options.cleanupDelay or 0.1, function()
				local assignedHero = PlayerResource:GetSelectedHeroEntity(playerID)
				local assignedEntIndex = assignedHero ~= nil
					and IsValidEntity(assignedHero)
					and not assignedHero:IsNull()
					and assignedHero.entindex ~= nil
					and assignedHero:entindex() or -1
				if oldEntIndex >= 0
					and oldEntIndex ~= newEntIndex
					and oldEntIndex ~= assignedEntIndex
					and oldHero ~= nil
					and IsValidEntity(oldHero)
					and not oldHero:IsNull()
					and oldHero.entindex ~= nil
					and oldHero:entindex() == oldEntIndex then
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

	-- Companion catalog entries are visual definitions, not instantiable entity
	-- classes. The runtime always creates this concrete base unit and applies the
	-- selected model, ambient particle and cosmetics afterward.
	self:PrecacheUnit("npc_donator_companion", callback, playerID)
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
	local units = {}
	local unitSet = {}

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

	for _, equipment in pairs(UNIT_EQUIPMENT or {}) do
		for _, wearable in pairs(equipment) do
			if type(wearable) == "string" then
				addUnique(models, modelSet, wearable)
			end
		end
	end

	for _, definitionsPath in ipairs({
		"scripts/npc/units/companions.txt",
		"scripts/npc/units/statues.txt",
	}) do
		local definitions = LoadKeyValues(definitionsPath) or {}
		for _, definition in pairs(definitions) do
			if type(definition) == "table" then
				addUnique(models, modelSet, definition.Model)
				addUnique(particles, particleSet, definition.AmbientParticle)
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
		"particles/econ/items/phantom_assassin/phantom_assassin_arcana_elder_smith/phantom_assassin_stifling_dagger_arcana.vpcf",
		"particles/econ/items/crystal_maiden/crystal_maiden_maiden_of_icewrack/maiden_arcana_base_ambient.vpcf",
	}

	for _, particle in pairs(cosmeticParticles) do
		addUnique(particles, particleSet, particle)
	end

	local rewardDefinitions = LoadKeyValues("scripts/vscripts/components/battlepass/keyvalues/items.txt") or {}
	for _, reward in pairs(rewardDefinitions) do
		if type(reward) == "table" and type(reward.visuals) == "table" then
			for _, visual in pairs(reward.visuals) do
				if type(visual) == "table" and visual.type == "particle" then
					addUnique(particles, particleSet, visual.modifier)
				end
			end
		end
	end

	local supporterManifest =
		LoadKeyValues("scripts/vscripts/components/battlepass/keyvalues/supporter_pass_2026.txt")
		or {}
	supporterManifest = supporterManifest.SupporterPass2026 or supporterManifest
	for _, anchor in ipairs({
		"particles/custom/supporter_pass/regen_aura_anchor.vpcf",
		"particles/custom/supporter_pass/attack_lifesteal_anchor.vpcf",
		"particles/custom/supporter_pass/spell_lifesteal_anchor.vpcf",
		"particles/custom/supporter_pass/immolation_owner_anchor.vpcf",
		"particles/custom/supporter_pass/immolation_target_anchor.vpcf",
		"particles/custom/supporter_pass/rebirth_anchor.vpcf",
		"particles/custom/supporter_pass/health_potion_anchor.vpcf",
		"particles/custom/supporter_pass/mana_potion_anchor.vpcf",
		"particles/custom/supporter_pass/light_potion_anchor.vpcf",
	}) do
		addUnique(particles, particleSet, anchor)
	end
	for _, reward in pairs(supporterManifest.catalog or {}) do
		if type(reward) == "table" then
			for _, field in ipairs({
				"start_pfx",
				"end_pfx",
				"pfx",
				"target_pfx",
				"caster_pfx",
				"health_pfx",
				"mana_pfx",
				"light_pfx",
				"owner_pfx",
				"overhead_pfx",
				"travel_pfx",
				"impact_pfx",
			}) do
				addUnique(particles, particleSet, reward[field])
			end
			if reward.item_type == "companion" or reward.item_type == "effigy" then
				addUnique(units, unitSet, reward.unit)
			end
		end
	end

	for _, model in pairs(models) do
		self:PrecacheResource("model", model, context)
	end

	for _, particle in pairs(particles) do
		self:PrecacheResource("particle", particle, context)
	end
	for _, unitName in pairs(units) do
		self:PrecacheUnitSync(unitName, context)
	end
end

function XHSPrecache:NoteRuntimeAsset(kind, path, source)
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
	if XHSObservability ~= nil then
		XHSObservability:Log("warning", "missing_" .. tostring(kind), "RUNTIME_ASSET_UNDECLARED", "Runtime asset was not declared in precache: " .. tostring(path), {
			kind = tostring(kind), path = tostring(path), call = tostring(source or "runtime"),
		})
	end
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
		"particles/units/heroes/hero_brewmaster/brewmaster_pulverize.vpcf",
		"particles/econ/items/juggernaut/ancient_exile/ancient_exile_healing_ward.vpcf",
		"particles/units/heroes/hero_juggernaut/juggernaut_healing_ward_eruption.vpcf",
		"particles/units/heroes/hero_juggernaut/juggernaut_healing_ward_variation02.vpcf",
		"particles/items_fx/blink_dagger_start.vpcf",
		"particles/items_fx/blink_dagger_end.vpcf",
		"particles/world_outpost/world_outpost_radiant_ambient.vpcf",
	},
	models = {
		"models/items/juggernaut/ward/ancient_exile_ward/ancient_exile_ward.vmdl",
		"models/props_structures/outpost.vmdl",
	},
	units = {
		"npc_dota_dungeon_checkpoint",
	},
	soundfiles = {
		"soundevents/game_sounds_custom.vsndevts",
		"soundevents/game_sounds_dungeon.vsndevts",
		"soundevents/game_sounds_dungeon_enemies.vsndevts",
	},
})

XHSPrecache:RegisterGroup("runes", {
	particles = {
		"particles/generic_gameplay/rune_arcane.vpcf",
		"particles/generic_gameplay/rune_bounty.vpcf",
		"particles/generic_gameplay/rune_doubledamage.vpcf",
		"particles/generic_gameplay/rune_haste.vpcf",
		"particles/generic_gameplay/rune_regeneration.vpcf",
		"particles/generic_gameplay/rune_shield.vpcf",
		"particles/generic_gameplay/rune_water.vpcf",
		"particles/generic_gameplay/rune_wisdom.vpcf",
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
		"particles/units/heroes/hero_zuus/zuus_arc_lightning.vpcf",
		"particles/units/heroes/hero_zuus/zuus_arc_lightning_head.vpcf",
		"particles/units/heroes/hero_razor_reduced_flash/razor_rain_storm_reduced_flash.vpcf",
		"particles/hero/ghost_revenant/ambient_effects.vpcf",
		"particles/econ/events/ti8/radiance_owner_ti8.vpcf",
		"particles/status_fx/status_effect_ghost_revenant.vpcf",
		"particles/econ/items/mirana/mirana_starstorm_bow/mirana_starstorm_starfall_attack.vpcf",
		"particles/units/heroes/hero_death_prophet/death_prophet_carrion_swarm.vpcf",
		"particles/units/heroes/hero_dreadlord/chaos_2_fly.vpcf",
		"particles/units/heroes/hero_dreadlord/chaos.vpcf",
		"particles/units/heroes/hero_medusa/medusa_mana_shield.vpcf",
		"particles/units/heroes/hero_medusa/medusa_mana_shield_impact.vpcf",
		"particles/custom/human/blood_mage/invoker_sun_strike_team_immortal2.vpcf",
		"particles/custom/human/blood_mage/exort_orb.vpcf",
		"particles/econ/items/crystal_maiden/crystal_maiden_maiden_of_icewrack/maiden_freezing_field_cracks_arcana.vpcf",
		"particles/econ/items/crystal_maiden/crystal_maiden_maiden_of_icewrack/maiden_freezing_field_darkcore_arcana1.vpcf",
		"particles/econ/items/crystal_maiden/crystal_maiden_maiden_of_icewrack/maiden_freezing_field_explosion_arcana1.vpcf",
		"particles/units/heroes/hero_ogre_magi/ogre_magi_bloodlust_cast.vpcf",
		"particles/units/heroes/hero_ogre_magi/ogre_magi_bloodlust_buff.vpcf",
		"particles/units/heroes/hero_luna/luna_lucent_beam_cast.vpcf",
		"particles/units/heroes/hero_luna/luna_lucent_beam.vpcf",
		"particles/units/heroes/hero_shadowshaman/shadowshaman_ether_shock.vpcf",
		"particles/items_fx/aura_endurance.vpcf",
		"particles/econ/courier/courier_faceless_rex/cour_rex_ground_a.vpcf",
		"particles/econ/courier/courier_roshan_frost/courier_roshan_frost_steam.vpcf",
	},
	models = {
		"models/heroes/doom/doom.vmdl",
	},
	units = {
		"npc_dota_doom_golem_1",
		"npc_dota_doom_golem_2",
		"npc_dota_doom_golem_3",
	},
	soundfiles = {
		"soundevents/game_sounds_heroes/game_sounds_zuus.vsndevts",
		"soundevents/game_sounds_heroes/game_sounds_medusa.vsndevts",
		"soundevents/game_sounds_heroes/game_sounds_ogre_magi.vsndevts",
	},
})

XHSPrecache:RegisterGroup("events", {
	particles = {
		"particles/act_2/campfire_flame.vpcf",
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
		"particles/boss_nevermore/screen_requiem_indicator.vpcf",
		"particles/units/heroes/hero_nevermore/nevermore_requiemofsouls_line.vpcf",
		"particles/custom/xhs_boss_warning_circle.vpcf",
		"particles/custom/boss_warnings/arthas/radius.vpcf",
		"particles/custom/boss_warnings/arthas/line.vpcf",
		"particles/custom/boss_warnings/arthas/target.vpcf",
		"particles/custom/boss_warnings/arthas/target_core.vpcf",
		"particles/custom/boss_warnings/arthas/release.vpcf",
		"particles/custom/boss_warnings/balanar/radius.vpcf",
		"particles/custom/boss_warnings/balanar/line.vpcf",
		"particles/custom/boss_warnings/balanar/target.vpcf",
		"particles/custom/boss_warnings/balanar/target_core.vpcf",
		"particles/custom/boss_warnings/balanar/release.vpcf",
		"particles/custom/boss_warnings/grom/radius.vpcf",
		"particles/custom/boss_warnings/grom/line.vpcf",
		"particles/custom/boss_warnings/grom/target.vpcf",
		"particles/custom/boss_warnings/grom/target_core.vpcf",
		"particles/custom/boss_warnings/grom/release.vpcf",
		"particles/custom/boss_warnings/illidan/radius.vpcf",
		"particles/custom/boss_warnings/illidan/line.vpcf",
		"particles/custom/boss_warnings/illidan/target.vpcf",
		"particles/custom/boss_warnings/illidan/target_core.vpcf",
		"particles/custom/boss_warnings/illidan/release.vpcf",
		"particles/custom/boss_warnings/lich_king/radius.vpcf",
		"particles/custom/boss_warnings/lich_king/line.vpcf",
		"particles/custom/boss_warnings/lich_king/target.vpcf",
		"particles/custom/boss_warnings/lich_king/target_core.vpcf",
		"particles/custom/boss_warnings/lich_king/release.vpcf",
		"particles/custom/boss_warnings/lich_king/impact.vpcf",
		"particles/custom/boss_warnings/magtheridon/radius.vpcf",
		"particles/custom/boss_warnings/magtheridon/line.vpcf",
		"particles/custom/boss_warnings/magtheridon/target.vpcf",
		"particles/custom/boss_warnings/magtheridon/target_core.vpcf",
		"particles/custom/boss_warnings/magtheridon/release.vpcf",
		"particles/custom/bosses/magtheridon/fel_radius_precast_green.vpcf",
		"particles/custom/bosses/magtheridon/infernal_ring_green.vpcf",
		"particles/custom/boss_warnings/proudmoore/radius.vpcf",
		"particles/custom/boss_warnings/proudmoore/line.vpcf",
		"particles/custom/boss_warnings/proudmoore/target.vpcf",
		"particles/custom/boss_warnings/proudmoore/target_core.vpcf",
		"particles/custom/boss_warnings/proudmoore/release.vpcf",
		"particles/custom/boss_warnings/special/radius.vpcf",
		"particles/custom/boss_warnings/special/line.vpcf",
		"particles/custom/boss_warnings/special/target.vpcf",
		"particles/custom/boss_warnings/special/target_core.vpcf",
		"particles/custom/boss_warnings/special/release.vpcf",
		"particles/custom/boss_warnings/spirit_master/radius.vpcf",
		"particles/custom/boss_warnings/spirit_master/line.vpcf",
		"particles/custom/boss_warnings/spirit_master/target.vpcf",
		"particles/custom/boss_warnings/spirit_master/target_core.vpcf",
		"particles/custom/boss_warnings/spirit_master/release.vpcf",
		"particles/custom/boss_warnings/spirit_storm/radius.vpcf",
		"particles/custom/boss_warnings/spirit_storm/line.vpcf",
		"particles/custom/boss_warnings/spirit_storm/target.vpcf",
		"particles/custom/boss_warnings/spirit_storm/target_core.vpcf",
		"particles/custom/boss_warnings/spirit_storm/release.vpcf",
		"particles/custom/boss_warnings/spirit_earth/radius.vpcf",
		"particles/custom/boss_warnings/spirit_earth/line.vpcf",
		"particles/custom/boss_warnings/spirit_earth/target.vpcf",
		"particles/custom/boss_warnings/spirit_earth/target_core.vpcf",
		"particles/custom/boss_warnings/spirit_earth/release.vpcf",
		"particles/custom/boss_warnings/spirit_fire/radius.vpcf",
		"particles/custom/boss_warnings/spirit_fire/line.vpcf",
		"particles/custom/boss_warnings/spirit_fire/target.vpcf",
		"particles/custom/boss_warnings/spirit_fire/target_core.vpcf",
		"particles/custom/boss_warnings/spirit_fire/release.vpcf",
		"particles/creatures/aghanim/aghanim_pulse_ambient.vpcf",
		"particles/units/heroes/hero_invoker/invoker_chaos_meteor_land_soil.vpcf",
		"particles/units/heroes/hero_invoker/invoker_chaos_meteor_crumble.vpcf",
		"particles/units/heroes/hero_templar_assassin/templar_assassin_trap_rings_inner.vpcf",
		"particles/units/heroes/hero_shadowshaman/shadow_shaman_dust_hit.vpcf",
		"particles/units/heroes/hero_centaur/centaur_warstomp.vpcf",
		"particles/units/heroes/hero_brewmaster/brewmaster_thunder_clap.vpcf",
		"particles/units/heroes/hero_brewmaster/brewmaster_thunder_clap_debuff.vpcf",
		"particles/units/heroes/heroes_underlord/abyssal_underlord_firestorm_wave.vpcf",
		"particles/units/heroes/heroes_underlord/underlord_firestorm_pre.vpcf",
		"particles/units/heroes/hero_elder_titan/elder_titan_earth_splitter.vpcf",
		"particles/units/heroes/heroes_underlord/underlord_pitofmalice.vpcf",
		"particles/units/heroes/heroes_underlord/underlord_pitofmalice_pre.vpcf",
		"particles/units/heroes/heroes_underlord/abyssal_underlord_pitofmalice_stun.vpcf",
		"particles/units/heroes/hero_lycan/lycan_howl_cast.vpcf",
		"particles/units/heroes/hero_earthshaker/earthshaker_fissure.vpcf",
		"particles/units/heroes/hero_abaddon/abaddon_curse_counter_stack.vpcf",
		"particles/units/heroes/hero_pugna/pugna_netherblast.vpcf",
		"particles/units/heroes/hero_bane/bane_nightmare.vpcf",
		"particles/units/heroes/hero_death_prophet/death_prophet_spirit_glow.vpcf",
		"particles/units/heroes/hero_death_prophet/death_prophet_carrion_swarm.vpcf",
		"particles/units/heroes/heroes_underlord/abyssal_underlord_portal_timer.vpcf",
		"particles/units/heroes/hero_invoker/invoker_chaos_meteor_fly.vpcf",
		"particles/hero/kunkka/torrent_splash.vpcf",
		"particles/econ/items/kunkka/kunkka_immortal/kunkka_immortal_ghost_ship_splash.vpcf",
		"particles/units/heroes/hero_tidehunter/tidehunter_anchor_hero.vpcf",
		"particles/econ/items/kunkka/kunkka_tidebringer_base/kunkka_spell_tidebringer.vpcf",
		"particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis_transform.vpcf",
		"particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis.vpcf",
		"particles/units/heroes/hero_phoenix/phoenix_supernova_reborn.vpcf",
		"particles/units/heroes/hero_lina/lina_spell_dragon_slave.vpcf",
		"particles/units/heroes/hero_lina/lina_spell_dragon_slave_impact.vpcf",
		"particles/units/heroes/hero_luna/luna_eclipse_cast.vpcf",
		"particles/econ/items/luna/luna_lucent_ti5/luna_eclipse_impact_moonfall.vpcf",
		"particles/units/heroes/hero_chaos_knight/chaos_knight_phantasm.vpcf",
		"particles/econ/items/faceless_void/faceless_void_weapon_bfury/faceless_void_weapon_bfury_cleave.vpcf",
		"particles/units/heroes/hero_juggernaut/juggernaut_blade_fury.vpcf",
		"particles/units/heroes/hero_juggernaut/juggernaut_blade_fury_null.vpcf",
		"particles/units/heroes/hero_juggernaut/juggernaut_blade_fury_tgt.vpcf",
		"particles/units/heroes/hero_ursa/ursa_earthshock.vpcf",
		"particles/units/heroes/hero_lich/lich_frost_nova.vpcf",
		"particles/units/heroes/hero_crystalmaiden/maiden_frostbite_buff.vpcf",
		"particles/units/heroes/hero_crystalmaiden/maiden_freezing_field_caster.vpcf",
		"particles/units/heroes/hero_crystalmaiden/maiden_freezing_field_explosion.vpcf",
		"particles/units/heroes/hero_omniknight/omniknight_purification.vpcf",
		"particles/units/heroes/hero_abaddon/abaddon_death_coil_explosion.vpcf",
		"particles/econ/items/crystal_maiden/crystal_maiden_cowl_of_ice/maiden_crystal_nova_cowlofice.vpcf",
		"particles/units/heroes/hero_abaddon/abaddon_aphotic_shield_explosion.vpcf",
		"particles/items_fx/blademail.vpcf",
		"particles/units/heroes/hero_centaur/centaur_return.vpcf",
		"particles/units/heroes/hero_abaddon/abaddon_borrowed_time_heal.vpcf",
		"particles/units/heroes/hero_winter_wyvern/wyvern_splinter_blast.vpcf",
		"particles/units/heroes/hero_winter_wyvern/wyvern_ambient_dryice_soft.vpcf",
		"particles/units/heroes/hero_nevermore/nevermore_requiemofsouls.vpcf",
		"particles/units/heroes/hero_sven/sven_spell_storm_bolt.vpcf",
		"particles/units/heroes/hero_skeletonking/skeletonking_hellfireblast_explosion.vpcf",
		"particles/units/heroes/hero_brewmaster/brewmaster_primal_split.vpcf",
		"particles/units/heroes/hero_stormspirit/stormspirit_overload_discharge.vpcf",
		"particles/units/heroes/hero_stormspirit/stormspirit_static_remnant.vpcf",
		"particles/units/heroes/hero_earth_spirit/espirit_bouldersmash_caster.vpcf",
		"particles/units/heroes/hero_earth_spirit/espirit_stoneremnant.vpcf",
		"particles/units/heroes/hero_lina/lina_spell_light_strike_array.vpcf",
		"particles/units/heroes/hero_invoker/invoker_sun_strike_team.vpcf",
		"particles/econ/items/invoker/invoker_apex/invoker_sun_strike_immortal1.vpcf",
		"particles/units/heroes/hero_phoenix/phoenix_fire_spirit_ground.vpcf",
		"particles/items_fx/aura_shivas.vpcf",
	},
	models = {
		"models/heroes/terrorblade/demon.vmdl",
	},
	soundfiles = {
		"soundevents/game_sounds_heroes/game_sounds_abaddon.vsndevts",
		"soundevents/game_sounds_heroes/game_sounds_abyssal_underlord.vsndevts",
		"soundevents/game_sounds_heroes/game_sounds_bane.vsndevts",
		"soundevents/game_sounds_heroes/game_sounds_brewmaster.vsndevts",
		"soundevents/game_sounds_heroes/game_sounds_centaur.vsndevts",
		"soundevents/game_sounds_heroes/game_sounds_chaos_knight.vsndevts",
		"soundevents/game_sounds_heroes/game_sounds_crystalmaiden.vsndevts",
		"soundevents/game_sounds_heroes/game_sounds_death_prophet.vsndevts",
		"soundevents/game_sounds_heroes/game_sounds_earth_spirit.vsndevts",
		"soundevents/game_sounds_heroes/game_sounds_earthshaker.vsndevts",
		"soundevents/game_sounds_heroes/game_sounds_elder_titan.vsndevts",
		"soundevents/game_sounds_heroes/game_sounds_ember_spirit.vsndevts",
		"soundevents/game_sounds_heroes/game_sounds_invoker.vsndevts",
		"soundevents/game_sounds_heroes/game_sounds_juggernaut.vsndevts",
		"soundevents/game_sounds_heroes/game_sounds_kunkka.vsndevts",
		"soundevents/game_sounds_heroes/game_sounds_lich.vsndevts",
		"soundevents/game_sounds_heroes/game_sounds_lina.vsndevts",
		"soundevents/game_sounds_heroes/game_sounds_luna.vsndevts",
		"soundevents/game_sounds_heroes/game_sounds_lycan.vsndevts",
		"soundevents/game_sounds_heroes/game_sounds_nevermore.vsndevts",
		"soundevents/game_sounds_heroes/game_sounds_nightstalker.vsndevts",
		"soundevents/game_sounds_heroes/game_sounds_phoenix.vsndevts",
		"soundevents/game_sounds_heroes/game_sounds_pugna.vsndevts",
		"soundevents/game_sounds_heroes/game_sounds_stormspirit.vsndevts",
		"soundevents/game_sounds_heroes/game_sounds_sven.vsndevts",
		"soundevents/game_sounds_heroes/game_sounds_skeletonking.vsndevts",
		"soundevents/game_sounds_heroes/game_sounds_terrorblade.vsndevts",
		"soundevents/game_sounds_heroes/game_sounds_tidehunter.vsndevts",
		"soundevents/game_sounds_heroes/game_sounds_winter_wyvern.vsndevts",
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
		"npc_xhs_uther_ice_prison",
		"npc_dota_hero_magtheridon",
		"npc_dota_hero_arthas",
		"npc_dota_hero_banehallow",
		"npc_dota_boss_spirit_master",
		"npc_dota_hero_secret",
	},
})

XHSPrecache:RegisterGroup("waves", {
	particles = {
		"particles/units/heroes/hero_pudge/pudge_rot.vpcf",
		"particles/units/heroes/hero_pudge/pudge_rot_recipient.vpcf",
		"particles/items_fx/abyssal_blade_crimson_impact_sparks.vpcf",
		"particles/generic_gameplay/generic_silenced.vpcf",
		"particles/darkmoon_last_hit_effect.vpcf",
		"particles/units/heroes/hero_jakiro/jakiro_base_attack.vpcf",
		"particles/units/heroes/hero_ancient_apparition/ancient_apparition_base_attack.vpcf",
		"particles/units/heroes/hero_lion/lion_base_attack.vpcf",
		"particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis_base_attack.vpcf",
		"particles/units/heroes/hero_necrolyte/necrolyte_base_attack.vpcf",
		"particles/units/heroes/hero_luna/luna_moon_glaive_bounce.vpcf",
		"particles/units/heroes/hero_spirit_breaker/spirit_breaker_charge.vpcf",
		"particles/econ/items/necrolyte/necronub_base_attack/necrolyte_base_attack_ka.vpcf",
	},
	models = {
		"models/creeps/neutral_creeps/n_creep_troll_skeleton/n_creep_troll_skeleton_fx.vmdl",
		"models/gameplay/breakingcrate_dest.vmdl",
		"models/creeps/lane_creeps/creep_bad_melee_diretide/creep_bad_melee_diretide.vmdl",
		"models/creeps/neutral_creeps/n_creep_ghost_b/n_creep_ghost_red.vmdl",
		"models/creeps/neutral_creeps/n_creep_forest_trolls/n_creep_forest_troll_high_priest.vmdl",
		"models/creeps/neutral_creeps/n_creep_harpy_b/n_creep_harpy_b.vmdl",
		"models/creeps/lane_creeps/creep_radiant_ranged/radiant_ranged_mega.vmdl",
		"models/creeps/lane_creeps/creep_bad_ranged/lane_dire_ranged.vmdl",
		"models/creeps/neutral_creeps/n_creep_troll_dark_a/n_creep_troll_dark_a.vmdl",
		"models/creeps/lane_creeps/creep_bird_radiant/creep_bird_radiant_ranged.vmdl",
		"models/creeps/lane_creeps/creep_bird_radiant/creep_bird_radiant_ranged_mega.vmdl",
		"models/creeps/lane_creeps/creep_dc_radiant/creep_dc_radiant_ranged.vmdl",
		"models/creeps/lane_creeps/creep_dc_radiant/creep_dc_radiant_ranged_mega.vmdl",
		"models/items/lone_druid/true_form/form_of_the_atniw/form_of_the_atniw.vmdl",
		"models/items/warlock/golem/mystery_of_the_lost_ores_golem/mystery_of_the_lost_ores_golem.vmdl",
		"models/items/warlock/golem/obsidian_golem/obsidian_golem.vmdl",
		"models/heroes/pudge/pudge.vmdl",
		"models/heroes/lycan/lycan.vmdl",
		"models/heroes/witchdoctor/witchdoctor_ward.vmdl",
	},
	units = {
		"npc_abomination_final_wave",
		"npc_dota_lycan_wolf1",
		"npc_dota_shadowshaman_serpentward",
		"npc_dota_furbolg",
	},
	soundfiles = {
		"soundevents/game_sounds_heroes/game_sounds_silencer.vsndevts",
	},
})

XHSPrecache:RegisterGroup("items_lua", {
	particles = {
		"particles/items3_fx/fish_bones_active.vpcf",
		"particles/items3_fx/mango_active.vpcf",
		"particles/items_fx/aegis_respawn.vpcf",
		"particles/items_fx/aegis_respawn_timer.vpcf",
		"particles/units/heroes/hero_undying/undying_tombstone.vpcf",
		"particles/econ/items/undying/fall20_undying_head/fall20_undying_tombstone_ambient.vpcf",
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
		"item_plagueheart",
		"item_astral_core",
		"item_tempest_aegis",
		"item_orb_of_earth2",
		"item_bracer_of_the_void",
		"item_celestial_claws",
		"item_searing_blade",
		"item_lifesteal_mask",
		"item_boots_of_speed",
		"item_xhs_cloak_of_flames",
		"item_amulet_of_the_wild",
		"item_viridian_gem",
		"item_mystic_gem",
		"item_zephyr_gem",
		"item_orb_of_earth3",
		"item_orb_of_darkness2",
		"item_orb_of_fire2",
		"item_orb_of_lightning2",
		"item_xhs_orb_of_venom",
		"item_orb_of_arcane",
		"item_orb_of_earth",
		"item_orb_of_darkness",
		"item_orb_of_fire",
		"item_orb_of_lightning",
		"item_tome_of_power",
		"item_tome_small",
		"item_ankh_of_reincarnation",
		"item_tome_big",
		"item_potion_full",
		"item_potion_of_invulnerability",
		"item_potion_of_antimagic",
		"item_healing_wards2",
		"item_health_potion",
		"item_healing_wards",
		"item_mana_potion",
	},
})

XHSPrecache:RegisterGroup("supporter_pass", {
	particles = {
		"particles/units/heroes/hero_abaddon/holdout_borrowed_time.vpcf",
		"particles/units/heroes/hero_abaddon/holdout_borrowed_time_2.vpcf",
		"particles/units/heroes/hero_abaddon/holdout_borrowed_time_3.vpcf",
		"particles/units/heroes/hero_abaddon/holdout_borrowed_time_4.vpcf",
		"particles/units/heroes/hero_abaddon/holdout_borrowed_time_purple.vpcf",
		"particles/econ/events/seasonal_reward_line_fall_2025/teleport_start_fallrewardline_2025.vpcf",
		"particles/econ/events/seasonal_reward_line_fall_2025/teleport_end_fallrewardline_2025.vpcf",
		"particles/econ/events/seasonal_reward_line_spring_2026/teleport_start_springrewardline_2026.vpcf",
		"particles/econ/events/seasonal_reward_line_spring_2026/teleport_end_springrewardline_2026.vpcf",
		"particles/econ/events/seasonal_reward_line_winter_2025/teleport_start_winterrewardline_2025.vpcf",
		"particles/econ/events/seasonal_reward_line_winter_2025/teleport_end_winterrewardline_2025.vpcf",
		"particles/econ/events/seasonal_reward_line_summer_2026/teleport_start_summerrewardline_2026.vpcf",
		"particles/econ/events/seasonal_reward_line_summer_2026/teleport_end_summerrewardline_2026.vpcf",
	},
})

return XHSPrecache
