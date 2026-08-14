local WAVE_STAT_BONUS = 0.20

modifier_xhs_phase_one_wave_scaling = class({})
modifier_xhs_phase_one_wave_scaling.XHS_LINK_CLIENT = true

function modifier_xhs_phase_one_wave_scaling:IsHidden()
	return false
end

function modifier_xhs_phase_one_wave_scaling:IsPurgable()
	return false
end

function modifier_xhs_phase_one_wave_scaling:RemoveOnDeath()
	return false
end

function modifier_xhs_phase_one_wave_scaling:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT
end

function modifier_xhs_phase_one_wave_scaling:GetTexture()
	return "item_assault"
end

function modifier_xhs_phase_one_wave_scaling:OnCreated(kv)
	kv = kv or {}
	self.level = math.max(1, math.min(4, tonumber(kv.level) or self.level or 1))
	self.progress = math.max(0, math.min(1, tonumber(kv.progress) or self.progress or 0))

	-- Tier balancing lives in the unit KV. This modifier only represents the
	-- positive wave-by-wave growth visible to players.
	self.healthDamagePct = WAVE_STAT_BONUS * self.progress * 100
	self.armorPct = WAVE_STAT_BONUS * self.progress * 100

	local parent = self:GetParent()
	local baseArmor = parent.GetPhysicalArmorBaseValue ~= nil
		and parent:GetPhysicalArmorBaseValue()
		or parent:GetPhysicalArmorValue(false)
	local armorMultiplier = 1.0 + self.armorPct * 0.01
	local scaledArmor = math.floor(baseArmor * armorMultiplier * 10 + 0.5) / 10
	self.armorBonus = scaledArmor - baseArmor

	if IsServer() then
		self:SetHasCustomTransmitterData(true)
		self:SetStackCount(self.level)
		self:SendBuffRefreshToClients()
	end
end

function modifier_xhs_phase_one_wave_scaling:OnRefresh(kv)
	self:OnCreated(kv)
end

function modifier_xhs_phase_one_wave_scaling:AddCustomTransmitterData()
	return {
		level = self.level or 1,
		progress = self.progress or 0,
		health_damage_pct = self.healthDamagePct or 0,
		armor_pct = self.armorPct or 0,
		armor_bonus = self.armorBonus or 0,
	}
end

function modifier_xhs_phase_one_wave_scaling:HandleCustomTransmitterData(data)
	self.level = tonumber(data.level) or 1
	self.progress = tonumber(data.progress) or 0
	self.healthDamagePct = tonumber(data.health_damage_pct) or 0
	self.armorPct = tonumber(data.armor_pct) or 0
	self.armorBonus = tonumber(data.armor_bonus) or 0
end

function modifier_xhs_phase_one_wave_scaling:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_EXTRA_HEALTH_PERCENTAGE,
		MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_TOOLTIP,
		MODIFIER_PROPERTY_TOOLTIP2,
	}
end

function modifier_xhs_phase_one_wave_scaling:GetModifierExtraHealthPercentage()
	return self.healthDamagePct or 0
end

function modifier_xhs_phase_one_wave_scaling:GetModifierBaseDamageOutgoing_Percentage()
	return self.healthDamagePct or 0
end

function modifier_xhs_phase_one_wave_scaling:GetModifierPhysicalArmorBonus()
	return self.armorBonus or 0
end

function modifier_xhs_phase_one_wave_scaling:OnTooltip()
	return self.healthDamagePct or 0
end

function modifier_xhs_phase_one_wave_scaling:OnTooltip2()
	return self.armorPct or 0
end
