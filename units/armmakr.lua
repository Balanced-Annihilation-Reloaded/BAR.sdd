return {
	armmakr = {
		acceleration = 0,
		activatewhenbuilt = true,
		brakerate = 0,
		buildangle = 8192,
		buildcostenergy = 1087,
		buildcostmetal = 1,




		buildpic = "ARMMAKR.DDS",
		buildtime = 2605,
		category = "ALL NOTLAND NOTSUB NOWEAPON NOTSHIP NOTAIR NOTHOVER SURFACE",
		description = "Converts up to 60 energy into 1 metal per second",
		explodeas = "ARMESTOR_BUILDINGEX",
		footprintx = 3,
		footprintz = 3,
		icontype = "building",
		idleautoheal = 5,
		idletime = 1800,
		maxdamage = 150,
		maxslope = 10,
		maxwaterdepth = 0,
		name = "Energy Converter",
		objectname = "ARMMAKR.s3o",
		seismicsignature = 0,
		selfdestructas = "ARMESTOR_BUILDING",
		sightdistance = 273,

		yardmap = "ooooooooo",
		customparams = {
			normalmaps = "yes",
			normaltex = "unittextures/Arm_normals.dds",
		},
		sounds = {
			activate = "metlon1",
			canceldestruct = "cancel2",
			deactivate = "metloff1",
			underattack = "warning1",
			working = "metlrun1",
			count = {
				[1] = "count6",
				[2] = "count5",
				[3] = "count4",
				[4] = "count3",
				[5] = "count2",
				[6] = "count1",
			},
			select = {
				[1] = "metlon1",
			},
		},
		buildingGroundDecalDecaySpeed=30,
	buildingGroundDecalSizeX=5,
	buildingGroundDecalSizeY=5,
	useBuildingGroundDecal = true,
	buildingGroundDecalType=[[armmakr_aoplane.dds]],},
}
