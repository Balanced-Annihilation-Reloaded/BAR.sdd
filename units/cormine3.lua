return {
	cormine3 = {
		acceleration = 0,
		brakerate = 0,
		buildcostenergy = 1250,
		buildcostmetal = 20,
		buildpic = "CORMINE3.DDS",
		buildtime = 125,
		canattack = false,
		canguard = false,
		canpatrol = false,
		category = "ALL NOTLAND WEAPON MINE KAMIKAZE NOTSUB NOTSHIP NOTAIR NOTHOVER SURFACE",
		cloakcost = 1.5,
		collide = false,
		collisionvolumeoffsets = "0 -2 0",
		collisionvolumescales = "15 6 15",
		collisionvolumetest = 1,
		collisionvolumetype = "Ell",
		description = "Heavy Mine",
		explodeas = "MINE_HEAVY",
		firestate = 2,
		footprintx = 1,
		footprintz = 1,
		icontype = "building",
		idleautoheal = 10,
		idletime = 300,
		initcloaked = true,
		levelground = false,
		maxdamage = 10,
		maxslope = 40,
		maxwaterdepth = 0,
		mincloakdistance = 8,
		name = 1100,
		nochasecategory = "VTOL",
		objectname = "CORMINE3.s3o",
		seismicsignature = 0,
		selfdestructas = "MINE_HEAVY",
		selfdestructcountdown = 0,
		sightdistance = 83.199996948242,
		stealth = true,
		yardmap = "y",
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
		weapondefs = {
			mine_detonator = {
				areaofeffect = 5,
				craterboost = 0,
				cratermult = 0,
				edgeeffectiveness = 0,
				explosiongenerator = "",
				firesubmersed = true,
				gravityaffected = "true",
				impulseboost = 0,
				impulsefactor = 0,
				name = "Mine Detonator",
				range = 1,
				reloadtime = 0.10000000149012,
				weapontype = "Cannon",
				weaponvelocity = 1000,
				damage = {
					default = 0,
					mines = 100,
				},
			},
			mine_dummy = {
				areaofeffect = 0,
				craterboost = 0,
				cratermult = 0,
				edgeeffectiveness = 0,
				explosiongenerator = "",
				firesubmersed = true,
				impulseboost = 0,
				impulsefactor = 0,
				name = "Crawlingbomb Dummy Weapon",
				range = 64,
				reloadtime = 0.10000000149012,
				tolerance = 100000,
				weapontype = "Melee",
				weaponvelocity = 100000,
				damage = {
					default = 0,
				},
			},
		},
		weapons = {
			[1] = {
				badtargetcategory = "VTOL",
				def = "MINE_DUMMY",
				onlytargetcategory = "SURFACE",
			},
			[2] = {
				def = "MINE_DETONATOR",
				onlytargetcategory = "NOTSUB",
			},
		},
	},
}
