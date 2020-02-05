LinkLuaModifier("modifier_ring_of_superiority", "items/ring_of_superiority.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_endurance_buff", "modifiers/auras/modifier_endurance_aura.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_unholy_buff", "modifiers/auras/modifier_unholy_aura.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_devotion_buff", "items/ring_of_superiority.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_command_buff", "modifiers/auras/modifier_command_aura.lua", LUA_MODIFIER_MOTION_NONE)

item_ring_of_superiority = item_ring_of_superiority or class({})

function item_ring_of_superiority:GetIntrinsicModifierName()
	return "modifier_ring_of_superiority"
end

modifier_ring_of_superiority = modifier_ring_of_superiority or class({})

function modifier_ring_of_superiority:OnCreated()
	if not IsServer() then return end

	if self:GetParent():IsRealHero() and _G.SOGAT_ARTIFACT_PICKED == false then
		_G.SOGAT_ARTIFACT_PICKED = true

		if timers.Ramero then
			Timers:RemoveTimer(timers.Ramero)
		end

		ReturnFromSpecialArena(self:GetParent())
	end

	self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_endurance_buff", {})
	self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_unholy_buff", {})
	self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_devotion_buff", {})
	self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_command_buff", {})
end

function modifier_ring_of_superiority:OnRemoved()
	if not IsServer() then return end

	self:GetParent():RemoveModifierByName("modifier_endurance_buff")
	self:GetParent():RemoveModifierByName("modifier_unholy_buff")
	self:GetParent():RemoveModifierByName("modifier_devotion_buff")
	self:GetParent():RemoveModifierByName("modifier_command_buff")
end

modifier_devotion_buff = modifier_devotion_buff or class({})

function modifier_devotion_buff:DeclareFunctions() return {
	MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
} end

function modifier_devotion_buff:OnCreated()
	if not IsServer() then return end

	self.pfx = ParticleManager:CreateParticle("particles/items_fx/aura_shivas.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
end

function modifier_devotion_buff:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("bonus_armor")
end

function modifier_devotion_buff:OnDestroy()
	if not IsServer() then return end

	if self.pfx then
		ParticleManager:DestroyParticle(self.pfx, false)
		ParticleManager:ReleaseParticleIndex(self.pfx)
	end
end
