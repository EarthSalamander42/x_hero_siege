LinkLuaModifier("modifier_rune_immolation", "items/item_rune_immolation.lua", LUA_MODIFIER_MOTION_NONE)

item_rune_immolation = item_rune_immolation or class({})

function item_rune_immolation:OnSpellStart()
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.duration = self:GetSpecialValueFor("duration") or -1

	self.caster:AddNewModifier(self.caster, self, "modifier_rune_immolation", { duration = self.duration })
	self.caster:EmitSound("Rune.Haste")

	PickupRune(self, self.caster)

	self.caster:RemoveItem(self)
end

modifier_rune_immolation = modifier_rune_immolation or class({})

function modifier_rune_immolation:IsHidden() return false end

function modifier_rune_immolation:GetTexture() return "custom/holdout_immolation" end

function modifier_rune_immolation:GetEffectName() return "particles/units/heroes/hero_lone_druid/lone_druid_battle_cry_overhead_ember.vpcf" end

function modifier_rune_immolation:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function modifier_rune_immolation:OnCreated()
	self.tick_time = self:GetAbility():GetSpecialValueFor("tick_time")
	self.radius = self:GetAbility():GetSpecialValueFor("radius")
	self.damage = self:GetAbility():GetSpecialValueFor("damage_per_tick") / self.tick_time

	if not IsServer() then return end

	self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_ember_spirit/ember_spirit_flameguard.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	ParticleManager:SetParticleControl(self.particle, 0, Vector(0, 0, 0))
	ParticleManager:SetParticleControl(self.particle, 1, Vector(self.radius, 1, 1))

	self:StartIntervalThink(self.tick_time)
end

function modifier_rune_immolation:OnIntervalThink()
	local enemies = FindUnitsInRadius(self:GetParent():GetTeamNumber(), self:GetParent():GetAbsOrigin(), nil, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)

	for _, enemy in pairs(enemies) do
		ApplyDamage({ attacker = self:GetParent(), victim = enemy, ability = self, damage = self.damage, damage_type = DAMAGE_TYPE_MAGICAL })
	end
end

function modifier_rune_immolation:OnDestroy()
	if not IsServer() then return end

	if self.particle then
		ParticleManager:DestroyParticle(self.particle, false)
		ParticleManager:ReleaseParticleIndex(self.particle)
	end
end
