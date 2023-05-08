----------------------------------------------------------------
--------------------	  Chronosphere		--------------------
----------------------------------------------------------------
if creature_chronosphere == nil then creature_chronosphere = class({}) end

LinkLuaModifier("modifier_creature_chronosphere_aura", "abilities/heroes/hero_abaddon/chronosphere.lua",
	LUA_MODIFIER_MOTION_NONE)                                                                                                         -- Aura - Handle applier
LinkLuaModifier("modifier_creature_chronosphere_handler", "abilities/heroes/hero_abaddon/chronosphere.lua",
	LUA_MODIFIER_MOTION_NONE)                                                                                                         -- Handler

function creature_chronosphere:OnSpellStart()
	local caster = self:GetCaster()
	local chrono_center = caster:GetAbsOrigin()

	-- Parameters
	local base_radius = self:GetSpecialValueFor("base_radius")
	local duration = self:GetSpecialValueFor("duration")

	-- Create flying vision node
	AddFOWViewer(caster:GetTeamNumber(), chrono_center, base_radius, duration, false)

	-- Create the dummy and give it the chronosphere aura
	local mod = CreateModifierThinker(caster,
		self,
		"modifier_creature_chronosphere_aura",
		{ duration = duration },
		chrono_center,
		caster:GetTeamNumber(),
		false
	)

	caster:EmitSound("Hero_FacelessVoid.Chronosphere")
end

---------------------------------
-----	Chronosphere Aura	-----
---------------------------------

if modifier_creature_chronosphere_aura == nil then modifier_creature_chronosphere_aura = class({}) end

function modifier_creature_chronosphere_aura:IsPurgable() return false end

function modifier_creature_chronosphere_aura:IsHidden() return true end

function modifier_creature_chronosphere_aura:IsAura() return true end

function modifier_creature_chronosphere_aura:IsNetherWardStealable() return false end

function modifier_creature_chronosphere_aura:GetAuraDuration()
	return 0.1
end

function modifier_creature_chronosphere_aura:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_BOTH
end

function modifier_creature_chronosphere_aura:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

function modifier_creature_chronosphere_aura:GetAuraSearchType()
	return DOTA_UNIT_TARGET_CREEP + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BUILDING + DOTA_UNIT_TARGET_OTHER
end

function modifier_creature_chronosphere_aura:GetModifierAura()
	return "modifier_creature_chronosphere_handler"
end

function modifier_creature_chronosphere_aura:GetAuraRadius()
	return self.base_radius
end

-- "Faceless Void and illusions of him (be it his own, enemy or allied illusions) are never disabled by any Chronosphere."
function modifier_creature_chronosphere_aura:GetAuraEntityReject(target)
	if target == self:GetCaster() then
		return true
	end
end

function modifier_creature_chronosphere_aura:OnCreated()
	if IsServer() then
		self.caster = self:GetCaster()
		self.ability = self:GetAbility()
		self.parent = self:GetParent()
		self.base_radius = self.ability:GetSpecialValueFor("base_radius")

		local particle = ParticleManager:CreateParticle(
		"particles/units/heroes/hero_faceless_void/faceless_void_chronosphere_red.vpcf", PATTACH_WORLDORIGIN, self
		.parent, self.caster)
		ParticleManager:SetParticleControl(particle, 0, self.parent:GetAbsOrigin())
		ParticleManager:SetParticleControl(particle, 1, Vector(self.base_radius, self.base_radius, self.base_radius))
		self:AddParticle(particle, false, false, -1, false, false)
	end
end

-------------------------------------
-----	Chronosphere Handler	-----
-------------------------------------
if modifier_creature_chronosphere_handler == nil then modifier_creature_chronosphere_handler = class({}) end

function modifier_creature_chronosphere_handler:IsHidden() return true end

function modifier_creature_chronosphere_handler:IsPurgable() return false end

function modifier_creature_chronosphere_handler:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

-- Utilizes the stack system to work
--	0 stacks = Everything that doesn't fit under other categories
--	1 stacks = Caster or units under their control
--	2 stacks = Ally when caster has a scepter
--	3 stacks = Anyone who has the Timelord ability thats not the caster
--  4 stacks = Caster or units under thier control and this is a mini chrono

function modifier_creature_chronosphere_handler:IsDebuff()
	if self:GetStackCount() == 1 or self:GetStackCount() == 4 then
		return false
	end

	return true
end

function modifier_creature_chronosphere_handler:OnCreated()
	if IsServer() then
		self.parent = self:GetParent()
		self.caster = self:GetCaster()
		self.projectile_speed = self.parent:GetProjectileSpeed()

		if self.parent == self.caster or self.parent:GetPlayerOwner() == self.caster:GetPlayerOwner() then
			self:SetStackCount(1)
		end

		self:StartIntervalThink(FrameTime())
	end
end

function modifier_creature_chronosphere_handler:OnIntervalThink()
	if IsServer() then
		self.projectile_speed = 0
		self.projectile_speed = self.parent:GetProjectileSpeed()

		-- Normal frozen enemy gets interrupted all the time
		if self:GetStackCount() == 0 then
			-- Make certain people are stunned
			self.parent:AddNewModifier(self.caster, self:GetAbility(), "modifier_stunned", { duration = FrameTime() })

			-- Non-IMBA handling
			self.parent:InterruptMotionControllers(true)
		end
	end
end

function modifier_creature_chronosphere_handler:CheckState()
	return {
		[MODIFIER_STATE_FROZEN] = true,
		[MODIFIER_STATE_ROOTED] = true,
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_SILENCED] = true,
		[MODIFIER_STATE_INVISIBLE] = false,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true
	}
end

function modifier_creature_chronosphere_handler:GetPriority()
	return MODIFIER_PRIORITY_HIGH
end

function modifier_creature_chronosphere_handler:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT,
		MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE,
		MODIFIER_PROPERTY_CASTTIME_PERCENTAGE,
		MODIFIER_PROPERTY_PROJECTILE_SPEED_BONUS,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
	}
end

function modifier_creature_chronosphere_handler:GetModifierIgnoreMovespeedLimit()
	return true
end

-- #3 TALENT: Void gains infinite movement speed in Chrono
function modifier_creature_chronosphere_handler:GetModifierMoveSpeed_Absolute()
	return self:GetAbility():GetSpecialValueFor("movement_speed")
end
