local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Crokier/Roblox/main/Packages/Sampluy/init.luau"))()

local Services = setmetatable({}, {__index = function(_, i) return cloneref and cloneref(game:GetService(i)) or game:GetService(i) end})
local Players = Services.Players
local ReplicatedStorage = Services.ReplicatedStorage

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")

local Enableds = {["Upgrade"] = false, ["Rebirth"] = false, ["ClaimIndex"] = false}
local Packets = {
	["BuyRebirth"] = ReplicatedStorage:QueryDescendants("#Remotes > #BuyRebirth")[1],
	["BuyUpgrade"] = ReplicatedStorage:QueryDescendants("#Remotes > #BuyUpgrade")[1],
	["ClaimIndex"] = ReplicatedStorage:QueryDescendants("#Remotes > #ClaimIndexReward")[1]
}
local Interfaces = {
	["MoneyUpgradeScroll"] = PlayerGui:QueryDescendants("#Main > #UIFrames > #UpgradeFrame > #ScrollingFrame")[1],
	["ClaimAllButton"] = PlayerGui:QueryDescendants("#Main > #UIFrames > #IndexFrame > #ViewFrame > #ClaimFrame")[1]
}

if Interfaces.ClaimAllButton then local target = Interfaces.ClaimAllButton Interfaces.ClaimAllButton = nil for i,v in ipairs(target:GetChildren()) do local lowerName = v.Name:lower() if lowerName:find("claimallbutton") or lowerName:find("claimalllbutton") then Interfaces.ClaimAllButton = v break end end end

local function FireButton(button)
	if firesignal then
		if not (button and button.Parent) then return end
		firesignal(button.Activated)
		firesignal(button.MouseButton1Click)
	end
end

local Window = UI:CreateWindow({
	Name = "Collect 1 Million Items",
	ConfigInfo = {Enabled=true,Path="Crokyreo/Collect1MillionItems/configs.json"},
	Destroying = function()
		for key, enabled in pairs(Enableds) do
			Enableds[key] = false
		end
	end
})

Window:BuildSettingsFeature({Link = "https://raw.githubusercontent.com/akipox/Roblox/main/Mods/Games/Collect1MillionItems.lua"})

Interfaces.UpgradeToggle = Window:AddToggle({
	Text = "Auto Upgrade",
	Value = false,
	Flag = "upgrade_enabled",
	Callback = function(value)
		Enableds.Upgrade = value
		if not Enableds.Upgrade then return end
		
		if not Interfaces.MoneyUpgradeScroll and Packets.BuyRebirth then
			Enableds.Upgrade = false
			Interfaces.UpgradeToggle:Replace(false)
			return
		end
		
		task.spawn(function()
			while Enableds.Upgrade do
				for _, layer in ipairs(Interfaces.MoneyUpgradeScroll:GetChildren()) do
					if not Enableds.Upgrade then break end
					
					if layer and layer.Parent and layer:IsA("GuiObject") then
						local key = layer.Name
						
						local buyTitle = layer:QueryDescendants("#BuyButton > #TextLabel")[1]
						if buyTitle ~= nil and buyTitle.Text:find("Not Enough") then continue end

						local title = layer:FindFirstChild("TextLabel")
						if not title then continue end
						
						Packets.BuyUpgrade:FireServer(key)
						task.wait()
					end
				end
				task.wait()
			end
		end)
	end
})

Interfaces.ClaimIndexToggle = Window:AddToggle({
	Text = "Claim Index",
	Value = false,
	Flag = "claim_index_enabled",
	Callback = function(value)
		Enableds.ClaimIndex = value
		if not Enableds.ClaimIndex then return end

		if not Interfaces.ClaimAllButton then
			Enableds.ClaimIndex = false
			Interfaces.ClaimIndexToggle:Replace(false)
			return
		end

		task.spawn(function()
			while Enableds.ClaimIndex do
				if Interfaces.ClaimAllButton.Visible == true then
					FireButton(Interfaces.ClaimAllButton)
				end
				task.wait()
			end
		end)
	end
})

Interfaces.RebirthToggle = Window:AddToggle({
	Text = "Auto Rebirth",
	Value = false,
	Flag = "rebirth_enabled",
	Callback = function(value)
		Enableds.Rebirth = value
		if not Enableds.Rebirth then return end
		
		if not Packets.BuyRebirth then
			Enableds.Rebirth = false
			Interfaces.RebirthToggle:Replace(false)
			return
		end
		
		task.spawn(function()
			while Enableds.Rebirth do
				Packets.BuyRebirth:FireServer()
				task.wait(3)
			end
		end)
	end
})

Window:AddLinkButton({Text = "Donate 💖", Link = "https://link-target.net/6690566/TlR2vuR2JR4F"})
Window:AddLabel({Text = "YouTube: Crokyreo", TextColor3 = Color3.fromRGB(255, 255, 255)})
Window:LoadConfig()
