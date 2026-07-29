XHSItemBuilds = XHSItemBuilds or class({})

local SCHEMA_VERSION = 1
local MAX_BUILDS = 3
local MAX_ITEMS_PER_SECTION = 12
local MAX_TOTAL_ITEMS = 60
local MAX_BUILD_NAME_BYTES = 128
local SECTION_KEYS = { "starting", "early", "core", "situational", "late" }
local ALLOWED_MAPS = {
	x_hero_siege_4 = true,
	x_hero_siege_8 = true,
	x_hero_siege_demo = true,
}
local ALLOWED_ITEMS = {
	item_amulet_of_the_wild = true,
	item_ankh_of_reincarnation = true,
	item_astral_core = true,
	item_boots_of_speed = true,
	item_bracer_of_the_void = true,
	item_celestial_claws = true,
	item_healing_wards = true,
	item_healing_wards2 = true,
	item_health_potion = true,
	item_lifesteal_mask = true,
	item_mana_potion = true,
	item_mystic_gem = true,
	item_orb_of_arcane = true,
	item_orb_of_darkness = true,
	item_orb_of_darkness2 = true,
	item_orb_of_earth = true,
	item_orb_of_earth2 = true,
	item_orb_of_earth3 = true,
	item_orb_of_fire = true,
	item_orb_of_fire2 = true,
	item_orb_of_lightning = true,
	item_orb_of_lightning2 = true,
	item_orb_of_wind = true,
	item_plagueheart = true,
	item_potion_full = true,
	item_potion_of_antimagic = true,
	item_potion_of_invulnerability = true,
	item_searing_blade = true,
	item_staff_of_mastery = true,
	item_tempest_aegis = true,
	item_tome_big = true,
	item_tome_of_power = true,
	item_tome_small = true,
	item_viridian_gem = true,
	item_xhs_cloak_of_flames = true,
	item_xhs_orb_of_venom = true,
	item_zephyr_gem = true,
}

local function sortedAllowedItems()
	local items = {}
	for item_name in pairs(ALLOWED_ITEMS) do
		table.insert(items, item_name)
	end
	table.sort(items)
	return items
end

local ALLOWED_ITEMS_ARRAY = sortedAllowedItems()

local function normalizeArray(value)
	if type(value) ~= "table" then return {} end

	local indexed = {}
	for key, entry in pairs(value) do
		local numeric_key = tonumber(key)
		if numeric_key ~= nil and numeric_key >= 0 and math.floor(numeric_key) == numeric_key then
			table.insert(indexed, { index = numeric_key, value = entry })
		end
	end
	table.sort(indexed, function(left, right)
		return left.index < right.index
	end)

	local result = {}
	for _, entry in ipairs(indexed) do
		table.insert(result, entry.value)
	end
	return result
end

local function cleanText(value, max_bytes)
	value = tostring(value or "")
	value = string.gsub(value, "[%z\1-\31\127]", "")
	value = string.gsub(value, "^%s+", "")
	value = string.gsub(value, "%s+$", "")
	if #value > max_bytes then
		value = string.sub(value, 1, max_bytes)
	end
	return value
end

local function validHeroName(hero_name)
	return type(hero_name) == "string"
		and #hero_name <= 96
		and string.match(hero_name, "^npc_dota_hero_[%w_]+$") ~= nil
end

local function validIdempotencyKey(value)
	local key = tostring(value or "")
	key = string.gsub(key, "^%s+", "")
	key = string.gsub(key, "%s+$", "")
	if #key < 1 or #key > 128 then return nil end
	if string.match(key, "^[%w_%.:%-]+$") == nil then return nil end
	return key
end

local function utf8CharacterCount(value)
	local without_continuation_bytes = string.gsub(value, "[\128-\191]", "")
	return #without_continuation_bytes
end

local function getPlayerHeroName(player_id)
	local hero = PlayerResource:GetSelectedHeroEntity(player_id)
	if hero ~= nil and not hero:IsNull() then
		return hero:GetUnitName()
	end

	local ok, hero_name = pcall(function()
		return PlayerResource:GetSelectedHeroName(player_id)
	end)
	if ok and validHeroName(hero_name) then
		return hero_name
	end
	return nil
end

local function currentMapScope()
	local map_name = tostring(GetMapName() or "")
	if ALLOWED_MAPS[map_name] then
		return map_name
	end
	return nil
end

local function validatePayload(payload)
	if type(payload) ~= "table" then
		return nil, "payload must be an object"
	end
	if tonumber(payload.schema_version) ~= SCHEMA_VERSION then
		return nil, "unsupported schema version"
	end

	local source_builds = normalizeArray(payload.builds)
	if #source_builds < 1 or #source_builds > MAX_BUILDS then
		return nil, "invalid build count"
	end

	local normalized = {
		schema_version = SCHEMA_VERSION,
		active_build_id = cleanText(payload.active_build_id, 64),
		builds = {},
	}
	local ids = {}
	local total_items = 0

	for _, source_build in ipairs(source_builds) do
		if type(source_build) ~= "table" then
			return nil, "invalid build"
		end

		local build_id = cleanText(source_build.id, 64)
		if build_id == "" or string.match(build_id, "^[%w_%-]+$") == nil or ids[build_id] then
			return nil, "invalid or duplicate build id"
		end
		ids[build_id] = true

		local build_name = cleanText(source_build.name, MAX_BUILD_NAME_BYTES + 1)
		if build_name == "" or #build_name > MAX_BUILD_NAME_BYTES or utf8CharacterCount(build_name) > 32 then
			return nil, "invalid build name"
		end

		local build = {
			id = build_id,
			name = build_name,
			sections = {},
		}
		local source_sections = type(source_build.sections) == "table" and source_build.sections or {}

		for _, section_key in ipairs(SECTION_KEYS) do
			local source_items = normalizeArray(source_sections[section_key])
			if #source_items > MAX_ITEMS_PER_SECTION then
				return nil, "too many items in section"
			end

			build.sections[section_key] = {}
			for _, item_name in ipairs(source_items) do
				item_name = tostring(item_name or "")
				if not ALLOWED_ITEMS[item_name] then
					return nil, "item is not available in the current XHS shop: " .. item_name
				end
				total_items = total_items + 1
				if total_items > MAX_TOTAL_ITEMS then
					return nil, "too many items in payload"
				end
				table.insert(build.sections[section_key], item_name)
			end
		end

		table.insert(normalized.builds, build)
	end

	if not ids[normalized.active_build_id] then
		return nil, "active build does not exist"
	end
	return normalized, nil
end

function XHSItemBuilds:GetPlayerID(event_source_index, payload)
	if api == nil or api.GetEventPlayerID == nil then return nil end
	return api:GetEventPlayerID(event_source_index, payload)
end

function XHSItemBuilds:GetPersistentSteamID(player_id)
	if api == nil or api.GetPersistentPlayerSteamID == nil then return nil end
	return api:GetPersistentPlayerSteamID(player_id)
end

function XHSItemBuilds:Send(player_id, event_name, payload)
	local player = PlayerResource:GetPlayer(player_id)
	if player == nil then return end
	CustomGameEventManager:Send_ServerToPlayer(player, event_name, payload)
end

function XHSItemBuilds:IsRateLimited(player_id, action, interval)
	self.last_request = self.last_request or {}
	local key = tostring(player_id) .. ":" .. action
	local now = GameRules:GetGameTime()
	local previous = tonumber(self.last_request[key] or -1000)
	if now - previous < interval then return true end
	self.last_request[key] = now
	return false
end

function XHSItemBuilds:Reject(player_id, event_name, payload, message, extra)
	payload = payload or {}
	local response = {
		request_id = tostring(payload.request_id or ""),
		hero_name = tostring(payload.hero_name or ""),
		ok = 0,
		error = tostring(message or "request rejected"),
	}
	for key, value in pairs(extra or {}) do
		response[key] = value
	end
	self:Send(player_id, event_name, response)
end

function XHSItemBuilds:ValidateIdentityAndHero(event_source_index, payload)
	local player_id = self:GetPlayerID(event_source_index, payload)
	if player_id == nil then return nil, nil, nil, "invalid event source" end

	local steam_id = self:GetPersistentSteamID(player_id)
	if steam_id == nil then return player_id, nil, nil, "persistent Steam identity unavailable" end

	local requested_hero = tostring(payload.hero_name or "")
	local actual_hero = getPlayerHeroName(player_id)
	if not validHeroName(requested_hero) or requested_hero ~= actual_hero then
		return player_id, steam_id, actual_hero, "hero does not belong to sender"
	end
	return player_id, steam_id, actual_hero, nil
end

function XHSItemBuilds:OnLoad(event_source_index, payload)
	payload = type(payload) == "table" and payload or {}
	local player_id, steam_id, hero_name, identity_error = self:ValidateIdentityAndHero(event_source_index, payload)
	if player_id == nil then return end
	if identity_error then
		return self:Reject(player_id, "xhs_item_builds_load_response", payload, identity_error)
	end
	if self:IsRateLimited(player_id, "load", 0.35) then
		return self:Reject(player_id, "xhs_item_builds_load_response", payload, "rate limited")
	end

	local map_scope = currentMapScope()
	if map_scope == nil then
		return self:Reject(player_id, "xhs_item_builds_load_response", payload, "unsupported XHS map")
	end
	api:Request("item-builds/get", function(data)
		self:Send(player_id, "xhs_item_builds_load_response", {
			request_id = tostring(payload.request_id or ""),
			hero_name = hero_name,
			map_scope = map_scope,
			ok = 1,
			revision = tonumber(data.revision or 0),
			payload = data.payload,
			allowed_items = ALLOWED_ITEMS_ARRAY,
		})
	end, function(error_data)
		self:Reject(player_id, "xhs_item_builds_load_response", payload, error_data and error_data.message or "backend unavailable", {
			map_scope = map_scope,
			allowed_items = ALLOWED_ITEMS_ARRAY,
		})
	end, "POST", {
		steamid = steam_id,
		hero_name = hero_name,
		map_scope = map_scope,
		schema_version = SCHEMA_VERSION,
	})
end

function XHSItemBuilds:OnSave(event_source_index, payload)
	payload = type(payload) == "table" and payload or {}
	local player_id, steam_id, hero_name, identity_error = self:ValidateIdentityAndHero(event_source_index, payload)
	if player_id == nil then return end
	if identity_error then
		return self:Reject(player_id, "xhs_item_builds_save_response", payload, identity_error)
	end
	if self:IsRateLimited(player_id, "save", 0.2) then
		return self:Reject(player_id, "xhs_item_builds_save_response", payload, "rate limited")
	end

	local normalized, validation_error = validatePayload(payload.payload)
	if validation_error then
		return self:Reject(player_id, "xhs_item_builds_save_response", payload, validation_error)
	end

	local idempotency_key = validIdempotencyKey(payload.idempotency_key)
	if idempotency_key == nil then
		return self:Reject(player_id, "xhs_item_builds_save_response", payload, "invalid idempotency key")
	end

	local map_scope = currentMapScope()
	if map_scope == nil then
		return self:Reject(player_id, "xhs_item_builds_save_response", payload, "unsupported XHS map")
	end
	api:Request("item-builds/save", function(data)
		self:Send(player_id, "xhs_item_builds_save_response", {
			request_id = tostring(payload.request_id or ""),
			hero_name = hero_name,
			map_scope = map_scope,
			ok = data.ok == false and 0 or 1,
			conflict = data.conflict == true and 1 or 0,
			revision = tonumber(data.revision or 0),
			error = tostring(data.error or ""),
		})
	end, function(error_data)
		self:Reject(player_id, "xhs_item_builds_save_response", payload, error_data and error_data.message or "backend unavailable")
	end, "POST", {
		steamid = steam_id,
		hero_name = hero_name,
		map_scope = map_scope,
		schema_version = SCHEMA_VERSION,
		expected_revision = math.max(0, math.floor(tonumber(payload.expected_revision) or 0)),
		idempotency_key = idempotency_key,
		payload = normalized,
	})
end

function XHSItemBuilds:Init()
	if self.initialized then return end
	self.initialized = true
	CustomGameEventManager:RegisterListener("xhs_item_builds_load", function(...)
		return self:OnLoad(...)
	end)
	CustomGameEventManager:RegisterListener("xhs_item_builds_save", function(...)
		return self:OnSave(...)
	end)
	print("[XHSItemBuilds] Durable personal item builds initialized")
end

XHSItemBuilds:Init()
