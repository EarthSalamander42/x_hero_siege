require("boss_scripts/phase3_ai/core")
require("boss_scripts/phase3_ai/telegraphs")
require("boss_scripts/phase3_ai/spirit_master_abilities")

if XHSSpiritMasterEncounter == nil then
	XHSSpiritMasterEncounter = {}
end

modifier_xhs_spirit_master_phase_ai = modifier_xhs_spirit_master_phase_ai or class({})
modifier_xhs_spirit_master_phase_ai.XHS_LINK_CLIENT = true
modifier_xhs_spirit_master_split_hidden = modifier_xhs_spirit_master_split_hidden or class({})
modifier_xhs_spirit_master_split_hidden.XHS_LINK_CLIENT = true
modifier_xhs_tri_spirit_phase_ai = modifier_xhs_tri_spirit_phase_ai or class({})
modifier_xhs_tri_spirit_phase_ai.XHS_LINK_CLIENT = true
modifier_xhs_spirit_dormant = modifier_xhs_spirit_dormant or class({})
modifier_xhs_spirit_dormant.XHS_LINK_CLIENT = true
modifier_xhs_spirit_finale = modifier_xhs_spirit_finale or class({})
modifier_xhs_spirit_finale.XHS_LINK_CLIENT = true

LinkLuaModifier("modifier_xhs_spirit_master_phase_ai", "boss_scripts/phase3_ai/spirit_master.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_spirit_master_split_hidden", "boss_scripts/phase3_ai/spirit_master.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_tri_spirit_phase_ai", "boss_scripts/phase3_ai/spirit_master.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_spirit_dormant", "boss_scripts/phase3_ai/spirit_master.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_spirit_finale", "boss_scripts/phase3_ai/spirit_master.lua", LUA_MODIFIER_MOTION_NONE)

local MASTER_ABILITIES = {
	"xhs_spirit_master_palm_of_balance",
	"xhs_spirit_master_elemental_mandala",
	"xhs_spirit_master_convergence",
	"xhs_spirit_master_trinity_cycle",
}

local SPIRIT_ABILITIES = {
	storm = {
		"xhs_spirit_storm_arc_dash",
		"xhs_spirit_storm_static_orbs",
		"xhs_spirit_storm_chain_focus",
	},
	earth = {
		"xhs_spirit_earth_fault_line",
		"xhs_spirit_earth_stone_guard",
		"xhs_spirit_earth_resonant_pillar",
	},
	fire = {
		"xhs_spirit_fire_cinder_step",
		"xhs_spirit_fire_solar_flare",
		"xhs_spirit_fire_wildfire_ring",
	},
}

local SPIRIT_AMBIENTS = {
	storm = {
		ability = "holdout_blue_effect",
		modifier = "modifier_blue",
	},
	earth = {
		ability = "holdout_green_effect",
		modifier = "modifier_green",
	},
	fire = {
		ability = "holdout_red_effect",
		modifier = "modifier_red",
	},
}

local SPIRIT_DEFS = {
	{
		key = "storm",
		unit = "npc_dota_boss_spirit_master_storm",
		bar_id = "spirit_master_storm",
		boss_count = 1,
		name = "npc_dota_boss_spirit_master_storm",
		icon = "npc_dota_hero_storm_spirit",
		dark = "#053f66",
		light = "#48d9ff",
		offset = Vector(0, 520, 0),
	},
	{
		key = "earth",
		unit = "npc_dota_boss_spirit_master_earth",
		bar_id = "spirit_master_earth",
		boss_count = 2,
		name = "npc_dota_boss_spirit_master_earth",
		icon = "npc_dota_hero_earth_spirit",
		dark = "#1f4d20",
		light = "#79d67b",
		offset = Vector(-450, -260, 0),
	},
	{
		key = "fire",
		unit = "npc_dota_boss_spirit_master_fire",
		bar_id = "spirit_master_fire",
		boss_count = 3,
		name = "npc_dota_boss_spirit_master_fire",
		icon = "npc_dota_hero_ember_spirit",
		dark = "#5a1300",
		light = "#ff9a2f",
		offset = Vector(450, -260, 0),
	},
}

local THRESHOLDS = { 70, 40, 10 }
local SPIRIT_ARENA_LEASH_RADIUS = 1850
local SPIRIT_ARENA_SAFE_RADIUS = 1500
local SPIRIT_ARENA_LEASH_INTERVAL = 0.10
local SPIRIT_FINALE_END_DELAY = 10.0

local SPIRIT_ROUNDS = {
	[1] = { threshold = 70, armor = 200, attack_multiplier = 1.00, ability_count = 1 },
	[2] = { threshold = 40, armor = 250, attack_multiplier = 1.25, ability_count = 2 },
	[3] = { threshold = 10, armor = 300, attack_multiplier = 1.50, ability_count = 3 },
}

local SYNC_WINDOWS = {
	[1] = 20,
	[2] = 17,
	[3] = 14,
	[4] = 11,
	[5] = 8,
}

local function IsValidAlive(unit)
	return unit ~= nil and IsValidEntity(unit) and not unit:IsNull() and unit:IsAlive()
end

local function GetDifficulty()
	if XHSPhase3BossAI ~= nil then return XHSPhase3BossAI:GetDifficulty() end
	return math.max(1, math.min(5, GameRules:GetCustomGameDifficulty() or 1))
end

local function SetSpiritAmbientEnabled(spirit, enabled)
	if spirit == nil or not IsValidEntity(spirit) or spirit:IsNull() then return end
	local ambient = SPIRIT_AMBIENTS[spirit.xhs_spirit_key]
	if ambient == nil then return end

	local ability = spirit:FindAbilityByName(ambient.ability)
	if ability ~= nil then
		ability:SetActivated(enabled == true)
	end

	if enabled ~= true then
		spirit:RemoveModifierByName(ambient.modifier)
		return
	end

	if ability ~= nil and not spirit:HasModifier(ambient.modifier) then
		ability:ApplyDataDrivenModifier(spirit, spirit, ambient.modifier, {})
	end
end

local function GetArenaCenter(fallback)
	local point = Entities:FindByName(nil, "npc_dota_spawner_magtheridon_arena")
	if point ~= nil then return point:GetAbsOrigin() end
	point = Entities:FindByName(nil, "npc_dota_spawner_lich_king_bis")
	if point ~= nil then return point:GetAbsOrigin() end
	return fallback or Vector(0, 0, 0)
end

local function HideBossBarFor(boss, retireIdentity)
	if boss == nil or boss:IsNull() then return end
	CustomGameEventManager:Send_ServerToAllClients("hide_boss_hp", {
		boss_count = boss.boss_count or 1,
		boss_bar_id = GetBossBarId and GetBossBarId(boss) or nil,
		boss_bar_retire = retireIdentity == true and 1 or 0,
	})
end

local function HideSpiritBossBars()
	for _, def in pairs(SPIRIT_DEFS) do
		CustomGameEventManager:Send_ServerToAllClients("hide_boss_hp", {
			boss_count = def.boss_count,
		})
	end
end

local function SuppressAndHideSpiritBossBars(spirits)
	-- Stop the generic health poller before sending the hide events. Otherwise
	-- one last queued update can recreate a removed spirit in Panorama and take
	-- the slot that belongs to the next trio.
	for _, spirit in pairs(spirits or {}) do
		if spirit ~= nil and IsValidEntity(spirit) and not spirit:IsNull() then
			spirit.xhs_boss_bar_suppressed = true
			if XHSBossCastBar ~= nil then XHSBossCastBar:Hide(spirit) end
			HideBossBarFor(spirit, true)
		end
	end

	-- Finish with an authoritative slot cleanup after the identity-specific
	-- hides, so all three spirit slots are empty before the master returns.
	HideSpiritBossBars()
end

local function HideLegacyMasterBossBar()
	-- Generic registration used slot 1 before the encounter assigned slot 4.
	CustomGameEventManager:Send_ServerToAllClients("hide_boss_hp", {
		boss_count = 1,
	})
end

local function ApplyBossBarIdentity(boss, def)
	boss.boss_count = def.boss_count or 1
	-- The entity index is the authoritative identity. Each threshold creates a
	-- fresh trio, so delayed events from an older spirit cannot own the new bar.
	boss.xhs_boss_bar_id = tostring(boss:entindex())
	boss.xhs_boss_bar_name = def.name
	boss.xhs_boss_bar_icon = def.icon
	boss.xhs_boss_bar_colors = {
		dark_color = def.dark,
		light_color = def.light,
	}
end

local function ConfigureBossBar(boss, def)
	ApplyBossBarIdentity(boss, def)
	if XHSPhase3BossAI ~= nil then
		XHSPhase3BossAI:HideVanillaHealthBar(boss)
	end
	ShowBossBar(boss)
end

function XHSSpiritMaster_ConfigureSpiritBossBar(boss)
	if boss == nil or not IsValidEntity(boss) or boss:IsNull() then return false end
	local unitName = boss:GetUnitName()
	for _, def in pairs(SPIRIT_DEFS) do
		if def.unit == unitName or def.key == boss.xhs_spirit_key then
			ApplyBossBarIdentity(boss, def)
			return true
		end
	end

	return false
end

local function SetAbilityContext(unit, abilityName, context)
	local ability = unit and unit:FindAbilityByName(abilityName)
	if ability == nil then return nil end
	ability.xhs_spirit_context = context or {}
	return ability
end

local function CastAbility(unit, abilityName, context, position)
	local ability = SetAbilityContext(unit, abilityName, context)
	if ability == nil or not ability:IsCooldownReady() then return nil end
	if XHSPhase3BossAI ~= nil then
		XHSPhase3BossAI:ProtectCast(unit, ability, 0.2)
	end
	if position ~= nil then
		ExecuteOrderFromTable({
			UnitIndex = unit:entindex(),
			OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
			AbilityIndex = ability:entindex(),
			Position = position,
		})
	else
		ExecuteOrderFromTable({
			UnitIndex = unit:entindex(),
			OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
			AbilityIndex = ability:entindex(),
		})
	end
	return ability
end

local function GetPlayerId(hero)
	if hero == nil then return -1 end
	if hero.GetPlayerOwnerID ~= nil then return hero:GetPlayerOwnerID() end
	if hero.GetPlayerID ~= nil then return hero:GetPlayerID() end
	return -1
end

local function CountLivingHeroes(center)
	local heroes = XHSPhase3BossAI:GetLivingHeroes(center or Vector(0, 0, 0), SPIRIT_ARENA_LEASH_RADIUS, true)
	local count = 0
	for _, hero in pairs(heroes) do
		if IsValidAlive(hero) and not hero:IsInvulnerable() then
			count = count + 1
		end
	end
	return math.max(1, count)
end

local function PickHero(center, avoidLocks)
	local heroes = XHSPhase3BossAI:GetLivingHeroes(center, SPIRIT_ARENA_LEASH_RADIUS, true)
	local now = GameRules:GetGameTime()
	local best = nil
	local bestLock = nil
	for _, hero in pairs(heroes) do
		if IsValidAlive(hero) and not hero:IsInvulnerable() then
			local id = GetPlayerId(hero)
			local locked = XHSSpiritMasterEncounter.target_locks[id] or 0
			if avoidLocks ~= true or locked <= now then
				return hero
			end
			if best == nil or locked < bestLock then
				best = hero
				bestLock = locked
			end
		end
	end
	return best
end

local function GetActiveSpiritBossBarId(def)
	local encounter = XHSSpiritMasterEncounter
	local spirit = encounter ~= nil and encounter.spirits ~= nil and encounter.spirits[def.key] or nil
	if spirit ~= nil and IsValidEntity(spirit) and not spirit:IsNull() then
		return GetBossBarId and GetBossBarId(spirit) or spirit.xhs_boss_bar_id
	end
	return def.bar_id
end

local function SetMasterAbilitiesEnabled(master, enabled)
	if master == nil or not IsValidEntity(master) or master:IsNull() then return end
	for _, abilityName in ipairs(MASTER_ABILITIES) do
		local ability = master:FindAbilityByName(abilityName)
		if ability ~= nil then
			ability:SetActivated(enabled == true)
		end
	end
end

local function UpdateBossTimer(label, remaining, duration)
	for _, def in pairs(SPIRIT_DEFS) do
		CustomGameEventManager:Send_ServerToAllClients("xhs_boss_timer_update", {
			boss_count = def.boss_count,
			boss_bar_id = GetActiveSpiritBossBarId(def),
			label = label,
			remaining = math.max(0, remaining or 0),
			duration = math.max(1, duration or 1),
			style = "spirit_master",
		})
	end
end

local function HideBossTimer()
	for _, def in pairs(SPIRIT_DEFS) do
		CustomGameEventManager:Send_ServerToAllClients("xhs_boss_timer_hide", {
			boss_count = def.boss_count,
			boss_bar_id = GetActiveSpiritBossBarId(def),
		})
	end
end

local function UpdateDormantCounter()
	for _, def in pairs(SPIRIT_DEFS) do
		CustomGameEventManager:Send_ServerToAllClients("xhs_boss_counter_update", {
			boss_count = def.boss_count,
			boss_bar_id = GetActiveSpiritBossBarId(def),
			label = "Dormant Spirits",
			remaining = XHSSpiritMasterEncounter.dormant_count or 0,
			total = 3,
		})
	end
end

local function HideDormantCounter()
	for _, def in pairs(SPIRIT_DEFS) do
		CustomGameEventManager:Send_ServerToAllClients("xhs_boss_counter_hide", {
			boss_count = def.boss_count,
			boss_bar_id = GetActiveSpiritBossBarId(def),
		})
	end
end

function XHSSpiritMasterEncounter:Reset()
	local previousMaster = self.master
	HideBossTimer()
	HideDormantCounter()
	SuppressAndHideSpiritBossBars(self.spirits)
	if previousMaster ~= nil and IsValidEntity(previousMaster) and not previousMaster:IsNull() then
		previousMaster:RemoveModifierByName("modifier_xhs_spirit_master_split_hidden")
		SetMasterAbilitiesEnabled(previousMaster, true)
	end

	self.phase = "idle"
	self.master = nil
	self.arena_center = nil
	self.thresholds = THRESHOLDS
	self.consumed = {}
	self.spirits = {}
	self.spirit_defs = {}
	self.dormant = {}
	self.dormant_count = 0
	self.sync_deadline = nil
	self.target_locks = {}
	self.active_casts = {}
	self.next_cast = {}
	self.return_health = nil
	self.pending_threshold = nil
	self.transition_deadline = nil
	self.final_death_ready = false
	self.split_round = 0
	self.finale_started = false
	self.final_attacker = nil
	SPIRIT_MASTER_KILLED_BOSS_COUNT = 0
end

function XHSSpiritMasterEncounter:RegisterMaster(master)
	if not IsValidAlive(master) then return end
	if self.phase == nil then self:Reset() end
	self.master = master
	SetMasterAbilitiesEnabled(master, true)
	self.arena_center = GetArenaCenter(master:GetAbsOrigin())
	self.thresholds = THRESHOLDS
	-- Keep the master on its own fourth slot. Slots 1-3 belong to Storm,
	-- Earth and Fire while the master is hidden during the split.
	master.boss_count = 4
	master.xhs_boss_bar_id = "spirit_master"
	master.xhs_boss_bar_name = "npc_dota_boss_spirit_master"
	master.xhs_boss_bar_icon = "npc_dota_hero_brewmaster"
	master.xhs_boss_bar_colors = {
		dark_color = "#11263d",
		light_color = "#87d7ff",
	}
	if master.xhs_spirit_master_bar_initialized ~= true then
		HideLegacyMasterBossBar()
		CustomGameEventManager:Send_ServerToAllClients("hide_boss_hp", {
			boss_count = 4,
			boss_bar_id = "spirit_master",
		})
		master.xhs_spirit_master_bar_initialized = true
	end
	self:UpdateMasterBossBarMarkers()
	ShowBossBar(master)
end

function XHSSpiritMasterEncounter:UpdateMasterBossBarMarkers()
	local master = self.master
	if master == nil or not IsValidEntity(master) or master:IsNull() then return end

	master.xhs_boss_bar_markers = {}
	for _, threshold in ipairs(self.thresholds or {}) do
		table.insert(master.xhs_boss_bar_markers, {
			percent = threshold,
			label = "Trinity Cycle",
			tooltip = "Splits into Storm, Earth, and Fire. Defeat all three spirits together.",
			triggered = self.consumed[threshold] == true,
		})
	end
end

function XHSSpiritMasterEncounter:GetNextThreshold(master)
	if master == nil then return nil end
	local pct = (master:GetHealth() / math.max(1, master:GetMaxHealth())) * 100
	for _, threshold in ipairs(self.thresholds or {}) do
		if self.consumed[threshold] ~= true and pct <= threshold then
			return threshold
		end
	end
	return nil
end

function XHSSpiritMasterEncounter:HasPendingThresholds()
	for _, threshold in ipairs(self.thresholds or {}) do
		if self.consumed[threshold] ~= true then
			return true
		end
	end

	return false
end

function XHSSpiritMasterEncounter:IsFinalDeathReady()
	return self.finale_started == true
end

function XHSSpiritMasterEncounter:GetSplitRound()
	return math.max(1, math.min(3, self.split_round or 1))
end

function XHSSpiritMasterEncounter:GetRoundConfig()
	return SPIRIT_ROUNDS[self:GetSplitRound()] or SPIRIT_ROUNDS[1]
end

function XHSSpiritMasterEncounter:GetRoundForThreshold(threshold)
	for round, config in ipairs(SPIRIT_ROUNDS) do
		if config.threshold == threshold then
			return round
		end
	end
	return math.max(1, math.min(3, (self.split_round or 0) + 1))
end

function XHSSpiritMasterEncounter:ClampArenaPosition(position, radius)
	local center = self.arena_center
	if center == nil or position == nil then return position end

	local offset = position - center
	offset.z = 0
	local maxRadius = math.max(200, radius or SPIRIT_ARENA_SAFE_RADIUS)
	if offset:Length2D() <= maxRadius then
		return GetGroundPosition(position, nil)
	end

	return GetGroundPosition(center + offset:Normalized() * maxRadius, nil)
end

function XHSSpiritMasterEncounter:MoveSpiritToArenaPosition(spirit, position)
	if not IsValidAlive(spirit) or position == nil then return false end
	local destination = self:ClampArenaPosition(position, SPIRIT_ARENA_SAFE_RADIUS)
	if destination == nil then return false end

	FindClearSpaceForUnit(spirit, destination, true)

	-- FindClearSpace can resolve collision on the far side of an arena wall.
	-- Never accept such a result for a Spirit: fall back to the already clamped
	-- inner point and resolve nearby units from there.
	if self.arena_center ~= nil
		and (spirit:GetAbsOrigin() - self.arena_center):Length2D() > (SPIRIT_ARENA_SAFE_RADIUS + 128)
	then
		spirit:SetAbsOrigin(destination)
		ResolveNPCPositions(destination, 128)
	end

	return true
end

function XHSSpiritMasterEncounter:KeepSpiritInArena(spirit)
	if not IsValidAlive(spirit) or self.arena_center == nil then return false end
	local position = spirit:GetAbsOrigin()
	if (position - self.arena_center):Length2D() <= SPIRIT_ARENA_LEASH_RADIUS then return false end

	spirit:InterruptMotionControllers(true)
	spirit:SetForceAttackTarget(nil)
	spirit:Stop()
	self:MoveSpiritToArenaPosition(spirit, position)
	return true
end

function XHSSpiritMasterEncounter:ConfigureSpiritForRound(spirit)
	if not IsValidAlive(spirit) then return end
	local config = self:GetRoundConfig()
	local baseMin = spirit:GetBaseDamageMin()
	local baseMax = spirit:GetBaseDamageMax()
	spirit.xhs_spirit_base_damage_min = baseMin
	spirit.xhs_spirit_base_damage_max = baseMax
	spirit.xhs_spirit_round = self:GetSplitRound()
	spirit:SetPhysicalArmorBaseValue(config.armor)
	spirit:SetBaseDamageMin(math.floor(baseMin * config.attack_multiplier + 0.5))
	spirit:SetBaseDamageMax(math.floor(baseMax * config.attack_multiplier + 0.5))
end

function XHSSpiritMasterEncounter:TriggerSplit(master, threshold)
	if self.phase == "split" or self.phase == "transition" then return false end
	if threshold == nil then return false end
	self.phase = "transition"
	self.pending_threshold = threshold
	self.return_health = math.max(math.floor(master:GetMaxHealth() * math.max(0.03, (threshold - 1.5) / 100)), 1)
	master:Interrupt()
	local ability = CastAbility(master, "xhs_spirit_master_trinity_cycle", { threshold = threshold }, nil)
	if ability == nil then
		self:BeginSplit(master, threshold)
	else
		self.transition_deadline = GameRules:GetGameTime() + math.max(0.5, ability:GetCastPoint() + 0.75)
	end
	return true
end

function XHSSpiritMasterEncounter:ResolveStalledTransition(master)
	if self.phase ~= "transition" or master ~= self.master then return false end
	if (self.transition_deadline or 0) > GameRules:GetGameTime() then return false end

	local threshold = self.pending_threshold
	if threshold == nil then
		self.phase = "master"
		self.transition_deadline = nil
		return false
	end

	master:Interrupt()
	self:BeginSplit(master, threshold)
	return true
end

function XHSSpiritMasterEncounter:CancelPendingSplit(master, threshold)
	if self.phase ~= "transition" then return end
	if master ~= self.master then return end
	if threshold ~= nil and self.pending_threshold ~= threshold then return end

	self.pending_threshold = nil
	self.transition_deadline = nil
	self.phase = "master"
end

function XHSSpiritMasterEncounter:BeginSplit(master, threshold)
	if not IsValidAlive(master) then return end
	threshold = threshold or self.pending_threshold
	self.split_round = self:GetRoundForThreshold(threshold)
	if threshold ~= nil then
		self.consumed[threshold] = true
	end
	self.pending_threshold = nil
	self.transition_deadline = nil
	self.final_death_ready = self:HasPendingThresholds() ~= true
	self:UpdateMasterBossBarMarkers()
	if UpdateBossBar ~= nil then
		UpdateBossBar(master)
	end
	self.phase = "split"
	self.master = master
	self.arena_center = GetArenaCenter(master:GetAbsOrigin())
	self.spirits = {}
	self.spirit_defs = {}
	self.dormant = {}
	self.dormant_count = 0
	self.sync_deadline = nil
	self.active_casts = {}
	self.next_cast = {}

	master.xhs_boss_bar_suppressed = true
	HideBossBarFor(master)
	HideLegacyMasterBossBar()
	HideSpiritBossBars()
	master:Interrupt()
	master:SetForceAttackTarget(nil)
	SetMasterAbilitiesEnabled(master, false)
	master:AddNoDraw()
	master:AddNewModifier(master, nil, "modifier_xhs_spirit_master_split_hidden", {})
	master:AddNewModifier(master, nil, "modifier_invulnerable", {})
	master:AddNewModifier(master, nil, "modifier_stunned", {})
	master:Stop()

	for _, def in pairs(SPIRIT_DEFS) do
		local spirit = CreateUnitByName(def.unit, self.arena_center + def.offset, true, nil, nil, master:GetTeamNumber())
		spirit.zone = "xhs_holdout"
		spirit.xhs_spirit_key = def.key
		spirit.xhs_spirit_master = master
		spirit:SetAngles(0, 270, 0)
		self:ConfigureSpiritForRound(spirit)
		if ApplyLatePhase3BossDefenseScaling ~= nil then
			ApplyLatePhase3BossDefenseScaling(spirit)
		end
		ConfigureBossBar(spirit, def)
		if XHSPhase3BossAI ~= nil then
			XHSPhase3BossAI:SetAbilityLevels(spirit, SPIRIT_ABILITIES[def.key])
		end
		SetSpiritAmbientEnabled(spirit, true)
		spirit:AddNewModifier(spirit, nil, "modifier_xhs_tri_spirit_phase_ai", {})
		if RegisterXHSDevSpawn ~= nil then
			RegisterXHSDevSpawn(spirit)
		end
		self.spirits[def.key] = spirit
		self.spirit_defs[def.key] = def
	end

	UpdateDormantCounter()
end

function XHSSpiritMasterEncounter:HandleSpiritLethal(spirit, attacker)
	if self.phase ~= "split" then return false end
	if not IsValidAlive(spirit) then return false end
	local key = spirit.xhs_spirit_key
	if key == nil or self.dormant[key] == true then return true end

	self.dormant[key] = true
	self.dormant_count = (self.dormant_count or 0) + 1
	spirit:SetHealth(1)
	spirit:RemoveModifierByName("modifier_xhs_boss_cast_protection")
	spirit:Interrupt()
	spirit:InterruptMotionControllers(true)
	spirit:SetForceAttackTarget(nil)
	SetSpiritAmbientEnabled(spirit, false)
	spirit:AddNewModifier(spirit, nil, "modifier_xhs_spirit_dormant", {})
	spirit:Stop()
	if XHSBossCastBar ~= nil then XHSBossCastBar:Hide(spirit) end

	local trinityCycle = self.master ~= nil and self.master:FindAbilityByName("xhs_spirit_master_trinity_cycle") or nil
	local window = trinityCycle ~= nil and trinityCycle:GetSpecialValueFor("sync_window") or (SYNC_WINDOWS[GetDifficulty()] or 20)
	self.sync_deadline = GameRules:GetGameTime() + window
	UpdateDormantCounter()
	UpdateBossTimer("Spirit Sync", window, window)

	if self.dormant_count >= 3 then
		if self:GetSplitRound() >= 3 then
			self:CompleteFinalSplit(attacker)
		else
			Timers:CreateTimer(0.8, function()
				self:CompleteSplit()
			end)
		end
	else
		self:StartSyncTimer(window)
	end

	return true
end

function XHSSpiritMasterEncounter:StartSyncTimer(duration)
	if self.sync_timer_active == true then return end
	self.sync_timer_active = true
	Timers:CreateTimer(0.25, function()
		if self.phase ~= "split" or self.sync_deadline == nil or self.dormant_count >= 3 then
			self.sync_timer_active = nil
			return nil
		end
		local remaining = self.sync_deadline - GameRules:GetGameTime()
		if remaining <= 0 then
			self.sync_timer_active = nil
			self:FailSync()
			return nil
		end
		UpdateBossTimer("Spirit Sync", math.ceil(remaining), duration)
		return 0.25
	end)
end

function XHSSpiritMasterEncounter:FailSync()
	local maxHealthPct = 0.25
	for key, spirit in pairs(self.spirits or {}) do
		if IsValidAlive(spirit) then
			if self.dormant[key] == true then
				spirit:RemoveModifierByName("modifier_xhs_spirit_dormant")
				spirit:SetHealth(math.max(1, math.floor(spirit:GetMaxHealth() * maxHealthPct)))
				SetSpiritAmbientEnabled(spirit, true)
			else
				local mod = spirit:AddNewModifier(spirit, nil, "modifier_xhs_spirit_discordant_echo", { duration = 20 })
				if mod ~= nil then mod:SetStackCount((mod:GetStackCount() or 0) + 1) end
			end
		end
	end
	self.dormant = {}
	self.dormant_count = 0
	self.sync_deadline = nil
	HideBossTimer()
	UpdateDormantCounter()
end

function XHSSpiritMasterEncounter:CompleteSplit()
	if self.phase ~= "split" then return end
	if self:GetSplitRound() >= 3 then
		self:CompleteFinalSplit(self.final_attacker)
		return
	end
	self.phase = "returning"
	HideBossTimer()
	HideDormantCounter()
	SuppressAndHideSpiritBossBars(self.spirits)

	for _, spirit in pairs(self.spirits or {}) do
		if spirit ~= nil and IsValidEntity(spirit) and not spirit:IsNull() then
			UTIL_Remove(spirit)
		end
	end

	self.spirits = {}
	self.dormant = {}
	self.dormant_count = 0
	self.sync_deadline = nil

	local master = self.master
	if IsValidAlive(master) then
		master:RemoveModifierByName("modifier_xhs_spirit_master_split_hidden")
		master:RemoveNoDraw()
		master:RemoveModifierByName("modifier_stunned")
		master:RemoveModifierByName("modifier_invulnerable")
		SetMasterAbilitiesEnabled(master, true)
		self.final_death_ready = self:HasPendingThresholds() ~= true
		master:SetHealth(math.min(master:GetMaxHealth(), math.max(1, self.return_health or master:GetHealth())))
		master.xhs_boss_bar_suppressed = nil
		ShowBossBar(master)
		CastAbility(master, "xhs_spirit_master_convergence", {}, nil)
	end

	Timers:CreateTimer(1.5, function()
		if self.phase == "returning" then
			self.phase = "master"
		end
	end)
end

function XHSSpiritMasterEncounter:CompleteFinalSplit(attacker)
	if self.phase ~= "split" or self.finale_started == true then return end
	self.finale_started = true
	self.final_attacker = attacker
	self.phase = "finale"
	self.sync_deadline = nil
	self.sync_timer_active = nil
	self.active_casts = {}
	self.next_cast = {}
	HideBossTimer()
	HideDormantCounter()
	HideLegacyMasterBossBar()
	SuppressAndHideSpiritBossBars(self.spirits)

	local master = self.master
	if IsValidAlive(master) then
		master:SetHealth(1)
		SetMasterAbilitiesEnabled(master, false)
		master:AddNewModifier(master, nil, "modifier_xhs_spirit_master_split_hidden", {})
		master.xhs_boss_bar_suppressed = true
		master:AddNoDraw()
		if not master:HasModifier("modifier_invulnerable") then
			master:AddNewModifier(master, nil, "modifier_invulnerable", {})
		end
		if not master:HasModifier("modifier_stunned") then
			master:AddNewModifier(master, nil, "modifier_stunned", {})
		end
		master:Stop()
		HideBossBarFor(master)
	end

	local deathSounds = {
		storm = "Hero_StormSpirit.Death",
		earth = "Hero_EarthSpirit.Death",
		fire = "Hero_EmberSpirit.Death",
	}
	local deathParticles = {
		storm = "particles/units/heroes/hero_stormspirit/stormspirit_overload_discharge.vpcf",
		earth = "particles/units/heroes/hero_earth_spirit/espirit_bouldersmash_caster.vpcf",
		fire = "particles/units/heroes/hero_ember_spirit/ember_spirit_flameguard.vpcf",
	}

	for index, def in ipairs(SPIRIT_DEFS) do
		local spirit = self.spirits[def.key]
		local spiritKey = def.key
		if spirit ~= nil and IsValidEntity(spirit) and not spirit:IsNull() then
			spirit:RemoveModifierByName("modifier_xhs_boss_cast_protection")
			spirit:RemoveModifierByName("modifier_xhs_tri_spirit_phase_ai")
			spirit:Interrupt()
			spirit:InterruptMotionControllers(true)
			spirit:SetForceAttackTarget(nil)
			spirit:Stop()
			spirit:RemoveModifierByName("modifier_xhs_spirit_dormant")
			spirit:AddNewModifier(spirit, nil, "modifier_xhs_spirit_finale", {})
			Timers:CreateTimer((index - 1) * 0.35, function()
				if spirit == nil or not IsValidEntity(spirit) or spirit:IsNull() then return nil end
				spirit:FadeGesture(ACT_DOTA_DISABLED)
				StartAnimation(spirit, { duration = 2.2, activity = ACT_DOTA_DIE, rate = 0.85 })
				spirit:EmitSound(deathSounds[spiritKey])
				local particle = ParticleManager:CreateParticle(deathParticles[spiritKey], PATTACH_ABSORIGIN_FOLLOW, spirit)
				ParticleManager:SetParticleControlEnt(particle, 0, spirit, PATTACH_ABSORIGIN_FOLLOW, nil, spirit:GetAbsOrigin(), true)
				ParticleManager:ReleaseParticleIndex(particle)
				return nil
			end)
		end
	end

	Timers:CreateTimer(1.0, function()
		if self.phase == "finale" then
			EmitGlobalSound("Loot_Drop_Stinger_Arcana")
		end
	end)

	Timers:CreateTimer(2.5, function()
		if self.phase ~= "finale" then return nil end
		for _, spirit in pairs(self.spirits or {}) do
			if spirit ~= nil and IsValidEntity(spirit) and not spirit:IsNull() then
				spirit:AddNoDraw()
				UTIL_Remove(spirit)
			end
		end
		self.spirits = {}
		self.dormant = {}
		self.dormant_count = 0
		return nil
	end)

	Timers:CreateTimer(SPIRIT_FINALE_END_DELAY, function()
		if self.phase ~= "finale" then return nil end
		local bDevSandbox = XHSDevTools ~= nil and XHSDevTools:IsSandboxActive()
		if bDevSandbox == true then
			Notifications:TopToAll({ text = "Dev sandbox: Spirit Master cleared. EndGame blocked.", duration = 6.0 })
			if XHSDevTools ~= nil then XHSDevTools:PushState() end
		else
			EndGame()
		end
		return nil
	end)
end

function XHSSpiritMasterEncounter:GetMaxConcurrentCasts()
	local heroes = CountLivingHeroes(self.arena_center)
	if heroes <= 2 then return 1 end
	return math.min(3, heroes)
end

function XHSSpiritMasterEncounter:CanCast(spirit, targetHero)
	if self.phase ~= "split" or not IsValidAlive(spirit) or spirit:HasModifier("modifier_xhs_spirit_dormant") then return false end
	local now = GameRules:GetGameTime()
	if (self.next_cast[spirit:entindex()] or 0) > now then return false end

	local active = 0
	for id, expiry in pairs(self.active_casts or {}) do
		if expiry > now then active = active + 1 else self.active_casts[id] = nil end
	end
	if active >= self:GetMaxConcurrentCasts() then return false end

	if targetHero ~= nil then
		local playerId = GetPlayerId(targetHero)
		if (self.target_locks[playerId] or 0) > now then return false end
	end

	return true
end

function XHSSpiritMasterEncounter:ReserveCast(spirit, ability, targetHero, recovery)
	local now = GameRules:GetGameTime()
	local castPoint = ability and ability.GetCastPoint and ability:GetCastPoint() or 1.0
	self.active_casts[spirit:entindex()] = now + castPoint + 0.4
	self.next_cast[spirit:entindex()] = now + castPoint + (recovery or 2.0)
	if targetHero ~= nil then
		self.target_locks[GetPlayerId(targetHero)] = now + castPoint + 4.0
	end
end

function XHSSpiritMasterEncounter:PickTarget()
	return PickHero(self.arena_center, true)
end

function XHSSpiritMasterEncounter:PickArenaPoint()
	local hero = self:PickTarget()
	if IsValidAlive(hero) then return self:ClampArenaPosition(hero:GetAbsOrigin()), hero end
	return self.arena_center, nil
end

function XHSSpiritMaster_AttachPhase3AI(master)
	if master == nil or master:IsNull() or master:GetUnitName() ~= "npc_dota_boss_spirit_master" then return end
	if XHSSpiritMasterEncounter.phase == nil then XHSSpiritMasterEncounter:Reset() end
	XHSSpiritMasterEncounter:RegisterMaster(master)
	if XHSPhase3BossAI ~= nil then
		XHSPhase3BossAI:HideVanillaHealthBar(master)
		XHSPhase3BossAI:SetAbilityLevels(master, MASTER_ABILITIES)
	end
	for _, abilityName in ipairs({
		"xhs_spirit_master_convergence",
	}) do
		local ability = master:FindAbilityByName(abilityName)
		if ability ~= nil then
			ability:SetHidden(true)
		end
	end
	if not master:HasModifier("modifier_xhs_spirit_master_phase_ai") then
		master:AddNewModifier(master, nil, "modifier_xhs_spirit_master_phase_ai", {})
	end
end

function modifier_xhs_spirit_master_phase_ai:IsHidden() return true end
function modifier_xhs_spirit_master_phase_ai:IsPurgable() return false end
function modifier_xhs_spirit_master_phase_ai:DeclareFunctions()
	return { MODIFIER_EVENT_ON_TAKEDAMAGE }
end

function modifier_xhs_spirit_master_phase_ai:OnCreated()
	if not IsServer() then return end
	self.boss = self:GetParent()
	self.next_action = GameRules:GetGameTime() + 3.0
	XHSSpiritMasterEncounter.phase = "master"
	XHSSpiritMasterEncounter:RegisterMaster(self.boss)
	self:StartIntervalThink(0.25)
end

function modifier_xhs_spirit_master_phase_ai:OnTakeDamage(event)
	if not IsServer() then return end
	if event.unit ~= self.boss then return end
	if XHSSpiritMasterEncounter.phase ~= "master" then return end
	local threshold = XHSSpiritMasterEncounter:GetNextThreshold(self.boss)
	if threshold ~= nil then
		XHSSpiritMasterEncounter:TriggerSplit(self.boss, threshold)
	end
end

function modifier_xhs_spirit_master_phase_ai:OnIntervalThink()
	if not IsServer() then return end
	if not IsValidAlive(self.boss) then return end
	if XHSSpiritMasterEncounter.phase == "transition" then
		XHSSpiritMasterEncounter:ResolveStalledTransition(self.boss)
		return
	end
	if XHSSpiritMasterEncounter.phase ~= "master" then return end
	local threshold = XHSSpiritMasterEncounter:GetNextThreshold(self.boss)
	if threshold ~= nil then
		XHSSpiritMasterEncounter:TriggerSplit(self.boss, threshold)
		return
	end
	if XHSPhase3BossAI:IsCastBlocked(self.boss) then return end
	local now = GameRules:GetGameTime()
	if now < (self.next_action or 0) then return end

	local target = PickHero(XHSSpiritMasterEncounter.arena_center, false)
	if not IsValidAlive(target) then return end
	local useMandala = RandomInt(1, 100) <= 42
	if useMandala then
		local ability = CastAbility(self.boss, "xhs_spirit_master_elemental_mandala", { position = XHSSpiritMasterEncounter.arena_center }, XHSSpiritMasterEncounter.arena_center)
		if ability ~= nil then self.next_action = now + ability:GetCastPoint() + 5.0 end
	else
		local direction = target:GetAbsOrigin() - self.boss:GetAbsOrigin()
		local ability = CastAbility(self.boss, "xhs_spirit_master_palm_of_balance", { direction = direction }, self.boss:GetAbsOrigin() + direction)
		if ability ~= nil then self.next_action = now + ability:GetCastPoint() + 3.2 end
	end
end

function modifier_xhs_spirit_master_split_hidden:IsHidden() return true end
function modifier_xhs_spirit_master_split_hidden:IsPurgable() return false end
function modifier_xhs_spirit_master_split_hidden:RemoveOnDeath() return false end

function modifier_xhs_spirit_master_split_hidden:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_DISABLE_HEALING,
	}
end

function modifier_xhs_spirit_master_split_hidden:GetDisableHealing()
	return 1
end

function modifier_xhs_spirit_master_split_hidden:CheckState()
	return {
		[MODIFIER_STATE_OUT_OF_GAME] = true,
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_ROOTED] = true,
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_SILENCED] = true,
		[MODIFIER_STATE_MUTED] = true,
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
	}
end

function modifier_xhs_spirit_master_split_hidden:OnCreated()
	if not IsServer() then return end
	self:FreezeResources()
	self:StartIntervalThink(0.1)
end

function modifier_xhs_spirit_master_split_hidden:OnRefresh()
	if not IsServer() then return end
	self:FreezeResources()
end

function modifier_xhs_spirit_master_split_hidden:FreezeResources()
	local parent = self:GetParent()
	if parent == nil or parent:IsNull() then return end
	self.locked_health = math.max(1, parent:GetHealth())
	self.locked_mana = math.max(0, parent:GetMana())
	parent:Interrupt()
	parent:SetForceAttackTarget(nil)
	parent:Stop()
end

function modifier_xhs_spirit_master_split_hidden:OnIntervalThink()
	if not IsServer() then return end
	local parent = self:GetParent()
	if parent == nil or parent:IsNull() then return end
	parent:SetHealth(math.min(parent:GetMaxHealth(), math.max(1, self.locked_health or parent:GetHealth())))
	parent:SetMana(math.min(parent:GetMaxMana(), math.max(0, self.locked_mana or parent:GetMana())))
	parent:Interrupt()
	parent:SetForceAttackTarget(nil)
	parent:Stop()
end

function modifier_xhs_tri_spirit_phase_ai:IsHidden() return true end
function modifier_xhs_tri_spirit_phase_ai:IsPurgable() return false end

function modifier_xhs_tri_spirit_phase_ai:OnCreated()
	if not IsServer() then return end
	self.boss = self:GetParent()
	self.key = self.boss.xhs_spirit_key
	self.next_action = GameRules:GetGameTime() + RandomFloat(1.0, 2.0)
	self:StartIntervalThink(SPIRIT_ARENA_LEASH_INTERVAL)
end

function modifier_xhs_tri_spirit_phase_ai:OnIntervalThink()
	if not IsServer() then return end
	if XHSSpiritMasterEncounter.phase ~= "split" then return end
	if not IsValidAlive(self.boss) then return end
	if XHSSpiritMasterEncounter:KeepSpiritInArena(self.boss) then
		self.next_action = GameRules:GetGameTime() + 0.5
		return
	end
	if self.boss:HasModifier("modifier_xhs_spirit_dormant") then return end
	if XHSPhase3BossAI:IsCastBlocked(self.boss) then return end
	local now = GameRules:GetGameTime()
	if now < (self.next_action or 0) then return end

	local point, target = XHSSpiritMasterEncounter:PickArenaPoint()
	if not XHSSpiritMasterEncounter:CanCast(self.boss, target) then
		self.next_action = now + 0.5
		return
	end

	local abilityName = self:PickAbilityName()
	local ability = CastAbility(self.boss, abilityName, { position = point }, point)
	if ability ~= nil then
		XHSSpiritMasterEncounter:ReserveCast(self.boss, ability, target, RandomFloat(2.6, 4.0))
		self.next_action = now + ability:GetCastPoint() + RandomFloat(2.6, 4.0)
	else
		self.next_action = now + 1.0
	end
end

function modifier_xhs_tri_spirit_phase_ai:PickAbilityName()
	local abilities = SPIRIT_ABILITIES[self.key] or SPIRIT_ABILITIES.fire
	local config = XHSSpiritMasterEncounter:GetRoundConfig()
	local count = math.max(1, math.min(#abilities, config.ability_count or 1))
	return abilities[RandomInt(1, count)]
end

function modifier_xhs_spirit_dormant:IsHidden() return false end
function modifier_xhs_spirit_dormant:IsPurgable() return false end
function modifier_xhs_spirit_dormant:GetTexture() return "brewmaster_primal_split" end

function modifier_xhs_spirit_dormant:OnCreated()
	if not IsServer() then return end
	local parent = self:GetParent()
	parent:Stop()
	parent:StartGesture(ACT_DOTA_DISABLED)
	parent:SetRenderColor(90, 120, 140)
	self.dormant_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_brewmaster/brewmaster_primal_split.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
	ParticleManager:SetParticleControlEnt(self.dormant_pfx, 0, parent, PATTACH_ABSORIGIN_FOLLOW, nil, parent:GetAbsOrigin(), true)
end

function modifier_xhs_spirit_dormant:OnDestroy()
	if not IsServer() then return end
	local parent = self:GetParent()
	if parent ~= nil and not parent:IsNull() then
		parent:FadeGesture(ACT_DOTA_DISABLED)
		parent:SetRenderColor(255, 255, 255)
	end
	if self.dormant_pfx ~= nil then
		ParticleManager:DestroyParticle(self.dormant_pfx, false)
		ParticleManager:ReleaseParticleIndex(self.dormant_pfx)
		self.dormant_pfx = nil
	end
end

function modifier_xhs_spirit_dormant:CheckState()
	return {
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_SILENCED] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
	}
end

function modifier_xhs_spirit_finale:IsHidden() return true end
function modifier_xhs_spirit_finale:IsPurgable() return false end
function modifier_xhs_spirit_finale:RemoveOnDeath() return true end
function modifier_xhs_spirit_finale:CheckState()
	return {
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
		[MODIFIER_STATE_ROOTED] = true,
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_SILENCED] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
	}
end
