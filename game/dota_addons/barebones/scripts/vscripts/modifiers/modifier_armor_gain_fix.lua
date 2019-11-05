modifier_armor_gain_fix = class({})

function modifier_armor_gain_fix:OnCreated()
	if IsServer() then
		self:StartIntervalThink(1.0)
		self.magical_resistance = 0
	end
end

function modifier_armor_gain_fix:OnIntervalThink()
	if IsServer() then
		self.armor_fix = (self:GetParent():GetAgility() * 0.16) * (-1) -- Don't ask.
	end
end

function modifier_armor_gain_fix:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}
end

function modifier_armor_gain_fix:GetModifierPhysicalArmorBonus()
	return self.armor_fix
end

function modifier_armor_gain_fix:IsHidden() return true end
function modifier_armor_gain_fix:IsPurgable() return false end
function modifier_armor_gain_fix:RemoveOnDeath() return false end
