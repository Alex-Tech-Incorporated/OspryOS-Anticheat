-- OspryOS Anticheat Client --

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
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// ReplicatedStorage
local RemotesModule = RS:WaitForChild("OspryAC_Remotes")

--// Remotes
local Remotes = require(RemotesModule)

--// Mappings
local Mappings = {
	--// Client Inbound / Outbound
	OspryAC = Remotes("OspryAC"),
	Actions = Remotes("Actions"),

	--// Client Data
	Get = Remotes("Get"),
}

--// Client Table
local Client = {
	--// Essentials
	Plr = Players.LocalPlayer,
	Remotes = Remotes,

	--// Client Data
	Config = {
		NoclipDetection = false,
		BtoolsDetection = false,
		GuiDetection = false,
		DexDetection = false,
		AWPDetection = false,

		DebugMode = false,
	},
	Data = {
		NoclipConfig = {},
		WhitelistedGuis = {},
	},
	Token = nil,

	--// Misc
	Deb = {
		Announcement = false,
		Warning = false,
	},
	Mappings = Mappings,
	Loaded = false,
}

--// Modules
Client.Detections = require(script:WaitForChild("Detections"))(Client)
Client.calls = require(script:WaitForChild("calls"))(Client)
Client.Gui = require(script:WaitForChild("Gui"))(Client)

--// Loading Order for Modules
Client.ModuleLoad_Order = {
	Client.Detections,
	-- Client.Gui -- Not really needed.
}

--// Prints
function Client:debug(...)
	if not Client.Config.DebugMode then return end
	warn("[OspryAC Client] Debug:", ...)
end



-- Client functions --

--// Sends Kick Data to the Server
function Client:Warn(Reason : string, ModMessage : string)
	Client.calls.Send_Action("Warn", Reason, ModMessage, Client.Token)
end

--// Sends Kick Data to the Server
function Client:Kick(Reason : string, ModMessage : string)
	Client.calls.Send_Action("Kick", Reason, ModMessage, Client.Token)
end



-- Client Startup --

--// Hide Remotes
-- RemotesModule.Parent = nil -- Removed for now due to unexpected behavior.

--// Initialize
Client.calls.Init()
Client.calls.Send("Init_Client")