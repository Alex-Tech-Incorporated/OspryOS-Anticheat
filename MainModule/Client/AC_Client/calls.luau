--// Client Framework
return function (Client)
	return {
		--// RemoteEvents
		Event = Client.Remotes("OspryAC"),
		Punish = Client.Remotes("Punish"),
		GetRemote = Client.Remotes("Get"),

		--// Sends a Request to the Server
		Send = function(ServerRequest : string, ...)
			Client:debug(`Sending {ServerRequest} to Server...`)
			Client.calls.Event:FireServer(ServerRequest, ...)
		end,
		
		--// Sends Punish data to the Server
		Send_Punish = function(Detection : string, Reason : string, ModMessage : string)
			Client.calls.Punish:FireServer(Client.Token, Detection, Reason, ModMessage)
		end,

		--// Gets ServerData by using the Get RemoteFunction
		Get = function(DataType : string)
			--// locals
			local Data = Client.calls.GetRemote:InvokeServer(DataType, Client.Token)

			--// Check Response
			if not Data.Success then
				Client.Plr:Kick(
					"The Server has responded with an Exception while trying to get Data."
					..`\n{Data.Exception}`
				)

			else
				return Data.Data
			end
		end,

		--// Initiates the calls Module
		Init = function()
			--// Setup
			Client.calls.Event:OnClientEvent(function(Request, command : string, ...)
				Client.calls.Commands[command](...)
			end)
		end,
		
		
		
		-- Client Actions --
		
		--// A list of functions the Server can use
		Commands = {
			--// Loads the Client
			Load_Client = function()
				if Client.Loaded then return end
				Client.Loaded = true
				
				--// Get Token
				Client.Token = Client.calls.Get("token")

				--// locals
				local start = os.clock()
				local Config = Client.calls.Get("config")
				local Data = Client.calls.Get("data")
				
				--// Configure
				for key, value in pairs(Config) do
					if Client.Config[key] ~= nil then
						Client.Config[key] = value
					end
				end

				--// Write Data
				for key, value in pairs(Data) do
					if Client.Data[key] ~= nil then
						Client.Data[key] = value
					end
				end
				Client:debug(`Configured.`)
				Client:debug(`Got Token: {Client.Token}`)
				
				
				
				-- Load Client --
				Client:debug(`Loading Client...`)
				
				--// Hide Client
				if not Client.Config.DebugMode then
					--// Rename Client
					script.Parent.Name = game:GetService("HttpService"):GenerateGUID(true)
					
					--// Hide Client
					-- getfenv().script.Parent:Destroy() -- I don't think this messes with anything, going to keep it like this though.
					getfenv().script.Parent = nil
				end

				--// Create Proxy
				local ProxyContainer = newproxy(true)
				local ProxyTable = getmetatable(ProxyContainer)
				
				--// Lock Proxy
				coroutine.wrap(function()
					--// Freeze Config and Data
					table.freeze(Client.Config)
					table.freeze(Client.Data)
					table.freeze(Client.Data.NoclipConfig)
					table.freeze(Client.Data.WhitelistedGuis)
					Client:debug(`Froze Config and Data Tables.`)
					
					--[[ -- These cause issues with Client behavior, so they will remain unused.
					ProxyTable.__newindex = nil
					ProxyTable.__concat = nil
					ProxyTable.__tostring = "OspryOS Anticheat" -- Can be replaced with nil but adding this to confuse exploiters
					ProxyTable.__len = math.random(1, 9999)  -- Can be replaced with nil but adding this to confuse exploiters
					
					
					--// Set Metatable and lock
					setmetatable(Client, ProxyTable)
					ProxyTable.__metatable = nil -- Locks the table for set and get metatable methods
					
					Client:debug(`Metatable locked.`)
					]]
				end)()
				
				--// Initialize Modules
				Client:debug(`Initializing Modules...`)
				for _, module in Client.ModuleLoad_Order do
					module.Init()
				end
				
				--// Complete
				Client:debug(`Client loaded, took: {os.clock() - start} seconds.`)
				Client.calls.Send("Client_Loaded")
			end,
			
			--// Displays a Gui
			-- Literally just fires a function on the Gui Module.
			DisplayGui = function(GuiType : string, ...)
				Client.Gui.Actions[GuiType](...)
			end,
			
			--// Allows to the Server to access Returns from the Client
			Get = function(Request : string, ...)
				--// locals
				local Return = Client.calls.Returns[Request]
				
				--// Send to Client
				Client.calls.Send("Client_Return", Return(...))
			end,
		},
		
		--// A list of Returnables that the Server could request
		Returns = {
			--// Pong!
			Ping = function()
				return "Pong!"
			end,
		},
	}
end