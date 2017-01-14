function Lifesteal( event )
local attacker = event.attacker
local target = event.target
local ability = event.ability

	if target.GetInvulnCount == nil and not target:IsBuilding() then
		ability:ApplyDataDrivenModifier(attacker, attacker, "modifier_lifesteal", {duration = 0.03})		
	end
end

function Reincarnation( event )
	local ability = event.ability
	local hero = event.caster
	local position = hero:GetAbsOrigin()
	local respawntime = ability:GetSpecialValueFor("reincarnation_time")

	if hero:IsRealHero() and not hero.ankh_respawn then
		hero:SetRespawnsDisabled(true)

		hero.respawn_timer = Timers:CreateTimer(respawntime,function () 
			hero:SetRespawnPosition(position)
			hero:EmitSound("Ability.ReincarnationAlt")
			hero:RespawnHero(false, false, false)
			ParticleManager:CreateParticle("particles/items_fx/aegis_respawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
			hero.ankh_respawn = false
			hero:SetRespawnsDisabled(false)
			end)
		hero.ankh_respawn = true

		ability:StartCooldown(60.0)
	end
end
