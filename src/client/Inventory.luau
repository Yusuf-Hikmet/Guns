local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local GunSystem: Folder = ReplicatedStorage:WaitForChild("GunSystem")
local Modules: Folder = GunSystem:WaitForChild("Modules")
local Remotes: Folder = GunSystem:WaitForChild("Remotes")
local ShopRemotes: Folder = Remotes:WaitForChild("ShopRemotes")
local Guns: Folder = GunSystem:WaitForChild("Guns")

local GunsDatas = require(Modules:WaitForChild("GunsDatas"))
local InventoryService = require(Modules:WaitForChild("InventoryService"))
local MainModule = require(Modules:WaitForChild("MainModule"))

local Aiming: RemoteEvent = Remotes:WaitForChild("Aiming")
local ViewModel: RemoteEvent = Remotes:WaitForChild("ViewModel")
local DropItem: RemoteEvent = Remotes:WaitForChild("DropItem")
local GetItem: RemoteEvent = Remotes:WaitForChild("GetItem")
local BuyEvent: RemoteEvent = ShopRemotes:WaitForChild("BuyEvent")
local Died: RemoteEvent = Remotes:WaitForChild("Died")
local SendLoginAmmoData: RemoteEvent = Remotes:WaitForChild("SendLoginAmmoData")
local GameLoaded: BindableEvent = Remotes:WaitForChild("GameLoadedClient")
local GetRayOrigin: RemoteFunction = Remotes:WaitForChild("GetRayPosition")

local ControlIsShopOpen: RemoteFunction = ShopRemotes:WaitForChild("ControlIsShopOpen")
local GetAmmoData: BindableFunction = ShopRemotes:WaitForChild("GetAmmoData")

game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

local Player = game:GetService("Players").LocalPlayer
GameLoaded.Event:Wait()
print(Player.Name.." Game Loaded")
task.wait(1)

local PlayerInventory = InventoryService.new(Player)

local GunsInstances = {} 

local Equipped = false
local CurrentGun = nil

local function GetGunIndex(Index): string?
	local Gun = Player.Backpack:GetChildren()[Index]
	if not Gun then	return end
	
	return Gun.Name
end

local function UnEquip(GunName)
	if CurrentGun then
		ViewModel:FireServer(CurrentGun.Name,false)
	end
	
	if Equipped then
		Equipped = false
		Player.Character.Humanoid:UnequipTools()
		
		CurrentGun:UnEquipped()
		CurrentGun = nil
	end
	
	ViewModel:FireServer(GunName,Equipped)
end

local function Equip(GunName)
	if not GunName then return end

	if CurrentGun ~= GunsInstances[GunName] then
		UnEquip(GunName)
	else
		UnEquip(GunName)
		return
	end
	
	if not Equipped then
		Player.Character.Humanoid:EquipTool(Player.Backpack:FindFirstChild(GunName))
		Equipped = true
		CurrentGun = GunsInstances[GunName]
		print(GunsInstances)
		CurrentGun:Equipped()
	end

	ViewModel:FireServer(GunName,Equipped)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if ControlIsShopOpen:InvokeServer() then return end
	
	if CurrentGun and not CurrentGun.CanShoot then return end
	if input.KeyCode == Enum.KeyCode.One then
		Equip(PlayerInventory.Guns[1])
	elseif input.KeyCode == Enum.KeyCode.Two then
		Equip(PlayerInventory.Guns[2])
	elseif input.KeyCode == Enum.KeyCode.Three then
		Equip(PlayerInventory.Guns[3])
	elseif input.KeyCode == Enum.KeyCode.Four then
		Equip(PlayerInventory.Guns[4])
	end
	
	if not CurrentGun then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		CurrentGun:Fire()
	end
	
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		CurrentGun:SetAiming(true)
		Aiming:FireServer(true)
	end
	
	if input.KeyCode == Enum.KeyCode.Backspace then
		PlayerInventory:RemoveGun(CurrentGun.Name)
		GunsInstances[CurrentGun.Name] = nil
		DropItem:FireServer(CurrentGun.Name)
	end
	
	if input.KeyCode == Enum.KeyCode.V then
		CurrentGun:FireModeChanged()
	end
	
	if input.KeyCode == Enum.KeyCode.R then
		CurrentGun:Reload()
	end
	
	if input.KeyCode == Enum.KeyCode.LeftControl then
		CurrentGun:Run()
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if not CurrentGun then return end
	
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		if CurrentGun.CurrentFireMode == "Auto" and CurrentGun.CurrentAmmo > 0 and CurrentGun.Holding then
			CurrentGun:Fire()
		end
	end
	
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		CurrentGun:SetAiming(false)
		Aiming:FireServer(false)
	end
	
	if input.KeyCode == Enum.KeyCode.LeftControl then
		if not CurrentGun.Running then return end
		CurrentGun:Run()
	end
end)

GetAmmoData.OnInvoke = function(GunName)
	if not GunsInstances[GunName] then return end

	return {
		Ammo = GunsInstances[GunName].Ammo,
		CurrentAmmo = GunsInstances[GunName].CurrentAmmo
	}
end

DropItem.OnClientEvent:Connect(function(GunName)
	UnEquip(GunName)
end)

GetItem.OnClientEvent:Connect(function(GunName,Ammo,CurrentAmmo,Pump)
	local ExtraModule = Guns[GunName]:FindFirstChild("Modules") or nil
	if ExtraModule then
		local GunModule = require(ExtraModule:WaitForChild(GunName))

		GunsInstances[GunName] = GunModule.new(GunsDatas[GunName])
	else
		GunsInstances[GunName] = MainModule.new(GunsDatas[GunName])
	end
	local Gun = GunsInstances[GunName]
	
	Gun.Ammo = Ammo
	Gun.CurrentAmmo = CurrentAmmo
	Gun.GaugeBuckshot = Pump
	PlayerInventory:AddGun(GunName)
end)

BuyEvent.OnClientEvent:Connect(function(ButtonName)
	if ButtonName:find("Ammo") then
		local Gun = ButtonName:gsub("Ammo","")
		GunsInstances[Gun].Ammo = GunsDatas[Gun].Ammo
		GunsInstances[Gun].CurrentAmmo = GunsDatas[Gun].MagSize
	else
		local ExtraModule = Guns[ButtonName]:FindFirstChild("Modules") or nil
		if ExtraModule then
			local GunModule = require(ExtraModule:WaitForChild(ButtonName))
 
			GunsInstances[ButtonName] = GunModule.new(GunsDatas[ButtonName])
		else
			GunsInstances[ButtonName] = MainModule.new(GunsDatas[ButtonName])
		end
		PlayerInventory:AddGun(ButtonName)
	end
end)

SendLoginAmmoData.OnClientEvent:Once(function(Ammos: {[string]: number},HaveGun: {string})
	for i, GunName in pairs(HaveGun) do
		local ExtraModule = Guns[GunName]:FindFirstChild("Modules") or nil
		if ExtraModule then
			local GunModule = require(ExtraModule:WaitForChild(GunName))
			GunsInstances[GunName] = GunModule.new(GunsDatas[GunName])
		else
			GunsInstances[GunName] = MainModule.new(GunsDatas[GunName])	
		end
		PlayerInventory:AddGun(GunName)
	end

	for GunName, v in pairs(Ammos) do
		GunsInstances[GunName].Ammo = v.Ammo
		GunsInstances[GunName].CurrentAmmo = v.CurrentAmmo
	end
end)

Died.OnClientEvent:Connect(function()
	if CurrentGun then
		CurrentGun:UnEquipped()
		CurrentGun = nil
		Equipped = false
	end
	for GunName, v in pairs(GunsInstances) do
		PlayerInventory:RemoveGun(GunName)
		GunsInstances[GunName] = nil
	end
end)

GetRayOrigin.OnClientInvoke = function()
	if not CurrentGun then return end
	local Model = CurrentGun:FindViewModel()
	local RayOrigin = Model:FindFirstChild("RayOrigin") or nil
	if not RayOrigin then return end
	
	return {
		Position = RayOrigin.Position,
		CFrame = RayOrigin.CFrame
	}
end