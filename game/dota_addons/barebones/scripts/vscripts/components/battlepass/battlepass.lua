-- Copyright (C) 2018  The Dota IMBA Development Team
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
-- http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Editors:
--     EarthSalamander #42

-- Battlepass

-- to add soon:
-- Maelstrom (particles/econ/events/ti8/maelstorm_ti8.vpcf) -- jarnbjorn use a yellow particle while others use the blue one
-- Mjollnir shield (particles/econ/events/ti8/mjollnir_shield_ti8.vpcf) -- jarnbjorn use a yellow particle while others use the blue one
-- Phase Boots (particles/econ/events/ti8/phase_boots_ti8.vpcf) -- lifesteal boots use ti8 cosmetic

if Battlepass == nil then Battlepass = class({}) end
local next_reward = true
local next_reward_shown = false
if IsInToolsMode() and next_reward == true then
	next_reward_shown = true
end

local BATTLEPASS_LEVEL_REWARD = {}
BATTLEPASS_LEVEL_REWARD[2]	= "teleport1"
BATTLEPASS_LEVEL_REWARD[5]	= "trail1"
BATTLEPASS_LEVEL_REWARD[10]	= "trail2"
BATTLEPASS_LEVEL_REWARD[15]	= "trail3"

CustomNetTables:SetTableValue("game_options", "battlepass", {battlepass = BATTLEPASS_LEVEL_REWARD})

function Battlepass:Init()
	BATTLEPASS_TELEPORT = {}
	BATTLEPASS_TRAIL = {}

	for k, v in pairs(BATTLEPASS_LEVEL_REWARD) do
		if string.find(v, "teleport") then
			BATTLEPASS_TELEPORT[v] = k
		elseif string.find(v, "trail") then
			BATTLEPASS_TRAIL[v] = k
		end
	end
end

function Battlepass:AddItemEffects(hero)
	-- useless fail-safes = best fail-safes
	if hero.GetPlayerID == nil then return end

	Battlepass:GetTeleportEffect(hero)
	Battlepass:GetTrailEffect(hero)
end

function Battlepass:GetRewardUnlocked(ID)
	if IsInToolsMode() then return 500 end

	if CustomNetTables:GetTableValue("player_table", tostring(ID)) then
		if CustomNetTables:GetTableValue("player_table", tostring(ID)).Lvl then
			return CustomNetTables:GetTableValue("player_table", tostring(ID)).Lvl
		end
	end

	return 1
end

function Battlepass:GetTeleportEffect(hero)
	local tp_effect = "particles/items2_fx/teleport_start.vpcf"
	local tp_effect_end = "particles/items2_fx/teleport_end.vpcf"

	print("BP Level:", Battlepass:GetRewardUnlocked(hero:GetPlayerID()))
	if Battlepass:GetRewardUnlocked(hero:GetPlayerID()) ~= nil then
		if Battlepass:GetRewardUnlocked(hero:GetPlayerID()) >= BATTLEPASS_TELEPORT["teleport1"] then
			tp_effect = "particles/econ/events/fall_major_2016/teleport_start_fm06_lvl3.vpcf"
			tp_effect_end = "particles/econ/events/fall_major_2016/teleport_end_fm06_lvl3.vpcf"
		end
	end

	hero.tp_effect = tp_effect
	hero.tp_effect_end = tp_effect_end
end

function Battlepass:GetTrailEffect(hero)
	local effect = ""

	print("BP Level:", Battlepass:GetRewardUnlocked(hero:GetPlayerID()))
	if Battlepass:GetRewardUnlocked(hero:GetPlayerID()) ~= nil then
		if Battlepass:GetRewardUnlocked(hero:GetPlayerID()) >= BATTLEPASS_TRAIL["trail3"] then
			effect = "particles/econ/courier/courier_roshan_frost/courier_roshan_frost_ambient.vpcf"
		elseif Battlepass:GetRewardUnlocked(hero:GetPlayerID()) >= BATTLEPASS_TRAIL["trail2"] then
			effect = "particles/econ/courier/courier_roshan_lava/courier_roshan_lava.vpcf"
		elseif Battlepass:GetRewardUnlocked(hero:GetPlayerID()) >= BATTLEPASS_TRAIL["trail1"] then
			effect = "particles/econ/courier/courier_golden_roshan/golden_roshan_ambient.vpcf"
		end
	end

	local particle = ParticleManager:CreateParticle(effect, PATTACH_ABSORIGIN_FOLLOW, hero)
end

function Battlepass:InitializeTowers()
	local radiant_level = 0
	local dire_level = 0

	for ID = 0, PlayerResource:GetPlayerCount() - 1 do
		if PlayerResource:GetPlayer(ID):GetTeamNumber() == 2 then
			radiant_level = radiant_level + Battlepass:GetRewardUnlocked(ID)
		else
			dire_level = dire_level + Battlepass:GetRewardUnlocked(ID)
		end
	end

	print("Team Battlepass Levels:", radiant_level, dire_level)

	local towers = Entities:FindAllByClassname("npc_dota_tower")

	for _, tower in pairs(towers) do
		local level = dire_level
		local particle = "particles/world_tower/tower_upgrade/ti7_dire_tower_orb.vpcf"
		local team = "dire"
--		local max_particle = "particles/world_tower/tower_upgrade/ti7_radiant_tower_lvl11_orb.vpcf"

		if tower:GetTeamNumber() == 2 then
			level = radiant_level
			particle = "particles/world_tower/tower_upgrade/ti7_radiant_tower_orb.vpcf"
			team = "radiant"
		end

		tower:SetModel("models/props_structures/tower_upgrade/tower_upgrade.vmdl")
		tower:SetOriginalModel("models/props_structures/tower_upgrade/tower_upgrade.vmdl")
		tower:SetMaterialGroup(team.."_level"..Battlepass:CheckBattlepassTowerLevel(level).mg)
		ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN_FOLLOW, tower)
		StartAnimation(tower, {duration=9999, activity=ACT_DOTA_CAPTURE, rate=1.0, translate = 'level'..Battlepass:CheckBattlepassTowerLevel(level).anim})
	end
end

function Battlepass:CheckBattlepassTowerLevel(level)
	local animation
	local material_group

	if level < 25 then
		material_group = "1"
		animation = "1"
	elseif level >= 25 then
		material_group = "2"
		animation = "1"
	elseif level >= 50 then
		material_group = "2"
		animation = "2"
	elseif level >= 75 then
		material_group = "3"
		animation = "2"
	elseif level >= 100 then
		material_group = "3"
		animation = "3"
	elseif level >= 150 then
		material_group = "4"
		animation = "3"
	elseif level >= 200 then
		material_group = "4"
		animation = "4"
	elseif level >= 300 then
		material_group = "5"
		animation = "4"
	elseif level >= 500 then
		material_group = "5"
		animation = "5"
	elseif level >= 1000 then
		material_group = "6"
		animation = "5"
	elseif level >= 2000 then
		material_group = "6"
		animation = "6"
	end

	return {anim = animation, mg = material_group}
end
