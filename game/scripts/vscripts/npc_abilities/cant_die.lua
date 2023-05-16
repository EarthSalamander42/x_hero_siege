LinkLuaModifier("modifier_cant_die_generic", "npc_abilities/cant_die.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dying_generic", "npc_abilities/cant_die.lua", LUA_MODIFIER_MOTION_NONE)

cant_die_generic = cant_die_generic or class({})

function cant_die_generic:GetIntrinsicModifierName()
	return "modifier_cant_die_generic"
end

modifier_cant_die_generic = modifier_cant_die_generic or class({})

function modifier_cant_die_generic:IsHidden() return true end

function modifier_cant_die_generic:IsPurgable() return false end

function modifier_cant_die_generic:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_MIN_HEALTH,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
end

function modifier_cant_die_generic:OnCreated()
	if not IsServer() then return end

	self.parent = self:GetParent()
	self.disable_on_takedamage = false

	local blacklist = {
		["npc_dota_hero_grom_hellscream"] = true,
		["npc_dota_hero_illidan"] = true,
		["npc_dota_hero_balanar"] = true,
		["npc_dota_hero_proudmoore"] = true,
		["npc_dota_boss_spirit_master_storm"] = true,
		["npc_dota_boss_spirit_master_earth"] = true,
		["npc_dota_boss_spirit_master_fire"] = true,
	}

	if not blacklist[self.parent:GetUnitName()] then
		if ShowBossBar then
			ShowBossBar(self.parent)
		end
	end
end

function modifier_cant_die_generic:GetMinHealth()
	if self:GetStackCount() == 1 then
		return 0
	end

	return 1
end

function modifier_cant_die_generic:OnTakeDamage(event)
	if self.disable_on_takedamage then return end
	local parent = event.unit
	local attacker = event.attacker

	if parent == self.parent then
		UpdateBossBar(parent, attacker)

		if parent:GetHealth() <= 100 and not parent:IsIllusion() and parent.deathStart ~= true then
			self.disable_on_takedamage = true

			parent:SetBaseHealthRegen(0.0)
			parent:AddNewModifier(parent, nil, "modifier_dying_generic", { duration = 15.0 })
			CustomGameEventManager:Send_ServerToAllClients("hide_boss_hp", { boss_count = parent.boss_count })

			parent.deathStart = true

			-- specific interaction for first 4 bosses
			if XHS_BOSSES_TABLE[parent:GetUnitName()] and XHS_BOSSES_TABLE[parent:GetUnitName()].four_bosses_kill_count then
				FourBossesKillCount()
			end

			-- play death sound
			if XHS_BOSSES_TABLE[parent:GetUnitName()] and XHS_BOSSES_TABLE[parent:GetUnitName()].custom_death_sound then
				EmitGlobalSound(XHS_BOSSES_TABLE[parent:GetUnitName()].custom_death_sound)
			else
				EmitSoundOn("skeleton_king_wraith_death_long_01", parent)
			end

			-- play death animation
			StartAnimation(parent, { duration = 6.0, activity = ACT_DOTA_FLAIL, rate = 0.75 })

			-- no draw and kill boss after delay
			Timers:CreateTimer(XHS_BOSSES_TABLE[parent:GetUnitName()].death_no_draw_delay, function()
				parent:AddNoDraw()
				self:SetStackCount(1)
				parent:Kill(attacker, nil)
				CustomGameEventManager:Send_ServerToAllClients("hide_ui", {})

				if XHS_BOSSES_TABLE[parent:GetUnitName()].refresh_players then
					RefreshPlayers()
				end
			end)

			-- play spirit master death sound and give stats
			if string.find(parent:GetUnitName(), "npc_dota_boss_spirit_master_") then
				SPIRIT_MASTER_KILLED_BOSS_COUNT = SPIRIT_MASTER_KILLED_BOSS_COUNT + 1

				-- last spirit master boss death
				if SPIRIT_MASTER_KILLED_BOSS_COUNT == 3 then
					Timers:CreateTimer(1.0, function()
						EmitGlobalSound("Loot_Drop_Stinger_Arcana")
					end)

					EndGame()
				else -- normal spirit master boss death
					Timers:CreateTimer(1.0, function()
						EmitGlobalSound("Loot_Drop_Stinger_Mythical")
					end)

					return
				end
			else -- normal boss death
				GiveTomeToAllHeroes(250)
				EmitGlobalSound("Loot_Drop_Stinger_Arcana")
			end

			-- open doors if any
			Timers:CreateTimer(6.0, function()
				if XHS_BOSSES_TABLE[parent:GetUnitName()] and XHS_BOSSES_TABLE[parent:GetUnitName()].doors_to_open then
					for _, door_name in pairs(XHS_BOSSES_TABLE[parent:GetUnitName()].doors_to_open) do
						DoEntFire(door_name, "SetAnimation", "gate_02_open", 0, nil, nil)
					end
				end

				if XHS_BOSSES_TABLE[parent:GetUnitName()] and XHS_BOSSES_TABLE[parent:GetUnitName()].obstructions_to_disable then
					for _, obs_name in pairs(XHS_BOSSES_TABLE[parent:GetUnitName()].obstructions_to_disable) do
						for _, obs in pairs(Entities:FindAllByName(obs_name)) do
							obs:SetEnabled(false, true)
						end
					end
				end

				StartAnimation(parent, XHS_BOSSES_TABLE[parent:GetUnitName()].death_animation)
				EmitSoundOn("skeleton_king_wraith_death_long_09", parent)
			end)

			-- next boss
			local delay = XHS_BOSSES_TABLE[parent:GetUnitName()].func_next_delay or 0.0
			local func = XHS_BOSSES_TABLE[parent:GetUnitName()].func_next

			if delay and func then
				Timers:CreateTimer(delay, function()
					func()
				end)
			end
		end
	end
end

modifier_dying_generic = modifier_dying_generic or class({})

function modifier_dying_generic:IsHidden() return true end

function modifier_dying_generic:IsPurgable() return false end

function modifier_dying_generic:CheckState()
	return {
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_ROOTED] = true,
		[MODIFIER_STATE_SILENCED] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_UNSELECTABLE] = true,
	}
end

function modifier_dying_generic:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_DISABLE_HEALING,
	}
end

function modifier_dying_generic:OnCreated()
	if not IsServer() then return end

	self.parent = self:GetParent()

	self:StartIntervalThink(0.5)
end

function modifier_dying_generic:OnIntervalThink()
	if not IsServer() then return end

	local particleVector = self.parent:GetAbsOrigin()
	local particleName = EXPLOSION_PARTICLE_TABLE[RandomInt(1, 1)]

	local pfx = ParticleManager:CreateParticle(particleName, PATTACH_ABSORIGIN_FOLLOW, self.parent)
	ParticleManager:SetParticleControlEnt(pfx, 0, self.parent, PATTACH_POINT_FOLLOW, "attach_hitloc", particleVector, true)

	local sound = EXPLOSION_SOUND_TABLE[RandomInt(1, 2)]
	EmitSoundOn(sound, self.parent)
end

function modifier_dying_generic:GetDisableHealing()
	return 1
end
