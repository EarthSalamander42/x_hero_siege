require('libraries/timers')

first_time_teleport = true
first_time_teleport_phase3_creeps = true
first_time_teleport_arthas = true
first_time_teleport_arthas_real = true

function StartMagtheridonArena(keys)
local activator = keys.activator
local point_mag = Entities:FindByName(nil,"npc_dota_spawner_magtheridon_arena"):GetAbsOrigin()
local point_mag2 = Entities:FindByName(nil,"npc_dota_spawner_magtheridon_arena2"):GetAbsOrigin()
local ankh = CreateItem("item_magtheridon_ankh", mag, mag)
local ankh2 = CreateItem("item_magtheridon_ankh", mag, mag)
local heroes = HeroList:GetAllHeroes()
local difficulty = GameRules:GetCustomGameDifficulty()

	if first_time_teleport then
		RefreshPlayers()
--		MagtheridonHealtHBar()
		if difficulty == 1 then
			magtheridon = CreateUnitByName("npc_dota_hero_magtheridon", point_mag  ,true, nil, nil, DOTA_TEAM_BADGUYS)
			magtheridon:SetAngles(0, 180, 0)
		elseif difficulty == 2 then
			magtheridon = CreateUnitByName("npc_dota_hero_magtheridon", point_mag  ,true, nil, nil, DOTA_TEAM_BADGUYS)
			magtheridon:SetAngles(0, 180, 0)
			magtheridon:AddItem(ankh)
			ankh:SetCurrentCharges(1)
		elseif difficulty == 3 then
			magtheridon = CreateUnitByName("npc_dota_hero_magtheridon", point_mag  ,true, nil, nil, DOTA_TEAM_BADGUYS)
			magtheridon:SetAngles(0, 180, 0)
			magtheridon:AddItem(ankh)
			ankh:SetCurrentCharges(3)
		elseif difficulty == 4 then
			magtheridon = CreateUnitByName("npc_dota_hero_magtheridon", point_mag  ,true, nil, nil, DOTA_TEAM_BADGUYS)
			magtheridon2 = CreateUnitByName("npc_dota_hero_magtheridon", point_mag2  ,true, nil, nil, DOTA_TEAM_BADGUYS)
			magtheridon:SetAngles(0, 180, 0)
			magtheridon2:SetAngles(0, 0, 0)
			magtheridon:AddItem(ankh)
			ankh:SetCurrentCharges(1)
			magtheridon2:AddItem(ankh2)
			ankh2:SetCurrentCharges(1)
			magtheridon2:AddNewModifier(nil, nil, "modifier_boss_stun", {Duration = 10, IsHidden = true})
			magtheridon2:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 10, IsHidden = true})
		end

		magtheridon:AddNewModifier(nil, nil, "modifier_boss_stun", {Duration = 10, IsHidden = true})
		magtheridon:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 10, IsHidden = true})

		for _,hero in pairs(heroes) do
		local id = hero:GetPlayerID()
		local point = Entities:FindByName(nil, "point_teleport_boss_"..id)
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				FindClearSpaceForUnit(hero, point:GetAbsOrigin(), true)
				hero:Stop()
				hero:AddNewModifier(nil, nil, "modifier_animation_freeze_stun", {Duration = 10, IsHidden = true})
				hero:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 10, IsHidden = true})
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), hero)
				first_time_teleport = false
				Timers:CreateTimer(0.1, function()
					PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), nil)
				end)
			end
		end
	elseif activator:GetTeam() == DOTA_TEAM_GOODGUYS then
		local point_alt = Entities:FindByName(nil, "point_teleport_boss_0")
		FindClearSpaceForUnit(activator, point_alt:GetAbsOrigin(), true)
		activator:Stop()
		PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),activator)
		Timers:CreateTimer(0.1, function()
			PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),nil)
		end)
	end
end

function EndMagtheridonArena()
local teleporters2 = Entities:FindAllByName("trigger_teleport2")

	for _,v in pairs(teleporters2) do
		v:Enable()
	end

	Notifications:TopToAll({text="You have killed Magtheridon. Blue teleporters activated.", style={color="blue"}, continue=true})
end

function DarkProtectors(keys)
local activator = keys.activator
local point = Entities:FindByName(nil,"point_teleport_phase3_creeps"):GetAbsOrigin()
local point2 = Entities:FindByName( nil, "spawner_phase3_creeps_west"):GetAbsOrigin()
local point3 = Entities:FindByName( nil, "spawner_phase3_creeps_east"):GetAbsOrigin()
local stats = 250

	if first_time_teleport_phase3_creeps then
		RefreshPlayers()
		DoEntFire("trigger_teleport_phase3_creeps", "Kill", nil, 0, nil, nil)
		Entities:FindByName(nil, "trigger_teleport_late"):Enable()
		Notifications:TopToAll({text="Power Up: +250 to all stats!", style={color="green"}, duration=10.0})
		activator:EmitSound("ui.trophy_levelup")
		local heroes = HeroList:GetAllHeroes()

		for _,hero in pairs(heroes) do
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				FindClearSpaceForUnit(hero, point, true)
				hero:Stop()
				hero:AddNewModifier(nil, nil, "modifier_animation_freeze_stun", {Duration = 5, IsHidden = true})
				hero:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 5, IsHidden = true})
				hero:ModifyAgility(stats)
				hero:ModifyStrength(stats)
				hero:ModifyIntellect(stats)
				local particle1 = ParticleManager:CreateParticle("particles/econ/events/ti6/hero_levelup_ti6.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
				ParticleManager:SetParticleControl(particle1, 0, hero:GetAbsOrigin())
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), hero)
				first_time_teleport_phase3_creeps = false
				Timers:CreateTimer(0.1, function()
					PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil)
				end)
				Timers:CreateTimer(3, function()
					local unit = CreateUnitByName("npc_dota_creep_dire_hulk", point2 + RandomVector(RandomInt(0, 50)), true, nil, nil, DOTA_TEAM_BADGUYS)
				end)
				Timers:CreateTimer(5, function()
					local unit = CreateUnitByName("npc_dota_creep_dire_hulk", point3 + RandomVector(RandomInt(0, 50)), true, nil, nil, DOTA_TEAM_BADGUYS)
				end)
			end
		end

		Timers:CreateTimer(10, function()
			local DoorObs = Entities:FindAllByName("obstruction_grom")
			for _, obs in pairs(DoorObs) do
				obs:SetEnabled(false, true)
			end
			DoEntFire("door_grom", "SetAnimation", "gate_entrance002_open", 0, nil, nil)
		end)
	end
end

function Start4BossesArena(keys)
local activator = keys.activator
local difficulty = GameRules:GetCustomGameDifficulty()
local point = Entities:FindByName(nil,"point_teleport_arthas"):GetAbsOrigin()
	if first_time_teleport_arthas then
		local heroes = HeroList:GetAllHeroes()

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
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), hero)
				Timers:CreateTimer(0.1, function()
					PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), nil)
				end)
				first_time_teleport_arthas = false
			end
		end
	elseif activator:GetTeam() == DOTA_TEAM_GOODGUYS then
		FindClearSpaceForUnit(activator, point, true)
		Timers:CreateTimer(0.1, function()
			PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(), nil)
		end)
		activator:Stop()
	end
end

function FourBossesKillCount()
local teleporters3 = Entities:FindAllByName("trigger_teleport3")
	FOUR_BOSSES = FOUR_BOSSES +1

	if FOUR_BOSSES == 4 then
		for _,v in pairs(teleporters3) do
			v:Enable()
		end
		Notifications:TopToAll({text="You have killed Grom, Proudmoore, Illidan and Balanar. Red Teleporters Activated." , duration = 10.0})
	end
end

function StartArthasArena(keys)
local activator = keys.activator
local heroes = HeroList:GetAllHeroes()
	if first_time_teleport_arthas_real then
		RefreshPlayers()
		local arthas = CreateUnitByName("npc_dota_hero_arthas",Entities:FindByName(nil,"npc_dota_spawner_magtheridon_arena"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_BADGUYS)
		arthas:SetAngles(0, 270, 0)

		arthas:AddNewModifier(nil, nil, "modifier_boss_stun", {Duration = 10, IsHidden = true})
		arthas:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 9, IsHidden = true})
		for _,hero in pairs(heroes) do
		local id = hero:GetPlayerID()
		local point = Entities:FindByName(nil, "point_teleport_boss_"..id)
			if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
				FindClearSpaceForUnit(hero, point:GetAbsOrigin(), true)
				hero:AddNewModifier(nil, nil, "modifier_animation_freeze_stun", {Duration = 10, IsHidden = true})
				hero:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 10, IsHidden = true})
				hero:Stop()
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),hero)
				Timers:CreateTimer(0.1, function()
					PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil)
				end)
				first_time_teleport_arthas_real = false
			end
		end
	elseif activator:GetTeam() == DOTA_TEAM_GOODGUYS then
	local point_alt = Entities:FindByName(nil, "point_teleport_boss_0")
		FindClearSpaceForUnit(activator, point_alt:GetAbsOrigin(), true)
		PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(), activator)
		Timers:CreateTimer(0.1, function()
			PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(),nil)
		end)
		activator:Stop()
	end
end

function StartBaneHallowArena()
local difficulty = GameRules:GetCustomGameDifficulty()
RefreshPlayers()

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

function StartLichKingArena()
local point_boss = Entities:FindByName(nil, "npc_dota_spawner_lich_king_bis"):GetAbsOrigin()
local heroes = HeroList:GetAllHeroes()
local reincarnate_time = 8.0
RefreshPlayers()

	for _,hero in pairs(heroes) do
	local id = hero:GetPlayerID()
	local point = Entities:FindByName(nil, "point_teleport_boss_"..id)
		if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
			FindClearSpaceForUnit(hero, point:GetAbsOrigin(), true)
			hero:AddNewModifier(nil, nil, "modifier_animation_freeze_stun", {Duration = 20, IsHidden = true})
			hero:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 20, IsHidden = true})
			hero:Stop()
			PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), lich_king)
			Timers:CreateTimer(0.5, function()
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil)
			end)
		end
	end

	Timers:CreateTimer(2.0, function()
		StartAnimation(lich_king, {duration = reincarnate_time, activity = ACT_DOTA_SPAWN, rate = 1.0})

		Timers:CreateTimer(reincarnate_time, function()
			UTIL_Remove(lich_king)
			local lich_king2 = CreateUnitByName("npc_dota_boss_lich_king", point_boss, true, nil, nil, DOTA_TEAM_BADGUYS)
			StartAnimation(lich_king2, {duration = 3.0, activity = ACT_DOTA_SPAWN, rate = 0.65})
			lich_king2:SetAngles(0, 270, 0)
			lich_king2:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 12, IsHidden = true})
			lich_king2:AddNewModifier(nil, nil, "modifier_boss_stun", {Duration = 12, IsHidden = true})
		end)
	end)

	Timers:CreateTimer(14,function()
		Notifications:TopToAll({text="From death, i grow stronger!" , duration = 5.0})
	end)
end

function StartSpiritMasterArena()
local point_boss_1 = Entities:FindByName(nil, "spirit_master_point_bis"):GetAbsOrigin()
local heroes = HeroList:GetAllHeroes()
RefreshPlayers()

	for _, hero in pairs(heroes) do
	local id = hero:GetPlayerID()
	local point_hero = Entities:FindByName(nil, "point_teleport_boss_"..id)
		if hero:GetTeam() == DOTA_TEAM_GOODGUYS then
			FindClearSpaceForUnit(hero, point_hero:GetAbsOrigin(), true)
			hero:AddNewModifier(nil, nil, "modifier_animation_freeze_stun", {Duration = 21, IsHidden = true})
			hero:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 20, IsHidden = true})
			hero:Stop()
			PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), spirit_master)
			Timers:CreateTimer(0.5, function()
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil)
			end)
		end
	end

	Timers:CreateTimer(2.0, function()
		StartAnimation(spirit_master, {duration = 0.5, activity = ACT_DOTA_IDLE, rate = 1.0})
--		spirit_master:RemoveModifierByName("modifier_boss_stun")
--		spirit_master:MoveToPositionAggressive(point_boss_1)
	end)

	Timers:CreateTimer(5.0, function()
		UTIL_Remove(spirit_master)
		local spirit_master2 = CreateUnitByName("npc_dota_boss_spirit_master", point_boss_1, true, nil, nil, DOTA_TEAM_BADGUYS)
		StartAnimation(spirit_master2, {duration = 3.0, activity = ACT_DOTA_SPAWN, rate = 0.85})
		spirit_master2:SetAngles(0, 90, 0)
		spirit_master2:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 11, IsHidden = true})
		spirit_master2:EmitSound("DOTAMusic_Diretide_Finale")
	end)
end

function StartSecretArena(keys)
local activator = keys.activator
local point = Entities:FindByName(nil, "npc_dota_muradin_player_1")
local difficulty = GameRules:GetCustomGameDifficulty()
local doomm_artifact = "item_doom_artifact"

	if difficulty == 4 then
		for itemSlot = 0, 5 do
			local item = activator:GetItemInSlot(itemSlot)
			if item:GetName() == doom_artifact then
				local secret = CreateUnitByName("npc_dota_hero_secret", Entities:FindByName(nil, "roshan_wp_4"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
				secret:SetAngles(0, 270, 0)
				secret:AddNewModifier(nil, nil, "modifier_boss_stun", {Duration = 10, IsHidden = true})
				secret:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 9, IsHidden = true})

				FindClearSpaceForUnit(activator, point:GetAbsOrigin(), true)
				activator:AddNewModifier(nil, nil, "modifier_animation_freeze_stun", {Duration = 10, IsHidden = true})
				activator:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 10, IsHidden = true})
				activator:Stop()
				PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(), activator)
				Timers:CreateTimer(0.1, function()
					PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(), nil)
				end)
			end
		end
	end
end
