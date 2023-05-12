function DebugPrint(...)
	local spew = Convars:GetInt('barebones_spew') or -1
	if spew == -1 and BAREBONES_DEBUG_SPEW then
		spew = 1
	end

	if spew == 1 then
		print(...)
	end
end

function DebugPrintTable(...)
	local spew = Convars:GetInt('barebones_spew') or -1
	if spew == -1 and BAREBONES_DEBUG_SPEW then
		spew = 1
	end

	if spew == 1 then
		PrintTable(...)
	end
end

function PrintTable(t, indent)
	--print( "PrintTable( t, indent ): " )
	if type(t) ~= "table" then return end

	for k, v in pairs(t) do
		if type(v) == "table" then
			if (v ~= t) then
				print(indent .. tostring(k) .. ":\n" .. indent .. "{")
				PrintTable(v, indent .. "  ")
				print(indent .. "}")
			end
		else
			print(indent .. tostring(k) .. ":" .. tostring(v))
		end
	end
end

-- Colors
COLOR_NONE = '\x06'
COLOR_GRAY = '\x06'
COLOR_GREY = '\x06'
COLOR_GREEN = '\x0C'
COLOR_DPURPLE = '\x0D'
COLOR_SPINK = '\x0E'
COLOR_DYELLOW = '\x10'
COLOR_PINK = '\x11'
COLOR_RED = '\x12'
COLOR_LGREEN = '\x15'
COLOR_BLUE = '\x16'
COLOR_DGREEN = '\x18'
COLOR_SBLUE = '\x19'
COLOR_PURPLE = '\x1A'
COLOR_ORANGE = '\x1B'
COLOR_LRED = '\x1C'
COLOR_GOLD = '\x1D'


--[[Author: Noya
	Date: 09.08.2015.
	Hides all dem hats
]]
function HideWearables(event)
	local hero = event.caster
	local model = hero:FirstMoveChild()

	hero.hiddenWearables = {} -- Keep every wearable handle in a table to show them later

	while model do
		if model:GetClassname() == "dota_item_wearable" then
			model:AddEffects(EF_NODRAW) -- Set model hidden
			table.insert(hero.hiddenWearables, model)
		end

		model = model:NextMovePeer()
	end
end

function ShowWearables(event)
	local hero = event.caster

	for i, v in pairs(hero.hiddenWearables) do
		v:RemoveEffects(EF_NODRAW)
	end
end

-- Adds [stack_amount] stacks to a modifier
function AddStacks(ability, caster, unit, modifier, stack_amount, refresh)
	if unit:HasModifier(modifier) then
		if refresh then
			ability:ApplyDataDrivenModifier(caster, unit, modifier, {})
		end
		unit:SetModifierStackCount(modifier, ability, unit:GetModifierStackCount(modifier, nil) + stack_amount)
	else
		ability:ApplyDataDrivenModifier(caster, unit, modifier, {})
		unit:SetModifierStackCount(modifier, ability, stack_amount)
	end
end

-- Removes [stack_amount] stacks from a modifier
function RemoveStacks(ability, unit, modifier, stack_amount)
	if unit:HasModifier(modifier) then
		if unit:GetModifierStackCount(modifier, ability) > stack_amount then
			unit:SetModifierStackCount(modifier, ability, unit:GetModifierStackCount(modifier, ability) - stack_amount)
		else
			unit:RemoveModifierByName(modifier)
		end
	end
end

-- Checks if a hero is wielding Aghanim's Scepter
function HasScepter(hero)
	for i = 0, 5 do
		local item = hero:GetItemInSlot(i)
		if item and item:GetAbilityName() == "item_ultimate_scepter" then
			return true
		end
	end

	return false
end

function shallowcopy(orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in pairs(orig) do
			copy[orig_key] = orig_value
		end
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

function ShuffledList(orig_list)
	local list = shallowcopy(orig_list)
	local result = {}
	local count = #list
	for i = 1, count do
		local pick = RandomInt(1, #list)
		result[#result + 1] = list[pick]
		table.remove(list, pick)
	end
	return result
end

function GenerateNumPointsAround(num, center, distance)
	local points = {}
	local angle = 360 / num
	for i = 0, num - 1 do
		local rotate_pos = center + Vector(1, 0, 0) * distance
		table.insert(points, RotatePosition(center, QAngle(0, angle * i, 0), rotate_pos))
	end
	return points
end

function HasEpic1(hero)
	if hero.has_epic_1 then
		return true
	end
	return false
end

function HasEpic2(hero)
	if hero.has_epic_2 then
		return true
	end
	return false
end

function HasEpic3(hero)
	if hero.has_epic_3 then
		return true
	end
	return false
end

function HasEpic4(hero)
	if hero.has_epic_4 then
		return true
	end
	return false
end

function HeroImage(hero)
	if hero.hero_image then
		return true
	end
	return false
end

function DualChoose(hero)
	if hero.dual_choose then
		return 1
	end
	return 0
end

function Lvl20Whispering(hero)
	if hero.lvl_20 then
		return true
	end
	return false
end

-- IMBA Rune System
function SpawnRunes()
	local powerup_rune_locations = Entities:FindAllByName("dota_item_rune_spawner_custom")
	local game_time = GameRules:GetDOTATime(false, false)

	RemoveRunes()

	-- List of powerup rune types
	local powerup_rune_types = {
		"item_rune_armor",
		"item_rune_immolation"
	}

	for _, rune_loc in pairs(powerup_rune_locations) do
		local rune = CreateItemOnPositionForLaunch(rune_loc:GetAbsOrigin() + Vector(0, 0, 50), CreateItem(powerup_rune_types[RandomInt(1, #powerup_rune_types)], nil, nil))
		RegisterRune(rune)
	end
end

function RegisterRune(rune)
	-- Initialize table
	if not rune_spawn_table then
		rune_spawn_table = {}
	end

	-- Register rune into table
	table.insert(rune_spawn_table, rune)
end

function RemoveRunes()
	if rune_spawn_table then
		-- Remove existing runes
		for _, rune in pairs(rune_spawn_table) do
			if not rune:IsNull() then
				local item = rune:GetContainedItem()
				UTIL_Remove(item)
				UTIL_Remove(rune)
			end
		end

		-- Clear the table
		rune_spawn_table = {}
	end
end

function PickupRune(item, unit)
	local gameEvent = {}
	if unit:IsRealHero() then
		gameEvent["player_id"] = unit:GetPlayerID()
	elseif unit:IsConsideredHero() then
		gameEvent["player_id"] = unit:GetPlayerOwnerID()
	end
	gameEvent["team_number"] = unit:GetTeamNumber()
	gameEvent["locstring_value"] = "#DOTA_Tooltip_Ability_" .. item:GetAbilityName()
	gameEvent["message"] = "#Dungeon_Rune"
	FireGameEvent("dota_combat_event_message", gameEvent)
end

-- Overrides dota method, use modifier_summoned MODIFIER_STATE_DOMINATED
function CDOTA_BaseNPC:IsSummoned()
	return self:IsDominated()
end

function CDOTA_BaseNPC:IsDummy()
	return self:GetUnitName():match("dummy_") or self:GetUnitLabel():match("dummy")
end

function SendErrorMessage(playerID, string)
	CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "dotacraft_error_message", { message = string })
end

-- Similar to SendErrorMessage to the bottom, except it checks whether the source of error is currently selected unit/hero.
function SendErrorMessageForSelectedUnit(playerID, string, unit)
	local selected = PlayerResource:GetSelectedEntities(playerID)
	if selected and selected["0"] == unit:GetEntityIndex() then
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "dotacraft_error_message", { message = string })
	end
end

-- Skeleton king cosmetics
function SkeletonKingWearables(hero)
	-- Cape
	Attachments:AttachProp(hero, "attach_hitloc", "models/items/wraith_king/regalia_of_the_bonelord_cape.vmdl", 1.0)

	-- Shoulderpiece
	Attachments:AttachProp(hero, "attach_hitloc", "models/heroes/wraith_king/wraith_king_shoulder.vmdl", 1.0)

	-- Crown
	Attachments:AttachProp(hero, "attach_head", "models/items/wraith_king/kings_spite_head/kings_spite_head.vmdl", 1.0)

	-- Chest
	Attachments:AttachProp(hero, "attach_hitloc", "models/heroes/wraith_king/wraith_king_chest.vmdl", 1.0)

	-- Gauntlet
	--	Attachments:AttachProp(hero, "attach_attack1", "models/heroes/wraith_king/wraith_king_gauntlet.vmdl", 1.0)

	-- Weapon
	Attachments:AttachProp(hero, "attach_attack1", "models/items/skeleton_king/the_blood_shard/the_blood_shard.vmdl", 1.0)

	-- Eye particles
	local eye_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_skeletonking/skeletonking_eyes.vpcf", PATTACH_ABSORIGIN, hero)
	ParticleManager:SetParticleControlEnt(eye_pfx, 0, hero, PATTACH_POINT_FOLLOW, "attach_eyeL", hero:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(eye_pfx, 1, hero, PATTACH_POINT_FOLLOW, "attach_eyeR", hero:GetAbsOrigin(), true)
end

-- ITEMS
function GetItemByID(id)
	for k, v in pairs(GameMode.ItemKVs) do
		if tonumber(v["ID"]) == id then return v end
	end
end

function OpenLane(lane_number)
	if CustomTimers.game_phase == 1 then
		if CREEP_LANES_TYPE == 1 then
			OpenCreepLane(lane_number)
		elseif CREEP_LANES_TYPE == 2 then
			if lane_number == 1 or lane_number == 2 then
				for i = 1, 2 do
					OpenCreepLane(i)
				end
			elseif lane_number == 3 or lane_number == 4 then
				for i = 3, 4 do
					OpenCreepLane(i)
				end
			elseif lane_number == 5 or lane_number == 6 then
				for i = 5, 6 do
					OpenCreepLane(i)
				end
			elseif lane_number == 7 or lane_number == 8 then
				for i = 7, 8 do
					OpenCreepLane(i)
				end
			end
		end
	end
end

function OpenCreepLane(lane_number)
	if CREEP_LANES[lane_number][1] == 1 then return end
	local DoorObs = Entities:FindAllByName("obstruction_lane" .. lane_number)
	local towers = Entities:FindAllByName("dota_badguys_tower" .. lane_number)
	local raxes = Entities:FindAllByName("dota_badguys_barracks_" .. lane_number)

	for _, obs in pairs(DoorObs) do
		obs:SetEnabled(false, true)
	end

	for _, tower in pairs(towers) do
		tower:RemoveModifierByName("modifier_invulnerable")
	end

	for _, rax in pairs(raxes) do
		rax:RemoveModifierByName("modifier_invulnerable")
	end

	Notifications:TopToAll({ text = "Host opened lane " .. lane_number .. "!", style = { color = "lightgreen" }, duration = 5.0 })
	CREEP_LANES[lane_number][1] = 1
	DoEntFire("door_lane" .. lane_number, "SetAnimation", "gate_02_open", 0, nil, nil)
end

function CloseLane(ID, lane_number)
	local player_count = PlayerResource:GetPlayerCount()
	for i = 0, PlayerResource:GetPlayerCount() - 1 do
		if PlayerResource:GetConnectionState(i) ~= 2 then
			player_count = player_count - 1
		end
	end

	if CustomTimers.game_phase ~= 3 then
		if CREEP_LANES_TYPE == 1 then
			print(lane_number, player_count)
			if lane_number <= player_count then
				SendErrorMessage(ID, "#error_cant_close_lane_player_count")
				return
			end

			CloseCreepLane(lane_number)
		elseif CREEP_LANES_TYPE == 2 then
			print(math.ceil(lane_number / 2), player_count)
			if math.ceil(lane_number / 2) <= player_count then
				SendErrorMessage(ID, "#error_cant_close_lane_player_count")
				return
			end

			if lane_number == 1 or lane_number == 2 then
				for i = 1, 2 do
					CloseCreepLane(i)
				end
			elseif lane_number == 3 or lane_number == 4 then
				for i = 3, 4 do
					CloseCreepLane(i)
				end
			elseif lane_number == 5 or lane_number == 6 then
				for i = 5, 6 do
					CloseCreepLane(i)
				end
			elseif lane_number == 7 or lane_number == 8 then
				for i = 7, 8 do
					CloseCreepLane(i)
				end
			end
		end
	end
end

function CloseCreepLane(lane_number)
	if not CREEP_LANES[lane_number] then return end
	if not CREEP_LANES[lane_number][1] then return end

	if CREEP_LANES[lane_number][1] == 0 then return end
	local DoorObs = Entities:FindAllByName("obstruction_lane" .. lane_number)
	local towers = Entities:FindAllByName("dota_badguys_tower" .. lane_number)
	local raxes = Entities:FindAllByName("dota_badguys_barracks_" .. lane_number)

	for _, obs in pairs(DoorObs) do
		obs:SetEnabled(true, false)
	end

	for _, tower in pairs(towers) do
		tower:AddNewModifier(tower, nil, "modifier_invulnerable", nil)
	end

	for _, rax in pairs(raxes) do
		rax:AddNewModifier(rax, nil, "modifier_invulnerable", nil)
	end

	Notifications:TopToAll({ text = "Host closed lane " .. lane_number .. "!", style = { color = "red" }, duration = 5.0 })
	CREEP_LANES[lane_number][1] = 0
	DoEntFire("door_lane" .. lane_number, "SetAnimation", "gate_02_close", 0, nil, nil)
end

function PauseHeroes()
	-- heal/revive heroes
	RefreshPlayers()

	for _, hero in pairs(HeroList:GetAllHeroes()) do
		if hero:IsRealHero() then
			hero:AddNewModifier(hero, nil, "modifier_pause_creeps", nil)
			hero:AddNewModifier(hero, nil, "modifier_invulnerable", nil)
		end
	end
end

function RestartHeroes()
	for _, hero in pairs(HeroList:GetAllHeroes()) do
		if hero:IsRealHero() then
			hero:RemoveModifierByName("modifier_pause_creeps")
			hero:RemoveModifierByName("modifier_invulnerable")
		end
	end
end

function PauseCreeps(iTime)
	local units = FindUnitsInRadius(DOTA_TEAM_CUSTOM_1, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
	local units2 = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
	local units3 = FindUnitsInRadius(DOTA_TEAM_BADGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)

	for _, v in pairs(units) do
		if v:HasMovementCapability() and not v.Boss then
			v:AddNewModifier(v, nil, "modifier_pause_creeps", { duration = iTime })
			v:AddNewModifier(v, nil, "modifier_invulnerable", { duration = iTime })
		end
	end

	for _, v in pairs(units2) do
		if v:HasMovementCapability() then
			v:AddNewModifier(v, nil, "modifier_pause_creeps", { duration = iTime })
			v:AddNewModifier(v, nil, "modifier_invulnerable", { duration = iTime })
		end
	end

	for _, v in pairs(units3) do
		if v:HasMovementCapability() then
			v:AddNewModifier(v, nil, "modifier_pause_creeps", { duration = iTime })
			v:AddNewModifier(v, nil, "modifier_invulnerable", { duration = iTime })
		end
	end
end

function KillCreeps(teamnumber)
	local units = FindUnitsInRadius(teamnumber, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)

	for _, v in pairs(units) do
		if v:HasMovementCapability() then
			--			v:RemoveSelf()
			v:ForceKill(false) -- looks better visually, revert if causing new bugs
		end
	end
end

function RestartCreeps(delay)
	local units = FindUnitsInRadius(DOTA_TEAM_BADGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
	local units2 = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
	local units3 = FindUnitsInRadius(DOTA_TEAM_CUSTOM_1, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)

	Timers:CreateTimer(delay, function()
		for _, v in pairs(units) do
			--			if v and v:HasMovementCapability() then
			if IsValidEntity(v) then
				if v:HasModifier("modifier_pause_creeps") then
					v:RemoveModifierByName("modifier_pause_creeps")
				end
				if v:HasModifier("modifier_invulnerable") then
					v:RemoveModifierByName("modifier_invulnerable")
				end
			end
		end

		for _, v in pairs(units2) do
			--			if v and v:HasMovementCapability() then
			if IsValidEntity(v) and not string.find(v:GetUnitName(), "npc_xhs_paladin") then
				if v:HasModifier("modifier_pause_creeps") then
					v:RemoveModifierByName("modifier_pause_creeps")
				end
				if v:HasModifier("modifier_invulnerable") then
					v:RemoveModifierByName("modifier_invulnerable")
				end
			end
		end

		for _, v in pairs(units3) do
			--			if v and v:HasMovementCapability() then
			if IsValidEntity(v) then
				if v:HasModifier("modifier_pause_creeps") then
					v:RemoveModifierByName("modifier_pause_creeps")
				end
				if v:HasModifier("modifier_invulnerable") then
					v:RemoveModifierByName("modifier_invulnerable")
				end
			end
		end
	end)
end

function DisableItems(hero, time)
	timers.disabled_items = Timers:CreateTimer(0.0, function()
		for itemSlot = 0, 5 do
			local item = hero:GetItemInSlot(itemSlot)
			if item then
				if item:GetName() == "item_tome_small" then
					item:StartCooldown(time)
				elseif item:GetName() == "item_tome_big" then
					item:StartCooldown(time)
				elseif item:GetName() == "item_tpscroll" then
					item:StartCooldown(time)
				end
			end
		end
	end)
end

function EnableItems(hero)
	if timers.disabled_items then
		Timers:RemoveTimer(timers.disabled_items)
	end
	for itemSlot = 0, 5 do
		local item = hero:GetItemInSlot(itemSlot)
		if item then
			if item:GetName() == "item_tome_small" then
				item:EndCooldown()
			elseif item:GetName() == "item_tome_big" then
				item:EndCooldown()
			elseif item:GetName() == "item_tpscroll" then
				item:EndCooldown()
			end
		end
	end
end

function SendErrorMessage(playerID, string)
	CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "dotacraft_error_message", { message = string })
end

function RefreshPlayers()
	for nPlayerID = 0, PlayerResource:GetPlayerCount() - 1 do
		if PlayerResource:HasSelectedHero(nPlayerID) then
			local hero = PlayerResource:GetSelectedHeroEntity(nPlayerID)

			if not hero:IsAlive() then
				hero:RespawnHero(false, false)
				hero.ankh_respawn = false
				hero:SetRespawnsDisabled(false)
				if hero.respawn_timer ~= nil then
					Timers:RemoveTimer(hero.respawn_timer)
					hero.respawn_timer = nil
				end
			end

			hero:SetHealth(hero:GetMaxHealth())
			hero:SetMana(hero:GetMaxMana())
		end
	end
end

function TeleportHero(hero, point, delay, iCameraSpeed)
	if not hero.GetPlayerID then return end
	if hero:GetPlayerID() == -1 then return end
	if delay == nil then delay = 0 end
	local pos = hero:GetAbsOrigin()
	--	local pos = hero:GetAbsOrigin() + RandomVector(400)

	local TeleportEffect
	local TeleportEffectEnd

	if delay > 0 then
		TeleportEffect = ParticleManager:CreateParticle("particles/items2_fx/teleport_start.vpcf", PATTACH_ABSORIGIN, hero, hero)
		ParticleManager:SetParticleControlEnt(TeleportEffect, PATTACH_ABSORIGIN, hero, PATTACH_ABSORIGIN, "attach_origin", pos, true)
		hero:Attribute_SetIntValue("effectsID", TeleportEffect)

		TeleportEffectEnd = ParticleManager:CreateParticle("particles/items2_fx/teleport_end.vpcf", PATTACH_ABSORIGIN, hero, hero)
		ParticleManager:SetParticleControlEnt(TeleportEffect, PATTACH_ABSORIGIN, hero, PATTACH_ABSORIGIN, "attach_origin", point, true)
		ParticleManager:SetParticleControl(TeleportEffectEnd, 1, point)
		hero:Attribute_SetIntValue("effectsID", TeleportEffect)

		hero:EmitSound("Portal.Loop_Appear")
	end

	hero:AddNewModifier(hero, nil, "modifier_command_restricted", {})

	CustomGameEventManager:Send_ServerToPlayer(hero:GetPlayerOwner(), "set_player_camera", { hPosition = point, iSpeed = iCameraSpeed })

	Timers:CreateTimer(delay, function()
		EmitSoundOnLocationWithCaster(pos, "Portal.Hero_Disappear", hero)

		hero:StopSound("Portal.Loop_Appear")

		if hero:GetUnitName() == "npc_dota_hero_meepo" then
			local meepo_table = Entities:FindAllByName("npc_dota_hero_meepo")

			if meepo_table then
				for i = 1, #meepo_table do
					FindClearSpaceForUnit(meepo_table[i], point, false)
					meepo_table[i]:Stop()
				end
			end
		else
			FindClearSpaceForUnit(hero, point, true)
			hero:Stop()
		end

		EmitSoundOnLocationWithCaster(hero:GetAbsOrigin(), "Portal.Hero_Appear", hero)
		hero:RemoveModifierByName("modifier_command_restricted")

		if delay > 0 then
			ParticleManager:DestroyParticle(TeleportEffect, false)
			ParticleManager:DestroyParticle(TeleportEffectEnd, false)
			ParticleManager:ReleaseParticleIndex(TeleportEffect)
			ParticleManager:ReleaseParticleIndex(TeleportEffectEnd)
		end
	end)
end

-- Ported from Dota IMBA
-- Get the base projectile of a unit
function GetBaseRangedProjectileName(unit)
	local unit_name = unit:GetUnitName()
	unit_name = string.gsub(unit_name, "dota", "imba")

	local unit_table = unit:IsHero() and GameRules.HeroKV[unit_name] or GameRules.UnitKV[unit_name]
	return unit_table and unit_table["ProjectileModel"] or ""
end

function ChangeAttackProjectile(unit)
	unit:SetRangedProjectileName(GetBaseRangedProjectileName(unit))
end

function StunBuildings(time)
	for Players = 1, 8 do
		local towers = Entities:FindAllByName("dota_badguys_tower" .. Players)
		for _, tower in pairs(towers) do
			if not tower:HasModifier("modifier_invulnerable") then
				tower:AddNewModifier(tower, nil, "modifier_invulnerable", { duration = time })
			end
		end
		local raxes = Entities:FindAllByName("dota_badguys_barracks_" .. Players)
		for _, rax in pairs(raxes) do
			if not rax:HasModifier("modifier_invulnerable") then
				rax:AddNewModifier(rax, nil, "modifier_invulnerable", { duration = time })
			end
		end
	end
	for TW = 1, 2 do
		local ice_towers = Entities:FindAllByName("npc_tower_cold_" .. TW)
		for _, tower in pairs(ice_towers) do
			if not tower:HasModifier("modifier_invulnerable") then
				tower:AddNewModifier(tower, nil, "modifier_invulnerable", { duration = time })
			end
		end
	end
	local death_towers = Entities:FindAllByName("npc_tower_death")
	for _, tower in pairs(death_towers) do
		if not tower:HasModifier("modifier_invulnerable") then
			tower:AddNewModifier(tower, nil, "modifier_invulnerable", { duration = time })
		end
	end
end

function getkvValues(tEntity, ...) -- KV Values look hideous in finished code, so this function will parse through all sent KV's for tEntity (typically self)
	local values = { ... }
	local data = {}
	for i, v in ipairs(values) do
		table.insert(data, tEntity:GetSpecialValueFor(v))
	end
	return unpack(data)
end

--[[
  Credits:
    Angel Arena Blackstar
  Description:
    Returns the player id from a given unit / player / table.
    For example, you should be able to pass in a reference to a lycan wolf and get back the correct player's ID.
    -- chrisinajar
]]
function UnitVarToPlayerID(unitvar)
	if unitvar then
		if type(unitvar) == "number" then
			return unitvar
		elseif type(unitvar) == "table" and not unitvar:IsNull() and unitvar.entindex and unitvar:entindex() then
			if unitvar.GetPlayerID and unitvar:GetPlayerID() > -1 then
				return unitvar:GetPlayerID()
			elseif unitvar.GetPlayerOwnerID then
				return unitvar:GetPlayerOwnerID()
			end
		end
	end

	return -1
end

function CDOTA_BaseNPC:IsXHSReincarnating()
	if self:IsReincarnating() then
		return true
	end

	return self.ankh_respawn
end

function GetBossBarColor(sBossName)
	local colors = {}
	colors.light_color = "#009933"
	colors.dark_color = "#003311"

	if sBossName == "npc_dota_hero_arthas" then
		colors.light_color = "#e6ac00"
		colors.dark_color = "#b34700"
	elseif sBossName == "npc_dota_hero_banehallow" then
		colors.light_color = "#ff6600"
		colors.dark_color = "#320000"
	elseif sBossName == "npc_dota_boss_lich_king" then
		colors.light_color = "#0047b3"
		colors.dark_color = "#000d33"
	elseif sBossName == "npc_dota_boss_spirit_master_storm" then
		colors.light_color = "#0092B3"
		colors.dark_color = "#002B33"
	elseif sBossName == "npc_dota_boss_spirit_master_fire" then
		colors.light_color = "#ff6600"
		colors.dark_color = "#320000"
	end

	return colors
end

function GetBossBarIcon(sBossName)
	if sBossName == "npc_dota_hero_arthas" then
		icon = "npc_dota_hero_omniknight"
	elseif sBossName == "npc_dota_hero_balanar" then
		icon = "npc_dota_hero_pugna"
	elseif sBossName == "npc_dota_hero_banehallow" then
		icon = "npc_dota_hero_nevermore"
	elseif sBossName == "npc_dota_hero_grom_hellscream" then
		icon = "npc_dota_hero_juggernaut"
	elseif sBossName == "npc_dota_hero_illidan" then
		icon = "npc_dota_hero_terrorblade"
	elseif sBossName == "npc_dota_boss_lich_king" then
		icon = "npc_dota_hero_abaddon"
	elseif sBossName == "npc_dota_hero_magtheridon" then
		icon = "npc_dota_hero_abyssal_underlord"
	elseif sBossName == "npc_dota_hero_proudmoore" then
		icon = "npc_dota_hero_kunkka"
	elseif sBossName == "npc_dota_boss_spirit_master_storm" then
		icon = "npc_dota_hero_storm_spirit"
	elseif sBossName == "npc_dota_boss_spirit_master_earth" then
		icon = "npc_dota_hero_earth_spirit"
	elseif sBossName == "npc_dota_boss_spirit_master_fire" then
		icon = "npc_dota_hero_ember_spirit"
	end
end

function ShowBossBar(caster)
	if caster.deathStart then return end
	local icon = GetBossBarIcon(caster:GetUnitName())
	local colors = GetBossBarColor(caster:GetUnitName())
	if caster.boss_count == nil then caster.boss_count = 1 end

	CustomGameEventManager:Send_ServerToAllClients("show_boss_hp", {
		boss_name = caster:GetUnitName(),
		difficulty = GameRules:GetCustomGameDifficulty(),
		boss_icon = icon,
		light_color = colors.light_color,
		dark_color = colors.dark_color,
		boss_health = caster:GetHealth(),
		boss_max_health = caster:GetMaxHealth(),
		boss_count = caster.boss_count,
	})
end

function UpdateBossBar(boss, attacker)
	if boss.deathStart then return end
	if boss.boss_count == nil then boss.boss_count = 1 end

	CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(attacker:GetPlayerID()), "update_boss_hp", {
		boss_health = boss:GetHealth(),
		boss_max_health = boss:GetMaxHealth(),
		boss_count = boss.boss_count,
	})
end

function IsNearEntity(entity_class, location, distance)
	local entity = Entities:FindByName(nil, entity_class)
	if (entity:GetAbsOrigin() - location):Length2D() <= distance then
		return true
	end

	return false
end

function TeleportAllHeroes(sEvent, iInvulnDelay, iTPDelay)
	for _, hero in pairs(HeroList:GetAllHeroes()) do
		if hero:IsRealHero() and hero:GetTeam() == DOTA_TEAM_GOODGUYS then
			local id = hero:GetPlayerID()
			if hero:GetPlayerID() ~= -1 then
				local point = Entities:FindByName(nil, sEvent .. tostring(id)) -- might cause error with Dark Fundamental?

				TeleportHero(hero, point:GetAbsOrigin(), iTPDelay)
				hero:AddNewModifier(hero, nil, "modifier_pause_creeps", { duration = iInvulnDelay, IsHidden = true })
				hero:AddNewModifier(hero, nil, "modifier_invulnerable", { duration = iInvulnDelay, IsHidden = true })
			end
		end
	end
end

function GiveTomeToAllHeroes(iCount)
	local sound_played = false

	Notifications:TopToAll({ text = "Power Up: +250 to all stats!", style = { color = "green" }, duration = 10.0 })

	for _, hero in pairs(HeroList:GetAllHeroes()) do
		hero:IncrementAttributes(iCount)
	end
end

function WinGame()
	GameRules:SetGameWinner(2)
end

function MapDemo()
	return GetMapName() == "x_hero_siege_demo"
end

-- credits to yahnich for the following
function CDOTA_BaseNPC:IsRealHero()
	if not self:IsNull() then
		return self:IsHero() and not (self:IsIllusion() or self:IsClone()) and not self:IsFakeHero()
	end
end

function CDOTA_BaseNPC:IsFakeHero()
	if self:IsIllusion() or (self:HasModifier("modifier_monkey_king_fur_army_soldier") or self:HasModifier("modifier_monkey_king_fur_army_soldier_hidden")) or self:IsTempestDouble() or self:IsClone() or self:HasAbility("dummy_passive_vulnerable") then
		return true
	else
		return false
	end
end

function ReturnFromSpecialArena(hero)
	CustomTimers.timers_paused = 0
	CustomGameEventManager:Send_ServerToAllClients("hide_timer_special_arena", {})
	GameMode.SpecialArena_occuring = 0

	local teleport_time = 3.0

	RestartCreeps(teleport_time + 3)

	if hero.old_pos then
		TeleportHero(hero, hero.old_pos, teleport_time)
	else
		if hero:GetTeamNumber() == 2 then
			TeleportHero(hero, BASE_GOOD:GetAbsOrigin(), 3.0)
			--		elseif hero:GetTeamNumber() == 3 then
			--			TeleportHero(hero, base_bad:GetAbsOrigin(), 3.0)
		end
	end

	hero:EmitSound("Hero_TemplarAssassin.Trap")
end
