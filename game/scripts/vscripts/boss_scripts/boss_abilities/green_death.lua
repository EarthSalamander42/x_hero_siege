-- Venomancer's Green Death (mainly projectile stuff)

frostivus_boss_green_death = class({})

function frostivus_boss_green_death:IsHiddenWhenStolen() return true end
function frostivus_boss_green_death:IsRefreshable() return true end
function frostivus_boss_green_death:IsStealable() return false end

function frostivus_boss_green_death:OnProjectileHit_ExtraData(target, location, ExtraData)
	if IsServer() then
		if target then
			local caster = self:GetCaster()
			local damage = ExtraData.damage

			-- Play hit sound
			target:EmitSound("Frostivus.GreenDeathImpact")

			-- Play impact particle
			local impact_pfx = ParticleManager:CreateParticle("particles/boss_veno/green_death_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
			ParticleManager:SetParticleControlEnt(impact_pfx, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", location, true)
			ParticleManager:ReleaseParticleIndex(impact_pfx)

			-- Deal damage
			local damage_dealt = ApplyDamage({victim = target, attacker = caster, ability = nil, damage = damage * RandomInt(90, 110) * 0.01, damage_type = DAMAGE_TYPE_MAGICAL})
			SendOverheadEventMessage(target, OVERHEAD_ALERT_BONUS_POISON_DAMAGE, target, damage_dealt, nil)
		end
	end
end