-- Nevermore's soul harvest (autoattacks)

frostivus_boss_soul_harvest = class({})

function frostivus_boss_soul_harvest:IsHiddenWhenStolen() return true end
function frostivus_boss_soul_harvest:IsRefreshable() return true end
function frostivus_boss_soul_harvest:IsStealable() return false end

function frostivus_boss_soul_harvest:OnProjectileHit_ExtraData(target, location, keys)
	if IsServer() then
		if target then

			-- Play hit sound
			target:EmitSound("Hero_Nevermore.ProjectileImpact")

			-- Apply Necromastery
			self:GetCaster():FindModifierByName("modifier_frostivus_necromastery"):IncrementStackCount()

			-- Deal damage
			local damage_dealt = ApplyDamage({victim = target, attacker = self:GetCaster(), ability = nil, damage = keys.damage * RandomInt(90, 110) * 0.01, damage_type = DAMAGE_TYPE_PHYSICAL})
			SendOverheadEventMessage(nil, OVERHEAD_ALERT_DAMAGE, target, damage_dealt, nil)
		end
	end
end