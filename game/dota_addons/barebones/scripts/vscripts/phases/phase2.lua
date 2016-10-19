require('libraries/timers')
--	require('gamemode')

first_time_wisp = true
first_time_teleport = true
first_time_teleport_arthas = true
first_time_teleport_arthas_real = true
STARTING_GOLD = 800

function SpawnHeroesBis()
	-- Special Events
	local frost_infernal = CreateUnitByName("npc_frost_infernal_bis", Entities:FindByName(nil, "frost_infernal_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	frost_infernal:SetAngles(0, 270, 0)

	-- VIP Hero
	local slardar = CreateUnitByName("npc_dota_hero_slardar_bis", Entities:FindByName(nil, "choose_slardar_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	slardar:SetAngles(0, 270, 0)

	-- Inner West
	local enchantress = CreateUnitByName("npc_dota_hero_enchantress_bis", Entities:FindByName(nil, "choose_enchantress_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	enchantress:SetAngles(0, 0, 0)

	local crystal_maiden = CreateUnitByName("npc_dota_hero_crystal_maiden_bis", Entities:FindByName(nil, "choose_crystal_maiden_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	crystal_maiden:SetAngles(0, 0, 0)

	local luna = CreateUnitByName("npc_dota_hero_luna_bis", Entities:FindByName(nil, "choose_luna_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	luna:SetAngles(0, 0, 0)
	-- Inner North
	local terrorblade = CreateUnitByName("npc_dota_hero_terrorblade_bis", Entities:FindByName(nil, "choose_terrorblade_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	terrorblade:SetAngles(0, 270, 0)

	local phantom_assassin = CreateUnitByName("npc_dota_hero_phantom_assassin_bis", Entities:FindByName(nil, "choose_phantom_assassin_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	phantom_assassin:SetAngles(0, 270, 0)
	-- Inner South
	local lina = CreateUnitByName("npc_dota_hero_lina_bis", Entities:FindByName(nil, "choose_lina_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	lina:SetAngles(0, 90, 0)

	local sven = CreateUnitByName("npc_dota_hero_sven_bis", Entities:FindByName(nil, "choose_sven_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	sven:SetAngles(0, 90, 0)
	-- Inner East
	local windrunner = CreateUnitByName("npc_dota_hero_windrunner_bis", Entities:FindByName(nil, "choose_windrunner_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	windrunner:SetAngles(0, 180, 0)
	-- Outer East
	local juggernaut = CreateUnitByName("npc_dota_hero_juggernaut_bis", Entities:FindByName(nil, "choose_juggernaut_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	juggernaut:SetAngles(0, 0, 0)

	local omniknight = CreateUnitByName("npc_dota_hero_omniknight_bis", Entities:FindByName(nil, "choose_omniknight_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	omniknight:SetAngles(0, 0, 0)

	local rattletrap = CreateUnitByName("npc_dota_hero_rattletrap_bis", Entities:FindByName(nil, "choose_rattletrap_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	rattletrap:SetAngles(0, 0, 0)

	local lich = CreateUnitByName("npc_dota_hero_lich_bis", Entities:FindByName(nil, "choose_lich_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	lich:SetAngles(0, 180, 0)

	local pugna = CreateUnitByName("npc_dota_hero_pugna_bis", Entities:FindByName(nil, "choose_pugna_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	pugna:SetAngles(0, 180, 0)

	local abyssal_underlord = CreateUnitByName("npc_dota_hero_abyssal_underlord_bis", Entities:FindByName(nil, "choose_abyssal_underlord_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	abyssal_underlord:SetAngles(0, 180, 0)

	local nevermore = CreateUnitByName("npc_dota_hero_nevermore_bis", Entities:FindByName(nil, "choose_nevermore_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	nevermore:SetAngles(0, 270, 0)

	local brewmaster = CreateUnitByName("npc_dota_hero_brewmaster_bis", Entities:FindByName(nil, "choose_brewmaster_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	brewmaster:SetAngles(0, 270, 0)

	local warlock = CreateUnitByName("npc_dota_hero_warlock_bis", Entities:FindByName(nil, "choose_warlock_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	warlock:SetAngles(0, 270, 0)

	local elder_titan = CreateUnitByName("npc_dota_hero_elder_titan_bis", Entities:FindByName(nil, "choose_elder_titan_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	elder_titan:SetAngles(0, 90, 0)

	local mirana = CreateUnitByName("npc_dota_hero_mirana_bis", Entities:FindByName(nil, "choose_mirana_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	mirana:SetAngles(0, 90, 0)

	local dragon_knight = CreateUnitByName("npc_dota_hero_dragon_knight_bis", Entities:FindByName(nil, "choose_dragon_knight_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	dragon_knight:SetAngles(0, 90, 0)

	local shadow_shaman = CreateUnitByName("npc_dota_hero_shadow_shaman_bis", Entities:FindByName(nil, "choose_shadow_shaman_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	shadow_shaman:SetAngles(0, 0, 0)

	local invoker = CreateUnitByName("npc_dota_hero_invoker_bis", Entities:FindByName(nil, "choose_invoker_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	invoker:SetAngles(0, 180, 0)

	local keeper_of_the_light = CreateUnitByName("npc_dota_hero_keeper_of_the_light_bis", Entities:FindByName(nil, "choose_keeper_of_the_light_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	keeper_of_the_light:SetAngles(0, 0, 0)

	local nyx_assassin = CreateUnitByName("npc_dota_hero_nyx_assassin_bis", Entities:FindByName(nil, "choose_nyx_assassin_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	nyx_assassin:SetAngles(0, 180, 0)

	local sniper = CreateUnitByName("npc_dota_hero_sniper_bis", Entities:FindByName(nil, "choose_sniper_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	sniper:SetAngles(0, 180, 0)
end

function SpawnTeleporterGoodGuys(keys)
local activator = keys.activator
local point = Entities:FindByName(nil,"point_teleport_choose_hero"):GetAbsOrigin()
local heroes = HeroList:GetAllHeroes()

	for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
		if PlayerResource:IsValidPlayer(playerID) and activator:GetUnitName() == "npc_dota_hero_wisp" then
			PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),activator)
			FindClearSpaceForUnit(activator, point, true)
			Timers:CreateTimer(0.5, function()
				PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),nil)
			end)
		end
	end
end

function choose_slardar(keys)
local activator = keys.activator
local point = Entities:FindByName(nil,"base_spawn"):GetAbsOrigin()

	for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
		if PlayerResource:IsValidPlayer(playerID) and activator:GetUnitName() == "npc_dota_hero_wisp" and (PlayerResource:GetSteamAccountID(playerID)) == 54896080 or (PlayerResource:GetSteamAccountID(playerID)) == 295458357 or (PlayerResource:GetSteamAccountID(playerID)) == 61711140 or (PlayerResource:GetSteamAccountID(playerID)) == 206464009 then -- Cookies + X Hero Siege + Mugiwara +  beast SteamID64
			PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),activator)
			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),nil)
				FindClearSpaceForUnit(activator, point, true)
				PlayerResource:ReplaceHeroWith(activator:GetPlayerID(), "npc_dota_hero_slardar", STARTING_GOLD, 0)
			end)
		elseif PlayerResource:IsValidPlayer(playerID) and activator:GetUnitName() == "npc_dota_hero_wisp" then
			Say(nil, "This hero is only for <font color='#FF0000'>VIP Members!</font> Please choose another hero.", false)
		end
	end
end

function choose_enchantress(keys)
local activator = keys.activator
local point = Entities:FindByName(nil,"base_spawn"):GetAbsOrigin()

	for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
		if PlayerResource:IsValidPlayer(playerID) and activator:GetUnitName() == "npc_dota_hero_wisp" then
			PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),activator)
			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),nil)
				FindClearSpaceForUnit(activator, point, true)
				PlayerResource:ReplaceHeroWith(activator:GetPlayerID(), "npc_dota_hero_enchantress", STARTING_GOLD, 0)
			end)
		end
	end
end

function choose_crystal_maiden(keys)
local activator = keys.activator
local point = Entities:FindByName(nil,"base_spawn"):GetAbsOrigin()

	for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
		if PlayerResource:IsValidPlayer(playerID) and activator:GetUnitName() == "npc_dota_hero_wisp" then
			PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),activator)
			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),nil)
				FindClearSpaceForUnit(activator, point, true)
				PlayerResource:ReplaceHeroWith(activator:GetPlayerID(), "npc_dota_hero_crystal_maiden", STARTING_GOLD, 0)
			end)
		end
	end
end

function choose_luna(keys)
local activator = keys.activator
local point = Entities:FindByName(nil,"base_spawn"):GetAbsOrigin()

	for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
		if PlayerResource:IsValidPlayer(playerID) and activator:GetUnitName() == "npc_dota_hero_wisp" then
			PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),activator)
			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),nil)
				FindClearSpaceForUnit(activator, point, true)
				PlayerResource:ReplaceHeroWith(activator:GetPlayerID(), "npc_dota_hero_luna", STARTING_GOLD, 0)
			end)
		end
	end
end

function choose_terrorblade(keys)
local activator = keys.activator
local point = Entities:FindByName(nil,"base_spawn"):GetAbsOrigin()

	for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
		if PlayerResource:IsValidPlayer(playerID) and activator:GetUnitName() == "npc_dota_hero_wisp" then
			PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),activator)
			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),nil)
				FindClearSpaceForUnit(activator, point, true)
				PlayerResource:ReplaceHeroWith(activator:GetPlayerID(), "npc_dota_hero_terrorblade", STARTING_GOLD, 0)
			end)
		end
	end
end

function choose_phantom_assassin(keys)
local activator = keys.activator
local point = Entities:FindByName(nil,"base_spawn"):GetAbsOrigin()

	for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
		if PlayerResource:IsValidPlayer(playerID) and activator:GetUnitName() == "npc_dota_hero_wisp" then
			PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),activator)
			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),nil)
				FindClearSpaceForUnit(activator, point, true)
				PlayerResource:ReplaceHeroWith(activator:GetPlayerID(), "npc_dota_hero_phantom_assassin", STARTING_GOLD, 0)
			end)
		end
	end
end

function choose_lina(keys)
local activator = keys.activator
local point = Entities:FindByName(nil,"base_spawn"):GetAbsOrigin()

	for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
		if PlayerResource:IsValidPlayer(playerID) and activator:GetUnitName() == "npc_dota_hero_wisp" then
			PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),activator)
			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),nil)
				FindClearSpaceForUnit(activator, point, true)
				PlayerResource:ReplaceHeroWith(activator:GetPlayerID(), "npc_dota_hero_lina", STARTING_GOLD, 0)
			end)
		end
	end
end

function choose_sven(keys)
local activator = keys.activator
local point = Entities:FindByName(nil,"base_spawn"):GetAbsOrigin()

	for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
		if PlayerResource:IsValidPlayer(playerID) and activator:GetUnitName() == "npc_dota_hero_wisp" then
			PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),activator)
			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),nil)
				FindClearSpaceForUnit(activator, point, true)
				PlayerResource:ReplaceHeroWith(activator:GetPlayerID(), "npc_dota_hero_sven", STARTING_GOLD, 0)
			end)
		end
	end
end

function choose_windrunner(keys)
local activator = keys.activator
local point = Entities:FindByName(nil,"base_spawn"):GetAbsOrigin()

	for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
		if PlayerResource:IsValidPlayer(playerID) and activator:GetUnitName() == "npc_dota_hero_wisp" then
			PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),activator)
			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),nil)
				FindClearSpaceForUnit(activator, point, true)
				PlayerResource:ReplaceHeroWith(activator:GetPlayerID(), "npc_dota_hero_windrunner", STARTING_GOLD, 0)
			end)
		end
	end
end

function choose_juggernaut(keys)
local activator = keys.activator
local point = Entities:FindByName(nil,"base_spawn"):GetAbsOrigin()

	for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
		if PlayerResource:IsValidPlayer(playerID) and activator:GetUnitName() == "npc_dota_hero_wisp" then
			PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),activator)
			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),nil)
				FindClearSpaceForUnit(activator, point, true)
				PlayerResource:ReplaceHeroWith(activator:GetPlayerID(), "npc_dota_hero_juggernaut", STARTING_GOLD, 0)
			end)
		end
	end
end

function choose_omniknight(keys)
local activator = keys.activator
local point = Entities:FindByName(nil,"base_spawn"):GetAbsOrigin()

	for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
		if PlayerResource:IsValidPlayer(playerID) and activator:GetUnitName() == "npc_dota_hero_wisp" then
			PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),activator)
			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),nil)
				FindClearSpaceForUnit(activator, point, true)
				PlayerResource:ReplaceHeroWith(activator:GetPlayerID(), "npc_dota_hero_omniknight", STARTING_GOLD, 0)
			end)
		end
	end
end

function choose_rattletrap(keys)
local activator = keys.activator
local point = Entities:FindByName(nil,"base_spawn"):GetAbsOrigin()

	for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
		if PlayerResource:IsValidPlayer(playerID) and activator:GetUnitName() == "npc_dota_hero_wisp" then
			PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),activator)
			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),nil)
				FindClearSpaceForUnit(activator, point, true)
				PlayerResource:ReplaceHeroWith(activator:GetPlayerID(), "npc_dota_hero_rattletrap", STARTING_GOLD, 0)
			end)
		end
	end
end

function choose_lich(keys)
local activator = keys.activator
local point = Entities:FindByName(nil,"base_spawn"):GetAbsOrigin()

	for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
		if PlayerResource:IsValidPlayer(playerID) and activator:GetUnitName() == "npc_dota_hero_wisp" then
			PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),activator)
			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),nil)
				FindClearSpaceForUnit(activator, point, true)
				PlayerResource:ReplaceHeroWith(activator:GetPlayerID(), "npc_dota_hero_lich", STARTING_GOLD, 0)
			end)
		end
	end
end

function choose_pugna(keys)
local activator = keys.activator
local point = Entities:FindByName(nil,"base_spawn"):GetAbsOrigin()

	for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
		if PlayerResource:IsValidPlayer(playerID) and activator:GetUnitName() == "npc_dota_hero_wisp" then
			PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),activator)
			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),nil)
				FindClearSpaceForUnit(activator, point, true)
				PlayerResource:ReplaceHeroWith(activator:GetPlayerID(), "npc_dota_hero_pugna", STARTING_GOLD, 0)
			end)
		end
	end
end

function choose_abyssal_underlord(keys)
local activator = keys.activator
local point = Entities:FindByName(nil,"base_spawn"):GetAbsOrigin()

	for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
		if PlayerResource:IsValidPlayer(playerID) and activator:GetUnitName() == "npc_dota_hero_wisp" then
			PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),activator)
			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),nil)
				FindClearSpaceForUnit(activator, point, true)
				PlayerResource:ReplaceHeroWith(activator:GetPlayerID(), "npc_dota_hero_abyssal_underlord", STARTING_GOLD, 0)
			end)
		end
	end
end

function choose_nevermore(keys)
local activator = keys.activator
local point = Entities:FindByName(nil,"base_spawn"):GetAbsOrigin()

	for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
		if PlayerResource:IsValidPlayer(playerID) and activator:GetUnitName() == "npc_dota_hero_wisp" then
			PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),activator)
			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),nil)
				FindClearSpaceForUnit(activator, point, true)
				PlayerResource:ReplaceHeroWith(activator:GetPlayerID(), "npc_dota_hero_nevermore", STARTING_GOLD, 0)
			end)
		end
	end
end

function choose_brewmaster(keys)
local activator = keys.activator
local point = Entities:FindByName(nil,"base_spawn"):GetAbsOrigin()

	for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
		if PlayerResource:IsValidPlayer(playerID) and activator:GetUnitName() == "npc_dota_hero_wisp" then
			PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),activator)
			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),nil)
				FindClearSpaceForUnit(activator, point, true)
				PlayerResource:ReplaceHeroWith(activator:GetPlayerID(), "npc_dota_hero_brewmaster", STARTING_GOLD, 0)
			end)
		end
	end
end

function choose_warlock(keys)
local activator = keys.activator
local point = Entities:FindByName(nil,"base_spawn"):GetAbsOrigin()

	for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
		if PlayerResource:IsValidPlayer(playerID) and activator:GetUnitName() == "npc_dota_hero_wisp" then
			PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),activator)
			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),nil)
				FindClearSpaceForUnit(activator, point, true)
				PlayerResource:ReplaceHeroWith(activator:GetPlayerID(), "npc_dota_hero_warlock", STARTING_GOLD, 0)
			end)
		end
	end
end

function choose_elder_titan(keys)
local activator = keys.activator
local point = Entities:FindByName(nil,"base_spawn"):GetAbsOrigin()

	for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
		if PlayerResource:IsValidPlayer(playerID) and activator:GetUnitName() == "npc_dota_hero_wisp" then
			PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),activator)
			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),nil)
				FindClearSpaceForUnit(activator, point, true)
				PlayerResource:ReplaceHeroWith(activator:GetPlayerID(), "npc_dota_hero_elder_titan", STARTING_GOLD, 0)
			end)
		end
	end
end

function choose_mirana(keys)
local activator = keys.activator
local point = Entities:FindByName(nil,"base_spawn"):GetAbsOrigin()

	for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
		if PlayerResource:IsValidPlayer(playerID) and activator:GetUnitName() == "npc_dota_hero_wisp" then
			PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),activator)
			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),nil)
				FindClearSpaceForUnit(activator, point, true)
				PlayerResource:ReplaceHeroWith(activator:GetPlayerID(), "npc_dota_hero_mirana", STARTING_GOLD, 0)
			end)
		end
	end
end

function choose_dragon_knight(keys)
local activator = keys.activator
local point = Entities:FindByName(nil,"base_spawn"):GetAbsOrigin()

	for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
		if PlayerResource:IsValidPlayer(playerID) and activator:GetUnitName() == "npc_dota_hero_wisp" then
			PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),activator)
			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),nil)
				FindClearSpaceForUnit(activator, point, true)
				PlayerResource:ReplaceHeroWith(activator:GetPlayerID(), "npc_dota_hero_dragon_knight", STARTING_GOLD, 0)
			end)
		end
	end
end

function choose_shadow_shaman(keys)
local activator = keys.activator
local point = Entities:FindByName(nil,"base_spawn"):GetAbsOrigin()

	for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
		if PlayerResource:IsValidPlayer(playerID) and activator:GetUnitName() == "npc_dota_hero_wisp" then
			PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),activator)
			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),nil)
				FindClearSpaceForUnit(activator, point, true)
				PlayerResource:ReplaceHeroWith(activator:GetPlayerID(), "npc_dota_hero_shadow_shaman", STARTING_GOLD, 0)
			end)
		end
	end
end

function choose_invoker(keys)
local activator = keys.activator
local point = Entities:FindByName(nil,"base_spawn"):GetAbsOrigin()

	for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
		if PlayerResource:IsValidPlayer(playerID) and activator:GetUnitName() == "npc_dota_hero_wisp" then
			PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),activator)
			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),nil)
				FindClearSpaceForUnit(activator, point, true)
				PlayerResource:ReplaceHeroWith(activator:GetPlayerID(), "npc_dota_hero_invoker", STARTING_GOLD, 0)
			end)
		end
	end
end

function choose_keeper_of_the_light(keys)
local activator = keys.activator
local point = Entities:FindByName(nil,"base_spawn"):GetAbsOrigin()

	for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
		if PlayerResource:IsValidPlayer(playerID) and activator:GetUnitName() == "npc_dota_hero_wisp" then
			PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),activator)
			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),nil)
				FindClearSpaceForUnit(activator, point, true)
				PlayerResource:ReplaceHeroWith(activator:GetPlayerID(), "npc_dota_hero_keeper_of_the_light", STARTING_GOLD, 0)
			end)
		end
	end
end

function choose_nyx_assassin(keys)
local activator = keys.activator
local point = Entities:FindByName(nil,"base_spawn"):GetAbsOrigin()

	for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
		if PlayerResource:IsValidPlayer(playerID) and activator:GetUnitName() == "npc_dota_hero_wisp" then
			PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),activator)
			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),nil)
				FindClearSpaceForUnit(activator, point, true)
				PlayerResource:ReplaceHeroWith(activator:GetPlayerID(), "npc_dota_hero_nyx_assassin", STARTING_GOLD, 0)
			end)
		end
	end
end

function choose_sniper(keys)
local activator = keys.activator
local point = Entities:FindByName(nil,"base_spawn"):GetAbsOrigin()

	for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
		if PlayerResource:IsValidPlayer(playerID) and activator:GetUnitName() == "npc_dota_hero_wisp" then
			PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),activator)
			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),nil)
				FindClearSpaceForUnit(activator, point, true)
				PlayerResource:ReplaceHeroWith(activator:GetPlayerID(), "npc_dota_hero_sniper", STARTING_GOLD, 0)
			end)
		end
	end
end

function trigger_second_wave_left()
--	local skywrath = Entities:FindByName(nil, "SkywrathMage_Guardian1"):GetAbsOrigin()
	print("Disabled trigger left")
	DoEntFire("trigger_phase2_left", "Kill", nil ,0 ,nil ,nil)
--	skywrath:RemoveSelf()

	Timers:CreateTimer(2.5, spawn_second_phase_left)
end

function trigger_second_wave_right()
	print("Disabled trigger right")
	DoEntFire("trigger_phase2_right", "Kill", nil, 0, nil, nil)
	
	Timers:CreateTimer(2.5, spawn_second_phase_right)
end

function spawn_second_phase_left()
	local EntIceTower = Entities:FindByName( nil, "npc_tower_cold_1" )
	local point = Entities:FindByName( nil, "npc_dota_spawner_top_left_1"):GetAbsOrigin()

	Timers:CreateTimer(0, function()
		if not EntIceTower:IsNull() then -- Level 1 lower than 6 min
			for j = 1, 8 do
			local unit = CreateUnitByName("npc_ghul_II", point+RandomVector(RandomInt(0, 50)), true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds
		elseif EntIceTower:IsNull() then
		return nil
		end
	end)
end

function spawn_second_phase_right()
	local EntIceTower = Entities:FindByName( nil, "npc_tower_cold_2" )
	local point = Entities:FindByName( nil, "npc_dota_spawner_top_right_1"):GetAbsOrigin()
	Timers:CreateTimer(0, function()
		if not EntIceTower:IsNull() then -- Level 1 lower than 6 min
			for j = 1, 8 do
			local unit = CreateUnitByName("npc_orc_II", point+RandomVector(RandomInt(0, 50)), true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds
		elseif EntIceTower:IsNull() then
		return nil
		end
	end)
end

function killed_frost_tower_left(keys)
GameMode.FrostTowers_killed = GameMode.FrostTowers_killed +1
print( GameMode.FrostTowers_killed )

	if GameMode.FrostTowers_killed >= 2 then
		print("FinalWave timer started")
		Notifications:TopToAll({text="WARNING! Final Wave incoming. Arriving in 60 seconds! Back to the Castle!" , duration=10.0})
		Timers:CreateTimer(60,FinalWave)
		FrostTowersToFinalWave()
	end
end

function killed_frost_tower_right(keys)
GameMode.FrostTowers_killed = GameMode.FrostTowers_killed +1
print( GameMode.FrostTowers_killed )

	if GameMode.FrostTowers_killed >= 2 then
		DebugPrint("FinalWave timer started")
		Notifications:TopToAll({text="WARNING! Final Wave incoming. Arriving in 60 seconds! Back to the Castle!" , duration=10.0})
		Timers:CreateTimer(60,FinalWave)
		FrostTowersToFinalWave()
	end
end

final_wave_creeps = {
	west = {
	"npc_abomination_final_wave",
	"npc_abomination_final_wave",
	"npc_abomination_final_wave",
	"npc_banshee_final_wave",
	"npc_banshee_final_wave",
	"npc_banshee_final_wave",
	"npc_necro_final_wave",
	"npc_necro_final_wave",
	"npc_necro_final_wave",
	"npc_magnataur_final_wave",
	"npc_magnataur_final_wave",
	"npc_magnataur_final_wave",
	"npc_dota_hero_balanar_final_wave"
	},

	north = {
	"npc_tauren_final_wave",
	"npc_tauren_final_wave",
	"npc_tauren_final_wave",
	"npc_chaos_orc_final_wave",
	"npc_chaos_orc_final_wave",
	"npc_chaos_orc_final_wave",
	"npc_warlock_final_wave",
	"npc_warlock_final_wave",
	"npc_warlock_final_wave",
	"npc_orc_raider_final_wave",
	"npc_orc_raider_final_wave",
	"npc_orc_raider_final_wave",
	"npc_dota_hero_grom_hellscream_final_wave"
	},

	east = {
	"npc_druid_final_wave",
	"npc_druid_final_wave",
	"npc_druid_final_wave",
	"npc_guard_final_wave",
	"npc_guard_final_wave",
	"npc_guard_final_wave",
	"npc_keeper_final_wave",
	"npc_keeper_final_wave",
	"npc_keeper_final_wave",
	"npc_luna_final_wave",
	"npc_luna_final_wave",
	"npc_luna_final_wave",
	"npc_dota_hero_illidan_final_wave"
	},

	south = {
	"npc_captain_final_wave",
	"npc_captain_final_wave",
	"npc_captain_final_wave",
	"npc_marine_final_wave",
	"npc_marine_final_wave",
	"npc_marine_final_wave",
	"npc_marine_final_wave",
	"npc_marine_final_wave",
	"npc_marine_final_wave",
	"npc_marine_final_wave",
	"npc_knight_final_wave",
	"npc_knight_final_wave",
	"npc_knight_final_wave",
	"npc_dota_hero_proudmoore_final_wave"
	}
}

function FinalWave()
  -- body
local final_spawn = nil
local waypoint = Entities:FindByName(nil,"base")
DebugPrint("Final Wave spawn")
		local directions = {"west","north","east","south"}
	for _,direction in pairs(directions) do
		for i = 1,17 do
			final_spawn = Entities:FindAllByName("npc_dota_spawner_"..direction.."_event")

			for _,point in pairs(final_spawn) do
				DebugPrint("spawn unit")
				Timers:CreateTimer(function()
				local unit = CreateUnitByName(final_wave_creeps[direction][i], point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
				unit:AddNewModifier(nil, nil, "modifier_animation_freeze_stun", {duration= 15, IsHidden = true})
				unit:AddNewModifier(nil, nil, "modifier_invulnerable", {duration= 15, IsHidden = true})
				end)
			end
		end
	end
	local teleporters = Entities:FindAllByName("trigger_teleport")

	for _,v in pairs(teleporters) do
	DebugPrint("enable teleport trigger")
	v:Enable()
	end
return nil
end

function EndMuradinEvent(keys)
	local caller = keys.caller
	local activator = keys.activator
	local point = Entities:FindByName(nil,"base_spawn"):GetAbsOrigin()

	if activator:GetTeam() == DOTA_TEAM_GOODGUYS then
	FindClearSpaceForUnit(activator, point, true)
	activator:Stop()
	PlayerResource:ModifyGold( activator:GetPlayerOwnerID(), 10000, false,  DOTA_ModifyGold_Unspecified )
	end
end

function teleport_to_top(keys)
-- Spawn Magtheridon
DebugPrint("teleport trigger")
local caller = keys.caller
local activator = keys.activator
local point = Entities:FindByName(nil,"point_teleport_boss"):GetAbsOrigin()
local point_mag = Entities:FindByName(nil,"npc_dota_spawner_magtheridon_arena"):GetAbsOrigin()
local point_mag2 = Entities:FindByName(nil,"npc_dota_spawner_magtheridon_arena2"):GetAbsOrigin()
local ankh = CreateItem("item_magtheridon_ankh", mag, mag)
local ankh2 = CreateItem("item_magtheridon_ankh", mag, mag)
local difficulty = GameRules:GetCustomGameDifficulty()

	if first_time_teleport then
		local heroes = HeroList:GetAllHeroes()
		print( "Magtheridon should appears now" )

		if difficulty == 1 then
			magtheridon = CreateUnitByName("npc_dota_hero_magtheridon", point_mag  ,true,nil,nil,DOTA_TEAM_BADGUYS)
			magtheridon:SetAngles(0, 180, 0)
		elseif difficulty == 2 then
			magtheridon = CreateUnitByName("npc_dota_hero_magtheridon", point_mag  ,true,nil,nil,DOTA_TEAM_BADGUYS)
			magtheridon:SetAngles(0, 180, 0)
			ankh:SetCurrentCharges(1)
			magtheridon:AddItem(ankh)
		elseif difficulty == 3 then
			magtheridon = CreateUnitByName("npc_dota_hero_magtheridon", point_mag  ,true,nil,nil,DOTA_TEAM_BADGUYS)
			magtheridon:SetAngles(0, 180, 0)
			ankh:SetCurrentCharges(3)
			magtheridon:AddItem(ankh)
		elseif difficulty == 4 then
			magtheridon = CreateUnitByName("npc_dota_hero_magtheridon", point_mag  ,true,nil,nil,DOTA_TEAM_BADGUYS)
			magtheridon2 = CreateUnitByName("npc_dota_hero_magtheridon", point_mag2  ,true,nil,nil,DOTA_TEAM_BADGUYS)
			magtheridon:SetAngles(0, 180, 0)
			magtheridon2:SetAngles(0, 0, 0)
			magtheridon:AddItem(ankh)
			magtheridon2:AddItem(ankh2)
			ankh2:SetCurrentCharges(1)
		end

		Timers:CreateTimer(10,StartMagtheridonFight)
		for _,hero in pairs(heroes) do
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				FindClearSpaceForUnit(hero, point, true)
				activator:Stop()
				hero:AddNewModifier(nil, nil, "modifier_animation_freeze_stun",nil)
				hero:AddNewModifier(nil, nil, "modifier_invulnerable",nil)
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
				first_time_teleport = false
				elseif hero:GetTeam() == DOTA_TEAM_GOODGUYS and hero:GetPlayerOwnerID() == 0 then
			end
		end

	elseif activator:GetTeam() == DOTA_TEAM_GOODGUYS then
		FindClearSpaceForUnit(activator, point, true)
		activator:Stop()
	end
end

function StartMagtheridonFight()
local heroes = HeroList:GetAllHeroes()

for _,hero in pairs(heroes) do
		if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
			PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil)
			hero:RemoveModifierByName("modifier_animation_freeze_stun")
			hero:RemoveModifierByName("modifier_invulnerable")
		end
	end
	return nil
end

function kill_magtheridon_count(keys)
local teleporters2 = Entities:FindAllByName("trigger_teleport2")
local difficulty = GameRules:GetCustomGameDifficulty()

	GameMode.Magtheridon_killed = GameMode.Magtheridon_killed +1
	print( GameMode.Magtheridon_killed )

	if GameMode.Magtheridon_killed > 0 and difficulty == 1 then
		for _,v in pairs(teleporters2) do
			DebugPrint("enable teleport trigger")
			v:Enable()
		end
		Notifications:TopToAll({text="You have killed Magtheridon. Blue teleporters activated." , duration=10.0})

	elseif GameMode.Magtheridon_killed > 1 and difficulty == 2 then
		for _,v in pairs(teleporters2) do
			DebugPrint("enable teleport trigger")
			v:Enable()
		end
		Notifications:TopToAll({text="You have killed Magtheridon. Blue teleporters activated." , duration=10.0})

	elseif GameMode.Magtheridon_killed > 3 and difficulty == 3 then
		for _,v in pairs(teleporters2) do
			DebugPrint("enable teleport trigger")
			v:Enable()
		end
		Notifications:TopToAll({text="You have killed Magtheridon. Blue teleporters activated." , duration=10.0})

	elseif GameMode.Magtheridon_killed > 3 and difficulty == 4 then
		for _,v in pairs(teleporters2) do
			DebugPrint("enable teleport trigger")
			v:Enable()
		end
		Notifications:TopToAll({text="You have killed Magtheridon. Blue teleporters activated." , duration=10.0})
	end
end
