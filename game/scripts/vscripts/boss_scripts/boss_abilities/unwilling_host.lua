-- Venomancer's Unwilling Host (for the clientside modifier)

frostivus_boss_unwilling_host = class({})

function frostivus_boss_unwilling_host:IsHiddenWhenStolen() return true end
function frostivus_boss_unwilling_host:IsRefreshable() return true end
function frostivus_boss_unwilling_host:IsStealable() return false end