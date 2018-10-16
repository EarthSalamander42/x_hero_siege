-- Fire boss (fire altar) owner aura

-- Aura ability
frostivus_altar_aura_fire = class({})

function frostivus_altar_aura_fire:GetIntrinsicModifierName() return "modifier_frostivus_altar_aura_fire" end

-- Aura emitter
LinkLuaModifier("modifier_frostivus_altar_aura_fire", "boss_scripts/aura_abilities/frostivus_altar_aura_fire.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_altar_aura_fire = modifier_frostivus_altar_aura_fire or class({})

function modifier_frostivus_altar_aura_fire:IsHidden() return true end
function modifier_frostivus_altar_aura_fire:IsPurgable() return false end
function modifier_frostivus_altar_aura_fire:IsDebuff() return false end

function modifier_frostivus_altar_aura_fire:OnCreated()
	if IsServer() then
		self:StartIntervalThink(1.0)
	end
end

function modifier_frostivus_altar_aura_fire:OnIntervalThink()
	if IsServer() then
		
		-- Iterate through aura targets
		local team = self:GetCaster():GetTeam()
		local stacks = self:GetStackCount()
		local caster = self:GetCaster()
		local ability = self:GetAbility()
		local all_heroes = HeroList:GetAllHeroes()
		for _, hero in pairs(all_heroes) do
			if hero:IsRealHero() and hero:GetTeam() == team then
				if not hero:HasModifier("modifier_frostivus_altar_aura_fire_buff") then
					hero:AddNewModifier(caster, ability, "modifier_frostivus_altar_aura_fire_buff", {})
				end
				hero:FindModifierByName("modifier_frostivus_altar_aura_fire_buff"):SetStackCount(stacks)
			end
		end
	end
end

-- Aura buff
LinkLuaModifier("modifier_frostivus_altar_aura_fire_buff", "boss_scripts/aura_abilities/frostivus_altar_aura_fire.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_altar_aura_fire_buff = modifier_frostivus_altar_aura_fire_buff or class({})

function modifier_frostivus_altar_aura_fire_buff:IsHidden() return false end
function modifier_frostivus_altar_aura_fire_buff:IsPurgable() return false end
function modifier_frostivus_altar_aura_fire_buff:IsDebuff() return false end
function modifier_frostivus_altar_aura_fire_buff:IsPermanent() return true end

function modifier_frostivus_altar_aura_fire_buff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_BONUS_NIGHT_VISION
	}
	return funcs
end

function modifier_frostivus_altar_aura_fire_buff:GetModifierBaseDamageOutgoing_Percentage()
	return 20 + 10 * self:GetStackCount()
end

function modifier_frostivus_altar_aura_fire_buff:GetModifierSpellAmplify_Percentage()
	return 8 + 4 * self:GetStackCount()
end

function modifier_frostivus_altar_aura_fire_buff:GetBonusNightVision()
	return 150 + 50 * self:GetStackCount()
end