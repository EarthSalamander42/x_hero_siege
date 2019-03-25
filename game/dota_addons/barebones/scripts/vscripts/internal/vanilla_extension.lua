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

-- credits to yahnich for the following
function CDOTA_BaseNPC:IsFakeHero()
	if self:IsIllusion() or (self:HasModifier("modifier_monkey_king_fur_army_soldier") or self:HasModifier("modifier_monkey_king_fur_army_soldier_hidden")) or self:IsTempestDouble() or self:IsClone() then
		return true
	else return false end
end

function CDOTA_BaseNPC:IsRealHero()
	if not self:IsNull() then
		return self:IsHero() and not ( self:IsIllusion() or self:IsClone() ) and not self:IsFakeHero()
	end
end

function CDOTA_BaseNPC:Blink(position, bTeamOnlyParticle, bPlaySound)
	if self:IsNull() then return end
	local blink_effect = "particles/items_fx/blink_dagger_start.vpcf"
	local blink_effect_end = "particles/items_fx/blink_dagger_end.vpcf"
	local blink_sound = "DOTA_Item.BlinkDagger.Activate"
	if self.blink_effect or self:GetPlayerOwner().blink_effect then blink_effect = self.blink_effect end
	if self.blink_effect_end or self:GetPlayerOwner().blink_effect_end then blink_effect_end = self.blink_effect_end end
	if self.blink_sound or self:GetPlayerOwner().blink_sound then blink_sound = self.blink_sound end
	if bPlaySound == true then EmitSoundOn(blink_sound, self) end
	if bTeamOnlyParticle == true then
		local blink_pfx = ParticleManager:CreateParticleForTeam(blink_effect, PATTACH_ABSORIGIN, self, self:GetTeamNumber())
		ParticleManager:ReleaseParticleIndex(blink_pfx)
	else
		ParticleManager:FireParticle(blink_effect, PATTACH_ABSORIGIN, self, {[0] = self:GetAbsOrigin()})
	end
	FindClearSpaceForUnit(self, position, true)
	ProjectileManager:ProjectileDodge( self )
	if bTeamOnlyParticle == true then
		local blink_end_pfx = ParticleManager:CreateParticleForTeam(blink_effect_end, PATTACH_ABSORIGIN, self, self:GetTeamNumber())
		ParticleManager:ReleaseParticleIndex(blink_end_pfx)
	else
		ParticleManager:FireParticle(blink_effect_end, PATTACH_ABSORIGIN, self, {[0] = self:GetAbsOrigin()})
	end
	if bPlaySound == true then EmitSoundOn("DOTA_Item.BlinkDagger.NailedIt", self) end
end
