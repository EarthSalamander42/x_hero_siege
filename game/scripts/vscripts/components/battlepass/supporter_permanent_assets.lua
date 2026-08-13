-- Permanent Supporter Pass runtime manifest.
--
-- This file is intentionally source-controlled and loaded before Precache().
-- An item is eligible for normal-map precache only when both `approved` and
-- `published` are explicitly true here. Content Studio review state is never
-- promoted into this manifest automatically.

local Manifest = {
	SCHEMA_VERSION = 1,
	ITEMS = {
		-- Rebirth audit batch 2026-08-11. These entries are deliberately staged
		-- but disabled until their VPCFs have been reviewed in Content Studio on
		-- x_hero_siege_demo. Once a candidate is approved and published in the
		-- permanent catalog, flip both flags for the matching stable item ID.
		["sp40_shop_rebirth_icewrack"] = {
			approved = false,
			published = false,
			slot_id = "rebirth",
			asset_path = "particles/econ/items/crystal_maiden/crystal_maiden_maiden_of_icewrack/cm_arcana_pup_spawn.vpcf",
		},
		["sp40_shop_rebirth_seismic_apotheosis"] = {
			approved = false,
			published = false,
			slot_id = "rebirth",
			asset_path = "particles/econ/items/earthshaker/earthshaker_arcana/earthshaker_arcana_spawn_v2.vpcf",
		},
		["sp40_shop_rebirth_phantom_legacy"] = {
			approved = false,
			published = false,
			slot_id = "rebirth",
			asset_path = "particles/econ/items/phantom_lancer/phantom_lancer_fall20_immortal/phantom_lancer_fall20_immortal_spawn.vpcf",
		},
		["sp40_shop_rebirth_haunting_rift_style2"] = {
			approved = false,
			published = false,
			slot_id = "rebirth",
			asset_path = "particles/econ/items/spectre/spectre_arcana/spectre_arcana_loadout_spawn_v2.vpcf",
		},
		["sp40_shop_rebirth_watchers_arrival"] = {
			approved = true,
			published = true,
			slot_id = "rebirth",
			asset_path = "particles/econ/events/ti9/shovel/shovel_baby_roshan_spawn.vpcf",
		},
		["sp40_shop_rebirth_stonefall"] = {
			approved = false,
			published = false,
			slot_id = "rebirth",
			asset_path = "particles/neutral_fx/roshan_spawn.vpcf",
		},
		["sp40_shop_rebirth_divine_descent"] = {
			approved = false,
			published = false,
			slot_id = "rebirth",
			asset_path = "particles/ui/ui_game_start_hero_spawn.vpcf",
		},
		["sp40_shop_rebirth_mistborne"] = {
			approved = false,
			published = false,
			slot_id = "rebirth",
			asset_path = "particles/units/heroes/hero_abaddon/abaddon_spawn.vpcf",
		},
		["sp40_shop_rebirth_exorcists_return"] = {
			approved = false,
			published = false,
			slot_id = "rebirth",
			asset_path = "particles/units/heroes/hero_death_prophet/death_prophet_spawn.vpcf",
		},
		["sp40_shop_rebirth_chronal_aperture"] = {
			approved = false,
			published = false,
			slot_id = "rebirth",
			asset_path = "particles/units/heroes/hero_faceless_void/faceless_void_spawn.vpcf",
		},
		["sp40_shop_rebirth_young_magus_debut"] = {
			approved = false,
			published = false,
			slot_id = "rebirth",
			asset_path = "particles/units/heroes/hero_invoker_kid/invoker_kid_debut_spawn.vpcf",
		},
		["sp40_shop_rebirth_phantom_arrival"] = {
			approved = false,
			published = false,
			slot_id = "rebirth",
			asset_path = "particles/units/heroes/hero_phantom_lancer/phantom_lancer_spawn.vpcf",
		},
		["sp40_shop_rebirth_winterwake"] = {
			approved = false,
			published = false,
			slot_id = "rebirth",
			asset_path = "particles/units/heroes/hero_winter_wyvern/wyvern_spawn.vpcf",
		},
		["sp40_shop_rebirth_faceless_void"] = {
			approved = true,
			published = true,
			slot_id = "rebirth",
			asset_path = "particles/econ/items/faceless_void/faceless_void_arcana/faceless_void_arcana_game_spawn.vpcf",
		},
		-- Keep the published item ID stable so existing owners retain access.
		-- Only its unusable Drow model-dependent runtime is replaced.
		["sp40_shop_rebirth_drow"] = {
			approved = true,
			published = true,
			slot_id = "rebirth",
			asset_path = "models/heroes/muerta/debut/particles/revenant/muerta_debut_revenant_spawn_portal.vpcf",
		},
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
	if type(value) ~= "string" then return false end
	local normalized = string.lower(value)
	return string.match(normalized, "^particles/.+%.vpcf$") ~= nil
		or normalized == "models/heroes/muerta/debut/particles/revenant/muerta_debut_revenant_spawn_portal.vpcf"
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
