modifier_xhs_growth_overhead = modifier_xhs_growth_overhead or class({})
modifier_xhs_growth_overhead.XHS_LINK_CLIENT = true

local GROWTH_OVERHEAD_PARTICLE = "particles/custom/xhs_growth_overhead.vpcf"
local GROWTH_OVERHEAD_HEIGHT = 96
local GROWTH_OVERHEAD_DIGIT_SPACING = 20

function modifier_xhs_growth_overhead:IsHidden() return true end

function modifier_xhs_growth_overhead:IsPurgable() return false end

function modifier_xhs_growth_overhead:IsPurgeException() return false end

function modifier_xhs_growth_overhead:RemoveOnDeath() return true end

function modifier_xhs_growth_overhead:OnCreated(params)
	if not IsServer() then return end

	params = params or {}
	self.pfxs = {}
	self:UpdateOverheadValue(params.growth_value)
end

function modifier_xhs_growth_overhead:OnRefresh(params)
	if not IsServer() then return end

	params = params or {}
	self:UpdateOverheadValue(params.growth_value)
end

function modifier_xhs_growth_overhead:OnDestroy()
	if not IsServer() then return end
	self:DestroyOverheadParticles()
end

function modifier_xhs_growth_overhead:DestroyOverheadParticles()
	for _, particle in ipairs(self.pfxs or {}) do
		ParticleManager:DestroyParticle(particle, false)
		ParticleManager:ReleaseParticleIndex(particle)
	end
	self.pfxs = {}
end

function modifier_xhs_growth_overhead:UpdateOverheadValue(value)
	value = math.max(0, math.floor(tonumber(value) or 0))
	self:SetStackCount(value)
	self:DestroyOverheadParticles()

	local text = tostring(value)
	local center = (#text + 1) * 0.5
	local parent = self:GetParent()

	for index = 1, #text do
		local digit = tonumber(text:sub(index, index)) or 0
		local screen_offset = (index - center) * GROWTH_OVERHEAD_DIGIT_SPACING
		local particle = ParticleManager:CreateParticle(GROWTH_OVERHEAD_PARTICLE, PATTACH_OVERHEAD_FOLLOW, parent)
		ParticleManager:SetParticleControlOffset(particle, 0, Vector(screen_offset, 0, GROWTH_OVERHEAD_HEIGHT))
		ParticleManager:SetParticleControl(particle, 1, Vector(0, digit, 0))
		table.insert(self.pfxs, particle)
	end
end
