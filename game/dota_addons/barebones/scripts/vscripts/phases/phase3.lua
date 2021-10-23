function StartMagtheridonArena()
	local point_mag = Entities:FindByName(nil, "npc_dota_spawner_magtheridon_arena"):GetAbsOrigin()
	local point_mag2 = Entities:FindByName(nil, "npc_dota_spawner_magtheridon_arena2"):GetAbsOrigin()
	local difficulty = GameRules:GetCustomGameDifficulty()
	local delay = 3.0

	RefreshPlayers()

	TeleportAllHeroes("point_teleport_boss_", 10.0 + delay, delay)

	Timers:CreateTimer(delay, function()
		magtheridon = CreateUnitByName("npc_dota_hero_magtheridon", point_mag  ,true, nil, nil, DOTA_TEAM_CUSTOM_2)
		magtheridon:SetAngles(0, 180, 0)
		magtheridon.zone = "xhs_holdout"

		if difficulty == 2 then
			magtheridon:AddNewModifier(magtheridon, nil, "modifier_ankh", {charges = 1})
		elseif difficulty == 3 then
			magtheridon:AddNewModifier(magtheridon, nil, "modifier_ankh", {charges = 3})
		elseif difficulty == 4 then
			magtheridon:AddNewModifier(magtheridon, nil, "modifier_ankh", {charges = 1})

			magtheridon2 = CreateUnitByName("npc_dota_hero_magtheridon", point_mag2  ,true, nil, nil, DOTA_TEAM_CUSTOM_2)
			magtheridon2:SetAngles(0, 0, 0)
			magtheridon2:AddNewModifier(magtheridon, nil, "modifier_ankh", {charges = 1})
			magtheridon2:AddNewModifier(nil, nil, "modifier_pause_creeps", {Duration = 10, IsHidden = true}):SetStackCount(1)
			magtheridon2:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 10, IsHidden = true})
			magtheridon2.zone = "xhs_holdout"
			magtheridon2.boss_count = 2
		elseif difficulty == 5 then
			magtheridon:AddNewModifier(magtheridon, nil, "modifier_ankh", {charges = 2})

			magtheridon2 = CreateUnitByName("npc_dota_hero_magtheridon", point_mag2  ,true, nil, nil, DOTA_TEAM_CUSTOM_2)
			magtheridon2:SetAngles(0, 0, 0)
			magtheridon2:AddNewModifier(magtheridon, nil, "modifier_ankh", {charges = 2})
			magtheridon2:AddNewModifier(nil, nil, "modifier_pause_creeps", {Duration = 10, IsHidden = true}):SetStackCount(1)
			magtheridon2:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 10, IsHidden = true})
			magtheridon2.zone = "xhs_holdout"
			magtheridon2.boss_count = 2
		end

		magtheridon:AddNewModifier(nil, nil, "modifier_pause_creeps", {Duration = 10, IsHidden = true}):SetStackCount(1)
		magtheridon:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 10, IsHidden = true})
	end)
end

function EndMagtheridonArena()
	Entities:FindByName(nil, "trigger_teleport_phase3_creeps"):Enable()

	CustomGameEventManager:Send_ServerToAllClients("hide_boss_hp", {boss_count = 1})
	CustomGameEventManager:Send_ServerToAllClients("hide_boss_hp", {boss_count = 2})
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

	RefreshPlayers()

	Timers:CreateTimer(0.5, function()
		DoEntFire("trigger_teleport_phase3_creeps", "Kill", nil, 0, nil, nil)
		TeleportAllHeroes("point_teleport_phase3_creeps_", 5.0)
		GiveTomeToAllHeroes(250)

		for i = 0, PlayerResource:GetPlayerCount() - 1 do
			Timers:CreateTimer(3.0, function()
				for i = 1, 4 * GameRules:GetCustomGameDifficulty() do
					local unit = CreateUnitByName("npc_dota_creep_dire_hulk", point2 + RandomVector(RandomInt(0, 50)), true, nil, nil, DOTA_TEAM_CUSTOM_2)
				end
			end)

			Timers:CreateTimer(5.0, function()
				for i = 1, 4 * GameRules:GetCustomGameDifficulty() do
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
	arthas:AddNewModifier(nil, nil, "modifier_pause_creeps", {Duration = 7, IsHidden = true}):SetStackCount(1)
	arthas:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 7, IsHidden = true})
--	BossBar(arthas, "arthas")
	arthas.zone = "xhs_holdout"

	TeleportAllHeroes("point_teleport_boss_", 10.0, 3.0)
end

function StartBanehallowArena()
	TeleportAllHeroes("point_teleport_boss_", 25.0, 3.0)
	local banehallow

	Timers:CreateTimer(8,function()
		banehallow = CreateUnitByName("npc_dota_hero_banehallow",Entities:FindByName(nil,"npc_dota_spawner_magtheridon_arena"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_CUSTOM_2)
		banehallow:SetAngles(0, 270, 0)
		banehallow:AddNewModifier(nil, nil, "modifier_pause_creeps", {Duration = 26, IsHidden = true}):SetStackCount(1)
		banehallow:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 14, IsHidden = true})
		banehallow:EmitSound("shop_jbrice_01.stinger.radiant_lose")
		banehallow.zone = "xhs_holdout"
	end)

	Timers:CreateTimer(12,function()
		local green_revenant = CreateUnitByName("npc_death_revenant_banehallow",Entities:FindByName(nil,"npc_dota_spawner_green_revenant_1"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_CUSTOM_2)
		green_revenant:SetAngles(0, 340, 0)
		green_revenant:AddNewModifier(nil, nil, "modifier_pause_creeps", {duration = 12, IsHidden = true})
		green_revenant:AddNewModifier(nil, nil, "modifier_invulnerable", {duration = 12, IsHidden = true}):SetStackCount(1)
		green_revenant:SetRenderColor(20, 200, 20)

		local green_revenant2 = CreateUnitByName("npc_death_revenant_banehallow",Entities:FindByName(nil,"npc_dota_spawner_green_revenant_7"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_CUSTOM_2)
		green_revenant2:SetAngles(0, 170, 0)
		green_revenant2:AddNewModifier(nil, nil, "modifier_pause_creeps", {duration = 12, IsHidden = true}):SetStackCount(1)
		green_revenant2:AddNewModifier(nil, nil, "modifier_invulnerable", {duration = 12, IsHidden = true})
		green_revenant2:SetRenderColor(20, 200, 20)
	end)

	Timers:CreateTimer(13.5,function()
		local green_revenant = CreateUnitByName("npc_death_revenant_banehallow",Entities:FindByName(nil,"npc_dota_spawner_green_revenant_2"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_CUSTOM_2)
		green_revenant:SetAngles(0, 320, 0)
		green_revenant:AddNewModifier(nil, nil, "modifier_pause_creeps", {duration = 10.5, IsHidden = true}):SetStackCount(1)
		green_revenant:AddNewModifier(nil, nil, "modifier_invulnerable", {duration = 10.5, IsHidden = true})
		green_revenant:SetRenderColor(20, 200, 20)

		local green_revenant2 = CreateUnitByName("npc_death_revenant_banehallow",Entities:FindByName(nil,"npc_dota_spawner_green_revenant_8"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_CUSTOM_2)
		green_revenant2:SetAngles(0, 150, 0)
		green_revenant2:AddNewModifier(nil, nil, "modifier_pause_creeps", {duration = 10.5, IsHidden = true}):SetStackCount(1)
		green_revenant2:AddNewModifier(nil, nil, "modifier_invulnerable", {duration = 10.5, IsHidden = true})
		green_revenant2:SetRenderColor(20, 200, 20)
	end)

	Timers:CreateTimer(15,function()
		local green_revenant = CreateUnitByName("npc_death_revenant_banehallow",Entities:FindByName(nil,"npc_dota_spawner_green_revenant_3"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_CUSTOM_2)
		green_revenant:SetAngles(0, 300, 0)
		green_revenant:AddNewModifier(nil, nil, "modifier_pause_creeps", {duration = 9, IsHidden = true}):SetStackCount(1)
		green_revenant:AddNewModifier(nil, nil, "modifier_invulnerable", {duration = 9, IsHidden = true})
		green_revenant:SetRenderColor(20, 200, 20)

		local green_revenant2 = CreateUnitByName("npc_death_revenant_banehallow",Entities:FindByName(nil,"npc_dota_spawner_green_revenant_9"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_CUSTOM_2)
		green_revenant2:SetAngles(0, 130, 0)
		green_revenant2:AddNewModifier(nil, nil, "modifier_pause_creeps", {duration = 9, IsHidden = true}):SetStackCount(1)
		green_revenant2:AddNewModifier(nil, nil, "modifier_invulnerable", {duration = 9, IsHidden = true})
		green_revenant2:SetRenderColor(20, 200, 20)
	end)

	Timers:CreateTimer(16.5,function()
		local green_revenant = CreateUnitByName("npc_death_revenant_banehallow",Entities:FindByName(nil,"npc_dota_spawner_green_revenant_4"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_CUSTOM_2)
		green_revenant:SetAngles(0, 240, 0)
		green_revenant:AddNewModifier(nil, nil, "modifier_pause_creeps", {duration = 7.5, IsHidden = true}):SetStackCount(1)
		green_revenant:AddNewModifier(nil, nil, "modifier_invulnerable", {duration = 7.5, IsHidden = true})
		green_revenant:SetRenderColor(20, 200, 20)

		local green_revenant2 = CreateUnitByName("npc_death_revenant_banehallow",Entities:FindByName(nil,"npc_dota_spawner_green_revenant_10"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_CUSTOM_2)
		green_revenant2:SetAngles(0, 50, 0)
		green_revenant2:AddNewModifier(nil, nil, "modifier_pause_creeps", {duration = 7.5, IsHidden = true}):SetStackCount(1)
		green_revenant2:AddNewModifier(nil, nil, "modifier_invulnerable", {duration = 7.5, IsHidden = true})
		green_revenant2:SetRenderColor(20, 200, 20)
	end)

	Timers:CreateTimer(18,function()
		local green_revenant = CreateUnitByName("npc_death_revenant_banehallow",Entities:FindByName(nil,"npc_dota_spawner_green_revenant_5"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_CUSTOM_2)
		green_revenant:SetAngles(0, 220, 0)
		green_revenant:AddNewModifier(nil, nil, "modifier_pause_creeps", {duration = 5, IsHidden = true}):SetStackCount(1)
		green_revenant:AddNewModifier(nil, nil, "modifier_invulnerable", {duration = 5, IsHidden = true})
		green_revenant:SetRenderColor(20, 200, 20)

		local green_revenant2 = CreateUnitByName("npc_death_revenant_banehallow",Entities:FindByName(nil,"npc_dota_spawner_green_revenant_11"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_CUSTOM_2)
		green_revenant2:SetAngles(0, 30, 0)
		green_revenant2:AddNewModifier(nil, nil, "modifier_pause_creeps", {duration = 5, IsHidden = true}):SetStackCount(1)
		green_revenant2:AddNewModifier(nil, nil, "modifier_invulnerable", {duration = 5, IsHidden = true})
		green_revenant2:SetRenderColor(20, 200, 20)
	end)

	Timers:CreateTimer(19.5,function()
		local green_revenant = CreateUnitByName("npc_death_revenant_banehallow",Entities:FindByName(nil,"npc_dota_spawner_green_revenant_6"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_CUSTOM_2)
		green_revenant:SetAngles(0, 200, 0)
		green_revenant:AddNewModifier(nil, nil, "modifier_pause_creeps", {duration = 3.5, IsHidden = true}):SetStackCount(1)
		green_revenant:AddNewModifier(nil, nil, "modifier_invulnerable", {duration = 3.5, IsHidden = true})
		green_revenant:SetRenderColor(20, 200, 20)

		local green_revenant2 = CreateUnitByName("npc_death_revenant_banehallow",Entities:FindByName(nil,"npc_dota_spawner_green_revenant_12"):GetAbsOrigin(),true,nil,nil,DOTA_TEAM_CUSTOM_2)
		green_revenant2:SetAngles(0, 10, 0)
		green_revenant2:AddNewModifier(nil, nil, "modifier_pause_creeps", {duration = 3.5, IsHidden = true}):SetStackCount(1)
		green_revenant2:AddNewModifier(nil, nil, "modifier_invulnerable", {duration = 3.5, IsHidden = true})
		green_revenant2:SetRenderColor(20, 200, 20)

		if banehallow then
			banehallow:AddNewModifier(banehallow, nil, "boss_thinker_nevermore", {})
		end
	end)
end

function StartLichKingArena()
	local point_boss = Entities:FindByName(nil, "npc_dota_spawner_lich_king_bis"):GetAbsOrigin()
	local reincarnate_time = 8.0
	local enemies = FindUnitsInRadius(DOTA_TEAM_CUSTOM_2, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
	local lich_king_boss = nil

	for _, enemy in pairs(enemies) do
		if enemy:GetUnitName() == "npc_dota_boss_lich_king" then
			lich_king_boss = enemy
			break
		end
	end

	if not lich_king_boss then
		Notifications:TopToAll({text="Something went wrong, please report Lich King not spawning on Discord!" , duration = 5.0})		
		return
	end

	TeleportAllHeroes("point_teleport_boss_", 20.0, 3.0)

	Timers:CreateTimer(2.0, function()
		StartAnimation(lich_king_boss, {duration = reincarnate_time, activity = ACT_DOTA_SPAWN, rate = 1.0})

		Timers:CreateTimer(5.0, function()
			lich_king_boss:EmitSound("Hero_SkeletonKing.Reincarnate")
		end)

		Timers:CreateTimer(reincarnate_time, function()
			FindClearSpaceForUnit(lich_king_boss, point_boss, true)
			lich_king_boss:RemoveModifierByName("modifier_invulnerable")
			lich_king_boss:RemoveModifierByName("modifier_stunned")
			lich_king_boss:MoveToPositionAggressive(Entities:FindByName(nil,"npc_dota_spawner_magtheridon_arena"):GetAbsOrigin())
			lich_king_boss:SetAttackCapability(DOTA_UNIT_CAP_MELEE_ATTACK)
			lich_king_boss:SetMoveCapability(DOTA_UNIT_CAP_MOVE_GROUND)
--			BossBar(lich_king_boss, "lich_king")
			lich_king_boss.zone = "xhs_holdout"

			for _, hero in pairs(HeroList:GetAllHeroes()) do
				if hero:IsRealHero() and hero:GetTeam() == DOTA_TEAM_GOODGUYS then
					CustomGameEventManager:Send_ServerToPlayer(hero:GetPlayerOwner(), "set_player_camera", {hPosition = lich_king_boss:GetAbsOrigin()})
				end
			end
		end)
	end)

	Timers:CreateTimer(14.0, function()
		Notifications:TopToAll({text="From death, i grow stronger!" , duration = 5.0})
	end)
end

function StartSpiritMasterArena()
	local point_boss = Entities:FindByName(nil, "npc_dota_spawner_lich_king_bis"):GetAbsOrigin()
	local start_time = 15.0

	TeleportAllHeroes("point_teleport_boss_", start_time + 1, 3.0)

	local spirit_master = CreateUnitByName("npc_dota_boss_spirit_master", Entities:FindByName(nil, "npc_dota_spawner_magtheridon_arena"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
	spirit_master:SetAngles(0, 270, 0)
	spirit_master:AddNewModifier(nil, nil, "modifier_pause_creeps", {Duration = start_time, IsHidden = true}):SetStackCount(1)
	spirit_master:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = start_time, IsHidden = true})
	spirit_master:EmitSound("SpiritMaster.StartArena")
	spirit_master.zone = "xhs_holdout"

	Timers:CreateTimer(start_time / 2, function()
		Notifications:TopToAll({text="Spirits. Assemble!" , duration = 5.0})
	end)
end

function StartSecretArena(hero)
	local point = Entities:FindByName(nil, "npc_dota_muradin_player_1")

	TeleportHero(hero, point:GetAbsOrigin(), 3.0)

	Timers:CreateTimer(3.0, function()
		FindClearSpaceForUnit(hero, point:GetAbsOrigin(), true)
		hero:AddNewModifier(nil, nil, "modifier_pause_creeps", {Duration = 10, IsHidden = true}):SetStackCount(1)
		hero:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 10, IsHidden = true})

		TeleportHero(hero, hero:GetAbsOrigin())

		Notifications:BottomToAll({ hero = hero:GetUnitName(), duration = 5.0 })
		Notifications:BottomToAll({ text = PlayerResource:GetPlayerName(hero:GetPlayerID()) .. " ", duration = 5.0, continue = true })
		Notifications:BottomToAll({ text = "found the secret arena!!! GOOD LUCK!", duration = 5.0, style = { color = "red" }, continue = true })

		local secret = CreateUnitByName("npc_dota_hero_secret", Entities:FindByName(nil, "npc_dota_muradin_boss"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
		secret:SetAngles(0, 270, 0)
		secret:AddNewModifier(nil, nil, "modifier_pause_creeps", {Duration = 10, IsHidden = true}):SetStackCount(1)
		secret:AddNewModifier(nil, nil, "modifier_invulnerable", {Duration = 9, IsHidden = true})
	end)
end
