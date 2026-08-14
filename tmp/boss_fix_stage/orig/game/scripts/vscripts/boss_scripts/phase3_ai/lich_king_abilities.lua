require("boss_scripts/phase3_ai/core")
require("boss_scripts/phase3_ai/telegraphs")
require("boss_scripts/phase3_ai/cast_bar")

xhs_lich_king_frozen_throne = xhs_lich_king_frozen_throne or class({})
xhs_lich_king_remorseless_winter = xhs_lich_king_remorseless_winter or class({})
xhs_lich_king_frostmourne_hunger = xhs_lich_king_frostmourne_hunger or class({})
xhs_lich_king_howling_blast = xhs_lich_king_howling_blast or class({})
xhs_lich_king_glacial_spikes = xhs_lich_king_glacial_spikes or class({})
xhs_lich_king_defile = xhs_lich_king_defile or class({})
xhs_lich_king_sindragosa_flyby = xhs_lich_king_sindragosa_flyby or class({})

modifier_xhs_lich_king_frost_slow = modifier_xhs_lich_king_frost_slow or class({})
modifier_xhs_lich_king_frost_slow.XHS_LINK_CLIENT = true
modifier_xhs_lich_king_remorseless = modifier_xhs_lich_king_remorseless or class({})
modifier_xhs_lich_king_remorseless.XHS_LINK_CLIENT = true
modifier_xhs_lich_king_frozen_throne = modifier_xhs_lich_king_frozen_throne or class({})
modifier_xhs_lich_king_frozen_throne.XHS_LINK_CLIENT = true
modifier_xhs_lich_king_frostbite = modifier_xhs_lich_king_frostbite or class({})
modifier_xhs_lich_king_frostbite.XHS_LINK_CLIENT = true

LinkLuaModifier("modifier_xhs_lich_king_frost_slow", "boss_scripts/phase3_ai/lich_king_abilities.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_lich_king_remorseless", "boss_scripts/phase3_ai/lich_king_abilities.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_lich_king_frozen_throne", "boss_scripts/phase3_ai/lich_king_abilities.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_lich_king_frostbite", "boss_scripts/phase3_ai/lich_king_abilities.lua", LUA_MODIFIER_MOTION_NONE)

local LICH_COLORS = {
	primary = Vector(120, 220, 255),
	secondary = Vector(235, 250, 255),
	style = 7,
}

local DARK_COLORS = {
	primary = Vector(40, 90, 150),
	secondary = Vector(160, 225, 255),
	style = 6,
}

local FROST_NOVA_PARTICLE = "particles/units/heroes/hero_lich/lich_frost_nova.vpcf"
local FROSTMOURNE_PARTICLE = "particles/units/heroes/hero_abaddon/abaddon_death_coil_explosion.vpcf"
local GLACIAL_SPIKE_PARTICLE = "particles/econ/items/crystal_maiden/crystal_maiden_cowl_of_ice/maiden_crystal_nova_cowlofice.vpcf"
local DEFILE_PARTICLE = "particles/units/heroes/hero_abaddon/abaddon_aphotic_shield_explosion.vpcf"
local SINDRAGOSA_PARTICLE = "particles/units/heroes/hero_winter_wyvern/wyvern_splinter_blast.vpcf"

local CollectTargets

local function IsValidAlive(unit)
	return unit ~= nil and IsValidEntity(unit) and not unit:IsNull() and unit:IsAlive()
end

local function GetContext(ability)
	return ability.xhs_lich_king_context or {}
end

local function ClearContext(ability)
	ability.xhs_lich_king_context = nil
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
			style = "lich_king",
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

local function GetFrozenThroneAbility(caster)
	if not IsValidAlive(caster) then return nil end
	local ability = caster:FindAbilityByName("xhs_lich_king_frozen_throne")
	if ability == nil or ability:IsNull() or ability:GetLevel() <= 0 then return nil end
	return ability
end

local function GrantFrostmourneSouls(caster, amount)
	local ability = GetFrozenThroneAbility(caster)
	if ability == nil then return end

	local modifier = caster:FindModifierByName("modifier_xhs_lich_king_frozen_throne")
	if modifier == nil then
		modifier = caster:AddNewModifier(caster, ability, "modifier_xhs_lich_king_frozen_throne", {})
	end
	if modifier == nil then return end

	local cap = math.max(1, ability:GetSpecialValueFor("soul_cap"))
	modifier:SetStackCount(math.min(cap, modifier:GetStackCount() + math.max(1, amount or 1)))
end

local function ApplyFrostbite(caster, sourceAbility, enemy, amount)
	if not IsValidAlive(enemy) or not enemy:IsRealHero() then return end

	local ability = GetFrozenThroneAbility(caster) or sourceAbility
	if ability == nil then return end

	local duration = ability:GetSpecialValueFor("frostbite_duration")
	local cap = math.max(1, ability:GetSpecialValueFor("frostbite_cap"))
	local modifier = enemy:AddNewModifier(caster, ability, "modifier_xhs_lich_king_frostbite", { duration = duration })
	if modifier ~= nil then
		modifier:SetStackCount(math.min(cap, modifier:GetStackCount() + math.max(1, amount or 1)))
	end

	GrantFrostmourneSouls(caster, amount or 1)
end

local function ConsumeFrostbite(caster, position, radius)
	local ability = GetFrozenThroneAbility(caster)
	if ability == nil then return 0 end

	local consumed = 0
	for _, enemy in pairs(CollectTargets(caster, position, radius, DOTA_UNIT_TARGET_HERO)) do
		local modifier = enemy:FindModifierByName("modifier_xhs_lich_king_frostbite")
		if modifier ~= nil then
			consumed = consumed + modifier:GetStackCount()
			modifier:Destroy()
		end
	end

	return consumed
end

CollectTargets = function(caster, position, radius, targetTypes)
	local targets = {}
	local seen = {}
	if not IsValidAlive(caster) or position == nil then return targets end
	targetTypes = targetTypes or DOTA_UNIT_TARGET_HERO

	local function AddUnits(units)
		for _, unit in pairs(units or {}) do
			if unit ~= nil and IsValidEntity(unit) and not unit:IsNull() and seen[unit:entindex()] ~= true then
				seen[unit:entindex()] = true
				table.insert(targets, unit)
			end
		end
	end

	AddUnits(FindUnitsInRadius(
		caster:GetTeamNumber(),
		position,
		nil,
		radius or 200,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		targetTypes,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		FIND_ANY_ORDER,
		false
	))

	AddUnits(FindUnitsInRadius(
		DOTA_TEAM_GOODGUYS,
		position,
		nil,
		radius or 200,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		targetTypes,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		FIND_ANY_ORDER,
		false
	))

	return targets
end

local function DamageEnemies(caster, ability, position, radius, damage, damageType, frostbiteStacks)
	if not IsValidAlive(caster) or position == nil then return end

	for _, enemy in pairs(CollectTargets(caster, position, radius, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC)) do
		if IsValidAlive(enemy) and not enemy:IsInvulnerable() then
			ApplyDamage({
				victim = enemy,
				attacker = caster,
				ability = ability,
				damage = damage or 0,
				damage_type = damageType or DAMAGE_TYPE_MAGICAL,
			})
			if frostbiteStacks ~= nil and frostbiteStacks > 0 then
				ApplyFrostbite(caster, ability, enemy, frostbiteStacks)
			end
		end
	end
end

local function SlowEnemies(caster, ability, position, radius, duration)
	for _, enemy in pairs(CollectTargets(caster, position, radius, DOTA_UNIT_TARGET_HERO)) do
		if IsValidAlive(enemy) then
			enemy:AddNewModifier(caster, ability, "modifier_xhs_lich_king_frost_slow", { duration = duration or 1.5 })
		end
	end
end

local function CreateImpact(position, particleName, radius, duration)
	local particle = ParticleManager:CreateParticle(particleName, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius or 220, 0, 0))
	Timers:CreateTimer(duration or 0.9, function()
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

function xhs_lich_king_frozen_throne:GetIntrinsicModifierName()
	return "modifier_xhs_lich_king_frozen_throne"
end

function xhs_lich_king_remorseless_winter:OnAbilityPhaseStart()
	if not IsServer() then return true end
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	StartBossCastBar(self, "Remorseless Winter")
	XHSBossTelegraphs:Circle(caster:GetAbsOrigin(), radius, self:GetCastPoint(), LICH_COLORS)
	XHSBossTelegraphs:Ring(caster:GetAbsOrigin(), radius * 0.65, 155, 12, self:GetCastPoint(), LICH_COLORS, 15)
	StartAnimation(caster, { duration = self:GetCastPoint() + 0.25, activity = ACT_DOTA_CAST_ABILITY_4, rate = 0.75 })
	caster:EmitSound("Hero_Lich.IceAge")
	return true
end

function xhs_lich_king_remorseless_winter:OnAbilityPhaseInterrupted()
	if IsServer() then HideBossCastBar(self) end
end

function xhs_lich_king_remorseless_winter:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	DamageEnemies(caster, self, caster:GetAbsOrigin(), radius, ScaleDamage(self:GetSpecialValueFor("damage")), DAMAGE_TYPE_PURE, 2)
	SlowEnemies(caster, self, caster:GetAbsOrigin(), radius, self:GetSpecialValueFor("slow_duration"))
	caster:AddNewModifier(caster, self, "modifier_xhs_lich_king_remorseless", { duration = self:GetSpecialValueFor("buff_duration") })
	CreateImpact(caster:GetAbsOrigin(), FROST_NOVA_PARTICLE, radius, 0.9)
	EmitLocationSound(caster, caster:GetAbsOrigin(), "Hero_Lich.FrostBlast")
	ClearContext(self)
end

function xhs_lich_king_frostmourne_hunger:OnAbilityPhaseStart()
	if not IsServer() then return true end
	local caster = self:GetCaster()
	local position = GetContext(self).position or self:GetCaster():GetAbsOrigin()
	StartBossCastBar(self, "Frostmourne Hunger")
	XHSBossTelegraphs:Target(position, self:GetSpecialValueFor("radius"), self:GetCastPoint(), DARK_COLORS)
	local particle = ParticleManager:CreateParticle(FROSTMOURNE_PARTICLE, PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(particle, 0, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(particle, 1, Vector(self:GetSpecialValueFor("radius"), 0, 0))
	Timers:CreateTimer(self:GetCastPoint() + 0.05, function()
		ParticleManager:DestroyParticle(particle, false)
		ParticleManager:ReleaseParticleIndex(particle)
		return nil
	end)
	StartAnimation(caster, { duration = self:GetCastPoint() + 0.15, activity = ACT_DOTA_CAST_ABILITY_1, rate = 0.9 })
	caster:EmitSound("Hero_SkeletonKing.CriticalStrike")
	return true
end

function xhs_lich_king_frostmourne_hunger:OnAbilityPhaseInterrupted()
	if IsServer() then HideBossCastBar(self) end
end

function xhs_lich_king_frostmourne_hunger:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local position = GetContext(self).position or caster:GetAbsOrigin()
	local radius = self:GetSpecialValueFor("radius")
	local consumedFrostbite = ConsumeFrostbite(caster, position, radius)
	local throne = GetFrozenThroneAbility(caster)
	local bonusPct = throne and throne:GetSpecialValueFor("frostbite_hunger_damage_pct") or 0
	local damage = ScaleDamage(self:GetSpecialValueFor("damage")) * (1 + consumedFrostbite * bonusPct * 0.01)
	DamageEnemies(caster, self, position, radius, damage, DAMAGE_TYPE_PURE, 1)
	SlowEnemies(caster, self, position, radius, self:GetSpecialValueFor("slow_duration"))
	caster:Heal(damage * self:GetSpecialValueFor("heal_pct") * 0.01, self)
	CreateImpact(position, FROSTMOURNE_PARTICLE, radius, 0.8)
	EmitLocationSound(caster, position, "Hero_SkeletonKing.Hellfire_BlastImpact")
	ClearContext(self)
end

function xhs_lich_king_howling_blast:OnAbilityPhaseStart()
	if not IsServer() then return true end
	local caster = self:GetCaster()
	local direction = NormalizeDirection(GetContext(self).direction or caster:GetForwardVector())
	StartBossCastBar(self, "Howling Blast")
	XHSBossTelegraphs:Line(caster:GetAbsOrigin(), direction, self:GetSpecialValueFor("spacing"), self:GetSpecialValueFor("radius"), self:GetSpecialValueFor("nodes"), self:GetCastPoint(), LICH_COLORS, 160)
	StartAnimation(caster, { duration = self:GetCastPoint() + 0.1, activity = ACT_DOTA_CAST_ABILITY_2, rate = 0.95 })
	caster:EmitSound("Hero_Lich.FrostBlast")
	caster:EmitSound("Hero_Crystal.Frostbite")
	return true
end

function xhs_lich_king_howling_blast:OnAbilityPhaseInterrupted()
	if IsServer() then HideBossCastBar(self) end
end

function xhs_lich_king_howling_blast:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local direction = NormalizeDirection(GetContext(self).direction or caster:GetForwardVector())
	local spacing = self:GetSpecialValueFor("spacing")
	local radius = self:GetSpecialValueFor("radius")
	caster:EmitSound("Hero_Lich.ChainFrost")
	for i = 1, self:GetSpecialValueFor("nodes") do
		local position = caster:GetAbsOrigin() + direction * (160 + spacing * (i - 1))
		DamageEnemies(caster, self, position, radius, ScaleDamage(self:GetSpecialValueFor("damage")), DAMAGE_TYPE_PURE, 1)
		SlowEnemies(caster, self, position, radius, self:GetSpecialValueFor("slow_duration"))
		CreateImpact(position, FROST_NOVA_PARTICLE, radius, 0.65)
		EmitLocationSound(caster, position, "Hero_Lich.FrostBlast")
	end
	ClearContext(self)
end

function xhs_lich_king_glacial_spikes:OnAbilityPhaseStart()
	if not IsServer() then return true end
	StartBossCastBar(self, "Glacial Spikes")
	local points = GetContext(self).points or {}
	if #points <= 0 then
		points = { { position = self:GetCaster():GetAbsOrigin() } }
	end
	for _, point in pairs(points) do
		XHSBossTelegraphs:Target(point.position, self:GetSpecialValueFor("radius"), self:GetCastPoint(), LICH_COLORS)
	end
	StartAnimation(self:GetCaster(), { duration = self:GetCastPoint() + 0.1, activity = ACT_DOTA_CAST_ABILITY_3, rate = 0.9 })
	return true
end

function xhs_lich_king_glacial_spikes:OnAbilityPhaseInterrupted()
	if IsServer() then HideBossCastBar(self) end
end

function xhs_lich_king_glacial_spikes:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	for _, point in pairs(GetContext(self).points or {}) do
		DamageEnemies(caster, self, point.position, radius, ScaleDamage(self:GetSpecialValueFor("damage")), DAMAGE_TYPE_PURE, 1)
		SlowEnemies(caster, self, point.position, radius, self:GetSpecialValueFor("slow_duration"))
		CreateImpact(point.position, GLACIAL_SPIKE_PARTICLE, radius, 0.8)
		EmitLocationSound(caster, point.position, "Hero_Lich.FrostBlast")
	end
	ClearContext(self)
end

function xhs_lich_king_defile:OnAbilityPhaseStart()
	if not IsServer() then return true end
	StartBossCastBar(self, "Defile")
	for _, point in pairs(GetContext(self).points or {}) do
		XHSBossTelegraphs:Circle(point.position, self:GetSpecialValueFor("radius"), self:GetCastPoint(), DARK_COLORS)
	end
	StartAnimation(self:GetCaster(), { duration = self:GetCastPoint() + 0.15, activity = ACT_DOTA_CAST_ABILITY_4, rate = 0.8 })
	self:GetCaster():EmitSound("Hero_Abaddon.Curse.Proc")
	return true
end

function xhs_lich_king_defile:OnAbilityPhaseInterrupted()
	if IsServer() then HideBossCastBar(self) end
end

function xhs_lich_king_defile:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local points = GetContext(self).points or {}
	local duration = self:GetSpecialValueFor("duration")
	local tick = self:GetSpecialValueFor("tick_rate")
	local radius = self:GetSpecialValueFor("radius")
	local damage = ScaleDamage(self:GetSpecialValueFor("damage_per_tick"))
	for _, point in pairs(points) do
		local position = point.position
		CreateImpact(position, DEFILE_PARTICLE, radius, 0.8)
		EmitLocationSound(caster, position, "Hero_Abaddon.AphoticShield.Cast")
		local elapsed = 0
		Timers:CreateTimer(0.0, function()
			if not IsValidAlive(caster) or elapsed > duration then return nil end
			DamageEnemies(caster, self, position, radius, damage, DAMAGE_TYPE_PURE, elapsed == 0 and 1 or 0)
			SlowEnemies(caster, self, position, radius, tick + 0.1)
			elapsed = elapsed + tick
			return tick
		end)
	end
	ClearContext(self)
end

function xhs_lich_king_sindragosa_flyby:OnAbilityPhaseStart()
	if not IsServer() then return true end
	local context = GetContext(self)
	local center = context.center or self:GetCaster():GetAbsOrigin()
	local directions = context.directions or { Vector(1, 0, 0) }
	StartBossCastBar(self, "Sindragosa Flyby")
	for index, direction in pairs(directions) do
		local start = center - NormalizeDirection(direction) * 850 + RotatePosition(Vector(0, 0, 0), QAngle(0, 90, 0), NormalizeDirection(direction)) * ((index - ((#directions + 1) / 2)) * self:GetSpecialValueFor("lane_offset"))
		XHSBossTelegraphs:Line(start, direction, self:GetSpecialValueFor("spacing"), self:GetSpecialValueFor("radius"), self:GetSpecialValueFor("nodes"), self:GetCastPoint(), LICH_COLORS, 0)
	end
	StartAnimation(self:GetCaster(), { duration = self:GetCastPoint() + 0.2, activity = ACT_DOTA_CAST_ABILITY_5, rate = 0.85 })
	if XHSPhase3BossAI ~= nil then
		XHSPhase3BossAI:EmitSoundOnce(self:GetCaster(), "Hero_Winter_Wyvern.WintersCurse.Cast", "sindragosa_precast", self:GetCastPoint())
	else
		self:GetCaster():EmitSound("Hero_Winter_Wyvern.WintersCurse.Cast")
	end
	return true
end

function xhs_lich_king_sindragosa_flyby:OnAbilityPhaseInterrupted()
	if IsServer() then HideBossCastBar(self) end
end

function xhs_lich_king_sindragosa_flyby:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local context = GetContext(self)
	local center = context.center or caster:GetAbsOrigin()
	local directions = context.directions or { Vector(1, 0, 0) }
	local radius = self:GetSpecialValueFor("radius")
	local spacing = self:GetSpecialValueFor("spacing")
	local nodes = self:GetSpecialValueFor("nodes")
	if XHSPhase3BossAI ~= nil then
		XHSPhase3BossAI:EmitSoundOnce(caster, "Hero_Winter_Wyvern.SplinterBlast.Cast", "sindragosa_cast", 2.0)
	else
		caster:EmitSound("Hero_Winter_Wyvern.SplinterBlast.Cast")
	end
	for index, direction in pairs(directions) do
		local normalized = NormalizeDirection(direction)
		local side = RotatePosition(Vector(0, 0, 0), QAngle(0, 90, 0), normalized)
		local start = center - normalized * 850 + side * ((index - ((#directions + 1) / 2)) * self:GetSpecialValueFor("lane_offset"))
		for i = 1, nodes do
			local position = start + normalized * (spacing * (i - 1))
			DamageEnemies(caster, self, position, radius, ScaleDamage(self:GetSpecialValueFor("damage")), DAMAGE_TYPE_PURE, 1)
			SlowEnemies(caster, self, position, radius, self:GetSpecialValueFor("slow_duration"))
			CreateImpact(position, SINDRAGOSA_PARTICLE, radius, 0.65)
		end
	end
	ClearContext(self)
end

function modifier_xhs_lich_king_frost_slow:IsPurgable() return true end
function modifier_xhs_lich_king_frost_slow:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end
function modifier_xhs_lich_king_frost_slow:GetModifierMoveSpeedBonus_Percentage() return -35 end
function modifier_xhs_lich_king_frost_slow:GetModifierAttackSpeedBonus_Constant() return -45 end

function modifier_xhs_lich_king_frozen_throne:IsHidden() return false end
function modifier_xhs_lich_king_frozen_throne:IsPurgable() return false end
function modifier_xhs_lich_king_frozen_throne:RemoveOnDeath() return true end
function modifier_xhs_lich_king_frozen_throne:GetTexture() return "custom/xhs_lich_king_frozen_throne" end
function modifier_xhs_lich_king_frozen_throne:DeclareFunctions()
	return { MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE, MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS }
end
function modifier_xhs_lich_king_frozen_throne:GetModifierBaseDamageOutgoing_Percentage()
	local ability = self:GetAbility()
	if ability == nil then return 0 end
	return self:GetStackCount() * ability:GetSpecialValueFor("soul_damage_pct")
end
function modifier_xhs_lich_king_frozen_throne:GetModifierPhysicalArmorBonus()
	local ability = self:GetAbility()
	if ability == nil then return 0 end
	return self:GetStackCount() * ability:GetSpecialValueFor("soul_armor")
end

function modifier_xhs_lich_king_frostbite:IsPurgable() return true end
function modifier_xhs_lich_king_frostbite:GetTexture() return "custom/xhs_lich_king_frozen_throne" end
function modifier_xhs_lich_king_frostbite:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end
function modifier_xhs_lich_king_frostbite:GetModifierMoveSpeedBonus_Percentage()
	local ability = self:GetAbility()
	if ability == nil then return 0 end
	return -(self:GetStackCount() * ability:GetSpecialValueFor("frostbite_move_slow_pct"))
end
function modifier_xhs_lich_king_frostbite:GetModifierAttackSpeedBonus_Constant()
	local ability = self:GetAbility()
	if ability == nil then return 0 end
	return -(self:GetStackCount() * ability:GetSpecialValueFor("frostbite_attack_slow"))
end

function modifier_xhs_lich_king_remorseless:IsPurgable() return false end
function modifier_xhs_lich_king_remorseless:GetTexture() return "lich_frost_nova" end
function modifier_xhs_lich_king_remorseless:DeclareFunctions()
	return { MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE, MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS }
end
function modifier_xhs_lich_king_remorseless:GetModifierBaseDamageOutgoing_Percentage() return 15 end
function modifier_xhs_lich_king_remorseless:GetModifierPhysicalArmorBonus() return 20 end
