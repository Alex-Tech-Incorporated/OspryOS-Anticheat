--// Client Framework
return function (Client)
	return {
		--// RemoteEvents
		Event = Client.Remotes("OspryAC"),
		Action = Client.Remotes("Actions"),
		GetRemote = Client.Remotes("Get"),

		--// Sends a Request to the Server
		Send = function(ServerRequest : string, ...)
			Client:debug(`Sending {ServerRequest} to Server...`)
			Client.calls.Event:FireServer(ServerRequest, ...)
		end,
		
		--// Sends an Action to the Server
		Send_Action = function(Action : string , ...)
			Client.calls.Action:FireServer(Action, ...)
		end,

		--// Gets ServerData by using the Get RemoteFunction
		Get = function(DataType : string)
			--// locals
			local Data = Client.Mappings.Get:InvokeServer(DataType)

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

		--// Initiates the Remote Module
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
				--// Set Data
				Client.Loaded = true

				--// Get Configuration Variables
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
				
				
				
				-- Load Client --
				Client:debug(`Loading Client...`)
				
				--// Hide Client
				if not Client.Config.DebugMode then
					getfenv().script.Parent:Destroy()
					getfenv().script.Parent = nil
				end

				--// Get Token
				Client.Token = Client.calls.Get("token")
				Client:debug(`Got Token: {Client.Token}`)

				--// Create Proxy
				local ProxyContainer = newproxy(true)
				local ProxyTable = getmetatable(ProxyContainer)

				--// Lock Proxy
				coroutine.wrap(function()
					ProxyTable.__newindex = nil
					ProxyTable.__concat = nil
					ProxyTable.__tostring = "OspryOS Anticheat" -- Can be replaced with nil but adding this to confuse exploiters
					ProxyTable.__len = math.random(1, 9999)  -- Can be replaced with nil but adding this to confuse exploiters
					setmetatable(Client.Mappings, ProxyTable)
					ProxyTable.__metatable = nil -- Locks the table for set and get metatable methods

					Client:debug("Metatable locked.")
				end)()
				
				--// Initialize Modules
				Client:debug(`Initializing Modules...`)
				for _, module in Client.ModuleLoad_Order do
					module.Init()
				end
				
				--// Complete
				Client:debug(`Client loaded.`)
				Client.calls.Send("Client_Loaded")
			end,
			
			--// Displays a Gui
			-- Literally just fires a function on the Gui Module.
			DisplayGui = function(GuiType : string, ...)
				Client.Gui.Actions[GuiType](...)
			end,
		},
	}
end