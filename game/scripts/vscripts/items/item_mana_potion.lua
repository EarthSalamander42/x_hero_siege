item_mana_potion = class({})

function item_mana_potion:GetAbilityTextureName()
	return "custom/mana_potion"
end

function item_mana_potion:OnSpellStart()
	if IsServer() then
		self:GetCaster():EmitSoundParams("DOTA_Item.Mango.Activate", 0, 0.5, 0)
		self:GetCaster():GiveMana(self:GetSpecialValueFor("mana_restore"))
		SendOverheadEventMessage(nil, OVERHEAD_ALERT_MANA_ADD, self:GetCaster(), self:GetSpecialValueFor("mana_restore"), nil)
		for _, Zone in pairs(GameRules.GameMode.Zones) do
			if Zone:ContainsUnit(self:GetCaster()) then
				Zone:AddStat(self:GetCaster():GetPlayerID(), ZONE_STAT_POTIONS, 1)
			end
		end

		local nFXIndex = ParticleManager:CreateParticle("particles/items3_fx/mango_active.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
		ParticleManager:ReleaseParticleIndex(nFXIndex)

		self:SpendCharge(0.0)
	end
end
