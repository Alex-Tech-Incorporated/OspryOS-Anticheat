-- OspryOS Anticheat Gui-Client --

--// locals
--// Services
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")

--// ReplicatedStorage
local RemotesModule
local Remotes

--// RemoteEvents
local GuiSystem

--// Player
local Plr = Players.LocalPlayer
local PlayerGui = script.Parent

--// Guis
local KickAnnounce
local WarnGui

--// System Table
local GuiClient = {
	--// Debounce
	Deb = {
		Kick = false,
		Warning = false,
	},
}

--// Prints
function GuiClient:print(...)
	print("[OspryAC Gui-Client]:", ...)
end
function GuiClient:warn(...)
	warn("[OspryAC Gui-Client]:", ...)
end



-- Client functions --

--// Initializes the Gui-Client
function GuiClient:Init()
	GuiClient:print("Initializing...")
	
	--// Get OspryAC Remotes
	RemotesModule = RS:WaitForChild("OspryAC_Remotes", 120)
	if not RemotesModule then
		GuiClient:warn("Failed to fetch Anticheat Remotes, waited 120 seconds.")
		return
	end
	
	--// Require Remotes and Set locals
	Remotes = require(RemotesModule)
	GuiSystem = Remotes("GuiSystem")
	
	--// Get Guis
	KickAnnounce = PlayerGui:WaitForChild("__OspryAC_KickAnnounce", 5)
	WarnGui = PlayerGui:WaitForChild("__OsprAC_WarnGui", 5)
	if not KickAnnounce and not WarnGui then
		GuiClient:print("No Guis found, initialization aborted.")

		--// Cancel
		script:Destroy()
		return
	end
	
	--// Parent to PlayerScripts
	script.Parent = Plr:WaitForChild("PlayerScripts")
	
	--// Complete
	GuiClient:print(`Initialized.`)
end



-- On Startup --
GuiClient:Init()



-- functions --

--// Displays a Warning Popup for a Player that was Warned by the Anticheat
local function DisplayWarn(Reason : string)
	if not WarnGui then return end
	
	--// locals
	local Background = WarnGui:WaitForChild("Main")
	local UIScale = Background:WaitForChild("UIScale")
	
	local TextHolder = Background:WaitForChild("TextHolder")
	local ReasonText = TextHolder:WaitForChild("Reason")
	local DismisButton = Background:WaitForChild("Dismis")
	
	--// TweenInfo
	local Info = TweenInfo.new(
		0.4,
		Enum.EasingStyle.Exponential
	)
	
	
	
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
		TS:Create(DismisButton, Info, {BackgroundTransparency = 0.4}):Play()
	end
	
	
	
	--// Check for Debounce
	if GuiClient.Deb.Warning then return end
	GuiClient.Deb.Warning = true
	
	--// Edit Text
	ReasonText.Text = "You have been given a Warning for the following reason,\n"..Reason

	--// Show Gui
	TS:Create(UIScale, Info, {Scale = 1}):Play()

	--// Dismis Cooldown
	ClickCooldown(5)
	
	
	
	-- Connect Dismis --
	DismisButton.MouseButton1Click:Connect(function()
		--// Close Window
		TS:Create(UIScale, Info, {Scale = 0}):Play()

		--// Disable Debounce
		task.delay(0.4, function() GuiClient.Deb.Warning = false end)
	end)
end

--// Displays the KickAnnounce Gui to the Player
local function DisplayKickAnnounce(Player : Player, Reason : string)
	if not KickAnnounce then return end
	
	--// locals
	local Background = KickAnnounce:WaitForChild("Main")
	local UIScale = Background:WaitForChild("UIScale")

	local TextHolder = Background:WaitForChild("TextHolder")
	local PlayerName = TextHolder:WaitForChild("PlayerName")
	local ReasonText = TextHolder:WaitForChild("Reason")

	--// TweenInfo
	local Info = TweenInfo.new(
		0.4,
		Enum.EasingStyle.Exponential
	)
	
	--// Check for Debounce
	if GuiClient.Deb.Kick then return end
	GuiClient.Deb.Kick = true

	--// Edit Text
	PlayerName.Text = "Player: "..Player.Name
	ReasonText.Text = Reason

	--// Show Gui
	TS:Create(UIScale, Info, {Scale = 1}):Play()

	task.wait(5)

	--// Hide Gui
	TS:Create(UIScale, Info, {Scale = 0}):Play()

	--// Debounce
	GuiClient.Deb.Kick = false
end



-- Connections --

GuiSystem:OnClientEvent(function(Request, GuiType : string, Reason : string, Plr : Player)
	--// Check Gui Type
	if GuiType == "Warning" then
		DisplayWarn(Reason)
		
	elseif GuiType == "Announce" then
		DisplayKickAnnounce(Plr, Reason)
	end
end)