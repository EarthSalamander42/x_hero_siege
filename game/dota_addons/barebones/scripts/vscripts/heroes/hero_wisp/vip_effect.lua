function RedWisp(keys)
local caster = keys.caster
	if caster:GetUnitName() == "npc_dota_hero_wisp" then
		for i = 1, #vip_members do
			if PlayerResource:GetSteamAccountID(caster:GetPlayerID()) == mod_creator[i] then
				local vip_effect = ParticleManager:CreateParticle("particles/status_fx/status_effect_holdout_borrowed_time_3.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
				ParticleManager:SetParticleControl(vip_effect, 0, caster:GetAbsOrigin())
				ParticleManager:SetParticleControl(vip_effect, 1, caster:GetAbsOrigin())

				local vip_effect2 = ParticleManager:CreateParticle("particles/units/heroes/hero_abaddon/holdout_borrowed_time_3.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
				ParticleManager:SetParticleControl(vip_effect2, 0, caster:GetAbsOrigin())
				ParticleManager:SetParticleControl(vip_effect2, 1, caster:GetAbsOrigin())
			end
			if PlayerResource:GetSteamAccountID(caster:GetPlayerID()) == mod_graphist[i] then
				local vip_effect = ParticleManager:CreateParticle("particles/status_fx/status_effect_holdout_borrowed_time_3.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
				ParticleManager:SetParticleControl(vip_effect, 0, caster:GetAbsOrigin())
				ParticleManager:SetParticleControl(vip_effect, 1, caster:GetAbsOrigin())

				local vip_effect2 = ParticleManager:CreateParticle("particles/units/heroes/hero_abaddon/holdout_borrowed_time_3.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
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
			if PlayerResource:GetSteamAccountID(caster:GetPlayerID()) == vip_members[i] then
				local vip_effect = ParticleManager:CreateParticle("particles/status_fx/status_effect_holdout_borrowed_time_2.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
				ParticleManager:SetParticleControl(vip_effect, 0, caster:GetAbsOrigin())
				ParticleManager:SetParticleControl(vip_effect, 1, caster:GetAbsOrigin())

				local vip_effect2 = ParticleManager:CreateParticle("particles/units/heroes/hero_abaddon/holdout_borrowed_time_2.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
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
		end
	end
end
