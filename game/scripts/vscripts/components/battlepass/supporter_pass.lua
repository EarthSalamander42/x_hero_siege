SupporterPass = SupporterPass or class({})

SupporterPass.DAILY_GAMEPLAY_FRAGMENT_CAP = 100
SupporterPass.DAILY_QUEST_FRAGMENT_CAP = 90
SupporterPass.DAILY_FRAGMENT_CAP = SupporterPass.DAILY_GAMEPLAY_FRAGMENT_CAP + SupporterPass.DAILY_QUEST_FRAGMENT_CAP
SupporterPass.WEEKLY_FRAGMENT_CAP = SupporterPass.DAILY_FRAGMENT_CAP
SupporterPass.SEASON_XP_PER_LEVEL = 1000

local function FirstSupporterValue(...)
	for i = 1, select("#", ...) do
		local value = select(i, ...)
		if value ~= nil then
			return value
		end
	end

	return nil
end

local function CopySupporterTable(source)
	local copy = {}
	if type(source) ~= "table" then
		return copy
	end

	for key, value in pairs(source) do
		copy[key] = value
	end
	return copy
end

-- Valve ships the TI reward thumbnails alongside their Panorama compendium
-- assets. Prefer those canonical images over legacy/custom placeholders so a
-- reward keeps the same preview in tracks, shop, Armory and bundle contents.
local VANILLA_TI_REWARD_IMAGES = {
	levelup = {
		[6] = "s2r://panorama/images/compendium/spring2016/rewards/levelup_fx_png.vtex",
		[7] = "s2r://panorama/images/compendium/international2017/prestigerewards/levelup_fx_png.vtex",
		[8] = "s2r://panorama/images/compendium/international2018/prestigerewards/levelup_fx_png.vtex",
		[9] = "s2r://panorama/images/compendium/international2019/prestigerewards/levelup_fx_png.vtex",
		[10] = "s2r://panorama/images/compendium/international2020/prestigerewards/levelup_fx_png.vtex",
	},
	radiance = {
		[6] = "s2r://panorama/images/compendium/spring2016/rewards/radiance_fx_png.vtex",
		[7] = "s2r://panorama/images/compendium/international2017/prestigerewards/radiance_fx_png.vtex",
		[8] = "s2r://panorama/images/compendium/international2018/prestigerewards/radiance_fx_png.vtex",
		[9] = "s2r://panorama/images/compendium/international2019/prestigerewards/radiance_fx_png.vtex",
		[10] = "s2r://panorama/images/compendium/international2020/prestigerewards/radiance_fx_png.vtex",
	},
	teleport = {
		[4] = "s2r://panorama/images/econ/huds/hud_ti4_png.vtex",
		[5] = "s2r://panorama/images/econ/huds/the_international_2015/hud_the_international_2015_png.vtex",
		[6] = "s2r://panorama/images/compendium/spring2016/rewards/tp_fx_lv3_png.vtex",
		[7] = "s2r://panorama/images/compendium/international2017/prestigerewards/tp_fx_lv3_png.vtex",
		[8] = "s2r://panorama/images/compendium/international2018/prestigerewards/tp_fx_lv3_png.vtex",
		[9] = "s2r://panorama/images/compendium/international2019/prestigerewards/tp_fx_lv3_png.vtex",
		[10] = "s2r://panorama/images/compendium/international2020/prestigerewards/tp_fx_lv2_png.vtex",
	},
	fountain = {
		[4] = "s2r://panorama/images/econ/huds/hud_ti4_png.vtex",
		[5] = "s2r://panorama/images/econ/huds/the_international_2015/hud_the_international_2015_png.vtex",
		[6] = "s2r://panorama/images/compendium/spring2016/rewards/fountain_fx_lv3_png.vtex",
		[7] = "s2r://panorama/images/compendium/international2017/prestigerewards/fountain_fx_lv3_png.vtex",
		[8] = "s2r://panorama/images/compendium/international2018/prestigerewards/fountain_fx_lv3_png.vtex",
		[9] = "s2r://panorama/images/compendium/international2019/prestigerewards/fountain_fx_lv3_png.vtex",
		[10] = "s2r://panorama/images/compendium/international2020/prestigerewards/fountain_fx_lv3_png.vtex",
		[11] = "s2r://panorama/images/compendium/international2022/prestigerewards/fountain_fx_lv3_png.vtex",
	},
	bottle = {
		[6] = "s2r://panorama/images/compendium/spring2016/rewards/bottle_fx_png.vtex",
		[7] = "s2r://panorama/images/compendium/international2017/prestigerewards/bottle_fx_png.vtex",
		[9] = "s2r://panorama/images/compendium/international2019/prestigerewards/bottle_fx_png.vtex",
	},
	high_five = {
		[9] = "s2r://panorama/images/compendium/international2019/prestigerewards/high_five_lvl_1_png.vtex",
		[10] = "s2r://panorama/images/compendium/international2020/prestigerewards/high_five_lvl_2_png.vtex",
	},
	emblem = {
		[10] = "s2r://panorama/images/compendium/international2020/prestigerewards/scepter_lv2_png.vtex",
		[11] = "s2r://panorama/images/compendium/international2022/prestigerewards/scepter_lv2_png.vtex",
	},
	shadow_kill = {
		[7] = "s2r://panorama/images/econ/items/shadow_demon/ti7_immortal_back/sd_ti7_immortal_back_png.vtex",
	},
	shadow_kill_gold = {
		[7] = "s2r://panorama/images/econ/items/shadow_demon/ti7_immortal_back/sd_ti7_immortal_back1_png.vtex",
	},
}

local LEGACY_LEVELUP_TI = {
	battlepass_levelup1 = 6,
	battlepass_levelup2 = 7,
	battlepass_levelup3 = 8,
	battlepass_levelup4 = 9,
	battlepass_levelup5 = 10,
}

local function ResolveVanillaTIRewardImage(item)
	if type(item) ~= "table" then return nil end

	local itemName = string.lower(tostring(item.item_name or item.name or ""))
	local kind = table.concat({
		string.lower(tostring(item.item_type or "")),
		string.lower(tostring(item.type or "")),
		string.lower(tostring(item.slot_id or "")),
		string.lower(tostring(item.category or "")),
		itemName,
		string.lower(tostring(item.display_name or item.title or "")),
	}, " ")
	local imageKind = nil
	if string.find(kind, "levelup", 1, true) or string.find(kind, "ascension", 1, true) then
		imageKind = "levelup"
	elseif string.find(kind, "immolation", 1, true) or string.find(kind, "radiance", 1, true) then
		imageKind = "radiance"
	elseif string.find(kind, "shadow poison", 1, true) or string.find(kind, "shadow_poison", 1, true) then
		imageKind = (string.find(kind, "gold", 1, true) or string.find(kind, "golden", 1, true)) and "shadow_kill_gold" or "shadow_kill"
	elseif string.find(kind, "teleport", 1, true) or string.find(kind, "tp_fx", 1, true) then
		imageKind = "teleport"
	elseif string.find(kind, "regen_aura", 1, true) or string.find(kind, "fountain", 1, true) then
		imageKind = "fountain"
	elseif string.find(kind, "potion", 1, true) or string.find(kind, "bottle", 1, true) then
		imageKind = "bottle"
	elseif string.find(kind, "high_five", 1, true) or string.find(kind, "high five", 1, true) then
		imageKind = "high_five"
	elseif string.find(kind, "emblem", 1, true) or string.find(kind, "aghanim_aura", 1, true) or string.find(kind, "scepter", 1, true) then
		imageKind = "emblem"
	end
	if imageKind == nil then return nil end

	local ti = imageKind == "levelup" and LEGACY_LEVELUP_TI[itemName] or nil
	local evidence = table.concat({
		itemName,
		string.lower(tostring(item.ti_edition or item.edition or "")),
		string.lower(tostring(item.display_name or item.title or "")),
		string.lower(tostring(item.family or "")),
		string.lower(tostring(item.asset_path or "")),
		string.lower(tostring(item.pfx or item.particle or "")),
		string.lower(tostring(item.owner_pfx or "")),
		string.lower(tostring(item.target_pfx or "")),
	}, " ")
	if ti == nil then
		ti = tonumber(string.match(evidence, "ti(%d+)"))
	end
	if ti == nil then
		local internationalYear = tonumber(string.match(evidence, "international(20%d%d)"))
		if internationalYear ~= nil and internationalYear >= 2016 and internationalYear <= 2020 then
			ti = internationalYear - 2010
		end
	end

	return VANILLA_TI_REWARD_IMAGES[imageKind][ti]
end

local function IsSupporterDisplayImage(value)
	if value == nil then return false end
	local path = string.lower(tostring(value)):gsub("\\", "/")
	return path ~= ""
		and string.find(path, ".vpcf", 1, true) == nil
		and string.sub(path, 1, 10) ~= "particles/"
end

local function ResolveSupporterDisplayImage(item)
	local tiImage = ResolveVanillaTIRewardImage(item)
	if tiImage ~= nil then return tiImage end
	if type(item) ~= "table" then return nil end

	for _, key in ipairs({ "preview_image", "image_url", "image", "image_inventory", "icon", "icon_path" }) do
		local value = item[key]
		if IsSupporterDisplayImage(value) then
			local image = tostring(value):gsub("\\", "/")
			local cdnFilename = string.match(image, "^https?://cdn%.frostrose%-studio%.com/static/images/battlepass/xhs%-4%.0/([^/?#]+)")
			if cdnFilename ~= nil then
				local localName = cdnFilename:gsub("%.[^%.]+$", ""):gsub("%-", "_")
				return "custom_game/battlepass/" .. localName
			end
			if string.sub(image, 1, 11) == "battlepass/" then
				return "custom_game/" .. image
			end
			return image
		end
	end
	return nil
end

local function ApplyVanillaTIRewardImage(item)
	local image = ResolveSupporterDisplayImage(item)
	item.image = image
	item.image_inventory = image
	return item
end

local function IsSupporterShopItem(value)
	return type(value) == "table" and (
		value.item_id ~= nil
		or value.catalog_item_id ~= nil
		or (
			value.id ~= nil
			and (
				value.name ~= nil
				or value.type ~= nil
				or value.item_type ~= nil
				or value.price ~= nil
				or value.price_fragments ~= nil
			)
		)
	)
end

local function AddSupporterShopItem(result, seen, value)
	if not IsSupporterShopItem(value) then return end
	local identity = value.item_id
		or value.catalog_item_id
		or value.id
	local key = tostring(identity or "")
	if key == "" then
		key = tostring(value)
	end
	if seen[key] then return end
	seen[key] = true
	table.insert(result, value)
end

local function CollectSupporterShopSection(result, seen, section)
	if type(section) ~= "table" then return end
	if IsSupporterShopItem(section) then
		AddSupporterShopItem(result, seen, section)
		return
	end

	local list = section.items
	if type(list) ~= "table" and #section > 0 then list = section end
	for _, item in ipairs(type(list) == "table" and list or {}) do
		AddSupporterShopItem(result, seen, item)
	end

	for _, field in ipairs({ "item", "primary", "secondary", "secondary_items" }) do
		local nested = section[field]
		if type(nested) == "table" then
			if IsSupporterShopItem(nested) then
				AddSupporterShopItem(result, seen, nested)
			else
				for _, item in ipairs(nested) do
					AddSupporterShopItem(result, seen, item)
				end
			end
		end
	end
end

local function NormalizeSupporterShopSection(source, fallbackItems)
	local section = CopySupporterTable(source)
	if type(source) == "table" and #source > 0 and source.items == nil then
		section = { items = source }
	end
	if type(section.items) ~= "table" then
		section.items = type(fallbackItems) == "table" and fallbackItems or {}
	end
	return section
end

local function SupporterShopItemIdentity(value)
	if type(value) ~= "table" then
		local identity = tostring(value or "")
		return identity ~= "" and identity or nil
	end
	local identity = value.item_id or value.catalog_item_id or value.id
	if identity == nil or tostring(identity) == "" then return nil end
	return tostring(identity)
end

local function AddSupporterShopReference(result, seen, value)
	local identity = SupporterShopItemIdentity(value)
	if identity == nil or seen[identity] then return end
	seen[identity] = true
	table.insert(result, identity)
end

local function IsNonEmptySupporterShopValue(value)
	return value ~= nil and tostring(value) ~= ""
end

local function IsExplicitSupporterShopFalse(value)
	if value == false or value == 0 then return true end
	local normalized = string.lower(tostring(value or ""))
	return normalized == "false" or normalized == "0"
end

local function NormalizePublishedSupporterShopComponent(source, parent, depth)
	local component = CopySupporterTable(source)
	if type(source) ~= "table" then return component end
	ApplyVanillaTIRewardImage(component)
	depth = tonumber(depth) or 0

	-- Bundle children are not necessarily published as standalone listings. Keep
	-- their own explicit catalogue flags, plus an immutable proof of the
	-- published parent listing that made them visible in this release.
	component.parent_item_id = parent.item_id
	component.parent_active = parent.active == true
	component.parent_is_published = parent.is_published == true
	component.parent_release_id = parent.release_id
	component.parent_release_status = parent.release_status

	if depth < 4 and type(source.components) == "table" then
		component.components = {}
		for _, child in ipairs(source.components) do
			table.insert(
				component.components,
				NormalizePublishedSupporterShopComponent(child, parent, depth + 1)
			)
		end
	end
	return component
end

local function NormalizePublishedSupporterShopItems(sourceItems, releaseID)
	local result = {}
	local releasePublished = IsNonEmptySupporterShopValue(releaseID)
	for _, source in ipairs(type(sourceItems) == "table" and sourceItems or {}) do
		if type(source) == "table" then
			local item = CopySupporterTable(source)
			ApplyVanillaTIRewardImage(item)
			local itemID = SupporterShopItemIdentity(item)
			if releasePublished and itemID ~= nil then
				-- getShop only returns rows from the published release where the
				-- listing and catalogue item are active and published. The backend
				-- omits those redundant flags on root listings, so make the proof
				-- explicit before publishing the game nettable.
				item.active = not IsExplicitSupporterShopFalse(source.active)
				item.is_published = not IsExplicitSupporterShopFalse(source.is_published)
				item.publication_status = "published"
				item.release_id = tostring(releaseID)
			end

			if type(source.components) == "table" then
				item.components = {}
				local parent = {
					item_id = itemID,
					active = item.active == true,
					is_published = item.is_published == true,
					release_id = releasePublished and tostring(releaseID) or nil,
					release_status = releasePublished and "published" or "unavailable",
				}
				for _, component in ipairs(source.components) do
					table.insert(
						item.components,
						NormalizePublishedSupporterShopComponent(component, parent, 0)
					)
				end
			end
			table.insert(result, item)
		end
	end
	return result
end

local function BuildNamedSupporterShopSections(shop, rawSections, rootItems)
	local isDefinitionList = type(rawSections) == "table" and #rawSections > 0
	local named = isDefinitionList and { definitions = rawSections } or CopySupporterTable(rawSections)
	local heroReferences = {}
	local featuredReferences = {}
	local catalogReferences = {}
	local seenHero = {}
	local seenFeatured = {}
	local seenCatalog = {}
	local featuredDefinition = nil

	for _, definition in ipairs(isDefinitionList and rawSections or {}) do
		local sectionID = string.lower(tostring(
			definition.section_id or definition.id or definition.key or ""
		))
		if sectionID == "featured" or sectionID == "hero" then
			featuredDefinition = definition
		end
	end

	for _, item in ipairs(rootItems) do
		AddSupporterShopReference(catalogReferences, seenCatalog, item)
		local rank = tonumber(item.featured_rank)
		local sectionID = string.lower(tostring(item.section_id or item.section or ""))
		if rank == 1 and #heroReferences == 0 then
			AddSupporterShopReference(heroReferences, seenHero, item)
		elseif rank ~= nil and rank > 0 then
			AddSupporterShopReference(featuredReferences, seenFeatured, item)
		elseif sectionID == "hero" and #heroReferences == 0 then
			AddSupporterShopReference(heroReferences, seenHero, item)
		elseif sectionID == "featured" then
			AddSupporterShopReference(featuredReferences, seenFeatured, item)
		end
	end

	for _, itemID in ipairs(type(featuredDefinition) == "table"
		and type(featuredDefinition.item_ids) == "table"
		and featuredDefinition.item_ids
		or {}) do
		local identity = SupporterShopItemIdentity(itemID)
		if identity ~= nil and seenHero[identity] then
			-- The rank-1 item is already the large hero card.
		elseif #heroReferences == 0 then
			AddSupporterShopReference(heroReferences, seenHero, itemID)
		else
			AddSupporterShopReference(featuredReferences, seenFeatured, itemID)
		end
	end
	if #heroReferences == 0 and #featuredReferences > 0 then
		local firstFeatured = table.remove(featuredReferences, 1)
		seenFeatured[firstFeatured] = nil
		AddSupporterShopReference(heroReferences, seenHero, firstFeatured)
	end
	if #heroReferences == 0 and #catalogReferences > 0 then
		AddSupporterShopReference(heroReferences, seenHero, catalogReferences[1])
	end

	named.hero = NormalizeSupporterShopSection(
		named.hero or shop.hero,
		heroReferences
	)
	named.featured = NormalizeSupporterShopSection(
		named.featured or shop.featured,
		featuredReferences
	)
	named.catalog = NormalizeSupporterShopSection(
		named.catalog or shop.permanent or shop.catalog,
		catalogReferences
	)
	return named
end

local function BuildPublishedSupporterShop(source)
	local shop = type(source) == "table" and source or {}
	local rawSections = type(shop.sections) == "table" and shop.sections or {}
	local rootItems = NormalizePublishedSupporterShopItems(shop.items, shop.release_id)
	local sections = BuildNamedSupporterShopSections(shop, rawSections, rootItems)

	local permanent = NormalizeSupporterShopSection(
		shop.permanent or rawSections.catalog or shop.catalog,
		rootItems
	)
	local rotation = NormalizeSupporterShopSection(shop.rotation, {})
	local items = {}
	local seen = {}
	CollectSupporterShopSection(items, seen, rootItems)
	CollectSupporterShopSection(items, seen, sections.hero)
	CollectSupporterShopSection(items, seen, sections.featured)
	CollectSupporterShopSection(items, seen, sections.catalog)
	CollectSupporterShopSection(items, seen, permanent)
	CollectSupporterShopSection(items, seen, rotation)

	local published = CopySupporterTable(shop)
	published.schema_version = tonumber(shop.schema_version) or 2
	published.version = shop.version or published.schema_version
	published.release_id = shop.release_id
	published.release_status = IsNonEmptySupporterShopValue(shop.release_id)
		and "published"
		or "unavailable"
	published.sections = sections
	published.section_definitions = #rawSections > 0 and rawSections or shop.section_definitions
	published.permanent = permanent
	published.rotation = rotation
	published.items = items
	return published
end

local function BuildPublishedSupporterLoadout(items)
	local published = {}
	for _, item in ipairs(type(items) == "table" and items or {}) do
		if type(item) == "table" then
			local resolvedImage = ResolveSupporterDisplayImage(item)
			local entry = {
				id = item.id or item.item_id or item.catalog_item_id,
				item_id = item.item_id or item.catalog_item_id or item.id,
				catalog_item_id = item.catalog_item_id or item.item_id or item.id,
				name = item.name or item.item_name,
				item_name = item.item_name or item.name,
				type = item.type or item.item_type or item.slot_id,
				item_type = item.item_type or item.type or item.slot_id,
				slot_id = item.slot_id or item.item_type or item.type,
				rarity = item.rarity or item.item_rarity,
				item_rarity = item.item_rarity or item.rarity,
				image = resolvedImage,
				image_inventory = resolvedImage,
				asset_path = item.asset_path,
				effect_paths = item.effect_paths,
				equip = item.equip,
				equip_rules = item.equip_rules,
				runtime = item.runtime,
				runtime_assets = item.runtime_assets,
				visuals = item.visuals,
				unit = item.unit or item.unit_name or item.file,
				particle = item.particle,
			}
			for _, field in ipairs({
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
				entry[field] = item[field]
			end
			table.insert(published, entry)
		end
	end
	return published
end

local function GetBackendSeasonRecord(supporterPass)
	local playerSeason = type(supporterPass) == "table"
		and supporterPass.season
		or nil
	if type(playerSeason) == "table" and next(playerSeason) ~= nil then
		return playerSeason
	end
	if playerSeason ~= nil and tostring(playerSeason) ~= "" then
		return playerSeason
	end

	local globalSeason = api
		and api.supporter_pass
		and api.supporter_pass.season
		or nil
	return globalSeason
end

local function IsBackendSeasonReady(supporterPass)
	local seasonRecord = GetBackendSeasonRecord(supporterPass)
	local identity = type(seasonRecord) == "table"
		and (
			seasonRecord.season_id
			or seasonRecord.season_key
			or seasonRecord.key
			or seasonRecord.id
		)
		or seasonRecord
	if SupporterPass2026 ~= nil
	and SupporterPass2026.IsBackendSeason2026 ~= nil then
		local seasonMatches =
			SupporterPass2026:IsBackendSeason2026(seasonRecord)
		local globalSeason = api
			and api.supporter_pass
			and api.supporter_pass.season
			or nil
		local globalSeasonMatches =
			SupporterPass2026:IsBackendSeason2026(globalSeason)
		local seasonPublished =
			SupporterPass2026.IsBackendSeasonPublished == nil
			or SupporterPass2026:IsBackendSeasonPublished(
				seasonRecord
			) ~= false
		local globalSeasonPublished =
			SupporterPass2026.IsBackendSeasonPublished == nil
			or SupporterPass2026:IsBackendSeasonPublished(
				globalSeason
			) ~= false
		local catalogReady = SupporterPass2026.IsBackendCatalog2026Ready ~= nil
			and SupporterPass2026:IsBackendCatalog2026Ready(
				api and api.supporter_pass and api.supporter_pass.rewards
			)
			or nil
		return seasonMatches ~= false
			and globalSeasonMatches ~= false
			and seasonPublished
			and globalSeasonPublished
			and catalogReady == true,
			identity
	end
	return false, identity
end

local function RewardIdentity(reward, index, sourceName)
	if type(reward) ~= "table" then
		return sourceName .. ":" .. tostring(index)
	end

	local itemID = reward.item_id or reward.catalog_item_id
	if itemID ~= nil and tostring(itemID) ~= "" then
		local itemType = string.lower(tostring(reward.type or reward.item_type or reward.slot_id or "default"))
		return "item:" .. itemType .. ":" .. tostring(itemID)
	end

	local rewardID = reward.reward_id or reward.id
	if rewardID ~= nil and tostring(rewardID) ~= "" then
		return "reward:" .. tostring(rewardID)
	end

	return sourceName .. ":" .. tostring(index)
end

local function IsSupporterRewardRecord(value)
	return type(value) == "table" and (
		value.reward_id ~= nil
		or value.item_id ~= nil
		or value.catalog_item_id ~= nil
		or value.item_type ~= nil
		or value.type ~= nil
		or (value.id ~= nil and (value.name ~= nil or value.track ~= nil or value.level ~= nil or value.level_required ~= nil))
	)
end

local function CollectSupporterRewards(value, forcedTrack, result)
	result = result or {}
	if type(value) ~= "table" then return result end

	if IsSupporterRewardRecord(value) then
		local reward = CopySupporterTable(value)
		ApplyVanillaTIRewardImage(reward)
		reward.track = reward.track or forcedTrack
		table.insert(result, reward)
		return result
	end

	if value.rewards ~= nil then
		CollectSupporterRewards(value.rewards, forcedTrack, result)
	end
	if value.free ~= nil then
		CollectSupporterRewards(value.free, "free", result)
	end
	if value.premium ~= nil then
		CollectSupporterRewards(value.premium, "premium", result)
	end

	local numericKeys = {}
	for key, nested in pairs(value) do
		if tonumber(key) ~= nil and type(nested) == "table" then
			table.insert(numericKeys, tonumber(key))
		end
	end
	table.sort(numericKeys)
	for _, numericKey in ipairs(numericKeys) do
		local nested = value[numericKey] or value[tostring(numericKey)]
		CollectSupporterRewards(nested, forcedTrack, result)
	end

	if #numericKeys == 0 and value.rewards == nil and value.free == nil and value.premium == nil then
		for _, nested in pairs(value) do
			if type(nested) == "table" then
				CollectSupporterRewards(nested, forcedTrack, result)
			end
		end
	end

	return result
end

local function MergeRewardTracks(legacyRewards, backendRewards, track)
	if SupporterPass2026 ~= nil and SupporterPass2026.MergeBackendTrack ~= nil then
		return SupporterPass2026:MergeBackendTrack(
			legacyRewards,
			CollectSupporterRewards(backendRewards),
			track
		)
	end

	local merged = {}
	local order = {}

	for index, reward in ipairs(legacyRewards or {}) do
		local normalized = CopySupporterTable(reward)
		ApplyVanillaTIRewardImage(normalized)
		normalized.track = track
		normalized.legacy = true
		normalized.claimable = false
		local key = RewardIdentity(normalized, index, "legacy")
		merged[key] = normalized
		table.insert(order, key)
	end

	for index, reward in ipairs(CollectSupporterRewards(backendRewards)) do
		if type(reward) == "table" and (reward.track or "free") == track then
			local normalized = CopySupporterTable(reward)
			ApplyVanillaTIRewardImage(normalized)
			normalized.track = track
			normalized.legacy = false
			local key = RewardIdentity(normalized, index, "backend")
			if merged[key] == nil then
				table.insert(order, key)
			else
				for field, value in pairs(merged[key]) do
					if normalized[field] == nil then
						normalized[field] = value
					end
				end
			end
			merged[key] = normalized
		end
	end

	local rewards = {}
	for _, key in ipairs(order) do
		table.insert(rewards, merged[key])
	end
	table.sort(rewards, function(a, b)
		return (tonumber(a.level_required or a.level) or 0) < (tonumber(b.level_required or b.level) or 0)
	end)
	return rewards
end

local function IsEarthwardenSupporterValue(tierName, tierColor, donatorStatus)
	local status = tonumber(donatorStatus) or 0
	if status == 8 or status == 9 then
		return true
	end

	local normalizedName = string.lower(tostring(tierName or ""))
	if string.find(normalizedName, "earthwarden", 1, true) ~= nil then
		return true
	end

	return string.lower(tostring(tierColor or "")) == "#c99cff"
end

local function NormalizeSeasonProgress(level, xp, xpMax)
	level = math.max(tonumber(level) or 1, 1)
	xp = math.max(tonumber(xp) or 0, 0)
	xpMax = math.max(tonumber(xpMax) or SupporterPass.SEASON_XP_PER_LEVEL, 1)

	local totalXP = xp
	if xp >= xpMax then
		local completedLevels = math.floor(xp / xpMax)
		xp = xp - completedLevels * xpMax
		level = math.max(level, 1 + completedLevels)
	end

	return level, xp, xpMax, totalXP
end

local function SeasonProgressTotal(level, xp, xpMax)
	level = math.max(tonumber(level) or 1, 1)
	xp = math.max(tonumber(xp) or 0, 0)
	xpMax = math.max(tonumber(xpMax) or SupporterPass.SEASON_XP_PER_LEVEL, 1)
	return ((level - 1) * xpMax) + xp
end

SupporterPass.TIERS = {
	[1] = {
		id = 1,
		name = "Donator",
		price = "$2",
		color = "#45C46B",
		fragments = 150,
		daily_gameplay_fragments = 125,
		xp_boost = 10,
		vote_power = 2,
		companion_unlocks = 3,
		emblem_unlocks = 1,
		effigy_unlocks = 1,
	},
	[2] = {
		id = 2,
		name = "Golden Donator",
		price = "$5",
		color = "#F2C94C",
		fragments = 400,
		daily_gameplay_fragments = 150,
		xp_boost = 20,
		vote_power = 3,
		companion_unlocks = 3,
		emblem_unlocks = 1,
		effigy_unlocks = 1,
	},
	[3] = {
		id = 3,
		name = "Ember Donator",
		price = "$10",
		color = "#E4572E",
		fragments = 900,
		daily_gameplay_fragments = 175,
		xp_boost = 30,
		vote_power = 4,
		companion_unlocks = 3,
		emblem_unlocks = 1,
		effigy_unlocks = 1,
	},
	[4] = {
		id = 4,
		name = "Stoneguard Donator",
		price = "$20",
		color = "#5AD0FF",
		fragments = 1800,
		daily_gameplay_fragments = 200,
		xp_boost = 40,
		vote_power = 5,
		companion_unlocks = 3,
		emblem_unlocks = 1,
		effigy_unlocks = 1,
	},
	[5] = {
		id = 5,
		name = "Earthwarden Donator",
		price = "$50",
		color = "#C99CFF",
		fragments = 1800,
		daily_gameplay_fragments = 200,
		xp_boost = 40,
		vote_power = 5,
		companion_unlocks = 3,
		emblem_unlocks = 1,
		effigy_unlocks = 1,
		prestige = true,
	},
}

SupporterPass.STATUS_TO_TIER = DONATOR_STATUS_TO_TIER or {}

function SupporterPass:Init()
	self:PublishMeta()
	self:PublishFeaturedShop()
end

function SupporterPass:GetTierByID(tierID)
	return self.TIERS[tonumber(tierID) or 0]
end

function SupporterPass:GetTierForStatus(status)
	if GetDonatorVisualTier ~= nil then
		return GetDonatorVisualTier(status)
	end

	return self.STATUS_TO_TIER[tonumber(status) or 0] or 0
end

function SupporterPass:GetTierForPlayer(playerID)
	if api and api.GetPlayerSupporterTier then
		return api:GetPlayerSupporterTier(playerID)
	end

	if api and api.GetDonatorStatus then
		return self:GetTierForStatus(api:GetDonatorStatus(playerID))
	end

	return 0
end

function SupporterPass:GetTierName(tierID)
	local tier = self:GetTierByID(tierID)
	return tier and tier.name or "Free Player"
end

function SupporterPass:GetTierColor(tierID)
	local tier = self:GetTierByID(tierID)
	return tier and tier.color or "#7DB9D8"
end

function SupporterPass:PublishMeta()
	CustomNetTables:SetTableValue("supporter_pass_meta", "tiers", self.TIERS)
	if BuildDonatorColorMeta ~= nil then
		CustomNetTables:SetTableValue("game_options", "donator_colors", BuildDonatorColorMeta(self.TIERS))
	end
	CustomNetTables:SetTableValue("supporter_pass_meta", "economy", {
		season_length_months = 3,
		daily_fragment_cap = self.DAILY_FRAGMENT_CAP,
		daily_gameplay_fragment_cap = self.DAILY_GAMEPLAY_FRAGMENT_CAP,
		daily_quest_fragment_cap = self.DAILY_QUEST_FRAGMENT_CAP,
		weekly_fragment_cap = self.DAILY_FRAGMENT_CAP,
	})
end

local SUPPORTER_SHOP_CHUNK_TARGET_BYTES = 45000
local SUPPORTER_SHOP_SECTION_ITEM_FIELDS = {
	"items",
	"item_ids",
	"item",
	"primary",
	"secondary",
	"secondary_items",
}

local function EstimateSupporterShopPayloadBytes(value, depth, visited)
	local valueType = type(value)
	if valueType == "nil" then return 4 end
	if valueType == "boolean" then return value and 4 or 5 end
	if valueType == "number" then return 24 end
	if valueType == "string" then return #value + 2 end
	if valueType ~= "table" then return #tostring(value) + 2 end

	depth = tonumber(depth) or 0
	if depth > 12 then return 16 end
	visited = visited or {}
	if visited[value] then return 4 end
	visited[value] = true

	local size = 2
	for key, child in pairs(value) do
		size = size + #tostring(key) + 4
			+ EstimateSupporterShopPayloadBytes(child, depth + 1, visited)
	end
	visited[value] = nil
	return size
end

local function BuildSupporterShopReferenceList(value)
	local references = {}
	local seen = {}
	if type(value) ~= "table" then
		AddSupporterShopReference(references, seen, value)
		return references
	end
	if IsSupporterShopItem(value) then
		AddSupporterShopReference(references, seen, value)
		return references
	end

	local list = value.items
	if type(list) ~= "table" then
		list = value
	end
	for _, item in ipairs(list) do
		AddSupporterShopReference(references, seen, item)
	end
	return references
end

local function CompactSupporterShopSection(section)
	if type(section) ~= "table" then return section end
	if IsSupporterShopItem(section) then
		return SupporterShopItemIdentity(section)
	end
	local compact = CopySupporterTable(section)
	for _, field in ipairs(SUPPORTER_SHOP_SECTION_ITEM_FIELDS) do
		if section[field] ~= nil then
			local references = BuildSupporterShopReferenceList(section[field])
			if field == "item" or field == "primary" then
				compact[field] = references[1]
			else
				compact[field] = references
			end
		end
	end
	if #section > 0 and section.items == nil then
		compact = { items = BuildSupporterShopReferenceList(section) }
	end
	return compact
end

local function CompactSupporterShopSections(sections)
	local compact = {}
	for key, section in pairs(type(sections) == "table" and sections or {}) do
		if key == "definitions" and type(section) == "table" then
			compact[key] = {}
			for index, definition in ipairs(section) do
				compact[key][index] = CompactSupporterShopSection(definition)
			end
		else
			compact[key] = CompactSupporterShopSection(section)
		end
	end
	return compact
end

local function CompactSupporterShopDefinitions(definitions)
	local compact = {}
	for index, definition in ipairs(type(definitions) == "table" and definitions or {}) do
		compact[index] = CompactSupporterShopSection(definition)
	end
	return compact
end

local function BuildSupporterShopChunks(items, generation)
	local chunks = {}
	local current = { generation = generation, items = {} }
	local currentSize = EstimateSupporterShopPayloadBytes(current)
	for _, item in ipairs(type(items) == "table" and items or {}) do
		local itemSize = EstimateSupporterShopPayloadBytes(item)
		if #current.items > 0
		and currentSize + itemSize > SUPPORTER_SHOP_CHUNK_TARGET_BYTES then
			table.insert(chunks, current)
			current = { generation = generation, items = {} }
			currentSize = EstimateSupporterShopPayloadBytes(current)
		end
		table.insert(current.items, item)
		currentSize = currentSize + itemSize
	end
	if #current.items > 0 then
		table.insert(chunks, current)
	end
	return chunks
end

local function BuildSupporterShopTransportManifest(shop, generation, chunkCount)
	local manifest = {}
	local transportedFields = {
		items = true,
		sections = true,
		section_definitions = true,
		permanent = true,
		rotation = true,
		hero = true,
		featured = true,
		catalog = true,
		catalog_items = true,
		permanent_items = true,
		featured_items = true,
	}
	for key, value in pairs(type(shop) == "table" and shop or {}) do
		if not transportedFields[key] and type(value) ~= "table" then
			manifest[key] = value
		end
	end
	manifest.transport_version = 2
	manifest.transport_generation = generation
	manifest.item_chunk_count = chunkCount
	manifest.item_count = #(type(shop.items) == "table" and shop.items or {})
	manifest.sections = CompactSupporterShopSections(shop.sections)
	manifest.section_definitions = CompactSupporterShopDefinitions(shop.section_definitions)
	manifest.permanent = CompactSupporterShopSection(shop.permanent)
	manifest.rotation = CompactSupporterShopSection(shop.rotation)
	manifest.hero = CompactSupporterShopSection(shop.hero)
	manifest.featured = CompactSupporterShopSection(shop.featured)
	manifest.catalog = CompactSupporterShopSection(shop.catalog)
	manifest.catalog_items = BuildSupporterShopReferenceList(shop.catalog_items)
	manifest.permanent_items = BuildSupporterShopReferenceList(shop.permanent_items)
	manifest.featured_items = BuildSupporterShopReferenceList(shop.featured_items)
	return manifest
end

function SupporterPass:PublishFeaturedShop()
	local source = api
		and api.supporter_pass
		and api.supporter_pass.shop
		or { items = {} }
	local shop = BuildPublishedSupporterShop(source)
	self.PublishedShop = shop
	self.PublishedShopGeneration = (tonumber(self.PublishedShopGeneration) or 0) + 1
	local generation = self.PublishedShopGeneration
	local chunks = BuildSupporterShopChunks(shop.items, generation)
	local manifest = BuildSupporterShopTransportManifest(shop, generation, #chunks)
	local legacyFeatured = CopySupporterTable(shop.sections.featured)
	legacyFeatured = CompactSupporterShopSection(legacyFeatured)
	legacyFeatured.release_id = shop.release_id
	legacyFeatured.version = shop.version
	legacyFeatured.schema_version = shop.schema_version
	legacyFeatured.refresh_label = legacyFeatured.refresh_label
		or shop.refresh_label
	legacyFeatured.rotation_id = legacyFeatured.rotation_id
		or shop.rotation_id
	legacyFeatured.season_id = legacyFeatured.season_id
		or shop.season_id

	for index, chunk in ipairs(chunks) do
		chunk.index = index
		chunk.count = #chunks
		CustomNetTables:SetTableValue(
			"supporter_pass_shop",
			"items_" .. tostring(index),
			chunk
		)
	end
	for staleIndex = #chunks + 1, tonumber(self.PublishedShopChunkCount) or 0 do
		CustomNetTables:SetTableValue(
			"supporter_pass_shop",
			"items_" .. tostring(staleIndex),
			{}
		)
	end
	self.PublishedShopChunkCount = #chunks

	CustomNetTables:SetTableValue("supporter_pass_shop", "permanent", manifest.permanent)
	CustomNetTables:SetTableValue("supporter_pass_shop", "rotation", manifest.rotation)
	CustomNetTables:SetTableValue("supporter_pass_shop", "hero", manifest.sections.hero)
	CustomNetTables:SetTableValue("supporter_pass_shop", "featured", legacyFeatured)
	CustomNetTables:SetTableValue("supporter_pass_shop", "meta", {
		release_id = shop.release_id,
		version = shop.version,
		schema_version = shop.schema_version,
		transport_version = 2,
		transport_generation = generation,
		item_chunk_count = #chunks,
	})
	-- Publish the manifest last. Panorama treats this key as the atomic switch
	-- after every chunk for the new generation is already available.
	CustomNetTables:SetTableValue("supporter_pass_shop", "catalog", manifest)
end

function SupporterPass:BuildPlayerTable(playerID)
	if not PlayerResource:IsValidPlayerID(playerID) then
		return nil
	end

	local steamID = tostring(PlayerResource:GetSteamID(playerID))
	local current = CustomNetTables:GetTableValue("supporter_pass_player", tostring(playerID)) or {}
	local player = api and api.players and api.players[steamID] or {}
	local supporterPass = player.supporter_pass or {}
	local backendSeasonReady, backendSeasonID = IsBackendSeasonReady(supporterPass)
	local seasonStateAllowed = backendSeasonReady ~= false
	local season = seasonStateAllowed and (supporterPass.season or {}) or {}
	local seasonSupporterPass = seasonStateAllowed and supporterPass or {}
	local seasonCurrent = seasonStateAllowed and current or {}
	local account = supporterPass.account or {}
	local settings = supporterPass.settings or player.settings or {}
	local passTierID = tonumber(FirstSupporterValue(supporterPass.tier_id, current.tier_id)) or 0
	local rawDonatorStatus = api and api.GetDonatorStatus and api:GetDonatorStatus(playerID) or 0
	local isDeveloper = IsInToolsMode()
		and api ~= nil
		and api.IsDeveloper ~= nil
		and api:IsDeveloper(playerID)
	local donatorStatus = GetDonatorVisualStatus ~= nil and GetDonatorVisualStatus(rawDonatorStatus) or rawDonatorStatus
	local rawTierName = FirstSupporterValue(supporterPass.tier_name, current.tier_name)
	local rawTierColor = FirstSupporterValue(supporterPass.tier_color, current.tier_color)
	local botTierID = api and api.GetBotSupporterTier and api:GetBotSupporterTier(playerID) or 0
	if botTierID > 0 then
		passTierID = botTierID
		rawTierName = nil
		rawTierColor = nil
	end
	local statusTierID = botTierID > 0 and botTierID or self:GetTierForStatus(donatorStatus)

	if IsEarthwardenSupporterValue(rawTierName, rawTierColor, donatorStatus) then
		passTierID = math.max(passTierID, 5)
	end

	local tierID = math.max(passTierID, statusTierID)
	local tier = self:GetTierByID(tierID)
	local tierName = FirstSupporterValue(rawTierName, self:GetTierName(tierID))
	local tierColor = FirstSupporterValue(rawTierColor, self:GetTierColor(tierID))
	if IsEarthwardenSupporterValue(tierName, tierColor, donatorStatus) then
		tierID = math.max(tierID, 5)
		tier = self:GetTierByID(tierID)
		tierName = self:GetTierName(tierID)
		tierColor = self:GetTierColor(tierID)
	end
	local accountLevel = tonumber(FirstSupporterValue(account.level, player.account_level, player.xp_level, supporterPass.account_level, current.account_level)) or 0
	local xhsAccountLevel = tonumber(current.xhs_account_level) or 0
	if player.xp_level ~= nil then
		xhsAccountLevel = math.max((tonumber(player.xp_level) or 0) + 1, 1)
	end
	local xhsXP = tonumber(FirstSupporterValue(player.xp, current.xhs_xp)) or 0
	local xhsXPCurrent = tonumber(FirstSupporterValue(player.xp_in_level, current.xhs_xp_current)) or 0
	local xhsXPMax = tonumber(FirstSupporterValue(player.xp_next_level, current.xhs_xp_max)) or 0
	local seasonLevel = math.max(tonumber(FirstSupporterValue(season.level, seasonSupporterPass.season_level, seasonSupporterPass.level, seasonCurrent.season_level, seasonCurrent.Lvl)) or 1, 1)
	local seasonXP = tonumber(FirstSupporterValue(season.xp, seasonSupporterPass.season_xp, seasonSupporterPass.current_exp, seasonCurrent.season_xp, seasonCurrent.XP)) or 0
	local seasonXPMax = tonumber(FirstSupporterValue(season.xp_per_level, seasonSupporterPass.season_xp_max, seasonSupporterPass.xp_per_level, seasonCurrent.season_xp_max, seasonCurrent.MaxXP)) or self.SEASON_XP_PER_LEVEL
	local seasonTotalXP = seasonXP
	seasonLevel, seasonXP, seasonXPMax, seasonTotalXP = NormalizeSeasonProgress(seasonLevel, seasonXP, seasonXPMax)
	local explicitSeasonXPChange = tonumber(FirstSupporterValue(
		season.xp_change,
		season.gained_xp,
		seasonSupporterPass.season_xp_change,
		seasonSupporterPass.xp_change,
		seasonSupporterPass.gained_xp,
		seasonStateAllowed and player.supporter_pass_xp_change or nil,
		seasonStateAllowed and player.supporter_xp_change or nil
	))
	local seasonXPChange = explicitSeasonXPChange or 0
	if explicitSeasonXPChange == nil and (seasonCurrent.steamid ~= nil or seasonCurrent.season_xp ~= nil or seasonCurrent.XP ~= nil) then
		local currentLevel = tonumber(FirstSupporterValue(seasonCurrent.season_level, seasonCurrent.Lvl)) or 1
		local currentXP = tonumber(FirstSupporterValue(seasonCurrent.season_xp, seasonCurrent.XP)) or 0
		local currentXPMax = tonumber(FirstSupporterValue(seasonCurrent.season_xp_max, seasonCurrent.MaxXP)) or seasonXPMax
		seasonXPChange = SeasonProgressTotal(seasonLevel, seasonXP, seasonXPMax) - SeasonProgressTotal(currentLevel, currentXP, currentXPMax)
	end
	local baseXPChange = tonumber(FirstSupporterValue(season.base_xp_change, seasonSupporterPass.base_xp_change, seasonStateAllowed and player.base_xp_change or nil, seasonCurrent.base_xp_change)) or 0
	local xpBonus = tonumber(FirstSupporterValue(season.xp_bonus, seasonSupporterPass.xp_bonus, seasonStateAllowed and player.xp_bonus or nil, seasonCurrent.xp_bonus)) or 0
	local passRewards = FirstSupporterValue(settings.pass_rewards, player.pass_rewards)
	if passRewards == nil then
		passRewards = player.bp_rewards
	end
	local loadout = supporterPass.loadout or current.loadout
	local isBot = Battlepass ~= nil
		and Battlepass.IsSupporterBotPlayerID ~= nil
		and Battlepass:IsSupporterBotPlayerID(playerID)
	local equippedItems = {}
	if Battlepass ~= nil and Battlepass.GetEquippedSupporterItems ~= nil then
		local success, items = pcall(
			Battlepass.GetEquippedSupporterItems,
			Battlepass,
			playerID
		)
		if success and type(items) == "table" then
			equippedItems = BuildPublishedSupporterLoadout(items)
		end
	end
	if isBot then
		loadout = equippedItems
		passRewards = true
	end
	local supporterTitle = FirstSupporterValue(
		supporterPass.supporter_title,
		current.supporter_title
	)
	if Battlepass ~= nil and Battlepass.GetEquippedSupporterItem ~= nil then
		local success, titleItem = pcall(
			Battlepass.GetEquippedSupporterItem,
			Battlepass,
			playerID,
			"title"
		)
		if success and type(titleItem) == "table" then
			supporterTitle = FirstSupporterValue(
				titleItem.title_text,
				titleItem.supporter_title,
				supporterTitle
			)
		end
	end

	return {
		steamid = steamID,
		is_bot = isBot,
		XP = seasonXP,
		MaxXP = seasonXPMax,
		Lvl = seasonLevel,
		title = "Supporter Pass",
		donator_level = donatorStatus,
		raw_donator_level = rawDonatorStatus,
		is_developer = isDeveloper,
		tier_id = tierID,
		tier_name = tierName,
		tier_color = tierColor,
		fragments = tonumber(FirstSupporterValue(supporterPass.fragments, supporterPass.fragment_balance, current.fragments, current.fragment_balance)) or 0,
		daily_fragments = tonumber(FirstSupporterValue(supporterPass.daily_fragments, supporterPass.daily_earned, supporterPass.weekly_fragments, supporterPass.weekly_earned, current.daily_fragments, current.daily_earned, current.weekly_fragments, current.weekly_earned)) or 0,
		daily_cap = tonumber(FirstSupporterValue(supporterPass.daily_cap, supporterPass.weekly_cap, current.daily_cap, current.weekly_cap)) or self.DAILY_FRAGMENT_CAP,
		daily_gameplay_fragments = tonumber(FirstSupporterValue(supporterPass.daily_gameplay_fragments, current.daily_gameplay_fragments)) or 0,
		daily_gameplay_cap = tonumber(FirstSupporterValue(supporterPass.daily_gameplay_cap, current.daily_gameplay_cap)) or (tier and tier.daily_gameplay_fragments or self.DAILY_GAMEPLAY_FRAGMENT_CAP),
		daily_quest_fragments = tonumber(FirstSupporterValue(supporterPass.daily_quest_fragments, current.daily_quest_fragments)) or 0,
		daily_quest_cap = tonumber(FirstSupporterValue(supporterPass.daily_quest_cap, current.daily_quest_cap)) or self.DAILY_QUEST_FRAGMENT_CAP,
		weekly_fragments = tonumber(FirstSupporterValue(supporterPass.daily_fragments, supporterPass.daily_earned, supporterPass.weekly_fragments, supporterPass.weekly_earned, current.daily_fragments, current.daily_earned, current.weekly_fragments, current.weekly_earned)) or 0,
		weekly_cap = tonumber(FirstSupporterValue(supporterPass.daily_cap, supporterPass.weekly_cap, current.daily_cap, current.weekly_cap)) or self.DAILY_FRAGMENT_CAP,
		monthly_fragments = tonumber(FirstSupporterValue(supporterPass.monthly_fragments, current.monthly_fragments)) or (tier and tier.fragments or 0),
		xp_boost = tonumber(FirstSupporterValue(supporterPass.xp_boost, current.xp_boost)) or (tier and tier.xp_boost or 0),
		vote_power = tonumber(FirstSupporterValue(
			supporterPass.vote_power,
			tier and tier.vote_power or nil,
			current.vote_power
		)) or math.max(1, math.min(tierID + 1, 5)),
		season_level = seasonLevel,
		season_xp = seasonXP,
		season_xp_max = seasonXPMax,
		season_total_xp = seasonTotalXP,
		season_id = SupporterPass2026 ~= nil and SupporterPass2026.SEASON_ID or "2026",
		backend_season_id = backendSeasonID,
		backend_season_ready = backendSeasonReady ~= false,
		season_xp_change = seasonXPChange,
		XP_change = seasonXPChange,
		base_xp_change = baseXPChange,
		xp_bonus = xpBonus,
		account_level = accountLevel,
		xhs_account_level = xhsAccountLevel,
		xhs_xp = xhsXP,
		xhs_xp_current = xhsXPCurrent,
		xhs_xp_max = xhsXPMax,
		account_title = FirstSupporterValue(account.title, current.account_title, "Supporter Pass"),
		supporter_title = supporterTitle,
		toggle_tag = FirstSupporterValue(settings.toggle_tag, player.toggle_tag, current.toggle_tag),
		pass_rewards = passRewards,
		bp_rewards = passRewards,
		player_xp = FirstSupporterValue(settings.player_xp, player.player_xp, current.player_xp),
		winrate = FirstSupporterValue(player.winrate, player.winrate_x_hero_siege, current.winrate),
		winrate_toggle = FirstSupporterValue(settings.winrate_toggle, player.winrate_toggle, current.winrate_toggle),
		xhs_ingame_advertize_hidden = FirstSupporterValue(settings.xhs_ingame_advertize_hidden, settings.ingame_advertize_hidden, player.xhs_ingame_advertize_hidden, player.ingame_advertize_hidden, current.xhs_ingame_advertize_hidden, current.ingame_advertize_hidden),
		ingame_tag = FirstSupporterValue(player.ingame_tag, current.ingame_tag),
		supporter_url = FirstSupporterValue(supporterPass.url, supporterPass.supporter_url, player.supporter_url, current.supporter_url, "https://mods.frostrose-studio.com/supporter-pass"),
		purchases = supporterPass.purchases or current.purchases,
		entitlements = supporterPass.entitlements or current.entitlements,
		access_timeline = supporterPass.access_timeline or current.access_timeline,
		armory = supporterPass.armory or current.armory,
		loadout = loadout,
		equipped_items = equippedItems,
		claimed_rewards = seasonStateAllowed
			and (supporterPass.claimed_rewards or current.claimed_rewards)
			or {},
	}
end

function SupporterPass:PublishPlayer(playerID)
	local playerTable = self:BuildPlayerTable(playerID)
	if playerTable then
		CustomNetTables:SetTableValue("supporter_pass_player", tostring(playerID), playerTable)
		if GameMode ~= nil and GameMode.RefreshSettingVotePower ~= nil then
			GameMode:RefreshSettingVotePower(playerID)
		end
		if api and api.PublishSupporterPassArmory then
			api:PublishSupporterPassArmory(playerID, playerTable.armory)
		end
	end
end

function SupporterPass:PublishPlayers()
	self:PublishMeta()
	self:PublishFeaturedShop()

	local backendRewards = api and api.supporter_pass and api.supporter_pass.rewards or {}
	local legacyFree = ItemsGame and ItemsGame.battlepass or {}
	local legacyPremium = ItemsGame and ItemsGame.battlepass2 or {}
	local freeRewards = MergeRewardTracks(legacyFree, backendRewards, "free")
	local premiumRewards = MergeRewardTracks(legacyPremium, backendRewards, "premium")
	if SupporterPass2026 ~= nil and SupporterPass2026.PublishRewardTrack ~= nil then
		SupporterPass2026:PublishRewardTrack("supporter_pass_rewards_free", freeRewards)
		SupporterPass2026:PublishRewardTrack("supporter_pass_rewards_premium", premiumRewards)
	else
		CustomNetTables:SetTableValue("supporter_pass_rewards_free", "rewards", freeRewards)
		CustomNetTables:SetTableValue("supporter_pass_rewards_premium", "rewards", premiumRewards)
	end

	for playerID = 0, PlayerResource:GetPlayerCount() - 1 do
		self:PublishPlayer(playerID)
	end
end
