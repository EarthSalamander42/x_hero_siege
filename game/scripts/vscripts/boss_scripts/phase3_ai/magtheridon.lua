require("boss_scripts/phase3_ai/core")

LinkLuaModifier("modifier_xhs_magtheridon_phase3_ai", "boss_scripts/phase3_ai/magtheridon.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_magtheridon_fragment", "boss_scripts/phase3_ai/magtheridon.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_magtheridon_empower", "boss_scripts/phase3_ai/magtheridon.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_magtheridon_twin_lockout", "boss_scripts/phase3_ai/magtheridon.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_magtheridon_slow", "boss_scripts/phase3_ai/magtheridon.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_magtheridon_cast_lock", "boss_scripts/phase3_ai/magtheridon.lua", LUA_MODIFIER_MOTION_NONE)

modifier_xhs_magtheridon_phase3_ai = modifier_xhs_magtheridon_phase3_ai or class({})
modifier_xhs_magtheridon_phase3_ai.XHS_LINK_CLIENT = true
modifier_xhs_magtheridon_fragment = modifier_xhs_magtheridon_fragment or class({})
modifier_xhs_magtheridon_fragment.XHS_LINK_CLIENT = true
modifier_xhs_magtheridon_empower = modifier_xhs_magtheridon_empower or class({})
modifier_xhs_magtheridon_empower.XHS_LINK_CLIENT = true
modifier_xhs_magtheridon_twin_lockout = modifier_xhs_magtheridon_twin_lockout or class({})
modifier_xhs_magtheridon_twin_lockout.XHS_LINK_CLIENT = true
modifier_xhs_magtheridon_slow = modifier_xhs_magtheridon_slow or class({})
modifier_xhs_magtheridon_slow.XHS_LINK_CLIENT = true
modifier_xhs_magtheridon_cast_lock = modifier_xhs_magtheridon_cast_lock or class({})
modifier_xhs_magtheridon_cast_lock.XHS_LINK_CLIENT = true

local INFERNAL_ROOT_MODIFIER = "modifier_xhs_magtheridon_infernal_root"
local EMPOWER_OVERHEAD_PARTICLE = "particles/units/heroes/heroes_underlord/abyssal_underlord_portal_timer.vpcf"

local MAGTHERIDON_ABILITIES = {
	"xhs_magtheridon_brutal_slam",
	"xhs_magtheridon_fel_stomp",
	"xhs_magtheridon_targeted_firestorms",
	"xhs_magtheridon_fel_fissure",
	"xhs_magtheridon_infernal_rings",
	"xhs_magtheridon_demonic_howl",
	"xhs_magtheridon_rupture",
	"xhs_creeps_phase_2_unholy_aura",
	"command_aura",
	"necronomicon_warrior_sight",
	"boss_health",
}

local WARNING_PARTICLE = "particles/custom/boss_warnings/magtheridon/radius.vpcf"
local FEL_WARNING_PARTICLE = "particles/custom/boss_warnings/magtheridon/radius.vpcf"
local SPAWN_WARNING_PARTICLE = "particles/units/heroes/hero_templar_assassin/templar_assassin_trap_rings_inner.vpcf"
local SPAWN_PARTICLE = "particles/units/heroes/hero_shadowshaman/shadow_shaman_dust_hit.vpcf"

local RUPTURE_REINCARNATE_TIME = 20.0
local MEDIUM_FRAGMENT_COUNT = 8
local SMALL_FRAGMENT_COUNT = 16
local RUPTURE_FRAGMENT_TOTAL = MEDIUM_FRAGMENT_COUNT + SMALL_FRAGMENT_COUNT
local RUPTURE_FRAGMENTS_PER_STACK = 3
local RUPTURE_MAX_EMPOWER_STACKS = 10
local RUPTURE_EMPOWER_DURATION = 35.0
local RUPTURE_DAMAGE_PER_STACK = 5
local RUPTURE_ARMOR_PER_STACK = 5
local RUPTURE_MODEL_SCALE_PER_STACK = 3

local FRAGMENT_SCALE = {
	[1] = { health = 0.75, damage = 1.00, armor = 0.70, move = 0.95 },
	[2] = { health = 1.00, damage = 1.20, armor = 1.00, move = 1.00 },
	[3] = { health = 1.15, damage = 1.45, armor = 1.10, move = 1.05 },
	[4] = { health = 1.25, damage = 1.75, armor = 1.20, move = 1.08 },
	[5] = { health = 1.40, damage = 2.10, armor = 1.35, move = 1.12 },
}

local function GetArenaCenter()
	local spawner = Entities:FindByName(nil, "npc_dota_spawner_magtheridon_arena")
	if spawner ~= nil then
		return spawner:GetAbsOrigin()
	end

	return Vector(0, 0, 0)
end

local function RegisterDevSpawn(unit)
	if unit ~= nil and XHSDevTools ~= nil and XHSDevTools:IsSandboxActive() then
		XHSDevTools:RegisterSpawnedUnit(unit)
	end
end

local function IsValidAlive(unit)
	return unit ~= nil and IsValidEntity(unit) and not unit:IsNull() and unit:IsAlive()
end

local function GetRuptureAbilityValue(unit, key, fallback)
	if unit == nil or not IsValidEntity(unit) or unit:IsNull() then return fallback end

	local ability = unit:FindAbilityByName("xhs_magtheridon_rupture")
	if ability == nil or ability:IsNull() then return fallback end

	local value = ability:GetSpecialValueFor(key)
	if value ~= nil and value > 0 then return value end
	return fallback
end

local function BuildRuptureConfig(unit)
	local mediumFragments = GetRuptureAbilityValue(unit, "medium_fragments", MEDIUM_FRAGMENT_COUNT)
	local smallFragments = GetRuptureAbilityValue(unit, "small_fragments", SMALL_FRAGMENT_COUNT)

	return {
		reincarnate_time = GetRuptureAbilityValue(unit, "reincarnate_time", RUPTURE_REINCARNATE_TIME),
		medium_fragments = mediumFragments,
		small_fragments = smallFragments,
		total_fragments = mediumFragments + smallFragments,
		fragments_per_stack = GetRuptureAbilityValue(unit, "empower_fragments_per_stack", RUPTURE_FRAGMENTS_PER_STACK),
		max_empower_stacks = GetRuptureAbilityValue(unit, "max_empower_stacks", RUPTURE_MAX_EMPOWER_STACKS),
		empower_duration = GetRuptureAbilityValue(unit, "empower_duration", RUPTURE_EMPOWER_DURATION),
		damage_per_stack = GetRuptureAbilityValue(unit, "damage_per_stack", RUPTURE_DAMAGE_PER_STACK),
		armor_per_stack = GetRuptureAbilityValue(unit, "armor_per_stack", RUPTURE_ARMOR_PER_STACK),
		model_scale_per_stack = GetRuptureAbilityValue(unit, "model_scale_per_stack", RUPTURE_MODEL_SCALE_PER_STACK),
	}
end

local function FaceUnitTowardsPosition(unit, position)
	if unit == nil or not IsValidEntity(unit) or unit:IsNull() or position == nil then return end

	local direction = position - unit:GetAbsOrigin()
	direction.z = 0
	if direction:Length2D() <= 0 then return end

	unit:SetForwardVector(direction:Normalized())
	unit:FaceTowards(position)
end

local function CreateWarning(position, radius, delay, fel)
	local particle = ParticleManager:CreateParticle(fel == true and FEL_WARNING_PARTICLE or WARNING_PARTICLE, PATTACH_WORLDORIGIN, nil)
	local color = fel == true and Vector(190, 255, 85) or Vector(102, 255, 64)
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius, delay or 1.0, 0))
	ParticleManager:SetParticleControl(particle, 2, Vector(delay or 1.0, 0, 1))
	ParticleManager:SetParticleControl(particle, 3, color)
	ParticleManager:SetParticleControl(particle, 4, position)
	ParticleManager:SetParticleControl(particle, 15, color)
	ParticleManager:SetParticleControl(particle, 16, Vector(1, 0, 0))
	Timers:CreateTimer(math.max(0.1, tonumber(delay) or 1.0), function()
		ParticleManager:DestroyParticle(particle, true)
		ParticleManager:ReleaseParticleIndex(particle)
		return nil
	end)
end

local function CreateImpact(position, radius, particleName)
	local particle = ParticleManager:CreateParticle(particleName or SPAWN_PARTICLE, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, position)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius, 0, 0))
	ParticleManager:ReleaseParticleIndex(particle)
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
				damage = XHSPhase3BossAI:ScaleDamage(damage),
				damage_type = damageType or ability:GetAbilityDamageType(),
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

local function BeginBossCastAnimation(boss, duration, activity, rate, facePosition)
	if not IsValidAlive(boss) then return end

	boss:SetForceAttackTarget(nil)
	if boss.SetAttacking ~= nil then
		boss:SetAttacking(nil)
	end
	boss:Stop()

	ExecuteOrderFromTable({
		UnitIndex = boss:entindex(),
		OrderType = DOTA_UNIT_ORDER_STOP,
	})

	if facePosition ~= nil then
		FaceUnitTowardsPosition(boss, facePosition)
	end

	boss:AddNewModifier(boss, nil, "modifier_xhs_magtheridon_cast_lock", { duration = duration })
	StartAnimation(boss, {
		duration = duration,
		activity = activity,
		rate = rate or 1.0,
	})
end

local function GetAbilityCastPoint(ability)
	if ability == nil then return 0 end
	if ability.GetCastPoint ~= nil then
		local castPoint = ability:GetCastPoint()
		if castPoint ~= nil and castPoint > 0 then return castPoint end
	end

	return ability:GetSpecialValueFor("cast_point")
end

local function CastPreparedAbility(boss, abilityName, context, facePosition)
	if not IsValidAlive(boss) then return nil end

	local ability = boss:FindAbilityByName(abilityName)
	if ability == nil or ability:IsNull() then return nil end
	if XHSPhase3BossAI:IsCastBlocked(boss) then return nil end

	ability.xhs_magtheridon_context = context or {}
	ability.xhs_magtheridon_context.arena_center = ability.xhs_magtheridon_context.arena_center or GetArenaCenter()

	if facePosition ~= nil then
		FaceUnitTowardsPosition(boss, facePosition)
	end

	XHSPhase3BossAI:ProtectCast(boss, ability)
	boss:CastAbilityNoTarget(ability, -1)
	return ability
end

local function GetMagtheridonRuptures()
	GameMode.MagtheridonRuptures = GameMode.MagtheridonRuptures or {}
	return GameMode.MagtheridonRuptures
end

local function GetRupture(bossCount)
	local ruptures = GetMagtheridonRuptures()
	ruptures[bossCount or 1] = ruptures[bossCount or 1] or {
		fragments = {},
		total = RUPTURE_FRAGMENT_TOTAL,
		active = false,
	}

	return ruptures[bossCount or 1]
end

local function CountLivingFragments(bossCount)
	local rupture = GetRupture(bossCount)
	local living = 0

	for key, unit in pairs(rupture.fragments or {}) do
		if IsValidAlive(unit) then
			living = living + 1
		else
			rupture.fragments[key] = nil
		end
	end

	return living
end

local function UpdateFragmentCounter(bossCount)
	local rupture = GetRupture(bossCount)
	if rupture.active ~= true then return end

	CustomGameEventManager:Send_ServerToAllClients("xhs_boss_counter_update", {
		boss_count = bossCount or 1,
		boss_bar_id = "magtheridon_" .. tostring(bossCount or 1),
		label = "Fragments left",
		remaining = CountLivingFragments(bossCount),
		total = rupture.total or RUPTURE_FRAGMENT_TOTAL,
	})
end

local function HideFragmentCounter(bossCount)
	CustomGameEventManager:Send_ServerToAllClients("xhs_boss_counter_hide", {
		boss_count = bossCount or 1,
		boss_bar_id = "magtheridon_" .. tostring(bossCount or 1),
	})
end

local function UpdateBossTimer(bossCount, label, remaining, duration)
	CustomGameEventManager:Send_ServerToAllClients("xhs_boss_timer_update", {
		boss_count = bossCount or 1,
		boss_bar_id = "magtheridon_" .. tostring(bossCount or 1),
		label = label or "Reincarnation",
		remaining = math.max(0, remaining or 0),
		duration = math.max(1, duration or 1),
		style = "magtheridon",
	})
end

local function HideBossTimer(bossCount)
	CustomGameEventManager:Send_ServerToAllClients("xhs_boss_timer_hide", {
		boss_count = bossCount or 1,
		boss_bar_id = "magtheridon_" .. tostring(bossCount or 1),
	})
end

local function CleanupRuptureFragments(bossCount)
	local rupture = GetRupture(bossCount)
	for key, unit in pairs(rupture.fragments or {}) do
		if unit ~= nil and IsValidEntity(unit) and not unit:IsNull() then
			UTIL_Remove(unit)
		end
		rupture.fragments[key] = nil
	end
end

local function FindLivingBigMagtheridons()
	local result = {}
	local units = FindUnitsInRadius(
		DOTA_TEAM_CUSTOM_2,
		Vector(0, 0, 0),
		nil,
		FIND_UNITS_EVERYWHERE,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_ALL,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
		FIND_ANY_ORDER,
		false
	)

	for _, unit in pairs(units) do
		if IsValidAlive(unit) and unit:GetUnitName() == "npc_dota_hero_magtheridon" then
			result[#result + 1] = unit
		end
	end

	return result
end

local function LockOtherMagtheridons(deadBossCount, duration)
	for _, boss in pairs(FindLivingBigMagtheridons()) do
		if boss.boss_count ~= deadBossCount and boss.ankh_respawn ~= true then
			boss:AddNewModifier(boss, nil, "modifier_xhs_magtheridon_twin_lockout", {
				duration = duration,
				source_boss_count = deadBossCount,
			})
		end
	end
end

local function PositionOnRing(center, radius, index, count, offsetDegrees)
	local angle = ((index - 1) / count) * 360 + (offsetDegrees or 0)
	return RotatePosition(center, QAngle(0, angle, 0), center + Vector(radius, 0, 0))
end

local function PickClosestHeroFromPosition(position)
	local heroes = XHSPhase3BossAI:GetLivingHeroes(GetArenaCenter(), 2800, true)
	local best = nil
	local bestDistance = nil

	for _, hero in pairs(heroes) do
		if IsValidAlive(hero) then
			local distance = (hero:GetAbsOrigin() - position):Length2D()
			if best == nil or distance < bestDistance then
				best = hero
				bestDistance = distance
			end
		end
	end

	return best
end

local function StartFragmentSeek(fragment)
	if not IsValidAlive(fragment) then return end

	local contextName = "xhs_magtheridon_fragment_seek_" .. tostring(fragment:entindex())
	fragment:SetContextThink(contextName, function()
		if not IsValidAlive(fragment) then return nil end

		local target = PickClosestHeroFromPosition(fragment:GetAbsOrigin())
		if IsValidAlive(target) then
			ExecuteOrderFromTable({
				UnitIndex = fragment:entindex(),
				OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
				TargetIndex = target:entindex(),
			})
		else
			ExecuteOrderFromTable({
				UnitIndex = fragment:entindex(),
				OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
				Position = GetArenaCenter(),
			})
		end

		return 1.0
	end, 0.25)
end

local function SpawnFragment(unitName, bossCount, position, center, delay, ringName)
	CreateWarning(position, unitName == "npc_dota_hero_magtheridon_medium" and 190 or 135, delay + 0.35, true)

	local spawnWarning = ParticleManager:CreateParticle(SPAWN_WARNING_PARTICLE, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(spawnWarning, 0, position)

	Timers:CreateTimer(delay, function()
		ParticleManager:DestroyParticle(spawnWarning, false)
		ParticleManager:ReleaseParticleIndex(spawnWarning)

		local fragment = CreateUnitByName(unitName, position, true, nil, nil, DOTA_TEAM_CUSTOM_2)
		if fragment == nil then return nil end

		fragment.zone = "xhs_holdout"
		fragment.xhs_magtheridon_fragment_boss_count = bossCount
		fragment.xhs_magtheridon_fragment_ring = ringName
		fragment:AddNewModifier(fragment, nil, "modifier_xhs_magtheridon_fragment", {})
		FaceUnitTowardsPosition(fragment, center)
		RegisterDevSpawn(fragment)
		StartFragmentSeek(fragment)

		local rupture = GetRupture(bossCount)
		rupture.fragments[tostring(fragment:entindex())] = fragment

		CreateImpact(position, unitName == "npc_dota_hero_magtheridon_medium" and 210 or 145, SPAWN_PARTICLE)
		fragment:EmitSound("Hero_AbyssalUnderlord.Pit.Target")
		UpdateFragmentCounter(bossCount)

		return nil
	end)
end

local function SpawnRuptureFragments(bossCount, origin, sourceBoss)
	local center = GetArenaCenter()
	local config = BuildRuptureConfig(sourceBoss)
	local rupture = GetRupture(bossCount)
	rupture.fragments = {}
	rupture.config = config
	rupture.total = config.total_fragments
	rupture.active = true

	local mediumRadius = 560
	local smallRadius = 900

	for i = 1, config.medium_fragments do
		local position = PositionOnRing(center, mediumRadius, i, config.medium_fragments, 22.5)
		SpawnFragment("npc_dota_hero_magtheridon_medium", bossCount, position, center, 0.45 + i * 0.08, "inner")
	end

	for i = 1, config.small_fragments do
		local position = PositionOnRing(center, smallRadius, i, config.small_fragments, 11.25)
		SpawnFragment("npc_dota_hero_magtheridon_small", bossCount, position, center, 0.8 + i * 0.04, "outer")
	end

	AddFOWViewer(DOTA_TEAM_GOODGUYS, origin or center, 1200, 3.0, false)
	UpdateFragmentCounter(bossCount)
end

function XHSMagtheridon_AttachPhase3AI(boss)
	if boss == nil or not IsValidEntity(boss) or boss:IsNull() then return end
	if boss:GetUnitName() ~= "npc_dota_hero_magtheridon" then return end

	boss:RemoveModifierByName("modifier_ai")
	if boss:HasModifier("modifier_xhs_magtheridon_phase3_ai") then return end
	XHSPhase3BossAI:HideVanillaHealthBar(boss)
	boss:AddNewModifier(boss, nil, "modifier_xhs_magtheridon_phase3_ai", {})
end

function XHSMagtheridon_StartRupture(deadBoss, bossCount, position, charges, reincarnateTime)
	bossCount = bossCount or 1
	local config = BuildRuptureConfig(deadBoss)
	reincarnateTime = reincarnateTime or config.reincarnate_time
	config.reincarnate_time = reincarnateTime

	LockOtherMagtheridons(bossCount, reincarnateTime)
	SpawnRuptureFragments(bossCount, position, deadBoss)
	GetRupture(bossCount).config = config
	UpdateBossTimer(bossCount, "Rebirth: kill fragments", reincarnateTime, reincarnateTime)

	local startedAt = GameRules:GetGameTime()
	Timers:CreateTimer(0.25, function()
		local remaining = math.max(0, reincarnateTime - (GameRules:GetGameTime() - startedAt))
		UpdateBossTimer(bossCount, "Rebirth: kill fragments", math.ceil(remaining), reincarnateTime)
		if remaining > 0 then return 0.25 end
		return nil
	end)
end

function XHSMagtheridon_GetRuptureEmpowerStacks(bossCount)
	local living = CountLivingFragments(bossCount)
	local rupture = GetRupture(bossCount)
	local config = rupture.config or {}
	local fragmentsPerStack = math.max(1, config.fragments_per_stack or RUPTURE_FRAGMENTS_PER_STACK)
	local maxStacks = config.max_empower_stacks or RUPTURE_MAX_EMPOWER_STACKS
	return math.min(maxStacks, math.ceil(living / fragmentsPerStack))
end

function XHSMagtheridon_OnRespawned(boss, bossCount, empowerStacks)
	if boss == nil or not IsValidEntity(boss) or boss:IsNull() then return end

	boss.boss_count = bossCount or boss.boss_count or 1
	boss.xhs_boss_bar_id = "magtheridon_" .. tostring(boss.boss_count)
	-- RespawnMagtheridon creates a new entity, which needs its own health poller
	-- even when Source recycles the previous Magtheridon's entity index.
	boss.deathStart = nil
	boss.xhs_boss_bar_suppressed = nil
	boss.xhs_boss_bar_think_active = nil
	-- Entity-handle recycling can also preserve the compact/private selection
	-- bookkeeping. Magtheridon is a global major boss after every rebirth.
	boss.xhs_boss_bar_players = nil
	boss.xhs_boss_bar_lock_to_registered = nil
	boss.xhs_boss_bar_display_mode = "major_boss"
	boss.zone = "xhs_holdout"
	RegisterDevSpawn(boss)
	XHSMagtheridon_AttachPhase3AI(boss)

	local rupture = GetRupture(boss.boss_count)
	local config = rupture.config or BuildRuptureConfig(boss)

	if empowerStacks ~= nil and empowerStacks > 0 then
		local modifier = boss:AddNewModifier(boss, nil, "modifier_xhs_magtheridon_empower", {
			duration = config.empower_duration or RUPTURE_EMPOWER_DURATION,
			damage_per_stack = config.damage_per_stack or RUPTURE_DAMAGE_PER_STACK,
			armor_per_stack = config.armor_per_stack or RUPTURE_ARMOR_PER_STACK,
			model_scale_per_stack = config.model_scale_per_stack or RUPTURE_MODEL_SCALE_PER_STACK,
		})
		if modifier ~= nil then
			modifier:SetStackCount(empowerStacks)
		end
	end

	CleanupRuptureFragments(boss.boss_count)
	rupture.active = false
	HideBossTimer(boss.boss_count)
	HideFragmentCounter(boss.boss_count)

	if ShowBossBar ~= nil then
		ShowBossBar(boss)
	end
end

function XHSMagtheridon_HideBossTimer(bossCount)
	HideBossTimer(bossCount)
end

function XHSMagtheridon_HideFragmentCounter(bossCount)
	HideFragmentCounter(bossCount)
end

function XHSMagtheridon_UpdateFragmentCounter(bossCount)
	UpdateFragmentCounter(bossCount)
end

function modifier_xhs_magtheridon_phase3_ai:IsHidden() return true end
function modifier_xhs_magtheridon_phase3_ai:IsPurgable() return false end

function modifier_xhs_magtheridon_phase3_ai:OnCreated()
	if not IsServer() then return end

	local boss = self:GetParent()
	self.arena_center = GetArenaCenter()
	self.recent_positions = {}
	self.patterns = {}
	self.state = "intro"
	self.cast_until = 0
	self.recover_until = 0
	self.basic_ready_at = 0
	self.last_pattern = nil
	self.major_lock_id = tostring(boss:entindex())
	self.thresholds_done = {}

	boss:RemoveModifierByName("modifier_ai")
	XHSPhase3BossAI:SetAbilityLevels(boss, MAGTHERIDON_ABILITIES)
	self:UpdateBossBarMarkers()
	self:BuildPatternDeck()
	self:StartIntervalThink(0.25)
end

function modifier_xhs_magtheridon_phase3_ai:IsBossActive()
	local boss = self:GetParent()
	return boss ~= nil and IsValidEntity(boss) and not boss:IsNull() and boss:IsAlive() and boss.deathStart ~= true and boss.ankh_respawn ~= true
end

function modifier_xhs_magtheridon_phase3_ai:BuildPatternDeck()
	local now = GameRules:GetGameTime()
	self.patterns = {
		{ id = "fel_stomp", weight = 4, cooldown = 8.0, ready_at = 0, run = function() return self:CastFelStomp() end },
		{ id = "targeted_firestorms", weight = 4, cooldown = 10.0, ready_at = 0, run = function() return self:CastTargetedFirestorms() end },
		{ id = "rupture", weight = 3, cooldown = 9.0, ready_at = 0, run = function() return self:CastRupture() end },
		{ id = "infernal_rings", weight = 3, cooldown = 11.0, ready_at = now + 3.0, run = function() return self:CastInfernalRings() end },
		{ id = "demonic_howl", weight = 2, cooldown = 18.0, ready_at = now + 7.0, run = function() return self:CastDemonicHowl() end },
	}
end

function modifier_xhs_magtheridon_phase3_ai:UpdateBossBarMarkers()
	local boss = self:GetParent()
	local ankh = boss:FindModifierByName("modifier_ankh_passives")
	local charges = ankh ~= nil and ankh:GetStackCount() or 0
	boss.xhs_boss_bar_markers = {}

	if charges > 0 then
		boss.xhs_boss_bar_markers[#boss.xhs_boss_bar_markers + 1] = {
			pct = 0,
			kind = "companion",
			label = "Demonic Rebirth",
			description = "On death with ankh charges, Magtheridon reincarnates after 20s. Kill fragments before he returns; survivors empower his damage and armor.",
			triggered = false,
		}
	end
end

function modifier_xhs_magtheridon_phase3_ai:OnIntervalThink()
	if not self:IsBossActive() then
		self.state = "dead"
		self:StartIntervalThink(-1)
		return
	end

	local boss = self:GetParent()
	local now = GameRules:GetGameTime()
	boss:RemoveModifierByName("modifier_ai")

	self:TrackHeroPositions()

	if boss:HasModifier("modifier_invulnerable") or boss:HasModifier("modifier_pause_creeps") or boss:HasModifier("modifier_xhs_magtheridon_twin_lockout") then
		self.state = "intro"
		return
	end

	if self:TryBasicPressure(now) then return end

	if self.state == "casting" then
		if now < self.cast_until then return end
		self.state = "recovery"
	end

	if self.state == "recovery" then
		if now < self.recover_until then return end
		self.state = "idle"
	end

	local entry = self:GetNextPattern(now)
	if entry == nil then
		self:Reposition()
		return
	end

	self:RunPattern(entry, now)
end

function modifier_xhs_magtheridon_phase3_ai:TrackHeroPositions()
	local heroes = XHSPhase3BossAI:GetLivingHeroes(self.arena_center, 2500, true)
	local now = GameRules:GetGameTime()
	for _, hero in pairs(heroes) do
		if IsValidAlive(hero) then
			local key = tostring(hero:entindex())
			local previous = self.recent_positions[key]
			self.recent_positions[key] = {
				current = hero:GetAbsOrigin(),
				previous = previous and previous.current or hero:GetAbsOrigin(),
				current_time = now,
				previous_time = previous and previous.current_time or now,
			}
		end
	end
end

function modifier_xhs_magtheridon_phase3_ai:GetPredictedHeroPosition(hero, lead)
	if hero == nil then return self.arena_center end

	local position = hero:GetAbsOrigin()
	local tracked = self.recent_positions[tostring(hero:entindex())]
	if tracked == nil then return position end

	local velocity = tracked.current - tracked.previous
	return tracked.current + velocity * (lead or 1.2)
end

function modifier_xhs_magtheridon_phase3_ai:GetPredictedHeroDropPosition(hero, secondsAhead)
	if hero == nil then return self.arena_center end

	local position = hero:GetAbsOrigin()
	local tracked = self.recent_positions[tostring(hero:entindex())]
	if tracked == nil then return position end

	local dt = math.max(0.03, (tracked.current_time or GameRules:GetGameTime()) - (tracked.previous_time or tracked.current_time or GameRules:GetGameTime()))
	local velocity = (tracked.current - tracked.previous) * (1 / dt)
	velocity.z = 0
	local speed = velocity:Length2D()
	local maxSpeed = hero.GetIdealSpeed ~= nil and math.max(350, hero:GetIdealSpeed() * 1.35) or 900
	if speed > maxSpeed then
		velocity = velocity:Normalized() * maxSpeed
	end

	return tracked.current + velocity * math.max(0, secondsAhead or 0)
end

function modifier_xhs_magtheridon_phase3_ai:GetRootedHeroes()
	local rooted = {}
	local heroes = XHSPhase3BossAI:GetLivingHeroes(self.arena_center, 2500, true)

	for _, hero in pairs(heroes) do
		if IsValidAlive(hero) and hero:HasModifier(INFERNAL_ROOT_MODIFIER) then
			rooted[#rooted + 1] = hero
		end
	end

	return rooted
end

function modifier_xhs_magtheridon_phase3_ai:HasRootedHeroForFirestorm()
	return #self:GetRootedHeroes() > 0
end

function modifier_xhs_magtheridon_phase3_ai:CanUseMajorPattern(now)
	GameMode.MagtheridonMajorCastLockUntil = GameMode.MagtheridonMajorCastLockUntil or 0
	if now >= GameMode.MagtheridonMajorCastLockUntil then return true end

	return GameMode.MagtheridonMajorCastOwner == self.major_lock_id
end

function modifier_xhs_magtheridon_phase3_ai:GetNextPattern(now)
	if not self:CanUseMajorPattern(now) then return nil end
	if self:HasRootedHeroForFirestorm() then
		for _, entry in pairs(self.patterns) do
			if entry.id == "targeted_firestorms" and now >= (entry.ready_at or 0) then
				return entry
			end
		end
	end

	return XHSPhase3BossAI:WeightedChoice(self.patterns, now)
end

function modifier_xhs_magtheridon_phase3_ai:RunPattern(entry, now)
	local duration = entry.run()
	if duration == nil or duration <= 0 then
		entry.ready_at = now + 1.0
		return
	end

	entry.ready_at = now + XHSPhase3BossAI:ScaleDelay(entry.cooldown)
	self.last_pattern = entry.id
	self.state = "casting"
	self.cast_until = now + duration
	self.recover_until = self.cast_until + XHSPhase3BossAI:ScaleDelay(1.0)
	GameMode.MagtheridonMajorCastOwner = self.major_lock_id
	GameMode.MagtheridonMajorCastLockUntil = self.recover_until

	if entry.id == "infernal_rings" then
		for _, pattern in pairs(self.patterns) do
			if pattern.id == "targeted_firestorms" then
				pattern.ready_at = math.min(pattern.ready_at or self.recover_until, self.recover_until)
			end
		end
	end
end

function modifier_xhs_magtheridon_phase3_ai:Reposition()
	self.state = "reposition"
	local boss = self:GetParent()
	local target = XHSPhase3BossAI:PickClosestHero(self.arena_center, 2500)
	local targetPosition = target ~= nil and target:GetAbsOrigin() or self.arena_center
	local direction = (boss:GetAbsOrigin() - targetPosition):Normalized()
	if direction:Length2D() <= 0 then direction = RandomVector(1) end
	local position = self.arena_center + direction * RandomFloat(320, 520)

	XHSPhase3BossAI:MoveBoss(boss, position)
	self.recover_until = GameRules:GetGameTime() + 0.8
	self.state = "recovery"
end

function modifier_xhs_magtheridon_phase3_ai:TryBasicPressure(now)
	if now < self.basic_ready_at or self.state == "casting" or self.state == "recovery" then return end

	local boss = self:GetParent()
	local target = XHSPhase3BossAI:PickClosestHero(boss:GetAbsOrigin(), 450)
	if target == nil then return end

	local ability = boss:FindAbilityByName("xhs_magtheridon_brutal_slam")
	if ability == nil then return end

	self.basic_ready_at = now + XHSPhase3BossAI:ScaleDelay(4.0)
	local castPoint = GetAbilityCastPoint(ability)
	local duration = castPoint + 0.45

	CastPreparedAbility(boss, "xhs_magtheridon_brutal_slam", {
		position = target:GetAbsOrigin(),
		target = target,
	}, target:GetAbsOrigin())

	self.state = "casting"
	self.cast_until = now + duration
	self.recover_until = self.cast_until + 0.15
	return true
end

function modifier_xhs_magtheridon_phase3_ai:CastFelStomp()
	local boss = self:GetParent()
	local ability = CastPreparedAbility(boss, "xhs_magtheridon_fel_stomp", {}, boss:GetAbsOrigin() + Vector(0, -100, 0))
	if ability == nil then return nil end

	return GetAbilityCastPoint(ability) + 0.45
end

function modifier_xhs_magtheridon_phase3_ai:CastTargetedFirestorms()
	local boss = self:GetParent()
	local ability = boss:FindAbilityByName("xhs_magtheridon_targeted_firestorms")
	local rootedHeroes = self:GetRootedHeroes()
	local heroes = #rootedHeroes > 0 and rootedHeroes or XHSPhase3BossAI:GetLivingHeroes(self.arena_center, 2500, true)
	if ability == nil or #heroes <= 0 then return nil end

	local count = XHSPhase3BossAI:ScaleDensity(ability:GetSpecialValueFor("target_count"), 2)
	local waves = XHSPhase3BossAI:ScaleDensity(ability:GetSpecialValueFor("waves"), 2)
	local waveInterval = XHSPhase3BossAI:ScaleDelay(ability:GetSpecialValueFor("wave_interval"))
	local targetStagger = XHSPhase3BossAI:ScaleDelay(ability:GetSpecialValueFor("target_stagger"))
	local castPoint = GetAbilityCastPoint(ability)
	local impacts = {}

	for i = 1, count do
		local hero = heroes[((i - 1) % #heroes) + 1]
		for wave = 1, waves do
			local impactDelay = (wave - 1) * waveInterval + (i - 1) * targetStagger
			local dropPosition = self:GetPredictedHeroDropPosition(hero, castPoint + impactDelay)
			impacts[#impacts + 1] = {
				position = dropPosition + RandomVector(RandomFloat(0, 120)) + RandomVector((wave - 1) * 85),
				delay = impactDelay,
			}
		end
	end

	local castFacePosition = heroes[1] ~= nil and heroes[1]:GetAbsOrigin() or nil
	local castAbility = CastPreparedAbility(boss, "xhs_magtheridon_targeted_firestorms", { impacts = impacts }, castFacePosition)
	if castAbility == nil then return nil end

	return castPoint + waves * waveInterval + count * targetStagger + 0.4
end

function modifier_xhs_magtheridon_phase3_ai:CastFelFissure()
	local boss = self:GetParent()
	local ability = boss:FindAbilityByName("xhs_magtheridon_fel_fissure")
	local target = XHSPhase3BossAI:PickFarthestHero(self.arena_center, 2500)
	if ability == nil or target == nil then return nil end

	local count = math.max(3, ability:GetSpecialValueFor("impact_count"))
	local spacing = ability:GetSpecialValueFor("spacing")
	local startDistance = ability:GetSpecialValueFor("start_distance")
	local stagger = XHSPhase3BossAI:ScaleDelay(ability:GetSpecialValueFor("impact_stagger"))
	local start = boss:GetAbsOrigin()
	local targetPosition = self:GetPredictedHeroPosition(target, 1.8)
	local direction = (targetPosition - start):Normalized()
	if direction:Length2D() <= 0 then direction = Vector(1, 0, 0) end

	local impacts = {}
	for i = 1, count do
		impacts[#impacts + 1] = {
			position = start + direction * (startDistance + i * spacing),
			delay = i * stagger,
		}
	end

	local castAbility = CastPreparedAbility(boss, "xhs_magtheridon_fel_fissure", { impacts = impacts }, targetPosition)
	if castAbility == nil then return nil end

	return GetAbilityCastPoint(castAbility) + count * stagger + 0.45
end

function modifier_xhs_magtheridon_phase3_ai:CastInfernalRings()
	local boss = self:GetParent()
	local ability = boss:FindAbilityByName("xhs_magtheridon_infernal_rings")
	if ability == nil then return nil end

	local bossPosition = boss:GetAbsOrigin()
	local target = XHSPhase3BossAI:PickClosestHero(bossPosition, 2500)
	if target == nil then return nil end

	local castPoint = GetAbilityCastPoint(ability)
	local impactRadius = ability:GetSpecialValueFor("radius")
	local innerRingRadius = ability:GetSpecialValueFor("inner_ring_radius")
	local ringSpacing = ability:GetSpecialValueFor("ring_spacing")
	local ringCount = math.max(2, ability:GetSpecialValueFor("ring_count"))
	local ringArcSpacing = math.max(
		impactRadius * 2 + 1,
		ability:GetSpecialValueFor("ring_arc_spacing")
	)
	local stagger = XHSPhase3BossAI:ScaleDelay(ability:GetSpecialValueFor("impact_stagger"))
	local rotationOffset = self.last_pattern == "infernal_rings" and 18 or 0
	local impacts = {}

	for ringIndex = 1, ringCount do
		local radius = innerRingRadius + ((ringIndex - 1) * ringSpacing)
		local impactCount = math.max(
			3,
			math.floor(((2 * math.pi * radius) / ringArcSpacing) + 0.5)
		)
		local offset = rotationOffset

		-- Alternate the angular offset so gaps do not align between circles.
		if ringIndex % 2 == 0 then
			offset = offset + (180 / impactCount)
		end

		for i = 1, impactCount do
			local position = PositionOnRing(bossPosition, radius, i, impactCount, offset)
			impacts[#impacts + 1] = {
				position = position,
				delay = ((i + ringIndex) % 2) * stagger,
			}
		end
	end

	local castAbility = CastPreparedAbility(boss, "xhs_magtheridon_infernal_rings", { impacts = impacts }, bossPosition)
	if castAbility == nil then return nil end

	return castPoint + stagger + 0.5
end

function modifier_xhs_magtheridon_phase3_ai:CastDemonicHowl()
	local boss = self:GetParent()
	local ability = CastPreparedAbility(boss, "xhs_magtheridon_demonic_howl", {}, boss:GetAbsOrigin() + Vector(0, -100, 0))
	if ability == nil then return nil end

	return GetAbilityCastPoint(ability) + 0.55
end

function modifier_xhs_magtheridon_phase3_ai:CastRupture()
	local boss = self:GetParent()
	local ability = boss:FindAbilityByName("xhs_magtheridon_rupture")
	local target = XHSPhase3BossAI:PickFarthestHero(self.arena_center, 2500)
	if ability == nil then return nil end

	local lineCount = math.max(1, ability:GetSpecialValueFor("line_count"))
	local lineSpread = ability:GetSpecialValueFor("line_spread_degrees")
	local lineLength = ability:GetSpecialValueFor("line_length")
	local spacing = ability:GetSpecialValueFor("segment_spacing")
	local segmentCount = math.max(1, math.floor(lineLength / math.max(1, spacing)) + 1)
	local targetPosition = target ~= nil and target:GetAbsOrigin() or self.arena_center + Vector(1, 0, 0)
	local baseDirection = targetPosition - boss:GetAbsOrigin()
	baseDirection.z = 0
	if baseDirection:Length2D() <= 0 then baseDirection = Vector(1, 0, 0) end
	baseDirection = baseDirection:Normalized()

	local lines = {}
	for i = 1, lineCount do
		local offset = lineCount == 1 and 0 or (((i - 1) / (lineCount - 1)) - 0.5) * lineSpread
		lines[#lines + 1] = {
			start = boss:GetAbsOrigin(),
			direction = RotatePosition(Vector(0, 0, 0), QAngle(0, offset, 0), baseDirection),
			segment_count = segmentCount,
		}
	end

	local castAbility = CastPreparedAbility(boss, "xhs_magtheridon_rupture", {
		lines = lines,
		arena_center = self.arena_center,
	}, targetPosition)
	if castAbility == nil then return nil end

	return GetAbilityCastPoint(castAbility) + 0.65
end

function modifier_xhs_magtheridon_fragment:IsHidden() return true end
function modifier_xhs_magtheridon_fragment:IsPurgable() return false end

function modifier_xhs_magtheridon_fragment:OnCreated()
	if not IsServer() then return end

	local parent = self:GetParent()
	local difficulty = XHSPhase3BossAI:GetDifficulty()
	local scale = FRAGMENT_SCALE[difficulty] or FRAGMENT_SCALE[1]
	local unitName = parent:GetUnitName()
	local isMedium = unitName == "npc_dota_hero_magtheridon_medium"

	local health = (isMedium and 30000 or 7500) * scale.health
	local damageMin = (isMedium and 10002 or 6001) * scale.damage
	local damageMax = (isMedium and 10012 or 6012) * scale.damage
	local armor = (isMedium and 115 or 70) * scale.armor

	parent:SetBaseMaxHealth(math.floor(health))
	parent:SetMaxHealth(math.floor(health))
	parent:SetHealth(math.floor(health))
	parent:SetBaseDamageMin(math.floor(damageMin))
	parent:SetBaseDamageMax(math.floor(damageMax))
	parent:SetPhysicalArmorBaseValue(math.floor(armor))
	parent:SetBaseMoveSpeed(math.floor((isMedium and 390 or 430) * scale.move))
end

function modifier_xhs_magtheridon_fragment:DeclareFunctions() return {
	MODIFIER_EVENT_ON_DEATH,
} end

function modifier_xhs_magtheridon_fragment:OnDeath(params)
	if not IsServer() then return end
	if params.unit ~= self:GetParent() then return end

	XHSMagtheridon_UpdateFragmentCounter(self:GetParent().xhs_magtheridon_fragment_boss_count or 1)
end

function modifier_xhs_magtheridon_empower:IsHidden() return false end
function modifier_xhs_magtheridon_empower:IsPurgable() return false end
function modifier_xhs_magtheridon_empower:GetTexture() return "abyssal_underlord_atrophy_aura" end

function modifier_xhs_magtheridon_empower:OnCreated(params)
	params = params or {}
	self.damage_per_stack = params.damage_per_stack or RUPTURE_DAMAGE_PER_STACK
	self.armor_per_stack = params.armor_per_stack or RUPTURE_ARMOR_PER_STACK
	self.model_scale_per_stack = params.model_scale_per_stack or RUPTURE_MODEL_SCALE_PER_STACK

	if not IsServer() then return end
	self.overhead_particle = ParticleManager:CreateParticle(EMPOWER_OVERHEAD_PARTICLE, PATTACH_OVERHEAD_FOLLOW, self:GetParent())
	self:UpdateOverheadParticle()
end

function modifier_xhs_magtheridon_empower:OnRefresh(params)
	params = params or {}
	self.damage_per_stack = params.damage_per_stack or self.damage_per_stack or RUPTURE_DAMAGE_PER_STACK
	self.armor_per_stack = params.armor_per_stack or self.armor_per_stack or RUPTURE_ARMOR_PER_STACK
	self.model_scale_per_stack = params.model_scale_per_stack or self.model_scale_per_stack or RUPTURE_MODEL_SCALE_PER_STACK

	if IsServer() then
		self:UpdateOverheadParticle()
	end
end

function modifier_xhs_magtheridon_empower:OnStackCountChanged()
	if not IsServer() then return end
	self:UpdateOverheadParticle()
end

function modifier_xhs_magtheridon_empower:UpdateOverheadParticle()
	if self.overhead_particle ~= nil then
		local buffCount = math.max(0, self:GetStackCount())
		if buffCount > 9 then
			ParticleManager:SetParticleControl(self.overhead_particle, 1, Vector(1, buffCount - 10, 0))
		else
			ParticleManager:SetParticleControl(self.overhead_particle, 1, Vector(0, buffCount, 0))
		end
	end
end

function modifier_xhs_magtheridon_empower:OnDestroy()
	if not IsServer() then return end
	if self.overhead_particle ~= nil then
		ParticleManager:DestroyParticle(self.overhead_particle, false)
		ParticleManager:ReleaseParticleIndex(self.overhead_particle)
		self.overhead_particle = nil
	end
end

function modifier_xhs_magtheridon_empower:DeclareFunctions() return {
	MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
	MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	MODIFIER_PROPERTY_MODEL_SCALE,
} end

function modifier_xhs_magtheridon_empower:GetModifierBaseDamageOutgoing_Percentage()
	return self:GetStackCount() * (self.damage_per_stack or RUPTURE_DAMAGE_PER_STACK)
end

function modifier_xhs_magtheridon_empower:GetModifierPhysicalArmorBonus()
	return self:GetStackCount() * (self.armor_per_stack or RUPTURE_ARMOR_PER_STACK)
end

function modifier_xhs_magtheridon_empower:GetModifierModelScale()
	return self:GetStackCount() * (self.model_scale_per_stack or RUPTURE_MODEL_SCALE_PER_STACK)
end

function modifier_xhs_magtheridon_empower:GetEffectName()
	return nil
end

function modifier_xhs_magtheridon_empower:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function modifier_xhs_magtheridon_twin_lockout:IsHidden() return false end
function modifier_xhs_magtheridon_twin_lockout:IsPurgable() return false end
function modifier_xhs_magtheridon_twin_lockout:GetTexture() return "modifiers/ankh_of_reincarnation" end

function modifier_xhs_magtheridon_twin_lockout:OnCreated()
	if not IsServer() then return end
	self:GetParent():Stop()
end

function modifier_xhs_magtheridon_twin_lockout:CheckState()
	return {
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_STUNNED] = true,
	}
end

function modifier_xhs_magtheridon_slow:IsHidden() return false end
function modifier_xhs_magtheridon_slow:IsDebuff() return true end
function modifier_xhs_magtheridon_slow:IsPurgable() return true end
function modifier_xhs_magtheridon_slow:GetTexture()
	local ability = self:GetAbility()
	if ability ~= nil and not ability:IsNull() then
		return ability:GetAbilityTextureName()
	end

	return "custom/xhs_magtheridon_fel_fissure"
end

function modifier_xhs_magtheridon_slow:OnCreated(params)
	params = params or {}
	self.movement_slow = params.movement_slow or -20
	self.attack_slow = params.attack_slow or -120
end

function modifier_xhs_magtheridon_slow:OnRefresh(params)
	self:OnCreated(params)
end

function modifier_xhs_magtheridon_slow:DeclareFunctions() return {
	MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	MODIFIER_PROPERTY_TOOLTIP,
	MODIFIER_PROPERTY_TOOLTIP2,
} end

function modifier_xhs_magtheridon_slow:GetModifierMoveSpeedBonus_Percentage()
	return self.movement_slow
end

function modifier_xhs_magtheridon_slow:GetModifierAttackSpeedBonus_Constant()
	return self.attack_slow
end

function modifier_xhs_magtheridon_slow:OnTooltip()
	return math.abs(self.movement_slow or 0)
end

function modifier_xhs_magtheridon_slow:OnTooltip2()
	return math.abs(self.attack_slow or 0)
end

function modifier_xhs_magtheridon_slow:GetEffectName()
	return "particles/units/heroes/hero_brewmaster/brewmaster_thunder_clap_debuff.vpcf"
end

function modifier_xhs_magtheridon_slow:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_xhs_magtheridon_cast_lock:IsHidden() return true end
function modifier_xhs_magtheridon_cast_lock:IsPurgable() return false end

function modifier_xhs_magtheridon_cast_lock:CheckState()
	return {
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_ROOTED] = true,
	}
end
