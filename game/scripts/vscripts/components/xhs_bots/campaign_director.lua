if XHSBotCampaignDirector == nil then
	XHSBotCampaignDirector = {}
end

XHSBotCampaignDirector.next_update = 0
XHSBotCampaignDirector.objective = nil
XHSBotCampaignDirector.stage = "inactive"
XHSBotCampaignDirector.shal_confirmed = false
XHSBotCampaignDirector.shal_entindex =
	XHSBotCampaignDirector.shal_entindex or nil
XHSBotCampaignDirector.uther_confirmed = false

local SHAL_NAME = "npc_xhs_paladin"
local UTHER_NAME = "npc_xhs_paladin_2"
local UTHER_PRISON_NAME = "npc_xhs_uther_ice_prison"
local ARTHAS_NAME = "npc_dota_hero_arthas"
local MAGTHERIDON_NAME = "npc_dota_hero_magtheridon"
local SHAL_REACHED_DISTANCE = 340

local PHASE_THREE_BOSSES = {
	{
		stage = "grom",
		quest = "kill_grom",
		goal = "campaign_grom",
		unit_name = "npc_dota_hero_grom_hellscream",
		spawn_names = { "spawn_grom_hellscream" },
		label = "GROM HELLSCREAM",
	},
	{
		stage = "illidan",
		quest = "kill_illidan",
		goal = "campaign_illidan",
		unit_name = "npc_dota_hero_illidan",
		spawn_names = { "spawn_illidan" },
		label = "ILLIDAN",
	},
	{
		stage = "balanar",
		quest = "kill_balanar",
		goal = "campaign_balanar",
		unit_name = "npc_dota_hero_balanar",
		spawn_names = { "spawn_balanar" },
		label = "BALANAR",
	},
	{
		stage = "proudmoore",
		quest = "kill_proudmoore",
		goal = "campaign_proudmoore",
		unit_name = "npc_dota_hero_proudmoore",
		spawn_names = { "spawn_admiral_proudmore" },
		label = "PROUDMOORE",
	},
}

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
	if not self:IsAutonomyAllowed()
		or self.shal_confirmed or not IsValidEntityHandle(shal)
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

function XHSBotCampaignDirector:ConfirmUtherDialog(uther)
	if not self:IsAutonomyAllowed()
		or self.uther_confirmed or not IsValidEntityHandle(uther)
		or not IsQuestActive("teleport_arthas") then
		return false
	end
	local completed = false
	for _, zone in pairs(GameMode.Zones or {}) do
		if zone ~= nil and zone.OnDialogAllConfirmed ~= nil then
			local ok = pcall(function()
				zone:OnDialogAllConfirmed(uther, 4)
			end)
			completed = completed or ok
		end
	end
	print(
		"[XHSBots][Campaign] action=confirm_uther_dialog result="
			.. tostring(completed)
	)
	self.uther_confirmed = completed
	return completed
end

function XHSBotCampaignDirector:Update(force)
	local now = GameRules:GetGameTime()
	if not force and now < (self.next_update or 0) then return end
	self.next_update = now + 0.5

	local phase = CustomTimers ~= nil
		and tonumber(CustomTimers.game_phase) or 1
	local autonomous = self:IsAutonomyAllowed()
	if not autonomous
		and phase >= 3
		and IsQuestActive("teleport_top")
		and not IsQuestComplete("teleport_top") then
		-- In mixed games the player owns campaign interactions. Keep bots visibly
		-- waiting around Shal instead of letting generic phase-three assignments
		-- pull them back and forth across the interaction area.
		local shal = self:FindShal()
		local position = IsValidEntityHandle(shal)
			and CopyPosition(shal:GetAbsOrigin()) or nil
		self:SetObjective("shal_waiting_for_player", position ~= nil and {
			goal = "campaign_wait_player",
			anchor = position,
			non_combat = true,
			attack_move = false,
			label = "WAITING FOR PLAYER",
			urgency = 0.72,
			-- Holding anywhere in this generous ring avoids oscillation while
			-- leaving the NPC approachable for the human player.
			reached_distance = 460,
		} or nil)
		return
	end
	if phase < 3 then
		self:SetObjective("waiting_phase_3", nil)
		return
	end

	if autonomous and IsQuestActive("teleport_top")
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

	local vanguard = GameMode ~= nil
		and type(GameMode.GromVanguard) == "table"
		and GameMode.GromVanguard or nil
	local vanguardQuestActive = IsQuestActive("clear_grom_vanguard")
		and not IsQuestComplete("clear_grom_vanguard")
	local vanguardFallbackActive = vanguard ~= nil
		and vanguard.started == true
		and vanguard.gate_opened ~= true
		and not IsQuestComplete("clear_grom_vanguard")
	if vanguardQuestActive or vanguardFallbackActive then
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

	-- The four bosses already exist behind their successive gates. Drive only
	-- the boss whose quest is active; otherwise an alive but still locked boss
	-- (or the stale GromVanguard.started flag) can pull bots backwards.
	for _, bossDefinition in ipairs(PHASE_THREE_BOSSES) do
		if IsQuestActive(bossDefinition.quest)
			and not IsQuestComplete(bossDefinition.quest) then
			local boss = FindUnitByName(
				bossDefinition.unit_name,
				DOTA_TEAM_CUSTOM_2,
				true
			)
			local bossIsAlive = IsValidCombatUnit(boss)
				and boss.deathStart ~= true
			local gromMirrorTrial = false
			if bossDefinition.stage == "grom" and bossIsAlive
				and boss.FindModifierByName ~= nil then
				local mirrorAI = boss:FindModifierByName(
					"modifier_xhs_grom_phase3_ai"
				)
				gromMirrorTrial = mirrorAI ~= nil
					and mirrorAI.trial_active == true
			end
			local position = gromMirrorTrial
				and FindNamedEntityPosition(bossDefinition.spawn_names)
				or bossIsAlive
				and CopyPosition(boss:GetAbsOrigin())
				or FindNamedEntityPosition(bossDefinition.spawn_names)
			self:SetObjective(bossDefinition.stage, position ~= nil and {
				goal = bossDefinition.goal,
				anchor = position,
				target_entindex = bossIsAlive and not gromMirrorTrial
					and boss:entindex() or nil,
				label = gromMirrorTrial and "SEARCHING GROM'S MIRRORS"
					or (bossIsAlive and "FIGHTING " or "GOING TO ")
						.. bossDefinition.label,
				urgency = 1,
				reached_distance = 500,
			} or nil)
			return
		end
	end

	if IsQuestActive("free_uther")
		and not IsQuestComplete("free_uther") then
		local prison = FindUnitByName(
			UTHER_PRISON_NAME,
			DOTA_TEAM_CUSTOM_2,
			true
		)
		local rescue = GameMode ~= nil and GameMode.UtherRescue or nil
		if not IsValidCombatUnit(prison) and type(rescue) == "table"
			and IsValidCombatUnit(rescue.prison) then
			prison = rescue.prison
		end
		local position = IsValidCombatUnit(prison)
			and CopyPosition(prison:GetAbsOrigin())
			or FindNamedEntityPosition({ "spawn_admiral_proudmore" })
		self:SetObjective("free_uther", position ~= nil and {
			goal = "campaign_free_uther",
			anchor = position,
			target_entindex = IsValidCombatUnit(prison)
				and prison:entindex() or nil,
			label = IsValidCombatUnit(prison)
				and "FREEING UTHER" or "GOING TO UTHER",
			urgency = 1,
			reached_distance = 400,
		} or nil)
		return
	end

	if IsQuestActive("teleport_arthas")
		and not IsQuestComplete("teleport_arthas") then
		local uther = FindUnitByName(UTHER_NAME, DOTA_TEAM_GOODGUYS, false)
		local position = IsValidEntityHandle(uther)
			and CopyPosition(uther:GetAbsOrigin())
			or FindNamedEntityPosition({ "xhs_spawner_paladin_2_vip" })
		self:SetObjective(
			autonomous and "uther" or "uther_waiting_for_player",
			position ~= nil and {
			goal = autonomous and "campaign_uther" or "campaign_wait_player",
			anchor = position,
			target_entindex = IsValidEntityHandle(uther)
				and uther:entindex() or nil,
			non_combat = true,
			attack_move = false,
			label = autonomous and "TALKING TO UTHER LIGHTBRINGER"
				or "WAITING FOR PLAYER",
			urgency = autonomous and 0.95 or 0.72,
			reached_distance = autonomous and SHAL_REACHED_DISTANCE or 460,
		} or nil)
		if autonomous and position ~= nil and self:AnyBotReached(
			position,
			SHAL_REACHED_DISTANCE
		) then
			self:ConfirmUtherDialog(uther)
		end
		return
	end

	if IsQuestActive("kill_arthas")
		and not IsQuestComplete("kill_arthas") then
		local arthas = FindUnitByName(ARTHAS_NAME, DOTA_TEAM_CUSTOM_2, true)
		local arthasIsAlive = IsValidCombatUnit(arthas)
			and arthas.deathStart ~= true
		local position = arthasIsAlive
			and CopyPosition(arthas:GetAbsOrigin())
			or FindNamedEntityPosition({
				"npc_dota_spawner_magtheridon_arena",
				"point_teleport_boss_1",
			})
		self:SetObjective("arthas", position ~= nil and {
			goal = "campaign_arthas",
			anchor = position,
			target_entindex = arthasIsAlive and arthas:entindex() or nil,
			label = arthasIsAlive and "FIGHTING ARTHAS"
				or "GOING TO ARTHAS",
			urgency = 1,
			reached_distance = 500,
		} or nil)
		return
	end

	self:SetObjective("phase_3_idle", nil)
end

function XHSBotCampaignDirector:GetObjective(playerID, hero)
	if type(self.objective) ~= "table" then
		return nil
	end
	local playerWaitObjective = self.stage == "shal_waiting_for_player"
		or self.stage == "uther_waiting_for_player"
	-- Mixed games still need explicit combat routing after the player starts a
	-- quest. Only autonomous non-combat interactions remain bot-only.
	if not self:IsAutonomyAllowed()
		and self.objective.non_combat == true
		and not playerWaitObjective then
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
	self.uther_confirmed = false
end

return XHSBotCampaignDirector
