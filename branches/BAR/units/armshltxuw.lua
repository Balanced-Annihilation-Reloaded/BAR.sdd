return {
	armshltxuw = {
		acceleration = 0,
		brakerate = 0,
		buildcostenergy = 54540,
		buildcostmetal = 7396,
		builder = true,
		buildinggrounddecaldecayspeed = 30,
		buildinggrounddecalsizex = 10,
		buildinggrounddecalsizey = 10,
		buildinggrounddecaltype = "armshltx_aoplane.dds",
		buildpic = "ARMSHLTXUW.DDS",
		buildtime = 61380,
		canmove = true,
		category = "ALL PLANT NOTSUB NOWEAPON NOTAIR NOTHOVER SURFACE",
		collisionVolumeScales		= [[150 43 150]],
		collisionVolumeOffsets	= [[0 10 8]],
		collisionVolumeTest	    = 1,
		collisionVolumeType	    = [[CylY]],
		corpse = "ARMSHLT_DEAD",
		description = "Produces Large Amphibious Units",
		energystorage = 1400,
		explodeas = "LARGE_BUILDINGEX",
		footprintx = 9,
		footprintz = 9,
		icontype = "building",
		idleautoheal = 5,
		idletime = 1800,
		maxdamage = 14400,
		maxslope = 18,
		maxwaterdepth = 160,
		metalstorage = 800,
		minwaterdepth = 30,
		name = "Experimental Gantry",
		objectname = "ARMSHLTX.s3o",
		script = "armshltx.cob",
		script = "armshltx.cob",
		seismicsignature = 0,
		selfdestructas = "LARGE_BUILDING",
		sightdistance = 273,
		terraformspeed = 3000,
		usebuildinggrounddecal = true,
		workertime = 600,
		yardmap = "oooooooooooooooooooocccccoooocccccoooocccccoooocccccoooocccccoooocccccoooocccccoo",
		buildoptions = {
			[1] = "armbanth",
			[2] = "marauder",
			--[3] = "armlun",
			[3] = "armcroc",
		},
		customparams = {
			normalmaps = "yes",
			normaltex = "unittextures/Arm_normals.dds",
		},
		featuredefs = {
			armshlt_dead = {
				blocking = true,
				category = "corpses",
				collisionvolumeoffsets = "0 -14 0",
				collisionvolumescales = "125 57 145",
				collisionvolumetest = 1,
				collisionvolumetype = "Ell",
				damage = 8640,
				description = "Experimental Gantry Wreckage",
				energy = 0,
				featuredead = "ARMSHLT_HEAP",
				featurereclamate = "SMUDGE01",
				footprintx = 9,
				footprintz = 9,
				height = 20,
				hitdensity = 100,
				metal = 4807,
				object = "ARMSHLTX_DEAD.s3o",
				reclaimable = true,
				seqnamereclamate = "TREE1RECLAMATE",
				world = "All Worlds",
			},
			armshlt_heap = {
				blocking = false,
				category = "heaps",
				damage = 4320,
				description = "Experimental Gantry Heap",
				energy = 0,
				featurereclamate = "SMUDGE01",
				footprintx = 9,
				footprintz = 9,
				height = 4,
				hitdensity = 100,
				metal = 1923,
				object = "arm7X7B.s3o",
				reclaimable = true,
				resurrectable = 0,
				seqnamereclamate = "TREE1RECLAMATE",
				world = "All Worlds",
			},
		},
		sfxtypes = {
			explosiongenerators = {
				[1] = "custom:YellowLight",
			},
		},
		sounds = {
			activate = "gantok2",
			build = "gantok2",
			canceldestruct = "cancel2",
			deactivate = "gantok2",
			repair = "lathelrg",
			underattack = "warning1",
			unitcomplete = "gantok1",
			working = "build",
			count = {
				[1] = "count6",
				[2] = "count5",
				[3] = "count4",
				[4] = "count3",
				[5] = "count2",
				[6] = "count1",
			},
			select = {
				[1] = "gantsel1",
			},
		},
	},
}
