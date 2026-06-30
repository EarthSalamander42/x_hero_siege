-- Author: Cookies
-- Date: 05.12.2019

require("boss_scripts/phase3_ai/magtheridon")

local function RespawnMagtheridon(iBossCount, vPosition, iAnkhCharges)
	if iAnkhCharges == 0 then return end

	local empowerStacks = 0
	if XHSMagtheridon_GetRuptureEmpowerStacks ~= nil then
		empowerStacks = XHSMagtheridon_GetRuptureEmpowerStacks(iBossCount)
	end

	local magtheridon = CreateUnitByName("npc_dota_hero_magtheridon", vPosition, true, nil, nil, DOTA_TEAM_CUSTOM_2)
	magtheridon.boss_count = iBossCount
	magtheridon.xhs_boss_bar_id = "magtheridon_" .. tostring(iBossCount or 1)

	magtheridon:AddNewModifier(magtheridon, nil, "modifier_ankh_passives", {}):SetStackCount(iAnkhCharges - 1)

	magtheridon:EmitSound("Ability.Reincarnation")
	magtheridon.zone = "xhs_holdout"

	if XHSMagtheridon_OnRespawned ~= nil then
		XHSMagtheridon_OnRespawned(magtheridon, iBossCount, empowerStacks)
	end
end

LinkLuaModifier("modifier_ankh_passives", "items/ankh_of_reincarnation.lua", LUA_MODIFIER_MOTION_NONE)

item_ankh_of_reincarnation = item_ankh_of_reincarnation or class({})

local ANKH_RESPAWN_PARTICLE = "particles/items_fx/aegis_respawn.vpcf"

local function GetMagtheridonRuptureReincarnateTime(unit, fallback)
	if unit == nil or unit:IsNull() then return fallback end

	local rupture = unit:FindAbilityByName("xhs_magtheridon_rupture")
	if rupture ~= nil then
		local value = rupture:GetSpecialValueFor("reincarnate_time")
		if value ~= nil and value > 0 then return value end
	end

	return fallback
end

local function PlayAnkhRespawnParticle(unit)
	if unit == nil or unit:IsNull() then return end

	local particle = ParticleManager:CreateParticle(ANKH_RESPAWN_PARTICLE, PATTACH_ABSORIGIN_FOLLOW, unit)
	ParticleManager:SetParticleControl(particle, 0, unit:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(particle)
end

local function SetXHSReincarnationNetTable(unit, active, duration)
	if unit == nil or unit:IsNull() then return end
	if not unit:IsRealHero() or not unit:IsOwnedByAnyPlayer() then return end

	duration = tonumber(duration) or 0
	CustomNetTables:SetTableValue("player_table", tostring(unit:entindex()).."_reincarnation", {
		active = active == true and 1 or 0,
		duration = duration,
		end_time = active == true and (GameRules:GetGameTime() + duration) or 0,
	})
end

function item_ankh_of_reincarnation:GetIntrinsicModifierName()
	return "modifier_ankh"
end

modifier_ankh = modifier_ankh or class({})

function modifier_ankh:IsHidden() return true end

function modifier_ankh:OnCreated(keys)
	if not IsServer() then return end

	if self:GetParent():IsRealHero() and self:GetParent():IsOwnedByAnyPlayer() and IsPlayerXHSReincarnating ~= nil and IsPlayerXHSReincarnating(self:GetParent():GetPlayerID()) then
		SendErrorMessage(self:GetParent():GetPlayerID(), "#error_reincarnation_inventory_locked")
		if WasItemInXHSReincarnationInventorySnapshot ~= nil and WasItemInXHSReincarnationInventorySnapshot(self:GetParent(), self:GetAbility()) then
			if RestoreXHSReincarnationInventory ~= nil then
				RestoreXHSReincarnationInventory(self:GetParent())
			end
			self:Destroy()
			return
		end

		if self:GetAbility() ~= nil and not self:GetAbility():IsNull() then
			UTIL_Remove(self:GetAbility())
		end
		self:Destroy()
		return
	end

	local mod = self:GetParent():FindModifierByName("modifier_ankh_passives")

	if mod then
		local previous_charges = CustomNetTables:GetTableValue("player_table", tostring(self:GetParent():entindex()).."_respawns")["1"] or 0
		local ankh_charges = self:GetAbility():GetCurrentCharges()

		mod:SetStackCount(previous_charges + ankh_charges)

		if self:GetParent():IsRealHero() and self:GetParent():IsOwnedByAnyPlayer() then
			CustomNetTables:SetTableValue("player_table", tostring(self:GetParent():entindex()).."_respawns", {mod:GetStackCount()})
			SetXHSReincarnationNetTable(self:GetParent(), false, 0)
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
			SetXHSReincarnationNetTable(self:GetParent(), false, 0)
		end
	end

	if self:GetAbility() ~= nil and not self:GetAbility():IsNull() then
		UTIL_Remove(self:GetAbility())
	end
	self:Destroy()
end

modifier_ankh_passives = modifier_ankh_passives or class({})

function modifier_ankh_passives:IsHidden() return true end
function modifier_ankh_passives:RemoveOnDeath() return false end
function modifier_ankh_passives:IsPurgable() return false end
function modifier_ankh_passives:IsPurgeException() return false end
function modifier_ankh_passives:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_ankh_passives:GetTexture() return "modifiers/ankh_of_reincarnation" end

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
		PlayAnkhRespawnParticle(self:GetParent())
	else
--		print("Unit name:", self:GetParent():GetUnitName())
		-- useless fail-safe, just in case (shouldn't proc as the unit is removed before the interval think occurs)
		if string.find(self:GetParent():GetUnitName(), "magtheridon") then
			print("MAGTHERIDON RESPAWN!")
		else
			self:GetParent():RespawnUnit()
			PlayAnkhRespawnParticle(self:GetParent())
		end
	end

	self:GetParent().ankh_respawn = false
	if self:GetParent():IsRealHero() and self:GetParent():IsOwnedByAnyPlayer() then
		SetXHSReincarnationNetTable(self:GetParent(), false, 0)
		_G.XHS_REINCARNATING_PLAYERS = _G.XHS_REINCARNATING_PLAYERS or {}
		_G.XHS_REINCARNATING_PLAYERS[self:GetParent():GetPlayerID()] = nil
		if StopXHSReincarnationInventoryLock ~= nil then
			StopXHSReincarnationInventoryLock(self:GetParent())
		end
	end
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
				SetXHSReincarnationNetTable(self:GetParent(), false, 0)
				return
			end
		end
	end

	if FragmentQuests ~= nil and self:GetParent():IsRealHero() then
		FragmentQuests:OnHeroDeath(self:GetParent(), { source = "ankh" })
	end

	local reincarnate_time = XHS_GLOBAL_RESPAWN_TIME

	AddFOWViewer(self:GetParent():GetTeamNumber(), self.position, 200, reincarnate_time, false)
	self:GetParent().ankh_respawn = true
	if self:GetParent():IsRealHero() and self:GetParent():IsOwnedByAnyPlayer() then
		_G.XHS_REINCARNATING_PLAYERS = _G.XHS_REINCARNATING_PLAYERS or {}
		_G.XHS_REINCARNATING_PLAYERS[self:GetParent():GetPlayerID()] = true
		if StartXHSReincarnationInventoryLock ~= nil then
			StartXHSReincarnationInventoryLock(self:GetParent())
		end
	end

	if self:GetParent():IsRealHero() then
		self:GetParent():SetRespawnsDisabled(true)
	else
		-- Prevent Beastmaster's bear ability to be cast while reincarnating
		if self:GetParent():GetOwner() and self:GetParent():GetOwner():FindAbilityByName("lone_druid_spirit_bear"):IsCooldownReady() then
			self:GetParent():GetOwner():FindAbilityByName("lone_druid_spirit_bear"):StartCooldown(self.reincarnation_time)
		end

		if string.find(self:GetParent():GetUnitName(), "magtheridon") then
			reincarnate_time = GetMagtheridonRuptureReincarnateTime(self:GetParent(), 20.0)

			if XHSMagtheridon_StartRupture ~= nil then
				XHSMagtheridon_StartRupture(self:GetParent(), boss_count, self.position, charges, reincarnate_time)
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

	SetXHSReincarnationNetTable(self:GetParent(), true, reincarnate_time)
	self:StartIntervalThink(reincarnate_time)
end
