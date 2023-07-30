--[[
			Author: MouJiaoZi / (MIRROR IMAGE)
			Date: 2017/12/06 YYYY/MM/DD
			Modified by: EarthSalamander #42
]]
   --

xhs_blademaster_mirror_image = xhs_blademaster_mirror_image or class({})

LinkLuaModifier("modifier_xhs_blademaster_mirror_image_invulnerable", "abilities/heroes/hero_blademaster.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_xhs_blademaster_mirror_image_handler", "abilities/heroes/hero_blademaster.lua", LUA_MODIFIER_MOTION_NONE)

function xhs_blademaster_mirror_image:IsHiddenWhenStolen() return false end

function xhs_blademaster_mirror_image:IsRefreshable() return true end

function xhs_blademaster_mirror_image:IsStealable() return true end

function xhs_blademaster_mirror_image:IsNetherWardStealable() return false end

function xhs_blademaster_mirror_image:GetIntrinsicModifierName()
	return "modifier_xhs_blademaster_mirror_image_handler"
end

function xhs_blademaster_mirror_image:GetAbilityTextureName()
	if IsServer() or not self:GetCaster().mirror_image_icon_client then return "" end

	if self:GetCaster().mirror_image_icon_client == 1 then
		return "custom/blademaster_mirror_image"
	elseif self:GetCaster().mirror_image_icon_client == 2 then
		return "naga_siren_mirror_image"
	end
end

function xhs_blademaster_mirror_image:OnSpellStart()
	if IsClient() then return end

	local distance_between_illusions = 108
	local vRandomSpawnPos = {
		Vector(distance_between_illusions, 0, 0),
		Vector(distance_between_illusions, distance_between_illusions, 0),
		Vector(distance_between_illusions, 0, 0),
		Vector(0, distance_between_illusions, 0),
		Vector(-distance_between_illusions, 0, 0),
		Vector(-distance_between_illusions, distance_between_illusions, 0),
		Vector(-distance_between_illusions, -distance_between_illusions, 0),
		Vector(0, -distance_between_illusions, 0),
	}

	local pfx = ParticleManager:CreateParticle("particles/items2_fx/manta_phase.vpcf", PATTACH_ABSORIGIN, self:GetCaster())
	self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_xhs_blademaster_mirror_image_invulnerable", { duration = self:GetSpecialValueFor("invuln_duration") })

	if self:GetCaster():GetUnitName() == "npc_dota_hero_juggernaut" then
		EmitSoundOn("Blademaster.MirrorImage", self:GetCaster())
	elseif self:GetCaster():GetUnitName() == "npc_dota_hero_naga_siren" then
		EmitSoundOn("Hero_NagaSiren.MirrorImage", self:GetCaster())
	end

	if self.illusions then
		for _, illusion in pairs(self.illusions) do
			if IsValidEntity(illusion) and illusion:IsAlive() then
				illusion:Kill(nil, nil)
			end
		end
	end

	self:GetCaster():SetContextThink(DoUniqueString("blademaster_mirror_image"), function()
		-- "API Additions - Global (Server): * CreateIllusions( hOwner, hHeroToCopy, hModifierKeys, nNumIllusions, nPadding, bScramblePosition, bFindClearSpace ) Note: See script_help2 for supported modifier keys"
		self.illusions = CreateIllusions(self:GetCaster(), self:GetCaster(), {
			outgoing_damage           = self:GetSpecialValueFor("outgoing_damage"),
			incoming_damage           = self:GetSpecialValueFor("incoming_damage"),
			bounty_base               = self:GetCaster():GetLevel() * 2,
			bounty_growth             = nil,
			outgoing_damage_structure = nil,
			outgoing_damage_roshan    = nil,
			duration                  = self:GetSpecialValueFor("illusion_duration")
		}, self:GetSpecialValueFor("images_count"), self:GetCaster():GetHullRadius(), true, true)

		for i = 1, #self.illusions do
			local illusion = self.illusions[i]
			local pos = self:GetCaster():GetAbsOrigin() + vRandomSpawnPos[i]
			FindClearSpaceForUnit(illusion, pos, true)
			local part2 = ParticleManager:CreateParticle("particles/units/heroes/hero_siren/naga_siren_riptide_foam.vpcf", PATTACH_ABSORIGIN, illusion)
			ParticleManager:ReleaseParticleIndex(part2)
			illusion:MoveToPositionAggressive(self:GetCaster():GetAbsOrigin())
			--			self:SetInventory(illusion) -- not working yet
		end

		ParticleManager:DestroyParticle(pfx, false)
		ParticleManager:ReleaseParticleIndex(pfx)

		self:GetCaster():Stop()

		return nil
	end, self:GetSpecialValueFor("invuln_duration"))
end

function xhs_blademaster_mirror_image:SetInventory(illusion)
	local shared_modifiers = {
		"modifier_rune_armor",
		--		"modifier_rune_immolation",
	}

	for _, v in pairs(shared_modifiers) do
		if self:GetCaster():HasModifier(v) then
			local duration = self:GetCaster():FindModifierByName(v):GetRemainingTime()
			illusion:AddNewModifier(illusion, nil, v, { duration = duration })
		end
	end
end

modifier_xhs_blademaster_mirror_image_invulnerable = modifier_xhs_blademaster_mirror_image_invulnerable or class({})

function modifier_xhs_blademaster_mirror_image_invulnerable:IsHidden() return true end

function modifier_xhs_blademaster_mirror_image_invulnerable:CheckState()
	local state =
	{
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_OUT_OF_GAME] = true,
	}

	return state
end

if modifier_xhs_blademaster_mirror_image_handler == nil then modifier_xhs_blademaster_mirror_image_handler = class({}) end
function modifier_xhs_blademaster_mirror_image_handler:IsHidden() return true end

function modifier_xhs_blademaster_mirror_image_handler:IsPurgable() return false end

function modifier_xhs_blademaster_mirror_image_handler:RemoveOnDeath() return false end

function modifier_xhs_blademaster_mirror_image_handler:OnCreated()
	self:StartIntervalThink(1.0)
	self:OnIntervalThink()
end

function modifier_xhs_blademaster_mirror_image_handler:OnIntervalThink()
	if self:GetCaster():IsIllusion() then return end

	if IsServer() then
		if self:GetParent():GetUnitName() == "npc_dota_hero_juggernaut" then
			self:SetStackCount(1)
		elseif self:GetParent():GetUnitName() == "npc_dota_hero_naga_siren" then
			self:SetStackCount(2)
		end
	end

	if IsClient() then
		self:GetCaster().mirror_image_icon_client = self:GetStackCount()
	end
end

LinkLuaModifier("modifier_blademaster_wardrums_aura", "abilities/heroes/hero_blademaster", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_blademaster_wardrums", "abilities/heroes/hero_blademaster", LUA_MODIFIER_MOTION_NONE)

blademaster_wardrums_aura = blademaster_wardrums_aura or class({})

function blademaster_wardrums_aura:GetIntrinsicModifierName() return "modifier_blademaster_wardrums_aura" end

modifier_blademaster_wardrums_aura = modifier_blademaster_wardrums_aura or class({})

-- Modifier properties
function modifier_blademaster_wardrums_aura:IsAura() return true end

function modifier_blademaster_wardrums_aura:IsAuraActiveOnDeath() return false end

function modifier_blademaster_wardrums_aura:IsDebuff() return false end

function modifier_blademaster_wardrums_aura:IsHidden() return true end

function modifier_blademaster_wardrums_aura:IsPermanent() return true end

function modifier_blademaster_wardrums_aura:IsPurgable() return false end

-- Aura properties
function modifier_blademaster_wardrums_aura:GetAuraRadius() return self:GetAbility():GetCastRange() end

function modifier_blademaster_wardrums_aura:GetAuraSearchFlags() return self:GetAbility():GetAbilityTargetFlags() end

function modifier_blademaster_wardrums_aura:GetAuraSearchTeam() return self:GetAbility():GetAbilityTargetTeam() end

function modifier_blademaster_wardrums_aura:GetAuraSearchType() return self:GetAbility():GetAbilityTargetType() end

function modifier_blademaster_wardrums_aura:GetModifierAura() return "modifier_blademaster_wardrums" end

modifier_blademaster_wardrums = modifier_blademaster_wardrums or class({})

-- Modifier properties
function modifier_blademaster_wardrums:IsPurgable() return false end

function modifier_blademaster_wardrums:IsPurgeException() return false end

function modifier_blademaster_wardrums:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
	}
end

function modifier_blademaster_wardrums:GetModifierDamageOutgoing_Percentage()
	return self:GetStackCount()
end
