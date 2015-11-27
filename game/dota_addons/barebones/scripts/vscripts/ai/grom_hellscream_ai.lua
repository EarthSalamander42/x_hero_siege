--[[
Grom Hellscream AI
]]

require( "ai_core" )

behaviorSystem = {} -- create the global so we can assign to it

function Spawn( entityKeyValues )
	thisEntity:SetContextThink( "AIThink", AIThink, 0.25 )
    behaviorSystem = AICore:CreateBehaviorSystem( { BehaviorNone, BehaviorBladeFury, BehaviorOmniSlash, BehaviorRunAway } ) 
end

function AIThink() -- For some reason AddThinkToEnt doesn't accept member functions
       return behaviorSystem:Think()
end

function CollectRetreatMarkers()
	local result = {}
	local i = 1
	local wp = nil
	while true do
		wp = Entities:FindByName( nil, string.format("npc_dota_spawner_%d", i ) )
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
	
	local ancient =  Entities:FindByName( nil, "spawn_grom_hellscream" )
	
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

BehaviorBladeFury = {}

function BehaviorBladeFury:Evaluate()
	ABILITY_bladefury = thisEntity:FindAbilityByName("creature_blade_fury")
	local desire = 0

	-- let's not choose this twice in a row
	if AICore.currentBehavior == self then return desire end

	local enemies = FindUnitsInRadius( DOTA_TEAM_BADGUYS, thisEntity:GetOrigin(), nil, 1500, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_ALL, 0, 0, false )
	if #enemies > 0 then
		if ABILITY_bladefury and ABILITY_bladefury:IsFullyCastable() then
			thisEntity:Stop()
			thisEntity:CastAbilityNoTarget( ABILITY_bladefury, -1 )
		end
	end

	return desire
end

function BehaviorBladeFury:Begin()
	self.endTime = GameRules:GetGameTime() + 5

	self.order =
	{
		OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
		UnitIndex = thisEntity:entindex(),
		TargetIndex = self.target:entindex(),
		AbilityIndex = ABILITY_bladefury:entindex()
	}
end

BehaviorBladeFury.Continue = BehaviorBladeFury.Begin --if we re-enter this ability, we might have a different target; might as well do a full reset

function BehaviorBladeFury:Think(dt)
	if not self.target:IsAlive() then
		self.endTime = GameRules:GetGameTime()
		return
	end
end

--------------------------------------------------------------------------------------------------------

BehaviorOmniSlash = {}

function BehaviorOmniSlash:Evaluate()
	local desire = 0
	
	-- let's not choose this twice in a row
	if currentBehavior == self then return desire end

	ABILITY_omnislash = thisEntity:FindAbilityByName( "creature_omni_slash" )
	
	if ABILITY_omnislash and ABILITY_omnislash:IsFullyCastable() then
		self.target = AICore:RandomEnemyHeroInRange( thisEntity, ABILITY_omnislash:GetCastRange() )
		if self.target then
			desire = 4
		end
	end

	local enemies = FindUnitsInRadius( DOTA_TEAM_BADGUYS, thisEntity:GetOrigin(), nil, 400, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, 0, 0, false )
	if #enemies > 0 then
		for _,enemy in pairs(enemies) do
			local enemyVec = enemy:GetOrigin() - thisEntity:GetOrigin()
			local myForward = thisEntity:GetForwardVector()
			local dotProduct = enemyVec:Dot( myForward ) 
			if dotProduct > 0 then
				desire = 2
			end
		end
	end 

	return desire
end

function BehaviorOmniSlash:Begin()
	self.endTime = GameRules:GetGameTime() + 1

	local targetPoint = self.target:GetOrigin()
	
	self.order =
	{
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
		AbilityIndex = ABILITY_omnislash:entindex(),
		Position = targetPoint
	}

end

BehaviorOmniSlash.Continue = BehaviorOmniSlash.Begin

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
	
	for i=0,DOTA_ITEM_MAX-1 do
		local item = thisEntity:GetItemInSlot( i )
		if item and item:GetAbilityName() == "item_force_staff" then
			self.forceAbility = item
		end
		if item and item:GetAbilityName() == "item_phase_boots" then
			self.phaseAbility = item
		end
		if item and item:GetAbilityName() == "item_ancient_janggo" then
			self.drumAbility = item
		end
		if item and item:GetAbilityName() == "item_urn_of_shadows" then
			self.urnAbility = item
		end
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
	
	ExecuteOrderFromTable({
			UnitIndex = thisEntity:entindex(),
			OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
			TargetIndex = thisEntity:entindex(),
			AbilityIndex = self.forceAbility:entindex()
		})
		
	if self.forceAbility and not self.forceAbility:IsFullyCastable() then
		ExecuteOrderFromTable({
			UnitIndex = thisEntity:entindex(),
			OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
			Position = escapePoint
		})
		ExecuteOrderFromTable({
			UnitIndex = thisEntity:entindex(),
			OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
			AbilityIndex = self.drumAbility:entindex()
		})
		ExecuteOrderFromTable({
			UnitIndex = thisEntity:entindex(),
			OrderType = DOTA_UNIT_ORDER_CAST_NO_TARGET,
			AbilityIndex = self.phaseAbility:entindex()
		})
	end
	
	if self.urnAbility and self.urnAbility:IsFullyCastable() and self.endTime < GameRules:GetGameTime() + 2 then
		ExecuteOrderFromTable({
			UnitIndex = thisEntity:entindex(),
			OrderType = DOTA_UNIT_ORDER_CAST_TARGET,
			TargetIndex = thisEntity:entindex(),
			AbilityIndex = self.urnAbility:entindex()
		})
	end
end

BehaviorRunAway.Continue = BehaviorRunAway.Begin

--------------------------------------------------------------------------------------------------------

AICore.possibleBehaviors = { BehaviorNone, BehaviorBladeFury, BehaviorOmniSlash, BehaviorRunAway }
