-- Copyright (C) 2026 Frostrose Studio
--
-- Supporter Pass high five ability.
--
-- This is a standalone Lua ability inspired by bukkadev/community-custom-heroes
-- PR #15. It does not depend on Valve's plus_high_five implementation.

LinkLuaModifier(
	"modifier_xhs_high_five_request",
	"components/battlepass/high_five.lua",
	LUA_MODIFIER_MOTION_NONE
)

xhs_high_five = xhs_high_five or class({})

SupporterHighFive = SupporterHighFive or class({})

SupporterHighFive.CLIENT_EVENT = "xhs_supporter_high_five"
SupporterHighFive.RESULT_EVENT = "xhs_supporter_high_five_result"
SupporterHighFive.ABILITY_NAME = "xhs_high_five"

SupporterHighFive.REQUEST_DURATION = 10.0
SupporterHighFive.MATCH_RADIUS = 900.0
SupporterHighFive.TRAVEL_SPEED = 700.0
SupporterHighFive.MIN_TRAVEL_TIME = 0.12
SupporterHighFive.TRIGGER_DEBOUNCE = 0.20
SupporterHighFive.SUCCESS_COOLDOWN = 1.0

SupporterHighFive.DEFAULT_ASSETS = {
	overhead_pfx = "particles/econ/events/plus/high_five/high_five_overhead.vpcf",
	travel_pfx = "particles/econ/events/plus/high_five/high_five_travel.vpcf",
	impact_pfx = "particles/econ/events/plus/high_five/high_five_impact.vpcf",
}

SupporterHighFive.FAMILIES = {
	foam_hand = {
		overhead_pfx = "particles/econ/events/fall_2022/high_five/high_five_foam_hand_overhead.vpcf",
		travel_pfx = "particles/econ/events/fall_2022/high_five/high_five_foam_hand_travel.vpcf",
		impact_pfx = "particles/econ/events/fall_2022/high_five/high_five_foam_hand_impact.vpcf",
	},
	crownfall = {
		overhead_pfx = "particles/econ/events/crownfall/high_five_crownfall_overhead.vpcf",
		travel_pfx = "particles/econ/events/crownfall/high_five_crownfall_travel.vpcf",
		impact_pfx = "particles/econ/events/crownfall/high_five_crownfall_impact.vpcf",
	},
	high_five_mug = {
		overhead_pfx = "particles/econ/events/frostivus_2023/high_five_mug_overhead.vpcf",
		travel_pfx = "particles/econ/events/frostivus_2023/high_five_mug_travel.vpcf",
		impact_pfx = "particles/econ/events/frostivus_2023/high_five_mug_impact.vpcf",
	},
	dark_carnival = {
		overhead_pfx = "particles/econ/events/dark_carnival/high_five/high_five_dark_carnival_overhead.vpcf",
		travel_pfx = "particles/econ/events/dark_carnival/high_five/high_five_dark_carnival_travel.vpcf",
		impact_pfx = "particles/econ/events/dark_carnival/high_five/high_five_dark_carnival_impact.vpcf",
	},
	monster_hunter = {
		overhead_pfx = "particles/econ/events/monster_hunter/high_five/high_five_monster_hunter_overhead.vpcf",
		travel_pfx = "particles/econ/events/monster_hunter/high_five/high_five_monster_hunter_travel.vpcf",
		impact_pfx = "particles/econ/events/monster_hunter/high_five/high_five_monster_hunter_impact.vpcf",
	},
}

SupporterHighFive.OBSOLETE_NATIVE_ABILITIES = {
	high_five = true,
	plus_high_five = true,
	seasonal_ti10_high_five = true,
	seasonal_diretide2020_high_five = true,
}

function xhs_high_five:OnSpellStart()
	if not IsServer() then return end
	local success = SupporterHighFive:Trigger(self:GetCaster(), self)
	if not success then self:EndCooldown() end
end

modifier_xhs_high_five_request = modifier_xhs_high_five_request or class({})

function modifier_xhs_high_five_request:IsHidden() return true end
function modifier_xhs_high_five_request:IsPurgable() return false end
function modifier_xhs_high_five_request:RemoveOnDeath() return true end

function modifier_xhs_high_five_request:OnDestroy()
	if not IsServer() or SupporterHighFive == nil then return end
	SupporterHighFive:OnRequestModifierDestroyed(self:GetParent(), self)
end

local function IsValid(entity)
	return entity ~= nil and (entity.IsNull == nil or not entity:IsNull())
end

local function EntityIndex(entity)
	if not IsValid(entity) or entity.entindex == nil then return nil end
	return entity:entindex()
end

local function GameTime()
	if GameRules ~= nil and GameRules.GetGameTime ~= nil then
		return GameRules:GetGameTime()
	end
	return 0
end

local function PlayerIDFromHero(hero)
	if not IsValid(hero) then return nil end
	local playerID = hero.GetPlayerOwnerID ~= nil and tonumber(hero:GetPlayerOwnerID()) or nil
	if (playerID == nil or playerID < 0) and hero.GetPlayerID ~= nil then
		playerID = tonumber(hero:GetPlayerID())
	end
	return playerID
end

local function IsDisconnected(playerID)
	if PlayerResource == nil or PlayerResource.GetConnectionState == nil then return false end
	local state = PlayerResource:GetConnectionState(playerID)
	return (DOTA_CONNECTION_STATE_DISCONNECTED ~= nil and state == DOTA_CONNECTION_STATE_DISCONNECTED)
		or (DOTA_CONNECTION_STATE_ABANDONED ~= nil and state == DOTA_CONNECTION_STATE_ABANDONED)
		or (DOTA_CONNECTION_STATE_FAILED ~= nil and state == DOTA_CONNECTION_STATE_FAILED)
end

local function IsTruePlayerHero(hero)
	if not IsValid(hero)
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
		or IsDisconnected(playerID)
		or (PlayerResource.IsFakeClient ~= nil and PlayerResource:IsFakeClient(playerID)) then
		return false
	end

	if PlayerResource.GetSelectedHeroEntity ~= nil then
		local selectedHero = PlayerResource:GetSelectedHeroEntity(playerID)
		if EntityIndex(selectedHero) ~= EntityIndex(hero) then return false end
	end
	return true
end

local function IsParticlePath(path)
	if type(path) ~= "string" or path == "" then return false end
	path = string.lower(string.gsub(path, "\\", "/"))
	return string.sub(path, 1, 10) == "particles/"
		and string.sub(path, -5) == ".vpcf"
		and string.find(path, "..", 1, true) == nil
end

local function Copy(source)
	local result = {}
	if type(source) ~= "table" then return result end
	for key, value in pairs(source) do result[key] = value end
	return result
end

local function Distance2D(a, b)
	local x = (b.x or 0) - (a.x or 0)
	local y = (b.y or 0) - (a.y or 0)
	return math.sqrt(x * x + y * y)
end

local function Midpoint(a, b)
	return Vector(
		((a.x or 0) + (b.x or 0)) * 0.5,
		((a.y or 0) + (b.y or 0)) * 0.5,
		((a.z or 0) + (b.z or 0)) * 0.5
	)
end

local function Velocity(origin, destination, speed)
	local x = (destination.x or 0) - (origin.x or 0)
	local y = (destination.y or 0) - (origin.y or 0)
	local length = math.sqrt(x * x + y * y)
	if length <= 0.001 then return Vector(0, 0, 0) end
	return Vector(x * speed / length, y * speed / length, 0)
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

function SupporterHighFive:FindAbility(hero)
	if not IsValid(hero) or hero.FindAbilityByName == nil then return nil end
	local ability = hero:FindAbilityByName(self.ABILITY_NAME)
	return IsValid(ability) and ability or nil
end

function SupporterHighFive:EnsureAbility(hero)
	if not IsTruePlayerHero(hero) then return nil end
	for abilityName in pairs(self.OBSOLETE_NATIVE_ABILITIES) do
		if hero:FindAbilityByName(abilityName) ~= nil then
			hero:RemoveAbility(abilityName)
		end
	end
	local ability = self:FindAbility(hero)
	if ability == nil and hero.AddAbility ~= nil then
		ability = hero:AddAbility(self.ABILITY_NAME)
	end
	if not IsValid(ability) then return nil end
	if ability.GetLevel ~= nil and ability.SetLevel ~= nil and ability:GetLevel() < 1 then
		ability:SetLevel(1)
	end
	return ability
end

function SupporterHighFive:SetSuccessCooldown(hero)
	local ability = self:FindAbility(hero)
	if not IsValid(ability) then return end
	if ability.EndCooldown ~= nil then ability:EndCooldown() end
	if ability.StartCooldown ~= nil then ability:StartCooldown(self.SUCCESS_COOLDOWN) end
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
	local event = Copy(payload)
	event.status = status
	CustomGameEventManager:Send_ServerToPlayer(player, self.RESULT_EVENT, event)
end

function SupporterHighFive:ResolveAssets(hero)
	local playerID = PlayerIDFromHero(hero)
	local item = nil
	if playerID ~= nil
		and Battlepass ~= nil
		and Battlepass.GetEquippedSupporterItem ~= nil
		and (Battlepass.AreSupporterRewardsEnabled == nil
			or Battlepass:AreSupporterRewardsEnabled(playerID)) then
		item = Battlepass:GetEquippedSupporterItem(playerID, "high_five")
	end

	local assets = {}
	if type(item) == "table" then
		for _, key in ipairs({ "overhead_pfx", "travel_pfx", "impact_pfx" }) do
			if IsParticlePath(item[key]) then assets[key] = item[key] end
		end

		local runtime = type(item.runtime_assets) == "table" and item.runtime_assets or nil
		if runtime ~= nil then
			for _, key in ipairs({ "overhead_pfx", "travel_pfx", "impact_pfx" }) do
				if assets[key] == nil and IsParticlePath(runtime[key]) then
					assets[key] = runtime[key]
				end
			end
		end

		local familyName = string.lower(tostring(
			item.family or item.high_five_family or item.particle_family or ""
		))
		familyName = string.gsub(familyName, "[%s%-]+", "_")
		local family = self.FAMILIES[familyName]
		if family ~= nil then
			for key, path in pairs(family) do
				if assets[key] == nil then assets[key] = path end
			end
		end
	end

	-- Unequipped players use the ordinary Plus particle family while the
	-- gameplay remains entirely owned by xhs_high_five.
	for key, path in pairs(self.DEFAULT_ASSETS) do
		if assets[key] == nil then assets[key] = path end
	end
	return assets
end

function SupporterHighFive:CreateOverhead(hero, particleName)
	if not IsTruePlayerHero(hero) or not IsParticlePath(particleName) then return nil end
	-- PATTACH_OVERHEAD_FOLLOW supplies CP0 and the correct overhead offset.
	-- Manually binding CP0 to attach_hitloc collapses that authored offset.
	local particle = ParticleManager:CreateParticle(particleName, PATTACH_OVERHEAD_FOLLOW, hero)
	return particle ~= nil and particle >= 0 and particle or nil
end

function SupporterHighFive:CreateTravel(origin, destination, particleName)
	if not IsParticlePath(particleName) then return nil end
	local particle = ParticleManager:CreateParticle(particleName, PATTACH_WORLDORIGIN, nil)
	if particle == nil or particle < 0 then return nil end
	-- All five authored travel parents use CP0 as their spawn position and
	-- C_INIT_VelocityFromCP on CP1.
	ParticleManager:SetParticleControl(particle, 0, origin)
	ParticleManager:SetParticleControl(particle, 1, Velocity(origin, destination, self.TRAVEL_SPEED))
	return particle
end

function SupporterHighFive:CreateImpact(origin, particleName)
	if not IsParticlePath(particleName) then return nil end
	local particle = ParticleManager:CreateParticle(particleName, PATTACH_WORLDORIGIN, nil)
	if particle == nil or particle < 0 then return nil end
	-- High-five impact parents spawn their children from CP3. CP0 is retained
	-- for child systems and backwards-compatible Plus assets.
	ParticleManager:SetParticleControl(particle, 0, origin)
	ParticleManager:SetParticleControl(particle, 3, origin)
	ParticleManager:ReleaseParticleIndex(particle)
	return particle
end

function SupporterHighFive:RemoveRequest(request, reason, notify)
	if type(request) ~= "table" or request.removed == true then return end
	request.removed = true
	self:CancelTimer(request.timer)
	request.timer = nil
	if IsValid(request.modifier) then
		request.removing_modifier = true
		request.modifier:Destroy()
		request.modifier = nil
	end
	self:DestroyParticle(request.overhead, false)
	request.overhead = nil

	if self.requestsByPlayer[request.player_id] == request then
		self.requestsByPlayer[request.player_id] = nil
	end
	if self.requestsByHero[request.hero_entindex] == request then
		self.requestsByHero[request.hero_entindex] = nil
	end
	if notify == true then
		self:SendResult(request.player_id, reason or "cancelled", {
			hero_entindex = request.hero_entindex,
		})
	end
end

function SupporterHighFive:OnRequestModifierDestroyed(hero, modifier)
	local request = self.requestsByHero[EntityIndex(hero)]
	if request == nil
		or request.removed == true
		or request.removing_modifier == true
		or request.modifier ~= modifier then
		return
	end
	request.modifier = nil
	self:RemoveRequest(request, "expired", true)
end

function SupporterHighFive:CancelMatch(match, reason, notify)
	if type(match) ~= "table" or match.cancelled == true then return end
	match.cancelled = true
	self:CancelTimer(match.timer)
	match.timer = nil
	for _, particle in ipairs(match.travel_particles or {}) do
		self:DestroyParticle(particle, true)
	end
	match.travel_particles = {}
	self.matches[match.id] = nil

	if notify == true then
		for _, playerID in ipairs(match.player_ids or {}) do
			self:SendResult(playerID, reason or "cancelled", { match_id = match.id })
		end
	end
end

function SupporterHighFive:CleanupHero(hero, reason)
	local heroIndex = EntityIndex(hero)
	if heroIndex == nil then return end
	local request = self.requestsByHero[heroIndex]
	if request ~= nil then self:RemoveRequest(request, reason or "cancelled", true) end

	local matches = {}
	for _, match in pairs(self.matches) do
		if match.hero_indices[heroIndex] == true then table.insert(matches, match) end
	end
	for _, match in ipairs(matches) do
		self:CancelMatch(match, reason or "cancelled", true)
	end
end

function SupporterHighFive:CleanupPlayer(playerID, reason)
	playerID = tonumber(playerID)
	if playerID == nil then return end
	local request = self.requestsByPlayer[playerID]
	if request ~= nil then self:RemoveRequest(request, reason or "cancelled", true) end

	local matches = {}
	for _, match in pairs(self.matches) do
		if match.player_set[playerID] == true then table.insert(matches, match) end
	end
	for _, match in ipairs(matches) do
		self:CancelMatch(match, reason or "cancelled", true)
	end
end

function SupporterHighFive:FindPartner(hero)
	local closest = nil
	local closestDistance = math.huge
	local heroOrigin = hero:GetAbsOrigin()
	local heroIndex = EntityIndex(hero)
	local heroTeam = hero:GetTeamNumber()
	local now = GameTime()
	local invalid = {}

	for _, request in pairs(self.requestsByPlayer) do
		local candidate = request.hero
		if request.removed ~= true and request.expires_at > now then
			if not IsTruePlayerHero(candidate) then
				table.insert(invalid, request)
			elseif EntityIndex(candidate) ~= heroIndex and candidate:GetTeamNumber() == heroTeam then
				local distance = Distance2D(heroOrigin, candidate:GetAbsOrigin())
				if distance <= self.MATCH_RADIUS and distance < closestDistance then
					closest = request
					closestDistance = distance
				end
			end
		end
	end
	for _, request in ipairs(invalid) do
		self:RemoveRequest(request, "cancelled", true)
	end
	return closest
end

function SupporterHighFive:CompleteMatch(match)
	if type(match) ~= "table"
		or match.cancelled == true
		or self.matches[match.id] ~= match then
		return
	end
	match.timer = nil
	if not IsTruePlayerHero(match.heroes[1]) or not IsTruePlayerHero(match.heroes[2]) then
		self:CancelMatch(match, "cancelled", true)
		return
	end

	for _, particle in ipairs(match.travel_particles) do
		self:DestroyParticle(particle, false)
	end
	match.travel_particles = {}

	local emitted = {}
	for _, assets in ipairs(match.assets) do
		if not emitted[assets.impact_pfx] then
			emitted[assets.impact_pfx] = true
			self:CreateImpact(match.midpoint, assets.impact_pfx)
		end
	end
	for _, hero in ipairs(match.heroes) do self:SetSuccessCooldown(hero) end

	self.matches[match.id] = nil
	for index, playerID in ipairs(match.player_ids) do
		self:SendResult(playerID, "impact", {
			match_id = match.id,
			partner_player_id = match.player_ids[index == 1 and 2 or 1],
		})
	end
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
	local distance = Distance2D(firstOrigin, secondOrigin)
	if distance > self.MATCH_RADIUS then return false, "out_of_range" end

	local firstPlayerID = firstRequest.player_id
	local secondPlayerID = PlayerIDFromHero(secondHero)
	local firstAssets = firstRequest.assets
	self:RemoveRequest(firstRequest, "matched", false)

	self.nextMatchID = self.nextMatchID + 1
	local match = {
		id = self.nextMatchID,
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
		midpoint = Midpoint(firstOrigin, secondOrigin),
		travel_particles = {},
	}
	self.matches[match.id] = match

	for _, data in ipairs({
		{ firstOrigin, firstAssets.travel_pfx },
		{ secondOrigin, secondAssets.travel_pfx },
	}) do
		local particle = self:CreateTravel(data[1], match.midpoint, data[2])
		if particle ~= nil then table.insert(match.travel_particles, particle) end
	end

	local travelTime = math.max(distance * 0.5 / self.TRAVEL_SPEED, self.MIN_TRAVEL_TIME)
	for index, playerID in ipairs(match.player_ids) do
		self:SendResult(playerID, "matched", {
			match_id = match.id,
			partner_player_id = match.player_ids[index == 1 and 2 or 1],
			travel_time = travelTime,
		})
	end
	match.timer = self:Schedule(travelTime, function() self:CompleteMatch(match) end)
	return true, "matched", match
end

function SupporterHighFive:CreateRequest(hero, assets, ability)
	local playerID = PlayerIDFromHero(hero)
	local heroIndex = EntityIndex(hero)
	local request = {
		player_id = playerID,
		hero_entindex = heroIndex,
		hero = hero,
		assets = assets,
		ability = ability,
		expires_at = GameTime() + self.REQUEST_DURATION,
	}
	request.overhead = self:CreateOverhead(hero, assets.overhead_pfx)
	self.requestsByPlayer[playerID] = request
	self.requestsByHero[heroIndex] = request
	request.modifier = hero:AddNewModifier(
		hero,
		ability,
		"modifier_xhs_high_five_request",
		{ duration = self.REQUEST_DURATION }
	)
	if not IsValid(request.modifier) then
		request.timer = self:Schedule(self.REQUEST_DURATION, function()
			if self.requestsByPlayer[playerID] == request then
				request.timer = nil
				self:RemoveRequest(request, "expired", true)
			end
		end)
	end
	self:SendResult(playerID, "pending", {
		hero_entindex = heroIndex,
		duration = self.REQUEST_DURATION,
		expires_at = request.expires_at,
	})
	return true, "pending", request
end

function SupporterHighFive:Trigger(hero, ability)
	if not IsTruePlayerHero(hero) then return false, "invalid_hero" end
	ability = IsValid(ability) and ability or self:FindAbility(hero)
	if not IsValid(ability) then return false, "missing_ability" end
	local playerID = PlayerIDFromHero(hero)
	local heroIndex = EntityIndex(hero)
	local now = GameTime()
	if now - (self.lastTriggerAt[heroIndex] or -100) < self.TRIGGER_DEBOUNCE then
		return false, "rate_limited"
	end
	self.lastTriggerAt[heroIndex] = now

	local ownRequest = self.requestsByPlayer[playerID]
	if ownRequest ~= nil and ownRequest.removed ~= true then
		self:SendResult(playerID, "pending", {
			hero_entindex = heroIndex,
			duration = math.max(ownRequest.expires_at - now, 0),
			expires_at = ownRequest.expires_at,
		})
		return true, "pending", ownRequest
	end

	local assets = self:ResolveAssets(hero)
	local partner = self:FindPartner(hero)
	if partner ~= nil then return self:Match(partner, hero, assets) end
	return self:CreateRequest(hero, assets, ability)
end

function SupporterHighFive:HeroFromClientEvent(sourceIndex)
	local source = tonumber(sourceIndex)
	if source == nil or source <= 0 then return nil end
	local ok, player = pcall(EntIndexToHScript, source)
	if not ok or not IsValid(player) or player.GetPlayerID == nil then return nil end
	local playerID = tonumber(player:GetPlayerID())
	if playerID == nil or not PlayerResource:IsValidPlayerID(playerID) then return nil end
	local hero = PlayerResource:GetSelectedHeroEntity(playerID)
	return IsTruePlayerHero(hero) and hero or nil
end

function SupporterHighFive:OnClientTrigger(sourceIndex)
	local hero = self:HeroFromClientEvent(sourceIndex)
	if hero == nil then return end
	local ability = self:FindAbility(hero)
	if not IsValid(ability) then
		self:SendResult(PlayerIDFromHero(hero), "error", { reason = "missing_ability" })
		return
	end
	if ability.IsCooldownReady ~= nil and not ability:IsCooldownReady() then
		self:SendResult(PlayerIDFromHero(hero), "error", { reason = "cooldown" })
		return
	end
	ExecuteOrderFromTable({
		UnitIndex = hero:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
		AbilityIndex = ability:entindex(),
		PlayerID = PlayerIDFromHero(hero),
		Queue = false,
	})
end

function SupporterHighFive:Reset()
	local requests = {}
	for _, request in pairs(self.requestsByPlayer or {}) do table.insert(requests, request) end
	for _, request in ipairs(requests) do self:RemoveRequest(request, "cancelled", false) end

	local matches = {}
	for _, match in pairs(self.matches or {}) do table.insert(matches, match) end
	for _, match in ipairs(matches) do self:CancelMatch(match, "cancelled", false) end

	self.requestsByPlayer = {}
	self.requestsByHero = {}
	self.matches = {}
	self.lastTriggerAt = {}
end

function SupporterHighFive:Init()
	if self.initialized == true then return self end
	self.initialized = true
	self.requestsByPlayer = {}
	self.requestsByHero = {}
	self.matches = {}
	self.lastTriggerAt = {}
	self.nextMatchID = 0

	if CustomGameEventManager ~= nil then
		CustomGameEventManager:RegisterListener(self.CLIENT_EVENT, function(sourceIndex)
			self:OnClientTrigger(sourceIndex)
		end)
	end
	ListenToGameEvent("entity_killed", function(event)
		local entityIndex = tonumber(event.entindex_killed)
		if entityIndex == nil then return end
		local ok, entity = pcall(EntIndexToHScript, entityIndex)
		if ok and IsValid(entity) then self:CleanupHero(entity, "death") end
	end, nil)
	ListenToGameEvent("player_disconnect", function(event)
		self:CleanupPlayer(event.PlayerID or event.playerid, "disconnected")
	end, nil)
	ListenToGameEvent("game_rules_state_change", function()
		-- State_Get can briefly be nil while the rules object changes state. We
		-- only need the exact post-game transition, not an ordered comparison.
		if GameRules:State_Get() == DOTA_GAMERULES_STATE_POST_GAME then self:Reset() end
	end, nil)

	self:Debug("initialized")
	return self
end

-- Requiring the module is the lifecycle boundary. Previously Init existed but
-- was never called, leaving every input listener inactive.
SupporterHighFive:Init()

return SupporterHighFive
