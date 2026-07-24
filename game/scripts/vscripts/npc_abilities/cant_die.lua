LinkLuaModifier("modifier_cant_die_generic", "npc_abilities/cant_die.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dying_generic", "npc_abilities/cant_die.lua", LUA_MODIFIER_MOTION_NONE)

local XHS_DEFERRED_PHASE3_BOSS_BARS = {
	["npc_dota_hero_grom_hellscream"] = true,
	["npc_dota_hero_illidan"] = true,
	["npc_dota_hero_balanar"] = true,
	["npc_dota_hero_proudmoore"] = true,
	["npc_dota_boss_spirit_master"] = true,
}

local function IsDeferredPhase3BossBar(boss)
	return boss ~= nil
		and IsValidEntity(boss)
		and not boss:IsNull()
		and XHS_DEFERRED_PHASE3_BOSS_BARS[boss:GetUnitName()] == true
end

local function GetBossFromDataDrivenKeys(keys)
	if keys == nil then return nil end

	local boss = keys.caster or keys.unit or keys.target
	if boss ~= nil and IsValidEntity(boss) and not boss:IsNull() then
		return boss
	end

	return nil
end

function OnCreated(keys)
	local boss = GetBossFromDataDrivenKeys(keys)
	if boss ~= nil and ((IsPrivateBossBarBoss and IsPrivateBossBarBoss(boss)) or IsDeferredPhase3BossBar(boss)) then
		return
	end

	if boss ~= nil and ShowBossBar then
		ShowBossBar(boss)
	end
end

function BossTakeDamage(keys)
	local boss = GetBossFromDataDrivenKeys(keys)
	if boss ~= nil and UpdateBossBar then
		if XHSSpiritMaster_ConfigureSpiritBossBar ~= nil
			and string.find(boss:GetUnitName(), "npc_dota_boss_spirit_master_") then
			XHSSpiritMaster_ConfigureSpiritBossBar(boss)
		end
		UpdateBossBar(boss, keys and keys.attacker)
	end
end

cant_die_generic = cant_die_generic or class({})

function cant_die_generic:GetIntrinsicModifierName()
	return "modifier_cant_die_generic"
end

modifier_cant_die_generic = modifier_cant_die_generic or class({})
modifier_cant_die_generic.XHS_LINK_CLIENT = true

local function CleanupBanehallowRevenants()
	local units = FindUnitsInRadius(
		DOTA_TEAM_CUSTOM_2,
		Vector(0, 0, 0),
		nil,
		FIND_UNITS_EVERYWHERE,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_ALL,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
		FIND_ANY_ORDER,
		false
	)

	for _, unit in pairs(units) do
		if unit ~= nil
			and IsValidEntity(unit)
			and not unit:IsNull()
			and unit:GetUnitName() == "npc_death_revenant_banehallow" then
			UTIL_Remove(unit)
		end
	end
end

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

	local is_private_boss_bar_boss = IsPrivateBossBarBoss and IsPrivateBossBarBoss(self.parent)

	if not is_private_boss_bar_boss
		and not IsDeferredPhase3BossBar(self.parent)
		and self.parent:GetUnitName() ~= "npc_dota_boss_spirit_master_storm"
		and self.parent:GetUnitName() ~= "npc_dota_boss_spirit_master_earth"
		and self.parent:GetUnitName() ~= "npc_dota_boss_spirit_master_fire" then
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
		if XHSSpiritMaster_ConfigureSpiritBossBar ~= nil
			and string.find(parent:GetUnitName(), "npc_dota_boss_spirit_master_") then
			XHSSpiritMaster_ConfigureSpiritBossBar(parent)
		end
		UpdateBossBar(parent, attacker)

		if parent:GetHealth() <= 100 and not parent:IsIllusion() and parent.deathStart ~= true then
			if XHSSpiritMasterEncounter ~= nil
				and XHSSpiritMasterEncounter.GetNextThreshold ~= nil
				and parent:GetUnitName() == "npc_dota_boss_spirit_master"
				and XHSSpiritMasterEncounter.phase ~= nil then
				if XHSSpiritMasterEncounter.phase ~= "master" then
					-- The real Spirit Master is only an encounter anchor during a
					-- split/finale. It must never enter the generic boss death path.
					parent:SetHealth(math.max(1, parent:GetHealth()))
					return
				else
					local threshold = XHSSpiritMasterEncounter:GetNextThreshold(parent)
					if threshold ~= nil and XHSSpiritMasterEncounter:TriggerSplit(parent, threshold) == true then
						return
					end
				end
			end

			if XHSSpiritMasterEncounter ~= nil
				and XHSSpiritMasterEncounter.HandleSpiritLethal ~= nil
				and string.find(parent:GetUnitName(), "npc_dota_boss_spirit_master_")
				and XHSSpiritMasterEncounter:HandleSpiritLethal(parent, attacker) == true then
				return
			end

			self.disable_on_takedamage = true

			parent:SetBaseHealthRegen(0.0)
			parent:AddNewModifier(parent, nil, "modifier_dying_generic", { duration = 15.0 })
			if HideBossBar then
				HideBossBar(parent)
			end
			if parent:GetUnitName() == "npc_dota_hero_banehallow" then
				CustomGameEventManager:Send_ServerToAllClients("xhs_boss_counter_hide", {
					boss_count = parent.boss_count,
					boss_bar_id = GetBossBarId and GetBossBarId(parent) or nil,
				})
				CleanupBanehallowRevenants()
				GameMode.BanehallowRevenantsRemaining = nil
				GameMode.BanehallowRevenantsTotal = nil
			end

			parent.deathStart = true
			local bDevSandbox = XHSDevTools ~= nil and XHSDevTools:IsSandboxActive()

			-- specific interaction for first 4 bosses
			if bDevSandbox ~= true and XHS_BOSSES_TABLE[parent:GetUnitName()] and XHS_BOSSES_TABLE[parent:GetUnitName()].four_bosses_kill_count then
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

					if bDevSandbox == true then
						Notifications:TopToAll({ text = "Dev sandbox: Spirit Master cleared. EndGame blocked.", duration = 6.0 })
						if XHSDevTools ~= nil then
							XHSDevTools:PushState()
						end
					else
						EndGame()
					end
				else -- normal spirit master boss death
					Timers:CreateTimer(1.0, function()
						EmitGlobalSound("Loot_Drop_Stinger_Mythical")
					end)

					return
				end
			else -- normal boss death
				if bDevSandbox ~= true then
					GiveTomeToAllHeroes(250)
				end
				EmitGlobalSound("Loot_Drop_Stinger_Arcana")
			end

			local bossConfig = XHS_BOSSES_TABLE[parent:GetUnitName()]
			local function FinishBossDoorTransition()
				StartAnimation(parent, XHS_BOSSES_TABLE[parent:GetUnitName()].death_animation)
				EmitSoundOn("skeleton_king_wraith_death_long_09", parent)
			end

			-- Start moving the camera before the six-second death beat, then open
			-- the next arena exactly when the camera reaches its doors.
			if bDevSandbox ~= true and bossConfig.doors_to_open ~= nil and XHSOpenDoorsWithCinematic ~= nil then
				Timers:CreateTimer(4.65, function()
					XHSOpenDoorsWithCinematic(
						bossConfig.doors_to_open,
						bossConfig.obstructions_to_disable,
						"gate_02_open",
						FinishBossDoorTransition,
						{
							move_duration = 1.35,
							hold_duration = 1.25,
							return_duration = 1.0,
						}
					)
				end)
			else
				Timers:CreateTimer(6.0, FinishBossDoorTransition)
			end

			-- next boss
			local delay = XHS_BOSSES_TABLE[parent:GetUnitName()].func_next_delay or 0.0
			local func = XHS_BOSSES_TABLE[parent:GetUnitName()].func_next

			if bDevSandbox ~= true and delay and func then
				Timers:CreateTimer(delay, function()
					func()
				end)
			elseif bDevSandbox == true and XHSDevTools ~= nil then
				Timers:CreateTimer(delay or 0.0, function()
					XHSDevTools:PushState()
				end)
			end
		end
	end
end

modifier_dying_generic = modifier_dying_generic or class({})
modifier_dying_generic.XHS_LINK_CLIENT = true

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
