local att = {}
att.name = "am_magnum"
att.displayName = "Magnum rounds"
att.displayNameShort = "Magnum"

att.statModifiers = {DamageMult = 0.15,
	RecoilMult = 0.15,
	MaxSpreadIncMult = 0.2,
	SpreadPerShotMult = 0.05}

if CLIENT then
	att.displayIcon = surface.GetTextureID("atts/magnumrounds")
	att.description = {}
end

function att:attachFunc()
	self:unloadWeapon()
end

function att:detachFunc()
	self:unloadWeapon()
end

CustomizableWeaponry:registerAttachment(att)