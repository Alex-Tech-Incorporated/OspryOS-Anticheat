-- OspryOS Anticheat calls --

--// Anticheat Framework
return function (OspryAC)
	
	-- Remote Connections --
	
	--// Exports
	return {
		Init = function()
			--// locals
			--// ReplicatedStorage
			local Remotes = require(OspryAC.Remotes)
			
			--// Remotes
			local getConfig = Remotes("get_Config")
			local getToken = Remotes("get_Token")
			
			local ClientKick = Remotes("ClientKick")
			local ClientWarn = Remotes("ClientWarn")
			
			--// Essential Configurations and Data
			-- This only sends specific things to the Client (Prevents Exploiters getting sensetive Stuff like Webhook URLs)
			local ClientConfig = {
				--// Detections
				NoclipDetection = OspryAC.Config.ClientSide.NoclipDetection,
				BtoolsDetection = OspryAC.Config.ClientSide.BtoolsDetection,
				GuiDetection = OspryAC.Config.ClientSide.GuiDetection,
				
				DexDetection = OspryAC.Config.ClientSide.DexDetection,
				AWPDetection = OspryAC.Config.ClientSide.AWPDetection,

				--// Behavior
				IssueWarns = OspryAC.Config.Behavior.Warnings,

				--// Development
				DebugMode = OspryAC.Config.Development.DebugMode,
			}
			local ClientData = {
				NoclipConfig = OspryAC.Data.NoclipDetection,
				WhitelistedGuis = OspryAC.Data.WhitelistedGuis,
			}
			
			
			
			-- RemoteFunction Connections --
			
			--// get_Config RemoteFunction
			getConfig:OnServerInvoke(function(Request, DataType : string)
				--// locals
				local Plr = Request.Client
				OspryAC:debug(`Got request from @{Plr.Name}, with DataType "{DataType}".`)
				
				--// Check Datatype
				if DataType == "config" then
					return Request:Close(ClientConfig)
					
				elseif DataType == "data" then
					return Request:Close(ClientData)
					
				else
					OspryAC:warn(`Calls has recieved an invalid datatype from the Client of {Plr.Name}.`)
					return Request:Raise("The Server recieved an invalid datatype.")
				end
			end)
			
			--// get_Token RemoteFunction
			getToken:OnServerInvoke(function(Request)
				--// locals
				local Plr = Request.Client
				local Token = OspryAC.tokens.GetToken(Plr)
				
				local StrictTokens = OspryAC.Config.Behavior.Strict_Tokens
				local called_Tokens = OspryAC.Data.System.Called_Tokens
				local TokenWasCalled = table.find(OspryAC.Data.System.Called_Tokens, Plr.UserId)
				
				--// Check if Token was already called
				if StrictTokens and TokenWasCalled then
					--// Kick Player
					OspryAC.functions.Kick(
						Plr,
						"Token was attempted to be called twice.",
						`The "get_Token" RemoteEvent was called twice.`
					)
					
				else
					--// Export and add to Called_Tokens
					if StrictTokens then table.insert(called_Tokens, Plr.UserId) end
					return Request:Close(Token)
				end
			end)
			
			
			
			-- RemoteEvent Connections --
			
			--// ClientKick RemoteEvent
			ClientKick:OnServerEvent(function(Request, Reason : string, ModMessage : string, recvToken : number)
				--// locals
				local Plr = Request.Client
				local Token = OspryAC.tokens.GetToken(Plr)
				
				--// Check if Token is valid
				if recvToken ~= Token then
					--// Kick Player if Token does not match
					OspryAC.functions.Kick(
						Plr,
						"Invalid Token sent to Server",
						`Player has attempted to interact with "ClientKick" RemoteEvent`
					)
					
				else
					--// Kick Player
					OspryAC.functions.Kick(
						Plr,
						Reason,
						ModMessage
					)
				end
				
				--// Debounce
				Request:Debounce(Plr, 5) -- Prevents Requests being spammed
			end)
			
			--// ClientWarn RemoteEvent
			ClientWarn:OnServerEvent(function(Request, Reason : string, ModMessage : string, recvToken : number)
				--// locals
				local Plr = Request.Client
				local Token = OspryAC.tokens.GetToken(Plr)
				
				--// Check if Token is valid
				if recvToken ~= Token then
					--// Kick Player if Token does not match
					OspryAC.functions.Kick(
						Plr,
						"Invalid Token sent to Server",
						`Player has attempted to interact with "ClientWarn" RemoteEvent`
					)

				else
					--// Warn Player
					OspryAC.functions.Warn(
						Plr,
						Reason,
						ModMessage
					)
				end
				
				--// Debounce
				Request:Debounce(Plr, 1) -- Prevents Requests being spammed
			end)
			
			--// Complete
			OspryAC:debug("calls initialized.")
		end,
	}
end