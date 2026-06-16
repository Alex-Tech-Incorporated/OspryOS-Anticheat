return {
	--// Humanoid Check Settings
	-- Please Check Roblox's Documentation for Humanoid States!
	-- https://create.roblox.com/docs/en-us/reference/engine/enums/HumanoidStateType
	HumanoidChecks = {
		WhitelistedStates = {0, 2, 3, 4, 5, 7, 8, 12, 13, 15, 18}, -- Whitelisted Humanoid States
		CheckPlatformStanding = true, -- Checks for Platform Standing (State 14)
	},
	
	--// Magnitude Check Settings
	MagnitudeChecks = {
		Max_Magnitude = 25, -- The Maximum amount of Magnitude changes allowed
		CheckTime = 1, -- The Duration between checks
		CheckDelay = 1, -- The Delay between the Check comparing Previous Values with new Values
	},
	
	--// Noclip Detection
	NoclipDetection = {
		AggressiveCharacterValidation = false, -- Second Noclip check (refer to the documentation for more detail)
		PrecisionMode = 2, -- Controls the secondary verification checks used (refer to the documentation for more detail)
		MaxAllocatedViolations = 7, -- How many violations are required to kick the player for noclipping
		ResetAllocationsPerCycleCount = 3, -- At what cycle do we reset the ViolationCounter
		IgnoreWaterForCasting = true, -- Do we account for water when casting
		NoclipEvaluationVector = Vector3.new(0, -1, 0), -- The vector to use to evaluate the player's state
	},
	
	--// Gui Detection
	-- This can be used as an alternative for any Gui not in StarterGui
	-- WARNING: this may make your game vulnerable to unknown Guis.
	WhitelistedGuis = {
		-- EXAMPLE: "ScreenGui", "AdminGui"
	},
}