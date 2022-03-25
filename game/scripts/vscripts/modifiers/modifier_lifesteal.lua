-- Lifesteal modifier

modifier_lifesteal = modifier_lifesteal or class({})

function modifier_lifesteal:IsHidden() return not IsInToolsMode() end
function modifier_lifesteal:IsPurgable() return false end
function modifier_lifesteal:IsDebuff() return false end
function modifier_lifesteal:RemoveOnDeath() return false end
function modifier_lifesteal:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_lifesteal:GetTexture()
	if self:GetAbility():GetAbilityName() == "item_lightning_sword" then
		return "item_lightning_sword"
	end

	return "modifiers/lifesteal_mask"
end

function modifier_lifesteal:OnCreated()
	if not IsServer() then return end

	self.particle_lifesteal = "particles/generic_gameplay/generic_lifesteal.vpcf"
end

function modifier_lifesteal:DeclareFunctions() return {
	MODIFIER_EVENT_ON_ATTACK_LANDED,
} end

function modifier_lifesteal:OnAttackLanded(keys)
	if not IsServer() then return end

	local attacker = keys.attacker
	local top_priority_item = nil

	if self:GetParent() ~= attacker then return end

	local target = keys.target
	local lifesteal_pct = 0

	-- If there's no valid target, or lifesteal amount, do nothing
	if target:IsBuilding() or (target:GetTeam() == attacker:GetTeam()) then
		return
	end

	for k, v in ipairs(MODIFIER_ITEMS_WITH_LEVELS[self:GetName()]) do
		local item = self:GetParent():FindItemInInventory(v)
		local ability = self:GetParent():FindAbilityByName(v)

		if item then
			top_priority_item = item:GetName()
			lifesteal_pct = item:GetSpecialValueFor("lifesteal_pct")
			break
		else
			if ability then
				top_priority_item = ability:GetName()
				lifesteal_pct = ability:GetSpecialValueFor("lifesteal_pct")
			end
		end
	end

	if top_priority_item ~= self:GetAbility():GetAbilityName() then return end

	if lifesteal_pct <= 0 then
		return
	end

	-- Calculate actual lifesteal amount
	local damage = attacker:GetRealDamageDone(target)
	if damage < 0 then return end
	local heal = damage * lifesteal_pct / 100
	SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, self:GetParent(), heal, nil)

	-- Heal and fire the particle
	attacker:Heal(heal, attacker)
	local lifesteal_pfx = ParticleManager:CreateParticle(self.particle_lifesteal, PATTACH_ABSORIGIN_FOLLOW, attacker)
	ParticleManager:SetParticleControl(lifesteal_pfx, 0, attacker:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(lifesteal_pfx)
end

function modifier_lifesteal:OnDestroy()
	if not IsServer() then return end

	-- fix with Vampiric Aura interaction
--	if self:GetParent():HasItemInInventory("item_lifesteal_mask") then
--		self:GetParent():AddNewModifier(self:GetParent(), self, "modifier_lifesteal", {})
--	end
end

--[[
function modifier_lifesteal:GetModifierLifesteal()
	if self:GetParent():FindAllModifiersByName(self:GetName())[1] == self then
		return self:GetAbility():GetSpecialValueFor("lifesteal_pct")
	end

	if self:GetAbility() == nil then
		self:GetCaster():RemoveModifierByName("modifier_lifesteal")
		return
	end
end
--]]
