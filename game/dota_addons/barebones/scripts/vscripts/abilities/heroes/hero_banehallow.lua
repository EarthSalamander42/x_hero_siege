function DeathCoil(keys)
local caster = keys.caster

	StartAnimation(caster, {duration=1.2, activity=ACT_DOTA_ATTACK, rate=1.25})
end

function create_projectile(keys)
local caster = keys.caster
local ability = keys.ability
local EffectKV = keys.EffectKV
local distance = ability:GetLevelSpecialValueFor("distance", ability:GetLevel()-1)
local speed = ability:GetLevelSpecialValueFor("speed", ability:GetLevel()-1)
local radius_skulls = ability:GetLevelSpecialValueFor("radius_skulls", ability:GetLevel()-1)
local radius = ability:GetLevelSpecialValueFor("radius", ability:GetLevel()-1)
local point = caster:GetAbsOrigin()
local skulls_per_tick = ability:GetLevelSpecialValueFor("skulls_per_tick", ability:GetLevel()-1)
local vector_line = caster:GetForwardVector():Cross(Vector(0,0,1))
vector_line = vector_line:Normalized()

	for j = 1, skulls_per_tick do
		local info = 
		{
			Ability = ability,
			EffectName = EffectKV,
			vSpawnOrigin = point-(distance/2.0)*caster:GetForwardVector() + (RandomInt(-radius/2.0, radius/2.0)) * vector_line,
			fDistance = distance,
			fStartRadius = radius_skulls,
			fEndRadius = radius_skulls,
			Source = caster,
			bHasFrontalCone = false,
			bReplaceExisting = false,
			iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
			iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_NONE,
			iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			fExpireTime = GameRules:GetGameTime() + 10.0,
			bDeleteOnHit = true,
			vVelocity = caster:GetForwardVector() * speed,
			bProvidesVision = false,
		}
		ProjectileManager:CreateLinearProjectile(info)
	end
end
