-- Author:	Cookies
-- Date:	05.11.2017

if modifier_ai == nil then modifier_ai = class({}) end
function modifier_ai:GetAttributes() return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end
function modifier_ai:IsPurgeException() return false end
function modifier_ai:IsPurgable() return false end
function modifier_ai:IsDebuff() return false end
function modifier_ai:IsHidden() return true end

function modifier_ai:GetPriority()
	return MODIFIER_PRIORITY_SUPER_ULTRA
end

function modifier_ai:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_EVENT_ON_ATTACK_START,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_EVENT_ON_UNIT_MOVED
	}
end

function modifier_ai:CheckState()
	local state = {}

--	state[MODIFIER_STATE_NO_UNIT_COLLISION]	= true
	return state
end

function modifier_ai:OnCreated()
	if IsServer() then
		self.last_movement = 0.0
		self.find_enemy_distance = 500
		if self:GetParent():GetKeyValue("UseAI") == 3 then
			self:StartIntervalThink(RandomInt(2, 5))
		else
			self:StartIntervalThink(1.0)
		end
	end
end

function modifier_ai:OnIntervalThink()
if not IsServer() then return end
if self:GetParent():IsIllusion() then return end

	self.is_casting = false

--	if GameRules:GetGameTime() - self.last_movement >= 3.0 then
--		print("Roshan is sleeping...")
--	else
--		print("Activating brain!")
--	end

	if self:GetParent():IsStunned() or self:GetParent():IsSilenced() or self:GetParent():IsHexed() or self:GetParent():IsChanneling() or self.is_casting == true then return end

--	print("AI: Ready to work!:", self:GetParent():GetUnitName())

	for ability_index = 0, self:GetParent():GetAbilityCount() - 1 do
		local ability = self:GetParent():GetAbilityByIndex(ability_index)
		if ability and not ability:IsPassive() and not ability:IsToggle() and ability:IsActivated() and ability:IsCooldownReady() then
			if ability:IsInAbilityPhase() then
				self.is_casting = true
				return
			end
		end
	end

	if self:GetParent():GetKeyValue("UseAI") == 1 then
		if not self:GetParent():IsAttacking() then
			local ancient = Entities:FindByName(nil, "dota_goodguys_fort")
			local distance = (self:GetParent():GetAbsOrigin() - ancient:GetAbsOrigin()):Length2D()

			if distance < 500 then
				self:GetParent():SetAttacking(ancient)
				return
			else
--				for _, vip in pairs(GameRules.GameMode.PrecachedVIPs) do
--					print(self:GetParent():GetAttackTarget())
--					if self:GetParent():GetAttackTarget() then
--						if self:GetParent():GetAttackTarget():GetUnitName() == vip or self:GetParent():GetAttackTarget():GetUnitName() == "npc_dota_crate" or self:GetParent():GetAttackTarget():GetUnitName() == "npc_treasure_chest" then -- error sometimes
--							print(self:GetParent():GetAttackTarget():GetUnitName(), vip)
--							self:GetParent():MoveToPosition(ancient:GetAbsOrigin())
--						end
--					end
--				end

				self:GetParent():MoveToPositionAggressive(ancient:GetAbsOrigin())
			end
		end
	elseif self:GetParent():GetKeyValue("UseAI") == 3 then
		local random_int = RandomInt(1, 4)
		if self.last_goal ~= random_int then
			self:GetParent():MoveToPositionAggressive(Entities:FindByName(nil, "roshan_wp_"..random_int):GetAbsOrigin())
			self.last_goal = random_int
		end
	end

	if not self:GetParent():GetCurrentActiveAbility() then
		for ability_index = 0, self:GetParent():GetAbilityCount() - 1 do
			local ability = self:GetParent():GetAbilityByIndex(ability_index)
			if ability and not ability:IsInAbilityPhase() and not ability:IsPassive() and not ability:IsToggle() and ability:IsActivated() and ability:IsCooldownReady() then
				local ability_behavior = tostring(ability:GetBehavior())
				local cast_range = ability:GetCastRange()
				local target_team = ability:GetAbilityTargetTeam()
				local target_type = ability:GetAbilityTargetType()
				local target_flags = ability:GetAbilityTargetFlags()
				if cast_range == 0 then cast_range = self.find_enemy_distance end
				cast_range = cast_range * 0.9 -- 90% of the range to allow projectiles hit the target. e.g: Mirana's Starfall
				if target_team == 0 then target_team = 2 end -- TEAM_ENEMY
				if target_type == 0 then target_type = 19 end -- DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
				local allies = FindUnitsInRadius(self:GetParent():GetTeamNumber(), self:GetParent():GetAbsOrigin(), nil, cast_range, self:GetParent():GetTeamNumber(), target_type, ability:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)
				local enemies = FindUnitsInRadius(self:GetParent():GetTeamNumber(), self:GetParent():GetAbsOrigin(), nil, cast_range, target_team, target_type, ability:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)

				-- Bug with jugg boss, no behavior after first cast
--				print(ability_behavior)

--				if tonumber(ability_behavior) == DOTA_ABILITY_BEHAVIOR_TOGGLE or tonumber(ability_behavior) == 8 then
--					if #enemies > 0 then
--						print("Enemy!")
--						if ability:GetToggleState() == false then
--							print("Enable ability!")
--							ability:ToggleAbility()
--							return
--						end
--					end
				if tonumber(ability_behavior) == DOTA_ABILITY_BEHAVIOR_NO_TARGET then
					if #enemies > 0 then
--						print("Cast No Target:", ability:GetAbilityName())
						self:GetParent():CastAbilityNoTarget(ability, -1)
					end
					return
				elseif tonumber(ability_behavior) == DOTA_ABILITY_BEHAVIOR_POINT then
--					print("Cast On Ground:", ability:GetAbilityName())
					for _, hero in pairs(enemies) do
						self:GetParent():CastAbilityOnPosition(hero:GetAbsOrigin(), ability, -1)
						return
					end
				elseif tonumber(ability_behavior) == DOTA_ABILITY_BEHAVIOR_UNIT_TARGET then
--					print("Cast On Target:", ability:GetAbilityName())
					if self:GetParent():GetTeam() == ability:GetAbilityTargetTeam() then
						for _, hero in pairs(allies) do
							self:GetParent():CastAbilityOnTarget(hero, ability, -1)
							return
						end
					else
						for _, hero in pairs(enemies) do
							self:GetParent():CastAbilityOnTarget(hero, ability, -1)
							return
						end
					end
				end
			end
		end
	end
end

--[[
function modifier_ai:OnUnitMoved(keys)    
	if IsServer() then
		local unit = keys.unit

		if self.caster == unit then
			self.last_movement = GameRules:GetGameTime()
		end
	end
end

function modifier_ai:OnOrder(kv)
local order_type = kv.order_type	

	if order_type == DOTA_UNIT_ORDER_CAST_NO_TARGET then
		
	end
end

function modifier_ai:OnTakeDamage(keys)
	if IsServer() then
		local unit = keys.unit
		local attacker = keys.attacker

		if unit == self:GetParent() then
			if attacker == unit then return nil end
			self.last_movement = GameRules:GetGameTime()
			attacker.roshan_attacked_time = GameRules:GetGameTime()
		end
	end
end

function modifier_ai:OnAttackLanded(keys)
	if IsServer() then
		local target = keys.target
		local attacker = keys.attacker
		
		if self:GetParent() == target then
			-- if attacked
		elseif self:GetParent() == attacker then
			-- if attacker
		end
	end
end

function modifier_ai:OnAttackStart(keys)
	if IsServer() then
		if self:GetParent() == keys.attacker then
			
		end
	end
end
--]]