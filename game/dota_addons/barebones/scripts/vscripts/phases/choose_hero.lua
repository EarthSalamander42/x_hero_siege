STARTING_GOLD = 2000
WeekHero = "npc_dota_hero_skeleton_king"
-- "npc_dota_hero_slardar"			-- Centurion
-- "npc_dota_hero_skeleton_king"	-- Lich King
-- "npc_dota_hero_meepo"			-- Kobold Knight
-- "npc_dota_hero_chaos_knight"		-- Dark Fundamental
-- "npc_dota_hero_tiny"				-- Stone Giant
-- "npc_dota_hero_sand_king"		-- Desert Wyrm
-- "npc_dota_hero_necrolyte"		-- Dark Summoner
-- "npc_dota_hero_storm_spirit"		-- Spirit Master

function SpawnHeroLoadout(hero_count)
local left_angle = {4, 5, 6, 7, 8, 14, 15, 16}
local top_angle = {11, 12, 13, 22, 23, 24, 28, 29, 30, 31, 32, 33}
local bot_angle = {9, 10, 25, 26, 27}

	local hero = CreateUnitByName("npc_dota_hero_"..HEROLIST[hero_count].."_bis", Entities:FindByName(nil, "choose_"..hero_count.."_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)

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

	Timers:CreateTimer(5.0, function()
		SpawnHeroLoadout(hero_count)
		if hero_count < #HEROLIST then
			hero_count = hero_count +1
			return 0.3
		else
			return nil
		end
	end)

	Timers:CreateTimer(10.0, function()
		if hero_vip_count == 4 then
			local dummy_hero = CreateUnitByName("npc_dota_hero_chaos_knight_bis", Entities:FindByName(nil, "choose_vip_4_point"):GetAbsOrigin() + Vector(-100, 0, 0), true, nil, nil, DOTA_TEAM_GOODGUYS)
			dummy_hero:SetAngles(0, 270, 0)
			local dummy_hero = CreateUnitByName("npc_dota_hero_keeper_of_the_light_bis", Entities:FindByName(nil, "choose_vip_4_point"):GetAbsOrigin() + Vector(100, 0, 0), true, nil, nil, DOTA_TEAM_GOODGUYS)
			dummy_hero:SetAngles(0, 270, 0)
		elseif hero_vip_count == 8 then
			local dummy_hero = CreateUnitByName("npc_dota_hero_storm_spirit_bis", Entities:FindByName(nil, "choose_vip_8_point"):GetAbsOrigin() + Vector(0, 100, 0), true, nil, nil, DOTA_TEAM_GOODGUYS)
			dummy_hero:SetAngles(0, 270, 0)
			local dummy_hero = CreateUnitByName("npc_dota_hero_ember_spirit_bis", Entities:FindByName(nil, "choose_vip_8_point"):GetAbsOrigin() + Vector(-100, 0, 0), true, nil, nil, DOTA_TEAM_GOODGUYS)
			dummy_hero:SetAngles(0, 270, 0)
			local dummy_hero = CreateUnitByName("npc_dota_hero_earth_spirit_bis", Entities:FindByName(nil, "choose_vip_8_point"):GetAbsOrigin() + Vector(100, 0, 0), true, nil, nil, DOTA_TEAM_GOODGUYS)
			dummy_hero:SetAngles(0, 270, 0)
		else
			local dummy_hero = CreateUnitByName("npc_dota_hero_"..HEROLIST_VIP[hero_vip_count].."_bis", Entities:FindByName(nil, "choose_vip_"..hero_vip_count.."_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
			dummy_hero:SetAngles(0, 270, 0)
		end
		if hero_vip_count < #HEROLIST_VIP then
			hero_vip_count = hero_vip_count +1
			return 0.3
		else
			return nil
		end
	end)

	local vip_point = Entities:FindByName(nil, "choose_vip_point"):GetAbsOrigin()
	if WeekHero == "npc_dota_hero_storm_spirit" then
		local vip_hero = CreateUnitByName("npc_dota_hero_storm_spirit_bis", vip_point + Vector(0, 100, 0), true, nil, nil, DOTA_TEAM_GOODGUYS)
		vip_hero:SetAngles(0, 270, 0)
		local vip_hero2 = CreateUnitByName("npc_dota_hero_ember_spirit_bis", vip_point + Vector(-100, 0, 0), true, nil, nil, DOTA_TEAM_GOODGUYS)
		vip_hero2:SetAngles(0, 270, 0)
		local vip_hero3 = CreateUnitByName("npc_dota_hero_earth_spirit_bis", vip_point + Vector(100, 0, 0), true, nil, nil, DOTA_TEAM_GOODGUYS)
		vip_hero3:SetAngles(0, 270, 0)
	else
		local vip_hero = CreateUnitByName(WeekHero.."_bis", vip_point, true, nil, nil, DOTA_TEAM_GOODGUYS)
		vip_hero:SetAngles(0, 270, 0)
	end

	RAMERO_DUMMY = CreateUnitByName("npc_ramero", Entities:FindByName(nil, "point_special_arena_1"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	RAMERO_DUMMY:SetAngles(0, 270, 0)
	RAMERO_DUMMY:AddNewModifier(nil, nil, "modifier_command_restricted", {})
	BARISTOL_DUMMY = CreateUnitByName("npc_baristol", Entities:FindByName(nil, "point_special_arena_2"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	BARISTOL_DUMMY:SetAngles(0, 270, 0)
	BARISTOL_DUMMY:AddNewModifier(nil, nil, "modifier_command_restricted", {})
	RAMERO_BIS_DUMMY = CreateUnitByName("npc_ramero", Entities:FindByName(nil, "point_special_arena_3"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	RAMERO_BIS_DUMMY:SetAngles(0, 270, 0)
	RAMERO_BIS_DUMMY:AddNewModifier(nil, nil, "modifier_command_restricted", {})

	-- Special Events
	lich_king = CreateUnitByName("npc_dota_boss_lich_king_bis", Entities:FindByName(nil, "npc_dota_spawner_lich_king"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
	lich_king:SetAngles(0, 90, 0)
	lich_king:AddNewModifier(nil, nil, "modifier_invulnerable", nil)
end

function ChooseHero(event)
local hero = event.activator
local caller = event.caller
local id = hero:GetPlayerID()
local difficulty = GameRules:GetCustomGameDifficulty()

	if PlayerResource:IsValidPlayer(id) and hero:GetUnitName() == "npc_dota_hero_wisp" then
		for i = 1, #HEROLIST do -- 12 = POTM, 19 = Paladin, 27 = Archimonde.
			if caller:GetName() == "trigger_hero_12" or caller:GetName() == "trigger_hero_19" or caller:GetName() == "trigger_hero_27" then
				Notifications:Bottom(hero:GetPlayerOwnerID(), {text = "This hero is disabled! Please choose a hero with a blue circle!", duration = 6.0})
				return
			end

			if caller:GetName() == "trigger_hero_"..i then
				UTIL_Remove(Entities:FindByName(nil, "trigger_hero_"..i))
				local particle = ParticleManager:CreateParticle("particles/econ/events/ti6/hero_levelup_ti6.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
				ParticleManager:SetParticleControl(particle, 0, hero:GetAbsOrigin())
				EmitSoundOnClient("ui.trophy_levelup", PlayerResource:GetPlayer(id))
				hero:AddNewModifier(hero, nil, "modifier_command_restricted", {})
				Notifications:Bottom(hero:GetPlayerOwnerID(), {hero="npc_dota_hero_"..HEROLIST[i], duration = 5.0})
				Notifications:Bottom(hero:GetPlayerOwnerID(), {text="HERO: ", duration = 5.0, style={color="white"}, continue=true})
				Notifications:Bottom(hero:GetPlayerOwnerID(), {text="#npc_dota_hero_"..HEROLIST[i], duration = 5.0, style={color="white"}, continue=true})
				
				local newHero = PlayerResource:ReplaceHeroWith(id, "npc_dota_hero_"..HEROLIST[i], STARTING_GOLD, 0)
				if difficulty < 4 then
					local item = newHero:AddItemByName("item_ankh_of_reincarnation")
				end
				local item = newHero:AddItemByName("item_health_potion")
				local item = newHero:AddItemByName("item_mana_potion")
				if difficulty == 1 then
					local item = newHero:AddItemByName("item_lifesteal_mask")
					item:SetSellable(false)
				end
				if newHero:GetTeamNumber() == 2 then
					TeleportHero(newHero, 3.0, base_good:GetAbsOrigin())
				elseif newHero:GetTeamNumber() == 3 then
					TeleportHero(newHero, 3.0, base_bad:GetAbsOrigin())
				end
				Timers:CreateTimer(0.1, function()
					if not hero:IsNull() then
						UTIL_Remove(hero)
					end
				end)
				return
			end

			if caller:GetName() == "trigger_hero_weekly" then
				if hero:HasAbility("holdout_vip") then
					Notifications:Bottom(hero:GetPlayerOwnerID(), {text="You are VIP. Please choose this hero on top!", duration = 5.0})
				return
				end
				UTIL_Remove(Entities:FindByName(nil, "trigger_hero_weekly"))
				local particle = ParticleManager:CreateParticle("particles/econ/events/ti6/hero_levelup_ti6.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
				ParticleManager:SetParticleControl(particle, 0, hero:GetAbsOrigin())
				EmitSoundOnClient("ui.trophy_levelup", PlayerResource:GetPlayer(id))
				hero:AddNewModifier(hero, nil, "modifier_command_restricted", {})
				Notifications:Bottom(hero:GetPlayerOwnerID(), {hero=WeekHero, duration = 5.0})
				Notifications:Bottom(hero:GetPlayerOwnerID(), {text="HERO: ", duration = 5.0, style={color="white"}, continue=true})
				Notifications:Bottom(hero:GetPlayerOwnerID(), {text="#"..WeekHero, duration = 5.0, style={color="white"}, continue=true})
				Timers:CreateTimer(3.1, function()
					local newHero = PlayerResource:ReplaceHeroWith(id, WeekHero, STARTING_GOLD, 0)
					if difficulty < 4 then
						local item = newHero:AddItemByName("item_ankh_of_reincarnation")
					end
					local item = newHero:AddItemByName("item_health_potion")
					local item = newHero:AddItemByName("item_mana_potion")
					if difficulty == 1 then
						local item = newHero:AddItemByName("item_lifesteal_mask")
						item:SetSellable(false)
					end
					if newHero:GetTeamNumber() == 2 then
						TeleportHero(newHero, 3.0, base_good:GetAbsOrigin())
					elseif newHero:GetTeamNumber() == 3 then
						TeleportHero(newHero, 3.0, base_bad:GetAbsOrigin())
					end
					Timers:CreateTimer(0.1, function()
						if not hero:IsNull() then
							UTIL_Remove(hero)
						end
					end)
				end)
				return
			end
		end
	end
end

function ChooseHeroVIP(event)
local hero = event.activator
local caller = event.caller
local id = hero:GetPlayerID()
local difficulty = GameRules:GetCustomGameDifficulty()

	if PlayerResource:IsValidPlayer(id) and hero:GetUnitName() == "npc_dota_hero_wisp" and hero:HasAbility("holdout_vip") then
		for i = 1, #HEROLIST_VIP do
			if caller:GetName() == "trigger_hero_vip_"..i then
				UTIL_Remove(Entities:FindByName(nil, "trigger_hero_vip_"..i))
				local particle = ParticleManager:CreateParticle("particles/econ/events/ti6/hero_levelup_ti6.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
				ParticleManager:SetParticleControl(particle, 0, hero:GetAbsOrigin())
				EmitSoundOnClient("ui.trophy_levelup", PlayerResource:GetPlayer(id))
				hero:AddNewModifier(hero, nil, "modifier_command_restricted", {})
--				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), hero)
				Notifications:Bottom(hero:GetPlayerOwnerID(), {hero="npc_dota_hero_"..HEROLIST_VIP[i], duration = 5.0})
				Notifications:Bottom(hero:GetPlayerOwnerID(), {text="HERO: ", duration = 5.0, style={color="white"}, continue=true})
				Notifications:Bottom(hero:GetPlayerOwnerID(), {text="#npc_dota_hero_"..HEROLIST_VIP[i], duration = 5.0, style={color="white"}, continue=true})
				
				local newHero = PlayerResource:ReplaceHeroWith(id, "npc_dota_hero_"..HEROLIST_VIP[i], STARTING_GOLD, 0)
				if difficulty < 4 then
					local item = newHero:AddItemByName("item_ankh_of_reincarnation")
				end
				local item = newHero:AddItemByName("item_health_potion")
				local item = newHero:AddItemByName("item_mana_potion")
				if difficulty == 1 then
					local item = newHero:AddItemByName("item_lifesteal_mask")
					item:SetSellable(false)
				end
				if newHero:GetTeamNumber() == 2 then
					TeleportHero(newHero, 3.0, base_good:GetAbsOrigin())
				elseif newHero:GetTeamNumber() == 3 then
					TeleportHero(newHero, 3.0, base_bad:GetAbsOrigin())
				end

				PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), nil)
				Timers:CreateTimer(0.1, function()
					if not hero:IsNull() then
						UTIL_Remove(hero)
					end
				end)
			end
		end
	elseif PlayerResource:IsValidPlayer(id) and hero:GetUnitName() == "npc_dota_hero_wisp" and not hero:HasAbility("holdout_vip") then
		Notifications:Bottom(hero:GetPlayerOwnerID(), {text = "This hero is only for <font color='#FF0000'>VIP Members!</font> Please choose another hero.", duration = 5.0})
	end
end
