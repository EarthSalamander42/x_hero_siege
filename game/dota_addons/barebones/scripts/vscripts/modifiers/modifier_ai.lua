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
		self.parent = self:GetParent()
		self.last_movement = 0.0
		self.find_enemy_distance = 500
		self.is_casting = false
		if self.parent:GetKeyValue("UseAI") == 3 then
			self:StartIntervalThink(RandomInt(2, 5))
		else
			self:StartIntervalThink(1.0)
		end
	end
end

function modifier_ai:OnIntervalThink()
if not IsServer() then return end

--	if GameRules:GetGameTime() - self.last_movement >= 3.0 then
--		print("Roshan is sleeping...")
--	else
--		print("Activating brain!")
--	end

	if self.parent:IsAlive() then
		if self.parent:IsStunned() or self.parent:IsSilenced() or self.parent:IsHexed() or self.parent:IsChanneling() or self.is_casting == true then return end

		for ability_index = 0, self.parent:GetAbilityCount() - 1 do
			local ability = self.parent:GetAbilityByIndex(ability_index)
			if ability and not ability:IsPassive() and not ability:IsToggle() and ability:IsActivated() and ability:IsCooldownReady() then
				if ability:IsInAbilityPhase() then
					self.is_casting = true
					return
				else
					self.is_casting = false
				end
			end
		end

		if self.parent:GetKeyValue("UseAI") == 1 then
			if not self.parent:IsAttacking() then
				local ancient = Entities:FindByName(nil, "dota_goodguys_fort")
				local distance = (self.parent:GetAbsOrigin() - ancient:GetAbsOrigin()):Length2D()

				if distance < 400 then
					self.parent:SetAttacking(ancient)
					return
				else
					self.parent:MoveToPositionAggressive(ancient:GetAbsOrigin())
				end
			end
		elseif self.parent:GetKeyValue("UseAI") == 3 then
			local random_int = RandomInt(1, 4)
			if self.last_goal ~= random_int then
				self.parent:MoveToPositionAggressive(Entities:FindByName(nil, "roshan_wp_"..random_int):GetAbsOrigin())
				self.last_goal = random_int
			end
		end

		if not self.parent:GetCurrentActiveAbility() then
			for ability_index = 0, self.parent:GetAbilityCount() - 1 do
				local ability = self.parent:GetAbilityByIndex(ability_index)
				if ability and not ability:IsInAbilityPhase() and not ability:IsPassive() and not ability:IsToggle() and ability:IsActivated() and ability:IsCooldownReady() then
					local ability_behavior = tostring(ability:GetBehavior())
					local cast_range = ability:GetCastRange()
					local target_team = ability:GetAbilityTargetTeam()
					local target_type = ability:GetAbilityTargetType()
					if cast_range == 0 then cast_range = self.find_enemy_distance end
					cast_range = cast_range * 0.9 -- 90% of the range to allow projectiles hit the target. e.g: Mirana's Starfall
					if target_team == 0 then target_team = 2 end -- TEAM_ENEMY
					if target_type == 0 then target_type = 19 end -- DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
					local enemies = FindUnitsInRadius(self.parent:GetTeamNumber(), self.parent:GetAbsOrigin(), nil, cast_range, target_team, target_type, ability:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)

--					print(ability_behavior)

--					if tonumber(ability_behavior) == DOTA_ABILITY_BEHAVIOR_TOGGLE or tonumber(ability_behavior) == 8 then
--						if #enemies > 0 then
--							print("Enemy!")
--							if ability:GetToggleState() == false then
--								print("Enable ability!")
--								ability:ToggleAbility()
--								return
--							end
--						end
					if tonumber(ability_behavior) == DOTA_ABILITY_BEHAVIOR_NO_TARGET then
						if #enemies > 0 then
--							print("Cast No Target:", ability:GetAbilityName())
							self.parent:CastAbilityNoTarget(ability, -1)
						end
						return
					elseif tonumber(ability_behavior) == DOTA_ABILITY_BEHAVIOR_POINT then
--						print("Cast On Ground:", ability:GetAbilityName())
						for _, hero in pairs(enemies) do
							self.parent:CastAbilityOnPosition(hero:GetAbsOrigin(), ability, -1)
							return
						end
					elseif tonumber(ability_behavior) == DOTA_ABILITY_BEHAVIOR_UNIT_TARGET then
--						print("Cast On Target:", ability:GetAbilityName())
						for _, hero in pairs(enemies) do
							self.parent:CastAbilityOnTarget(hero, ability, -1)
							return
						end
					end
				end
			end
		end

--		if not self.parent:GetCurrentActiveAbility() then
--			-- Cast Toss if its available
--			if self.toss and self.toss:IsCooldownReady() then
--				local maxRange = self.toss:GetSpecialValueFor("tooltip_range")
--				local pickupRadius = self.toss:GetSpecialValueFor("grab_radius")
--				local pickupUnit = nil
--				local throwTarget = nil
--				
--				local units = FindUnitsInRadius(self.parent:GetTeamNumber(), self.parent:GetAbsOrigin(), nil, pickupRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS, FIND_CLOSEST, false) 
--				for _, unit in ipairs(units) do
--					if unit and unit:IsAlive() and not unit:IsAncient() then
--						pickupUnit = unit
--						break
--					end
--				end
--
--				if pickupUnit then
--					units = FindUnitsInRadius(self.parent:GetTeamNumber(), self.parent:GetAbsOrigin(), nil, maxRange, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS, FIND_FARTHEST, false) 
--					for _, unit in ipairs(units) do
--						if unit and unit:IsAlive() then
--							throwTarget = unit
--							break
--						end
--					end
--
--					if throwTarget then
--						self.parent:CastAbilityOnTarget(throwTarget, self.toss, 1)
--						return
--					end
--				end
--			end
--		end
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

		if unit == self.parent then
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
		
		if self.parent == target then
			-- if attacked
		elseif self.parent == attacker then
			-- if attacker
		end
	end
end

function modifier_ai:OnAttackStart(keys)
	if IsServer() then
		if self.parent == keys.attacker then
			
		end
	end
end
--]]