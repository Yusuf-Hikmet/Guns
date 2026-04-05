local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")

local Assets = game:GetDescendants()

local GunSystem: Folder = ReplicatedStorage:WaitForChild("GunSystem")
local Remotes: Folder = GunSystem:WaitForChild("Remotes")

local GameLoaded: RemoteEvent = Remotes:WaitForChild("GameLoaded")
local GameLoadedClient: BindableEvent = Remotes:WaitForChild("GameLoadedClient")

for	i,Asset in Assets do
	ContentProvider:PreloadAsync({Asset})
	--print( i / #Assets * 100)
end
task.wait(.5)

GameLoaded:FireServer()

task.wait(1)

GameLoadedClient:Fire()
