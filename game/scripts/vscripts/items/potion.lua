function FullRestauration(event)
local caster = event.caster
local ability = event.ability
local Health = 30000
local Mana = 30000

	caster:Heal(Health, caster)
	SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, caster, Health, nil)
	caster:SetMana(caster:GetMana() + Mana)
	SendOverheadEventMessage(nil, OVERHEAD_ALERT_MANA_ADD, caster, Mana, nil)

	for _, Zone in pairs(GameRules.GameMode.Zones) do
		if Zone:ContainsUnit(caster) then
			Zone:AddStat(caster:GetPlayerID(), ZONE_STAT_POTIONS, 1)
		end
	end
end

function Invulnerability(event)
local caster = event.caster
local ability = event.ability
local duration = ability:GetLevelSpecialValueFor("duration", (ability:GetLevel() - 1))

	caster:AddNewModifier( caster, nil, "modifier_invulnerable", {duration = duration})

	for _, Zone in pairs(GameRules.GameMode.Zones) do
		if Zone:ContainsUnit(caster) then
			Zone:AddStat(caster:GetPlayerID(), ZONE_STAT_POTIONS, 1)
		end
	end
end
