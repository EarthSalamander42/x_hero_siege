LinkLuaModifier("modifier_command_buff", "modifiers/auras/modifier_command_aura.lua", LUA_MODIFIER_MOTION_NONE)

modifier_command_aura = modifier_command_aura or class({})

function modifier_command_aura:IsAura() return true end
function modifier_command_aura:GetAuraDuration() return 0.2 end
function modifier_command_aura:GetAuraRadius() return self:GetAbility():GetSpecialValueFor("radius") end
function modifier_command_aura:GetAuraSearchTeam() return self:GetAbility():GetAbilityTargetTeam() end
function modifier_command_aura:GetAuraSearchType() return self:GetAbility():GetAbilityTargetType() end
function modifier_command_aura:GetAuraSearchFlags() return self:GetAbility():GetAbilityTargetFlags() end
function modifier_command_aura:GetModifierAura() return "modifier_command_buff" end

function modifier_command_aura:IsHidden() return true end
function modifier_command_aura:IsPurgable() return false end
function modifier_command_aura:IsPurgeException() return false end
function modifier_command_aura:RemoveOnDeath() return false end

modifier_command_buff = modifier_command_buff or class({})

function modifier_command_buff:GetTexture()
	return "custom/holdout_command_aura"
end

function modifier_command_buff:DeclareFunctions() return {
	MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
} end

function modifier_command_buff:OnCreated()
	if not IsServer() then return end

	self.pfx = ParticleManager:CreateParticle("particles/items_fx/aura_shivas.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
end

function modifier_command_buff:GetModifierDamageOutgoing_Percentage()
	if not self or not self:GetAbility() then self:OnDestroy() return end

	if self:GetAbility():GetSpecialValueFor("bonus_damage_percentage_self") ~= 0 and self:GetCaster() == self:GetParent() then
		return self:GetAbility():GetSpecialValueFor("bonus_damage_percentage_self")
	else
		return self:GetAbility():GetSpecialValueFor("bonus_damage_percentage")
	end
end

function modifier_command_buff:OnDestroy()
	if not IsServer() then return end

	if self.pfx then
		ParticleManager:DestroyParticle(self.pfx, false)
		ParticleManager:ReleaseParticleIndex(self.pfx)
	end
end
