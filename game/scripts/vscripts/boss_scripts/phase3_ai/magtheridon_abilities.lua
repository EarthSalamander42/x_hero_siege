require("boss_scripts/phase3_ai/core")
require("boss_scripts/phase3_ai/telegraphs")
require("boss_scripts/phase3_ai/cast_bar")

xhs_magtheridon_brutal_slam = xhs_magtheridon_brutal_slam or class({})
xhs_magtheridon_fel_stomp = xhs_magtheridon_fel_stomp or class({})
xhs_magtheridon_targeted_firestorms = xhs_magtheridon_targeted_firestorms or class({})
xhs_magtheridon_fel_fissure = xhs_magtheridon_fel_fissure or class({})
xhs_magtheridon_infernal_rings = xhs_magtheridon_infernal_rings or class({})
xhs_magtheridon_demonic_howl = xhs_magtheridon_demonic_howl or class({})
xhs_magtheridon_rupture = xhs_magtheridon_rupture or class({})

LinkLuaModifier("modifier_xhs_magtheridon_infernal_root", "boss_scripts/phase3_ai/magtheridon_abilities.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_magtheridon_demonic_howl", "boss_scripts/phase3_ai/magtheridon_abilities.lua", LUA_MODIFIER_MOTION_NONE)

local BRUTAL_SLAM_PARTICLE = "particles/units/heroes/hero_centaur/centaur_warstomp.vpcf"
local FEL_STOMP_PARTICLE = "particles/units/heroes/hero_brewmaster/brewmaster_thunder_clap.vpcf"
local DARKMOON_AOE_PRECAST_PARTICLE = "particles/econ/events/darkmoon_2017/darkmoon_generic_aoe.vpcf"
local FIRESTORM_PARTICLE = "particles/units/heroes/heroes_underlord/abyssal_underlord_firestorm_wave.vpcf"
local FIRESTORM_PRECAST_PARTICLE = "particles/units/heroes/heroes_underlord/underlord_firestorm_pre.vpcf"
local FEL_FISSURE_PARTICLE = "particles/units/heroes/hero_elder_titan/elder_titan_earth_splitter.vpcf"
local INFERNAL_RING_PARTICLE = "particles/units/heroes/heroes_underlord/underlord_pitofmalice.vpcf"
local INFERNAL_RING_PRECAST_PARTICLE = "particles/units/heroes/heroes_underlord/underlord_pitofmalice_pre.vpcf"
local DEMONIC_HOWL_PARTICLE = "particles/units/heroes/hero_lycan/lycan_howl_cast.vpcf"
local RUPTURE_PARTICLE = "particles/units/heroes/hero_elder_titan/elder_titan_earth_splitter.vpcf"
local INFERNAL_RING_VISUAL_DURATION = 0.45
local EARTH_SPLITTER_RELEASE_BUFFER = 1.35

local BRUTAL_SLAM_PRECAST_SOUND = "Hero_Centaur.Attack"
local BRUTAL_SLAM_IMPACT_SOUND = "Hero_Centaur.HoofStomp"
local FEL_STOMP_PRECAST_SOUND = "Hero_Brewmaster.Attack"
local FEL_STOMP_IMPACT_SOUND = "Hero_Brewmaster.ThunderClap"
local FIRESTORM_PRECAST_SOUND = "Hero_AbyssalUnderlord.Firestorm.Cast"
local FIRESTORM_IMPACT_SOUND = "Hero_AbyssalUnderlord.Firestorm.Target"
local FEL_FISSURE_PRECAST_SOUND = "Hero_ElderTitan.EarthSplitter.Cast"
local FEL_FISSURE_IMPACT_SOUND = "Hero_ElderTitan.EarthSplitter.Destroy"
local INFERNAL_RINGS_PRECAST_SOUND = "Hero_AbyssalUnderlord.PitOfMalice.Start"
local INFERNAL_RINGS_IMPACT_SOUND = "Hero_AbyssalUnderlord.Pit.Target"
local DEMONIC_HOWL_PRECAST_SOUND = "Hero_Lycan.Howl.Team"
local DEMONIC_HOWL_CAST_SOUND = "Hero_Lycan.Howl"
local RUPTURE_PRECAST_SOUND = "Hero_ElderTitan.EarthSplitter.Cast"
local RUPTURE_IMPACT_SOUND = "Hero_ElderTitan.EarthSplitter.Destroy"

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

local function TrackPrecastParticle(ability, particle)
	if ability == nil or particle == nil then return end
	ability.xhs_magtheridon_precast_particles = ability.xhs_magtheridon_precast_particles or {}
	table.insert(ability.xhs_magtheridon_precast_particles, particle)
end

local function ReleaseTrackedPrecastParticle(ability, particle, immediate)
	if ability == nil or particle == nil or ability.xhs_magtheridon_precast_particles == nil then return false end

	for index, trackedParticle in pairs(ability.xhs_magtheridon_precast_particles) do
		if trackedParticle == particle then
			ability.xhs_magtheridon_precast_particles[index] = nil
			ParticleManager:DestroyParticle(particle, immediate == true)
			ParticleManager:ReleaseParticleIndex(particle)
			return true
		end
	end

	return false
end

local function ClearPrecastParticles(ability, immediate)
	if ability == nil or ability.xhs_magtheridon_precast_particles == nil then return end

	local particles = ability.xhs_magtheridon_precast_particles
	ability.xhs_magtheridon_precast_particles = nil

	for _, particle in pairs(particles) do
		ParticleManager:DestroyParticle(particle, immediate == true)
		ParticleManager:ReleaseParticleIndex(particle)
	end
end

local function GetCastPoint(ability)
	if ability ~= nil and ability.GetCastPoint ~= nil then
		local castPoint = ability:GetCastPoint()
		if castPoint ~= nil and castPoint > 0 then return castPoint end
	end

	return ability:GetSpecialValueFor("cast_point")
end

local function StartBossCastBar(ability, displayName)
	if XHSBossCastBar ~= nil then
		XHSBossCastBar:Start(ability:GetCaster(), ability, {
			display_name = displayName,
			style = "magtheridon",
		})
	end
end

local function HideBossCastBar(ability)
	if XHSBossCastBar ~= nil then
		XHSBossCastBar:Hide(ability:GetCaster())
	end
end

local function EmitLocationSound(caster, position, soundName)
	if soundName == nil or position == nil then return end
	if IsValidAlive(caster) then
		EmitSoundOnLocationWithCaster(position, soundName, caster)
	end
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

local function DamageLineEnemies(attacker, ability, startPosition, direction, spacing, radius, count, damage, damageType, startDistance)
	local hitUnits = {}
	if not IsValidAlive(attacker) or startPosition == nil or direction == nil then return hitUnits end

	direction.z = 0
	if direction:Length2D() <= 0 then direction = Vector(1, 0, 0) end
	direction = direction:Normalized()

	local hit = {}
	count = math.max(1, count or 1)
	for i = 1, count do
		local position = startPosition + direction * ((startDistance or 0) + spacing * (i - 1))
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
			local key = target:entindex()
			if hit[key] ~= true and IsValidAlive(target) and not target:IsInvulnerable() then
				hit[key] = true
				ApplyDamage({
					victim = target,
					attacker = attacker,
					ability = ability,
					damage = ScaleDamage(damage),
					damage_type = damageType or DAMAGE_TYPE_PURE,
				})
				hitUnits[#hitUnits + 1] = target
			end
		end
	end

	return hitUnits
end

local function ApplySlow(attacker, target, duration, movementSlow, attackSlow)
	if not IsValidAlive(target) then return end

	target:AddNewModifier(attacker, nil, "modifier_xhs_magtheridon_slow", {
		duration = duration,
		movement_slow = movementSlow,
		attack_slow = attackSlow,
	})
end

local function ApplyRoot(attacker, ability, target, duration)
	if not IsValidAlive(target) then return end

	target:AddNewModifier(attacker, ability, "modifier_xhs_magtheridon_infernal_root", {
		duration = duration,
	})
end

local function ApplyDemonicHowl(attacker, ability, target, duration)
	if not IsValidAlive(target) then return end

	target:AddNewModifier(attacker, ability, "modifier_xhs_magtheridon_demonic_howl", {
		duration = duration,
		movement_slow = ability:GetSpecialValueFor("movement_slow"),
		attack_slow = ability:GetSpecialValueFor("attack_slow"),
		damage_reduction_pct = ability:GetSpecialValueFor("damage_reduction_pct"),
	})
end

local function CreateRadialParticle(position, radius, particleName)
	local particle = ParticleManager:CreateParticle(particleName, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius, radius, radius))
	ParticleManager:ReleaseParticleIndex(particle)
end

local function CreateDarkmoonAOEPrecast(ability, position, radius, duration)
	local particle = ParticleManager:CreateParticle(DARKMOON_AOE_PRECAST_PARTICLE, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius, 0, 0))
	ParticleManager:SetParticleControl(particle, 2, Vector(duration or 1.0, 0, 1))
	ParticleManager:SetParticleControl(particle, 3, FEL_COLORS.primary)
	ParticleManager:SetParticleControl(particle, 4, position)
	TrackPrecastParticle(ability, particle)

	Timers:CreateTimer(math.max(duration or 1.0, 0.03), function()
		ReleaseTrackedPrecastParticle(ability, particle, false)
		return nil
	end)

	return particle
end

local function CreateFirestormWave(position, radius)
	local particle = ParticleManager:CreateParticle(FIRESTORM_PARTICLE, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControl(particle, 4, Vector(radius, 0, 0))
	ParticleManager:ReleaseParticleIndex(particle)
end

local function CreateFirestormPrecast(ability, position)
	return CreateDarkmoonAOEPrecast(ability, position, ability:GetSpecialValueFor("radius"), GetCastPoint(ability))
end

local function CreateEarthSplitterLine(ability, startPosition, endPosition, delay)
	if startPosition == nil or endPosition == nil then return end

	local particle = ParticleManager:CreateParticle(FEL_FISSURE_PARTICLE, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, startPosition)
	ParticleManager:SetParticleControl(particle, 1, endPosition)
	ParticleManager:SetParticleControl(particle, 3, Vector(0, delay or 0, 0))
	TrackPrecastParticle(ability, particle)

	Timers:CreateTimer(math.max((delay or 0) + EARTH_SPLITTER_RELEASE_BUFFER, 0.03), function()
		ReleaseTrackedPrecastParticle(ability, particle, false)
		return nil
	end)
end

local function CreatePitOfMaliceZone(position, radius, duration)
	duration = duration or INFERNAL_RING_VISUAL_DURATION
	local particle = ParticleManager:CreateParticle(INFERNAL_RING_PARTICLE, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius, 1, 1))
	ParticleManager:SetParticleControl(particle, 2, Vector(duration, 0, 0))

	Timers:CreateTimer(duration, function()
		ParticleManager:DestroyParticle(particle, false)
		ParticleManager:ReleaseParticleIndex(particle)
		return nil
	end)
end

local function CreatePitOfMalicePrecast(ability, position, radius)
	return CreateDarkmoonAOEPrecast(ability, position, radius, GetCastPoint(ability))
end

local function CreateFissureLine(ability, startPosition, endPosition, delay, duration)
	if startPosition == nil or endPosition == nil then return end

	local particle = ParticleManager:CreateParticle(RUPTURE_PARTICLE, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, startPosition)
	ParticleManager:SetParticleControl(particle, 1, endPosition)
	ParticleManager:SetParticleControl(particle, 3, Vector(0, delay or 0, 0))
	TrackPrecastParticle(ability, particle)

	Timers:CreateTimer((duration or 1.0) + (delay or 0), function()
		ReleaseTrackedPrecastParticle(ability, particle, false)
		return nil
	end)
end

local function GetImpactLineBounds(impacts)
	if impacts == nil or #impacts <= 0 then return nil, nil, 0 end

	local first = impacts[1]
	local last = impacts[#impacts]
	local maxDelay = 0
	for _, entry in pairs(impacts) do
		maxDelay = math.max(maxDelay, entry.delay or 0)
	end

	return first and first.position or nil, last and last.position or nil, maxDelay
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

	StartBossCastBar(self, "Brutal Slam")
	XHSBossTelegraphs:Target(position, radius, castPoint, FEL_COLORS)
	caster:EmitSound(BRUTAL_SLAM_PRECAST_SOUND)
	StartAnimation(caster, { duration = castPoint + 0.25, activity = ACT_DOTA_ATTACK, rate = 0.95 })
	return true
end

function xhs_magtheridon_brutal_slam:OnAbilityPhaseInterrupted()
	if IsServer() then HideBossCastBar(self) end
end

function xhs_magtheridon_brutal_slam:OnSpellStart()
	if not IsServer() then return end

	local context = GetContext(self)
	local caster = self:GetCaster()
	local position = context.position or caster:GetAbsOrigin()
	local radius = self:GetSpecialValueFor("radius")
	local damageTarget = IsValidAlive(context.target) and context.target or caster
	local damage = caster:GetAverageTrueAttackDamage(damageTarget) * self:GetSpecialValueFor("attack_damage_pct") * 0.01

	CreateRadialParticle(position, radius, BRUTAL_SLAM_PARTICLE)
	EmitLocationSound(caster, position, BRUTAL_SLAM_IMPACT_SOUND)
	DamageEnemies(caster, self, position, radius, damage, DAMAGE_TYPE_PHYSICAL)
	ClearContext(self)
end

function xhs_magtheridon_fel_stomp:OnAbilityPhaseStart()
	if not IsServer() then return true end

	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	local castPoint = GetCastPoint(self)

	StartBossCastBar(self, "Fel Stomp")
	CreateDarkmoonAOEPrecast(self, caster:GetAbsOrigin(), radius, castPoint)
	caster:EmitSound(FEL_STOMP_PRECAST_SOUND)
	StartAnimation(caster, { duration = castPoint + 0.2, activity = ACT_DOTA_CAST_ABILITY_2, rate = 0.85 })
	return true
end

function xhs_magtheridon_fel_stomp:OnAbilityPhaseInterrupted()
	if IsServer() then
		ClearPrecastParticles(self, true)
		HideBossCastBar(self)
	end
end

function xhs_magtheridon_fel_stomp:OnSpellStart()
	if not IsServer() then return end

	ClearPrecastParticles(self, false)

	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	local damage = self:GetSpecialValueFor("damage") * self:GetSpecialValueFor("damage_pct") * 0.01
	local slowDuration = self:GetSpecialValueFor("slow_duration")

	caster:EmitSound(FEL_STOMP_IMPACT_SOUND)
	CreateRadialParticle(caster:GetAbsOrigin(), radius, FEL_STOMP_PARTICLE)
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

	StartBossCastBar(self, "Targeted Firestorms")
	caster:EmitSound(FIRESTORM_PRECAST_SOUND)
	StartAnimation(caster, { duration = castPoint + 0.4, activity = ACT_DOTA_CAST_ABILITY_1, rate = 0.9 })

	for _, entry in pairs(context.impacts or {}) do
		CreateDarkmoonAOEPrecast(self, entry.position, radius, castPoint + (entry.delay or 0))
		XHSBossTelegraphs:Target(entry.position, radius, castPoint + (entry.delay or 0), FEL_COLORS)
	end

	return true
end

function xhs_magtheridon_targeted_firestorms:OnAbilityPhaseInterrupted()
	if IsServer() then
		ClearPrecastParticles(self, true)
		HideBossCastBar(self)
	end
end

function xhs_magtheridon_targeted_firestorms:OnSpellStart()
	if not IsServer() then return end

	ClearPrecastParticles(self, false)

	local context = GetContext(self)
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	local damage = self:GetSpecialValueFor("wave_damage") * self:GetSpecialValueFor("damage_pct") * 0.01

	for _, entry in pairs(context.impacts or {}) do
		local position = entry.position
		Timers:CreateTimer(entry.delay or 0, function()
			if not IsValidAlive(caster) then return nil end
			CreateFirestormWave(position, radius)
			EmitLocationSound(caster, position, FIRESTORM_IMPACT_SOUND)
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
	local startPosition, endPosition, maxDelay = GetImpactLineBounds(context.impacts)

	StartBossCastBar(self, "Fel Fissure")
	caster:EmitSound(FEL_FISSURE_PRECAST_SOUND)
	StartAnimation(caster, { duration = castPoint + 0.2, activity = ACT_DOTA_CAST_ABILITY_1, rate = 0.85 })
	CreateEarthSplitterLine(self, startPosition, endPosition, castPoint + maxDelay)
	for _, entry in pairs(context.impacts or {}) do
		XHSBossTelegraphs:Circle(entry.position, radius, castPoint + (entry.delay or 0), FEL_COLORS)
	end

	return true
end

function xhs_magtheridon_fel_fissure:OnAbilityPhaseInterrupted()
	if IsServer() then
		ClearPrecastParticles(self, true)
		HideBossCastBar(self)
	end
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
			EmitLocationSound(caster, position, FEL_FISSURE_IMPACT_SOUND)
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

	StartBossCastBar(self, "Infernal Rings")
	caster:EmitSound(INFERNAL_RINGS_PRECAST_SOUND)
	StartAnimation(caster, { duration = castPoint + 0.2, activity = ACT_DOTA_CAST_ABILITY_3, rate = 0.85 })
	for _, entry in pairs(context.impacts or {}) do
		CreatePitOfMalicePrecast(self, entry.position, radius)
		XHSBossTelegraphs:Circle(entry.position, radius, castPoint + (entry.delay or 0), FEL_COLORS)
	end

	return true
end

function xhs_magtheridon_infernal_rings:OnAbilityPhaseInterrupted()
	if IsServer() then
		ClearPrecastParticles(self, true)
		HideBossCastBar(self)
	end
end

function xhs_magtheridon_infernal_rings:OnSpellStart()
	if not IsServer() then return end

	ClearPrecastParticles(self, false)

	local context = GetContext(self)
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	local damage = self:GetSpecialValueFor("wave_damage") * self:GetSpecialValueFor("damage_pct") * 0.01
	local rootDuration = self:GetSpecialValueFor("root_duration")

	for _, entry in pairs(context.impacts or {}) do
		local position = entry.position
		Timers:CreateTimer(entry.delay or 0, function()
			if not IsValidAlive(caster) then return nil end
			CreatePitOfMaliceZone(position, radius, INFERNAL_RING_VISUAL_DURATION)
			EmitLocationSound(caster, position, INFERNAL_RINGS_IMPACT_SOUND)
			DamageEnemies(caster, self, position, radius, damage, DAMAGE_TYPE_PURE)
			local units = FindUnitsInRadius(caster:GetTeamNumber(), position, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
			for _, unit in pairs(units) do
				ApplyRoot(caster, self, unit, rootDuration)
			end
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

	StartBossCastBar(self, "Demonic Howl")
	CreateDarkmoonAOEPrecast(self, caster:GetAbsOrigin(), radius, castPoint)
	caster:EmitSound(DEMONIC_HOWL_PRECAST_SOUND)
	StartAnimation(caster, { duration = castPoint + 0.2, activity = ACT_DOTA_CAST_ABILITY_4, rate = 0.85 })
	return true
end

function xhs_magtheridon_demonic_howl:OnAbilityPhaseInterrupted()
	if IsServer() then
		ClearPrecastParticles(self, true)
		HideBossCastBar(self)
	end
end

function xhs_magtheridon_demonic_howl:OnSpellStart()
	if not IsServer() then return end

	ClearPrecastParticles(self, false)

	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	local duration = self:GetSpecialValueFor("duration")
	local howl = ParticleManager:CreateParticle(DEMONIC_HOWL_PARTICLE, PATTACH_OVERHEAD_FOLLOW, caster)
	ParticleManager:ReleaseParticleIndex(howl)
	caster:EmitSound(DEMONIC_HOWL_CAST_SOUND)

	local units = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
	for _, unit in pairs(units) do
		if IsValidAlive(unit) then
			ApplyDemonicHowl(caster, self, unit, duration)
		end
	end

	ClearContext(self)
end

function xhs_magtheridon_rupture:GetIntrinsicModifierName()
	return nil
end

function xhs_magtheridon_rupture:GetBehavior()
	return DOTA_ABILITY_BEHAVIOR_NO_TARGET
end

function xhs_magtheridon_rupture:SpawnRingPositions(center, ringRadius, count, offsetDegrees)
	local positions = {}
	for i = 1, count do
		positions[#positions + 1] = PositionOnRing(center, ringRadius, i, count, offsetDegrees)
	end

	return positions
end

function xhs_magtheridon_rupture:OnAbilityPhaseStart()
	if not IsServer() then return true end

	local context = GetContext(self)
	local caster = self:GetCaster()
	local castPoint = GetCastPoint(self)
	local spacing = self:GetSpecialValueFor("segment_spacing")
	local radius = self:GetSpecialValueFor("node_radius")
	local startDistance = self:GetSpecialValueFor("start_distance")
	local slowDuration = self:GetSpecialValueFor("slow_duration")
	local visualDelay = self:GetSpecialValueFor("visual_delay")

	StartBossCastBar(self, "Rupture")
	caster:EmitSound(RUPTURE_PRECAST_SOUND)
	StartAnimation(caster, { duration = castPoint + 0.3, activity = ACT_DOTA_CAST_ABILITY_4, rate = 0.82 })

	for _, line in pairs(context.lines or {}) do
		local startPosition = line.start or caster:GetAbsOrigin()
		local direction = line.direction or Vector(1, 0, 0)
		direction.z = 0
		if direction:Length2D() <= 0 then direction = Vector(1, 0, 0) end
		direction = direction:Normalized()
		local count = line.segment_count or 1
		local lineStart = startPosition + direction * startDistance
		local lineEnd = startPosition + direction * (startDistance + spacing * math.max(count - 1, 1))
		CreateFissureLine(self, lineStart, lineEnd, castPoint + visualDelay, slowDuration + 0.8)
		XHSBossTelegraphs:Line(startPosition, direction, spacing, radius, count, castPoint, FEL_COLORS, startDistance)
	end

	return true
end

function xhs_magtheridon_rupture:OnAbilityPhaseInterrupted()
	if IsServer() then
		ClearPrecastParticles(self, true)
		HideBossCastBar(self)
	end
end

function xhs_magtheridon_rupture:OnSpellStart()
	if not IsServer() then return end

	local context = GetContext(self)
	local caster = self:GetCaster()
	local spacing = self:GetSpecialValueFor("segment_spacing")
	local radius = self:GetSpecialValueFor("node_radius")
	local startDistance = self:GetSpecialValueFor("start_distance")
	local damage = self:GetSpecialValueFor("damage")
	local slowDuration = self:GetSpecialValueFor("slow_duration")
	local visualDelay = self:GetSpecialValueFor("visual_delay")

	caster:EmitSound(RUPTURE_PRECAST_SOUND)
	for _, line in pairs(context.lines or {}) do
		local startPosition = line.start or caster:GetAbsOrigin()
		local direction = line.direction or Vector(1, 0, 0)
		direction.z = 0
		if direction:Length2D() <= 0 then direction = Vector(1, 0, 0) end
		direction = direction:Normalized()
		local count = line.segment_count or 1
		local lineEnd = startPosition + direction * (startDistance + spacing * math.max(count - 1, 1))

		Timers:CreateTimer(visualDelay, function()
			if not IsValidAlive(caster) then return nil end
			EmitLocationSound(caster, lineEnd, RUPTURE_IMPACT_SOUND)
			local units = DamageLineEnemies(caster, self, startPosition, direction, spacing, radius, count, damage, DAMAGE_TYPE_PURE, startDistance)
			for _, unit in pairs(units) do
				ApplySlow(caster, unit, slowDuration, self:GetSpecialValueFor("movement_slow"), self:GetSpecialValueFor("attack_slow"))
			end
			return nil
		end)
	end

	ClearContext(self)
end

modifier_xhs_magtheridon_demonic_howl = modifier_xhs_magtheridon_demonic_howl or class({})

function modifier_xhs_magtheridon_demonic_howl:IsHidden() return false end
function modifier_xhs_magtheridon_demonic_howl:IsDebuff() return true end
function modifier_xhs_magtheridon_demonic_howl:IsPurgable() return true end
function modifier_xhs_magtheridon_demonic_howl:GetTexture() return "lycan_howl" end

function modifier_xhs_magtheridon_demonic_howl:OnCreated(params)
	params = params or {}
	self.movement_slow = params.movement_slow or -20
	self.attack_slow = params.attack_slow or -120
	self.damage_reduction_pct = -math.abs(params.damage_reduction_pct or 35)
end

function modifier_xhs_magtheridon_demonic_howl:OnRefresh(params)
	self:OnCreated(params)
end

function modifier_xhs_magtheridon_demonic_howl:DeclareFunctions() return {
	MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
	MODIFIER_PROPERTY_TOOLTIP,
} end

function modifier_xhs_magtheridon_demonic_howl:GetModifierMoveSpeedBonus_Percentage()
	return self.movement_slow
end

function modifier_xhs_magtheridon_demonic_howl:GetModifierAttackSpeedBonus_Constant()
	return self.attack_slow
end

function modifier_xhs_magtheridon_demonic_howl:GetModifierTotalDamageOutgoing_Percentage()
	return self.damage_reduction_pct
end

function modifier_xhs_magtheridon_demonic_howl:OnTooltip()
	return math.abs(self.damage_reduction_pct or 0)
end

modifier_xhs_magtheridon_infernal_root = modifier_xhs_magtheridon_infernal_root or class({})

function modifier_xhs_magtheridon_infernal_root:IsHidden() return false end
function modifier_xhs_magtheridon_infernal_root:IsDebuff() return true end
function modifier_xhs_magtheridon_infernal_root:IsPurgable() return true end
function modifier_xhs_magtheridon_infernal_root:GetTexture() return "abyssal_underlord_pit_of_malice" end

function modifier_xhs_magtheridon_infernal_root:CheckState()
	return {
		[MODIFIER_STATE_ROOTED] = true,
	}
end

function modifier_xhs_magtheridon_infernal_root:GetEffectName()
	return "particles/units/heroes/heroes_underlord/underlord_pitofmalice_stun.vpcf"
end

function modifier_xhs_magtheridon_infernal_root:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end
