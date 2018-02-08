modifier_rune_armor = class({})

function modifier_rune_armor:IsHidden() return false end

function modifier_rune_armor:GetTextureName()
	return "tower_armor_aura"
end

function modifier_rune_armor:GetEffectName()
	return "particles/units/heroes/hero_dazzle/dazzle_armor_friend.vpcf"
end

function modifier_rune_armor:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function modifier_rune_armor:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS_UNIQUE,
	}
	return funcs
end

function modifier_rune_armor:GetModifierPhysicalArmorBonusUnique()
	return 75
end
