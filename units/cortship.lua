return {
	cortship = {
		acceleration = 0.061999998986721,
		brakerate = 0.08500000089407,
		buildangle = 16384,
		buildcostenergy = 4786,
		buildcostmetal = 887,
		buildpic = "CORTSHIP.DDS",
		buildtime = 13663,
		canattack = false,
		canmove = true,
		category = "ALL NOTLAND MOBILE WEAPON SHIP NOTSUB NOTAIR NOTHOVER SURFACE",
		collisionvolumeoffsets = "0 9 -2",
		collisionvolumescales = "39 81 111",
		collisionvolumetest = 1,
		collisionvolumetype = "CylY",
		corpse = "DEAD",
		description = "Armored Transport",
		energymake = 0.30000001192093,
		energyuse = 0.30000001192093,
		explodeas = "BIG_UNITEX",
		floater = true,
		footprintx = 6,
		footprintz = 6,
		icontype = "sea",
		idleautoheal = 5,
		idletime = 1800,
		maxdamage = 11420,
		maxvelocity = 3.2200000286102,
		minwaterdepth = 12,
		movementclass = "DBOAT6",
		name = "Envoy",
		nochasecategory = "ALL",
		objectname = "CORTSHIP.s3o",
		seismicsignature = 0,
		selfdestructas = "BIG_UNIT",
		sightdistance = 325,
		transportcapacity = 40,
		transportsize = 4,
		turnrate = 373,
		waterline = 6,
		windgenerator = 0.0010000000474975,
		customparams = {
			normalmaps = "yes",
			normaltex = "unittextures/Core_normal.tga",
		},
		featuredefs = {
			dead = {
				blocking = false,
				category = "corpses",
				collisionvolumeoffsets = "0.0 -3.80138675537 -0.0",
				collisionvolumescales = "66.6000061035 64.2990264893 117.277526855",
				collisionvolumetype = "Box",
				damage = 6852,
				description = "Envoy Wreckage",
				energy = 0,
				featuredead = "HEAP",
				footprintx = 5,
				footprintz = 5,
				height = 4,
				hitdensity = 100,
				metal = 577,
				object = "CORTSHIP_DEAD",
				reclaimable = true,
				seqnamereclamate = "TREE1RECLAMATE",
				world = "All Worlds",
			},
			heap = {
				blocking = false,
				category = "heaps",
				damage = 2016,
				description = "Envoy Heap",
				energy = 0,
				footprintx = 2,
				footprintz = 2,
				height = 4,
				hitdensity = 100,
				metal = 291,
				object = "5X5A",
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
				[1] = "shcormov",
			},
			select = {
				[1] = "shcorsel",
			},
		},
	},
}
