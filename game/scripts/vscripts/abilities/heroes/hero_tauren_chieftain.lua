LinkLuaModifier("modifier_holdout_pulverize", "abilities/heroes/hero_tauren_chieftain.lua", LUA_MODIFIER_MOTION_NONE)

holdout_pulverize = holdout_pulverize or class({})
modifier_holdout_pulverize = modifier_holdout_pulverize or class({})
modifier_holdout_pulverize.XHS_LINK_CLIENT = true

local PULVERIZE_PARTICLE = "particles/units/heroes/hero_brewmaster/brewmaster_pulverize.vpcf"
local PULVERIZE_SOUND = "Hero_EarthShaker.Aftershock"

function holdout_pulverize:GetIntrinsicModifierName()
	return "modifier_holdout_pulverize"
end

function modifier_holdout_pulverize:IsHidden() return true end
function modifier_holdout_pulverize:IsPurgable() return false end
function modifier_holdout_pulverize:RemoveOnDeath() return false end

function modifier_holdout_pulverize:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ABILITY_FULLY_CAST,
	}
end

function modifier_holdout_pulverize:OnAbilityFullyCast(event)
	if not IsServer() then return end

	local parent = self:GetParent()
	local ability = self:GetAbility()
	local castAbility = event.ability
	if event.unit ~= parent or ability == nil or castAbility == nil then return end
	if castAbility == ability or castAbility:IsItem() or castAbility:IsToggle() then return end
	if parent:PassivesDisabled() or ability:GetLevel() <= 0 then return end

	local behavior = tonumber(tostring(castAbility:GetBehavior())) or 0
	if bit.band(behavior, DOTA_ABILITY_BEHAVIOR_PASSIVE) ~= 0 then return end

	self:TriggerPulverize()
end

function modifier_holdout_pulverize:TriggerPulverize()
	local parent = self:GetParent()
	local ability = self:GetAbility()
	if ability == nil then return end

	local radius = ability:GetSpecialValueFor("aftershock_range")
	local damage = ability:GetSpecialValueFor("aftershock_damage")
	local duration = ability:GetDuration()
	local enemies = FindUnitsInRadius(
		parent:GetTeamNumber(),
		parent:GetAbsOrigin(),
		nil,
		radius,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_ANY_ORDER,
		false
	)

	for _, enemy in pairs(enemies) do
		if enemy ~= nil and not enemy:IsNull() and enemy:IsAlive() and not enemy:IsInvulnerable() then
			ApplyDamage({
				victim = enemy,
				attacker = parent,
				ability = ability,
				damage = damage,
				damage_type = DAMAGE_TYPE_MAGICAL,
			})
			enemy:AddNewModifier(parent, ability, "modifier_stunned", {
				duration = duration,
			})
		end
	end

	local particle = ParticleManager:CreateParticle(PULVERIZE_PARTICLE, PATTACH_ABSORIGIN_FOLLOW, parent)
	ParticleManager:SetParticleControl(particle, 1, Vector(radius, radius, radius))
	ParticleManager:ReleaseParticleIndex(particle)
	parent:EmitSound(PULVERIZE_SOUND)
end
