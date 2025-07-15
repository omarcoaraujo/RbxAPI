--!strict
--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--// Modules
local RemoteSignal = require(script.RemoteSignal)

--// Package
local Signal = require(ReplicatedStorage.Packages.Signal)

--// Types
export type RbxAPI = { [string]: RemoteSignal.RemoteSignal | (self: RbxAPI, player: Player, ...any) -> any }
export type ClientRbxAPI = { [string]: Signal.Signal | (self: RbxAPI, ...any) -> any }

--// Vars | Constants
local apiList = {}

--// API
local endPoints = {}

--// Functions
function endPoints.getMethods(_, api: RbxAPI)
	local methods = {}

	for name, method in api do
		if typeof(method) == "function" and name:sub(1, 1) ~= "_" then
			table.insert(methods, name)
		end
	end

	return methods
end

function endPoints.getRemoteSignals(_, api: RbxAPI)
	local remoteSignals = {}

	for name, remoteSignal in api do
		if RemoteSignal.is(remoteSignal) then
			table.insert(remoteSignals, name)
		end
	end

	return remoteSignals
end

function endPoints.callMethod(player: Player, api: RbxAPI, methodName: string, ...)
	return api[methodName](api, player, ...)
end

--// Factory
local RbxAPI = {}

--// Constructor
function RbxAPI.new(params: { name: string, remoteSignalNames: { string }? }): RbxAPI
	local self = {}

	--// Attributes
	self._name = params.name
	self._remoteSignalNames = params.remoteSignalNames or {}

	--// Methods
	function self:_createRemotes(parent: Folder)
		local remoteEvent = Instance.new("RemoteEvent")
		local remoteFunction = Instance.new("RemoteFunction")

		remoteEvent.Parent = parent
		remoteFunction.Parent = parent
	end

	function self:_createRemoteSignals()
		local remoteEvent: RemoteEvent = self._folder.RemoteEvent

		for _, name in self._remoteSignalNames do
			self[name] = RemoteSignal.new(name, remoteEvent)
		end
	end

	function self:_setup()
		local apiFolder = Instance.new("Folder")

		self:_createRemotes(apiFolder)
		local remoteFunction = apiFolder.RemoteFunction

		apiFolder.Name = self._name
		apiFolder.Parent = script

		self._folder = apiFolder
		self:_createRemoteSignals()

		remoteFunction.OnServerInvoke = function(player: Player, packet: { string }, ...)
			if typeof(packet) ~= "table" then
				return
			end
			local result = {}

			for _, requestName in packet do
				if typeof(requestName) ~= "string" then
					continue
				end
				local endPointResult = { endPoints[requestName](player, self, ...) }

				if #endPointResult > 0 then
					for _, value in endPointResult do
						table.insert(result, value)
					end
				end
			end

			return unpack(result)
		end
	end

	self:_setup()
	return self
end

--// Functions
function RbxAPI._getServerReplica(apiFolder)
	local remoteFunction = apiFolder.RemoteFunction
	local serverMethods, serverRemoteSignals = remoteFunction:InvokeServer({ "getMethods", "getRemoteSignals" })

	local serverApiReplica = {}

	for _, methodName in serverMethods do
		serverApiReplica[methodName] = function(self, ...)
			return remoteFunction:InvokeServer({ "callMethod" }, methodName, ...)
		end
	end

	for _, remoteSignalName in serverRemoteSignals do
		serverApiReplica[remoteSignalName] = Signal.new()
	end
	return serverApiReplica
end

function RbxAPI.get(name: string): RbxAPI | ClientRbxAPI
	local apiFolder = script:WaitForChild(name)

	if RunService:IsClient() then
		local serverApiReplica = RbxAPI._getServerReplica(apiFolder)
		local remoteEvent = apiFolder.RemoteEvent

		remoteEvent.OnClientEvent:Connect(function(remoteSignalName, ...)
			serverApiReplica[remoteSignalName]:Fire(...)
		end)
		return serverApiReplica
	else
		return apiList[apiFolder]
	end
end

--// End
return RbxAPI
