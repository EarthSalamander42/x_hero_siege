LinkLuaModifier("modifier_balanar_rain_of_chaos", "abilities/heroes/npc_hero_balanar/balanar_rain_of_chaos.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_balanar_rain_of_chaos_dummy", "abilities/heroes/npc_hero_balanar/balanar_rain_of_chaos.lua", LUA_MODIFIER_MOTION_NONE)

balanar_rain_of_chaos = balanar_rain_of_chaos or class({})
holdout_rain_of_chaos = balanar_rain_of_chaos
holdout_rain_of_chaos_20 = balanar_rain_of_chaos

function balanar_rain_of_chaos:OnSpellStart()
	local caster = self:GetCaster()

	self.radius = self:GetSpecialValueFor("radius")
	self.radius_explosion = self:GetSpecialValueFor("radius_explosion")
	self.meteors_per_tick = self:GetSpecialValueFor("meteors_per_tick")
	self.interval = self:GetSpecialValueFor("time_between_meteors")
	self.duration = self:GetSpecialValueFor("duration")
	self.damage = self:GetSpecialValueFor("damage_per_unit")
	self.stun_duration = self:GetSpecialValueFor("stun_duration")
	self.golem_duration = self:GetSpecialValueFor("golem_duration")
	self.damage_reduction = self:GetSpecialValueFor("damage_reduction")
	self.seek_radius = self:GetSpecialValueFor("seek_radius")

	caster:AddNewModifier(caster, self, "modifier_balanar_rain_of_chaos", { duration = self.duration })

	if caster:GetUnitName() == "npc_dota_hero_balanar" then
		caster:AddNewModifier(caster, self, "modifier_invulnerable", { duration = self.duration })
	end

	caster:EmitSound("DOTA_Item.BlackKingBar.Activate")
end

modifier_balanar_rain_of_chaos = modifier_balanar_rain_of_chaos or class({})

function modifier_balanar_rain_of_chaos:IsHidden() return true end

function modifier_balanar_rain_of_chaos:IsPurgable() return false end

function modifier_balanar_rain_of_chaos:GetEffectName() return "particles/items_fx/black_king_bar_avatar.vpcf" end

function modifier_balanar_rain_of_chaos:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_balanar_rain_of_chaos:DeclareFunctions()
	return
	{
		MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
	}
end

function modifier_balanar_rain_of_chaos:CheckState()
	return
	{
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
		[MODIFIER_STATE_MAGIC_IMMUNE] = true,

	}
end

function modifier_balanar_rain_of_chaos:GetOverrideAnimation()
	return ACT_DOTA_TELEPORT
end

function modifier_balanar_rain_of_chaos:OnCreated()
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.ability = self:GetAbility()

	self:StartIntervalThink(self.ability.interval)
end

function modifier_balanar_rain_of_chaos:OnIntervalThink()
	local enemies = FindUnitsInRadius(self.caster:GetTeamNumber(), self.caster:GetAbsOrigin(), nil, self.ability.seek_radius, self.ability:GetAbilityTargetTeam(), self.ability:GetAbilityTargetType(), self.ability:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)
	local point

	if #enemies == 0 then
		point = self.caster:GetAbsOrigin() + RandomInt(200, self.ability.radius) * RandomVector(1)
	else
		local random_enemy = enemies[RandomInt(1, #enemies)]

		if random_enemy and not random_enemy:IsNull() then
			point = random_enemy:GetAbsOrigin()
		end
	end

	for i = 1, self.ability.meteors_per_tick do
		local meteor = ParticleManager:CreateParticle("particles/units/heroes/hero_invoker/invoker_chaos_meteor_fly.vpcf", PATTACH_CUSTOMORIGIN, self.caster)
		ParticleManager:SetParticleControl(meteor, 0, point + Vector(0, 0, 500))
		ParticleManager:SetParticleControl(meteor, 1, point)
		ParticleManager:SetParticleControl(meteor, 2, Vector(1.2, 0, 0))

		local warning = ParticleManager:CreateParticle("particles/econ/events/darkmoon_2017/darkmoon_generic_aoe.vpcf", PATTACH_CUSTOMORIGIN, self.caster)
		ParticleManager:SetParticleControl(warning, 0, point)
		ParticleManager:SetParticleControl(warning, 1, Vector(self.radius_explosion, 0, 0))
		ParticleManager:SetParticleControl(warning, 2, Vector(6, 0, 1))
		ParticleManager:SetParticleControl(warning, 3, Vector(200, 0, 0))
		ParticleManager:SetParticleControl(warning, 4, point)

		local unit = CreateUnitByName("dummy_unit_invulnerable", point, true, nil, nil, self.caster:GetTeamNumber())
		unit:EmitSound("Hero_Invoker.ChaosMeteor.Loop")
		unit:AddNewModifier(self.caster, self.ability, "modifier_balanar_rain_of_chaos_dummy", { duration = self.ability.interval })
	end
end

function modifier_balanar_rain_of_chaos:GetModifierIncomingDamage_Percentage()
	if self.ability.damage_reduction then
		return self.ability.damage_reduction * (-1)
	end
end

modifier_balanar_rain_of_chaos_dummy = modifier_balanar_rain_of_chaos_dummy or class({})

function modifier_balanar_rain_of_chaos_dummy:IsHidden() return true end

function modifier_balanar_rain_of_chaos_dummy:IsPurgable() return false end

function modifier_balanar_rain_of_chaos_dummy:OnCreated()
	if not IsServer() then return end

	self.caster = self:GetCaster()
	self.parent = self:GetParent()
	self.ability = self:GetAbility()

	-- self:StartIntervalThink(0.1)
end

-- function modifier_balanar_rain_of_chaos_dummy:OnIntervalThink()

-- end

function modifier_balanar_rain_of_chaos_dummy:OnDestroy()
	if not IsServer() then return end

	self.parent:EmitSound("Hero_Invoker.ChaosMeteor.Impact")
	self.parent:StopSound("Hero_Invoker.ChaosMeteor.Loop")

	local enemies = FindUnitsInRadius(self.parent:GetTeamNumber(), self.parent:GetAbsOrigin(), nil, self.ability.radius_explosion, self.ability:GetAbilityTargetTeam(), self.ability:GetAbilityTargetType(), self.ability:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)

	for _, enemy in pairs(enemies) do
		ApplyDamage({
			victim = enemy,
			attacker = self.caster,
			damage = self.ability.damage,
			damage_type = self.ability:GetAbilityDamageType(),
			ability = self.ability
		})

		enemy:AddNewModifier(self.parent, self.ability, "modifier_stunned", { duration = self.ability.stun_duration })
	end

	local soil = ParticleManager:CreateParticle("particles/units/heroes/hero_invoker/invoker_chaos_meteor_land_soil.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(soil, 3, self.parent:GetAbsOrigin() + Vector(0, 0, 40))

	local crumble = ParticleManager:CreateParticle("particles/units/heroes/hero_invoker/invoker_chaos_meteor_crumble.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(crumble, 3, self.parent:GetAbsOrigin())

	-- only balanar boss should spawn golems
	if self.ability.golem_duration and self.ability.golem_duration > 0 then
		local unit = CreateUnitByName("npc_infernal_beast", self.parent:GetAbsOrigin(), true, caster, caster, self.parent:GetTeamNumber())
		unit:AddNewModifier(unit, nil, "modifier_kill", { duration = self.ability.duration })
	end

	if self.parent then
		self.parent:RemoveSelf()
	end
end
