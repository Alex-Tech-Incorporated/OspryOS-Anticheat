-- OspryOS Anticheat --

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
local ServerScriptService = game:GetService("ServerScriptService")

--// Module
local Server = script
local MainModule = Server.Parent

local Client = MainModule.Client
local Modules = MainModule.Modules
local Dependencies = MainModule.Dependencies

--// OspryOS Anticheat
local OspryOS_Anticheat = {
	--// Directories
	Client = Client,
	Modules = Modules,
	Dependencies = Dependencies,
	
	--// Remotes Container
	Remotes = nil,
	
	--// Configuration
	Config = require(Server.Base_Config),
	Data = require(Server.Base_Data),
}

--// Anticheat Modules
OspryOS_Anticheat.functions = require(Modules.functions)(OspryOS_Anticheat)
OspryOS_Anticheat.tokens = require(Modules.tokens)(OspryOS_Anticheat)
OspryOS_Anticheat.calls = require(Modules.calls)(OspryOS_Anticheat)
OspryOS_Anticheat.HTTP = require(Modules.HTTP)(OspryOS_Anticheat)

OspryOS_Anticheat.Server_Module = require(Dependencies.Anticheat_Server)(OspryOS_Anticheat)

--// Loading Order for Modules
local ModuleLoad_Order = {
	OspryOS_Anticheat.functions,
	OspryOS_Anticheat.calls,
	OspryOS_Anticheat.Server_Module,
}

-- Prints --
function OspryOS_Anticheat:print(...)
	print("[OspryOS Anticheat]:", ...)
end
function OspryOS_Anticheat:warn(...)
	warn("[OspryOS Anticheat]:", ...)
end
function OspryOS_Anticheat:debug(...)
	if not OspryOS_Anticheat.Config.Development.DebugMode then return end
	warn("[OspryOS Anticheat] Debug:", ...)
end



-- Internal functions --



-- Server functions --

--// Configures the Anticheat's Settings and Data
function OspryOS_Anticheat:Configure(Settings : typeof(OspryOS_Anticheat.Config), Data : typeof(OspryOS_Anticheat.Data))
	--// Settings
	for index, value in Settings do
		OspryOS_Anticheat.Config[index] = value
	end
	
	--// Data
	for index, value in Data do
		OspryOS_Anticheat.Data[index] = value
	end
	
	--// Complete
	OspryOS_Anticheat:debug("Configured.")
end

--// Starts the Anticheat's Initializations process
function OspryOS_Anticheat:Initialize()
	--// Check for running Mutex
	if _G.OspryOS_Anticheat_MUTEX then
		return false, "OspryOS_Anticheat_MUTEX is already running."
	end
	
	--// Initialize
	OspryOS_Anticheat:print("Initializing...")
	_G.OspryOS_Anticheat_MUTEX = true
	
	--// Clone Remotes to ReplicatedStorage
	coroutine.wrap(function()
		local Remotes = Dependencies.Remotes:Clone()
		Remotes.Name = "OspryAC_Remotes"
		Remotes.Parent = game:GetService("ReplicatedStorage")
		OspryOS_Anticheat.Remotes = Remotes
		OspryOS_Anticheat:debug("Remotes cloned, running at:", Remotes:GetFullName())
	end)()
	
	--// Initialize Modules
	for _, module in ModuleLoad_Order do
		module.Init()
	end
	
	--// Complete
	return true, `Anticheat version v{OspryOS_Anticheat.Config.System.Version} successfully initialized`
end



--// Export
return OspryOS_Anticheat