--!strict
--// Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Packages
local RbxAPI = require(ReplicatedStorage.Packages.RbxAPI)

--// Vars | Constants
local serverAPI = RbxAPI.get("ServerAPI")
local result = serverAPI:response("Hello, Server!")

--// Code
serverAPI.onResponse:Connect(function(response)
	print("Received response from server: " .. response)
end)

print("Server response: " .. result)

--// End
