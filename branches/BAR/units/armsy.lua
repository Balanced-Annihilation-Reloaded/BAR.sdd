return {
	armsy = {
		acceleration = 0,
		brakerate = 0,
		buildcostenergy = 827,
		buildcostmetal = 453,
		builder = true,
		buildpic = "ARMSY.DDS",
		buildtime = 6050,
		canmove = true,
		category = "ALL PLANT NOTLAND NOTSUB NOWEAPON NOTSHIP NOTAIR NOTHOVER SURFACE",
		corpse = "DEAD",
		description = "Produces Level 1 Ships",
		energymake = 15,
		energystorage = 125,
		explodeas = "LARGE_BUILDINGEX",
		footprintx = 8,
		footprintz = 8,
		icontype = "building",
		idleautoheal = 5,
		idletime = 1800,
		maxdamage = 3700,
		metalmake = 0.5,
		metalstorage = 125,
		minwaterdepth = 30,
		name = "Shipyard",
		objectname = "ARMSY.s3o",
		radardistance = 50,
		seismicsignature = 0,
		selfdestructas = "LARGE_BUILDING",
		sightdistance = 340,
		terraformspeed = 500,
		waterline = 0,
		workertime = 220,
		yardmap = "oyyyyyyoyccccccyyccccccyyccccccyyccccccyyccccccyyccccccyoyyyyyyo",
		buildoptions = {
			[1] = "armcs",
			[2] = "armpt",
			[3] = "decade",
			[4] = "armroy",
			[5] = "armtship",
			[6] = "armsub",
			[7] = "armrecl",
		},
		customparams = {
			faction = "arm",
			normalmaps = "yes",
			normaltex = "unittextures/Arm_normals.dds",
		},
		featuredefs = {
			dead = {
				blocking = false,
				category = "corpses",
				collisionvolumeoffsets = "-2 -2 -3",
				collisionvolumescales = "116 52 116",
				collisionvolumetest = 1,
				collisionvolumetype = "Box",
				damage = 1794,
				description = "Shipyard Wreckage",
				energy = 0,
				footprintx = 7,
				footprintz = 7,
				height = 4,
				hitdensity = 100,
				metal = 400,
				object = "armsy_dead.s3o",
				reclaimable = true,
				seqnamereclamate = "TREE1RECLAMATE",
				world = "All Worlds",
				customparams = {
					faction = "arm",
				},
			},
		},
		sfxtypes = {
			explosiongenerators = {
				[1] = "custom:YellowLight",
			},
		},
		sounds = {
			canceldestruct = "cancel2",
			underattack = "warning1",
			unitcomplete = "untdone",
			count = {
				[1] = "count6",
				[2] = "count5",
				[3] = "count4",
				[4] = "count3",
				[5] = "count2",
				[6] = "count1",
			},
			select = {
				[1] = "pshpactv",
			},
		},
	},
}
