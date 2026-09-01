local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Crokier/Roblox/main/Packages/Sampluy/init.luau"))()

local Services = setmetatable({}, {__index = function(_, i) return cloneref and cloneref(game:GetService(i)) or game:GetService(i) end})

local Players = Services.Players
local RunService = Services.RunService
local ReplicatedStorage = Services.ReplicatedStorage

local Enableds = {["FarmEggs"] = false, ["AutoPlace"] = false, ["AutoFarm"] = false, ["AutoHatch"] = false, ["AutoEquip"] = false}
local Connections = {}
local Values = {["ChosenArea"] = "Automatic"}

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local Packets = {} 
local SpeedValue = LocalPlayer:QueryDescendants("#leaderstats > #Speed")[1]
local Plot = nil

local PlotsFolder = workspace:FindFirstChild("Plots")

for i, plot in pairs(PlotsFolder:GetChildren()) do
	local imageLabel = plot:QueryDescendants("#PlotSign > #PlayerPlotSign > #Frame > #PlayerIcon")[1]
	if imageLabel and imageLabel.Image:find(tostring(LocalPlayer.UserId)) then
		Plot = plot
		break
	end
end

local GuardAreas = workspace:QueryDescendants("#__OBJECTS > #Areas > #GuardAreas")[1]
local SpawnedEggs = workspace:FindFirstChild("AreaEggSlotsClient")
local PlacedEggs = nil

local Interfaces = {}

for i, v in pairs(workspace:GetChildren()) do
	if v.Name == "PlacedEggRenders" and #v:GetChildren() >= 1 then
		PlacedEggs = v
	end
end

local AreasList = {
	"Automatic"
}
for i, v in pairs(GuardAreas:GetChildren()) do
	table.insert(AreasList, v.Name)
end

local Areas = {
	["Forest"] = {
		Speed = 0
	},
	["Lake"] = {
		Speed = 900
	},
	["Desert"] = {
		Speed = 10000
	},
	["Jungle"] = {
		Speed = 40000
	},
	["Snow"] = {
		Speed = 450000
	},
	["Volcano"] = {
		Speed = 700000
	},
	["Abyss Ocean"] = {
		Speed = 2500000
	},
	["Prehistoric"] = {
		Speed = 17000000
	},
	["Cosmic"] = {
		Speed = 700000000
	}
}

local Waypoints = {
	SafeArea = Vector3.new(542, 71, -363)
}

local LastInventory = nil

Connections.CharacterAdded = LocalPlayer.CharacterAdded:Connect(function(char)
	Character = char
end)

local function GetBestArea()
	local currentSpeed = SpeedValue.Value
	local bestName, bestSpeed = nil, -1

	if Values.ChosenArea == "Automatic" then
		for name, data in pairs(Areas) do
			if data.Speed <= currentSpeed and data.Speed > bestSpeed then
				bestName = name
				bestSpeed = data.Speed
			end
		end
	else
		bestName = Values.ChosenArea
	end

	return bestName or "Lake"
end

local function walkTo(hum, pos)
	local hrp = hum.RootPart
	while true do
		hum:MoveTo(pos)
		local reached = hum.MoveToFinished:Wait()

		if reached then
			return true
		end

		if hrp and hrp.Parent then
			local flat = (Vector2.new(hrp.Position.X, hrp.Position.Z) - Vector2.new(pos.X, pos.Z)).Magnitude
			if flat <= 4 then
				return true
			end
		else
			return false
		end
	end
end

local Window = UI:CreateWindow({
	Name = "Steal an Egg",
	Destroying = function()
		for key, enabled in pairs(Enableds) do
			Enableds[key] = false
		end
		for key, connection in pairs(Connections) do
			if connection then
				connection:Disconnect()
			end
		end
	end
})

Window:AddToggle({
	Name = "Auto Farm",
	Value = false,
	Callback = function(v)
		Enableds.AutoFarm = v

		if Enableds.AutoFarm then
			task.spawn(function()
				while Enableds.AutoFarm do
					local NoclipParts = {}
					local Noclipping

					local Humanoid = Character:FindFirstChildOfClass("Humanoid")

					Noclipping = RunService.Stepped:Connect(function()
						if Enableds.AutoFarm then
							for _, child in pairs(Character:GetDescendants()) do
								if child:IsA("BasePart") and child.CanCollide == true then
									child.CanCollide = false
									NoclipParts[child] = true
								end
							end
						end
					end)

					if Enableds.FarmEggs and Packets.Steal then
						local bestArea = GuardAreas[GetBestArea()]

						--Humanoid.HipHeight = 20
						task.wait(0.1)
						walkTo(Humanoid, Waypoints.SafeArea)
						--Humanoid.HipHeight = 2
						task.wait(0.1)
						walkTo(Humanoid, bestArea.Bounds.Position)

						local closestEgg, closestDist = nil, nil
						for _, v in pairs(SpawnedEggs:GetChildren()) do
							local primaryPart = v.PrimaryPart
							if primaryPart then
								local rootPart = Character.PrimaryPart or Character:FindFirstChild("HumanoidRootPart")
								local dist = (primaryPart.Position - Character.HumanoidRootPart.Position).Magnitude
								if not closestDist or dist < closestDist then
									closestDist = dist
									closestEgg = v
								end
							end
						end

						if closestEgg then
							walkTo(Humanoid, closestEgg.PrimaryPart.Position)

							task.wait(0.5)

							walkTo(Humanoid, closestEgg.PrimaryPart.Position)
							task.wait()

							Packets.Steal:InvokeServer({Uid = closestEgg.Name})
						end
						walkTo(Humanoid, Waypoints.SafeArea)
					end

					task.wait(0.5)

					if Enableds.AutoPlace and Packets.Place then
						if LastInventory ~= nil then
							Humanoid.HipHeight = 20
							task.wait(0.1)
							walkTo(Humanoid, Plot.CenterPoint.Position)

							for i, v in pairs(LastInventory) do
								local randomArea = CFrame.new(math.random(-23, 23), -0.5001220703125, math.random(-29, 29), 0, 0, 1, 0, 1, 0, -1, 0, 0)

								Packets.Place:InvokeServer(
									{
										Uid = i,
										LocalCFrame = randomArea
									}
								)

								task.wait()
							end
						end
					end

					if Enableds.AutoHatch and Packets.Hatch and Packets.CompleteHatch then
						for i, v in pairs(PlacedEggs:GetChildren()) do
							if not (v and v.Parent) then continue end
							local splitString = v.Name:split("_")
							if splitString[1] == tostring(LocalPlayer.UserId) then
								--Humanoid.HipHeight = 20
								task.wait(0.1)
								walkTo(Humanoid, v.PrimaryPart.Position)

								local res = Packets.Hatch:InvokeServer(
									splitString[2]
								)

								if res then
									Packets.CompleteHatch:InvokeServer(splitString[2])
								end

								task.wait(0.1)
							end
						end
					end

					if Enableds.AutoEquip and Packets.EquipBest then
						Packets.EquipBest:InvokeServer()
					end

					if Noclipping then
						Noclipping:Disconnect()
						Noclipping = nil
					end
					for part in pairs(NoclipParts) do
						if part and part.Parent then
							part.CanCollide = true
						end
					end
					NoclipParts = {}

					task.wait(1)

					task.wait()
				end
			end)
		end
	end
})

Interfaces.CollectToggle = Window:AddToggle({
	Name = "Auto Collect",
	Default = false,
	Callback = function(v)
		Enableds.FarmEggs = v
		if v then
			if not Packets.Steal then
				local ok, result = pcall(function()
					return ReplicatedStorage.Packages.Networking["RF/EggWorld/AskFieldEggCarry"]
				end)
				if ok and result then Packets.Steal = result end

				if not Packets.Steal then
					ok, result = pcall(function()
						return ReplicatedStorage.Network["Eggs: RequestAreaEggCarry"]
					end)
					if ok and result then Packets.Steal = result end
				end
			end
		end
		if not Packets.Steal then
			Enableds.FarmEggs = false
			Interfaces.CollectToggle:Replace(false)
		end
	end
})

Window:AddDropdown({
	Name = "Area",
	Options = AreasList,
	Multi = false,
	Callback = function(option)
		Values.ChosenArea = option[1]
	end
})

Interfaces.PlaceToggle = Window:AddToggle({
	Name = "Auto Place",
	Default = false,
	Callback = function(v)
		Enableds.AutoPlace = v
		if v then
			if not Packets.Place then
				local ok, result = pcall(function()
					return ReplicatedStorage.Packages.Networking["RF/EggWorld/AskPlaceEgg"]
				end)
				if ok and result then Packets.Place = result end

				if not Packets.Place then
					ok, result = pcall(function()
						return ReplicatedStorage.Network["Eggs: RequestPlaceEgg"]
					end)
					if ok and result then Packets.Place = result end
				end
			end
			if not Packets.Inventory then
				local ok, result = pcall(function()
					return ReplicatedStorage.Packages.Networking["RE/EggWorld/OwnerShifted"]
				end)
				if ok and result then Packets.Inventory = result end

				if not Packets.Inventory then
					ok, result = pcall(function()
						return ReplicatedStorage.Network["Eggs: RuntimeOwnerUpdated"]
					end)
					if ok and result then Packets.Inventory = result end
				end
			end
			if Packets.Inventory and not Connections.Inventory then
				Connections.Inventory = Packets.InventoryChanged.OnClientEvent:Connect(function(data)
					if data.OwnerUserId == LocalPlayer.UserId then
						LastInventory = data.Records
					end
				end)
			end
		end
		if not (Packets.Place and Packets.Inventory) then
			Enableds.AutoPlace = false
			Interfaces.PlaceToggle:Replace(false)
		end
	end
})

Interfaces.HatchToggle = Window:AddToggle({
	Name = "Auto Hatch",
	Default = false,
	Callback = function(v)
		Enableds.AutoHatch = v
		if v then
			if not Packets.Hatch then
				local ok, result = pcall(function()
					return ReplicatedStorage.Packages.Networking["RF/EggWorld/AskHatch"]
				end)
				if ok and result then Packets.Hatch = result end
				if not Packets.Hatch then
					ok, result = pcall(function()
						return ReplicatedStorage.Network["Eggs: RequestHatchEgg"]
					end)
					if ok and result then Packets.Hatch = result end
				end
			end
			if not Packets.CompleteHatch then
				local ok, result = pcall(function()
					return ReplicatedStorage.Packages.Networking["RF/EggWorld/AskFinishHatch"]
				end)
				if ok and result then Packets.CompleteHatch = result end
				if not Packets.CompleteHatch then
					ok, result = pcall(function()
						return ReplicatedStorage.Network["Eggs: RequestCompleteHatchEgg"]
					end)
					if ok and result then Packets.CompleteHatch = result end
				end
			end
		end
		if not (Packets.Hatch and Packets.CompleteHatch) then
			Enableds.AutoHatch = false
			Interfaces.HatchToggle:Replace(false)
		end 
	end
})

Interfaces.EquipToggle = Window:AddToggle({
	Name = "Auto Equip Best",
	Default = false,
	Callback = function(v)
		Enableds.AutoEquip = v
		if v then
			if not Packets.EquipBest then
				local ok, result = pcall(function()
					return ReplicatedStorage.Packages.Networking["RF/Haul/WearBest"]
				end)
				if ok and result then Packets.EquipBest = result end
				if not Packets.EquipBest then
					ok, result = pcall(function()
						return ReplicatedStorage.Network["Backpack: EquipBest"]
					end)
					if ok and result then Packets.EquipBest = result end
				end
			end
		end
		if not Packets.EquipBest then
			Enableds.AutoEquip = false
			Interfaces.EquipToggle:Replace(false)
		end 
	end
})

Window:AddLabel({
	Name = "YouTube: Crokyreo",
	TextColor3 = Color3.fromRGB(255, 255, 255),
})

Window:AddLabel({
	Name = "YouTube: vaehz",
	TextColor3 = Color3.fromRGB(255, 255, 255),
})
