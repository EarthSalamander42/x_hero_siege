function ToggleAbilities(keys)
local caster = keys.caster
local ability = keys.ability
local ability_aux = keys.ability_aux
local ability2 = caster:FindAbilityByName(ability_aux)
local projectile_model = keys.projectile_model

	-- debug
	caster:SetRangedProjectileName(projectile_model)

	if ability:GetToggleState() == true and ability:GetToggleState() == ability2:GetToggleState() then
		ability2:ToggleAbility()
		caster:SetRangedProjectileName(projectile_model)
	end
end

function SetOriginal(keys)
local caster = keys.caster
local projectile_model = "particles/units/heroes/hero_sniper/sniper_base_attack.vpcf"

	caster:SetRangedProjectileName(projectile_model)
end

function PreRifleOrb(keys)
local caster = keys.caster
local ability = keys.ability
local ability_level = ability:GetLevel() - 1
local mana = ability:GetManaCost(ability_level)
local sound = keys.sound

	if caster:GetMana() > ability:GetManaCost(ability_level) and ability:GetToggleState() == true then
		EmitSoundOn(sound, caster)
		caster:SpendMana(mana, ability)
	elseif caster:GetMana() < ability:GetManaCost(ability_level) and ability:GetToggleState() == true then
		ability:ToggleAbility() -- Remove modifier
	end
end

function RifleOrb(keys)
local caster = keys.caster
local target = keys.target
local ability = keys.ability
local ability_level = ability:GetLevel() - 1
local damage = ability:GetLevelSpecialValueFor("bonus_damage", ability_level)
local sound = keys.sound

	if caster:GetMana() > ability:GetManaCost(ability_level) and ability:GetToggleState() == true then
		EmitSoundOn(sound, target)
	end
end

rifleman_assassinate = class({})

--------------------------------------------------------------------------------

function rifleman_assassinate:GetAOERadius()
	return self:GetSpecialValueFor( "scepter_radius" )
end

--------------------------------------------------------------------------------

function rifleman_assassinate:GetBehavior()
	if self:GetCaster():HasScepter() then
		return DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_AOE
	end

	return self.BaseClass.GetBehavior( self )
end

--------------------------------------------------------------------------------

function rifleman_assassinate:OnAbilityPhaseStart()
	if IsServer() then
		local aim_duration = self:GetSpecialValueFor( "aim_duration" )
		local hTarget = self:GetCursorTarget()
		if hTarget ~= nil then
			hTarget:AddNewModifier( self:GetCaster(), self, "modifier_sniper_assassinate", { duration = aim_duration } )
		elseif self:GetCaster():HasScepter() then
			self.hScepterTargets = {}
			local scepter_radius = self:GetSpecialValueFor( "scepter_radius" )
			local enemies = FindUnitsInRadius( self:GetCaster():GetTeamNumber(), self:GetCursorPosition(), self:GetCaster(), scepter_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false )
			if #enemies > 0 then
				for _,enemy in pairs(enemies) do
					if enemy ~= nil then
						enemy:AddNewModifier( self:GetCaster(), self, "modifier_sniper_assassinate", { duration = aim_duration } )
						table.insert( self.hScepterTargets, enemy )
					end
				end
			end
		end

		EmitSoundOn( "Ability.AssassinateLoad", self:GetCaster() )
	end

	return true
end

--------------------------------------------------------------------------------

function rifleman_assassinate:OnAbilityPhaseInterrupted()
	if IsServer() then
		local hTarget = self:GetCursorTarget()
		if hTarget ~= nil then
			hTarget:RemoveModifierByName( "modifier_sniper_assassinate" )
		elseif self:GetCaster():HasScepter() then
			for i=1,#self.hScepterTargets do
				local enemy = self.hScepterTargets[i]
				if enemy ~= nil then
					enemy:RemoveModifierByName( "modifier_sniper_assassinate" )
					table.remove( self.hScepterTargets, i )
				end
			end
		end
	end
end

--------------------------------------------------------------------------------

function rifleman_assassinate:OnSpellStart()	
	if IsServer() then
		self.bInBuckshot = false
		local hTarget = self:GetCursorTarget()
		if hTarget ~= nil then
			local info = 
			{
				EffectName = "particles/units/heroes/hero_sniper/sniper_assassinate.vpcf";
				Target = hTarget,
				Source = self:GetCaster(),
				Ability = self,
				iMoveSpeed = self:GetSpecialValueFor( "projectile_speed" )
			}

			ProjectileManager:CreateTrackingProjectile( info )
			EmitSoundOn( "Ability.Assassinate", self:GetCaster() )
			EmitSoundOn( "Hero_Sniper.AssassinateProjectile", self:GetCaster() )
		elseif self:GetCaster():HasScepter() then
			local scepter_radius = self:GetSpecialValueFor( "scepter_radius" )
			local enemies = FindUnitsInRadius( self:GetCaster():GetTeamNumber(), self:GetCursorPosition(), self:GetCaster(), FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false )
			if #enemies > 0 then
				for _,enemy in pairs(enemies) do
					if enemy ~= nil and enemy:FindModifierByName( "modifier_sniper_assassinate" ) ~= nil then
						local info = 
						{
							EffectName = "particles/units/heroes/hero_sniper/sniper_assassinate.vpcf";
							Target = enemy,
							Source = self:GetCaster(),
							Ability = self,
							iMoveSpeed = self:GetSpecialValueFor( "projectile_speed" )
						}

						ProjectileManager:CreateTrackingProjectile( info )
						EmitSoundOn( "Ability.Assassinate", self:GetCaster() )
						EmitSoundOn( "Hero_Sniper.AssassinateProjectile", self:GetCaster() )
					end
				end
			end
		end
	end
end

--------------------------------------------------------------------------------

function rifleman_assassinate:OnProjectileHit( hTarget, vLocation )
	if IsServer() then
		if hTarget ~= nil then
			hTarget:RemoveModifierByName( "modifier_sniper_assassinate" )
			if not hTarget:IsInvulnerable() then
				if self:GetCaster():HasScepter() then
					self:GetCaster():AddNewModifier( self:GetCaster(), self, "modifier_sniper_assassinate_caster", {} )
					self:GetCaster():PerformAttack( hTarget, true, true, true, true, false, false, true )
					self:GetCaster():RemoveModifierByName( "modifier_sniper_assassinate_caster" )
				else
					if self.bInBuckshot == false then
						local damage = 
						{
							victim = hTarget,
							attacker = self:GetCaster(),
							ability = self,
							damage = self:GetSpecialValueFor( "assassinate_damage"),
							damage_type = DAMAGE_TYPE_PURE,
						}

						ApplyDamage( damage )
						EmitSoundOn( "Hero_Sniper.AssassinateDamage", hTarget )

						-- stun the main target
						hTarget:AddNewModifier( self:GetCaster(), self, "modifier_stunned", { duration = self:GetSpecialValueFor( "stun_duration" ) } )

						local vToTarget = hTarget:GetOrigin() - self:GetCaster():GetOrigin() 
						vToTarget = vToTarget:Normalized()

						local vSideTarget = Vector( vToTarget.y, -vToTarget.x, 0.0 )
						local scatter_range = self:GetSpecialValueFor( "scatter_range" )
						local scatter_width = self:GetSpecialValueFor( "scatter_width" )

						local enemies = FindUnitsInRadius( self:GetCaster():GetTeamNumber(), hTarget:GetOrigin(), self:GetCaster(), scatter_range + scatter_width, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, 0, false )
						if #enemies > 0 then
							for _,enemy in pairs(enemies) do
								if enemy ~= nil and not enemy:IsInvulnerable() then
									local vToPotentialTarget = enemy:GetOrigin() - hTarget:GetOrigin()
									local flSideAmount = math.abs( vToPotentialTarget.x * vSideTarget.x + vToPotentialTarget.y * vSideTarget.y + vToPotentialTarget.z * vSideTarget.z )
									local flLengthAmount = ( vToPotentialTarget.x * vToTarget.x + vToPotentialTarget.y * vToTarget.y + vToPotentialTarget.z * vToTarget.z )
									if ( flSideAmount < scatter_width ) and ( flLengthAmount > 0.0 ) and ( flLengthAmount < scatter_range ) then
										local info = 
										{
											EffectName = "particles/units/heroes/hero_sniper/sniper_assassinate.vpcf";
											Target = enemy,
											Source = hTarget,
											Ability = self,
											iMoveSpeed = self:GetSpecialValueFor( "projectile_speed" ) / 2
										}

										ProjectileManager:CreateTrackingProjectile( info )
										EmitSoundOn( "Hero_Sniper.AssassinateProjectile_Scatter", enemy )
									end
								end
							end
						end
						self.bInBuckshot = true
					else
						local damage = 
						{
							victim = hTarget,
							attacker = self:GetCaster(),
							ability = self,
							damage = self:GetSpecialValueFor( "assassinate_damage") * 0.4,
							damage_type = DAMAGE_TYPE_PURE,
						}

						ApplyDamage( damage )
						EmitSoundOn( "Hero_Sniper.AssassinateDamage_Scatter", hTarget )
					end
				end
			end
		end
	end

	return true
end
