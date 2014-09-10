return {
	amgeo = {
		acceleration = 0,
		activatewhenbuilt = true,
		brakerate = 0,
		buildangle = 0,
		buildcostenergy = 24852,
		buildcostmetal = 1520,




		buildpic = "AMGEO.DDS",
		buildtime = 33152,
		category = "ALL NOTSUB NOWEAPON NOTAIR NOTHOVER SURFACE",
		collisionVolumeScales = [[69 69 107]],
		collisionVolumeOffsets = [[-2 -2 6]],
		collisionVolumeTest = 1,
		collisionVolumeType = [[CylY]],
		description = "Hazardous Energy Source (1250E)"
		energymake = 1250,
		energystorage = 12000,
		explodeas = "NUCLEAR_MISSILE",
		footprintx = 5,
		footprintz = 8,
		icontype = "building",
		idleautoheal = 5,
		idletime = 1800,
		maxdamage = 3240,
		maxslope = 15,
		maxwaterdepth = 0,
		name = "Moho Geothermal Powerplant",
		objectname = "AMGEO.s3o",
		seismicsignature = 0,
		selfdestructas = "NUCLEAR_MISSILE",
		sightdistance = 273,

		yardmap = "ooooo ooooo ooooo ooooo ooooo oGGGo oGGGo ooooo",
		customparams = {
			normalmaps = "yes",
			normaltex = "unittextures/Arm_normals.dds",
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
				[1] = "geothrm1",
			},
		},
		buildingGroundDecalDecaySpeed=30,
	buildingGroundDecalSizeX=11,
	buildingGroundDecalSizeY=11,
	useBuildingGroundDecal = true,
	buildingGroundDecalType=[[amgeo_aoplane.dds]],},
}
