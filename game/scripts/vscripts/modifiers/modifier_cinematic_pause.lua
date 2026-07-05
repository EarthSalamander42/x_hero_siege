modifier_cinematic_pause = modifier_cinematic_pause or class({})
modifier_cinematic_pause.XHS_LINK_CLIENT = true
modifier_cinematic_pause_release = modifier_cinematic_pause_release or class({})
modifier_cinematic_pause_release.XHS_LINK_CLIENT = true

local CINEMATIC_PAUSE_LOG_PREFIX = "[modifier_cinematic_pause]"
local CINEMATIC_PAUSE_RELEASE_DURATION = 0.8
local CINEMATIC_PAUSE_INTERVAL = 0.03

local function CinematicPauseEntityID(entity)
	if entity == nil then return "nil" end
	if entity.entindex ~= nil then return tostring(entity:entindex()) end
	if entity.GetEntityIndex ~= nil then return tostring(entity:GetEntityIndex()) end
	return "unknown"
end

local function CinematicPauseUnitName(entity)
	if entity == nil then return "nil" end
	if entity.GetUnitName ~= nil then return entity:GetUnitName() end
	if entity.GetName ~= nil then return entity:GetName() end
	return "unknown"
end

local function CinematicPauseRealm()
	if IsServer ~= nil and IsServer() then return "server" end
	return "client"
end

function modifier_cinematic_pause:Log(message)
	local parent = self:GetParent()
	print(string.format(
		"%s realm=%s entid=%s unit=%s stack=%s progress=%s elapsed=%s :: %s",
		CINEMATIC_PAUSE_LOG_PREFIX,
		CinematicPauseRealm(),
		CinematicPauseEntityID(parent),
		CinematicPauseUnitName(parent),
		tostring(self:GetStackCount()),
		tostring(self.progress),
		tostring(self.elapsed),
		tostring(message)
	))
end

function modifier_cinematic_pause:LogOnce(key, message)
	self._cinematic_pause_logged = self._cinematic_pause_logged or {}
	if self._cinematic_pause_logged[key] then return end
	self._cinematic_pause_logged[key] = true
	self:Log(message)
end

function modifier_cinematic_pause:IsHidden() return true end
function modifier_cinematic_pause:IsPurgable() return false end
function modifier_cinematic_pause:IsPurgeException() return false end

function modifier_cinematic_pause:OnCreated(keys)
	keys = keys or {}
	self.ramp_duration = math.max(tonumber(keys.ramp_duration) or 1.0, 0.1)
	self.elapsed = 0
	self.progress = self:GetStackCount() / 100
	self._cinematic_pause_logged = {}
	self._cinematic_pause_last_bucket = -1

	self:Log(string.format(
		"OnCreated duration=%s ramp_duration=%s raw_ramp=%s caster_ent=%s ability=%s",
		tostring(keys.duration),
		tostring(self.ramp_duration),
		tostring(keys.ramp_duration),
		CinematicPauseEntityID(self:GetCaster()),
		tostring(self:GetAbility() and self:GetAbility():GetAbilityName() or "nil")
	))

	if IsServer() then
		local parent = self:GetParent()
		if parent ~= nil and not parent:IsNull() then
			parent:RemoveModifierByName("modifier_cinematic_pause_release")
		end

		self:SetStackCount(0)
		self:StartIntervalThink(CINEMATIC_PAUSE_INTERVAL)
		self:Log("StartIntervalThink interval=" .. tostring(CINEMATIC_PAUSE_INTERVAL))
	else
		self:Log("OnCreated client side, interval not started")
	end
end

function modifier_cinematic_pause:OnRefresh(keys)
	self:Log(string.format("OnRefresh raw_duration=%s raw_ramp=%s", tostring(keys and keys.duration), tostring(keys and keys.ramp_duration)))
	if not IsServer() then return end

	keys = keys or {}
	if keys.ramp_duration ~= nil then
		self.ramp_duration = math.max(tonumber(keys.ramp_duration) or self.ramp_duration or 1.0, 0.1)
	end
end

function modifier_cinematic_pause:OnIntervalThink()
	self.elapsed = self.elapsed + CINEMATIC_PAUSE_INTERVAL
	self.progress = math.min(self.elapsed / self.ramp_duration, 1)
	self:SetStackCount(math.floor(self.progress * 100))

	local bucket = math.floor(self.progress * 4)
	if bucket ~= self._cinematic_pause_last_bucket then
		self._cinematic_pause_last_bucket = bucket
		self:Log(string.format("OnIntervalThink ramp_bucket=%s progress=%.2f stack=%s", tostring(bucket), self.progress, tostring(self:GetStackCount())))
	end

	if self.progress >= 1 then
		self:Log("Ramp complete, stopping interval and enabling full pause states")
		self:StartIntervalThink(-1)
	end
end

function modifier_cinematic_pause:DeclareFunctions()
	self:LogOnce("DeclareFunctions", "DeclareFunctions called")
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE_MIN,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE,
		MODIFIER_PROPERTY_DISABLE_HEALING,
	}
end

function modifier_cinematic_pause:GetModifierMoveSpeedBonus_Percentage()
	self:LogOnce("MoveSpeed", "GetModifierMoveSpeedBonus_Percentage first call")
	return -100 * self:GetSlowProgress()
end

function modifier_cinematic_pause:GetModifierMoveSpeed_AbsoluteMin()
	return 0
end

function modifier_cinematic_pause:GetModifierAttackSpeedBonus_Constant()
	self:LogOnce("AttackSpeed", "GetModifierAttackSpeedBonus_Constant first call")
	return -700 * self:GetSlowProgress()
end

function modifier_cinematic_pause:GetModifierTurnRate_Percentage()
	self:LogOnce("TurnRate", "GetModifierTurnRate_Percentage first call")
	return -100 * self:GetSlowProgress()
end

function modifier_cinematic_pause:GetDisableHealing()
	self:LogOnce("DisableHealing", "GetDisableHealing first call")
	return 1
end

function modifier_cinematic_pause:GetSlowProgress()
	local stackProgress = math.min(self:GetStackCount() / 100, 1)
	return stackProgress
end

function modifier_cinematic_pause:CheckState()
	self:LogOnce("CheckState", "CheckState first call")
	local state = {
		[MODIFIER_STATE_INVULNERABLE] = true,
	}

	if self:GetSlowProgress() >= 1 then
		self:LogOnce("CheckStateFullPause", "CheckState applying stunned/command_restricted/frozen")
		state[MODIFIER_STATE_DISARMED] = true
		state[MODIFIER_STATE_SILENCED] = true
		state[MODIFIER_STATE_MUTED] = true
		state[MODIFIER_STATE_STUNNED] = true
		state[MODIFIER_STATE_COMMAND_RESTRICTED] = true
		state[MODIFIER_STATE_FROZEN] = true
	end

	return state
end

function modifier_cinematic_pause:OnRemoved()
	self:Log("OnRemoved")
end

function modifier_cinematic_pause:OnDestroy()
	self:Log("OnDestroy")

	if not IsServer() then return end

	local parent = self:GetParent()
	if parent == nil or parent:IsNull() then return end
	if self:GetStackCount() <= 0 then return end
	if parent:HasModifier("modifier_cinematic_pause_release") then return end

	parent:AddNewModifier(parent, nil, "modifier_cinematic_pause_release", {
		duration = CINEMATIC_PAUSE_RELEASE_DURATION,
		release_duration = CINEMATIC_PAUSE_RELEASE_DURATION,
		start_stack = self:GetStackCount(),
	})
end

function modifier_cinematic_pause_release:IsHidden() return true end
function modifier_cinematic_pause_release:IsPurgable() return false end
function modifier_cinematic_pause_release:IsPurgeException() return false end

function modifier_cinematic_pause_release:OnCreated(keys)
	keys = keys or {}
	self.release_duration = math.max(tonumber(keys.release_duration) or CINEMATIC_PAUSE_RELEASE_DURATION, 0.03)
	self.elapsed = 0
	self.start_stack = math.max(tonumber(keys.start_stack) or 100, 0)

	if IsServer() then
		self:SetStackCount(self.start_stack)
		self:StartIntervalThink(CINEMATIC_PAUSE_INTERVAL)
	end
end

function modifier_cinematic_pause_release:OnIntervalThink()
	self.elapsed = self.elapsed + CINEMATIC_PAUSE_INTERVAL

	local progress = math.min(self.elapsed / self.release_duration, 1)
	self:SetStackCount(math.max(math.ceil(self.start_stack * (1 - progress)), 0))

	if progress >= 1 then
		self:Destroy()
	end
end

function modifier_cinematic_pause_release:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE_MIN,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE,
	}
end

function modifier_cinematic_pause_release:GetSlowProgress()
	return math.min(self:GetStackCount() / 100, 1)
end

function modifier_cinematic_pause_release:GetModifierMoveSpeedBonus_Percentage()
	return -100 * self:GetSlowProgress()
end

function modifier_cinematic_pause_release:GetModifierMoveSpeed_AbsoluteMin()
	return 0
end

function modifier_cinematic_pause_release:GetModifierAttackSpeedBonus_Constant()
	return -700 * self:GetSlowProgress()
end

function modifier_cinematic_pause_release:GetModifierTurnRate_Percentage()
	return -100 * self:GetSlowProgress()
end
