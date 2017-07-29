return {
	armjam = {
		acceleration = 0.035,
		activatewhenbuilt = true,
		brakerate = 0.036,
		buildcostenergy = 1729,
		buildcostmetal = 103,
		buildpic = "ARMJAM.DDS",
		buildtime = 5933,
		canattack = false,
		canmove = true,
		category = "ALL TANK MOBILE NOTSUB NOWEAPON NOTSHIP NOTAIR NOTHOVER SURFACE",
		corpse = "dead",
		description = "Radar Jammer Vehicle",
		energymake = 16,
		energyuse = 100,
		explodeas = "BIG_UNITEX",
		footprintx = 3,
		footprintz = 3,
		idleautoheal = 5,
		idletime = 1800,
		leavetracks = true,
		maxdamage = 460,
		maxslope = 16,
		maxvelocity = 1.2,
		maxwaterdepth = 0,
		movementclass = "TANK3",
		name = "Jammer",
		nochasecategory = "MOBILE",
		objectname = "ARMJAM.s3o",
		onoffable = true,
		radardistance = 0,
		radardistancejam = 450,
		selfdestructas = "BIG_UNIT",
		sightdistance = 300,
		trackoffset = 8,
		trackstrength = 10,
		tracktype = "StdTank",
		trackwidth = 22,
		turninplace = 0,
		turninplaceanglelimit = 140,
		turninplacespeedlimit = 0.792,
		turnrate = 505,
		customparams = {
			faction = "arm",
			normalmaps = "yes",
			normaltex = "unittextures/Arm_normals.dds",
		},
		featuredefs = {
			dead = {
				blocking = true,
				category = "corpses",
				collisionvolumeoffsets = "-1.99268341064 -6.74999977051 3.60781097412",
				collisionvolumescales = "23.7459869385 3.61972045898 31.9999847412",
				collisionvolumetype = "Box",
				damage = 400,
				description = "Jammer Wreckage",
				featuredead = "HEAP",
				featurereclamate = "SMUDGE01",
				footprintx = 3,
				footprintz = 3,
				height = 20,
				hitdensity = 100,
				metal = 78,
				object = "armjam_dead.s3o",
				reclaimable = true,
				seqnamereclamate = "TREE1RECLAMATE",
				world = "All Worlds",
				customparams = {
					faction = "arm",
				},
			},
			heap = {
				blocking = false,
				category = "heaps",
				damage = 368,
				description = "Jammer Heap",
				featurereclamate = "SMUDGE01",
				footprintx = 3,
				footprintz = 3,
				height = 4,
				hitdensity = 100,
				metal = 39,
				object = "arm3x3b.s3o",
				reclaimable = true,
				resurrectable = 0,
				seqnamereclamate = "TREE1RECLAMATE",
				world = "All Worlds",
				customparams = {
					faction = "arm",
				},
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
				[1] = "varmmove",
			},
			select = {
				[1] = "radjam1",
			},
		},
	},
}
