return {
	corpt = {
		acceleration = 0.096000000834465,
		airsightdistance = 800,
		brakerate = 0.025000000372529,
		buildcostenergy = 917,
		buildcostmetal = 95,
		buildpic = "CORPT.DDS",
		buildtime = 1877,
		canmove = true,
		category = "ALL MOBILE WEAPON NOTLAND SHIP NOTSUB NOTAIR NOTHOVER SURFACE",
		collisionvolumeoffsets = "0 5 0",
		collisionvolumescales = "19 33 61",
		collisionvolumetest = 1,
		collisionvolumetype = "CylY",
		corpse = "DEAD",
		description = "Scout Boat/Light Anti-Air",
		energymake = 0.23000000417233,
		energyuse = 0.23000000417233,
		explodeas = "SMALL_UNITEX",
		floater = true,
		footprintx = 3,
		footprintz = 3,
		icontype = "sea",
		idleautoheal = 5,
		idletime = 1800,
		maxdamage = 228,
		maxvelocity = 5.0599999427795,
		minwaterdepth = 6,
		movementclass = "BOAT4",
		name = "Searcher",
		nochasecategory = "VTOL UNDERWATER",
		objectname = "CORPT.s3o",
		seismicsignature = 0,
		selfdestructas = "SMALL_UNIT",
		sightdistance = 585,
		turninplace = 0,
		turnrate = 622,
		waterline = 1.5,
		windgenerator = 0.0010000000474975,
		customparams = {
			normalmaps = "yes",
			normaltex = "unittextures/Core_normal.tga",
		},
		featuredefs = {
			dead = {
				blocking = false,
				category = "corpses",
				collisionvolumeoffsets = "-3.69921112061 1.72119140629e-06 -0.0",
				collisionvolumescales = "32.8984222412 14.8354034424 64.0",
				collisionvolumetype = "Box",
				damage = 342,
				description = "Searcher Wreckage",
				energy = 0,
				featuredead = "HEAP",
				footprintx = 3,
				footprintz = 3,
				height = 4,
				hitdensity = 100,
				metal = 62,
				object = "CORPT_DEAD.s3o",
				reclaimable = true,
				seqnamereclamate = "TREE1RECLAMATE",
				world = "All Worlds",
			},
			heap = {
				blocking = false,
				category = "heaps",
				damage = 716,
				description = "Searcher Heap",
				energy = 0,
				footprintx = 2,
				footprintz = 2,
				height = 4,
				hitdensity = 100,
				metal = 26,
				object = "cor3X3A.s3o",
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
			armkbot_missile = {
				areaofeffect = 48,
				canattackground = false,
				craterboost = 0,
				cratermult = 0,
				explosiongenerator = "custom:FLASH2",
				firestarter = 70,
				flighttime = 3,
				impulseboost = 0.12300000339746,
				impulsefactor = 0.12300000339746,
				metalpershot = 0,
				model = "cormissile.s3o",
				name = "Missiles",
				noselfdamage = true,
				range = 760,
				reloadtime = 2,
				smoketrail = true,
				soundhit = "xplosml2",
				soundstart = "rocklit1",
				startvelocity = 650,
				texture2 = "armsmoketrail",
				toairweapon = true,
				tolerance = 9000,
				tracks = true,
				turnrate = 63000,
				turret = true,
				weaponacceleration = 141,
				weapontimer = 5,
				weapontype = "MissileLauncher",
				weaponvelocity = 850,
				damage = {
					default = 110,
					subs = 5,
				},
			},
			armpt_laser = {
				areaofeffect = 8,
				beamtime = 0.10000000149012,
				burstrate = 0.20000000298023,
				corethickness = 0.10000000149012,
				craterboost = 0,
				cratermult = 0,
				duration = 0.019999999552965,
				energypershot = 5,
				explosiongenerator = "custom:SMALL_YELLOW_BURN",
				firestarter = 50,
				impactonly = 1,
				impulseboost = 0.12300000339746,
				impulsefactor = 0.12300000339746,
				laserflaresize = 5,
				name = "Laser",
				noselfdamage = true,
				range = 220,
				reloadtime = 0.89999997615814,
				rgbcolor = "1 1 0",
				soundhit = "lasrhit2",
				soundstart = "lasrfir1",
				soundtrigger = true,
				targetmoveerror = 0.20000000298023,
				thickness = 1,
				tolerance = 10000,
				turret = true,
				weapontype = "BeamLaser",
				weaponvelocity = 750,
				damage = {
					bombers = 9,
					default = 55,
					fighters = 9,
					subs = 2,
					vtol = 9,
				},
			},
		},
		weapons = {
			[1] = {
				def = "ARMPT_LASER",
				onlytargetcategory = "NOTSUB",
			},
			[3] = {
				def = "ARMKBOT_MISSILE",
				onlytargetcategory = "VTOL",
			},
		},
	},
}
