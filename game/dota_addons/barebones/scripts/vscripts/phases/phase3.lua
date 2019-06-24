function StartMagtheridonArena()
local point_mag = Entities:FindByName(nil,"npc_dota_spawner_magtheridon_arena"):GetAbsOrigin()
local point_mag2 = Entities:FindByName(nil,"npc_dota_spawner_magtheridon_arena2"):GetAbsOrigin()
local ankh = CreateItem("item_magtheridon_ankh", mag, mag)
local ankh2 = CreateItem("item_magtheridon_ankh", mag, mag)
local difficulty = GameRules:GetCustomGameDifficulty()
local delay = 3.0

	RefreshPlayers()
	PHASE = 3

	TeleportAllHeroes("point_teleport_boss_", 10.0 + delay, delay)

	Timers:CreateTimer(delay, function()
		if difficulty == 1 then
			magtheridon = CreateUnitByName("npc_dota_hero_magtheridon", point_mag  ,true, nil, nil, DOTA_TEAM_CUSTOM_2)
			magtheridon:SetAngles(0, 180, 0)
			magtheridon.zone = "xhs_holdout"
		elseif difficulty == 2 then
			magtheridon = CreateUnitByName("npc_dota_hero_magtheridon", point_mag  ,true, nil, nil, DOTA_TEAM_CUSTOM_2)
			magtheridon:SetAngles(0, 180, 0)
			magtheridon:AddItem(ankh)
			ankh:SetCurrentCharges(1)
			magtheridon.zone = "xhs_holdout"
		elseif difficulty == 3 then
			magtheridon = CreateUnitByName("npc_dota_hero_magtheridon", point_mag  ,true, nil, nil, DOTA_TEAM_CUSTOM_2)
			magtheridon:SetAngles(0, 180, 0)
			magtheridon:AddItem(ankh)
			ankh:SetCurrentCharges(3)
			magtheridon.zone = "xhs_holdout"
		elseif difficulty == 4 then
			magtheridon = CreateUnitByName("npc_dota_hero_magtheridon", point_mag  ,true, nil, nil, DOTA_TEAM_CUSTOM_2)
			magtheridon2 = CreateUnitByName("npc_dota_hero_magtheridon", point_mag2  ,true, nil, nil, DOTA_TEAM_CUSTOM_2)
			magtheridon:SetAngles(0, 180, 0)
			magtheridon2:SetAngles(0, 0, 0)
			magtheridon:AddItem(ankh)
			ankh:SetCurrentCharges(1)
			magtheridon2:AddItem(ankh2)
			ankh2:SetCurrentCharges(1)
			magtheridon2:AddNewModifier(nil, nil, "modifier_boss_stun", {Duration = 10, IsHidden = true})
			magtheridon2:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 10, IsHidden = true})
			magtheridon.zone = "xhs_holdout"
			magtheridon2.zone = "xhs_holdout"

--			Timers:CreateTimer(0.0, function()
--				CustomNetTables:SetTableValue("round_data", "bossHealth", {boss = "mag", hp = magtheridon:GetHealthPercent(), boss2 = "true" , hp2 = magtheridon2:GetHealthPercent()})

--				return 1.0
--			end)
		elseif difficulty == 5 then
			magtheridon = CreateUnitByName("npc_dota_hero_magtheridon", point_mag  ,true, nil, nil, DOTA_TEAM_CUSTOM_2)
			magtheridon2 = CreateUnitByName("npc_dota_hero_magtheridon", point_mag2  ,true, nil, nil, DOTA_TEAM_CUSTOM_2)
			magtheridon:SetAngles(0, 180, 0)
			magtheridon2:SetAngles(0, 0, 0)
			magtheridon:AddItem(ankh)
			ankh:SetCurrentCharges(2)
			magtheridon2:AddItem(ankh2)
			ankh2:SetCurrentCharges(2)
			magtheridon2:AddNewModifier(nil, nil, "modifier_boss_stun", {Duration = 10, IsHidden = true})
			magtheridon2:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 10, IsHidden = true})
			magtheridon.zone = "xhs_holdout"
			magtheridon2.zone = "xhs_holdout"

--			Timers:CreateTimer(0.0, function()
--				CustomNetTables:SetTableValue("round_data", "bossHealth", {boss = "mag", hp = magtheridon:GetHealthPercent(), boss2 = "true" , hp2 = magtheridon2:GetHealthPercent()})
--			return 1.0
--			end)
		end

--		BossBar(magtheridon, "mag")
		magtheridon:AddNewModifier(nil, nil, "modifier_boss_stun", {Duration = 10, IsHidden = true})
		magtheridon:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 10, IsHidden = true})
	end)
end

function EndMagtheridonArena()
	Entities:FindByName(nil, "trigger_teleport_phase3_creeps"):Enable()
	CustomGameEventManager:Send_ServerToAllClients("hide_boss_hp", {})
	CustomGameEventManager:Send_ServerToAllClients("hide_ui", {})
	Notifications:TopToAll({text="Magtheridon has been killed! Door opened.", style={color="white"}, duration=10.0})
	DoEntFire("door_magtheridon", "SetAnimation", "gate_02_open", 0, nil, nil)

	local DoorObs = Entities:FindAllByName("obstruction_magtheridon")
	for _, obs in pairs(DoorObs) do
		obs:SetEnabled(false, true)
	end

	Timers:CreateTimer(2.0, function()
		local grom = CreateUnitByName("npc_dota_hero_grom_hellscream",Entities:FindByName(nil,"spawn_grom_hellscream"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_CUSTOM_2)
		grom.zone = "xhs_holdout"
		grom:SetAngles(0, 270, 0)
	end)
	Timers:CreateTimer(4.0, function()
		local illidan = CreateUnitByName("npc_dota_hero_illidan",Entities:FindByName(nil,"spawn_illidan"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_CUSTOM_2)
		illidan.zone = "xhs_holdout"
		illidan:SetAngles(0, 0, 0)
	end)
	Timers:CreateTimer(6.0, function()
		local balanar = CreateUnitByName("npc_dota_hero_balanar",Entities:FindByName(nil,"spawn_balanar"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_CUSTOM_2)
		balanar.zone = "xhs_holdout"
		balanar:SetAngles(0, 90, 0)
	end)
	Timers:CreateTimer(8.0, function()
		local proudmoore = CreateUnitByName("npc_dota_hero_proudmoore",Entities:FindByName(nil,"spawn_admiral_proudmore"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_CUSTOM_2)
		proudmoore.zone = "xhs_holdout"
		proudmoore:SetAngles(0, 180, 0)
	end)
end

function DarkProtectors(keys)
local activator = keys.activator
local point2 = Entities:FindByName(nil, "spawner_phase3_creeps_west"):GetAbsOrigin()
local point3 = Entities:FindByName(nil, "spawner_phase3_creeps_east"):GetAbsOrigin()
local play_sound = false

	DoEntFire("door_magtheridon", "SetAnimation", "gate_02_close", 0, nil, nil)
	RefreshPlayers()

	Timers:CreateTimer(0.5, function()
		DoEntFire("trigger_teleport_phase3_creeps", "Kill", nil, 0, nil, nil)
		TeleportAllHeroes("point_teleport_phase3_creeps_", 5.0)
		GiveTomeToAllHeroes(250)

		for i = 0, PlayerResource:GetPlayerCount() - 1 do
			Timers:CreateTimer(3.0, function()
				for i = 1, 2 do
					local unit = CreateUnitByName("npc_dota_creep_dire_hulk", point2 + RandomVector(RandomInt(0, 50)), true, nil, nil, DOTA_TEAM_CUSTOM_2)
				end
			end)

			Timers:CreateTimer(5.0, function()
				for i = 1, 2 do
					local unit = CreateUnitByName("npc_dota_creep_dire_hulk", point3 + RandomVector(RandomInt(0, 50)), true, nil, nil, DOTA_TEAM_CUSTOM_2)
				end
			end)
		end

		Timers:CreateTimer(10, function()
			local DoorObs = Entities:FindAllByName("obstruction_grom")
			for _, obs in pairs(DoorObs) do
				obs:SetEnabled(false, true)
			end
			DoEntFire("door_grom", "SetAnimation", "gate_02_open", 0, nil, nil)
			DoEntFire("door_grom2", "SetAnimation", "gate_02_open", 0, nil, nil)
		end)
	end)
end

function FourBossesKillCount()
local teleporters = Entities:FindAllByName("trigger_teleport3")
	FOUR_BOSSES = FOUR_BOSSES +1

	if FOUR_BOSSES == 4 then
		for _,v in pairs(teleporters) do
			v:Enable()
		end
		Notifications:TopToAll({text="You have killed Grom, Proudmoore, Illidan and Balanar. Talk to Uther." , duration = 10.0})
	end
end

function StartArthasArena(keys)
	DoEntFire("door_magtheridon", "SetAnimation", "gate_02_close", 0, nil, nil)
	local DoorObs = Entities:FindAllByName("obstruction_magtheridon")
	for _, obs in pairs(DoorObs) do
		obs:SetEnabled(true, false)
	end

	local arthas = CreateUnitByName("npc_dota_hero_arthas", Entities:FindByName(nil,"npc_dota_spawner_magtheridon_arena"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_CUSTOM_2)
	arthas:SetAngles(0, 270, 0)
	arthas:AddNewModifier(nil, nil, "modifier_boss_stun", {Duration = 10, IsHidden = true})
	arthas:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 9, IsHidden = true})
--	BossBar(arthas, "arthas")
	arthas.zone = "xhs_holdout"

	TeleportAllHeroes("point_teleport_boss_", 10.0, 3.0)
end

function StartBanehallowArena()
	Timers:CreateTimer(8,function()
	local banehallow = CreateUnitByName("npc_dota_hero_banehallow",Entities:FindByName(nil,"npc_dota_spawner_magtheridon_arena"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_CUSTOM_2)
	banehallow:SetAngles(0, 270, 0)
	banehallow:AddNewModifier(nil, nil, "modifier_boss_stun", {Duration = 26, IsHidden = true})
	banehallow:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 14, IsHidden = true})
	banehallow:EmitSound("shop_jbrice_01.stinger.radiant_lose")
--	BossBar(banehallow, "banehallow")
	banehallow.zone = "xhs_holdout"
	end)

	Timers:CreateTimer(12,function()
		local green_revenant = CreateUnitByName("npc_death_revenant_banehallow",Entities:FindByName(nil,"npc_dota_spawner_green_revenant_1"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_CUSTOM_2)
		green_revenant:SetAngles(0, 340, 0)
		green_revenant:AddNewModifier(nil, nil, "modifier_boss_stun", {duration = 12, IsHidden = true})
		green_revenant:AddNewModifier(nil, nil, "modifier_invulnerable", {duration = 12, IsHidden = true})
		local green_revenant2 = CreateUnitByName("npc_death_revenant_banehallow",Entities:FindByName(nil,"npc_dota_spawner_green_revenant_7"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_CUSTOM_2)
		green_revenant2:SetAngles(0, 170, 0)
		green_revenant2:AddNewModifier(nil, nil, "modifier_boss_stun", {duration = 12, IsHidden = true})
		green_revenant2:AddNewModifier(nil, nil, "modifier_invulnerable", {duration = 12, IsHidden = true})
	end)

	Timers:CreateTimer(13.5,function()
		local green_revenant = CreateUnitByName("npc_death_revenant_banehallow",Entities:FindByName(nil,"npc_dota_spawner_green_revenant_2"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_CUSTOM_2)
		green_revenant:SetAngles(0, 320, 0)
		green_revenant:AddNewModifier(nil, nil, "modifier_boss_stun", {duration = 10.5, IsHidden = true})
		green_revenant:AddNewModifier(nil, nil, "modifier_invulnerable", {duration = 10.5, IsHidden = true})
		local green_revenant2 = CreateUnitByName("npc_death_revenant_banehallow",Entities:FindByName(nil,"npc_dota_spawner_green_revenant_8"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_CUSTOM_2)
		green_revenant2:SetAngles(0, 150, 0)
		green_revenant2:AddNewModifier(nil, nil, "modifier_boss_stun", {duration = 10.5, IsHidden = true})
		green_revenant2:AddNewModifier(nil, nil, "modifier_invulnerable", {duration = 10.5, IsHidden = true})
	end)

	Timers:CreateTimer(15,function()
		local green_revenant = CreateUnitByName("npc_death_revenant_banehallow",Entities:FindByName(nil,"npc_dota_spawner_green_revenant_3"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_CUSTOM_2)
		green_revenant:SetAngles(0, 300, 0)
		green_revenant:AddNewModifier(nil, nil, "modifier_boss_stun", {duration = 9, IsHidden = true})
		green_revenant:AddNewModifier(nil, nil, "modifier_invulnerable", {duration = 9, IsHidden = true})
		local green_revenant2 = CreateUnitByName("npc_death_revenant_banehallow",Entities:FindByName(nil,"npc_dota_spawner_green_revenant_9"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_CUSTOM_2)
		green_revenant2:SetAngles(0, 130, 0)
		green_revenant2:AddNewModifier(nil, nil, "modifier_boss_stun", {duration = 9, IsHidden = true})
		green_revenant2:AddNewModifier(nil, nil, "modifier_invulnerable", {duration = 9, IsHidden = true})
	end)

	Timers:CreateTimer(16.5,function()
		local green_revenant = CreateUnitByName("npc_death_revenant_banehallow",Entities:FindByName(nil,"npc_dota_spawner_green_revenant_4"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_CUSTOM_2)
		green_revenant:SetAngles(0, 240, 0)
		green_revenant:AddNewModifier(nil, nil, "modifier_boss_stun", {duration = 7.5, IsHidden = true})
		green_revenant:AddNewModifier(nil, nil, "modifier_invulnerable", {duration = 7.5, IsHidden = true})
		local green_revenant2 = CreateUnitByName("npc_death_revenant_banehallow",Entities:FindByName(nil,"npc_dota_spawner_green_revenant_10"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_CUSTOM_2)
		green_revenant2:SetAngles(0, 50, 0)
		green_revenant2:AddNewModifier(nil, nil, "modifier_boss_stun", {duration = 7.5, IsHidden = true})
		green_revenant2:AddNewModifier(nil, nil, "modifier_invulnerable", {duration = 7.5, IsHidden = true})
	end)

	Timers:CreateTimer(18,function()
		local green_revenant = CreateUnitByName("npc_death_revenant_banehallow",Entities:FindByName(nil,"npc_dota_spawner_green_revenant_5"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_CUSTOM_2)
		green_revenant:SetAngles(0, 220, 0)
		green_revenant:AddNewModifier(nil, nil, "modifier_boss_stun", {duration = 5, IsHidden = true})
		green_revenant:AddNewModifier(nil, nil, "modifier_invulnerable", {duration = 5, IsHidden = true})
		local green_revenant2 = CreateUnitByName("npc_death_revenant_banehallow",Entities:FindByName(nil,"npc_dota_spawner_green_revenant_11"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_CUSTOM_2)
		green_revenant2:SetAngles(0, 30, 0)
		green_revenant2:AddNewModifier(nil, nil, "modifier_boss_stun", {duration = 5, IsHidden = true})
		green_revenant2:AddNewModifier(nil, nil, "modifier_invulnerable", {duration = 5, IsHidden = true})
	end)

	Timers:CreateTimer(19.5,function()
		local green_revenant = CreateUnitByName("npc_death_revenant_banehallow",Entities:FindByName(nil,"npc_dota_spawner_green_revenant_6"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_CUSTOM_2)
		green_revenant:SetAngles(0, 200, 0)
		green_revenant:AddNewModifier(nil, nil, "modifier_boss_stun", {duration = 3.5, IsHidden = true})
		green_revenant:AddNewModifier(nil, nil, "modifier_invulnerable", {duration = 3.5, IsHidden = true})
		local green_revenant2 = CreateUnitByName("npc_death_revenant_banehallow",Entities:FindByName(nil,"npc_dota_spawner_green_revenant_12"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_CUSTOM_2)
		green_revenant2:SetAngles(0, 10, 0)
		green_revenant2:AddNewModifier(nil, nil, "modifier_boss_stun", {duration = 3.5, IsHidden = true})
		green_revenant2:AddNewModifier(nil, nil, "modifier_invulnerable", {duration = 3.5, IsHidden = true})
	end)
end

function StartLichKingArena()
local point_boss = Entities:FindByName(nil, "npc_dota_spawner_lich_king_bis"):GetAbsOrigin()
local reincarnate_time = 8.0

	if not XHS_LICH_KING_BOSS then
		Notifications:TopToAll({text="Something went wrong, please report Lich King not spawning on Discord!" , duration = 5.0})		
		return
	end

	for _, hero in pairs(HeroList:GetAllHeroes()) do
		if hero:IsRealHero() and hero:GetTeam() == DOTA_TEAM_GOODGUYS then
			local id = hero:GetPlayerID()
			print("ID:", id)
			if type(id) == "number" and id ~= -1 then
				local point = Entities:FindByName(nil, "point_teleport_boss_"..id)
				FindClearSpaceForUnit(hero, point:GetAbsOrigin(), true)
				hero:AddNewModifier(nil, nil, "modifier_animation_freeze_stun", {Duration = 20, IsHidden = true})
				hero:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 20, IsHidden = true})
				hero:Stop()
				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), XHS_LICH_KING_BOSS)

				Timers:CreateTimer(0.5, function()
					PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), nil)
				end)
			end
		end
	end

	Timers:CreateTimer(2.0, function()
		StartAnimation(XHS_LICH_KING_BOSS, {duration = reincarnate_time, activity = ACT_DOTA_SPAWN, rate = 1.0})

		Timers:CreateTimer(5.0, function()
			XHS_LICH_KING_BOSS:EmitSound("Hero_SkeletonKing.Reincarnate")
		end)

		Timers:CreateTimer(reincarnate_time, function()
			FindClearSpaceForUnit(XHS_LICH_KING_BOSS, point_boss, true)
			XHS_LICH_KING_BOSS:RemoveModifierByName("modifier_invulnerable")
			XHS_LICH_KING_BOSS:RemoveModifierByName("modifier_stunned")
			XHS_LICH_KING_BOSS:SetAttackCapability(DOTA_UNIT_CAP_MELEE_ATTACK)
			XHS_LICH_KING_BOSS:SetMoveCapability(DOTA_UNIT_CAP_MOVE_GROUND)
--			BossBar(XHS_LICH_KING_BOSS, "lich_king")
			XHS_LICH_KING_BOSS.zone = "xhs_holdout"
		end)
	end)

	Timers:CreateTimer(14.0, function()
		Notifications:TopToAll({text="From death, i grow stronger!" , duration = 5.0})
	end)
end

function StartSecretArena(hero)
	local point = Entities:FindByName(nil, "npc_dota_muradin_player_1")

	TeleportHero(hero, 3.0, point:GetAbsOrigin())

	Timers:CreateTimer(3.0, function()
		FindClearSpaceForUnit(hero, point:GetAbsOrigin(), true)
		hero:AddNewModifier(nil, nil, "modifier_animation_freeze_stun", {Duration = 10, IsHidden = true})
		hero:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 10, IsHidden = true})
		hero:Stop()
		PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), hero)
		Timers:CreateTimer(0.1, function()
			PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), nil)
		end)

		Notifications:BottomToAll({ hero = hero:GetUnitName(), duration = 5.0 })
		Notifications:BottomToAll({ text = PlayerResource:GetPlayerName(hero:GetPlayerID()) .. " ", duration = 5.0, continue = true })
		Notifications:BottomToAll({ text = "found the secret arena!!! GOOD LUCK!", duration = 5.0, style = { color = "red" }, continue = true })

		local secret = CreateUnitByName("npc_dota_hero_secret", Entities:FindByName(nil, "npc_dota_muradin_boss"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
		secret:SetAngles(0, 270, 0)
		secret:AddNewModifier(nil, nil, "modifier_boss_stun", {Duration = 10, IsHidden = true})
		secret:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 9, IsHidden = true})
	end)
end
