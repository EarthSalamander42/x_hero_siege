if XHSBotHeroProfiles == nil then
	XHSBotHeroProfiles = {}
end

local ITEM_AFFINITIES = {
	npc_dota_hero_enchantress = {
		right_click = 1.00, attack_speed = 1.00, physical = 0.90,
		single_target = 0.75, wave = 0.45, damage_over_time = 0.35,
		mobility = 0.25, survival = 0.25, evasion = 0.20,
	},
	npc_dota_hero_sniper = {
		right_click = 1.00, attack_speed = 0.95, physical = 0.90,
		single_target = 1.00, wave = 0.25, mobility = 0.45, survival = 0.25,
	},
	npc_dota_hero_sven = {
		right_click = 0.75, physical = 0.80, frontline = 0.90,
		survival = 0.85, armor = 0.60, control = 0.55, wave = 0.40,
	},
	npc_dota_hero_omniknight = {
		caster = 0.80, magical = 0.70, cooldown = 0.85,
		sustain = 1.00, team = 1.00, frontline = 0.55,
		survival = 0.65, control = 0.35, mana = 0.55,
	},
	npc_dota_hero_crystal_maiden = {
		caster = 1.00, magical = 1.00, cooldown = 0.95,
		control = 0.85, mana = 0.75, summons = 0.45,
		survival = 0.25, wave = 0.65,
	},
	npc_dota_hero_abyssal_underlord = {
		caster = 0.70, magical = 0.75, cooldown = 0.70,
		frontline = 1.00, survival = 0.90, armor = 0.60,
		control = 0.80, wave = 0.85, right_click = 0.35,
	},
	npc_dota_hero_dragon_knight = {
		frontline = 0.90, survival = 0.90, sustain = 0.80,
		team = 0.75, caster = 0.55, magical = 0.45,
		cooldown = 0.55, right_click = 0.45, wave = 0.45,
	},
	npc_dota_hero_elder_titan = {
		frontline = 0.95, survival = 0.80, control = 1.00,
		caster = 0.75, magical = 0.70, cooldown = 0.75,
		wave = 0.65, right_click = 0.40,
	},
	npc_dota_hero_windrunner = {
		right_click = 0.95, attack_speed = 0.85, physical = 0.90,
		single_target = 0.85, wave = 0.60, sustain = 0.40,
		mobility = 0.40, control = 0.25,
	},
}

-- Roles are deliberately separate from the legacy combat label. The primary
-- role describes where a hero stands and what keeps it alive; the secondary
-- role describes how its kit converts resources into impact. Item affinities
-- consume both so a frontline right-clicker does not get built like a pure
-- damage sponge.
local ROLE_AFFINITY_BONUSES = {
	frontline = {
		frontline = 0.18, survival = 0.14, armor = 0.10,
	},
	right_click = {
		right_click = 0.28, physical = 0.22, attack_speed = 0.18,
		single_target = 0.14, wave = 0.10,
	},
	ranged_dps = {
		right_click = 0.18, physical = 0.14, single_target = 0.10,
	},
	support = {
		team = 0.18, sustain = 0.14, cooldown = 0.08,
	},
	spellcaster = {
		caster = 0.18, magical = 0.18, cooldown = 0.12, mana = 0.08,
	},
	control = {
		control = 0.18, cooldown = 0.08,
	},
	wave_clear = {
		wave = 0.22, cleave = 0.18, physical = 0.08, magical = 0.08,
	},
}

-- Source of truth for native attack lifesteal in the playable XHS hero roster.
-- Spell lifesteal (Leshrac/Dark Summoner) is deliberately excluded: it does not
-- replace the Mask's sustain on basic attacks.
local INTRINSIC_ATTACK_LIFESTEAL_BY_HERO = {
	npc_dota_hero_axe = {
		ability = "axe_battle_rage",
		kind = "active_buff",
		lifesteal_pct = 16,
	},
	npc_dota_hero_lone_druid = {
		ability = "xhs_vampiric_aura",
		kind = "aura",
		lifesteal_pct = 50,
	},
	npc_dota_hero_meepo = {
		ability = "holdout_life_steal",
		kind = "autocast_attack",
		lifesteal_pct = 250,
	},
	npc_dota_hero_monkey_king = {
		ability = "holdout_jingu_mastery",
		kind = "conditional_attack",
		lifesteal_pct = 50,
	},
	npc_dota_hero_sven = {
		ability = "holdout_muradin_hammer",
		kind = "aura",
		lifesteal_pct = 50,
	},
	npc_dota_hero_terrorblade = {
		ability = "xhs_vampiric_aura",
		kind = "aura",
		lifesteal_pct = 50,
	},
}

local PROFILE_BY_HERO = {
	npc_dota_hero_enchantress = {
		certified = true,
		runtime_validated = false,
		display_name = "Tyrande",
		role = "ranged_dps",
		primary_role = "ranged_dps",
		secondary_role = "right_click",
		preferred_range = 620,
		safety_distance = 390,
		retreat_health = 0.28,
		target_priority = { "boss", "ranged", "nearest" },
		item_affinities = ITEM_AFFINITIES.npc_dota_hero_enchantress,
		item_family_limits = { lightning = 2 },
		consumable_targets = { health = 5, mana = 3 },
		skill_build = {
			"xhs_trueshot_aura",
			"holdout_endurance_aura",
			"holdout_critical_arrows",
			"tyrande_multiple_arrows",
			"holdout_evasion",
			"holdout_poison_attack",
		},
		abilities = {},
	},
	npc_dota_hero_sniper = {
		certified = true,
		runtime_validated = false,
		display_name = "Rifleman",
		role = "ranged_dps",
		primary_role = "ranged_dps",
		secondary_role = "right_click",
		preferred_range = 720,
		safety_distance = 430,
		retreat_health = 0.28,
		target_priority = { "boss", "ranged", "nearest" },
		item_affinities = ITEM_AFFINITIES.npc_dota_hero_sniper,
		skill_build = {
			"rifleman_assassinate",
			"holdout_shield",
			"holdout_distance_aura",
			"holdout_plasma_rifle",
			"holdout_rocket_launcher",
			"rifleman_bloodlust",
		},
		attack_mode = {
			single_target = {
				"holdout_laser",
				"holdout_rocket_launcher",
			},
			cleave = {
				"holdout_plasma_rifle_20",
				"holdout_plasma_rifle",
			},
			cleave_radius = 325,
			cleave_enter_targets = 3,
			cleave_exit_targets = 2,
			minimum_mana_ratio = 0.05,
			minimum_mode_attacks = 2,
			minimum_mode_duration = 0.35,
			target_loss_grace = 0.45,
			target_change_override = true,
			priority = 90,
		},
		abilities = {
			rifleman_bloodlust = {
				mode = "ally_buff",
				priority = 63,
				intent = "offense",
				prefer_roles = { "ranged_dps", "frontline" },
				active_modifier = "modifier_rifleman_bloodlust",
				require_combat = true,
			},
			rifleman_assassinate = { mode = "enemy_unit", priority = 88, prefer_boss = true },
		},
	},
	npc_dota_hero_sven = {
		certified = true,
		runtime_validated = false,
		display_name = "Mountain King",
		role = "frontline",
		primary_role = "frontline",
		secondary_role = "right_click",
		-- The first two cheap cores are deliberate: Darkness lets him stand
		-- in the wave, then Fire converts his melee attacks into wave clear.
		-- Once that opening is complete, the adaptive need scorer is free to
		-- upgrade either family or take Earth as the neutral third option.
		opening_orb_order = { "darkness", "fire" },
		orb_fallback_order = { "darkness", "fire", "earth" },
		preferred_range = 180,
		safety_distance = 120,
		retreat_health = 0.22,
		target_priority = { "boss", "caster", "nearest" },
		item_affinities = ITEM_AFFINITIES.npc_dota_hero_sven,
		skill_build = {
			"holdout_avatar",
			"xhs_mountain_king_bash",
			"holdout_muradin_hammer",
			"holdout_storm_bolt",
			"holdout_thunder_clap",
			"holdout_thunder_spirit",
		},
		abilities = {
			holdout_storm_bolt = { mode = "enemy_unit", priority = 82, control = true, optional = true },
			holdout_storm_bolt_20 = { mode = "enemy_unit", priority = 85, control = true, optional = true },
			holdout_thunder_clap = { mode = "no_target_enemy", priority = 76, radius = 400, minimum_targets = 2, optional = true },
			holdout_thunder_clap_20 = { mode = "no_target_enemy", priority = 79, radius = 400, minimum_targets = 2, optional = true },
			holdout_avatar = {
				mode = "self_buff",
				priority = 72,
				require_combat = true,
				radius = 700,
				minimum_targets = 3,
				cast_on_boss = true,
			},
		},
	},
	npc_dota_hero_omniknight = {
		certified = true,
		runtime_validated = false,
		display_name = "Paladin",
		role = "support",
		primary_role = "support",
		secondary_role = "frontline",
		preferred_range = 360,
		safety_distance = 260,
		retreat_health = 0.30,
		target_priority = { "threat_to_ally", "boss", "nearest" },
		item_affinities = ITEM_AFFINITIES.npc_dota_hero_omniknight,
		skill_build = {
			"holdout_pure_light",
			"holdout_howl_of_terror",
			"holdout_devotion_aura",
			"holdout_healing_wave",
			"holdout_fan_of_light",
			"holdout_taunt",
		},
		abilities = {
			holdout_healing_wave = {
				mode = "ally_heal",
				priority = 96,
				include_self = true,
				-- The bounce can reach the caster, but it is not guaranteed
				-- when allies are spread out. Fatal self-heal targeting must
				-- therefore treat the caster as an explicit recipient.
				heals_caster = false,
				heal_flat_key = "damage",
				heal_percent_key = "heal_pct",
				self_save_threshold = 0.42,
				minimum_effective_heal_ratio = 0.06,
			},
			holdout_fan_of_light = {
				mode = "no_target_enemy",
				priority = 78,
				radius = 675,
				minimum_targets = 2,
			},
			holdout_howl_of_terror = { mode = "point_aoe", priority = 70, radius = 350, minimum_targets = 1 },
			holdout_taunt = { mode = "no_target_enemy", priority = 64, radius = 450, minimum_targets = 3, optional = true },
			holdout_light_frenzy = {
				mode = "ally_buff",
				priority = 86,
				intent = "offense",
				prefer_roles = { "ranged_dps", "frontline" },
				active_modifier = "modifier_light_frenzy",
				require_combat = true,
				optional = true,
			},
			holdout_pure_light = {
				mode = "self_buff",
				priority = 83,
				require_combat = true,
				radius = 700,
				minimum_targets = 3,
				cast_on_boss = true,
			},
		},
	},
	npc_dota_hero_crystal_maiden = {
		certified = true,
		runtime_validated = false,
		display_name = "Archmage",
		role = "ranged_control",
		primary_role = "spellcaster",
		secondary_role = "control",
		preferred_range = 620,
		safety_distance = 400,
		retreat_health = 0.30,
		target_priority = { "caster", "boss", "nearest" },
		item_affinities = ITEM_AFFINITIES.npc_dota_hero_crystal_maiden,
		skill_build = {
			"holdout_elemental_wave",
			"holdout_drain",
			"holdout_debilitation_aura",
			"holdout_crushing_wave",
			"holdout_summon_water_elemental",
			"holdout_mana_shield",
		},
		abilities = {
			holdout_crushing_wave = { mode = "point_aoe", priority = 82, minimum_targets = 2 },
			holdout_summon_water_elemental = { mode = "summon", priority = 58, require_combat = true },
			holdout_drain = { mode = "enemy_unit", priority = 74 },
			holdout_mana_shield = { mode = "defensive_toggle", priority = 85 },
			holdout_elemental_wave = {
				mode = "directional_point",
				priority = 90,
				radius = 450,
				minimum_targets = 2,
				aim_distance = 240,
				travel_range = 1800,
				optional = true,
			},
			holdout_rain_of_ice = { mode = "point_aoe", priority = 94, radius = 500, minimum_targets = 2, optional = true },
		},
	},
	npc_dota_hero_abyssal_underlord = {
		certified = true,
		runtime_validated = false,
		display_name = "Magtheridon",
		role = "frontline",
		primary_role = "frontline",
		secondary_role = "spellcaster",
		preferred_range = 190,
		safety_distance = 130,
		retreat_health = 0.24,
		target_priority = { "boss", "caster", "nearest" },
		item_affinities = ITEM_AFFINITIES.npc_dota_hero_abyssal_underlord,
		skill_build = {
			"holdout_doom",
			"holdout_rain_of_chaos",
			"holdout_unholy_aura",
			"holdout_firestorm",
			"holdout_war_thunder",
			"holdout_innate_great_cleave",
		},
		abilities = {
			holdout_firestorm = { mode = "point_aoe", priority = 82, radius = 400, minimum_targets = 2 },
			holdout_war_thunder = { mode = "no_target_enemy", priority = 78, radius = 400, minimum_targets = 2, control = true },
			holdout_rain_of_chaos = {
				mode = "no_target_enemy",
				priority = 91,
				radius = 1000,
				minimum_targets = 3,
				cast_on_boss = true,
				control = true,
			},
			holdout_doom = { mode = "enemy_unit", priority = 98, prefer_boss = true, optional = true },
		},
	},
	npc_dota_hero_dragon_knight = {
		certified = true,
		runtime_validated = false,
		display_name = "Arthas",
		role = "frontline_support",
		primary_role = "frontline",
		secondary_role = "support",
		preferred_range = 190,
		safety_distance = 130,
		retreat_health = 0.25,
		target_priority = { "threat_to_ally", "boss", "nearest" },
		item_affinities = ITEM_AFFINITIES.npc_dota_hero_dragon_knight,
		skill_build = {
			"holdout_light_roar",
			"holdout_frostmourne",
			"holdout_chieftain_endurance_aura",
			"holdout_holy_light",
			"holdout_divine_shield",
			"holdout_innate_great_cleave",
		},
		abilities = {
			holdout_holy_light = {
				mode = "no_target_mixed",
				priority = 92,
				radius = 550,
				minimum_targets = 2,
				team_health_threshold = 0.82,
				healing = true,
				heals_caster = true,
				heal_flat_key = "heal",
				self_save_threshold = 0.44,
				minimum_effective_heal_ratio = 0.06,
			},
			holdout_divine_shield = {
				mode = "self_defensive",
				priority = 97,
				health_threshold = 0.42,
				focus_threshold = 2,
				active_modifier = "modifier_divine_shield",
			},
			holdout_light_roar = {
				mode = "team_buff",
				priority = 94,
				radius = 900,
				minimum_allies = 2,
				minimum_enemies = 3,
				cast_on_boss = true,
				active_modifier = "modifier_light_roar",
			},
		},
	},
	npc_dota_hero_elder_titan = {
		certified = true,
		runtime_validated = false,
		display_name = "Tauren Chieftain",
		role = "frontline_control",
		primary_role = "frontline",
		secondary_role = "control",
		preferred_range = 190,
		safety_distance = 130,
		retreat_health = 0.24,
		target_priority = { "caster", "boss", "nearest" },
		item_affinities = ITEM_AFFINITIES.npc_dota_hero_elder_titan,
		redundant_items = {
			-- Chieftain wants enemies hittable; an ethereal target works
			-- against his physical frontline/control job.
			item_staff_of_mastery = true,
		},
		skill_build = {
			"holdout_lightning_stroke",
			"holdout_pulverize",
			"holdout_chieftain_endurance_aura",
			"holdout_shockwave",
			"holdout_war_stomp",
			"holdout_roar",
		},
		abilities = {
			holdout_shockwave = { mode = "enemy_unit", priority = 82, control = true },
			holdout_war_stomp = { mode = "no_target_enemy", priority = 84, radius = 450, minimum_targets = 2, control = true },
			holdout_roar = {
				mode = "team_buff",
				priority = 89,
				radius = 900,
				minimum_allies = 2,
				minimum_enemies = 3,
				cast_on_boss = true,
				active_modifier = "modifier_roar",
			},
			holdout_lightning_stroke = {
				mode = "no_target_enemy",
				priority = 96,
				radius = 1000,
				minimum_targets = 3,
				cast_on_boss = true,
				control = true,
			},
		},
	},
	npc_dota_hero_windrunner = {
		certified = true,
		runtime_validated = false,
		display_name = "Ranger",
		role = "ranged_dps",
		primary_role = "ranged_dps",
		secondary_role = "wave_clear",
		preferred_range = 620,
		safety_distance = 390,
		retreat_health = 0.29,
		target_priority = { "boss", "caster", "nearest" },
		item_affinities = ITEM_AFFINITIES.npc_dota_hero_windrunner,
		skill_build = {
			"holdout_splash_arrows",
			"holdout_critical_arrows_alt",
			"holdout_bash_arrows",
			"holdout_searing_arrows",
			"holdout_inner_fire",
			"forest_troll_high_priest_heal",
		},
		abilities = {
			holdout_inner_fire = {
				mode = "ally_buff",
				priority = 91,
				intent = "offense",
				prefer_roles = { "ranged_dps", "frontline", "frontline_control" },
				active_modifier = "modifier_inner_fire",
				require_combat = true,
			},
			holdout_searing_arrows = {
				mode = "autocast_attack",
				priority = 88,
				mana_threshold = 0.20,
			},
			forest_troll_high_priest_heal = {
				mode = "ally_heal",
				priority = 95,
				include_self = true,
				heal_flat_key = "health",
				self_save_threshold = 0.40,
				minimum_effective_heal_ratio = 0.06,
				optional = true,
			},
		},
	},
}

local function ApplyRoleAffinities(profile)
	if type(profile) ~= "table" then return end
	profile.item_affinities = profile.item_affinities or {}
	local roles = {
		{ name = profile.primary_role, weight = 1.00 },
		{ name = profile.secondary_role, weight = 0.85 },
	}
	for _, role in ipairs(roles) do
		for affinity, bonus in pairs(ROLE_AFFINITY_BONUSES[role.name] or {}) do
			profile.item_affinities[affinity] = math.min(
				1.25,
				math.max(0, tonumber(profile.item_affinities[affinity]) or 0)
					+ bonus * role.weight
			)
		end
	end
end

local function ApplyIntrinsicAttackLifesteal(heroName, profile)
	if type(profile) ~= "table" then return end
	local source = INTRINSIC_ATTACK_LIFESTEAL_BY_HERO[heroName]
	if type(source) ~= "table" then return end

	profile.intrinsic_sustain = profile.intrinsic_sustain or {}
	profile.intrinsic_sustain.attack_lifesteal = true
	profile.intrinsic_sustain.lifesteal_aura = source.kind == "aura"
	profile.intrinsic_sustain.lifesteal_pct = tonumber(source.lifesteal_pct) or 0
	profile.intrinsic_sustain.ability = source.ability
	profile.intrinsic_sustain.kind = source.kind
	profile.redundant_items = profile.redundant_items or {}
	profile.redundant_items.item_lifesteal_mask = true
end

for heroName, profile in pairs(PROFILE_BY_HERO) do
	profile.hero_name = heroName
	ApplyRoleAffinities(profile)
	ApplyIntrinsicAttackLifesteal(heroName, profile)
end

local STANDARD_HEROES = {
	{ hero = "npc_dota_hero_enchantress" },
	{ hero = "npc_dota_hero_crystal_maiden" },
	{
		hero = "npc_dota_hero_luna",
		exclusion_reason = "Active ability timing and target selection have not been validated in Tools",
	},
	{
		hero = "npc_dota_hero_lone_druid",
		exclusion_reason = "Summon ownership, orders, death, and respawn lifecycle are not certified",
	},
	{
		hero = "npc_dota_hero_pugna",
		exclusion_reason = "Unit/point cast rules and defensive spell use have no validated Tools profile",
	},
	{
		hero = "npc_dota_hero_lich",
		exclusion_reason = "Ally buff and chained-spell target rules have no validated Tools profile",
	},
	{
		hero = "npc_dota_hero_nyx_assassin",
		exclusion_reason = "Burrow/invisibility state transitions and directional casts are not certified",
	},
	{ hero = "npc_dota_hero_abyssal_underlord" },
	{
		hero = "npc_dota_hero_terrorblade",
		exclusion_reason = "Transformation and alternate-form ability behavior are not certified",
	},
	{
		hero = "npc_dota_hero_phantom_assassin",
		exclusion_reason = "Mobility target selection and melee commitment have no validated Tools profile",
	},
	{ hero = "npc_dota_hero_elder_titan" },
	{
		hero = "npc_dota_hero_mirana",
		exclusion_reason = "Summon ownership and support-target selection are not certified",
	},
	{ hero = "npc_dota_hero_dragon_knight" },
	{ hero = "npc_dota_hero_windrunner" },
	{
		hero = "npc_dota_hero_invoker",
		exclusion_reason = "Multi-ability state machine and spell sequencing are not certified",
	},
	{ hero = "npc_dota_hero_sniper" },
	{
		hero = "npc_dota_hero_shadow_shaman",
		exclusion_reason = "Ward ownership, placement, and summon behavior are not certified",
	},
	{
		hero = "npc_dota_hero_juggernaut",
		exclusion_reason = "Channel protection and mobility target selection have no validated Tools profile",
	},
	{ hero = "npc_dota_hero_omniknight" },
	{
		hero = "npc_dota_hero_rattletrap",
		exclusion_reason = "Forced movement and point-target initiation are not certified",
	},
	{
		hero = "npc_dota_hero_chen",
		exclusion_reason = "Controlled-unit acquisition, orders, and lifecycle are not certified",
	},
	{
		hero = "npc_dota_hero_lina",
		exclusion_reason = "Line/point spell placement has no validated Tools profile",
	},
	{ hero = "npc_dota_hero_sven" },
	{
		hero = "npc_dota_hero_ursa",
		exclusion_reason = "Melee commitment and defensive timing have no validated Tools profile",
	},
	{
		hero = "npc_dota_hero_nevermore",
		exclusion_reason = "Directional spell sequencing and facing control are not certified",
	},
	{
		hero = "npc_dota_hero_brewmaster",
		exclusion_reason = "Split and secondary-unit lifecycle are not certified",
	},
	{
		hero = "npc_dota_hero_warlock",
		exclusion_reason = "Summon ownership and portal behavior are not certified",
	},
	{
		hero = "npc_dota_hero_razor",
		exclusion_reason = "Tether maintenance and movement-aware cast behavior have no validated Tools profile",
	},
}

local COMPOSITION_ORDER = {
	balanced = {
		"npc_dota_hero_sven",
		"npc_dota_hero_sniper",
		"npc_dota_hero_enchantress",
		"npc_dota_hero_omniknight",
		"npc_dota_hero_crystal_maiden",
		"npc_dota_hero_abyssal_underlord",
		"npc_dota_hero_dragon_knight",
		"npc_dota_hero_elder_titan",
		"npc_dota_hero_windrunner",
	},
	damage = {
		"npc_dota_hero_sniper",
		"npc_dota_hero_enchantress",
		"npc_dota_hero_windrunner",
		"npc_dota_hero_sven",
		"npc_dota_hero_abyssal_underlord",
		"npc_dota_hero_elder_titan",
		"npc_dota_hero_crystal_maiden",
		"npc_dota_hero_dragon_knight",
		"npc_dota_hero_omniknight",
	},
	support = {
		"npc_dota_hero_omniknight",
		"npc_dota_hero_dragon_knight",
		"npc_dota_hero_crystal_maiden",
		"npc_dota_hero_elder_titan",
		"npc_dota_hero_windrunner",
		"npc_dota_hero_enchantress",
		"npc_dota_hero_sven",
		"npc_dota_hero_abyssal_underlord",
		"npc_dota_hero_sniper",
	},
	random = {
		"npc_dota_hero_sniper",
		"npc_dota_hero_enchantress",
		"npc_dota_hero_sven",
		"npc_dota_hero_omniknight",
		"npc_dota_hero_crystal_maiden",
		"npc_dota_hero_abyssal_underlord",
		"npc_dota_hero_dragon_knight",
		"npc_dota_hero_elder_titan",
		"npc_dota_hero_windrunner",
	},
}

local function CopyArray(source)
	local copy = {}
	for index, value in ipairs(source or {}) do
		copy[index] = value
	end
	return copy
end

function XHSBotHeroProfiles:Get(heroName)
	return PROFILE_BY_HERO[heroName]
end

function XHSBotHeroProfiles:GetIntrinsicAttackLifesteal(heroName)
	return INTRINSIC_ATTACK_LIFESTEAL_BY_HERO[heroName]
end

function XHSBotHeroProfiles:HasIntrinsicAttackLifesteal(heroName)
	return self:GetIntrinsicAttackLifesteal(heroName) ~= nil
end

function XHSBotHeroProfiles:IsCertified(heroName)
	local profile = self:Get(heroName)
	return profile ~= nil and profile.certified == true
end

function XHSBotHeroProfiles:GetCertifiedHeroes(composition)
	return CopyArray(COMPOSITION_ORDER[composition] or COMPOSITION_ORDER.balanced)
end

function XHSBotHeroProfiles:GetCertifiedHeroOptions()
	local options = {}
	local seen = {}
	for _, heroName in ipairs(COMPOSITION_ORDER.balanced) do
		local profile = self:Get(heroName)
		if profile ~= nil and profile.certified == true and seen[heroName] ~= true then
			table.insert(options, {
				hero = heroName,
				display_name = profile.display_name or heroName,
			})
			seen[heroName] = true
		end
	end
	return options
end

function XHSBotHeroProfiles:GetCertifiedHeroCount()
	local count = 0
	for _, profile in pairs(PROFILE_BY_HERO) do
		if profile.certified == true then count = count + 1 end
	end
	return count
end

function XHSBotHeroProfiles:GetAvailableHeroCount(composition, unavailable)
	unavailable = unavailable or {}
	local seen = {}
	local count = 0
	for _, heroName in ipairs(self:GetCertifiedHeroes(composition)) do
		if seen[heroName] ~= true
			and unavailable[heroName] ~= true
			and self:IsCertified(heroName) then
			seen[heroName] = true
			count = count + 1
		end
	end
	return count
end

function XHSBotHeroProfiles:PickHeroes(count, composition, unavailable)
	count = math.max(0, math.floor(tonumber(count) or 0))
	unavailable = unavailable or {}
	local candidates = self:GetCertifiedHeroes(composition)
	local candidatePool = {}
	local candidateSet = {}
	local selected = {}
	local selectedSet = {}

	for rank, heroName in ipairs(candidates) do
		if unavailable[heroName] ~= true
			and candidateSet[heroName] ~= true
			and self:IsCertified(heroName) then
			table.insert(candidatePool, {
				hero = heroName,
				rank = rank,
			})
			candidateSet[heroName] = true
		end
	end

	while #selected < count and #candidatePool > 0 do
		local totalWeight = 0
		for _, candidate in ipairs(candidatePool) do
			local weight = composition == "random"
				and 1
				or math.max(1, #candidates - candidate.rank + 1)
			candidate.weight = weight
			totalWeight = totalWeight + weight
		end

		local roll = RandomFloat ~= nil
			and RandomFloat(0, totalWeight)
			or math.random() * totalWeight
		local cumulativeWeight = 0
		local selectedIndex = #candidatePool
		for index, candidate in ipairs(candidatePool) do
			cumulativeWeight = cumulativeWeight + candidate.weight
			if roll < cumulativeWeight then
				selectedIndex = index
				break
			end
		end

		local heroName = candidatePool[selectedIndex].hero
		table.remove(candidatePool, selectedIndex)
		table.insert(selected, heroName)
		selectedSet[heroName] = true
		unavailable[heroName] = true
	end

	return selected
end

function XHSBotHeroProfiles:GetCoverage()
	local coverage = {}
	for _, entry in ipairs(STANDARD_HEROES) do
		local heroName = entry.hero
		local profile = PROFILE_BY_HERO[heroName]
		table.insert(coverage, {
			hero = heroName,
			status = profile and profile.certified and "certified" or "excluded",
			runtime_validated = profile and profile.runtime_validated == true or false,
			reason = profile and profile.certified
				and "Implementation-ready profile; full Tools runtime validation is still pending"
				or entry.exclusion_reason,
		})
	end
	return coverage
end

return XHSBotHeroProfiles
