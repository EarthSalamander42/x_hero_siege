LinkLuaModifier("modifier_ring_of_superiority", "items/ring_of_superiority.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_endurance_buff", "modifiers/auras/modifier_endurance_aura.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_unholy_aura_buff", "items/ring_of_superiority.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_devotion_aura_hidden", "items/ring_of_superiority.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_command_buff", "items/ring_of_superiority.lua", LUA_MODIFIER_MOTION_NONE)

item_ring_of_superiority = item_ring_of_superiority or class({})

function item_ring_of_superiority:GetIntrinsicModifierName()
	return "modifier_ring_of_superiority"
end

modifier_ring_of_superiority = modifier_ring_of_superiority or class({})

--[[
function modifier_ring_of_superiority:DeclareFunctions() return {
} end
--]]

function modifier_ring_of_superiority:OnCreated()
	if not IsServer() then return end

	if _G.SOGAT_ARTIFACT_PICKED == false then
		_G.SOGAT_ARTIFACT_PICKED = true

		if timers.Ramero then
			Timers:RemoveTimer(timers.Ramero)
		end

		ReturnFromSpecialArena(self:GetParent())
	end

	self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_endurance_buff", {})
	self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_unholy_aura_buff", {})
	self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_devotion_aura_hidden", {})
	self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_command_buff", {})
end

modifier_unholy_aura_buff = modifier_unholy_aura_buff or class({})

function modifier_unholy_aura_buff:DeclareFunctions() return {
	MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
	MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
} end

function modifier_unholy_aura_buff:OnCreated()
	if not IsServer() then return end

	self.pfx1 = ParticleManager:CreateParticle("particles/econ/courier/courier_faceless_rex/cour_rex_ground_a.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	self.pfx2 = ParticleManager:CreateParticle("particles/econ/courier/courier_roshan_frost/courier_roshan_frost_steam.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent())
end

function modifier_unholy_aura_buff:GetModifierConstantHealthRegen()
	return self:GetAbility():GetSpecialValueFor("bonus_health_regen")
end

function modifier_unholy_aura_buff:GetModifierMoveSpeedBonus_Constant()
	return self:GetAbility():GetSpecialValueFor("bonus_movement_speed")
end

function modifier_unholy_aura_buff:OnDestroy()
	if not IsServer() then return end

	if self.pfx1 then
		ParticleManager:DestroyParticle(self.pfx1, false)
		ParticleManager:ReleaseParticleIndex(self.pfx1)
	end

	if self.pfx2 then
		ParticleManager:DestroyParticle(self.pfx2, false)
		ParticleManager:ReleaseParticleIndex(self.pfx2)
	end
end

modifier_devotion_aura_hidden = modifier_devotion_aura_hidden or class({})

function modifier_devotion_aura_hidden:DeclareFunctions() return {
	MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
} end

function modifier_devotion_aura_hidden:OnCreated()
	if not IsServer() then return end

	self.pfx = ParticleManager:CreateParticle("particles/items_fx/aura_shivas.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
end

function modifier_devotion_aura_hidden:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_devotion_aura_hidden:OnDestroy()
	if not IsServer() then return end

	if self.pfx then
		ParticleManager:DestroyParticle(self.pfx, false)
		ParticleManager:ReleaseParticleIndex(self.pfx)
	end
end

modifier_command_buff = modifier_command_buff or class({})

function modifier_command_buff:GetTexture()
	return "custom/holdout_command_aura"
end

function modifier_command_buff:DeclareFunctions() return {
	MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
} end

function modifier_command_buff:OnCreated()
	if not IsServer() then return end

	self.pfx = ParticleManager:CreateParticle("particles/items_fx/aura_shivas.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
end

function modifier_command_buff:GetModifierBaseDamageOutgoing_Percentage()
	return self:GetAbility():GetSpecialValueFor("bonus_damage_percentage")
end

function modifier_command_buff:OnDestroy()
	if not IsServer() then return end

	if self.pfx then
		ParticleManager:DestroyParticle(self.pfx, false)
		ParticleManager:ReleaseParticleIndex(self.pfx)
	end
end
