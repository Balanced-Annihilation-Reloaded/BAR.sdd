return {
	armcybr = {
		acceleration = 0.13,
		brakerate = 0.05,
		buildcostenergy = 43062,
		buildcostmetal = 2243,
		buildpic = "ARMCYBR.DDS",
		buildtime = 56203,
		canfly = true,
		canmove = true,
		category = "ALL WEAPON NOTSUB VTOL NOTHOVER",
		collide = false,
		cruisealt = 150,
		description = "Atomic Bomber",
		energyuse = 40,
		explodeas = "SMALL_BUILDING",
		firestate = 0,
		footprintx = 3,
		footprintz = 3,
		icontype = "air",
		idleautoheal = 5,
		idletime = 1800,
		maxdamage = 2050,
		maxslope = 10,
		maxvelocity = 10.35,
		maxwaterdepth = 0,
		name = "Liche",
		noautofire = false,
		nochasecategory = "VTOL",
		objectname = "ARMCYBR.s3o",
		seismicsignature = 0,
		selfdestructas = "BIG_UNITEX",
		sightdistance = 455,
		turnrate = 535,
		customparams = {
			faction = "arm",
			normalmaps = "yes",
			normaltex = "unittextures/Arm_normals.dds",
		},
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
			arm_pidr = {
				areaofeffect = 256,
				avoidfeature = false,
				avoidfriendly = false,
				collidefriendly = false,
				commandfire = true,
				craterareaofeffect = 256,
				craterboost = 0,
				cratermult = 0,
				edgeeffectiveness = 0.5,
				explosiongenerator = "custom:mininuke",
				firestarter = 100,
				flighttime = 1.5,
				impulseboost = 0.123,
				impulsefactor = 2,
				model = "catapultmissile.s3o",
				name = "PlasmaImplosionDumpRocket",
				noselfdamage = true,
				range = 250,
				reloadtime = 9,
				smoketrail = true,
				soundhit = "tonukeex",
				soundhitwet = "splslrg",
				soundhitwetvolume = 0.5,
				soundstart = "bombdropxx",
				startvelocity = 200,
				targetable = 0,
				tolerance = 16000,
				tracks = false,
				turnrate = 32768,
				weaponacceleration = 40,
				weapontimer = 6,
				weapontype = "MissileLauncher",
				weaponvelocity = 400,
				damage = {
					commanders = 3350,
					default = 5625,
					subs = 5,
				},
			},
		},
		weapons = {
			[1] = {
				badtargetcategory = "VTOL",
				def = "ARM_PIDR",
				onlytargetcategory = "SURFACE",
			},
		},
	},
}
