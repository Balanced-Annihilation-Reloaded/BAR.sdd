return {
	corck = {
		acceleration = 0.456,
		brakerate = 2.85,
		buildcostenergy = 1730,
		buildcostmetal = 121,
		builddistance = 130,
		builder = true,
		buildpic = "CORCK.DDS",
		buildtime = 3551,
		canmove = true,
		category = "KBOT MOBILE ALL NOTSUB NOWEAPON NOTSHIP NOTAIR NOTHOVER SURFACE",
		corpse = "DEAD",
		description = "Construction Kbot",
		energymake = 7,
		energystorage = 50,
		energyuse = 7,
		explodeas = "BIG_UNITEX",
		footprintx = 2,
		footprintz = 2,
		idleautoheal = 5,
		idletime = 1800,
		maxdamage = 590,
		maxslope = 20,
		maxvelocity = 1.15,
		maxwaterdepth = 25,
		metalmake = 0.07,
		metalstorage = 50,
		movementclass = "KBOT2",
		name = "Ratchet",
		objectname = "CORCK.s3o",
		seismicsignature = 0,
		selfdestructas = "BIG_UNIT",
		sightdistance = 299,
		terraformspeed = 450,
		turninplace = 1,
		turninplaceanglelimit = 60,
		turninplacespeedlimit = 0.759,
		turnrate = 1045,
		upright = true,
		workertime = 80,
		buildoptions = {
			[1] = "corsolar",
			[2] = "coradvsol",
			[3] = "corwin",
			[4] = "corgeo",
			[5] = "cormstor",
			[6] = "corestor",
			[7] = "cormex",
			[8] = "corexp",
			[9] = "cormakr",
			[10] = "coralab",
			[11] = "corlab",
			[12] = "corvp",
			[13] = "corap",
			[14] = "corhp",
			[15] = "cornanotc",
			[16] = "coreyes",
			[17] = "corrad",
			[18] = "cordrag",
			[19] = "cormaw",
			[20] = "corllt",
			[21] = "hllt",
			[22] = "corhlt",
			[23] = "corpun",
			[24] = "corrl",
			[25] = "madsam",
			[26] = "corerad",
			[27] = "cordl",
			[28] = "corjamt",
			[29] = "cjuno",
			[30] = "corsy",
		},
		customparams = {
			normalmaps = "yes",
			normaltex = "unittextures/Core_normal.dds",
		},
		featuredefs = {
			dead = {
				blocking = true,
				category = "corpses",
				collisionvolumeoffsets = "-0.363754272461 2.60498046867e-05 -3.98596954346",
				collisionvolumescales = "23.7274780273 30.2996520996 30.1248321533",
				collisionvolumetype = "Box",
				damage = 354,
				description = "Construction Kbot Wreckage",
				energy = 0,
				featuredead = "HEAP",
				featurereclamate = "SMUDGE01",
				footprintx = 2,
				footprintz = 2,
				height = 20,
				hitdensity = 100,
				metal = 73,
				object = "CORCK_DEAD.s3o",
				reclaimable = true,
				seqnamereclamate = "TREE1RECLAMATE",
				world = "All Worlds",
			},
			heap = {
				blocking = false,
				category = "heaps",
				damage = 177,
				description = "Construction Kbot Heap",
				energy = 0,
				featurereclamate = "SMUDGE01",
				footprintx = 2,
				footprintz = 2,
				height = 4,
				hitdensity = 100,
				metal = 29,
				object = "cor2x2f.s3o",
				reclaimable = true,
				resurrectable = 0,
				seqnamereclamate = "TREE1RECLAMATE",
				world = "All Worlds",
			},
		},
		sounds = {
			build = "nanlath2",
			canceldestruct = "cancel2",
			capture = "capture2",
			repair = "repair2",
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
				[1] = "kbcormov",
			},
			select = {
				[1] = "kbcorsel",
			},
		},
	},
}