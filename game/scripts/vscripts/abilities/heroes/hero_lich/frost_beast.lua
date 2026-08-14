LinkLuaModifier("modifier_lich_frost_beast_spawn_growth", "abilities/heroes/hero_lich/frost_beast.lua", LUA_MODIFIER_MOTION_NONE)

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

function OnFrostBeastSpawn(event)
	local unit = event.target or event.unit

	if not unit or unit:IsNull() then return end

	unit:AddNewModifier(unit, event.ability, "modifier_lich_frost_beast_spawn_growth", { duration = 2.0 })
end

modifier_lich_frost_beast_spawn_growth = modifier_lich_frost_beast_spawn_growth or class({})
modifier_lich_frost_beast_spawn_growth.XHS_LINK_CLIENT = true

function modifier_lich_frost_beast_spawn_growth:IsHidden() return true end
function modifier_lich_frost_beast_spawn_growth:IsPurgable() return false end
function modifier_lich_frost_beast_spawn_growth:RemoveOnDeath() return true end

function modifier_lich_frost_beast_spawn_growth:OnCreated()
	if not IsServer() then return end

	self.grow_duration = 2.0
	self.start_scale_factor = 0.25
	self.start_time = GameRules:GetGameTime()
	self.parent = self:GetParent()
	self.final_scale = self.parent:GetModelScale()
	self.start_scale = self.final_scale * self.start_scale_factor

	self.parent:SetModelScale(self.start_scale)
	self:StartIntervalThink(0.03)
end

function modifier_lich_frost_beast_spawn_growth:OnIntervalThink()
	if not IsServer() then return end
	if not self.parent or self.parent:IsNull() then return end

	local elapsed = math.min(GameRules:GetGameTime() - self.start_time, self.grow_duration)
	local progress = elapsed / self.grow_duration
	local eased = progress * progress * (3 - 2 * progress)
	local scale = self.start_scale + (self.final_scale - self.start_scale) * eased

	self.parent:SetModelScale(scale)

	if progress >= 1 then
		self.parent:SetModelScale(self.final_scale)
		self:StartIntervalThink(-1)
		self:Destroy()
	end
end

function modifier_lich_frost_beast_spawn_growth:OnDestroy()
	if not IsServer() then return end
	if self.parent and not self.parent:IsNull() and self.final_scale then
		self.parent:SetModelScale(self.final_scale)
	end
end
