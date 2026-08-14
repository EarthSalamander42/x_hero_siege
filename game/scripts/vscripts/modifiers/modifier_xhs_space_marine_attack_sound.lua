modifier_xhs_space_marine_attack_sound = class({})

function modifier_xhs_space_marine_attack_sound:IsHidden()
	return true
end

function modifier_xhs_space_marine_attack_sound:IsPurgable()
	return false
end

function modifier_xhs_space_marine_attack_sound:RemoveOnDeath()
	return false
end

function modifier_xhs_space_marine_attack_sound:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_xhs_space_marine_attack_sound:OnAttackLanded(params)
	if not IsServer() or params.attacker ~= self:GetParent() then
		return
	end

	local target = params.target
	if target == nil or target:IsNull() then
		return
	end

	EmitSoundOn("Hero_Sniper.ProjectileImpact", target)
end
