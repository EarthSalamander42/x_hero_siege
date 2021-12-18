-- Author: Cookies
-- Date: 05.12.2019

local function RespawnMagtheridon(iBossCount, vPosition, iAnkhCharges)
	if iAnkhCharges == 0 then return end

	local magtheridon = CreateUnitByName("npc_dota_hero_magtheridon", vPosition, true, nil, nil, DOTA_TEAM_CUSTOM_2)
	magtheridon.boss_count = iBossCount

	print(iAnkhCharges)
	magtheridon:AddNewModifier(magtheridon, nil, "modifier_ankh_passives", {}):SetStackCount(iAnkhCharges - 1)

	magtheridon:EmitSound("Ability.Reincarnation")
	magtheridon.zone = "xhs_holdout"
end

LinkLuaModifier("modifier_ankh_passives", "items/ankh_of_reincarnation.lua", LUA_MODIFIER_MOTION_NONE)

item_ankh_of_reincarnation = item_ankh_of_reincarnation or class({})

function item_ankh_of_reincarnation:GetIntrinsicModifierName()
	return "modifier_ankh"
end

modifier_ankh = modifier_ankh or class({})

function modifier_ankh:IsHidden() return true end

function modifier_ankh:OnCreated(keys)
	if not IsServer() then return end

	local mod = self:GetParent():FindModifierByName("modifier_ankh_passives")

	if mod then
		mod:IncrementStackCount()

		if self:GetParent():IsRealHero() and self:GetParent():IsOwnedByAnyPlayer() then
			CustomNetTables:SetTableValue("player_table", tostring(self:GetParent():entindex()).."_respawns", {mod:GetStackCount()})
		end
	else
		local charges = 0

		if self:GetAbility() and self:GetAbility().GetCurrentCharges then
			charges = self:GetAbility():GetCurrentCharges()
		elseif keys and keys.charges then
			charges = keys.charges
		end

		self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_ankh_passives", {}):SetStackCount(charges)

		if self:GetParent():IsRealHero() and self:GetParent():IsOwnedByAnyPlayer() then
			CustomNetTables:SetTableValue("player_table", tostring(self:GetParent():entindex()).."_respawns", {charges})
		end
	end

	UTIL_Remove(self:GetAbility())
	self:Destroy()
end

modifier_ankh_passives = modifier_ankh_passives or class({})

function modifier_ankh_passives:IsHidden() return not IsInToolsMode() end
function modifier_ankh_passives:RemoveOnDeath() return false end
function modifier_ankh_passives:IsPurgable() return false end
function modifier_ankh_passives:IsPurgeException() return false end
function modifier_ankh_passives:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_ankh_passives:GetTextre() return "modifiers/ankh_of_reincarnation" end

function modifier_ankh_passives:DeclareFunctions() return {
	MODIFIER_EVENT_ON_DEATH,
} end

function modifier_ankh_passives:OnIntervalThink()
	self:StartIntervalThink(-1)

	self:GetParent():EmitSound("Ability.ReincarnationAlt")

	if self:GetParent():IsRealHero() then
		self:GetParent():SetRespawnPosition(self.position)
		self:GetParent():RespawnHero(false, false)
		self:GetParent():SetRespawnsDisabled(false)
	else
--		print("Unit name:", self:GetParent():GetUnitName())
		-- useless fail-safe, just in case (shouldn't proc as the unit is removed before the interval think occurs)
		if string.find(self:GetParent():GetUnitName(), "magtheridon") then
			print("MAGTHERIDON RESPAWN!")
		else
			self:GetParent():RespawnUnit()
		end
	end

	self:GetParent().ankh_respawn = false
end

function modifier_ankh_passives:OnDeath(params)
	if not IsServer() then return end
	if self:GetParent() == nil then return end
	if self:GetParent().IsIllusion and self:GetParent():IsIllusion() then return end
	if self:GetParent().GetUnitName and self:GetParent():GetUnitName() == "npc_spirit_beast" then return end
	if params.unit ~= self:GetParent() then return end
	if self:GetParent().ankh_respawn == true then return end

	self.position = self:GetParent():GetAbsOrigin()
	local boss_count = self:GetParent().boss_count
	local charges = self:GetStackCount()

	if self:GetAbility() and self:GetAbility():GetAbilityName() == "item_shield_of_invincibility" then
		print("Victim is wearing Shield!")
		if not self:GetAbility():IsCooldownReady() then return end

		print("Ability name:", self:GetAbility():GetAbilityName())
		self:GetAbility():StartCooldown(self:GetAbility():GetCooldown(self:GetAbility():GetLevel()))
	else
		if not self:GetParent():HasItemInInventory("item_shield_of_invincibility") then
			local new_stacks = math.max(charges - 1, 0)

			if self:GetParent():IsRealHero() and self:GetParent():IsOwnedByAnyPlayer() then
				CustomNetTables:SetTableValue("player_table", tostring(self:GetParent():entindex()).."_respawns", {new_stacks})
			end

			self:SetStackCount(new_stacks)

			if charges == 0 then
				return
			end
		end
	end

	local reincarnate_time = XHS_GLOBAL_RESPAWN_TIME

	AddFOWViewer(self:GetParent():GetTeamNumber(), self.position, 200, reincarnate_time, false)
	self:GetParent().ankh_respawn = true

	if self:GetParent():IsRealHero() then
		self:GetParent():SetRespawnsDisabled(true)
	else
		-- Prevent Beastmaster's bear ability to be cast while reincarnating
		if self:GetParent():GetOwner() and self:GetParent():GetOwner():FindAbilityByName("lone_druid_spirit_bear"):IsCooldownReady() then
			self:GetParent():GetOwner():FindAbilityByName("lone_druid_spirit_bear"):StartCooldown(self.reincarnation_time)
		end

		if string.find(self:GetParent():GetUnitName(), "magtheridon") then
			reincarnate_time = 10.0

			for i = 1, 8 do
				CreateUnitByName("npc_dota_hero_magtheridon_medium", self.position + RandomVector(200), true, nil, nil, DOTA_TEAM_CUSTOM_2)
			end

			Timers:CreateTimer(reincarnate_time, function()
				RespawnMagtheridon(boss_count, self.position, charges)
			end)
		end
	end

	local particle = ParticleManager:CreateParticle("particles/items_fx/aegis_respawn_timer.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	ParticleManager:SetParticleControl(particle, 1, Vector(reincarnate_time, 0, 0))
	ParticleManager:SetParticleControl(particle, 3, self.position)
	ParticleManager:ReleaseParticleIndex(particle)

	self:StartIntervalThink(reincarnate_time)
end
