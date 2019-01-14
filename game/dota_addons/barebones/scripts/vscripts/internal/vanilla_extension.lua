function GetReductionFromArmor(armor)
	return ( 0.052 * armor ) / ( 0.9 + 0.048 * armor)
end

function CDOTA_BaseNPC:GetLifesteal()
	local lifesteal = 0

	-- useless atm because modifier can't have multiple instances, find a way to call lifefsteal attack once
	for _, parent_modifier in pairs(self:FindAllModifiers()) do
		if parent_modifier.GetModifierLifesteal then
			if parent_modifier:GetModifierLifesteal() > lifesteal then
				lifesteal = parent_modifier:GetModifierLifesteal()
			end
		end
	end

	return lifesteal
end

function CDOTA_BaseNPC:GetRealDamageDone(hTarget)
	local base_damage = self:GetAverageTrueAttackDamage(hTarget)
	local armor_reduction = GetReductionFromArmor(hTarget:GetPhysicalArmorValue())
	return base_damage - (base_damage * armor_reduction)
end

function CDOTA_BaseNPC:Lifesteal(hTarget, modifier)
	local lifesteal = self:GetLifesteal()
	-- If there's no valid target, or lifesteal amount, do nothing
	if hTarget:IsBuilding() or (hTarget:GetTeam() == self:GetTeam()) or lifesteal <= 0 then
		return
	end

	for _, modifier_name in ipairs(_G.XHS_LIFESTEAL_MODIFIER_PRIORITY) do
		if self:HasModifier(modifier:GetName()) then
			print(_G.XHS_LIFESTEAL_MODIFIER_PRIORITY[modifier:GetName()])
			print(_G.XHS_LIFESTEAL_MODIFIER_PRIORITY[modifier_name])
			if _G.XHS_LIFESTEAL_MODIFIER_PRIORITY[modifier_name] < _G.XHS_LIFESTEAL_MODIFIER_PRIORITY[modifier:GetName()] then
				return
			end
		end
	end

	-- Calculate actual lifesteal amount
	local damage = self:GetRealDamageDone(hTarget)
	if damage < 0 then return end
	local heal = damage * lifesteal / 100
	SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, self, heal, nil)

	-- Heal and fire the particle
	self:Heal(heal, self)
	local lifesteal_pfx = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, self)
	ParticleManager:SetParticleControl(lifesteal_pfx, 0, self:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(lifesteal_pfx)
end

function CDOTA_BaseNPC:FindItemByName(ItemName, bStash)
	local count = 8

	if bStash == true then
		count = 14
	end

	for slot = 0, count do
		local item = self:GetItemInSlot(slot)
		if item then
			if item:GetName() == ItemName then
				return item
			end
		end
	end

	return nil
end

function CDOTA_BaseNPC:RemoveItemByName(ItemName, bStash)
	local count = 8

	if bStash == true then
		count = 14
	end

	for slot = 0, count do
		local item = self:GetItemInSlot(slot)
		if item then
			if item:GetName() == ItemName then
				self:RemoveItem(item)
				break
			end
		end
	end
end
