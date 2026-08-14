if XHSBotLoot == nil then XHSBotLoot = {} end

XHSBotLoot.CRATE_RADIUS = 850
XHSBotLoot.DROP_RADIUS = 1050
XHSBotLoot.CLAIM_SECONDS = 4
XHSBotLoot.claims = XHSBotLoot.claims or {}

local function Valid(entity)
	return entity ~= nil and IsValidEntity(entity) and not entity:IsNull()
end

local function Distance(hero, entity)
	return (hero:GetAbsOrigin() - entity:GetAbsOrigin()):Length2D()
end

function XHSBotLoot:Reset()
	self.claims = {}
end

function XHSBotLoot:ExpireClaims(now)
	for entindex, claim in pairs(self.claims) do
		if claim == nil or claim.expires_at <= now then
			self.claims[entindex] = nil
		end
	end
end

function XHSBotLoot:CanClaim(entity, playerID, now)
	local claim = self.claims[entity:entindex()]
	return claim == nil or claim.expires_at <= now or claim.player_id == playerID
end

function XHSBotLoot:Claim(entity, playerID, now)
	self.claims[entity:entindex()] = {
		player_id = playerID,
		expires_at = now + self.CLAIM_SECONDS,
	}
end

function XHSBotLoot:HasPickupCapacity(hero, item)
	if Valid(item) and item.GetAbilityName ~= nil
		and item:GetAbilityName() == "item_bag_of_gold" then
		return true
	end
	for slot = 0, 8 do
		if hero:GetItemInSlot(slot) == nil then return true end
	end
	if not Valid(item) or item.GetAbilityName == nil then return false end
	local name = item:GetAbilityName()
	for slot = 0, 8 do
		local carried = hero:GetItemInSlot(slot)
		if Valid(carried) and carried.GetAbilityName ~= nil
			and carried:GetAbilityName() == name then
			local ok, stackable = pcall(function() return item:IsStackable() end)
			if ok and stackable then return true end
		end
	end
	return false
end

function XHSBotLoot:FindDrop(playerID, hero, now)
	local nearest = nil
	for _, drop in pairs(Entities:FindAllByClassnameWithin(
		"dota_item_drop",
		hero:GetAbsOrigin(),
		self.DROP_RADIUS
	)) do
		if Valid(drop) and drop.GetContainedItem ~= nil
			and self:CanClaim(drop, playerID, now) then
			local item = drop:GetContainedItem()
			local itemName = Valid(item) and item.GetAbilityName ~= nil
				and item:GetAbilityName() or ""
			local sharedTome = itemName ~= ""
				and XHSBotItemCatalog ~= nil
				and XHSBotItemCatalog.GetTome ~= nil
				and XHSBotItemCatalog:GetTome(itemName) ~= nil
			local supportedDrop = drop.xhs_breakable_loot == true
				or sharedTome
			if supportedDrop and self:HasPickupCapacity(hero, item) then
				local candidate = {
					kind = sharedTome and "shared_tome" or "drop",
					entity = drop,
					position = drop:GetAbsOrigin(),
					distance = Distance(hero, drop),
					item_name = itemName,
				}
				if nearest == nil or candidate.distance < nearest.distance then
					nearest = candidate
				end
			end
		end
	end
	if nearest ~= nil then self:Claim(nearest.entity, playerID, now) end
	return nearest
end

function XHSBotLoot:FindCrate(playerID, hero, now)
	-- Breakables are npc_dota_creature entities whose team is rewritten by a
	-- modifier. Combat target queries can omit them despite a visible crate
	-- being attackable, so inspect the bounded entity class directly.
	local units = Entities:FindAllByClassnameWithin(
		"npc_dota_creature",
		hero:GetAbsOrigin(),
		self.CRATE_RADIUS
	) or {}
	local nearest = nil
	for _, unit in pairs(units) do
		if Valid(unit) and unit:IsAlive()
			and unit:GetUnitName() == "npc_dota_crate"
			and unit:HasModifier("modifier_breakable_container")
			and self:CanClaim(unit, playerID, now) then
			local candidate = {
				kind = "crate",
				entity = unit,
				position = unit:GetAbsOrigin(),
				distance = Distance(hero, unit),
				item_name = "",
			}
			if nearest == nil or candidate.distance < nearest.distance then
				nearest = candidate
			end
		end
	end
	if nearest ~= nil then self:Claim(nearest.entity, playerID, now) end
	return nearest
end

function XHSBotLoot:FindOpportunity(playerID, hero, record, allowed)
	if allowed ~= true or not Valid(hero) or not hero:IsAlive() then return nil end
	local now = GameRules:GetGameTime()
	self:ExpireClaims(now)
	local drop = self:FindDrop(playerID, hero, now)
	if drop ~= nil then return drop end
	return self:FindCrate(playerID, hero, now)
end

return XHSBotLoot
