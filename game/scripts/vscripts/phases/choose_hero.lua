STARTING_GOLD = { 10000, 5000, 4000, 3000, 2000 }

-- WeekHero = "npc_dota_hero_slardar"			-- Centurion
WeekHero = "npc_dota_hero_skeleton_king" -- Lich King
-- WeekHero = "npc_dota_hero_meepo"			-- Kobold Knight
-- WeekHero = "npc_dota_hero_tiny"				-- Stone Giant
-- WeekHero = "npc_dota_hero_sand_king"		-- Desert Wyrm
-- WeekHero = "npc_dota_hero_necrolyte"		-- Dark Summoner

-- the first hero will be selected by default when using a table
--[[
WeekHero = { -- Spirit Master
	"npc_dota_hero_storm_spirit",
	"npc_dota_hero_ember_spirit",
	"npc_dota_hero_earth_spirit",
}
--]]
-- WeekHero = { -- Dark Fundamental
--	"npc_dota_hero_chaos_knight",
--	"npc_dota_hero_keeper_of_the_light",
-- }

ListenToGameEvent('game_rules_state_change', function(keys)
	if GameRules:State_Get() == DOTA_GAMERULES_STATE_CUSTOM_GAME_SETUP then
		if _G.INIT_CHOOSE_HERO == false then
			_G.INIT_CHOOSE_HERO = true

			-- Need a timer else Battlepass is nil when first dummy hero spawn
			Timers:CreateTimer(1.0, function()
				SpawnHeroesBis()
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

	local vip_point = Entities:FindByName(nil, "choose_vip_point"):GetAbsOrigin()

	if type(WeekHero) == "table" then
		local pos = {}
		pos[1] = Vector(0, 100, 0)
		pos[2] = Vector(-100, 0, 0)
		pos[3] = Vector(100, 0, 0)

		for i, hero in ipairs(WeekHero) do
			local vip_hero = CreateUnitByName(hero, vip_point + pos[i], true, nil, nil, DOTA_TEAM_GOODGUYS)
			vip_hero:SetAngles(0, 270, 0)
			vip_hero:AddAbility("dummy_passive_vulnerable"):SetLevel(1)
			vip_hero.is_fake_hero = true
		end
	else
		local vip_hero = CreateUnitByName(WeekHero, vip_point, true, nil, nil, DOTA_TEAM_GOODGUYS)
		vip_hero:SetAngles(0, 270, 0)
		vip_hero:AddAbility("dummy_passive_vulnerable"):SetLevel(1)
	end
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
				Notifications:Bottom(hero:GetPlayerOwnerID(), { hero = "npc_dota_hero_" .. HEROLIST[i], duration = 5.0 })
				Notifications:Bottom(hero:GetPlayerOwnerID(), { text = "HERO: ", duration = 5.0, style = { color = "white" }, continue = true })
				Notifications:Bottom(hero:GetPlayerOwnerID(), { text = "#npc_dota_hero_" .. HEROLIST[i], duration = 5.0, style = { color = "white" }, continue = true })

				local newHero = PlayerResource:ReplaceHeroWith(id, "npc_dota_hero_" .. HEROLIST[i], STARTING_GOLD[difficulty], 0)
				StartingItems(hero, newHero)

				Timers:CreateTimer(0.1, function()
					if not hero:IsNull() then
						UTIL_Remove(hero)
					end
				end)

				return
			end

			if caller:GetName() == "trigger_hero_weekly" then
				if api:IsDonator(hero:GetPlayerID()) then
					Notifications:Bottom(hero:GetPlayerOwnerID(), { text = "You are VIP. Please choose this hero on top!", duration = 5.0 })

					return
				end

				UTIL_Remove(Entities:FindByName(nil, "trigger_hero_weekly"))
				local particle = ParticleManager:CreateParticle("particles/generic_hero_status/hero_levelup.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero, hero)
				ParticleManager:SetParticleControl(particle, 0, hero:GetAbsOrigin())
				EmitSoundOnClient("ui.trophy_levelup", PlayerResource:GetPlayer(id))
				hero:AddNewModifier(hero, nil, "modifier_command_restricted", {})
				local weekly_hero = WeekHero
				if type(WeekHero) == "table" then weekly_hero = WeekHero[0] end
				Notifications:Bottom(hero:GetPlayerOwnerID(), { hero = weekly_hero, duration = 5.0 })
				Notifications:Bottom(hero:GetPlayerOwnerID(), { text = "HERO: ", duration = 5.0, style = { color = "white" }, continue = true })
				Notifications:Bottom(hero:GetPlayerOwnerID(), { text = "#" .. weekly_hero, duration = 5.0, style = { color = "white" }, continue = true })

				local newHero = PlayerResource:ReplaceHeroWith(id, weekly_hero, STARTING_GOLD[difficulty], 0)
				StartingItems(hero, newHero)

				Timers:CreateTimer(0.1, function()
					if not hero:IsNull() then
						UTIL_Remove(hero)
					end
				end)

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

	if PlayerResource:IsValidPlayer(id) and hero:GetUnitName() == "npc_dota_hero_wisp" and api:IsDonator(hero:GetPlayerID()) then
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

				local newHero = PlayerResource:ReplaceHeroWith(id, picked_hero_name, STARTING_GOLD[difficulty], 0)
				StartingItems(hero, newHero)

				if picked_hero_name == "npc_dota_hero_storm_spirit" then
					PrecacheUnitByNameAsync("npc_dota_hero_ember_spirit", function()
					end)
					PrecacheUnitByNameAsync("npc_dota_hero_earth_spirit", function()
					end)
				end

				return
			end
		end
	elseif PlayerResource:IsValidPlayer(id) and hero:GetUnitName() == "npc_dota_hero_wisp" and not api:IsDonator(hero:GetPlayerID()) then
		Notifications:Bottom(hero:GetPlayerOwnerID(), { text = "This hero is only for <font color='#FF0000'>VIP Members!</font> Please choose another hero.", duration = 5.0 })
	end
end

function StartingItems(hero, newHero)
	local difficulty = GameRules:GetCustomGameDifficulty()

	if difficulty ~= 5 then
		newHero:AddNewModifier(newHero, nil, "modifier_ankh", { charges = 5 - difficulty })

		local item = newHero:AddItemByName("item_health_potion")
		item:SetPurchaseTime(0)

		local item = newHero:AddItemByName("item_mana_potion")
		item:SetPurchaseTime(0)

		if difficulty == 1 then
			local item = newHero:AddItemByName("item_lifesteal_mask")
			item:SetSellable(false)
		end
	end

	if newHero:GetTeamNumber() == 2 then
		TeleportHero(newHero, base_good:GetAbsOrigin(), 3.0)
	elseif newHero:GetTeamNumber() == 3 then
		TeleportHero(newHero, base_bad:GetAbsOrigin(), 3.0)
	end

	Timers:CreateTimer(0.1, function()
		if not hero:IsNull() then
			UTIL_Remove(hero)
		end
	end)

	Timers:CreateTimer(1.0, function()
		for k, v in pairs(HeroList:GetAllHeroes()) do
			if v and IsValidEntity(v) and not v:IsNull() and v:GetUnitName() == "npc_dota_hero_wisp" then
				--				print("A wisp was found! Players are still picking a hero")
				return
			end
		end

		-- all players selected a hero, remove pick screen to reduce lag
		--		print("All players selected a hero, remove pick screen")
		for k, v in pairs(HeroList:GetAllHeroes()) do
			if v and IsValidEntity(v) and not v:IsNull() and v.is_fake_hero then
				UTIL_Remove(v)
			end
		end
	end)
end
