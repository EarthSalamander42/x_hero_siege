-- Changes the color of the summoned unit
function RenderInferno(event)
	event.target:SetRenderColor(128, 255, 0)
	event.target:AddNewModifier(nil, nil, "modifier_phased", {duration = 0.05})
end
