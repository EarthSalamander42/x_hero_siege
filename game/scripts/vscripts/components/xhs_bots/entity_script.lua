-- Entity script used only to obtain a real Dota bot player slot. The XHS
-- manager owns all decision making; no vanilla lane bot logic runs here.
function Spawn(entityKeyValues)
	if not IsServer() or thisEntity == nil then return end
	thisEntity.xhs_is_bot = true

	if XHSBotProvisioner ~= nil and XHSBotProvisioner.OnEntityScriptSpawn ~= nil then
		XHSBotProvisioner:OnEntityScriptSpawn(thisEntity)
	end
end
