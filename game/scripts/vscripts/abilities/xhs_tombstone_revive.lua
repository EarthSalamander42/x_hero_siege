local XHSUnitTombstone = {}

local BASE_CHANNEL_TIME = 5.0
local MIN_CHANNEL_TIME = 0.1
local INTERACTION_RANGE = 190
local INTERACTION_TIMEOUT = 12.0
local REVIVE_PARTICLE = "particles/items_fx/aegis_respawn.vpcf"
local CHANNEL_PARTICLE = "particles/items_fx/aegis_respawn_timer.vpcf"
local SPAWN_PARTICLE = "particles/units/heroes/hero_undying/undying_tombstone.vpcf"
local AMBIENT_PARTICLE = "particles/econ/items/undying/fall20_undying_head/fall20_undying_tombstone_ambient.vpcf"
local COMPLETE_SOUND = "Hero_Omniknight.GuardianAngel.Cast"

local SupporterRecoveryEffects = require("components/battlepass/recovery_effects"):Init()

local function IsValid(entity)
	return entity ~= nil and IsValidEntity(entity) and not entity:IsNull()
end

local function GetHeroFromTombstone(tombstone)
	if not IsValid(tombstone) then return nil end
	local entindex = tonumber(tombstone.xhs_revive_hero_entindex)
	local hero = entindex ~= nil and entindex > 0 and EntIndexToHScript(entindex) or nil
	return IsValid(hero) and hero:IsRealHero() and hero or nil
end

local function GetState(hero, create)
	if not IsValid(hero) then return nil end
	if hero.xhs_tombstone_state == nil and create then
		hero.xhs_tombstone_state = {
			channels = {},
			end_time = nil,
			completed = false,
		}
	end
	return hero.xhs_tombstone_state
end

local function SetNetState(hero, active, duration, endTime, channelCount, tombstone)
	if not IsValid(hero) then return end
	CustomNetTables:SetTableValue("player_table", tostring(hero:entindex()) .. "_revive_channel", {
		active = active == true and 1 or 0,
		duration = tonumber(duration) or 0,
		end_time = tonumber(endTime) or 0,
		channels = tonumber(channelCount) or 0,
		tombstone_entindex = IsValid(tombstone) and tombstone:entindex() or -1,
	})
end

local function SendLocalChannelState(caster, active)
	if not IsValid(caster) then return end
	local playerId = caster:GetPlayerOwnerID()
	local player = playerId ~= nil and playerId >= 0 and PlayerResource:GetPlayer(playerId) or nil
	if player == nil then return end
	CustomGameEventManager:Send_ServerToPlayer(player, "xhs_tombstone_channel_local", {
		active = active == true and 1 or 0,
	})
end

local function BroadcastReviveState(hero, active, duration, endTime, channelCount, result)
	if not IsValid(hero) then return end
	CustomGameEventManager:Send_ServerToAllClients("xhs_tombstone_revive_update", {
		hero_entindex = hero:entindex(),
		player_id = hero:GetPlayerOwnerID(),
		hero_name = hero:GetUnitName(),
		active = active == true and 1 or 0,
		duration = tonumber(duration) or 0,
		end_time = tonumber(endTime) or 0,
		channels = tonumber(channelCount) or 0,
		result = result or "",
	})
end

local function DestroyChannelParticle(ability, interrupted)
	if ability == nil or ability.xhs_channel_particle == nil then return end
	ParticleManager:DestroyParticle(ability.xhs_channel_particle, interrupted == true)
	ParticleManager:ReleaseParticleIndex(ability.xhs_channel_particle)
	ability.xhs_channel_particle = nil
end

local function ScheduleAbilityRemoval(caster, ability)
	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("xhs_revive_ability_cleanup"), function()
		if not IsValid(caster) or ability == nil then return nil end
		local current = caster:FindAbilityByName("xhs_tombstone_revive_channel")
		if current == ability and not current:IsChanneling() then
			caster:RemoveAbility("xhs_tombstone_revive_channel")
		end
		return nil
	end, 0)
end

local function PruneChannels(hero, state)
	if state == nil then return 0, nil end
	local count = 0
	local earliestEnd = nil
	for casterIndex, channel in pairs(state.channels or {}) do
		local caster = channel.caster
		local ability = channel.ability
		if IsValid(caster) and caster:IsAlive() and ability ~= nil and ability:IsChanneling() then
			count = count + 1
			local channelEnd = tonumber(channel.end_time) or 0
			earliestEnd = earliestEnd == nil and channelEnd or math.min(earliestEnd, channelEnd)
		else
			state.channels[casterIndex] = nil
		end
	end
	state.end_time = earliestEnd
	return count, earliestEnd
end

local function PublishState(hero, state)
	if not IsValid(hero) or hero:IsAlive() or state == nil then
		if IsValid(hero) then
			SetNetState(hero, false, 0, 0, 0, hero.xhs_tombstone_unit)
			BroadcastReviveState(hero, false, 0, 0, 0)
		end
		return 0
	end

	local count, endTime = PruneChannels(hero, state)
	local remaining = endTime ~= nil and math.max(0, endTime - GameRules:GetGameTime()) or 0
	if count <= 0 or remaining <= 0 then
		SetNetState(hero, false, 0, 0, 0, hero.xhs_tombstone_unit)
		BroadcastReviveState(hero, false, 0, 0, 0)
		return 0
	end

	SetNetState(hero, true, remaining, endTime, count, hero.xhs_tombstone_unit)
	BroadcastReviveState(hero, true, remaining, endTime, count)
	for _, channel in pairs(state.channels) do
		SendLocalChannelState(channel.caster, true)
	end
	return count
end

local function RemoveTombstone(hero)
	if not IsValid(hero) then return end
	local tombstone = hero.xhs_tombstone_unit
	hero.xhs_tombstone_unit = nil
	if IsValid(tombstone) then
		if tombstone.xhs_tombstone_ambient_particle ~= nil then
			ParticleManager:DestroyParticle(tombstone.xhs_tombstone_ambient_particle, false)
			ParticleManager:ReleaseParticleIndex(tombstone.xhs_tombstone_ambient_particle)
			tombstone.xhs_tombstone_ambient_particle = nil
		end
		UTIL_Remove(tombstone)
	end
end

local function CancelAllChannels(hero, completed)
	local state = GetState(hero, false)
	if state == nil then return end
	state.completed = completed == true
	for _, channel in pairs(state.channels or {}) do
		local caster = channel.caster
		local ability = channel.ability
		SendLocalChannelState(caster, false)
		if ability ~= nil then
			ability.xhs_finish_handled = true
			DestroyChannelParticle(ability, not completed)
		end
		if IsValid(caster) and caster:IsChanneling() then
			caster:InterruptChannel()
		end
		ScheduleAbilityRemoval(caster, ability)
	end
	state.channels = {}
	state.end_time = nil
	SetNetState(hero, false, 0, 0, 0, hero.xhs_tombstone_unit)
	BroadcastReviveState(hero, false, 0, 0, 0, completed and "completed" or "cancelled")
end

local function CompleteRevive(hero, caster, ability)
	if not IsValid(hero) or hero:IsAlive() then return false end
	local tombstone = hero.xhs_tombstone_unit
	local revivePosition = IsValid(tombstone) and tombstone:GetAbsOrigin() or hero:GetAbsOrigin()

	hero:RespawnHero(false, false)
	if not hero:IsAlive() then return false end

	FindClearSpaceForUnit(hero, revivePosition, true)
	hero:SetHealth(hero:GetMaxHealth())
	hero:SetMana(hero:GetMaxMana())
	hero:Stop()
	SupporterRecoveryEffects:PlayRebirth(hero, REVIVE_PARTICLE)
	if IsValid(caster) then caster:EmitSound(COMPLETE_SOUND) end

	local gameMode = GameRules.GameMode
	if gameMode ~= nil and gameMode.OnPlayerRevived ~= nil then
		gameMode:OnPlayerRevived({
			caster = IsValid(caster) and caster:entindex() or -1,
			target = hero:entindex(),
			channel_time = ability ~= nil and ability:GetChannelTime() or BASE_CHANNEL_TIME,
		})
	end

	CancelAllChannels(hero, true)
	RemoveTombstone(hero)
	hero.xhs_tombstone_state = nil
	return true
end

xhs_tombstone_revive_channel = xhs_tombstone_revive_channel or class({})

function xhs_tombstone_revive_channel:GetChannelTime()
	return self.xhs_channel_duration or BASE_CHANNEL_TIME
end

function xhs_tombstone_revive_channel:OnAbilityPhaseStart()
	if not IsServer() then return true end
	local caster = self:GetCaster()
	local tombstone = self.xhs_tombstone
	local hero = GetHeroFromTombstone(tombstone)
	return IsValid(caster)
		and caster:IsAlive()
		and IsValid(hero)
		and not hero:IsAlive()
		and caster:GetTeamNumber() == tombstone:GetTeamNumber()
		and (caster:GetAbsOrigin() - tombstone:GetAbsOrigin()):Length2D() <= INTERACTION_RANGE + 50
end

function xhs_tombstone_revive_channel:OnSpellStart()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local tombstone = self.xhs_tombstone
	local hero = GetHeroFromTombstone(tombstone)
	if not IsValid(hero) then return end

	local now = GameRules:GetGameTime()
	local state = GetState(hero, true)
	self.xhs_channel_end_time = now + self:GetChannelTime()
	state.channels[caster:entindex()] = {
		caster = caster,
		ability = self,
		end_time = self.xhs_channel_end_time,
	}

	self.xhs_channel_particle = ParticleManager:CreateParticle(CHANNEL_PARTICLE, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(self.xhs_channel_particle, 0, tombstone:GetAbsOrigin())
	ParticleManager:SetParticleControl(self.xhs_channel_particle, 1, Vector(self:GetChannelTime(), 0, 0))
	ParticleManager:SetParticleControl(self.xhs_channel_particle, 3, tombstone:GetAbsOrigin())
	PublishState(hero, state)
end

function xhs_tombstone_revive_channel:OnChannelFinish(interrupted)
	if not IsServer() or self.xhs_finish_handled == true then return end
	self.xhs_finish_handled = true
	local caster = self:GetCaster()
	local hero = GetHeroFromTombstone(self.xhs_tombstone)
	DestroyChannelParticle(self, interrupted)

	if not IsValid(hero) then
		SendLocalChannelState(caster, false)
		ScheduleAbilityRemoval(caster, self)
		return
	end

	local state = GetState(hero, false)
	if state ~= nil then state.channels[caster:entindex()] = nil end
	if interrupted then
		SendLocalChannelState(caster, false)
		PublishState(hero, state)
		ScheduleAbilityRemoval(caster, self)
		return
	end

	SendLocalChannelState(caster, false)
	if not CompleteRevive(hero, caster, self) then
		PublishState(hero, state)
	end
	ScheduleAbilityRemoval(caster, self)
end

function XHSUnitTombstone:IsTombstone(unit)
	return IsValid(unit) and unit.xhs_is_hero_tombstone == true
end

function XHSUnitTombstone:BeginInteraction(caster, tombstone)
	if not IsValid(caster) or not caster:IsRealHero() or not caster:IsAlive() then return false end
	if not self:IsTombstone(tombstone) or caster:GetTeamNumber() ~= tombstone:GetTeamNumber() then return false end
	local hero = GetHeroFromTombstone(tombstone)
	if not IsValid(hero) or hero:IsAlive() or caster == hero then return false end

	caster.xhs_pending_tombstone_entindex = tombstone:entindex()
	local deadline = GameRules:GetGameTime() + INTERACTION_TIMEOUT
	caster:MoveToPosition(tombstone:GetAbsOrigin())

	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("xhs_tombstone_interact"), function()
		if not IsValid(caster) or not caster:IsAlive() then return nil end
		if caster.xhs_pending_tombstone_entindex ~= tombstone:entindex() then return nil end
		if not self:IsTombstone(tombstone) or hero:IsAlive() then
			caster.xhs_pending_tombstone_entindex = nil
			return nil
		end
		if GameRules:GetGameTime() >= deadline then
			caster.xhs_pending_tombstone_entindex = nil
			return nil
		end

		if (caster:GetAbsOrigin() - tombstone:GetAbsOrigin()):Length2D() > INTERACTION_RANGE then
			return 0.05
		end

		caster.xhs_pending_tombstone_entindex = nil
		caster:Stop()
		caster:FaceTowards(tombstone:GetAbsOrigin())
		local state = GetState(hero, true)
		local activeCount, earliestEnd = PruneChannels(hero, state)
		if state.channels[caster:entindex()] ~= nil then return nil end

		local duration = BASE_CHANNEL_TIME
		if activeCount > 0 and earliestEnd ~= nil then
			duration = math.max(MIN_CHANNEL_TIME, (earliestEnd - GameRules:GetGameTime()) * 0.5)
		end

		local ability = caster:FindAbilityByName("xhs_tombstone_revive_channel")
		if ability == nil then ability = caster:AddAbility("xhs_tombstone_revive_channel") end
		if ability == nil then return nil end
		ability:SetLevel(1)
		ability:SetActivated(true)
		ability.xhs_tombstone = tombstone
		ability.xhs_channel_duration = duration
		ability.xhs_finish_handled = false

		ExecuteOrderFromTable({
			UnitIndex = caster:entindex(),
			OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
			AbilityIndex = ability:entindex(),
			PlayerID = caster:GetPlayerOwnerID(),
			Queue = false,
		})
		return nil
	end, 0)
	return true
end

function XHSUnitTombstone:RemoveForHero(hero, cleanupChannels)
	if not IsValid(hero) then return end
	if cleanupChannels == true then CancelAllChannels(hero, false) end
	local legacyDrop = hero.xhs_tombstone_drop
	local legacyItem = hero.xhs_tombstone_item
	hero.xhs_tombstone_drop = nil
	hero.xhs_tombstone_item = nil
	if IsValid(legacyDrop) then UTIL_Remove(legacyDrop) end
	if IsValid(legacyItem) then UTIL_Remove(legacyItem) end
	RemoveTombstone(hero)
end

function XHSUnitTombstone:EnsureForHero(hero, position)
	if not IsValid(hero) or hero:IsAlive() then return nil end
	if self:IsTombstone(hero.xhs_tombstone_unit) then return hero.xhs_tombstone_unit end

	RemoveTombstone(hero)
	local spawnPosition = position or hero:GetAbsOrigin()
	local tombstone = CreateUnitByName("npc_xhs_hero_tombstone", spawnPosition, false, hero, hero, hero:GetTeamNumber())
	if not IsValid(tombstone) then return nil end
	tombstone.xhs_is_hero_tombstone = true
	tombstone.xhs_revive_hero_entindex = hero:entindex()
	tombstone:SetAngles(0, RandomFloat(0, 360), 0)
	tombstone:AddNewModifier(tombstone, nil, "modifier_invulnerable", {})
	tombstone:AddNewModifier(tombstone, nil, "modifier_phased", {})
	tombstone:AddNewModifier(tombstone, nil, "modifier_no_healthbar", {})
	FindClearSpaceForUnit(tombstone, spawnPosition, true)

	local spawnParticle = ParticleManager:CreateParticle(SPAWN_PARTICLE, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(spawnParticle, 0, tombstone:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(spawnParticle)
	tombstone.xhs_tombstone_ambient_particle = ParticleManager:CreateParticle(AMBIENT_PARTICLE, PATTACH_ABSORIGIN_FOLLOW, tombstone)
	hero.xhs_tombstone_unit = tombstone
	SetNetState(hero, false, 0, 0, 0, tombstone)
	return tombstone
end

function XHSUnitTombstone:SpawnForHero(hero, position)
	if not IsValid(hero) or hero:IsAlive() then return nil end
	self:RemoveForHero(hero, true)
	hero.xhs_tombstone_state = {
		channels = {},
		end_time = nil,
		completed = false,
	}
	return self:EnsureForHero(hero, position)
end

function XHSUnitTombstone:Install()
	_G.XHSUnitTombstone = self
	_G.XHSBeginTombstoneInteraction = function(caster, tombstone)
		return self:BeginInteraction(caster, tombstone)
	end
	_G.XHSClearTombstoneReviveState = function(hero)
		if IsValid(hero) then SetNetState(hero, false, 0, 0, 0, hero.xhs_tombstone_unit) end
	end
	_G.XHSRemoveTombstoneGroundForHero = function(hero, cleanupChannels)
		self:RemoveForHero(hero, cleanupChannels)
	end
	_G.EnsureXHSTombstoneGroundDrop = function(hero, position)
		local tombstone = self:EnsureForHero(hero, position)
		return tombstone, nil
	end
	_G.SpawnXHSTombstoneForHero = function(hero, position)
		local tombstone = self:SpawnForHero(hero, position)
		return tombstone, nil
	end
	_G.XHSIsTombstonePickupByActiveChanneler = function()
		return false
	end
end

return XHSUnitTombstone
