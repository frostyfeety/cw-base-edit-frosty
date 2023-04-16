local att = {}
att.name = "am_slugrounds"
att.displayName = "Slug rounds"
att.displayNameShort = "Slug"

att.statModifiers = {DamageMult = 5,
	AimSpreadMult = 1}

if CLIENT then
	att.displayIcon = surface.GetTextureID("atts/slugrounds")
	att.description = {{t = "Deals massive damage with no spread", c = CustomizableWeaponry.textColors.POSITIVE},
	{t = "Only fires one projectile.", c = CustomizableWeaponry.textColors.NEGATIVE}}
end

function att:attachFunc()
	self.Shots = 1
	self.ClumpSpread = nil
	self:unloadWeapon()
end

function att:detachFunc()
	self.Shots = self.Shots_Orig
	self.ClumpSpread = self.ClumpSpread_Orig
	self:unloadWeapon()
end

CustomizableWeaponry:registerAttachment(att)