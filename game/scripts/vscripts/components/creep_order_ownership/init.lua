if XHSCreepOrderOwnership == nil then
	_G.XHSCreepOrderOwnership = class({})
end

XHSCreepOrderOwnership.OWNER_MODIFIER_AI = "modifier_ai"
XHSCreepOrderOwnership.OWNER_WAVE = "wave"

local function IsValidUnit(unit)
	return unit ~= nil
		and (unit.IsNull == nil or not unit:IsNull())
		and (unit.IsAlive == nil or unit:IsAlive())
end

local function Counter(name, amount)
	if XHSPerformanceCounters ~= nil
		and XHSPerformanceCounters.Increment ~= nil then
		XHSPerformanceCounters:Increment(name, amount or 1)
	end
end

local function OrderSignature(order)
	order = order or {}
	local fields = {
		tostring(tonumber(order.OrderType) or -1),
		tostring(tonumber(order.TargetIndex) or -1),
	}
	local position = order.Position
	if position ~= nil then
		fields[#fields + 1] = tostring(math.floor((tonumber(position.x) or 0) / 64))
		fields[#fields + 1] = tostring(math.floor((tonumber(position.y) or 0) / 64))
	end
	return table.concat(fields, ":")
end

function XHSCreepOrderOwnership:GetOwner(unit)
	if not IsValidUnit(unit) then return nil end
	return unit.xhs_movement_order_owner
end

function XHSCreepOrderOwnership:Claim(unit, owner, allowHandoff)
	if not IsValidUnit(unit) then return false end
	owner = tostring(owner or "")
	if owner == "" then return false end

	local current = unit.xhs_movement_order_owner
	if current == owner then return true end
	if current ~= nil and current ~= "" then
		if allowHandoff ~= true then
			Counter("creep_order_owner_conflicts")
			return false
		end
		Counter("creep_order_owner_handoffs")
	end
	unit.xhs_movement_order_owner = owner
	unit.xhs_movement_order_owner_since = GameRules:GetGameTime()
	return true
end

function XHSCreepOrderOwnership:Release(unit, owner)
	if not IsValidUnit(unit) then return false end
	if owner ~= nil and unit.xhs_movement_order_owner ~= owner then return false end
	unit.xhs_movement_order_owner = nil
	unit.xhs_movement_order_owner_since = nil
	unit.xhs_last_movement_order_signature = nil
	unit.xhs_last_movement_order_at = nil
	return true
end

function XHSCreepOrderOwnership:Issue(unit, owner, order, minimumInterval)
	if not IsValidUnit(unit) or type(order) ~= "table" then return false end
	if not self:Claim(unit, owner, false) then
		Counter("creep_orders_blocked_wrong_owner")
		return false
	end

	local now = GameRules:GetGameTime()
	local signature = OrderSignature(order)
	if signature == unit.xhs_last_movement_order_signature
		and now - (tonumber(unit.xhs_last_movement_order_at) or -math.huge)
			< math.max(0, tonumber(minimumInterval) or 0) then
		Counter("creep_orders_deduplicated")
		return false
	end

	unit.xhs_last_movement_order_signature = signature
	unit.xhs_last_movement_order_at = now
	unit.xhs_last_movement_order_source = owner
	if owner == self.OWNER_MODIFIER_AI then
		Counter("creep_orders_modifier_ai")
	elseif owner == self.OWNER_WAVE then
		Counter("creep_orders_wave")
	end
	ExecuteOrderFromTable(order)
	return true
end

return XHSCreepOrderOwnership
