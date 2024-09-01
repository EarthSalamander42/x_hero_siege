if IsClient() then
	LinkLuaModifier("modifier_provides_fow_position", "modifiers/modifier_provides_fow_position", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_npc_dialog", "modifiers/modifier_npc_dialog", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_npc_dialog_notify", "modifiers/modifier_npc_dialog_notify", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_stack_count_animation_controller", "modifiers/modifier_stack_count_animation_controller", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_disable_aggro", "modifiers/modifier_disable_aggro", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_tome_of_stats", "items/tomes.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_pause_creeps", "modifiers/modifier_pause_creeps.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_custom_mechanics", "modifiers/modifier_custom_mechanics", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_corpse", "modifiers/modifier_corpse.lua", LUA_MODIFIER_MOTION_NONE)
end
