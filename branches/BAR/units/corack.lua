return {
	corack = {
		acceleration = 0.2039999961853,
		brakerate = 0.42500001192093,
		buildcostenergy = 5428,
		buildcostmetal = 319,
		builddistance = 136,
		builder = true,
		buildpic = "CORACK.DDS",
		buildtime = 9709,
		canmove = true,
		category = "KBOT MOBILE ALL NOTSUB NOWEAPON NOTSHIP NOTAIR NOTHOVER SURFACE",
		collisionvolumeoffsets = "0 -1 0",
		collisionvolumescales = "22 33 25",
		collisionvolumetest = 1,
		collisionvolumetype = "Box",
		corpse = "DEAD",
		description = "Tech Level 2",
		energymake = 14,
		energystorage = 100,
		energyuse = 14,
		explodeas = "BIG_UNITEX",
		footprintx = 2,
		footprintz = 2,
		idleautoheal = 5,
		idletime = 1800,
		maxdamage = 900,
		maxslope = 20,
		maxvelocity = 1.1000000238419,
		maxwaterdepth = 25,
		metalmake = 0.14000000059605,
		metalstorage = 100,
		movementclass = "KBOT2",
		name = "Advanced Construction Kbot",
		objectname = "CORACK",
		radardistance = 50,
		seismicsignature = 0,
		selfdestructas = "BIG_UNIT",
		sightdistance = 318.5,
		terraformspeed = 900,
		turnrate = 935,
		upright = true,
		workertime = 180,
		buildoptions = {
			[10] = "corarad",
			[11] = "corshroud",
			[12] = "corfort",
			[13] = "corasp",
			[14] = "cortarg",
			[15] = "corsd",
			[16] = "corgate",
			[17] = "cortoast",
			[18] = "corvipe",
			[19] = "cordoom",
			[1] = "corfus",
			[20] = "corflak",
			[21] = "screamer",
			[22] = "cortron",
			[23] = "corfmd",
			[24] = "corsilo",
			[25] = "corint",
			[26] = "corbuzz",
			[27] = "corlab",
			[28] = "coralab",
			[2] = "corgant",
			[3] = "cmgeo",
			[4] = "corbhmth",
			[5] = "cormoho",
			[6] = "cormexp",
			[7] = "cormmkr",
			[8] = "coruwadves",
			[9] = "coruwadvms",
		},
		featuredefs = {
			dead = {
				blocking = true,
				category = "corpses",
				collisionvolumeoffsets = "0.0 -1.11450195313e-05 -6.82949829102",
				collisionvolumescales = "22.0 23.11277771 24.3265991211",
				collisionvolumetype = "Box",
				damage = 540,
				description = "Advanced Construction Kbot Wreckage",
				energy = 0,
				featuredead = "HEAP",
				featurereclamate = "SMUDGE01",
				footprintx = 2,
				footprintz = 2,
				height = 20,
				hitdensity = 100,
				metal = 207,
				object = "CORACK_DEAD",
				reclaimable = true,
				seqnamereclamate = "TREE1RECLAMATE",
				world = "All Worlds",
			},
			heap = {
				blocking = false,
				category = "heaps",
				damage = 270,
				description = "Advanced Construction Kbot Heap",
				energy = 0,
				featurereclamate = "SMUDGE01",
				footprintx = 2,
				footprintz = 2,
				height = 4,
				hitdensity = 100,
				metal = 83,
				object = "2X2B",
				reclaimable = true,
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
