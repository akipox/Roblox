-- This is what the script looks like from Tora IsMe.
-- This is a script I made myself. I DO NOT STEAL SCRIPT because i can't read script on Tora IsMe

-- ============================================================================== --
-- =============================== DEPENDENCIES ================================= --
-- ============================================================================== --
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Crokier/Roblox/main/Packages/Sampluy/init.luau"))()

local Services = setmetatable({}, {__index = function(_, i) return cloneref and cloneref(game:GetService(i)) or game:GetService(i) end})
local Players = Services.Players
local ReplicatedStorage = Services.ReplicatedStorage

-- ============================================================================== --
-- ================================= VARIABLES ================================== --
-- ============================================================================== --
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- State Management
local Enableds = {
	["Click"] = false, 
	["Upgrade"] = false, 
	["Cash"] = false, 
	["Hit"] = false, 
	["Sell"] = false, 
	["Rebirth"] = false,
	["EquipBestFish"] = false
}
local Connections = {}
local Packets = {}
local ClickIndex = 0

-- UI & Game Objects
local MainGui = PlayerGui:FindFirstChild("Main")
local HomeButton = PlayerGui:QueryDescendants("#HUD > #Main > #Top > #GoShow > #TextButton")[1]
local UpgradeScroll = LocalPlayer:QueryDescendants("#Main > #Upgrades > #Main > #ScrollingFrame")[1]
local CapacityValue = LocalPlayer:QueryDescendants("#BackpackData > #capacity")[1]
local StageValue = LocalPlayer:QueryDescendants("#Stage > #stage")[1]

local UpgradeTypes, UpgradeActives, UpgradeInfos = {}, {["AllEnabled"] = true}, {}
local ProfileData = {}

local StageFolder = nil
local WorldFishFolder = nil
local RebirthFrame, RebirthFill, RebirthButton = nil, nil, nil
local CashHitbox = nil
local HitToggle = nil
local CashToggle = nil

local MaxLevel = 0

-- ============================================================================== --
-- =============================== INITIALIZATION =============================== --
-- ============================================================================== --

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

local LevelTarget = ProfileData.Stage or 1

Connections.CharacterAdded = LocalPlayer.CharacterAdded:Connect(function(newCharacter)
	Character = newCharacter
end)

-- Parse Upgrades
if UpgradeScroll then
	local sortUpgrades = {}

	for _, layer in ipairs(UpgradeScroll:GetChildren()) do
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
							MaxLevel += 1
						end
					end
					break 
				end
			end
		end
		if StageFolder then break end
	end
end

-- ============================================================================== --
-- ============================== UTILITY FUNCTIONS ============================= --
-- ============================================================================== --

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

local Plot = GetPlot()

local function SuperPivoTo(model, p1, p2, height)
	local orientation = p2.Orientation
	local extraHeight = (p1.Size.Y / 2) + (p2.Size.Y / 2) + height
	local newPosition = Vector3.new(p1.Position.X, p1.Position.Y + extraHeight, p1.Position.Z)
	local newRotation = CFrame.fromEulerAngles(math.rad(orientation.X), math.rad(orientation.Y), math.rad(orientation.Z), Enum.RotationOrder.YXZ)
	model:PivotTo(CFrame.new(newPosition) * newRotation)
end

-- ============================================================================== --
-- ================================= CORE LOGIC ================================= --
-- ============================================================================== --

local function HandleCash()
	if not Enableds.Cash then return end

	if not CashHitbox then
		local newPlot = GetPlot()
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
		if CashToggle then CashToggle:Replace(false) end
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

	task.spawn(function()
		while Enableds.Click do
			Packets.Click:FireServer(ClickIndex)
			ClickIndex += 1
			task.wait(0.1)
		end
	end)
end

local function HandleEquipBestFish()
	if not Enableds.EquipBestFish then return end
	Packets.EquipBestFish = Packets.EquipBestFish or ReplicatedStorage.Remote.Function.FishShow["[C-S]BestFishUI"]

	task.spawn(function()
		while Enableds.EquipBestFish do
			Packets.EquipBestFish:InvokeServer()
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

	task.spawn(function()
		while Enableds.Sell do
			Packets.SellAll:InvokeServer()
			task.wait(1)
		end
	end)
end

local function HandleHit()
	if not Enableds.Hit then return end

	task.spawn(function()
		while Enableds.Hit do
			local level = ProfileData.Stage
			local levelFolder = StageFolder:FindFirstChild("关卡"..tostring(level))

			if levelFolder then
				local checkPart = levelFolder:FindFirstChild("光门")
				local surfacePart = levelFolder:FindFirstChild("水面")
				local humanoid = Character:FindFirstChildOfClass("Humanoid")
				local rootPart = Character.PrimaryPart or Character:FindFirstChild("HumanoidRootPart")

				while Enableds.Hit and checkPart and checkPart.CanCollide and level < LevelTarget do
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
								task.wait(0.1)
							end
						end
					end

					if not Enableds.Hit then break end

					table.sort(sortFishs, function(a, b)
						return a.Tier > b.Tier
					end)

					local currentCapacity = 0
					for _, info in ipairs(sortFishs) do
						if not Enableds.Hit then break end

						local spawnPoint, prompt = info.SpawnPoint, info.Prompt
						SuperPivoTo(Character, spawnPoint, rootPart, humanoid.HipHeight)
						task.wait(0.1)
						FirePrompt(prompt)

						if currentCapacity >= ProfileData.Capacity then
							break
						end
						currentCapacity += 1
						task.wait(0.1)
					end

					if currentCapacity >= ProfileData.Capacity and HomeButton then
						FireButton(HomeButton)
					end
					table.clear(sortFishs)
				end
			end
			
			task.wait(1)
		end
	end)
end

local function FireRebirth()
	if RebirthFill and RebirthButton and IsFillFull(RebirthFill) and Enableds.Rebirth then
		FireButton(RebirthButton)
	end
end

local function HandleRebirth()
	if Connections.Rebirth then 
		Connections.Rebirth:Disconnect() 
		Connections.Rebirth = nil 
	end

	if not Enableds.Rebirth then return end

	RebirthFrame = RebirthFrame or (MainGui and MainGui:FindFirstChild("Rebirth+1water") and MainGui["Rebirth+1water"]:FindFirstChild("UI1") or nil)

	if RebirthFrame then
		RebirthFill = RebirthFill or (RebirthFrame:FindFirstChild("Progress bar") and RebirthFrame["Progress bar"]:FindFirstChild("Internal progress bar") or nil)
		RebirthButton = RebirthButton or RebirthFrame:QueryDescendants("#RebirthButton > #TextButton")[1]
	end

	if RebirthFill then
		Connections.Rebirth = RebirthFill:GetPropertyChangedSignal("Size"):Connect(FireRebirth)
	end

	task.spawn(function()
		while Enableds.Rebirth do
			FireRebirth()
			task.wait(1)
		end
	end)
end

-- ============================================================================== --
-- ================================= UI SETUP =================================== --
-- ============================================================================== --

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

Window:AddToggle({
	Text = "Level Up",
	Value = false,
	Flag = "click_enabled",
	Callback = function(value)
		value = false
		Enableds.Click = value
		HandleClick()
	end
})

Window:AddSlider({
	Text = "Checkpoint",
	Range = {1, MaxLevel > 0 and MaxLevel or 1},
	Value = LevelTarget,
	Increment = 1,
	Flag = "checkpoint_index",
	Callback = function(value)
		LevelTarget = value
	end
})

HitToggle = Window:AddToggle({
	Text = "Auto Hit",
	Value = false,
	Flag = "hit_enabled",
	Callback = function(value)
		value = false
		Enableds.Hit = value
		HandleHit()
	end
})

CashToggle = Window:AddToggle({
	Text = "Collect Cash",
	Value = false,
	Flag = "cash_enabled",
	Callback = function(value)
		value = false
		Enableds.Cash = value
		HandleCash()
	end
})

Window:AddToggle({
	Text = "Equip Best Fish",
	Value = false,
	Flag = "equip_best_fish_enabled",
	Callback = function(value)
        value = false
		Enableds.EquipBestFish = value
		HandleEquipBestFish()
	end
})

Window:AddToggle({
	Text = "Auto Rebirth",
	Value = false,
	Flag = "rebirth_enabled",
	Callback = function(value)
		value = false
		Enableds.Rebirth = value
		HandleRebirth()
	end
})

Window:AddLabel({ Text = "+ More Feature", TextColor3 = Color3.fromRGB(255, 255, 255) })
if true then return end

Window:AddToggle({
	Text = "Auto Sell",
	Value = false,
	Flag = "sell_enabled",
	Callback = function(value)
        value = false
		Enableds.Sell = value
		HandleSell()
	end
})

Window:AddDropdown({
	Text = "Upgrade Type (Empty = All)",
	Options = #UpgradeTypes > 0 and UpgradeTypes or {"No Upgrade Type"},
	Option = nil,
	MultipleOptions = true,
	Flag = "upgrade_options",
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
		value = false
		Enableds.Upgrade = value
		HandleUpgrade()
	end
})

-- Credits & Info
Window:AddLabel({ Text = "YouTube: Crokyreo", TextColor3 = Color3.fromRGB(255, 255, 255) })
Window:AddLabel({ Text = "YouTube: Tora IsMe", TextColor3 = Color3.fromRGB(255, 255, 255) })
Window:AddLabel({ Text = "Date: 08-15-2026", TextColor3 = Color3.fromRGB(255, 255, 255) })

Services.GuiService:SetGameplayPausedNotificationEnabled(false)
