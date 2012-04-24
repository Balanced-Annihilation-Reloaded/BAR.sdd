return {
	corasy = {
		acceleration = 0,
		brakerate = 0,
		buildcostenergy = 10763,
		buildcostmetal = 3345,
		builder = true,
		buildpic = "CORASY.DDS",
		buildtime = 15696,
		canmove = true,
		category = "ALL PLANT NOTLAND NOWEAPON NOTSUB NOTSHIP NOTAIR NOTHOVER",
		collisionvolumeoffsets = "0 10 -2",
		collisionvolumescales = "186 78 183",
		collisionvolumetest = 1,
		collisionvolumetype = "Box",
		corpse = "DEAD",
		description = "Produces Level 2 Ships",
		energystorage = 200,
		explodeas = "LARGE_BUILDINGEX",
		footprintx = 12,
		footprintz = 12,
		icontype = "building",
		idleautoheal = 5 ,
		idletime = 1800 ,
		maxdamage = 4416,
		metalmake = 1,
		metalstorage = 200,
		minwaterdepth = 30,
		name = "Advanced Shipyard",
		objectname = "CORASY.s3o",
		customParams ={
			normaltex = "unittextures/Core_normal.tga",
			normalmaps = "yes",
		},
		radardistance = 50,
		seismicsignature = 0,
		selfdestructas = "LARGE_BUILDING",
		sightdistance = 301.60000610352,
		terraformspeed = 1000,
		waterline = 12,
		workertime = 400,
		yardmap = "wCCCCCCCCCCwCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCwCCCCCCCCCCw",
		buildoptions = {
			[1] = "coracsub",
			[2] = "cormls",
			[3] = "correcl",
			[4] = "corshark",
			[5] = "corssub",
			[6] = "corarch",
			[7] = "corcrus",
			[8] = "corbats",
			[9] = "cormship",
			[10] = "corblackhy",
			[11] = "corcarry",
			[12] = "corsjam",
		},
		featuredefs = {
			dead = {
				blocking = false,
				category = "corpses",
				collisionvolumeoffsets = "0 -13 -3",
				collisionvolumescales = "192 61 180",
				collisionvolumetest = 1,
				collisionvolumetype = "Box",
				damage = 2650,
				description = "Advanced Shipyard Wreckage",
				energy = 0,
				footprintx = 12,
				footprintz = 12,
				height = 4,
				hitdensity = 100,
				metal = 2174,
				object = "CORASY_DEAD.s3o",
				reclaimable = true,
				seqnamereclamate = "TREE1RECLAMATE",
				world = "All Worlds",
			},
		},
		sfxtypes = {
			explosiongenerators = {
				[1] = "custom:WhiteLight",
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
