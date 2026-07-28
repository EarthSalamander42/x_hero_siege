function JinguHit(keys)
local caster = keys.caster
local ability = keys.ability
local jinguBuff = caster:FindModifierByName("modifier_jingu_mastery_activated")

	-- Keep the DataDriven Lifesteal action as the source of truth for gameplay.
	-- Its companion RunScript (after the action) only observes the real health
	-- gained so the equipped Supporter Pass attack-lifesteal cosmetic can play.
	caster.xhs_supporter_jingu_lifesteal = nil
	local health_before = caster:GetHealth()
	if health_before < caster:GetMaxHealth() then
		caster.xhs_supporter_jingu_lifesteal = {
			health_before = health_before,
			victim = keys.target,
		}
	end

	if jinguBuff then
		jinguBuff:DecrementStackCount()
		if jinguBuff:GetStackCount() <= 0 then
			jinguBuff:Destroy()
			caster:RemoveModifierByName("modifier_jingu_mastery_activated_damage")
		end
	end
end

function JinguLifestealFX(keys)
	local hero = keys.caster
	local state = hero and hero.xhs_supporter_jingu_lifesteal
	if hero then
		hero.xhs_supporter_jingu_lifesteal = nil
	end
	if state == nil then return end

	local actual_heal = hero:GetHealth() - (tonumber(state.health_before) or hero:GetHealth())
	if actual_heal > 0 and XHSPlaySupporterAttackLifestealFX ~= nil then
		XHSPlaySupporterAttackLifestealFX(hero, state.victim, actual_heal)
	end
end

function CheckJingu(keys)
local caster = keys.caster
local target = keys.target
local ability = keys.ability

--	if caster:HasModifier("modifier_jingu_mastery_activated") or not target:IsRealHero() or not caster:IsRealHero() or caster:PassivesDisabled() then return
	if caster:HasModifier("modifier_jingu_mastery_activated") or target:IsBuilding() or caster:PassivesDisabled() then return
	else
		local jinguStack = target:FindModifierByName("modifier_jingu_mastery_hitcount")
		if not jinguStack then 
			ability:ApplyDataDrivenModifier(caster, target, "modifier_jingu_mastery_hitcount", {duration = ability:GetLevelSpecialValueFor("counter_duration", ability:GetLevel() - 1)})
			jinguStack = target:FindModifierByName("modifier_jingu_mastery_hitcount")
			jinguStack:SetStackCount(0)
		end

		jinguStack:SetStackCount(jinguStack:GetStackCount() + 1)

		if not target.OverHeadJingu then 
			target.OverHeadJingu = ParticleManager:CreateParticle(keys.particle, PATTACH_OVERHEAD_FOLLOW, target)
			ParticleManager:SetParticleControl(target.OverHeadJingu, 0, target:GetAbsOrigin())
		end
		ParticleManager:SetParticleControl(target.OverHeadJingu, 1, Vector(0,jinguStack:GetStackCount(),0))
		
		if jinguStack:GetStackCount() == ability:GetLevelSpecialValueFor("required_hits", ability:GetLevel() - 1) then
			local jinguBuff = ability:ApplyDataDrivenModifier(caster, caster, "modifier_jingu_mastery_activated", {})
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_jingu_mastery_activated_damage", {})
			jinguBuff:SetStackCount(ability:GetLevelSpecialValueFor("charges", ability:GetLevel() - 1))
			jinguStack:Destroy()
		end
	end
end

function JinguOverheadDestroy(keys)
local caster = keys.caster
local target = keys.target
local ability = keys.ability
	
	ParticleManager:DestroyParticle(target.OverHeadJingu, false)
	ParticleManager:ReleaseParticleIndex(target.OverHeadJingu)
	target.OverHeadJingu = nil
end