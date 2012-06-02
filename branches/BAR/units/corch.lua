return {
	corch = {
		acceleration = 0.059999998658895,
		brakerate = 0.061999998986721,
		buildcostenergy = 2771,
		buildcostmetal = 154,
		builddistance = 128,
		builder = true,
		buildpic = "CORCH.DDS",
		buildtime = 4576,
		canhover = true,
		canmove = true,
		category = "ALL HOVER MOBILE NOTSUB NOWEAPON NOTSHIP NOTAIR SURFACE",
		collisionvolumeoffsets = "0 1 0",
		collisionvolumescales = "24 12 32",
		collisionvolumetest = 1,
		collisionvolumetype = "CylY",
		corpse = "DEAD",
		description = "Tech Level 1",
		energymake = 11,
		energystorage = 75,
		energyuse = 11,
		explodeas = "BIG_UNITEX",
		footprintx = 3,
		footprintz = 3,
		idleautoheal = 5,
		idletime = 1800,
		maxdamage = 1341,
		maxslope = 16,
		maxvelocity = 2.2999999523163,
		maxwaterdepth = 0,
		metalmake = 0.10999999940395,
		metalstorage = 75,
		movementclass = "HOVER3",
		name = "Construction Hovercraft",
		objectname = "CORCH.s3o",
		radardistance = 50,
		seismicsignature = 0,
		selfdestructas = "BIG_UNIT",
		sightdistance = 338,
		terraformspeed = 550,
		turnrate = 410,
		workertime = 110,
		buildoptions = {
			[10] = "corlab",
			[11] = "corvp",
			[12] = "corap",
			[13] = "corhp",
			[14] = "cornanotc",
			[15] = "coreyes",
			[16] = "corrad",
			[17] = "cordrag",
			[18] = "cormaw",
			[19] = "corllt",
			[1] = "corsolar",
			[20] = "hllt",
			[21] = "corhlt",
			[22] = "corpun",
			[23] = "corrl",
			[24] = "madsam",
			[25] = "corerad",
			[26] = "cordl",
			[27] = "corjamt",
			[28] = "cjuno",
			[29] = "corfhp",
			[2] = "coradvsol",
			[30] = "corsy",
			[31] = "cortide",
			[32] = "coruwmex",
			[33] = "corfmkr",
			[34] = "coruwms",
			[35] = "coruwes",
			[36] = "csubpen",
			[37] = "corsonar",
			[38] = "corfdrag",
			[39] = "corfrad",
			[3] = "corwin",
			[40] = "corfhlt",
			[41] = "corfrt",
			[42] = "cortl",
			[4] = "corgeo",
			[5] = "cormstor",
			[6] = "corestor",
			[7] = "cormex",
			[8] = "corexp",
			[9] = "cormakr",
		},
		customparams = {
			normalmaps = "yes",
			normaltex = "unittextures/Core_normal.tga",
		},
		featuredefs = {
			dead = {
				blocking = false,
				category = "corpses",
				collisionvolumeoffsets = "-0.331680297852 0.27175427002 0.101982116699",
				collisionvolumescales = "30.3070983887 10.39112854 31.9606170654",
				collisionvolumetype = "Box",
				damage = 805,
				description = "Construction Hovercraft Wreckage",
				energy = 0,
				featuredead = "HEAP",
				footprintx = 3,
				footprintz = 3,
				height = 20,
				hitdensity = 100,
				metal = 100,
				object = "CORCH_DEAD",
				reclaimable = true,
				seqnamereclamate = "TREE1RECLAMATE",
				world = "All Worlds",
			},
			heap = {
				blocking = false,
				category = "heaps",
				damage = 403,
				description = "Construction Hovercraft Heap",
				energy = 0,
				footprintx = 3,
				footprintz = 3,
				height = 4,
				hitdensity = 100,
				metal = 40,
				object = "cor3X3D.s3o",
				reclaimable = true,
				seqnamereclamate = "TREE1RECLAMATE",
				world = "All Worlds",
			},
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
				[1] = "hovmdok2",
			},
			select = {
				[1] = "hovmdsl2",
			},
		},
	},
}
