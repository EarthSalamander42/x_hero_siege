-- Single server-side entry point for tombstone interaction and cleanup.
-- The GameMode filter only suppresses a repeated click on the tombstone whose
-- revive is already channeling; interaction startup remains owned here.
modifier_xhs_tombstone_interaction = modifier_xhs_tombstone_interaction or class({})

local TOMBSTONE_UNIT_NAME = "npc_xhs_hero_tombstone"
local GROUND_CLICK_RADIUS = 180
local TARGET_ORDER_TYPES = {
	[2] = true, -- DOTA_UNIT_ORDER_MOVE_TO_TARGET
	[4] = true, -- DOTA_UNIT_ORDER_ATTACK_TARGET
}

local function IsValidEntityHandle(entity)
	return entity ~= nil and IsValidEntity(entity) and not entity:IsNull()
end

local function IsTombstone(entity)
	if not IsValidEntityHandle(entity) then return false end
	if _G.XHSUnitTombstone ~= nil and _G.XHSUnitTombstone.IsTombstone ~= nil then
		return _G.XHSUnitTombstone:IsTombstone(entity)
	end
	return entity.GetUnitName ~= nil and entity:GetUnitName() == TOMBSTONE_UNIT_NAME
end

local function ResolveOrderedTombstone(params)
	if TARGET_ORDER_TYPES[params.order_type] == true then
		return IsTombstone(params.target) and params.target or nil
	end
	if params.order_type == DOTA_UNIT_ORDER_MOVE_TO_POSITION and params.new_pos ~= nil then
		local nearby = Entities:FindByNameNearest(TOMBSTONE_UNIT_NAME, params.new_pos, GROUND_CLICK_RADIUS)
		return IsTombstone(nearby) and nearby or nil
	end
	return nil
end

function modifier_xhs_tombstone_interaction:IsHidden() return true end

function modifier_xhs_tombstone_interaction:IsPurgable() return false end

function modifier_xhs_tombstone_interaction:RemoveOnDeath() return false end

function modifier_xhs_tombstone_interaction:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ORDER,
		MODIFIER_EVENT_ON_RESPAWN,
	}
end

function modifier_xhs_tombstone_interaction:OnRespawn(params)
	if not IsServer() or params == nil or params.unit ~= self:GetParent() then return end
	if params.unit.xhs_tombstone_internal_respawn == true then return end
	local system = _G.XHSUnitTombstone
	if system ~= nil and system.CleanupRevivedHero ~= nil then
		system:CleanupRevivedHero(params.unit)
	end
end

function modifier_xhs_tombstone_interaction:OnOrder(params)
	if not IsServer() or params == nil then return end
	local hero = self:GetParent()
	if params.unit ~= hero or not hero:IsRealHero() or not hero:IsAlive() then return end

	local tombstone = ResolveOrderedTombstone(params)
	if tombstone == nil or tombstone:GetTeamNumber() ~= hero:GetTeamNumber() then
		hero.xhs_pending_tombstone_entindex = nil
		return
	end
	local tombstoneEntindex = tombstone:entindex()
	if hero.xhs_pending_tombstone_entindex == tombstoneEntindex then return end
	hero.xhs_pending_tombstone_entindex = tombstoneEntindex

	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("xhs_tombstone_on_order"), function()
		local system = _G.XHSUnitTombstone
		if IsValidEntityHandle(hero) and hero:IsAlive()
			and IsTombstone(tombstone) and system ~= nil and system.BeginInteraction ~= nil then
			if system:BeginInteraction(hero, tombstone) then return nil end
		end
		if IsValidEntityHandle(hero) and hero.xhs_pending_tombstone_entindex == tombstoneEntindex then
			hero.xhs_pending_tombstone_entindex = nil
		end
		return nil
	end, 0)
end
