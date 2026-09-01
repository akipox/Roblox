--                         This was made by vaehz and Crokyreo 
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Crokier/Roblox/main/Packages/Sampluy/init.luau"))()

local Services = setmetatable({}, {__index = function(_, i) return cloneref and cloneref(game:GetService(i)) or game:GetService(i) end})

local Players = Services.Players
local RunService = Services.RunService
local ReplicatedStorage = Services.ReplicatedStorage

local Enableds = {["FarmEggs"] = false, ["AutoPlace"] = false, ["AutoFarm"] = false, ["AutoHatch"] = false, ["AutoEquip"] = false}
local Connections = {}
local Values = {["ChosenArea"] = "Automatic"}

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()

local Packets = {} 

local SpeedVal = Player.leaderstats.Speed
local PlayerBase

for i, base in pairs(workspace.Plots:GetChildren()) do
	if base.PlotSign.PlayerPlotSign.Frame.PlayerIcon.Image:find(tostring(Player.UserId)) then
		PlayerBase = base
	end
end

local GuardAreas = workspace.__OBJECTS.Areas.GuardAreas
local SpawnedEggs = workspace.AreaEggSlotsClient
local PlacedEggs

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

--[[
local StealEvent = ReplicatedStorage.Network["Eggs: RequestAreaEggCarry"]
local PlaceEvent = ReplicatedStorage.Network["Eggs: RequestPlaceEgg"]
local HatchEvent = ReplicatedStorage.Network["Eggs: RequestHatchEgg"]
local EquipEvent = ReplicatedStorage.Network["Backpack: EquipBest"]
local CompleteHatchEvent = ReplicatedStorage.Network["Eggs: RequestCompleteHatchEgg"]

local InventoryEvent = ReplicatedStorage.Network["Eggs: RuntimeOwnerUpdated"]
]]

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

local LastInventory

local function GetBestArea()
	local currentSpeed = SpeedVal.Value
	local bestName, bestSpeed = nil, -1

	if ChosenArea == "Automatic" then
		for name, data in pairs(Areas) do
			if data.Speed <= currentSpeed and data.Speed > bestSpeed then
				bestName = name
				bestSpeed = data.Speed
			end
		end
	else
		bestName = ChosenArea
	end

	return bestName
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
			local flat = (Vector2.new(hrp.Position.X, hrp.Position.Z)
				- Vector2.new(pos.X, pos.Z)).Magnitude
			if flat <= 4 then
				return true
			end
		else
			return false
		end
	end
end

Connections.CharacterAdded = Player.CharacterAdded:Connect(function(char)
	Character = char
end)

task.spawn(function()
	if not Packets.InventoryChanged then
		return 
	end
	Packets.InventoryChanged = ReplicatedStorage.Network["Eggs: RuntimeOwnerUpdated"]
	Connections.InventoryChanged = Packets.InventoryChanged.OnClientEvent:Connect(function(data)
	    if data.OwnerUserId == Player.UserId then
		   LastInventory = data.Records
	    end
    end)
end)
	

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
					pcall(function()
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

						if Enableds.FarmEggs then
							local bestArea = GuardAreas[GetBestArea()]

							Humanoid.HipHeight = 20
							task.wait(0.1)
							walkTo(Humanoid, Waypoints.SafeArea)
							Humanoid.HipHeight = 2
							task.wait(0.1)
							walkTo(Humanoid, bestArea.Bounds.Position)

							local closestEgg, closestDist
							for _, v in pairs(SpawnedEggs:GetChildren()) do
								local primaryPart = v.PrimaryPart
								if primaryPart then
									local dist = (primaryPart.Position - Character.HumanoidRootPart.Position).Magnitude
									if not closestDist or dist < closestDist then
										closestDist = dist
										closestEgg = v
									end
								end
							end

							walkTo(Humanoid, closestEgg.PrimaryPart.Position)

							task.wait(0.5)

							walkTo(Humanoid, closestEgg.PrimaryPart.Position)
							task.wait()

							StealEvent:InvokeServer(
								{
									Uid = closestEgg.Name
								}
							)

							walkTo(Humanoid, Waypoints.SafeArea)
						end

						task.wait(0.5)

						if Enableds.AutoPlace and Packets.Place then
							if LastInventory ~= nil then
								Humanoid.HipHeight = 20
								task.wait(0.1)
								walkTo(Humanoid, PlayerBase.CenterPoint.Position)

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
								local splitString = v.Name:split("_")
								if splitString[1] == tostring(Player.UserId) then
									Humanoid.HipHeight = 20
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
					end)

					task.wait()
				end
			end)
		end
	end
})

Window:AddToggle({
	Name = "Auto Collect",
	Default = false,
	Callback = function(v)
		Enableds.FarmEggs = v
	end
})

Window:AddDropdown({
	Name = "Area",
	Options = AreasList,
	Multi = false,
	Callback = function(v)
		Values.ChosenArea = v
	end
})

Window:AddToggle({
	Name = "Auto Place",
	Default = false,
	Callback = function(v)
		Enableds.AutoPlace = v
		if v then
		   if not Packets.Place then
		       local ok = pcall(function()
			       Packets.Place = Packets.Place or ReplicatedStorage.Packages.Networking["RF/EggWorld/AskPlaceEgg"]
		       end)

		       if not ok then
			       ok = pcall(function()
			           Packets.Place = Packets.Place or ReplicatedStorage.Network["Eggs: RequestPlaceEgg"]
		           end)
			   end
		   end
		end
	end
})

Window:AddToggle({
	Name = "Auto Hatch",
	Default = false,
	Callback = function(v)
		Enableds.AutoHatch = v
			
	    if v then
		   if not Packets.Hatch then
		       local ok = pcall(function()
			       Packets.Hatch = Packets.Hatch or ReplicatedStorage.Packages.Networking["RF/EggWorld/AskHatch"]
		       end)

		       if not ok then
			       ok = pcall(function()
			           Packets.Hatch = Packets.Hatch or ReplicatedStorage.Network["Eggs: RequestHatchEgg"]
		           end)
			   end
		   end
		   if not Packets.CompleteHatch then
		       local ok = pcall(function()
			       Packets.CompleteHatch = Packets.CompleteHatch or ReplicatedStorage.Packages.Networking["RF/EggWorld/AskFinishHatch"]
		       end)

		       if not ok then
			       ok = pcall(function()
			           Packets.CompleteHatch = Packets.CompleteHatch or ReplicatedStorage.Network["Eggs: RequestCompleteHatchEgg"]
		           end)
			   end
			end
		end
	end
})

Window:AddToggle({
	Name = "Auto Equip Best",
	Default = false,
	Callback = function(v)
		Enableds.AutoEquip = v
		if v then
		   if not Packets.EquipBest then
		       local ok = pcall(function()
			       Packets.EquipBest = Packets.EquipBest or ReplicatedStorage.Packages.Networking["RF/Haul/WearBest"]
		       end)

		       if not ok then
			       ok = pcall(function()
			           Packets.EquipBest = Packets.EquipBest or ReplicatedStorage.Network["Backpack: EquipBest"]
		           end)
			   end
		   end
		end
	end
})

Window:AddLabel({
	Name = "YouTube: vaehz",
	TextColor3 = Color3.fromRGB(255, 255, 255),
})

Window:AddLabel({
	Name = "YouTube: Crokyreo",
	TextColor3 = Color3.fromRGB(255, 255, 255),
})
