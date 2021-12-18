-----------------------------------------------------------------------------------------------------------
--	Item Definition
-----------------------------------------------------------------------------------------------------------
if item_xhs_cloak_of_flames == nil then item_xhs_cloak_of_flames = class({}) end
LinkLuaModifier( "modifier_xhs_cloak_of_flames_basic", "items/item_cloak_of_flames.lua", LUA_MODIFIER_MOTION_NONE )			-- Item stats
LinkLuaModifier( "modifier_xhs_cloak_of_flames_aura", "items/item_cloak_of_flames.lua", LUA_MODIFIER_MOTION_NONE )			-- Aura
LinkLuaModifier( "modifier_xhs_cloak_of_flames_burn", "items/item_cloak_of_flames.lua", LUA_MODIFIER_MOTION_NONE )			-- Damage + blind effect

function item_xhs_cloak_of_flames:GetIntrinsicModifierName()
	return "modifier_xhs_cloak_of_flames_basic" end

function item_xhs_cloak_of_flames:OnSpellStart()
	if IsServer() then
		if self:GetCaster():HasModifier("modifier_xhs_cloak_of_flames_aura") then
			self:GetCaster():RemoveModifierByName("modifier_xhs_cloak_of_flames_aura")
		else
			self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_xhs_cloak_of_flames_aura", {})
		end
	end
end

-----------------------------------------------------------------------------------------------------------
--	Basic modifier definition
-----------------------------------------------------------------------------------------------------------
if modifier_xhs_cloak_of_flames_basic == nil then modifier_xhs_cloak_of_flames_basic = class({}) end

function modifier_xhs_cloak_of_flames_basic:IsHidden() return true end
function modifier_xhs_cloak_of_flames_basic:IsPurgable() return false end
function modifier_xhs_cloak_of_flames_basic:RemoveOnDeath() return false end
function modifier_xhs_cloak_of_flames_basic:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

-- Adds the unique modifier to the owner when created
function modifier_xhs_cloak_of_flames_basic:OnCreated(keys)
	if IsServer() then
        if not self:GetAbility() then self:Destroy() end
    end

	if IsServer() then
		if not self:GetParent():HasModifier("modifier_xhs_cloak_of_flames_aura") then
			self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_xhs_cloak_of_flames_aura", {})
		end

		if self.particle == nil then
			self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_ember_spirit/ember_spirit_flameguard.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
			ParticleManager:SetParticleControl(self.particle, 0, Vector(0, 0, 0))
			ParticleManager:SetParticleControl(self.particle, 1, Vector(self:GetAbility():GetSpecialValueFor("radius"), 1, 1))
		end
	end
end

-- Removes the unique modifier from the owner if this is the last Radiance in its inventory
function modifier_xhs_cloak_of_flames_basic:OnDestroy(keys)
	if IsServer() then
		if not self:GetParent():HasModifier("modifier_xhs_cloak_of_flames_basic") then
			self:GetParent():RemoveModifierByName("modifier_xhs_cloak_of_flames_aura")
		end
	end
	
	if self.particle ~= nil then
		ParticleManager:DestroyParticle(self.particle, false)
		ParticleManager:ReleaseParticleIndex(self.particle)
		self.particle = nil
	end
end

-----------------------------------------------------------------------------------------------------------
--	Aura definition
-----------------------------------------------------------------------------------------------------------
if modifier_xhs_cloak_of_flames_aura == nil then modifier_xhs_cloak_of_flames_aura = class({}) end
function modifier_xhs_cloak_of_flames_aura:IsAura() return true end
function modifier_xhs_cloak_of_flames_aura:IsHidden() return true end
function modifier_xhs_cloak_of_flames_aura:IsDebuff() return false end
function modifier_xhs_cloak_of_flames_aura:IsPurgable() return false end

function modifier_xhs_cloak_of_flames_aura:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY end

function modifier_xhs_cloak_of_flames_aura:GetAuraSearchType()
	return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end

function modifier_xhs_cloak_of_flames_aura:GetModifierAura()
	return "modifier_xhs_cloak_of_flames_burn"
end

function modifier_xhs_cloak_of_flames_aura:GetAuraRadius()
	return self:GetAbility():GetSpecialValueFor("radius")
end

-----------------------------------------------------------------------------------------------------------
--	Aura effect (damage)
-----------------------------------------------------------------------------------------------------------
if modifier_xhs_cloak_of_flames_burn == nil then modifier_xhs_cloak_of_flames_burn = class({}) end
function modifier_xhs_cloak_of_flames_burn:IsHidden() return false end
function modifier_xhs_cloak_of_flames_burn:IsDebuff() return true end
function modifier_xhs_cloak_of_flames_burn:IsPurgable() return false end

function modifier_xhs_cloak_of_flames_burn:GetTexture()
	return "modifiers/cloak_of_flames"
end

function modifier_xhs_cloak_of_flames_burn:OnCreated()
	if not self:GetAbility() then self:Destroy() return end
	
	self.base_damage	= self:GetAbility():GetSpecialValueFor("damage_per_tick")
	self.think_interval	= self:GetAbility():GetSpecialValueFor("tick_time")

	if IsServer() then
		self:StartIntervalThink(self.think_interval)
	end
end

function modifier_xhs_cloak_of_flames_burn:OnIntervalThink()
	if self:GetAbility() then
		ApplyDamage({
			victim = self:GetParent(),
			attacker = self:GetCaster(),
			ability = self:GetAbility(),
			damage = self.base_damage,
			damage_type = DAMAGE_TYPE_MAGICAL
		})
	end
end