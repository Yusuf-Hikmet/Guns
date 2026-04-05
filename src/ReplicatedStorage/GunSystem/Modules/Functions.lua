local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local GunSystem = ReplicatedStorage:WaitForChild("GunSystem")
local Remotes = GunSystem:WaitForChild("Remotes")

local Damage: RemoteEvent = Remotes:WaitForChild("Damage")
local ViewModelReload: RemoteEvent = Remotes:WaitForChild("ViewModelReload")
local GetItem: RemoteEvent = Remotes:WaitForChild("GetItem")

local GunsDatas = require(script.Parent:WaitForChild("GunsDatas"))

local Functions = {}

function Functions.SetArmsTransparency(player: Player,transparency: number): ()
	local character = player.Character
	local rightArm = character:WaitForChild("Right Arm")
	local leftArm = character:WaitForChild("Left Arm")

	rightArm.Transparency = transparency
	leftArm.Transparency = transparency
end

function Functions.CloneGun(player,GunName)
	if RunService:IsServer() then
		local GunProcess = require(SSS.GunServer.GunProcess)
		local PlrInstance = GunProcess.GetInstance(player)
		
		if not player.Character:FindFirstChild(GunName) then
			return
		else
			player.Character:FindFirstChild(GunName):Destroy()
		end
		
		local CGun = ServerStorage["Gun Models"][GunName]:Clone()
		local ProxyPrompt = Instance.new("ProximityPrompt",CGun)
		ProxyPrompt.HoldDuration = 2
		ProxyPrompt.MaxIndicatorDistance = 5
		ProxyPrompt.MaxActivationDistance = 5
		
		CGun.Parent = workspace
		CGun:PivotTo(player.Character:GetPivot() * CFrame.new(0,2,-2))
		CGun.PrimaryPart.AssemblyLinearVelocity += Vector3.new(math.random(-10,10),math.random(10,20),math.random(-10,10))
		
		print(PlrInstance)
		if not PlrInstance.Guns[GunName] then
			CGun:SetAttribute("Ammo",GunsDatas[GunName].Ammo)
			CGun:SetAttribute("CurrentAmmo",GunsDatas[GunName].MagSize)
			if GunsDatas[GunName].GaugeBuckshot then
				CGun:SetAttribute("GaugeBuckshot",GunsDatas[GunName].GaugeBuckshot)
			end
		else
			CGun:SetAttribute("Ammo",PlrInstance.Guns[GunName].Ammo)
			CGun:SetAttribute("CurrentAmmo",PlrInstance.Guns[GunName].CurrentAmmo)
			if GunsDatas[GunName].GaugeBuckshot then
				CGun:SetAttribute("GaugeBuckshot",PlrInstance.Guns[GunName].Pump)
			end
		end
		
		task.delay(300,function()
			CGun:Destroy()
		end)
		
		ProxyPrompt.Triggered:Connect(function(plr)
			if plr.Backpack:FindFirstChild(GunName) then
				return 
			end
			
			local CGunTool = ServerStorage["AvailableGuns"][GunName]:Clone()
			CGunTool.Parent = plr.Backpack
			GetItem:FireClient(plr,GunName ,
				CGun:GetAttribute("Ammo"),
				CGun:GetAttribute("CurrentAmmo"),
				CGun:GetAttribute("GaugeBuckshot"))
			
			PlrInstance.Guns[GunName] = nil
			
			local GetPlrInstance = GunProcess.GetInstance(plr)
			
			if not GetPlrInstance.Guns[GunName] then
				GetPlrInstance.Guns[GunName] = {}
			end
			
			GetPlrInstance.Guns[GunName].Ammo = CGun:GetAttribute("Ammo")
			GetPlrInstance.Guns[GunName].CurrentAmmo = CGun:GetAttribute("CurrentAmmo") 
			if GunsDatas[GunName].GaugeBuckshot then
				GetPlrInstance.Guns[GunName].Pump = CGun:GetAttribute("GaugeBuckshot")
			end
			GetPlrInstance.Guns[GunName].lastFire = 999
			CGun:Destroy()
		end)
	end
end

function Functions.SetArmsApperance(plr,viewmodel: Model): ()
	local character = plr.Character
	local humanoid = character:WaitForChild("Humanoid")
	local SkinColor = humanoid:GetAppliedDescription().HeadColor
	local Shirt = character:FindFirstChild("Shirt")

	local ViewModelShirt = viewmodel:FindFirstChild("Shirt")

	if viewmodel:FindFirstChild("Right Arm") then
		viewmodel["Right Arm"].Color = SkinColor
	end

	if viewmodel:FindFirstChild("Left Arm") then
		viewmodel["Left Arm"].Color = SkinColor
	end

	if Shirt and ViewModelShirt then
		ViewModelShirt.ShirtTemplate = Shirt.ShirtTemplate
	end
end

function Functions.MultiplierFindX(Part: Instance): string?
	local RPart
	if Part:IsA("BasePart") then
		if Part.Name == "Head" then
			RPart = "Head"
		elseif Part.Name == "Left Arm" or Part.Name == "Right Arm" then
			RPart = "Arms"
		elseif Part.Name == "Left Leg" or Part.Name == "Right Leg" then
			RPart = "Legs"
		elseif "HumanoidRootPart" then
			RPart = "Torso"
		else
			RPart = "Torso"
		end

		return RPart
	else
		return
	end
end

local tracking = {}

function Functions.PlayAnimationModel(Model: Model, Anim: Animation, plr: Player?,AnimIsReturned: boolean?): ()
	if not Anim or Anim.AnimationId == "" then return end
	if tracking[Model] then return end

	tracking[Model] = true

	local Hum = Model:WaitForChild("Humanoid")
	local Animator = Hum:FindFirstChild("Animator")

	local TAnim: AnimationTrack = Animator:LoadAnimation(Anim)
	TAnim:Play()

	if AnimIsReturned then
		tracking[Model] = nil
		return TAnim
	end

	if Anim.Name ~= "Reload" then
		TAnim.Stopped:Connect(function()
			tracking[Model] = nil
		end)
	else
		ViewModelReload:FireServer(Model.Name:sub(12))
		tracking[Model] = nil
	end

	local AnimLength = TAnim.Length
	task.delay(AnimLength, function()
		if tracking[Model] and AnimLength > 0 then
			tracking[Model] = nil
		end
	end)

	if RunService:IsClient() and plr then

		local function ModelFinder(GunName: string): Model
			local Model

			if plr.Character:FindFirstChild("ViewModelTP"..GunName) then
				Model = plr.Character:FindFirstChild("ViewModelTP"..GunName)
			elseif workspace.CurrentCamera:FindFirstChild("ViewModelFP"..GunName) then
				Model = workspace.CurrentCamera:FindFirstChild("ViewModelFP"..GunName)
			end

			return Model
		end

		local CurrentModelType: string

		local function FPToTPAnim(Recall: boolean? ,NewAnim: AnimationTrack? ,RestartTimeValue: number?): ()
			local AnimProcess: number
			if Recall then
				AnimProcess = RestartTimeValue
			else
				AnimProcess = 0
			end

			local ModelControl = true
			local Problem = false

			task.spawn(function()
				local GunName = Model.Name:sub(12)

				while ModelControl do

					if Model.Name:find("ViewModelTP") and not Recall then
						CurrentModelType = "TP"
					elseif not Recall then
						CurrentModelType = "FP"
					end

					if CurrentModelType == "TP" then
						ModelControl = plr.Character:FindFirstChild("ViewModelTP"..GunName)
					else
						ModelControl = workspace.CurrentCamera:FindFirstChild("ViewModelFP"..GunName)
					end

					Problem = true
					if not tracking[Model] and AnimProcess > GunsDatas[GunName].ReloadTime then Problem = false break end
					AnimProcess += .1
					task.wait(.1)
				end

				if Problem then
					local RestartTime

					ModelControl = ModelFinder(GunName)
					if not ModelControl then return end
					CurrentModelType = ModelControl.Name:sub(10,11) -- "TP" or "FP" returned

					if Recall and NewAnim then
						NewAnim:Stop()
						RestartTime = NewAnim.TimePosition

						local Animator = ModelControl:FindFirstChild("Humanoid"):FindFirstChild("Animator")
						local Nanim: AnimationTrack =  Animator:LoadAnimation(Anim)
						Nanim:Play()
						Nanim.TimePosition = RestartTime

						FPToTPAnim(true,Nanim,Nanim.TimePosition)
					else

						TAnim:Stop()
						RestartTime = TAnim.TimePosition

						local Animator = ModelControl:FindFirstChild("Humanoid"):FindFirstChild("Animator")
						local Nanim: AnimationTrack = Animator:LoadAnimation(Anim)

						Nanim:Play()
						Nanim.TimePosition = RestartTime
						FPToTPAnim(true,Nanim,Nanim.TimePosition)
					end
				end
			end)
		end
		FPToTPAnim()
	end
end

function Functions.Ray(OriginInstance: {},range: number,Filter: RaycastParams,GunName: string ,Spread: Vector2): RaycastResult?
	local direction = (
		OriginInstance.CFrame.LookVector + 
			OriginInstance.CFrame.RightVector * Spread.X +
			OriginInstance.CFrame.UpVector * Spread.Y).Unit * range

	local result = workspace:Raycast(OriginInstance.Position ,direction ,Filter)	

	if result then
		print("Hitted",result.Instance.Name)
		if RunService:IsServer() then
			return result
		else
			Damage:FireServer(GunName,Spread)
		end
	else
		if RunService:IsServer() then
			return result
		else
			Damage:FireServer(GunName,Spread)
		end
	end
end

return Functions