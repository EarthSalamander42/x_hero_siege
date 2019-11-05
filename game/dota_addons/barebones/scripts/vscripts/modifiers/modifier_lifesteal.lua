-- Lifesteal modifier

modifier_lifesteal = class({})

function modifier_lifesteal:GetAbilityTextureName()
	return "modifiers/lifesteal_mask"
end

function modifier_lifesteal:GetTexture()
	return "modifiers/lifesteal_mask"
end

function modifier_lifesteal:OnCreated()
	self.caster = self:GetCaster()
	self.ability = self:GetAbility()
	self.particle_lifesteal = "particles/generic_gameplay/generic_lifesteal.vpcf"
end

function modifier_lifesteal:DeclareFunctions()
	local decFunc = {
	MODIFIER_EVENT_ON_ATTACK_LANDED}

	return decFunc
end

function modifier_lifesteal:OnAttackLanded(keys)
	if IsServer() then
		local parent = self:GetParent()
		local attacker = keys.attacker

		if parent ~= attacker then return end

		local target = keys.target
		local lifesteal_amount = attacker:GetLifesteal()

		-- If there's no valid target, or lifesteal amount, do nothing
		if target:IsBuilding() or (target:GetTeam() == attacker:GetTeam()) or lifesteal_amount <= 0 then
			return
		end

		-- Calculate actual lifesteal amount
		local damage = keys.damage
		local target_armor = target:GetPhysicalArmorValue(false)
		local heal = damage * lifesteal_amount * 0.01 * GetReductionFromArmor(target_armor) * 0.01
		SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, parent, heal, nil)

		-- Heal and fire the particle
		attacker:Heal(heal, attacker)
		local lifesteal_pfx = ParticleManager:CreateParticle(self.particle_lifesteal, PATTACH_ABSORIGIN_FOLLOW, attacker)
		ParticleManager:SetParticleControl(lifesteal_pfx, 0, attacker:GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(lifesteal_pfx)
	end
end

function modifier_lifesteal:OnDestroy()
	if IsServer() then
		-- fix with Vampiric Aura interaction
		if self:GetParent():HasItemInInventory("item_lifesteal_mask") then
			self:GetParent():AddNewModifier(self:GetParent(), self, "modifier_lifesteal", {})
		end
	end
end

function modifier_lifesteal:IsHidden() return false end
function modifier_lifesteal:IsPurgable() return false end
function modifier_lifesteal:IsDebuff() return false end

--	function modifier_lifesteal:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_lifesteal:GetModifierLifesteal()
	if self:GetAbility() == nil then
		self:GetCaster():RemoveModifierByName("modifier_lifesteal")
		return
	end

	return self:GetAbility():GetSpecialValueFor("lifesteal_pct")
end
