if XHSBotPlayerRegistry == nil then
	XHSBotPlayerRegistry = {}
end

XHSBotPlayerRegistry.bots = XHSBotPlayerRegistry.bots or {}
XHSBotPlayerRegistry.maximum_player_id = 23

local function IsValidPlayerID(playerID)
	playerID = tonumber(playerID)
	return playerID ~= nil
		and playerID >= 0
		and PlayerResource ~= nil
		and PlayerResource.IsValidPlayerID ~= nil
		and PlayerResource:IsValidPlayerID(playerID)
end

local function IsGoodGuys(playerID)
	return PlayerResource.GetTeam == nil or PlayerResource:GetTeam(playerID) == DOTA_TEAM_GOODGUYS
end

local function IsValidHeroForPlayer(playerID, hero)
	if hero == nil
		or IsValidEntity ~= nil and not IsValidEntity(hero)
		or hero:IsNull()
		or hero.IsRealHero == nil or not hero:IsRealHero()
		or hero.GetPlayerID == nil
		or tonumber(hero:GetPlayerID()) ~= tonumber(playerID)
		or hero.GetTeamNumber == nil
		or hero:GetTeamNumber() ~= DOTA_TEAM_GOODGUYS then
		return false
	end
	return true
end

function XHSBotPlayerRegistry:Reset()
	self.bots = {}
end

function XHSBotPlayerRegistry:RegisterBot(playerID, hero, metadata)
	playerID = tonumber(playerID)
	if playerID == nil or playerID < 0 then return nil end

	metadata = metadata or {}
	local record = self.bots[playerID] or {
		player_id = playerID,
		created_at = GameRules ~= nil and GameRules:GetGameTime() or 0,
		state = "SELECTING_HERO",
		macro_state = "SELECTING_HERO",
		orders = 0,
		rejected_orders = 0,
		casts_considered = 0,
		casts_issued = 0,
		casts_rejected = 0,
		target_changes = 0,
		assignment_changes = 0,
		stuck_recoveries = 0,
		danger_hits = 0,
		danger_damage = 0,
		idle_seconds = 0,
		decision_ticks = 0,
		decision_cost_total_ms = 0,
		decision_cost_average_ms = 0,
		decision_cost_max_ms = 0,
	}

	record.slot = tonumber(metadata.slot) or record.slot
	record.name = metadata.name or record.name or ("XHS Bot " .. tostring(playerID + 1))
	record.difficulty = metadata.difficulty or record.difficulty or "normal"
	record.composition = metadata.composition or record.composition or "balanced"
	record.requested_hero = metadata.requested_hero or record.requested_hero
	record.provisioning = metadata.provisioning or record.provisioning
	record.registered = true

	self.bots[playerID] = record
	if hero ~= nil then
		self:BindHero(playerID, hero)
	end
	return record
end

function XHSBotPlayerRegistry:UnregisterBot(playerID)
	playerID = tonumber(playerID)
	if playerID == nil then return end
	self.bots[playerID] = nil
end

function XHSBotPlayerRegistry:BindHero(playerID, hero)
	local record = self.bots[tonumber(playerID)]
	if record == nil or not IsValidHeroForPlayer(playerID, hero) then return nil end

	local changedHero = record.hero_entindex ~= hero:entindex()
	record.hero_entindex = hero:entindex()
	record.hero_name = hero:GetUnitName()
	record.alive = hero:IsAlive()
	record.hero_missing_since = nil
	record.hero_missing_checks = 0
	if changedHero then
		record.state = hero:IsAlive() and "INITIALIZING" or "DEAD"
	end
	hero.xhs_is_bot = true
	hero.is_fake_hero = nil
	hero.xhs_bot_player_id = record.player_id
	return record
end

function XHSBotPlayerRegistry:GetBot(playerID)
	return self.bots[tonumber(playerID)]
end

function XHSBotPlayerRegistry:IsXHSBotPlayerID(playerID)
	return self.bots[tonumber(playerID)] ~= nil
end

function XHSBotPlayerRegistry:IsEngineBotPlayerID(playerID)
	if not IsValidPlayerID(playerID) then return false end
	if PlayerResource.IsFakeClient ~= nil then
		local ok, isFake = pcall(function()
			return PlayerResource:IsFakeClient(playerID)
		end)
		if ok then return isFake == true end
	end
	return false
end

function XHSBotPlayerRegistry:IsHumanPlayerID(playerID)
	if not IsValidPlayerID(playerID) or not IsGoodGuys(playerID) then return false end
	if self:IsXHSBotPlayerID(playerID) then return false end
	if self:IsEngineBotPlayerID(playerID) then return false end
	-- A valid Radiant slot is still a human identity while its player handle is
	-- loading or temporarily disconnected. Connection state is availability,
	-- not identity.
	return true
end

function XHSBotPlayerRegistry:IsXHSBotUnit(unit)
	if unit == nil or unit:IsNull() then return false end
	if unit.IsRealHero == nil or not unit:IsRealHero() then return false end
	if unit.xhs_is_bot == true then return true end
	if unit.GetPlayerID ~= nil then
		return self:IsXHSBotPlayerID(unit:GetPlayerID())
	end
	return false
end

function XHSBotPlayerRegistry:IsDummyOrShowcaseUnit(unit)
	if unit == nil or unit:IsNull() then return false end
	return unit.is_fake_hero == true
		or unit.xhs_devtools_spawned == true
		or unit:GetUnitName() == "npc_dota_hero_wisp" and unit.GetPlayerID ~= nil and unit:GetPlayerID() < 0
end

function XHSBotPlayerRegistry:GetXHSBotPlayerIDs()
	local ids = {}
	for playerID in pairs(self.bots) do
		table.insert(ids, playerID)
	end
	table.sort(ids)
	return ids
end

function XHSBotPlayerRegistry:GetHumanPlayerIDs()
	local ids = {}
	for playerID = 0, self.maximum_player_id do
		if self:IsHumanPlayerID(playerID) then
			table.insert(ids, playerID)
		end
	end
	return ids
end

function XHSBotPlayerRegistry:GetHumanCount()
	return #self:GetHumanPlayerIDs()
end

function XHSBotPlayerRegistry:HasHumanCombatHero()
	if HeroList == nil or HeroList.GetAllHeroes == nil then return false end
	for _, hero in pairs(HeroList:GetAllHeroes() or {}) do
		if hero ~= nil and not hero:IsNull()
			and hero.IsRealHero ~= nil and hero:IsRealHero()
			and hero:GetTeamNumber() == DOTA_TEAM_GOODGUYS
			and hero.is_fake_hero ~= true
			and not self:IsXHSBotUnit(hero) then
			local playerID = hero.GetPlayerID ~= nil
				and tonumber(hero:GetPlayerID()) or -1
			if playerID >= 0
				and self:IsHumanPlayerID(playerID)
				and hero:GetUnitName() ~= "npc_dota_hero_wisp" then
				return true
			end
		end
	end
	return false
end

-- Spectator-controlled bot-only sessions have no Radiant human identity.
-- Requiring both conditions prevents a disconnected/unpicked normal player
-- from accidentally handing campaign progression to the AI.
function XHSBotPlayerRegistry:IsBotOnlyCombatSession()
	return #self:GetXHSBotPlayerIDs() > 0
		and self:GetHumanCount() == 0
		and not self:HasHumanCombatHero()
end

function XHSBotPlayerRegistry:GetCombatParticipantPlayerIDs()
	local seen = {}
	local ids = {}
	for _, playerID in ipairs(self:GetHumanPlayerIDs()) do
		seen[playerID] = true
		table.insert(ids, playerID)
	end
	for _, playerID in ipairs(self:GetXHSBotPlayerIDs()) do
		if not seen[playerID] and IsValidPlayerID(playerID) and IsGoodGuys(playerID) then
			seen[playerID] = true
			table.insert(ids, playerID)
		end
	end
	table.sort(ids)
	return ids
end

function XHSBotPlayerRegistry:GetCombatParticipantOrdinal(playerID)
	playerID = tonumber(playerID)
	if playerID == nil then return nil end
	for ordinal, participantPlayerID in ipairs(self:GetCombatParticipantPlayerIDs()) do
		if participantPlayerID == playerID then return ordinal end
	end
	return nil
end

function XHSBotPlayerRegistry:GetCombatParticipantCount()
	return #self:GetCombatParticipantPlayerIDs()
end

function XHSBotPlayerRegistry:GetBotHero(playerID)
	local record = self:GetBot(playerID)
	if record == nil then return nil end

	local player = PlayerResource ~= nil and PlayerResource:GetPlayer(playerID) or nil
	local hero = player ~= nil and player:GetAssignedHero() or nil
	if IsValidHeroForPlayer(playerID, hero) then
		self:BindHero(playerID, hero)
		return hero
	end

	hero = PlayerResource ~= nil
		and PlayerResource.GetSelectedHeroEntity ~= nil
		and PlayerResource:GetSelectedHeroEntity(playerID) or nil
	if IsValidHeroForPlayer(playerID, hero) then
		self:BindHero(playerID, hero)
		return hero
	end

	if record.hero_entindex ~= nil and EntIndexToHScript ~= nil then
		local ok, entity = pcall(EntIndexToHScript, record.hero_entindex)
		if ok and IsValidHeroForPlayer(playerID, entity) then
			self:BindHero(playerID, entity)
			return entity
		end
	end

	-- Scripted revives and ReplaceHeroWith can briefly leave the Player object
	-- without an assigned handle. Rediscover the real hero by immutable player
	-- identity before declaring it missing; never bind showcases or illusions.
	if HeroList ~= nil and HeroList.GetAllHeroes ~= nil then
		for _, candidate in pairs(HeroList:GetAllHeroes() or {}) do
			if IsValidHeroForPlayer(playerID, candidate)
				and candidate.is_fake_hero ~= true
				and (candidate.IsIllusion == nil or not candidate:IsIllusion()) then
				self:BindHero(playerID, candidate)
				return candidate
			end
		end
	end

	record.hero_entindex = nil
	record.hero_missing_since = record.hero_missing_since
		or (GameRules ~= nil and GameRules:GetGameTime() or 0)
	record.hero_missing_checks = (record.hero_missing_checks or 0) + 1
	return nil
end

-- Global compatibility helpers deliberately route through one source of truth.
function IsXHSBotPlayerID(playerID)
	return XHSBotPlayerRegistry ~= nil and XHSBotPlayerRegistry:IsXHSBotPlayerID(playerID)
end

function IsXHSHumanPlayerID(playerID)
	return XHSBotPlayerRegistry == nil or XHSBotPlayerRegistry:IsHumanPlayerID(playerID)
end

function IsXHSPersistentPlayerID(playerID)
	return IsXHSHumanPlayerID(playerID)
end

function GetXHSBotPlayerIDs()
	return XHSBotPlayerRegistry ~= nil and XHSBotPlayerRegistry:GetXHSBotPlayerIDs() or {}
end

function GetXHSHumanPlayerIDs()
	return XHSBotPlayerRegistry ~= nil and XHSBotPlayerRegistry:GetHumanPlayerIDs() or {}
end

function GetXHSCombatParticipantCount()
	if XHSBotPlayerRegistry ~= nil then
		return XHSBotPlayerRegistry:GetCombatParticipantCount()
	end
	return PlayerResource ~= nil and PlayerResource:GetPlayerCount() or 0
end

function GetXHSCombatParticipantPlayerIDs()
	return XHSBotPlayerRegistry ~= nil
		and XHSBotPlayerRegistry:GetCombatParticipantPlayerIDs() or {}
end

function GetXHSCombatParticipantOrdinal(playerID)
	return XHSBotPlayerRegistry ~= nil
		and XHSBotPlayerRegistry:GetCombatParticipantOrdinal(playerID) or nil
end

function XHSSessionContainsBots()
	return XHSBotPlayerRegistry ~= nil
		and #XHSBotPlayerRegistry:GetXHSBotPlayerIDs() > 0
end

function XHSBotOnlyAutonomyAllowed()
	if XHSBotPlayerRegistry == nil then return false end

	-- The setup snapshot is authoritative for the whole match. A temporary
	-- PlayerResource gap (loading, reconnecting or hero replacement) must never
	-- let bots seize campaign interactions from a human-controlled party.
	local configuration = XHSBots ~= nil and XHSBots.configuration or nil
	if type(configuration) == "table"
		and configuration.spectator_mode ~= true
		and math.max(
			tonumber(configuration.combat_human_count) or 0,
			tonumber(configuration.human_count) or 0
		) > 0 then
		return false
	end

	return XHSBotPlayerRegistry:IsBotOnlyCombatSession()
end

return XHSBotPlayerRegistry
