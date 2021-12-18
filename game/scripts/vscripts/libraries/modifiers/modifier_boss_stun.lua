modifier_boss_stun = class({})

function modifier_boss_stun:OnCreated(keys) 

end

function modifier_boss_stun:GetAttributes()
	return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE --+ MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_boss_stun:IsHidden()
	return false
end

function modifier_boss_stun:IsDebuff() 
	return false
end

function modifier_boss_stun:IsPurgable() 
	return false
end

function modifier_boss_stun:CheckState() 
	local state = {
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
	}

	return state
end

