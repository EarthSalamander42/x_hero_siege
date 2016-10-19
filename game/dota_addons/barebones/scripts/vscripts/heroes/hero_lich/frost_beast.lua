function GrowModel( event )
	local caster = event.caster
	local ability = event.ability

	Timers:CreateTimer(function() 
		local model = caster:FirstMoveChild()
		while model ~= nil do
			if model:GetClassname() == "dota_item_wearable" then
				if not string.match(model:GetModelName(), "tree") then
					local new_model_name = string.gsub(model:GetModelName(),"1","4")
					model:SetModel(new_model_name)
				else
					model:SetParent(caster, "attach_attack1")
					model:AddEffects(EF_NODRAW)
				end
			end
			model = model:NextMovePeer()
			caster:AddNewModifier(caster, nil, "modifier_phased", {duration = 0.05})
		end
	end)
end
