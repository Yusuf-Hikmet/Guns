local GuiController = {}

local Player = game.Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

function GuiController.UpdateGui(GunName: string ,Ammo: number, CurrentAmmo: number): ()
	local GunsGui: ScreenGui = PlayerGui:WaitForChild("GunsGui")
	local AmmoFrame = GunsGui:WaitForChild("AmmoFrame")
	local AmmoLabel = AmmoFrame.AmmoLabel
	local GunNameLabel = AmmoFrame.GunNameLabel
	
	GunNameLabel.Text = GunName
	AmmoLabel.Text = CurrentAmmo.."/"..Ammo
end

function GuiController.ToggleGui(FrameName: string,Enabled: boolean): ()
	local GunsGui: ScreenGui = PlayerGui:WaitForChild("GunsGui")
	local AmmoFrame = GunsGui:WaitForChild("AmmoFrame")
	local AmmoLabel = AmmoFrame.AmmoLabel
	local GunNameLabel = AmmoFrame.GunNameLabel
	
	GunsGui[FrameName].Visible = Enabled
end

return GuiController
