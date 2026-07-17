return {
	--// Server-Sided Detections
	ServerSide = {
		HumanoidChecks = true, -- Checks for Humanoid State changes
		MagnitudeChecks = true, -- Checks for abnormal Magnitude changes
	},
	
	--// Client-Sided Detections
	ClientSide = {
		NoclipDetection = true, -- Attempts to detect Noclip via Raycasting or if the HumanoidRootPart has CanCollide disabled
		BtoolsDetection = true, -- Attempts to detect Btools in the Player's Backpack and Character
		GuiDetection = false, -- (NOT RECOMMENDED) Attempts to detected unauthroized Guis and Scripts by checking if the object is also in StarterGui
		
		--// Advanced Client Detections
		DexDetection = false, -- Please refer to our Documentation for more info on Dex Detection
		AWPDetection = false, -- A detection methood targetting AWP users, refer to Documentation for more detail
	},
	
	--// Anticheat Behavior
	Behavior = {
		ShowKickReason = false, -- Shows the Kick reason to the Exploiter and Players if AnnounceKicks is enabled
		AnnounceKicks = false, -- Announces if a Player was kicked to everyone in the Server
		
		Warnings = true, -- Makes the Anticheat issue warnings instead of kicking a Player directly for certian Detections
		Max_Warns = 3, -- The maximum amount of Warnings a Player can recieve
		
		Strict_Tokens = false, -- If enabled, Tokens can only be called once by the Client
		
		SendToWebhook = false, -- Sends Kicks and Warnings to a Webhook
		Webhook_URL = "CHANGE_THIS", -- Your Webhook URL
	},
	
	--// Whitelist Settings and Options
	Whitelists = {
		--// Options
		AdonisWhitelist = false, -- Uses the Adonis _G API to ignore Admins from Detections (Includes anyone with a Rank in Adonis)
		Min_Level = 100, -- The Minimum Admin Level required for a Player to be ignored
		
		--// Whitelist Tables
		Players = {
			-- Example: "Username", 123456789
			-- -1, "Alexkist"
		},
		Groups = {
			-- Example: [GroupID] = Minrank
		},
	},
	
	--// Development related
	Development = {
		LoadLocally = true, -- Loads a local version of the MainModule, placed in ServerScriptService
		DebugMode = true, -- Enables special prints and weakens Anticheat Security for debugging
		
		MainModule = 0, -- The ID of the MainModule
	},
}