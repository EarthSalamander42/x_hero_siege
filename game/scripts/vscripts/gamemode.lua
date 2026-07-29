if GameMode == nil then
	_G.GameMode = class({})
end

require('addon_init')
require('events')
require('constants') -- in cause?
require('components/creep_passives/init')
require('components/creep_ai_director/init')

require('libraries/notifications')
require('libraries/animations')
require('libraries/fun')()
require('libraries/functional')
require('libraries/physics')
require('libraries/playerresource')
require('libraries/playertables')
require('libraries/gold')
require('libraries/rgb_to_hex')
require('libraries/corpse_cleanup')

-- require('phases/choose_hero') -- this should remain disabled as this is called through hero map triggers
require('phases/creeps')
require('phases/special_events')
require('phases/phase1')
require('phases/phase2')
require('phases/phase3')
require('zones/zones')
require('units/breakable_container_surprises')
require('units/treasure_chest_surprises')
require('triggers')
if IsInToolsMode() then
	pcall(require, 'components/xhs_bots/init')
end
require('components/api/init')
require('components/item_builds/init')
require('components/performance_counters/init')
require('components/performance_telemetry/init')
require('components/custom_polls/init')
if IsInToolsMode() then
	require('libraries/adv_log')
end
require('components/battlepass/init')
require('components/timers/init')
require('components/overhead_status/init')
require('components/runes/init')
require('components/fragment_quests/init')
require('components/cinematics/init')

if GetMapName() == "x_hero_siege_demo" then
	require('components/hero_selection/init')
	require('components/demo/init')
end

-- new bosses system
require('boss_scripts/boss_functions')
require('components/devtools/init')

LinkLuaModifier("modifier_xhs_end_screen_stat_tracker", "modifiers/modifier_xhs_end_screen_stat_tracker.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_castle_health_bar", "modifiers/modifier_xhs_castle_health_bar.lua", LUA_MODIFIER_MOTION_NONE)

function GameMode:OnFirstPlayerLoaded()
	BASE_GOOD = Entities:FindByName(nil, "base_spawn")
	if BASE_GOOD ~= nil then
		if BASE_GOOD.SetHullRadius ~= nil then
			BASE_GOOD:SetHullRadius(420)
		end
	end

	local castle = Entities:FindByName(nil, "dota_goodguys_fort")
	if castle ~= nil
		and castle.HasModifier ~= nil
		and castle.AddNewModifier ~= nil
		and not castle:HasModifier("modifier_xhs_castle_health_bar") then
		castle:AddNewModifier(castle, nil, "modifier_xhs_castle_health_bar", {})
	end
end

local function ApplyPlayableHeroBaseDamageMultiplier(hero)
	if hero == nil or hero:IsNull() or not hero:IsRealHero() then return end
	if hero:GetUnitName() == "npc_dota_hero_wisp" then return end
	if hero.xhs_base_attack_damage_doubled == true then return end

	hero.xhs_base_attack_damage_doubled = true
	hero:SetBaseDamageMin(math.floor(hero:GetBaseDamageMin() * 2 + 0.5))
	hero:SetBaseDamageMax(math.floor(hero:GetBaseDamageMax() * 2 + 0.5))
end

local function ApplyPlayableHeroBaseHealthMultiplier(hero)
	if hero == nil or hero:IsNull() or not hero:IsRealHero() then return end
	if hero:GetUnitName() == "npc_dota_hero_wisp" then return end
	if hero.xhs_base_health_doubled == true then return end

	local baseMaxHealth = hero.GetBaseMaxHealth ~= nil and hero:GetBaseMaxHealth() or hero:GetMaxHealth()
	if baseMaxHealth == nil or baseMaxHealth <= 0 then return end

	hero.xhs_base_health_doubled = true
	hero:SetBaseMaxHealth(math.floor(baseMaxHealth * 2 + 0.5))
	hero:SetHealth(hero:GetMaxHealth())
end

function GameMode:OnHeroInGame(hero)
	local id = hero:GetPlayerID()
	local point = Entities:FindByName(nil, "hero_selection_" .. id)
	local is_engine_bot = id ~= nil and id >= 0
		and PlayerResource ~= nil
		and PlayerResource.IsFakeClient ~= nil
		and PlayerResource:IsFakeClient(id)

	if hero:GetUnitName() ~= "npc_dota_hero_wisp" and XHSSetPlayerBaseRespawnPosition ~= nil then
		XHSSetPlayerBaseRespawnPosition(hero)
	end
	ApplyPlayableHeroBaseDamageMultiplier(hero)
	ApplyPlayableHeroBaseHealthMultiplier(hero)

	if GetMapName() == "x_hero_siege_demo" then
		point = Entities:FindByName(nil, "npc_dota_spawner_good_mid_staging")
	end

	if hero:GetUnitName() == "npc_dota_hero_wisp" then
		hero:SetAbilityPoints(0)
		hero:SetGold(0, false)

		-- Player bots are replaced by XHSBotProvisioner and do not own one of
		-- the map's human hero-selection pads. Never dereference a missing pad.
		if not is_engine_bot and point ~= nil then
			local delay = 2.0
			hero:AddNewModifier(hero, nil, "modifier_command_restricted", { duration = delay + 0.1 })

			hero:SetContextThink("delay_to_fix_camera_not_centering_lul", function()
				if point ~= nil and not point:IsNull() then
					TeleportHero(hero, point:GetAbsOrigin(), 3.0)
				end
				return nil
			end, delay)
		end
	elseif hero:GetUnitName() == "npc_dota_hero_terrorblade" then
		if IsInToolsMode() then
			hero:IncrementAttributes(100000)
		end
	end

	hero:SetDayTimeVisionRange(XHS_HERO_VISION)
	hero:SetNightTimeVisionRange(XHS_HERO_VISION)

	if hero:IsRealHero() and id ~= nil and id >= 0 and hero:GetUnitName() ~= "npc_dota_hero_wisp" then
		hero:AddNewModifier(hero, nil, "modifier_xhs_end_screen_stat_tracker", {})
	end

	-- debugging tool
	-- if IsInToolsMode() and hero:GetUnitName() == "npc_dota_hero_terrorblade" and hero:IsOwnedByAnyPlayer() then
	-- 	GameMode:TestEveryUnitSpawn()
	-- end
end

function GameMode:TestEveryUnitSpawn()
	local custom_units = LoadKeyValues("scripts/npc/npc_units_custom.txt")
	local units_array = {}
	local delay = 0.5

	local index = 1 -- Indice pour suivre l'unité en cours d'invocation

	for k, v in pairs(custom_units) do
		table.insert(units_array, k)
	end

	local function SpawnNextUnit()
		local unit_name = units_array[index]
		local remainingUnits = #units_array - index
		print("Attempt to spawn unit " .. unit_name .. ". Remaining:" .. remainingUnits)

		CreateUnitByName(unit_name, Vector(0, 0, 0), true, nil, nil, DOTA_TEAM_CUSTOM_1)

		index = index + 1
		if index <= #units_array then
			return delay
		else
			return nil
		end
	end

	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("spawn_units"), function()
		local context = GameRules:GetGameModeEntity():GetContext("spawn_units")

		if context then
			index = tonumber(context)
		end

		local nextDelay = SpawnNextUnit()

		if nextDelay then
			GameRules:GetGameModeEntity():SetContextThink("spawn_units", function()
				return SpawnNextUnit()
			end, nextDelay)
		else
			GameRules:GetGameModeEntity():SetContextThink("spawn_units", nil, 0)
		end

		return nil
	end, 0)
end

function GameMode:InitGameMode()
	local mode = GameRules:GetGameModeEntity()
	-- Timer Rules
	GameRules:SetPostGameTime(600.0)
	GameRules:SetTreeRegrowTime(240.0)
	GameRules:SetHeroSelectionTime(0.0)
	GameRules:SetGoldTickTime(0.0)
	GameRules:SetGoldPerTick(0.0)
	GameRules:SetCustomGameSetupAutoLaunchDelay(9999.0) -- disabled, custom setup flow handles launch
	GameRules:SetCustomGameSetupTimeout(-1.0)        -- keep setup open until custom logic starts the game
	GameRules:SetPreGameTime(PREGAMETIME)

	-- mode:SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_AGILITY_ARMOR, 0) -- default: 0.016 armor per agility point

	--[[
	--Disabling Derived Stats
	mode:SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_STRENGTH_MAGIC_RESISTANCE_PERCENT, 0) -- not working

	mode:SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_AGILITY_MOVE_SPEED_PERCENT, 0)

	-- Overriding Derived Stats
--	mode:SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_STRENGTH_HP_REGEN_PERCENT, 0.0025)
	mode:SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_INTELLIGENCE_SPELL_AMP_PERCENT, 0.075)
--]]
	-- Boolean Rules
	GameRules:SetUseCustomHeroXPValues(true)
	GameRules:SetUseBaseGoldBountyOnHeroes(false)
	GameRules:SetHeroRespawnEnabled(true)
	mode:SetUseCustomHeroLevels(true)
	mode:SetRecommendedItemsDisabled(true)
	mode:SetUnseenFogOfWarEnabled(false)
	mode:SetBuybackEnabled(false)
	mode:SetBotThinkingEnabled(false)
	mode:SetTowerBackdoorProtectionEnabled(false)
	mode:SetFogOfWarDisabled(false)
	mode:SetGoldSoundDisabled(false)
	mode:SetRemoveIllusionsOnDeath(false)
	mode:SetAlwaysShowPlayerInventory(false)
	mode:SetAnnouncerDisabled(false)
	mode:SetLoseGoldOnDeath(false)
	mode:SetDaynightCycleDisabled(true)
	mode:SetWeatherEffectsDisabled(true)
	mode:SetCustomTerrainWeatherEffect("particles/rain_fx/econ_snow.vpcf")

	-- Value Rules
	mode:SetCameraDistanceOverride(1250)
	mode:SetMaximumAttackSpeed(500)
	mode:SetMinimumAttackSpeed(20)
	mode:SetCustomHeroMaxLevel(20)
	-- GameRules:SetHeroMinimapIconScale(1.0) -- There's a bug causing it to change from big to small billion times a second
	-- GameRules:SetCreepMinimapIconScale(1)
	-- GameRules:SetRuneMinimapIconScale(1)

	-- Team Rules
	SetTeamCustomHealthbarColor(DOTA_TEAM_GOODGUYS, 64, 64, 192) --Blue
	--	SetTeamCustomHealthbarColor(DOTA_TEAM_BADGUYS, 255, 255, 0) --Yellow
	SetTeamCustomHealthbarColor(DOTA_TEAM_CUSTOM_1, 128, 32, 32) --Red	
	SetTeamCustomHealthbarColor(DOTA_TEAM_CUSTOM_2, 128, 32, 32) --Red	

	mode:SetCustomGameForceHero("npc_dota_hero_wisp")
	GameRules:LockCustomGameSetupTeamAssignment(true)
	mode:SetFixedRespawnTime(RESPAWN_TIME)
	GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS, 8)
	GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_BADGUYS, 0)
	GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_CUSTOM_1, 0)
	GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_CUSTOM_2, 0)
	mode:SetCustomXPRequiredToReachNextLevel(XP_PER_LEVEL_TABLE)

	-- Lua Modifiers
	LinkLuaModifier("modifier_earthquake_aura", "abilities/heroes/hero_brewmaster", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_command_restricted", "modifiers/modifier_command_restricted", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_ai", "modifiers/modifier_ai", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_breakable_container", "modifiers/modifier_breakable_container", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_creature_techies_land_mine", "modifiers/modifier_creature_techies_land_mine", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_ankh", "items/ankh_of_reincarnation.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_cinematic_pause", "modifiers/modifier_cinematic_pause.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_cinematic_pause_release", "modifiers/modifier_cinematic_pause.lua", LUA_MODIFIER_MOTION_NONE)

	CustomGameEventManager:RegisterListener("setting_vote", Dynamic_Wrap(GameMode, "OnSettingVote"))
	CustomGameEventManager:RegisterListener("custom_setup_ready", Dynamic_Wrap(GameMode, "OnCustomSetupReady"))

	-- Initialized tables for tracking state
	GameMode.bSeenWaitForPlayers = false
	GameMode.vUserIds = {}
	GameMode.VoteTable = {}
	GameMode.CustomSetupAutoReadyDelay = 30
	GameMode.CustomSetupReadyLaunchDelay = 3
	GameMode.CustomSetupDuration = 30
	GameMode.CustomSetupBotDuration = 60
	GameMode.CustomSetupBotProvisioningTimeout = 15
	GameMode.CustomSetupState = nil
	self.PrecachedEnemies = {}
	self.PrecachedVIPs = {}

	if XHSBots ~= nil then
		XHSBots:Init()
	end

	GameMode:OnFirstPlayerLoaded()

	mode:SetThink("OnThink", GameMode, 1)
	mode:SetModifyGoldFilter(Dynamic_Wrap(GameMode, "GoldFilter"), GameMode)
	mode:SetModifyExperienceFilter(Dynamic_Wrap(GameMode, "ExperienceFilter"), GameMode)
	-- mode:SetModifierGainedFilter(Dynamic_Wrap(GameMode, "ModifierFilter"), GameMode)

	if IsInToolsMode() then
		Convars:RegisterCommand("muradin_event", function(keys) return SpecialEvents:MuradinEvent(10) end, "Test Farm Event", FCVAR_CHEAT)
		Convars:RegisterCommand("r&b", function(keys) return SpecialEvents:StartRameroAndBaristolEvent() end, "Test Ramero and Baristol Arena", FCVAR_CHEAT)
		Convars:RegisterCommand("farm_event", function(keys) return SpecialEvents:FarmEvent(10) end, "Test Farm Event", FCVAR_CHEAT)
		Convars:RegisterCommand("final_wave", function(keys) return FinalWave() end, "Test Final Wave", FCVAR_CHEAT)
		Convars:RegisterCommand("magtheridon", function(keys) return StartMagtheridonArena(true) end, "Test Magtheridon Boss", FCVAR_CHEAT)
		Convars:RegisterCommand("arthas", function(keys) return StartArthasArena(true) end, "Test Banehallow Boss", FCVAR_CHEAT)
		Convars:RegisterCommand("banehallow", function(keys) return StartBanehallowArena() end, "Test Banehallow Boss", FCVAR_CHEAT)
		Convars:RegisterCommand("lich_king", function(keys) return StartLichKingArena() end, "Test Magtheridon Boss", FCVAR_CHEAT)
		Convars:RegisterCommand("spirit_master", function(keys) return StartSpiritMasterArena() end, "Test Spirit Master Boss", FCVAR_CHEAT)
		Convars:RegisterCommand("duel_event", function(keys) return SpecialEvents:DuelEvent() end, "Test Duel Event", FCVAR_CHEAT)
		Convars:RegisterCommand("win_game", function(keys) return WinGame() end, "End the game", FCVAR_CHEAT)
	end

	mode:SetExecuteOrderFilter(Dynamic_Wrap(GameMode, "FilterExecuteOrder"), GameMode)
	mode:SetDamageFilter(Dynamic_Wrap(GameMode, "DamageFilter"), GameMode)
	mode:SetHealingFilter(Dynamic_Wrap(GameMode, "HealingFilter"), GameMode)

	CustomGameEventManager:RegisterListener("event_hero_image", function(_, event)
		return GameMode:HeroImage(event)
	end)
	CustomGameEventManager:RegisterListener("event_all_hero_images", function(_, event)
		return GameMode:AllHeroImages(event)
	end)
	CustomGameEventManager:RegisterListener("event_spirit_beast", function(_, event)
		return GameMode:SpiritBeast(event)
	end)
	CustomGameEventManager:RegisterListener("event_frost_infernal", function(_, event)
		return GameMode:FrostInfernal(event)
	end)
	CustomGameEventManager:RegisterListener("quit_event", function(_, event)
		return GameMode:SpecialEventTPQuit2(event)
	end)

	CustomGameEventManager:RegisterListener("dialog_complete", function(...) return GameMode:OnDialogEnded(...) end)
	CustomGameEventManager:RegisterListener("dialog_confirm", function(...) return GameMode:OnDialogConfirm(...) end)
	CustomGameEventManager:RegisterListener("dialog_confirm_expire",
		function(...) return GameMode:OnDialogConfirmExpired(...) end)
	CustomGameEventManager:RegisterListener("xhs_quest_focus", function(...) return GameMode:OnQuestFocusRequested(...) end)
	CustomGameEventManager:RegisterListener("xhs_buy_tomes", function(...) return GameMode:OnBuyTomesRequested(...) end)
	CustomGameEventManager:RegisterListener("xhs_toggle_auto_buy_tomes", function(...) return GameMode:OnToggleAutoBuyTomesRequested(...) end)

	ListenToGameEvent("dota_holdout_revive_complete", Dynamic_Wrap(GameMode, "OnPlayerRevived"), GameMode)
	ListenToGameEvent("dota_pause_event", Dynamic_Wrap(GameMode, "OnDotaPauseEvent"), GameMode)
	ListenToGameEvent("dota_player_update_selected_unit", Dynamic_Wrap(GameMode, "OnPlayerSelectedUnit"), GameMode)
	ListenToGameEvent("dota_item_picked_up", Dynamic_Wrap(GameMode, "OnDotaItemPickedUp"), GameMode)

	--Dungeon
	GameMode.CheckpointsActivated = {}
	GameMode.Zones = {}

	if FragmentQuests ~= nil then
		FragmentQuests:Init()
	end

	if XHSOverheadStatus ~= nil then
		XHSOverheadStatus:Init()
	end

	if XHSDevTools ~= nil then
		XHSDevTools:Init()
	end

	if XHSPerformanceCounters ~= nil then
		XHSPerformanceCounters:Init()
	end

	if XHSCreepAIDirector ~= nil then
		XHSCreepAIDirector:Init()
	end

	if XHSPerformanceTelemetry ~= nil then
		XHSPerformanceTelemetry:Init()
	end

	if XHSPublishAllTomePurchaseStatuses ~= nil then
		XHSPublishAllTomePurchaseStatuses()
	end
end

function GameMode:OnDotaPauseEvent(event)
	local paused = GameRules:IsGamePaused()
	local eventPaused = nil
	if event ~= nil then
		eventPaused = event.paused
		if eventPaused == nil then
			eventPaused = event.game_paused
		end
	end
	if eventPaused ~= nil then
		local value = tostring(eventPaused)
		paused = eventPaused == true or value == "1" or value == "true"
	end

	self:SetPauseHealthBarsHidden(paused)

	CustomGameEventManager:Send_ServerToAllClients("xhs_game_pause_state", {
		paused = paused and 1 or 0,
	})

	if XHSPublishAllTomePurchaseStatuses ~= nil then
		_G.XHSTomePurchaseStatusCache = {}
		XHSPublishAllTomePurchaseStatuses()
	end
end

local CheckTeamDeath = 0

function GameMode:OnThink()
	if XHSPublishAllTomePurchaseStatuses ~= nil then
		XHSPublishAllTomePurchaseStatuses()
	end

	if GameRules:IsGamePaused() == true then return 1 end
	if XHSProcessAutoTomePurchases ~= nil then
		XHSProcessAutoTomePurchases()
	end
	local newState = GameRules:State_Get()

	if newState >= DOTA_GAMERULES_STATE_PRE_GAME then
		if GetMapName() ~= "x_hero_siege_demo" then
			CustomTimers:Think()
		end
	end

	if newState >= DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		GameRules:SetTimeOfDay(0) -- always night
		if FragmentQuests ~= nil then
			FragmentQuests:Think()
		end
	end

	if not GameMode.Zones then GameMode.Zones = {} end

	for _, Zone in pairs(GameMode.Zones) do
		if Zone ~= nil then
			Zone:OnThink()
		end
	end

	for i, Zone in pairs(GameMode.Zones) do
		if not Zone.bNoLeaderboard then
			local netTable = {}
			netTable["ZoneName"] = Zone.szName
			CustomNetTables:SetTableValue("zone_names", string.format("%d", i), netTable)
		end
	end

	local IsTeamAlive = false

	for nPlayerID = 0, PlayerResource:GetPlayerCount() - 1 do
		if PlayerResource:GetTeam(nPlayerID) == DOTA_TEAM_GOODGUYS then
			local Hero = PlayerResource:GetSelectedHeroEntity(nPlayerID)

			if Hero then
				-- From phase 3 onward, reincarnating heroes still keep the team alive.
				if CustomTimers.game_phase >= 3 then
					local isReincarnating = IsPlayerXHSReincarnating ~= nil
						and IsPlayerXHSReincarnating(nPlayerID)
					if Hero:IsAlive() or isReincarnating then
						IsTeamAlive = true
					end
				end

				-- Dungeon stuff
				for _, Zone in pairs(GameMode.Zones) do
					if Zone and Zone:ContainsUnit(Hero) then
						local netTable = {}
						netTable["ZoneName"] = Zone.szName
						CustomNetTables:SetTableValue("player_zone_locations", string.format("%d", nPlayerID), netTable)
					end
				end
			end
		end
	end

	-- using BT_ENABLED to check if Muradin or Farm Event is currently occuring, not the best way but it's a way
	if CustomTimers.game_phase == 1 and GameMode.SpecialArena_occuring == false and GameMode.Muradin_occuring == false and GameMode.FarmEvent_occuring == false then
		SpecialEvents:ReturnFromSpecialArena()
	end

	if CustomTimers.game_phase >= 3 then
		if IsTeamAlive == false then
			if CheckTeamDeath == 0 and Notifications ~= nil then
				Notifications:TopToAll({
					text = "#xhs_team_defeat_countdown_started",
					duration = 5.0,
					severity = "warning",
					style = { color = "#ff5a52" },
				})
			end
			CheckTeamDeath = CheckTeamDeath + 1
		else
			CheckTeamDeath = 0
		end
	else
		CheckTeamDeath = 0
	end

	-- After ten consecutive checks with nobody alive or reincarnating, end the game.
	if CheckTeamDeath == 10 then
		GameRules:SetGameWinner(3)
	end

	-- if not CScriptParticleManager.ACTIVE_PARTICLES then CScriptParticleManager.ACTIVE_PARTICLES = {} end

	-- for k, v in pairs(CScriptParticleManager.ACTIVE_PARTICLES) do
	-- 	if v[2] >= 60 then
	-- 		ParticleManager:DestroyParticle(v[1], false)
	-- 		ParticleManager:ReleaseParticleIndex(v[1])
	-- 		table.remove(CScriptParticleManager.ACTIVE_PARTICLES, k)
	-- 	else
	-- 		CScriptParticleManager.ACTIVE_PARTICLES[k][2] = CScriptParticleManager.ACTIVE_PARTICLES[k][2] + 1
	-- 	end
	-- end

	return 1
end

---------------------------------------------------------------------------
--	HealingFilter
--  *entindex_target_const
--	*entindex_healer_const
--	*entindex_inflictor_const
--	*heal
---------------------------------------------------------------------------
function GameMode:HealingFilter(filterTable)
	local nHeal = filterTable["heal"]
	if filterTable["entindex_healer_const"] == nil then
		return true
	end

	local hHealingHero = EntIndexToHScript(filterTable["entindex_healer_const"])
	if nHeal > 0 and hHealingHero ~= nil and hHealingHero:IsRealHero() then
		if filterTable["entindex_target_const"] ~= nil and XHSRecordEndScreenStat ~= nil and XHSGetPlayerIDFromUnit ~= nil then
			local hHealingTarget = EntIndexToHScript(filterTable["entindex_target_const"])
			local healerPlayerID = XHSGetPlayerIDFromUnit(hHealingHero)
			local targetPlayerID = XHSGetPlayerIDFromUnit(hHealingTarget)

			if healerPlayerID ~= nil and healerPlayerID == targetPlayerID then
				if XHSRecordEndScreenStatSource ~= nil then
					XHSRecordEndScreenStatSource(healerPlayerID, "self_healing", nHeal, "filter")
				else
					XHSRecordEndScreenStat(healerPlayerID, "self_healing", nHeal)
				end
			end
		end

		if FragmentQuests ~= nil then
			FragmentQuests:AddHealing(hHealingHero:GetPlayerID(), nHeal)
		end

		for _, Zone in pairs(GameMode.Zones) do
			if Zone:ContainsUnit(hHealingHero) then
				Zone:AddStat(hHealingHero:GetPlayerID(), ZONE_STAT_HEALING, nHeal)
				return true
			end
		end
	end
	return true
end

---------------------------------------------------------------------------
--	DamageFilter
--  *entindex_victim_const
--	*entindex_attacker_const
--	*entindex_inflictor_const
--	*damagetype_const
--	*damage
---------------------------------------------------------------------------

function GameMode:DamageFilter(filterTable)
	if Runes and Runes.OnDamageFilter then
		Runes:OnDamageFilter(filterTable)
	end

	if FragmentQuests ~= nil then
		FragmentQuests:OnDamage(filterTable)
	end

	local flDamage = filterTable["damage"]

	if filterTable["entindex_attacker_const"] == nil then
		return true
	end

	local hAttackerHero = EntIndexToHScript(filterTable["entindex_attacker_const"])
	local hVictim = nil
	if filterTable["entindex_victim_const"] ~= nil then
		hVictim = EntIndexToHScript(filterTable["entindex_victim_const"])
	end

	-- The Tools-only ally planner consumes a decayed physical/magical/pure
	-- distribution. Keep this observer fail-closed so bot telemetry can never
	-- reject or interrupt the authoritative game damage filter.
	if flDamage > 0 and hVictim ~= nil and XHSBots ~= nil
		and XHSBots.RecordDamageType ~= nil then
		pcall(function()
			XHSBots:RecordDamageType(
				hVictim,
				filterTable["damagetype_const"],
				flDamage
			)
		end)
	end

	if flDamage > 0 and XHSRecordEndScreenStat ~= nil and XHSGetPlayerIDFromUnit ~= nil then
		local attackerPlayerID = XHSGetPlayerIDFromUnit(hAttackerHero)
		if attackerPlayerID ~= nil and XHSIsBossDamageTarget ~= nil and XHSIsBossDamageTarget(hVictim) then
			if XHSRecordEndScreenStatSource ~= nil then
				XHSRecordEndScreenStatSource(attackerPlayerID, "boss_damage", flDamage, "filter")
			else
				XHSRecordEndScreenStat(attackerPlayerID, "boss_damage", flDamage)
			end
		end

		if hVictim ~= nil and hVictim:IsRealHero() then
			local victimPlayerID = XHSGetPlayerIDFromUnit(hVictim)
			if victimPlayerID ~= nil then
				if XHSRecordEndScreenStatSource ~= nil then
					XHSRecordEndScreenStatSource(victimPlayerID, "damage_taken", flDamage, "filter")
				else
					XHSRecordEndScreenStat(victimPlayerID, "damage_taken", flDamage)
				end
			end
		end
	end

	if flDamage > 0 and hAttackerHero ~= nil and hAttackerHero:IsRealHero() then
		for _, Zone in pairs(GameMode.Zones) do
			if Zone:ContainsUnit(hAttackerHero) then
				Zone:AddStat(hAttackerHero:GetPlayerID(), ZONE_STAT_DAMAGE, flDamage)
				return true
			end
		end
	end
	return true
end

function GameMode:FilterExecuteOrder(filterTable)
	--[[
	print("-----------------------------------------")
	for k, v in pairs( filterTable ) do
		print("Order: " .. k .. " " .. tostring(v) )
	end
	]]
	local units = filterTable["units"]
	local order_type = filterTable["order_type"]
	local issuer = filterTable["issuer_player_id_const"]
	local abilityIndex = filterTable["entindex_ability"]
	local targetIndex = filterTable["entindex_target"]
	local x = tonumber(filterTable["position_x"])
	local y = tonumber(filterTable["position_y"])
	local z = tonumber(filterTable["position_z"])
	local point = Vector(x, y, z)
	local queue = filterTable["queue"] == 1
	local unit

	-- Panorama input suppression is cosmetic; reject every player-issued order
	-- authoritatively while that player's cinematic lock is active.
	if XHSCinematics ~= nil and XHSCinematics:IsOrderLocked(issuer) then
		return false
	end

	local function IsAnkhReincarnationInventoryOrder(orderType)
		return orderType == DOTA_UNIT_ORDER_PURCHASE_ITEM
			or (DOTA_UNIT_ORDER_MOVE_ITEM ~= nil and orderType == DOTA_UNIT_ORDER_MOVE_ITEM)
			or (DOTA_UNIT_ORDER_SELL_ITEM ~= nil and orderType == DOTA_UNIT_ORDER_SELL_ITEM)
			or (DOTA_UNIT_ORDER_DROP_ITEM ~= nil and orderType == DOTA_UNIT_ORDER_DROP_ITEM)
			or (DOTA_UNIT_ORDER_GIVE_ITEM ~= nil and orderType == DOTA_UNIT_ORDER_GIVE_ITEM)
			or (DOTA_UNIT_ORDER_PICKUP_ITEM ~= nil and orderType == DOTA_UNIT_ORDER_PICKUP_ITEM)
			or (DOTA_UNIT_ORDER_TAKE_ITEM_FROM_STASH ~= nil and orderType == DOTA_UNIT_ORDER_TAKE_ITEM_FROM_STASH)
			or (DOTA_UNIT_ORDER_EJECT_ITEM_FROM_STASH ~= nil and orderType == DOTA_UNIT_ORDER_EJECT_ITEM_FROM_STASH)
			or (DOTA_UNIT_ORDER_DISASSEMBLE_ITEM ~= nil and orderType == DOTA_UNIT_ORDER_DISASSEMBLE_ITEM)
			or (DOTA_UNIT_ORDER_SET_ITEM_COMBINE_LOCK ~= nil and orderType == DOTA_UNIT_ORDER_SET_ITEM_COMBINE_LOCK)
	end

	local function GetOrderHero()
		if unit ~= nil and not unit:IsNull() and unit.IsRealHero and unit:IsRealHero() then
			return unit
		end

		if issuer ~= nil and issuer >= 0 and PlayerResource:HasSelectedHero(issuer) then
			return PlayerResource:GetSelectedHeroEntity(issuer)
		end

		return nil
	end

	local numUnits = 0
	local numBuildings = 0
	if units then
		-- Skip Prevents order loops
		unit = EntIndexToHScript(units["0"])
		if unit then
			if unit.skip then
				unit.skip = false
				return true
			end
		end

		for n, unit_index in pairs(units) do
			local unit = EntIndexToHScript(unit_index)
			if unit and IsValidEntity(unit) then
				unit.current_order = order_type -- Track the last executed order
				unit.orderTable = filterTable -- Keep the whole order table, to resume it later if needed
				--				local bBuilding = IsCustomBuilding(unit) and not IsUprooted(unit)
				--				if bBuilding then
				--					numBuildings = numBuildings + 1
				--				else
				--					numUnits = numUnits + 1
				--				end
			end
		end
	end

	-- A phase-3 tombstone is a real allied unit. Right-clicking it replaces the
	-- move/attack order with a range-aware revive interaction.
	if unit ~= nil and issuer ~= nil and issuer >= 0 then
		unit.xhs_pending_tombstone_entindex = nil
	end
	local interactionTarget = targetIndex ~= nil and targetIndex > 0 and EntIndexToHScript(targetIndex) or nil
	local isTombstoneInteractionOrder = order_type == DOTA_UNIT_ORDER_MOVE_TO_TARGET
		or order_type == DOTA_UNIT_ORDER_ATTACK_TARGET
	if unit ~= nil
		and interactionTarget ~= nil
		and not interactionTarget:IsNull()
		and isTombstoneInteractionOrder
		and XHSUnitTombstone ~= nil
		and XHSUnitTombstone:IsTombstone(interactionTarget) then
		GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("xhs_tombstone_order"), function()
			if XHSBeginTombstoneInteraction ~= nil then
				XHSBeginTombstoneInteraction(unit, interactionTarget)
			end
			return nil
		end, 0)
		return false
	end

	-- Clicking the same Tombstone again while already channeling it is a harmless
	-- misclick. Reject only that pickup order so the current channel keeps running;
	-- movement, attacks, spells, and every other order still interrupt normally.
	if DOTA_UNIT_ORDER_PICKUP_ITEM ~= nil
		and order_type == DOTA_UNIT_ORDER_PICKUP_ITEM
		and unit ~= nil
		and XHSIsTombstonePickupByActiveChanneler ~= nil then
		local pickupIndex = tonumber(targetIndex)
		if pickupIndex == nil or pickupIndex <= 0 then
			pickupIndex = tonumber(abilityIndex)
		end
		local pickupTarget = pickupIndex ~= nil and EntIndexToHScript(pickupIndex) or nil
		if pickupTarget ~= nil
			and not pickupTarget:IsNull()
			and XHSIsTombstonePickupByActiveChanneler(unit, pickupTarget) then
			return false
		end
	end

	if IsAnkhReincarnationInventoryOrder(order_type) then
		if issuer ~= nil and issuer >= 0 and IsPlayerXHSReincarnating ~= nil and IsPlayerXHSReincarnating(issuer) then
			SendErrorMessage(issuer, "#error_reincarnation_inventory_locked")
			return false
		end

		local orderHero = GetOrderHero()
		if orderHero ~= nil and not orderHero:IsNull() and orderHero.IsXHSReincarnating and orderHero:IsXHSReincarnating() then
			SendErrorMessage(orderHero:GetPlayerID(), "#error_reincarnation_inventory_locked")
			return false
		end
	end

	-- Don't need this.
	if order_type == DOTA_UNIT_ORDER_RADAR or order_type == DOTA_UNIT_ORDER_GLYPH then return end

	--	if order_type == DOTA_UNIT_ORDER_CAST_TARGET then
	--		if target:GetTeam() ~= caster:GetTeam() then
	--			if target:TriggerSpellAbsorb(ability) then
	--				return
	--			end
	--		end
	--	return true
	--	end

	--[[
	-- Deny No-Target Orders requirements
	if order_type == DOTA_UNIT_ORDER_CAST_NO_TARGET then
		local ability = EntIndexToHScript(abilityIndex)
		if not ability then return true end
		local playerID = unit:GetPlayerOwnerID()
		
		-- Check health/mana requirements
		local manaDeficit = unit:GetMana() ~= unit:GetMaxMana()
		local healthDeficit = unit:GetHealthDeficit() > 0
		local bNeedsAnyDeficit = ability:GetKeyValue("RequiresAnyDeficit")
		local requiresHealthDeficit = ability:GetKeyValue("RequiresHealthDeficit")
		local requiresManaDeficit = ability:GetKeyValue("RequiresManaDeficit")

		if bNeedsAnyDeficit and not healthDeficit and not manaDeficit then
			if unit:GetMaxMana() > 0 then
				SendErrorMessage(issuer, "#error_full_mana_health")
			else
				SendErrorMessage(issuer, "#error_full_health")
			end
			return false
		elseif requiresHealthDeficit and not healthDeficit then
			SendErrorMessage(issuer, "#error_full_health")
			return false
		elseif requiresManaDeficit and not manaDeficit then
			SendErrorMessage(issuer, "#error_full_mana")
			return false
		end
	end
--]]
	if order_type == DOTA_UNIT_ORDER_PURCHASE_ITEM then
		if issuer ~= nil and issuer >= 0 and IsPlayerXHSReincarnating ~= nil and IsPlayerXHSReincarnating(issuer) then
			SendErrorMessage(issuer, "#error_reincarnation_inventory_locked")
			return false
		end

		local buyer = unit
		if (buyer == nil or buyer:IsNull() or not buyer:IsRealHero()) and issuer ~= nil then
			buyer = PlayerResource:GetSelectedHeroEntity(issuer)
		end

		local purchasedItemName = filterTable.shop_item_name or filterTable.item_name or filterTable.abilityname
		if purchasedItemName == nil and abilityIndex ~= nil and abilityIndex > 0 then
			local purchasedItem = EntIndexToHScript(abilityIndex)
			if purchasedItem ~= nil and not purchasedItem:IsNull() then
				if purchasedItem.GetAbilityName then
					purchasedItemName = purchasedItem:GetAbilityName()
				elseif purchasedItem.GetName then
					purchasedItemName = purchasedItem:GetName()
				end
			end
		end

		if IsTomeItemName(purchasedItemName) then
			if buyer ~= nil and not buyer:IsNull() and IsHeroOptionalEventTomeLocked(buyer) then
				SendErrorMessage(buyer:GetPlayerID(), "#error_buy_tome_disabled")
				return false
			end

			if IsTomePurchaseGloballyLocked() then
				local playerID = issuer
				if (playerID == nil or playerID < 0) and buyer ~= nil and not buyer:IsNull() then
					playerID = buyer:GetPlayerID()
				end
				if playerID ~= nil and playerID >= 0 then
					SendErrorMessage(playerID, "#error_buy_tome_disabled")
				end
				return false
			end
		end

		if CustomTimers.timers_paused == 1 then
			SendErrorMessage(unit:GetPlayerID(), "#error_shop_disabled")
			return false
		else
			return true
		end
	end

	if order_type == DOTA_UNIT_ORDER_CAST_POSITION then
		local ability = EntIndexToHScript(filterTable["entindex_ability"])

		if ability:GetName() == "item_tpscroll" then
			if _G.SECRET == 1 then return true end

			local target_loc = Vector(filterTable.position_x, filterTable.position_y, filterTable.position_z)

			if IsNearEntity("npc_dota_muradin_boss", target_loc, 1200) then
				print("Near muradin")
				if GameRules:GetCustomGameDifficulty() >= 4 or IsInToolsMode() then
					print("Right difficulty")
					for itemSlot = 0, 5 do
						local item = unit:GetItemInSlot(itemSlot)

						if item and item:GetName() == "item_key_of_the_three_moons" then
							print("You have key to enter secret arena")
							if not GameRules:IsCheatMode() or IsInToolsMode() then
								print("Not cheat mode")
								if not IsInToolsMode() then
									_G.SECRET = 1
								end

								StartSecretArena(unit)
							end
						end
					end
				end

				SendErrorMessage(hero:GetPlayerID(), "I'm sorry, i can't let you in.")
				return false
			end
		end
	end

	return true
end

function GameMode:ReturnHeroFromOptionalEvent(hero, timerName)
	if hero == nil or not IsValidEntity(hero) or hero:IsNull() then return end

	hero:Stop()
	SetHeroOptionalEventTomeLock(hero, nil, false)
	hero:RemoveModifierByName("modifier_pause_creeps")
	hero:RemoveModifierByName("modifier_cinematic_pause")
	hero:RemoveModifierByName("modifier_invulnerable")
	EnableItems(hero)

	local trigger = Entities:FindByName(nil, "trigger_special_event")
	if trigger ~= nil then
		trigger:Enable()
	end

	if timerName ~= nil then
		CustomGameEventManager:Send_ServerToAllClients("hide_timer_" .. timerName, {})
	end

	if hero:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
		local base = BASE_GOOD
		if base == nil or base:IsNull() then
			base = Entities:FindByName(nil, "base_spawn")
		end
		if base ~= nil then
			TeleportHero(hero, base:GetAbsOrigin())
		end
	end
end

function GameMode:IsHeroImageCompleted(playerID, hero)
	self.HeroImageCompletedByPlayer = self.HeroImageCompletedByPlayer or {}

	if playerID ~= nil and self.HeroImageCompletedByPlayer[playerID] == true then
		return true
	end

	return hero ~= nil and IsValidEntity(hero) and not hero:IsNull() and hero.hero_image == true
end

function GameMode:MarkHeroImageCompleted(hero)
	if hero == nil or not IsValidEntity(hero) or hero:IsNull() then return end

	hero.hero_image = true
	self.HeroImageCompletedByPlayer = self.HeroImageCompletedByPlayer or {}

	local playerID = hero:GetPlayerID()
	if playerID ~= nil and playerID >= 0 then
		self.HeroImageCompletedByPlayer[playerID] = true
	end
end

local XHS_OPTIONAL_EVENT_BOSS_BARS = {
	ramero = {
		id = "optional_ramero",
		name = "npc_ramero",
		icon = "npc_dota_hero_sven",
		boss_count = 1,
		global = true,
		light_color = "#f6b54a",
		dark_color = "#38200d",
	},
	baristol = {
		id = "optional_baristol",
		name = "npc_baristol",
		icon = "npc_dota_hero_sven",
		boss_count = 2,
		global = true,
		light_color = "#fff0a6",
		dark_color = "#3b3212",
	},
	sogat = {
		id = "optional_sogat",
		name = "npc_ramero_2",
		icon = "npc_dota_hero_sven",
		boss_count = 1,
		light_color = "#db82ff",
		dark_color = "#30133d",
	},
	spirit_beast = {
		id = "optional_spirit_beast",
		name = "npc_spirit_beast",
		icon = "npc_dota_hero_lone_druid",
		light_color = "#72e8be",
		dark_color = "#123229",
	},
	frost_infernal = {
		id = "optional_frost_infernal",
		name = "npc_frost_infernal",
		icon = "npc_dota_hero_tiny",
		light_color = "#8fe8ff",
		dark_color = "#102b42",
	},
}

function GameMode:ShowOptionalEventBossBar(eventName, boss, hero)
	if boss == nil or not IsValidEntity(boss) or boss:IsNull() then return end

	local config = XHS_OPTIONAL_EVENT_BOSS_BARS[eventName] or {}
	local playerID = nil
	if config.global ~= true then
		if hero == nil or not IsValidEntity(hero) or hero:IsNull() then return end
		playerID = hero:GetPlayerID()
		if playerID == nil or playerID < 0 then return end
	end

	boss.boss_count = config.boss_count or 1
	boss.xhs_boss_bar_id = config.id or eventName
	boss.xhs_boss_bar_name = config.name or boss:GetUnitName()
	boss.xhs_boss_bar_icon = config.icon
	boss.xhs_boss_bar_colors = {
		light_color = config.light_color or "#9be7ff",
		dark_color = config.dark_color or "#102533",
	}
	boss.xhs_boss_bar_suppressed = nil

	local noHealthBar = boss:FindAbilityByName("ability_no_health_bar") or boss:AddAbility("ability_no_health_bar")
	if noHealthBar ~= nil and noHealthBar:GetLevel() < 1 then
		noHealthBar:SetLevel(1)
	end

	if config.global == true then
		boss.xhs_optional_event_player_id = nil
		boss.xhs_boss_bar_players = nil
		boss.xhs_boss_bar_lock_to_registered = nil
		ShowBossBar(boss)
	else
		boss.xhs_optional_event_player_id = playerID
		boss.xhs_boss_bar_lock_to_registered = true
		ShowPrivateBossBar(boss, playerID)
	end
end

function GameMode:HideOptionalEventBossBar(eventName, boss)
	local config = XHS_OPTIONAL_EVENT_BOSS_BARS[eventName] or {}
	local bossIsValid = boss ~= nil and IsValidEntity(boss) and not boss:IsNull()
	local bossCount = config.boss_count or (bossIsValid and boss.boss_count) or 1
	local bossBarId = config.id or (bossIsValid and boss.xhs_boss_bar_id) or eventName

	if bossIsValid then
		boss.xhs_boss_bar_suppressed = true
		HideBossBar(boss)
		boss.xhs_boss_bar_players = nil
		boss.xhs_optional_event_player_id = nil
		boss.xhs_boss_bar_lock_to_registered = nil
	end

	-- A dead optional boss can already have an invalid entity handle when the
	-- arena's other boss triggers the shared cleanup. Send a handle-independent
	-- hide as a final authority so its last 0 HP Panorama state cannot survive.
	if config.global == true then
		CustomGameEventManager:Send_ServerToAllClients("hide_boss_hp", {
			boss_count = bossCount,
			boss_bar_id = bossBarId,
		})
	end
end

function GameMode:GetPlayerIDFromEvent(event)
	if event == nil then return nil end

	local playerID = tonumber(event.PlayerID or event.player_id or event.playerid)
	if playerID ~= nil and playerID >= 0 then return playerID end

	local userID = tonumber(event.userid or event.UserID)
	if userID ~= nil then
		if PlayerResource.GetPlayerIDForUserID ~= nil then
			playerID = PlayerResource:GetPlayerIDForUserID(userID)
			if playerID ~= nil and playerID >= 0 then
				return playerID
			end
		end

		return userID
	end

	return nil
end

function GameMode:GetSelectedUnitFromEvent(event, playerID)
	if event ~= nil then
		for _, key in pairs({ "entindex", "entity_index", "selected_unit_entindex", "selected_unit" }) do
			local entIndex = tonumber(event[key])
			if entIndex ~= nil and entIndex > 0 then
				local unit = EntIndexToHScript(entIndex)
				if unit ~= nil and IsValidEntity(unit) and not unit:IsNull() then
					return unit
				end
			end
		end
	end

	if playerID ~= nil and PlayerResource.GetSelectedEntity ~= nil then
		local unit = PlayerResource:GetSelectedEntity(playerID)
		if unit ~= nil and IsValidEntity(unit) and not unit:IsNull() then
			return unit
		end
	end

	return nil
end

function GameMode:IsOptionalEventBossBarUnit(unit)
	return unit ~= nil
		and IsValidEntity(unit)
		and not unit:IsNull()
		and unit.xhs_optional_event_player_id ~= nil
		and IsBossBarSuppressed(unit) ~= true
end

function GameMode:OnPlayerSelectedUnit(event)
	local playerID = self:GetPlayerIDFromEvent(event)
	if playerID == nil or playerID < 0 then return end

	self.OptionalBossBarSelectionByPlayer = self.OptionalBossBarSelectionByPlayer or {}
	local selected = self:GetSelectedUnitFromEvent(event, playerID)
	local previous = self.OptionalBossBarSelectionByPlayer[playerID]

	if previous ~= nil
		and IsValidEntity(previous)
		and not previous:IsNull()
		and previous ~= selected
		and previous.xhs_optional_event_player_id ~= playerID
	then
		HideBossBarForPlayer(previous, playerID)
	end

	if self:IsOptionalEventBossBarUnit(selected) then
		ShowPrivateBossBar(selected, playerID)
		self.OptionalBossBarSelectionByPlayer[playerID] = selected
	else
		self.OptionalBossBarSelectionByPlayer[playerID] = nil
	end
end

function GameMode:CreateShieldOfInvincibilityDropEffect(position)
	if position == nil then return end

	self.ShieldOfInvincibilityDropEffects = self.ShieldOfInvincibilityDropEffects or {}

	local key = DoUniqueString("xhs_shield_drop")
	local basePosition = Vector(position.x, position.y, position.z + 36)
	local color = Vector(110, 210, 255)
	local particles = {}

	local ring = ParticleManager:CreateParticle("particles/generic_gameplay/rune_bounty_owner.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(ring, 0, basePosition)
	ParticleManager:SetParticleControl(ring, 1, color)
	table.insert(particles, ring)

	local glow = ParticleManager:CreateParticle("particles/generic_hero_status/hero_levelup.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(glow, 0, basePosition)
	ParticleManager:SetParticleControl(glow, 1, color)
	table.insert(particles, glow)

	self.ShieldOfInvincibilityDropEffects[key] = {
		position = basePosition,
		particles = particles,
		started_at = GameRules:GetGameTime(),
	}

	Timers:CreateTimer(0.03, function()
		local effect = self.ShieldOfInvincibilityDropEffects and self.ShieldOfInvincibilityDropEffects[key] or nil
		if effect == nil then return nil end

		local elapsed = GameRules:GetGameTime() - effect.started_at
		local animatedPosition = effect.position + Vector(0, 0, math.sin(elapsed * 3.5) * 8)
		for _, particle in pairs(effect.particles or {}) do
			ParticleManager:SetParticleControl(particle, 0, animatedPosition)
		end

		if elapsed >= 180 then
			self:CleanupShieldOfInvincibilityDropEffect(key)
			return nil
		end

		return 0.03
	end)
end

function GameMode:CleanupShieldOfInvincibilityDropEffect(key)
	if self.ShieldOfInvincibilityDropEffects == nil then return end

	local effect = self.ShieldOfInvincibilityDropEffects[key]
	if effect == nil then return end

	for _, particle in pairs(effect.particles or {}) do
		ParticleManager:DestroyParticle(particle, false)
		ParticleManager:ReleaseParticleIndex(particle)
	end

	self.ShieldOfInvincibilityDropEffects[key] = nil
end

function GameMode:CleanupNearestShieldOfInvincibilityDropEffect(position)
	if position == nil or self.ShieldOfInvincibilityDropEffects == nil then return end

	local nearestKey = nil
	local nearestDistance = nil

	for key, effect in pairs(self.ShieldOfInvincibilityDropEffects) do
		local distance = (effect.position - position):Length2D()
		if distance <= 900 and (nearestDistance == nil or distance < nearestDistance) then
			nearestKey = key
			nearestDistance = distance
		end
	end

	if nearestKey ~= nil then
		self:CleanupShieldOfInvincibilityDropEffect(nearestKey)
	end
end

function GameMode:OnDotaItemPickedUp(event)
	if event == nil then return end

	local itemName = event.itemname or event.item_name or event.ItemName
	local playerID = self:GetPlayerIDFromEvent(event)
	local hero = playerID ~= nil and PlayerResource:GetSelectedHeroEntity(playerID) or nil
	if hero == nil or not IsValidEntity(hero) or hero:IsNull() then
		local heroIndex = tonumber(event.HeroEntityIndex or event.HeroEntIndex or event.hero_entindex or event.UnitEntityIndex)
		if heroIndex ~= nil and heroIndex > 0 then
			hero = EntIndexToHScript(heroIndex)
		end
	end

	if itemName == "item_tombstone" then
		if hero == nil or not IsValidEntity(hero) or hero:IsNull() or playerID == nil then return end
		local itemIndex = tonumber(event.ItemEntityIndex or event.item_entindex or event.ItemEntIndex)
		local item = itemIndex ~= nil and itemIndex > 0 and EntIndexToHScript(itemIndex) or nil
		if item == nil or item:IsNull() then
			for slot = 0, 14 do
				local inventoryItem = hero:GetItemInSlot(slot)
				if inventoryItem ~= nil
					and not inventoryItem:IsNull()
					and inventoryItem:GetAbilityName() == "item_tombstone"
					and inventoryItem.xhs_channel_started ~= true then
					item = inventoryItem
					break
				end
			end
		end
		if item == nil or item:IsNull() then return end

		item.xhs_reviver_entindex = hero:entindex()
		GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("xhs_tombstone_cast"), function()
			if item == nil or item:IsNull() or hero == nil or hero:IsNull() or not hero:IsAlive() then return nil end

			-- ItemCastOnPickup normally starts the channel before this callback.
			-- Keep the explicit order only as a fallback for engine pickup edge cases.
			if item.xhs_channel_started ~= true then
				ExecuteOrderFromTable({
					UnitIndex = hero:entindex(),
					OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
					AbilityIndex = item:entindex(),
					PlayerID = playerID,
					Queue = false,
				})
			end

			GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("xhs_tombstone_cast_check"), function()
				if item ~= nil and not item:IsNull() and item.xhs_channel_started ~= true and XHSRearmTombstoneItem ~= nil then
					XHSRearmTombstoneItem(item)
				end
				return nil
			end, 0.25)
			return nil
		end, 0.03)
		return
	end

	if itemName ~= "item_shield_of_invincibility" then return end
	if hero ~= nil and IsValidEntity(hero) and not hero:IsNull() then
		self:CleanupNearestShieldOfInvincibilityDropEffect(hero:GetAbsOrigin())
	end
end

local HERO_IMAGE_INTRO_DURATION = 5.0

function GameMode:HeroImage(event)
	local PlayerID = event.pID
	local player = PlayerResource:GetPlayer(PlayerID)
	if player == nil then return end

	local hero = player:GetAssignedHero()
	if hero == nil or not IsValidEntity(hero) then return end

	local point_hero = Entities:FindByName(nil, "hero_image_player")
	local point_beast = Entities:FindByName(nil, "hero_image_boss"):GetAbsOrigin()

	if GameMode.HeroImage_occuring == true then
		GameMode:SpecialEventTPQuit(hero)
		Notifications:Bottom(hero:GetPlayerOwnerID(),
			{ text = "Another hero is already fighting Hero Image. Please choose another event.", duration = 7.5 })
		CustomGameEventManager:Send_ServerToPlayer(hero:GetPlayerOwner(), "xhs_event_usage_update", {
			hero_image_busy = true,
		})
		return
	end

	if GameMode:IsHeroImageCompleted(PlayerID, hero) then
		GameMode:SpecialEventTPQuit(hero)
		Notifications:Bottom(hero:GetPlayerOwnerID(), { text = "You can do hero image only once!", duration = 5.0 })
		CustomGameEventManager:Send_ServerToPlayer(hero:GetPlayerOwner(), "xhs_event_usage_update", {
			hero_image_used = true,
			hero_image_busy = false,
		})
		return
	else
		GameMode.HeroImage_occuring = true
		CustomGameEventManager:Send_ServerToAllClients("xhs_event_usage_update", {
			hero_image_busy = true,
		})
		Entities:FindByName(nil, "trigger_special_event_back4"):Enable()
		CustomTimers.current_time["hero_image"] = 0
		GameMode.HeroImageTimerStarted = false

		GameMode.HeroImageUnit = CreateUnitByName(hero:GetUnitName(), point_beast, true, nil, nil, DOTA_TEAM_CUSTOM_1)
		GameMode.HeroImageUnit:SetAngles(0, 210, 0)

		GameMode.HeroImageUnit:SetBaseStrength(hero:GetStrength() * 4)
		GameMode.HeroImageUnit:SetBaseIntellect(hero:GetIntellect(true) * 4)
		GameMode.HeroImageUnit:SetBaseAgility(hero:GetAgility() * 4)
		--		GameMode.HeroImageUnit:SetHasInventory(true)

		ForEachUnitAbility(GameMode.HeroImageUnit, function(ability)
			if ability then
				ability:SetLevel(ability:GetMaxLevel())
			end
		end)

		for i = 0, 5 do
			local item = hero:GetItemInSlot(i)

			if item then
				local newItem = CreateItem(item:GetName(), GameMode.HeroImageUnit, GameMode.HeroImageUnit)
				GameMode.HeroImageUnit:AddItem(newItem)
			end
		end

		GameMode.HeroImageUnit:AddNewModifier(GameMode.HeroImageUnit, nil, "modifier_pause_creeps", { Duration = HERO_IMAGE_INTRO_DURATION, IsHidden = true })
		GameMode.HeroImageUnit:AddNewModifier(GameMode.HeroImageUnit, nil, "modifier_invulnerable", { Duration = HERO_IMAGE_INTRO_DURATION, IsHidden = true })
		GameMode.HeroImageUnit:MakeIllusion()
		GameMode.HeroImageUnit:AddAbility("hero_image_death")
		GameMode.HeroImageUnit.Boss = true
		GameMode.HeroImageUnit:SetHealth(99999999)
		GameMode.HeroImageUnit:SetMana(99999999)

		local ability = GameMode.HeroImageUnit:FindAbilityByName("hero_image_death")
		ability:ApplyDataDrivenModifier(GameMode.HeroImageUnit, GameMode.HeroImageUnit, "modifier_hero_image", {})

		if IsValidEntity(hero) then
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				GameMode:SpecialEventTPQuit(hero)
				SetHeroOptionalEventTomeLock(hero, "hero_image", true)
				DisableItems(hero, SPECIAL_ARENA_DURATION + HERO_IMAGE_INTRO_DURATION)
				Notifications:Bottom(hero:GetPlayerOwnerID(),
					{ text = "Special Event: Kill Hero Image for +250 Stats. You have 2 minutes.", duration = 5.0 })
				TeleportHero(hero, point_hero:GetAbsOrigin())
			end
		end

		-- The mirrored hero is invulnerable and paused during its entrance.
		-- Start both the visible countdown and the authoritative timeout only
		-- when that five-second introduction has finished.
		timers.HeroImageIntro = Timers:CreateTimer(HERO_IMAGE_INTRO_DURATION, function()
			timers.HeroImageIntro = nil
			if GameMode.HeroImage_occuring ~= true
				or GameMode.HeroImageUnit == nil
				or not IsValidEntity(GameMode.HeroImageUnit)
				or GameMode.HeroImageUnit:IsNull() then
				return nil
			end

			CustomTimers.current_time["hero_image"] = SPECIAL_ARENA_DURATION
			CustomGameEventManager:Send_ServerToPlayer(hero:GetPlayerOwner(), "show_timer_hero_image", {})
			if FragmentQuests ~= nil then
				FragmentQuests:OnOptionalEventStart("hero_image", SPECIAL_ARENA_DURATION)
			end
			GameMode.HeroImageTimerStarted = true

			timers.HeroImage = Timers:CreateTimer(SPECIAL_ARENA_DURATION, function()
				timers.HeroImage = nil
				local durationTrigger = Entities:FindByName(nil, "trigger_hero_image_duration")
				if durationTrigger ~= nil then
					durationTrigger:Enable()
				end
				GameMode.HeroImage_occuring = false
				SetHeroOptionalEventTomeLock(hero, "hero_image", false)
				local heroImageCompleted = GameMode:IsHeroImageCompleted(PlayerID, hero)
				if FragmentQuests ~= nil and GameMode.HeroImageTimerStarted == true then
					FragmentQuests:OnOptionalEventEnd("hero_image", heroImageCompleted)
				end
				GameMode.HeroImageTimerStarted = false
				GameMode:ReturnHeroFromOptionalEvent(hero, "hero_image")
				CustomGameEventManager:Send_ServerToPlayer(hero:GetPlayerOwner(), "xhs_event_usage_update", {
					hero_image_used = heroImageCompleted,
					hero_image_busy = false,
				})
				CustomGameEventManager:Send_ServerToAllClients("xhs_event_usage_update", {
					hero_image_busy = false,
				})

				Timers:CreateTimer(5.5, function() --Debug time in case Hero Image kills the player at the very last second
					local trigger = Entities:FindByName(nil, "trigger_hero_image_duration")
					if trigger ~= nil then
						trigger:Disable()
					end
				end)
				if GameMode.HeroImageUnit ~= nil and IsValidEntity(GameMode.HeroImageUnit) and not GameMode.HeroImageUnit:IsNull() then
					GameMode.HeroImageUnit:RemoveSelf()
				end
				GameMode.HeroImageUnit = nil
			end)

			return nil
		end)
	end
end

function GameMode:SpiritBeast(event)
	local PlayerID = event.pID
	local player = PlayerResource:GetPlayer(PlayerID)
	local hero = player:GetAssignedHero()
	local point_hero = Entities:FindByName(nil, "spirit_beast_player")
	local point_beast = Entities:FindByName(nil, "spirit_beast_boss"):GetAbsOrigin()

	if GameMode.SpiritBeast_occuring == true then
		GameMode:SpecialEventTPQuit(hero)
		CustomGameEventManager:Send_ServerToAllClients("xhs_event_usage_update", {
			spirit_beast_busy = true,
		})
		Notifications:Bottom(hero:GetPlayerOwnerID(),
			{ text = "Spirit Beast is already occuring, please choose another event.", duration = 7.5 })
	elseif GameMode.SpiritBeast_killed == false then
		GameMode.SpiritBeast_occuring = true
		CustomGameEventManager:Send_ServerToAllClients("xhs_event_usage_update", {
			spirit_beast_busy = true,
		})
		Entities:FindByName(nil, "trigger_special_event_back3"):Enable()
		CustomGameEventManager:Send_ServerToPlayer(hero:GetPlayerOwner(), "show_timer_spirit_beast", {})
		CustomTimers.current_time["spirit_beast"] = SPECIAL_ARENA_DURATION
		if FragmentQuests ~= nil then
			FragmentQuests:OnOptionalEventStart("spirit_beast", SPECIAL_ARENA_DURATION)
		end

		timers.SpiritBeast = Timers:CreateTimer(SPECIAL_ARENA_DURATION, function()
			timers.SpiritBeast = nil
			if Entities:FindByName(nil, "trigger_spirit_beast_duration") then
				Entities:FindByName(nil, "trigger_spirit_beast_duration"):Enable()
			end

			GameMode.SpiritBeast_occuring = false
			CustomGameEventManager:Send_ServerToAllClients("xhs_event_usage_update", {
				spirit_beast_busy = false,
			})
			SetHeroOptionalEventTomeLock(hero, "spirit_beast", false)
			if FragmentQuests ~= nil then
				FragmentQuests:OnOptionalEventEnd("spirit_beast", false)
			end
			if GameMode.spirit_beast ~= nil and IsValidEntity(GameMode.spirit_beast) and not GameMode.spirit_beast:IsNull() then
				GameMode:HideOptionalEventBossBar("spirit_beast", GameMode.spirit_beast)
				GameMode.spirit_beast:RemoveSelf()
			end
			GameMode.spirit_beast = nil

			Timers:CreateTimer(5.5, function() --Debug time in case Spirit Beast kills the player at the very last second
				Entities:FindByName(nil, "trigger_spirit_beast_duration"):Disable()
			end)
		end)

		GameMode.spirit_beast = CreateUnitByName("npc_spirit_beast", point_beast, true, nil, nil, DOTA_TEAM_CUSTOM_1)
		GameMode.spirit_beast:SetAngles(0, 210, 0)
		GameMode.spirit_beast:AddNewModifier(GameMode.spirit_beast, nil, "modifier_pause_creeps", { Duration = 5, IsHidden = true })
		GameMode.spirit_beast:AddNewModifier(GameMode.spirit_beast, nil, "modifier_invulnerable", { Duration = 5, IsHidden = true })
		GameMode.spirit_beast.Boss = true
		GameMode:ShowOptionalEventBossBar("spirit_beast", GameMode.spirit_beast, hero)

		if IsValidEntity(hero) then
			GameMode:SpecialEventTPQuit(hero)
			SetHeroOptionalEventTomeLock(hero, "spirit_beast", true)
			Notifications:Bottom(hero:GetPlayerOwnerID(),
				{
					text = "Special Event: Kill Spirit Beast for the Shield of Invincibility. You have 2 minutes.",
					duration = 5.0
				})

			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				TeleportHero(hero, point_hero:GetAbsOrigin())
			end
		end

		DisableItems(hero, SPECIAL_ARENA_DURATION)
	elseif GameMode.SpiritBeast_killed == true then
		GameMode:SpecialEventTPQuit(hero)
		CustomGameEventManager:Send_ServerToAllClients("xhs_event_usage_update", {
			spirit_beast_used = true,
			spirit_beast_busy = false,
		})
		Notifications:Bottom(hero:GetPlayerOwnerID(), { text = "Spirit Beast has already been killed!", duration = 5.0 })
	end
end

function GameMode:FrostInfernal(event)
	local PlayerID = event.pID
	local player = PlayerResource:GetPlayer(PlayerID)
	local hero = player:GetAssignedHero()
	local point_hero = Entities:FindByName(nil, "frost_infernal_player")
	local point_beast = Entities:FindByName(nil, "frost_infernal_boss"):GetAbsOrigin()

	if GameMode.FrostInfernal_occuring == true then
		GameMode:SpecialEventTPQuit(hero)
		CustomGameEventManager:Send_ServerToAllClients("xhs_event_usage_update", {
			frost_infernal_busy = true,
		})
		Notifications:Bottom(hero:GetPlayerOwnerID(),
			{ text = "Frost Infernal is already occuring, please choose another event.", duration = 7.5 })
	elseif GameMode.FrostInfernal_killed == false then
		GameMode.FrostInfernal_occuring = true
		CustomGameEventManager:Send_ServerToAllClients("xhs_event_usage_update", {
			frost_infernal_busy = true,
		})
		Entities:FindByName(nil, "trigger_special_event_back2"):Enable()
		CustomGameEventManager:Send_ServerToPlayer(hero:GetPlayerOwner(), "show_timer_frost_infernal", {})
		CustomTimers.current_time["frost_infernal"] = SPECIAL_ARENA_DURATION
		if FragmentQuests ~= nil then
			FragmentQuests:OnOptionalEventStart("frost_infernal", SPECIAL_ARENA_DURATION)
		end

		timers.FrostInfernal = Timers:CreateTimer(SPECIAL_ARENA_DURATION, function()
			timers.FrostInfernal = nil
			if Entities:FindByName(nil, "trigger_frost_infernal_duration") then
				Entities:FindByName(nil, "trigger_frost_infernal_duration"):Enable()
			end

			GameMode.FrostInfernal_occuring = false
			CustomGameEventManager:Send_ServerToAllClients("xhs_event_usage_update", {
				frost_infernal_busy = false,
			})
			SetHeroOptionalEventTomeLock(hero, "frost_infernal", false)
			if FragmentQuests ~= nil then
				FragmentQuests:OnOptionalEventEnd("frost_infernal", false)
			end
			if GameMode.frost_infernal ~= nil and IsValidEntity(GameMode.frost_infernal) and not GameMode.frost_infernal:IsNull() then
				GameMode:HideOptionalEventBossBar("frost_infernal", GameMode.frost_infernal)
				GameMode.frost_infernal:RemoveSelf()
			end
			GameMode.frost_infernal = nil

			Timers:CreateTimer(5.5,
				function() --Debug time in case Frost Infernal kills the player at the very last second
					if Entities:FindByName(nil, "trigger_frost_infernal_duration") then
						Entities:FindByName(nil, "trigger_frost_infernal_duration"):Disable()
					end
				end)
		end)

		GameMode.frost_infernal = CreateUnitByName("npc_frost_infernal", point_beast, true, nil, nil, DOTA_TEAM_CUSTOM_1)
		GameMode.frost_infernal:SetAngles(0, 210, 0)
		GameMode.frost_infernal:AddNewModifier(GameMode.frost_infernal, nil, "modifier_pause_creeps", { Duration = 5, IsHidden = true })
		GameMode.frost_infernal:AddNewModifier(GameMode.frost_infernal, nil, "modifier_invulnerable", { Duration = 5, IsHidden = true })
		GameMode.frost_infernal.Boss = true
		GameMode:ShowOptionalEventBossBar("frost_infernal", GameMode.frost_infernal, hero)

		GameMode:SpecialEventTPQuit(hero)
		SetHeroOptionalEventTomeLock(hero, "frost_infernal", true)
		Notifications:Bottom(hero:GetPlayerOwnerID(),
			{ text = "Special Event: Kill Frost Infernal for the Key of the 3 Moons. You have 2 minutes.", duration = 5.0 })

		if IsValidEntity(hero) then
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				TeleportHero(hero, point_hero:GetAbsOrigin())
			end
		end

		DisableItems(hero, SPECIAL_ARENA_DURATION)
	else
		GameMode:SpecialEventTPQuit(hero)
		CustomGameEventManager:Send_ServerToAllClients("xhs_event_usage_update", {
			frost_infernal_used = true,
			frost_infernal_busy = false,
		})
		Notifications:Bottom(hero:GetPlayerOwnerID(), { text = "Frost Infernal has already been killed!", duration = 5.0 })
	end
end

function GameMode:AllHeroImages(event)
	local PlayerID = event.pID
	local player = PlayerResource:GetPlayer(PlayerID)
	local hero = player:GetAssignedHero()
	local point = Entities:FindByName(nil, "all_hero_image_player")

	if GameMode.AllHeroImagesDead == true then
		GameMode:SpecialEventTPQuit(hero)
		CustomGameEventManager:Send_ServerToAllClients("xhs_event_usage_update", {
			all_hero_images_used = true,
			all_hero_images_busy = false,
		})
		Notifications:Bottom(hero:GetPlayerOwnerID(), { text = "All Hero Image has already been done!", duration = 5.0 })
		return
	end

	if GameMode.AllHeroImages_occuring == true then
		GameMode:SpecialEventTPQuit(hero)
		CustomGameEventManager:Send_ServerToAllClients("xhs_event_usage_update", {
			all_hero_images_busy = true,
		})
		Notifications:Bottom(hero:GetPlayerOwnerID(),
			{ text = "All Hero Images is already occuring, please choose another event.", duration = 7.5 })
	elseif GameMode.AllHeroImages_occuring == false then
		GameMode.AllHeroImages_occuring = true
		CustomGameEventManager:Send_ServerToAllClients("xhs_event_usage_update", {
			all_hero_images_busy = true,
		})
		Entities:FindByName(nil, "trigger_special_event_back5"):Enable()
		CustomGameEventManager:Send_ServerToPlayer(hero:GetPlayerOwner(), "show_timer_all_hero_image", {})
		CustomTimers.current_time["all_hero_images"] = SPECIAL_ARENA_DURATION
		if FragmentQuests ~= nil then
			FragmentQuests:OnOptionalEventStart("all_hero_images", SPECIAL_ARENA_DURATION)
		end

		local illusion_spawn = 0
		local spawnedImages = 0
		Timers:CreateTimer(0.25, function()
			local random = RandomInt(1, #HEROLIST)
			illusion_spawn = illusion_spawn + 1
			local point_image = Entities:FindByName(nil, "special_event_all_" .. illusion_spawn)
			local heroImageName = "npc_dota_hero_" .. HEROLIST[random]
			local spawnIndex = illusion_spawn

			XHSPrecache:CreateUnitByName(heroImageName, point_image:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2, function(heroImage)
				GameMode.AllHeroImage = heroImage
				GameMode.AllHeroImage:SetAngles(0, 45 - 45 * spawnIndex, 0)

				GameMode.AllHeroImage:SetBaseStrength(hero:GetStrength() * 2)
				GameMode.AllHeroImage:SetBaseIntellect(hero:GetIntellect(true) * 2)
				GameMode.AllHeroImage:SetBaseAgility(hero:GetAgility() * 2)

				for i = 0, 5 do
					local item = hero:GetItemInSlot(i)

					if item then
						local newItem = CreateItem(item:GetName(), GameMode.AllHeroImage, GameMode.AllHeroImage)
						GameMode.AllHeroImage:AddItem(newItem)
					end
				end

				GameMode.AllHeroImage:AddNewModifier(GameMode.AllHeroImage, nil, "modifier_pause_creeps", { Duration = 5, IsHidden = true })
				GameMode.AllHeroImage:AddNewModifier(GameMode.AllHeroImage, nil, "modifier_invulnerable", { Duration = 5, IsHidden = true })

				GameMode.AllHeroImage:MakeIllusion()
				GameMode.AllHeroImage.Boss = true
				GameMode.AllHeroImage:SetHealth(99999999)
				GameMode.AllHeroImage:SetMana(99999999)
				spawnedImages = spawnedImages + 1
			end, hero:GetPlayerID())

			local return_time = nil

			if illusion_spawn < 8 then
				return_time = 0.2
			end

			return return_time
		end)

		if IsValidEntity(hero) then
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				GameMode:SpecialEventTPQuit(hero)
				SetHeroOptionalEventTomeLock(hero, "all_hero_images", true)
				Notifications:Bottom(hero:GetPlayerOwnerID(),
					{
						text = "Special Event: Kill All Heroes for Necklace of Immunity. You have 2 minutes.",
						duration = 5.0
					})
				TeleportHero(hero, point:GetAbsOrigin())
			end
		end

		DisableItems(hero, SPECIAL_ARENA_DURATION)

		timers.AllHeroImage = Timers:CreateTimer(0.5, function()
			if spawnedImages < 8 then
				return 1.0
			end

			ALL_HERO_IMAGE_DEAD = 0
			local units = FindUnitsInRadius(DOTA_TEAM_CUSTOM_2, point:GetAbsOrigin(), nil, 2500,
				DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER,
				false)
			for _, unit in pairs(units) do
				ALL_HERO_IMAGE_DEAD = ALL_HERO_IMAGE_DEAD + 1
			end

			if ALL_HERO_IMAGE_DEAD == 0 then
				GameMode.AllHeroImagesDead = true
				GameMode.AllHeroImages_occuring = false
				if FragmentQuests ~= nil then
					FragmentQuests:OnOptionalEventEnd("all_hero_images", true)
				end
				DoEntFire("trigger_all_hero_image_duration", "Kill", nil, 0, nil, nil)
				CustomGameEventManager:Send_ServerToAllClients("hide_timer_all_hero_image", {})
				CustomGameEventManager:Send_ServerToAllClients("xhs_event_usage_update", {
					all_hero_images_used = true,
					all_hero_images_busy = false,
				})
				Timers:RemoveTimer(timers.AllHeroImage)
				Timers:RemoveTimer(timers.AllHeroImage2)
				SetHeroOptionalEventTomeLock(hero, "all_hero_images", false)
				Timers:CreateTimer(0.5, function()
					local pos = Entities:FindByName(nil, "all_hero_image_player"):GetAbsOrigin()
					DropNeutralItemAtPositionForHero("item_necklace_of_spell_immunity", pos, hero, hero:GetTeam(), true)
				end)
				return nil
			end
			return 1.0
		end)

		timers.AllHeroImage2 = Timers:CreateTimer(SPECIAL_ARENA_DURATION, function()
			local durationTrigger = Entities:FindByName(nil, "trigger_all_hero_image_duration")
			if durationTrigger ~= nil then
				durationTrigger:Enable()
			end
			GameMode.AllHeroImages_occuring = false
			if FragmentQuests ~= nil then
				FragmentQuests:OnOptionalEventEnd("all_hero_images", false)
			end
			GameMode:ReturnHeroFromOptionalEvent(hero, "all_hero_image")
			CustomGameEventManager:Send_ServerToAllClients("xhs_event_usage_update", {
				all_hero_images_busy = false,
			})
			SetHeroOptionalEventTomeLock(hero, "all_hero_images", false)

			Timers:CreateTimer(5.5,
				function() --Debug time in case Frost Infernal kills the player at the very last second
					if Entities:FindByName(nil, "trigger_all_hero_image_duration") then
						Entities:FindByName(nil, "trigger_all_hero_image_duration"):Disable()
					end
				end)

			local units = FindUnitsInRadius(DOTA_TEAM_CUSTOM_2, point:GetAbsOrigin(), nil, 2500,
				DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER,
				false)
			for _, v in pairs(units) do
				UTIL_Remove(v)
			end
		end)
	end
end

function GameMode:SpecialEventTPQuit(hero)
	CustomGameEventManager:Send_ServerToPlayer(hero:GetPlayerOwner(), "quit_events", {})
	hero:Stop()
	SetHeroOptionalEventTomeLock(hero, nil, false)
	Entities:FindByName(nil, "trigger_special_event"):Enable()
	hero:RemoveModifierByName("modifier_pause_creeps")
	hero:RemoveModifierByName("modifier_cinematic_pause")
	hero:RemoveModifierByName("modifier_invulnerable")
	EnableItems(hero)
end

function GameMode:SpecialEventTPQuit2(event)
	local PlayerID = event.pID
	local player = PlayerResource:GetPlayer(PlayerID)
	local hero = player:GetAssignedHero()

	hero:Stop()
	SetHeroOptionalEventTomeLock(hero, nil, false)
	hero:RemoveModifierByName("modifier_pause_creeps")
	hero:RemoveModifierByName("modifier_cinematic_pause")
	hero:RemoveModifierByName("modifier_invulnerable")
	EnableItems(hero)

	Entities:FindByName(nil, "trigger_special_event"):Enable()
end

-- Gold gain filter function
function GameMode:GoldFilter(keys)
	-- reason_const		12
	-- reliable			1
	-- player_id_const	0
	-- gold				141

	--	local hero = PlayerResource:GetPlayer(keys.player_id_const):GetAssignedHero()

	-- Show gold earned message??
	--	if hero then
	--		hero:ModifyGold(keys.gold, reliable, keys.reason_const)
	--		if keys.reason_const == DOTA_ModifyGold_Unspecified then return true end
	--		SendOverheadEventMessage(PlayerResource:GetPlayer(keys.player_id_const), OVERHEAD_ALERT_GOLD, hero, keys.gold, nil)
	--	end

	if Runes and Runes.OnGoldFilter then
		return Runes:OnGoldFilter(keys)
	end

	return true
end

function GameMode:ExperienceFilter(keys)
	if Runes and Runes.OnExperienceFilter then
		return Runes:OnExperienceFilter(keys)
	end

	return true
end

function GameMode:HasDialog(hDialogEnt)
	if hDialogEnt == nil or hDialogEnt:IsNull() then
		return false
	end

	for k, v in pairs(DialogDefinition) do
		if k == hDialogEnt:GetUnitName() then
			return true
		end
	end

	return false
end

function GameMode:GetDialog(hDialogEnt)
	if GameMode:HasDialog(hDialogEnt) == false then
		return nil
	end

	local Dialog = DialogDefinition[hDialogEnt:GetUnitName()]
	if Dialog == nil then
		return nil
	end

	if hDialogEnt.nCurrentLine == nil then
		hDialogEnt.nCurrentLine = 1
	end

	if Dialog[hDialogEnt.nCurrentLine] ~= nil and Dialog[hDialogEnt.nCurrentLine].szAdvanceQuestActive ~= nil then
		if GameMode:IsQuestActive(Dialog[hDialogEnt.nCurrentLine].szAdvanceQuestActive) then
			hDialogEnt.nCurrentLine = hDialogEnt.nCurrentLine + 1
		end
	end

	return Dialog[hDialogEnt.nCurrentLine]
end

function GameMode:GetDialogLine(hDialogEnt, nLineNumber)
	if GameMode:HasDialog(hDialogEnt) == false then
		return nil
	end

	local Dialog = DialogDefinition[hDialogEnt:GetUnitName()]
	if Dialog == nil then
		return nil
	end

	return Dialog[nLineNumber]
end

function GameMode:IsQuestActive(szQuestName)
	for _, zone in pairs(GameMode.Zones) do
		if zone ~= nil and zone:IsQuestActive(szQuestName) == true then
			return true
		end
	end

	return false
end

-- Modifier gained filter function
-- function GameMode:ModifierFilter(keys)
-- 	-- entindex_parent_const	215
-- 	-- entindex_ability_const	610
-- 	-- duration					-1
-- 	-- entindex_caster_const	215
-- 	-- name_const				modifier_imba_roshan_rage_stack

-- 	if IsServer() then
-- 		local modifier_owner = EntIndexToHScript(keys.entindex_parent_const)
-- 		local modifier_name = keys.name_const
-- 		local modifier_caster
-- 		local modifier_class

-- 		if keys.entindex_caster_const then
-- 			modifier_caster = EntIndexToHScript(keys.entindex_caster_const)
-- 		else
-- 			return true
-- 		end

-- 		return true
-- 	end
-- end

-- Supporter vote power starts at 2 votes for tier 1 and caps at 5 votes.
ListenToGameEvent('game_rules_state_change', function(keys)
	local game_state = GameRules:State_Get()

	if game_state == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		GameMode:StartCustomSetupFlow()
	elseif game_state == DOTA_GAMERULES_STATE_HERO_SELECTION then
		local default_gamemode = XHS_GAMEMODE_REBORN or 2
		local default_difficulty = 1

		if api then
			api:SetCustomGamemode(default_gamemode)
			api:SetCustomDifficulty(default_difficulty)
		else
			CustomNetTables:SetTableValue("game_options", "gamemode", { tostring(default_gamemode) })
			CustomNetTables:SetTableValue("game_options", "difficulty", { tostring(default_difficulty) })
			GameRules:SetCustomGameDifficulty(default_difficulty)
		end

		XHS_GAMEMODE_ACTIVE = default_gamemode
		GameMode.SelectedGameMode = default_gamemode

		if GameMode.VoteTable == nil then return end
		local votes = GameMode.VoteTable

		for category, pidVoteTable in pairs(votes) do
			-- Tally the votes into a new table
			local voteCounts = {}
			for pid, vote in pairs(pidVoteTable) do
				local gamemode = vote[1]
				local vote_count = vote[2]
				if not voteCounts[vote[1]] then voteCounts[vote[1]] = 0 end
				--				print(pid, vote[1], vote[2])
				voteCounts[vote[1]] = voteCounts[vote[1]] + vote[2]
			end

			-- Find the key that has the highest value (key=vote value, value=number of votes)
			local highest_vote = 0
			local highest_key = ""
			for k, v in pairs(voteCounts) do
				--				print(k, v)
				if v > highest_vote then
					highest_key = k
					highest_vote = v
				end
			end

			-- Check for a tie by counting how many values have the highest number of votes
			local tieTable = {}
			for k, v in pairs(voteCounts) do
				--				print(k, v)
				if v == highest_vote then
					table.insert(tieTable, tonumber(k))
				end
			end

			-- Resolve a tie by selecting a random value from those with the highest votes
			if table.getn(tieTable) > 1 then
				--				print("Vote System: TIE!")
				highest_key = tieTable[math.random(table.getn(tieTable))]
			end

			-- Act on the winning vote
			if category == "difficulty" then
				local selected_difficulty = tonumber(highest_key) or default_difficulty

				if api then
					api:SetCustomDifficulty(selected_difficulty)
				else
					CustomNetTables:SetTableValue("game_options", "difficulty", { tostring(selected_difficulty) })
					GameRules:SetCustomGameDifficulty(selected_difficulty)
				end
			end

			-- print(category .. ": " .. highest_key)
		end
	end
end, nil)

local donator_list = {}
donator_list[1] = 5 -- Lead-Dev
donator_list[2] = 5 -- Dev
donator_list[3] = 5 -- Administrator
donator_list[4] = 4 -- Ember Donator
donator_list[5] = 3 -- Golden Donator
donator_list[6] = 2 -- Donator
donator_list[7] = 5 -- Stoneguard Donator
donator_list[8] = 5 -- Earthwarden Donator
donator_list[9] = 5 -- Legacy Gaben Donator maps to Earthwarden

local function GetPlayerVotePower(pid)
	local vote_power = 1

	local supporter_table = CustomNetTables:GetTableValue("supporter_pass_player", tostring(pid))
	if type(supporter_table) == "table" then
		vote_power = math.max(vote_power, math.floor(tonumber(supporter_table.vote_power) or 1))
	end

	if api then
		if api.GetDonatorStatus then
			vote_power = math.max(vote_power, donator_list[api:GetDonatorStatus(pid)] or 1)
		end

		if api.GetPlayerSupporterTier then
			local supporter_tier = math.floor(tonumber(api:GetPlayerSupporterTier(pid)) or 0)
			if supporter_tier > 0 then
				vote_power = math.max(vote_power, math.min(supporter_tier + 1, 5))
			end
		end
	end

	return math.max(1, math.min(vote_power, 5))
end

function GameMode:RefreshSettingVotePower(pid)
	pid = tonumber(pid)
	if pid == nil or pid < 0 or type(self.VoteTable) ~= "table" then return end

	local vote_power = GetPlayerVotePower(pid)
	for category, votes in pairs(self.VoteTable) do
		local player_vote = type(votes) == "table" and votes[pid] or nil
		if category ~= "gamemode" and type(player_vote) == "table" and player_vote[2] ~= vote_power then
			player_vote[2] = vote_power
			CustomGameEventManager:Send_ServerToAllClients("send_votes", {
				category = category,
				vote = player_vote[1],
				table = votes,
			})
		end
	end
end

function GameMode:OnSettingVote(event_source_index, keys)
	local payload = keys

	-- Dynamic_Wrap supplies the authoritative event source separately. Calls
	-- without that source deliberately fail closed instead of trusting PlayerID.
	if not payload then
		return
	end

	local category = payload.category
	local vote = payload.vote
	local pid = nil
	if api ~= nil and api.GetEventPlayerID ~= nil then
		local ok, sender_player_id = pcall(function()
			return api:GetEventPlayerID(event_source_index, nil)
		end)
		if ok then
			pid = tonumber(sender_player_id)
		end
	end

	if category == nil or vote == nil then
		return
	end

	if pid == nil or pid < 0
		or (IsXHSPersistentPlayerID ~= nil and not IsXHSPersistentPlayerID(pid))
		or (IsXHSPersistentPlayerID == nil
			and PlayerResource.IsFakeClient ~= nil
			and PlayerResource:IsFakeClient(pid)) then
		return
	end

	if category == "gamemode" then
		return
	end

	if not GameMode.VoteTable then GameMode.VoteTable = {} end
	if not GameMode.VoteTable[category] then GameMode.VoteTable[category] = {} end

	if pid >= 0 then
		if not GameMode.VoteTable[category][pid] then GameMode.VoteTable[category][pid] = {} end

		GameMode.VoteTable[category][pid][1] = vote

		GameMode.VoteTable[category][pid][2] = GetPlayerVotePower(pid)
	end

	-- TODO: Finish votes show up
	CustomGameEventManager:Send_ServerToAllClients("send_votes",
		{ category = category, vote = vote, table = GameMode.VoteTable[category] })
end

function GameMode:IsPlayerEligibleForCustomSetupReady(player_id)
	if not PlayerResource:IsValidPlayerID(player_id) then
		return false
	end

	-- Do not require GetPlayer() here: it can remain nil while the client is
	-- loading, and excluding it would let already-loaded clients bypass it.
	if PlayerResource:GetTeam(player_id) ~= DOTA_TEAM_GOODGUYS then
		return false
	end

	if IsXHSPersistentPlayerID ~= nil then
		return IsXHSPersistentPlayerID(player_id)
	end

	if PlayerResource.IsFakeClient ~= nil and PlayerResource:IsFakeClient(player_id) then
		return false
	end

	return true
end

function GameMode:GetCustomSetupEligiblePlayers()
	local players = {}

	for player_id = 0, 23 do
		if self:IsPlayerEligibleForCustomSetupReady(player_id) then
			table.insert(players, player_id)
		end
	end

	return players
end

function GameMode:AreAllCustomSetupPlayersLoaded()
	local eligible_players = self:GetCustomSetupEligiblePlayers()

	if #eligible_players <= 0 then
		return false, eligible_players
	end

	for _, player_id in pairs(eligible_players) do
		-- DOTA_CONNECTION_STATE_CONNECTED is 2 in both Lua and Panorama.
		if PlayerResource:GetConnectionState(player_id) ~= 2 then
			return false, eligible_players
		end
	end

	return true, eligible_players
end

function GameMode:GetCustomSetupSummary()
	local eligible_players = self:GetCustomSetupEligiblePlayers()
	local ready_players = {}
	local ready_count = 0

	for _, player_id in pairs(eligible_players) do
		local is_ready = false

		if self.CustomSetupState and self.CustomSetupState.ready_players and self.CustomSetupState.ready_players[player_id] then
			is_ready = true
		end

		if is_ready then
			ready_count = ready_count + 1
		end

		ready_players[tostring(player_id)] = is_ready and 1 or 0
	end

	return ready_players, ready_count, #eligible_players
end

function GameMode:HasConfiguredXHSBots()
	return IsInToolsMode()
		and XHSBots ~= nil
		and XHSBots.enabled == true
		and type(XHSBots.configuration) == "table"
		and (tonumber(XHSBots.configuration.count) or 0) > 0
end

function GameMode:GetCustomSetupConfiguredDuration()
	if self:HasConfiguredXHSBots() then
		return self.CustomSetupBotDuration or 60
	end
	return self.CustomSetupDuration or 30
end

function GameMode:UpdateCustomSetupBotWindow()
	local state = self.CustomSetupState
	if state == nil or not state.active or state.bot_provisioning then return end

	local current_time = GameRules:GetGameTime()
	local has_configured_bots = self:HasConfiguredXHSBots()
	if has_configured_bots and not state.bot_setup_extended then
		local bot_duration = self.CustomSetupBotDuration or 60
		state.bot_setup_extended = true
		state.duration = bot_duration
		state.auto_ready_delay = bot_duration
		state.deadline = math.max(state.deadline or current_time, current_time + bot_duration)

		-- Applying a positive bot count is an explicit interaction. Restart the
		-- auto-ready window so provisioning cannot race an old zero-bot deadline.
		if state.all_players_loaded_since ~= nil then
			state.all_players_loaded_since = current_time
		end
	elseif not has_configured_bots and state.bot_setup_extended then
		-- Returning to zero bots restores the ordinary Tools window instead of
		-- retaining a stale 60-second extension.
		local base_duration = self.CustomSetupDuration or 30
		state.bot_setup_extended = false
		state.duration = base_duration
		state.auto_ready_delay = self.CustomSetupAutoReadyDelay or base_duration
		state.deadline = math.min(
			state.deadline or (current_time + base_duration),
			current_time + base_duration
		)
		if state.all_players_loaded_since ~= nil then
			state.all_players_loaded_since = current_time
		end
	end
end

function GameMode:PushCustomSetupNetTable()
	if not self.CustomSetupState then
		return
	end

	local ready_players, ready_count, total_players = self:GetCustomSetupSummary()
	local remaining_time = 0
	local bot_provisioning_remaining = 0
	local auto_ready_remaining = 0
	local auto_ready_active = false
	local all_players_loaded = false

	if self.CustomSetupState.active then
		local current_time = GameRules:GetGameTime()
		remaining_time = math.max(0, math.ceil(self.CustomSetupState.deadline - current_time))
		all_players_loaded = self:AreAllCustomSetupPlayersLoaded()
		if self.CustomSetupState.bot_provisioning
			and self.CustomSetupState.bot_provisioning_deadline ~= nil then
			bot_provisioning_remaining = math.max(0, math.ceil(
				self.CustomSetupState.bot_provisioning_deadline - current_time
			))
			-- Panorama already renders remaining_time. Keep that legacy field
			-- meaningful while the separate provisioning watchdog is active.
			remaining_time = math.max(remaining_time, bot_provisioning_remaining)
		end

		if self.CustomSetupState.all_players_loaded_since ~= nil and ready_count < total_players then
			auto_ready_active = true
			auto_ready_remaining = math.max(0, math.ceil(
				(self.CustomSetupState.auto_ready_delay or self.CustomSetupAutoReadyDelay or 30) -
				(current_time - self.CustomSetupState.all_players_loaded_since)
			))
		end
	end

	CustomNetTables:SetTableValue("game_options", "custom_setup", {
		active = self.CustomSetupState.active and 1 or 0,
		launching = self.CustomSetupState.launching and 1 or 0,
		launch_reason = self.CustomSetupState.launch_reason or "",
		duration = self.CustomSetupState.duration or self.CustomSetupDuration or 30,
		remaining_time = remaining_time,
		auto_ready_delay = self.CustomSetupState.auto_ready_delay or self.CustomSetupAutoReadyDelay or 30,
		auto_ready_remaining = auto_ready_remaining,
		auto_ready_active = auto_ready_active and 1 or 0,
		all_players_loaded = all_players_loaded and 1 or 0,
		ready_count = ready_count,
		total_players = total_players,
		ready_players = ready_players,
		bot_provisioning = self.CustomSetupState.bot_provisioning and 1 or 0,
		bot_provisioning_remaining = bot_provisioning_remaining,
		bot_provisioning_timed_out = self.CustomSetupState.bot_provisioning_timed_out and 1 or 0,
		bot_provisioning_error = self.CustomSetupState.bot_provisioning_error or "",
	})
end

function GameMode:StartCustomSetupFlow()
	if self.CustomSetupState and self.CustomSetupState.active then
		self:PushCustomSetupNetTable()
		return
	end

	local current_time = GameRules:GetGameTime()
	local configured_duration = self:GetCustomSetupConfiguredDuration()
	local has_configured_bots = self:HasConfiguredXHSBots()
	self.CustomSetupState = {
		active = true,
		launching = false,
		launch_reason = "",
		started_at = current_time,
		duration = configured_duration,
		auto_ready_delay = has_configured_bots and configured_duration
			or (self.CustomSetupAutoReadyDelay or 30),
		deadline = current_time + configured_duration,
		all_ready_triggered = false,
		auto_ready_triggered = false,
		all_players_loaded_since = nil,
		ready_players = {},
		bot_provisioning = false,
		bot_provisioning_generation = 0,
		bot_provisioning_timed_out = false,
		bot_provisioning_error = "",
		bot_setup_extended = has_configured_bots,
	}

	self:PushCustomSetupNetTable()

	GameRules:GetGameModeEntity():SetContextThink("xhs_custom_setup_think", function()
		return GameMode:CustomSetupThink()
	end, 0.1)
end

function GameMode:CompleteCustomSetupLaunch(launch_reason)
	if not self.CustomSetupState or not self.CustomSetupState.active then
		return
	end

	self.CustomSetupState.bot_provisioning_generation =
		(self.CustomSetupState.bot_provisioning_generation or 0) + 1
	self.CustomSetupState.bot_provisioning = false
	self.CustomSetupState.active = false
	self.CustomSetupState.launching = true
	self.CustomSetupState.launch_reason = launch_reason or "timeout"
	self:PushCustomSetupNetTable()

	if GameRules.FinishCustomGameSetup then
		GameRules:FinishCustomGameSetup()
	else
		GameRules:SetCustomGameSetupRemainingTime(0.0)
	end
end

function GameMode:FinishCustomSetup(launch_reason)
	if not self.CustomSetupState or not self.CustomSetupState.active then
		return
	end
	if self.CustomSetupState.bot_provisioning then
		return
	end

	if XHSBots ~= nil and XHSBots.enabled == true and XHSBots.locked ~= true then
		local state = self.CustomSetupState
		local generation = (state.bot_provisioning_generation or 0) + 1
		state.bot_provisioning_generation = generation
		local callback_fired = false
		local function OnBotProvisioningFinished()
			callback_fired = true
			local current_state = GameMode.CustomSetupState
			if current_state == nil
				or not current_state.active
				or current_state.bot_provisioning_generation ~= generation then
				return
			end
			current_state.bot_provisioning = false
			current_state.bot_provisioning_deadline = nil
			GameMode:CompleteCustomSetupLaunch(launch_reason)
		end

		local hook_ok, canLaunch = pcall(function()
			return XHSBots:BeforeCustomSetupFinish(
				launch_reason,
				OnBotProvisioningFinished
			)
		end)

		if not hook_ok then
			local provisioning_error = tostring(canLaunch)
			state.bot_provisioning_error = provisioning_error
			state.bot_provisioning_generation = generation + 1
			if XHSBots ~= nil then
				XHSBots.status = "error"
				XHSBots.error = provisioning_error
				if type(XHSBots.PushConfiguration) == "function" then
					pcall(function()
						XHSBots:PushConfiguration()
					end)
				end
			end
			self:CompleteCustomSetupLaunch("bot_provisioning_error")
			return
		end

		if callback_fired or not self.CustomSetupState.active then
			return
		end

		if not canLaunch then
			local current_time = GameRules:GetGameTime()
			state.bot_provisioning = true
			state.bot_provisioning_started_at = current_time
			state.bot_provisioning_deadline = current_time
				+ (self.CustomSetupBotProvisioningTimeout or 15)
			state.launch_reason = "bot_provisioning"
			self:PushCustomSetupNetTable()
			return
		end
	end

	self:CompleteCustomSetupLaunch(launch_reason)
end

function GameMode:CustomSetupThink()
	self:UpdateCustomSetupBotWindow()

	if not self.CustomSetupState then
		return nil
	end

	if GameRules:State_Get() ~= DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		self.CustomSetupState.active = false
		self.CustomSetupState.launching = false
		self:PushCustomSetupNetTable()
		return nil
	end

	if self.CustomSetupState.bot_provisioning then
		local current_time = GameRules:GetGameTime()
		local provisioning_deadline = self.CustomSetupState.bot_provisioning_deadline
		if provisioning_deadline ~= nil and current_time >= provisioning_deadline then
			local provisioning_error = "Bot provisioning timed out"
			self.CustomSetupState.bot_provisioning = false
			self.CustomSetupState.bot_provisioning_timed_out = true
			self.CustomSetupState.bot_provisioning_error = provisioning_error
			self.CustomSetupState.bot_provisioning_generation =
				(self.CustomSetupState.bot_provisioning_generation or 0) + 1
			if XHSBots ~= nil then
				XHSBots.status = "error"
				XHSBots.error = provisioning_error
				if type(XHSBots.PushConfiguration) == "function" then
					pcall(function()
						XHSBots:PushConfiguration()
					end)
				end
			end
			self:CompleteCustomSetupLaunch("bot_provisioning_timeout")
			return nil
		end
		self:PushCustomSetupNetTable()
		return 0.2
	end

	local ready_launch_delay = self.CustomSetupReadyLaunchDelay or 3
	local auto_ready_delay = self.CustomSetupState.auto_ready_delay
		or self.CustomSetupAutoReadyDelay or 30
	local current_time = GameRules:GetGameTime()
	local _, ready_count, total_players = self:GetCustomSetupSummary()
	local all_players_loaded, eligible_players = self:AreAllCustomSetupPlayersLoaded()

	if all_players_loaded and ready_count < total_players then
		if self.CustomSetupState.all_players_loaded_since == nil then
			self.CustomSetupState.all_players_loaded_since = current_time
			print(string.format(
				"[XHS CustomSetup] All %d eligible player(s) loaded; auto-ready starts in %ds.",
				total_players,
				auto_ready_delay
			))
		end

		if current_time - self.CustomSetupState.all_players_loaded_since >= auto_ready_delay then
			for _, player_id in pairs(eligible_players) do
				self.CustomSetupState.ready_players[player_id] = true
			end

			self.CustomSetupState.auto_ready_triggered = true
			ready_count = total_players
			print(string.format(
				"[XHS CustomSetup] Auto-ready applied to %d player(s) after %ds.",
				total_players,
				auto_ready_delay
			))
		end
	elseif self.CustomSetupState.all_players_loaded_since ~= nil and ready_count < total_players then
		print("[XHS CustomSetup] Auto-ready timer reset because at least one player is no longer loaded.")
		self.CustomSetupState.all_players_loaded_since = nil
	end

	if total_players > 0 and ready_count >= total_players then
		local all_ready_deadline = current_time + ready_launch_delay

		-- Everyone is ready: start a short final countdown, but never extend
		-- an already shorter auto-launch timer.
		if self.CustomSetupState.deadline > all_ready_deadline then
			self.CustomSetupState.deadline = all_ready_deadline
			self.CustomSetupState.all_ready_triggered = true
		end
	end

	if current_time >= self.CustomSetupState.deadline then
		local launch_reason = "timeout"
		if self.CustomSetupState.auto_ready_triggered then
			launch_reason = "auto_ready"
		elseif self.CustomSetupState.all_ready_triggered then
			launch_reason = "all_ready"
		end

		self:FinishCustomSetup(launch_reason)
		return nil
	end

	self:PushCustomSetupNetTable()
	return 0.2
end

function GameMode:OnCustomSetupReady(event_source_index, keys)
	local payload = keys

	-- Ready state is bound to the authoritative event source. Never accept a
	-- PlayerID supplied by the client payload.
	if not payload then
		return
	end

	if not GameMode.CustomSetupState or not GameMode.CustomSetupState.active then
		return
	end

	local player_id = nil
	if api ~= nil and api.GetEventPlayerID ~= nil then
		local ok, sender_player_id = pcall(function()
			return api:GetEventPlayerID(event_source_index, nil)
		end)
		if ok then
			player_id = tonumber(sender_player_id)
		end
	end

	if player_id == nil or player_id < 0 then
		return
	end

	if not GameMode:IsPlayerEligibleForCustomSetupReady(player_id) then
		return
	end

	GameMode.CustomSetupState.ready_players[player_id] = true
	GameMode:PushCustomSetupNetTable()
end

function GameMode:OnBuyTomesRequested(event_source_index, keys)
	local payload = keys

	if type(event_source_index) == "table" and payload == nil then
		payload = event_source_index
	end

	if not payload then
		return
	end

	local player_id = -1

	if type(event_source_index) == "number" and event_source_index > 0 then
		local ok, sender = pcall(EntIndexToHScript, event_source_index)
		if ok and sender ~= nil and sender.GetPlayerID then
			local sender_player_id = sender:GetPlayerID()
			if sender_player_id ~= nil and sender_player_id >= 0 then
				player_id = sender_player_id
			end
		end
	end

	if player_id < 0 then
		player_id = tonumber(payload.PlayerID or -1) or -1
	end

	if player_id < 0 or not PlayerResource:IsValidPlayerID(player_id) then
		return
	end

	local player = PlayerResource:GetPlayer(player_id)
	if player == nil then
		return
	end

	self.XHSBuyTomeRequestTimes = self.XHSBuyTomeRequestTimes or {}
	local now = GameRules:GetGameTime()
	local last_request_time = self.XHSBuyTomeRequestTimes[player_id] or -999
	if now - last_request_time < 0.25 then
		return
	end
	self.XHSBuyTomeRequestTimes[player_id] = now

	return BuyMaxSmallTomesForPlayer(player_id)
end

function GameMode:OnToggleAutoBuyTomesRequested(event_source_index, keys)
	local payload = keys

	if type(event_source_index) == "table" and payload == nil then
		payload = event_source_index
	end

	if not payload then
		return
	end

	local player_id = -1
	if type(event_source_index) == "number" and event_source_index > 0 then
		local ok, sender = pcall(EntIndexToHScript, event_source_index)
		if ok and sender ~= nil and sender.GetPlayerID then
			player_id = tonumber(sender:GetPlayerID()) or -1
		end
	end

	if player_id < 0 then
		player_id = tonumber(payload.PlayerID or -1) or -1
	end

	if player_id < 0 or not PlayerResource:IsValidPlayerID(player_id) then
		return
	end

	local enabled = XHSIsTomeAutoBuyEnabled ~= nil and XHSIsTomeAutoBuyEnabled(player_id)
	return XHSSetTomeAutoBuyEnabled(player_id, not enabled)
end
