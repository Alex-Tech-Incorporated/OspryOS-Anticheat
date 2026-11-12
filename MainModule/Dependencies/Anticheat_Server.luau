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
		Running_Threads = {}, -- Format: [string] = Thread | RBXScriptConnection
	}
	
	-- Server functions --
	
	--// Creates a Coroutine and saves it in the Coroutine table
	function Server:CreateRoutine(Name : string, func)
		if Server.Running_Threads[Name] then
			OspryAC:warn(`The Coroutine "{Name}" already exists, the existing Coroutine has been overwritten.`)
		end

		--// Create and Resume Coroutine
		local Thread = coroutine.create(func)
		local success, result = coroutine.resume(Thread)

		--// Check if Coroutine failed
		if not success then
			OspryAC:warn(`Failed to create Coroutine "{Name}", got: {result}`)
			return nil
		end

		--// Add to Table
		OspryAC:debug(`Coroutine "{Name}" created?`)
		Server.Running_Threads[Name] = Thread
		return Thread
	end
	
	--// Saves a Connection to the Server table
	function Server:AddConnection(Name : string, Connection : RBXScriptConnection)
		Server.Running_Threads[Name] = Connection
	end
	
	--// Sends Punishment data to functions
	function Server:Punish(Detection : string, Plr : Player, Reason : string, ModMessage : string)
		functions.Punish(Detection, Plr, Reason, ModMessage)
	end
	
	
	
	-- Anticheat functions --
	return {
		--// Initialize
		Init = function()
			--// Connect New Players
			Players.PlayerAdded:Connect(function(Plr : Player)
				--// Connect Character to Checks
				Plr.CharacterAdded:Connect(function(Char : Model)
					--// Connect Checks
					OspryAC.Server_Module.MagCheck(Plr)
					OspryAC.Server_Module.HumanoidCheck(Plr)
				end)
				
				--// Cleanup Sequence
				Plr.CharacterRemoving:Connect(function(Char : Model)
					OspryAC:debug(`Character removing of {Plr.Name}`)

					--// Disconnect Threads and Connections
					for Name, Thread in pairs(Server.Running_Threads) do
						if Name:match(Plr.UserId) then
							OspryAC:debug(Name, typeof(Thread))
							
							--// Check type
							if typeof(Thread) == "thread" then
								--// Cancel / Remove thread
								task.cancel(Thread)
								Server.Running_Threads[Name] = nil

								OspryAC:debug(`Thread "{Name}" cancelled for {Char.Name}`)
								
							elseif typeof(Thread) == "RBXScriptConnection" then
								--// Disconnect and Remove Connection
								Thread:Disconnect()
								Server.Running_Threads[Name] = nil
								
								OspryAC:debug(`Connection "{Name}" disconnected for {Char.Name}`)
							end
						end
					end

					--// Complete
					OspryAC:debug(`Character cleanup completed for {Char:GetFullName()}`)
				end)
			end)
			
			--// Connect Existing Players
			for _, Plr in pairs(Players:GetPlayers()) do
				--// Connect Detections
				OspryAC.Server_Module.MagCheck(Plr)
				OspryAC.Server_Module.HumanoidCheck(Plr)
			end
			OspryAC:debug(`Added existing Players`)
			
			--// Complete
			OspryAC:debug(`Initialized Server Detections.`)
		end,
		
		--// Magnitude Check
		MagCheck = function(Plr : Player)
			if not Config.ServerSide.MagnitudeChecks then return end
			
			--// locals
			local Char = Plr.Character
			if not Char then return end
			
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

					--// Check for Rapid Magnitude changes
					if (Current_Position - Prev_Position).Magnitude >= Data.MagnitudeChecks.Max_Magnitude then
						--// Compare Whitelisted States with New and Previous State
						local isWhitelistedState = table.find(
							Data.HumanoidChecks.WhitelistedStates,
							New_Humanoid_State.Value
						)
						local isPreviousState = table.find(
							Data.HumanoidChecks.WhitelistedStates,
							Prev_Humanoid_State.Value
						)
						if isWhitelistedState or isPreviousState then return end

						--// Ignore if the Player is not in the Air or if the Player died / resetted
						if Humanoid.FloorMaterial ~= Enum.Material.Air or Humanoid.Health == 0 then return end

						--// Punish
						Server:Punish(
							"MagnitudeCheck", Plr,
							"Abnormal Magnitude changes",
							`Player has exceeded {Data.MagnitudeChecks.Max_Magnitude} by {tostring(Current_Position.Magnitude)} in {Data.MagnitudeChecks.CheckTime} second(s).`
						)
					end
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
		HumanoidCheck = function(Plr : Player)
			if not Config.ServerSide.HumanoidChecks then return end
			
			--// locals
			local Char = Plr.Character
			if not Char then return end

			local Humanoid = Char:WaitForChild("Humanoid") :: Humanoid?
			
			--// Humanoid Check Connection
			local StateChanged = Humanoid.StateChanged:Connect(function(PrevState, NewState)
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
						`Humanoid State has switched from {PrevState.Value} to {NewState.Value}`
					)
				end
			end)
			
			--// Add to Connections
			Server:AddConnection(`HumanoidCheck_{Plr.UserId}`, StateChanged)
			
			--// Complete
			OspryAC:debug(`Connected HumanoidCheck to {Char:GetFullName()}`)
		end,
	}
end