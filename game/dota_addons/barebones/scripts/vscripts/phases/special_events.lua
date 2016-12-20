require('libraries/timers')

function MuradinEvent() -- 12 Min, lasts 2 Min.
local teleporters = Entities:FindAllByName("trigger_teleport_muradin_end")
local heroes = HeroList:GetAllHeroes()
nCOUNTDOWNTIMER = 121

	local Muradin = CreateUnitByName("npc_dota_creature_muradin_bronzebeard", Entities:FindByName(nil, "npc_dota_muradin_boss"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
	Muradin:AddNewModifier( nil, nil, "modifier_boss_stun", {duration = 5})
	Muradin:AddNewModifier( nil, nil, "modifier_invulnerable", {duration = 5})
	Muradin:SetAngles(0, 270, 0)
--	Muradin:EmitSound("Muradin.StormEarthFire")
	Muradin:EmitSound("SantaClaus.StartArena")
	Notifications:TopToAll({hero="npc_dota_hero_zuus", duration=5.0})
	Notifications:TopToAll({text=" You can't kill him! Just survive the Countdown. ", continue=true})
	Notifications:TopToAll({text="Reward: 15 000 Gold.", continue=true})

	for _,hero in pairs(heroes) do
	local id = hero:GetPlayerID()
	local point = Entities:FindByName(nil,"npc_dota_muradin_player_"..id)
		FindClearSpaceForUnit(hero, point:GetAbsOrigin(), true)
		PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), hero)
		Timers:CreateTimer(0.1, function()
			PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), nil)
		end)
	end

	Timers:CreateTimer(120, function() -- 14:00 Min, teleport back to the spawn
		for _,v in pairs(teleporters) do
			v:Enable()
		end

		UTIL_Remove(Muradin)
		nCOUNTDOWNTIMER = 600
	end)

	Timers:CreateTimer(126, function() -- 14:05 Min: MURADIN BRONZEBEARD EVENT 1, END
		Notifications:TopToAll({text="All heroes who survived Muradin received 15 000 Gold!", duration=6.0})
		Notifications:TopToAll({ability="alchemist_goblins_greed", continue=true})
		for _,v in pairs(teleporters) do
			v:Disable()
		end
	end)
end

function EndMuradinEvent(keys)
	local activator = keys.activator
	local point = Entities:FindByName(nil,"base_spawn"):GetAbsOrigin()

	if activator:GetTeam() == DOTA_TEAM_GOODGUYS then
	FindClearSpaceForUnit(activator, point, true)
	PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(), activator)
	Timers:CreateTimer(0.1, function()
		PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(), nil)
	end)
	activator:Stop()
	PlayerResource:ModifyGold( activator:GetPlayerOwnerID(), 15000, false,  DOTA_ModifyGold_Unspecified )
	end
end

function FarmEvent() -- 24 Min, lasts 3 Min.
local heroes = HeroList:GetAllHeroes()
nCOUNTDOWNTIMER = 180
nCOUNTDOWNCREEP = 1
nCOUNTDOWNINCWAVE = 1
NEUTRAL_SPAWN = 1
BT_ENABLED = 0

	Notifications:TopToAll({hero="npc_dota_hero_alchemist", duration=5.0})
	Notifications:TopToAll({text=" It's farming time! Kill as much creeps as you can!", continue = true})

	for _,hero in pairs(heroes) do
		local id = hero:GetPlayerID()
		local point = Entities:FindByName(nil, "farm_event_player_"..id)

		if id == 0 then
			for j = 1, 5 do
				FindClearSpaceForUnit(hero, point:GetAbsOrigin(), true)
				PlayerResource:SetCameraTarget(hero:GetPlayerID(), hero)
--				hero:EmitSound("Muradin.StormEarthFire") --Very loud, can't find why
				local unit = CreateUnitByName("npc_dota_creature_murloc", point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		elseif id == -1 then
			return nil
		else
			for j = 1, 5 do
				FindClearSpaceForUnit(hero, point:GetAbsOrigin(), true)
				PlayerResource:SetCameraTarget(hero:GetPlayerID(), hero)
--				hero:EmitSound("Muradin.StormEarthFire")
				local unit = CreateUnitByName("npc_dota_creature_murloc", point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		end

		Farm0 = Timers:CreateTimer(0.1, FarmEventCreeps0)
		Farm1 = Timers:CreateTimer(0.1, FarmEventCreeps1)
		Farm2 = Timers:CreateTimer(0.1, FarmEventCreeps2)
		Farm3 = Timers:CreateTimer(0.1, FarmEventCreeps3)
		Farm4 = Timers:CreateTimer(0.1, FarmEventCreeps4)
		Farm5 = Timers:CreateTimer(0.1, FarmEventCreeps5)
		Farm6 = Timers:CreateTimer(0.1, FarmEventCreeps6)
		Farm7 = Timers:CreateTimer(0.1, FarmEventCreeps7)

		Timers:CreateTimer(0.1, function()
			PlayerResource:SetCameraTarget(hero:GetPlayerID(), nil)
		end)
	end

	Timers:CreateTimer(180, function() -- 27:00 Min, teleport back to the spawn
	local units = FindUnitsInRadius( DOTA_TEAM_BADGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE , FIND_ANY_ORDER, false )
	local teleporters = Entities:FindAllByName("trigger_farm_event")

		nCOUNTDOWNCREEP = 180
		nCOUNTDOWNINCWAVE = 240
		NEUTRAL_SPAWN = 0
		BT_ENABLED = 1

		for _,v in pairs(teleporters) do
			v:Enable()
		end

		Timers:CreateTimer(0.1, function()
			for _,v in pairs(units) do
				v:ForceKill(false)
			end
		end)
	end)
end

function EndFarmEvent(keys)
local activator = keys.activator
local point = Entities:FindByName(nil,"base_spawn"):GetAbsOrigin()

	if activator:GetTeam() == DOTA_TEAM_GOODGUYS then
	FindClearSpaceForUnit(activator, point, true)
	PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(), activator)
	Timers:CreateTimer(0.1, function()
		PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(), nil)
	end)
	activator:Stop()
	end
end

function FarmEventCreeps0()
local point = Entities:FindByName(nil, "farm_event_player_0")
local units = FindUnitsInRadius(DOTA_TEAM_BADGUYS, point:GetAbsOrigin(), nil, 1500, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
local number0 = 0

	for _,v in pairs(units) do
		number0 = number0 +1
	end

	if number0 <= 1 and PlayerResource:GetPlayerCount() >= 1 and NEUTRAL_SPAWN == 1 then
		for j = 1, 10 do
			local unit = CreateUnitByName("npc_dota_creature_murloc", point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
		end
	end
	return 1
end

function FarmEventCreeps1()
local point = Entities:FindByName(nil, "farm_event_player_1")
local units = FindUnitsInRadius(DOTA_TEAM_BADGUYS, point:GetAbsOrigin(), nil, 1500, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
local number1 = 0

	for _,v in pairs(units) do
		number1 = number1 +1
	end

	if number1 <= 1 and PlayerResource:GetPlayerCount() >= 2 and NEUTRAL_SPAWN == 1 then
		for j = 1, 10 do
			local unit = CreateUnitByName("npc_dota_creature_murloc", point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
		end
	end
	return 1
end

function FarmEventCreeps2()
local point = Entities:FindByName(nil, "farm_event_player_2")
local units = FindUnitsInRadius(DOTA_TEAM_BADGUYS, point:GetAbsOrigin(), nil, 1500, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
local number2 = 0

	for _,v in pairs(units) do
		number2 = number2 +1
	end

	if number2 <= 1 and PlayerResource:GetPlayerCount() >= 3 and NEUTRAL_SPAWN == 1 then
		for j = 1, 10 do
			local unit = CreateUnitByName("npc_dota_creature_murloc", point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
		end
	end
	return 1
end

function FarmEventCreeps3()
local point = Entities:FindByName(nil, "farm_event_player_3")
local units = FindUnitsInRadius(DOTA_TEAM_BADGUYS, point:GetAbsOrigin(), nil, 1500, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
local number3 = 0

	for _,v in pairs(units) do
		number3 = number3 +1
	end

	if number3 <= 1 and PlayerResource:GetPlayerCount() >= 4 and NEUTRAL_SPAWN == 1 then
		for j = 1, 10 do
			local unit = CreateUnitByName("npc_dota_creature_murloc", point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
		end
	end
	return 1
end

function FarmEventCreeps4()
local point = Entities:FindByName(nil, "farm_event_player_4")
local units = FindUnitsInRadius(DOTA_TEAM_BADGUYS, point:GetAbsOrigin(), nil, 1500, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
local number4 = 0

	for _,v in pairs(units) do
		number4 = number4 +1
	end

	if number4 <= 1 and PlayerResource:GetPlayerCount() >= 5 and NEUTRAL_SPAWN == 1 then
		for j = 1, 10 do
			local unit = CreateUnitByName("npc_dota_creature_murloc", point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
		end
	end
	return 1
end

function FarmEventCreeps5()
local point = Entities:FindByName(nil, "farm_event_player_5")
local units = FindUnitsInRadius(DOTA_TEAM_BADGUYS, point:GetAbsOrigin(), nil, 1500, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
local number5 = 0

	for _,v in pairs(units) do
		number5 = number5 +1
	end

	if number5 <= 1 and PlayerResource:GetPlayerCount() >= 6 and NEUTRAL_SPAWN == 1 then
		for j = 1, 10 do
			local unit = CreateUnitByName("npc_dota_creature_murloc", point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
		end
	end
	return 1
end

function FarmEventCreeps6()
local point = Entities:FindByName(nil, "farm_event_player_6")
local units = FindUnitsInRadius(DOTA_TEAM_BADGUYS, point:GetAbsOrigin(), nil, 1500, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
local number6 = 0

	for _,v in pairs(units) do
		number6 = number6 +1
	end

	if number6 <= 1 and PlayerResource:GetPlayerCount() >= 7 and NEUTRAL_SPAWN == 1 then
		for j = 1, 10 do
			local unit = CreateUnitByName("npc_dota_creature_murloc", point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
		end
	end
	return 1
end

function FarmEventCreeps7()
local point = Entities:FindByName(nil, "farm_event_player_7")
local units = FindUnitsInRadius(DOTA_TEAM_BADGUYS, point:GetAbsOrigin(), nil, 1500, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		
local number7 = 0

	for _,v in pairs(units) do
		number7 = number7 +1
	end

	if number7 <= 1 and PlayerResource:GetPlayerCount() >= 8 and NEUTRAL_SPAWN == 1 then
		for j = 1, 10 do
			local unit = CreateUnitByName("npc_dota_creature_murloc", point:GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
		end
	end
	return 1
end

function RameroEvent() -- 940 kills
local teleporters = Entities:FindAllByName("trigger_teleport_ramero_end")
nCOUNTDOWNTIMER = 121

	local Ramero = CreateUnitByName("npc_ramero", Entities:FindByName(nil, "roshan_wp_4"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
	Ramero:AddNewModifier( nil, nil, "modifier_boss_stun", {duration = 5})
	Ramero:AddNewModifier( nil, nil, "modifier_invulnerable", {duration = 5})
	Ramero:SetAngles(0, 45, 0)
	local Baristal = CreateUnitByName("npc_baristal", Entities:FindByName(nil, "roshan_wp_2"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
	Baristal:AddNewModifier( nil, nil, "modifier_boss_stun", {duration = 5})
	Baristal:AddNewModifier( nil, nil, "modifier_invulnerable", {duration = 5})
	Baristal:SetAngles(0, 325, 0)
--	Ramero:EmitSound("Muradin.StormEarthFire")
	Notifications:TopToAll({hero="npc_dota_hero_sven", duration=5.0})
	Notifications:TopToAll({text="Kill Ramero and Baristal to get special items! ", continue=true})
	Notifications:TopToAll({text="Reward: Lightning Sword and Tome of Stats +250.", continue=true})

	Timers:CreateTimer(120, function() -- Teleport back to the spawn
		for _,v in pairs(teleporters) do
			v:Enable()
		end

		UTIL_Remove(Ramero)
		UTIL_Remove(Baristal)
	end)

	Timers:CreateTimer(126, function() -- 14:05 Min: MURADIN BRONZEBEARD EVENT 1, END
--		Notifications:TopToAll({text="Ramero and Baristal won the duel!", duration = 6.0})
		for _,v in pairs(teleporters) do
			v:Disable()
		end
	end)
end

function EndRameroEvent(keys)
	local activator = keys.activator
	local point = Entities:FindByName(nil,"base_spawn"):GetAbsOrigin()

	if activator:GetTeam() == DOTA_TEAM_GOODGUYS then
	FindClearSpaceForUnit(activator, point, true)
	PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(), activator)
	Timers:CreateTimer(0.1, function()
		PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(), nil)
	end)
	activator:Stop()
	end
end