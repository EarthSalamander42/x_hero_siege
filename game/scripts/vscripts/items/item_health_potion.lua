item_health_potion = class({})

local SupporterRecoveryEffects = require("components/battlepass/recovery_effects"):Init()
local HEALTH_POTION_PARTICLE = "particles/items3_fx/fish_bones_active.vpcf"

function item_health_potion:GetAbilityTextureName()
	return "custom/health_potion"
end

function item_health_potion:OnSpellStart()
	self.heal = self:GetSpecialValueFor("hp_restore")

	if IsServer() then
		self:GetCaster():EmitSoundParams("DOTA_Item.FaerieSpark.Activate", 0, 0.5, 0)
		self:GetCaster():Heal(self.heal, self)
		SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, self:GetCaster(), self.heal, nil)

		XHSRecordPotionUse(self:GetCaster(), self:GetAbilityName())

		SupporterRecoveryEffects:PlayPotion(self:GetCaster(), "health", HEALTH_POTION_PARTICLE)

		self:SpendCharge(0.0)
	end
end
