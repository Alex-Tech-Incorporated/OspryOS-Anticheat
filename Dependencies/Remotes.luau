--!strict

--[[
	Remotes // Evercyan @ 2024 Dec.
	Wrapper for remotes which offers vastly superior functionality over traditional remotes.
	
	### Parameter Types
	--> Require other machines to send over proper types and check them before running any code connected to these Remote events.
	--> This can be done through the use of syntax similar to Luau typechecking.
	
	### Built-in Debounce
	--> Add rate limiting to any remote connection through the use of the RequestBlob object in OnServerEvent/OnClientEvent/OnServerInvoke.
	--> Limit requests & actions per-player and globally for temporary actions & beefier server-sided calculations.
	--> Meant to be used primarily on the server.
	
	### Smart Exception Handling
	--> It won't even attempt to run OnServerEvent/OnClientEvent functions if Parameter Types are mismatched, or if a debounce is active.
	--> OnServerInvoke has a convention similar to HttpService calls wrapped with pcall.
	--> Give client more information for pop-ups! Return Success values back to the client for every invocation, as well as any additional information (e.g. new pet details, lack of Coins for an item)!
	--> Any error that occurs inside of your function will cause all active Debounces to shortly expire to prevent indefinite debounce locks.
	
	### Strict Typechecking
	Writing code with Remotes is trivial with its custom Luau typechecking. Simply require, call, and do something!
]]

--> Services
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--> Variables
local IsServer = RunService:IsServer()
local RemoteEvents = {"RemoteEvent", "UnreliableRemoteEvent"}
local ListRemote = {}

--> Configuration
local RandomizeNames = true -- Randomizes remote names on the client side once replicated. Realistically does little to keep your game safer, but it might deter some inexperienced coders? :shrug:
local ErrorDebounce = 5 -- How many seconds to yield to clear any existing Debounces (client/global) if a connection's function encounters an error. Ensures no memory leaks here & clients won't be forever stuck not being able to access a remote if one happens to error.
local print = function(...) end -- Comment this line for detailed debugging. Not recommended for live servers.

--> Types
type ServerRequestBlob = {
	Client: Player,
	Debounce: (ServerRequestBlob, Client: Player?, Seconds: number?) -> ()
}
type ServerInvRequestBlob = ServerRequestBlob & {
	Raise: (ServerInvRequestBlob, Exception: string, Data: any?) -> {Success: false, Exception: string, Data: any?},
	Close: (ServerInvRequestBlob, Data: any?) -> {Success: true, Data: any?}
}
type ClientRequestBlob = {
	Debounce: (ClientRequestBlob, Seconds: number?) -> ()
}
type DebounceData = {
	Client: {[number]: boolean?}?,
	Global: boolean
}
type ReferenceParam = string | {string}
export type Remote = {
	Id: string,
	ClassName: string,
	Object: Instance,
	FireServer: (...any) -> (),
	FireClients: ({Player}, ...any) -> (),
	FireAllClients: (...any) -> (),
	InvokeServer: (...any) -> (boolean, ...any),
	OnServerEvent: (Remote, (ServerRequestBlob, ...any) -> (), {ReferenceParam}?) -> RBXScriptConnection,
	OnClientEvent: (Remote, (ClientRequestBlob, ...any) -> (), {ReferenceParam}?) -> RBXScriptConnection,
	OnServerInvoke: (Remote, (ServerInvRequestBlob, ...any) -> (boolean, ...any), {ReferenceParam}?) -> (),
}

--------------------------------------------------------------------------------

-- Takes a ReferenceParam and turns it into a Union (list of type strings) if it ends with a "?".
local function ConvertToUnion(ReferenceParam: ReferenceParam): ReferenceParam
	if typeof(ReferenceParam) == "string" then
		local len = #ReferenceParam
		if string.sub(ReferenceParam, len, len) == "?" then
			return {string.sub(ReferenceParam, 1, len-1), "nil"}
		end
	end
	return ReferenceParam
end

-- Returns whether or not the SentRawParams matches up with ReferenceParams.
local function ProcessHasProperTypes(ReferenceParams: {ReferenceParam}?, SentRawParams: {any}): boolean
	if not ReferenceParams then
		print("Process doesn't have any reference parameters.")
		return true
	end
	
	for i, ReferenceParam in pairs(ReferenceParams) do
		local SentRawParam = SentRawParams[i]
		ReferenceParam = ReferenceParam and ConvertToUnion(ReferenceParam)
		
		if not ReferenceParam then
			print("ReferenceParams list finished; any additional SentRawParam is treated as optional.")
			break
		end
		
		if typeof(ReferenceParam) == "string" and typeof(SentRawParam) ~= ReferenceParam then
			return false
		elseif typeof(ReferenceParam) == "table" then
			if not table.find(ReferenceParam, typeof(SentRawParam)) then
				return false
			end
		end
	end
	
	return true
end

-- Run this function when an exception occurs under an xpcall to reset Debounce values.
local function DebounceException(Debounce: DebounceData, err)
	task.delay(ErrorDebounce, function()
		Debounce.Global = false
		if Debounce.Client then
			Debounce.Client = {}
		end
	end)
	warn(`[Remotes]: Request Func raised an exception. Exception: "{err}"\n--> Clearing all marked debounces in {ErrorDebounce} seconds.`)
end

-- Boilerplate for each Request:Debounce function
local function DebounceBoiler(Debounce: DebounceData, Client: Player?, Seconds: number?)
	if Client and Debounce.Client then
		if Seconds then
			Debounce.Client[Client.UserId] = true
			task.delay(Seconds, function()
				Debounce.Client[Client.UserId] = nil
			end)
		else
			Debounce.Client[Client.UserId] = not Debounce.Client[Client.UserId] and true or nil
		end
	else
		if Seconds then
			Debounce.Global = true
			task.delay(Seconds, function()
				Debounce.Global = false
			end)
		else
			Debounce.Global = if Debounce.Global then false else true
		end
	end
end

--------------------------------------------------------------------------------

local Remote = {}
Remote.__index = Remote

-- Creates a new remote if it doesn't exist by the given Id; returns an existing one if it does.
function Remote.get(Id: string)
	local self = ListRemote[Id]
	
	if self then
		return self
	else
		local Object = script:FindFirstChild(Id, true)
		if not Object then
			error(`[Remotes]: No remote object for ClassName "{Id}" found.`)
		end
		
		local self = setmetatable({
			Id = Id,
			ClassName = Object.ClassName,
			Object = Object,
		}, Remote)
		ListRemote[Id] = self
		
		return self
	end
end

local function PerRemoteObject(Object: RemoteEvent | RemoteFunction)
	local self = Remote.get(Object.Name)
	if not IsServer then
		self.Object.Name = HttpService:GenerateGUID()
	end
end

script.DescendantAdded:Connect(PerRemoteObject)
for _, Object in script:GetDescendants() do
	task.spawn(PerRemoteObject, Object)
end

function Remote:FireServer(...)
	if not table.find(RemoteEvents, self.ClassName) then
		error(`[Remotes]: Can't use FireServer on {self.ClassName} "{self.Object}".`)
	end
	if IsServer then
		error(`[Remotes]: FireServer for {self.ClassName} "{self.Object}" can only be used on the client.`)
	end
	
	self.Object:FireServer(...)
end

function Remote:FireClients(Clients: {Player}, ...)
	if not table.find(RemoteEvents, self.ClassName) then
		error(`[Remotes]: Can't use FireClients on {self.ClassName} "{self.Object}".`)
	end
	if not IsServer then
		error(`[Remotes]: FireClients for {self.ClassName} "{self.Object}" can only be used on the server.`)
	end
	
	for _, Client in Clients do
		self.Object:FireClient(Client, ...)
	end
end

function Remote:FireAllClients(...)
	if not table.find(RemoteEvents, self.ClassName) then
		error(`[Remotes]: Can't use FireAllClients on {self.ClassName} "{self.Object}".`)
	end
	if not IsServer then
		error(`[Remotes]: FireAllClients for {self.ClassName} "{self.Object}" can only be used on the server.`)
	end
	
	self.Object:FireAllClients(...)
end

function Remote:InvokeServer(...)
	if self.ClassName ~= "RemoteFunction" then
		error(`[Remotes]: Can't use InvokeServer on {self.ClassName} "{self.Object}".`)
	end
	if IsServer then
		error(`[Remotes]: InvokeServer for {self.ClassName} "{self.Object}" can only be used on the client.`)
	end
	
	return self.Object:InvokeServer(...)
end

function Remote:OnServerEvent(Func: (ServerRequestBlob, ...any) -> (), Params: {ReferenceParam}?): RBXScriptConnection
	if not table.find(RemoteEvents, self.ClassName) then
		error(`[Remotes]: Can't use OnServerEvent on {self.ClassName} "{self.Object}".`)
	end
	if not IsServer then
		error(`[Remotes]: OnServerEvent for {self.ClassName} "{self.Object}" can only be used on the server.`)
	end
	
	local DebounceData = {
		Global = false,
		Client = {}
	}
	
	local Connection
	Connection = (self.Object :: RemoteEvent).OnServerEvent:Connect(function(Client, ...)
		if DebounceData.Global or DebounceData.Client[Client.UserId] then
			print(`[Remotes]: Request is stuck on debounce.`)
			return
		end
		if not ProcessHasProperTypes(Params, {...}) then
			print(`[Remotes]: Request doesn't have proper types. Needed:`, Params, ". Received:", {...})
			return
		end
		
		local Request = {
			Client = Client
		}
		
		function Request:Debounce(Client: Player?, Seconds: number?)
			DebounceBoiler(DebounceData, Client, Seconds)
		end
		
		xpcall(Func, function(err)
			DebounceException(DebounceData, err)
		end, Request, ...)
	end)
	
	return Connection
end

function Remote:OnClientEvent(Func: (ClientRequestBlob, ...any) -> (), Params: {ReferenceParam}?): RBXScriptConnection
	if not table.find(RemoteEvents, self.ClassName) then
		error(`[Remotes]: Can't use OnClientEvent on {self.ClassName} "{self.Object}".`)
	end
	if IsServer then
		error(`[Remotes]: OnClientEvent for {self.ClassName} "{self.Object}" can only be used on the client.`)
	end
	
	local DebounceData = {
		Global = false
	}
	
	local Connection
	Connection = (self.Object :: RemoteEvent).OnClientEvent:Connect(function(...)
		if DebounceData.Global then
			print(`[Remotes]: Request is stuck on debounce.`)
			return
		end
		if not ProcessHasProperTypes(Params, {...}) then
			print(`[Remotes]: Request doesn't have proper types. Needed:`, Params, ". Received:", {...})
			return
		end
		
		local Request = {}
		
		function Request:Debounce(Seconds: number?)
			DebounceBoiler(DebounceData, nil, Seconds)
		end
		
		xpcall(Func, function(err)
			DebounceException(DebounceData, err)
		end, Request, ...)
	end)
	
	return Connection
end

function Remote:OnServerInvoke(Func: (ServerInvRequestBlob, ...any) -> (boolean, ...any), Params: {ReferenceParam}?)
	if self.ClassName ~= "RemoteFunction" then
		error(`[Remotes]: Can't use OnServerInvoke on {self.ClassName} "{self.Object}".`)
	end
	if not IsServer then
		error(`[Remotes]: OnServerInvoke for {self.ClassName} "{self.Object}" can only be used on the server.`)
	end
	
	local DebounceData = {
		Global = false,
		Client = {}
	};
	
	(self.Object :: RemoteFunction).OnServerInvoke = function(Client, ...)
		local Request = {
			Client = Client,
		}
		
		function Request:Debounce(Client: Player?, Seconds: number?)
			DebounceBoiler(DebounceData, Client, Seconds)
		end
		
		function Request:Raise(Exception: string, Data: any): {Success: false, Exception: string, Data: any?}
			return {
				Success = false,
				Exception = Exception,
				Data = Data
			}
		end
		
		function Request:Close(Data: any?): {Success: true, Data: any?}
			return {
				Success = true,
				Data = Data
			}
		end
		
		if DebounceData.Global or DebounceData.Client[Client.UserId] then
			print(`[Remotes]: Request is stuck on debounce.`)
			return Request:Raise("Request can't be fulfilled; You are exceeding rate limits.")
		end
		if not ProcessHasProperTypes(Params, {...}) then
			print(`[Remotes]: Request doesn't have proper types. Needed:`, Params, ". Received:", {...})
			return Request:Raise("Request can't be fulfilled; Sent parameter types aren't matching up with the server's copy.")
		end
		
		local t = {xpcall(Func, function(err)
			DebounceException(DebounceData, err)
		end, Request, ...)}
		if t[1] == true then -- No Lua exception.
			local t2 = t[2]
			if typeof(t2) ~= "table" then
				print(`[Remotes]: Request attempted to return an incorrect Response format to the client. Id: {self.Id}`)
				return Request:Raise("Request can't be fulfilled; Server-side attempted to return an incorrect Response format.")
			end
			return table.unpack(t, 2)
		else
			return Request:Raise("The server ran into an exception. Try again later.")
		end
	end
end

return setmetatable({}, {
	__call = function(_, Id: string)
		return Remote.get(Id)
	end :: (any, string) -> (Remote),
})