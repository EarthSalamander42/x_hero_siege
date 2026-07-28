LinkLuaModifier("modifier_muradin_avatar", "abilities/heroes/muradin.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_muradin_avatar_buff", "abilities/heroes/muradin.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_muradin_true_strike", "abilities/heroes/muradin.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_mountain_king_bash", "abilities/heroes/muradin.lua", LUA_MODIFIER_MOTION_NONE)

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

local function IsXHSBossTarget(unit)
	if unit == nil or unit:IsNull() then return false end
	if unit.Boss == true or unit.bBoss == true then return true end
	if unit.boss_count ~= nil or unit.xhs_boss_bar_id ~= nil then return true end

	if XHSIsBossDamageTarget ~= nil then
		local ok, isBoss = pcall(XHSIsBossDamageTarget, unit)
		if ok and isBoss == true then return true end
	end

	return false
end

xhs_mountain_king_bash = xhs_mountain_king_bash or class({})

function xhs_mountain_king_bash:GetIntrinsicModifierName()
	return "modifier_xhs_mountain_king_bash"
end

modifier_xhs_mountain_king_bash = modifier_xhs_mountain_king_bash or class({})
modifier_xhs_mountain_king_bash.XHS_LINK_CLIENT = true

function modifier_xhs_mountain_king_bash:IsHidden() return true end
function modifier_xhs_mountain_king_bash:IsPurgable() return false end

function modifier_xhs_mountain_king_bash:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_xhs_mountain_king_bash:OnCreated()
	self.valid_attack_count = 0
end

function modifier_xhs_mountain_king_bash:OnAttackLanded(params)
	if not IsServer() or params.attacker ~= self:GetParent() then return end

	local attacker = params.attacker
	local target = params.target
	local ability = self:GetAbility()
	if target == nil or target:IsNull() or ability == nil or ability:IsNull() then return end
	if attacker:PassivesDisabled() or attacker:IsIllusion() then return end
	if target:GetTeamNumber() == attacker:GetTeamNumber() or target:IsBuilding() or target:IsOther() then return end

	self.valid_attack_count = self.valid_attack_count + 1
	local attacksRequired = math.max(1, ability:GetSpecialValueFor("attack_count"))
	if self.valid_attack_count < attacksRequired then return end

	self.valid_attack_count = 0

	-- Boss casts are encounter mechanics. The bash still procs and deals its
	-- normal bonus damage, but bosses never receive the interrupting stun.
	if not IsXHSBossTarget(target) then
		local stunDuration = ability:GetSpecialValueFor("duration")
		target:AddNewModifier(attacker, ability, "modifier_stunned", {
			duration = stunDuration,
		})
	end

	target:EmitSound("Hero_Slardar.Bash")

	local particle = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_slardar/slardar_bash.vpcf",
		PATTACH_ABSORIGIN_FOLLOW,
		target
	)
	ParticleManager:ReleaseParticleIndex(particle)

	ApplyDamage({
		victim = target,
		attacker = attacker,
		ability = ability,
		damage = ability:GetSpecialValueFor("bonus_damage"),
		damage_type = DAMAGE_TYPE_PHYSICAL,
	})
end
