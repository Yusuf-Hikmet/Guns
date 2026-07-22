local InventoryService = {}

InventoryService.__index = InventoryService

function InventoryService.new(Player)
	
	local self = setmetatable({},InventoryService)
	self.Player = Player
	self.Guns = {}
	
	for _,Gun in pairs(Player.Backpack:GetChildren()) do
		table.insert(self.Guns,Gun.Name)
	end
	print(Player.Name,"Envanter",self.Guns)
	
	return self
end

function InventoryService:AddGun(GunName: string)
	if table.find(self.Guns,GunName) then return end
	
	table.insert(self.Guns,GunName)
end

function InventoryService:RemoveGun(GunName: string)
	if not table.find(self.Guns,GunName) then return end
	
	table.remove(self.Guns,table.find(self.Guns,GunName))
end

return InventoryService
