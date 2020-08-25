function avatar_grown_model(keys)
    local final_model_scale = (keys.PercentageOverModelScale / 100) + 1  --This will be something like 1.3.
    local model_scale_increase_per_interval = 100 / (final_model_scale - 1)

    --Scale the model up over time.
    for i=1,100 do
        Timers:CreateTimer(i/75, 
        function()
            keys.caster:SetModelScale(1 + i/model_scale_increase_per_interval)
        end)
    end

    --Scale the model back down around the time the duration ends.
    for i=1,100 do
        Timers:CreateTimer(keys.Duration - 1 + (i/50),
        function()
            keys.caster:SetModelScale(final_model_scale - i/model_scale_increase_per_interval)
        end)
    end
end