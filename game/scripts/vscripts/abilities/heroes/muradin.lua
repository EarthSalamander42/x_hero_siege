LinkLuaModifier("modifier_muradin_avatar", "abilities/heroes/muradin.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_muradin_avatar_buff", "abilities/heroes/muradin.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_muradin_true_strike", "abilities/heroes/muradin.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_dwarven_bulwark", "abilities/heroes/muradin.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_dwarven_bulwark_armor", "abilities/heroes/muradin.lua", LUA_MODIFIER_MOTION_NONE)

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

local function IsDamageSourceInFront(parent, source, frontalAngle)
	if source == nil or source == parent then return false end
	if IsValidEntity ~= nil and not IsValidEntity(source) then return false end
	if source.IsNull == nil or source:IsNull() then return false end

	local direction = source:GetAbsOrigin() - parent:GetAbsOrigin()
	direction.z = 0
	if direction:Length2D() <= 0.01 then return true end
	direction = direction:Normalized()

	local forward = parent:GetForwardVector()
	forward.z = 0
	forward = forward:Normalized()
	local minimumDot = math.cos(math.rad(math.max(0, math.min(360, frontalAngle)) * 0.5))
	return forward:Dot(direction) >= minimumDot
end

xhs_mountain_king_bulwark = xhs_mountain_king_bulwark or class({})

local XHS_DWARVEN_BULWARK_CAST_TEXTURE = "custom/xhs_mountain_king_bulwark_cast"
local XHS_DWARVEN_BULWARK_RELEASE_TEXTURE = "custom/xhs_mountain_king_bulwark_release"

function xhs_mountain_king_bulwark:GetAbilityTextureName()
	local caster = self:GetCaster()
	if caster ~= nil
		and not caster:IsNull()
		and caster:HasModifier("modifier_xhs_dwarven_bulwark") then
		return XHS_DWARVEN_BULWARK_RELEASE_TEXTURE
	end
	return XHS_DWARVEN_BULWARK_CAST_TEXTURE
end

function xhs_mountain_king_bulwark:OnSpellStart()
	local caster = self:GetCaster()
	if caster == nil or caster:IsNull() then return end

	local existing = caster:FindModifierByName("modifier_xhs_dwarven_bulwark")
	if existing ~= nil and not existing:IsNull() then
		existing:ReleaseBulwark()
		return
	end

	-- Keep the ability available during the guard so the player may release the
	-- stored force early. The real cooldown begins when the guard ends.
	self:EndCooldown()
	caster:AddNewModifier(caster, self, "modifier_xhs_dwarven_bulwark", {
		duration = self:GetSpecialValueFor("duration"),
	})
	caster:EmitSound("Hero_Sven.WarCry")
end

modifier_xhs_dwarven_bulwark = modifier_xhs_dwarven_bulwark or class({})
modifier_xhs_dwarven_bulwark.XHS_LINK_CLIENT = true

function modifier_xhs_dwarven_bulwark:IsHidden() return false end
function modifier_xhs_dwarven_bulwark:IsPurgable() return false end
function modifier_xhs_dwarven_bulwark:GetTexture() return XHS_DWARVEN_BULWARK_CAST_TEXTURE end
function modifier_xhs_dwarven_bulwark:GetEffectName()
	return "particles/units/heroes/hero_sven/sven_warcry_buff.vpcf"
end
function modifier_xhs_dwarven_bulwark:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_xhs_dwarven_bulwark:OnCreated()
	local ability = self:GetAbility()
	if ability == nil or ability:IsNull() then return end

	self.front_reduction = ability:GetSpecialValueFor("front_damage_reduction")
	self.rear_reduction = ability:GetSpecialValueFor("rear_damage_reduction")
	self.frontal_angle = ability:GetSpecialValueFor("frontal_angle")
	self.stored_damage_pct = ability:GetSpecialValueFor("stored_damage_pct")
	self.stored_damage_cap_pct = ability:GetSpecialValueFor("stored_damage_cap_pct")
	self.stored_damage = 0
	self.released = false

	if IsServer() then self:SetStackCount(0) end
end

function modifier_xhs_dwarven_bulwark:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
end

function modifier_xhs_dwarven_bulwark:GetReductionForSource(source)
	if IsDamageSourceInFront(self:GetParent(), source, self.frontal_angle or 140) then
		return self.front_reduction or 0
	end
	return self.rear_reduction or 0
end

function modifier_xhs_dwarven_bulwark:GetModifierIncomingDamage_Percentage(params)
	if params ~= nil and params.attacker == self:GetParent() then return 0 end
	return -self:GetReductionForSource(params and params.attacker or nil)
end

function modifier_xhs_dwarven_bulwark:OnTakeDamage(params)
	if not IsServer() or params.unit ~= self:GetParent() then return end
	if params.damage == nil or params.damage <= 0 then return end
	if params.attacker == self:GetParent() then return end
	if bit ~= nil
		and params.damage_flags ~= nil
		and bit.band(params.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) ~= 0 then return end

	local reduction = math.min(95, math.max(0, self:GetReductionForSource(params.attacker)))
	if reduction <= 0 then return end

	-- OnTakeDamage reports post-mitigation damage. Reconstruct the portion this
	-- modifier prevented, then store only the configured share of that amount.
	local prevented = params.damage * reduction / math.max(1, 100 - reduction)
	local gained = prevented * (self.stored_damage_pct or 0) * 0.01
	local cap = self:GetParent():GetMaxHealth() * (self.stored_damage_cap_pct or 0) * 0.01
	self.stored_damage = math.min(cap, (self.stored_damage or 0) + gained)
	self:SetStackCount(math.floor(self.stored_damage + 0.5))
end

function modifier_xhs_dwarven_bulwark:ReleaseBulwark()
	if not IsServer() or self.released then return end
	self.released = true
	self:Destroy()
end

function modifier_xhs_dwarven_bulwark:OnDestroy()
	if not IsServer() then return end

	local caster = self:GetParent()
	local ability = self:GetAbility()
	if caster == nil or caster:IsNull() or ability == nil or ability:IsNull() then return end

	ability:StartCooldown(ability:GetCooldown(ability:GetLevel() - 1))
	if not caster:IsAlive() then return end

	local radius = ability:GetSpecialValueFor("release_radius")
	local origin = caster:GetAbsOrigin() + caster:GetForwardVector()
		* ability:GetSpecialValueFor("release_offset")
	local damage = ability:GetSpecialValueFor("release_base_damage") + (self.stored_damage or 0)

	caster:StartGesture(ACT_DOTA_CAST_ABILITY_2)
	caster:EmitSound("Hero_Brewmaster.ThunderClap")
	local particle = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_brewmaster/brewmaster_thunder_clap.vpcf",
		PATTACH_WORLDORIGIN,
		caster
	)
	ParticleManager:SetParticleControl(particle, 0, origin)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius, radius, radius))
	ParticleManager:ReleaseParticleIndex(particle)

	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		origin,
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		FIND_ANY_ORDER,
		false
	)
	for _, enemy in ipairs(enemies) do
		ApplyDamage({
			victim = enemy,
			attacker = caster,
			ability = ability,
			damage = damage,
			damage_type = DAMAGE_TYPE_PHYSICAL,
		})
		enemy:AddNewModifier(caster, ability, "modifier_xhs_dwarven_bulwark_armor", {
			duration = ability:GetSpecialValueFor("armor_duration"),
		})
	end
end

modifier_xhs_dwarven_bulwark_armor = modifier_xhs_dwarven_bulwark_armor or class({})
modifier_xhs_dwarven_bulwark_armor.XHS_LINK_CLIENT = true

function modifier_xhs_dwarven_bulwark_armor:IsDebuff() return true end
function modifier_xhs_dwarven_bulwark_armor:IsPurgable() return true end
function modifier_xhs_dwarven_bulwark_armor:GetTexture() return "sven_warcry" end

function modifier_xhs_dwarven_bulwark_armor:OnCreated()
	local ability = self:GetAbility()
	self.armor_reduction = ability ~= nil and not ability:IsNull()
		and ability:GetSpecialValueFor("armor_reduction") or 0
end

function modifier_xhs_dwarven_bulwark_armor:DeclareFunctions()
	return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS }
end

function modifier_xhs_dwarven_bulwark_armor:GetModifierPhysicalArmorBonus()
	return -(self.armor_reduction or 0)
end
