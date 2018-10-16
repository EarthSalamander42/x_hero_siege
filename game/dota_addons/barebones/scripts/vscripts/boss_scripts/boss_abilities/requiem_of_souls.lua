-- Nevermore's Requiem of Souls (mainly projectile stuff)

frostivus_boss_requiem_of_souls = class({})

function frostivus_boss_requiem_of_souls:IsHiddenWhenStolen() return true end
function frostivus_boss_requiem_of_souls:IsRefreshable() return true end
function frostivus_boss_requiem_of_souls:IsStealable() return false end

function frostivus_boss_requiem_of_souls:OnProjectileHit_ExtraData(target, location, ExtraData)
	if IsServer() then
		if target then
			local caster = self:GetCaster()
			local damage = ExtraData.damage

			-- Play hit sound
			target:EmitSound("Hero_Nevermore.RequiemOfSouls.Damage")

			-- Deal damage
			local damage_dealt = ApplyDamage({victim = target, attacker = caster, ability = nil, damage = damage * RandomInt(90, 110) * 0.01, damage_type = DAMAGE_TYPE_MAGICAL})
			SendOverheadEventMessage(nil, OVERHEAD_ALERT_DAMAGE, target, damage_dealt, nil)
		end
	end
end