require('libraries/timers')

first_time_teleport = true
first_time_teleport_phase3_creeps = true
first_time_teleport_arthas = true
first_time_teleport_arthas_real = true

function teleport_phase3_creeps(keys)
-- Spawn Phase 3 Creeps
DebugPrint("teleport trigger")
local caller = keys.caller
local activator = keys.activator
local point = Entities:FindByName(nil,"point_teleport_phase3_creeps"):GetAbsOrigin()
	if first_time_teleport_phase3_creeps then
		print("Disabled trigger right")
		DoEntFire("trigger_teleport_phase3_creeps","Kill",nil,0,nil,nil)
		Notifications:TopToAll({text="Arthas invoke Dark Protectors" , duration=10.0})
		local heroes = HeroList:GetAllHeroes()

		Timers:CreateTimer(5,StartPhase3CreepsFight)
		for _,hero in pairs(heroes) do
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				FindClearSpaceForUnit(hero, point, true)
				hero:AddNewModifier(nil, nil, "modifier_stunned",nil)
				hero:AddNewModifier(nil, nil, "modifier_invulnerable",nil)
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
				first_time_teleport_phase3_creeps = false
			end
		end

	elseif activator:GetTeam() == DOTA_TEAM_GOODGUYS then
		first_time_teleport_phase3_creeps = false
		return
	end
end

function StartPhase3CreepsFight()
local heroes = HeroList:GetAllHeroes()
local point = Entities:FindByName( nil, "spawner_phase3_creeps_west"):GetAbsOrigin()
local point2 = Entities:FindByName( nil, "spawner_phase3_creeps_east"):GetAbsOrigin()

	for j = 1,10 do
	local unit = CreateUnitByName("npc_dota_creep_radiant_hulk", point+RandomVector(RandomInt(0, 50)), true, nil, nil, DOTA_TEAM_BADGUYS)
	end

	for j = 1,10 do
	local unit = CreateUnitByName("npc_dota_creep_dire_hulk", point2+RandomVector(RandomInt(0, 50)), true, nil, nil, DOTA_TEAM_BADGUYS)
	end

	for _,hero in pairs(heroes) do
		if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
		PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil)
		hero:RemoveModifierByName("modifier_stunned")
		hero:RemoveModifierByName("modifier_invulnerable")
		end
	end
	return nil
end

function destroy_4bosses(keys)
local teleporters3 = Entities:FindAllByName("trigger_teleport3")
GameMode.BossesTop_killed = GameMode.BossesTop_killed +1
print( GameMode.BossesTop_killed )

	if GameMode.BossesTop_killed > 3 then
		for _,v in pairs(teleporters3) do
		DebugPrint("enable teleport trigger")
		v:Enable()
		end
	Notifications:TopToAll({text="You have killed Grom, Proudmoore, Illidan and Balanar. Arthas is waiting for you.." , duration=10.0})
	Notifications:TopToAll({text="Teleporter Activated!" , duration=10.0})
	print( "Teleporter to 4Bosses Activated!" )
	else return nil
	end
end

function LastArenaBossKillCount(keys)
	GameMode.Arthas_killed = GameMode.Arthas_killed +1
	print( GameMode.Arthas_killed )

	if GameMode.Arthas_killed == 1 then
	print( "Arthas is Dead!" )
	Notifications:TopToAll({text="Who did this?.." , duration=5.0})

	local point = Entities:FindByName(nil,"point_teleport_boss"):GetAbsOrigin()
	local heroes = HeroList:GetAllHeroes()
		Timers:CreateTimer(5, StartBaneHallowArena)
		for _,hero in pairs(heroes) do
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				FindClearSpaceForUnit(hero, point, true)
				hero:AddNewModifier(nil, nil, "modifier_stunned",nil)
				hero:AddNewModifier(nil, nil, "modifier_invulnerable",nil)
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
			end
		end
	end
end

function teleport_to_arthas_arena(keys)
	local caller = keys.caller
	local activator = keys.activator
	local point = Entities:FindByName(nil,"point_teleport_arthas"):GetAbsOrigin()
	if first_time_teleport_arthas then
		local heroes = HeroList:GetAllHeroes()
		print( "Grom, Proudmoore, Illidan, Balanar should appears now" )

		local grom = CreateUnitByName("npc_dota_hero_grom_hellscream",Entities:FindByName(nil,"spawn_grom_hellscream"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_BADGUYS)
		grom:SetAngles(0, 270, 0)

		local illidan = CreateUnitByName("npc_dota_hero_illidan",Entities:FindByName(nil,"spawn_illidan"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_BADGUYS)
		illidan:SetAngles(0, 0, 0)

		local balanar = CreateUnitByName("npc_dota_hero_balanar",Entities:FindByName(nil,"spawn_balanar"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_BADGUYS)
		balanar:SetAngles(0, 90, 0)

		local proudmoore = CreateUnitByName("npc_dota_hero_proudmoore",Entities:FindByName(nil,"spawn_admiral_proudmore"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_BADGUYS)
		proudmoore:SetAngles(0, 180, 0)

		Timers:CreateTimer(0.5,StartBossFight)
		for _,hero in pairs(heroes) do
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				FindClearSpaceForUnit(hero, point, true)
				hero:AddNewModifier(nil, nil, "modifier_stunned",nil)
				hero:AddNewModifier(nil, nil, "modifier_invulnerable",nil)
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
				first_time_teleport_arthas = false
			end
		end
	elseif activator:GetTeam() == DOTA_TEAM_GOODGUYS then
		FindClearSpaceForUnit(activator, point, true)
	end
end

function StartBossFight()
local heroes = HeroList:GetAllHeroes()

for _,hero in pairs(heroes) do
	if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
		PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil)
		hero:RemoveModifierByName("modifier_stunned")
		hero:RemoveModifierByName("modifier_invulnerable")
	end
end
	return nil
end

function StartArthasArena(keys)
-- Spawn Arthas 
DebugPrint("teleport trigger")
local caller = keys.caller
local activator = keys.activator
local point = Entities:FindByName(nil,"point_teleport_boss"):GetAbsOrigin()
	if first_time_teleport_arthas_real then
		local heroes = HeroList:GetAllHeroes()
		print( "Arthas should appears now" )

		local arthas = CreateUnitByName("npc_dota_hero_arthas",Entities:FindByName(nil,"npc_dota_spawner_magtheridon_arena"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_BADGUYS)
		arthas:SetAngles(0, 270, 0)

		Timers:CreateTimer(9,function()
			arthas:RemoveModifierByName("modifier_stunned")
			arthas:RemoveModifierByName("modifier_invulnerable")
			arthas = nil
		end)

		arthas:AddNewModifier(nil, nil, "modifier_stunned",nil)
		arthas:AddNewModifier(nil, nil, "modifier_invulnerable",nil)
		Timers:CreateTimer(10,StartBossFight)
		for _,hero in pairs(heroes) do
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				FindClearSpaceForUnit(hero, point, true)
				hero:AddNewModifier(nil, nil, "modifier_stunned",nil)
				hero:AddNewModifier(nil, nil, "modifier_invulnerable",nil)
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
				first_time_teleport_arthas_real = false
			end
		end
	elseif activator:GetTeam() == DOTA_TEAM_GOODGUYS then
		FindClearSpaceForUnit(activator, point, true)
	end
end

function StartBaneHallowArena(keys)
-- Spawn Arthas
DebugPrint("teleport trigger")
local caller = keys.caller
local activator = keys.activator
local point = Entities:FindByName(nil,"point_teleport_boss"):GetAbsOrigin()
	local heroes = HeroList:GetAllHeroes()
	print( "BaneHallow should appears now" )

	Timers:CreateTimer(8,function()
	local banehallow = CreateUnitByName("npc_dota_hero_banehallow",Entities:FindByName(nil,"npc_dota_spawner_magtheridon_arena"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_BADGUYS)
	banehallow:SetAngles(0, 270, 0)
	banehallow:AddNewModifier(nil, nil, "modifier_stunned",nil)
	banehallow:AddNewModifier(nil, nil, "modifier_invulnerable",nil)

	Timers:CreateTimer(12,function()
		banehallow:RemoveModifierByName("modifier_stunned")
		banehallow:RemoveModifierByName("modifier_invulnerable")
		banehallow = nil
	end)
	end)

	Timers:CreateTimer(12,function()
		local green_revenant = CreateUnitByName("npc_death_revenant_banehallow",Entities:FindByName(nil,"npc_dota_spawner_green_revenant_1"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_BADGUYS)
		green_revenant:SetAngles(0, 340, 0)
		local green_revenant2 = CreateUnitByName("npc_death_revenant_banehallow",Entities:FindByName(nil,"npc_dota_spawner_green_revenant_7"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_BADGUYS)
		green_revenant2:SetAngles(0, 170, 0)
	end)

	Timers:CreateTimer(13.5,function()
		local green_revenant = CreateUnitByName("npc_death_revenant_banehallow",Entities:FindByName(nil,"npc_dota_spawner_green_revenant_2"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_BADGUYS)
		green_revenant:SetAngles(0, 320, 0)
		local green_revenant2 = CreateUnitByName("npc_death_revenant_banehallow",Entities:FindByName(nil,"npc_dota_spawner_green_revenant_8"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_BADGUYS)
		green_revenant2:SetAngles(0, 150, 0)
	end)

	Timers:CreateTimer(15,function()
		local green_revenant = CreateUnitByName("npc_death_revenant_banehallow",Entities:FindByName(nil,"npc_dota_spawner_green_revenant_3"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_BADGUYS)
		green_revenant:SetAngles(0, 300, 0)
		local green_revenant2 = CreateUnitByName("npc_death_revenant_banehallow",Entities:FindByName(nil,"npc_dota_spawner_green_revenant_9"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_BADGUYS)
		green_revenant2:SetAngles(0, 130, 0)
	end)

	Timers:CreateTimer(16.5,function()
		local green_revenant = CreateUnitByName("npc_death_revenant_banehallow",Entities:FindByName(nil,"npc_dota_spawner_green_revenant_4"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_BADGUYS)
		green_revenant:SetAngles(0, 240, 0)
		local green_revenant2 = CreateUnitByName("npc_death_revenant_banehallow",Entities:FindByName(nil,"npc_dota_spawner_green_revenant_10"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_BADGUYS)
		green_revenant2:SetAngles(0, 50, 0)
	end)

	Timers:CreateTimer(18,function()
		local green_revenant = CreateUnitByName("npc_death_revenant_banehallow",Entities:FindByName(nil,"npc_dota_spawner_green_revenant_5"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_BADGUYS)
		green_revenant:SetAngles(0, 220, 0)
		local green_revenant2 = CreateUnitByName("npc_death_revenant_banehallow",Entities:FindByName(nil,"npc_dota_spawner_green_revenant_11"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_BADGUYS)
		green_revenant2:SetAngles(0, 30, 0)
	end)

	Timers:CreateTimer(19.5,function()
		local green_revenant = CreateUnitByName("npc_death_revenant_banehallow",Entities:FindByName(nil,"npc_dota_spawner_green_revenant_6"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_BADGUYS)
		green_revenant:SetAngles(0, 200, 0)
		local green_revenant2 = CreateUnitByName("npc_death_revenant_banehallow",Entities:FindByName(nil,"npc_dota_spawner_green_revenant_12"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_BADGUYS)
		green_revenant2:SetAngles(0, 10, 0)
	end)

	Timers:CreateTimer(23,StartBossFight)
end

function StartAbaddonArena(keys)
-- Spawn Arthas 
DebugPrint("teleport trigger")
local caller = keys.caller
local activator = keys.activator
local point = Entities:FindByName(nil,"point_teleport_boss"):GetAbsOrigin()
local heroes = HeroList:GetAllHeroes()
print( "Abaddon should appears now" )

	Timers:CreateTimer(5,function()
		local abaddon = CreateUnitByName("npc_dota_creature_abaddon",Entities:FindByName(nil,"npc_dota_spawner_magtheridon_arena"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_BADGUYS)
		abaddon:SetAngles(0, 270, 0)
		abaddon:AddNewModifier(nil, nil, "modifier_stunned",nil)
		abaddon:AddNewModifier(nil, nil, "modifier_invulnerable",nil)

		Timers:CreateTimer(7,function()
		abaddon:RemoveModifierByName("modifier_stunned")
		abaddon:RemoveModifierByName("modifier_invulnerable")
		abaddon = nil
	end)
	end)

	Timers:CreateTimer(10,function()
		Notifications:TopToAll({text="From death, i grow stronger!" , duration=5.0})
	end)

	Timers:CreateTimer(13,StartBossFight)
	for _,hero in pairs(heroes) do
		if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
			FindClearSpaceForUnit(hero, point, true)
			hero:AddNewModifier(nil, nil, "modifier_stunned",nil)
			hero:AddNewModifier(nil, nil, "modifier_invulnerable",nil)
			PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
		end
	end
end
