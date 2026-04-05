local ReplicatedStoragbe = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local GunSystem: Folder = ReplicatedStoragbe:WaitForChild("GunSystem")
local Modules: Folder = GunSystem:WaitForChild("Modules")
local Remotes: Folder = GunSystem:WaitForChild("Remotes")

local SendLoginAmmoData: RemoteEvent = Remotes:WaitForChild("SendLoginAmmoData")
local ViewModel: RemoteEvent = Remotes:WaitForChild("ViewModel")
local Died: RemoteEvent = Remotes:WaitForChild("Died")

local GunsDatas = require(Modules:WaitForChild("GunsDatas"))

local GunProcess = {}

GunProcess.__index = GunProcess
GunProcess.Instances = {}

function GunProcess.new(Player)
	if GunProcess.Instances[Player.UserId] then
		warn("GunProcess already exists for player: " .. Player.Name); return
	end

	local self = setmetatable({}, GunProcess)
	self.Player = Player
	self.Guns = {}
	self.PriveousBackpack = {}
	
	self.DataSaving = false
	
	self.ChildRemovedConn = nil
	self.ChildAddedConn = nil
	self.CharacterAddedConn = nil
	self.HumanoidDiedConn = nil
	self.HandleGun = nil

	GunProcess.Instances[Player.UserId] = self

	local function bindDied(character)
		if self.HumanoidDiedConn then
			self.HumanoidDiedConn:Disconnect()
			self.HumanoidDiedConn = nil
		end

		local humanoid = character:WaitForChild("Humanoid")
		self.HumanoidDiedConn = humanoid.Died:Connect(function()
			Died:FireClient(self.Player)
			self.Player.Backpack:ClearAllChildren()
			self.PriveousBackpack:ClearAllChildren()
		end)
	end

	local function GetHandleItem(character)
		if self.ChildRemovedConn then
			self.ChildRemovedConn:Disconnect()
			self.ChildRemovedConn = nil
		end
		if self.ChildAddedConn then
			self.ChildAddedConn:Disconnect()
			self.ChildAddedConn = nil
		end

		self.ChildRemovedConn = character.ChildRemoved:Connect(function(child)
			if child:IsA("Tool") and GunsDatas[child.Name] then
				if not self.Player.Backpack:FindFirstChild(child.Name) then
					self.HandleGun = nil
				end
			end
		end)

		self.ChildAddedConn = character.ChildAdded:Connect(function(child)
			if self.Player:GetAttribute("Died") and self.Player:GetAttribute("Died") == true then
				self.Player:SetAttribute("Died", false)
			end
			if child:IsA("Tool") and GunsDatas[child.Name] then
				self.HandleGun = child.Name
			end
		end)
	end

	if self.Player.Character then
		self.PriveousBackpack = self.Player.Backpack
		bindDied(self.Player.Character)
		GetHandleItem(self.Player.Character)
	end

	self.CharacterAddedConn = self.Player.CharacterAdded:Connect(function(char)
		GetHandleItem(char)
		bindDied(char)
		self.PriveousBackpack = self.Player.Backpack
	end)

	return self
end

function GunProcess.GetInstance(player): {any}
	if GunProcess.Instances[player.UserId] then
		return GunProcess.Instances[player.UserId]
	else
		warn("Player not found in GunProcess.Instances")
	end
end

function GunProcess:Reload(GunName,Bypassed: boolean): ()
	local Gun = self.Guns[GunName]
	if Bypassed then
		print("Passed")
		Gun.Ammo = GunsDatas[GunName].Ammo
		Gun.CurrentAmmo = GunsDatas[GunName].MagSize
		
		if GunsDatas[GunName].GaugeBuckshot then
			Gun.Pump = GunsDatas[GunName].GaugeBuckshot
		end
		return
	end
	
	local Needle = GunsDatas[GunName].MagSize - Gun.CurrentAmmo
	
	if Needle <= Gun.Ammo then
		Gun.Ammo -= Needle
		Gun.CurrentAmmo += Needle
	elseif Needle > Gun.Ammo then
		Gun.CurrentAmmo +=  Gun.Ammo
		Gun.Ammo = 0
	end

	print(Gun.CurrentAmmo.."/"..Gun.Ammo)
end

function GunProcess:SetPlayer(): ()
	
	local leaderstats = Instance.new("Folder",self.Player)
	local Cash = Instance.new("IntValue",leaderstats)
	local Kill = Instance.new("IntValue",leaderstats)

	leaderstats.Name = "leaderstats"
	Cash.Name = "Cash"
	Kill.Name = "Kill"

	Cash.Value += 15000
	Kill.Value = 0

	self.Player:SetAttribute("Died",false)
	self.Player:SetAttribute("IsShopOpen",false)
end

function GunProcess:LoadData(Player,DataStore): ()
	local succ, data = pcall(function()
		return DataStore:GetAsync(Player.UserId)
	end)
	
	if succ and data ~= nil then
		print(self.Player.Name.." data",data)
		self.Guns = data.GunsData or {}
		
		local Leaderstats = Player:FindFirstChild("leaderstats")
		local Cash = Leaderstats:FindFirstChild("Cash") or nil
		local Kill = Leaderstats:FindFirstChild("Kill") or nil
		
		if not Cash then
			repeat 
				task.wait(.1)	
			until Leaderstats:FindFirstChild("Cash")
			Cash = Leaderstats:FindFirstChild("Cash")
		end
		
		if not Kill then
			repeat 
				task.wait(.1)		
			until Leaderstats:FindFirstChild("Kill")
			Kill = Leaderstats:FindFirstChild("Kill")
		end
		
		Cash.Value = data.Cash or 0
		Kill.Value = data.Kill or 0
		
		for _,v in pairs(data.HaveGun) do
			if not self.Player.Backpack:FindFirstChild(v) then
				ServerStorage.AvailableGuns[v]:Clone().Parent = Player.Backpack
			end
		end
		
		SendLoginAmmoData:FireClient(Player,data.GunsData ,data.HaveGun)
		task.delay(.5,function()
			
		end)
	else
		warn(self.Player.Name.." Data not Loaded Because", data)
	end
end

function GunProcess:SaveData(DataStore): ()
	if self.DataSaving then return end
	self.DataSaving = true
	self.ChildRemovedConn = nil
	self.ChildAddedConn = nil
	self.CharacterAddedConn = nil
	self.HumanoidDiedConn = nil
	
	local Leaderstats = self.Player:FindFirstChild("leaderstats")
	
	local Data = {
		Cash = Leaderstats.Cash.Value,
		Kill = Leaderstats.Kill.Value,
		HaveGun = {},
		GunsData = self.Guns
	}
	
	for _,v in pairs(self.Player.Backpack:GetChildren()) do
		if GunsDatas[v.Name] and not table.find(Data.HaveGun,v.Name) then
			table.insert(Data.HaveGun,v.Name)
		end
	end
	if self.HandleGun ~= nil then
		table.insert(Data.HaveGun,self.HandleGun)
	end
	
	for i,v in pairs(ServerStorage.AvailableGuns:GetChildren()) do
		if not table.find(Data.HaveGun,v.Name) and Data.GunsData[v.Name] then
			Data.GunsData[v.Name] = nil
		end
	end
	
	local succ, err = pcall(function()
		return DataStore:SetAsync(self.Player.UserId, Data)
	end)
	
	if succ then
		print(self.Player.Name.." Data Saved",Data)
	else
		warn(self.Player.Name.." Data Not Saved Because:",err)
	end
	GunProcess.Instances[self.Player.UserId] = nil
	
	table.clear(self)
	setmetatable(self,nil)
end

return GunProcess
