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

-- ReleaseParticleIndex only releases the Lua handle; it does not stop a
-- looping particle system. Seasonal cosmetic particles are not guaranteed to
-- terminate on their own, so transient effects must always have an explicit
-- lifetime to avoid accumulating client-side particle simulations.
function XHSDestroyParticleAfter(particle, duration, immediate)
	if particle == nil then return end

	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("xhs_transient_particle"), function()
		ParticleManager:DestroyParticle(particle, immediate == true)
		ParticleManager:ReleaseParticleIndex(particle)
		return nil
	end, math.max(FrameTime(), tonumber(duration) or 5.0))
end

local XHS_BASE_SPAWN_LOCAL_OFFSETS = {
	[0] = Vector(-180, -120, 0),
	[1] = Vector(180, -120, 0),
	[2] = Vector(-180, 120, 0),
	[3] = Vector(180, 120, 0),
	[4] = Vector(-360, -120, 0),
	[5] = Vector(360, -120, 0),
	[6] = Vector(-360, 120, 0),
	[7] = Vector(360, 120, 0),
}

function XHSGetPlayerBaseSpawnPosition(playerID, base)
	base = base or BASE_GOOD or Entities:FindByName(nil, "base_spawn")
	if base == nil or not IsValidEntity(base) or base:IsNull() then return nil end

	playerID = math.max(0, tonumber(playerID) or 0)
	local localOffset = XHS_BASE_SPAWN_LOCAL_OFFSETS[playerID]
	if localOffset == nil then
		local extraIndex = playerID - 8
		local side = extraIndex % 2 == 0 and -1 or 1
		local row = math.floor(extraIndex / 2)
		localOffset = Vector(side * (540 + row * 150), 0, 0)
	end

	local angles = base:GetAnglesAsVector()
	local yaw = math.rad(angles.y)
	local forward = Vector(math.cos(yaw), math.sin(yaw), 0)
	local right = Vector(-math.sin(yaw), math.cos(yaw), 0)
	local position = base:GetAbsOrigin() + right * localOffset.x + forward * localOffset.y

	if GetGroundPosition ~= nil then
		position = GetGroundPosition(position, base)
	end
	return position
end

function XHSSetPlayerBaseRespawnPosition(hero, base)
	if hero == nil or not IsValidEntity(hero) or hero:IsNull() then return nil end

	local position = XHSGetPlayerBaseSpawnPosition(hero:GetPlayerID(), base)
	if position == nil then return nil end

	hero:SetRespawnPosition(position)
	hero.xhs_base_respawn_position = position
	return position
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

local function GetDoorCinematicCenter(doorNames)
	local center = Vector(0, 0, 0)
	local count = 0

	for _, doorName in ipairs(doorNames or {}) do
		for _, door in ipairs(Entities:FindAllByName(doorName)) do
			if door ~= nil and IsValidEntity(door) then
				center = center + door:GetAbsOrigin()
				count = count + 1
			end
		end
	end

	if count == 0 then return nil end
	return center / count
end

-- Moves every active player's camera to a door group, executes the opening once
-- the camera has arrived, then smoothly returns each player to their own hero.
function XHSPlayDoorOpeningCinematic(doorNames, onCameraArrived, options)
	options = options or {}
	local target = options.camera_position or GetDoorCinematicCenter(doorNames)
	if target == nil then
		if onCameraArrived ~= nil then onCameraArrived() end
		return
	end

	local moveDuration = tonumber(options.move_duration) or 1.25
	local holdDuration = tonumber(options.hold_duration) or 1.15
	local returnDuration = tonumber(options.return_duration) or 1.0
	local maxPlayers = DOTA_MAX_TEAM_PLAYERS or 24

	_G.XHSDoorCinematicSerial = (_G.XHSDoorCinematicSerial or 0) + 1
	local serial = _G.XHSDoorCinematicSerial
	local cinematicId = "xhs_door_camera_" .. tostring(serial)
	if XHSCinematics == nil then
		if onCameraArrived ~= nil then onCameraArrived() end
		return
	end
	if _G.XHSDoorCinematicId ~= nil then
		XHSCinematics:EndForAll(_G.XHSDoorCinematicId)
	end
	_G.XHSDoorCinematicId = cinematicId

	local expectedPlayers = 0
	for playerID = 0, maxPlayers - 1 do
		if PlayerResource:IsValidPlayerID(playerID) and PlayerResource:GetPlayer(playerID) ~= nil then
			expectedPlayers = expectedPlayers + 1
		end
	end
	local arrivedPlayers = 0
	local arrivalHandled = false
	local function OnAllCamerasArrived()
		if arrivalHandled then return end
		arrivedPlayers = arrivedPlayers + 1
		if arrivedPlayers < math.max(1, expectedPlayers) then return end
		arrivalHandled = true
		if serial ~= _G.XHSDoorCinematicSerial then return end
		if onCameraArrived ~= nil then onCameraArrived() end

		Timers:CreateTimer(holdDuration, function()
			if serial ~= _G.XHSDoorCinematicSerial then return end
			XHSCinematics:EndForAll(cinematicId)
			if _G.XHSDoorCinematicId == cinematicId then
				_G.XHSDoorCinematicId = nil
			end
		end)
	end

	XHSCinematics:BeginForAll(cinematicId, {
		duration = 0,
		hide_hud = false,
		hide_health_bars = true,
		lock_orders = false,
		camera_position = target,
		camera_speed = moveDuration,
		return_camera_speed = returnDuration,
		return_camera = options.return_camera ~= false,
		on_camera_arrive = OnAllCamerasArrived,
		letterbox_pct = 0,
		transition = 0.1,
	})
	if expectedPlayers == 0 then OnAllCamerasArrived() end
end

function XHSOpenDoorsWithCinematic(doorNames, obstructionNames, animationName, onOpened, options)
	XHSPlayDoorOpeningCinematic(doorNames, function()
		for _, doorName in ipairs(doorNames or {}) do
			DoEntFire(doorName, "SetAnimation", animationName or "gate_02_open", 0, nil, nil)
		end

		for _, obstructionName in ipairs(obstructionNames or {}) do
			for _, obstruction in ipairs(Entities:FindAllByName(obstructionName)) do
				obstruction:SetEnabled(false, true)
			end
		end

		if onOpened ~= nil then onOpened() end
	end, options)
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
	return itemName ~= nil and XHS_TOME_ITEM_NAMES[tostring(itemName)] == true
end

local XHS_TOME_STAT_VALUES = {
	item_tome_small = 50,
	item_tome_big = 250,
}

local XHS_POTION_ITEM_NAMES = {
	item_health_potion = true,
	item_mana_potion = true,
	item_potion_full = true,
	item_potion_of_invulnerability = true,
	item_potion_of_antimagic = true,
}

function XHSGetTomeStatValue(itemName)
	if itemName == nil then return 0 end

	return tonumber(XHS_TOME_STAT_VALUES[tostring(itemName)]) or 0
end

function XHSIsPotionItemName(itemName)
	return itemName ~= nil and XHS_POTION_ITEM_NAMES[tostring(itemName)] == true
end

local XHS_TOME_OPTIONAL_EVENT_LOCK_REASONS = {
	hero_image = "#xhs_tome_lock_hero_image",
	all_hero_images = "#xhs_tome_lock_all_hero_images",
	spirit_beast = "#xhs_tome_lock_spirit_beast",
	frost_infernal = "#xhs_tome_lock_frost_infernal",
}

function XHSGetTomePurchaseLockReason(playerID)
	if playerID == nil or playerID < 0 or not PlayerResource:IsValidPlayerID(playerID) then
		return nil
	end

	if GameRules:IsGamePaused() then
		return "#xhs_tome_lock_paused"
	end

	if IsPlayerXHSReincarnating ~= nil and IsPlayerXHSReincarnating(playerID) then
		return "#xhs_tome_lock_reincarnating"
	end

	local player = PlayerResource:GetPlayer(playerID)
	local hero = PlayerResource:GetSelectedHeroEntity(playerID)
		or (player ~= nil and player:GetAssignedHero() or nil)
	if hero ~= nil and not hero:IsNull() and hero.xhs_optional_event_tome_locked == true then
		return XHS_TOME_OPTIONAL_EVENT_LOCK_REASONS[hero.xhs_optional_event_tome_lock_name]
			or "#xhs_tome_lock_optional_event"
	end

	if GameMode ~= nil and GameMode.Muradin_occuring == true then
		return "#xhs_tome_lock_muradin"
	end

	if GameMode ~= nil and GameMode.SpecialArena_occuring == true then
		if SpecialEvents ~= nil and SpecialEvents.Ramero_trigger == 1 then
			return "#xhs_tome_lock_ramero"
		elseif SpecialEvents ~= nil and SpecialEvents.Ramero_trigger == 2 then
			return "#xhs_tome_lock_sogat"
		end
		return "#xhs_tome_lock_special_arena"
	end

	if BT_ENABLED == 0 then
		return "#xhs_tome_lock_temporarily_disabled"
	end

	return nil
end

function XHSPublishTomePurchaseStatus(playerID)
	if CustomNetTables == nil or playerID == nil or playerID < 0
		or not PlayerResource:IsValidPlayerID(playerID) then
		return
	end

	local reason = XHSGetTomePurchaseLockReason(playerID)
	local autoBuyEnabled = GameMode ~= nil
		and GameMode.XHSTomeAutoBuyPlayers ~= nil
		and GameMode.XHSTomeAutoBuyPlayers[playerID] == true
	local signature = (reason or "") .. "|" .. (autoBuyEnabled and "1" or "0")
	_G.XHSTomePurchaseStatusCache = _G.XHSTomePurchaseStatusCache or {}
	if _G.XHSTomePurchaseStatusCache[playerID] == signature then
		return
	end

	_G.XHSTomePurchaseStatusCache[playerID] = signature
	CustomNetTables:SetTableValue("xhs_tome_purchase", tostring(playerID), {
		locked = reason ~= nil and 1 or 0,
		reason = reason or "",
		auto_buy = autoBuyEnabled and 1 or 0,
	})
end

function XHSIsTomeAutoBuyEnabled(playerID)
	return GameMode ~= nil
		and GameMode.XHSTomeAutoBuyPlayers ~= nil
		and GameMode.XHSTomeAutoBuyPlayers[playerID] == true
end

function XHSSetTomeAutoBuyEnabled(playerID, enabled)
	if playerID == nil or playerID < 0 or not PlayerResource:IsValidPlayerID(playerID) then
		return false
	end

	GameMode.XHSTomeAutoBuyPlayers = GameMode.XHSTomeAutoBuyPlayers or {}
	GameMode.XHSTomeAutoBuyPlayers[playerID] = enabled == true
	XHSPublishTomePurchaseStatus(playerID)
	return GameMode.XHSTomeAutoBuyPlayers[playerID]
end

function XHSPublishAllTomePurchaseStatuses()
	local maxPlayers = DOTA_MAX_TEAM_PLAYERS or 24
	for playerID = 0, maxPlayers - 1 do
		if PlayerResource:IsValidPlayerID(playerID) then
			XHSPublishTomePurchaseStatus(playerID)
		end
	end
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

	local playerID = hero:GetPlayerID()
	if playerID ~= nil and playerID >= 0 then
		XHSPublishTomePurchaseStatus(playerID)
	end
end

function IsHeroOptionalEventTomeLocked(hero)
	return hero ~= nil and not hero:IsNull() and hero.xhs_optional_event_tome_locked == true
end

function IsTomePurchaseGloballyLocked()
	if GameMode ~= nil and GameMode.FarmEvent_occuring == true then
		return false
	end
	return BT_ENABLED == 0
		or GameMode.Muradin_occuring == true
		or GameMode.SpecialArena_occuring == true
end

function BuyMaxSmallTomesForPlayer(playerID, options)
	if playerID == nil or playerID < 0 or not PlayerResource:IsValidPlayerID(playerID) then return 0 end

	options = options or {}
	local suppressErrors = options.suppress_errors == true
	local silent = options.silent == true
	local function SendPurchaseError(message)
		if not suppressErrors then
			SendErrorMessage(playerID, message)
		end
	end

	local player = PlayerResource:GetPlayer(playerID)
	if player == nil then return 0 end

	if GameRules:IsGamePaused() then
		SendPurchaseError("#error_buy_tome_pause")
		return 0
	end

	local hero = PlayerResource:GetSelectedHeroEntity(playerID) or player:GetAssignedHero()
	if hero == nil or hero:IsNull() then return 0 end

	if IsPlayerXHSReincarnating(playerID) then
		SendPurchaseError("#error_reincarnation_inventory_locked")
		return 0
	end

	if IsHeroOptionalEventTomeLocked(hero) or IsTomePurchaseGloballyLocked() then
		SendPurchaseError("#error_buy_tome_disabled")
		return 0
	end

	local cost = 10000
	local numberOfTomes = math.floor(Gold:GetGold(playerID) / cost)
	if numberOfTomes < 1 then
		SendPurchaseError("#error_cant_afford_tomes")
		return 0
	end

	Notifications:Bottom(player, { text = "You've bought " .. numberOfTomes .. " Tomes!", duration = 5.0, style = { color = "white" } })
	PlayerResource:SpendGold(playerID, numberOfTomes * cost, DOTA_ModifyGold_PurchaseItem)

	if XHSRecordTomeStatsForPlayer ~= nil then
		XHSRecordTomeStatsForPlayer(playerID, numberOfTomes * 50)
	end

	-- A bulk purchase used to create two seasonal level-up particles per tome,
	-- ten times per second. Some Valve event particles keep emitting star trails
	-- until explicitly stopped, so a large purchase could leave hundreds of
	-- expensive simulations attached to the hero. Celebrate the transaction
	-- once and keep the stat increments silent/particle-free.
	local levelupParticle = XHSGetBattlepassParticle ~= nil
		and XHSGetBattlepassParticle(hero, "levelup_pfx", "particles/generic_hero_status/hero_levelup.vpcf")
		or "particles/generic_hero_status/hero_levelup.vpcf"
	local pfx = ParticleManager:CreateParticle(levelupParticle, PATTACH_ABSORIGIN_FOLLOW, hero)
	ParticleManager:SetParticleControl(pfx, 0, hero:GetAbsOrigin())
	XHSDestroyParticleAfter(pfx, 1.5, false)
	if not silent then
		hero:EmitSound("ui.trophy_levelup")
	end

	local i = 0
	GameRules:GetGameModeEntity():SetContextThink(DoUniqueString("XHSBuyTomes"), function()
		if hero == nil or hero:IsNull() then return nil end

		hero:IncrementAttributes(50, {
			record_stats = false,
			play_sound = false,
			play_effect = false,
		})

		i = i + 1
		if i >= numberOfTomes then
			return nil
		end
		return 0.1
	end, FrameTime())

	return numberOfTomes
end

function XHSProcessAutoTomePurchases()
	if GameMode == nil or GameMode.XHSTomeAutoBuyPlayers == nil or GameRules:IsGamePaused() then
		return
	end

	for playerID, enabled in pairs(GameMode.XHSTomeAutoBuyPlayers) do
		if enabled == true
			and PlayerResource:IsValidPlayerID(playerID)
			and XHSGetTomePurchaseLockReason(playerID) == nil
			and Gold:GetGold(playerID) >= 10000 then
			BuyMaxSmallTomesForPlayer(playerID, {
				silent = true,
				suppress_errors = true,
			})
		end
	end
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
	if IsInToolsMode() then
		OpenCreepLane(lane_number)
		return
	end

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
	if IsInToolsMode() then
		CloseCreepLane(lane_number)
		return
	end

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

function RespawnDeadHeroesForPhase3Start()
	local respawnedCount = 0
	_G.XHS_REINCARNATING_PLAYERS = _G.XHS_REINCARNATING_PLAYERS or {}

	for nPlayerID = 0, PlayerResource:GetPlayerCount() - 1 do
		if PlayerResource:HasSelectedHero(nPlayerID) then
			local hero = PlayerResource:GetSelectedHeroEntity(nPlayerID)

			if hero ~= nil and not hero:IsNull() and hero:GetTeamNumber() == DOTA_TEAM_GOODGUYS and not hero:IsAlive() then
				local playerID = hero:GetPlayerID()

				if hero.respawn_timer ~= nil and Timers ~= nil then
					Timers:RemoveTimer(hero.respawn_timer)
					hero.respawn_timer = nil
				end

				local ankhModifier = hero:FindModifierByName("modifier_ankh_passives")
				if ankhModifier ~= nil then
					ankhModifier:StartIntervalThink(-1)
				end

				hero.ankh_respawn = false
				_G.XHS_REINCARNATING_PLAYERS[playerID] = nil
				CustomNetTables:SetTableValue("player_table", tostring(hero:entindex()).."_reincarnation", {
					active = 0,
					duration = 0,
					end_time = 0,
				})
				if StopXHSReincarnationInventoryLock ~= nil then
					StopXHSReincarnationInventoryLock(hero)
				end

				hero:SetRespawnsDisabled(false)
				hero:RespawnHero(false, false)
				hero:SetHealth(hero:GetMaxHealth())
				hero:SetMana(hero:GetMaxMana())
				respawnedCount = respawnedCount + 1
			end
		end
	end

	return respawnedCount
end

local XHS_RETURN_MARKER_PARTICLE = "particles/units/heroes/hero_wisp/wisp_relocate_marker.vpcf"

local function XHSHexToRgbVector(value)
	if type(value) ~= "string" then return nil end

	local hex = string.gsub(value, "#", "")
	if string.len(hex) ~= 6 then return nil end

	local r = tonumber(string.sub(hex, 1, 2), 16)
	local g = tonumber(string.sub(hex, 3, 4), 16)
	local b = tonumber(string.sub(hex, 5, 6), 16)
	if r == nil or g == nil or b == nil then return nil end

	return Vector(r, g, b)
end

local function XHSGetHeroPlayerColorVector(hero)
	if hero == nil or hero:IsNull() or not hero.GetPlayerID then return Vector(255, 255, 255) end

	local player_id = hero:GetPlayerID()
	local color = PLAYER_COLORS and PLAYER_COLORS[player_id]
	if type(color) == "table" then
		if type(color[1]) == "number" and type(color[2]) == "number" and type(color[3]) == "number" then
			return Vector(color[1], color[2], color[3])
		end

		if type(color.r) == "number" and type(color.g) == "number" and type(color.b) == "number" then
			return Vector(color.r, color.g, color.b)
		end
	elseif type(color) == "string" then
		return XHSHexToRgbVector(color) or Vector(255, 255, 255)
	end

	return Vector(255, 255, 255)
end

function DestroyXHSReturnMarker(hero)
	if hero == nil or hero:IsNull() or hero.xhs_return_marker_pfx == nil then return end

	ParticleManager:DestroyParticle(hero.xhs_return_marker_pfx, false)
	ParticleManager:ReleaseParticleIndex(hero.xhs_return_marker_pfx)
	hero.xhs_return_marker_pfx = nil
	hero.xhs_return_marker_position = nil
end

function ClearXHSReturnMarker(hero)
	if hero == nil or hero:IsNull() then return end

	DestroyXHSReturnMarker(hero)
	hero.old_pos = nil
end

function CreateXHSReturnMarker(hero, position)
	if hero == nil or hero:IsNull() or position == nil then return end

	DestroyXHSReturnMarker(hero)

	local marker_position = GetGroundPosition(position, hero)
	local marker = ParticleManager:CreateParticle(XHS_RETURN_MARKER_PARTICLE, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(marker, 0, marker_position)
	ParticleManager:SetParticleControl(marker, 60, XHSGetHeroPlayerColorVector(hero))
	ParticleManager:SetParticleControl(marker, 61, Vector(1, 0, 0))

	hero.xhs_return_marker_pfx = marker
	hero.xhs_return_marker_position = marker_position
end

local XHS_TELEPORT_MIN_ANIMATION_DURATION = 0.65
-- The removed Panorama camera handler used 2.0 whenever callers
-- omitted iCameraSpeed. Preserve that public TeleportHero contract: dozens of
-- legacy two/three-argument calls intentionally rely on the default travelling
-- camera rather than an instant snap.
local XHS_TELEPORT_DEFAULT_CAMERA_DURATION = 2.0

function TeleportHero(hero, point, delay, iCameraSpeed)
	if hero == nil or not IsValidEntity(hero) or hero:IsNull() or point == nil then return end
	local playerID = hero.GetPlayerID ~= nil and hero:GetPlayerID() or -1
	if delay == nil then delay = 0 end
	local pos = hero:GetAbsOrigin()
	--	local pos = hero:GetAbsOrigin() + RandomVector(400)

	StartAnimation(hero, {
		duration = math.max(delay, XHS_TELEPORT_MIN_ANIMATION_DURATION),
		activity = ACT_DOTA_TELEPORT,
		rate = 1.0,
	})

	local TeleportEffect
	local TeleportEffectEnd

	if delay > 0 then
		-- Reveal the Lua teleport destination only for the duration of the
		-- teleport. Arena entrances and returns can therefore be understood
		-- without leaving permanent vision behind.
		AddFOWViewer(hero:GetTeamNumber(), point, 400, delay, false)

		local teleportStartParticle = XHSGetBattlepassParticle ~= nil
			and XHSGetBattlepassParticle(hero, "teleport_start_pfx", "particles/items2_fx/teleport_start.vpcf")
			or "particles/items2_fx/teleport_start.vpcf"
		local teleportEndParticle = XHSGetBattlepassParticle ~= nil
			and XHSGetBattlepassParticle(hero, "teleport_end_pfx", "particles/items2_fx/teleport_end.vpcf")
			or "particles/items2_fx/teleport_end.vpcf"

		TeleportEffect = ParticleManager:CreateParticle(teleportStartParticle, PATTACH_ABSORIGIN, hero)
		ParticleManager:SetParticleControlEnt(TeleportEffect, 0, hero, PATTACH_ABSORIGIN, "attach_origin", pos, true)
		hero:Attribute_SetIntValue("effectsID", TeleportEffect)

		TeleportEffectEnd = ParticleManager:CreateParticle(teleportEndParticle, PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(TeleportEffectEnd, 0, point)
		ParticleManager:SetParticleControl(TeleportEffectEnd, 1, point)

		hero:EmitSound("Portal.Loop_Appear")
	end

	hero:AddNewModifier(hero, nil, "modifier_command_restricted", {})

	-- An unassigned hero (notably `-createhero wisp`) still needs the gameplay
	-- teleport and the final modifier cleanup. It simply has no player camera
	-- to animate.
	if playerID ~= nil and playerID >= 0 and CameraMotion ~= nil then
		local cameraDuration = tonumber(iCameraSpeed)
		if cameraDuration == nil then
			cameraDuration = XHS_TELEPORT_DEFAULT_CAMERA_DURATION
		end
		CameraMotion:Move(playerID, point, {
			from = hero,
			duration = cameraDuration,
			easing = "smootherstep",
			owner = "hero_teleport",
			priority = 30,
			policy = "replace",
			release = "free",
		})
	end

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

		if hero:GetUnitName() == "npc_dota_hero_wisp" then
			local wisp_passive = hero:FindModifierByName("modifier_wisp_passive")
			if wisp_passive ~= nil then
				wisp_passive:SetStackCount(1)
			end
		end

		local return_position = hero.xhs_return_marker_position or hero.old_pos
		if return_position ~= nil and (point - return_position):Length2D() <= 128 then
			ClearXHSReturnMarker(hero)
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
		and (XHS_PRIVATE_BOSS_BAR_BOSSES[boss:GetUnitName()] == true or boss.xhs_boss_bar_players ~= nil)
end

local function GetBossBarStateKey(boss)
	if boss == nil or not IsValidEntity(boss) or boss:IsNull() then return nil end
	return tostring(boss:entindex())
end

function GetBossBarId(boss)
	if boss == nil or not IsValidEntity(boss) or boss:IsNull() then return nil end
	return boss.xhs_boss_bar_id or tostring(boss:entindex())
end

function IsBossBarSuppressed(boss)
	return boss ~= nil and IsValidEntity(boss) and not boss:IsNull() and boss.xhs_boss_bar_suppressed == true
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
		if IsBossBarSuppressed(boss) then
			return XHS_BOSS_BAR_POLL_INTERVAL
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
	if IsBossBarSuppressed(caster) then return end

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

function ShowPrivateBossBar(caster, playerID)
	ShowBossBarToPlayer(caster, playerID)
end

function HideBossBarForPlayer(boss, playerID)
	if boss == nil or not IsValidEntity(boss) or boss:IsNull() or playerID == nil then return end

	local player = PlayerResource:GetPlayer(playerID)
	if player == nil then return end

	CustomGameEventManager:Send_ServerToPlayer(player, "hide_boss_hp", {
		boss_count = boss.boss_count,
		boss_bar_id = GetBossBarId and GetBossBarId(boss) or nil,
	})

	if boss.xhs_boss_bar_players ~= nil then
		boss.xhs_boss_bar_players[playerID] = nil
	end
end

function ShowBossBar(caster)
	if caster.deathStart then return end
	if IsBossBarSuppressed(caster) then return end
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
	if IsBossBarSuppressed(boss) then return end
	if boss.boss_count == nil then boss.boss_count = 1 end

	if IsPrivateBossBarBoss(boss) then
		if boss.xhs_boss_bar_lock_to_registered ~= true then
			ShowBossBarToPlayer(boss, GetBossBarPlayerIDFromAttacker(attacker))
		end
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
	local heroes = {}
	for _, hero in pairs(HeroList:GetAllHeroes()) do
		if hero:IsRealHero()
			and not hero:IsIllusion()
			and hero:GetTeam() == DOTA_TEAM_GOODGUYS
			and hero:GetPlayerID() >= 0 then
			table.insert(heroes, hero)
		end
	end

	table.sort(heroes, function(left, right)
		return left:GetPlayerID() < right:GetPlayerID()
	end)

	local prefix = tostring(sEvent or "")
	local points = {}
	local maxPlayers = DOTA_MAX_TEAM_PLAYERS or 24
	for index = 0, maxPlayers - 1 do
		local point = Entities:FindByName(nil, prefix .. tostring(index))
		if point ~= nil and not point:IsNull() then
			points[index] = point
		end
	end

	local assignments = {}
	local usedPoints = {}
	for _, hero in ipairs(heroes) do
		local playerID = hero:GetPlayerID()
		if points[playerID] ~= nil then
			assignments[hero:entindex()] = points[playerID]
			usedPoints[playerID] = true
		end
	end

	for _, hero in ipairs(heroes) do
		if assignments[hero:entindex()] == nil then
			for index = 0, maxPlayers - 1 do
				if points[index] ~= nil and usedPoints[index] ~= true then
					assignments[hero:entindex()] = points[index]
					usedPoints[index] = true
					break
				end
			end
		end
	end

	for _, hero in ipairs(heroes) do
		local point = assignments[hero:entindex()]
		local ok, message = pcall(function()
			if point ~= nil then
				TeleportHero(hero, point:GetAbsOrigin(), iTPDelay)
			else
				print(string.format(
					"[XHS TeleportAllHeroes] No destination for player %d with prefix '%s'; continuing encounter.",
					hero:GetPlayerID(),
					prefix
				))
			end
			hero:AddNewModifier(hero, nil, "modifier_pause_creeps", { duration = iInvulnDelay, IsHidden = true })
			hero:AddNewModifier(hero, nil, "modifier_invulnerable", { duration = iInvulnDelay, IsHidden = true })
		end)
		if not ok then
			print(string.format(
				"[XHS TeleportAllHeroes] Player %d teleport failed: %s",
				hero:GetPlayerID(),
				tostring(message)
			))
		end
	end
end

function GiveTomeToAllHeroes(iCount)
	local granted = false

	for _, hero in pairs(HeroList:GetAllHeroes()) do
		if hero:IsRealHero() and not hero:IsIllusion() then
			if GrantTomeStatsToHero(hero, iCount, nil, nil, { play_sound = false }) ~= nil then
				granted = true
			end
		end
	end

	if granted == true then
		EmitGlobalSound("ui.trophy_levelup")
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

function GrantTomeStatsToHero(unit, amount, title, text, options)
	local hero = GetPlayerHeroFromUnit(unit)
	if hero == nil then return nil end

	hero:IncrementAttributes(amount, options)
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

function XHSRecordTomeStatsForPlayer(playerID, amount)
	playerID = tonumber(playerID)
	amount = tonumber(amount) or 0

	if playerID == nil or playerID < 0 or not PlayerResource:IsValidPlayerID(playerID) or amount <= 0 then
		return 0
	end

	_G.XHS_TOME_STATS = _G.XHS_TOME_STATS or {}
	_G.XHS_TOME_STATS[playerID] = (_G.XHS_TOME_STATS[playerID] or 0) + amount

	if XHSRecordEndScreenStat ~= nil then
		XHSRecordEndScreenStat(playerID, "tome_stats_bonus", amount)
	end

	return _G.XHS_TOME_STATS[playerID]
end

function XHSRecordTomeStats(unit, amount)
	return XHSRecordTomeStatsForPlayer(XHSGetPlayerIDFromUnit(unit), amount)
end

function XHSGetTomeStats(playerID)
	if playerID == nil then return 0 end

	_G.XHS_TOME_STATS = _G.XHS_TOME_STATS or {}
	return tonumber(_G.XHS_TOME_STATS[playerID]) or 0
end

function XHSRecordPotionUseForPlayer(playerID, caster, itemName)
	playerID = tonumber(playerID)

	if playerID == nil or playerID < 0 or not PlayerResource:IsValidPlayerID(playerID) then return 0 end

	if itemName ~= nil then
		_G.XHS_POTION_RECORD_TIMES = _G.XHS_POTION_RECORD_TIMES or {}
		local key = tostring(playerID) .. ":" .. tostring(itemName)
		local now = GameRules ~= nil and GameRules:GetGameTime() or 0
		local last = _G.XHS_POTION_RECORD_TIMES[key]
		if last ~= nil and now - last < 0.12 then
			_G.XHS_POTION_USES = _G.XHS_POTION_USES or {}
			return tonumber(_G.XHS_POTION_USES[playerID]) or 0
		end
		_G.XHS_POTION_RECORD_TIMES[key] = now
	end

	_G.XHS_POTION_USES = _G.XHS_POTION_USES or {}
	_G.XHS_POTION_USES[playerID] = (_G.XHS_POTION_USES[playerID] or 0) + 1

	if XHSRecordEndScreenStat ~= nil then
		XHSRecordEndScreenStat(playerID, "potions_used", 1)
	end

	if FragmentQuests ~= nil and caster ~= nil then
		FragmentQuests:OnPotionUsed(caster)
	end

	if caster ~= nil and ZONE_STAT_POTIONS ~= nil and GameRules.GameMode ~= nil and GameRules.GameMode.Zones ~= nil then
		for _, Zone in pairs(GameRules.GameMode.Zones) do
			if Zone ~= nil and Zone.ContainsUnit ~= nil and Zone:ContainsUnit(caster) then
				Zone:AddStat(playerID, ZONE_STAT_POTIONS, 1)
			end
		end
	end

	return _G.XHS_POTION_USES[playerID]
end

function XHSRecordPotionUse(caster, itemName)
	return XHSRecordPotionUseForPlayer(XHSGetPlayerIDFromUnit(caster), caster, itemName)
end

function XHSGetPotionUses(playerID)
	if playerID == nil then return 0 end

	_G.XHS_POTION_USES = _G.XHS_POTION_USES or {}
	return tonumber(_G.XHS_POTION_USES[playerID]) or 0
end

function XHSRecordEndScreenStat(playerID, statName, amount)
	playerID = tonumber(playerID)
	amount = tonumber(amount) or 0

	if playerID == nil or playerID < 0 or statName == nil or amount <= 0 then
		return 0
	end

	_G.XHS_END_SCREEN_STATS = _G.XHS_END_SCREEN_STATS or {}
	_G.XHS_END_SCREEN_STATS[playerID] = _G.XHS_END_SCREEN_STATS[playerID] or {}
	_G.XHS_END_SCREEN_STATS[playerID][statName] = (_G.XHS_END_SCREEN_STATS[playerID][statName] or 0) + amount

	return _G.XHS_END_SCREEN_STATS[playerID][statName]
end

-- Keep independent collectors for fragile engine callbacks. The public getter
-- takes the largest collector total, so the damage/heal filter and the hero
-- modifier can back each other up without counting the same event twice.
function XHSRecordEndScreenStatSource(playerID, statName, amount, sourceName)
	playerID = tonumber(playerID)
	amount = tonumber(amount) or 0
	sourceName = tostring(sourceName or "unknown")

	if playerID == nil or playerID < 0 or statName == nil or amount <= 0 then
		return 0
	end

	_G.XHS_END_SCREEN_STAT_SOURCES = _G.XHS_END_SCREEN_STAT_SOURCES or {}
	_G.XHS_END_SCREEN_STAT_SOURCES[playerID] = _G.XHS_END_SCREEN_STAT_SOURCES[playerID] or {}
	_G.XHS_END_SCREEN_STAT_SOURCES[playerID][statName] = _G.XHS_END_SCREEN_STAT_SOURCES[playerID][statName] or {}
	local sources = _G.XHS_END_SCREEN_STAT_SOURCES[playerID][statName]
	sources[sourceName] = (sources[sourceName] or 0) + amount
	return sources[sourceName]
end

function XHSGetEndScreenStat(playerID, statName)
	playerID = tonumber(playerID)
	if playerID == nil or statName == nil then return 0 end

	_G.XHS_END_SCREEN_STATS = _G.XHS_END_SCREEN_STATS or {}
	local playerStats = _G.XHS_END_SCREEN_STATS[playerID]
	local best = playerStats and tonumber(playerStats[statName]) or 0

	_G.XHS_END_SCREEN_STAT_SOURCES = _G.XHS_END_SCREEN_STAT_SOURCES or {}
	local playerSources = _G.XHS_END_SCREEN_STAT_SOURCES[playerID]
	local statSources = playerSources and playerSources[statName]
	for _, value in pairs(statSources or {}) do
		best = math.max(best, tonumber(value) or 0)
	end

	return best
end

function XHSIsBossDamageTarget(unit)
	if unit == nil or unit:IsNull() then return false end
	if unit.Boss == true or unit.bBoss == true then return true end
	if unit.FindAbilityByName ~= nil and unit:FindAbilityByName("boss_health") ~= nil then return true end

	local unitName = unit.GetUnitName ~= nil and unit:GetUnitName() or ""
	return string.find(unitName, "boss") ~= nil
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

function StartingItems(hero, newHero, options)
	options = options or {}
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

	if newHero:GetTeamNumber() == 2 and options.teleportToBase ~= false then
		TeleportHero(newHero, BASE_GOOD:GetAbsOrigin(), 3.0)
		-- elseif newHero:GetTeamNumber() == 3 then
		-- TeleportHero(newHero, base_bad:GetAbsOrigin(), 3.0)
	end

	-- Old-hero lifetime is owned by XHSPrecache:ReplaceHeroWith. Keeping the
	-- cleanup in one place prevents two delayed removals from racing on a
	-- recycled Source 2 entity handle.

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
