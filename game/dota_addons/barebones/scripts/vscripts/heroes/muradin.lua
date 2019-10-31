LinkLuaModifier("modifier_muradin_avatar", "heroes/muradin.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_muradin_avatar_buff", "heroes/muradin.lua", LUA_MODIFIER_MOTION_NONE)

muradin_avatar = muradin_avatar or class({})

function muradin_avatar:GetIntrinsicModifierName()
	return "modifier_muradin_avatar"
end

modifier_muradin_avatar = modifier_muradin_avatar or class({})

function modifier_muradin_avatar:IsHidden() return true end

function modifier_muradin_avatar:OnCreated()
	if not IsServer() then return end

	self:StartIntervalThink(_G.XHS_MURADIN_EVENT_DURATION / 2)
end

function modifier_muradin_avatar:OnIntervalThink()
	self:StartIntervalThink(-1)

	Notifications:TopToAll({text="Muradin goes into a frenzy rage!!", duration=5.0})

	self:GetCaster():EmitSound("MountainKing.Avatar")
	self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_muradin_avatar_buff", {duration = self:GetAbility():GetSpecialValueFor("duration")})
end

modifier_muradin_avatar_buff = modifier_muradin_avatar_buff or class({})

function modifier_muradin_avatar_buff:GetHeroEffectName() return "particles/units/heroes/hero_sven/sven_gods_strength_hero_effect.vpcf" end
function modifier_muradin_avatar_buff:HeroEffectPriority() return 10 end
function modifier_muradin_avatar_buff:GetStatusEffectName() return "particles/status_fx/status_effect_gods_strength.vpcf" end
function modifier_muradin_avatar_buff:StatusEffectPriority() return 10 end

function modifier_muradin_avatar_buff:DeclareFunctions() return {
	MODIFIER_PROPERTY_ATTACK_POINT_CONSTANT,
	MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
	MODIFIER_PROPERTY_MODEL_SCALE,
} end

function modifier_muradin_avatar_buff:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("bonus_as")
end

function modifier_muradin_avatar_buff:GetModifierMoveSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("bonus_ms")
end

function modifier_muradin_avatar_buff:GetModifierModelScale()
	return self:GetAbility():GetSpecialValueFor("bonus_model_scale")
end
