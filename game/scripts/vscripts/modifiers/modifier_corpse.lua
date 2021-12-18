modifier_corpse = modifier_corpse or class({})

function modifier_corpse:IsHidden() return true end

function modifier_corpse:CheckState() return {
	[MODIFIER_STATE_INVULNERABLE] = true,
	[MODIFIER_STATE_NO_HEALTH_BAR] = true,
	[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
	[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
} end
