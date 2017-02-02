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

function PrintTable(t, indent, done)
	--print ( string.format ('PrintTable type %s', type(keys)) )
	if type(t) ~= "table" then return end

	done = done or {}
	done[t] = true
	indent = indent or 0

	local l = {}
	for k, v in pairs(t) do
		table.insert(l, k)
	end

	table.sort(l)
	for k, v in ipairs(l) do
		-- Ignore FDesc
		if v ~= 'FDesc' then
			local value = t[v]

			if type(value) == "table" and not done[value] then
				done [value] = true
				print(string.rep ("\t", indent)..tostring(v)..":")
				PrintTable (value, indent + 2, done)
			elseif type(value) == "userdata" and not done[value] then
				done [value] = true
				print(string.rep ("\t", indent)..tostring(v)..": "..tostring(value))
				PrintTable ((getmetatable(value) and getmetatable(value).__index) or getmetatable(value), indent + 2, done)
			else
				if t.FDesc and t.FDesc[v] then
					print(string.rep ("\t", indent)..tostring(t.FDesc[v]))
				else
					print(string.rep ("\t", indent)..tostring(v)..": "..tostring(value))
				end
			end
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
function HideWearables( event )
	local hero = event.caster
	local ability = event.ability

	hero.hiddenWearables = {} -- Keep every wearable handle in a table to show them later
		local model = hero:FirstMoveChild()
		while model ~= nil do
				if model:GetClassname() == "dota_item_wearable" then
						model:AddEffects(EF_NODRAW) -- Set model hidden
						table.insert(hero.hiddenWearables, model)
				end
				model = model:NextMovePeer()
		end
end

function ShowWearables( event )
	local hero = event.caster

	for i,v in pairs(hero.hiddenWearables) do
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

-- Skeleton king cosmetics
function SkeletonKingWearables( hero )

	-- Cape
	Attachments:AttachProp(hero, "attach_head", "models/heroes/skeleton_king/wraith_king_cape.vmdl", 1.0)

	-- Shoulderpiece
	Attachments:AttachProp(hero, "attach_head", "models/heroes/skeleton_king/wraith_king_shoulder.vmdl", 1.0)

	-- Crown
	Attachments:AttachProp(hero, "attach_head", "models/heroes/skeleton_king/wraith_king_head.vmdl", 1.0)

	-- Gauntlet
	Attachments:AttachProp(hero, "attach_attack1", "models/heroes/skeleton_king/wraith_king_gauntlet.vmdl", 1.0)

	-- Weapon (randomly chosen)
	local random_weapon = {
		"models/items/skeleton_king/spine_splitter/spine_splitter.vmdl",
		"models/items/skeleton_king/regalia_of_the_bonelord_sword/regalia_of_the_bonelord_sword.vmdl",
		"models/items/skeleton_king/weapon_backbone.vmdl",
		"models/items/skeleton_king/the_blood_shard/the_blood_shard.vmdl",
		"models/items/skeleton_king/sk_dragon_jaw/sk_dragon_jaw.vmdl",
		"models/items/skeleton_king/weapon_spine_sword.vmdl",
		"models/items/skeleton_king/shattered_destroyer/shattered_destroyer.vmdl"
	}
	Attachments:AttachProp(hero, "attach_attack1", random_weapon[RandomInt(1, #random_weapon)], 1.0)

	-- Eye particles
	local eye_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_skeletonking/skeletonking_eyes.vpcf", PATTACH_ABSORIGIN, hero)
	ParticleManager:SetParticleControlEnt(eye_pfx, 0, hero, PATTACH_POINT_FOLLOW, "attach_eyeL", hero:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(eye_pfx, 1, hero, PATTACH_POINT_FOLLOW, "attach_eyeR", hero:GetAbsOrigin(), true)
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
	for i=0,5 do
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

function ShuffledList( orig_list )
	local list = shallowcopy( orig_list )
	local result = {}
	local count = #list
	for i = 1, count do
		local pick = RandomInt( 1, #list )
		result[ #result + 1 ] = list[ pick ]
		table.remove( list, pick )
	end
	return result
end

function GenerateNumPointsAround(num, center, distance)
	local points = {}
	local angle = 360/num
	for i=0,num-1 do
		local rotate_pos = center + Vector(1,0,0) * distance
		table.insert(points, RotatePosition(center, QAngle(0, angle*i, 0), rotate_pos) )
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

-- IMBA Rune System
function SpawnRunes()
local powerup_rune_locations = Entities:FindAllByName("dota_item_rune_spawner_custom")
local game_time = GameRules:GetDOTATime(false, false)

	-- List of powerup rune types
	local powerup_rune_types = {
		"item_rune_armor"
	}

	for _, rune_loc in pairs(powerup_rune_locations) do
		local Rune = CreateItemOnPositionForLaunch(rune_loc:GetAbsOrigin() + Vector(0, 0, 50), CreateItem(powerup_rune_types[RandomInt(1, #powerup_rune_types)], nil, nil))
		Timers:CreateTimer(239.0, function()
			for _, runes in pairs(Rune) do -- 3:59
				UTIL_Remove(Rune)
			end
		end)
	end
end

-- Picks up an Armor rune
function PickupArmorRune(item, unit)

	item:ApplyDataDrivenModifier(unit, unit, "modifier_rune_armor", {})
	EmitSoundOnLocationForAllies(unit:GetAbsOrigin(), "Rune.Regen", unit)
end

if not Corpses then
	Corpses = class({})
end

CORPSE_DURATION = 87.0
CORPSE_APPEAR_DELAY = 3.0

function Corpses:CreateFromUnit(killed)
	if LeavesCorpse( killed ) then
		local name = killed:GetUnitName()
		local position = killed:GetAbsOrigin()
		local fv = killed:GetForwardVector()
		local team = killed:GetTeamNumber()
		local corpse = Corpses:CreateByNameOnPosition(name, position, DOTA_TEAM_GOODGUYS)
		corpse.playerID = killed:GetPlayerOwnerID()
		corpse:SetForwardVector(fv)
		corpse:AddNoDraw()
		Timers:CreateTimer(CORPSE_APPEAR_DELAY, function()
			if IsValidEntity(corpse) then
				UTIL_Remove(killed)
				corpse:RemoveNoDraw()
			end
		end)
	end
end

function Corpses:CreateByNameOnPosition(name, position, team)
	local corpse = CreateUnitByName("dotacraft_corpse", position, false, nil, nil, team)
	corpse.unit_name = name -- Keep a reference to its name

	-- Remove the corpse from the game at any point
	function corpse:RemoveCorpse()
		corpse:StopExpiration()
		-- Remove the entity
		UTIL_Remove(corpse)
	end

	-- Removes the removal timer
	function corpse:StopExpiration()
		if corpse.removal_timer then Timers:RemoveTimer(corpse.removal_timer) end
	end

	-- Remove itself after the corpse duration
	function corpse:StartExpiration()
		corpse.corpse_expiration = GameRules:GetGameTime() + CORPSE_DURATION

		corpse.removal_timer = Timers:CreateTimer(CORPSE_DURATION, function()
			if corpse and IsValidEntity(corpse) and not corpse.meat_wagon then
				UTIL_Remove(corpse)
			end
		end)
	end

	corpse:StartExpiration()
	
	return corpse
end

function Corpses:AreAnyInRadius(playerID, origin, radius)
	return self:FindClosestInRadius(playerID, origin, radius) ~= nil
end

function Corpses:AreAnyAlliedInRadius(playerID, origin, radius)
	return self:FindAlliedInRadius(playerID, origin, radius)[1] ~= nil
end

function Corpses:AreAnyOutsideInRadius(playerID, origin, radius)
	return self:FindInRadiusOutside(playerID, origin, radius)[1] ~= nil
end

function Corpses:FindClosestInRadius(playerID, origin, radius)
	return self:FindInRadius(playerID, origin, radius)[1]
end

function Corpses:FindInRadius(playerID, origin, radius)
	local targets = FindUnitsInRadius(PlayerResource:GetTeam(playerID), origin, nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_CLOSEST, false)
	local corpses = {}
	for _, target in pairs(targets) do
		if IsCorpse(target) and not target.meat_wagon then -- Ignore meat wagon corpses as first targets
			table.insert(corpses, target)
		end
	end
	for _,target in pairs(targets) do
		if IsCorpse(target) and target.meat_wagon and target.meat_wagon:GetPlayerOwnerID() == playerID then -- Check meat wagon ownership
			table.insert(corpses, target)
		end
	end
	return corpses
end

-- Only Friendly corpses
function Corpses:FindAlliedInRadius(playerID, origin, radius)
	local targets = FindUnitsInRadius(PlayerResource:GetTeam(playerID), origin, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_CLOSEST, false)
	local corpses = {}
	local teamNumber = PlayerResource:GetTeam(playerID)
	for _,target in pairs(targets) do
--		if IsCorpse(target) and not target.meat_wagon then -- Ignore meat wagon corpses
		if IsCorpse(target) then
			table.insert(corpses, target)
		end
	end
	return corpses
end

-- Only corpses outside meat wagon
function Corpses:FindInRadiusOutside(playerID, origin, radius)
	local targets = FindUnitsInRadius(PlayerResource:GetTeam(playerID), origin, nil, radius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_CLOSEST, false)
	local corpses = {}
	for _,target in pairs(targets) do
		if IsCorpse(target) and not target.meat_wagon then -- Ignore meat wagon corpses
			table.insert(corpses, target)
		end
	end
	return corpses
end

function CDOTA_BaseNPC:SetNoCorpse()
	self.no_corpse = true
end

function SetNoCorpse(event)
	event.target:SetNoCorpse()
end

-- Needs a corpse_expiration and not being eaten by cannibalize
function IsCorpse(unit)
	return unit.corpse_expiration and not unit.being_eaten
end

-- Custom Corpse Mechanic
function LeavesCorpse(unit)
	
	if not unit or not IsValidEntity(unit) then
		return false

	-- Heroes don't leave corpses (includes illusions)
	elseif unit:IsHero() then
		return false

	-- Ignore buildings 
	elseif unit.GetInvulnCount ~= nil then
		return false

	-- Ignore units that start with dummy keyword   
	elseif unit:IsDummy() then
		return false

	-- Ignore units that were specifically set to leave no corpse
--	elseif unit.no_corpse then
--		return false

	-- Air units
--	elseif unit:GetKeyValue("MovementCapabilities") == "DOTA_UNIT_CAP_MOVE_FLY" then
--		return false

	-- Summoned units via permanent modifier
	elseif unit:IsSummoned() then
		return false

	-- Read the LeavesCorpse KV
	else
		local leavesCorpse = unit:GetKeyValue("LeavesCorpse")
		if leavesCorpse and leavesCorpse == 0 then
			return false
		else
			-- Leave corpse     
			return true
		end
	end
end

-- Overrides dota method, use modifier_summoned MODIFIER_STATE_DOMINATED
function CDOTA_BaseNPC:IsSummoned()
    return self:IsDominated()
end

function CDOTA_BaseNPC:IsDummy()
    return self:GetUnitName():match("dummy_") or self:GetUnitLabel():match("dummy")
end

function SendErrorMessage(playerID, string)
   CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "dotacraft_error_message", {message=string}) 
end

-- Similar to SendErrorMessage to the bottom, except it checks whether the source of error is currently selected unit/hero.
function SendErrorMessageForSelectedUnit(playerID, string, unit)
	local selected = PlayerResource:GetSelectedEntities(playerID)
	if selected and selected["0"] == unit:GetEntityIndex() then
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(playerID), "dotacraft_error_message", {message=string})
	end
end
