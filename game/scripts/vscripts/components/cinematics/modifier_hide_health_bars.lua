modifier_xhs_cinematic_hide_health_bars = modifier_xhs_cinematic_hide_health_bars or class({})
modifier_xhs_cinematic_hide_health_bars.XHS_LINK_CLIENT = true

function modifier_xhs_cinematic_hide_health_bars:IsHidden()
	return true
end

function modifier_xhs_cinematic_hide_health_bars:IsPurgable()
	return false
end

function modifier_xhs_cinematic_hide_health_bars:IsPurgeException()
	return false
end

function modifier_xhs_cinematic_hide_health_bars:RemoveOnDeath()
	return false
end

function modifier_xhs_cinematic_hide_health_bars:CheckState()
	return {
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
	}
end
