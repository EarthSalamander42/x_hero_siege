-- Author: Cookies
-- Date: 22.11.2016

-----------------------
--    MORBID MASK    --
-----------------------

LinkLuaModifier("modifier_lifesteal_mask", "items/item_lifesteal_mask.lua", LUA_MODIFIER_MOTION_NONE)

item_lifesteal_mask = item_lifesteal_mask or class({})

function item_lifesteal_mask:GetIntrinsicModifierName()
	return "modifier_lifesteal_mask"
end

modifier_lifesteal_mask = modifier_lifesteal_mask or class({})

function modifier_lifesteal_mask:GetTexture()
	return "modifiers/lifesteal_mask"
end

function modifier_lifesteal_mask:GetModifierLifesteal()
	return self:GetAbility():GetSpecialValueFor("lifesteal_pct")
end
