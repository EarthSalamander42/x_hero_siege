require("boss_scripts/phase3_ai/core")
require("boss_scripts/phase3_ai/telegraphs")
require("boss_scripts/phase3_ai/cast_bar")

xhs_spirit_master_trinity_cycle = xhs_spirit_master_trinity_cycle or class({})
xhs_spirit_master_palm_of_balance = xhs_spirit_master_palm_of_balance or class({})
xhs_spirit_master_elemental_mandala = xhs_spirit_master_elemental_mandala or class({})
xhs_spirit_master_convergence = xhs_spirit_master_convergence or class({})

xhs_spirit_storm_arc_dash = xhs_spirit_storm_arc_dash or class({})
xhs_spirit_storm_static_orbs = xhs_spirit_storm_static_orbs or class({})
xhs_spirit_storm_chain_focus = xhs_spirit_storm_chain_focus or class({})
xhs_spirit_earth_fault_line = xhs_spirit_earth_fault_line or class({})
xhs_spirit_earth_stone_guard = xhs_spirit_earth_stone_guard or class({})
xhs_spirit_earth_resonant_pillar = xhs_spirit_earth_resonant_pillar or class({})
xhs_spirit_fire_cinder_step = xhs_spirit_fire_cinder_step or class({})
xhs_spirit_fire_solar_flare = xhs_spirit_fire_solar_flare or class({})
xhs_spirit_fire_wildfire_ring = xhs_spirit_fire_wildfire_ring or class({})

modifier_xhs_spirit_master_slow = modifier_xhs_spirit_master_slow or class({})
modifier_xhs_spirit_master_slow.XHS_LINK_CLIENT = true
modifier_xhs_spirit_discordant_echo = modifier_xhs_spirit_discordant_echo or class({})
modifier_xhs_spirit_discordant_echo.XHS_LINK_CLIENT = true
modifier_xhs_spirit_mandala_burn = modifier_xhs_spirit_mandala_burn or class({})
modifier_xhs_spirit_mandala_burn.XHS_LINK_CLIENT = true
modifier_xhs_spirit_mandala_storm = modifier_xhs_spirit_mandala_storm or class({})
modifier_xhs_spirit_mandala_storm.XHS_LINK_CLIENT = true
modifier_xhs_spirit_storm_silence = modifier_xhs_spirit_storm_silence or class({})
modifier_xhs_spirit_storm_silence.XHS_LINK_CLIENT = true
modifier_xhs_spirit_fire_burn = modifier_xhs_spirit_fire_burn or class({})
modifier_xhs_spirit_fire_burn.XHS_LINK_CLIENT = true
modifier_xhs_spirit_earth_guard = modifier_xhs_spirit_earth_guard or class({})
modifier_xhs_spirit_earth_guard.XHS_LINK_CLIENT = true

LinkLuaModifier("modifier_xhs_spirit_master_slow", "boss_scripts/phase3_ai/spirit_master_abilities.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_spirit_discordant_echo", "boss_scripts/phase3_ai/spirit_master_abilities.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_spirit_mandala_burn", "boss_scripts/phase3_ai/spirit_master_abilities.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_spirit_mandala_storm", "boss_scripts/phase3_ai/spirit_master_abilities.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_spirit_storm_silence", "boss_scripts/phase3_ai/spirit_master_abilities.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_spirit_fire_burn", "boss_scripts/phase3_ai/spirit_master_abilities.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_spirit_earth_guard", "boss_scripts/phase3_ai/spirit_master_abilities.lua", LUA_MODIFIER_MOTION_NONE)

local SPIRIT_TEXTURES = {
	trinity_cycle = "custom/xhs_spirit_master_trinity_cycle",
	palm_of_balance = "custom/xhs_spirit_master_palm_of_balance",
	elemental_mandala = "custom/xhs_spirit_master_elemental_mandala",
	convergence = "custom/xhs_spirit_master_convergence",
	storm_arc_dash = "custom/xhs_spirit_storm_arc_dash",
	storm_static_orbs = "custom/xhs_spirit_storm_static_orbs",
	storm_chain_focus = "custom/xhs_spirit_storm_chain_focus",
	earth_fault_line = "custom/xhs_spirit_earth_fault_line",
	earth_stone_guard = "custom/xhs_spirit_earth_stone_guard",
	earth_resonant_pillar = "custom/xhs_spirit_earth_resonant_pillar",
	fire_cinder_step = "custom/xhs_spirit_fire_cinder_step",
	fire_solar_flare = "custom/xhs_spirit_fire_solar_flare",
	fire_wildfire_ring = "custom/xhs_spirit_fire_wildfire_ring",
}

local COLORS = {
	master = { primary = Vector(255, 255, 255), secondary = Vector(70, 210, 255), style = 4, family = "spirit_master" },
	storm = { primary = Vector(70, 220, 255), secondary = Vector(210, 245, 255), style = 4, family = "spirit_storm" },
	earth = { primary = Vector(110, 220, 110), secondary = Vector(210, 255, 160), style = 5, family = "spirit_earth" },
	fire = { primary = Vector(255, 45, 20), secondary = Vector(255, 145, 35), style = 0, family = "spirit_fire" },
	trinity = { primary = Vector(255, 255, 255), secondary = Vector(255, 185, 70), style = 2, family = "spirit_master" },
}

-- Elemental Mandala reads from the inside out. Keep its three precasts tied to
-- the first-circle (radius) particle of the matching elemental family.
local MANDALA_COLORS = {
	fire = COLORS.fire,
	earth = COLORS.earth,
	storm = COLORS.storm,
}

local UNIT_STYLES = {
	npc_dota_boss_spirit_master = "spirit_master",
	npc_dota_boss_spirit_master_storm = "spirit_storm",
	npc_dota_boss_spirit_master_earth = "spirit_earth",
	npc_dota_boss_spirit_master_fire = "spirit_fire",
}

local PALM_PARTICLE = "particles/units/heroes/hero_brewmaster/brewmaster_thunder_clap.vpcf"
local TRINITY_SPLIT_PARTICLE = "particles/units/heroes/hero_brewmaster/brewmaster_primal_split.vpcf"
local STORM_OVERLOAD_PARTICLE = "particles/units/heroes/hero_stormspirit/stormspirit_overload_discharge.vpcf"
local STORM_REMNANT_PARTICLE = "particles/units/heroes/hero_stormspirit/stormspirit_static_remnant.vpcf"
local EARTH_FAULT_PARTICLE = "particles/units/heroes/hero_elder_titan/elder_titan_earth_splitter.vpcf"
local EARTH_GUARD_PARTICLE = "particles/units/heroes/hero_earth_spirit/espirit_bouldersmash_caster.vpcf"
local EARTH_PILLAR_PARTICLE = "particles/units/heroes/hero_earth_spirit/espirit_stoneremnant.vpcf"
local FIRE_CINDER_PARTICLE = "particles/units/heroes/hero_ember_spirit/ember_spirit_flameguard.vpcf"
local FIRE_CINDER_DESTINATION_PARTICLE = "particles/units/heroes/hero_ember_spirit/ember_spirit_fire_remnant.vpcf"
local FIRE_SOLAR_PARTICLE = "particles/units/heroes/hero_lina/lina_spell_light_strike_array.vpcf"
local FIRE_WILDFIRE_PARTICLE = "particles/units/heroes/hero_phoenix/phoenix_fire_spirit_ground.vpcf"
local SHORT_IMPACT_DURATION = 1.15
local EARTH_SPLITTER_RELEASE_BUFFER = 1.35

function xhs_spirit_master_trinity_cycle:GetAbilityTextureName() return SPIRIT_TEXTURES.trinity_cycle end
function xhs_spirit_master_palm_of_balance:GetAbilityTextureName() return SPIRIT_TEXTURES.palm_of_balance end
function xhs_spirit_master_elemental_mandala:GetAbilityTextureName() return SPIRIT_TEXTURES.elemental_mandala end
function xhs_spirit_master_convergence:GetAbilityTextureName() return SPIRIT_TEXTURES.convergence end
function xhs_spirit_storm_arc_dash:GetAbilityTextureName() return SPIRIT_TEXTURES.storm_arc_dash end
function xhs_spirit_storm_static_orbs:GetAbilityTextureName() return SPIRIT_TEXTURES.storm_static_orbs end
function xhs_spirit_storm_chain_focus:GetAbilityTextureName() return SPIRIT_TEXTURES.storm_chain_focus end
function xhs_spirit_earth_fault_line:GetAbilityTextureName() return SPIRIT_TEXTURES.earth_fault_line end
function xhs_spirit_earth_stone_guard:GetAbilityTextureName() return SPIRIT_TEXTURES.earth_stone_guard end
function xhs_spirit_earth_resonant_pillar:GetAbilityTextureName() return SPIRIT_TEXTURES.earth_resonant_pillar end
function xhs_spirit_fire_cinder_step:GetAbilityTextureName() return SPIRIT_TEXTURES.fire_cinder_step end
function xhs_spirit_fire_solar_flare:GetAbilityTextureName() return SPIRIT_TEXTURES.fire_solar_flare end
function xhs_spirit_fire_wildfire_ring:GetAbilityTextureName() return SPIRIT_TEXTURES.fire_wildfire_ring end

local function IsValidAlive(unit)
	return unit ~= nil and IsValidEntity(unit) and not unit:IsNull() and unit:IsAlive()
end

local function GetContext(ability)
	return ability.xhs_spirit_context or {}
end

local function ClearContext(ability)
	ability.xhs_spirit_context = nil
end

local function GetColor(key)
	return COLORS[key] or COLORS.master
end

local function GetSpiritKey(caster)
	local name = caster and caster:GetUnitName() or ""
	if name == "npc_dota_boss_spirit_master_storm" then return "storm" end
	if name == "npc_dota_boss_spirit_master_earth" then return "earth" end
	if name == "npc_dota_boss_spirit_master_fire" then return "fire" end
	return "master"
end

local function StartBossCastBar(ability, displayName)
	if XHSBossCastBar == nil then return end
	local caster = ability:GetCaster()
	XHSBossCastBar:Start(caster, ability, {
		display_name = displayName,
		style = UNIT_STYLES[caster:GetUnitName()] or "spirit_master",
	})
end

local function HideBossCastBar(ability)
	if XHSBossCastBar ~= nil then
		XHSBossCastBar:Hide(ability:GetCaster())
	end
end

local function NormalizeDirection(direction)
	if direction == nil then return Vector(1, 0, 0) end
	direction.z = 0
	if direction:Length2D() <= 0 then return Vector(1, 0, 0) end
	return direction:Normalized()
end

local function GetSpiritRound(ability)
	local caster = ability and ability:GetCaster()
	if caster ~= nil and caster.xhs_spirit_round ~= nil then
		return math.max(1, math.min(3, caster.xhs_spirit_round))
	end
	if XHSSpiritMasterEncounter ~= nil and XHSSpiritMasterEncounter.GetSplitRound ~= nil then
		return XHSSpiritMasterEncounter:GetSplitRound()
	end
	return 1
end

local function GetRoundSpecialValue(ability, name)
	return ability:GetSpecialValueFor("round_" .. tostring(GetSpiritRound(ability)) .. "_" .. name)
end

local function RotateDirection(direction, degrees)
	return NormalizeDirection(RotatePosition(Vector(0, 0, 0), QAngle(0, degrees or 0, 0), direction))
end

local function GetRoundLineDirections(ability, direction)
	local count = math.max(1, GetRoundSpecialValue(ability, "line_count"))
	local angle = GetRoundSpecialValue(ability, "line_angle")
	local directions = {}
	for index = 1, count do
		local offset = (index - ((count + 1) * 0.5)) * angle
		table.insert(directions, RotateDirection(direction, offset))
	end
	return directions
end

local function GetSolarPositions(ability, center)
	local count = math.max(1, GetRoundSpecialValue(ability, "impact_count"))
	local spacing = GetRoundSpecialValue(ability, "impact_spacing")
	local caster = ability:GetCaster()
	local forward = NormalizeDirection(center - caster:GetAbsOrigin())
	local side = Vector(-forward.y, forward.x, 0)
	local positions = {}
	for index = 1, count do
		local offset = (index - ((count + 1) * 0.5)) * spacing
		table.insert(positions, center + side * offset)
	end
	return positions
end

local function GetResonantPillarPositions(ability, center)
	local count = math.max(1, GetRoundSpecialValue(ability, "pillar_count"))
	local positions = { center }
	local satelliteCount = count - 1
	if satelliteCount <= 0 then return positions end

	for index = 1, satelliteCount do
		table.insert(positions, RotatePosition(
			center,
			QAngle(0, ((index - 1) / satelliteCount) * 360 + 90, 0),
			center + Vector(ability:GetSpecialValueFor("ring_radius"), 0, 0)
		))
	end
	return positions
end

local function MoveSpiritWithinArena(spirit, position)
	if XHSSpiritMasterEncounter ~= nil and XHSSpiritMasterEncounter.MoveSpiritToArenaPosition ~= nil then
		return XHSSpiritMasterEncounter:MoveSpiritToArenaPosition(spirit, position)
	end
	FindClearSpaceForUnit(spirit, position, true)
	return true
end

local function GetCinderStepDestination(ability, caster, direction)
	local destination = caster:GetAbsOrigin() + direction * ability:GetSpecialValueFor("dash_distance")
	if XHSSpiritMasterEncounter ~= nil and XHSSpiritMasterEncounter.ClampArenaPosition ~= nil then
		return XHSSpiritMasterEncounter:ClampArenaPosition(destination)
	end
	return GetGroundPosition(destination, caster)
end

local function DestroyCinderStepDestination(ability, immediate)
	local particle = ability.xhs_cinder_destination_particle
	if particle == nil then return end
	ParticleManager:DestroyParticle(particle, immediate == true)
	ParticleManager:ReleaseParticleIndex(particle)
	ability.xhs_cinder_destination_particle = nil
	ability.xhs_cinder_destination = nil
end

local function CreateCinderStepDestination(ability, caster, destination, direction)
	DestroyCinderStepDestination(ability, true)
	local particle = ParticleManager:CreateParticle(FIRE_CINDER_DESTINATION_PARTICLE, PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(particle, 0, destination)
	ParticleManager:SetParticleControlForward(particle, 0, direction)
	ability.xhs_cinder_destination_particle = particle
	ability.xhs_cinder_destination = destination
	Timers:CreateTimer(math.max(0.5, ability:GetCastPoint() + 1), function()
		if ability.xhs_cinder_destination_particle == particle then
			DestroyCinderStepDestination(ability, true)
		end
		return nil
	end)
end

local function GetPalmLine(ability)
	local caster = ability:GetCaster()
	local rawDirection = GetContext(ability).direction or caster:GetForwardVector()
	rawDirection.z = 0
	local baseSpacing = math.max(1, ability:GetSpecialValueFor("spacing"))
	local baseNodes = math.max(1, ability:GetSpecialValueFor("nodes"))
	local targetDistance = math.min(
		math.max(140, rawDirection:Length2D()),
		math.max(140, ability:GetCastRange(caster:GetAbsOrigin(), nil))
	)
	local nodes = math.max(baseNodes, math.ceil(math.max(0, targetDistance - 140) / baseSpacing) + 1)
	return NormalizeDirection(rawDirection), baseSpacing, nodes
end

local function ScaleDamage(value)
	if XHSPhase3BossAI ~= nil and XHSPhase3BossAI.ScaleDamage ~= nil then
		return XHSPhase3BossAI:ScaleDamage(value)
	end
	return value or 0
end

local function CollectTargets(caster, position, radius, targetTypes)
	local targets = {}
	local seen = {}
	if not IsValidAlive(caster) or position == nil then return targets end
	local function AddUnits(units)
		for _, unit in pairs(units or {}) do
			if unit ~= nil and IsValidEntity(unit) and not unit:IsNull() and seen[unit:entindex()] ~= true then
				seen[unit:entindex()] = true
				table.insert(targets, unit)
			end
		end
	end
	AddUnits(FindUnitsInRadius(caster:GetTeamNumber(), position, nil, radius or 200, DOTA_UNIT_TARGET_TEAM_ENEMY, targetTypes, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false))
	AddUnits(FindUnitsInRadius(DOTA_TEAM_GOODGUYS, position, nil, radius or 200, DOTA_UNIT_TARGET_TEAM_FRIENDLY, targetTypes, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false))
	return targets
end

local function DamageEnemies(caster, ability, position, radius, damage, damageType, onHit)
	if not IsValidAlive(caster) or position == nil then return end
	for _, enemy in pairs(CollectTargets(caster, position, radius, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC)) do
		if IsValidAlive(enemy) and not enemy:IsInvulnerable() then
			local dealt = ApplyDamage({
				victim = enemy,
				attacker = caster,
				ability = ability,
				damage = damage or 0,
				damage_type = damageType or ability:GetAbilityDamageType(),
			})
			if dealt > 0 then SendOverheadEventMessage(nil, OVERHEAD_ALERT_DAMAGE, enemy, dealt, nil) end
			if onHit ~= nil then onHit(enemy) end
		end
	end
end

local function DamageEnemiesOnce(caster, ability, position, radius, damage, damageType, hitEnemies, onHit)
	hitEnemies = hitEnemies or {}
	for _, enemy in pairs(CollectTargets(caster, position, radius, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC)) do
		local index = enemy:entindex()
		if hitEnemies[index] ~= true and IsValidAlive(enemy) and not enemy:IsInvulnerable() then
			hitEnemies[index] = true
			local dealt = ApplyDamage({
				victim = enemy,
				attacker = caster,
				ability = ability,
				damage = damage or 0,
				damage_type = damageType or ability:GetAbilityDamageType(),
			})
			if dealt > 0 then SendOverheadEventMessage(nil, OVERHEAD_ALERT_DAMAGE, enemy, dealt, nil) end
			if onHit ~= nil then onHit(enemy) end
		end
	end
	return hitEnemies
end

local function ApplyStormSilence(enemy, caster, ability, duration)
	if not IsValidAlive(enemy) or enemy:IsMagicImmune() then return end
	local existing = enemy:FindModifierByName("modifier_xhs_spirit_storm_silence")
	if existing ~= nil then
		existing:SetDuration(duration or 1.0, true)
		existing:ForceRefresh()
		return
	end
	enemy:AddNewModifier(caster, ability, "modifier_xhs_spirit_storm_silence", {
		duration = duration or 1.0,
	})
end

local function SlowEnemies(caster, ability, position, radius, duration)
	for _, enemy in pairs(CollectTargets(caster, position, radius, DOTA_UNIT_TARGET_HERO)) do
		if IsValidAlive(enemy) then
			enemy:AddNewModifier(caster, ability, "modifier_xhs_spirit_master_slow", { duration = duration or 1.2 })
		end
	end
end

local function DestroyParticleAfter(particle, delay)
	if particle == nil then return end
	Timers:CreateTimer(math.max(delay or 0.03, 0.03), function()
		ParticleManager:DestroyParticle(particle, false)
		ParticleManager:ReleaseParticleIndex(particle)
		return nil
	end)
end

local function CreateImpact(position, particle, radius, duration)
	local p = ParticleManager:CreateParticle(particle, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(p, 0, position)
	ParticleManager:SetParticleControl(p, 1, Vector(radius or 220, 0, 0))
	if duration ~= nil then
		ParticleManager:SetParticleControl(p, 2, Vector(duration, 0, 0))
		DestroyParticleAfter(p, duration)
	else
		DestroyParticleAfter(p, SHORT_IMPACT_DURATION)
	end
end

local function CreateStaticRemnantImpact(caster, position, duration)
	local particle = ParticleManager:CreateParticle(STORM_REMNANT_PARTICLE, PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControlForward(particle, 0, caster:GetForwardVector())
	ParticleManager:SetParticleControlEnt(
		particle,
		1,
		caster,
		PATTACH_POINT_FOLLOW,
		"attach_hitloc",
		position,
		true
	)
	ParticleManager:SetParticleControl(particle, 2, Vector(ACT_DOTA_CAST_ABILITY_1, 1, 100))
	ParticleManager:SetParticleControl(particle, 11, position)
	DestroyParticleAfter(particle, duration or SHORT_IMPACT_DURATION)
end

local function CreateEarthSplitterPrecast(caster, startPosition, direction, length, delay)
	direction = NormalizeDirection(direction)
	local p = ParticleManager:CreateParticle(EARTH_FAULT_PARTICLE, PATTACH_WORLDORIGIN, caster)
	ParticleManager:SetParticleControl(p, 0, startPosition)
	ParticleManager:SetParticleControl(p, 1, startPosition + direction * length)
	ParticleManager:SetParticleControl(p, 3, Vector(0, delay or 0, 0))
	return {
		particle = p,
		active = true,
	}
end

local function DestroyEarthSplitterPrecasts(ability, immediate)
	for _, entry in pairs(ability.xhs_earth_splitter_precasts or {}) do
		if entry.active == true then
			entry.active = false
			ParticleManager:DestroyParticle(entry.particle, immediate == true)
			ParticleManager:ReleaseParticleIndex(entry.particle)
		end
	end
	ability.xhs_earth_splitter_precasts = nil
end

function xhs_spirit_master_trinity_cycle:OnAbilityPhaseStart()
	if not IsServer() then return true end
	local caster = self:GetCaster()
	StartBossCastBar(self, "Trinity Cycle")
	XHSBossTelegraphs:Circle(caster:GetAbsOrigin(), self:GetSpecialValueFor("radius"), self:GetCastPoint(), COLORS.trinity)
	StartAnimation(caster, { duration = self:GetCastPoint() + 0.3, activity = ACT_DOTA_CAST_ABILITY_4, rate = 0.75 })
	caster:EmitSound("Hero_Brewmaster.PrimalSplit.Cast")
	return true
end

function xhs_spirit_master_trinity_cycle:OnAbilityPhaseInterrupted()
	if not IsServer() then return end
	HideBossCastBar(self)
	if XHSSpiritMasterEncounter ~= nil and XHSSpiritMasterEncounter.CancelPendingSplit ~= nil then
		XHSSpiritMasterEncounter:CancelPendingSplit(self:GetCaster(), GetContext(self).threshold)
	end
	ClearContext(self)
end

function xhs_spirit_master_trinity_cycle:OnSpellStart()
	if not IsServer() then return end
	if XHSSpiritMasterEncounter ~= nil then
		XHSBossTelegraphs:Release(self:GetCaster():GetAbsOrigin(), self:GetSpecialValueFor("radius"), COLORS.trinity)
		CreateImpact(self:GetCaster():GetAbsOrigin(), TRINITY_SPLIT_PARTICLE, self:GetSpecialValueFor("radius"))
		self:GetCaster():EmitSound("Hero_Brewmaster.PrimalSplit.Cast")
		XHSSpiritMasterEncounter:BeginSplit(self:GetCaster(), GetContext(self).threshold)
	end
	ClearContext(self)
end

function xhs_spirit_master_palm_of_balance:OnAbilityPhaseStart()
	if not IsServer() then return true end
	local caster = self:GetCaster()
	local direction, spacing, nodes = GetPalmLine(self)
	StartBossCastBar(self, "Palm of Balance")
	XHSBossTelegraphs:Line(caster:GetAbsOrigin(), direction, spacing, self:GetSpecialValueFor("radius"), nodes, self:GetCastPoint(), COLORS.master, 140)
	StartAnimation(caster, { duration = self:GetCastPoint() + 0.15, activity = ACT_DOTA_CAST_ABILITY_1, rate = 0.9 })
	caster:EmitSound("Hero_Brewmaster.ThunderClap")
	return true
end

function xhs_spirit_master_palm_of_balance:OnAbilityPhaseInterrupted()
	if IsServer() then HideBossCastBar(self) end
end

function xhs_spirit_master_palm_of_balance:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local direction, spacing, nodes = GetPalmLine(self)
	local origin = caster:GetAbsOrigin()
	local radius = self:GetSpecialValueFor("radius")
	for i = 1, nodes do
		local pos = origin + direction * (140 + spacing * (i - 1))
		DamageEnemies(caster, self, pos, radius, ScaleDamage(self:GetSpecialValueFor("damage")), self:GetAbilityDamageType())
		SlowEnemies(caster, self, pos, radius, self:GetSpecialValueFor("slow_duration"))
		CreateImpact(pos, PALM_PARTICLE, radius)
		EmitSoundOnLocationWithCaster(pos, "Hero_Brewmaster.ThunderClap", caster)
	end
	ClearContext(self)
end

function xhs_spirit_master_elemental_mandala:OnAbilityPhaseStart()
	if not IsServer() then return true end
	local caster = self:GetCaster()
	local center = GetContext(self).position or caster:GetAbsOrigin()
	local ringRadius = self:GetSpecialValueFor("ring_radius")
	StartBossCastBar(self, "Elemental Mandala")
	XHSBossTelegraphs:Ring(center, ringRadius * 0.36, self:GetSpecialValueFor("node_radius"), 6, self:GetCastPoint(), MANDALA_COLORS.fire, 40)
	StartAnimation(caster, { duration = self:GetCastPoint() + 0.4, activity = ACT_DOTA_CAST_ABILITY_4, rate = 0.75 })
	caster:EmitSound("Hero_Brewmaster.PrimalSplit.Cast")
	return true
end

function xhs_spirit_master_elemental_mandala:OnAbilityPhaseInterrupted()
	if IsServer() then HideBossCastBar(self) end
end

function xhs_spirit_master_elemental_mandala:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local center = GetContext(self).position or caster:GetAbsOrigin()
	local ringRadius = self:GetSpecialValueFor("ring_radius")
	local nodeRadius = self:GetSpecialValueFor("node_radius")
	local damage = ScaleDamage(self:GetSpecialValueFor("damage"))
	local waveDelay = math.max(0.25, self:GetSpecialValueFor("wave_delay"))
	local waves = {
		{ key = "fire", radius = ringRadius * 0.36, count = 6, offset = 40, delay = 0, colors = MANDALA_COLORS.fire, particle = FIRE_WILDFIRE_PARTICLE, sound = "Ability.LightStrikeArray" },
		{ key = "earth", radius = ringRadius * 0.68, count = 9, offset = 20, delay = waveDelay, colors = MANDALA_COLORS.earth, particle = EARTH_PILLAR_PARTICLE, sound = "Hero_ElderTitan.EarthSplitter.Destroy" },
		{ key = "storm", radius = ringRadius, count = 12, offset = 0, delay = waveDelay * 2, colors = MANDALA_COLORS.storm, particle = STORM_OVERLOAD_PARTICLE, sound = "Hero_StormSpirit.StaticRemnantExplode" },
	}

	for waveIndex, wave in ipairs(waves) do
		local waveData = wave
		if waveIndex > 1 then
			Timers:CreateTimer(waveData.delay - waveDelay, function()
				if not IsValidAlive(caster) then return nil end
				XHSBossTelegraphs:Ring(center, waveData.radius, nodeRadius, waveData.count, waveDelay, waveData.colors, waveData.offset)
				return nil
			end)
		end

		Timers:CreateTimer(waveData.delay, function()
			if not IsValidAlive(caster) then return nil end
			EmitSoundOnLocationWithCaster(center, waveData.sound, caster)
			for i = 1, waveData.count do
				local pos = RotatePosition(center, QAngle(0, ((i - 1) / waveData.count) * 360 + waveData.offset, 0), center + Vector(waveData.radius, 0, 0))
				if waveData.key == "fire" then
					DamageEnemies(caster, self, pos, nodeRadius, damage * 0.45, self:GetAbilityDamageType(), function(enemy)
						enemy:AddNewModifier(caster, self, "modifier_xhs_spirit_mandala_burn", { duration = self:GetSpecialValueFor("fire_burn_duration") })
					end)
				elseif waveData.key == "earth" then
					DamageEnemies(caster, self, pos, nodeRadius, damage * self:GetSpecialValueFor("earth_damage_pct") * 0.01, self:GetAbilityDamageType())
					SlowEnemies(caster, self, pos, nodeRadius, self:GetSpecialValueFor("earth_slow_duration"))
				else
					DamageEnemies(caster, self, pos, nodeRadius, damage * self:GetSpecialValueFor("storm_damage_pct") * 0.01, self:GetAbilityDamageType(), function(enemy)
						enemy:AddNewModifier(caster, self, "modifier_xhs_spirit_mandala_storm", { duration = self:GetSpecialValueFor("storm_debuff_duration") })
					end)
				end
				CreateImpact(pos, waveData.particle, nodeRadius, waveData.key == "fire" and nil or SHORT_IMPACT_DURATION)
			end
			return nil
		end)
	end
	ClearContext(self)
end

function xhs_spirit_master_convergence:OnAbilityPhaseStart()
	if not IsServer() then return true end
	local caster = self:GetCaster()
	StartBossCastBar(self, "Convergence")
	XHSBossTelegraphs:Circle(caster:GetAbsOrigin(), self:GetSpecialValueFor("radius"), self:GetCastPoint(), COLORS.trinity)
	StartAnimation(caster, { duration = self:GetCastPoint() + 0.2, activity = ACT_DOTA_CAST_ABILITY_3, rate = 0.85 })
	caster:EmitSound("Hero_Brewmaster.CinderBrew.Cast")
	return true
end

function xhs_spirit_master_convergence:OnAbilityPhaseInterrupted()
	if IsServer() then HideBossCastBar(self) end
end

function xhs_spirit_master_convergence:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	XHSBossTelegraphs:Release(caster:GetAbsOrigin(), self:GetSpecialValueFor("radius"), COLORS.trinity)
	DamageEnemies(caster, self, caster:GetAbsOrigin(), self:GetSpecialValueFor("radius"), 0, self:GetAbilityDamageType())
	CreateImpact(caster:GetAbsOrigin(), TRINITY_SPLIT_PARTICLE, self:GetSpecialValueFor("radius"))
	caster:EmitSound("Hero_Brewmaster.CinderBrew.Cast")
	ClearContext(self)
end

function xhs_spirit_storm_arc_dash:OnAbilityPhaseStart()
	if not IsServer() then return true end
	local caster = self:GetCaster()
	local context = GetContext(self)
	local target = context.position or caster:GetAbsOrigin() + caster:GetForwardVector() * 500
	local direction = NormalizeDirection(target - caster:GetAbsOrigin())
	StartBossCastBar(self, "Arc Dash")
	for _, lineDirection in ipairs(GetRoundLineDirections(self, direction)) do
		XHSBossTelegraphs:Line(caster:GetAbsOrigin(), lineDirection, self:GetSpecialValueFor("spacing"), self:GetSpecialValueFor("radius"), self:GetSpecialValueFor("nodes"), self:GetCastPoint(), COLORS.storm, 120)
	end
	StartAnimation(caster, { duration = self:GetCastPoint() + 0.1, activity = ACT_DOTA_CAST_ABILITY_1, rate = 1.0 })
	caster:EmitSound("Hero_StormSpirit.StaticRemnantPlant")
	return true
end

function xhs_spirit_storm_arc_dash:OnAbilityPhaseInterrupted() if IsServer() then HideBossCastBar(self) end end
function xhs_spirit_storm_arc_dash:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local direction = NormalizeDirection((GetContext(self).position or caster:GetAbsOrigin()) - caster:GetAbsOrigin())
	for _, lineDirection in ipairs(GetRoundLineDirections(self, direction)) do
		for i = 1, self:GetSpecialValueFor("nodes") do
			local pos = caster:GetAbsOrigin() + lineDirection * (120 + self:GetSpecialValueFor("spacing") * (i - 1))
			DamageEnemies(caster, self, pos, self:GetSpecialValueFor("radius"), ScaleDamage(self:GetSpecialValueFor("damage")), self:GetAbilityDamageType(), function(enemy)
				ApplyStormSilence(enemy, caster, self, self:GetSpecialValueFor("silence_duration"))
			end)
			CreateImpact(pos, STORM_OVERLOAD_PARTICLE, self:GetSpecialValueFor("radius"), SHORT_IMPACT_DURATION)
			EmitSoundOnLocationWithCaster(pos, "Hero_StormSpirit.Overload", caster)
		end
	end
	MoveSpiritWithinArena(caster, caster:GetAbsOrigin() + direction * self:GetSpecialValueFor("dash_distance"))
	ClearContext(self)
end

function xhs_spirit_storm_static_orbs:OnAbilityPhaseStart()
	if not IsServer() then return true end
	StartBossCastBar(self, "Static Orbs")
	local caster = self:GetCaster()
	local center = GetContext(self).position or caster:GetAbsOrigin()
	caster:EmitSound("Hero_StormSpirit.StaticRemnantPlant")
	XHSBossTelegraphs:Target(center, self:GetSpecialValueFor("radius"), self:GetCastPoint(), COLORS.storm)
	XHSBossTelegraphs:Ring(center, self:GetSpecialValueFor("ring_radius"), self:GetSpecialValueFor("radius"), self:GetSpecialValueFor("orb_count"), self:GetCastPoint(), COLORS.storm, 15)
	if GetRoundSpecialValue(self, "ring_count") >= 2 then
		XHSBossTelegraphs:Ring(center, self:GetSpecialValueFor("ring_radius") * self:GetSpecialValueFor("inner_radius_pct") * 0.01, self:GetSpecialValueFor("radius"), self:GetSpecialValueFor("inner_orb_count"), self:GetCastPoint(), COLORS.storm, 0)
	end
	StartAnimation(caster, { duration = self:GetCastPoint() + 0.1, activity = ACT_DOTA_CAST_ABILITY_2, rate = 1.0 })
	return true
end

function xhs_spirit_storm_static_orbs:OnAbilityPhaseInterrupted() if IsServer() then HideBossCastBar(self) end end
function xhs_spirit_storm_static_orbs:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local center = GetContext(self).position or caster:GetAbsOrigin()
	local rings = {
		{ radius = self:GetSpecialValueFor("ring_radius"), count = self:GetSpecialValueFor("orb_count"), offset = 15 },
	}
	if GetRoundSpecialValue(self, "ring_count") >= 2 then
		table.insert(rings, {
			radius = self:GetSpecialValueFor("ring_radius") * self:GetSpecialValueFor("inner_radius_pct") * 0.01,
			count = self:GetSpecialValueFor("inner_orb_count"),
			offset = 0,
		})
	end
	local function DetonateOrb(position)
		DamageEnemies(caster, self, position, self:GetSpecialValueFor("radius"), ScaleDamage(self:GetSpecialValueFor("damage")), self:GetAbilityDamageType(), function(enemy)
			enemy:AddNewModifier(caster, self, "modifier_stunned", { duration = self:GetSpecialValueFor("stun_duration") })
		end)
		CreateStaticRemnantImpact(caster, position, SHORT_IMPACT_DURATION)
		EmitSoundOnLocationWithCaster(position, "Hero_StormSpirit.StaticRemnantExplode", caster)
	end

	DetonateOrb(center)
	for _, ring in ipairs(rings) do
		for i = 1, ring.count do
			local pos = RotatePosition(center, QAngle(0, ((i - 1) / ring.count) * 360 + ring.offset, 0), center + Vector(ring.radius, 0, 0))
			DetonateOrb(pos)
		end
	end
	ClearContext(self)
end

function xhs_spirit_storm_chain_focus:OnAbilityPhaseStart()
	if not IsServer() then return true end
	local position = GetContext(self).position or self:GetCaster():GetAbsOrigin()
	StartBossCastBar(self, "Chain Focus")
	local lineCount = math.max(1, self:GetSpecialValueFor("line_count"))
	local nodes = math.max(1, self:GetSpecialValueFor("line_nodes"))
	local spacing = self:GetSpecialValueFor("line_spacing")
	local lineWidth = self:GetSpecialValueFor("radius")
	for index = 1, lineCount do
		local direction = RotateDirection(Vector(1, 0, 0), ((index - 1) / lineCount) * 360)
		XHSBossTelegraphs:Line(position, direction, spacing, lineWidth, nodes, self:GetCastPoint(), COLORS.storm, 0)
	end
	self:GetCaster():EmitSound("Hero_StormSpirit.ElectricVortexCast")
	return true
end

function xhs_spirit_storm_chain_focus:OnAbilityPhaseInterrupted() if IsServer() then HideBossCastBar(self) end end
function xhs_spirit_storm_chain_focus:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local position = GetContext(self).position or caster:GetAbsOrigin()
	local lineCount = math.max(1, self:GetSpecialValueFor("line_count"))
	local nodes = math.max(1, self:GetSpecialValueFor("line_nodes"))
	local spacing = self:GetSpecialValueFor("line_spacing")
	local radius = self:GetSpecialValueFor("radius")
	local damage = ScaleDamage(self:GetSpecialValueFor("damage"))
	local hitEnemies = {}
	for index = 1, lineCount do
		local direction = RotateDirection(Vector(1, 0, 0), ((index - 1) / lineCount) * 360)
		for node = 1, nodes do
			local nodePosition = position + direction * (spacing * (node - 1))
			DamageEnemiesOnce(caster, self, nodePosition, radius, damage, self:GetAbilityDamageType(), hitEnemies, function(enemy)
				ApplyStormSilence(enemy, caster, self, self:GetSpecialValueFor("silence_duration"))
				enemy:AddNewModifier(caster, self, "modifier_xhs_spirit_master_slow", {
					duration = self:GetSpecialValueFor("slow_duration"),
				})
			end)
			if node > 1 or index == 1 then
				CreateImpact(nodePosition, STORM_OVERLOAD_PARTICLE, radius, SHORT_IMPACT_DURATION)
			end
		end
	end
	EmitSoundOnLocationWithCaster(position, "Hero_StormSpirit.ElectricVortex", caster)
	ClearContext(self)
end

function xhs_spirit_earth_fault_line:OnAbilityPhaseStart()
	if not IsServer() then return true end
	local caster = self:GetCaster()
	local direction = NormalizeDirection((GetContext(self).position or caster:GetAbsOrigin()) - caster:GetAbsOrigin())
	local length = self:GetSpecialValueFor("spacing") * math.max(self:GetSpecialValueFor("nodes") - 1, 1)
	StartBossCastBar(self, "Fault Line")
	DestroyEarthSplitterPrecasts(self, true)
	self.xhs_earth_splitter_precasts = {}
	for _, lineDirection in ipairs(GetRoundLineDirections(self, direction)) do
		XHSBossTelegraphs:Line(caster:GetAbsOrigin(), lineDirection, self:GetSpecialValueFor("spacing"), self:GetSpecialValueFor("radius"), self:GetSpecialValueFor("nodes"), self:GetCastPoint(), COLORS.earth, 120)
		local entry = CreateEarthSplitterPrecast(caster, caster:GetAbsOrigin() + lineDirection * 120, lineDirection, length, self:GetCastPoint())
		table.insert(self.xhs_earth_splitter_precasts, entry)
		Timers:CreateTimer(self:GetCastPoint() + EARTH_SPLITTER_RELEASE_BUFFER, function()
			if entry.active == true then
				entry.active = false
				ParticleManager:DestroyParticle(entry.particle, false)
				ParticleManager:ReleaseParticleIndex(entry.particle)
			end
			return nil
		end)
	end
	caster:EmitSound("Hero_ElderTitan.EarthSplitter.Cast")
	return true
end

function xhs_spirit_earth_fault_line:OnAbilityPhaseInterrupted()
	if not IsServer() then return end
	DestroyEarthSplitterPrecasts(self, true)
	HideBossCastBar(self)
end
function xhs_spirit_earth_fault_line:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local direction = NormalizeDirection((GetContext(self).position or caster:GetAbsOrigin()) - caster:GetAbsOrigin())
	for _, lineDirection in ipairs(GetRoundLineDirections(self, direction)) do
		for i = 1, self:GetSpecialValueFor("nodes") do
			local pos = caster:GetAbsOrigin() + lineDirection * (120 + self:GetSpecialValueFor("spacing") * (i - 1))
			DamageEnemies(caster, self, pos, self:GetSpecialValueFor("radius"), ScaleDamage(self:GetSpecialValueFor("damage")), self:GetAbilityDamageType(), function(enemy)
				enemy:AddNewModifier(caster, self, "modifier_stunned", { duration = self:GetSpecialValueFor("stun_duration") })
			end)
			SlowEnemies(caster, self, pos, self:GetSpecialValueFor("radius"), self:GetSpecialValueFor("slow_duration"))
		end
	end
	caster:EmitSound("Hero_ElderTitan.EarthSplitter.Destroy")
	ClearContext(self)
end

function xhs_spirit_earth_stone_guard:OnAbilityPhaseStart()
	if not IsServer() then return true end
	StartBossCastBar(self, "Stone Guard")
	XHSBossTelegraphs:Circle(self:GetCaster():GetAbsOrigin(), self:GetSpecialValueFor("radius"), self:GetCastPoint(), COLORS.earth)
	if GetRoundSpecialValue(self, "pulse_count") >= 2 then
		XHSBossTelegraphs:Circle(self:GetCaster():GetAbsOrigin(), self:GetSpecialValueFor("radius") * self:GetSpecialValueFor("outer_radius_pct") * 0.01, self:GetCastPoint() + self:GetSpecialValueFor("pulse_delay"), COLORS.earth)
	end
	self:GetCaster():EmitSound("Hero_EarthSpirit.StoneRemnant.Impact")
	return true
end

function xhs_spirit_earth_stone_guard:OnAbilityPhaseInterrupted() if IsServer() then HideBossCastBar(self) end end
function xhs_spirit_earth_stone_guard:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	XHSBossTelegraphs:Release(caster:GetAbsOrigin(), self:GetSpecialValueFor("radius"), COLORS.earth)
	DamageEnemies(caster, self, caster:GetAbsOrigin(), self:GetSpecialValueFor("radius"), ScaleDamage(self:GetSpecialValueFor("damage")), self:GetAbilityDamageType())
	SlowEnemies(caster, self, caster:GetAbsOrigin(), self:GetSpecialValueFor("radius"), self:GetSpecialValueFor("slow_duration"))
	caster:AddNewModifier(caster, self, "modifier_xhs_spirit_earth_guard", { duration = self:GetSpecialValueFor("guard_duration") })
	CreateImpact(caster:GetAbsOrigin(), EARTH_GUARD_PARTICLE, self:GetSpecialValueFor("radius"), SHORT_IMPACT_DURATION)
	caster:EmitSound("Hero_EarthSpirit.StoneRemnant.Impact")
	if GetRoundSpecialValue(self, "pulse_count") >= 2 then
		local ability = self
		local delay = self:GetSpecialValueFor("pulse_delay")
		Timers:CreateTimer(delay, function()
			if not IsValidAlive(caster) or ability == nil or ability:IsNull() then return nil end
			local radius = ability:GetSpecialValueFor("radius") * ability:GetSpecialValueFor("outer_radius_pct") * 0.01
			local damage = ScaleDamage(ability:GetSpecialValueFor("damage")) * ability:GetSpecialValueFor("second_pulse_damage_pct") * 0.01
			DamageEnemies(caster, ability, caster:GetAbsOrigin(), radius, damage, ability:GetAbilityDamageType())
			SlowEnemies(caster, ability, caster:GetAbsOrigin(), radius, ability:GetSpecialValueFor("slow_duration"))
			CreateImpact(caster:GetAbsOrigin(), EARTH_GUARD_PARTICLE, radius, SHORT_IMPACT_DURATION)
			caster:EmitSound("Hero_EarthSpirit.StoneRemnant.Impact")
			return nil
		end)
	end
	ClearContext(self)
end

function xhs_spirit_earth_resonant_pillar:OnAbilityPhaseStart()
	if not IsServer() then return true end
	local center = GetContext(self).position or self:GetCaster():GetAbsOrigin()
	local count = math.max(1, GetRoundSpecialValue(self, "pillar_count"))
	StartBossCastBar(self, "Resonant Pillar")
	XHSBossTelegraphs:Target(center, self:GetSpecialValueFor("radius"), self:GetCastPoint(), COLORS.earth)
	if count > 1 then
		XHSBossTelegraphs:Ring(center, self:GetSpecialValueFor("ring_radius"), self:GetSpecialValueFor("radius"), count - 1, self:GetCastPoint(), COLORS.earth, 90)
	end
	self:GetCaster():EmitSound("Hero_EarthSpirit.BoulderSmash.Cast")
	return true
end

function xhs_spirit_earth_resonant_pillar:OnAbilityPhaseInterrupted() if IsServer() then HideBossCastBar(self) end end
function xhs_spirit_earth_resonant_pillar:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local center = GetContext(self).position or caster:GetAbsOrigin()
	for _, pos in ipairs(GetResonantPillarPositions(self, center)) do
		DamageEnemies(caster, self, pos, self:GetSpecialValueFor("radius"), ScaleDamage(self:GetSpecialValueFor("damage")), self:GetAbilityDamageType(), function(enemy)
			enemy:AddNewModifier(caster, self, "modifier_stunned", { duration = self:GetSpecialValueFor("stun_duration") })
		end)
		CreateImpact(pos, EARTH_PILLAR_PARTICLE, self:GetSpecialValueFor("radius"), SHORT_IMPACT_DURATION)
		EmitSoundOnLocationWithCaster(pos, "Hero_EarthSpirit.BoulderSmash.Target", caster)
	end
	ClearContext(self)
end

function xhs_spirit_fire_cinder_step:OnAbilityPhaseStart()
	if not IsServer() then return true end
	local caster = self:GetCaster()
	local direction = NormalizeDirection((GetContext(self).position or caster:GetAbsOrigin()) - caster:GetAbsOrigin())
	local destination = GetCinderStepDestination(self, caster, direction)
	StartBossCastBar(self, "Cinder Step")
	for _, lineDirection in ipairs(GetRoundLineDirections(self, direction)) do
		XHSBossTelegraphs:Line(caster:GetAbsOrigin(), lineDirection, self:GetSpecialValueFor("spacing"), self:GetSpecialValueFor("radius"), self:GetSpecialValueFor("nodes"), self:GetCastPoint(), COLORS.fire, 100)
	end
	CreateCinderStepDestination(self, caster, destination, direction)
	caster:EmitSound("Hero_EmberSpirit.FireRemnant.Activate")
	return true
end

function xhs_spirit_fire_cinder_step:OnAbilityPhaseInterrupted()
	if not IsServer() then return end
	DestroyCinderStepDestination(self, true)
	HideBossCastBar(self)
end
function xhs_spirit_fire_cinder_step:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local direction = NormalizeDirection((GetContext(self).position or caster:GetAbsOrigin()) - caster:GetAbsOrigin())
	local destination = self.xhs_cinder_destination or GetCinderStepDestination(self, caster, direction)
	for _, lineDirection in ipairs(GetRoundLineDirections(self, direction)) do
		for i = 1, self:GetSpecialValueFor("nodes") do
			local pos = caster:GetAbsOrigin() + lineDirection * (100 + self:GetSpecialValueFor("spacing") * (i - 1))
			DamageEnemies(caster, self, pos, self:GetSpecialValueFor("radius"), ScaleDamage(self:GetSpecialValueFor("damage")), self:GetAbilityDamageType(), function(enemy)
				enemy:AddNewModifier(caster, self, "modifier_xhs_spirit_fire_burn", { duration = self:GetSpecialValueFor("burn_duration") })
			end)
			CreateImpact(pos, FIRE_CINDER_PARTICLE, self:GetSpecialValueFor("radius"))
			EmitSoundOnLocationWithCaster(pos, "Hero_EmberSpirit.FireRemnant.Explode", caster)
		end
	end
	MoveSpiritWithinArena(caster, destination)
	DestroyCinderStepDestination(self, false)
	ClearContext(self)
end

function xhs_spirit_fire_solar_flare:OnAbilityPhaseStart()
	if not IsServer() then return true end
	local position = GetContext(self).position or self:GetCaster():GetAbsOrigin()
	StartBossCastBar(self, "Solar Flare")
	for _, impactPosition in ipairs(GetSolarPositions(self, position)) do
		XHSBossTelegraphs:Target(impactPosition, self:GetSpecialValueFor("radius"), self:GetCastPoint(), COLORS.fire)
	end
	self:GetCaster():EmitSound("Hero_EmberSpirit.FlameGuard.Cast")
	return true
end

function xhs_spirit_fire_solar_flare:OnAbilityPhaseInterrupted() if IsServer() then HideBossCastBar(self) end end
function xhs_spirit_fire_solar_flare:OnSpellStart()
	if not IsServer() then return end
	local position = GetContext(self).position or self:GetCaster():GetAbsOrigin()
	for _, impactPosition in ipairs(GetSolarPositions(self, position)) do
		DamageEnemies(self:GetCaster(), self, impactPosition, self:GetSpecialValueFor("radius"), ScaleDamage(self:GetSpecialValueFor("damage")), self:GetAbilityDamageType(), function(enemy)
			enemy:AddNewModifier(self:GetCaster(), self, "modifier_stunned", { duration = self:GetSpecialValueFor("stun_duration") })
			enemy:AddNewModifier(self:GetCaster(), self, "modifier_xhs_spirit_fire_burn", { duration = self:GetSpecialValueFor("burn_duration") })
		end)
		CreateImpact(impactPosition, FIRE_SOLAR_PARTICLE, self:GetSpecialValueFor("radius"))
		EmitSoundOnLocationWithCaster(impactPosition, "Ability.LightStrikeArray", self:GetCaster())
	end
	ClearContext(self)
end

function xhs_spirit_fire_wildfire_ring:OnAbilityPhaseStart()
	if not IsServer() then return true end
	local center = GetContext(self).position or self:GetCaster():GetAbsOrigin()
	StartBossCastBar(self, "Wildfire Ring")
	XHSBossTelegraphs:Ring(center, self:GetSpecialValueFor("outer_radius"), self:GetSpecialValueFor("node_radius"), 12, self:GetCastPoint(), COLORS.fire, 0)
	XHSBossTelegraphs:Ring(center, self:GetSpecialValueFor("inner_radius"), self:GetSpecialValueFor("node_radius"), 8, self:GetCastPoint(), COLORS.fire, 22)
	if GetRoundSpecialValue(self, "ring_count") >= 3 then
		XHSBossTelegraphs:Ring(center, (self:GetSpecialValueFor("outer_radius") + self:GetSpecialValueFor("inner_radius")) * 0.5, self:GetSpecialValueFor("node_radius"), self:GetSpecialValueFor("middle_node_count"), self:GetCastPoint(), COLORS.fire, 11)
	end
	self:GetCaster():EmitSound("Hero_Phoenix.FireSpirits.Cast")
	return true
end

function xhs_spirit_fire_wildfire_ring:OnAbilityPhaseInterrupted() if IsServer() then HideBossCastBar(self) end end
function xhs_spirit_fire_wildfire_ring:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local center = GetContext(self).position or caster:GetAbsOrigin()
	local damage = ScaleDamage(self:GetSpecialValueFor("damage"))
	local nodeRadius = self:GetSpecialValueFor("node_radius")
	local rings = { { self:GetSpecialValueFor("outer_radius"), 12 }, { self:GetSpecialValueFor("inner_radius"), 8 } }
	if GetRoundSpecialValue(self, "ring_count") >= 3 then
		table.insert(rings, { (self:GetSpecialValueFor("outer_radius") + self:GetSpecialValueFor("inner_radius")) * 0.5, self:GetSpecialValueFor("middle_node_count") })
	end
	for _, ring in ipairs(rings) do
		for i = 1, ring[2] do
			local pos = RotatePosition(center, QAngle(0, ((i - 1) / ring[2]) * 360, 0), center + Vector(ring[1], 0, 0))
			DamageEnemies(caster, self, pos, nodeRadius, damage, self:GetAbilityDamageType(), function(enemy)
				enemy:AddNewModifier(caster, self, "modifier_xhs_spirit_fire_burn", { duration = self:GetSpecialValueFor("burn_duration") })
			end)
			CreateImpact(pos, FIRE_WILDFIRE_PARTICLE, nodeRadius)
			EmitSoundOnLocationWithCaster(pos, "Hero_Phoenix.FireSpirits.ProjectileHit", caster)
		end
	end
	ClearContext(self)
end

function modifier_xhs_spirit_master_slow:IsPurgable() return true end
function modifier_xhs_spirit_master_slow:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end
function modifier_xhs_spirit_master_slow:GetModifierMoveSpeedBonus_Percentage() return -35 end
function modifier_xhs_spirit_master_slow:GetModifierAttackSpeedBonus_Constant() return -45 end

function modifier_xhs_spirit_mandala_burn:IsDebuff() return true end
function modifier_xhs_spirit_mandala_burn:IsPurgable() return true end
function modifier_xhs_spirit_mandala_burn:GetTexture() return "ember_spirit_flame_guard" end
function modifier_xhs_spirit_mandala_burn:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(1.0)
end
function modifier_xhs_spirit_mandala_burn:OnIntervalThink()
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local parent = self:GetParent()
	if not IsValidAlive(caster) or not IsValidAlive(parent) or ability == nil then return end
	ApplyDamage({ victim = parent, attacker = caster, ability = ability, damage = ScaleDamage(ability:GetSpecialValueFor("fire_burn_damage")), damage_type = self:GetAbility():GetAbilityDamageType() })
end

function modifier_xhs_spirit_mandala_storm:IsDebuff() return true end
function modifier_xhs_spirit_mandala_storm:IsPurgable() return true end
function modifier_xhs_spirit_mandala_storm:GetTexture() return "storm_spirit_overload" end
function modifier_xhs_spirit_mandala_storm:DeclareFunctions()
	return { MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE }
end
function modifier_xhs_spirit_mandala_storm:GetModifierIncomingDamage_Percentage()
	return self:GetAbility() and self:GetAbility():GetSpecialValueFor("storm_vulnerability") or 25
end

function modifier_xhs_spirit_storm_silence:IsDebuff() return true end
function modifier_xhs_spirit_storm_silence:IsPurgable() return true end
function modifier_xhs_spirit_storm_silence:GetTexture() return "storm_spirit_electric_vortex" end
function modifier_xhs_spirit_storm_silence:CheckState()
	if self:GetParent():IsMagicImmune() then return {} end
	return {
		[MODIFIER_STATE_SILENCED] = true,
	}
end

function modifier_xhs_spirit_fire_burn:IsDebuff() return true end
function modifier_xhs_spirit_fire_burn:IsPurgable() return true end
function modifier_xhs_spirit_fire_burn:GetTexture() return "ember_spirit_flame_guard" end
function modifier_xhs_spirit_fire_burn:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(1.0)
end
function modifier_xhs_spirit_fire_burn:OnIntervalThink()
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local parent = self:GetParent()
	if not IsValidAlive(caster) or not IsValidAlive(parent) or ability == nil then return end
	ApplyDamage({
		victim = parent,
		attacker = caster,
		ability = ability,
		damage = ScaleDamage(ability:GetSpecialValueFor("burn_damage")),
		damage_type = self:GetAbility():GetAbilityDamageType(),
	})
end

function modifier_xhs_spirit_earth_guard:IsPurgable() return false end
function modifier_xhs_spirit_earth_guard:GetTexture() return "earth_spirit_stone_caller" end
function modifier_xhs_spirit_earth_guard:DeclareFunctions()
	return { MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE }
end
function modifier_xhs_spirit_earth_guard:GetModifierIncomingDamage_Percentage()
	return -(self:GetAbility() and self:GetAbility():GetSpecialValueFor("damage_reduction") or 25)
end

function modifier_xhs_spirit_discordant_echo:IsPurgable() return false end
function modifier_xhs_spirit_discordant_echo:GetTexture() return "brewmaster_primal_split" end
function modifier_xhs_spirit_discordant_echo:DeclareFunctions()
	return { MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end
function modifier_xhs_spirit_discordant_echo:GetModifierBaseDamageOutgoing_Percentage()
	return 8 * self:GetStackCount()
end
function modifier_xhs_spirit_discordant_echo:GetModifierAttackSpeedBonus_Constant()
	return 15 * self:GetStackCount()
end
