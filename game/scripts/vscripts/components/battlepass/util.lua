-- Copyright (C) 2018  Frostrose Studio
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
-- http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Editors:
--     Earth Salamander #42

require('libraries/keyvalues')

LinkLuaModifier("modifier_companion", "components/battlepass/modifiers/modifier_companion.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_patreon_donator", "components/battlepass/modifiers/modifier_patreon_donator.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_donator_statue", "components/battlepass/modifiers/modifier_donator_statue.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_battlepass_taunt", "components/battlepass/modifiers/modifier_battlepass_taunt.lua", LUA_MODIFIER_MOTION_NONE)

CustomGameEventManager:RegisterListener("change_companion", Dynamic_Wrap(Battlepass, "DonatorCompanionJS"))
CustomGameEventManager:RegisterListener("change_statue", Dynamic_Wrap(Battlepass, "DonatorStatueJS"))
CustomGameEventManager:RegisterListener("change_emblem", Dynamic_Wrap(Battlepass, "DonatorEmblemJS"))
CustomGameEventManager:RegisterListener("change_companion_skin", Dynamic_Wrap(Battlepass, "DonatorCompanionSkinJS"))
CustomGameEventManager:RegisterListener("supporter_pass_change_companion", Dynamic_Wrap(Battlepass, "DonatorCompanionJS"))
CustomGameEventManager:RegisterListener("supporter_pass_change_effigy", Dynamic_Wrap(Battlepass, "DonatorStatueJS"))
CustomGameEventManager:RegisterListener("supporter_pass_change_emblem", Dynamic_Wrap(Battlepass, "DonatorEmblemJS"))
CustomGameEventManager:RegisterListener("supporter_pass_buy_shop_item", Dynamic_Wrap(Battlepass, "SupporterPassBuyShopItem"))
CustomGameEventManager:RegisterListener("supporter_pass_open_bundle", Dynamic_Wrap(Battlepass, "SupporterPassOpenBundle"))
CustomGameEventManager:RegisterListener("supporter_pass_claim_reward", Dynamic_Wrap(Battlepass, "SupporterPassClaimReward"))
CustomGameEventManager:RegisterListener("supporter_pass_equip_item", Dynamic_Wrap(Battlepass, "SupporterPassEquipItem"))
CustomGameEventManager:RegisterListener("supporter_pass_unequip_item", Dynamic_Wrap(Battlepass, "SupporterPassUnequipItem"))
CustomGameEventManager:RegisterListener("supporter_pass_update_settings", Dynamic_Wrap(Battlepass, "SupporterPassUpdateSettings"))
CustomGameEventManager:RegisterListener("supporter_pass_open_payment_portal", Dynamic_Wrap(Battlepass, "SupporterPassOpenPaymentPortal"))
CustomGameEventManager:RegisterListener("supporter_pass_dev_test_reward", Dynamic_Wrap(Battlepass, "SupporterPassDevTestReward"))
CustomGameEventManager:RegisterListener("supporter_pass_dev_stop_test", Dynamic_Wrap(Battlepass, "SupporterPassDevStopTest"))
CustomGameEventManager:RegisterListener("supporter_pass_catalog_preview", Dynamic_Wrap(Battlepass, "SupporterPassCatalogPreview"))
CustomGameEventManager:RegisterListener("supporter_pass_catalog_preview_stop", Dynamic_Wrap(Battlepass, "SupporterPassCatalogPreviewStop"))
CustomGameEventManager:RegisterListener("supporter_pass_dev_equip_local", Dynamic_Wrap(Battlepass, "SupporterPassDevEquipLocal"))
CustomGameEventManager:RegisterListener("supporter_pass_request_companion", Dynamic_Wrap(Battlepass, "SupporterPassRequestCompanion"))
CustomGameEventManager:RegisterListener("supporter_pass_request_asset", Dynamic_Wrap(Battlepass, "SupporterPassRequestAsset"))
CustomGameEventManager:RegisterListener("toggle_ingame_tag", Dynamic_Wrap(Battlepass, 'ToggleDonatorTag'))
CustomGameEventManager:RegisterListener("change_ingame_tag", Dynamic_Wrap(Battlepass, 'SetDonatorTag'))
CustomGameEventManager:RegisterListener("change_supporter_pass_rewards", Dynamic_Wrap(Battlepass, 'BattlepassRewards'))
CustomGameEventManager:RegisterListener("change_player_xp", Dynamic_Wrap(Battlepass, 'PlayerXP'))
CustomGameEventManager:RegisterListener("play_hero_taunt", Dynamic_Wrap(Battlepass, "PlayHeroTaunt"))
CustomGameEventManager:RegisterListener("change_winrate", Dynamic_Wrap(Battlepass, 'Winrate'))

function Battlepass:GetRewardUnlocked(ID)
	if IsInToolsMode() then return 1000 end
	if CustomNetTables:GetTableValue("supporter_pass_player", tostring(ID)) then
		if CustomNetTables:GetTableValue("supporter_pass_player", tostring(ID)).Lvl then
			return CustomNetTables:GetTableValue("supporter_pass_player", tostring(ID)).Lvl
		end
	end

	return 1
end

-- global functions shared across Frostrose Studio custom games
function Battlepass:AddItemEffects(hero, ply_table)
	if hero.GetPlayerID == nil then return end

	if ply_table and ply_table.bp_rewards == 0 then return end

	if CUSTOM_GAME_TYPE == "PW" then
		Battlepass:SetItemEffects(hero)
	else
		Battlepass:RegisterHeroTaunt(hero)
		Battlepass:GetHeroEffect(hero)
	end
end

-- old function. Still used for Axe and Phantom Assassin
function Battlepass:HasArcana(ID, hero_name)
	if not Battlepass.GetRewardUnlocked or not BattlepassHeroes or not BattlepassHeroes[hero_name] then return nil end

	if BattlepassHeroes[hero_name][hero_name .. "_arcana2"] then
		if Battlepass:GetRewardUnlocked(ID) >= BattlepassHeroes[hero_name][hero_name .. "_arcana2"] then
			return 1
		end
	elseif BattlepassHeroes[hero_name][hero_name .. "_arcana"] then
		if Battlepass:GetRewardUnlocked(ID) >= BattlepassHeroes[hero_name][hero_name .. "_arcana"] then
			return 0
		end
		-- -- axe immortal topbar icon handling
		-- elseif BattlepassHeroes[hero_name]["axe_immortal"] then
		-- if Battlepass:GetRewardUnlocked(ID) >= BattlepassHeroes[hero_name]["axe_immortal"] then
		-- return 0
		-- end
	end

	return nil
end

function Battlepass:ToggleDonatorTag(event_source_index, event)
	local keys = self:GetSupporterPassEventPayload(event_source_index, event)
	if keys.PlayerID == nil then return end
	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local hero = player and player:GetAssignedHero() or nil

	Battlepass:UpdatePlayerTable(keys.PlayerID, "toggle_tag", keys.tag)
end

function Battlepass:SetDonatorTag(event_source_index, event)
	local keys = self:GetSupporterPassEventPayload(event_source_index, event)
	if keys.PlayerID == nil then return end
	--	print(keys)
	local hero = PlayerResource:GetSelectedHeroEntity(keys.PlayerID)
end

function Battlepass:BattlepassRewards(event_source_index, event)
	local keys = self:GetSupporterPassEventPayload(event_source_index, event)
	if keys.PlayerID == nil then return end
	Battlepass:UpdatePlayerTable(keys.PlayerID, "bp_rewards", keys.bp_rewards)
	Battlepass:ApplySupporterLoadout(keys.PlayerID)
end

function Battlepass:PlayerXP(event_source_index, event)
	local keys = self:GetSupporterPassEventPayload(event_source_index, event)
	if keys.PlayerID == nil then return end
	Battlepass:UpdatePlayerTable(keys.PlayerID, "player_xp", keys.player_xp)
end

function Battlepass:RegisterHeroTaunt(hero)
	local armory = Battlepass:GetEquippedSupporterItems(hero:GetPlayerID()) or {}

	--	print("Armory:", armory)

	if armory and type(armory) == "table" then
		for k, v in pairs(armory) do
			local catalogItemID = Battlepass:GetSupporterCatalogItemID(v)
			if catalogItemID and v.slot_id == "taunt" then
				if hero:GetUnitName() == v.hero and Battlepass:GetRewardUnlocked(hero:GetPlayerID()) >= ItemsGame:GetItemUnlockLevel(catalogItemID) then
					if ItemsGame:GetItemVisuals(catalogItemID)["asset_modifier1"] then
						hero.bp_taunt = ItemsGame:GetItemVisuals(catalogItemID)["asset_modifier1"].modifier
					elseif ItemsGame:GetItemVisuals(catalogItemID)["asset_modifier0"] then
						hero.bp_taunt = ItemsGame:GetItemVisuals(catalogItemID)["asset_modifier0"].modifier
					elseif ItemsGame:GetItemVisuals(catalogItemID)["asset_modifier"] then
						hero.bp_taunt = ItemsGame:GetItemVisuals(catalogItemID)["asset_modifier"].modifier
					end

					return
				end
			end
		end
	end
end

function Battlepass:PlayHeroTaunt(event_source_index, event)
	local keys = self:GetSupporterPassEventPayload(event_source_index, event)
	if keys.PlayerID == nil then return end
	local hero = PlayerResource:GetSelectedHeroEntity(keys.PlayerID)
	if hero == nil or hero:IsNull() then return end

	if hero.can_cast_taunt == false then
		-- Notification: You can cast it again in x seconds

		return
	end

	local hero_short_name = string.gsub(hero:GetUnitName(), "npc_dota_hero_", "")

	if hero.bp_taunt == nil then
		-- Notification: you're level is too low or this hero have no taunt!

		return
	end

	if not hero.can_cast_taunt then
		hero.can_cast_taunt = true
	end

	if hero.can_cast_taunt == true then
		hero.can_cast_taunt = false
		hero:AddNewModifier(hero, nil, "modifier_battlepass_taunt", { duration = 7.0, taunt_anim_translate = hero.bp_taunt })
		--		ActivityModifier:AddWearableActivity(hero, hero.bp_taunt, sItemDef)

		Timers:CreateTimer(8.0, function()
			hero.can_cast_taunt = true
		end)
	end
end

function Battlepass:Winrate(event_source_index, event)
	local keys = self:GetSupporterPassEventPayload(event_source_index, event)
	if keys.PlayerID == nil then return end
	Battlepass:UpdatePlayerTable(keys.PlayerID, "winrate", keys.winrate)
end

local SUPPORTER_SLOT_ALIASES = {
	teleport_fx = "teleport",
	["teleport fx"] = "teleport",
	tome = "levelup",
	tome_fx = "levelup",
	["tome fx"] = "levelup",
	kill_fx = "kill_effect",
	["kill fx"] = "kill_effect",
	courier = "companion",
	companions = "companion",
	statue = "effigy",
	emblems = "emblem",
	bottle = "potion",
	bottles = "potion",
	mekansm = "potion",
	mekanism = "potion",
	potion_effect = "potion",
	potion_fx = "potion",
	potions = "potion",
	ankh = "rebirth",
	ankhs = "rebirth",
	reincarnation = "rebirth",
	revival = "rebirth",
	respawn = "rebirth",
	rebirth_fx = "rebirth",
	lifesteal = "attack_lifesteal",
	lifesteal_effect = "attack_lifesteal",
	attack_lifesteal_effect = "attack_lifesteal",
	spell_lifesteal_effect = "spell_lifesteal",
	fountain = "regen_aura",
	fountain_regen = "regen_aura",
	regen = "regen_aura",
	radiance = "immolation",
	cloak_of_flames = "immolation",
	immolation_effect = "immolation",
	highfive = "high_five",
	["high five"] = "high_five",
	effigies = "effigy",
	account_title = "title",
	supporter_title = "title",
	fragments = "fragment",
}

local function CopySupporterItem(source)
	local copy = {}
	if type(source) ~= "table" then return copy end
	for key, value in pairs(source) do
		copy[key] = value
	end
	return copy
end

local function NormalizeSupporterSlot(slot)
	local normalized = string.lower(tostring(slot or "default"))
	return SUPPORTER_SLOT_ALIASES[normalized] or normalized
end

function Battlepass:NormalizeSupporterSlot(slot)
	return NormalizeSupporterSlot(slot)
end

local SUPPORTER_RUNTIME_PARTICLE_FIELDS = {
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
}

local SUPPORTER_EFFECT_PATH_FIELDS = {
	start = "start_pfx",
	start_pfx = "start_pfx",
	["end"] = "end_pfx",
	end_pfx = "end_pfx",
	pfx = "pfx",
	particle = "pfx",
	target = "target_pfx",
	target_pfx = "target_pfx",
	caster = "caster_pfx",
	caster_pfx = "caster_pfx",
	health = "health_pfx",
	health_pfx = "health_pfx",
	mana = "mana_pfx",
	mana_pfx = "mana_pfx",
	light = "light_pfx",
	light_pfx = "light_pfx",
	owner = "owner_pfx",
	owner_pfx = "owner_pfx",
	overhead = "overhead_pfx",
	overhead_pfx = "overhead_pfx",
	travel = "travel_pfx",
	travel_pfx = "travel_pfx",
	impact = "impact_pfx",
	impact_pfx = "impact_pfx",
}

local SUPPORTER_PARTICLE_FIELD_BY_ANCHOR = {
	["particles/items2_fx/teleport_start.vpcf"] = "start_pfx",
	["particles/items2_fx/teleport_end.vpcf"] = "end_pfx",
	["particles/generic_hero_status/hero_levelup.vpcf"] = "pfx",
	["particles/kill_effect/default_target.vpcf"] = "target_pfx",
	["particles/kill_effect/default_caster.vpcf"] = "caster_pfx",
	["particles/hero_emblem/default.vpcf"] = "pfx",
	["particles/custom/supporter_pass/health_potion_anchor.vpcf"] = "health_pfx",
	["particles/custom/supporter_pass/mana_potion_anchor.vpcf"] = "mana_pfx",
	["particles/custom/supporter_pass/light_potion_anchor.vpcf"] = "light_pfx",
	["particles/custom/supporter_pass/rebirth_anchor.vpcf"] = "pfx",
	["particles/custom/supporter_pass/attack_lifesteal_anchor.vpcf"] = "pfx",
	["particles/custom/supporter_pass/spell_lifesteal_anchor.vpcf"] = "pfx",
	["particles/custom/supporter_pass/regen_aura_anchor.vpcf"] = "pfx",
	["particles/custom/supporter_pass/immolation_owner_anchor.vpcf"] = "owner_pfx",
	["particles/custom/supporter_pass/immolation_target_anchor.vpcf"] = "target_pfx",
}

local SUPPORTER_DEFAULT_ASSET_FIELD = {
	teleport = "start_pfx",
	levelup = "pfx",
	kill_effect = "target_pfx",
	emblem = "pfx",
	rebirth = "pfx",
	attack_lifesteal = "pfx",
	spell_lifesteal = "pfx",
	regen_aura = "pfx",
	immolation = "owner_pfx",
	high_five = "overhead_pfx",
}

local SUPPORTER_PERMANENT_RUNTIME_FIELDS = {
	asset_path = true,
	effect_paths = true,
	equip = true,
	equip_rules = true,
	runtime = true,
	runtime_assets = true,
	visuals = true,
	unit = true,
	unit_name = true,
	file = true,
	particle = true,
	title_text = true,
}
for field, _ in pairs(SUPPORTER_RUNTIME_PARTICLE_FIELDS) do
	SUPPORTER_PERMANENT_RUNTIME_FIELDS[field] = true
end

local function IsSupporterRuntimeParticlePath(value)
	return type(value) == "string"
		and string.match(string.lower(value), "^particles/.+%.vpcf$") ~= nil
end

local function SetSupporterRuntimeParticle(item, field, value)
	if SUPPORTER_RUNTIME_PARTICLE_FIELDS[field] ~= true
		or not IsSupporterRuntimeParticlePath(value)
		or IsSupporterRuntimeParticlePath(item[field]) then
		return
	end
	item[field] = value
end

local function HydrateSupporterRuntimeMetadata(item, ignoreMetadata)
	if type(item) ~= "table" then return item end
	if ignoreMetadata ~= true then
		if item.metadata == nil and type(item.metadata_json) == "table" then
			item.metadata = item.metadata_json
		end
		if item.visuals == nil and type(item.visuals_json) == "table" then
			item.visuals = item.visuals_json
		end
		if item.equip_rules == nil and type(item.equip_rules_json) == "table" then
			item.equip_rules = item.equip_rules_json
		end
	end
	local metadata = ignoreMetadata ~= true and type(item.metadata) == "table"
		and item.metadata
		or {}
	local payload = ignoreMetadata ~= true and type(item.payload) == "table"
		and item.payload
		or {}
	for _, field in ipairs({
		"asset_path",
		"effect_paths",
		"equip",
		"equip_rules",
		"runtime",
		"runtime_assets",
		"visuals",
	}) do
		if item[field] == nil then
			local value = metadata[field]
			if value == nil then value = payload[field] end
			item[field] = value
		end
	end

	local runtime = type(item.runtime) == "table" and item.runtime or {}
	for field, _ in pairs(SUPPORTER_RUNTIME_PARTICLE_FIELDS) do
		SetSupporterRuntimeParticle(item, field, runtime[field])
	end
	for _, field in ipairs({ "unit", "unit_name", "file", "particle", "title_text" }) do
		if (item[field] == nil or item[field] == "") and runtime[field] ~= nil then
			item[field] = runtime[field]
		end
	end

	local effectPaths = type(item.effect_paths) == "table" and item.effect_paths or {}
	for channel, path in pairs(effectPaths) do
		local field = SUPPORTER_EFFECT_PATH_FIELDS[string.lower(tostring(channel))]
		if field ~= nil then SetSupporterRuntimeParticle(item, field, path) end
	end
	if type(runtime.effect_paths) == "table" then
		for channel, path in pairs(runtime.effect_paths) do
			local field = SUPPORTER_EFFECT_PATH_FIELDS[string.lower(tostring(channel))]
			if field ~= nil then SetSupporterRuntimeParticle(item, field, path) end
		end
	end

	for key, value in pairs(type(item.runtime_assets) == "table" and item.runtime_assets or {}) do
		local hook = key
		local path = value
		if type(value) == "table" then
			hook = value.hook or value.channel or value.field or key
			path = value.path or value.modifier or value.asset_path
		end
		local field = SUPPORTER_EFFECT_PATH_FIELDS[string.lower(tostring(hook))]
			or SUPPORTER_PARTICLE_FIELD_BY_ANCHOR[string.lower(tostring(hook))]
		if field ~= nil then SetSupporterRuntimeParticle(item, field, path) end
	end

	for _, visual in pairs(type(item.visuals) == "table" and item.visuals or {}) do
		if type(visual) == "table" and tostring(visual.type or "particle") == "particle" then
			local field = SUPPORTER_EFFECT_PATH_FIELDS[string.lower(tostring(visual.channel or ""))]
				or SUPPORTER_PARTICLE_FIELD_BY_ANCHOR[string.lower(tostring(visual.asset or ""))]
			if field ~= nil then
				SetSupporterRuntimeParticle(item, field, visual.modifier or visual.path)
			end
		end
	end

	local assetPath = item.asset_path
	local slot = NormalizeSupporterSlot(item.slot_id or item.item_type or item.type)
	local defaultField = SUPPORTER_DEFAULT_ASSET_FIELD[slot]
	if slot == "potion" then
		local channel = tostring(
			metadata.potion_channel
			or payload.potion_channel
			or runtime.potion_channel
			or item.potion_channel
			or ""
		)
		defaultField = SUPPORTER_EFFECT_PATH_FIELDS[string.lower(channel)]
	end
	if defaultField ~= nil then
		SetSupporterRuntimeParticle(item, defaultField, assetPath)
	end

	if slot == "emblem" and item.particle == nil and IsSupporterRuntimeParticlePath(item.pfx) then
		item.particle = item.pfx
	end
	return item
end

local function MergeSupporterRuntimeSource(item, source)
	if type(item) ~= "table" or type(source) ~= "table" then return item end
	for key, _ in pairs(SUPPORTER_PERMANENT_RUNTIME_FIELDS) do
		if (item[key] == nil or item[key] == "") and source[key] ~= nil then
			item[key] = source[key]
		end
	end
	if item.metadata == nil and type(source.metadata) == "table" then
		item.metadata = source.metadata
	end
	if item.metadata == nil and type(source.metadata_json) == "table" then
		item.metadata = source.metadata_json
	end
	if item.payload == nil and type(source.payload) == "table" then
		item.payload = source.payload
	end
	if item.visuals == nil and type(source.visuals_json) == "table" then
		item.visuals = source.visuals_json
	end
	if item.equip_rules == nil and type(source.equip_rules_json) == "table" then
		item.equip_rules = source.equip_rules_json
	end
	return item
end

local function ApplySupporterPermanentManifest(item)
	if type(item) ~= "table"
		or SupporterPermanentAssets == nil
		or SupporterPermanentAssets.FindItem == nil then
		return item, false
	end
	local definition = SupporterPermanentAssets:FindItem(item)
	if type(definition) ~= "table" then return item, false end
	for key, _ in pairs(SUPPORTER_PERMANENT_RUNTIME_FIELDS) do
		item[key] = nil
	end
	for key, value in pairs(definition) do
		if SUPPORTER_PERMANENT_RUNTIME_FIELDS[key] == true then
			-- Runtime-sensitive fields are sourced from the reviewed game manifest.
			item[key] = value
		elseif item[key] == nil or item[key] == "" then
			item[key] = value
		end
	end
	item.permanent_manifest_version = SupporterPermanentAssets.SCHEMA_VERSION
	return item, true
end

local function IsSupporterContentStudioRuntime(item)
	if not IsInToolsMode()
		or GetMapName == nil
		or string.lower(GetMapName() or "") ~= "x_hero_siege_demo" then
		return false
	end
	if type(item) ~= "table" then return false end
	if item.content_studio == true then return true end
	for _, field in ipairs({ "item_id", "catalog_item_id", "id" }) do
		if string.sub(tostring(item[field] or ""), 1, 15) == "content_studio:" then
			return true
		end
	end
	return false
end

local function StripUntrustedSupporterRuntime(item)
	if type(item) ~= "table" then return item end
	for field, _ in pairs(SUPPORTER_PERMANENT_RUNTIME_FIELDS) do
		item[field] = nil
	end
	item.runtime_manifest_blocked = true
	return item
end

local function ApplyTrustedItemsGameRuntime(battlepass, item)
	if type(item) ~= "table"
		or ItemsGame == nil
		or ItemsGame.GetItemKV == nil
		or battlepass.GetSupporterCatalogItemID == nil then
		return item, false
	end
	local catalogID = battlepass:GetSupporterCatalogItemID(item)
	local definition = catalogID ~= nil and ItemsGame:GetItemKV(catalogID) or nil
	if type(definition) ~= "table" then return item, false end

	item = StripUntrustedSupporterRuntime(item)
	item.runtime_manifest_blocked = nil
	for field, _ in pairs(SUPPORTER_RUNTIME_PARTICLE_FIELDS) do
		item[field] = definition[field]
	end
	for _, field in ipairs({
		"asset_path",
		"effect_paths",
		"equip",
		"equip_rules",
		"runtime",
		"runtime_assets",
		"visuals",
		"unit",
		"unit_name",
		"file",
		"particle",
		"title_text",
	}) do
		if definition[field] ~= nil then item[field] = definition[field] end
	end
	if item.runtime_assets == nil and ItemsGame.GetItemRuntimeAssets ~= nil then
		item.runtime_assets = ItemsGame:GetItemRuntimeAssets(catalogID)
	end
	item.trusted_items_game_id = tostring(catalogID)
	return item, true
end

-- Unique companions are assigned by the backend, so requiring one manifest
-- entry per owner would make every assignment depend on a game update. Trust
-- only the entitlement identity here; the actual runtime unit must still be a
-- companion definition shipped in this addon. No backend-provided model,
-- particle or arbitrary unit path survives this boundary.
local function ApplyTrustedUniqueCompanionRuntime(item)
	if type(item) ~= "table" or item.unique_companion ~= true then
		return item, false
	end

	local slot = NormalizeSupporterSlot(item.slot_id or item.item_type or item.type)
	local itemID = tostring(
		item.item_id
		or item.entitlement_id
		or item.catalog_item_id
		or item.id
		or ""
	)
	local unitName = tostring(item.unit or item.unit_name or "")
	if slot ~= "companion"
		or string.match(string.lower(itemID), "^unique_companion_[a-z0-9_:%.%-]+$") == nil
		or unitName == "" then
		return item, false
	end

	local companions = LoadKeyValues("scripts/npc/units/companions.txt") or {}
	if type(companions[unitName]) ~= "table" then
		return item, false
	end

	item = StripUntrustedSupporterRuntime(item)
	item.runtime_manifest_blocked = nil
	item.unit = unitName
	item.unit_name = unitName
	item.trusted_unique_companion_unit = true
	return item, true
end

function Battlepass:HydrateSupporterRuntimeMetadata(item)
	item = HydrateSupporterRuntimeMetadata(item, false)
	local manifestApplied = false
	item, manifestApplied = ApplySupporterPermanentManifest(item)
	if manifestApplied then
		item = HydrateSupporterRuntimeMetadata(item, true)
		item.runtime_manifest_blocked = nil
		return item
	end
	local itemsGameApplied = false
	item, itemsGameApplied = ApplyTrustedItemsGameRuntime(self, item)
	if itemsGameApplied then
		return HydrateSupporterRuntimeMetadata(item, true)
	end
	local uniqueCompanionApplied = false
	item, uniqueCompanionApplied = ApplyTrustedUniqueCompanionRuntime(item)
	if uniqueCompanionApplied then
		return HydrateSupporterRuntimeMetadata(item, true)
	end
	if IsSupporterContentStudioRuntime(item) then
		item.runtime_manifest_blocked = nil
		return item
	end
	return StripUntrustedSupporterRuntime(item)
end

local function RequiredSupporterTier(value, fallback)
	if type(value) ~= "table" then return fallback or 0 end
	local tier = tonumber(value.required_tier or value.tier_id)
	if tier == nil and DONATOR_STATUS_TO_TIER ~= nil then
		tier = DONATOR_STATUS_TO_TIER[tonumber(value.required_status)]
	end
	return tier or fallback or 0
end

local function NormalizeSupporterList(value)
	if type(value) ~= "table" then return {} end
	if #value > 0 then return value end
	for _, wrapper in ipairs({ "items", "rewards", "armory", "entitlements" }) do
		if type(value[wrapper]) == "table" then
			local nested = NormalizeSupporterList(value[wrapper])
			if #nested > 0 then return nested end
		end
	end

	local keyCount = 0
	local onlyKey = nil
	local numericKeys = {}
	for key, _ in pairs(value) do
		keyCount = keyCount + 1
		onlyKey = key
		if tonumber(key) ~= nil then
			table.insert(numericKeys, tonumber(key))
		end
	end

	if keyCount == 1 and tostring(onlyKey) == "1" and type(value[onlyKey]) == "table"
		and value.item_id == nil and value.id == nil and value.entitlement_id == nil then
		return NormalizeSupporterList(value[onlyKey])
	end

	if #numericKeys > 0 then
		table.sort(numericKeys)
		local result = {}
		for _, numericKey in ipairs(numericKeys) do
			local item = value[numericKey] or value[tostring(numericKey)]
			if type(item) == "table" then
				table.insert(result, item)
			end
		end
		return result
	end

	if value.item_id ~= nil or value.id ~= nil or value.entitlement_id ~= nil or value.unit ~= nil then
		return { value }
	end

	return {}
end

local function SupporterItemMatches(item, itemID)
	if type(item) ~= "table" or itemID == nil then return false end
	local expected = tostring(itemID)
	local fields = {
		item.entitlement_id,
		item.id,
		item.item_id,
		item.catalog_item_id,
		item.catalog_item_key,
		item.item_key,
		item.reward_item_id,
		item.unit,
		item.unit_name,
		item.name,
	}
	for _, value in ipairs(fields) do
		if value ~= nil and tostring(value) == expected then
			return true
		end
	end
	return false
end

function Battlepass:GetOwnedSupporterItems(playerID)
	local armory = api and api.GetSupporterPassArmory and api:GetSupporterPassArmory(playerID) or {}
	if type(armory) ~= "table" or next(armory) == nil then
		armory = CustomNetTables:GetTableValue("supporter_pass_armory", "rewards_" .. tostring(playerID)) or {}
	end
	local items = NormalizeSupporterList(armory)
	if #items > 0 then return items end

	for _, item in pairs(armory) do
		if type(item) == "table" then
			table.insert(items, item)
		end
	end
	return items
end

function Battlepass:FindOwnedSupporterItem(playerID, itemID)
	for _, item in ipairs(self:GetOwnedSupporterItems(playerID)) do
		if SupporterItemMatches(item, itemID) then
			return CopySupporterItem(item)
		end
	end
	return nil
end

function Battlepass:BuildLegacySupporterItem(playerID, itemID, requestedSlot)
	if ItemsGame == nil or ItemsGame.GetItemKV == nil then return nil end
	local definition = ItemsGame:GetItemKV(itemID)
	if type(definition) ~= "table" then return nil end
	-- Season 2026 catalog entries must come from the claimed/owned armory.
	-- Only the historical catalog keeps the level-based compatibility fallback.
	if tostring(definition.season_id or "") == "2026" then return nil end

	local requiredLevel = tonumber(ItemsGame:GetItemUnlockLevel(itemID)) or 1
	if self:GetRewardUnlocked(playerID) < requiredLevel then return nil end
	if ItemsGame:IsPremiumReward(itemID) and (SupporterPass == nil or SupporterPass:GetTierForPlayer(playerID) < 1) then
		return nil
	end
	if definition.item_unreleased == 1 or definition.item_unreleased == "1" then return nil end

	local itemType = ItemsGame:GetItemType(itemID)
	return {
		id = tostring(itemID),
		item_id = tostring(itemID),
		name = ItemsGame:GetItemName(itemID),
		type = itemType,
		item_type = itemType,
		slot_id = NormalizeSupporterSlot(requestedSlot ~= "default" and requestedSlot or itemType),
		hero = ItemsGame:GetItemHero(itemID) or itemType or "global",
		legacy = true,
	}
end

function Battlepass:ResolveSupporterItem(playerID, itemID, requestedSlot)
	local resolvedRequestID = itemID
	if SupporterPass2026 ~= nil and SupporterPass2026.ResolveCatalogID ~= nil then
		resolvedRequestID = SupporterPass2026:ResolveCatalogID(itemID) or itemID
	end
	local item = self:FindOwnedSupporterItem(playerID, itemID)
	if item == nil and tostring(resolvedRequestID) ~= tostring(itemID) then
		item = self:FindOwnedSupporterItem(playerID, resolvedRequestID)
	end
	if item == nil and SupporterPass2026 ~= nil
		and SupporterPass2026.GetBackendCatalogKey ~= nil then
		local backendCatalogKey =
			SupporterPass2026:GetBackendCatalogKey(resolvedRequestID)
		if backendCatalogKey ~= nil then
			item = self:FindOwnedSupporterItem(
				playerID,
				backendCatalogKey
			)
		end
	end
	if item == nil then
		item = self:BuildLegacySupporterItem(playerID, resolvedRequestID, requestedSlot)
	end
	if item == nil then return nil end

	item.item_id = item.item_id
		or item.catalog_item_id
		or item.catalog_item_key
		or item.item_key
		or item.reward_item_id
		or item.id
	item.slot_id = NormalizeSupporterSlot(item.slot_id or item.item_type or item.type or requestedSlot)

	local catalogItemID = self:GetSupporterCatalogItemID(item)
	if catalogItemID == nil and SupporterPass2026 ~= nil
		and SupporterPass2026.ResolveCatalogID ~= nil then
		catalogItemID = SupporterPass2026:ResolveCatalogID(itemID)
	end
	local definition = catalogItemID ~= nil and ItemsGame:GetItemKV(catalogItemID) or nil
	if type(definition) == "table" then
		item.catalog_item_id = tostring(catalogItemID)
		for key, value in pairs(definition) do
			if key ~= "item_id" and (item[key] == nil or item[key] == "") then
				item[key] = value
			end
		end
		if item.slot_id == "default" then
			item.slot_id = NormalizeSupporterSlot(
				definition.slot_id or definition.item_type
			)
		end
	end

	-- Backend loadouts intentionally contain only identity and slot fields. Rehydrate
	-- cosmetic runtime metadata from the legacy catalogs before applying the item.
	local catalogs = {
		companion = api and api.companions or {},
		emblem = api and api.emblems or {},
		effigy = api and (api.effigies or api.statues) or {},
	}
	for _, cosmetic in pairs(catalogs[item.slot_id] or {}) do
		if SupporterItemMatches(cosmetic, itemID)
			or SupporterItemMatches(cosmetic, item.item_id)
			or SupporterItemMatches(cosmetic, item.entitlement_id) then
			for key, value in pairs(cosmetic) do
				if (item[key] == nil or item[key] == "") and value ~= nil and value ~= "" then
					item[key] = value
				end
			end
			break
		end
	end
	if self.FindSupporterPassShopItem ~= nil then
		local resolver = self.FindSupporterPassRuntimeCatalogItem
			or self.FindSupporterPassShopItem
		local shopItem = resolver(self, item.item_id or itemID)
		if shopItem == nil and tostring(resolvedRequestID) ~= tostring(itemID) then
			shopItem = resolver(self, resolvedRequestID)
		end
		item = MergeSupporterRuntimeSource(item, shopItem)
	end
	item = self:HydrateSupporterRuntimeMetadata(item)

	if item.slot_id == "companion" or item.slot_id == "effigy" then
		item.unit = item.unit or item.unit_name or item.file
		local definitionsFile = item.slot_id == "companion"
			and "scripts/npc/units/companions.txt"
			or "scripts/npc/units/statues.txt"
		local definitions = LoadKeyValues(definitionsFile) or {}
		local unitCandidate = tostring(item.unit or item.item_id or item.id or "")
		if type(definitions[unitCandidate]) == "table" then
			item.unit = unitCandidate
		end
	elseif item.slot_id == "emblem" then
		item.particle = item.particle or item.file
	end

	return self:HydrateSupporterRuntimeMetadata(item)
end

local function HydrateSupporterLoadoutItem(battlepass, playerID, value, requestedSlot)
	local item = type(value) == "table" and CopySupporterItem(value) or {}
	local itemID = type(value) == "table"
		and (value.entitlement_id or value.item_id or value.catalog_item_id or value.catalog_item_key or value.item_key or value.reward_item_id or value.id or value.unit)
		or value
	local slot = NormalizeSupporterSlot(item.slot_id or item.item_type or item.type or requestedSlot)
	local resolved = itemID ~= nil and battlepass:ResolveSupporterItem(playerID, itemID, slot) or nil

	-- A backend loadout is only an identity/slot hint. Never apply a stale or
	-- forged-looking record that cannot be proven against the player's owned
	-- armory (or the explicit historical level fallback).
	if resolved == nil then return nil end

	for key, fieldValue in pairs(item) do
		if fieldValue ~= nil and fieldValue ~= "" then
			resolved[key] = fieldValue
		end
	end
	item = resolved

	if next(item) == nil then return nil end
	item.slot_id = NormalizeSupporterSlot(item.slot_id or item.item_type or item.type or slot)
	return battlepass:HydrateSupporterRuntimeMetadata(item)
end

local SUPPORTER_BOT_EFFECT_SLOT_ORDER = {
	"teleport",
	"levelup",
	"kill_effect",
	"emblem",
	"potion",
	"rebirth",
	"attack_lifesteal",
	"spell_lifesteal",
	"regen_aura",
	"immolation",
	"high_five",
}

local SUPPORTER_BOT_EFFECT_FIELDS = {
	teleport = { "start_pfx", "end_pfx" },
	levelup = { "pfx" },
	kill_effect = { "target_pfx", "caster_pfx" },
	emblem = { "pfx" },
	potion = { "health_pfx", "mana_pfx", "light_pfx" },
	rebirth = { "pfx" },
	attack_lifesteal = { "pfx" },
	spell_lifesteal = { "pfx" },
	regen_aura = { "pfx" },
	immolation = { "owner_pfx", "target_pfx" },
	high_five = { "overhead_pfx", "travel_pfx", "impact_pfx" },
}

local SUPPORTER_BOT_EFFECT_ANCHORS = {
	teleport = {
		start_pfx = "particles/items2_fx/teleport_start.vpcf",
		end_pfx = "particles/items2_fx/teleport_end.vpcf",
	},
	levelup = {
		pfx = "particles/generic_hero_status/hero_levelup.vpcf",
	},
	kill_effect = {
		target_pfx = "particles/kill_effect/default_target.vpcf",
		caster_pfx = "particles/kill_effect/default_caster.vpcf",
	},
	emblem = {
		pfx = "particles/hero_emblem/default.vpcf",
	},
	potion = {
		health_pfx = "particles/custom/supporter_pass/health_potion_anchor.vpcf",
		mana_pfx = "particles/custom/supporter_pass/mana_potion_anchor.vpcf",
		light_pfx = "particles/custom/supporter_pass/light_potion_anchor.vpcf",
	},
	rebirth = {
		pfx = "particles/custom/supporter_pass/rebirth_anchor.vpcf",
	},
	attack_lifesteal = {
		pfx = "particles/custom/supporter_pass/attack_lifesteal_anchor.vpcf",
	},
	spell_lifesteal = {
		pfx = "particles/custom/supporter_pass/spell_lifesteal_anchor.vpcf",
	},
	regen_aura = {
		pfx = "particles/custom/supporter_pass/regen_aura_anchor.vpcf",
	},
	immolation = {
		owner_pfx = "particles/custom/supporter_pass/immolation_owner_anchor.vpcf",
		target_pfx = "particles/custom/supporter_pass/immolation_target_anchor.vpcf",
	},
}

local SUPPORTER_BOT_DEFAULT_PARTICLES = {
	["particles/items2_fx/teleport_start.vpcf"] = true,
	["particles/items2_fx/teleport_end.vpcf"] = true,
	["particles/generic_hero_status/hero_levelup.vpcf"] = true,
	["particles/kill_effect/default_target.vpcf"] = true,
	["particles/kill_effect/default_caster.vpcf"] = true,
	["particles/hero_emblem/default.vpcf"] = true,
	["particles/custom/supporter_pass/health_potion_anchor.vpcf"] = true,
	["particles/custom/supporter_pass/mana_potion_anchor.vpcf"] = true,
	["particles/custom/supporter_pass/light_potion_anchor.vpcf"] = true,
	["particles/custom/supporter_pass/rebirth_anchor.vpcf"] = true,
	["particles/custom/supporter_pass/attack_lifesteal_anchor.vpcf"] = true,
	["particles/custom/supporter_pass/spell_lifesteal_anchor.vpcf"] = true,
	["particles/custom/supporter_pass/regen_aura_anchor.vpcf"] = true,
	["particles/custom/supporter_pass/immolation_owner_anchor.vpcf"] = true,
	["particles/custom/supporter_pass/immolation_target_anchor.vpcf"] = true,
}

local function IsSupporterBotCustomParticle(path)
	if type(path) ~= "string" then return false end
	local normalized = string.lower(path)
	return string.match(normalized, "^particles/.+%.vpcf$") ~= nil
		and SUPPORTER_BOT_DEFAULT_PARTICLES[normalized] ~= true
end

local function ResolveSupporterBotDefinitionEffects(definition, slot)
	if type(definition) ~= "table" then return nil end
	local fields = SUPPORTER_BOT_EFFECT_FIELDS[slot]
	if type(fields) ~= "table" then return nil end
	local resolved = {}
	for _, field in ipairs(fields) do
		local particle = definition[field]
		if not IsSupporterBotCustomParticle(particle) then
			local expectedAnchor = SUPPORTER_BOT_EFFECT_ANCHORS[slot]
				and SUPPORTER_BOT_EFFECT_ANCHORS[slot][field]
			for _, visual in pairs(definition.visuals or {}) do
				if type(visual) == "table"
					and visual.type == "particle"
					and (expectedAnchor == nil or visual.asset == expectedAnchor)
					and IsSupporterBotCustomParticle(visual.modifier) then
					particle = visual.modifier
					break
				end
			end
		end
		if not IsSupporterBotCustomParticle(particle) then return nil end
		resolved[field] = particle
	end
	return resolved
end

local function ShuffleSupporterBotPool(pool)
	for index = #pool, 2, -1 do
		local swapIndex = RandomInt ~= nil and RandomInt(1, index) or index
		pool[index], pool[swapIndex] = pool[swapIndex], pool[index]
	end
end

function Battlepass:IsSupporterBotPlayerID(playerID)
	playerID = tonumber(playerID)
	if playerID == nil or playerID < 0 or not PlayerResource:IsValidPlayerID(playerID) then
		return false
	end
	if IsXHSBotPlayerID ~= nil then
		local ok, isBot = pcall(IsXHSBotPlayerID, playerID)
		if ok and isBot == true then return true end
	end
	if api ~= nil and api.IsXHSBotParticipant ~= nil then
		local ok, isBot = pcall(api.IsXHSBotParticipant, api, playerID)
		if ok and isBot == true then return true end
	end
	if PlayerResource.IsFakeClient ~= nil then
		local ok, isBot = pcall(function()
			return PlayerResource:IsFakeClient(playerID)
		end)
		if ok and isBot == true then return true end
	end
	return false
end

function Battlepass:BuildSupporterBotEffectPools()
	if type(self.SUPPORTER_BOT_EFFECT_POOLS) == "table" then
		return self.SUPPORTER_BOT_EFFECT_POOLS
	end

	local pools = {}
	local seenSignatures = {}
	for _, slot in ipairs(SUPPORTER_BOT_EFFECT_SLOT_ORDER) do
		pools[slot] = {}
		seenSignatures[slot] = {}
	end
	for catalogID, definition in pairs(ItemsGame and ItemsGame.custom_kv or {}) do
		local slot = NormalizeSupporterSlot(type(definition) == "table"
			and (definition.slot_id or definition.item_type) or nil)
		local resolvedEffects = pools[slot] ~= nil
			and ResolveSupporterBotDefinitionEffects(definition, slot) or nil
		if resolvedEffects ~= nil then
			local signatureParts = {}
			for _, field in ipairs(SUPPORTER_BOT_EFFECT_FIELDS[slot]) do
				table.insert(signatureParts, resolvedEffects[field])
			end
			local signature = table.concat(signatureParts, "\0")
			if not seenSignatures[slot][signature] then
				seenSignatures[slot][signature] = true
				local item = CopySupporterItem(definition)
				for field, particle in pairs(resolvedEffects) do
					item[field] = particle
				end
				item.id = tostring(catalogID)
				item.item_id = tostring(catalogID)
				item.catalog_item_id = tostring(catalogID)
				item.slot_id = slot
				item.item_type = item.item_type or slot
				item.type = item.type or item.item_type
				item.name = item.name or item.item_name
				item.image = item.image or item.image_inventory
				item.rarity = item.rarity or item.item_rarity
				if slot == "emblem" then
					item.particle = item.particle or item.pfx
				end
				table.insert(pools[slot], item)
			end
		end
	end

	for _, slot in ipairs(SUPPORTER_BOT_EFFECT_SLOT_ORDER) do
		table.sort(pools[slot], function(a, b)
			local aID = tonumber(a.catalog_item_id)
			local bID = tonumber(b.catalog_item_id)
			if aID ~= nil and bID ~= nil then return aID < bID end
			return tostring(a.catalog_item_id) < tostring(b.catalog_item_id)
		end)
		ShuffleSupporterBotPool(pools[slot])
	end

	self.SUPPORTER_BOT_EFFECT_POOLS = pools
	return pools
end

function Battlepass:GetSupporterBotEffectItems(playerID)
	playerID = tonumber(playerID)
	if not self:IsSupporterBotPlayerID(playerID) then return {} end
	self.SUPPORTER_BOT_EFFECT_LOADOUTS = self.SUPPORTER_BOT_EFFECT_LOADOUTS or {}
	local cached = self.SUPPORTER_BOT_EFFECT_LOADOUTS[playerID]
	if type(cached) == "table" then return cached end

	self.SUPPORTER_BOT_EFFECT_ASSIGNMENTS = self.SUPPORTER_BOT_EFFECT_ASSIGNMENTS or {}
	local assignmentIndex = self.SUPPORTER_BOT_EFFECT_ASSIGNMENTS[playerID]
	if assignmentIndex == nil then
		self.SUPPORTER_BOT_EFFECT_ASSIGNMENT_COUNT =
			(tonumber(self.SUPPORTER_BOT_EFFECT_ASSIGNMENT_COUNT) or 0) + 1
		assignmentIndex = self.SUPPORTER_BOT_EFFECT_ASSIGNMENT_COUNT
		self.SUPPORTER_BOT_EFFECT_ASSIGNMENTS[playerID] = assignmentIndex
	end

	local loadout = {}
	local pools = self:BuildSupporterBotEffectPools()
	for _, slot in ipairs(SUPPORTER_BOT_EFFECT_SLOT_ORDER) do
		local pool = pools[slot] or {}
		if #pool > 0 then
			local poolIndex = ((assignmentIndex - 1) % #pool) + 1
			local item = CopySupporterItem(pool[poolIndex])
			item.bot_assignment_index = assignmentIndex
			table.insert(loadout, item)
		end
	end
	self.SUPPORTER_BOT_EFFECT_LOADOUTS[playerID] = loadout
	return loadout
end

function Battlepass:GetEquippedSupporterItems(playerID)
	if self:IsSupporterBotPlayerID(playerID) then
		return self:GetSupporterBotEffectItems(playerID)
	end
	local loadout = api and api.GetSupporterPassLoadout and api:GetSupporterPassLoadout(playerID) or {}
	if type(loadout) ~= "table" or next(loadout) == nil then
		local playerTable = CustomNetTables:GetTableValue("supporter_pass_player", tostring(playerID)) or {}
		loadout = playerTable.loadout or {}
	end

	local list = NormalizeSupporterList(loadout)
	local result = {}
	if #list > 0 then
		for _, value in ipairs(list) do
			local item = HydrateSupporterLoadoutItem(self, playerID, value, value.slot_id or value.item_type or value.type)
			if item ~= nil then
				table.insert(result, item)
			end
		end
	else
		for slot, value in pairs(loadout) do
			local item = HydrateSupporterLoadoutItem(self, playerID, value, slot)
			if item ~= nil then
				item.slot_id = NormalizeSupporterSlot(item.slot_id or slot)
				table.insert(result, item)
			end
		end
	end

	-- Tools-mode DEV UI equipment is a match-local overlay. It never mutates
	-- api.players and never calls the backend, but all runtime consumers see it
	-- as the equipped item for the selected slot.
	local devLoadout = self.SUPPORTER_DEV_LOCAL_LOADOUTS
		and self.SUPPORTER_DEV_LOCAL_LOADOUTS[playerID]
	if type(devLoadout) == "table" then
		local merged = {}
		for _, item in ipairs(result) do
			local slot = NormalizeSupporterSlot(item.slot_id or item.item_type or item.type)
			if devLoadout[slot] == nil then
				table.insert(merged, item)
			end
		end
		for slot, item in pairs(devLoadout) do
			if type(item) == "table" then
				local localItem = CopySupporterItem(item)
				localItem.slot_id = NormalizeSupporterSlot(localItem.slot_id or slot)
				table.insert(merged, localItem)
			end
		end
		result = merged
	end
	return result
end

function Battlepass:GetEquippedSupporterItem(playerID, slot)
	local expectedSlot = NormalizeSupporterSlot(slot)
	for _, item in ipairs(self:GetEquippedSupporterItems(playerID)) do
		local itemSlot = NormalizeSupporterSlot(item.slot_id or item.item_type or item.type or item.hero)
		if itemSlot == expectedSlot then
			return item
		end
	end
	return nil
end

function Battlepass:SetLocalSupporterLoadoutItem(playerID, item)
	if not api or not api.players or type(item) ~= "table" then return false end
	local steamID = tostring(PlayerResource:GetSteamID(playerID))
	local player = api.players[steamID]
	if type(player) ~= "table" then return false end

	local loadout = {}
	for _, equipped in ipairs(self:GetEquippedSupporterItems(playerID)) do
		local equippedSlot = NormalizeSupporterSlot(equipped.slot_id or equipped.item_type or equipped.type)
		loadout[equippedSlot] = CopySupporterItem(equipped)
	end
	local slot = NormalizeSupporterSlot(item.slot_id or item.item_type or item.type)
	loadout[slot] = CopySupporterItem(item)
	player.supporter_pass = player.supporter_pass or {}
	player.supporter_pass.loadout = loadout

	if SupporterPass and SupporterPass.PublishPlayer then
		SupporterPass:PublishPlayer(playerID)
	else
		self:ApplySupporterLoadout(playerID)
	end
	return true
end

function Battlepass:AreSupporterRewardsEnabled(playerID)
	if self:IsSupporterBotPlayerID(playerID) then
		return true
	end
	if self.SUPPORTER_DEV_LOCAL_LOADOUTS
		and type(self.SUPPORTER_DEV_LOCAL_LOADOUTS[playerID]) == "table" then
		return true
	end
	local playerTable = CustomNetTables:GetTableValue("supporter_pass_player", tostring(playerID)) or {}
	local value = playerTable.pass_rewards
	if value == nil then value = playerTable.bp_rewards end
	return value ~= false and value ~= 0 and value ~= "0"
end

function Battlepass:GetSupporterItemParticle(item, expectedAsset)
	if type(item) ~= "table" then return nil end
	item = self:HydrateSupporterRuntimeMetadata(item)
	local expectedKey = string.lower(tostring(expectedAsset or ""))
	local directField = SUPPORTER_PARTICLE_FIELD_BY_ANCHOR[expectedKey]
	if directField ~= nil and IsSupporterRuntimeParticlePath(item[directField]) then
		return item[directField]
	end

	for _, visual in pairs(type(item.visuals) == "table" and item.visuals or {}) do
		if type(visual) == "table"
			and tostring(visual.type or "particle") == "particle"
			and (expectedAsset == nil or tostring(visual.asset or "") == tostring(expectedAsset))
			and IsSupporterRuntimeParticlePath(visual.modifier or visual.path) then
			return visual.modifier or visual.path
		end
	end

	if ItemsGame == nil then return nil end
	local itemID = self:GetSupporterCatalogItemID(item)
	if itemID == nil then return nil end
	local visuals = ItemsGame:GetItemVisuals(itemID)
	if type(visuals) ~= "table" then return nil end

	for _, visual in pairs(visuals) do
		if type(visual) == "table" and visual.type == "particle"
			and (expectedAsset == nil or visual.asset == expectedAsset) then
			return visual.modifier
		end
	end
	return nil
end

function Battlepass:GetSupporterCatalogItemID(item)
	if type(item) ~= "table" or ItemsGame == nil then return nil end
	local candidateFields = {
		"catalog_item_id",
		"catalog_item_key",
		"item_key",
		"reward_item_id",
		"item_id",
		"reward_id",
		"entitlement_id",
		"id",
		"name",
		"unit",
	}
	for _, field in ipairs(candidateFields) do
		local candidate = item[field]
		if candidate ~= nil and ItemsGame:GetItemKV(candidate) ~= nil then
			return tostring(candidate)
		end
		if candidate ~= nil and SupporterPass2026 ~= nil
			and SupporterPass2026.ResolveCatalogID ~= nil then
			local catalogItemID = SupporterPass2026:ResolveCatalogID(candidate)
			if catalogItemID ~= nil and ItemsGame:GetItemKV(catalogItemID) ~= nil then
				return tostring(catalogItemID)
			end
		end
	end
	return nil
end

Battlepass.Player = Battlepass.Player or {}

local SUPPORTER_PLAYER_PARTICLE_CHANNELS = {
	teleport = {
		{ key = "teleport_start_pfx", field = "start_pfx", anchor = "particles/items2_fx/teleport_start.vpcf" },
		{ key = "teleport_end_pfx",   field = "end_pfx",   anchor = "particles/items2_fx/teleport_end.vpcf" },
	},
	levelup = {
		{ key = "levelup_pfx", field = "pfx", anchor = "particles/generic_hero_status/hero_levelup.vpcf" },
	},
	kill_effect = {
		{ key = "kill_target_pfx", field = "target_pfx", anchor = "particles/kill_effect/default_target.vpcf" },
		{ key = "kill_caster_pfx", field = "caster_pfx", anchor = "particles/kill_effect/default_caster.vpcf" },
	},
	emblem = {
		{ key = "emblem_pfx", field = "pfx", anchor = "particles/hero_emblem/default.vpcf" },
	},
	potion = {
		{ key = "health_potion_pfx", field = "health_pfx", anchor = "particles/custom/supporter_pass/health_potion_anchor.vpcf" },
		{ key = "mana_potion_pfx",   field = "mana_pfx",   anchor = "particles/custom/supporter_pass/mana_potion_anchor.vpcf" },
		{ key = "light_potion_pfx",  field = "light_pfx",  anchor = "particles/custom/supporter_pass/light_potion_anchor.vpcf" },
	},
	rebirth = {
		{ key = "rebirth_pfx", field = "pfx", anchor = "particles/custom/supporter_pass/rebirth_anchor.vpcf" },
	},
	attack_lifesteal = {
		{ key = "attack_lifesteal_pfx", field = "pfx", anchor = "particles/custom/supporter_pass/attack_lifesteal_anchor.vpcf" },
	},
	spell_lifesteal = {
		{ key = "spell_lifesteal_pfx", field = "pfx", anchor = "particles/custom/supporter_pass/spell_lifesteal_anchor.vpcf" },
	},
	regen_aura = {
		{ key = "regen_aura_pfx", field = "pfx", anchor = "particles/custom/supporter_pass/regen_aura_anchor.vpcf" },
	},
	immolation = {
		{ key = "immolation_owner_pfx",  field = "owner_pfx",  anchor = "particles/custom/supporter_pass/immolation_owner_anchor.vpcf" },
		{ key = "immolation_target_pfx", field = "target_pfx", anchor = "particles/custom/supporter_pass/immolation_target_anchor.vpcf" },
	},
	high_five = {
		{ key = "high_five_overhead_pfx", field = "overhead_pfx" },
		{ key = "high_five_travel_pfx",   field = "travel_pfx" },
		{ key = "high_five_impact_pfx",   field = "impact_pfx" },
	},
}

local function IsSupporterParticlePath(path)
	return type(path) == "string"
		and string.match(string.lower(path), "^particles/.+%.vpcf$") ~= nil
end

function Battlepass:ApplySupporterPlayerParticleItem(playerID, slot, item)
	playerID = tonumber(playerID)
	if playerID == nil or playerID < 0 then return end

	self.Player[playerID] = self.Player[playerID] or {}
	local playerParticles = self.Player[playerID]
	for _, channel in ipairs(SUPPORTER_PLAYER_PARTICLE_CHANNELS[slot] or {}) do
		playerParticles[channel.key] = nil
		local particle = type(item) == "table" and item[channel.field] or nil
		if not IsSupporterParticlePath(particle) and channel.anchor ~= nil then
			particle = self:GetSupporterItemParticle(item, channel.anchor)
		end
		if IsSupporterParticlePath(particle) and particle ~= channel.anchor then
			playerParticles[channel.key] = particle
		end
	end
end

function Battlepass:BuildSupporterPlayerParticles(playerID)
	playerID = tonumber(playerID)
	if playerID == nil or playerID < 0 then return nil end

	local previous = self.Player[playerID]
	self.Player[playerID] = {
		ready = true,
		particle_overrides = type(previous) == "table" and previous.particle_overrides or {},
	}
	if not self:AreSupporterRewardsEnabled(playerID) then
		return self.Player[playerID]
	end

	for slot, _ in pairs(SUPPORTER_PLAYER_PARTICLE_CHANNELS) do
		self:ApplySupporterPlayerParticleItem(
			playerID,
			slot,
			self:GetEquippedSupporterItem(playerID, slot)
		)
	end
	return self.Player[playerID]
end

function Battlepass:GetSupporterPlayerID(subject)
	if type(subject) == "number" then return subject end
	if subject == nil or (subject.IsNull ~= nil and subject:IsNull()) then return nil end

	for _, getter in ipairs({ "GetPlayerOwnerID", "GetPlayerID" }) do
		if subject[getter] ~= nil then
			local ok, playerID = pcall(subject[getter], subject)
			if ok and tonumber(playerID) ~= nil and tonumber(playerID) >= 0 then
				return tonumber(playerID)
			end
		end
	end
	return nil
end

function Battlepass:GetPlayerParticle(subject, key, fallback)
	local playerID = self:GetSupporterPlayerID(subject)
	if playerID == nil then return fallback end

	local playerParticles = self.Player[playerID]
	if type(playerParticles) ~= "table" or playerParticles.ready ~= true then
		playerParticles = self:BuildSupporterPlayerParticles(playerID)
	end
	local particle = type(playerParticles) == "table" and playerParticles[key] or nil
	return IsSupporterParticlePath(particle) and particle or fallback
end

function Battlepass:GetPlayerParticleOverride(subject, originalParticle)
	local playerID = self:GetSupporterPlayerID(subject)
	if playerID == nil then return originalParticle end
	local playerParticles = self.Player[playerID]
	local overrides = type(playerParticles) == "table" and playerParticles.particle_overrides or nil
	local replacement = type(overrides) == "table" and overrides[originalParticle] or nil
	return IsSupporterParticlePath(replacement) and replacement or originalParticle
end

function XHSGetBattlepassParticle(subject, key, fallback)
	if Battlepass ~= nil and Battlepass.GetPlayerParticle ~= nil then
		return Battlepass:GetPlayerParticle(subject, key, fallback)
	end
	return fallback
end

function Battlepass:ClearSupporterOverrides(playerID)
	self.Player = self.Player or {}
	self.Player[playerID] = self.Player[playerID] or {}
	self.Player[playerID].particle_overrides = {}
	self.SUPPORTER_OVERRIDE_ASSETS = self.SUPPORTER_OVERRIDE_ASSETS or {}
	for asset, _ in pairs(self.SUPPORTER_OVERRIDE_ASSETS[playerID] or {}) do
		CustomNetTables:SetTableValue("supporter_pass_player", asset .. "_" .. tostring(playerID), { asset })
	end
	self.SUPPORTER_OVERRIDE_ASSETS[playerID] = {}
end

function Battlepass:ApplySupporterEmblem(hero, item)
	if hero == nil or hero:IsNull() then return end
	local particle = item and (item.particle or item.pfx or item.file or self:GetSupporterItemParticle(item, "particles/hero_emblem/default.vpcf")) or ""
	if particle ~= "" and not hero:HasModifier("modifier_patreon_donator") then
		hero:AddNewModifier(hero, nil, "modifier_patreon_donator", {})
	end
	local modifier = hero:FindModifierByName("modifier_patreon_donator")
	if modifier and modifier.SetDonatorEffect then
		modifier:SetDonatorEffect(particle)
	end
end

local function RefreshSupporterItemVisuals(hero)
	if hero == nil or hero:IsNull() then return end
	for _, modifier in pairs(hero:FindAllModifiersByName("modifier_lifesteal_mask") or {}) do
		if modifier.RefreshSupporterIcon ~= nil then
			modifier:RefreshSupporterIcon()
		end
	end
end

function Battlepass:ApplySupporterLoadout(playerID, hero)
	if not PlayerResource:IsValidPlayerID(playerID) then return end
	self:BuildSupporterPlayerParticles(playerID)
	hero = hero or PlayerResource:GetSelectedHeroEntity(playerID)
	if hero == nil or hero:IsNull() then return end

	self:ClearSupporterOverrides(playerID)
	if not self:AreSupporterRewardsEnabled(playerID) then
		self:ApplySupporterEmblem(hero, nil)
		self:DonatorCompanion(playerID, "", true)
		if self.RemoveDonatorStatue then self:RemoveDonatorStatue(playerID) end
		if SupporterRegenAura and SupporterRegenAura.Refresh then
			SupporterRegenAura:Refresh(hero)
		end
		-- Refresh active sources after clearing per-player overrides so their
		-- authored vanilla fallback is restored immediately. A full Cleanup
		-- would leave owner-only sources (for example Cloak with no current
		-- target) invisible until another gameplay hook reacquired them.
		if SupporterPassImmolation and SupporterPassImmolation.Refresh then
			SupporterPassImmolation:Refresh(hero)
		end
		if SupporterHighFive and SupporterHighFive.CleanupHero then
			SupporterHighFive:CleanupHero(hero, "rewards_disabled")
		end
		RefreshSupporterItemVisuals(hero)
		return
	end

	self:RegisterHeroTaunt(hero)
	self:GetHeroEffect(hero)

	local companion = self:GetEquippedSupporterItem(playerID, "companion")
	local companionUnit = companion and (
		companion.unit
		or companion.unit_name
		or companion.file
		or companion.item_id
		or companion.id
	) or ""
	if companionUnit == "" and api and api.GetPlayerCompanion then
		companionUnit = api:GetPlayerCompanion(playerID) or ""
	end
	self:DonatorCompanion(playerID, companionUnit, true)

	local emblem = self:GetEquippedSupporterItem(playerID, "emblem")
	if emblem == nil and api and api.GetPlayerEmblem then
		local particle = api:GetPlayerEmblem(playerID)
		if particle then emblem = { particle = particle } end
	end
	self:ApplySupporterEmblem(hero, emblem)

	local effigy = self:GetEquippedSupporterItem(playerID, "effigy")
	local effigyUnit = effigy and (effigy.unit or effigy.unit_name or effigy.file) or ""
	if effigyUnit == "" and api and api.GetPlayerStatue then
		effigyUnit = api:GetPlayerStatue(playerID) or ""
	end
	if effigyUnit ~= "" then
		self:DonatorStatue(playerID, effigyUnit, true)
	elseif self.RemoveDonatorStatue then
		self:RemoveDonatorStatue(playerID)
	end

	if SupporterRegenAura and SupporterRegenAura.Ensure then
		SupporterRegenAura:Ensure(hero)
		SupporterRegenAura:Refresh(hero)
	end
	if SupporterPassImmolation and SupporterPassImmolation.Refresh then
		SupporterPassImmolation:Refresh(hero)
	end
	RefreshSupporterItemVisuals(hero)
end

function Battlepass:PlaySupporterKillEffect(hero, victim, item)
	if hero == nil or victim == nil or item == nil or hero:IsNull() or victim:IsNull() then return false end
	local DROW_TARGET_ARROW_Z_OFFSET = -110

	local function PlayAttachedParticle(particleName, anchor, counterpart)
		if particleName == nil or particleName == "" or anchor == nil or anchor:IsNull() then return false end
		local anchorOrigin = anchor:GetAbsOrigin()
		local normalizedParticle = string.lower(tostring(particleName))
		local isDrowRevengeKillEffect =
			string.find(normalizedParticle, "/drow/drow_arcana/", 1, true) ~= nil
			and string.find(normalizedParticle, "revenge_kill_effect", 1, true) ~= nil
		local isDrowCaster = isDrowRevengeKillEffect
			and string.find(normalizedParticle, "_caster", 1, true) ~= nil
		local isRazorKillEffect =
			string.find(normalizedParticle, "/razor/razor_arcana/razor_arcana_kill_effect_", 1, true) ~= nil
		local isRazorCaster = isRazorKillEffect
			and string.find(normalizedParticle, "_caster", 1, true) ~= nil
		local isZeusKillEffect =
			string.find(normalizedParticle, "/zeus/arcana_chariot/zeus_arcana_kill_", 1, true) ~= nil
		local particle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, anchor)
		if particle == nil or particle < 0 then return false end

		ParticleManager:SetParticleControl(particle, 0, anchorOrigin)
		ParticleManager:SetParticleControlEnt(
			particle,
			0,
			anchor,
			PATTACH_POINT_FOLLOW,
			"attach_hitloc",
			anchorOrigin,
			true
		)
		if isDrowCaster then
			-- The Drow caster beam travels from CP1 above the caster to CP5,
			-- whose child operator derives the lower endpoint from CP0.
			ParticleManager:SetParticleControl(particle, 1, anchorOrigin + Vector(0, 0, 800))
			ParticleManager:SetParticleControl(particle, 5, anchorOrigin + Vector(0, 0, 600))
		elseif isDrowRevengeKillEffect then
			-- Both Drow styles emit their arrow models around CP1. Keep CP0 on the
			-- victim for smoke/impact, but lower CP1 so the arrows frame the hero.
			ParticleManager:SetParticleControl(
				particle,
				1,
				anchorOrigin + Vector(0, 0, DROW_TARGET_ARROW_Z_OFFSET)
			)
		elseif isZeusKillEffect then
			-- Zeus' complete remnant tree treats CP1 as the victim origin.
			ParticleManager:SetParticleControlEnt(
				particle,
				1,
				anchor,
				PATTACH_ABSORIGIN_FOLLOW,
				"",
				anchorOrigin,
				true
			)
		elseif isRazorCaster then
			-- Razor's caster parent/beam use CP2 at the caster and CP5 overhead.
			ParticleManager:SetParticleControlEnt(
				particle, 2, anchor, PATTACH_ABSORIGIN_FOLLOW, "", anchorOrigin, true
			)
			ParticleManager:SetParticleControl(particle, 5, anchorOrigin + Vector(20, 0, 650))
		elseif isRazorKillEffect then
			-- Razor's target lightning uses CP1/CP5 at the victim and CP6 above it.
			ParticleManager:SetParticleControlEnt(
				particle, 1, anchor, PATTACH_ABSORIGIN_FOLLOW, "", anchorOrigin, true
			)
			ParticleManager:SetParticleControlEnt(
				particle, 5, anchor, PATTACH_ABSORIGIN_FOLLOW, "", anchorOrigin, true
			)
			ParticleManager:SetParticleControl(particle, 6, anchorOrigin + Vector(0, 0, 1000))
		elseif counterpart ~= nil and not counterpart:IsNull() then
			ParticleManager:SetParticleControlEnt(
				particle,
				1,
				counterpart,
				PATTACH_POINT_FOLLOW,
				"attach_hitloc",
				counterpart:GetAbsOrigin(),
				true
			)
		end
		ParticleManager:ReleaseParticleIndex(particle)

		-- if IsInToolsMode() then
		-- 	print("[Supporter Pass] Played kill FX:", particleName, "particle:", particle)
		-- end

		return true
	end

	local played = false
	local targetParticle = item.target_pfx or self:GetSupporterItemParticle(item, "particles/kill_effect/default_target.vpcf")
	played = PlayAttachedParticle(targetParticle, victim, hero) or played

	local casterParticle = item.caster_pfx or self:GetSupporterItemParticle(item, "particles/kill_effect/default_caster.vpcf")
	played = PlayAttachedParticle(casterParticle, hero, victim) or played
	if IsInToolsMode() and not played then
		print("[Supporter Pass] No kill FX resolved for item:", tostring(item.item_id or item.id or "?"))
	end
	return played
end

function Battlepass:OnSupporterPassEntityKilled(event)
	local victim = event.entindex_killed and EntIndexToHScript(event.entindex_killed) or nil
	local attacker = event.entindex_attacker and EntIndexToHScript(event.entindex_attacker) or nil
	if victim == nil or victim:IsNull() then return end
	if victim.xhs_supporter_dev_test_target == true then
		local preview = victim.xhs_supporter_dev_test_kill_effect
		if type(preview) == "table"
			and preview.played ~= true
			and preview.hero ~= nil
			and not preview.hero:IsNull()
			and type(preview.item) == "table" then
			preview.played = true
			local visible = self:PlaySupporterKillEffect(preview.hero, victim, preview.item)
			if visible == true and type(preview.on_visible) == "function" then
				preview.on_visible()
			end
		end
		return
	end
	if attacker == nil or attacker:IsNull() then return end
	if victim.IsIllusion and victim:IsIllusion() then return end
	if attacker.IsIllusion and attacker:IsIllusion() then return end

	local hero = attacker
	if not hero:IsRealHero() and attacker.GetOwnerEntity then
		local owner = attacker:GetOwnerEntity()
		if owner and owner.IsRealHero and owner:IsRealHero() then
			hero = owner
		end
	end
	if not hero:IsRealHero() then return end
	if victim.GetTeamNumber and victim:GetTeamNumber() == hero:GetTeamNumber() then return end

	local playerID = hero:GetPlayerOwnerID()
	if not PlayerResource:IsValidPlayerID(playerID) or not self:AreSupporterRewardsEnabled(playerID) then return end
	local item = self:GetEquippedSupporterItem(playerID, "kill_effect")
	if item == nil then return end
	self:PlaySupporterKillEffect(hero, victim, item)
end

local SUPPORTER_DEV_TEST_SLOTS = {
	teleport = true,
	levelup = true,
	kill_effect = true,
	emblem = true,
	companion = true,
	effigy = true,
	potion = true,
	rebirth = true,
	attack_lifesteal = true,
	spell_lifesteal = true,
	regen_aura = true,
	immolation = true,
	high_five = true,
	title = true,
}

function Battlepass:IsSupporterDevTestAllowed(playerID)
	return IsInToolsMode()
		and api ~= nil
		and api.IsDeveloper ~= nil
		and api:IsDeveloper(playerID)
end

function Battlepass:SendSupporterDevTestResult(playerID, requestID, itemID, slot, status, message)
	if not PlayerResource:IsValidPlayerID(playerID) then return end
	local player = PlayerResource:GetPlayer(playerID)
	if player == nil then return end
	CustomGameEventManager:Send_ServerToPlayer(player, "supporter_pass_dev_test_result", {
		request_id = tostring(requestID or ""),
		item_id = tostring(itemID or ""),
		slot_id = tostring(slot or ""),
		status = tostring(status or "error"),
		message = message,
	})
end

function Battlepass:ResolveSupporterDevTestItem(itemID, requestedSlot)
	if itemID == nil or tostring(itemID) == "" then return nil end
	local expectedSlot = NormalizeSupporterSlot(requestedSlot)
	local item = nil

	local catalogs = {
		companion = api and api.companions or {},
		emblem = api and api.emblems or {},
		effigy = api and (api.effigies or api.statues) or {},
	}
	if catalogs[expectedSlot] ~= nil then
		for _, cosmetic in pairs(catalogs[expectedSlot]) do
			if SupporterItemMatches(cosmetic, itemID) then
				item = CopySupporterItem(cosmetic)
				item.item_id = item.item_id or item.id or tostring(itemID)
				item.slot_id = expectedSlot
				item.type = expectedSlot
				break
			end
		end
	end

	-- Backend entitlement identifiers can be numeric and collide with legacy
	-- ItemsGame IDs, so only consult the historical catalog after the requested
	-- runtime slot catalog has had a chance to resolve the identity.
	local catalogItemID = itemID
	if SupporterPass2026 ~= nil and SupporterPass2026.ResolveCatalogID ~= nil then
		catalogItemID = SupporterPass2026:ResolveCatalogID(itemID) or itemID
	end
	if item == nil and ItemsGame ~= nil and ItemsGame.GetItemKV ~= nil
		and ItemsGame:GetItemKV(catalogItemID) ~= nil then
		local itemType = NormalizeSupporterSlot(ItemsGame:GetItemType(catalogItemID))
		local definition = ItemsGame:GetItemKV(catalogItemID)
		item = {
			id = tostring(itemID),
			item_id = tostring(catalogItemID),
			catalog_item_id = tostring(catalogItemID),
			name = ItemsGame:GetItemName(catalogItemID),
			type = itemType,
			item_type = itemType,
			slot_id = itemType,
			unit = ItemsGame:GetItemInfo(catalogItemID, "unit", "nope")
				or ItemsGame:GetItemInfo(catalogItemID, "unit_name", "nope")
				or ItemsGame:GetItemInfo(catalogItemID, "file", "nope"),
		}
		for key, value in pairs(definition or {}) do
			if key ~= "item_id" and (item[key] == nil or item[key] == "") then
				item[key] = value
			end
		end
	end

	if item == nil and expectedSlot == "companion" then
		local definitions = LoadKeyValues("scripts/npc/units/companions.txt") or {}
		if type(definitions[tostring(itemID)]) == "table" then
			item = { id = tostring(itemID), item_id = tostring(itemID), unit = tostring(itemID), type = expectedSlot, slot_id = expectedSlot }
		end
	elseif item == nil and expectedSlot == "effigy" then
		local definitions = LoadKeyValues("scripts/npc/units/statues.txt") or {}
		if type(definitions[tostring(itemID)]) == "table" then
			item = { id = tostring(itemID), item_id = tostring(itemID), unit = tostring(itemID), type = expectedSlot, slot_id = expectedSlot }
		end
	end

	if item == nil then return nil end
	local actualSlot = NormalizeSupporterSlot(item.slot_id or item.item_type or item.type)
	if expectedSlot ~= actualSlot or SUPPORTER_DEV_TEST_SLOTS[actualSlot] ~= true then return nil end
	item.slot_id = actualSlot
	if actualSlot == "companion" or actualSlot == "effigy" then
		item.unit = item.unit or item.unit_name or item.file or item.item_id
	elseif actualSlot == "emblem" then
		item.particle = item.particle or item.file
	end
	return self:HydrateSupporterRuntimeMetadata(item)
end

function Battlepass:CleanupSupporterDevTest(playerID, restoreLoadout)
	self.SUPPORTER_DEV_TESTS = self.SUPPORTER_DEV_TESTS or {}
	local state = self.SUPPORTER_DEV_TESTS[playerID]
	if state ~= nil then
		state.cancelled = true
		if state.timer ~= nil and Timers ~= nil then
			Timers:RemoveTimer(state.timer)
		end
		if state.hide_target_timer ~= nil and Timers ~= nil then
			Timers:RemoveTimer(state.hide_target_timer)
		end
		if state.attack_lifesteal_hit_timer ~= nil and Timers ~= nil then
			Timers:RemoveTimer(state.attack_lifesteal_hit_timer)
		end
		if state.attack_lifesteal_kill_timer ~= nil and Timers ~= nil then
			Timers:RemoveTimer(state.attack_lifesteal_kill_timer)
		end
		if state.kill_effect_kill_timer ~= nil and Timers ~= nil then
			Timers:RemoveTimer(state.kill_effect_kill_timer)
		end
		if state.target ~= nil and not state.target:IsNull() then
			UTIL_Remove(state.target)
		end
		for _, particle in ipairs(state.particles or {}) do
			ParticleManager:DestroyParticle(particle, true)
			ParticleManager:ReleaseParticleIndex(particle)
		end
	end
	self.SUPPORTER_DEV_TESTS[playerID] = nil

	local hero = PlayerResource:GetSelectedHeroEntity(playerID)
	self:ClearSupporterOverrides(playerID)
	if hero ~= nil and not hero:IsNull() then
		self:ApplySupporterEmblem(hero, nil)
	end
	self:DonatorCompanion(playerID, "", true)
	if self.RemoveDonatorStatue then self:RemoveDonatorStatue(playerID) end
	if restoreLoadout ~= false then
		self:ApplySupporterLoadout(playerID, hero)
	end
end

function Battlepass:ApplySupporterDevTestItem(playerID, state, hero, reapply)
	if state == nil or hero == nil or hero:IsNull() then return false, "#xhs_sp_dev_test_error_hero" end
	local item = state.item
	local slot = state.slot

	if slot == "emblem" then
		local particle = item.particle or item.pfx or item.file or self:GetSupporterItemParticle(item, "particles/hero_emblem/default.vpcf")
		if particle == nil or particle == "" then return false, "#xhs_sp_dev_test_error_asset" end
		item.particle = particle
		self:ApplySupporterEmblem(hero, item)
		return true
	elseif slot == "companion" then
		local unitName = tostring(item.unit or "")
		local definitions = LoadKeyValues("scripts/npc/units/companions.txt") or {}
		if type(definitions[unitName]) ~= "table" then return false, "#xhs_sp_dev_test_error_item" end
		self:DonatorCompanion(playerID, unitName, true)
		return true
	elseif slot == "effigy" then
		local unitName = tostring(item.unit or "")
		local definitions = LoadKeyValues("scripts/npc/units/statues.txt") or {}
		if type(definitions[unitName]) ~= "table" then return false, "#xhs_sp_dev_test_error_item" end
		local previewOrigin = hero:GetAbsOrigin() + hero:GetForwardVector() * 280
		self:DonatorStatue(playerID, unitName, true, previewOrigin)
		if Notifications ~= nil and Notifications.Bottom ~= nil then
			Notifications:Bottom(playerID, {
				text = "[Battle Pass] Effigy preview spawned in front of your hero.",
				duration = 3.0,
				severity = "system",
			})
		end
		return true
	end

	if reapply == true then return true end
	if slot == "teleport"
		or slot == "levelup"
		or slot == "potion"
		or slot == "rebirth"
		or slot == "attack_lifesteal"
		or slot == "spell_lifesteal"
		or slot == "regen_aura"
		or slot == "immolation" then
		self:ApplySupporterPlayerParticleItem(playerID, slot, item)
	end

	local function CreatePreviewTarget(invulnerable)
		local target = CreateUnitByName(
			"npc_dota_creep_badguys_melee",
			hero:GetAbsOrigin() + hero:GetForwardVector() * 220,
			false,
			hero,
			hero,
			DOTA_TEAM_BADGUYS
		)
		if target == nil then return nil end
		target.xhs_supporter_dev_test_target = true
		if invulnerable ~= false then
			target:AddNewModifier(target, nil, "modifier_invulnerable", {})
		end
		target:AddNewModifier(target, nil, "modifier_command_restricted", {})
		target:AddNewModifier(target, nil, "modifier_phased", {})
		state.target = target
		return target
	end

	local function TrackParticle(particle)
		if particle == nil or particle < 0 then return false end
		state.particles = state.particles or {}
		table.insert(state.particles, particle)
		return true
	end

	local function NotifyPotionChannel(channel)
		local payload = {
			text = string.format(
				"[Battle Pass] %s POTION - %s (#%s)",
				string.upper(channel),
				tostring(item.name or item.item_name or "Potion bundle"),
				tostring(state.item_id or item.item_id or "")
			),
			duration = 1.2,
			severity = "system",
		}
		if Notifications ~= nil and Notifications.Bottom ~= nil then
			Notifications:Bottom(playerID, payload)
			return
		end
		local player = PlayerResource:GetPlayer(playerID)
		if player ~= nil then
			CustomGameEventManager:Send_ServerToPlayer(player, "bottom_notification", payload)
		end
	end

	if slot == "teleport" then
		if state.content_studio == true then
			local startParticleName = item.start_pfx
			local endParticleName = item.end_pfx
			if startParticleName == nil or startParticleName == ""
				or endParticleName == nil or endParticleName == "" then
				return false, "#xhs_sp_dev_test_error_asset"
			end
			local origin = hero:GetAbsOrigin()
			local destination = origin + hero:GetForwardVector() * 280
			local startParticle = ParticleManager:CreateParticle(startParticleName, PATTACH_ABSORIGIN, hero)
			local endParticle = ParticleManager:CreateParticle(endParticleName, PATTACH_WORLDORIGIN, nil)
			if startParticle == nil or startParticle < 0 or endParticle == nil or endParticle < 0 then
				if startParticle ~= nil and startParticle >= 0 then
					ParticleManager:DestroyParticle(startParticle, true)
					ParticleManager:ReleaseParticleIndex(startParticle)
				end
				if endParticle ~= nil and endParticle >= 0 then
					ParticleManager:DestroyParticle(endParticle, true)
					ParticleManager:ReleaseParticleIndex(endParticle)
				end
				return false, "#xhs_sp_dev_test_error_asset"
			end
			ParticleManager:SetParticleControlEnt(startParticle, 0, hero, PATTACH_ABSORIGIN, "attach_origin", origin, true)
			ParticleManager:SetParticleControl(startParticle, 7, Vector(3.0, 0, 0))
			ParticleManager:SetParticleControl(endParticle, 0, destination)
			ParticleManager:SetParticleControl(endParticle, 1, destination)
			return TrackParticle(startParticle) and TrackParticle(endParticle)
		end
		local respawn = BASE_GOOD
		if respawn == nil or respawn:IsNull() then
			respawn = Entities:FindByName(nil, "base_spawn")
		end
		if respawn == nil then return false, "#xhs_sp_dev_test_error_respawn" end
		TeleportHero(hero, respawn:GetAbsOrigin(), 3.0, 1.0)
		return true
	elseif slot == "levelup" then
		local particlePath = self:GetPlayerParticle(
			hero,
			"levelup_pfx",
			"particles/generic_hero_status/hero_levelup.vpcf"
		)
		local particle = ParticleManager:CreateParticle(particlePath, PATTACH_ABSORIGIN_FOLLOW, hero)
		ParticleManager:SetParticleControl(particle, 0, hero:GetAbsOrigin())
		XHSDestroyParticleAfter(particle, 1.5, false)
		hero:EmitSound("ui.trophy_levelup")
		return true
	elseif slot == "kill_effect" then
		local target = CreatePreviewTarget(false)
		if target == nil then return false, "#xhs_sp_dev_test_error_target" end

		target:SetBaseMaxHealth(1)
		target:SetMaxHealth(1)
		target:SetHealth(1)
		target.xhs_supporter_dev_test_kill_effect = {
			hero = hero,
			item = item,
			played = false,
			on_visible = state.on_visible,
		}

		state.kill_effect_kill_timer = Timers:CreateTimer(3.0, function()
			state.kill_effect_kill_timer = nil
			if self.SUPPORTER_DEV_TESTS[playerID] == state
				and state.cancelled ~= true
				and target ~= nil
				and not target:IsNull()
				and target:IsAlive() then
				target:ForceKill(false)
			end
			return nil
		end)

		ExecuteOrderFromTable({
			UnitIndex = hero:entindex(),
			OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
			TargetIndex = target:entindex(),
			Queue = false,
		})
		return true
	elseif slot == "potion" then
		if SupporterRecoveryEffects == nil then return false, "#xhs_sp_dev_test_error_asset" end
		local channel = state.preview_channel
		if channel ~= "health" and channel ~= "mana" and channel ~= "light" then
			return false, "#xhs_sp_dev_test_error_type"
		end
		NotifyPotionChannel(channel)
		return SupporterRecoveryEffects:PlayPotion(
			hero,
			channel,
			item[channel .. "_pfx"]
		) ~= nil
	elseif slot == "rebirth" then
		if SupporterRecoveryEffects == nil then return false, "#xhs_sp_dev_test_error_asset" end
		if state.content_studio == true then
			local particle = SupporterRecoveryEffects:PlayRebirth(hero, item.pfx, {
				externally_managed = true,
			})
			return TrackParticle(particle)
		end
		return SupporterRecoveryEffects:PlayRebirth(hero, item.pfx) ~= nil
	elseif slot == "attack_lifesteal" or slot == "spell_lifesteal" then
		local target = CreatePreviewTarget(slot ~= "attack_lifesteal")
		if target == nil then return false, "#xhs_sp_dev_test_error_target" end
		if slot == "attack_lifesteal" and XHSPlaySupporterAttackLifestealFX ~= nil then
			-- Keep the preview creep alive long enough to show a real attack,
			-- then play the selected cosmetic on the first damage it receives.
			local previewHealth = 1000000000
			target:SetBaseMaxHealth(previewHealth)
			target:SetMaxHealth(previewHealth)
			target:SetHealth(previewHealth)

			local startingHealth = target:GetHealth()
			local hitDeadline = GameRules:GetGameTime() + 2.95
			state.attack_lifesteal_hit_timer = Timers:CreateTimer(0.03, function()
				if self.SUPPORTER_DEV_TESTS[playerID] ~= state
					or state.cancelled == true
					or target == nil
					or target:IsNull()
					or not target:IsAlive() then
					state.attack_lifesteal_hit_timer = nil
					return nil
				end

				if target:GetHealth() < startingHealth then
					state.attack_lifesteal_hit_timer = nil
					if state.content_studio == true and XHSPlaySupporterLifestealPreviewFX ~= nil then
						local visible = XHSPlaySupporterLifestealPreviewFX(hero, target, item.pfx)
						if visible == true and type(state.on_visible) == "function" then
							state.on_visible()
						end
					else
						XHSPlaySupporterAttackLifestealFX(
							hero,
							target,
							startingHealth - target:GetHealth()
						)
					end
					return nil
				end

				if GameRules:GetGameTime() >= hitDeadline then
					state.attack_lifesteal_hit_timer = nil
					return nil
				end
				return 0.03
			end)

			state.attack_lifesteal_kill_timer = Timers:CreateTimer(3.0, function()
				state.attack_lifesteal_kill_timer = nil
				if self.SUPPORTER_DEV_TESTS[playerID] == state
					and state.cancelled ~= true
					and target ~= nil
					and not target:IsNull()
					and target:IsAlive() then
					target:ForceKill(false)
				end
				return nil
			end)

			ExecuteOrderFromTable({
				UnitIndex = hero:entindex(),
				OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
				TargetIndex = target:entindex(),
				Queue = false,
			})
			return true
		elseif slot == "spell_lifesteal" and state.content_studio == true
			and XHSPlaySupporterLifestealPreviewFX ~= nil then
			return XHSPlaySupporterLifestealPreviewFX(hero, target, item.pfx) == true
		elseif slot == "spell_lifesteal" and XHSPlaySupporterLifestealFX ~= nil then
			return XHSPlaySupporterLifestealFX(hero, target, "spell", 1) == true
		end
		return false, "#xhs_sp_dev_test_error_asset"
	elseif slot == "regen_aura" then
		local particleName = item.pfx or self:GetSupporterItemParticle(
			item,
			SupporterPass2026.ANCHORS.regen_aura
		)
		if particleName == nil then return false, "#xhs_sp_dev_test_error_asset" end
		local particle = ParticleManager:CreateParticle(
			particleName,
			PATTACH_ABSORIGIN_FOLLOW,
			hero
		)
		if particle == nil or particle < 0 then
			return false, "#xhs_sp_dev_test_error_asset"
		end
		ParticleManager:SetParticleControlEnt(
			particle,
			0,
			hero,
			PATTACH_ABSORIGIN_FOLLOW,
			"attach_hitloc",
			hero:GetAbsOrigin(),
			true
		)
		return TrackParticle(particle)
	elseif slot == "immolation" then
		local target = CreatePreviewTarget()
		if target == nil then return false, "#xhs_sp_dev_test_error_target" end
		local ownerParticleName = item.owner_pfx or self:GetSupporterItemParticle(
			item,
			SupporterPass2026.ANCHORS.immolation_owner
		)
		local targetParticleName = item.target_pfx or self:GetSupporterItemParticle(
			item,
			SupporterPass2026.ANCHORS.immolation_target
		)
		if ownerParticleName == nil or targetParticleName == nil then
			return false, "#xhs_sp_dev_test_error_asset"
		end
		local ownerParticle = ParticleManager:CreateParticle(
			ownerParticleName,
			PATTACH_ABSORIGIN_FOLLOW,
			hero
		)
		local targetParticle = ParticleManager:CreateParticle(
			targetParticleName,
			PATTACH_ABSORIGIN_FOLLOW,
			target
		)
		if ownerParticle == nil or ownerParticle < 0
			or targetParticle == nil or targetParticle < 0 then
			if ownerParticle ~= nil and ownerParticle >= 0 then
				ParticleManager:DestroyParticle(ownerParticle, true)
				ParticleManager:ReleaseParticleIndex(ownerParticle)
			end
			if targetParticle ~= nil and targetParticle >= 0 then
				ParticleManager:DestroyParticle(targetParticle, true)
				ParticleManager:ReleaseParticleIndex(targetParticle)
			end
			return false, "#xhs_sp_dev_test_error_asset"
		end
		ParticleManager:SetParticleControl(ownerParticle, 0, hero:GetAbsOrigin())
		ParticleManager:SetParticleControl(targetParticle, 0, target:GetAbsOrigin())
		local ownerTracked = TrackParticle(ownerParticle)
		local targetTracked = TrackParticle(targetParticle)
		return ownerTracked and targetTracked
	elseif slot == "high_five" then
		if SupporterHighFive == nil then return false, "#xhs_sp_dev_test_error_asset" end
		local destination = hero:GetAbsOrigin() + hero:GetForwardVector() * 360
		local overhead = SupporterHighFive:CreateOverhead(hero, item.overhead_pfx)
		local travel = SupporterHighFive:CreateTravel(
			hero:GetAbsOrigin(),
			destination,
			item.travel_pfx
		)
		local overheadTracked = TrackParticle(overhead)
		local travelTracked = TrackParticle(travel)
		if not overheadTracked or not travelTracked then
			return false, "#xhs_sp_dev_test_error_asset"
		end
		Timers:CreateTimer(0.45, function()
			if self.SUPPORTER_DEV_TESTS[playerID] == state and state.cancelled ~= true then
				SupporterHighFive:CreateImpact(destination, item.impact_pfx)
			end
			return nil
		end)
		return true
	end
	return false, "#xhs_sp_dev_test_error_type"
end

function Battlepass:ReapplySupporterDevTest(playerID, hero)
	self.SUPPORTER_DEV_TESTS = self.SUPPORTER_DEV_TESTS or {}
	local state = self.SUPPORTER_DEV_TESTS[playerID]
	local allowed = self:IsSupporterDevTestAllowed(playerID)
		or (state ~= nil and state.trusted_devtools == true and IsInToolsMode())
	if state == nil or state.persistent ~= true or not allowed then return end
	self:ApplySupporterDevTestItem(playerID, state, hero, true)
end

function Battlepass:SupporterPassDevTestReward(event_source_index, event)
	event = self:GetSupporterPassEventPayload(event_source_index, event)
	local playerID = event.PlayerID
	if playerID == nil then return end
	local requestID = tostring(event.request_id or "")
	local itemID = tostring(event.item_id or "")
	local slot = NormalizeSupporterSlot(event.slot_id)
	local previewChannel = tostring(event.preview_channel or ""):lower()
	if slot ~= "potion"
		or (previewChannel ~= "health" and previewChannel ~= "mana" and previewChannel ~= "light") then
		previewChannel = nil
	end
	local trustedDevTools = event.xhs_devtools_trusted == true and IsInToolsMode()

	if not trustedDevTools and not self:IsSupporterDevTestAllowed(playerID) then
		self:SendSupporterDevTestResult(playerID, requestID, itemID, slot, "error", "#xhs_sp_dev_test_error_forbidden")
		return
	end
	if tostring(event.action or "") ~= "test" then
		self:SendSupporterDevTestResult(playerID, requestID, itemID, slot, "error", "#xhs_sp_dev_test_error_item")
		return
	end
	self.SUPPORTER_DEV_TEST_LAST_REQUEST = self.SUPPORTER_DEV_TEST_LAST_REQUEST or {}
	local now = GameRules:GetGameTime()
	if now - (self.SUPPORTER_DEV_TEST_LAST_REQUEST[playerID] or -10) < 0.35 then
		self:SendSupporterDevTestResult(playerID, requestID, itemID, slot, "error", "#xhs_sp_dev_test_error_rate")
		return
	end
	self.SUPPORTER_DEV_TEST_LAST_REQUEST[playerID] = now

	self.SUPPORTER_DEV_TESTS = self.SUPPORTER_DEV_TESTS or {}
	local previous = self.SUPPORTER_DEV_TESTS[playerID]
	if previous ~= nil and previous.transient == true then
		self:SendSupporterDevTestResult(playerID, requestID, itemID, slot, "error", "#xhs_sp_dev_test_error_busy")
		return
	end
	local item = self:ResolveSupporterDevTestItem(itemID, slot)
	if item == nil then
		self:SendSupporterDevTestResult(playerID, requestID, itemID, slot, "error", "#xhs_sp_dev_test_error_item")
		return
	end
	local hero = PlayerResource:GetSelectedHeroEntity(playerID)
	if hero == nil or hero:IsNull() then
		self:SendSupporterDevTestResult(playerID, requestID, itemID, slot, "error", "#xhs_sp_dev_test_error_hero")
		return
	end

	self:CleanupSupporterDevTest(playerID, true)
	local persistent = slot == "emblem" or slot == "companion" or slot == "effigy"
	local state = {
		item = item,
		item_id = itemID,
		slot = slot,
		preview_channel = previewChannel,
		request_id = requestID,
		persistent = persistent,
		transient = not persistent,
		trusted_devtools = trustedDevTools,
	}
	self.SUPPORTER_DEV_TESTS[playerID] = state
	state.timer = Timers:CreateTimer(0.5, function()
		if self.SUPPORTER_DEV_TESTS[playerID] ~= state or state.cancelled == true then return nil end
		state.timer = nil
		local currentHero = PlayerResource:GetSelectedHeroEntity(playerID)
		local success, message = self:ApplySupporterDevTestItem(playerID, state, currentHero, false)
		if not success then
			self:CleanupSupporterDevTest(playerID, true)
			self:SendSupporterDevTestResult(playerID, requestID, itemID, slot, "error", message)
			return nil
		end

		self:SendSupporterDevTestResult(playerID, requestID, itemID, slot, "active", "#xhs_sp_dev_test_active")
		if not persistent then
			local duration = 1.8
			if slot == "teleport" then
				duration = 3.6
			elseif slot == "kill_effect" then
				duration = 3.5
			elseif slot == "attack_lifesteal" then
				duration = 3.25
			elseif slot == "potion" then
				duration = 5.5
			elseif slot == "regen_aura"
				or slot == "immolation"
				or slot == "high_five" then
				duration = 3.0
			end
			state.timer = Timers:CreateTimer(duration, function()
				if self.SUPPORTER_DEV_TESTS[playerID] == state then
					self:CleanupSupporterDevTest(playerID, true)
					self:SendSupporterDevTestResult(playerID, requestID, itemID, slot, "success", "#xhs_sp_dev_test_success")
				end
				return nil
			end)
		end
		return nil
	end)
end

function Battlepass:SupporterPassDevStopTest(event_source_index, event)
	event = self:GetSupporterPassEventPayload(event_source_index, event)
	local playerID = event.PlayerID
	if playerID == nil then return end
	local requestID = tostring(event.request_id or "")
	if not self:IsSupporterDevTestAllowed(playerID) then
		self:SendSupporterDevTestResult(playerID, requestID, "", "", "error", "#xhs_sp_dev_test_error_forbidden")
		return
	end
	if tostring(event.action or "") ~= "stop" then
		self:SendSupporterDevTestResult(playerID, requestID, "", "", "error", "#xhs_sp_dev_test_error_item")
		return
	end
	self:CleanupSupporterDevTest(playerID, true)
	self:SendSupporterDevTestResult(playerID, requestID, "", "", "idle", "#xhs_sp_dev_test_stopped")
end

local SUPPORTER_PUBLIC_PREVIEW_SLOTS = {
	teleport = true,
	levelup = true,
	kill_effect = true,
	emblem = true,
	companion = true,
	potion = true,
	rebirth = true,
	attack_lifesteal = true,
	spell_lifesteal = true,
	regen_aura = true,
	immolation = true,
	high_five = true,
}

local function IsSupporterPreviewPublished(value)
	if value == true or value == 1 then return true end
	local normalized = string.lower(tostring(value or ""))
	return normalized == "true" or normalized == "1"
end

local function IsSupporterPreviewExplicitlyUnpublished(value)
	if value == false or value == 0 then return true end
	local normalized = string.lower(tostring(value or ""))
	return normalized == "false" or normalized == "0"
end

local function CountSupporterPreviewHumans()
	local count = 0
	local maximumPlayers = DOTA_MAX_TEAM_PLAYERS or 24
	for candidateID = 0, maximumPlayers - 1 do
		if PlayerResource:IsValidPlayerID(candidateID) then
			local fake = false
			if PlayerResource.IsFakeClient ~= nil then
				local ok, result = pcall(function()
					return PlayerResource:IsFakeClient(candidateID)
				end)
				fake = ok and result == true
			end
			if not fake then count = count + 1 end
		end
	end
	return count
end

function Battlepass:IsSupporterCatalogPreviewMapAllowed()
	local mapName = GetMapName ~= nil and string.lower(GetMapName() or "") or ""
	return mapName == "x_hero_siege_demo" or CountSupporterPreviewHumans() == 1
end

function Battlepass:SendSupporterCatalogPreviewResult(playerID, payload)
	if playerID == nil or not PlayerResource:IsValidPlayerID(playerID) then return end
	local player = PlayerResource:GetPlayer(playerID)
	if player == nil then return end
	CustomGameEventManager:Send_ServerToPlayer(
		player,
		"supporter_pass_catalog_preview_result",
		payload or {}
	)
end

function Battlepass:ResolveSupporterCatalogPreviewItem(itemID)
	local source = self:FindSupporterPassRuntimeCatalogItem(itemID)
	if type(source) ~= "table" then return nil, "#xhs_sp_dev_test_error_item" end
	local parentItemID = tostring(source.parent_item_id or "")
	local isBundleComponent = parentItemID ~= ""
	if isBundleComponent
		and (IsSupporterPreviewExplicitlyUnpublished(source.active)
			or IsSupporterPreviewExplicitlyUnpublished(source.is_published)) then
		return nil, "#xhs_sp_dev_test_error_item"
	end
	local ownPublicationProven = IsSupporterPreviewPublished(source.active)
		and IsSupporterPreviewPublished(source.is_published)
	local parentPublicationProven = isBundleComponent
		and IsSupporterPreviewPublished(source.parent_active)
		and IsSupporterPreviewPublished(source.parent_is_published)
		and tostring(source.parent_release_id or "") ~= ""
		and string.lower(tostring(source.parent_release_status or "")) == "published"
	local rootPublicationProven = not isBundleComponent
		and ownPublicationProven
		and tostring(source.release_id or "") ~= ""
		and string.lower(tostring(source.publication_status or "")) == "published"
	if not rootPublicationProven
		and not (isBundleComponent and (ownPublicationProven or parentPublicationProven)) then
		return nil, "#xhs_sp_dev_test_error_item"
	end
	local runtimeStatus = string.lower(tostring(source.runtime_status or source.status or ""))
	if runtimeStatus ~= "ready" and runtimeStatus ~= "available" then
		return nil, "#xhs_sp_dev_test_error_asset"
	end
	local item = CopySupporterItem(source)
	item.item_id = item.item_id or item.catalog_item_id or item.id or tostring(itemID)
	item.slot_id = NormalizeSupporterSlot(
		item.slot_id or item.item_type or item.type or item.category
	)
	if tostring(item.item_type or item.type or ""):lower() == "bundle"
		or SUPPORTER_PUBLIC_PREVIEW_SLOTS[item.slot_id] ~= true then
		return nil, "#xhs_sp_dev_test_error_type"
	end
	if item.slot_id == "high_five" and not isBundleComponent then
		return nil, "#xhs_sp_dev_test_error_type"
	end
	item = self:HydrateSupporterRuntimeMetadata(item)
	if item.runtime_manifest_blocked == true then
		return nil, "#xhs_sp_dev_test_error_asset"
	end
	return item, nil
end

local function SupporterCatalogPreviewDuration(slot)
	if slot == "teleport" then return 3.6 end
	if slot == "kill_effect" then return 3.5 end
	if slot == "attack_lifesteal" then return 3.25 end
	if slot == "potion" then return 5.5 end
	if slot == "emblem" or slot == "companion" then return 8.0 end
	if slot == "regen_aura" or slot == "immolation" or slot == "high_five" then return 3.0 end
	return 1.8
end

function Battlepass:SupporterPassCatalogPreview(event_source_index, event)
	event = self:GetSupporterPassEventPayload(event_source_index, event)
	local playerID = event.PlayerID
	if playerID == nil then return end
	local requestID = string.gsub(tostring(event.request_id or ""), "[%c]", ""):sub(1, 96)
	local itemID = string.gsub(tostring(event.item_id or ""), "[%c]", ""):sub(1, 96)
	local function Reply(status, message, slot, expiresIn)
		self:SendSupporterCatalogPreviewResult(playerID, {
			request_id = requestID,
			item_id = itemID,
			slot_id = slot or "",
			status = status,
			message = message,
			expires_in = tonumber(expiresIn) or 0,
		})
	end

	if tostring(event.action or "") ~= "preview"
		or itemID == ""
		or string.match(itemID, "^[%w_:%-%.]+$") == nil then
		return Reply("error", "#xhs_sp_dev_test_error_item")
	end
	if not self:IsSupporterCatalogPreviewMapAllowed() then
		return Reply(
			"error",
			"Preview is available on the demo map, or on a normal map with exactly one human player."
		)
	end
	self.SupporterCatalogPreviewLastRequest = self.SupporterCatalogPreviewLastRequest or {}
	local now = GameRules:GetGameTime()
	if now - (self.SupporterCatalogPreviewLastRequest[playerID] or -10) < 0.35 then
		return Reply("error", "#xhs_sp_dev_test_error_rate")
	end
	self.SupporterCatalogPreviewLastRequest[playerID] = now

	local item, message = self:ResolveSupporterCatalogPreviewItem(itemID)
	if item == nil then return Reply("error", message) end
	local slot = item.slot_id
	local hero = PlayerResource:GetSelectedHeroEntity(playerID)
	if hero == nil or hero:IsNull() then
		return Reply("error", "#xhs_sp_dev_test_error_hero", slot)
	end

	self.SUPPORTER_DEV_TESTS = self.SUPPORTER_DEV_TESTS or {}
	local existing = self.SUPPORTER_DEV_TESTS[playerID]
	if type(existing) == "table" and existing.public_catalog_preview ~= true then
		return Reply("error", "#xhs_sp_dev_test_error_busy", slot)
	end
	self:CleanupSupporterDevTest(playerID, true)
	local previewChannel = nil
	if slot == "potion" then
		for _, channel in ipairs({ "health", "mana", "light" }) do
			if IsSupporterRuntimeParticlePath(item[channel .. "_pfx"]) then
				previewChannel = channel
				break
			end
		end
	end
	local duration = SupporterCatalogPreviewDuration(slot)
	local state = {
		item = item,
		item_id = itemID,
		slot = slot,
		preview_channel = previewChannel,
		request_id = requestID,
		persistent = false,
		transient = true,
		public_catalog_preview = true,
	}
	self.SUPPORTER_DEV_TESTS[playerID] = state
	Reply("pending", nil, slot, duration)
	state.timer = Timers:CreateTimer(0.25, function()
		if self.SUPPORTER_DEV_TESTS[playerID] ~= state or state.cancelled == true then return nil end
		state.timer = nil
		local currentHero = PlayerResource:GetSelectedHeroEntity(playerID)
		local success, applyMessage = self:ApplySupporterDevTestItem(
			playerID,
			state,
			currentHero,
			false
		)
		if not success then
			self:CleanupSupporterDevTest(playerID, true)
			Reply("error", applyMessage, slot)
			return nil
		end
		Reply("active", "#xhs_sp_dev_test_active", slot, duration)
		state.timer = Timers:CreateTimer(duration, function()
			if self.SUPPORTER_DEV_TESTS[playerID] == state then
				self:CleanupSupporterDevTest(playerID, true)
				Reply("success", "#xhs_sp_dev_test_success", slot)
			end
			return nil
		end)
		return nil
	end)
end

function Battlepass:SupporterPassCatalogPreviewStop(event_source_index, event)
	event = self:GetSupporterPassEventPayload(event_source_index, event)
	local playerID = event.PlayerID
	if playerID == nil then return end
	local requestID = tostring(event.request_id or ""):sub(1, 96)
	if tostring(event.action or "") ~= "stop" then
		return self:SendSupporterCatalogPreviewResult(playerID, {
			request_id = requestID,
			status = "error",
			message = "#xhs_sp_dev_test_error_item",
		})
	end
	local state = self.SUPPORTER_DEV_TESTS and self.SUPPORTER_DEV_TESTS[playerID] or nil
	if type(state) == "table" and state.public_catalog_preview == true then
		self:CleanupSupporterDevTest(playerID, true)
	end
	self:SendSupporterCatalogPreviewResult(playerID, {
		request_id = requestID,
		item_id = type(state) == "table" and state.item_id or "",
		slot_id = type(state) == "table" and state.slot or "",
		status = "idle",
		message = "#xhs_sp_dev_test_stopped",
		expires_in = 0,
	})
end

function Battlepass:SendSupporterDevLocalEquipResult(playerID, itemID, slot, action, success, message)
	if not PlayerResource:IsValidPlayerID(playerID) then return end
	local player = PlayerResource:GetPlayer(playerID)
	if player == nil then return end
	CustomGameEventManager:Send_ServerToPlayer(player, "supporter_pass_dev_equip_local_result", {
		item_id = tostring(itemID or ""),
		slot_id = tostring(slot or ""),
		action = tostring(action or "equip"),
		success = success == true,
		message = message,
	})
end

function Battlepass:SupporterPassDevEquipLocal(event_source_index, event)
	event = self:GetSupporterPassEventPayload(event_source_index, event)
	local playerID = event.PlayerID
	if playerID == nil then return end
	local action = tostring(event.action or "equip"):lower()
	local itemID = tostring(event.item_id or "")
	local slot = NormalizeSupporterSlot(event.slot_id)

	if not self:IsSupporterDevTestAllowed(playerID) then
		self:SendSupporterDevLocalEquipResult(playerID, itemID, slot, action, false, "#xhs_sp_dev_test_error_forbidden")
		return
	end

	self.SUPPORTER_DEV_LOCAL_LOADOUTS = self.SUPPORTER_DEV_LOCAL_LOADOUTS or {}
	if action == "clear" then
		self.SUPPORTER_DEV_LOCAL_LOADOUTS[playerID] = nil
		self:CleanupSupporterDevTest(playerID, false)
		self:ApplySupporterLoadout(playerID)
		if SupporterPass and SupporterPass.PublishPlayer then
			SupporterPass:PublishPlayer(playerID)
		end
		self:SendSupporterDevLocalEquipResult(playerID, "", "", action, true)
		return
	end
	if action == "unequip_all" then
		local loadout = {}
		for supportedSlot, _ in pairs(SUPPORTER_DEV_TEST_SLOTS) do
			loadout[supportedSlot] = false
		end
		self.SUPPORTER_DEV_LOCAL_LOADOUTS[playerID] = loadout
		self:CleanupSupporterDevTest(playerID, false)
		self:ApplySupporterLoadout(playerID)
		if SupporterPass and SupporterPass.PublishPlayer then
			SupporterPass:PublishPlayer(playerID)
		end
		self:SendSupporterDevLocalEquipResult(playerID, "", "all", action, true)
		return
	end
	if action == "unequip" and SUPPORTER_DEV_TEST_SLOTS[slot] == true then
		local loadout = self.SUPPORTER_DEV_LOCAL_LOADOUTS[playerID] or {}
		loadout[slot] = false
		self.SUPPORTER_DEV_LOCAL_LOADOUTS[playerID] = loadout
		self:CleanupSupporterDevTest(playerID, false)
		self:ApplySupporterLoadout(playerID)
		if SupporterPass and SupporterPass.PublishPlayer then
			SupporterPass:PublishPlayer(playerID)
		end
		self:SendSupporterDevLocalEquipResult(playerID, "", slot, action, true)
		return
	end

	if action ~= "equip" or itemID == "" or SUPPORTER_DEV_TEST_SLOTS[slot] ~= true then
		self:SendSupporterDevLocalEquipResult(playerID, itemID, slot, action, false, "#xhs_sp_dev_test_error_item")
		return
	end

	local item = self:ResolveSupporterDevTestItem(itemID, slot)
	if item == nil then
		self:SendSupporterDevLocalEquipResult(playerID, itemID, slot, action, false, "#xhs_sp_dev_test_error_item")
		return
	end

	local loadout = self.SUPPORTER_DEV_LOCAL_LOADOUTS[playerID] or {}
	loadout[slot] = CopySupporterItem(item)
	self.SUPPORTER_DEV_LOCAL_LOADOUTS[playerID] = loadout

	-- Remove any transient one-shot preview, then apply the complete local
	-- loadout so persistent sources and already-held item icons refresh now.
	self:CleanupSupporterDevTest(playerID, false)
	self:ApplySupporterLoadout(playerID)
	if SupporterPass and SupporterPass.PublishPlayer then
		SupporterPass:PublishPlayer(playerID)
	end
	self:SendSupporterDevLocalEquipResult(playerID, itemID, slot, action, true)
end

function Battlepass:ResolveSupporterUnitSelection(playerID, unitName, expectedSlot)
	unitName = tostring(unitName or "")
	local slot = NormalizeSupporterSlot(expectedSlot)
	if unitName == "" or (slot ~= "companion" and slot ~= "effigy") then return nil end

	local item = self:ResolveSupporterItem(playerID, unitName, slot)

	-- Historical unit selectors sent the unit name rather than the catalog ID.
	-- Preserve those unlocked rewards by resolving the old catalog locally,
	-- while never falling back from a season-2026 definition to level access.
	if item == nil and ItemsGame ~= nil and type(ItemsGame.custom_kv) == "table" then
		for catalogID, definition in pairs(ItemsGame.custom_kv) do
			if type(definition) == "table"
				and NormalizeSupporterSlot(
					definition.slot_id or definition.item_type or definition.type
				) == slot then
				local definitionUnit = definition.unit
					or definition.unit_name
					or definition.file
				if tostring(definitionUnit or "") == unitName then
					item = self:ResolveSupporterItem(
						playerID,
						tostring(catalogID),
						slot
					)
					break
				end
			end
		end
	end

	if type(item) ~= "table" then return nil end
	if NormalizeSupporterSlot(item.slot_id or item.item_type or item.type) ~= slot then
		return nil
	end

	local resolvedUnit = tostring(item.unit or item.unit_name or item.file or "")
	if resolvedUnit ~= unitName then return nil end

	local premiumFallback = tonumber(item.premium) == 1 and 1 or 0
	local requiredTier = RequiredSupporterTier(item, premiumFallback)
	local currentTier = SupporterPass ~= nil
		and SupporterPass.GetTierForPlayer ~= nil
		and SupporterPass:GetTierForPlayer(playerID)
		or 0
	if currentTier < requiredTier then return nil end
	return item
end

function Battlepass:DonatorCompanionJS(event_source_index, event)
	event = self:GetSupporterPassEventPayload(event_source_index, event)
	local playerID = event.PlayerID
	if playerID == nil then return end
	local unitName = tostring(event.unit or "")
	if unitName ~= "" then
		local companions = LoadKeyValues("scripts/npc/units/companions.txt") or {}
		local item = self:ResolveSupporterUnitSelection(
			playerID,
			unitName,
			"companion"
		)
		if type(companions[unitName]) ~= "table" or item == nil then
			self:SendSupporterPassFailure(playerID, "supporter_pass_equip_failed", "#xhs_sp_error_companion_unavailable", {
				item_id = unitName,
			})
			return
		end
	end
	Battlepass:DonatorCompanion(playerID, unitName, true)
end

function Battlepass:DonatorStatueJS(event_source_index, event)
	event = self:GetSupporterPassEventPayload(event_source_index, event)
	local playerID = event.PlayerID
	if playerID == nil then return end
	local unitName = tostring(event.unit or "")
	local statues = LoadKeyValues("scripts/npc/units/statues.txt") or {}
	if unitName == "" then
		if self.RemoveDonatorStatue then self:RemoveDonatorStatue(playerID) end
		return
	end
	local item = self:ResolveSupporterUnitSelection(
		playerID,
		unitName,
		"effigy"
	)
	if type(statues[unitName]) ~= "table" or item == nil then
		self:SendSupporterPassFailure(playerID, "supporter_pass_equip_failed", "#xhs_sp_error_effigy_unavailable", {
			item_id = unitName,
		})
		return
	end
	Battlepass:DonatorStatue(playerID, unitName, true)
end

function Battlepass:DonatorEmblemJS(event_source_index, event)
	event = self:GetSupporterPassEventPayload(event_source_index, event)
	local playerID = event.PlayerID
	if playerID == nil then return end
	local hero = PlayerResource:GetSelectedHeroEntity(playerID)
	local equipped = self:GetEquippedSupporterItem(playerID, "emblem")
	local expectedParticle = equipped and self:GetSupporterItemParticle(equipped, "particles/hero_emblem/default.vpcf") or ""
	if tostring(event.unit or "") ~= tostring(expectedParticle) then return end
	self:ApplySupporterEmblem(hero, equipped)
end

function Battlepass:DonatorCompanionSkinJS(event_source_index, event)
	event = self:GetSupporterPassEventPayload(event_source_index, event)
	if event.PlayerID == nil then return end
	DonatorCompanionSkin(event.PlayerID, event.unit, event.skin)
end

function Battlepass:GetSupporterPassEventPayload(event_source_index, event)
	local payload = event
	if type(event_source_index) == "table" and payload == nil then
		payload = event_source_index
	end
	if type(payload) ~= "table" then
		payload = {}
	end

	payload.PlayerID = nil
	local playerID = XHSResolveEventPlayerID ~= nil
		and XHSResolveEventPlayerID(event_source_index) or nil
	if playerID == nil and api ~= nil and api.GetEventPlayerID ~= nil then
		local ok, resolved = pcall(function()
			return api:GetEventPlayerID(event_source_index, nil)
		end)
		if ok then playerID = tonumber(resolved) end
	end

	local sourceIndex = tonumber(event_source_index)
	if playerID == nil and sourceIndex ~= nil and sourceIndex > 0 then
		local ok, sender = pcall(EntIndexToHScript, sourceIndex)
		if ok and sender ~= nil and sender.GetPlayerID then
			playerID = tonumber(sender:GetPlayerID())
		end
	end
	if playerID ~= nil and PlayerResource:IsValidPlayerID(playerID) then
		payload.PlayerID = playerID
	end

	return payload
end

function Battlepass:SendSupporterPassFailure(playerID, eventName, message, payload)
	if playerID == nil or not PlayerResource:IsValidPlayerID(playerID) then
		return
	end

	local player = PlayerResource:GetPlayer(playerID)
	if not player then
		return
	end

	payload = payload or {}
	payload.message = payload.message or message
	CustomGameEventManager:Send_ServerToPlayer(player, eventName, payload)
end

function Battlepass:GetSupporterCompanionModelSet()
	if self.SupporterCompanionModelSet ~= nil then
		return self.SupporterCompanionModelSet
	end

	self.SupporterCompanionModelSet = {}
	local companions = LoadKeyValues("scripts/npc/units/companions.txt") or {}
	for _, unit in pairs(companions) do
		if type(unit) == "table" and type(unit.Model) == "string" then
			self.SupporterCompanionModelSet[string.lower(unit.Model)] = true
		end
	end
	return self.SupporterCompanionModelSet
end

function Battlepass:GetCourierRequestModel(itemDef)
	if Wearable == nil or Wearable.items == nil or Wearable.asset_modifier == nil then
		return nil, nil
	end

	local key = tostring(itemDef or "")
	local item = Wearable.items[key]
	if type(item) ~= "table" or tostring(item.prefab or "") ~= "courier" then
		return nil, nil
	end

	local fallback = nil
	for _, modifier in pairs(Wearable.asset_modifier[key] or {}) do
		if type(modifier) == "table" and modifier.type == "courier" and type(modifier.modifier) == "string" then
			fallback = fallback or modifier.modifier
			if modifier.asset == "radiant" and (modifier.style == nil or tostring(modifier.style) == "0") then
				return modifier.modifier, item
			end
		end
	end
	return fallback, item
end

function Battlepass:GetSupporterEffigyUnitSet(category)
	self.SupporterEffigyUnitSets = self.SupporterEffigyUnitSets or {}
	if self.SupporterEffigyUnitSets[category] ~= nil then
		return self.SupporterEffigyUnitSets[category]
	end

	local units = {}
	if category == "hero" then
		for _, heroName in pairs(HEROLIST or {}) do units["npc_dota_hero_" .. tostring(heroName)] = true end
		for _, heroName in pairs(HEROLIST_VIP or {}) do units["npc_dota_hero_" .. tostring(heroName)] = true end
	else
		local files = category == "creep" and {
			"scripts/npc/units/xhs_wave_creeps.txt",
			"scripts/npc/units/events.txt",
			"scripts/npc/units/neutral_dragons.txt",
		} or category == "boss" and {
			"scripts/npc/units/bosses.txt",
			"scripts/npc/units/phase2_and_final_waves.txt",
		} or {}
		for _, path in ipairs(files) do
			for unitName, definition in pairs(LoadKeyValues(path) or {}) do
				if type(unitName) == "string" and type(definition) == "table" then units[unitName] = true end
			end
		end
	end

	self.SupporterEffigyUnitSets[category] = units
	return units
end

local function CleanSupporterRequestText(value, maxLength)
	value = tostring(value or ""):gsub("[%c]", " "):gsub("^%s+", ""):gsub("%s+$", "")
	return string.sub(value, 1, maxLength)
end

function Battlepass:SupporterPassRequestAsset(event_source_index, event, resultEventName)
	event = self:GetSupporterPassEventPayload(event_source_index, event)
	local playerID = event.PlayerID
	local requestType = tostring(event.request_type or "")
	local category = tostring(event.category or "")
	local itemDef = tostring(event.item_def or "")
	local unitName = tostring(event.unit_name or "")
	local assetID = tostring(event.asset_id or "")
	local requestID = tostring(event.request_id or "")
	local resultEvent = resultEventName or "supporter_pass_asset_request_result"
	local requestKey = requestType .. ":" .. category .. ":" .. assetID
	local function fail(message)
		self:SendSupporterPassFailure(playerID, resultEvent, message, {
			request_key = requestKey,
			request_type = requestType,
			category = category,
			asset_id = assetID,
			item_def = itemDef,
			request_id = requestID,
			accepted = false,
		})
	end

	if playerID == nil or not PlayerResource:IsValidPlayerID(playerID)
		or (requestType ~= "companion" and requestType ~= "effigy")
		or (category ~= "courier" and category ~= "hero" and category ~= "creep" and category ~= "boss")
		or requestID == "" or #requestID > 96 or not string.match(requestID, "^[%w_%-]+$")
		or assetID == "" or #assetID > 128 then
		return fail("#xhs_sp_request_failed")
	end
	if requestType == "companion" and category ~= "courier" then
		return fail("#xhs_sp_request_failed")
	end

	self.SupporterAssetRequestTimes = self.SupporterAssetRequestTimes or {}
	local now = GameRules:GetGameTime()
	if now - (self.SupporterAssetRequestTimes[playerID] or -100) < 2 then
		return fail("#xhs_sp_request_rate_limited")
	end
	self.SupporterAssetRequestTimes[playerID] = now

	local model = ""
	if category == "courier" then
		if itemDef == "" then itemDef = assetID end
		if not string.match(itemDef, "^%d+$") or assetID ~= itemDef then
			return fail("#xhs_sp_request_invalid_courier")
		end
		local courierModel = self:GetCourierRequestModel(itemDef)
		if courierModel == nil or (requestType == "companion" and self:GetSupporterCompanionModelSet()[string.lower(courierModel)]) then
			return fail("#xhs_sp_request_invalid_courier")
		end
		model = courierModel
		unitName = ""
	else
		if requestType ~= "effigy" or assetID ~= unitName or not self:GetSupporterEffigyUnitSet(category)[unitName] then
			return fail("#xhs_sp_request_failed")
		end
		itemDef = ""
	end

	if api == nil or api.RequestSupporterPassAsset == nil then
		return fail("#xhs_sp_request_failed")
	end

	api:RequestSupporterPassAsset(playerID, {
		request_id = requestID,
		request_type = requestType,
		category = category,
		asset_id = assetID,
		item_def = itemDef ~= "" and itemDef or nil,
		unit_name = unitName ~= "" and unitName or nil,
		model = model ~= "" and model or nil,
		display_name = CleanSupporterRequestText(event.display_name, 128),
	}, function(ok, response)
		local player = PlayerResource:GetPlayer(playerID)
		if player == nil then return end
		if not ok then
			return self:SendSupporterPassFailure(playerID, resultEvent, response and response.message or "#xhs_sp_request_failed", {
				request_key = requestKey,
				request_type = requestType,
				category = category,
				asset_id = assetID,
				item_def = itemDef,
				request_id = requestID,
				accepted = false,
			})
		end
		CustomGameEventManager:Send_ServerToPlayer(player, resultEvent, {
			request_key = requestKey,
			request_type = requestType,
			category = category,
			asset_id = assetID,
			item_def = itemDef,
			request_id = requestID,
			accepted = true,
			request_count = response and response.request_count or 1,
			message = "#xhs_sp_request_recorded",
		})
	end)
end

function Battlepass:SupporterPassRequestCompanion(event_source_index, event)
	event = type(event) == "table" and event or {}
	event.request_type = "companion"
	event.category = "courier"
	event.asset_id = tostring(event.item_def or "")
	return self:SupporterPassRequestAsset(event_source_index, event, "supporter_pass_companion_request_result")
end

local function FindSupporterShopItemInSection(section, itemID, depth, includeComponents)
	if type(section) ~= "table" or (tonumber(depth) or 0) > 4 then return nil end
	if SupporterItemMatches(section, itemID) then return section end
	for _, item in ipairs(NormalizeSupporterList(section.items or section)) do
		if SupporterItemMatches(item, itemID) then return item end
		if includeComponents == true and item ~= section then
			local nested = FindSupporterShopItemInSection(
				item,
				itemID,
				(tonumber(depth) or 0) + 1,
				true
			)
			if nested ~= nil then return nested end
		end
	end
	local fields = {
		"item",
		"primary",
		"secondary",
		"secondary_items",
		"hero",
		"featured",
		"catalog",
		"permanent",
		"rotation",
	}
	if includeComponents == true then
		table.insert(fields, "components")
		table.insert(fields, "grants")
		table.insert(fields, "payload")
	end
	for _, field in ipairs(fields) do
		local found = FindSupporterShopItemInSection(
			section[field],
			itemID,
			(tonumber(depth) or 0) + 1,
			includeComponents
		)
		if found ~= nil then return found end
	end
	return nil
end

function Battlepass:FindSupporterPassShopItem(itemID)
	for _, key in ipairs({ "catalog", "permanent", "featured", "rotation", "hero" }) do
		local value = CustomNetTables:GetTableValue("supporter_pass_shop", key) or {}
		local found = FindSupporterShopItemInSection(value, itemID, 0, false)
		if found ~= nil then return found end
	end
	return nil
end

function Battlepass:FindSupporterPassRuntimeCatalogItem(itemID)
	for _, key in ipairs({ "catalog", "permanent", "featured", "rotation", "hero" }) do
		local value = CustomNetTables:GetTableValue("supporter_pass_shop", key) or {}
		local found = FindSupporterShopItemInSection(value, itemID, 0, true)
		if found ~= nil then return found end
	end
	return nil
end

function Battlepass:FindSupporterPassReward(rewardID)
	local tableNames = { "supporter_pass_rewards_free", "supporter_pass_rewards_premium" }
	for _, tableName in ipairs(tableNames) do
		local rewards = SupporterPass2026 ~= nil
			and SupporterPass2026.GetPublishedTrack ~= nil
			and SupporterPass2026:GetPublishedTrack(tableName)
			or CustomNetTables:GetTableValue(tableName, "rewards")
			or {}
		for _, reward in ipairs(NormalizeSupporterList(rewards)) do
			if tostring(reward.reward_id or reward.id or "") == tostring(rewardID) then
				return reward, tableName == "supporter_pass_rewards_premium"
			end
		end
	end
	return nil, false
end

function Battlepass:SupporterPassBuyShopItem(event_source_index, event)
	event = self:GetSupporterPassEventPayload(event_source_index, event)
	local playerID = event.PlayerID
	local ply_table = CustomNetTables:GetTableValue("supporter_pass_player", tostring(playerID))

	if playerID == nil or not ply_table or not api or not api.BuySupporterPassShopItem then
		self:SendSupporterPassFailure(playerID, "supporter_pass_purchase_failed", "#xhs_sp_error_shop_unavailable", {
			item_id = event.item_id,
		})
		return
	end

	if event.item_id == nil or tostring(event.item_id) == "" then
		self:SendSupporterPassFailure(playerID, "supporter_pass_purchase_failed", "#xhs_sp_error_shop_item_invalid", {})
		return
	end

	if self:FindSupporterPassShopItem(event.item_id) == nil then
		self:SendSupporterPassFailure(playerID, "supporter_pass_purchase_failed", "#xhs_sp_error_shop_item_inactive", {
			item_id = event.item_id,
		})
		return
	end

	CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "supporter_pass_purchase_pending", {
		item_id = event.item_id,
	})

	api:BuySupporterPassShopItem(playerID, event.item_id, event.request_id, function(success, data)
		local player = PlayerResource:GetPlayer(playerID)
		if not success then
			if player then
				CustomGameEventManager:Send_ServerToPlayer(player, "supporter_pass_purchase_failed", {
					item_id = event.item_id,
					message = data and data.message or nil,
					code = data and data.code or nil,
				})
			end
			return
		end

		if SupporterPass and SupporterPass.PublishPlayer then
			SupporterPass:PublishPlayer(playerID)
		end
		if api and api.PublishSupporterPassArmory then
			api:PublishSupporterPassArmory(playerID, data and data.armory or nil)
		end

		if player then
			CustomGameEventManager:Send_ServerToPlayer(player, "supporter_pass_purchase_success", {
				item_id = event.item_id,
				already_owned = data and data.already_owned or false,
			})
		end
	end)
end

function Battlepass:SupporterPassOpenPaymentPortal(event_source_index, event)
	event = self:GetSupporterPassEventPayload(event_source_index, event)
	local playerID = event.PlayerID
	local player = playerID ~= nil and PlayerResource:GetPlayer(playerID) or nil
	if playerID == nil or not player or not api or not api.CreateSupporterPaymentIntent then
		return
	end

	api:CreateSupporterPaymentIntent(playerID, {
		source = event.source or "supporter_pass",
		locale = event.locale or "en",
		game_mode = GetMapName and GetMapName() or "xhs",
	}, function(success, data)
		if not player or player:IsNull() then return end
		if not success or type(data) ~= "table" or type(data.url) ~= "string" or data.url == "" then
			CustomGameEventManager:Send_ServerToPlayer(player, "supporter_pass_payment_portal_failed", {
				message = data and data.message or "Unable to create a secure supporter link.",
				code = data and data.code or "supporter_payment_intent_failed",
			})
			return
		end
		CustomGameEventManager:Send_ServerToPlayer(player, "supporter_pass_payment_portal_ready", {
			url = data.url,
			expires_at = data.expires_at,
		})
	end)
end

function Battlepass:SupporterPassOpenBundle(event_source_index, event)
	event = self:GetSupporterPassEventPayload(event_source_index, event)
	local playerID = event.PlayerID
	local player = playerID ~= nil and PlayerResource:GetPlayer(playerID) or nil
	if playerID == nil or not player or not api or not api.OpenSupporterPassBundle then
		self:SendSupporterPassFailure(playerID, "supporter_pass_bundle_open_failed", "#xhs_sp_error_shop_unavailable", {
			instance_id = event.instance_id,
		})
		return
	end
	if event.instance_id == nil or tostring(event.instance_id) == "" then
		self:SendSupporterPassFailure(playerID, "supporter_pass_bundle_open_failed", "#xhs_sp_bundle_open_failed", {})
		return
	end

	api:OpenSupporterPassBundle(playerID, event.instance_id, event.request_id, function(success, data)
		if not success then
			CustomGameEventManager:Send_ServerToPlayer(player, "supporter_pass_bundle_open_failed", {
				instance_id = event.instance_id,
				message = data and data.message or nil,
				code = data and data.code or nil,
			})
			return
		end
		if SupporterPass and SupporterPass.PublishPlayer then SupporterPass:PublishPlayer(playerID) end
		if api and api.PublishSupporterPassArmory then api:PublishSupporterPassArmory(playerID, data and data.armory or nil) end
		CustomGameEventManager:Send_ServerToPlayer(player, "supporter_pass_bundle_open_success", {
			instance_id = event.instance_id,
		})
	end)
end

function Battlepass:SupporterPassClaimReward(event_source_index, event)
	event = self:GetSupporterPassEventPayload(event_source_index, event)
	local playerID = event.PlayerID
	if playerID == nil or not api or not api.ClaimSupporterPassReward then
		self:SendSupporterPassFailure(playerID, "supporter_pass_claim_failed", "#xhs_sp_error_reward_backend_unavailable", {
			reward_id = event.reward_id,
		})
		return
	end

	if event.reward_id == nil or tostring(event.reward_id) == "" then
		self:SendSupporterPassFailure(playerID, "supporter_pass_claim_failed", "#xhs_sp_error_reward_invalid", {})
		return
	end

	local reward, premiumTrack = self:FindSupporterPassReward(event.reward_id)
	local playerTable = CustomNetTables:GetTableValue("supporter_pass_player", tostring(playerID)) or {}
	if playerTable.backend_season_ready == false
		or playerTable.backend_season_ready == 0
		or playerTable.backend_season_ready == "0"
		or playerTable.backend_season_ready == "false" then
		self:SendSupporterPassFailure(playerID, "supporter_pass_claim_failed", "#xhs_sp_error_reward_backend_unavailable", {
			reward_id = event.reward_id,
		})
		return
	end
	local rewardClaimable = reward and reward.legacy ~= true and reward.legacy ~= 1 and reward.legacy ~= "1"
		and reward.claimable ~= false and reward.claimable ~= 0 and reward.claimable ~= "0"
	local requiredLevel = reward and tonumber(reward.level_required or reward.level) or math.huge
	local currentLevel = tonumber(playerTable.season_level or playerTable.Lvl) or 1
	local tierID = tonumber(playerTable.tier_id) or 0
	local requiredTier = RequiredSupporterTier(reward, premiumTrack and 1 or 0)
	if reward == nil or not rewardClaimable or currentLevel < requiredLevel or tierID < requiredTier then
		self:SendSupporterPassFailure(playerID, "supporter_pass_claim_failed", "#xhs_sp_error_reward_not_claimable", {
			reward_id = event.reward_id,
		})
		return
	end

	api:ClaimSupporterPassReward(playerID, event.reward_id, function(success, data)
		local player = PlayerResource:GetPlayer(playerID)
		if not player then return end
		if success then
			if SupporterPass and SupporterPass.PublishPlayer then
				SupporterPass:PublishPlayer(playerID)
			end
			if api and api.PublishSupporterPassArmory then
				api:PublishSupporterPassArmory(playerID, data and data.armory or nil)
			end
		end
		CustomGameEventManager:Send_ServerToPlayer(player, success and "supporter_pass_claim_success" or "supporter_pass_claim_failed", {
			reward_id = event.reward_id,
			already_claimed = data and data.already_claimed or false,
			message = data and data.message or nil,
		})
	end)
end

local SUPPORTER_PASS_MUTATION_REQUEST_SEQUENCE = 0

local function CreateSupporterPassMutationRequestID(action, playerID)
	SUPPORTER_PASS_MUTATION_REQUEST_SEQUENCE = SUPPORTER_PASS_MUTATION_REQUEST_SEQUENCE + 1
	local gameID = api ~= nil and api.GetApiGameId ~= nil and api:GetApiGameId() or 0
	local matchID = api ~= nil and api.GetMatchID ~= nil and api:GetMatchID() or 0
	local now = 0
	if Time ~= nil then
		local ok, value = pcall(Time)
		if ok then now = tonumber(value) or 0 end
	elseif GameRules ~= nil and GameRules.GetGameTime ~= nil then
		local ok, value = pcall(function() return GameRules:GetGameTime() end)
		if ok then now = tonumber(value) or 0 end
	end
	local unique = ""
	if DoUniqueString ~= nil then
		local ok, value = pcall(DoUniqueString, "supporter_loadout")
		if ok and value ~= nil then unique = tostring(value) end
	end
	local requestID = table.concat({
		"xhs",
		tostring(action or "mutation"),
		tostring(gameID or 0),
		tostring(matchID or 0),
		tostring(playerID or -1),
		tostring(math.floor(now * 1000)),
		tostring(SUPPORTER_PASS_MUTATION_REQUEST_SEQUENCE),
		unique,
	}, "_")
	requestID = string.gsub(requestID, "[^%w_-]", "_")
	return string.sub(requestID, 1, 160)
end

local function NormalizeSupporterUnequipScope(value)
	if value == nil then return nil end
	local scope = tostring(value)
		:gsub("[%z\1-\31\127]", "")
		:gsub("^%s+", "")
		:gsub("%s+$", "")
	if scope == "" then return nil end
	return string.sub(scope, 1, 96)
end

local function ResolveSupporterUnequipTarget(battlepass, playerID, slot, fallbackHero)
	local hero = tostring(fallbackHero or "global")
	if slot == "all" or battlepass.GetEquippedSupporterItem == nil then
		return hero, nil
	end
	local equipped = battlepass:GetEquippedSupporterItem(playerID, slot)
	if type(equipped) ~= "table" then return hero, nil end
	local metadata = type(equipped.metadata) == "table" and equipped.metadata or {}
	hero = tostring(equipped.hero or metadata.hero or hero)
	local scope = NormalizeSupporterUnequipScope(
		equipped.scope or metadata.scope or equipped.item_type or equipped.type
	)
	return hero, scope
end

function Battlepass:SupporterPassEquipItem(event_source_index, event)
	event = self:GetSupporterPassEventPayload(event_source_index, event)
	local playerID = event.PlayerID
	if playerID == nil then return end

	if event.item_id == nil or tostring(event.item_id) == "" then
		self:SendSupporterPassFailure(playerID, "supporter_pass_equip_failed", "#xhs_sp_error_armory_item_invalid", {})
		return
	end

	local item = self:ResolveSupporterItem(playerID, event.item_id, event.slot_id)
	if item == nil then
		self:SendSupporterPassFailure(playerID, "supporter_pass_equip_failed", "#xhs_sp_error_armory_item_not_owned", {
			item_id = event.item_id,
		})
		return
	end

	local requestedSlot = NormalizeSupporterSlot(event.slot_id)
	local itemSlot = NormalizeSupporterSlot(item.slot_id or item.item_type or item.type)
	local currentTier = SupporterPass and SupporterPass:GetTierForPlayer(playerID) or 0
	local requiredTier = RequiredSupporterTier(item, 0)
	if currentTier < requiredTier then
		self:SendSupporterPassFailure(playerID, "supporter_pass_equip_failed", "#xhs_sp_error_armory_tier_insufficient", {
			item_id = event.item_id,
		})
		return
	end
	if requestedSlot ~= "default" and requestedSlot ~= "global" and itemSlot ~= "default" and requestedSlot ~= itemSlot then
		self:SendSupporterPassFailure(playerID, "supporter_pass_equip_failed", "#xhs_sp_error_armory_slot_mismatch", {
			item_id = event.item_id,
		})
		return
	end

	if not api or not api.EquipSupporterPassItem then
		if item.legacy and self:SetLocalSupporterLoadoutItem(playerID, item) then
			local player = PlayerResource:GetPlayer(playerID)
			if player then
				CustomGameEventManager:Send_ServerToPlayer(player, "supporter_pass_equip_success", {
					item_id = event.item_id,
					local_only = true,
				})
			end
			return
		end
		self:SendSupporterPassFailure(playerID, "supporter_pass_equip_failed", "#xhs_sp_error_armory_backend_unavailable", {
			item_id = event.item_id,
		})
		return
	end

	local requestID = CreateSupporterPassMutationRequestID("equip", playerID)
	local equipHero = item.hero or event.hero or "global"
	api:EquipSupporterPassItem(playerID, event.item_id, equipHero, itemSlot, requestID, function(success, data)
		local player = PlayerResource:GetPlayer(playerID)
		if not player then return end
		if not success and item.legacy and Battlepass:SetLocalSupporterLoadoutItem(playerID, item) then
			success = true
			data = { local_only = true, request_id = requestID }
		end
		if success then
			if SupporterPass and SupporterPass.PublishPlayer then
				SupporterPass:PublishPlayer(playerID)
			end
			if api and api.PublishSupporterPassArmory then
				api:PublishSupporterPassArmory(playerID, data and data.armory or nil)
			end
			Battlepass:ApplySupporterLoadout(playerID)
		end
		CustomGameEventManager:Send_ServerToPlayer(player, success and "supporter_pass_equip_success" or "supporter_pass_equip_failed", {
			item_id = event.item_id,
			request_id = requestID,
			message = data and data.message or nil,
			local_only = data and data.local_only or false,
		})
	end)
end

function Battlepass:SupporterPassUnequipItem(event_source_index, event)
	event = self:GetSupporterPassEventPayload(event_source_index, event)
	local playerID = event.PlayerID
	if playerID == nil then return end

	local slot = NormalizeSupporterSlot(event.slot_id)
	if slot ~= "all" and SUPPORTER_DEV_TEST_SLOTS[slot] ~= true then
		self:SendSupporterPassFailure(playerID, "supporter_pass_unequip_failed", "#xhs_sp_error_armory_slot_mismatch", {
			slot_id = slot,
		})
		return
	end

	if not api or not api.UnequipSupporterPassItem then
		self:SendSupporterPassFailure(playerID, "supporter_pass_unequip_failed", "#xhs_sp_error_armory_backend_unavailable", {
			slot_id = slot,
		})
		return
	end

	local unequipHero, scope = ResolveSupporterUnequipTarget(self, playerID, slot, event.hero)
	local requestID = CreateSupporterPassMutationRequestID("unequip", playerID)
	api:UnequipSupporterPassItem(playerID, unequipHero, slot, scope, requestID, function(success, data)
		local player = PlayerResource:GetPlayer(playerID)
		if not player then return end
		if success then
			if SupporterPass and SupporterPass.PublishPlayer then
				SupporterPass:PublishPlayer(playerID)
			end
			if api and api.PublishSupporterPassArmory then
				api:PublishSupporterPassArmory(playerID, data and data.armory or nil)
			end
			Battlepass:ApplySupporterLoadout(playerID)
		end
		CustomGameEventManager:Send_ServerToPlayer(player, success and "supporter_pass_unequip_success" or "supporter_pass_unequip_failed", {
			slot_id = slot,
			request_id = requestID,
			message = data and data.message or nil,
		})
	end)
end

function Battlepass:SupporterPassUpdateSettings(event_source_index, event)
	event = self:GetSupporterPassEventPayload(event_source_index, event)
	local playerID = event.PlayerID
	if playerID == nil then
		return
	end

	local ply_table = CustomNetTables:GetTableValue("supporter_pass_player", tostring(playerID)) or {}
	local previous_table = {}
	for key, value in pairs(ply_table) do
		previous_table[key] = value
	end

	local settings = {}
	if event.toggle_tag ~= nil then settings.toggle_tag = event.toggle_tag == 1 or event.toggle_tag == true end
	if event.pass_rewards ~= nil then settings.pass_rewards = event.pass_rewards == 1 or event.pass_rewards == true end
	if event.player_xp ~= nil then settings.player_xp = event.player_xp == 1 or event.player_xp == true end
	if event.winrate_toggle ~= nil then settings.winrate_toggle = event.winrate_toggle == 1 or event.winrate_toggle == true end
	if event.xhs_ingame_advertize_hidden ~= nil then settings.xhs_ingame_advertize_hidden = event.xhs_ingame_advertize_hidden == 1 or event.xhs_ingame_advertize_hidden == true end

	if next(settings) == nil then
		return
	end

	if settings.toggle_tag ~= nil then ply_table.toggle_tag = settings.toggle_tag end
	if settings.pass_rewards ~= nil then
		ply_table.pass_rewards = settings.pass_rewards
		ply_table.bp_rewards = ply_table.pass_rewards
	end
	if settings.player_xp ~= nil then ply_table.player_xp = settings.player_xp end
	if settings.winrate_toggle ~= nil then ply_table.winrate_toggle = settings.winrate_toggle end
	if settings.xhs_ingame_advertize_hidden ~= nil then ply_table.xhs_ingame_advertize_hidden = settings.xhs_ingame_advertize_hidden end

	CustomNetTables:SetTableValue("supporter_pass_player", tostring(playerID), ply_table)

	if api and api.UpdateSupporterPassSettings then
		api:UpdateSupporterPassSettings(playerID, settings, function(success, data)
			local player = PlayerResource:GetPlayer(playerID)

			if not success then
				CustomNetTables:SetTableValue("supporter_pass_player", tostring(playerID), previous_table)
				local hero = PlayerResource:GetSelectedHeroEntity(playerID)
				Battlepass:ApplySupporterLoadout(playerID, hero)
				if player then
					CustomGameEventManager:Send_ServerToPlayer(player, "supporter_pass_settings_failed", {
						message = data and data.message or "#xhs_sp_settings_failed",
					})
				end
				return
			end

			if SupporterPass and SupporterPass.PublishPlayer then
				SupporterPass:PublishPlayer(playerID)
			end

			local hero = PlayerResource:GetSelectedHeroEntity(playerID)

			if settings.pass_rewards ~= nil then
				Battlepass:ApplySupporterLoadout(playerID, hero)
			end

			if player then
				CustomGameEventManager:Send_ServerToPlayer(player, "supporter_pass_settings_success", {})
			end
		end)
	else
		local hero = PlayerResource:GetSelectedHeroEntity(playerID)

		if settings.pass_rewards ~= nil then
			Battlepass:ApplySupporterLoadout(playerID, hero)
		end

		local player = PlayerResource:GetPlayer(playerID)
		if player then
			CustomGameEventManager:Send_ServerToPlayer(player, "supporter_pass_settings_success", {})
		end
	end
end

function Battlepass:SetOverrideAssets(hero, modifier, table_name)
	if hero == nil or hero:IsNull() or type(table_name) ~= "table" then return end
	local asset_style = 0
	local playerID = hero:GetPlayerID()
	self.SUPPORTER_OVERRIDE_ASSETS = self.SUPPORTER_OVERRIDE_ASSETS or {}
	self.SUPPORTER_OVERRIDE_ASSETS[playerID] = self.SUPPORTER_OVERRIDE_ASSETS[playerID] or {}

	if modifier and hero:HasModifier(modifier) and hero:FindModifierByName(modifier):GetStackCount() then
		asset_style = hero:FindModifierByName(modifier):GetStackCount()
	end

	for i, j in pairs(table_name) do
		if i ~= "skip_model_combine" and type(j) ~= "number" then
			if j.type == "particle" then
				if j.style == nil or j.style == asset_style then
					if j.asset == GetKeyValueByHeroName(hero:GetUnitName(), "ProjectileModel") then
						--						print("Range attack particle:", j)
						hero:SetRangedProjectileName(j.modifier)
					else
						self.Player = self.Player or {}
						self.Player[playerID] = self.Player[playerID] or {}
						self.Player[playerID].particle_overrides =
							self.Player[playerID].particle_overrides or {}
						self.Player[playerID].particle_overrides[j.asset] = j.modifier
					end
				end
			elseif j.type == "sound" then
				if j.style == nil or j.style == asset_style then
					--					print("Sound:", j)
					CustomNetTables:SetTableValue("supporter_pass_player", j.asset .. '_' .. playerID, { j.modifier })
					self.SUPPORTER_OVERRIDE_ASSETS[playerID][j.asset] = true
				end
			elseif j.type == "ability_icon" then
				if j.style == nil or j.style == asset_style then
					--					print("ability icon:", j)
					CustomNetTables:SetTableValue("supporter_pass_player", j.asset .. '_' .. playerID, { j.modifier })
					self.SUPPORTER_OVERRIDE_ASSETS[playerID][j.asset] = true
				end
			elseif j.type == "icon_replacement_hero" then
				if j.style == nil or j.style == asset_style then
					--					print("topbar icon:", j)
					CustomGameEventManager:Send_ServerToAllClients("override_hero_image", {
						player_id = hero:GetPlayerID(),
						icon_path = j.modifier,
					})
				end
			elseif j.type == "entity_model" then
				if j.style == nil or j.style == asset_style then
					--					print("entity model:", j)
					Battlepass.ENTITY_MODEL_OVERRIDE[j.asset] = j.modifier
				end
			elseif j.type == "sheepstick_model" then
				hero.sheepstick_model = j.modifier
			end
		end
	end
end

-- todo: use values in items_game.txt instead
function Battlepass:GetHeroEffect(hero)
	if hero:GetUnitName() == "npc_dota_hero_drow_ranger" then
		hero.base_attack_projectile = "particles/units/heroes/hero_drow/drow_base_attack.vpcf"
		hero.frost_arrows_debuff_pfx = "particles/units/heroes/hero_drow/drow_frost_arrow_debuff.vpcf"
		hero.marksmanship_arrow_pfx = "particles/units/heroes/hero_drow/drow_marksmanship_attack.vpcf"
		hero.marksmanship_frost_arrow_pfx = "particles/units/heroes/hero_drow/drow_marksmanship_frost_arrow.vpcf"
	elseif hero:GetUnitName() == "npc_dota_hero_tiny" then
		hero.ambient_pfx_effect = "particles/units/heroes/hero_tiny/tiny_ambient.vpcf"
		hero.death_pfx = "particles/units/heroes/hero_tiny/tiny01_death.vpcf"

		hero.avalanche_effect = "particles/units/heroes/hero_tiny/tiny_avalanche.vpcf"
		hero.avalance_projectile_effect = "particles/units/heroes/hero_tiny/tiny_avalanche_projectile.vpcf"

		hero.tree_model = "models/heroes/tiny_01/tiny_01_tree.vmdl"
		hero.tree_linear_effect = "particles/units/heroes/hero_tiny/tiny_tree_linear_proj.vpcf"
		hero.tree_tracking_effect = "particles/units/heroes/hero_tiny/tiny_tree_proj.vpcf"
		hero.tree_ambient_effect = ""
		hero.tree_grab_sound = "Hero_Tiny.Tree.Grab"
		hero.tree_throw_sound = "Hero_Tiny.Tree.Throw"
		hero.tree_throw_target_sound = "Hero_Tiny.Tree.Target"
		hero.tree_channel_target_sound = "Hero_Tiny.TreeChannel.Target"

		hero.grow_effect = "particles/units/heroes/hero_tiny/tiny_transform.vpcf"

		hero.tree_cleave_effect = "particles/units/heroes/hero_tiny/tiny_craggy_cleave.vpcf"
	end

	local ply_table = CustomNetTables:GetTableValue("supporter_pass_player", tostring(hero:GetPlayerID()))

	if ply_table and ply_table.bp_rewards == 0 then
		return
	end

	if tostring(PlayerResource:GetSteamID(hero:GetPlayerID())) ~= "0" then
		local armory = Battlepass:GetEquippedSupporterItems(hero:GetPlayerID())
		--		print("Armory:", armory)
		if not armory or armory and type(armory) ~= "table" then return end

		local battlepass_items = {}
		battlepass_items["blink"] = ""
		battlepass_items["bottle"] = ""
		battlepass_items["force_staff"] = ""
		battlepass_items["fountain"] = ""
		battlepass_items["maelstrom"] = ""
		battlepass_items["mekansm"] = ""
		battlepass_items["radiance"] = ""
		battlepass_items["sheepstick"] = ""
		battlepass_items["shiva"] = ""

		for k, v in pairs(armory) do
			local catalogItemID = Battlepass:GetSupporterCatalogItemID(v)
			-- HEROES HANDLE
			if catalogItemID ~= nil and hero:GetUnitName() == v.hero then
				for item_id, slot_id in pairs(ItemsGame:GetItemWearables(catalogItemID) or {}) do
					if type(item_id) == "number" then item_id = tostring(item_id) end

					local modifier = ItemsGame:GetItemModifier(catalogItemID)
					local style = 0

					if modifier then
						--						print("Add cosmetic modifier:", modifier)
						hero:AddNewModifier(hero, nil, modifier, {})

						if v.hero == "npc_dota_hero_phantom_assassin" then
							--							print("Arcana kills:")
							local pa_arcana_kills = api:GetPhantomAssassinArcanaKills(hero:GetPlayerID()) or 0
							--							print(pa_arcana_kills)
							hero:AddNewModifier(hero, nil, "modifier_phantom_assassin_arcana", {}):SetStackCount(tonumber(pa_arcana_kills))

							if tonumber(pa_arcana_kills) >= 400 then
								style = 1
							elseif tonumber(pa_arcana_kills) >= 1000 then
								style = 2
							end
						end
					end

					Wearable:_WearProp(hero, item_id, slot_id, style)

					if Wearable.asset_modifier[item_id] then
						Battlepass:SetOverrideAssets(hero, modifier, Wearable.asset_modifier[item_id])
					end

					if Wearable.items_game["items"][item_id] and Wearable.items_game["items"][item_id]["visuals"] then
						Battlepass:SetOverrideAssets(hero, modifier, Wearable.items_game["items"][item_id]["visuals"])
					end

					if hero:GetUnitName() == "npc_dota_hero_crystal_maiden" and catalogItemID == "117" then
						-- timer to let donator companion spawn if any, to then override it with arcana companion
						Timers:CreateTimer(2.0, function()
							Battlepass:DonatorCompanion(hero:GetPlayerID(), "npc_donator_companion_crystal_maiden_puppy")
						end)
					end
				end
			elseif catalogItemID ~= nil then
				local itemType = ItemsGame:GetItemType(catalogItemID)
				if itemType == "levelup" or itemType == "teleport" then
					Battlepass:SetOverrideAssets(hero, nil, ItemsGame:GetItemVisuals(catalogItemID))
				end

				local item_name = v.hero

				-- items rewards only
				if battlepass_items[item_name] then
					--					print(v.item_id, item_name)
					local item_effects = ItemsGame:GetItemVisuals(catalogItemID)

					--					print(item_effects)
					Battlepass:SetOverrideAssets(hero, nil, ItemsGame:GetItemVisuals(catalogItemID))

					local images = ItemsGame:GetItemImages(catalogItemID)

					for k, v in pairs(images) do
						CustomNetTables:SetTableValue("supporter_pass_player", v.asset .. '_' .. hero:GetPlayerID(), { v.modifier })
					end
				end
			end
		end

		--		print(CScriptParticleManager.PARTICLES_OVERRIDE)
		--		print("---------------------------------")
		--		print(CDOTA_BaseNPC.SOUNDS_OVERRIDE)
	end

	local hello = false
	if hello == false then return end

	print("DONT")

	if Battlepass:GetRewardUnlocked(hero:GetPlayerID()) ~= nil then
		local short_name = string.gsub(hero:GetUnitName(), "npc_dota_hero_", "")

		if hero:GetUnitName() == "npc_dota_hero_drow_ranger" then
			if Battlepass:GetRewardUnlocked(hero:GetPlayerID()) >= BattlepassHeroes[short_name]["drow_ranger_immortal"] then
				hero.base_attack_projectile = "particles/econ/items/drow/drow_ti9_immortal/drow_ti9_base_attack.vpcf"
				hero.frost_arrows_debuff_pfx = "particles/econ/items/drow/drow_ti9_immortal/drow_ti9_frost_arrow_debuff.vpcf"
				hero.marksmanship_arrow_pfx = "particles/econ/items/drow/drow_ti9_immortal/drow_ti9_marksman.vpcf"
				hero.marksmanship_frost_arrow_pfx = "particles/econ/items/drow/drow_ti9_immortal/drow_ti9_marksman_frost.vpcf"
				hero:SetRangedProjectileName("particles/econ/items/drow/drow_ti9_immortal/drow_ti9_base_attack.vpcf")

				Wearable:_WearProp(hero, "12946", "weapon")

				hero:AddNewModifier(hero, nil, "modifier_battlepass_wearable_spellicons", {})
			end
		elseif hero:GetUnitName() == "npc_dota_hero_earthshaker" then
			if Battlepass:GetRewardUnlocked(hero:GetPlayerID()) >= BattlepassHeroes[short_name]["earthshaker_arcana2"] then
				hero.enchant_totem_leap_blur_pfx = "particles/econ/items/earthshaker/earthshaker_arcana/earthshaker_arcana_totem_leap_v2.vpcf"
				hero.enchant_totem_buff_pfx = "particles/econ/items/earthshaker/earthshaker_arcana/earthshaker_arcana_totem_buff.vpcf"
				hero.enchant_totem_cast_pfx = "particles/econ/items/earthshaker/earthshaker_arcana/earthshaker_arcana_totem_cast_v2.vpcf"
				hero.aftershock_pfx = "particles/econ/items/earthshaker/earthshaker_arcana/earthshaker_arcana_aftershock_v2.vpcf"
				hero.echo_slam_start_pfx = "particles/econ/items/earthshaker/earthshaker_arcana/earthshaker_arcana_echoslam_start_v2.vpcf"
				hero.echo_slam_tgt_pfx = "particles/econ/items/earthshaker/earthshaker_arcana/earthshaker_arcana_echoslam_ground_v2.vpcf"
				hero.echo_slam_pfx = "particles/econ/items/earthshaker/earthshaker_arcana/earthshaker_arcana_echoslam_proj_v2.vpcf"

				hero.blink_effect = "particles/econ/items/earthshaker/earthshaker_arcana/earthshaker_arcana_blink_start_v2.vpcf"
				hero.blink_effect_end = "particles/econ/items/earthshaker/earthshaker_arcana/earthshaker_arcana_blink_end_v2.vpcf"
				hero.blink_icon = "earthshaker2"
				hero.blink_sound = "Hero_Earthshaker.BlinkDagger.Arcana"

				Wearable:_WearProp(hero, "12692", "head", "02")
				hero:AddNewModifier(hero, nil, "modifier_battlepass_wearable_spellicons", { style = 2 })
			elseif Battlepass:GetRewardUnlocked(hero:GetPlayerID()) >= BattlepassHeroes[short_name]["earthshaker_arcana"] then
				hero.enchant_totem_leap_blur_pfx = "particles/econ/items/earthshaker/earthshaker_arcana/earthshaker_arcana_totem_leap.vpcf"
				hero.enchant_totem_buff_pfx = "particles/econ/items/earthshaker/earthshaker_arcana/earthshaker_arcana_totem_buff.vpcf"
				hero.enchant_totem_cast_pfx = "particles/econ/items/earthshaker/earthshaker_arcana/earthshaker_arcana_totem_cast.vpcf"
				hero.aftershock_pfx = "particles/econ/items/earthshaker/earthshaker_arcana/earthshaker_arcana_aftershock.vpcf"
				hero.echo_slam_start_pfx = "particles/econ/items/earthshaker/earthshaker_arcana/earthshaker_arcana_echoslam_start.vpcf"
				hero.echo_slam_tgt_pfx = "particles/econ/items/earthshaker/earthshaker_arcana/earthshaker_arcana_echoslam_ground.vpcf"
				hero.echo_slam_pfx = "particles/econ/items/earthshaker/earthshaker_arcana/earthshaker_arcana_echoslam_proj.vpcf"

				hero.blink_effect = "particles/econ/items/earthshaker/earthshaker_arcana/earthshaker_arcana_blink_start.vpcf"
				hero.blink_effect_end = "particles/econ/items/earthshaker/earthshaker_arcana/earthshaker_arcana_blink_end.vpcf"
				hero.blink_icon = "earthshaker"
				hero.blink_sound = "Hero_Earthshaker.BlinkDagger.Arcana"

				Wearable:_WearProp(hero, "12692", "head")
				hero:AddNewModifier(hero, nil, "modifier_battlepass_wearable_spellicons", { style = 1 })
				-- not used atm
				--				if not hero:HasModifier("modifier_earthshaker_arcana") then -- need to change name, this is the vanilla modifier name
				--					hero:AddNewModifier(hero, nil, "modifier_earthshaker_arcana", {})
				--				end
			end
		elseif hero:GetUnitName() == "npc_dota_hero_nevermore" then
			if IsInToolsMode() then
				if Battlepass:GetRewardUnlocked(hero:GetPlayerID()) >= BattlepassHeroes[short_name]["nevermore_arcana"] then
					Wearable:_WearProp(hero, "6996", "head")
				end
			end
		elseif hero:GetUnitName() == "npc_dota_hero_terrorblade" then
			if IsInToolsMode() then
				--				if Battlepass:GetRewardUnlocked(hero:GetPlayerID()) >= BattlepassHeroes[short_name]["terrorblade_arcana"] then
				--					Wearable:_WearProp(hero, "5957", "head")
				--				end
			end
			--		elseif hero:GetUnitName() == "npc_dota_hero_tidehunter" then
			--			if Battlepass:GetRewardUnlocked(hero:GetPlayerID()) >= BattlepassHeroes[short_name]["tidehunter_ancient"] then
			--				Wearable:RemoveWearables(hero)
			--				hero.arms = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/items/tidehunter/Celth_AzhagTidehunter/tidehunter_arms_wh/tidehunter_arms_wh.vmdl"})
			--				hero.back = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/items/tidehunter/Celth_AzhagTidehunter/tidehunter_back_wh/tidehunter_back_wh.vmdl"})
			--				hero.belt = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/items/tidehunter/Celth_AzhagTidehunter/tidehunter_belt_wh/tidehunter_belt_wh.vmdl"})
			--				hero.head = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/items/tidehunter/Celth_AzhagTidehunter/tidehunter_head_wh/tidehunter_head_wh.vmdl"})
			--				hero.offhand = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/items/tidehunter/Celth_AzhagTidehunter/tidehunter_offhand_wh/tidehunter_offhand_wh.vmdl"})
			--				hero.weapon = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/items/tidehunter/Celth_AzhagTidehunter/tidehunter_weapon_wh/tidehunter_weapon_wh.vmdl"})
			--			end
		elseif hero:GetUnitName() == "npc_dota_hero_tiny" then
			if Battlepass:GetRewardUnlocked(hero:GetPlayerID()) >= BattlepassHeroes[short_name]["tiny_immortal"] then
				-- attempt to fix tree throw pfx being vanilla (whatever you have equipped in your armory). not fixing it
				Wearable:RemoveWearables(hero)

				hero.ambient_pfx_effect = "particles/econ/items/tiny/tiny_prestige/tiny_prestige_lvl1_ambient.vpcf"
				hero.death_pfx = "particles/econ/items/tiny/tiny_prestige/tiny_prestige_lvl1_death.vpcf"

				hero.avalanche_effect = "particles/econ/items/tiny/tiny_prestige/tiny_prestige_avalanche.vpcf"
				hero.avalance_projectile_effect = "particles/econ/items/tiny/tiny_prestige/tiny_prestige_avalanche_projectile.vpcf"

				hero.tree_model = "models/items/tiny/tiny_prestige/tiny_prestige_sword.vmdl"
				hero.tree_ambient_effect = "particles/econ/items/tiny/tiny_prestige/tiny_prestige_tree_ambient.vpcf"
				hero.tree_linear_effect = "particles/econ/items/tiny/tiny_prestige/tiny_prestige_tree_linear_proj.vpcf"
				hero.tree_tracking_effect = "particles/econ/items/tiny/tiny_prestige/tiny_prestige_tree_proj.vpcf"
				hero.tree_grab_sound = "Hero_Tiny.Prestige.Grab"
				hero.tree_throw_sound = "Hero_Tiny.Prestige.Throw"
				hero.tree_throw_target_sound = "Hero_Tiny.Prestige.Target"
				hero.tree_channel_target_sound = "Hero_Tiny.Prestige.Target"

				hero.grow_effect = "particles/econ/items/tiny/tiny_prestige/tiny_prestige_transform.vpcf"

				hero.tree_cleave_effect = "particles/econ/items/tiny/tiny_prestige/tiny_prestige_tree_melee_hit.vpcf"

				hero.is_storegga = true
				hero:SetModel("models/items/tiny/tiny_prestige/tiny_prestige_lvl_01.vmdl")
				hero:SetOriginalModel("models/items/tiny/tiny_prestige/tiny_prestige_lvl_01.vmdl")
				hero:AddNewModifier(hero, nil, "modifier_battlepass_wearable_spellicons", {})
				--				Wearable:_WearProp(hero, "13541", "weapon")

				hero.ambient_pfx = ParticleManager:CreateParticle(hero.ambient_pfx_effect, PATTACH_ABSORIGIN_FOLLOW, hero)
			end
		elseif hero:GetUnitName() == "npc_dota_hero_ursa" then
			if Battlepass:GetRewardUnlocked(hero:GetPlayerID()) >= BattlepassHeroes[short_name]["ursa_immortal"] then
				Wearable:_WearProp(hero, "4212", "head")
				Wearable:_WearProp(hero, "4213", "back")
				Wearable:_WearProp(hero, "4214", "belt")
				Wearable:_WearProp(hero, "4215", "arms")
			end
		end
	end
end

function Battlepass:InitializeTowers()
	local radiant_level = 0
	local dire_level = 0

	for ID = 0, PlayerResource:GetPlayerCount() - 1 do
		if PlayerResource:GetPlayer(ID):GetTeamNumber() == 2 then
			radiant_level = radiant_level + Battlepass:GetRewardUnlocked(ID)
		else
			dire_level = dire_level + Battlepass:GetRewardUnlocked(ID)
		end
	end

	print("Team Battlepass Levels:", radiant_level, dire_level)

	local towers = Entities:FindAllByClassname("npc_dota_tower")

	for _, tower in pairs(towers) do
		local level = dire_level
		local particle = "particles/world_tower/tower_upgrade/ti7_dire_tower_orb.vpcf"
		local team = "dire"
		--		local max_particle = "particles/world_tower/tower_upgrade/ti7_radiant_tower_lvl11_orb.vpcf"

		if tower:GetTeamNumber() == 2 then
			level = radiant_level
			particle = "particles/world_tower/tower_upgrade/ti7_radiant_tower_orb.vpcf"
			team = "radiant"
		end

		tower:SetModel("models/props_structures/tower_upgrade/tower_upgrade.vmdl")
		tower:SetOriginalModel("models/props_structures/tower_upgrade/tower_upgrade.vmdl")
		tower:SetMaterialGroup(team .. "_level" .. Battlepass:CheckBattlepassTowerLevel(level).mg)
		ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN_FOLLOW, tower)
		StartAnimation(tower, { duration = 9999, activity = ACT_DOTA_CAPTURE, rate = 1.0, translate = 'level' .. Battlepass:CheckBattlepassTowerLevel(level).anim })
	end
end

function Battlepass:CheckBattlepassTowerLevel(level)
	local animation
	local material_group

	if level < 25 then
		material_group = "1"
		animation = "1"
	elseif level >= 25 then
		material_group = "2"
		animation = "1"
	elseif level >= 50 then
		material_group = "2"
		animation = "2"
	elseif level >= 75 then
		material_group = "3"
		animation = "2"
	elseif level >= 100 then
		material_group = "3"
		animation = "3"
	elseif level >= 150 then
		material_group = "4"
		animation = "3"
	elseif level >= 200 then
		material_group = "4"
		animation = "4"
	elseif level >= 300 then
		material_group = "5"
		animation = "4"
	elseif level >= 500 then
		material_group = "5"
		animation = "5"
	elseif level >= 1000 then
		material_group = "6"
		animation = "5"
	elseif level >= 2000 then
		material_group = "6"
		animation = "6"
	end

	local params = {
		anim = animation,
		mg = material_group
	}

	return params
end
