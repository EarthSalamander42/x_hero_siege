local ApiConfig = {
	endpoint = "http://api.dota2imba.fr",
	agent = "xhs-"..tostring(X_HERO_SIEGE_V), -- Add the version AND UPDATE it here
	timeout = 10000,
	debug = true
}

local ApiEndpoints = {
	donators = "/imba/donators"
}

function ApiDebug(text, ignore)
	if ApiConfig.debug or ignore ~= nil then
		print("[api] " .. tostring(text))
	end
end

function ApiPerform(data, endpoint, callback)
	local payload = nil
	local method = "GET"

	if data ~= nil then
		method = "POST"
		payload = json.encode({
			agent = ApiConfig.agent,
			time = {
				frames = tonumber(GetFrameCount()),
				server_time = tonumber(Time()),
				dota_time = tonumber(GameRules:GetDOTATime(true, true)),
				game_time = tonumber(GameRules:GetGameTime()),
				server_system_date_time = tostring(GetSystemDate()) .. " " .. tostring(GetSystemTime()),
			},
			data = data
		})
	end

	ApiDebug("Performing " .. method .. " @ " .. endpoint, true)

	if (method == "POST") then
		ApiDebug("Payload " .. payload)
	end

	-- create request
	rqH = CreateHTTPRequestScriptVM(method, ApiConfig.endpoint .. endpoint)
	rqH:SetHTTPRequestAbsoluteTimeoutMS(ApiConfig.timeout)

	-- set payload
	if payload ~= nil then
		rqH:SetHTTPRequestRawPostBody("application/json", payload)
	end

	ApiDebug("Performing Request to " .. ApiConfig.endpoint .. endpoint)

	-- send request
	rqH:Send(function (result)
		-- decode response (we should always get json)
		-- 500 indi
		ApiDebug("Status code: " .. result.StatusCode)
		if result.StatusCode == 503 then
			ApiDebug("Server not available!", true)
			callback(true, nil)
		elseif result.StatusCode ~= 200 then
			ApiDebug("Request failed with Invalid status: " .. result.StatusCode, true)
			callback(true, nil)
		else
			rp = json.decode(result.Body)
			if rp.error then
				ApiDebug("Request failed with custom error: " .. rp.message, true)
				callback(true, rp)
			else
				ApiDebug("Request succesful")
				ApiDebug("Payload: " .. result.Body)
				callback(false, rp)
			end
		end
	end)
end

local ApiCache = {
	donators = nil
}

function ApiLoad()
	ApiPerform(nil, ApiEndpoints.donators, function (err, response)
		if (err) then
			ApiDebug("Donators Request failed!", true)
		else
			ApiCache.donators = response.data.players
		end
	end)
end

function IsDonator(hero)
--	print(ApiCache.donators)

	local player_id = nil

	if string.find(hero:GetUnitName(), "npc_dota_lone_druid_bear") then
		if hero:GetOwnerEntity():GetPlayerID() then
			player_id = hero:GetOwnerEntity():GetPlayerID()
		end
	else
		if hero.GetPlayerID == nil then return false end
		if hero:GetPlayerID() == -1 or hero:IsIllusion() or ApiCache.donators == nil then return false end

		player_id = hero:GetPlayerID()
	end

	for i = 1, #ApiCache.donators do
--		print(PlayerResource:GetSteamID(player_id), ApiCache.donators[i].steamid)
		if tostring(PlayerResource:GetSteamID(player_id)) == ApiCache.donators[i].steamid then
			return ApiCache.donators[i].status
		elseif i == #ApiCache.donators then
			return false
		end
	end
end
