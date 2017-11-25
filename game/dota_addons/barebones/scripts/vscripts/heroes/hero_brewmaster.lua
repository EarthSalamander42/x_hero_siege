if xhs_brewmaster_drunken_haze == nil then xhs_brewmaster_drunken_haze = class({}) end

function xhs_brewmaster_drunken_haze:GetAbilityTextureName()
   return "brewmaster_drunken_haze"
end

function xhs_brewmaster_drunken_haze:GetBehavior()
	return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET end

function xhs_brewmaster_drunken_haze:OnSpellStart()
	local projectile = {
		Target = self:GetCursorTarget(),
		Source = self:GetCaster(),
		Ability = self,
		EffectName = "particles/units/heroes/hero_brewmaster/brewmaster_drunken_haze.vpcf",
		bDodgable = true,
		bProvidesVision = false,
		iMoveSpeed = self:GetSpecialValueFor("projectile_speed"),
		iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_HITLOCATION,
	}
	EmitSoundOn("Hero_Brewmaster.DrunkenHaze.Cast", self:GetCaster())
	ProjectileManager:CreateTrackingProjectile(projectile)
end

function xhs_brewmaster_drunken_haze:OnProjectileHit(target, location)
	if target:TriggerSpellAbsorb(self) then return end
	
	EmitSoundOn("Hero_Brewmaster.DrunkenHaze.Target", target)

	local units = FindUnitsInRadius(self:GetCaster():GetTeamNumber(), target:GetAbsOrigin(), nil, self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for _, unit in pairs(units) do
		unit:AddNewModifier(self:GetCaster(), self, "modifier_xhs_brewmaster_drunken_haze_debuff", {duration = self:GetSpecialValueFor("duration")})
	end
end

-----------------------------------------------

LinkLuaModifier( "modifier_xhs_brewmaster_drunken_haze_debuff", "heroes/hero_brewmaster.lua", LUA_MODIFIER_MOTION_NONE )
if modifier_xhs_brewmaster_drunken_haze_debuff == nil then modifier_xhs_brewmaster_drunken_haze_debuff = class({}) end
function modifier_xhs_brewmaster_drunken_haze_debuff:IsPurgable() return true end
function modifier_xhs_brewmaster_drunken_haze_debuff:IsHidden() return false end
function modifier_xhs_brewmaster_drunken_haze_debuff:IsDebuff() return true end
function modifier_xhs_brewmaster_drunken_haze_debuff:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_xhs_brewmaster_drunken_haze_debuff:GetTexture()
	return "brewmaster_drunken_haze"
end

function modifier_xhs_brewmaster_drunken_haze_debuff:GetEffectName()
	return "particles/units/heroes/hero_brewmaster/brewmaster_drunken_haze_debuff.vpcf"
end

function modifier_xhs_brewmaster_drunken_haze_debuff:GetStatusEffectName()
	return "particles/status_fx/status_effect_brewmaster_drunken_haze.vpcf"
end

function modifier_xhs_brewmaster_drunken_haze_debuff:StatusEffectPriority()
	return 5
end

function modifier_xhs_brewmaster_drunken_haze_debuff:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_xhs_brewmaster_drunken_haze_debuff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_MISS_PERCENTAGE,
	}
	return funcs
end

function modifier_xhs_brewmaster_drunken_haze_debuff:GetModifierMiss_Percentage()
	return self:GetAbility():GetSpecialValueFor("miss_chance")
end

function modifier_xhs_brewmaster_drunken_haze_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("movement_slow")
end

-----------------------------------------

LinkLuaModifier( "modifier_xhs_brewmaster_drunken_haze_burn", "heroes/hero_brewmaster.lua", LUA_MODIFIER_MOTION_NONE )
if modifier_xhs_brewmaster_drunken_haze_burn == nil then modifier_xhs_brewmaster_drunken_haze_burn = class({}) end
function modifier_xhs_brewmaster_drunken_haze_burn:IsPurgable() return true end
function modifier_xhs_brewmaster_drunken_haze_burn:IsHidden() return false end
function modifier_xhs_brewmaster_drunken_haze_burn:IsDebuff() return true end
function modifier_xhs_brewmaster_drunken_haze_burn:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_xhs_brewmaster_drunken_haze_burn:GetTexture()
	return "custom/holdout_dragon_slave"
end

function modifier_xhs_brewmaster_drunken_haze_burn:GetEffectName()
	return "particles/econ/items/wraith_king/wraith_king_ti6_bracer/wraith_king_ti6_hellfireblast_debuff.vpcf"
end

function modifier_xhs_brewmaster_drunken_haze_burn:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_xhs_brewmaster_drunken_haze_burn:OnCreated()
	if IsServer() then
		self:StartIntervalThink(1.0)
	end
end

function modifier_xhs_brewmaster_drunken_haze_burn:OnIntervalThink()
	ApplyDamage({ victim = self:GetParent(), attacker = self:GetCaster(), damage = self:GetCaster():FindAbilityByName("xhs_brewmaster_drunken_haze"):GetSpecialValueFor("burn_damage"), ability = self:GetAbility(), damage_type = DAMAGE_TYPE_MAGICAL })
end

-----------------------------------------

function DragonSlaveBurn(keys)
local caster = keys.caster
local target = keys.target
local ability = keys.ability

	if target:HasModifier("modifier_xhs_brewmaster_drunken_haze_debuff") then --Apply normal damage + burn damage over 5 seconds
		ability:ApplyDataDrivenModifier(caster, target, "modifier_xhs_brewmaster_drunken_haze_burn", {duration = caster:FindAbilityByName("xhs_brewmaster_drunken_haze"):GetSpecialValueFor("burn_duration")})
	elseif not target:HasModifier("modifier_xhs_brewmaster_drunken_haze_debuff") then
		return
	end
end

--------------------------------

-- Creates a dummy unit to apply the Earthquake aura
function EarthquakeStart( event )
	local ability = event.ability
	local caster = event.caster
	local point = event.target_points[1]

	caster.earthquake_dummy = CreateUnitByName("dummy_unit_vulnerable", point, false, caster, caster, caster:GetTeam())
	caster.earthquake_dummy:AddNewModifier(caster, ability, "modifier_earthquake_aura", {})

	caster:EmitSound("Hero_Leshrac.Split_Earth")
	Timers:CreateTimer(0.5, function()
		if ability:IsChanneling() then
			caster:StartGesture(ACT_DOTA_KINETIC_FIELD)
			return 1
		end
	end)
end

function EarthquakeEnd( event )
	local caster = event.caster
	if IsValidEntity(caster.earthquake_dummy) then
		caster:RemoveGesture(ACT_DOTA_KINETIC_FIELD)
		caster.earthquake_dummy:ForceKill(true)
	end
end

------------------------------------------------

modifier_earthquake_aura = class({})

LinkLuaModifier("modifier_earthquake", "heroes/hero_brewmaster", LUA_MODIFIER_MOTION_NONE)

function modifier_earthquake_aura:OnCreated()
	if IsServer() then
		self:PlayParticleEffect()
		self:StartIntervalThink(1)
	end
end

function modifier_earthquake_aura:OnIntervalThink()
	if self:GetAbility():IsChanneling() then
		self:PlayParticleEffect() 
		self:GetParent():EmitSound("Hero_Leshrac.Split_Earth")   
	end
end

function modifier_earthquake_aura:PlayParticleEffect()
	local radius = self:GetAbility():GetSpecialValueFor("radius")
	self.particle = ParticleManager:CreateParticle("particles/custom/orc/earthquake.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	ParticleManager:SetParticleControl(self.particle, 1, Vector(radius, radius, radius))
end

function modifier_earthquake_aura:IsAura() return true end
function modifier_earthquake_aura:IsHidden() return true end
function modifier_earthquake_aura:IsPurgable() return false end

function modifier_earthquake_aura:GetAuraRadius()
	return self:GetAbility():GetSpecialValueFor("radius")
end

function modifier_earthquake_aura:GetModifierAura()
	return "modifier_earthquake"
end
   
function modifier_earthquake_aura:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

--	function modifier_earthquake_aura:GetAuraEntityReject(target)
--		return target:IsWard() or target:IsFlyingUnit()
--	end

function modifier_earthquake_aura:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
end

function modifier_earthquake_aura:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_earthquake_aura:GetAuraDuration()
	return 0.5
end

--------------------------------------------------------------------------------

modifier_earthquake = class({})

function modifier_earthquake:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE }
end

function modifier_earthquake:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("movement_speed_slow_pct")
end

function modifier_earthquake:OnCreated()
	if IsServer() then
		self:DamageUnits()
		self:StartIntervalThink(1)
	end
end

function modifier_earthquake:OnIntervalThink()
	ApplyDamage({ victim = self:GetParent(), attacker = self:GetCaster(), damage = self:GetAbility():GetSpecialValueFor("damage_per_sec"), ability = self:GetAbility(), damage_type = DAMAGE_TYPE_MAGICAL })
end

function modifier_earthquake:DamageUnits()
	ApplyDamage({ victim = self:GetParent(), attacker = self:GetCaster(), damage = self:GetAbility():GetSpecialValueFor("damage_per_sec"), ability = self:GetAbility(), damage_type = DAMAGE_TYPE_MAGICAL })
end

function modifier_earthquake:IsPurgable() return false end
function modifier_earthquake:IsDebuff() return true end
