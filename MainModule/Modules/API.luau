--// Anticheat Framework
return function (OspryAC)
	
	--// locals
	--// API
	local G_API = {}
	
	--// Anticheat Modules
	local functions = OspryAC.functions
	local config = OspryAC.Config
	local data = OspryAC.Data
	
	--// Exports
	return {
		Init = function()
			if not config.Behavior.API then return end
			OspryAC:debug(`Registering _G API calls...`)
			
			-- _G API functions --
			
			--// Adds integration with .Kick() within functions
			G_API.Kick = function(Plr : Player, Reason : string, ModMessage : string)
				functions.Kick(Plr, Reason, ModMessage)
			end
			
			--// Adds integration with .Warn() within functions
			G_API.Warn = function(Plr : Player, Reason : string, ModMessage : string, displayReason : boolean)
				functions.Warn(Plr, Reason, ModMessage, displayReason)
			end
			
			--// Allows a Player's current Warnings to be called by the _G API
			G_API.GetWarns = function(Plr : Player)
				--// locals
				local currentWarns = data.System.Warnings[Plr.UserId] or 0
				
				--// Export
				return currentWarns
			end
			
			--// Complete
			_G.OspryAC = G_API
			OspryAC:debug(`_G API initialized.`)
		end,
	}
end