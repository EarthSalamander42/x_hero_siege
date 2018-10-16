modifier_npc_dialog = class({})

-----------------------------------------------------------------------

function modifier_npc_dialog:IsHidden()
	return true
end

-----------------------------------------------------------------------

function modifier_npc_dialog:IsPurgable()
	return false
end

-----------------------------------------------------------------------

function modifier_npc_dialog:OnCreated( params )
	if IsServer() then
		self.flTalkDistance = 800.0
	end
end

-----------------------------------------------------------------------

function modifier_npc_dialog:CheckState()
	local state = 
	{
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_STUNNED] = true,
	}
	
	return state
end

-----------------------------------------------------------------------

function modifier_npc_dialog:DeclareFunctions()
	local funcs = 
	{
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
        MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
		MODIFIER_EVENT_ON_ORDER,
	}
	return funcs
end

function modifier_npc_dialog:GetAbsoluteNoDamageMagical()
	return 1
end

function modifier_npc_dialog:GetAbsoluteNoDamagePhysical()
	return 1
end

function modifier_npc_dialog:GetAbsoluteNoDamagePure()
	return 1
end

-----------------------------------------------------------------------

function modifier_npc_dialog:OnOrder( params )
	if IsServer() then
		local hOrderedUnit = params.unit 
		local hTargetUnit = params.target
		local nOrderType = params.order_type
		if nOrderType ~= 4 then
			return
		end

		if hTargetUnit == nil or hTargetUnit ~= self:GetParent() then
			return
		end

		if hOrderedUnit ~= nil and hOrderedUnit:IsRealHero() and hOrderedUnit:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
			self.hPlayerEnt = hOrderedUnit
			self:StartIntervalThink( 0.25 )
			return
		end

		self:StartIntervalThink( -1 )
	end

	return 0
end


-----------------------------------------------------------------------

function modifier_npc_dialog:OnIntervalThink()
	if IsServer() then
		if self.hPlayerEnt ~= nil then
			if self.flTalkDistance >= ( self.hPlayerEnt:GetOrigin() - self:GetParent():GetOrigin() ):Length2D() then
				if GameMode ~= nil then
					self.hPlayerEnt:Interrupt()
					GameMode:OnDialogBegin( self.hPlayerEnt, self:GetParent() )
					self:StartIntervalThink( -1 )
					self.hPlayerEnt = nil
				end
			end
		end
	end
end
