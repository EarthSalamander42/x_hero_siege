modifier_xhs_growth_overhead = modifier_xhs_growth_overhead or class({})
modifier_xhs_growth_overhead.XHS_LINK_CLIENT = true

local GROWTH_OVERHEAD_PARTICLE = "particles/custom/xhs_growth_overhead.vpcf"

function modifier_xhs_growth_overhead:IsHidden() return true end

function modifier_xhs_growth_overhead:IsPurgable() return false end

function modifier_xhs_growth_overhead:IsPurgeException() return false end

function modifier_xhs_growth_overhead:RemoveOnDeath() return true end

function modifier_xhs_growth_overhead:OnCreated(params)
	if not IsServer() then return end

	params = params or {}
	self:UpdateOverheadValue(params.growth_value)
end

function modifier_xhs_growth_overhead:OnRefresh(params)
	if not IsServer() then return end

	params = params or {}
	self:UpdateOverheadValue(params.growth_value)
end

function modifier_xhs_growth_overhead:OnDestroy()
	if not IsServer() then return end
	self:DestroyOverheadParticle()
end

function modifier_xhs_growth_overhead:DestroyOverheadParticle()
	if not self.pfx then return end

	ParticleManager:DestroyParticle(self.pfx, false)
	ParticleManager:ReleaseParticleIndex(self.pfx)
	self.pfx = nil
end

function modifier_xhs_growth_overhead:UpdateOverheadValue(value)
	value = math.min(999, math.max(0, math.floor(tonumber(value) or 0)))
	self:SetStackCount(value)
	self:DestroyOverheadParticle()

	local digit_count = value >= 100 and 3 or (value >= 10 and 2 or 1)
	local units = value % 10
	local tens = math.floor(value / 10) % 10
	local hundreds = math.floor(value / 100) % 10

	self.pfx = ParticleManager:CreateParticle(GROWTH_OVERHEAD_PARTICLE, PATTACH_OVERHEAD_FOLLOW, self:GetParent())
	ParticleManager:SetParticleControl(self.pfx, 1, Vector(digit_count, 0, 0))
	ParticleManager:SetParticleControl(self.pfx, 2, Vector(hundreds, tens, units))
end
