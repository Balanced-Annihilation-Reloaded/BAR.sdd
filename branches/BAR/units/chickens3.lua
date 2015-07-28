return {
	chickens3 = {
		acceleration = 0.5,
		airstrafe = true,
		autoheal = 7,
		brakerate = 3.5,
		buildcostenergy = 2200,
		buildcostmetal = 72,
		builder = false,
		buildpic = "chicken_pidgeon.png",
		buildtime = 1700,
		canfly = true,
		canguard = true,
		canland = true,
		canmove = true,
		canpatrol = true,
		canstop = true,
		category = "VTOL MOBILE WEAPON NOTSUB NOTSHIP NOTHOVER ALL",
		collide = false,
		collisionvolumeoffsets = "0 7 -6",
		collisionvolumescales = "48 12 22",
		collisionvolumetype = "box",
		cruisealt = 150,
		defaultmissiontype = "VTOL_standby",
		description = "Spiker Air Assault",
		explodeas = "TALON_DEATH",
		floater = true,
		footprintx = 1,
		footprintz = 1,
		hidedamage = 1,
		hoverattack = true,
		icontype = "chickenf",
		idleautoheal = 2,
		idletime = 0,
		mass = 280,
		maxdamage = 1900,
		maxvelocity = 7,
		name = "Fang",
		nochasecategory = "VTOL",
		objectname = "spiker_gunship.s3o",
		seismicsignature = 0,
		selfdestructas = "TALON_DEATH",
		side = "THUNDERBIRDS",
		sightdistance = 550,
		smoothanim = true,
		steeringmode = "1",
		tedclass = "VTOL",
		turnrate = 900,
		unitname = "chickens3",
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
			weapon = {
				accuracy = 1100,
				areaofeffect = 24,
				avoidfriendly = false,
				burnblow = true,
				collidefriendly = false,
				craterboost = 0,
				cratermult = 0,
				explosiongenerator = "custom:dirt",
				impulseboost = 0,
				impulsefactor = 0.4,
				interceptedbyshieldtype = 0,
				model = "spike.s3o",
				name = "Spike",
				noselfdamage = true,
				range = 350,
				reloadtime = 1.95,
				soundstart = "talonattack",
				startvelocity = 200,
				submissile = 1,
				turret = true,
				weaponacceleration = 100,
				weapontimer = 1,
				weaponvelocity = 350,
				damage = {
					default = 200,
				},
			},
		},
		weapons = {
			[1] = {
				badtargetcategory = "WEAPON",
				def = "WEAPON",
				maindir = "0 0 1",
				maxangledif = 120,
			},
		},
	},
}
