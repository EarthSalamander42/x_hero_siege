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
