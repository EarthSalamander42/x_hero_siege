-- Author:	Cookies
-- Date:	05.11.2017

modifier_ai = modifier_ai or class({})
modifier_ai.XHS_LINK_CLIENT = true

local function IsBreakableTarget(target)
	if target == nil or target:IsNull() or target.GetUnitName == nil then return false end

	local unitName = target:GetUnitName()
	return unitName == "npc_dota_crate" or unitName == "npc_dota_chest" or unitName == "npc_dota_vase"
end

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

function modifier_ai:MovePastBreakable()
	local ancient = Entities:FindByName(nil, "dota_goodguys_fort")
	if ancient == nil then return end

	self.isAttacking = false
	self.parent.xhs_breakable_ignore_until = GameRules:GetGameTime() + 1.5
	self.parent:SetForceAttackTarget(nil)
	if self.parent.SetAttacking ~= nil then
		self.parent:SetAttacking(nil)
	end
	self.parent:Stop()
	ExecuteOrderFromTable({
		UnitIndex = self.parent:entindex(),
		OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
		Position = ancient:GetAbsOrigin(),
	})
end

function modifier_ai:OnIntervalThink()
	if self.parent:IsIllusion() then return end
	if Entities:FindByName(nil, "dota_goodguys_fort") == nil then return end
	if self.parent:IsStunned() or self.parent:IsSilenced() or self.parent:IsHexed() or self.parent:IsChanneling() or self.parent:GetCurrentActiveAbility() then return end

	local now = GameRules:GetGameTime()
	local aggroTarget = self.parent:GetAggroTarget()
	local attackTarget = self.parent:GetAttackTarget()

	-- Aggro is assigned before GetAttackTarget is always populated. Handle both
	-- states before the normal "already has a target" early return, otherwise a
	-- wave can remain permanently focused on an untouchable breakable.
	if IsBreakableTarget(aggroTarget) or IsBreakableTarget(attackTarget) then
		self:MovePastBreakable()
		return
	end
	if aggroTarget ~= nil then return end

	-- Wave creeps temporarily ignore breakable containers while they move past
	-- them. The wave controller owns that movement window; issuing another
	-- order here would make the creep oscillate between the crate and the lane.
	if self.parent.xhs_breakable_ignore_until ~= nil and now < self.parent.xhs_breakable_ignore_until then
		self.parent:SetForceAttackTarget(nil)
		return
	end

	if self.last_attack_time and now - self.last_attack_time < 0.5 then
		return
	end

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
			local ancient_position = ancient:GetAbsOrigin()

			-- print("Attack range:", attack_range)

			-- ignore VIPs
			for _, vip in pairs(CDungeonZone.VIPsAlive) do
				local vip_distance = (self.parent:GetAbsOrigin() - vip:GetAbsOrigin()):Length2D()
				-- this variable is to ignore vip if he is too close to the unit based on attack range or 600, whichever is lower

				-- print("VIP distance:", vip_distance)
				if vip_distance < attack_range then
					self.parent:SetForceAttackTarget(nil)
					ExecuteOrderFromTable({
						UnitIndex = self.parent:entindex(),
						OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
						Position = ancient_position,
					})
					-- print("VIP here, move to ancient")
					return
				end
			end

			-- ignore crates and chests
			local crates = Entities:FindAllByClassnameWithin("npc_dota_crate", self.parent:GetAbsOrigin(), attack_range + 500)
			local chests = Entities:FindAllByClassnameWithin("npc_dota_chest", self.parent:GetAbsOrigin(), attack_range + 500)

			if #crates > 0 or #chests > 0 then
				self:MovePastBreakable()
				-- print("Crate or chest here, move to ancient")
				return
			end

			if not self.isAttacking then
				self.parent:SetForceAttackTarget(nil)
				ExecuteOrderFromTable({
					UnitIndex = self.parent:entindex(),
					OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
					Position = ancient_position,
				})
			end
		end
		-- Muradin AI
	elseif self.ai_state == 3 then
		local random_int = RandomInt(1, 4)
		if self.last_goal ~= random_int and not self.parent:IsMoving() and not self.parent:IsAttacking() then
			ExecuteOrderFromTable({
				UnitIndex = self.parent:entindex(),
				OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
				Position = Entities:FindByName(nil, "roshan_wp_" .. random_int):GetAbsOrigin(),
			})
			self.last_goal = random_int
		end
	end

	-- print(self.parent:GetCurrentActiveAbility())
	-- print("Caster is not casting an ability")
	for ability_index = 0, GetUnitAbilityCount(self.parent) - 1 do
		local ability = GetUnitAbilityBySafeIndex(self.parent, ability_index)

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

				self.parent:Stop()
				self.parent:CastAbilityNoTarget(ability, -1)

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
			if IsBreakableTarget(keys.target) then
				self:MovePastBreakable()
				return
			end
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
			self.last_attack_time = GameRules:GetGameTime()
		end
	end
end
