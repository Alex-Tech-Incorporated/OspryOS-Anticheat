return function (OspryAC)
	--// locals
	--// Services
	local Players = game:GetService("Players")
	
	--// Anticheat
	local Config = OspryAC.Config
	local Data = OspryAC.Data
	local functions = OspryAC.functions
	
	--// Data
	local Server = {
		--// System
		Prefixes = {"MagnitudeCheck_", "HumanoidCheck_"},
		
		--// Connects and Threads
		Running_Threads = {}, -- Format: [string (Name)] = Thread | RBXScriptConnection
		Connected = {}, -- Format: [number (UserId)] = { RBXScriptConnection }
	}
	
	-- Server functions --
	
	--// Creates a Coroutine and saves it in the Coroutine table
	function Server:CreateRoutine(Name : string, func)
		if Server.Running_Threads[Name] then
			OspryAC:warn(`The Coroutine "{Name}" already exists, the existing Coroutine has been stopped and replaced.`)
			Server:Disconnect(Name)
		end

		--// Create and Resume Coroutine
		local Thread = task.spawn(function()
			local success, result = xpcall(func, debug.traceback)
			if not success then
				OspryAC:warn(`Thread "{Name}" errored: {result}`)
			end
			
			--// Remove thread once finished
			if Server.Running_Threads[Name] == coroutine.running() then
				Server.Running_Threads[Name] = nil
			end
		end)

		--// Check if the Thread died
		if coroutine.status(Thread) ~= "dead" then
			Server.Running_Threads[Name] = Thread
			OspryAC:debug(`Thread "{Name}" created`)
		end
		return Thread
	end
	
	--// Saves a Connection to the Server table
	function Server:AddConnection(Name : string, Connection : RBXScriptConnection)
		if Server.Running_Threads[Name] then
			OspryAC:warn(`The Connection "{Name}" already exists, the existing Connection has been disconnected and replaced.`)
			Server:Disconnect(Name)
		end
		Server.Running_Threads[Name] = Connection
	end
	
	--// Disconnbects or Cancels a thread saved in the Server Table
	function Server:Disconnect(Name : string)
		local Entry = Server.Running_Threads[Name]
		if not Entry then return end

		if typeof(Entry) == "thread" then
			pcall(task.cancel, Entry)
		elseif typeof(Entry) == "RBXScriptConnection" then
			Entry:Disconnect()
		end

		Server.Running_Threads[Name] = nil
		OspryAC:debug(`Stopped "{Name}"`)
	end
	
	--// Stops all currently active checks for a Player
	function Server:StopChecks(UserId : number)
		for _, Prefix in ipairs(Server.Prefixes) do
			Server:Disconnect(Prefix..UserId)
		end
	end
	
	--// Sends Punishment data to functions
	function Server:Punish(Detection : string, Plr : Player, Reason : string, ModMessage : string)
		functions.Punish(Detection, Plr, Reason, ModMessage)
	end
	
	
	
	-- Internal functions --
	
	--// Starts all Server Checks for a Player
	local function StartChecks(Plr : Player, Char : Model)
		Server:StopChecks(Plr.UserId)
		task.spawn(OspryAC.Server_Module.MagCheck, Plr, Char)
		task.spawn(OspryAC.Server_Module.HumanoidCheck, Plr, Char)
	end
	
	
	
	-- Anticheat functions --
	return {
		--// Initialize
		Init = function()
			--// Connect Character to Checks
			local function ConnectChar(Plr : Player)
				if Server.Connected[Plr.UserId] then OspryAC:debug(`{Plr.Name} is already connected to checks`) return end
				
				--// locals
				local Connections = {}
				
				--// Connect Script Connections
				table.insert(Connections, Plr.CharacterAdded:Connect(function(Char : Model?)
					StartChecks(Plr, Char)
				end))
				
				--// Connect Cleanup
				table.insert(Connections, Plr.CharacterRemoving:Connect(function(Char : Model?)
					--// Cleanup
					OspryAC:debug(`Character removing of {Plr.Name}`)
					Server:StopChecks(Plr.UserId)

					--// Complete
					OspryAC:debug(`Character cleanup completed for {Char:GetFullName()}`)
				end))
				
				--// Check if Character already exists
				if Plr.Character then
					StartChecks(Plr, Plr.Character)
				end
				
				--// Connected
				Server.Connected[Plr.UserId] = Connections
				OspryAC:debug(`Connected {Plr.Name} to Server checks`)
			end
			
			--// Connect New Players
			Players.PlayerAdded:Connect(ConnectChar)
			
			--// Connect Existing Players
			for _, Plr in ipairs(Players:GetPlayers()) do
				ConnectChar(Plr)
			end
			OspryAC:debug(`Added existing players`)
			
			--// Complete
			OspryAC:debug(`Initialized Server Detections.`)
		end,
		
		--// Magnitude Check
		MagCheck = function(Plr : Player, RecvChar : Model?)
			if not Config.ServerSide.MagnitudeChecks then return end
			
			--// locals
			local Char = RecvChar or Plr.Character
			if Plr.Character ~= Char then return end
			
			local Humanoid = Char:WaitForChild("Humanoid") :: Humanoid?
			local RootPart = Char:WaitForChild("HumanoidRootPart") :: BasePart?
			
			--// Magnitude Check
			local function CheckMagnitude()
				if not RootPart then return end

				--// Get Previous Position and Humanoid State
				local Prev_Position = RootPart.Position
				local Prev_Humanoid_State = Humanoid:GetState()

				--// Delay comparison between previous and new Values
				task.delay(Data.MagnitudeChecks.CheckDelay, function()
					--// locals
					local Current_Position = RootPart.Position
					local New_Humanoid_State = Humanoid:GetState()
					local Distance = (Current_Position - Prev_Position).Magnitude

					--// Check for Rapid Magnitude changes
					if Distance < Data.MagnitudeChecks.Max_Magnitude then return end

					--// Compare Whitelisted States with New and Previous State
					local WhitelistedStates = Data.HumanoidChecks.WhitelistedStates
					if table.find(WhitelistedStates, New_Humanoid_State.Value)
						or table.find(WhitelistedStates, Prev_Humanoid_State.Value) then
						return
					end

					--// Ignore if the Player is not in the Air or if the Player died / reset
					if Humanoid.FloorMaterial ~= Enum.Material.Air or Humanoid.Health <= 0 then return end

					--// Punish
					Server:Punish(
						"MagnitudeCheck", Plr,
						"Abnormal Magnitude changes",
						`Player has exceeded {Data.MagnitudeChecks.Max_Magnitude} by {string.format("%.2f", Distance)} in {Data.MagnitudeChecks.CheckTime} second(s).`
					)
				end)
			end
			
			--// Create Coroutine
			Server:CreateRoutine("MagnitudeCheck_"..Plr.UserId, function()
				while task.wait(Data.MagnitudeChecks.CheckTime) do
					CheckMagnitude()
				end
			end)
			
			--// Complete
			OspryAC:debug(`Connected MagnitudeCheck to {Char:GetFullName()}`)
		end,
		
		--// Humanoid Check
		HumanoidCheck = function(Plr : Player, Char : Model?)
			if not Config.ServerSide.HumanoidChecks then return end
			
			--// locals
			local Humanoid = Char:WaitForChild("Humanoid", 5) :: Humanoid?
			if not Humanoid then
				OspryAC.warn(`{Char:GetFullName()} has no Humanoid, the check has been skipped.`)
				return
			end
			
			if Plr.Character ~= Char then return end
			
			--// Humanoid Check Connection
			local StateChanged = Humanoid.StateChanged:Connect(function(PrevState, NewState)
				if Humanoid.Health <= 0 or NewState == Enum.HumanoidStateType.Dead then return end
				
				--// Whitelist Check
				local isWhitelisted = table.find(
					Data.HumanoidChecks.WhitelistedStates,
					NewState.Value
				)
				local isPlatformStanding = Data.HumanoidChecks.CheckPlatformStanding and NewState == Enum.HumanoidStateType.PlatformStanding
				
				--// Compare
				if isPlatformStanding or not isWhitelisted then
					Server:Punish(
						"HumanoidCheck", Plr,
						"Unauthorized Humanoid State",
						`Humanoid State has switched from {PrevState.Name} ({PrevState.Value}) to {NewState.Name} ({NewState.Value})`
					)
				end
			end)
			
			--// Add to Connections
			Server:AddConnection(`HumanoidCheck_{Plr.UserId}`, StateChanged)
			
			--// Complete
			OspryAC:debug(`Connected HumanoidCheck to {Char:GetFullName()}`)
		end,
		
		--// Clears the Player from the "Connected" Table
		Leave_Cleanup = function(Plr : Player)
			--// Stop running checks
			Server:StopChecks(Plr.UserId)
			
			--// Disconnect active connections
			local Connections = Server.Connected[Plr.UserId]
			if Connections then
				for _, Connection in ipairs(Connections) do
					Connection:Disconnect()
				end
				Server.Connected[Plr.UserId] = nil
			end
			
			--// Complete
			OspryAC:debug(`Server cleanup completed for {Plr.Name}`)
		end,
	}
end