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
local stats = 250

	if first_time_teleport_phase3_creeps then
		print("Disabled trigger dark protectors")
		DoEntFire("trigger_teleport_phase3_creeps","Kill",nil,0,nil,nil)
		Notifications:TopToAll({text="Power Up: +250 to all stats!", style={color="green"}, duration=10.0})
		activator:EmitSound("ui.trophy_levelup")
		local heroes = HeroList:GetAllHeroes()

		Timers:CreateTimer(5, StartPhase3CreepsFight)
		for _,hero in pairs(heroes) do
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				FindClearSpaceForUnit(hero, point, true)
				hero:Stop()
				hero:AddNewModifier(nil, nil, "modifier_animation_freeze_stun", {Duration = 6, IsHidden = true})
				hero:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 5, IsHidden = true})
				hero:ModifyAgility(stats)
				hero:ModifyStrength(stats)
				hero:ModifyIntellect(stats)
				local particle1 = ParticleManager:CreateParticle("particles/econ/events/ti6/hero_levelup_ti6.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
				ParticleManager:SetParticleControl(particle1, 0, hero:GetAbsOrigin())
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
				Timers:CreateTimer(0.1, function()
					PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil)
				end)
				first_time_teleport_phase3_creeps = false
			end
		end
	end
end

function StartPhase3CreepsFight()
local heroes = HeroList:GetAllHeroes()
local point = Entities:FindByName( nil, "spawner_phase3_creeps_west"):GetAbsOrigin()
local point2 = Entities:FindByName( nil, "spawner_phase3_creeps_east"):GetAbsOrigin()

	for j = 1,8 do
		local unit = CreateUnitByName("npc_dota_creep_radiant_hulk", point+RandomVector(RandomInt(0, 50)), true, nil, nil, DOTA_TEAM_BADGUYS)
	end

	for j = 1,8 do
		local unit = CreateUnitByName("npc_dota_creep_dire_hulk", point2+RandomVector(RandomInt(0, 50)), true, nil, nil, DOTA_TEAM_BADGUYS)
	end
	return nil
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
		Notifications:TopToAll({text="+250 Stats added to all heroes!", style={color="green"}, duration=10.0})
		for _,hero in pairs(heroes) do
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				FindClearSpaceForUnit(hero, point, true)
				hero:Stop()
				hero:AddNewModifier(nil, nil, "modifier_animation_freeze_stun", {Duration = 5, IsHidden = true})
				hero:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 5, IsHidden = true})
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
				local stats = 250
				hero:ModifyAgility(stats)
				hero:ModifyStrength(stats)
				hero:ModifyIntellect(stats)
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

		for _,hero in pairs(heroes) do
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				FindClearSpaceForUnit(hero, point, true)
				hero:Stop()
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
				Timers:CreateTimer(0.1, function()
					PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil)
				end)
				first_time_teleport_arthas = false
			end
		end
	elseif activator:GetTeam() == DOTA_TEAM_GOODGUYS then
		FindClearSpaceForUnit(activator, point, true)
		activator:Stop()
	end
end

function StartArthasArena(keys)
local caller = keys.caller
local activator = keys.activator
local point = Entities:FindByName(nil,"point_teleport_boss"):GetAbsOrigin()
local heroes = HeroList:GetAllHeroes()
print( "Arthas should appears now" )
	if first_time_teleport_arthas_real then
		local arthas = CreateUnitByName("npc_dota_hero_arthas",Entities:FindByName(nil,"npc_dota_spawner_magtheridon_arena"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_BADGUYS)
		arthas:SetAngles(0, 270, 0)

		arthas:AddNewModifier(nil, nil, "modifier_boss_stun", {Duration = 10, IsHidden = true})
		arthas:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 9, IsHidden = true})
		for _,hero in pairs(heroes) do
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				FindClearSpaceForUnit(hero, point, true)
				hero:AddNewModifier(nil, nil, "modifier_animation_freeze_stun", {Duration = 10, IsHidden = true})
				hero:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 9, IsHidden = true})
				hero:Stop()
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
				Timers:CreateTimer(0.1, function()
					PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil)
				end)
				first_time_teleport_arthas_real = false
			end
		end
	elseif activator:GetTeam() == DOTA_TEAM_GOODGUYS then
		FindClearSpaceForUnit(activator, point, true)
		PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
		Timers:CreateTimer(0.1, function()
			PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil)
		end)
		activator:Stop()
	end
end

function StartBaneHallowArena(keys)
local caller = keys.caller
local activator = keys.activator
local point = Entities:FindByName(nil,"point_teleport_boss"):GetAbsOrigin()
print( "BaneHallow should appears now" )

	Timers:CreateTimer(8,function()
	local banehallow = CreateUnitByName("npc_dota_hero_banehallow",Entities:FindByName(nil,"npc_dota_spawner_magtheridon_arena"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_BADGUYS)
	banehallow:SetAngles(0, 270, 0)
	banehallow:AddNewModifier(nil, nil, "modifier_boss_stun", {Duration = 25, IsHidden = true})
	banehallow:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 14, IsHidden = true})
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
end

function StartLichKingArena(keys)
local caller = keys.caller
local activator = keys.activator
local point = Entities:FindByName(nil, "npc_dota_spawner_lich_king_bis")
local point_abs = Entities:FindByName(nil, "npc_dota_spawner_lich_king_bis"):GetAbsOrigin()
local point_hero = Entities:FindByName(nil, "point_teleport_boss"):GetAbsOrigin()
local heroes = HeroList:GetAllHeroes()
local reincarnate_time = 7.75
print( "Lich King should appears now" )

	for _,hero in pairs(heroes) do
		if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
			FindClearSpaceForUnit(hero, point_hero, true)
			hero:AddNewModifier(nil, nil, "modifier_animation_freeze_stun", {Duration = 21, IsHidden = true})
			hero:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 20, IsHidden = true})
			hero:Stop()
			PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), lich_king)
			Timers:CreateTimer(0.5, function()
					PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil)
				end)
			first_time_teleport_arthas_real = false
		end
	end

	StartAnimation(lich_king, {duration = reincarnate_time, activity = ACT_DOTA_SPAWN, rate = 1.0})

	Timers:CreateTimer(reincarnate_time, function()
		UTIL_Remove(lich_king)
		local lich_king2 = CreateUnitByName("npc_dota_boss_lich_king", point_abs, true, nil, nil, DOTA_TEAM_BADGUYS)
		StartAnimation(lich_king2, {duration = 3.0, activity = ACT_DOTA_SPAWN, rate = 0.65})
		lich_king2:SetAngles(0, 270, 0)
		lich_king2:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 12, IsHidden = true})
		lich_king2:AddNewModifier(nil, nil, "modifier_boss_stun", {Duration = 12, IsHidden = true})
	end)

	Timers:CreateTimer(14,function()
		Notifications:TopToAll({text="From death, i grow stronger!" , duration = 5.0})
	end)
end
