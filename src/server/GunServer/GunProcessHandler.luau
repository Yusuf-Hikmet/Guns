local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GunSystem: Folder = ReplicatedStorage:WaitForChild("GunSystem")
local Remotes: Folder = GunSystem:WaitForChild("Remotes")

local GameLoaded: RemoteEvent = Remotes:WaitForChild("GameLoaded")

local PlayerData = DataStoreService:GetDataStore("PlayerData")

local GunProcess = require(script.Parent.GunProcess)

Players.PlayerAdded:Connect(function(Player)
	Player.CharacterAdded:Wait()

	local PlayerFunctions = GunProcess.new(Player)

	PlayerFunctions:SetPlayer()

	PlayerFunctions:LoadData(Player,PlayerData)
end)

Players.PlayerRemoving:Connect(function(Player)
	local PlayerFunctions = GunProcess.GetInstance(Player)

	PlayerFunctions:SaveData(PlayerData)
end)

game:BindToClose(function()
	for _, Player in pairs(Players:GetPlayers()) do
		local PlayerFunctions = GunProcess.GetInstance(Player)

		if PlayerFunctions then
			PlayerFunctions:SaveData(PlayerData)
		end
		task.wait(.05)
	end
	task.wait(.5)
end)