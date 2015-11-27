--[[
Phoenix AI
]]

require( "ai_core" )

behaviorSystem = {} -- create the global so we can assign to it

function Spawn( entityKeyValues )
	thisEntity:SetContextThink( "AIThink", AIThink, 0.25 )
	behaviorSystem = AICore:CreateBehaviorSystem( {
		BehaviorNone,
		BehaviorFirestorm,
--		BehaviorFirefly,
--		BehaviorSupernova,
		BehaviorRunAway } ) 
end

function AIThink() -- For some reason AddThinkToEnt doesn't accept member functions
	   return behaviorSystem:Think()
end

function CollectRetreatMarkers()
	local result = {}
	local i = 1
	local wp = nil
	while true do
		wp = Entities:FindByName( nil, string.format("waypoint_%d", i ) )
		if not wp then
			return result
		end
		table.insert( result, wp:GetOrigin() )
		i = i + 1
	end
end
POSITIONS_retreat = CollectRetreatMarkers()

--------------------------------------------------------------------------------------------------------

BehaviorNone = {}

function BehaviorNone:Evaluate()
	return 1 -- must return a value > 0, so we have a default
end

function BehaviorNone:Begin()
	self.endTime = GameRules:GetGameTime() + 1
	
	local ancient =  Entities:FindByName( nil, "dota_goodguys_fort" )
	
	if ancient then
		self.order =
		{
			UnitIndex = thisEntity:entindex(),
			OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
			Position = ancient:GetOrigin()
		}
	else
		self.order =
		{
			UnitIndex = thisEntity:entindex(),
			OrderType = DOTA_UNIT_ORDER_STOP
		}
	end
end

function BehaviorNone:Continue()
	self.endTime = GameRules:GetGameTime() + 1
end

--------------------------------------------------------------------------------------------------------

BehaviorFirestorm = {}

function BehaviorFirestorm:Evaluate()
	local desire = 0
	
	-- let's not choose this twice in a row
	if currentBehavior == self then return desire end

	ABILITY_firestorm = thisEntity:FindAbilityByName( "magtheridon_firestorm" )
	
	local enemies = FindUnitsInRadius( DOTA_TEAM_BADGUYS, thisEntity:GetOrigin(), nil, 900, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, 0, false )
	if #enemies > 0 then
		desire = 4
		if ABILITY_firestorm and ABILITY_firestorm:IsFullyCastable() then
			thisEntity:Stop()
			thisEntity:CastAbilityNoTarget( ABILITY_firestorm, -1 )
		end
	end 

	return desire
end

function BehaviorFirestorm:Begin()
	self.endTime = GameRules:GetGameTime() + 1
	
	self.order =
	{
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
		AbilityIndex = ABILITY_firestorm:entindex(),
	}

end

BehaviorFirestorm.Continue = BehaviorFirestorm.Begin

--------------------------------------------------------------------------------------------------------
--[[
BehaviorFirefly = {}

function BehaviorFirefly:Evaluate()
	local desire = 0
	
	-- let's not choose this twice in a row
	if currentBehavior == self then return desire end

	ABILITY_firefly = thisEntity:FindAbilityByName( "creature_firefly" )
	
	local enemies = FindUnitsInRadius( DOTA_TEAM_BADGUYS, thisEntity:GetOrigin(), nil, 1500, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, 0, false )
	if #enemies > 0 then
		desire = 4
		if ABILITY_firefly and ABILITY_firefly:IsFullyCastable() then
			thisEntity:Stop()
			thisEntity:CastAbilityNoTarget( ABILITY_firefly, -1 )
		end
	end 

	return desire
end

function BehaviorFirefly:Begin()
	self.endTime = GameRules:GetGameTime() + 1
	
	self.order =
	{
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
		AbilityIndex = ABILITY_firefly:entindex(),
	}

end

BehaviorFirefly.Continue = BehaviorFirefly.Begin

--------------------------------------------------------------------------------------------------------

BehaviorSupernova = {}

function BehaviorSupernova:Evaluate()
	ABILITY_supernova = thisEntity:FindAbilityByName("creature_supernova")
	local target
	local desire = 0

	-- let's not choose this twice in a row
	if AICore.currentBehavior == self then return desire end

	if ABILITY_supernova and ABILITY_supernova:IsFullyCastable() and thisEntity:GetHealth() < 2000 then
		thisEntity:CastAbilityNoTarget( ABILITY_supernova, -1 )
	end

	if target then
		desire = 5
		self.target = target
	else
		desire = 1
	end

	return desire
end

function BehaviorSupernova:Begin()
	self.endTime = GameRules:GetGameTime() + 6

	self.order =
	{
		OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
		UnitIndex = thisEntity:entindex(),
		TargetIndex = self.target:entindex(),
		AbilityIndex = ABILITY_supernova:entindex()
	}
end

BehaviorSupernova.Continue = BehaviorSupernova.Begin --if we re-enter this ability, we might have a different target; might as well do a full reset

function BehaviorSupernova:Think(dt)
	if not self.target:IsAlive() then
		self.endTime = GameRules:GetGameTime()
		return
	end
end
--]]
--------------------------------------------------------------------------------------------------------

BehaviorRunAway = {}

function BehaviorRunAway:Evaluate()
	local desire = 0
	local happyPlaceIndex =  RandomInt( 1, #POSITIONS_retreat )
	escapePoint = POSITIONS_retreat[ happyPlaceIndex ]
	-- let's not choose this twice in a row
	if currentBehavior == self then return desire end
	
	local enemies = FindUnitsInRadius( DOTA_TEAM_BADGUYS, thisEntity:GetOrigin(), nil, 700, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, 0, false )
	if #enemies > 0 then
		desire = #enemies
	end

	return desire
end


function BehaviorRunAway:Begin()
	self.endTime = GameRules:GetGameTime() + 6

	self.order =
	{
		OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
		UnitIndex = thisEntity:entindex(),
		TargetIndex = thisEntity:entindex(),
		AbilityIndex = self.forceAbility:entindex()
	}
end


function BehaviorRunAway:Think(dt)

end

BehaviorRunAway.Continue = BehaviorRunAway.Begin

--------------------------------------------------------------------------------------------------------

AICore.possibleBehaviors = {
	BehaviorNone,
	BehaviorFirestorm,
--	BehaviorFirefly,
--	BehaviorSupernova,
	BehaviorRunAway }
