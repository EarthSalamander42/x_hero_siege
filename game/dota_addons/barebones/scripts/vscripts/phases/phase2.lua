require('libraries/timers')

first_time_teleport = true
first_time_teleport_arthas = true
first_time_teleport_arthas_real = true
STARTING_GOLD = 800

function SpawnHeroesBis()
local heroes = HeroList:GetAllHeroes()
	Timers:CreateTimer(5, function()
		-- Inner West
		local enchantress = CreateUnitByName("npc_dota_hero_enchantress_bis", Entities:FindByName(nil, "choose_enchantress_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		enchantress:SetAngles(0, 0, 0)

		local crystal_maiden = CreateUnitByName("npc_dota_hero_crystal_maiden_bis", Entities:FindByName(nil, "choose_crystal_maiden_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		crystal_maiden:SetAngles(0, 0, 0)

		local luna = CreateUnitByName("npc_dota_hero_luna_bis", Entities:FindByName(nil, "choose_luna_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		luna:SetAngles(0, 0, 0)

		-- Outer West
		local pugna = CreateUnitByName("npc_dota_hero_pugna_bis", Entities:FindByName(nil, "choose_pugna_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		pugna:SetAngles(0, 180, 0)

		local lich = CreateUnitByName("npc_dota_hero_lich_bis", Entities:FindByName(nil, "choose_lich_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		lich:SetAngles(0, 180, 0)

		local nyx_assassin = CreateUnitByName("npc_dota_hero_nyx_assassin_bis", Entities:FindByName(nil, "choose_nyx_assassin_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		nyx_assassin:SetAngles(0, 180, 0)

		local abyssal_underlord = CreateUnitByName("npc_dota_hero_abyssal_underlord_bis", Entities:FindByName(nil, "choose_abyssal_underlord_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		abyssal_underlord:SetAngles(0, 180, 0)

		for _,hero in pairs(heroes) do
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), lich)
			end
		end
	end)

	Timers:CreateTimer(8, function()
		-- Inner North
		local terrorblade = CreateUnitByName("npc_dota_hero_terrorblade_bis", Entities:FindByName(nil, "choose_terrorblade_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		terrorblade:SetAngles(0, 270, 0)

		local phantom_assassin = CreateUnitByName("npc_dota_hero_phantom_assassin_bis", Entities:FindByName(nil, "choose_phantom_assassin_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		phantom_assassin:SetAngles(0, 270, 0)

		-- Outer North
		local elder_titan = CreateUnitByName("npc_dota_hero_elder_titan_bis", Entities:FindByName(nil, "choose_elder_titan_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		elder_titan:SetAngles(0, 90, 0)

		local mirana = CreateUnitByName("npc_dota_hero_mirana_bis", Entities:FindByName(nil, "choose_mirana_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		mirana:SetAngles(0, 90, 0)

		local dragon_knight = CreateUnitByName("npc_dota_hero_dragon_knight_bis", Entities:FindByName(nil, "choose_dragon_knight_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		dragon_knight:SetAngles(0, 90, 0)

		for _,hero in pairs(heroes) do
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), mirana)
			end
		end
	end)

	Timers:CreateTimer(11, function()
		-- Inner East
		local windrunner = CreateUnitByName("npc_dota_hero_windrunner_bis", Entities:FindByName(nil, "choose_windrunner_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		windrunner:SetAngles(0, 180, 0)

		local invoker = CreateUnitByName("npc_dota_hero_invoker_bis", Entities:FindByName(nil, "choose_invoker_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		invoker:SetAngles(0, 180, 0)

		local sniper = CreateUnitByName("npc_dota_hero_sniper_bis", Entities:FindByName(nil, "choose_sniper_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		sniper:SetAngles(0, 180, 0)

		-- Outer East
		local shadow_shaman = CreateUnitByName("npc_dota_hero_shadow_shaman_bis", Entities:FindByName(nil, "choose_shadow_shaman_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		shadow_shaman:SetAngles(0, 0, 0)

		local juggernaut = CreateUnitByName("npc_dota_hero_juggernaut_bis", Entities:FindByName(nil, "choose_juggernaut_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		juggernaut:SetAngles(0, 0, 0)

		local omniknight = CreateUnitByName("npc_dota_hero_omniknight_bis", Entities:FindByName(nil, "choose_omniknight_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		omniknight:SetAngles(0, 0, 0)

		local rattletrap = CreateUnitByName("npc_dota_hero_rattletrap_bis", Entities:FindByName(nil, "choose_rattletrap_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		rattletrap:SetAngles(0, 0, 0)

		local keeper_of_the_light = CreateUnitByName("npc_dota_hero_keeper_of_the_light_bis", Entities:FindByName(nil, "choose_keeper_of_the_light_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		keeper_of_the_light:SetAngles(0, 0, 0)

		for _,hero in pairs(heroes) do
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), invoker)
			end
		end
	end)

	Timers:CreateTimer(14, function()
		-- Inner South
		local lina = CreateUnitByName("npc_dota_hero_lina_bis", Entities:FindByName(nil, "choose_lina_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		lina:SetAngles(0, 90, 0)

		local sven = CreateUnitByName("npc_dota_hero_sven_bis", Entities:FindByName(nil, "choose_sven_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		sven:SetAngles(0, 90, 0)

		-- Outer South
		local nevermore = CreateUnitByName("npc_dota_hero_nevermore_bis", Entities:FindByName(nil, "choose_nevermore_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		nevermore:SetAngles(0, 270, 0)

		local brewmaster = CreateUnitByName("npc_dota_hero_brewmaster_bis", Entities:FindByName(nil, "choose_brewmaster_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		brewmaster:SetAngles(0, 270, 0)

		local warlock = CreateUnitByName("npc_dota_hero_warlock_bis", Entities:FindByName(nil, "choose_warlock_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		warlock:SetAngles(0, 270, 0)

		for _,hero in pairs(heroes) do
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), brewmaster)
			end
		end
	end)

	Timers:CreateTimer(17, function()
		-- Special Events
		local frost_infernal = CreateUnitByName("npc_frost_infernal_bis", Entities:FindByName(nil, "frost_infernal_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		frost_infernal:SetAngles(0, 270, 0)

		-- VIP Hero
		local slardar = CreateUnitByName("npc_dota_hero_slardar_bis", Entities:FindByName(nil, "choose_slardar_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		slardar:SetAngles(0, 270, 0)

		for _,hero in pairs(heroes) do
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil)
			end
		end
	end)
end

function SpawnTeleporterGoodGuys(keys)
local activator = keys.activator
local point = Entities:FindByName(nil,"point_teleport_choose_hero"):GetAbsOrigin()

	for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
		if PlayerResource:IsValidPlayer(playerID) and activator:GetUnitName() == "npc_dota_hero_wisp" then
			PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),activator)
			FindClearSpaceForUnit(activator, point, true)
--			Timers:CreateTimer(0.5, function()
--				PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),nil)
--			end)
		end
	end
end

function choose_slardar(keys)
local activator = keys.activator
local point = Entities:FindByName(nil,"base_spawn"):GetAbsOrigin()
local msg = "This hero is only for <font color='#FF0000'>VIP Members!</font> Please choose another hero."

	for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
--		if PlayerResource:IsValidPlayer(playerID) and activator:GetUnitName() == "npc_dota_hero_wisp" and (PlayerResource:GetSteamAccountID(playerID)) == 54896080 or (PlayerResource:GetSteamAccountID(playerID)) == 295458357 or (PlayerResource:GetSteamAccountID(playerID)) == 61711140 or (PlayerResource:GetSteamAccountID(playerID)) == 206464009 then -- Cookies + X Hero Siege + Mugiwara +  beast SteamID64
		if PlayerResource:IsValidPlayer(playerID) and activator:GetUnitName() == "npc_dota_hero_wisp" and PlayerResource:GetSteamAccountID(activator:GetPlayerID()) == 54896080 or PlayerResource:GetSteamAccountID(activator:GetPlayerID()) == 295458357 or  PlayerResource:GetSteamAccountID(activator:GetPlayerID()) == 61711140 or  PlayerResource:GetSteamAccountID(activator:GetPlayerID()) == 206464009 then -- Cookies + X Hero Siege + Mugiwara +  beast SteamID64
			PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),activator)
			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),nil)
				FindClearSpaceForUnit(activator, point, true)
				PlayerResource:ReplaceHeroWith(activator:GetPlayerID(), "npc_dota_hero_slardar", STARTING_GOLD, 0)
			end)
		elseif PlayerResource:IsValidPlayer(playerID) and activator:GetUnitName() == "npc_dota_hero_wisp" then
			Notifications:Top(activator:GetPlayerOwnerID(),{text=msg, duration=5.0})
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

function FinalWave()
local heroes = HeroList:GetAllHeroes()
local point = Entities:FindByName(nil, "final_wave_player"):GetAbsOrigin()
local teleporters = Entities:FindAllByName("trigger_teleport")
local heroes = HeroList:GetAllHeroes()
local point_west_1 = Entities:FindByName(nil,"final_wave_west_1"):GetAbsOrigin()
local point_west_2 = Entities:FindByName(nil,"final_wave_west_2"):GetAbsOrigin()
local point_west_3 = Entities:FindByName(nil,"final_wave_west_3"):GetAbsOrigin()
local point_west_4 = Entities:FindByName(nil,"final_wave_west_4"):GetAbsOrigin()
local point_west_5 = Entities:FindByName(nil,"final_wave_west_5"):GetAbsOrigin()
local point_west_6 = Entities:FindByName(nil,"final_wave_west_6"):GetAbsOrigin()
local point_west_7 = Entities:FindByName(nil,"final_wave_west_7"):GetAbsOrigin()
local point_west_8 = Entities:FindByName(nil,"final_wave_west_8"):GetAbsOrigin()
local point_west_9 = Entities:FindByName(nil,"final_wave_west_9"):GetAbsOrigin()
local point_west_10 = Entities:FindByName(nil,"final_wave_west_10"):GetAbsOrigin()
local point_west_11 = Entities:FindByName(nil,"final_wave_west_11"):GetAbsOrigin()
local point_west_12 = Entities:FindByName(nil,"final_wave_west_12"):GetAbsOrigin()
local point_west_13 = Entities:FindByName(nil,"final_wave_west_13"):GetAbsOrigin()
local point_north_1 = Entities:FindByName(nil,"final_wave_north_1"):GetAbsOrigin()
local point_north_2 = Entities:FindByName(nil,"final_wave_north_2"):GetAbsOrigin()
local point_north_3 = Entities:FindByName(nil,"final_wave_north_3"):GetAbsOrigin()
local point_north_4 = Entities:FindByName(nil,"final_wave_north_4"):GetAbsOrigin()
local point_north_5 = Entities:FindByName(nil,"final_wave_north_5"):GetAbsOrigin()
local point_north_6 = Entities:FindByName(nil,"final_wave_north_6"):GetAbsOrigin()
local point_north_7 = Entities:FindByName(nil,"final_wave_north_7"):GetAbsOrigin()
local point_north_8 = Entities:FindByName(nil,"final_wave_north_8"):GetAbsOrigin()
local point_north_9 = Entities:FindByName(nil,"final_wave_north_9"):GetAbsOrigin()
local point_north_10 = Entities:FindByName(nil,"final_wave_north_10"):GetAbsOrigin()
local point_north_11 = Entities:FindByName(nil,"final_wave_north_11"):GetAbsOrigin()
local point_north_12 = Entities:FindByName(nil,"final_wave_north_12"):GetAbsOrigin()
local point_north_13 = Entities:FindByName(nil,"final_wave_north_13"):GetAbsOrigin()
local point_east_1 = Entities:FindByName(nil,"final_wave_east_1"):GetAbsOrigin()
local point_east_2 = Entities:FindByName(nil,"final_wave_east_2"):GetAbsOrigin()
local point_east_3 = Entities:FindByName(nil,"final_wave_east_3"):GetAbsOrigin()
local point_east_4 = Entities:FindByName(nil,"final_wave_east_4"):GetAbsOrigin()
local point_east_5 = Entities:FindByName(nil,"final_wave_east_5"):GetAbsOrigin()
local point_east_6 = Entities:FindByName(nil,"final_wave_east_6"):GetAbsOrigin()
local point_east_7 = Entities:FindByName(nil,"final_wave_east_7"):GetAbsOrigin()
local point_east_8 = Entities:FindByName(nil,"final_wave_east_8"):GetAbsOrigin()
local point_east_9 = Entities:FindByName(nil,"final_wave_east_9"):GetAbsOrigin()
local point_east_10 = Entities:FindByName(nil,"final_wave_east_10"):GetAbsOrigin()
local point_east_11 = Entities:FindByName(nil,"final_wave_east_11"):GetAbsOrigin()
local point_east_12 = Entities:FindByName(nil,"final_wave_east_12"):GetAbsOrigin()
local point_east_13 = Entities:FindByName(nil,"final_wave_east_13"):GetAbsOrigin()
local point_south_1 = Entities:FindByName(nil,"final_wave_south_1"):GetAbsOrigin()
local point_south_2 = Entities:FindByName(nil,"final_wave_south_2"):GetAbsOrigin()
local point_south_3 = Entities:FindByName(nil,"final_wave_south_3"):GetAbsOrigin()
local point_south_4 = Entities:FindByName(nil,"final_wave_south_4"):GetAbsOrigin()
local point_south_5 = Entities:FindByName(nil,"final_wave_south_5"):GetAbsOrigin()
local point_south_6 = Entities:FindByName(nil,"final_wave_south_6"):GetAbsOrigin()
local point_south_7 = Entities:FindByName(nil,"final_wave_south_7"):GetAbsOrigin()
local point_south_8 = Entities:FindByName(nil,"final_wave_south_8"):GetAbsOrigin()
local point_south_9 = Entities:FindByName(nil,"final_wave_south_9"):GetAbsOrigin()
local point_south_10 = Entities:FindByName(nil,"final_wave_south_10"):GetAbsOrigin()
local point_south_11 = Entities:FindByName(nil,"final_wave_south_11"):GetAbsOrigin()
local point_south_12 = Entities:FindByName(nil,"final_wave_south_12"):GetAbsOrigin()
local point_south_13 = Entities:FindByName(nil,"final_wave_south_13"):GetAbsOrigin()

	for _,v in pairs(teleporters) do
		DebugPrint("enable teleport trigger")
		v:Enable()
	end

	Timers:CreateTimer(10, function()
		local unit1 = CreateUnitByName("npc_abomination_final_wave", point_west_1, true, nil, nil, DOTA_TEAM_BADGUYS)
		local unit2 = CreateUnitByName("npc_abomination_final_wave", point_west_2, true, nil, nil, DOTA_TEAM_BADGUYS)
		local unit3 = CreateUnitByName("npc_abomination_final_wave", point_west_3, true, nil, nil, DOTA_TEAM_BADGUYS)

		local unit4 = CreateUnitByName("npc_banshee_final_wave", point_west_4, true, nil, nil, DOTA_TEAM_BADGUYS)
		local unit5 = CreateUnitByName("npc_banshee_final_wave", point_west_5, true, nil, nil, DOTA_TEAM_BADGUYS)
		local unit6 = CreateUnitByName("npc_banshee_final_wave", point_west_6, true, nil, nil, DOTA_TEAM_BADGUYS)

		local unit7 = CreateUnitByName("npc_necro_final_wave", point_west_7, true, nil, nil, DOTA_TEAM_BADGUYS)
		local unit8 = CreateUnitByName("npc_necro_final_wave", point_west_8, true, nil, nil, DOTA_TEAM_BADGUYS)
		local unit9 = CreateUnitByName("npc_necro_final_wave", point_west_9, true, nil, nil, DOTA_TEAM_BADGUYS)

		local unit10 = CreateUnitByName("npc_magnataur_final_wave", point_west_10, true, nil, nil, DOTA_TEAM_BADGUYS)
		local unit11 = CreateUnitByName("npc_magnataur_final_wave", point_west_11, true, nil, nil, DOTA_TEAM_BADGUYS)
		local unit12 = CreateUnitByName("npc_magnataur_final_wave", point_west_12, true, nil, nil, DOTA_TEAM_BADGUYS)

		local unit13 = CreateUnitByName("npc_dota_hero_balanar_final_wave", point_west_13, true, nil, nil, DOTA_TEAM_BADGUYS)

		local units = FindUnitsInRadius( DOTA_TEAM_BADGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE , FIND_ANY_ORDER, false )
		for _,v in pairs(units) do
			if v:IsCreature() and v:HasMovementCapability() then
				v:AddNewModifier(nil, nil, "modifier_stunned", {duration= 25, IsHidden = true})
				v:AddNewModifier(nil, nil, "modifier_invulnerable", {duration= 25, IsHidden = true})
			end
		end
	
		for _,hero in pairs(heroes) do
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), unit13)
			end
		end
	end)

	Timers:CreateTimer(15, function()
		local unit1 = CreateUnitByName("npc_tauren_final_wave", point_north_1, true, nil, nil, DOTA_TEAM_BADGUYS)
		unit1:SetAngles(0, 270, 0)
		local unit2 = CreateUnitByName("npc_tauren_final_wave", point_north_2, true, nil, nil, DOTA_TEAM_BADGUYS)
		unit2:SetAngles(0, 270, 0)
		local unit3 = CreateUnitByName("npc_tauren_final_wave", point_north_3, true, nil, nil, DOTA_TEAM_BADGUYS)
		unit3:SetAngles(0, 270, 0)
		local unit4 = CreateUnitByName("npc_chaos_orc_final_wave", point_north_4, true, nil, nil, DOTA_TEAM_BADGUYS)
		unit4:SetAngles(0, 270, 0)
		local unit5 = CreateUnitByName("npc_chaos_orc_final_wave", point_north_5, true, nil, nil, DOTA_TEAM_BADGUYS)
		unit5:SetAngles(0, 270, 0)
		local unit6 = CreateUnitByName("npc_chaos_orc_final_wave", point_north_6, true, nil, nil, DOTA_TEAM_BADGUYS)
		unit6:SetAngles(0, 270, 0)
		local unit7 = CreateUnitByName("npc_warlock_final_wave", point_north_7, true, nil, nil, DOTA_TEAM_BADGUYS)
		unit7:SetAngles(0, 270, 0)
		local unit8 = CreateUnitByName("npc_warlock_final_wave", point_north_8, true, nil, nil, DOTA_TEAM_BADGUYS)
		unit8:SetAngles(0, 270, 0)
		local unit9 = CreateUnitByName("npc_warlock_final_wave", point_north_9, true, nil, nil, DOTA_TEAM_BADGUYS)
		unit9:SetAngles(0, 270, 0)
		local unit10 = CreateUnitByName("npc_orc_raider_final_wave", point_north_10, true, nil, nil, DOTA_TEAM_BADGUYS)
		unit10:SetAngles(0, 270, 0)
		local unit11 = CreateUnitByName("npc_orc_raider_final_wave", point_north_11, true, nil, nil, DOTA_TEAM_BADGUYS)
		unit11:SetAngles(0, 270, 0)
		local unit12 = CreateUnitByName("npc_orc_raider_final_wave", point_north_12, true, nil, nil, DOTA_TEAM_BADGUYS)
		unit12:SetAngles(0, 270, 0)
		local unit13 = CreateUnitByName("npc_dota_hero_grom_hellscream_final_wave", point_north_13, true, nil, nil, DOTA_TEAM_BADGUYS)
		unit13:SetAngles(0, 270, 0)
	
		local units = FindUnitsInRadius( DOTA_TEAM_BADGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE , FIND_ANY_ORDER, false )
		for _,v in pairs(units) do
			if v:IsCreature() and v:HasMovementCapability() then
				v:AddNewModifier(nil, nil, "modifier_stunned", {duration= 20, IsHidden = true})
				v:AddNewModifier(nil, nil, "modifier_invulnerable", {duration= 20, IsHidden = true})
			end
		end
	
		for _,hero in pairs(heroes) do
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), unit13)
			end
		end
	end)

	Timers:CreateTimer(20, function()
		local unit1 = CreateUnitByName("npc_druid_final_wave", point_east_1, true, nil, nil, DOTA_TEAM_BADGUYS)
		unit1:SetAngles(0, 180, 0)
		local unit2 = CreateUnitByName("npc_druid_final_wave", point_east_2, true, nil, nil, DOTA_TEAM_BADGUYS)
		unit2:SetAngles(0, 180, 0)
		local unit3 = CreateUnitByName("npc_druid_final_wave", point_east_3, true, nil, nil, DOTA_TEAM_BADGUYS)
		unit3:SetAngles(0, 180, 0)
		local unit4 = CreateUnitByName("npc_guard_final_wave", point_east_4, true, nil, nil, DOTA_TEAM_BADGUYS)
		unit4:SetAngles(0, 180, 0)
		local unit5 = CreateUnitByName("npc_guard_final_wave", point_east_5, true, nil, nil, DOTA_TEAM_BADGUYS)
		unit5:SetAngles(0, 180, 0)
		local unit6 = CreateUnitByName("npc_guard_final_wave", point_east_6, true, nil, nil, DOTA_TEAM_BADGUYS)
		unit6:SetAngles(0, 180, 0)
		local unit7 = CreateUnitByName("npc_keeper_final_wave", point_east_7, true, nil, nil, DOTA_TEAM_BADGUYS)
		unit7:SetAngles(0, 180, 0)
		local unit8 = CreateUnitByName("npc_keeper_final_wave", point_east_8, true, nil, nil, DOTA_TEAM_BADGUYS)
		unit8:SetAngles(0, 180, 0)
		local unit9 = CreateUnitByName("npc_keeper_final_wave", point_east_9, true, nil, nil, DOTA_TEAM_BADGUYS)
		unit9:SetAngles(0, 180, 0)
		local unit10 = CreateUnitByName("npc_luna_final_wave", point_east_10, true, nil, nil, DOTA_TEAM_BADGUYS)
		unit10:SetAngles(0, 180, 0)
		local unit11 = CreateUnitByName("npc_luna_final_wave", point_east_11, true, nil, nil, DOTA_TEAM_BADGUYS)
		unit11:SetAngles(0, 180, 0)
		local unit12 = CreateUnitByName("npc_luna_final_wave", point_east_12, true, nil, nil, DOTA_TEAM_BADGUYS)
		unit12:SetAngles(0, 180, 0)
		local unit13 = CreateUnitByName("npc_dota_hero_illidan_final_wave", point_east_13, true, nil, nil, DOTA_TEAM_BADGUYS)
		unit13:SetAngles(0, 180, 0)

		local units = FindUnitsInRadius( DOTA_TEAM_BADGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE , FIND_ANY_ORDER, false )
		for _,v in pairs(units) do
			if v:IsCreature() and v:HasMovementCapability() then
				v:AddNewModifier(nil, nil, "modifier_stunned", {duration= 15, IsHidden = true})
				v:AddNewModifier(nil, nil, "modifier_invulnerable", {duration= 15, IsHidden = true})
			end
		end

		for _,hero in pairs(heroes) do
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), unit13)
			end
		end
	end)

	Timers:CreateTimer(25, function()
		local unit1 = CreateUnitByName("npc_captain_final_wave", point_south_1, true, nil, nil, DOTA_TEAM_BADGUYS)
		unit1:SetAngles(0, 90, 0)
		local unit2 = CreateUnitByName("npc_captain_final_wave", point_south_2, true, nil, nil, DOTA_TEAM_BADGUYS)
		unit2:SetAngles(0, 90, 0)
		local unit3 = CreateUnitByName("npc_captain_final_wave", point_south_3, true, nil, nil, DOTA_TEAM_BADGUYS)
		unit3:SetAngles(0, 90, 0)
		local unit4 = CreateUnitByName("npc_marine_final_wave", point_south_4, true, nil, nil, DOTA_TEAM_BADGUYS)
		unit4:SetAngles(0, 90, 0)
		local unit5 = CreateUnitByName("npc_marine_final_wave", point_south_5, true, nil, nil, DOTA_TEAM_BADGUYS)
		unit5:SetAngles(0, 90, 0)
		local unit6 = CreateUnitByName("npc_marine_final_wave", point_south_6, true, nil, nil, DOTA_TEAM_BADGUYS)
		unit6:SetAngles(0, 90, 0)
		local unit7 = CreateUnitByName("npc_marine_final_wave", point_south_7, true, nil, nil, DOTA_TEAM_BADGUYS)
		unit7:SetAngles(0, 90, 0)
		local unit8 = CreateUnitByName("npc_marine_final_wave", point_south_8, true, nil, nil, DOTA_TEAM_BADGUYS)
		unit8:SetAngles(0, 90, 0)
		local unit9 = CreateUnitByName("npc_marine_final_wave", point_south_9, true, nil, nil, DOTA_TEAM_BADGUYS)
		unit9:SetAngles(0, 90, 0)
		local unit10 = CreateUnitByName("npc_knight_final_wave", point_south_10, true, nil, nil, DOTA_TEAM_BADGUYS)
		unit10:SetAngles(0, 90, 0)
		local unit11 = CreateUnitByName("npc_knight_final_wave", point_south_11, true, nil, nil, DOTA_TEAM_BADGUYS)
		unit11:SetAngles(0, 90, 0)
		local unit12 = CreateUnitByName("npc_knight_final_wave", point_south_12, true, nil, nil, DOTA_TEAM_BADGUYS)
		unit12:SetAngles(0, 90, 0)
		local unit13 = CreateUnitByName("npc_dota_hero_proudmoore_final_wave", point_south_13, true, nil, nil, DOTA_TEAM_BADGUYS)
		unit13:SetAngles(0, 90, 0)

		local units = FindUnitsInRadius( DOTA_TEAM_BADGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE , FIND_ANY_ORDER, false )
		for _,v in pairs(units) do
			if v:IsCreature() and v:HasMovementCapability() then
				v:AddNewModifier(nil, nil, "modifier_stunned", {duration= 10, IsHidden = true})
				v:AddNewModifier(nil, nil, "modifier_invulnerable", {duration= 10, IsHidden = true})
			end
		end

		for _,hero in pairs(heroes) do
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), unit13)
			end
		end
	end)

	for _,hero in pairs(heroes) do
		if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
			FindClearSpaceForUnit(hero, point, true)
			hero:AddNewModifier(nil, nil, "modifier_animation_freeze_stun", {duration= 30, IsHidden = true})
			hero:AddNewModifier(nil, nil, "modifier_invulnerable", {duration= 25, IsHidden = true})
			PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
		end

		Timers:CreateTimer(30, function()
			PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil)
		end)
	end
end

function EndMuradinEvent(keys)
	local caller = keys.caller
	local activator = keys.activator
	local point = Entities:FindByName(nil,"base_spawn"):GetAbsOrigin()

	if activator:GetTeam() == DOTA_TEAM_GOODGUYS then
	FindClearSpaceForUnit(activator, point, true)
	activator:Stop()
	PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
	PlayerResource:ModifyGold( activator:GetPlayerOwnerID(), 10000, false,  DOTA_ModifyGold_Unspecified )
	Timers:CreateTimer(0.1, function()
		PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil)
	end)
	end
end

function teleport_to_top(keys)
DebugPrint("Entering Magtheridon")
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
