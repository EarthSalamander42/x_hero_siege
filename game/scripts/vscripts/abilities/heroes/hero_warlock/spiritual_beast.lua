--[[Kill wolves on resummon
	Author: Noya
	Date: 20.01.2015.]]

function KillWolves( event )
	local caster = event.caster
	local targets = caster.wolves or {}
for _,unit in pairs(targets) do 
	if unit and IsValidEntity(unit) then
			unit:Kill(nil, nil)
		end
	end
-- Reset table
caster.wolves = {}
end

--[[
	Author: Noya
	Date: 20.01.2015.
	Gets the summoning forward direction for the new units
]]

function GetSummonPoints( event )
	local caster = event.caster
	local fv = caster:GetForwardVector()
	local origin = caster:GetAbsOrigin()
	local distance = event.distance
-- Gets 2 points facing a distance away from the caster origin and separated from each other at 30 degrees left and right
	ang_right = QAngle(0, -30, 0)
	ang_left = QAngle(0, 30, 0)
	ang_right2 = QAngle(0, -70, 0)
	ang_left2 = QAngle(0, 70, 0)
	ang_right3 = QAngle(0, -110, 0)
	ang_left3 = QAngle(0, 110, 0)
	ang_right4 = QAngle(0, -150, 0)
	ang_left4 = QAngle(0, 150, 0)
local front_position = origin + fv * distance
	point_left = RotatePosition(origin, ang_left, front_position)
	point_right = RotatePosition(origin, ang_right, front_position)
	point_left2 = RotatePosition(origin, ang_left2, front_position)
	point_right2 = RotatePosition(origin, ang_right2, front_position)
	point_left3 = RotatePosition(origin, ang_left3, front_position)
	point_right3 = RotatePosition(origin, ang_right3, front_position)
	point_left4 = RotatePosition(origin, ang_left4, front_position)
	point_right4 = RotatePosition(origin, ang_right4, front_position)
local result = { }
	table.insert(result, point_right)
	table.insert(result, point_left)
	table.insert(result, point_right2)
	table.insert(result, point_left2)
	table.insert(result, point_right3)
	table.insert(result, point_left3)
	table.insert(result, point_right4)
	table.insert(result, point_left4)
return result
end

-- Set the units looking at the same point of the caster
function SetUnitsMoveForward( event )
	local caster = event.caster
	local target = event.target
	local fv = caster:GetForwardVector()
	local origin = caster:GetAbsOrigin()
target:SetForwardVector(fv)
-- Add the target to a table on the caster handle, to find them later
table.insert(caster.wolves, target)
end