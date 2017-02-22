--[[
Creeps AI
]]

require( "ai_core" )

behaviorSystem = {} -- create the global so we can assign to it

function Spawn( entityKeyValues )
	thisEntity:SetContextThink( "AIThink", AIThink, 0.25 )
	behaviorSystem = AICore:CreateBehaviorSystem( { BehaviorNone } ) 
end

function AIThink() -- For some reason AddThinkToEnt doesn't accept member functions
	return behaviorSystem:Think()
end

--------------------------------------------------------------------------------------------------------

BehaviorNone = {}

function BehaviorNone:Evaluate()
	return 10 -- must return a value > 0, so we have a default
end

function BehaviorNone:Begin()
	self.endTime = GameRules:GetGameTime() + 10

	local ancient = Entities:FindByName(nil, "dota_goodguys_fort")

	if ancient then
		self.order =
		{
			UnitIndex = thisEntity:entindex(),
			OrderType = DOTA_UNIT_ORDER_ATTACK_MOVE,
			Position = ancient:GetOrigin()
		}
--	else
--		self.order =
--		{
--			UnitIndex = thisEntity:entindex(),
--			OrderType = DOTA_UNIT_ORDER_STOP
--		}
	end
end

function BehaviorNone:Continue()
	self.endTime = GameRules:GetGameTime() + 10
end

--------------------------------------------------------------------------------------------------------

AICore.possibleBehaviors = { BehaviorNone }
