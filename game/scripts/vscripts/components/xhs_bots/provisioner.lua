if XHSBotProvisioner == nil then
	XHSBotProvisioner = {}
end

XHSBotProvisioner.pending_slots = XHSBotProvisioner.pending_slots or {}
XHSBotProvisioner.provisioned = XHSBotProvisioner.provisioned or false
XHSBotProvisioner.requested_count = XHSBotProvisioner.requested_count or 0
XHSBotProvisioner.created_count = XHSBotProvisioner.created_count or 0
XHSBotProvisioner.request_generation = XHSBotProvisioner.request_generation or 0
XHSBotProvisioner.next_request_id = XHSBotProvisioner.next_request_id or 0
XHSBotProvisioner.provision_request_timeout = 8
XHSBotProvisioner.pending_count = 0
XHSBotProvisioner.inflight_count = 0
XHSBotProvisioner.failed_count = 0
XHSBotProvisioner.timed_out_count = 0
XHSBotProvisioner.uncorrelated_spawns = XHSBotProvisioner.uncorrelated_spawns or {}
XHSBotProvisioner.hero_assignment_started_at = nil
XHSBotProvisioner.hero_assignment_timeout = 45
XHSBotProvisioner.hero_replace_timeout = 15
XHSBotProvisioner.hero_assignment_generation = XHSBotProvisioner.hero_assignment_generation or 0

local BOT_NAMES = {
	"Bluebell",
	"Rowan",
	"Thistle",
	"Juniper",
	"Bramble",
	"Willow",
	"Clover",
	"Hawthorn",
}

local function ProvisionLogValue(value)
	local text = tostring(value == nil and "nil" or value)
	text = string.gsub(text, "[%c%s=]+", "_")
	return string.sub(text, 1, 180)
end

local function ProvisionLog(eventName, fields)
	-- Intentionally silent: provisioning state is exposed through XHSBots.
end

function XHSBotProvisioner:GetLaneNumberForSlot(slot)
	slot = math.max(1, math.floor(tonumber(slot) or 1))
	local humanCount = XHSBotPlayerRegistry ~= nil
		and XHSBotPlayerRegistry:GetHumanCount()
		or 0
	return humanCount + slot
end

function XHSBotProvisioner:GetDisplayName(slot, lane)
	slot = math.max(1, math.floor(tonumber(slot) or 1))
	lane = math.max(1, math.floor(tonumber(lane) or self:GetLaneNumberForSlot(slot)))
	local botName = BOT_NAMES[slot] or ("Bot" .. tostring(slot))
	return "[BOT] " .. botName .. "_L" .. tostring(lane)
end

local function IsValidHero(hero)
	return hero ~= nil and IsValidEntity(hero) and not hero:IsNull() and hero:IsRealHero()
end

local function CurrentTime()
	if Time ~= nil then return Time() end
	return GameRules ~= nil and GameRules:GetGameTime() or 0
end

local function IsVerifiedBotHero(hero)
	if not IsValidHero(hero) then return false, "invalid hero" end
	local playerID = hero:GetPlayerID()
	if playerID == nil or playerID < 0 or not PlayerResource:IsValidPlayerID(playerID) then
		return false, "invalid player id"
	end
	if PlayerResource:GetTeam(playerID) ~= DOTA_TEAM_GOODGUYS then
		return false, "bot is not on Radiant"
	end
	if PlayerResource.IsFakeClient == nil then
		return false, "fake-client verification API is unavailable"
	end
	local ok, isFakeClient = pcall(function() return PlayerResource:IsFakeClient(playerID) end)
	if not ok or isFakeClient ~= true then
		return false, ok and "slot is not a fake client" or "fake-client verification failed"
	end
	return true, "verified"
end

function XHSBotProvisioner:GetVerificationCounts()
	local registered = 0
	local verified = 0
	for _, playerID in ipairs(XHSBotPlayerRegistry:GetXHSBotPlayerIDs()) do
		registered = registered + 1
		local hero = XHSBotPlayerRegistry:GetBotHero(playerID)
		local ok, reason = IsVerifiedBotHero(hero)
		local record = XHSBotPlayerRegistry:GetBot(playerID)
		if record ~= nil then
			record.engine_fake_client = XHSBotPlayerRegistry:IsEngineBotPlayerID(playerID)
			record.engine_team_verified = PlayerResource:IsValidPlayerID(playerID)
				and PlayerResource:GetTeam(playerID) == DOTA_TEAM_GOODGUYS
			record.provisioning_verification = reason
		end
		if ok then verified = verified + 1 end
	end
	return registered, verified
end

function XHSBotProvisioner:IsAvailable()
	return XHSBots ~= nil
		and XHSBots.enabled == true
		and XHSBots.setup_approved == true
		and GameRules ~= nil
		and GameRules.AddBotPlayerWithEntityScript ~= nil
end

function XHSBotProvisioner:BuildMetadata(slot, configuration)
	self.next_request_id = self.next_request_id + 1
	local lane = self:GetLaneNumberForSlot(slot)
	local displayName = self:GetDisplayName(slot, lane)
	local requestToken = "g" .. tostring(self.request_generation)
		.. "_s" .. tostring(slot)
		.. "_r" .. tostring(self.next_request_id)
	return {
		slot = slot,
		lane = lane,
		name = displayName,
		request_name = displayName,
		request_token = requestToken,
		request_state = "created",
		request_attempted = false,
		difficulty = configuration.difficulty,
		composition = configuration.composition,
		provisioning = "AddBotPlayerWithEntityScript",
	}
end

function XHSBotProvisioner:GetProvisioningCounts(requested)
	requested = math.max(0, math.floor(tonumber(requested) or self.requested_count or 0))
	local registered, verified = self:GetVerificationCounts()
	local counts = {
		requested = requested,
		registered = registered,
		verified = verified,
		pending = math.max(0, requested - registered),
		inflight = 0,
		timed_out = 0,
		failed = 0,
		unrequested = 0,
		uncorrelated = 0,
	}
	local now = CurrentTime()

	for slot = 1, requested do
		local metadata = self.pending_slots[slot]
		if metadata == nil then
			counts.unrequested = counts.unrequested + 1
		elseif metadata.registered ~= true then
			if metadata.request_state == "inflight"
				and now - (metadata.requested_at or now) >= self.provision_request_timeout then
				metadata.request_state = "timed_out"
				metadata.timed_out_at = now
				metadata.error = "spawn callback timed out; request will not be reissued"
			end

			if metadata.request_state == "inflight" then
				counts.inflight = counts.inflight + 1
			elseif metadata.request_state == "timed_out" then
				counts.timed_out = counts.timed_out + 1
			elseif metadata.request_state == "failed" then
				counts.failed = counts.failed + 1
			end
		end
	end

	for _ in pairs(self.uncorrelated_spawns) do
		counts.uncorrelated = counts.uncorrelated + 1
	end

	self.created_count = registered
	self.pending_count = counts.pending
	self.inflight_count = counts.inflight
	self.failed_count = counts.failed
	self.timed_out_count = counts.timed_out
	return counts
end

function XHSBotProvisioner:FormatProvisioningStatus(counts, detail)
	counts = counts or self:GetProvisioningCounts(self.requested_count)
	local suffix = detail ~= nil and detail ~= "" and ("; " .. tostring(detail)) or ""
	return "registered=" .. tostring(counts.registered) .. "/" .. tostring(counts.requested)
		.. " verified=" .. tostring(counts.verified)
		.. " pending=" .. tostring(counts.pending)
		.. " inflight=" .. tostring(counts.inflight)
		.. " timed_out=" .. tostring(counts.timed_out)
		.. " failed=" .. tostring(counts.failed)
		.. " unrequested=" .. tostring(counts.unrequested)
		.. " uncorrelated=" .. tostring(counts.uncorrelated)
		.. suffix
end

function XHSBotProvisioner:RegisterPendingHero(metadata, hero)
	ProvisionLog("register_pending_started", {
		hero_entindex = IsValidHero(hero) and hero:entindex() or -1,
		request_state = metadata and metadata.request_state,
		slot = metadata and metadata.slot,
		token = metadata and metadata.request_token,
	})
	if metadata == nil or metadata.registered == true or not IsValidHero(hero) then
		ProvisionLog("register_pending_rejected", {
			reason = "invalid_pending_hero",
			slot = metadata and metadata.slot,
		})
		return false, "invalid pending hero"
	end

	metadata.hero_entindex = hero:entindex()
	local verified, reason = IsVerifiedBotHero(hero)
	if not verified then
		metadata.error = "spawn not verified yet: " .. tostring(reason)
		ProvisionLog("register_pending_rejected", {
			reason = metadata.error,
			slot = metadata.slot,
			token = metadata.request_token,
		})
		return false, metadata.error
	end

	local playerID = hero:GetPlayerID()
	local existing = XHSBotPlayerRegistry:GetBot(playerID)
	if existing ~= nil and tonumber(existing.slot) ~= tonumber(metadata.slot) then
		metadata.request_state = "failed"
		metadata.error = "player id already belongs to another bot slot"
		return false, metadata.error
	end

	local record = XHSBotPlayerRegistry:RegisterBot(playerID, hero, metadata)
	if record == nil then
		metadata.request_state = "failed"
		metadata.error = "registry rejected spawned bot"
		return false, metadata.error
	end

	record.provision_request_token = metadata.request_token
	record.provision_request_name = metadata.request_name
	metadata.registered = true
	metadata.registered_at = CurrentTime()
	metadata.registered_player_id = playerID
	metadata.request_state = "registered"
	metadata.error = nil
	self.uncorrelated_spawns[playerID] = nil
	ProvisionLog("register_pending_completed", {
		hero_entindex = hero:entindex(),
		player_id = playerID,
		slot = metadata.slot,
		token = metadata.request_token,
	})
	return true, "registered"
end

function XHSBotProvisioner:Provision(configuration)
	ProvisionLog("provision_entered", {
		already_provisioned = self.provisioned,
		game_state = GameRules and GameRules:State_Get() or -1,
		requested = configuration and configuration.count,
	})
	if self.provisioned then
		return #XHSBotPlayerRegistry:GetXHSBotPlayerIDs(), "already provisioned"
	end
	if not self:IsAvailable() then
		return 0, "GameRules:AddBotPlayerWithEntityScript is unavailable"
	end

	configuration = configuration or {}
	local requested = math.max(0, math.min(
		XHSBotConfig.MAX_BOTS,
		math.floor(tonumber(configuration.count) or 0)
	))
	local previousRequested = self.requested_count
	if previousRequested ~= requested then
		if next(self.pending_slots) ~= nil then
			local counts = self:GetProvisioningCounts(previousRequested)
			return counts.verified, self:FormatProvisioningStatus(
				counts,
				"configuration change rejected while bot requests exist"
			)
		end
		self.request_generation = self.request_generation + 1
		self.pending_slots = {}
	end
	self.requested_count = requested

	-- Reconcile entity handles returned before their player slot became verifiable.
	for _, metadata in pairs(self.pending_slots) do
		if metadata.registered ~= true and metadata.hero_entindex ~= nil then
			local ok, hero = pcall(EntIndexToHScript, metadata.hero_entindex)
			if ok and IsValidHero(hero) then
				self:RegisterPendingHero(metadata, hero)
			end
		end
	end

	local occupiedSlots = {}
	for _, playerID in ipairs(XHSBotPlayerRegistry:GetXHSBotPlayerIDs()) do
		local record = XHSBotPlayerRegistry:GetBot(playerID)
		if record ~= nil and record.slot ~= nil then
			local slot = tonumber(record.slot)
			occupiedSlots[slot] = true
			local metadata = self.pending_slots[slot]
			if metadata ~= nil then
				metadata.registered = true
				metadata.registered_player_id = playerID
				metadata.request_state = "registered"
			end
		end
	end

	local counts = self:GetProvisioningCounts(requested)
	ProvisionLog("provision_counts_before", {
		failed = counts.failed,
		inflight = counts.inflight,
		pending = counts.pending,
		registered = counts.registered,
		requested = counts.requested,
		timed_out = counts.timed_out,
		verified = counts.verified,
	})
	if counts.registered > requested then
		return counts.verified, self:FormatProvisioningStatus(counts, "over-provisioned")
	end
	if counts.uncorrelated > 0 then
		return counts.verified, self:FormatProvisioningStatus(
			counts,
			"uncorrelated XHS bot spawn detected; refusing further requests"
		)
	end
	if counts.timed_out > 0 or counts.failed > 0 then
		return counts.verified, self:FormatProvisioningStatus(
			counts,
			"request failed or timed out; slot will not be reissued"
		)
	end
	if counts.inflight > 0 then
		return counts.verified, self:FormatProvisioningStatus(
			counts,
			"waiting for correlated entity-script spawn"
		)
	end

	for slot = 1, requested do
		if occupiedSlots[slot] ~= true and self.pending_slots[slot] == nil then
			local metadata = self:BuildMetadata(slot, configuration)
			metadata.request_attempted = true
			metadata.request_state = "inflight"
			metadata.requested_at = CurrentTime()
			self.pending_slots[slot] = metadata
			ProvisionLog("native_request_starting", {
				game_state = GameRules:State_Get(),
				name = metadata.request_name,
				slot = slot,
				token = metadata.request_token,
			})

			local ok, heroOrError = pcall(function()
				return GameRules:AddBotPlayerWithEntityScript(
					"npc_dota_hero_wisp",
					metadata.request_name,
					DOTA_TEAM_GOODGUYS,
					"components/xhs_bots/entity_script.lua",
					true
				)
			end)
			ProvisionLog("native_request_returned", {
				ok = ok,
				result_is_valid_hero = ok and IsValidHero(heroOrError),
				slot = slot,
				token = metadata.request_token,
			})

			if not ok then
				metadata.request_state = "failed"
				metadata.error = tostring(heroOrError)
				ProvisionLog("native_request_failed", {
					error = metadata.error,
					slot = slot,
					token = metadata.request_token,
				})
				break
			end

			if metadata.registered ~= true and IsValidHero(heroOrError) then
				metadata.hero_entindex = heroOrError:entindex()
				self:RegisterPendingHero(metadata, heroOrError)
			end
			if metadata.registered ~= true then
				metadata.error = metadata.error or "waiting for correlated entity-script spawn"
				break
			end

			occupiedSlots[slot] = true
			-- One fake client per timer pass avoids a burst of native player
			-- creation and gives Source 2 time to network each slot safely.
			break
		end
	end

	counts = self:GetProvisioningCounts(requested)
	self.provisioned = counts.registered == requested
		and counts.verified == requested
		and counts.inflight == 0
		and counts.timed_out == 0
		and counts.failed == 0
		and counts.uncorrelated == 0
	if self.provisioned then
		self.hero_assignment_started_at = nil
		ProvisionLog("provision_completed", {
			registered = counts.registered,
			requested = requested,
			verified = counts.verified,
		})
		return counts.verified, self:FormatProvisioningStatus(counts, "ok")
	end
	ProvisionLog("provision_incomplete", {
		detail = self:FormatProvisioningStatus(counts, "provisioning incomplete"),
	})
	return counts.verified, self:FormatProvisioningStatus(counts, "provisioning incomplete")
end

function XHSBotProvisioner:OnEntityScriptSpawn(hero)
	ProvisionLog("entity_script_spawned", {
		game_state = GameRules and GameRules:State_Get() or -1,
		hero_entindex = IsValidHero(hero) and hero:entindex() or -1,
		player_id = IsValidHero(hero) and hero:GetPlayerID() or -1,
	})
	if XHSBots == nil or XHSBots.enabled ~= true
		or XHSBots.setup_approved ~= true
		or not IsValidHero(hero) then return end
	local playerID = hero:GetPlayerID()
	if playerID == nil or playerID < 0 then return end

	local existing = XHSBotPlayerRegistry:GetBot(playerID)
	if existing ~= nil then
		XHSBotPlayerRegistry:BindHero(playerID, hero)
		return
	end

	local engineName = ""
	if PlayerResource.GetPlayerName ~= nil then
		engineName = tostring(PlayerResource:GetPlayerName(playerID) or "")
	end

	local matched = nil
	local soleOutstanding = nil
	local outstandingCount = 0
	for _, metadata in pairs(self.pending_slots) do
		local outstanding = metadata.registered ~= true
			and (metadata.request_state == "inflight" or metadata.request_state == "timed_out")
		if outstanding then
			outstandingCount = outstandingCount + 1
			soleOutstanding = metadata
			if metadata.hero_entindex == hero:entindex()
				or engineName ~= "" and engineName == metadata.request_name then
				matched = metadata
				break
			end
		end
	end

	-- Sequential requests guarantee this fallback is unambiguous even when an
	-- engine build does not preserve the requested player name.
	if matched == nil and outstandingCount == 1 then
		matched = soleOutstanding
	end

	if matched == nil then
		self.uncorrelated_spawns[playerID] = {
			player_id = playerID,
			hero_entindex = hero:entindex(),
			engine_name = engineName,
			detected_at = CurrentTime(),
		}
		return
	end

	local registered, reason = self:RegisterPendingHero(matched, hero)
	ProvisionLog("entity_script_correlated", {
		player_id = playerID,
		reason = reason,
		registered = registered,
		slot = matched.slot,
		token = matched.request_token,
	})
end

function XHSBotProvisioner:GetUnavailableHumanHeroes()
	local unavailable = {}
	for _, playerID in ipairs(XHSBotPlayerRegistry:GetHumanPlayerIDs()) do
		local player = PlayerResource:GetPlayer(playerID)
		local hero = player ~= nil and player:GetAssignedHero() or nil
		if not IsValidHero(hero) then
			hero = PlayerResource:GetSelectedHeroEntity(playerID)
		end
		if IsValidHero(hero) and hero:GetUnitName() ~= "npc_dota_hero_wisp" then
			unavailable[hero:GetUnitName()] = true
		end
	end
	for _, playerID in ipairs(XHSBotPlayerRegistry:GetXHSBotPlayerIDs()) do
		local record = XHSBotPlayerRegistry:GetBot(playerID)
		local heroName = record ~= nil and record.requested_hero or nil
		if heroName == nil then
			local hero = XHSBotPlayerRegistry:GetBotHero(playerID)
			heroName = IsValidHero(hero) and hero:GetUnitName() or nil
		end
		if heroName ~= nil and heroName ~= "npc_dota_hero_wisp" then
			unavailable[heroName] = true
		end
	end
	return unavailable
end

function XHSBotProvisioner:AreHumanHeroesSelected()
	local humans = XHSBotPlayerRegistry:GetHumanPlayerIDs()
	if #humans == 0 then return true end

	for _, playerID in ipairs(humans) do
		local player = PlayerResource:GetPlayer(playerID)
		local hero = player ~= nil and player:GetAssignedHero() or nil
		if not IsValidHero(hero) then
			hero = PlayerResource:GetSelectedHeroEntity(playerID)
		end
		if not IsValidHero(hero) or hero:GetUnitName() == "npc_dota_hero_wisp" then
			return false
		end
	end
	return true
end

function XHSBotProvisioner:RemoveSelectionTrigger(heroName)
	if type(HEROLIST) ~= "table" then return end
	local shortName = string.gsub(heroName or "", "^npc_dota_hero_", "")
	for index, candidate in ipairs(HEROLIST) do
		if candidate == shortName then
			local trigger = Entities:FindByName(nil, "trigger_hero_" .. tostring(index))
			if trigger ~= nil then
				UTIL_Remove(trigger)
			end
			return
		end
	end
end

function XHSBotProvisioner:CompleteHeroAssignment(
	playerID,
	heroName,
	removeSelectionTrigger,
	assignmentGeneration,
	origin,
	newHero
)
	ProvisionLog("hero_assignment_callback", {
		generation = assignmentGeneration,
		hero = IsValidHero(newHero) and newHero:GetUnitName() or "invalid",
		player_id = playerID,
	})
	local current = XHSBotPlayerRegistry:GetBot(playerID)
	if current == nil or current.hero_assignment_generation ~= assignmentGeneration then
		return
	end

	current.hero_assignment_pending = false
	current.hero_assignment_timed_out = false
	if not IsValidHero(newHero)
		or newHero:GetPlayerID() ~= playerID
		or newHero:GetUnitName() ~= heroName then
		current.hero_assignment_failed = true
		current.error = "ReplaceHeroWith returned no matching hero"
		return
	end

	current.hero_assignment_failed = false
	current.hero_assigned = true
	current.hero_name = heroName
	XHSBotPlayerRegistry:BindHero(playerID, newHero)
	local spawnPosition = XHSSetPlayerBaseRespawnPosition ~= nil
		and XHSSetPlayerBaseRespawnPosition(newHero)
		or origin
	FindClearSpaceForUnit(newHero, spawnPosition, true)
	newHero:SetRespawnPosition(newHero:GetAbsOrigin())
	newHero.xhs_base_respawn_position = newHero:GetAbsOrigin()
	if removeSelectionTrigger then
		self:RemoveSelectionTrigger(heroName)
	end
	if XHSBots ~= nil and XHSBots.OnBotHeroReady ~= nil then
		XHSBots:OnBotHeroReady(playerID, newHero)
	end
	local counts = self:GetHeroAssignmentCounts()
	if counts.total > 0 and counts.assigned == counts.total
		and XHSBotOnlyAutonomyAllowed ~= nil
		and XHSBotOnlyAutonomyAllowed()
		and XHSCleanupHeroSelectionShowcase ~= nil then
		local cleanupOK, removed, cleanupReason = pcall(
			XHSCleanupHeroSelectionShowcase,
			"all_bot_heroes_assigned"
		)
		ProvisionLog("selection_showcase_cleanup", {
			ok = cleanupOK,
			removed = removed,
			reason = cleanupReason,
		})
	end
end

function XHSBotProvisioner:AssignHero(playerID, heroName, removeSelectionTrigger)
	ProvisionLog("hero_assignment_requested", {
		hero = heroName,
		player_id = playerID,
		remove_trigger = removeSelectionTrigger,
	})
	local record = XHSBotPlayerRegistry:GetBot(playerID)
	if record == nil then return false, "unknown bot" end
	if record.hero_assigned == true then return true, "already assigned" end
	if record.hero_assignment_pending == true then return false, "replacement already in flight" end
	if record.hero_assignment_failed == true then return false, tostring(record.error) end

	local oldHero = XHSBotPlayerRegistry:GetBotHero(playerID)
	if not IsValidHero(oldHero) then return false, "waiting for current hero" end

	if oldHero:GetUnitName() == heroName then
		record.hero_assigned = true
		record.requested_hero = heroName
		return true, "already using requested hero"
	end

	local origin = oldHero:GetAbsOrigin()
	local difficulty = GameRules:GetCustomGameDifficulty()
	local startingGold = XHS_STARTING_GOLD and XHS_STARTING_GOLD[difficulty] or 0
	self.hero_assignment_generation = self.hero_assignment_generation + 1
	local assignmentGeneration = self.hero_assignment_generation
	record.requested_hero = heroName
	record.hero_assignment_pending = true
	record.hero_assignment_failed = false
	record.hero_assignment_timed_out = false
	record.hero_assignment_generation = assignmentGeneration
	record.hero_assignment_started_at = CurrentTime()
	record.hero_assignment_deadline = record.hero_assignment_started_at + self.hero_replace_timeout
	record.error = nil

	local ok, replaceError = pcall(function()
		XHSPrecache:ReplaceHeroWith(playerID, heroName, startingGold, 0, oldHero, {
			startingItems = true,
		}, function(newHero)
			local callback = function()
				return XHSBotProvisioner:CompleteHeroAssignment(
					playerID,
					heroName,
					removeSelectionTrigger,
					assignmentGeneration,
					origin,
					newHero
				)
			end
			local current = XHSBotPlayerRegistry:GetBot(playerID)
			local callbackOK = false
			local callbackResult = nil
			local callbackError = nil
			if XHSBots ~= nil and XHSBots.RunSafely ~= nil then
				callbackOK, callbackResult, callbackError = XHSBots:RunSafely(
					"hero_assignment_callback:" .. tostring(playerID),
					callback,
					current,
					nil
				)
			else
				callbackOK, callbackError = pcall(callback)
			end
			if not callbackOK and current ~= nil
				and current.hero_assignment_generation == assignmentGeneration then
				current.hero_assignment_pending = false
				current.hero_assignment_failed = true
				current.error = "Hero assignment callback failed safely: "
					.. tostring(callbackError or "unknown error")
			end
		end)
	end)

	if not ok then
		record.hero_assignment_pending = false
		record.hero_assignment_failed = true
		record.error = "ReplaceHeroWith failed: " .. tostring(replaceError)
		ProvisionLog("hero_assignment_failed", {
			error = record.error,
			player_id = playerID,
		})
		return false, record.error
	end

	ProvisionLog("hero_assignment_started", {
		generation = assignmentGeneration,
		hero = heroName,
		player_id = playerID,
	})
	return true, "replacement started"
end

function XHSBotProvisioner:GetHeroAssignmentCounts()
	local counts = {
		total = 0,
		assigned = 0,
		pending = 0,
		inflight = 0,
		timed_out = 0,
		failed = 0,
		unstarted = 0,
	}
	local now = CurrentTime()

	for _, playerID in ipairs(XHSBotPlayerRegistry:GetXHSBotPlayerIDs()) do
		local record = XHSBotPlayerRegistry:GetBot(playerID)
		if record ~= nil then
			counts.total = counts.total + 1
			if record.hero_assigned == true then
				counts.assigned = counts.assigned + 1
			elseif record.hero_assignment_pending == true then
				if record.hero_assignment_timed_out ~= true
					and now >= (record.hero_assignment_deadline or math.huge) then
					record.hero_assignment_timed_out = true
					record.error = "hero replacement callback timed out; replacement will not be reissued"
				end
				counts.pending = counts.pending + 1
				if record.hero_assignment_timed_out == true then
					counts.timed_out = counts.timed_out + 1
				else
					counts.inflight = counts.inflight + 1
				end
			elseif record.hero_assignment_failed == true then
				counts.failed = counts.failed + 1
			else
				counts.unstarted = counts.unstarted + 1
			end
		end
	end

	self.hero_assignment_pending_count = counts.pending
	self.hero_assignment_inflight_count = counts.inflight
	self.hero_assignment_timed_out_count = counts.timed_out
	self.hero_assignment_failed_count = counts.failed
	return counts
end

function XHSBotProvisioner:FormatHeroAssignmentStatus(counts, detail)
	counts = counts or self:GetHeroAssignmentCounts()
	local suffix = detail ~= nil and detail ~= "" and ("; " .. tostring(detail)) or ""
	return "assigned=" .. tostring(counts.assigned) .. "/" .. tostring(counts.total)
		.. " pending=" .. tostring(counts.pending)
		.. " inflight=" .. tostring(counts.inflight)
		.. " timed_out=" .. tostring(counts.timed_out)
		.. " failed=" .. tostring(counts.failed)
		.. " unstarted=" .. tostring(counts.unstarted)
		.. suffix
end

function XHSBotProvisioner:TryAssignHeroes(configuration)
	if not self.provisioned then return false, "not provisioned" end
	if GameRules:State_Get() < DOTA_GAMERULES_STATE_PRE_GAME then
		return false, "waiting for pre-game"
	end

	if self.hero_assignment_started_at == nil then
		self.hero_assignment_started_at = CurrentTime()
	end

	local humansSelected = self:AreHumanHeroesSelected()
	local timedOut = CurrentTime() - self.hero_assignment_started_at >= self.hero_assignment_timeout
	if not humansSelected and not timedOut then
		return false, "waiting for human hero choices"
	end

	local counts = self:GetHeroAssignmentCounts()
	if counts.timed_out > 0 then
		return false, self:FormatHeroAssignmentStatus(
			counts,
			"callback timed out; replacement remains quarantined"
		)
	end
	if counts.failed > 0 then
		return false, self:FormatHeroAssignmentStatus(counts, "replacement failed")
	end
	if counts.inflight > 0 then
		return false, self:FormatHeroAssignmentStatus(counts, "waiting for callbacks")
	end
	if counts.assigned == counts.total then
		return true, self:FormatHeroAssignmentStatus(counts, "all assigned")
	end

	local assignable = {}
	for _, playerID in ipairs(XHSBotPlayerRegistry:GetXHSBotPlayerIDs()) do
		local record = XHSBotPlayerRegistry:GetBot(playerID)
		if record ~= nil and record.hero_assigned ~= true and record.hero_assignment_pending ~= true then
			table.insert(assignable, playerID)
		end
	end
	if #assignable == 0 then
		return false, self:FormatHeroAssignmentStatus(counts, "no assignable bot")
	end

	local unavailable = self:GetUnavailableHumanHeroes()
	local heroes = XHSBotHeroProfiles:PickHeroes(#assignable, configuration.composition, unavailable)
	local started = 0
	for index, playerID in ipairs(assignable) do
		local heroName = heroes[index]
		if heroName ~= nil then
			local assignmentStarted = self:AssignHero(playerID, heroName, humansSelected)
			if assignmentStarted then started = started + 1 end
		end
	end

	counts = self:GetHeroAssignmentCounts()
	if counts.failed > 0 then
		return false, self:FormatHeroAssignmentStatus(counts, "replacement failed to start")
	end
	return false, self:FormatHeroAssignmentStatus(
		counts,
		"started=" .. tostring(started)
			.. (timedOut and " after human-selection timeout" or " after humans")
	)
end

function XHSBotProvisioner:Reset()
	local counts = self:GetProvisioningCounts(self.requested_count)
	if counts.registered > 0 or counts.pending > 0 or counts.uncorrelated > 0 then
		return false, self:FormatProvisioningStatus(
			counts,
			"reset refused while engine slots or requests exist"
		)
	end

	self.pending_slots = {}
	self.provisioned = false
	self.requested_count = 0
	self.created_count = 0
	self.pending_count = 0
	self.inflight_count = 0
	self.failed_count = 0
	self.timed_out_count = 0
	self.uncorrelated_spawns = {}
	self.request_generation = self.request_generation + 1
	self.hero_assignment_started_at = nil
	return true, "reset"
end

return XHSBotProvisioner
