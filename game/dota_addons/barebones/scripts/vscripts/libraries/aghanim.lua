if Check_Aghanim == nil then
    print ( '[Check_Aghanim] creating Check_Aghanim' )
    Check_Aghanim = {} -- Creates an array to let us beable to index abilities_simple when creating new functions
    Check_Aghanim.__index = Check_Aghanim
end

function HasCustomScepter(unit)
    local Has_Scepter = false
    for itemSlot = 0, 5, 1 do
        local Item = unit:GetItemInSlot( itemSlot )

        if Item ~= nil and Item:GetName() == "item_ultimate_scepter" then
            Has_Scepter = true
        end

        if Item ~= nil and Item:GetName() == "item_ultimate_scepter2" then
            Has_Scepter = true
        end

    end
    return Has_Scepter
end

function HasCustomScepter2(unit)
    local Has_Scepter2 = false
    for itemSlot = 0, 5, 1 do
        local Item = unit:GetItemInSlot( itemSlot )

        if Item ~= nil and Item:GetName() == "item_ultimate_scepter2" then
        Has_Scepter2 = true
        end
    end
    return Has_Scepter2
end

--[[
function LoopScepter( unit )
    if Has_Scepter == false then
        Timers:CreateTimer( 0.0, function()
            time_elapsed = time_elapsed + 0.5
            if time_elapsed >= 1.0 then
                print( "[AGHANIM] Aghs checker" )
                return 0.5

            end
        end)

    elseif Has_Scepter == true then
    print( "[AGHANIM] Aghs Checker found the Aghs!" )
    end
end
--]]