if GameMode == nil then
	_G.GameMode = class({})
end

require('addon_init')
require('events')
require('constants') -- in cause?

require('libraries/notifications')
require('libraries/animations')
require('libraries/fun')()
require('libraries/functional')
require('libraries/playerresource')
require('libraries/playertables')
require('libraries/gold')
require('libraries/rgb_to_hex')
require('libraries/corpses')

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
require('components/api/init')
if IsInToolsMode() then
	require('libraries/adv_log')
end
require('components/battlepass/init')
require('components/timers/init')

if GetMapName() == "x_hero_siege_demo" then
	require('components/hero_selection/init')
	require('components/demo/init')
end

-- new bosses system
require('boss_scripts/boss_functions')

function GameMode:OnFirstPlayerLoaded()
	BASE_GOOD = Entities:FindByName(nil, "base_spawn")
end

function GameMode:OnHeroInGame(hero)
	local id = hero:GetPlayerID()
	local point = Entities:FindByName(nil, "hero_selection_" .. id)

	if GetMapName() == "x_hero_siege_demo" then
		point = Entities:FindByName(nil, "npc_dota_spawner_good_mid_staging")
	end

	if hero:GetUnitName() == "npc_dota_hero_wisp" then
		hero:SetAbilityPoints(0)
		hero:SetGold(0, false)

		local delay = 2.0
		hero:AddNewModifier(hero, nil, "modifier_command_restricted", { duration = delay + 0.1 })

		hero:SetContextThink("delay_to_fix_camera_not_centering_lul", function()
			TeleportHero(hero, point:GetAbsOrigin(), 3.0)

			return nil
		end, delay)
	elseif hero:GetUnitName() == "npc_dota_hero_terrorblade" then
		if IsInToolsMode() then
			hero:IncrementAttributes(100000)
		end
	end

	hero:SetDayTimeVisionRange(XHS_HERO_VISION)
	hero:SetNightTimeVisionRange(XHS_HERO_VISION)

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
	GameRules:SetCustomGameSetupAutoLaunchDelay(10.0) --Vote Time
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
	if GetMapName() == "x_hero_siege_4" then
		GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS, 4)
	end
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

	CustomGameEventManager:RegisterListener("setting_vote", Dynamic_Wrap(GameMode, "OnSettingVote"))

	-- Initialized tables for tracking state
	GameMode.bSeenWaitForPlayers = false
	GameMode.vUserIds = {}
	GameMode.VoteTable = {}

	GameMode:OnFirstPlayerLoaded()

	mode:SetThink("OnThink", GameMode, 1)
	mode:SetModifyGoldFilter(Dynamic_Wrap(GameMode, "GoldFilter"), GameMode)
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

	CustomGameEventManager:RegisterListener("event_hero_image", Dynamic_Wrap(GameMode, "HeroImage"))
	CustomGameEventManager:RegisterListener("event_all_hero_images", Dynamic_Wrap(GameMode, "AllHeroImages"))
	CustomGameEventManager:RegisterListener("event_spirit_beast", Dynamic_Wrap(GameMode, "SpiritBeast"))
	CustomGameEventManager:RegisterListener("event_frost_infernal", Dynamic_Wrap(GameMode, "FrostInfernal"))
	CustomGameEventManager:RegisterListener("quit_event", Dynamic_Wrap(GameMode, "SpecialEventTPQuit2"))

	CustomGameEventManager:RegisterListener("dialog_complete", function(...) return GameMode:OnDialogEnded(...) end)
	CustomGameEventManager:RegisterListener("dialog_confirm", function(...) return GameMode:OnDialogConfirm(...) end)
	CustomGameEventManager:RegisterListener("dialog_confirm_expire",
		function(...) return GameMode:OnDialogConfirmExpired(...) end)

	ListenToGameEvent("dota_holdout_revive_complete", Dynamic_Wrap(GameMode, "OnPlayerRevived"), GameMode)

	--Dungeon
	GameMode.PrecachedVIPs = {}
	GameMode.CheckpointsActivated = {}
	GameMode.Zones = {}
end

local CheckTeamDeath = 0

function GameMode:OnThink()
	if GameRules:IsGamePaused() == true then return 1 end
	local newState = GameRules:State_Get()

	if newState >= DOTA_GAMERULES_STATE_PRE_GAME then
		if GetMapName() ~= "x_hero_siege_demo" then
			CustomTimers:Think()
		end
	end

	if newState >= DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		GameRules:SetTimeOfDay(0) -- always night
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
				-- Check for all players death in Phase 3
				if CustomTimers.game_phase == 3 then
					if Hero:IsAlive() then
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

	if CustomTimers.game_phase == 3 then
		if IsTeamAlive == false then
			CheckTeamDeath = CheckTeamDeath + 1
		else
			CheckTeamDeath = 0
		end
	end

	-- after 6 seconds of death for the whole team, end the game
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
	local flDamage = filterTable["damage"]

	if filterTable["entindex_attacker_const"] == nil then
		return true
	end

	local hAttackerHero = EntIndexToHScript(filterTable["entindex_attacker_const"])

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

function GameMode:HeroImage(event)
	local PlayerID = event.pID
	local player = PlayerResource:GetPlayer(PlayerID)
	local hero = player:GetAssignedHero()
	local point_hero = Entities:FindByName(nil, "hero_image_player")
	local point_beast = Entities:FindByName(nil, "hero_image_boss"):GetAbsOrigin()

	if GameMode.HeroImage_occuring == true then
		GameMode:SpecialEventTPQuit(hero)
		Notifications:Bottom(hero:GetPlayerOwnerID(),
			{ text = "Hero Image is already occuring, please choose another event.", duration = 7.5 })
	end

	if hero.hero_image then
		Notifications:Bottom(hero:GetPlayerOwnerID(), { text = "You can do hero image only once!", duration = 5.0 })
	else
		GameMode.HeroImage_occuring = true
		Entities:FindByName(nil, "trigger_special_event_back4"):Enable()
		CustomGameEventManager:Send_ServerToAllClients("show_timer_hero_image", {})
		CustomTimers.current_time["hero_image"] = SPECIAL_ARENA_DURATION

		GameMode.HeroImage = CreateUnitByName(hero:GetUnitName(), point_beast, true, nil, nil, DOTA_TEAM_CUSTOM_1)
		GameMode.HeroImage:SetAngles(0, 210, 0)

		GameMode.HeroImage:SetBaseStrength(hero:GetStrength() * 4)
		GameMode.HeroImage:SetBaseIntellect(hero:GetIntellect(true) * 4)
		GameMode.HeroImage:SetBaseAgility(hero:GetAgility() * 4)
		--		GameMode.HeroImage:SetHasInventory(true)

		for i = 0, GameMode.HeroImage:GetAbilityCount() - 1 do
			local ability = GameMode.HeroImage:GetAbilityByIndex(i)
			if ability then
				ability:SetLevel(ability:GetMaxLevel())
			end
		end

		for i = 0, 5 do
			local item = hero:GetItemInSlot(i)

			if item then
				local newItem = CreateItem(item:GetName(), GameMode.HeroImage, GameMode.HeroImage)
				GameMode.HeroImage:AddItem(newItem)
			end
		end

		GameMode.HeroImage:AddNewModifier(GameMode.HeroImage, nil, "modifier_pause_creeps", { Duration = 5, IsHidden = true })
		GameMode.HeroImage:AddNewModifier(GameMode.HeroImage, nil, "modifier_invulnerable", { Duration = 5, IsHidden = true })
		GameMode.HeroImage:MakeIllusion()
		GameMode.HeroImage:AddAbility("hero_image_death")
		GameMode.HeroImage.Boss = true
		GameMode.HeroImage:SetHealth(99999999)
		GameMode.HeroImage:SetMana(99999999)

		local ability = GameMode.HeroImage:FindAbilityByName("hero_image_death")
		ability:ApplyDataDrivenModifier(GameMode.HeroImage, GameMode.HeroImage, "modifier_hero_image", {})

		if IsValidEntity(hero) then
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				GameMode:SpecialEventTPQuit(hero)
				DisableItems(hero, SPECIAL_ARENA_DURATION)
				Notifications:Bottom(hero:GetPlayerOwnerID(),
					{ text = "Special Event: Kill Hero Image for +250 Stats. You have 2 minutes.", duration = 5.0 })
				TeleportHero(hero, point_hero:GetAbsOrigin())
			end
		end

		timers.HeroImage = Timers:CreateTimer(SPECIAL_ARENA_DURATION, function()
			Entities:FindByName(nil, "trigger_hero_image_duration"):Enable()
			GameMode.SpiritBeast_occuring = false

			Timers:CreateTimer(5.5, function() --Debug time in case Hero Image kills the player at the very last second
				Entities:FindByName(nil, "trigger_hero_image_duration"):Disable()
			end)
			if not GameMode.HeroImage:IsNull() then
				GameMode.HeroImage:RemoveSelf()
			else
			end
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
		Notifications:Bottom(hero:GetPlayerOwnerID(),
			{ text = "Spirit Beast is already occuring, please choose another event.", duration = 7.5 })
	elseif GameMode.SpiritBeast_killed == false then
		GameMode.SpiritBeast_occuring = true
		Entities:FindByName(nil, "trigger_special_event_back3"):Enable()
		CustomGameEventManager:Send_ServerToAllClients("show_timer_spirit_beast", {})
		CustomTimers.current_time["spirit_beast"] = SPECIAL_ARENA_DURATION

		timers.SpiritBeast = Timers:CreateTimer(SPECIAL_ARENA_DURATION, function()
			if Entities:FindByName(nil, "trigger_spirit_beast_duration") then
				Entities:FindByName(nil, "trigger_spirit_beast_duration"):Enable()
			end

			GameMode.SpiritBeast_occuring = false
			GameMode.spirit_beast:RemoveSelf()

			Timers:CreateTimer(5.5, function() --Debug time in case Spirit Beast kills the player at the very last second
				Entities:FindByName(nil, "trigger_spirit_beast_duration"):Disable()
			end)
		end)

		GameMode.spirit_beast = CreateUnitByName("npc_spirit_beast", point_beast, true, nil, nil, DOTA_TEAM_CUSTOM_1)
		GameMode.spirit_beast:SetAngles(0, 210, 0)
		GameMode.spirit_beast:AddNewModifier(GameMode.spirit_beast, nil, "modifier_pause_creeps", { Duration = 5, IsHidden = true })
		GameMode.spirit_beast:AddNewModifier(GameMode.spirit_beast, nil, "modifier_invulnerable", { Duration = 5, IsHidden = true })
		GameMode.spirit_beast.Boss = true

		if IsValidEntity(hero) then
			GameMode:SpecialEventTPQuit(hero)
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
		Notifications:Bottom(hero:GetPlayerOwnerID(),
			{ text = "Frost Infernal is already occuring, please choose another event.", duration = 7.5 })
	elseif GameMode.FrostInfernal_killed == false then
		GameMode.FrostInfernal_occuring = true
		Entities:FindByName(nil, "trigger_special_event_back2"):Enable()
		CustomGameEventManager:Send_ServerToAllClients("show_timer_frost_infernal", {})
		CustomTimers.current_time["frost_infernal"] = SPECIAL_ARENA_DURATION

		timers.FrostInfernal = Timers:CreateTimer(SPECIAL_ARENA_DURATION, function()
			if Entities:FindByName(nil, "trigger_frost_infernal_duration") then
				Entities:FindByName(nil, "trigger_frost_infernal_duration"):Enable()
			end

			GameMode.FrostInfernal_occuring = false
			GameMode.frost_infernal:RemoveSelf()

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

		GameMode:SpecialEventTPQuit(hero)
		Notifications:Bottom(hero:GetPlayerOwnerID(),
			{ text = "Special Event: Kill Frost Infernal for the Key of the 3 Moons. You have 2 minutes.", duration = 5.0 })

		if IsValidEntity(hero) then
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				TeleportHero(hero, point_hero:GetAbsOrigin())
			end
		end

		DisableItems(hero, SPECIAL_ARENA_DURATION)
	else
		Notifications:Bottom(hero:GetPlayerOwnerID(), { text = "Frost Infernal has already been killed!", duration = 5.0 })
	end
end

function GameMode:AllHeroImages(event)
	local PlayerID = event.pID
	local player = PlayerResource:GetPlayer(PlayerID)
	local hero = player:GetAssignedHero()
	local point = Entities:FindByName(nil, "all_hero_image_player")

	if GameMode.AllHeroImagesDead == true then
		Notifications:Bottom(hero:GetPlayerOwnerID(), { text = "All Hero Image has already been done!", duration = 5.0 })
		return
	end

	if GameMode.AllHeroImages_occuring == true then
		Notifications:Bottom(hero:GetPlayerOwnerID(),
			{ text = "All Hero Images is already occuring, please choose another event.", duration = 7.5 })
	elseif GameMode.AllHeroImages_occuring == false then
		GameMode.AllHeroImages_occuring = true
		Entities:FindByName(nil, "trigger_special_event_back5"):Enable()
		CustomGameEventManager:Send_ServerToAllClients("show_timer_all_hero_image", {})
		CustomTimers.current_time["all_hero_images"] = SPECIAL_ARENA_DURATION

		local illusion_spawn = 0
		Timers:CreateTimer(0.25, function()
			local random = RandomInt(1, #HEROLIST)
			illusion_spawn = illusion_spawn + 1
			local point_image = Entities:FindByName(nil, "special_event_all_" .. illusion_spawn)
			GameMode.AllHeroImage = CreateUnitByName("npc_dota_hero_" .. HEROLIST[random], point_image:GetAbsOrigin(),
				true, nil, nil, DOTA_TEAM_CUSTOM_2)
			GameMode.AllHeroImage:SetAngles(0, 45 - 45 * illusion_spawn, 0)

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

			local return_time = nil

			if illusion_spawn < 8 then
				return_time = 0.2
			end

			return return_time
		end)

		if IsValidEntity(hero) then
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				GameMode:SpecialEventTPQuit(hero)
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
			ALL_HERO_IMAGE_DEAD = 0
			local units = FindUnitsInRadius(DOTA_TEAM_CUSTOM_2, point:GetAbsOrigin(), nil, 2500,
				DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER,
				false)
			for _, unit in pairs(units) do
				ALL_HERO_IMAGE_DEAD = ALL_HERO_IMAGE_DEAD + 1
			end

			if ALL_HERO_IMAGE_DEAD == 0 then
				GameMode.AllHeroImagesDead = true
				DoEntFire("trigger_all_hero_image_duration", "Kill", nil, 0, nil, nil)
				CustomGameEventManager:Send_ServerToAllClients("hide_timer_all_hero_image", {})
				Timers:RemoveTimer(timers.AllHeroImage)
				Timers:RemoveTimer(timers.AllHeroImage2)
				Timers:CreateTimer(0.5, function()
					local pos = Entities:FindByName(nil, "all_hero_image_player"):GetAbsOrigin()
					DropNeutralItemAtPositionForHero("item_necklace_of_spell_immunity", pos, hero, hero:GetTeam(), true)
				end)
				return nil
			end
			return 1.0
		end)

		timers.AllHeroImage2 = Timers:CreateTimer(SPECIAL_ARENA_DURATION, function()
			Entities:FindByName(nil, "trigger_all_hero_image_duration"):Enable()
			GameMode.AllHeroImages_occuring = false

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
	Entities:FindByName(nil, "trigger_special_event"):Enable()
	hero:RemoveModifierByName("modifier_pause_creeps")
	hero:RemoveModifierByName("modifier_invulnerable")
	EnableItems(hero)
end

function GameMode:SpecialEventTPQuit2(event)
	local PlayerID = event.pID
	local player = PlayerResource:GetPlayer(PlayerID)
	local hero = player:GetAssignedHero()

	hero:Stop()
	hero:RemoveModifierByName("modifier_pause_creeps")
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

-- new system, double votes for donators
ListenToGameEvent('game_rules_state_change', function(keys)
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_HERO_SELECTION then
		-- If no one voted, default to IMBA 10v10 gamemode

		if api then
			api:SetCustomGamemode(1)
			api:SetCustomDifficulty(1)
		else
			GameRules:SetCustomGameDifficulty(2)
		end

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
			if category == "gamemode" then
				api:SetCustomGamemode(highest_key)
			elseif category == "difficulty" then
				api:SetCustomDifficulty(highest_key)
			end

			-- print(category .. ": " .. highest_key)
		end
	end
end, nil)

local donator_list = {}
donator_list[1] = 5 -- Lead-Dev
donator_list[2] = 5 -- Dev
-- donator_list[3] = 5 -- Administrator
donator_list[4] = 1 -- Ember Donator
donator_list[7] = 2 -- Salamander Donator
donator_list[8] = 3 -- Icefrog Donator
donator_list[9] = 3 -- Gaben Donator

function GameMode:OnSettingVote(keys)
	local pid = keys.PlayerID

	print(keys)

	if not GameMode.VoteTable then GameMode.VoteTable = {} end
	if not GameMode.VoteTable[keys.category] then GameMode.VoteTable[keys.category] = {} end

	if pid >= 0 then
		if not GameMode.VoteTable[keys.category][pid] then GameMode.VoteTable[keys.category][pid] = {} end

		GameMode.VoteTable[keys.category][pid][1] = keys.vote

		if api then
			if donator_list[api:GetDonatorStatus(pid)] then
				GameMode.VoteTable[keys.category][pid][2] = donator_list[api:GetDonatorStatus(pid)]
			else
				GameMode.VoteTable[keys.category][pid][2] = 1
			end
		end
	end

	--	GameRules:SendCustomMessage(keys.category, 0, 0)
	--	GameRules:SendCustomMessage(tostring(keys.vote), 0, 0)

	-- TODO: Finish votes show up
	CustomGameEventManager:Send_ServerToAllClients("send_votes",
		{ category = keys.category, vote = keys.vote, table = GameMode.VoteTable[keys.category] })
end
