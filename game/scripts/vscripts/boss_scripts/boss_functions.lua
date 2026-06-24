-- Boss-fighting related functions


---------------------
-- Other modifiers
---------------------
LinkLuaModifier("boss_thinker_nevermore", "boss_scripts/boss_thinker_nevermore.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_xhs_banehallow_phase3_ai", "boss_scripts/phase3_ai/banehallow.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_xhs_magtheridon_phase3_ai", "boss_scripts/phase3_ai/magtheridon.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_xhs_magtheridon_fragment", "boss_scripts/phase3_ai/magtheridon.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_xhs_magtheridon_empower", "boss_scripts/phase3_ai/magtheridon.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_xhs_magtheridon_twin_lockout", "boss_scripts/phase3_ai/magtheridon.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_xhs_magtheridon_slow", "boss_scripts/phase3_ai/magtheridon.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_xhs_magtheridon_cast_lock", "boss_scripts/phase3_ai/magtheridon.lua", LUA_MODIFIER_MOTION_NONE )

---------------------
-- Other stuff
---------------------

function BossPhaseAbilityCast(team, ability_image, ability_name, delay)
	local ability_cast_timer = 0.0
	Timers:CreateTimer(function()
		CustomGameEventManager:Send_ServerToTeam(team, "BossStartedCast", {ability_image = ability_image, ability_name = ability_name, current_cast_time = ability_cast_timer, cast_time = delay})
		if ability_cast_timer < delay then
			ability_cast_timer = ability_cast_timer + FrameTime()
			return FrameTime()
		elseif ability_cast_timer >= delay then
			ability_cast_timer = 0.0
			CustomGameEventManager:Send_ServerToTeam(team, "BossStartedCast", {ability_image = ability_image, ability_name = ability_name, current_cast_time = ability_cast_timer, cast_time = delay})
		end
	end)
end

---------------------
-- Phase transitions
---------------------

function BossPhaseAbilityCastAlt(team, ability_image, ability_name, delay)
	local ability_cast_timer = 0.0
	Timers:CreateTimer(function()
		CustomGameEventManager:Send_ServerToTeam(team, "BossStartedCastAlt", {ability_image = ability_image, ability_name = ability_name, current_cast_time = ability_cast_timer, cast_time = delay})
		if ability_cast_timer < delay then
			ability_cast_timer = ability_cast_timer + FrameTime()
			return FrameTime()
		elseif ability_cast_timer >= delay then
			ability_cast_timer = 0.0
			CustomGameEventManager:Send_ServerToTeam(team, "BossStartedCastAlt", {ability_image = ability_image, ability_name = ability_name, current_cast_time = ability_cast_timer, cast_time = delay})
		end
	end)
end
