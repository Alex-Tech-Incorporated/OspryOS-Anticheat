return {
	--// Server-Sided Detections
	ServerSide = {
		HumanoidChecks = true, -- Checks for Humanoid State changes
		MagnitudeChecks = true, -- Checks for abnormal Magnitude changes
	},
	
	--// Client-Sided Detections
	ClientSide = {
		--// Client Settings
		Load_Timeout = 60, -- The Time before a Client is counted as "Timed-out" on loading
		
		--// Basic Detections
		NoclipDetection = true, -- Attempts to detect Noclip via Raycasting or if the HumanoidRootPart has CanCollide disabled
		BtoolsDetection = false, -- Attempts to detect Btools in the Player's Backpack and Character
		GuiDetection = false, -- (NOT RECOMMENDED) Attempts to detected unauthroized Guis and Scripts by checking if the object is also in StarterGui
		
		--// Advanced Client Detections
		DexDetection = false, -- Please refer to our Documentation for more info on Dex Detection
		AWPDetection = false, -- A detection methood targetting AWP users, refer to Documentation for more detail
	},
	
	--// Anticheat Behavior
	Behavior = {
		--// Gui Settings
		ShowKickReason = false, -- Shows the Kick reason to the Exploiter and Players if AnnounceKicks is enabled
		AnnounceKicks = false, -- Announces if a Player was kicked to everyone in the Server
		
		--// Warnings
		Warnings = true, -- Makes the Anticheat issue warnings instead of kicking a Player directly for certian Detections
		Max_Warns = 3, -- The maximum amount of Warnings a Player can recieve
		
		--// Misc
		Strict_Tokens = false, -- If enabled, Tokens can only be called once by the Client
		GetReq_RequireToken = true, -- If enabled, most Client Get Requests require the Client to send over the Token
		API = false, -- Allows the use of the _G API (_G.OspryAC), refer to Documentation for more detail
		
		--// HTTP Settings
		SendToWebhook = false, -- Sends Kicks and Warnings to a Webhook
		Webhook_URL = "CHANGE_THIS", -- Your Webhook URL
		
		Use_HTTPSecret = false, -- Uses Roblox's HTTP Secret instead of a URL within the Config
		HTTP_Secret_BaseURL = "https://discord.com/api/webhooks/", -- The URL to where the Payload gets sent to (Defaults to Discord's Webhook API)
		HTTP_SecretKey = "CHANGE_ME", -- The Key for the HTTP Secret so the Anticheat can find it
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