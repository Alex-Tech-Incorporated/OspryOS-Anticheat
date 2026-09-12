-- OspryOS Anticheat tokens --

--// locals
--// Services
local Players = game:GetService("Players")

--// Anticheat Framework
return function (OspryAC)
	--// locals
	local Data = OspryAC.Data
	
	local System_Data = Data.System
	
	--// functions
	return {
		--// Generates a Token for a Player
		Generate = function(Plr : Player)
			--// Generate Token
			local Token = math.random(100000, 999999) * (math.random() + time()) - DateTime.now().UnixTimestamp

			--// Assign Token to Player
			System_Data.Tokens[Plr.UserId] = Token
			OspryAC:debug(`Generated Token for @{Plr.Name} ({Plr.UserId}) | {Token}`)
		end,
		
		--// Gets the Token of a Player
		Get = function(Plr : Player)
			--// locals
			local Client_Tokens = System_Data.Tokens
			local Token = Client_Tokens[Plr.UserId]
			OspryAC:debug(`Found Token for {Plr.Name}: {Token}`)
			
			--// Check if Token exists
			return if Token then Token else nil
		end,
		
		--// Deletes a Player's Token
		Delete = function(Plr : Player)
			--// locals
			local Client_Tokens = System_Data.Tokens
			local Token = Client_Tokens[Plr.UserId]
			
			if not Token then return end
			
			--// Delete Token
			Client_Tokens[Plr.UserId] = nil
		end,
	}
end