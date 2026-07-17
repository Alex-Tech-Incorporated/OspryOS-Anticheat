-- OspryOS Anticheat functions --

--// locals
--// Services
local Players = game:GetService("Players")
local GroupService = game:GetService("GroupService")



--// Anticheat Framework
return function (OspryAC)
	--// Exported functions
	return {
		--// Initiates the functions module
		Init = function()
			--// Connection for the Anticheat to initialize its Client features
			Players.PlayerAdded:Connect(function(Plr : Player)
				OspryAC:debug("Player joined,", Plr.Name)
				
				--// locals
				local PlayerGui = Plr:WaitForChild("PlayerGui")
				
				-- // Gui Data
				local GuiData = {
					--// KickAnnounce Gui Data
					KickAnnounce = {
						Enabled = OspryAC.Config.Behavior.AnnounceKicks,
						Gui = OspryAC.Client.Guis:WaitForChild("KickAnnounce"),
						Final = "__OspryAC_KickAnnounce",
					},

					--// WarningPopup Gui Data
					WarningPopup = {
						Enabled = OspryAC.Config.Behavior.Warnings,
						Gui = OspryAC.Client.Guis:WaitForChild("WarningPopup"),
						Final = "__OsprAC_WarnGui",
					},
				}
				
				--// Clone Guis into PlayerGui
				for Gui, Data in pairs(GuiData) do
					if not Data.Enabled then continue end
					
					--// Clone to PlayerGui
					local Clone = Data.Gui:Clone()
					Clone.Name = Data.Final
					Clone.Parent = PlayerGui
					
					--// Complete
					OspryAC:debug(`Cloned "{Clone.Name}" into`, PlayerGui:GetFullName())
				end
			end)
			
			--// Connection for the Anticheat to cleanup Player Data as soon as the Player leaves
			Players.PlayerRemoving:Connect(function(Plr : Player)
				OspryAC:debug("Player leaving,", Plr.Name)
				
				--// locals
				local Token = OspryAC.tokens.Get(Plr)
				local Called_Tokens = OspryAC.Data.System.Called_Tokens
				
				local hasCalledToken = table.find(
					Called_Tokens,
					Plr.UserId
				)
				
				--// Clear Data Tables
				OspryAC.Data.System.Client_Stats[Plr.UserId] = nil
				OspryAC.Data.System.Tokens[Plr.UserId] = nil
				
				--// Clear Token if present
				if Token then
					--// Check if Strict Tokens is active, and clear User from Table
					if hasCalledToken then
						for i, v in pairs(Called_Tokens) do
							if v == Plr.UserId then
								table.remove(Called_Tokens, i)
								break
							end
						end
					end
				end
				OspryAC:debug(OspryAC.Data.System)
				
				--// Cleanup Complete
				OspryAC:debug(`Cleanup completetd, {Plr.Name}`)
			end)
			
			OspryAC:debug("functions initialized.")
		end,
		
		--// Checks all the Anticheat's Whitelists if a Player is on them
		CheckWhitelists = function(Plr : Player)
			--// locals
			local AdonisAPI = _G.Adonis
			-- local ArclightAPI = _G.Arclight -- Support for an Adonis fork, coming soon.
			
			local WhitelistConfig = OspryAC.Config.Whitelists
			
			--// Check _G.Adonis
			if WhitelistConfig.AdonisWhitelist and AdonisAPI then
				--// Check if _G.Adonis is reachable
				-- Should prevent the Script hard crashing if the _G API is disabled
				-- Also, why is this a thing?
				local success, result = pcall(function()
					return AdonisAPI.GetLevel(Plr)
				end)
				
				--// Check Response
				if not success then
					OspryAC:warn(`Failed to reach _G.Adonis!`)
					OspryAC:warn(`{result}`)
					
				else
					--// Check if Result is over Minimum Level
					if result >= WhitelistConfig.Min_Level then return true end
				end
				
			elseif WhitelistConfig.AdonisWhitelist and not AdonisAPI then
				OspryAC:warn(`_G.Adonis was not found, is Adonis running?`)
			end
			
			--// Check Player Whitelist
			if table.find(OspryAC.Config.Whitelists.Players, Plr.Name) or table.find(OspryAC.Config.Whitelists.Players, Plr.UserId) then
				return true
			end
			
			--// Check Group Rank in Whitelisted Groups
			for groupID, minRank in pairs(OspryAC.Config.Whitelists.Groups) do
				if typeof(groupID) == "number" then
					if Plr:GetRankInGroupAsync(groupID) >= minRank then
						return true
					end
					
				else
					OspryAC:warn(`groupID is not a number! Got: {groupID}`)
				end
			end
			
			--// User is not Whitelist, so this will return false.
			-- Also acts as a failsafe incase all checks fail.
			return false
		end,
		
		--// Announces if a User is kicked to all Players currently in-game
		AnnounceToClients = function(KickedPlr : Player, Reason : string)
			if not OspryAC.Config.Behavior.AnnounceKicks then return end
			
			--// Send to Clients
			OspryAC.calls.SendAll(
				"DisplayGui", "Announce",
				if OspryAC.Config.Behavior.ShowKickReason
					then Reason
					else "User has been kicked for Exploiting",
				KickedPlr
			)
		end,
		
		--// Notifies a Player about a Warning
		NotifyWarning = function(Plr : Player, Reason : string)
			if not OspryAC.Config.Behavior.Warnings then return end
			
			--// Send to Client
			OspryAC.calls.Send(
				Plr, "DisplayGui", "Warning",
				if OspryAC.Config.Behavior.ShowKickReason
					then Reason
					else "A Detection has been tripped."
			)
		end,
		
		
		
		--// Kicks a Player from the Game
		Kick = function(Plr : Player, Reason : string, ModMessage : string)
			--// locals
			local isWhitelisted = OspryAC.functions.CheckWhitelists(Plr)
			if isWhitelisted then return end
			
			--// Send to Webhook and Announce
			OspryAC.HTTP.SendKickToWebhook(Plr, Reason, ModMessage)
			OspryAC.functions.AnnounceToClients(Plr, Reason)
			
			--// Kick
			if not OspryAC.Config.Development.DebugMode then
				Plr:Kick(
					"[OspryOS Anticheat]"
					.."\nYou have been kicked for Exploiting"
					..if OspryAC.Config.Behavior.ShowKickReason then "\n\nReason:\n"..Reason else ""
				)
				
				--// Print
				OspryAC:warn(`{Plr.Name} has been kicked. Reason: {Reason}`)
			else
				--// Debug Print
				OspryAC:debug(
					`\n{Plr.Name} ({Plr.UserId})`
					..`\n{Reason}`
					..`\n{ModMessage}`
				)
			end
		end,
		
		--// Issues a Warning to a Player
		Warn = function(Plr : Player, Reason : string, ModMessage : string)
			if not OspryAC.Config.Behavior.Warnings then
				--// Kick Player
				OspryAC.functions.Kick(
					Plr,
					Reason,
					ModMessage
				)
				return
			end
			
			--// locals
			local isWhitelisted = OspryAC.functions.CheckWhitelists(Plr)
			local currentWarns = OspryAC.Data.System.Warnings[Plr.UserId] or 0
			if isWhitelisted then return end
			
			--// Check Warnings
			if currentWarns >= OspryAC.Config.Behavior.Max_Warns then
				OspryAC.functions.Kick(
					Plr,
					"Maximum Warnings exceeded",
					`Player has exceeded the Maximum Warnings set ({OspryAC.Config.Behavior.Max_Warns} Warnings)`
				)
				
			else
				--// Issue Warning
				OspryAC.Data.System.Warnings[Plr.UserId] = currentWarns +1
				OspryAC:debug(`{Plr.Name}: {OspryAC.Data.System.Warnings[Plr.UserId]}/{OspryAC.Config.Behavior.Max_Warns}`)
				
				--// Send to Webhook
				OspryAC.HTTP.SendWarnToWebhook(Plr, Reason, ModMessage)
				OspryAC.functions.NotifyWarning(Plr, Reason)
				
				--// Prints
				OspryAC:debug(`{Plr.Name} has been issued a Warning.`)
			end
		end,
	}
end