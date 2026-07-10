--// locals
--// Services
local TS = game:GetService("TweenService")

--// TweenService
local AnnInfo = TweenInfo.new(
	0.4,
	Enum.EasingStyle.Exponential
)
local WarnInfo = TweenInfo.new(
	0.4,
	Enum.EasingStyle.Exponential
)

--// Client Framework
return function (Client)
	--// locals (Client-dependant)
	local Plr = Client.Plr :: Player?
	local PlayerGui = Plr:WaitForChild("PlayerGui")
	
	local AnnouncementGui = PlayerGui:WaitForChild("__OspryAC_KickAnnounce", 10)
	local WarnGui = PlayerGui:WaitForChild("__OsprAC_WarnGui", 10)
	
	--// Export
	return {
		--// Actions
		Actions = {
			--// Displays an Announcement, showing who was Kicked any why (If ShowReason is set to true)
			Announce = function(Reason : string, KickedPlr : Player)
				if not AnnouncementGui then return end
				
				--// Check for Debounce
				if Client.Deb.Announcement then return end
				Client.Deb.Announcement = true
				
				--// locals
				local Background = AnnouncementGui:WaitForChild("Main")
				local UIScale = Background:WaitForChild("UIScale")

				local TextHolder = Background:WaitForChild("TextHolder")
				local PlayerName = TextHolder:WaitForChild("PlayerName")
				local ReasonText = TextHolder:WaitForChild("Reason")

				--// Edit Text
				PlayerName.Text = "Player: "..KickedPlr.Name
				ReasonText.Text = Reason

				--// Show Gui
				TS:Create(UIScale, AnnInfo, {Scale = 1}):Play()

				task.wait(5)

				--// Hide Gui
				TS:Create(UIScale, AnnInfo, {Scale = 0}):Play()

				--// Debounce
				Client.Deb.Announcement = false
			end,
			
			--// Displays the issued Warning to the Player
			Warning = function(Reason : string)
				if not WarnGui then return end
				
				--// Check for Debounce
				if Client.Deb.Warning then return end
				Client.Deb.Warning = true
				
				--// locals
				local Background = WarnGui:WaitForChild("Main")
				local UIScale = Background:WaitForChild("UIScale")
				
				local TextHolder = Background:WaitForChild("TextHolder")
				local ReasonText = TextHolder:WaitForChild("Reason")
				local DismisButton = Background:WaitForChild("Dismis")
				
				-- Internal functions --
				
				--// Starts a small Cooldown before the Player can press "Dismis"
				local function ClickCooldown(SetDuration : number)
					--// locals
					local Duration =  SetDuration
					
					--// Lock Button
					DismisButton.Interactable = false
					DismisButton.Text = "Dismis ("..Duration..")"
					DismisButton.BackgroundTransparency = 0.8
					
					--// Button Timer
					repeat
						--// Edit Text
						DismisButton.Text = "Dismis ("..Duration..")"
						
						task.wait(1)
						
						Duration = Duration -1
					until Duration == 0
					
					task.wait(Duration)
					
					--// Unlock Button
					DismisButton.Interactable = true
					DismisButton.Text = "Dismis"
					TS:Create(DismisButton, WarnInfo, {BackgroundTransparency = 0.4}):Play()
				end
				
				--// Edit Text
				ReasonText.Text = "You have been given a Warning for the following reason,\n"..Reason
				
				--// Show Gui
				TS:Create(UIScale, WarnInfo, {Scale = 1}):Play()
				
				--// Dismis Cooldown
				ClickCooldown(5)
				
				
				
				-- Connect Dismis --
				DismisButton.MouseButton1Click:Connect(function()
					--// Close Window
					TS:Create(UIScale, WarnInfo, {Scale = 0}):Play()

					--// Disable Debounce
					task.delay(0.4, function() Client.Deb.Warning = false end)
				end)
			end,
		},
	}
end