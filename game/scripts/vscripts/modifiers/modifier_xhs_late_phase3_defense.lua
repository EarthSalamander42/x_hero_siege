modifier_xhs_late_phase3_physical_resistance = class({})
modifier_xhs_late_phase3_physical_resistance.XHS_LINK_CLIENT = true

function modifier_xhs_late_phase3_physical_resistance:IsHidden()
	return true
end

function modifier_xhs_late_phase3_physical_resistance:IsPurgable()
	return false
end

function modifier_xhs_late_phase3_physical_resistance:RemoveOnDeath()
	return false
end

function modifier_xhs_late_phase3_physical_resistance:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}
end

function modifier_xhs_late_phase3_physical_resistance:GetModifierPhysicalArmorBonus()
	return self:GetStackCount()
end

modifier_xhs_late_phase3_magic_resistance = class({})
modifier_xhs_late_phase3_magic_resistance.XHS_LINK_CLIENT = true

function modifier_xhs_late_phase3_magic_resistance:IsHidden()
	return true
end

function modifier_xhs_late_phase3_magic_resistance:IsPurgable()
	return false
end

function modifier_xhs_late_phase3_magic_resistance:RemoveOnDeath()
	return false
end

function modifier_xhs_late_phase3_magic_resistance:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
	}
end

function modifier_xhs_late_phase3_magic_resistance:GetModifierMagicalResistanceBonus()
	return self:GetStackCount()
end
