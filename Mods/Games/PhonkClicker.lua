local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Crokier/Roblox/main/Packages/Sampluy/init.luau"))()

local Services = setmetatable({}, {__index = function(_, i) return cloneref and cloneref(game:GetService(i)) or game:GetService(i) end})
local Players = Services.Players
local ReplicatedStorage = Services.ReplicatedStorage
local VirtualInputManager = Services.VirtualInputManager
local UserInputService = Services.UserInputService

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local Enableds = {["Click"] = false, ["Upgrade"] = false, ["Rebirth"] = false}

local Values = {
	["ClickPoint"] = Vector2.new(500, 500),
	["RebirthDebounce"] = false,
	["LuckyBlockDebounce"] = false,
	["FailColor"] = Color3.fromRGB(244, 67, 54),
	["SuccessColor"] = Color3.fromRGB(112, 255, 73) 
}

local TypeData = {
	["Upgrade"] = {},
	["Code"] = {}
}

local ActiveData = {
	["Upgrade"] = {
		["AllEnabled"] = true
	}
}

local InfoData = {
	["Upgrade"] = {},
}

local Packets = {
	["Click"] = ReplicatedStorage:QueryDescendants("#Remotes > #ClickBrainrot")[1],
	["Rebirth"] = ReplicatedStorage:QueryDescendants("#Remotes > #Rebirth")[1],
	["RedeemCode"] = ReplicatedStorage:QueryDescendants("#Remotes > #RedeemCode")[1]
}

local Modules = {}

local Interfaces = {
	["LuckyBlockFrame"] = PlayerGui:QueryDescendants("#Main > #LuckyRewardFrame")[1],
	["LuckyBlockRedeemButton"] = PlayerGui:QueryDescendants("#Main > #LuckyRewardFrame > #RedeemButton")[1],
	["LuckyBlockCloseButton"] = PlayerGui:QueryDescendants("#LuckyBlock > #EndBrainrotFrame > #FinalBrainrotFrame > #Close")[1],
	["UpgradeScroll"] = PlayerGui:QueryDescendants("#Main > #UpgradesBackground > #ScrollingFrame")[1],
	["HUDRebirthButton"] = PlayerGui:QueryDescendants("#Main > #UpgradesBackground > #RebirthButton")[1],
	["CheckRebirth"] = PlayerGui:QueryDescendants("#Main > #UpgradesBackground > #RebirthButton > #BuyButton")[1],
	["RebirthButton"] =  PlayerGui:QueryDescendants("#Main > #RebirthBackground > #RebirthButtons > #RebirthButton")[1],
	["RebirthFill"] = PlayerGui:QueryDescendants("#Main > #RebirthBackground > #RequirementsFrame > #MoneyNeededBG > #Bar")[1],
	["AutoClickButton"] = PlayerGui:QueryDescendants("#Main > #AutoClickerButton")[1],
	["AutoClickTimeLabel"] = PlayerGui:QueryDescendants("#Main > #AutoClickerButton > #TimeLabel")[1]
}

task.delay(2, function()
	Values.ClickPoint = UserInputService:GetMouseLocation()
end)

if Interfaces.UpgradeScroll then
	local sortUpgrades = {}

	for _, layer in ipairs(Interfaces.UpgradeScroll:GetChildren()) do
		if layer and layer.Parent and layer:IsA("GuiObject") then
			local button = layer:FindFirstChild("BuyButton")
			if not button then continue end

			local lockedFrame = layer:FindFirstChild("LockedFrame")
			if not lockedFrame then continue end

			local key = layer.Name

			if ActiveData.Upgrade[key] == nil then
				ActiveData.Upgrade[key] = false
				table.insert(sortUpgrades, {
					["Name"] = key,
					["Tier"] = layer.LayoutOrder,
					["Button"] = button,
					["LockedFrame"] = lockedFrame,
				})
			end
		end
	end

	table.sort(sortUpgrades, function(a, b)
		return a.Tier < b.Tier
	end)

	for _, info in ipairs(sortUpgrades) do
		table.insert(TypeData.Upgrade, info.Name)
	end

	table.sort(sortUpgrades, function(a, b)
		return a.Tier > b.Tier
	end)
	
	for _, info in ipairs(sortUpgrades) do
		table.insert(InfoData.Upgrade, info)
	end
end

local function FireButton(button)
	if firesignal then
		if not (button and button.Parent) then return end
		firesignal(button.Activated)
		firesignal(button.MouseButton1Click)
	end
end

local function FireTouch(part1, part2)
	if firetouchinterest then
		if not (part1 and part1.Parent and part2 and part2.Parent) then return end
		firetouchinterest(part1, part1, 1)
		task.wait()
		if not (part1 and part1.Parent and part2 and part2.Parent) then return end
		firetouchinterest(part1, part1, 0)
	end
end

local function SendClick(x,y)
	VirtualInputManager:SendMouseButtonEvent(x,y,0,true,game,0)
	task.wait()
	VirtualInputManager:SendMouseButtonEvent(x,y,0,false,game,0)
end

local Window = UI:CreateWindow({
	Name = "Phonk Clicker",
	Destroying = function()
		for key, enabled in pairs(Enableds) do
			Enableds[key] = false
		end
	end
})

Window:AddToggle({
	Text = "Auto Click",
	Value = false,
	Callback = function(value)
		Enableds.Click = value
		if not Enableds.Click then return end
		task.spawn(function()
			while Enableds.Click do
				if Interfaces.AutoClickButton and Interfaces.AutoClickTimeLabel and Interfaces.AutoClickTimeLabel.Text == "Ready" then
					task.wait(1.5)
					FireButton(Interfaces.AutoClickButton)
				end
				Packets.Click:FireServer(1)
				task.wait()
			end
		end)
	end
})

Window:AddDropdown({
	Text = "Upgrade Type (Empty = All)",
	Options = #TypeData.Upgrade > 0 and TypeData.Upgrade or {"No Upgrade Type"},
	Option = nil,
	MultipleOptions = true,
	Callback = function(option)
		for _, mode in ipairs(TypeData.Upgrade) do
			ActiveData.Upgrade[mode] = table.find(option, mode) ~= nil
		end
		ActiveData.Upgrade.AllEnabled = #option <= 0
	end
})

Window:AddToggle({
	Text = "Auto Upgrade",
	Value = false,
	Callback = function(value)
		Enableds.Upgrade = value
		if not Enableds.Upgrade then return end
		task.spawn(function()
			while Enableds.Upgrade do
				for _, info in ipairs(InfoData.Upgrade) do
					if not Enableds.Upgrade then break end
					local active = ActiveData.Upgrade[info.Name]
					if info ~= nil and (active or ActiveData.Upgrade.AllEnabled) then
						local lockedFrame = info.LockedFrame
						if lockedFrame and lockedFrame.Visible == true then return end
						local button = info.Button
						if button then 
							if button.ImageColor3 == Values.FailColor then return end
							FireButton(button)
						end
					end
					task.wait()
				end
				task.wait()
			end
		end)
	end
})

Window:AddToggle({
	Text = "Open Lucky Block",
	Value = false,
	Callback = function(value)
		Enableds.LuckyBlock = value
		if not Enableds.LuckyBlock then Values.LuckyBlockDebounce = false return end
		task.spawn(function()
			while Enableds.LuckyBlock do
				if Enableds.LuckyBlock and Interfaces.LuckyBlockFrame.Visible then
					if not Values.LuckyBlockDebounce then 
						Values.LuckyBlockDebounce = true 
						FireButton(Interfaces.LuckyBlockRedeemButton)
						task.wait(0.5)
						for i = 1, 7 do
							SendClick(Values.ClickPoint.X, Values.ClickPoint.Y)
						end
						task.wait(0.5)
						if Interfaces.LuckyBlockCloseButton then
							FireButton(Interfaces.LuckyBlockCloseButton)
						end
						Values.LuckyBlockDebounce = false
					end
					
				end
				task.wait()
			end
		end)
	end
})

Interfaces.CodeDropdown = Window:AddDropdown({
	Text = "Code List",
	Options = {"No Code"},
	Option = nil,
	Multi = true,
	Callback = function() end
})

Window:AddButton({
	Text = "Claim Code",
	MethodType = "DebounceClick",
	Callback = function()
		Modules.CodeData = Modules.CodeData or require(ReplicatedStorage:QueryDescendants("#Modules > #CodesConfig")[1]:Clone())
		table.clear(TypeData.Code)
		for code, info in pairs(Modules.CodeData.Codes) do
			Packets.RedeemCode:InvokeServer(code)
			table.insert(TypeData.Code, code)
		end
		Interfaces.CodeDropdown.Options = TypeData.Code
		Interfaces.CodeDropdown:Refresh()
	end
})

Window:AddToggle({
	Text = "Auto Rebirth",
	Value = false,
	Callback = function(value)
		Enableds.Rebirth = value
		if not Enableds.Rebirth then Values.RebirthDebounce = false return end
		task.spawn(function()
			while Enableds.Rebirth do
				if Interfaces.CheckRebirth.ImageColor3 == Values.SuccessColor then
					if not Values.RebirthDebounce then 
						Values.RebirthDebounce = true
						FireButton(Interfaces.HUDRebirthButton)
						task.wait(0.1)
						FireButton(Interfaces.RebirthButton)
						Packets.Rebirth:InvokeServer()
						task.wait(0.5)
						for i = 1, 7 do
							SendClick(Values.ClickPoint.X, Values.ClickPoint.Y)
						end
						task.wait(0.5)
						if Interfaces.LuckyBlockCloseButton then
							FireButton(Interfaces.LuckyBlockCloseButton)
						end
						Values.RebirthDebounce = false
					end
					
				end
				task.wait()
			end
		end)
	end
})

Window:AddLabel({
	Text = "YouTube: Crokyreo",
	TextColor3 = Color3.fromRGB(255, 255, 255)
})
