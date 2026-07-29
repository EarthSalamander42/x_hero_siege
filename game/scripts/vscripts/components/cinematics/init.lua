if XHSCinematics == nil then
	_G.XHSCinematics = {}
end

LinkLuaModifier(
	"modifier_xhs_cinematic_hide_health_bars",
	"components/cinematics/modifier_hide_health_bars.lua",
	LUA_MODIFIER_MOTION_NONE
)

XHSCinematics.active_all = XHSCinematics.active_all or {}
XHSCinematics.active_players = XHSCinematics.active_players or {}
XHSCinematics.locked_units = XHSCinematics.locked_units or {}
XHSCinematics.health_bar_units = XHSCinematics.health_bar_units or {}
XHSCinematics.serial = XHSCinematics.serial or 0

local function BuildPayload(cinematicId, options)
	options = options or {}
	return {
		id = tostring(cinematicId or "default"),
		duration = tonumber(options.duration) or 0,
		letterbox_pct = tonumber(options.letterbox_pct) or 10,
		transition = tonumber(options.transition) or 0.7,
		hide_hud = options.hide_hud == false and 0 or 1,
		allow_dialog_ui = options.allow_dialog_ui == true and 1 or 0,
		camera_entindex = tonumber(options.camera_entindex) or -1,
		camera_position = options.camera_position or "",
		camera_speed = tonumber(options.camera_speed) or 0.55,
		native_camera = options.native_camera == true and 1 or 0,
		return_camera = options.return_camera == false and 0 or 1,
		music = tostring(options.music or ""),
		music_layers = math.max(1, math.floor(tonumber(options.music_layers) or 1)),
		title = tostring(options.title or ""),
		subtitle = tostring(options.subtitle or ""),
	}
end

local function GetPlayerID(player)
	if type(player) == "number" then return player end
	if player ~= nil and player.GetPlayerID ~= nil then return player:GetPlayerID() end
	return -1
end

local function IsValidUnit(unit)
	return unit ~= nil and IsValidEntity(unit) and not unit:IsNull()
end

function XHSCinematics:ShouldHideHealthBars()
	for _, state in pairs(self.active_all) do
		if state.hide_health_bars then return true end
	end
	for _, playerStates in pairs(self.active_players) do
		for _, state in pairs(playerStates) do
			if state.hide_health_bars then return true end
		end
	end
	return false
end

function XHSCinematics:ApplyHealthBarMask()
	local targetTypes = (DOTA_UNIT_TARGET_HERO or 0)
		+ (DOTA_UNIT_TARGET_BASIC or 0)
		+ (DOTA_UNIT_TARGET_BUILDING or 0)
	local targetFlags = (DOTA_UNIT_TARGET_FLAG_INVULNERABLE or 0)
		+ (DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD or 0)
	local units = FindUnitsInRadius(
		DOTA_TEAM_NEUTRALS,
		Vector(0, 0, 0),
		nil,
		FIND_UNITS_EVERYWHERE,
		DOTA_UNIT_TARGET_TEAM_BOTH,
		targetTypes,
		targetFlags,
		FIND_ANY_ORDER,
		false
	)

	for _, unit in pairs(units) do
		if IsValidUnit(unit) then
			local unitIndex = unit:entindex()
			if not unit:HasModifier("modifier_xhs_cinematic_hide_health_bars") then
				unit:AddNewModifier(unit, nil, "modifier_xhs_cinematic_hide_health_bars", {})
			end
			self.health_bar_units[unitIndex] = true
		end
	end
end

function XHSCinematics:RemoveHealthBarMask()
	for unitIndex, _ in pairs(self.health_bar_units) do
		local unit = EntIndexToHScript(tonumber(unitIndex) or -1)
		if IsValidUnit(unit) and unit:HasModifier("modifier_xhs_cinematic_hide_health_bars") then
			unit:RemoveModifierByName("modifier_xhs_cinematic_hide_health_bars")
		end
	end
	self.health_bar_units = {}
end

function XHSCinematics:RefreshHealthBarVisibility()
	local shouldHide = self:ShouldHideHealthBars()
	if not shouldHide then
		self.health_bar_watch_active = false
		self:RemoveHealthBarMask()
		return
	end

	self:ApplyHealthBarMask()
	if self.health_bar_watch_active or Timers == nil then return end

	self.health_bar_watch_active = true
	Timers:CreateTimer(function()
		if not self.health_bar_watch_active or not self:ShouldHideHealthBars() then
			self.health_bar_watch_active = false
			self:RemoveHealthBarMask()
			return nil
		end

		-- Catch units and buildings spawned after cinematic begin as well.
		self:ApplyHealthBarMask()
		return 0.1
	end)
end

function XHSCinematics:IsOrderLocked(playerID)
	playerID = tonumber(playerID) or -1
	if playerID < 0 then return false end

	for _, state in pairs(self.active_all) do
		if state.lock_orders then return true end
	end
	local playerStates = self.active_players[playerID]
	if playerStates ~= nil then
		for _, state in pairs(playerStates) do
			if state.lock_orders then return true end
		end
	end
	return false
end

function XHSCinematics:RefreshPlayerLocks()
	local units = FindUnitsInRadius(
		DOTA_TEAM_GOODGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL,
		DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false
	)
	for _, unit in pairs(units) do
		if IsValidUnit(unit) and unit.GetPlayerOwnerID ~= nil then
			local unitIndex = unit:entindex()
			local playerID = unit:GetPlayerOwnerID()
			local shouldLock = playerID ~= nil and playerID >= 0 and self:IsOrderLocked(playerID)
			if shouldLock and not unit:HasModifier("modifier_cinematic_pause") then
				unit:AddNewModifier(unit, nil, "modifier_cinematic_pause", { ramp_duration = 0.12 })
				self.locked_units[unitIndex] = true
			elseif not shouldLock and self.locked_units[unitIndex] then
				if unit:HasModifier("modifier_cinematic_pause") then
					unit:RemoveModifierByName("modifier_cinematic_pause")
				end
				self.locked_units[unitIndex] = nil
			end
		end
	end
end

function XHSCinematics:ScheduleEnd(playerID, cinematicId, duration, serial)
	if duration <= 0 or Timers == nil then return end
	Timers:CreateTimer(duration, function()
		local states = playerID == nil and self.active_all or self.active_players[playerID]
		local state = states ~= nil and states[cinematicId] or nil
		if state == nil or state.serial ~= serial then return nil end
		if playerID == nil then
			self:EndForAll(cinematicId)
		else
			self:EndForPlayer(playerID, cinematicId)
		end
		return nil
	end)
end

function XHSCinematics:BeginForPlayer(player, cinematicId, options)
	local playerID = GetPlayerID(player)
	if playerID < 0 then return end
	player = PlayerResource:GetPlayer(playerID)
	if player == nil then return end

	options = options or {}
	cinematicId = tostring(cinematicId or "default")
	self.serial = self.serial + 1
	self.active_players[playerID] = self.active_players[playerID] or {}
	self.active_players[playerID][cinematicId] = {
		lock_orders = options.lock_orders ~= false,
		hide_health_bars = options.hide_health_bars ~= false,
		serial = self.serial,
	}
	CustomGameEventManager:Send_ServerToPlayer(player, "xhs_cinematic_begin", BuildPayload(cinematicId, options))
	self:RefreshPlayerLocks()
	self:RefreshHealthBarVisibility()
	self:ScheduleEnd(playerID, cinematicId, tonumber(options.duration) or 0, self.serial)
end

function XHSCinematics:BeginForAll(cinematicId, options)
	options = options or {}
	cinematicId = tostring(cinematicId or "default")
	self.serial = self.serial + 1
	self.active_all[cinematicId] = {
		lock_orders = options.lock_orders ~= false,
		hide_health_bars = options.hide_health_bars ~= false,
		serial = self.serial,
	}
	CustomGameEventManager:Send_ServerToAllClients("xhs_cinematic_begin", BuildPayload(cinematicId, options))
	self:RefreshPlayerLocks()
	self:RefreshHealthBarVisibility()
	self:ScheduleEnd(nil, cinematicId, tonumber(options.duration) or 0, self.serial)
end

function XHSCinematics:EndForPlayer(player, cinematicId)
	local playerID = GetPlayerID(player)
	if playerID < 0 then return end
	player = PlayerResource:GetPlayer(playerID)
	if player == nil then return end

	cinematicId = tostring(cinematicId or "default")
	if self.active_players[playerID] ~= nil then
		self.active_players[playerID][cinematicId] = nil
	end
	CustomGameEventManager:Send_ServerToPlayer(player, "xhs_cinematic_end", { id = cinematicId })
	self:RefreshPlayerLocks()
	self:RefreshHealthBarVisibility()
end

function XHSCinematics:EndForAll(cinematicId)
	cinematicId = tostring(cinematicId or "default")
	self.active_all[cinematicId] = nil
	CustomGameEventManager:Send_ServerToAllClients("xhs_cinematic_end", { id = cinematicId })
	self:RefreshPlayerLocks()
	self:RefreshHealthBarVisibility()
end

return XHSCinematics
