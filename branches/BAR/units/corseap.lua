return {
	corseap = {
		acceleration = 0.3120000064373,
		brakerate = 4.75,
		buildcostenergy = 6785,
		buildcostmetal = 234,
		buildpic = "CORSEAP.DDS",
		buildtime = 13698,
		canfly = true,
		canmove = true,
		cansubmerge = true,
		category = "ALL NOTLAND MOBILE WEAPON ANTIGATOR VTOL ANTIFLAME ANTIEMG ANTILASER NOTSUB NOTSHIP NOTHOVER",
		collide = false,
		cruisealt = 100,
		description = "Torpedo Seaplane",
		energymake = 0.69999998807907,
		energyuse = 0.69999998807907,
		explodeas = "BIG_UNITEX",
		footprintx = 3,
		footprintz = 3,
		icontype = "air",
		idleautoheal = 5,
		idletime = 1800,
		maxdamage = 1660,
		maxslope = 10,
		maxvelocity = 8.8699998855591,
		maxwaterdepth = 255,
		name = "Typhoon",
		nochasecategory = "VTOL",
		objectname = "CORSEAP.s3o",
		seismicsignature = 0,
		selfdestructas = "BIG_UNIT",
		sightdistance = 455,
		turnrate = 575,
		customparams = {
			normalmaps = "yes",
			normaltex = "unittextures/Core_normal.tga",
		},
		sounds = {
			build = "nanlath1",
			canceldestruct = "cancel2",
			repair = "repair1",
			underattack = "warning1",
			working = "reclaim1",
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
				[1] = "vtolcrmv",
			},
			select = {
				[1] = "seapsel2",
			},
		},
		weapondefs = {
			armseap_weapon1 = {
				areaofeffect = 16,
				avoidfriendly = false,
				burnblow = true,
				collidefriendly = false,
				craterboost = 0,
				cratermult = 0,
				explosiongenerator = "custom:FLASH2",
				impulseboost = 0.12300000339746,
				impulsefactor = 0.12300000339746,
				model = "torpedo",
				name = "TorpedoLauncher",
				noselfdamage = true,
				range = 500,
				reloadtime = 8,
				soundhit = "xplodep2",
				soundstart = "bombrel",
				startvelocity = 100,
				tolerance = 12000,
				tracks = true,
				turnrate = 25000,
				turret = false,
				waterweapon = true,
				weaponacceleration = 15,
				weapontimer = 5,
				weapontype = "TorpedoLauncher",
				weaponvelocity = 100,
				damage = {
					default = 960,
				},
			},
		},
		weapons = {
			[1] = {
				badtargetcategory = "NOTSHIP",
				def = "ARMSEAP_WEAPON1",
				onlytargetcategory = "NOTHOVER",
			},
		},
	},
}
