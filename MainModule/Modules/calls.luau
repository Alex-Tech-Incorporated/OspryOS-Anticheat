-- OspryOS Anticheat calls --

--// Anticheat Framework
return function (OspryAC)
	--// locals
	--// Services
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")

	--// OspryAC
	local Config = OspryAC.Config
	local Data = OspryAC.Data
	
	local functions = OspryAC.functions
	local Tokens = OspryAC.tokens

	--// calls
	-- All of these get set once calls Initializes.
	local Remotes
	local ClientRemote
	local PunishRemote
	local ClientData

	--// Export
	return {
		--// Data
		Requests = {},

		--// Sends a Command to a Client
		Send = function(Plr : Player, command : string, ...)
			ClientRemote:FireClients({Plr}, command, ...)
		end,

		--// Sends a Command to all Clients
		SendAll = function(command : string, ...)
			ClientRemote:FireAllClients(command, ...)
		end,

		--// Sends a Get Request to the Client of a Player
		Get = function(Plr : Player, Timeout : number, Request : string, ...)
			--// Generate Request and ID
			local RequestID = tostring(Plr.UserId)
			OspryAC.calls.Requests[RequestID] = OspryAC.Signal.new()

			--// locals
			local end_time = os.clock() + (Timeout or 10)
			local returned_Data = nil

			--// Connections
			local return_signal = OspryAC.calls.Requests[RequestID]:Connect(function(...)
				returned_Data = {...}
			end)

			local Player_Removing = Players.PlayerRemoving:Connect(function(Player : Player)
				if Plr == Player then returned_Data = {} end
			end)

			--// Send Request
			OspryAC.calls.Send(Plr, "Get", Request, ...)

			repeat task.wait(1) until os.clock() > end_time or returned_Data ~= nil

			--// Disconnect Events
			return_signal:Disconnect()
			Player_Removing:Disconnect()
			OspryAC.calls.Requests[RequestID] = nil

			--// Export
			return table.unpack(returned_Data or {})
		end,

		--// Attempts to check if a Client loaded
		Is_ClientLoaded = function(Plr : Player): boolean
			--// locals
			local Timeout = RunService:IsStudio() and 1000 or Config.ClientSide.Load_Timeout
			local end_time = os.time() + Timeout

			--// Check if the Client already loaded
			if Data.System.Client_Stats[Plr.UserId] == "Complete" then
				return true
			end

			--// Wait for Client to Complete loading...
			repeat task.wait(1) until Data.System.Client_Stats[Plr.UserId] == "Complete" or os.time() > end_time or not Plr.Parent

			return Data.System.Client_Stats[Plr.UserId] == "Complete"
		end,

		--// Initiates the calls Module
		Init = function()
			--// Set locals
			Remotes = require(OspryAC.Remotes)
			ClientRemote = Remotes("OspryAC")
			PunishRemote = Remotes("Punish")
			ClientData = Remotes("Get")

			-- Remote Connections --

			--// OspryAC RemoteEvent Connection
			ClientRemote:OnServerEvent(function(Request, command : string, ...)
				--// locals
				local Plr = Request.Client

				--// Command
				local func = OspryAC.calls.Commands[command]
				if not func then
					OspryAC:warn(`Invalid function recieved "{command}" from {Plr.Name}`)
					return
				end

				--// Trigger
				func(Plr, ...)
			end)

			--// Actions RemoteEvent Connection
			PunishRemote:OnServerEvent(function(Request, sentToken : number, Detection : string, Reason : string, ModMessage : string)
				--// locals
				local Plr = Request.Client
				local Token = Tokens.Get(Plr)
				
				--// Debounce
				Request:Debounce(Plr, 1)
				
				--// Check Token
				if Token ~= sentToken then
					functions.Punish(
						"Invalid_Token", Plr,
						"The Server has recieved an invalid Token.",
						`The Player has sent an invalid Token to the Server during a Punish request`
					)
					return
				end

				--// Send to functions
				functions.Punish(Detection, Plr, Reason, ModMessage)
			end)

			--// "Get" RemoteFunction Connection
			ClientData:OnServerInvoke(function(Request, DataType : string, Token : number)
				--// locals
				local Plr = Request.Client
				local DataReq = OspryAC.calls.Returns[DataType]
				OspryAC:debug(`Got Request from {Plr.Name} | {DataType}`)

				--// Check if DataType is valid
				if DataReq then
					--// locals
					local fetchedData = DataReq(Plr, Token)

					--// Send to Client
					return
						if fetchedData then Request:Close(fetchedData)
						else Request:Raise("A Data Request has returned nil, please rejoin.")

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
				Data.System.Client_Stats[Plr.UserId] = "Loading"
				OspryAC.calls.Send(Plr, "Load_Client")
			end,

			--// Sends a Client's load success to the Server
			Client_Loaded = function(Plr : Player)
				if OspryAC.Data.System.Client_Stats[Plr.UserId] ~= "Loading" then
					functions.Punish(
						"Tamper_Attempt", Plr,
						"Do not attempt to forge Client Remote calls!",
						`Player has attempted to forge there Client's Loaded state.`
					)
					return
				end

				--// Set System
				Data.System.Client_Stats[Plr.UserId] = "Complete"
				OspryAC:debug(`Client loaded, {Plr.Name}`)

				-- Add some Client check logic here...
			end,

			--// Command for the Client to return requested data
			Client_Return = function(Plr : Player, ...)
				local UserId = tostring(Plr.UserId)
				local Request = OspryAC.calls.Requests[UserId]
				if not Request then return end
				OspryAC:debug(`Got Data return from Request ID: {Plr.UserId} | {...}`)

				--// Send Signal
				OspryAC.calls.Requests[UserId]:Fire(...)
			end,
		},

		--// Client Returns
		-- Data returns for the "Get" RemoteFunction
		Returns = {
			--// Config Variables for the Client
			config = function(Plr : Player, recvToken : number)
				--// locals
				local Token = OspryAC.tokens.Get(Plr)
				local strict_ClientReq = Config.Behavior.GetReq_RequireToken
				if Token and strict_ClientReq and Token ~= recvToken then
					functions.Punish(
						"Invalid_Token", Plr,
						"The Server has recieved an invalid token",
						`Player has sent a "Get" request with "config", but the sent Token does not match.`
					)
					return nil
				end

				--// Export to Client
				return {
					--// Detections
					NoclipDetection = Config.ClientSide.NoclipDetection,
					BtoolsDetection = Config.ClientSide.BtoolsDetection,
					GuiDetection = Config.ClientSide.GuiDetection,

					DexDetection = Config.ClientSide.DexDetection,
					AWPDetection = Config.ClientSide.AWPDetection,

					--// Development
					DebugMode = Config.Development.DebugMode,
				}
			end,

			--// Data Variables for the Client
			data = function(Plr : Player, recvToken : number)
				--// locals
				local Token = OspryAC.tokens.Get(Plr)
				local strict_ClientReq = Config.Behavior.GetReq_RequireToken
				if Token and strict_ClientReq and Token ~= recvToken then
					functions.Punish(
						"Invalid_Token", Plr,
						"The Server has recieved an invalid token",
						`Player has sent a "Get" request with "data", but the sent Token does not match.`
					)
					return nil
				end

				--// Export to Client
				return {
					NoclipConfig = Data.NoclipDetection,
					WhitelistedGuis = Data.WhitelistedGuis,
				}
			end,

			--// Returns the Token for the Player
			token = function(Plr : Player)
				--// locals
				local Token = OspryAC.tokens.Get(Plr)

				local StrictTokens = Config.Behavior.Strict_Tokens
				local called_Tokens = Data.System.Called_Tokens
				local Player_hasCalled = table.find(called_Tokens, Plr.UserId)

				--// Check if Token was already called
				if StrictTokens and Player_hasCalled then
					functions.Punish(
						"Tamper_Attempt", Plr,
						"Token was attempted to be called twice.",
						`Player has sent a "Get" request with "token", but the Token was already called.`
					)
					return nil
				end
				
				--// Export and add to Called_Tokens
				if StrictTokens then table.insert(called_Tokens, Plr.UserId) end
				return Token
			end,
		},
	}
end