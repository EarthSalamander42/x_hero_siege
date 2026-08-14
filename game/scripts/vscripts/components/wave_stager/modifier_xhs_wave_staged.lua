modifier_xhs_wave_staged = modifier_xhs_wave_staged or class({})

function modifier_xhs_wave_staged:IsHidden() return true end
function modifier_xhs_wave_staged:IsPurgable() return false end
function modifier_xhs_wave_staged:IsPurgeException() return false end
function modifier_xhs_wave_staged:RemoveOnDeath() return false end

function modifier_xhs_wave_staged:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_xhs_wave_staged:CheckState()
	return {
		[MODIFIER_STATE_OUT_OF_GAME] = true,
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_SILENCED] = true,
		[MODIFIER_STATE_MUTED] = true,
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
	}
end
