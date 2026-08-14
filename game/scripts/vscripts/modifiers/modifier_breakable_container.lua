modifier_breakable_container = class({})
modifier_breakable_container.XHS_LINK_CLIENT = true

--------------------------------------------------------------------------------

function modifier_breakable_container:IsHidden()
	return true
end

--------------------------------------------------------------------------------

function modifier_breakable_container:OnCreated(kv)
	if IsServer() then
		local parent = self:GetParent()
		-- Phase 1/2 waves use CUSTOM_1. Owning breakables with the same team
		-- makes the native acquisition system ignore them completely, while
		-- GOODGUYS players still see them as hostile and can destroy them.
		parent:SetTeam(DOTA_TEAM_CUSTOM_1)
		if parent:GetUnitName() == "npc_dota_crate" then
			parent:SetModelScale(RandomFloat(0.6, 0.9))
		elseif parent:GetUnitName() == "npc_dota_vase" then
			parent:SetModelScale(RandomFloat(0.4, 0.6))
		end
	end
end

--------------------------------------------------------------------------------

function modifier_breakable_container:CheckState()
	local state = {}
	if IsServer() then
		state[MODIFIER_STATE_ROOTED] = true
		state[MODIFIER_STATE_NO_HEALTH_BAR] = true
		state[MODIFIER_STATE_BLIND] = true
		state[MODIFIER_STATE_NOT_ON_MINIMAP] = true
		state[MODIFIER_STATE_LOW_ATTACK_PRIORITY] = true
	end

	return state
end

--------------------------------------------------------------------------------

function modifier_breakable_container:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_DEATH,
		MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
	}
	return funcs
end

--------------------------------------------------------------------------------

function modifier_breakable_container:GetModifierProvidesFOWVision(params)
	return 1
end

-----------------------------------------------------------------------

function modifier_breakable_container:OnDeath(params)
	if IsServer() then
		if (params.unit == self:GetParent()) then
			--print( string.format( "Breakable container \"%s\" destroyed by \"%s\"", self:GetParent():GetUnitName() or "Unknown Attacker", self.hAttacker:GetUnitName() ) )
			if self:GetParent():GetUnitName() == "npc_dota_crate" then
				if RandomInt(0, 1) >= 1 then
					EmitSoundOn("Dungeon.SmashCrateShort", self:GetParent())
				else
					EmitSoundOn("Dungeon.SmashCrateLong", self:GetParent())
				end
			elseif self:GetParent():GetUnitName() == "npc_dota_vase" then
				EmitSoundOn("Dungeon.VaseBreak", self:GetParent())
			end
			GameRules.GameMode:ChooseBreakableSurprise(params.attacker, self:GetParent())
		end
	end
end

-----------------------------------------------------------------------
