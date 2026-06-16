return {
	ServerSide = {
		HumanoidChecks = true,
		MagnitudeChecks = true,
	},

	ClientSide = {
		Enabled = true,

		NoclipDetection = true,
		BtoolsDetection = true,
		GuiDetection = false,
		
		DexDetection = false,
		AWPDetection = false,
	},

	Behavior = {
		ShowKickReason = false,
		AnnounceKicks = false,

		Warnings = true,
		Max_Warns = 3,
		
		Strict_Tokens = false,

		SendToWebhook = false,
		Webhook_URL = "CHANGE_THIS",
	},
	
	Whitelists = {
		AdonisWhitelist = false,
		
		Players = {},
		Groups = {},
	},

	Development = {
		DebugMode = false,
	},
	
	--// Anticheat specific
	System = {
		Version = "3.0.0",
	}
}