local att = {}
att.name = "am_matchgrade"
att.displayName = "Match grade rounds"
att.displayNameShort = "Match"

att.statModifiers = {AimSpreadMult = -0.3,
	SpreadPerShotMult = -0.12,
	SpreadCooldownMult = 0.1,
	DamageMult = -0.05,
	RecoilMult = -0.1}

if CLIENT then
	att.displayIcon = surface.GetTextureID("atts/matchgradeammo")
	att.description = {}
end

function att:attachFunc()
	self:unloadWeapon()
end

function att:detachFunc()
	self:unloadWeapon()
end

CustomizableWeaponry:registerAttachment(att)