if XHSBotCampaignDirector == nil then
	XHSBotCampaignDirector = {}
end

XHSBotCampaignDirector.next_update = 0
XHSBotCampaignDirector.objective = nil
XHSBotCampaignDirector.stage = "inactive"
XHSBotCampaignDirector.shal_confirmed = false
XHSBotCampaignDirector.shal_entindex =
	XHSBotCampaignDirector.shal_entindex or nil

local SHAL_NAME = "npc_xhs_paladin"
local MAGTHERIDON_NAME = "npc_dota_hero_magtheridon"
local GROM_NAME = "npc_dota_hero_grom_hellscream"
local SHAL_REACHED_DISTANCE = 340

local function IsValidEntityHandle(entity)
	return entity ~= nil and IsValidEntity(entity) and not entity:IsNull()
end

local function IsValidCombatUnit(unit)
	return IsValidEntityHandle(unit)
		and unit.IsAlive ~= nil and unit:IsAlive()
end

local function CopyPosition(position)
	if position == nil then return nil end
	return Vector(position.x, position.y, position.z or 0)
end

local function FindUnitByName(name, team, requireAlive)
	if HeroList ~= nil and HeroList.GetAllHeroes ~= nil then
		for _, unit in pairs(HeroList:GetAllHeroes() or {}) do
			if IsValidEntityHandle(unit)
				and unit:GetUnitName() == name
				and (team == nil or unit:GetTeamNumber() == team)
				and (not requireAlive or unit:IsAlive()) then
				return unit
			end
		end
	end
	local units = FindUnitsInRadius(
		DOTA_TEAM_GOODGUYS,
		Vector(0, 0, 0),
		nil,
		FIND_UNITS_EVERYWHERE,
		team == DOTA_TEAM_GOODGUYS
			and DOTA_UNIT_TARGET_TEAM_FRIENDLY
			or DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_INVULNERABLE
			+ DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		FIND_ANY_ORDER,
		false
	)
	for _, unit in pairs(units or {}) do
		if IsValidEntityHandle(unit)
			and unit:GetUnitName() == name
			and (team == nil or unit:GetTeamNumber() == team)
			and (not requireAlive or unit:IsAlive()) then
			return unit
		end
	end
	return nil
end

local function IsQuestActive(name)
	return GameMode ~= nil and GameMode.IsQuestActive ~= nil
		and GameMode:IsQuestActive(name) == true
end

local function IsQuestComplete(name)
	if GameMode == nil or type(GameMode.Zones) ~= "table" then return false end
	for _, zone in pairs(GameMode.Zones) do
		if zone ~= nil and zone.IsQuestComplete ~= nil
			and zone:IsQuestComplete(name) == true then
			return true
		end
	end
	return false
end

local function FindNamedEntityPosition(names)
	for _, name in ipairs(names or {}) do
		local entity = Entities:FindByName(nil, name)
		if IsValidEntityHandle(entity) then
			return CopyPosition(entity:GetAbsOrigin()), entity
		end
	end
	return nil, nil
end

function XHSBotCampaignDirector:IsAutonomyAllowed()
	return XHSBotOnlyAutonomyAllowed ~= nil
		and XHSBotOnlyAutonomyAllowed() == true
end

function XHSBotCampaignDirector:SetObjective(stage, objective)
	if self.stage ~= stage then
		print(
			"[XHSBots][Campaign] stage=" .. tostring(stage)
				.. " previous=" .. tostring(self.stage)
		)
	end
	self.stage = stage
	self.objective = objective
end

function XHSBotCampaignDirector:FindShal()
	local units = FindUnitsInRadius(
		DOTA_TEAM_GOODGUYS,
		Vector(0, 0, 0),
		nil,
		FIND_UNITS_EVERYWHERE,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_INVULNERABLE
			+ DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		FIND_ANY_ORDER,
		false
	)
	local candidates = {}
	for _, unit in pairs(units or {}) do
		if IsValidEntityHandle(unit)
			and unit:GetUnitName() == SHAL_NAME
			and unit.xhs_freed_shal_lightbinder == true then
			if unit:entindex() == self.shal_entindex then
				return unit
			end
			table.insert(candidates, unit)
		end
	end
	local best = nil
	local bestDistance = math.huge
	for _, unit in ipairs(candidates) do
		local distance = math.huge
		for _, playerID in ipairs(
			XHSBotPlayerRegistry:GetXHSBotPlayerIDs()
		) do
			local hero = XHSBotPlayerRegistry:GetBotHero(playerID)
			if IsValidCombatUnit(hero) then
				distance = math.min(
					distance,
					(hero:GetAbsOrigin() - unit:GetAbsOrigin()):Length2D()
				)
			end
		end
		if best == nil or distance < bestDistance
			or distance == bestDistance
				and unit:entindex() < best:entindex() then
			best = unit
			bestDistance = distance
		end
	end
	self.shal_entindex =
		IsValidEntityHandle(best) and best:entindex() or nil
	return best
end

function XHSBotCampaignDirector:AnyBotReached(position, distance)
	if position == nil or XHSBotPlayerRegistry == nil then return false end
	for _, playerID in ipairs(XHSBotPlayerRegistry:GetXHSBotPlayerIDs()) do
		local hero = XHSBotPlayerRegistry:GetBotHero(playerID)
		if IsValidCombatUnit(hero)
			and (hero:GetAbsOrigin() - position):Length2D()
				<= (tonumber(distance) or SHAL_REACHED_DISTANCE) then
			return true
		end
	end
	return false
end

function XHSBotCampaignDirector:ConfirmShalDialog(shal)
	if self.shal_confirmed or not IsValidEntityHandle(shal)
		or not IsQuestActive("teleport_top") then
		return false
	end
	local completed = false
	for _, zone in pairs(GameMode.Zones or {}) do
		if zone ~= nil and zone.OnDialogAllConfirmed ~= nil then
			local ok = pcall(function()
				zone:OnDialogAllConfirmed(shal, 4)
			end)
			completed = completed or ok
		end
	end
	print(
		"[XHSBots][Campaign] action=confirm_shal_dialog result="
			.. tostring(completed)
	)
	self.shal_confirmed = completed
	return completed
end

function XHSBotCampaignDirector:Update(force)
	local now = GameRules:GetGameTime()
	if not force and now < (self.next_update or 0) then return end
	self.next_update = now + 0.5

	if not self:IsAutonomyAllowed() then
		self:SetObjective("human_controlled", nil)
		return
	end
	local phase = CustomTimers ~= nil
		and tonumber(CustomTimers.game_phase) or 1
	if phase < 3 then
		self:SetObjective("waiting_phase_3", nil)
		return
	end

	if IsQuestActive("teleport_top")
		and not IsQuestComplete("teleport_top") then
		local shal = self:FindShal()
		local position = IsValidEntityHandle(shal)
			and CopyPosition(shal:GetAbsOrigin()) or nil
		self:SetObjective("shal", position ~= nil and {
			goal = "campaign_shal",
			anchor = position,
			target_entindex = shal:entindex(),
			non_combat = true,
			attack_move = false,
			label = "TALKING TO SHAL LIGHTBINDER",
			urgency = 0.92,
			reached_distance = SHAL_REACHED_DISTANCE,
		} or nil)
		if position ~= nil and self:AnyBotReached(
			position,
			SHAL_REACHED_DISTANCE
		) then
			self:ConfirmShalDialog(shal)
		end
		return
	end

	local magtheridon = FindUnitByName(
		MAGTHERIDON_NAME,
		DOTA_TEAM_CUSTOM_2,
		true
	)
	if IsValidCombatUnit(magtheridon)
		or IsQuestActive("kill_mag")
			and not IsQuestComplete("kill_mag") then
		local position = IsValidCombatUnit(magtheridon)
			and CopyPosition(magtheridon:GetAbsOrigin())
			or FindNamedEntityPosition({
				"npc_dota_spawner_magtheridon_arena",
				"point_teleport_boss_1",
			})
		self:SetObjective("magtheridon", {
			goal = "campaign_magtheridon",
			anchor = position,
			target_entindex = IsValidCombatUnit(magtheridon)
				and magtheridon:entindex() or nil,
			label = IsValidCombatUnit(magtheridon)
				and "FIGHTING MAGTHERIDON"
				or "GOING TO MAGTHERIDON",
			urgency = 1,
			reached_distance = 500,
		})
		return
	end

	local grom = FindUnitByName(GROM_NAME, DOTA_TEAM_CUSTOM_2, true)
	local vanguard = GameMode ~= nil
		and type(GameMode.GromVanguard) == "table"
		and GameMode.GromVanguard or nil
	if IsValidCombatUnit(grom)
		and (vanguard == nil or vanguard.gate_opened == true) then
		self:SetObjective("grom", {
			goal = "campaign_grom",
			anchor = CopyPosition(grom:GetAbsOrigin()),
			target_entindex = grom:entindex(),
			label = "FIGHTING GROM HELLSCREAM",
			urgency = 1,
			reached_distance = 500,
		})
		return
	end

	if IsQuestActive("clear_grom_vanguard")
		or vanguard ~= nil and vanguard.started == true then
		local started = vanguard ~= nil and vanguard.started == true
		local position = nil
		if started then
			position = FindNamedEntityPosition({
				"point_teleport_phase3_creeps_1",
				"spawner_phase3_creeps_west",
			})
		else
			position = FindNamedEntityPosition({
				"trigger_teleport_phase3_creeps",
			})
		end
		self:SetObjective("grom_vanguard", position ~= nil and {
			goal = "campaign_grom_vanguard",
			anchor = position,
			label = started
				and "BREAKING GROM'S VANGUARD"
				or "GOING TO GROM'S VANGUARD",
			urgency = 1,
			reached_distance = started and 650 or 180,
		} or nil)
		return
	end

	self:SetObjective("phase_3_idle", nil)
end

function XHSBotCampaignDirector:GetObjective(playerID, hero)
	if not self:IsAutonomyAllowed() or type(self.objective) ~= "table" then
		return nil
	end
	local objective = {}
	for key, value in pairs(self.objective) do
		objective[key] = value
	end
	objective.player_id = tonumber(playerID)
	return objective
end

function XHSBotCampaignDirector:Reset()
	self.next_update = 0
	self.objective = nil
	self.stage = "inactive"
	self.shal_confirmed = false
	self.shal_entindex = nil
end

return XHSBotCampaignDirector
