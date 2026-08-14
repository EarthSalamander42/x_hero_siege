require("libraries/timers")

local function IsValidHowlingBlastEntity(entity)
	return entity ~= nil
		and IsValidEntity(entity)
		and not entity:IsNull()
end

function HowlingBlast(keys)
	if keys == nil then return end

	local caster = keys.caster
	local attacker = keys.attacker
	local ability = keys.ability
	if not IsValidHowlingBlastEntity(caster)
		or not IsValidHowlingBlastEntity(attacker)
		or not IsValidHowlingBlastEntity(ability) then
		return
	end

	local attacker_position = attacker:GetAbsOrigin()
	local damage = ability:GetLevelSpecialValueFor("ensnare_damage", ability:GetLevel() - 1)
	local duration = ability:GetLevelSpecialValueFor("ensnare_duration", ability:GetLevel() - 1)
	local cooldown = 1.0
	local modifier = keys.modifier
	local abilityName = ability:GetAbilityName()

	if not attacker:IsBuilding() and ability:IsActivated() then
		local particle1 = ParticleManager:CreateParticle("particles/units/heroes/heroes_underlord/abyssal_underlord_pitofmalice_stun.vpcf", PATTACH_ABSORIGIN_FOLLOW, attacker)
		ParticleManager:SetParticleControl(particle1, 0, attacker_position)
		Timers:CreateTimer(duration, function()
			ParticleManager:DestroyParticle(particle1, true)
			ParticleManager:ReleaseParticleIndex(particle1)
		end)

		attacker:EmitSound("Hero_AbyssalUnderlord.Pit.TargetHero")
		ability:ApplyDataDrivenModifier(caster, attacker, "modifier_rooted", { duration = duration })
		if modifier ~= nil and modifier ~= "" then
			ability:ApplyDataDrivenModifier(caster, attacker, modifier, { duration = duration })
		end
		caster:RemoveModifierByName('modifier_howling_blast')
		ability:StartCooldown(cooldown)

		ApplyDamage({ victim = attacker, attacker = caster, damage = damage, ability = ability, damage_type = ability:GetAbilityDamageType() })

		Timers:CreateTimer(cooldown, function()
			if not IsValidHowlingBlastEntity(caster) then return nil end

			-- Never reuse the captured ability handle: a dead/removed creature
			-- leaves a non-nil Lua object whose engine type has become [none].
			local currentAbility = caster:FindAbilityByName(abilityName)
			if IsValidHowlingBlastEntity(currentAbility) then
				currentAbility:ApplyDataDrivenModifier(caster, caster, "modifier_howling_blast", {})
			end
			return nil
		end)
	end
end
