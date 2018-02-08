modifier_rune_immolation = class({})

function modifier_rune_immolation:IsHidden() return false end

function modifier_rune_immolation:GetTextureName()
	return "modifiers/cloak_of_flames"
end

function modifier_rune_immolation:GetEffectName()
	return "particles/units/heroes/hero_lone_druid/lone_druid_battle_cry_overhead_ember.vpcf"
end

function modifier_rune_immolation:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function modifier_rune_immolation:OnCreated()
	self.radius = 375
	self.damage = 75
	self:StartIntervalThink(1.0)

	self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_ember_spirit/ember_spirit_flameguard.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	ParticleManager:SetParticleControl(self.particle, 0, Vector(0, 0, 0))
	ParticleManager:SetParticleControl(self.particle, 1, Vector(self.radius, 1, 1))
end

function modifier_rune_immolation:OnIntervalThink()
	local enemies = FindUnitsInRadius(self:GetParent():GetTeamNumber(), self:GetParent():GetAbsOrigin(), nil, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

	for _, enemy in pairs(enemies) do
	    ApplyDamage({attacker = self:GetParent(), victim = enemy, ability = self, damage = self.damage, damage_type = DAMAGE_TYPE_MAGICAL})
	end
end

function modifier_rune_immolation:OnDestroy()
	ParticleManager:DestroyParticle(self.particle, false)
	ParticleManager:ReleaseParticleIndex(self.particle)
end
