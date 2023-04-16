AddCSLuaFile()

CustomizableWeaponry.shells = {}
CustomizableWeaponry.shells.cache = {}

-- register new shell types with this function
-- name - the name of the shell
-- model - the model of the shell
-- collideSound - table containing the collision sounds this shell should make
-- keep in mind that the shells are somewhat fake

function CustomizableWeaponry.shells:addNew(name, model, collideSound)
	self.cache[name] = {m = model, s = collideSound}
end

function CustomizableWeaponry.shells:getShell(name)
	return self.cache[name]
end

local up = Vector(0, 0, -100)
local shellMins, shellMaxs = Vector(-0.5, -0.15, -0.5), Vector(0.5, 0.15, 0.5)

function CustomizableWeaponry.shells:make(pos, ang, velocity, soundTime, removeTime)
	if not pos or not ang then
		return
	end

	CustomizableWeaponry.shells.finishMaking(self, pos, ang, velocity, soundTime, removeTime)
end

local angleVel = Vector(0, 0, 0)

function CustomizableWeaponry.shells:finishMaking(pos, ang, velocity, soundTime, removeTime)
	velocity = velocity or up
	velocity.x = velocity.x + math.Rand(-0.1, 0.1)
	velocity.y = velocity.y + math.Rand(-0.1, 0.1)
	velocity.z = velocity.z + math.Rand(-0.1, 0.1)
	
	time = math.Rand(0.4, 0.7)
	removetime = 20 or 2
	
	local t = self._shellTable or CustomizableWeaponry.shells:getShell("mainshell") -- default to the 'mainshell' shell type if there is none defined
	
	local ent = ClientsideModel(t.m, RENDERGROUP_BOTH) 
	ent:SetPos(pos)
	ent:PhysicsInitBox(shellMins, shellMaxs)
	ent:SetAngles(ang)
	ent:SetModelScale((self.ShellScale or 1), 0)
	ent:SetMoveType(MOVETYPE_VPHYSICS) 
	ent:SetSolid(SOLID_VPHYSICS) 
	ent:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	
	local phys = ent:GetPhysicsObject()
	phys:SetMaterial("gmod_silent")
	phys:SetDamping(-0.5, -2)
	phys:SetMass(0.01)
	phys:SetVelocity(velocity/math.Rand(1.5, 2))
	
	angleVel.x = math.random(-300, 300)
	angleVel.y = math.random(-300, 300)
	angleVel.z = math.random(-300, 300)
	
	phys:AddAngleVelocity(ang:Right() * 100 + angleVel)

	timer.Simple(time, function()
		if t.s and IsValid(ent) then
			sound.Play(t.s, ent:GetPos())
		end
	end)
	
	SafeRemoveEntityDelayed(ent, removetime)
end

CustomizableWeaponry:addReloadSound("CWC_SHELL_MAIN", {"shells/casings_rifle1.wav", "shells/casings_rifle2.wav", "shells/casings_rifle3.wav", "shells/casings_rifle4.wav", "shells/casings_rifle5.wav"}, 100)
CustomizableWeaponry:addReloadSound("CWC_SHELL_SMALL", {"shells/casings_pistol1.wav", "shells/casings_pistol2.wav", "shells/casings_pistol3.wav", "shells/casings_pistol4.wav"}, 100, 100, 100, 100)
CustomizableWeaponry:addReloadSound("CWC_SHELL_SHOT", {"shells/shells_12g1.wav", "shells/shells_12g2.wav", "shells/shells_12g3.wav", "shells/shells_12g4.wav", "shells/shells_12g5.wav"}, 100)
CustomizableWeaponry:addReloadSound("CWC_50CAL_SHELL", {"shells/casings_50bmg1.wav", "shells/casings_50bmg2.wav", "shells/casings_50bmg3.wav", "shells/casings_50bmg4.wav", "shells/casings_50bmg5.wav"})

CustomizableWeaponry.shells:addNew("mainshell", "models/weapons/rifleshell.mdl", "CWC_SHELL_MAIN")
CustomizableWeaponry.shells:addNew("smallshell", "models/weapons/shell.mdl", "CWC_SHELL_SMALL")
CustomizableWeaponry.shells:addNew("shotshell", "models/weapons/Shotgun_shell.mdl", "CWC_SHELL_SHOT")
CustomizableWeaponry.shells:addNew("50shell", "models/weapons/rifleshell.mdl", "CWC_50CAL_SHELL")
