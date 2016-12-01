modifier_animation_freeze_stun = class({})

function modifier_animation_freeze_stun:OnCreated(keys) 

end

function modifier_animation_freeze_stun:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE --+ MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_animation_freeze_stun:IsHidden()
	return false
end

function modifier_animation_freeze_stun:IsDebuff() 
	return false
end

function modifier_animation_freeze_stun:IsPurgable() 
	return false
end

function modifier_animation_freeze_stun:CheckState() 
	local state = {
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_FROZEN] = true,
	}

	return state
end
