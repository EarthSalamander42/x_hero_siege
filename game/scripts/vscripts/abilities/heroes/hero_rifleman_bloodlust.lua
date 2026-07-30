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
		bonus_movement_speed = self:GetSpecialValueFor("bonus_movement_speed"),
		bonus_attack_speed = self:GetSpecialValueFor("bonus_attack_speed"),
		bonus_attack_damage_pct = self:GetSpecialValueFor("bonus_attack_damage_pct"),
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

function modifier_rifleman_bloodlust:RefreshSpecialValues(params)
	params = params or {}
	self.bonus_movement_speed =
		tonumber(params.bonus_movement_speed) or self.bonus_movement_speed or 0
	self.bonus_attack_speed =
		tonumber(params.bonus_attack_speed) or self.bonus_attack_speed or 0
	self.bonus_attack_damage_pct =
		tonumber(params.bonus_attack_damage_pct) or self.bonus_attack_damage_pct or 0
	local ability = self:GetAbility()
	if ability == nil or (ability.IsNull ~= nil and ability:IsNull()) then return end
	self.bonus_movement_speed = ability:GetSpecialValueFor("bonus_movement_speed")
	self.bonus_attack_speed = ability:GetSpecialValueFor("bonus_attack_speed")
	self.bonus_attack_damage_pct = ability:GetSpecialValueFor("bonus_attack_damage_pct")
end

function modifier_rifleman_bloodlust:OnCreated(params)
	self.bonus_movement_speed = 0
	self.bonus_attack_speed = 0
	self.bonus_attack_damage_pct = 0
	self:RefreshSpecialValues(params)
end

function modifier_rifleman_bloodlust:OnRefresh(params)
	self:RefreshSpecialValues(params)
end

function modifier_rifleman_bloodlust:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
	}
end

function modifier_rifleman_bloodlust:GetModifierMoveSpeedBonus_Percentage()
	return self.bonus_movement_speed or 0
end

function modifier_rifleman_bloodlust:GetModifierAttackSpeedBonus_Constant()
	return self.bonus_attack_speed or 0
end

function modifier_rifleman_bloodlust:GetModifierBaseDamageOutgoing_Percentage()
	return self.bonus_attack_damage_pct or 0
end
