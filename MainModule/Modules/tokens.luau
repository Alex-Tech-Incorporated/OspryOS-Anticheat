-- OspryOS Anticheat tokens --

--// locals
--// Services
local Players = game:GetService("Players")

--// Anticheat Framework
return function (OspryAC)
	return {
		--// Generates a Token for a Player
		GenerateToken = function(Plr : Player)
			--// Generate Token
			local Token = math.random(100000, 999999) * (math.random() + time()) - DateTime.now().UnixTimestamp

			--// Assign Token to Player
			OspryAC.Data.System.Tokens[Plr.UserId] = Token
			OspryAC:debug(`Token generated for @{Plr.Name} ({Plr.UserId}) | {Token}`)
		end,
		
		--// Gets the Token of a Player
		GetToken = function(Plr : Player)
			--// locals
			local Token = OspryAC.Data.System.Tokens[Plr.UserId]
			
			--// Check if Token exists
			if Token then
				return Token
				
			else
				if OspryAC.Config.ClientSide.Enabled then OspryAC:warn(`Failed to fetch Token for {Plr.Name}.`) end
				return nil
			end
		end,
	}
end