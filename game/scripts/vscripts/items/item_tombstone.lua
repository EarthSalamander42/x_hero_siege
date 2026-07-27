item_tombstone = item_tombstone or class({})

local SupporterRecoveryEffects = require("components/battlepass/recovery_effects"):Init()

local BASE_CHANNEL_TIME = 5.0
local MIN_SHARED_CHANNEL_TIME = 0.1
local REVIVE_PARTICLE = "particles/items_fx/aegis_respawn.vpcf"
local CHANNEL_PARTICLE = "particles/items_fx/aegis_respawn_timer.vpcf"
local CHANNEL_START_SOUND = "ui_generic_button_click"
local CHANNEL_COMPLETE_SOUND = "Hero_Omniknight.GuardianAngel.Cast"

local function IsValidEntityHandle(entity)
	return entity ~= nil and IsValidEntity(entity) and not entity:IsNull()
end

local function GetReviveHero(item)
	if not IsValidEntityHandle(item) then return nil end

	local entindex = tonumber(item.xhs_revive_hero_entindex)
	if entindex ~= nil and entindex > 0 then
		local hero = EntIndexToHScript(entindex)
		if IsValidEntityHandle(hero) and hero:IsRealHero() then
			return hero
		end
	end

	local purchaser = item:GetPurchaser()
	if IsValidEntityHandle(purchaser) and purchaser:IsRealHero() then
		return purchaser
	end

	return nil
end

local function GetChannelCaster(item)
	if not IsValidEntityHandle(item) then return nil end

	local entindex = tonumber(item.xhs_reviver_entindex)
	if entindex ~= nil and entindex > 0 then
		local caster = EntIndexToHScript(entindex)
		if IsValidEntityHandle(caster) then
			return caster
		end
	end

	local caster = item:GetCaster()
	if IsValidEntityHandle(caster) then
		return caster
	end

	return nil
end

local function GetChannelNotificationId(caster)
	if not IsValidEntityHandle(caster) then return "" end
	return "tombstone_" .. tostring(caster:entindex())
end

local function SendChannelNotification(item, eventName, data)
	local caster = GetChannelCaster(item)
	if not IsValidEntityHandle(caster) then return end

	local playerID = caster:GetPlayerOwnerID()
	if playerID == nil or playerID < 0 then return end
	local player = PlayerResource:GetPlayer(playerID)
	if player == nil then return end

	data = data or {}
	data.id = GetChannelNotificationId(caster)
	CustomGameEventManager:Send_ServerToPlayer(player, eventName, data)
end

local function SendChannelStartNotification(item, playSound)
	local hero = GetReviveHero(item)
	local targetPlayerID = -1
	if IsValidEntityHandle(hero) then
		local resolvedPlayerID = hero:GetPlayerOwnerID()
		if resolvedPlayerID ~= nil and resolvedPlayerID >= 0 then
			targetPlayerID = resolvedPlayerID
		end
	end

	SendChannelNotification(item, "xhs_channel_notification_start", {
		duration = item:GetChannelTime(),
		end_time = GameRules:GetGameTime() + item:GetChannelTime(),
		item_name = "item_tombstone",
		target_player_id = targetPlayerID,
		target_unit_name = IsValidEntityHandle(hero) and hero:GetUnitName() or "",
		sound = playSound and CHANNEL_START_SOUND or "none",
	})
end

local function SendChannelFinishNotification(item, completed)
	SendChannelNotification(item, "xhs_channel_notification_finish", {
		result = completed and "completed" or "cancelled",
	})
end

local function GetSharedState(hero, create)
	if not IsValidEntityHandle(hero) then return nil end
	if hero.xhs_tombstone_state == nil and create then
		hero.xhs_tombstone_state = {
			channels = {},
			end_time = nil,
			completed = false,
		}
	end
	return hero.xhs_tombstone_state
end

local function SetReviveChannelNetTable(hero, active, duration, endTime, channelCount)
	if not IsValidEntityHandle(hero) or not hero:IsRealHero() or not hero:IsOwnedByAnyPlayer() then return end

	CustomNetTables:SetTableValue("player_table", tostring(hero:entindex()) .. "_revive_channel", {
		active = active == true and 1 or 0,
		duration = tonumber(duration) or 0,
		end_time = tonumber(endTime) or 0,
		channels = tonumber(channelCount) or 0,
	})
end

function XHSClearTombstoneReviveState(hero)
	SetReviveChannelNetTable(hero, false, 0, 0, 0)
end

local function DestroyChannelParticle(item, interrupted)
	if item.xhs_channel_particle == nil then return end
	ParticleManager:DestroyParticle(item.xhs_channel_particle, interrupted == true)
	ParticleManager:ReleaseParticleIndex(item.xhs_channel_particle)
	item.xhs_channel_particle = nil
end

local function RemoveItemFromInventory(item, owner)
	if not IsValidEntityHandle(item) or not IsValidEntityHandle(owner) then return false end
	for slot = 0, 14 do
		if owner:GetItemInSlot(slot) == item then
			owner:RemoveItem(item)
			return true
		end
	end
	return false
end

local function IsActiveChannelItem(item)
	if not IsValidEntityHandle(item) then return false end
	if item.xhs_restart_in_progress == true then
		return IsValidEntityHandle(GetChannelCaster(item))
	end
	if item.xhs_channel_started ~= true then return false end
	local caster = GetChannelCaster(item)
	return IsValidEntityHandle(caster) and caster:IsAlive() and item:IsChanneling()
end

local function PruneChannels(state)
	if state == nil or state.channels == nil then return 0 end
	local count = 0
	for key, item in pairs(state.channels) do
		if IsActiveChannelItem(item) then
			count = count + 1
		else
			state.channels[key] = nil
		end
	end
	return count
end

local function PublishReviveChannelState(hero, state)
	if not IsValidEntityHandle(hero) or hero:IsAlive() or state == nil then
		XHSClearTombstoneReviveState(hero)
		return 0
	end

	local activeCount = PruneChannels(state)
	local endTime = tonumber(state.end_time) or 0
	local remaining = math.max(0, endTime - GameRules:GetGameTime())
	if activeCount <= 0 or remaining <= 0 then
		XHSClearTombstoneReviveState(hero)
		return 0
	end

	SetReviveChannelNetTable(hero, true, remaining, endTime, activeCount)
	return activeCount
end

local function UnregisterChannel(item)
	local hero = GetReviveHero(item)
	local state = GetSharedState(hero, false)
	local activeCount = 0
	if state ~= nil and state.channels ~= nil then
		state.channels[item:entindex()] = nil
		activeCount = PruneChannels(state)
		if activeCount == 0 then
			state.end_time = nil
		end
	end
	PublishReviveChannelState(hero, state)
	return activeCount
end

local function RemoveChannelItem(item)
	if not IsValidEntityHandle(item) then return end
	DestroyChannelParticle(item, true)
	local caster = GetChannelCaster(item)
	RemoveItemFromInventory(item, caster)
	if IsValidEntityHandle(item) then
		UTIL_Remove(item)
	end
end

local function RegisterClaimedTombstoneDrop(item, hero)
	if not IsValidEntityHandle(item) then return end

	local dropEntindex = tonumber(item.xhs_tombstone_drop_entindex)
	if IsValidEntityHandle(hero) then
		if dropEntindex ~= nil and dropEntindex > 0 then
			hero.xhs_tombstone_claimed_drops = hero.xhs_tombstone_claimed_drops or {}
			hero.xhs_tombstone_claimed_drops[dropEntindex] = true
		end
		if hero.xhs_tombstone_item == item then
			hero.xhs_tombstone_item = nil
			hero.xhs_tombstone_drop = nil
		end
	end
	item.xhs_tombstone_drop_entindex = nil
end

function XHSGetTombstoneReviveHero(item)
	return GetReviveHero(item)
end

function XHSIsTombstonePickupByActiveChanneler(caster, target)
	if not IsValidEntityHandle(caster) or not IsValidEntityHandle(target) then return false end

	local item = target
	if target.GetContainedItem ~= nil then
		local containedItem = target:GetContainedItem()
		if IsValidEntityHandle(containedItem) then
			item = containedItem
		end
	end
	if not IsValidEntityHandle(item)
		or item.GetAbilityName == nil
		or item:GetAbilityName() ~= "item_tombstone" then
		return false
	end

	local hero = GetReviveHero(item)
	local state = GetSharedState(hero, false)
	if state == nil or state.channels == nil then return false end

	for _, channelItem in pairs(state.channels) do
		if IsActiveChannelItem(channelItem) and GetChannelCaster(channelItem) == caster then
			return true
		end
	end
	return false
end

function XHSRearmTombstoneItem(item)
	if not IsValidEntityHandle(item) or item.xhs_rearm_scheduled == true then return end
	item.xhs_rearm_scheduled = true
	SendChannelFinishNotification(item, false)

	local hero = GetReviveHero(item)
	local caster = GetChannelCaster(item)
	local position = item.xhs_tombstone_position
	if position == nil and IsValidEntityHandle(hero) then
		position = hero:GetAbsOrigin()
	end
	if position == nil and IsValidEntityHandle(caster) then
		position = caster:GetAbsOrigin()
	end
	position = position or Vector(0, 0, 0)
	local revivePosition = Vector(position.x, position.y, position.z)

	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("xhs_tombstone_rearm"), function()
		local remainingChannels = UnregisterChannel(item)
		RemoveChannelItem(item)

		if IsValidEntityHandle(hero) and not hero:IsAlive() and EnsureXHSTombstoneGroundDrop ~= nil then
			EnsureXHSTombstoneGroundDrop(hero, revivePosition)
		end
		if remainingChannels == 0 and XHSCleanupClaimedTombstoneDrops ~= nil then
			XHSCleanupClaimedTombstoneDrops(hero, 0.2)
		end
		return nil
	end, 0)
end

function item_tombstone:GetChannelTime()
	return self.xhs_channel_duration or BASE_CHANNEL_TIME
end

function item_tombstone:OnAbilityPhaseStart()
	if not IsServer() then return true end
	if self.xhs_finish_handled == true or self.xhs_rearm_scheduled == true then return false end

	local caster = self:GetCaster()
	local hero = GetReviveHero(self)
	if not IsValidEntityHandle(caster) or not caster:IsRealHero() then
		return false
	end
	if not IsValidEntityHandle(hero) or hero:IsAlive() then
		return false
	end
	if caster:GetTeamNumber() ~= hero:GetTeamNumber() then
		return false
	end

	self.xhs_reviver_entindex = caster:entindex()
	local state = GetSharedState(hero, true)

	if self.xhs_restart_cast == true then
		self.xhs_channel_duration = self.xhs_forced_channel_duration or BASE_CHANNEL_TIME
		return true
	end

	for _, channelItem in pairs(state.channels) do
		if IsActiveChannelItem(channelItem) and GetChannelCaster(channelItem) == caster then
			return false
		end
	end

	local activeCount = PruneChannels(state)
	if activeCount > 0 and state.end_time ~= nil then
		local remaining = math.max(MIN_SHARED_CHANNEL_TIME, state.end_time - GameRules:GetGameTime())
		self.xhs_channel_duration = math.max(MIN_SHARED_CHANNEL_TIME, remaining * 0.5)
		self.xhs_accelerates_shared_channel = true
	else
		self.xhs_channel_duration = BASE_CHANNEL_TIME
		self.xhs_accelerates_shared_channel = false
	end

	return true
end

local function RestartExistingChannel(item, duration)
	if not IsActiveChannelItem(item) then return end

	local caster = GetChannelCaster(item)
	item.xhs_restart_in_progress = true
	item.xhs_restart_pending = true
	item.xhs_forced_channel_duration = duration
	item.xhs_finish_handled = false
	caster:InterruptChannel()

	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("xhs_tombstone_restart"), function()
		if not IsValidEntityHandle(item) or not IsValidEntityHandle(caster) or not caster:IsAlive() then
			if IsValidEntityHandle(item) then
				XHSRearmTombstoneItem(item)
			end
			return nil
		end

		item.xhs_restart_cast = true
		item.xhs_channel_started = false
		item.xhs_finish_handled = false
		ExecuteOrderFromTable({
			UnitIndex = caster:entindex(),
			OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
			AbilityIndex = item:entindex(),
			PlayerID = caster:GetPlayerOwnerID(),
			Queue = false,
		})

		GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("xhs_tombstone_restart_check"), function()
			if IsValidEntityHandle(item) and item.xhs_channel_started ~= true then
				item.xhs_restart_in_progress = false
				XHSRearmTombstoneItem(item)
			end
			return nil
		end, 0.2)
		return nil
	end, 0)
end

function item_tombstone:OnSpellStart()
	if not IsServer() then return end

	local caster = self:GetCaster()
	local hero = GetReviveHero(self)
	if not IsValidEntityHandle(caster) or not IsValidEntityHandle(hero) then return end

	local position = self.xhs_tombstone_position or caster:GetAbsOrigin()
	local isRestart = self.xhs_restart_cast == true
	self.xhs_restart_cast = false
	self.xhs_restart_pending = false
	self.xhs_restart_in_progress = false
	self.xhs_channel_started = true
	self.xhs_channel_start_time = GameRules:GetGameTime()
	self.xhs_revive_position = Vector(position.x, position.y, position.z)

	local state = GetSharedState(hero, true)
	state.channels[self:entindex()] = self
	state.end_time = GameRules:GetGameTime() + self:GetChannelTime()
	PublishReviveChannelState(hero, state)

	DestroyChannelParticle(self, true)
	self.xhs_channel_particle = ParticleManager:CreateParticle(CHANNEL_PARTICLE, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(self.xhs_channel_particle, 0, self.xhs_revive_position)
	ParticleManager:SetParticleControl(self.xhs_channel_particle, 1, Vector(self:GetChannelTime(), 0, 0))
	ParticleManager:SetParticleControl(self.xhs_channel_particle, 3, self.xhs_revive_position)
	SendChannelStartNotification(self, not isRestart)

	if isRestart then return end

	-- Never hide, detach or remove the physical item drop from OnSpellStart.
	-- ItemCastOnPickup can still have a native ownership link to that drop while
	-- this callback runs; touching it here can crash the engine.
	RegisterClaimedTombstoneDrop(self, hero)
	local replacementPosition = Vector(self.xhs_revive_position.x, self.xhs_revive_position.y, self.xhs_revive_position.z)
	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("xhs_tombstone_replacement_drop"), function()
		if IsValidEntityHandle(hero) and not hero:IsAlive() and EnsureXHSTombstoneGroundDrop ~= nil then
			EnsureXHSTombstoneGroundDrop(hero, replacementPosition)
		end
		return nil
	end, 0.1)

	if self.xhs_accelerates_shared_channel == true then
		local sharedDuration = self:GetChannelTime()
		-- Restart every participant, including the newcomer. This makes the actual
		-- engine channel and every HUD progress bar adopt the same shortened time.
		GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("xhs_tombstone_accelerate"), function()
			for _, channelItem in pairs(state.channels) do
				RestartExistingChannel(channelItem, sharedDuration)
			end
			return nil
		end, 0)
	end
end

local function CleanupSuccessfulRevive(hero, winningItem)
	local state = GetSharedState(hero, false)
	if state ~= nil then
		state.completed = true
		for _, channelItem in pairs(state.channels or {}) do
			if IsValidEntityHandle(channelItem) then
				SendChannelFinishNotification(channelItem, true)
			end
			if channelItem ~= winningItem and IsValidEntityHandle(channelItem) then
				channelItem.xhs_finish_handled = true
				local caster = GetChannelCaster(channelItem)
				if IsValidEntityHandle(caster) and channelItem:IsChanneling() then
					caster:InterruptChannel()
				end
				RemoveChannelItem(channelItem)
			end
		end
		state.channels = {}
	end

	if XHSRemoveTombstoneGroundForHero ~= nil then
		XHSRemoveTombstoneGroundForHero(hero, true)
	end
	XHSClearTombstoneReviveState(hero)
	hero.xhs_tombstone_state = nil
end

function item_tombstone:OnChannelFinish(interrupted)
	if not IsServer() or self.xhs_finish_handled == true then return end

	if self.xhs_restart_pending == true then
		self.xhs_restart_pending = false
		self.xhs_channel_started = false
		DestroyChannelParticle(self, true)
		return
	end

	self.xhs_finish_handled = true
	self.xhs_channel_started = false
	DestroyChannelParticle(self, interrupted)
	if interrupted then
		SendChannelFinishNotification(self, false)
		XHSRearmTombstoneItem(self)
		return
	end

	local caster = GetChannelCaster(self)
	local hero = GetReviveHero(self)
	if not IsValidEntityHandle(caster) or not IsValidEntityHandle(hero) or hero:IsAlive() then
		SendChannelFinishNotification(self, false)
		XHSRearmTombstoneItem(self)
		return
	end

	local revivePosition = self.xhs_revive_position or self.xhs_tombstone_position or caster:GetAbsOrigin()
	hero:RespawnHero(false, false)
	if not hero:IsAlive() then
		SendChannelFinishNotification(self, false)
		XHSRearmTombstoneItem(self)
		return
	end

	FindClearSpaceForUnit(hero, revivePosition, true)
	hero:SetHealth(hero:GetMaxHealth())
	hero:SetMana(hero:GetMaxMana())
	hero:Stop()

	SupporterRecoveryEffects:PlayRebirth(hero, REVIVE_PARTICLE)
	caster:EmitSound(CHANNEL_COMPLETE_SOUND)

	local gameMode = GameRules.GameMode
	if gameMode ~= nil and gameMode.OnPlayerRevived ~= nil then
		gameMode:OnPlayerRevived({
			caster = caster:entindex(),
			target = hero:entindex(),
			channel_time = self:GetChannelTime(),
		})
	end

	CleanupSuccessfulRevive(hero, self)
	RemoveChannelItem(self)
end
