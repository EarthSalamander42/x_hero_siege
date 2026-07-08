local function FormatPhase2CreepTimer(seconds)
	seconds = math.max(0, math.floor(seconds or 0))
	return tostring(math.floor(seconds / 60)) .. ":" .. string.format("%02d", seconds % 60)
end

local function ActivatePhase2CreepTimer()
	if XHSSetGlobalObjectiveState == nil or CustomTimers == nil then return end

	local remaining = math.max(0, (CustomTimers.current_time and CustomTimers.current_time["special_event"] or XHS_SPECIAL_EVENT_INTERVAL) - 1)
	XHSSetGlobalObjectiveState("phase2_creeps", "Active", "Phase 2 creeps: " .. FormatPhase2CreepTimer(remaining), remaining)
end

function StartPhase2()
	CustomTimers:IncrementGamePhase() -- Phase 1 to Phase 2
	CustomTimers.timers_paused = 0
	ActivatePhase2CreepTimer()

	local DoorObs = Entities:FindAllByName("obstruction_phase2_1")

	for _, obs in pairs(DoorObs) do
		obs:SetEnabled(false, true)
	end

	DoEntFire("door_phase2_left", "SetAnimation", "gate_entrance002_open", 0, nil, nil)
	Phase2CreepsLeft()

	if PlayerResource:GetPlayerCount() > 1 then
		local DoorObs = Entities:FindAllByName("obstruction_phase2_2")

		for _, obs in pairs(DoorObs) do
			obs:SetEnabled(false, true)
		end

		DoEntFire("door_phase2_right", "SetAnimation", "gate_entrance002_open", 0, nil, nil)
		Phase2CreepsRight()
	end

	for c = 1, 8 do
		CREEP_LANES[c][1] = 0
		CREEP_LANES[c][3] = 0
	end
end

function Phase2CreepsLeft()
	local EntIceTower = Entities:FindByName(nil, "npc_tower_cold_1")
	local point = Entities:FindByName(nil, "npc_dota_spawner_top_left_1"):GetAbsOrigin()
	local difficulty = GameRules:GetCustomGameDifficulty()
	local wave_count = 0

	Timers:CreateTimer(function()
		if EntIceTower == nil or EntIceTower:IsNull() or not EntIceTower:IsAlive() or CustomTimers.proc_final_wave == true or CustomTimers.game_phase >= 3 then
			return nil
		elseif XHSDevTools ~= nil and XHSDevTools:IsSandboxActive() then
			return XHS_CREEPS_INTERVAL
		elseif CustomTimers.timers_paused == 0 then
			wave_count = wave_count + 1

			for j = 1, 8 do
				local unit = CreateUnitByName("npc_ghul_II", point + RandomVector(RandomInt(0, 50)), true, nil, nil, DOTA_TEAM_CUSTOM_1)
				unit:SetBaseDamageMin(unit:GetRealDamageDone(unit) + (PHASE_2_UPGRADE["damage"][difficulty] * wave_count))
				unit:SetBaseDamageMax(unit:GetRealDamageDone(unit) + (PHASE_2_UPGRADE["damage"][difficulty] * wave_count) * 1.1)
				unit:SetMaxHealth(unit:GetMaxHealth() + (PHASE_2_UPGRADE["health"][difficulty] * wave_count))
				unit:SetBaseMaxHealth(unit:GetMaxHealth() + (PHASE_2_UPGRADE["health"][difficulty] * wave_count))
				unit:SetHealth(unit:GetMaxHealth())
				unit:SetPhysicalArmorBaseValue(unit:GetPhysicalArmorValue(false) + (PHASE_2_UPGRADE["armor"][difficulty] * wave_count))
				ApplyGrowthOverheadMarker(unit, wave_count)
			end

			return XHS_CREEPS_INTERVAL
		else -- if CustomTimers.timers_paused == 1 or 2
			return XHS_CREEPS_INTERVAL
		end
	end)
end

function Phase2CreepsRight()
	local EntIceTower = Entities:FindByName(nil, "npc_tower_cold_2")
	local point = Entities:FindByName(nil, "npc_dota_spawner_top_right_1"):GetAbsOrigin()
	local difficulty = GameRules:GetCustomGameDifficulty()
	local wave_count = 0

	Timers:CreateTimer(0, function()
		if EntIceTower == nil or EntIceTower:IsNull() or not EntIceTower:IsAlive() or CustomTimers.proc_final_wave == true or CustomTimers.game_phase >= 3 then
			return nil
		elseif XHSDevTools ~= nil and XHSDevTools:IsSandboxActive() then
			return 30
		elseif CustomTimers.timers_paused == 0 then
			wave_count = wave_count + 1
			for j = 1, 8 do
				local unit = CreateUnitByName("npc_orc_II", point + RandomVector(RandomInt(0, 50)), true, nil, nil, DOTA_TEAM_CUSTOM_1)
				unit:SetBaseDamageMin(unit:GetRealDamageDone(unit) + (PHASE_2_UPGRADE["damage"][difficulty] * wave_count))
				unit:SetBaseDamageMax(unit:GetRealDamageDone(unit) + (PHASE_2_UPGRADE["damage"][difficulty] * wave_count) * 1.1)
				unit:SetMaxHealth(unit:GetMaxHealth() + (PHASE_2_UPGRADE["health"][difficulty] * wave_count))
				unit:SetBaseMaxHealth(unit:GetMaxHealth() + (PHASE_2_UPGRADE["health"][difficulty] * wave_count))
				unit:SetHealth(unit:GetMaxHealth())
				unit:SetPhysicalArmorBaseValue(unit:GetPhysicalArmorValue(false) + (PHASE_2_UPGRADE["armor"][difficulty] * wave_count))
				ApplyGrowthOverheadMarker(unit, wave_count)
			end
			return 30
		elseif CustomTimers.timers_paused ~= 0 then
			return 30
		end
	end)
end

function EndPhase2()
	if XHSSetGlobalObjectiveState ~= nil then
		XHSSetGlobalObjectiveState("phase2_creeps", "Completed", "Phase 2 creep assault survived", nil)
	end

	local ice_towers = Entities:FindAllByName("npc_tower_death")
	for _, tower in pairs(ice_towers) do
		tower:Kill(nil, nil)
	end

	for TW = 1, 2 do
		local ice_towers_main = Entities:FindByName(nil, "npc_tower_cold_" .. TW)
		ice_towers_main:Kill(nil, nil)
	end
end

local FINAL_WAVE_QUEST_NAME = "kill_final_wave"
local FINAL_WAVE_TOTAL_UNITS = 52
local FINAL_WAVE_INTRO_DURATION = 52.0
local FINAL_WAVE_CARDINAL_REVEAL_DELAY = 2.8
local FINAL_WAVE_UNIT_SPAWN_INTERVAL = 0.18
local FINAL_WAVE_PORTAL_FOW_RADIUS = 900
local FINAL_WAVE_PORTAL_FOW_DURATION = 9.0
local FINAL_WAVE_MUSIC_SOUND = "yaskar_01.music.ui_hero_select"
local FINAL_WAVE_PORTAL_START_PARTICLE = "particles/items2_fx/teleport_start.vpcf"
local FINAL_WAVE_PORTAL_END_PARTICLE = "particles/items2_fx/teleport_end.vpcf"
local FINAL_WAVE_PORTAL_RING_PARTICLE = "particles/units/heroes/hero_templar_assassin/templar_assassin_trap_rings_inner.vpcf"

local FINAL_WAVE_CARDINALS = {
	{
		delay = 8.0,
		direction = "west",
		direction_label = "West",
		boss_label = "Balanar",
		angle = 0,
		waypoint = "final_wave_player_2",
		boss = "npc_dota_hero_balanar",
		creeps = { "npc_abomination", "npc_banshee", "npc_necro", "npc_magnataur" },
	},
	{
		delay = 18.0,
		direction = "north",
		direction_label = "North",
		boss_label = "Grom",
		angle = 270,
		waypoint = "final_wave_player_4",
		boss = "npc_dota_hero_grom_hellscream",
		creeps = { "npc_tauren", "npc_chaos_orc", "npc_warlock", "npc_orc_raider" },
	},
	{
		delay = 28.0,
		direction = "east",
		direction_label = "East",
		boss_label = "Illidan",
		angle = 180,
		waypoint = "final_wave_player_6",
		boss = "npc_dota_hero_illidan",
		creeps = { "npc_druid", "npc_guard", "npc_keeper", "npc_luna" },
	},
	{
		delay = 38.0,
		direction = "south",
		direction_label = "South",
		boss_label = "Proudmoore",
		angle = 90,
		waypoint = "final_wave_player_0",
		boss = "npc_dota_hero_proudmoore",
		creeps = { "npc_captain", "npc_marine", "npc_marine", "npc_knight" },
	},
}

local function FindFinalWaveQuest()
	if GameMode == nil or GameMode.Zones == nil then
		return nil, nil
	end

	for _, zone in pairs(GameMode.Zones) do
		if zone ~= nil and zone.Quests ~= nil then
			for _, quest in pairs(zone.Quests) do
				if quest ~= nil and quest.szQuestName == FINAL_WAVE_QUEST_NAME then
					return zone, quest
				end
			end
		end
	end

	return nil, nil
end

local function SendFinalWaveQuestProgress(zone, quest)
	if zone == nil or quest == nil then return end

	CustomGameEventManager:Send_ServerToAllClients("quest_completed", {
		ZoneName = zone.szName,
		QuestName = quest.szQuestName,
		QuestType = quest.szQuestType,
		Completed = quest.nCompleted,
		CompleteLimit = quest.nCompleteLimit,
		XPReward = quest.RewardXP or 0,
		GoldReward = quest.RewardGold or 0,
		ZoneCompleted = false,
		Optional = quest.bOptional,
		ZoneStars = zone.nStars,
	})
end

local function UpdateFinalWaveQuestLimit()
	local spawnedCount = math.min(CustomTimers.final_wave_spawned_kill_limit or 0, FINAL_WAVE_TOTAL_UNITS)
	if spawnedCount <= 0 then return end

	local zone, quest = FindFinalWaveQuest()
	if zone == nil or quest == nil or quest.bCompleted == true then return end

	quest.nCompleteLimit = spawnedCount

	if quest.bActivated ~= true then
		quest.nCompleted = 0
		GameRules.GameMode:OnQuestStarted(zone, quest)
	else
		SendFinalWaveQuestProgress(zone, quest)
	end
end

local function RegisterFinalWaveUnit(unit)
	if unit == nil then return end

	unit.zone = "xhs_holdout"
	unit.xhs_final_wave_unit = true
	CustomTimers.final_wave_spawned_kill_limit = (CustomTimers.final_wave_spawned_kill_limit or 0) + 1
end

local function IsFinalWaveSequenceActive(sequenceId)
	return sequenceId == nil or CustomTimers.final_wave_sequence_id == sequenceId
end

local function GetFinalWaveFort()
	return Entities:FindByClassname(nil, "npc_dota_fort")
end

local function FindFinalWaveSpawner(direction, index)
	return Entities:FindByName(nil, "final_wave_" .. direction .. "_" .. index)
end

local function GetFinalWavePortalOrigin(config)
	local bossSpawner = FindFinalWaveSpawner(config.direction, 13)
	if bossSpawner ~= nil then
		return bossSpawner:GetAbsOrigin()
	end

	local firstSpawner = FindFinalWaveSpawner(config.direction, 1)
	if firstSpawner ~= nil then
		return firstSpawner:GetAbsOrigin()
	end

	return Vector(0, 0, 0)
end

local function SendFinalWaveCamera(position, speed)
	for _, hero in pairs(HeroList:GetAllHeroes()) do
		if hero:IsRealHero() and hero:GetTeam() == DOTA_TEAM_GOODGUYS then
			CustomGameEventManager:Send_ServerToPlayer(hero:GetPlayerOwner(), "set_player_camera", {
				hPosition = position,
				iSpeed = speed or 0.65,
			})
		end
	end
end

local function ApplyFinalWaveCinematicLock(unit, duration)
	if unit == nil or unit:IsNull() then return end
	if duration <= 0 then return end

	local pauseModifier = unit:AddNewModifier(unit, nil, "modifier_pause_creeps", { duration = duration, IsHidden = true })
	if pauseModifier ~= nil then
		pauseModifier:SetStackCount(1)
	end
	unit:AddNewModifier(unit, nil, "modifier_invulnerable", { duration = duration, IsHidden = true })
end

local function QueueFinalWaveRelease(unit, waypoint)
	if unit == nil or unit:IsNull() then return end

	CustomTimers.final_wave_pending_units = CustomTimers.final_wave_pending_units or {}
	table.insert(CustomTimers.final_wave_pending_units, {
		unit = unit,
		waypoint = waypoint,
	})
end

local function ReleaseFinalWaveUnit(unit, waypoint)
	if unit == nil or unit:IsNull() or not unit:IsAlive() then return end

	unit:RemoveModifierByName("modifier_pause_creeps")
	unit:RemoveModifierByName("modifier_invulnerable")

	if waypoint ~= nil and not waypoint:IsNull() then
		unit:SetInitialGoalEntity(waypoint)
		ExecuteOrderFromTable({
			UnitIndex = unit:entindex(),
			OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
			Position = waypoint:GetAbsOrigin(),
		})
	end
end

local function ReleaseFinalWavePendingUnits()
	if CustomTimers.final_wave_pending_units ~= nil then
		for _, data in pairs(CustomTimers.final_wave_pending_units) do
			ReleaseFinalWaveUnit(data.unit, data.waypoint)
		end
	end

	CustomTimers.final_wave_pending_units = nil
	UpdateFinalWaveQuestLimit()
	CustomTimers.final_wave_kill_counting = (CustomTimers.final_wave_spawned_kill_limit or 0) >= FINAL_WAVE_TOTAL_UNITS
end

local function CreateFinalWaveParticle(particleName, origin, duration)
	local particle = ParticleManager:CreateParticle(particleName, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(particle, 0, origin)

	Timers:CreateTimer(duration, function()
		ParticleManager:DestroyParticle(particle, false)
		ParticleManager:ReleaseParticleIndex(particle)
	end)

	return particle
end

local function CreateFinalWavePortalEffects(origin)
	CreateFinalWaveParticle(FINAL_WAVE_PORTAL_RING_PARTICLE, origin, FINAL_WAVE_PORTAL_FOW_DURATION)
	CreateFinalWaveParticle(FINAL_WAVE_PORTAL_START_PARTICLE, origin, FINAL_WAVE_PORTAL_FOW_DURATION)
	AddFOWViewer(DOTA_TEAM_GOODGUYS, origin, FINAL_WAVE_PORTAL_FOW_RADIUS, FINAL_WAVE_PORTAL_FOW_DURATION, false)
end

local function PlayFinalWaveArrivalEffects(unit, playSound)
	if unit == nil or unit:IsNull() then return end

	local origin = unit:GetAbsOrigin()
	local particle = ParticleManager:CreateParticle(FINAL_WAVE_PORTAL_END_PARTICLE, PATTACH_ABSORIGIN_FOLLOW, unit)
	ParticleManager:SetParticleControl(particle, 0, origin)
	ParticleManager:ReleaseParticleIndex(particle)

	if playSound == true then
		unit:EmitSound("Portal.Hero_Disappear")
	end
end

local function NotifyFinalWaveArrival(config)
	if Notifications == nil then return end

	Notifications:TopToAll({
		text = config.boss_label .. " arrives from the " .. config.direction_label,
		duration = 4.0,
		style = { color = "#ffdc73", ["font-size"] = "28px", ["font-weight"] = "bold" },
	})
end

local function SpawnFinalWaveUnit(unitName, spawner, angle, releaseWaypoint, lockDuration, playSound)
	if spawner == nil then return nil end

	local unit = CreateUnitByName(unitName .. "_final_wave", spawner:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
	if unit == nil then return nil end

	RegisterFinalWaveUnit(unit)
	unit:SetAngles(0, angle, 0)
	ApplyFinalWaveCinematicLock(unit, lockDuration)
	QueueFinalWaveRelease(unit, releaseWaypoint)
	PlayFinalWaveArrivalEffects(unit, playSound)

	if playSound == true then
		unit:EmitSound("Hero_TemplarAssassin.Trap")
	end

	UpdateFinalWaveQuestLimit()
	CustomTimers.final_wave_kill_counting = (CustomTimers.final_wave_spawned_kill_limit or 0) >= FINAL_WAVE_TOTAL_UNITS

	return unit
end

function FinalWave(force)
	if force ~= true and XHSDevTools ~= nil and XHSDevTools:IsSandboxActive() then return end

	CustomTimers.proc_final_wave = true
	CustomTimers.final_wave_kill_counting = false
	CustomTimers.final_wave_spawned_kill_limit = 0
	CustomTimers.final_wave_pending_units = {}
	CustomTimers.final_wave_sequence_id = (CustomTimers.final_wave_sequence_id or 0) + 1
	local finalWaveSequenceId = CustomTimers.final_wave_sequence_id

	CustomTimers.current_time["special_event"] = 1
	CustomTimers:Countdown("special_event")
	if XHSSetGlobalObjectiveState ~= nil then
		XHSSetGlobalObjectiveState("final_wave", "Active", "Final Wave active")
	else
		CustomGameEventManager:Send_ServerToAllClients("xhs_global_objective_update", {
			id = "final_wave",
			state = "Active",
			text = "Final Wave active",
		})
	end
	KillCreeps(DOTA_TEAM_CUSTOM_1)
	RefreshPlayers()
	GameRules:SetHeroRespawnEnabled(false)

	TeleportAllHeroes("final_wave_player_", FINAL_WAVE_INTRO_DURATION)

	local fort = GetFinalWaveFort()
	if fort ~= nil then
		EmitSoundOn(FINAL_WAVE_MUSIC_SOUND, fort)
	end

	for _, config in ipairs(FINAL_WAVE_CARDINALS) do
		Timers:CreateTimer(config.delay, function()
			if not IsFinalWaveSequenceActive(finalWaveSequenceId) then return end
			FinalWaveSpawner(config, finalWaveSequenceId)
		end)
	end

	Timers:CreateTimer(FINAL_WAVE_INTRO_DURATION, function()
		if not IsFinalWaveSequenceActive(finalWaveSequenceId) then return end

		for _, hero in pairs(HeroList:GetAllHeroes()) do
			if hero:IsRealHero() and hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				CustomGameEventManager:Send_ServerToPlayer(hero:GetPlayerOwner(), "set_player_camera", {
					hPosition = hero:GetAbsOrigin(),
					iSpeed = 0.85,
				})
			end
		end

		ReleaseFinalWavePendingUnits()

		local finalWaveFort = GetFinalWaveFort()
		if finalWaveFort ~= nil then
			StopSoundOn(FINAL_WAVE_MUSIC_SOUND, finalWaveFort)
			EmitSoundOn("Hero_TemplarAssassin.Trap", finalWaveFort)
		end
	end)
end

function FinalWaveSpawner(configOrCreep1, creep2, creep3, creep4, bossName, angle, direction, waypointName)
	local config = configOrCreep1
	local sequenceId = nil
	if type(configOrCreep1) == "table" then
		sequenceId = creep2
	end

	if not IsFinalWaveSequenceActive(sequenceId) then return end

	if type(configOrCreep1) ~= "table" then
		config = {
			delay = 0,
			direction = direction,
			direction_label = direction or "",
			boss_label = bossName or "",
			angle = angle or 0,
			waypoint = waypointName,
			boss = bossName,
			creeps = { configOrCreep1, creep2, creep3, creep4 },
		}
	end

	if config == nil or config.direction == nil or config.boss == nil then return end

	local releaseWaypoint = Entities:FindByName(nil, config.waypoint)
	local lockDuration = math.max(1.0, FINAL_WAVE_INTRO_DURATION - (config.delay or 0))
	local portalOrigin = GetFinalWavePortalOrigin(config)
	local bossSpawner = FindFinalWaveSpawner(config.direction, 13)
	if bossSpawner == nil then return end

	CreateFinalWavePortalEffects(portalOrigin)
	NotifyFinalWaveArrival(config)

	local boss = SpawnFinalWaveUnit(config.boss, bossSpawner, config.angle, releaseWaypoint, lockDuration, true)
	if boss ~= nil then
		boss:EmitSound("Portal.Loop_Appear")
		SendFinalWaveCamera(boss:GetAbsOrigin(), 0.65)

		Timers:CreateTimer(FINAL_WAVE_CARDINAL_REVEAL_DELAY, function()
			if boss ~= nil and not boss:IsNull() then
				if not IsFinalWaveSequenceActive(sequenceId) then
					StopSoundOn("Portal.Loop_Appear", boss)
					return
				end
				StopSoundOn("Portal.Loop_Appear", boss)
				boss:EmitSound("Hero_TemplarAssassin.Trap")
			end
		end)
	end

	local spawnSlot = 1
	for _, creepName in ipairs(config.creeps) do
		for _ = 1, 3 do
			local currentSlot = spawnSlot
			local currentCreepName = creepName
			Timers:CreateTimer(FINAL_WAVE_CARDINAL_REVEAL_DELAY + (spawnSlot * FINAL_WAVE_UNIT_SPAWN_INTERVAL), function()
				if not IsFinalWaveSequenceActive(sequenceId) then return end
				local spawner = FindFinalWaveSpawner(config.direction, currentSlot)
				SpawnFinalWaveUnit(currentCreepName, spawner, config.angle, releaseWaypoint, lockDuration, currentSlot == 1)
			end)
			spawnSlot = spawnSlot + 1
		end
	end
end
