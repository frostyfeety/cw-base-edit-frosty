local att = {}
att.name = "am_luckylast"
att.displayName = "Lucky Last Round"
att.displayNameShort = "Lucky"

att.statModifiers ={
DamageMult = -0.25,
RecoilMult = 0}

if CLIENT then
	att.displayIcon = surface.GetTextureID("atts/luckylastrounds")
	att.description = {{t = "Quintruples the damage of your last round in the magazine.", c = CustomizableWeaponry.textColors.POSITIVE}}
end

function att:attachFunc()
	self:unloadWeapon()	
end

function att:detachFunc()
	self:unloadWeapon()
end

CustomizableWeaponry:registerAttachment(att)