require('libraries/timers')

STARTING_GOLD = 1000

function SpawnHeroesBis()
local heroes = HeroList:GetAllHeroes()
	Timers:CreateTimer(8, function()
		-- Inner West
		HEROLIST_ALT[1] = CreateUnitByName("npc_dota_hero_enchantress_bis", Entities:FindByName(nil, "choose_enchantress_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_ALT[1]:SetAngles(0, 0, 0)

		HEROLIST_ALT[2] = CreateUnitByName("npc_dota_hero_crystal_maiden_bis", Entities:FindByName(nil, "choose_crystal_maiden_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_ALT[2]:SetAngles(0, 0, 0)

		HEROLIST_ALT[3] = CreateUnitByName("npc_dota_hero_luna_bis", Entities:FindByName(nil, "choose_luna_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_ALT[3]:SetAngles(0, 0, 0)

		-- Outer West
		HEROLIST_ALT[4] = CreateUnitByName("npc_dota_hero_beastmaster_bis", Entities:FindByName(nil, "choose_beastmaster_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_ALT[4]:SetAngles(0, 180, 0)

		HEROLIST_ALT[5] = CreateUnitByName("npc_dota_hero_pugna_bis", Entities:FindByName(nil, "choose_pugna_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_ALT[5]:SetAngles(0, 180, 0)

		HEROLIST_ALT[6] = CreateUnitByName("npc_dota_hero_lich_bis", Entities:FindByName(nil, "choose_lich_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_ALT[6]:SetAngles(0, 180, 0)

		HEROLIST_ALT[7] = CreateUnitByName("npc_dota_hero_nyx_assassin_bis", Entities:FindByName(nil, "choose_nyx_assassin_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_ALT[7]:SetAngles(0, 180, 0)

		HEROLIST_ALT[8] = CreateUnitByName("npc_dota_hero_abyssal_underlord_bis", Entities:FindByName(nil, "choose_abyssal_underlord_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_ALT[8]:SetAngles(0, 180, 0)
	end)

	Timers:CreateTimer(12, function()
		-- Inner North
		HEROLIST_ALT[9] = CreateUnitByName("npc_dota_hero_terrorblade_bis", Entities:FindByName(nil, "choose_terrorblade_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_ALT[9]:SetAngles(0, 270, 0)

		HEROLIST_ALT[10] = CreateUnitByName("npc_dota_hero_phantom_assassin_bis", Entities:FindByName(nil, "choose_phantom_assassin_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_ALT[10]:SetAngles(0, 270, 0)

		-- Outer North
		HEROLIST_ALT[11] = CreateUnitByName("npc_dota_hero_elder_titan_bis", Entities:FindByName(nil, "choose_elder_titan_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_ALT[11]:SetAngles(0, 90, 0)

		HEROLIST_ALT[12] = CreateUnitByName("npc_dota_hero_mirana_bis", Entities:FindByName(nil, "choose_mirana_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_ALT[12]:SetAngles(0, 90, 0)

		HEROLIST_ALT[13] = CreateUnitByName("npc_dota_hero_dragon_knight_bis", Entities:FindByName(nil, "choose_dragon_knight_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_ALT[13]:SetAngles(0, 90, 0)

		WEEKLY_HERO = CreateUnitByName("npc_dota_hero_slardar_bis", Entities:FindByName(nil, "choose_vip_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		WEEKLY_HERO:SetAngles(0, 270, 0)
	end)

	Timers:CreateTimer(16, function()
		-- Inner East
		HEROLIST_ALT[14] = CreateUnitByName("npc_dota_hero_windrunner_bis", Entities:FindByName(nil, "choose_windrunner_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_ALT[14]:SetAngles(0, 180, 0)

		HEROLIST_ALT[15] = CreateUnitByName("npc_dota_hero_invoker_bis", Entities:FindByName(nil, "choose_invoker_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_ALT[15]:SetAngles(0, 180, 0)

		HEROLIST_ALT[16] = CreateUnitByName("npc_dota_hero_sniper_bis", Entities:FindByName(nil, "choose_sniper_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_ALT[16]:SetAngles(0, 180, 0)

		-- Outer East
		HEROLIST_ALT[17] = CreateUnitByName("npc_dota_hero_shadow_shaman_bis", Entities:FindByName(nil, "choose_shadow_shaman_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_ALT[17]:SetAngles(0, 0, 0)

		HEROLIST_ALT[18] = CreateUnitByName("npc_dota_hero_juggernaut_bis", Entities:FindByName(nil, "choose_juggernaut_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_ALT[18]:SetAngles(0, 0, 0)

		HEROLIST_ALT[19] = CreateUnitByName("npc_dota_hero_omniknight_bis", Entities:FindByName(nil, "choose_omniknight_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_ALT[19]:SetAngles(0, 0, 0)

		HEROLIST_ALT[20] = CreateUnitByName("npc_dota_hero_rattletrap_bis", Entities:FindByName(nil, "choose_rattletrap_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_ALT[20]:SetAngles(0, 0, 0)

		HEROLIST_ALT[21] = CreateUnitByName("npc_dota_hero_chen_bis", Entities:FindByName(nil, "choose_chen_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_ALT[21]:SetAngles(0, 0, 0)
	end)

	Timers:CreateTimer(20, function()
		-- Inner South
		HEROLIST_ALT[22] = CreateUnitByName("npc_dota_hero_lina_bis", Entities:FindByName(nil, "choose_lina_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_ALT[22]:SetAngles(0, 90, 0)

		HEROLIST_ALT[23] = CreateUnitByName("npc_dota_hero_sven_bis", Entities:FindByName(nil, "choose_sven_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_ALT[23]:SetAngles(0, 90, 0)

		-- Outer South
		HEROLIST_ALT[24] = CreateUnitByName("npc_dota_hero_furion_bis", Entities:FindByName(nil, "choose_furion_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_ALT[24]:SetAngles(0, 90, 0)

		HEROLIST_ALT[25] = CreateUnitByName("npc_dota_hero_nevermore_bis", Entities:FindByName(nil, "choose_nevermore_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_ALT[25]:SetAngles(0, 270, 0)

		HEROLIST_ALT[26] = CreateUnitByName("npc_dota_hero_brewmaster_bis", Entities:FindByName(nil, "choose_brewmaster_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_ALT[26]:SetAngles(0, 270, 0)

		HEROLIST_ALT[27] = CreateUnitByName("npc_dota_hero_warlock_bis", Entities:FindByName(nil, "choose_warlock_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_ALT[27]:SetAngles(0, 270, 0)
	end)

	Timers:CreateTimer(24, function()
		-- VIP Hero
		HEROLIST_VIP_ALT[4] = CreateUnitByName("npc_dota_hero_chaos_knight_bis", Entities:FindByName(nil, "choose_chaos_knight_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_VIP_ALT[4]:SetAngles(0, 270, 0)
		HEROLIST_VIP_ALT[4] = CreateUnitByName("npc_dota_hero_keeper_of_the_light_bis", Entities:FindByName(nil, "choose_keeper_of_the_light_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_VIP_ALT[4]:SetAngles(0, 270, 0)

		HEROLIST_VIP_ALT[3] = CreateUnitByName("npc_dota_hero_meepo_bis", Entities:FindByName(nil, "choose_meepo_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_VIP_ALT[3]:SetAngles(0, 270, 0)

		HEROLIST_VIP_ALT[1] = CreateUnitByName("npc_dota_hero_slardar_bis", Entities:FindByName(nil, "choose_slardar_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_VIP_ALT[1]:SetAngles(0, 270, 0)

		HEROLIST_VIP_ALT[2] = CreateUnitByName("npc_dota_hero_skeleton_king_bis", Entities:FindByName(nil, "choose_skeleton_king_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_VIP_ALT[2]:SetAngles(0, 270, 0)
		StartAnimation(HEROLIST_VIP_ALT[2], {duration = 20000.0, activity = ACT_DOTA_IDLE, rate = 0.9})

		HEROLIST_VIP_ALT[5] = CreateUnitByName("npc_dota_hero_tiny_bis", Entities:FindByName(nil, "choose_tiny_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_VIP_ALT[5]:SetAngles(0, 270, 0)

		HEROLIST_VIP_ALT[6] = CreateUnitByName("npc_dota_hero_sand_king_bis", Entities:FindByName(nil, "choose_sand_king_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_VIP_ALT[6]:SetAngles(0, 270, 0)

		HEROLIST_VIP_ALT[7] = CreateUnitByName("npc_dota_hero_necrolyte_bis", Entities:FindByName(nil, "choose_pudge_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_VIP_ALT[7]:SetAngles(0, 270, 0)

		HEROLIST_VIP_ALT[8] = CreateUnitByName("npc_dota_hero_storm_spirit_bis", Entities:FindByName(nil, "choose_storm_spirit_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_VIP_ALT[8]:SetAngles(0, 270, 0)
		HEROLIST_VIP_ALT[8] = CreateUnitByName("npc_dota_hero_ember_spirit_bis", Entities:FindByName(nil, "choose_ember_spirit_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_VIP_ALT[8]:SetAngles(0, 270, 0)
		HEROLIST_VIP_ALT[8] = CreateUnitByName("npc_dota_hero_earth_spirit_bis", Entities:FindByName(nil, "choose_earth_spirit_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_VIP_ALT[8]:SetAngles(0, 270, 0)
	end)

	Timers:CreateTimer(28, function()
		-- Special Events
		RAMERO_DUMMY = CreateUnitByName("npc_ramero_bis", Entities:FindByName(nil, "point_special_arena_1"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		RAMERO_DUMMY:SetAngles(0, 270, 0)

		BARISTOL_DUMMY = CreateUnitByName("npc_baristol_bis", Entities:FindByName(nil, "point_special_arena_2"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		BARISTOL_DUMMY:SetAngles(0, 270, 0)

		RAMERO_BIS_DUMMY = CreateUnitByName("npc_ramero_bis", Entities:FindByName(nil, "point_special_arena_3"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		RAMERO_BIS_DUMMY:SetAngles(0, 270, 0)

		lich_king = CreateUnitByName("npc_dota_boss_lich_king_bis", Entities:FindByName(nil, "npc_dota_spawner_lich_king"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
		lich_king:SetAngles(0, 90, 0)
		lich_king:AddNewModifier(nil, nil, "modifier_invulnerable", nil)
		StartAnimation(lich_king, {duration = 20000.0, activity = ACT_DOTA_IDLE, rate = 0.9})
	end)

	Timers:CreateTimer(32, function()
		-- Special Events
--		local iron_man = CreateUnitByName("npc_dota_hero_tinker_bis", Entities:FindByName(nil, "choose_tinker_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
--		iron_man:SetAngles(0, 180, 0)

		HEROLIST_ALT[28] = CreateUnitByName("npc_dota_hero_axe_bis", Entities:FindByName(nil, "choose_dota_point_1"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_ALT[28]:SetAngles(0, 180, 0)

		HEROLIST_ALT[29] = CreateUnitByName("npc_dota_hero_monkey_king_bis", Entities:FindByName(nil, "choose_dota_point_2"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_ALT[29]:SetAngles(0, 180, 0)

		HEROLIST_ALT[30] = CreateUnitByName("npc_dota_hero_troll_warlord_bis", Entities:FindByName(nil, "choose_dota_point_3"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_ALT[30]:SetAngles(0, 180, 0)

		HEROLIST_ALT[31] = CreateUnitByName("npc_dota_hero_doom_bringer_bis", Entities:FindByName(nil, "choose_dota_point_4"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_ALT[31]:SetAngles(0, 180, 0)

		HEROLIST_ALT[32] = CreateUnitByName("npc_dota_hero_bristleback_bis", Entities:FindByName(nil, "choose_dota_point_5"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_ALT[32]:SetAngles(0, 180, 0)

		HEROLIST_ALT[33] = CreateUnitByName("npc_dota_hero_leshrac_bis", Entities:FindByName(nil, "choose_dota_point_6"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_ALT[33]:SetAngles(0, 180, 0)
	end)
end

function ChooseHero(event)
local hero = event.activator
local caller = event.caller
local id = hero:GetPlayerID()
local point = Entities:FindByName(nil, "base_spawn")
local difficulty = GameRules:GetCustomGameDifficulty()

	for playerID = 0, DOTA_MAX_TEAM_PLAYERS -1 do
		if PlayerResource:IsValidPlayer(playerID) and hero:GetUnitName() == "npc_dota_hero_wisp" and DUAL_HERO == 1 then
			for i = 1, #HEROLIST do
				if caller:GetName() == "trigger_hero_"..i then
					local particle = ParticleManager:CreateParticle("particles/econ/events/ti6/hero_levelup_ti6.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
					ParticleManager:SetParticleControl(particle, 0, hero:GetAbsOrigin())
					EmitSoundOnClient("ui.trophy_levelup", PlayerResource:GetPlayer(playerID))
					hero:AddNewModifier(nil, nil, "modifier_boss_stun", {Duration = 3.0, IsHidden = true})
					PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), hero)
					Notifications:Bottom(hero:GetPlayerOwnerID(), {hero="npc_dota_hero_"..HEROLIST[i], duration = 5.0})
					Notifications:Bottom(hero:GetPlayerOwnerID(), {text="HERO: ", duration = 5.0, style={color="white"}, continue=true})
					Notifications:Bottom(hero:GetPlayerOwnerID(), {text="#npc_dota_hero_"..HEROLIST[i], duration = 5.0, style={color="white"}, continue=true})
					Timers:CreateTimer(3.0, function()
						UTIL_Remove(Entities:FindByName(nil, "trigger_hero_"..i))
						UTIL_Remove(HEROLIST_ALT[i])
						FindClearSpaceForUnit(hero, point:GetAbsOrigin(), true)
						local newHero = PlayerResource:ReplaceHeroWith(hero:GetPlayerID(), "npc_dota_hero_"..HEROLIST[i], STARTING_GOLD, 0)
						PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), nil)
						if difficulty < 4 then
							local item = newHero:AddItemByName("item_ankh_of_reincarnation")
						end
						local item = newHero:AddItemByName("item_healing_potion")
						local item = newHero:AddItemByName("item_mana_potion")
						if difficulty == 1 then
							local item = newHero:AddItemByName("item_lifesteal_mask")
						end
						Timers:CreateTimer(4.0, function()
							if not hero:IsNull() then
								UTIL_Remove(hero)
							end
						end)
					end)
				end
			end
			if caller:GetName() == "trigger_hero_weekly" then
				if not hero:HasAbility("holdout_vip") then
					local particle = ParticleManager:CreateParticle("particles/econ/events/ti6/hero_levelup_ti6.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
					ParticleManager:SetParticleControl(particle, 0, hero:GetAbsOrigin())
					EmitSoundOnClient("ui.trophy_levelup", PlayerResource:GetPlayer(playerID))
					hero:AddNewModifier(nil, nil, "modifier_boss_stun", {Duration = 3.0, IsHidden = true})
					PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), hero)
					Notifications:Bottom(hero:GetPlayerOwnerID(), {hero="npc_dota_hero_slardar", duration = 5.0})
					Notifications:Bottom(hero:GetPlayerOwnerID(), {text="HERO: ", duration = 5.0, style={color="white"}, continue=true})
					Notifications:Bottom(hero:GetPlayerOwnerID(), {text="#npc_dota_hero_slardar", duration = 5.0, style={color="white"}, continue=true})
					Timers:CreateTimer(3.0, function()
						UTIL_Remove(Entities:FindByName(nil, "trigger_hero_weekly"))
						UTIL_Remove(WEEKLY_HERO)
						FindClearSpaceForUnit(hero, point:GetAbsOrigin(), true)
						local newHero = PlayerResource:ReplaceHeroWith(hero:GetPlayerID(), "npc_dota_hero_slardar", STARTING_GOLD, 0)
						PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), nil)
						local particle = ParticleManager:CreateParticle("particles/econ/events/ti6/hero_levelup_ti6.vpcf", PATTACH_ABSORIGIN_FOLLOW, newHero)
						ParticleManager:SetParticleControl(particle, 0, newHero:GetAbsOrigin())
						if difficulty < 4 then
							local item = newHero:AddItemByName("item_ankh_of_reincarnation")
						end
						local item = newHero:AddItemByName("item_healing_potion")
						local item = newHero:AddItemByName("item_mana_potion")
						if difficulty == 1 then
							local item = newHero:AddItemByName("item_lifesteal_mask")
						end
						Timers:CreateTimer(4.0, function()
							if not hero:IsNull() then
								UTIL_Remove(hero)
							end
						end)
					end)
				elseif hero:HasAbility("holdout_vip") then
					Notifications:Bottom(hero:GetPlayerOwnerID(),{text = "You are VIP. Please select this hero on top!", duration = 5.0})
				end
			end
		elseif PlayerResource:IsValidPlayer(playerID) and hero:GetUnitName() == "npc_dota_hero_wisp" and DUAL_HERO == 2 then
			for i = 1, #HEROLIST do
				if caller:GetName() == "trigger_hero_"..i and hero.dual_choose == 0 then
					local particle = ParticleManager:CreateParticle("particles/econ/events/ti6/hero_levelup_ti6.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
					ParticleManager:SetParticleControl(particle, 0, hero:GetAbsOrigin())
					EmitSoundOnClient("ui.trophy_levelup", PlayerResource:GetPlayer(playerID))
					UTIL_Remove(Entities:FindByName(nil, "trigger_hero_"..i))
					UTIL_Remove(HEROLIST_ALT[i])
					Notifications:Bottom(hero:GetPlayerOwnerID(), {hero="npc_dota_hero_"..HEROLIST[i], duration = 5.0})
					Notifications:Bottom(hero:GetPlayerOwnerID(), {text="HERO: ", duration = 5.0, style={color="white"}, continue=true})
					Notifications:Bottom(hero:GetPlayerOwnerID(), {text="#npc_dota_hero_"..HEROLIST[i], duration = 5.0, style={color="white"}, continue=true})
					Notifications:Bottom(hero:GetPlayerOwnerID(), {text="DUAL MODE: Please choose a second hero!", duration = 5.0, style={color="white"}})
					DUAL_HERO_1[id] = "npc_dota_hero_"..HEROLIST[i]
					hero.dual_choose = 1
				end
				if caller:GetName() == "trigger_hero_"..i and hero.dual_choose == 1 then
					CustomGameEventManager:Send_ServerToPlayer(hero:GetPlayerOwner(), "show_dual", {})
					DUAL_HERO_2[id] = "npc_dota_hero_"..HEROLIST[i]
					local particle = ParticleManager:CreateParticle("particles/econ/events/ti6/hero_levelup_ti6.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
					ParticleManager:SetParticleControl(particle, 0, hero:GetAbsOrigin())
					EmitSoundOnClient("ui.trophy_levelup", PlayerResource:GetPlayer(playerID))
					hero:AddNewModifier(nil, nil, "modifier_boss_stun", {Duration = 3.0, IsHidden = true})
					PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), hero)
					Notifications:Bottom(hero:GetPlayerOwnerID(), {hero="npc_dota_hero_"..HEROLIST[i], duration = 5.0})
					Notifications:Bottom(hero:GetPlayerOwnerID(), {text="HERO: ", duration = 5.0, style={color="white"}, continue=true})
					Notifications:Bottom(hero:GetPlayerOwnerID(), {text="#npc_dota_hero_"..HEROLIST[i], duration = 5.0, style={color="white"}, continue=true})
					Timers:CreateTimer(3.0, function()
						UTIL_Remove(Entities:FindByName(nil, "trigger_hero_"..i))
						UTIL_Remove(HEROLIST_ALT[i])
						FindClearSpaceForUnit(hero, point:GetAbsOrigin(), true)
						local newHero = PlayerResource:ReplaceHeroWith(hero:GetPlayerID(), "npc_dota_hero_"..HEROLIST[i], STARTING_GOLD, 0)
						PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), nil)
						if difficulty < 4 then
							local item = newHero:AddItemByName("item_ankh_of_reincarnation")
						end
						local item = newHero:AddItemByName("item_healing_potion")
						local item = newHero:AddItemByName("item_mana_potion")
						if difficulty == 1 then
							local item = newHero:AddItemByName("item_lifesteal_mask")
						end
						Timers:CreateTimer(4.0, function()
							if not hero:IsNull() then
								UTIL_Remove(hero)
							end
						end)
					end)
				end
			end
		end
	end
end

function ChooseHeroVIP(event)
local activator = event.activator
local caller = event.caller
local id = activator:GetPlayerID()
local point = Entities:FindByName(nil, "base_spawn")
local difficulty = GameRules:GetCustomGameDifficulty()

	for playerID = 0, DOTA_MAX_TEAM_PLAYERS -1 do
		if PlayerResource:IsValidPlayer(playerID) then
			if activator:GetUnitName() == "npc_dota_hero_wisp" then
				if activator:HasAbility("holdout_vip") then
					if DUAL_HERO == 1 then
						for i = 1, #HEROLIST_VIP do
							if caller:GetName() == "trigger_hero_vip_"..i then
								local particle = ParticleManager:CreateParticle("particles/econ/events/ti6/hero_levelup_ti6.vpcf", PATTACH_ABSORIGIN_FOLLOW, activator)
								ParticleManager:SetParticleControl(particle, 0, activator:GetAbsOrigin())
								EmitSoundOnClient("ui.trophy_levelup", PlayerResource:GetPlayer(playerID))
								activator:AddNewModifier(nil, nil, "modifier_boss_stun", {Duration = 3.0, IsHidden = true})
								PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(), activator)
								Notifications:Bottom(activator:GetPlayerOwnerID(), {hero="npc_dota_hero_"..HEROLIST_VIP[i], duration = 5.0})
								Notifications:Bottom(activator:GetPlayerOwnerID(), {text="HERO: ", duration = 5.0, style={color="white"}, continue=true})
								Notifications:Bottom(activator:GetPlayerOwnerID(), {text="#npc_dota_hero_"..HEROLIST_VIP[i], duration = 5.0, style={color="white"}, continue=true})
								Timers:CreateTimer(3.0, function()
									FindClearSpaceForUnit(activator, point:GetAbsOrigin(), true)
									PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(), nil)
									local newHero = PlayerResource:ReplaceHeroWith(activator:GetPlayerID(), "npc_dota_hero_"..HEROLIST_VIP[i], STARTING_GOLD, 0)
									local particle = ParticleManager:CreateParticle("particles/econ/events/ti6/hero_levelup_ti6.vpcf", PATTACH_ABSORIGIN_FOLLOW, newHero)
									ParticleManager:SetParticleControl(particle, 0, newHero:GetAbsOrigin())
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
									Timers:CreateTimer(4.0, function()
										if not activator:IsNull() then
											UTIL_Remove(activator)
										end
									end)
								end)
							end
						end
					elseif DUAL_HERO == 2 then
						Notifications:Bottom(activator:GetPlayerOwnerID(), {text = "VIP Heroes are disabled in Dual Hero Mode.", duration = 5.0})
					end
				elseif not activator:HasAbility("holdout_vip") then
					Notifications:Bottom(activator:GetPlayerOwnerID(), {text = "This hero is only for <font color='#FF0000'>VIP Members!</font> Please choose another hero.", duration = 5.0})
				end
			end
		end
	end
end

function DisabledHero(event)
local hero = event.activator
local msg = "This hero is disabled! Please choose a hero with a blue circle!"
	Notifications:Bottom(hero:GetPlayerOwnerID(), {text = msg, duration = 6.0})
end
