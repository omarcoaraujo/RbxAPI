--!strict
--// Services
local Players = game:GetService("Players")

--// Type
export type RemoteSignal = {

	fire: (self: RemoteSignal, player: Player, ...any) -> nil,
	fireAll: (self: RemoteSignal, ...any) -> nil,

	fireFilter: (self: RemoteSignal, callback: (player: Player) -> boolean, ...any) -> nil,
	fireFor: (self: RemoteSignal, players: { [Player?]: Player? }, ...any) -> nil,

	fireInRadius: (self: RemoteSignal, position: Vector3, radius: number, ...any) -> nil,
}

--// Factory
local RemoteSignal = {}

--// Constructor
function RemoteSignal.new(name: string, remoteEvent: RemoteEvent)
	local self = {}

	--// Attributes
	self._remoteEvent = remoteEvent
	self._name = name

	--// Methods
	function self:fire(player: Player, ...)
		self._remoteEvent:FireClient(player, self._name, ...)
	end

	function self:fireAll(...)
		self._remoteEvent:FireAllClients(self._name, ...)
	end

	function self:fireFilter(callback: (player: Player) -> boolean, ...)
		for _, player in Players:GetPlayers() do
			if callback(player) then
				self:fire(player, ...)
			end
		end
	end

	function self:fireFor(players: { [Player?]: Player? }, ...)
		for index: Player?, value: Player? in players do
			local player = if typeof(index) == "Instance" and index:IsA("Player") then index else value

			self:fire(player, ...)
		end
	end

	function self:fireInRadius(position: Vector3, radius: number, ...)
		for _, player in Players:GetPlayers() do
			local character = player.Character
			if not character then
				continue
			end

			local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
			if not humanoidRootPart then
				continue
			end

			local distance = (humanoidRootPart.Position - position).Magnitude
			if distance > radius then
				continue
			end

			self:fire(player, ...)
		end
	end

	setmetatable(self, RemoteSignal)
	return self
end

--// Functions
function RemoteSignal.is(object)
	return getmetatable(object) == RemoteSignal
end

--// End
return RemoteSignal
