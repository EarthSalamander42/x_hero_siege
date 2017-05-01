function WispEffects(keys)
local caster = keys.caster
	if caster:GetUnitName() == "npc_dota_hero_wisp" then
		for i = 1, #golden_vip_members do
			if PlayerResource:GetSteamAccountID(caster:GetPlayerID()) == mod_creator[i] then
				local vip_effect = ParticleManager:CreateParticle("particles/status_fx/status_effect_holdout_borrowed_time_3.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
				ParticleManager:SetParticleControl(vip_effect, 0, caster:GetAbsOrigin())
				ParticleManager:SetParticleControl(vip_effect, 1, caster:GetAbsOrigin())

				local vip_effect2 = ParticleManager:CreateParticle("particles/units/heroes/hero_abaddon/holdout_borrowed_time_3.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
				ParticleManager:SetParticleControl(vip_effect2, 0, caster:GetAbsOrigin())
				ParticleManager:SetParticleControl(vip_effect2, 1, caster:GetAbsOrigin())
			end
			if PlayerResource:GetSteamAccountID(caster:GetPlayerID()) == mod_graphist[i] then
				local vip_effect = ParticleManager:CreateParticle("particles/status_fx/status_effect_holdout_borrowed_time.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
				ParticleManager:SetParticleControl(vip_effect, 0, caster:GetAbsOrigin())
				ParticleManager:SetParticleControl(vip_effect, 1, caster:GetAbsOrigin())

				local vip_effect2 = ParticleManager:CreateParticle("particles/units/heroes/hero_abaddon/holdout_borrowed_time.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
				ParticleManager:SetParticleControl(vip_effect2, 0, caster:GetAbsOrigin())
				ParticleManager:SetParticleControl(vip_effect2, 1, caster:GetAbsOrigin())
			end
			if PlayerResource:GetSteamAccountID(caster:GetPlayerID()) == captain_baumi[i] then
				local vip_effect = ParticleManager:CreateParticle("particles/status_fx/status_effect_holdout_borrowed_time.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
				ParticleManager:SetParticleControl(vip_effect, 0, caster:GetAbsOrigin())
				ParticleManager:SetParticleControl(vip_effect, 1, caster:GetAbsOrigin())

				local vip_effect2 = ParticleManager:CreateParticle("particles/units/heroes/hero_abaddon/holdout_borrowed_time.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
				ParticleManager:SetParticleControl(vip_effect2, 0, caster:GetAbsOrigin())
				ParticleManager:SetParticleControl(vip_effect2, 1, caster:GetAbsOrigin())
			end
			if PlayerResource:GetSteamAccountID(caster:GetPlayerID()) == golden_vip_members[i] then
				local vip_effect = ParticleManager:CreateParticle("particles/status_fx/status_effect_holdout_borrowed_time_4.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
				ParticleManager:SetParticleControl(vip_effect, 0, caster:GetAbsOrigin())
				ParticleManager:SetParticleControl(vip_effect, 1, caster:GetAbsOrigin())

				local vip_effect2 = ParticleManager:CreateParticle("particles/units/heroes/hero_abaddon/holdout_borrowed_time_4.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
				ParticleManager:SetParticleControl(vip_effect2, 0, caster:GetAbsOrigin())
				ParticleManager:SetParticleControl(vip_effect2, 1, caster:GetAbsOrigin())
			end
			if PlayerResource:GetSteamAccountID(caster:GetPlayerID()) == vip_members[i] then
				local vip_effect = ParticleManager:CreateParticle("particles/status_fx/status_effect_holdout_borrowed_time_2.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
				ParticleManager:SetParticleControl(vip_effect, 0, caster:GetAbsOrigin())
				ParticleManager:SetParticleControl(vip_effect, 1, caster:GetAbsOrigin())

				local vip_effect2 = ParticleManager:CreateParticle("particles/units/heroes/hero_abaddon/holdout_borrowed_time_2.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
				ParticleManager:SetParticleControl(vip_effect2, 0, caster:GetAbsOrigin())
				ParticleManager:SetParticleControl(vip_effect2, 1, caster:GetAbsOrigin())
			end
		end
	end
end

function ChooseRandomHero(event)
local hero = event.caster
local id = hero:GetPlayerID()
local difficulty = GameRules:GetCustomGameDifficulty()
local point = Entities:FindByName(nil, "base_spawn")
local random = RandomInt(1, #HEROLIST)

	local IsAvailableHero = Entities:FindByName(nil, "trigger_hero_"..random)
	if DUAL_HERO == 1 then
		if not IsAvailableHero:IsNull() then
			UTIL_Remove(IsAvailableHero)
			UTIL_Remove(HEROLIST_ALT[random])
			local particle = ParticleManager:CreateParticle("particles/econ/events/ti6/hero_levelup_ti6.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
			ParticleManager:SetParticleControl(particle, 0, hero:GetAbsOrigin())
			EmitSoundOnClient("ui.trophy_levelup", PlayerResource:GetPlayer(id))
			hero:AddNewModifier(nil, nil, "modifier_boss_stun", {Duration = 3.0, IsHidden = true})
			PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), hero)
			Notifications:Bottom(hero:GetPlayerOwnerID(), {hero="npc_dota_hero_"..HEROLIST[random], duration = 5.0})
			Notifications:Bottom(hero:GetPlayerOwnerID(), {text="HERO: ", duration = 5.0, style={color="white"}, continue=true})
			Notifications:Bottom(hero:GetPlayerOwnerID(), {text="#npc_dota_hero_"..HEROLIST[random], duration = 5.0, style={color="white"}, continue=true})
			Timers:CreateTimer(3.0, function()
				FindClearSpaceForUnit(hero, point:GetAbsOrigin(), true)
				local newHero = PlayerResource:ReplaceHeroWith(hero:GetPlayerID(), "npc_dota_hero_"..HEROLIST[random], STARTING_GOLD * 2, 0)
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
	elseif DUAL_HERO == 2 then
		if not IsAvailableHero:IsNull() and hero.dual_choose == 0 then
			local particle = ParticleManager:CreateParticle("particles/econ/events/ti6/hero_levelup_ti6.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
			ParticleManager:SetParticleControl(particle, 0, hero:GetAbsOrigin())
			EmitSoundOnClient("ui.trophy_levelup", PlayerResource:GetPlayer(id))
			UTIL_Remove(Entities:FindByName(nil, "trigger_hero_"..random))
			UTIL_Remove(HEROLIST_ALT[random])
			Notifications:Bottom(hero:GetPlayerOwnerID(), {hero="npc_dota_hero_"..HEROLIST[random], duration = 5.0})
			Notifications:Bottom(hero:GetPlayerOwnerID(), {text="HERO: ", duration = 5.0, style={color="white"}, continue=true})
			Notifications:Bottom(hero:GetPlayerOwnerID(), {text="#npc_dota_hero_"..HEROLIST[random], duration = 5.0, style={color="white"}, continue=true})
			Notifications:Bottom(hero:GetPlayerOwnerID(), {text="DUAL MODE: Please choose a second hero!", duration = 5.0, style={color="white"}})
			DUAL_HERO_1[id] = "npc_dota_hero_"..HEROLIST[random]
			hero.dual_choose = 1
			print("Hero 1: "..DUAL_HERO_1[id])
		end
		if not IsAvailableHero:IsNull() and hero.dual_choose == 1 then
			CustomGameEventManager:Send_ServerToPlayer(hero:GetPlayerOwner(), "show_dual", {})
			DUAL_HERO_2[id] = "npc_dota_hero_"..HEROLIST[random]
			print("Hero 2: "..DUAL_HERO_2[id])
			local particle = ParticleManager:CreateParticle("particles/econ/events/ti6/hero_levelup_ti6.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
			ParticleManager:SetParticleControl(particle, 0, hero:GetAbsOrigin())
			EmitSoundOnClient("ui.trophy_levelup", PlayerResource:GetPlayer(id))
			hero:AddNewModifier(nil, nil, "modifier_boss_stun", {Duration = 3.0, IsHidden = true})
			PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), hero)
			Notifications:Bottom(hero:GetPlayerOwnerID(), {hero="npc_dota_hero_"..HEROLIST[random], duration = 5.0})
			Notifications:Bottom(hero:GetPlayerOwnerID(), {text="HERO: ", duration = 5.0, style={color="white"}, continue=true})
			Notifications:Bottom(hero:GetPlayerOwnerID(), {text="#npc_dota_hero_"..HEROLIST[random], duration = 5.0, style={color="white"}, continue=true})
			Timers:CreateTimer(3.0, function()
				UTIL_Remove(Entities:FindByName(nil, "trigger_hero_"..random))
				UTIL_Remove(HEROLIST_ALT[random])
				FindClearSpaceForUnit(hero, point:GetAbsOrigin(), true)
				local newHero = PlayerResource:ReplaceHeroWith(hero:GetPlayerID(), "npc_dota_hero_"..HEROLIST[random], STARTING_GOLD * 2, 0)
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
