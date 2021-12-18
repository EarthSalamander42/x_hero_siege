LinkLuaModifier("modifier_endurance_buff", "modifiers/auras/modifier_endurance_aura.lua", LUA_MODIFIER_MOTION_NONE)

modifier_endurance_aura = modifier_endurance_aura or class({})

function modifier_endurance_aura:IsAura() return true end
function modifier_endurance_aura:GetAuraDuration() return 0.2 end
function modifier_endurance_aura:GetAuraRadius() return self:GetAbility():GetSpecialValueFor("radius") end
function modifier_endurance_aura:GetAuraSearchTeam() return self:GetAbility():GetAbilityTargetTeam() end
function modifier_endurance_aura:GetAuraSearchType() return self:GetAbility():GetAbilityTargetType() end
function modifier_endurance_aura:GetAuraSearchFlags() return self:GetAbility():GetAbilityTargetFlags() end
function modifier_endurance_aura:GetModifierAura() return "modifier_endurance_buff" end

function modifier_endurance_aura:IsHidden() return true end
function modifier_endurance_aura:IsPurgable() return false end
function modifier_endurance_aura:IsPurgeException() return false end
function modifier_endurance_aura:RemoveOnDeath() return false end

modifier_endurance_buff = modifier_endurance_buff or class({})

function modifier_endurance_buff:GetTexture()
	return "custom/holdout_endurance_aura"
end

function modifier_endurance_buff:DeclareFunctions() return {
	MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT,
	MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, -- only used for phase 2 ghouls
} end

function modifier_endurance_buff:OnCreated()
	if not IsServer() then return end

	self.pfx = ParticleManager:CreateParticle("particles/items_fx/aura_endurance.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
end

function modifier_endurance_buff:GetModifierMoveSpeedBonus_Percentage()
	if not self or not self:GetAbility() then self:OnDestroy() return end

	return self:GetAbility():GetSpecialValueFor("endurance_bonus_movement_speed")
end

function modifier_endurance_buff:GetModifierBaseAttackTimeConstant()
	if not self or not self:GetAbility() then self:OnDestroy() return end

	return self:GetAbility():GetSpecialValueFor("bat_reduction") * (-1)
end

function modifier_endurance_buff:GetModifierAttackSpeedBonus_Constant()
	if not self or not self:GetAbility() then self:OnDestroy() return end

	return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_endurance_buff:OnDestroy()
	if not IsServer() then return end

	if self.pfx then
		ParticleManager:DestroyParticle(self.pfx, false)
		ParticleManager:ReleaseParticleIndex(self.pfx)
	end
end
