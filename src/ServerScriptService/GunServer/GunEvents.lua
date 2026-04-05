local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local ActiveWeapons = workspace:WaitForChild("ActiveWeapons")
local GunSystem: Folder = ReplicatedStorage:WaitForChild("GunSystem")
local Remotes: Folder = GunSystem:WaitForChild("Remotes")
local Modules: Folder = GunSystem:WaitForChild("Modules")
local Guns: Folder = GunSystem:WaitForChild("Guns")

local Damage: RemoteEvent = Remotes:WaitForChild("Damage")
local SoundPlayer: RemoteEvent = Remotes:WaitForChild("SoundPlayer")
local DropItem: RemoteEvent = Remotes:WaitForChild("DropItem")
local GetRayOrigin: RemoteFunction = Remotes:WaitForChild("GetRayPosition")

local ReloadDataTransfer: BindableEvent = script.Parent.ReloadDataTransfer

local GunsDatas = require(Modules:WaitForChild("GunsDatas"))
local Functions = require(Modules:WaitForChild("Functions"))
local GunProcess = require(script.Parent.GunProcess)

local function fSoundPlayer(SParent: any?,Sound: Sound)
	if SParent:FindFirstChild("Fire") then SParent:FindFirstChild("Fire"):Destroy() end

	Sound:Clone().Parent = SParent
	Sound:Play()
end

local PlayerInstances = {}

Damage.OnServerEvent:Connect(function(player,GunName ,Spread: Vector2)
	if not GunsDatas[GunName] then player:Kick("Gun not found") return end
	local Model = ActiveWeapons:FindFirstChild("ViewModelTP"..GunName..player.Name) or nil
	if not Model then player:Kick("Gun model not found") return end
	local IsPump =  GunsDatas[GunName].GaugeBuckshot 

	if not PlayerInstances[player.UserId].Guns[GunName] then
		PlayerInstances[player.UserId].Guns[GunName] = {
			lastFire = 999,
			CurrentAmmo = GunsDatas[GunName].MagSize,
			Ammo = GunsDatas[GunName].Ammo,
			Pump = GunsDatas[GunName].GaugeBuckshot	or nil
		}
	end
	
	if PlayerInstances[player.UserId] and PlayerInstances[player.UserId].Guns[GunName] then 
		local Gun = PlayerInstances[player.UserId].Guns[GunName]
		if Gun.Pump then
			Gun.Pump -= 1
			
			if Gun.CurrentAmmo <= 0 then
				return
			end
		end
		
		if not Gun.Pump or Gun.Pump == 0 then
			Gun.CurrentAmmo -= 1
			if tick() - Gun.lastFire < GunsDatas[GunName].FireRate then return end 

			if Gun.CurrentAmmo < 0 then print("CurrentAmmo is less than 0") return end
			
			if Gun.Pump then Gun.Pump = GunsDatas[GunName].GaugeBuckshot end
		end
	end
	
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {player.Character,Model}
	params.IgnoreWater = true

	Functions.PlayAnimationModel(Model,Guns[GunName].Animations["Fire"])
	local RayOrigin = GetRayOrigin:InvokeClient(player) :: {[string]: CFrame | Vector3}
	
	if not RayOrigin or (player.Character.HumanoidRootPart.Position - RayOrigin.Position).Magnitude > GunsDatas[GunName].maxHRPDist then return end

	local result = Functions.Ray(RayOrigin,GunsDatas[GunName].Range,params,GunName,Spread)

	if result then
		if result.Instance:FindFirstAncestorOfClass("Model") 
			and result.Instance:FindFirstAncestorOfClass("Model"):FindFirstChild("Humanoid") then

			local CharModel = result.Instance:FindFirstAncestorOfClass("Model")
			-- Player
			if Players:FindFirstChild(CharModel.Name) then
				local Humanoid = CharModel:FindFirstChild("Humanoid")
				local Multiplier = GunsDatas[GunName].DamageMultipliers[Functions.MultiplierFindX(result.Instance)]
				
				local Enemy = Players:GetPlayerFromCharacter(CharModel)
				if Enemy and Enemy:GetAttribute("Died") and Enemy:GetAttribute("Died") == true then return end
				if not Enemy then return end
				Humanoid:TakeDamage(GunsDatas[GunName].Damage * Multiplier)
				
				if Enemy then
					if Humanoid.Health <= 0 then Enemy:SetAttribute("Died",true) return end
					player.leaderstats.Cash.Value += 500
					player.leaderstats.Kill.Value += 1
				end

			else
				-- Npc
				local Humanoid = CharModel:FindFirstChild("Humanoid")
				local Multiplier = GunsDatas[GunName].DamageMultipliers[Functions.MultiplierFindX(result.Instance)]
				
				Humanoid:TakeDamage(GunsDatas[GunName].Damage * Multiplier)
				
				if Humanoid.Health <= 0 then
					player.leaderstats.Cash.Value += 10
				end
			end
		else
			if result.Instance:IsA("Part") or result.Instance:IsA("MeshPart") then
				local Hole = Instance.new("Part")
				Hole.Size = Vector3.new(.15,.15,.15)
				Hole.Position = result.Position
				Hole.Anchored = true
				Hole.CanCollide = true
				Hole.Parent = workspace
				Hole.Material = Enum.Material.SmoothPlastic
				Hole.Color = Color3.fromRGB()

				local hitpos = result.Position
				local hitnor = result.Normal

				Hole.CFrame = CFrame.lookAt(hitpos + hitnor * .01 ,hitpos + hitnor * .01 + hitnor)
				Debris:AddItem(Hole,3)
			end 
		end
	end
end)

SoundPlayer.OnServerEvent:Connect(function(player,Sound: Sound)
	fSoundPlayer(player.Character,Sound)
end)

DropItem.OnServerEvent:Connect(function(plr,GunName)
	if not GunName and typeof(GunName) ~= "string" then return end
	Functions.CloneGun(plr,GunName)
	PlayerInstances[plr.UserId].Guns[GunName] = nil
	DropItem:FireClient(plr,GunName)
end)

Players.PlayerAdded:Connect(function(player)
	task.delay(1,function()
		PlayerInstances[player.UserId] = GunProcess.GetInstance(player)
		print(PlayerInstances)
	end)	
end)

ReloadDataTransfer.Event:Connect(function(player,GunName,Bypassed)
	if not PlayerInstances[player.UserId].Guns[GunName] then return end

	print("Reload Data Reloaded")
	PlayerInstances[player.UserId]:Reload(GunName,Bypassed)
end)