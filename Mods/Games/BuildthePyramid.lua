if not game:IsLoaded() then game.Loaded:Wait() end

local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Crokier/Roblox/main/Packages/Sampluy/init.luau"))()

local Services = setmetatable({}, {__index = function(_, i) return cloneref and cloneref(game:GetService(i)) or game:GetService(i) end})
local Players = Services.Players
local ReplicatedStorage = Services.ReplicatedStorage

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local Modules = {}

local TypeData = {
	["Code"] = {}
}

local ActiveData = {
	["Code"] = {}
}

local Packets = {
	["RedeemCode"] = ReplicatedStorage:QueryDescendants("#Packages > #_Index >> #Services > #CodesService > #RF > #Redeem")[1]
}

local Interfaces = {}

local function updateCodes(option, isList)
   local changed = false
   for v1,v2 in ipairs(option) do
	    local code = isList and v2 or v1
	    if ActiveData.Code[code]==nil then
			ActiveData.Code[code]=false
			table.insert(TypeData.Code, code)
		    changed = true 
		end
	end
	return TypeData.Code
end

local Window = UI:CreateWindow({
	Name = "Build the Pyramida",
	ConfigInfo = {Enabled=true,Path="Crokyreo/BuildthePyramida/configs.json"},
	Destroying = function() end
})

Interfaces.CodeDropdown = Window:AddDropdown({
	Text = "Code List",
	Options = {"No Code"},
	Option = nil,
	Multi = true,
	Flag = "code_options",
	Callback = function(option)
		
		
	end
})

Window:AddButton({
	Text = "Claim Code",
	MethodType = "DebounceClick",
	Callback = function()
		Modules.CodeData = Modules.CodeData or require(ReplicatedStorage:QueryDescendants("#Shared > #Config > #CodesConfig")[1]:Clone())
		local changed = false
		for code, info in pairs(Modules.CodeData.Codes) do
			Packets.RedeemCode:InvokeServer(code)
			if ActiveData.Code[code]==nil then
				ActiveData.Code[code]=false
				table.insert(TypeData.Code, code)
				changed = true
			end
			task.wait()
		end
		Interfaces.CodeDropdown.Options = TypeData.Code
		Interfaces.CodeDropdown:Refresh()
		if changed then
			Interfaces.CodeDropdown:Set(TypeData.Code)
		end
	end
})

Window:AddLinkButton({Text = "Donate 💖", Link = "https://link-target.net/6690566/TlR2vuR2JR4F"})
Window:AddLabel({Text = "YouTube: Crokyreo", TextColor3 = Color3.fromRGB(255, 255, 255)})
Services.GuiService:SetGameplayPausedNotificationEnabled(false)
Window:LoadConfig()
