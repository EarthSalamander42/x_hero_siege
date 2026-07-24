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
local WARD_BUFF_PARTICLE = "particles/units/heroes/hero_juggernaut/juggernaut_healing_ward_variation02.vpcf"

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
	self:ReadRegeneration()
end

function modifier_healing_ward_datadriven:OnRefresh()
	self:ReadRegeneration()
end

function modifier_healing_ward_datadriven:ReadRegeneration()
	local ability = self:GetAbility()
	self.regenFlat = ability ~= nil and ability:GetSpecialValueFor("bonus_health_regen_flat") or 0
	self.regenPct = ability ~= nil and ability:GetSpecialValueFor("bonus_health_regen") or 0
end

function modifier_healing_ward_datadriven:GetEffectiveRegeneration()
	local parent = self:GetParent()
	return (self.regenFlat or 0) + parent:GetMaxHealth() * (self.regenPct or 0) * 0.01
end

function modifier_healing_ward_datadriven:IsStrongestSource()
	local parent = self:GetParent()
	local modifiers = parent:FindAllModifiersByName("modifier_healing_ward_datadriven")
	local greaterModifiers = parent:FindAllModifiersByName("modifier_healing_ward2_datadriven")
	for _, modifier in pairs(greaterModifiers) do
		modifiers[#modifiers + 1] = modifier
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

function modifier_healing_ward_datadriven:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
	}
end

function modifier_healing_ward_datadriven:GetModifierConstantHealthRegen()
	return self:IsStrongestSource() and (self.regenFlat or 0) or 0
end

function modifier_healing_ward_datadriven:GetModifierHealthRegenPercentage()
	return self:IsStrongestSource() and (self.regenPct or 0) or 0
end
