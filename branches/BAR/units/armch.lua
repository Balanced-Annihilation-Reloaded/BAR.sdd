return {
	armch = {
		acceleration = 0.144,
		brakerate = 0.45,
		buildcostenergy = 2691,
		buildcostmetal = 145,
		builddistance = 112,
		builder = true,
		buildpic = "ARMCH.DDS",
		buildtime = 4472,
		canhover = true,
		canmove = true,
		category = "ALL HOVER MOBILE NOTSUB NOWEAPON NOTSHIP NOTAIR SURFACE",
		corpse = "DEAD",
		description = "Level 1 Construction Hovercraft",
		energymake = 11,
		energystorage = 75,
		energyuse = 11,
		explodeas = "BIG_UNITEX",
		footprintx = 3,
		footprintz = 3,
		idleautoheal = 5,
		idletime = 1800,
		maxdamage = 1296,
		maxslope = 16,
		maxvelocity = 2.53,
		maxwaterdepth = 0,
		metalmake = 0.11,
		metalstorage = 75,
		movementclass = "HOVER3",
		name = "Construction Hovercraft",
		objectname = "ARMCH.s3o",
		radardistance = 50,
		seismicsignature = 0,
		selfdestructas = "BIG_UNIT",
		sightdistance = 351,
		terraformspeed = 550,
		turninplace = 1,
		turninplaceanglelimit = 60,
		turninplacespeedlimit = 1.6698,
		turnrate = 425,
		workertime = 110,
		buildoptions = {
			[1] = "armsolar",
			[2] = "armadvsol",
			[3] = "armwin",
			[4] = "armgeo",
			[5] = "armmstor",
			[6] = "armestor",
			[7] = "armmex",
			[8] = "armamex",
			[9] = "armmakr",
			[10] = "armlab",
			[11] = "armvp",
			[12] = "armap",
			[13] = "armhp",
			[14] = "armnanotc",
			[15] = "armeyes",
			[16] = "armrad",
			[17] = "armdrag",
			[18] = "armclaw",
			[19] = "armllt",
			[20] = "tawf001",
			[21] = "armhlt",
			[22] = "armguard",
			[23] = "armrl",
			[24] = "packo",
			[25] = "armcir",
			[26] = "armdl",
			[27] = "armjamt",
			[28] = "ajuno",
			[29] = "armfhp",
			[30] = "armsy",
			[31] = "armtide",
			[32] = "armuwmex",
			[33] = "armfmkr",
			[34] = "armuwms",
			[35] = "armuwes",
			[36] = "asubpen",
			[37] = "armsonar",
			[38] = "armfdrag",
			[39] = "armfrad",
			[40] = "armfhlt",
			[41] = "armfrt",
			[42] = "armtl",
		},
		customparams = {
			normalmaps = "yes",
			normaltex = "unittextures/Arm_normals.dds",
		},
		featuredefs = {
			dead = {
				blocking = false,
				category = "corpses",
				collisionvolumeoffsets = "0.0 -1.56249816895 0.0184326171875",
				collisionvolumescales = "24.4295043945 10.1600036621 29.846862793",
				collisionvolumetype = "Box",
				damage = 778,
				description = "Construction Hovercraft Wreckage",
				energy = 0,
				featuredead = "HEAP",
				footprintx = 3,
				footprintz = 3,
				height = 20,
				hitdensity = 100,
				metal = 88,
				object = "armch_dead.s3o",
				reclaimable = true,
				seqnamereclamate = "TREE1RECLAMATE",
				world = "All Worlds",
			},
			heap = {
				blocking = false,
				category = "heaps",
				damage = 389,
				description = "Construction Hovercraft Heap",
				energy = 0,
				footprintx = 3,
				footprintz = 3,
				height = 4,
				hitdensity = 100,
				metal = 35,
				object = "arm3x3a.s3o",
				reclaimable = true,
				resurrectable = 0,
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
				[1] = "hovmdok1",
			},
			select = {
				[1] = "hovmdsl1",
			},
		},
	},
}