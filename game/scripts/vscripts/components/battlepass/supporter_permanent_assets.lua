-- Permanent Supporter Pass runtime manifest.
--
-- This file is intentionally source-controlled and loaded before Precache().
-- An item is eligible for normal-map precache only when both `approved` and
-- `published` are explicitly true here. Content Studio review state is never
-- promoted into this manifest automatically.

local Manifest = {
	SCHEMA_VERSION = 1,
	ITEMS = {
		-- Keep empty until a reviewed permanent catalog item is approved for a
		-- game release. Expected shape:
		-- ["permanent_item_id"] = {
		-- 	approved = true,
		-- 	published = true,
		-- 	slot_id = "teleport",
		-- 	asset_path = "particles/.../start.vpcf",
		-- 	effect_paths = { ["end"] = "particles/.../end.vpcf" },
		-- },
	},
}

local PARTICLE_FIELDS = {
	"asset_path",
	"start_pfx",
	"end_pfx",
	"pfx",
	"target_pfx",
	"caster_pfx",
	"health_pfx",
	"mana_pfx",
	"light_pfx",
	"owner_pfx",
	"overhead_pfx",
	"travel_pfx",
	"impact_pfx",
}

local function IsPublishedEntry(entry)
	return type(entry) == "table"
		and entry.approved == true
		and entry.published == true
end

local function IsParticlePath(value)
	return type(value) == "string"
		and string.match(string.lower(value), "^particles/.+%.vpcf$") ~= nil
end

local function CopyTable(source)
	local copy = {}
	if type(source) ~= "table" then return copy end
	for key, value in pairs(source) do
		copy[key] = type(value) == "table" and CopyTable(value) or value
	end
	return copy
end

local function AddUnique(result, seen, value)
	if value == nil or value == "" or seen[value] then return end
	seen[value] = true
	table.insert(result, value)
end

local function CollectParticleValues(value, result, seen)
	if IsParticlePath(value) then
		AddUnique(result, seen, value)
		return
	end
	if type(value) ~= "table" then return end
	for _, nested in pairs(value) do
		CollectParticleValues(nested, result, seen)
	end
end

function Manifest:IsPublished(itemID)
	return IsPublishedEntry(self.ITEMS[tostring(itemID or "")])
end

function Manifest:GetItem(itemID)
	local entry = self.ITEMS[tostring(itemID or "")]
	if not IsPublishedEntry(entry) then return nil end
	return CopyTable(entry)
end

function Manifest:FindItem(value)
	if value == nil then return nil end
	if type(value) ~= "table" then
		return self:GetItem(value)
	end

	for _, field in ipairs({
		"catalog_item_id",
		"catalog_item_key",
		"item_key",
		"item_id",
		"entitlement_id",
		"id",
	}) do
		local entry = self:GetItem(value[field])
		if entry ~= nil then return entry end
	end
	return nil
end

function Manifest:BuildPrecacheGroup()
	local group = {
		particles = {},
		models = {},
		model_folders = {},
		soundfiles = {},
		units = {},
		items = {},
	}
	local seenParticles = {}
	local seenByKind = {
		models = {},
		model_folders = {},
		soundfiles = {},
		units = {},
		items = {},
	}

	for _, entry in pairs(self.ITEMS) do
		if IsPublishedEntry(entry) then
			for _, field in ipairs(PARTICLE_FIELDS) do
				CollectParticleValues(entry[field], group.particles, seenParticles)
			end
			CollectParticleValues(entry.effect_paths, group.particles, seenParticles)
			CollectParticleValues(entry.runtime, group.particles, seenParticles)
			CollectParticleValues(entry.runtime_assets, group.particles, seenParticles)
			CollectParticleValues(entry.visuals, group.particles, seenParticles)

			local explicit = type(entry.precache) == "table" and entry.precache or {}
			CollectParticleValues(explicit.particle or explicit.particles, group.particles, seenParticles)
			for _, kind in ipairs({ "models", "model_folders", "soundfiles", "units", "items" }) do
				local values = explicit[kind]
				if type(values) == "string" then values = { values } end
				for _, value in pairs(type(values) == "table" and values or {}) do
					if type(value) == "string" and value ~= "" then
						AddUnique(group[kind], seenByKind[kind], value)
					end
				end
			end
		end
	end

	table.sort(group.particles)
	for kind, values in pairs(group) do
		if kind ~= "particles" then table.sort(values) end
	end
	return group
end

_G.SupporterPermanentAssets = Manifest

if XHSPrecache ~= nil and XHSPrecache.RegisterGroup ~= nil then
	XHSPrecache:RegisterGroup(
		"supporter_permanent_published",
		Manifest:BuildPrecacheGroup()
	)
end

return Manifest
