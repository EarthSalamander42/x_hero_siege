LinkLuaModifier(
	"modifier_creature_thunder_clap_low",
	"abilities/creeps/creature_thunder_clap_low",
	LUA_MODIFIER_MOTION_NONE
)

creature_thunder_clap_low = creature_thunder_clap_low or class({})

local WARNING_PARTICLE = "particles/custom/boss_warnings/magtheridon/radius.vpcf"
local IMPACT_PARTICLE = "particles/units/heroes/hero_brewmaster/brewmaster_thunder_clap.vpcf"
local DEBUFF_PARTICLE = "particles/units/heroes/hero_brewmaster/brewmaster_thunder_clap_debuff.vpcf"
local STATUS_PARTICLE = "particles/status_fx/status_effect_brewmaster_thunder_clap.vpcf"

function creature_thunder_clap_low:OnAbilityPhaseStart()
	if not IsServer() then return true end

	self:DestroyWarningParticle(true)

	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	self.warning_particle = ParticleManager:CreateParticle(
		WARNING_PARTICLE,
		PATTACH_CUSTOMORIGIN,
		caster
	)
	ParticleManager:SetParticleControl(
		self.warning_particle,
		0,
		caster:GetAbsOrigin()
	)
	ParticleManager:SetParticleControl(
		self.warning_particle,
		1,
		Vector(radius, 6, 0)
	)
	return true
end

function creature_thunder_clap_low:OnAbilityPhaseInterrupted()
	if IsServer() then
		self:DestroyWarningParticle(true)
	end
end

function creature_thunder_clap_low:OnSpellStart()
	if not IsServer() then return end

	self:DestroyWarningParticle(true)

	local caster = self:GetCaster()
	local origin = caster:GetAbsOrigin()
	local radius = self:GetSpecialValueFor("radius")
	local duration = self:GetSpecialValueFor("duration")

	caster:EmitSound("Hero_Brewmaster.ThunderClap")

	local impact = ParticleManager:CreateParticle(
		IMPACT_PARTICLE,
		PATTACH_ABSORIGIN_FOLLOW,
		caster
	)
	ParticleManager:SetParticleControl(impact, 1, Vector(radius, 0, 0))
	ParticleManager:ReleaseParticleIndex(impact)

	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		origin,
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false
	)

	for _, enemy in pairs(enemies) do
		ApplyDamage({
			victim = enemy,
			attacker = caster,
			ability = self,
			damage = self:GetSpecialValueFor("damage"),
			damage_type = DAMAGE_TYPE_PURE,
		})
		enemy:AddNewModifier(
			caster,
			self,
			"modifier_creature_thunder_clap_low",
			{ duration = duration * (1 - enemy:GetStatusResistance()) }
		)
	end
end

function creature_thunder_clap_low:DestroyWarningParticle(immediate)
	if self.warning_particle == nil then return end

	ParticleManager:DestroyParticle(self.warning_particle, immediate == true)
	ParticleManager:ReleaseParticleIndex(self.warning_particle)
	self.warning_particle = nil
end

modifier_creature_thunder_clap_low =
	modifier_creature_thunder_clap_low or class({})
modifier_creature_thunder_clap_low.XHS_LINK_CLIENT = true

function modifier_creature_thunder_clap_low:IsDebuff() return true end

function modifier_creature_thunder_clap_low:IsPurgable() return true end

function modifier_creature_thunder_clap_low:OnCreated()
	local ability = self:GetAbility()
	self.movement_slow = ability and ability:GetSpecialValueFor("movement_slow") or 0
	self.attack_speed_slow = ability and ability:GetSpecialValueFor("attack_speed_slow") or 0

	if IsServer() then
		self:GetParent():EmitSound("Hero_Brewmaster.ThunderClap.Target")
	end
end

function modifier_creature_thunder_clap_low:OnRefresh()
	self:OnCreated()
end

function modifier_creature_thunder_clap_low:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
	}
end

function modifier_creature_thunder_clap_low:GetModifierMoveSpeedBonus_Percentage()
	return self.movement_slow
end

function modifier_creature_thunder_clap_low:GetModifierAttackSpeedBonus_Constant()
	return self.attack_speed_slow
end

function modifier_creature_thunder_clap_low:GetEffectName()
	return DEBUFF_PARTICLE
end

function modifier_creature_thunder_clap_low:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_creature_thunder_clap_low:GetStatusEffectName()
	return STATUS_PARTICLE
end

function modifier_creature_thunder_clap_low:StatusEffectPriority()
	return 10
end
