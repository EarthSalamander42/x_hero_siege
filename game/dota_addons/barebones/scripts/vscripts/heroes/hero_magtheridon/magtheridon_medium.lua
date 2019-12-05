-- Author: Cookies
-- Date: 05.12.2019

LinkLuaModifier("modifier_ankh_passives", "items/ankh_of_reincarnation.lua", LUA_MODIFIER_MOTION_NONE)

magtheridon_medium = magtheridon_medium or class({})

function magtheridon_medium:GetIntrinsicModifierName()
	return "modifier_ankh_passives"
end
