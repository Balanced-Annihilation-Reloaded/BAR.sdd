return {
	armbanth = {
		acceleration = 0.103,
		airsightdistance = 1100,
		brakerate = 0.654,
		buildcostenergy = 285812,
		buildcostmetal = 13537,
		buildpic = "ARMBANTH.DDS",
		buildtime = 276057,
		canmove = true,
		category = "KBOT WEAPON ALL NOTSUB NOTAIR NOTHOVER SURFACE",
		corpse = "DEAD",
		description = "Assault Mech",
		energymake = 12,
		energystorage = 120,
		explodeas = "BANTHA_DEATH",
		footprintx = 3,
		footprintz = 3,
		idleautoheal = 25,
		idletime = 900,
		mass = 999999995904,
		maxdamage = 62000,
		maxslope = 17,
		maxvelocity = 1.65,
		maxwaterdepth = 12,
		movementclass = "VKBOT3",
		name = "Bantha",
		nochasecategory = "VTOL",
		objectname = "ARMBANTHA.s3o",
		pushresistant = true,
		seismicsignature = 0,
		selfdestructas = "BANTHA_NUKE",
		selfdestructcountdown = 10,
		sightdistance = 617,
		turninplaceanglelimit = 140,
		turninplacespeedlimit = 1.089,
		turnrate = 1056,
		upright = true,
		customparams = {
			normalmaps = "yes",
			normaltex = "unittextures/Arm_normals.dds",
			paralyzemultiplier = 0.5,
		},
		featuredefs = {
			dead = {
				blocking = true,
				category = "corpses",
				collisionvolumeoffsets = "4.18798065186 -1.60430091553 -4.70808410645",
				collisionvolumescales = "64.8059539795 21.2949981689 66.8361816406",
				collisionvolumetype = "Box",
				damage = 21000,
				description = "Bantha Wreckage",
				energy = 0,
				featuredead = "HEAP",
				featurereclamate = "SMUDGE01",
				footprintx = 3,
				footprintz = 3,
				height = 20,
				hitdensity = 100,
				metal = 8249,
				object = "armbanth_dead.s3o",
				reclaimable = true,
				seqnamereclamate = "TREE1RECLAMATE",
				world = "All Worlds",
			},
			heap = {
				blocking = false,
				category = "heaps",
				damage = 10500,
				description = "Bantha Heap",
				energy = 0,
				featurereclamate = "SMUDGE01",
				footprintx = 3,
				footprintz = 3,
				height = 4,
				hitdensity = 100,
				metal = 3300,
				object = "arm3x3a.s3o",
				reclaimable = true,
				resurrectable = 0,
				seqnamereclamate = "TREE1RECLAMATE",
				world = "All Worlds",
			},
		},
		sfxtypes = {
			explosiongenerators = {
				[1] = "custom:BANTHAMUZZLE",
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
				[1] = "krogok1",
			},
			select = {
				[1] = "krogsel1",
			},
		},
		weapondefs = {
			armbantha_fire = {
				accuracy = 100,
				areaofeffect = 64,
				avoidfeature = false,
				burnblow = true,
				cegtag = "banthablaster",
				craterareaofeffect = 0,
				craterboost = 0,
				cratermult = 0,
				explosiongenerator = "custom:FLASHBANTHA",
				impulseboost = 0,
				impulsefactor = 0,
				intensity = 4,
				name = "ImpulsionBlaster",
				noselfdamage = true,
				proximitypriority = 1,
				range = 465,
				reloadtime = 0.7,
				rgbcolor = "0.05 0.05 1",
				size = 1,
				soundhit = "xplosml3",
				soundhitwet = "sizzle",
				soundhitwetvolume = 0.5,
				soundstart = "Lasrhvy2",
				tolerance = 10000,
				turret = true,
				weapontype = "LaserCannon",
				weaponvelocity = 400,
				damage = {
					default = 365,
					subs = 5,
				},
			},
			bantha_rocket = {
				areaofeffect = 96,
				avoidfeature = false,
				canattackground = false,
				craterareaofeffect = 96,
				craterboost = 0,
				cratermult = 0,
				explosiongenerator = "custom:STARFIRE",
				firestarter = 70,
				impulseboost = 0.123,
				impulsefactor = 0.123,
				model = "corkbmissl1.s3o",
				name = "HeavyRockets",
				noselfdamage = true,
				proximitypriority = -1,
				range = 800,
				reloadtime = 2.75,
				smoketrail = true,
				soundhit = "xplosml2",
				soundhitwet = "splsmed",
				soundhitwetvolume = 0.5,
				soundstart = "rapidrocket3",
				startvelocity = 200,
				targetable = 0,
				texture2 = "armsmoketrail",
				tolerance = 9000,
				tracks = true,
				turnrate = 50000,
				weaponacceleration = 150,
				weapontimer = 0.35,
				weapontype = "StarburstLauncher",
				weaponvelocity = 2100,
				damage = {
					default = 360,
					subs = 5,
				},
			},
			tehlazerofdewm = {
				areaofeffect = 14,
				avoidfeature = false,
				beamtime = 1.05,
				corethickness = 0.5,
				craterareaofeffect = 0,
				craterboost = 0,
				cratermult = 0,
				energypershot = 100,
				explosiongenerator = "custom:BURN_WHITE",
				impulseboost = 0,
				impulsefactor = 0,
				laserflaresize = 12,
				name = "DEEEEEEEEEEEEEWWWWWMMMM",
				noselfdamage = true,
				range = 800,
				reloadtime = 5,
				rgbcolor = "0.2 0.2 1",
				soundhitdry = "",
				soundhitwet = "sizzle",
				soundhitwetvolume = 0.5,
				soundstart = "annigun1",
				soundtrigger = 1,
				targetmoveerror = 0.2,
				thickness = 4,
				tolerance = 10000,
				turret = true,
				weapontype = "BeamLaser",
				weaponvelocity = 1500,
				damage = {
					commanders = 1200,
					default = 4000,
					subs = 5,
				},
			},
		},
		weapons = {
			[1] = {
				badtargetcategory = "VTOL",
				def = "ARMBANTHA_FIRE",
				onlytargetcategory = "NOTSUB",
			},
			[2] = {
				badtargetcategory = "VTOL GROUNDSCOUT",
				def = "TEHLAZEROFDEWM",
				onlytargetcategory = "NOTSUB",
			},
			[3] = {
				badtargetcategory = "VTOL GROUNDSCOUT",
				def = "BANTHA_ROCKET",
				onlytargetcategory = "NOTSUB",
			},
		},
	},
}
