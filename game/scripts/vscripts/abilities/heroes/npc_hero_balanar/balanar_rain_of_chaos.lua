LinkLuaModifier("modifier_balanar_rain_of_chaos", "abilities/heroes/npc_hero_balanar/balanar_rain_of_chaos.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_balanar_rain_of_chaos_dummy", "abilities/heroes/npc_hero_balanar/balanar_rain_of_chaos.lua", LUA_MODIFIER_MOTION_NONE)

balanar_rain_of_chaos = balanar_rain_of_chaos or class({})
holdout_rain_of_chaos = balanar_rain_of_chaos
holdout_rain_of_chaos_20 = balanar_rain_of_chaos

local METEOR_FLY_PARTICLE = "particles/units/heroes/hero_invoker/invoker_chaos_meteor_fly.vpcf"
local METEOR_WARNING_PARTICLE = "particles/custom/boss_warnings/balanar/radius.vpcf"
local METEOR_IMPACT_PARTICLE = "particles/units/heroes/hero_invoker/invoker_chaos_meteor_land_soil.vpcf"
local METEOR_CRUMBLE_PARTICLE = "particles/units/heroes/hero_invoker/invoker_chaos_meteor_crumble.vpcf"
local WARNING_LIFETIME = 1.2
local METEOR_WARNING_COLOR = Vector(155, 55, 255)

function balanar_rain_of_chaos:OnSpellStart()
	local caster = self:GetCaster()

	self.radius = self:GetSpecialValueFor("radius")
	self.radius_explosion = self:GetSpecialValueFor("radius_explosion")
	self.meteors_per_tick = self:GetSpecialValueFor("meteors_per_tick")
	self.unit_per_meteor = self:GetSpecialValueFor("unit_per_meteor")
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
modifier_balanar_rain_of_chaos.XHS_LINK_CLIENT = true

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
	if self.caster == nil or self.caster:IsNull() or self.ability == nil or self.ability:IsNull() then
		self:Destroy()
		return
	end

	self:StartIntervalThink(self.ability.interval)
end

function modifier_balanar_rain_of_chaos:OnIntervalThink()
	if self.caster == nil or self.caster:IsNull() or self.ability == nil or self.ability:IsNull() then
		return
	end

	local points = {}
	local unitPerMeteor = tonumber(self.ability.unit_per_meteor) or 0

	if unitPerMeteor > 0 then
		unitPerMeteor = math.max(1, math.floor(unitPerMeteor))
		local heroes = FindUnitsInRadius(
			self.caster:GetTeamNumber(),
			self.caster:GetAbsOrigin(),
			nil,
			self.ability.seek_radius,
			DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO,
			self.ability:GetAbilityTargetFlags(),
			FIND_ANY_ORDER,
			false
		)

		for index, hero in ipairs(heroes) do
			if hero ~= nil and not hero:IsNull() and hero:IsAlive() and ((index - 1) % unitPerMeteor) == 0 then
				points[#points + 1] = hero:GetAbsOrigin()
			end
		end
	else
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

		if point == nil then
			point = self.caster:GetAbsOrigin() + RandomInt(200, self.ability.radius) * RandomVector(1)
		end

		for i = 1, math.max(1, self.ability.meteors_per_tick or 1) do
			points[#points + 1] = point
		end
	end

	if #points == 0 then
		points[1] = self.caster:GetAbsOrigin() + RandomInt(200, self.ability.radius) * RandomVector(1)
	end

	for _, point in ipairs(points) do
		local meteor = ParticleManager:CreateParticle(METEOR_FLY_PARTICLE, PATTACH_CUSTOMORIGIN, self.caster)
		ParticleManager:SetParticleControl(meteor, 0, point + Vector(0, 0, 500))
		ParticleManager:SetParticleControl(meteor, 1, point)
		ParticleManager:SetParticleControl(meteor, 2, Vector(1.2, 0, 0))
		ParticleManager:ReleaseParticleIndex(meteor)

		local warning = ParticleManager:CreateParticle(METEOR_WARNING_PARTICLE, PATTACH_CUSTOMORIGIN, self.caster)
		ParticleManager:SetParticleControl(warning, 0, point)
		ParticleManager:SetParticleControl(warning, 1, Vector(self.ability.radius_explosion, WARNING_LIFETIME, 0))
		ParticleManager:SetParticleControl(warning, 15, METEOR_WARNING_COLOR)
		ParticleManager:SetParticleControl(warning, 16, Vector(1, 0, 0))
		Timers:CreateTimer(WARNING_LIFETIME + 0.1, function()
			ParticleManager:DestroyParticle(warning, false)
			ParticleManager:ReleaseParticleIndex(warning)
			return nil
		end)

		local unit = CreateUnitByName("dummy_unit_invulnerable", point, true, nil, nil, self.caster:GetTeamNumber())
		if unit == nil or unit:IsNull() then
			return
		end

		unit:EmitSound("Hero_Invoker.ChaosMeteor.Loop")
		unit:AddNewModifier(self.caster, self.ability, "modifier_balanar_rain_of_chaos_dummy", { duration = self.ability.interval })
	end
end

function modifier_balanar_rain_of_chaos:GetModifierIncomingDamage_Percentage()
	if self.ability and self.ability.damage_reduction then
		return self.ability.damage_reduction * (-1)
	end
end

modifier_balanar_rain_of_chaos_dummy = modifier_balanar_rain_of_chaos_dummy or class({})
modifier_balanar_rain_of_chaos_dummy.XHS_LINK_CLIENT = true

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

	local parent = self.parent
	local caster = self.caster
	local ability = self.ability
	if parent == nil or parent:IsNull() or ability == nil or ability:IsNull() then
		return
	end
	local attacker = caster
	if attacker == nil or attacker:IsNull() then
		attacker = parent
	end

	parent:EmitSound("Hero_Invoker.ChaosMeteor.Impact")
	parent:StopSound("Hero_Invoker.ChaosMeteor.Loop")

	local enemies = FindUnitsInRadius(parent:GetTeamNumber(), parent:GetAbsOrigin(), nil, ability.radius_explosion, ability:GetAbilityTargetTeam(), ability:GetAbilityTargetType(), ability:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)

	for _, enemy in pairs(enemies) do
		if enemy ~= nil and not enemy:IsNull() then
			enemy:AddNewModifier(parent, ability, "modifier_stunned", { duration = ability.stun_duration })
		end

		if enemy ~= nil and not enemy:IsNull() then
			ApplyDamage({
				victim = enemy,
				attacker = attacker,
				damage = ability.damage,
				damage_type = ability:GetAbilityDamageType(),
				ability = ability
			})
		end
	end

	local soil = ParticleManager:CreateParticle(METEOR_IMPACT_PARTICLE, PATTACH_CUSTOMORIGIN, attacker)
	ParticleManager:SetParticleControl(soil, 3, parent:GetAbsOrigin() + Vector(0, 0, 40))
	ParticleManager:ReleaseParticleIndex(soil)

	local crumble = ParticleManager:CreateParticle(METEOR_CRUMBLE_PARTICLE, PATTACH_CUSTOMORIGIN, attacker)
	ParticleManager:SetParticleControl(crumble, 3, parent:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(crumble)

	-- only balanar boss should spawn golems
	if ability.golem_duration and ability.golem_duration > 0 then
		local unit = CreateUnitByName("npc_infernal_beast", parent:GetAbsOrigin(), true, attacker, attacker, parent:GetTeamNumber())
		if unit ~= nil and not unit:IsNull() then
			unit:AddNewModifier(unit, nil, "modifier_kill", { duration = ability.duration })
		end
	end

	if parent then
		parent:RemoveSelf()
	end
end
