-- Author: Cookies
-- Date: 05.12.2019


LinkLuaModifier("modifier_ankh_passives", "items/ankh_of_reincarnation.lua", LUA_MODIFIER_MOTION_NONE)

item_ankh_of_reincarnation = item_ankh_of_reincarnation or class({})

function item_ankh_of_reincarnation:GetIntrinsicModifierName()
	return "modifier_ankh_passives"
end

modifier_ankh_passives = modifier_ankh_passives or class({})

function modifier_ankh_passives:IsHidden() return not IsInToolsMode() end
function modifier_ankh_passives:RemoveOnDeath() return false end
function modifier_ankh_passives:IsPurgable() return false end
function modifier_ankh_passives:IsPurgeException() return false end
function modifier_ankh_passives:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_ankh_passives:DeclareFunctions() return {
	MODIFIER_EVENT_ON_DEATH,
} end

function modifier_ankh_passives:OnDeath(params)
	if not IsServer() then return end
	if self:GetParent() == nil then return end
	if self:GetParent().IsIllusion and self:GetParent():IsIllusion() then return end
	if self:GetParent().GetUnitName and self:GetParent():GetUnitName() == "npc_spirit_beast" then return end

	if params.unit == self:GetParent() and self:GetAbility():IsCooldownReady() then
		if self:GetParent().ankh_respawn == true then return end

		-- todo: handle abilities procs first

		local reincarnation_items = {
			"item_shield_of_invincibility",
			"item_doom_artifact",
		}

		-- check if parent wear shield or doom artifact (Note: items cd start before this check) -- not sure this block is required with parent.ankh_respawn, but heh
		if self:GetAbility():GetAbilityName() == "item_ankh_of_reincarnation" then
			print("Wearing Ankh!")
			for i = 1, #reincarnation_items do
				local item_name = reincarnation_items[i]
				print(item_name)
				local item = self:GetParent():FindItemInInventory(item_name)

				-- if wearing item (cooldown ready), ignore ankh modifier
				print(item)
				if item then
					print(item:GetAbilityName(), item:IsCooldownReady())

					if item:IsCooldownReady() then
						print("Proc item, not ankh.")
						return
					end
				end
			end
		end

		print("Ability name:", self:GetAbility():GetAbilityName())

		local reincarnate_time = XHS_GLOBAL_RESPAWN_TIME
		self.position = self:GetParent():GetAbsOrigin()

		if string.find(self:GetParent():GetUnitName(), "magtheridon") then
			reincarnate_time = self:GetAbility():GetSpecialValueFor("magtheridon_reincarnation_time")
		end

		AddFOWViewer(self:GetParent():GetTeamNumber(), self.position, 200, reincarnate_time, false)
		self:GetParent().ankh_respawn = true

		if self:GetParent():IsRealHero() then
			self:GetParent():SetRespawnsDisabled(true)
		else
			-- Prevent Beastmaster's bear ability to be cast while reincarnating
			if self:GetParent():GetOwner():FindAbilityByName("lone_druid_spirit_bear"):IsCooldownReady() then
				self:GetParent():GetOwner():FindAbilityByName("lone_druid_spirit_bear"):StartCooldown(5.0)
			end
		end

		local particle = ParticleManager:CreateParticle("particles/items_fx/aegis_respawn_timer.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
		ParticleManager:SetParticleControl(particle, 1, Vector(reincarnate_time, 0, 0))
		ParticleManager:SetParticleControl(particle, 3, self.position)
		ParticleManager:ReleaseParticleIndex(particle)

		if self:GetAbility():GetAbilityName() ~= "item_ankh_of_reincarnation" then
			self:GetAbility():StartCooldown(self:GetAbility():GetCooldown(self:GetAbility():GetLevel()))
		else
			if self:GetAbility():GetCurrentCharges() -1 >= 1 then
				self:GetAbility():SetCurrentCharges(self:GetAbility():GetCurrentCharges() -1)
			else
				self.mark_for_delete = true
			end
		end

		self:StartIntervalThink(reincarnate_time)
	end
end

function modifier_ankh_passives:OnIntervalThink()
	self:StartIntervalThink(-1)

	self:GetParent():SetRespawnPosition(self.position)
	self:GetParent():EmitSound("Ability.ReincarnationAlt")

	if self:GetParent():IsRealHero() then
		self:GetParent():RespawnHero(false, false)
		self:GetParent():SetRespawnsDisabled(false)
	else
		self:GetParent():RespawnUnit()
	end

	-- requires 0.1 timer?
	self:GetParent().ankh_respawn = false

	if self.mark_for_delete then
		self:GetAbility():RemoveSelf()
	end
end
