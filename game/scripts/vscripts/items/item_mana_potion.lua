item_mana_potion = class({})

local SupporterRecoveryEffects = require("components/battlepass/recovery_effects"):Init()
local MANA_POTION_PARTICLE = "particles/items3_fx/mango_active.vpcf"

function item_mana_potion:GetAbilityTextureName()
	return "custom/mana_potion"
end

function item_mana_potion:OnSpellStart()
	if IsServer() then
		self:GetCaster():EmitSoundParams("DOTA_Item.Mango.Activate", 0, 0.5, 0)
		self:GetCaster():GiveMana(self:GetSpecialValueFor("mana_restore"))
		SendOverheadEventMessage(nil, OVERHEAD_ALERT_MANA_ADD, self:GetCaster(), self:GetSpecialValueFor("mana_restore"), nil)
		XHSRecordPotionUse(self:GetCaster(), self:GetAbilityName())

		SupporterRecoveryEffects:PlayPotion(self:GetCaster(), "mana", MANA_POTION_PARTICLE)

		self:SpendCharge(0.0)
	end
end
