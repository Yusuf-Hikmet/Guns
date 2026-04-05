local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local GunSystem: Folder = ReplicatedStorage:WaitForChild("GunSystem")
local Remotes: Folder = GunSystem:WaitForChild("Remotes")
local Modules: Folder = GunSystem:WaitForChild("Modules")
local Guns: Folder = GunSystem:WaitForChild("Guns")
local ActiveWeapons: Folder = workspace:WaitForChild("ActiveWeapons")

local ViewModel: RemoteEvent = Remotes:WaitForChild("ViewModel")
local ViewModelDestroyClient: RemoteEvent = Remotes:WaitForChild("ViewModelDestroyClient")
local ViewModelReload: RemoteEvent = Remotes:WaitForChild("ViewModelReload")
local Aiming: RemoteEvent = Remotes:WaitForChild("Aiming")
local ReloadDataTransfer: BindableEvent = script.Parent.ReloadDataTransfer

local Functions = require(Modules:WaitForChild("Functions"))
local GunsDatas = require(Modules:WaitForChild("GunsDatas"))

local plrViewData = {}

local function GetModel(GunName,PlayerName): Model
	local Model = ActiveWeapons:FindFirstChild("ViewModelTP"..GunName..PlayerName) or nil
	return Model
end

ViewModel.OnServerEvent:Connect(function(plr,GunName,Equipped)
	if Equipped then
		if GetModel(GunName,plr.Name) then GetModel(GunName,plr.Name):Destroy() end
		
		local Gun = GunsDatas[GunName]
		local GunFolder = Guns[GunName]
		
		local Model = GunFolder.Models["ViewModelTP"..GunName]:Clone()
		Model.Name ..= plr.Name
		Model.Parent = ActiveWeapons
		
		ViewModelDestroyClient:FireClient(plr,Model)
		ViewModel:FireAllClients(plr ,GunName ,Equipped ,Model)
		Functions.SetArmsTransparency(plr,1)
		Functions.SetArmsApperance(plr,Model)
		
		local AimCF = CFrame.new()		
		plrViewData[plr.UserId] = {Reloading = false}
		
	else
		local Model = GetModel(GunName,plr.Name)
		ViewModel:FireAllClients(plr ,GunName ,Equipped ,Model)

		if Model then Model:Destroy() end

		Functions.SetArmsTransparency(plr,0)
	end
end)

Aiming.OnServerEvent:Connect(function(plr,Aim: boolean)
	if plrViewData[plr.UserId] then
		plrViewData[plr.UserId].Aiming = Aim
		Aiming:FireAllClients(plr,Aim)
	end
end)

ViewModelReload.OnServerEvent:Connect(function(plr,GunName)
	if plrViewData[plr.UserId]["Reloading"] then return end
	
	plrViewData[plr.UserId]["Reloading"] = true
	local Model = GetModel(GunName,plr.Name)
	local Animator = Model:WaitForChild("Humanoid"):FindFirstChild("Animator")
	local ReloadAnim: AnimationTrack = Animator:LoadAnimation(Guns[GunName].Animations.Reload)
	local Gun = Model:FindFirstChildOfClass("Model")
	local Mag = Gun.Default:FindFirstChild("Mag") or nil
	
	ReloadAnim:Play()
	
	ReloadAnim.Stopped:Connect(function()
		ReloadDataTransfer:Fire(plr,GunName)	
		plrViewData[plr.UserId]["Reloading"] = false
	end)
	
	task.spawn(function()
		local process = 0
		
		while task.wait(.1) do
			process += .1
			if not plrViewData[plr.UserId] then break end
			
			if not GetModel(GunName,plr.Name) then 
				plrViewData[plr.UserId]["Reloading"] = false
				break
			end
			if process >= GunsDatas[GunName].ReloadTime then
				break
			end
		end
	end)
end)

Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Wait()
	task.wait(.5)
	ViewModel:FireAllClients(plr,plr,nil,nil,nil,true)
end)

Players.PlayerRemoving:Connect(function(plr)
	if plrViewData[plr.UserId] then
		for i,v in pairs(ActiveWeapons:GetChildren()) do
			if v.Name:find(plr.Name) then
				v:Destroy()
			end
		end
		ViewModel:FireAllClients(plr,nil,nil,nil,true,nil)
		plrViewData[plr.UserId] = nil
	else
		ViewModel:FireAllClients(plr,nil,nil,nil,true,nil)
		plrViewData[plr.UserId] = nil
	end
end)