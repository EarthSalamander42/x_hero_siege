if XHSBotItemCatalog == nil then
	XHSBotItemCatalog = {}
end

-- Semantic data lives here; prices and recipe names mirror the authoritative
-- KV files and are verified by scripts/verify_xhs_bot_economy.js.
local ITEMS = {
	item_health_potion = {
		cost = 150, shop = "home", kind = "consumable", consumable = "health",
		purchasable = true, charges = 15, stackable = true,
		active_slot = true, requires_active_slot = true, backpack_usable = false,
		cooldown = 1, script_file = "items/item_health_potion",
		tags = { sustain = 1.0 },
		behavior = "instant_no_target", stacking = "charges",
		stats = { hp_restore = 3000 },
	},
	item_mana_potion = {
		cost = 100, shop = "home", kind = "consumable", consumable = "mana",
		purchasable = true, charges = 15, stackable = true,
		active_slot = true, requires_active_slot = true, backpack_usable = false,
		cooldown = 1, script_file = "items/item_mana_potion",
		tags = { mana = 1.0 },
		behavior = "instant_no_target", stacking = "charges",
		stats = { mana_restore = 3000 },
	},
	item_ankh_of_reincarnation = {
		cost = 1500, shop = "home", kind = "revive", purchasable = true,
		charges = 1, stackable = true, active_slot = true,
		requires_active_slot = true, backpack_usable = false, no_backpack = true,
		script_file = "items/ankh_of_reincarnation.lua",
		tags = { survival = 1.0, revive = 1.0 },
		behavior = "passive_on_equip", stacking = "modifier_charges",
		intrinsic_modifier = "modifier_ankh",
		persistent_modifier = "modifier_ankh_passives",
		stats = { reincarnation_time = 5, magtheridon_reincarnation_time = 10 },
	},
	item_amulet_of_the_wild = {
		cost = 5000, shop = "secret", kind = "tactical", purchasable = true,
		charges = 3, stackable = false, minimum_game_difficulty = 4,
		active_slot = true, requires_active_slot = true, backpack_usable = false,
		cooldown = 60, cast_point = 0.15,
		script_file = "items/amulet_of_the_wild.lua",
		tags = { summons = 1.0, frontline = 0.75, survival = 0.55 },
		behavior = "instant_no_target", stacking = "charges",
		stats = { summon_duration = 180, summon_count = 1 },
	},
	item_xhs_cloak_of_flames = {
		cost = 3750, shop = "secret", kind = "tactical", purchasable = true,
		stackable = false, active_slot = true, requires_active_slot = true,
		backpack_usable = false, default_active = true,
		active_modifier = "modifier_xhs_cloak_of_flames_aura",
		intrinsic_modifier = "modifier_xhs_cloak_of_flames_basic",
		script_file = "items/item_cloak_of_flames.lua",
		tags = { wave = 1.0, magical = 0.45, frontline = 0.35 },
		behavior = "passive_aura", stacking = "unique_aura",
		stats = { radius = 375, damage_per_tick = 60, tick_time = 1 },
	},
	item_lifesteal_mask = {
		cost = 15000, shop = "secret", kind = "core", purchasable = true,
		stackable = false, requires_active_slot = true, backpack_usable = false,
		opening_core = true, equip_priority = 995,
		script_file = "items/item_lifesteal_mask.lua",
		tags = { right_click = 1.0, sustain = 1.0, survival = 0.55 },
		behavior = "passive", stacking = "unique_lifesteal",
		intrinsic_modifier = "modifier_lifesteal_mask",
		stats = { lifesteal_pct = 50 },
	},
	item_boots_of_speed = {
		cost = 6250, shop = "secret", kind = "core", purchasable = true,
		stackable = false, requires_active_slot = true, backpack_usable = false,
		tags = { mobility = 1.0 }, default_penalty = 34,
		behavior = "passive", stacking = "unique_movement_speed",
		intrinsic_modifier = "modifier_item_boots",
		stats = { bonus_movement_speed = 60 },
	},
	item_staff_of_mastery = {
		cost = 30000, shop = "secret", kind = "utility", purchasable = true,
		stackable = false, active_slot = true, requires_active_slot = true,
		backpack_usable = false, cooldown = 30, cast_range = 700,
		target_team = "enemy",
		tags = { armor = 0.8, magical = 0.6, control = 0.45, mana = 0.25 },
		behavior = "unit_target", stacking = "multiple_passive",
		intrinsic_modifier = "modifier_item_ghost_datadriven",
		active_modifier = "modifier_item_ghost_datadriven_active",
		stats = {
			bonus_armor = 50, duration = 5, target_spell_damage_pct = -100,
			bonus_movement_pct = -60, target_magic_amp_pct = 50,
			mana_regen = 10,
		},
	},
	item_healing_wards = {
		cost = 3000, shop = "home", kind = "tactical", purchasable = true,
		charges = 3, stackable = true, active_slot = true,
		requires_active_slot = true, backpack_usable = false,
		cooldown = 20, cast_range = 500, script_file = "items/wards",
		tags = { sustain = 0.85, team = 0.75 },
		behavior = "instant_point", stacking = "charges",
		summoned_unit = "healing_ward",
		stats = {
			duration = 30, radius = 500, regeneration_pct = 0.5,
			flat_regeneration = 75,
		},
	},
	item_healing_wards2 = {
		cost = 30000, shop = "home", kind = "tactical", purchasable = true,
		charges = 3, stackable = true, active_slot = true,
		requires_active_slot = true, backpack_usable = false,
		cooldown = 20, cast_range = 600, script_file = "items/wards",
		tags = { sustain = 1.0, team = 1.0 },
		behavior = "instant_point", stacking = "charges",
		summoned_unit = "healing_ward2",
		stats = {
			duration = 35, radius = 600, regeneration_pct = 1,
			flat_regeneration = 300,
		},
	},
	item_potion_full = {
		cost = 3500, shop = "home", kind = "tactical", purchasable = true,
		charges = 3, stackable = true, active_slot = true,
		requires_active_slot = true, backpack_usable = false,
		cooldown = 5, script_file = "items/potion.lua",
		tags = { sustain = 1.0, mana = 0.7, survival = 0.5 },
		behavior = "instant_no_target", stacking = "charges",
		stats = { hp_restore = 30000, mana_restore = 30000 },
	},
	item_potion_of_invulnerability = {
		cost = 7500, shop = "home", kind = "tactical", purchasable = true,
		charges = 3, stackable = true, active_slot = true,
		requires_active_slot = true, backpack_usable = false,
		cooldown = 40, script_file = "items/potion.lua",
		tags = { survival = 1.0, physical_defense = 0.8 },
		behavior = "instant_no_target", stacking = "charges",
		stats = { duration = 10 },
	},
	item_potion_of_antimagic = {
		cost = 6000, shop = "home", kind = "tactical", purchasable = true,
		charges = 3, stackable = true, active_slot = true,
		requires_active_slot = true, backpack_usable = false,
		cooldown = 75, script_file = "items/potion.lua",
		tags = { survival = 1.0, magical_defense = 1.0 },
		behavior = "instant_no_target", stacking = "charges",
		active_modifier = "modifier_anti_magic",
		stats = { duration = 6 },
	},
}

-- Tome KV entries are purchasable inventory items for humans and drops, but
-- the bot economy intentionally mirrors BuyMaxSmallTomesForPlayer by granting
-- the small tome's stats directly. Keeping them outside ITEMS prevents an
-- inventory purchase candidate while preserving one tested semantic source.
local TOME_ITEMS = {
	item_tome_small = {
		cost = 10000, shop = "side", kind = "tome",
		purchasable = true, charges = 1, active_slot = true,
		requires_active_slot = true, backpack_usable = false,
		behavior = "instant_no_target", stacking = "charges",
		script_file = "items/tomes.lua",
		bot_transaction = "direct_stats", bot_record_stats = false,
		stats = { stat_bonus = 50 },
	},
	item_tome_big = {
		cost = 50000, shop = "side", kind = "tome",
		purchasable = true, charges = 1, active_slot = true,
		requires_active_slot = true, backpack_usable = false,
		behavior = "instant_no_target", stacking = "charges",
		script_file = "items/tomes.lua",
		bot_transaction = "not_selected",
		stats = { stat_bonus = 250 },
	},
	item_tome_of_power = {
		cost = 5000, shop = "side", kind = "tome",
		purchasable = true, charges = 1, active_slot = true,
		requires_active_slot = true, backpack_usable = false,
		behavior = "instant_no_target", stacking = "charges",
		script_file = "items/tomes.lua",
		bot_transaction = "not_selected",
		cooldown = 60,
		stock = { initial = 0, maximum = 2, initial_time = 990, restock_time = 120 },
		stats = { hero_levels = 1, maximum_hero_level = 30 },
	},
}

-- Arena rewards and other non-purchasable drops are intentionally excluded
-- from ITEMS so the planner can never spend gold on them.  They still need
-- semantic metadata for inventory optimization after a bot earns one.
local EQUIP_ONLY_ITEMS = {
	item_ring_of_superiority = {
		kind = "reward", source = "sogat_arena", purchasable = false,
		requires_active_slot = true, equip_priority = 1090,
		behavior = "passive_on_equip", stacking = "unique_auras",
		tags = {
			right_click = 1.0, armor = 1.0, survival = 1.0,
			sustain = 1.0, mobility = 0.85,
		},
		stats = {
			bonus_damage_pct = 50, bonus_armor = 40,
			bonus_health_regen = 125, bonus_movement_speed = 90,
			bat_reduction = 0.4, endurance_bonus_movement_speed = 20,
		},
	},
}

local FAMILIES = {
	lightning = {
		tags = { right_click = 1.0, attack_speed = 0.95, single_target = 0.65, mobility = 0.25 },
		behavior = "toggle_no_target", passive_stacks = true,
		active_stacks = false, requires_active_slot = true,
		default_active = true, toggle_policy = "always_on",
		active_modifier = "modifier_orb_of_lightning_active",
		levels = {
			{
				name = "item_orb_of_lightning", cost = 10000, shop = "home",
				stats = {
					bonus_damage = 150, purge_chance = 10,
					purge_duration = 3, bonus_movespeed_pct = 5,
					purge_cooldown = 10, damage_to_summons = 300,
				},
			},
			{
				name = "item_orb_of_lightning2",
				purchase_name = "item_recipe_orb_of_lightning2",
				cost = 10000, shop = "home",
				stats = {
					bonus_damage = 450, purge_chance = 10,
					purge_duration = 3, bonus_movespeed_pct = 10,
					purge_cooldown = 10, damage_to_summons = 300,
				},
			},
			{
				name = "item_celestial_claws",
				purchase_name = "item_recipe_celestial_claws",
				cost = 30000, shop = "secret", no_backpack = true,
				stats = {
					bonus_damage = 1350, purge_chance = 10,
					purge_duration = 3, bonus_movespeed_pct = 20,
					purge_cooldown = 10, damage_to_summons = 300,
					bat_reduction = 0.2,
				},
			},
		},
	},
	fire = {
		tags = { right_click = 0.45, physical = 0.35, wave = 1.0, cleave = 1.0 },
		behavior = "toggle_no_target", passive_stacks = true,
		active_stacks = false, requires_active_slot = true,
		default_active = true, toggle_policy = "always_on",
		active_modifier = "modifier_orb_of_fire_active",
		levels = {
			{
				name = "item_orb_of_fire", cost = 10000, shop = "home",
				stats = { bonus_damage = 100, radius = 325, cleave_pct = 15 },
			},
			{
				name = "item_orb_of_fire2",
				purchase_name = "item_recipe_orb_of_fire2",
				cost = 10000, shop = "home",
				stats = { bonus_damage = 300, radius = 325, cleave_pct = 25 },
			},
			{
				name = "item_searing_blade",
				purchase_name = "item_recipe_searing_blade",
				cost = 30000, shop = "secret", no_backpack = true,
				stats = { bonus_damage = 450, radius = 325, cleave_pct = 40 },
			},
		},
	},
	earth = {
		tags = { right_click = 0.35, frontline = 0.65, armor = 1.0, physical_defense = 0.85, control = 0.4 },
		behavior = "toggle_no_target", passive_stacks = true,
		active_stacks = false, requires_active_slot = true,
		default_active = true, toggle_policy = "always_on",
		active_modifier = "modifier_orb_of_earth_active",
		levels = {
			{
				name = "item_orb_of_earth", cost = 10000, shop = "home",
				stats = {
					bonus_damage = 100, bonus_armor = 5,
					bash_duration = 0.5, bash_chance = 7,
				},
			},
			{
				name = "item_orb_of_earth2",
				purchase_name = "item_recipe_orb_of_earth2",
				cost = 10000, shop = "home",
				stats = {
					bonus_damage = 300, bonus_armor = 15,
					bash_duration = 0.5, bash_chance = 7,
				},
			},
			{
				name = "item_orb_of_earth3",
				purchase_name = "item_recipe_orb_of_earth3",
				cost = 30000, shop = "secret", no_backpack = true,
				stats = {
					bonus_damage = 900, bonus_armor = 30,
					bash_duration = 0.5, bash_chance = 7,
				},
			},
		},
	},
	darkness = {
		tags = { frontline = 1.0, survival = 1.0, armor = 0.55, sustain = 0.55, summons = 0.65 },
		behavior = "toggle_no_target", passive_stacks = true,
		active_stacks = false, requires_active_slot = true,
		default_active = true, toggle_policy = "threat_hysteresis",
		active_modifier = "modifier_orb_of_darkness_active",
		levels = {
			{
				name = "item_orb_of_darkness", cost = 10000, shop = "home",
				stats = {
					bonus_hp = 1500, bonus_damage = 50, bonus_armor = 5,
					bonus_health_regen = 20, summon_duration = 25,
					max_units = 10,
				},
			},
			{
				name = "item_orb_of_darkness2",
				purchase_name = "item_recipe_orb_of_darkness2",
				cost = 10000, shop = "home",
				stats = {
					bonus_hp = 3000, bonus_damage = 100, bonus_armor = 10,
					bonus_health_regen = 20, summon_duration = 25,
					max_units = 10,
				},
			},
			{
				name = "item_bracer_of_the_void",
				purchase_name = "item_recipe_bracer_of_the_void",
				cost = 30000, shop = "secret", no_backpack = true,
				stats = {
					bonus_hp = 9000, bonus_damage = 150, bonus_armor = 20,
					bonus_health_regen = 20, summon_duration = 25,
					max_units = 10,
				},
			},
		},
	},
	arcane = {
		tags = {
			magical = 1.0, cooldown = 1.0, caster = 1.0,
			control = 0.25, shared_debuff = 0.35,
		},
		behavior = "toggle_no_target", passive_stacks = true,
		active_stacks = false, requires_active_slot = true,
		default_active = true, toggle_policy = "always_on",
		active_modifier = "modifier_orb_of_arcane_active",
		levels = {
			{
				name = "item_orb_of_arcane", cost = 10000, shop = "home",
				stats = {
					spell_amp_pct = 35, cooldown_reduction_pct = 5,
					exposure_magic_resist_reduction = 8,
					exposure_duration = 4,
				},
			},
			{
				name = "item_mystic_gem",
				purchase_name = "item_recipe_mystic_gem",
				cost = 10000, shop = "home",
				stats = {
					spell_amp_pct = 50, cooldown_reduction_pct = 12,
					exposure_magic_resist_reduction = 16,
					exposure_duration = 5,
				},
			},
			{
				name = "item_astral_core",
				purchase_name = "item_recipe_astral_core",
				cost = 30000, shop = "secret", no_backpack = true,
				stats = {
					spell_amp_pct = 70, cooldown_reduction_pct = 20,
					exposure_magic_resist_reduction = 25,
					exposure_duration = 6,
				},
			},
		},
	},
	wind = {
		tags = { mobility = 1.0, evasion = 1.0, physical_defense = 0.9, survival = 0.4 },
		behavior = "toggle_no_target", passive_stacks = true,
		active_stacks = false, requires_active_slot = true,
		default_active = true, toggle_policy = "always_on",
		active_modifier = "modifier_orb_of_wind_active",
		levels = {
			{
				name = "item_orb_of_wind", cost = 10000, shop = "home",
				stats = {
					bonus_damage = 100, bonus_evasion_pct = 17,
					bonus_movement_speed = 40, evasion_proc_duration = 0,
					evasion_proc_cooldown = 0, evasion_proc_movespeed_pct = 0,
					evasion_proc_damage_reduction_pct = 0,
				},
			},
			{
				name = "item_zephyr_gem",
				purchase_name = "item_recipe_zephyr_gem",
				cost = 10000, shop = "home",
				stats = {
					bonus_damage = 300, bonus_evasion_pct = 25,
					bonus_movement_speed = 70, evasion_proc_duration = 2,
					evasion_proc_cooldown = 8, evasion_proc_movespeed_pct = 20,
					evasion_proc_damage_reduction_pct = 0,
				},
			},
			{
				name = "item_tempest_aegis",
				purchase_name = "item_recipe_tempest_aegis",
				cost = 30000, shop = "secret", no_backpack = true,
				stats = {
					bonus_damage = 900, bonus_evasion_pct = 35,
					bonus_movement_speed = 100, evasion_proc_duration = 2,
					evasion_proc_cooldown = 8, evasion_proc_movespeed_pct = 20,
					evasion_proc_damage_reduction_pct = 20,
				},
			},
		},
	},
	venom = {
		tags = {
			right_click = 0.5, physical = 0.55, single_target = 0.8,
			boss = 1.0, damage_over_time = 1.0, shared_debuff = 0.7,
		},
		behavior = "toggle_no_target", passive_stacks = true,
		active_stacks = false, requires_active_slot = true,
		default_active = true, toggle_policy = "always_on",
		active_modifier = "modifier_orb_of_venom_xhs_active",
		levels = {
			{
				name = "item_xhs_orb_of_venom", cost = 10000, shop = "home",
				stats = {
					bonus_damage = 50, poison_damage_per_second = 25,
					poison_duration = 4, armor_reduction = 0,
					toxic_saturation_damage = 0,
				},
			},
			{
				name = "item_viridian_gem",
				purchase_name = "item_recipe_viridian_gem",
				cost = 10000, shop = "home",
				stats = {
					bonus_damage = 150, poison_damage_per_second = 75,
					poison_duration = 4, armor_reduction = 5,
					toxic_saturation_damage = 0,
				},
			},
			{
				name = "item_plagueheart",
				purchase_name = "item_recipe_plagueheart",
				cost = 30000, shop = "secret", no_backpack = true,
				stats = {
					bonus_damage = 450, poison_damage_per_second = 150,
					poison_duration = 4, armor_reduction = 12,
					toxic_saturation_damage = 500,
				},
			},
		},
	},
}

local function Copy(source)
	local result = {}
	for key, value in pairs(source or {}) do
		result[key] = type(value) == "table" and Copy(value) or value
	end
	return result
end

for familyName, family in pairs(FAMILIES) do
	for tier, level in ipairs(family.levels) do
		local item = Copy(level)
		item.kind = "core"
		item.purchasable = true
		item.family = familyName
		item.tier = tier
		item.tags = Copy(family.tags)
		item.behavior = level.behavior or family.behavior
		item.passive_stacks = family.passive_stacks
		item.active_stacks = family.active_stacks
		item.requires_active_slot = family.requires_active_slot
		item.default_active = family.default_active
		item.toggle_policy = family.toggle_policy
		item.active_modifier = family.active_modifier
		item.maximum = 1
		item.combines = tier > 1
		item.predecessor = tier > 1 and family.levels[tier - 1].name or nil
		item.terminal = tier == #family.levels
		item.total_cost = tier == 1 and level.cost
			or (family.levels[tier - 1].total_cost or 0) + level.cost
		family.levels[tier].total_cost = item.total_cost
		ITEMS[item.name] = item
	end
end

-- Table keys are not retained when an entry is deep-copied. Every runtime
-- consumer (planner, transaction layer, telemetry) therefore needs an
-- explicit canonical identity on all catalog surfaces, not only orb levels.
local function NormalizeEntryNames(entries)
	for name, entry in pairs(entries or {}) do
		entry.name = tostring(name)
	end
end

NormalizeEntryNames(ITEMS)
NormalizeEntryNames(EQUIP_ONLY_ITEMS)
NormalizeEntryNames(TOME_ITEMS)

function XHSBotItemCatalog:Get(name)
	name = tostring(name or "")
	return ITEMS[name] or EQUIP_ONLY_ITEMS[name] or TOME_ITEMS[name]
end

function XHSBotItemCatalog:GetFamily(name)
	return FAMILIES[tostring(name or "")]
end

function XHSBotItemCatalog:GetFamilies()
	return FAMILIES
end

function XHSBotItemCatalog:GetItems()
	return ITEMS
end

function XHSBotItemCatalog:GetEquipOnlyItems()
	return EQUIP_ONLY_ITEMS
end

function XHSBotItemCatalog:GetTomes()
	return TOME_ITEMS
end

function XHSBotItemCatalog:GetTome(name)
	return TOME_ITEMS[tostring(name or "")]
end

function XHSBotItemCatalog:CopyEntry(name)
	return Copy(self:Get(name))
end

return XHSBotItemCatalog
