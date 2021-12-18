-- Lifesteal modifier

modifier_magical_resistance_fix = class({})

function modifier_magical_resistance_fix:OnCreated()
	if IsServer() then
		self:StartIntervalThink(1.0)
		self.magical_resistance = 0
	end
end

function modifier_magical_resistance_fix:OnIntervalThink()


	if self:GetParent():HasModifier("modifier_necklace_of_spell_immunity") then return end

	local magic_resistance = self:GetParent():GetMagicalArmorValue() * 100
	print("Magic Resistance:", magic_resistance)

	if magic_resistance ~= 25 then
		self:GetParent():SetBaseMagicalResistanceValue(25)
	end
end

function modifier_magical_resistance_fix:IsHidden() return false end
function modifier_magical_resistance_fix:IsPurgable() return false end
function modifier_magical_resistance_fix:RemoveOnDeath() return false end
