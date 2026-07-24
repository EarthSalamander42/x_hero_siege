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
CustomGameEventManager:RegisterListener("supporter_pass_claim_reward", Dynamic_Wrap(Battlepass, "SupporterPassClaimReward"))
CustomGameEventManager:RegisterListener("supporter_pass_equip_item", Dynamic_Wrap(Battlepass, "SupporterPassEquipItem"))
CustomGameEventManager:RegisterListener("supporter_pass_update_settings", Dynamic_Wrap(Battlepass, "SupporterPassUpdateSettings"))
CustomGameEventManager:RegisterListener("supporter_pass_dev_test_reward", Dynamic_Wrap(Battlepass, "SupporterPassDevTestReward"))
CustomGameEventManager:RegisterListener("supporter_pass_dev_stop_test", Dynamic_Wrap(Battlepass, "SupporterPassDevStopTest"))
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

function CDOTA_BaseNPC:RemoveHealthBarLabel()
	if self.SetCustomHealthLabel then
		self:SetCustomHealthLabel("", 255, 255, 255)
	end
end

function CDOTA_BaseNPC:SetupHealthBarLabel(customTag)
	if not self.GetPlayerOwnerID or not self.SetCustomHealthLabel then return end

	local playerID = self:GetPlayerOwnerID()
	if not PlayerResource:IsValidPlayerID(playerID) then return end
	local playerTable = CustomNetTables:GetTableValue("supporter_pass_player", tostring(playerID))
	if type(playerTable) ~= "table" then return end

	local donatorLevel = tonumber(playerTable.donator_level) or 0
	if donatorLevel <= 0 then
		self:RemoveHealthBarLabel()
		return
	end

	local visualLevel = GetDonatorVisualStatus ~= nil and GetDonatorVisualStatus(donatorLevel) or donatorLevel
	local color = DONATOR_COLOR[visualLevel] or DONATOR_COLOR[0] or { 255, 255, 255 }
	local label = customTag or playerTable.ingame_tag or ("#donator_label_" .. tostring(donatorLevel))
	self:SetCustomHealthLabel(label, color[1], color[2], color[3])
end

function Battlepass:ApplySupporterTag(hero, enabled)
	if hero == nil or hero:IsNull() then return end

	if enabled == true then
		hero:SetupHealthBarLabel()
	else
		hero:RemoveHealthBarLabel()
	end
end

function CDOTA_BaseNPC:CenterCameraOnEntity(hTarget, iDuration)
	PlayerResource:SetCameraTarget(self:GetPlayerID(), hTarget)
	if iDuration == nil then iDuration = FrameTime() end
	if iDuration ~= -1 then
		Timers:CreateTimer(iDuration, function()
			PlayerResource:SetCameraTarget(self:GetPlayerID(), nil)
			Timers:CreateTimer(FrameTime(), function() --fail-safe
				PlayerResource:SetCameraTarget(self:GetPlayerID(), nil)
			end)
			Timers:CreateTimer(FrameTime() * 3, function() --fail-safe
				PlayerResource:SetCameraTarget(self:GetPlayerID(), nil)
			end)
		end)
	end
end

function Battlepass:ToggleDonatorTag(event_source_index, event)
	local keys = self:GetSupporterPassEventPayload(event_source_index, event)
	if keys.PlayerID == nil then return end
	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local hero = player and player:GetAssignedHero() or nil

	Battlepass:UpdatePlayerTable(keys.PlayerID, "toggle_tag", keys.tag)
	Battlepass:ApplySupporterTag(hero, keys.tag == 1 or keys.tag == true)
end

function Battlepass:SetDonatorTag(event_source_index, event)
	local keys = self:GetSupporterPassEventPayload(event_source_index, event)
	if keys.PlayerID == nil then return end
	--	print(keys)
	local hero = PlayerResource:GetSelectedHeroEntity(keys.PlayerID)

	--	if api.players[steamid].changed_tag_this_game then
	--		DisplayError(keys.PlayerID, "Don't abuse the fucking feature!")
	--	else
	-- api:SetPlayerIngameTag(keys.PlayerID, keys.ingame_tag)
	-- hero:SetupHealthBarLabel(keys.ingame_tag)
	--	end
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
	local item = self:FindOwnedSupporterItem(playerID, itemID)
	if item == nil then
		item = self:BuildLegacySupporterItem(playerID, itemID, requestedSlot)
	end
	if item == nil and SupporterPass and SupporterPass:GetTierForPlayer(playerID) > 0 then
		local slot = NormalizeSupporterSlot(requestedSlot)
		local catalogs = {
			companion = api and api.companions or {},
			emblem = api and api.emblems or {},
			effigy = api and api.effigies or {},
		}
		for _, cosmetic in pairs(catalogs[slot] or {}) do
			if SupporterItemMatches(cosmetic, itemID) then
				local requiredTier = RequiredSupporterTier(cosmetic, 1)
				if SupporterPass:GetTierForPlayer(playerID) >= requiredTier then
					item = CopySupporterItem(cosmetic)
					item.id = item.id or tostring(itemID)
					item.item_id = item.item_id or item.id or tostring(itemID)
					item.type = slot
					item.slot_id = slot
					item.hero = "global"
					item.legacy = true
					if slot == "companion" or slot == "effigy" then
						item.unit = item.unit or item.unit_name or item.file
					elseif slot == "emblem" then
						item.particle = item.particle or item.file
					end
				end
				break
			end
		end
		if item == nil and slot == "companion" then
			local companions = LoadKeyValues("scripts/npc/units/companions.txt") or {}
			if type(companions[tostring(itemID)]) == "table" then
				item = {
					id = tostring(itemID), item_id = tostring(itemID), unit = tostring(itemID),
					type = "companion", slot_id = "companion", hero = "global", legacy = true,
				}
			end
		elseif item == nil and slot == "effigy" then
			local statues = LoadKeyValues("scripts/npc/units/statues.txt") or {}
			if type(statues[tostring(itemID)]) == "table" then
				item = {
					id = tostring(itemID), item_id = tostring(itemID), unit = tostring(itemID),
					type = "effigy", slot_id = "effigy", hero = "global", legacy = true,
				}
			end
		end
	end
	if item == nil then return nil end

	item.item_id = item.item_id or item.catalog_item_id or item.reward_item_id or item.id
	item.slot_id = NormalizeSupporterSlot(item.slot_id or item.item_type or item.type or requestedSlot)

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

	return item
end

local function HydrateSupporterLoadoutItem(battlepass, playerID, value, requestedSlot)
	local item = type(value) == "table" and CopySupporterItem(value) or {}
	local itemID = type(value) == "table"
		and (value.entitlement_id or value.item_id or value.catalog_item_id or value.reward_item_id or value.id or value.unit)
		or value
	local slot = NormalizeSupporterSlot(item.slot_id or item.item_type or item.type or requestedSlot)
	local resolved = itemID ~= nil and battlepass:ResolveSupporterItem(playerID, itemID, slot) or nil

	if resolved ~= nil then
		for key, fieldValue in pairs(item) do
			if fieldValue ~= nil and fieldValue ~= "" then
				resolved[key] = fieldValue
			end
		end
		item = resolved
	end

	if next(item) == nil then return nil end
	item.slot_id = NormalizeSupporterSlot(item.slot_id or item.item_type or item.type or slot)
	return item
end

function Battlepass:GetEquippedSupporterItems(playerID)
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
		return result
	end

	for slot, value in pairs(loadout) do
		local item = HydrateSupporterLoadoutItem(self, playerID, value, slot)
		if item ~= nil then
			item.slot_id = NormalizeSupporterSlot(item.slot_id or slot)
			table.insert(result, item)
		end
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
	local playerTable = CustomNetTables:GetTableValue("supporter_pass_player", tostring(playerID)) or {}
	local value = playerTable.pass_rewards
	if value == nil then value = playerTable.bp_rewards end
	return value ~= false and value ~= 0 and value ~= "0"
end

function Battlepass:GetSupporterItemParticle(item, expectedAsset)
	if type(item) ~= "table" or ItemsGame == nil then return nil end
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
	local candidates = { item.catalog_item_id, item.reward_item_id, item.item_id, item.id }
	for _, candidate in ipairs(candidates) do
		if candidate ~= nil and ItemsGame:GetItemKV(candidate) ~= nil then
			return tostring(candidate)
		end
	end
	return nil
end

function Battlepass:ClearSupporterOverrides(playerID)
	self.SUPPORTER_OVERRIDE_ASSETS = self.SUPPORTER_OVERRIDE_ASSETS or {}
	for asset, _ in pairs(self.SUPPORTER_OVERRIDE_ASSETS[playerID] or {}) do
		CustomNetTables:SetTableValue("supporter_pass_player", asset .. "_" .. tostring(playerID), { asset })
	end
	self.SUPPORTER_OVERRIDE_ASSETS[playerID] = {}
end

function Battlepass:ApplySupporterEmblem(hero, item)
	if hero == nil or hero:IsNull() then return end
	local particle = item and (item.particle or item.file or self:GetSupporterItemParticle(item, "particles/hero_emblem/default.vpcf")) or ""
	if particle ~= "" and not hero:HasModifier("modifier_patreon_donator") then
		hero:AddNewModifier(hero, nil, "modifier_patreon_donator", {})
	end
	local modifier = hero:FindModifierByName("modifier_patreon_donator")
	if modifier and modifier.SetDonatorEffect then
		modifier:SetDonatorEffect(particle)
	end
end

function Battlepass:ApplySupporterLoadout(playerID, hero)
	if not PlayerResource:IsValidPlayerID(playerID) then return end
	hero = hero or PlayerResource:GetSelectedHeroEntity(playerID)
	if hero == nil or hero:IsNull() then return end

	self:ClearSupporterOverrides(playerID)
	if not self:AreSupporterRewardsEnabled(playerID) then
		self:ApplySupporterEmblem(hero, nil)
		self:DonatorCompanion(playerID, "", true)
		if self.RemoveDonatorStatue then self:RemoveDonatorStatue(playerID) end
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
end

function Battlepass:PlaySupporterKillEffect(hero, victim, item)
	if hero == nil or victim == nil or item == nil or hero:IsNull() or victim:IsNull() then return false end
	local played = false
	local targetParticle = self:GetSupporterItemParticle(item, "particles/kill_effect/default_target.vpcf")
	if targetParticle then
		local particle = ParticleManager:CreateParticle(targetParticle, PATTACH_ABSORIGIN_FOLLOW, victim)
		ParticleManager:SetParticleControl(particle, 0, victim:GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(particle)
		played = true
	end

	local casterParticle = self:GetSupporterItemParticle(item, "particles/kill_effect/default_caster.vpcf")
	if casterParticle then
		local particle = ParticleManager:CreateParticle(casterParticle, PATTACH_ABSORIGIN_FOLLOW, hero)
		ParticleManager:SetParticleControl(particle, 0, hero:GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(particle)
		played = true
	end
	return played
end

function Battlepass:OnSupporterPassEntityKilled(event)
	local victim = event.entindex_killed and EntIndexToHScript(event.entindex_killed) or nil
	local attacker = event.entindex_attacker and EntIndexToHScript(event.entindex_attacker) or nil
	if victim == nil or attacker == nil or victim:IsNull() or attacker:IsNull() then return end
	if victim.xhs_supporter_dev_test_target == true then return end
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
	if item == nil and ItemsGame ~= nil and ItemsGame.GetItemKV ~= nil and ItemsGame:GetItemKV(itemID) ~= nil then
		local itemType = NormalizeSupporterSlot(ItemsGame:GetItemType(itemID))
		item = {
			id = tostring(itemID),
			item_id = tostring(itemID),
			name = ItemsGame:GetItemName(itemID),
			type = itemType,
			item_type = itemType,
			slot_id = itemType,
			unit = ItemsGame:GetItemInfo(itemID, "unit", "nope")
				or ItemsGame:GetItemInfo(itemID, "unit_name", "nope")
				or ItemsGame:GetItemInfo(itemID, "file", "nope"),
		}
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
	return item
end

function Battlepass:CleanupSupporterDevTest(playerID, restoreLoadout)
	self.SUPPORTER_DEV_TESTS = self.SUPPORTER_DEV_TESTS or {}
	local state = self.SUPPORTER_DEV_TESTS[playerID]
	if state ~= nil then
		state.cancelled = true
		if state.timer ~= nil and Timers ~= nil then
			Timers:RemoveTimer(state.timer)
		end
		if state.target ~= nil and not state.target:IsNull() then
			UTIL_Remove(state.target)
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
		self:DonatorStatue(playerID, unitName, true)
		return true
	end

	if reapply == true then return true end
	if slot == "teleport" or slot == "levelup" then
		local catalogItemID = self:GetSupporterCatalogItemID(item)
		local visuals = catalogItemID and ItemsGame:GetItemVisuals(catalogItemID) or nil
		if type(visuals) ~= "table" then return false, "#xhs_sp_dev_test_error_asset" end
		self:SetOverrideAssets(hero, nil, visuals)
	end

	if slot == "teleport" then
		local respawn = BASE_GOOD
		if respawn == nil or respawn:IsNull() then
			respawn = Entities:FindByName(nil, "base_spawn")
		end
		if respawn == nil then return false, "#xhs_sp_dev_test_error_respawn" end
		TeleportHero(hero, respawn:GetAbsOrigin(), 3.0, 1.0)
		return true
	elseif slot == "levelup" then
		local particle = ParticleManager:CreateParticle("particles/generic_hero_status/hero_levelup.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero, hero)
		ParticleManager:SetParticleControl(particle, 0, hero:GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(particle)
		hero:EmitSound("ui.trophy_levelup")
		return true
	elseif slot == "kill_effect" then
		local target = CreateUnitByName("npc_dota_creep_badguys_melee", hero:GetAbsOrigin() + hero:GetForwardVector() * 220, false, hero, hero, DOTA_TEAM_BADGUYS)
		if target == nil then return false, "#xhs_sp_dev_test_error_target" end
		target.xhs_supporter_dev_test_target = true
		target:AddNewModifier(target, nil, "modifier_invulnerable", {})
		target:AddNewModifier(target, nil, "modifier_command_restricted", {})
		state.target = target
		if not self:PlaySupporterKillEffect(hero, target, item) then
			UTIL_Remove(target)
			state.target = nil
			return false, "#xhs_sp_dev_test_error_asset"
		end
		return true
	end
	return false, "#xhs_sp_dev_test_error_type"
end

function Battlepass:ReapplySupporterDevTest(playerID, hero)
	self.SUPPORTER_DEV_TESTS = self.SUPPORTER_DEV_TESTS or {}
	local state = self.SUPPORTER_DEV_TESTS[playerID]
	if state == nil or state.persistent ~= true or not self:IsSupporterDevTestAllowed(playerID) then return end
	self:ApplySupporterDevTestItem(playerID, state, hero, true)
end

function Battlepass:SupporterPassDevTestReward(event_source_index, event)
	event = self:GetSupporterPassEventPayload(event_source_index, event)
	local playerID = event.PlayerID
	if playerID == nil then return end
	local requestID = tostring(event.request_id or "")
	local itemID = tostring(event.item_id or "")
	local slot = NormalizeSupporterSlot(event.slot_id)

	if not self:IsSupporterDevTestAllowed(playerID) then
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
		request_id = requestID,
		persistent = persistent,
		transient = not persistent,
	}
	self.SUPPORTER_DEV_TESTS[playerID] = state
	local success, message = self:ApplySupporterDevTestItem(playerID, state, hero, false)
	if not success then
		self:CleanupSupporterDevTest(playerID, true)
		self:SendSupporterDevTestResult(playerID, requestID, itemID, slot, "error", message)
		return
	end

	self:SendSupporterDevTestResult(playerID, requestID, itemID, slot, "active", "#xhs_sp_dev_test_active")
	if not persistent then
		local duration = slot == "teleport" and 3.6 or 1.8
		state.timer = Timers:CreateTimer(duration, function()
			if self.SUPPORTER_DEV_TESTS[playerID] == state then
				self:CleanupSupporterDevTest(playerID, true)
				self:SendSupporterDevTestResult(playerID, requestID, itemID, slot, "success", "#xhs_sp_dev_test_success")
			end
			return nil
		end)
	end
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

function Battlepass:DonatorCompanionJS(event_source_index, event)
	event = self:GetSupporterPassEventPayload(event_source_index, event)
	local playerID = event.PlayerID
	if playerID == nil then return end
	local unitName = tostring(event.unit or "")
	if unitName ~= "" then
		local companions = LoadKeyValues("scripts/npc/units/companions.txt") or {}
		if type(companions[unitName]) ~= "table" or not api:IsDonator(playerID) then
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
	if type(statues[unitName]) ~= "table" or not api:IsDonator(playerID) then
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
	local sourceIndex = tonumber(event_source_index)
	if sourceIndex ~= nil and sourceIndex > 0 then
		local ok, sender = pcall(EntIndexToHScript, sourceIndex)
		if ok and sender ~= nil and sender.GetPlayerID then
			local playerID = tonumber(sender:GetPlayerID())
			if playerID ~= nil and PlayerResource:IsValidPlayerID(playerID) then
				payload.PlayerID = playerID
			end
		end
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

function Battlepass:FindSupporterPassShopItem(itemID)
	local featured = CustomNetTables:GetTableValue("supporter_pass_shop", "featured") or {}
	for _, item in ipairs(NormalizeSupporterList(featured.items or featured)) do
		if SupporterItemMatches(item, itemID) then
			return item
		end
	end
	return nil
end

function Battlepass:FindSupporterPassReward(rewardID)
	local tableNames = { "supporter_pass_rewards_free", "supporter_pass_rewards_premium" }
	for _, tableName in ipairs(tableNames) do
		local rewards = CustomNetTables:GetTableValue(tableName, "rewards") or {}
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

	api:BuySupporterPassShopItem(playerID, event.item_id, function(success, data)
		local player = PlayerResource:GetPlayer(playerID)
		if not success then
			if player then
				CustomGameEventManager:Send_ServerToPlayer(player, "supporter_pass_purchase_failed", {
					item_id = event.item_id,
					message = data and data.message or nil,
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

	api:EquipSupporterPassItem(playerID, event.item_id, event.hero, itemSlot, function(success, data)
		local player = PlayerResource:GetPlayer(playerID)
		if not player then return end
		if not success and item.legacy and Battlepass:SetLocalSupporterLoadoutItem(playerID, item) then
			success = true
			data = { local_only = true }
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
			message = data and data.message or nil,
			local_only = data and data.local_only or false,
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
				Battlepass:ApplySupporterTag(hero, previous_table.toggle_tag == true or previous_table.toggle_tag == 1)
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
			if settings.toggle_tag ~= nil and hero ~= nil and not hero:IsNull() then
				Battlepass:ApplySupporterTag(hero, settings.toggle_tag)
			end
			if settings.pass_rewards ~= nil then
				Battlepass:ApplySupporterLoadout(playerID, hero)
			end

			if player then
				CustomGameEventManager:Send_ServerToPlayer(player, "supporter_pass_settings_success", {})
			end
		end)
	else
		local hero = PlayerResource:GetSelectedHeroEntity(playerID)
		if settings.toggle_tag ~= nil and hero ~= nil and not hero:IsNull() then
			Battlepass:ApplySupporterTag(hero, settings.toggle_tag)
		end
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
						--						print("Particle:", j)
						local particle_table = {}
						particle_table.asset = j.asset
						particle_table.modifier = j.modifier
						particle_table.parent = hero

						CustomNetTables:SetTableValue("supporter_pass_player", j.asset .. '_' .. playerID, { j.modifier })
						self.SUPPORTER_OVERRIDE_ASSETS[playerID][j.asset] = true
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
