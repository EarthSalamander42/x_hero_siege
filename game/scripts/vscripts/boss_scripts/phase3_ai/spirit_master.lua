require("boss_scripts/phase3_ai/core")
require("boss_scripts/phase3_ai/telegraphs")
require("boss_scripts/phase3_ai/spirit_master_abilities")

if XHSSpiritMasterEncounter == nil then
	XHSSpiritMasterEncounter = {}
end

modifier_xhs_spirit_master_phase_ai = modifier_xhs_spirit_master_phase_ai or class({})
modifier_xhs_spirit_master_phase_ai.XHS_LINK_CLIENT = true
modifier_xhs_tri_spirit_phase_ai = modifier_xhs_tri_spirit_phase_ai or class({})
modifier_xhs_tri_spirit_phase_ai.XHS_LINK_CLIENT = true
modifier_xhs_spirit_dormant = modifier_xhs_spirit_dormant or class({})
modifier_xhs_spirit_dormant.XHS_LINK_CLIENT = true

LinkLuaModifier("modifier_xhs_spirit_master_phase_ai", "boss_scripts/phase3_ai/spirit_master.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_tri_spirit_phase_ai", "boss_scripts/phase3_ai/spirit_master.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_spirit_dormant", "boss_scripts/phase3_ai/spirit_master.lua", LUA_MODIFIER_MOTION_NONE)

local MASTER_ABILITIES = {
	"xhs_spirit_master_palm_of_balance",
	"xhs_spirit_master_elemental_mandala",
	"xhs_spirit_master_spirit_call",
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

local SPIRIT_ROUNDS = {
	[1] = { threshold = 70, attack_multiplier = 1.00, ability_count = 1 },
	[2] = { threshold = 40, attack_multiplier = 1.25, ability_count = 2 },
	[3] = { threshold = 10, attack_multiplier = 1.50, ability_count = 3 },
}

local SYNC_WINDOWS = {
	[1] = 24,
	[2] = 22,
	[3] = 20,
	[4] = 18,
	[5] = 16,
}

local function IsValidAlive(unit)
	return unit ~= nil and IsValidEntity(unit) and not unit:IsNull() and unit:IsAlive()
end

local function GetDifficulty()
	if XHSPhase3BossAI ~= nil then return XHSPhase3BossAI:GetDifficulty() end
	return math.max(1, math.min(5, GameRules:GetCustomGameDifficulty() or 1))
end

local function GetArenaCenter(fallback)
	local point = Entities:FindByName(nil, "npc_dota_spawner_magtheridon_arena")
	if point ~= nil then return point:GetAbsOrigin() end
	point = Entities:FindByName(nil, "npc_dota_spawner_lich_king_bis")
	if point ~= nil then return point:GetAbsOrigin() end
	return fallback or Vector(0, 0, 0)
end

local function HideBossBarFor(boss)
	if boss == nil or boss:IsNull() then return end
	CustomGameEventManager:Send_ServerToAllClients("hide_boss_hp", {
		boss_count = boss.boss_count or 1,
		boss_bar_id = GetBossBarId and GetBossBarId(boss) or nil,
	})
end

local function HideSpiritBossBars()
	for _, def in pairs(SPIRIT_DEFS) do
		CustomGameEventManager:Send_ServerToAllClients("hide_boss_hp", {
			boss_count = def.boss_count,
			boss_bar_id = def.bar_id,
		})
	end
end

local function HideLegacyMasterBossBar()
	-- Generic registration used slot 1 before the encounter assigned slot 4.
	CustomGameEventManager:Send_ServerToAllClients("hide_boss_hp", {
		boss_count = 1,
	})
end

local function ApplyBossBarIdentity(boss, def)
	boss.boss_count = def.boss_count or 1
	boss.xhs_boss_bar_id = def.bar_id
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
	local heroes = XHSPhase3BossAI:GetLivingHeroes(center or Vector(0, 0, 0), 2600, true)
	local count = 0
	for _, hero in pairs(heroes) do
		if IsValidAlive(hero) and not hero:IsInvulnerable() then
			count = count + 1
		end
	end
	return math.max(1, count)
end

local function PickHero(center, avoidLocks)
	local heroes = XHSPhase3BossAI:GetLivingHeroes(center, 2600, true)
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

local function UpdateBossTimer(label, remaining, duration)
	for _, def in pairs(SPIRIT_DEFS) do
		CustomGameEventManager:Send_ServerToAllClients("xhs_boss_timer_update", {
			boss_count = def.boss_count,
			boss_bar_id = def.bar_id,
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
			boss_bar_id = def.bar_id,
		})
	end
end

local function UpdateDormantCounter()
	for _, def in pairs(SPIRIT_DEFS) do
		CustomGameEventManager:Send_ServerToAllClients("xhs_boss_counter_update", {
			boss_count = def.boss_count,
			boss_bar_id = def.bar_id,
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
			boss_bar_id = def.bar_id,
		})
	end
end

function XHSSpiritMasterEncounter:Reset()
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
	self.final_death_ready = false
	self.split_round = 0
	self.finale_started = false
	self.final_attacker = nil
	SPIRIT_MASTER_KILLED_BOSS_COUNT = 0
	HideBossTimer()
	HideDormantCounter()
	HideSpiritBossBars()
end

function XHSSpiritMasterEncounter:RegisterMaster(master)
	if not IsValidAlive(master) then return end
	if self.phase == nil then self:Reset() end
	self.master = master
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
			label = "Spirit Call",
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

function XHSSpiritMasterEncounter:ConfigureSpiritForRound(spirit)
	if not IsValidAlive(spirit) then return end
	local config = self:GetRoundConfig()
	local baseMin = spirit:GetBaseDamageMin()
	local baseMax = spirit:GetBaseDamageMax()
	spirit.xhs_spirit_base_damage_min = baseMin
	spirit.xhs_spirit_base_damage_max = baseMax
	spirit.xhs_spirit_round = self:GetSplitRound()
	spirit:SetBaseDamageMin(math.floor(baseMin * config.attack_multiplier + 0.5))
	spirit:SetBaseDamageMax(math.floor(baseMax * config.attack_multiplier + 0.5))
end

function XHSSpiritMasterEncounter:TriggerSplit(master, threshold)
	if self.phase == "split" or self.phase == "transition" then return false end
	if threshold == nil then return false end
	self.phase = "transition"
	self.pending_threshold = threshold
	self.return_health = math.max(math.floor(master:GetMaxHealth() * math.max(0.03, (threshold - 1.5) / 100)), 1)
	local ability = CastAbility(master, "xhs_spirit_master_spirit_call", { threshold = threshold }, nil)
	if ability == nil then
		self:BeginSplit(master, threshold)
	end
	return true
end

function XHSSpiritMasterEncounter:CancelPendingSplit(master, threshold)
	if self.phase ~= "transition" then return end
	if master ~= self.master then return end
	if threshold ~= nil and self.pending_threshold ~= threshold then return end

	self.pending_threshold = nil
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
	self.final_death_ready = self:HasPendingThresholds() ~= true
	self:UpdateMasterBossBarMarkers()
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
	master:AddNoDraw()
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
		ConfigureBossBar(spirit, def)
		if XHSPhase3BossAI ~= nil then
			XHSPhase3BossAI:SetAbilityLevels(spirit, SPIRIT_ABILITIES[def.key])
		end
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
	spirit:AddNewModifier(spirit, nil, "modifier_xhs_spirit_dormant", {})
	spirit:Stop()
	if XHSBossCastBar ~= nil then XHSBossCastBar:Hide(spirit) end

	local window = SYNC_WINDOWS[GetDifficulty()] or 20
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

	for _, spirit in pairs(self.spirits or {}) do
		if spirit ~= nil and IsValidEntity(spirit) and not spirit:IsNull() then
			if XHSBossCastBar ~= nil then XHSBossCastBar:Hide(spirit) end
			HideBossBarFor(spirit)
			UTIL_Remove(spirit)
		end
	end

	self.spirits = {}
	self.dormant = {}
	self.dormant_count = 0
	self.sync_deadline = nil

	local master = self.master
	if IsValidAlive(master) then
		master:RemoveNoDraw()
		master:RemoveModifierByName("modifier_stunned")
		master:RemoveModifierByName("modifier_invulnerable")
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
	HideSpiritBossBars()

	local master = self.master
	if IsValidAlive(master) then
		master:SetHealth(1)
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
			if XHSBossCastBar ~= nil then XHSBossCastBar:Hide(spirit) end
			HideBossBarFor(spirit)
			spirit:Stop()
			spirit:RemoveModifierByName("modifier_xhs_spirit_dormant")
			spirit:AddNewModifier(spirit, nil, "modifier_invulnerable", {})
			spirit:AddNewModifier(spirit, nil, "modifier_stunned", {})
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

	Timers:CreateTimer(5.0, function()
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
	if IsValidAlive(hero) then return hero:GetAbsOrigin(), hero end
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
	if XHSSpiritMasterEncounter.phase ~= "master" then return end
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

function modifier_xhs_tri_spirit_phase_ai:IsHidden() return true end
function modifier_xhs_tri_spirit_phase_ai:IsPurgable() return false end

function modifier_xhs_tri_spirit_phase_ai:OnCreated()
	if not IsServer() then return end
	self.boss = self:GetParent()
	self.key = self.boss.xhs_spirit_key
	self.next_action = GameRules:GetGameTime() + RandomFloat(1.0, 2.0)
	self:StartIntervalThink(0.35)
end

function modifier_xhs_tri_spirit_phase_ai:OnIntervalThink()
	if not IsServer() then return end
	if XHSSpiritMasterEncounter.phase ~= "split" then return end
	if not IsValidAlive(self.boss) or self.boss:HasModifier("modifier_xhs_spirit_dormant") then return end
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
