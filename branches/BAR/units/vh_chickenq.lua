return {
	vh_chickenq = {
		acceleration = 1.8,
		airsightdistance = 2400,
		autoheal = 75,
		brakerate = 2,
		buildcostenergy = 2000000,
		buildcostmetal = 50000,
		builder = false,
		buildpic = "VH_CHICKENQ.DDS",
		buildtime = 1000000,
		canattack = true,
		canguard = true,
		canmove = true,
		canpatrol = true,
		canstop = "1",
		cantbetransported = true,
		category = "MOBILE WEAPON NOTAIR NOTSUB NOTHOVER NOTSHIP ALL SURFACE",
		collisionspherescale = 1.75,
		collisionvolumeoffsets = "0 -52 15",
		collisionvolumescales = "60 130 140",
		collisionvolumetype = "box",
		corpse = "DEAD",
		description = "Clucking Hell! (Very Hard)",
		explodeas = "QUEEN_DEATH",
		footprintx = 3,
		footprintz = 3,
		icontype = "chickenq",
		leavetracks = true,
		maneuverleashlength = 2000,
		mass = 2000000,
		maxdamage = 1750000,
		maxslope = 40,
		maxvelocity = 2.9,
		maxwaterdepth = 70,
		movementclass = "CHICKQUEEN",
		name = "Chicken Queen",
		noautofire = false,
		nochasecategory = "VTOL",
		objectname = "vh_chickenq.s3o",
		pushresistant = true,
		seismicsignature = 4,
		selfdestructas = "QUEEN_DEATH",
		sightdistance = 1250,
		trackoffset = 18,
		trackstrength = 8,
		trackstretch = 1,
		tracktype = "ChickenTrack",
		trackwidth = 100,
		turninplace = 0,
		turnrate = 700,
		upright = false,
		workertime = 0,
		customparams = {
			faction = "chicken",
		},
		featuredefs = {
			dead = {},
			heap = {},
		},
		sfxtypes = {
			explosiongenerators = {
				[1] = "custom:blood_spray",
				[2] = "custom:blood_explode",
				[3] = "custom:dirt",
			},
		},
		weapondefs = {
			goo = {
				accuracy = 1200,
				areaofeffect = 200,
				avoidfeature = 0,
				avoidfriendly = 0,
				burst = 10,
				burstrate = 0.01,
				cegtag = "ROCKTRAIL",
				collidefriendly = 0,
				craterboost = 0,
				cratermult = 0,
				edgeeffectiveness = 0.33,
				explosiongenerator = "custom:gundam_MISSILE_EXPLOSION",
				impulseboost = 0,
				impulsefactor = 0,
				intensity = 0.7,
				interceptedbyshieldtype = 1,
				model = "SGreyRock1.S3O",
				name = "Blob",
				noselfdamage = true,
				proximitypriority = -4,
				range = 1200,
				reloadtime = 4,
				rgbcolor = "0.1 0.6 1",
				size = 8,
				sizedecay = 0,
				soundhit = "xplomed2",
				soundstart = "bigchickenroar",
				sprayangle = 4096,
				tolerance = 5000,
				turret = true,
				weapontimer = 0.2,
				weaponvelocity = 800,
				damage = {
					bombers = 9999,
					chicken = 400,
					default = 1000,
					fighters = 9999,
					vtol = 6000,
				},
			},
			melee = {
				areaofeffect = 60,
				avoidfeature = 0,
				avoidfriendly = 0,
				camerashake = 0,
				collidefriendly = 0,
				craterboost = 0,
				cratermult = 0,
				explosiongenerator = "custom:NONE",
				impulseboost = 1.5,
				impulsefactor = 1.5,
				name = "ChickenClaws",
				noselfdamage = true,
				proximitypriority = -3,
				range = 280,
				reloadtime = 0.45,
				size = 0,
				soundstart = "bigchickenbreath",
				tolerance = 5000,
				turret = true,
				waterweapon = true,
				weapontype = "Cannon",
				weaponvelocity = 2500,
				damage = {
					bombers = 3000,
					chicken = 0.001,
					default = 900,
					fighters = 3000,
					tinychicken = 0.001,
					vtol = 3000,
				},
			},
			spores1 = {
				areaofeffect = 96,
				avoidfriendly = 0,
				burnblow = 1,
				burst = 3,
				burstrate = 0.11,
				collidefriendly = false,
				craterboost = 0,
				cratermult = 0,
				dance = 20,
				explosiongenerator = "custom:QUEENSPIKES",
				firestarter = 0,
				flighttime = 5,
				groundbounce = 1,
				heightmod = 0.5,
				impulseboost = 0,
				impulsefactor = 0.4,
				interceptedbyshieldtype = 0,
				metalpershot = 0,
				model = "spike.s3o",
				name = "Missiles",
				noselfdamage = true,
				proximitypriority = 3,
				range = 700,
				reloadtime = 1.5,
				smoketrail = true,
				soundhit = "xplosml2",
				startvelocity = 200,
				texture1 = "",
				texture2 = "sporetrail",
				tolerance = 10000,
				tracks = true,
				trajectoryheight = 2,
				turnrate = 48000,
				turret = true,
				waterweapon = true,
				weaponacceleration = 200,
				weapontype = "MissileLauncher",
				weaponvelocity = 4000,
				wobble = 64000,
				damage = {
					bombers = 700,
					default = 285,
					fighters = 500,
					vtol = 500,
				},
			},
			spores2 = {
				areaofeffect = 96,
				avoidfeature = 0,
				avoidfriendly = false,
				burnblow = 1,
				burst = 2,
				burstrate = 0.09,
				collidefriendly = false,
				craterboost = 0,
				cratermult = 0,
				dance = 20,
				explosiongenerator = "custom:QUEENSPIKES",
				firestarter = 0,
				flighttime = 5,
				groundbounce = 1,
				heightmod = 0.5,
				impulseboost = 0,
				impulsefactor = 0.4,
				interceptedbyshieldtype = 0,
				metalpershot = 0,
				model = "spike.s3o",
				name = "Missiles",
				noselfdamage = true,
				range = 700,
				reloadtime = 0.7,
				smoketrail = true,
				soundhit = "xplosml2",
				startvelocity = 200,
				texture1 = "",
				texture2 = "sporetrail",
				tolerance = 10000,
				tracks = true,
				trajectoryheight = 2,
				turnrate = 48000,
				turret = true,
				waterweapon = true,
				weaponacceleration = 200,
				weapontype = "MissileLauncher",
				weaponvelocity = 4000,
				wobble = 64000,
				damage = {
					bombers = 500,
					default = 285,
					fighters = 700,
					vtol = 500,
				},
			},
			spores3 = {
				areaofeffect = 64,
				avoidfriendly = false,
				burnblow = 1,
				burst = 1,
				burstrate = 0.1,
				collidefriendly = 0,
				craterboost = 0,
				cratermult = 0,
				dance = 20,
				explosiongenerator = "custom:QUEENSPIKES",
				firestarter = 0,
				flighttime = 5,
				groundbounce = 1,
				heightmod = 0.5,
				impulseboost = 0,
				impulsefactor = 0.4,
				interceptedbyshieldtype = 0,
				metalpershot = 0,
				model = "spike.s3o",
				name = "Missiles",
				noselfdamage = true,
				proximitypriority = -3,
				range = 700,
				reloadtime = 0.5,
				smoketrail = true,
				soundhit = "xplosml2",
				startvelocity = 200,
				texture1 = "",
				texture2 = "sporetrail",
				tolerance = 10000,
				tracks = true,
				trajectoryheight = 2,
				turnrate = 48000,
				turret = true,
				waterweapon = true,
				weaponacceleration = 200,
				weapontype = "MissileLauncher",
				weaponvelocity = 4000,
				wobble = 64000,
				damage = {
					bombers = 500,
					default = 285,
					fighters = 500,
					vtol = 700,
				},
			},
		},
		weapons = {
			[1] = {
				def = "MELEE",
				maindir = "0 0 1",
				maxangledif = 155,
			},
			[2] = {
				badtargetcategory = "NOTAIR",
				def = "SPORES1",
			},
			[3] = {
				badtargetcategory = "WEAPON",
				def = "SPORES2",
			},
			[4] = {
				badtargetcategory = "NOWEAPON",
				def = "SPORES3",
			},
			[5] = {
				def = "GOO",
				maindir = "0 0 1",
				maxangledif = 120,
			},
		},
	},
}
