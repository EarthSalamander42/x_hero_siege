_G.nCOUNTDOWNTIMER = 0
_G.nCOUNTDOWNCREEP = 0
_G.nCOUNTDOWNINCWAVE = 0
_G.nCOUNTDOWNEVENT = 0
_G.BT_ENABLED = 1
_G.NEUTRAL_SPAWN = 0
_G.RAMERO = 0
_G.MAGTHERIDON = 0
_G.FOUR_BOSSES = 0
_G.SPIRIT_MASTER = 0
_G.ANKHS = 1
_G.SPECIAL_EVENT = 0
_G.PlayerNumberRadiant = 0
_G.PlayerNumberDire = 0
_G.sword_first_time = true
_G.ring_first_time = true
_G.X_HERO_SIEGE_V = 3.35

_G.mod_creator = {
		54896080,	-- Cookies
		295458357	-- X Hero Siege
	}

_G.captain_baumi = {
		43305444,	-- Baumi( Because why not? )
		44022861	-- Padaa
	}

_G.mod_graphist = {
		61711140,	-- Mugiwara
		56352263,	-- Flotos
		231117589	-- Xero
	}

_G.vip_members = {
		320774890,	-- Error [Han Gao on Patreon, Remove Date if not paid: 26/01/2017]
		97490223,	-- IllidanStormrage [Lucas Diao on Patreon, Removed Date if not paid: 29/01/2017]
		44364795,	-- Lyzer93 [Balraj McCoy on Patreon, Removed Date if not paid: 10/02/2017]
		46744186,	-- Captain Darian Frey [CaptainDarianFrey on Patreon, Removed Date if not paid: 10/02/2017]
		3180772,	-- Yoshi [Fabian Rothmund on Patreon, Removed Date if not paid: 15/02/2017]
		54935523	-- The Patriarchy [Kevin Moore on Patreon, Removed Date if not paid: 17/02/2017]
	}

_G.golden_vip_members = {
		69533529,	-- West [Unlimited]
		51728279,	-- mC [Unlimited]
		206464009,	-- beast [Unlimited]
		86718505,	-- Noya [Unlimited]
		62993541,	-- KennyCrazy [Unlimited]
		117327434,	-- Eren [Unlimited]
		146805680,	-- [UTAC] Rekail [Gatiipz Gatiipz on Patreon, Remove Date if not paid: 01/01/2017]
		110786327,	-- MechJesus [Mauro Solares on Patreon, Remove Date if not paid: 07/01/2017]
		93860661,	-- Meteor [Supawit Enyord on Patreon, Remove Date if not paid: 10/01/2017]
		97629656,	-- jacobkahnji  [Jacob A Yow on Patreon, Remove Date if not paid: 23/01/2017]
		136258650,	-- Meliodas [Dinh Quang on Patreon, Remove Date if not paid: 25/01/2017]
		55770641,	-- Primeape [Filip Dingum on Patreon, Remove Date if not paid: 31/01/2017]
		5194446,	-- Botd [Hugo Marques on Patreon, Remove Date if not paid: 31/01/2017]
		27954291,	-- Gengar [Christian Oversand Deildok on Patreon, Remove Date if not paid: 04/01/2017]
		80192910,	-- Cheshire [Nathan Perscott on Patreon, Removed Date if not paid: 29/01/2017]
		28261641,	-- Timoznn [Timo Nurnberg on Patreon, Unlimited]
		79258147,	-- Dyuss [Altynbek Duisenkul on Patreon, Removed Date if not paid: 10/02/2017]
		66147815,	-- FreshKiller23 [Unlimited]
		33042578	-- ryusajin [Unlimited]
	}

_G.banned_players = {
		151018319 -- Mohammad Mehdi Akhondi
	}

PLAYER_COLORS = {}	-- Stores individual player colors
PLAYER_COLORS[0] = { 200, 0, 0 } --Red
PLAYER_COLORS[1] = { 0, 50, 200 } --Blue
PLAYER_COLORS[2] = { 0, 255, 255 } --Cyan
PLAYER_COLORS[3] = { 100, 0, 100 } --Purple
PLAYER_COLORS[4] = { 255, 255, 0 } --Yellow
PLAYER_COLORS[5] = { 255, 150, 0 } --Orange
PLAYER_COLORS[6] = { 50, 255, 50 } --Green
PLAYER_COLORS[7] = { 255, 100, 255 } --Pink

CREEP_LANES = {}	-- Stores individual creep lanes
CREEP_LANES[1] = 0
CREEP_LANES[2] = 0
CREEP_LANES[3] = 0
CREEP_LANES[4] = 0
CREEP_LANES[5] = 0
CREEP_LANES[6] = 0
CREEP_LANES[7] = 0
CREEP_LANES[8] = 0

BARRACKMENTS = {}	-- Stores individual barrackments
BARRACKMENTS[1] = 1
BARRACKMENTS[2] = 1
BARRACKMENTS[3] = 1
BARRACKMENTS[4] = 1
BARRACKMENTS[5] = 1
BARRACKMENTS[6] = 1
BARRACKMENTS[7] = 1
BARRACKMENTS[8] = 1

HEROLIST = {}
HEROLIST[1] = "enchantress"			-- Dryad
HEROLIST[2] = "crystal_maiden"		-- Archmage
HEROLIST[3] = "luna"				-- Huntress
HEROLIST[4] = "beastmaster"			-- Beastmaster
HEROLIST[5] = "pugna"				-- Dread Lord
HEROLIST[6] = "lich"				-- Lich
HEROLIST[7] = "nyx_assassin"		-- Crypt Lord
HEROLIST[8] = "abyssal_underlord"	-- Pit Lord
HEROLIST[9] = "terrorblade"			-- Demon Hunter
HEROLIST[10] = "phantom_assassin"	-- Warden
HEROLIST[11] = "elder_titan"		-- Tauren Chieftain
HEROLIST[12] = "mirana"				-- Priestess of the Moon
HEROLIST[13] = "dragon_knight"		-- Arthas
HEROLIST[14] = "windrunner"			-- Sylvanas Windrunner
HEROLIST[15] = "invoker"			-- Blood Mage
HEROLIST[16] = "sniper"				-- Rifleman
HEROLIST[17] = "shadow_shaman"		-- Shadow Hunter
HEROLIST[18] = "juggernaut"			-- Blademaster
HEROLIST[19] = "omniknight"			-- Paladin
HEROLIST[20] = "rattletrap"			-- Space Marine
HEROLIST[21] = "chen"				-- Archimage
HEROLIST[22] = "lina"				-- Sorceress
HEROLIST[23] = "sven"				-- Mountain King
HEROLIST[24] = "ursa"				-- Malfurion
HEROLIST[25] = "nevermore"			-- Banehallow
HEROLIST[26] = "brewmaster"			-- Pandaren Brewmaster
HEROLIST[27] = "warlock"			-- Archimonde
HEROLIST[28] = "monkey_king"		-- Dota 2 Hero [Axe, Monkey King]

HEROLIST_ALT = {}
HEROLIST_ALT[1] = enchantress		-- Dryad
HEROLIST_ALT[2] = crystal_maiden	-- Archmage
HEROLIST_ALT[3] = luna				-- Huntress
HEROLIST_ALT[4] = beastmaster		-- Beastmaster
HEROLIST_ALT[5] = pugna				-- Dread Lord
HEROLIST_ALT[6] = lich				-- Lich
HEROLIST_ALT[7] = nyx_assassin		-- Crypt Lord
HEROLIST_ALT[8] = abyssal_underlord	-- Pit Lord
HEROLIST_ALT[9] = terrorblade		-- Demon Hunter
HEROLIST_ALT[10] = phantom_assassin	-- Warden
HEROLIST_ALT[11] = elder_titan		-- Tauren Chieftain
HEROLIST_ALT[12] = mirana			-- Priestess of the Moon
HEROLIST_ALT[13] = dragon_knight	-- Arthas
HEROLIST_ALT[14] = windrunner		-- Sylvanas Windrunner
HEROLIST_ALT[15] = invoker			-- Blood Mage
HEROLIST_ALT[16] = sniper			-- Rifleman
HEROLIST_ALT[17] = shadow_shaman	-- Shadow Hunter
HEROLIST_ALT[18] = juggernaut		-- Blademaster
HEROLIST_ALT[19] = omniknight		-- Paladin
HEROLIST_ALT[20] = rattletrap		-- Space Marine
HEROLIST_ALT[21] = chen				-- Archimage
HEROLIST_ALT[22] = lina				-- Sorceress
HEROLIST_ALT[23] = sven				-- Mountain King
HEROLIST_ALT[24] = ursa				-- Malfurion
HEROLIST_ALT[25] = nevermore		-- Banehallow
HEROLIST_ALT[26] = brewmaster		-- Pandaren Brewmaster
HEROLIST_ALT[27] = warlock			-- Archimonde
HEROLIST_ALT[28] = monkey_king		-- Dota 2 Hero [Axe, Monkey King]

HEROLIST_VIP = {}
HEROLIST_VIP[1] = "slardar"				-- Centurion
HEROLIST_VIP[2] = "skeleton_king"		-- Lich King
HEROLIST_VIP[3] = "meepo"				-- Kobold Knight
HEROLIST_VIP[4] = "chaos_knight"		-- Dark Fundamental
HEROLIST_VIP[5] = "tiny"				-- Stone Giant
HEROLIST_VIP[6] = "sand_king"			-- Desert Wyrm
HEROLIST_VIP[7] = "necrolyte"			-- Dark Summoner

HEROLIST_VIP_ALT = {}
HEROLIST_VIP_ALT[1] = slardar			-- Centurion
HEROLIST_VIP_ALT[2] = skeleton_king		-- Lich King
HEROLIST_VIP_ALT[3] = meepo				-- Kobold Knight
HEROLIST_VIP_ALT[4] = chaos_knight		-- Dark Fundamental
HEROLIST_VIP_ALT[5] = tiny				-- Stone Giant
HEROLIST_VIP_ALT[6] = sand_king			-- Desert Wyrm
HEROLIST_VIP_ALT[7] = necrolyte			-- Dark Summoner

timers = {}

if GameMode == nil then
	_G.GameMode = class({})
end

require('events')
require('internal/gamemode')
require('internal/events')
require('libraries/timers')
require('libraries/physics')
require('libraries/projectiles')
require('libraries/notifications')
require('libraries/animations')
require('libraries/attachments')
require('libraries/keyvalues')
require('phases/choose_hero')
require('phases/creeps')
require('phases/special_events')
require('phases/phase1')
require('phases/phase2')
require('phases/phase3')

function GameMode:OnFirstPlayerLoaded()

end

function FrostTowersToFinalWave()
	if GameMode.FrostTowers_killed >= 2 then
		nCOUNTDOWNTIMER = 60
		nCOUNTDOWNCREEP = 1
		nCOUNTDOWNEVENT = 1
	end
end

function SpecialEventsTimer()
	nCOUNTDOWNEVENT = 121
end

function SpecialEventsTimerEnd()
	nCOUNTDOWNEVENT = 1
end

function GameMode:OnAllPlayersLoaded()
GameMode.FrostInfernal_killed = 0
GameMode.SpiritBeast_killed = 0
GameMode.FrostTowers_killed = 0
GameMode.BossesTop_killed = 0
time_elapsed = 0

	for playerID = 0, DOTA_MAX_TEAM_PLAYERS -1 do
		if PlayerResource:IsValidPlayer(playerID) then
			PlayerResource:SetCustomPlayerColor( playerID, PLAYER_COLORS[playerID][1], PLAYER_COLORS[playerID][2], PLAYER_COLORS[playerID][3])
		end
	end

	if PlayerResource:GetPlayerCount() >= 1 then
		CREEP_LANES[1] = 1
	end
	if PlayerResource:GetPlayerCount() >= 2 then
		CREEP_LANES[2] = 1
	end
	if PlayerResource:GetPlayerCount() >= 3 then
		CREEP_LANES[3] = 1
	end
	if PlayerResource:GetPlayerCount() >= 4 then
		CREEP_LANES[4] = 1
	end
	if PlayerResource:GetPlayerCount() >= 5 then
		CREEP_LANES[5] = 1
	end
	if PlayerResource:GetPlayerCount() >= 6 then
		CREEP_LANES[6] = 1
	end
	if PlayerResource:GetPlayerCount() >= 7 then
		CREEP_LANES[7] = 1
	end
	if PlayerResource:GetPlayerCount() >= 8 then
		CREEP_LANES[8] = 1
	end

	Timers:CreateTimer(3.0, function()
		EmitGlobalSound("Global.InGame")
	end)

	GameRules:GetGameModeEntity():SetItemAddedToInventoryFilter( Dynamic_Wrap(GameMode, "ItemAddedFilter"), self )
end

function GameMode:OnHeroInGame(hero)
	if hero:GetUnitName() == "npc_dota_hero_wisp" then
		hero:SetAbilityPoints(0)
		hero:SetGold(0, false)
		hero:AddNewModifier(nil, nil, "modifier_boss_stun", {Duration = 20, IsHidden = true})
	end
end

function GameMode:OnGameInProgress()
local difficulty = GameRules:GetCustomGameDifficulty()
local triggers_choice = Entities:FindAllByName("trigger_special_event_choice")
local triggers_hero_image = Entities:FindAllByName("trigger_special_event_hero_image")
local triggers_spirit_beast = Entities:FindAllByName("trigger_special_event_spirit_beast")
local triggers_frost_infernal = Entities:FindAllByName("trigger_special_event_frost_infernal")

	-- Timer: Creep Levels 1 to 6. Lanes 1 to 8.
	Timers:CreateTimer(0, function()
--		print(time_elapsed)
		time_elapsed = time_elapsed + 30
		SpawnCreeps()
	return 30
	end)

--	EmitGlobalSound("Global.HumanMusic1") -- Lasts 4:33

	-- Timer: Creeps Levels 2, 3, 4, 5, 6 Whispering
	Timers:CreateTimer(360, function() -- 6 Min
		Notifications:TopToAll({hero="npc_dota_hero_undying", duration=6.0})
		Notifications:TopToAll({text="Creeps are now Level 2!", style={color="green"}, continue=true})
		SpawnRedDragon()
	end)
	Timers:CreateTimer(840, function() -- 12 Min + 2 Min with Muradin Event = 14 Min
		Notifications:TopToAll({hero="npc_dota_hero_nyx_assassin", duration=6.0})
		Notifications:TopToAll({text="Creeps are now Level 3! ", style={color="DodgerBlue"}, continue=true})
		Notifications:TopToAll({text="Special Events are unlocked!", style={color="DodgerBlue"}, continue=true})
		nCOUNTDOWNCREEP = 361
		nCOUNTDOWNINCWAVE = 241
		SpawnBlackDragon()
		for _,v in pairs(triggers_choice) do
			v:Enable()
		end
		for _,v in pairs(triggers_hero_image) do
			v:Enable()
		end
		for _,v in pairs(triggers_spirit_beast) do
			v:Enable()
		end
		for _,v in pairs(triggers_frost_infernal) do
			v:Enable()
		end
	end)
	Timers:CreateTimer(1200, function() -- 18 Min + 2 Min with Muradin Event = 20 Min
		Notifications:TopToAll({hero="npc_dota_hero_doom_bringer", duration=6.0})
		Notifications:TopToAll({text="Creeps are now Level 4!", style={color="red"}, continue=true})
	end)
	Timers:CreateTimer(1800, function() -- 24 Min + 3 Min Farm Event + 1 Dummy Min = 30 Min
		Notifications:TopToAll({hero="npc_dota_hero_phantom_lancer", duration=6.0})
		Notifications:TopToAll({text="Creeps are now Level 5!", style={color="blue"}, continue=true})
	end)
	Timers:CreateTimer(2160, function() -- 36 Min
		Notifications:TopToAll({hero="npc_dota_hero_tiny", duration=6.0})
		Notifications:TopToAll({text="Creeps are now Level 6!", style={color="white"}, continue=true})
	end)

	-- Timer: West, North, East, South Event Whispering
	Timers:CreateTimer(211, function() -- 3 Min 30 sec
		Notifications:TopToAll({text="WARNING: Incoming wave of Darkness from the West!", duration=25.0, style={color="red"}})
		SpawnRunes()
	end)
	Timers:CreateTimer(451, function() -- 7 Min 30 sec
		Notifications:TopToAll({text="WARNING: Incoming wave of Darkness from the North!", duration=25.0, style={color="red"}})
		SpawnRunes()
	end)
	Timers:CreateTimer(691, function() -- 11 Min 30 sec
		Notifications:TopToAll({text="WARNING: Muradin Event in 30 sec!", duration=25.0, style={color="grey"}})
	end)
	Timers:CreateTimer(811, function() -- 13 Min 30 sec
		Notifications:TopToAll({text="WARNING: Incoming wave of Darkness from the East!", duration=25.0, style={color="red"}})
		SpawnRunes()
	end)
	Timers:CreateTimer(1051, function() -- 15 Min 30 sec
		Notifications:TopToAll({text="WARNING: Incoming wave of Darkness from the South!", duration=25.0, style={color="red"}})
		SpawnRunes()
	end)
	Timers:CreateTimer(1291, function() -- 19 Min 30 sec
		Notifications:TopToAll({text="WARNING: Incoming wave of Darkness from the West!", duration=25.0, style={color="red"}})
		SpawnRunes()
	end)
	Timers:CreateTimer(1411, function() -- 23 Min 30 sec
		Notifications:TopToAll({text="WARNING: Farming Event in 30 sec!", duration=25.0, style={color="grey"}})
	end)
	Timers:CreateTimer(1591, function() -- 24 Min 30 sec
		Notifications:TopToAll({text="WARNING: Incoming wave of Darkness from the North!", duration=25.0, style={color="red"}})
		SpawnRunes()
	end)
	Timers:CreateTimer(1831, function() -- 27 Min 30 sec
		Notifications:TopToAll({text="WARNING: Incoming wave of Darkness from the East!", duration=25.0, style={color="red"}})
		SpawnRunes()
	end)
	Timers:CreateTimer(2071, function() -- 31 Min 30 sec
		Notifications:TopToAll({text="WARNING: Incoming wave of Darkness from the South!", duration=25.0, style={color="red"}})
		SpawnRunes()
	end)
--	Timers:CreateTimer(2131, function() -- 35 Min 30 sec
--		Notifications:TopToAll({text="WARNING: Duel Event in 30 sec! (Ankhs will be disabled)", duration=25.0, style={color="red"}})
--		SpawnRunes()
--	end)

	--//=================================================================================================================
	--// Timer: West Event 1 Spawn
	--//=================================================================================================================
	Timers:CreateTimer(241, function() -- 4 Min: NECROLYTE WEST EVENT 1
	local point = Entities:FindByName( nil, "npc_dota_spawner_west_event"):GetAbsOrigin()
		for j = 1, 10 do
			local unit = CreateUnitByName("npc_dota_creature_necrolyte_event_1", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		end
	end)

	--//=================================================================================================================
	--// Timer: North Event 2 Spawn
	--//=================================================================================================================
	Timers:CreateTimer(481, function() -- 8 Min: NAGA SIREN NORTH EVENT 2
	local point = Entities:FindByName( nil, "npc_dota_spawner_north_event"):GetAbsOrigin()
		for j = 1, 10 do
			local unit = CreateUnitByName("npc_dota_creature_naga_siren_event_2", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		end
	end)

	--//=================================================================================================================
	--// Timer: East Event 3 Spawn
	--//=================================================================================================================
	Timers:CreateTimer(841, function() -- 12 Min: VENGEFUL SPIRIT SOUTH EVENT 3
	local point = Entities:FindByName( nil, "npc_dota_spawner_east_event"):GetAbsOrigin()
		for j = 1, 10 do
			local unit = CreateUnitByName("npc_dota_creature_vengeful_spirit_event_3", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		end
	end)

	--//=================================================================================================================
	--// Timer: South Event 4 Spawn
	--//=================================================================================================================
	Timers:CreateTimer(1081, function() -- 16 Min: CAPTAIN SOUTH EVENT 4
	local point = Entities:FindByName( nil, "npc_dota_spawner_south_event"):GetAbsOrigin()
		for j = 1, 10 do
			local unit = CreateUnitByName("npc_dota_creature_captain_event_4", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		end
	end)

	--//=================================================================================================================
	--// Timer: West Event 5 Spawn
	--//=================================================================================================================
	Timers:CreateTimer(1321, function() -- 20 Min: SLARDARS EVENT 5
	local point = Entities:FindByName( nil, "npc_dota_spawner_west_event"):GetAbsOrigin()
		for j = 1, 10 do
			local unit = CreateUnitByName("npc_dota_creature_slardar_event_5", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		end
	end)

	--//=================================================================================================================
	--// Timer: North Event 6 Spawn
	--//=================================================================================================================
	Timers:CreateTimer(1626, function() -- 25 Min: CHAOS KNIGHTS EVENT 6 - 1621
	local point = Entities:FindByName( nil, "npc_dota_spawner_north_event"):GetAbsOrigin()
		for j = 1, 10 do
			local unit = CreateUnitByName("npc_dota_creature_chaos_knight_event_6", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		end
	end)

	--//=================================================================================================================
	--// Timer: East Event 7 Spawn
	--//=================================================================================================================
	Timers:CreateTimer(1861, function() -- 29 Min: LUNA EVENT 7
	local point = Entities:FindByName( nil, "npc_dota_spawner_east_event"):GetAbsOrigin()
		for j = 1, 10 do
			local unit = CreateUnitByName("npc_dota_creature_luna_event_7", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		end
	end)

	--//=================================================================================================================
	--// Timer: South Event 8 Spawn
	--//=================================================================================================================
	Timers:CreateTimer(2101, function() -- 33 Min: CLOCKWERK EVENT 8
	local point = Entities:FindByName( nil, "npc_dota_spawner_south_event"):GetAbsOrigin()
		for j = 1, 10 do
			local unit = CreateUnitByName("npc_dota_creature_clockwerk_event_8", point, true, nil, nil, DOTA_TEAM_BADGUYS)
		end
	end)

	Timers:CreateTimer(716, function() -- 716 - 11:55 Min: MURADIN BRONZEBEARD EVENT 1
		PauseCreepsMuradin()
		PauseHeroes()
		RefreshPlayers()
		Timers:CreateTimer(5, function()
			MuradinEvent()
			Timers:CreateTimer(3, RestartHeroes())
		end)
	end)
	Timers:CreateTimer(1436, function() -- 1436 - 23:55 Min: FARM EVENT 2
		PauseCreepsFarm()
		PauseHeroes()
		RefreshPlayers()
		Timers:CreateTimer(5, function()
			FarmEvent()
			Timers:CreateTimer(3, RestartHeroes())
		end)
	end)

--	Timers:CreateTimer(6, function() -- 2156 - 35:55 Min: DUEL EVENT 3
--		KillCreeps()
--		PauseHeroes()
--		RefreshPlayers()
--		Timers:CreateTimer(5, function()
--			ANKHS = 0
--			SPECIAL_EVENT = 1
--			DuelEvent()
--			Timers:CreateTimer(3, RestartHeroes())
--		end)
--	end)
end

function RestartHeroes()
local heroes = HeroList:GetAllHeroes()

	for _,hero in pairs(heroes) do
		hero:RemoveModifierByName("modifier_animation_freeze_stun")
		hero:RemoveModifierByName("modifier_invulnerable")
	end
end

function PauseHeroes()
local heroes = HeroList:GetAllHeroes()

	for _,hero in pairs(heroes) do
		hero:AddNewModifier(nil, nil, "modifier_animation_freeze_stun", nil)
		hero:AddNewModifier(nil, nil, "modifier_invulnerable", nil)
	end
end

function KillCreeps()
local units = FindUnitsInRadius( DOTA_TEAM_BADGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE , FIND_ANY_ORDER, false )
local units2 = FindUnitsInRadius( DOTA_TEAM_GOODGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE , FIND_ANY_ORDER, false )

	for _,v in pairs(units) do
		if v:IsCreature() and v:HasMovementCapability() then
			UTIL_Remove(v)
		end
	end

	for _,v in pairs(units2) do
		if v:IsCreature() and v:HasMovementCapability() then
			UTIL_Remove(v)
		end
	end
end

function PauseCreepsCastle()
local units = FindUnitsInRadius( DOTA_TEAM_BADGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE , FIND_ANY_ORDER, false )
local units2 = FindUnitsInRadius( DOTA_TEAM_GOODGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE , FIND_ANY_ORDER, false )

	for _,v in pairs(units) do
		if v:IsCreature() and v:HasMovementCapability() then
			v:AddNewModifier(nil, nil, "modifier_animation_freeze_stun", {duration = 10.0})
			v:AddNewModifier(nil, nil, "modifier_invulnerable", {duration = 10.0})
		end
	end

	for _,v in pairs(units2) do
		if v:IsCreature() and v:HasMovementCapability() then
			v:AddNewModifier(nil, nil, "modifier_animation_freeze_stun", {duration = 10.0})
			v:AddNewModifier(nil, nil, "modifier_invulnerable", {duration = 10.0})
		end
	end
end

function PauseCreepsMuradin()
local units = FindUnitsInRadius( DOTA_TEAM_BADGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE , FIND_ANY_ORDER, false )
local units2 = FindUnitsInRadius( DOTA_TEAM_GOODGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE , FIND_ANY_ORDER, false )

	for _,v in pairs(units) do
		if v:IsCreature() and v:HasMovementCapability() then
			v:AddNewModifier(nil, nil, "modifier_animation_freeze_stun", {duration = 130.0})
			v:AddNewModifier(nil, nil, "modifier_invulnerable", {duration = 130.0})
		end
	end

	for _,v in pairs(units2) do
		if v:IsCreature() and v:HasMovementCapability() then
			v:AddNewModifier(nil, nil, "modifier_animation_freeze_stun", {duration = 130.0})
			v:AddNewModifier(nil, nil, "modifier_invulnerable", {duration = 130.0})
		end
	end
end

function PauseCreepsFarm()
local units = FindUnitsInRadius( DOTA_TEAM_BADGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE , FIND_ANY_ORDER, false )
local units2 = FindUnitsInRadius( DOTA_TEAM_GOODGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE , FIND_ANY_ORDER, false )

	for _,v in pairs(units) do
		if v:IsCreature() and v:HasMovementCapability() then
			v:AddNewModifier(nil, nil, "modifier_animation_freeze_stun", {duration = 190.0})
			v:AddNewModifier(nil, nil, "modifier_invulnerable", {duration = 190.0})
		end
	end

	for _,v in pairs(units2) do
		if v:IsCreature() and v:HasMovementCapability() then
			v:AddNewModifier(nil, nil, "modifier_animation_freeze_stun", {duration = 190.0})
			v:AddNewModifier(nil, nil, "modifier_invulnerable", {duration = 190.0})
		end
	end
end

	XP_PER_LEVEL_TABLE = {
	0,-- 1
	200,-- 2 +200
	500,-- 3 +300
	900,-- 4 +400
	1400,-- 5 +500
	2000,-- 6 +600
	2800,-- 7 +700
	3800,-- 8 +1000
	5000,-- 9 +1200
	6400,-- 10 +1400
	8200,-- 11 +1800
	10400,-- 12 +2200
	13000,-- 13 +2600
	16000,-- 14 + 3000
	19500,-- 15 + 3500
	23500,-- 16 + 4000
	28000,-- 17 + 4500
	33000,-- 18 + 5000
	38500,-- 19 + 5500
	44500, -- 20 + 6000
	50500, -- 21 + 6000
	56500, -- 22 + 6000
	62500, -- 23 + 6000
	68500, -- 24 + 6000
	74500, -- 25 + 6000
	80500, -- 26 + 6000
	86500, -- 27 + 6000
	92500, -- 28 + 6000
	100500, -- 29 + 6000
	106500 -- 30 + 6000
}

function GameMode:InitGameMode()
	GameMode = self
	mode = GameRules:GetGameModeEntity()

	-- Timer Rules
	GameRules:SetPreGameTime(120.0) --120.0
	GameRules:SetPostGameTime(30.0)
	GameRules:SetTreeRegrowTime(180.0)
	GameRules:SetHeroSelectionTime(0.0) --This is not dota bitch
	GameRules:SetGoldTickTime(0.0) --This is not dota bitch
	GameRules:SetGoldPerTick(0.0) --This is not dota bitch
	GameRules:SetCustomGameSetupAutoLaunchDelay(15.0) --Vote Time

	-- Boolean Rules
	GameRules:LockCustomGameSetupTeamAssignment(true)
--	GameRules:EnableCustomGameSetupAutoLaunch(true)
	GameRules:SetUseCustomHeroXPValues(true)
	GameRules:SetUseBaseGoldBountyOnHeroes(false)
	GameRules:SetHeroRespawnEnabled(true)
	mode:SetUseCustomHeroLevels(true)
	mode:SetRecommendedItemsDisabled(false)
	mode:SetTopBarTeamValuesOverride(true)
	mode:SetTopBarTeamValuesVisible(false)
	mode:SetUnseenFogOfWarEnabled(false)
	mode:SetStashPurchasingDisabled(true)

	mode:SetBuybackEnabled(false)
	mode:SetBotThinkingEnabled(false)
	mode:SetTowerBackdoorProtectionEnabled(false)
	mode:SetFogOfWarDisabled(false) --FUCK YOU VOLVO
	mode:SetGoldSoundDisabled(false)
	mode:SetRemoveIllusionsOnDeath(false)
	mode:SetAlwaysShowPlayerInventory(false)
	mode:SetAnnouncerDisabled(false)
	mode:SetLoseGoldOnDeath(false)

	-- Value Rules
	mode:SetCameraDistanceOverride(1250)
	mode:SetMaximumAttackSpeed(500)
	mode:SetMinimumAttackSpeed(20)
	mode:SetCustomHeroMaxLevel(30)
	GameRules:SetHeroMinimapIconScale(1.0)
	GameRules:SetCreepMinimapIconScale(1)
	GameRules:SetRuneMinimapIconScale(1)

	-- Team Rules
	SetTeamCustomHealthbarColor(DOTA_TEAM_GOODGUYS, 0, 64, 128) --Blue
	SetTeamCustomHealthbarColor(DOTA_TEAM_BADGUYS, 128, 32, 32) --Red
	SetTeamCustomHealthbarColor(DOTA_TEAM_CUSTOM_1, 255, 255, 0) --Yellow

	-- Table Rules
	mode:SetCustomXPRequiredToReachNextLevel( XP_PER_LEVEL_TABLE )

	GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS, 8)
	GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_BADGUYS, 0)
	GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_CUSTOM_1, 0)
	mode:SetCustomGameForceHero( "npc_dota_hero_wisp" )
	mode:SetFixedRespawnTime(40)

	-- Lua Modifiers
	LinkLuaModifier("modifier_earthquake_aura", "heroes/hero_brewmaster/earthquake", LUA_MODIFIER_MOTION_NONE)

	GameMode:_InitGameMode()
	self:OnFirstPlayerLoaded()

	GameRules:GetGameModeEntity():SetThink( "OnThink", self, 1 )

	self.countdownEnabled = false

	Convars:RegisterCommand( "test_spirit_master", function() return StartSpiritMasterArena() end, "Test Spirit Master Arena", FCVAR_CHEAT )
	mode:SetExecuteOrderFilter( Dynamic_Wrap( GameMode, "FilterExecuteOrder" ), self )
end				

function GameMode:OnGameRulesStateChange(keys)
local heroes = HeroList:GetAllHeroes()

	-- This internal handling is used to set up main barebones functions
	GameMode:_OnGameRulesStateChange(keys)

	local newState = GameRules:State_Get()

	if newState == DOTA_GAMERULES_STATE_HERO_SELECTION then
		GameRules:SetCustomGameDifficulty(2)
		local mode  = GameMode
		local votes = mode.VoteTable

		--[[
		-- Random tables for test purposes
		local testTable = {game_length = {}, combat_system = {}}
		local votes_a = {15, 20, 25, 30}
		local votes_b = {1, 2}
		for i = 0,9 do
		  testTable.game_length[i]  = votes_a[math.random(table.getn(votes_a))]
		  testTable.combat_system[i]  = votes_b[math.random(table.getn(votes_b))]
		end
		votes = testTable   
		]]

		for category, pidVoteTable in pairs(votes) do
	  
		  -- Tally the votes into a new table
			local voteCounts = {}
			for pid, vote in pairs(pidVoteTable) do
				if not voteCounts[vote] then voteCounts[vote] = 0 end
				voteCounts[vote] = voteCounts[vote] + 1
			end

		  --print(" ----- " .. category .. " ----- ")
		  --PrintTable(voteCounts)

		  -- Find the key that has the highest value (key=vote value, value=number of votes)
			local highest_vote = 0
			local highest_key = ""
			for k, v in pairs(voteCounts) do
				if v > highest_vote then
					highest_key = k
					highest_vote = v
				end
			end

			-- Check for a tie by counting how many values have the highest number of votes
			local tieTable = {}
			for k, v in pairs(voteCounts) do
				if v == highest_vote then
					table.insert(tieTable, k)
				end
			end

			-- Resolve a tie by selecting a random value from those with the highest votes
			if table.getn(tieTable) > 1 then
				--print("TIE!")
				highest_key = tieTable[math.random(table.getn(tieTable))]
			end
			-- Act on the winning vote
			if category == "difficulty" then
				GameRules:SetCustomGameDifficulty(highest_key)
			end

			print(category .. ": " .. highest_key)
		end
	end

	if newState == DOTA_GAMERULES_STATE_PRE_GAME then
		self._fPreGameStartTime = GameRules:GetGameTime()
		for _, hero in pairs(heroes) do
			if hero:IsRealHero() then
--			local ID = hero:GetPlayerID()
--			local Gold = hero:GetGold()
--				if ID == 0 or ID == 2 or ID == 4 or ID == 6 then
--					PlayerResource:UpdateTeamSlot(ID, DOTA_TEAM_BADGUYS, 1)
--				else
--					PlayerResource:UpdateTeamSlot(ID, DOTA_TEAM_GOODGUYS, 1)
--				end
			end
		end
		SpawnHeroesBis()
		CustomGameEventManager:Send_ServerToAllClients( "disable_adminmod", broadcast_gametimer )
		GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 4 )

		local diff = {"Easy","Normal","Hard","Extreme"}
		Notifications:TopToAll({text="DIFFICULTY: "..diff[GameRules:GetCustomGameDifficulty()], duration=15.0})
	end

	if newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		nCOUNTDOWNTIMER = 721 -- 721
		nCOUNTDOWNCREEP = 361
		nCOUNTDOWNINCWAVE = 241
		nCOUNTDOWNEVENT = 1
		print( "OnGameRulesStateChange: Game In Progress" )
		self.countdownEnabled = true
		CustomGameEventManager:Send_ServerToAllClients( "show_timer", {} )
	end
end

function GameMode:OnThink()	
local newState = GameRules:State_Get()
	-- Stop thinking if game is paused
	if GameRules:IsGamePaused() == true then
		return 1
	end

	CountdownTimerMuradin()
	CountdownTimerCreep()
	CountdownTimerIncomingWave()
	CountdownTimerSpecialEvents()

	if nCOUNTDOWNTIMER < 1 then
		nCOUNTDOWNTIMER = 1
	end

	if nCOUNTDOWNCREEP < 1 then -- Keep timers to 0 before game starts
		nCOUNTDOWNCREEP = 1
	elseif nCOUNTDOWNCREEP < 2 then
		nCOUNTDOWNCREEP = 361
	elseif time_elapsed > 720 and time_elapsed < 870 then
		nCOUNTDOWNCREEP = 1
	elseif time_elapsed > 1990 then
		nCOUNTDOWNCREEP = 1
	end

	if nCOUNTDOWNINCWAVE < 1 then -- Keep timers to 0 before game starts
		nCOUNTDOWNINCWAVE = 1
	elseif nCOUNTDOWNINCWAVE < 2 then
		nCOUNTDOWNINCWAVE = 241
	elseif time_elapsed > 720 and time_elapsed < 870 then
		nCOUNTDOWNINCWAVE = 1
	elseif time_elapsed > 2140 then
		nCOUNTDOWNINCWAVE = 1
	end

	if nCOUNTDOWNEVENT < 1 then -- Keep timers to 0 before game starts
		nCOUNTDOWNEVENT = 1
	end
	return 1
end

function CountdownTimerMuradin()
	nCOUNTDOWNTIMER = nCOUNTDOWNTIMER - 1
	local t = nCOUNTDOWNTIMER
	local minutes = math.floor(t / 60)
	local seconds = t - (minutes * 60)
	local m10 = math.floor(minutes / 10)
	local m01 = minutes - (m10 * 10)
	local s10 = math.floor(seconds / 10)
	local s01 = seconds - (s10 * 10)
	local broadcast_gametimer = 
		{
			timer_minute_10 = m10,
			timer_minute_01 = m01,
			timer_second_10 = s10,
			timer_second_01 = s01,
		}
	CustomGameEventManager:Send_ServerToAllClients( "countdown", broadcast_gametimer )
	if t <= 120 then
		CustomGameEventManager:Send_ServerToAllClients( "time_remaining", broadcast_gametimer )
	end
end

function CountdownTimerCreep()
	nCOUNTDOWNCREEP = nCOUNTDOWNCREEP - 1
	local t = nCOUNTDOWNCREEP
--	print( "Countdown Timer Activated" )
	local minutes = math.floor(t / 60)
	local seconds = t - (minutes * 60)
	local m10 = math.floor(minutes / 10)
	local m01 = minutes - (m10 * 10)
	local s10 = math.floor(seconds / 10)
	local s01 = seconds - (s10 * 10)
	local broadcast_gametimer = 
		{
			timer_minute_10_2 = m10,
			timer_minute_01_2 = m01,
			timer_second_10_2 = s10,
			timer_second_01_2 = s01,
		}
	CustomGameEventManager:Send_ServerToAllClients( "creepcountdown", broadcast_gametimer )
end

function CountdownTimerIncomingWave()
	nCOUNTDOWNEVENT = nCOUNTDOWNEVENT - 1 -- They are somehow inverted, try to fix later incoming wave and beasts events
	local t = nCOUNTDOWNEVENT
--	print( "Countdown Timer Activated" )
	local minutes = math.floor(t / 60)
	local seconds = t - (minutes * 60)
	local m10 = math.floor(minutes / 10)
	local m01 = minutes - (m10 * 10)
	local s10 = math.floor(seconds / 10)
	local s01 = seconds - (s10 * 10)
	local broadcast_gametimer = 
		{
			timer_minute_10_3 = m10,
			timer_minute_01_3 = m01,
			timer_second_10_3 = s10,
			timer_second_01_3 = s01,
		}
	CustomGameEventManager:Send_ServerToAllClients( "incomingwavecountdown", broadcast_gametimer )
end

function CountdownTimerSpecialEvents()
	nCOUNTDOWNINCWAVE = nCOUNTDOWNINCWAVE - 1
	local t = nCOUNTDOWNINCWAVE
--	print( "Countdown Timer Activated" )
	local minutes = math.floor(t / 60)
	local seconds = t - (minutes * 60)
	local m10 = math.floor(minutes / 10)
	local m01 = minutes - (m10 * 10)
	local s10 = math.floor(seconds / 10)
	local s01 = seconds - (s10 * 10)
	local broadcast_gametimer = 
		{
			timer_minute_10_3 = m10,
			timer_minute_01_3 = m01,
			timer_second_10_3 = s10,
			timer_second_01_3 = s01,
		}
	CustomGameEventManager:Send_ServerToAllClients( "specialeventscountdown", broadcast_gametimer )
end

-- Item added to inventory filter
function GameMode:ItemAddedFilter(keys)
local hero = EntIndexToHScript(keys.inventory_parent_entindex_const)
local item = EntIndexToHScript(keys.item_entindex_const)
local item_name = 0
local point = Entities:FindByName(nil, "base_spawn"):GetAbsOrigin()
local key = "item_key_of_the_three_moons"
local shield = "item_shield_of_invincibility"
local sword = "item_lightning_sword"
local ring = "item_ring_of_superiority"

if item:GetName() then
	item_name = item:GetName()
end

	if hero:IsRealHero() then
		if item_name == sword and sword_first_time then
			FindClearSpaceForUnit(hero, point, true)
			PlayerResource:SetCameraTarget(hero:GetPlayerID(), hero)
			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(hero:GetPlayerID(), nil)
			end)
			sword_first_time = false
		end
		if item_name == ring and ring_first_time then
			FindClearSpaceForUnit(hero, point, true)
			PlayerResource:SetCameraTarget(hero:GetPlayerID(), hero)
			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(hero:GetPlayerID(), nil)
			end)
			ring_first_time = false
		end

		if item_name == key then
			hero.has_epic_1 = true
		end

		if item_name == shield then
			hero.has_epic_2 = true
		end

		if item_name == sword then
			hero.has_epic_3 = true
		end

		if item_name == ring then
			hero.has_epic_4 = true
		end

		if hero.has_epic_1 and hero.has_epic_2 and hero.has_epic_3 and hero.has_epic_4 then
			local line_duration = 10
			Notifications:BottomToAll({hero = hero:GetName(), duration = line_duration})
--			Notifications:BottomToAll({text = hero:GetUnitName().." ", duration = line_duration, continue = true})
			Notifications:BottomToAll({text = PlayerResource:GetPlayerName(hero:GetPlayerID()).." ", duration = line_duration, continue = true})
			Notifications:BottomToAll({text = "merged the 4 Epic items to create Doom Artifact!", duration = line_duration, style = {color = "Red"}, continue = true})

			for itemSlot = 0, 5 do
				Timers:CreateTimer(0.1, function()
					local Item = hero:GetItemInSlot( itemSlot )
					if not Item:IsNull() and Item:GetName() == key then
						hero:EmitSound("Hero_TemplarAssassin.Trap")
						hero:RemoveItem(Item)
						hero.has_epic_1 = false
					end
				end)
				Timers:CreateTimer(0.5, function()
					local Item = hero:GetItemInSlot( itemSlot )
					if not Item:IsNull() and Item:GetName() == shield then
						hero:EmitSound("Hero_TemplarAssassin.Trap")
						hero:RemoveItem(Item)
						hero.has_epic_2 = false
					end
				end)
				Timers:CreateTimer(0.9, function()
					local Item = hero:GetItemInSlot( itemSlot )
					if not Item:IsNull() and Item:GetName() == ring then
						hero:EmitSound("Hero_TemplarAssassin.Trap")
						hero:RemoveItem(Item)
						hero.has_epic_3 = false
					end
				end)
				Timers:CreateTimer(1.3, function()
					local Item = hero:GetItemInSlot( itemSlot )
					if not Item:IsNull() and Item:GetName() == sword then
						hero:EmitSound("Hero_TemplarAssassin.Trap")
						hero:RemoveItem(Item)
						hero.has_epic_4 = false
					end
				end)
			end

			Timers:CreateTimer(1.3, function()
				hero:AddItemByName("item_doom_artifact")
			end)
		end
	end

	-------------------------------------------------------------------------------------------------
	-- Rune pickup logic
	-------------------------------------------------------------------------------------------------
	local unit = hero
	if item_name == "item_rune_armor" then

		-- Only real heroes can pick up runes
		if unit:IsRealHero() then
			if item_name == "item_rune_armor" then
				PickupArmorRune(item, unit)
				return false
			end
		-- If this is not a real hero, drop another rune in place of the picked up one
		else
			local new_rune = CreateItem(item_name, nil, nil)
			CreateItemOnPositionForLaunch(item:GetAbsOrigin() + Vector(0, 0, 50), new_rune)
			return false
		end
	end

	return true
end

function GameMode:FilterDamage( filterTable )
	--	for k, v in pairs( filterTable ) do
		--  print("Damage: " .. k .. " " .. tostring(v) )
	--	end
local victim_index = filterTable["entindex_victim_const"]
local attacker_index = filterTable["entindex_attacker_const"]
if not victim_index or not attacker_index then
  return true
end

local victim = EntIndexToHScript( victim_index )
local attacker = EntIndexToHScript( attacker_index )
local damagetype = filterTable["damagetype_const"]
local damage = attacker:GetAttackDamage()
local intMultiplierDota = 1+((attacker:GetIntellect()/16)/100)
local intMultiplierNew = 1+((attacker:GetIntellect()/50)/100)

	if attacker:IsHero() and attacker:GetUnitName() == "npc_dota_hero_nevermore" then
		if damagetype == DAMAGE_TYPE_PHYSICAL then
			DealDamage(attacker, victim, damage, DAMAGE_TYPE_PURE, nil)
			print("Nevermore Damage: "..damage)
		end
	end
	--	if damagetype == DAMAGE_TYPE_MAGICAL or damagetype == DAMAGE_TYPE_PURE then
	--		filterTable["damage"] = filterTable["damage"]/(1+((attacker:GetIntellect()/16)/100)) -- Disable spell amp
	--		filterTable["damage"] = (filterTable["damage"]/intMultiplierDota)*intMultiplierNew		-- re-enable
	--	end
	return true
end

--	DAMAGE_TYPES = {
--	    [0] = "DAMAGE_TYPE_NONE",
--	    [1] = "DAMAGE_TYPE_PHYSICAL",
--	    [2] = "DAMAGE_TYPE_MAGICAL",
--	    [4] = "DAMAGE_TYPE_PURE",
--	    [7] = "DAMAGE_TYPE_ALL",
--	    [8] = "DAMAGE_TYPE_HP_REMOVAL",
--	}

function RefreshPlayers()
	for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS -1 do
		if PlayerResource:GetTeam( nPlayerID ) == DOTA_TEAM_GOODGUYS then
			if PlayerResource:HasSelectedHero( nPlayerID ) then
				local hero = PlayerResource:GetSelectedHeroEntity(nPlayerID)
				if not hero:IsAlive() then
					hero.ankh_respawn = false
					hero:SetRespawnsDisabled(false)
					Timers:RemoveTimer(hero.respawn_timer)
					hero:RespawnUnit()
				end
				hero:SetHealth(hero:GetMaxHealth())
				hero:SetMana(hero:GetMaxMana())
			end
		end
	end
end

function GameMode:FilterExecuteOrder( filterTable )
	--[[
	print("-----------------------------------------")
	for k, v in pairs( filterTable ) do
		print("Order: " .. k .. " " .. tostring(v) )
	end
	]]

	local units = filterTable["units"]
	local order_type = filterTable["order_type"]
	local issuer = filterTable["issuer_player_id_const"]
	local abilityIndex = filterTable["entindex_ability"]
	local targetIndex = filterTable["entindex_target"]
	local x = tonumber(filterTable["position_x"])
	local y = tonumber(filterTable["position_y"])
	local z = tonumber(filterTable["position_z"])
	local point = Vector(x,y,z)
	local queue = filterTable["queue"] == 1

	local unit
	local numUnits = 0
	local numBuildings = 0
	if units then
		-- Skip Prevents order loops
		unit = EntIndexToHScript(units["0"])
		if unit then
			if unit.skip then
				unit.skip = false
				return true
			end
		end

		for n,unit_index in pairs(units) do
			local unit = EntIndexToHScript(unit_index)
			if unit and IsValidEntity(unit) then
				unit.current_order = order_type -- Track the last executed order
				unit.orderTable = filterTable -- Keep the whole order table, to resume it later if needed
--				local bBuilding = IsCustomBuilding(unit) and not IsUprooted(unit)
--				if bBuilding then
--					numBuildings = numBuildings + 1
--				else
--					numUnits = numUnits + 1
--				end
			end
		end
	end

	-- Don't need this.
	if order_type == DOTA_UNIT_ORDER_RADAR or order_type == DOTA_UNIT_ORDER_GLYPH then return end

	-- Deny No-Target Orders requirements
	if order_type == DOTA_UNIT_ORDER_CAST_NO_TARGET then
		local ability = EntIndexToHScript(abilityIndex)
		if not ability then return true end
		local playerID = unit:GetPlayerOwnerID()
--		
--		-- Check health/mana requirements
--		local manaDeficit = unit:GetMana() ~= unit:GetMaxMana()
--		local healthDeficit = unit:GetHealthDeficit() > 0
--		local bNeedsAnyDeficit = ability:GetKeyValue("RequiresAnyDeficit")
--		local requiresHealthDeficit = ability:GetKeyValue("RequiresHealthDeficit")
--		local requiresManaDeficit = ability:GetKeyValue("RequiresManaDeficit")
--
--		if bNeedsAnyDeficit and not healthDeficit and not manaDeficit then
--			if unit:GetMaxMana() > 0 then
--				SendErrorMessage(issuer, "#error_full_mana_health")
--			else
--				SendErrorMessage(issuer, "#error_full_health")
--			end
--			return false
--		elseif requiresHealthDeficit and not healthDeficit then
--			SendErrorMessage(issuer, "#error_full_health")
--			return false
--		elseif requiresManaDeficit and not manaDeficit then
--			SendErrorMessage(issuer, "#error_full_mana")
--			return false
--		end

		-- Check corpse requirements
--		local corpseRadius = ability:GetKeyValue("RequiresCorpsesAround")
--		if corpseRadius then
--			local corpseFlag = ability:GetKeyValue("CorpseFlag")
--			if corpseFlag then
--				if corpseFlag == "NotMeatWagon" then
--					if not Corpses:AreAnyOutsideInRadius(playerID, unit:GetAbsOrigin(), corpseRadius) then
--						SendErrorMessage(issuer, "#error_no_usable_corpses")
--						return false
--					end
--				end
--			elseif not Corpses:AreAnyInRadius(playerID, unit:GetAbsOrigin(), corpseRadius) then
--			if not Corpses:AreAnyInRadius(playerID, unit:GetAbsOrigin(), corpseRadius) then
--				Notifications:Bottom(playerID, {text="No corpses near!", duration=5.0, style={color="white"}})
--				return false
--			end
--		end
--		local alliedCorpseRadius = ability:GetKeyValue("RequiresAlliedCorpsesAround")
--		if alliedCorpseRadius then
--			if not Corpses:AreAnyAlliedInRadius(playerID, unit:GetAbsOrigin(), alliedCorpseRadius) then
--				SendErrorMessage(issuer, "#error_no_usable_friendly_corpses")
--				return false
--			end
--		end
	end

	return true
end
