require("boss_scripts/phase3_ai/core")
require("boss_scripts/phase3_ai/telegraphs")

xhs_magtheridon_brutal_slam = xhs_magtheridon_brutal_slam or class({})
xhs_magtheridon_fel_stomp = xhs_magtheridon_fel_stomp or class({})
xhs_magtheridon_targeted_firestorms = xhs_magtheridon_targeted_firestorms or class({})
xhs_magtheridon_fel_fissure = xhs_magtheridon_fel_fissure or class({})
xhs_magtheridon_infernal_rings = xhs_magtheridon_infernal_rings or class({})
xhs_magtheridon_demonic_howl = xhs_magtheridon_demonic_howl or class({})
xhs_magtheridon_rupture = xhs_magtheridon_rupture or class({})

local FIRE_IMPACT_PARTICLE = "particles/units/heroes/hero_invoker/invoker_chaos_meteor_land_soil.vpcf"
local FIRE_CRUMBLE_PARTICLE = "particles/units/heroes/hero_invoker/invoker_chaos_meteor_crumble.vpcf"
local STOMP_PARTICLE = "particles/units/heroes/hero_brewmaster/brewmaster_thunder_clap.vpcf"
local HOWL_PARTICLE = "particles/units/heroes/hero_lycan/lycan_howl_cast.vpcf"

local FEL_COLORS = {
	primary = Vector(255, 110, 35),
	secondary = Vector(120, 255, 80),
}

local function IsValidAlive(unit)
	return unit ~= nil and IsValidEntity(unit) and not unit:IsNull() and unit:IsAlive()
end

local function ScaleDamage(value)
	if XHSPhase3BossAI ~= nil and XHSPhase3BossAI.ScaleDamage ~= nil then
		return XHSPhase3BossAI:ScaleDamage(value)
	end

	return value or 0
end

local function GetContext(ability)
	return ability.xhs_magtheridon_context or {}
end

local function ClearContext(ability)
	ability.xhs_magtheridon_context = nil
end

local function GetCastPoint(ability)
	if ability ~= nil and ability.GetCastPoint ~= nil then
		local castPoint = ability:GetCastPoint()
		if castPoint ~= nil and castPoint > 0 then return castPoint end
	end

	return ability:GetSpecialValueFor("cast_point")
end

local function DamageEnemies(attacker, ability, position, radius, damage, damageType)
	if not IsValidAlive(attacker) then return end

	local units = FindUnitsInRadius(
		attacker:GetTeamNumber(),
		position,
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		FIND_ANY_ORDER,
		false
	)

	for _, target in pairs(units) do
		if IsValidAlive(target) and not target:IsInvulnerable() then
			ApplyDamage({
				victim = target,
				attacker = attacker,
				ability = ability,
				damage = ScaleDamage(damage),
				damage_type = damageType or DAMAGE_TYPE_PURE,
			})
		end
	end
end

local function ApplySlow(attacker, target, duration, movementSlow, attackSlow)
	if not IsValidAlive(target) then return end

	target:AddNewModifier(attacker, nil, "modifier_xhs_magtheridon_slow", {
		duration = duration,
		movement_slow = movementSlow,
		attack_slow = attackSlow,
	})
end

local function CreateImpact(position, radius, particleName)
	local particle = ParticleManager:CreateParticle(particleName or FIRE_IMPACT_PARTICLE, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius, 0, 0))
	ParticleManager:ReleaseParticleIndex(particle)
end

local function PositionOnRing(center, radius, index, count, offsetDegrees)
	local angle = ((index - 1) / count) * 360 + (offsetDegrees or 0)
	return RotatePosition(center, QAngle(0, angle, 0), center + Vector(radius, 0, 0))
end

function xhs_magtheridon_brutal_slam:OnAbilityPhaseStart()
	if not IsServer() then return true end

	local context = GetContext(self)
	local caster = self:GetCaster()
	local position = context.position or caster:GetAbsOrigin()
	local radius = self:GetSpecialValueFor("radius")
	local castPoint = GetCastPoint(self)

	XHSBossTelegraphs:Target(position, radius, castPoint, FEL_COLORS)
	caster:EmitSound("Hero_AbyssalUnderlord.Attack")
	StartAnimation(caster, { duration = castPoint + 0.25, activity = ACT_DOTA_ATTACK, rate = 0.95 })
	return true
end

function xhs_magtheridon_brutal_slam:OnSpellStart()
	if not IsServer() then return end

	local context = GetContext(self)
	local caster = self:GetCaster()
	local position = context.position or caster:GetAbsOrigin()
	local radius = self:GetSpecialValueFor("radius")
	local damageTarget = IsValidAlive(context.target) and context.target or caster
	local damage = caster:GetAverageTrueAttackDamage(damageTarget) * self:GetSpecialValueFor("attack_damage_pct") * 0.01

	CreateImpact(position, radius, FIRE_CRUMBLE_PARTICLE)
	DamageEnemies(caster, self, position, radius, damage, DAMAGE_TYPE_PHYSICAL)
	ClearContext(self)
end

function xhs_magtheridon_fel_stomp:OnAbilityPhaseStart()
	if not IsServer() then return true end

	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	local castPoint = GetCastPoint(self)

	XHSBossTelegraphs:Circle(caster:GetAbsOrigin(), radius, castPoint, FEL_COLORS)
	caster:EmitSound("Hero_Brewmaster.ThunderClap")
	StartAnimation(caster, { duration = castPoint + 0.2, activity = ACT_DOTA_CAST_ABILITY_2, rate = 0.85 })
	return true
end

function xhs_magtheridon_fel_stomp:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	local damage = self:GetSpecialValueFor("damage") * self:GetSpecialValueFor("damage_pct") * 0.01
	local slowDuration = self:GetSpecialValueFor("slow_duration")

	CreateImpact(caster:GetAbsOrigin(), radius, STOMP_PARTICLE)
	DamageEnemies(caster, self, caster:GetAbsOrigin(), radius, damage, DAMAGE_TYPE_PURE)

	local units = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
	for _, unit in pairs(units) do
		ApplySlow(caster, unit, slowDuration, self:GetSpecialValueFor("movement_slow"), self:GetSpecialValueFor("attack_slow"))
	end

	ClearContext(self)
end

function xhs_magtheridon_targeted_firestorms:OnAbilityPhaseStart()
	if not IsServer() then return true end

	local context = GetContext(self)
	local caster = self:GetCaster()
	local castPoint = GetCastPoint(self)
	local radius = self:GetSpecialValueFor("radius")

	caster:EmitSound("Hero_AbyssalUnderlord.Firestorm.Cast")
	StartAnimation(caster, { duration = castPoint + 0.4, activity = ACT_DOTA_CAST_ABILITY_1, rate = 0.9 })

	for _, entry in pairs(context.impacts or {}) do
		XHSBossTelegraphs:Target(entry.position, radius, castPoint + (entry.delay or 0), FEL_COLORS)
	end

	return true
end

function xhs_magtheridon_targeted_firestorms:OnSpellStart()
	if not IsServer() then return end

	local context = GetContext(self)
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	local damage = self:GetSpecialValueFor("wave_damage") * self:GetSpecialValueFor("damage_pct") * 0.01

	for _, entry in pairs(context.impacts or {}) do
		local position = entry.position
		Timers:CreateTimer(entry.delay or 0, function()
			if not IsValidAlive(caster) then return nil end
			CreateImpact(position, radius, FIRE_IMPACT_PARTICLE)
			DamageEnemies(caster, self, position, radius, damage, DAMAGE_TYPE_PURE)
			return nil
		end)
	end

	ClearContext(self)
end

function xhs_magtheridon_fel_fissure:OnAbilityPhaseStart()
	if not IsServer() then return true end

	local context = GetContext(self)
	local caster = self:GetCaster()
	local castPoint = GetCastPoint(self)
	local radius = self:GetSpecialValueFor("radius")

	StartAnimation(caster, { duration = castPoint + 0.2, activity = ACT_DOTA_CAST_ABILITY_1, rate = 0.85 })
	for _, entry in pairs(context.impacts or {}) do
		XHSBossTelegraphs:Circle(entry.position, radius, castPoint + (entry.delay or 0), FEL_COLORS)
	end

	return true
end

function xhs_magtheridon_fel_fissure:OnSpellStart()
	if not IsServer() then return end

	local context = GetContext(self)
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	local damage = self:GetSpecialValueFor("wave_damage") * self:GetSpecialValueFor("damage_pct") * 0.01

	for _, entry in pairs(context.impacts or {}) do
		local position = entry.position
		Timers:CreateTimer(entry.delay or 0, function()
			if not IsValidAlive(caster) then return nil end
			CreateImpact(position, radius, FIRE_CRUMBLE_PARTICLE)
			DamageEnemies(caster, self, position, radius, damage, DAMAGE_TYPE_PURE)
			return nil
		end)
	end

	ClearContext(self)
end

function xhs_magtheridon_infernal_rings:OnAbilityPhaseStart()
	if not IsServer() then return true end

	local context = GetContext(self)
	local caster = self:GetCaster()
	local castPoint = GetCastPoint(self)
	local radius = self:GetSpecialValueFor("radius")

	caster:EmitSound("Hero_AbyssalUnderlord.PitOfMalice")
	StartAnimation(caster, { duration = castPoint + 0.2, activity = ACT_DOTA_CAST_ABILITY_3, rate = 0.85 })
	for _, entry in pairs(context.impacts or {}) do
		XHSBossTelegraphs:Circle(entry.position, radius, castPoint + (entry.delay or 0), FEL_COLORS)
	end

	return true
end

function xhs_magtheridon_infernal_rings:OnSpellStart()
	if not IsServer() then return end

	local context = GetContext(self)
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	local damage = self:GetSpecialValueFor("wave_damage") * self:GetSpecialValueFor("damage_pct") * 0.01

	for _, entry in pairs(context.impacts or {}) do
		local position = entry.position
		Timers:CreateTimer(entry.delay or 0, function()
			if not IsValidAlive(caster) then return nil end
			CreateImpact(position, radius, FIRE_IMPACT_PARTICLE)
			DamageEnemies(caster, self, position, radius, damage, DAMAGE_TYPE_PURE)
			return nil
		end)
	end

	ClearContext(self)
end

function xhs_magtheridon_demonic_howl:OnAbilityPhaseStart()
	if not IsServer() then return true end

	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	local castPoint = GetCastPoint(self)

	XHSBossTelegraphs:Circle(caster:GetAbsOrigin(), radius, castPoint, FEL_COLORS)
	StartAnimation(caster, { duration = castPoint + 0.2, activity = ACT_DOTA_CAST_ABILITY_4, rate = 0.85 })
	return true
end

function xhs_magtheridon_demonic_howl:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	local duration = self:GetSpecialValueFor("duration")
	local howl = ParticleManager:CreateParticle(HOWL_PARTICLE, PATTACH_OVERHEAD_FOLLOW, caster)
	ParticleManager:ReleaseParticleIndex(howl)
	caster:EmitSound("Hero_Lycan.Howl")

	local units = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
	for _, unit in pairs(units) do
		if IsValidAlive(unit) then
			ApplySlow(caster, unit, duration, self:GetSpecialValueFor("movement_slow"), self:GetSpecialValueFor("attack_slow"))
		end
	end

	ClearContext(self)
end

function xhs_magtheridon_rupture:GetIntrinsicModifierName()
	return nil
end

function xhs_magtheridon_rupture:GetBehavior()
	return DOTA_ABILITY_BEHAVIOR_PASSIVE
end

function xhs_magtheridon_rupture:SpawnRingPositions(center, ringRadius, count, offsetDegrees)
	local positions = {}
	for i = 1, count do
		positions[#positions + 1] = PositionOnRing(center, ringRadius, i, count, offsetDegrees)
	end

	return positions
end
