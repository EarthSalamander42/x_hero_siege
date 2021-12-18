CAST_SOUND_TABLE = {"nevermore_nev_anger_04", "nevermore_nev_anger_06", "nevermore_nev_anger_07", "nevermore_nev_arc_laugh_04", "nevermore_nev_arc_laugh_05", "nevermore_nev_arc_laugh_02"}

function begin_explosion(event)
	local caster = event.caster
	local ability = event.ability
	abilityLevel = ability:GetLevel()
	location = caster:GetOrigin()
	forwardVector = caster:GetForwardVector()
	StartAnimation(caster, {duration=2, activity=ACT_DOTA_CAST_ABILITY_6, rate=1})
	local randInt = RandomInt(0, 2)
	if randInt == 0 then
		pattern1(forwardVector, location, ability, caster, abilityLevel)
	elseif randInt == 1 then
		pattern2(forwardVector, location, ability, caster, abilityLevel)
	elseif randInt == 2 then
		pattern3(forwardVector, location, ability, caster, abilityLevel)
	end
	EmitSoundOn(CAST_SOUND_TABLE[RandomInt(1,6)], caster)
	--StartAnimation(caster, {duration=.5, activity=ACT_DOTA_CAST_ABILITY_3, rate=.8, translate="blood_chaser"}) 
	
end

function pattern1(forwardVector, location, ability, caster, abilityLevel)
	for i=-3, 3, 1 do 
		rotatedVector = rotateVector(forwardVector, i*2*math.pi/7)*Vector(200, 200, 0)
		targetPoint = rotatedVector + location*Vector(1,1,0)
		create_individual_explosion(abilityLevel, caster, targetPoint, location)
	end
	Timers:CreateTimer(0.3, -- Start this timer 10 game-time seconds later
          function()
          	EmitSoundOn("Hero_Nevermore.Shadowraze", caster)
				for i=-6, 6, 1 do 
					rotatedVector = rotateVector(forwardVector, i*2*math.pi/13)*Vector(400, 400, 0)
					targetPoint = rotatedVector + location*Vector(1,1,0)
					create_individual_explosion(abilityLevel, caster, targetPoint, location)
				end
           end)
	Timers:CreateTimer(0.6, -- Start this timer 10 game-time seconds later
          function()
          	EmitSoundOn("Hero_Nevermore.Shadowraze", caster)
				for i=-9, 9, 1 do 
					rotatedVector = rotateVector(forwardVector, i*2*math.pi/19)*Vector(600, 600, 0)
					targetPoint = rotatedVector + location*Vector(1,1,0)
					create_individual_explosion(abilityLevel, caster, targetPoint, location)
				end
           end)
	Timers:CreateTimer(0.9, -- Start this timer 10 game-time seconds later
          function()
          	EmitSoundOn("Hero_Nevermore.Shadowraze", caster)
				for i=-13, 13, 1 do 
					rotatedVector = rotateVector(forwardVector, i*2*math.pi/27)*Vector(600, 600, 0)
					targetPoint = rotatedVector + location*Vector(1,1,0)
					create_individual_explosion(abilityLevel, caster, targetPoint, location)
				end
           end)

end

function pattern2(forwardVector, location, ability, caster, abilityLevel)
	perp = perpendicularVector(forwardVector)
	for i=-2, 2, 1 do 
		targetPoint = (location+forwardVector*Vector(200,200,0)) + forwardVector+perp*Vector(200,200,0)*i
		create_individual_explosion(abilityLevel, caster, targetPoint, location)
	end	
	Timers:CreateTimer(.15, -- Start this timer 10 game-time seconds later
          function()
          	EmitSoundOn("Hero_Nevermore.Shadowraze", caster)
			for i=-2, 2, 1 do 
				targetPoint = (location+forwardVector*Vector(400,400,0)) + forwardVector+perp*Vector(200,200,0)*i
				create_individual_explosion(abilityLevel, caster, targetPoint, location)
			end	
           end)
	Timers:CreateTimer(.3, -- Start this timer 10 game-time seconds later
          function()
          	EmitSoundOn("Hero_Nevermore.Shadowraze", caster)
			for i=-2, 2, 1 do 
				targetPoint = (location+forwardVector*Vector(600,600,0)) + forwardVector+perp*Vector(200,200,0)*i
				create_individual_explosion(abilityLevel, caster, targetPoint, location)
			end	
           end)
	Timers:CreateTimer(.45, -- Start this timer 10 game-time seconds later
          function()
          	EmitSoundOn("Hero_Nevermore.Shadowraze", caster)
			for i=-2, 2, 1 do 
				targetPoint = (location+forwardVector*Vector(800,800,0)) + forwardVector+perp*Vector(200,200,0)*i
				create_individual_explosion(abilityLevel, caster, targetPoint, location)
			end	
           end)
	Timers:CreateTimer(.6, -- Start this timer 10 game-time seconds later
          function()
          	EmitSoundOn("Hero_Nevermore.Shadowraze", caster)
			for i=-2, 2, 1 do 
				targetPoint = (location+forwardVector*Vector(1000,1000,0)) + forwardVector+perp*Vector(200,200,0)*i
				create_individual_explosion(abilityLevel, caster, targetPoint, location)
			end	
           end)
	Timers:CreateTimer(0.75, -- Start this timer 10 game-time seconds later
          function()
          	EmitSoundOn("Hero_Nevermore.Shadowraze", caster)
			for i=-2, 2, 1 do 
				targetPoint = (location+forwardVector*Vector(1200,1200,0)) + forwardVector+perp*Vector(200,200,0)*i
				create_individual_explosion(abilityLevel, caster, targetPoint, location)
			end	
           end)
	Timers:CreateTimer(0.9, -- Start this timer 10 game-time seconds later
          function()
          	EmitSoundOn("Hero_Nevermore.Shadowraze", caster)
			for i=-2, 2, 1 do 
				targetPoint = (location+forwardVector*Vector(1400,1400,0)) + forwardVector+perp*Vector(200,200,0)*i
				create_individual_explosion(abilityLevel, caster, targetPoint, location)
			end	
           end)


end

function pattern3(forwardVector, location, ability, caster, abilityLevel)
	print("pattern3 time")
	for i = -7, 7 do
			targetPoint = (location+forwardVector*Vector(200,200,0)*i)
			create_individual_explosion(abilityLevel, caster, targetPoint, location)
	end
	for i = -7, 7 do
			local perp = perpendicularVector(forwardVector)
			targetPoint = (location+perp*Vector(200,200,0)*i)
			create_individual_explosion(abilityLevel, caster, targetPoint, location)
	end
	forwardVector = rotateVector(forwardVector, math.pi/6)
	location = caster:GetAbsOrigin()
		Timers:CreateTimer(.8, -- Start this timer 10 game-time seconds later
	          function()
	          	EmitSoundOn("Hero_Nevermore.Shadowraze", caster)
		for i = -7, 7 do
				targetPoint = (location+forwardVector*Vector(200,200,0)*i)
				create_individual_explosion(abilityLevel, caster, targetPoint, location)
		end
		for i = -7, 7 do
				local perp = perpendicularVector(forwardVector)
				targetPoint = (location+perp*Vector(200,200,0)*i)
				create_individual_explosion(abilityLevel, caster, targetPoint, location)
		end
	end)
	forwardVector = rotateVector(forwardVector, math.pi/6)
	location = caster:GetAbsOrigin()
		Timers:CreateTimer(1.6, -- Start this timer 10 game-time seconds later
	          function()
	          	EmitSoundOn("Hero_Nevermore.Shadowraze", caster)
		for i = -7, 7 do
				targetPoint = (location+forwardVector*Vector(200,200,0)*i)
				create_individual_explosion(abilityLevel, caster, targetPoint, location)
		end
		for i = -7, 7 do
				local perp = perpendicularVector(forwardVector)
				targetPoint = (location+perp*Vector(200,200,0)*i)
				create_individual_explosion(abilityLevel, caster, targetPoint, location)
		end
	end)
end

function create_individual_explosion(abilityLevel, caster, targetPoint, casterOrigin)
  	local dummy = CreateUnitByName("npc_dummy_unit", casterOrigin, true, caster, caster, caster:GetTeamNumber())
  	dummy.owner = "forest_boss"

  	dummy:AddAbility("forest_boss_aoe_explosion")
  	dummy:NoHealthBar()
  	dummy:AddAbility("dummy_unit")
  	dummy:FindAbilityByName("dummy_unit"):SetLevel(1)

  	local blast = dummy:FindAbilityByName("forest_boss_aoe_explosion")
  	blast:SetLevel(abilityLevel)
	local order =
	{
		UnitIndex = dummy:GetEntityIndex(),
		OrderType = DOTA_UNIT_ORDER_CAST_POSITION,
		AbilityIndex = blast:GetEntityIndex(),
		Position = targetPoint,
		Queue = true
	}

	ExecuteOrderFromTable(order)
	  Timers:CreateTimer(4, -- Start this timer 10 game-time seconds later
	  function()
		dummy:RemoveSelf() 
	  end)
end

function rotateVector(vector, radians)
   XX = vector.x	
   YY = vector.y
   
   Xprime = math.cos(radians)*XX -math.sin(radians)*YY
   Yprime = math.sin(radians)*XX +math.cos(radians)*YY

   vectorX = Vector(1,0,0)*Xprime
   vectorY = Vector(0,1,0)*Yprime
   rotatedVector = vectorX + vectorY
   return rotatedVector
   
end

function perpendicularVector(vector)
	x = vector.x
	y = -vector.y

	return Vector(y, x)
end

EXPLOSION_SOUND_TABLE = {"Hero_Techies.RemoteMine.Detonate", "Hero_Rattletrap.Rocket_Flare.Explode"}
EXPLOSION_PARTICLE_TABLE = {"particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_shadowraze.vpcf"}

function death_animation(keys)
	caster = keys.caster
    local particleName = EXPLOSION_PARTICLE_TABLE[RandomInt(1, 2)]
    local particleVector = caster:GetAbsOrigin()
    pfx = ParticleManager:CreateParticle( particleName, PATTACH_ABSORIGIN_FOLLOW, caster )
    ParticleManager:SetParticleControlEnt( pfx, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", particleVector, true )
    local sound = EXPLOSION_SOUND_TABLE[RandomInt(1, 2)]
    EmitSoundOn(sound, caster)
end