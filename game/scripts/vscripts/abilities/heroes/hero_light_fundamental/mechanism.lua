--[[ ============================================================================================================
	Author: Rook
	Date: January 26, 2015
	Called when Mekansm is cast.  Heals nearby units if they have not been healed by a Mekansm recently.
	Additional parameters: keys.HealAmount and keys.HealRadius
================================================================================================================= ]]
function Mechanism(keys)
local caster = keys.caster
local ability = keys.ability
local stacks = caster:GetLevel()
local heal = keys.HealAmount -- 300
local armor = keys.Armor
local hp_regen = keys.HealthRegen
local full_heal = heal * stacks -- 300 * 30 = 9000
local full_armor = armor * stacks -- 5 * 30 = 150

local nearby_allied_units = FindUnitsInRadius(caster:GetTeam(), caster:GetAbsOrigin(), nil, keys.HealRadius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

	caster:EmitSound("DOTA_Item.Mekansm.Activate")
	ParticleManager:CreateParticle("particles/items2_fx/mekanism.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)

	for i, nearby_ally in ipairs(nearby_allied_units) do  --Restore health and play a particle effect for every found ally.
		nearby_ally:Heal(full_heal, caster)
		SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, nearby_ally, full_heal, nil)
		SendOverheadEventMessage(nil, OVERHEAD_ALERT_XP, nearby_ally, full_armor, nil) -- Armor

		nearby_ally:EmitSound("DOTA_Item.Mekansm.Target")
		ParticleManager:CreateParticle("particles/items2_fx/mekanism_recipient.vpcf", PATTACH_ABSORIGIN_FOLLOW, nearby_ally)

		ability:ApplyDataDrivenModifier(caster, nearby_ally, "modifier_mechanism_armor", nil)
		nearby_ally:SetModifierStackCount("modifier_mechanism_armor", ability, stacks)
	end
end
