-- Author:	Cookies
-- Date:	05.11.2017

modifier_ai = modifier_ai or class({})

function modifier_ai:GetAttributes() return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

function modifier_ai:IsPurgeException() return false end

function modifier_ai:IsPurgable() return false end

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

function modifier_ai:OnCreated(params)
	if IsServer() then
		self.last_movement = 0.0
		self.find_enemy_distance = 1000
		self:StartIntervalThink(1.0)
		self.ai_state = params.state

		--		print("Add AI to unit:", self:GetParent():GetUnitName())
	end
end

function modifier_ai:OnIntervalThink()
	if self:GetParent():IsIllusion() then return end
	if Entities:FindByName(nil, "dota_goodguys_fort") == nil then return end

	if self:GetParent():IsStunned() or self:GetParent():IsSilenced() or self:GetParent():IsHexed() or self:GetParent():IsChanneling() or self:GetParent():GetCurrentActiveAbility() then return end

	--	print("AI: Ready to work!:", self:GetParent():GetUnitName())

	-- Move to ancient if no target
	if self.ai_state == 1 then
		print(self:GetParent():IsAttacking())
		if not self:GetParent():IsAttacking() then
			local ancient = Entities:FindByName(nil, "dota_goodguys_fort")
			local distance = (self:GetParent():GetAbsOrigin() - ancient:GetAbsOrigin()):Length2D()

			if distance < 500 then
				self:GetParent():SetAttacking(ancient)
				return
			else
				for _, vip in pairs(GameRules.GameMode.PrecachedVIPs) do
					-- print(self:GetParent():GetAttackTarget())
					if self:GetParent():GetAttackTarget() then
						if self:GetParent():GetAttackTarget():GetUnitName() == vip or self:GetParent():GetAttackTarget():GetUnitName() == "npc_dota_crate" or self:GetParent():GetAttackTarget():GetUnitName() == "npc_treasure_chest" then -- error sometimes
							print(self:GetParent():GetAttackTarget():GetUnitName(), vip)
							self:GetParent():MoveToPosition(ancient:GetAbsOrigin())
						end
					end
				end

				self:GetParent():MoveToPositionAggressive(ancient:GetAbsOrigin())
			end
		end
		-- Muradin AI
	elseif self.ai_state == 3 then
		local random_int = RandomInt(1, 4)
		if self.last_goal ~= random_int and not self:GetParent():IsMoving() and not self:GetParent():IsAttacking() then
			self:GetParent():MoveToPositionAggressive(Entities:FindByName(nil, "roshan_wp_" .. random_int):GetAbsOrigin())
			self.last_goal = random_int
		end
	end

	-- print(self:GetParent():GetCurrentActiveAbility())
	-- print("Caster is not casting an ability")
	for ability_index = 0, self:GetParent():GetAbilityCount() - 1 do
		local ability = self:GetParent():GetAbilityByIndex(ability_index)

		if ability and not ability:IsInAbilityPhase() and not ability:IsPassive() and ability:IsActivated() and ability:IsCooldownReady() and ability:GetLevel() > 0 then
			-- print("Ability is castable:", ability:GetAbilityName())
			local cast_range = ability:GetCastRange(self:GetParent():GetCursorPosition(), self:GetParent()) or self.find_enemy_distance
			local target_team = ability:GetAbilityTargetTeam()
			local target_type = ability:GetAbilityTargetType()
			if target_team == 0 then target_team = 2 end -- TEAM_ENEMY
			if target_type == 0 then target_type = 19 end -- DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
			-- local target_flags = ability:GetAbilityTargetFlags()
			if cast_range == 0 then cast_range = self.find_enemy_distance end
			-- print("Cast Range:", cast_range)
			cast_range = cast_range * 0.9 -- 90% of the range to allow projectiles hit the target. e.g: Mirana's Starfall
			local allies = FindUnitsInRadius(self:GetParent():GetTeamNumber(), self:GetParent():GetAbsOrigin(), nil, cast_range, self:GetParent():GetTeamNumber(), target_type, ability:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)
			local enemies = FindUnitsInRadius(self:GetParent():GetTeamNumber(), self:GetParent():GetAbsOrigin(), nil, cast_range, target_team, target_type, ability:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)

			-- print(#enemies)
			if #enemies == 0 then
				-- print("range / enemies / behavior:", self:GetParent():GetUnitName(), ability:GetAbilityName(), cast_range, #enemies, target_team, target_type)
				if bit.band(tonumber(tostring(ability:GetBehavior())), DOTA_ABILITY_BEHAVIOR_TOGGLE) == DOTA_ABILITY_BEHAVIOR_TOGGLE then
					if ability:GetToggleState() == true then
						ability:ToggleAbility()
					end
				end

				return
			elseif #enemies == 1 and IsValidEntity(enemies[1]) and enemies[1]:IsInvisible() then
				for _, restricted_ab in pairs(_G.multiplayer_abilities_cast) do
					if ability:GetAbilityName() == restricted_ab then
						print("Casting this ability in solo mode is restricted!!")
						return
					end
				end
			end

			-- Bug with jugg boss, no behavior after first cast
			--				print("Behavior:", ability:GetBehavior())

			if bit.band(tonumber(tostring(ability:GetBehavior())), DOTA_ABILITY_BEHAVIOR_TOGGLE) == DOTA_ABILITY_BEHAVIOR_TOGGLE then
				if ability:GetToggleState() == false then
					ability:ToggleAbility()
				end
			elseif bit.band(tonumber(tostring(ability:GetBehavior())), DOTA_ABILITY_BEHAVIOR_NO_TARGET) == DOTA_ABILITY_BEHAVIOR_NO_TARGET then
				-- print("Cast No Target:", ability:GetAbilityName())

				if ability:GetAbilityName() == "arthas_holy_light" then
					-- print(self:GetParent():GetHealthPercent(), ability:GetSpecialValueFor("health_threshold"))
					if self:GetParent():GetHealthPercent() <= ability:GetSpecialValueFor("health_threshold") then
						self:GetParent():Stop()
						self:GetParent():CastAbilityNoTarget(ability, -1)
					end
				else
					self:GetParent():Stop()
					self:GetParent():CastAbilityNoTarget(ability, -1)
				end

				return
			elseif bit.band(tonumber(tostring(ability:GetBehavior())), DOTA_ABILITY_BEHAVIOR_POINT) == DOTA_ABILITY_BEHAVIOR_POINT then
				self:GetParent():Stop()
				for k, v in pairs(enemies) do
					if v and IsValidEntity(v) and v:IsAlive() and not v:IsInvisible() and not v:IsInvulnerable() then
						local position = v:GetAbsOrigin()

						ExecuteOrderFromTable({
							UnitIndex = self:GetParent():entindex(),
							OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
							AbilityIndex = ability:entindex(),
							Position = position,
							-- Queue = true
						})

						return
					end
				end

				return
			elseif bit.band(tonumber(tostring(ability:GetBehavior())), DOTA_ABILITY_BEHAVIOR_UNIT_TARGET) == DOTA_ABILITY_BEHAVIOR_UNIT_TARGET then
				-- print("Cast On Target:", ability:GetAbilityName())

				if self:GetParent():GetTeam() == ability:GetAbilityTargetTeam() then
					self:GetParent():Stop()
					self:GetParent():CastAbilityOnTarget(allies[RandomInt(1, #allies)], ability, -1)

					return
				else
					for k, v in pairs(enemies) do
						if v and IsValidEntity(v) and v:IsAlive() and not v:IsInvisible() and not v:IsInvulnerable() then
							self:GetParent():Stop()
							self:GetParent():CastAbilityOnTarget(v, ability, -1)
							return
						end
					end

					return
				end
			end
		else
			-- print("Unable to cast ability.")
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
