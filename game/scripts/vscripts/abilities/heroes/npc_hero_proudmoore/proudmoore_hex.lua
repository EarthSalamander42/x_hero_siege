--[[Author: Pizzalol
	Date: 18.01.2015.
	Checks if the target is an illusion, if true then it kills it
	otherwise the target model gets swapped into the passed model]]
function voodoo_start(keys)
	local target = keys.target
	local model = keys.model

	if target:IsIllusion() then
		target:Kill(nil, nil)
	else
		if target.target_model == nil then
			target.target_model = target:GetModelName()
		end

		target:SetOriginalModel(model)
	end
end

--[[Author: Pizzalol
	Date: 18.01.2015.
	Reverts the target model back to what it was]]
function voodoo_end(keys)
	local target = keys.target

	-- Checking for errors
	if target.target_model ~= nil then
		target:SetModel(target.target_model)
		target:SetOriginalModel(target.target_model)
	end
end

function HideWearables(event)
	local hero = event.target
	local ability = event.ability
	local duration = ability:GetLevelSpecialValueFor("duration", ability:GetLevel() - 1)
	hero.hiddenWearables = {} -- Keep every wearable handle in a table, as its way better to iterate than in the MovePeer system
	print("Hiding Wearables")
	local model = hero:FirstMoveChild()
	--hero:AddNoDraw() -- Doesn't work on classname dota_item_wearable
	while model ~= nil do
		if model:GetClassname() == "dota_item_wearable" then
			model:AddEffects(EF_NODRAW)

			table.insert(hero.hiddenWearables, model)
		end
		model = model:NextMovePeer()
	end
end

--[[Author: Noya
  Date: 10.01.2015.
  Shows the hidden hero wearables
]]
function ShowWearables(event)
	local hero = event.target

	-- Iterate on both tables to set each item back to their original modelName
	for i, v in ipairs(hero.hiddenWearables) do
		v:RemoveEffects(EF_NODRAW)
	end
end
