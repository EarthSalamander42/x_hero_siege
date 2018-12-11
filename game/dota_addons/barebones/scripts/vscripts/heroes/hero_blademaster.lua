--[[
			Author: MouJiaoZi / (MIRROR IMAGE)
			Date: 2017/12/06 YYYY/MM/DD
			Modified by: EarthSalamander #42
]]--

xhs_blademaster_mirror_image = xhs_blademaster_mirror_image or class({})

LinkLuaModifier( "modifier_xhs_blademaster_mirror_image_invulnerable", "heroes/hero_blademaster.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier( "modifier_xhs_blademaster_mirror_image_handler", "heroes/hero_blademaster.lua", LUA_MODIFIER_MOTION_NONE )

function xhs_blademaster_mirror_image:IsHiddenWhenStolen() 		return false end
function xhs_blademaster_mirror_image:IsRefreshable() 			return true  end
function xhs_blademaster_mirror_image:IsStealable() 			return true  end
function xhs_blademaster_mirror_image:IsNetherWardStealable() 	return false end

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
	local caster = self:GetCaster()
	local caster_entid = caster:entindex()
	local ability = self
	local delay = ability:GetSpecialValueFor("invuln_duration")
	local image_count = ability:GetSpecialValueFor("images_count")
	local image_out_dmg = ability:GetSpecialValueFor("outgoing_damage")
	local image_in_dmg = ability:GetSpecialValueFor("incoming_damage")
	local image_duration = ability:GetSpecialValueFor("illusion_duration")
	local distance_between_illusions = 150
	local vRandomSpawnPos = {
		Vector( distance_between_illusions, 0, 0 ),
		Vector( distance_between_illusions, distance_between_illusions, 0 ),
		Vector( distance_between_illusions, 0, 0 ),
		Vector( 0, distance_between_illusions, 0 ),
		Vector( -distance_between_illusions, 0, 0 ),
		Vector( -distance_between_illusions, distance_between_illusions, 0 ),
		Vector( -distance_between_illusions, -distance_between_illusions, 0 ),
		Vector( 0, -distance_between_illusions, 0 ),
	}
	local particle = "particles/items2_fx/manta_phase.vpcf"
--	local particle2 = "particles/units/heroes/hero_siren/blademaster_riptide_foam.vpcf"
	local part = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN, caster)
	local buff = caster:AddNewModifier(caster, ability, "modifier_xhs_blademaster_mirror_image_invulnerable", {})
	if caster:GetUnitName() == "npc_dota_hero_juggernaut" then
		EmitSoundOn("Blademaster.MirrorImage", caster)
	elseif caster:GetUnitName() == "npc_dota_hero_naga_siren" then
		EmitSoundOn("Hero_NagaSiren.MirrorImage", caster)
	end
	caster:SetContextThink( DoUniqueString("blademaster_mirror_image"), function ( )
		for i=1, image_count do
			local j = RandomInt(1, #vRandomSpawnPos)
			local pos = caster:GetAbsOrigin() + vRandomSpawnPos[j]
			local illusion = IllusionManager:CreateIllusion(caster, self, pos, caster, {damagein=image_in_dmg, damageout=image_out_dmg, unique=caster_entid.."_siren_image_"..i, duration=image_duration})
			self:SetInventory(illusion) -- not working yet

			table.remove(vRandomSpawnPos,j)
--			local part2 = ParticleManager:CreateParticle(particle2, PATTACH_ABSORIGIN, illusion)
--			ParticleManager:ReleaseParticleIndex(part2)
		end
		ParticleManager:DestroyParticle(part, true)
		ParticleManager:ReleaseParticleIndex(part)
		caster:Stop()
		buff:Destroy()
		return nil
	end, delay)
end

function xhs_blademaster_mirror_image:SetInventory(illusion)
if type(illusion) ~= "table" then return end
	local shared_modifiers = {
		"modifier_rune_armor",
--		"modifier_rune_immolation",
	}

	for _, v in pairs(shared_modifiers) do
		if self:GetCaster():HasModifier(v) then
			local duration = self:GetCaster():FindModifierByName(v):GetRemainingTime()
			illusion:AddNewModifier(illusion, nil, v, {duration=duration})
		end
	end
end

modifier_xhs_blademaster_mirror_image_invulnerable = modifier_xhs_blademaster_mirror_image_invulnerable or class({})

function modifier_xhs_blademaster_mirror_image_invulnerable:IsHidden()
	return true
end

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
function modifier_xhs_blademaster_mirror_image_handler:IsDebuff() return false end
function modifier_xhs_blademaster_mirror_image_handler:IsPurgable() return false end
function modifier_xhs_blademaster_mirror_image_handler:RemoveOnDeath() return false end

function modifier_xhs_blademaster_mirror_image_handler:OnCreated()
	self:StartIntervalThink(1.0)
	self:OnIntervalThink()

	if IsServer() then
		self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_imba_shiva_aura", {})
	end
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
