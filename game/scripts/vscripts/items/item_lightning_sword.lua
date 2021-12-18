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
			_G.RAMERO_ARTIFACT_PICKED = true

			if timers.RameroAndBaristol then
				Timers:RemoveTimer(timers.RameroAndBaristol)
			end

			ReturnFromSpecialArena(self:GetParent())
		end
	end

	self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_lifesteal", {})
end

function modifier_lightning_sword_unique:OnRemoved()
	if IsServer() then
		if not self:GetParent():IsIllusion() then
			self:GetParent().has_epic_3 = false
		end

		for k, v in pairs(self:GetParent():FindAllModifiersByName("modifier_lifesteal")) do
			if v:GetAbility() == self:GetAbility() or v:GetAbility() == nil then
				v:Destroy()
				-- don't break in case multiple modifiers were added with Lightning Sword as ability (bug happens sometimes because modifier_lifesteal is not an intrinsic modifier here)
			end
		end
	end
end

function modifier_lightning_sword_unique:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_lightning_sword_unique:GetModifierPreAttack_BonusDamage()
	return self:GetAbility():GetSpecialValueFor("bonus_damage")
end
