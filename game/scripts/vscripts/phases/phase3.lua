local function RegisterXHSDevSpawn(unit)
	if XHSDevTools ~= nil and XHSDevTools:IsSandboxActive() then
		XHSDevTools:RegisterSpawnedUnit(unit)
	end
end

require("boss_scripts/phase3_ai/magtheridon")
require("boss_scripts/phase3_ai/grom")
require("boss_scripts/phase3_ai/illidan")
require("boss_scripts/phase3_ai/balanar")
require("boss_scripts/phase3_ai/proudmoore")

LinkLuaModifier(
	"modifier_xhs_late_phase3_physical_resistance",
	"modifiers/modifier_xhs_late_phase3_defense.lua",
	LUA_MODIFIER_MOTION_NONE
)
LinkLuaModifier(
	"modifier_xhs_late_phase3_magic_resistance",
	"modifiers/modifier_xhs_late_phase3_defense.lua",
	LUA_MODIFIER_MOTION_NONE
)

-- Arthas and every boss after him must survive the combined damage of a full
-- party. Solo keeps the KV values; each additional player adds difficulty-
-- appropriate physical and magical resistance.
local LATE_PHASE3_DEFENSE_PER_EXTRA_PLAYER = {
	[1] = { armor = 30, magic_resistance = 6 },
	[2] = { armor = 34, magic_resistance = 7 },
	[3] = { armor = 38, magic_resistance = 8 },
	[4] = { armor = 42, magic_resistance = 9 },
	[5] = { armor = 46, magic_resistance = 10 },
}

local function GetLatePhase3PartySize()
	local playerIds = {}
	local partySize = 0

	for _, hero in pairs(HeroList:GetAllHeroes()) do
		if hero:IsRealHero() and hero:GetTeam() == DOTA_TEAM_GOODGUYS then
			local playerId = hero:GetPlayerOwnerID()
			if playerId >= 0 and playerIds[playerId] ~= true then
				playerIds[playerId] = true
				partySize = partySize + 1
			end
		end
	end

	return math.max(1, math.min(4, partySize))
end

function ApplyLatePhase3BossDefenseScaling(boss)
	if boss == nil or not IsValidEntity(boss) or boss:IsNull() then return end

	local difficulty = math.max(1, math.min(5, GameRules:GetCustomGameDifficulty() or 1))
	local partySize = GetLatePhase3PartySize()
	local extraPlayers = partySize - 1
	local defense = LATE_PHASE3_DEFENSE_PER_EXTRA_PLAYER[difficulty]
	local armorBonus = extraPlayers * defense.armor
	local magicResistanceBonus = extraPlayers * defense.magic_resistance

	boss.xhs_late_phase3_party_size = partySize
	boss.xhs_late_phase3_armor_bonus = armorBonus
	boss.xhs_late_phase3_magic_resistance_bonus = magicResistanceBonus

	local armorModifier = boss:FindModifierByName("modifier_xhs_late_phase3_physical_resistance")
	local magicModifier = boss:FindModifierByName("modifier_xhs_late_phase3_magic_resistance")

	if extraPlayers <= 0 then
		if armorModifier ~= nil then armorModifier:Destroy() end
		if magicModifier ~= nil then magicModifier:Destroy() end
		return
	end

	if armorModifier == nil then
		armorModifier = boss:AddNewModifier(boss, nil, "modifier_xhs_late_phase3_physical_resistance", {})
	end
	if magicModifier == nil then
		magicModifier = boss:AddNewModifier(boss, nil, "modifier_xhs_late_phase3_magic_resistance", {})
	end

	if armorModifier ~= nil then armorModifier:SetStackCount(armorBonus) end
	if magicModifier ~= nil then magicModifier:SetStackCount(magicResistanceBonus) end
end

local function FaceUnitTowardsPosition(unit, position)
	if unit == nil or not IsValidEntity(unit) or unit:IsNull() or position == nil then return end

	local direction = position - unit:GetAbsOrigin()
	direction.z = 0
	if direction:Length2D() <= 0 then return end

	unit:SetForwardVector(direction:Normalized())
	unit:FaceTowards(position)
end

local PHASE3_BOSS_CINEMATIC_DURATION = 3.5
local BANEHALLOW_CINEMATIC_DURATION = PHASE3_BOSS_CINEMATIC_DURATION * 2
local PHASE3_BOSS_PREP_DURATION = 2.5
local PHASE3_BOSS_CAMERA_MOVE_DURATION = 0.20

local function EnsureBossIntroModifierDuration(boss, modifierName, minimumDuration)
	if boss == nil or not IsValidEntity(boss) or boss:IsNull() then return nil end

	local modifier = boss:FindModifierByName(modifierName)
	if modifier == nil then
		modifier = boss:AddNewModifier(boss, nil, modifierName, { duration = minimumDuration })
	elseif modifier:GetRemainingTime() >= 0 and modifier:GetRemainingTime() < minimumDuration then
		modifier:SetDuration(minimumDuration, true)
	end
	return modifier
end

local function ApplyPostCinematicHeroPrepLock(duration)
	for _, hero in pairs(HeroList:GetAllHeroes()) do
		if hero:IsRealHero() and hero:GetTeam() == DOTA_TEAM_GOODGUYS and hero:IsAlive() then
			local modifier = hero:AddNewModifier(hero, nil, "modifier_pause_creeps", { duration = duration })
			if modifier ~= nil then
				modifier:SetStackCount(1)
			end
		end
	end
end

local function PlayPhase3BossSpawnCinematic(boss, cinematicId, title, subtitle, duration, cameraSpeed)
	if XHSCinematics == nil or boss == nil or not IsValidEntity(boss) or boss:IsNull() then return end

	local cinematicDuration = duration or PHASE3_BOSS_CINEMATIC_DURATION
	local minimumBossLockDuration = cinematicDuration + PHASE3_BOSS_PREP_DURATION
	local pauseModifier = EnsureBossIntroModifierDuration(boss, "modifier_pause_creeps", minimumBossLockDuration)
	if pauseModifier ~= nil then
		pauseModifier:SetStackCount(1)
	end
	EnsureBossIntroModifierDuration(boss, "modifier_invulnerable", minimumBossLockDuration)

	XHSCinematics:BeginForAll(cinematicId, {
		duration = cinematicDuration,
		hide_hud = true,
		lock_orders = true,
		camera_entindex = boss:entindex(),
		camera_speed = cameraSpeed or PHASE3_BOSS_CAMERA_MOVE_DURATION,
		transition = 0.4,
		letterbox_pct = 11,
		title = title or "",
		subtitle = subtitle or "",
	})

	Timers:CreateTimer(cinematicDuration, function()
		ApplyPostCinematicHeroPrepLock(PHASE3_BOSS_PREP_DURATION)
	end)
end

local function SpawnBanehallowRevenant(spawnerName, banehallow, pauseDuration)
	local spawner = Entities:FindByName(nil, spawnerName)
	if spawner == nil then return nil end

	local revenant = CreateUnitByName("npc_death_revenant_banehallow", spawner:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
	local targetPosition = banehallow ~= nil and not banehallow:IsNull() and banehallow:GetAbsOrigin() or nil
	FaceUnitTowardsPosition(revenant, targetPosition)
	local pauseModifier = revenant:AddNewModifier(revenant, nil, "modifier_pause_creeps", { duration = pauseDuration, IsHidden = true })
	if pauseModifier ~= nil then
		pauseModifier:SetStackCount(1)
	end
	revenant:AddNewModifier(revenant, nil, "modifier_invulnerable", { duration = pauseDuration, IsHidden = true }):SetStackCount(1)
	revenant:SetRenderColor(20, 200, 20)
	RegisterXHSDevSpawn(revenant)

	return revenant
end

local function SetupMagtheridonPhase3Boss(magtheridon, bossCount)
	if magtheridon == nil then return end

	magtheridon.boss_count = bossCount or magtheridon.boss_count or 1
	magtheridon.xhs_boss_bar_id = "magtheridon_" .. tostring(magtheridon.boss_count)
	magtheridon.zone = "xhs_holdout"
	RegisterXHSDevSpawn(magtheridon)

	if XHSMagtheridon_AttachPhase3AI ~= nil then
		XHSMagtheridon_AttachPhase3AI(magtheridon)
	end
end

local MAGTHERIDON_DEATH_PARTICLE = "particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_shadowraze.vpcf"
local MAGTHERIDON_DEATH_BURSTS = {
	{ delay = 0.00, offset = Vector(0, 0, 80) },
	{ delay = 0.18, offset = Vector(150, 60, 40) },
	{ delay = 0.34, offset = Vector(-130, 95, 65) },
	{ delay = 0.52, offset = Vector(70, -155, 50) },
	{ delay = 0.75, offset = Vector(-90, -110, 100) },
}

function PlayMagtheridonFinalDeathSequence(magtheridon)
	if magtheridon == nil or not IsValidEntity(magtheridon) or magtheridon:IsNull() then return end

	local origin = magtheridon:GetAbsOrigin()
	EmitSoundOnLocationWithCaster(origin, "Hero_Techies.RemoteMine.Detonate", magtheridon)
	for _, burst in ipairs(MAGTHERIDON_DEATH_BURSTS) do
		Timers:CreateTimer(burst.delay, function()
			local position = origin + burst.offset
			local particle = ParticleManager:CreateParticle(MAGTHERIDON_DEATH_PARTICLE, PATTACH_WORLDORIGIN, nil)
			ParticleManager:SetParticleControl(particle, 0, position)
			ParticleManager:ReleaseParticleIndex(particle)
		end)
	end

	Timers:CreateTimer(0.35, function()
		EmitGlobalSound("Loot_Drop_Stinger_Arcana")
	end)
end

function StartMagtheridonArena(bConsole)
	if bConsole == true then
		local newZone = CDungeonZone()
		newZone:StartQuestByName("kill_mag")
	end

	local point_mag = Entities:FindByName(nil, "npc_dota_spawner_magtheridon_arena"):GetAbsOrigin()
	local difficulty = GameRules:GetCustomGameDifficulty()
	local delay = 3.0

	RefreshPlayers()

	TeleportAllHeroes("point_teleport_boss_", 10.0 + delay, delay)

	Timers:CreateTimer(delay, function()
		local magtheridon = CreateUnitByName("npc_dota_hero_magtheridon", point_mag, true, nil, nil, DOTA_TEAM_CUSTOM_2)
		magtheridon:SetAngles(0, 180, 0)

		if difficulty == 2 then
			magtheridon:AddNewModifier(magtheridon, nil, "modifier_ankh", { charges = 1 })
		elseif difficulty == 3 then
			magtheridon:AddNewModifier(magtheridon, nil, "modifier_ankh", { charges = 3 })
		elseif difficulty == 4 then
			magtheridon:AddNewModifier(magtheridon, nil, "modifier_ankh", { charges = 1 })
		elseif difficulty == 5 then
			magtheridon:AddNewModifier(magtheridon, nil, "modifier_ankh", { charges = 2 })
		end

		SetupMagtheridonPhase3Boss(magtheridon, 1)
		magtheridon:AddNewModifier(magtheridon, nil, "modifier_pause_creeps", { Duration = 10, IsHidden = true }):SetStackCount(1)
		magtheridon:AddNewModifier(magtheridon, nil, "modifier_invulnerable", { Duration = 10, IsHidden = true })
		PlayPhase3BossSpawnCinematic(
			magtheridon,
			"xhs_boss_spawn_magtheridon",
			"MAGTHERIDON",
			"THE PIT LORD AWAKENS",
			nil,
			0.30
		)
	end)
end

function EndMagtheridonArena()
	if XHSDevTools ~= nil and XHSDevTools:IsSandboxActive() then
		CustomGameEventManager:Send_ServerToAllClients("hide_boss_hp", { boss_count = 1 })
		CustomGameEventManager:Send_ServerToAllClients("hide_boss_hp", { boss_count = 2 })
		if XHSMagtheridon_HideBossTimer ~= nil then
			XHSMagtheridon_HideBossTimer(1)
			XHSMagtheridon_HideBossTimer(2)
		end
		if XHSMagtheridon_HideFragmentCounter ~= nil then
			XHSMagtheridon_HideFragmentCounter(1)
			XHSMagtheridon_HideFragmentCounter(2)
		end
		CustomGameEventManager:Send_ServerToAllClients("hide_ui", {})
		Notifications:TopToAll({ text = "Dev sandbox: Magtheridon cleared. Door and four-boss progression blocked.", duration = 6.0 })
		XHSDevTools:PushState()
		return
	end

	Entities:FindByName(nil, "trigger_teleport_phase3_creeps"):Enable()

	CustomGameEventManager:Send_ServerToAllClients("hide_boss_hp", { boss_count = 1 })
	CustomGameEventManager:Send_ServerToAllClients("hide_boss_hp", { boss_count = 2 })
	if XHSMagtheridon_HideBossTimer ~= nil then
		XHSMagtheridon_HideBossTimer(1)
		XHSMagtheridon_HideBossTimer(2)
	end
	if XHSMagtheridon_HideFragmentCounter ~= nil then
		XHSMagtheridon_HideFragmentCounter(1)
		XHSMagtheridon_HideFragmentCounter(2)
	end
	CustomGameEventManager:Send_ServerToAllClients("hide_ui", {})

	Notifications:TopToAll({ text = "Magtheridon has been killed! Door opened.", style = { color = "white" }, duration = 10.0 })

	XHSOpenDoorsWithCinematic(
		{ "door_magtheridon" },
		{ "obstruction_magtheridon" },
		"gate_02_open",
		nil,
		{
			move_duration = 1.35,
			hold_duration = 1.25,
			return_duration = 1.0,
		}
	)

	Timers:CreateTimer(2.0, function()
		local grom = CreateUnitByName("npc_dota_hero_grom_hellscream", Entities:FindByName(nil, "spawn_grom_hellscream"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
		grom.zone = "xhs_holdout"
		grom.boss_count = 1
		grom.xhs_boss_bar_suppressed = true
		grom:SetAngles(0, 270, 0)
		GameMode.GromPhase3Boss = grom
		RegisterXHSDevSpawn(grom)
		if XHSGrom_AttachPhase3AI ~= nil then
			XHSGrom_AttachPhase3AI(grom)
		end
	end)

	Timers:CreateTimer(4.0, function()
		local illidan = CreateUnitByName("npc_dota_hero_illidan", Entities:FindByName(nil, "spawn_illidan"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
		illidan.zone = "xhs_holdout"
		illidan.boss_count = 2
		illidan.xhs_boss_bar_suppressed = true
		illidan:SetAngles(0, 0, 0)
		RegisterXHSDevSpawn(illidan)
		if XHSIllidan_AttachPhase3AI ~= nil then
			XHSIllidan_AttachPhase3AI(illidan)
		end
	end)

	Timers:CreateTimer(6.0, function()
		local balanar = CreateUnitByName("npc_dota_hero_balanar", Entities:FindByName(nil, "spawn_balanar"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
		balanar.zone = "xhs_holdout"
		balanar.boss_count = 3
		balanar.xhs_boss_bar_suppressed = true
		balanar:SetAngles(0, 90, 0)
		RegisterXHSDevSpawn(balanar)
		if XHSBalanar_AttachPhase3AI ~= nil then
			XHSBalanar_AttachPhase3AI(balanar)
		end
	end)

	Timers:CreateTimer(8.0, function()
		local proudmoore = CreateUnitByName("npc_dota_hero_proudmoore", Entities:FindByName(nil, "spawn_admiral_proudmore"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
		proudmoore.zone = "xhs_holdout"
		proudmoore.boss_count = 4
		proudmoore.xhs_boss_bar_suppressed = true
		proudmoore:SetAngles(0, 180, 0)
		RegisterXHSDevSpawn(proudmoore)
		if XHSProudmoore_AttachPhase3AI ~= nil then
			XHSProudmoore_AttachPhase3AI(proudmoore)
		end
	end)
end

local function CloseMagtheridonGate()
	DoEntFire("door_magtheridon", "SetAnimation", "gate_02_close", 0, nil, nil)

	local DoorObs = Entities:FindAllByName("obstruction_magtheridon")
	for _, obs in pairs(DoorObs) do
		obs:SetEnabled(true, false)
	end
end

local GROM_VANGUARD_ROUNDS = {
	{
		"npc_orc_raider_final_wave",
		"npc_chaos_orc_final_wave",
		"npc_warlock_final_wave",
	},
	{
		"npc_necro_final_wave",
		"npc_banshee_final_wave",
		"npc_abomination_final_wave",
	},
	{
		"npc_tauren_final_wave",
		"npc_orc_raider_final_wave",
		"npc_warlock_final_wave",
		"npc_magnataur_final_wave",
	},
	{
		"npc_chaos_orc_final_wave",
		"npc_tauren_final_wave",
		"npc_banshee_final_wave",
		"npc_necro_final_wave",
		"npc_magnataur_final_wave",
	},
}

local GROM_VANGUARD_ROUND_TOTALS = {
	[0] = { 16, 16, 16, 16 },
	[1] = { 16, 16, 16, 16 },
	[2] = { 20, 20, 24, 24 },
	[3] = { 28, 28, 32, 32 },
	[4] = { 32, 36, 36, 40 },
	[5] = { 44, 44, 48, 48 },
}

local GROM_VANGUARD_BOUNTIES = {
	npc_orc_raider_final_wave = { gold_min = 550, gold_max = 750, xp = 45 },
	npc_chaos_orc_final_wave = { gold_min = 550, gold_max = 750, xp = 45 },
	npc_warlock_final_wave = { gold_min = 800, gold_max = 1100, xp = 60 },
	npc_necro_final_wave = { gold_min = 800, gold_max = 1100, xp = 60 },
	npc_banshee_final_wave = { gold_min = 800, gold_max = 1100, xp = 60 },
	npc_abomination_final_wave = { gold_min = 1300, gold_max = 1700, xp = 85 },
	npc_tauren_final_wave = { gold_min = 1300, gold_max = 1700, xp = 85 },
	npc_magnataur_final_wave = { gold_min = 1300, gold_max = 1700, xp = 85 },
}

local GROM_VANGUARD_GOLD_MULTIPLIER = 5
local GROM_VANGUARD_HEALTH_MULTIPLIER = 2

local function GetGromVanguardState()
	GameMode.GromVanguard = GameMode.GromVanguard or {}
	return GameMode.GromVanguard
end

local function GetGromVanguardAttackPosition()
	local center = nil
	local count = 0

	for _, hero in pairs(HeroList:GetAllHeroes()) do
		if hero ~= nil and hero:IsRealHero() and hero:GetTeamNumber() == DOTA_TEAM_GOODGUYS and hero:IsAlive() then
			center = center == nil and hero:GetAbsOrigin() or center + hero:GetAbsOrigin()
			count = count + 1
		end
	end

	if center ~= nil and count > 0 then
		return center / count
	end

	local fallback = Entities:FindByName(nil, "point_teleport_phase3_creeps_1")
	if fallback ~= nil then
		return fallback:GetAbsOrigin()
	end

	return Vector(0, 0, 0)
end

local function OrderGromVanguardUnit(unit)
	if unit == nil or not IsValidEntity(unit) or unit:IsNull() or not unit:IsAlive() then return nil end

	local targetPosition = GetGromVanguardAttackPosition()
	ExecuteOrderFromTable({
		UnitIndex = unit:entindex(),
		OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
		Position = targetPosition,
		Queue = false,
	})

	return 3.0
end

local function ApplyGromVanguardBounty(unit, unitName)
	local bounty = GROM_VANGUARD_BOUNTIES[unitName]
	if unit == nil or bounty == nil then return end

	unit:SetMinimumGoldBounty(bounty.gold_min * GROM_VANGUARD_GOLD_MULTIPLIER)
	unit:SetMaximumGoldBounty(bounty.gold_max * GROM_VANGUARD_GOLD_MULTIPLIER)
	unit:SetDeathXP(bounty.xp)
end

local function SpawnGromVanguardUnit(unitName, spawnPosition)
	local unit = CreateUnitByName(unitName, spawnPosition, true, nil, nil, DOTA_TEAM_CUSTOM_2)
	if unit == nil then return nil end

	local state = GetGromVanguardState()
	unit.zone = "xhs_holdout"
	unit.xhs_grom_vanguard_unit = true
	local maxHealth = math.max(1, math.floor(unit:GetMaxHealth() * GROM_VANGUARD_HEALTH_MULTIPLIER))
	unit:SetBaseMaxHealth(maxHealth)
	unit:SetMaxHealth(maxHealth)
	unit:SetHealth(maxHealth)
	ApplyGromVanguardBounty(unit, unitName)
	state.active_units = state.active_units or {}
	state.active_units[unit:entindex()] = true

	if RegisterXHSDevSpawn ~= nil then
		RegisterXHSDevSpawn(unit)
	end

	Timers:CreateTimer(0.2, function()
		return OrderGromVanguardUnit(unit)
	end)

	return unit
end

local function CountLivingGromVanguardUnits()
	local state = GetGromVanguardState()
	local activeUnits = state.active_units or {}
	local count = 0

	for entindex, _ in pairs(activeUnits) do
		local unit = EntIndexToHScript(entindex)
		if unit ~= nil and IsValidEntity(unit) and not unit:IsNull() and unit:IsAlive() then
			count = count + 1
		else
			activeUnits[entindex] = nil
		end
	end

	return count
end

local function EnsureGromVanguardQuestStarted()
	if GameMode == nil or GameMode.Zones == nil or GameMode:IsQuestActive("clear_grom_vanguard") == true then
		return
	end

	for _, zone in pairs(GameMode.Zones) do
		if zone ~= nil and zone.StartQuestByName ~= nil and zone:IsQuestComplete("clear_grom_vanguard") ~= true then
			zone:StartQuestByName("clear_grom_vanguard")
			return
		end
	end
end

local function SpawnGromVanguardRound(roundIndex)
	local round = GROM_VANGUARD_ROUNDS[roundIndex]
	if round == nil then return end

	local difficulty = GameRules:GetCustomGameDifficulty() or 1
	local roundTotals = GROM_VANGUARD_ROUND_TOTALS[difficulty] or GROM_VANGUARD_ROUND_TOTALS[1]
	local totalCount = roundTotals[roundIndex] or 0
	local westCount = math.ceil(totalCount / 2)
	local eastCount = totalCount - westCount
	local westSpawner = Entities:FindByName(nil, "spawner_phase3_creeps_west")
	local eastSpawner = Entities:FindByName(nil, "spawner_phase3_creeps_east")

	if westSpawner == nil or eastSpawner == nil then
		print("SpawnGromVanguardRound - missing phase 3 creep spawners")
		return
	end

	Notifications:TopToAll({
		text = "Grom's Vanguard - wave " .. roundIndex .. " of " .. #GROM_VANGUARD_ROUNDS,
		duration = 4.0,
	})

	local function SpawnSide(spawner, count)
		for i = 1, count do
			local unitName = round[((i - 1) % #round) + 1]
			local position = spawner:GetAbsOrigin() + RandomVector(RandomInt(0, 120))
			SpawnGromVanguardUnit(unitName, position)
		end
	end

	SpawnSide(westSpawner, westCount)
	SpawnSide(eastSpawner, eastCount)

	local state = GetGromVanguardState()
	state.round = roundIndex

	Timers:CreateTimer(1.0, function()
		if CountLivingGromVanguardUnits() > 0 then
			return 1.0
		end

		if state.round < #GROM_VANGUARD_ROUNDS then
			Timers:CreateTimer(4.0, function()
				SpawnGromVanguardRound(state.round + 1)
			end)
		end

		return nil
	end)
end

function OpenGromGate()
	local state = GetGromVanguardState()
	if state.gate_opened == true then return end

	state.gate_opened = true
	local cameraPosition = nil
	local reference = Entities:FindByName(nil, "npc_dota_spawner_magtheridon_arena")
	if reference ~= nil then
		local referencePosition = reference:GetAbsOrigin()
		local closestDistance = nil
		for _, doorName in ipairs({ "door_grom", "door_grom2" }) do
			for _, door in ipairs(Entities:FindAllByName(doorName)) do
				if door ~= nil and IsValidEntity(door) then
					local distance = (door:GetAbsOrigin() - referencePosition):Length2D()
					if closestDistance == nil or distance < closestDistance then
						closestDistance = distance
						cameraPosition = door:GetAbsOrigin()
					end
				end
			end
		end
	end
	if cameraPosition == nil then
		local firstDoor = Entities:FindByName(nil, "door_grom")
		if firstDoor ~= nil and IsValidEntity(firstDoor) then
			cameraPosition = firstDoor:GetAbsOrigin()
		end
	end

	XHSOpenDoorsWithCinematic({ "door_grom", "door_grom2" }, { "obstruction_grom" }, "gate_02_open", function()
		local grom = GameMode.GromPhase3Boss
		if grom ~= nil and IsValidEntity(grom) and not grom:IsNull() then
			if HideBossBar then
				HideBossBar(grom)
			end
			local ai = grom:FindModifierByName("modifier_xhs_grom_phase3_ai")
			if ai ~= nil then
				ai.xhs_boss_bar_revealed = false
			end
		end
	end, {
		camera_position = cameraPosition,
		move_duration = 1.35,
		hold_duration = 1.25,
		return_duration = 1.0,
	})
end

function DarkProtectors(keys)
	local state = GetGromVanguardState()
	if state.started == true then return end
	state.started = true
	state.round = 0
	state.active_units = {}
	state.gate_opened = false

	RefreshPlayers()
	CloseMagtheridonGate()
	EnsureGromVanguardQuestStarted()

	Timers:CreateTimer(0.5, function()
		DoEntFire("trigger_teleport_phase3_creeps", "Kill", nil, 0, nil, nil)
		TeleportAllHeroes("point_teleport_phase3_creeps_", 5.0)
		GiveTomeToAllHeroes(250)

		Timers:CreateTimer(3.0, function()
			SpawnGromVanguardRound(1)
		end)
	end)
end

function FourBossesKillCount()
	if XHSDevTools ~= nil and XHSDevTools:IsSandboxActive() then
		Notifications:TopToAll({ text = "Dev sandbox: four-boss gate progression blocked.", duration = 5.0 })
		XHSDevTools:PushState()
		return
	end

	local teleporters = Entities:FindAllByName("trigger_teleport3")
	FOUR_BOSSES = FOUR_BOSSES + 1

	if FOUR_BOSSES == 4 then
		for _, v in pairs(teleporters) do
			v:Enable()
		end
		Notifications:TopToAll({ text = "You have killed Grom, Proudmoore, Illidan and Balanar. Talk to Uther.", duration = 10.0 })
	end
end

function StartArthasArena(bConsole)
	if bConsole == true then
		local newZone = CDungeonZone()
		newZone:StartQuestByName("kill_arthas")
	end

	CloseMagtheridonGate()

	local arthas = CreateUnitByName("npc_dota_hero_arthas", Entities:FindByName(nil, "npc_dota_spawner_magtheridon_arena"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
	arthas:SetAngles(0, 270, 0)
	arthas:AddNewModifier(arthas, nil, "modifier_pause_creeps", { Duration = 7, IsHidden = true }):SetStackCount(1)
	arthas:AddNewModifier(arthas, nil, "modifier_invulnerable", { Duration = 7, IsHidden = true })
	arthas.zone = "xhs_holdout"
	ApplyLatePhase3BossDefenseScaling(arthas)
	if XHSArthas_AttachPhase3AI ~= nil then
		XHSArthas_AttachPhase3AI(arthas)
	end
	RegisterXHSDevSpawn(arthas)

	TeleportAllHeroes("point_teleport_boss_", 7.0, 3.0)
	Timers:CreateTimer(3.0, function()
		PlayPhase3BossSpawnCinematic(
			arthas,
			"xhs_boss_spawn_arthas",
			"ARTHAS",
			"THE FALLEN PRINCE",
			nil,
			0.20
		)
	end)
end

function StartBanehallowArena()
	TeleportAllHeroes("point_teleport_boss_", 25.0, 3.0)
	local banehallow
	local index = 1
	GameMode.BanehallowRevenantsTotal = 12
	GameMode.BanehallowRevenantsRemaining = GameMode.BanehallowRevenantsTotal

	Timers:CreateTimer(8.0, function()
		banehallow = CreateUnitByName("npc_dota_hero_banehallow", Entities:FindByName(nil, "npc_dota_spawner_magtheridon_arena"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
		banehallow:SetAngles(0, 270, 0)
		banehallow:AddNewModifier(banehallow, nil, "modifier_pause_creeps", { Duration = 20, IsHidden = true }):SetStackCount(1)
		banehallow:AddNewModifier(banehallow, nil, "modifier_invulnerable", { Duration = 20, IsHidden = true })
		banehallow:EmitSound("shop_jbrice_01.stinger.radiant_lose")
		banehallow.zone = "xhs_holdout"
		ApplyLatePhase3BossDefenseScaling(banehallow)
		RegisterXHSDevSpawn(banehallow)
		PlayPhase3BossSpawnCinematic(
			banehallow,
			"xhs_boss_spawn_banehallow",
			"BANEHALLOW",
			"THE NIGHT HUNGERS",
			BANEHALLOW_CINEMATIC_DURATION
		)
		CustomGameEventManager:Send_ServerToAllClients("xhs_boss_counter_update", {
			boss_count = 1,
			label = "Ghost Revenants",
			remaining = GameMode.BanehallowRevenantsRemaining,
			total = GameMode.BanehallowRevenantsTotal,
		})

		for i = 1, 6 do
			local delay = i * 1.0

			Timers:CreateTimer(delay, function()
				local pauseDuration = 20 - delay
				SpawnBanehallowRevenant("npc_dota_spawner_green_revenant_" .. index, banehallow, pauseDuration)
				SpawnBanehallowRevenant("npc_dota_spawner_green_revenant_" .. (index + 6), banehallow, pauseDuration)

				index = index + 1

				if i == 6 then
					if banehallow then
						banehallow:AddNewModifier(banehallow, nil, "modifier_xhs_banehallow_phase3_ai", {})
					end
				end
			end)
		end
	end)
end

function StartLichKingArena()
	local point_boss = Entities:FindByName(nil, "npc_dota_spawner_lich_king_bis"):GetAbsOrigin()
	local reincarnate_time = 8.0
	local enemies = FindUnitsInRadius(DOTA_TEAM_CUSTOM_2, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
	local lich_king_boss = nil

	for _, enemy in pairs(enemies) do
		if enemy:GetUnitName() == "npc_dota_boss_lich_king" then
			lich_king_boss = enemy
			break
		end
	end

	if not lich_king_boss then
		Notifications:TopToAll({ text = "Something went wrong, please report Lich King not spawning on Discord!", duration = 5.0 })
		return
	end

	ApplyLatePhase3BossDefenseScaling(lich_king_boss)
	ShowBossBar(lich_king_boss)
	-- The Lich King is pre-spawned outside his combat position. Move him before
	-- the reveal so the entity-follow camera starts and remains on the arena,
	-- instead of travelling to the old spawn and snapping later.
	FindClearSpaceForUnit(lich_king_boss, point_boss, true)

	TeleportAllHeroes("point_teleport_boss_", 20.0, 3.0)

	Timers:CreateTimer(2.0, function()
		StartAnimation(lich_king_boss, { duration = reincarnate_time, activity = ACT_DOTA_SPAWN, rate = 1.0 })

		Timers:CreateTimer(5.0, function()
			lich_king_boss:EmitSound("Hero_SkeletonKing.Reincarnate")
			PlayPhase3BossSpawnCinematic(
				lich_king_boss,
				"xhs_boss_spawn_lich_king",
				"THE LICH KING",
				"EVERY SOUL YOU LOST NOW MARCHES AT MY COMMAND.",
				3.0
			)
		end)

		Timers:CreateTimer(reincarnate_time, function()
			ApplyLatePhase3BossDefenseScaling(lich_king_boss)
			local attack_position = Entities:FindByName(nil, "npc_dota_spawner_magtheridon_arena"):GetAbsOrigin()
			lich_king_boss:RemoveModifierByName("modifier_invulnerable")
			lich_king_boss:RemoveModifierByName("modifier_stunned")
			ExecuteOrderFromTable({
				UnitIndex = lich_king_boss:entindex(),
				OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
				Position = attack_position,
			})
			lich_king_boss:SetAttackCapability(DOTA_UNIT_CAP_MELEE_ATTACK)
			lich_king_boss:SetMoveCapability(DOTA_UNIT_CAP_MOVE_GROUND)
			--			BossBar(lich_king_boss, "lich_king")
			lich_king_boss.zone = "xhs_holdout"
			RegisterXHSDevSpawn(lich_king_boss)
			if XHSLichKing_AttachPhase3AI ~= nil then
				XHSLichKing_AttachPhase3AI(lich_king_boss)
			end
		end)
	end)

end

function StartSpiritMasterArena()
	local point_boss = Entities:FindByName(nil, "npc_dota_spawner_lich_king_bis"):GetAbsOrigin()
	local start_time = 15.0

	if XHSSpiritMasterEncounter ~= nil then
		XHSSpiritMasterEncounter:Reset()
	end

	TeleportAllHeroes("point_teleport_boss_", start_time + 1, 3.0)

	local spirit_master = CreateUnitByName("npc_dota_boss_spirit_master", Entities:FindByName(nil, "npc_dota_spawner_magtheridon_arena"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
	spirit_master:SetAngles(0, 270, 0)
	spirit_master:AddNewModifier(spirit_master, nil, "modifier_pause_creeps", { Duration = start_time, IsHidden = true }):SetStackCount(1)
	spirit_master:AddNewModifier(spirit_master, nil, "modifier_invulnerable", { Duration = start_time, IsHidden = true })
	spirit_master:EmitSound("SpiritMaster.StartArena")
	spirit_master.zone = "xhs_holdout"
	ApplyLatePhase3BossDefenseScaling(spirit_master)
	RegisterXHSDevSpawn(spirit_master)
	if XHSSpiritMaster_AttachPhase3AI ~= nil then
		XHSSpiritMaster_AttachPhase3AI(spirit_master)
	end
	Timers:CreateTimer(3.0, function()
		PlayPhase3BossSpawnCinematic(spirit_master, "xhs_boss_spawn_spirit_master", "SPIRIT MASTER", "SPIRITS, ASSEMBLE")
	end)
end

function StartSecretArena(hero)
	local point = Entities:FindByName(nil, "npc_dota_muradin_player_1")

	TeleportHero(hero, point:GetAbsOrigin(), 3.0)

	Timers:CreateTimer(3.0, function()
		FindClearSpaceForUnit(hero, point:GetAbsOrigin(), true)
		hero:AddNewModifier(hero, nil, "modifier_pause_creeps", { Duration = 10, IsHidden = true }):SetStackCount(1)
		hero:AddNewModifier(hero, nil, "modifier_invulnerable", { Duration = 10, IsHidden = true })

		TeleportHero(hero, hero:GetAbsOrigin())

		Notifications:BottomToAll({
			duration = 5.0,
			segments = {
				{ hero = hero:GetUnitName() },
				{
					identity_player_id = hero:GetPlayerID(),
					identity_hero_name = hero:GetUnitName(),
				},
				{ text = "found the secret arena!!! GOOD LUCK!", style = { color = "red" } },
			},
		})

		local secret = CreateUnitByName("npc_dota_hero_secret", Entities:FindByName(nil, "npc_dota_muradin_boss"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
		secret:SetAngles(0, 270, 0)
		secret:AddNewModifier(secret, nil, "modifier_pause_creeps", { Duration = 10, IsHidden = true }):SetStackCount(1)
		secret:AddNewModifier(secret, nil, "modifier_invulnerable", { Duration = 9, IsHidden = true })
		ApplyLatePhase3BossDefenseScaling(secret)
	end)
end

function EndGame()
	if XHSDevTools ~= nil and XHSDevTools:IsSandboxActive() then
		Notifications:TopToAll({ text = "Dev sandbox: EndGame blocked.", duration = 6.0 })
		XHSDevTools:PushState()
		return
	end

	GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)

	--		Notifications:TopToAll({text="It's Duel Time!", duration=5.0, style={color="white"}})
	--		Timers:CreateTimer(1, function()
	--			PauseHeroes()
	--			Timers:CreateTimer(5, function()
	--				DuelEvent()
	--				Timers:CreateTimer(3, RestartHeroes())
	--			end)
	--		end)
end
