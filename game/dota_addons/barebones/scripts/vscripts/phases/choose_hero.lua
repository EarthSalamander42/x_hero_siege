require('libraries/timers')

STARTING_GOLD = 1000

function SpawnHeroesBis()
local heroes = HeroList:GetAllHeroes()
	Timers:CreateTimer(5, function()
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

		HEROLIST_ALT[7] = CreateUnitByName("npc_dota_hero_weaver_bis", Entities:FindByName(nil, "choose_weaver_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_ALT[7]:SetAngles(0, 180, 0)

		HEROLIST_ALT[8] = CreateUnitByName("npc_dota_hero_abyssal_underlord_bis", Entities:FindByName(nil, "choose_abyssal_underlord_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_ALT[8]:SetAngles(0, 180, 0)
	end)

	Timers:CreateTimer(8, function()
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
	end)

	Timers:CreateTimer(11, function()
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

	Timers:CreateTimer(14, function()
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

		HEROLIST_ALT[28] = CreateUnitByName("npc_dota_hero_axe_bis", Entities:FindByName(nil, "choose_dota_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_ALT[28]:SetAngles(0, 90, 0)
	end)

	Timers:CreateTimer(17, function()
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

		HEROLIST_ALT_VIP[5] = CreateUnitByName("npc_dota_hero_tiny_bis", Entities:FindByName(nil, "choose_tiny_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		HEROLIST_ALT_VIP[5]:SetAngles(0, 90, 0)

--		HEROLIST_ALT_VIP[6] = CreateUnitByName("npc_dota_hero_sand_king_bis", Entities:FindByName(nil, "choose_sand_king_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
--		HEROLIST_ALT_VIP[6]:SetAngles(0, 90, 0)
	end)

	Timers:CreateTimer(20, function()
		-- Special Events
		local frost_infernal = CreateUnitByName("npc_frost_infernal_bis", Entities:FindByName(nil, "frost_infernal_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		frost_infernal:SetAngles(0, 270, 0)

		local spirit_beast = CreateUnitByName("npc_spirit_beast_bis", Entities:FindByName(nil, "spirit_beast_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		spirit_beast:SetAngles(0, 270, 0)

		local hero_image = CreateUnitByName("npc_hero_image_bis", Entities:FindByName(nil, "hero_image_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		hero_image:SetAngles(0, 270, 0)

		local ramero = CreateUnitByName("npc_ramero_bis", Entities:FindByName(nil, "point_special_arena_1"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		ramero:SetAngles(0, 270, 0)

		local baristal = CreateUnitByName("npc_baristal_bis", Entities:FindByName(nil, "point_special_arena_2"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		baristal:SetAngles(0, 270, 0)

		local ramero_alt = CreateUnitByName("npc_ramero_bis", Entities:FindByName(nil, "point_special_arena_3"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_GOODGUYS)
		ramero_alt:SetAngles(0, 270, 0)

		lich_king = CreateUnitByName("npc_dota_boss_lich_king_bis", Entities:FindByName(nil, "npc_dota_spawner_lich_king"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
		lich_king:SetAngles(0, 270, 0)
		lich_king:AddNewModifier(nil, nil, "modifier_invulnerable", nil)
		StartAnimation(lich_king, {duration = 20000.0, activity = ACT_DOTA_IDLE, rate = 0.9})

		spirit_master = CreateUnitByName("npc_dota_boss_spirit_master_bis", Entities:FindByName(nil, "spirit_master_point"):GetAbsOrigin(), true, nil, nil, DOTA_TEAM_BADGUYS)
		spirit_master:SetAngles(0, 90, 0)
		spirit_master:AddNewModifier(nil, nil, "modifier_invulnerable", nil)
		spirit_master:AddNewModifier(nil, nil, "modifier_boss_stun", nil)
--		StartAnimation(spirit_master, {duration = 20000.0, activity = ACT_DOTA_VICTORY, rate = 1.0})
	end)
end

function SpawnTeleporterGoodGuys(keys)
local activator = keys.activator
local heroes = HeroList:GetAllHeroes()
	for _,hero in pairs(heroes) do
	local id = hero:GetPlayerID()
	local point = Entities:FindByName(nil, "point_teleport_choose_hero_"..id)
		PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), hero)
		Timers:CreateTimer(13.0, function()
			FindClearSpaceForUnit(hero, point:GetAbsOrigin(), true)
		end)
		Timers:CreateTimer(19.0, function()
			PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(),nil)
			Entities:FindByName(nil, "trigger_teleport_spawn"):Disable()
		end)
	end
end

function ChooseHero(event)
local activator = event.activator
local caller = event.caller
local id = activator:GetPlayerID()
	for playerID = 0, DOTA_MAX_TEAM_PLAYERS -1 do
		if PlayerResource:IsValidPlayer(playerID) and activator:GetUnitName() == "npc_dota_hero_wisp" then
			for i = 1, #HEROLIST do
				if caller:GetName() == "trigger_hero_"..i then
				local point = Entities:FindByName(nil, "base_spawn")
					PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(), nil)
					FindClearSpaceForUnit(activator, point:GetAbsOrigin(), true)
					Timers:CreateTimer(2.0, function()
						activator:SetPlayerID(id)
					end)
					UTIL_Remove(HEROLIST_ALT[i])
					UTIL_Remove(Entities:FindByName(nil, "trigger_hero_"..i))
					local newHero = PlayerResource:ReplaceHeroWith(activator:GetPlayerID(), "npc_dota_hero_"..HEROLIST[i], STARTING_GOLD, 0)
					local particle = ParticleManager:CreateParticle("particles/econ/events/ti6/hero_levelup_ti6.vpcf", PATTACH_ABSORIGIN_FOLLOW, newHero)
					ParticleManager:SetParticleControl(particle, 0, newHero:GetAbsOrigin())
					local item1 = newHero:AddItemByName("item_ankh_of_reincarnation")
					local item2 = newHero:AddItemByName("item_healing_potion")
					local item3 = newHero:AddItemByName("item_mana_potion")
					local item4 = newHero:AddItemByName("item_backpack")
					local item5 = newHero:AddItemByName("item_backpack")
					local item6 = newHero:AddItemByName("item_backpack")
					newHero:SwapItems(3, 6)
					newHero:SwapItems(4, 7)
					newHero:SwapItems(5, 8)
				end
			end
		end
	end
end

function ChooseHeroVIP(event)
local activator = event.activator
local caller = event.caller
local id = activator:GetPlayerID()
local msg = "This hero is only for <font color='#FF0000'>VIP Members!</font> Please choose another hero."
	for playerID = 0, DOTA_MAX_TEAM_PLAYERS -1 do
		if PlayerResource:IsValidPlayer(playerID) and activator:GetUnitName() == "npc_dota_hero_wisp" and activator:HasAbility("holdout_vip") then
			for i = 1, #HEROLIST_VIP do
				if caller:GetName() == "trigger_hero_vip_"..i then
				local point = Entities:FindByName(nil, "base_spawn")
					PlayerResource:SetCameraTarget(activator:GetPlayerOwnerID(), nil)
					FindClearSpaceForUnit(activator, point:GetAbsOrigin(), true)
					Timers:CreateTimer(2.0, function()
						activator:SetPlayerID(id)
					end)
					local newHero = PlayerResource:ReplaceHeroWith(activator:GetPlayerID(), "npc_dota_hero_"..HEROLIST_VIP[i], STARTING_GOLD, 0)
					local particle = ParticleManager:CreateParticle("particles/econ/events/ti6/hero_levelup_ti6.vpcf", PATTACH_ABSORIGIN_FOLLOW, newHero)
					ParticleManager:SetParticleControl(particle, 0, newHero:GetAbsOrigin())
					local item1 = newHero:AddItemByName("item_ankh_of_reincarnation")
					local item2 = newHero:AddItemByName("item_healing_potion")
					local item3 = newHero:AddItemByName("item_mana_potion")
					local item4 = newHero:AddItemByName("item_backpack")
					local item5 = newHero:AddItemByName("item_backpack")
					local item6 = newHero:AddItemByName("item_backpack")
					newHero:SwapItems(3, 6)
					newHero:SwapItems(4, 7)
					newHero:SwapItems(5, 8)
				end
			end
		elseif PlayerResource:IsValidPlayer(playerID) and activator:GetUnitName() == "npc_dota_hero_wisp" then
			Notifications:Bot(activator:GetPlayerOwnerID(),{text = msg, duration = 5.0})
		end
	end
end
