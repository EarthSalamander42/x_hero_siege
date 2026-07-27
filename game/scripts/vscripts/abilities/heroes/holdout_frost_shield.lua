local FROST_SHIELD_CAST_SOUND = "Hero_Lich.FrostArmor"
local FROST_SHIELD_RETALIATE_SOUND = "Hero_Lich.FrostArmorDamage"
local FROST_SHIELD_PARTICLE = "particles/units/heroes/hero_lich/lich_frost_armor.vpcf"
local FROST_SHIELD_STATUS_PARTICLE = "particles/status_fx/status_effect_frost_lich.vpcf"
local FROST_SHIELD_TEXTURE = "custom/holdout_frost_armor"

LinkLuaModifier("modifier_xhs_frost_shield_autocast", "abilities/heroes/holdout_frost_shield.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_frost_shield", "abilities/heroes/holdout_frost_shield.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_frost_shield_slow", "abilities/heroes/holdout_frost_shield.lua", LUA_MODIFIER_MOTION_NONE)

holdout_frost_armor = holdout_frost_armor or class({})
holdout_frost_shield = holdout_frost_shield or class({})

local function GetFrostShieldIntrinsicModifierName()
	return "modifier_xhs_frost_shield_autocast"
end

local function CastFrostShield(ability)
	if not IsServer() then return end

	local caster = ability:GetCaster()
	local target = ability:GetCursorTarget()
	if not caster or caster:IsNull() or not target or target:IsNull() then return end

	target:AddNewModifier(caster, ability, "modifier_xhs_frost_shield", {
		duration = ability:GetSpecialValueFor("duration"),
	})

	-- Keep the cast cue centered on the caster and the application cue centered
	-- on the protected ally. A self-cast only needs one positional instance.
	EmitSoundOn(FROST_SHIELD_CAST_SOUND, caster)
	if target ~= caster then
		EmitSoundOn(FROST_SHIELD_CAST_SOUND, target)
	end
end

function holdout_frost_armor:GetIntrinsicModifierName()
	return GetFrostShieldIntrinsicModifierName()
end

function holdout_frost_armor:OnSpellStart()
	CastFrostShield(self)
end

function holdout_frost_shield:GetIntrinsicModifierName()
	return GetFrostShieldIntrinsicModifierName()
end

function holdout_frost_shield:OnSpellStart()
	CastFrostShield(self)
end

modifier_xhs_frost_shield_autocast = modifier_xhs_frost_shield_autocast or class({})
modifier_xhs_frost_shield_autocast.XHS_LINK_CLIENT = true

function modifier_xhs_frost_shield_autocast:IsHidden() return true end
function modifier_xhs_frost_shield_autocast:IsPurgable() return false end
function modifier_xhs_frost_shield_autocast:RemoveOnDeath() return false end

function modifier_xhs_frost_shield_autocast:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACKED,
	}
end

function modifier_xhs_frost_shield_autocast:OnAttacked(event)
	if not IsServer() then return end

	local caster = self:GetParent()
	local ability = self:GetAbility()
	local target = event and event.target or nil
	local attacker = event and event.attacker or nil
	if not caster or caster:IsNull()
		or not ability or ability:IsNull()
		or not target or target:IsNull()
		or not attacker or attacker:IsNull()
		or not ability:GetAutoCastState()
		or not ability:IsFullyCastable()
		or caster:IsChanneling()
		or not caster:IsAlive()
		or target:GetTeamNumber() ~= caster:GetTeamNumber()
		or attacker:GetTeamNumber() == caster:GetTeamNumber()
		or target:HasModifier("modifier_xhs_frost_shield") then
		return
	end

	local filter = UnitFilter(
		target,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_BUILDING,
		DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
		caster:GetTeamNumber()
	)
	if filter ~= UF_SUCCESS then return end

	local castRange = ability:GetCastRange(caster:GetAbsOrigin(), target)
	if castRange > 0 and (target:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D() > castRange then
		return
	end

	caster:CastAbilityOnTarget(target, ability, caster:GetPlayerOwnerID())
end

modifier_xhs_frost_shield = modifier_xhs_frost_shield or class({})
modifier_xhs_frost_shield.XHS_LINK_CLIENT = true

function modifier_xhs_frost_shield:IsHidden() return false end
function modifier_xhs_frost_shield:IsDebuff() return false end
function modifier_xhs_frost_shield:IsPurgable() return true end
function modifier_xhs_frost_shield:GetTexture() return FROST_SHIELD_TEXTURE end
function modifier_xhs_frost_shield:GetEffectName() return FROST_SHIELD_PARTICLE end
function modifier_xhs_frost_shield:GetEffectAttachType() return PATTACH_OVERHEAD_FOLLOW end

function modifier_xhs_frost_shield:OnCreated()
	self:ReadSpecialValues()
end

function modifier_xhs_frost_shield:OnRefresh()
	self:ReadSpecialValues()
end

function modifier_xhs_frost_shield:ReadSpecialValues()
	local ability = self:GetAbility()
	if not ability or ability:IsNull() then
		self.armorBonus = 0
		self.slowDuration = 0
		return
	end

	self.armorBonus = ability:GetSpecialValueFor("armor_bonus")
	self.slowDuration = ability:GetSpecialValueFor("slow_duration")
end

function modifier_xhs_frost_shield:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_EVENT_ON_ATTACKED,
	}
end

function modifier_xhs_frost_shield:GetModifierPhysicalArmorBonus()
	return self.armorBonus or 0
end

function modifier_xhs_frost_shield:OnAttacked(event)
	if not IsServer() or not event or event.target ~= self:GetParent() then return end

	local attacker = event.attacker
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	if not attacker or attacker:IsNull()
		or not caster or caster:IsNull()
		or not ability or ability:IsNull() then
		return
	end

	local filter = UnitFilter(
		attacker,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE,
		self:GetParent():GetTeamNumber()
	)
	if filter ~= UF_SUCCESS then return end

	attacker:AddNewModifier(caster, ability, "modifier_xhs_frost_shield_slow", {
		duration = self.slowDuration or ability:GetSpecialValueFor("slow_duration"),
	})
	EmitSoundOn(FROST_SHIELD_RETALIATE_SOUND, attacker)
end

modifier_xhs_frost_shield_slow = modifier_xhs_frost_shield_slow or class({})
modifier_xhs_frost_shield_slow.XHS_LINK_CLIENT = true

function modifier_xhs_frost_shield_slow:IsHidden() return false end
function modifier_xhs_frost_shield_slow:IsDebuff() return true end
function modifier_xhs_frost_shield_slow:IsPurgable() return true end
function modifier_xhs_frost_shield_slow:IsStunDebuff() return false end
function modifier_xhs_frost_shield_slow:GetTexture() return FROST_SHIELD_TEXTURE end
function modifier_xhs_frost_shield_slow:GetStatusEffectName() return FROST_SHIELD_STATUS_PARTICLE end
function modifier_xhs_frost_shield_slow:StatusEffectPriority() return 2 end

function modifier_xhs_frost_shield_slow:OnCreated()
	self:ReadSpecialValues()
end

function modifier_xhs_frost_shield_slow:OnRefresh()
	self:ReadSpecialValues()
end

function modifier_xhs_frost_shield_slow:ReadSpecialValues()
	local ability = self:GetAbility()
	if not ability or ability:IsNull() then
		self.attackSlow = 0
		self.movementSlow = 0
		return
	end

	self.attackSlow = ability:GetSpecialValueFor("slow_attack_speed")
	self.movementSlow = ability:GetSpecialValueFor("slow_movement_speed")
end

function modifier_xhs_frost_shield_slow:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_xhs_frost_shield_slow:GetModifierAttackSpeedBonus_Constant()
	return self.attackSlow or 0
end

function modifier_xhs_frost_shield_slow:GetModifierMoveSpeedBonus_Percentage()
	return self.movementSlow or 0
end
