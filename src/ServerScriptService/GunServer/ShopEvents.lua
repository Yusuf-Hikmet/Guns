local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local GunSystem: Folder = ReplicatedStorage:WaitForChild("GunSystem")
local Remotes: Folder = GunSystem:WaitForChild("Remotes")
local ShopRemotes: Folder = Remotes:WaitForChild("ShopRemotes")

local DeleteGui: RemoteEvent = ShopRemotes:WaitForChild("DeleteGui")
local BuyEvent: RemoteEvent = ShopRemotes:WaitForChild("BuyEvent")

local ControlIsShopOpen: RemoteFunction = ShopRemotes:WaitForChild("ControlIsShopOpen")

local ReloadDataTransfer: BindableEvent = script.Parent.ReloadDataTransfer

DeleteGui.OnServerEvent:Connect(function(plr)
	local PlayerGui = plr:WaitForChild("PlayerGui")
	local GunShop = PlayerGui:FindFirstChild("GunShop")
	
	if GunShop then
		GunShop:Destroy()
		plr:SetAttribute("IsShopOpen",false)
		plr.Character.ShopShield:Destroy()
		plr.Character.Humanoid.WalkSpeed = 16
	else
		plr:Kick("Exploit")
	end
end)

BuyEvent.OnServerEvent:Connect(function(plr,ButtonName)
	local PlayerGui = plr:WaitForChild("PlayerGui")
	local Leaderstats = plr:WaitForChild("leaderstats")
	local Cash = Leaderstats:WaitForChild("Cash")
	
	local GunShop = PlayerGui:FindFirstChild("GunShop")
	local Shop = GunShop:WaitForChild("Shop")
	
	if ButtonName:find("Ammo") then 
		local price = Shop[ButtonName].PriceInfo.Text:gsub("%$","")
		price = tonumber(price)
		
		if Cash.Value >= price then
			ReloadDataTransfer:Fire(plr,ButtonName:gsub("Ammo",""),true)
			Cash.Value -= price
			BuyEvent:FireClient(plr,ButtonName,true)
		end
	else
		if plr.Backpack:FindFirstChild(ButtonName) then return end
		
		local price = Shop[ButtonName].PriceInfo.Text:gsub("%$","")
		price = tonumber(price)
		
		if Cash.Value >= price then
			ServerStorage.AvailableGuns[ButtonName]:Clone().Parent = plr.Backpack
			Cash.Value -= price
			ReloadDataTransfer:Fire(plr,ButtonName,true)
			BuyEvent:FireClient(plr,ButtonName)
		end
	end
end)

ControlIsShopOpen.OnServerInvoke = function(plr)
	return plr:GetAttribute("IsShopOpen")
end