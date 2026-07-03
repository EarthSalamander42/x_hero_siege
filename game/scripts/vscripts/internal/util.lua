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

function ApplyGrowthOverheadMarker(unit, value)
	if not IsValidEntity(unit) then return end

	local modifier = unit:FindModifierByName("modifier_xhs_growth_overhead")
	if modifier then
		modifier:UpdateOverheadValue(value)
	else
		unit:AddNewModifier(unit, nil, "modifier_xhs_growth_overhead", { growth_value = value or 0 })
	end
end

function GetUnitAbilityCount(unit)
	if unit == nil or not IsValidEntity(unit) or unit:IsNull() then return 0 end
	if unit.GetAbilityCount == nil then return 0 end

	local count = unit:GetAbilityCount()
	if count == nil or count < 0 then return 0 end

	return count
end

function GetUnitAbilityBySafeIndex(unit, index)
	if index == nil or index < 0 then return nil end
	if index >= GetUnitAbilityCount(unit) then return nil end

	return unit:GetAbilityByIndex(index)
end

function ForEachUnitAbility(unit, callback)
	if callback == nil then return end

	local ability_count = GetUnitAbilityCount(unit)
	for ability_index = 0, ability_count - 1 do
		local ability = unit:GetAbilityByIndex(ability_index)
		if ability ~= nil and IsValidEntity(ability) then
			callback(ability, ability_index)
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

local XHS_TOME_ITEM_NAMES = {
	item_tome_small = true,
	item_tome_big = true,
	item_tome_of_power = true,
}

function IsTomeItemName(itemName)
	return itemName ~= nil and XHS_TOME_ITEM_NAMES[itemName] == true
end

function SetHeroOptionalEventTomeLock(hero, eventName, isLocked)
	if hero == nil or hero:IsNull() then return end

	if isLocked then
		hero.xhs_optional_event_tome_locked = true
		hero.xhs_optional_event_tome_lock_name = eventName
	else
		hero.xhs_optional_event_tome_locked = nil
		hero.xhs_optional_event_tome_lock_name = nil
	end
end

function IsHeroOptionalEventTomeLocked(hero)
	return hero ~= nil and not hero:IsNull() and hero.xhs_optional_event_tome_locked == true
end

function IsTomePurchaseGloballyLocked()
	return BT_ENABLED == 0
		or GameMode.Muradin_occuring == true
		or GameMode.SpecialArena_occuring == true
end

function BuyMaxSmallTomesForPlayer(playerID)
	if playerID == nil or playerID < 0 or not PlayerResource:IsValidPlayerID(playerID) then return 0 end

	local player = PlayerResource:GetPlayer(playerID)
	if player == nil then return 0 end

	if GameRules:IsGamePaused() then
		SendErrorMessage(playerID, "#error_buy_tome_pause")
		return 0
	end

	local hero = PlayerResource:GetSelectedHeroEntity(playerID) or player:GetAssignedHero()
	if hero == nil or hero:IsNull() then return 0 end

	if IsPlayerXHSReincarnating(playerID) then
		SendErrorMessage(playerID, "#error_reincarnation_inventory_locked")
		return 0
	end

	if IsHeroOptionalEventTomeLocked(hero) or IsTomePurchaseGloballyLocked() then
		SendErrorMessage(playerID, "#error_buy_tome_disabled")
		return 0
	end

	local cost = 10000
	local numberOfTomes = math.floor(Gold:GetGold(playerID) / cost)
	if numberOfTomes < 1 then
		SendErrorMessage(playerID, "#error_cant_afford_tomes")
		return 0
	end

	Notifications:Bottom(player, { text = "You've bought " .. numberOfTomes .. " Tomes!", duration = 5.0, style = { color = "white" } })
	PlayerResource:SpendGold(playerID, numberOfTomes * cost, DOTA_ModifyGold_PurchaseItem)

	local i = 0
	GameRules:GetGameModeEntity():SetContextThink("PreGame", function()
		if hero == nil or hero:IsNull() then return nil end

		hero:IncrementAttributes(50)
		hero:EmitSound("ui.trophy_levelup")

		local pfx = ParticleManager:CreateParticle("particles/generic_hero_status/hero_levelup.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero, hero)
		ParticleManager:SetParticleControl(pfx, 0, hero:GetAbsOrigin())

		i = i + 1
		if i >= numberOfTomes then
			return nil
		end
		return 0.1
	end, FrameTime())

	return numberOfTomes
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

-- Overrides dota method, use modifier_summoned MODIFIER_STATE_DOMINATED
function CDOTA_BaseNPC:IsSummoned()
	return self:IsDominated()
end

function CDOTA_BaseNPC:IsDummy()
	return self:GetUnitName():match("dummy_") or self:GetUnitLabel():match("dummy")
end

function CDOTA_BaseNPC:IsXHSRuneUnit()
	return self.xhs_is_rune == true
end

function IsXHSRuneUnit(unit)
	return unit ~= nil and not unit:IsNull() and ((unit.IsXHSRuneUnit and unit:IsXHSRuneUnit()) or unit.xhs_is_rune == true)
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
			if lane_number <= player_count then
				SendErrorMessage(ID, "#error_cant_close_lane_player_count")
				return
			end

			CloseCreepLane(lane_number)
		elseif CREEP_LANES_TYPE == 2 then
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
			hero:RemoveModifierByName("modifier_cinematic_pause")
			hero:RemoveModifierByName("modifier_invulnerable")
		end
	end
end

function CinematicPauseHeroes(rampDuration)
	RefreshPlayers()

	for _, hero in pairs(HeroList:GetAllHeroes()) do
		if hero:IsRealHero() then
			hero:AddNewModifier(hero, nil, "modifier_cinematic_pause", { ramp_duration = rampDuration })
		end
	end
end

function CinematicPauseHero(hero, rampDuration, duration)
	if hero == nil or hero:IsNull() or not hero:IsRealHero() then return end

	hero:AddNewModifier(hero, nil, "modifier_cinematic_pause", {
		duration = duration,
		ramp_duration = rampDuration,
	})
end

function CinematicPauseHeroesForDuration(rampDuration, duration)
	RefreshPlayers()

	for _, hero in pairs(HeroList:GetAllHeroes()) do
		CinematicPauseHero(hero, rampDuration, duration)
	end
end

function CinematicPauseGame(rampDuration, duration)
	CinematicPauseCreeps(rampDuration, duration)
	CinematicPauseHeroesForDuration(rampDuration, duration)
end

function PauseCreeps(iTime)
	if iTime then
		print("Pausing creeps for " .. iTime .. " seconds")
	else
		print("Pausing creeps indefinitely")
	end

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

function CinematicPauseCreeps(rampDuration, iTime)
	if iTime then
		print("Cinematic pausing creeps for " .. iTime .. " seconds")
	else
		print("Cinematic pausing creeps indefinitely")
	end

	ApplyCinematicPauseToCreeps(rampDuration, iTime)
end

function ApplyCinematicPauseToCreeps(rampDuration, iTime)
	local units = FindUnitsInRadius(DOTA_TEAM_CUSTOM_1, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
	local units2 = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
	local units3 = FindUnitsInRadius(DOTA_TEAM_BADGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)

	for _, v in pairs(units) do
		if v:HasMovementCapability() and not v.Boss and not v:HasModifier("modifier_cinematic_pause") then
			v:AddNewModifier(v, nil, "modifier_cinematic_pause", { duration = iTime, ramp_duration = rampDuration })
		end
	end

	for _, v in pairs(units2) do
		if v:HasMovementCapability() and not v:HasModifier("modifier_cinematic_pause") then
			v:AddNewModifier(v, nil, "modifier_cinematic_pause", { duration = iTime, ramp_duration = rampDuration })
		end
	end

	for _, v in pairs(units3) do
		if v:HasMovementCapability() and not v:HasModifier("modifier_cinematic_pause") then
			v:AddNewModifier(v, nil, "modifier_cinematic_pause", { duration = iTime, ramp_duration = rampDuration })
		end
	end
end

function StartCinematicPauseCreepsWatch(name, rampDuration)
	name = name or "xhs_cinematic_pause_creeps_watch"

	GameRules:GetGameModeEntity():SetContextThink(name, function()
		if GameMode.SpecialArena_occuring ~= true then
			return nil
		end

		ApplyCinematicPauseToCreeps(rampDuration)
		return 0.25
	end, 0.0)
end

function KillCreeps(teamnumber)
	local units = FindUnitsInRadius(teamnumber, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)

	for _, v in pairs(units) do
		if v:HasMovementCapability() then
			--			v:RemoveSelf()
			v:Kill(nil, nil) -- looks better visually, revert if causing new bugs
		end
	end
end

function RestartCreeps(delay)
	if delay then
		print("Restarting creeps in " .. delay .. " seconds")
	else
		print("Restarting creeps immediately")
	end

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
				if v:HasModifier("modifier_cinematic_pause") then
					v:RemoveModifierByName("modifier_cinematic_pause")
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
				if v:HasModifier("modifier_cinematic_pause") then
					v:RemoveModifierByName("modifier_cinematic_pause")
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
				if v:HasModifier("modifier_cinematic_pause") then
					v:RemoveModifierByName("modifier_cinematic_pause")
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
				elseif item:GetName() == "item_tome_of_power" then
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
			elseif item:GetName() == "item_tome_of_power" then
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
				_G.XHS_REINCARNATING_PLAYERS = _G.XHS_REINCARNATING_PLAYERS or {}
				_G.XHS_REINCARNATING_PLAYERS[nPlayerID] = nil
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

-- Ported from upstream custom game code
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

local XHS_REINCARNATION_INVENTORY_FIRST_SLOT = 0
local XHS_REINCARNATION_INVENTORY_LAST_SLOT = 14

local function GetXHSInventorySlotItemEntIndex(hero, slot)
	local item = hero:GetItemInSlot(slot)
	if item ~= nil and not item:IsNull() then
		return item:entindex()
	end

	return -1
end

function SnapshotXHSReincarnationInventory(hero)
	if hero == nil or hero:IsNull() then return end

	hero.xhs_reincarnation_inventory_snapshot = {}
	for slot = XHS_REINCARNATION_INVENTORY_FIRST_SLOT, XHS_REINCARNATION_INVENTORY_LAST_SLOT do
		hero.xhs_reincarnation_inventory_snapshot[slot] = GetXHSInventorySlotItemEntIndex(hero, slot)
	end
end

function ClearXHSReincarnationInventorySnapshot(hero)
	if hero == nil or hero:IsNull() then return end

	hero.xhs_reincarnation_inventory_snapshot = nil
	hero.xhs_reincarnation_inventory_restoring = nil
	hero.xhs_reincarnation_inventory_lock_message_time = nil
end

function WasItemInXHSReincarnationInventorySnapshot(hero, item)
	if hero == nil or hero:IsNull() or item == nil or item:IsNull() then return false end

	local snapshot = hero.xhs_reincarnation_inventory_snapshot
	if snapshot == nil then return false end

	local itemEntIndex = item:entindex()
	for slot = XHS_REINCARNATION_INVENTORY_FIRST_SLOT, XHS_REINCARNATION_INVENTORY_LAST_SLOT do
		if snapshot[slot] == itemEntIndex then
			return true
		end
	end

	return false
end

function RestoreXHSReincarnationInventory(hero)
	if hero == nil or hero:IsNull() then return false end
	if hero.xhs_reincarnation_inventory_restoring == true then return false end

	local snapshot = hero.xhs_reincarnation_inventory_snapshot
	if snapshot == nil then return false end

	local changed = false
	hero.xhs_reincarnation_inventory_restoring = true

	for targetSlot = XHS_REINCARNATION_INVENTORY_FIRST_SLOT, XHS_REINCARNATION_INVENTORY_LAST_SLOT do
		local expectedEntIndex = snapshot[targetSlot] or -1
		if expectedEntIndex ~= -1 and GetXHSInventorySlotItemEntIndex(hero, targetSlot) ~= expectedEntIndex then
			local sourceSlot = nil
			for slot = XHS_REINCARNATION_INVENTORY_FIRST_SLOT, XHS_REINCARNATION_INVENTORY_LAST_SLOT do
				if GetXHSInventorySlotItemEntIndex(hero, slot) == expectedEntIndex then
					sourceSlot = slot
					break
				end
			end

			if sourceSlot ~= nil and sourceSlot ~= targetSlot then
				hero:SwapItems(targetSlot, sourceSlot)
				changed = true
			end
		end
	end

	hero.xhs_reincarnation_inventory_restoring = nil
	return changed
end

function SendXHSReincarnationInventoryLockedError(hero)
	if hero == nil or hero:IsNull() or not hero.GetPlayerID then return end

	local playerID = hero:GetPlayerID()
	if playerID == nil or playerID < 0 then return end

	local now = GameRules:GetGameTime()
	if hero.xhs_reincarnation_inventory_lock_message_time == nil or hero.xhs_reincarnation_inventory_lock_message_time <= now then
		SendErrorMessage(playerID, "#error_reincarnation_inventory_locked")
		hero.xhs_reincarnation_inventory_lock_message_time = now + 0.75
	end
end

function StartXHSReincarnationInventoryLock(hero)
	if hero == nil or hero:IsNull() or not hero:IsRealHero() or not hero:IsOwnedByAnyPlayer() then return end

	SnapshotXHSReincarnationInventory(hero)

	local thinkName = "xhs_reincarnation_inventory_lock_" .. tostring(hero:entindex())
	hero.xhs_reincarnation_inventory_lock_think_name = thinkName

	GameRules:GetGameModeEntity():SetContextThink(thinkName, function()
		if hero == nil or hero:IsNull() then return nil end
		if not hero.IsXHSReincarnating or not hero:IsXHSReincarnating() then return nil end

		if RestoreXHSReincarnationInventory(hero) then
			SendXHSReincarnationInventoryLockedError(hero)
		end

		return 0.03
	end, 0)
end

function StopXHSReincarnationInventoryLock(hero)
	if hero == nil or hero:IsNull() then return end

	if hero.xhs_reincarnation_inventory_lock_think_name ~= nil then
		GameRules:GetGameModeEntity():SetContextThink(hero.xhs_reincarnation_inventory_lock_think_name, nil, 0)
		hero.xhs_reincarnation_inventory_lock_think_name = nil
	end

	ClearXHSReincarnationInventorySnapshot(hero)
end

function IsPlayerXHSReincarnating(playerID)
	playerID = tonumber(playerID)
	if playerID == nil or playerID < 0 then return false end

	if _G.XHS_REINCARNATING_PLAYERS ~= nil and _G.XHS_REINCARNATING_PLAYERS[playerID] == true then
		return true
	end

	local hero = nil
	if PlayerResource:IsValidPlayerID(playerID) and PlayerResource:HasSelectedHero(playerID) then
		hero = PlayerResource:GetSelectedHeroEntity(playerID)
	end

	if (hero == nil or hero:IsNull()) then
		local player = PlayerResource:GetPlayer(playerID)
		if player ~= nil then
			hero = player:GetAssignedHero()
		end
	end

	return hero ~= nil and not hero:IsNull() and hero.IsXHSReincarnating and hero:IsXHSReincarnating() == true
end

function GetBossBarColor(sBossName)
	local colors = {
		default = {
			light_color = "#009933",
			dark_color = "#003311"
		},
		npc_dota_hero_arthas = {
			light_color = "#e6ac00",
			dark_color = "#b34700"
		},
		npc_dota_hero_banehallow = {
			light_color = "#ff6600",
			dark_color = "#320000"
		},
		npc_dota_hero_grom_hellscream = {
			light_color = "#ffb13a",
			dark_color = "#4a0702"
		},
		npc_dota_hero_illidan = {
			light_color = "#77ff3d",
			dark_color = "#170039"
		},
		npc_dota_hero_balanar = {
			light_color = "#9b37ff",
			dark_color = "#160325"
		},
		npc_dota_hero_proudmoore = {
			light_color = "#46beff",
			dark_color = "#08243a"
		},
		npc_dota_boss_lich_king = {
			light_color = "#0047b3",
			dark_color = "#000d33"
		},
		npc_dota_boss_spirit_master = {
			light_color = "#33ccff",
			dark_color = "#001f33"
		},
		npc_dota_boss_spirit_master_storm = {
			light_color = "#48d9ff",
			dark_color = "#053f66"
		},
		npc_dota_boss_spirit_master_earth = {
			light_color = "#79d67b",
			dark_color = "#1f4d20"
		},
		npc_dota_boss_spirit_master_fire = {
			light_color = "#ff9a2f",
			dark_color = "#5a1300"
		}
	}

	return colors[sBossName] or colors.default
end

function GetBossBarIcon(sBossName)
	local icons = {
		npc_dota_hero_arthas = "npc_dota_hero_omniknight",
		npc_dota_hero_balanar = "spellicons/custom/xhs_balanar_vampiric_presence",
		npc_dota_hero_banehallow = "npc_dota_hero_nevermore",
		npc_dota_hero_grom_hellscream = "spellicons/custom/xhs_grom_mirror_trial",
		npc_dota_hero_illidan = "spellicons/custom/xhs_illidan_demon_hunter",
		npc_dota_hero_proudmoore = "spellicons/custom/xhs_proudmoore_admirals_command",
		npc_dota_boss_lich_king = "npc_dota_hero_abaddon",
		npc_dota_hero_magtheridon = "npc_dota_hero_abyssal_underlord",
		npc_dota_boss_spirit_master = "npc_dota_hero_brewmaster",
		npc_dota_boss_spirit_master_storm = "npc_dota_hero_storm_spirit",
		npc_dota_boss_spirit_master_fire = "npc_dota_hero_ember_spirit",
		npc_dota_boss_spirit_master_earth = "npc_dota_hero_earth_spirit",
	}

	return icons[sBossName] or sBossName
end

local XHS_BOSS_BAR_POLL_INTERVAL = 0.2
local XHS_BOSS_BAR_LAST = {}
local XHS_PRIVATE_BOSS_BAR_LAST = {}

local XHS_PRIVATE_BOSS_BAR_BOSSES = {
}

function IsPrivateBossBarBoss(boss)
	return boss ~= nil
		and IsValidEntity(boss)
		and not boss:IsNull()
		and XHS_PRIVATE_BOSS_BAR_BOSSES[boss:GetUnitName()] == true
end

local function GetBossBarStateKey(boss)
	if boss == nil or not IsValidEntity(boss) or boss:IsNull() then return nil end
	return tostring(boss:entindex())
end

function GetBossBarId(boss)
	if boss == nil or not IsValidEntity(boss) or boss:IsNull() then return nil end
	return boss.xhs_boss_bar_id or tostring(boss:entindex())
end

local function GetBossBarMarkers(boss)
	if boss == nil or not IsValidEntity(boss) or boss:IsNull() then return nil end
	if type(boss.xhs_boss_bar_markers) ~= "table" then return nil end

	return boss.xhs_boss_bar_markers
end

local function GetBossBarMarkersKey(boss)
	local markers = GetBossBarMarkers(boss)
	if markers == nil then return "" end

	local parts = {}
	for index = 1, #markers do
		local marker = markers[index]
		if marker ~= nil then
			local pct = marker.pct or marker.percent or marker.health_pct or ""
			local kind = marker.kind or ""
			local triggered = marker.triggered == true and "1" or "0"
			parts[#parts + 1] = tostring(index) .. ":" .. tostring(pct) .. ":" .. tostring(kind) .. ":" .. triggered
		end
	end

	return table.concat(parts, "|")
end

local function GetBossBarSnapshot(boss)
	return {
		health = boss:GetHealth(),
		max_health = boss:GetMaxHealth(),
		boss_count = boss.boss_count or 1,
		boss_bar_id = GetBossBarId(boss),
		ankh_count = GetBossBarAnkhCount(boss),
		markers_key = GetBossBarMarkersKey(boss),
	}
end

local function BossBarSnapshotChanged(previous, current)
	return previous == nil
		or previous.health ~= current.health
		or previous.max_health ~= current.max_health
		or previous.boss_count ~= current.boss_count
		or previous.boss_bar_id ~= current.boss_bar_id
		or previous.ankh_count ~= current.ankh_count
		or previous.markers_key ~= current.markers_key
end

local function GetBossBarPayload(boss)
	local unitName = boss.xhs_boss_bar_name or boss:GetUnitName()
	local icon = boss.xhs_boss_bar_icon or GetBossBarIcon(unitName)
	local colors = boss.xhs_boss_bar_colors or GetBossBarColor(unitName)

	return {
		boss_name = unitName,
		difficulty = GameRules:GetCustomGameDifficulty(),
		boss_icon = icon,
		light_color = colors.light_color,
		dark_color = colors.dark_color,
		boss_health = boss:GetHealth(),
		boss_max_health = boss:GetMaxHealth(),
		boss_count = boss.boss_count or 1,
		boss_bar_id = GetBossBarId(boss),
		ankh_count = GetBossBarAnkhCount(boss),
		boss_bar_markers = GetBossBarMarkers(boss),
	}
end

local function SendBossBarUpdateIfChanged(boss, force)
	local key = GetBossBarStateKey(boss)
	if key == nil then return end

	local snapshot = GetBossBarSnapshot(boss)
	if force ~= true and not BossBarSnapshotChanged(XHS_BOSS_BAR_LAST[key], snapshot) then
		return
	end

	XHS_BOSS_BAR_LAST[key] = snapshot
	CustomGameEventManager:Send_ServerToAllClients("update_boss_hp", GetBossBarPayload(boss))
end

local function SendPrivateBossBarUpdateIfChanged(boss, force)
	local key = GetBossBarStateKey(boss)
	if key == nil or boss.xhs_boss_bar_players == nil then return end

	local snapshot = GetBossBarSnapshot(boss)
	if force ~= true and not BossBarSnapshotChanged(XHS_PRIVATE_BOSS_BAR_LAST[key], snapshot) then
		return
	end

	XHS_PRIVATE_BOSS_BAR_LAST[key] = snapshot
	local payload = GetBossBarPayload(boss)

	for playerID, _ in pairs(boss.xhs_boss_bar_players) do
		local player = PlayerResource:GetPlayer(playerID)
		if player ~= nil then
			CustomGameEventManager:Send_ServerToPlayer(player, "update_boss_hp", payload)
		end
	end
end

local function StartBossBarHealthThink(boss)
	local key = GetBossBarStateKey(boss)
	if key == nil or boss.xhs_boss_bar_think_active == true then return end

	boss.xhs_boss_bar_think_active = true
	GameRules:GetGameModeEntity():SetContextThink("xhs_boss_bar_health_" .. key, function()
		if boss == nil or not IsValidEntity(boss) or boss:IsNull() or boss.deathStart == true then
			XHS_BOSS_BAR_LAST[key] = nil
			XHS_PRIVATE_BOSS_BAR_LAST[key] = nil
			return nil
		end

		if IsPrivateBossBarBoss(boss) then
			SendPrivateBossBarUpdateIfChanged(boss, false)
		else
			SendBossBarUpdateIfChanged(boss, false)
		end
		return XHS_BOSS_BAR_POLL_INTERVAL
	end, XHS_BOSS_BAR_POLL_INTERVAL)
end

local function GetBossBarPlayerIDFromAttacker(attacker)
	if attacker == nil or not IsValidEntity(attacker) or attacker:IsNull() then return nil end

	local playerID = attacker:GetPlayerOwnerID()
	if playerID ~= nil and playerID >= 0 then
		return playerID
	end

	if attacker.GetPlayerID ~= nil then
		playerID = attacker:GetPlayerID()
		if playerID ~= nil and playerID >= 0 then
			return playerID
		end
	end

	local playerOwner = attacker:GetPlayerOwner()
	if playerOwner ~= nil and playerOwner.GetPlayerID ~= nil then
		playerID = playerOwner:GetPlayerID()
		if playerID ~= nil and playerID >= 0 then
			return playerID
		end
	end

	return nil
end

local function ShowBossBarToPlayer(caster, playerID)
	if caster.deathStart or playerID == nil then return end

	if caster.boss_count == nil then caster.boss_count = 1 end
	local player = PlayerResource:GetPlayer(playerID)
	if player == nil then return end

	caster.xhs_boss_bar_players = caster.xhs_boss_bar_players or {}
	caster.xhs_boss_bar_players[playerID] = true

	local key = GetBossBarStateKey(caster)
	if key ~= nil then
		XHS_PRIVATE_BOSS_BAR_LAST[key] = GetBossBarSnapshot(caster)
	end

	CustomGameEventManager:Send_ServerToPlayer(player, "show_boss_hp", GetBossBarPayload(caster))
	StartBossBarHealthThink(caster)
end

function ShowBossBar(caster)
	if caster.deathStart then return end
	local boss_health = caster:FindAbilityByName("boss_health")
	if boss_health and boss_health:GetLevel() < 1 then
		boss_health:SetLevel(1)
	end
	if IsPrivateBossBarBoss(caster) then return end

	if caster.boss_count == nil then caster.boss_count = 1 end
	local key = GetBossBarStateKey(caster)
	if key ~= nil then
		XHS_BOSS_BAR_LAST[key] = GetBossBarSnapshot(caster)
	end

	CustomGameEventManager:Send_ServerToAllClients("show_boss_hp", GetBossBarPayload(caster))

	StartBossBarHealthThink(caster)
end

function GetBossBarAnkhCount(boss)
	if boss == nil or not IsValidEntity(boss) or boss:IsNull() then return nil end
	if boss:GetUnitName() ~= "npc_dota_hero_magtheridon" then return nil end

	local ankh_modifier = boss:FindModifierByName("modifier_ankh_passives")
	if ankh_modifier == nil then return 0 end

	return ankh_modifier:GetStackCount()
end

function UpdateBossBar(boss, attacker)
	if boss == nil or not IsValidEntity(boss) or boss:IsNull() then return end
	if boss.deathStart then return end
	if boss.boss_count == nil then boss.boss_count = 1 end

	if IsPrivateBossBarBoss(boss) then
		ShowBossBarToPlayer(boss, GetBossBarPlayerIDFromAttacker(attacker))
		SendPrivateBossBarUpdateIfChanged(boss, true)
	else
		SendBossBarUpdateIfChanged(boss, true)
	end
end

function HideBossBar(boss)
	if boss == nil or not IsValidEntity(boss) or boss:IsNull() then return end

	local payload = {
		boss_count = boss.boss_count,
		boss_bar_id = GetBossBarId and GetBossBarId(boss) or nil,
	}

	if IsPrivateBossBarBoss(boss) and boss.xhs_boss_bar_players ~= nil then
		for playerID, _ in pairs(boss.xhs_boss_bar_players) do
			local player = PlayerResource:GetPlayer(playerID)
			if player ~= nil then
				CustomGameEventManager:Send_ServerToPlayer(player, "hide_boss_hp", payload)
			end
		end
	else
		CustomGameEventManager:Send_ServerToAllClients("hide_boss_hp", payload)
	end

	local key = GetBossBarStateKey(boss)
	if key ~= nil then
		XHS_BOSS_BAR_LAST[key] = nil
		XHS_PRIVATE_BOSS_BAR_LAST[key] = nil
	end
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
	for _, hero in pairs(HeroList:GetAllHeroes()) do
		if hero:IsRealHero() and not hero:IsIllusion() then
			GrantTomeStatsToHero(hero, iCount)
		end
	end
end

function GetPlayerHeroFromUnit(unit)
	if unit == nil or unit:IsNull() then return nil end

	if unit:IsRealHero() and not unit:IsIllusion() then
		return unit
	end

	if unit.GetPlayerOwner then
		local owner = unit:GetPlayerOwner()
		if owner ~= nil and owner.GetAssignedHero then
			local hero = owner:GetAssignedHero()
			if hero ~= nil and not hero:IsNull() then
				return hero
			end
		end
	end

	if unit.GetPlayerOwnerID then
		local playerID = unit:GetPlayerOwnerID()
		if playerID ~= nil and playerID >= 0 then
			local hero = PlayerResource:GetSelectedHeroEntity(playerID)
			if hero ~= nil and not hero:IsNull() then
				return hero
			end
		end
	end

	return nil
end

function SendStatsGrantedNotification(hero, amount, title, text)
	if hero == nil or hero:IsNull() or not hero.GetPlayerOwnerID then return end

	local playerID = hero:GetPlayerOwnerID()
	local player = PlayerResource:GetPlayer(playerID)
	if player == nil then return end

	CustomGameEventManager:Send_ServerToPlayer(player, "xhs_reward_notification", {
		type = "stats",
		amount = amount,
		title = title or "Tome Granted",
		text = text or ("+" .. amount .. " all stats"),
		duration = 2.6,
	})
end

function GrantTomeStatsToHero(unit, amount, title, text)
	local hero = GetPlayerHeroFromUnit(unit)
	if hero == nil then return nil end

	hero:IncrementAttributes(amount)
	SendStatsGrantedNotification(hero, amount, title, text)

	return hero
end

function WinGame()
	GameRules:SetGameWinner(2)
end

function MapDemo()
	return GetMapName() == "x_hero_siege_demo"
end

function XHSGetPlayerIDFromUnit(unit)
	if unit == nil or unit:IsNull() then return nil end
	local playerID = -1

	if unit.xhs_player_id ~= nil then
		playerID = tonumber(unit.xhs_player_id) or -1
	end

	if unit.GetPlayerID then
		if playerID == nil or playerID < 0 then
			playerID = unit:GetPlayerID()
		end
	end

	if (playerID == nil or playerID < 0) and unit.GetPlayerOwnerID then
		playerID = unit:GetPlayerOwnerID()
	end

	if (playerID == nil or playerID < 0) and unit.GetPlayerOwner then
		local player = unit:GetPlayerOwner()
		if player ~= nil and player.GetPlayerID then
			playerID = player:GetPlayerID()
		end
	end

	if (playerID == nil or playerID < 0) and PlayerResource ~= nil then
		for id = 0, PlayerResource:GetPlayerCount() - 1 do
			if PlayerResource:IsValidPlayerID(id) then
				local selectedHero = PlayerResource:GetSelectedHeroEntity(id)
				if selectedHero ~= nil and not selectedHero:IsNull() and selectedHero == unit then
					playerID = id
					break
				end

				local player = PlayerResource:GetPlayer(id)
				local assignedHero = player ~= nil and player:GetAssignedHero() or nil
				if assignedHero ~= nil and not assignedHero:IsNull() and assignedHero == unit then
					playerID = id
					break
				end
			end
		end
	end

	if playerID == nil or playerID < 0 or not PlayerResource:IsValidPlayerID(playerID) then
		return nil
	end

	return playerID
end

function XHSRecordTomeStats(unit, amount)
	local playerID = XHSGetPlayerIDFromUnit(unit)
	amount = tonumber(amount) or 0

	if playerID == nil or amount <= 0 then
		return 0
	end

	_G.XHS_TOME_STATS = _G.XHS_TOME_STATS or {}
	_G.XHS_TOME_STATS[playerID] = (_G.XHS_TOME_STATS[playerID] or 0) + amount

	return _G.XHS_TOME_STATS[playerID]
end

function XHSGetTomeStats(playerID)
	if playerID == nil then return 0 end

	_G.XHS_TOME_STATS = _G.XHS_TOME_STATS or {}
	return tonumber(_G.XHS_TOME_STATS[playerID]) or 0
end

function XHSRecordPotionUse(caster)
	local playerID = XHSGetPlayerIDFromUnit(caster)

	if playerID == nil then return 0 end

	_G.XHS_POTION_USES = _G.XHS_POTION_USES or {}
	_G.XHS_POTION_USES[playerID] = (_G.XHS_POTION_USES[playerID] or 0) + 1

	if FragmentQuests ~= nil then
		FragmentQuests:OnPotionUsed(caster)
	end

	if ZONE_STAT_POTIONS ~= nil and GameRules.GameMode ~= nil and GameRules.GameMode.Zones ~= nil then
		for _, Zone in pairs(GameRules.GameMode.Zones) do
			if Zone ~= nil and Zone.ContainsUnit ~= nil and Zone:ContainsUnit(caster) then
				Zone:AddStat(playerID, ZONE_STAT_POTIONS, 1)
			end
		end
	end

	return _G.XHS_POTION_USES[playerID]
end

function XHSGetPotionUses(playerID)
	if playerID == nil then return 0 end

	_G.XHS_POTION_USES = _G.XHS_POTION_USES or {}
	return tonumber(_G.XHS_POTION_USES[playerID]) or 0
end

local function XHSEnsurePermanentTownPortalScroll(hero)
	if not hero or hero:IsNull() then return end

	local tpScroll = nil
	for itemSlot = 0, 16 do
		local item = hero:GetItemInSlot(itemSlot)
		if item and item:GetName() == "item_tpscroll" then
			tpScroll = item
			break
		end
	end

	if not tpScroll then
		tpScroll = hero:AddItemByName("item_tpscroll")
	end

	if tpScroll then
		tpScroll:SetCurrentCharges(1000)
		tpScroll:SetPurchaseTime(0)
	end
end

function StartingItems(hero, newHero)
	local difficulty = GameRules:GetCustomGameDifficulty()

	XHSEnsurePermanentTownPortalScroll(newHero)

	if difficulty ~= 5 then
		newHero:AddNewModifier(newHero, nil, "modifier_ankh", { charges = 5 - difficulty })

		local item = newHero:AddItemByName("item_health_potion")
		item:SetPurchaseTime(0)

		local item = newHero:AddItemByName("item_mana_potion")
		item:SetPurchaseTime(0)

		if difficulty == 1 then
			local item = newHero:AddItemByName("item_lifesteal_mask")
			item:SetSellable(false)
		end
	end

	if newHero:GetTeamNumber() == 2 then
		TeleportHero(newHero, BASE_GOOD:GetAbsOrigin(), 3.0)
		-- elseif newHero:GetTeamNumber() == 3 then
		-- TeleportHero(newHero, base_bad:GetAbsOrigin(), 3.0)
	end

	Timers:CreateTimer(0.1, function()
		if not hero:IsNull() then
			UTIL_Remove(hero)
		end
	end)

	Timers:CreateTimer(1.0, function()
		for k, v in pairs(HeroList:GetAllHeroes()) do
			if v and IsValidEntity(v) and not v:IsNull() and v:GetUnitName() == "npc_dota_hero_wisp" then
				-- print("A wisp was found! Players are still picking a hero")
				return
			end
		end

		-- all players selected a hero, remove pick screen to reduce lag
		-- print("All players selected a hero, remove pick screen")
		for k, v in pairs(HeroList:GetAllHeroes()) do
			if v and IsValidEntity(v) and not v:IsNull() and v.is_fake_hero then
				UTIL_Remove(v)
			end
		end
	end)
end
