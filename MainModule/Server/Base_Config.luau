return {
	ServerSide = {
		HumanoidChecks = true,
		MagnitudeChecks = true,
	},

	ClientSide = {
		Load_Timeout = 60,

		NoclipDetection = true,
		BtoolsDetection = false,
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
		GetReq_RequireToken = false,
		API = false,

		SendToWebhook = false,
		Webhook_URL = "CHANGE_THIS",
		
		Use_HTTPSecret = false,
		HTTP_Secret_BaseURL = "https://discord.com/api/webhooks/",
		HTTP_SecretKey = "CHANGE_ME",
	},
	
	Whitelists = {
		AdonisWhitelist = false,
		Min_Level = 100,
		
		Players = {},
		Groups = {},
	},

	Development = {
		DebugMode = false,
	},
	
	--// Anticheat specific
	System = {
		Version = "3.2.3-Patch 1",
	}
}