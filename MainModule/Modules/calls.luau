-- OspryOS Anticheat calls --

--// Anticheat Framework
return function (OspryAC)
	--// locals
	-- All of these get set once calls Initializes.
	local Remotes
	local ClientRemote
	local ClientActions
	local ClientData
	
	--// Export
	return {
		--// Sends a Command to a Client
		Send = function(Plr : Player, command : string, ...)
			ClientRemote:FireClients({Plr}, command, ...)
		end,
		
		--// Sends a Command to all Clients
		SendAll = function(command : string, ...)
			ClientRemote:FireAllClients(command, ...)
		end,
		
		--// Initiates the calls Module
		Init = function()
			--// Set locals
			Remotes = require(OspryAC.Remotes)
			ClientRemote = Remotes("OspryAC")
			ClientActions = Remotes("Actions")
			ClientData = Remotes("Get")
			
			-- Remote Connections --
			
			--// OspryAC RemoteEvent Connection
			ClientRemote:OnServerEvent(function(Request, command : string, ...)
				--// locals
				local Plr = Request.Client
				
				--// Command
				local func = OspryAC.calls.Commands[command]
				if not func then return end
				
				--// Trigger
				func(Plr, ...)
			end)
			
			--// Actions RemoteEvent Connection
			ClientActions:OnServerEvent(function(Request, Type : string, ...)
				--// locals
				local Plr = Request.Client
				local Action = OspryAC.calls.Actions[Type]
				
				--// Check if Action exists
				if Action then
					Action(Request, ...)
					
				else
					OspryAC.functions.Kick(
						Plr,
						"Do not attempt to forge Client Actions!",
						`Player has attempted to forge Client Actions data`
					)
				end
			end)
			
			--// "Get" RemoteFunction Connection
			ClientData:OnServerInvoke(function(Request, DataType : string)
				--// locals
				local Plr = Request.Client
				local Data = OspryAC.calls.Requests[DataType]
				OspryAC:debug(`Got Request from {Plr.Name} | {DataType}`)
				
				--// Check if DataType is valid
				if Data then
					return Request:Close(Data(Plr))
					
				else
					OspryAC:warn(`calls has recieved an invalid datatype from @{Plr.Name}.`)
					return Request:Raise("The Server has recieved an invalid datatype.")
				end
			end)
		end,
		
		
		
		-- Server Actions --
		
		--// Server Commands
		-- Regular calls used by the OspryAC RemoteEvent
		Commands = {
			-- Client Essentials --
			
			--// Initiates a Players Client
			Init_Client = function(Plr : Player)
				if OspryAC.Data.System.Client_Stats[Plr.UserId] then return end
				
				--// Generate Token
				OspryAC.tokens.Generate(Plr)
				
				--// Load Client
				OspryAC.Data.System.Client_Stats[Plr.UserId] = "Loading"
				OspryAC.calls.Send(Plr, "Load_Client")
			end,
			
			--// Sends a Client's load success to the Server
			Client_Loaded = function(Plr : Player)
				if OspryAC.Data.System.Client_Stats[Plr.UserId] ~= "Loading" then
					OspryAC.functions.Kick(
						Plr,
						"Do not attempt to forge Client calls!",
						`Player has attempt to forge "Client_Loaded" data.`
					)
					return
				end
				
				--// Set System
				OspryAC.Data.System.Client_Stats[Plr.UserId] = "Complete"
				OspryAC:debug(`Client loaded, {Plr.Name}`)
			end,
		},
		
		--// Client Actions
		-- All of these are used by the "Actions" RemoteEvent
		Actions = {
			--// Warns a Player from a Client Request
			Warn = function(Request, Reason : string, ModMessage : string, recvToken : number)
				--// locals
				local Plr = Request.Client
				local Token = OspryAC.tokens.Get(Plr)

				--// Check if Token is valid
				if recvToken ~= Token then
					--// Kick Player if Token does not match
					OspryAC.functions.Kick(
						Plr,
						"Invalid Token sent to Server",
						`Player has sent an invalid Token to the Server`
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
			end,
			
			--// Kicks a Player from a Client Request
			Kick = function(Request, Reason : string, ModMessage : string, recvToken : number)
				--// locals
				local Plr = Request.Client
				local Token = OspryAC.tokens.Get(Plr)

				--// Check if Token is valid
				if recvToken ~= Token then
					--// Kick Player if Token does not match
					OspryAC.functions.Kick(
						Plr,
						"Invalid Token sent to Server",
						`Player has sent an invalid Token to the Server`
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
			end,
		},
		
		--// Client Requests
		-- Requests for the "Get" RemoteFunction
		Requests = {
			--// Config Variables for the Client
			config = function()
				return {
					--// Detections
					NoclipDetection = OspryAC.Config.ClientSide.NoclipDetection,
					BtoolsDetection = OspryAC.Config.ClientSide.BtoolsDetection,
					GuiDetection = OspryAC.Config.ClientSide.GuiDetection,

					DexDetection = OspryAC.Config.ClientSide.DexDetection,
					AWPDetection = OspryAC.Config.ClientSide.AWPDetection,

					--// Development
					DebugMode = OspryAC.Config.Development.DebugMode,
				}
			end,
			
			--// Data Variables for the Client
			data = function()
				return {
					NoclipConfig = OspryAC.Data.NoclipDetection,
					WhitelistedGuis = OspryAC.Data.WhitelistedGuis,
				}
			end,
			
			--// Returns the Token for the Player
			token = function(Plr : Player)
				--// locals
				local Token = OspryAC.tokens.Get(Plr)

				local StrictTokens = OspryAC.Config.Behavior.Strict_Tokens
				local called_Tokens = OspryAC.Data.System.Called_Tokens
				local TokenWasCalled = table.find(OspryAC.Data.System.Called_Tokens, Plr.UserId)

				--// Check if Token was already called
				if StrictTokens and TokenWasCalled then
					--// Kick Player
					OspryAC.functions.Kick(
						Plr,
						"Token was attempted to be called twice.",
						`The "Get" RemoteFunction was called twice with the "token" Datatype.`
					)

				else
					--// Export and add to Called_Tokens
					if StrictTokens then table.insert(called_Tokens, Plr.UserId) end
					return Token
				end
			end,
		},
	}
end