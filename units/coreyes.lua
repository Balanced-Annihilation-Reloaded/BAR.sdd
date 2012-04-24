return {
	coreyes = {
		acceleration = 0,
		activatewhenbuilt = true,
		brakerate = 0,
		buildangle = 8192,
		buildcostenergy = 800,
		buildcostmetal = 30,
		buildpic = "COREYES.DDS",
		buildtime = 750,
		category = "ALL NOTLAND NOTSUB NOWEAPON NOTSHIP NOTAIR NOTHOVER SURFACE",
		cloakcost = 10,
		corpse = "CDRAGONSEYES_DEAD",
		description = "Perimeter Camera",
		energyuse = 5,
		footprintx = 1,
		footprintz = 1,
		icontype = "building",
		idleautoheal = 5,
		idletime = 300,
		initcloaked = true,
		levelground = false,
		maxdamage = 250,
		maxslope = 24,
		maxwaterdepth = 0,
		mincloakdistance = 36,
		name = "Dragon's Eye",
		objectname = "COREYES.s3o",
		seismicsignature = 0,
		sightdistance = 540,
		stealth = true,
		waterline = 5,
		yardmap = "o",
		customparams = {
			normalmaps = "yes",
			normaltex = "unittextures/Core_normal.tga",
		},
		featuredefs = {
			cdragonseyes_dead = {
				blocking = false,
				category = "heaps",
				collisionvolumeoffsets = "-0.0323944091797 0.0 0.00588226318359",
				collisionvolumescales = "15.8270874023 2.5 15.2345123291",
				collisionvolumetype = "Box",
				damage = 120,
				description = "Dragon's Eye Heap",
				energy = 0,
				featurereclamate = "SMUDGE01",
				footprintx = 1,
				footprintz = 1,
				height = 4,
				hitdensity = 100,
				metal = 12,
				object = "1X1B",
				reclaimable = true,
				seqnamereclamate = "TREE1RECLAMATE",
				world = "All Worlds",
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
				[1] = "servsml6",
			},
			select = {
				[1] = "minesel2",
			},
		},
	},
}
