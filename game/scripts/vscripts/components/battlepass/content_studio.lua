local ContentStudio = {
	candidates = {},
	verified = {},
	previewGeneration = {},
	syncGeneration = {},
	runtimeStates = {},
}

local SYNC_CHUNK_SIZE = 6
local SLOT_BY_CATEGORY = {
	teleport = "teleport",
	ascension = "levelup",
	kill_fx = "kill_effect",
	emblem = "emblem",
	potion = "potion",
	rebirth = "rebirth",
	attack_lifesteal = "attack_lifesteal",
	spell_lifesteal = "spell_lifesteal",
	regen_aura = "regen_aura",
	immolation = "immolation",
	high_five = "high_five",
}

local function ResolvePlayerID(sourceIndex)
	local numericSourceIndex = tonumber(sourceIndex)
	local playerID = nil
	if CustomGameEventManager ~= nil and CustomGameEventManager.GetPlayerIDFromEventSourceIndex ~= nil then
		local ok, resolvedPlayerID = pcall(function()
			return CustomGameEventManager:GetPlayerIDFromEventSourceIndex(sourceIndex)
		end)
		if ok then playerID = tonumber(resolvedPlayerID) end
	end
	if (playerID == nil or playerID < 0) and numericSourceIndex ~= nil and numericSourceIndex > 0 then
		local ok, resolvedPlayerID = pcall(function()
			local sender = EntIndexToHScript(numericSourceIndex)
			return sender ~= nil and sender.GetPlayerID ~= nil and sender:GetPlayerID() or nil
		end)
		if ok then playerID = tonumber(resolvedPlayerID) end
	end
	if playerID == nil or playerID < 0 or not PlayerResource:IsValidPlayerID(playerID) then return nil end
	return playerID
end

local function IsStudioAvailable()
	return IsInToolsMode ~= nil and IsInToolsMode() and string.lower(GetMapName() or "") == "x_hero_siege_demo"
end

local function Send(playerID, eventName, payload)
	local player = PlayerResource:GetPlayer(playerID)
	if player ~= nil then CustomGameEventManager:Send_ServerToPlayer(player, eventName, payload or {}) end
end

local function SendCandidateChunks(playerID, requestID, candidates, categories, rarityPrices)
	local totalChunks = math.max(1, math.ceil(#candidates / SYNC_CHUNK_SIZE))
	for chunkIndex = 1, totalChunks do
		local first = ((chunkIndex - 1) * SYNC_CHUNK_SIZE) + 1
		local last = math.min(#candidates, first + SYNC_CHUNK_SIZE - 1)
		local chunk = {}
		for index = first, last do table.insert(chunk, candidates[index]) end
		Send(playerID, "supporter_content_studio_state", {
			ok = true,
			request_id = requestID,
			chunk_index = chunkIndex,
			total_chunks = totalChunks,
			candidates = chunk,
			categories = chunkIndex == 1 and (categories or {}) or {},
			rarity_prices = chunkIndex == 1 and (rarityPrices or {}) or {},
			scene_panel = chunkIndex == 1 and {
				raw_vpcf_supported = false,
				fallback = "world_preview",
				reason = "DOTAScenePanel requires an authored VMap scene; raw VPCF paths cannot be injected safely."
			} or {},
		})
	end
end

local function NormalizeList(value)
	if type(value) ~= "table" then return {} end
	local result = {}
	for _, item in pairs(value) do
		if type(item) == "table" and item.candidate_id ~= nil then table.insert(result, item) end
	end
	table.sort(result, function(a, b) return tostring(a.candidate_id) < tostring(b.candidate_id) end)
	return result
end

local function PersistentSteamID(playerID)
	if api == nil or api.GetPersistentPlayerSteamID == nil then return nil end
	return api:GetPersistentPlayerSteamID(playerID)
end

function ContentStudio:StopPreview(playerID)
	self.previewGeneration[playerID] = (self.previewGeneration[playerID] or 0) + 1
	local state = self.runtimeStates[playerID]
	self.runtimeStates[playerID] = nil
	if state ~= nil then state.on_visible = nil end
	if state ~= nil and Battlepass ~= nil and Battlepass.SUPPORTER_DEV_TESTS ~= nil
		and Battlepass.SUPPORTER_DEV_TESTS[playerID] == state
		and Battlepass.CleanupSupporterDevTest ~= nil then
		pcall(function() Battlepass:CleanupSupporterDevTest(playerID, true) end)
	end
end

local function IsParticlePath(value)
	return type(value) == "string"
		and string.match(string.lower(value), "^particles/.+%.vpcf$") ~= nil
end

local function CandidateAssetSignature(candidate)
	local metadata = type(candidate) == "table" and candidate.metadata or nil
	local signature = type(metadata) == "table"
		and string.lower(tostring(metadata.asset_signature or "")) or ""
	if #signature ~= 64 or string.match(signature, "^[a-f0-9]+$") == nil then return "" end
	return signature
end

local function BuildRuntimeItem(candidate)
	local slot = SLOT_BY_CATEGORY[tostring(candidate.category or "")]
	local assetPath = tostring(candidate.asset_path or "")
	if slot == nil or not IsParticlePath(assetPath) then return nil, nil, nil, "Unsupported runtime slot or VPCF." end
	local metadata = type(candidate.metadata) == "table" and candidate.metadata or {}
	local effectPaths = type(metadata.effect_paths) == "table" and metadata.effect_paths or {}
	local item = {
		id = "content_studio:" .. tostring(candidate.candidate_id or ""),
		item_id = "content_studio:" .. tostring(candidate.candidate_id or ""),
		name = tostring(candidate.display_name or candidate.candidate_id or "Content Studio candidate"),
		type = slot,
		item_type = slot,
		slot_id = slot,
	}
	local previewChannel = nil
	if slot == "teleport" then
		item.start_pfx = tostring(effectPaths.start or assetPath)
		item.end_pfx = tostring(effectPaths["end"] or "")
		if not IsParticlePath(item.start_pfx) or not IsParticlePath(item.end_pfx) then
			return nil, nil, nil, "Teleport candidates require compatible start and end VPCFs."
		end
	elseif slot == "kill_effect" then
		item.target_pfx = assetPath
		if IsParticlePath(effectPaths.caster) then item.caster_pfx = effectPaths.caster end
	elseif slot == "emblem" then
		item.pfx = assetPath
		item.particle = assetPath
	elseif slot == "potion" then
		previewChannel = tostring(metadata.potion_channel or "")
		if previewChannel ~= "health" and previewChannel ~= "mana" and previewChannel ~= "light" then
			return nil, nil, nil, "Potion candidates require an explicit compatible channel."
		end
		item[previewChannel .. "_pfx"] = assetPath
	elseif slot == "immolation" then
		item.owner_pfx = tostring(effectPaths.owner or assetPath)
		item.target_pfx = tostring(effectPaths.target or "")
		if not IsParticlePath(item.owner_pfx) or not IsParticlePath(item.target_pfx) then
			return nil, nil, nil, "Immolation candidates require compatible owner and target VPCFs."
		end
	elseif slot == "high_five" then
		item.overhead_pfx = tostring(effectPaths.overhead or assetPath)
		item.travel_pfx = tostring(effectPaths.travel or "")
		item.impact_pfx = tostring(effectPaths.impact or "")
		if not IsParticlePath(item.overhead_pfx) or not IsParticlePath(item.travel_pfx)
			or not IsParticlePath(item.impact_pfx) then
			return nil, nil, nil, "High Five candidates require coherent overhead, travel, and impact VPCFs."
		end
	else
		item.pfx = assetPath
	end
	return slot, item, previewChannel, nil
end

function ContentStudio:Sync(sourceIndex, event)
	local playerID = ResolvePlayerID(sourceIndex)
	if playerID == nil then return end
	local requestID = tostring(type(event) == "table" and event.request_id or "")
	self.syncGeneration[playerID] = (self.syncGeneration[playerID] or 0) + 1
	local syncGeneration = self.syncGeneration[playerID]
	if not IsStudioAvailable() then
		return Send(playerID, "supporter_content_studio_state", { ok = false, unavailable = true, request_id = requestID, message = "Content Studio is available in Tools Mode on the demo map only." })
	end
	local steamid = PersistentSteamID(playerID)
	if steamid == nil or api == nil or api.Request == nil then
		return Send(playerID, "supporter_content_studio_state", { ok = false, request_id = requestID, message = "Persistent Content Studio API is unavailable." })
	end
	api:Request("supporter-pass/content-studio/sync", function(response)
		if self.syncGeneration[playerID] ~= syncGeneration then return end
		local candidates = NormalizeList(response and response.candidates)
		self.candidates[playerID] = {}
		local previousVerified = self.verified[playerID] or {}
		self.verified[playerID] = {}
		for _, candidate in ipairs(candidates) do
			local id = tostring(candidate.candidate_id)
			local signature = CandidateAssetSignature(candidate)
			self.candidates[playerID][id] = candidate
			if signature ~= "" and (previousVerified[id] == signature
				or candidate.sent == true or candidate.sent == 1 or candidate.sent == "1") then
				self.verified[playerID][id] = signature
			end
		end
		SendCandidateChunks(
			playerID,
			requestID,
			candidates,
			response and response.categories or {},
			response and response.rarity_prices or {}
		)
	end, function(error)
		if self.syncGeneration[playerID] ~= syncGeneration then return end
		Send(playerID, "supporter_content_studio_state", { ok = false, request_id = requestID, message = error and error.message or "Content Studio sync failed." })
	end, "POST", { steamid = steamid, filters = {} })
end

function ContentStudio:Preview(sourceIndex, event)
	local playerID = ResolvePlayerID(sourceIndex)
	if playerID == nil or not IsStudioAvailable() then return end
	local candidateID = tostring(event and event.candidate_id or "")
	local operationID = tostring(event and event.operation_id or "")
	local candidate = self.candidates[playerID] and self.candidates[playerID][candidateID] or nil
	local hero = PlayerResource:GetSelectedHeroEntity(playerID)
	if candidate == nil or hero == nil or hero:IsNull() then
		return Send(playerID, "supporter_content_studio_preview_result", { ok = false, candidate_id = candidateID, operation_id = operationID, message = "Candidate or preview hero unavailable." })
	end
	local assetSignature = CandidateAssetSignature(candidate)
	if assetSignature == "" then
		return Send(playerID, "supporter_content_studio_preview_result", { ok = false, candidate_id = candidateID, operation_id = operationID, message = "Candidate asset signature is missing or invalid. Refresh the catalog before testing." })
	end
	self:StopPreview(playerID)
	local generation = self.previewGeneration[playerID]
	local slot, item, previewChannel, buildError = BuildRuntimeItem(candidate)
	if slot == "high_five" and SupporterHighFive == nil then
		pcall(function() require("components/battlepass/high_five") end)
	end
	if slot == nil or Battlepass == nil or Battlepass.ApplySupporterDevTestItem == nil
		or Battlepass.CleanupSupporterDevTest == nil then
		return Send(playerID, "supporter_content_studio_preview_result", {
			ok = false,
			candidate_id = candidateID,
			operation_id = operationID,
			message = buildError or "The live Supporter Pass playback adapter is unavailable."
		})
	end
	local metadata = type(candidate.metadata) == "table" and candidate.metadata or {}
	Battlepass.SUPPORTER_DEV_TESTS = Battlepass.SUPPORTER_DEV_TESTS or {}
	if Battlepass.SUPPORTER_DEV_TESTS[playerID] ~= nil then
		pcall(function() Battlepass:CleanupSupporterDevTest(playerID, true) end)
	end
	Battlepass.Player = Battlepass.Player or {}
	Battlepass.Player[playerID] = Battlepass.Player[playerID] or {}
	Battlepass.Player[playerID].ready = true
	local state = {
		item = item,
		item_id = item.item_id,
		slot = slot,
		preview_channel = previewChannel,
		request_id = operationID,
		candidate_id = candidateID,
		asset_signature = assetSignature,
		operation_id = operationID,
		persistent = false,
		transient = true,
		trusted_devtools = true,
		content_studio = true,
		particles = {},
	}
	local requiresVisibleCallback = slot == "kill_effect" or slot == "attack_lifesteal"
	local pendingSent = false
	local visibilitySeen = false
	local visibilityFinalized = false
	local function FinalizeVisiblePreview()
		if visibilityFinalized or not pendingSent or state.cancelled == true
			or self.runtimeStates[playerID] ~= state
			or self.previewGeneration[playerID] ~= generation then
			return false
		end
		visibilityFinalized = true
		state.on_visible = nil
		self.verified[playerID] = self.verified[playerID] or {}
		self.verified[playerID][candidateID] = assetSignature
		Send(playerID, "supporter_content_studio_preview_result", {
			ok = true,
			verified = true,
			candidate_id = candidateID,
			asset_signature = assetSignature,
			operation_id = operationID,
			message = "The selected VPCF was created by its live gameplay trigger. Confirm that it is clearly visible before sending it to review."
		})
		return true
	end
	if requiresVisibleCallback then
		state.on_visible = function()
			if visibilitySeen then return false end
			visibilitySeen = true
			if pendingSent then return FinalizeVisiblePreview() end
			return true
		end
	end
	Battlepass.SUPPORTER_DEV_TESTS[playerID] = state
	self.runtimeStates[playerID] = state
	local called, success, message = pcall(function()
		return Battlepass:ApplySupporterDevTestItem(playerID, state, hero, false)
	end)
	if not called or success ~= true then
		self:StopPreview(playerID)
		return Send(playerID, "supporter_content_studio_preview_result", {
			ok = false,
			candidate_id = candidateID,
			operation_id = operationID,
			message = called and (message or "Live playback rejected this candidate.") or "Live playback raised an error. Keep this candidate unselected."
		})
	end
	local duration = math.max(2, math.min(tonumber(metadata.test_duration_seconds) or 6, 30))
	if requiresVisibleCallback then
		pendingSent = true
		Send(playerID, "supporter_content_studio_preview_result", {
			ok = true,
			pending = true,
			candidate_id = candidateID,
			asset_signature = assetSignature,
			operation_id = operationID,
			message = "Live trigger started. Waiting for the selected VPCF to be created before verification."
		})
		if visibilitySeen then FinalizeVisiblePreview() end
	else
		self.verified[playerID] = self.verified[playerID] or {}
		self.verified[playerID][candidateID] = assetSignature
		Send(playerID, "supporter_content_studio_preview_result", {
			ok = true,
			verified = true,
			candidate_id = candidateID,
			asset_signature = assetSignature,
			operation_id = operationID,
			message = slot == "teleport"
				and "Exact teleport start/end VPCFs started without moving the hero. Confirm both are clearly visible before sending."
				or "Category-matched live playback started. Confirm that the effect is clearly visible before sending it to review."
		})
	end
	state.timer = Timers:CreateTimer(duration, function()
		state.timer = nil
		if self.previewGeneration[playerID] == generation then
			if requiresVisibleCallback and not visibilityFinalized then
				Send(playerID, "supporter_content_studio_preview_result", {
					ok = false,
					candidate_id = candidateID,
					asset_signature = assetSignature,
					operation_id = operationID,
					message = "Preview timed out before the selected VPCF was created. Keep this candidate unverified and retry after checking the hero can perform the trigger."
				})
			end
			self:StopPreview(playerID)
		end
		return nil
	end)
end

function ContentStudio:Stop(sourceIndex, event)
	local playerID = ResolvePlayerID(sourceIndex)
	if playerID == nil then return end
	local operationID = tostring(event and event.operation_id or "")
	self:StopPreview(playerID)
	Send(playerID, "supporter_content_studio_preview_result", { ok = true, candidate_id = "", operation_id = operationID, stopped = true, message = "Preview stopped." })
end

function ContentStudio:Submit(sourceIndex, event)
	local playerID = ResolvePlayerID(sourceIndex)
	if playerID == nil or not IsStudioAvailable() then return end
	local candidateID = tostring(event and event.candidate_id or "")
	local operationID = tostring(event and event.operation_id or "")
	local candidate = self.candidates[playerID] and self.candidates[playerID][candidateID] or nil
	if candidate == nil then
		return Send(playerID, "supporter_content_studio_submit_result", { ok = false, candidate_id = candidateID, operation_id = operationID, message = "Candidate is not part of the synced official-asset list." })
	end
	local assetSignature = CandidateAssetSignature(candidate)
	if assetSignature == "" or not self.verified[playerID]
		or self.verified[playerID][candidateID] ~= assetSignature then
		return Send(playerID, "supporter_content_studio_submit_result", { ok = false, candidate_id = candidateID, operation_id = operationID, message = "Run the live gameplay preview and confirm it is visible before sending this candidate." })
	end
	local steamid = PersistentSteamID(playerID)
	local gameID = api and api.GetApiGameId and api:GetApiGameId() or nil
	if steamid == nil or gameID == nil or api == nil or api.Request == nil then
		return Send(playerID, "supporter_content_studio_submit_result", { ok = false, candidate_id = candidateID, operation_id = operationID, message = "Registered demo game required before submission." })
	end
	api:Request("supporter-pass/content-studio/submit", function(response)
		candidate.sent = true
		Send(playerID, "supporter_content_studio_submit_result", {
			ok = true,
			candidate_id = candidateID,
			asset_signature = assetSignature,
			operation_id = operationID,
			already_sent = response and response.already_sent == true,
			message = response and response.already_sent == true and "Already sent; no duplicate was created." or "Candidate sent to the review queue."
		})
	end, function(error)
		Send(playerID, "supporter_content_studio_submit_result", { ok = false, candidate_id = candidateID, operation_id = operationID, message = error and error.message or "Submission failed." })
	end, "POST", {
		steamid = steamid,
		game_id = gameID,
		request_id = "studio_" .. tostring(playerID) .. "_" .. operationID,
		candidate_id = candidateID,
		category = tostring(candidate.category or ""),
		asset_path = tostring(candidate.asset_path or ""),
		asset_signature = assetSignature,
	})
end

CustomGameEventManager:RegisterListener("supporter_content_studio_sync", function(sourceIndex, event) ContentStudio:Sync(sourceIndex, event) end)
CustomGameEventManager:RegisterListener("supporter_content_studio_preview", function(sourceIndex, event) ContentStudio:Preview(sourceIndex, event) end)
CustomGameEventManager:RegisterListener("supporter_content_studio_stop", function(sourceIndex, event) ContentStudio:Stop(sourceIndex, event) end)
CustomGameEventManager:RegisterListener("supporter_content_studio_submit", function(sourceIndex, event) ContentStudio:Submit(sourceIndex, event) end)
ListenToGameEvent("player_disconnect", function(event)
	local playerID = tonumber(event and (event.PlayerID or event.playerid))
	if playerID ~= nil and playerID >= 0 then
		ContentStudio:StopPreview(playerID)
		ContentStudio.syncGeneration[playerID] = (ContentStudio.syncGeneration[playerID] or 0) + 1
		ContentStudio.candidates[playerID] = nil
		ContentStudio.verified[playerID] = nil
		ContentStudio.runtimeStates[playerID] = nil
	end
end, nil)

return ContentStudio
