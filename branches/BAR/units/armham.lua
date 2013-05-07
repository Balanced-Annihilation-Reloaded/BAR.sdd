return {
	armham = {
		acceleration = 0.11999999731779,
		brakerate = 0.22499999403954,
		buildcostenergy = 1231,
		buildcostmetal = 121,
		buildpic = "ARMHAM.DDS",
		buildtime = 2210,
		canmove = true,
		category = "KBOT MOBILE WEAPON ALL NOTSUB NOTSHIP NOTAIR NOTHOVER SURFACE",
		collisionVolumeScales		= [[29 28 29]],
		collisionVolumeOffsets	= [[0 -2 -3]],
		collisionVolumeTest	    = 1,
		collisionVolumeType	    = [[CylY]],
		corpse = "DEAD",
		description = "Light Plasma Kbot",
		energymake = 0.60000002384186,
		energyuse = 0.60000002384186,
		explodeas = "BIG_UNITEX",
		footprintx = 2,
		footprintz = 2,
		idleautoheal = 5,
		idletime = 1800,
		mass = 300,
		maxdamage = 810,
		maxslope = 14,
		maxvelocity = 1.539999961853,
		maxwaterdepth = 12,
		movementclass = "KBOT2",
		name = "Hammer",
		nochasecategory = "VTOL",
		objectname = "ARMHAM",
		seismicsignature = 0,
		selfdestructas = "BIG_UNIT",
		sightdistance = 380,
		turnrate = 1094,
		upright = true,
		featuredefs = {
			dead = {
				blocking = true,
				category = "corpses",
				collisionvolumeoffsets = "1.85908508301 -3.40689422363 2.59911346436",
				collisionvolumescales = "31.0182495117 8.18759155273 36.3284454346",
				collisionvolumetype = "Box",
				damage = 486,
				description = "Hammer Wreckage",
				energy = 0,
				featuredead = "HEAP",
				featurereclamate = "SMUDGE01",
				footprintx = 2,
				footprintz = 2,
				height = 40,
				hitdensity = 100,
				metal = 79,
				object = "ARMHAM_DEAD",
				reclaimable = true,
				seqnamereclamate = "TREE1RECLAMATE",
				world = "All Worlds",
			},
			heap = {
				blocking = false,
				category = "heaps",
				damage = 243,
				description = "Hammer Heap",
				energy = 0,
				featurereclamate = "SMUDGE01",
				footprintx = 2,
				footprintz = 2,
				height = 4,
				hitdensity = 100,
				metal = 32,
				object = "2X2E",
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
			arm_ham = {
				areaofeffect = 36,
				craterboost = 0,
				cratermult = 0,
				explosiongenerator = "custom:LIGHT_PLASMA",
				gravityaffected = "true",
				impulseboost = 0.12300000339746,
				impulsefactor = 0.12300000339746,
				name = "PlasmaCannon",
				noselfdamage = true,
				predictboost = 0.40000000596046,
				range = 380,
				reloadtime = 1.75,
				soundhit = "xplomed3",
				soundstart = "cannon1",
				turret = true,
				weapontype = "Cannon",
				weaponvelocity = 286,
				damage = {
					bombers = 21,
					default = 104,
					fighters = 21,
					subs = 5,
					vtol = 21,
				},
			},
		},
		weapons = {
			[1] = {
				badtargetcategory = "VTOL",
				def = "ARM_HAM",
				onlytargetcategory = "NOTSUB",
			},
		},
	},
}
