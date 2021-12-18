local dummy = nil

function modifier_start(event)
	dummy = event.target
end

function firestorm(event)
local caster = event.caster
local ability = event.ability
local units = FindUnitsInRadius(caster:GetTeamNumber(), dummy:GetAbsOrigin(), nil, ability:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO+DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)		

	local warning = ParticleManager:CreateParticle("particles/events/darkmoon_generic_aoe_green.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(warning, 0, dummy:GetAbsOrigin())
	ParticleManager:SetParticleControl(warning, 1, Vector(radius, 0, 0))
	ParticleManager:SetParticleControl(warning, 2, Vector(6, 0, 1))
	ParticleManager:SetParticleControl(warning, 3, Vector(200, 0, 0))
	ParticleManager:SetParticleControl(warning, 4, dummy:GetAbsOrigin())

	for _,v in pairs(units) do
		local damageTable = {
			victim = v,
			attacker = caster,
			damage = ability:GetSpecialValueFor("damage_per_tick"),
			damage_type = DAMAGE_TYPE_MAGICAL,
		}
 	
		ApplyDamage(damageTable)
		ability:ApplyDataDrivenModifier(caster, v, "modifier_firestorm_afterburn", nil)
	end
end

function ThunderClap(event)
local caster = event.caster
local ability = event.ability
local radius = ability:GetLevelSpecialValueFor("radius", ability:GetLevel()-1)

	local warning = ParticleManager:CreateParticle("particles/econ/events/darkmoon_2017/darkmoon_generic_aoe.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControl(warning, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(warning, 1, Vector(radius, 0, 0))
	ParticleManager:SetParticleControl(warning, 2, Vector(6, 0, 1))
	ParticleManager:SetParticleControl(warning, 3, Vector(200, 0, 0))
	ParticleManager:SetParticleControl(warning, 4, caster:GetAbsOrigin())
end

function channel_end(event)	
	if dummy ~= nil then
		dummy:RemoveSelf()
		dummy = nil
	end
end
