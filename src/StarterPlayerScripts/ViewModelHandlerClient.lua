local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local GunSystem: Folder = ReplicatedStorage:WaitForChild("GunSystem")
local Remotes: Folder = GunSystem:WaitForChild("Remotes")
local Modules: Folder = GunSystem:WaitForChild("Modules")

local ViewModelDestroyClient: RemoteEvent = Remotes:WaitForChild("ViewModelDestroyClient")
local ViewModel: RemoteEvent = Remotes:WaitForChild("ViewModel")
local Aiming: RemoteEvent = Remotes:WaitForChild("Aiming")

local GunsDatas = require(Modules:WaitForChild("GunsDatas"))

local plrAimAndRenderData = {}

local function ModelpivotToHrp(SelfPlayer ,GunModel ,GunData)
	local char = SelfPlayer.Character
	if not char then return end
	
	local AimCF = CFrame.new()
	RunService.PreRender:Connect(function(dt)
		local Alpha = 1 - math.exp(-10 * dt)

		if plrAimAndRenderData[SelfPlayer.UserId].Aiming then
			AimCF = AimCF:Lerp(CFrame.new(GunData.ADS.TP.AimCFX,GunData.ADS.TP.AimCFY,GunData.ADS.TP.AimCFZ),Alpha)
		else
			AimCF = AimCF:Lerp(CFrame.new(),Alpha)
		end
		GunModel:PivotTo(char.Head.CFrame * CFrame.new(0,-4.5,0) * AimCF)
	end)
end

ViewModel.OnClientEvent:Connect(function(SelfPlayer,
	GunName, 
	Equipped: boolean, 
	GunModel: Model,
	PlayerRemoving: boolean?,
	OnJoined: {}?)
	
	if OnJoined then
		if SelfPlayer ~= Player then return end
		local ActiveWeapons: Folder = workspace:WaitForChild("ActiveWeapons")
		
		for _,plr in pairs(Players:GetPlayers()) do
			for _,GunModel in pairs(ActiveWeapons:GetChildren()) do
				if GunModel:IsA("Model") and GunModel.Name:find(plr.Name) then
					local GunName = GunModel.Name:gsub(plr.Name,""):gsub("ViewModelTP","")
					local GunData = GunsDatas[GunName]
					
					plrAimAndRenderData[plr.UserId] = {Aiming = false}
					plrAimAndRenderData[plr.UserId][plr.Name] = ModelpivotToHrp(plr,GunModel,GunData)
				end
			end
		end

		return
	end
	
	if SelfPlayer == Player then return end
	
	if PlayerRemoving and plrAimAndRenderData[SelfPlayer.UserId][SelfPlayer.Name] then
		plrAimAndRenderData[SelfPlayer.UserId][SelfPlayer.Name]:Disconnect()
		plrAimAndRenderData[SelfPlayer.UserId][SelfPlayer.Name] = nil
		return
	end
	
	if Equipped then
		local char = SelfPlayer.Character 
		if not char then return end

		local GunData = GunsDatas[GunName]
		local AimCF = CFrame.new()

		plrAimAndRenderData[SelfPlayer.UserId] = {[SelfPlayer.Name] = ModelpivotToHrp(SelfPlayer,GunModel,GunData)}
	else
		if plrAimAndRenderData[SelfPlayer] 
			and plrAimAndRenderData[SelfPlayer.UserId] 
			and plrAimAndRenderData[SelfPlayer.UserId][SelfPlayer] 
			and plrAimAndRenderData[SelfPlayer.UserId][SelfPlayer.Name] then
			
			plrAimAndRenderData[SelfPlayer.UserId][SelfPlayer.Name]:Disconnect()
		end
	end
end)

ViewModelDestroyClient.OnClientEvent:Connect(function(Model,GunName)
	if Model then
		Model:Destroy()
	end
end)


Aiming.OnClientEvent:Connect(function(SelfPlayer,Aiming)
	if SelfPlayer == Player then return end
	
	if not plrAimAndRenderData[SelfPlayer.UserId] then
		plrAimAndRenderData[SelfPlayer.UserId] = { Aiming = Aiming }
	else
		plrAimAndRenderData[SelfPlayer.UserId].Aiming = Aiming
	end
end)