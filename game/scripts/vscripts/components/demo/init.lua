--------------------------------------------------------------------------------
-- GameEvent:OnGameRulesStateChange
--------------------------------------------------------------------------------
ListenToGameEvent('game_rules_state_change', function()
	local state = GameRules:State_Get()

	if GetMapName() ~= "x_hero_siege_demo" then return end

	if state == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		GameMode:InitDemo()
		-- Team assignment is only guaranteed to be writable during custom setup.
		-- Repair the local slot before the separate listener immediately finishes
		-- this otherwise-skipped state.
		GameMode:EnsureDemoPlayableHeroes(false)
	elseif state == DOTA_GAMERULES_STATE_PRE_GAME then
		-- The demo deliberately skips the ordinary XHS selection flow. Verify
		-- after the engine assignment pass that every human owns a playable hero.
		GameRules:GetGameModeEntity():SetContextThink("xhs_demo_ensure_playable_heroes", function()
			GameMode:EnsureDemoPlayableHeroes()
			return nil
		end, 0.1)
	end
end, nil)

ListenToGameEvent('player_connect_full', function()
	if GetMapName() ~= "x_hero_siege_demo" then return end

	-- A direct Tools launch can connect the local player after CUSTOM_GAME_SETUP
	-- has already been collapsed to zero. Keep this event as the authoritative
	-- late-arrival repair trigger; OnThink verifies the result afterward.
	GameMode:EnsureDemoPlayableHeroes()
end, nil)

function GameMode:EnsureDemoPlayableHeroes(allowHeroCreation)
	self.demoHeroRecoveryPending = self.demoHeroRecoveryPending or {}
	local foundHuman = false
	local allHumansReady = true

	for playerID = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
		local isValidPlayer = PlayerResource:IsValidPlayerID(playerID)
		local player = isValidPlayer and PlayerResource:GetPlayer(playerID) or nil
		local isFakeClient = isValidPlayer
			and PlayerResource.IsFakeClient ~= nil
			and PlayerResource:IsFakeClient(playerID)

		if player ~= nil and not isFakeClient then
			foundHuman = true

			if PlayerResource:GetTeam(playerID) ~= DOTA_TEAM_GOODGUYS
				and PlayerResource.SetCustomTeamAssignment ~= nil then
				local teamOK, teamError = pcall(function()
					PlayerResource:SetCustomTeamAssignment(playerID, DOTA_TEAM_GOODGUYS)
				end)
				if not teamOK and XHSBootstrapLog ~= nil then
					XHSBootstrapLog("warn", "demo player team assignment failed player_id="
						.. tostring(playerID) .. " error=" .. tostring(teamError))
				end
			end
			local teamReady = PlayerResource:GetTeam(playerID) == DOTA_TEAM_GOODGUYS

			local hero = PlayerResource:GetSelectedHeroEntity(playerID)
			if (hero == nil or hero:IsNull()) and player ~= nil and player.GetAssignedHero ~= nil then
				hero = player:GetAssignedHero()
			end
			local needsPlayableHero = not teamReady
				or hero == nil
				or hero:IsNull()
				or hero:GetUnitName() == "npc_dota_hero_wisp"
				or hero:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS

			if needsPlayableHero then
				allHumansReady = false
			end

			if needsPlayableHero
				and teamReady
				and hero ~= nil
				and not hero:IsNull()
				and hero:GetUnitName() == "npc_dota_hero_wisp"
				and allowHeroCreation ~= false
				and not self.demoHeroRecoveryPending[playerID] then
				self.demoHeroRecoveryPending[playerID] = true

				local function CompleteDemoHeroRecovery(newHero)
					self.demoHeroRecoveryPending[playerID] = nil
					if newHero ~= nil and not newHero:IsNull() then
						newHero:SetGold(99999, false)
						PlayerResource:SetCameraTarget(playerID, newHero)
						GameRules:GetGameModeEntity():SetContextThink(
							"xhs_demo_release_recovery_camera_" .. tostring(playerID),
							function()
								PlayerResource:SetCameraTarget(playerID, nil)
								return nil
							end,
							0.1
						)
					end
				end

				-- Let the engine finish spawning its default Wisp first. Replacing it
				-- on the same frame can race hero assignment and leave an incomplete
				-- model, so keep the default visible briefly before Mountain King.
				Timers:CreateTimer(0.5, function()
					local currentHero = PlayerResource:GetSelectedHeroEntity(playerID)
					if currentHero == nil
						or currentHero:IsNull()
						or currentHero:GetUnitName() ~= "npc_dota_hero_wisp" then
						self.demoHeroRecoveryPending[playerID] = nil
						return nil
					end

					XHSPrecache:ReplaceHeroWith(playerID, "npc_dota_hero_sven", 99999, 0, currentHero, {
						cleanupDelay = 1.0,
					}, CompleteDemoHeroRecovery)
					return nil
				end)
			end
		end
	end

	self.demoInitialPlayableHeroReady = foundHuman and allHumansReady
end

function GameMode:InitDemo()
	GameRules:GetGameModeEntity():SetTowerBackdoorProtectionEnabled( true )
	GameRules:GetGameModeEntity():SetFixedRespawnTime( 4 )
--	GameRules:GetGameModeEntity():SetBotThinkingEnabled( true ) -- the ConVar is currently disabled in C++
	-- Set bot mode difficulty: can try GameRules:GetGameModeEntity():SetCustomGameDifficulty( 1 )

	GameRules:SetPreGameTime(10.0)
	GameRules:SetStrategyTime(0.0)
	GameRules:SetCustomGameSetupTimeout(0.0) -- skip the custom team UI with 0, or do indefinite duration with -1
	GameRules:SetSafeToLeave(true)

	-- Events
	CustomGameEventManager:RegisterListener( "WelcomePanelDismissed", function(...) return self:OnWelcomePanelDismissed( ... ) end )
	CustomGameEventManager:RegisterListener( "RefreshButtonPressed", function(...) return self:OnRefreshButtonPressed( ... ) end )
	CustomGameEventManager:RegisterListener( "LevelUpButtonPressed", function(...) return self:OnLevelUpButtonPressed( ... ) end )
	CustomGameEventManager:RegisterListener( "MaxLevelButtonPressed", function(...) return self:OnMaxLevelButtonPressed( ... ) end )
	CustomGameEventManager:RegisterListener( "FranticButtonPressed", function(...) return self:OnFranticButtonPressed( ... ) end )
	CustomGameEventManager:RegisterListener( "FreeSpellsButtonPressed", function(...) return self:OnFreeSpellsButtonPressed( ... ) end )
	CustomGameEventManager:RegisterListener( "InvulnerabilityButtonPressed", function(...) return self:OnInvulnerabilityButtonPressed( ... ) end )
	CustomGameEventManager:RegisterListener( "SpawnAllyButtonPressed", function(...) return self:OnSpawnAllyButtonPressed( ... ) end ) -- deprecated
	CustomGameEventManager:RegisterListener( "SpawnEnemyButtonPressed", function(...) return self:OnSpawnEnemyButtonPressed( ... ) end )
	CustomGameEventManager:RegisterListener( "LevelUpEnemyButtonPressed", function(...) return self:OnLevelUpEnemyButtonPressed( ... ) end )
	CustomGameEventManager:RegisterListener( "DummyTargetButtonPressed", function(...) return self:OnDummyTargetButtonPressed( ... ) end )
	CustomGameEventManager:RegisterListener( "RemoveSpawnedUnitsButtonPressed", function(...) return self:OnRemoveSpawnedUnitsButtonPressed( ... ) end )
	CustomGameEventManager:RegisterListener( "LaneCreepsButtonPressed", function(...) return self:OnLaneCreepsButtonPressed( ... ) end )
	CustomGameEventManager:RegisterListener( "ChangeHeroButtonPressed", function(...) return self:OnChangeHeroButtonPressed( ... ) end )
	CustomGameEventManager:RegisterListener( "ChangeCosmeticsButtonPressed", function(...) return self:OnChangeCosmeticsButtonPressed( ... ) end )
	CustomGameEventManager:RegisterListener( "PauseButtonPressed", function(...) return self:OnPauseButtonPressed( ... ) end )
	CustomGameEventManager:RegisterListener( "LeaveButtonPressed", function(...) return self:OnLeaveButtonPressed( ... ) end )
--	CustomGameEventManager:RegisterListener("fix_newly_picked_hero", Dynamic_Wrap(self, 'OnNewHeroChosen'))
	CustomGameEventManager:RegisterListener("demo_select_hero", Dynamic_Wrap(self, 'OnNewHeroSelected'))

	GameRules:SetCustomGameTeamMaxPlayers(2, 1)
	GameRules:SetCustomGameTeamMaxPlayers(3, 0)

	SendToServerConsole( "sv_cheats 1" )
	SendToServerConsole( "dota_hero_god_mode 0" )
	SendToServerConsole( "dota_ability_debug 0" )
	SendToServerConsole( "dota_creeps_no_spawning 0" )
--	SendToServerConsole( "dota_bot_mode 1" )

	self.m_bPlayerDataCaptured = false
	self.m_nPlayerID = 0

--	self.m_nHeroLevelBeforeMaxing = 1 -- unused now
--	self.m_bHeroMaxedOut = false -- unused now

	self.m_nALLIES_TEAM = 2
	self.m_tAlliesList = {}
	self.m_nAlliesCount = 0

	self.m_nENEMIES_TEAM = 3
	self.m_tEnemiesList = {}

	self.m_bFreeSpellsEnabled = false
	self.m_bInvulnerabilityEnabled = false
	self.m_bCreepsEnabled = true

	self.i_broadcast_message_duration = 5.0

	local hNeutralSpawn = Entities:FindByName( nil, "neutral_caster_spawn" )
	self.hNeutralCaster = CreateUnitByName( "npc_dota_neutral_caster", hNeutralSpawn:GetAbsOrigin(), false, nil, nil, DOTA_TEAM_GOODGUYS )
end

function GameMode:BroadcastMsg(message, iDuration)
	if iDuration == nil then
		iDuration = GameMode.i_broadcast_message_duration
	elseif iDuration == -1 then
		iDuration = 99999
	end

	Notifications:BottomToAll({ text = message, duration = iDuration, style = {color = "white"}})
end

require("components/demo/events")
