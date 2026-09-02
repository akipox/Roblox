-- This is what the script looks like from Tora IsMe.
-- This is a script I made myself. I DO NOT STEAL SCRIPT because i can't read script on Tora IsMe

---------------------------------- [DEPENDENCIES] ----------------------------------
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Crokier/Roblox/main/Packages/Sampluy/init.luau"))()
local Services = setmetatable({}, {__index = function(_, i) return cloneref and cloneref(game:GetService(i)) or game:GetService(i) end})
local Players = Services.Players
local ReplicatedStorage = Services.ReplicatedStorage

---------------------------------- [VARIABLES] ----------------------------------
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- State Management
local Enableds = {["Click"] = false, ["Upgrade"] = false, ["Cash"] = false, ["Stage"] = false, ["Sell"] = false, ["Rebirth"] = false, ["Equip"] = false}
local Connections = {}
local Packets = {}
local ClickIndex = 0

-- UI & Game Objects
local Interfaces={
	["MainGui"] = PlayerGui:FindFirstChild("Main"),
	["HomeButton"] = PlayerGui:QueryDescendants("#HUD > #Main > #Top > #GoShow > #TextButton")[1],
	["UpgradeScroll"] = PlayerGui:QueryDescendants("#Main > #Upgrades > #Main > #ScrollingFrame")[1],
}

local AmountValue = LocalPlayer:QueryDescendants("#BackpackData > #amount")[1]
local CapacityValue = LocalPlayer:QueryDescendants("#BackpackData > #capacity")[1]
local StageValue = LocalPlayer:QueryDescendants("#Stage > #stage")[1]


local UpgradeTypes, UpgradeActives, UpgradeInfos = {}, {["AllEnabled"] = true}, {}
local ProfileData = {
	["MaxStage"] = 0
}

local StageFolder = nil
local WorldFishFolder = nil
local CashHitbox = nil
local CashToggle = nil
---------------------------------- [INITIALIZATION] ----------------------------------
-- Track Player Data
if StageValue and (StageValue:IsA("NumberValue") or StageValue:IsA("IntValue")) then
	ProfileData.Stage = StageValue.Value
	Connections.StageChanged = StageValue:GetPropertyChangedSignal("Value"):Connect(function()
		ProfileData.Stage = StageValue.Value
	end)
end

if CapacityValue and (CapacityValue:IsA("NumberValue") or CapacityValue:IsA("IntValue")) then
	ProfileData.Capacity = CapacityValue.Value
	Connections.CapacityChanged = CapacityValue:GetPropertyChangedSignal("Value"):Connect(function()
		ProfileData.Capacity = CapacityValue.Value
	end)
end

if AmountValue and (AmountValue:IsA("NumberValue") or AmountValue:IsA("IntValue")) then
	ProfileData.Amount = AmountValue.Value
	Connections.AmountChanged = AmountValue:GetPropertyChangedSignal("Value"):Connect(function()
		ProfileData.Amount = AmountValue.Value
	end)
end

local LevelTarget = ProfileData.Stage or 1

-- Track Character
Connections.CharacterAdded = LocalPlayer.CharacterAdded:Connect(function(newCharacter)
	Character = newCharacter
end)

-- Parse Upgrades
if Interfaces.UpgradeScroll then
	local sortUpgrades = {}

	for _, layer in ipairs(Interfaces.UpgradeScroll:GetChildren()) do
		if layer and layer.Parent and layer:IsA("GuiObject") then
			local frame = layer:FindFirstChild("1")
			if not frame then continue end

			local buyButton = frame:QueryDescendants("#Sell > #go")[1]
			if not buyButton then continue end

			local title = frame:QueryDescendants("#Flame > #name")[1]
			if not title then continue end

			local key = title.Text

			if not UpgradeInfos[key] then
				UpgradeInfos[key] = {}
				UpgradeActives[key] = false
				table.insert(sortUpgrades, {
					Name = key,
					Tier = layer.LayoutOrder,
				})
			end

			table.insert(UpgradeInfos[key], {
				Name = key,
				UpgradeButton = buyButton
			})
		end
	end

	table.sort(sortUpgrades, function(a, b)
		return a.Tier < b.Tier
	end)

	for _, info in ipairs(sortUpgrades) do
		table.insert(UpgradeTypes, info.Name)
	end 
end

-- Find Stage and WorldFish Folders
for _, v1 in ipairs(workspace:GetChildren()) do
	if not (v1 and v1.Parent) then continue end
	if v1.Name == "主场景" then
		for _, v2 in ipairs(v1:GetChildren()) do
			if not (v2 and v2.Parent) then continue end
			if v2.Name == "验证场景" then
				for _, v3 in ipairs(v2:GetChildren()) do
					if not (v3 and v3.Parent) then continue end
					if v3.Name:find("关卡") then
						StageFolder = v2
						break
					end
				end

				if StageFolder then 
					if not WorldFishFolder then
						WorldFishFolder = StageFolder:FindFirstChild("WorldFish")
					end
					for _, v3 in ipairs(StageFolder:GetChildren()) do
						if not (v3 and v3.Parent) then continue end
						if v3.Name:find("关卡") then
							ProfileData.MaxStage += 1
						end
					end
					break 
				end
			end
		end
		if StageFolder then break end
	end
end

---------------------------------- [UTILITY] ----------------------------------
local function FirePrompt(prompt)
	if fireproximityprompt then
		fireproximityprompt(prompt, 0)
	end
end

local function FireButton(button)
	if firesignal then
		firesignal(button.Activated)
		firesignal(button.MouseButton1Click)
	end
end

local function FireTouch(hitPart, targetPart)
	if firetouchinterest then
		firetouchinterest(hitPart, targetPart, 1)
		task.wait()
		firetouchinterest(hitPart, targetPart, 0)
	end
end

local function IsFillFull(fill)
	return fill.Size.X.Scale >= 1
end

local function GetPlot()
	local fishShowPlotId = LocalPlayer:GetAttribute("FishShowPlotId")
	for _, plot in ipairs(workspace:GetChildren()) do
		local folder = plot:FindFirstChild("玩家区域")
		if not folder then continue end

		local plotId = tonumber(plot.Name:match("%d+") or "")
		if not plotId then continue end

		local humanoid = plot:FindFirstChildOfClass("Humanoid")
		if humanoid then continue end

		if fishShowPlotId ~= nil and plotId == fishShowPlotId then
			return plot
		end
	end
	return nil
end

local function SuperPivoTo(model, p1, p2, height)
	local orientation = p2.Orientation
	local extraHeight = (p1.Size.Y / 2) + (p2.Size.Y / 2) + height
	local newPosition = Vector3.new(p1.Position.X, p1.Position.Y + extraHeight, p1.Position.Z)
	local newRotation = CFrame.fromEulerAngles(math.rad(orientation.X), math.rad(orientation.Y), math.rad(orientation.Z), Enum.RotationOrder.YXZ)
	model:PivotTo(CFrame.new(newPosition) * newRotation)
end

---------------------------------- [LOGIC] ----------------------------------
local Plot = GetPlot()

local function HandleCash()
	if not Enableds.Cash then return end
	if not CashHitbox then
		local newPlot = Plot or GetPlot()
		if newPlot then
			local folder = newPlot:FindFirstChild("玩家区域")
			if folder then
				for _, model in ipairs(folder:GetChildren()) do
					if model.Name:find("收集按钮") and model:IsA("Model") then
						local part = model:FindFirstChild("Cash")
						if not part then continue end

						local hitbox = model:FindFirstChild("Touch")
						if not hitbox then continue end

						CashHitbox = hitbox
						break
					end
				end
			end
		end
	end

	if not CashHitbox then
		Enableds.Cash = false
		Interfaces.CashToggle:Replace(false)
		return
	end

	task.spawn(function()
		while Enableds.Cash do
			local rootPart = Character.PrimaryPart or Character:FindFirstChild("HumanoidRootPart")
			if rootPart and CashHitbox then
				FireTouch(rootPart, CashHitbox)
			end
			task.wait(1)
		end
	end)
end

local function HandleClick()
	if not Enableds.Click then return end
	Packets.Click = Packets.Click or ReplicatedStorage.Remote.Event.Level["[C-S]Click"]
	if not Packets.Click then
		Enableds.Click = false
		Interfaces.ClickToggle:Replace(false)
		return
	end
	task.spawn(function()
		while Enableds.Click do
			Packets.Click:FireServer(ClickIndex)
			ClickIndex += 1
			task.wait(0.1)
		end
	end)
end

local function HandleEquip()
	if not Enableds.Equip then return end
	Packets.EquipBest = Packets.EquipBest or ReplicatedStorage.Remote.Function.FishShow["[C-S]BestFishUI"]
	if not Packets.EquipBest then
		Enableds.Equip = false
		Interfaces.EquipToggle:Replace(false)
		return
	end
	task.spawn(function()
		while Enableds.Equip do
			Packets.EquipBest:InvokeServer()
			task.wait(3)
		end
	end)
end

local function HandleUpgrade()
	if not Enableds.Upgrade then return end

	task.spawn(function()
		while Enableds.Upgrade do
			for key, active in pairs(UpgradeActives) do
				if not Enableds.Upgrade then break end
				if key == "AllEnabled" then continue end
				if UpgradeActives.AllEnabled then active = true end
				if not active then continue end
				local list = UpgradeInfos[key]
				if not list then continue end
				for _, info in ipairs(list) do
					if not Enableds.Upgrade then break end
					local button = info.UpgradeButton
					if button then
						FireButton(button)
						task.wait(0.05)
					end
				end
				task.wait(0.05)
			end
			task.wait(0.5)
		end
	end)
end

local function HandleSell()
	if not Enableds.Sell then return end
	Packets.SellAll = Packets.SellAll or ReplicatedStorage.Remote.Function.Fish["[C-S]SellAllFish"]
	if not Packets.SellAll then
		Enableds.Sell = false
		Interfaces.SellToggle:Replace(false)
		return
	end
	task.spawn(function()
		while Enableds.Sell do
			Packets.SellAll:InvokeServer()
			task.wait(1)
		end
	end)
end

local function HandleStage()
	if not Enableds.Stage then return end
	Packets.GoHome = Packets.GoHome or ReplicatedStorage.Remote.Event.Level["[C-S]GoShow"]
	task.spawn(function()
		while Enableds.Stage do
			local level = ProfileData.Stage
			local levelFolder = StageFolder:FindFirstChild("关卡"..tostring(level))

			if levelFolder then
				local checkPart = levelFolder:FindFirstChild("光门")
				local surfacePart = levelFolder:FindFirstChild("水面")
				local humanoid = Character:FindFirstChildOfClass("Humanoid")
				local rootPart = Character.PrimaryPart or Character:FindFirstChild("HumanoidRootPart")

				while Enableds.Stage and checkPart and checkPart.CanCollide and level < LevelTarget do
					SuperPivoTo(Character, surfacePart, rootPart, humanoid.HipHeight)
					task.wait()
				end

				local lastLevel = ProfileData.Stage - 1
				if level >= LevelTarget then
					task.wait(0.3)
					local sortFishs = {}

					if WorldFishFolder then
						for _, child in ipairs(WorldFishFolder:GetChildren()) do
							if not Enableds.Hit then break end
							if child and child.Parent and child:IsA("Model") then
								local stageId = child:GetAttribute("StageId")
								if stageId == nil or stageId ~= lastLevel then continue end

								local price = child:GetAttribute("Price")
								if price == nil then continue end

								local fishRoot = child:FindFirstChild("FishRoot")
								if not fishRoot then continue end

								local prompt = fishRoot:FindFirstChild("PickupPrompt")

								table.insert(sortFishs, {
									Tier = price,
									SpawnPoint = fishRoot,
									Prompt = prompt,
								})
								task.wait()
							end
						end
					end

					if not Enableds.Stage then break end

					table.sort(sortFishs, function(a, b)
						return a.Tier > b.Tier
					end)

					for _, info in ipairs(sortFishs) do
						if not Enableds.Stage then break end
						if ProfileData.Amount >= ProfileData.Capacity then
							if Packets.GoHome then
								Packets.GoHome:FireServer()
							else
								FireButton(Interfaces.HomeButton)
							end
							break
						end
						local spawnPoint, prompt = info.SpawnPoint, info.Prompt
						SuperPivoTo(Character, spawnPoint, rootPart, humanoid.HipHeight)
						task.wait(0.1)
						FirePrompt(prompt)
						task.wait(0.1)
					end
					table.clear(sortFishs)
				end
			end

			task.wait()
		end
	end)
end

local function HandleRebirth()
	if not Enableds.Rebirth then return end
	Interfaces.RebirthFrame = Interfaces.RebirthFrame or (Interfaces.MainGui and Interfaces.MainGui:FindFirstChild("Rebirth+1water") and Interfaces.MainGui["Rebirth+1water"]:FindFirstChild("UI1") or nil)
	if Interfaces.RebirthFrame then
		Interfaces.RebirthFill = Interfaces.RebirthFill or (Interfaces.RebirthFrame:FindFirstChild("Progress bar") and Interfaces.RebirthFrame["Progress bar"]:FindFirstChild("Internal progress bar") or nil)
		Interfaces.RebirthButton = Interfaces.RebirthButton or Interfaces.RebirthFrame:QueryDescendants("#RebirthButton > #TextButton")[1]
	end
	task.spawn(function()
		while Enableds.Rebirth do
			if IsFillFull(Interfaces.RebirthFill) then
				FireButton(Interfaces.RebirthButton)
			end
			task.wait(0.5)
		end
	end)
end

---------------------------------- [UI SETUP] ----------------------------------
local Window = UI:CreateWindow({
	Name = "+1 Drain Water Per Click", 
	Destroying = function()
		for key, _ in pairs(Enableds) do
			Enableds[key] = false
		end
		for _, connection in pairs(Connections) do
			if connection then
				connection:Disconnect()
			end
		end
	end
})

Interfaces.ClickToggle = Window:AddToggle({
	Text = "Level Up",
	Value = false,
	Callback = function(value)
		Enableds.Click = value
		HandleClick()
	end
})

Window:AddSlider({
	Text = "Stage",
	Range = {1, ProfileData.MaxStage > 0 and ProfileData.MaxStage or 1},
	Value = LevelTarget,
	Increment = 1,
	Callback = function(value)
		LevelTarget = value
	end
})

Interfaces.StageToggle = Window:AddToggle({
	Text = "Auto Stage",
	Value = false,
	Callback = function(value)
		Enableds.Stage = value
		HandleStage()
	end
})

Interfaces.CashToggle = Window:AddToggle({
	Text = "Collect Cash",
	Value = false,
	Callback = function(value)
		Enableds.Cash = value
		HandleCash()
	end
})

Interfaces.EquipToggle = Window:AddToggle({
	Text = "Equip Best",
	Value = false,
	Callback = function(value)
		Enableds.Equip = value
		HandleEquip()
	end
})

Window:AddToggle({
	Text = "Auto Rebirth",
	Value = false,
	Callback = function(value)
		Enableds.Rebirth = value
		HandleRebirth()
	end
})

Interfaces.SellToggle = Window:AddToggle({
	Text = "Auto Sell",
	Value = false,
	Callback = function(value)
		Enableds.Sell = value
		HandleSell()
	end
})

Window:AddDropdown({
	Text = "Upgrade Type",
	Options = #UpgradeTypes > 0 and UpgradeTypes or {"No Upgrade Type"},
	Option = nil,
	MultipleOptions = true,
	Callback = function(option)
		for _, mode in ipairs(UpgradeTypes) do
			UpgradeActives[mode] = table.find(option, mode) ~= nil
		end
		UpgradeActives["AllEnabled"] = #option <= 0
	end
})

Window:AddToggle({
	Text = "Auto Upgrade",
	Value = false,
	Flag = "upgrade_enabled",
	Callback = function(value)
		Enableds.Upgrade = value
		HandleUpgrade()
	end
})

-- Credits & Info
Window:AddLabel({ Text = "YouTube: Crokyreo", TextColor3 = Color3.fromRGB(255, 255, 255) })
Window:AddLabel({ Text = "YouTube: Tora IsMe", TextColor3 = Color3.fromRGB(255, 255, 255) })

Services.GuiService:SetGameplayPausedNotificationEnabled(false)
