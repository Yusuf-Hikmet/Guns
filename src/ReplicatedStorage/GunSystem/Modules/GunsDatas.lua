local GunsDatas = {
	M4A1 = {
		Name = "M4A1",
		Damage = 15	,
		FireRate = .075,
		MagSize = 30,
		Ammo = 120,
		ReloadTime = 3.7, 
		Range = 250,
		
		AmmoPriceOf1 = 3,
		Price = 2000,
		maxHRPDist = 6.2,
		Spread = Vector2.new(),
		SpreadIncrease = .05,
		SpreadDecrease = .01,
		SpreadMax = .2,
		SpreadMin = -.2,
		FireModes = {
			"Auto",
			"Semi"
		},
		Recoil = {
			X = .03,
			Y = .02,
		},
		DamageMultipliers = {
			Head = 2,
			Torso = 1,
			Arms = .8,
			Legs = .5
		},
		ADS = { -- Aim Down Sights
			Zoom = 40,
			Time = 0.6,
			AimCFX = -.44,
			AimCFY = .24,
			AimCFZ = .5,
			TP = {
				AimCFX = -.44,
				AimCFY = .24,
				AimCFZ = -.1
			}
		},
	},
	Deagle = {
		Name = "Deagle",
		Damage = 45,
		FireRate = .2,
		MagSize = 7,
		Ammo = 28,
		ReloadTime = 3.9, 
		Range = 325,
		
		AmmoPriceOf1 = 15,
		Price = 1500,
		maxHRPDist = 6.5,
		Spread = Vector2.new(),
		SpreadIncrease = .02,
		SpreadDecrease = .005,
		SpreadMin = -.2,
		SpreadMax = .2,
		
		FireModes = {
			"Semi"
		},
		Recoil = {
			X = .05,
			Y = .01,
		},
		DamageMultipliers = {
			Head = 2,
			Torso = 1,
			Arms = .8,
			Legs = .5
		},
		ADS = {
			Zoom = 40,
			Time = .4,
			AimCFX = -1,
			AimCFY = .40,
			AimCFZ = .5,
			TP = {
				AimCFX = -.4,
				AimCFY = .35,
				AimCFZ = .1
			}
		}
	},
	Remington700 = {
		Name = "Remington700",
		Damage = 60,
		FireRate = 1.25,
		MagSize = 5,
		Ammo = 10,
		ReloadTime = 2.266666,
		Range = 900,
		
		AmmoPriceOf1 = 33,
		Price = 2500,
		maxHRPDist = 9.25,
		Spread = Vector2.new(),
		SpreadIncrease = .002,
		SpreadDecrease = .01,
		SpreadMin = -.1,
		SpreadMax = .1,

		FireModes = {
			"Semi"
		},
		Recoil = {
			X = .1,
			Y = .05,
		},
		DamageMultipliers = {
			Head = 2,
			Torso = 1,
			Arms = .8,
			Legs = .5
		},
		ADS = {
			Zoom = 10,
			Time = 1,
			AimCFX = 0, -- -.61
			AimCFY = 0, -- 0.36
			AimCFZ = 0, -- 0
			TP = {
				AimCFX = -.4,
				AimCFY = .35,
				AimCFZ = .1
			}
		}
	},
	Remington870 = {
		Name = "Remington870",
		Damage = 15,
		GaugeBuckshot = 7,
		FireRate = 1.3,
		MagSize = 5,
		Ammo = 15,
		ReloadTime = 3.200,
		Range = 70,
		AmmoPriceOf1 = 20,
		Price = 1750,
		
		maxHRPDist = 8.85,
		Spread = Vector2.new(),
		SpreadIncrease = .06,
		SpreadDecrease = .02,
		SpreadMin = -.3,
		SpreadMax = .3,

		FireModes = {
			"Pump"
		},
		Recoil = {
			X = .1,
			Y = .05,
		},
		DamageMultipliers = {
			Head = 2,
			Torso = 1,
			Arms = .8,
			Legs = .5
		},
		ADS = {
			Zoom = 50,
			Time = 0.2,
			AimCFX = -.6125,
			AimCFY = .7, 
			AimCFZ = 1.2, 
			TP = {
				AimCFX = -.5,
				AimCFY = .35,
				AimCFZ = -.4
			}
		}
	}
}

return GunsDatas
