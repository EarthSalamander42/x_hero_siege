require("boss_scripts/phase3_ai/core")
require("boss_scripts/phase3_ai/telegraphs")
require("boss_scripts/phase3_ai/cast_bar")

xhs_balanar_nightfall = xhs_balanar_nightfall or class({})
xhs_balanar_dread_howl = xhs_balanar_dread_howl or class({})
xhs_balanar_sleeping_terror = xhs_balanar_sleeping_terror or class({})
xhs_balanar_carrion_swarm = xhs_balanar_carrion_swarm or class({})
xhs_balanar_rain_of_chaos = xhs_balanar_rain_of_chaos or class({})
xhs_balanar_vampiric_presence = xhs_balanar_vampiric_presence or class({})

LinkLuaModifier("modifier_xhs_balanar_nightfall", "boss_scripts/phase3_ai/balanar_abilities.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_balanar_nightfall_vision", "boss_scripts/phase3_ai/balanar_abilities.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_balanar_dread", "boss_scripts/phase3_ai/balanar_abilities.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_balanar_nightmare", "boss_scripts/phase3_ai/balanar_abilities.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_balanar_vampiric_presence", "boss_scripts/phase3_ai/balanar_abilities.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_balanar_rain_of_chaos", "abilities/heroes/npc_hero_balanar/balanar_rain_of_chaos.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_balanar_rain_of_chaos_dummy", "abilities/heroes/npc_hero_balanar/balanar_rain_of_chaos.lua", LUA_MODIFIER_MOTION_NONE)

modifier_xhs_balanar_nightfall = modifier_xhs_balanar_nightfall or class({})
modifier_xhs_balanar_nightfall.XHS_LINK_CLIENT = true
modifier_xhs_balanar_nightfall_vision = modifier_xhs_balanar_nightfall_vision or class({})
modifier_xhs_balanar_nightfall_vision.XHS_LINK_CLIENT = true
modifier_xhs_balanar_dread = modifier_xhs_balanar_dread or class({})
modifier_xhs_balanar_dread.XHS_LINK_CLIENT = true
modifier_xhs_balanar_nightmare = modifier_xhs_balanar_nightmare or class({})
modifier_xhs_balanar_nightmare.XHS_LINK_CLIENT = true
modifier_xhs_balanar_vampiric_presence = modifier_xhs_balanar_vampiric_presence or class({})
modifier_xhs_balanar_vampiric_presence.XHS_LINK_CLIENT = true

local BALANAR_COLORS = {
	primary = Vector(155, 55, 255),
	secondary = Vector(45, 255, 105),
	style = 6,
	family = "balanar",
}

local NIGHTFALL_PARTICLE = "particles/units/heroes/hero_pugna/pugna_netherblast.vpcf"
local DREAD_HOWL_PARTICLE = "particles/units/heroes/hero_lycan/lycan_howl_cast.vpcf"
local DARKMOON_AOE_PARTICLE = "particles/custom/boss_warnings/balanar/radius.vpcf"
local SLEEPING_TERROR_PARTICLE = "particles/units/heroes/hero_bane/bane_nightmare.vpcf"
local CARRION_SWARM_PARTICLE = "particles/units/heroes/hero_death_prophet/death_prophet_carrion_swarm.vpcf"

local function IsValidAlive(unit)
	return unit ~= nil and IsValidEntity(unit) and not unit:IsNull() and unit:IsAlive()
end

local function GetContext(ability)
	return ability.xhs_balanar_context or {}
end

local function ClearContext(ability)
	ability.xhs_balanar_context = nil
end

local function NormalizeDirection(direction)
	if direction == nil then return Vector(1, 0, 0) end
	direction.z = 0
	if direction:Length2D() <= 0 then return Vector(1, 0, 0) end
	return direction:Normalized()
end

local function StartBossCastBar(ability, displayName)
	if XHSBossCastBar ~= nil then
		XHSBossCastBar:Start(ability:GetCaster(), ability, {
			display_name = displayName,
			style = "balanar",
		})
	end
end

local function HideBossCastBar(ability)
	if XHSBossCastBar ~= nil then
		XHSBossCastBar:Hide(ability:GetCaster())
	end
end

local function ScaleDamage(value)
	if XHSPhase3BossAI ~= nil and XHSPhase3BossAI.ScaleDamage ~= nil then
		return XHSPhase3BossAI:ScaleDamage(value)
	end

	return value or 0
end

local function DamageEnemies(caster, ability, position, radius, damage, damageType)
	if not IsValidAlive(caster) then return end

	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		position,
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		FIND_ANY_ORDER,
		false
	)

	for _, enemy in pairs(enemies) do
		if IsValidAlive(enemy) and not enemy:IsInvulnerable() then
			ApplyDamage({
				victim = enemy,
				attacker = caster,
				ability = ability,
				damage = damage,
				damage_type = damageType or ability:GetAbilityDamageType(),
			})
		end
	end
end

local function CreateRadialImpact(position, radius, particleName)
	local particle = ParticleManager:CreateParticle(particleName, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius or 250, 0, 0))
	Timers:CreateTimer(1.2, function()
		ParticleManager:DestroyParticle(particle, false)
		ParticleManager:ReleaseParticleIndex(particle)
		return nil
	end)
end

local function CreateOverheadCast(caster, particleName)
	if not IsValidAlive(caster) then return end
	local particle = ParticleManager:CreateParticle(particleName, PATTACH_OVERHEAD_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(particle, 0, caster, PATTACH_OVERHEAD_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(particle)
end

local function CreateDarkmoonPrecast(position, radius, duration)
	local particle = ParticleManager:CreateParticle(DARKMOON_AOE_PARTICLE, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius or 250, duration or 1.0, 0))
	ParticleManager:SetParticleControl(particle, 2, Vector(duration or 1.0, 0, 0))
	ParticleManager:SetParticleControl(particle, 15, BALANAR_COLORS.primary)
	ParticleManager:SetParticleControl(particle, 16, Vector(1, 0, 0))
	Timers:CreateTimer(math.max(0.1, duration or 1.0) + 0.03, function()
		ParticleManager:DestroyParticle(particle, false)
		ParticleManager:ReleaseParticleIndex(particle)
		return nil
	end)
end

local function CreateNightfallScreenEffects(duration)
	CustomGameEventManager:Send_ServerToAllClients("xhs_nightfall_vignette", {
		duration = math.max(0.1, duration or 1.0),
	})
end

local function EmitLocationSound(caster, position, soundName)
	if IsValidAlive(caster) and position ~= nil and soundName ~= nil then
		EmitSoundOnLocationWithCaster(position, soundName, caster)
	end
end

function xhs_balanar_nightfall:OnAbilityPhaseStart()
	if not IsServer() then return true end

	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	StartBossCastBar(self, "Nightfall")
	XHSBossTelegraphs:Circle(caster:GetAbsOrigin(), radius, self:GetCastPoint(), BALANAR_COLORS)
	CreateDarkmoonPrecast(caster:GetAbsOrigin(), radius, self:GetCastPoint())
	StartAnimation(caster, { duration = self:GetCastPoint() + 0.25, activity = ACT_DOTA_CAST_ABILITY_4, rate = 0.8 })
	caster:EmitSound("Hero_Nightstalker.Void")
	return true
end

function xhs_balanar_nightfall:OnAbilityPhaseInterrupted()
	if IsServer() then HideBossCastBar(self) end
end

function xhs_balanar_nightfall:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	local duration = self:GetSpecialValueFor("duration")
	local visionReduction = self:GetSpecialValueFor("vision_reduction")
	GameRules:SetTimeOfDay(0)
	DamageEnemies(caster, self, caster:GetAbsOrigin(), radius, ScaleDamage(self:GetSpecialValueFor("damage")), self:GetAbilityDamageType())
	caster:AddNewModifier(caster, self, "modifier_xhs_balanar_nightfall", { duration = duration })
	local radiantUnits = FindUnitsInRadius(
		DOTA_TEAM_GOODGUYS,
		caster:GetAbsOrigin(),
		nil,
		FIND_UNITS_EVERYWHERE,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_ALL,
		DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
		FIND_ANY_ORDER,
		false
	)
	for _, unit in pairs(radiantUnits) do
		if unit ~= nil and not unit:IsNull() then
			unit:AddNewModifier(caster, self, "modifier_xhs_balanar_nightfall_vision", {
				duration = duration,
				vision_reduction = visionReduction,
			})
		end
	end
	CreateRadialImpact(caster:GetAbsOrigin(), radius, NIGHTFALL_PARTICLE)
	XHSBossTelegraphs:Release(caster:GetAbsOrigin(), radius, BALANAR_COLORS)
	CreateNightfallScreenEffects(duration)
	caster:EmitSound("Hero_Nightstalker.Darkness")
	ClearContext(self)
end

function xhs_balanar_dread_howl:OnAbilityPhaseStart()
	if not IsServer() then return true end

	local caster = self:GetCaster()
	StartBossCastBar(self, "Dread Howl")
	CreateDarkmoonPrecast(caster:GetAbsOrigin(), self:GetSpecialValueFor("radius"), self:GetCastPoint())
	StartAnimation(caster, { duration = self:GetCastPoint() + 0.2, activity = ACT_DOTA_CAST_ABILITY_1, rate = 0.9 })
	return true
end

function xhs_balanar_dread_howl:OnAbilityPhaseInterrupted()
	if IsServer() then HideBossCastBar(self) end
end

function xhs_balanar_dread_howl:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	DamageEnemies(caster, self, caster:GetAbsOrigin(), radius, ScaleDamage(self:GetSpecialValueFor("damage")), self:GetAbilityDamageType())

	local enemies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
	for _, enemy in pairs(enemies) do
		if IsValidAlive(enemy) then
			enemy:AddNewModifier(caster, self, "modifier_xhs_balanar_dread", { duration = self:GetSpecialValueFor("slow_duration") })
		end
	end
	CreateOverheadCast(caster, DREAD_HOWL_PARTICLE)
	caster:EmitSound("Hero_Lycan.Howl")
	ClearContext(self)
end

function xhs_balanar_sleeping_terror:OnAbilityPhaseStart()
	if not IsServer() then return true end

	local context = GetContext(self)
	local position = context.position or self:GetCaster():GetAbsOrigin()
	StartBossCastBar(self, "Sleeping Terror")
	XHSBossTelegraphs:Target(position, self:GetSpecialValueFor("radius"), self:GetCastPoint(), BALANAR_COLORS)
	StartAnimation(self:GetCaster(), { duration = self:GetCastPoint() + 0.15, activity = ACT_DOTA_CAST_ABILITY_2, rate = 1.0 })
	return true
end

function xhs_balanar_sleeping_terror:OnAbilityPhaseInterrupted()
	if IsServer() then HideBossCastBar(self) end
end

function xhs_balanar_sleeping_terror:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local context = GetContext(self)
	local position = context.position or caster:GetAbsOrigin()
	local radius = self:GetSpecialValueFor("radius")
	DamageEnemies(caster, self, position, radius, ScaleDamage(self:GetSpecialValueFor("damage")), self:GetAbilityDamageType())

	local enemies = FindUnitsInRadius(caster:GetTeamNumber(), position, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
	for _, enemy in pairs(enemies) do
		if IsValidAlive(enemy) then
			enemy:AddNewModifier(caster, self, "modifier_xhs_balanar_nightmare", { duration = self:GetSpecialValueFor("nightmare_duration") })
		end
	end
	CreateRadialImpact(position, radius, SLEEPING_TERROR_PARTICLE)
	XHSBossTelegraphs:Release(position, radius, BALANAR_COLORS)
	EmitLocationSound(caster, position, "Hero_Bane.Nightmare")
	ClearContext(self)
end

function xhs_balanar_carrion_swarm:OnAbilityPhaseStart()
	if not IsServer() then return true end

	local context = GetContext(self)
	local caster = self:GetCaster()
	local direction = NormalizeDirection(context.direction or caster:GetForwardVector())
	local length = self:GetSpecialValueFor("length")
	local width = self:GetSpecialValueFor("width")
	local spacing = math.max(1, width * 1.35)

	StartBossCastBar(self, "Carrion Swarm")
	XHSBossTelegraphs:Line(caster:GetAbsOrigin(), direction, spacing, width, math.max(1, math.floor(length / spacing)), self:GetCastPoint(), BALANAR_COLORS, 120)
	StartAnimation(caster, { duration = self:GetCastPoint() + 0.15, activity = ACT_DOTA_CAST_ABILITY_3, rate = 1.0 })
	return true
end

function xhs_balanar_carrion_swarm:OnAbilityPhaseInterrupted()
	if IsServer() then HideBossCastBar(self) end
end

function xhs_balanar_carrion_swarm:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local context = GetContext(self)
	local direction = NormalizeDirection(context.direction or caster:GetForwardVector())
	local length = self:GetSpecialValueFor("length")
	local endRadius = self:GetSpecialValueFor("width")
	local startRadius = math.max(1, endRadius * (160 / 300))
	local speed = math.max(1, self:GetSpecialValueFor("projectile_speed"))

	ProjectileManager:CreateLinearProjectile({
		Ability = self,
		EffectName = CARRION_SWARM_PARTICLE,
		vSpawnOrigin = caster:GetAbsOrigin(),
		fDistance = length,
		fStartRadius = startRadius,
		fEndRadius = endRadius,
		Source = caster,
		bHasFrontalCone = true,
		bReplaceExisting = false,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		fExpireTime = GameRules:GetGameTime() + (length / speed) + 1.0,
		bDeleteOnHit = false,
		vVelocity = direction * speed,
		bProvidesVision = false,
		ExtraData = {
			damage = ScaleDamage(self:GetSpecialValueFor("damage")),
		},
	})
	caster:EmitSound("Hero_DeathProphet.CarrionSwarm")
	ClearContext(self)
end

function xhs_balanar_carrion_swarm:OnProjectileHit_ExtraData(target, location, extraData)
	if not IsServer() or not IsValidAlive(target) or target:IsInvulnerable() then return false end

	local dealt = ApplyDamage({
		victim = target,
		attacker = self:GetCaster(),
		ability = self,
		damage = tonumber(extraData.damage) or 0,
		damage_type = self:GetAbilityDamageType(),
	})
	SendOverheadEventMessage(nil, OVERHEAD_ALERT_DAMAGE, target, dealt, nil)
	return false
end

function xhs_balanar_rain_of_chaos:OnAbilityPhaseStart()
	if not IsServer() then return true end

	local castPoint = self:GetCastPoint()
	StartBossCastBar(self, "Rain of Chaos")
	StartAnimation(self:GetCaster(), { duration = castPoint + 0.3, activity = ACT_DOTA_CAST_ABILITY_4, rate = 0.75 })
	self:GetCaster():EmitSound("Hero_Warlock.RainOfChaos_buildup")
	return true
end

function xhs_balanar_rain_of_chaos:OnAbilityPhaseInterrupted()
	if IsServer() then HideBossCastBar(self) end
end

function xhs_balanar_rain_of_chaos:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()
	self.radius = self:GetSpecialValueFor("radius")
	self.radius_explosion = self:GetSpecialValueFor("radius_explosion")
	self.unit_per_meteor = math.max(1, self:GetSpecialValueFor("unit_per_meteor"))
	self.interval = self:GetSpecialValueFor("time_between_meteors")
	self.duration = self:GetSpecialValueFor("duration")
	self.damage = ScaleDamage(self:GetSpecialValueFor("damage_per_unit"))
	self.stun_duration = self:GetSpecialValueFor("stun_duration")
	self.golem_duration = self:GetSpecialValueFor("golem_duration")
	self.damage_reduction = self:GetSpecialValueFor("damage_reduction")
	self.seek_radius = self:GetSpecialValueFor("seek_radius")

	caster:AddNewModifier(caster, self, "modifier_balanar_rain_of_chaos", { duration = self.duration })
	caster:AddNewModifier(caster, self, "modifier_invulnerable", { duration = self.duration })
	caster:EmitSound("DOTA_Item.BlackKingBar.Activate")
	ClearContext(self)
end

function xhs_balanar_vampiric_presence:GetIntrinsicModifierName()
	return "modifier_xhs_balanar_vampiric_presence"
end

function modifier_xhs_balanar_nightfall:IsPurgable() return false end
function modifier_xhs_balanar_nightfall:DeclareFunctions()
	return { MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end
function modifier_xhs_balanar_nightfall:GetModifierBaseDamageOutgoing_Percentage()
	return self:GetAbility() and self:GetAbility():GetSpecialValueFor("bonus_damage_pct") or 0
end
function modifier_xhs_balanar_nightfall:GetModifierAttackSpeedBonus_Constant()
	return self:GetAbility() and self:GetAbility():GetSpecialValueFor("bonus_attack_speed") or 0
end

function modifier_xhs_balanar_nightfall_vision:IsHidden() return true end
function modifier_xhs_balanar_nightfall_vision:IsPurgable() return false end
function modifier_xhs_balanar_nightfall_vision:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_BONUS_DAY_VISION,
		MODIFIER_PROPERTY_BONUS_NIGHT_VISION,
	}
end
function modifier_xhs_balanar_nightfall_vision:GetBonusDayVision()
	return -(self:GetAbility() and self:GetAbility():GetSpecialValueFor("vision_reduction") or self:GetStackCount() or 0)
end
function modifier_xhs_balanar_nightfall_vision:GetBonusNightVision()
	return -(self:GetAbility() and self:GetAbility():GetSpecialValueFor("vision_reduction") or self:GetStackCount() or 0)
end

function modifier_xhs_balanar_dread:IsDebuff() return true end
function modifier_xhs_balanar_dread:IsPurgable() return true end
function modifier_xhs_balanar_dread:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE }
end
function modifier_xhs_balanar_dread:GetModifierMoveSpeedBonus_Percentage()
	return -(self:GetAbility() and self:GetAbility():GetSpecialValueFor("slow_pct") or 35)
end
function modifier_xhs_balanar_dread:GetModifierDamageOutgoing_Percentage()
	return -(self:GetAbility() and self:GetAbility():GetSpecialValueFor("damage_reduction_pct") or 20)
end

function modifier_xhs_balanar_nightmare:IsPurgable() return true end
function modifier_xhs_balanar_nightmare:OnCreated()
	if not IsServer() then return end
	local parent = self:GetParent()
	self.nightmare_pfx = ParticleManager:CreateParticle(SLEEPING_TERROR_PARTICLE, PATTACH_OVERHEAD_FOLLOW, parent)
	ParticleManager:SetParticleControlEnt(self.nightmare_pfx, 0, parent, PATTACH_OVERHEAD_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
	parent:EmitSound("Hero_Bane.Nightmare.Loop")
end
function modifier_xhs_balanar_nightmare:OnDestroy()
	if not IsServer() then return end
	local parent = self:GetParent()
	if parent ~= nil and not parent:IsNull() then
		parent:StopSound("Hero_Bane.Nightmare.Loop")
		parent:EmitSound("Hero_Bane.Nightmare.End")
	end
	if self.nightmare_pfx ~= nil then
		ParticleManager:DestroyParticle(self.nightmare_pfx, false)
		ParticleManager:ReleaseParticleIndex(self.nightmare_pfx)
		self.nightmare_pfx = nil
	end
end
function modifier_xhs_balanar_nightmare:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end
function modifier_xhs_balanar_nightmare:GetModifierMoveSpeedBonus_Percentage()
	return -(self:GetAbility() and self:GetAbility():GetSpecialValueFor("nightmare_slow_pct") or 65)
end
function modifier_xhs_balanar_nightmare:CheckState()
	return {
		[MODIFIER_STATE_STUNNED] = true,
	}
end

function modifier_xhs_balanar_vampiric_presence:IsHidden() return true end
function modifier_xhs_balanar_vampiric_presence:IsPurgable() return false end
function modifier_xhs_balanar_vampiric_presence:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ATTACK_LANDED }
end
function modifier_xhs_balanar_vampiric_presence:OnAttackLanded(keys)
	if not IsServer() then return end
	local parent = self:GetParent()
	if keys.attacker ~= parent or keys.damage == nil or keys.damage <= 0 then return end
	local ability = self:GetAbility()
	local lifesteal = ability and ability:GetSpecialValueFor("lifesteal_pct") or 0
	if lifesteal <= 0 then return end

	local heal = keys.damage * lifesteal * 0.01
	parent:Heal(heal, ability)
	SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, parent, heal, nil)

	local lifestealParticle = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
	ParticleManager:SetParticleControl(lifestealParticle, 0, parent:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(lifestealParticle)
end
