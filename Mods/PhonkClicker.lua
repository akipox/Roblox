local SimpleUI=loadstring(game:HttpGet("http://raw.githubusercontent.com/PaazlisMaswa/RobloxProject/refs/heads/main/Packages/SimpleUI/init.luau"))()

local ReplicatedStorage=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunServie")

local Window = SimpleUI:CreateWindow({
	Name = "Targeting Tools"
})

local AutoClickEnabled=false
local ClickBrainrotRE=nil

Window:CreateToggle({Name = "Auto Clicker", CurrentValue = false, Callback=function(value)
   if value then
      if AutoClickEnabled then return end
      AutoClickEnabled=true
      task.spawn(function()
         while AutoClickEnabled then
            task.wait()
			if not ClickBrainrotRE or not ClickBrainrotRE.Parent then
				ClickBrainrotRE=ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ClickBrainrot")
			end
            ClickBrainrotRE:FireServer(1)
         end
      end)
   end
end})


local Credit = Window:AddLabel({Text = "YouTube: None"})
