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
	
	local HTTP_Data = Data.HTTP
	
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
	
	
	
	--// Exported functions
	return {
		--// Generates a GUID and exports it
		GenerateGUID = function()
			local GUID = HTTPService:GenerateGUID(true)
			return GUID
		end,
		
		--// Sends a Webhook to Staff Members if a Player has been warned by the Anticheat
		SendWarnToWebhook = function(Plr : Player, Reason : string, ModMessage : string)
			if not OspryAC.Config.Behavior.SendToWebhook then return end
			
			--// Get Game Name
			local GameName = GetGameName()
			
			--// Embed Fields
			local Fields = {
				{ name = "Reason", value = Reason, inline = false },
				{ name = "Moderator Message", value = ModMessage, inline = false },
				{ name = "Game", value = GameName, inline = false },
			}
			
			--// Payload
			local Payload = GenerateEmbed(Plr, HTTP_Data.WarnColor, Fields)
			
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
		end,
		
		--// Sends a Webhook to Staff Members if a Player has been kicked by the Anticheat
		SendKickToWebhook = function(Plr : Player, Reason : string, ModMessage : string)
			if not OspryAC.Config.Behavior.SendToWebhook then return end
			
			--// Get Game Name
			local GameName = GetGameName()

			--// Embed Fields
			local Fields = {
				{ name = "Reason", value = Reason, inline = false },
				{ name = "Moderator Message", value = ModMessage, inline = false },
				{ name = "Game", value = GameName, inline = false },
			}

			--// Payload
			local Payload = GenerateEmbed(Plr, HTTP_Data.KickColor, Fields)

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
		end,
	}
end