-- Copyright (C) 2026 Frostrose Studio
--
-- Supporter Pass high five runtime.
--
-- This module deliberately owns only the voluntary high-five action. It does
-- not replace any global Dota particle path and it does not add an ability to
-- heroes. Call Init() once from the battlepass bootstrap, then either:
--   * send "xhs_supporter_high_five" from Panorama; or
--   * call SupporterHighFive:Trigger(hero) from trusted server code.

SupporterHighFive = SupporterHighFive or class({})

SupporterHighFive.CLIENT_EVENT = "xhs_supporter_high_five"
SupporterHighFive.RESULT_EVENT = "xhs_supporter_high_five_result"

-- These values mirror the current native Dota high_five ability where useful.
SupporterHighFive.REQUEST_DURATION = 10.0
SupporterHighFive.TRAVEL_SPEED = 700.0
SupporterHighFive.MATCH_RADIUS = 900.0
SupporterHighFive.MIN_TRAVEL_TIME = 0.12
SupporterHighFive.TRIGGER_DEBOUNCE = 0.20

SupporterHighFive.FALLBACK_ASSETS = {
	overhead_pfx = "particles/econ/events/plus/high_five/high_five_overhead.vpcf",
	travel_pfx = "particles/econ/events/plus/high_five/high_five_travel.vpcf",
	impact_pfx = "particles/econ/events/plus/high_five/high_five_impact.vpcf",
}

-- Catalog records may use high_five_family instead of repeating the triplet.
-- Direct fields/runtime_assets still take priority over the family.
SupporterHighFive.FAMILIES = {
	crownfall = {
		overhead_pfx = "particles/econ/events/crownfall/high_five_crownfall_overhead.vpcf",
		travel_pfx = "particles/econ/events/crownfall/high_five_crownfall_travel.vpcf",
		impact_pfx = "particles/econ/events/crownfall/high_five_crownfall_impact.vpcf",
	},
	monster_hunter = {
		overhead_pfx = "particles/econ/events/monster_hunter/high_five/high_five_monster_hunter_overhead.vpcf",
		travel_pfx = "particles/econ/events/monster_hunter/high_five/high_five_monster_hunter_travel.vpcf",
		impact_pfx = "particles/econ/events/monster_hunter/high_five/high_five_monster_hunter_impact.vpcf",
	},
	dark_carnival = {
		overhead_pfx = "particles/econ/events/dark_carnival/high_five/high_five_dark_carnival_overhead.vpcf",
		travel_pfx = "particles/econ/events/dark_carnival/high_five/high_five_dark_carnival_travel.vpcf",
		impact_pfx = "particles/econ/events/dark_carnival/high_five/high_five_dark_carnival_impact.vpcf",
	},
}

SupporterHighFive.NATIVE_ABILITIES = {
	high_five = true,
	plus_high_five = true,
	seasonal_ti10_high_five = true,
	seasonal_diretide2020_high_five = true,
}

local ASSET_FIELDS = {
	overhead_pfx = {
		"overhead_pfx",
		"high_five_overhead_pfx",
		"overhead_particle",
		"particle_overhead",
	},
	travel_pfx = {
		"travel_pfx",
		"high_five_travel_pfx",
		"travel_particle",
		"particle_travel",
	},
	impact_pfx = {
		"impact_pfx",
		"high_five_impact_pfx",
		"impact_particle",
		"particle_impact",
	},
}

local ASSET_CHANNEL_HINTS = {
	overhead_pfx = "overhead",
	travel_pfx = "travel",
	impact_pfx = "impact",
}

local function Now()
	if GameRules ~= nil and GameRules.GetGameTime ~= nil then
		return GameRules:GetGameTime()
	end
	return 0
end

local function IsEntityValid(entity)
	return entity ~= nil and (entity.IsNull == nil or not entity:IsNull())
end

local function EntityIndex(entity)
	if not IsEntityValid(entity) or entity.entindex == nil then
		return nil
	end
	return entity:entindex()
end

local function PlayerIDFromHero(hero)
	if not IsEntityValid(hero) then return nil end

	local playerID = nil
	if hero.GetPlayerOwnerID ~= nil then
		playerID = tonumber(hero:GetPlayerOwnerID())
	end
	if (playerID == nil or playerID < 0) and hero.GetPlayerID ~= nil then
		playerID = tonumber(hero:GetPlayerID())
	end
	return playerID
end

local function IsDisconnected(playerID)
	if PlayerResource == nil or PlayerResource.GetConnectionState == nil then
		return false
	end

	local state = PlayerResource:GetConnectionState(playerID)
	return (DOTA_CONNECTION_STATE_DISCONNECTED ~= nil and state == DOTA_CONNECTION_STATE_DISCONNECTED)
		or (DOTA_CONNECTION_STATE_ABANDONED ~= nil and state == DOTA_CONNECTION_STATE_ABANDONED)
		or (DOTA_CONNECTION_STATE_FAILED ~= nil and state == DOTA_CONNECTION_STATE_FAILED)
end

local function IsTruePlayerHero(hero)
	if not IsEntityValid(hero)
		or hero.IsRealHero == nil
		or not hero:IsRealHero()
		or (hero.IsIllusion ~= nil and hero:IsIllusion())
		or (hero.IsAlive ~= nil and not hero:IsAlive()) then
		return false
	end

	local playerID = PlayerIDFromHero(hero)
	if playerID == nil
		or playerID < 0
		or PlayerResource == nil
		or not PlayerResource:IsValidPlayerID(playerID)
		or IsDisconnected(playerID) then
		return false
	end
	if PlayerResource.IsFakeClient ~= nil and PlayerResource:IsFakeClient(playerID) then
		return false
	end

	-- IsRealHero() also covers a few controllable hero-like duplicates. Requiring
	-- the selected hero keeps hCaster on the player's actual hero.
	if PlayerResource.GetSelectedHeroEntity ~= nil then
		local selected = PlayerResource:GetSelectedHeroEntity(playerID)
		if not IsEntityValid(selected) or EntityIndex(selected) ~= EntityIndex(hero) then
			return false
		end
	end

	return true
end

local function IsParticlePath(value)
	if type(value) ~= "string" or value == "" then return false end
	local normalized = string.lower(string.gsub(value, "\\", "/"))
	return string.sub(normalized, 1, 10) == "particles/"
		and string.sub(normalized, -5) == ".vpcf"
		and string.find(normalized, "..", 1, true) == nil
end

local function CopyTable(source)
	local copy = {}
	if type(source) ~= "table" then return copy end
	for key, value in pairs(source) do
		copy[key] = value
	end
	return copy
end

local function SupporterItemID(item)
	if type(item) ~= "table" then return nil end
	return item.entitlement_id
		or item.item_id
		or item.catalog_item_id
		or item.reward_item_id
		or item.id
end

local function ItemMatchesID(item, expectedID)
	if type(item) ~= "table" or expectedID == nil then return false end
	local expected = tostring(expectedID)
	local fields = {
		item.entitlement_id,
		item.item_id,
		item.catalog_item_id,
		item.reward_item_id,
		item.id,
	}
	for _, value in ipairs(fields) do
		if value ~= nil and tostring(value) == expected then
			return true
		end
	end
	return false
end

local function LooksLikeHighFiveItem(item)
	if type(item) ~= "table" then return false end
	local slot = string.lower(tostring(item.slot_id or item.item_type or item.type or ""))
	if slot == "high_five" or slot == "high five" or slot == "highfive" then
		return true
	end
	return item.overhead_pfx ~= nil
		or item.travel_pfx ~= nil
		or item.impact_pfx ~= nil
		or item.high_five_family ~= nil
end

local function FindCatalogItem(root, expectedID, depth, seen)
	if type(root) ~= "table" or expectedID == nil or depth > 6 then return nil end
	seen = seen or {}
	if seen[root] then return nil end
	seen[root] = true

	if ItemMatchesID(root, expectedID) and LooksLikeHighFiveItem(root) then
		return root
	end

	for _, value in pairs(root) do
		if type(value) == "table" then
			local match = FindCatalogItem(value, expectedID, depth + 1, seen)
			if match ~= nil then return match end
		end
	end
	return nil
end

local function MergeMissing(target, source)
	if type(target) ~= "table" or type(source) ~= "table" then return target end
	for key, value in pairs(source) do
		if (target[key] == nil or target[key] == "") and value ~= nil and value ~= "" then
			target[key] = value
		end
	end
	return target
end

local function ChannelFromHint(value)
	local hint = string.lower(tostring(value or ""))
	for channel, needle in pairs(ASSET_CHANNEL_HINTS) do
		if string.find(hint, needle, 1, true) ~= nil then
			return channel
		end
	end
	return nil
end

local function ReadAssetEntry(assets, entry, keyHint)
	if type(assets) ~= "table" then return end

	if type(entry) == "string" then
		local channel = ChannelFromHint(keyHint)
		if channel ~= nil and assets[channel] == nil and IsParticlePath(entry) then
			assets[channel] = entry
		end
		return
	end
	if type(entry) ~= "table" then return end

	local path = entry.path
		or entry.modifier
		or entry.particle
		or entry.pfx
		or entry.file
	local channel = ChannelFromHint(
		entry.channel
		or entry.role
		or entry.asset
		or entry.hook
		or entry.name
		or keyHint
	)
	if channel ~= nil and assets[channel] == nil and IsParticlePath(path) then
		assets[channel] = path
	end
end

local function ReadAssetsFromRecord(assets, record)
	if type(record) ~= "table" then return end

	for channel, fields in pairs(ASSET_FIELDS) do
		for _, field in ipairs(fields) do
			local value = record[field]
			if assets[channel] == nil and IsParticlePath(value) then
				assets[channel] = value
				break
			end
		end
	end

	for key, entry in pairs(record.runtime_assets or {}) do
		ReadAssetEntry(assets, entry, key)
	end
	for key, entry in pairs(record.visuals or {}) do
		ReadAssetEntry(assets, entry, key)
	end
end

local function VectorDistance2D(a, b)
	if a == nil or b == nil then return math.huge end
	local x = (a.x or 0) - (b.x or 0)
	local y = (a.y or 0) - (b.y or 0)
	return math.sqrt(x * x + y * y)
end

local function Midpoint(a, b)
	return Vector(
		((a.x or 0) + (b.x or 0)) * 0.5,
		((a.y or 0) + (b.y or 0)) * 0.5,
		((a.z or 0) + (b.z or 0)) * 0.5
	)
end

local function VelocityTowards(origin, destination, speed)
	local x = (destination.x or 0) - (origin.x or 0)
	local y = (destination.y or 0) - (origin.y or 0)
	local length = math.sqrt(x * x + y * y)
	if length <= 0.001 then return Vector(0, 0, 0) end
	return Vector(x / length * speed, y / length * speed, 0)
end

function SupporterHighFive:Debug(...)
	if IsInToolsMode ~= nil and IsInToolsMode() then
		print("[Supporter High Five]", ...)
	end
end

function SupporterHighFive:Schedule(delay, callback)
	if Timers ~= nil and Timers.CreateTimer ~= nil then
		return Timers:CreateTimer(delay, callback)
	end

	-- Timers is present in XHS, but this fallback keeps the isolated module
	-- executable from a minimal custom-game harness.
	self.nextThinkID = (self.nextThinkID or 0) + 1
	local thinkName = "xhs_supporter_high_five_" .. tostring(self.nextThinkID)
	local gameMode = GameRules ~= nil and GameRules:GetGameModeEntity() or nil
	if gameMode ~= nil and gameMode.SetContextThink ~= nil then
		gameMode:SetContextThink(thinkName, function()
			callback()
			return nil
		end, delay)
		return { context_think = thinkName }
	end
	return nil
end

function SupporterHighFive:CancelTimer(timer)
	if timer ~= nil and Timers ~= nil and Timers.RemoveTimer ~= nil then
		Timers:RemoveTimer(timer)
	end
end

function SupporterHighFive:DestroyParticle(particle, immediate)
	if particle == nil or ParticleManager == nil then return end
	ParticleManager:DestroyParticle(particle, immediate == true)
	ParticleManager:ReleaseParticleIndex(particle)
end

function SupporterHighFive:SendResult(playerID, status, payload)
	if playerID == nil
		or PlayerResource == nil
		or not PlayerResource:IsValidPlayerID(playerID)
		or CustomGameEventManager == nil then
		return
	end

	local player = PlayerResource:GetPlayer(playerID)
	if player == nil then return end
	local message = CopyTable(payload)
	message.status = status
	CustomGameEventManager:Send_ServerToPlayer(player, self.RESULT_EVENT, message)
end

function SupporterHighFive:GetEquippedItem(playerID)
	local item = nil
	if Battlepass ~= nil and Battlepass.GetEquippedSupporterItem ~= nil then
		local rewardsEnabled = Battlepass.AreSupporterRewardsEnabled == nil
			or Battlepass:AreSupporterRewardsEnabled(playerID)
		if rewardsEnabled then
			item = Battlepass:GetEquippedSupporterItem(playerID, "high_five")
		end
	end
	if type(item) ~= "table" then return nil end

	item = CopyTable(item)
	local itemID = SupporterItemID(item)
	if itemID == nil then return item end

	-- Loadouts may intentionally contain identity fields only. Hydrate the
	-- server-owned item from every catalog source available to this module.
	if ItemsGame ~= nil and ItemsGame.GetItemKV ~= nil then
		MergeMissing(item, ItemsGame:GetItemKV(itemID))
	end
	if api ~= nil and api.supporter_pass ~= nil then
		MergeMissing(item, FindCatalogItem(api.supporter_pass.rewards, itemID, 0))
	end
	if CustomNetTables ~= nil then
		local free = CustomNetTables:GetTableValue("supporter_pass_rewards_free", "rewards")
		local premium = CustomNetTables:GetTableValue("supporter_pass_rewards_premium", "rewards")
		MergeMissing(item, FindCatalogItem(free, itemID, 0))
		MergeMissing(item, FindCatalogItem(premium, itemID, 0))
	end

	if item.runtime_assets == nil
		and ItemsGame ~= nil
		and ItemsGame.GetItemRuntimeAssets ~= nil
		and ItemsGame.GetItemKV ~= nil
		and ItemsGame:GetItemKV(itemID) ~= nil then
		item.runtime_assets = ItemsGame:GetItemRuntimeAssets(itemID)
	end
	if item.visuals == nil
		and ItemsGame ~= nil
		and ItemsGame.GetItemVisuals ~= nil
		and ItemsGame.GetItemKV ~= nil
		and ItemsGame:GetItemKV(itemID) ~= nil then
		item.visuals = ItemsGame:GetItemVisuals(itemID)
	end

	return item
end

function SupporterHighFive:ResolveAssets(hero, allowFallbackWithoutItem)
	local playerID = PlayerIDFromHero(hero)
	local item = playerID ~= nil and self:GetEquippedItem(playerID) or nil
	local assets = {}
	ReadAssetsFromRecord(assets, item)

	local familyName = type(item) == "table"
		and string.lower(tostring(item.high_five_family or item.particle_family or ""))
		or ""
	familyName = string.gsub(familyName, "[%s%-]+", "_")
	local family = self.FAMILIES[familyName]
	if family ~= nil then
		for channel, path in pairs(family) do
			if assets[channel] == nil and IsParticlePath(path) then
				assets[channel] = path
			end
		end
	end

	-- A direct Trigger()/Panorama action needs a complete vanilla fallback.
	-- Native ability casts already render their own vanilla high five, so an
	-- unequipped player participates in matching without doubling those PFX.
	if item ~= nil or allowFallbackWithoutItem ~= false then
		for channel, path in pairs(self.FALLBACK_ASSETS) do
			if assets[channel] == nil then
				assets[channel] = path
			end
		end
	end
	return assets, item
end

function SupporterHighFive:CreateOverhead(hero, particleName)
	if not IsTruePlayerHero(hero) or not IsParticlePath(particleName) then return nil end
	local particle = ParticleManager:CreateParticle(particleName, PATTACH_OVERHEAD_FOLLOW, hero)
	if particle == nil or particle < 0 then return nil end
	ParticleManager:SetParticleControlEnt(
		particle,
		0,
		hero,
		PATTACH_OVERHEAD_FOLLOW,
		"attach_hitloc",
		hero:GetAbsOrigin(),
		true
	)
	return particle
end

function SupporterHighFive:CreateTravel(origin, destination, particleName)
	if not IsParticlePath(particleName) then return nil end
	local particle = ParticleManager:CreateParticle(particleName, PATTACH_WORLDORIGIN, nil)
	if particle == nil or particle < 0 then return nil end
	ParticleManager:SetParticleControl(particle, 0, origin)
	ParticleManager:SetParticleControl(
		particle,
		1,
		VelocityTowards(origin, destination, self.TRAVEL_SPEED)
	)
	return particle
end

function SupporterHighFive:CreateImpact(origin, particleName)
	if not IsParticlePath(particleName) then return nil end
	local particle = ParticleManager:CreateParticle(particleName, PATTACH_WORLDORIGIN, nil)
	if particle == nil or particle < 0 then return nil end

	-- The modern high-five impact parents initialize at CP3. Setting CP0 as
	-- well keeps the Plus fallback and older triplets compatible.
	ParticleManager:SetParticleControl(particle, 0, origin)
	ParticleManager:SetParticleControl(particle, 3, origin)
	ParticleManager:ReleaseParticleIndex(particle)
	return particle
end

function SupporterHighFive:RemoveRequest(state, reason, notify)
	if type(state) ~= "table" or state.removed == true then return end
	state.removed = true
	state.status = reason or "cancelled"

	if state.timer ~= nil then
		self:CancelTimer(state.timer)
		state.timer = nil
	end
	if state.overhead_particle ~= nil then
		self:DestroyParticle(state.overhead_particle, false)
		state.overhead_particle = nil
	end

	if self.requestsByPlayer[state.player_id] == state then
		self.requestsByPlayer[state.player_id] = nil
	end
	if self.requestsByHero[state.hero_entindex] == state then
		self.requestsByHero[state.hero_entindex] = nil
	end

	if notify == true then
		self:SendResult(state.player_id, state.status, {
			hero_entindex = state.hero_entindex,
		})
	end
end

function SupporterHighFive:CancelMatch(match, reason, notify)
	if type(match) ~= "table" or match.cancelled == true then return end
	match.cancelled = true

	if match.timer ~= nil then
		self:CancelTimer(match.timer)
		match.timer = nil
	end
	for _, particle in ipairs(match.travel_particles or {}) do
		self:DestroyParticle(particle, true)
	end
	match.travel_particles = {}
	self.activeMatches[match.id] = nil

	if notify == true then
		for _, playerID in ipairs(match.player_ids or {}) do
			self:SendResult(playerID, reason or "cancelled", {
				match_id = match.id,
			})
		end
	end
end

function SupporterHighFive:CleanupHero(hero, reason)
	local heroIndex = EntityIndex(hero)
	if heroIndex == nil then return end

	local request = self.requestsByHero[heroIndex]
	if request ~= nil then
		self:RemoveRequest(request, reason or "cancelled", true)
	end
	for _, match in pairs(self.activeMatches) do
		if match.hero_indices[heroIndex] == true then
			self:CancelMatch(match, reason or "cancelled", true)
		end
	end
end

function SupporterHighFive:CleanupPlayer(playerID, reason)
	playerID = tonumber(playerID)
	if playerID == nil then return end

	local request = self.requestsByPlayer[playerID]
	if request ~= nil then
		self:RemoveRequest(request, reason or "cancelled", true)
	end
	for _, match in pairs(self.activeMatches) do
		if match.player_set[playerID] == true then
			self:CancelMatch(match, reason or "cancelled", true)
		end
	end
end

function SupporterHighFive:FindPartner(hero)
	local heroOrigin = hero:GetAbsOrigin()
	local heroTeam = hero:GetTeamNumber()
	local closest = nil
	local closestDistance = math.huge
	local currentTime = Now()

	for _, request in pairs(self.requestsByPlayer) do
		local candidate = request.hero
		if request.removed ~= true and request.expires_at > currentTime then
			if not IsTruePlayerHero(candidate) then
				self:RemoveRequest(request, "cancelled", true)
			elseif candidate:GetTeamNumber() == heroTeam
				and EntityIndex(candidate) ~= EntityIndex(hero) then
				local distance = VectorDistance2D(heroOrigin, candidate:GetAbsOrigin())
				if distance <= self.MATCH_RADIUS and distance < closestDistance then
					closest = request
					closestDistance = distance
				end
			end
		end
	end
	return closest, closestDistance
end

function SupporterHighFive:CompleteMatch(match)
	if type(match) ~= "table"
		or match.cancelled == true
		or self.activeMatches[match.id] ~= match then
		return
	end
	match.timer = nil

	if not IsTruePlayerHero(match.heroes[1]) or not IsTruePlayerHero(match.heroes[2]) then
		self:CancelMatch(match, "cancelled", true)
		return
	end

	for _, particle in ipairs(match.travel_particles or {}) do
		self:DestroyParticle(particle, false)
	end
	match.travel_particles = {}

	local playedImpacts = {}
	for _, assets in ipairs(match.assets) do
		local particleName = assets.impact_pfx
		if IsParticlePath(particleName) and playedImpacts[particleName] ~= true then
			playedImpacts[particleName] = true
			self:CreateImpact(match.impact_origin, particleName)
		end
	end

	self.activeMatches[match.id] = nil
	for index, playerID in ipairs(match.player_ids) do
		self:SendResult(playerID, "impact", {
			match_id = match.id,
			partner_player_id = match.player_ids[index == 1 and 2 or 1],
		})
	end
	self:Debug("impact", match.id)
end

function SupporterHighFive:Match(firstRequest, secondHero, secondAssets)
	local firstHero = firstRequest.hero
	if not IsTruePlayerHero(firstHero) or not IsTruePlayerHero(secondHero) then
		return false, "invalid_hero"
	end
	if firstHero:GetTeamNumber() ~= secondHero:GetTeamNumber() then
		return false, "not_allied"
	end

	local firstOrigin = firstHero:GetAbsOrigin()
	local secondOrigin = secondHero:GetAbsOrigin()
	local distance = VectorDistance2D(firstOrigin, secondOrigin)
	if distance > self.MATCH_RADIUS then
		return false, "out_of_range"
	end

	local firstPlayerID = firstRequest.player_id
	local secondPlayerID = PlayerIDFromHero(secondHero)
	local firstAssets = firstRequest.assets
	self:RemoveRequest(firstRequest, "matched", false)

	self.nextMatchID = (self.nextMatchID or 0) + 1
	local matchID = self.nextMatchID
	local impactOrigin = Midpoint(firstOrigin, secondOrigin)
	local match = {
		id = matchID,
		heroes = { firstHero, secondHero },
		hero_indices = {
			[EntityIndex(firstHero)] = true,
			[EntityIndex(secondHero)] = true,
		},
		player_ids = { firstPlayerID, secondPlayerID },
		player_set = {
			[firstPlayerID] = true,
			[secondPlayerID] = true,
		},
		assets = { firstAssets, secondAssets },
		impact_origin = impactOrigin,
		travel_particles = {},
	}
	self.activeMatches[matchID] = match

	local firstTravel = self:CreateTravel(firstOrigin, impactOrigin, firstAssets.travel_pfx)
	if firstTravel ~= nil then table.insert(match.travel_particles, firstTravel) end
	local secondTravel = self:CreateTravel(secondOrigin, impactOrigin, secondAssets.travel_pfx)
	if secondTravel ~= nil then table.insert(match.travel_particles, secondTravel) end

	local travelTime = math.max((distance * 0.5) / self.TRAVEL_SPEED, self.MIN_TRAVEL_TIME)
	for index, playerID in ipairs(match.player_ids) do
		self:SendResult(playerID, "matched", {
			match_id = matchID,
			partner_player_id = match.player_ids[index == 1 and 2 or 1],
			travel_time = travelTime,
		})
	end

	match.timer = self:Schedule(travelTime, function()
		self:CompleteMatch(match)
		return nil
	end)
	self:Debug("matched", firstPlayerID, secondPlayerID, "distance", distance)
	return true, "matched", match
end

function SupporterHighFive:CreateRequest(hero, assets)
	local playerID = PlayerIDFromHero(hero)
	local heroIndex = EntityIndex(hero)
	local state = {
		player_id = playerID,
		hero_entindex = heroIndex,
		hero = hero,
		assets = assets,
		started_at = Now(),
		expires_at = Now() + self.REQUEST_DURATION,
		status = "pending",
	}
	state.overhead_particle = self:CreateOverhead(hero, assets.overhead_pfx)
	self.requestsByPlayer[playerID] = state
	self.requestsByHero[heroIndex] = state

	state.timer = self:Schedule(self.REQUEST_DURATION, function()
		if self.requestsByPlayer[playerID] == state and state.removed ~= true then
			state.timer = nil
			self:RemoveRequest(state, "expired", true)
		end
		return nil
	end)

	self:SendResult(playerID, "pending", {
		hero_entindex = heroIndex,
		duration = self.REQUEST_DURATION,
		expires_at = state.expires_at,
	})
	self:Debug("pending", playerID, heroIndex)
	return true, "pending", state
end

function SupporterHighFive:Trigger(hero, options)
	if not IsTruePlayerHero(hero) then
		return false, "invalid_hero"
	end
	options = type(options) == "table" and options or {}

	local playerID = PlayerIDFromHero(hero)
	local heroIndex = EntityIndex(hero)
	local currentTime = Now()
	if currentTime - (self.lastTriggerAt[heroIndex] or -100) < self.TRIGGER_DEBOUNCE then
		return false, "rate_limited"
	end
	self.lastTriggerAt[heroIndex] = currentTime

	local ownRequest = self.requestsByPlayer[playerID]
	if ownRequest ~= nil and ownRequest.removed ~= true then
		self:SendResult(playerID, "pending", {
			hero_entindex = heroIndex,
			duration = math.max(ownRequest.expires_at - currentTime, 0),
			expires_at = ownRequest.expires_at,
		})
		return true, "pending", ownRequest
	end

	local assets = self:ResolveAssets(hero, options.native ~= true)
	local partner = self:FindPartner(hero)
	if partner ~= nil then
		return self:Match(partner, hero, assets)
	end
	return self:CreateRequest(hero, assets)
end

function SupporterHighFive:HeroFromClientEvent(sourceIndex)
	local numericSourceIndex = tonumber(sourceIndex)
	if numericSourceIndex == nil or numericSourceIndex <= 0 then return nil end

	local ok, player = pcall(EntIndexToHScript, numericSourceIndex)
	if not ok or player == nil or player.GetPlayerID == nil then return nil end
	local playerID = tonumber(player:GetPlayerID())
	if playerID == nil or not PlayerResource:IsValidPlayerID(playerID) then return nil end

	local hero = PlayerResource:GetSelectedHeroEntity(playerID)
	if not IsTruePlayerHero(hero) or PlayerIDFromHero(hero) ~= playerID then return nil end
	return hero
end

function SupporterHighFive:OnClientTrigger(sourceIndex, _event)
	local hero = self:HeroFromClientEvent(sourceIndex)
	if hero == nil then return end
	local success, status = self:Trigger(hero)
	if not success then
		self:SendResult(PlayerIDFromHero(hero), "error", { reason = status })
	end
end

function SupporterHighFive:OnNativeAbilityUsed(event)
	if type(event) ~= "table"
		or self.NATIVE_ABILITIES[tostring(event.abilityname or "")] ~= true then
		return
	end

	local casterIndex = tonumber(event.caster_entindex)
	if casterIndex == nil then return end
	local ok, hero = pcall(EntIndexToHScript, casterIndex)
	if not ok or not IsTruePlayerHero(hero) then return end

	local eventPlayerID = tonumber(event.PlayerID)
	if eventPlayerID ~= nil and eventPlayerID >= 0 and eventPlayerID ~= PlayerIDFromHero(hero) then
		return
	end
	local success, status = self:Trigger(hero, { native = true })
	if not success and status ~= "rate_limited" then
		self:SendResult(PlayerIDFromHero(hero), "error", { reason = status })
	end
end

function SupporterHighFive:Reset()
	local requests = {}
	for _, request in pairs(self.requestsByPlayer or {}) do
		table.insert(requests, request)
	end
	for _, request in ipairs(requests) do
		self:RemoveRequest(request, "cancelled", false)
	end

	local matches = {}
	for _, match in pairs(self.activeMatches or {}) do
		table.insert(matches, match)
	end
	for _, match in ipairs(matches) do
		self:CancelMatch(match, "cancelled", false)
	end

	self.requestsByPlayer = {}
	self.requestsByHero = {}
	self.activeMatches = {}
	self.lastTriggerAt = {}
end

function SupporterHighFive:Init()
	if self.initialized == true then return self end
	self.initialized = true
	self.requestsByPlayer = self.requestsByPlayer or {}
	self.requestsByHero = self.requestsByHero or {}
	self.activeMatches = self.activeMatches or {}
	self.lastTriggerAt = self.lastTriggerAt or {}

	CustomGameEventManager:RegisterListener(self.CLIENT_EVENT, function(sourceIndex, event)
		self:OnClientTrigger(sourceIndex, event)
	end)

	ListenToGameEvent("dota_player_used_ability", function(event)
		self:OnNativeAbilityUsed(event)
	end, nil)
	ListenToGameEvent("entity_killed", function(event)
		local entityIndex = tonumber(event.entindex_killed)
		if entityIndex == nil then return end
		local ok, entity = pcall(EntIndexToHScript, entityIndex)
		if ok and IsEntityValid(entity) then
			self:CleanupHero(entity, "death")
		end
	end, nil)
	ListenToGameEvent("player_disconnect", function(event)
		self:CleanupPlayer(event.PlayerID or event.playerid, "disconnected")
	end, nil)
	ListenToGameEvent("game_rules_state_change", function()
		if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then
			self:Reset()
		end
	end, nil)

	self:Debug("initialized")
	return self
end

return SupporterHighFive
