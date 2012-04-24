return {
	corexp = {
		acceleration = 0,
		activatewhenbuilt = true,
		brakerate = 0,
		buildangle = 32768,
		buildcostenergy = 1811,
		buildcostmetal = 220,
		buildinggrounddecaldecayspeed = 30,
		buildinggrounddecalsizex = 5,
		buildinggrounddecalsizey = 5,
		buildinggrounddecaltype = "corexp_aoplane.dds",
		buildpic = "COREXP.DDS",
		buildtime = 2724,
		category = "ALL NOTLAND ANTIGATOR NOTSUB ANTIEMG NOWEAPON NOTSHIP NOTAIR NOTHOVER SURFACE",
		corpse = "DEAD",
		description = "Armed Metal Extractor",
		explodeas = "MEDIUM_BUILDINGEX",
		extractsmetal = 0.0010000000474975,
		footprintx = 3,
		footprintz = 3,
		icontype = "building",
		idleautoheal = 5,
		idletime = 1800,
		maxdamage = 1300,
		maxslope = 20,
		maxwaterdepth = 0,
		metalstorage = 75,
		name = "Exploiter",
		nochasecategory = "MOBILE",
		objectname = "COREXP.s3o",
		onoffable = true,
		seismicsignature = 0,
		selfdestructcountdown = 1,
		sightdistance = 455,
		usebuildinggrounddecal = true,
		yardmap = "ooooooooo",
		customparams = {
			normalmaps = "yes",
			normaltex = "unittextures/Core_normal.tga",
		},
		featuredefs = {
			dead = {
				blocking = true,
				category = "corpses",
				collisionvolumeoffsets = "0.0 0.0 -0.0",
				collisionvolumescales = "38.0 18.0 38.0",
				collisionvolumetype = "Box",
				damage = 780,
				description = "Exploiter Wreckage",
				energy = 0,
				featuredead = "HEAP",
				featurereclamate = "SMUDGE01",
				footprintx = 3,
				footprintz = 3,
				height = 20,
				hitdensity = 100,
				metal = 122,
				object = "COREXP_DEAD.s3o",
				reclaimable = true,
				seqnamereclamate = "TREE1RECLAMATE",
				world = "All Worlds",
			},
			heap = {
				blocking = false,
				category = "heaps",
				damage = 390,
				description = "Exploiter Heap",
				energy = 0,
				featurereclamate = "SMUDGE01",
				footprintx = 3,
				footprintz = 3,
				height = 4,
				hitdensity = 100,
				metal = 49,
				object = "3X3A",
				reclaimable = true,
				seqnamereclamate = "TREE1RECLAMATE",
				world = "All Worlds",
			},
		},
		sounds = {
			activate = "mexrun2",
			canceldestruct = "cancel2",
			deactivate = "mexoff2",
			underattack = "warning1",
			working = "mexrun2",
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
				[1] = "servmed2",
			},
			select = {
				[1] = "mexon2",
			},
		},
		weapondefs = {
			hllt_bottom = {
				areaofeffect = 12,
				avoidfeature = false,
				beamtime = 0.11999999731779,
				corethickness = 0.17499999701977,
				craterboost = 0,
				cratermult = 0,
				energypershot = 15,
				explosiongenerator = "custom:SMALL_RED_BURN",
				firestarter = 100,
				impactonly = 1,
				impulseboost = 0.12300000339746,
				impulsefactor = 0.12300000339746,
				laserflaresize = 10,
				name = "LightLaser",
				noselfdamage = true,
				proximitypriority = 3,
				range = 430,
				reloadtime = 0.47999998927116,
				rgbcolor = "1 0 0",
				soundhit = "lasrhit2",
				soundstart = "lasrfir3",
				soundtrigger = true,
				targetmoveerror = 0.10000000149012,
				thickness = 2.5,
				tolerance = 10000,
				turret = true,
				weapontype = "BeamLaser",
				weaponvelocity = 2250,
				damage = {
					bombers = 5,
					commanders = 140,
					default = 75,
					fighters = 5,
					subs = 2,
					vtol = 5,
				},
			},
		},
		weapons = {
			[1] = {
				badtargetcategory = "VTOL",
				def = "HLLT_BOTTOM",
				onlytargetcategory = "NOTSUB",
			},
		},
	},
}
