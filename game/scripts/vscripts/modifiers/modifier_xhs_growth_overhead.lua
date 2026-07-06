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
	self.pfx = ParticleManager:CreateParticle(GROWTH_OVERHEAD_PARTICLE, PATTACH_OVERHEAD_FOLLOW, self:GetParent())
	self:UpdateOverheadValue(params.growth_value)
end

function modifier_xhs_growth_overhead:OnRefresh(params)
	if not IsServer() then return end

	params = params or {}
	self:UpdateOverheadValue(params.growth_value)
end

function modifier_xhs_growth_overhead:OnDestroy()
	if not IsServer() then return end

	if self.pfx then
		ParticleManager:DestroyParticle(self.pfx, false)
		ParticleManager:ReleaseParticleIndex(self.pfx)
		self.pfx = nil
	end
end

function modifier_xhs_growth_overhead:UpdateOverheadValue(value)
	value = math.max(0, tonumber(value) or 0)
	self:SetStackCount(value)

	if self.pfx then
		ParticleManager:SetParticleControl(self.pfx, 1, Vector(0, value, 0))
	end
end
