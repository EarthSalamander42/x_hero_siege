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
		MODIFIER_EVENT_ON_ATTACK_START,
		MODIFIER_EVENT_ON_ATTACK_FAIL,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
	}
end

function modifier_ai:CheckState()
	local state = {}

	--	state[MODIFIER_STATE_NO_UNIT_COLLISION]	= true
	return state
end

function modifier_ai:OnCreated(params)
	if IsServer() then
		self.parent = self:GetParent()
		self.last_movement = 0.0
		self.find_enemy_distance = 1000
		self.ai_state = params.state
		self.isAttacking = false

		self:StartIntervalThink(1.0)

		-- print("Add AI to unit:", self.parent:GetUnitName())
	end
end

function modifier_ai:OnIntervalThink()
	if self.parent:IsIllusion() then return end
	if Entities:FindByName(nil, "dota_goodguys_fort") == nil then return end

	if self.parent:IsStunned() or self.parent:IsSilenced() or self.parent:IsHexed() or self.parent:IsChanneling() or self.parent:GetCurrentActiveAbility() then return end

	-- print("AI: Ready to work!:", self.parent:GetUnitName())

	-- Move to ancient if no target
	if self.ai_state == 1 then
		-- print(self.parent:GetUnitName() .. " is attacking? ", self.isAttacking)
		-- print(self.parent:GetUnitName() .. " is attacking? ", self.isAttacking)
		local ancient = Entities:FindByName(nil, "dota_goodguys_fort")
		local distance = (self.parent:GetAbsOrigin() - ancient:GetAbsOrigin()):Length2D()

		if distance < 500 then
			self.parent:SetAttacking(ancient)
			-- print("Attack ancient")
			return
		else
			local attack_range = math.max(self.parent:Script_GetAttackRange(), 800)

			-- print("Attack range:", attack_range)

			-- ignore VIPs
			for _, vip in pairs(CDungeonZone.VIPsAlive) do
				local vip_distance = (self.parent:GetAbsOrigin() - vip:GetAbsOrigin()):Length2D()
				-- this variable is to ignore vip if he is too close to the unit based on attack range or 600, whichever is lower

				-- print("VIP distance:", vip_distance)
				if vip_distance < attack_range then
					self.parent:SetForceAttackTarget(nil)
					self.parent:MoveToPosition(ancient:GetAbsOrigin())
					-- print("VIP here, move to ancient")
					return
				end
			end

			-- ignore crates and chests
			local crates = Entities:FindAllByClassnameWithin("npc_dota_crate", self.parent:GetAbsOrigin(), attack_range + 500)
			local chests = Entities:FindAllByClassnameWithin("npc_dota_chest", self.parent:GetAbsOrigin(), attack_range + 500)

			if #crates > 0 or #chests > 0 then
				self.parent:SetForceAttackTarget(nil)
				self.parent:MoveToPosition(ancient:GetAbsOrigin())
				-- print("Crate or chest here, move to ancient")
				return
			end

			if not self.isAttacking then
				self.parent:SetForceAttackTarget(nil)
				self.parent:MoveToPositionAggressive(ancient:GetAbsOrigin())
			end
		end
		-- Muradin AI
	elseif self.ai_state == 3 then
		local random_int = RandomInt(1, 4)
		if self.last_goal ~= random_int and not self.parent:IsMoving() and not self.parent:IsAttacking() then
			self.parent:MoveToPositionAggressive(Entities:FindByName(nil, "roshan_wp_" .. random_int):GetAbsOrigin())
			self.last_goal = random_int
		end
	end

	-- print(self.parent:GetCurrentActiveAbility())
	-- print("Caster is not casting an ability")
	for ability_index = 0, self.parent:GetAbilityCount() - 1 do
		local ability = self.parent:GetAbilityByIndex(ability_index)

		if ability and not ability:IsInAbilityPhase() and not ability:IsPassive() and ability:IsActivated() and ability:IsCooldownReady() and ability:GetLevel() > 0 then
			-- print("Ability is castable:", ability:GetAbilityName())
			local cast_range = ability:GetCastRange(self.parent:GetCursorPosition(), self.parent) or self.find_enemy_distance
			local target_team = ability:GetAbilityTargetTeam()
			local target_type = ability:GetAbilityTargetType()
			if target_team == 0 then target_team = 2 end -- TEAM_ENEMY
			if target_type == 0 then target_type = 19 end -- DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
			-- local target_flags = ability:GetAbilityTargetFlags()
			if cast_range == 0 then cast_range = self.find_enemy_distance end
			-- print("Cast Range:", cast_range)
			cast_range = cast_range * 0.9 -- 90% of the range to allow projectiles hit the target. e.g: Mirana's Starfall
			local allies = FindUnitsInRadius(self.parent:GetTeamNumber(), self.parent:GetAbsOrigin(), nil, cast_range, self.parent:GetTeamNumber(), target_type, ability:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)
			local enemies = FindUnitsInRadius(self.parent:GetTeamNumber(), self.parent:GetAbsOrigin(), nil, cast_range, target_team, target_type, ability:GetAbilityTargetFlags(), FIND_ANY_ORDER, false)

			-- print(#enemies)
			if #enemies == 0 then
				-- print("range / enemies / behavior:", self.parent:GetUnitName(), ability:GetAbilityName(), cast_range, #enemies, target_team, target_type)
				if bit.band(tonumber(tostring(ability:GetBehavior())), DOTA_ABILITY_BEHAVIOR_TOGGLE) == DOTA_ABILITY_BEHAVIOR_TOGGLE then
					if ability:GetToggleState() == true then
						ability:ToggleAbility()
					end
				end

				return
			elseif #enemies == 1 and IsValidEntity(enemies[1]) and not enemies[1]:IsInvisible() then
				for _, restricted_ab in pairs(_G.multiplayer_abilities_cast) do
					if ability:GetAbilityName() == restricted_ab then
						-- print("Casting this ability in solo mode is restricted!!")
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
					-- print(self.parent:GetHealthPercent(), ability:GetSpecialValueFor("health_threshold"))
					if self.parent:GetHealthPercent() <= ability:GetSpecialValueFor("health_threshold") then
						self.parent:Stop()
						self.parent:CastAbilityNoTarget(ability, -1)
					end
				else
					self.parent:Stop()
					self.parent:CastAbilityNoTarget(ability, -1)
				end

				return
			elseif bit.band(tonumber(tostring(ability:GetBehavior())), DOTA_ABILITY_BEHAVIOR_POINT) == DOTA_ABILITY_BEHAVIOR_POINT then
				self.parent:Stop()
				for k, v in pairs(enemies) do
					if v and IsValidEntity(v) and v:IsAlive() and not v:IsInvisible() and not v:IsInvulnerable() then
						local position = v:GetAbsOrigin()

						ExecuteOrderFromTable({
							UnitIndex = self.parent:entindex(),
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

				if self.parent:GetTeam() == ability:GetAbilityTargetTeam() then
					self.parent:Stop()
					self.parent:CastAbilityOnTarget(allies[RandomInt(1, #allies)], ability, -1)

					return
				else
					for k, v in pairs(enemies) do
						if v and IsValidEntity(v) and v:IsAlive() and not v:IsInvisible() and not v:IsInvulnerable() then
							self.parent:Stop()
							self.parent:CastAbilityOnTarget(v, ability, -1)
							return
						end
					end

					return
				end
			end
		else
			-- print(self.parent:GetUnitName() .. " unable to cast ability.")
		end
	end
end

function modifier_ai:OnAttackStart(keys)
	if IsServer() then
		if self.parent == keys.attacker then
			self.isAttacking = true
		end
	end
end

function modifier_ai:OnAttackFail(keys)
	if IsServer() then
		if self.parent == keys.attacker then
			self.isAttacking = false
		end
	end
end

function modifier_ai:OnAttackLanded(keys)
	if IsServer() then
		local attacker = keys.attacker

		if self.parent == attacker then
			self.isAttacking = false
		end
	end
end
