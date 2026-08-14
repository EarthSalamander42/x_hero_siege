local CASTLE_BAR_TIMEOUT = 15.0
local CASTLE_BAR_POLL_INTERVAL = 0.2
local DEFAULT_MURADIN_THRESHOLD = 40

modifier_xhs_castle_health_bar = class({})

function modifier_xhs_castle_health_bar:IsHidden()
	return true
end

function modifier_xhs_castle_health_bar:IsPurgable()
	return false
end

function modifier_xhs_castle_health_bar:RemoveOnDeath()
	return false
end

function modifier_xhs_castle_health_bar:OnCreated()
	if not IsServer() then return end

	self.barVisible = false
	self.lastAttackTime = -math.huge
	self.snapshot = nil
	self.muradinThreshold = nil
	self.muradinTriggered = false
	self:PublishState(false)
end

function modifier_xhs_castle_health_bar:OnDestroy()
	if not IsServer() then return end
	self:HideBar()
end

function modifier_xhs_castle_health_bar:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_xhs_castle_health_bar:GetMuradinThreshold()
	if self.muradinThreshold ~= nil then
		return self.muradinThreshold
	end

	local threshold = DEFAULT_MURADIN_THRESHOLD
	local ability = self:GetParent():FindAbilityByName("castle_muradin_defend")
	if ability ~= nil and not ability:IsNull() then
		threshold = tonumber(ability:GetSpecialValueFor("hp_tooltip")) or threshold
	end
	self.muradinThreshold = threshold
	return threshold
end

function modifier_xhs_castle_health_bar:IsMuradinTriggered()
	local ability = self:GetParent():FindAbilityByName("castle_muradin_defend")
	return self.muradinTriggered == true or ability == nil or ability:IsNull()
end

function modifier_xhs_castle_health_bar:GetPayload()
	local castle = self:GetParent()
	local threshold = self:GetMuradinThreshold()
	local triggered = self:IsMuradinTriggered()
	return {
		castle_name = castle:GetUnitName(),
		castle_icon = "npc_dota_hero_omniknight",
		castle_health = castle:GetHealth(),
		castle_max_health = castle:GetMaxHealth(),
		muradin_threshold = threshold,
		muradin_triggered = triggered and 1 or 0,
		light_color = "#70d6ff",
		dark_color = "#102d55",
		castle_markers = {
			{
				pct = threshold,
				kind = "companion",
				label = triggered and "Muradin deployed" or "Muradin arrives",
				description = triggered
					and "Muradin has already answered the castle's call."
					or "Muradin appears when the castle reaches this health threshold.",
				triggered = triggered,
			},
		},
	}
end

function modifier_xhs_castle_health_bar:PublishState(visible)
	if CustomNetTables == nil then return end

	if visible == true then
		local payload = self:GetPayload()
		payload.visible = 1
		CustomNetTables:SetTableValue("xhs_castle_bar", "state", payload)
	else
		CustomNetTables:SetTableValue("xhs_castle_bar", "state", { visible = 0 })
	end
end

function modifier_xhs_castle_health_bar:GetSnapshot()
	local castle = self:GetParent()
	return table.concat({
		tostring(castle:GetHealth()),
		tostring(castle:GetMaxHealth()),
		tostring(self:GetMuradinThreshold()),
		self:IsMuradinTriggered() and "1" or "0",
	}, "|")
end

function modifier_xhs_castle_health_bar:UpdateBar(force)
	if self.barVisible ~= true then return end

	local snapshot = self:GetSnapshot()
	if force ~= true and self.snapshot == snapshot then return end

	self.snapshot = snapshot
	local payload = self:GetPayload()
	self:PublishState(true)
	CustomGameEventManager:Send_ServerToAllClients("update_castle_hp", payload)
end

function modifier_xhs_castle_health_bar:ShowBar()
	if GameMode ~= nil and GameMode.SpecialArena_occuring == true then
		self:HideBar()
		return
	end

	self.lastAttackTime = GameRules:GetGameTime()
	if self.barVisible ~= true then
		self.barVisible = true
		self.snapshot = self:GetSnapshot()
		local payload = self:GetPayload()
		self:PublishState(true)
		CustomGameEventManager:Send_ServerToAllClients("show_castle_hp", payload)
	else
		self:UpdateBar(true)
	end
	self:StartIntervalThink(CASTLE_BAR_POLL_INTERVAL)
end

function modifier_xhs_castle_health_bar:HideBar(force)
	local shouldPublish = self.barVisible == true or force == true

	self.barVisible = false
	self.snapshot = nil
	self:StartIntervalThink(-1)
	if not shouldPublish then return end
	self:PublishState(false)
	CustomGameEventManager:Send_ServerToAllClients("hide_castle_hp", {})
end

function modifier_xhs_castle_health_bar:OnIntervalThink()
	if GameRules:GetGameTime() - self.lastAttackTime >= CASTLE_BAR_TIMEOUT then
		self:HideBar()
		return
	end
	self:UpdateBar(false)
end

function modifier_xhs_castle_health_bar:OnAttackLanded(event)
	if not IsServer() or event.target ~= self:GetParent() then return end
	self:ShowBar()
end

function modifier_xhs_castle_health_bar:MarkMuradinTriggered(threshold)
	if not IsServer() then return end

	self.muradinTriggered = true
	self.muradinThreshold = tonumber(threshold) or self:GetMuradinThreshold()
	self:UpdateBar(true)
end
