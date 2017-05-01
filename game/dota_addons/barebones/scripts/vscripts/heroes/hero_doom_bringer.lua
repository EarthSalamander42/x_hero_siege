--Author: Pizzalol, igo95862, Noya
function Devour(keys)
local caster = keys.caster
local target = keys.target
local ability = keys.ability
local ability_level = ability:GetLevel() - 1

-- Ability variables
local target_hp = target:GetHealth()
local health_per_second = ability:GetLevelSpecialValueFor("health_per_second", ability_level)
local modifier = keys.modifier
local modifier_duration = target_hp/health_per_second

	-- Apply the modifier and kill the target
	ability:ApplyDataDrivenModifier(caster, caster, modifier, {duration = modifier_duration})
	target:Kill(ability, caster)
	caster:RemoveModifierByName("modifier_endurance_aura")
	caster:RemoveModifierByName("modifier_command_aura")
	caster:RemoveModifierByName("modifier_aura_of_blight")

-- Setting up the table for allowed devour targets
local devour_table = {}
local doom_empty1 = keys.doom_empty1
local doom_empty2 = keys.doom_empty2

-- Insert the names of the units that you want to be valid targets for ability stealing
table.insert(devour_table, "npc_xhs_undead_creep_melee_1")
table.insert(devour_table, "npc_xhs_elf_creep_melee_1")
table.insert(devour_table, "npc_xhs_orc_creep_melee_1")
table.insert(devour_table, "npc_xhs_human_creep_melee_1")
table.insert(devour_table, "npc_xhs_undead_creep_ranged_1")
table.insert(devour_table, "npc_xhs_elf_creep_ranged_1")
table.insert(devour_table, "npc_xhs_orc_creep_ranged_1")
table.insert(devour_table, "npc_xhs_human_creep_ranged_1")
table.insert(devour_table, "npc_xhs_undead_creep_melee_2")
table.insert(devour_table, "npc_xhs_elf_creep_melee_2")
table.insert(devour_table, "npc_xhs_orc_creep_melee_2")
table.insert(devour_table, "npc_xhs_human_creep_melee_2")
table.insert(devour_table, "npc_xhs_undead_creep_ranged_2")
table.insert(devour_table, "npc_xhs_elf_creep_ranged_2")
table.insert(devour_table, "npc_xhs_orc_creep_ranged_2")
table.insert(devour_table, "npc_xhs_human_creep_ranged_2")
table.insert(devour_table, "npc_xhs_undead_creep_melee_3")
table.insert(devour_table, "npc_xhs_elf_creep_melee_3")
table.insert(devour_table, "npc_xhs_orc_creep_melee_3")
table.insert(devour_table, "npc_xhs_human_creep_melee_3")
table.insert(devour_table, "npc_xhs_undead_creep_ranged_3")
table.insert(devour_table, "npc_xhs_elf_creep_ranged_3")
table.insert(devour_table, "npc_xhs_orc_creep_ranged_3")
table.insert(devour_table, "npc_xhs_human_creep_ranged_3")
table.insert(devour_table, "npc_xhs_undead_creep_melee_4")
table.insert(devour_table, "npc_xhs_elf_creep_melee_4")
table.insert(devour_table, "npc_xhs_orc_creep_melee_4")
table.insert(devour_table, "npc_xhs_human_creep_melee_4")
table.insert(devour_table, "npc_xhs_undead_creep_ranged_4")
table.insert(devour_table, "npc_xhs_elf_creep_ranged_4")
table.insert(devour_table, "npc_xhs_orc_creep_ranged_4")
table.insert(devour_table, "npc_xhs_human_creep_ranged_4")
table.insert(devour_table, "npc_dota_creature_polar_furbolg")
table.insert(devour_table, "npc_dota_creature_razormane")
table.insert(devour_table, "npc_dota_creature_revenant")
table.insert(devour_table, "npc_dota_creature_satyrr")

	-- Checks if the killed unit is in the table for allowed targets
	for _,v in ipairs(devour_table) do
		if target:GetUnitName() == v then
			-- Get the first two abilities
			local ability1 = target:GetAbilityByIndex(0)
			local ability2 = target:GetAbilityByIndex(1)

			-- If we already devoured a target and stole an ability from before then clear it
			if caster.devour_ability1 then
				caster:SwapAbilities(doom_empty1, caster.devour_ability1, true, false)
				caster:RemoveAbility(caster.devour_ability1)
			end

			if caster.devour_ability2 then
				caster:SwapAbilities(doom_empty2, caster.devour_ability2, true, false) 
				caster:RemoveAbility(caster.devour_ability2)
			end

			-- Checks if the ability actually exist on the target
			if ability1 then
				-- Get the name and add it to the caster
				local ability1_name = ability1:GetAbilityName()
				caster:AddAbility(ability1_name)

				-- Make the stolen ability active, level it up and save it in the caster handle for later checks
				caster:SwapAbilities(doom_empty1, ability1_name, false, true)
				caster.devour_ability1 = ability1_name
				caster:FindAbilityByName(ability1_name):SetLevel(ability1:GetLevel())
			end

			-- Checks if the ability actually exist on the target
			if ability2 then
				-- Get the name and add it to the caster
				local ability2_name = ability2:GetAbilityName()
				caster:AddAbility(ability2_name)

				-- Make the stolen ability active, level it up and save it in the caster handle for later checks
				caster:SwapAbilities(doom_empty2, ability2_name, false, true)
				caster.devour_ability2 = ability2_name
				caster:FindAbilityByName(ability2_name):SetLevel(ability2:GetLevel())
			end
		end
	end
end

function DevourGold(keys)
local target = keys.target
local ability = keys.ability
local ability_level = ability:GetLevel() - 1

local bonus_gold = ability:GetLevelSpecialValueFor("bonus_gold", ability_level)

	-- Give the gold only if the target is alive
	if target:IsAlive() then
		target:ModifyGold(bonus_gold, false, 0)
	end
end

function DevourCheck(keys)
local caster = keys.caster
local modifier = keys.modifier
local player = caster:GetPlayerOwner()
local pID = caster:GetPlayerOwnerID()

	if caster:HasModifier(modifier) then
		caster:Interrupt()

		-- Play Error Sound
		EmitSoundOnClient("General.CastFail_InvalidTarget_Hero", player)
	end
end