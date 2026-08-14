-- Credits: EarthSalamander #42
-- Date (DD/MM/YYYY): 14/12/2018

LinkLuaModifier("modifier_orb_of_darkness_passive", "items/item_orb_of_darkness.lua", LUA_MODIFIER_MOTION_NONE)

require("items/orb_toggle")

local function IsValidEntity(entity)
	return entity ~= nil and not entity:IsNull()
end

item_orb_of_darkness = item_orb_of_darkness or class({})

function item_orb_of_darkness:GetIntrinsicModifierName()
	return "modifier_orb_of_darkness_passive"
end

function item_orb_of_darkness:GetAbilityTextureName()
	return "custom/orb_of_darkness"
end

item_orb_of_darkness2 = item_orb_of_darkness2 or class({})

function item_orb_of_darkness2:GetIntrinsicModifierName()
	return "modifier_orb_of_darkness_passive"
end

function item_orb_of_darkness2:GetAbilityTextureName()
	return "custom/orb_of_darkness2"
end

item_bracer_of_the_void = item_bracer_of_the_void or class({})

function item_bracer_of_the_void:GetIntrinsicModifierName()
	return "modifier_orb_of_darkness_passive"
end

function item_bracer_of_the_void:GetAbilityTextureName()
	return "custom/bracer_of_the_void"
end

modifier_orb_of_darkness_passive = modifier_orb_of_darkness_passive or class({})
modifier_orb_of_darkness_passive.XHS_LINK_CLIENT = true

function modifier_orb_of_darkness_passive:IsHidden() return true end

function modifier_orb_of_darkness_passive:IsPurgable() return false end

function modifier_orb_of_darkness_passive:IsPurgeException() return false end

function modifier_orb_of_darkness_passive:IsDebuff() return false end

function modifier_orb_of_darkness_passive:RemoveOnDeath() return false end

function modifier_orb_of_darkness_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_orb_of_darkness_passive:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
	}
end

function modifier_orb_of_darkness_passive:GetModifierPreAttack_BonusDamage()
	return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_orb_of_darkness_passive:GetModifierHealthBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_hp")
end

function modifier_orb_of_darkness_passive:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_orb_of_darkness_passive:GetModifierConstantHealthRegen()
	return self:GetAbility():GetSpecialValueFor("bonus_health_regen")
end
