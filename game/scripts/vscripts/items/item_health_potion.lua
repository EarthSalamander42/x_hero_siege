item_health_potion = class({})

function item_health_potion:GetAbilityTextureName()
	return "custom/health_potion"
end

function item_health_potion:OnSpellStart()
	if IsServer() then
		self:GetCaster():EmitSoundParams("DOTA_Item.FaerieSpark.Activate", 0, 0.5, 0)
		self:GetCaster():Heal(self:GetSpecialValueFor("hp_restore"), self)
		SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, self:GetCaster(), self:GetSpecialValueFor("hp_restore"), nil)
		for _, Zone in pairs(GameRules.GameMode.Zones) do
			if Zone:ContainsUnit(self:GetCaster()) then
				Zone:AddStat(self:GetCaster():GetPlayerID(), ZONE_STAT_POTIONS, 1)
			end
		end

		local nFXIndex = ParticleManager:CreateParticle("particles/items3_fx/fish_bones_active.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster())
		ParticleManager:ReleaseParticleIndex(nFXIndex)

		self:SpendCharge()
	end
end
