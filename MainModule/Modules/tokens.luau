-- OspryOS Anticheat tokens --

--// locals
--// Services
local Players = game:GetService("Players")

--// Anticheat Framework
return function (OspryAC)
	return {
		--// Generates a Token for a Player
		Generate = function(Plr : Player)
			--// Generate Token
			local Token = math.random(100000, 999999) * (math.random() + time()) - DateTime.now().UnixTimestamp

			--// Assign Token to Player
			OspryAC.Data.System.Tokens[Plr.UserId] = Token
			OspryAC:debug(`Generated Token for @{Plr.Name} ({Plr.UserId}) | {Token}`)
		end,
		
		--// Gets the Token of a Player
		Get = function(Plr : Player)
			--// locals
			local Client_Tokens = OspryAC.Data.System.Tokens
			local Token = Client_Tokens[Plr.UserId]
			OspryAC:debug(`Found Token for {Plr.Name}: {Token}`)
			
			--// Check if Token exists
			return if Token then Token else nil
		end,
	}
end