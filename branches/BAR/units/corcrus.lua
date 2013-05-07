return {
	corcrus = {
		acceleration = 0.041999999433756,
		activatewhenbuilt = true,
		brakerate = 0.061999998986721,
		buildangle = 16384,
		buildcostenergy = 13551,
		buildcostmetal = 1794,
		buildpic = "CORCRUS.DDS",
		buildtime = 19950,
		canmove = true,
		category = "ALL NOTLAND MOBILE WEAPON SHIP NOTSUB NOTAIR NOTHOVER SURFACE",
		collisionVolumeScales		= [[41 41 110]],
		collisionVolumeOffsets	= [[0 -6 0]],
		collisionVolumeTest	    = 1,
		collisionVolumeType	    = [[CylZ]],
		corpse = "DEAD",
		description = "Cruiser",
		energymake = 2.2000000476837,
		energyuse = 2.2000000476837,
		explodeas = "BIG_UNITEX",
		floater = true,
		footprintx = 4,
		footprintz = 4,
		icontype = "sea",
		idleautoheal = 5,
		idletime = 1800,
		maxdamage = 4649,
		maxvelocity = 2.6400001049042,
		minwaterdepth = 30,
		movementclass = "BOAT5",
		name = "Executioner",
		nochasecategory = "VTOL",
		objectname = "CORCRUS",
		seismicsignature = 0,
		selfdestructas = "BIG_UNIT",
		sightdistance = 533,
		sonardistance = 375,
		turninplace = 0,
		turnrate = 448,
		waterline = 5.5,
		windgenerator = 0.0010000000474975,
		featuredefs = {
			dead = {
				blocking = false,
				category = "corpses",
				collisionvolumeoffsets = "0.0 2.11181640619e-05 7.62939453125e-06",
				collisionvolumescales = "44.054901123 24.9370422363 110.273605347",
				collisionvolumetype = "Box",
				damage = 2789,
				description = "Executioner Wreckage",
				energy = 0,
				featuredead = "HEAP",
				footprintx = 5,
				footprintz = 5,
				height = 4,
				hitdensity = 100,
				metal = 1241,
				object = "CORCRUS_DEAD",
				reclaimable = true,
				seqnamereclamate = "TREE1RECLAMATE",
				world = "All Worlds",
			},
			heap = {
				blocking = false,
				category = "heaps",
				damage = 2016,
				description = "Executioner Heap",
				energy = 0,
				footprintx = 2,
				footprintz = 2,
				height = 4,
				hitdensity = 100,
				metal = 476,
				object = "2X2A",
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
				[1] = "shcormov",
			},
			select = {
				[1] = "shcorsel",
			},
		},
		weapondefs = {
			adv_decklaser = {
				areaofeffect = 8,
				beamtime = 0.15,
				corethickness = 0.17499999701977,
				craterboost = 0,
				cratermult = 0,
				energypershot = 10,
				explosiongenerator = "custom:SMALL_RED_BURN",
				firestarter = 30,
				impactonly = 1,
				impulseboost = 0.12300000339746,
				impulsefactor = 0.12300000339746,
				laserflaresize = 12,
				name = "L2DeckLaser",
				noselfdamage = true,
				range = 450,
				reloadtime = 0.40000000596046,
				rgbcolor = "1 0 0",
				soundstart = "lasrfir3",
				soundtrigger = true,
				targetmoveerror = 0.10000000149012,
				thickness = 2.5,
				tolerance = 10000,
				turret = true,
				weapontype = "BeamLaser",
				weaponvelocity = 800,
				damage = {
					bombers = 15,
					default = 110,
					fighters = 15,
					subs = 5,
					vtol = 15,
				},
			},
			advdepthcharge = {
				areaofeffect = 32,
				avoidfriendly = false,
				burnblow = true,
				collidefriendly = false,
				craterboost = 0,
				cratermult = 0,
				edgeeffectiveness = 0.80000001192093,
				explosiongenerator = "custom:FLASH4",
				impulseboost = 0.12300000339746,
				impulsefactor = 0.12300000339746,
				model = "DEPTHCHARGE",
				name = "CruiserDepthCharge",
				noselfdamage = true,
				range = 500,
				reloadtime = 3,
				soundhit = "xplodep2",
				soundstart = "torpedo1",
				startvelocity = 110,
				tolerance = 32767,
				tracks = true,
				turnrate = 9800,
				turret = false,
				waterweapon = true,
				weaponacceleration = 15,
				weapontimer = 10,
				weapontype = "TorpedoLauncher",
				weaponvelocity = 200,
				damage = {
					default = 220,
				},
			},
			cor_crus = {
				areaofeffect = 8,
				beamtime = 0.15000000596046,
				corethickness = 0.20000000298023,
				craterboost = 0,
				cratermult = 0,
				energypershot = 50,
				explosiongenerator = "custom:FLASH1",
				firestarter = 90,
				impulseboost = 0.12300000339746,
				impulsefactor = 0.12300000339746,
				name = "HighEnergyLaser",
				noselfdamage = true,
				range = 785,
				reloadtime = 0.89999997615814,
				rgbcolor = "0 1 0",
				soundstart = "Lasrmas2",
				targetmoveerror = 0.17499999701977,
				thickness = 3,
				turret = true,
				weapontype = "BeamLaser",
				weaponvelocity = 700,
				damage = {
					bombers = 44,
					default = 180,
					fighters = 44,
					subs = 5,
					vtol = 44,
				},
			},
		},
		weapons = {
			[1] = {
				def = "COR_CRUS",
				onlytargetcategory = "SURFACE",
			},
			[2] = {
				def = "ADV_DECKLASER",
				onlytargetcategory = "NOTSUB",
			},
			[3] = {
				def = "ADVDEPTHCHARGE",
				onlytargetcategory = "NOTHOVER",
			},
		},
	},
}
