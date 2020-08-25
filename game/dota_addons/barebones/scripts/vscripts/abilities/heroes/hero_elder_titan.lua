LinkLuaModifier("modifier_endurance_aura", "modifiers/auras/modifier_endurance_aura.lua", LUA_MODIFIER_MOTION_NONE)

holdout_chieftain_endurance_aura = holdout_chieftain_endurance_aura or class({})

function holdout_chieftain_endurance_aura:GetIntrinsicModifierName()
	return "modifier_endurance_aura"
end
