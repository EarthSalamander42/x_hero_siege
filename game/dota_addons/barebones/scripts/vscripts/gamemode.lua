_G.nCOUNTDOWNTIMER = 0
_G.nCOUNTDOWNCREEP = 0
_G.nCOUNTDOWNINCWAVE = 0
_G.nCOUNTDOWNEVENT = 0
_G.BT_ENABLED = 1

_G.mod_creator = {
		54896080, -- Cookies
		295458357 -- X Hero Siege
	}

_G.captain_baumi = {
		43305444 -- Baumi( Because why not? )
	}

_G.mod_graphist = {
		61711140 -- Mugiwara
	}

_G.vip_members = {
		69533529, -- West [Unlimited]
		206464009, -- beast [Unlimited]
		86718505, -- Noya [Unlimited]
		146805680, -- [UTAC] Rekail [Gatiipz Gatiipz on Patreon, Remove Date if not paid: 1/01/2017]
		75034844, -- Specter [Tyrael on Patreon, Remove Date if not paid: 5/01/2017]
		348253073, -- 禁断のゲーム [Alisia on Patreon, Remove Date if not paid: DECLINED. 7/11/2016]
		110786327, -- MechJesus [Mauro Solares on Patreon, Remove Date if not paid: DECLINED. 7/11/2016]
		93860661, -- Meteor [Supawit Enyord on Patreon, Remove Date if not paid: 10/01/2017]
		190411200, -- Nojo [Nojo on Patreon, Remove Date if not paid: DECLINED. 23/11/2016]
		97629656, -- jacobkahnji  [Jacob A Yow on Patreon, Remove Date if not paid: 23/01/2017]
		136258650, -- Meliodas [Dinh Quang on Patreon, Remove Date if not paid: DECLINED. 25/11/2016]
		55770641, -- Primeape [Filip Dingum on Patreon, Remove Date if not paid: DECLINED. 31/11/2016]
		5194446, -- Botd [Hugo Marques on Patreon, Remove Date if not paid: 31/01/2017]

		312910864, -- breddybourne [Winner of the 21th November Day Event]
		157808659, -- ST8 [Winner of the 21th November Day Event]
		62993541, -- KennyCrazy [Winner of the 21th November Day Event]
		331762743, -- Sterling8077 [Winner of the 21th November Day Event]
		112182763, -- Mugiwara, not the graphist another one ^^ [Winner of the 21th November Day Event]
		56352263 -- Flotos [Winner of the 21th November Day Event]
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

if GameMode == nil then
	_G.GameMode = class({})
end

require('events')
require('internal/gamemode')
require('internal/events')
require('label')
require('libraries/timers')
require('libraries/physics')
require('libraries/projectiles')
require('libraries/notifications')
require('libraries/animations')
require('libraries/attachments')
require('phases/creeps')
require('phases/special_events')
require('phases/phase1')
require('phases/phase2')

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
GameMode.Magtheridon_killed = 0
GameMode.BossesTop_killed = 0
GameMode.Arthas_killed = 0
time_elapsed = 0

	for playerID = 0, DOTA_MAX_TEAM_PLAYERS do
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
end

function GameMode:OnHeroInGame(hero)
	if hero:GetUnitName() == "npc_dota_hero_wisp" then
		hero:SetAbilityPoints(0)
		hero:SetGold(0, false)
		hero:AddNewModifier(nil, nil, "modifier_animation_freeze_stun", {Duration = 20, IsHidden = true})
		hero:AddNewModifier(nil, nil, "modifier_invulnerable", nil)
	end
end

function GameMode:OnGameInProgress()
local difficulty = GameRules:GetCustomGameDifficulty()
local triggers_choice = Entities:FindAllByName("trigger_special_event_choice")

	-- Timer: Creep Levels 1 to 6. Lanes 1 to 8.
	Timers:CreateTimer(0, function()
		print(time_elapsed)
		time_elapsed = time_elapsed + 30
		SpawnCreeps()
	return 30
	end)

	-- Timer: Creeps Levels 2, 3, 4, 5, 6 Whispering
	Timers:CreateTimer(360, function() -- 6 Min
		Notifications:TopToAll({hero="npc_dota_hero_undying", duration=6.0})
		Notifications:TopToAll({text="Creeps are now Level 2!", style={color="green"}, continue=true})
		SpawnRedDragon()
	end)
	Timers:CreateTimer(840, function() -- 12 Min + 2 Min with Muradin Event = 14 Min
		Notifications:TopToAll({hero="npc_dota_hero_nyx_assassin", duration=6.0})
		Notifications:TopToAll({text="Creeps are now Level 3! ", style={color="grey"}, continue=true})
		Notifications:TopToAll({text="Beasts Events are unlocked!", style={color="grey"}, continue=true})
		nCOUNTDOWNCREEP = 361
		nCOUNTDOWNINCWAVE = 241
		SpawnBlackDragon()
		for _,v in pairs(triggers_choice) do
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
	end)
	Timers:CreateTimer(451, function() -- 7 Min 30 sec
		Notifications:TopToAll({text="WARNING: Incoming wave of Darkness from the North!", duration=25.0, style={color="red"}})
	end)
	Timers:CreateTimer(691, function() -- 11 Min 30 sec
		Notifications:TopToAll({text="WARNING: Muradin Event in 30 sec!", duration=25.0, style={color="grey"}})
	end)
	Timers:CreateTimer(811, function() -- 13 Min 30 sec
		Notifications:TopToAll({text="WARNING: Incoming wave of Darkness from the East!", duration=25.0, style={color="red"}})
	end)
	Timers:CreateTimer(1051, function() -- 15 Min 30 sec
		Notifications:TopToAll({text="WARNING: Incoming wave of Darkness from the South!", duration=25.0, style={color="red"}})
	end)
	Timers:CreateTimer(1291, function() -- 19 Min 30 sec
		Notifications:TopToAll({text="WARNING: Incoming wave of Darkness from the West!", duration=25.0, style={color="red"}})
	end)
	Timers:CreateTimer(1411, function() -- 23 Min 30 sec
		Notifications:TopToAll({text="WARNING: Farming Event in 30 sec!", duration=25.0, style={color="grey"}})
	end)
	Timers:CreateTimer(1591, function() -- 24 Min 30 sec
		Notifications:TopToAll({text="WARNING: Incoming wave of Darkness from the North!", duration=25.0, style={color="red"}})
	end)
	Timers:CreateTimer(1831, function() -- 27 Min 30 sec
		Notifications:TopToAll({text="WARNING: Incoming wave of Darkness from the East!", duration=25.0, style={color="red"}})
	end)
	Timers:CreateTimer(2071, function() -- 31 Min 30 sec
		Notifications:TopToAll({text="WARNING: Incoming wave of Darkness from the South!", duration=25.0, style={color="red"}})
	end)

	--//=================================================================================================================
	--// Timer: West Event 1 Spawn
	--//=================================================================================================================
	Timers:CreateTimer(241, function() -- 4 Min: NECROLYTE WEST EVENT 1
	local point = Entities:FindByName( nil, "npc_dota_spawner_west_event"):GetAbsOrigin()
		if difficulty == 1 then
			for j = 1, 6 do
				local unit = CreateUnitByName("npc_dota_creature_necrolyte_event_1", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		elseif difficulty == 2 then
			for j = 1, 8 do
				local unit = CreateUnitByName("npc_dota_creature_necrolyte_event_1", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		elseif difficulty == 3 then
			for j = 1, 10 do
				local unit = CreateUnitByName("npc_dota_creature_necrolyte_event_1", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		elseif difficulty == 4 then
			for j = 1, 14 do
				local unit = CreateUnitByName("npc_dota_creature_necrolyte_event_1", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		end
	end)

	--//=================================================================================================================
	--// Timer: North Event 2 Spawn
	--//=================================================================================================================
	Timers:CreateTimer(481, function() -- 8 Min: NAGA SIREN NORTH EVENT 2
	local point = Entities:FindByName( nil, "npc_dota_spawner_north_event"):GetAbsOrigin()
		if difficulty == 1 then
			for j = 1, 6 do
				local unit = CreateUnitByName("npc_dota_creature_naga_siren_event_2", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		elseif difficulty == 2 then
			for j = 1, 8 do
				local unit = CreateUnitByName("npc_dota_creature_naga_siren_event_2", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		elseif difficulty == 3 then
			for j = 1, 10 do
				local unit = CreateUnitByName("npc_dota_creature_naga_siren_event_2", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		elseif difficulty == 4 then
			for j = 1, 14 do
				local unit = CreateUnitByName("npc_dota_creature_naga_siren_event_2", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		end
	end)

	--//=================================================================================================================
	--// Timer: East Event 3 Spawn
	--//=================================================================================================================
	Timers:CreateTimer(841, function() -- 12 Min: VENGEFUL SPIRIT SOUTH EVENT 3
	local point = Entities:FindByName( nil, "npc_dota_spawner_east_event"):GetAbsOrigin()
		if difficulty == 1 then
			for j = 1, 6 do
				local unit = CreateUnitByName("npc_dota_creature_vengeful_spirit_event_3", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		elseif difficulty == 2 then
			for j = 1, 8 do
				local unit = CreateUnitByName("npc_dota_creature_vengeful_spirit_event_3", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		elseif difficulty == 3 then
			for j = 1, 10 do
				local unit = CreateUnitByName("npc_dota_creature_vengeful_spirit_event_3", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		elseif difficulty == 4 then
			for j = 1, 14 do
				local unit = CreateUnitByName("npc_dota_creature_vengeful_spirit_event_3", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		end
	end)

	--//=================================================================================================================
	--// Timer: South Event 4 Spawn
	--//=================================================================================================================
	Timers:CreateTimer(1081, function() -- 16 Min: CAPTAIN SOUTH EVENT 4
	local point = Entities:FindByName( nil, "npc_dota_spawner_south_event"):GetAbsOrigin()
		if difficulty == 1 then
			for j = 1, 6 do
				local unit = CreateUnitByName("npc_dota_creature_captain_event_4", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			elseif difficulty == 2 then
			for j = 1, 8 do
				local unit = CreateUnitByName("npc_dota_creature_captain_event_4", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			elseif difficulty == 3 then
			for j = 1, 10 do
				local unit = CreateUnitByName("npc_dota_creature_captain_event_4", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			elseif difficulty == 4 then
			for j = 1, 14 do
				local unit = CreateUnitByName("npc_dota_creature_captain_event_4", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		end
	end)

	--//=================================================================================================================
	--// Timer: West Event 5 Spawn
	--//=================================================================================================================
	Timers:CreateTimer(1321, function() -- 20 Min: SLARDARS EVENT 5
	local point = Entities:FindByName( nil, "npc_dota_spawner_west_event"):GetAbsOrigin()
		if difficulty == 1 then
			for j = 1, 6 do
				local unit = CreateUnitByName("npc_dota_creature_slardar_event_5", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			elseif difficulty == 2 then
			for j = 1, 8 do
				local unit = CreateUnitByName("npc_dota_creature_slardar_event_5", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			elseif difficulty == 3 then
			for j = 1, 10 do
				local unit = CreateUnitByName("npc_dota_creature_slardar_event_5", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			elseif difficulty == 4 then
			for j = 1, 14 do
				local unit = CreateUnitByName("npc_dota_creature_slardar_event_5", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		end
	end)

	--//=================================================================================================================
	--// Timer: North Event 6 Spawn
	--//=================================================================================================================
	Timers:CreateTimer(1621, function() -- 25 Min: CHAOS KNIGHTS EVENT 6
	local point = Entities:FindByName( nil, "npc_dota_spawner_north_event"):GetAbsOrigin()
		if difficulty == 1 then
			for j = 1, 6 do
				local unit = CreateUnitByName("npc_dota_creature_chaos_knight_event_6", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			elseif difficulty == 2 then
			for j = 1, 8 do
				local unit = CreateUnitByName("npc_dota_creature_chaos_knight_event_6", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			elseif difficulty == 3 then
			for j = 1, 10 do
				local unit = CreateUnitByName("npc_dota_creature_chaos_knight_event_6", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			elseif difficulty == 4 then
			for j = 1, 14 do
				local unit = CreateUnitByName("npc_dota_creature_chaos_knight_event_6", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		end
	end)

	--//=================================================================================================================
	--// Timer: East Event 7 Spawn
	--//=================================================================================================================
	Timers:CreateTimer(1861, function() -- 29 Min: LUNA EVENT 7
	local point = Entities:FindByName( nil, "npc_dota_spawner_east_event"):GetAbsOrigin()
		if difficulty == 1 then
			for j = 1, 6 do
				local unit = CreateUnitByName("npc_dota_creature_luna_event_7", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			elseif difficulty == 2 then
			for j = 1, 8 do
				local unit = CreateUnitByName("npc_dota_creature_luna_event_7", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			elseif difficulty == 3 then
			for j = 1, 10 do
				local unit = CreateUnitByName("npc_dota_creature_luna_event_7", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			elseif difficulty == 4 then
			for j = 1, 14 do
				local unit = CreateUnitByName("npc_dota_creature_luna_event_7", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		end
	end)

	--//=================================================================================================================
	--// Timer: South Event 8 Spawn
	--//=================================================================================================================
	Timers:CreateTimer(2101, function() -- 33 Min: CLOCKWERK EVENT 8
	local point = Entities:FindByName( nil, "npc_dota_spawner_south_event"):GetAbsOrigin()
		if difficulty == 1 then
			for j = 1, 6 do
				local unit = CreateUnitByName("npc_dota_creature_clockwerk_event_8", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			elseif difficulty == 2 then
			for j = 1, 8 do
				local unit = CreateUnitByName("npc_dota_creature_clockwerk_event_8", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			elseif difficulty == 3 then
			for j = 1, 10 do
				local unit = CreateUnitByName("npc_dota_creature_clockwerk_event_8", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
			elseif difficulty == 4 then
			for j = 1, 14 do
				local unit = CreateUnitByName("npc_dota_creature_clockwerk_event_8", point, true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		end
	end)

	Timers:CreateTimer(716, function() -- 716 - 11:55 Min: MURADIN BRONZEBEARD EVENT 1
		PauseCreepsMuradin()
		PauseHeroes()
		Timers:CreateTimer(5, function()
			MuradinEvent()
			Timers:CreateTimer(3, RestartHeroes())
		end)
	end)

	Timers:CreateTimer(6, function() -- 1436 - 23:55 Min: FARM EVENT 2
		PauseCreepsFarm()
		PauseHeroes()
		Timers:CreateTimer(5, function()
			FarmEvent()
			Timers:CreateTimer(3, RestartHeroes())
		end)
	end)
end

function RestartHeroes()
local heroes = HeroList:GetAllHeroes()

	for _,hero in pairs(heroes) do
		if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
			hero:RemoveModifierByName("modifier_animation_freeze_stun")
			hero:RemoveModifierByName("modifier_invulnerable")
		end
	end
end

function PauseHeroes()
local heroes = HeroList:GetAllHeroes()

	for _,hero in pairs(heroes) do
		if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
			hero:AddNewModifier(nil, nil, "modifier_animation_freeze_stun",nil)
			hero:AddNewModifier(nil, nil, "modifier_invulnerable",nil)
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
	local difficulty = GameRules:GetCustomGameDifficulty()

	-- Timer Rules
	GameRules:SetPreGameTime( 120.0 )
	GameRules:SetPostGameTime( 30.0 )
	GameRules:SetTreeRegrowTime( 60.0 )
	GameRules:SetHeroSelectionTime( 0.0 ) --This is not dota bitch
	GameRules:SetGoldTickTime( 0.0 ) --This is not dota bitch
	GameRules:SetGoldPerTick( 0.0 ) --This is not dota bitch
	GameRules:SetCustomGameSetupAutoLaunchDelay( 10.0 ) --Vote Time

	-- Boolean Rules
	GameRules:LockCustomGameSetupTeamAssignment( true )
--	GameRules:EnableCustomGameSetupAutoLaunch( true )
	GameRules:SetUseCustomHeroXPValues ( true )
	GameRules:SetUseBaseGoldBountyOnHeroes( true )
	GameRules:SetHeroRespawnEnabled( true )
	mode:SetUseCustomHeroLevels( true )
	mode:SetRecommendedItemsDisabled( false )
	mode:SetTopBarTeamValuesOverride ( true )
	mode:SetTopBarTeamValuesVisible( false )
	mode:SetUnseenFogOfWarEnabled( false )
	mode:SetStashPurchasingDisabled ( true )

	mode:SetBuybackEnabled( false )
	mode:SetBotThinkingEnabled( false )
	mode:SetTowerBackdoorProtectionEnabled( false )
	mode:SetFogOfWarDisabled( true ) --FUCK YOU VOLVO
	mode:SetGoldSoundDisabled( false )
	mode:SetRemoveIllusionsOnDeath( false )
	mode:SetAlwaysShowPlayerInventory( false )
	mode:SetAnnouncerDisabled( false )
	mode:SetLoseGoldOnDeath( false )

	-- Value Rules
	mode:SetCameraDistanceOverride( 1250 )
	mode:SetMaximumAttackSpeed( 600 )
	mode:SetMinimumAttackSpeed( 20 )
	mode:SetCustomHeroMaxLevel( 30 )
	GameRules:SetHeroMinimapIconScale( 1.25 )
	GameRules:SetCreepMinimapIconScale( 1 )
	GameRules:SetRuneMinimapIconScale( 1 )

	-- Team Rules
	SetTeamCustomHealthbarColor(DOTA_TEAM_GOODGUYS, 52, 52, 190) --Blue
	SetTeamCustomHealthbarColor(DOTA_TEAM_BADGUYS, 190, 52, 52) --Red
	SetTeamCustomHealthbarColor(DOTA_TEAM_CUSTOM_1, 255, 255, 0) --Yellow

	-- Table Rules
	mode:SetCustomXPRequiredToReachNextLevel( XP_PER_LEVEL_TABLE )

	GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_GOODGUYS, 8 )
	GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_BADGUYS, 0 )
	GameRules:SetCustomGameTeamMaxPlayers( DOTA_TEAM_CUSTOM_1, 0 )
	mode:SetCustomGameForceHero( "npc_dota_hero_wisp" )
	mode:SetFixedRespawnTime( 40 )

	-- Lua Modifiers
	LinkLuaModifier("modifier_earthquake_aura", "heroes/hero_brewmaster/earthquake", LUA_MODIFIER_MOTION_NONE)

--	if difficulty == 1 then
--		mode:SetFixedRespawnTime( 30 )
--	elseif difficulty == 2 then
--		mode:SetFixedRespawnTime( 60 )
--	elseif difficulty == 3 then
--		mode:SetFixedRespawnTime( 90 )
--	elseif difficulty == 4 then
--		mode:SetFixedRespawnTime( 120 )
--	end

	GameMode:_InitGameMode()
	self:OnFirstPlayerLoaded()

	GameRules:GetGameModeEntity():SetThink( "OnThink", self, 1 )

	self.countdownEnabled = false

	Convars:RegisterCommand( "muradin_set_timer", function(...) return SetTimerMuradin( ... ) end, "Set the timer.", FCVAR_CHEAT )
	Convars:RegisterCommand( "creep_set_timer", function(...) return SetTimerCreep( ... ) end, "Set the timer.", FCVAR_CHEAT )
	Convars:RegisterCommand( "wave_set_timer", function(...) return SetTimerIncomingWave( ... ) end, "Set the timer.", FCVAR_CHEAT )
	Convars:RegisterCommand( "beast_set_timer", function(...) return SetTimerSpecialEvents( ... ) end, "Set the timer.", FCVAR_CHEAT )
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
		for _,hero in pairs(heroes) do
			if hero:IsRealHero() then
--				local item1 = CreateItem("item_ankh_of_reincarnation", hero, hero)
--				hero:AddItem(item1)

--				local item2 = CreateItem("item_faerie_fire", hero, hero)
--				hero:AddItem(item2)
			end
		end
		SpawnHeroesBis()

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
	elseif time_elapsed > 1920 then
		nCOUNTDOWNCREEP = 1
	end

	if nCOUNTDOWNINCWAVE < 1 then -- Keep timers to 0 before game starts
		nCOUNTDOWNINCWAVE = 1
	elseif nCOUNTDOWNINCWAVE < 2 then
		nCOUNTDOWNINCWAVE = 241
	elseif time_elapsed > 720 and time_elapsed < 870 then
		nCOUNTDOWNINCWAVE = 1
	elseif time_elapsed > 2040 then
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
--	print( "Countdown Timer Activated" )
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

function SetTimerMuradin( cmdName, time )
	print( "Set the timer to: " .. time )
	nCOUNTDOWNTIMER = time
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

function SetTimerCreep( cmdName, time )
	print( "Set the timer to: " .. time )
	nCOUNTDOWNCREEP = time
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

function SetTimerIncomingWave( cmdName, time )
	print( "Set the timer to: " .. time )
	nCOUNTDOWNEVENT = time
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

function SetTimerSpecialEvents( cmdName, time )
	print( "Set the timer to: " .. time )
	nCOUNTDOWNINCWAVE = time
end
