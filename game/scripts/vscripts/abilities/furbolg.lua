furbolg_earthshock = class({})

LinkLuaModifier("modifier_furbolg_earthshock_slow", "abilities/furbolg", LUA_MODIFIER_MOTION_NONE)

function furbolg_earthshock:GetCastRange(location, target)
	return self:GetSpecialValueFor("radius")
end

function furbolg_earthshock:OnSpellStart()
	if not IsServer() then return end

	-- Play cast sound
	EmitSoundOn("Hero_Ursa.Earthshock", self:GetCaster())

	-- Add appropriate particles
	local earthshock_particle_fx = ParticleManager:CreateParticle("particles/units/heroes/hero_ursa/ursa_earthshock.vpcf", PATTACH_ABSORIGIN, self:GetCaster())
	ParticleManager:SetParticleControl(earthshock_particle_fx, 0, self:GetCaster():GetAbsOrigin())
	ParticleManager:SetParticleControl(earthshock_particle_fx, 1, Vector(1,1,1))
	ParticleManager:ReleaseParticleIndex(earthshock_particle_fx)

	-- Find all enemies in Aoe
	local enemies = FindUnitsInRadius(
		self:GetCaster():GetTeamNumber(),
		self:GetCaster():GetAbsOrigin(),
		nil,
		self:GetSpecialValueFor("radius"),
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false
	)

	for _,enemy in pairs(enemies) do
		if not enemy:IsMagicImmune() then
			-- Apply damage
			local damageTable = {
				victim = enemy,
				attacker = self:GetCaster(),
				damage = self:GetSpecialValueFor("base_damage"),
				damage_type = DAMAGE_TYPE_MAGICAL,
				ability = self
			}

			ApplyDamage(damageTable)

			-- Apply debuff to non-magic immune enemies
			enemy:AddNewModifier(self:GetCaster(), self, "modifier_furbolg_earthshock_slow", {duration = self:GetSpecialValueFor("duration")})
		end
	end
end

-- Earthshock slow debuff
modifier_furbolg_earthshock_slow = class({})

function modifier_furbolg_earthshock_slow:IsDebuff() return true end
function modifier_furbolg_earthshock_slow:IsHidden() return false end
function modifier_furbolg_earthshock_slow:IsPurgable() return true end
function modifier_furbolg_earthshock_slow:GetEffectName() return "particles/units/heroes/hero_ursa/ursa_earthshock_modifier.vpcf" end
function modifier_furbolg_earthshock_slow:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_furbolg_earthshock_slow:DeclareFunctions() return {
	MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
} end

function modifier_furbolg_earthshock_slow:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("slow_pct") * (-1)
end
