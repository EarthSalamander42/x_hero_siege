LinkLuaModifier("modifier_healing_ward", "items/healing_wards.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_healing_ward2", "items/healing_wards.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_healing_ward_datadriven", "items/healing_wards.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_healing_ward2_datadriven", "items/healing_wards.lua", LUA_MODIFIER_MOTION_NONE)

holdout_healing_ward = holdout_healing_ward or class({})
holdout_healing_ward2 = holdout_healing_ward2 or class({})
modifier_healing_ward = modifier_healing_ward or class({})
modifier_healing_ward2 = modifier_healing_ward2 or class({})
modifier_healing_ward_datadriven = modifier_healing_ward_datadriven or class({})
modifier_healing_ward2_datadriven = modifier_healing_ward2_datadriven or class(modifier_healing_ward_datadriven)
modifier_healing_ward.XHS_LINK_CLIENT = true
modifier_healing_ward2.XHS_LINK_CLIENT = true
modifier_healing_ward_datadriven.XHS_LINK_CLIENT = true
modifier_healing_ward2_datadriven.XHS_LINK_CLIENT = true

local WARD_AMBIENT_PARTICLE = "particles/units/heroes/hero_juggernaut/juggernaut_healing_ward.vpcf"
local WARD_ERUPTION_PARTICLE = "particles/units/heroes/hero_juggernaut/juggernaut_healing_ward_eruption.vpcf"
-- The Supporter Pass regen controller owns the recipient visual. Keep the
-- gameplay modifier intact while routing its old persistent PFX to an empty
-- anchor, so equipped regen cosmetics never stack with the legacy effect.
local WARD_BUFF_PARTICLE = "particles/custom/supporter_pass/regen_aura_anchor.vpcf"

local WARD_REGEN_DEFAULTS = {
	modifier_healing_ward_datadriven = {
		flat = 75,
		pct = 0.5,
	},
	modifier_healing_ward2_datadriven = {
		flat = 300,
		pct = 1.0,
	},
}

local function GetWardRegenDefaults(modifier)
	return WARD_REGEN_DEFAULTS[modifier:GetName()] or WARD_REGEN_DEFAULTS.modifier_healing_ward_datadriven
end

function holdout_healing_ward:GetIntrinsicModifierName()
	return "modifier_healing_ward"
end

function holdout_healing_ward2:GetIntrinsicModifierName()
	return "modifier_healing_ward2"
end

local function ConfigureAuraModifier(modifier, auraModifierName)
	function modifier:IsHidden() return true end
	function modifier:IsPurgable() return false end
	function modifier:IsAura() return true end
	function modifier:GetModifierAura() return auraModifierName end
	function modifier:GetAuraRadius() return self:GetAbility():GetSpecialValueFor("aura_radius") end
	function modifier:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
	function modifier:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
	function modifier:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_NOT_ANCIENTS end
	function modifier:GetAuraDuration() return 0.3 end

	function modifier:OnCreated()
		if not IsServer() then return end

		local parent = self:GetParent()
		local radius = self:GetAbility():GetSpecialValueFor("radius")
		local ambient = ParticleManager:CreateParticle(WARD_AMBIENT_PARTICLE, PATTACH_ABSORIGIN_FOLLOW, parent)
		ParticleManager:SetParticleControl(ambient, 1, Vector(radius, 0, radius))
		self:AddParticle(ambient, false, false, -1, false, false)

		local eruption = ParticleManager:CreateParticle(WARD_ERUPTION_PARTICLE, PATTACH_ABSORIGIN_FOLLOW, parent)
		ParticleManager:ReleaseParticleIndex(eruption)
	end
end

ConfigureAuraModifier(modifier_healing_ward, "modifier_healing_ward_datadriven")
ConfigureAuraModifier(modifier_healing_ward2, "modifier_healing_ward2_datadriven")

function modifier_healing_ward_datadriven:IsHidden() return false end
function modifier_healing_ward_datadriven:IsBuff() return true end
function modifier_healing_ward_datadriven:IsPurgable() return false end
function modifier_healing_ward_datadriven:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_healing_ward_datadriven:GetTexture() return "juggernaut_healing_ward" end
function modifier_healing_ward2_datadriven:GetTexture() return "custom/healing_wards2" end
function modifier_healing_ward_datadriven:GetEffectName() return WARD_BUFF_PARTICLE end
function modifier_healing_ward_datadriven:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_healing_ward_datadriven:OnCreated()
	-- Custom transmitter data can reach the client before or after OnCreated.
	-- Never overwrite a payload that has already arrived with local zeroes.
	self.regenFlat = tonumber(self.regenFlat)
	self.regenPct = tonumber(self.regenPct)
	self.effectiveRegen = tonumber(self.effectiveRegen)
	if self.isStrongestSource == nil then
		self.isStrongestSource = true
	end

	if not IsServer() then
		if (self.regenFlat or 0) <= 0 or (self.regenPct or 0) <= 0 then
			self:ReadRegeneration()
		end
		return
	end

	self:SetHasCustomTransmitterData(true)
	self:ReadRegeneration()
	self.clientRefreshesRemaining = 4
	self.nextPeriodicClientRefresh = GameRules:GetGameTime() + 2.0
	self:RefreshClientRegeneration(true)
	self:StartIntervalThink(0.25)
end

function modifier_healing_ward_datadriven:OnRefresh()
	if not IsServer() then return end
	self:ReadRegeneration()
	self:RefreshClientRegeneration(true)
end

function modifier_healing_ward_datadriven:ReadRegeneration()
	local defaults = GetWardRegenDefaults(self)
	local ability = self:GetAbility()
	local regenFlat = ability ~= nil and ability:GetSpecialValueFor("bonus_health_regen_flat") or 0
	local regenPct = ability ~= nil and ability:GetSpecialValueFor("bonus_health_regen") or 0
	self.regenFlat = regenFlat > 0 and regenFlat or defaults.flat
	self.regenPct = regenPct > 0 and regenPct or defaults.pct
	self.effectiveRegen = self:CalculateEffectiveRegeneration()
end

function modifier_healing_ward_datadriven:AddCustomTransmitterData()
	return {
		regen_flat = self.regenFlat or 0,
		regen_pct = self.regenPct or 0,
		effective_regen = self.effectiveRegen or 0,
		is_strongest = self.isStrongestSource == false and 0 or 1,
	}
end

function modifier_healing_ward_datadriven:HandleCustomTransmitterData(data)
	self.regenFlat = tonumber(data.regen_flat) or 0
	self.regenPct = tonumber(data.regen_pct) or 0
	self.effectiveRegen = tonumber(data.effective_regen) or 0
	self.isStrongestSource = tonumber(data.is_strongest) ~= 0
	if self.effectiveRegen <= 0 and (self.regenFlat > 0 or self.regenPct > 0) then
		self.effectiveRegen = self:CalculateEffectiveRegeneration()
	end
end

function modifier_healing_ward_datadriven:CalculateEffectiveRegeneration()
	local parent = self:GetParent()
	return (self.regenFlat or 0) + parent:GetMaxHealth() * (self.regenPct or 0) * 0.01
end

function modifier_healing_ward_datadriven:RefreshClientRegeneration(force)
	if not IsServer() then return end

	local effective = self:CalculateEffectiveRegeneration()
	local isStrongest = self:ComputeIsStrongestSource()
	local strongestChanged = isStrongest ~= self.isStrongestSource
	if force ~= true
		and not strongestChanged
		and math.abs(effective - (self.effectiveRegen or 0)) < 0.01 then
		return
	end

	self.effectiveRegen = effective
	self.isStrongestSource = isStrongest
	self:SendBuffRefreshToClients()
	local parent = self:GetParent()
	if parent ~= nil and parent.CalculateStatBonus ~= nil then
		parent:CalculateStatBonus(true)
	end
end

function modifier_healing_ward_datadriven:OnIntervalThink()
	if not IsServer() then return end

	local now = GameRules:GetGameTime()
	local force = (self.clientRefreshesRemaining or 0) > 0
	if force then
		self.clientRefreshesRemaining = self.clientRefreshesRemaining - 1
	elseif now >= (self.nextPeriodicClientRefresh or 0) then
		force = true
		self.nextPeriodicClientRefresh = now + 2.0
	end

	self:RefreshClientRegeneration(force)
end

function modifier_healing_ward_datadriven:GetEffectiveRegeneration()
	local effective = tonumber(self.effectiveRegen) or 0
	if effective > 0 then return effective end

	if (tonumber(self.regenFlat) or 0) <= 0 or (tonumber(self.regenPct) or 0) <= 0 then
		self:ReadRegeneration()
	end
	return self:CalculateEffectiveRegeneration()
end

function modifier_healing_ward_datadriven:ComputeIsStrongestSource()
	local parent = self:GetParent()
	if parent == nil or parent.FindAllModifiers == nil then return true end
	local modifiers = {}
	for _, modifier in pairs(parent:FindAllModifiers() or {}) do
		local modifierName = modifier:GetName()
		if modifierName == "modifier_healing_ward_datadriven"
			or modifierName == "modifier_healing_ward2_datadriven" then
			modifiers[#modifiers + 1] = modifier
		end
	end
	local best = self
	local bestValue = self:GetEffectiveRegeneration()
	local bestCaster = self:GetCaster()
	local bestIndex = bestCaster ~= nil and bestCaster:entindex() or -1

	for _, modifier in pairs(modifiers) do
		local value = modifier:GetEffectiveRegeneration()
		local caster = modifier:GetCaster()
		local index = caster ~= nil and caster:entindex() or -1
		if value > bestValue or (value == bestValue and index >= 0 and (bestIndex < 0 or index < bestIndex)) then
			best = modifier
			bestValue = value
			bestIndex = index
		end
	end

	return best == self
end

function modifier_healing_ward_datadriven:IsStrongestSource()
	-- FindAllModifiers is server-only. Property and tooltip callbacks also run
	-- in the client VM, where the server's transmitted winner is authoritative.
	if not IsServer() then
		return self.isStrongestSource ~= false
	end

	self.isStrongestSource = self:ComputeIsStrongestSource()
	return self.isStrongestSource
end

function modifier_healing_ward_datadriven:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
		MODIFIER_PROPERTY_TOOLTIP,
	}
end

function modifier_healing_ward_datadriven:GetModifierConstantHealthRegen()
	return self:IsStrongestSource() and (self.regenFlat or 0) or 0
end

function modifier_healing_ward_datadriven:GetModifierHealthRegenPercentage()
	return self:IsStrongestSource() and (self.regenPct or 0) or 0
end

function modifier_healing_ward_datadriven:OnTooltip()
	return self:IsStrongestSource() and self:GetEffectiveRegeneration() or 0
end

-- Source 2 does not consistently expose inherited modifier property callbacks
-- to the client tooltip. Keep the shared implementation, but declare the
-- Greater Ward callbacks directly on its concrete modifier class.
function modifier_healing_ward2_datadriven:OnCreated()
	modifier_healing_ward_datadriven.OnCreated(self)
end

function modifier_healing_ward2_datadriven:OnRefresh()
	modifier_healing_ward_datadriven.OnRefresh(self)
end

function modifier_healing_ward2_datadriven:AddCustomTransmitterData()
	return modifier_healing_ward_datadriven.AddCustomTransmitterData(self)
end

function modifier_healing_ward2_datadriven:HandleCustomTransmitterData(data)
	modifier_healing_ward_datadriven.HandleCustomTransmitterData(self, data)
end

function modifier_healing_ward2_datadriven:OnIntervalThink()
	modifier_healing_ward_datadriven.OnIntervalThink(self)
end

function modifier_healing_ward2_datadriven:DeclareFunctions()
	return modifier_healing_ward_datadriven.DeclareFunctions(self)
end

function modifier_healing_ward2_datadriven:GetModifierConstantHealthRegen()
	return modifier_healing_ward_datadriven.GetModifierConstantHealthRegen(self)
end

function modifier_healing_ward2_datadriven:GetModifierHealthRegenPercentage()
	return modifier_healing_ward_datadriven.GetModifierHealthRegenPercentage(self)
end

function modifier_healing_ward2_datadriven:OnTooltip()
	return modifier_healing_ward_datadriven.OnTooltip(self)
end
