return {
	chickens2 = {
		acceleration = 3,
		bmcode = "1",
		brakerate = 3,
		buildcostenergy = 174,
		buildcostmetal = 174,
		builder = false,
		buildtime = 7000,
		canattack = true,
		canguard = true,
		canmove = true,
		canpatrol = true,
		canstop = "1",
		category = "MOBILE WEAPON NOTAIR NOTSUB NOTSHIP ALL NOTHOVER SURFACE",
		cloakable = 1,
		cloakcost = 0,
		cloakcostmoving = 0,
		collisionvolumeoffsets = "0 -1 0",
		collisionvolumescales = "24 34 53",
		collisionvolumetype = "box",
		corpse = "DEAD",
		defaultmissiontype = "Standby",
		description = "Ghost Spiker",
		explodeas = "BUG_DEATH",
		floater = false,
		footprintx = 3,
		footprintz = 3,
		icontype = "chickens",
		idleautoheal = 20,
		idletime = 300,
		initcloaked = 1,
		leavetracks = true,
		maneuverleashlength = "750",
		mass = 300,
		maxdamage = 5000,
		maxslope = 18,
		maxvelocity = 9,
		maxwaterdepth = 15,
		mincloakdistance = 200,
		movementclass = "AKBOT2",
		name = "Advanced Spiker",
		noautofire = false,
		nochasecategory = "VTOL",
		objectname = "chickens2.s3o",
		seismicsignature = 0,
		selfdestructas = "BUG_DEATH",
		side = "THUNDERBIRDS",
		sightdistance = 720,
		smoothanim = true,
		sonardistance = 720,
		steeringmode = "2",
		tedclass = "AKBOT2",
		trackoffset = 6,
		trackstrength = 8,
		trackstretch = 1,
		tracktype = "ChickenTrack",
		trackwidth = 30,
		turninplace = 0,
		turnrate = 1900,
		unitname = "chickens2",
		upright = false,
		workertime = 0,
		customparams = {
			normalmaps = "yes",
			normaltex = "unittextures/chicken_normal.tga",
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
			waterweapon = {
				areaofeffect = 16,
				avoidfriendly = 0,
				burnblow = 1,
				collidefriendly = 0,
				craterboost = 0,
				cratermult = 0,
				explosiongenerator = "custom:dirt",
				impulseboost = 0.123,
				impulsefactor = 0.123,
				interceptedbyshieldtype = 0,
				model = "spike.s3o",
				name = "Sea Spike",
				noselfdamage = 1,
				range = 690,
				reloadtime = 5,
				startvelocity = 150,
				tolerance = 32767,
				tracks = 1,
				turnrate = 1500,
				turret = 1,
				waterweapon = 1,
				weaponacceleration = 25,
				weapontimer = 4,
				weaponvelocity = 220,
				damage = {
					default = 1500,
				},
			},
			weapon = {
				areaofeffect = 16,
				avoidfeature = 0,
				avoidfriendly = 0,
				burnblow = true,
				collidefeature = true,
				collidefriendly = false,
				craterboost = 0,
				cratermult = 0,
				edgeeffectiveness = 0,
				explosiongenerator = "custom:ASPIKER",
				impulseboost = 0,
				impulsefactor = 0.4,
				interceptedbyshieldtype = 0,
				model = "spike.s3o",
				name = "Spike",
				noselfdamage = true,
				range = 470,
				reloadtime = 3.25,
				smoketrail = true,
				startvelocity = 600,
				texture1 = "",
				texture2 = "sporetrail",
				turret = true,
				waterweapon = false,
				weapontimer = 1,
				weapontype = "MissileLauncher",
				weaponvelocity = 600,
				damage = {
					bombers = 1500,
					default = 1130,
					fighters = 1500,
					vtol = 1500,
				},
			},
		},
		weapons = {
			[1] = {
				badtargetcategory = "VTOL",
				def = "WEAPON",
				maindir = "0 0 1",
				maxangledif = 120,
			},
			[2] = {
				def = "WATERWEAPON",
				maindir = "0 0 1",
				maxangledif = 160,
			},
		},
	},
}
