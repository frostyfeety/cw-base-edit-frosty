AddCSLuaFile()

CustomizableWeaponry.quickGrenade = CustomizableWeaponry.quickGrenade or {}

-- set this to 'false' to disable quick grenade functionality
CustomizableWeaponry.quickGrenade.enabled = true

-- the weapon action delay after throwing a grenade and re-equipping the weapon
CustomizableWeaponry.quickGrenade.postGrenadeWeaponDelay = 0.2
CustomizableWeaponry.quickGrenade.throwVelocity = 800
CustomizableWeaponry.quickGrenade.addVelocity = Vector(0, 0, 150) -- additional velocity independant from any factors
CustomizableWeaponry.quickGrenade.movementAddVelocity = 600 -- how much additional direction based velocity the grenade will receive based on the player's movement speed

CustomizableWeaponry.quickGrenade.canDropLiveGrenadeIfKilled = true
CustomizableWeaponry.quickGrenade.liveGrenadeVelocity = 100
CustomizableWeaponry.quickGrenade.liveGrenadeAddVelocity = Vector(0, 0, 20)
CustomizableWeaponry.quickGrenade.unthrownGrenadesGiveWeapon = false

-- func is called from the SWEP base	
function CustomizableWeaponry.quickGrenade:initializeQuickGrenade()
	if not self.enabled then
		return
	end
	
	-- this table defines in which states the player can't use the 'quick grenade' feature
	self.restrictedStates = {[CW_RUNNING] = true, 
		[CW_ACTION] = true,
		[CW_CUSTOMIZE] = true}
end

local td = {}

function CustomizableWeaponry.quickGrenade:getThrowOffset(player)
	local aimDir = player:EyeAngles() -- EyeAngles():Forward() because GetAimVector works in a retarded manner
	
	return aimDir:Up() * -3 + aimDir:Forward() * 30 + aimDir:Right() * 3
end

function CustomizableWeaponry.quickGrenade:getThrowVelocity(playerEnt, throwVelocity, addVelocity)
	throwVelocity = throwVelocity or self.throwVelocity
	addVelocity = addVelocity or self.addVelocity
	
	local forward = playerEnt:EyeAngles():Forward()
	local overallSideMod = playerEnt:KeyDown(IN_SPEED) and 2 or 1

	-- take the velocity into account
	addMod = math.Clamp(playerEnt:GetVelocity():Length() / playerEnt:GetRunSpeed(), 0, 1)
	
	local velocity = forward * throwVelocity + addVelocity
	local velNorm = playerEnt:GetVelocity():GetNormal()
	velNorm.z = 0
	
	-- add velocity based on player velocity normal
	velocity = velocity + velNorm * self.movementAddVelocity * addMod
	
	return velocity
end

function CustomizableWeaponry.quickGrenade:applyThrowVelocity(playerEnt, nade, throwVelocity, addVelocity)
	local phys = nade:GetPhysicsObject()
	
	if IsValid(phys) then
		local vel = self:getThrowVelocity(playerEnt, throwVelocity, addVelocity)
		
		phys:SetVelocity(vel)
		phys:AddAngleVelocity(Vector(math.random(-500, 500), math.random(-500, 500), math.random(-500, 500)))
	end
end

function CustomizableWeaponry.quickGrenade:canThrow()
	-- it's disabled, can't throw
	if not CustomizableWeaponry.quickGrenade.enabled then
		return false
	end
	
	-- can't throw if we're within a restricted state
	if CustomizableWeaponry.quickGrenade.restrictedStates[self.dt.State] then
		return false
	end
	
	-- can't throw while reloading
	if self.ReloadDelay then
		return false
	end
	
	-- can't throw with an active bipod
	if self.dt.BipodDeployed then
		return false
	end
	
	-- can't throw while changing weapons
	if self.HolsterDelay then
		return false
	end
	
	-- can't throw with no grenades
	if self.Owner:GetAmmoCount("Frag Grenades") <= 0 then
		return false
	end
	
	-- can't throw the grenade if we're really close to an object
	td.start = self.Owner:GetShootPos()
	td.endpos = td.start + CustomizableWeaponry.quickGrenade:getThrowOffset(self)
	td.filter = self.Owner
	
	local tr = util.TraceLine(td)
	
	-- something in front of us, can't throw
	if tr.Hit then
		return false
	end
	
	-- everything passes, can throw, woo!
	return true
end

local pinPullAnims = {"pullpin", "pullpin2", "pullpin3", "pullpin4"}
local pinQuickPullAnims = {"pullpin_quick"}
local SP = game.SinglePlayer()

function CustomizableWeaponry.quickGrenade:createThrownGrenade(player)
	local pos = player:GetShootPos()
	local offset = CustomizableWeaponry.quickGrenade:getThrowOffset(player)
	local eyeAng = player:EyeAngles()
	local forward = eyeAng:Forward()
	
	local nade = ents.Create("cw_grenade_thrown")
	nade:SetPos(pos + offset)
	nade:SetAngles(eyeAng)
	nade:Spawn()
	nade:Activate()
	nade:Fuse(3)
	nade:SetOwner(player)
	
	return nade
end

function CustomizableWeaponry.quickGrenade:createUnthrownGrenade(player)
	local pos = player:GetShootPos()
	local offset = CustomizableWeaponry.quickGrenade:getThrowOffset(player)
	local eyeAng = player:EyeAngles()
	local forward = eyeAng:Forward()
	
	local nade = ents.Create("cw_grenade_unthrown") -- it's inactive and can be picked up as ammo
	nade:SetPos(pos + offset)
	nade:SetAngles(eyeAng)
	nade:Spawn()
	nade:Activate()
	
	return nade
end

function CustomizableWeaponry.quickGrenade:throw()
		
		if self.LoseAimVelocity and self.Owner:OnGround() and self.Owner:KeyDown(IN_SPEED) then
			timerholster = 1.7
			CustomizableWeaponry.quickGrenade.throwVelocity = 2000
			CustomizableWeaponry.quickGrenade.movementAddVelocity = -900
		else
			timerholster = 1.3
			CustomizableWeaponry.quickGrenade.throwVelocity = 700
			CustomizableWeaponry.quickGrenade.movementAddVelocity = 300
		end
		
	local CT = CurTime()
	self:setGlobalDelay(timerholster)
	self:SetNextPrimaryFire(CT + timerholster)
	
	if SERVER and SP then
		SendUserMessage("CW20_THROWGRENADE", self.Owner)
	end
	
	self.dt.State = CW_ACTION
	
	if (not SP and IsFirstTimePredicted()) or SP then
		if self:filterPrediction() then
			self:EmitSound("CWC_HOLSTER")
			self:EmitSound("CWC_FOLEY_HEAVY")
			self.Owner:ViewPunch(Angle (-1, math.Rand(-0.5, -1), math.Rand(1, -1)))
		end
		
		CustomizableWeaponry.callbacks.processCategory(self, "beginThrowGrenade")
		
			
		
		if CLIENT then
			if self.LoseAimVelocity and self.Owner:OnGround() and self.Owner:KeyDown(IN_SPEED) then
				CustomizableWeaponry.actionSequence.new(self, 0.2, nil, function()
					self.GrenadePos.z = -35
					self.grenadeTime = CurTime() + timerholster
					self:playAnim(table.Random(pinPullAnims), 1.1, 0, self.CW_GREN)
				end)

				CustomizableWeaponry.actionSequence.new(self, 0.25, nil, function()
					surface.PlaySound("weapons/cw_foley/CWC/jiggle_light_"..math.random(1,10)..".wav")
					surface.PlaySound("weapons/cwc_grenade/pinpull_start.wav")
				end)
				
				CustomizableWeaponry.actionSequence.new(self, 0.4, nil, function()
					surface.PlaySound("weapons/cwc_grenade/pinpull.wav")
					self.GrenadePos.y = 500
				end)
				
				CustomizableWeaponry.actionSequence.new(self, 0.95, nil, function()
					self:playAnim("throw", 1, 0, self.CW_GREN)
				end)
				
				CustomizableWeaponry.actionSequence.new(self, 1.0, nil, function()
					surface.PlaySound("weapons/cwc_grenade/ntoss"..math.random(1,3)..".wav")
					surface.PlaySound("weapons/cwc_grenade/spoon.wav")
					self.GrenadePos.z = -5
					self.GrenadePos.x = -10
					self.Owner:SetAnimation(PLAYER_ATTACK1)
					self:playAnim("throw", 0.7, 0.8, self.CW_GREN)
				end)
			else
				CustomizableWeaponry.actionSequence.new(self, 0.2, nil, function()
					self.GrenadePos.z = -35
					self.grenadeTime = CurTime() + timerholster
					self:playAnim(table.Random(pinQuickPullAnims), 1.5, 0, self.CW_GREN)
				end)

				CustomizableWeaponry.actionSequence.new(self, 0.1, nil, function()
					surface.PlaySound("weapons/cw_foley/CWC/jiggle_light_"..math.random(1,10)..".wav")
					surface.PlaySound("weapons/cwc_grenade/pinpull_start.wav")
				end)
				
				CustomizableWeaponry.actionSequence.new(self, 0.3, nil, function()
					surface.PlaySound("weapons/cwc_grenade/pinpull.wav")
				end)
				
				CustomizableWeaponry.actionSequence.new(self, 0.65, nil, function()
					surface.PlaySound("weapons/cwc_grenade/ntoss"..math.random(1,3)..".wav")
					self.Owner:SetAnimation(PLAYER_ATTACK1)
				end)
				
				CustomizableWeaponry.actionSequence.new(self, 0.7, nil, function()
					self.GrenadePos.z = -1
					self.GrenadePos.y = -10
					self.GrenadePos.x = -10
					surface.PlaySound("weapons/cwc_grenade/spoon.wav")
					self:playAnim("throw_quick", 1.1, 0, self.CW_GREN)
				end)
				
				CustomizableWeaponry.actionSequence.new(self, 0.85, nil, function()
					surface.PlaySound("weapons/cw_foley/foley_toss"..math.random(1,4)..".wav")
				end)
				
				CustomizableWeaponry.actionSequence.new(self, 1.0, nil, function()
					surface.PlaySound("weapons/cw_foley/CWC/jiggle_light_"..math.random(1,10)..".wav")
				end)
			end
		end
		
		if SERVER then
				
			if self.LoseAimVelocity and self.Owner:OnGround() and self.Owner:KeyDown(IN_SPEED) then
				CustomizableWeaponry.actionSequence.new(self, 0.1, nil, function()
					self.Owner:ViewPunch(Angle (01.1 ,0, 0))
				end)
			
				CustomizableWeaponry.actionSequence.new(self, 0.3, nil, function()
					self.Owner:ViewPunch(Angle (-0.2 ,0, 0))
					self.canDropGrenade = true
					self.liveGrenade = true
				end)

				CustomizableWeaponry.actionSequence.new(self, 0.4, nil, function()
					self.Owner:ViewPunch(Angle (-1 ,-1.5, 2))
				end)
				
				CustomizableWeaponry.actionSequence.new(self, 0.75, nil, function()
					self.Owner:ViewPunch(Angle (-1 , -3, 3))
				end)
				CustomizableWeaponry.actionSequence.new(self, 0.8, nil, function()
					self.Owner:ViewPunch(Angle (-1 , -3, 3))
				end)
				CustomizableWeaponry.actionSequence.new(self, 0.85, nil, function()
					self.Owner:ViewPunch(Angle (-1 , -3, 3))
				end)
				CustomizableWeaponry.actionSequence.new(self, 0.9, nil, function()
					self.Owner:ViewPunch(Angle (-1 , -3, 3))
				end)

				CustomizableWeaponry.actionSequence.new(self, 1, nil, function()
					self.Owner:ViewPunch(Angle (7 , 9, -3))
				end)
			
				CustomizableWeaponry.actionSequence.new(self, 1.05, nil, function()
					self.Owner:ViewPunch(Angle (4 , 9, -3))
					local nade = CustomizableWeaponry.quickGrenade:createThrownGrenade(self.Owner)
					CustomizableWeaponry.quickGrenade:applyThrowVelocity(self.Owner, nade, throwVelocity, addVelocity)
					
					self.liveGrenade = false
					self.canDropGrenade = false
					self.Owner:RemoveAmmo(1, "Frag Grenades")
					
					CustomizableWeaponry.callbacks.processCategory(self, "finishThrowGrenade")
				end)

				CustomizableWeaponry.actionSequence.new(self, 1.1, nil, function()
					self.Owner:ViewPunch(Angle (4 , 1, -3))
				end)
			else
			
				CustomizableWeaponry.actionSequence.new(self, 0.1, nil, function()
					self.Owner:ViewPunch(Angle (01.1 ,0, 0))
				end)
			
				CustomizableWeaponry.actionSequence.new(self, 0.3, nil, function()
					self.Owner:ViewPunch(Angle (-0.2 ,0, 0))
					self.canDropGrenade = true
				end)

				CustomizableWeaponry.actionSequence.new(self, 0.4, nil, function()
					self.Owner:ViewPunch(Angle (-1 ,-1.5, 2))
				end)
				
				CustomizableWeaponry.actionSequence.new(self, 0.5, nil, function()
					self.Owner:ViewPunch(Angle (-0.2 ,-1, 1))
					self.liveGrenade = true
				end)

				CustomizableWeaponry.actionSequence.new(self, 0.7, nil, function()
					self.Owner:ViewPunch(Angle (2 , 8, -3))
				end)
			
				CustomizableWeaponry.actionSequence.new(self, 0.8, nil, function()
					local nade = CustomizableWeaponry.quickGrenade:createThrownGrenade(self.Owner)
					CustomizableWeaponry.quickGrenade:applyThrowVelocity(self.Owner, nade, throwVelocity, addVelocity)
					
					self.liveGrenade = false
					self.canDropGrenade = false
					self.Owner:RemoveAmmo(1, "Frag Grenades")
					
					CustomizableWeaponry.callbacks.processCategory(self, "finishThrowGrenade")
				end)
			end
		end
			
			CustomizableWeaponry.actionSequence.new(self, timerholster, nil, function()
			local delay = CustomizableWeaponry.quickGrenade.postGrenadeWeaponDelay
			self:EmitSound("CWC_FOLEY_MEDIUM")
			self:SetNextPrimaryFire(CT + delay)
			self:SetNextSecondaryFire(CT + delay)
		end)
	end
end

function CustomizableWeaponry.quickGrenade.DoPlayerDeathCallback(victim, attacker, dmginfo)
	local wep = victim:GetActiveWeapon()
	
	if IsValid(wep) and wep.CW20Weapon then
		if wep.canDropGrenade then
			local nade = nil
			local throwVel, addVel = nil, nil
			
			if wep.liveGrenade then
				nade = CustomizableWeaponry.quickGrenade:createThrownGrenade(victim)
			else
				nade = CustomizableWeaponry.quickGrenade:createUnthrownGrenade(victim) 
			end
			
			CustomizableWeaponry.quickGrenade:applyThrowVelocity(victim, nade, CustomizableWeaponry.quickGrenade.liveGrenadeVelocity, CustomizableWeaponry.quickGrenade.liveGrenadeAddVelocity)
		end
	end
end

hook.Add("DoPlayerDeath", "CustomizableWeaponry.quickGrenade.DoPlayerDeathCallback", CustomizableWeaponry.quickGrenade.DoPlayerDeathCallback)