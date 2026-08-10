require("abilities/creeps/xhs_creep_passives")

XHSCreepPassives = XHSCreepPassives or {}

local REGISTRY = {
	-- Phase 1 lane creeps
	npc_xhs_undead_creep_melee_1 = "xhs_creep_blood_hunger",
	npc_xhs_orc_creep_melee_1 = "xhs_creep_heavy_hide",
	npc_xhs_elf_creep_melee_1 = "xhs_creep_moon_glaive",
	npc_xhs_human_creep_melee_1 = "xhs_creep_dragon_blood",
	npc_xhs_undead_creep_ranged_1 = "xhs_creep_geminate_shot",
	npc_xhs_orc_creep_ranged_1 = "xhs_creep_berserker_blood",
	npc_xhs_elf_creep_ranged_1 = "xhs_creep_frost_arrows",
	npc_xhs_human_creep_ranged_1 = "xhs_creep_headshot",

	npc_xhs_undead_creep_melee_2 = "xhs_creep_plague_cloud",
	npc_xhs_orc_creep_melee_2 = "xhs_creep_endurance",
	npc_xhs_elf_creep_melee_2 = "xhs_creep_fury_swipes",
	npc_xhs_human_creep_melee_2 = "xhs_creep_knights_guard",
	npc_xhs_undead_creep_ranged_2 = "xhs_creep_death_aura",
	npc_xhs_orc_creep_ranged_2 = "xhs_creep_shamanic_ward",
	npc_xhs_elf_creep_ranged_2 = "xhs_creep_chimaera_splash",
	npc_xhs_human_creep_ranged_2 = "xhs_creep_devotion",

	npc_xhs_undead_creep_melee_3 = "xhs_creep_spiked_carapace",
	npc_xhs_orc_creep_melee_3 = "xhs_creep_chaos_strike",
	npc_xhs_elf_creep_melee_3 = "xhs_creep_craggy_exterior",
	npc_xhs_human_creep_melee_3 = "xhs_creep_mana_break",
	npc_xhs_undead_creep_ranged_3 = "xhs_creep_dread_aura",
	npc_xhs_orc_creep_ranged_3 = "xhs_creep_fervor",
	npc_xhs_elf_creep_ranged_3 = "xhs_creep_venom_shot",
	npc_xhs_human_creep_ranged_3 = "xhs_creep_fiery_soul",

	npc_xhs_undead_creep_melee_4 = "xhs_creep_frostmourne_hunger",
	npc_xhs_orc_creep_melee_4 = "xhs_creep_titanic_cleave",
	npc_xhs_elf_creep_melee_4 = "xhs_creep_evasion",
	npc_xhs_human_creep_melee_4 = "xhs_creep_pack_leader",
	npc_xhs_undead_creep_ranged_4 = "xhs_creep_cold_skin",
	npc_xhs_orc_creep_ranged_4 = "xhs_creep_corrosive_scales",
	npc_xhs_elf_creep_ranged_4 = "xhs_creep_untouchable",
	npc_xhs_human_creep_ranged_4 = "xhs_creep_silencing_glaive",

	-- Dragons
	npc_dota_creature_green_dragon = "xhs_creep_scorching_breath",
	npc_dota_creature_red_dragon = "xhs_creep_corrosive_scales",
	npc_dota_creature_blue_dragon = "xhs_creep_toxic_flight",

	-- Phase 2 assault and tower punishments
	npc_ghul_II = "xhs_creep_unholy_sustain",
	npc_orc_II = "xhs_creep_endurance",
	xhs_death_revenant = "xhs_creep_static_charge",
	xhs_death_revenant_2 = "xhs_creep_death_surge",
	npc_magnataur_destroyer_crypt = "xhs_creep_war_leader",

	-- Special waves (Farm Event targets intentionally excluded)
	npc_dota_creature_necrolyte_event_1 = "xhs_creep_death_aura",
	npc_dota_creature_naga_siren_event_2 = "xhs_creep_riposte",
	npc_dota_creature_vengeful_spirit_event_3 = "xhs_creep_vengeance_aura",
	npc_dota_creature_captain_event_4 = "xhs_creep_command_aura",
	npc_dota_creature_slardar_event_5 = "xhs_creep_crushing_armor",
	npc_dota_creature_chaos_knight_event_6 = "xhs_creep_chaos_strike",
	npc_dota_creature_luna_event_7 = "xhs_creep_moon_glaive",
	npc_dota_creature_clockwerk_event_8 = "xhs_creep_reactive_armor",

	-- Final wave creeps (boss variants intentionally excluded)
	npc_abomination_final_wave = "xhs_creep_plague_cloud",
	npc_banshee_final_wave = "xhs_creep_spell_ward",
	npc_necro_final_wave = "xhs_creep_death_aura",
	npc_magnataur_final_wave = "xhs_creep_war_leader",
	npc_tauren_final_wave = "xhs_creep_endurance",
	npc_chaos_orc_final_wave = "xhs_creep_chaos_strike",
	npc_warlock_final_wave = "xhs_creep_fel_ward",
	npc_orc_raider_final_wave = "xhs_creep_crippling_strike",
	npc_druid_final_wave = "xhs_creep_thorns",
	npc_guard_final_wave = "xhs_creep_evasion",
	npc_keeper_final_wave = "xhs_creep_restoration",
	npc_luna_final_wave = "xhs_creep_moon_glaive",
	npc_captain_final_wave = "xhs_creep_command_aura",
	npc_marine_final_wave = "xhs_creep_double_tap",
	npc_knight_final_wave = "xhs_creep_knights_guard",
}

local LEGACY_PASSIVES = {
	"holdout_lunar_glaive",
	"dragon_knight_dragon_blood",
	"weaver_geminate_attack",
	"huskar_berserkers_blood",
	"undead_disease_cloud",
	"ursa_fury_swipes",
	"antimage_mana_break",
	"chaos_knight_chaos_strike",
	"nevermore_dark_lord",
	"viper_corrosive_skin",
	"lich_frost_beast_cold_skin",
	"xhs_creeps_phase_2_unholy_aura",
	"xhs_creeps_phase_2_endurance_aura",
	"unholy_aura",
	"command_aura",
	"devotion_aura",
	"grom_devotion_aura",
	"demonhunter_vampiric_aura",
	"demonhunter_evasion",
}

function XHSCreepPassives:GetRegistry()
	return REGISTRY
end

function XHSCreepPassives:GetPassiveForUnit(unit_name)
	return REGISTRY[unit_name]
end

function XHSCreepPassives:Apply(unit, difficulty)
	if unit == nil or unit:IsNull() then return false end

	local passive_name = REGISTRY[unit:GetUnitName()]
	if passive_name == nil then return false end

	for _, legacy_name in ipairs(LEGACY_PASSIVES) do
		if legacy_name ~= passive_name and unit:HasAbility(legacy_name) then
			local legacy_ability = unit:FindAbilityByName(legacy_name)
			local intrinsic_name = legacy_ability
				and legacy_ability.GetIntrinsicModifierName
				and legacy_ability:GetIntrinsicModifierName()
			unit:RemoveAbility(legacy_name)
			if intrinsic_name and intrinsic_name ~= "" and unit:HasModifier(intrinsic_name) then
				unit:RemoveModifierByName(intrinsic_name)
			end
		end
	end

	local ability = unit:FindAbilityByName(passive_name)
	if ability == nil then
		ability = unit:AddAbility(passive_name)
	end
	if ability == nil then
		print("[XHSCreepPassives] Failed to add " .. passive_name .. " to " .. unit:GetUnitName())
		return false
	end

	difficulty = math.max(1, math.min(5, tonumber(difficulty) or 1))
	ability:SetLevel(difficulty)
	unit.xhs_creep_passive_name = passive_name
	return true
end

function XHSCreepPassives:ValidateRuntime()
	local errors = {}
	for unit_name, ability_name in pairs(REGISTRY) do
		local unit_kv = GetUnitKeyValuesByName(unit_name)
		if unit_kv == nil then
			table.insert(errors, "missing unit: " .. unit_name)
		end
		if ability_name:sub(1, 10) ~= "xhs_creep_" then
			table.insert(errors, "invalid passive prefix for " .. unit_name .. ": " .. ability_name)
		end
	end
	return errors
end
