LinkLuaModifier(
	"modifier_xhs_custom_creep_health_bar",
	"components/creep_health_bars/modifier.lua",
	LUA_MODIFIER_MOTION_NONE
)

if XHSCreepHealthBars == nil then
	XHSCreepHealthBars = class({})
end

local NET_TABLE = "xhs_creep_health_bars"
local NET_KEY = "units"
local THINK_INTERVAL = 0.25
local SUMMON_CAST_CAPTURE_WINDOW = 2.0
local PRESENTATION_BLOCKED_BIT = 1
local GOODGUYS_VISION_BIT = 2

local EXCLUDED_UNIT_NAMES = {
	npc_dota_crate = true,
	npc_dota_vase = true,
	npc_dota_dungeon_checkpoint = true,
	npc_dota_lich_king_sindragosa = true,
	npc_xhs_hero_tombstone = true,
}

local HEALTH_BAR_HIDDEN_ILLUSION_NAMES = {
	npc_dota_hero_grom_hellscream = true,
}

local function IsUsableUnit(unit)
	return unit ~= nil
		and IsValidEntity(unit)
		and (unit.IsNull == nil or not unit:IsNull())
		and unit.entindex ~= nil
end

local function GetUsableGameModeEntity()
	if GameRules == nil or GameRules.GetGameModeEntity == nil then return nil end
	local ok, gameModeEntity = pcall(function()
		return GameRules:GetGameModeEntity()
	end)
	if not ok
		or gameModeEntity == nil
		or gameModeEntity.SetContextThink == nil
		or (gameModeEntity.IsNull ~= nil and gameModeEntity:IsNull()) then
		return nil
	end
	return gameModeEntity
end

local function SafeBooleanCall(unit, methodName)
	if unit == nil or type(unit[methodName]) ~= "function" then return false end
	local ok, result = pcall(function() return unit[methodName](unit) end)
	return ok and result == true
end

local function ShouldHideIllusionHealthBar(unit)
	if not IsUsableUnit(unit) or not SafeBooleanCall(unit, "IsIllusion") then
		return false
	end
	local unitName = unit.GetUnitName ~= nil and tostring(unit:GetUnitName() or "") or ""
	return HEALTH_BAR_HIDDEN_ILLUSION_NAMES[unitName] == true
end

local function ApplyNoHealthBarModifier(unit)
	if not IsUsableUnit(unit)
		or unit.HasModifier == nil
		or unit.AddNewModifier == nil
		or unit:HasModifier("modifier_xhs_custom_creep_health_bar") then
		return
	end
	pcall(function()
		unit:AddNewModifier(unit, nil, "modifier_xhs_custom_creep_health_bar", {})
	end)
end

local function HasPlayerController(unit)
	if not IsUsableUnit(unit) then return false end
	if SafeBooleanCall(unit, "IsControllableByAnyPlayer") then return true end
	if unit.GetPlayerOwnerID == nil then return false end
	local ok, playerID = pcall(function() return unit:GetPlayerOwnerID() end)
	if not ok or tonumber(playerID) == nil or tonumber(playerID) < 0 then return false end
	return PlayerResource == nil
		or PlayerResource.IsValidPlayerID == nil
		or PlayerResource:IsValidPlayerID(tonumber(playerID))
end

local function GetSummonOwnerHero(unit)
	if not IsUsableUnit(unit) then return nil end

	local current = unit
	local visited = {}
	for _ = 1, 4 do
		local owner = nil
		for _, methodName in ipairs({ "GetOwnerEntity", "GetOwner" }) do
			if current ~= nil and type(current[methodName]) == "function" then
				local ok, candidate = pcall(function()
					return current[methodName](current)
				end)
				if ok and IsUsableUnit(candidate) and candidate ~= current then
					owner = candidate
					break
				end
			end
		end

		if owner == nil or visited[owner] then break end
		visited[owner] = true
		if SafeBooleanCall(owner, "IsRealHero") then return owner end
		current = owner
	end

	if unit.GetPlayerOwnerID ~= nil and PlayerResource ~= nil then
		local ok, playerID = pcall(function() return unit:GetPlayerOwnerID() end)
		playerID = ok and tonumber(playerID) or nil
		if playerID ~= nil and playerID >= 0
			and PlayerResource.GetSelectedHeroEntity ~= nil then
			local hero = PlayerResource:GetSelectedHeroEntity(playerID)
			if IsUsableUnit(hero) then return hero end
		end
	end

	return nil
end

local function CaptureSummonAbilityLevel(unit)
	if not IsUsableUnit(unit) or tonumber(unit.xhs_summon_ability_level) ~= nil then return end
	local ownerHero = GetSummonOwnerHero(unit)
	local cast = ownerHero ~= nil and ownerHero.xhs_last_executed_ability or nil
	if type(cast) ~= "table" then return end

	local level = math.floor(tonumber(cast.level) or 0)
	local castTime = tonumber(cast.cast_time)
	local now = GameRules ~= nil and GameRules.GetGameTime ~= nil
		and GameRules:GetGameTime() or nil
	if level <= 0 or castTime == nil or now == nil
		or now < castTime or now - castTime > SUMMON_CAST_CAPTURE_WINDOW then
		return
	end

	unit.xhs_summon_ability_level = level
	unit.xhs_summon_ability_name = tostring(cast.name or "")
end

local function IsPresentationBlocked(unit)
	if not IsUsableUnit(unit) then return true end
	if SafeBooleanCall(unit, "IsInvisible") or SafeBooleanCall(unit, "IsOutOfGame") then
		return true
	end
	local unitName = unit.GetUnitName ~= nil and tostring(unit:GetUnitName() or "") or ""
	if unit.HasModifier ~= nil then
		-- The prison is only a combat target after Proudmoore's protection is
		-- removed. Before that point neither its Vanilla nor custom bar should
		-- disclose it as an enemy target.
		if unitName == "npc_xhs_uther_ice_prison"
			and unit:HasModifier("modifier_invulnerable") then
			return true
		end
		-- Uther's own bar stays hidden for the complete imprisoned/frozen state.
		-- The shared no-health-bar modifier suppresses Vanilla while this relay
		-- suppresses the replacement bar.
		if unitName == "npc_xhs_paladin_2"
			and (unit:HasModifier("modifier_pause_creeps")
				or unit:HasModifier("modifier_xhs_uther_prison_target")) then
			return true
		end
	end
	return unit.HasModifier ~= nil and (
		unit:HasModifier("modifier_eul_cyclone")
		or unit:HasModifier("modifier_invoker_tornado")
		or unit:HasModifier("modifier_brewmaster_storm_cyclone")
	)
end

function XHSCreepHealthBars:GetBarKind(unit)
	if not IsUsableUnit(unit) then return false end
	local unitName = unit.GetUnitName ~= nil and tostring(unit:GetUnitName() or "") or ""
	-- The prison uses a ward relationship for targeting, but still needs the
	-- custom bar pipeline so its Vanilla bar can remain hidden until activation.
	if unitName == "npc_xhs_uther_ice_prison" then return "creep" end
	if unit.xhs_custom_health_bar_kind == "creep_hero" then return "creep_hero" end
	if XHSIsBossDamageTarget ~= nil and XHSIsBossDamageTarget(unit) then
		return false
	end

	-- Enemy hero illusions must use the same segmented bar as their original
	-- creep-hero. Leaving the Vanilla illusion bar visible makes the real unit
	-- immediately identifiable. Radiant player illusions stay on the Vanilla
	-- hero presentation so they continue to match their owning player hero.
	if SafeBooleanCall(unit, "IsIllusion") then
		local isHeroUnit = SafeBooleanCall(unit, "IsHero")
			or SafeBooleanCall(unit, "IsConsideredHero")
			or SafeBooleanCall(unit, "IsRealHero")
		local unitTeam = unit.GetTeamNumber ~= nil and unit:GetTeamNumber() or nil
		if isHeroUnit and unitTeam ~= DOTA_TEAM_GOODGUYS then
			return "creep_hero"
		end
		return false
	end

	if SafeBooleanCall(unit, "IsRealHero")
		or SafeBooleanCall(unit, "IsBuilding")
		or SafeBooleanCall(unit, "IsWard")
		or SafeBooleanCall(unit, "IsCourier")
		or SafeBooleanCall(unit, "IsOther") then
		return false
	end
	if unit.HasModifier ~= nil and unit:HasModifier("modifier_breakable_container") then
		return false
	end

	if EXCLUDED_UNIT_NAMES[unitName]
		or string.find(unitName, "dummy", 1, true) ~= nil
		or string.find(unitName, "thinker", 1, true) ~= nil
		or string.find(unitName, "ward", 1, true) ~= nil then
		return false
	end

	-- ConsideredHero summons (Spirit Bear, special-wave units and similar NPCs)
	-- need the richer hero-like bar without entering the real-player hero path.
	if SafeBooleanCall(unit, "IsHero") or SafeBooleanCall(unit, "IsConsideredHero") then
		return "creep_hero"
	end
	if SafeBooleanCall(unit, "IsCreature") or SafeBooleanCall(unit, "IsCreep") then
		if HasPlayerController(unit) then return "creep_controlled" end
		if unit.GetTeamNumber ~= nil and unit:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
			return false
		end
		return "creep"
	end
	return false
end

function XHSCreepHealthBars:ShouldTrack(unit)
	return self:GetBarKind(unit) ~= false
end

local function GetDisplayedUnitLevel(unit, kind)
	local summonLevel = unit ~= nil
		and math.floor(tonumber(unit.xhs_summon_ability_level) or 0) or 0
	if summonLevel > 0 then return summonLevel end
	if kind ~= "creep_controlled" or unit == nil or unit.GetLevel == nil then return nil end
	local ok, level = pcall(function() return unit:GetLevel() end)
	level = ok and math.floor(tonumber(level) or 0) or 0
	return level > 0 and level or nil
end

function XHSCreepHealthBars:Publish()
	local entries = {}
	for entityIndex, unitData in pairs(self.units or {}) do
		local unit = EntIndexToHScript(tonumber(entityIndex) or -1)
		if IsUsableUnit(unit) and SafeBooleanCall(unit, "IsAlive") then
			local kind = type(unitData) == "table" and unitData.kind or unitData
			local level = type(unitData) == "table" and unitData.level or nil
			entries[#entries + 1] = {
				entindex = tonumber(entityIndex),
				kind = kind,
				level = level,
			}
		else
			self.units[entityIndex] = nil
		end
	end
	table.sort(entries, function(a, b) return a.entindex < b.entindex end)
	CustomNetTables:SetTableValue(NET_TABLE, NET_KEY, { entries = entries })
end

function XHSCreepHealthBars:QueuePublish()
	if self.publishQueued then return end
	local gameModeEntity = GetUsableGameModeEntity()
	if gameModeEntity == nil then
		-- Early map spawns can arrive before the game-mode entity exists. The
		-- next accepted spawn will publish the complete registry.
		self.publishPending = true
		return
	end
	self.publishQueued = true
	self.publishPending = false
	gameModeEntity:SetContextThink("xhs_creep_health_bars_publish", function()
		self.publishQueued = false
		self:Publish()
		return nil
	end, 0.03)
end

function XHSCreepHealthBars:Apply(unit)
	local unitName = IsUsableUnit(unit) and unit.GetUnitName ~= nil
		and tostring(unit:GetUnitName() or "") or ""
	if EXCLUDED_UNIT_NAMES[unitName] then
		local entityIndex = IsUsableUnit(unit) and tostring(unit:entindex()) or nil
		local wasTracked = entityIndex ~= nil and self.units[entityIndex] ~= nil
		if entityIndex ~= nil then self.units[entityIndex] = nil end
		ApplyNoHealthBarModifier(unit)
		if wasTracked then self:QueuePublish() end
		return false
	end
	if ShouldHideIllusionHealthBar(unit) then
		local hiddenEntityIndex = tostring(unit:entindex())
		local wasTracked = self.units[hiddenEntityIndex] ~= nil
		self.units[hiddenEntityIndex] = nil
		ApplyNoHealthBarModifier(unit)
		if wasTracked then self:QueuePublish() end
		return true
	end

	CaptureSummonAbilityLevel(unit)
	local kind = self:GetBarKind(unit)
	if kind == false then return false end
	local entityIndex = unit:entindex()
	self.units[tostring(entityIndex)] = {
		kind = kind,
		level = GetDisplayedUnitLevel(unit, kind),
	}

	ApplyNoHealthBarModifier(unit)
	-- Establish visibility before publishing the entity to Panorama. This avoids
	-- a one-frame flash for intentionally hidden targets such as Uther's prison.
	self:RefreshPresentation(unit)
	self:QueuePublish()
	self:EnsureThink()
	return true
end

function XHSCreepHealthBars:RefreshPresentation(unit)
	if not IsUsableUnit(unit) then return false end
	local modifier = unit.FindModifierByName ~= nil
		and unit:FindModifierByName("modifier_xhs_custom_creep_health_bar")
		or nil
	if modifier == nil then return false end

	local mask = IsPresentationBlocked(unit) and PRESENTATION_BLOCKED_BIT or 0
	local origin = unit.GetAbsOrigin ~= nil and unit:GetAbsOrigin() or nil
	if origin ~= nil
		and (IsLocationVisible == nil or IsLocationVisible(DOTA_TEAM_GOODGUYS, origin)) then
		mask = mask + GOODGUYS_VISION_BIT
	end
	if modifier:GetStackCount() ~= mask then modifier:SetStackCount(mask) end
	return true
end

function XHSCreepHealthBars:EnsureThink()
	if self.thinkRunning then return end
	local gameModeEntity = GetUsableGameModeEntity()
	if gameModeEntity == nil then return end
	self.thinkRunning = true
	gameModeEntity:SetContextThink("xhs_creep_health_bars_visibility", function()
		local hasUnits = false
		local registryChanged = false
		for entityIndex, unitData in pairs(self.units or {}) do
			local unit = EntIndexToHScript(tonumber(entityIndex) or -1)
			if IsUsableUnit(unit) and SafeBooleanCall(unit, "IsAlive") then
				hasUnits = true
				-- Ownership and MODIFIER_EVENT_ON_ABILITY_EXECUTED can settle just
				-- after npc_spawned. Retry during the short capture window so the
				-- initial unit-level fallback cannot become permanently cached.
				CaptureSummonAbilityLevel(unit)
				if type(unitData) == "table" then
					local displayedLevel = GetDisplayedUnitLevel(unit, unitData.kind)
					if unitData.level ~= displayedLevel then
						unitData.level = displayedLevel
						registryChanged = true
					end
				end
				self:RefreshPresentation(unit)
			else
				self.units[entityIndex] = nil
				registryChanged = true
			end
		end
		if registryChanged then self:QueuePublish() end
		if not hasUnits then
			self.thinkRunning = false
			return nil
		end
		return THINK_INTERVAL
	end, THINK_INTERVAL)
end

function XHSCreepHealthBars:ProcessPendingSpawns()
	self.spawnQueued = false
	local pendingSpawns = self.pendingSpawns or {}
	self.pendingSpawns = {}
	for entityIndex in pairs(pendingSpawns) do
		local unit = EntIndexToHScript(tonumber(entityIndex) or -1)
		if IsUsableUnit(unit) then self:Apply(unit) end
	end
end

function XHSCreepHealthBars:QueueSpawnProcessing()
	if self.spawnQueued or next(self.pendingSpawns or {}) == nil then return end
	local gameModeEntity = GetUsableGameModeEntity()
	if gameModeEntity == nil then return end
	self.spawnQueued = true
	gameModeEntity:SetContextThink("xhs_creep_health_bars_spawn", function()
		self:ProcessPendingSpawns()
		return nil
	end, 0.03)
end

function XHSCreepHealthBars:OnNPCSpawned(event)
	local entityIndex = tonumber(event and event.entindex)
	if entityIndex == nil then return end
	-- Ownership/control is commonly assigned immediately after CreateUnitByName.
	-- One shared queue preserves that delay without one think/closure per NPC.
	self.pendingSpawns[tostring(entityIndex)] = true
	self:QueueSpawnProcessing()
end

function XHSCreepHealthBars:Init()
	if self.initialized then return end
	self.initialized = true
	self.units = {}
	self.publishQueued = false
	self.publishPending = false
	self.thinkRunning = false
	self.pendingSpawns = {}
	self.spawnQueued = false
	CustomNetTables:SetTableValue(NET_TABLE, NET_KEY, { entries = {} })
	ListenToGameEvent("npc_spawned", function(event)
		self:OnNPCSpawned(event)
	end, nil)
	ListenToGameEvent("game_rules_state_change", function()
		self:QueueSpawnProcessing()
	end, nil)
end

XHSCreepHealthBars:Init()

return XHSCreepHealthBars
