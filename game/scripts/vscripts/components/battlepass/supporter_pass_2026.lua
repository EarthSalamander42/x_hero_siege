-- Supporter Pass 2026 canonical season adapter.
--
-- The historical items.txt catalog remains untouched. This module loads the
-- season manifest, adds catalog ids 41..124 in memory and builds exactly one
-- Free and one Premium reward for each of the 50 levels.

SupporterPass2026 = SupporterPass2026 or {}

SupporterPass2026.MANIFEST_PATH =
	"scripts/vscripts/components/battlepass/keyvalues/supporter_pass_2026.txt"
SupporterPass2026.SEASON_ID = "2026"
SupporterPass2026.LEVEL_COUNT = 50
SupporterPass2026.TRACK_NETTABLE_SCHEMA = 2
SupporterPass2026.TRACK_CHUNK_SIZE = 10
SupporterPass2026.BACKEND_SEASON_IDS = {
	["2026"] = true,
	["xhs_2026_s1"] = true,
}

SupporterPass2026.ANCHORS = {
	regen_aura = "particles/custom/supporter_pass/regen_aura_anchor.vpcf",
	attack_lifesteal = "particles/custom/supporter_pass/attack_lifesteal_anchor.vpcf",
	spell_lifesteal = "particles/custom/supporter_pass/spell_lifesteal_anchor.vpcf",
	immolation_owner = "particles/custom/supporter_pass/immolation_owner_anchor.vpcf",
	immolation_target = "particles/custom/supporter_pass/immolation_target_anchor.vpcf",
	rebirth = "particles/custom/supporter_pass/rebirth_anchor.vpcf",
	health_potion = "particles/custom/supporter_pass/health_potion_anchor.vpcf",
	mana_potion = "particles/custom/supporter_pass/mana_potion_anchor.vpcf",
	light_potion = "particles/custom/supporter_pass/light_potion_anchor.vpcf",
}

local PARTICLE_FIELDS = {
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

local VISUAL_CHANNELS = {
	teleport = {
		{ field = "start_pfx", anchor = "particles/items2_fx/teleport_start.vpcf" },
		{ field = "end_pfx", anchor = "particles/items2_fx/teleport_end.vpcf" },
	},
	levelup = {
		{ field = "pfx", anchor = "particles/generic_hero_status/hero_levelup.vpcf" },
	},
	kill_effect = {
		{ field = "target_pfx", anchor = "particles/kill_effect/default_target.vpcf" },
		{ field = "caster_pfx", anchor = "particles/kill_effect/default_caster.vpcf" },
	},
	emblem = {
		{ field = "pfx", anchor = "particles/hero_emblem/default.vpcf" },
	},
	potion = {
		{ field = "health_pfx", anchor = SupporterPass2026.ANCHORS.health_potion },
		{ field = "mana_pfx", anchor = SupporterPass2026.ANCHORS.mana_potion },
		{ field = "light_pfx", anchor = SupporterPass2026.ANCHORS.light_potion },
	},
	rebirth = {
		{ field = "pfx", anchor = SupporterPass2026.ANCHORS.rebirth },
	},
	attack_lifesteal = {
		{ field = "pfx", anchor = SupporterPass2026.ANCHORS.attack_lifesteal },
	},
	spell_lifesteal = {
		{ field = "pfx", anchor = SupporterPass2026.ANCHORS.spell_lifesteal },
	},
	regen_aura = {
		{ field = "pfx", anchor = SupporterPass2026.ANCHORS.regen_aura },
	},
	immolation = {
		{ field = "owner_pfx", anchor = SupporterPass2026.ANCHORS.immolation_owner },
		{ field = "target_pfx", anchor = SupporterPass2026.ANCHORS.immolation_target },
	},
}

local function CopyTable(source)
	local copy = {}
	if type(source) ~= "table" then return copy end
	for key, value in pairs(source) do
		if type(value) == "table" then
			copy[key] = CopyTable(value)
		else
			copy[key] = value
		end
	end
	return copy
end

local function SortedNumericKeys(source)
	local keys = {}
	for key, _ in pairs(source or {}) do
		local numericKey = tonumber(key)
		if numericKey ~= nil then
			table.insert(keys, numericKey)
		end
	end
	table.sort(keys)
	return keys
end

local function ValueAt(source, key)
	if type(source) ~= "table" then return nil end
	return source[key] or source[tostring(key)]
end

local function IsParticlePath(value)
	if type(value) ~= "string" then return false end
	local normalized = string.lower(value)
	return string.sub(normalized, 1, 10) == "particles/"
		and string.sub(normalized, -5) == ".vpcf"
end

local function AddRuntimeAsset(result, seen, hook, path)
	if not IsParticlePath(path) then return end
	local key = tostring(hook) .. "\0" .. path
	if seen[key] then return end
	seen[key] = true
	table.insert(result, {
		kind = "particle",
		hook = hook,
		path = path,
	})
end

function SupporterPass2026:LoadManifest()
	if type(self.manifest) == "table" then
		return self.manifest
	end

	local loaded = LoadKeyValues(self.MANIFEST_PATH) or {}
	self.manifest = loaded.SupporterPass2026 or loaded
	self.catalog = self.manifest.catalog or {}
	self.tracks = self.manifest.tracks or {}
	self.types = self.manifest.types or {}
	self:BuildIndexes()
	return self.manifest
end

function SupporterPass2026:BuildIndexes()
	self.catalogIDByIdentity = {}
	self.trackMetaByCatalogID = {}

	for catalogID, definition in pairs(self.catalog or {}) do
		if type(definition) == "table" then
			catalogID = tostring(catalogID)
			self.catalogIDByIdentity[catalogID] = catalogID
			self.catalogIDByIdentity[
				"supporter_pass_2026:" .. catalogID
			] = catalogID
			for _, identity in ipairs({
				definition.item_name,
				definition.unit,
			}) do
				if identity ~= nil and identity ~= "" then
					self.catalogIDByIdentity[tostring(identity)] = tostring(catalogID)
				end
			end
		end
	end

	for _, track in ipairs({ "free", "premium" }) do
		for _, level in ipairs(SortedNumericKeys((self.tracks or {})[track])) do
			local catalogID = tostring(ValueAt(self.tracks[track], level) or "")
			if catalogID ~= "" then
				local seasonDefinition =
					ValueAt(self.catalog, catalogID)
				local definition = seasonDefinition
				or (ItemsGame ~= nil and ItemsGame.GetItemKV ~= nil
					and ItemsGame:GetItemKV(catalogID))
				local isSeason2026 =
					type(seasonDefinition) == "table"
					or (
						type(definition) == "table"
						and tostring(definition.season_id or "")
							== self.SEASON_ID
					)
				local backendPrefix = isSeason2026
					and "supporter_pass_2026:"
					or "legacy_battlepass:"
				self.catalogIDByIdentity[
					backendPrefix .. catalogID
				] = catalogID
				self.trackMetaByCatalogID[catalogID] = {
					track = track,
					level = level,
				}
				self.catalogIDByIdentity[string.format(
					"sp26_%s_%02d",
					track,
					level
				)] = catalogID
			end
		end
	end
end

function SupporterPass2026:ResolveCatalogID(identity)
	self:LoadManifest()
	if identity == nil then return nil end
	return self.catalogIDByIdentity[tostring(identity)]
end

function SupporterPass2026:GetBackendCatalogKey(identity)
	local catalogID = self:ResolveCatalogID(identity)
	if catalogID == nil then return nil end
	local seasonDefinition = ValueAt(self.catalog, catalogID)
	local definition = seasonDefinition
		or (ItemsGame ~= nil and ItemsGame.GetItemKV ~= nil
			and ItemsGame:GetItemKV(catalogID))
	local isSeason2026 = type(seasonDefinition) == "table"
		or (
			type(definition) == "table"
			and tostring(definition.season_id or "")
				== self.SEASON_ID
		)
	local prefix = isSeason2026
		and "supporter_pass_2026:"
		or "legacy_battlepass:"
	return prefix .. tostring(catalogID)
end

function SupporterPass2026:BuildVisuals(definition)
	local visuals = {}
	local channels = VISUAL_CHANNELS[tostring(definition.item_type or "")]
	for index, channel in ipairs(channels or {}) do
		local particle = definition[channel.field]
		if IsParticlePath(particle) then
			visuals["asset_modifier" .. tostring(index - 1)] = {
				type = "particle",
				asset = channel.anchor,
				modifier = particle,
				channel = channel.field,
			}
		end
	end
	return visuals
end

function SupporterPass2026:BuildRuntimeAssets(definition)
	local runtimeAssets = {}
	local seen = {}
	for _, field in ipairs(PARTICLE_FIELDS) do
		AddRuntimeAsset(runtimeAssets, seen, field, definition[field])
	end
	table.sort(runtimeAssets, function(a, b)
		local aKey = tostring(a.hook) .. "\0" .. tostring(a.path)
		local bKey = tostring(b.hook) .. "\0" .. tostring(b.path)
		return aKey < bKey
	end)
	return runtimeAssets
end

function SupporterPass2026:ApplyCatalog(customKV)
	self:LoadManifest()
	if type(customKV) ~= "table" then return customKV end

	for _, numericID in ipairs(SortedNumericKeys(self.catalog)) do
		local catalogID = tostring(numericID)
		local definition = CopyTable(ValueAt(self.catalog, numericID))
		local trackMeta = self.trackMetaByCatalogID[catalogID] or {}
		local slotID = definition.slot_id or definition.item_type or "default"

		definition.catalog_item_id = catalogID
		definition.item_id = definition.item_id or "16315"
		definition.item_unlock_level = tostring(trackMeta.level or 1)
		definition.premium = trackMeta.track == "premium" and "1" or nil
		definition.used_by_heroes = definition.used_by_heroes or slotID
		definition.season_id = self.SEASON_ID
		definition.visuals = self:BuildVisuals(definition)
		customKV[catalogID] = definition
	end

	return customKV
end

function SupporterPass2026:BuildReward(itemsGame, track, level, catalogID)
	local definition = itemsGame:GetItemKV(catalogID)
	if type(definition) ~= "table" then return nil end

	local rewardID = string.format("sp26_%s_%02d", track, level)
	local runtimeAssets = self:BuildRuntimeAssets(definition)
	if #runtimeAssets == 0 and itemsGame.GetItemRuntimeAssets ~= nil then
		runtimeAssets = itemsGame:GetItemRuntimeAssets(catalogID)
	end
	local reward = {
		id = rewardID,
		reward_id = rewardID,
		season_id = self.SEASON_ID,
		track = track,
		level = level,
		level_required = level,
		item_id = tostring(catalogID),
		catalog_item_id = tostring(catalogID),
		name = definition.item_name,
		type = definition.item_type,
		item_type = definition.item_type,
		slot_id = definition.slot_id or definition.item_type,
		hero = definition.used_by_heroes or definition.slot_id or definition.item_type,
		image = definition.image_inventory,
		image_inventory = definition.image_inventory,
		rarity = definition.item_rarity,
		item_unreleased = definition.item_unreleased,
		runtime_assets = runtimeAssets,
		premium = track == "premium" and 1 or 0,
		required_tier = track == "premium" and 1 or 0,
		legacy = false,
		claimable = true,
	}

	for _, field in ipairs({
		"family",
		"unit",
		"amount",
		"title_text",
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
	}) do
		if definition[field] ~= nil then
			reward[field] = definition[field]
		end
	end

	return reward
end

function SupporterPass2026:BuildTrack(itemsGame, track)
	self:LoadManifest()
	local result = {}
	local trackDefinition = self.tracks[track] or {}

	for level = 1, self.LEVEL_COUNT do
		local catalogID = ValueAt(trackDefinition, level)
		if catalogID ~= nil then
			local reward = self:BuildReward(itemsGame, track, level, tostring(catalogID))
			if reward ~= nil then
				table.insert(result, reward)
			end
		end
	end
	return result
end

function SupporterPass2026:BuildTracks(itemsGame)
	return self:BuildTrack(itemsGame, "free"), self:BuildTrack(itemsGame, "premium")
end

local function CopyRewardRange(rewards, firstIndex, lastIndex)
	local chunk = {}
	for index = firstIndex, math.min(lastIndex, #(rewards or {})) do
		table.insert(chunk, rewards[index])
	end
	return chunk
end

-- A full 50-entry track is roughly 31-35 KiB once semantic PFX fields and
-- runtime_assets are serialized. CustomNetTables values are therefore split
-- deterministically into five small values; `rewards` becomes only the index.
function SupporterPass2026:PublishRewardTrack(tableName, rewards)
	rewards = rewards or {}
	local chunkSize = self.TRACK_CHUNK_SIZE
	local chunkCount = math.max(1, math.ceil(#rewards / chunkSize))
	local chunkKeys = {}

	for chunkIndex = 1, chunkCount do
		local key = string.format("chunk_%02d", chunkIndex)
		chunkKeys[chunkIndex] = key
		if CustomNetTables ~= nil then
			local firstIndex = ((chunkIndex - 1) * chunkSize) + 1
			CustomNetTables:SetTableValue(
				tableName,
				key,
				CopyRewardRange(rewards, firstIndex, firstIndex + chunkSize - 1)
			)
		end
	end

	local index = {
		schema_version = self.TRACK_NETTABLE_SCHEMA,
		season_id = self.SEASON_ID,
		reward_count = #rewards,
		chunk_count = chunkCount,
		chunk_size = chunkSize,
		chunk_keys = chunkKeys,
	}
	if type(rewards[1]) == "table" then
		index.track = rewards[1].track
	end

	-- Publish the index last so clients that react to it can immediately read
	-- every referenced chunk. Existing listeners may also refresh per chunk.
	if CustomNetTables ~= nil then
		CustomNetTables:SetTableValue(tableName, "rewards", index)
	end
	return index
end

function SupporterPass2026:GetPublishedTrack(tableName)
	if CustomNetTables == nil or CustomNetTables.GetTableValue == nil then
		return {}
	end

	local index = CustomNetTables:GetTableValue(tableName, "rewards") or {}
	local chunkCount = tonumber(index.chunk_count) or 0
	if chunkCount <= 0 then
		-- Backward compatibility with the former monolithic value.
		return index
	end

	local result = {}
	for chunkIndex = 1, chunkCount do
		local key = ValueAt(index.chunk_keys, chunkIndex)
			or string.format("chunk_%02d", chunkIndex)
		local chunk = CustomNetTables:GetTableValue(tableName, tostring(key)) or {}
		for _, numericIndex in ipairs(SortedNumericKeys(chunk)) do
			local reward = ValueAt(chunk, numericIndex)
			if type(reward) == "table" then
				table.insert(result, reward)
			end
		end
	end
	return result
end

function SupporterPass2026:BuildCompanionCatalog(itemsGame)
	local companions = {}
	for _, numericID in ipairs(SortedNumericKeys(self.catalog or {})) do
		local catalogID = tostring(numericID)
		local definition = itemsGame:GetItemKV(catalogID)
		if type(definition) == "table" and definition.item_type == "companion" then
			local entry = CopyTable(definition)
			entry.id = catalogID
			entry.item_id = catalogID
			entry.image = entry.image or entry.image_inventory
			entry.rarity = entry.rarity or entry.item_rarity
			table.insert(companions, entry)
		end
	end
	return companions
end

local BACKEND_PROTECTED_FIELDS = {
	id = true,
	reward_id = true,
	season_id = true,
	track = true,
	level = true,
	level_required = true,
	item_id = true,
	catalog_item_id = true,
	name = true,
	type = true,
	item_type = true,
	slot_id = true,
	hero = true,
	image = true,
	image_inventory = true,
	rarity = true,
	runtime_assets = true,
	premium = true,
	required_tier = true,
	family = true,
	unit = true,
	amount = true,
	title_text = true,
	start_pfx = true,
	end_pfx = true,
	pfx = true,
	target_pfx = true,
	caster_pfx = true,
	health_pfx = true,
	mana_pfx = true,
	light_pfx = true,
	owner_pfx = true,
	overhead_pfx = true,
	travel_pfx = true,
	impact_pfx = true,
	-- Player-specific state must never leak through the global reward tracks.
	-- Claims/ownership/equip state is published only in supporter_pass_player.
	claimed = true,
	already_claimed = true,
	claim_state = true,
	claimed_at = true,
	claimed_by = true,
	owned = true,
	already_owned = true,
	equipped = true,
	is_equipped = true,
	unlocked = true,
	locked = true,
	can_claim = true,
}

function SupporterPass2026:IsBackendSeason2026(value)
	local season = value
	local semanticCandidates = {}
	local function AddCandidate(candidate)
		if candidate ~= nil and tostring(candidate) ~= "" then
			table.insert(semanticCandidates, candidate)
		end
	end
	if type(season) == "table" then
		local metadata = season.metadata_json or season.metadata
		if type(metadata) == "table" then
			AddCandidate(metadata.season_id)
			AddCandidate(metadata.season_key)
			AddCandidate(metadata.key)
		end
		AddCandidate(season.season_id)
		AddCandidate(season.season_key)
		AddCandidate(season.key)
		AddCandidate(season.id)
		AddCandidate(season.name)
		AddCandidate(season.title)
	else
		AddCandidate(season)
	end

	local sawOpaqueNumericID = false
	for _, candidate in ipairs(semanticCandidates) do
		if candidate ~= nil and tostring(candidate) ~= "" then
			local normalized = string.lower(tostring(candidate))
			if self.BACKEND_SEASON_IDS[normalized] == true then
				return true
			end
			if string.find(normalized, "2026", 1, true) ~= nil then
				return true
			end
			if tonumber(normalized) ~= nil then
				sawOpaqueNumericID = true
			else
				-- A semantic non-2026 identifier (for example
				-- xhs_2027_s1) is an explicit mismatch.
				return false
			end
		end
	end
	if sawOpaqueNumericID then return nil end
	return nil
end

function SupporterPass2026:IsBackendSeasonPublished(value)
	if type(value) ~= "table" then return nil end
	local status = string.lower(tostring(value.status or ""))
	if status ~= "" and status ~= "active" then return false end
	if value.is_published == false
	or value.is_published == 0
	or value.is_published == "0"
	or value.is_published == "false" then
		return false
	end
	if value.active == false
	and status ~= "active" then
		return false
	end
	return true
end

local function NormalizeBackendRewardID(value)
	if value == nil or tostring(value) == "" then return nil end
	return string.lower(tostring(value))
end

local function IsSupporterPass2026RewardID(value)
	return type(value) == "string"
		and string.sub(value, 1, 5) == "sp26_"
end

local function StrictBackendTrack(value)
	local track = nil
	local found = false
	for _, field in ipairs({ "track", "reward_track" }) do
		if value[field] ~= nil and tostring(value[field]) ~= "" then
			local candidate = string.lower(tostring(value[field]))
			if candidate ~= "free" and candidate ~= "premium" then
				return nil, false
			end
			if track ~= nil and track ~= candidate then
				return nil, false
			end
			track = candidate
			found = true
		end
	end
	return track, found
end

local function StrictBackendLevel(value)
	local level = nil
	local found = false
	for _, field in ipairs({ "level_required", "level", "position" }) do
		if value[field] ~= nil and tostring(value[field]) ~= "" then
			local candidate = tonumber(value[field])
			if candidate == nil or candidate ~= math.floor(candidate) then
				return nil, false
			end
			if level ~= nil and level ~= candidate then
				return nil, false
			end
			level = candidate
			found = true
		end
	end
	return level, found
end

local function BackendRewardIdentity(value, keyHint)
	local explicitIDs = {}
	for _, field in ipairs({ "reward_id", "reward_key" }) do
		local candidate = NormalizeBackendRewardID(value[field])
		if candidate ~= nil then table.insert(explicitIDs, candidate) end
	end

	local idCandidate = NormalizeBackendRewardID(value.id)
	if not IsSupporterPass2026RewardID(idCandidate) then
		idCandidate = nil
	end
	local keyCandidate = NormalizeBackendRewardID(keyHint)
	if not IsSupporterPass2026RewardID(keyCandidate) then
		keyCandidate = nil
	end

	local catalogKey = string.lower(tostring(value.catalog_item_key or ""))
	local has2026CatalogKey =
		string.sub(catalogKey, 1, 20) == "supporter_pass_2026:"
	local has2026ID = idCandidate ~= nil or keyCandidate ~= nil
	for _, candidate in ipairs(explicitIDs) do
		if IsSupporterPass2026RewardID(candidate) then
			has2026ID = true
		end
	end

	local seasonMatches = SupporterPass2026:IsBackendSeason2026(
		value.season_id or value.season
	)
	local hasRewardShape =
		#explicitIDs > 0
		or value.track ~= nil
		or value.reward_track ~= nil
		or value.level ~= nil
		or value.level_required ~= nil
		or value.position ~= nil
	local eligible =
		has2026ID
		or has2026CatalogKey
		or (seasonMatches == true and hasRewardShape)
	if not eligible then return false, nil, true end
	if seasonMatches == false then return true, nil, false end

	local rewardID = nil
	local function AddIdentity(candidate)
		if candidate == nil then return true end
		if rewardID ~= nil and rewardID ~= candidate then return false end
		rewardID = candidate
		return true
	end
	for _, candidate in ipairs(explicitIDs) do
		if not AddIdentity(candidate) then return true, nil, false end
	end
	if not AddIdentity(idCandidate) or not AddIdentity(keyCandidate) then
		return true, nil, false
	end
	return true, rewardID, rewardID ~= nil
end

local function CollectBackend2026RewardEntries(value)
	local result = {}
	local valid = true
	local visiting = {}

	local function Visit(node, keyHint, depth)
		if not valid or type(node) ~= "table" then return end
		if depth > 8 or visiting[node] then
			valid = false
			return
		end
		visiting[node] = true

		local eligible, rewardID, identityValid =
			BackendRewardIdentity(node, keyHint)
		if eligible then
			if not identityValid then
				valid = false
			else
				table.insert(result, {
					reward = node,
					reward_id = rewardID,
				})
			end
		else
			for key, nested in pairs(node) do
				if type(nested) == "table" then
					Visit(nested, key, depth + 1)
				end
			end
		end

		visiting[node] = nil
	end

	Visit(value, nil, 0)
	return result, valid
end

function SupporterPass2026:IsBackendCatalog2026Ready(value)
	if type(value) ~= "table" then return nil end
	local entries, valid = CollectBackend2026RewardEntries(value)
	if not valid or #entries ~= self.LEVEL_COUNT * 2 then return false end

	local seen = {}
	for _, entry in ipairs(entries) do
		local rewardID = entry.reward_id
		local isFreeID =
			string.match(rewardID, "^sp26_free_%d%d$") ~= nil
		local isPremiumID =
			string.match(rewardID, "^sp26_premium_%d%d$") ~= nil
		local idTrack, idLevelText =
			string.match(rewardID, "^sp26_([%a]+)_(%d%d)$")
		local idLevel = tonumber(idLevelText)
		local backendTrack, trackValid = StrictBackendTrack(entry.reward)
		local backendLevel, levelValid = StrictBackendLevel(entry.reward)
		if (not isFreeID and not isPremiumID)
		or (idTrack ~= "free" and idTrack ~= "premium")
		or idLevel == nil
		or idLevel < 1
		or idLevel > self.LEVEL_COUNT
		or not trackValid
		or not levelValid
		or backendTrack ~= idTrack
		or backendLevel ~= idLevel
		or seen[rewardID] then
			return false
		end
		seen[rewardID] = true
	end

	local seenCount = 0
	for _ in pairs(seen) do seenCount = seenCount + 1 end
	if seenCount ~= self.LEVEL_COUNT * 2 then return false end
	for level = 1, self.LEVEL_COUNT do
		if not seen[string.format("sp26_free_%02d", level)]
		or not seen[string.format("sp26_premium_%02d", level)] then
			return false
		end
	end
	return true
end

function SupporterPass2026:MergeBackendTrack(localRewards, backendRewards, track)
	-- Publication is atomic from the game client's point of view. Until both
	-- complete 50-level tracks are live, keep the canonical local catalog
	-- untouched instead of exposing a partially imported hybrid.
	local globalSeason = api
		and api.supporter_pass
		and api.supporter_pass.season
		or nil
	local globalSeasonMatches = self:IsBackendSeason2026(globalSeason)
	local globalSeasonPublished = self:IsBackendSeasonPublished(globalSeason)
	if self:IsBackendCatalog2026Ready(backendRewards) ~= true
	or globalSeasonMatches == false
	or globalSeasonPublished == false then
		local localOnly = {}
		for index, reward in ipairs(localRewards or {}) do
			localOnly[index] = CopyTable(reward)
		end
		return localOnly
	end

	local backendByRewardID = {}
	local backendEntries = CollectBackend2026RewardEntries(backendRewards)
	for _, entry in ipairs(backendEntries) do
		local backendTrack = StrictBackendTrack(entry.reward)
		if backendTrack == track then
			backendByRewardID[entry.reward_id] = entry.reward
		end
	end

	local merged = {}
	for index, localReward in ipairs(localRewards or {}) do
		local reward = CopyTable(localReward)
		local backendReward = backendByRewardID[
			string.lower(tostring(reward.reward_id or ""))
		]

		if type(backendReward) == "table" then
			for field, value in pairs(backendReward) do
				if not BACKEND_PROTECTED_FIELDS[field] then
					reward[field] = value
				end
			end
			if backendReward.id ~= nil and tostring(backendReward.id) ~= reward.id then
				reward.backend_id = backendReward.id
			end
			reward.backend = true
		end
		merged[index] = reward
	end
	return merged
end

function SupporterPass2026:PublishMeta()
	if CustomNetTables == nil then return end
	CustomNetTables:SetTableValue("supporter_pass_meta", "season", {
		season_id = self.SEASON_ID,
		schema_version = tostring((self.manifest or {}).schema_version or "1"),
		level_count = self.LEVEL_COUNT,
		free_reward_count = self.LEVEL_COUNT,
		premium_reward_count = self.LEVEL_COUNT,
	})
	CustomNetTables:SetTableValue("supporter_pass_meta", "types", self.types or {})
end

function SupporterPass2026:Init()
	if self.initialized then
		self:PublishMeta()
		return
	end
	self.initialized = true
	self:LoadManifest()
	self:PublishMeta()

	for _, runtime in ipairs({
		SupporterRegenAura,
		SupporterRecoveryEffects,
		SupporterPassImmolation,
		SupporterHighFive,
	}) do
		if runtime ~= nil and runtime.Init ~= nil then
			runtime:Init()
		end
	end
end

return SupporterPass2026
