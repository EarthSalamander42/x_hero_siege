function reincarnation( event )
	-- body
	local ability = event.ability
	local hero = event.caster
	local position = hero:GetAbsOrigin()
	local respawntime = ability:GetSpecialValueFor("reincarnation_time")

	if hero:IsRealHero() then
		hero:SetBuybackEnabled(false)
		
		hero.respawn_timer = Timers:CreateTimer(respawntime,function () 
			hero:SetRespawnPosition(position)
			hero:RespawnHero(false, false, false)
			ParticleManager:CreateParticle("particles/items_fx/aegis_respawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
			hero.ankh_respawn = false
			hero:SetBuybackEnabled(true)
			end)
		hero.ankh_respawn = true

		if ability:GetCurrentCharges()-1 >= 1 then
			ability:SetCurrentCharges(ability:GetCurrentCharges()-1)
		else
			ability:RemoveSelf()
		end
	end
end

function shield( event )
	-- body
	local ability = event.ability
	local hero = event.caster
	local position = hero:GetAbsOrigin()
	local respawntime = ability:GetSpecialValueFor("reincarnation_time")

	if hero:IsRealHero() then

		hero:SetRespawnsDisabled(true)
		
		hero.respawn_timer = Timers:CreateTimer(respawntime,function () 
			hero:SetRespawnPosition(position)
			hero:RespawnHero(false, false, false)
			ParticleManager:CreateParticle("particles/items_fx/aegis_respawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
			hero.ankh_respawn = false
			hero:SetRespawnsDisabled(false)
			end)
		hero.ankh_respawn = true
		
	end


end