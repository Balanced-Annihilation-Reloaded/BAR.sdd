return {
	armfrt = {
		acceleration = 0,
		activatewhenbuilt = true,
		airsightdistance = 750,
		brakerate = 0,
		buildangle = 16384,
		buildcostenergy = 1053,
		buildcostmetal = 91,
		buildpic = "ARMFRT.DDS",
		buildtime = 2163,
		category = "ALL NOTLAND WEAPON NOTSUB NOTSHIP NOTAIR NOTHOVER SURFACE",
		collisionvolumeoffsets = "0 15 0",
		collisionvolumescales = "36 59 36",
		collisionvolumetype = "CylY",
		corpse = "DEAD",
		description = "Floating Anti-air Tower",
		energyuse = 0.1,
		explodeas = "BIG_UNITEX",
		footprintx = 4,
		footprintz = 4,
		icontype = "building",
		idleautoheal = 5,
		idletime = 1800,
		maxdamage = 340,
		minwaterdepth = 2,
		name = "Sentry",
		nochasecategory = "ALL",
		objectname = "ARMFRT.s3o",
		seismicsignature = 0,
		selfdestructas = "BIG_UNIT",
		sightdistance = 468,
		waterline = 0,
		yardmap = "wwwwwwwwwwwwwwww",
		customparams = {
			normalmaps = "yes",
			normaltex = "unittextures/Arm_normals.dds",
		},
		featuredefs = {
			dead = {
				blocking = false,
				category = "corpses",
				collisionvolumeoffsets = "0.10124206543 -0.0500075439453 1.15520477295",
				collisionvolumescales = "41.2024536133 67.0857849121 50.3104095459",
				collisionvolumetype = "Box",
				damage = 151,
				description = "Sentry Wreckage",
				energy = 0,
				footprintx = 3,
				footprintz = 3,
				height = 40,
				hitdensity = 100,
				metal = 46,
				object = "armfrt_dead.s3o",
				reclaimable = true,
				seqnamereclamate = "TREE1RECLAMATE",
				world = "All Worlds",
			},
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
				[1] = "kbarmmov",
			},
			select = {
				[1] = "kbarmsel",
			},
		},
		weapondefs = {
			armrl_missile = {
				areaofeffect = 64,
				avoidfeature = false,
				canattackground = false,
				craterareaofeffect = 0,
				craterboost = 0,
				cratermult = 0,
				edgeeffectiveness = 0.6,
				explosiongenerator = "custom:FLASH2",
				firestarter = 70,
				flighttime = 3,
				impulseboost = 0.123,
				impulsefactor = 0.123,
				metalpershot = 0,
				model = "cormissile.s3o",
				name = "Missiles",
				noselfdamage = true,
				proximitypriority = 1,
				range = 765,
				reloadtime = 1.2,
				smoketrail = true,
				soundhit = "xplomed2",
				soundhitwet = "splssml",
				soundhitwetvolume = 0.5,
				soundstart = "rockhvy2",
				startvelocity = 400,
				texture2 = "armsmoketrail",
				tolerance = 10000,
				tracks = true,
				turnrate = 63000,
				turret = true,
				weaponacceleration = 150,
				weapontimer = 5,
				weapontype = "MissileLauncher",
				weaponvelocity = 750,
				damage = {
					default = 125,
					subs = 5,
				},
			},
		},
		weapons = {
			[1] = {
				badtargetcategory = "NOTAIR LIGHTAIRSCOUT",
				def = "ARMRL_MISSILE",
				onlytargetcategory = "VTOL",
			},
		},
	},
}
