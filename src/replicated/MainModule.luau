local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local GunSystem: Folder = ReplicatedStorage:WaitForChild("GunSystem")
local Modules: Folder = GunSystem:WaitForChild("Modules") 
local Remotes: Folder = GunSystem:WaitForChild("Remotes")
local Guns: Folder = GunSystem:WaitForChild("Guns")

local SoundPlayer: RemoteEvent = Remotes:WaitForChild("SoundPlayer")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Functions = require(Modules:WaitForChild("Functions"))
local GuiController = require(Modules:WaitForChild("GuiController"))

local MainModule = {}

MainModule.__index = MainModule

local FireModes = {
	Auto = "Auto",
	Semi = "Semi",
	Pump = "Pump",
}

function MainModule.new(data: {any}): {}
	local self = setmetatable({},MainModule)
	-- Variables
	self.Ammo = data.Ammo
	self.Damage = data.Damage
	self.FireRate = data.FireRate
	self.Name = data.Name
	self.MagSize = data.MagSize
	self.ReloadTime = data.ReloadTime
	self.Range = data.Range
	self.Spread = data.Spread
	self.SpreadIncrease = data.SpreadIncrease
	self.SpreadDecrease = data.SpreadDecrease
	self.SpreadMax = data.SpreadMax
	self.SpreadMin = data.SpreadMin
	
	if data.GaugeBuckshot then
		self.GaugeBuckshot = data.GaugeBuckshot
	end
	-- Tables Variables
	self.ADS = data.ADS
	self.DamageMultipliers = data.DamageMultipliers
	self.FireModes = data.FireModes
	self.Recoil = data.Recoil

	-- Folder Variables
	self.Animations = Guns[self.Name].Animations
	self.Sounds = Guns[self.Name].Sounds

	-- Other Variables
	self.Aiming = false
	self.CurrentFireMode = self.FireModes[1]
	self.CurrentAmmo = self.MagSize
	self.CanShoot = true
	self.ReloadCanceled = false
	self.Reloading = false

	self.Running = nil
	self.Holding = nil
	self.SwayConn = nil

	local TInfo = TweenInfo.new(self.ADS.Time,Enum.EasingStyle.Sine,Enum.EasingDirection.In,0,false,0)

	self.Zoom = TweenService:Create(Camera,TInfo,{FieldOfView = self.ADS.Zoom})
	self.NoZoom = TweenService:Create(Camera,TInfo,{FieldOfView = 70})

	return self
end

function MainModule:IsFirstPerson(): boolean
	local char = Player.Character
	local head = char:WaitForChild("Head")

	if head.LocalTransparencyModifier == 1 or (head.CFrame.Position - Camera.CFrame.Position).Magnitude < 0.8 then
		return true
	else
		return false
	end
end

function MainModule:CreateModel(): ()

	if self:IsFirstPerson() then
		local ViewModel = Guns[self.Name].Models["ViewModelFP"..self.Name]:Clone()
		ViewModel.Parent = Camera
	else
		local ViewModel =  Guns[self.Name].Models["ViewModelTP"..self.Name]:Clone()
		ViewModel.Parent = Player.Character
	end

end

function MainModule:SetMouseIcon(SetIcon): ()
	UserInputService.MouseIconEnabled = SetIcon
	if SetIcon then
		self.NoZoom:Play()
	end
end

function MainModule:RemoveModel(TPorFP): ()
	if TPorFP then
		if TPorFP == "TP" then
			Player.Character:WaitForChild("ViewModelTP"..self.Name):Destroy()
		else
			Camera:FindFirstChild("ViewModelFP"..self.Name):Destroy()
		end
	else
		if self:IsFirstPerson() then
			Camera:FindFirstChild("ViewModelFP"..self.Name):Destroy()
		else
			Player.Character:WaitForChild("ViewModelTP"..self.Name):Destroy()
		end
	end
end

function MainModule:FireModeChanged(): ()
	if not self.CanShoot then return end

	local index = table.find(self.FireModes,self.CurrentFireMode)

	if not self.FireModes[index + 1] then
		self.CurrentFireMode = self.FireModes[1]
	else
		self.CurrentFireMode = self.FireModes[index + 1]
	end
	print("FireMode:",self.CurrentFireMode)
end

function MainModule:FindViewModel(): Model
	local Model

	if self:IsFirstPerson() then
		Model = Camera:FindFirstChild("ViewModelFP"..self.Name) 
	else
		Model = Player.Character:FindFirstChild("ViewModelTP"..self.Name) 
	end
	Functions.SetArmsApperance(Player,Model)
	return Model
end

function MainModule:SetAiming(Aiming): ()
	self.Aiming = Aiming
end

function MainModule:UnEquipped(): ()
	GuiController.ToggleGui("AmmoFrame",false)
	self.NoZoom:Play()
	self:RemoveModel()
	self:SetMouseIcon(true)
	self:spreadDecrease(true)

	self.Holding = false
	self.CanShoot = false
	self.Aiming = false

	if self.Running then
		self.Running:Stop()
		self.Running = nil
		Player.Character:FindFirstChild("Humanoid").WalkSpeed = 16

	end
	if self.Reloading then 
		self.ReloadCanceled = true
	end

	self.Reloading = false

	if self.SwayConn then
		self.SwayConn:Disconnect()
		self.SwayConn = nil
	end
end

function MainModule:Equipped(): ()
	self.CanShoot = true

	self:CreateModel()  
	self:Sways()
	self:SetMouseIcon(false)
	GuiController.ToggleGui("AmmoFrame",true)
	GuiController.UpdateGui(self.Name,self.Ammo,self.CurrentAmmo)
end

function MainModule:CameraRecoil(): ()
	local conn

	task.spawn(function()
		local x = self.Recoil.X
		local y = math.random(0,1) == 1 and self.Recoil.Y or -self.Recoil.Y
		conn = RunService.PreRender:Connect(function(dt)
			local scale = dt / (1/60)

			if self.Aiming then
				Camera.CFrame *= CFrame.Angles(x / 3 * scale, y / 3 * scale, 0)
			else
				Camera.CFrame *= CFrame.Angles(x * scale, y * scale, 0)
			end

			x -= dt * 2
			if x <= 0 then
				conn:Disconnect()
				conn = nil
			end
		end)
	end)
end

function MainModule:spreadIncrease(): ()
	local state = math.random(0,1) == 1

	local Xr = state and self.SpreadIncrease or -self.SpreadIncrease
	local Yr = state and self.SpreadIncrease or -self.SpreadIncrease

	if self.Aiming then
		self.Spread += Vector2.new(
			(math.random() * Xr) / 2,
			(math.random() * Yr) / 2
		)
	else
		self.Spread += Vector2.new(
			(math.random() * Xr),
			(math.random() * Yr)
		)
	end

	self.Spread = Vector2.new(
		math.clamp(self.Spread.X,self.SpreadMin,self.SpreadMax),
		math.clamp(self.Spread.Y,self.SpreadMin,self.SpreadMax)
	)

end

function MainModule:spreadDecrease(IsReset: boolean?): ()
	if IsReset then
		self.Spread = Vector2.new()
	else
		self.Spread = Vector2.new(
			math.max(self.Spread.X - self.SpreadDecrease, 0),
			math.max(self.Spread.X - self.SpreadDecrease, 0)
		)
	end
end

function MainModule:Fire(): ()
	if self.Holding then self.Holding = false return end
	if self.CurrentAmmo <= 0 then print("No Bullets") return end
	if self.Reloading == true then return end
	if not self.CanShoot then return end
	if self.Running then return end

	local Model = self:FindViewModel()
	local RayOrigin = Model:FindFirstChild("RayOrigin")
	local MainVFX = Model:FindFirstChild("FireVFX")

	local function VFXFire()
		if not MainVFX then return end
		
		for _,v in MainVFX:GetDescendants() do
			v.Enabled = true
		end
		
		task.delay(.3,function()
			for _,v in MainVFX:GetDescendants() do
				v.Enabled = false
			end
		end)
	end

	local Params = RaycastParams.new()
	Params.FilterType = Enum.RaycastFilterType.Exclude
	Params.FilterDescendantsInstances = {Model,Player.Character}
	Params.IgnoreWater = true

	self.CanShoot = false
	local RayData = {
		CFrame = RayOrigin.CFrame,
		Position = RayOrigin.Position
	}
	
	if self.CurrentFireMode == FireModes.Semi then
	
		Functions.Ray(RayData ,self.Range ,Params ,self.Name ,self.Spread)
		self:CameraRecoil()
		self:spreadIncrease()
		VFXFire()
	
		self.CurrentAmmo -= 1
		
		GuiController.UpdateGui(self.Name,self.Ammo,self.CurrentAmmo)
		Functions.PlayAnimationModel(Model,self.Animations["Fire"])
		SoundPlayer:FireServer(self.Sounds["Fire"])
		print("Fired: ",self.CurrentAmmo.."/"..self.Ammo)

		task.wait(self.FireRate)

	elseif self.CurrentFireMode == FireModes.Auto then
		self.Holding = true

		while self.Holding do

			Functions.Ray(RayData,self.Range ,Params ,self.Name ,self.Spread)
			self:CameraRecoil()
			self:spreadIncrease()
			VFXFire()

			self.CurrentAmmo -= 1
			
			GuiController.UpdateGui(self.Name,self.Ammo,self.CurrentAmmo)
			Functions.PlayAnimationModel(Model,self.Animations["Fire"])
			SoundPlayer:FireServer(self.Sounds["Fire"])

			print("Fired: ",self.CurrentAmmo.."/"..self.Ammo)
			task.wait(self.FireRate)
			if self.CurrentAmmo <= 0 or not self.Holding then break end
		end

		task.wait(self.FireRate)
	elseif self.CurrentFireMode == FireModes.Pump then
		for i = 1,self.GaugeBuckshot do
			Functions.Ray(RayData,self.Range ,Params ,self.Name ,self.Spread)
			self:spreadIncrease()
		end
		
		self:CameraRecoil()
		VFXFire()
		
		self.CurrentAmmo -= 1
		
		GuiController.UpdateGui(self.Name,self.Ammo,self.CurrentAmmo)
		Functions.PlayAnimationModel(Model,self.Animations["Fire"])
		SoundPlayer:FireServer(self.Sounds["Fire"])
		
		print("Fired: ",self.CurrentAmmo.."/"..self.Ammo)
		task.wait(self.FireRate)
	end

	self.CanShoot = true
end

function MainModule:Reload(): ()
	if not self.CanShoot then return end
	if self.Reloading then return end
	if self.Ammo <= 0 then return end
	if self.Running then return end
	if self.CurrentAmmo == self.MagSize then return end
	local Model = self:FindViewModel()

	self.Reloading = true
	self.ReloadCanceled = false
	self.Aiming = false
	Functions.PlayAnimationModel(Model,self.Animations["Reload"],Player)
	print("Reloading...")
	local ReloadProcess = 0

	while task.wait(0.1) do
		if self.ReloadCanceled then print("Reload Canceled") return end
		ReloadProcess += 0.1

		if ReloadProcess >= self.ReloadTime then break end
	end

	local Needle = self.MagSize - self.CurrentAmmo
	if Needle <= self.Ammo then
		self.Ammo -= Needle
		self.CurrentAmmo += Needle
	elseif Needle > self.Ammo then
		self.CurrentAmmo +=  self.Ammo
		self.Ammo = 0
	end

	self.Reloading = false
	GuiController.UpdateGui(self.Name,self.Ammo,self.CurrentAmmo)
	print("Reload Completed: ",self.CurrentAmmo.."/"..self.Ammo)
end

function MainModule:Run(): ()
	if self.Reloading then return end
	if self.Holding then return end
	if self.Aiming then return end
	if not self.CanShoot then return end

	local char = Player.Character
	local hum = char:WaitForChild("Humanoid")

	if self.Running then
		self.Running:Stop()
		self.Running = nil
		hum.WalkSpeed = 16
		return
	end

	local Model = self:FindViewModel()

	self.Running = Functions.PlayAnimationModel(Model,self.Animations["Run"],nil,true)
	hum.WalkSpeed = 25
end

function MainModule:Sways(): ()
	local AimCF = CFrame.new()
	local lastCameraCF = CFrame.new()
	local ModelSway = CFrame.new()
	local ModelRoll = CFrame.new()
	local WalkCF = CFrame.new()
	local Breath = CFrame.new()
	local Running = CFrame.new()

	local Char = Player.Character
	local Hum = Char:WaitForChild("Humanoid")
	local Model 
	Model = self:FindViewModel()

	if self.SwayConn then
		self.SwayConn:Disconnect()
		self.SwayConn = nil
	end
	
	self.SwayConn = RunService.PreRender:Connect(function(dt)
		local rot = Camera.CFrame:ToObjectSpace(lastCameraCF)
		local X, Y = rot:ToOrientation()

		local lerpSpeed = 10
		local alpha = 1 - math.exp(-lerpSpeed * dt)
		Model["Left Arm"].CanCollide = false
		Model["Right Arm"].CanCollide = false

		ModelSway = ModelSway:Lerp(CFrame.Angles(math.sin(math.clamp(X / dt * (1/60),-1,1)) * 0.6, math.sin(math.clamp(Y / dt * (1/60),-1,1)) * 0.6,0),alpha)

		lastCameraCF = Camera.CFrame

		if self.CanShoot or self.Reloading then
			if self.Spread.X > 0 or self.Spread.Y > 0 or self.Spread.X < 0 or self.Spread.Y < 0 then
				self:spreadDecrease()
			end
		end

		if Hum.MoveDirection.Magnitude > 0 then
			Breath = Breath:Lerp(CFrame.new(),alpha)

			local relative = Player.Character.HumanoidRootPart.CFrame:VectorToObjectSpace(Hum.MoveDirection)

			if relative.X > 0.1 then
				ModelRoll = ModelRoll:Lerp(CFrame.Angles(0 ,0 ,-0.020),alpha)
			elseif relative.X < -0.1 then
				ModelRoll = ModelRoll:Lerp(CFrame.Angles(0 ,0 ,0.020),alpha)
			end

			if self.Running then
				Running = Running:Lerp(CFrame.Angles(0,math.sin(os.clock() * 10) * 0.05,0),alpha)
			else 
				Running = Running:Lerp(CFrame.new(),alpha)
			end

			if Model.Name:find("ViewModelTP") then
				Camera.CFrame *= CFrame.Angles(0 ,0 ,math.rad(math.sin(os.clock() * 5) * 1))
			else
				Camera.CFrame *= CFrame.Angles(0 ,0 ,math.rad(math.sin(os.clock() * 5) * 1.5))
			end

			WalkCF = WalkCF:Lerp(CFrame.new(math.sin(os.clock() * 5) * .01,math.cos(os.clock() * 5) * .01,0),alpha)         
		else
			ModelRoll = ModelRoll:Lerp(CFrame.new(),alpha)
			WalkCF = WalkCF:Lerp(CFrame.new(),alpha)
			Breath = Breath:Lerp(CFrame.new(0,math.sin(os.clock()* 1.5 )* .01 ,0),alpha)
		end

		if self.Aiming and not self.Reloading and not self.Running then
			self.Zoom:Play()
			if Model.Name:find("ViewModelTP") then
				AimCF = AimCF:Lerp(CFrame.new(self.ADS.TP.AimCFX,self.ADS.TP.AimCFY,self.ADS.TP.AimCFZ),alpha)
			else
				AimCF = AimCF:Lerp(CFrame.new(self.ADS.AimCFX,self.ADS.AimCFY,self.ADS.AimCFZ),alpha)               
			end
		elseif not self.Aiming then
			if Camera.FieldOfView ~= 70 then
				self.NoZoom:Play()
			end
			AimCF = AimCF:Lerp(CFrame.new(),alpha)
		end

		if self:IsFirstPerson() then
			if Model.Name:find("ViewModelTP") then
				self:RemoveModel("TP")
				self:CreateModel()
				Model = self:FindViewModel()
				if self.Running then
					self.Running = Functions.PlayAnimationModel(Model,self.Animations["Run"],nil,true)
				end
			end

			Model:PivotTo(Camera.CFrame * CFrame.new(0,-4.5,0) * ModelSway * AimCF * WalkCF * ModelRoll * Breath * Running)
		else
			if Model.Name:find("ViewModelFP") then
				self:RemoveModel("FP")
				self:CreateModel()
				Model = self:FindViewModel()
				if self.Running then
					self.Running = Functions.PlayAnimationModel(Model,self.Animations["Run"],nil,true)
				end
			end

			Model:PivotTo(Player.Character.Head.CFrame * CFrame.new(0,-4.5,0) * ModelSway * AimCF * WalkCF * Running)
			-- CFrame -4.5 to align with the head
		end

	end)
end

return MainModule