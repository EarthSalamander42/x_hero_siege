function WispEffects(keys)
local caster = keys.caster
	if caster:GetUnitName() == "npc_dota_hero_wisp" then

		if IsDonator(caster) == 1 then
			local vip_effect = ParticleManager:CreateParticle("particles/status_fx/status_effect_holdout_borrowed_time_3.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControl(vip_effect, 0, caster:GetAbsOrigin())
			ParticleManager:SetParticleControl(vip_effect, 1, caster:GetAbsOrigin())

			local vip_effect2 = ParticleManager:CreateParticle("particles/units/heroes/hero_abaddon/holdout_borrowed_time_3.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControl(vip_effect2, 0, caster:GetAbsOrigin())
			ParticleManager:SetParticleControl(vip_effect2, 1, caster:GetAbsOrigin())
		elseif IsDonator(caster) == 2 or IsDonator(caster) == 3 then
			local vip_effect = ParticleManager:CreateParticle("particles/status_fx/status_effect_holdout_borrowed_time.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControl(vip_effect, 0, caster:GetAbsOrigin())
			ParticleManager:SetParticleControl(vip_effect, 1, caster:GetAbsOrigin())

			local vip_effect2 = ParticleManager:CreateParticle("particles/units/heroes/hero_abaddon/holdout_borrowed_time.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControl(vip_effect2, 0, caster:GetAbsOrigin())
			ParticleManager:SetParticleControl(vip_effect2, 1, caster:GetAbsOrigin())
		elseif IsDonator(caster) == 4 then
			local vip_effect = ParticleManager:CreateParticle("particles/status_fx/status_effect_holdout_borrowed_time_3.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControl(vip_effect, 0, caster:GetAbsOrigin())
			ParticleManager:SetParticleControl(vip_effect, 1, caster:GetAbsOrigin())

			local vip_effect2 = ParticleManager:CreateParticle("particles/units/heroes/hero_abaddon/holdout_borrowed_time_3.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControl(vip_effect2, 0, caster:GetAbsOrigin())
			ParticleManager:SetParticleControl(vip_effect2, 1, caster:GetAbsOrigin())
		elseif IsDonator(caster) == 5 then
			local vip_effect = ParticleManager:CreateParticle("particles/status_fx/status_effect_holdout_borrowed_time_4.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControl(vip_effect, 0, caster:GetAbsOrigin())
			ParticleManager:SetParticleControl(vip_effect, 1, caster:GetAbsOrigin())

			local vip_effect2 = ParticleManager:CreateParticle("particles/units/heroes/hero_abaddon/holdout_borrowed_time_4.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControl(vip_effect2, 0, caster:GetAbsOrigin())
			ParticleManager:SetParticleControl(vip_effect2, 1, caster:GetAbsOrigin())
		elseif IsDonator(caster) == 6 then
			local vip_effect = ParticleManager:CreateParticle("particles/status_fx/status_effect_holdout_borrowed_time_2.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControl(vip_effect, 0, caster:GetAbsOrigin())
			ParticleManager:SetParticleControl(vip_effect, 1, caster:GetAbsOrigin())

			local vip_effect2 = ParticleManager:CreateParticle("particles/units/heroes/hero_abaddon/holdout_borrowed_time_2.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControl(vip_effect2, 0, caster:GetAbsOrigin())
			ParticleManager:SetParticleControl(vip_effect2, 1, caster:GetAbsOrigin())
		end

		for i = 1, #vip_members do
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
local random = RandomInt(1, #HEROLIST + 1) -- Weekly hero
local IsAvailableHero = Entities:FindByName(nil, "trigger_hero_"..random)
local difficulty = GameRules:GetCustomGameDifficulty()
local hero_name

	if random == 12 or random == 27 then
		print("This hero is either chosen or disabled! Re-rolls Random Hero")
		ChooseRandomHero(event)
		return
	elseif random == #HEROLIST + 1 then
		hero_name = WeekHero
	end

	hero_name = "npc_dota_hero_"..HEROLIST[random]

	UTIL_Remove(IsAvailableHero)
	local particle = ParticleManager:CreateParticle("particles/econ/events/ti6/hero_levelup_ti6.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
	ParticleManager:SetParticleControl(particle, 0, hero:GetAbsOrigin())
	EmitSoundOnClient("ui.trophy_levelup", PlayerResource:GetPlayer(id))
	hero:AddNewModifier(hero, nil, "modifier_command_restricted", {})
	Notifications:Bottom(hero:GetPlayerOwnerID(), {hero=hero_name, duration = 5.0})
	Notifications:Bottom(hero:GetPlayerOwnerID(), {text="HERO: ", duration = 5.0, style={color="white"}, continue=true})
	Notifications:Bottom(hero:GetPlayerOwnerID(), {text="#npc_dota_hero_"..HEROLIST[random], duration = 5.0, style={color="white"}, continue=true})

	local newHero = PlayerResource:ReplaceHeroWith(id, hero_name, STARTING_GOLD[difficulty] * 2, 0)
	StartingItems(hero, newHero)

	Timers:CreateTimer(0.1, function()
		if not hero:IsNull() then
			UTIL_Remove(hero)
		end
	end)
end
