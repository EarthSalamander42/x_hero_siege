-- Nevermore AI thinker

boss_thinker_nevermore = class({})

function boss_thinker_nevermore:IsHidden()
	return true
end

function boss_thinker_nevermore:IsPurgable()
	return false
end

function boss_thinker_nevermore:OnCreated( params )
	if IsServer() then
		self.boss_name = "nevermore"
		self.team = 2
		if params.team then
			self.team = params.team
		end

		local boss = self:GetParent()

		-- Abilities
		local difficulty = GameRules:GetCustomGameDifficulty()
		boss:FindAbilityByName("frostivus_boss_necromastery"):SetLevel(difficulty)
		boss:FindAbilityByName("frostivus_boss_immolation"):SetLevel(difficulty)
		boss:FindAbilityByName("frostivus_boss_ragna_blade"):SetLevel(difficulty)
		boss:FindAbilityByName("frostivus_boss_meteorain"):SetLevel(difficulty)
		boss:FindAbilityByName("frostivus_boss_shadowraze"):SetLevel(difficulty)
		boss:FindAbilityByName("frostivus_boss_soul_harvest"):SetLevel(difficulty)
		boss:FindAbilityByName("frostivus_boss_nevermore"):SetLevel(difficulty)
		boss:FindAbilityByName("frostivus_boss_requiem_of_souls"):SetLevel(difficulty)

		-- Cosmetics
		boss:SetRenderColor(0, 0, 0)
		boss.head = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/items/nevermore/diabolical_fiend_head/diabolical_fiend_head.vmdl"})
		boss.head:FollowEntity(boss, true)
		boss.wings = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/shadow_fiend/arcana_wings.vmdl"})
		boss.wings:FollowEntity(boss, true)
		boss.wings:SetRenderColor(0, 0, 0)
		boss.shoulders = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/items/nevermore/ferrum_chiroptera_shoulder/ferrum_chiroptera_shoulder.vmdl"})
		boss.shoulders:FollowEntity(boss, true)
		boss.shoulders:SetRenderColor(0, 0, 0)
		boss.arms = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/items/nevermore/diabolical_fiend_arms/diabolical_fiend_arms.vmdl"})
		boss.arms:FollowEntity(boss, true)
		boss.arms:SetRenderColor(0, 0, 0)
		boss.hand = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/shadow_fiend/fx_shadow_fiend_arcana_hand.vmdl"})
		boss.hand:FollowEntity(boss, true)
		boss.hand:SetRenderColor(0, 0, 0)

		-- Draw boss ambient particles
		if not self.fire_pfx then
			local boss_loc = boss:GetAbsOrigin()
			self.fire_pfx = ParticleManager:CreateParticle("particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_ambient.vpcf", PATTACH_POINT_FOLLOW, boss)
			ParticleManager:SetParticleControlEnt(self.fire_pfx, 0, boss, PATTACH_POINT_FOLLOW, "attach_hitloc", boss_loc, true)
			ParticleManager:SetParticleControlEnt(self.fire_pfx, 1, boss, PATTACH_POINT_FOLLOW, "attach_arm_L", boss_loc, true)
			ParticleManager:SetParticleControlEnt(self.fire_pfx, 2, boss, PATTACH_POINT_FOLLOW, "attach_arm_L", boss_loc, true)
			ParticleManager:SetParticleControlEnt(self.fire_pfx, 3, boss, PATTACH_POINT_FOLLOW, "attach_arm_L", boss_loc, true)
			ParticleManager:SetParticleControlEnt(self.fire_pfx, 4, boss, PATTACH_POINT_FOLLOW, "attach_arm_R", boss_loc, true)
			ParticleManager:SetParticleControlEnt(self.fire_pfx, 5, boss, PATTACH_POINT_FOLLOW, "attach_arm_R", boss_loc, true)
			ParticleManager:SetParticleControlEnt(self.fire_pfx, 6, boss, PATTACH_POINT_FOLLOW, "attach_arm_R", boss_loc, true)
			ParticleManager:SetParticleControlEnt(self.fire_pfx, 7, boss, PATTACH_POINT_FOLLOW, "attach_head", boss_loc, true)
			ParticleManager:SetParticleControlEnt(self.fire_pfx, 8, boss, PATTACH_POINT_FOLLOW, "attach_hitloc", boss_loc, true)

			self.shoulders_pfx = ParticleManager:CreateParticle("particles/boss_nevermore/nevermore_shoulder_ambient.vpcf", PATTACH_POINT_FOLLOW, boss)
			ParticleManager:SetParticleControlEnt(self.shoulders_pfx, 0, boss, PATTACH_POINT_FOLLOW, "attach_shoulder_l", boss_loc, true)
			ParticleManager:SetParticleControlEnt(self.shoulders_pfx, 4, boss, PATTACH_POINT_FOLLOW, "attach_hitloc", boss_loc, true)
			ParticleManager:ReleaseParticleIndex(self.shoulders_pfx)

			self.shadow_trail_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_nevermore/nevermore_trail.vpcf", PATTACH_ABSORIGIN_FOLLOW, boss)
			ParticleManager:SetParticleControl(self.shadow_trail_pfx, 0, boss_loc)
			ParticleManager:ReleaseParticleIndex(self.shadow_trail_pfx)
		end

		-- Boss script constants
--		self.altar_loc = Vector(-25, 7211, 1231)
		self.altar_loc = Vector(0, 7018, 128)
		self.harvest_cooldown = 0

		-- Start thinking
		self.boss_timer = 0
		self.events = {}
		self:StartIntervalThink(0.1)
	end
end

function boss_thinker_nevermore:OnIntervalThink()
	if IsServer() then
		-- Parameters
		local boss = self:GetParent()

		if boss.deathStart == true then return end

		-- Soul Harvest logic
		if self.harvest_cooldown > 0 then
			self.harvest_cooldown = self.harvest_cooldown - 0.1
		else
			local nearby_enemies = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, boss:GetAbsOrigin(), nil, 550, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
			if #nearby_enemies >= 1 then

				-- Attack first target
				local damage = boss:GetAttackDamage() * 100 * 0.01 * self:GetNecromasteryAmp()
				self.harvest_cooldown = 4.0
				StartAnimation(boss, {duration = 1.04, activity=ACT_DOTA_ATTACK, rate=1.0})
				Timers:CreateTimer(0.5, function()
					local attack_projectile = {
						Target = nearby_enemies[1],
						Source = boss,
						Ability = boss:FindAbilityByName("frostivus_boss_soul_harvest"),
						EffectName = "particles/econ/items/shadow_fiend/sf_desolation/sf_base_attack_desolation_fire_arcana.vpcf",
						bDodgeable = true,
						bProvidesVision = false,
						bVisibleToEnemies = true,
						bReplaceExisting = false,
						iMoveSpeed = 1200,
						iVisionRadius = 0,
						iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,

					--	iVisionTeamNumber = boss:GetTeamNumber(),
						ExtraData = {damage = damage}
					}
					ProjectileManager:CreateTrackingProjectile(attack_projectile)
				end)
			end
		end

		-- Think
		self.boss_timer = self.boss_timer + 0.1
		self.random_position = self.altar_loc + RandomVector(10):Normalized() * 400

		if self.boss_timer > 170 then
			self.boss_timer = 0
			self.events = {}
		end

		-- Boss move script
		if self.boss_timer > 1 and not self.events[1] then
			boss:MoveToPosition(RotatePosition(self.altar_loc, QAngle(0, 180, 0), self.random_position))
			self:LineRaze(self.altar_loc)
			self.events[1] = true
		end

		if self.boss_timer > 6.5 and not self.events[2] then
			boss:MoveToPosition(RotatePosition(self.altar_loc, QAngle(0, 180, 0), self.random_position))
			self:Immolation(self.altar_loc)
			self.events[2] = true
		end

		if self.boss_timer > 11 and not self.events[3] then
			boss:MoveToPosition(self.altar_loc + Vector(0, 300, 0))
			self:Meteorain(self.altar_loc)
			self.events[3] = true
		end

		if self.boss_timer > 21.5 and not self.events[4] then
			boss:MoveToPosition(self.altar_loc + Vector(0, 300, 0))
			self:RagnaBlade(self.altar_loc)
			self.events[4] = true
		end

		if self.boss_timer > 26.5 and not self.events[5] then
			boss:MoveToPosition(self.altar_loc)
			self:CircleRaze(self.altar_loc)
			self.events[5] = true
		end

		if self.boss_timer > 31.5 and not self.events[6] then
			boss:MoveToPosition(self.altar_loc)
			self:Immolation(self.altar_loc)
			self.events[6] = true
		end

		if self.boss_timer > 36.5 and not self.events[7] then
			boss:MoveToPosition(self.altar_loc)
			self:RequiemOfSouls(self.altar_loc)
			self.events[7] = true
		end

		if self.boss_timer > 42 and not self.events[8] then
			boss:MoveToPosition(self.altar_loc)
			self:Meteorain(self.altar_loc)
			self.events[8] = true
		end

		if self.boss_timer > 52.5 and not self.events[9] then
			boss:MoveToPosition(self.altar_loc)
			self:CircleRaze(self.altar_loc)
			self.events[9] = true
		end

		if self.boss_timer > 52.5 and not self.events[10] then
			self:Nevermore(self.altar_loc)
			self.events[10] = true
		end

		if self.boss_timer > 60.5 and not self.events[11] then
			boss:MoveToPosition(self.altar_loc + Vector(0, 500, 0))
			self:Immolation(self.altar_loc)
			self.events[11] = true
		end

		if self.boss_timer > 66 and not self.events[12] then
			boss:MoveToPosition(self.altar_loc + Vector(0, 500, 0))
			self:RagnaBlade(self.altar_loc)
			self.events[12] = true
		end

		if self.boss_timer > 71 and not self.events[13] then
			boss:MoveToPosition(self.altar_loc + Vector(0, 500, 0))
			self:CircleRaze(self.altar_loc)
			self.events[13] = true
		end

		if self.boss_timer > 76 and not self.events[14] then
			boss:MoveToPosition(self.altar_loc + Vector(0, 500, 0))
			self:Immolation(self.altar_loc)
			self.events[14] = true
		end

		if self.boss_timer > 81 and not self.events[15] then
			boss:MoveToPosition(self.altar_loc + Vector(0, 500, 0))
			self:Meteorain(self.altar_loc)
			self.events[15] = true
		end

		if self.boss_timer > 91.5 and not self.events[16] then
			boss:MoveToPosition(self.altar_loc)
			self:RequiemOfSouls(self.altar_loc)
			self.events[16] = true
		end

		if self.boss_timer > 97 and not self.events[17] then
			boss:MoveToPosition(self.altar_loc + Vector(0, 500, 0))
			self:Meteorain(self.altar_loc)
			self.events[17] = true
		end

		if self.boss_timer > 97 and not self.events[18] then
			self:Nevermore(self.altar_loc)
			self.events[18] = true
		end

		if self.boss_timer > 105 and not self.events[19] then
			boss:MoveToPosition(self.altar_loc + Vector(0, 500, 0))
			self:RagnaBlade(self.altar_loc)
			self.events[19] = true
		end

		if self.boss_timer > 105 and not self.events[20] then
			boss:MoveToPosition(self.altar_loc + Vector(0, 500, 0))
			self:RequiemOfSouls(self.altar_loc)
			self.events[20] = true
		end

		if self.boss_timer > 110 and not self.events[21] then
			boss:MoveToPosition(self.altar_loc + Vector(0, 500, 0))
			self:RagnaBlade(self.altar_loc)
			self.events[21] = true
		end

		if self.boss_timer > 114.5 and not self.events[22] then
			boss:MoveToPosition(self.altar_loc + Vector(0, 500, 0))
			self:Meteorain(self.altar_loc)
			self.events[22] = true
		end

		if self.boss_timer > 114.5 and not self.events[23] then
			self:CircleRaze(self.altar_loc)
			self.events[23] = true
		end

		if self.boss_timer > 120 and not self.events[24] then
			boss:MoveToPosition(self.altar_loc + Vector(0, 500, 0))
			self:CircleRaze(self.altar_loc)
			self.events[24] = true
		end

		if self.boss_timer > 126 and not self.events[25] then
			boss:MoveToPosition(self.random_position)
			self:Immolation(self.altar_loc)
			self.events[25] = true
		end

		if self.boss_timer > 131.5 and not self.events[26] then
			boss:MoveToPosition(self.random_position)
			self:CircleRaze(self.altar_loc)
			self.events[26] = true
		end

		if self.boss_timer > 133.5 and not self.events[27] then
			boss:MoveToPosition(self.random_position)
			self:RagnaBlade(self.altar_loc)
			self.events[27] = true
		end

		if self.boss_timer > 135.5 and not self.events[28] then
			boss:MoveToPosition(self.random_position)
			self:CircleRaze(self.altar_loc)
			self.events[28] = true
		end

		if self.boss_timer > 137.5 and not self.events[29] then
			boss:MoveToPosition(self.random_position)
			self:Meteorain(self.altar_loc)
			self.events[29] = true
		end

		if self.boss_timer > 141 and not self.events[30] then
			self:Nevermore(self.altar_loc)
			self.events[30] = true
		end

		if self.boss_timer > 147 and not self.events[31] then
			boss:MoveToPosition(self.altar_loc)
			self:RequiemOfSouls(self.altar_loc)
			self.events[31] = true
		end

		if self.boss_timer > 151 and not self.events[32] then
			boss:MoveToPosition(self.random_position)
			self:Meteorain(self.altar_loc)
			self.events[32] = true
		end

		if self.boss_timer > 160 and not self.events[33] then
			self:Immolation(self.altar_loc)
			boss:MoveToPosition(self.random_position)
			self.events[33] = true
		end
	end
end

---------------------------
-- Auxiliary stuff
---------------------------

-- Returns current Necromastery bonus damage
function boss_thinker_nevermore:GetNecromasteryAmp()
	return 1 + self:GetParent():FindModifierByName("modifier_frostivus_necromastery"):GetStackCount() * 0.02
end

-- Adds one stack of Necromastery to SF
function boss_thinker_nevermore:ApplyNecromastery(amount)
	for i = 1, amount do
		self:GetParent():FindModifierByName("modifier_frostivus_necromastery"):IncrementStackCount()
	end
end

-- Raze a target location
function boss_thinker_nevermore:Raze(target, play_impact_sound)
	local ability = self:GetParent():FindAbilityByName("frostivus_boss_shadowraze")
	local delay = ability:GetSpecialValueFor("delay")
	local damage = ability:GetSpecialValueFor("damage")
	local radius = ability:GetSpecialValueFor("radius")
	print("Raze damage:", damage)

	-- Show warning pulses
	local warning_pfx = ParticleManager:CreateParticle("particles/boss_nevermore/pre_raze.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(warning_pfx, 0, target)
	ParticleManager:SetParticleControl(warning_pfx, 1, Vector(radius, 0, 0))
	ParticleManager:ReleaseParticleIndex(warning_pfx)

	Timers:CreateTimer(delay, function()	
		-- Sound
		if play_impact_sound then
			self:GetParent():EmitSound("Hero_Nevermore.Shadowraze")
		end

		-- Particles
		local raze_pfx = ParticleManager:CreateParticle("particles/boss_nevermore/raze_blast.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(raze_pfx, 0, target)
		ParticleManager:SetParticleControl(raze_pfx, 1, Vector(0, 0, 0))
		ParticleManager:ReleaseParticleIndex(raze_pfx)

		-- Hit enemies
		local hit_enemies = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, target, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		for _, enemy in pairs(hit_enemies) do
			-- Deal damage
			local damage_dealt = ApplyDamage({victim = enemy, attacker = self:GetParent(), ability = nil, damage = damage, damage_type = DAMAGE_TYPE_PURE})
			SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, enemy, damage_dealt, nil)

			-- Apply Necromastery
			self:ApplyNecromastery(1)
		end
	end)
end

-- Meteor a target location
function boss_thinker_nevermore:Meteor(altar_loc, target, radius, damage)
	-- Warning particle & sound
	self:GetParent():EmitSound("Hero_Invoker.ChaosMeteor.Cast")
	local warning_pfx = ParticleManager:CreateParticle("particles/boss_nevermore/meteorain_pre.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(warning_pfx, 0, target)
	ParticleManager:SetParticleControl(warning_pfx, 1, Vector(radius, 0, 0))
	ParticleManager:ReleaseParticleIndex(warning_pfx)

	-- Meteor particle
	local meteor_pfx = ParticleManager:CreateParticle("particles/boss_nevermore/meteorain.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(meteor_pfx, 0, target + Vector(300, -300, 1000))
	ParticleManager:SetParticleControl(meteor_pfx, 1, target)
	ParticleManager:SetParticleControl(meteor_pfx, 2, Vector(1.5, 0, 0))
	ParticleManager:ReleaseParticleIndex(meteor_pfx)

	-- Meteor travel delay
	Timers:CreateTimer(1.5, function()
		-- Play impact sound
		self:GetParent():EmitSound("Hero_Invoker.ChaosMeteor.Impact")

		-- Hit enemies
		local hit_enemies = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, target, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		for _, enemy in pairs(hit_enemies) do
			-- Deal damage
			local damage_dealt = ApplyDamage({victim = enemy, attacker = self:GetParent(), ability = nil, damage = damage, damage_type = DAMAGE_TYPE_PURE})
			SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, enemy, damage_dealt, nil)

			-- Apply Necromastery
			self:ApplyNecromastery(1)
		end
	end)
end

---------------------------
-- Nevermore's moves
---------------------------

-- Inner Immolation
function boss_thinker_nevermore:Immolation(altar_loc)
	if IsServer() then
		local boss = self:GetParent()
			local ability = self:GetParent():FindAbilityByName("frostivus_boss_immolation")
			local delay = ability:GetSpecialValueFor("delay")
			local tick_damage = ability:GetSpecialValueFor("damage")
			local radius = ability:GetSpecialValueFor("radius")

		-- Send cast bar event
--		if cast_bar == 1 then
--			BossPhaseAbilityCast(self.team, "frostivus_boss_immolation", "boss_nevermore_immolation", delay)
--		elseif cast_bar == 2 then
--			BossPhaseAbilityCastAlt(self.team, "frostivus_boss_immolation", "boss_nevermore_immolation", delay)
--		end

		-- Draw warning particle
		local warning_pfx = ParticleManager:CreateParticle("particles/boss_nevermore/immolation_warning.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(warning_pfx, 0, altar_loc)
		ParticleManager:SetParticleControl(warning_pfx, 1, Vector(375, 0, 0))

		-- Play warning sound
		self:GetParent():EmitSound("Frostivus.AbilityWarning")

		-- Animate boss cast
		Timers:CreateTimer(delay - 2.0, function()
			boss:FaceTowards(altar_loc)
			StartAnimation(boss, {duration = 2.2, activity=ACT_DOTA_GENERIC_CHANNEL_1, rate=1.0})
		end)

		-- Wait [delay] seconds
		Timers:CreateTimer(delay, function()
			-- Destroy warning particle
			ParticleManager:DestroyParticle(warning_pfx, true)
			ParticleManager:ReleaseParticleIndex(warning_pfx)

			-- Play cast sound
			boss:EmitSound("Hero_Lina.DragonSlave.FireHair")

			-- Apply the modifier to the altar
			boss:AddNewModifier(boss, nil, "modifier_frostivus_immolation", {damage = tick_damage, radius = radius})
		end)
	end
end

-- Immolation buff
LinkLuaModifier("modifier_frostivus_immolation", "boss_scripts/boss_thinker_nevermore.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_immolation = modifier_frostivus_immolation or class({})

function modifier_frostivus_immolation:IsHidden() return true end
function modifier_frostivus_immolation:IsPurgable() return false end
function modifier_frostivus_immolation:IsDebuff() return false end

function modifier_frostivus_immolation:OnCreated(keys)
	if IsServer() then
		self.tick_damage = keys.damage * 0.2
		self.radius = keys.radius
		self.tick_counter = 0

		-- Play initial particle
		self.immolation_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_ember_spirit/ember_spirit_flameguard.vpcf", PATTACH_ABSORIGIN_FOLLOW, nil)
		ParticleManager:SetParticleControl(self.immolation_pfx, 0, self:GetParent():GetAbsOrigin())
		ParticleManager:SetParticleControl(self.immolation_pfx, 1, Vector(self.radius, 1, 1))

		self:StartIntervalThink(0.2)
	end
end

function modifier_frostivus_immolation:OnDestroy()
	if IsServer() then
		ParticleManager:DestroyParticle(self.immolation_pfx, false)
		ParticleManager:ReleaseParticleIndex(self.immolation_pfx)
	end
end

function modifier_frostivus_immolation:OnIntervalThink()
	if IsServer() then

		-- Deal damage to enemies in the area
		local nearby_enemies = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, self:GetParent():GetAbsOrigin(), nil, self.radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		for _, enemy in pairs(nearby_enemies) do
			enemy:EmitSound("Hero_Invoker.ChaosMeteor.Damage")
			local damage_dealt = ApplyDamage({victim = enemy, attacker = self:GetParent(), ability = nil, damage = self.tick_damage * RandomInt(90, 110) * 0.01, damage_type = DAMAGE_TYPE_PURE})
			SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, enemy, damage_dealt, nil)
		end

		-- If it's time, play the particle again
		self.tick_counter = self.tick_counter + 0.2
		if self.tick_counter >= 2.0 then
			self:GetParent():EmitSound("Frostivus.ImmolateLoop")
			self.tick_counter = 0
		end
	end
end

-- Ragna Blade
function boss_thinker_nevermore:RagnaBlade(altar_loc, delay)
	if IsServer() then
		local boss = self:GetParent()
		local ability = boss:FindAbilityByName("frostivus_boss_ragna_blade")
		local target_amount = ability:GetSpecialValueFor("target_amount")
		local damage_pct = ability:GetSpecialValueFor("damage_pct")
		local delay = ability:GetSpecialValueFor("delay")

		-- Look for valid targets
		local targets = {}
		local nearby_enemies = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, altar_loc, nil, 1800, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		for _,enemy in pairs(nearby_enemies) do
			targets[#targets + 1] = enemy
			if #targets >= target_amount then
				break
			end
		end

		-- If there's no valid target, do nothing
		if #targets <= 0 then
			return nil
		end

		-- Send cast bar event
--		if cast_bar == 1 then
--			BossPhaseAbilityCast(self.team, "frostivus_boss_ragna_blade", "boss_nevermore_ragna_blade", delay)
--		elseif cast_bar == 2 then
--			BossPhaseAbilityCastAlt(self.team, "frostivus_boss_ragna_blade", "boss_nevermore_ragna_blade", delay)
--		end

		-- Draw warning particle on the targets' position
		for _, target in pairs(targets) do
			local warning_pfx = ParticleManager:CreateParticle("particles/boss_nevermore/ragna_blade_pre_warning.vpcf", PATTACH_OVERHEAD_FOLLOW, target)
			ParticleManager:SetParticleControl(warning_pfx, 0, target:GetAbsOrigin())

			-- Play warning sound
			target:EmitSound("Frostivus.AbilityWarning")

			Timers:CreateTimer(delay, function()
				ParticleManager:DestroyParticle(warning_pfx, true)
				ParticleManager:ReleaseParticleIndex(warning_pfx)
			end)
		end

		-- Animate boss cast
		Timers:CreateTimer(delay - 0.85, function()
			boss:FaceTowards(targets[1]:GetAbsOrigin())
			StartAnimation(boss, {duration = 1.75, activity=ACT_DOTA_VICTORY, rate=2.0})
		end)

		-- Wait [delay] seconds
		Timers:CreateTimer(delay, function()
			-- Play cast sound
			boss:EmitSound("Hero_Lina.LagunaBlade.Immortal")

			for _,target in pairs(targets) do
				-- Play impact sound
				target:EmitSound("Hero_Lina.LagunaBladeImpact.Immortal")

				-- Play impact particle
				local impact_pfx = ParticleManager:CreateParticle("particles/boss_nevermore/ragna_blade.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
				ParticleManager:SetParticleControlEnt(impact_pfx, 0, boss, PATTACH_POINT_FOLLOW, "attach_head", boss:GetAbsOrigin(), true)
				ParticleManager:SetParticleControlEnt(impact_pfx, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
				ParticleManager:ReleaseParticleIndex(impact_pfx)

				-- Deal damage
				local damage = target:GetMaxHealth() / 100 * damage_pct
				local damage_dealt = ApplyDamage({victim = target, attacker = boss, ability = nil, damage = damage, damage_type = DAMAGE_TYPE_PURE})
				SendOverheadEventMessage(nil, OVERHEAD_ALERT_DAMAGE, target, damage_dealt, nil)

				-- Apply Necromastery
				self:ApplyNecromastery(1)
			end
		end)
	end
end

-- Meteorain
function boss_thinker_nevermore:Meteorain(altar_loc)
	if IsServer() then
		local boss = self:GetParent()
		local ability = self:GetParent():FindAbilityByName("frostivus_boss_meteorain")
		local impact_damage = ability:GetSpecialValueFor("damage")
		local radius = ability:GetSpecialValueFor("radius")
		local duration = ability:GetSpecialValueFor("duration")
		local delay = ability:GetSpecialValueFor("delay")
		local spawn_delay = ability:GetSpecialValueFor("spawn_delay")
		local spawn_amount = ability:GetSpecialValueFor("spawn_amount")
		print("Meteor damage:", impact_damage)

		-- Send cast bar event
--		if cast_bar == 1 then
--			BossPhaseAbilityCast(self.team, "frostivus_boss_meteorain", "boss_nevermore_meteorain", delay)
--		elseif cast_bar == 2 then
--			BossPhaseAbilityCastAlt(self.team, "frostivus_boss_meteorain", "boss_nevermore_meteorain", delay)
--		end

		-- Play warning sound
		boss:EmitSound("Hero_Invoker.ChaosMeteor.Cast")

		-- Animate boss cast
		Timers:CreateTimer(delay - 0.9, function()
			boss:FaceTowards(altar_loc)
			StartAnimation(boss, {duration = 2.3, activity=ACT_DOTA_IDLE_RARE, rate=1.0})

			-- Taunt during the rain
			Timers:CreateTimer(delay + 2.0, function()
				StartAnimation(boss, {duration = 1.0, activity=ACT_DOTA_TAUNT, rate=1.0})
				Timers:CreateTimer(delay + 2.0, function()
					StartAnimation(boss, {duration = 1.0, activity=ACT_DOTA_TAUNT, rate=1.0})
				end)
			end)
		end)

		-- Wait [delay] seconds
		Timers:CreateTimer(delay, function()
			local elapsed_duration = 0
			local remaining_spawns = spawn_amount
			Timers:CreateTimer(0, function()
				-- Spawn meteors
				local nearby_enemies = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, altar_loc, nil, 900, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
				for _,enemy in pairs(nearby_enemies) do
					self:Meteor(altar_loc, enemy:GetAbsOrigin(), radius, impact_damage)
					remaining_spawns = remaining_spawns - 1
					if remaining_spawns <= 0 then
						break
					end
				end

				-- Check if the duration has ended
				elapsed_duration = elapsed_duration + spawn_delay
				if elapsed_duration <= duration then
					return spawn_delay
				end
			end)
		end)
	end
end

-- Line Raze (Sav Omoz)
function boss_thinker_nevermore:LineRaze(altar_loc)
	if IsServer() then
		local boss = self:GetParent()
		local ability = boss:FindAbilityByName("frostivus_boss_shadowraze")
		local raze_damage = ability:GetSpecialValueFor("damage")
		local radius = ability:GetSpecialValueFor("radius")
		local delay = ability:GetSpecialValueFor("delay")
		local spawn_distance = ability:GetSpecialValueFor("spawn_distance")

		-- Look for a valid target
		local target = false
		local nearby_enemies = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, altar_loc, nil, 900, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		for _,enemy in pairs(nearby_enemies) do
			target = enemy
			break
		end

		-- If there's no valid target, do nothing
		if not target then
			return nil
		end

		-- Send cast bar event
--		if cast_bar == 1 then
--			BossPhaseAbilityCast(self.team, "frostivus_boss_shadowraze", "boss_nevermore_shadowraze_line", delay)
--		elseif cast_bar == 2 then
--			BossPhaseAbilityCastAlt(self.team, "frostivus_boss_shadowraze", "boss_nevermore_shadowraze_line", delay)
--		end

		-- Face direction
		Timers:CreateTimer(delay - 1.5, function()
			boss:FaceTowards(target:GetAbsOrigin())

			-- Calculate raze points
			local raze_points = {}
			local boss_loc = boss:GetAbsOrigin()
			local direction = (target:GetAbsOrigin() - boss_loc):Normalized()
			for i = 1, 7 do
				raze_points[i] = boss_loc + direction * (radius * 0.5 + spawn_distance * (i - 1))
			end

			-- Raze
			for _, raze_point in pairs(raze_points) do
				self:Raze(raze_point, false)
			end
		end)

		-- Animate boss cast
		Timers:CreateTimer(delay - 0.55, function()
			StartAnimation(boss, {duration = 0.55, activity=ACT_DOTA_RAZE_3, rate=1.0})
		end)

		-- Play raze sound
		Timers:CreateTimer(delay, function()
			boss:EmitSound("Hero_Nevermore.Shadowraze")
		end)
	end
end

-- Circle Raze (Sah/Voo Omoz)
function boss_thinker_nevermore:CircleRaze(altar_loc)
	if IsServer() then
		local boss = self:GetParent()
		local ability = self:GetParent():FindAbilityByName("frostivus_boss_shadowraze")
		local raze_damage = ability:GetSpecialValueFor("damage")
		local radius = ability:GetSpecialValueFor("radius")
		local delay = ability:GetSpecialValueFor("delay")
		local distance = ability:GetSpecialValueFor("spawn_distance")

		-- Send cast bar event
--		if cast_bar == 1 then
--			if distance <= 450 then
--				BossPhaseAbilityCast(self.team, "frostivus_boss_shadowraze", "boss_nevermore_shadowraze_circle_near", delay)
--			else
--				BossPhaseAbilityCast(self.team, "frostivus_boss_shadowraze", "boss_nevermore_shadowraze_circle_far", delay)
--			end
--		elseif cast_bar == 2 then
--			if distance <= 450 then
--				BossPhaseAbilityCastAlt(self.team, "frostivus_boss_shadowraze", "boss_nevermore_shadowraze_circle_near", delay)
--			else
--				BossPhaseAbilityCastAlt(self.team, "frostivus_boss_shadowraze", "boss_nevermore_shadowraze_circle_far", delay)
--			end
--		end

		-- Raze
		Timers:CreateTimer(delay - 1.5, function()
			boss:FaceTowards(boss:GetAbsOrigin() + Vector(0, -100, 0))

			-- Calculate raze points
			local raze_points = {}
			if distance <= 450 then
				for i = 1, 6 do
					raze_points[i] = RotatePosition(altar_loc, QAngle(0, 60 * (i - 1), 0), altar_loc + Vector(0, 1, 0) * distance)
				end
			else
				for i = 1, 12 do
					raze_points[i] = RotatePosition(altar_loc, QAngle(0, 30 * (i - 1), 0), altar_loc + Vector(0, 1, 0) * distance)
				end
			end

			-- Raze
			for _, raze_point in pairs(raze_points) do
				self:Raze(raze_point, false)
			end
		end)

		-- Animate boss cast
		Timers:CreateTimer(delay - 0.55, function()
			if distance <= 450 then
				StartAnimation(boss, {duration = 0.55, activity=ACT_DOTA_RAZE_1, rate=1.0})
			else
				StartAnimation(boss, {duration = 0.55, activity=ACT_DOTA_RAZE_2, rate=1.0})
			end
		end)

		-- Play raze sound
		Timers:CreateTimer(delay, function()
			boss:EmitSound("Hero_Nevermore.Shadowraze")
		end)
	end
end
--[[
-- Moving Raze (Ala/Ula Omoz)
function boss_thinker_nevermore:MovingRaze(altar_loc, direction, start_position)
	if IsServer() then
		local boss = self:GetParent()
		local ability = self:GetParent():FindAbilityByName("frostivus_boss_shadowraze")
		local raze_damage = ability:GetSpecialValueFor("damage")
		local radius = ability:GetSpecialValueFor("radius")
		local delay = ability:GetSpecialValueFor("delay")
		local distance = ability:GetSpecialValueFor("spawn_distance")
		local spawn_delay = ability:GetSpecialValueFor("spawn_delay")
		print("MovingRaze damage:", damage)

		-- Send cast bar event
--		if cast_bar == 1 then
--			if direction == 1 then
--				BossPhaseAbilityCast(self.team, "frostivus_boss_shadowraze", "boss_nevermore_shadowraze_moving_clock", delay)
--			else
--				BossPhaseAbilityCast(self.team, "frostivus_boss_shadowraze", "boss_nevermore_shadowraze_moving_counterclock", delay)
--			end
--		elseif cast_bar == 2 then
--			if direction == 1 then
--				BossPhaseAbilityCastAlt(self.team, "frostivus_boss_shadowraze", "boss_nevermore_shadowraze_moving_clock", delay)
--			else
--				BossPhaseAbilityCastAlt(self.team, "frostivus_boss_shadowraze", "boss_nevermore_shadowraze_moving_counterclock", delay)
--			end
--		end

		-- Raze
		Timers:CreateTimer(delay - 1.5, function()
			boss:FaceTowards(start_position)

			-- Calculate raze points
			local raze_points = {}
			if direction == 1 then
				for i = 1, 12 do
					raze_points[i] = RotatePosition(altar_loc, QAngle(0, -30 * (i - 1), 0), start_position)
				end
			else
				for i = 1, 12 do
					raze_points[i] = RotatePosition(altar_loc, QAngle(0, 30 * (i - 1), 0), start_position)
				end
			end

			-- Raze
			local raze_count = 1
			Timers:CreateTimer(0, function()
				self:Raze(raze_points[raze_count], true)
				raze_count = raze_count + 1
				if raze_count <= 12 then
					return spawn_delay
				end
			end)
		end)

		-- Animate boss cast
		Timers:CreateTimer(delay - 1.0, function()
			StartAnimation(boss, {duration = 1.0 + 11 * spawn_delay, activity=ACT_DOTA_GENERIC_CHANNEL_1, rate=1.0})
		end)
	end
end
--]]
-- Nevermore
function boss_thinker_nevermore:Nevermore(altar_loc)
	if IsServer() then
		local boss = self:GetParent()
		local ability = self:GetParent():FindAbilityByName("frostivus_boss_shadowraze")
		local delay = ability:GetSpecialValueFor("delay")
		local duration = ability:GetSpecialValueFor("duration")

		-- Send cast bar event
--		if cast_bar == 1 then
--			BossPhaseAbilityCast(self.team, "frostivus_boss_nevermore", "boss_nevermore_nevermore", delay)
--		elseif cast_bar == 2 then
--			BossPhaseAbilityCastAlt(self.team, "frostivus_boss_nevermore", "boss_nevermore_nevermore", delay)
--		end

		-- Play warning sound
		boss:EmitSound("Hero_Nevermore.RequiemOfSoulsCast")

		-- Animate boss cast
		boss:FaceTowards(altar_loc)
		StartAnimation(boss, {duration = delay + 1.0, activity=ACT_DOTA_VERSUS, rate=2.0})

		-- Wait [delay] seconds
		Timers:CreateTimer(delay, function()
			-- Lights out!!
			for player_id = 0, 20 do
				if PlayerResource:GetPlayer(player_id) and PlayerResource:GetTeam(player_id) == self.team then
					local win_pfx = ParticleManager:CreateParticleForPlayer("particles/boss_nevermore/screen_requiem_indicator.vpcf", PATTACH_EYES_FOLLOW, PlayerResource:GetSelectedHeroEntity(player_id), PlayerResource:GetPlayer(player_id))
					self:AddParticle(win_pfx, false, false, -1, false, false)
					Timers:CreateTimer(duration, function()
						ParticleManager:DestroyParticle(win_pfx, true)
						ParticleManager:ReleaseParticleIndex(win_pfx)
					end)
				end
			end
		end)
	end
end

-- Requiem of Souls
function boss_thinker_nevermore:RequiemOfSouls(altar_loc)
	if IsServer() then
		local boss = self:GetParent()
		local ability = self:GetParent():FindAbilityByName("frostivus_boss_requiem_of_souls")
		local delay = ability:GetSpecialValueFor("delay")
		local line_amount = ability:GetSpecialValueFor("line_amount")
		local line_damage = ability:GetSpecialValueFor("damage")
		print("Ros damage:", line_damage)

		-- Send cast bar event
--		if cast_bar == 1 then
--			BossPhaseAbilityCast(self.team, "frostivus_boss_requiem_of_souls", "boss_nevermore_requiem_of_souls", delay)
--		elseif cast_bar == 2 then
--			BossPhaseAbilityCastAlt(self.team, "frostivus_boss_requiem_of_souls", "boss_nevermore_requiem_of_souls", delay)
--		end

		-- Animate boss cast
		Timers:CreateTimer(delay - 1.65, function()
			boss:FaceTowards(boss:GetAbsOrigin() + Vector(0, -100, 0))
			boss:EmitSound("Hero_Nevermore.ROS.Arcana.Cast")
			StartAnimation(boss, {duration = 2.0, activity=ACT_DOTA_RAZE_3, rate=0.35})
		end)

		-- Wait [delay] seconds
		Timers:CreateTimer(delay, function()
			-- Successful cast sound
			boss:EmitSound("Hero_Nevermore.ROS.Arcana")

			-- Add souls from Necromastery
			local line_count = line_amount + math.floor(boss:FindModifierByName("modifier_frostivus_necromastery"):GetStackCount() * 0.5)
			boss:FindModifierByName("modifier_frostivus_necromastery"):SetStackCount(0)

			-- Calculate projectile speed
			local projectile_speeds = {}
			local boss_loc = boss:GetAbsOrigin()
			local north = boss_loc + Vector(0, 700, 0)
			for i = 1, line_count do
				projectile_speeds[i] = (RotatePosition(boss_loc, QAngle(0, (i - 1) * 360 / line_count, 0), north) - boss_loc):Normalized() * 700
			end

			-- Base projectile
			local soul_projectile =	{
				Ability				= boss:FindAbilityByName("frostivus_boss_requiem_of_souls"),
				EffectName			= "particles/units/heroes/hero_nevermore/nevermore_requiemofsouls_line.vpcf",
				vSpawnOrigin		= boss_loc,
				fDistance			= distance,
				fStartRadius		= 125,
				fEndRadius			= 300,
				Source				= boss,
				bHasFrontalCone		= false,
				bReplaceExisting	= false,
				iUnitTargetTeam		= DOTA_UNIT_TARGET_TEAM_ENEMY,
				iUnitTargetFlags	= DOTA_UNIT_TARGET_FLAG_NONE,
				iUnitTargetType		= DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
				fExpireTime 		= GameRules:GetGameTime() + 10.0,
				bDeleteOnHit		= false,
				vVelocity			= Vector(projectile_speeds[1].x, projectile_speeds[1].y, 0),
				bProvidesVision		= false,
				ExtraData			= {damage = line_damage}
			}

			-- Spawn projectiles and particles
			for i = 1, line_count do
				soul_projectile.vVelocity = Vector(projectile_speeds[i].x, projectile_speeds[i].y, 0)
				ProjectileManager:CreateLinearProjectile(soul_projectile)

				local line_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_nevermore/nevermore_requiemofsouls_line.vpcf", PATTACH_ABSORIGIN, boss)
				ParticleManager:SetParticleControl(line_pfx, 0, boss_loc)
				ParticleManager:SetParticleControl(line_pfx, 1, projectile_speeds[i])
				ParticleManager:SetParticleControl(line_pfx, 2, Vector(0, 9 / 7, 0))
				ParticleManager:ReleaseParticleIndex(line_pfx)
			end
		end)
	end
end
