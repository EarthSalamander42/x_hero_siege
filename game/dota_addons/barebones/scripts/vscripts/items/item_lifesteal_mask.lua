-- Author: Cookies
-- Date: 22.11.2016

-----------------------
--    MORBID MASK    --
-----------------------

LinkLuaModifier("modifier_lifesteal", "items/item_lifesteal_mask.lua", LUA_MODIFIER_MOTION_NONE)

item_lifesteal_mask = class({})

function item_lifesteal_mask:GetIntrinsicModifierName()
	return "modifier_lifesteal"
end

-- Lifesteal modifier
modifier_lifesteal = class({})

function modifier_lifesteal:IsHidden() return false end
function modifier_lifesteal:IsPurgable() return false end
function modifier_lifesteal:IsDebuff() return false end
function modifier_lifesteal:RemoveOnDeath() return false end

function modifier_lifesteal:GetTexture()
	return "modifiers/lifesteal_mask"
end

function modifier_lifesteal:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED
	}
end

function modifier_lifesteal:OnAttackLanded(keys)
	if IsServer() then

--	MODIFIER_ITEMS_WITH_LEVELS["modifier_lifesteal"] = {
--		"item_doom_artifact",
--		"item_lightning_sword",
--		"item_lifesteal_mask",
--	}

--		print("Lifesteal item name:", self:GetAbilityName())

		-- TODO: format me later
--		if self:GetParent():HasItemInInventory("item_lifesteal_mask") and self:GetAbility():GetAbilityName() ~= "item_lifesteal_mask" then
--			print("Lifesteal mask owned but ignored because there's a higher item.")
--			return
--		end

--		if self:GetParent():HasItemInInventory("item_lightning_sword") and self:GetAbility():GetAbilityName() ~= "item_doom_artifact" or self:GetAbility():GetAbilityName() ~= "item_lightning_sword" then
--			print("Lightning Sword owned but ignored because there's a higher item.")
--			return
--		end

		if self:GetParent() == keys.attacker then
			self:GetParent():Lifesteal(keys.target, self)
		end
	end
end

function modifier_lifesteal:GetModifierLifesteal()
	if self:GetAbility() == nil then self:Destroy() return end
	return self:GetAbility():GetSpecialValueFor("lifesteal_pct")
end

function modifier_lifesteal:OnDestroy()
	if IsServer() then
		-- fix with Vampiric Aura interaction
		if self:GetParent():HasItemInInventory("item_lifesteal_mask") or self:GetParent():HasItemInInventory("item_lightning_sword") then
			self:GetParent():AddNewModifier(self:GetParent(), self, "modifier_lifesteal", {})
		end
	end
end
