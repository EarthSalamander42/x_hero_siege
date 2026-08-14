modifier_xhs_end_screen_stat_tracker = class({})

function modifier_xhs_end_screen_stat_tracker:IsHidden() return true end
function modifier_xhs_end_screen_stat_tracker:IsPurgable() return false end
function modifier_xhs_end_screen_stat_tracker:RemoveOnDeath() return false end

function modifier_xhs_end_screen_stat_tracker:DeclareFunctions()
	local events = { MODIFIER_EVENT_ON_TAKEDAMAGE }
	if MODIFIER_EVENT_ON_HEAL_RECEIVED ~= nil then
		table.insert(events, MODIFIER_EVENT_ON_HEAL_RECEIVED)
	elseif MODIFIER_EVENT_ON_HEALTH_GAINED ~= nil then
		table.insert(events, MODIFIER_EVENT_ON_HEALTH_GAINED)
	end
	return events
end

local function Record(parent, statName, amount)
	if not IsServer() or parent == nil or parent:IsNull() or XHSRecordEndScreenStatSource == nil then return end
	local playerID = XHSGetPlayerIDFromUnit ~= nil and XHSGetPlayerIDFromUnit(parent) or parent:GetPlayerOwnerID()
	if playerID ~= nil and playerID >= 0 then
		local isPersistent = true
		if IsXHSPersistentPlayerID ~= nil then
			isPersistent = IsXHSPersistentPlayerID(playerID)
		elseif PlayerResource.IsFakeClient ~= nil and PlayerResource:IsValidPlayerID(playerID) then
			isPersistent = not PlayerResource:IsFakeClient(playerID)
		end
		local sourceName = "hero_modifier"
		if not isPersistent then
			-- Keep bot statistics in the local end-screen snapshot. The API
			-- serializes only persistent humans to its backend payload.
			parent.xhs_end_screen_stats_local_only = true
			sourceName = "hero_modifier_bot_local"
		end
		XHSRecordEndScreenStatSource(playerID, statName, amount, sourceName)
	end
end

function modifier_xhs_end_screen_stat_tracker:OnTakeDamage(event)
	if not IsServer() or event == nil or (tonumber(event.damage) or 0) <= 0 then return end
	local parent = self:GetParent()

	if event.unit == parent then
		Record(parent, "damage_taken", event.damage)
	end

	if event.attacker ~= nil and XHSGetPlayerIDFromUnit ~= nil and XHSIsBossDamageTarget ~= nil and XHSIsBossDamageTarget(event.unit) then
		local ownerID = XHSGetPlayerIDFromUnit(event.attacker)
		local parentID = XHSGetPlayerIDFromUnit(parent)
		if ownerID ~= nil and ownerID == parentID then
			Record(parent, "boss_damage", event.damage)
		end
	end
end

function modifier_xhs_end_screen_stat_tracker:RecordHealing(event)
	if not IsServer() or event == nil or event.unit ~= self:GetParent() then return end
	local amount = tonumber(event.gain or event.heal or event.amount) or 0
	if amount <= 0 then return end

	local healer = event.healer or event.source or event.attacker
	if healer ~= nil and XHSGetPlayerIDFromUnit ~= nil then
		local healerID = XHSGetPlayerIDFromUnit(healer)
		local targetID = XHSGetPlayerIDFromUnit(self:GetParent())
		if healerID == nil or healerID ~= targetID then return end
	end

	Record(self:GetParent(), "self_healing", amount)
end

function modifier_xhs_end_screen_stat_tracker:OnHealReceived(event)
	self:RecordHealing(event)
end

function modifier_xhs_end_screen_stat_tracker:OnHealthGained(event)
	self:RecordHealing(event)
end
