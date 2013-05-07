return {
	armkam = {
		acceleration = 0.15399999916553,
		brakerate = 3.75,
		buildcostenergy = 2226,
		buildcostmetal = 125,
		buildpic = "ARMKAM.DDS",
		buildtime = 5046,
		canfly = true,
		canmove = true,
		category = "ALL WEAPON NOTSUB VTOL NOTHOVER",
		collide = false,
		cruisealt = 60,
		description = "Light Gunship",
		energyuse = 0.80000001192093,
		explodeas = "BIG_UNITEX",
		footprintx = 2,
		footprintz = 2,
		hoverattack = true,
		icontype = "air",
		idleautoheal = 5,
		idletime = 1800,
		maxdamage = 435,
		maxslope = 10,
		maxvelocity = 6.1599998474121,
		maxwaterdepth = 0,
		name = "Banshee",
		nochasecategory = "VTOL",
		objectname = "ARMKAM",
		seismicsignature = 0,
		selfdestructas = "BIG_UNIT",
		sightdistance = 520,
		turnrate = 693,
		sounds = {
			canceldestruct = "cancel2",
			underattack = "warning1",
			cant = {
				[1] = "cantdo4",
			},
			count = {
				[1] = "count6",
				[2] = "count5",
				[3] = "count4",
				[4] = "count3",
				[5] = "count2",
				[6] = "count1",
			},
			ok = {
				[1] = "vtolarmv",
			},
			select = {
				[1] = "vtolarac",
			},
		},
		weapondefs = {
			med_emg = {
				areaofeffect = 8,
				burst = 3,
				burstrate = 0.25,
				craterboost = 0,
				cratermult = 0,
				explosiongenerator = "custom:BRAWLIMPACTS",
				impulseboost = 0.12300000339746,
				impulsefactor = 0.12300000339746,
				intensity = 0.80000001192093,
				name = "E.M.G.",
				noselfdamage = true,
				range = 350,
				reloadtime = 0.69999998807907,
				rgbcolor = "1 0.95 0.4",
				size = 2.25,
				soundstart = "brawlemg",
				sprayangle = 1024,
				tolerance = 6000,
				turret = false,
				weapontimer = 1,
				weapontype = "Cannon",
				weaponvelocity = 350,
				damage = {
					bombers = 1,
					commanders = 5,
					default = 9,
					fighters = 1,
					subs = 1,
					vtol = 1,
				},
			},
		},
		weapons = {
			[1] = {
				badTargetCategory = "VTOL",
				def = "MED_EMG",
				onlytargetcategory = "SURFACE",
			},
		},
	},
}
