-- Credits: EarthSalamander #42
-- Date (DD/MM/YYYY): 14/12/2018

LinkLuaModifier("modifier_lightning_sword_active", "items/item_lightning_sword.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lightning_sword_passive", "items/item_lightning_sword.lua", LUA_MODIFIER_MOTION_NONE)

item_lightning_sword = class({})

function item_lightning_sword:GetIntrinsicModifierName()
	return "modifier_lightning_sword_passive"
end

--------------------------------------------------------------

modifier_lightning_sword_active = class({})

function modifier_lightning_sword_active:IsHidden() return false end
function modifier_lightning_sword_active:IsPurgable() return false end
function modifier_lightning_sword_active:IsPurgeException() return false end
function modifier_lightning_sword_active:IsDebuff() return false end

-- allow multiple instances of that modifier
function modifier_lightning_sword_active:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_lightning_sword_active:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
	}
end

function modifier_lightning_sword_active:GetModifierPreAttack_BonusDamage()
	return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_lightning_sword_active:GetModifierHealthBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_hp")
end

function modifier_lightning_sword_active:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_lightning_sword_active:GetModifierConstantHealthRegen()
	return self:GetAbility():GetSpecialValueFor("bonus_health_regen")
end

--------------------------------------------------------------

modifier_lightning_sword_passive = class({})

function modifier_lightning_sword_passive:IsHidden() return false end
function modifier_lightning_sword_passive:IsPurgable() return false end
function modifier_lightning_sword_passive:IsPurgeException() return false end
function modifier_lightning_sword_passive:IsDebuff() return false end

-- allow multiple instances of that modifier
function modifier_lightning_sword_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_lightning_sword_passive:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
	}
end

function modifier_lightning_sword_passive:GetModifierPreAttack_BonusDamage()
	return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

function modifier_lightning_sword_passive:GetModifierHealthBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_hp")
end

function modifier_lightning_sword_passive:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_lightning_sword_passive:GetModifierConstantHealthRegen()
	return self:GetAbility():GetSpecialValueFor("bonus_health_regen")
end
