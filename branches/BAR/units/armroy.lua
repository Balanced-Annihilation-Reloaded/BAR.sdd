return {
	armroy = {
		acceleration = 0.054000001400709,
		activatewhenbuilt = true,
		brakerate = 0.12999999523163,
		buildangle = 16384,
		buildcostenergy = 5671,
		buildcostmetal = 987,
		buildpic = "ARMROY.DDS",
		buildtime = 13391,
		canmove = true,
		category = "ALL NOTLAND MOBILE WEAPON NOTSUB SHIP NOTAIR NOTHOVER SURFACE",
		collisionvolumeoffsets = "0 -16 -2",
		collisionvolumescales = "32 48 78",
		collisionvolumetest = 1,
		collisionvolumetype = "CylY",
		corpse = "DEAD",
		description = "Destroyer",
		energymake = 2,
		energyuse = 2,
		explodeas = "BIG_UNITEX",
		floater = true,
		footprintx = 3,
		footprintz = 3,
		icontype = "sea",
		idleautoheal = 5,
		idletime = 1800,
		maxdamage = 2575,
		maxvelocity = 3.3399999141693,
		minwaterdepth = 12,
		movementclass = "BOAT4",
		name = "Crusader",
		nochasecategory = "VTOL",
		objectname = "ARMROY",
		seismicsignature = 0,
		selfdestructas = "BIG_UNIT",
		sightdistance = 490,
		sonardistance = 400,
		turnrate = 199,
		waterline = 4.5,
		windgenerator = 0.0010000000474975,
		featuredefs = {
			dead = {
				blocking = false,
				category = "corpses",
				collisionvolumeoffsets = "0.164245605469 8.02001953204e-06 -0.56591796875",
				collisionvolumescales = "31.5542297363 37.44581604 80.6425476074",
				collisionvolumetype = "Box",
				damage = 1545,
				description = "Crusader Wreckage",
				energy = 0,
				featuredead = "HEAP",
				footprintx = 5,
				footprintz = 5,
				height = 4,
				hitdensity = 100,
				metal = 558,
				object = "ARMROY_DEAD",
				reclaimable = true,
				seqnamereclamate = "TREE1RECLAMATE",
				world = "All Worlds",
			},
			heap = {
				blocking = false,
				category = "heaps",
				damage = 2016,
				description = "Crusader Heap",
				energy = 0,
				footprintx = 2,
				footprintz = 2,
				height = 4,
				hitdensity = 100,
				metal = 234,
				object = "5X5B",
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
				[1] = "sharmmov",
			},
			select = {
				[1] = "sharmsel",
			},
		},
		weapondefs = {
			arm_roy = {
				areaofeffect = 32,
				craterboost = 0,
				cratermult = 0,
				explosiongenerator = "custom:FLASH3",
				gravityaffected = "true",
				impulseboost = 0.12300000339746,
				impulsefactor = 0.12300000339746,
				name = "HeavyCannon",
				noselfdamage = true,
				range = 700,
				reloadtime = 1.3999999761581,
				soundhit = "xplomed2",
				soundstart = "cannon3",
				turret = true,
				weapontype = "Cannon",
				weaponvelocity = 307.40850830078,
				damage = {
					bombers = 41,
					default = 160,
					fighters = 41,
					subs = 5,
					vtol = 41,
				},
			},
			depthcharge = {
				areaofeffect = 32,
				avoidfriendly = false,
				burnblow = true,
				collidefriendly = false,
				craterboost = 0,
				cratermult = 0,
				edgeeffectiveness = 0.99000000953674,
				explosiongenerator = "custom:FLASH2",
				impulseboost = 0.12300000339746,
				impulsefactor = 0.12300000339746,
				model = "DEPTHCHARGE",
				name = "DepthCharge",
				noselfdamage = true,
				range = 400,
				reloadtime = 2.5,
				soundhit = "xplodep2",
				soundstart = "torpedo1",
				startvelocity = 100,
				tolerance = 1000,
				tracks = true,
				turnrate = 1700,
				turret = true,
				waterweapon = true,
				weaponacceleration = 15,
				weapontimer = 3,
				weapontype = "TorpedoLauncher",
				weaponvelocity = 100,
				damage = {
					default = 210,
				},
			},
		},
		weapons = {
			[1] = {
				def = "ARM_ROY",
				onlytargetcategory = "SURFACE",
			},
			[2] = {
				def = "DEPTHCHARGE",
				onlytargetcategory = "NOTHOVER",
			},
		},
	},
}
