LinkLuaModifier("modifier_muradin_avatar", "abilities/heroes/muradin.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_muradin_avatar_buff", "abilities/heroes/muradin.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_muradin_true_strike", "abilities/heroes/muradin.lua", LUA_MODIFIER_MOTION_NONE)

local MURADIN_FRENZY_REMAINING_TIME = 60

muradin_avatar = muradin_avatar or class({})

function muradin_avatar:GetIntrinsicModifierName()
	return "modifier_muradin_avatar"
end

function muradin_avatar:GetAbilityTextureName()
	return "custom/holdout_avatar"
end

modifier_muradin_avatar = modifier_muradin_avatar or class({})
modifier_muradin_avatar.XHS_LINK_CLIENT = true

function modifier_muradin_avatar:IsHidden() return true end

function modifier_muradin_avatar:OnCreated()
	if not IsServer() then return end

	self.frenzy_started = false
	XHS_MURADIN_FRENZY_MODIFIER = self
	self:StartIntervalThink(0.1)
end

function modifier_muradin_avatar:OnDestroy()
	if not IsServer() then return end

	if XHS_MURADIN_FRENZY_MODIFIER == self then
		XHS_MURADIN_FRENZY_MODIFIER = nil
	end
end

function modifier_muradin_avatar:TryStartFrenzy(remaining)
	if self.frenzy_started == true then return false end
	if GameMode == nil or GameMode.Muradin_occuring ~= true then return false end

	remaining = tonumber(remaining)
	if remaining == nil or remaining > MURADIN_FRENZY_REMAINING_TIME then return false end

	local caster = self:GetCaster()
	local ability = self:GetAbility()
	if caster == nil or caster:IsNull() or ability == nil or ability:IsNull() then return false end

	self.frenzy_started = true
	self:StartIntervalThink(-1)

	caster:EmitSound("MountainKing.Avatar")
	caster:AddNewModifier(caster, ability, "modifier_muradin_avatar_buff", {
		duration = ability:GetSpecialValueFor("duration"),
	})

	return true
end

function modifier_muradin_avatar:OnIntervalThink()
	if CustomTimers == nil or CustomTimers.current_time == nil then return end
	if CustomTimers.current_event_timer_paused == true then return end

	self:TryStartFrenzy(CustomTimers.current_time["special_event"])
end

function XHSTriggerMuradinFrenzy(remaining)
	if XHS_MURADIN_FRENZY_MODIFIER == nil then return false end

	return XHS_MURADIN_FRENZY_MODIFIER:TryStartFrenzy(remaining)
end

modifier_muradin_avatar_buff = modifier_muradin_avatar_buff or class({})
modifier_muradin_avatar_buff.XHS_LINK_CLIENT = true

function modifier_muradin_avatar_buff:GetHeroEffectName() return "particles/units/heroes/hero_sven/sven_gods_strength_hero_effect.vpcf" end
function modifier_muradin_avatar_buff:HeroEffectPriority() return 10 end
function modifier_muradin_avatar_buff:GetStatusEffectName() return "particles/status_fx/status_effect_gods_strength.vpcf" end
function modifier_muradin_avatar_buff:StatusEffectPriority() return 10 end
function modifier_muradin_avatar_buff:GetTexture() return "custom/holdout_avatar" end

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

muradin_true_strike = muradin_true_strike or class({})

function muradin_true_strike:GetIntrinsicModifierName()
	return "modifier_muradin_true_strike"
end

modifier_muradin_true_strike = modifier_muradin_true_strike or class({})
modifier_muradin_true_strike.XHS_LINK_CLIENT = true

function modifier_muradin_true_strike:IsHidden() return false end
function modifier_muradin_true_strike:IsPurgable() return false end
function modifier_muradin_true_strike:RemoveOnDeath() return false end
function modifier_muradin_true_strike:GetTexture() return "item_monkey_king_bar" end

function modifier_muradin_true_strike:CheckState()
	return {
		[MODIFIER_STATE_CANNOT_MISS] = true,
	}
end
