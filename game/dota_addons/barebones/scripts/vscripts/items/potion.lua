require('libraries/timers')

function FullRestauration(event)
local caster = event.caster
local ability = event.ability
local MaxHealth = caster:GetMaxHealth()
local MaxMana = caster:GetMaxMana()

	caster:SetHealth(MaxHealth)
	caster:SetMana(MaxMana)
end

function Invulnerability(event)
local caster = event.caster
local ability = event.ability
local duration = ability:GetLevelSpecialValueFor("duration", (ability:GetLevel() - 1))

	caster:AddNewModifier( caster, nil, "modifier_invulnerable", {duration = duration})
end
