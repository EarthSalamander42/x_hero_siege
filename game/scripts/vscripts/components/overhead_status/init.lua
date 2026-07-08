XHSOverheadStatus = XHSOverheadStatus or {}
XHSOverheadStatus.NET_TABLE = "player_table"
XHSOverheadStatus.REFRESH_SECONDS = 0.1
XHSOverheadStatus.cache = XHSOverheadStatus.cache or {}

XHSOverheadStatus.PRIORITY = {
	{
		key = "stunned",
		label = "STUNNED",
		class_name = "XHSStatusStunned",
		methods = { "IsStunned", "IsCommandRestricted" },
		states = { "MODIFIER_STATE_STUNNED", "MODIFIER_STATE_COMMAND_RESTRICTED" },
	},
	{
		key = "hexed",
		label = "HEXED",
		class_name = "XHSStatusHexed",
		methods = { "IsHexed" },
		states = { "MODIFIER_STATE_HEXED" },
	},
	{
		key = "sleep",
		label = "SLEEP",
		class_name = "XHSStatusSleep",
		methods = { "IsNightmared" },
		states = { "MODIFIER_STATE_NIGHTMARED" },
	},
	{
		key = "feared",
		label = "FEARED",
		class_name = "XHSStatusFeared",
		states = { "MODIFIER_STATE_FEARED" },
	},
	{
		key = "taunted",
		label = "TAUNTED",
		class_name = "XHSStatusTaunted",
		states = { "MODIFIER_STATE_TAUNTED" },
	},
	{
		key = "cycloned",
		label = "CYCLONED",
		class_name = "XHSStatusCycloned",
		methods = { "IsOutOfGame" },
		states = { "MODIFIER_STATE_OUT_OF_GAME" },
	},
	{
		key = "rooted",
		label = "ROOTED",
		class_name = "XHSStatusRooted",
		methods = { "IsRooted" },
		states = { "MODIFIER_STATE_ROOTED" },
	},
	{
		key = "leashed",
		label = "LEASHED",
		class_name = "XHSStatusLeashed",
		states = { "MODIFIER_STATE_LEASHED", "MODIFIER_STATE_TETHERED" },
	},
	{
		key = "silenced",
		label = "SILENCED",
		class_name = "XHSStatusSilenced",
		methods = { "IsSilenced" },
		states = { "MODIFIER_STATE_SILENCED" },
	},
	{
		key = "muted",
		label = "MUTED",
		class_name = "XHSStatusMuted",
		methods = { "IsMuted" },
		states = { "MODIFIER_STATE_MUTED" },
	},
	{
		key = "disarmed",
		label = "DISARMED",
		class_name = "XHSStatusDisarmed",
		methods = { "IsDisarmed" },
		states = { "MODIFIER_STATE_DISARMED" },
	},
	{
		key = "broken",
		label = "BROKEN",
		class_name = "XHSStatusBroken",
		methods = { "PassivesDisabled" },
		states = { "MODIFIER_STATE_PASSIVES_DISABLED" },
	},
	{
		key = "invulnerable",
		label = "INVULNERABLE",
		class_name = "XHSStatusInvulnerable",
		methods = { "IsInvulnerable" },
		states = { "MODIFIER_STATE_INVULNERABLE" },
	},
}

function XHSOverheadStatus:SafeHeroMethod(hero, methodName)
	if hero == nil or hero:IsNull() or methodName == nil or hero[methodName] == nil then return false end

	local ok, value = pcall(function()
		return hero[methodName](hero)
	end)

	return ok and value == true
end

function XHSOverheadStatus:ModifierHasState(modifier, stateName)
	if modifier == nil or stateName == nil or _G[stateName] == nil or modifier.CheckState == nil then return false end

	local ok, states = pcall(function()
		return modifier:CheckState()
	end)

	return ok and states ~= nil and states[_G[stateName]] == true
end

function XHSOverheadStatus:GetModifierRemainingTime(modifier)
	if modifier == nil or modifier.GetRemainingTime == nil then return 0 end

	local ok, remaining = pcall(function()
		return modifier:GetRemainingTime()
	end)

	if not ok or remaining == nil or remaining < 0 then return 0 end
	return remaining
end

function XHSOverheadStatus:GetStatusRemainingTime(hero, status)
	if hero == nil or hero:IsNull() or status == nil or hero.FindAllModifiers == nil then return 0 end

	local longest = 0
	for _, modifier in pairs(hero:FindAllModifiers()) do
		if modifier ~= nil then
			for _, stateName in pairs(status.states or {}) do
				if self:ModifierHasState(modifier, stateName) then
					longest = math.max(longest, self:GetModifierRemainingTime(modifier))
				end
			end
		end
	end

	return longest
end

function XHSOverheadStatus:HeroMatchesStatus(hero, status)
	if hero == nil or hero:IsNull() or status == nil then return false end

	for _, methodName in pairs(status.methods or {}) do
		if self:SafeHeroMethod(hero, methodName) then
			return true
		end
	end

	if hero.FindAllModifiers ~= nil then
		for _, modifier in pairs(hero:FindAllModifiers()) do
			for _, stateName in pairs(status.states or {}) do
				if self:ModifierHasState(modifier, stateName) then
					return true
				end
			end
		end
	end

	return false
end

function XHSOverheadStatus:GetHeroStatusEffect(hero)
	if hero == nil or hero:IsNull() then return nil end

	for _, status in pairs(self.PRIORITY) do
		if self:HeroMatchesStatus(hero, status) then
			local remaining = self:GetStatusRemainingTime(hero, status)
			local payload = {
				key = status.key,
				label = status.label,
				class_name = status.class_name,
				remaining = remaining,
			}

			if remaining > 0 then
				payload.end_time = GameRules:GetGameTime() + remaining
			end

			return payload
		end
	end

	return nil
end

function XHSOverheadStatus:BuildPayload(hero)
	if hero == nil or hero:IsNull() or not hero:IsRealHero() then return nil end

	local status = self:GetHeroStatusEffect(hero)
	if status == nil then
		return {
			active = 0,
		}
	end

	status.active = 1
	status.remaining = math.max(0, status.remaining or 0)
	status.remaining_tenths = math.ceil(status.remaining * 10)
	return status
end

function XHSOverheadStatus:PublishHero(hero)
	if hero == nil or hero:IsNull() then return end

	local entIndex = hero:entindex()
	local payload = self:BuildPayload(hero)
	if payload == nil then return end

	local cacheKey = tostring(entIndex)
	local signature = table.concat({
		tostring(payload.active or 0),
		tostring(payload.key or ""),
		tostring(payload.remaining_tenths or 0),
	}, ":")

	if self.cache[cacheKey] == signature then return end
	self.cache[cacheKey] = signature

	CustomNetTables:SetTableValue(self.NET_TABLE, cacheKey .. "_status_effect", payload)
end

function XHSOverheadStatus:Think()
	local maxPlayers = DOTA_MAX_TEAM_PLAYERS or 24
	for playerID = 0, maxPlayers - 1 do
		if PlayerResource:IsValidPlayerID(playerID) and PlayerResource:HasSelectedHero(playerID) then
			self:PublishHero(PlayerResource:GetSelectedHeroEntity(playerID))
		end
	end

	return self.REFRESH_SECONDS
end

function XHSOverheadStatus:Init()
	if self.initialized == true then return end
	self.initialized = true

	if Timers ~= nil then
		Timers:CreateTimer(self.REFRESH_SECONDS, function()
			return self:Think()
		end)
	else
		GameRules:GetGameModeEntity():SetContextThink("xhs_overhead_status", function()
			return self:Think()
		end, self.REFRESH_SECONDS)
	end
end
