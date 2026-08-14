modifier_xhs_uther_prison_target = modifier_xhs_uther_prison_target or class({})
modifier_xhs_uther_prison_target.XHS_LINK_CLIENT = true

function modifier_xhs_uther_prison_target:IsHidden() return true end
function modifier_xhs_uther_prison_target:IsPurgable() return false end
function modifier_xhs_uther_prison_target:IsPurgeException() return false end

function modifier_xhs_uther_prison_target:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
	}
end

function modifier_xhs_uther_prison_target:CheckState()
	return {
		-- Allows both A + left click and the right-click force-attack option on
		-- friendly Uther at full health. The server order filter changes the target
		-- to the overlapping ice-prison unit.
		[MODIFIER_STATE_SPECIALLY_DENIABLE] = true,
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
		[MODIFIER_STATE_FROZEN] = true,
	}
end

function modifier_xhs_uther_prison_target:GetAbsoluteNoDamagePhysical() return 1 end
function modifier_xhs_uther_prison_target:GetAbsoluteNoDamageMagical() return 1 end
function modifier_xhs_uther_prison_target:GetAbsoluteNoDamagePure() return 1 end
