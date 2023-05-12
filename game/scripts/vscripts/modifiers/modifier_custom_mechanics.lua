modifier_custom_mechanics = modifier_custom_mechanics or class({})

function modifier_custom_mechanics:IsHidden() return true end

function modifier_custom_mechanics:IsPurgable() return false end

function modifier_custom_mechanics:RemoveOnDeath() return false end

function modifier_custom_mechanics:DeclareFunctions()
	return {
		--	MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_custom_mechanics:OnCreated()
	self.required_intellect = 16

	if not IsServer() then return end

	--	self:StartIntervalThink(1.0)
	--	self.magical_resistance = 0
	--	self.intellect =
	--	self:SetHasCustomTransmitterData(true)
end

--[[
function modifier_warpath_weaponsmith_basic_arms:AddCustomTransmitterData() return {
	bonus_damage = self.bonus_damage
} end

function modifier_warpath_weaponsmith_basic_arms:HandleCustomTransmitterData(data)
	self.bonus_damage = data.bonus_damage
end
--]]
function modifier_custom_mechanics:OnIntervalThink()
	--	self.armor_fix = (self:GetParent():GetAgility() * 0.16) * (-1) -- Don't ask.
end

function modifier_custom_mechanics:GetModifierPhysicalArmorBonus()
	--	return self.armor_fix
end

function modifier_custom_mechanics:GetModifierSpellAmplify_Percentage()
	return self:GetParent():GetIntellect() * (1 / self.required_intellect)
end

function modifier_custom_mechanics:OnAttackLanded(keys)
	if not IsServer() then return end

	local attacker = keys.attacker

	if self:GetParent() ~= attacker then return end

	local target = keys.target

	if not target or target:IsNull() then return end

	-- If there's no valid target, or lifesteal amount, do nothing
	if target:IsBuilding() or (target:GetTeam() == attacker:GetTeam()) then
		return
	end

	attacker:SendLifestealAttack(target)
end
