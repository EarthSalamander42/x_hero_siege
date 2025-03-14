ListenToGameEvent('game_rules_state_change', function(keys)
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		if _G.INIT_CHOOSE_HERO == false then
			_G.INIT_CHOOSE_HERO = true

			-- Need a timer else Battlepass is nil when first dummy hero spawn
			Timers:CreateTimer(1.0, function()
				SpawnHeroesBis()
				SpawnBosses()
			end)
		end
	end
end, nil)

function SpawnHeroLoadout(hero_count)
	local left_angle = { 4, 5, 6, 7, 8, 14, 15, 16 }
	local top_angle = { 11, 12, 13, 22, 23, 24, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39 }
	local bot_angle = { 9, 10, 25, 26, 27 }

	local hero = CreateUnitByName("npc_dota_hero_" .. HEROLIST[hero_count], Entities:FindByName(nil, "choose_" .. hero_count .. "_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	hero:AddAbility("dummy_passive_vulnerable"):SetLevel(1)
	hero.is_fake_hero = true

	for _, angle in pairs(left_angle) do
		if angle == hero_count then
			hero:SetAngles(0, 180, 0)
		end
	end

	for _, angle in pairs(top_angle) do
		if angle == hero_count then
			hero:SetAngles(0, 90, 0)
		end
	end

	for _, angle in pairs(bot_angle) do
		if angle == hero_count then
			hero:SetAngles(0, 270, 0)
		end
	end
end

function SpawnHeroesBis()
	local hero_count = 1
	local hero_vip_count = 1

	Timers:CreateTimer(function()
		SpawnHeroLoadout(hero_count)
		if hero_count < #HEROLIST then
			hero_count = hero_count + 1
			return 0.3
		else
			return nil
		end
	end)

	Timers:CreateTimer(5.0, function()
		if hero_vip_count == 4 then
			local dummy_hero = CreateUnitByName("npc_dota_hero_chaos_knight", Entities:FindByName(nil, "choose_vip_4_point"):GetAbsOrigin() + Vector(-100, 0, 0), true, nil, nil, DOTA_TEAM_GOODGUYS)
			dummy_hero:SetAngles(0, 270, 0)
			dummy_hero:AddAbility("dummy_passive_vulnerable"):SetLevel(1)
			dummy_hero.is_fake_hero = true
			local dummy_hero = CreateUnitByName("npc_dota_hero_keeper_of_the_light", Entities:FindByName(nil, "choose_vip_4_point"):GetAbsOrigin() + Vector(100, 0, 0), true, nil, nil, DOTA_TEAM_GOODGUYS)
			dummy_hero:SetAngles(0, 270, 0)
			dummy_hero:AddAbility("dummy_passive_vulnerable"):SetLevel(1)
			dummy_hero.is_fake_hero = true
		elseif hero_vip_count == 8 then
			local dummy_hero = CreateUnitByName("npc_dota_hero_storm_spirit", Entities:FindByName(nil, "choose_vip_8_point"):GetAbsOrigin() + Vector(0, 100, 0), true, nil, nil, DOTA_TEAM_GOODGUYS)
			dummy_hero:SetAngles(0, 270, 0)
			dummy_hero:AddAbility("dummy_passive_vulnerable"):SetLevel(1)
			dummy_hero.is_fake_hero = true
			local dummy_hero = CreateUnitByName("npc_dota_hero_ember_spirit", Entities:FindByName(nil, "choose_vip_8_point"):GetAbsOrigin() + Vector(-100, 0, 0), true, nil, nil, DOTA_TEAM_GOODGUYS)
			dummy_hero:SetAngles(0, 270, 0)
			dummy_hero:AddAbility("dummy_passive_vulnerable"):SetLevel(1)
			dummy_hero.is_fake_hero = true
			local dummy_hero = CreateUnitByName("npc_dota_hero_earth_spirit", Entities:FindByName(nil, "choose_vip_8_point"):GetAbsOrigin() + Vector(100, 0, 0), true, nil, nil, DOTA_TEAM_GOODGUYS)
			dummy_hero:SetAngles(0, 270, 0)
			dummy_hero:AddAbility("dummy_passive_vulnerable"):SetLevel(1)
			dummy_hero.is_fake_hero = true
		else
			local dummy_hero = CreateUnitByName("npc_dota_hero_" .. HEROLIST_VIP[hero_vip_count], Entities:FindByName(nil, "choose_vip_" .. hero_vip_count .. "_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
			dummy_hero:AddAbility("dummy_passive_vulnerable"):SetLevel(1)
			dummy_hero:SetAngles(0, 270, 0)
			dummy_hero.is_fake_hero = true
		end

		if hero_vip_count < #HEROLIST_VIP then
			hero_vip_count = hero_vip_count + 1
			return 0.3
		else
			return nil
		end
	end)
end

function SpawnBosses()
	_G.RAMERO_DUMMY = CreateUnitByName("npc_ramero", Entities:FindByName(nil, "point_special_arena_1"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	_G.RAMERO_DUMMY:SetAngles(0, 270, 0)
	_G.RAMERO_DUMMY:AddNewModifier(_G.RAMERO_DUMMY, nil, "modifier_command_restricted", {})
	_G.BARISTOL_DUMMY = CreateUnitByName("npc_baristol", Entities:FindByName(nil, "point_special_arena_2"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	_G.BARISTOL_DUMMY:SetAngles(0, 270, 0)
	_G.BARISTOL_DUMMY:AddNewModifier(_G.BARISTOL_DUMMY, nil, "modifier_command_restricted", {})
	_G.RAMERO_BIS_DUMMY = CreateUnitByName("npc_ramero_2", Entities:FindByName(nil, "point_special_arena_3"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	_G.RAMERO_BIS_DUMMY:SetAngles(0, 270, 0)
	_G.RAMERO_BIS_DUMMY:AddNewModifier(_G.RAMERO_BIS_DUMMY, nil, "modifier_command_restricted", {})

	-- Special events
	local lich_king_boss = CreateUnitByName("npc_dota_boss_lich_king", Entities:FindByName(nil, "npc_dota_spawner_lich_king"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_2)
	lich_king_boss:SetAngles(0, 90, 0)
	CustomGameEventManager:Send_ServerToAllClients("hide_boss_hp", { boss_count = 1 })

	-- Suddenly non-vanilla modifiers are not working on Lich King
	lich_king_boss:AddNewModifier(lich_king_boss, nil, "modifier_invulnerable", {})
	lich_king_boss:AddNewModifier(lich_king_boss, nil, "modifier_stunned", {})
end

function ChooseHero(event)
	local hero = event.activator
	if hero == nil or hero.GetPlayerID == nil or hero:GetPlayerID() == nil then return end
	local caller = event.caller
	local id = hero:GetPlayerID()
	local difficulty = GameRules:GetCustomGameDifficulty()

	if PlayerResource:IsValidPlayer(id) and hero:GetUnitName() == "npc_dota_hero_wisp" then
		for i = 1, #HEROLIST do -- 12 = POTM.
			if caller:GetName() == "trigger_hero_" .. i then
				UTIL_Remove(Entities:FindByName(nil, "trigger_hero_" .. i))
				local particle = ParticleManager:CreateParticle("particles/generic_hero_status/hero_levelup.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero, hero)
				ParticleManager:SetParticleControl(particle, 0, hero:GetAbsOrigin())
				EmitSoundOnClient("ui.trophy_levelup", PlayerResource:GetPlayer(id))
				hero:AddNewModifier(hero, nil, "modifier_command_restricted", {})
				local picked_hero_name = "npc_dota_hero_" .. HEROLIST[i]
				Notifications:Bottom(hero:GetPlayerOwnerID(), { hero = picked_hero_name, duration = 5.0 })
				Notifications:Bottom(hero:GetPlayerOwnerID(), { text = "HERO: ", duration = 5.0, style = { color = "white" }, continue = true })
				Notifications:Bottom(hero:GetPlayerOwnerID(), { text = "#" .. picked_hero_name, duration = 5.0, style = { color = "white" }, continue = true })

				PrecacheUnitByNameAsync(picked_hero_name, function()
					local newHero = PlayerResource:ReplaceHeroWith(id, picked_hero_name, XHS_STARTING_GOLD[difficulty], 0)
					StartingItems(hero, newHero)

					Timers:CreateTimer(0.1, function()
						if not hero:IsNull() then
							UTIL_Remove(hero)
						end
					end)
				end, id)

				return
			end
		end
	end
end

function ChooseHeroVIP(event)
	local hero = event.activator
	if hero == nil or hero.GetPlayerID == nil or hero:GetPlayerID() == nil then return end
	local caller = event.caller
	local id = hero:GetPlayerID()
	local difficulty = GameRules:GetCustomGameDifficulty()

	if PlayerResource:IsValidPlayer(id) and hero:GetUnitName() == "npc_dota_hero_wisp" then
		for i = 1, #HEROLIST_VIP do
			if caller:GetName() == "trigger_hero_vip_" .. i then
				local picked_hero_name = "npc_dota_hero_" .. HEROLIST_VIP[i]
				UTIL_Remove(Entities:FindByName(nil, "trigger_hero_vip_" .. i))
				local particle = ParticleManager:CreateParticle("particles/generic_hero_status/hero_levelup.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
				ParticleManager:SetParticleControl(particle, 0, hero:GetAbsOrigin())
				EmitSoundOnClient("ui.trophy_levelup", PlayerResource:GetPlayer(id))
				hero:AddNewModifier(hero, nil, "modifier_command_restricted", {})
				Notifications:Bottom(hero:GetPlayerOwnerID(), { hero = picked_hero_name, duration = 5.0 })
				Notifications:Bottom(hero:GetPlayerOwnerID(), { text = "HERO: ", duration = 5.0, style = { color = "white" }, continue = true })
				Notifications:Bottom(hero:GetPlayerOwnerID(), { text = "#npc_dota_hero_" .. HEROLIST_VIP[i], duration = 5.0, style = { color = "white" }, continue = true })

				PrecacheUnitByNameAsync(picked_hero_name, function()
					local newHero = PlayerResource:ReplaceHeroWith(id, picked_hero_name, XHS_STARTING_GOLD[difficulty], 0)
					StartingItems(hero, newHero)

					Timers:CreateTimer(0.1, function()
						if not hero:IsNull() then
							UTIL_Remove(hero)
						end
					end)
				end, id)

				if picked_hero_name == "npc_dota_hero_storm_spirit" then
					PrecacheUnitByNameAsync("npc_dota_hero_ember_spirit", function()
					end, id)
					PrecacheUnitByNameAsync("npc_dota_hero_earth_spirit", function()
					end, id)
				end

				return
			end
		end
	end
end
