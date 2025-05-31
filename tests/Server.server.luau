--!strict
--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--// Packages
local RbxAPI = require(ReplicatedStorage.Packages.RbxAPI)

--// Vars | Constants
local serverAPI = RbxAPI.new({ name = "ServerAPI", remoteSignalNames = { "onResponse" } })

--// Endpoints
function serverAPI:response(player: Player, message: string): string
	print("Server received message: " .. message)
	return "Hello from the Server!"
end

--// Events
Players.PlayerAdded:Connect(function(player: Player)
	player.CharacterAdded:Connect(function(character: Model)
		serverAPI.onResponse:fire(player, "Hello, Client!")
	end)
end)

--// End
