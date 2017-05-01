function ModelSwapStart(keys)
local caster = keys.caster
local model = keys.model
local projectile_model = keys.projectile_model

	if caster.caster_model == nil then 
		caster.caster_model = caster:GetModelName()
	end
	caster.caster_attack = caster:GetAttackCapability()

	caster:SetOriginalModel(model)
	caster:SetRangedProjectileName(projectile_model)
	caster:SetAttackCapability(DOTA_UNIT_CAP_RANGED_ATTACK)
end

function ModelSwapEnd(keys)
local caster = keys.caster

	caster:SetModel(caster.caster_model)
	caster:SetOriginalModel(caster.caster_model)
	caster:SetAttackCapability(caster.caster_attack)
end

function HideWearables(event)
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

function ShowWearables(event)
local hero = event.caster

	for i,v in pairs(hero.hiddenWearables) do
		v:RemoveEffects(EF_NODRAW)
	end
end
