return {
	ajuno = {
		acceleration = 0,
		brakerate = 0,
		buildcostenergy = 16581,
		buildcostmetal = 597,
		buildinggrounddecaldecayspeed = 30,
		buildinggrounddecalsizex = 6,
		buildinggrounddecalsizey = 6,
		buildinggrounddecaltype = "ajuno_aoplane.dds",
		buildpic = "AJUNO.DDS",
		buildtime = 21833,
		category = "ALL NOTLAND WEAPON NOTSUB NOTSHIP NOTAIR NOTHOVER SURFACE",
		collisionvolumeoffsets = "0 -2 0",
		collisionvolumescales = "44 88 44",
		collisionvolumetest = 1,
		collisionvolumetype = "CylY",
		corpse = "DEAD",
		description = "Anti Radar/Jammer/Minefield Weapon",
		explodeas = "ESTOR_BUILDINGEX",
		footprintx = 4,
		footprintz = 4,
		icontype = "building",
		idleautoheal = 5,
		idletime = 1800,
		maxdamage = 2120,
		maxslope = 10,
		maxwaterdepth = 0,
		name = "Arm Juno",
		objectname = "AJUNO",
		seismicsignature = 0,
		selfdestructas = "ATOMIC_BLAST",
		sightdistance = 494,
		stealth = true,
		usebuildinggrounddecal = true,
		yardmap = "oooooooooooooooo",
		featuredefs = {
			dead = {
				blocking = true,
				category = "corpses",
				collisionvolumeoffsets = "1.02378845215 -0.244132250977 6.86585998535",
				collisionvolumescales = "65.8518981934 75.545135498 65.7558898926",
				collisionvolumetype = "Box",
				damage = 1272,
				description = "Arm Juno Wreckage",
				energy = 0,
				featuredead = "HEAP",
				featurereclamate = "SMUDGE01",
				footprintx = 4,
				footprintz = 4,
				height = 20,
				hitdensity = 100,
				metal = 352,
				object = "AJUNO_DEAD",
				reclaimable = true,
				seqnamereclamate = "TREE1RECLAMATE",
				world = "All Worlds",
			},
			heap = {
				blocking = false,
				category = "heaps",
				damage = 636,
				description = "Arm Juno Heap",
				energy = 0,
				featurereclamate = "SMUDGE01",
				footprintx = 4,
				footprintz = 4,
				height = 4,
				hitdensity = 100,
				metal = 145,
				object = "4X4A",
				reclaimable = true,
				seqnamereclamate = "TREE1RECLAMATE",
				world = "All Worlds",
			},
		},
		sfxtypes = {
			explosiongenerators = {
				[1] = "custom:juno_sphere_emit",
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
				[1] = "drone1",
			},
			select = {
				[1] = "drone1",
			},
		},
		weapondefs = {
			juno_pulse = {
				areaofeffect = 1400,
				commandfire = true,
				craterboost = 0,
				cratermult = 0,
				edgeeffectiveness = 1,
				energypershot = 12000,
				explosiongenerator = "custom:FLASHJUNO",
				flighttime = 400,
				impulseboost = 0,
				impulsefactor = 0,
				metalpershot = 0,
				model = "epulse",
				name = "AntiSignal",
				range = 32000,
				reloadtime = 2,
				smoketrail = true,
				soundhit = "junohit2",
				soundstart = "junofir2",
				stockpile = true,
				stockpiletime = 75,
				targetable = 0,
				tolerance = 4000,
				turnrate = 24384,
				weaponacceleration = 80,
				weapontimer = 5,
				weapontype = "StarburstLauncher",
				weaponvelocity = 500,
				damage = {
					["else"] = 1,
					bombers = 1,
					commanders = 1,
					crawlingbombs = 1,
					default = 1,
					fighters = 1,
					heavyunits = 1,
					mines = 1000,
					nanos = 1,
					subs = 1,
					vtol = 1,
				},
			},
		},
		weapons = {
			[1] = {
				badtargetcategory = "MOBILE",
				def = "JUNO_PULSE",
				onlytargetcategory = "NOTSUB",
			},
		},
	},
}
