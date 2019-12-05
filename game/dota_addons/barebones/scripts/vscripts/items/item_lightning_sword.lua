-- Author: Cookies
-- Date: 22.11.2016

-----------------------
--  LIGHTNING SWORD  --
-----------------------

LinkLuaModifier("modifier_lightning_sword_unique", "items/item_lightning_sword.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lifesteal_lightning_sword", "items/item_lightning_sword.lua", LUA_MODIFIER_MOTION_NONE)

item_lightning_sword = item_lightning_sword or class({})

function item_lightning_sword:GetIntrinsicModifierName()
	return "modifier_lightning_sword_unique"
end

modifier_lightning_sword_unique = class({})

function modifier_lightning_sword_unique:IsHidden() return true end
function modifier_lightning_sword_unique:IsDebuff() return false end
function modifier_lightning_sword_unique:IsPurgable() return false end
function modifier_lightning_sword_unique:RemoveOnDeath() return false end

function modifier_lightning_sword_unique:OnCreated()
	if not IsServer() then return end

	if self:GetParent():IsRealHero() and _G.RAMERO_ARTIFACT_PICKED == false then
		_G.RAMERO_ARTIFACT_PICKED = true

		if timers.RameroAndBaristol then
			Timers:RemoveTimer(timers.RameroAndBaristol)
		end

		ReturnFromSpecialArena(self:GetParent())
	end

	if not self:GetParent():HasModifier("modifier_lifesteal_lightning_sword") then
		self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_lifesteal_lightning_sword", {})
	end
end

function modifier_lightning_sword_unique:OnRemoved()
	if IsServer() then
		if not self:GetParent():IsIllusion() then
			self:GetParent().has_epic_3 = false
		end

		if self:GetParent():HasModifier("modifier_lifesteal_lightning_sword") then
			self:GetParent():RemoveModifierByName("modifier_lifesteal_lightning_sword")
		end
	end
end

function modifier_lightning_sword_unique:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	}

	return funcs
end

function modifier_lightning_sword_unique:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_lightning_sword_unique:GetModifierPreAttack_BonusDamage()
	return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

modifier_lifesteal_lightning_sword = class({})

function modifier_lifesteal_lightning_sword:IsHidden() return false end
function modifier_lifesteal_lightning_sword:IsPurgable() return false end
function modifier_lifesteal_lightning_sword:IsDebuff() return false end
function modifier_lifesteal_lightning_sword:RemoveOnDeath() return false end

function modifier_lifesteal_lightning_sword:GetTexture()
	return "modifiers/lightning_sword"
end

function modifier_lifesteal_lightning_sword:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED
	}
end

function modifier_lifesteal_lightning_sword:OnAttackLanded(keys)
	if IsServer() then
		if self:GetParent() == keys.attacker then
			if self:GetParent():HasModifier("modifier_lifesteal_doom_artifact") then
				return
			end

			self:GetParent():Lifesteal(keys.target, self)
		end
	end
end

function modifier_lifesteal_lightning_sword:GetModifierLifesteal()
	return self:GetAbility():GetSpecialValueFor("lifesteal_pct")
end

function modifier_lifesteal_lightning_sword:OnDestroy()
	if IsServer() then
		-- fix with Vampiric Aura interaction
		if self:GetParent():HasItemInInventory("item_lifesteal_mask") or self:GetParent():HasItemInInventory("item_lightning_sword") then
			self:GetParent():AddNewModifier(self:GetParent(), self, "modifier_lifesteal_lightning_sword", {})
		end
	end
end
