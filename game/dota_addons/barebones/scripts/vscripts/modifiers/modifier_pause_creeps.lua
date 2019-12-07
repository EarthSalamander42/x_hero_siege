modifier_pause_creeps = modifier_pause_creeps or class({})

function modifier_pause_creeps:IsHidden() return true end
function modifier_pause_creeps:IsPurgable() return false end
function modifier_pause_creeps:IsPurgeException() return false end

function modifier_pause_creeps:DeclareFunctions() return {
	MODIFIER_PROPERTY_DISABLE_HEALING,
} end

function modifier_pause_creeps:CheckState()
	local state = {
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
		[MODIFIER_STATE_INVULNERABLE] = true,
	}

	if self:GetStackCount() ~= 1 then
		state[MODIFIER_STATE_FROZEN] = true
	end

	return state
end


function modifier_pause_creeps:GetDisableHealing()
	return 1
end
