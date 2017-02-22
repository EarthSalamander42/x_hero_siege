--[[
    CHANGELIST:
    10.01.2015 - Delete unnecessary parameter to avoid confusion
]]

--[[
    Author: kritth
    Date: 10.01.2015
    Find necessary vectors, and spawn spawning until units cap is reached
]]
function march_of_the_machines_spawn( keys )
    -- Variables
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
        end
    )
end

function LifeDrainParticle( event)
    local caster = event.caster
    local target = event.target
    local ability = event.ability

    local particleName = "particles/units/heroes/hero_pugna/pugna_life_drain.vpcf"
    caster.LifeDrainParticle = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControlEnt(caster.LifeDrainParticle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)

    local particleName2 = "particles/units/heroes/hero_lion/lion_spell_mana_drain.vpcf"
    caster.LifeDrainParticle2 = ParticleManager:CreateParticle(particleName2, PATTACH_ABSORIGIN_FOLLOW, caster)
    ParticleManager:SetParticleControlEnt(caster.LifeDrainParticle2, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
end

function LifeDrainHealthTransfer( event )
    local caster = event.caster
    local target = event.target
    local ability = event.ability

    local health_drain = ability:GetLevelSpecialValueFor( "health_drain" , ability:GetLevel() - 1 )
    local tick_rate = ability:GetLevelSpecialValueFor( "tick_rate" , ability:GetLevel() - 1 )
    local HP_drain = health_drain * tick_rate

    -- HP drained depends on the actual damage dealt. This is for MAGICAL damage type
    local HP_gain = HP_drain * ( 1 - target:GetMagicalArmorValue())

    print(HP_drain,target:GetMagicalArmorValue(),HP_gain)

    -- Act according to the targets team
    local targetTeam = target:GetTeamNumber()
    local casterTeam = caster:GetTeamNumber()

    -- If its an illusion then kill it
    if target:IsIllusion() then
        target:ForceKill(true)
        ability:OnChannelFinish(false)
        caster:Stop()
        return
    else
        -- Location variables
        local caster_location = caster:GetAbsOrigin()
        local target_location = target:GetAbsOrigin()

        -- Distance variables
        local distance = (target_location - caster_location):Length2D()
        local break_distance = ability:GetCastRange()
        local direction = (target_location - caster_location):Normalized()

        -- If the leash is broken then stop the channel
        if distance >= break_distance then
            ability:OnChannelFinish(false)
            caster:Stop()
            return
        end

        -- Make sure that the caster always faces the target
        caster:SetForwardVector(direction)
    end

    if caster:GetHealthDeficit() > 0 then
        -- Health Transfer Enemy->Caster
        ApplyDamage({ victim = target, attacker = caster, damage = HP_drain, damage_type = DAMAGE_TYPE_MAGICAL })
        caster:Heal( HP_gain, caster )
        caster:GiveMana( HP_gain )

        -- Set the particle control color as green
        ParticleManager:SetParticleControl(caster.LifeDrainParticle, 10, Vector(0,0,0))
        ParticleManager:SetParticleControl(caster.LifeDrainParticle, 11, Vector(0,0,0))
    end
end

function LifeDrainParticleEnd( event )
    local caster = event.caster
    ParticleManager:DestroyParticle(caster.LifeDrainParticle,false)
    ParticleManager:DestroyParticle(caster.LifeDrainParticle2,false)
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
