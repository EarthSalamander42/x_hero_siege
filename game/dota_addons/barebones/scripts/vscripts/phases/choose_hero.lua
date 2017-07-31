require('libraries/timers')

STARTING_GOLD = 2000
WeekHero = "npc_dota_hero_tiny"
-- "npc_dota_hero_slardar"			-- Centurion
-- "npc_dota_hero_skeleton_king"	-- Lich King
-- "npc_dota_hero_meepo"			-- Kobold Knight
-- "npc_dota_hero_chaos_knight"		-- Dark Fundamental
-- "npc_dota_hero_tiny"				-- Stone Giant
-- "npc_dota_hero_sand_king"		-- Desert Wyrm
-- "npc_dota_hero_necrolyte"		-- Dark Summoner
-- "npc_dota_hero_storm_spirit"		-- Spirit Master

function SpawnHeroesBis()
	for dummy = 1, #HEROLIST do
		local point = Entities:FindByName(nil, "choose_"..HEROLIST[dummy].."_point"):GetAbsOrigin()
		local dummy_hero = CreateUnitByName("npc_dota_hero_"..HEROLIST[dummy].."_bis", point, true, nil, nil, DOTA_TEAM_GOODGUYS)
		dummy_hero:SetAngles(0, 270, 0)
		dummy_hero:AddAbility("dummy_passive_vulnerable")
		dummy_hero:FindAbilityByName("dummy_passive_vulnerable"):SetLevel(1)
	end

	for dummy = 1, #HEROLIST_VIP do
		if dummy == 2 then
			local dummy_hero = CreateUnitByName("npc_dota_hero_skeleton_king_bis", Entities:FindByName(nil, "choose_skeleton_king_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
			dummy_hero:SetAngles(0, 270, 0)
			StartAnimation(dummy_hero, {duration = 20000.0, activity = ACT_DOTA_IDLE, rate = 0.9})
		elseif dummy == 4 then
			local dummy_hero = CreateUnitByName("npc_dota_hero_chaos_knight_bis", Entities:FindByName(nil, "choose_chaos_knight_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
			dummy_hero:SetAngles(0, 270, 0)
			local dummy_hero = CreateUnitByName("npc_dota_hero_keeper_of_the_light_bis", Entities:FindByName(nil, "choose_keeper_of_the_light_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
			dummy_hero:SetAngles(0, 270, 0)
		elseif dummy == 8 then
			local dummy_hero = CreateUnitByName("npc_dota_hero_storm_spirit_bis", Entities:FindByName(nil, "choose_storm_spirit_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
			dummy_hero:SetAngles(0, 270, 0)
			local dummy_hero = CreateUnitByName("npc_dota_hero_ember_spirit_bis", Entities:FindByName(nil, "choose_ember_spirit_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
			dummy_hero:SetAngles(0, 270, 0)
			local dummy_hero = CreateUnitByName("npc_dota_hero_earth_spirit_bis", Entities:FindByName(nil, "choose_earth_spirit_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
			dummy_hero:SetAngles(0, 270, 0)
		else
			local point = Entities:FindByName(nil, "choose_"..HEROLIST_VIP[dummy].."_point"):GetAbsOrigin()
			local dummy_hero = CreateUnitByName("npc_dota_hero_"..HEROLIST_VIP[dummy].."_bis", point, true, nil, nil, DOTA_TEAM_GOODGUYS)
			dummy_hero:SetAngles(0, 270, 0)
		end
	end

	local vip_point = Entities:FindByName(nil, "choose_vip_point"):GetAbsOrigin()
	local vip_hero = CreateUnitByName(WeekHero.."_bis", vip_point, true, nil, nil, DOTA_TEAM_GOODGUYS)
	vip_hero:SetAngles(0, 270, 0)
	vip_hero:AddAbility("dummy_passive_vulnerable")
	vip_hero:FindAbilityByName("dummy_passive_vulnerable"):SetLevel(1)

	RAMERO_DUMMY = CreateUnitByName("npc_ramero", Entities:FindByName(nil, "point_special_arena_1"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	RAMERO_DUMMY:SetAngles(0, 270, 0)
	RAMERO_DUMMY:AddNewModifier(nil, nil, "modifier_invulnerable", {})
	BARISTOL_DUMMY = CreateUnitByName("npc_baristol", Entities:FindByName(nil, "point_special_arena_2"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	BARISTOL_DUMMY:SetAngles(0, 270, 0)
	BARISTOL_DUMMY:AddNewModifier(nil, nil, "modifier_invulnerable", {})
	RAMERO_BIS_DUMMY = CreateUnitByName("npc_ramero", Entities:FindByName(nil, "point_special_arena_3"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
	RAMERO_BIS_DUMMY:SetAngles(0, 270, 0)
	RAMERO_BIS_DUMMY:AddNewModifier(nil, nil, "modifier_invulnerable", {})

	-- Special Events
	lich_king = CreateUnitByName("npc_dota_boss_lich_king_bis", Entities:FindByName(nil, "npc_dota_spawner_lich_king"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_CUSTOM_1)
	lich_king:SetAngles(0, 90, 0)
	lich_king:AddNewModifier(nil, nil, "modifier_invulnerable", nil)
	StartAnimation(lich_king, {duration = 20000.0, activity = ACT_DOTA_IDLE, rate = 0.9})

--	local i, j = string.find( HEROLIST[dummy], "" )
--	print(HEROLIST_VIP[dummy])
--	print(dummy)
end

function ChooseHero(event)
local hero = event.activator
local caller = event.caller
local id = hero:GetPlayerID()
local point = Entities:FindByName(nil, "base_spawn")
local difficulty = GameRules:GetCustomGameDifficulty()

	if PlayerResource:IsValidPlayer(id) and hero:GetUnitName() == "npc_dota_hero_wisp" then
		for i = 1, #HEROLIST do
			if caller:GetName() == "trigger_hero_"..i then
				UTIL_Remove(Entities:FindByName(nil, "trigger_hero_"..i))
				local particle = ParticleManager:CreateParticle("particles/econ/events/ti6/hero_levelup_ti6.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
				ParticleManager:SetParticleControl(particle, 0, hero:GetAbsOrigin())
				EmitSoundOnClient("ui.trophy_levelup", PlayerResource:GetPlayer(id))
				hero:AddNewModifier(hero, nil, "modifier_command_restricted", {})
				Notifications:Bottom(hero:GetPlayerOwnerID(), {hero="npc_dota_hero_"..HEROLIST[i], duration = 5.0})
				Notifications:Bottom(hero:GetPlayerOwnerID(), {text="HERO: ", duration = 5.0, style={color="white"}, continue=true})
				Notifications:Bottom(hero:GetPlayerOwnerID(), {text="#npc_dota_hero_"..HEROLIST[i], duration = 5.0, style={color="white"}, continue=true})
				Timers:CreateTimer(3.1, function()
					PrecacheUnitByNameAsync("npc_dota_hero_"..HEROLIST[i], function()
						local newHero = PlayerResource:ReplaceHeroWith(id, "npc_dota_hero_"..HEROLIST[i], STARTING_GOLD, 0)
						newHero:RespawnHero(false, false, false)
						if difficulty < 4 then
							local item = newHero:AddItemByName("item_ankh_of_reincarnation")
						end
						local item = newHero:AddItemByName("item_healing_potion")
						local item = newHero:AddItemByName("item_mana_potion")
						if difficulty == 1 then
							local item = newHero:AddItemByName("item_lifesteal_mask")
						end
						Timers:CreateTimer(0.1, function()
							if not hero:IsNull() then
								UTIL_Remove(hero)
							end
						end)
					end, id)
				end)
			elseif caller:GetName() == "trigger_hero_weekly" then
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
					PrecacheUnitByNameAsync(WeekHero, function()
						local newHero = PlayerResource:ReplaceHeroWith(id, WeekHero, STARTING_GOLD, 0)
						newHero:RespawnHero(false, false, false)
						if difficulty < 4 then
							local item = newHero:AddItemByName("item_ankh_of_reincarnation")
						end
						local item = newHero:AddItemByName("item_healing_potion")
						local item = newHero:AddItemByName("item_mana_potion")
						if difficulty == 1 then
							local item = newHero:AddItemByName("item_lifesteal_mask")
						end
						Timers:CreateTimer(0.1, function()
							if not hero:IsNull() then
								UTIL_Remove(hero)
							end
						end)
					end, id)
				end)
			end
		end
	end
end

function ChooseHeroVIP(event)
local hero = event.activator
local caller = event.caller
local id = hero:GetPlayerID()
local point = Entities:FindByName(nil, "base_spawn")
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
				Timers:CreateTimer(3.1, function()
					PrecacheUnitByNameAsync("npc_dota_hero_"..HEROLIST[i], function()
						local newHero = PlayerResource:ReplaceHeroWith(id, "npc_dota_hero_"..HEROLIST_VIP[i], STARTING_GOLD, 0)
						newHero:RespawnHero(false, false, false)
						if difficulty < 4 then
							local item = newHero:AddItemByName("item_ankh_of_reincarnation")
						end
						local item = newHero:AddItemByName("item_healing_potion")
						local item = newHero:AddItemByName("item_mana_potion")
						if difficulty == 1 then
							local item = newHero:AddItemByName("item_lifesteal_mask")
						end
						if newHero:GetUnitName() == "npc_dota_hero_skeleton_king" then
							SkeletonKingWearables(newHero)
						end
						PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), nil)
						Timers:CreateTimer(0.1, function()
							if not hero:IsNull() then
								UTIL_Remove(hero)
							end
						end)
					end, id)
				end)
			end
		end
	elseif PlayerResource:IsValidPlayer(id) and hero:GetUnitName() == "npc_dota_hero_wisp" and not hero:HasAbility("holdout_vip") then
		Notifications:Bottom(hero:GetPlayerOwnerID(), {text = "This hero is only for <font color='#FF0000'>VIP Members!</font> Please choose another hero.", duration = 5.0})
	end
end

function DisabledHero(event)
local hero = event.activator
local msg = "This hero is disabled! Please choose a hero with a blue circle!"
	Notifications:Bottom(hero:GetPlayerOwnerID(), {text = msg, duration = 6.0})
end
