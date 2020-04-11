-- Author: Cookies
-- Date: 05.12.2019

LinkLuaModifier("modifier_key_passives", "items/item_key_of_the_three_moons.lua", LUA_MODIFIER_MOTION_NONE)

item_key_of_the_three_moons = item_key_of_the_three_moons or class({})

function item_key_of_the_three_moons:GetIntrinsicModifierName()
	return "modifier_key_passives"
end

modifier_key_passives = modifier_key_passives or class({})

function modifier_key_passives:IsHidden() return true end

function modifier_key_passives:DeclareFunctions() return {
	MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
	MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
	MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
} end

function modifier_key_passives:GetModifierBonusStats_Strength()
	return self:GetAbility():GetSpecialValueFor("bonus_stats")
end

function modifier_key_passives:GetModifierBonusStats_Agility()
	return self:GetAbility():GetSpecialValueFor("bonus_stats")
end

function modifier_key_passives:GetModifierBonusStats_Intellect()
	return self:GetAbility():GetSpecialValueFor("bonus_stats")
end
