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
				
				local GuiClient = OspryAC.Client.Guis:WaitForChild("Gui_Client") :: LocalScript
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
				
				--// Clone Client to Player
				if OspryAC.Config.ClientSide.Enabled then
					--// Clone Client Module and Generate Token
					task.spawn(function()
						--// locals
						local ClientBase = OspryAC.Client:WaitForChild("Anticheat_Client")
						local isWhitelisted = OspryAC.functions.CheckWhitelists(Plr)
						if isWhitelisted then OspryAC:debug(`{Plr.Name} is Whitelisted, Client initialization skipped.`) return end
						
						--// Clone Module
						local ClientModule = ClientBase:Clone()
						
						--// Generate Token
						OspryAC.tokens.GenerateToken(Plr)

						--// Insert and Enable
						ClientModule.Parent = PlayerGui -- Why is there no way to put this into PlayerScripts?
						ClientModule.Enabled = true
					end)
				end
				
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
				
				--// Clone and Insert Gui Client
				local OspryAC_GuiClient = GuiClient:Clone()
				OspryAC_GuiClient.Name = "__OspryAC_Gui_Client"
				OspryAC_GuiClient.Enabled = true
				OspryAC_GuiClient.Parent = PlayerGui
			end)
			
			--// Connection for the Anticheat to cleanup Player Data as soon as the Player leaves
			Players.PlayerRemoving:Connect(function(Plr : Player)
				OspryAC:debug("Player leaving,", Plr.Name)
				
				--// locals
				local Token = OspryAC.tokens.GetToken(Plr)
				local Called_Tokens = OspryAC.Data.System.Called_Tokens
				
				local hasCalledToken = table.find(
					Called_Tokens,
					Plr.UserId
				)
				
				--// Clear Token if present
				if Token then
					OspryAC.Data.System.Tokens[Plr.UserId] = nil
					
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
			
			--// Check Adonis _G API
			if WhitelistConfig.AdonisWhitelist and AdonisAPI then
				--// pcall API Request
				-- Should prevent the _G API's hard crash effecting the Whitelist.
				local success, result = pcall(function()
					return AdonisAPI.CheckAdmin(Plr)
				end)
				
				--// Check Response
				if not success then
					OspryAC:warn("Failed to reach _G.Adonis!")
					OspryAC:warn(`{result}`)
					
				else
					--// Export CheckAdmin result
					return result
				end
				
			elseif WhitelistConfig.AdonisWhitelist and not AdonisAPI then
				OspryAC:warn("_G.Adonis not found, is Adonis installed and running?")
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
			
			--// locals
			local Remotes = require(OspryAC.Remotes)
			local GuiRemote = Remotes("GuiSystem")
			
			--// Send to Clients
			GuiRemote:FireAllClients(
				"Announce",
				if OspryAC.Config.Behavior.ShowKickReason
					then Reason
					else "User has been kicked for Exploiting",
				KickedPlr
			)
		end,
		
		--// Notifies a Player about a Warning
		NotifyWarning = function(Plr : Player, Reason : string)
			--// locals
			local Remotes = require(OspryAC.Remotes)
			local GuiRemote = Remotes("GuiSystem")
			
			--// Send to Client
			GuiRemote:FireClients(
				{Plr}, -- Yes, this has to be a Table.
				"Warning",
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