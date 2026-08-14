modifier_xhs_farm_staged = modifier_xhs_farm_staged or class({})
modifier_xhs_farm_suspended = modifier_xhs_farm_suspended or class({})
modifier_xhs_farm_wave_damage = modifier_xhs_farm_wave_damage or class({})

local function HiddenPermanentModifier(modifier)
	function modifier:IsHidden() return true end
	function modifier:IsPurgable() return false end
	function modifier:IsPurgeException() return false end
	function modifier:RemoveOnDeath() return true end
end

HiddenPermanentModifier(modifier_xhs_farm_staged)
HiddenPermanentModifier(modifier_xhs_farm_suspended)
HiddenPermanentModifier(modifier_xhs_farm_wave_damage)

local function DormantStates()
	return {
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_OUT_OF_GAME] = true,
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
		[MODIFIER_STATE_UNSELECTABLE] = true,
	}
end

function modifier_xhs_farm_staged:CheckState()
	return DormantStates()
end

function modifier_xhs_farm_suspended:CheckState()
	return DormantStates()
end

function modifier_xhs_farm_wave_damage:OnCreated(params)
	self.damage_pct = tonumber(params and params.damage_pct) or 0
end

function modifier_xhs_farm_wave_damage:OnRefresh(params)
	self.damage_pct = tonumber(params and params.damage_pct) or self.damage_pct or 0
end

function modifier_xhs_farm_wave_damage:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
	}
end

function modifier_xhs_farm_wave_damage:GetModifierDamageOutgoing_Percentage()
	return self.damage_pct or 0
end
