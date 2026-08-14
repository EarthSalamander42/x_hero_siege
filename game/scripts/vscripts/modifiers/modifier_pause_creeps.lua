modifier_pause_creeps = modifier_pause_creeps or class({})
modifier_pause_creeps.XHS_LINK_CLIENT = true

function modifier_pause_creeps:IsHidden() return true end
function modifier_pause_creeps:IsPurgable() return false end
function modifier_pause_creeps:IsPurgeException() return false end

local function IsFrozenUther(modifier)
	local parent = modifier:GetParent()
	return parent ~= nil
		and not parent:IsNull()
		and parent:GetUnitName() == "npc_xhs_paladin_2"
		and modifier:GetStackCount() ~= 1
end

function modifier_pause_creeps:DeclareFunctions()
	local functions = {
		MODIFIER_PROPERTY_DISABLE_HEALING,
	}

	if IsFrozenUther(self) then
		functions[#functions + 1] = MODIFIER_PROPERTY_FIXED_DAY_VISION
		functions[#functions + 1] = MODIFIER_PROPERTY_FIXED_NIGHT_VISION
	end

	return functions
end

function modifier_pause_creeps:GetFixedDayVision()
	if IsFrozenUther(self) then return 0 end
	return nil
end

function modifier_pause_creeps:GetFixedNightVision()
	if IsFrozenUther(self) then return 0 end
	return nil
end

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
