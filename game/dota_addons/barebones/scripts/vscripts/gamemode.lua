if GameMode == nil then
	_G.GameMode = class({})
end

require('events')
require('internal/gamemode')
require('internal/events')
require('constants')
require('libraries/timers')
require('libraries/physics')
require('libraries/projectiles')
require('libraries/notifications')
require('libraries/animations')
require('libraries/attachments')
require('libraries/keyvalues')
require('libraries/illusionmanager')
require('libraries/fun')()
require('libraries/functional')
require('libraries/playerresource')
require('libraries/playertables')
require('libraries/gold')
require('phases/choose_hero')
require('phases/creeps')
require('phases/special_events')
require('phases/phase1')
require('phases/phase2')
require('phases/phase3')
require('zones/zones')
require('units/breakable_container_surprises')
require('units/treasure_chest_surprises')
require('triggers')
require('items/global')
require('api/api')

-- new bosses system
require('boss_scripts/boss_functions')

function GameMode:OnFirstPlayerLoaded()
	base_good = Entities:FindByName(nil, "base_spawn_goodguys")
end

function GameMode:OnAllPlayersLoaded()
	for playerID = 0, PlayerResource:GetPlayerCount() -1 do
		if PlayerResource:IsValidPlayer(playerID) then
			PlayerResource:SetCustomPlayerColor(playerID, PLAYER_COLORS[playerID][1], PLAYER_COLORS[playerID][2], PLAYER_COLORS[playerID][3])
		end
	end

	Timers:CreateTimer(3.0, function()
		EmitSoundOn("Global.InGame", base_good)

--		if base_bad then
--			EmitSoundOn("Global.InGame", base_bad)
--		end
	end)
end

function GameMode:OnHeroInGame(hero)
local id = hero:GetPlayerID()
local point = Entities:FindByName(nil, "hero_selection_"..id)

	if hero:GetUnitName() == "npc_dota_hero_wisp" then
		hero:SetAbilityPoints(0)
		hero:SetGold(0, false)
		hero:AddNewModifier(nil, nil, "modifier_boss_stun", {Duration = 15.0, IsHidden = true})
		PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), hero)
		Timers:CreateTimer(15.0, function()
			FindClearSpaceForUnit(hero, point:GetAbsOrigin(), true)
			hero:Stop()
			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), nil)
			end)
		end)
	elseif hero:GetUnitName() == "npc_dota_hero_terrorblade" then
		if IsInToolsMode() then
			hero:ModifyStrength(10000)
			hero:ModifyAgility(10000)
			hero:ModifyIntellect(10000)
		end
	end
end

function GameMode:InitGameMode()
	GameMode = self
	mode = GameRules:GetGameModeEntity()

	-- Timer Rules
	GameRules:SetPostGameTime(60.0)
	GameRules:SetTreeRegrowTime(240.0)
	GameRules:SetHeroSelectionTime(0.0)
	GameRules:SetGoldTickTime(0.0)
	GameRules:SetGoldPerTick(0.0)
	GameRules:SetCustomGameSetupAutoLaunchDelay(10.0) --Vote Time
	GameRules:SetPreGameTime(PREGAMETIME)

	--Disabling Derived Stats
	mode:SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_STRENGTH_MAGIC_RESISTANCE_PERCENT, 0)

	mode:SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_AGILITY_MOVE_SPEED_PERCENT, 0)

	-- Overriding Derived Stats
--	mode:SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_STRENGTH_HP_REGEN_PERCENT, 0.0025)
	mode:SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_AGILITY_ARMOR, 0) -- default: 0.016 armor per agility point
	mode:SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_INTELLIGENCE_SPELL_AMP_PERCENT, 0.075)

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

	-- Value Rules
	mode:SetCameraDistanceOverride(1250)
	mode:SetMaximumAttackSpeed(500)
	mode:SetMinimumAttackSpeed(20)
	mode:SetCustomHeroMaxLevel(20)
	GameRules:SetHeroMinimapIconScale(1.0)
	GameRules:SetCreepMinimapIconScale(1)
	GameRules:SetRuneMinimapIconScale(1)

	-- Team Rules
	SetTeamCustomHealthbarColor(DOTA_TEAM_GOODGUYS, 0, 64, 128) --Blue
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
	LinkLuaModifier("modifier_earthquake_aura", "heroes/hero_brewmaster", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_command_restricted", "modifiers/modifier_command_restricted", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_ai", "modifiers/modifier_ai", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_breakable_container", "modifiers/modifier_breakable_container", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_creature_techies_land_mine", "modifiers/modifier_creature_techies_land_mine", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_lifesteal", "modifiers/modifier_lifesteal.lua", LUA_MODIFIER_MOTION_NONE)

	GameMode:_InitGameMode()
	self:OnFirstPlayerLoaded()

	mode:SetThink( "OnThink", self, 1 )
	mode:SetModifyGoldFilter( Dynamic_Wrap(GameMode, "GoldFilter"), self )

	if IsInToolsMode() then
		Convars:RegisterCommand("duel_event", function(keys) return DuelEvent() end, "Test Duel Event", FCVAR_CHEAT)
		Convars:RegisterCommand("magtheridon", function(keys) return StartMagtheridonArena() end, "Test Magtheridon Boss", FCVAR_CHEAT)
		Convars:RegisterCommand("banehallow", function(keys) return StartBanehallowArena() end, "Test Magtheridon Boss", FCVAR_CHEAT)
		Convars:RegisterCommand("r&b", function(keys) return RameroAndBaristolEvent() end, "Test Ramero and Baristol Arena", FCVAR_CHEAT)
		Convars:RegisterCommand("r", function(keys) return RameroEvent() end, "Test Ramero Arena", FCVAR_CHEAT)
		Convars:RegisterCommand("farm_event", function(keys) return FarmTest() end, "Test Farm Event", FCVAR_CHEAT)
	end

	mode:SetExecuteOrderFilter(Dynamic_Wrap(GameMode, "FilterExecuteOrder"), self)
	mode:SetDamageFilter(Dynamic_Wrap(GameMode, "DamageFilter"), self)
	mode:SetHealingFilter(Dynamic_Wrap(GameMode, "HealingFilter"), self)

	CustomGameEventManager:RegisterListener("event_hero_image", Dynamic_Wrap(GameMode, "HeroImage"))
	CustomGameEventManager:RegisterListener("event_all_hero_images", Dynamic_Wrap(GameMode, "AllHeroImages"))
	CustomGameEventManager:RegisterListener("event_spirit_beast", Dynamic_Wrap(GameMode, "SpiritBeast"))
	CustomGameEventManager:RegisterListener("event_frost_infernal", Dynamic_Wrap(GameMode, "FrostInfernal"))
	CustomGameEventManager:RegisterListener("quit_event", Dynamic_Wrap(GameMode, "SpecialEventTPQuit2"))

	CustomGameEventManager:RegisterListener( "dialog_complete", function(...) return self:OnDialogEnded( ... ) end )
	CustomGameEventManager:RegisterListener( "dialog_confirm", function(...) return self:OnDialogConfirm( ... ) end )
	CustomGameEventManager:RegisterListener( "dialog_confirm_expire", function(...) return self:OnDialogConfirmExpired( ... ) end )

	ListenToGameEvent("dota_holdout_revive_complete", Dynamic_Wrap(GameMode, "OnPlayerRevived"), self)

	--Dungeon
	self.PrecachedVIPs = {}
	self.CheckpointsActivated = {}
	self.Zones = {}

	-- Item added to inventory filter
	mode:SetItemAddedToInventoryFilter(function(ctx, event)
		local hero = EntIndexToHScript(event.inventory_parent_entindex_const)
		if hero:IsRealHero() then if hero:GetPlayerID() == -1 then return end end
		local item = EntIndexToHScript(event.item_entindex_const)
		local key = "item_key_of_the_three_moons"
		local shield = "item_shield_of_invincibility"
		local sword = "item_lightning_sword"
		local ring = "item_ring_of_superiority"
		local doom = "item_doom_artifact"
		local frost = "item_orb_of_frost"
		if item:GetAbilityName() == "item_tpscroll" and item:GetPurchaser() == nil then return false end

		if hero:IsRealHero() then
			if hero:GetUnitName() == "npc_baristol" then return end
			if hero:GetTeamNumber() == 2 or hero:GetTeamNumber() == 3 then
				if item:GetName() == sword and sword_first_time then
					SPECIAL_EVENT = 0
					CustomGameEventManager:Send_ServerToAllClients("hide_timer_special_arena", {})
					GameMode.SpecialArena_occuring = 0
					if timers.RameroAndBaristol then
						Timers:RemoveTimer(timers.RameroAndBaristol)
					end
					local teleport_time = 3.0
					RestartCreeps(teleport_time + 3)
					sword_first_time = false
					if hero.old_pos then
						TeleportHero(hero, teleport_time, hero.old_pos)
					else
						if hero:GetTeamNumber() == 2 then
							TeleportHero(hero, 3.0, base_good:GetAbsOrigin())
--						elseif hero:GetTeamNumber() == 3 then
--							TeleportHero(hero, 3.0, base_bad:GetAbsOrigin())
						end
					end
					hero:EmitSound("Hero_TemplarAssassin.Trap")
				end
				if item:GetName() == ring and ring_first_time then
					SPECIAL_EVENT = 0
					CustomGameEventManager:Send_ServerToAllClients("hide_timer_special_arena", {})
					GameMode.SpecialArena_occuring = 0
					if timers.Ramero then
						Timers:RemoveTimer(timers.Ramero)
					end
					local teleport_time = 3.0
					RestartCreeps(teleport_time + 3)
					ring_first_time = false
					if hero.old_pos then
						TeleportHero(hero, teleport_time, hero.old_pos)
					else
						if hero:GetTeamNumber() == 2 then
							TeleportHero(hero, 3.0, base_good:GetAbsOrigin())
--						elseif hero:GetTeamNumber() == 3 then
--							TeleportHero(hero, 3.0, base_bad:GetAbsOrigin())
						end
					end
					hero:EmitSound("Hero_TemplarAssassin.Trap")
				end
				if item:GetName() == frost and frost_first_time then
					frost_first_time = false
					if hero.old_pos then
						TeleportHero(hero, 3.0, hero.old_pos)
					else
						if hero:GetTeamNumber() == 2 then
							TeleportHero(hero, 3.0, base_good:GetAbsOrigin())
--						else
--							TeleportHero(hero, 3.0, base_bad:GetAbsOrigin())
						end
					end
					hero:EmitSound("Hero_TemplarAssassin.Trap")
--				elseif item:GetName() == frost and frost_first_time == false then
--					return false
				end
			end

--			if item:GetName() == key and hero.has_epic_1 == false then
--				hero.has_epic_1 = true
--				hero:EmitSound("Hero_TemplarAssassin.Trap")
--			end
--			if item:GetName() == shield and hero.has_epic_2 == false then
--				hero.has_epic_2 = true
--				hero:EmitSound("Hero_TemplarAssassin.Trap")
--			end
--			if item:GetName() == sword and hero.has_epic_3 == false then
--				hero.has_epic_3 = true
--				hero:EmitSound("Hero_TemplarAssassin.Trap")
--			end
--			if item:GetName() == ring and hero.has_epic_4 == false then
--				hero.has_epic_4 = true
--				hero:EmitSound("Hero_TemplarAssassin.Trap")
--			end

			if item:GetName() == doom and doom_first_time then
				doom_first_time = false
				hero:EmitSound("Hero_TemplarAssassin.Trap")
				local line_duration = 10
				Notifications:TopToAll({hero = hero:GetName(), duration = line_duration})
--				Notifications:TopToAll({text = hero:GetUnitName().." ", duration = line_duration, continue = true})
				Notifications:TopToAll({text = PlayerResource:GetPlayerName(hero:GetPlayerID()).." ", duration = line_duration, continue = true})
				Notifications:TopToAll({text = "merged the 4 Boss items to create Doom Artifact!", duration = line_duration, style = {color = "Red"}, continue = true})
--			elseif item:GetName() == doom and frost_first_time == false then
--				return false
			end

			-- Rune System
			if item:GetName() == "item_rune_armor" then
				PickupArmorRune(item, hero)
				return false
			elseif item:GetName() == "item_rune_immolation" then
				PickupImmolationRune(item, hero)
				return false
			end
		end

		if hero:IsRealHero() or hero:IsConsideredHero() then
			-- Rune System
			if item:GetName() == "item_rune_armor" then
				PickupArmorRune(item, hero)
				return false
			elseif item:GetName() == "item_rune_immolation" then
				PickupImmolationRune(item, hero)
				return false
			end
		end
    	return true
	end, self)
end

function FarmTest()
	SPECIAL_EVENT = 1
	FarmEvent(180)
end

function GameMode:OnGameRulesStateChange(keys)
local newState = GameRules:State_Get()

	CustomGameEventManager:Send_ServerToAllClients( 'game_state', {
		newState = newState
	})

	if newState == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		ApiLoad()
	end

	if newState == DOTA_GAMERULES_STATE_HERO_SELECTION then
		GameRules:SetCustomGameDifficulty(2)
		local mode  = GameMode
		local votes = mode.VoteTable

		for category, pidVoteTable in pairs(votes) do
			-- Tally the votes into a new table
			local voteCounts = {}
			for pid, vote in pairs(pidVoteTable) do
				if not voteCounts[vote] then voteCounts[vote] = 0 end
				voteCounts[vote] = voteCounts[vote] + 1
			end

			-- Find the key that has the highest value (key=vote value, value=number of votes)
			local highest_vote = 0
			local highest_key = ""
			for k, v in pairs(voteCounts) do
				if v > highest_vote then
					highest_key = k
					highest_vote = v
				end
			end

			-- Check for a tie by counting how many values have the highest number of votes
			local tieTable = {}
			for k, v in pairs(voteCounts) do
				if v == highest_vote then
					table.insert(tieTable, k)
				end
			end

			-- Resolve a tie by selecting a random value from those with the highest votes
			if table.getn(tieTable) > 1 then
				--print("TIE!")
				highest_key = tieTable[math.random(table.getn(tieTable))]
			end

			-- Act on the winning vote
			if category == "difficulty" then
				GameRules:SetCustomGameDifficulty(highest_key)
			end
			print(category .. ": " .. highest_key)
		end
	end

	if newState == DOTA_GAMERULES_STATE_PRE_GAME then
		Gold:Init()
		nTimer_GameTime = PREGAMETIME

		if nTimer_GameTime == 10 then
			ChooseRandomHero(event)
		end

		for i = 1, 8 do
			DoEntFire("door_lane"..i, "SetAnimation", "gate_02_close", 0, nil, nil)
		end

		SpawnHeroesBis()

		-- debug
		if IsInToolsMode() then
			Entities:FindByName(nil, "trigger_special_event_tp_off"):Disable()
			Entities:FindByName(nil, "trigger_special_event"):Enable()
		end

		local diff = {"Easy", "Normal", "Hard", "Extreme", "Divine"}
		local lanes = {"Simple", "Double", "Full"}
		local Color = {"green", "Yellow", "orange", "red", "darkred"}
		Timers:CreateTimer(3.0, function()
			CustomGameEventManager:Send_ServerToAllClients("show_timer_bar", {})
			Notifications:TopToAll({text="DIFFICULTY: "..diff[GameRules:GetCustomGameDifficulty()], color = Color[GameRules:GetCustomGameDifficulty()], duration=10.0})
		end)

		AddFOWViewer(DOTA_TEAM_GOODGUYS, Vector(6528, 1152, 192), 900, 99999, false)
		AddFOWViewer(DOTA_TEAM_CUSTOM_2, Vector(6528, 1152, 192), 900, 99999, false)

		require('zones/dialog_ep_1')
		require('zones/zone_tables_ep_1')
		self:SetupZones()
	end

	if newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		print("OnGameRulesStateChange: Game In Progress")

		GAME_WINNER_TEAM = "Dire"
		nTimer_SpecialEvent = 720
		nTimer_IncomingWave = 240
		nTimer_CreepLevel = 360
--		ModifyLanes()

		local ice_towers = Entities:FindAllByName("npc_tower_death")
		for _, tower in pairs(ice_towers) do
			tower:AddNewModifier(nil, nil, "modifier_invulnerable", nil)
		end

		for TW = 1, 2 do
			local ice_towers_main = Entities:FindByName(nil, "npc_tower_cold_"..TW)
			ice_towers_main:AddNewModifier(nil, nil, "modifier_invulnerable", nil)
			ice_towers_main.zone = "xhs_holdout"
		end

		-- Make towers invulnerable again
		for Players = 1, 8 do
			local towers = Entities:FindAllByName("dota_badguys_tower"..Players)
			for _, tower in pairs(towers) do
				tower:AddNewModifier(nil, nil, "modifier_invulnerable", nil)
			end
			local raxes = Entities:FindAllByName("dota_badguys_barracks_"..Players)
			for _, rax in pairs(raxes) do
				rax.zone = "xhs_holdout"
				rax:AddNewModifier(nil, nil, "modifier_invulnerable", nil)
			end
		end

		for NumPlayers = 1, PlayerResource:GetPlayerCount() * CREEP_LANES_TYPE do
			CREEP_LANES[NumPlayers][1] = 1
			local DoorObs = Entities:FindAllByName("obstruction_lane"..NumPlayers)
			for _, obs in pairs(DoorObs) do
				obs:SetEnabled(false, true)
			end
			DoEntFire("door_lane"..NumPlayers, "SetAnimation", "gate_02_open", 0, nil, nil)
			local towers = Entities:FindAllByName("dota_badguys_tower"..NumPlayers)
			for _, tower in pairs(towers) do
				tower:RemoveModifierByName("modifier_invulnerable")
			end
		end

		-- Timer: Creep Levels 1 to 4. Lanes 1 to 8.
		Timers:CreateTimer(0, function()
			if PHASE == 3 then
				print("Creeps Timer killed, Phase 3.")
				return nil
			elseif SPECIAL_EVENT == 0 then
				SpawnCreeps()
			elseif SPECIAL_EVENT ~= 0 then
				print("Creeps paused, Special Event.")
			end

			return 30
		end)
	end

	if newState == DOTA_GAMERULES_STATE_POST_GAME then
		-- call imba api
		api.imba.event(api.events.entered_post_game)

		api.imba.complete(function (error, players)
			safe(function ()
				if error then
					-- if we have an error we should display the scoreboard anyways, just with reduced data
					CustomGameEventManager:Send_ServerToAllClients("end_game_scoreboard", {
						players = {},
						xp_info = {},
						info = {
							winner = GAME_WINNER_TEAM,
							id = 0
						},
						error = true
					})
				else
					-- everything went fine. use the old system for xp
					local xp_info = {}

					for i = 1, #players do
						local player = players[i]

						local level = GetXPLevelByXp(player.xp)
						local title = GetTitleIXP(level)
						local color = GetTitleColorIXP(title, true)
						local progress = GetXpProgressToNextLevel(player.xp)

						if level and title and color and progress then
							table.insert(xp_info, {
								steamid = player.steamid,
								level = level,
								title = title,
								color = color,
								progress = progress
							})
						end

						-- i-1 should be replaced by player ID
						player.potion = CustomNetTables:GetTableValue("zone_scores", "xhs_holdout")[i-1]["Potions"]
					end

					CustomGameEventManager:Send_ServerToAllClients("end_game", {
						players = players,
						xp_info = xp_info,
						info = {
							winner = GAME_WINNER_TEAM,
							id = api.imba.data.id,
							radiant_score = GetTeamHeroKills(2),
						},
						error = false
					})
				end
			end)
		end)

--		CustomNetTables:SetTableValue("game_options", "game_count", {value = 0})
		CustomGameEventManager:Send_ServerToAllClients("end_game", {})
	end
end

function GameMode:OnThink()
local newState = GameRules:State_Get()
if GameRules:IsGamePaused() == true then return 1 end
if not reg then reg = 1 end
if not poi then poi = 1 end

local Region = {
	"Incoming wave of Darkness from the West",
	"Incoming wave of Darkness from the North",
	"Muradin Event in 30 sec",
	"Incoming wave of Darkness from the South",
	"Incoming wave of Darkness from the West",
	"Farming Event in 30 sec",
	"Incoming wave of Darkness from the East",
	"Incoming wave of Darkness from the South"
}

	GameTimer()

	if newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		if SPECIAL_EVENT == 0 then
			CountdownTimerIncomingWave()
			CountdownTimerCreepLevel()
		end
		if GameMode.SpecialArena_occuring == 1 then
			CountdownTimerSpecialArena()
		else
			CountdownTimerMuradin()
		end
		if GameMode.HeroImage_occuring == 1 then
			CountdownTimerHeroImage()
		end
		if GameMode.SpiritBeast_occuring == 1 then
			CountdownTimerSpiritBeast()
		end
		if GameMode.FrostInfernal_occuring == 1 then
			CountdownTimerFrostInfernal()
		end
		if GameMode.AllHeroImages_occuring == 1 then
			CountdownTimerAllHeroImage()
		end

		if PHASE ~= 3 then
			if nTimer_GameTime == 359 then -- 6 Min
				NumPlayers = 1, PlayerResource:GetPlayerCount() * CREEP_LANES_TYPE
				SpawnDragons("npc_dota_creature_red_dragon")
				CreepLevels(2)
			elseif nTimer_GameTime == 715 then -- 715 - 11:55 Min: MURADIN BRONZEBEARD EVENT 1
				nTimer_GameTime = 720 -1
				nTimer_IncomingWave = 240 +1 --	+1
				nTimer_CreepLevel = 360 +1
				RefreshPlayers()
				Timers:CreateTimer(1, function()
					SPECIAL_EVENT = 1
					PauseCreeps()
					PauseHeroes()
					Timers:CreateTimer(5, function()
						MuradinEvent(120)
						Timers:CreateTimer(3, RestartHeroes())
					end)
				end)
			elseif nTimer_GameTime == 721 then --12:00, Muradin End
				EndMuradinEvent()
				NumPlayers = 1, PlayerResource:GetPlayerCount() * CREEP_LANES_TYPE
				SpawnDragons("npc_dota_creature_black_dragon")
				CreepLevels(3)
			elseif nTimer_GameTime == 726 then --12:05, Muradin End
				EndMuradinEvent()
			elseif nTimer_GameTime == 839 then -- 14 Min
				
			elseif nTimer_GameTime == 1079 then -- 18 Min
				NumPlayers = 1, PlayerResource:GetPlayerCount() * CREEP_LANES_TYPE
				SpawnDragons("npc_dota_creature_green_dragon")
				CreepLevels(4)
			elseif nTimer_GameTime == 1435 then -- 1435 - 23:55 Min: FARM EVENT 2
				nTimer_GameTime = 1439
				nTimer_IncomingWave = 241 -- +1
				RefreshPlayers()
				Timers:CreateTimer(1, function()
					SPECIAL_EVENT = 1
					PauseCreeps()
					PauseHeroes()
					Timers:CreateTimer(5, function()
						FarmEvent(180)
						Timers:CreateTimer(3, RestartHeroes())
					end)
				end)
			end
		end

		if nTimer_CreepLevel <= 0 then nTimer_CreepLevel = 1 end
		if nTimer_SpecialEvent <= 0 then nTimer_SpecialEvent = 1 end
		if nTimer_SpecialArena <= 0 then nTimer_SpecialArena = 1 end

		if nTimer_IncomingWave <= 0 then
			nTimer_IncomingWave = 1
		elseif nTimer_IncomingWave == 1 then
			Timers:CreateTimer(1.0, function()
				SpecialWave()
			end)
		elseif nTimer_IncomingWave == 30 and reg <= 8 then
			Notifications:TopToAll({text="WARNING: "..Region[reg].."!", duration=25.0, style={color="red"}})
			SpawnRunes()
			reg = reg + 1
		elseif nTimer_GameTime > 2140 then
			nTimer_IncomingWave = 240
		end
	end

	for _,Zone in pairs(self.Zones) do
		if Zone ~= nil then
			Zone:OnThink()
		end
	end

	for i,Zone in pairs(self.Zones) do
		if not Zone.bNoLeaderboard then
			local netTable = {}
			netTable["ZoneName"] = Zone.szName
			CustomNetTables:SetTableValue("zone_names", string.format("%d", i), netTable)
		end
	end

	for nPlayerID = 0, (PlayerResource:GetPlayerCount() - 1) do
		if PlayerResource:GetTeam(nPlayerID) == DOTA_TEAM_GOODGUYS then
			local Hero = PlayerResource:GetSelectedHeroEntity(nPlayerID)
			if Hero then
				for _,Zone in pairs(self.Zones) do
					if Zone and Zone:ContainsUnit(Hero) then
						local netTable = {}
						netTable["ZoneName"] = Zone.szName
						CustomNetTables:SetTableValue("player_zone_locations", string.format("%d", nPlayerID), netTable)
					end
				end
			end
		end
	end
	return 1
end

function GameTimer()
local newState = GameRules:State_Get()
	if newState == DOTA_GAMERULES_STATE_PRE_GAME then
		nTimer_GameTime = nTimer_GameTime - 1
	elseif newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		if SPECIAL_EVENT == 0 then
			nTimer_GameTime = nTimer_GameTime + 1
		end
	end
	local t = nTimer_GameTime
	local minutes = math.floor(t / 60)
	local seconds = t - (minutes * 60)
	local m10 = math.floor(minutes / 10)
	local m01 = minutes - (m10 * 10)
	local s10 = math.floor(seconds / 10)
	local s01 = seconds - (s10 * 10)
	local broadcast_gametimer = 
		{
			timer_minute_10 = m10,
			timer_minute_01 = m01,
			timer_second_10 = s10,
			timer_second_01 = s01,
		}
	CustomGameEventManager:Send_ServerToAllClients("timer_game", broadcast_gametimer)
end

function CountdownTimerMuradin()
	nTimer_SpecialEvent = nTimer_SpecialEvent - 1
	local t = nTimer_SpecialEvent
	local minutes = math.floor(t / 60)
	local seconds = t - (minutes * 60)
	local m10 = math.floor(minutes / 10)
	local m01 = minutes - (m10 * 10)
	local s10 = math.floor(seconds / 10)
	local s01 = seconds - (s10 * 10)
	local broadcast_gametimer = 
		{
			timer_minute_10 = m10,
			timer_minute_01 = m01,
			timer_second_10 = s10,
			timer_second_01 = s01,
		}
	CustomGameEventManager:Send_ServerToAllClients("timer_special_event", broadcast_gametimer)
--	if t <= 120 then
--		CustomGameEventManager:Send_ServerToAllClients("time_remaining", broadcast_gametimer)
--	end
end

function CountdownTimerIncomingWave()
	nTimer_IncomingWave = nTimer_IncomingWave - 1
	local t = nTimer_IncomingWave
	local minutes = math.floor(t / 60)
	local seconds = t - (minutes * 60)
	local m10 = math.floor(minutes / 10)
	local m01 = minutes - (m10 * 10)
	local s10 = math.floor(seconds / 10)
	local s01 = seconds - (s10 * 10)
	local broadcast_gametimer = 
		{
			timer_minute_10 = m10,
			timer_minute_01 = m01,
			timer_second_10 = s10,
			timer_second_01 = s01,
		}
	CustomGameEventManager:Send_ServerToAllClients("timer_incoming_wave", broadcast_gametimer)
end

function CountdownTimerCreepLevel()
	nTimer_CreepLevel = nTimer_CreepLevel - 1
	local t = nTimer_CreepLevel
	local minutes = math.floor(t / 60)
	local seconds = t - (minutes * 60)
	local m10 = math.floor(minutes / 10)
	local m01 = minutes - (m10 * 10)
	local s10 = math.floor(seconds / 10)
	local s01 = seconds - (s10 * 10)
	local broadcast_gametimer = 
		{
			timer_minute_10 = m10,
			timer_minute_01 = m01,
			timer_second_10 = s10,
			timer_second_01 = s01,
		}
	CustomGameEventManager:Send_ServerToAllClients("timer_creep_level", broadcast_gametimer)
end

function CountdownTimerSpecialArena()
	nTimer_SpecialArena = nTimer_SpecialArena - 1
	local t = nTimer_SpecialArena
	local minutes = math.floor(t / 60)
	local seconds = t - (minutes * 60)
	local m10 = math.floor(minutes / 10)
	local m01 = minutes - (m10 * 10)
	local s10 = math.floor(seconds / 10)
	local s01 = seconds - (s10 * 10)
	local broadcast_gametimer = 
		{
			timer_minute_10 = m10,
			timer_minute_01 = m01,
			timer_second_10 = s10,
			timer_second_01 = s01,
		}
	CustomGameEventManager:Send_ServerToAllClients("timer_special_arena", broadcast_gametimer)
end

function CountdownTimerHeroImage()
	nTimer_HeroImage = nTimer_HeroImage - 1
	local t = nTimer_HeroImage
	local minutes = math.floor(t / 60)
	local seconds = t - (minutes * 60)
	local m10 = math.floor(minutes / 10)
	local m01 = minutes - (m10 * 10)
	local s10 = math.floor(seconds / 10)
	local s01 = seconds - (s10 * 10)
	local broadcast_gametimer = 
		{
			timer_minute_10 = m10,
			timer_minute_01 = m01,
			timer_second_10 = s10,
			timer_second_01 = s01,
		}
	CustomGameEventManager:Send_ServerToAllClients("timer_hero_image", broadcast_gametimer)
end

function CountdownTimerSpiritBeast()
	nTimer_SpiritBeast = nTimer_SpiritBeast - 1
	local t = nTimer_SpiritBeast
	local minutes = math.floor(t / 60)
	local seconds = t - (minutes * 60)
	local m10 = math.floor(minutes / 10)
	local m01 = minutes - (m10 * 10)
	local s10 = math.floor(seconds / 10)
	local s01 = seconds - (s10 * 10)
	local broadcast_gametimer = 
		{
			timer_minute_10 = m10,
			timer_minute_01 = m01,
			timer_second_10 = s10,
			timer_second_01 = s01,
		}
	CustomGameEventManager:Send_ServerToAllClients("timer_spirit_beast", broadcast_gametimer)
end

function CountdownTimerFrostInfernal()
	nTimer_FrostInfernal = nTimer_FrostInfernal - 1
	local t = nTimer_FrostInfernal
	local minutes = math.floor(t / 60)
	local seconds = t - (minutes * 60)
	local m10 = math.floor(minutes / 10)
	local m01 = minutes - (m10 * 10)
	local s10 = math.floor(seconds / 10)
	local s01 = seconds - (s10 * 10)
	local broadcast_gametimer = 
		{
			timer_minute_10 = m10,
			timer_minute_01 = m01,
			timer_second_10 = s10,
			timer_second_01 = s01,
		}
	CustomGameEventManager:Send_ServerToAllClients("timer_frost_infernal", broadcast_gametimer)
end

function CountdownTimerAllHeroImage()
	nTimer_AllHeroImage = nTimer_AllHeroImage - 1
	local t = nTimer_AllHeroImage
	local minutes = math.floor(t / 60)
	local seconds = t - (minutes * 60)
	local m10 = math.floor(minutes / 10)
	local m01 = minutes - (m10 * 10)
	local s10 = math.floor(seconds / 10)
	local s01 = seconds - (s10 * 10)
	local broadcast_gametimer = 
		{
			timer_minute_10 = m10,
			timer_minute_01 = m01,
			timer_second_10 = s10,
			timer_second_01 = s01,
		}
	CustomGameEventManager:Send_ServerToAllClients("timer_all_hero_image", broadcast_gametimer)
end

---------------------------------------------------------------------------
--	HealingFilter
--  *entindex_target_const
--	*entindex_healer_const
--	*entindex_inflictor_const
--	*heal
---------------------------------------------------------------------------
function GameMode:HealingFilter( filterTable )
	local nHeal = filterTable["heal"]
	if filterTable["entindex_healer_const"] == nil then
		return true
	end

	local hHealingHero = EntIndexToHScript( filterTable["entindex_healer_const"] )
	if nHeal > 0 and hHealingHero ~= nil and hHealingHero:IsRealHero() then
		for _,Zone in pairs( self.Zones ) do
			if Zone:ContainsUnit( hHealingHero ) then
				Zone:AddStat( hHealingHero:GetPlayerID(), ZONE_STAT_HEALING, nHeal )
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

function GameMode:DamageFilter( filterTable )
	local flDamage = filterTable["damage"]
	if filterTable["entindex_attacker_const"] == nil then
		return true
	end
	local hAttackerHero = EntIndexToHScript( filterTable["entindex_attacker_const"] )
	if flDamage > 0 and hAttackerHero ~= nil and hAttackerHero:IsRealHero() then
		for _,Zone in pairs( self.Zones ) do
			if Zone:ContainsUnit( hAttackerHero ) then
				Zone:AddStat( hAttackerHero:GetPlayerID(), ZONE_STAT_DAMAGE, flDamage )
				return true
			end
		end
	end
	return true
end

function GameMode:FilterExecuteOrder( filterTable )
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
	local point = Vector(x,y,z)
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

		for n,unit_index in pairs(units) do
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

	-- Deny No-Target Orders requirements
	if order_type == DOTA_UNIT_ORDER_CAST_NO_TARGET then
		local ability = EntIndexToHScript(abilityIndex)
		if not ability then return true end
		local playerID = unit:GetPlayerOwnerID()
--		
--		-- Check health/mana requirements
--		local manaDeficit = unit:GetMana() ~= unit:GetMaxMana()
--		local healthDeficit = unit:GetHealthDeficit() > 0
--		local bNeedsAnyDeficit = ability:GetKeyValue("RequiresAnyDeficit")
--		local requiresHealthDeficit = ability:GetKeyValue("RequiresHealthDeficit")
--		local requiresManaDeficit = ability:GetKeyValue("RequiresManaDeficit")
--
--		if bNeedsAnyDeficit and not healthDeficit and not manaDeficit then
--			if unit:GetMaxMana() > 0 then
--				SendErrorMessage(issuer, "#error_full_mana_health")
--			else
--				SendErrorMessage(issuer, "#error_full_health")
--			end
--			return false
--		elseif requiresHealthDeficit and not healthDeficit then
--			SendErrorMessage(issuer, "#error_full_health")
--			return false
--		elseif requiresManaDeficit and not manaDeficit then
--			SendErrorMessage(issuer, "#error_full_mana")
--			return false
--		end

		-- Check corpse requirements
--		local corpseRadius = ability:GetKeyValue("RequiresCorpsesAround")
--		if corpseRadius then
--			local corpseFlag = ability:GetKeyValue("CorpseFlag")
--			if corpseFlag then
--				if corpseFlag == "NotMeatWagon" then
--					if not Corpses:AreAnyOutsideInRadius(playerID, unit:GetAbsOrigin(), corpseRadius) then
--						SendErrorMessage(issuer, "#error_no_usable_corpses")
--						return false
--					end
--				end
--		elseif not Corpses:AreAnyInRadius(playerID, unit:GetAbsOrigin(), corpseRadius) then
--			if not Corpses:AreAnyInRadius(playerID, unit:GetAbsOrigin(), corpseRadius) then
--				Notifications:Bottom(playerID, {text="No corpses near!", duration=5.0, style={color="white"}})
--				return false
--			end
--		end
	end

	if order_type == DOTA_UNIT_ORDER_PURCHASE_ITEM then
		if SPECIAL_EVENT == 1 then
			SendErrorMessage(unit:GetPlayerID(), "#error_shop_disabled")
			return false
		else
			return true
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

	if GameMode.HeroImage_occuring == 1 then
		GameMode:SpecialEventTPQuit(hero)
		Notifications:Bottom(hero:GetPlayerOwnerID(),{text = "Hero Image is already occuring, please choose another event.", duration = 7.5})
	end

	if not hero.hero_image and GameMode.HeroImage_occuring == 0 then
		GameMode.HeroImage_occuring = 1
		Entities:FindByName(nil, "trigger_special_event_back4"):Enable()
		CustomGameEventManager:Send_ServerToAllClients("show_timer_hero_image", {})
		nTimer_HeroImage = 120

		PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
		Timers:CreateTimer(0.1, function()
			PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil) 
		end)

		GameMode.HeroImage = CreateUnitByName(hero:GetUnitName(), point_beast, true, nil, nil, DOTA_TEAM_CUSTOM_1)
		GameMode.HeroImage:SetAngles(0, 210, 0)

		GameMode.HeroImage:SetBaseStrength(hero:GetBaseStrength() * 4)
		GameMode.HeroImage:SetBaseIntellect(hero:GetBaseIntellect() * 4)
		GameMode.HeroImage:SetBaseAgility(hero:GetBaseAgility() * 4)

		for i = 0, GameMode.HeroImage:GetAbilityCount() - 1 do
			local ability = GameMode.HeroImage:GetAbilityByIndex(i)
			if ability then
				ability:SetLevel(ability:GetMaxLevel())
			end
		end

		GameMode.HeroImage:AddNewModifier(nil, nil, "modifier_boss_stun", {Duration = 5,IsHidden = true})
		GameMode.HeroImage:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 5,IsHidden = true})
		GameMode.HeroImage:MakeIllusion()
		GameMode.HeroImage:AddAbility("hero_image_death")
		GameMode.HeroImage.Boss = true

		local ability = GameMode.HeroImage:FindAbilityByName("hero_image_death")
		ability:ApplyDataDrivenModifier(GameMode.HeroImage, GameMode.HeroImage, "modifier_hero_image", {})

		if IsValidEntity(hero) then
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				GameMode:SpecialEventTPQuit(hero)
				DisableItems(hero, 120)
				Notifications:Bottom(hero:GetPlayerOwnerID(), {text = "Special Event: Kill Hero Image for +250 Stats. You have 2 minutes.", duration = 5.0})					
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
				Timers:CreateTimer(0.1, function()
					PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil) 
				end)

				TeleportHero(hero, 0.0, point_hero:GetAbsOrigin())
			end
		end

		timers.HeroImage = Timers:CreateTimer(120.0,function()
			Entities:FindByName(nil, "trigger_hero_image_duration"):Enable()
			GameMode.SpiritBeast_occuring = 0

			Timers:CreateTimer(5.5, function() --Debug time in case Hero Image kills the player at the very last second
				Entities:FindByName(nil, "trigger_hero_image_duration"):Disable()
			end)
			if not GameMode.HeroImage:IsNull() then
				GameMode.HeroImage:RemoveSelf()
			else
			end
		end)
	elseif hero.hero_image then
		Notifications:Bottom(hero:GetPlayerOwnerID(), {text = "You can do hero image only once!", duration = 5.0})
	end
end

function GameMode:SpiritBeast(event)
local PlayerID = event.pID
local player = PlayerResource:GetPlayer(PlayerID)
local hero = player:GetAssignedHero()
local point_hero = Entities:FindByName(nil, "spirit_beast_player")
local point_beast = Entities:FindByName(nil, "spirit_beast_boss"):GetAbsOrigin()

	if GameMode.SpiritBeast_occuring == 1 then
		GameMode:SpecialEventTPQuit(hero)
		Notifications:Bottom(hero:GetPlayerOwnerID(),{text = "Spirit Beast is already occuring, please choose another event.", duration = 7.5})
	elseif GameMode.SpiritBeast_killed == 0 then
		GameMode.SpiritBeast_occuring = 1
		Entities:FindByName(nil, "trigger_special_event_back3"):Enable()
		CustomGameEventManager:Send_ServerToAllClients("show_timer_spirit_beast", {})
		nTimer_SpiritBeast = 120

		PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
		Timers:CreateTimer(0.1, function()
			PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil) 
		end)

		timers.SpiritBeast = Timers:CreateTimer(120.0,function()
			Entities:FindByName(nil, "trigger_spirit_beast_duration"):Enable()
			GameMode.SpiritBeast_occuring = 0
			GameMode.spirit_beast:RemoveSelf()

			Timers:CreateTimer(5.5, function() --Debug time in case Spirit Beast kills the player at the very last second
				Entities:FindByName(nil, "trigger_spirit_beast_duration"):Disable()
			end)
		end)

		GameMode.spirit_beast = CreateUnitByName("npc_spirit_beast", point_beast, true, nil, nil, DOTA_TEAM_CUSTOM_1)
		GameMode.spirit_beast:SetAngles(0, 210, 0)
		GameMode.spirit_beast:AddNewModifier(nil, nil, "modifier_boss_stun", {Duration = 5,IsHidden = true})
		GameMode.spirit_beast:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 5,IsHidden = true})
		GameMode.spirit_beast.Boss = true

		if IsValidEntity(hero) then
			GameMode:SpecialEventTPQuit(hero)
			Notifications:Bottom(hero:GetPlayerOwnerID(), {text = "Special Event: Kill Spirit Beast for the Shield of Invincibility. You have 2 minutes.", duration = 5.0})
			PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil) 
			end)

			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				TeleportHero(hero, 0.0, point_hero:GetAbsOrigin())
			end
		end

		DisableItems(hero, 120)
	elseif GameMode.SpiritBeast_killed == 1 then
		Notifications:Bottom(hero:GetPlayerOwnerID(), {text = "Spirit Beast has already been killed!", duration = 5.0})
	end
end

function GameMode:FrostInfernal(event)
local PlayerID = event.pID
local player = PlayerResource:GetPlayer(PlayerID)
local hero = player:GetAssignedHero()
local point_hero = Entities:FindByName(nil, "frost_infernal_player")
local point_beast = Entities:FindByName(nil, "frost_infernal_boss"):GetAbsOrigin()

	if GameMode.FrostInfernal_occuring == 1 then
		GameMode:SpecialEventTPQuit(hero)
		Notifications:Bottom(hero:GetPlayerOwnerID(),{text = "Frost Infernal is already occuring, please choose another event.", duration = 7.5})
	elseif GameMode.FrostInfernal_killed == 0 then
		GameMode.FrostInfernal_occuring = 1
		Entities:FindByName(nil, "trigger_special_event_back2"):Enable()
		CustomGameEventManager:Send_ServerToAllClients("show_timer_frost_infernal", {})
		nTimer_FrostInfernal = 120

		timers.FrostInfernal = Timers:CreateTimer(120.0,function()
			Entities:FindByName(nil, "trigger_frost_infernal_duration"):Enable()
			GameMode.FrostInfernal_occuring = 0
			GameMode.frost_infernal:RemoveSelf()

			Timers:CreateTimer(5.5, function() --Debug time in case Frost Infernal kills the player at the very last second
				Entities:FindByName(nil, "trigger_frost_infernal_duration"):Disable()
			end)
		end)

		GameMode.frost_infernal = CreateUnitByName("npc_frost_infernal", point_beast, true, nil, nil, DOTA_TEAM_CUSTOM_1)
		GameMode.frost_infernal:SetAngles(0, 210, 0)
		GameMode.frost_infernal:AddNewModifier(nil, nil, "modifier_boss_stun", {Duration = 5, IsHidden = true})
		GameMode.frost_infernal:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 5, IsHidden = true})
		GameMode.frost_infernal.Boss = true

		GameMode:SpecialEventTPQuit(hero)
		Notifications:Bottom(hero:GetPlayerOwnerID(),{text = "Special Event: Kill Frost Infernal for the Key of the 3 Moons. You have 2 minutes.", duration = 5.0})
		PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), hero)
		Timers:CreateTimer(0.1, function()
			PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), nil) 
		end)

		if IsValidEntity(hero) then
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				TeleportHero(hero, 0.0, point_hero:GetAbsOrigin())
			end
		end

		DisableItems(hero, 120)
	else
		Notifications:Bottom(hero:GetPlayerOwnerID(), {text = "Frost Infernal has already been killed!", duration = 5.0})
	end
end

function GameMode:AllHeroImages(event)
local PlayerID = event.pID
local player = PlayerResource:GetPlayer(PlayerID)
local hero = player:GetAssignedHero()
local point = Entities:FindByName(nil, "all_hero_image_player")

	if GameMode.AllHeroImagesDead == 1 then
		Notifications:Bottom(hero:GetPlayerOwnerID(), {text = "All Hero Image has already been done!", duration = 5.0})
		return
	end

	if GameMode.AllHeroImages_occuring == 1 then
		Notifications:Bottom(hero:GetPlayerOwnerID(),{text = "All Hero Images is already occuring, please choose another event.", duration = 7.5})
	elseif GameMode.AllHeroImages_occuring == 0 then
		GameMode.AllHeroImages_occuring = 1
		Entities:FindByName(nil, "trigger_special_event_back5"):Enable()
		CustomGameEventManager:Send_ServerToAllClients("show_timer_all_hero_image", {})
		nTimer_AllHeroImage = 120

		PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
		Timers:CreateTimer(0.1, function()
			PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil) 
		end)

		local illusion_spawn = 0
		Timers:CreateTimer(0.25, function()
			local random = RandomInt(1, #HEROLIST)
			illusion_spawn = illusion_spawn + 1
			local point_image = Entities:FindByName(nil, "special_event_all_"..illusion_spawn)
			GameMode.AllHeroImage = CreateUnitByName("npc_dota_hero_"..HEROLIST[random], point_image:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
			GameMode.AllHeroImage:SetAngles(0, 45 - 45 * illusion_spawn, 0)
			GameMode.AllHeroImage:SetBaseStrength(hero:GetBaseStrength()*2)
			GameMode.AllHeroImage:SetBaseIntellect(hero:GetBaseIntellect()*2)
			GameMode.AllHeroImage:SetBaseAgility(hero:GetBaseAgility()*2)
			GameMode.AllHeroImage:AddNewModifier(nil, nil, "modifier_boss_stun", {Duration = 5,IsHidden = true})
			GameMode.AllHeroImage:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 5,IsHidden = true})
			GameMode.AllHeroImage:MakeIllusion()
			GameMode.AllHeroImage.Boss = true

			if illusion_spawn < 8 then
				return_time = 0.2
			else
				return_time = nil
			end

			return return_time
		end)

		if IsValidEntity(hero) then
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				GameMode:SpecialEventTPQuit(hero)
				Notifications:Bottom(hero:GetPlayerOwnerID(), {text = "Special Event: Kill All Heroes for Necklace of Immunity. You have 2 minutes.", duration = 5.0})
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
				Timers:CreateTimer(0.1, function()
					PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil) 
				end)

				TeleportHero(hero, 0.0, point:GetAbsOrigin())
			end
		end

		DisableItems(hero, 120)

		timers.AllHeroImage = Timers:CreateTimer(0.5, function()
			ALL_HERO_IMAGE_DEAD = 0
			local units = FindUnitsInRadius(DOTA_TEAM_CUSTOM_2, point:GetAbsOrigin(), nil, 2500, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE , FIND_ANY_ORDER, false)
			for _, unit in pairs(units) do
				ALL_HERO_IMAGE_DEAD = ALL_HERO_IMAGE_DEAD +1
			end

			if ALL_HERO_IMAGE_DEAD == 0 then
				GameMode.AllHeroImagesDead = 1
				DoEntFire("trigger_all_hero_image_duration", "Kill", nil ,0 ,nil ,nil)
				CustomGameEventManager:Send_ServerToAllClients("hide_timer_all_hero_image", {})
				Timers:RemoveTimer(timers.AllHeroImage)
				Timers:RemoveTimer(timers.AllHeroImage2)
				Timers:CreateTimer(0.5, function()
					local item = CreateItem("item_necklace_of_spell_immunity", nil, nil)
					local pos = Entities:FindByName(nil, "all_hero_image_player"):GetAbsOrigin()
					local drop = CreateItemOnPositionSync( pos, item )
					local pos_launch = pos + RandomVector(RandomFloat(150, 200))
					item:LaunchLoot(false, 300, 0.5, pos)
				end)
				return nil
			end
			return 1.0
		end)

		timers.AllHeroImage2 = Timers:CreateTimer(120.0, function()
			Entities:FindByName(nil, "trigger_all_hero_image_duration"):Enable()
			GameMode.AllHeroImages_occuring = 0

			Timers:CreateTimer(5.5, function() --Debug time in case Frost Infernal kills the player at the very last second
				Entities:FindByName(nil, "trigger_all_hero_image_duration"):Disable()
			end)

			local units = FindUnitsInRadius(DOTA_TEAM_CUSTOM_2, point, nil, 2500, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE , FIND_ANY_ORDER, false)
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
	hero:RemoveModifierByName("modifier_boss_stun")
	hero:RemoveModifierByName("modifier_invulnerable")
	EnableItems(hero)
end

function GameMode:SpecialEventTPQuit2(event)
local PlayerID = event.pID
local player = PlayerResource:GetPlayer(PlayerID)
local hero = player:GetAssignedHero()

	hero:Stop()
	Entities:FindByName(nil, "trigger_special_event"):Enable()
	hero:RemoveModifierByName("modifier_boss_stun")
	hero:RemoveModifierByName("modifier_invulnerable")
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

function GameMode:HasDialog( hDialogEnt )
	if hDialogEnt == nil or hDialogEnt:IsNull() then
		return false
	end
	
	for k,v in pairs ( DialogDefinition ) do
		if k == hDialogEnt:GetUnitName() then
			return true
		end
	end

	return false
end

function GameMode:GetDialog( hDialogEnt )
	if self:HasDialog( hDialogEnt ) == false then
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
 		if self:IsQuestActive( Dialog[hDialogEnt.nCurrentLine].szAdvanceQuestActive ) then
			hDialogEnt.nCurrentLine = hDialogEnt.nCurrentLine + 1
		end
	end

	return Dialog[hDialogEnt.nCurrentLine]
end

function GameMode:GetDialogLine( hDialogEnt, nLineNumber )
	if self:HasDialog( hDialogEnt ) == false then
		return nil
	end

	local Dialog = DialogDefinition[hDialogEnt:GetUnitName()]
	if Dialog == nil then
		return nil
	end

	return Dialog[nLineNumber]
end

function GameMode:IsQuestActive( szQuestName )
	for _,zone in pairs( self.Zones ) do
		if zone ~= nil and zone:IsQuestActive( szQuestName ) == true then
			return true
		end
	end

	return false
end