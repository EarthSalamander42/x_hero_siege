function Immolation(event)
	local manacost_per_second = 10

	if event.caster:GetMana() >= manacost_per_second then
		event.caster:SpendMana(manacost_per_second, event.ability)
	else
		event.ability:ToggleAbility()
	end
end

--------------------------------------

LinkLuaModifier("modifier_xhs_vampiric_aura", "abilities/heroes/hero_demon_hunter.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_vampiric", "abilities/heroes/hero_demon_hunter.lua", LUA_MODIFIER_MOTION_NONE)

xhs_vampiric_aura = xhs_vampiric_aura or class({})
holdout_muradin_hammer = xhs_vampiric_aura

function xhs_vampiric_aura:GetAbilityTextureName()
	return "custom/holdout_thirst_aura"
end

function xhs_vampiric_aura:GetIntrinsicModifierName()
	return "modifier_xhs_vampiric_aura"
end

-- Fountain aura
modifier_xhs_vampiric_aura = modifier_xhs_vampiric_aura or class({})

function modifier_xhs_vampiric_aura:OnCreated()
	self.caster = self:GetCaster()
	self.ability = self:GetAbility()
	if not self.ability or not self.caster:IsRealHero() then
		self:Destroy()
		return nil
	end

	-- Ability specials
	self.aura_radius = self.ability:GetSpecialValueFor("aura_radius")
	self.aura_stickyness = self.ability:GetSpecialValueFor("aura_stickyness")
end

--ability properties
function modifier_xhs_vampiric_aura:OnRefresh()
	self:OnCreated()
end

function modifier_xhs_vampiric_aura:GetAuraDuration()
	return self.aura_stickyness
end

function modifier_xhs_vampiric_aura:GetAuraRadius()
	return self.aura_radius
end

function modifier_xhs_vampiric_aura:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_PLAYER_CONTROLLED
end

function modifier_xhs_vampiric_aura:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_xhs_vampiric_aura:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_xhs_vampiric_aura:GetModifierAura()
	return "modifier_xhs_vampiric"
end

function modifier_xhs_vampiric_aura:IsAura() return true end

function modifier_xhs_vampiric_aura:IsDebuff() return false end

function modifier_xhs_vampiric_aura:IsHidden() return false end

modifier_xhs_vampiric = modifier_xhs_vampiric or class({})

function modifier_xhs_vampiric:GetModifierLifesteal()
	return self:GetAbility():GetSpecialValueFor("lifesteal_pct")
end

-------------------------------------------------------

function Roar(event)
	local caster = event.caster
	EmitSoundOnLocationForAllies(caster:GetAbsOrigin(), "Ability.Roar", caster)

	Timers:CreateTimer(1.9, function()
		caster:StopSound("Ability.Roar")
	end)
end

function ModelSwapStart(keys)
	local caster = keys.caster
	local model = keys.model
	local projectile_model = keys.projectile_model

	if caster.caster_model == nil then
		caster.caster_model = caster:GetModelName()
	end
	caster.caster_attack = caster:GetAttackCapability()

	caster:SetOriginalModel(model)
	caster:SetRangedProjectileName(projectile_model)
	caster:SetAttackCapability(DOTA_UNIT_CAP_RANGED_ATTACK)
end

function ModelSwapEnd(keys)
	local caster = keys.caster

	caster:SetModel(caster.caster_model)
	caster:SetOriginalModel(caster.caster_model)
	caster:SetAttackCapability(caster.caster_attack)
end

function HideWearables(event)
	local hero = event.caster
	local ability = event.ability
	local duration = ability:GetLevelSpecialValueFor("duration", ability:GetLevel() - 1)
	hero.hiddenWearables = {} -- Keep every wearable handle in a table, as its way better to iterate than in the MovePeer system
	print("Hiding Wearables")
	local model = hero:FirstMoveChild()
	--hero:AddNoDraw() -- Doesn't work on classname dota_item_wearable
	while model ~= nil do
		if model:GetClassname() == "dota_item_wearable" then
			model:AddEffects(EF_NODRAW)
			table.insert(hero.hiddenWearables, model)
		end
		model = model:NextMovePeer()
	end
end

function ShowWearables(event)
	local hero = event.caster

	for i, v in ipairs(hero.hiddenWearables) do
		v:RemoveEffects(EF_NODRAW)
	end
end
