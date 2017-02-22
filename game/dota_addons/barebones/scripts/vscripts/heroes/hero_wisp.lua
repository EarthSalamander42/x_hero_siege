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
local caster = event.caster
local id = caster:GetPlayerID()
local point = Entities:FindByName(nil, "base_spawn")
local random = RandomInt(1, #HEROLIST)

	local IsAvailableHero = Entities:FindByName(nil, "trigger_hero_"..random)
	if not IsAvailableHero:IsNull() then
		UTIL_Remove(IsAvailableHero)
		UTIL_Remove(HEROLIST_ALT[random])
		PlayerResource:SetCameraTarget(caster:GetPlayerOwnerID(), nil)
		FindClearSpaceForUnit(caster, point:GetAbsOrigin(), true)
		local newHero = PlayerResource:ReplaceHeroWith(caster:GetPlayerID(), "npc_dota_hero_"..HEROLIST[random], STARTING_GOLD * 2, 0)
		caster:SetPlayerID(id)
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
