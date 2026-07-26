modifier_companion = class({})
modifier_companion.XHS_LINK_CLIENT = true

local COMPANION_STATE_FOLLOWING = "following"
local COMPANION_STATE_EVADING = "evading"
local COMPANION_STATE_HIDDEN = "hidden"
local COMPANION_STATE_RETURNING = "returning"

local COMPANION_THREAT_RADIUS = 700
local COMPANION_EVADE_DISTANCE = 430
local COMPANION_HIDE_ENEMY_COUNT = 4
local COMPANION_HIDE_THREAT_DISTANCE = 220
local COMPANION_SAFE_DELAY = 3.5
local COMPANION_FOLLOW_ORDER_INTERVAL = 0.35
local COMPANION_RECENT_HIT_WINDOW = 1.25
local COMPANION_HIDE_HIT_COUNT = 4
local COMPANION_VANISH_DELAY = 0.18
local COMPANION_MAX_HIDE_DURATION = 4.5
local COMPANION_HIDE_COOLDOWN = 6.0

local function CompanionModifierLog(parent, message, ...)
	local entindex = parent ~= nil and not parent:IsNull() and parent:entindex() or -1
	local ok, formatted = pcall(string.format, tostring(message), ...)
	print(string.format("[XHS Companion] modifier ent=%s %s", tostring(entindex), ok and formatted or tostring(message)))
end

function modifier_companion:IsHidden() return true end

function modifier_companion:GetAbsoluteNoDamagePhysical() return 1 end

function modifier_companion:GetAbsoluteNoDamageMagical() return 1 end

function modifier_companion:GetAbsoluteNoDamagePure() return 1 end

function modifier_companion:CheckState()
	local state = {
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_INVULNERABLE] = true,
	}

	if self.is_flying == true or self.is_flying == 1 then
		state[MODIFIER_STATE_FLYING] = true
	end

	return state
end

function modifier_companion:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_VISUAL_Z_DELTA,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
end

function modifier_companion:GetVisualZDelta()
	if self.is_flying == true or self.is_flying == 1 then
		return 290
	end

	return 0
end

-- add "ultimate_scepter" + "enchant_totem_leap_from_battle"
function modifier_companion:GetActivityTranslationModifiers()
	if self:GetParent():GetModelName() == "models/heroes/phantom_assassin/pa_arcana.vmdl" then
		return "arcana"
	end

	return ""
end

function modifier_companion:OnCreated()
	if IsServer() then
		self.is_flying = false
		self.set_final_pos = false
		self.run_gesture_active = false
		self.next_follow_order_time = 0
		self.companion_state = COMPANION_STATE_FOLLOWING
		self.last_damage_time = -999
		self.last_threat_entindex = nil
		self.recent_hit_times = {}
		self.last_hero_health = nil
		self.hidden_by_combat = false
		self.hidden_since = nil
		self.combat_hide_cooldown_until = 0
		self.hidden_by_shared_state = false
		self.missing_hero_logged = false
		self:GetParent():RemoveNoDraw()
		CompanionModifierLog(self:GetParent(), "created model=%s origin=%s", tostring(self:GetParent():GetModelName()), tostring(self:GetParent():GetAbsOrigin()))

		if GetMapName() == "imba_1v1" then
			self:GetParent():Kill(nil, nil)
			return
		else
			self:StartIntervalThink(0.1)
		end

		if not self:GetParent().base_model then
			self:GetParent().base_model = self:GetParent():GetModelName()
		end

		if not self:GetParent():HasModifier("modifier_bloodseeker_thirst") then
			self:GetParent():AddNewModifier(self:GetParent(), nil, "modifier_bloodseeker_thirst", {})
		end

		self:GetParent():SetMoveCapability(DOTA_UNIT_CAP_MOVE_GROUND)

		if string.find(self:GetParent():GetModelName(), "flying") or self:GetParent().xhs_companion_is_flying == true then
			self.is_flying = true
			self:SetStackCount(1)
		end
	end

	if IsClient() then
		if self:GetStackCount() == 1 then
			self.is_flying = true
		end
	end
end

function modifier_companion:GetAssignedHero()
	local companion = self:GetParent()
	if companion == nil or companion:IsNull() or companion.GetPlayerOwner == nil then return nil end

	local player = companion:GetPlayerOwner()
	if player == nil or player.GetAssignedHero == nil then return nil end

	local hero = player:GetAssignedHero()
	if hero == nil or hero:IsNull() then return nil end

	return hero
end

function modifier_companion:IsValidThreat(unit, hero)
	if unit == nil or unit:IsNull() or hero == nil or hero:IsNull() then return false end
	if not unit:IsAlive() then return false end
	if unit:GetTeamNumber() == hero:GetTeamNumber() then return false end
	if unit.IsBuilding and unit:IsBuilding() then return false end
	if unit.IsWard and unit:IsWard() then return false end

	return true
end

function modifier_companion:GetRecentHitCount(now)
	now = now or GameRules:GetGameTime()
	self.recent_hit_times = self.recent_hit_times or {}

	local writeIndex = 1
	for _, hitTime in ipairs(self.recent_hit_times) do
		if now - hitTime <= COMPANION_RECENT_HIT_WINDOW then
			self.recent_hit_times[writeIndex] = hitTime
			writeIndex = writeIndex + 1
		end
	end

	for index = writeIndex, #self.recent_hit_times do
		self.recent_hit_times[index] = nil
	end

	return #self.recent_hit_times
end

function modifier_companion:RecordCombatHit(attacker, hero)
	local now = GameRules:GetGameTime()
	self.last_damage_time = now

	if self:IsValidThreat(attacker, hero) then
		self.last_threat_entindex = attacker:entindex()
	end

	self.recent_hit_times = self.recent_hit_times or {}
	table.insert(self.recent_hit_times, now)
	self:GetRecentHitCount(now)
end

function modifier_companion:GetThreatInfo(hero)
	local hero_origin = hero:GetAbsOrigin()
	local enemies = FindUnitsInRadius(
		hero:GetTeamNumber(),
		hero_origin,
		nil,
		COMPANION_THREAT_RADIUS,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		DOTA_UNIT_TARGET_FLAG_NONE,
		FIND_CLOSEST,
		false
	)

	local count = 0
	local nearest = nil
	local nearestDistance = nil
	local center = Vector(0, 0, 0)

	for _, enemy in pairs(enemies or {}) do
		if self:IsValidThreat(enemy, hero) then
			local origin = enemy:GetAbsOrigin()
			local distance = (origin - hero_origin):Length2D()
			count = count + 1
			center = center + origin

			if nearestDistance == nil or distance < nearestDistance then
				nearest = enemy
				nearestDistance = distance
			end
		end
	end

	local threat = nil
	if self.last_threat_entindex ~= nil then
		local lastThreat = EntIndexToHScript(self.last_threat_entindex)
		if self:IsValidThreat(lastThreat, hero) and (lastThreat:GetAbsOrigin() - hero_origin):Length2D() <= COMPANION_THREAT_RADIUS + 250 then
			threat = lastThreat
		end
	end

	if threat == nil then
		threat = nearest
	end

	local threatOrigin = nil
	if threat ~= nil then
		threatOrigin = threat:GetAbsOrigin()
	elseif count > 0 then
		threatOrigin = center / count
	end

	return {
		count = count,
		nearest = nearest,
		nearest_distance = nearestDistance or 99999,
		origin = threatOrigin,
	}
end

function modifier_companion:GetEvadePosition(hero, threatInfo)
	local hero_origin = hero:GetAbsOrigin()
	local threat_origin = threatInfo and threatInfo.origin or nil
	local direction = nil

	if threat_origin ~= nil and (hero_origin - threat_origin):Length2D() > 1 then
		direction = (hero_origin - threat_origin):Normalized()
	else
		local companion = self:GetParent()
		direction = companion ~= nil and not companion:IsNull() and (companion:GetAbsOrigin() - hero_origin) or RandomVector(1)
		if direction:Length2D() <= 1 then
			direction = RandomVector(1)
		else
			direction = direction:Normalized()
		end
	end

	return hero_origin + direction * COMPANION_EVADE_DISTANCE
end

function modifier_companion:PlayCompanionParticle(effectName)
	local companion = self:GetParent()
	if companion == nil or companion:IsNull() then return end

	local particle = ParticleManager:CreateParticle(effectName, PATTACH_ABSORIGIN_FOLLOW, companion)
	ParticleManager:ReleaseParticleIndex(particle)
end

function modifier_companion:HideForCombat()
	if self.hidden_by_combat == true then return end

	local companion = self:GetParent()
	if companion == nil or companion:IsNull() then return end

	self.hidden_by_combat = true
	self.hidden_since = GameRules:GetGameTime()
	self.companion_state = COMPANION_STATE_HIDDEN
	self.next_follow_order_time = 0
	companion:Stop()
	CompanionModifierLog(companion, "combat hide state=%s origin=%s", tostring(self.companion_state), tostring(companion:GetAbsOrigin()))
	self:PlayCompanionParticle("particles/items_fx/blink_dagger_start.vpcf")

	Timers:CreateTimer(COMPANION_VANISH_DELAY, function()
		if self == nil then return end
		local parent = self:GetParent()
		if parent ~= nil and not parent:IsNull() and self.hidden_by_combat == true then
			parent:AddNoDraw()
		end
	end)
end

function modifier_companion:ReturnFromCombat(hero)
	local companion = self:GetParent()
	if companion == nil or companion:IsNull() or hero == nil or hero:IsNull() then return end

	local return_position = hero:GetAbsOrigin() + RandomVector(RandomInt(160, 240))
	FindClearSpaceForUnit(companion, return_position, false)
	companion:RemoveNoDraw()
	CompanionModifierLog(companion, "combat return origin=%s hero_origin=%s", tostring(companion:GetAbsOrigin()), tostring(hero:GetAbsOrigin()))
	self:PlayCompanionParticle("particles/items_fx/blink_dagger_end.vpcf")
	self.hidden_by_combat = false
	self.hidden_since = nil
	self.combat_hide_cooldown_until = GameRules:GetGameTime() + COMPANION_HIDE_COOLDOWN
	self.companion_state = COMPANION_STATE_RETURNING
	self.next_follow_order_time = 0

	Timers:CreateTimer(0.45, function()
		if self == nil then return end
		if self.companion_state == COMPANION_STATE_RETURNING then
			self.companion_state = COMPANION_STATE_FOLLOWING
		end
	end)
end

function modifier_companion:OnTakeDamage(keys)
	if not IsServer() then return end
	if keys == nil or keys.damage == nil or keys.damage <= 0 then return end

	local hero = self:GetAssignedHero()
	if hero == nil or keys.unit ~= hero then return end

	local attacker = keys.attacker
	if not self:IsValidThreat(attacker, hero) then return end

	self:RecordCombatHit(attacker, hero)
end

--[[
local anti_spam = false
function modifier_companion:OnAttacked(keys)
local target = keys.target

	if IsServer() then
		if target == self:GetParent() then
			if anti_spam == false then
				anti_spam = true
				target:EmitSound("Companion.Llama")
				Timers:CreateTimer(5.0, function()
					anti_spam = false
				end)
			end
		end
	end
end
--]]
function modifier_companion:GetModifierMoveSpeedBonus_Constant()
	return self:GetStackCount()
end

function modifier_companion:OnIntervalThink()
	if IsServer() then
		local companion = self:GetParent()

		-- npc_dota_base_additive does not reliably drive locomotion for courier/hero cosmetics.
		if companion:IsMoving() then
			if self.run_gesture_active ~= true then
				companion:StartGesture(ACT_DOTA_RUN)
				self.run_gesture_active = true
			end
		elseif self.run_gesture_active == true then
			companion:FadeGesture(ACT_DOTA_RUN)
			self.run_gesture_active = false
		end

		local hero = self:GetAssignedHero()
		if hero == nil then
			if self.missing_hero_logged ~= true then
				self.missing_hero_logged = true
				CompanionModifierLog(companion, "waiting for assigned hero/player owner")
			end
			return
		end
		if self.missing_hero_logged == true then
			CompanionModifierLog(companion, "assigned hero recovered ent=%s", tostring(hero:entindex()))
			self.missing_hero_logged = false
		end
		hero.companion = companion
		local fountain_abs = Vector(0, 0, 0)
		local map_name = GetMapName()

		if map_name == "imbathrow_ffa" then
			fountain_abs = Entities:FindByName(nil, "@overboss"):GetAbsOrigin()
		elseif map_name == "imba_demo" then
			for _, ent in pairs(Entities:FindAllByClassname("ent_dota_fountain")) do
				if ent:GetTeamNumber() == companion:GetTeamNumber() then
					fountain_abs = ent:GetAbsOrigin()
					break
				end
			end
		elseif map_name == "pudgewars_new" then
			fountain_abs = _G.rune_spell_caster_good:GetAbsOrigin()
		elseif map_name == "battle_royale_ffa" or map_name == "battle_royale_2v2v2v2v2" then
			-- These maps intentionally use the world origin as their return point.
		else
			if hero:GetTeamNumber() == DOTA_TEAM_GOODGUYS and GoodCamera then
				fountain_abs = GoodCamera:GetAbsOrigin()
			elseif hero:GetTeamNumber() == DOTA_TEAM_BADGUYS and BadCamera then
				fountain_abs = BadCamera:GetAbsOrigin()
			end
		end

		local hero_origin = hero:GetAbsOrigin()
		local hero_distance = (hero_origin - companion:GetAbsOrigin()):Length()
		local fountain_distance = (fountain_abs - companion:GetAbsOrigin()):Length()
		local min_distance = 250
		local blink_distance = 750
		local now = GameRules:GetGameTime()
		local hero_health = hero:GetHealth()
		if self.last_hero_health ~= nil and hero_health < self.last_hero_health - 1 and hero:IsAlive() then
			self:RecordCombatHit(nil, hero)
		end
		self.last_hero_health = hero_health

		local threatInfo = self:GetThreatInfo(hero)
		local recentCombat = now - (self.last_damage_time or -999) <= COMPANION_SAFE_DELAY
		local recentHitCount = self:GetRecentHitCount(now)
		local crowdedDanger = threatInfo.count >= COMPANION_HIDE_ENEMY_COUNT
		local highDanger = now >= (self.combat_hide_cooldown_until or 0) and recentCombat and (
			crowdedDanger
			or threatInfo.nearest_distance <= COMPANION_HIDE_THREAT_DISTANCE
			or recentHitCount >= COMPANION_HIDE_HIT_COUNT
		)
		local hiddenDuration = self.hidden_since ~= nil and now - self.hidden_since or 0
		local safeToReturn = (
			not recentCombat
			and threatInfo.nearest_distance > COMPANION_HIDE_THREAT_DISTANCE
		) or hiddenDuration >= COMPANION_MAX_HIDE_DURATION

		if companion:GetIdealSpeed() ~= hero:GetIdealSpeed() - 70 then
			companion:SetBaseMoveSpeed(hero:GetIdealSpeed() - 70)
		end

		-- This thing crashes with Treant's Nature's Guise
		-- Also using static lists for invisibltiy modifiers is just asking for trouble
		-- for _,v in pairs(IMBA_INVISIBLE_MODIFIERS) do
		-- if not hero:HasModifier(v) then
		-- if companion:HasModifier(v) then
		-- companion:RemoveModifierByName(v)
		-- end
		-- else
		-- if not companion:HasModifier(v) then
		-- companion:AddNewModifier(companion, nil, v, {})
		-- break -- remove this break if you want to add multiple modifiers at the same time
		-- end
		-- end
		-- end

		if hero:IsInvisible() then
			companion:AddNewModifier(companion, nil, "modifier_invisible", {})
		else
			companion:RemoveModifierByNameAndCaster("modifier_invisible", companion)
		end

		local sharedHideReason = nil
		for _, modifierName in ipairs(SHARED_NODRAW_MODIFIERS or {}) do
			if hero:HasModifier(modifierName) then
				sharedHideReason = modifierName
				break
			end
		end
		if sharedHideReason == nil and self:IsSignificantlyAboveGround(hero) then
			sharedHideReason = "above_ground"
		end

		if sharedHideReason ~= nil then
			if self.hidden_by_shared_state ~= true or self.shared_hide_reason ~= sharedHideReason then
				CompanionModifierLog(companion, "NoDraw on reason=%s hero_origin=%s", tostring(sharedHideReason), tostring(hero:GetAbsOrigin()))
			end
			self.hidden_by_shared_state = true
			self.shared_hide_reason = sharedHideReason
			companion:AddNoDraw()
			return
		elseif self.hidden_by_shared_state == true then
			self.hidden_by_shared_state = false
			self.shared_hide_reason = nil
			if self.hidden_by_combat ~= true then
				companion:RemoveNoDraw()
				CompanionModifierLog(companion, "NoDraw off after shared/terrain state")
			end
		end

		if self.hidden_by_combat == true then
			if not hero:IsAlive() then
				return
			end

			if not safeToReturn then
				return
			end

			self:ReturnFromCombat(hero)
			return
		end

		if highDanger then
			self:HideForCombat()
			return
		end

		if recentCombat and hero:IsAlive() then
			self.companion_state = COMPANION_STATE_EVADING
			local evade_position = self:GetEvadePosition(hero, threatInfo)
			if now >= (self.next_follow_order_time or 0) or not companion:IsMoving() then
				ExecuteOrderFromTable({
					UnitIndex = companion:entindex(),
					OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
					Position = evade_position,
				})
				self.next_follow_order_time = now + COMPANION_FOLLOW_ORDER_INTERVAL
			end

			self:SetStackCount(hero_distance / 4)
			return
		elseif self.companion_state == COMPANION_STATE_EVADING then
			self.companion_state = COMPANION_STATE_FOLLOWING
			self.next_follow_order_time = 0
		end

		if hero_distance < min_distance then
			if hero:IsMoving() == false and self.set_final_pos == false then
				self.set_final_pos = true
				local move_position = hero:GetAbsOrigin() + RandomVector(200)
				ExecuteOrderFromTable({
					UnitIndex = companion:entindex(),
					OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
					Position = move_position,
				})
				return
			elseif hero:IsMoving() and self.set_final_pos == true then
				self.set_final_pos = false
			end
		elseif hero_distance > blink_distance then
			companion:Blink(hero_origin + RandomVector(RandomInt(150, 300)), true, false)
			companion:Stop()
			self.next_follow_order_time = 0
		elseif hero_distance > min_distance then
			if now >= (self.next_follow_order_time or 0) or not companion:IsMoving() then
				local companion_origin = companion:GetAbsOrigin()
				local direction = companion_origin - hero_origin
				if direction:Length2D() < 1 then
					direction = RandomVector(1)
				else
					direction = direction:Normalized()
				end

				local follow_distance = hero:IsMoving() and 190 or 150
				local follow_position = hero_origin + direction * follow_distance
				ExecuteOrderFromTable({
					UnitIndex = companion:entindex(),
					OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
					Position = follow_position,
				})
				self.next_follow_order_time = now + 0.35
			end
		elseif fountain_distance > blink_distance and not hero:IsAlive() then -- min_distance is too high with fountain bound radius
			FindClearSpaceForUnit(companion, fountain_abs, false)
			companion:Stop()
			return
		end

		self:SetStackCount(hero_distance / 4)
	end
end

function modifier_companion:IsSignificantlyAboveGround(hero)
	if hero == nil or hero:IsNull() then return false end
	local origin = hero:GetAbsOrigin()
	local groundHeight = GetGroundHeight(origin, hero)
	return origin.z - groundHeight > 128
end
