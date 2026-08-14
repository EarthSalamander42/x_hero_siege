modifier_command_restricted = class({})
modifier_command_restricted.XHS_LINK_CLIENT = true

function modifier_command_restricted:IsHidden()
	return true
end

function modifier_command_restricted:CheckState()
	local state = 
	{
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_STUNNED] = true,
	}

	if self:GetStackCount() == 1 then
		state[MODIFIER_STATE_FROZEN] = true
	end
	
	return state
end
