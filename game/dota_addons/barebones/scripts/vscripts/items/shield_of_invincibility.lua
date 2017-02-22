function Reincarnation( event )
	local ability = event.ability
	local hero = event.caster
	local position = hero:GetAbsOrigin()
	local respawntime = ability:GetSpecialValueFor("reincarnation_time")

	if hero:IsRealHero() and not hero.ankh_respawn and ability:IsCooldownReady() then
		hero:SetRespawnsDisabled(true)
		hero.respawn_timer = Timers:CreateTimer(respawntime, function() 
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

function Return( event )
local caster = event.caster
local attacker = event.attacker
local ability = event.ability
local damageType = DAMAGE_TYPE_PHYSICAL
local return_damage = ability:GetSpecialValueFor("damage_return_pct")
local attacker_damage = attacker:GetBaseDamageMin()
local divided_damage = attacker_damage / 100
local total_damage = divided_damage * return_damage

	if attacker:GetTeamNumber() ~= caster:GetTeamNumber() and not attacker:IsBuilding() then
		ApplyDamage({ victim = attacker, attacker = caster, damage = total_damage, damage_type = damageType })
	end
end
