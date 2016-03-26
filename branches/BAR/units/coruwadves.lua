return {
	coruwadves = {
		buildangle = 7822,
		buildcostenergy = 10701,
		buildcostmetal = 843,
		buildinggrounddecaldecayspeed = 30,
		buildinggrounddecalsizex = 8,
		buildinggrounddecalsizey = 8,
		buildinggrounddecaltype = "coruwadves_aoplane.dds",
		buildpic = "CORUWADVES.DDS",
		buildtime = 20416,
		category = "ALL NOTSUB NOWEAPON NOTAIR NOTHOVER SURFACE",
		corpse = "DEAD",
		description = "",
		energystorage = 40000,
		explodeas = "ATOMIC_BLAST",
		footprintx = 5,
		footprintz = 5,
		icontype = "building",
		idleautoheal = 5,
		idletime = 1800,
		maxdamage = 11400,
		maxslope = 20,
		maxwaterdepth = 9999,
		name = "Hardened Energy Storage",
		objectname = "CORUWADVES.s3o",
		seismicsignature = 0,
		selfdestructas = "MINE_NUKE",
		sightdistance = 192,
		usebuildinggrounddecal = true,
		yardmap = "ooooooooooooooooooooooooo",
		customparams = {
			faction = "core",
			normalmaps = "yes",
			normaltex = "unittextures/Core_normal.dds",
		},
		featuredefs = {
			dead = {
				blocking = true,
				category = "corpses",
				collisionvolumeoffsets = "-2.07458496094 4.21508789046e-05 -0.501388549805",
				collisionvolumescales = "87.0777893066 35.5382843018 90.1298522949",
				collisionvolumetype = "Box",
				damage = 4560,
				description = "Advanced Energy Storage Wreckage",
				energy = 0,
				featuredead = "HEAP",
				featurereclamate = "SMUDGE01",
				footprintx = 5,
				footprintz = 5,
				height = 9,
				hitdensity = 100,
				metal = 514,
				object = "CORUWADVES_DEAD.s3o",
				reclaimable = true,
				seqnamereclamate = "TREE1RECLAMATE",
				world = "all",
				customparams = {
					faction = "core",
				},
			},
			heap = {
				blocking = false,
				category = "heaps",
				damage = 2280,
				description = "Advanced Energy Storage Heap",
				energy = 0,
				featurereclamate = "SMUDGE01",
				footprintx = 5,
				footprintz = 5,
				hitdensity = 100,
				metal = 206,
				object = "cor5x5a.s3o",
				reclaimable = true,
				resurrectable = 0,
				seqnamereclamate = "TREE1RECLAMATE",
				world = "all",
				customparams = {
					faction = "core",
				},
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
				[1] = "storngy2",
			},
		},
	},
}
