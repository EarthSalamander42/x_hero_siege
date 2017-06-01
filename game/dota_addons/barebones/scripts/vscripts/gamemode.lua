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

_G.PREGAMETIME = 150
_G.nGAMETIMER = 0
_G.nCOUNTDOWNTIMER = 0
_G.nCOUNTDOWNCREEP = 0
_G.nCOUNTDOWNINCWAVE = 0
_G.nCOUNTDOWNEVENT = 0
_G.BT_ENABLED = 1
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
_G.doom_first_time = false
_G.frost_first_time = false
_G.X_HERO_SIEGE_V = 3.40
_G.SECRET = 0
_G.RESPAWN_TIME = 40.0
_G.ALL_HERO_IMAGE_DEAD = 0
_G.PHASE_3 = 0
_G.CREEP_LANES_TYPE = 1
_G.FORCED_LANES = 0
_G.DUAL_HERO = 1
_G.STORM_SPIRIT = 0

_G.mod_creator = {
		54896080,	-- Cookies
		295458357	-- X Hero Siege
	}

_G.captain_baumi = {
		43305444,	-- Baumi(Because why not?)
		44022861	-- Padaa
	}

_G.mod_graphist = {
		61711140,	-- Mugiwara
		56352263,	-- Flotos
		231117589	-- Xero
	}

_G.golden_vip_members = {
		69533529,	-- West
		51728279,	-- mC
		206464009,	-- beast
		86718505,	-- Noya
		62993541,	-- KennyCrazy
		117327434,	-- Eren
		146805680,	-- [UTAC] Rekail [Gatiipz Gatiipz on Patreon]
		33042578,	-- ryusajin
		110786327,	-- MechJesus [Mauro Solares on Patreon]
		93860661,	-- Meteor [Supawit Enyord on Patreon]
		136258650,	-- Meliodas [Dinh Quang on Patreon]
		55770641,	-- Primeape [Filip Dingum on Patreon]
		33529791,	-- Reo Speedwagon [Punito on Discord]
		74297042,	-- отец молдун [Pascale on Discord]
		46875732,	-- Firetoad
		42452574,	-- FrenchDeath
		59765927,	-- Champi
		28496872,	-- Ou Sen
		134026389,	-- Hypérion
		80192910,	-- Cheshire [Nathan Perscott on Patreon]
		89498388,	-- Sly
		78356159,	-- [Sam Teo on Patreon, May paid, 2 months left for Permanent]
		111692244,	-- [Iris Von Everec on Steam, May paid, 2 months left for Permanent]
		101989646	-- [PraaNavi, Bug-Seeker, Permanent]
	}

_G.vip_members = {
		320774890,	-- Error [Han Gao on Patreon, April Paid]
		97490223,	-- IllidanStormrage [Lucas Diao on Patreon, April Paid]
		44364795,	-- Lyzer93 [Balraj McCoy on Patreon, April Paid]
		46744186,	-- Captain Darian Frey [CaptainDarianFrey on Patreon, April Paid]
		54935523,	-- The Patriarchy [Kevin Moore on Patreon, April Paid]
		3180772,	-- Yoshi [Fabian Rothmund on Patreon, April Paid]
		61166985,	-- SpaceGauges [Nicholas Karlberg on Patreon, April Paid]
		100304532,	-- DoniLouMeI [Kyle Leong on Patreon, April Paid]
		587665,		-- Yatzy [Yatzy on Patreon, April Paid]
		123433896,	-- Nikolai on Patreon, April Paid
		142465613,	-- Four [Darell Tian on Patreon, April Paid]
		325760680,	-- I-Am-? [nieva06 on Discord, April Paid]
		130393455,	-- Achi Cirno, April Paid
		177329557,	-- Pupuniko [spax28 on Patreon, April Paid]
		80662298,	-- The Dimenator [Michael Cloutier on Patreon, April Paid]
		175647606,	-- Typical Wolf [April Paid]
		87395017	-- Fuzzy [Farzad Havaldar on Patreon, April Paid]
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
PLAYER_COLORS[6] = { 0, 125, 0 } --Green (Dark)
PLAYER_COLORS[7] = { 255, 100, 255 } --Pink

CREEP_LANES = {} -- Stores individual creep lanes {enable/disable, creep level, rax alive}
CREEP_LANES[1] = {0, 1, 1}
CREEP_LANES[2] = {0, 1, 1}
CREEP_LANES[3] = {0, 1, 1}
CREEP_LANES[4] = {0, 1, 1}
CREEP_LANES[5] = {0, 1, 1}
CREEP_LANES[6] = {0, 1, 1}
CREEP_LANES[7] = {0, 1, 1}
CREEP_LANES[8] = {0, 1, 1}

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

-- DOTA 2
HEROLIST[28] = "axe"
HEROLIST[29] = "monkey_king"
HEROLIST[30] = "troll_warlord"
HEROLIST[31] = "doom_bringer"
HEROLIST[32] = "bristleback"
HEROLIST[33] = "leshrac"

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

-- DOTA 2
HEROLIST_ALT[28] = axe
HEROLIST_ALT[29] = monkey_king
HEROLIST_ALT[30] = troll_warlord
HEROLIST_ALT[31] = doom_bringer
HEROLIST_ALT[32] = bristleback
HEROLIST_ALT[33] = leshrac

HEROLIST_VIP = {}
HEROLIST_VIP[1] = "slardar"				-- Centurion
HEROLIST_VIP[2] = "skeleton_king"		-- Lich King
HEROLIST_VIP[3] = "meepo"				-- Kobold Knight
HEROLIST_VIP[4] = "chaos_knight"		-- Dark Fundamental
HEROLIST_VIP[5] = "tiny"				-- Stone Giant
HEROLIST_VIP[6] = "sand_king"			-- Desert Wyrm
HEROLIST_VIP[7] = "necrolyte"			-- Dark Summoner
HEROLIST_VIP[8] = "storm_spirit"		-- Spirit Master

HEROLIST_VIP_ALT = {}
HEROLIST_VIP_ALT[1] = slardar			-- Centurion
HEROLIST_VIP_ALT[2] = skeleton_king		-- Lich King
HEROLIST_VIP_ALT[3] = meepo				-- Kobold Knight
HEROLIST_VIP_ALT[4] = chaos_knight		-- Dark Fundamental
HEROLIST_VIP_ALT[5] = tiny				-- Stone Giant
HEROLIST_VIP_ALT[6] = sand_king			-- Desert Wyrm
HEROLIST_VIP_ALT[7] = necrolyte			-- Dark Summoner
HEROLIST_VIP_ALT[8] = storm_spirit		-- Spirit Master

HEROLIST_MARVEL = {}
HEROLIST_MARVEL[1] = "tinker"			-- Iron Man

HEROLIST_MARVEL_ALT = {}
HEROLIST_MARVEL_ALT[1] = tinker			-- Iron Man

_G.FarmEvent_Creeps = {
	"npc_dota_creature_murloc",
	"npc_dota_creature_wildkin",
	"npc_dota_creature_golem",
	"npc_dota_creature_polar_furbolg",
	"npc_dota_creature_centaur",
	"npc_dota_creature_razormane",
	"npc_dota_creature_revenant",
	"npc_dota_creature_tuskarr",
	"npc_dota_creature_satyrr"
	}

DUAL_HERO_1 = {}
DUAL_HERO_1[0] = 0
DUAL_HERO_1[1] = 0
DUAL_HERO_1[2] = 0
DUAL_HERO_1[3] = 0
DUAL_HERO_1[4] = 0
DUAL_HERO_1[5] = 0
DUAL_HERO_1[6] = 0
DUAL_HERO_1[7] = 0

DUAL_HERO_2 = {}
DUAL_HERO_2[0] = 0
DUAL_HERO_2[1] = 0
DUAL_HERO_2[2] = 0
DUAL_HERO_2[3] = 0
DUAL_HERO_2[4] = 0
DUAL_HERO_2[5] = 0
DUAL_HERO_2[6] = 0
DUAL_HERO_2[7] = 0

timers = {}

function GameMode:OnFirstPlayerLoaded()

end

function FrostTowersToFinalWave()
	if GameMode.FrostTowers_killed >= 2 then
		nCOUNTDOWNTIMER = 60
		nCOUNTDOWNCREEP = 1
		nCOUNTDOWNINCWAVE = 1
		nCOUNTDOWNEVENT = 1
		PHASE_3 = 1
--		CustomGameEventManager:Send_ServerToAllClients("hide_timer", {})
		PauseCreeps()
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
GameMode.FrostInfernal_occuring = 0
GameMode.SpiritBeast_killed = 0
GameMode.SpiritBeast_occuring = 0
GameMode.HeroImage_occuring = 0
GameMode.AllHeroImages_occuring = 0
GameMode.AllHeroImagesDead = 0
GameMode.FrostTowers_killed = 0
GameMode.BossesTop_killed = 0
time_elapsed = 0
GameMode.creep_roll = {}
GameMode.creep_roll["race"] = 0

	for playerID = 0, DOTA_MAX_TEAM_PLAYERS -1 do
		if PlayerResource:IsValidPlayer(playerID) then
			PlayerResource:SetCustomPlayerColor(playerID, PLAYER_COLORS[playerID][1], PLAYER_COLORS[playerID][2], PLAYER_COLORS[playerID][3])
		end
	end

	Timers:CreateTimer(3.0, function()
		EmitGlobalSound("Global.InGame")
	end)

	GameRules:GetGameModeEntity():SetItemAddedToInventoryFilter(Dynamic_Wrap(GameMode, "ItemAddedFilter"), self)
end

function GameMode:OnHeroInGame(hero)
local id = hero:GetPlayerID()
local point = Entities:FindByName(nil, "point_teleport_choose_hero_"..id)

	if hero:GetUnitName() == "npc_dota_hero_wisp" then
		hero:SetAbilityPoints(0)
		hero:SetGold(0, false)
		hero:AddNewModifier(nil, nil, "modifier_boss_stun", {Duration = 30, IsHidden = true})
		if DUAL_HERO == 2 then
			hero.dual_choose = 0
		end
		PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), hero)
		Timers:CreateTimer(23.0, function()
			FindClearSpaceForUnit(hero, point:GetAbsOrigin(), true)
		end)
		Timers:CreateTimer(29.0, function()
			PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil)
		end)
	elseif hero:GetUnitName() == "npc_dota_hero_terrorblade" then
		if IsInToolsMode() then
--			hero:AddExperience(100000, false, false)
			hero:ModifyStrength(10000)
			hero:ModifyAgility(10000)
			hero:ModifyIntellect(10000)
		end
	end
end

function GameMode:OnGameInProgress()
local difficulty = GameRules:GetCustomGameDifficulty()

	-- Make towers invulnerable again
	for Players = 1, 8 do
		local towers = Entities:FindAllByName("dota_badguys_tower"..Players)
		for _, tower in pairs(towers) do
			tower:AddNewModifier(nil, nil, "modifier_invulnerable", nil)
		end
		local raxes = Entities:FindAllByName("dota_badguys_barracks_"..Players)
		for _, rax in pairs(raxes) do
			rax:AddNewModifier(nil, nil, "modifier_invulnerable", nil)
		end
	end

	-- Make towers vulnerable depending player numbers
	local Count = PlayerResource:GetPlayerCount()
	if CREEP_LANES_TYPE == 3 then
		for NumPlayers = 1, 8 do
			CREEP_LANES[NumPlayers][1] = 1
			local DoorObs = Entities:FindAllByName("obstruction_lane"..NumPlayers)
			for _, obs in pairs(DoorObs) do
				obs:SetEnabled(false, true)
			end
			DoEntFire("door_lane"..NumPlayers, "SetAnimation", "open", 0, nil, nil)
			local towers = Entities:FindAllByName("dota_badguys_tower"..NumPlayers)
			for _, tower in pairs(towers) do
				tower:RemoveModifierByName("modifier_invulnerable")
			end
			local raxes = Entities:FindAllByName("dota_badguys_barracks_"..NumPlayers)
			for _, rax in pairs(raxes) do
				rax:RemoveModifierByName("modifier_invulnerable")
			end
		end
	else
		for NumPlayers = 1, Count * CREEP_LANES_TYPE do
			CREEP_LANES[NumPlayers][1] = 1
			local DoorObs = Entities:FindAllByName("obstruction_lane"..NumPlayers)
			for _, obs in pairs(DoorObs) do
				obs:SetEnabled(false, true)
			end
			DoEntFire("door_lane"..NumPlayers, "SetAnimation", "open", 0, nil, nil)
			local towers = Entities:FindAllByName("dota_badguys_tower"..NumPlayers)
			for _, tower in pairs(towers) do
				tower:RemoveModifierByName("modifier_invulnerable")
			end
			local raxes = Entities:FindAllByName("dota_badguys_barracks_"..NumPlayers)
			for _, rax in pairs(raxes) do
				rax:RemoveModifierByName("modifier_invulnerable")
			end
		end
	end

	Timers:CreateTimer(839, function() -- 839, 12 Min + 2 Min with Muradin Event = 14 Min
		Notifications:TopToAll({text="Special Events are unlocked!", style={color="DodgerBlue"}, continue=true})
		Entities:FindByName(nil, "trigger_special_event_tp_off"):Disable()
		Entities:FindByName(nil, "trigger_special_event"):Enable()
	end)

	-- Timer: Creep Levels 1 to 4. Lanes 1 to 8.
	Timers:CreateTimer(0, function()
		time_elapsed = time_elapsed + 30
		if SPECIAL_EVENT == 0 then
			SpawnCreeps()
			return 30
		elseif SPECIAL_EVENT == 1 then
			print("Creeps paused, Special Event.")
		elseif Phase_3 == 1 then
			print("Creeps Timer killed, Phase 3.")
			return nil
		end
		return 30
	end)
end

function PauseHeroes()
local heroes = HeroList:GetAllHeroes()

	for _,hero in pairs(heroes) do
		hero:AddNewModifier(nil, nil, "modifier_animation_freeze_stun", nil)
		hero:AddNewModifier(nil, nil, "modifier_invulnerable", nil)
	end
end

function RestartHeroes()
local heroes = HeroList:GetAllHeroes()

	for _,hero in pairs(heroes) do
		hero:RemoveModifierByName("modifier_animation_freeze_stun")
		hero:RemoveModifierByName("modifier_invulnerable")
	end
end

function PauseCreeps()
local units = FindUnitsInRadius( DOTA_TEAM_BADGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_INVULNERABLE , FIND_ANY_ORDER, false )
local units2 = FindUnitsInRadius( DOTA_TEAM_GOODGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_INVULNERABLE , FIND_ANY_ORDER, false )

	for _,v in pairs(units) do
		if v:IsCreature() and v:HasMovementCapability() then
			v:AddNewModifier(nil, nil, "modifier_animation_freeze_stun", nil)
			v:AddNewModifier(nil, nil, "modifier_invulnerable", nil)
		end
	end

	for _,v in pairs(units2) do
		if v:IsCreature() and v:HasMovementCapability() then
			v:AddNewModifier(nil, nil, "modifier_animation_freeze_stun", nil)
			v:AddNewModifier(nil, nil, "modifier_invulnerable", nil)
		end
	end
end

function RestartCreeps()
local units = FindUnitsInRadius( DOTA_TEAM_BADGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_INVULNERABLE , FIND_ANY_ORDER, false )
local units2 = FindUnitsInRadius( DOTA_TEAM_GOODGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_INVULNERABLE , FIND_ANY_ORDER, false )

	for _,v in pairs(units) do
		if v:IsCreature() and v:HasMovementCapability() then
			v:RemoveModifierByName("modifier_animation_freeze_stun")
			v:RemoveModifierByName("modifier_invulnerable")
		end
	end

	for _,v in pairs(units2) do
		if v:IsCreature() and v:HasMovementCapability() then
			v:RemoveModifierByName("modifier_animation_freeze_stun")
			v:RemoveModifierByName("modifier_invulnerable")
		end
	end
end

function PauseCreepsCastle()
local units = FindUnitsInRadius( DOTA_TEAM_BADGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_INVULNERABLE , FIND_ANY_ORDER, false )
local units2 = FindUnitsInRadius( DOTA_TEAM_GOODGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_INVULNERABLE , FIND_ANY_ORDER, false )

	for _,v in pairs(units) do
		if v:IsCreature() and v:HasMovementCapability() then
			v:AddNewModifier(nil, nil, "modifier_boss_stun", {duration = 10.0})
			v:AddNewModifier(nil, nil, "modifier_invulnerable", {duration = 10.0})
		end
	end

	for _,v in pairs(units2) do
		if v:IsCreature() and v:HasMovementCapability() then
			v:AddNewModifier(nil, nil, "modifier_boss_stun", {duration = 10.0})
			v:AddNewModifier(nil, nil, "modifier_invulnerable", {duration = 10.0})
		end
	end
end

	XP_PER_LEVEL_TABLE = {
	0,		-- 1
	200,	-- 2 +200
	500,	-- 3 +300
	900,	-- 4 +400
	1400,	-- 5 +500
	2000,	-- 6 +600
	2800,	-- 7 +700
	3800,	-- 8 +1000
	5000,	-- 9 +1200
	6400,	-- 10 +1400
	8200,	-- 11 +1800
	10400,	-- 12 +2200
	13000,	-- 13 +2600
	16000,	-- 14 + 3000
	19500,	-- 15 + 3500
	23500,	-- 16 + 4000
	28000,	-- 17 + 4500
	33000,	-- 18 + 5000
	38500,	-- 19 + 5500
	44500,	-- 20 + 6000
	50500,	-- 21 + 6000
	56500,	-- 22 + 6000
	62500,	-- 23 + 6000
	68500,	-- 24 + 6000
	74500,	-- 25 + 6000
	80500,	-- 26 + 6000
	86500,	-- 27 + 6000
	92500,	-- 28 + 6000
	100500,	-- 29 + 6000
	106500	-- 30 + 6000
}

function GameMode:InitGameMode()
	GameMode = self
	mode = GameRules:GetGameModeEntity()

	GameMode.ItemKVs = LoadKeyValues("scripts/npc/npc_items_custom.txt")

	-- Timer Rules
	GameRules:SetPostGameTime(30.0)
	GameRules:SetTreeRegrowTime(240.0)
	GameRules:SetHeroSelectionTime(0.0) --This is not dota bitch
	GameRules:SetGoldTickTime(0.0) --This is not dota bitch
	GameRules:SetGoldPerTick(0.0) --This is not dota bitch
	GameRules:SetCustomGameSetupAutoLaunchDelay(20.0) --Vote Time

	-- Boolean Rules
	GameRules:SetUseCustomHeroXPValues(true)
	GameRules:SetUseBaseGoldBountyOnHeroes(false)
	GameRules:SetHeroRespawnEnabled(true)
	mode:SetUseCustomHeroLevels(true)
	mode:SetRecommendedItemsDisabled(true)
	mode:SetTopBarTeamValuesOverride(true)
	mode:SetTopBarTeamValuesVisible(true)
	mode:SetUnseenFogOfWarEnabled(false)
	mode:SetBuybackEnabled(false)
	mode:SetBotThinkingEnabled(false)
	mode:SetTowerBackdoorProtectionEnabled(false)
	mode:SetFogOfWarDisabled(false)
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
	SetTeamCustomHealthbarColor(DOTA_TEAM_CUSTOM_3, 0, 180, 200) --Cyan
	SetTeamCustomHealthbarColor(DOTA_TEAM_CUSTOM_4, 0, 150, 60) --Green

	mode:SetCustomGameForceHero("npc_dota_hero_wisp")
	GameRules:SetPreGameTime(PREGAMETIME)
--	mode:SetStashPurchasingDisabled(true)
	GameRules:LockCustomGameSetupTeamAssignment(true)
	GameRules:SetHeroRespawnEnabled(true)
	mode:SetFixedRespawnTime(RESPAWN_TIME)
	GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS, 8)
	GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_BADGUYS, 0)
	GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_CUSTOM_1, 0)
	GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_CUSTOM_3, 0)
	GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_CUSTOM_4, 0)
	mode:SetCustomXPRequiredToReachNextLevel( XP_PER_LEVEL_TABLE )

	-- Lua Modifiers
	LinkLuaModifier("modifier_earthquake_aura", "heroes/hero_brewmaster", LUA_MODIFIER_MOTION_NONE)

	GameMode:_InitGameMode()
	self:OnFirstPlayerLoaded()

	GameRules:GetGameModeEntity():SetThink( "OnThink", self, 1 )

	self.countdownEnabled = false

--	Convars:RegisterCommand("duel_event", function(keys) return DuelEvent() end, "Test Duel Event", FCVAR_CHEAT)
--	Convars:RegisterCommand("magtheridon", function(keys) return StartMagtheridonArena(keys) end, "Test Magtheridon Boss", FCVAR_CHEAT)

	mode:SetExecuteOrderFilter(Dynamic_Wrap(GameMode, "FilterExecuteOrder"), self)
	mode:SetDamageFilter(Dynamic_Wrap(GameMode, "FilterDamage"), self)

	CustomGameEventManager:RegisterListener("toggle_dual_hero", Dynamic_Wrap(GameMode, "DualHero"))
	CustomGameEventManager:RegisterListener("event_hero_image", Dynamic_Wrap(GameMode, "HeroImage"))
	CustomGameEventManager:RegisterListener("event_all_hero_images", Dynamic_Wrap(GameMode, "AllHeroImages"))
	CustomGameEventManager:RegisterListener("event_spirit_beast", Dynamic_Wrap(GameMode, "SpiritBeast"))
	CustomGameEventManager:RegisterListener("event_frost_infernal", Dynamic_Wrap(GameMode, "FrostInfernal"))
	CustomGameEventManager:RegisterListener("quit_event", Dynamic_Wrap(GameMode, "SpecialEventTPQuit2"))
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

		for category, pidVoteTable in pairs(votes) do
			-- Tally the votes into a new table
			local voteCounts = {}
			for pid, vote in pairs(pidVoteTable) do
				if not voteCounts[vote] then voteCounts[vote] = 0 end
				voteCounts[vote] = voteCounts[vote] + 1
			end

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
			if category == "creep_lanes" then
				CREEP_LANES_TYPE = highest_key
			end
			if category == "dual_hero" then
				DUAL_HERO = highest_key
			end
			print(category .. ": " .. highest_key)
		end
	end

	if newState == DOTA_GAMERULES_STATE_PRE_GAME then
		self._fPreGameStartTime = GameRules:GetGameTime()
		nGAMETIMER = PREGAMETIME
		if nGAMETIMER == 10 then
			ChooseRandomHero(event)
		end
		for i = 1, 8 do
			DoEntFire("door_lane"..i, "SetAnimation", "close_idle", 0, nil, nil)
		end
		SpawnHeroesBis()
		GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_CUSTOM_3, 4)
		GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_CUSTOM_4, 4)

		if PlayerResource:GetPlayerCount() > 4 then
			CREEP_LANES_TYPE = 1
			FORCED_LANES = 1			
		end

		local diff = {"Easy", "Normal", "Hard", "Extreme"}
		local lanes = {"Simple", "Double", "Full"}
		local dual = {"Normal", "Dual"}
		Timers:CreateTimer(3.0, function()
			CustomGameEventManager:Send_ServerToAllClients("show_timer", {})
			Notifications:TopToAll({text="DIFFICULTY: "..diff[GameRules:GetCustomGameDifficulty()], duration=10.0})
			if FORCED_LANES == 0 then
				Notifications:TopToAll({text="CREEP LANES: "..lanes[CREEP_LANES_TYPE], duration=10.0})
			elseif FORCED_LANES == 1 then
				Notifications:TopToAll({text="CREEP LANES: SIMPLE, more than 4 players required to play Double Lanes!", duration=10.0})
			end
			Notifications:TopToAll({text="DUAL HERO: "..dual[DUAL_HERO], duration=10.0})
		end)
	end

	if newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		nCOUNTDOWNTIMER = 720
		nCOUNTDOWNCREEP = 360
		nCOUNTDOWNINCWAVE = 240
		nCOUNTDOWNEVENT = 1
		print("OnGameRulesStateChange: Game In Progress")
		self.countdownEnabled = true
	end
end

function GameMode:OnThink()	
local newState = GameRules:State_Get()
local Count = PlayerResource:GetPlayerCount()

if not reg then
	reg = 1
end

if not poi then
	poi = 1
end

local Region = {
		"Incoming wave of Darkness from the West",
		"Incoming wave of Darkness from the North",
		"Muradin Event in 30 sec",
		"Incoming wave of Darkness from the South",
		"Incoming wave of Darkness from the West",
		"Farming Event in 30 sec",
		"Incoming wave of Darkness from the East",
		"Incoming wave of Darkness from the South"
	}

	-- Stop thinking if game is paused
	if GameRules:IsGamePaused() == true then
		return 1
	end

	GameTimer()

	if newState == DOTA_GAMERULES_STATE_PRE_GAME then

	elseif newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		CountdownTimerMuradin()
		if SPECIAL_EVENT == 0 then
			CountdownTimerCreep()
			CountdownTimerIncomingWave()
			CountdownTimerSpecialEvents()
		end

		if PHASE_3 == 0 then
			if nGAMETIMER == 359 then -- 6 Min
				NumPlayers = 1, Count * CREEP_LANES_TYPE
				SpawnDragons("npc_dota_creature_red_dragon")
			end
			if nGAMETIMER == 839 then -- 12 Min
				NumPlayers = 1, Count * CREEP_LANES_TYPE
				SpawnDragons("npc_dota_creature_black_dragon")
			end
			if nGAMETIMER == 1079 then -- 18 Min
				NumPlayers = 1, Count * CREEP_LANES_TYPE
				SpawnDragons("npc_dota_creature_green_dragon")
			end

			-- Timer: Special Events
			if nGAMETIMER == 716 then -- 716 - 11:55 Min: MURADIN BRONZEBEARD EVENT 1
				nGAMETIMER = 720 -1
				nCOUNTDOWNCREEP = 360 +1
				nCOUNTDOWNINCWAVE = 240 --	+1
				RefreshPlayers()
				Timers:CreateTimer(1, function()
					SPECIAL_EVENT = 1
					PauseCreeps()
					PauseHeroes()
					Timers:CreateTimer(5, function()
						MuradinEvent()
						Timers:CreateTimer(3, RestartHeroes())
					end)
				end)
			end
			if nGAMETIMER == 1436 then -- 1436 - 23:55 Min: FARM EVENT 2
				nGAMETIMER = 1440 -1
				nCOUNTDOWNINCWAVE = 240 --	+1
				RefreshPlayers()
				Timers:CreateTimer(1, function()
					SPECIAL_EVENT = 1
					PauseCreeps()
					PauseHeroes()
					Timers:CreateTimer(5, function()
						FarmEvent()
						Timers:CreateTimer(3, RestartHeroes())
					end)
				end)
			end
		end

		if nCOUNTDOWNTIMER <= 0 then
			nCOUNTDOWNTIMER = 1
		end

		if nCOUNTDOWNCREEP <= 0 then
			nCOUNTDOWNCREEP = 1
		end

		if nCOUNTDOWNINCWAVE <= 0 then
			nCOUNTDOWNINCWAVE = 1
		elseif nCOUNTDOWNINCWAVE == 1 then
			Timers:CreateTimer(1.0, function()
				SpecialWave()
			end)
		elseif nCOUNTDOWNINCWAVE == 30 then
			Notifications:TopToAll({text="WARNING: "..Region[reg].."!", duration=25.0, style={color="red"}})
			SpawnRunes()
			reg = reg + 1
		elseif time_elapsed > 720 and time_elapsed < 870 then
			nCOUNTDOWNINCWAVE = 240
		elseif time_elapsed > 2140 then
			nCOUNTDOWNINCWAVE = 240
		end

		if nCOUNTDOWNEVENT < 1 then -- Keep timers to 0 before game starts
			nCOUNTDOWNEVENT = 1
		end
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
	CustomGameEventManager:Send_ServerToAllClients( "creepcountdown", broadcast_gametimer )
end

function CountdownTimerIncomingWave()
	nCOUNTDOWNEVENT = nCOUNTDOWNEVENT - 1
	local t = nCOUNTDOWNEVENT
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
	CustomGameEventManager:Send_ServerToAllClients( "incomingwavecountdown", broadcast_gametimer )
end

function CountdownTimerSpecialEvents()
	nCOUNTDOWNINCWAVE = nCOUNTDOWNINCWAVE - 1
	local t = nCOUNTDOWNINCWAVE
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
	CustomGameEventManager:Send_ServerToAllClients( "specialeventscountdown", broadcast_gametimer )
end

function GameTimer()
local newState = GameRules:State_Get()
	if newState == DOTA_GAMERULES_STATE_PRE_GAME then
		nGAMETIMER = nGAMETIMER - 1
	elseif newState == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		if SPECIAL_EVENT == 0 then
			nGAMETIMER = nGAMETIMER + 1
		end
	end
	local t = nGAMETIMER
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
	CustomGameEventManager:Send_ServerToAllClients("gametimer", broadcast_gametimer)
end

-- Item added to inventory filter
function GameMode:ItemAddedFilter(keys)
local hero = EntIndexToHScript(keys.inventory_parent_entindex_const)
local item = EntIndexToHScript(keys.item_entindex_const)
local item_name = 0
local key = "item_key_of_the_three_moons"
local shield = "item_shield_of_invincibility"
local sword = "item_lightning_sword"
local ring = "item_ring_of_superiority"
local doom = "item_doom_artifact"
local frost = "item_orb_of_frost"
local base = Entities:FindByName(nil, "base_spawn"):GetAbsOrigin()

if item:GetName() then
	item_name = item:GetName()
end

	if hero:IsRealHero() then
		if item_name == sword and sword_first_time then
			SPECIAL_EVENT = 0
			if timers.RameroAndBaristol then
				Timers:RemoveTimer(timers.RameroAndBaristol)
			end
			RestartCreeps()
			sword_first_time = false
				if hero.old_pos then
					FindClearSpaceForUnit(hero, hero.old_pos, true)
				else
					FindClearSpaceForUnit(hero, base, true)
				end
				PlayerResource:SetCameraTarget(hero:GetPlayerID(), hero)
				hero:EmitSound("Hero_TemplarAssassin.Trap")
				Timers:CreateTimer(0.1, function()
					PlayerResource:SetCameraTarget(hero:GetPlayerID(), nil)
				end)
		end
		if item_name == ring and ring_first_time then
			SPECIAL_EVENT = 0
			if timers.Ramero then
				Timers:RemoveTimer(timers.Ramero)
			end
			RestartCreeps()
			ring_first_time = false
			if hero.old_pos then
				FindClearSpaceForUnit(hero, hero.old_pos, true)
			else
				FindClearSpaceForUnit(hero, base, true)
			end
			PlayerResource:SetCameraTarget(hero:GetPlayerID(), hero)
			hero:EmitSound("Hero_TemplarAssassin.Trap")
			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(hero:GetPlayerID(), nil)
			end)
		end
		if item_name == frost and frost_first_time then
			frost_first_time = false
			if hero.old_pos then
				FindClearSpaceForUnit(hero, hero.old_pos, true)
			else
				FindClearSpaceForUnit(hero, base, true)
			end
			PlayerResource:SetCameraTarget(hero:GetPlayerID(), hero)
			hero:EmitSound("Hero_TemplarAssassin.Trap")
			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(hero:GetPlayerID(), nil)
			end)
		elseif item_name == frost and frost_first_time == false then
			return false
		end

		if item_name == key then
			hero.has_epic_1 = true
			hero:EmitSound("Hero_TemplarAssassin.Trap")
		end

		if item_name == shield then
			hero.has_epic_2 = true
			hero:EmitSound("Hero_TemplarAssassin.Trap")
		end

		if item_name == sword then
			hero.has_epic_3 = true
			hero:EmitSound("Hero_TemplarAssassin.Trap")
		end

		if item_name == ring then
			hero.has_epic_4 = true
			hero:EmitSound("Hero_TemplarAssassin.Trap")
		end

		if item_name == doo and doom_first_time then
			doom_first_time = false
			hero:EmitSound("Hero_TemplarAssassin.Trap")
			local line_duration = 10
			Notifications:TopToAll({hero = hero:GetName(), duration = line_duration})
--			Notifications:TopToAll({text = hero:GetUnitName().." ", duration = line_duration, continue = true})
			Notifications:TopToAll({text = PlayerResource:GetPlayerName(hero:GetPlayerID()).." ", duration = line_duration, continue = true})
			Notifications:TopToAll({text = "merged the 4 Boss items to create Doom Artifact!", duration = line_duration, style = {color = "Red"}, continue = true})
		elseif item_name == doom and frost_first_time == false then
			return false
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

	if damagetype == DAMAGE_TYPE_PHYSICAL then
		if attacker:IsHero() then
			if attacker:GetUnitName() == "npc_dota_hero_nevermore" then
				print("Damage dealt: "..filterTable["damage"])
				local value = filterTable["damage"] --Post reduction
				local damage, reduction = GameMode:GetPreMitigationDamage(value, victim, attacker, damagetype) --Pre reduction
				local attack_damage = damage
				local armor = victim:GetPhysicalArmorValue()

--				damage = (attack_damage * (1 - reduction)) * multiplier
				filterTable["damage"] = damage
				print("Damage dealt 2: "..damage)
			end
		else
		end
	end

--	if attacker:IsHero() then
--		local intMultiplierDota = 1+((attacker:GetIntellect()/16)/100)
--		local intMultiplierNew = (1+((attacker:GetIntellect()/16)/100)+0.5)
--		if damagetype == DAMAGE_TYPE_MAGICAL or damagetype == DAMAGE_TYPE_PURE then
--			filterTable["damage"] = filterTable["damage"]/(intMultiplierDota)	-- Disable spell amp
--			filterTable["damage"] = (filterTable["damage"]/intMultiplierDota)*intMultiplierNew		-- re-enable
--			print("FILTER DAMAGE:"..damage.." Magical or Pure Hero Damage detected!")
--		end
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

function GameMode:GetPreMitigationDamage(value, victim, attacker, damagetype)
	if damagetype == DAMAGE_TYPE_PHYSICAL then
		local armor = victim:GetPhysicalArmorValue()
		local reduction = (armor*0.06) / (1+0.06*armor)
		local damage = value / (1 - reduction)
		
		return damage, reduction

--	elseif damagetype == DAMAGE_TYPE_MAGICAL then
--		local reduction = victim:GetMagicalArmorValue()*0.01
--		local damage = value / (1 - reduction)

--		return damage, reduction
--	else
--		print("PRE MITIGATION: Other")
--		return value, 0
	end
end

function RefreshPlayers()
	for nPlayerID = 0, DOTA_MAX_TEAM_PLAYERS -1 do
		if PlayerResource:GetTeam(nPlayerID) == DOTA_TEAM_GOODGUYS then
			if PlayerResource:HasSelectedHero(nPlayerID) then
				local hero = PlayerResource:GetSelectedHeroEntity(nPlayerID)
				if not hero:IsAlive() then
					hero:RespawnHero(false, false, false)
					hero.ankh_respawn = false
					hero:SetRespawnsDisabled(false)
					if hero.respawn_timer ~= nil then
						Timers:RemoveTimer(hero.respawn_timer)
						hero.respawn_timer = nil
					end
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

--	if order_type == DOTA_UNIT_ORDER_CAST_TARGET then
--		if target:GetTeam() ~= caster:GetTeam() then
--			if target:TriggerSpellAbsorb(ability) then
--				return
--			end
--		end
--	return true
--	end

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
--		elseif not Corpses:AreAnyInRadius(playerID, unit:GetAbsOrigin(), corpseRadius) then
--			if not Corpses:AreAnyInRadius(playerID, unit:GetAbsOrigin(), corpseRadius) then
--				Notifications:Bottom(playerID, {text="No corpses near!", duration=5.0, style={color="white"}})
--				return false
--			end
--		end
	end

	if order_type == DOTA_UNIT_ORDER_PURCHASE_ITEM then
		if SPECIAL_EVENT == 1 then
			return false
		else
			return true
		end
	end

	return true
end

caster_cooldowns = {}

function GameMode:DualHero(event)
local PlayerID = event.pID
local player = PlayerResource:GetPlayer(PlayerID)
local hero = player:GetAssignedHero()
local gold = hero:GetGold()
local loc = hero:GetAbsOrigin()
local Strength = hero:GetBaseStrength()
local Intellect = hero:GetBaseIntellect()
local Agility = hero:GetBaseAgility()
local HP = hero:GetMaxHealth() * hero:GetHealthPercent() / 100
local Mana = hero:GetMaxMana() * hero:GetManaPercent() / 100
local AbPoints = hero:GetAbilityPoints()
CURRENT_XP = hero:GetCurrentXP()

	if hero:IsAlive() and not hero:IsStunned() and not GameRules:IsGamePaused() then
		if hero:GetUnitName() == DUAL_HERO_2[PlayerID] then
			NewHero = PlayerResource:ReplaceHeroWith(PlayerID, DUAL_HERO_1[PlayerID], gold, 0)
		elseif hero:GetUnitName() == DUAL_HERO_1[PlayerID] then
			NewHero = PlayerResource:ReplaceHeroWith(PlayerID, DUAL_HERO_2[PlayerID], gold, 0)
		end

		local cooldowns_caster = {}
		for i = 0, 5 do
		caster_ability = hero:GetAbilityByIndex(i)
		hero_ability = NewHero:GetAbilityByIndex(i)
			if IsValidEntity(caster_ability) then
				if i == 4 then -- Ignores Innate Ability
				else
					hero_ability:SetLevel(caster_ability:GetLevel())
				end
				cooldowns_caster[i] = caster_ability:GetCooldownTimeRemaining()
				hero_ability:StartCooldown(cooldowns_caster[i])
			end
		end

		local items = {}
		for i = 0, 8 do
			if hero:GetItemInSlot(i) ~= nil and hero:GetItemInSlot(i):GetName() ~= "item_classchange_reset" then
				itemCopy = CreateItem(hero:GetItemInSlot(i):GetName(), nil, nil)
				items[i] = itemCopy
			end
		end

		for i = 0, 8 do
			if items[i] ~= nil then
				NewHero:AddItem(items[i])
				items[i]:SetCurrentCharges(hero:GetItemInSlot(i):GetCurrentCharges())
			end
		end

		NewHero:AddExperience(CURRENT_XP, false, false)
		NewHero:SetAbsOrigin(loc)
		NewHero:SetBaseStrength(Strength)
		NewHero:SetBaseIntellect(Intellect)
		NewHero:SetBaseAgility(Agility)
		NewHero:SetHealth(HP)
		NewHero:SetMana(Mana)
		NewHero:SetAbilityPoints(AbPoints)

		Timers:CreateTimer(1.0, function()
			if not hero:IsNull() then
				UTIL_Remove(hero)
			end
		end)
	else
		Notifications:Bottom(hero:GetPlayerOwnerID(), {text="You can not Swap Hero at the moment!", duration = 5.0, style={color="red"}})
	end
end

function GameMode:HeroImage(event)
local PlayerID = event.pID
local player = PlayerResource:GetPlayer(PlayerID)
local hero = player:GetAssignedHero()
local point_hero = Entities:FindByName(nil, "hero_image_player"):GetAbsOrigin()
local point_beast = Entities:FindByName(nil, "hero_image_boss"):GetAbsOrigin()

	if GameMode.HeroImage_occuring == 1 then
		GameMode:SpecialEventTPQuit(hero)
		Notifications:Bottom(hero:GetPlayerOwnerID(),{text = "Hero Image is already occuring, please choose another event.", duration = 7.5})
	end

	if not hero.hero_image and GameMode.HeroImage_occuring == 0 then
		SpecialEventsTimer()
		GameMode.HeroImage_occuring = 1
		Entities:FindByName(nil, "trigger_special_event_back4"):Enable()

		PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
		Timers:CreateTimer(0.1, function()
			PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil) 
		end)

		GameMode.HeroImage = CreateUnitByName(hero:GetUnitName(), point_beast, true, nil, nil, DOTA_TEAM_CUSTOM_1)
		GameMode.HeroImage:SetAngles(0, 210, 0)
		GameMode.HeroImage:SetBaseStrength(hero:GetBaseStrength()*4)
		GameMode.HeroImage:SetBaseIntellect(hero:GetBaseIntellect()*4)
		GameMode.HeroImage:SetBaseAgility(hero:GetBaseAgility()*4)
		GameMode.HeroImage:AddNewModifier(nil, nil, "modifier_boss_stun", {Duration = 5,IsHidden = true})
		GameMode.HeroImage:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 5,IsHidden = true})
		GameMode.HeroImage:MakeIllusion()
		GameMode.HeroImage:AddAbility("hero_image_death")
		local ability = GameMode.HeroImage:FindAbilityByName("hero_image_death")
		ability:ApplyDataDrivenModifier(GameMode.HeroImage, GameMode.HeroImage, "modifier_hero_image", {})

		if IsValidEntity(hero) then
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				GameMode:SpecialEventTPQuit(hero)
				Notifications:Bottom(hero:GetPlayerOwnerID(), {text = "Special Event: Kill Hero Image for +250 Stats. You have 2 minutes.", duration = 5.0})					
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
				Timers:CreateTimer(0.1, function()
					PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil) 
				end)

				if hero:GetUnitName() == "npc_dota_hero_meepo" then
				local meepo_table = Entities:FindAllByName("npc_dota_hero_meepo")
					if meepo_table then
						for i = 1, #meepo_table do
							FindClearSpaceForUnit(meepo_table[i], point_hero, false)
							meepo_table[i]:Stop()
							PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), hero)
							Timers:CreateTimer(0.1, function()
								PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), nil) 
							end)
						end
					end
				else
					FindClearSpaceForUnit(hero, point_hero, true)
					hero:Stop()
				end
			end
		end

		local ability = hero:FindAbilityByName("holdout_blink")
		if ability then
			ability:StartCooldown(120.0)
		end
		for itemSlot = 0, 5 do
		local item = hero:GetItemInSlot(itemSlot)
			if item ~= nil and item:GetName() == "item_tome_small" then
				item:StartCooldown(120.0)
			end
			if item ~= nil and item:GetName() == "item_tome_big" then
				item:StartCooldown(120.0)
			end
			if item ~= nil and item:GetName() == "item_boots_of_speed" then
				item:StartCooldown(120.0)
			end
			if item ~= nil and item:GetName() == "item_tpscroll" then
				item:StartCooldown(120.0)
			end
		end

		timers.HeroImage = Timers:CreateTimer(120.0,function()
			Entities:FindByName(nil, "trigger_hero_image_duration"):Enable()
			GameMode.SpiritBeast_occuring = 0

			Timers:CreateTimer(5.5, function() --Debug time in case Hero Image kills the player at the very last second
				Entities:FindByName(nil, "trigger_hero_image_duration"):Disable()
			end)
			if not GameMode.HeroImage:IsNull() then
				GameMode.HeroImage:RemoveSelf()
			else
			end
		end)
	elseif hero.hero_image then
		Notifications:Bottom(hero:GetPlayerOwnerID(), {text = "You can do hero image only once!", duration = 5.0})
	end
end

function GameMode:AllHeroImages(event)
local PlayerID = event.pID
local player = PlayerResource:GetPlayer(PlayerID)
local hero = player:GetAssignedHero()
local point_hero = Entities:FindByName(nil, "all_hero_image_player"):GetAbsOrigin()

	if GameMode.AllHeroImages_occuring == 1 then
		GameMode:SpecialEventTPQuit(hero)
		Notifications:Bottom(hero:GetPlayerOwnerID(),{text = "All Hero Images is already occuring, please choose another event.", duration = 7.5})
	elseif GameMode.AllHeroImages_occuring == 0 then
		SpecialEventsTimer()
		GameMode.AllHeroImages_occuring = 1
		Entities:FindByName(nil, "trigger_special_event_back5"):Enable()

		PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
		Timers:CreateTimer(0.1, function()
			PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil) 
		end)

		local illusion_spawn = 0
		Timers:CreateTimer(0.25, function()
			local random = RandomInt(1, #HEROLIST)
			illusion_spawn = illusion_spawn + 1
			local point_image = Entities:FindByName(nil, "special_event_all_"..illusion_spawn)
			GameMode.AllHeroImage = CreateUnitByName("npc_dota_hero_"..HEROLIST[random], point_image:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
			GameMode.AllHeroImage:SetAngles(0, 45 - 45 * illusion_spawn, 0)
			GameMode.AllHeroImage:SetBaseStrength(hero:GetBaseStrength()*2)
			GameMode.AllHeroImage:SetBaseIntellect(hero:GetBaseIntellect()*2)
			GameMode.AllHeroImage:SetBaseAgility(hero:GetBaseAgility()*2)
			GameMode.AllHeroImage:AddNewModifier(nil, nil, "modifier_boss_stun", {Duration = 5,IsHidden = true})
			GameMode.AllHeroImage:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 5,IsHidden = true})
			GameMode.AllHeroImage:MakeIllusion()
			GameMode.AllHeroImage:AddAbility("all_hero_image_death")
			local ability = GameMode.AllHeroImage:FindAbilityByName("all_hero_image_death")
			ability:ApplyDataDrivenModifier(GameMode.AllHeroImage, GameMode.AllHeroImage, "modifier_hero_image", {})

			if illusion_spawn < 8 then
				return_time = 0.25
			else
				return_time = nil
			end

			return return_time
		end)

		if IsValidEntity(hero) then
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				GameMode:SpecialEventTPQuit(hero)
				Notifications:Bottom(hero:GetPlayerOwnerID(), {text = "Special Event: Kill All Heroes for Necklace of Immunity. You have 2 minutes.", duration = 5.0})
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
				Timers:CreateTimer(0.1, function()
					PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil) 
				end)

				if hero:GetUnitName() == "npc_dota_hero_meepo" then
				local meepo_table = Entities:FindAllByName("npc_dota_hero_meepo")
					if meepo_table then
						for i = 1, #meepo_table do
							FindClearSpaceForUnit(meepo_table[i], point_hero, false)
							meepo_table[i]:Stop()
							PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), hero)
							Timers:CreateTimer(0.1, function()
								PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), nil) 
							end)
						end
					end
				else
					FindClearSpaceForUnit(hero, point_hero, true)
					hero:Stop()
				end
			end
		end

		local ability = hero:FindAbilityByName("holdout_blink")
		if ability then
			ability:StartCooldown(120.0)
		end
		for itemSlot = 0, 5 do
		local item = hero:GetItemInSlot(itemSlot)
			if item ~= nil and item:GetName() == "item_tome_small" then
				item:StartCooldown(120.0)
			end
			if item ~= nil and item:GetName() == "item_tome_big" then
				item:StartCooldown(120.0)
			end
			if item ~= nil and item:GetName() == "item_boots_of_speed" then
				item:StartCooldown(120.0)
			end
			if item ~= nil and item:GetName() == "item_tpscroll" then
				item:StartCooldown(120.0)
			end
		end

		timers.AllHeroImage = Timers:CreateTimer(120.0, function()
			Entities:FindByName(nil, "trigger_all_hero_image_duration"):Enable()
			GameMode.AllHeroImages_occuring = 0

			Timers:CreateTimer(5.5, function() --Debug time in case Frost Infernal kills the player at the very last second
				Entities:FindByName(nil, "trigger_all_hero_image_duration"):Disable()
			end)
			
			local units = FindUnitsInRadius( DOTA_TEAM_CUSTOM_1, point_hero, nil, 2000, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE , FIND_ANY_ORDER, false )
			for _, v in pairs(units) do
				UTIL_Remove(v)
			end
		end)
	elseif GameMode.AllHeroImagesDead == 1 then
		Notifications:Bottom(hero:GetPlayerOwnerID(), {text = "All Hero Image has already been done!", duration = 5.0})
	end
end

function GameMode:SpiritBeast(event)
local PlayerID = event.pID
local player = PlayerResource:GetPlayer(PlayerID)
local hero = player:GetAssignedHero()
local point_hero = Entities:FindByName(nil, "spirit_beast_player"):GetAbsOrigin()
local point_beast = Entities:FindByName(nil, "spirit_beast_boss"):GetAbsOrigin()

	if GameMode.SpiritBeast_occuring == 1 then
		GameMode:SpecialEventTPQuit(hero)
		Notifications:Bottom(hero:GetPlayerOwnerID(),{text = "Spirit Beast is already occuring, please choose another event.", duration = 7.5})
	elseif GameMode.SpiritBeast_killed == 0 then
		GameMode.SpiritBeast_occuring = 1
		SpecialEventsTimer()
		Entities:FindByName(nil, "trigger_special_event_back3"):Enable()

		PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
		Timers:CreateTimer(0.1, function()
			PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil) 
		end)

		timers.SpiritBeast = Timers:CreateTimer(120.0,function()
			Entities:FindByName(nil, "trigger_spirit_beast_duration"):Enable()
			GameMode.SpiritBeast_occuring = 0
			GameMode.spirit_beast:RemoveSelf()

			Timers:CreateTimer(5.5, function() --Debug time in case Spirit Beast kills the player at the very last second
				Entities:FindByName(nil, "trigger_spirit_beast_duration"):Disable()
			end)
		end)

		GameMode.spirit_beast = CreateUnitByName("npc_spirit_beast", point_beast, true, nil, nil, DOTA_TEAM_CUSTOM_1)
		GameMode.spirit_beast:SetAngles(0, 210, 0)
		GameMode.spirit_beast:AddNewModifier(nil, nil, "modifier_animation_freeze_stun", {Duration = 5,IsHidden = true})
		GameMode.spirit_beast:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 5,IsHidden = true})

		if IsValidEntity(hero) then
			GameMode:SpecialEventTPQuit(hero)
			Notifications:Bottom(hero:GetPlayerOwnerID(), {text = "Special Event: Kill Spirit Beast for the Shield of Invincibility. You have 2 minutes.", duration = 5.0})
			PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
			Timers:CreateTimer(0.1, function()
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil) 
			end)

			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				if hero:GetUnitName() == "npc_dota_hero_meepo" then
				local meepo_table = Entities:FindAllByName("npc_dota_hero_meepo")
					if meepo_table then
						for i = 1, #meepo_table do
							FindClearSpaceForUnit(meepo_table[i], point_hero, false)
							meepo_table[i]:Stop()
							PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), hero)
							Timers:CreateTimer(0.1, function()
								PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), nil) 
							end)
						end
					end
				else
					FindClearSpaceForUnit(hero,point_hero, true)
					hero:Stop()
				end
			end
		end

		local ability = hero:FindAbilityByName("holdout_blink")
		if ability then
			ability:StartCooldown(120.0)
		end
		for itemSlot = 0, 5 do
		local item = hero:GetItemInSlot(itemSlot)
			if item ~= nil and item:GetName() == "item_tome_small" then
				item:StartCooldown(120.0)
			end
			if item ~= nil and item:GetName() == "item_tome_big" then
				item:StartCooldown(120.0)
			end
			if item ~= nil and item:GetName() == "item_boots_of_speed" then
				item:StartCooldown(120.0)
			end
			if item ~= nil and item:GetName() == "item_tpscroll" then
				item:StartCooldown(120.0)
			end
		end
	elseif GameMode.SpiritBeast_killed == 1 then
		Notifications:Bottom(hero:GetPlayerOwnerID(), {text = "Spirit Beast has already been killed!", duration = 5.0})
	end
end

function GameMode:FrostInfernal(event)
local PlayerID = event.pID
local player = PlayerResource:GetPlayer(PlayerID)
local hero = player:GetAssignedHero()
local point_hero = Entities:FindByName(nil, "frost_infernal_player"):GetAbsOrigin()
local point_beast = Entities:FindByName(nil, "frost_infernal_boss"):GetAbsOrigin()

	if GameMode.FrostInfernal_occuring == 1 then
		GameMode:SpecialEventTPQuit(hero)
		Notifications:Bottom(hero:GetPlayerOwnerID(),{text = "Frost Infernal is already occuring, please choose another event.", duration = 7.5})
	elseif GameMode.FrostInfernal_killed == 0 then
		GameMode.FrostInfernal_occuring = 1
		SpecialEventsTimer()
		Entities:FindByName(nil, "trigger_special_event_back2"):Enable()

		timers.FrostInfernal = Timers:CreateTimer(120.0,function()
			Entities:FindByName(nil, "trigger_frost_infernal_duration"):Enable()
			GameMode.FrostInfernal_occuring = 0
			GameMode.frost_infernal:RemoveSelf()

			Timers:CreateTimer(5.5, function() --Debug time in case Frost Infernal kills the player at the very last second
				Entities:FindByName(nil, "trigger_frost_infernal_duration"):Disable()
			end)
		end)

		GameMode.frost_infernal = CreateUnitByName("npc_frost_infernal", point_beast, true, nil, nil, DOTA_TEAM_CUSTOM_1)
		GameMode.frost_infernal:SetAngles(0, 210, 0)
		GameMode.frost_infernal:AddNewModifier(nil, nil, "modifier_animation_freeze_stun", {Duration = 5, IsHidden = true})
		GameMode.frost_infernal:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 5, IsHidden = true})

		GameMode:SpecialEventTPQuit(hero)
		Notifications:Bottom(hero:GetPlayerOwnerID(),{text = "Special Event: Kill Frost Infernal for the Key of the 3 Moons. You have 2 minutes.", duration = 5.0})
		PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), hero)
		Timers:CreateTimer(0.1, function()
			PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), nil) 
		end)

		if IsValidEntity(hero) then
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				if hero:GetUnitName() == "npc_dota_hero_meepo" then
				local meepo_table = Entities:FindAllByName("npc_dota_hero_meepo")
					if meepo_table then
						for i = 1, #meepo_table do
							FindClearSpaceForUnit(meepo_table[i], point_hero, false)
							meepo_table[i]:RemoveModifierByName("modifier_animation_freeze_stun")
							PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), hero)
							Timers:CreateTimer(0.1, function()
								PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), nil) 
							end)
						end
					end
				else
					FindClearSpaceForUnit(hero, point_hero, true)
				end
			end
		end

		local ability = hero:FindAbilityByName("holdout_blink")
		if ability then
			ability:StartCooldown(120.0)
		end
		for itemSlot = 0, 5 do
		local item = hero:GetItemInSlot(itemSlot)
			if item ~= nil and item:GetName() == "item_tome_small" then
				item:StartCooldown(120.0)
			end
			if item ~= nil and item:GetName() == "item_tome_big" then
				item:StartCooldown(120.0)
			end
			if item ~= nil and item:GetName() == "item_boots_of_speed" then
				item:StartCooldown(120.0)
			end
			if item ~= nil and item:GetName() == "item_tpscroll" then
				item:StartCooldown(120.0)
			end
		end
	else
		Notifications:Bottom(hero:GetPlayerOwnerID(), {text = "Frost Infernal has already been killed!", duration = 5.0})
	end
end

function GameMode:SpecialEventTPQuit(hero)
	CustomGameEventManager:Send_ServerToPlayer(hero:GetPlayerOwner(), "quit_events", {})
	
	hero:RemoveModifierByName("modifier_boss_stun")
	hero:RemoveModifierByName("modifier_invulnerable")
	hero:Stop()
end

function GameMode:SpecialEventTPQuit2(event)
local PlayerID = event.pID
local player = PlayerResource:GetPlayer(PlayerID)
local hero = player:GetAssignedHero()

	hero:RemoveModifierByName("modifier_boss_stun")
	hero:RemoveModifierByName("modifier_invulnerable")
	hero:Stop()

	Timers:CreateTimer(3.0, function()
		Entities:FindByName(nil, "trigger_special_event"):Enable()
	end)
end
