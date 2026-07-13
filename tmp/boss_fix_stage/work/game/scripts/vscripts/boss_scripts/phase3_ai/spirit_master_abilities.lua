require("boss_scripts/phase3_ai/core")
require("boss_scripts/phase3_ai/telegraphs")
require("boss_scripts/phase3_ai/cast_bar")

xhs_spirit_master_trinity_cycle = xhs_spirit_master_trinity_cycle or class({})
xhs_spirit_master_palm_of_balance = xhs_spirit_master_palm_of_balance or class({})
xhs_spirit_master_elemental_mandala = xhs_spirit_master_elemental_mandala or class({})
xhs_spirit_master_spirit_call = xhs_spirit_master_spirit_call or class({})
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

LinkLuaModifier("modifier_xhs_spirit_master_slow", "boss_scripts/phase3_ai/spirit_master_abilities.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_spirit_discordant_echo", "boss_scripts/phase3_ai/spirit_master_abilities.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_spirit_mandala_burn", "boss_scripts/phase3_ai/spirit_master_abilities.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_spirit_mandala_storm", "boss_scripts/phase3_ai/spirit_master_abilities.lua", LUA_MODIFIER_MOTION_NONE)

local SPIRIT_TEXTURES = {
	trinity_cycle = "custom/xhs_spirit_master_trinity_cycle",
	palm_of_balance = "custom/xhs_spirit_master_palm_of_balance",
	elemental_mandala = "custom/xhs_spirit_master_elemental_mandala",
	spirit_call = "custom/xhs_spirit_master_spirit_call",
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
	master = { primary = Vector(255, 255, 255), secondary = Vector(70, 210, 255), style = 4 },
	storm = { primary = Vector(70, 220, 255), secondary = Vector(210, 245, 255), style = 4 },
	earth = { primary = Vector(110, 220, 110), secondary = Vector(210, 255, 160), style = 5 },
	fire = { primary = Vector(255, 115, 35), secondary = Vector(255, 220, 90), style = 0 },
	trinity = { primary = Vector(255, 255, 255), secondary = Vector(255, 185, 70), style = 2 },
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
local FIRE_SOLAR_PARTICLE = "particles/units/heroes/hero_lina/lina_spell_light_strike_array.vpcf"
local FIRE_WILDFIRE_PARTICLE = "particles/units/heroes/hero_phoenix/phoenix_fire_spirit_ground.vpcf"
local SHORT_IMPACT_DURATION = 1.15
local EARTH_SPLITTER_RELEASE_DELAY = 0.16
local EARTH_SPLITTER_CLEANUP_DELAY = 1.45

function xhs_spirit_master_trinity_cycle:GetAbilityTextureName() return SPIRIT_TEXTURES.trinity_cycle end
function xhs_spirit_master_palm_of_balance:GetAbilityTextureName() return SPIRIT_TEXTURES.palm_of_balance end
function xhs_spirit_master_elemental_mandala:GetAbilityTextureName() return SPIRIT_TEXTURES.elemental_mandala end
function xhs_spirit_master_spirit_call:GetAbilityTextureName() return SPIRIT_TEXTURES.spirit_call end
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

local function ScaleDamage(value)
	if XHSPhase3BossAI ~= nil and XHSPhase3BossAI.ScaleDamage ~= nil then
		return XHSPhase3BossAI:ScaleDamage(value)
	end
	return value or 0
end

local function DamageEnemies(caster, ability, position, radius, damage, damageType, onHit)
	if not IsValidAlive(caster) or position == nil then return end
	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		position,
		nil,
		radius or 200,
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
				damage = damage or 0,
				damage_type = damageType or DAMAGE_TYPE_MAGICAL,
			})
			if onHit ~= nil then onHit(enemy) end
		end
	end
end

local function SlowEnemies(caster, ability, position, radius, duration)
	local enemies = FindUnitsInRadius(caster:GetTeamNumber(), position, nil, radius or 200, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
	for _, enemy in pairs(enemies) do
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

local function CreateEarthSplitterImpact(startPosition, direction, length, delay, cleanupDelay)
	direction = NormalizeDirection(direction)
	local p = ParticleManager:CreateParticle(EARTH_FAULT_PARTICLE, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(p, 0, startPosition)
	ParticleManager:SetParticleControl(p, 1, startPosition + direction * length)
	ParticleManager:SetParticleControl(p, 3, Vector(0, delay or EARTH_SPLITTER_RELEASE_DELAY, 0))
	DestroyParticleAfter(p, cleanupDelay or EARTH_SPLITTER_CLEANUP_DELAY)
end

function xhs_spirit_master_trinity_cycle:GetIntrinsicModifierName()
	return nil
end

function xhs_spirit_master_palm_of_balance:OnAbilityPhaseStart()
	if not IsServer() then return true end
	local caster = self:GetCaster()
	local direction = NormalizeDirection(GetContext(self).direction or caster:GetForwardVector())
	StartBossCastBar(self, "Palm of Balance")
	XHSBossTelegraphs:Line(caster:GetAbsOrigin(), direction, self:GetSpecialValueFor("spacing"), self:GetSpecialValueFor("radius"), self:GetSpecialValueFor("nodes"), self:GetCastPoint(), COLORS.master, 140)
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
	local context = GetContext(self)
	local direction = NormalizeDirection(context.direction or caster:GetForwardVector())
	local origin = caster:GetAbsOrigin()
	local spacing = self:GetSpecialValueFor("spacing")
	local radius = self:GetSpecialValueFor("radius")
	for i = 1, self:GetSpecialValueFor("nodes") do
		local pos = origin + direction * (140 + spacing * (i - 1))
		DamageEnemies(caster, self, pos, radius, ScaleDamage(self:GetSpecialValueFor("damage")), DAMAGE_TYPE_MAGICAL)
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
	XHSBossTelegraphs:Ring(center, ringRadius * 0.36, self:GetSpecialValueFor("node_radius"), 6, self:GetCastPoint(), COLORS.fire, 40)
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
		{ key = "fire", radius = ringRadius * 0.36, count = 6, offset = 40, delay = 0, colors = COLORS.fire, particle = FIRE_WILDFIRE_PARTICLE, sound = "Ability.LightStrikeArray" },
		{ key = "earth", radius = ringRadius * 0.68, count = 9, offset = 20, delay = waveDelay, colors = COLORS.earth, particle = EARTH_PILLAR_PARTICLE, sound = "Hero_ElderTitan.EarthSplitter.Destroy" },
		{ key = "storm", radius = ringRadius, count = 12, offset = 0, delay = waveDelay * 2, colors = COLORS.storm, particle = STORM_OVERLOAD_PARTICLE, sound = "Hero_StormSpirit.StaticRemnantExplode" },
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
					DamageEnemies(caster, self, pos, nodeRadius, damage * 0.45, DAMAGE_TYPE_MAGICAL, function(enemy)
						enemy:AddNewModifier(caster, self, "modifier_xhs_spirit_mandala_burn", { duration = self:GetSpecialValueFor("fire_burn_duration") })
					end)
				elseif waveData.key == "earth" then
					DamageEnemies(caster, self, pos, nodeRadius, damage * self:GetSpecialValueFor("earth_damage_pct") * 0.01, DAMAGE_TYPE_MAGICAL)
					SlowEnemies(caster, self, pos, nodeRadius, self:GetSpecialValueFor("earth_slow_duration"))
				else
					DamageEnemies(caster, self, pos, nodeRadius, damage * self:GetSpecialValueFor("storm_damage_pct") * 0.01, DAMAGE_TYPE_PURE, function(enemy)
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

function xhs_spirit_master_spirit_call:OnAbilityPhaseStart()
	if not IsServer() then return true end
	local caster = self:GetCaster()
	StartBossCastBar(self, "Spirit Call")
	XHSBossTelegraphs:Circle(caster:GetAbsOrigin(), self:GetSpecialValueFor("radius"), self:GetCastPoint(), COLORS.trinity)
	StartAnimation(caster, { duration = self:GetCastPoint() + 0.3, activity = ACT_DOTA_CAST_ABILITY_4, rate = 0.75 })
	caster:EmitSound("Hero_Brewmaster.PrimalSplit.Cast")
	return true
end

function xhs_spirit_master_spirit_call:OnAbilityPhaseInterrupted()
	if IsServer() then HideBossCastBar(self) end
end

function xhs_spirit_master_spirit_call:OnSpellStart()
	if not IsServer() then return end
	if XHSSpiritMasterEncounter ~= nil then
		CreateImpact(self:GetCaster():GetAbsOrigin(), TRINITY_SPLIT_PARTICLE, self:GetSpecialValueFor("radius"))
		self:GetCaster():EmitSound("Hero_Brewmaster.PrimalSplit.Cast")
		XHSSpiritMasterEncounter:BeginSplit(self:GetCaster(), GetContext(self).threshold)
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
	DamageEnemies(caster, self, caster:GetAbsOrigin(), self:GetSpecialValueFor("radius"), 0, DAMAGE_TYPE_MAGICAL)
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
	XHSBossTelegraphs:Line(caster:GetAbsOrigin(), direction, self:GetSpecialValueFor("spacing"), self:GetSpecialValueFor("radius"), self:GetSpecialValueFor("nodes"), self:GetCastPoint(), COLORS.storm, 120)
	StartAnimation(caster, { duration = self:GetCastPoint() + 0.1, activity = ACT_DOTA_CAST_ABILITY_1, rate = 1.0 })
	caster:EmitSound("Hero_StormSpirit.StaticRemnantPlant")
	return true
end

function xhs_spirit_storm_arc_dash:OnAbilityPhaseInterrupted() if IsServer() then HideBossCastBar(self) end end
function xhs_spirit_storm_arc_dash:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local direction = NormalizeDirection((GetContext(self).position or caster:GetAbsOrigin()) - caster:GetAbsOrigin())
	for i = 1, self:GetSpecialValueFor("nodes") do
		local pos = caster:GetAbsOrigin() + direction * (120 + self:GetSpecialValueFor("spacing") * (i - 1))
		DamageEnemies(caster, self, pos, self:GetSpecialValueFor("radius"), ScaleDamage(self:GetSpecialValueFor("damage")), DAMAGE_TYPE_MAGICAL)
		CreateImpact(pos, STORM_OVERLOAD_PARTICLE, self:GetSpecialValueFor("radius"), SHORT_IMPACT_DURATION)
	end
	FindClearSpaceForUnit(caster, caster:GetAbsOrigin() + direction * self:GetSpecialValueFor("dash_distance"), true)
	ClearContext(self)
end

function xhs_spirit_storm_static_orbs:OnAbilityPhaseStart()
	if not IsServer() then return true end
	StartBossCastBar(self, "Static Orbs")
	local caster = self:GetCaster()
	local center = GetContext(self).position or caster:GetAbsOrigin()
	XHSBossTelegraphs:Ring(center, self:GetSpecialValueFor("ring_radius"), self:GetSpecialValueFor("radius"), self:GetSpecialValueFor("orb_count"), self:GetCastPoint(), COLORS.storm, 15)
	StartAnimation(caster, { duration = self:GetCastPoint() + 0.1, activity = ACT_DOTA_CAST_ABILITY_2, rate = 1.0 })
	return true
end

function xhs_spirit_storm_static_orbs:OnAbilityPhaseInterrupted() if IsServer() then HideBossCastBar(self) end end
function xhs_spirit_storm_static_orbs:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local center = GetContext(self).position or caster:GetAbsOrigin()
	for i = 1, self:GetSpecialValueFor("orb_count") do
		local pos = RotatePosition(center, QAngle(0, ((i - 1) / self:GetSpecialValueFor("orb_count")) * 360 + 15, 0), center + Vector(self:GetSpecialValueFor("ring_radius"), 0, 0))
		DamageEnemies(caster, self, pos, self:GetSpecialValueFor("radius"), ScaleDamage(self:GetSpecialValueFor("damage")), DAMAGE_TYPE_MAGICAL)
		CreateImpact(pos, STORM_REMNANT_PARTICLE, self:GetSpecialValueFor("radius"), SHORT_IMPACT_DURATION)
		EmitSoundOnLocationWithCaster(pos, "Hero_StormSpirit.StaticRemnantExplode", caster)
	end
	ClearContext(self)
end

function xhs_spirit_storm_chain_focus:OnAbilityPhaseStart()
	if not IsServer() then return true end
	local position = GetContext(self).position or self:GetCaster():GetAbsOrigin()
	StartBossCastBar(self, "Chain Focus")
	XHSBossTelegraphs:Target(position, self:GetSpecialValueFor("radius"), self:GetCastPoint(), COLORS.storm)
	self:GetCaster():EmitSound("Hero_StormSpirit.ElectricVortexCast")
	return true
end

function xhs_spirit_storm_chain_focus:OnAbilityPhaseInterrupted() if IsServer() then HideBossCastBar(self) end end
function xhs_spirit_storm_chain_focus:OnSpellStart()
	if not IsServer() then return end
	local position = GetContext(self).position or self:GetCaster():GetAbsOrigin()
	DamageEnemies(self:GetCaster(), self, position, self:GetSpecialValueFor("radius"), ScaleDamage(self:GetSpecialValueFor("damage")), DAMAGE_TYPE_MAGICAL)
	SlowEnemies(self:GetCaster(), self, position, self:GetSpecialValueFor("radius"), self:GetSpecialValueFor("slow_duration"))
	CreateImpact(position, STORM_OVERLOAD_PARTICLE, self:GetSpecialValueFor("radius"), SHORT_IMPACT_DURATION)
	EmitSoundOnLocationWithCaster(position, "Hero_StormSpirit.ElectricVortex", self:GetCaster())
	ClearContext(self)
end

function xhs_spirit_earth_fault_line:OnAbilityPhaseStart()
	if not IsServer() then return true end
	local caster = self:GetCaster()
	local direction = NormalizeDirection((GetContext(self).position or caster:GetAbsOrigin()) - caster:GetAbsOrigin())
	StartBossCastBar(self, "Fault Line")
	XHSBossTelegraphs:Line(caster:GetAbsOrigin(), direction, self:GetSpecialValueFor("spacing"), self:GetSpecialValueFor("radius"), self:GetSpecialValueFor("nodes"), self:GetCastPoint(), COLORS.earth, 120)
	caster:EmitSound("Hero_ElderTitan.EarthSplitter.Cast")
	return true
end

function xhs_spirit_earth_fault_line:OnAbilityPhaseInterrupted() if IsServer() then HideBossCastBar(self) end end
function xhs_spirit_earth_fault_line:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local direction = NormalizeDirection((GetContext(self).position or caster:GetAbsOrigin()) - caster:GetAbsOrigin())
	local length = self:GetSpecialValueFor("spacing") * math.max(self:GetSpecialValueFor("nodes") - 1, 1)
	CreateEarthSplitterImpact(caster:GetAbsOrigin() + direction * 120, direction, length)
	for i = 1, self:GetSpecialValueFor("nodes") do
		local pos = caster:GetAbsOrigin() + direction * (120 + self:GetSpecialValueFor("spacing") * (i - 1))
		DamageEnemies(caster, self, pos, self:GetSpecialValueFor("radius"), ScaleDamage(self:GetSpecialValueFor("damage")), DAMAGE_TYPE_MAGICAL)
		SlowEnemies(caster, self, pos, self:GetSpecialValueFor("radius"), self:GetSpecialValueFor("slow_duration"))
	end
	caster:EmitSound("Hero_ElderTitan.EarthSplitter.Destroy")
	ClearContext(self)
end

function xhs_spirit_earth_stone_guard:OnAbilityPhaseStart()
	if not IsServer() then return true end
	StartBossCastBar(self, "Stone Guard")
	XHSBossTelegraphs:Circle(self:GetCaster():GetAbsOrigin(), self:GetSpecialValueFor("radius"), self:GetCastPoint(), COLORS.earth)
	self:GetCaster():EmitSound("Hero_EarthSpirit.StoneRemnant.Impact")
	return true
end

function xhs_spirit_earth_stone_guard:OnAbilityPhaseInterrupted() if IsServer() then HideBossCastBar(self) end end
function xhs_spirit_earth_stone_guard:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	DamageEnemies(caster, self, caster:GetAbsOrigin(), self:GetSpecialValueFor("radius"), ScaleDamage(self:GetSpecialValueFor("damage")), DAMAGE_TYPE_MAGICAL)
	SlowEnemies(caster, self, caster:GetAbsOrigin(), self:GetSpecialValueFor("radius"), self:GetSpecialValueFor("slow_duration"))
	CreateImpact(caster:GetAbsOrigin(), EARTH_GUARD_PARTICLE, self:GetSpecialValueFor("radius"), SHORT_IMPACT_DURATION)
	ClearContext(self)
end

function xhs_spirit_earth_resonant_pillar:OnAbilityPhaseStart()
	if not IsServer() then return true end
	local center = GetContext(self).position or self:GetCaster():GetAbsOrigin()
	StartBossCastBar(self, "Resonant Pillar")
	XHSBossTelegraphs:Ring(center, self:GetSpecialValueFor("ring_radius"), self:GetSpecialValueFor("radius"), 3, self:GetCastPoint(), COLORS.earth, 90)
	return true
end

function xhs_spirit_earth_resonant_pillar:OnAbilityPhaseInterrupted() if IsServer() then HideBossCastBar(self) end end
function xhs_spirit_earth_resonant_pillar:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local center = GetContext(self).position or caster:GetAbsOrigin()
	for i = 1, 3 do
		local pos = RotatePosition(center, QAngle(0, ((i - 1) / 3) * 360 + 90, 0), center + Vector(self:GetSpecialValueFor("ring_radius"), 0, 0))
		DamageEnemies(caster, self, pos, self:GetSpecialValueFor("radius"), ScaleDamage(self:GetSpecialValueFor("damage")), DAMAGE_TYPE_MAGICAL)
		CreateImpact(pos, EARTH_PILLAR_PARTICLE, self:GetSpecialValueFor("radius"), SHORT_IMPACT_DURATION)
	end
	ClearContext(self)
end

function xhs_spirit_fire_cinder_step:OnAbilityPhaseStart()
	if not IsServer() then return true end
	local caster = self:GetCaster()
	local direction = NormalizeDirection((GetContext(self).position or caster:GetAbsOrigin()) - caster:GetAbsOrigin())
	StartBossCastBar(self, "Cinder Step")
	XHSBossTelegraphs:Line(caster:GetAbsOrigin(), direction, self:GetSpecialValueFor("spacing"), self:GetSpecialValueFor("radius"), self:GetSpecialValueFor("nodes"), self:GetCastPoint(), COLORS.fire, 100)
	caster:EmitSound("Hero_EmberSpirit.FireRemnant.Activate")
	return true
end

function xhs_spirit_fire_cinder_step:OnAbilityPhaseInterrupted() if IsServer() then HideBossCastBar(self) end end
function xhs_spirit_fire_cinder_step:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local direction = NormalizeDirection((GetContext(self).position or caster:GetAbsOrigin()) - caster:GetAbsOrigin())
	for i = 1, self:GetSpecialValueFor("nodes") do
		local pos = caster:GetAbsOrigin() + direction * (100 + self:GetSpecialValueFor("spacing") * (i - 1))
		DamageEnemies(caster, self, pos, self:GetSpecialValueFor("radius"), ScaleDamage(self:GetSpecialValueFor("damage")), DAMAGE_TYPE_MAGICAL)
		CreateImpact(pos, FIRE_CINDER_PARTICLE, self:GetSpecialValueFor("radius"))
	end
	FindClearSpaceForUnit(caster, caster:GetAbsOrigin() + direction * self:GetSpecialValueFor("dash_distance"), true)
	ClearContext(self)
end

function xhs_spirit_fire_solar_flare:OnAbilityPhaseStart()
	if not IsServer() then return true end
	local position = GetContext(self).position or self:GetCaster():GetAbsOrigin()
	StartBossCastBar(self, "Solar Flare")
	XHSBossTelegraphs:Target(position, self:GetSpecialValueFor("radius"), self:GetCastPoint(), COLORS.fire)
	self:GetCaster():EmitSound("Hero_EmberSpirit.FlameGuard.Cast")
	return true
end

function xhs_spirit_fire_solar_flare:OnAbilityPhaseInterrupted() if IsServer() then HideBossCastBar(self) end end
function xhs_spirit_fire_solar_flare:OnSpellStart()
	if not IsServer() then return end
	local position = GetContext(self).position or self:GetCaster():GetAbsOrigin()
	DamageEnemies(self:GetCaster(), self, position, self:GetSpecialValueFor("radius"), ScaleDamage(self:GetSpecialValueFor("damage")), DAMAGE_TYPE_MAGICAL)
	CreateImpact(position, FIRE_SOLAR_PARTICLE, self:GetSpecialValueFor("radius"))
	EmitSoundOnLocationWithCaster(position, "Ability.LightStrikeArray", self:GetCaster())
	ClearContext(self)
end

function xhs_spirit_fire_wildfire_ring:OnAbilityPhaseStart()
	if not IsServer() then return true end
	local center = GetContext(self).position or self:GetCaster():GetAbsOrigin()
	StartBossCastBar(self, "Wildfire Ring")
	XHSBossTelegraphs:Ring(center, self:GetSpecialValueFor("outer_radius"), self:GetSpecialValueFor("node_radius"), 12, self:GetCastPoint(), COLORS.fire, 0)
	XHSBossTelegraphs:Ring(center, self:GetSpecialValueFor("inner_radius"), self:GetSpecialValueFor("node_radius"), 8, self:GetCastPoint(), COLORS.fire, 22)
	return true
end

function xhs_spirit_fire_wildfire_ring:OnAbilityPhaseInterrupted() if IsServer() then HideBossCastBar(self) end end
function xhs_spirit_fire_wildfire_ring:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local center = GetContext(self).position or caster:GetAbsOrigin()
	local damage = ScaleDamage(self:GetSpecialValueFor("damage"))
	local nodeRadius = self:GetSpecialValueFor("node_radius")
	for _, ring in pairs({ { self:GetSpecialValueFor("outer_radius"), 12 }, { self:GetSpecialValueFor("inner_radius"), 8 } }) do
		for i = 1, ring[2] do
			local pos = RotatePosition(center, QAngle(0, ((i - 1) / ring[2]) * 360, 0), center + Vector(ring[1], 0, 0))
			DamageEnemies(caster, self, pos, nodeRadius, damage, DAMAGE_TYPE_MAGICAL)
			CreateImpact(pos, FIRE_WILDFIRE_PARTICLE, nodeRadius)
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
	ApplyDamage({ victim = parent, attacker = caster, ability = ability, damage = ScaleDamage(ability:GetSpecialValueFor("fire_burn_damage")), damage_type = DAMAGE_TYPE_MAGICAL })
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
