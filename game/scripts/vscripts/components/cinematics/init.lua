if XHSCinematics == nil then
	_G.XHSCinematics = {}
end

local function BuildPayload(cinematicId, options)
	options = options or {}
	return {
		id = tostring(cinematicId or "default"),
		duration = tonumber(options.duration) or 0,
		letterbox_pct = tonumber(options.letterbox_pct) or 10,
		transition = tonumber(options.transition) or 0.7,
		hide_hud = options.hide_hud == false and 0 or 1,
		music = tostring(options.music or ""),
		music_layers = math.max(1, math.floor(tonumber(options.music_layers) or 1)),
		title = tostring(options.title or ""),
		subtitle = tostring(options.subtitle or ""),
	}
end

function XHSCinematics:BeginForPlayer(player, cinematicId, options)
	if type(player) == "number" then
		player = PlayerResource:GetPlayer(player)
	end
	if player == nil then return end

	CustomGameEventManager:Send_ServerToPlayer(player, "xhs_cinematic_begin", BuildPayload(cinematicId, options))
end

function XHSCinematics:BeginForAll(cinematicId, options)
	CustomGameEventManager:Send_ServerToAllClients("xhs_cinematic_begin", BuildPayload(cinematicId, options))
end

function XHSCinematics:EndForPlayer(player, cinematicId)
	if type(player) == "number" then
		player = PlayerResource:GetPlayer(player)
	end
	if player == nil then return end

	CustomGameEventManager:Send_ServerToPlayer(player, "xhs_cinematic_end", {
		id = tostring(cinematicId or "default"),
	})
end

function XHSCinematics:EndForAll(cinematicId)
	CustomGameEventManager:Send_ServerToAllClients("xhs_cinematic_end", {
		id = tostring(cinematicId or "default"),
	})
end

return XHSCinematics
