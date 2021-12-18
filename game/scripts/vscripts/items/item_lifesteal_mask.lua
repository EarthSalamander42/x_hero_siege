-- Author: Cookies
-- Date: 22.11.2016

-----------------------
--    MORBID MASK    --
-----------------------

LinkLuaModifier("modifier_lifesteal", "modifiers/modifier_lifesteal.lua", LUA_MODIFIER_MOTION_NONE)

item_lifesteal_mask = item_lifesteal_mask or class({})

function item_lifesteal_mask:GetIntrinsicModifierName()
	return "modifier_lifesteal"
end
