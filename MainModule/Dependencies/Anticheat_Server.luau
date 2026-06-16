--[[
	OspryOS Anticheat - A simple and lightweight Anticheat System
    Copyright (C) 2026 Alexkist (https://github.com/Alexkist)

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as
    published by the Free Software Foundation, either version 3 of the
    License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]

--// locals
--// Services
local Players = game:GetService("Players")



--// Server Table
local Server = {
	Coroutines = {}, -- ["Name"] = Thread
}



--// OspryOS Anticheat Framework
return function (OspryAC)
	--// locals
	local Settings = OspryAC.Config
	local Data = OspryAC.Data
	local functions = OspryAC.functions
	
	
	
	-- Server functions --

	--// Creates a Coroutine
	function Server:CreateCoroutine(Name : string, func)
		if Server.Coroutines[Name] then
			OspryAC:print(`The Coroutine "{Name}" already exists, the existing Coroutine has been overwritten.`)
		end
		
		--// Create and Resume Coroutine
		local Thread = coroutine.create(func)
		local success, result = coroutine.resume(Thread)
		
		--// Check if Coroutine failed
		if not success then
			OspryAC:warn(`Failed to create Coroutine "{Name}", got: {result}`)
		end

		--// Add to Table
		OspryAC:debug(`Coroutine "{Name}" created?`)
		Server.Coroutines[Name] = Thread
		return Thread
	end
	
	--// Fires the .Kick() function within functions
	function Server:Kick(Plr : Player, Reason : string, ModMessage : string)
		functions.Kick(
			Plr,
			Reason,
			ModMessage
		)
	end
	
	--// Fires the .Warn() function within functions
	function Server:Warn(Plr : Player, Reason : string, ModMessage : string)
		--// Check if Warnings are enabled
		if not Settings.Behavior.Warnings then
			Server:Kick(Plr, Reason, ModMessage)
			return
		end
		
		--// Issue Warn
		functions.Warn(
			Plr,
			Reason,
			ModMessage
		)
	end
	
	--// Export
	return {
		--// Initializes the Server
		Init = function()
			-- Player / Character Detections --
			Players.PlayerAdded:Connect(function(Plr : Player)
				--// Character Detections
				Plr.CharacterAdded:Connect(function(Char : Model)
					OspryAC:debug(`Character added, {Plr.Name}`)
					
					--// locals
					local Humanoid = Char:WaitForChild("Humanoid") :: Humanoid
					local RootPart = Char:WaitForChild("HumanoidRootPart")
					
					
					
					--// Magnitude Check
					local function CheckMagnitude()
						if not Settings.MagnitudeChecks then return end
						
						--// Check for RootPart
						if not RootPart then
							Server:Kick(
								Plr,
								`"HumanoidRootPart" not found in Character.`,
								`Player has no "HumanoidRootPart" within there Character.`
							)
							return
						end
						
						--// Get Previous Position and Humanoid State
						local Prev_Position = RootPart.Position
						local Prev_Humanoid_State = Humanoid:GetState()
						
						--// Delay comparison between previous and new Values
						task.delay(Data.MagnitudeChecks.CheckDelay, function()
							--// locals
							local Current_Position = RootPart.Position
							local HumanoidState = Humanoid:GetState()
							
							--// Check for Rapid Magnitude changes
							if (Current_Position - Prev_Position).Magnitude >= Data.MagnitudeChecks.Max_Magnitude then
								--// Check Whitelisted States
								local isWhitelistedState = table.find(
									Data.HumanoidChecks.WhitelistedStates,
									HumanoidState.Value
								)
								local isPreviousState = table.find(
									Data.HumanoidChecks.WhitelistedStates,
									Prev_Humanoid_State.Value
								)
								if isWhitelistedState or isPreviousState then return end
								
								--// Ignore if the Player is not in the Air or if the Player died / resetted
								if Humanoid.FloorMaterial ~= Enum.Material.Air or Humanoid.Health == 0 then return end
								
								--// Issue Warning or Kick
								Server:Warn(
									Plr,
									"Abnormal Magnitude changes",
									`Player has exceeded {Data.MagnitudeChecks.Max_Magnitude} by {tostring(Current_Position.Magnitude)} in {tostring(Data.MagnitudeChecks.CheckTime)} second(s).`
								)
							end
						end)
					end
					
					
					
					-- Humanoid State changes --
					if Settings.ServerSide.HumanoidChecks then
						Humanoid.StateChanged:Connect(function(Prev_State, New_State)
							--// locals
							local isWhitelistedState = table.find(
								Data.HumanoidChecks.WhitelistedStates,
								New_State.Value
							)
							
							--// Compare States
							if Data.HumanoidChecks.CheckPlatformStanding and New_State == Enum.HumanoidStateType.PlatformStanding or not isWhitelistedState then
								--// Kick Player
								Server:Kick(
									Plr,
									"Unathorized Humanoid State",
									`Humanoid State has switched from {Prev_State.Value} to {New_State.Value}`
								)
							end
						end)
						OspryAC:debug(`Connected Humanoid.StateChanged to {Char:GetFullName()}`)
					end
					
					
					
					-- Coroutines --
					
					--// MagnitudeChecks Coroutine
					if Settings.ServerSide.MagnitudeChecks then
						--// Create Coroutine
						Server:CreateCoroutine("MagnitudeCheck", function()
							while task.wait(Data.MagnitudeChecks.CheckTime) do
								CheckMagnitude()
							end
						end)
					end
					
					--// Complete
					OspryAC:print(`Server-Sided Anticheat initialized.`)
				end)
			end)
		end,
	}
end