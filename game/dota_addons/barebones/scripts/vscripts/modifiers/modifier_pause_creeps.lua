modifier_pause_creeps = modifier_pause_creeps or class({})

function modifier_pause_creeps:IsHidden() return true end
function modifier_pause_creeps:IsPurgable() return false end
function modifier_pause_creeps:IsPurgeException() return false end

function modifier_pause_creeps:DeclareFunctions() return {
	MODIFIER_PROPERTY_DISABLE_HEALING,
} end

function modifier_pause_creeps:CheckState() return {
	[MODIFIER_STATE_STUNNED] = true,
	[MODIFIER_STATE_FROZEN] = true,
	[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
	[MODIFIER_STATE_INVULNERABLE] = true,
} end


function modifier_pause_creeps:GetDisableHealing()
	return 1
end
