function MarkOfTheClaw(keys)
local caster = keys.caster
local target = keys.target
local ability = keys.ability
local ability_level = ability:GetLevel() - 1
local radius = ability:GetLevelSpecialValueFor("radius", ability_level) 
local bonus_damage = ability:GetLevelSpecialValueFor("bonus_damage", ability_level) 
local target_exists = false
local splash_percent = ability:GetLevelSpecialValueFor("splash_percent", ability_level) / 100
local splash_radius = FindUnitsInRadius(caster:GetTeam(), target:GetAbsOrigin() , nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, 0, 0, false)
local attack_damage = caster:GetAttackDamage() * splash_percent

	local damage_table = {}
	damage_table.attacker = caster
	damage_table.damage_type = DAMAGE_TYPE_PHYSICAL
	damage_table.damage = attack_damage + bonus_damage

	for i,v in ipairs(splash_radius) do
		if v ~= target then
			if not target_exists then
				damage_table.damage = attack_damage + bonus_damage
				damage_table.victim = v
				ApplyDamage(damage_table)
			else
				target_exists = false
			end
		end
	end
end

function StrengthOfTheWild(keys)
local caster = keys.caster
local target = keys.target
local ability = keys.ability
local ability_level = ability:GetLevel() - 1
local hero_mult = ability:GetLevelSpecialValueFor("damage_mult_hero", ability_level) -1 -- -1 again to remove the base attack damage
local creep_mult = ability:GetLevelSpecialValueFor("damage_mult_creep", ability_level) -1
local hero_damage = caster:GetAttackDamage() * hero_mult
local creep_damage = caster:GetAttackDamage() * creep_mult

	if target:IsConsideredHero() or target:IsHero() then
		ApplyDamage({ victim = target, attacker = caster, damage = hero_damage,	damage_type = DAMAGE_TYPE_PHYSICAL })
	elseif target:IsCreep() then
		ApplyDamage({ victim = target, attacker = caster, damage = creep_damage, damage_type = DAMAGE_TYPE_PHYSICAL })
	end
end

function TrueFormStart(event)
local caster = event.caster
local model = event.model
local ability = event.ability
local BAT = caster:GetBaseAttackTime()
local BAT_Dec = ability:GetLevelSpecialValueFor("bat_reduction", ability:GetLevel()-1)

	-- Saves the original model and attack capability
	if caster.caster_model == nil then 
		caster.caster_model = caster:GetModelName()
	end
	caster.caster_attack = caster:GetAttackCapability()

	-- Sets the new model
	caster:SetOriginalModel(model)

	-- Swap sub_ability
	local sub_ability_name = event.sub_ability_name
	local main_ability_name = ability:GetAbilityName()

	caster:SwapAbilities(main_ability_name, sub_ability_name, false, true)
	caster:SetBaseAttackTime( BAT + BAT_Dec )
end

-- Reverts back to the original model and attack type, swaps abilities, removes modifier passed
function TrueFormEnd( event )
local caster = event.caster
local ability = event.ability
local BAT = caster:GetBaseAttackTime()
local BAT_Dec = ability:GetLevelSpecialValueFor("bat_reduction", ability:GetLevel()-1)
local modifier = event.remove_modifier_name

	caster:SetModel(caster.caster_model)
	caster:SetOriginalModel(caster.caster_model)

	-- Swap the sub_ability back to normal
	local main_ability_name = event.main_ability_name
	local sub_ability_name = ability:GetAbilityName()

	caster:SwapAbilities(sub_ability_name, main_ability_name, false, true)
	caster:RemoveModifierByName(modifier)
	caster:SetBaseAttackTime( BAT - BAT_Dec )
end
