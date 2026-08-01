require("boss_scripts/phase3_ai/core")
require("boss_scripts/phase3_ai/telegraphs")
require("boss_scripts/phase3_ai/cast_bar")

xhs_illidan_metamorphosis = xhs_illidan_metamorphosis or class({})
xhs_illidan_fel_beam = xhs_illidan_fel_beam or class({})
xhs_illidan_shadow_dash = xhs_illidan_shadow_dash or class({})
xhs_illidan_immolation_burst = xhs_illidan_immolation_burst or class({})
xhs_illidan_glaive_storm = xhs_illidan_glaive_storm or class({})
xhs_illidan_demon_hunter = xhs_illidan_demon_hunter or class({})

LinkLuaModifier("modifier_xhs_illidan_metamorphosis", "boss_scripts/phase3_ai/illidan_abilities.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_illidan_demon_hunter", "boss_scripts/phase3_ai/illidan_abilities.lua", LUA_MODIFIER_MOTION_NONE)

modifier_xhs_illidan_metamorphosis = modifier_xhs_illidan_metamorphosis or class({})
modifier_xhs_illidan_metamorphosis.XHS_LINK_CLIENT = true
modifier_xhs_illidan_demon_hunter = modifier_xhs_illidan_demon_hunter or class({})
modifier_xhs_illidan_demon_hunter.XHS_LINK_CLIENT = true

local ILLIDAN_COLORS = {
	primary = Vector(102, 255, 64),
	secondary = Vector(142, 66, 255),
	style = 5,
}

local METAMORPHOSIS_PARTICLE = "particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis_transform.vpcf"
local METAMORPHOSIS_AMBIENT_PARTICLE = "particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis.vpcf"
local METAMORPHOSIS_ATTACK_PARTICLE = "particles/units/heroes/hero_terrorblade/terrorblade_metamorphosis_base_attack.vpcf"
local ILLIDAN_BASE_MODEL = "models/heroes/terrorblade/terrorblade.vmdl"
local METAMORPHOSIS_MODEL = "models/heroes/terrorblade/demon.vmdl"
local METAMORPHOSIS_CLEAVE_PARTICLE = "particles/econ/items/faceless_void/faceless_void_weapon_bfury/faceless_void_weapon_bfury_cleave.vpcf"
local FEL_BEAM_PARTICLE = "particles/units/heroes/hero_lina/lina_spell_dragon_slave.vpcf"
local FEL_BEAM_IMPACT_PARTICLE = "particles/units/heroes/hero_lina/lina_spell_dragon_slave_impact.vpcf"
local SHADOW_DASH_START_PARTICLE = "particles/items_fx/blink_dagger_start.vpcf"
local SHADOW_DASH_END_PARTICLE = "particles/items_fx/blink_dagger_end.vpcf"
local IMMOLATION_PULSE_PARTICLE = "particles/units/heroes/hero_phoenix/phoenix_supernova_reborn.vpcf"
local IMMOLATION_PRECAST_PARTICLE = "particles/econ/events/darkmoon_2017/darkmoon_generic_aoe.vpcf"
local SHADOW_DASH_ARENA_RADIUS = 2000
local GLAIVE_STORM_PARTICLE = "particles/econ/items/luna/luna_lucent_ti5/luna_eclipse_impact_moonfall.vpcf"
local GLAIVE_STORM_CAST_PARTICLE = "particles/units/heroes/hero_luna/luna_eclipse_cast.vpcf"

local function IsValidAlive(unit)
	return unit ~= nil and IsValidEntity(unit) and not unit:IsNull() and unit:IsAlive()
end

local function GetContext(ability)
	return ability.xhs_illidan_context or {}
end

local function ClearContext(ability)
	ability.xhs_illidan_context = nil
end

local function ClearImmolationPrecast(ability, immediate)
	local particle = ability and ability.xhs_illidan_immolation_precast_particle
	if particle == nil then return end

	ability.xhs_illidan_immolation_precast_particle = nil
	ParticleManager:DestroyParticle(particle, immediate == true)
	ParticleManager:ReleaseParticleIndex(particle)
end

local function GetIllidanBossBarId(parent)
	if parent == nil or parent:IsNull() then return nil end
	if GetBossBarId ~= nil then
		return GetBossBarId(parent)
	end
	return parent.xhs_boss_bar_id
end

local function UpdateMetamorphosisCounter(modifier)
	if modifier == nil then return end
	local parent = modifier:GetParent()
	if parent == nil or parent:IsNull() then return end
	local remaining = math.max(0, math.ceil(modifier:GetRemainingTime()))
	if modifier.xhs_last_counter_remaining == remaining then return end
	modifier.xhs_last_counter_remaining = remaining

	CustomGameEventManager:Send_ServerToAllClients("xhs_boss_counter_update", {
		boss_count = parent.boss_count or 1,
		boss_bar_id = GetIllidanBossBarId(parent),
		label = "Metamorphosis",
		remaining = remaining,
		display_mode = "seconds",
	})
end

local function HideMetamorphosisCounter(parent)
	if parent == nil or parent:IsNull() then return end
	CustomGameEventManager:Send_ServerToAllClients("xhs_boss_counter_hide", {
		boss_count = parent.boss_count or 1,
		boss_bar_id = GetIllidanBossBarId(parent),
	})
end

local function CreateImmolationPrecast(ability, position, radius, duration)
	ClearImmolationPrecast(ability, true)

	local particle = ParticleManager:CreateParticle(IMMOLATION_PRECAST_PARTICLE, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius, 0, 0))
	ParticleManager:SetParticleControl(particle, 2, Vector(duration or 1.0, 0, 1))
	ParticleManager:SetParticleControl(particle, 3, ILLIDAN_COLORS.primary)
	ParticleManager:SetParticleControl(particle, 4, position)
	ability.xhs_illidan_immolation_precast_particle = particle

	Timers:CreateTimer(math.max(duration or 1.0, 0.03), function()
		if ability.xhs_illidan_immolation_precast_particle == particle then
			ClearImmolationPrecast(ability, false)
		end
		return nil
	end)
end

local function StartBossCastBar(ability, displayName)
	if XHSBossCastBar ~= nil then
		XHSBossCastBar:Start(ability:GetCaster(), ability, {
			display_name = displayName,
			style = "illidan",
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

local function NormalizeDirection(direction)
	if direction == nil then return Vector(1, 0, 0) end
	direction.z = 0
	if direction:Length2D() <= 0 then return Vector(1, 0, 0) end
	return direction:Normalized()
end

local function GetShadowDashPath(ability, caster)
	local context = GetContext(ability)
	local startPosition = caster:GetAbsOrigin()
	local targetPosition = context.position or startPosition
	local direction = NormalizeDirection(targetPosition - startPosition)
	local maxDistance = ability:GetSpecialValueFor("max_distance")
	local travelDistance = math.min(maxDistance, math.max(180, (targetPosition - startPosition):Length2D()))
	local endPosition = startPosition + direction * travelDistance
	local arenaCenter = context.arena_center

	if arenaCenter ~= nil then
		local fromCenter = endPosition - arenaCenter
		fromCenter.z = 0
		if fromCenter:Length2D() > SHADOW_DASH_ARENA_RADIUS then
			endPosition = arenaCenter + fromCenter:Normalized() * SHADOW_DASH_ARENA_RADIUS
			endPosition.z = startPosition.z
			direction = NormalizeDirection(endPosition - startPosition)
			travelDistance = (endPosition - startPosition):Length2D()
		end
	end

	return {
		start_position = startPosition,
		end_position = endPosition,
		direction = direction,
		distance = travelDistance,
	}
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

local function DamageLine(caster, ability, startPosition, direction, length, width, damage, damageType, onHit)
	if not IsValidAlive(caster) then return end

	direction = NormalizeDirection(direction)
	local endPosition = startPosition + direction * length
	local enemies = FindUnitsInLine(
		caster:GetTeamNumber(),
		startPosition,
		endPosition,
		nil,
		width,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
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
			if onHit ~= nil then
				onHit(enemy)
			end
		end
	end
end

local function CreateRadialImpact(position, radius, particleName)
	local particle = ParticleManager:CreateParticle(particleName, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius or 240, 0, 0))
	Timers:CreateTimer(1.2, function()
		ParticleManager:DestroyParticle(particle, false)
		ParticleManager:ReleaseParticleIndex(particle)
		return nil
	end)
end

local function CreateGlaiveStormImpact(caster, position, radius)
	local duration = 1.2
	local sourcePosition = position + Vector(0, 0, 1000)
	local dummy = nil
	if IsValidAlive(caster) then
		dummy = CreateUnitByName("dummy_unit_invulnerable", position, false, caster, caster, caster:GetTeamNumber())
	end

	if dummy ~= nil and not dummy:IsNull() then
		if dummy.NoHealthBar ~= nil then
			dummy:NoHealthBar()
		end
		dummy:AddNewModifier(dummy, nil, "modifier_invulnerable", {})
		dummy:AddNewModifier(dummy, nil, "modifier_phased", {})
		dummy:AddNewModifier(dummy, nil, "modifier_kill", { duration = duration + 0.2 })

		local particle = ParticleManager:CreateParticle(GLAIVE_STORM_PARTICLE, PATTACH_CUSTOMORIGIN, dummy)
		ParticleManager:SetParticleControl(particle, 0, sourcePosition)
		ParticleManager:SetParticleControl(particle, 1, position)
		ParticleManager:SetParticleControl(particle, 2, position)
		ParticleManager:SetParticleControl(particle, 5, position)
		ParticleManager:SetParticleControl(particle, 10, Vector(radius or 240, 0, 0))
		Timers:CreateTimer(duration, function()
			ParticleManager:DestroyParticle(particle, false)
			ParticleManager:ReleaseParticleIndex(particle)
			if dummy ~= nil and not dummy:IsNull() then
				UTIL_Remove(dummy)
			end
			return nil
		end)
		return
	end

	local particle = ParticleManager:CreateParticle(GLAIVE_STORM_PARTICLE, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, sourcePosition)
	ParticleManager:SetParticleControl(particle, 1, position)
	ParticleManager:SetParticleControl(particle, 2, position)
	ParticleManager:SetParticleControl(particle, 5, position)
	Timers:CreateTimer(duration, function()
		ParticleManager:DestroyParticle(particle, false)
		ParticleManager:ReleaseParticleIndex(particle)
		return nil
	end)
end

local function CreateLineParticle(startPosition, direction, length, particleName, duration)
	direction = NormalizeDirection(direction)
	local endPosition = startPosition + direction * length
	local particle = ParticleManager:CreateParticle(particleName, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, startPosition)
	ParticleManager:SetParticleControl(particle, 1, endPosition)
	ParticleManager:SetParticleControl(particle, 2, Vector(duration or 0.7, 0, 0))
	Timers:CreateTimer(math.max(0.1, duration or 0.7) + 0.15, function()
		ParticleManager:DestroyParticle(particle, false)
		ParticleManager:ReleaseParticleIndex(particle)
		return nil
	end)
end

local function CreateDragonSlaveParticle(caster, ability, startPosition, direction, length, width, duration)
	direction = NormalizeDirection(direction)
	duration = math.max(0.1, duration or 0.8)
	length = math.max(1, length or 1)
	width = math.max(1, width or 125)

	ProjectileManager:CreateLinearProjectile({
		Source = caster,
		Ability = ability,
		vSpawnOrigin = startPosition,
		bDeleteOnHit = false,
		iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
		iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		EffectName = FEL_BEAM_PARTICLE,
		fDistance = length,
		fStartRadius = width,
		fEndRadius = width,
		vVelocity = direction * (length / duration),
		bProvidesVision = false,
	})
end

local function CreateBlinkImpact(position, particleName, duration)
	local particle = ParticleManager:CreateParticle(particleName, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, position)
	Timers:CreateTimer(math.max(0.1, duration or 1.0), function()
		ParticleManager:DestroyParticle(particle, false)
		ParticleManager:ReleaseParticleIndex(particle)
		return nil
	end)
end

local function EmitLocationSound(caster, position, soundName)
	if IsValidAlive(caster) and position ~= nil and soundName ~= nil then
		EmitSoundOnLocationWithCaster(position, soundName, caster)
	end
end

function xhs_illidan_metamorphosis:OnAbilityPhaseStart()
	if not IsServer() then return true end

	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	StartBossCastBar(self, "Metamorphosis")
	XHSBossTelegraphs:Circle(caster:GetAbsOrigin(), radius, self:GetCastPoint(), ILLIDAN_COLORS)
	CreateImmolationPrecast(self, caster:GetAbsOrigin(), radius, self:GetCastPoint())
	StartAnimation(caster, { duration = self:GetCastPoint() + 0.25, activity = ACT_DOTA_CAST_ABILITY_4, rate = 0.85 })
	caster:EmitSound("Hero_Terrorblade.Metamorphosis")
	return true
end

function xhs_illidan_metamorphosis:OnAbilityPhaseInterrupted()
	if IsServer() then
		ClearImmolationPrecast(self, true)
		HideBossCastBar(self)
	end
end

function xhs_illidan_metamorphosis:OnSpellStart()
	if not IsServer() then return end

	ClearImmolationPrecast(self, false)
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	local damage = ScaleDamage(self:GetSpecialValueFor("damage"))
	local duration = self:GetSpecialValueFor("duration")

	-- Apply the transformation first so damage callbacks cannot prevent the
	-- metamorphosis from completing after its precast.
	caster:AddNewModifier(caster, self, "modifier_xhs_illidan_metamorphosis", { duration = duration })
	DamageEnemies(caster, self, caster:GetAbsOrigin(), radius, damage, self:GetAbilityDamageType())
	CreateRadialImpact(caster:GetAbsOrigin(), radius, METAMORPHOSIS_PARTICLE)
	CreateRadialImpact(caster:GetAbsOrigin(), radius, IMMOLATION_PULSE_PARTICLE)
	EmitLocationSound(caster, caster:GetAbsOrigin(), "Hero_Terrorblade.Metamorphosis")
	HideBossCastBar(self)
	ClearContext(self)
end

function xhs_illidan_fel_beam:OnAbilityPhaseStart()
	if not IsServer() then return true end

	local context = GetContext(self)
	local caster = self:GetCaster()
	local startPosition = context.start or caster:GetAbsOrigin()
	local direction = NormalizeDirection(context.direction or caster:GetForwardVector())
	local length = self:GetSpecialValueFor("length")
	local width = self:GetSpecialValueFor("width")
	local spacing = math.max(1, width * 1.35)
	local count = math.max(1, math.floor(length / spacing))

	StartBossCastBar(self, "Fel Beam")
	XHSBossTelegraphs:Line(startPosition, direction, spacing, width, count, self:GetCastPoint(), ILLIDAN_COLORS, 120)
	StartAnimation(caster, { duration = self:GetCastPoint() + 0.25, activity = ACT_DOTA_CAST_ABILITY_1, rate = 0.8 })
	caster:EmitSound("Hero_Terrorblade.Reflection")
	return true
end

function xhs_illidan_fel_beam:OnAbilityPhaseInterrupted()
	if IsServer() then HideBossCastBar(self) end
end

function xhs_illidan_fel_beam:OnSpellStart()
	if not IsServer() then return end

	local context = GetContext(self)
	local caster = self:GetCaster()
	local startPosition = context.start or caster:GetAbsOrigin()
	local direction = NormalizeDirection(context.direction or caster:GetForwardVector())
	local length = self:GetSpecialValueFor("length")
	local width = self:GetSpecialValueFor("width")
	local damage = ScaleDamage(self:GetSpecialValueFor("damage"))

	DamageLine(caster, self, startPosition, direction, length, width, damage, self:GetAbilityDamageType(), function(enemy)
		local impact = ParticleManager:CreateParticle(FEL_BEAM_IMPACT_PARTICLE, PATTACH_ABSORIGIN_FOLLOW, enemy)
		ParticleManager:SetParticleControlEnt(impact, 0, enemy, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlForward(impact, 1, direction)
		ParticleManager:ReleaseParticleIndex(impact)
		enemy:EmitSound("Hero_Lina.DragonSlave.Impact")
	end)
	CreateDragonSlaveParticle(caster, self, startPosition, direction, length, width, 0.8)
	EmitLocationSound(caster, startPosition + direction * (length * 0.5), "Hero_Lina.DragonSlave")
	caster:EmitSound("Hero_Terrorblade.Metamorphosis.Attack")
	ClearContext(self)
end

function xhs_illidan_shadow_dash:OnAbilityPhaseStart()
	if not IsServer() then return true end

	local caster = self:GetCaster()
	local path = GetShadowDashPath(self, caster)
	local width = self:GetSpecialValueFor("width")
	local spacing = math.max(1, width * 1.4)
	local count = math.max(1, math.floor(path.distance / spacing))

	StartBossCastBar(self, "Shadow Dash")
	XHSBossTelegraphs:Target(path.end_position, self:GetSpecialValueFor("target_radius"), self:GetCastPoint(), ILLIDAN_COLORS)
	XHSBossTelegraphs:Line(path.start_position, path.direction, spacing, width, count, self:GetCastPoint(), ILLIDAN_COLORS, 80)
	StartAnimation(caster, { duration = self:GetCastPoint() + 0.2, activity = ACT_DOTA_CAST_ABILITY_2, rate = 1.0 })
	caster:EmitSound("Hero_Terrorblade.Sunder.Cast")
	return true
end

function xhs_illidan_shadow_dash:OnAbilityPhaseInterrupted()
	if IsServer() then HideBossCastBar(self) end
end

function xhs_illidan_shadow_dash:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local path = GetShadowDashPath(self, caster)
	local width = self:GetSpecialValueFor("width")
	local damage = ScaleDamage(self:GetSpecialValueFor("damage"))

	CreateBlinkImpact(path.start_position, SHADOW_DASH_START_PARTICLE, 1.0)
	DamageLine(caster, self, path.start_position, path.direction, path.distance, width, damage, self:GetAbilityDamageType())
	CreateDragonSlaveParticle(caster, self, path.start_position, path.direction, path.distance, width, 0.55)
	FindClearSpaceForUnit(caster, path.end_position, true)
	CreateBlinkImpact(path.end_position, SHADOW_DASH_END_PARTICLE, 1.0)
	EmitLocationSound(caster, path.end_position, "DOTA_Item.BlinkDagger.Activate")
	caster:EmitSound("Hero_Antimage.Blink_out")
	ClearContext(self)
end

function xhs_illidan_immolation_burst:OnAbilityPhaseStart()
	if not IsServer() then return true end

	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	StartBossCastBar(self, "Immolation Burst")
	XHSBossTelegraphs:Circle(caster:GetAbsOrigin(), radius, self:GetCastPoint(), ILLIDAN_COLORS)
	CreateImmolationPrecast(self, caster:GetAbsOrigin(), radius, self:GetCastPoint())
	StartAnimation(caster, { duration = self:GetCastPoint() + 0.35, activity = ACT_DOTA_CAST_ABILITY_3, rate = 0.9 })
	caster:EmitSound("Hero_EmberSpirit.FlameGuard.Cast")
	return true
end

function xhs_illidan_immolation_burst:OnAbilityPhaseInterrupted()
	if IsServer() then
		ClearImmolationPrecast(self, true)
		HideBossCastBar(self)
	end
end

function xhs_illidan_immolation_burst:OnSpellStart()
	if not IsServer() then return end
	ClearImmolationPrecast(self, false)

	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	local pulseCount = math.max(1, math.floor(self:GetSpecialValueFor("pulse_count")))
	local pulseInterval = math.max(0.1, self:GetSpecialValueFor("pulse_interval"))
	local damage = ScaleDamage(self:GetSpecialValueFor("damage_per_pulse"))
	local pulse = 0

	Timers:CreateTimer(0, function()
		if not IsValidAlive(caster) then return nil end

		pulse = pulse + 1
		DamageEnemies(caster, self, caster:GetAbsOrigin(), radius, damage, DAMAGE_TYPE_PURE)
		CreateRadialImpact(caster:GetAbsOrigin(), radius, IMMOLATION_PULSE_PARTICLE)
		if pulse == 1 then
			EmitLocationSound(caster, caster:GetAbsOrigin(), "Hero_Phoenix.SuperNova.Explode")
		end

		if pulse < pulseCount then return pulseInterval end
		return nil
	end)

	HideBossCastBar(self)
	ClearContext(self)
end

function xhs_illidan_glaive_storm:OnAbilityPhaseStart()
	if not IsServer() then return true end

	local context = GetContext(self)
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")

	StartBossCastBar(self, "Glaive Storm")
	local castParticle = ParticleManager:CreateParticle(GLAIVE_STORM_CAST_PARTICLE, PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(castParticle, 0, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(castParticle)
	for _, point in pairs(context.points or {}) do
		XHSBossTelegraphs:Circle(point.position, radius, self:GetCastPoint() + (point.delay or 0), ILLIDAN_COLORS)
	end

	StartAnimation(caster, { duration = self:GetCastPoint() + 0.35, activity = ACT_DOTA_CAST_ABILITY_1, rate = 1.0 })
	caster:EmitSound("Hero_Terrorblade.ConjureImage")
	return true
end

function xhs_illidan_glaive_storm:OnAbilityPhaseInterrupted()
	if IsServer() then HideBossCastBar(self) end
end

function xhs_illidan_glaive_storm:OnSpellStart()
	if not IsServer() then return end

	local context = GetContext(self)
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	local damage = ScaleDamage(self:GetSpecialValueFor("damage"))

	for _, point in pairs(context.points or {}) do
		Timers:CreateTimer(point.delay or 0, function()
			if not IsValidAlive(caster) then return nil end
			DamageEnemies(caster, self, point.position, radius, damage, self:GetAbilityDamageType())
			CreateGlaiveStormImpact(caster, point.position, radius)
			EmitLocationSound(caster, point.position, "Hero_Luna.Eclipse.Target")
			caster:EmitSound("Hero_Terrorblade_Morphed.Attack")
			return nil
		end)
	end

	ClearContext(self)
end

function xhs_illidan_demon_hunter:GetIntrinsicModifierName()
	return "modifier_xhs_illidan_demon_hunter"
end

function modifier_xhs_illidan_metamorphosis:IsHidden() return false end
function modifier_xhs_illidan_metamorphosis:IsPurgable() return false end
function modifier_xhs_illidan_metamorphosis:GetTexture() return "terrorblade_metamorphosis" end

function modifier_xhs_illidan_metamorphosis:RefreshValues()
	self.damage_pct = self:GetAbility() and self:GetAbility():GetSpecialValueFor("bonus_damage_pct") or 15
	self.attack_speed = self:GetAbility() and self:GetAbility():GetSpecialValueFor("bonus_attack_speed") or 80
	self.attack_range = self:GetAbility() and self:GetAbility():GetSpecialValueFor("bonus_attack_range") or 350
	self.cleave_radius = self:GetAbility() and self:GetAbility():GetSpecialValueFor("cleave_radius") or 325
	self.cleave_pct = self:GetAbility() and self:GetAbility():GetSpecialValueFor("cleave_pct") or 35
	self.model_scale = self:GetAbility() and self:GetAbility():GetSpecialValueFor("model_scale_bonus") or 18
end

function modifier_xhs_illidan_metamorphosis:OnCreated()
	self:RefreshValues()

	if not IsServer() then return end

	local parent = self:GetParent()
	self.original_attack_capability = parent:GetAttackCapability()
	self.original_model = ILLIDAN_BASE_MODEL
	if parent.GetRangedProjectileName ~= nil then
		self.original_projectile = parent:GetRangedProjectileName()
	end
	self.hidden_wearables = {}

	local wearable = parent:FirstMoveChild()
	while wearable ~= nil do
		if wearable:GetClassname() == "dota_item_wearable" then
			wearable:AddEffects(EF_NODRAW)
			self.hidden_wearables[#self.hidden_wearables + 1] = wearable
		end
		wearable = wearable:NextMovePeer()
	end

	-- A direct model swap is required for creature-based bosses. The modifier
	-- property alone is not consistently applied to npc_dota_creature units.
	parent:SetOriginalModel(METAMORPHOSIS_MODEL)
	parent:SetModel(METAMORPHOSIS_MODEL)
	parent:SetAttackCapability(DOTA_UNIT_CAP_RANGED_ATTACK)
	parent:SetRangedProjectileName(METAMORPHOSIS_ATTACK_PARTICLE)

	self.ambient_pfx = ParticleManager:CreateParticle(METAMORPHOSIS_AMBIENT_PARTICLE, PATTACH_ABSORIGIN_FOLLOW, parent)
	ParticleManager:SetParticleControlEnt(self.ambient_pfx, 0, parent, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
	self:AddParticle(self.ambient_pfx, false, false, -1, false, false)

	parent:EmitSound("Hero_Terrorblade.Metamorphosis.Scepter")
	UpdateMetamorphosisCounter(self)
	self:StartIntervalThink(0.2)
end

function modifier_xhs_illidan_metamorphosis:OnRefresh()
	self:RefreshValues()
	if IsServer() then
		self.xhs_last_counter_remaining = nil
		UpdateMetamorphosisCounter(self)
	end
end

function modifier_xhs_illidan_metamorphosis:OnIntervalThink()
	if not IsServer() then return end
	UpdateMetamorphosisCounter(self)
end

function modifier_xhs_illidan_metamorphosis:OnDestroy()
	if not IsServer() then return end

	local parent = self:GetParent()
	if parent == nil or parent:IsNull() then return end
	HideMetamorphosisCounter(parent)

	if self.original_attack_capability ~= nil then
		parent:SetAttackCapability(self.original_attack_capability)
	end
	if self.original_projectile ~= nil then
		parent:SetRangedProjectileName(self.original_projectile)
	end
	if self.original_model ~= nil and self.original_model ~= "" then
		parent:SetOriginalModel(self.original_model)
		parent:SetModel(self.original_model)
	end
	for _, wearable in pairs(self.hidden_wearables or {}) do
		if wearable ~= nil and IsValidEntity(wearable) and not wearable:IsNull() then
			wearable:RemoveEffects(EF_NODRAW)
		end
	end
end

function modifier_xhs_illidan_metamorphosis:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
		MODIFIER_PROPERTY_MODEL_CHANGE,
		MODIFIER_PROPERTY_MODEL_SCALE,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_xhs_illidan_metamorphosis:GetModifierBaseDamageOutgoing_Percentage()
	return self.damage_pct or 15
end

function modifier_xhs_illidan_metamorphosis:GetModifierAttackSpeedBonus_Constant()
	return self.attack_speed or 80
end

function modifier_xhs_illidan_metamorphosis:GetModifierAttackRangeBonus()
	return self.attack_range or 350
end

function modifier_xhs_illidan_metamorphosis:GetModifierModelChange()
	return METAMORPHOSIS_MODEL
end

function modifier_xhs_illidan_metamorphosis:GetModifierModelScale()
	return self.model_scale or 18
end

function modifier_xhs_illidan_metamorphosis:OnAttackLanded(event)
	if not IsServer() then return end
	if event.attacker ~= self:GetParent() or event.target == nil then return end
	if event.target:IsBuilding() then return end

	local parent = self:GetParent()
	local ability = self:GetAbility()
	local radius = self.cleave_radius or 325
	local cleaveDamage = (event.damage or 0) * ((self.cleave_pct or 35) / 100)
	if cleaveDamage <= 0 then return end

	local cleaveParticle = ParticleManager:CreateParticle(METAMORPHOSIS_CLEAVE_PARTICLE, PATTACH_ABSORIGIN_FOLLOW, event.target)
	ParticleManager:SetParticleControl(cleaveParticle, 0, event.target:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(cleaveParticle)

	local enemies = FindUnitsInRadius(
		parent:GetTeamNumber(),
		event.target:GetAbsOrigin(),
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		FIND_ANY_ORDER,
		false
	)

	for _, enemy in pairs(enemies) do
		if enemy ~= event.target and IsValidAlive(enemy) and not enemy:IsBuilding() and not enemy:IsInvulnerable() then
			ApplyDamage({
				victim = enemy,
				attacker = parent,
				ability = ability,
				damage = cleaveDamage,
				damage_type = self:GetAbility():GetAbilityDamageType(),
			})
		end
	end
end

function modifier_xhs_illidan_demon_hunter:IsHidden() return false end
function modifier_xhs_illidan_demon_hunter:IsPurgable() return false end
function modifier_xhs_illidan_demon_hunter:GetTexture() return "phantom_assassin_blur" end

function modifier_xhs_illidan_demon_hunter:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_EVASION_CONSTANT,
	}
end

function modifier_xhs_illidan_demon_hunter:GetModifierEvasion_Constant()
	local ability = self:GetAbility()
	if ability == nil then return 15 end
	return ability:GetSpecialValueFor("evasion")
end
