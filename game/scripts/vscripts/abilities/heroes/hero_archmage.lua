LinkLuaModifier("modifier_holdout_mana_shield", "abilities/heroes/hero_archmage.lua", LUA_MODIFIER_MOTION_NONE)

holdout_mana_shield = holdout_mana_shield or class({})

function holdout_mana_shield:ProcsMagicStick()
	return false
end

function holdout_mana_shield:OnToggle()
	if not IsServer() then return end

	local caster = self:GetCaster()
	if not caster or caster:IsNull() then return end

	if self:GetToggleState() then
		caster:EmitSound("Hero_Medusa.ManaShield.On")
		caster:AddNewModifier(caster, self, "modifier_holdout_mana_shield", {})
	else
		caster:EmitSound("Hero_Medusa.ManaShield.Off")
		caster:RemoveModifierByNameAndCaster("modifier_holdout_mana_shield", caster)
	end
end

modifier_holdout_mana_shield = modifier_holdout_mana_shield or class({})

function modifier_holdout_mana_shield:IsPurgable() return false end
function modifier_holdout_mana_shield:RemoveOnDeath() return false end
function modifier_holdout_mana_shield:GetTexture() return "custom/holdout_mana_shield" end
function modifier_holdout_mana_shield:GetEffectName() return "particles/units/heroes/hero_medusa/medusa_mana_shield.vpcf" end
function modifier_holdout_mana_shield:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

local function SpendManaShieldMana(unit, mana, ability)
	if not unit or unit:IsNull() or mana <= 0 then return end

	if unit.SpendMana then
		unit:SpendMana(mana, ability)
	elseif unit.SetMana and unit.GetMana then
		unit:SetMana(math.max(0, unit:GetMana() - mana))
	end
end

function modifier_holdout_mana_shield:OnCreated()
	local ability = self:GetAbility()
	if not ability or ability:IsNull() then return end

	self.damage_per_mana = ability:GetSpecialValueFor("damage_per_mana")
	self.absorption_pct = ability:GetSpecialValueFor("absorption_tooltip")
end

function modifier_holdout_mana_shield:OnRefresh()
	self:OnCreated()
end

function modifier_holdout_mana_shield:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
	}
end

function modifier_holdout_mana_shield:GetModifierIncomingDamage_Percentage(keys)
	if not IsServer() then return 0 end
	if not keys then return 0 end

	local parent = self:GetParent()
	local ability = self:GetAbility()
	if not parent or parent:IsNull() or not ability or ability:IsNull() then return 0 end
	if keys.target and keys.target ~= parent then return 0 end
	if keys.damage_type == DAMAGE_TYPE_MAGICAL and parent:IsMagicImmune() then return 0 end

	local damage = keys.original_damage or keys.damage or 0
	if damage <= 0 then return 0 end

	local damage_per_mana = self.damage_per_mana or ability:GetSpecialValueFor("damage_per_mana")
	local absorption_pct = self.absorption_pct or ability:GetSpecialValueFor("absorption_tooltip")
	if damage_per_mana <= 0 or absorption_pct <= 0 then return 0 end

	local current_mana = parent:GetMana()
	if current_mana <= 0 then
		self:DisableShield()
		return 0
	end

	local desired_block = damage * absorption_pct * 0.01
	local available_block = current_mana * damage_per_mana
	local blocked_damage = math.min(desired_block, available_block)
	if blocked_damage <= 0 then return 0 end

	local mana_spent = blocked_damage / damage_per_mana
	SpendManaShieldMana(parent, mana_spent, ability)
	parent:EmitSound("Hero_Medusa.ManaShield.Proc")

	local shield_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_medusa/medusa_mana_shield_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
	ParticleManager:ReleaseParticleIndex(shield_particle)

	if parent:GetMana() <= 0 then
		self:DisableShield()
	end

	return -blocked_damage / damage * 100
end

function modifier_holdout_mana_shield:DisableShield()
	if not IsServer() then return end

	local ability = self:GetAbility()
	if ability and not ability:IsNull() and ability:GetToggleState() then
		ability:ToggleAbility()
	else
		self:Destroy()
	end
end

function march_of_the_machines_spawn( keys )
local caster = keys.caster
local ability = keys.ability
local casterLoc = caster:GetAbsOrigin()
local targetLoc = keys.target_points[1]
local duration = ability:GetLevelSpecialValueFor( "duration", ability:GetLevel() - 1 )
local distance = ability:GetLevelSpecialValueFor( "distance", ability:GetLevel() - 1 )
local radius = ability:GetLevelSpecialValueFor( "radius", ability:GetLevel() - 1 )
local collision_radius = ability:GetLevelSpecialValueFor( "collision_radius", ability:GetLevel() - 1 )
local projectile_speed = ability:GetLevelSpecialValueFor( "speed", ability:GetLevel() - 1 )
local machines_per_sec = ability:GetLevelSpecialValueFor ( "machines_per_sec", ability:GetLevel() - 1 )
local dummyModifierName = "modifier_march_of_the_machines_dummy_datadriven"
	
	-- Find forward vector
	local forwardVec = targetLoc - casterLoc
	forwardVec = forwardVec:Normalized()
	
	-- Find backward vector
	local backwardVec = casterLoc - targetLoc
	backwardVec = backwardVec:Normalized()
	
	-- Find middle point of the spawning line
	local middlePoint = casterLoc + ( radius * backwardVec )

	-- Find perpendicular vector
	local v = middlePoint - casterLoc
	local dx = -v.y
	local dy = v.x
	local perpendicularVec = Vector( dx, dy, v.z )
	perpendicularVec = perpendicularVec:Normalized()
	
	-- Create dummy to store data in case of multiple instances are called
	local dummy = CreateUnitByName( "npc_dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber() )
	ability:ApplyDataDrivenModifier( caster, dummy, dummyModifierName, {} )
	dummy.march_of_the_machines_num = 0
	
	-- Create timer to spawn projectile
	Timers:CreateTimer( function()
		-- Get random location for projectile
		local random_distance = RandomInt( -radius, radius )
		local spawn_location = middlePoint + perpendicularVec * random_distance
		
		local velocityVec = Vector( forwardVec.x, forwardVec.y, 0 )

		-- Spawn projectiles
		local projectileTable = {
			Ability = ability,
			EffectName = "particles/units/heroes/hero_morphling/morphling_waveform.vpcf",
			vSpawnOrigin = spawn_location,
			fDistance = distance,
			fStartRadius = collision_radius,
			fEndRadius = collision_radius,
			Source = caster,
			bHasFrontalCone = false,
			bReplaceExisting = false,
			bProvidesVision = false,
			iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
			iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			vVelocity = velocityVec * projectile_speed
		}
		ProjectileManager:CreateLinearProjectile( projectileTable )
		
		-- Increment the counter
		dummy.march_of_the_machines_num = dummy.march_of_the_machines_num + 1
		
		-- Check if the number of machines have been reached
		if dummy.march_of_the_machines_num == machines_per_sec * duration then
			dummy:Destroy()
			return nil
		else
			return 1 / machines_per_sec
		end
	end)
end

function RainOfIce( event )
local caster = event.target
local ability = event.ability
local radius = ability:GetLevelSpecialValueFor("radius", ability:GetLevel() -1)
local radius_explosion = ability:GetLevelSpecialValueFor("radius_explosion", ability:GetLevel() -1)
local damage_per_unit = ability:GetLevelSpecialValueFor("damage_per_unit", ability:GetLevel() -1)
local stun_duration = ability:GetLevelSpecialValueFor("stun_duration", ability:GetLevel() -1)
local explosions_per_tick = ability:GetLevelSpecialValueFor("explosions_per_tick", ability:GetLevel() -1)
local delay = ability:GetLevelSpecialValueFor("delay", ability:GetLevel() -1)

	StartAnimation(caster, {duration = 1.0, activity = ACT_DOTA_CAST_ABILITY_1, rate = 1.0})

	for i = 1, explosions_per_tick do
		local point = caster:GetAbsOrigin() + RandomInt(1,radius-(math.floor(radius_explosion/2.0)))*RandomVector(1)
		local units = FindUnitsInRadius(caster:GetTeam(), point, nil, radius_explosion, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO , DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
		for _,unit in pairs(units) do
			Timers:CreateTimer( delay,function () ApplyDamage({victim = unit, attacker = caster, damage = damage_per_unit, damage_type = DAMAGE_TYPE_MAGICAL})
			unit:AddNewModifier(caster, nil, "modifier_stunned", {duration = stun_duration})
			end)
		end

		local moonstrike = ParticleManager:CreateParticle("particles/custom/human/blood_mage/invoker_sun_strike_team_immortal2.vpcf",PATTACH_CUSTOMORIGIN,caster)
		ParticleManager:SetParticleControl(moonstrike, 0, point)

		local moontrike_inner = ParticleManager:CreateParticle("particles/econ/items/crystal_maiden/crystal_maiden_maiden_of_icewrack/maiden_freezing_field_cracks_arcana.vpcf",PATTACH_CUSTOMORIGIN,caster)
		ParticleManager:SetParticleControl(moontrike_inner, 0, point)

		local moonstrike_outer = ParticleManager:CreateParticle("particles/econ/items/crystal_maiden/crystal_maiden_maiden_of_icewrack/maiden_freezing_field_darkcore_arcana1.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(moonstrike_outer, 0, point)
		ParticleManager:SetParticleControl(moonstrike_outer, 2, Vector(11,0,0))

		Timers:CreateTimer(delay - 0.1, function()
			local moonstrike = ParticleManager:CreateParticle("particles/econ/items/crystal_maiden/crystal_maiden_maiden_of_icewrack/maiden_freezing_field_explosion_arcana1.vpcf", PATTACH_CUSTOMORIGIN, caster)
			ParticleManager:SetParticleControl(moonstrike, 0, point)
			caster:EmitSound("Hero_Invoker.SunStrike.Ignite")
		end)
	end
end
