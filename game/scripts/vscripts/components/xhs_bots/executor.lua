if XHSBotExecutor == nil then
	XHSBotExecutor = {}
end

local function IsValidEntityHandle(entity)
	return entity ~= nil and IsValidEntity(entity) and not entity:IsNull()
end

local function JitterPosition(position, amount)
	if position == nil then return nil end
	amount = math.max(0, tonumber(amount) or 0)
	if amount <= 0 then return position end
	return position + RandomVector(RandomFloat(0, amount))
end

local function GameTime()
	return GameRules ~= nil and GameRules:GetGameTime() or 0
end

local function Distance2D(left, right)
	return (left - right):Length2D()
end

local function IsVisibleToHeroTeam(hero, target)
	if target.IsInvisible ~= nil and target:IsInvisible()
		and target:GetTeamNumber() ~= hero:GetTeamNumber() then
		return false
	end
	if hero.CanEntityBeSeenByMyTeam ~= nil then
		local ok, visible = pcall(function()
			return hero:CanEntityBeSeenByMyTeam(target)
		end)
		return ok and visible == true
	end
	return target:GetTeamNumber() == hero:GetTeamNumber()
end

local function VectorSignature(prefix, position, bucket)
	bucket = math.max(1, tonumber(bucket) or 80)
	return prefix
		.. ":" .. tostring(math.floor(position.x / bucket))
		.. ":" .. tostring(math.floor(position.y / bucket))
end

function XHSBotExecutor:Reject(record, reason)
	if type(record) ~= "table" then return false end
	record.last_rejected_action = tostring(reason or "order rejected")
	record.rejected_orders = (record.rejected_orders or 0) + 1
	return false
end

function XHSBotExecutor:PruneOrderWindow(record, now)
	record.order_timestamps = record.order_timestamps or {}
	local retained = {}
	for _, timestamp in ipairs(record.order_timestamps) do
		if now - timestamp < 1 then
			table.insert(retained, timestamp)
		end
	end
	record.order_timestamps = retained
	return #retained
end

function XHSBotExecutor:GetOrdersPerSecond(record, now)
	if type(record) ~= "table" then return 0 end
	return self:PruneOrderWindow(record, tonumber(now) or GameTime())
end

function XHSBotExecutor:CanIssue(record, signature, minimumInterval)
	if type(record) ~= "table" then return false end
	local now = GameTime()
	minimumInterval = math.max(
		tonumber(minimumInterval) or 0.18,
		tonumber(record.minimum_order_interval) or 0
	)
	if now < (record.next_order_at or 0) then return false end
	if record.last_order_signature == signature
		and now - (record.last_order_at or 0) < minimumInterval then
		return false
	end
	local recentOrders = self:PruneOrderWindow(record, now)
	-- A rolling one-second window counts whole orders. Flooring makes future
	-- fractional configuration conservative instead of silently allowing ceil.
	local maximumOrders = math.max(1, math.floor(tonumber(record.max_orders_per_second) or 3))
	if recentOrders >= maximumOrders then
		record.last_rejected_action = "order rate limit"
		record.rate_limited_orders = (record.rate_limited_orders or 0) + 1
		return false
	end
	return true
end

function XHSBotExecutor:Record(record, signature, label, minimumInterval)
	local now = GameTime()
	record.last_order_signature = signature
	record.last_order = label
	record.last_order_at = now
	record.next_order_at = now + math.max(
		minimumInterval or 0.18,
		tonumber(record.minimum_order_interval) or 0
	)
	record.orders = (record.orders or 0) + 1
	record.order_timestamps = record.order_timestamps or {}
	table.insert(record.order_timestamps, now)
	record.orders_per_second = self:PruneOrderWindow(record, now)
	record.max_orders_per_second_observed = math.max(
		record.max_orders_per_second_observed or 0,
		record.orders_per_second
	)
	record.last_rejected_action = nil
end

function XHSBotExecutor:Move(hero, position, record, label, jitter)
	if not IsValidEntityHandle(hero) or position == nil then
		return self:Reject(record, "invalid move target")
	end
	position = JitterPosition(position, jitter)
	local signature = VectorSignature("move", position, 80)
	if not self:CanIssue(record, signature, 0.35) then return false end

	ExecuteOrderFromTable({
		UnitIndex = hero:entindex(),
		OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
		Position = position,
		Queue = false,
	})
	self:Record(record, signature, label or "move", 0.18)
	record.last_movement_destination = position
	record.last_movement_order_at = GameTime()
	record.last_movement_kind = "move"
	return true
end

-- Instant survival items must not lose a lethal race because a movement or
-- attack order consumed the ordinary per-second budget just before the item
-- became castable. Keep a very small duplicate guard, but deliberately bypass
-- the shared movement/action throttle for this one urgent cast.
function XHSBotExecutor:CanIssueUrgent(record, signature)
	if type(record) ~= "table" then return false end
	local now = GameTime()
	if record.last_order_signature == signature
		and now - (record.last_order_at or 0) < 0.12 then
		return false
	end
	return true
end

function XHSBotExecutor:AttackMove(hero, position, record, label, jitter)
	if not IsValidEntityHandle(hero) or position == nil then
		return self:Reject(record, "invalid attack-move target")
	end
	position = JitterPosition(position, jitter)
	local signature = VectorSignature("attack_move", position, 100)
	if not self:CanIssue(record, signature, 0.45) then return false end

	ExecuteOrderFromTable({
		UnitIndex = hero:entindex(),
		OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
		Position = position,
		Queue = false,
	})
	self:Record(record, signature, label or "attack-move", 0.24)
	record.last_movement_destination = position
	record.last_movement_order_at = GameTime()
	record.last_movement_kind = "attack_move"
	return true
end

function XHSBotExecutor:Hold(hero, record)
	if not IsValidEntityHandle(hero) then return self:Reject(record, "invalid hold unit") end
	local signature = "hold_position"
	if not self:CanIssue(record, signature, 1.25) then
		return record.last_order_signature == signature
	end
	ExecuteOrderFromTable({
		UnitIndex = hero:entindex(),
		OrderType = DOTA_UNIT_ORDER_HOLD_POSITION,
		Queue = false,
	})
	self:Record(record, signature, "hold position", 0.30)
	return true
end

function XHSBotExecutor:Attack(hero, target, record, maximumDistance)
	if not IsValidEntityHandle(hero)
		or not IsValidEntityHandle(target)
		or not target:IsAlive()
		or target:IsInvulnerable() then
		return self:Reject(record, "invalid attack target")
	end
	if not IsVisibleToHeroTeam(hero, target) then
		return self:Reject(record, "attack target is not team-visible")
	end
	maximumDistance = math.max(250, tonumber(maximumDistance) or 1800)
	if Distance2D(hero:GetAbsOrigin(), target:GetAbsOrigin()) > maximumDistance then
		return self:Reject(record, "attack target beyond chase limit")
	end
	local signature = "attack:" .. tostring(target:entindex())
	if not self:CanIssue(record, signature, 0.65) then return false end

	ExecuteOrderFromTable({
		UnitIndex = hero:entindex(),
		OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
		TargetIndex = target:entindex(),
		Queue = false,
	})
	self:Record(record, signature, "attack " .. target:GetUnitName(), 0.22)
	return true
end

function XHSBotExecutor:GetCastRange(hero, ability, target)
	local castRange = 0
	if ability.GetCastRange ~= nil then
		local ok, value = pcall(function()
			return ability:GetCastRange(hero:GetAbsOrigin(), target)
		end)
		if ok then castRange = tonumber(value) or 0 end
	end
	if castRange <= 0 then castRange = 650 end
	return castRange + 90
end

function XHSBotExecutor:ValidateUnitTarget(hero, ability, target, record)
	if not IsValidEntityHandle(target) or not target:IsAlive() or target:IsInvulnerable() then
		return self:Reject(record, "invalid cast target")
	end
	if not IsVisibleToHeroTeam(hero, target) then
		return self:Reject(record, "cast target is not team-visible")
	end

	if ability.CastFilterResultTarget ~= nil then
		local ok, filterResult = pcall(function()
			return ability:CastFilterResultTarget(target)
		end)
		local successCode = UF_SUCCESS or 0
		if ok and filterResult ~= nil and filterResult ~= successCode then
			return self:Reject(record, "ability target filter rejected target")
		end
	end

	local castRange = self:GetCastRange(hero, ability, target)
	if castRange > 90
		and Distance2D(hero:GetAbsOrigin(), target:GetAbsOrigin()) > castRange then
		return self:Reject(record, "cast target out of range")
	end
	return true
end

function XHSBotExecutor:Toggle(hero, ability, desiredState, record, allowPerAttackManaToggle)
	if not IsValidEntityHandle(hero)
		or not IsValidEntityHandle(ability)
		or not ability:IsActivated() then
		return self:Reject(record, "invalid toggle")
	end
	if ability:GetToggleState() == desiredState then return false end
	if desiredState
		and allowPerAttackManaToggle ~= true
		and not ability:IsFullyCastable() then
		return self:Reject(record, "toggle is not castable")
	end
	local signature = "toggle:" .. ability:GetAbilityName() .. ":" .. tostring(desiredState)
	if not self:CanIssue(record, signature, 0.5) then return false end

	ability:ToggleAbility()
	self:Record(record, signature, signature, 0.2)
	record.last_ability = ability:GetAbilityName()
	return true
end

function XHSBotExecutor:PickupItem(hero, drop, record)
	if DOTA_UNIT_ORDER_PICKUP_ITEM == nil or not IsValidEntityHandle(hero)
		or not IsValidEntityHandle(drop)
		or drop.GetContainedItem == nil
		or not IsValidEntityHandle(drop:GetContainedItem()) then
		return self:Reject(record, "invalid supported loot pickup")
	end
	local item = drop:GetContainedItem()
	local itemName = item.GetAbilityName ~= nil and item:GetAbilityName() or "unknown"
	local sharedTome = XHSBotItemCatalog ~= nil
		and XHSBotItemCatalog.GetTome ~= nil
		and XHSBotItemCatalog:GetTome(itemName) ~= nil
	if drop.xhs_breakable_loot ~= true and not sharedTome then
		return self:Reject(record, "unsupported ground item pickup")
	end
	if Distance2D(hero:GetAbsOrigin(), drop:GetAbsOrigin()) > 1100 then
		return self:Reject(record, "ground loot beyond pickup leash")
	end
	local signature = "pickup_loot:" .. tostring(drop:entindex())
	if not self:CanIssue(record, signature, 0.75) then return false end
	ExecuteOrderFromTable({
		UnitIndex = hero:entindex(),
		OrderType = DOTA_UNIT_ORDER_PICKUP_ITEM,
		TargetIndex = drop:entindex(),
		Queue = false,
	})
	self:Record(
		record,
		signature,
		sharedTome and "pick up shared tome " .. itemName
			or "pick up crate loot " .. itemName,
		0.30
	)
	record.last_movement_destination = drop:GetAbsOrigin()
	record.last_movement_order_at = GameTime()
	record.last_movement_kind = "pickup_loot"
	record.loot_pickup_orders = (record.loot_pickup_orders or 0) + 1
	record.last_loot_item = itemName
	return true
end

function XHSBotExecutor:ToggleAutocast(hero, ability, desiredState, record)
	if not IsValidEntityHandle(hero)
		or not IsValidEntityHandle(ability)
		or not ability:IsActivated()
		or ability.GetAutoCastState == nil
		or ability.ToggleAutoCast == nil then
		return self:Reject(record, "invalid autocast")
	end
	if ability:GetAutoCastState() == desiredState then return false end
	if desiredState and not ability:IsFullyCastable() then
		return self:Reject(record, "autocast is not castable")
	end
	local signature = "autocast:" .. ability:GetAbilityName() .. ":" .. tostring(desiredState)
	if not self:CanIssue(record, signature, 0.5) then return false end

	ability:ToggleAutoCast()
	self:Record(record, signature, signature, 0.2)
	record.last_ability = ability:GetAbilityName()
	return true
end

function XHSBotExecutor:Cast(hero, abilityAction, record, jitter)
	if not IsValidEntityHandle(hero) or type(abilityAction) ~= "table" then
		return self:Reject(record, "invalid cast action")
	end
	local ability = abilityAction.ability
	if not IsValidEntityHandle(ability) or not ability:IsActivated() then
		return self:Reject(record, "invalid or deactivated ability")
	end

	local mode = abilityAction.mode
	local abilityName = ability:GetAbilityName()
	if mode == "autocast_attack" then
		local toggled = self:ToggleAutocast(
			hero,
			ability,
			abilityAction.desired_state == true,
			record
		)
		if toggled then record.last_ability_reason = abilityAction.reason end
		return toggled
	end
	if mode == "toggle_single"
		or mode == "toggle_aoe"
		or mode == "defensive_toggle"
		or mode == "rifle_attack_mode" then
		local toggled = self:Toggle(
			hero,
			ability,
			abilityAction.desired_state == true,
			record,
			mode == "rifle_attack_mode"
		)
		if toggled then
			record.last_ability_reason = abilityAction.reason
		end
		return toggled
	end
	if not ability:IsFullyCastable() then
		record.casts_rejected = (record.casts_rejected or 0) + 1
		return self:Reject(record, abilityName .. " is not fully castable")
	end

	local order = {
		UnitIndex = hero:entindex(),
		AbilityIndex = ability:entindex(),
		Queue = false,
	}
	local signature = "cast:" .. abilityName

	if mode == "enemy_unit" or mode == "ally_heal" or mode == "ally_buff" then
		local target = abilityAction.target
		if not self:ValidateUnitTarget(hero, ability, target, record) then
			record.casts_rejected = (record.casts_rejected or 0) + 1
			return false
		end
		order.OrderType = DOTA_UNIT_ORDER_CAST_TARGET
		order.TargetIndex = target:entindex()
		signature = signature .. ":" .. tostring(target:entindex())
	elseif mode == "point_aoe" or mode == "directional_point" then
		local position = JitterPosition(abilityAction.position, jitter)
		if position == nil then
			record.casts_rejected = (record.casts_rejected or 0) + 1
			return self:Reject(record, "missing cast position")
		end
		local castRange = self:GetCastRange(hero, ability, nil)
		if castRange > 90 and Distance2D(hero:GetAbsOrigin(), position) > castRange then
			record.casts_rejected = (record.casts_rejected or 0) + 1
			return self:Reject(record, "cast position out of range")
		end
		if ability.CastFilterResultLocation ~= nil then
			local ok, filterResult = pcall(function()
				return ability:CastFilterResultLocation(position)
			end)
			local successCode = UF_SUCCESS or 0
			if ok and filterResult ~= nil and filterResult ~= successCode then
				record.casts_rejected = (record.casts_rejected or 0) + 1
				return self:Reject(record, "ability location filter rejected position")
			end
		end
		order.OrderType = DOTA_UNIT_ORDER_CAST_POSITION
		order.Position = position
		signature = VectorSignature(signature, position, 100)
	else
		if ability.CastFilterResult ~= nil then
			local ok, filterResult = pcall(function() return ability:CastFilterResult() end)
			local successCode = UF_SUCCESS or 0
			if ok and filterResult ~= nil and filterResult ~= successCode then
				record.casts_rejected = (record.casts_rejected or 0) + 1
				return self:Reject(record, "ability cast filter rejected no-target cast")
			end
		end
		order.OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET
	end

	local canIssue = nil
	if abilityAction.urgent == true then
		canIssue = self:CanIssueUrgent(record, signature)
	else
		canIssue = self:CanIssue(record, signature, 0.75)
	end
	if not canIssue then return false end
	-- Read timing before issuing the order. Consumables can be removed from the
	-- inventory synchronously, invalidating their ability handle immediately.
	local castPoint = 0
	if ability.GetCastPoint ~= nil then
		local ok, value = pcall(function() return ability:GetCastPoint() end)
		if ok then castPoint = math.max(0, tonumber(value) or 0) end
	end
	local channelTime = 0
	if ability.GetChannelTime ~= nil then
		local ok, value = pcall(function() return ability:GetChannelTime() end)
		if ok then channelTime = math.max(0, tonumber(value) or 0) end
	end
	ExecuteOrderFromTable(order)
	self:Record(
		record,
		signature,
		"cast " .. abilityName,
		math.max(0.2, castPoint + channelTime + 0.05)
	)
	record.last_ability = abilityName
	record.last_ability_reason = abilityAction.reason
	record.casts_issued = (record.casts_issued or 0) + 1
	if channelTime > 0 then
		record.channels_started = (record.channels_started or 0) + 1
		record.expected_channel_until = GameTime() + castPoint + channelTime
	end
	if abilityAction.control == true and abilityAction.target ~= nil then
		record.combo_target_entindex = abilityAction.target:entindex()
		record.combo_until = GameTime() + (tonumber(record.simple_combo_window) or 0)
	end
	return true
end

function XHSBotExecutor:Execute(hero, action, record, difficulty)
	if not IsValidEntityHandle(hero) or type(action) ~= "table" then
		return self:Reject(record, "invalid executable action")
	end
	difficulty = difficulty or {}
	record.minimum_order_interval = tonumber(difficulty.min_order_interval) or 0.18
	record.max_orders_per_second = tonumber(difficulty.max_orders_per_second) or 3
	record.simple_combo_window = tonumber(difficulty.simple_combo_window) or 0

	if hero:IsChanneling() then
		local mayInterrupt = (action.id == "evade_danger" or action.id == "retreat")
			and action.data ~= nil
			and action.data.interrupt_channel == true
		if not mayInterrupt then
			return self:Reject(record, "channel protected")
		end
		record.channels_interrupted = (record.channels_interrupted or 0) + 1
		record.next_order_at = 0
		record.last_order_signature = nil
	end

	local jitter = difficulty.order_jitter or 0
	if action.id == "evade_danger" then
		return self:Move(hero, action.data.position, record, "evade danger", jitter * 0.25)
	elseif action.id == "retreat" then
		return self:Move(hero, action.data.position, record, "retreat", jitter)
	elseif action.id == "reposition" then
		return self:Move(hero, action.data.position, record, "reposition", jitter)
	elseif action.id == "move_to_objective" then
		local collectingRune = action.data.objective == "rune"
		return self:Move(
			hero,
			action.data.position,
			record,
			collectingRune and "collect rune" or "move to objective",
			collectingRune and math.min(20, jitter) or jitter
		)
	elseif action.id == "move_to_last_seen" then
		return self:Move(hero, action.data.position, record, "move to last seen position", jitter * 0.5)
	elseif action.id == "attack_move" then
		return self:AttackMove(hero, action.data.position, record, "attack-move to objective", jitter)
	elseif action.id == "attack_target" then
		return self:Attack(
			hero,
			action.data.target,
			record,
			action.data.maximum_distance or difficulty.max_chase_distance
		)
	elseif action.id == "break_crate" then
		local issued = self:Attack(hero, action.data.target, record, 900)
		if issued then
			record.crates_targeted = (record.crates_targeted or 0) + 1
		end
		return issued
	elseif action.id == "pickup_loot" then
		return self:PickupItem(hero, action.data.target, record)
	elseif action.id == "cast_ability" then
		return self:Cast(hero, action.data, record, jitter * 0.35)
	elseif action.id == "hold" then
		return self:Hold(hero, record)
	elseif action.id == "wait" then
		record.last_order = "wait"
		return true
	end
	return self:Reject(record, "unsupported action: " .. tostring(action.id))
end

return XHSBotExecutor
