LinkLuaModifier("modifier_rune_armor", "items/item_rune_armor.lua", LUA_MODIFIER_MOTION_NONE)

item_rune_armor = item_rune_armor or class({})

function item_rune_armor:OnSpellStart()
	if not IsServer() then return end

	self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_rune_armor", {duration = self:GetSpecialValueFor("duration")})
	self:GetCaster():EmitSound("Rune.Regen")
	PickupRune(self, self:GetCaster())
	self:GetCaster():RemoveItem(self)
end

modifier_rune_armor = modifier_rune_armor or class({})

function modifier_rune_armor:GetTexture() return "tower_armor_aura" end
function modifier_rune_armor:GetEffectName() return "particles/units/heroes/hero_dazzle/dazzle_armor_friend.vpcf" end
function modifier_rune_armor:GetEffectAttachType() return PATTACH_OVERHEAD_FOLLOW end

function modifier_rune_armor:DeclareFunctions() return {
	MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
} end

function modifier_rune_armor:OnCreated()
	self.bonus_armor = self:GetAbility():GetSpecialValueFor("bonus_armor")

	if not IsServer() then return end
end

function modifier_rune_armor:GetModifierPhysicalArmorBonus()
	return self.bonus_armor
end
