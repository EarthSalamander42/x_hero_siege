modifier_xhs_custom_creep_health_bar = class({})

function modifier_xhs_custom_creep_health_bar:IsHidden()
	return true
end

function modifier_xhs_custom_creep_health_bar:IsPurgable()
	return false
end

function modifier_xhs_custom_creep_health_bar:RemoveOnDeath()
	-- Respawning units receive npc_spawned again and the modifier is reapplied.
	-- Do not retain one modifier instance for every dead creep in the match.
	return true
end

function modifier_xhs_custom_creep_health_bar:CheckState()
	return {
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
	}
end
