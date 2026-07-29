LinkLuaModifier(
	"modifier_rifleman_bloodlust",
	"abilities/heroes/hero_rifleman_bloodlust.lua",
	LUA_MODIFIER_MOTION_NONE
)

rifleman_bloodlust = class({})

function rifleman_bloodlust:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	if target == nil or target:IsNull() then return end

	target:AddNewModifier(caster, self, "modifier_rifleman_bloodlust", {
		duration = self:GetSpecialValueFor("duration"),
	})

	local particle = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_ogre_magi/ogre_magi_bloodlust_cast.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		caster
	)
	ParticleManager:SetParticleControlEnt(
		particle,
		1,
		target,
		PATTACH_ABSORIGIN_FOLLOW,
		"attach_hitloc",
		target:GetAbsOrigin(),
		true
	)
	ParticleManager:ReleaseParticleIndex(particle)

	caster:EmitSound("Hero_OgreMagi.Bloodlust.Cast")
	target:EmitSound("Hero_OgreMagi.Bloodlust.Target")
end

modifier_rifleman_bloodlust = class({})
modifier_rifleman_bloodlust.XHS_LINK_CLIENT = true

function modifier_rifleman_bloodlust:IsPurgable()
	return true
end

function modifier_rifleman_bloodlust:GetEffectName()
	return "particles/units/heroes/hero_ogre_magi/ogre_magi_bloodlust_buff.vpcf"
end

function modifier_rifleman_bloodlust:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_rifleman_bloodlust:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
	}
end

function modifier_rifleman_bloodlust:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("bonus_movement_speed")
end

function modifier_rifleman_bloodlust:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("bonus_attack_speed")
end

function modifier_rifleman_bloodlust:GetModifierBaseDamageOutgoing_Percentage()
	return self:GetAbility():GetSpecialValueFor("bonus_attack_damage_pct")
end
