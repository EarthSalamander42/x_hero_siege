CustomPolls = CustomPolls or class({})

function CustomPolls:Init()
	if self.initialized then return end

	self.initialized = true
	self.polls = {}
	self.polls_by_id = {}
	self.pending_votes = {}
	self.server_time = nil

	CustomGameEventManager:RegisterListener("xhs_custom_poll_vote", Dynamic_Wrap(CustomPolls, "OnVoteRequested"))
end

function CustomPolls:SetBackendPayload(payload)
	self.server_time = payload and payload.server_time or nil
	self.polls = {}
	self.polls_by_id = {}
	self.pending_votes = {}

	if type(payload) == "table" and type(payload.polls) == "table" then
		for _, poll in pairs(payload.polls) do
			local normalized = self:NormalizePoll(poll)
			if normalized ~= nil then
				table.insert(self.polls, normalized)
				self.polls_by_id[normalized.poll_id] = normalized
			end
		end
	end

	table.sort(self.polls, function(a, b)
		local priority_a = tonumber(a.priority) or 0
		local priority_b = tonumber(b.priority) or 0
		if priority_a == priority_b then
			return tostring(a.poll_id) < tostring(b.poll_id)
		end
		return priority_a > priority_b
	end)

	self:PublishAll()
end

function CustomPolls:NormalizePoll(poll)
	if type(poll) ~= "table" then return nil end

	local poll_id = tostring(poll.poll_id or poll.id or "")
	if poll_id == "" then return nil end

	local normalized = {
		poll_id = poll_id,
		title = tostring(poll.title or "Community Vote"),
		description = tostring(poll.description or ""),
		priority = tonumber(poll.priority) or 0,
		starts_at = poll.starts_at,
		ends_at = poll.ends_at,
		options = {},
		players = poll.players or {},
		results = poll.results,
	}

	if type(poll.options) == "table" then
		for _, option in pairs(poll.options) do
			local option_id = tostring(option.option_id or option.id or option.option_key or "")
			if option_id ~= "" then
				table.insert(normalized.options, {
					option_id = option_id,
					label = tostring(option.label or option.title or option_id),
					description = tostring(option.description or ""),
					sort_order = tonumber(option.sort_order) or #normalized.options + 1,
				})
			end
		end
	end

	table.sort(normalized.options, function(a, b)
		if a.sort_order == b.sort_order then
			return tostring(a.option_id) < tostring(b.option_id)
		end
		return a.sort_order < b.sort_order
	end)

	if #normalized.options <= 0 then return nil end

	return normalized
end

function CustomPolls:PublishAll()
	for player_id = 0, PlayerResource:GetPlayerCount() - 1 do
		if PlayerResource:IsValidPlayerID(player_id) then
			self:PublishPlayer(player_id)
		end
	end
end

function CustomPolls:PublishPlayer(player_id)
	if player_id == nil or not PlayerResource:IsValidPlayerID(player_id) then return end

	CustomNetTables:SetTableValue("custom_polls", tostring(player_id), self:BuildPlayerState(player_id))
end

function CustomPolls:BuildPlayerState(player_id)
	local steamid = tostring(PlayerResource:GetSteamID(player_id))
	local state = {
		server_time = self.server_time,
		polls = {},
		has_unvoted = false,
		has_review = false,
	}

	for _, poll in ipairs(self.polls or {}) do
		local player_state = self:GetPollPlayerState(poll, steamid)
		local pending_key = self:GetPendingKey(player_id, poll.poll_id)

		local view = {
			poll_id = poll.poll_id,
			title = poll.title,
			description = poll.description,
			priority = poll.priority,
			starts_at = poll.starts_at,
			ends_at = poll.ends_at,
			options = poll.options,
			player = player_state,
			pending = self.pending_votes[pending_key] == true,
		}

		if player_state.voted then
			view.results = player_state.results or poll.results
			state.has_review = true
		else
			state.has_unvoted = true
		end

		table.insert(state.polls, view)
	end

	return state
end

function CustomPolls:GetPollPlayerState(poll, steamid)
	local row = nil
	if type(poll.players) == "table" then
		row = poll.players[steamid] or poll.players[tostring(steamid)]
	end
	row = type(row) == "table" and row or {}

	return {
		voted = row.voted == true or row.selected_option_id ~= nil,
		selected_option_id = row.selected_option_id and tostring(row.selected_option_id) or nil,
		results = row.results,
	}
end

function CustomPolls:GetPendingKey(player_id, poll_id)
	return tostring(player_id) .. ":" .. tostring(poll_id)
end

function CustomPolls:GetPlayerIDFromEvent(event_source_index, event)
	local player_id = nil

	if CustomGameEventManager.GetPlayerIDFromEventSourceIndex ~= nil then
		player_id = CustomGameEventManager:GetPlayerIDFromEventSourceIndex(event_source_index)
	end

	if player_id == nil or player_id < 0 then
		player_id = tonumber(event and event.PlayerID)
	end

	if player_id == nil or not PlayerResource:IsValidPlayerID(player_id) then
		return nil
	end

	return player_id
end

function CustomPolls:FindOption(poll, option_id)
	option_id = tostring(option_id or "")
	for _, option in ipairs(poll.options or {}) do
		if tostring(option.option_id) == option_id then
			return option
		end
	end
	return nil
end

function CustomPolls:SendResult(player_id, success, payload)
	local player = PlayerResource:GetPlayer(player_id)
	if player == nil then return end

	payload = payload or {}
	payload.success = success == true
	CustomGameEventManager:Send_ServerToPlayer(player, "xhs_custom_poll_vote_result", payload)
end

function CustomPolls:OnVoteRequested(event_source_index, event)
	local player_id = self:GetPlayerIDFromEvent(event_source_index, event)
	if player_id == nil then return end

	local poll_id = tostring(event and event.poll_id or "")
	local option_id = tostring(event and event.option_id or "")
	local poll = self.polls_by_id[poll_id]

	if poll == nil then
		self:SendResult(player_id, false, { message = "Poll unavailable." })
		return
	end

	if self:FindOption(poll, option_id) == nil then
		self:SendResult(player_id, false, { poll_id = poll_id, message = "Invalid poll option." })
		return
	end

	local steamid = tostring(PlayerResource:GetSteamID(player_id))
	local player_state = self:GetPollPlayerState(poll, steamid)
	if player_state.voted then
		self:SendResult(player_id, false, {
			poll_id = poll_id,
			selected_option_id = player_state.selected_option_id,
			message = "Vote already recorded.",
			state = self:BuildPlayerState(player_id),
		})
		return
	end

	local pending_key = self:GetPendingKey(player_id, poll_id)
	if self.pending_votes[pending_key] then
		self:SendResult(player_id, false, { poll_id = poll_id, message = "Vote already pending." })
		return
	end

	if api == nil or api.SubmitCustomPollVote == nil then
		self:SendResult(player_id, false, { poll_id = poll_id, message = "Vote backend unavailable." })
		return
	end

	self.pending_votes[pending_key] = true
	self:PublishPlayer(player_id)

	api:SubmitCustomPollVote(player_id, poll_id, option_id, function(success, data)
		self.pending_votes[pending_key] = nil

		if success then
			local selected_option_id = tostring(data.selected_option_id or option_id)
			poll.players = poll.players or {}
			poll.players[steamid] = poll.players[steamid] or {}
			poll.players[steamid].voted = true
			poll.players[steamid].selected_option_id = selected_option_id
			poll.players[steamid].results = data.results or poll.players[steamid].results
			poll.results = data.results or poll.results

			self:PublishPlayer(player_id)
			self:SendResult(player_id, true, {
				poll_id = poll_id,
				selected_option_id = selected_option_id,
				results = data.results,
				state = self:BuildPlayerState(player_id),
			})
			return
		end

		local message = data and data.message or "Vote failed."
		self:PublishPlayer(player_id)
		self:SendResult(player_id, false, {
			poll_id = poll_id,
			message = message,
			state = self:BuildPlayerState(player_id),
		})
	end)
end

CustomPolls:Init()
