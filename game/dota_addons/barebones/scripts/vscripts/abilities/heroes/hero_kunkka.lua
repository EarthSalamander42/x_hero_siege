
-------------------------------------------
--			  TORRENT
-------------------------------------------

imba_kunkka_torrent = class({})
LinkLuaModifier("modifier_imba_torrent_handler", "abilities/heroes/hero_kunkka", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_torrent_cast", "abilities/heroes/hero_kunkka", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_torrent_slow_tide", "abilities/heroes/hero_kunkka", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_torrent_slow", "abilities/heroes/hero_kunkka", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_sec_torrent_slow", "abilities/heroes/hero_kunkka", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_torrent_phase", "abilities/heroes/hero_kunkka", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_kunkka_torrent_talent_thinker", "abilities/heroes/hero_kunkka", LUA_MODIFIER_MOTION_NONE)

function imba_kunkka_torrent:GetAbilityTextureName()
	return "kunkka_torrent"
end

function imba_kunkka_torrent:GetIntrinsicModifierName()
	return "modifier_imba_torrent_handler"
end

function imba_kunkka_torrent:OnSpellStart()
	if IsServer() then
		local caster = self:GetCaster()
		local target = self:GetCaster():GetAbsOrigin()

		-- Parameters
		local vision_duration = 4
		local first_delay = self:GetSpecialValueFor("launch_delay")

		local radius = self:GetSpecialValueFor("radius")
		local slow_duration = self:GetSpecialValueFor("slow_duration")
		local stun_duration = self:GetSpecialValueFor("stun_duration")
		local damage = self:GetSpecialValueFor("damage")
		local sec_torrent_count = 0
		local sec_torrent_stun = self:GetSpecialValueFor("sec_torrent_stun")
		local sec_torrent_damage = self:GetSpecialValueFor("sec_torrent_damage")
		local sec_torrent_slow_duration = self:GetSpecialValueFor("sec_torrent_slow_duration")
		local tick_count = self:GetSpecialValueFor("tick_count")
		local torrent_height = self:GetSpecialValueFor("torrent_height")


		-- Calculates the damage to deal per tick
		local tick_interval = stun_duration / tick_count
		local damage_tick = damage / tick_count
		vision_duration = vision_duration + (sec_torrent_count * 2)

		-- Set slow duration (After stun)
		slow_duration = slow_duration + stun_duration
		sec_torrent_slow_duration = sec_torrent_slow_duration + sec_torrent_stun

		self:CreateVisibilityNode(target, radius, vision_duration)

		local bubbles_pfx = ParticleManager:CreateParticleForTeam("particles/hero/kunkka/torrent_bubbles.vpcf", PATTACH_ABSORIGIN, caster, caster:GetTeam())
		ParticleManager:SetParticleControl(bubbles_pfx, 0, target)
		ParticleManager:SetParticleControl(bubbles_pfx, 1, Vector(radius,0,0))
		local bubbles_sec_pfc

		EmitSoundOnLocationForAllies(target, "Ability.pre.Torrent", caster)

		-- Setting these as variables due to Rubick error stuff
		local target_team			= self:GetAbilityTargetTeam()
		local target_type			= self:GetAbilityTargetType()
		local target_flags			= self:GetAbilityTargetFlags()
		local damage_type			= self:GetAbilityDamageType()
		local sec_torrent_radius	= self:GetSpecialValueFor("sec_torrent_radius")

		-- Cast for each count
		for torrent_count = 0, sec_torrent_count, 1
		do
			local delay = first_delay + (torrent_count * 2)
			-- Start after the delay
			Timers:CreateTimer(delay, function()
					-- Parameters for secoundary Torrents
					if torrent_count > 0 then
						damage_tick = sec_torrent_damage / tick_count
						stun_duration = sec_torrent_stun
						torrent_height = torrent_height / 1.5
						radius = sec_torrent_radius
					end

					-- Destroy initial bubble-particle & create secoundary visible for both teams
					if torrent_count == 0 then
						ParticleManager:DestroyParticle(bubbles_pfx, false)
						ParticleManager:ReleaseParticleIndex(bubbles_pfx)
						bubbles_sec_pfc = ParticleManager:CreateParticleForTeam("particles/hero/kunkka/torrent_bubbles.vpcf", PATTACH_ABSORIGIN, caster, caster:GetTeam())
						ParticleManager:SetParticleControl(bubbles_sec_pfc, 0, target)
						ParticleManager:SetParticleControl(bubbles_sec_pfc, 1, Vector(radius,0,0))
					end

					-- Destroy bubbles if it was the last torrent
					if torrent_count == sec_torrent_count then
						ParticleManager:DestroyParticle(bubbles_sec_pfc, false)
						ParticleManager:ReleaseParticleIndex(bubbles_sec_pfc)
					end

					-- Finds affected enemies
					local enemies = FindUnitsInRadius(caster:GetTeam(), target, nil, radius, target_team, target_type, target_flags, 0, false)

					-- Torrent response if an enemy was hit 30%
					if (#enemies > 0) and (caster:GetName() == "npc_dota_hero_kunkka") then
						if math.random(1,10) < 3 then
							caster:EmitSound("kunkka_kunk_ability_torrent_0"..math.random(1,4))
						end
					end
					-- Iterate through affected enemies
					for _,enemy in pairs(enemies) do

						-- Deals the initial damage
						ApplyDamage({victim = enemy, attacker = caster, ability = self, damage = damage_tick, damage_type = damage_type})
						local current_ticks = 0
						local randomness_x = 0
						local randomness_y = 0

						-- Calculates the knockback position (for Tsunami)
						local torrent_border = ( enemy:GetAbsOrigin() - target ):Normalized() * ( radius + 100 )
						local distance_from_center = ( enemy:GetAbsOrigin() - target ):Length2D()
						if not ( tsunami and torrent_count == 0 ) then
							distance_from_center = 0
						else
							-- Some randomness to tsunami-torrent for smoother animation
							randomness_x = math.random() * math.random(-30,30)
							randomness_y = math.random() * math.random(-30,30)
						end

						-- Knocks the target up
						local knockback =
						{
							should_stun = 1,
							knockback_duration = stun_duration,
							duration = stun_duration,
							knockback_distance = distance_from_center,
							knockback_height = torrent_height,
							center_x = (target + torrent_border).x + randomness_x,
							center_y = (target + torrent_border).y + randomness_y,
							center_z = (target + torrent_border).z
						}

						-- Apply knockback on enemies hit
						enemy:RemoveModifierByName("modifier_knockback")
						enemy:AddNewModifier(caster, self, "modifier_knockback", knockback):SetDuration(stun_duration, true)
						enemy:AddNewModifier(caster, self, "modifier_imba_torrent_phase", {duration = stun_duration})

						-- Deals tick damage tick_count times
						Timers:CreateTimer(function()
								if current_ticks < tick_count then
									ApplyDamage({victim = enemy, attacker = caster, ability = self, damage = damage_tick, damage_type = damage_type})
									current_ticks = current_ticks + 1
									return tick_interval
								end
							end)

						-- Applies the slow
						if torrent_count == 0 then
							enemy:AddNewModifier(caster, self, "modifier_imba_torrent_slow", {duration = slow_duration})
							if extra_slow then
								enemy:AddNewModifier(caster, self, "modifier_imba_torrent_slow_tide", {duration = slow_duration})
							end
						else
							enemy:AddNewModifier(caster, self, "modifier_imba_sec_torrent_slow", {duration = sec_torrent_slow_duration})
						end
					end

					-- Creates the post-ability sound effect
					EmitSoundOnLocationWithCaster(target, "Ability.Torrent", caster)

					-- Draws the particle
					local particle = "particles/hero/kunkka/torrent_splash.vpcf"
					local torrent_fx = ParticleManager:CreateParticle(particle, PATTACH_CUSTOMORIGIN, caster)
					ParticleManager:SetParticleControl(torrent_fx, 0, target)
					ParticleManager:SetParticleControl(torrent_fx, 1, Vector(radius,0,0))
					ParticleManager:ReleaseParticleIndex(torrent_fx)
				end)
		end
	end
end

function imba_kunkka_torrent:IsHiddenWhenStolen()
	return false
end

function imba_kunkka_torrent:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end


-----------------------------------
-- MODIFIER_IMBA_TORRENT_HANDLER --
-----------------------------------

modifier_imba_torrent_handler = class({})

function modifier_imba_torrent_handler:IsHidden()	return true end

function modifier_imba_torrent_handler:OnIntervalThink()
	if not IsServer() then return end

	if self:GetAbility():GetAutoCastState() and self:GetAbility():IsFullyCastable() and not self:GetAbility():IsInAbilityPhase() and not self:GetCaster():IsHexed() and not self:GetCaster():IsNightmared() and not self:GetCaster():IsOutOfGame() and not self:GetCaster():IsSilenced() and not self:GetCaster():IsStunned() and not self:GetCaster():IsChanneling() then
		self:GetCaster():SetCursorPosition(self:GetCaster():GetAbsOrigin())
		self:GetAbility():CastAbility()
	end
end

function modifier_imba_torrent_handler:DeclareFunctions()
	local decFuncs = {MODIFIER_EVENT_ON_ORDER, MODIFIER_PROPERTY_IGNORE_CAST_ANGLE, MODIFIER_PROPERTY_DISABLE_TURNING}
	
	return decFuncs
end

function modifier_imba_torrent_handler:OnOrder(keys)
	if not IsServer() or keys.unit ~= self:GetParent() then return end
	
	if keys.ability == self:GetAbility() then
		if keys.order_type == DOTA_UNIT_ORDER_CAST_POSITION and (keys.new_pos - self:GetCaster():GetAbsOrigin()):Length2D() <= self:GetAbility():GetCastRange(self:GetCaster():GetCursorPosition(), self:GetCaster()) + self:GetCaster():GetCastRangeBonus() then
			self.bActive = true
		else
			self.bActive = false
		end
	else
		self.bActive = false
	end
end

function modifier_imba_torrent_handler:GetModifierIgnoreCastAngle()
	if not IsServer() or self.bActive == false then return end
	return 1
end

function modifier_imba_torrent_handler:GetModifierDisableTurning()
	if not IsServer() or self.bActive == false then return end
	return 1
end

modifier_imba_torrent_phase = class({})

function modifier_imba_torrent_phase:CheckState()
	local state = {[MODIFIER_STATE_NO_UNIT_COLLISION] = true}
	return state
end

function modifier_imba_torrent_phase:IsHidden()
	return true
end

function modifier_imba_torrent_phase:IsDebuff()
	return true
end

modifier_imba_torrent_slow_tide = class({})

function modifier_imba_torrent_slow_tide:IsHidden()
	return true
end

function modifier_imba_torrent_slow_tide:IsDebuff()
	return true
end

function modifier_imba_torrent_slow_tide:IsPurgable()
	return true
end

modifier_imba_torrent_slow = class({})

function modifier_imba_torrent_slow:DeclareFunctions()
	local decFuncs =
	{
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
	}
	return decFuncs
end

function modifier_imba_torrent_slow:GetModifierMoveSpeedBonus_Percentage( )
	local ability = self:GetAbility()
	local slow = ability:GetSpecialValueFor("main_slow")
	if self:GetParent():HasModifier("modifier_imba_torrent_slow_tide")then
		slow = slow + ability:GetSpecialValueFor("tide_red_slow")
	end
	return slow * (-1)
end

function modifier_imba_torrent_slow:IsHidden()
	return false
end

function modifier_imba_torrent_slow:IsDebuff()
	return true
end

function modifier_imba_torrent_slow:IsPurgable()
	return true
end

modifier_imba_sec_torrent_slow = class({})

function modifier_imba_sec_torrent_slow:DeclareFunctions()
	local decFuncs =
	{
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
	}
	return decFuncs
end

function modifier_imba_sec_torrent_slow:GetModifierMoveSpeedBonus_Percentage( )
	return ( self:GetAbility():GetSpecialValueFor("sec_torrent_slow") * (-1) )
end

function modifier_imba_sec_torrent_slow:IsHidden()
	return false
end

function modifier_imba_sec_torrent_slow:IsDebuff()
	return true
end

function modifier_imba_sec_torrent_slow:IsPurgable()
	return true
end

-- Modifier for casting torrent without showing cast direction
-- Modifier is added in the OrderFilter in imba.lua !
modifier_imba_torrent_cast = class({})

function modifier_imba_torrent_cast:DeclareFunctions()
	local decFuncs =
	{
		MODIFIER_PROPERTY_IGNORE_CAST_ANGLE,
		MODIFIER_PROPERTY_DISABLE_TURNING
	}
	return decFuncs
end

function modifier_imba_torrent_cast:GetModifierIgnoreCastAngle( params )
	return 1
end

function modifier_imba_torrent_cast:GetModifierDisableTurning( params )
	return 1
end

function modifier_imba_torrent_cast:IsHidden()
	return false
end

-- Do a stop order after finish casting to prevent turning to the destination point
function modifier_imba_torrent_cast:OnDestroy( params )
	if IsServer() then
		local stopOrder =
		{
			UnitIndex = self:GetCaster():entindex(),
			OrderType = DOTA_UNIT_ORDER_STOP
		}
		ExecuteOrderFromTable( stopOrder )
	end
end

modifier_imba_kunkka_torrent_talent_thinker = class({})

function modifier_imba_kunkka_torrent_talent_thinker:IsHidden()
	return false
end

function modifier_imba_kunkka_torrent_talent_thinker:IsPurgable()
	return false
end

function modifier_imba_kunkka_torrent_talent_thinker:OnCreated(keys)
	if IsServer() then
		-- Ability properties
		self.caster = self:GetCaster()
		self.ability = self:GetAbility()
		self.min_interval = self.caster:FindTalentValue("special_bonus_imba_kunkka_4","min_interval") * 10
		self.max_interval = self.caster:FindTalentValue("special_bonus_imba_kunkka_4") * 10

		self.tick = (math.random() + math.random(self.min_interval, self.max_interval)) / 10

		-- Parameters
		-- fuck you vectors
		self.pos = Vector(keys.pos_x,keys.pos_y,keys.pos_z)
		self.affected_radius = keys.affected_radius
		self.sec_torrent_radius = keys.sec_torrent_radius
		self.sec_torrent_stun = keys.sec_torrent_stun
		self.sec_torrent_count = keys.sec_torrent_count
		self.sec_torrent_damage = keys.sec_torrent_damage
		self.sec_torrent_slow_duration = keys.sec_torrent_slow_duration
		self.tick_count = keys.tick_count
		self.torrent_height = keys.torrent_height

		-- Ability specials
		self:StartIntervalThink(self.tick)
	end
end

function modifier_imba_kunkka_torrent_talent_thinker:OnIntervalThink()
	if IsServer() then
		local interval = (math.random() + math.random(self.min_interval, ((self:GetRemainingTime()+self.tick) * 10))) / 10
		-- Re-roll the interval
		self.tick = (math.random() + math.random(self.min_interval, self.max_interval)) / 10
		Timers:CreateTimer(interval, function()

				-- Parameters for secoundary Torrents
				local random_radius = math.random(0, self.affected_radius)
				local random_vector = self.pos + RandomVector(random_radius)
				damage_tick = self.sec_torrent_damage / self.tick_count
				stun_duration = self.sec_torrent_stun
				torrent_height = self.torrent_height / 1.5
				radius = self.sec_torrent_radius
				tick_interval = stun_duration / self.tick_count

				-- Finds affected enemies
				local enemies = FindUnitsInRadius(self.caster:GetTeam(), random_vector, nil, radius, self.ability:GetAbilityTargetTeam(), self.ability:GetAbilityTargetType(), self.ability:GetAbilityTargetFlags(), 0, false)

				-- Torrent response if an enemy was hit 30%
				if (#enemies > 0) and (self.caster:GetName() == "npc_dota_hero_kunkka") then
					if math.random(1,10) < 3 then
						self.caster:EmitSound("kunkka_kunk_ability_torrent_0"..math.random(1,4))
					end
				end
				-- Iterate through affected enemies
				for _,enemy in pairs(enemies) do

					-- Deals the initial damage
					ApplyDamage({victim = enemy, attacker = self.caster, ability = self.ability, damage = damage_tick, damage_type = self.ability:GetAbilityDamageType()})
					local current_ticks = 0
					local randomness_x = 0
					local randomness_y = 0

					-- Calculates the knockback position (for Tsunami)
					local torrent_border = ( enemy:GetAbsOrigin() - random_vector ):Normalized() * ( radius + 100 )
					local distance_from_center = 0

					-- Knocks the target up
					local knockback =
					{
						should_stun = 1,
						knockback_duration = stun_duration,
						duration = stun_duration,
						knockback_distance = distance_from_center,
						knockback_height = torrent_height,
						center_x = (random_vector + torrent_border).x + randomness_x,
						center_y = (random_vector + torrent_border).y + randomness_y,
						center_z = (random_vector + torrent_border).z
					}

					-- Apply knockback on enemies hit
					enemy:RemoveModifierByName("modifier_knockback")
					enemy:AddNewModifier(self.caster, self.ability, "modifier_knockback", knockback)
					enemy:AddNewModifier(self.caster, self.ability, "modifier_imba_torrent_phase", {duration = stun_duration})

					-- Deals tick damage tick_count times
					Timers:CreateTimer(function()
							-- TODO: tick count can be nil for some reason
							if tick_count ~= nil and current_ticks < tick_count then
								ApplyDamage({victim = enemy, attacker = self.caster, ability = self.ability, damage = damage_tick, damage_type = self.ability:GetAbilityDamageType()})
								current_ticks = current_ticks + 1
								return tick_interval
							end
						end)


					enemy:AddNewModifier(self.caster, self.ability, "modifier_imba_sec_torrent_slow", {duration = self.sec_torrent_slow_duration})
				end

				-- Creates the post-ability sound effect
				EmitSoundOnLocationWithCaster(random_vector, "Ability.Torrent", caster)

				-- Draws the particle
				local particle = "particles/hero/kunkka/torrent_splash.vpcf"
				local torrent_fx = ParticleManager:CreateParticle(particle, PATTACH_CUSTOMORIGIN, self.caster)
				ParticleManager:SetParticleControl(torrent_fx, 0, random_vector)
				ParticleManager:SetParticleControl(torrent_fx, 1, Vector(radius,0,0))
				ParticleManager:ReleaseParticleIndex(torrent_fx)

			end)
	end
end

-------------------------------------------
--			GHOSTSHIP
-------------------------------------------

imba_kunkka_ghostship = class({})
LinkLuaModifier("modifier_imba_ghostship_rum", "abilities/heroes/hero_kunkka", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_ghostship_rum_damage", "abilities/heroes/hero_kunkka", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_ghostship_tide_slow", "abilities/heroes/hero_kunkka", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_imba_ghostship_drag", "abilities/heroes/hero_kunkka", LUA_MODIFIER_MOTION_NONE)


function imba_kunkka_ghostship:OnSpellStart()
	if IsServer() then
		-- Preventing projectiles getting stuck in one spot due to potential 0 length vector
		if self:GetCursorPosition() == self:GetCaster():GetAbsOrigin() then
			self:GetCaster():SetCursorPosition(self:GetCursorPosition() + self:GetCaster():GetForwardVector())
		end
	
		local caster = self:GetCaster()
		local target = self:GetCursorPosition()

		-- Parameters
		local scepter = caster:HasScepter()
		local damage = self:GetSpecialValueFor("damage")
		local speed = self:GetSpecialValueFor("ghostship_speed")
		local radius = self:GetSpecialValueFor("ghostship_width")
		local start_distance = self:GetSpecialValueFor("start_distance")
		local crash_distance = self:GetSpecialValueFor("crash_distance")
		local stun_duration = self:GetSpecialValueFor("stun_duration")
		local buff_duration = self:GetSpecialValueFor("buff_duration")
		local crash_delay = 0
		local caster_pos = caster:GetAbsOrigin()

		-- Check buffs by Ebb and Flow
--		local tsunami = caster:HasModifier("modifier_imba_ebb_and_flow_tsunami")
		-- Flood Tide
--		if caster:HasModifier("modifier_imba_ebb_and_flow_tide_flood") or tsunami then
--			damage = damage + self:GetSpecialValueFor("tide_flood_damage")
--		end
		-- High Tide
--		if caster:HasModifier("modifier_imba_ebb_and_flow_tide_high") or tsunami then
--			if scepter then
--				radius = radius + self:GetSpecialValueFor("scepter_tide_high_radius")
--			end
--			radius = radius + self:GetSpecialValueFor("tide_high_radius")
--		end
		-- Wave Tide
--		if caster:HasModifier("modifier_imba_ebb_and_flow_tide_wave") or tsunami then
--			speed = speed + self:GetSpecialValueFor("tide_wave_speed")
--		end
		-- Red Tide
--		local extra_slow = false
--		if caster:HasModifier("modifier_imba_ebb_and_flow_tide_red") or tsunami then
--			extra_slow = true
--		end
		-- Tsunami exclusive
--		if tsunami then
--			stun_duration = stun_duration + self:GetSpecialValueFor("tsunami_stun")
--		end

		-- Calculate spawn and crash positions
		local closest_target = true
		local spawn_pos
		local boat_direction
		local crash_pos
		local travel_time

		-- Response on cast
		if caster:GetName() == "npc_dota_hero_kunkka" then
			caster:EmitSound("kunkka_kunk_ability_ghostshp_0"..math.random(1,3))
		end

		-- Scepter check
		if scepter then
			local scepter_damage = damage * (self:GetSpecialValueFor("buff_duration") / 100)
			-- Wave Tide
			if caster:HasModifier("modifier_imba_ebb_and_flow_tide_wave") or tsunami then
				crash_delay = self:GetSpecialValueFor("scepter_tide_wave_delay")
			else
				crash_delay = self:GetSpecialValueFor("scepter_crash_delay")
			end

			spawn_pos = target

			boat_direction = ( target - caster_pos ):Normalized()
			crash_pos = target + boat_direction * (start_distance + crash_distance) * (-1)
		end

		-- In case the ability is stolen don't cast the next tide
--		if caster:HasAbility("imba_kunkka_ebb_and_flow") and not ( caster:HasModifier("modifier_imba_ebb_and_flow_tide_low") and not scepter ) then
--			local ability_tide = caster:FindAbilityByName("imba_kunkka_ebb_and_flow")
--			ability_tide:CastAbility()
--		end

		if not scepter then
			boat_direction = ( target - caster_pos ):Normalized()
			crash_pos = target
			spawn_pos = target + boat_direction * (start_distance + crash_distance) * (-1)
		end

		travel_time = ((start_distance + crash_distance - radius ) / speed )
		local bubbles_pfx
		-- Aghanims crushing down
		if scepter then
			local height = 1000
			local ticks = FrameTime()
			local travel = 0
			local float_boat = spawn_pos + Vector(0,0,height)
			local height_ticks = height *  ticks / crash_delay * (-1)
			self:CreateVisibilityNode(target, radius, crash_delay + 1 )
			bubbles_pfx = ParticleManager:CreateParticle("particles/hero/kunkka/torrent_bubbles.vpcf", PATTACH_ABSORIGIN, caster)
			ParticleManager:SetParticleControl(bubbles_pfx, 0, target)
			ParticleManager:SetParticleControl(bubbles_pfx, 1, Vector(radius,0,0))
			Timers:CreateTimer((crash_delay + 1), function()
					ParticleManager:DestroyParticle(bubbles_pfx, false)
					ParticleManager:ReleaseParticleIndex(bubbles_pfx)
				end)
			local boat_pfx = ParticleManager:CreateParticle("particles/econ/items/kunkka/kunkka_immortal/kunkka_immortal_ghost_ship.vpcf", PATTACH_ABSORIGIN, caster)
			ParticleManager:SetParticleControl(boat_pfx, 0, (spawn_pos - boat_direction * (-1) * crash_distance ) )
			Timers:CreateTimer(ticks, function()
					float_boat = float_boat + Vector(0,0,height_ticks)
					ParticleManager:SetParticleControl(boat_pfx, 3, float_boat )

					travel = travel + ticks
					if travel > crash_delay then

						-- Water Nova on hit + crash sound
						local water_fx = ParticleManager:CreateParticle("particles/econ/items/kunkka/kunkka_immortal/kunkka_immortal_ghost_ship_splash.vpcf", PATTACH_CUSTOMORIGIN, caster)
						ParticleManager:SetParticleControl(water_fx, 3, target)
						Timers:CreateTimer(2, function()
								ParticleManager:DestroyParticle(water_fx, false)
								ParticleManager:ReleaseParticleIndex(water_fx)
							end)

						-- Stunning and rooting all hit enemies
						local enemies = FindUnitsInRadius(caster:GetTeam(), target, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, self:GetAbilityTargetType(), 0, 0, false)
						for k, enemy in pairs(enemies) do
							--enemy:AddNewModifier(caster, self, "modifier_stunned", {duration = travel_time})
							--enemy:AddNewModifier(caster, self, "modifier_rooted", { duration = travel_time})

							-- Deal crash damage to enemies hit
							ApplyDamage({victim = enemy, attacker = caster, ability = self, damage = damage, damage_type = self:GetAbilityDamageType()})
						end

						-- Setting ship underneath the world + deleting it
						ParticleManager:SetParticleControl(boat_pfx, 3, ( float_boat - Vector(0,0,500)) )
						ParticleManager:DestroyParticle(boat_pfx, false)
						ParticleManager:ReleaseParticleIndex(boat_pfx)
						return nil
					end
					return ticks
				end)
		end

		Timers:CreateTimer(crash_delay, function()
				self:CreateVisibilityNode(crash_pos, radius, travel_time + 2 )
				local boat_velocity
				if caster:HasScepter() then
					boat_velocity = boat_direction * speed * (-1)
				else
					boat_velocity = boat_direction * speed
				end
				-- Spawn the boat
				local boat_projectile = {
					Ability = self,
					EffectName = "particles/econ/items/kunkka/kunkka_immortal/kunkka_immortal_ghost_ship.vpcf",
					vSpawnOrigin = spawn_pos,
					fDistance = start_distance + crash_distance - radius,
					fStartRadius = radius,
					fEndRadius = radius,
					fExpireTime = GameRules:GetGameTime() + travel_time + 2,
					Source = caster,
					bHasFrontalCone = false,
					bReplaceExisting = false,
					bProvidesVision = false,
					iUnitTargetTeam = self:GetAbilityTargetTeam(),
					iUnitTargetType = self:GetAbilityTargetType(),
					vVelocity = boat_velocity,
					ExtraData =
					{
						crash_x = crash_pos.x,
						crash_y = crash_pos.y,
						crash_z = crash_pos.z,
						speed = speed,
						radius = radius
					}
				}
				ProjectileManager:CreateLinearProjectile(boat_projectile)

				EmitSoundOnLocationWithCaster( spawn_pos, "Ability.Ghostship.bell", caster )
				EmitSoundOnLocationWithCaster( spawn_pos, "Ability.Ghostship", caster )

				-- Show visual crash point effect to allies only
				local crash_pfx = ParticleManager:CreateParticleForTeam("particles/econ/items/kunkka/kunkka_immortal/kunkka_immortal_ghost_ship_marker.vpcf", PATTACH_ABSORIGIN, caster, caster:GetTeam())
				ParticleManager:SetParticleControl(crash_pfx, 0, crash_pos )
				-- Destroy particle after the crash
				Timers:CreateTimer(travel_time, function()
						ParticleManager:DestroyParticle(crash_pfx, false)
						ParticleManager:ReleaseParticleIndex(crash_pfx)

						-- Fire sound on crash point
						EmitSoundOnLocationWithCaster(crash_pos, "Ability.Ghostship.crash", caster)

						-- Stun and damage enemies
						local enemies = FindUnitsInRadius(caster:GetTeam(), crash_pos, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, self:GetAbilityTargetType(), 0, 0, false)
						if (not (#enemies > 0)) and (caster:GetName() == "npc_dota_hero_kunkka") then
							if math.random(1,2) == 1 then
								caster:EmitSound("kunkka_kunk_ability_failure_0"..math.random(1,2))
							end
						end
						for k, enemy in pairs(enemies) do
							ApplyDamage({victim = enemy, attacker = caster, ability = self, damage = damage, damage_type = self:GetAbilityDamageType()})
							if extra_slow then
								enemy:AddNewModifier(caster, self, "modifier_imba_ghostship_tide_slow", { duration = stun_duration + self:GetSpecialValueFor("tide_red_slow_duration") })
							end
							enemy:AddNewModifier(caster, self, "modifier_stunned", { duration = stun_duration })
						end
					end)
			end)
	end
end

function imba_kunkka_ghostship:IsHiddenWhenStolen()
	return false
end

function imba_kunkka_ghostship:GetCastRange( location , target)
	local caster = self:GetCaster()
	local range = self.BaseClass.GetCastRange(self,location,target)
	if caster:HasScepter() then
		range = self:GetSpecialValueFor("scepter_cast_range")
	end
	if caster:HasModifier("modifier_imba_ebb_and_flow_tide_low") or caster:HasModifier("modifier_imba_ebb_and_flow_tsunami") then
		range = range + self:GetSpecialValueFor("scepter_tide_low_range")
	end
	return range
end

function imba_kunkka_ghostship:GetAOERadius()
	local caster = self:GetCaster()
	if (not caster:HasScepter()) then return 0 end
	local radius = self:GetSpecialValueFor("ghostship_width")
	return radius
end

function imba_kunkka_ghostship:OnProjectileHit_ExtraData(target, location, ExtraData)
	if target then
		local caster = self:GetCaster()
		
		-- If the target hit is on the same team as the caster, give them the rum buff and do nothing else
		if caster:GetTeam() == target:GetTeam() then
			local duration = self:GetSpecialValueFor("buff_duration")
			target:AddNewModifier(caster, self, "modifier_imba_ghostship_rum", { duration = duration })
			-- #4 Talent: Ghostship now drags Kunkka into the target location
				return false
		end
		
		-- Rest of this code is for enemy interaction
		
		-- The exact location where the boat is going to finish impact
		local crash_pos =  Vector(ExtraData.crash_x,ExtraData.crash_y,ExtraData.crash_z)
		-- The exact location where the enemy makes contact with the boat
		local target_pos = target:GetAbsOrigin()
		-- 
		local knockback_origin = target_pos + (target_pos - crash_pos):Normalized() * 100
		-- Distnace between target and crash location
		local distance = (crash_pos - target_pos ):Length2D()
		local duration = ((location - crash_pos ):Length2D() - ExtraData.radius) / ExtraData.speed

		
		-- Apply the knockback modifier
		local knockback =
		{	should_stun = 0,
			knockback_duration = duration,
			duration = duration,
			knockback_distance = distance,
			knockback_height = 0,
			center_x = knockback_origin.x + (math.random() * math.random(-10,10)),
			center_y = knockback_origin.y + (math.random() * math.random(-10,10)),
			center_z = knockback_origin.z
		}
		-- Apply a new modifier to drag
		if target == caster then
			ghostship_drag = target:AddNewModifier(caster,self,"modifier_imba_ghostship_drag", {duration = duration})
			if ghostship_drag then
				ghostship_drag.crash_pos = crash_pos
				ghostship_drag.direction = (crash_pos - target_pos):Normalized()
				ghostship_drag.ship_width = ExtraData.radius
				ghostship_drag.ship_speed = ExtraData.speed
			end
		else
			target:RemoveModifierByName("modifier_knockback")
			target:AddNewModifier(caster, nil, "modifier_knockback", knockback)
		end
	end
	return false
end

modifier_imba_ghostship_drag = class({})

function modifier_imba_ghostship_drag:IsHidden()
	return false
end

function modifier_imba_ghostship_drag:IsPurgable()
	return false
end

function modifier_imba_ghostship_drag:IsDebuff()
	return false
end

function modifier_imba_ghostship_drag:RemoveOnDeath()
	return false
end

function modifier_imba_ghostship_drag:StatusEffectPriority()
	return 20
end

function modifier_imba_ghostship_drag:CheckState()
	local state = {
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}
	return state
end

function modifier_imba_ghostship_drag:GetMotionControllerPriority()
	return DOTA_MOTION_CONTROLLER_PRIORITY_HIGH
end

function modifier_imba_ghostship_drag:OnCreated()
	if IsServer() then
		self.caster = self:GetCaster()
		self.ability = self:GetAbility()
		self.tick = FrameTime()

		self:StartIntervalThink(self.tick)
	end
end

function modifier_imba_ghostship_drag:OnIntervalThink()
	-- Check for motion controllers
	if self:CheckMotionControllers() then
	else
		self:Destroy()
		return nil
	end

	self:GetDragged()
end

function modifier_imba_ghostship_drag:GetDragged()
	if IsServer() then
		self.current_loc = self.caster:GetAbsOrigin()
		self.new_loc = self.current_loc + self.direction * self.ship_speed * self.tick
		self.distance = (self.crash_pos - self.current_loc):Length2D()

		Timers:CreateTimer(self.tick, function()
				if not self:IsNull() then
					self.next_loc = self.caster:GetAbsOrigin()
					self.distance_between_ship = (self.next_loc - self.current_loc):Length2D()
					-- If Kunkka exits the Ghost ship, remove the drag force.
					if self.distance_between_ship > (self.ship_width/2) then
						self:Destroy()
					end
				end
			end)
		-- If the distance is more than 20, set Kunkka to the new dragged location
		if self.distance > 20 then
			self.caster:SetAbsOrigin(self.new_loc)
		else
			self.caster:SetAbsOrigin(self.crash_pos)
			self.caster:SetUnitOnClearGround()
			self:Destroy()
		end
	end
end

function modifier_imba_ghostship_drag:OnDestroy()
	if IsServer() then
		if self.caster:HasModifier("modifier_item_forcestaff_active") or self.caster:HasModifier("modifier_item_hurricane_pike_active") or self.caster:HasModifier("modifier_item_hurricane_pike_active_alternate") then
		else
			self.caster:SetUnitOnClearGround()
		end
	end
end

modifier_imba_ghostship_rum = class({})

function modifier_imba_ghostship_rum:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("rum_speed")
end

-- Setting up the damage counter
function modifier_imba_ghostship_rum:OnCreated()
	if IsServer() then
		self.damage_counter = 0
	end
end

function modifier_imba_ghostship_rum:GetCustomIncomingDamagePct()
	return self:GetAbility():GetSpecialValueFor("rum_reduce_pct") * (-1)
end

function modifier_imba_ghostship_rum:DeclareFunctions()
	local decFuncs =
	{
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
	return decFuncs
end

function modifier_imba_ghostship_rum:OnTakeDamage( params )
	if IsServer() then
		if params.unit == self:GetParent() then
			local rum_reduction = (100 - self:GetAbility():GetSpecialValueFor("rum_reduce_pct"))/100
			local gen_reduction = (100 + params.unit:GetIncomingDamagePct())/100
			local prevented_damage = params.damage / rum_reduction - params.damage

			self.damage_counter = self.damage_counter + prevented_damage
		end
	end
end

function modifier_imba_ghostship_rum:OnDestroy()
	if IsServer() then
		local caster = self:GetCaster()
		local ability = self:GetAbility()
            self:GetParent():AddNewModifier(caster, ability, "modifier_imba_ghostship_rum_damage", { duration = ability:GetSpecialValueFor("damage_duration"), stored_damage = self.damage_counter })
		self.damage_counter = 0
	end
end

function modifier_imba_ghostship_rum:GetStatusEffectName()
	return "particles/status_fx/status_effect_rum.vpcf"
end

function modifier_imba_ghostship_rum:StatusEffectPriority()
	return 10
end

function modifier_imba_ghostship_rum:GetTexture()
	return "kunkka_ghostship"
end

function modifier_imba_ghostship_rum:IsHidden()
	return false
end

function modifier_imba_ghostship_rum:IsPurgable()
	return false
end

function modifier_imba_ghostship_rum:IsDebuff( )
	return false
end

modifier_imba_ghostship_rum_damage = class({})

function modifier_imba_ghostship_rum_damage:GetCustomIncomingDamagePct()
	return self:GetAbility():GetSpecialValueFor("rum_reduce_pct")
end

function modifier_imba_ghostship_rum_damage:IsHidden()
	return false
end

function modifier_imba_ghostship_rum_damage:GetTexture()
	return "kunkka_ghostship"
end

function modifier_imba_ghostship_rum_damage:IsPurgable()
	return false
end

function modifier_imba_ghostship_rum_damage:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_imba_ghostship_rum_damage:IsDebuff( )
	return true
end

function modifier_imba_ghostship_rum_damage:OnCreated( params )
	if IsServer() then
		local ability = self:GetAbility()
		local parent = self:GetParent()

		local damage_duration = ability:GetSpecialValueFor("damage_duration")
		local damage_interval = ability:GetSpecialValueFor("damage_interval")
		local ticks = damage_duration / damage_interval
		local damage_amount = params.stored_damage / ticks
		local current_tick = 0

		Timers:CreateTimer(damage_interval, function()
				-- If the target has died, do nothing
				if parent:IsAlive() then

					-- Nonlethal HP removal
					local target_hp = parent:GetHealth()
					if target_hp - damage_amount < 1 then
						parent:SetHealth(1)
					else
						parent:SetHealth(target_hp - damage_amount)
					end

					current_tick = current_tick + 1
					if current_tick >= ticks then
						return nil
					else
						return damage_interval
					end
				else
					return nil
				end
			end)
	end
end

modifier_imba_ghostship_tide_slow = class({})

function modifier_imba_ghostship_tide_slow:DeclareFunctions()
	local decFuncs =
	{
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
	}
	return decFuncs
end

function modifier_imba_ghostship_tide_slow:GetModifierMoveSpeedBonus_Percentage( )
	return ( self:GetAbility():GetSpecialValueFor("tide_red_slow") * (-1) )
end

function modifier_imba_ghostship_tide_slow:IsDebuff()
	return true
end

function modifier_imba_ghostship_tide_slow:IsPurgable()
	return true
end

function modifier_imba_ghostship_tide_slow:IsHidden()
	return false
end

function modifier_imba_ghostship_tide_slow:RemoveOnDeath()
	return true
end
