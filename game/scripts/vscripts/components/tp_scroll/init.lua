if XHSTPScroll == nil then
	XHSTPScroll = class({})
end

LinkLuaModifier(
	"modifier_xhs_tp_scroll_channel",
	"components/tp_scroll/init.lua",
	LUA_MODIFIER_MOTION_NONE
)

local DEFAULT_MINIMUM_DISTANCE = 70
local DEFAULT_MAXIMUM_DISTANCE = 375
local DEFAULT_VISION_RADIUS = 300
local DEFAULT_CHANNEL_TIME = 3.0
local TELEPORT_START_PARTICLE = "particles/items2_fx/teleport_start.vpcf"
local TELEPORT_END_PARTICLE = "particles/items2_fx/teleport_end.vpcf"
local TELEPORT_LOOP_SOUND = "Portal.Loop_Appear"
local CHANNEL_MODIFIER = "modifier_xhs_tp_scroll_channel"
local UPDATE_INTERVAL = 0.03
local DEBUG_LOGS = true

XHSTPScroll.channels = XHSTPScroll.channels or {}
XHSTPScroll.next_cast_id = XHSTPScroll.next_cast_id or 0

local function DebugLog(castID, formatString, ...)
	if not DEBUG_LOGS then return end
	local ok, message = pcall(string.format, formatString, ...)
	if not ok then message = formatString .. " [format_error=" .. tostring(message) .. "]" end
	local gameTime = GameRules ~= nil and GameRules.GetGameTime ~= nil and GameRules:GetGameTime() or -1
	print(string.format(
		"[XHS][TPScroll][cast=%s][t=%.3f] %s",
		tostring(castID or "none"),
		tonumber(gameTime) or -1,
		tostring(message)
	))
end

local function VectorToString(position)
	if position == nil then return "nil" end
	return string.format("(%.1f, %.1f, %.1f)", position.x or 0, position.y or 0, position.z or 0)
end

local function EntityIndexToString(entity)
	if entity == nil or entity.entindex == nil then return "nil" end
	local ok, index = pcall(entity.entindex, entity)
	return ok and tostring(index) or "invalid"
end

DebugLog("boot", "FEATURE loaded debug_logs=%s", tostring(DEBUG_LOGS))

local function IsValidEntityHandle(entity)
	return entity ~= nil and IsValidEntity(entity) and not entity:IsNull()
end

local function GetAbilityName(ability)
	if not IsValidEntityHandle(ability) then return "" end
	if ability.GetAbilityName ~= nil then return ability:GetAbilityName() or "" end
	if ability.GetName ~= nil then return ability:GetName() or "" end
	return ""
end

local function GetSpecialValue(ability, name, fallback)
	if not IsValidEntityHandle(ability) or ability.GetSpecialValueFor == nil then return fallback end
	local value = tonumber(ability:GetSpecialValueFor(name))
	if value == nil or value <= 0 then return fallback end
	return value
end

local function IsLivingFriendlyBuilding(caster, entity)
	if not IsValidEntityHandle(caster) or not IsValidEntityHandle(entity) then return false end
	if entity.GetTeamNumber == nil or entity:GetTeamNumber() ~= caster:GetTeamNumber() then return false end
	if entity.IsBuilding == nil or not entity:IsBuilding() then return false end
	return entity.IsAlive == nil or entity:IsAlive()
end

local function IsTeamAnchor(caster, entity)
	return IsValidEntityHandle(caster)
		and IsValidEntityHandle(entity)
		and (entity.GetTeamNumber == nil or entity:GetTeamNumber() == caster:GetTeamNumber())
end

local function GetBaseAnchor(caster)
	if not IsValidEntityHandle(caster) then return nil end

	local candidate = BASE_GOOD
	if IsTeamAnchor(caster, candidate) then return candidate end

	candidate = Entities:FindByName(nil, "dota_goodguys_fort")
	if IsTeamAnchor(caster, candidate) then return candidate end

	candidate = Entities:FindByName(nil, "base_spawn")
	if IsTeamAnchor(caster, candidate) then return candidate end

	for _, fountain in pairs(Entities:FindAllByClassname("ent_dota_fountain") or {}) do
		if IsTeamAnchor(caster, fountain) then return fountain end
	end

	return nil
end

local function FindTeleportAnchor(caster, ability, position)
	if not IsValidEntityHandle(caster) or position == nil then return nil end

	local maximumDistance = GetSpecialValue(ability, "maximum_distance", DEFAULT_MAXIMUM_DISTANCE)
	local buildings = FindUnitsInRadius(
		caster:GetTeamNumber(),
		position,
		nil,
		maximumDistance,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_BUILDING,
		DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
		FIND_CLOSEST,
		false
	)

	for _, building in ipairs(buildings or {}) do
		if IsLivingFriendlyBuilding(caster, building) then return building end
	end

	local function IsNearbyNamedAnchor(anchor)
		return IsTeamAnchor(caster, anchor)
			and (anchor:GetAbsOrigin() - position):Length2D() <= maximumDistance
	end

	local anchor = Entities:FindByName(nil, "dota_goodguys_fort")
	if IsNearbyNamedAnchor(anchor) then return anchor end

	anchor = BASE_GOOD
	if IsNearbyNamedAnchor(anchor) then return anchor end

	anchor = Entities:FindByName(nil, "base_spawn")
	if IsNearbyNamedAnchor(anchor) then return anchor end

	return nil
end

local function BuildDestination(caster, ability, anchor, requestedPosition)
	if not IsValidEntityHandle(caster) or not IsValidEntityHandle(anchor) then return nil end

	local anchorPosition = anchor:GetAbsOrigin()
	local direction = (requestedPosition or anchorPosition) - anchorPosition
	direction.z = 0

	local minimumDistance = GetSpecialValue(ability, "minimun_distance", DEFAULT_MINIMUM_DISTANCE)
	if direction:Length2D() < minimumDistance then
		direction = caster:GetAbsOrigin() - anchorPosition
		direction.z = 0
		if direction:Length2D() < 0.01 then
			direction = anchor.GetForwardVector ~= nil and anchor:GetForwardVector() or Vector(1, 0, 0)
			direction.z = 0
		end
		direction = direction:Normalized() * minimumDistance
	end

	return GetGroundPosition(anchorPosition + direction, caster)
end

local function GetOrderPosition(filterTable)
	local x = tonumber(filterTable.position_x)
	local y = tonumber(filterTable.position_y)
	local z = tonumber(filterTable.position_z)
	if x == nil or y == nil then return nil end
	return Vector(x, y, z or 0)
end

local function ResolveOrderDestination(filterTable, caster, ability, orderType)
	if orderType == DOTA_UNIT_ORDER_CAST_TARGET then
		local targetIndex = tonumber(filterTable.entindex_target)
		local target = targetIndex ~= nil and targetIndex > 0 and EntIndexToHScript(targetIndex) or nil
		if not IsLivingFriendlyBuilding(caster, target) then return nil end
		return BuildDestination(caster, ability, target, target:GetAbsOrigin())
	end

	if orderType == DOTA_UNIT_ORDER_CAST_NO_TARGET then
		local base = GetBaseAnchor(caster)
		return BuildDestination(caster, ability, base, base and base:GetAbsOrigin() or nil)
	end

	if orderType == DOTA_UNIT_ORDER_CAST_POSITION then
		local position = GetOrderPosition(filterTable)
		local anchor = FindTeleportAnchor(caster, ability, position)
		return BuildDestination(caster, ability, anchor, position)
	end

	return nil
end

local function IsTeleportCastOrder(orderType)
	return orderType == DOTA_UNIT_ORDER_CAST_POSITION
		or orderType == DOTA_UNIT_ORDER_CAST_TARGET
		or orderType == DOTA_UNIT_ORDER_CAST_NO_TARGET
end

local function IsNonInterruptingOrder(orderType)
	return orderType == DOTA_UNIT_ORDER_PURCHASE_ITEM
		or orderType == DOTA_UNIT_ORDER_SELL_ITEM
		or orderType == DOTA_UNIT_ORDER_RADAR
		or orderType == DOTA_UNIT_ORDER_GLYPH
		or orderType == DOTA_UNIT_ORDER_TRAIN_ABILITY
		or (DOTA_UNIT_ORDER_MOVE_ITEM ~= nil and orderType == DOTA_UNIT_ORDER_MOVE_ITEM)
		or (DOTA_UNIT_ORDER_DISASSEMBLE_ITEM ~= nil and orderType == DOTA_UNIT_ORDER_DISASSEMBLE_ITEM)
		or (DOTA_UNIT_ORDER_SET_ITEM_COMBINE_LOCK ~= nil and orderType == DOTA_UNIT_ORDER_SET_ITEM_COMBINE_LOCK)
		or (DOTA_UNIT_ORDER_TAKE_ITEM_FROM_STASH ~= nil and orderType == DOTA_UNIT_ORDER_TAKE_ITEM_FROM_STASH)
		or (DOTA_UNIT_ORDER_EJECT_ITEM_FROM_STASH ~= nil and orderType == DOTA_UNIT_ORDER_EJECT_ITEM_FROM_STASH)
end

local function DestroyParticle(state, field, immediate)
	local particle = state[field]
	if particle == nil then return end
	ParticleManager:DestroyParticle(particle, immediate == true)
	ParticleManager:ReleaseParticleIndex(particle)
	state[field] = nil
end

local function SendCastError(caster, message)
	if IsValidEntityHandle(caster) and caster.GetPlayerID ~= nil then
		local playerID = caster:GetPlayerID()
		if playerID ~= nil and playerID >= 0 then SendErrorMessage(playerID, message) end
	end
end

local function LogSupporterState(caster, castID, stage)
	local playerID = IsValidEntityHandle(caster) and caster.GetPlayerID ~= nil and caster:GetPlayerID() or -1
	local rewardsEnabled = "unavailable"
	local equipped = nil
	if Battlepass ~= nil then
		if Battlepass.AreSupporterRewardsEnabled ~= nil then
			local ok, value = pcall(Battlepass.AreSupporterRewardsEnabled, Battlepass, playerID)
			if ok then rewardsEnabled = tostring(value) else rewardsEnabled = "error:" .. tostring(value) end
		end
		if Battlepass.GetEquippedSupporterItem ~= nil then
			local ok, value = pcall(Battlepass.GetEquippedSupporterItem, Battlepass, playerID, "teleport")
			if ok then equipped = value end
		end
	end

	local cache = Battlepass ~= nil
		and type(Battlepass.Player) == "table"
		and Battlepass.Player[playerID]
		or nil
	DebugLog(
		castID,
		"SUPPORTER stage=%s player=%s helper=%s rewards=%s equipped_id=%s equipped_name=%s equipped_slot=%s equipped_start=%s equipped_end=%s cache_ready=%s cache_start=%s cache_end=%s",
		tostring(stage),
		tostring(playerID),
		tostring(XHSGetBattlepassParticle ~= nil),
		tostring(rewardsEnabled),
		tostring(type(equipped) == "table" and (equipped.item_id or equipped.id or equipped.item_def) or nil),
		tostring(type(equipped) == "table" and (equipped.item_name or equipped.name) or nil),
		tostring(type(equipped) == "table" and (equipped.slot_id or equipped.item_type or equipped.type) or nil),
		tostring(type(equipped) == "table" and equipped.start_pfx or nil),
		tostring(type(equipped) == "table" and equipped.end_pfx or nil),
		tostring(type(cache) == "table" and cache.ready or nil),
		tostring(type(cache) == "table" and cache.teleport_start_pfx or nil),
		tostring(type(cache) == "table" and cache.teleport_end_pfx or nil)
	)
end

function XHSTPScroll:Cleanup(state, interrupted, reason)
	if state == nil or state.cleaning == true then return end
	DebugLog(
		state.cast_id,
		"CLEANUP interrupted=%s reason=%s caster=%s start_index=%s end_index=%s",
		tostring(interrupted == true),
		tostring(reason or "unspecified"),
		EntityIndexToString(state.caster),
		tostring(state.start_particle),
		tostring(state.end_particle)
	)
	state.cleaning = true
	self.channels[state.caster_entindex] = nil

	local caster = state.caster
	local ability = state.ability
	if IsValidEntityHandle(ability) and ability.SetChanneling ~= nil then
		ability:SetChanneling(false)
	end
	if IsValidEntityHandle(caster) then
		caster:StopSound(TELEPORT_LOOP_SOUND)
		if EndAnimation ~= nil then EndAnimation(caster) end
		local modifier = caster:FindModifierByName(CHANNEL_MODIFIER)
		if modifier ~= nil and (modifier.IsNull == nil or not modifier:IsNull()) then
			modifier:Destroy()
		end
	end

	DestroyParticle(state, "start_particle", interrupted)
	DestroyParticle(state, "end_particle", interrupted)
end

function XHSTPScroll:Cancel(caster, reason)
	if not IsValidEntityHandle(caster) then return false end
	local state = self.channels[caster:entindex()]
	if state == nil then return false end
	self:Cleanup(state, true, reason or "cancelled")
	return true
end

function XHSTPScroll:Complete(caster)
	if not IsValidEntityHandle(caster) then return end
	local state = self.channels[caster:entindex()]
	if state == nil then return end

	local destination = state.destination
	DebugLog(state.cast_id, "COMPLETE destination=%s", VectorToString(destination))
	self:Cleanup(state, false, "completed")
	if not caster:IsAlive() then return end

	if TeleportHero ~= nil then
		DebugLog(state.cast_id, "TELEPORT helper=TeleportHero delay=0 camera=0")
		TeleportHero(caster, destination, 0, 0)
	else
		DebugLog(state.cast_id, "TELEPORT helper=FindClearSpaceForUnit fallback=true")
		FindClearSpaceForUnit(caster, destination, true)
		caster:Stop()
	end
end

function XHSTPScroll:Update(caster)
	if not IsValidEntityHandle(caster) then return end
	local state = self.channels[caster:entindex()]
	if state == nil then return end

	local interrupted = not caster:IsAlive()
		or (caster.IsStunned ~= nil and caster:IsStunned())
		or (caster.IsHexed ~= nil and caster:IsHexed())
		or (caster.IsNightmared ~= nil and caster:IsNightmared())
		or (caster.IsOutOfGame ~= nil and caster:IsOutOfGame())
		or (caster.IsMuted ~= nil and caster:IsMuted())
		or (caster.IsCommandRestricted ~= nil and caster:IsCommandRestricted())
	if interrupted then
		local reason = not caster:IsAlive() and "death"
			or (caster.IsStunned ~= nil and caster:IsStunned()) and "stunned"
			or (caster.IsHexed ~= nil and caster:IsHexed()) and "hexed"
			or (caster.IsNightmared ~= nil and caster:IsNightmared()) and "nightmared"
			or (caster.IsOutOfGame ~= nil and caster:IsOutOfGame()) and "out_of_game"
			or (caster.IsMuted ~= nil and caster:IsMuted()) and "muted"
			or (caster.IsCommandRestricted ~= nil and caster:IsCommandRestricted()) and "command_restricted"
			or "state_change"
		self:Cancel(caster, reason)
		return
	end

	if GameRules:GetGameTime() >= state.end_time then self:Complete(caster) end
end

function XHSTPScroll:Begin(caster, ability, destination, castID)
	if not IsValidEntityHandle(caster)
		or not caster:IsAlive()
		or not IsValidEntityHandle(ability)
		or destination == nil
	then
		DebugLog(castID, "BEGIN rejected reason=invalid_arguments")
		return false
	end
	if self.channels[caster:entindex()] ~= nil then
		DebugLog(castID, "BEGIN rejected reason=already_channeling")
		return false
	end
	if ability.IsFullyCastable ~= nil and not ability:IsFullyCastable() then
		DebugLog(
			castID,
			"BEGIN rejected reason=not_fully_castable cooldown_remaining=%.3f mana=%.1f",
			ability.GetCooldownTimeRemaining ~= nil and ability:GetCooldownTimeRemaining() or -1,
			caster.GetMana ~= nil and caster:GetMana() or -1
		)
		return false
	end

	local abilityLevel = math.max(0, (ability.GetLevel ~= nil and ability:GetLevel() or 1) - 1)
	local manaCost = ability.GetManaCost ~= nil and math.max(0, ability:GetManaCost(abilityLevel)) or 0
	local cooldown = ability.GetCooldown ~= nil and math.max(0, ability:GetCooldown(abilityLevel)) or 0
	-- item_tpscroll keeps its native targeting implementation, so on dedicated
	-- servers GetChannelTime() may report zero even though our KV override and
	-- tooltip specify a three-second channel. Zero must mean "use the XHS
	-- fallback", not an almost-instant 0.01-second teleport.
	local nativeChannelTime = ability.GetChannelTime ~= nil
		and tonumber(ability:GetChannelTime()) or nil
	local channelTime = nativeChannelTime ~= nil and nativeChannelTime > 0.1
		and nativeChannelTime
		or GetSpecialValue(ability, "tooltip_channel_time", DEFAULT_CHANNEL_TIME)
	channelTime = math.max(0.1, tonumber(channelTime) or DEFAULT_CHANNEL_TIME)

	DebugLog(
		castID,
		"BEGIN caster=%s player=%s ability=%s ability_index=%s destination=%s mana_cost=%.1f cooldown=%.3f channel=%.3f",
		EntityIndexToString(caster),
		tostring(caster.GetPlayerID ~= nil and caster:GetPlayerID() or -1),
		GetAbilityName(ability),
		EntityIndexToString(ability),
		VectorToString(destination),
		manaCost,
		cooldown,
		channelTime
	)

	-- The intercepted native order never stops the hero by itself.
	caster:Stop()
	if manaCost > 0 then caster:SpendMana(manaCost, ability) end
	ability:StartCooldown(cooldown)
	if ability.SetChanneling ~= nil then ability:SetChanneling(true) end

	local state = {
		cast_id = castID,
		caster = caster,
		caster_entindex = caster:entindex(),
		ability = ability,
		destination = Vector(destination.x, destination.y, destination.z),
		end_time = GameRules:GetGameTime() + channelTime,
	}
	self.channels[state.caster_entindex] = state

	LogSupporterState(caster, castID, "before_resolve")
	local startParticle = XHSGetBattlepassParticle ~= nil
		and XHSGetBattlepassParticle(caster, "teleport_start_pfx", TELEPORT_START_PARTICLE)
		or TELEPORT_START_PARTICLE
	local endParticle = XHSGetBattlepassParticle ~= nil
		and XHSGetBattlepassParticle(caster, "teleport_end_pfx", TELEPORT_END_PARTICLE)
		or TELEPORT_END_PARTICLE
	LogSupporterState(caster, castID, "after_resolve")
	DebugLog(castID, "PFX resolved start=%s start_fallback=%s end=%s end_fallback=%s",
		tostring(startParticle), tostring(startParticle == TELEPORT_START_PARTICLE),
		tostring(endParticle), tostring(endParticle == TELEPORT_END_PARTICLE))

	state.start_particle = ParticleManager:CreateParticle(startParticle, PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControlEnt(
		state.start_particle,
		0,
		caster,
		PATTACH_ABSORIGIN,
		"attach_origin",
		caster:GetAbsOrigin(),
		true
	)
	ParticleManager:SetParticleControl(state.start_particle, 7, Vector(channelTime, 0, 0))
	state.end_particle = ParticleManager:CreateParticle(endParticle, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(state.end_particle, 0, state.destination)
	ParticleManager:SetParticleControl(state.end_particle, 1, state.destination)
	DebugLog(
		castID,
		"PFX created start_index=%s end_index=%s",
		tostring(state.start_particle),
		tostring(state.end_particle)
	)

	AddFOWViewer(
		caster:GetTeamNumber(),
		state.destination,
		GetSpecialValue(ability, "vision_radius", DEFAULT_VISION_RADIUS),
		channelTime,
		false
	)
	if StartAnimation ~= nil then
		StartAnimation(caster, {
			duration = channelTime,
			activity = ACT_DOTA_TELEPORT,
			rate = 1.0,
		})
	end
	caster:EmitSound(TELEPORT_LOOP_SOUND)

	local modifier = caster:AddNewModifier(caster, ability, CHANNEL_MODIFIER, {
		duration = channelTime + 0.25,
	})
	if modifier == nil then
		DebugLog(castID, "BEGIN failed reason=channel_modifier_missing")
		self:Cancel(caster, "channel_modifier_missing")
		return false
	end

	DebugLog(
		castID,
		"CHANNEL active ability_channeling=%s caster_channeling=%s modifier=%s",
		tostring(ability.IsChanneling ~= nil and ability:IsChanneling() or "unavailable"),
		tostring(caster.IsChanneling ~= nil and caster:IsChanneling() or "unavailable"),
		tostring(modifier ~= nil)
	)
	return true
end

function XHSTPScroll:HandleSecretArenaOrder(caster, position, castID)
	if _G.SECRET == 1 or position == nil then return false end
	if not IsNearEntity("npc_dota_muradin_boss", position, 1200) then return false end
	DebugLog(castID, "SECRET_ARENA intercepted position=%s", VectorToString(position))

	if GameRules:GetCustomGameDifficulty() >= 4 or IsInToolsMode() then
		for itemSlot = 0, 5 do
			local item = caster:GetItemInSlot(itemSlot)
			if IsValidEntityHandle(item) and GetAbilityName(item) == "item_key_of_the_three_moons" then
				if not GameRules:IsCheatMode() or IsInToolsMode() then
					if not IsInToolsMode() then _G.SECRET = 1 end
					StartSecretArena(caster)
				end
				break
			end
		end
	end

	SendCastError(caster, "I'm sorry, i can't let you in.")
	return true
end

function XHSTPScroll:FilterOrder(filterTable, caster)
	if not IsValidEntityHandle(caster) then return nil end

	local orderType = tonumber(filterTable.order_type)
	local abilityIndex = tonumber(filterTable.entindex_ability)
	local ability = abilityIndex ~= nil and abilityIndex > 0 and EntIndexToHScript(abilityIndex) or nil
	local isTPAbility = GetAbilityName(ability) == "item_tpscroll"
	local isTPCast = isTPAbility and IsTeleportCastOrder(orderType)
	local state = self.channels[caster:entindex()]

	if isTPAbility then
		self.next_cast_id = self.next_cast_id + 1
	end
	local castID = isTPAbility and self.next_cast_id or (state ~= nil and state.cast_id or nil)

	if state ~= nil
		and not isTPCast
		and filterTable.queue ~= 1
		and not IsNonInterruptingOrder(orderType)
	then
		DebugLog(
			state.cast_id,
			"INTERRUPT_BY_ORDER order=%s ability=%s ability_index=%s queue=%s",
			tostring(orderType),
			GetAbilityName(ability),
			EntityIndexToString(ability),
			tostring(filterTable.queue)
		)
		self:Cancel(caster, "order:" .. tostring(orderType))
	end

	if not isTPCast then
		if isTPAbility then
			DebugLog(
				castID,
				"ORDER unsupported order=%s ability_index=%s target_index=%s position=%s queue=%s native_execution_will_pass=true",
				tostring(orderType),
				EntityIndexToString(ability),
				tostring(filterTable.entindex_target),
				VectorToString(GetOrderPosition(filterTable)),
				tostring(filterTable.queue)
			)
		end
		return nil
	end

	local position = orderType == DOTA_UNIT_ORDER_CAST_POSITION and GetOrderPosition(filterTable) or nil
	DebugLog(
		castID,
		"ORDER intercepted order=%s caster=%s player=%s ability_index=%s target_index=%s position=%s queue=%s active_cast=%s",
		tostring(orderType),
		EntityIndexToString(caster),
		tostring(caster.GetPlayerID ~= nil and caster:GetPlayerID() or -1),
		EntityIndexToString(ability),
		tostring(filterTable.entindex_target),
		VectorToString(position),
		tostring(filterTable.queue),
		tostring(state ~= nil and state.cast_id or nil)
	)

	-- Never let this order reach Valve's item implementation: that is what keeps
	-- the dedicated slot/bind while replacing only the actual teleport call.
	if state ~= nil then
		if filterTable.queue ~= 1 then self:Cancel(caster, "recast") end
		DebugLog(castID, "ORDER blocked native_server_execution=true reason=already_channeling")
		return false
	end

	if self:HandleSecretArenaOrder(caster, position, castID) then
		DebugLog(castID, "ORDER blocked native_server_execution=true reason=secret_arena")
		return false
	end

	local destination = ResolveOrderDestination(filterTable, caster, ability, orderType)
	if destination == nil then
		DebugLog(castID, "ORDER blocked native_server_execution=true reason=no_valid_destination")
		SendCastError(caster, "#dota_hud_error_no_valid_target")
		return false
	end

	DebugLog(castID, "ORDER destination_resolved=%s", VectorToString(destination))
	local started = self:Begin(caster, ability, destination, castID)
	DebugLog(castID, "ORDER return=false native_server_execution=blocked feature_started=%s", tostring(started))
	return false
end

function XHSTPScroll:OnChannelModifierDestroyed(caster)
	if not IsValidEntityHandle(caster) then return end
	local state = self.channels[caster:entindex()]
	if state ~= nil and state.cleaning ~= true then
		DebugLog(state.cast_id, "CHANNEL modifier_destroyed unexpected=true")
		self:Cancel(caster, "modifier_destroyed")
	end
end

modifier_xhs_tp_scroll_channel = class({})

function modifier_xhs_tp_scroll_channel:IsHidden() return true end
function modifier_xhs_tp_scroll_channel:IsPurgable() return false end
function modifier_xhs_tp_scroll_channel:RemoveOnDeath() return true end

function modifier_xhs_tp_scroll_channel:OnCreated()
	if not IsServer() then return end
	self:StartIntervalThink(UPDATE_INTERVAL)
end

function modifier_xhs_tp_scroll_channel:OnIntervalThink()
	if XHSTPScroll ~= nil then XHSTPScroll:Update(self:GetParent()) end
end

function modifier_xhs_tp_scroll_channel:OnDestroy()
	if not IsServer() then return end
	if XHSTPScroll ~= nil then XHSTPScroll:OnChannelModifierDestroyed(self:GetParent()) end
end

function modifier_xhs_tp_scroll_channel:CheckState()
	return {
		[MODIFIER_STATE_ROOTED] = true,
		[MODIFIER_STATE_DISARMED] = true,
	}
end

return XHSTPScroll
