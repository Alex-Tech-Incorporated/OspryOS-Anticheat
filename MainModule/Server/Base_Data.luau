return {
	HumanoidChecks = {
		WhitelistedStates = {0, 2, 3, 4, 5, 7, 8, 12, 13, 15, 18},
		CheckPlatformStanding = true,
	},
	
	MagnitudeChecks = {
		Max_Magnitude = 25,
		CheckTime = 1,
		CheckDelay = 1,
	},
	
	NoclipDetection = {
		AggressiveCharacterValidation = false,
		PrecisionMode = 2,
		MaxAllocatedViolations = 7,
		ResetAllocationsPerCycleCount = 3,
		IgnoreWaterForCasting = true,
		NoclipEvaluationVector = Vector3.new(0, -1, 0),
	},
	
	WhitelistedGuis = {},
	
	--// Anticheat specific
	System = {
		Tokens = {}, -- Format: [UserId] = Token
		Client_Stats = {}, -- Format: [UserId] = ClientState | "Loading" or "Complete"
		Called_Tokens = {}, -- Stores all Players that already called there Token
		
		Warnings = {}, -- Format: [UserId] = WarningCount
	},
}