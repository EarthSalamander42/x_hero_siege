LinkLuaModifier("modifier_unholy_buff", "modifiers/auras/modifier_unholy_aura.lua", LUA_MODIFIER_MOTION_NONE)

modifier_unholy_aura = modifier_unholy_aura or class({})

function modifier_unholy_aura:IsAura() return true end
function modifier_unholy_aura:GetAuraDuration() return 0.2 end
function modifier_unholy_aura:GetAuraRadius() return self:GetAbility():GetSpecialValueFor("radius") end
function modifier_unholy_aura:GetAuraSearchTeam() return self:GetAbility():GetAbilityTargetTeam() end
function modifier_unholy_aura:GetAuraSearchType() return self:GetAbility():GetAbilityTargetType() end
function modifier_unholy_aura:GetAuraSearchFlags() return self:GetAbility():GetAbilityTargetFlags() end
function modifier_unholy_aura:GetModifierAura() return "modifier_unholy_buff" end

function modifier_unholy_aura:IsHidden() return true end
function modifier_unholy_aura:IsPurgable() return false end
function modifier_unholy_aura:IsPurgeException() return false end
function modifier_unholy_aura:RemoveOnDeath() return false end

modifier_unholy_buff = modifier_unholy_buff or class({})

function modifier_unholy_buff:GetTexture()
	return "custom/holdout_unholy_aura"
end

function modifier_unholy_buff:DeclareFunctions() return {
	MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
	MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
} end

function modifier_unholy_buff:OnCreated()
	if not IsServer() then return end
	if self:GetParent():GetTeam() ~= 2 then return end -- Assuming this is causing massive lag issues in Phase 2

	self.pfx1 = ParticleManager:CreateParticle("particles/econ/courier/courier_faceless_rex/cour_rex_ground_a.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	self.pfx2 = ParticleManager:CreateParticle("particles/econ/courier/courier_roshan_frost/courier_roshan_frost_steam.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
end

function modifier_unholy_buff:GetModifierConstantHealthRegen()
	if not self:GetAbility() then return end

	return self:GetAbility():GetSpecialValueFor("bonus_health_regen")
end

function modifier_unholy_buff:GetModifierMoveSpeedBonus_Constant()
	if not self:GetAbility() then return end

	return self:GetAbility():GetSpecialValueFor("bonus_movement_speed")
end

function modifier_unholy_buff:OnDestroy()
	if not IsServer() then return end

	if self.pfx1 then
		ParticleManager:DestroyParticle(self.pfx1, false)
		ParticleManager:ReleaseParticleIndex(self.pfx1)
	end

	if self.pfx2 then
		ParticleManager:DestroyParticle(self.pfx2, false)
		ParticleManager:ReleaseParticleIndex(self.pfx2)
	end
end
