require('libraries/timers')

function Immolation( event )
local manacost_per_second = 10

	if event.caster:GetMana() >= manacost_per_second then
		event.caster:SpendMana( manacost_per_second, event.ability)
	else
		event.ability:ToggleAbility()
	end
end

function Roar( event )
local caster = event.caster
	EmitSoundOnLocationForAllies(caster:GetAbsOrigin(), "Ability.Roar", caster)

	Timers:CreateTimer(1.9, function()
		caster:StopSound("Ability.Roar")
	end)
end

function ModelSwapStart( keys )
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

function ModelSwapEnd( keys )
local caster = keys.caster

	caster:SetModel(caster.caster_model)
	caster:SetOriginalModel(caster.caster_model)
	caster:SetAttackCapability(caster.caster_attack)
end


function HideWearables( event )
local hero = event.caster
local ability = event.ability
local duration = ability:GetLevelSpecialValueFor( "duration", ability:GetLevel() - 1 )
hero.hiddenWearables = {} -- Keep every wearable handle in a table, as its way better to iterate than in the MovePeer system
print("Hiding Wearables")
local model = hero:FirstMoveChild()
--hero:AddNoDraw() -- Doesn't work on classname dota_item_wearable
	while model ~= nil do
		if model:GetClassname() == "dota_item_wearable" then
			model:AddEffects(EF_NODRAW)
			table.insert(hero.hiddenWearables,model)
		end
		model = model:NextMovePeer()
	end
end

function ShowWearables( event )
local hero = event.caster

	for i,v in ipairs(hero.hiddenWearables) do
		v:RemoveEffects(EF_NODRAW)
	end
end
