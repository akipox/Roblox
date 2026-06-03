local SimpleUI=loadstring(game:HttpGet("http://raw.githubusercontent.com/PaazlisMaswa/RobloxProject/refs/heads/main/Packages/SimpleUI/init.luau"))()

local RunService=game:GetService("RunServie")

local Window = SimpleUI:CreateWindow({
	Name = "Targeting Tools"
})

local AutoClickEnabled=false

Window:CreateToggle({Name = "Auto Clicker", CurrentValue = false, Callback=function(value)
   if value then
      if AutoClickEnabled then return end
      AutoClickEnabled=true
      task.spawn()
         while AutoClickEnabled then
            task.wait()
            
         end
      end
   end
end})


local Credit = Window:AddLabel({Text = "YouTube: None"})
  
    
