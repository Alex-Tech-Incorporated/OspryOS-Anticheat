--// locals
--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

--// Player
local Plr = Players.LocalPlayer
local PlayerGui = Plr:WaitForChild("PlayerGui")

--// Client Framework
return function (Client)
	return {
		Init = function()
			Client:debug(`Initializing Detections...`)
			
			--// Gui Detection
			if Client.Config.GuiDetection then
				coroutine.wrap(function()
					--// Connects on Child Added
					PlayerGui.ChildAdded:Connect(function()
						for i, v in PlayerGui:GetChildren() do
							if not StarterGui:FindFirstChild(v.Name) then
								if table.find(Client.Data.WhitelistedGuis, v.Name) then
									-- Do nothing since its whitelisted
								else
									--// Destroy Gui and Warn Player (or kick, depending on Settings)
									v:Destroy() -- Deletes the Detected Gui
									Client:Warn("Unidentified Gui detected", "Player had a Gui called '"..v.Name.."' inserted into their PlayerGui.")
								end
							end
						end
					end)
				end)()
			end

			--// Btools detection
			if Client.Config.BtoolsDetection then
				--// locals
				local Flagged = false

				coroutine.wrap(function()
					Plr.CharacterAdded:Connect(function(Char : Model)
						Client:debug("Character loaded, starting Btools routine")

						--// Detection loop
						while true do
							task.wait()

							if Flagged then -- Since break cannot be used in the coroutines below, we instead call the kick like this so we can exit the loop without flooding the remote
								Client:Kick("Btools detected", "Player has attempted to use Btools")
								break
							end

							coroutine.wrap(function()  
								--// locals
								local Backpack = Plr:WaitForChild("Backpack")

								-- Checking for the name first, then we check if its actually Building Tools by looking for certain components within the tool
								if Backpack:FindFirstChild("Building Tools") ~= nil then
									if Backpack:FindFirstChild("Building Tools"):FindFirstChild("Interfaces"):FindFirstChild("BTAnchorToolGUI") then
										Flagged = true
									end
								end
							end)()

							coroutine.wrap(function()  
								-- Checking if the player exists so we can evaluate safely
								if Plr.Character == nil then
									Client:Debug("Character does not exist, skipping character check due to no character to check")	
								else
									-- To be extra safe, check for btools in a pcall so the thread does not clog-up due to errors
									pcall(function()
										if Plr.Character:FindFirstChildOfClass("Tool") ~= nil then
											if Plr.Character:FindFirstChildOfClass("Tool").Interfaces.BTAnchorToolGUI ~= nil then
												Flagged = true
											end
										end
									end)
								end
							end)()
						end
					end)
				end)()
			end

			--// Noclip Detection
			if Client.Config.NoclipDetection then
				coroutine.wrap(function()
					--// locals
					local ViolationCounter = 0 -- Allows for some leniency with false positives
					local CycleCounter = 0

					--// loop check
					while true do
						task.wait(2.1) -- Raycast calls can be expensive so we call them with slight delay

						-- Making sure we only check for active players
						if Plr.Character:FindFirstChild("HumanoidRootPart") ~= nil then
							-- Configuring the Casting Params we will use
							local CastConfig = RaycastParams.new()

							coroutine.wrap(function()
								CastConfig.FilterType = Enum.RaycastFilterType.Exclude
								CastConfig.IgnoreWater = Client.Data.NoclipConfig.IgnoreWaterForCasting
								CastConfig.FilterDescendantsInstances = Plr.Character:GetDescendants() -- This ensures the raycast ignores player objects when we check for no-clipping
							end)()

							local Cast = workspace:Raycast(Plr.Character:FindFirstChild("HumanoidRootPart").Position, Client.Data.NoclipConfig.NoclipEvaluationVector, CastConfig) -- The direction vector creates a cast within the player that only hits objects if they are inside of something (like a wall and so forth)

							-- If the cast hit something, begin secondary checks so we know that the player is no-clipping for sure
							if Cast then
								pcall(function() 
									local HitPart = Cast.Instance
									local VerifiedPrecision = false

									coroutine.wrap(function() 
										if Client.Data.NoclipConfig.PrecisionMode >= 3 then
											-- Another check for part validity (most precise)
											if HitPart.CanCollide and HitPart.CanTouch then
												VerifiedPrecision = true
											end
										end
										if Client.Data.NoclipConfig.PrecisionMode >= 2 then
											-- Also confirming CollisionGroups with the player/part (even more precise)
											if HitPart.CollisionGroup == Plr.Character:FindFirstChild("HumanoidRootPart").CollisionGroup then
												VerifiedPrecision = true
											end
										end
										if Client.Data.NoclipConfig.PrecisionMode >= 1 then
											-- Add verification to what we hit (more precise)
											if HitPart:IsA("BasePart")  or HitPart:IsA("UnionOperation") or HitPart:IsA("MeshPart") then 
												VerifiedPrecision = true
											end
										end
										if Client.Data.NoclipConfig.PrecisionMode <= 0 then -- Also ensures that negative value cases are handled 
											-- Always assume that they are no clipping (least precise)
											VerifiedPrecision = true
										end

										if VerifiedPrecision then
											ViolationCounter += 1
											Client:Debug("Predicted Noclip, ViolationCounter is now at", ViolationCounter)
										else
											Client:Debug("Did not Predict Noclip")
										end	
									end)()
								end)
							end

							-- By default, HumanoidRootPart should have CanCollide on, we can use this detail to detect more sneaky noclips
							if Client.Data.NoclipConfig.AggressiveCharacterValidation then
								--// locals
								local RootPart = Plr.Character:FindFirstChild("HumanoidRootPart")

								--// Check for Collision
								if RootPart.CanCollide == false then
									Client:Kick("Noclip detected", `HumanoidRootPart does not have CanCollide enabled`)
									break

								elseif not RootPart then
									Client:Kick("HumanoidRootPart not found or missing", "The HumanoidRootPart of the Player is missing or was not found.")
									break
								end
							end
						end

						--// ViolationCounter check
						if ViolationCounter >  Client.Data.NoclipConfig.MaxAllocatedViolations then
							Client:Kick("Noclip detected", `Player exceeded { Client.Data.NoclipConfig.MaxAllocatedViolations} violations at Cycle {CycleCounter}`)
							break
						end

						--// CycleCounter check
						if CycleCounter > Client.Data.NoclipConfig.ResetAllocationsPerCycleCount then
							CycleCounter = 0
							ViolationCounter = 0
						end

						--// Add to CycleCounter
						CycleCounter += 1
					end
				end)()
			end

			--// Dex Detection
			if Client.Config.DexDetection then
				coroutine.wrap(function()
					--// Wait for the Game to Load
					if not game:IsLoaded() then game.Loaded:Wait() end

					task.wait(3)
					local name = tostring(math.random())
					local Chat = game:GetService("Chat")
					Instance.new("BoolValue", Chat).Name = name -- make it and forget about it
					Client:debug("Game loaded, Dex Detection loop running.")

					local t = setmetatable({}, {__mode="v"})
					while task.wait() do
						t[1] = {}
						t[2] = Chat:FindFirstChild(name)
						while t[1] ~= nil do
							-- encourage the gc to move faster by adding a 4kb string
							t[3] = string.rep("ab", 1024*2)
							t[3] = nil
							task.wait()
						end
						if t[2] ~= nil then
							Client:Kick("Dex Explorer detected", "Invalid gc behavior detected")
							Client:debug("Dex Detection loop killed.")
							break
						end
					end
				end)()
			end

			--// AWP Detections
			if Client.Config.AWPDetection then
				coroutine.wrap(function()
					if RunService:IsStudio() then Client:debug("AWP Detection cannot be used in Studio.") return end

					--// locals
					local getfenv = getfenv
					local tick = tick

					--// Check
					local violations = 0
					while task.wait(0.2) do
						local t1 = tick()
						for i = 1, 1e4 do
							getfenv()
						end
						local t2 = tick()
						for i = 1, 1e4 do
							-- do nothing lol
						end
						local t3 = tick()
						local ratio = (t2-t1)/(t3-t2)
						if ratio > 25 then
							-- dont punish lag spikes, require 8 fails in a row
							violations = violations + 1
							if violations >= 8 then
								Client:Kick("AWP Injection detected.", "AWP has been detected with decent confidence (r8: "..ratio..").")
								Client:debug("AWP Detection loop killed.")
								break
							end
						else
							violations = 0
						end
					end

					Client:debug("AWP Detection loop running")
				end)()
			end
			
			--// Complete
			Client:debug(`Detections initialized.`)
		end,
	}
end