require('libraries/tools')

function spawn_spirit( event )
	-- body
	local avatar = event.caster
	local ability = event.ability
	local max_spirits = ability:GetLevelSpecialValueFor("max_units", ability:GetLevel()-1)
	local number_spirits = ability:GetLevelSpecialValueFor("units", ability:GetLevel()-1)

	if IsValidAlive(avatar) then
		if avatar.spirits == nil then
			avatar.spirits = {}
		end
		
		for k,v in ipairs(avatar.spirits) do
			if not IsValidAlive(v) then
				table.remove(avatar.spirits,k)
			end 
		end

		if #avatar.spirits >= max_spirits then
			local a = table.remove(avatar.spirits)
			a:RemoveSelf()
		end 

		for i = 1,number_spirits do
			local unit = CreateUnitByName("npc_spirit_of_vengeance", avatar:GetAbsOrigin()+150*avatar:GetForwardVector(), true, avatar, avatar:GetOwner(), avatar:GetTeam())
			unit:SetControllableByPlayer(avatar:GetPlayerOwnerID(), true)
			unit:AddNewModifier(nil, nil, "modifier_phased", {Duration = 0.05})
			ability:ApplyDataDrivenModifier(avatar, unit, "modifier_spirit_of_vengeance", {})
			table.insert(avatar.spirits,1,unit)
		end
	end 
end

function despawn_spirits(event)
	-- body
	local avatar = event.target

	for k,v in pairs(avatar.spirits) do
		if not v:IsNull() then
			v:RemoveSelf()
		end
	end
	avatar.spirits = {}
end