LinkLuaModifier("modifier_voodoo_lua", "libraries/modifiers/modifier_voodoo_lua.lua", LUA_MODIFIER_MOTION_NONE)

function heat_seeking_missile_seek_targets( keys )
	-- Variables
	local caster            = keys.caster
	local ability           = keys.ability
	local particleName      = "particles/econ/items/phantom_assassin/phantom_assassin_arcana_elder_smith/phantom_assassin_stifling_dagger_arcana.vpcf"
	local modifierDudName   = "modifier_heat_seeking_missile_dud"
	local projectileSpeed   = ability:GetLevelSpecialValueFor( "speed", ability:GetLevel() - 1 )
	local radius            = ability:GetLevelSpecialValueFor( "radius", ability:GetLevel() - 1 )
	local max_targets       = ability:GetLevelSpecialValueFor( "targets", ability:GetLevel() - 1 )
	local targetTeam        = ability:GetAbilityTargetTeam()
	local targetType        = ability:GetAbilityTargetType()
	local targetFlag        = ability:GetAbilityTargetFlags() -- DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NO_INVIS + DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS
	local projectileDodgable = false
	local projectileProvidesVision = false

	-- pick up x nearest target heroes and create tracking projectile targeting the number of targets
	local units = FindUnitsInRadius(
	caster:GetTeamNumber(), caster:GetAbsOrigin(), caster, radius, targetTeam, targetType, targetFlag, FIND_CLOSEST, false)

	-- Seek out target
	local count = 0
	for k, v in pairs( units ) do
		if count < max_targets then
			local projTable = {
				Target = v,
				Source = caster,
				Ability = ability,
				EffectName = particleName,
				bDodgeable = projectileDodgable,
				bProvidesVision = projectileProvidesVision,
				iMoveSpeed = projectileSpeed, 
				vSpawnOrigin = caster:GetAbsOrigin()
			}
			ProjectileManager:CreateTrackingProjectile( projTable )
			count = count + 1
		else
			break
		end
	end

	-- If no unit is found, fire dud
	if count == 0 then
		ability:ApplyDataDrivenModifier( caster, caster, modifierDudName, {} )
	end
end

function Blink(keys)
local point = keys.target_points[1]
local caster = keys.caster
local casterPos = caster:GetAbsOrigin()
local pid = caster:GetPlayerID()
local difference = point - casterPos
local ability = keys.ability
local range = ability:GetLevelSpecialValueFor("blink_range", (ability:GetLevel() - 1))
	
	ProjectileManager:ProjectileDodge(caster)

	if difference:Length2D() > range then
		point = casterPos + (point - casterPos):Normalized() * range
	end

	FindClearSpaceForUnit(caster, point, false) 
end

function Morph( keys )
local caster = keys.caster
local ability = keys.ability
local ability_level = ability:GetLevel() - 1
local target = keys.target
local duration = ability:GetLevelSpecialValueFor("voodoo_duration", ability_level)

	if target:IsIllusion() then
		target:ForceKill(true)
	else
		target:AddNewModifier(caster, ability, "modifier_voodoo_lua", {duration = duration})
	end
end
