return {
	armuwadvms = {
		buildangle = 5049,
		buildcostenergy = 10493,
		buildcostmetal = 705,




		buildpic = "ARMUWADVMS.DDS",
		buildtime = 20391,
		category = "ALL NOTSUB NOWEAPON NOTAIR NOTHOVER SURFACE",
		collisionvolumeoffsets = "0 0 0",
		collisionvolumescales = "88 38 72",
		collisionvolumetest = 1,
		collisionvolumetype = "Box",
		corpse = "DEAD",
		description = "Increases Metal Storage (10000)",
		explodeas = "LARGE_BUILDINGEX",
		footprintx = 4,
		footprintz = 4,
		icontype = "building",
		idleautoheal = 5,
		idletime = 1800,
		maxdamage = 9300,
		maxslope = 20,
		maxwaterdepth = 9999,
		metalstorage = 10000,
		name = "Hardened Metal Storage",
		objectname = "ARMUWADVMS.s3o",
		seismicsignature = 0,
		selfdestructas = "LARGE_BUILDING",
		sightdistance = 195,

		yardmap = "oooooooooooooooo",
		customparams = {
			normalmaps = "yes",
			normaltex = "unittextures/Arm_normals.dds",
		},
		featuredefs = {
			dead = {
				blocking = true,
				category = "corpses",
				collisionvolumeoffsets = "7.62939453125e-06 -3.51196289046e-05 -0.0",
				collisionvolumescales = "45.1519927979 49.1111297607 45.1520080566",
				collisionvolumetype = "Box",
				damage = 3720,
				description = "Advanced Metal Storage Wreckage",
				energy = 0,
				featuredead = "HEAP",
				featurereclamate = "SMUDGE01",
				footprintx = 4,
				footprintz = 4,
				height = 9,
				hitdensity = 100,
				metal = 458,
				object = "armuwadvms_dead.s3o",
				reclaimable = true,
				seqnamereclamate = "TREE1RECLAMATE",
				world = "all",
			},
			heap = {
				blocking = false,
				category = "heaps",
				damage = 1860,
				description = "Advanced Metal Storage Heap",
				energy = 0,
				featurereclamate = "SMUDGE01",
				footprintx = 4,
				footprintz = 4,
				hitdensity = 100,
				metal = 183,
				object = "arm4x4a.s3o",
				reclaimable = true,
				seqnamereclamate = "TREE1RECLAMATE",
				world = "all",
			},
		},
		sounds = {
			canceldestruct = "cancel2",
			underattack = "warning1",
			count = {
				[1] = "count6",
				[2] = "count5",
				[3] = "count4",
				[4] = "count3",
				[5] = "count2",
				[6] = "count1",
			},
			select = {
				[1] = "stormtl1",
			},
		},
		buildingGroundDecalDecaySpeed=30,
	buildingGroundDecalSizeX=6,
	buildingGroundDecalSizeY=6,
	useBuildingGroundDecal = true,
	buildingGroundDecalType=[[armuwadvms_aoplane.dds]],},
}
