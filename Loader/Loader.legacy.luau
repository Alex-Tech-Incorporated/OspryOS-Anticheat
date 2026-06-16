-- OspryOS Anticheat Loader --

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
local SSS = game:GetService("ServerScriptService")

--// Loader
local Container = script.Parent
local ConfigModules = Container.Config
local LoaderConfig = ConfigModules.Settings
local LoaderData = ConfigModules.Data

--// MainModule
local OspryAC

--// Loader Table
local Loader = {
	--// Loader Modules
	Config = require(LoaderConfig),
	Data = require(LoaderData),
	
	--// Loader Version
	Version = "3.0.0",
}

function Loader:print(...)
	print("[OspryOS Anticheat Loader]:", ...)
end
function Loader:warn(...)
	warn("[OspryOS Anticheat Loader]:", ...)
end



-- Loading process --
Container.Parent = SSS -- Never leave Loaders in workspace... Especially Loaders like these.

--// Check if MainModule is availible
local success, module = pcall(function()
	return require(
		if Loader.Config.Development.LoadLocally then SSS:WaitForChild("MainModule", 60)
			else Loader.Config.Development.MainModule
	)
end)

--// Check Response
if success then
	OspryAC = module
	Loader:print("Loading...")
	
else
	Loader:warn("Failed to require MainModule.")
	return
end



-- Initialize MainModule --

--// Write Settings and Data to MainModule
OspryAC:Configure(Loader.Config, Loader.Data)

--// Initialize MainModule
local loaded, response = OspryAC:Initialize()

--// Check if MainModule initialized
if loaded then
	Loader:print(`{response}, required by Loader Version {Loader.Version}`)
	
else
	Loader:warn(`MainModule has failed to initialize!`)
	Loader:warn(`{response}`)
end