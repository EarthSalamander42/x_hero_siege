-- Author: Cookies
-- Date: 22.11.201

-----------------------
--    MORBID MASK    --
-----------------------

item_lifesteal_mask = class({})

function item_lifesteal_mask:GetIntrinsicModifierName()
	return "modifier_lifesteal"
end

function item_lifesteal_mask:GetAbilityTextureName()
	return "custom/lifesteal_mask"
end
