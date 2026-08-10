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
local PRESENTATION_BLOCKED_BIT = 1
local GOODGUYS_VISION_BIT = 2

local EXCLUDED_UNIT_NAMES = {
	npc_dota_crate = true,
	npc_dota_vase = true,
	npc_dota_dungeon_checkpoint = true,
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

local function IsPresentationBlocked(unit)
	if not IsUsableUnit(unit) then return true end
	if SafeBooleanCall(unit, "IsInvisible") or SafeBooleanCall(unit, "IsOutOfGame") then
		return true
	end
	return unit.HasModifier ~= nil and (
		unit:HasModifier("modifier_eul_cyclone")
		or unit:HasModifier("modifier_invoker_tornado")
		or unit:HasModifier("modifier_brewmaster_storm_cyclone")
	)
end

function XHSCreepHealthBars:GetBarKind(unit)
	if not IsUsableUnit(unit) then return false end
	if unit.xhs_custom_health_bar_kind == "creep_hero" then return "creep_hero" end
	if SafeBooleanCall(unit, "IsRealHero")
		or SafeBooleanCall(unit, "IsBuilding")
		or SafeBooleanCall(unit, "IsWard")
		or SafeBooleanCall(unit, "IsCourier")
		or SafeBooleanCall(unit, "IsOther")
		or SafeBooleanCall(unit, "IsIllusion") then
		return false
	end
	if XHSIsBossDamageTarget ~= nil and XHSIsBossDamageTarget(unit) then
		return false
	end
	if unit.HasModifier ~= nil and unit:HasModifier("modifier_breakable_container") then
		return false
	end

	local unitName = unit.GetUnitName ~= nil and tostring(unit:GetUnitName() or "") or ""
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
	local kind = self:GetBarKind(unit)
	if kind == false then return false end
	local entityIndex = unit:entindex()
	self.units[tostring(entityIndex)] = {
		kind = kind,
		level = GetDisplayedUnitLevel(unit, kind),
	}

	if unit.HasModifier ~= nil
		and unit.AddNewModifier ~= nil
		and not unit:HasModifier("modifier_xhs_custom_creep_health_bar") then
		pcall(function()
			unit:AddNewModifier(unit, nil, "modifier_xhs_custom_creep_health_bar", {})
		end)
	end
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
		for entityIndex in pairs(self.units or {}) do
			local unit = EntIndexToHScript(tonumber(entityIndex) or -1)
			if IsUsableUnit(unit) and SafeBooleanCall(unit, "IsAlive") then
				hasUnits = true
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
