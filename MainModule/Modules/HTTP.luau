-- OspryOS Anticheat HTTP --

--// locals
--// Services
local HTTPService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

--// Anticheat Framework
return function (OspryAC)
	--// locals
	local Config = OspryAC.Config
	local Data = OspryAC.Data
	
	--// Anticheat Config
	local Behavior = Config.Behavior
	
	--// Anticheat Data
	local HTTP_Data = Data.HTTP
	
	--// Internal HTTP table
	local HTTP = {
		--// Main
		Use_Secret = false,
		
		--// API
		API_BaseURL = "https://discord.com/api/webhooks/", -- Used by the HTTP Secret
		
		--// Webhook URL and Secret
		HTTP_Secret = nil,
		Webhook_URL = nil,
	}
	
	-- Internal functions (Module dependant) --
	
	--// Generates an Embed
	local function GenerateEmbed(Plr : Player, Color : number, Fields : any)
		local generatedEmbed = HTTP_Data.GenerateEmbed(Plr, Color, Fields)
		return generatedEmbed
	end
	
	--// Attempts to fetch the Game's Name via :GetProductInfoAsync()
	local function GetGameName()
		--// pcall
		local success, result = pcall(function()
			return MarketplaceService:GetProductInfoAsync(game.PlaceId)
		end)

		--// Check if Fetch failed
		if not success then
			OspryAC:warn("HTTP has failed to fetch the Game's Name!")
			OspryAC:warn(`result: {result}`)
		end

		--// Fetched GameName
		local GameName = success and result.Name or "N/A"

		--// Export
		return tostring(GameName)
	end
	
	--// Sends a Payload to a Webhook
	local function SendPayload(Plr : Player, Color : number, Fields : any)
		--// Embed Payload
		local Payload = GenerateEmbed(Plr, Color, Fields)
		
		--// Send Payload
		local success, result = pcall(function()
			return if HTTP.Use_Secret
				then HTTPService:PostAsync(
					`{HTTP.API_BaseURL}{HTTP.Use_Secret}`,
					HTTPService:JSONEncode(Payload),
					Enum.HttpContentType.ApplicationJson
				)
				
				else HTTPService:PostAsync(
					HTTP.Webhook_URL,
					HTTPService:JSONEncode(Payload),
					Enum.HttpContentType.ApplicationJson
				)
		end)
		
		--// Check Response
		if success then
			OspryAC:debug(`Webhook sent? | isSecret: {HTTP.Use_Secret}`)
			
		else
			OspryAC:warn(`An error has occured while trying to send the Webhook's payload.`)
			OspryAC:warn(result)
			
			OspryAC:debug(`isSecret: {HTTP.Use_Secret}`)
		end
	end
	
	
	
	--// Exported functions
	return {
		--// Generates a GUID and exports it
		GenerateGUID = function()
			local GUID = HTTPService:GenerateGUID(true)
			return GUID
		end,
		
		--// Sends a Webhook to Staff Members if a Player has been warned by the Anticheat
		SendWarnToWebhook = function(Plr : Player, Reason : string, ModMessage : string)
			if not Behavior.SendToWebhook then return end
			
			--// Get Game Name
			local GameName = GetGameName()
			
			--// Embed Fields
			local Fields = {
				{ name = "Reason", value = Reason, inline = false },
				{ name = "Moderator Message", value = ModMessage, inline = false },
				{ name = "Game", value = GameName, inline = false },
			}
			
			--// Send to Webhook
			SendPayload(Plr, HTTP_Data.WarnColor, Fields)
			
			--[[
			--// Payload
			local Payload = GenerateEmbed(
				Plr,
				HTTP_Data.WarnColor,
				Fields
			)
			
			--// Attempt to send
			local success, response = pcall(function()
				HTTPService:PostAsync(
					OspryAC.Config.Behavior.Webhook_URL,
					HTTPService:JSONEncode(Payload),
					Enum.HttpContentType.ApplicationJson
				)
			end)
			
			--// Check HTTP Response
			if not success then
				OspryAC:warn("HTTP has failed to sent the Payload to a Webhook.")
				OspryAC:warn(`Got: {response}`)
				
			else
				OspryAC:debug("Webhook sent?")
			end
			]]
		end,
		
		--// Sends a Webhook to Staff Members if a Player has been kicked by the Anticheat
		SendKickToWebhook = function(Plr : Player, Reason : string, ModMessage : string)
			if not Behavior.SendToWebhook then return end
			
			--// Get Game Name
			local GameName = GetGameName()

			--// Embed Fields
			local Fields = {
				{ name = "Reason", value = Reason, inline = false },
				{ name = "Moderator Message", value = ModMessage, inline = false },
				{ name = "Game", value = GameName, inline = false },
			}
			
			--// Send to Webhook
			SendPayload(Plr, HTTP_Data.KickColor, Fields)
			
			--[[
			--// Payload
			local Payload = GenerateEmbed(
				Plr,
				HTTP_Data.KickColor,
				Fields
			)

			--// Attempt to send
			local success, response = pcall(function()
				HTTPService:PostAsync(
					OspryAC.Config.Behavior.Webhook_URL,
					HTTPService:JSONEncode(Payload),
					Enum.HttpContentType.ApplicationJson
				)
			end)

			--// Check HTTP Response
			if not success then
				OspryAC:warn("HTTP has failed to sent the Payload to a Webhook.")
				OspryAC:warn(`Got: {response}`)

			else
				OspryAC:debug("Webhook sent?")
			end
			]]
		end,
		
		
		
		--// Initiates the HTTP Module
		Init = function()
			if not Behavior.SendToWebhook then return end
			
			--// Check if HTTPService is enabled
			if not HTTPService.HttpEnabled then
				OspryAC:warn(`HTTP initialization skipped, HTTPService is not enabled.`)
				return
			end
			
			--// Set if Secret should be used
			HTTP.Use_Secret = Behavior.Use_HTTPSecret
			
			--// Check if Secret should be used
			if HTTP.Use_Secret then
				--// Set Base URL
				HTTP.API_BaseURL = Behavior.HTTP_Secret_BaseURL or "https://discord.com/api/webhooks/"
				
				--// Attempt to get Secret
				local success, result = pcall(function()
					return HTTPService:GetSecret(Behavior.HTTP_SecretKey)
				end)
				
				--// Check Response
				if not success then
					OspryAC:warn(`Failed to fetch HTTP Secret! Falling back to Webhook URL.`)
					OspryAC:warn(result)
					
					--// Disable usage of Secrets
					HTTP.Use_Secret = false
					
				else
					--// Set Secret
					HTTP.HTTP_Secret = HTTPService.HttpEnabled and result or nil
					OspryAC:debug(`Fetched HTTP Secret?`)
				end
			end
			
			--// Set Webhook URL
			HTTP.Webhook_URL = Behavior.Webhook_URL
			
			--// Complete
			OspryAC:debug(`HTTP initialization complete.`)
		end,
	}
end