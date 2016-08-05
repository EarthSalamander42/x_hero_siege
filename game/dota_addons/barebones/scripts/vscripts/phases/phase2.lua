require('libraries/timers')

first_time_teleport = true
first_time_teleport_arthas = true
first_time_teleport_arthas_real = true

function trigger_second_wave_left()
print("Disabled trigger left")
DoEntFire("trigger_phase2_left","Kill",nil,0,nil,nil)

Timers:CreateTimer(3.0,spawn_second_phase_left)
end

function trigger_second_wave_right()
print("Disabled trigger right")
DoEntFire("trigger_phase2_right","Kill",nil,0,nil,nil)

Timers:CreateTimer(3.0,spawn_second_phase_right)
end

function trigger_second_wave_solo()
print("Disabled trigger solo")
DoEntFire("trigger_phase2_solo","Kill",nil,0,nil,nil)

Timers:CreateTimer(2.0,spawn_second_phase_solo)
end

function spawn_second_phase_left()
	local EntIceTower = Entities:FindByName( nil, "npc_tower_cold_1" )
	local point = Entities:FindByName( nil, "npc_dota_spawner_top_left_1"):GetAbsOrigin()
	Timers:CreateTimer(0, function()
		if EntIceTower:IsAlive() then -- Level 1 lower than 6 min
			for j = 1, 8 do
			local unit = CreateUnitByName("npc_ghul_II", point+RandomVector(RandomInt(0, 50)), true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds
		elseif not EntIceTower:IsAlive() then
		return nil
		end
	end)
end

function spawn_second_phase_right()
	local EntIceTower = Entities:FindByName( nil, "npc_tower_cold_2" )
	local point = Entities:FindByName( nil, "npc_dota_spawner_top_right_1"):GetAbsOrigin()
	Timers:CreateTimer(0, function()
		if EntIceTower:IsAlive() then -- Level 1 lower than 6 min
			for j = 1, 8 do
			local unit = CreateUnitByName("npc_orc_II", point+RandomVector(RandomInt(0, 50)), true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds
		elseif not EntIceTower:IsAlive() then
		return nil
		end
	end)
end

function spawn_second_phase_solo()
	local EntIceTower = Entities:FindByName( nil, "npc_tower_cold_3" )
	local point = Entities:FindByName( nil, "npc_dota_spawner_top_solo_1"):GetAbsOrigin()
	Timers:CreateTimer(0, function()
		if EntIceTower:IsAlive() then -- Level 1 lower than 6 min
			for j = 1, 5 do
			local unit = CreateUnitByName("npc_ghul_II", point+RandomVector(RandomInt(0, 50)), true, nil, nil, DOTA_TEAM_BADGUYS)
			end
		return 30 -- Rerun this timer every 30 game-time seconds
		elseif not EntIceTower:IsAlive() then
		return nil
		end
	end)
end

function killed_frost_tower_left(keys)
	caller = keys.caller
	GameMode.FrostTowers_killed = GameMode.FrostTowers_killed +1
	print( GameMode.FrostTowers_killed )
--	Timers:RemoveTimer(GameMode.timer_second_phase_left)
	GameMode.timer_second_phase_left = nil

	if GameMode.FrostTowers_killed >= 2 then
--		Timers:RemoveTimer( timer_wave_spawn)
--		timer_wave_spawn = nil
--		Timers:RemoveTimer( timer_wave_message)
--		timer_wave_message = nil
		print("FinalWave timer started")
		Notifications:TopToAll({text="WARNING! Final Wave incoming. Arriving in 60 seconds! Back to the Castle!" , duration=59.0})
		Timers:CreateTimer(20,FinalWave)
		local directions = {"west","north","east","south"}
	end
end

function killed_frost_tower_right(keys)
	caller = keys.caller
	GameMode.FrostTowers_killed = GameMode.FrostTowers_killed +1
	print( GameMode.FrostTowers_killed )
--	Timers:RemoveTimer(GameMode.timer_second_phase_right)
	GameMode.timer_second_phase_right = nil

	if GameMode.FrostTowers_killed >= 2 then
--		Timers:RemoveTimer( timer_wave_spawn)
--		timer_wave_spawn = nil
--		Timers:RemoveTimer( timer_wave_message)
--		timer_wave_message = nil
		DebugPrint("FinalWave timer started")
		Notifications:TopToAll({text="WARNING! Final Wave incoming. Arriving in 60 seconds! Back to the Castle!" , duration=59.0})
		Timers:CreateTimer(60,FinalWave)
	end
end

function killed_frost_tower_solo(keys)
	caller = keys.caller
	GameMode.FrostTowers_killed = GameMode.FrostTowers_killed + 2
	print( GameMode.FrostTowers_killed )
--	Timers:RemoveTimer(GameMode.timer_second_phase_left)
	GameMode.timer_second_phase_left = nil

	if GameMode.FrostTowers_killed >= 2 then
--		Timers:RemoveTimer( timer_wave_spawn)
--		timer_wave_spawn = nil
--		Timers:RemoveTimer( timer_wave_message)
--		timer_wave_message = nil
		print("FinalWave timer started")
		Notifications:TopToAll({text="WARNING! Final Wave incoming. Arriving in 60 seconds! Back to the Castle!" , duration=59.0})
		Timers:CreateTimer(60, FinalWave)
		local directions = {"west","north","east","south"}
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
				unit:AddNewModifier(nil, nil, "modifier_stunned", {duration= 15,IsHidden = true})
				unit:AddNewModifier(nil, nil, "modifier_invulnerable", {duration= 15,IsHidden = true})
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
	PlayerResource:ModifyGold( activator:GetPlayerOwnerID(), 10000, false,  DOTA_ModifyGold_Unspecified )
	end
end

function teleport_to_top(keys)
	-- body
	-- Spawn Magtheridon
	DebugPrint("teleport trigger")
	local caller = keys.caller
	local activator = keys.activator
	local point = Entities:FindByName(nil,"point_teleport_boss"):GetAbsOrigin()
	local point_mag = Entities:FindByName(nil,"npc_dota_spawner_magtheridon_arena"):GetAbsOrigin()
	local ankh = CreateItem("item_magtheridon_ankh", mag, mag)

	if first_time_teleport then
		local heroes = HeroList:GetAllHeroes()
		print( "Magtheridon should appears now" )

		if GetMapName() == "easymode" then
			magtheridon = CreateUnitByName("npc_dota_hero_magtheridon", point_mag  ,true,nil,nil,DOTA_TEAM_BADGUYS)
			magtheridon:SetAngles(0, 180, 0)
			ankh:SetCurrentCharges(3)
			magtheridon:AddItem(ankh)
		elseif GetMapName() == "hardmode" then
			local point_mag2 = Entities:FindByName(nil,"npc_dota_spawner_magtheridon_arena2"):GetAbsOrigin()
			magtheridon = CreateUnitByName("npc_dota_hero_magtheridon", point_mag  ,true,nil,nil,DOTA_TEAM_BADGUYS)
			magtheridon2 = CreateUnitByName("npc_dota_hero_magtheridon", point_mag2  ,true,nil,nil,DOTA_TEAM_BADGUYS)
			magtheridon:SetAngles(0, 180, 0)
			magtheridon2:SetAngles(0, 0, 0)
			magtheridon:AddItem(ankh)
			magtheridon2:AddItem(ankh)
			ankh:SetCurrentCharges(1)
		elseif GetMapName() == "solomode" then
			magtheridon = CreateUnitByName("npc_dota_hero_magtheridon", point_mag  ,true,nil,nil,DOTA_TEAM_BADGUYS)
			magtheridon:SetAngles(0, 180, 0)
		end

		magtheridon:AddNewModifier(nil, nil, "modifier_stunned",nil)
		magtheridon:AddNewModifier(nil, nil, "modifier_invulnerable",nil)
		magtheridon2:AddNewModifier(nil, nil, "modifier_stunned",nil)
		magtheridon2:AddNewModifier(nil, nil, "modifier_invulnerable",nil)
		Timers:CreateTimer(10,StartMagtheridonFight)
		for _,hero in pairs(heroes) do
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				FindClearSpaceForUnit(hero, point, true)
				hero:AddNewModifier(nil, nil, "modifier_stunned",nil)
				hero:AddNewModifier(nil, nil, "modifier_invulnerable",nil)
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
				first_time_teleport = false
			end
		end

	elseif activator:GetTeam() == DOTA_TEAM_GOODGUYS then
		FindClearSpaceForUnit(activator, point, true)
	end
end

function StartMagtheridonFight()
  local heroes = HeroList:GetAllHeroes()

  magtheridon:RemoveModifierByName("modifier_stunned")
  magtheridon:RemoveModifierByName("modifier_invulnerable")
  magtheridon2:RemoveModifierByName("modifier_stunned")
  magtheridon2:RemoveModifierByName("modifier_invulnerable")

  magtheridon = nil
  magtheridon2 = nil

  for _,hero in pairs(heroes) do
	  if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
		PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil)
		hero:RemoveModifierByName("modifier_stunned")
		hero:RemoveModifierByName("modifier_invulnerable")
	  end
   end
   return nil
end

function kill_magtheridon_count(keys)
local teleporters2 = Entities:FindAllByName("trigger_teleport2")
	GameMode.Magtheridon_killed = GameMode.Magtheridon_killed +1
	print( GameMode.Magtheridon_killed )

	if GameMode.Magtheridon_killed > 3 and GetMapName() == "easymode" then
		for _,v in pairs(teleporters2) do
			DebugPrint("enable teleport trigger")
			v:Enable()
		end
		Notifications:TopToAll({text="You have killed Magtheridon. Blue teleporters activated." , duration=10.0})

	elseif GameMode.Magtheridon_killed > 2 and GetMapName() == "hardmode" then
		for _,v in pairs(teleporters2) do
			DebugPrint("enable teleport trigger")
			v:Enable()
		end
		Notifications:TopToAll({text="You have killed Magtheridon. Blue teleporters activated." , duration=10.0})

	elseif GameMode.Magtheridon_killed > 0 and GetMapName() == "solomode" then
		for _,v in pairs(teleporters2) do
			DebugPrint("enable teleport trigger")
			v:Enable()
		end
		Notifications:TopToAll({text="You have killed Magtheridon. Blue teleporters activated." , duration=10.0})
	end
end
