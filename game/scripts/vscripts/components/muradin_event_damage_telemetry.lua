modifier_xhs_muradin_event_damage_telemetry = modifier_xhs_muradin_event_damage_telemetry or class({})

local DAMAGE_TYPE_NAMES = {
	[DAMAGE_TYPE_PHYSICAL] = "physical",
	[DAMAGE_TYPE_MAGICAL] = "magical",
	[DAMAGE_TYPE_PURE] = "pure",
}

local DAMAGE_CATEGORY_NAMES = {
	[DOTA_DAMAGE_CATEGORY_ATTACK] = "attack",
	[DOTA_DAMAGE_CATEGORY_SPELL] = "spell",
}

local function IsValidHandle(entity)
	return entity ~= nil and IsValidEntity(entity) and not entity:IsNull()
end

local function UnitName(unit)
	if not IsValidHandle(unit) or unit.GetUnitName == nil then return "unknown" end
	local ok, value = pcall(function() return unit:GetUnitName() end)
	return ok and tostring(value or "unknown") or "unknown"
end

local function PlayerID(unit)
	if not IsValidHandle(unit) or unit.GetPlayerOwnerID == nil then return -1 end
	local ok, value = pcall(function() return unit:GetPlayerOwnerID() end)
	return ok and (tonumber(value) or -1) or -1
end

local function ResolveDamageSource(attacker)
	if not IsValidHandle(attacker) then return nil, nil end
	local source = attacker
	local owner = nil
	if attacker.GetOwnerEntity ~= nil then
		pcall(function() owner = attacker:GetOwnerEntity() end)
	end
	if IsValidHandle(owner) and owner.IsRealHero ~= nil then
		local ok, isHero = pcall(function() return owner:IsRealHero() end)
		if ok and isHero then source = owner end
	end
	return source, owner
end

local function AbilityName(inflictor)
	if not IsValidHandle(inflictor) or inflictor.GetAbilityName == nil then return "attack" end
	local ok, value = pcall(function() return inflictor:GetAbilityName() end)
	return ok and tostring(value or "unknown_spell") or "unknown_spell"
end

local function LogTelemetry(severity, code, message, context)
	if XHSObservability ~= nil and type(XHSObservability.Log) == "function" then
		local ok = pcall(function()
			XHSObservability:Log(
				severity or "info",
				"muradin_event_damage",
				code,
				message,
				context or {}
			)
		end)
		if ok then return end
	end
	if XHSBootstrapLog ~= nil then
		pcall(XHSBootstrapLog, severity or "info", "[XHS][MuradinDamage] " .. tostring(message))
	end
end

function modifier_xhs_muradin_event_damage_telemetry:IsHidden() return true end
function modifier_xhs_muradin_event_damage_telemetry:IsPurgable() return false end
function modifier_xhs_muradin_event_damage_telemetry:RemoveOnDeath() return false end

function modifier_xhs_muradin_event_damage_telemetry:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_EVENT_ON_DEATH,
	}
end

function modifier_xhs_muradin_event_damage_telemetry:OnCreated(params)
	if not IsServer() then return end
	self.startedAt = GameRules:GetGameTime()
	self.eventDuration = tonumber(params and params.event_duration) or 0
	self.totalDamage = 0
	self.totalHits = 0
	self.sources = {}
	self.flushed = false
end

function modifier_xhs_muradin_event_damage_telemetry:OnTakeDamage(params)
	if not IsServer() or params.unit ~= self:GetParent() then return end
	local damage = math.max(0, tonumber(params.damage) or 0)
	if damage <= 0 then return end

	local attacker = params.attacker
	local source, owner = ResolveDamageSource(attacker)
	local attackerName = UnitName(attacker)
	local sourceName = UnitName(source)
	local ownerName = UnitName(owner)
	local playerID = PlayerID(source)
	if playerID < 0 then playerID = PlayerID(attacker) end
	local abilityName = AbilityName(params.inflictor)
	local damageType = DAMAGE_TYPE_NAMES[params.damage_type] or tostring(params.damage_type or "unknown")
	local category = DAMAGE_CATEGORY_NAMES[params.damage_category]
		or (params.inflictor == nil and "attack" or "spell")
	local damageFlags = tonumber(params.damage_flags) or 0
	local key = table.concat({
		tostring(playerID), sourceName, attackerName, abilityName,
		damageType, category, tostring(damageFlags),
	}, "|")
	local record = self.sources[key]
	if record == nil then
		record = {
			player_id = playerID,
			source_hero = sourceName,
			attacker_unit = attackerName,
			owner_unit = ownerName,
			ability = abilityName,
			damage_type = damageType,
			damage_category = category,
			damage_flags = damageFlags,
			total_damage = 0,
			original_damage = 0,
			hits = 0,
			max_hit = 0,
			first_game_time = GameRules:GetGameTime(),
		}
		self.sources[key] = record
	end

	record.total_damage = record.total_damage + damage
	record.original_damage = record.original_damage
		+ math.max(0, tonumber(params.original_damage) or damage)
	record.hits = record.hits + 1
	record.max_hit = math.max(record.max_hit, damage)
	record.last_game_time = GameRules:GetGameTime()
	record.health_after = math.max(0, self:GetParent():GetHealth())
	record.health_before = record.health_after + damage
	self.totalDamage = self.totalDamage + damage
	self.totalHits = self.totalHits + 1
end

function modifier_xhs_muradin_event_damage_telemetry:Flush(reason, killer)
	if not IsServer() or self.flushed then return end
	self.flushed = true
	local parent = self:GetParent()
	local records = {}
	for _, record in pairs(self.sources or {}) do table.insert(records, record) end
	table.sort(records, function(left, right)
		return (tonumber(left.total_damage) or 0) > (tonumber(right.total_damage) or 0)
	end)

	local elapsed = math.max(0, GameRules:GetGameTime() - (tonumber(self.startedAt) or 0))
	LogTelemetry(reason == "death" and "warn" or "info", "MURADIN_DAMAGE_SUMMARY",
		"Muradin event damage summary", {
			reason = tostring(reason or "unknown"),
			alive = IsValidHandle(parent) and parent:IsAlive() or false,
			health = IsValidHandle(parent) and parent:GetHealth() or 0,
			max_health = IsValidHandle(parent) and parent:GetMaxHealth() or 0,
			total_damage = self.totalDamage or 0,
			total_hits = self.totalHits or 0,
			source_count = #records,
			elapsed = elapsed,
			event_duration = self.eventDuration or 0,
			killer = UnitName(killer),
		})

	for rank, record in ipairs(records) do
		record.rank = rank
		record.flush_reason = tostring(reason or "unknown")
		record.effective_damage_pct = (tonumber(record.original_damage) or 0) > 0
			and (tonumber(record.total_damage) or 0) / record.original_damage * 100 or 0
		LogTelemetry(reason == "death" and "warn" or "info", "MURADIN_DAMAGE_SOURCE",
			"Muradin damaged by " .. tostring(record.source_hero)
				.. " via " .. tostring(record.ability), record)
	end
end

function modifier_xhs_muradin_event_damage_telemetry:OnDeath(params)
	if not IsServer() or params.unit ~= self:GetParent() then return end
	self:Flush("death", params.attacker)
end

function modifier_xhs_muradin_event_damage_telemetry:OnDestroy()
	if not IsServer() then return end
	self:Flush("removed")
end
