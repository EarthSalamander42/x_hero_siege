-- Author: Cookies
-- Date: 22.11.2016

-----------------------
--  LIGHTNING SWORD  --
-----------------------

LinkLuaModifier("modifier_lightning_sword_unique", "items/item_lightning_sword.lua", LUA_MODIFIER_MOTION_NONE)

item_lightning_sword = item_lightning_sword or class({})

function item_lightning_sword:GetIntrinsicModifierName()
	return "modifier_lightning_sword_unique"
end

modifier_lightning_sword_unique = class({})

function modifier_lightning_sword_unique:IsHidden() return true end

function modifier_lightning_sword_unique:IsDebuff() return false end

function modifier_lightning_sword_unique:IsPurgable() return false end

function modifier_lightning_sword_unique:RemoveOnDeath() return false end

function modifier_lightning_sword_unique:GetModifierLifesteal() return self:GetAbility():GetSpecialValueFor("lifesteal_pct") end

function modifier_lightning_sword_unique:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	}

	return funcs
end

function modifier_lightning_sword_unique:OnCreated()
	if not IsServer() then return end

	if _G.RAMERO_ARTIFACT_PICKED == false then
		if self:GetParent():IsRealHero() then
			SpecialEvents:EndRameroAndBaristolEvent(true)
		end
	end
end

function modifier_lightning_sword_unique:OnRemoved()
	if IsServer() then
		if not self:GetParent():IsIllusion() then
			self:GetParent().has_epic_3 = false
		end
	end
end

function modifier_lightning_sword_unique:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_lightning_sword_unique:GetModifierPreAttack_BonusDamage()
	return self:GetAbility():GetSpecialValueFor("bonus_damage")
end
